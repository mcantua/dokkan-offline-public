// Native services for the Unit Creator screens on iPhone.
// Everything Android-specific is done in JavaScript (web/src/ios-native.js); this file only gives
// that code what a web page can't do by itself: reach any web address, keep big files on the phone,
// keep secrets in the Keychain and show the iPhone's Share sheet.
#import "Host.h"
#import "Player.h"
#import <sys/utsname.h>
#import <Security/Security.h>
#import <sqlite3.h>
#import <Network/Network.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import <CommonCrypto/CommonHMAC.h>
#import <stdatomic.h>
#import <stdbool.h>

static NSString *const kUserAgent = @"DokkanUnitForge/2.7";

/// JS sends null as NSNull: read flags and numbers safely
static BOOL B(id v) { return ([v isKindOfClass:[NSNumber class]] || [v isKindOfClass:[NSString class]]) ? [v boolValue] : NO; }
static NSInteger I(id v) { return ([v isKindOfClass:[NSNumber class]] || [v isKindOfClass:[NSString class]]) ? [v integerValue] : 0; }

extern NSDictionary *ForgeDisplayGeometry;

#pragma mark - storage

static NSString *LegacyStorageRootPath(void) {
    static NSString *root;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *base = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
        root = [[base stringByAppendingPathComponent:@"forge"] stringByStandardizingPath];
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm createDirectoryAtPath:root withIntermediateDirectories:YES attributes:nil error:nil];
        // downloaded game files can be fetched again: keep them out of iCloud backups
        NSString *cache = [root stringByAppendingPathComponent:@"cache"];
        [fm createDirectoryAtPath:cache withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSURL fileURLWithPath:cache] setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    });
    return root;
}

// Everything the app downloads lives in ONE folder the person can see in the Files app:
//   On My iPhone › Dokkan Unit Creator › Game files / Game movies / Animation scripts / Website files
// (the app's Documents folder). The Photos app never sees app files. Not backed up to iCloud:
// it can all be downloaded again.
static NSDictionary<NSString *, NSString *> *PublicFolders(void) {
    return @{ @"preview-cache": @"Game files", @"movie-cache": @"Game movies",
              @"animation-sources": @"Animation scripts", @"cache/mirror": @"Website files",
              @"sparking/resource-cache": @"Sparking files" };
}

static NSString *LegacyDownloadsRootPath(void) {
    static NSString *docs;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByStandardizingPath];
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm createDirectoryAtPath:docs withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSURL fileURLWithPath:docs] setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
        // files downloaded by earlier versions (kept privately) move into the visible folder once
        NSString *root = LegacyStorageRootPath();
        [PublicFolders() enumerateKeysAndObjectsUsingBlock:^(NSString *old, NSString *name, BOOL *stop) {
            NSString *from = [root stringByAppendingPathComponent:old], *to = [docs stringByAppendingPathComponent:name];
            BOOL dir = NO;
            if (![fm fileExistsAtPath:from isDirectory:&dir] || !dir) return;
            if (![fm fileExistsAtPath:to]) { [fm moveItemAtPath:from toPath:to error:nil]; return; }
            for (NSString *child in [fm contentsOfDirectoryAtPath:from error:nil] ?: @[]) {
                NSString *dest = [to stringByAppendingPathComponent:child];
                if (![fm fileExistsAtPath:dest]) [fm moveItemAtPath:[from stringByAppendingPathComponent:child] toPath:dest error:nil];
            }
            [fm removeItemAtPath:from error:nil];
        }];
        for (NSString *name in PublicFolders().allValues)
            [fm createDirectoryAtPath:[docs stringByAppendingPathComponent:name] withIntermediateDirectories:YES attributes:nil error:nil];
    });
    return docs;
}

static NSString *_Nullable LegacyResolvePath(NSString *relative) {
    if (![relative isKindOfClass:[NSString class]]) return nil;
    NSString *rel = [relative stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    if (!rel.length) return LegacyStorageRootPath();
    for (NSString *part in [rel componentsSeparatedByString:@"/"])
        if ([part isEqualToString:@".."] || [part isEqualToString:@"."]) return nil;
    for (NSString *key in PublicFolders()) {
        if (![rel isEqualToString:key] && ![rel hasPrefix:[key stringByAppendingString:@"/"]]) continue;
        NSString *base = [LegacyDownloadsRootPath() stringByAppendingPathComponent:PublicFolders()[key]];
        NSString *full = [[base stringByAppendingPathComponent:[rel substringFromIndex:key.length]] stringByStandardizingPath];
        if (![full isEqualToString:base] && ![full hasPrefix:[base stringByAppendingString:@"/"]]) return nil;
        return full;
    }
    NSString *root = LegacyStorageRootPath();
    NSString *full = [[root stringByAppendingPathComponent:rel] stringByStandardizingPath];
    if (![full isEqualToString:root] && ![full hasPrefix:[root stringByAppendingString:@"/"]]) return nil;
    return full;
}

// Scoped instances never override the process's legacy root or class methods.
@implementation ForgeStorageContext {
    BOOL _scoped;
    atomic_bool _revoked;
    NSString *_storageRoot, *_downloadsRoot, *_temporaryRoot, *_siteRoot;
    NSString *_keychainService, *_preferencesPrefix;
    BOOL (^_current)(void);
    BOOL (^_authorize)(NSURL *);
}
- (instancetype)init { return [super init]; }
+ (instancetype)legacyContext {
    static ForgeStorageContext *context; static dispatch_once_t once;
    dispatch_once(&once, ^{ context = [ForgeStorageContext new]; });
    return context;
}
- (instancetype)initWithRootURL:(NSURL *)root siteURL:(NSURL *)site
    keychainNamespace:(NSString *)keychainNamespace preferencesNamespace:(NSString *)preferencesNamespace
    contextIsCurrent:(BOOL (^)(void))current URLAuthorization:(BOOL (^)(NSURL *))authorization
    error:(NSError **)error {
    if (!(self = [super init])) return nil;
    if (!root.isFileURL || !site.isFileURL || !current || !authorization ||
        !keychainNamespace.length || !preferencesNamespace.length || !root.path.isAbsolutePath || !site.path.isAbsolutePath) {
        if (error) *error = [NSError errorWithDomain:@"ODCreatorTools" code:1 userInfo:@{NSLocalizedDescriptionKey:@"The native Creator workspace is unavailable."}];
        return nil;
    }
    _scoped = YES; _current = [current copy]; _authorize = [authorization copy];
    atomic_init(&_revoked, false);
    NSFileManager *fm = NSFileManager.defaultManager;
    if ([[fm attributesOfItemAtPath:root.path error:nil].fileType isEqualToString:NSFileTypeSymbolicLink]) {
        if (error) *error = [NSError errorWithDomain:@"ODCreatorTools" code:2 userInfo:@{NSLocalizedDescriptionKey:@"A linked Creator workspace is not allowed."}]; return nil;
    }
    _storageRoot = [[root.path stringByStandardizingPath] stringByResolvingSymlinksInPath];
    _downloadsRoot = [_storageRoot stringByAppendingPathComponent:@"downloads"];
    _temporaryRoot = [_storageRoot stringByAppendingPathComponent:@"temporary"];
    _siteRoot = [[site.path stringByStandardizingPath] stringByResolvingSymlinksInPath];
    _keychainService = [keychainNamespace copy]; _preferencesPrefix = [preferencesNamespace copy];
    for (NSString *dir in @[_storageRoot, _downloadsRoot, _temporaryRoot]) {
        if ([[fm attributesOfItemAtPath:dir error:nil].fileType isEqualToString:NSFileTypeSymbolicLink]) {
            if (error) *error = [NSError errorWithDomain:@"ODCreatorTools" code:2 userInfo:@{NSLocalizedDescriptionKey:@"A linked Creator workspace is not allowed."}]; return nil;
        }
        if (![fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions:@0700} error:error]) return nil;
        [[NSURL fileURLWithPath:dir] setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    }
    return self;
}
- (BOOL)scoped { return _scoped; }
- (NSString *)storageRoot { return _scoped ? _storageRoot : LegacyStorageRootPath(); }
- (NSString *)downloadsRoot { return _scoped ? _downloadsRoot : LegacyDownloadsRootPath(); }
- (NSString *)temporaryRoot { return _scoped ? _temporaryRoot : NSTemporaryDirectory(); }
- (NSString *)siteRoot { return _scoped ? _siteRoot : [[NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"site"] stringByStandardizingPath]; }
- (NSString *)keychainService { return _scoped ? _keychainService : @"com.dokkanunitcreator.secrets"; }
- (NSString *)sourceKeychainService { return _scoped ? [_keychainService stringByAppendingString:@".source"] : self.keychainService; }
- (NSString *)preferencesPrefix { return _scoped ? _preferencesPrefix : @"forge.gameFolder."; }
- (BOOL)isCurrent {
    if (!_scoped) return YES;
    if (atomic_load_explicit(&_revoked, memory_order_acquire)) return NO;
    // The native issuer can require UIKit/main actor. Background IO checks only
    // the atomic cancellation flag; the owner revokes before releasing its lease.
    if (NSThread.isMainThread && (!_current || !_current())) { [self invalidate]; return NO; }
    return YES;
}
- (void)invalidate { if (_scoped) atomic_store_explicit(&_revoked, true, memory_order_release); }
- (BOOL)allowsURL:(NSURL *)url {
    if (!_scoped) return YES;
    return self.isCurrent && [url.scheme.lowercaseString isEqualToString:@"https"] && !url.user.length && !url.password.length && _authorize && _authorize(url);
}
- (NSURLRequest *)authorizedRequest:(NSURLRequest *)request {
    if (!_scoped) return request;
    if (![self allowsURL:request.URL] || !self.requestDecorator) return nil;
    NSURLRequest *authorized = self.requestDecorator(request);
    return [authorized.URL.absoluteString isEqualToString:request.URL.absoluteString] ? authorized : nil;
}
- (BOOL)allowsFileMutation { return !_scoped || (self.isCurrent && self.fileMutationAuthorization && self.fileMutationAuthorization()); }
- (NSString *)resolve:(NSString *)relative {
    if (!_scoped) return LegacyResolvePath(relative);
    if (![self isCurrent] || ![relative isKindOfClass:NSString.class] ||
        ([relative hasPrefix:@"/"] && ![relative isEqualToString:@"/"])) return nil;
    NSString *rel = [relative stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    if ([rel rangeOfCharacterFromSet:[NSCharacterSet controlCharacterSet]].location != NSNotFound ||
        [rel rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\\:%?#"]].location != NSNotFound) return nil;
    for (NSString *part in [rel componentsSeparatedByString:@"/"])
        if (rel.length && (!part.length || [part isEqualToString:@".."] || [part isEqualToString:@"."])) return nil;
    NSString *base = self.storageRoot, *tail = rel;
    for (NSString *key in PublicFolders()) {
        if (![rel isEqualToString:key] && ![rel hasPrefix:[key stringByAppendingString:@"/"]]) continue;
        base = [self.downloadsRoot stringByAppendingPathComponent:PublicFolders()[key]];
        tail = [rel substringFromIndex:key.length];
        break;
    }
    NSString *full = [[base stringByAppendingPathComponent:tail] stringByStandardizingPath];
    if (![full isEqualToString:self.storageRoot] && ![full hasPrefix:[self.storageRoot stringByAppendingString:@"/"]]) return nil;
    NSString *walk = self.storageRoot;
    if ([[NSFileManager.defaultManager attributesOfItemAtPath:walk error:nil].fileType isEqualToString:NSFileTypeSymbolicLink]) return nil;
    for (NSString *part in [[full substringFromIndex:self.storageRoot.length] pathComponents]) {
        if ([part isEqualToString:@"/"] || !part.length) continue;
        walk = [walk stringByAppendingPathComponent:part];
        if ([[NSFileManager.defaultManager attributesOfItemAtPath:walk error:nil].fileType isEqualToString:NSFileTypeSymbolicLink]) return nil;
    }
    return full;
}
@end
static NSString *_Nullable ResolvePath(ForgeStorageContext *context, NSString *relative) { return [context resolve:relative]; }
static NSString *_Nullable SecretRead(ForgeStorageContext *context, NSString *key);
static NSString *_Nullable SourceSecretRead(ForgeStorageContext *context, NSString *key);
static dispatch_queue_t FileWriteQueue(void);

static NSString *MimeType(NSString *path) {
    static NSDictionary<NSString *, NSString *> *types;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        types = @{
            @"html": @"text/html; charset=utf-8", @"htm": @"text/html; charset=utf-8",
            @"js": @"text/javascript; charset=utf-8", @"cjs": @"text/javascript; charset=utf-8",
            @"mjs": @"text/javascript; charset=utf-8", @"css": @"text/css; charset=utf-8",
            @"json": @"application/json; charset=utf-8", @"webmanifest": @"application/manifest+json",
            @"gz": @"application/gzip", @"wasm": @"application/wasm", @"png": @"image/png",
            @"jpg": @"image/jpeg", @"jpeg": @"image/jpeg", @"webp": @"image/webp", @"gif": @"image/gif",
            @"svg": @"image/svg+xml", @"ico": @"image/x-icon", @"ttf": @"font/ttf", @"otf": @"font/otf",
            @"woff": @"font/woff", @"woff2": @"font/woff2", @"txt": @"text/plain; charset=utf-8",
            @"lua": @"text/plain; charset=utf-8", @"xml": @"text/xml; charset=utf-8",
            @"mp3": @"audio/mpeg", @"ogg": @"audio/ogg", @"wav": @"audio/wav", @"m4a": @"audio/mp4",
            @"mp4": @"video/mp4", @"m4v": @"video/mp4", @"webm": @"video/webm", @"mov": @"video/quicktime",
        };
    });
    return types[path.pathExtension.lowercaseString] ?: @"application/octet-stream";
}

static NSDictionary *QueryItems(NSURL *url) {
    NSMutableDictionary *q = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO].queryItems)
        if (item.value) q[item.name] = item.value;
    return q;
}

