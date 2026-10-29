#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
typedef void (^ODCoreReply)(id _Nullable result, NSError *_Nullable error);
/** Native capability issued only on its save owner's serial queue. Object
 * identity, not a client-supplied string, authorizes original Creator work. */
@interface ODNativeCreatorLease : NSObject
@property(nonatomic,copy,readonly) NSString *profileID;
@property(nonatomic,copy,readonly) NSString *contentID;
@property(nonatomic,copy,readonly) NSString *saveScopeSHA256;
- (instancetype)init NS_UNAVAILABLE;
@end
typedef void (^ODCoreCreatorLeaseReply)(ODNativeCreatorLease *_Nullable lease,NSError *_Nullable error);
/** Own-app bridge, not a replacement HttpAsynConnection game implementation.
 * Trusted native host supplies all URLs/content identity. Work runs off the UI thread;
 * completion returns to the main queue for a Creator view controller/WebView. */
@interface ODNativeCore : NSObject
- (instancetype)initWithSaveURL:(NSURL *)saveURL masterURL:(NSURL *)masterURL contentID:(NSString *)contentID;
/** Native host binding check over immutable owner identity; no file/path/KVC
 * discovery and no WebView operation. Queue/open errors remain authoritative. */
- (BOOL)matchesSaveURL:(NSURL *)saveURL masterURL:(NSURL *)masterURL contentID:(NSString *)contentID;
/** Native-only durable original-client Creator projection. Uses this exact
 * owner's core/master/save on its serial queue; overlay URL is host-pinned.
 * Success: content_id, save_scope_sha256, projection_generation,
 * applied_generation and clean=YES. No original-engine hook is implied.
 * Failed/stale reconciliation never fabricates a clean receipt; keep the
 * editor open/paused until a matching successful retry. Not a WebView op. */
- (void)synchronizeOriginalCreatorProjectionForProfile:(NSString *)profile
    overlayURL:(NSURL *)approvedHostOverlayURL reply:(ODCoreReply)reply;
/** Native read admission before choosing scope-keyed workspace/sidecar paths.
 * Returns actual profile_id/content_id/save_scope_sha256 and projection status;
 * does not reconcile/ack or authorize overwriting a foreign-scope workspace. */
- (void)originalCreatorProjectionAdmissionForProfile:(NSString *)profile reply:(ODCoreReply)reply;
/** Native original-client data adapter only. Read actual scope + canonical
 * player/own provisioned identity in ONE owner-queue block. An import cannot
 * slip between those operations through this owner. Result is
 * {admission,player_snapshot}; expected scope must be native-pinned. */
- (void)originalClientPlayerSnapshotForProfile:(NSString *)profile
    expectedSaveScopeSHA256:(NSString *)scope reply:(ODCoreReply)reply;
/** Acquire after initial successful projection sync. Same-queue save imports
 * reject until this exact lease is cleanly released. No synchronous main/owner
 * dispatch and no lease grant through a WebView operation. */
- (void)acquireOriginalCreatorLeaseForProfile:(NSString *)profile
    expectedSaveScopeSHA256:(NSString *)scope reply:(ODCoreCreatorLeaseReply)reply;
- (void)releaseOriginalCreatorLease:(ODNativeCreatorLease *)lease reply:(ODCoreReply)reply;
/** Check exact current lease/scope and perform the allowed Creator operation
 * within one owner-queue block, before any mutation. Deadline-expired/stale
 * sessions cannot reuse a later editor's same-scope capability. */
- (void)executeCreatorOperation:(NSString *)operation profile:(NSString *)profile
    command:(nullable NSString *)command arguments:(NSDictionary *)arguments
    expectedSaveScopeSHA256:(NSString *)scope lease:(ODNativeCreatorLease *)lease reply:(ODCoreReply)reply;
/** Native immutable accepted-project packet input. Returns exact registered
 * definition_bytes (NSData) plus SHA/id/version/content/scope/profile metadata,
 * never a NSDictionary reserialization. Original mode requires its exact lease;
 * nil legacy lease is allowed only when NO owner lease exists. Expected scope
 * remains mandatory in both cases. No WebView/native JSON operation is added. */
- (void)acceptedCreatorDefinitionForProfile:(NSString *)profile definitionID:(NSString *)definitionID
    version:(int64_t)version expectedSaveScopeSHA256:(NSString *)scope
    lease:(nullable ODNativeCreatorLease *)lease reply:(ODCoreReply)reply;
/** Read-only recovery proof for the exact retained creator.finish intent.
 * Missing/pruned/mismatched receipt stays unresolved: NEVER execute/replay an
 * old unaccepted Finish to discover whether it happened. Same scope/lease rules
 * as raw export; only trusted Session recovery calls this native method. */
- (void)creatorFinishReceiptForProfile:(NSString *)profile command:(NSString *)command
    expectedDefinitionBytes:(NSData *)definition expectedSaveScopeSHA256:(NSString *)scope
    lease:(nullable ODNativeCreatorLease *)lease reply:(ODCoreReply)reply;
- (void)execute:(NSString *)operation profile:(NSString *)profile command:(nullable NSString *)command
      arguments:(NSDictionary *)arguments reply:(ODCoreReply)reply;
/** Native policy/evaluator only; no user-supplied switch to this authority level. */
- (void)executePolicy:(NSString *)operation profile:(NSString *)profile command:(NSString *)command
      fixedHostArguments:(NSDictionary *)arguments reply:(ODCoreReply)reply;
- (void)exportToURL:(NSURL *)approvedHostURL reply:(ODCoreReply)reply;
- (void)importFromURL:(NSURL *)approvedHostURL reply:(ODCoreReply)reply;
- (void)close;
@end
NS_ASSUME_NONNULL_END
