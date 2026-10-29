# Actual original-client startup ownership

This is a static review of the existing native composition, not a launch or
gameplay result. No new UI, replacement engine, app build, or test run was made.

The genuine shell remains UIKit's application delegate. In
`ios/ODOriginalClientBootstrap.m`, the pinned shell's own launch method is called
on its original shell object. A separate, strongly retained original
`AppController` is allocated and receives its own launch selector. Original
methods are never called with the shell object as their receiver. The supplied
controller provider returns that same original object to the Duo scene bridge.

The shell's scene-configuration method is explicitly replaced because the
genuine shell hardcodes its previous WebView scene delegate. A manifest change
alone cannot select the original-game scene. After the original controller has
created its legacy window and renderer, `ODDuoOriginalSceneDelegate` verifies
the source ivars and classes, moves the same `RootViewController` and
`CCEAGLView` into a scene-owned window, and keeps the hidden legacy window alive.
Disconnection restores the controller to that legacy window. Scene callbacks
forward the original foreground/background methods; the shell only forwards
termination, avoiding duplicate application/scene lifecycle delivery.

The current install order is important:

1. Pin the genuine baseline/current shell identities and register the local
   Foundation transport.
2. Enter `ODLoadPreparedOriginalEngine`'s configuration callback. Native
   resource/state directory preparation runs here, before `dlopen`.
3. Load the pinned prepared engine. Its ordinary dyld initializers execute
   during this call, including the recorded 5,259 initializer offsets whose
   bodies have not all been reviewed.
4. Run the optional `attachPreparedImage` callback, then verify the source HTTP
   ABI, register the actual controller provider and scene bridge, and install
   the genuine-shell launch/scene wrappers.
5. Return to the shell's `UIApplicationMain` path. Its launch wrapper creates
   and launches the actual original `AppController`; the scene then adopts the
   real original renderer.

Consequently, an attachment callback after `dlopen` is too late to guarantee
initializers did not already open a master database or inspect resources.
Byte-preserving startup files and any required native filesystem preparation
must be ready before step 3. This does not authorize guessed close/reopen calls
or modifying native key handling.

Concrete unresolved gates remain. The integrated factory is not implemented;
integrated host installation requires staged derived master, reviewed routes,
native image attachment, and same-save services or admitted deferred services.
The host intentionally rejects the two unverified auth routes. A separate
diagnostic can omit those integrated requirements, but it still requires the
real prepared engine's `AdjustSigSdk` dependency and original startup resources.
Loading only the retained shell and engine cannot satisfy that dependency.
Recovering two pinned startup files does not establish a complete resource set.

This review found no proven controller/window ownership defect to patch. The
next useful evidence is an admitted original diagnostic launch with actual
inputs, followed by the native master/auth contracts. Exact runtime SDK/ABI,
scene adoption, display behavior, original login/home/battle, and persistent
saves remain unverified.