#pragma mark - scheme handler

@interface ForgeSchemeHandler () <NSURLSessionDataDelegate>
@end

@implementation ForgeSchemeHandler {
    NSString *_site;
    NSHashTable *_stopped;                         // main thread only; holds the tasks (their addresses can't be reused)
    NSURLSession *_net;                            // streamed /__net requests
    NSURLSession *_plain;                          // /__mirror downloads
    NSMutableDictionary<NSNumber *, id<WKURLSchemeTask>> *_netTasks;   // main thread only
    NSMutableSet<NSString *> *_mirrorBusy;         // main thread only
    NSMutableDictionary<NSString *, NSMutableArray<id<WKURLSchemeTask>> *> *_mirrorWaiting;
    NSUInteger _thumbnailRequests;
}

- (instancetype)init {
    return [self initWithStorageContext:[ForgeStorageContext legacyContext]];
}
- (instancetype)initWithStorageContext:(ForgeStorageContext *)context {
    if ((self = [super init])) {
        _storageContext = context;
        _site = context.siteRoot;
        _stopped = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality capacity:16];
        _netTasks = [NSMutableDictionary dictionary];
        _mirrorBusy = [NSMutableSet set];
        _mirrorWaiting = [NSMutableDictionary dictionary];
        NSURLSessionConfiguration *c = context.scoped ? [NSURLSessionConfiguration ephemeralSessionConfiguration] : [NSURLSessionConfiguration defaultSessionConfiguration];
        if (context.scoped) { c.HTTPCookieStorage = nil; c.HTTPShouldSetCookies = NO; c.URLCredentialStorage = nil; c.URLCache = nil; }
        c.HTTPAdditionalHeaders = @{@"User-Agent": kUserAgent};
        c.timeoutIntervalForRequest = 60;
        c.timeoutIntervalForResource = 60 * 30;
        c.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        c.HTTPMaximumConnectionsPerHost = 6;
        _net = [NSURLSession sessionWithConfiguration:c delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        _plain = context.scoped ? [NSURLSession sessionWithConfiguration:c delegate:self delegateQueue:NSOperationQueue.mainQueue] : [NSURLSession sessionWithConfiguration:c];
    }
    return self;
}

- (BOOL)isStopped:(id<WKURLSchemeTask>)task { return [_stopped containsObject:task]; }
- (void)forget:(id<WKURLSchemeTask>)task { [_stopped removeObject:task]; }

- (void)task:(id<WKURLSchemeTask>)task status:(NSInteger)status headers:(NSDictionary *)extra data:(nullable NSData *)data {
    if ([self isStopped:task]) { [self forget:task]; return; }
    NSMutableDictionary *h = [@{ @"Cache-Control": @"no-cache", @"Access-Control-Allow-Origin": @"*",
                                 @"Access-Control-Expose-Headers": @"*" } mutableCopy];
    [h addEntriesFromDictionary:extra];
    if (!h[@"Content-Type"]) h[@"Content-Type"] = @"text/plain; charset=utf-8";
    h[@"Content-Length"] = [NSString stringWithFormat:@"%lu", (unsigned long)data.length];
    NSURL *url = task.request.URL ?: [NSURL URLWithString:@"app://local/"];
    [task didReceiveResponse:[[NSHTTPURLResponse alloc] initWithURL:url statusCode:status HTTPVersion:@"HTTP/1.1" headerFields:h]];
    if (data.length) [task didReceiveData:data];
    [task didFinish];
}

- (void)task:(id<WKURLSchemeTask>)task text:(NSString *)text status:(NSInteger)status {
    [self task:task status:status headers:@{} data:[text dataUsingEncoding:NSUTF8StringEncoding]];
}

/// Serves a file from disk, honoring a Range header (needed by video and audio players).
- (void)task:(id<WKURLSchemeTask>)task serveFile:(NSString *)file head:(BOOL)head {
    NSString *range = [task.request valueForHTTPHeaderField:@"Range"];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:nil];
        BOOL isFile = attrs && ![attrs.fileType isEqualToString:NSFileTypeDirectory];
        unsigned long long size = attrs.fileSize;
        NSInteger status = 200;
        NSMutableDictionary *h = [@{ @"Content-Type": MimeType(file), @"Accept-Ranges": @"bytes" } mutableCopy];
        NSData *data = nil;
        if (isFile) {
            unsigned long long start = 0, end = size ? size - 1 : 0;
            if (range.length && size) {
                NSScanner *s = [NSScanner scannerWithString:range];
                unsigned long long a = 0, b = 0;
                BOOL hasA = NO, hasB = NO;
                if ([s scanString:@"bytes=" intoString:nil]) {
                    hasA = [s scanUnsignedLongLong:&a];
                    if ([s scanString:@"-" intoString:nil]) hasB = [s scanUnsignedLongLong:&b];
                }
                if (!hasA && hasB) { start = b >= size ? 0 : size - b; end = size - 1; }      // bytes=-N
                else if (hasA) { start = a; end = hasB ? MIN(b, size - 1) : size - 1; }
                if (start >= size || start > end) {
                    h[@"Content-Range"] = [NSString stringWithFormat:@"bytes */%llu", size];
                    dispatch_async(dispatch_get_main_queue(), ^{ [self task:task status:416 headers:h data:nil]; });
                    return;
                }
                status = 206;
                h[@"Content-Range"] = [NSString stringWithFormat:@"bytes %llu-%llu/%llu", start, end, size];
            }
            if (head) {
                data = nil;
            } else if (status == 206) {
                NSData *all = [NSData dataWithContentsOfFile:file options:NSDataReadingMappedAlways error:nil];   // clean, mapped pages
                data = all ? [[NSData alloc] initWithBytesNoCopy:(void *)((const char *)all.bytes + start) length:(NSUInteger)(end - start + 1) deallocator:^(void *p, NSUInteger n) { (void)all; }] : nil;
            } else {
                data = [NSData dataWithContentsOfFile:file options:NSDataReadingMappedIfSafe error:nil];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!isFile) { [self task:task text:@"Not found" status:404]; return; }
            if (head) {
                if ([self isStopped:task]) { [self forget:task]; return; }
                h[@"Content-Length"] = [NSString stringWithFormat:@"%llu", size];
                h[@"Access-Control-Allow-Origin"] = @"*";
                h[@"Access-Control-Expose-Headers"] = @"*";
                [task didReceiveResponse:[[NSHTTPURLResponse alloc] initWithURL:task.request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:h]];
                [task didFinish];
                return;
            }
            [self task:task status:status headers:h data:data ?: [NSData data]];
        });
    });
}

- (nullable NSData *)bodyOf:(NSURLRequest *)request {
    if (request.HTTPBody) return request.HTTPBody;
    NSInputStream *stream = request.HTTPBodyStream;
    if (!stream) return nil;
    NSMutableData *body = [NSMutableData data];
    [stream open];
    uint8_t buf[65536];
    NSInteger n;
    while ((n = [stream read:buf maxLength:sizeof buf]) > 0) [body appendBytes:buf length:(NSUInteger)n];
    [stream close];
    return body;
}

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)task {
    if (![self.storageContext isCurrent]) { [self task:task text:@"The Creator workspace changed." status:409]; return; }
    NSURL *url = task.request.URL;
    NSString *path = url.path.length ? url.path : @"/";
    NSString *method = task.request.HTTPMethod.uppercaseString ?: @"GET";

    if ([method isEqualToString:@"OPTIONS"]) {
        [self task:task status:204 headers:@{ @"Access-Control-Allow-Methods": @"GET, HEAD, PUT, POST, DELETE",
                                              @"Access-Control-Allow-Headers": @"*" } data:nil];
        return;
    }
    if ([path isEqualToString:@"/__net"]) { [self net:task]; return; }
    if ([path hasPrefix:@"/__file/"]) { [self file:task path:[path substringFromIndex:8] method:method]; return; }
    if ([path hasPrefix:@"/__mirror/"]) { [self mirror:task path:[path substringFromIndex:10]]; return; }
    if ([path isEqualToString:@"/__thumb"]) { [self thumb:task]; return; }

    if ([path isEqualToString:@"/"]) path = @"/index.html";
    NSString *file = [[_site stringByAppendingPathComponent:[path substringFromIndex:1]] stringByStandardizingPath];
    if (![file hasPrefix:[_site stringByAppendingString:@"/"]]) { [self task:task text:@"Forbidden" status:403]; return; }
    [self task:task serveFile:file head:[method isEqualToString:@"HEAD"]];
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)task {
    NSArray *keys = [_netTasks allKeysForObject:task];
    if (keys.count) {   // a streamed web request: forget it and cancel the download (no "stopped" mark left behind)
        for (NSNumber *key in keys) {
            [_netTasks removeObjectForKey:key];
            [_net getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> *tasks) {
                for (NSURLSessionTask *t in tasks) if (t.taskIdentifier == key.unsignedIntegerValue) [t cancel];
            }];
        }
        return;
    }
    [_stopped addObject:task];
}

#pragma mark /__file

- (void)file:(id<WKURLSchemeTask>)task path:(NSString *)rel method:(NSString *)method {
    if (![@[@"GET", @"HEAD"] containsObject:method] && ![self.storageContext allowsFileMutation]) {
        [self task:task text:@"Finish the current Creator archive operation first." status:409]; return;
    }
    NSString *file = ResolvePath(self.storageContext, rel.stringByRemovingPercentEncoding ?: rel);
    if (!file) { [self task:task text:@"Forbidden" status:403]; return; }
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"]) {
        [self task:task serveFile:file head:[method isEqualToString:@"HEAD"]];
    } else if ([method isEqualToString:@"PUT"] || [method isEqualToString:@"POST"]) {
        NSData *body = [self bodyOf:task.request];
        if (!body) { [self task:task status:411 headers:@{ @"X-Forge-No-Body": @"1" } data:nil]; return; }
        BOOL append = [QueryItems(task.request.URL)[@"append"] isEqualToString:@"1"];
        dispatch_async(FileWriteQueue(), ^{
            if (![self.storageContext isCurrent]) { dispatch_async(dispatch_get_main_queue(), ^{ [self task:task text:@"The Creator workspace changed." status:409]; }); return; }
            [fm createDirectoryAtPath:file.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
            BOOL ok;
            if (append && [fm fileExistsAtPath:file]) {
                NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:file];
                NSError *we = nil; ok = fh && [fh seekToEndReturningOffset:NULL error:&we] && [fh writeData:body error:&we]; [fh closeFile];
            } else {
                ok = [body writeToFile:file atomically:YES];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self task:task status:ok ? 200 : 500 headers:@{ @"Content-Type": @"application/json" }
                      data:[[NSString stringWithFormat:@"{\"ok\":%@,\"bytes\":%lu}", ok ? @"true" : @"false", (unsigned long)body.length] dataUsingEncoding:NSUTF8StringEncoding]];
            });
        });
    } else if ([method isEqualToString:@"DELETE"]) {
        [fm removeItemAtPath:file error:nil];
        [self task:task text:@"{\"ok\":true}" status:200];
    } else {
        [self task:task text:@"Method not allowed" status:405];
    }
}

#pragma mark /__net (streamed)

