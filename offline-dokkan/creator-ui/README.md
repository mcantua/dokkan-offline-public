# Shared Creator screens in our Offline host

This embeds the actual Unit Creator controllers in the separate, original Offline Dokkan host. It is not a hook into the original game's app, a verified battle renderer, or a claim of drawable banners.

Stage the UI without building an APK or IPA:

```sh
python3 offline-dokkan/creator-ui/build.py
```

Serve the single generated `site/` tree through the native host's fixed local resource origin. The directory is ignored and overwritten. Native package builders should invoke this staging command; no database is needed to stage it. `projection-tables.json` comes directly from the existing strict projector's `supportedTables`, and `ui-manifest.json` records every staged file's SHA-256.

The dependency review in `reviewed-ui-files.json` must match the current shared index. New modules need a data review before being included. This prevents a newly added data-bearing script from silently entering the Offline package.

## No bundled game data

The stage copies reviewed original JS/CSS, original UI artwork, UI fonts and their OFL notices, and the licensed Lua parser already referenced by the shared screen code. It excludes:

- All `v2/ui/data/` files, databases, raw APK/IPA files, wiki and movie catalogs, reference metadata and animation-availability snapshots.
- `passive-catalog-data.js` and source-script hash catalog `preview-opponent-scenes.js`.
- Inline game scene/domain/counter/revival/BGM catalogs in `special-skills.js` and `builder-model.js`. Only those known declarations are replaced; a changed declaration fails staging for review.

The selected user's native master supplies compact runtime references through bounded, read-only column queries. Entrance/counter/revival labels come from actual master passive ownership; Domain names, descriptions, resources and durations come from master fields/efficacies. Passive variants and default values come from observed rows in that selected master. The UI retains authored mechanic labels and editor rules. No game data, catalog, master path, signing key, AI key or Sparking key is emitted into the staged tree.

Remote game thumbnails are replaced with an original neutral SVG. CSP blocks remote scripts, images, network and frames. Imported asset/battle integration is separate work; this settings-only bridge rejects unsupported operations and retains full editable projects rather than silently discarding their unsupported features.

## Fixed bridge

Before loading shared controllers, `host-adapter.js` requests pinned `info` and derives references. `bootstrap.js` then loads the actual reviewed scripts in their original order and starts their real `boot()` only after all controllers exist. It does not copy the browser database shim.

The fixed `OfflineCreator` capability uses:

- iPhone: `window.webkit.messageHandlers.OfflineCreator.postMessage({op,args})`, returning a Promise.
- Android: `window.OfflineCreator.postMessage(JSON.stringify({id,op,args}))`, with `__offlineCreatorReply({id,ok,result,error})`. Requests allow 24 MiB including their JSON envelope around a native project of up to 20 MiB. Large responses use ordered `__offlineCreatorReplyChunk(id,index,total,text)`: at most 2,048 unique ordered chunks of 24,000 UTF-16 characters and 32 MiB of final UTF-8 JSON.

`info.offlineCreator` includes only native-pinned `sourceDatabase` and `contentId`. The selected game names the document/Creator heading and info source; templates receive matching `source.database` and `source.contentId` before returning to shared screen logic. Eclipse sessions explicitly reject `querySparking` and report its catalog unavailable. Both aliases in a Sparking session query only its selected Sparking master; a second master is never implied. Read-only `query`/`querySparking` accept validated table/columns, scalar filters, ID lists, search, order, limit and offset, never SQL or paths. The native capability also supplies actual card indexes and durable JSON projects/versions; media, external network and arbitrary core/policy commands are not exposed.

`ui-adapter.js` adds **Finish in Offline Dokkan** around the existing screens:

1. Pin the actual current project to its selected source, run the existing `Forge.hydrateStatGrowth` against that read-only master to capture any changed high-level stat policy, then confirm it saved.
2. Call `offlineCreatorPrepare({key})`. Native returns an opaque persisted intent, its durable project snapshot, pinned context and table names whose complete baseline rows were proven unchanged against that master.
3. Pass a settings-only snapshot through `OfflineDokkanCreator.projectToDefinition`. When native prepare returns `fullBundle:true`, skip that projector. The page does not build the full packet.
4. Call `offlineCreatorFinish({key,snapshot,definition})` for settings. A full unit calls `offlineCreatorFinish({key,snapshot})`. Native rechecks the saved project. A full unit is validated, then imported once into the saved `local-player` account. Public `creator.finish` still rejects a full-bundle descriptor.
5. Require explicit `{imported:true,definitionId,version,library,banner}` confirmation. Display newest creation only when the actual library names it. A `not_configured` banner reports that trusted catalog allocation remains required; registration alone never claims it is drawable.

The native master is always read only. No file export/move is needed to finish, and projects remain editable in their own native store. The native implementations and their own-file lifecycle checks are owned by the mobile host modules.

## Focused verification

One cloud scenario loaded this staged real UI at outer/inner phone widths against each restored Eclipse and Sparking master. It created an actual `Forge.loadTemplate` project, saved an edited name, ran the strict projection, and invoked the existing C/SQLite `creator.import`; the result became the actual newest library record. Runtime references populated from each selected source, and both full master SHA-256 values remained unchanged. The harness used a cloud HTTP transport for UI control; actual WK/Android bridge integration is a separate native cohort check. No native packages were built for this change.

A later targeted selected-source check used the actual visible finder and selected full source rows. Eclipse source `1007471` rejected `querySparking` before transport. Sparking-only eligible source `1899771`, absent from the Eclipse master, returned its actual 56-column card through `querySparking`; template source game/content identity and the UI title matched its pinned master. Raising each source to GR level 200 before Finish refreshed the existing explicit Creator stat policy and successfully registered the actual core definition. Both master hashes stayed unchanged. Incomplete six-digit Sparking placeholders with no leader/passive sets remained excluded. This did not repeat movie/codec or the earlier general UI suite.
