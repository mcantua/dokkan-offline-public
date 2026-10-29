// Native services for the Unit Creator screens on iPhone (see Host.m and web/src/ios-host.js).
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/// An explicit native-owned storage/network context. The scoped initializer is
/// for an embedded editor; it never substitutes the process's legacy root.
@interface ForgeStorageContext : NSObject
+ (instancetype)legacyContext;
- (instancetype)init NS_DESIGNATED_INITIALIZER; // legacy standalone context only
- (nullable instancetype)initWithRootURL:(NSURL *)root siteURL:(NSURL *)site
    keychainNamespace:(NSString *)keychainNamespace preferencesNamespace:(NSString *)preferencesNamespace
    contextIsCurrent:(BOOL (^)(void))current URLAuthorization:(BOOL (^)(NSURL *))authorization
    error:(NSError * _Nullable * _Nullable)error NS_DESIGNATED_INITIALIZER;
@property(nonatomic, readonly) BOOL scoped;
@property(nonatomic, readonly) NSString *storageRoot;
@property(nonatomic, readonly) NSString *downloadsRoot;
@property(nonatomic, readonly) NSString *temporaryRoot;
@property(nonatomic, readonly) NSString *siteRoot;
@property(nonatomic, readonly) NSString *keychainService;
@property(nonatomic, readonly) NSString *sourceKeychainService;
@property(nonatomic, readonly) NSString *preferencesPrefix;
/// Native-only request capability decorator supplied by an admitted host.
/// Scoped requests fail closed until this is installed; pages cannot set it.
@property(nonatomic, copy, nullable) NSURLRequest *_Nullable (^requestDecorator)(NSURLRequest *);
@property(nonatomic, copy, nullable) BOOL (^fileMutationAuthorization)(void);
- (nullable NSString *)resolve:(NSString *)relative;
- (BOOL)isCurrent;
- (void)invalidate;
- (BOOL)allowsURL:(NSURL *)url;
- (nullable NSURLRequest *)authorizedRequest:(NSURLRequest *)request;
- (BOOL)allowsFileMutation;
@end

/// Serves app://local/…
///   /…                 the bundled app ("site" folder)
///   /__net?u=URL       any web address, fetched natively (no browser cross-site limits), streamed
///   /__file/PATH       the app's own storage: GET (with Range), HEAD, PUT (write body), DELETE
///   /__mirror/HOST/P   a saved copy of https://HOST/P (downloaded and saved on first use)
@interface ForgeSchemeHandler : NSObject <WKURLSchemeHandler>
- (instancetype)initWithStorageContext:(ForgeStorageContext *)context NS_DESIGNATED_INITIALIZER;
@property(nonatomic, readonly) ForgeStorageContext *storageContext;
- (void)invalidate;
- (BOOL)hasActiveRequests;
@end

/// window.webkit.messageHandlers.ForgeHost.postMessage({op, …}) → Promise (files, downloads, keychain…)
@interface ForgeHost : NSObject <WKScriptMessageHandlerWithReply>
- (instancetype)initWithStorageContext:(ForgeStorageContext *)context NS_DESIGNATED_INITIALIZER;
@property(nonatomic, readonly) ForgeStorageContext *storageContext;
@property (nonatomic, weak, nullable) WKWebView *webView;
@property (nonatomic, weak, nullable) UIViewController *presenter;
@property (nonatomic, strong, nullable) id player;   // ForgePlayer: ops starting with "player"/"server"/"saveDocument"
/// Native-only current personal-source capability; empty by default in scoped tools.
@property(nonatomic, copy, nullable) BOOL (^sourceCodecAuthorization)(void);
+ (NSString *)storageRoot;
+ (nullable NSString *)resolve:(NSString *)relative;   // nil if the path leaves storage
+ (dispatch_queue_t)fileMutationQueue;
- (BOOL)hasActiveDownloads;
- (void)performAfterFileWrites:(dispatch_block_t)block;
/// Native-only typed inspection of a staged readonly game-data candidate.
/// No SQL text, writable flag or absolute path is accepted from a page.
- (void)inspectSourceDatabase:(NSString *)relative kind:(NSString *)kind
    table:(nullable NSString *)table identityIsCurrent:(BOOL (^)(void))identity
    reply:(void (^)(id _Nullable, NSString *_Nullable))reply;
- (void)handleMessage:(NSDictionary *)message reply:(void (^)(id _Nullable, NSString *_Nullable))reply;
- (void)invalidate;
@end

NS_ASSUME_NONNULL_END