- (void)net:(id<WKURLSchemeTask>)task {
    NSString *target = QueryItems(task.request.URL)[@"u"];
    NSURL *url = target ? [NSURL URLWithString:target] : nil;
    if (self.storageContext.scoped && ![self.storageContext allowsURL:url]) { [self task:task text:@"This native network request is not authorized." status:403]; return; }
    if (!url || !([url.scheme isEqualToString:@"https"] || [url.scheme isEqualToString:@"http"])) {
        [self task:task text:@"Bad address" status:400];
        return;
    }
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = task.request.HTTPMethod ?: @"GET";
    NSData *body = [self bodyOf:task.request];
    if (body.length) req.HTTPBody = body;
    [task.request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSString *v, BOOL *stop) {
        NSString *lower = k.lowercaseString;
        if ([lower hasPrefix:@"x-forge-header-"]) [req setValue:v forHTTPHeaderField:[k substringFromIndex:15]];
        else if ([lower isEqualToString:@"content-type"] || [lower isEqualToString:@"range"] || [lower isEqualToString:@"accept"])
            [req setValue:v forHTTPHeaderField:k];
    }];
    NSURLRequest *authorized = [self.storageContext authorizedRequest:req];
    if (!authorized) { [self task:task text:@"This native network request is not authorized." status:403]; return; }
    NSURLSessionDataTask *t = [_net dataTaskWithRequest:authorized];
    _netTasks[@(t.taskIdentifier)] = task;
    [t resume];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    id<WKURLSchemeTask> task = _netTasks[@(dataTask.taskIdentifier)];
    if (!task || [self isStopped:task]) { completionHandler(NSURLSessionResponseCancel); return; }
    NSHTTPURLResponse *http = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
    NSMutableDictionary *h = [NSMutableDictionary dictionary];
    for (NSString *k in @[@"Content-Type", @"Content-Length", @"Content-Range", @"Accept-Ranges", @"Last-Modified", @"ETag", @"Content-Disposition"]) {
        NSString *v = [http valueForHTTPHeaderField:k];
        if (v) h[k] = v;
    }
    // NSURLSession already unpacked gzip bodies: the old length would be wrong
    if ([http valueForHTTPHeaderField:@"Content-Encoding"]) [h removeObjectForKey:@"Content-Length"];
    h[@"Access-Control-Allow-Origin"] = @"*";
    h[@"Access-Control-Expose-Headers"] = @"*";
    h[@"Cache-Control"] = @"no-cache";
    h[@"X-Forge-Final-Url"] = response.URL.absoluteString ?: @"";
    h[@"X-Forge-Status"] = [NSString stringWithFormat:@"%ld", (long)(http ? http.statusCode : 200)];
    [task didReceiveResponse:[[NSHTTPURLResponse alloc] initWithURL:task.request.URL statusCode:http ? http.statusCode : 200
                                                        HTTPVersion:@"HTTP/1.1" headerFields:h]];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    id<WKURLSchemeTask> task = _netTasks[@(dataTask.taskIdentifier)];
    if (!task || [self isStopped:task]) { [dataTask cancel]; return; }
    [task didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)t didCompleteWithError:(NSError *)error {
    id<WKURLSchemeTask> task = _netTasks[@(t.taskIdentifier)];
    [_netTasks removeObjectForKey:@(t.taskIdentifier)];
    if (!task) return;
    if ([self isStopped:task]) { [self forget:task]; return; }
    if (error) {
        if (!t.response) { [self task:task text:[NSString stringWithFormat:@"Network error: %@", error.localizedDescription] status:502]; return; }
        [task didFailWithError:error];
    } else {
        [task didFinish];
    }
}

#pragma mark /__mirror (saved copies of web files)

- (void)mirror:(id<WKURLSchemeTask>)task path:(NSString *)rest {
    NSRange slash = [rest rangeOfString:@"/"];
    NSString *host = slash.location == NSNotFound ? rest : [rest substringToIndex:slash.location];
    NSString *p = slash.location == NSNotFound ? @"" : [rest substringFromIndex:slash.location + 1];
    NSString *decoded = p.stringByRemovingPercentEncoding ?: p;
    if (!decoded.length || [decoded hasSuffix:@"/"]) decoded = [decoded stringByAppendingString:@"index.html"];
    NSCharacterSet *bad = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789.-"] invertedSet];
    if (!host.length || [host.lowercaseString rangeOfCharacterFromSet:bad].location != NSNotFound) { [self task:task text:@"Bad host" status:400]; return; }
    NSString *file = ResolvePath(self.storageContext, [NSString stringWithFormat:@"cache/mirror/%@/%@", host.lowercaseString, decoded]);
    if (!file) { [self task:task text:@"Forbidden" status:403]; return; }
    BOOL isDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDir] && !isDir) {
        [self task:task serveFile:file head:[task.request.HTTPMethod.uppercaseString isEqualToString:@"HEAD"]];
        return;
    }
    // several requests for the same file share one download
    NSMutableArray *waiting = _mirrorWaiting[file];
    if (waiting) { [waiting addObject:task]; return; }
    _mirrorWaiting[file] = [NSMutableArray arrayWithObject:task];

    NSString *query = task.request.URL.query;
    NSString *remote = [NSString stringWithFormat:@"https://%@/%@%@%@", host, p, query.length ? @"?" : @"", query ?: @""];
    NSURL *remoteURL = [NSURL URLWithString:remote];
    if (!remoteURL) { [self finishMirror:file status:400 message:@"Bad address"]; return; }
    if (self.storageContext.scoped && ![self.storageContext allowsURL:remoteURL]) { [self finishMirror:file status:403 message:@"This native network request is not authorized."]; return; }
    NSURLRequest *authorized = [self.storageContext authorizedRequest:[NSURLRequest requestWithURL:remoteURL]];
    if (!authorized) { [self finishMirror:file status:403 message:@"This native network request is not authorized."]; return; }
    [[_plain downloadTaskWithRequest:authorized completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 0;
        BOOL saved = NO;
        if (!error && location && status >= 200 && status < 300 && [self.storageContext isCurrent]) {
            NSFileManager *fm = [NSFileManager defaultManager];
            [fm createDirectoryAtPath:file.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
            [fm removeItemAtPath:file error:nil];
            saved = [fm moveItemAtURL:location toURL:[NSURL fileURLWithPath:file] error:nil];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishMirror:file status:saved ? 200 : (status ?: 502) message:error.localizedDescription ?: @"Not available"];
        });
    }] resume];
}

#pragma mark /__thumb (character thumbnails from the saved previews, like Android's OfflineLibrary.intercept)

- (void)thumb:(id<WKURLSchemeTask>)task {
    NSString *u = QueryItems(task.request.URL)[@"u"];
    if (![u hasPrefix:@"https://dokkan-eclipse.com/cdn/uncompressed/character/thumb/"] || ![u hasSuffix:@".png"] || [u containsString:@"?"] || [u containsString:@".."]) {
        [self task:task text:@"Not found" status:404]; return;
    }
    NSData *ud = [u dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char md[CC_SHA256_DIGEST_LENGTH]; CC_SHA256(ud.bytes, (CC_LONG)ud.length, md);
    NSMutableString *hex = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) [hex appendFormat:@"%02x", md[i]];
    NSString *base = [ResolvePath(self.storageContext, @"preview-cache") stringByAppendingPathComponent:hex];
    if (!base) { [self task:task text:@"The Creator workspace changed." status:409]; return; }
    NSString *body = [base stringByAppendingString:@".body"], *meta = [base stringByAppendingString:@".json"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:body] && [fm fileExistsAtPath:meta]) { [self task:task serveFile:body head:NO]; return; }
    NSDictionary *settings = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[ResolvePath(self.storageContext, @"preview-cache") stringByAppendingPathComponent:@"settings.json"]] ?: [NSData data] options:0 error:nil];
    if ([settings isKindOfClass:[NSDictionary class]] && B(settings[@"offline"])) { [self task:task text:@"Not saved" status:404]; return; }
    NSURL *tu = [NSURL URLWithString:u];
    if (!tu) { [self task:task text:@"Not found" status:404]; return; }
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:tu];
    [req setValue:@"DokkanUnitForge/2.7" forHTTPHeaderField:@"User-Agent"];
    NSURLRequest *authorized = [self.storageContext authorizedRequest:req];
    if (!authorized) { [self task:task text:@"This native network request is not authorized." status:403]; return; }
    _thumbnailRequests++;
    [[_plain dataTaskWithRequest:authorized completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 0;
        BOOL ok = !error && status == 200 && data.length > 0 && data.length <= 4 * 1024 * 1024 && [self.storageContext isCurrent];
        if (ok) {   // keep it for next time (and for offline use)
            [fm createDirectoryAtPath:body.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
            [data writeToFile:body atomically:YES];
            NSData *j = [NSJSONSerialization dataWithJSONObject:@{ @"url": u, @"type": @"image/png" } options:0 error:nil];
            [j writeToFile:meta atomically:YES];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self->_thumbnailRequests) self->_thumbnailRequests--;
            if (ok) [self task:task status:200 headers:@{ @"Content-Type": @"image/png" } data:data];
            else [self task:task text:@"Not available" status:status ?: 502];
        });
    }] resume];
}

- (void)finishMirror:(NSString *)file status:(NSInteger)status message:(NSString *)message {
    NSArray *tasks = _mirrorWaiting[file] ?: @[];
    [_mirrorWaiting removeObjectForKey:file];
    for (id<WKURLSchemeTask> t in tasks) {
        if (status == 200) [self task:t serveFile:file head:NO];
        else [self task:t text:message status:status];
    }
}
- (void)invalidate { [_net invalidateAndCancel]; [_plain invalidateAndCancel]; }
- (BOOL)hasActiveRequests { return _netTasks.count || _mirrorWaiting.count || _thumbnailRequests; }
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *_Nullable))completionHandler {
    (void)session; (void)task; (void)response;
    completionHandler([self.storageContext authorizedRequest:request]);
}
@end

#pragma mark - SQLite (the same game databases and queries as the Android app)

static NSMutableDictionary<NSString *, NSValue *> *OpenDatabases(void) {
    static NSMutableDictionary *dbs; static dispatch_once_t once;
    dispatch_once(&once, ^{ dbs = [NSMutableDictionary dictionary]; });
    return dbs;
}

static dispatch_queue_t SqlQueue(void) {
    static dispatch_queue_t q; static dispatch_once_t once;
    dispatch_once(&once, ^{ q = dispatch_queue_create("forge.sqlite", DISPATCH_QUEUE_SERIAL); });
    return q;
}

/// Runs on SqlQueue. Opens read-only unless writable is set; cached per file.
static sqlite3 *_Nullable OpenDb(NSString *file, BOOL writable, NSString **error) {
    NSString *key = [NSString stringWithFormat:@"%@|%d", file, writable];
    NSValue *v = OpenDatabases()[key];
    if (v) return (sqlite3 *)v.pointerValue;
    if (![[NSFileManager defaultManager] fileExistsAtPath:file]) { *error = @"The game database is missing."; return NULL; }
    sqlite3 *db = NULL;
    int flags = writable ? (SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE) : SQLITE_OPEN_READONLY;
    if (sqlite3_open_v2(file.fileSystemRepresentation, &db, flags | SQLITE_OPEN_NOMUTEX, NULL) != SQLITE_OK) {
        *error = [NSString stringWithFormat:@"Couldn't open the game database: %s", db ? sqlite3_errmsg(db) : "unknown"];
        if (db) sqlite3_close(db);
        return NULL;
    }
    OpenDatabases()[key] = [NSValue valueWithPointer:db];
    return db;
}

static void CloseDb(NSString *file) {
    for (NSString *key in OpenDatabases().allKeys) {
        if ([key hasPrefix:[file stringByAppendingString:@"|"]]) {
            sqlite3_close_v2((sqlite3 *)OpenDatabases()[key].pointerValue);
            [OpenDatabases() removeObjectForKey:key];
        }
    }
}

static id SqlValue(sqlite3_stmt *st, int i) {
    switch (sqlite3_column_type(st, i)) {
        case SQLITE_INTEGER: return @(sqlite3_column_int64(st, i));
        case SQLITE_FLOAT: return @(sqlite3_column_double(st, i));
        case SQLITE_TEXT: return [NSString stringWithUTF8String:(const char *)sqlite3_column_text(st, i)] ?: @"";
        case SQLITE_BLOB: {
            int n = sqlite3_column_bytes(st, i);
            NSData *d = [NSData dataWithBytes:sqlite3_column_blob(st, i) length:(NSUInteger)n];
            NSString *text = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
            return text ?: @{ @"base64": [d base64EncodedStringWithOptions:0] };
        }
        default: return [NSNull null];
    }
}

