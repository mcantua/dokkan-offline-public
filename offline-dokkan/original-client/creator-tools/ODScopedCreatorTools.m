#import "ODScopedCreatorTools.h"
#import "../ios/ODNativeCreatorNetwork.h"
#import "ODCreatorSourceCodec.h"
#import "ODCreatorSourceDatabases.h"
#import <stdatomic.h>
#import <stdbool.h>
#import <fcntl.h>
#import <sys/stat.h>
#import <unistd.h>
// Intentional compile-time class names, separate from the genuine app shell.
#define ForgeStorageContext ODScopedCreatorStorageContext
#define ForgeSchemeHandler ODScopedCreatorSchemeHandler
#define ForgeHost ODScopedCreatorHost
#define ForgePlayer ODScopedCreatorPlayer
#import "../../../unit-creator/ios-objc/Host.h"
#import "../../../unit-creator/ios-objc/Player.h"

NSDictionary *ODScopedCreatorDisplayGeometry;

@implementation ODScopedCreatorTools {
    ODScopedCreatorStorageContext *_storage;
    ODScopedCreatorHost *_host;
    ODScopedCreatorPlayer *_player;
    ODScopedCreatorSchemeHandler *_scheme;
    ODCreatorSourceCodec *_sourceCodec;
    ODCreatorSourceDatabases *_sourceDatabases;
    ODCreatorContentArchive *_archive;
    ODCreatorArchiveSnapshotProvider _archiveSnapshot;
    ODCreatorArchiveDocumentsRestorer _archiveRestorer;
    __weak WKWebView *_webView;
    BOOL (^_current)(void);
    BOOL _invalidated;
    BOOL _archiveGate;
    NSString *_scopeIdentifier;
    atomic_bool _archiveMutationBlocked;
}
- (instancetype)initWithWorkspaceURL:(NSURL *)workspace siteURL:(NSURL *)site
    scopeIdentifier:(NSString *)scope contextIsCurrent:(BOOL (^)(void))current
    networkAuthorization:(BOOL (^)(NSURL *))authorization error:(NSError **)error {
    if (!(self = [super init])) return nil;
    NSCharacterSet *bad = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet];
    if (!workspace.isFileURL || !site.isFileURL || scope.length != 64 ||
        [scope rangeOfCharacterFromSet:bad].location != NSNotFound || !current || !authorization) {
        if (error) *error = [NSError errorWithDomain:@"ODCreatorTools" code:1 userInfo:@{NSLocalizedDescriptionKey:@"A native-bound Creator workspace is required."}];
        return nil;
    }
    _current = [current copy];
    _scopeIdentifier = [scope copy];
    atomic_init(&_archiveMutationBlocked, false);
    __weak ODScopedCreatorTools *weakSelf = self;
    _storage = [[ODScopedCreatorStorageContext alloc]
        initWithRootURL:[workspace URLByAppendingPathComponent:@"native-tools" isDirectory:YES] siteURL:site
        keychainNamespace:[@"org.offlinedokkan.creator.tools.ai." stringByAppendingString:scope]
        preferencesNamespace:[[ @"org.offlinedokkan.creator.tools." stringByAppendingString:scope] stringByAppendingString:@".gameFolder."]
        contextIsCurrent:^BOOL { ODScopedCreatorTools *me = weakSelf; return me && !me->_invalidated && me->_current && me->_current(); }
        URLAuthorization:authorization error:error];
    if (!_storage) return nil;
    _storage.fileMutationAuthorization = ^BOOL {
        ODScopedCreatorTools *me = weakSelf;
        return me && !atomic_load_explicit(&me->_archiveMutationBlocked, memory_order_acquire);
    };
    __weak ODScopedCreatorStorageContext *weakStorage = _storage;
    _storage.requestDecorator = ^NSURLRequest *(NSURLRequest *request) {
        return ODNativeCreatorAuthorizedRequest(request, ^BOOL { return [weakStorage isCurrent]; }, authorization, nil);
    };
    _host = [[ODScopedCreatorHost alloc] initWithStorageContext:_storage];
    _sourceCodec = [[ODCreatorSourceCodec alloc] initWithStorageContext:_storage];
    __weak ODCreatorSourceCodec *weakCodec = _sourceCodec;
    _host.sourceCodecAuthorization = ^BOOL { return [weakCodec isAdmitted]; };
    _sourceDatabases = [[ODCreatorSourceDatabases alloc] initWithStorageContext:_storage host:_host];
    _scheme = [[ODScopedCreatorSchemeHandler alloc] initWithStorageContext:_storage];
    return self;
}
- (id<WKURLSchemeHandler>)schemeHandler { return _scheme; }
- (NSString *)scopeIdentifier { return _scopeIdentifier; }
- (int)openAssetKey:(NSString *)assetKey error:(NSError **)error {
    // Walk every component through held directory descriptors: a symlink swap
    // cannot escape the native-issued resource namespace during validation.
    int descriptor = -1;
    NSCharacterSet *forbidden = [NSCharacterSet characterSetWithCharactersInString:@"\\:%"];
    NSArray<NSString *> *parts = [assetKey isKindOfClass:NSString.class] ? [assetKey componentsSeparatedByString:@"/"] : nil;
    NSSet *private = [NSSet setWithArray:@[@"projects",@"patches",@"exports",@"_databases",@"metadata.json",@"forge-project.json",@"database-meta.json",@"database-state.json",@"account.txt",@"credentials.json",@"secrets.json"]];
    NSSet *extensions = [NSSet setWithArray:@[@"png",@"jpg",@"jpeg",@"webp",@"gif",@"bmp",@"lwf",@"lua",@"usm",@"cpk",@"kks",@"ogg",@"mp3",@"wav",@"awb",@"acb",@"atlas",@"plist",@"json",@"xml",@"tmx",@"bytes",@"fsh",@"vsh",@"fnt",@"ttf",@"otf",@"strings",@"txt",@"bin"]];
    BOOL valid = [_storage isCurrent] && assetKey.length <= 500 && parts.count >= 2 &&
        [assetKey rangeOfCharacterFromSet:forbidden].location == NSNotFound &&
        [assetKey rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location == NSNotFound &&
        [extensions containsObject:assetKey.pathExtension.lowercaseString];
    for (NSString *part in parts) {
        NSString *lower = part.lowercaseString;
        if (!part.length || [part hasPrefix:@"."] || [private containsObject:lower] ||
            [lower rangeOfString:@"\\.(db|sqlite|sqlite3)([-.].*)?$" options:NSRegularExpressionSearch].location != NSNotFound) valid = NO;
    }
    if (valid) {
        descriptor = open(_storage.storageRoot.fileSystemRepresentation, O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
        NSArray<NSString *> *walk = [@[@"assets"] arrayByAddingObjectsFromArray:parts];
        for (NSUInteger i=0; descriptor >= 0 && i<walk.count; i++) {
            int flags = O_RDONLY|O_NOFOLLOW|O_CLOEXEC;
            if (i+1<walk.count) flags |= O_DIRECTORY;
            int next = openat(descriptor, walk[i].fileSystemRepresentation, flags);
            close(descriptor); descriptor = next;
        }
        struct stat state;
        int flags = descriptor >= 0 ? fcntl(descriptor, F_GETFL) : -1;
        /* The full-bundle validator captures this FD only when it is a fresh
         * readonly regular file. A writable or replaced descriptor is denied. */
        if (descriptor >= 0 && (flags < 0 || (flags & O_ACCMODE) != O_RDONLY ||
            fstat(descriptor,&state) || !S_ISREG(state.st_mode) ||
            state.st_size < 0 || state.st_size > 160LL*1024*1024 || ![_storage isCurrent])) {
            close(descriptor); descriptor = -1;
        }
    }
    if (descriptor < 0 && error) *error = [NSError errorWithDomain:@"ODCreatorTools" code:2
        userInfo:@{NSLocalizedDescriptionKey:@"The selected Creator resource is unavailable in this save scope."}];
    return descriptor;
}
- (BOOL)archiveOperationInProgress { return _archiveGate || _archive.busy; }
+ (NSSet<NSString *> *)supportedOperations {
    static NSSet *operations; static dispatch_once_t once;
    dispatch_once(&once, ^{ operations = [NSSet setWithArray:@[
        @"display", @"info", @"list", @"stat", @"usage", @"remove", @"mkdir", @"move", @"write",
        @"head", @"download", @"cancel", @"sha256", @"copy", @"hashes", @"network", @"wifiOnlyDownloads",
        @"aiRequest", @"aiCancel", @"copyText", @"secretHint", @"secretSet", @"secretDelete",
        @"share", @"openURL", @"keepAwake", @"serverInfo", @"playerOpen", @"playerLayout", @"playerEval",
        @"playerBar", @"playerNote", @"playerOverlay", @"playerSnapshot", @"playerCookieClear",
        @"saveDocument", @"gameFolderStatus", @"gameFolderLink", @"gameFolderUnlink", @"gameFolderCopyIn", @"gameFolderWrite",
        @"sourceCodecStatus", @"sourceCodecImportAPK", @"sqlcipherDecrypt", @"sprkEncode", @"sprkDecode", @"userContentArchive",
        @"sourceDatabaseOpen", @"sourceDatabaseRead", @"sourceDatabaseClose"
    ]]; });
    return operations;
}
- (void)attachWebView:(WKWebView *)webView presenter:(UIViewController *)presenter {
    if (_invalidated || ![_storage isCurrent]) return;
    [_player invalidate];
    _webView = webView; _host.webView = webView; _host.presenter = presenter;
    _player = [[ODScopedCreatorPlayer alloc] initWithMainWebView:webView controller:presenter storageContext:_storage];
    _host.player = _player;
}
- (BOOL)admit:(NSDictionary *)message reply:(void (^)(id, NSString *))reply {
    if (_invalidated || ![_storage isCurrent]) { reply(nil,@"The Creator workspace changed."); return NO; }
    NSString *op = [message[@"op"] isKindOfClass:NSString.class] ? message[@"op"] : @"";
    if (_archiveGate && ![@[@"display",@"network",@"cancel",@"aiCancel",@"sourceDatabaseClose"] containsObject:op]) { reply(nil,@"Finish the current Creator archive operation first."); return NO; }
    if (![[self.class supportedOperations] containsObject:op]) { reply(nil,@"This operation belongs to the bound Creator session or a separate source capability."); return NO; }
    if ([op hasPrefix:@"secret"]) {
        NSString *key = [message[@"key"] isKindOfClass:NSString.class] ? message[@"key"] : @"";
        if (![@[@"ai.openai",@"ai.gemini",@"ai.anthropic",@"ai.xai",@"ai.openrouter",@"ai.custom"] containsObject:key]) {
            reply(nil,@"Only AI connections belong to this Keychain capability."); return NO;
        }
    }
    if ([op isEqualToString:@"aiRequest"]) {
        NSString *provider = [message[@"provider"] isKindOfClass:NSString.class] ? message[@"provider"] : @"";
        NSURL *url = [message[@"url"] isKindOfClass:NSString.class] ? [NSURL URLWithString:message[@"url"]] : nil;
        NSDictionary *hosts = @{@"openai":@"api.openai.com",@"gemini":@"generativelanguage.googleapis.com",
            @"anthropic":@"api.anthropic.com",@"xai":@"api.x.ai",@"openrouter":@"openrouter.ai"};
        BOOL custom = [provider isEqualToString:@"custom"];
        if ((!custom && ![url.host.lowercaseString isEqualToString:hosts[provider]]) || ![_storage allowsURL:url]) {
            reply(nil,@"The AI destination is not authorized for this provider."); return NO;
        }
    }
    if ([op isEqualToString:@"gameFolderCopyIn"]) {
        NSString *relative = [message[@"rel"] isKindOfClass:NSString.class] ? message[@"rel"] : @"";
        NSSet *private = [NSSet setWithArray:@[@"user",@"shared_prefs",@"settings",@"secrets",@"credentials"]];
        for (NSString *part in [relative.lowercaseString componentsSeparatedByString:@"/"])
            if ([private containsObject:part]) { reply(nil,@"Private game settings are not Creator resources."); return NO; }
    }
    return YES;
}
- (void)handleMessage:(NSDictionary *)message reply:(void (^)(id, NSString *))reply {
    if (![self admit:message reply:reply]) return;
    NSString *op = message[@"op"];
    if ([op isEqualToString:@"sourceCodecStatus"]) { reply([_sourceCodec status], nil); return; }
    if ([op isEqualToString:@"sourceCodecImportAPK"]) { [_sourceCodec importAPKAtRelativePath:message[@"path"] reply:reply]; return; }
    if ([@[@"sourceDatabaseOpen", @"sourceDatabaseRead", @"sourceDatabaseClose"] containsObject:op]) { [_sourceDatabases handleMessage:message reply:reply]; return; }
    if ([op isEqualToString:@"userContentArchive"]) { [self archiveArguments:message reply:reply]; return; }
    [_host handleMessage:message reply:^(id value, NSString *error) {
        reply([self->_storage isCurrent] ? value : nil, [self->_storage isCurrent] ? error : @"The Creator workspace changed.");
    }];
}
- (void)userContentController:(WKUserContentController *)controller didReceiveScriptMessage:(WKScriptMessage *)message
    replyHandler:(void (^)(id, NSString *))reply {
    NSURL *url = message.frameInfo.request.URL;
    if (message.webView != _webView || !message.frameInfo.mainFrame ||
        ![url.scheme isEqualToString:@"app"] || ![url.host isEqualToString:@"local"]) {
        reply(nil,@"Only the bound Creator screen can use these tools."); return;
    }
    NSDictionary *body = [message.body isKindOfClass:NSDictionary.class] ? message.body : @{};
    if (![self admit:body reply:reply]) return;
    if ([@[@"sourceCodecStatus", @"sourceCodecImportAPK", @"userContentArchive", @"sourceDatabaseOpen", @"sourceDatabaseRead", @"sourceDatabaseClose"] containsObject:body[@"op"]]) { [self handleMessage:body reply:reply]; return; }
    [_host userContentController:controller didReceiveScriptMessage:message replyHandler:^(id value, NSString *error) {
        reply([self->_storage isCurrent] ? value : nil, [self->_storage isCurrent] ? error : @"The Creator workspace changed.");
    }];
}
- (void)layoutInBounds:(CGRect)bounds safeArea:(UIEdgeInsets)insets { [_player layoutInBounds:bounds safeArea:insets]; }
- (void)configureArchiveWithSnapshotProvider:(ODCreatorArchiveSnapshotProvider)snapshot
    documentsRestorer:(ODCreatorArchiveDocumentsRestorer)restorer {
    if (_invalidated || ![_storage isCurrent]) return;
    _archiveSnapshot = [snapshot copy]; _archiveRestorer = [restorer copy];
}
- (void)archiveArguments:(NSDictionary *)message reply:(void (^)(id, NSString *))reply {
    if (!_archiveSnapshot || !_archiveRestorer) { reply(nil, @"The bound Creator archive capability is unavailable."); return; }
    if (_archive.busy) { reply(nil, @"Finish the current Creator archive operation first."); return; }
    if ([_host hasActiveDownloads] || [_scheme hasActiveRequests]) { reply(nil, @"Finish the current native downloads before archiving Creator content."); return; }
    BOOL mutation = ![message[@"action"] isEqualToString:@"status"];
    if (mutation) { _archiveGate = YES; atomic_store_explicit(&_archiveMutationBlocked, true, memory_order_release); }
    [_host performAfterFileWrites:^{ [self beginArchiveArguments:message reply:reply]; }];
}
- (void)beginArchiveArguments:(NSDictionary *)message reply:(void (^)(id, NSString *))reply {
    if (![_storage isCurrent]) { _archiveGate = NO; atomic_store(&_archiveMutationBlocked, false); reply(nil,@"The Creator workspace changed."); return; }
    __weak ODScopedCreatorStorageContext *weakStorage = _storage;
    NSError *error = nil;
    _archive = [[ODCreatorContentArchive alloc] initWithResourcesRootURL:[NSURL fileURLWithPath:_storage.storageRoot isDirectory:YES]
        archiveFolderURL:[_player folderURLForGame:@"dokkan-files"] contextIsCurrent:^BOOL { return [weakStorage isCurrent]; }
        snapshotProvider:_archiveSnapshot documentsRestorer:_archiveRestorer error:&error];
    if (!_archive) { _archiveGate = NO; atomic_store(&_archiveMutationBlocked, false); reply(nil, error.localizedDescription ?: @"The Creator archive capability is unavailable."); return; }
    NSMutableDictionary *arguments = [message mutableCopy]; [arguments removeObjectForKey:@"op"];
    [_archive handleArguments:arguments reply:^(NSDictionary *result, NSString *failure) {
        dispatch_block_t finish = ^{ self->_archiveGate = NO; atomic_store(&self->_archiveMutationBlocked, false); reply(result,failure); };
        if (NSThread.isMainThread) finish(); else dispatch_async(dispatch_get_main_queue(), finish);
    }];
}
- (void)invalidate {
    if (_invalidated) return;
    _invalidated = YES; [_sourceDatabases invalidate]; [_archive invalidate]; [_host invalidate]; [_scheme invalidate]; [_player invalidate];
    _host.player = nil; _player = nil; _webView = nil;
}
- (void)dealloc { [_sourceDatabases invalidate]; [_host invalidate]; [_scheme invalidate]; [_player invalidate]; }
@end
