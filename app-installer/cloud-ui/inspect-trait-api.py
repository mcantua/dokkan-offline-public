#!/usr/bin/env python3
"""Inspect installed public UIKit declarations and syntax-check one trait probe."""
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys

sys.dont_write_bytecode = True
REPO = 'mcantua/dokkan-offline-public'
BRANCH = 'chatgpt/app-installer-pairing-repair'
ROOT = Path(__file__).resolve().parents[2]
if (sys.platform != 'darwin' or os.environ.get('GITHUB_ACTIONS') != 'true'
        or os.environ.get('GITHUB_REPOSITORY') != REPO
        or os.environ.get('GITHUB_REF_NAME') != BRANCH
        or ROOT.name != 'dokkan-offline-public' or Path.cwd().resolve() != ROOT
        or ROOT != (Path(os.environ.get('GITHUB_WORKSPACE', '/nonexistent')) / 'AI-Workspace/dokkan-offline-public').resolve()):
    raise SystemExit('Requires the exact public repair branch in the hosted macOS checkout.')
if Path(subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip()).resolve() != ROOT:
    raise SystemExit('Unexpected Git root.')
OUT = ROOT / 'app-installer/cloud-ui/work/trait-api-inventory'
OUT.mkdir(parents=True, exist_ok=True)

def query(*args):
    return subprocess.check_output(args, cwd=ROOT, text=True, timeout=60).strip()

def sha(data): return hashlib.sha256(data).hexdigest()

os.environ['DEVELOPER_DIR'] = query(sys.executable, str(ROOT / 'app-installer/cloud-ui/select-xcode.py'))
sdk = Path(query('/usr/bin/xcrun', '--sdk', 'iphonesimulator', '--show-sdk-path'))
sdk_version = query('/usr/bin/xcrun', '--sdk', 'iphonesimulator', '--show-sdk-version')
if tuple(map(int, sdk_version.split('.'))) < (27, 1):
    raise SystemExit('Genuine installed SDK27.1+ required.')
headers = sdk / 'System/Library/Frameworks/UIKit.framework/Headers'
tokens = ('traitOverrides', 'containsTrait:', 'removeTrait:', 'UITraitPreferredContentSizeCategory',
          'preferredContentSizeCategory', 'preferredSymbolConfigurationForImage')
records = []
for header in sorted(headers.glob('*.h')):
    raw = header.read_bytes()
    if len(raw) > 4 * 1024 * 1024: continue
    lines = raw.decode('utf-8', errors='replace').splitlines()
    excerpts = []
    for number, line in enumerate(lines):
        found = [token for token in tokens if token in line]
        if found:
            excerpts.append({'line': number + 1, 'tokens': found,
                             'declaration': '\n'.join(lines[max(0, number-1):number+4])[:1800]})
    if excerpts:
        records.append({'header': str(header.relative_to(sdk)), 'sha256': sha(raw), 'excerpts': excerpts[:30]})
(OUT / 'declarations.json').write_text(json.dumps(records, indent=2) + '\n')
probe = r"""#import <UIKit/UIKit.h>
void AppInstallerTraitAPIProbe(UIWindow *window, UIButton *button) {
    if (@available(iOS 17.0, *)) {
        id<UITraitOverrides> overrides = window.traitOverrides;
        BOOL hadCategory = [overrides containsTrait:UITraitPreferredContentSizeCategory.class];
        UIContentSizeCategory savedCategory = overrides.preferredContentSizeCategory;
        overrides.preferredContentSizeCategory = UIContentSizeCategoryAccessibilityExtraExtraExtraLarge;
        if (hadCategory) overrides.preferredContentSizeCategory = savedCategory;
        else [overrides removeTrait:UITraitPreferredContentSizeCategory.class];
    }
    UIImageSymbolConfiguration *symbol = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightRegular];
    UIButtonConfiguration *configuration = [UIButtonConfiguration tintedButtonConfiguration];
    configuration.preferredSymbolConfigurationForImage = symbol;
    button.configuration = configuration;
}
"""
probe_path = OUT / 'trait-api-probe.m'
probe_path.write_text(probe)
cache = OUT / 'module-cache'
command = ['/usr/bin/xcrun', '--sdk', 'iphonesimulator', 'clang', '-target', 'arm64-apple-ios16.4-simulator',
           '-isysroot', str(sdk), '-fobjc-arc', '-fmodules', '-fmodules-cache-path=' + str(cache),
           '-Werror', '-fsyntax-only', '-x', 'objective-c', str(probe_path)]
receipt = {'schema_version': 1, 'repository': REPO, 'branch': BRANCH,
           'source_commit': query('git', 'rev-parse', 'HEAD'), 'run_id': os.environ.get('GITHUB_RUN_ID'),
           'xcode': query('/usr/bin/xcodebuild', '-version'), 'sdk_version': sdk_version,
           'sdk_path': str(sdk), 'clang': query('/usr/bin/xcrun', '--sdk', 'iphonesimulator', 'clang', '--version'),
           'architecture': platform.machine(), 'command': command, 'probe_sha256': sha(probe.encode()),
           'declarations_sha256': sha((OUT / 'declarations.json').read_bytes()),
           'scope': 'Installed public UIKit header snippets and one Objective-C syntax-only compiler invocation. '
                    'No link, application build/launch, tests, simulator startup, account or personal-resource use.'}
try:
    with (OUT / 'diagnostics.txt').open('wb') as diagnostics:
        result = subprocess.run(command, cwd=ROOT, stdout=diagnostics, stderr=subprocess.STDOUT, timeout=120)
    receipt['syntax_probe_exit_code'] = result.returncode
except subprocess.TimeoutExpired:
    receipt['syntax_probe_exit_code'] = 124
    receipt['syntax_probe_timed_out'] = True
finally:
    shutil.rmtree(cache, ignore_errors=True)
    diagnostics = OUT / 'diagnostics.txt'
    if diagnostics.is_file() and diagnostics.stat().st_size > 65536:
        diagnostics.write_bytes(diagnostics.read_bytes()[:65536])
        receipt['diagnostics_truncated'] = True
    receipt['diagnostics_sha256'] = sha(diagnostics.read_bytes()) if diagnostics.is_file() else None
    discovery = ROOT / 'app-installer/cloud-ui/work/evidence/toolchain-discovery.json'
    if discovery.is_file(): shutil.copy2(discovery, OUT / 'toolchain-discovery.json')
    (OUT / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps(receipt, indent=2))
raise SystemExit(receipt['syntax_probe_exit_code'])
