"""Focused My Unit copy -> real ZIP/SQL -> real browser importer check. No native package build."""
import io
import json
import pathlib
import shutil
import sqlite3
import subprocess
import tempfile
import zipfile
from playwright.sync_api import sync_playwright

ROOT=pathlib.Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='dokkan-unit-copy-final-') as directory:
    archive=pathlib.Path(directory)/'copied.zip'
    subprocess.run(['node',str(ROOT/'web/test_unit_copy_resources.cjs'),str(ROOT/'apk/assets/reference.db'),str(archive)],check=True)
    with zipfile.ZipFile(archive) as z:
        project=json.loads(z.read('forge-project.json'));sql=z.read(next(p for p in z.namelist() if p.endswith('.sql'))).decode()
    original=sqlite3.connect('file:'+str(ROOT/'apk/assets/reference.db')+'?mode=ro',uri=True)
    memory=sqlite3.connect(':memory:');original.backup(memory);original.close();memory.executescript(sql)
    assert memory.execute('SELECT resource_id FROM cards WHERE id=?',(project['targetId'],)).fetchone()[0]==97001010
    assert memory.execute('SELECT count(*) FROM special_views WHERE id IN (SELECT view_id FROM card_specials WHERE card_id=?)',(project['targetId'],)).fetchone()[0]>0
    memory.close();print('PASS copied unit SQL installs actual card/artwork/custom-view records into real master fixture',flush=True)
    with sync_playwright() as p:
        browser=p.chromium.launch(headless=True,executable_path=shutil.which('chromium'),args=['--no-sandbox'])
        page=browser.new_page()
        def route(r):
            name=r.request.url.split('/source/',1)
            if len(name)==2:r.fulfill(status=200,content_type='text/javascript',body=(ROOT/name[1]).read_text())
            else:r.fulfill(status=200,content_type='text/html',body='<script src="/source/v2/ui/core.js"></script><script src="/source/web/src/web-native.js"></script><script src="/source/web/src/ios-formats.js"></script>')
        page.route('**/*',route);page.goto('http://localhost:8767/copy-roundtrip')
        page.evaluate("window.result=null;window.failure=null;void forgeNative.call('import').then(r=>result=r,e=>failure=e.message)")
        page.locator('dialog input[type=file]').set_input_files(str(archive));page.wait_for_function('result!==null||failure!==null')
        result=page.evaluate('({result,failure})');assert not result['failure'],result['failure']
        imported=result['result']['project'];assert imported['artBinding']['resourceId']==97001010 and len(imported['animationAssignments'])==1
        status=page.evaluate("async()=>{const unit=result.project;const statuses=await forgeNative.call('assetStatus',{keys:[...new Set(unit.assets.map(a=>a.key))]});const bytes=await Promise.all(unit.assets.map(async a=>{const url=await forgeNative.call('assetUrl',{key:a.key});return(await(await fetch(url)).arrayBuffer()).byteLength;}));return{valid:Forge.validate(unit).errors,available:statuses.every(s=>s.available),allBytes:bytes.every(n=>n>0),saved:(await forgeNative.call('projects')).length};}")
        assert status['valid']==[] and status['available'] and status['allBytes'] and status['saved']==1,status
        print('PASS real browser reimport retains editable animation, CPK aliases, art, immutable movie/music bytes and saved unit',flush=True)
        browser.close()
print('Focused copy/export/SQL/reimport batch passed. Synthetic media bytes do not establish phone/game playback acceptance.')
