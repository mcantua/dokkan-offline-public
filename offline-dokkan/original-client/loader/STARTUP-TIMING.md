# Original diagnostic startup timing review

This is source review only. No original client, app assembler, native compiler,
test, signing operation or device was run. The next useful runtime check, once
builds are explicitly authorized, is a fresh own diagnostic container reaching
the actual original scene's first frame. This review is not that evidence.

The diagnostic constructor calls
`ODCreateOriginalDuoStartupDiagnosticHost` before the retained shell reaches
`UIApplicationMain`. Its compatible resource preparation uses one newly
created serial queue and `dispatch_sync`. The call returns only after the
catalog, exact admitted requirements, source bytes and working publication have
completed or failed. The block calls native FD/resource APIs and a plain
currentness callback. It never waits for a main-queue callback, semaphore,
WebKit evaluation, renderer or UIKit scene. No asynchronous resource worker is
left for the genuine main to race. `dispatch_sync` does not guarantee a
different physical thread: the important property here is completed serial
preparation before main and before original `dlopen`, not a claim that hashing
cannot occupy the calling thread.

`ODUnifiedDuoHost.installBeforeApplicationMain:` then enters the existing
bootstrap synchronously. The local Foundation transport is installed before
the prepared-image loader enters its environment callback and `dlopen`.
Original native initializers execute during `dlopen`; only afterward can the
optional image attachment callback run. Attachment is therefore not a valid
place to promise pre-initializer resources or database preparation. Unsupported
request observations are queued asynchronously to main and are not waited on
by this diagnostic's zero-route transport.

`ODOriginalClientBootstrap` registers the original-controller provider and
actual renderer scene bridge, then replaces the exact admitted shell launch
and scene-configuration methods. All of this finishes before the constructor
returns. It uses no asynchronous provider initialization. The launch wrapper
calls the pinned shell's own launch implementation on its proper shell object,
then strongly retains a separate real `AppController` before calling that
object's own launch selector synchronously. The source shell's launch returns
YES, and its main directly enters `UIApplicationMain`; its WebView belongs to
the old `SceneDelegate`, which the installed scene-configuration wrapper no
longer selects. No waiting WebKit bootstrap is introduced into this path.

The scene provider returns that same original controller. The scene bridge
requires main-thread delivery, verifies the actual source window/controller
ivars and renderer classes, and requires an already-loaded original root view.
It moves that same root/renderer into the scene-owned window, retaining the
hidden legacy window for the original owner. Disconnection restores the root
to that legacy window. It does not allocate a replacement game view or call a
guessed C++ start function. The provider itself cannot race a background
creator or resource task in this diagnostic. Actual UIKit callback ordering,
the native launch's completed state, renderer behavior and reconnect behavior
still need observation on the admitted client.

One concrete startup blocker was found outside this module: the host's
source-patcher absence probe walked the uncanonicalized native Frameworks URL
with `O_NOFOLLOW`, which could reject iOS's OS-owned `/var` prefix. The host
owner fixed that probe through its trusted-root canonicalization and native/
canonical FD identity checks. The diagnostic separately preserves the exact
native engine URL spelling required by the prepared loader while preflighting
the canonical root. No shared host/auth/master file was edited by this review.

The authored diagnostic path contains no proven main-queue/semaphore deadlock
or unfinished asynchronous preparation edge requiring another patch. This is
not an exhaustive claim about all 5,259 original image initializers, the
embedded SDK, native callbacks or runtime system services. A dyld return,
original first frame, scene transition and ordinary offline request failure
must be observed before claiming the diagnostic launches correctly. Offline
login, gameplay, save acceptance and both Duo displays remain separate actual
runtime requirements.
