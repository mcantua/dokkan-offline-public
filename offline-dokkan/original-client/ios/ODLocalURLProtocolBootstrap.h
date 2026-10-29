// Native bootstrap-private entry. Never expose this to the Creator/WebView bridge.
#import "ODLocalURLProtocol.h"
NS_ASSUME_NONNULL_BEGIN
/** Called only after the bootstrap pins the actual source files, before the
 * reviewed game-image loader runs any original initializers. ABI verification
 * follows image loading and must pass before the original UIApplicationMain. */
BOOL ODInstallLocalTransportForPinnedBootstrap(NSArray<NSURL *> *origins,
                                               NSArray<ODLocalTransportRoute *> *routes,
                                               NSError **error);
NS_ASSUME_NONNULL_END
