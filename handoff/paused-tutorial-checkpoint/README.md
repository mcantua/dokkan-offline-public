# Original tutorial checkpoint adapter

`ODTutorialCheckpointAdapter` persists the original tutorial's own checkpoint
requests through the existing bound local-player Core. It does not implement a
replacement tutorial, battle, team, progression formula or grant.

The source request contract is exact `PUT /tutorial`, without a query for this
constructor/send path. Its body is an ordinary JSON object with signed32
`progress` and optional unsigned64 `timewarp`. The constructor does not create a
`sign` envelope. The shared body setter adds `timewarp` only when its raw field
is nonzero; a zero native field omits the key. Existing encoded battle builders
are a different path and are not generalized to this tutorial endpoint.

The common constructor initializes query136 empty. The actual352-byte ancestor
and712-byte game API constructor leave it unchanged. Preparation108 invokes
only the already-reviewed header builders before materialization, or retains
the request on the original deferred queue. The actual248-byte suffix helper
adds a question mark only for a nonempty query. No generic query support or
transport allowance was added. Source configured origins remain a separate
trusted host responsibility.

The actual240-byte setter invokes the same136-byte `Json::FastWriter` used
elsewhere. Its1100-byte recursive writer emits JSON object delimiters, quoted
member names and native integer text. The signed/unsigned formatters were
checked directly: base10 digits, with a minus sign for negative signed values.
The writer may append a line feed. The actual1284-byte materializer copies the
stored body into the known Foundation request bridge's nonstream HTTPBody.
There is no tutorial body encryption/encoded-field wrapper in this path.

The adapter deliberately admits only positive signed32 checkpoints, rejecting0,
negative values and the original internal999999 finish sentinel. It never
marks a tutorial finished. `timewarp` is validated lexically as a nonzero uint64
without floating-point conversion, then discarded from the mutation. It is
not saved as a clock, nonce, request ID or player progression.

Only the existing bound Creator services can supply the same native Core.
Each request obtains a current atomic player/scope snapshot, applies
`tutorial.progress` with that revision and scope, then checks the fresh durable
readback before creating plain HTTP200 `{}`. The current Core rejects writes
while a Creator lease is held. Scope, current services/Core identity, active
transport request and actual checkpoint readback are checked; a failed mutation
cannot produce success. Cancellation after commit does not roll back the saved
checkpoint or manufacture a second grant.

A fresh private UUID is retained for each native transport-request object.
Repeated handling of that same object reuses its intent; it does not create
another command. This is our local command identity, not a claimed original
wire request ID. Different source HTTP retries are not guessed to share an ID
based on timewarp, request bytes or progress. Core's unchanged-checkpoint
operation has no new reward, completion or revision effect. A cached successful
native-request reply rechecks current canonical scope before delivery.

The response contract reuses the exact tutorial final `void()` consumer, common
plain-object-without-sign selector and four optional-root processors. An empty
object skips those optional model updates. The original failure callback also
continues its captured completion; that behavior is never used to disguise a
failed canonical write as committed success.

The immutable route candidate is separate from global registration. No host
route is installed by constructing this adapter; actual original startup,
master compatibility, login, initial User projection and application route
composition remain their own gates. Source readiness is not a native/gameplay
acceptance receipt.

This implementation received manual source review only. No C/Objective-C
compilation, new runtime/SQL test, native build, game launch, real save, User
contents, source key or signing material was accessed. Prior Core13 SQL and
ordinary-response evidence was reused. Real tutorial checkpoints and replay/
cancellation behavior still need one focused native check when builds are
explicitly authorized.
