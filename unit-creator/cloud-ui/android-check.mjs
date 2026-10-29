// Actual Android WebView CDP, reached only through adb forwarding to our owned emulator app.
// No desktop browser, bridge replacement or native-response fixture.
import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';

const evidence = process.env.UC_ANDROID_EVIDENCE;
const adb = process.env.UC_ADB;
const phase = process.argv[2];
const reportPath = path.join(evidence, 'android-native-result.json');
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
function requireValue(value, label) { if (!value) throw new Error(label); return value; }
let endpoint;
for (let i=0;i<120;i++) {
  try {
    const pages = await (await fetch('http://127.0.0.1:9222/json/list')).json();
    endpoint = pages.find(p => p.type === 'page' && /index\.html/.test(p.url))?.webSocketDebuggerUrl;
    if (endpoint) break;
  } catch {}
  await pause(500);
}
requireValue(endpoint, 'Actual Android app WebView debugger page unavailable');
const socket = new WebSocket(endpoint);
await new Promise((resolve,reject) => { socket.addEventListener('open',resolve,{once:true});socket.addEventListener('error',()=>reject(new Error('Actual Android CDP connection failed')),{once:true}); });
let sequence = 0;
const pending = new Map(), exceptions = [];
socket.addEventListener('message', ({data}) => {
  const message = JSON.parse(data);
  if (message.id) {
    const item = pending.get(message.id); if (!item) return; pending.delete(message.id);clearTimeout(item.timer);
    if (message.error) item.reject(new Error(message.error.message)); else item.resolve(message.result);
  } else if (message.method === 'Runtime.exceptionThrown') {
    const detail = message.params.exceptionDetails;
    exceptions.push(String(detail.exception?.description || detail.text).slice(0,1000));
  }
});
function command(method, params = {}) {
  return new Promise((resolve,reject) => {
    const id = ++sequence, timer = setTimeout(()=>{pending.delete(id);reject(new Error(method+' timed out'));},90000);
    pending.set(id,{resolve,reject,timer});socket.send(JSON.stringify({id,method,params}));
  });
}
async function js(expression) {
  const result = await command('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true,userGesture:true});
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.exception?.description || result.exceptionDetails.text);
  return result.result.value;
}
async function until(expression, label, count=150) {
  for(let i=0;i<count;i++){const value=await js(expression);if(value)return value;await pause(200);}
  throw new Error(label+' did not become ready');
}
async function paint() { await js('(async()=>{await document.fonts.ready;await new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)));return true})()'); }
function screenshot(name) { fs.writeFileSync(path.join(evidence,name),execFileSync(adb,['-s','emulator-5554','exec-out','screencap','-p'],{maxBuffer:32*1024*1024})); }
await command('Runtime.enable');
try {
  await until(`window.__forgeWorkspaceStartup==='ready'&&document.getElementById('db-quick')&&!document.querySelector('#main .initial-loading')`,'Native Home');
  const geometry=await js(`(()=>{const r=document.getElementById('db-quick').getBoundingClientRect();return {startup:window.__forgeWorkspaceStartup,createVisible:r.width>0&&r.height>0&&r.right>0&&r.left<innerWidth&&r.bottom>0&&r.top<innerHeight,innerWidth,innerHeight,pageWidth:document.documentElement.scrollWidth,androidBridge:!!window.ForgeAndroid};})()`);
  requireValue(geometry.createVisible&&geometry.androidBridge&&geometry.pageWidth<=geometry.innerWidth+1,'Actual native Home must fit, show Create and expose the real Java bridge');
  if(phase==='create') {
    await paint(); screenshot('android-home.png');
    await js(`document.getElementById('db-quick').click();true`);
    await until(`!!document.getElementById('cc-template')`,'Create choice');
    await js(`document.getElementById('cc-template').click();true`);
    await until(`!!document.querySelector('#qc-finder [data-fd-pick]')`,'Actual native SQLite character finder',450);
    await js(`document.querySelector('#qc-finder [data-fd-pick]').click();true`);
    await until(`!!document.querySelector('[data-qc-style]')`,'Fighting style');
    await js(`document.querySelector('[data-qc-style]').click();true`);
    await until(`!!document.getElementById('qc-name')`,'Final touches');
    await js(`(()=>{const n=document.getElementById('qc-name');n.value='Cloud Native Check';n.dispatchEvent(new Event('input',{bubbles:true}));document.getElementById('qc-create').click();return true})()`);
    const saved=await until(`(async()=>{if(typeof state==='undefined'||!state.project||state.project.name!=='Cloud Native Check'||state.view!=='editor')return false;const p=await Native.call('loadProject',{key:state.project.key});return p&&p.name==='Cloud Native Check'?{key:p.key,name:p.name}:false})()`,'Actual native project save',450);
    const counts=await js(`(async()=>({eclipse:(await Native.call('info')).count,sparking:(await Native.call('sparkingInfo')).count}))()`);
    requireValue(counts.eclipse>1000&&counts.sparking>1000,'Both actual native SQL card catalogs must load');
    await paint();screenshot('android-created.png');
    requireValue(exceptions.length===0,'Unhandled native WebView JavaScript exception');
    fs.writeFileSync(reportPath,JSON.stringify({scope:'Actual retained Android app installed on owned hosted API35 emulator, actual native WebView/SQL/file bridge; browser snapshot data reconstructed for CI',package:'com.dokkanunitcreator.development',version:'2.36.3',code:128,geometry,counts,saved,unhandled_js_exceptions:exceptions,save_reopened:false,not_verified:['Physical device/touch','Other Android API versions','Original database byte fidelity','Game installation/encryption/full feature parity']},null,2)+'\n');
  } else if(phase==='reopen') {
    const report=JSON.parse(fs.readFileSync(reportPath));
    const loaded=await js(`Native.call('loadProject',{key:${JSON.stringify(report.saved.key)}})`);
    requireValue(loaded?.name===report.saved.name,'Project did not survive force-stop/relaunch');
    requireValue(await js(`(async()=>{const list=await Native.call('projects');return list.some(p=>p.key===${JSON.stringify(report.saved.key)}&&p.name==='Cloud Native Check')})()`),'Native saved collection lost project');
    await paint();screenshot('android-reopened.png');requireValue(exceptions.length===0,'Unhandled WebView error after relaunch');
    report.save_reopened=true;report.unhandled_js_exceptions.push(...exceptions);fs.writeFileSync(reportPath,JSON.stringify(report,null,2)+'\n');
  } else throw new Error('Unknown native check phase');
  console.log('Actual Android native '+phase+' flow passed.');
} finally { socket.close(); }
