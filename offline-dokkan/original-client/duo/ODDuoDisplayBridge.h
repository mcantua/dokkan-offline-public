#import <UIKit/UIKit.h>
#import "ODDuoViewport.h"

NS_ASSUME_NONNULL_BEGIN
@interface ODDuoDisplaySnapshot : NSObject
@property(nonatomic, readonly) CGRect bounds;
@property(nonatomic, readonly) UIEdgeInsets safeArea;
@property(nonatomic, readonly) CGFloat displayScale;
@property(nonatomic, readonly) BOOL reservedRegionsAvailable;
@property(nonatomic, readonly) BOOL reservedRegionReadComplete;
/* Each region has kind, active and CGRect-valued frame, in view coordinates. */
@property(nonatomic, readonly, copy) NSArray<NSDictionary *> *regions;
/* Scene geometry only; fillsScene is not proof of full physical Duo display. */
@property(nonatomic, readonly, copy) NSDictionary *sceneGeometry;
/* Rejects incomplete/unavailable reserved-region reads. Raw bounds/safeArea
   remain available to a host with another verified native layout contract. */
- (BOOL)fixedCanvasWithLogicalSize:(CGSize)size result:(ODDuoViewport *)result;
@end

typedef void (^ODDuoDisplayHandler)(UIView *renderer, ODDuoDisplaySnapshot *snapshot);

/* Host API: retain this per live renderer, call refresh after layout/safe-area
   changes, and refreshAfterTransition with its actual transition coordinator.
   This object never replaces/resizes the original renderer or changes saves. */
@interface ODDuoDisplayBridge : NSObject
- (instancetype)initWithRenderer:(UIView *)renderer handler:(ODDuoDisplayHandler)handler;
- (void)refresh;
- (void)refreshAfterTransition:(id<UIViewControllerTransitionCoordinator>)coordinator;
@end

/* Optional verified original-client attachment. Observes only CCEAGLView's own
   v16@0:8 layoutSubviews method, invokes its original implementation first, and
   reports geometry. Does not configure the game renderer or make its SDK26
   executable a genuine SDK27.1 scene-based app. Must run on the main thread. */
BOOL ODDuoInstallOriginalRendererObservation(ODDuoDisplayHandler handler,
                                             NSError * _Nullable * _Nullable error);
BOOL ODDuoRemoveOriginalRendererObservation(void);
NS_ASSUME_NONNULL_END
