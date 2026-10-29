#!/usr/bin/env python3
"""Stage full shared/native Creator tools without private databases or media.

Public/authored reference metadata is explicitly listed in the manifest.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import shutil
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
UI = ROOT / 'unit-creator/v2/ui'
SITE = HERE / 'site'
EXCLUDED = {'passive-catalog-data.js', 'vendor/media/preview-opponent-scenes.js'}
IOS_ADAPTERS = ['argon2.js', 'zstd.js', 'eclp.js', 'web-native.js', 'ios-host.js', 'ios-native.js', 'ios-formats.js', 'ios-preview.js', 'ios-player.js', 'ios-assets.js', 'ios-sparking.js', 'ios-offline.js', 'ios-io.js']
TOOL_METADATA = {'animation-queries.json', 'preview-metadata-rules.json', 'preview-bootstrap.json', 'preview-script-index.json', 'sparking-animation-paths.json', 'sparking-reference.json'}
TOOL_REFERENCE_SCRIPTS = ['animation-availability.js', 'movie-catalog.js']
REPLACED = {
    'builder-model.js': {'COUNTER_ANIMS': 'counters', 'REVIVAL_VIEWS': 'revivals', 'REVIVAL_BGM': 'revivalMusic'},
    'special-skills.js': {'INTROS': 'intros', 'DOMAINS': 'domains'},
}


def strip_catalogs(name, source):
    for constant, field in REPLACED.get(name, {}).items():
        pattern = r'(?m)^(\s*)const ' + re.escape(constant) + r' = (?:\[.*\]|\{.*\});$'
        source, count = re.subn(pattern, lambda match: match.group(1) + 'const ' + constant + ' = window.OfflineCreatorReferences.' + field + ';', source)
        if count != 1:
            raise ValueError('Catalog stripping no longer matches ' + name + ':' + constant)
    if name == 'builder.js':
        marker = '  function saveHTML() {\n'
        if source.count(marker) != 1:
            raise ValueError('Shared Save screen changed; review the embedded completion hook')
        source = source.replace(marker, '  function saveHTML() {\n    const finish = window.OfflineCreatorUI ? OfflineCreatorUI.saveHTML() : "";\n    return window.OfflineCreatorTools ? finish + originalSaveHTML() : finish || originalSaveHTML();\n  }\n  function originalSaveHTML() {\n')
        source = source.replace('Send your unit to Dokkan Eclipse or Dokkan Sparking, then test its artwork, moves and battle mechanics.', 'Finish your unit to add it to this game’s collection and keep the design editable.')
        source = source.replace('Saved for Eclipse', 'Saved to your collection').replace('Design prepared — test it in Eclipse or Sparking.', 'Design prepared — finish in Offline Dokkan.')
    if name == 'shell.js':
        source = source.replace('Create brand-new cards for Dokkan Eclipse and Dokkan Sparking', 'Create brand-new cards for Offline Dokkan')
        source = source.replace('Save your unit for Dokkan Eclipse or Dokkan Sparking on the last step.', 'Finish your unit to add it to this game’s collection.')
        source = source.replace('on the last step, tap Import to Eclipse or Import to Sparking.', 'on the last step, tap Finish in Offline Dokkan.')
    if name == 'dbz-home.js':
        source = source.replace('Eclipse · Sparking', 'Offline Dokkan')
    if name == 'offline.js':
        marker = '  async function storageReady(force = false) {\n'
        if source.count(marker) != 1:
            raise ValueError('Shared storage admission changed; review native folder selection')
        source = source.replace(marker, marker + '    if (window.OfflineCreatorTools) {\n      if (!force) return true;\n      const result = await Native.call("storageAccess");\n      return result?.opened === true;\n    }\n')
    if name == 'sparking-content.js':
        # Both compatibility query aliases refer to the same selected master.
        # Do not relabel an Eclipse-backed template as Sparking after the
        # trusted loadTemplate hook has already pinned its actual provenance.
        source = source.replace('project.source.database="sparking";', 'project.source.database=window.OfflineCreatorHost.game();')
        source = source.replace('Sparking characters', 'Selected game characters').replace('cards from the actual Sparking game database.', 'cards from your selected game database.')
    if name == 'app.js':
        marker = 'if(document.readyState === "complete") boot();\nelse document.addEventListener("DOMContentLoaded", () => boot(), {once:true});'
        if source.count(marker) != 1:
            raise ValueError('Shared Creator boot guard changed; inspect before staging')
        source = source.replace(marker, '// Offline bootstrap starts boot() after all shared screen controllers register.')
    return source


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--original-client', action='store_true', help='Stage the actual original-game integration without the legacy authored gameplay harness')
    original_client = parser.parse_args().original_client
    source = (UI / 'index.html').read_text()
    scripts = re.findall(r'<script\b[^>]*\bsrc="([^"]+)"[^>]*></script>', source)
    styles = re.findall(r'<link\b[^>]*\bhref="([^"]+\.css)"[^>]*>', source)
    scripts = [path for path in scripts if not path.startswith('data/') and path not in EXCLUDED]
    reviewed = json.loads((HERE / 'reviewed-ui-files.json').read_text())
    if sorted(set(scripts + styles)) != reviewed:
        raise ValueError('Shared UI dependencies changed; review new or removed code for data-free packaging first')
    # This is an ignored, single generated staging directory, never a game-data
    # copy. Delete it before every staging run so removed snapshots cannot linger.
    if SITE.is_symlink():
        raise ValueError('Refusing a symlink staging directory')
    if SITE.exists():
        shutil.rmtree(SITE)
    SITE.mkdir()
    for name in scripts + styles:
        relative = Path(name)
        if relative.is_absolute() or '..' in relative.parts or (UI / relative).is_symlink():
            raise ValueError('Unsafe shared UI dependency')
        target = SITE / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        text = (UI / relative).read_text()
        target.write_text(strip_catalogs(name, text) if name.endswith('.js') else text)
    # Actual iPhone adapters/workers, not rewritten feature stubs. Never copy
    # build_ios's bundled private databases or its generated database snapshots.
    (SITE / 'web').mkdir()
    for name in IOS_ADAPTERS + ['argon2-worker.js', 'ios-ui.js', 'ios.css']:
        text = (ROOT / 'unit-creator/web/src' / name).read_text()
        if name == 'ios-sparking.js':
            start = text.index('  const LIB_SHA = ')
            end = text.index('  // ---------------------------------------------------------------- .sprk patches', start)
            text = text[:start] + '  // Native source capability owns format admission and keys.\n' + text[end:]
        if name == 'ios-io.js':
            marker = 'if (chosen) { await IOS.useDb(chosen.path, name, {}); database = true; }'
            if text.count(marker) != 1:
                raise ValueError('Archive source activation changed; review the selected-master boundary')
            text = text.replace(marker, 'if (chosen && !window.OfflineCreatorTools) { await IOS.useDb(chosen.path, name, {}); database = true; }')
            marker = '      let info, mode;\n      if (chosen) {'
            if text.count(marker) != 1:
                raise ValueError('APK source activation changed; review the selected-master boundary')
            text = text.replace(marker, '      if (window.OfflineCreatorTools) {\n        IOS.invalidateAssets();\n        return { kind: "apk", database: false, mode: "resources", apk, count: r.count, bytes: r.bytes, expanded: r.expanded, warnings: r.warnings, note: "Available resources imported. Return to Offline Dokkan before changing its selected game database." };\n      }\n' + marker)
        (SITE / 'web' / name).write_text(text)
    for resource in (UI / 'vendor').rglob('*'):
        if not resource.is_file() or resource.is_symlink():
            continue
        name = str(resource.relative_to(UI))
        if name in EXCLUDED:
            continue
        target = SITE / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(resource, target)
    (SITE / 'data').mkdir()
    for name in TOOL_METADATA | set(TOOL_REFERENCE_SCRIPTS):
        shutil.copy2(UI / 'data' / name, SITE / 'data' / name)
    # Only the original UI fonts and their existing provenance accompany CSS.
    for font in (UI / 'fonts').iterdir():
        if font.is_file() and not font.is_symlink() and font.suffix.lower() in {'.ttf', '.txt', '.md'}:
            (SITE / 'fonts').mkdir(exist_ok=True)
            shutil.copy2(font, SITE / 'fonts' / font.name)
    (SITE / 'licenses').mkdir(exist_ok=True)
    for name in ['Bangers-OFL.txt', 'RussoOne-OFL.txt', 'LICENSE', 'THIRD-PARTY-NOTICES.txt']:
        source_license = UI / 'licenses' / name
        if source_license.is_file():
            shutil.copy2(source_license, SITE / 'licenses' / name)
    lua_license = UI / 'vendor/luaparse/LICENSE'
    if lua_license.is_file():
        shutil.copy2(lua_license, SITE / 'vendor/luaparse/LICENSE')
    for name in ['host-adapter.js', 'ui-adapter.js', 'ios-tools-adapter.js', 'bootstrap.js', 'host.css']:
        shutil.copy2(HERE / name, SITE / name)
    shutil.copy2(UI / 'cpk-writer.js', SITE / 'cpk-writer.js')
    projector = ROOT / 'offline-dokkan/adapter/creator-project.js'
    shutil.copy2(projector, SITE / 'creator-project.js')
    # Trusted native JavaScriptCore uses this fixed authored materializer with
    # the same bundled core.js. It is not a WebView handler or a game engine.
    shutil.copy2(ROOT / 'offline-dokkan/original-client/master/runtime_forge.js', SITE / 'runtime-forge.js')
    tables = json.loads(subprocess.check_output(['node', '-e', 'process.stdout.write(JSON.stringify(require(process.argv[1]).supportedTables))', str(projector)], text=True))
    (SITE / 'projection-tables.json').write_text(json.dumps(tables, separators=(',', ':')) + '\n')
    (SITE / 'ui-scripts.json').write_text(json.dumps(scripts + ['cpk-writer.js', 'creator-project.js', 'ui-adapter.js'], separators=(',', ':')) + '\n')
    (SITE / 'ios-tools-scripts.json').write_text(json.dumps(['web/' + name for name in IOS_ADAPTERS] + ['data/' + name for name in TOOL_REFERENCE_SCRIPTS] + ['ios-tools-adapter.js'], separators=(',', ':')) + '\n')
    source = re.sub(r'<script\b[^>]*\bsrc="[^"]+"[^>]*></script>', '', source)
    source = re.sub(r'<meta http-equiv="Content-Security-Policy"[^>]*>', '<meta http-equiv="Content-Security-Policy" content="default-src \'self\'; script-src \'self\' \'wasm-unsafe-eval\'; worker-src \'self\' blob:; style-src \'self\'; img-src \'self\' data: blob:; media-src \'self\' data: blob:; font-src \'self\' data:; connect-src \'self\'; object-src \'none\'; base-uri \'none\'; form-action \'none\'; frame-src \'none\'">', source)
    source = source.replace('</head>', '<link rel="stylesheet" href="host.css"><script src="host-adapter.js"></script><script src="bootstrap.js" defer></script></head>')
    (SITE / 'index.html').write_text(source)
    # Old internal harness resources have no place in the original-game bundle.
    # Default keeps the existing isolated diagnostic host backward-compatible.
    if not original_client:
        (SITE / 'gameplay').mkdir()
        for name in ['coordinator-runtime.js', 'battle.js', 'session.js', 'battle-view.js', 'battle.css', 'source-roster.js', 'stage-plan.js']:
            source_gameplay = ROOT / 'offline-dokkan/gameplay' / name
            if not source_gameplay.is_file() or source_gameplay.is_symlink():
                raise ValueError('Missing reviewed authored gameplay resource: ' + name)
            shutil.copy2(source_gameplay, SITE / 'gameplay' / name)
    manifest = {str(path.relative_to(SITE)): hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted(SITE.rglob('*')) if path.is_file()}
    if any((path.startswith('data/') and path[5:] not in TOOL_METADATA | set(TOOL_REFERENCE_SCRIPTS)) or Path(path).suffix in {'.db', '.sqlite', '.apk', '.ipa'} for path in manifest):
        raise ValueError('Game data must never enter the Offline UI bundle')
    (SITE / 'ui-manifest.json').write_text(json.dumps({'format': 'offline-dokkan-creator-ui', 'version': 2, 'originalClient': original_client, 'authoredGameplayHarnessIncluded': not original_client, 'gameDatabasesIncluded': False, 'gameDataIncluded': True, 'referenceMetadataIncluded': sorted(TOOL_METADATA | set(TOOL_REFERENCE_SCRIPTS)), 'files': manifest}, sort_keys=True, indent=2) + '\n')
    print('Staged actual Creator screens:', len(scripts), 'shared scripts;', len(manifest), 'UI files; no game databases; explicit reference metadata only.')


if __name__ == '__main__':
    main()