/// {db, sql, params:[…], writable} → {columns:[…], rows:[[…]], changes}. Several statements: use "batch" with sqls.
static NSDictionary *_Nullable ExecuteSql(sqlite3 *db, NSString *sql, NSArray *params,
    NSUInteger maxRows, NSUInteger maxCellBytes, NSString **error) {
    sqlite3_stmt *st = NULL;
    if (sqlite3_prepare_v2(db, sql.UTF8String, -1, &st, NULL) != SQLITE_OK) {
        *error = [NSString stringWithFormat:@"%s", sqlite3_errmsg(db)];
        return nil;
    }
    int i = 1;
    for (id p in params) {
        if ([p isKindOfClass:[NSNull class]]) sqlite3_bind_null(st, i);
        else if ([p isKindOfClass:[NSNumber class]]) {
            const char *t = [p objCType];
            if (strcmp(t, "d") == 0 || strcmp(t, "f") == 0) sqlite3_bind_double(st, i, [p doubleValue]);
            else sqlite3_bind_int64(st, i, [p longLongValue]);
        } else sqlite3_bind_text(st, i, [[p description] UTF8String], -1, SQLITE_TRANSIENT);
        i++;
    }
    NSMutableArray *columns = [NSMutableArray array];
    for (int c = 0; c < sqlite3_column_count(st); c++) [columns addObject:[NSString stringWithUTF8String:sqlite3_column_name(st, c)] ?: @""];
    NSMutableArray *rows = [NSMutableArray array];
    int rc;
    while ((rc = sqlite3_step(st)) == SQLITE_ROW) {
        if (maxRows && rows.count >= maxRows) { *error = @"The source inspection result is too large."; sqlite3_finalize(st); return nil; }
        NSMutableArray *row = [NSMutableArray arrayWithCapacity:columns.count];
        for (int c = 0; c < (int)columns.count; c++) {
            if (maxCellBytes && (sqlite3_column_type(st,c)==SQLITE_TEXT || sqlite3_column_type(st,c)==SQLITE_BLOB) &&
                (NSUInteger)sqlite3_column_bytes(st,c)>maxCellBytes) { *error=@"The source inspection field is too large."; sqlite3_finalize(st); return nil; }
            [row addObject:SqlValue(st, c)];
        }
        [rows addObject:row];
    }
    if (rc != SQLITE_DONE) {
        *error = [NSString stringWithFormat:@"%s", sqlite3_errmsg(db)];
        sqlite3_finalize(st);
        return nil;
    }
    sqlite3_finalize(st);
    return @{ @"columns": columns, @"rows": rows, @"changes": @(sqlite3_changes(db)) };
}
static NSDictionary *_Nullable RunSql(NSString *file, NSString *sql, NSArray *params, BOOL writable, NSString **error) {
    sqlite3 *db=OpenDb(file,writable,error);
    return db?ExecuteSql(db,sql,params,0,0,error):nil;
}

typedef struct { unsigned budget; } ForgeSourceInspection;
static int SourceInspectionProgress(void *opaque) {
    ForgeSourceInspection *state=opaque;return state->budget--==0;
}
static int SourceInspectionAuthorize(void *opaque,int action,const char *a,const char *b,const char *database,const char *trigger) {
    (void)opaque;(void)trigger;
    if(database&&strcmp(database,"main")&&strcmp(database,"temp"))return SQLITE_DENY;
    switch(action) {
        case SQLITE_SELECT: return SQLITE_OK;
        case SQLITE_READ:
            if(!a)return SQLITE_DENY;
            return (!strcmp(a,"sqlite_master")||!strcmp(a,"sqlite_schema")||!strcmp(a,"cards"))?SQLITE_OK:SQLITE_DENY;
        case SQLITE_FUNCTION:return b&&!strcmp(b,"count")?SQLITE_OK:SQLITE_DENY;
        case SQLITE_PRAGMA:
            if(!a)return SQLITE_DENY;
            if(!strcmp(a,"quick_check"))return b&&!strcmp(b,"1")?SQLITE_OK:SQLITE_DENY;
            if(!strcmp(a,"table_info")||!strcmp(a,"table_list"))return SQLITE_OK;
            return SQLITE_DENY;
        default:return SQLITE_DENY;
    }
}

/// The game databases ship inside the app; the first time, they're copied to the phone's storage
/// (so "Update to the newest characters" can replace them later).
static void InstallBundledDatabases(ForgeStorageContext *context) {
    // The game databases ship inside the app. They are linked (not copied: 200 MB saved) into the
    // app's storage; "Update to the newest characters" stores new ones beside them (databases/).
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *bundled = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"db"];
    NSString *dir = ResolvePath(context, @"db");
    [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    for (NSString *name in [fm contentsOfDirectoryAtPath:bundled error:nil] ?: @[]) {
        if (![name hasSuffix:@".db"]) continue;
        NSString *src = [bundled stringByAppendingPathComponent:name], *dest = [dir stringByAppendingPathComponent:name];
        NSString *link = [fm destinationOfSymbolicLinkAtPath:dest error:nil];
        if ([link isEqualToString:src]) continue;   // the app's location changes after each update
        CloseDb(dest);
        [fm removeItemAtPath:dest error:nil];
        [fm createSymbolicLinkAtPath:dest withDestinationPath:src error:nil];
    }
}

#pragma mark - Sparking: XXH64, SQLCipher 4 pages, SPRK (AES-256-CTR)

static const uint64_t XP1 = 11400714785074694791ULL, XP2 = 14029467366897019727ULL, XP3 = 1609587929392839161ULL, XP4 = 9650029242287828579ULL, XP5 = 2870177450012600261ULL;
static inline uint64_t xrotl(uint64_t x, int r) { return (x << r) | (x >> (64 - r)); }
static inline uint64_t xround(uint64_t acc, uint64_t lane) { acc += lane * XP2; acc = xrotl(acc, 31); return acc * XP1; }
static inline uint64_t xmerge(uint64_t h, uint64_t v) { h ^= xround(0, v); return h * XP1 + XP4; }
typedef struct { uint64_t v[4]; uint8_t buf[32]; size_t used; uint64_t total; } XXH;
static void xxhInit(XXH *x) { x->v[0] = XP1 + XP2; x->v[1] = XP2; x->v[2] = 0; x->v[3] = 0 - XP1; x->used = 0; x->total = 0; }
static uint64_t rd64(const uint8_t *p) { uint64_t v; memcpy(&v, p, 8); return v; }
static uint32_t rd32(const uint8_t *p) { uint32_t v; memcpy(&v, p, 4); return v; }
static void xxhUpdate(XXH *x, const uint8_t *b, size_t n) {
    x->total += n;
    if (x->used + n < 32) { memcpy(x->buf + x->used, b, n); x->used += n; return; }
    if (x->used) { size_t k = 32 - x->used; memcpy(x->buf + x->used, b, k); for (int i = 0; i < 4; i++) x->v[i] = xround(x->v[i], rd64(x->buf + 8 * i)); b += k; n -= k; x->used = 0; }
    while (n >= 32) { for (int i = 0; i < 4; i++) x->v[i] = xround(x->v[i], rd64(b + 8 * i)); b += 32; n -= 32; }
    if (n) { memcpy(x->buf, b, n); x->used = n; }
}
static uint64_t xxhDigest(XXH *x) {
    uint64_t h;
    if (x->total >= 32) { h = xrotl(x->v[0], 1) + xrotl(x->v[1], 7) + xrotl(x->v[2], 12) + xrotl(x->v[3], 18); for (int i = 0; i < 4; i++) h = xmerge(h, x->v[i]); }
    else h = XP5;
    h += x->total;
    size_t i = 0;
    for (; i + 8 <= x->used; i += 8) h = xrotl(h ^ xround(0, rd64(x->buf + i)), 27) * XP1 + XP4;
    if (i + 4 <= x->used) { h = xrotl(h ^ ((uint64_t)rd32(x->buf + i) * XP1), 23) * XP2 + XP3; i += 4; }
    for (; i < x->used; i++) h = xrotl(h ^ (x->buf[i] * XP5), 11) * XP1;
    h ^= h >> 33; h *= XP2; h ^= h >> 29; h *= XP3; h ^= h >> 32;
    return h;
}

/// SQLCipher (3 or 4) page decryption into a plain SQLite file. Returns nil or the error message.
static NSString *_Nullable SqlCipherDecrypt(NSString *inPath, NSString *outPath, NSData *pass, int mode) {
    int pageSize = mode == 4 ? 4096 : 1024, reserve = mode == 4 ? 80 : 48, hmacLen = mode == 4 ? 64 : 20;
    unsigned iter = mode == 4 ? 256000 : 64000;
    CCPseudoRandomAlgorithm prf = mode == 4 ? kCCPRFHmacAlgSHA512 : kCCPRFHmacAlgSHA1;
    CCHmacAlgorithm halg = mode == 4 ? kCCHmacAlgSHA512 : kCCHmacAlgSHA1;
    if (pass.length < 1 || pass.length > 4096) return @"The imported APK did not provide a supported database format.";
    NSDictionary *a = [[NSFileManager defaultManager] attributesOfItemAtPath:inPath error:nil];
    unsigned long long len = a.fileSize;
    if (!a || len < (unsigned long long)pageSize || len > 512ULL * 1024 * 1024 || len % pageSize) return @"This legacy database is incomplete or uses an unsupported page format.";
    NSFileHandle *in = [NSFileHandle fileHandleForReadingAtPath:inPath];
    NSString *tmp = [[outPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"legacy-db-%@.tmp", [NSUUID UUID].UUIDString]];
    [[NSFileManager defaultManager] createFileAtPath:tmp contents:nil attributes:nil];
    NSFileHandle *out = [NSFileHandle fileHandleForWritingAtPath:tmp];
    if (!in || !out) return @"Choose a separate safe database output file.";
    NSData *first = [in readDataOfLength:(NSUInteger)pageSize];
    uint8_t salt[16], macSalt[16], encKey[32], macKey[32];
    memcpy(salt, first.bytes, 16);
    for (int i = 0; i < 16; i++) macSalt[i] = salt[i] ^ 0x3a;
    CCKeyDerivationPBKDF(kCCPBKDF2, pass.bytes, pass.length, salt, 16, prf, iter, encKey, 32);
    CCKeyDerivationPBKDF(kCCPBKDF2, (const char *)encKey, 32, macSalt, 16, prf, 2, macKey, 32);
    [in seekToFileOffset:0];
    int usable = pageSize - reserve;
    uint8_t *plain = malloc((size_t)pageSize), *zero = calloc((size_t)reserve, 1), mac[64];
    NSString *err = nil;
    for (unsigned long long n = 1; n <= len / pageSize; n++) {
        @autoreleasepool {
            NSData *pd = [in readDataOfLength:(NSUInteger)pageSize];
            if (pd.length != (NSUInteger)pageSize) { err = @"The legacy database changed during import."; break; }
            const uint8_t *p = pd.bytes;
            int off = n == 1 ? 16 : 0;
            CCHmacContext ctx;
            CCHmacInit(&ctx, halg, macKey, 32);
            CCHmacUpdate(&ctx, p + off, (size_t)(usable + 16 - off));
            uint32_t pn = (uint32_t)n;   // little-endian page number
            uint8_t pnb[4] = { pn & 255, (pn >> 8) & 255, (pn >> 16) & 255, (pn >> 24) & 255 };
            CCHmacUpdate(&ctx, pnb, 4);
            CCHmacFinal(&ctx, mac);
            if (memcmp(mac, p + usable + 16, (size_t)hmacLen) != 0) { err = @"Database authentication failed. The file is damaged or does not match this imported APK's supported format."; break; }
            size_t moved = 0;
            CCCrypt(kCCDecrypt, kCCAlgorithmAES, 0, encKey, 32, p + usable, p + off, (size_t)(usable - off), plain, (size_t)pageSize, &moved);
            if (n == 1) {
                if (((plain[0] << 8) | plain[1]) != (pageSize == 65536 ? 1 : pageSize) || plain[4] < reserve || plain[5] != 64 || plain[6] != 32 || plain[7] != 32) { err = @"The decrypted database has an unsupported SQLite header."; break; }
                uint8_t magic[16] = { 'S','Q','L','i','t','e',' ','f','o','r','m','a','t',' ','3',0 };
                if (![out writeData:[NSData dataWithBytes:magic length:16] error:nil]) { err = @"Could not save the authenticated database."; break; }
            }
            if (![out writeData:[NSData dataWithBytes:plain length:(NSUInteger)(usable - off)] error:nil] ||
                ![out writeData:[NSData dataWithBytes:zero length:(NSUInteger)reserve] error:nil]) { err = @"Could not save the authenticated database."; break; }
        }
    }
    free(plain); free(zero);
    memset(encKey, 0, 32); memset(macKey, 0, 32);
    [in closeFile]; [out synchronizeFile]; [out closeFile];
    if (err) { [[NSFileManager defaultManager] removeItemAtPath:tmp error:nil]; return err; }
    [[NSFileManager defaultManager] removeItemAtPath:outPath error:nil];
    if (![[NSFileManager defaultManager] moveItemAtPath:tmp toPath:outPath error:nil]) { [[NSFileManager defaultManager] removeItemAtPath:tmp error:nil]; return @"Could not save the authenticated database."; }
    return nil;
}

