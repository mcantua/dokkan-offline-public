#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^ODAcceptedCreatorResourceContextCurrent)(void);
typedef void (^ODAcceptedCreatorResourceOpenReply)(int readonlyDescriptor, NSError * _Nullable error);

/** Read-only capability over the captured bytes of one accepted native unit.
 * Creation accepts Session's exact six-key full packet and the SAME native
 * issuer's workspace URL. Neither value may come from a page or file picker.
 * The current-context callback is invoked only on main, before queued IO and
 * again before delivery. It must pin that issuer's admitted content/save scope.
 * Hashing, directory/file access and verification run on the private IO queue.
 * This class never publishes resources, builds a CPK or grants engine readiness.
 */
@interface ODAcceptedCreatorResources : NSObject
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
+ (void)prepareAcceptedPacket:(NSDictionary *)packet
                 workspaceURL:(NSURL *)workspace
             contextIsCurrent:(ODAcceptedCreatorResourceContextCurrent)current
                   completion:(void (^)(ODAcceptedCreatorResources * _Nullable resources, NSError * _Nullable error))completion;
/** Exact declared logical resource path, never a source path or blob hash.
 * CPK container records are not packed bytes and reject this entry point. */
- (void)openDeclaredResource:(NSString *)path completion:(ODAcceptedCreatorResourceOpenReply)completion;
/** Native trusted-planner adapter only. Verifies and closes the same blob FD,
 * then returns {path,sha256,size,content_id,save_scope,full_bundle_sha256,
 * project_sha256}. This attests accepted source bytes, not a rebased resource
 * or installation. No descriptor or filesystem path is exposed to JavaScript. */
- (void)attestDeclaredResource:(NSString *)path
                    completion:(void (^)(NSDictionary * _Nullable descriptor, NSError * _Nullable error))completion;
/** Open one explicitly captured input inside an accepted CPK container.
 * The returned bytes are the input, not a rebuilt/verified CPK container. */
- (void)openDeclaredCPKInput:(NSString *)entryPath container:(NSString *)containerPath
                completion:(ODAcceptedCreatorResourceOpenReply)completion;
/** Revokes queued deliveries. A stale success closes its descriptor instead of
 * passing it to the caller. Delivery is on main; on success caller must close
 * the fresh O_RDONLY descriptor, which starts at offset zero. */
- (void)invalidate;
@end
NS_ASSUME_NONNULL_END
