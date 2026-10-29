#import <UIKit/UIKit.h>
#import "ODLocalURLProtocol.h"

NS_ASSUME_NONNULL_BEGIN
/** Trusted native loader callback, implemented by the reviewed original-image
 * adapter. File descriptors remain bootstrap-owned, read-only, and open during
 * the callback; do not close them. No raw MH_EXECUTE dlopen is assumed.
 * The loader must verify its prepared image, exclude the source patcher and
 * establish concrete native preparation before initialization. A controlled
 * startup diagnostic is not a claim of complete offline/network containment. */
typedef BOOL (^ODOriginalClientLoadImage)(int originalExecutableFD, int sourcePatcherFD,
                                           NSError **error);

/** Register the verified original-window/renderer/embedded-Creator observation
 * bridge before UIApplicationMain. It must preserve the real AppController and
 * attach only after its actual UIWindow/render view exist. */
typedef BOOL (^ODOriginalClientRegisterSceneBridge)(NSError **error);
/** Native compiled prepared-image verifier/loader. It must validate its own
 * pinned transformation/code/binding recipe against the build-time source pin
 * before image initialization. No source patcher or duplicate source executable
 * needs to be embedded in the final app. Never supply this from JSON/JS. */
typedef BOOL (^ODPreparedOriginalClientLoadImage)(NSError **error);

/** Real authored launcher entry for a genuine SDK27.1+ Duo target. It pins exact
 * supplied source files, installs local Foundation handling before image load,
 * verifies the now-loaded actual HTTP ABI, registers original-scene observation,
 * and invokes the verified UIApplicationMain(argc,argv,nil,@"AppController").
 * A failed gate returns EXIT_FAILURE; no live/original-main fallback executes.
 * This entry does not define any game response projections or claim to contain
 * raw sockets. The reviewed image loader and actual contracts remain required.
 * Call once, on the main thread, before any UIApplication singleton is created. */
FOUNDATION_EXPORT int ODRunPinnedOriginalClient(int argc, char * _Nullable * _Nonnull argv,
    NSURL *originalExecutableURL, NSURL *sourcePatcherURL,
    NSArray<NSURL *> *approvedOrigins, NSArray<ODLocalTransportRoute *> *routes,
    ODOriginalClientLoadImage loadImage,
    ODOriginalClientRegisterSceneBridge registerSceneBridge, NSError **error);

/** Concrete preserved-genuine-shell path. Called by the authored plugin before
 * the exact SDK27.1 shell reaches main. The source-shell baseline is pinned to
 * the genuine CI executable; the active host must preserve its reviewed section
 * identity, body bytes and load commands, allowing only authored plugin loading
 * and code-signature metadata changes, and retain actual iOS27.1/min16.4.
 * The plugin itself may use older headers: the verified MAIN host sets UIKit's
 * compatibility tier. OS signing/install validation remains independently
 * required; section identity alone is not treated as signature attestation.
 * On NO the plugin caller MUST stop process startup, not run the old shell UI.
 * Replaces only the verified own shell AppDelegate launch/scene methods with
 * authored wrappers. The real AppController is allocated separately at launch.
 * Scene owns active/background forwarding; termination is forwarded separately.
 * Loader and scene registrar obligations match ODRunPinnedOriginalClient. */
FOUNDATION_EXPORT BOOL ODInstallPinnedDuoShellBootstrap(
    NSURL *genuineShellBaselineURL, NSURL *originalExecutableURL, NSURL *sourcePatcherURL,
    NSArray<NSURL *> *approvedOrigins, NSArray<ODLocalTransportRoute *> *routes,
    ODOriginalClientLoadImage loadImage,
    ODOriginalClientRegisterSceneBridge registerSceneBridge, NSError **error);

/** Final prepared-image variant of the same genuine-shell/bootstrap gates.
 * The reviewed compiled loader proves/loads its prepared engine directly;
 * original source-patcher bytes/keys remain outside the app. Exact source pins
 * belong in the private build-time recipe, not a runtime credential payload. */
FOUNDATION_EXPORT BOOL ODInstallPreparedDuoShellBootstrap(
    NSURL *genuineShellBaselineURL,
    NSArray<NSURL *> *approvedOrigins, NSArray<ODLocalTransportRoute *> *routes,
    ODPreparedOriginalClientLoadImage verifyAndLoadPreparedImage,
    ODOriginalClientRegisterSceneBridge registerSceneBridge, NSError **error);
NS_ASSUME_NONNULL_END