#pragma mark - ForgeHost (files, downloads, keychain, share)

@interface ForgeDownload : NSObject
@property (nonatomic, copy) NSString *ident;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) void (^reply)(id _Nullable, NSString *_Nullable);
@property (nonatomic) BOOL keepErrors;
@property (nonatomic) BOOL noRedirect;
@property (nonatomic) BOOL wantsProgress;
@property (nonatomic) CFAbsoluteTime lastProgress;
@property (nonatomic) BOOL saved;
@property (nonatomic, copy) NSString *moveError;
@end
@implementation ForgeDownload
@end

@interface ForgeHost () <NSURLSessionDownloadDelegate>
@end

@implementation ForgeHost {
    NSURLSession *_session;
    NSMutableDictionary<NSNumber *, ForgeDownload *> *_downloads;   // guarded by @synchronized(_downloads): downloads run off the main thread
    NSURLSession *_aiSession;
    NSMutableDictionary<NSString *, NSURLSessionTask *> *_aiTasks;
    nw_path_monitor_t _monitor;
    BOOL _netKnown, _netConnected, _netMetered, _netWifi, _wifiOnlyDownloads;
}

+ (NSString *)storageRoot { return [ForgeStorageContext legacyContext].storageRoot; }
+ (NSString *)resolve:(NSString *)relative { return ResolvePath([ForgeStorageContext legacyContext], relative); }
+ (dispatch_queue_t)fileMutationQueue { return FileWriteQueue(); }
- (BOOL)hasActiveDownloads { @synchronized(_downloads) { return _downloads.count != 0; } }
- (void)performAfterFileWrites:(dispatch_block_t)block { dispatch_async(FileWriteQueue(), ^{ dispatch_async(dispatch_get_main_queue(), block); }); }
- (void)inspectSourceDatabase:(NSString *)relative kind:(NSString *)kind table:(NSString *)table
    identityIsCurrent:(BOOL (^)(void))identity reply:(void (^)(id, NSString *))reply {
    NSString *file=ResolvePath(self.storageContext,relative);
    NSSet *tables=[NSSet setWithArray:@[@"cards",@"card_categories",@"link_skills",@"leader_skill_sets",@"leader_skills",@"passive_skill_sets",@"passive_skills",@"passive_skill_set_relations"]];
    NSString *query=nil;NSArray *params=@[];
    if([kind isEqualToString:@"quickCheck"])query=@"PRAGMA quick_check(1)";
    else if([kind isEqualToString:@"tableType"]&&[tables containsObject:table]){query=@"SELECT type FROM sqlite_schema WHERE name=?1";params=@[table];}
    else if([kind isEqualToString:@"tableInfo"]&&[tables containsObject:table])query=[NSString stringWithFormat:@"PRAGMA table_info(\"%@\")",table];
    else if([kind isEqualToString:@"cardCount"])query=@"SELECT count(*) AS n FROM cards";
    if(!self.storageContext.scoped||!file||!query||!identity||!identity()){reply(nil,@"The staged source inspection is not admitted.");return;}
    dispatch_async(SqlQueue(), ^{
        sqlite3 *db=NULL;NSString *failure=nil;NSDictionary *result=nil;
        if(![self.storageContext isCurrent]||!identity()){failure=@"The staged source changed.";goto finish;}
        if(sqlite3_open_v2(file.fileSystemRepresentation,&db,SQLITE_OPEN_READONLY|SQLITE_OPEN_NOMUTEX|SQLITE_OPEN_NOFOLLOW,NULL)!=SQLITE_OK||sqlite3_db_readonly(db,"main")!=1){failure=@"The staged source could not be opened read-only.";goto finish;}
#ifndef SQLITE_OMIT_LOAD_EXTENSION
        sqlite3_enable_load_extension(db,0);
#endif
        sqlite3_drop_modules(db,NULL);
        sqlite3_db_config(db,SQLITE_DBCONFIG_DEFENSIVE,1,NULL);sqlite3_db_config(db,SQLITE_DBCONFIG_TRUSTED_SCHEMA,0,NULL);
        sqlite3_limit(db,SQLITE_LIMIT_LENGTH,1024*1024);sqlite3_limit(db,SQLITE_LIMIT_SQL_LENGTH,4096);sqlite3_limit(db,SQLITE_LIMIT_COLUMN,1024);
        ForgeSourceInspection inspection={10000};sqlite3_progress_handler(db,1000,SourceInspectionProgress,&inspection);
        sqlite3_set_authorizer(db,SourceInspectionAuthorize,NULL);
        if([kind isEqualToString:@"cardCount"]){
            NSDictionary *list=ExecuteSql(db,@"PRAGMA table_list",@[],4096,4096,&failure);BOOL ordinary=NO;
            for(NSArray *row in list[@"rows"])if(row.count>=3&&[row[0] isEqual:@"main"]&&[row[1] isEqual:@"cards"]&&[row[2] isEqual:@"table"])ordinary=YES;
            if(!ordinary){failure=@"The source cards must be an ordinary data table.";goto finish;}
        }
        result=ExecuteSql(db,query,params,4096,4096,&failure);
        if(!identity()){result=nil;failure=@"The staged source changed during inspection.";}
finish:if(db)sqlite3_close_v2(db);
        dispatch_async(dispatch_get_main_queue(), ^{reply(result,result?nil:(failure?:@"Source inspection failed."));});
    });
}

