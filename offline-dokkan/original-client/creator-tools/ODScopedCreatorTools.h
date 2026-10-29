#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "../creator-archive/ODCreatorContentArchive.h"
NS_ASSUME_NONNULL_BEGIN
/** Reuses the actual Creator native tools inside one native-issued workspace.
 * No project/master/core/Finish authority is supplied by this capability.
 * Construct/attach/configure on main. current is evaluated only on main, with
 * atomic revocation used by background IO; invalidate BEFORE releasing/changing
 * the native lease. networkAuthorization must be immutable/thread-safe and must
 * not touch UIKit. Register as ForgeHost; forward only selected __file/net/
 * mirror/thumb endpoints after the shared controller's own admission checks. */
@interface ODScopedCreatorTools : NSObject <WKScriptMessageHandlerWithReply>
- (nullable instancetype)initWithWorkspaceURL:(NSURL *)workspace siteURL:(NSURL *)site
    scopeIdentifier:(NSString *)scope contextIsCurrent:(BOOL (^)(void))current
    networkAuthorization:(BOOL (^)(NSURL *))authorization
    error:(NSError * _Nullable * _Nullable)error NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic, readonly) id<WKURLSchemeHandler> schemeHandler;
/** Immutable native-issued scope, used only to isolate persistent WebKit data. */
@property(nonatomic, readonly, copy) NSString *scopeIdentifier;
/** Native-only fresh readonly regular-file FD in assets/<collection>/... .
 * Ownership transfers to caller; -1 means denied. No page bridge operation. */
- (int)openAssetKey:(NSString *)assetKey error:(NSError * _Nullable * _Nullable)error;
@property(nonatomic, readonly) BOOL archiveOperationInProgress; // main-actor authority gate
+ (NSSet<NSString *> *)supportedOperations;
- (void)attachWebView:(WKWebView *)webView presenter:(UIViewController *)presenter;
/** Scoped original-client preview only. Adds the player bar control that
 * returns to the game through the presenter. */
- (void)useInGameCreatorMenuWithTarget:(id)target action:(SEL)action;
- (void)handleMessage:(NSDictionary *)message reply:(void (^)(id _Nullable, NSString *_Nullable))reply;
- (void)layoutInBounds:(CGRect)bounds safeArea:(UIEdgeInsets)insets;
- (void)configureArchiveWithSnapshotProvider:(ODCreatorArchiveSnapshotProvider)snapshot
    documentsRestorer:(ODCreatorArchiveDocumentsRestorer)restorer;
- (void)invalidate;
@end
NS_ASSUME_NONNULL_END
