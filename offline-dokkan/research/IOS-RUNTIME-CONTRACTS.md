# Original iPhone client: static Objective-C ABI

`tools/objc_runtime_metadata.py` reads the supplied binaries without executing or modifying them. It emits only reviewed class, selector and ivar names, their type encodings, byte offsets/sizes and structural counts/hashes. It never dumps strings, application bytes, payloads, profiles or keys. The exact sanitized results are in `ios-runtime-contracts.json`.

## Inputs and supported decoding

- Actual main executable:55,697,728bytes, SHA256 `9d6bf0470c4b4ff7d914740ccf9f1622afa962b763e18bfcf1f6e051bfae0610`.
- Actual source patcher:5,657,724bytes, SHA256 `74e47aa75fdbd828fa3918a966b50457e8497143962d5be573cb60f332e055dc`.
- Thin little-endian arm64 only, bounded file/commands/sections/fixups/strings/method lists. Encrypted input, unresolved binds needed by selected metadata, unsupported pointer formats and multi-start chains reject. No bind symbols or arbitrary method names are emitted.
- Main uses dyld `PTR_64_OFFSET` format6. The inspector resolved702,664 rebase locations and retained41,447 unresolved bind locations without emitting their symbols. Patcher has no chained-fixup command and uses its static VM addresses. File-backed VM mapping is checked before every metadata read.
- Methods come from each selected class's own instance/metaclass list. They do not include inherited methods. Absence here means no matching own method was emitted, not that the runtime object lacks an inherited selector.

## HTTP bridge verified signatures

All following are instance methods on the actual main's `HttpAsynConnection`.

| Selector | Exact Objective-C encoding |
| --- | --- |
| `startRequest:` | `v24@0:8@16` |
| `responseData`, `responseHeader`, `statusString` | `@16@0:8` |
| `setResponseData:`, `setResponseHeader:`, `setStatusString:` | `v24@0:8@16` |
| `responseCode` | `q16@0:8` |
| `connection:didReceiveResponse:`, `connection:didReceiveData:`, `connection:didFailWithError:` | `v32@0:8@16@24` |
| `connectionDidFinishLoading:` | `v24@0:8@16` |

Allowlisted ivars are `responseHeader` (`NSDictionary`,offset32), `responseData` (`NSMutableData`,offset40), `responseCode` (signed64-bit,offset56), and `statusString` (`NSString`,offset64); all are8bytes. No `setResponseCode:` method was emitted from this class's own list. Do not replace the signed64-bit return with an assumed32-bit `int`.

The source patcher's `LocalResponseHandler` has class method `handleResponseForParsedRequest:originalData:statusCode:error:` with exact encoding `@48@0:8@16@24q32^@40`. The allowlisted announcement/event/my-data/quest-start/briefing handlers take two objects and return an object (`@32@0:8@16@24`); its ping handler is `@24@0:8@16`. This establishes static ABI only. It does not establish concrete request/response classes, data schema, internal side effects, thread/ownership contracts or safe use as our offline server. No source dispatcher was invoked.

## App and renderer entry points

- `AppController` instance `application:didFinishLaunchingWithOptions:` is `B32@0:8@16@24`; the selected background/foreground/active/termination callbacks are `v24@0:8@16`. Its `window` ivar is `UIWindow` at offset8 and `_viewController` is `RootViewController` at offset16.
- `CCEAGLView` class `layerClass` is `#16@0:8`; instance `initWithFrame:` is `@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`; `layoutSubviews` and `swapBuffers` are `v16@0:8`.
- `RootViewController` instance `shouldAutorotate` is `B16@0:8`; `supportedInterfaceOrientations` is `Q16@0:8`.

A `Class` return encoding does not identify which layer class is returned. CGRect initialization and a layout selector do not prove resizing updates the original Cocos projection, drawable or touch transforms. Native viewport/transport components must remain explicitly detached until the actual attachment and callback behavior are verified.

## Focused verification and remaining work

### Actual main entry

The actual `LC_MAIN` entry is a96byte function. Its indirect-symbol-table imports and the referenced class/CFString establish this sequence: allocate/initialize `NSAutoreleasePool`, call `UIApplicationMain` with the original argc/argv, nil principal class and delegate-class string `AppController`, release the pool, then return UIKit's result. No additional game-engine setup occurs in that entry body. The committed JSON records its code hash and facts without code bytes or addresses.

This does not establish original `AppController` startup, image initializer behavior/order, patcher bootstrap side effects or whether an authored wrapper can safely transfer control. Do not treat a plain `dlopen` of an executable as established by this review.

### Selected HTTP implementation evidence

The existing pinned NDKr28b `llvm-objdump` was used only on five actual HTTP own-method spans, bounded by the main's `LC_FUNCTION_STARTS`. Raw instruction bytes were suppressed; private assembly/reference files remain ignored. The committed evidence records only each span's size/hash and reviewed semantic facts, never implementation bytes, addresses, arbitrary strings or credentials.

- `startRequest:` preserves its object argument and forwards it unchanged into `initWithRequest:delegate:startImmediately:`. The constructor receiver's chained import resolves specifically to `NSURLConnection` (main import format3). Delegate is `self`; startImmediately is false. It obtains `NSRunLoop.currentRunLoop`, schedules the connection via `scheduleInRunLoop:forMode:`, then calls `start`. The method therefore follows Foundation's NSURLRequest-compatible loader contract. No dictionary-to-request conversion occurs at this entry. The argument's concrete runtime instance/subclass and construction upstream remain unobserved.
- The response callback reads `allHeaderFields` and `statusCode`, stores the signed64-bit status at the verified responseCode ivar, uses `localizedStringForStatusCode:` and resets the data buffer's length. The data callback calls `appendData:` on the verified responseData ivar and increments a counter at offset48.
- `connectionDidFinishLoading:` only writes1 to the completion byte at self+8 and returns. It does not dispatch a game callback. The failure callback forwards its error argument to another object-argument setter and writes the same completion byte. The setter's exact name is omitted until independently admitted; this is not a verified error-object ownership contract.

These facts support investigating Foundation URL loading as the insertion point rather than fabricating the object's response/callback sequence. They do not prove a registered URLProtocol is reached in this app, callback scheduling/order under interception, source-patcher hook coexistence, the Cocos polling/completion path, or current game-server response schemas. Do not manually write completion/ivar offsets or invoke the source patcher based on this static review.

One combined actual-input scenario verified main/patcher metadata, exact source hashes and unchanged file size/mtime; malformed magic rejected. Earlier targeted invocations established the initial main/patcher decoder and exposed no unsupported-format fallback. No full application suite, HTML rebuild or native package build was run.

Next: establish upstream HTTP request construction, the Cocos completion/polling path and actual Foundation interception/coexistence, original renderer attachment/resize semantics, and current local wire/data contracts. Static ABI/call paths are not a game launch, offline login/battle, integrated Creator success or Duo display proof. Main SDK26.0 remains unchanged and does not meet the existing genuine SDK27.1/Duo acceptance requirement.
