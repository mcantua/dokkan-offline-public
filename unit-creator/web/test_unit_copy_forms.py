"""One new linked-form copy/export/install/reimport batch; no native build."""
import json,pathlib,shutil,sqlite3,subprocess,tempfile,zipfile
from playwright.sync_api import sync_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='dokkan-forms-copy-') as directory:
 archive=pathlib.Path(directory)/'linked.zip';subprocess.run(['node',str(ROOT/'web/test_unit_copy_forms.cjs'),str(ROOT/'apk/assets/reference.db'),str(archive)],check=True)
 with zipfile.ZipFile(archive) as z: project=json.loads(z.read('forge-project.json'));sql=z.read(next(p for p in z.namelist() if p.endswith('.sql'))).decode()
 original=sqlite3.connect('file:'+str(ROOT/'apk/assets/reference.db')+'?mode=ro',uri=True);memory=sqlite3.connect(':memory:');original.backup(memory);original.close();memory.executescript(sql)
 members=[project,*project['formProjects']];assert all(memory.execute('SELECT id FROM cards WHERE id=?',(p['targetId'],)).fetchone() for p in members);memory.close();print('PASS actual linked-form SQL installs all private cards into real master',flush=True)
 with sync_playwright() as p:
  browser=p.chromium.launch(headless=True,executable_path=shutil.which('chromium'),args=['--no-sandbox']);page=browser.new_page()
  def route(r):
   name=r.request.url.split('/source/',1);r.fulfill(status=200,content_type='text/javascript' if len(name)==2 else 'text/html',body=(ROOT/name[1]).read_text() if len(name)==2 else '<script src="/source/v2/ui/core.js"></script><script src="/source/web/src/web-native.js"></script><script src="/source/web/src/ios-formats.js"></script>')
  page.route('**/*',route);page.goto('http://localhost:8767/forms-copy');page.evaluate("window.result=null;window.failure=null;void forgeNative.call('import').then(r=>result=r,e=>failure=e.message)");page.locator('dialog input[type=file]').set_input_files(str(archive));page.wait_for_function('result!==null||failure!==null');result=page.evaluate('({result,failure})');assert not result['failure'],result['failure']
  assert len(result['result']['project']['formProjects'])==2
  assert page.evaluate("async()=>{const p=result.project;const keys=[...new Set(p.formProjects.flatMap(f=>f.assets.map(a=>a.key)))];return !Forge.validate(p).errors.length&&(await forgeNative.call('assetStatus',{keys})).every(s=>s.available);}");print('PASS real browser ZIP reimport retains owned form graph and every attached media resource',flush=True);browser.close()
