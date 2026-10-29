# Original renderer across Duo scene changes

Source review only; no simulator, app/native build, device, test or screenshot
was used. Actual first-frame rendering, touch alignment, camera-safe HUD
placement and both physical Duo displays remain unverified.

The admitted game has one original `AppController`, `RootViewController` and
`CCEAGLView`. The provider retains that original controller across scene
disconnect. Scene admission reads its existing window/root ivars without
changing the source object's ownership fields. The same root and renderer move
to the own scene window; the legacy window stays hidden and retained. On
disconnect the root returns to that hidden legacy window for a later scene
connection. No original launch, battle, player state or renderer is recreated
by this transition path.

One narrow ownership gap was corrected: `willConnectToSession:` previously
ignored the provided session and admitted any `UIWindowScene` when no scene
was active. The shell's scene-configuration wrapper can supply this delegate
for other roles. A non-application/external scene connecting first could then
take the single original renderer. Admission now requires that exact scene's
session and the primary application role before consulting the original
provider or touching its window/controller. This preserves the single original
game on the admitted application scene; it introduces no external-display game
or second renderer. Unsupported roles and additional scenes return without
emitting the primary host's failure callback, so they cannot clear an existing
Creator attachment or mark the working primary scene failed. A mismatched
first primary scene/session still rejects before original-provider access.
The guard has not been compiled or executed.

The original layout method runs before geometry observation. Observations use
the renderer's actual bounds, safe-area insets and trait display scale. The
scene bridge updates its real Metal layer's drawable size to those view pixels;
if scale changes, it requests the original layout again so the source's own
pixel-size pair follows the same scale. The reentry guards prevent the
observer's layout refresh from recursively delivering another scene update.
No transform, guessed logical design resolution or independent aspect/touch
conversion is introduced. Original touch handlers continue receiving the same
view and its native content scale.

Scene coordinate/trait updates request layout immediately and once after
settling. Delayed delivery uses a weak scene plus active-scene/generation
checks. The optional geometry bridge separately retains only a weak renderer,
and its transition callbacks use a weak bridge and generation checks. An old
renderer cannot keep a game/controller alive through that observation path.
UIKit owns scene-window sizing; absence of another explicit window-frame write
on every update alone does not establish a resize defect. No speculative
window/frame or original camera-policy rewrite was made.

Original background delivery survives scene delegate replacement. A held
Creator pause lease continues to withhold foreground/resume; a disconnected
scene does not restart the game by dropping UI references. Original root/view
identity and native lease state are rechecked when returning to gameplay. The
static path preserves these invariants; physical fold/reconnect and native
pause/render behavior still require actual acceptance.

Reserved-region reads remain explicit availability/completeness observations.
An incomplete read cannot authorize the optional fixed-canvas helper. That
helper is not applied to the original game merely to make it fit a screenshot.
Full-window drawable pixels do not establish native logical projection or safe
HUD layout. Those missing runtime/native contracts must be observed or proved
before altering the approved original presentation.
