#import <Foundation/Foundation.h>
@class ODNativeCore,ODNativeCreatorLease;
NS_ASSUME_NONNULL_BEGIN
typedef void (^ODCreatorReply)(id _Nullable result, NSString *_Nullable error);
/** Restricted Creator services. All paths, content identity, core and profile are native-owned. */
@interface ODCreatorSession : NSObject
@property(nonatomic, readonly) BOOL originalClientMode;
- (instancetype)initWithMasterURL:(NSURL *)master contentID:(NSString *)contentID
                            game:(NSString *)game directory:(NSURL *)directory core:(ODNativeCore *)core;
/** Trusted original-client binding only. A nil lease is an unissued/cold
 * session: settings remain readable, but no Creator core work is authorized.
 * An issued session retains the exact native capability; strings from pages
 * cannot grant authority or borrow another editor's same-scope lease. */
- (nullable instancetype)initWithMasterURL:(NSURL *)master contentID:(NSString *)contentID
                            game:(NSString *)game directory:(NSURL *)directory core:(ODNativeCore *)core
                            originalClientSaveScopeSHA256:(NSString *)scope
                            lease:(nullable ODNativeCreatorLease *)lease;
- (void)handleOperation:(NSString *)operation arguments:(NSDictionary *)arguments reply:(ODCreatorReply)reply;
/** Native-only archive adapter. Virtual document paths/data only: never the
 * raw state file, settings, intents, definition IDs, core or master. Restore
 * merges atomically; a conflicting existing document rejects the whole merge. */
- (void)exportArchiveDocumentsWithReply:(void (^)(NSDictionary<NSString *, NSData *> * _Nullable files, NSString * _Nullable error))reply;
- (void)restoreArchiveDocuments:(NSDictionary<NSString *, NSData *> *)files reply:(ODCreatorReply)reply;
/** Native original-runtime compiler only. Immutable exact accepted bytes, not
 * editable drafts. Historical versions are retained; no WebView registration. */
- (void)recoverAcceptedProjectsWithReply:(ODCreatorReply)reply;
- (void)acceptedProjectForDefinitionID:(NSString *)definitionID version:(NSNumber *)version reply:(ODCreatorReply)reply;
/** Trusted native coordinator only. Never route this through a WebView handler.
 * offlineBattleRead {} => null|{token,data}; offlineBattleCompareSwap
 * {expectedToken:null|string,data:string} => new opaque token|false.
 * The slot is untrusted persistence, not settlement/reward authority. */
- (void)nativeBattleOperation:(NSString *)operation arguments:(NSDictionary *)arguments reply:(ODCreatorReply)reply;
// Trusted native run/stage planner only; no matching public page operations.
- (void)startTrustedBattlePlan:(NSDictionary *)plan reply:(ODCreatorReply)reply;
- (void)openTrustedBattlePlan:(NSDictionary *)reference reply:(ODCreatorReply)reply;
@end
NS_ASSUME_NONNULL_END