- (instancetype)init {
    return [self initWithStorageContext:[ForgeStorageContext legacyContext]];
}
- (instancetype)initWithStorageContext:(ForgeStorageContext *)context {
    if ((self = [super init])) {
        _storageContext = context;
        NSURLSessionConfiguration *c = context.scoped ? [NSURLSessionConfiguration ephemeralSessionConfiguration] : [NSURLSessionConfiguration defaultSessionConfiguration];
        if (context.scoped) { c.HTTPCookieStorage = nil; c.HTTPShouldSetCookies = NO; c.URLCredentialStorage = nil; c.URLCache = nil; }
        c.HTTPAdditionalHeaders = @{@"User-Agent": kUserAgent};
        c.timeoutIntervalForRequest = 60;
        c.timeoutIntervalForResource = 60 * 60 * 3;
        c.HTTPMaximumConnectionsPerHost = 24;   // downloads: 24 files at a time (matches ios-offline.js)
        // Downloads are handled on their own background queue, not the main thread: with 48 files at once, moving
        // finished files and progress on the main thread froze scrolling and taps (iPhone Duo, 27 Oct 2026).
        NSOperationQueue *dq = [NSOperationQueue new];
        dq.maxConcurrentOperationCount = 1;
        dq.qualityOfService = NSQualityOfServiceUtility;
        dq.name = @"forge.downloads";
        _session = [NSURLSession sessionWithConfiguration:c delegate:self delegateQueue:dq];
        _downloads = [NSMutableDictionary dictionary];
        NSURLSessionConfiguration *ai = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        if (context.scoped) { ai.HTTPCookieStorage = nil; ai.HTTPShouldSetCookies = NO; ai.URLCredentialStorage = nil; ai.URLCache = nil; }
        ai.timeoutIntervalForRequest = 240;
        ai.timeoutIntervalForResource = 300;
        _aiSession = [NSURLSession sessionWithConfiguration:ai delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        _aiTasks = [NSMutableDictionary dictionary];
        // network state for "Wi-Fi only" downloads (Android: ConnectivityManager / metered)
        _monitor = nw_path_monitor_create();
        nw_path_monitor_set_queue(_monitor, dispatch_get_main_queue());
        __weak ForgeHost *weakSelf = self;
        nw_path_monitor_set_update_handler(_monitor, ^(nw_path_t path) {
            ForgeHost *me = weakSelf; if (!me) return;
            me->_netKnown = YES;
            me->_netConnected = nw_path_get_status(path) == nw_path_status_satisfied;
            me->_netMetered = nw_path_is_expensive(path) || nw_path_is_constrained(path);
            me->_netWifi = me->_netConnected && !me->_netMetered && (nw_path_uses_interface_type(path, nw_interface_type_wifi) || nw_path_uses_interface_type(path, nw_interface_type_wired));
        });
        nw_path_monitor_start(_monitor);
    }
    return self;
}

- (void)invalidate {
    [self.storageContext invalidate];
    [_session invalidateAndCancel]; [_aiSession invalidateAndCancel];
    if (_monitor) { nw_path_monitor_cancel(_monitor); _monitor = nil; }
}

- (void)emit:(NSDictionary *)detail {
    NSData *json = [NSJSONSerialization dataWithJSONObject:detail options:0 error:nil];
    if (!json) return;
    NSString *js = [NSString stringWithFormat:@"dispatchEvent(new CustomEvent('forge-host',{detail:%@}))",
                    [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]];
    [self.webView evaluateJavaScript:js completionHandler:nil];
}

static NSDictionary *Entry(NSString *name, NSDictionary *attrs) {
    BOOL dir = [attrs.fileType isEqualToString:NSFileTypeDirectory];
    return @{ @"name": name, @"dir": @(dir), @"size": @(dir ? 0 : attrs.fileSize),
              @"mtime": @((long long)([attrs.fileModificationDate timeIntervalSince1970] * 1000)) };
}

// File work (listing, saving, moving, deleting) used to run on the main thread, where it stalled the screen while
// many downloads finished at once or a big folder was listed. It now runs off the main thread; answers go back to
// the page on the main thread as before. Changes go through one queue (same order as sent), reads may run side by side.
static dispatch_queue_t FileWriteQueue(void) {
    static dispatch_queue_t q; static dispatch_once_t once;
    dispatch_once(&once, ^{ q = dispatch_queue_create("forge.files", DISPATCH_QUEUE_SERIAL); });
    return q;
}

- (void)userContentController:(WKUserContentController *)controller didReceiveScriptMessage:(WKScriptMessage *)message
                 replyHandler:(void (^)(id _Nullable, NSString *_Nullable))reply {
    NSDictionary *m = [message.body isKindOfClass:[NSDictionary class]] ? message.body : @{};
    NSString *op0 = [m[@"op"] isKindOfClass:[NSString class]] ? m[@"op"] : @"";
    static NSSet *readOps, *writeOps;
    static dispatch_once_t onceOps;
    dispatch_once(&onceOps, ^{ readOps = [NSSet setWithArray:@[@"list", @"stat"]]; writeOps = [NSSet setWithArray:@[@"remove", @"mkdir", @"move", @"write"]]; });
    BOOL bgRead = [readOps containsObject:op0], bgWrite = [writeOps containsObject:op0];
    if (bgRead || bgWrite) {
        void (^mainReply)(id, NSString *) = ^(id v, NSString *e) { dispatch_async(dispatch_get_main_queue(), ^{ reply(v, e); }); };
        dispatch_async(bgWrite ? FileWriteQueue() : dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{ [self handleMessage:m reply:mainReply]; });
        return;
    }
    [self handleMessage:m reply:reply];
}

- (void)handleMessage:(NSDictionary *)m reply:(void (^)(id _Nullable, NSString *_Nullable))reply {
    if (![self.storageContext isCurrent]) { reply(nil, @"The Creator workspace changed."); return; }
    NSString *op = [m[@"op"] isKindOfClass:[NSString class]] ? m[@"op"] : @"";
    if (self.storageContext.scoped && [@[@"remove", @"mkdir", @"move", @"write", @"download", @"copy", @"share", @"sqlcipherDecrypt", @"sprkEncode", @"sprkDecode"] containsObject:op] && ![self.storageContext allowsFileMutation]) {
        reply(nil, @"Finish the current Creator archive operation first."); return;
    }
    if (self.storageContext.scoped && [@[@"sql", @"sqlBatch", @"sqlClose", @"installDatabases"] containsObject:op]) {
        reply(nil, @"Database access belongs to the bound Creator session."); return;
    }
    if (self.storageContext.scoped && [@[@"sqlcipherDecrypt", @"sprkEncode", @"sprkDecode"] containsObject:op] &&
        (!self.sourceCodecAuthorization || !self.sourceCodecAuthorization())) {
        reply(nil, @"Import your admitted personal Sparking APK before using this source codec."); return;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = m[@"path"] ? ResolvePath(self.storageContext, m[@"path"]) : nil;
    if (m[@"path"] && !path) { reply(nil, @"That file location isn't allowed."); return; }
    static NSSet *needsPath;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ needsPath = [NSSet setWithArray:@[@"list", @"stat", @"usage", @"remove", @"mkdir", @"move", @"write", @"download", @"share", @"sha256", @"copy", @"hashes", @"sqlcipherDecrypt", @"sprkDecode", @"sprkEncode"]]; });
    if ([needsPath containsObject:op] && !path) { reply(nil, @"Missing file location."); return; }
    if (self.storageContext.scoped && [path isEqualToString:self.storageContext.storageRoot] &&
        ![@[@"list", @"stat", @"usage", @"remove", @"mkdir"] containsObject:op]) {
        reply(nil, @"Choose a file inside the Creator workspace."); return;
    }

    if ([op hasPrefix:@"player"] || [op hasPrefix:@"server"] || [op isEqualToString:@"saveDocument"] || [op hasPrefix:@"gameFolder"]) {
        if (!self.player) { reply(nil, @"The animation player is not ready yet."); return; }
        [(ForgePlayer *)self.player handle:op message:m reply:reply];
        return;
    }
    if ([op isEqualToString:@"display"]) {   // what the phone really reports (for checking both displays)
        UIView *v = self.presenter.view;
        UIWindowScene *ws = v.window.windowScene;
        UIScreen *sc = ws.screen ?: [UIScreen mainScreen];
        UIEdgeInsets sa = v.safeAreaInsets;
        struct utsname un; uname(&un);
        reply(@{ @"window": @{ @"width": @(v.bounds.size.width), @"height": @(v.bounds.size.height) },
                 @"screen": @{ @"width": @(sc.bounds.size.width), @"height": @(sc.bounds.size.height) },
                 @"native": @{ @"width": @(sc.nativeBounds.size.width), @"height": @(sc.nativeBounds.size.height) },
                 @"scale": @(sc.scale), @"nativeScale": @(sc.nativeScale), @"maxFps": @(sc.maximumFramesPerSecond),
                 @"safeArea": @{ @"top": @(sa.top), @"left": @(sa.left), @"bottom": @(sa.bottom), @"right": @(sa.right) },
                 @"edges": ForgeDisplayGeometry ?: @{},
                 @"orientation": @(ws.interfaceOrientation), @"idiom": @(UIDevice.currentDevice.userInterfaceIdiom),
                 @"machine": [NSString stringWithUTF8String:un.machine] ?: @"", @"system": UIDevice.currentDevice.systemVersion,
                 @"memoryGB": @([NSProcessInfo processInfo].physicalMemory / 1073741824.0), @"cores": @([NSProcessInfo processInfo].activeProcessorCount),
                 @"lowPower": @([NSProcessInfo processInfo].lowPowerModeEnabled), @"thermal": @([NSProcessInfo processInfo].thermalState) }, nil);
        return;
    }
    if ([op isEqualToString:@"info"]) {
        NSDictionary *b = [NSBundle mainBundle].infoDictionary;
        NSDictionary *space = [fm attributesOfFileSystemForPath:self.storageContext.storageRoot error:nil];
        reply(@{ @"version": b[@"CFBundleShortVersionString"] ?: @"", @"build": b[@"CFBundleVersion"] ?: @"",
                 @"system": [UIDevice currentDevice].systemVersion, @"model": [UIDevice currentDevice].model,
                 @"freeBytes": space[NSFileSystemFreeSize] ?: @0, @"root": self.storageContext.storageRoot }, nil);
    } else if ([op isEqualToString:@"list"]) {
        BOOL deep = B(m[@"deep"]);
        NSMutableArray *out = [NSMutableArray array];
        if (deep) {
            NSDirectoryEnumerator *en = [fm enumeratorAtPath:path];
            NSString *rel;
            while ((rel = [en nextObject])) {
                NSDictionary *a = en.fileAttributes;
                if (![a.fileType isEqualToString:NSFileTypeDirectory]) [out addObject:Entry(rel, a)];
                if (out.count > 200000) break;
            }
        } else {
            for (NSString *name in [fm contentsOfDirectoryAtPath:path error:nil] ?: @[]) {
                NSDictionary *a = [fm attributesOfItemAtPath:[path stringByAppendingPathComponent:name] error:nil];
                if (a) [out addObject:Entry(name, a)];
            }
        }
        reply(out, nil);
    } else if ([op isEqualToString:@"stat"]) {
        NSDictionary *a = [fm attributesOfItemAtPath:path error:nil];
        reply(a ? Entry(path.lastPathComponent, a) : [NSNull null], nil);
    } else if ([op isEqualToString:@"usage"]) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            unsigned long long total = 0, count = 0;
            NSDirectoryEnumerator *en = [fm enumeratorAtPath:path];
            NSString *suffix = [m[@"suffix"] isKindOfClass:[NSString class]] ? m[@"suffix"] : nil;
            NSString *rel;
            while ((rel = [en nextObject])) {
                if ([en.fileAttributes.fileType isEqualToString:NSFileTypeDirectory]) continue;
                if (suffix.length && ![rel hasSuffix:suffix]) continue;
                total += en.fileAttributes.fileSize; count++;
            }
            dispatch_async(dispatch_get_main_queue(), ^{ reply(@{ @"bytes": @(total), @"count": @(count) }, nil); });
        });
    } else if ([op isEqualToString:@"remove"]) {
        if ([path isEqualToString:self.storageContext.storageRoot]) {   // "delete everything": empty the folders, keep them
            for (NSString *name in [fm contentsOfDirectoryAtPath:path error:nil] ?: @[])
                [fm removeItemAtPath:[path stringByAppendingPathComponent:name] error:nil];
            for (NSString *name in PublicFolders().allValues) {
                NSString *dir = [self.storageContext.downloadsRoot stringByAppendingPathComponent:name];
                for (NSString *child in [fm contentsOfDirectoryAtPath:dir error:nil] ?: @[])
                    [fm removeItemAtPath:[dir stringByAppendingPathComponent:child] error:nil];
            }
        } else {
            [fm removeItemAtPath:path error:nil];
        }
        reply(@YES, nil);
    } else if ([op isEqualToString:@"mkdir"]) {
        reply(@([fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil]), nil);
    } else if ([op isEqualToString:@"move"]) {
        NSString *to = ResolvePath(self.storageContext, m[@"to"]);
        if (self.storageContext.scoped && [to isEqualToString:self.storageContext.storageRoot]) { reply(nil, @"Choose a file inside the Creator workspace."); return; }
        if (!to) { reply(nil, @"That file location isn't allowed."); return; }
        [fm createDirectoryAtPath:to.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
        [fm removeItemAtPath:to error:nil];
        NSError *e = nil;
        BOOL ok = [fm moveItemAtPath:path toPath:to error:&e];
        reply(ok ? @YES : nil, ok ? nil : e.localizedDescription);
    } else if ([op isEqualToString:@"write"]) {
        NSData *data = [m[@"base64"] isKindOfClass:[NSString class]]
            ? [[NSData alloc] initWithBase64EncodedString:m[@"base64"] options:NSDataBase64DecodingIgnoreUnknownCharacters]
            : [([m[@"text"] isKindOfClass:[NSString class]] ? m[@"text"] : @"") dataUsingEncoding:NSUTF8StringEncoding];
        if (!data) { reply(nil, @"Couldn't read the file data."); return; }
        [fm createDirectoryAtPath:path.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
        BOOL ok;
        if (B(m[@"append"]) && [fm fileExistsAtPath:path]) {
            NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
            NSError *we = nil; ok = fh && [fh seekToEndReturningOffset:NULL error:&we] && [fh writeData:data error:&we]; [fh closeFile];
        } else {
            ok = [data writeToFile:path atomically:YES];
        }
        reply(ok ? @(data.length) : nil, ok ? nil : @"Couldn't save the file. Is the phone full?");
    } else if ([op isEqualToString:@"head"]) {          // size of an Eclipse file without downloading it
        NSURL *url = [m[@"url"] isKindOfClass:[NSString class]] ? [NSURL URLWithString:m[@"url"]] : nil;
        if (self.storageContext.scoped && ![self.storageContext allowsURL:url]) { reply(nil, @"This native network request is not authorized."); return; }
        if (!url || ![url.scheme isEqualToString:@"https"] || ![url.host isEqualToString:@"dokkan-eclipse.com"]) { reply(nil, @"Bad address."); return; }
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
        req.HTTPMethod = @"HEAD";
        req.timeoutInterval = 30;
        [req setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
        [req setValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];
        NSURLRequest *authorized = [self.storageContext authorizedRequest:req];
        if (!authorized) { reply(nil, @"This native network request is not authorized."); return; }
        [[(self.storageContext.scoped ? _aiSession : NSURLSession.sharedSession) dataTaskWithRequest:authorized completionHandler:^(NSData *data, NSURLResponse *r, NSError *e) {
            NSHTTPURLResponse *h = (NSHTTPURLResponse *)r;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (e || ![h isKindOfClass:[NSHTTPURLResponse class]]) reply(nil, e.localizedDescription ?: @"No answer.");
                else reply(@{ @"status": @(h.statusCode), @"length": @(h.expectedContentLength) }, nil);
            });
        }] resume];
    } else if ([op isEqualToString:@"download"]) {
        NSURL *url = [m[@"url"] isKindOfClass:[NSString class]] ? [NSURL URLWithString:m[@"url"]] : nil;
        if (self.storageContext.scoped && ![self.storageContext allowsURL:url]) { reply(nil, @"This native network request is not authorized."); return; }
        if (!url || !path) { reply(nil, @"Bad download."); return; }
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
        if (_wifiOnlyDownloads) {   // "Wi-Fi only": iOS itself refuses mobile data / hotspots for this download
            req.allowsCellularAccess = NO;
            if (@available(iOS 13.0, *)) { req.allowsExpensiveNetworkAccess = NO; req.allowsConstrainedNetworkAccess = NO; }
        }
        NSDictionary *headers = [m[@"headers"] isKindOfClass:[NSDictionary class]] ? m[@"headers"] : @{};
        [headers enumerateKeysAndObjectsUsingBlock:^(id k, id v, BOOL *stop) {
            if ([k isKindOfClass:[NSString class]] && [v isKindOfClass:[NSString class]]) [req setValue:v forHTTPHeaderField:k];
        }];
        NSURLRequest *authorized = [self.storageContext authorizedRequest:req];
        if (!authorized) { reply(nil, @"This native network request is not authorized."); return; }
        NSURLSessionDownloadTask *t = [_session downloadTaskWithRequest:authorized];
        ForgeDownload *d = [ForgeDownload new];
        d.ident = [m[@"id"] isKindOfClass:[NSString class]] ? m[@"id"] : [[NSUUID UUID] UUIDString];
        d.path = path;
        d.reply = reply;
        d.keepErrors = B(m[@"keepErrors"]);
        d.noRedirect = B(m[@"noRedirect"]);
        d.wantsProgress = B(m[@"progress"]);
        @synchronized (_downloads) { _downloads[@(t.taskIdentifier)] = d; }
        [t resume];
    } else if ([op isEqualToString:@"cancel"]) {
        NSString *ident = [m[@"id"] isKindOfClass:[NSString class]] ? m[@"id"] : @"";
        NSDictionary *snapshot; @synchronized (_downloads) { snapshot = [_downloads copy]; }
        [snapshot enumerateKeysAndObjectsUsingBlock:^(NSNumber *k, ForgeDownload *d, BOOL *stop) {
            if ([d.ident isEqualToString:ident]) {
                [self->_session getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> *tasks) {
                    for (NSURLSessionTask *t in tasks) if (t.taskIdentifier == k.unsignedIntegerValue) [t cancel];
                }];
            }
        }];
        reply(@YES, nil);
    } else if ([op isEqualToString:@"sql"] || [op isEqualToString:@"sqlBatch"] || [op isEqualToString:@"sqlClose"]) {
        NSString *file = ResolvePath(self.storageContext, [m[@"db"] isKindOfClass:[NSString class]] ? m[@"db"] : @"");
        if (!file) { reply(nil, @"That database location isn't allowed."); return; }
        BOOL writable = B(m[@"writable"]);
        NSArray *sqls = [op isEqualToString:@"sqlBatch"] ? ([m[@"sqls"] isKindOfClass:[NSArray class]] ? m[@"sqls"] : @[]) : @[m[@"sql"] ?: @""];
        NSArray *params = [m[@"params"] isKindOfClass:[NSArray class]] ? m[@"params"] : @[];
        BOOL close = [op isEqualToString:@"sqlClose"];
        dispatch_async(SqlQueue(), ^{
            if (close) { CloseDb(file); dispatch_async(dispatch_get_main_queue(), ^{ reply(@YES, nil); }); return; }
            InstallBundledDatabases(self.storageContext);
            NSString *error = nil; NSDictionary *result = nil;
            for (id one in sqls) {
                NSString *q = [one isKindOfClass:[NSString class]] ? one : @"";
                result = RunSql(file, q, sqls.count == 1 ? params : @[], writable, &error);
                if (!result) break;
            }
            dispatch_async(dispatch_get_main_queue(), ^{ reply(result, result ? nil : (error ?: @"Database error.")); });
        });
    } else if ([op isEqualToString:@"installDatabases"]) {
        dispatch_async(SqlQueue(), ^{ InstallBundledDatabases(self.storageContext); dispatch_async(dispatch_get_main_queue(), ^{ reply(@YES, nil); }); });
    } else if ([op isEqualToString:@"sha256"]) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSInputStream *in = [NSInputStream inputStreamWithFileAtPath:path];
            [in open];
            if (in.streamStatus != NSStreamStatusOpen) { dispatch_async(dispatch_get_main_queue(), ^{ reply(nil, @"File not found."); }); return; }
            CC_SHA256_CTX ctx; CC_SHA256_Init(&ctx);
            uint8_t *buf = malloc(1 << 20); NSInteger n; unsigned long long total = 0;
            while ((n = [in read:buf maxLength:1 << 20]) > 0) { CC_SHA256_Update(&ctx, buf, (CC_LONG)n); total += (unsigned long long)n; }
            free(buf); [in close];
            unsigned char md[CC_SHA256_DIGEST_LENGTH]; CC_SHA256_Final(md, &ctx);
            NSMutableString *hex = [NSMutableString string];
            for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) [hex appendFormat:@"%02x", md[i]];
            dispatch_async(dispatch_get_main_queue(), ^{ reply(@{ @"sha256": hex, @"bytes": @(total) }, nil); });
        });
    } else if ([op isEqualToString:@"copy"]) {
        NSString *to = ResolvePath(self.storageContext, m[@"to"]);
        if (self.storageContext.scoped && [to isEqualToString:self.storageContext.storageRoot]) { reply(nil, @"Choose a file inside the Creator workspace."); return; }
        if (!to) { reply(nil, @"That file location isn't allowed."); return; }
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            [fm createDirectoryAtPath:to.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
            [fm removeItemAtPath:to error:nil];
            NSError *e = nil;
            BOOL ok = [fm copyItemAtPath:[path stringByResolvingSymlinksInPath] toPath:to error:&e];   // copy the file, not a link
            dispatch_async(dispatch_get_main_queue(), ^{ reply(ok ? @YES : nil, ok ? nil : e.localizedDescription); });
        });
    } else if ([op isEqualToString:@"hashes"]) {   // sha256 + XXH64 (unsigned decimal) of a file
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSInputStream *in = [NSInputStream inputStreamWithFileAtPath:path];
            [in open];
            if (in.streamStatus != NSStreamStatusOpen) { dispatch_async(dispatch_get_main_queue(), ^{ reply(nil, @"File not found."); }); return; }
            CC_SHA256_CTX ctx; CC_SHA256_Init(&ctx); XXH x; xxhInit(&x);
            uint8_t *buf = malloc(1 << 20); NSInteger n; unsigned long long total = 0;
            while ((n = [in read:buf maxLength:1 << 20]) > 0) { CC_SHA256_Update(&ctx, buf, (CC_LONG)n); xxhUpdate(&x, buf, (size_t)n); total += (unsigned long long)n; }
            free(buf); [in close];
            unsigned char md[CC_SHA256_DIGEST_LENGTH]; CC_SHA256_Final(md, &ctx);
            NSMutableString *hex = [NSMutableString string];
            for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) [hex appendFormat:@"%02x", md[i]];
            NSString *xx = [NSString stringWithFormat:@"%llu", xxhDigest(&x)];
            dispatch_async(dispatch_get_main_queue(), ^{ reply(@{ @"sha256": hex, @"xxhash64": xx, @"bytes": @(total) }, nil); });
        });
    } else if ([op isEqualToString:@"sqlcipherDecrypt"]) {   // passphrase comes from the Keychain, never from JS
        NSString *to = ResolvePath(self.storageContext, m[@"to"]);
        NSString *sourceSlot = [m[@"keyName"] isKindOfClass:[NSString class]] ? m[@"keyName"] : @"";
        if (self.storageContext.scoped && ![sourceSlot isEqualToString:@"sparking.db"]) { reply(nil, @"The source database slot is not admitted."); return; }
        NSString *secret = SourceSecretRead(self.storageContext, sourceSlot);
        int mode = I(m[@"mode"]) == 3 ? 3 : 4;
        if (!to || !path || [to isEqualToString:path]) { reply(nil, @"Choose a separate safe database output file."); return; }
        if (!secret.length) { reply(nil, @"Import the original Sparking 6.5.5 APK or its ZIP first. Then download characters here."); return; }
        NSData *pass = [secret dataUsingEncoding:NSUTF8StringEncoding];
        dispatch_async((self.storageContext.scoped ? FileWriteQueue() : dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)), ^{
            NSString *err = SqlCipherDecrypt(path, to, pass, mode);
            dispatch_async(dispatch_get_main_queue(), ^{ reply(err ? nil : @YES, err); });
        });
    } else if ([op isEqualToString:@"sprkEncode"]) {   // the other way: ZIP -> "SPRK" 01 IV[16] AES-256-CTR(zip), for "Import to Sparking"
        NSString *to = ResolvePath(self.storageContext, m[@"to"]);
        NSString *hexKey = SourceSecretRead(self.storageContext, @"sparking.sprk");
        if (hexKey.length != 64) { reply(nil, @"Set up Sparking first: Library › Sparking (it needs your Sparking APK once)."); return; }
        if (!to || !path || [to isEqualToString:path]) { reply(nil, @"Choose a separate file for the Sparking patch."); return; }
        dispatch_async((self.storageContext.scoped ? FileWriteQueue() : dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)), ^{
            NSString *err = nil;
            uint8_t key[32], iv[16];
            for (int i = 0; i < 32; i++) { unsigned v = 0; sscanf(hexKey.UTF8String + 2 * i, "%2x", &v); key[i] = (uint8_t)v; }
            // A given IV (hex, from the patch's own SHA-256) makes the same unit give the same file, so sending it
            // again is recognised and no second copy is made. Otherwise a random one.
            NSString *ivHex = [m[@"iv"] isKindOfClass:[NSString class]] ? m[@"iv"] : @"";
            if (ivHex.length == 32) { for (int i = 0; i < 16; i++) { unsigned v = 0; sscanf(ivHex.UTF8String + 2 * i, "%2x", &v); iv[i] = (uint8_t)v; } }
            else if (SecRandomCopyBytes(kSecRandomDefault, 16, iv) != errSecSuccess) err = @"Could not prepare the Sparking patch.";
            NSFileHandle *in = err ? nil : [NSFileHandle fileHandleForReadingAtPath:path];
            if (!err && !in) err = @"The unit file is missing.";
            if (!err) {
                CCCryptorRef ref = NULL;
                if (CCCryptorCreateWithMode(kCCEncrypt, kCCModeCTR, kCCAlgorithmAES, ccNoPadding, iv, key, 32, NULL, 0, 0, kCCModeOptionCTR_BE, &ref) != kCCSuccess || !ref) {
                    memset(key, 0, 32); [in closeFile];
                    dispatch_async(dispatch_get_main_queue(), ^{ reply(nil, @"Could not prepare the Sparking patch."); });
                    return;
                }
                [[NSFileManager defaultManager] createDirectoryAtPath:to.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
                NSMutableData *head = [NSMutableData dataWithBytes:"SPRK\x01" length:5];
                [head appendBytes:iv length:16];
                [[NSFileManager defaultManager] createFileAtPath:to contents:head attributes:nil];
                NSFileHandle *out = [NSFileHandle fileHandleForWritingAtPath:to];
                [out seekToEndOfFile];
                uint8_t *buf = malloc(1 << 20);
                while (1) {
                    @autoreleasepool {
                        NSData *part = [in readDataOfLength:1 << 20];
                        if (!part.length) break;
                        size_t moved = 0;
                        if (CCCryptorUpdate(ref, part.bytes, part.length, buf, 1 << 20, &moved) != kCCSuccess) { err = @"Could not encrypt the Sparking patch."; break; }
                        if (![out writeData:[NSData dataWithBytes:buf length:moved] error:nil]) { err = @"Could not save the Sparking patch."; break; }
                    }
                }
                free(buf); CCCryptorRelease(ref); [out synchronizeFile]; [out closeFile]; [in closeFile];
            }
            memset(key, 0, 32);
            dispatch_async(dispatch_get_main_queue(), ^{ reply(err ? nil : @YES, err); });
        });
    } else if ([op isEqualToString:@"sprkDecode"]) {   // SPRK v1: "SPRK" 01 IV[16] AES-256-CTR(zip)
        NSString *to = ResolvePath(self.storageContext, m[@"to"]);
        NSString *hexKey = SourceSecretRead(self.storageContext, @"sparking.sprk");
        if (hexKey.length != 64) { reply(nil, @"Import the supported Sparking APK before opening an SPRK patch."); return; }
        if (!to || !path || [to isEqualToString:path]) { reply(nil, @"Choose a separate, safe staging file for this Sparking patch."); return; }
        dispatch_async((self.storageContext.scoped ? FileWriteQueue() : dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)), ^{
            NSString *err = nil;
            uint8_t key[32];
            for (int i = 0; i < 32; i++) { unsigned v = 0; sscanf(hexKey.UTF8String + 2 * i, "%2x", &v); key[i] = (uint8_t)v; }
            unsigned long long len = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
            NSFileHandle *in = [NSFileHandle fileHandleForReadingAtPath:path];
            if (len <= 21 || len - 21 > 512ULL * 1024 * 1024) err = @"This Sparking patch is empty or exceeds the512MiB conversion limit.";
            NSData *h = err ? nil : [in readDataOfLength:21];
            const uint8_t *hb = h.bytes;
            if (!err && (h.length < 21)) err = @"The Sparking file is truncated.";
            if (!err && !(hb[0] == 'S' && hb[1] == 'P' && hb[2] == 'R' && hb[3] == 'K' && hb[4] == 1)) err = @"Unsupported Sparking patch header. Only the verified SPRK version1 format is supported.";
            if (!err) {
                CCCryptorRef ref = NULL;
                CCCryptorCreateWithMode(kCCDecrypt, kCCModeCTR, kCCAlgorithmAES, ccNoPadding, hb + 5, key, 32, NULL, 0, 0, kCCModeOptionCTR_BE, &ref);
                [[NSFileManager defaultManager] createDirectoryAtPath:to.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
                [[NSFileManager defaultManager] createFileAtPath:to contents:nil attributes:nil];
                NSFileHandle *out = [NSFileHandle fileHandleForWritingAtPath:to];
                uint8_t *buf = malloc(1 << 20);
                while (1) {
                    @autoreleasepool {
                        NSData *part = [in readDataOfLength:1 << 20];
                        if (!part.length) break;
                        size_t moved = 0;
                        CCCryptorUpdate(ref, part.bytes, part.length, buf, 1 << 20, &moved);
                        if (![out writeData:[NSData dataWithBytes:buf length:moved] error:nil]) { err = @"Could not commit the decoded Sparking archive."; break; }
                    }
                }
                free(buf); CCCryptorRelease(ref); [out synchronizeFile]; [out closeFile];
            }
            memset(key, 0, 32);
            [in closeFile];
            dispatch_async(dispatch_get_main_queue(), ^{ reply(err ? nil : @YES, err); });
        });
    } else if ([op isEqualToString:@"network"]) {
        reply(_netKnown ? @{ @"connected": @(_netConnected), @"metered": @(_netMetered), @"wifi": @(_netWifi) } : @{ @"unknown": @YES }, nil);
    } else if ([op isEqualToString:@"wifiOnlyDownloads"]) {   // while on: downloads may never use mobile data or a hotspot
        _wifiOnlyDownloads = B(m[@"on"]);
        reply(@(_wifiOnlyDownloads), nil);
    } else if ([op isEqualToString:@"aiRequest"]) {
        [self aiRequest:m reply:reply];
    } else if ([op isEqualToString:@"aiCancel"]) {
        NSURLSessionTask *t = [m[@"job"] isKindOfClass:[NSString class]] ? _aiTasks[m[@"job"]] : nil;
        [t cancel];
        reply(@YES, nil);
    } else if ([op isEqualToString:@"copyText"]) {
        [UIPasteboard generalPasteboard].string = [m[@"text"] isKindOfClass:[NSString class]] ? m[@"text"] : @"";
        reply(@YES, nil);
    } else if ([op hasPrefix:@"secret"]) {
        [self secret:op message:m reply:reply];
    } else if ([op isEqualToString:@"share"]) {
        BOOL isDir = NO;
        if (![fm fileExistsAtPath:path isDirectory:&isDir] || isDir) { reply(nil, @"File not found."); return; }
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        NSString *name = [m[@"name"] isKindOfClass:[NSString class]] ? [m[@"name"] stringByReplacingOccurrencesOfString:@"/" withString:@"_"] : nil;
        if (name.length && ![name isEqualToString:path.lastPathComponent]) {   // share under a friendly name
            NSString *dir = [self.storageContext.temporaryRoot stringByAppendingPathComponent:@"share"];
            [fm removeItemAtPath:dir error:nil];
            [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
            NSString *copy = [dir stringByAppendingPathComponent:name];
            if ([fm linkItemAtPath:path toPath:copy error:nil] || [fm copyItemAtPath:path toPath:copy error:nil]) fileURL = [NSURL fileURLWithPath:copy];
        }
        UIActivityViewController *sheet = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
        __block BOOL replied = NO;   // iOS can call this twice (an extension cancelled, then the sheet closed)
        sheet.completionWithItemsHandler = ^(UIActivityType type, BOOL completed, NSArray *items, NSError *error) { if (replied) return; replied = YES; reply(@(completed), nil); };
        UIViewController *top = self.presenter;
        while (top.presentedViewController) top = top.presentedViewController;
        if (sheet.popoverPresentationController) {
            sheet.popoverPresentationController.sourceView = top.view;
            sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(top.view.bounds), CGRectGetMidY(top.view.bounds), 1, 1);
            sheet.popoverPresentationController.permittedArrowDirections = 0;
        }
        if (!top || top.isBeingDismissed) { reply(nil, @"Can't show the Share sheet right now."); return; }
        [top presentViewController:sheet animated:YES completion:nil];
    } else if ([op isEqualToString:@"openURL"]) {
        NSURL *url = [m[@"url"] isKindOfClass:[NSString class]] ? [NSURL URLWithString:m[@"url"]] : nil;
        if (!url) { reply(@NO, nil); return; }
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL ok) { reply(@(ok), nil); }];
    } else if ([op isEqualToString:@"keepAwake"]) {
        [UIApplication sharedApplication].idleTimerDisabled = B(m[@"on"]);
        reply(@YES, nil);
    } else {
        reply(nil, [NSString stringWithFormat:@"Unknown action: %@", op]);
    }
}

