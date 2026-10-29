#import <Foundation/Foundation.h>
#import "ODLocalURLProtocol.h"
#import "ODResourceResponseProjector.h"
@class ODOriginalRequestDecoder;

NS_ASSUME_NONNULL_BEGIN
/** Called only on main. The native factory returns its actual issued scoped
 * projector after Core admission, or nil while not ready. No values/snapshot
 * from a page can replace this native object capability. */
typedef ODResourceResponseProjector *_Nullable (^ODOriginalPlayerResourcesProjectorProvider)(void);
/** MAIN-only actual original-image decoder, nil until issued. Successful
 * native own-JSON self-check is enforced by the capability itself. */
typedef ODOriginalRequestDecoder *_Nullable (^ODOriginalPlayerRequestDecoderProvider)(void);
/** MAIN-only initial owner-preparation wait. The host owns its bounded pending
 * queue and wakes it on actual services bind/failure. requestActive preserves
 * the original transport deadline/cancellation; completion must run once on
 * main. No timer, polling, replacement Core or master admission is supplied. */
typedef void (^ODOriginalPlayerResourcesPreparationWaiter)(ODResourceContextCurrent requestActive,
    void (^completion)(NSError *_Nullable error));
/** Native bootstrap resources and saved-team routes for the actual client.
 * The trusted host must supply its SAME scoped Core-backed projector and
 * current-context block. No page, source account, or second Core owns this.
 * Resources use the persisted new-profile skip policy. GET /teams uses only
 * the existing complete own-team projection; no team/default is created.
 * Full Home data and established collections are not manufactured. */
@interface ODOriginalPlayerResourcesAdapter : NSObject
@property (nonatomic, copy, readonly) NSArray<ODLocalTransportRoute *> *routes;
- (nullable instancetype)initWithProjector:(ODResourceResponseProjector *)projector
                           contextCurrent:(ODResourceContextCurrent)current;
/** Static routes may be installed before asynchronous Core scope admission.
 * The provider must return the exact projector issued from that SAME owner. */
- (nullable instancetype)initWithProjectorProvider:(ODOriginalPlayerResourcesProjectorProvider)provider
                                  contextCurrent:(ODResourceContextCurrent)current;
/** User-only resources need actual Core scope but no inferred native-master
 * acceptance. Saved-team responses additionally require genuine native-master
 * admission. Both predicates run only on main, never in the query validator. */
- (nullable instancetype)initWithProjectorProvider:(ODOriginalPlayerResourcesProjectorProvider)provider
                                  contextCurrent:(ODResourceContextCurrent)current
                            masterContextCurrent:(ODResourceContextCurrent)masterCurrent;
/** Adds original POST /teams. A nil/unverified decoder fails specifically;
 * there is no plaintext/base64-as-JSON fallback or unverified Core write. */
- (nullable instancetype)initWithProjectorProvider:(ODOriginalPlayerResourcesProjectorProvider)provider
                                  contextCurrent:(ODResourceContextCurrent)current
                            masterContextCurrent:(ODResourceContextCurrent)masterCurrent
                         requestDecoderProvider:(nullable ODOriginalPlayerRequestDecoderProvider)decoderProvider;
/** Login/home may arrive while the SAME owner's initial Core/services are
 * preparing. A nil waiter retains immediate readiness failure behavior. */
- (nullable instancetype)initWithProjectorProvider:(ODOriginalPlayerResourcesProjectorProvider)provider
                                  contextCurrent:(ODResourceContextCurrent)current
                            masterContextCurrent:(ODResourceContextCurrent)masterCurrent
                         requestDecoderProvider:(nullable ODOriginalPlayerRequestDecoderProvider)decoderProvider
                              preparationWaiter:(nullable ODOriginalPlayerResourcesPreparationWaiter)waiter;
- (instancetype)init NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
