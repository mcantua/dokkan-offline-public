// Native bootstrap-private entry. Never expose this to the Creator/WebView bridge.
#import "ODLocalURLProtocol.h"
@class ODOriginalNativeOrigin;
NS_ASSUME_NONNULL_BEGIN
/** Called only after the bootstrap pins the actual source files, before the
 * reviewed game-image loader runs any original initializers. ABI verification
 * follows image loading and must pass before the original UIApplicationMain. */
BOOL ODInstallLocalTransportForPinnedBootstrap(NSArray<NSURL *> *origins,
                                               NSArray<ODLocalTransportRoute *> *routes,
                                               NSError **error);
/** Main-only one-use transition from the already-installed empty-origin,
 * empty-route deny-all configuration. Only the loader-issued, still-current
 * original-image origin capability can admit the owned native routes. Keeps
 * the original serial queue; old configuration requests cannot deliver success.
 * No generic origin setter, remotely supplied configuration or WebView entry. */
BOOL ODRearmLocalTransportForLoadedOriginalOrigin(ODOriginalNativeOrigin *origin,
                                                  NSArray<ODLocalTransportRoute *> *routes,
                                                  NSError **error);
NS_ASSUME_NONNULL_END
