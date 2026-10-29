# Original first-run tutorial selection and persistence boundary

The supplied original iPhone engine contains the tutorial selection and
execution system. The offline adapter must feed that system and retain its
actual checkpoints. It must not construct a replacement sequence, invent a
starter team, or require normal team selection before an original tutorial
battle. All facts below are static; no game was executed.

## Title loading selects the tutorial from User state

A172-byte callback obtains the actual profile container and its shared User,
then reads the same byte145 that the reviewed decoder fills from
`user.tutorial.is_finished`. False branches directly to the512-byte
`TitleLoadingLayer::onTutorialProgress` method. True takes a different title
continuation. Two callback RTTI records created inside that512-byte method
confirm its exact enclosing source name and `void()` callback signatures.

`onTutorialProgress` obtains that same User and passes its32-bit `progress`
member120 into the608-byte tutorial cache owner. A separate native tutorial
mode flag can force the argument to0. The owner loads the actual phase, step
and process definitions, constructs their related native models, and obtains
its own ordered process list. For a nonpositive signed32 progress argument,
it takes the first process in that native list and asks the original progress
composer for its selector. Positive progress uses the supplied selector.

This is an actual User→tutorial consumer chain. It establishes what0 does in
the selected original code: select the beginning of the original loaded
sequence. It is not a claim that a raw master row ID equals wire progress,
nor a copied server/new-account default. No particular first process ID was
hard-coded or inferred from table order.

The240-byte composer follows two parent-model links and returns, using native
32-bit arithmetic:

```
ancestor component × 10000 + parent component × 100 + process component
```

Those component fields still need their exact model-column bindings before
this formula is named as a master-number codec or implemented in authored
code. Reuse the original composer/selector. Do not replace the composite
selector with a phase ID, step ID or process ID.

The608/512/240/172-byte scoped decompilations and the372-byte ordered-list
helper have no high-Pcode instruction sites outside their declared bodies.
Raw code, pointers and callback RTTI details remain ignored and private.

## The original progress write is a checkpoint request

The real issuer is
`Tutorial::TutorialModel::putTutorialProgress(int, function<void()> const&)`,
808bytes. It creates the actual `Tutorial::TutorialAPI` request using an80-byte
factory and the already-reviewed264-byte request constructor. The established
method is `PUT`, relative suffix `/tutorial` with query behavior still to be
bound. Its body contains the caller's signed32 `progress` and the previously
reviewed opaque native `timewarp` value. See `TUTORIAL-UPDATE-CONTRACT.md`.

The issuer's only direct396-byte caller gets the next process's composite
progress and tests the native resume/step boundary before issuing the write.
The44-byte next-progress getter returns-1 when there is no next process.
The caller converts that absence to its internal999999 value and takes a
different native advance/finish path, rather than passing-1 through this PUT.
Do not adopt-1 as a server tutorial-completion request or mark the tutorial
finished because this getter returned it.

The32-byte success closure has exact RTTI `void()` and only calls the captured
completion. The156-byte failure closure has exact RTTI
`void(shared_ptr<WebAPI::Error>)`, also invokes that completion, and releases
its error ownership. A local persistence failure therefore must never
be disguised as a successful committed checkpoint just to advance the UI.

## What the offline implementation can reuse

Preserve native tutorial selection, scripted combat, temporary characters,
animations and checkpoint timing. For a genuinely new canonical profile,
the approved start-at-the-beginning policy can be expressed through the
observed false/0 control flow after native state authority is provided.
Existing profiles must not be silently reset or migrated to that state.
`contents_lv`, starting storage limits, grants and completion behavior remain
independent contracts; this trace supplies no invented values for them.

A durable local checkpoint operation should retain the actual received
progress under the same native-owned profile/save/content scope. It must
commit before returning success and preserve the same value on a retry.
It must not infer grants, completion, phase IDs or clock changes from the
opaque request fields. This document alone does not add that operation.

## Exact remaining response bridge

The issuer wraps the API in the real `WebAPILayer` through a164-byte factory
and464-byte constructor. These are actual original-client objects, not an
authored task system. The ordinary `WebAPIBase::send` success wrapper and
`WebAPICaller::call` success callback still need their required JSON/status
behavior tied to this request before a complete response is admitted.

The common1284-byte materializer is already bound to this actual TutorialAPI
vtable. Its reviewed HTTP completion gives the parsed document root to the
success callback. That reusable fact does not prove that WebAPILayer accepts
an empty object. No `{}` response, route or working tutorial battle is claimed.

## Reproduce the exact continuation

```
python3 offline-dokkan/original-client/protocol-inspection/recover_tutorial_runtime.py \
  offline-dokkan/private/source-client/OriginalDokkanEngine.dylib \
  --private-output offline-dokkan/private/research-tutorial/reviewed-runtime-spans.private.json
```

This reuses the existing body-pin recovery, without reading any game database
or source account. It restores14 exact reviewed spans for a scoped analysis
continuation. Keep the resulting coordinates private. No app build, device,
personal connection, save folder, key or source-file modification was used.
