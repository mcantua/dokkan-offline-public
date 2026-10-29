#import <Foundation/Foundation.h>
#import "ODLocalURLProtocol.h"
#import "ODResourceResponseProjector.h"

NS_ASSUME_NONNULL_BEGIN
/** Called only on main. The native factory returns its actual issued scoped
 * projector after Core admission, or nil while not ready. No values/snapshot
 * from a page can replace this native object capability. */
typedef ODResourceResponseProjector *_Nullable (^ODOriginalPlayerResourcesProjectorProvider)(void);
/** Native bootstrap resources routes for the actual original client.
 * The trusted host must supply its SAME scoped Core-backed projector and
 * current-context block. No page, source account, or second Core owns this.
 * Only the persisted new-profile skip policy is supported here; full Home
 * data and established collections are not manufactured. */
@interface ODOriginalPlayerResourcesAdapter : NSObject
@property (nonatomic, copy, readonly) NSArray<ODLocalTransportRoute *> *routes;
- (nullable instancetype)initWithProjector:(ODResourceResponseProjector *)projector
                           contextCurrent:(ODResourceContextCurrent)current;
/** Static routes may be installed before asynchronous Core scope admission.
 * The provider must return the exact projector issued from that SAME owner. */
- (nullable instancetype)initWithProjectorProvider:(ODOriginalPlayerResourcesProjectorProvider)provider
                                  contextCurrent:(ODResourceContextCurrent)current;
- (instancetype)init NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