#pragma mark keychain (AI keys never leave native code: JavaScript only ever sees a hint)

static NSDictionary *SecretQuery(ForgeStorageContext *context, NSString *key) {
    return @{ (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrService: context.keychainService,
              (__bridge id)kSecAttrAccount: key };
}

static NSString *_Nullable SecretRead(ForgeStorageContext *context, NSString *key) {
    NSMutableDictionary *q = [SecretQuery(context, key) mutableCopy];
    q[(__bridge id)kSecReturnData] = @YES;
    q[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    CFTypeRef out = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)q, &out) != errSecSuccess) return nil;
    NSData *data = (__bridge_transfer NSData *)out;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
static NSString *_Nullable SourceSecretRead(ForgeStorageContext *context, NSString *key) {
    if (!context.scoped) return SecretRead(context, key);
    if (![context isCurrent] || ![@[@"sparking.db", @"sparking.sprk"] containsObject:key]) return nil;
    NSMutableDictionary *q = [SecretQuery(context, key) mutableCopy];
    q[(__bridge id)kSecAttrService] = context.sourceKeychainService;
    q[(__bridge id)kSecReturnData] = @YES; q[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    CFTypeRef result = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)q, &result) != errSecSuccess) return nil;
    return [[NSString alloc] initWithData:(__bridge_transfer NSData *)result encoding:NSUTF8StringEncoding];
}

