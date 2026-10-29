#import "ODOriginalDuoStartupDiagnostic.h"
#import "../duo/ODUnifiedDuoHost.h"
#import <CommonCrypto/CommonDigest.h>
#include <fcntl.h>
#include <dirent.h>
#include <errno.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(OD_ORIGINAL_DUO_DIAGNOSTIC_ENTRY) && OD_ORIGINAL_DUO_DIAGNOSTIC_ENTRY && \
    defined(OD_UNIFIED_DUO_STARTUP_ENTRY) && OD_UNIFIED_DUO_STARTUP_ENTRY
#error Original startup diagnostic and integrated production entries are mutually exclusive.
#endif

static NSDictionary *ODDiagnosticReport;

static NSError *ODDiagnosticFailure(void) {
    return [NSError errorWithDomain:@"OfflineDokkan.OriginalStartupDiagnostic" code:1
        userInfo:@{NSLocalizedDescriptionKey:@"The original-client startup inputs are unavailable. No replacement game was opened."}];
}

/* Walk the actual native path. NSURL's normalized spelling alone must not admit
 * a symlink into another directory. This never opens a save or a key file. */
static int ODDiagnosticDirectory(NSURL *url) {
    if (!url.isFileURL || !url.path.isAbsolutePath) return -1;
    int fd = open("/",O_RDONLY|O_DIRECTORY|O_CLOEXEC);
    if (fd < 0) return -1;
    for (NSString *part in url.path.pathComponents) {
        if ([part isEqualToString:@"/"]) continue;
        if ([part isEqualToString:@"."] || [part isEqualToString:@".."]) { close(fd); return -1; }
        int next = openat(fd,part.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
        close(fd); if (next < 0) return -1; fd = next;
    }
    return fd;
}

/* Foundation selects these app-owned roots, including iOS's /var alias.
 * Resolve only the trusted root prefix, after refusing a symlink at the root
 * itself. Resource/framework descendants still use the NOFOLLOW FD walk.
 * Reopening the resolved spelling must name that same native directory. */
static NSURL *ODDiagnosticNativeRoot(NSURL *url) {
    if (!url.isFileURL || !url.path.isAbsolutePath) return nil;
    struct stat original,confirmed;
    if (lstat(url.fileSystemRepresentation,&original) || !S_ISDIR(original.st_mode) || S_ISLNK(original.st_mode)) return nil;
    NSURL *canonical = url.URLByResolvingSymlinksInPath;
    int fd = ODDiagnosticDirectory(canonical);
    BOOL valid = fd >= 0 && !fstat(fd,&confirmed) && original.st_dev == confirmed.st_dev && original.st_ino == confirmed.st_ino;
    if (fd >= 0) close(fd);
    return valid ? canonical : nil;
}

static BOOL ODDiagnosticRegularFile(NSURL *url) {
    int parent = ODDiagnosticDirectory(url.URLByDeletingLastPathComponent);
    if (parent < 0) return NO;
    int fd = openat(parent,url.lastPathComponent.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);
    struct stat info;
    BOOL valid = fd >= 0 && !fstat(fd,&info) && S_ISREG(info.st_mode) && info.st_size > 0;
    if (fd >= 0) close(fd); close(parent); return valid;
}

static BOOL ODDiagnosticOriginalSeed(NSURL *url) {
    int parent = ODDiagnosticDirectory(url.URLByDeletingLastPathComponent);
    if (parent < 0) return NO;
    int fd = openat(parent,url.lastPathComponent.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);
    close(parent); if (fd < 0) return NO;
    struct stat before,after;
    BOOL valid = !fstat(fd,&before) && S_ISREG(before.st_mode) && before.st_size == 535552;
    CC_SHA256_CTX hash; CC_SHA256_Init(&hash);
    unsigned char buffer[65536],digest[CC_SHA256_DIGEST_LENGTH]; off_t done = 0;
    while (valid && done < before.st_size) {
        ssize_t count = pread(fd,buffer,sizeof(buffer),(off_t)done);
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0 || count > before.st_size-done) { valid = NO; break; }
        CC_SHA256_Update(&hash,buffer,(CC_LONG)count); done += count;
    }
    CC_SHA256_Final(digest,&hash);
    valid = valid && done == 535552 && !fstat(fd,&after) && before.st_dev == after.st_dev &&
        before.st_ino == after.st_ino && before.st_size == after.st_size &&
        before.st_mtimespec.tv_sec == after.st_mtimespec.tv_sec && before.st_mtimespec.tv_nsec == after.st_mtimespec.tv_nsec &&
        before.st_ctimespec.tv_sec == after.st_ctimespec.tv_sec && before.st_ctimespec.tv_nsec == after.st_ctimespec.tv_nsec;
    close(fd);
    static const unsigned char expected[CC_SHA256_DIGEST_LENGTH] = {
        0x66,0x7e,0x55,0x4a,0x9c,0xfb,0x8c,0x47,0x65,0xf0,0x5a,0x1d,0x85,0xf0,0xfd,0xf7,
        0x07,0xad,0xe6,0x15,0x62,0xb5,0x0e,0x3e,0x5c,0xd9,0x8a,0xc5,0x2f,0x99,0x7b,0xa3};
    return valid && !memcmp(digest,expected,sizeof(expected));
}

static BOOL ODDiagnosticHasAssets(int fd) {
    if (fd < 0) return NO;
    int copy = dup(fd); if (copy < 0) return NO;
    DIR *directory = fdopendir(copy); if (!directory) { close(copy); return NO; }
    BOOL found = NO; struct dirent *entry;
    while ((entry = readdir(directory))) {
        if (strcmp(entry->d_name,".") && strcmp(entry->d_name,"..")) { found = YES; break; }
    }
    closedir(directory); return found;
}

