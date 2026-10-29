"""One focused gallery -> ZIP -> actual Android importer -> gallery/iOS handler roundtrip.
Uses synthetic media bytes, real IndexedDB/ZIP/SHA and original models. No app package build.
"""
import base64
import copy
import io
import json
import os
import pathlib
import subprocess
import sys
import shutil
import tempfile
import zipfile
from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parents[1]
checks = 0
def ok(label, condition):
    global checks
    assert condition, label
    checks += 1
    print('PASS', label, flush=True)

HTML = '''<!doctype html><div id="save-state"></div><dialog id="dialog"><h2 id="dialog-title"></h2><div id="dialog-body"></div></dialog>
<script>window.$=s=>document.querySelector(s);window.esc=v=>String(v).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));window.messages=[];window.toast=(s)=>messages.push(s);
window.state={view:'home',info:{schema:{effect_packs:[]}},project:{key:'existing-unit',targetId:1800011111,name:'Keep my unit',tables:{effect_packs:[]},schema:{effect_packs:[]},assets:[],movieBindings:[],animationStudio:{clips:[],name:'Old unit animation'}}};
window.studioState={};window.savedUnits=[];window.flushSave=async()=>{if(state.project)savedUnits.push(structuredClone(state.project));};window.scheduleSave=()=>{};window.updateNav=()=>{};window.renderStudio=async()=>{};window.studioBusy=async(_t,f)=>f();window.studioOwner=()=>ForgeAnimationGallery.current()||state.project;window.studioProject=()=>studioOwner()?.animationStudio;window.studioAssignDialog=()=>{window.assignmentOpened=true;};window.ForgeGuide={targets:()=>[{key:'super:1'}]};window.ForgeSparkingContent={attachAnimation:async()=>{},checkEclipseAnimation:async()=>{}};window.ForgePreviewBindings={request:()=>({})};window.dialog=(title,body)=>{$('#dialog-title').textContent=title;$('#dialog-body').innerHTML=body;if(!$('#dialog').open)$('#dialog').showModal();};
window.resource=new Uint8Array([83,89,78,84,72,69,84,73,67]);window.resourceUrl=URL.createObjectURL(new Blob([resource]));window.Native={call:async(method,args={})=>{if(method==='animationImportLeases'){const leases=JSON.parse(localStorage.getItem('fixture-import-leases')||'[]');if(args.action==='pending')return leases;const log=JSON.parse(localStorage.getItem('fixture-import-log')||'[]');log.push({action:args.action,token:args.token});localStorage.setItem('fixture-import-log',JSON.stringify(log));localStorage.setItem('fixture-import-leases',JSON.stringify(leases.filter(l=>l.token!==args.token)));return{committed:args.action==='commit',discarded:args.action==='discard'};}if(method==='assetUrl')return resourceUrl;if(method==='export'){window.exported=args;const files={};for(const e of args.entries)files[e.path]=e.assetKey?resource:new TextEncoder().encode(e.text);window.archive=fflate.zipSync(files,{level:6});return{saved:true};}if(method==='importAnimationBackup'){const value=window.importResult;if(value?.importToken){const leases=JSON.parse(localStorage.getItem('fixture-import-leases')||'[]');leases.push({token:value.importToken,resources:Object.values(value.resources)});localStorage.setItem('fixture-import-leases',JSON.stringify(leases));}return value;}throw Error('Unexpected fixture native method '+method);}};
</script>
<script src="/ui/core.js"></script><script src="/ui/motion.js"></script><script src="/ui/movie-model.js"></script><script src="/ui/sequence-model.js"></script><script src="/ui/vendor/fflate.js"></script><script src="/ui/animation-gallery.js"></script>'''

def rewrite(data, change=None, extra=None, symlink=False):
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        files = {n:z.read(n) for n in z.namelist()}
    if change:
        record=json.loads(files['animation.json']);change(record);files['animation.json']=json.dumps(record).encode()
    if extra: files[extra]=b'forbidden'
    output=io.BytesIO()
    with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as z:
        for name,body in files.items():
            if symlink and name.startswith('resources/'):
                info=zipfile.ZipInfo(name);info.create_system=3;info.external_attr=(0o120777<<16);z.writestr(info,body)
            else:z.writestr(name,body)
    return output.getvalue()

