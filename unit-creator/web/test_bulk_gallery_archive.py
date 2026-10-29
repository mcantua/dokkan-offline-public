"""Focused bulk-gallery ZIP -> actual native files -> real IndexedDB restore cases."""
import ast,json,os,pathlib,shutil,subprocess,tempfile
from playwright.sync_api import sync_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1]
tree=ast.parse((ROOT/'web/test_animation_backup.py').read_text())
HTML=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='HTML' for t in n.targets))
with tempfile.TemporaryDirectory(prefix='dokkan-bulk-') as directory,sync_playwright() as p:
 tmp=pathlib.Path(directory);browser=p.chromium.launch(headless=True,executable_path=shutil.which('chromium'),args=['--no-sandbox']);context=browser.new_context()
 def route(r):
  path=r.request.url.split('/ui/',1)
  r.fulfill(status=200,content_type='text/javascript' if len(path)==2 else 'text/html',body=(ROOT/'v2/ui'/path[1]).read_text() if len(path)==2 else HTML)
 context.route('**/*',route);page=context.new_page();page.goto('http://localhost:8766/bulk-gallery')
 snapshot=page.evaluate("""async()=>{await ForgeAnimationGallery.create();const d=ForgeAnimationGallery.current();d.animationStudio.name='Unfinished creation';d.assets=[{key:'import-11111111-1111-4111-8111-111111111111/song.mp3',path:'bgm/mine.mp3'}];ForgeAnimationGallery.changed();await ForgeAnimationGallery.flush();return ForgeAnimationGallery.archiveSnapshot();}""")
 (tmp/'snapshot.json').write_text(json.dumps(snapshot));classes=tmp/'classes';classes.mkdir();cp=os.pathsep.join(str(ROOT/q) for q in ['dock/build/stubs','dock/app-v2.jar'])
 subprocess.run([str(ROOT/'tools/javac'),'--release','8','-cp',cp,'-d',str(classes),*map(str,(ROOT/'dock/src/com/personal/aihub').glob('*.java')),str(ROOT/'dock/test/com/personal/aihub/UserContentArchiveTest.java'),str(ROOT/'dock/test/com/personal/aihub/BulkGalleryArchiveTest.java')],check=True)
 subprocess.run(['java','-cp',str(classes)+os.pathsep+cp,'com.personal.aihub.BulkGalleryArchiveTest',str(tmp/'snapshot.json'),str(tmp/'verified.json')],check=True)
 verified=json.loads((tmp/'verified.json').read_text());page.evaluate('s=>window.verified=s',verified)
 result=page.evaluate('ForgeAnimationGallery.restoreArchiveSnapshot(verified)');assert result=={'restored':0,'unchanged':1,'conflicts':[]};print('PASS identical gallery restore is idempotent',flush=True)
 page.evaluate("async()=>{ForgeAnimationGallery.current().animationStudio.name='Keep my newer editing';ForgeAnimationGallery.changed();await ForgeAnimationGallery.flush();}")
 result=page.evaluate('ForgeAnimationGallery.restoreArchiveSnapshot(verified)');assert len(result['conflicts'])==1 and page.evaluate('ForgeAnimationGallery.current().animationStudio.name')=='Keep my newer editing';print('PASS differing existing gallery kept with explicit conflict',flush=True)
 result=page.evaluate("""async()=>{const s=structuredClone(verified);s.documents.push({...structuredClone(s.documents[0]),key:'fresh-a'},{...structuredClone(s.documents[0]),key:'fresh-b'});s.count=3;window.retry=s;const put=IDBObjectStore.prototype.put;let writes=0;IDBObjectStore.prototype.put=function(...args){if(this.name==='animations'&&++writes===2)throw new DOMException('Fixture quota','QuotaExceededError');return put.apply(this,args);};let rejected=false;try{await ForgeAnimationGallery.restoreArchiveSnapshot(s);}catch{rejected=true;}finally{IDBObjectStore.prototype.put=put;}return rejected&&!(await ForgeAnimationGallery.read('fresh-a'))&&!(await ForgeAnimationGallery.read('fresh-b'));}""");assert result;print('PASS quota abort rolls back every new gallery document, preserves existing edits',flush=True)
 result=page.evaluate('ForgeAnimationGallery.restoreArchiveSnapshot(retry)');assert result['restored']==2 and len(result['conflicts'])==1;assert page.evaluate('ForgeAnimationGallery.restoreArchiveSnapshot(retry)')['unchanged']==2;print('PASS same verified archive retries successfully without duplicating documents',flush=True)
 browser.close()
