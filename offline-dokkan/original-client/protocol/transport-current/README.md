# Current original-client Foundation transport

The existing local transport can serve the preserved client's actual
`NSURLConnection` path. No speculative Cocos callback replacement is required.
The earlier original-executable review is in `ios/README.md` and
`research/ios-runtime-contracts.json`; this folder retains the matching prepared
image method identities so they can be reused without repeating that review.

The source `HttpAsynConnection.startRequest:` forwards the original request
argument to `initWithRequest:delegate:startImmediately:` with the original
connection object as delegate and `startImmediately:NO`. It schedules the
connection on the current run loop and starts it. Its response delegates read
headers/status, reset and append the mutable response buffer, and set the
completion byte on finish/failure. The 2,960-byte Foundation bridge sets request
method/headers/body, calls `startRequest:`, services the run loop, then reads the
response fields. A direct cancel selector was not observed in this bridge's
bounded body; complete cancellation/timeout semantics are not established by
that absence.

`ODInstallPreparedDuoShellBootstrap` registers `ODLocalURLProtocol` before
loading the prepared engine. Requests reaching that protocol are handled by
owned local routes or fail; there is no forwarding fallback. This registration
supports the reviewed Foundation path. It does not prove containment of SDK
sessions, WebKit, raw sockets, dynamic resolution, or dyld initializers.

The protocol serializes route dispatch and ignores late or duplicate response
completion after stop/completion. It strips original account headers from the
local request object. Each future state-changing route still needs native
same-save scope checks and idempotent commands; cancelling an HTTP request is
not proof that an already-dispatched state change was rolled back.

The immediate compatibility frontier is URL construction. The current
664-byte URL builder selects HTTPS for port 443, HTTP otherwise, appends an
explicit port unless it is 80, and appends `/` plus its 248-byte relative-URL
helper. That helper inserts `?` only when the query string at offset 136 is
nonempty. The nonce constructor and sign-in constructor chain reach the same
420-byte common constructor, which initializes that string from an empty
literal; their derived constructors leave it unchanged. These constructed auth
requests therefore fit the existing no-query transport policy. Query rejection
stays intact. This does not exclude later mutation outside the reviewed
construction or establish runtime request delivery. Origins, route/body
contracts, and actual login remain separate gates.

`inspect_transport.py` reads only bounded current-client methods and emits
reviewed selectors/body hashes publicly. Private addresses and annotated
instructions remain under ignored `private/research-transport`. No original
code execution, transport swizzle, app build, route enablement, or runtime
interception is claimed.