static BOOL ODDiagnosticNoExistingEngineWorkingTree(int assets) {
    if (assets < 0) return NO;
    /* Unknown/existing native working trees cannot be admitted as a fresh
     * diagnostic staging set. Do not remove, inspect or rewrite their data. */
    struct stat info;
    if (!fstatat(assets,"User",&info,AT_SYMLINK_NOFOLLOW) || errno != ENOENT) return NO;
    int sqlite = openat(assets,"sqlite",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
    if (sqlite < 0) return errno == ENOENT;
    int found = fstatat(sqlite,"current",&info,AT_SYMLINK_NOFOLLOW);
    int result = errno; close(sqlite);
    return found < 0 && result == ENOENT;
}

ODUnifiedDuoHost *ODCreateOriginalDuoStartupDiagnosticHost(NSError **error) {
    if (!NSThread.isMainThread) { if (error) *error = ODDiagnosticFailure(); return nil; }
    NSBundle *bundle = NSBundle.mainBundle;
    /* Never install/run this adapted engine under the supplied original game's
     * identity. Native failure cleanup can delete its working sqlite/current
     * tree; an Application Support probe does not isolate that Documents root.
     * The reviewed package must also select a fresh own diagnostic container. */
    NSString *identity = bundle.bundleIdentifier;
    if (![identity isEqualToString:@"org.offlinedokkan.startupdiagnostic.duo"]) {
        if (error) *error = ODDiagnosticFailure(); return nil;
    }
    NSURL *bundleRoot = ODDiagnosticNativeRoot(bundle.resourceURL);
    NSURL *baseline = [bundleRoot URLByAppendingPathComponent:@"OriginalClient/OriginalGenuineDuoShell"];
    NSURL *frameworks = [bundleRoot URLByAppendingPathComponent:@"Frameworks" isDirectory:YES];
    NSURL *engine = [frameworks URLByAppendingPathComponent:@"OriginalDokkanEngine.dylib"];
    NSURL *dependency = [frameworks URLByAppendingPathComponent:@"AdjustSigSdk.framework/AdjustSigSdk"];
    NSURL *seed = [bundleRoot URLByAppendingPathComponent:@"database.db"];
    NSArray<NSURL *> *documents = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentRoot = ODDiagnosticNativeRoot(documents.firstObject);
    NSURL *resources = [documentRoot URLByAppendingPathComponent:@"assets" isDirectory:YES];
    int resourceFD = ODDiagnosticDirectory(resources);
    BOOL ready = ODDiagnosticHasAssets(resourceFD) && ODDiagnosticNoExistingEngineWorkingTree(resourceFD) && ODDiagnosticRegularFile(baseline) &&
        ODDiagnosticRegularFile(engine) && ODDiagnosticRegularFile(dependency) && ODDiagnosticOriginalSeed(seed);
    if (resourceFD >= 0) close(resourceFD);
    if (!ready) { if (error) *error = ODDiagnosticFailure(); return nil; }

    /* Dedicated disposable diagnostic state, separate from Documents/assets and
     * existing save folders. No source seed or resource is copied/modified. */
    NSURL *support = ODDiagnosticNativeRoot([NSFileManager.defaultManager URLForDirectory:NSApplicationSupportDirectory
        inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL]);
    int supportFD = ODDiagnosticDirectory(support);
    if (supportFD < 0) { if (error) *error = ODDiagnosticFailure(); return nil; }
    (void)mkdirat(supportFD,"OriginalClientStartupDiagnostic",0700);
    int stateFD = openat(supportFD,"OriginalClientStartupDiagnostic",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
    close(supportFD);
    if (stateFD < 0) { if (error) *error = ODDiagnosticFailure(); return nil; }
    close(stateFD);
    NSURL *state = [support URLByAppendingPathComponent:@"OriginalClientStartupDiagnostic" isDirectory:YES];
    NSError *failure = nil;
    ODUnifiedDuoHost *host = [[ODUnifiedDuoHost alloc] initWithPurpose:ODUnifiedDuoStartupDiagnostic
        genuineShellBaselineURL:baseline preparedEngineURL:engine resourcesRootURL:resources
        writableStateRootURL:state approvedOrigins:@[] routes:@[] creatorServices:nil attachPreparedImage:nil
        contextIsCurrent:^BOOL { return NSThread.isMainThread; }
        reportHandler:^(NSDictionary *report) { ODDiagnosticReport = [report copy]; } error:&failure];
    if (!host && error) *error = ODDiagnosticFailure();
    return host;
}

NSDictionary *ODCopyOriginalDuoStartupDiagnosticReport(void) {
    return NSThread.isMainThread ? [ODDiagnosticReport copy] : nil;
}

/* Library/component reuse is inert by default. This explicit diagnostic entry
 * cannot satisfy the integrated factory's purpose check or its release gate. */
#if defined(OD_ORIGINAL_DUO_DIAGNOSTIC_ENTRY) && OD_ORIGINAL_DUO_DIAGNOSTIC_ENTRY
static ODUnifiedDuoHost *ODDiagnosticHost;
__attribute__((constructor)) static void ODStartOriginalDuoDiagnostic(void) {
    @autoreleasepool {
        @try {
            ODUnifiedDuoHost *host = ODCreateOriginalDuoStartupDiagnosticHost(NULL);
            if (host && [host.startupReport[@"purpose"] isEqualToString:@"original-startup-diagnostic"] &&
                [host installBeforeApplicationMain:NULL]) {
                ODDiagnosticHost = host;
                return;
            }
        } @catch (NSException *exception) { (void)exception; }
        fputs("Offline Dokkan: original-client startup diagnostic failed.\n",stderr);
        _exit(EXIT_FAILURE);
    }
}
#endif