with tempfile.TemporaryDirectory(prefix='dokkan-animation-roundtrip-') as directory, sync_playwright() as playwright:
    tmp=pathlib.Path(directory)
    browser=playwright.chromium.launch(headless=True,executable_path=shutil.which('chromium'),args=['--no-sandbox'])
    context=browser.new_context()
    def route(request):
        url=request.request.url
        if '/ui/' in url:
            path=ROOT/'v2/ui'/url.split('/ui/',1)[1]
            request.fulfill(status=200,content_type='text/javascript',body=path.read_text())
        else:request.fulfill(status=200,content_type='text/html',body=HTML)
    context.route('**/*',route)
    page=context.new_page();page.goto('http://localhost:8766/gallery-check')
    if '--ios-only' in sys.argv:
        payload=pathlib.Path(sys.argv[-1]).read_bytes();good=tmp/'animation.zip';good.write_bytes(payload)
        invalid=[]
        for label,data in [('hash',rewrite(payload,lambda d:d['resources'][0].update(sha256='0'*64))),('sql',rewrite(payload,extra='database.sql')),('symlink',rewrite(payload,symlink=True))]:
            path=tmp/(label+'.zip');path.write_bytes(data);invalid.append(path)
    else:
        page.evaluate('''async()=>{await ForgeAnimationGallery.create();const doc=ForgeAnimationGallery.current();doc.animationStudio.name='My independent animation';doc.animationStudio.clips=[ForgeMotion.createClip({path:'ab_script/attack_sp/sp0001.lua',text:'setMoveKey(0,0,0,0,0);endPhase(60);',label:'Synthetic move'})];doc.assets=[{key:'import-fixture/song.mp3',path:'bgm/forge_sequence_1800000000_song.mp3',owner:'forge-sequence-music'}];doc.animationStudio.music={kind:'file',path:doc.assets[0].path,title:'Synthetic song'};ForgeAnimationGallery.changed();await ForgeAnimationGallery.save();await ForgeAnimationGallery.exportBackup();}''')
        payload=bytes(page.evaluate('Array.from(archive)'));good=tmp/'animation.zip';good.write_bytes(payload)
        with zipfile.ZipFile(good) as z:
            manifest=json.loads(z.read('animation.json'))
            ok('independent ZIP includes editable document and actual attached resource',set(z.namelist())=={'animation.json','resources/1.mp3'} and z.read('resources/1.mp3')==b'SYNTHETIC' and manifest['document']['assets'][0]['key']=='resources/1.mp3')
        ok('animation backup does not export the previously open unit',page.evaluate(r"state.project.name==='Keep my unit' && !exported.entries.some(e=>/forge-project|database|\.sql$/.test(e.path))"))
        invalid=[]
        for label,data in [('hash',rewrite(payload,lambda d:d['resources'][0].update(sha256='0'*64))),('sql',rewrite(payload,extra='database.sql')),('symlink',rewrite(payload,symlink=True))]:
            p=tmp/(label+'.zip');p.write_bytes(data);invalid.append(p)
        classes=tmp/'classes';classes.mkdir();cp=os.pathsep.join(str(ROOT/p) for p in ['dock/build/stubs','dock/app-v2.jar'])
        subprocess.run([str(ROOT/'tools/javac'),'--release','8','-Xlint:-options','-cp',cp,'-d',str(classes),*map(str,(ROOT/'dock/src/com/personal/aihub').glob('*.java')),str(ROOT/'dock/test/com/personal/aihub/AnimationBackupImportTest.java')],check=True)
        native=tmp/'native.json';subprocess.run(['java','-cp',str(classes)+os.pathsep+cp,'com.personal.aihub.AnimationBackupImportTest',str(good),*map(str,invalid),str(native)],check=True)
        page.evaluate('r=>window.importResult=r',json.loads(native.read_text()))
        page.evaluate('ForgeAnimationGallery.importBackup()')
        rows=page.evaluate('ForgeAnimationGallery.list()');ok('native-imported document enters gallery under fresh identity',len(rows)==2 and len({d['key'] for d in rows})==2 and any(d['assets'][0]['key'].startswith('import-') for d in rows))
        page.evaluate('window.baselineImport=structuredClone(importResult)')
        rejected=page.evaluate('''async()=>{importResult=structuredClone(baselineImport);const old=importResult.importToken;importResult.importToken=crypto.randomUUID();for(const path of Object.keys(importResult.resources))importResult.resources[path]=importResult.resources[path].replace(old,importResult.importToken);importResult.document.animationStudio.name='';let failed=false;try{await ForgeAnimationGallery.importBackup();}catch{failed=true;}return failed&&JSON.parse(localStorage.getItem('fixture-import-leases')).length===0&&JSON.parse(localStorage.getItem('fixture-import-log')).at(-1).action==='discard';}''')
        ok('semantic validation failure discards only its returned fresh lease',rejected and len(page.evaluate('ForgeAnimationGallery.list()'))==2)
        rejected=page.evaluate('''async()=>{importResult=structuredClone(baselineImport);const old=importResult.importToken;importResult.importToken=crypto.randomUUID();for(const path of Object.keys(importResult.resources))importResult.resources[path]=importResult.resources[path].replace(old,importResult.importToken);const put=IDBObjectStore.prototype.put;IDBObjectStore.prototype.put=function(...args){if(this.name==='animations')throw new DOMException('Fixture quota','QuotaExceededError');return put.apply(this,args);};let failed=false;try{await ForgeAnimationGallery.importBackup();}catch{failed=true;}finally{IDBObjectStore.prototype.put=put;}return failed&&JSON.parse(localStorage.getItem('fixture-import-leases')).length===0&&JSON.parse(localStorage.getItem('fixture-import-log')).at(-1).action==='discard';}''')
        ok('real IndexedDB quota abort releases fresh resources and preserves gallery',rejected and len(page.evaluate('ForgeAnimationGallery.list()'))==2)
        page.evaluate('''()=>{window.referencedToken=baselineImport.importToken;window.unusedToken=crypto.randomUUID();localStorage.setItem('fixture-recovery-tokens',JSON.stringify([referencedToken,unusedToken]));localStorage.setItem('fixture-import-leases',JSON.stringify([{token:referencedToken,resources:Object.values(baselineImport.resources)},{token:unusedToken,resources:['import-'+unusedToken+'/1.mp3']}]));}''')
        page.reload();page.evaluate('ForgeAnimationGallery.show()');page.evaluate("state.view='animations';ForgeAnimationGallery.restore()")
        ok('restart reconciles actual saved gallery references before discarding unused import',page.evaluate("(()=>{const [used,unused]=JSON.parse(localStorage.getItem('fixture-recovery-tokens')),log=JSON.parse(localStorage.getItem('fixture-import-log'));return log.some(x=>x.token===used&&x.action==='commit')&&log.some(x=>x.token===unused&&x.action==='discard')&&JSON.parse(localStorage.getItem('fixture-import-leases')).length===0;})()"))
        original=page.evaluate('ForgeAnimationGallery.current().key');page.evaluate('''async()=>{const d=ForgeAnimationGallery.current();d.animationStudio.name='Changed title';ForgeAnimationGallery.changed();await ForgeAnimationGallery.undo();await ForgeAnimationGallery.flush();}''')
        ok('independent undo preserves unit draft and restores animation edit',page.evaluate("ForgeAnimationGallery.current().animationStudio.name==='My independent animation' && state.project.name==='Keep my unit'"))
        page.evaluate('''async()=>{await ForgeAnimationGallery.copyToUnit(ForgeAnimationGallery.current(),state.project,'super:1');}''')
        ok('assigning independent animation persists unit and keeps gallery entry',page.evaluate("!ForgeAnimationGallery.current() && savedUnits.at(-1).animationStudio.name==='My independent animation' && savedUnits.at(-1).animationStudio.target==='super:1'") and len(page.evaluate('ForgeAnimationGallery.list()'))==2)
        page.evaluate('(key)=>ForgeAnimationGallery.remove(key)',original);page.reload();page.evaluate('ForgeAnimationGallery.show()')
        ok('removed gallery item can be recovered after restart',page.locator('#gallery-undo').count()==1)
        page.locator('#gallery-undo').click();page.wait_for_function("document.querySelectorAll('[data-gallery-action=edit]').length===2")
    # Load the actual iPhone JS adapter with a file-storage fixture, then use its real picker/parser.
    page.evaluate(r'''()=>{window.iosFiles=new Map();window.iosDirs=new Set();window.__forgeIOS={H:{},formats:{},safePath:Forge.safePath,uuid4:()=>crypto.randomUUID(),progress:()=>{},invalidateAssets:()=>{},sha256Hex:async b=>Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',b)),n=>n.toString(16).padStart(2,'0')).join(''),host:{stat:async p=>iosDirs.has(p)?{name:p.split('/').at(-1),dir:true,size:0}:iosFiles.has(p)?{name:p.split('/').at(-1),dir:false,size:iosFiles.get(p).length}:null,list:async(p,deep=false)=>[...iosFiles].filter(([k])=>k.startsWith(p.replace(/\/$/,'')+'/')&&(deep||!k.slice(p.replace(/\/$/,'').length+1).includes('/'))).map(([k,b])=>({name:k.slice(p.replace(/\/$/,'').length+1),dir:false,size:b.length})),readBytes:async p=>iosFiles.get(p)||null,readJson:async p=>JSON.parse(new TextDecoder().decode(iosFiles.get(p))),writeJson:async(p,v)=>iosFiles.set(p,new TextEncoder().encode(JSON.stringify(v))),mkdir:async p=>{iosDirs.add(p);},exists:async p=>iosDirs.has(p)||iosFiles.has(p),writeBytes:async(p,b)=>iosFiles.set(p,new Uint8Array(b)),remove:async p=>{for(const k of [...iosFiles.keys()])if(k===p||k.startsWith(p+'/'))iosFiles.delete(k);iosDirs.delete(p);},move:async(p,to)=>{for(const [k,v]of [...iosFiles])if(k.startsWith(p+'/')){iosFiles.set(to+k.slice(p.length),v);iosFiles.delete(k);}iosDirs.delete(p);iosDirs.add(to);}}};}''')
    page.add_script_tag(content=(ROOT/'web/src/ios-io.js').read_text())
    def ios_import(path):
        page.evaluate("window.iosResult=null;window.iosError=null;void __forgeIOS.H.importAnimationBackup().then(r=>iosResult=r,e=>iosError=e.message)")
        page.locator('dialog.web-file-dialog input[type=file]').set_input_files(str(path))
        page.wait_for_function('iosResult!==null||iosError!==null')
    ios_import(good)
    ok('iPhone handler imports same resource ZIP and commits one fresh collection',page.evaluate("iosError===null && iosResult.document.animationStudio.name==='My independent animation' && [...iosFiles.keys()].filter(k=>k.startsWith('assets/')).length===1 && [...iosFiles.keys()].some(k=>k.startsWith('assets/import-'))"))
    ok('iPhone leaves a durable pending import until gallery commit',page.evaluate("(async()=>{const rows=await __forgeIOS.H.animationImportLeases({action:'pending'});return rows.length===1&&rows[0].token===iosResult.importToken;})()"))
    page.evaluate("__forgeIOS.H.animationImportLeases({action:'commit',token:iosResult.importToken})")
    ok('iPhone commit preserves files and clears pending journal',page.evaluate("(async()=>!(await __forgeIOS.H.animationImportLeases({action:'pending'})).length&&[...iosFiles.keys()].filter(k=>k.startsWith('assets/')).length===1)()"))
    ios_import(invalid[0]);ok('iPhone bad checksum rolls back only its staging files',page.evaluate("!!iosError && [...iosFiles.keys()].filter(k=>k.startsWith('assets/')).length===1 && ![...iosDirs].some(p=>p.startsWith('cache/animation-import-'))"))
    ios_import(invalid[1]);ok('iPhone rejects unexpected SQL without changing stored files',page.evaluate("!!iosError && [...iosFiles.keys()].filter(k=>k.startsWith('assets/')).length===1"))
    ios_import(invalid[2]);ok('iPhone rejects symlink entries without changing stored files',page.evaluate("!!iosError && [...iosFiles.keys()].filter(k=>k.startsWith('assets/')).length===1"))
    browser.close()
    print(f'{checks} gallery/iPhone assertions plus Android importer assertions passed; physical Android/iPhone picker and media decoding remain device checks.')