- (void)secret:(NSString *)op message:(NSDictionary *)m reply:(void (^)(id _Nullable, NSString *_Nullable))reply {
    NSString *key = [m[@"key"] isKindOfClass:[NSString class]] ? m[@"key"] : nil;
    if (self.storageContext.scoped && ![@[@"ai.openai", @"ai.gemini", @"ai.anthropic", @"ai.xai", @"ai.openrouter", @"ai.custom"] containsObject:key]) {
        reply(nil, @"Only AI connections belong to this Keychain capability."); return;
    }
    if (!key.length) { reply(nil, @"Missing key name."); return; }
    if ([op isEqualToString:@"secretHint"]) {
        NSString *v = SecretRead(self.storageContext, key) ?: @"";
        NSString *hint = v.length > 4 ? [@"…" stringByAppendingString:[v substringFromIndex:v.length - 4]] : (v.length ? @"set" : @"");
        reply(@{ @"hasKey": @(v.length > 0), @"keyHint": hint }, nil);
    } else if ([op isEqualToString:@"secretSet"]) {
        NSString *value = [m[@"value"] isKindOfClass:[NSString class]] ? m[@"value"] : @"";
        SecItemDelete((__bridge CFDictionaryRef)SecretQuery(self.storageContext, key));
        if (!value.length) { reply(@YES, nil); return; }
        NSMutableDictionary *add = [SecretQuery(self.storageContext, key) mutableCopy];
        add[(__bridge id)kSecValueData] = [value dataUsingEncoding:NSUTF8StringEncoding];
        add[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
        OSStatus s = SecItemAdd((__bridge CFDictionaryRef)add, NULL);
        reply(s == errSecSuccess ? @YES : nil, s == errSecSuccess ? nil : @"Could not save the AI connection.");
    } else if ([op isEqualToString:@"secretDelete"]) {
        SecItemDelete((__bridge CFDictionaryRef)SecretQuery(self.storageContext, key));
        reply(@YES, nil);
    } else {
        reply(nil, @"Unknown action.");
    }
}

/// {provider, url, method, body, keyName} → {status, text}. The key is read from the Keychain here
/// and added as the provider's auth header (ForgeAi.perform on Android).
- (void)aiRequest:(NSDictionary *)m reply:(void (^)(id _Nullable, NSString *_Nullable))reply {
    NSString *provider = [m[@"provider"] isKindOfClass:[NSString class]] ? m[@"provider"] : @"";
    NSURL *url = [m[@"url"] isKindOfClass:[NSString class]] ? [NSURL URLWithString:m[@"url"]] : nil;
    if (self.storageContext.scoped && ![self.storageContext allowsURL:url]) { reply(nil, @"This native network request is not authorized."); return; }
    if (!url) { reply(nil, @"Unsupported AI request."); return; }
    NSString *key = SecretRead(self.storageContext, [@"ai." stringByAppendingString:provider]) ?: @"";
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:240];
    BOOL post = ![m[@"method"] isEqual:@"GET"];
    req.HTTPMethod = post ? @"POST" : @"GET";
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setValue:@"DokkanUnitCreation/2.12 (iOS)" forHTTPHeaderField:@"User-Agent"];
    if ([provider isEqualToString:@"gemini"]) [req setValue:key forHTTPHeaderField:@"x-goog-api-key"];
    else if ([provider isEqualToString:@"anthropic"]) { [req setValue:key forHTTPHeaderField:@"x-api-key"]; [req setValue:@"2023-06-01" forHTTPHeaderField:@"anthropic-version"]; }
    else if (key.length) [req setValue:[@"Bearer " stringByAppendingString:key] forHTTPHeaderField:@"Authorization"];
    if ([provider isEqualToString:@"openrouter"]) [req setValue:@"Dokkan Unit Creation" forHTTPHeaderField:@"X-Title"];
    if (post) {
        [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        req.HTTPBody = [([m[@"body"] isKindOfClass:[NSString class]] ? m[@"body"] : @"{}") dataUsingEncoding:NSUTF8StringEncoding];
    }
    NSURLRequest *authorized = [self.storageContext authorizedRequest:req];
    if (!authorized) { reply(nil, @"This native network request is not authorized."); return; }
    NSURLSessionDataTask *t = [_aiSession dataTaskWithRequest:authorized completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_aiTasks removeObjectForKey:m[@"job"] ?: @""];
            if (error) {
                NSString *msg = error.localizedDescription ?: @"The AI request failed.";
                if (error.code == NSURLErrorCancelled) msg = @"Canceled.";
                else if (error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorDNSLookupFailed) msg = @"No Internet connection, or the AI server address is wrong.";
                else if (error.code == NSURLErrorTimedOut) msg = @"The AI service took too long to answer. Try again.";
                reply(nil, msg);
                return;
            }
            if (data.length > 48 * 1024 * 1024) { reply(nil, @"The AI response is too large."); return; }
            NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 0;
            NSString *text = [[NSString alloc] initWithData:data ?: [NSData data] encoding:NSUTF8StringEncoding] ?: @"";
            reply(@{ @"status": @(status), @"text": text }, nil);
        });
    }];
    if ([m[@"job"] isKindOfClass:[NSString class]]) _aiTasks[m[@"job"]] = t;
    [t resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *_Nullable))completionHandler {
    if (session == _aiSession) { completionHandler(nil); return; }   // AI requests never follow redirects (keys stay with the provider)
    if (self.storageContext.scoped && ![self.storageContext allowsURL:request.URL]) { completionHandler(nil); return; }
    ForgeDownload *d; @synchronized (_downloads) { d = _downloads[@(task.taskIdentifier)]; }
    completionHandler(d.noRedirect ? nil : [self.storageContext authorizedRequest:request]);
}

#pragma mark downloads

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)t didWriteData:(int64_t)written
 totalBytesWritten:(int64_t)total totalBytesExpectedToWrite:(int64_t)expected {
    ForgeDownload *d; @synchronized (_downloads) { d = _downloads[@(t.taskIdentifier)]; }
    if (!d || !d.wantsProgress) return;          // only downloads with a progress bar report progress to the page
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (now - d.lastProgress < 0.25) return;
    d.lastProgress = now;
    NSDictionary *ev = @{ @"type": @"progress", @"id": d.ident, @"bytes": @(total), @"total": @(expected > 0 ? expected : 0) };
    dispatch_async(dispatch_get_main_queue(), ^{ [self emit:ev]; });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)t didFinishDownloadingToURL:(NSURL *)location {
    ForgeDownload *d; @synchronized (_downloads) { d = _downloads[@(t.taskIdentifier)]; }
    if (!d) return;
    if (![self.storageContext isCurrent]) { d.moveError = @"The Creator workspace changed."; return; }
    NSInteger status = [t.response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)t.response).statusCode : 200;
    if ((status < 200 || status >= 300) && !d.keepErrors) return;
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:d.path.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *part = [d.path stringByAppendingString:@".part"];
    [fm removeItemAtPath:part error:nil];
    NSError *e = nil;
    if ([fm moveItemAtURL:location toURL:[NSURL fileURLWithPath:part] error:&e]) {
        [fm removeItemAtPath:d.path error:nil];
        d.saved = [fm moveItemAtPath:part toPath:d.path error:&e];
    }
    if (!d.saved) d.moveError = e.localizedDescription ?: @"Couldn't save the download.";
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)t didCompleteWithError:(NSError *)error {
    if (session != _session) return;
    ForgeDownload *d;
    @synchronized (_downloads) { d = _downloads[@(t.taskIdentifier)]; [_downloads removeObjectForKey:@(t.taskIdentifier)]; }
    if (!d) return;
    NSHTTPURLResponse *http = [t.response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)t.response : nil;
    // worked out here (background), answered on the main thread (the reply talks to the web page)
    id result = nil; NSString *err = nil;
    if (error) err = error.code == NSURLErrorCancelled ? @"Canceled." : [NSString stringWithFormat:@"Download failed: %@", error.localizedDescription];
    else if (d.moveError) err = d.moveError;
    else {
        NSDictionary *a = [[NSFileManager defaultManager] attributesOfItemAtPath:d.path error:nil];
        result = @{ @"status": @(http ? http.statusCode : 200), @"saved": @(d.saved), @"bytes": @(d.saved ? a.fileSize : 0),
                    @"finalUrl": t.response.URL.absoluteString ?: @"", @"contentType": [http valueForHTTPHeaderField:@"Content-Type"] ?: @"",
                    @"etag": [http valueForHTTPHeaderField:@"ETag"] ?: @"", @"lastModified": [http valueForHTTPHeaderField:@"Last-Modified"] ?: @"" };
    }
    void (^reply)(id _Nullable, NSString *_Nullable) = d.reply;
    dispatch_async(dispatch_get_main_queue(), ^{ reply(result, err); });
}
@end
