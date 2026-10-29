/* Animations: join parts of moves. Each part is chosen by playing the move and tapping
   "Start here" and "End here" — no timeline, no dragging. */
(function(){
 'use strict';
 const old={render:renderStudio,timeline:renderStudioTimeline,results:loadStudioResults,assign:studioAssignDialog,action:studioAction,context:studioContext,checks:showStudioChecks};
 const h=esc,S=ForgeSequence;
 let advanced=false,picker=null,pickFor=null;
 try{advanced=localStorage.getItem('forge-animation-editor-v2')==='advanced';}catch{}
 const button=(label,action,kind='ghost')=>'<button type="button" class="button '+kind+'" data-studio="'+h(action)+'">'+h(label)+'</button>';
 const details=(title,content)=>'<details class="beginner-details"><summary>'+h(title)+'</summary>'+content+'</details>';
 // The old (advanced) animation editor is offered only with Settings → Help level → Advanced (or to get back out of it).
 const modeButton=()=>advanced||document.documentElement.dataset.experience==='advanced'?button(advanced?'Use simple editor':'Advanced editor','simple-toggle','ghost small'):'';
 function closePicker(){if(picker){picker.close();picker.remove();picker=null;}++studioState.loading;}
 // After an animation is put on a move from the picker, go straight back to that unit's animations.
 window.forgeAfterAnimationUse=()=>{if(!pickFor)return;pickFor=null;closePicker();navigate('editor').catch(()=>{});};
 function modal(title,body){
  clearTimeout(studioState.timer);++studioState.loading;
  if(!picker?.open){closePicker();picker=document.createElement('dialog');picker.className='sequence-picker';picker.setAttribute('aria-labelledby','sequence-picker-title');document.body.append(picker);picker.addEventListener('cancel',e=>{e.preventDefault();pickFor=null;closePicker();});}
  picker.innerHTML='<div class="section-heading"><h2 id="sequence-picker-title">'+h(title)+'</h2><button type="button" class="icon-button" aria-label="Close picker">×</button></div>'+body;
  picker.querySelector('[aria-label="Close picker"]').onclick=()=>{pickFor=null;closePicker();};
  if(!picker.open)picker.showModal();return picker;
 }

 // ======== Slider editor ========
 // The preview sits in a small window at the top. Below it:
 //  • one slider for the whole animation: drag it to watch any moment, ▶ plays from there;
 //  • one card per move with a two-handle slider over the whole move: drag the green handle to
 //    where the move should start and the orange handle to where it should end. While you drag,
 //    the preview shows that move at exactly the frame under your handle. ▶ on a card plays the
 //    part you kept. Nothing else to learn.
 const ed={playhead:0,sig:'',timer:0,monitor:'closed',status:'s',own:false,opening:false,pending:null,
  mode:'all',moveKey:'',scrub:false,stopAt:null,report:null,rate:1,followRaf:0,followLast:0,seekBusy:false,seekNext:null,dragging:false,moveAt:0};
 const totalOf=p=>{const t=S.timeline(p?.clips||[]);return t.length?t[t.length-1].end:0;};
 const sigOf=p=>JSON.stringify([p.clips.map(c=>[c.key,c.from,c.to,c.source?.path||'',(c.source?.text||'').length]),p.music||null]);
 const clock=sec=>S.clock(Math.max(0,sec));
 const findClip=key=>(studioProject()?.clips||[]).find(c=>c.key===key);
 const moveSig=c=>'move|'+c.key+'|'+(c.source?.path||'')+'|'+(c.source?.text||'').length;
 // What the preview window should be showing right now: the whole animation, or one whole move.
 const wantSig=()=>{const p=studioProject();if(!p)return '';if(ed.mode==='move'){const c=findClip(ed.moveKey);if(c)return moveSig(c);}return sigOf(p);};
 // Every preview started from the Animations screen opens in the small window (the editor's monitor).
 const baseCall=Native.call;
 Native.call=function(method,args){
  if(method==='previewAnimation'){
   // Any other preview (▶ Watch in the picker, Save video…) takes over the window: the editor stops following it.
   if(!ed.opening){ed.own=false;ed.sig='';ed.pending=null;ed.monitor='closed';ed.status='s';}
   if(state.view==='animations'&&args&&typeof args==='object'&&!args.dockSize)args={...args,dockSize:'small'};
  }
  return baseCall.call(this,method,args);};
 function openMonitor(play=false,at=null){
  const p=studioProject();if(!p?.clips.length)return;
  let text,start;
  if(ed.mode==='move'&&!findClip(ed.moveKey))ed.mode='all';
  if(ed.mode==='move'){
   // the whole move, untrimmed, so any frame you might want to keep can be shown
   const c=findClip(ed.moveKey),whole={...c,from:0,to:sourceLength(c)};
   try{text=ForgeMotion.compile([whole],{damage:false,music:null});}catch(e){toast(e.message,true);return;}
   start=Math.max(0,at??c.from);
  }else{
   const errors=ForgeMotion.validate(p.clips);if(errors.length){showStudioChecks();return;}
   try{text=ForgeMotion.compile(p.clips,{damage:false,music:p.music});}catch(e){toast(e.message,true);return;}
   if(at!=null)ed.playhead=at;
   const len=totalOf(p);if(ed.playhead>=len-0.05)ed.playhead=play?0:Math.max(0,len-0.05);
   start=ed.playhead;
  }
  ed.sig=wantSig();ed.monitor='loading';ed.own=true;ed.pending=null;ed.status=play?'p':'s';paint();
  let call;ed.opening=true;try{call=Native.call('previewAnimation',{name:p.name,text,...studioPreviewRequest(),dockSize:'small',startAt:Math.round(start*60),startPaused:!play});}finally{ed.opening=false;}
  call.catch(e=>{ed.monitor='closed';ed.own=false;ed.sig='';paint();toast(e.message,true);});
 }
 function closeMonitor(){clearTimeout(ed.timer);if(ed.own&&window.ForgeDock&&ForgeDock.state()!=='closed')ForgeDock.close().catch(()=>{});ed.own=false;ed.monitor='closed';ed.sig='';ed.pending=null;}
 // After an edit the whole-animation preview is rebuilt (paused) once you stop changing things.
 // While you are choosing a part of one move, that move stays in the window instead.
 function scheduleRefresh(fromEdit){clearTimeout(ed.timer);ed.timer=setTimeout(async()=>{const p=studioProject();if(state.view!=='animations'||!p||!document.getElementById('tl'))return;if(!p.clips.length){closeMonitor();return;}
  if(ed.mode!=='all')return;
  if(fromEdit&&!(ed.own&&window.ForgeDock&&ForgeDock.state()!=='closed'))return;
  if(window.ForgeDock&&ForgeDock.dockable&&!(await ForgeDock.dockable()))return;
  if(picker?.open||ed.dragging){scheduleRefresh(fromEdit);return;}if(state.view==='animations'&&wantSig()!==ed.sig)openMonitor(false);},1200);}
 const monitorLive=()=>window.ForgeDock&&ForgeDock.state()!=='closed'&&ed.own&&ed.monitor==='ready'&&ed.sig===wantSig();
 // The window is still opening exactly this: remember the command and send it once it reports in.
 const monitorLoading=()=>window.ForgeDock&&ForgeDock.state()!=='closed'&&ed.own&&ed.monitor==='loading'&&ed.sig===wantSig();
 // Show `sec` in the window (of the whole animation or of the move being trimmed). Seeks are sent one
 // at a time; while one is on its way only the newest position is kept, so dragging never piles up.
 function seekTo(sec,play=false){
  if(monitorLive()){
   ed.status=play?'p':'s';
   if(ed.seekBusy){ed.seekNext={sec,play};return;}
   ed.seekBusy=true;
   ForgeDock.seek(Math.round(sec*60),play).catch(()=>{}).finally(()=>{ed.seekBusy=false;const n=ed.seekNext;ed.seekNext=null;if(n)seekTo(n.sec,n.play);});
   return;
  }
  if(monitorLoading()){ed.pending={frame:Math.round(sec*60),play};ed.status=play?'p':'s';paint();return;}
  openMonitor(play,sec);
 }
 window.addEventListener('forge-dock-failed',()=>{ed.monitor='closed';ed.sig='';ed.own=false;ed.pending=null;ed.status='s';paint();});
 window.addEventListener('forge-dock-state',e=>{if(e.detail.state==='closed'){ed.monitor='closed';ed.sig='';ed.own=false;ed.status='s';}else if(ed.monitor==='closed'&&ed.own)ed.monitor='loading';paint();});
 window.addEventListener('forge-dock-position',e=>{
  if(!document.getElementById('tl')||!ed.own)return;const {frame,status}=e.detail;ed.monitor='ready';
  if(ed.pending){const q=ed.pending;ed.pending=null;ed.status=q.play?'p':'s';ForgeDock.seek(q.frame,q.play).catch(()=>{});paint();return;}
  const now=performance.now(),sec=frame/60,last=ed.report;
  if(last&&status==='p'&&last.status==='p'&&now-last.at>150&&now-last.at<700&&sec>last.sec){const r=(sec-last.sec)/((now-last.at)/1000);if(r>1.6&&r<2.4)ed.rate=2;else if(r>0.6&&r<1.4)ed.rate=1;}
  ed.report={sec,at:now,status};ed.status=status;
  // ▶ on a move plays only the part you kept, then stops
  if(ed.stopAt!=null&&status==='p'&&sec>=ed.stopAt-0.04){ForgeDock.pause().catch(()=>{});ed.stopAt=null;ed.status='s';}
  if(status!=='p')ed.stopAt=null;
  if(ed.mode==='all'){
   if(!ed.scrub){const target=Math.min(totalOf(studioProject()),sec);if(!(status==='p'&&target<ed.playhead&&ed.playhead-target<0.35))ed.playhead=target;placeHead();}
  }else if(!ed.dragging){ed.moveAt=sec;placeMoveMark();}
  paint();follow();
 });
 // The position glides with the picture between the player's reports (about 4 a second), never
 // more than 0.3 s ahead of the last report.
 function follow(){
  if(ed.followRaf)return;
  const step=t=>{ed.followRaf=0;
   if(ed.status!=='p'||!ed.report||ed.report.status!=='p'||!monitorLive()||ed.scrub||ed.dragging||!document.getElementById('tl'))return;
   if(t-(ed.followLast||0)>=50){ed.followLast=t;const x=ed.report.sec+Math.min(0.3,(performance.now()-ed.report.at)/1000)*(ed.rate||1);
    if(ed.mode==='all'){const y=Math.min(totalOf(studioProject()),x);if(y>ed.playhead){ed.playhead=y;placeHead();}}else if(x>ed.moveAt){ed.moveAt=x;placeMoveMark();}}
   ed.followRaf=requestAnimationFrame(step);};
  ed.followRaf=requestAnimationFrame(step);
 }
 // While the "Choose the part" window is open, it follows the move as it plays.
 function placeMoveMark(){paintPicker();}
 function updateClock(){const p=studioProject(),node=$('#tl-clock');if(node&&p)node.textContent=clock(ed.playhead)+' / '+clock(totalOf(p));const bar=$('#pt-progress');if(bar&&p)bar.style.width=(Math.min(1,ed.playhead/Math.max(0.1,totalOf(p)))*100).toFixed(2)+'%';}
 function paint(){
  const b=$('#tl-play');if(b){const loading=ed.mode==='all'&&ed.monitor==='loading'&&window.ForgeDock&&ForgeDock.state()!=='closed',playing=ed.mode==='all'&&ed.status==='p'&&monitorLive();b.innerHTML=playing?'❚❚ <span>Pause</span>':'▶ <span>Play my animation</span>';b.setAttribute('aria-label',playing?'Pause':'Play my animation');b.classList.toggle('tl-loading',loading);}
  const p=studioProject();
  document.querySelectorAll('[data-pt-watch]').forEach(btn=>{const c=p?.clips[Number(btn.dataset.ptWatch)],on=!!c&&ed.mode==='move'&&ed.moveKey===c.key&&ed.status==='p'&&ed.stopAt!=null&&!pp;btn.textContent=on?'❚❚ Pause':'▶ Watch';});
  paintPicker();
 }
 async function playPause(){
  const p=studioProject();if(!p?.clips.length)return;
  if(ed.mode!=='all'){ed.mode='all';ed.stopAt=null;}
  if(monitorLive()){
   if(ed.status==='p'){await ForgeDock.pause();ed.status='s';}
   else{if(ed.playhead>=totalOf(p)-0.05||ed.status==='d'){ed.playhead=0;placeHead();}seekTo(ed.playhead,true);}
   paint();return;}
  if(monitorLoading()){if(ed.pending&&ed.pending.play){ed.pending={frame:ed.playhead*60,play:false};ed.status='s';}else{if(ed.playhead>=totalOf(p)-0.05){ed.playhead=0;placeHead();}ed.pending={frame:ed.playhead*60,play:true};ed.status='p';}paint();return;}
  openMonitor(true);
 }
 function placeHead(){updateClock();}
 // ▶ Watch on a part: play just that part (from its start to its end) in the preview.
 function playPart(i){
  const c=studioProject()?.clips[i];if(!c)return;
  if(ed.mode==='move'&&ed.moveKey===c.key&&ed.status==='p'&&monitorLive()){ForgeDock.pause().catch(()=>{});ed.status='s';ed.stopAt=null;paint();return;}
  ed.mode='move';ed.moveKey=c.key;ed.stopAt=c.to;ed.moveAt=c.from;seekTo(c.from,true);paint();
 }

 // ======== Choose the part: play the move, tap "Start here" and "End here" ========
 let pp=null; // {i, key, from, to, len}
 // (inline style attributes are blocked by the page's security policy, so positions are set in code)
 function pickerBar(box,from,to,at,len){
  if(!box.firstChild)box.innerHTML='<div class="pt-bar" aria-hidden="true"><div class="pt-keep"></div><div class="pt-at"></div></div>';
  const keep=box.querySelector('.pt-keep'),mark=box.querySelector('.pt-at');
  keep.style.left=(from/len*100).toFixed(2)+'%';keep.style.width=(Math.max(0,to-from)/len*100).toFixed(2)+'%';mark.style.left=(Math.min(1,at/len)*100).toFixed(2)+'%';
 }
 function choosePart(i){
  const p=studioProject(),c=p?.clips[i];if(!c)return;
  const len=sourceLength(c);
  pp={i,key:c.key,from:c.from,to:c.to,len};
  const panel=modal('Choose the part to keep','<div class="pt" id="pt">'+
   '<p class="pt-name">'+(i+1)+'. '+h(c.label)+'</p>'+
   '<div class="pt-play-row"><button type="button" class="button pt-play" id="pt-play">▶ Play</button><span class="pt-clock" id="pt-clock">0:00.0 / '+clock(len)+'</span></div>'+
   '<div id="pt-bar"></div>'+
   '<div class="pt-step"><button type="button" class="button ghost small" id="pt-back">⏮ From the start</button><button type="button" class="button ghost small" id="pt-prev" aria-label="Back a little">◀ 0.1 s</button><button type="button" class="button ghost small" id="pt-next" aria-label="Forward a little">0.1 s ▶</button></div>'+
   '<div class="pt-marks"><button type="button" class="button pt-mark pt-mark-start" id="pt-start"><span>Start here</span><small id="pt-start-v"></small></button><button type="button" class="button pt-mark pt-mark-end" id="pt-end"><span>End here</span><small id="pt-end-v"></small></button></div>'+
   '<p class="pt-keeps" id="pt-keeps" role="status"></p>'+
   '<div class="pt-done-row"><button type="button" class="button ghost" id="pt-watch">▶ Watch my part</button><button type="button" class="button" id="pt-done">✓ Done</button></div>'+
   '<button type="button" class="text-button pt-whole" id="pt-whole">Keep the whole move</button></div>');
  const q=s=>panel.querySelector(s);
  // closing the window (×, back) without Done keeps the part as it was and goes back to the whole animation
  panel.addEventListener('close',()=>{if(pp&&pp.key===c.key){pp=null;ed.mode='all';ed.stopAt=null;if(ed.status==='p'&&monitorLive())ForgeDock.pause().catch(()=>{});scheduleRefresh(false);}},{once:true});
  q('#pt-play').onclick=()=>pickerPlay();
  q('#pt-back').onclick=()=>{ed.stopAt=null;ed.moveAt=0;seekTo(0,false);paintPicker();};
  q('#pt-prev').onclick=()=>step(-0.1);q('#pt-next').onclick=()=>step(0.1);
  q('#pt-start').onclick=()=>mark('start').catch(e=>toast(e.message,true));
  q('#pt-end').onclick=()=>mark('end').catch(e=>toast(e.message,true));
  q('#pt-watch').onclick=()=>{if(!pp)return;ed.stopAt=pp.to;ed.moveAt=pp.from;seekTo(pp.from,true);paintPicker();};
  q('#pt-whole').onclick=()=>{if(!pp)return;pp.from=0;pp.to=pp.len;paintPicker();toast('The whole move is kept.');};
  q('#pt-done').onclick=()=>finishPart().catch(e=>toast(e.message,true));
  // the move appears in the preview, paused at its current start
  ed.mode='move';ed.moveKey=c.key;ed.stopAt=null;ed.moveAt=c.from;seekTo(c.from,false);
  paintPicker();
 }
 function pickerPlay(){
  if(!pp)return;
  if(ed.status==='p'&&monitorLive()){ForgeDock.pause().catch(()=>{});ed.status='s';ed.stopAt=null;paintPicker();return;}
  ed.stopAt=null;const at=ed.moveAt>=pp.len-0.05?0:ed.moveAt;seekTo(at,true);paintPicker();
 }
 function step(delta){
  if(!pp)return;
  if(ed.status==='p'&&monitorLive()){ForgeDock.pause().catch(()=>{});ed.status='s';}
  ed.stopAt=null;ed.moveAt=Math.max(0,Math.min(pp.len,Math.round((ed.moveAt+delta)*10)/10));seekTo(ed.moveAt,false);paintPicker();
 }
 // The exact moment on screen: when playing, pause and take the frame the player reports.
 async function momentNow(){
  if(ed.status!=='p'||!monitorLive())return ed.moveAt;
  const reported=new Promise(res=>{const on=e=>{if(e.detail.status!=='p'){removeEventListener('forge-dock-position',on);res(e.detail.frame/60);}};addEventListener('forge-dock-position',on);setTimeout(()=>{removeEventListener('forge-dock-position',on);res(null);},900);});
  const guess=ed.report?ed.report.sec+Math.min(0.3,(performance.now()-ed.report.at)/1000):ed.moveAt;
  ed.stopAt=null;await ForgeDock.pause().catch(()=>{});ed.status='s';
  const t=await reported;return t==null?guess:t;
 }
 async function mark(edge){
  if(!pp)return;
  const t=Math.max(0,Math.min(pp.len,Math.round((await momentNow())*10)/10));
  ed.moveAt=t;
  if(edge==='start'){pp.from=t;if(pp.to<=t+0.05)pp.to=pp.len;toast('Start set at '+clock(t)+'. Tap ▶ Play, then End here.');}
  else{if(t<=pp.from+0.05){toast('The end has to come after the start ('+clock(pp.from)+'). Play a bit further, then tap End here.',true);paintPicker();return;}pp.to=t;toast('End set at '+clock(t)+'. Tap ✓ Done to keep this part.');}
  paintPicker();
 }
 async function finishPart(){
  if(!pp)return;const {i,key,from,to}=pp;
  const p=studioProject(),c=p?.clips[i];if(!c||c.key!==key){pp=null;closePicker();return;}
  if(ed.status==='p'&&monitorLive()){ForgeDock.pause().catch(()=>{});ed.status='s';}
  pp=null;closePicker();
  if(from!==c.from||to!==c.to){if(!await applyTrim(i,from,to)){drawMoves();return;}}
  ed.mode='all';ed.stopAt=null;drawMoves();scheduleRefresh(false);
  toast('Part '+(i+1)+' keeps '+(to-from).toFixed(1)+' s.');
 }
 function paintPicker(){
  const box=document.getElementById('pt');if(!box||!pp)return;
  const at=ed.moveAt||0,playing=ed.status==='p'&&monitorLive();
  const play=box.querySelector('#pt-play');play.textContent=playing?'❚❚ Pause':ed.monitor==='loading'?'Loading…':'▶ Play';
  box.querySelector('#pt-clock').textContent=clock(at)+' / '+clock(pp.len);
  pickerBar(box.querySelector('#pt-bar'),pp.from,pp.to,at,pp.len);
  box.querySelector('#pt-start-v').textContent=clock(pp.from);box.querySelector('#pt-end-v').textContent=clock(pp.to);
  box.querySelector('#pt-keeps').textContent='Keeps '+clock(pp.from)+' → '+clock(pp.to)+' · '+(pp.to-pp.from).toFixed(1)+' s'+(pp.from===0&&pp.to>=pp.len-0.05?' (the whole move)':'');
 }

 // ---- the list of parts
 function drawMoves(){
  const p=studioProject(),box=$('#sl-moves');if(!p||!box)return;
  box.innerHTML=p.clips.map((c,i)=>{const len=sourceLength(c),whole=c.from===0&&c.to>=len-0.05;
   return '<section class="pt-card clip-color-'+(i%6)+'" data-pt="'+i+'" aria-label="Part '+(i+1)+': '+h(c.label)+'">'+
    '<div class="pt-card-head"><span class="sl-no">'+(i+1)+'</span><strong class="sl-name">'+h(c.label)+'</strong><button type="button" class="sl-icon" data-pt-menu="'+i+'" aria-label="More for part '+(i+1)+'">⋯</button></div>'+
    '<p class="pt-card-range">'+(whole?'The whole move':clock(c.from)+' → '+clock(c.to))+' · <b>'+(c.to-c.from).toFixed(1)+' s</b></p>'+
    '<div class="pt-card-actions"><button type="button" class="button pt-choose" data-pt-choose="'+i+'">✂ Choose the part</button><button type="button" class="button ghost" data-pt-watch="'+i+'">▶ Watch</button></div></section>';}).join('');
  box.querySelectorAll('[data-pt-choose]').forEach(b=>b.onclick=()=>choosePart(Number(b.dataset.ptChoose)));
  box.querySelectorAll('[data-pt-watch]').forEach(b=>b.onclick=()=>playPart(Number(b.dataset.ptWatch)));
  box.querySelectorAll('[data-pt-menu]').forEach(b=>b.onclick=()=>moveMenu(Number(b.dataset.ptMenu)));
  const music=$('#tl-music');if(music){music.textContent='🎵 Music';music.setAttribute('aria-label','Music: '+songLabel(p));}
  placeHead();refreshSummary();showStudioChecks();paint();
 }
 function moveMenu(i){
  const p=studioProject(),c=p?.clips[i];if(!c)return;const len=sourceLength(c),n=p.clips.length;
  const item=(label,action,cls='ghost')=>'<button type="button" class="button tl-sheet-btn '+cls+'" data-sl-act="'+action+'">'+h(label)+'</button>';
  const panel=modal('Part '+(i+1)+' · '+c.label,'<div class="tl-sheet">'+
   (i>0?item('↑ Play it earlier','up'):'')+(i<n-1?item('↓ Play it later','down'):'')+
   item('⧉ Use another part of this move too','copy')+
   (c.from>0||c.to<len-0.05?item('↺ Keep the whole move again','reset'):'')+
   item('🗑 Remove this part','remove','danger')+'</div>');
  panel.querySelectorAll('[data-sl-act]').forEach(b=>b.onclick=async()=>{const a=b.dataset.slAct;closePicker();
   try{
    if(a==='reset'){if(await applyTrim(i,0,len)){drawMoves();toast('The whole move is back.');}return;}
    await studioAction(a+':'+i);
    if(ed.mode==='move'&&!findClip(ed.moveKey))ed.mode='all';
    drawMoves();
    if(a==='copy')choosePart(i+1);
   }catch(e){toast(e.message,true);}});
 }
 function sheet(kind){
  const p=studioProject(),independent=!!ForgeAnimationGallery.current(),big=(label,action,style='')=>'<button type="button" class="button tl-sheet-btn '+style+'" data-studio="'+h(action)+'">'+h(label)+'</button>';
  if(kind==='save'){const panel=modal('Save','<div class="tl-sheet">'+big('💾 Save to My animations','gallery-save')+big(independent?'Use on a unit':'Use on my unit','assign','ghost')+big('🎬 Save as a video file','save-video','ghost')+'<p class="hint">Your work also saves by itself as you go.</p></div>');bindStudio(panel);panel.querySelectorAll('[data-studio]').forEach(b=>b.addEventListener('click',()=>{if(b.dataset.studio!=='gallery-save')closePicker();}));return;}
  const panel=modal('More','<div class="tl-sheet">'+big('📁 My animations','gallery','ghost')+big('＋ Start a new animation','gallery-new','ghost')+big('🎞 Combine movie scenes','movie-editor','ghost')+big('Create movement','pose','ghost')+(independent?'':big('Switch unit','my-units','ghost'))+'<div class="row">'+(independent?'':modeButton())+(independent?'':button('Save a backup','backup','ghost small'))+'</div></div>');
  bindStudio(panel);
 }
 // Changes from anywhere (undo, adding, music) rebuild the preview once things settle.
 const baseChange=studioChange;
 studioChange=function(){const r=baseChange.apply(this,arguments);if(document.getElementById('tl'))scheduleRefresh(true);return r;};
 // Leaving the Animations screen closes the editor's preview window.
 const baseNavigate=navigate;
 navigate=async function(view){const was=state.view;const r=await baseNavigate.apply(this,arguments);
  // only after the move succeeded (a failed save keeps you on the editor with its window)
  if(view!=='animations'&&state.view!=='animations'){document.documentElement.classList.remove('tl-active');if(was==='animations')closeMonitor();}return r;};
 function songLabel(p){return p?.music?.title||(p?.music?.kind==='none'?'No music':'Scene audio only');}
 function refreshSummary(){const p=studioProject(),node=$('#simple-sequence-summary');if(node&&p)node.textContent=p.clips.length+' move'+(p.clips.length===1?'':'s')+' · '+S.clock(totalOf(p))+' long';const tl=document.getElementById('tl');if(tl)tl.classList.toggle('tl-empty-state',!p?.clips.length);}
 renderStudio=async function(){
  closePicker();
  if(state.studioTarget&&ForgeAnimationGallery.current())await ForgeAnimationGallery.exit();
  // an independent animation started before another unit was opened gives way to that unit
  if(state.project&&ForgeAnimationGallery.current()&&ForgeAnimationGallery.ownerKey()!==state.project.key)await ForgeAnimationGallery.exit();
  if(!state.project&&!ForgeAnimationGallery.current())await ForgeAnimationGallery.restore();
  const independent=!!ForgeAnimationGallery.current();if(independent)advanced=false;
  if(advanced){await old.render();$('#main').insertAdjacentHTML('afterbegin','<div class="simple-mode-switch row">'+modeButton()+button('New animation','gallery-new','')+button('My animations','gallery')+button('Save to My animations','gallery-save')+'</div>');bindStudio($('#main'));return;}
  studioState.sourceDatabase=studioState.sourceDatabase||state.project?.source?.database||'eclipse';
  const p=studioProject(),owner=studioOwner(),requestedBrowse=state.studioMode==='browse';
  if(state.studioTarget){const t=state.project&&ForgeGuide.targets(state.project).find(x=>x.key===state.studioTarget);if(p&&t)p.target=state.studioTarget;pickFor=t&&requestedBrowse?{key:t.key,name:t.name}:null;state.studioTarget=null;}else if(!requestedBrowse)pickFor=null;
  if(state.studioKind){studioState.kind=state.studioKind;studioState.offset=0;state.studioKind=null;}
  state.studioMode=null;studioState.mode='compose';
  document.documentElement.classList.add('tl-active');
  if(!p||!p.clips.length){
   closeMonitor();
   main('<div class="tl tl-empty-state" id="tl"><div class="tl-empty"><div class="tl-empty-art" aria-hidden="true">▶</div><h1>Make an animation</h1><p>Put moves from any character one after another, keep the parts you like and add music. You watch it as you edit.</p>'+(p?button('＋ Add your first move','browse','tl-big'):button('＋ Start a new animation','gallery-new','tl-big'))+button('📁 My animations','gallery','ghost')+'<div class="row tl-empty-links"><button type="button" class="button ghost small" id="tl-more">⋯ More tools</button><button type="button" class="button ghost small" id="tl-help">? How it works</button></div><p id="simple-sequence-summary" class="tl-hidden"></p><div id="studio-timeline" hidden></div></div></div>');
   bindStudio($('#main'));$('#tl-more').onclick=()=>sheet('more');$('#tl-help').onclick=()=>window.ForgeHelp?.open();if(requestedBrowse)await browse();return;
  }
  main('<div class="tl sl pt-editor" id="tl">'+
   '<div class="tl-head"><button type="button" class="tl-icon" id="tl-help" aria-label="Help for the animation editor">?</button><input id="studio-name" class="tl-name" maxlength="120" aria-label="Animation name" value="'+h(p.name)+'"><button type="button" class="tl-icon" data-studio="undo" aria-label="Undo">↶</button><button type="button" class="tl-icon" data-studio="redo" aria-label="Redo">↷</button></div>'+
   '<section class="pt-top" aria-label="Your animation"><button type="button" class="button tl-play pt-big-play" id="tl-play">▶ <span>Play my animation</span></button><div class="pt-top-info"><span id="tl-clock" class="tl-clock">0:00.0 / 0:00.0</span><span id="simple-sequence-summary" class="tl-summary" role="status"></span></div><div class="pt-progress-track"><div class="pt-progress" id="pt-progress"></div></div></section>'+
   '<h2 class="pt-heading">Parts, in order</h2>'+
   '<div id="sl-moves" class="sl-moves"></div><div id="studio-checks"></div>'+
   '<div class="tl-bottom">'+button('＋ Add a part','browse','tl-add')+'<button type="button" class="button ghost" id="tl-music" data-studio="song">🎵 Music</button><button type="button" class="button ghost" id="tl-save">💾 Save</button><button type="button" class="button ghost" id="tl-more">⋯ More</button></div>'+
  '</div>');
  bindStudio($('#main'));
  $('#studio-name').onchange=()=>{const name=$('#studio-name').value;if(p.name===name)return;p.name=name;studioChange();};
  $('#tl-play').onclick=()=>playPause().catch(e=>toast(e.message,true));
  $('#tl-help').onclick=()=>window.ForgeHelp?.open();
  $('#tl-save').onclick=()=>sheet('save');$('#tl-more').onclick=()=>sheet('more');
  drawMoves();
  if(!monitorLive()&&!pickFor)scheduleRefresh();
  if(requestedBrowse)await browse();
 };
 studioContext=function(){return advanced?old.context():'<span id="studio-context"></span>';};
 showStudioChecks=function(){
  if(advanced)return old.checks();const p=studioProject(),node=$('#studio-checks');if(!node||!p)return;
  const errors=p.clips.length?ForgeMotion.validate(p.clips):[];
  node.innerHTML=errors.length?'<div class="notice error">'+errors.map(h).join('<br>')+'</div>':'';
 };
 loadStudioResults=async function(){
  picker?.querySelector('#sequence-picker-error')?.remove();
  await old.results();if(advanced||state.view!=='animations')return;
  const area=$('#studio-results');if(!area)return;
  area.querySelectorAll('.animation-tile').forEach(tile=>{const name=tile.querySelector('h3')?.textContent.trim().toLowerCase(),owner=(tile.querySelector('h3+p')?.textContent||'').split(' · ')[0].trim();if((name==='none'||!name)&&/^\d*$/.test(owner)){tile.remove();return;}const actions=tile.querySelector('.row');if(!actions)return;actions.classList.add('anim-tile-actions');const add=actions.querySelector('[data-studio^="add:"]')||actions.querySelector('[data-studio^="edit:"]'),preview=actions.querySelector('[data-studio^="preview:"]'),use=actions.querySelector('[data-studio^="use:"]');actions.textContent='';
   // Choosing for one move: ▶ Watch and ✓ Use. Otherwise: ▶ Watch and ＋ Add to the timeline.
   const keep=pickFor&&use?[preview,use]:[preview,add];for(const button of keep.filter(Boolean))actions.appendChild(button);if(preview)preview.textContent='▶ Watch';
   if(pickFor&&use){use.textContent='✓ Use';use.className='button small';}
   else if(add){add.textContent='＋ Add';add.dataset.studio=add.dataset.studio.replace(/^edit:/,'add:');}const description=tile.querySelector('.hint');if(description)description.remove();});
 };
 function showPickerError(e,retryAction=null){
  if(!picker?.open)return;
  let node=picker.querySelector('#sequence-picker-error');if(!node){node=document.createElement('div');node.id='sequence-picker-error';node.setAttribute('role','alert');node.className='notice error';picker.querySelector('.section-heading').after(node);}
  node.textContent=e.message||String(e);
  if(picker.querySelector('#studio-results')){const retry=document.createElement('button');retry.type='button';retry.className='button ghost small';retry.textContent=retryAction?'Try again':'Retry animation list';retry.onclick=async()=>{retry.disabled=true;node.remove();try{await(retryAction?retryAction():loadStudioResults());}catch(error){showPickerError(error,retryAction);}};node.append(document.createElement('br'),retry);}
 }
 async function browse(){
  const panel=modal(pickFor?'Choose an animation':studioState.unitId?(studioState.characterName||'Selected character')+' · moves':'Pick a move',(pickFor?'<p class="notice anim-pick-for">For <strong>'+h(pickFor.name)+'</strong>. Tap <em>▶ Watch</em> to see an animation, then <em>✓ Use</em>. Your move keeps its own damage and effects.</p>':'')+'<label class="field">Search a character or attack<input id="studio-search" type="search" placeholder="Goku, Vegito, Kamehameha…" value="'+h(studioState.unitId?'':studioState.search)+'"></label><div class="row">'+button('Choose character','choose-character')+(state.project&&!ForgeAnimationGallery.current()?button('This unit’s moves','unit-moves'):'')+(studioState.unitId?button('All characters','all-characters'):'')+'</div><p class="hint" id="sequence-filter">'+h(studioState.unitId?'Choose a move below for '+(studioState.characterName||studioState.search||'selected character'):'Search by character or attack, or choose a character to narrow the list.')+'</p><label class="field">Animation type<select id="studio-kind">'+selection(Object.entries(ForgeMotion.kinds),studioState.kind)+'</select></label>'+details('Other collections','<label class="field">Game collection<select id="studio-database">'+selection([['eclipse','Eclipse'],['sparking','Sparking']],studioState.sourceDatabase)+'</select></label><div class="row">'+button('Character moves','characters')+button('All game animations','files')+'</div>')+'<div id="studio-results"><p>Finding animations…</p></div><div id="studio-pages" class="row"></div>');
  $('#studio-search').oninput=()=>{clearTimeout(studioState.timer);studioState.search=$('#studio-search').value;studioState.offset=0;studioState.timer=setTimeout(()=>loadStudioResults().catch(showPickerError),250);};
  $('#studio-kind').onchange=()=>{studioState.kind=$('#studio-kind').value;studioState.offset=0;loadStudioResults().catch(showPickerError);};
  $('#studio-database').onchange=()=>{studioState.sourceDatabase=$('#studio-database').value;studioState.unitId=0;studioState.search='';studioState.offset=0;studioState.files=[];browse().catch(e=>toast(e.message,true));};
  bindStudio(panel);try{await loadStudioResults();}catch(e){showPickerError(e);}$('#studio-search')?.focus();
 }
 // ---- Clip timeline: one card per clip with a visual trim bar (ForgeTrim).
 const sourceLength=c=>{let frames=Number(c.report?.frames)||0;if(!frames){try{frames=ForgeMotion.analyze(c.source?.text||'').frames;}catch{frames=Math.round((c.to||1)*60);}}return Math.max(c.to,frames/60);};
 const markersOf=c=>{let m=c.report?.markers;if(!Array.isArray(m)){try{m=ForgeMotion.analyze(c.source?.text||'').markers;}catch{m=[];}}return m.map(f=>f/60);};
 const isVideo=c=>Boolean(c.report?.video||c.source?.movieBindingKey);
 function updateTimes(){refreshSummary();showStudioChecks();}
 async function applyTrim(index,from,to){
  const p=studioProject(),c=p?.clips[index];if(!c)return false;
  const before={from:c.from,to:c.to};from=Math.round(from*10)/10;to=Math.round(to*10)/10;
  if(from<0||to<=from||to>600){toast('End must be after Start, within ten minutes.',true);return false;}
  c.from=from;c.to=to;
  const undo=()=>{c.from=before.from;c.to=before.to;};
  const candidate={...c,source:{...c.source,sequenceMovieTrim:{from,to}}},early=ForgeMotion.validate(p.clips.map(v=>v===c?candidate:v));
  if(early.length){undo();toast(early[0],true);return false;}
  if(c.report?.video&&(c.from>0||c.source.sequenceMovieTrim)){
   const controller=new AbortController();dialog('Cutting the movie','<p id="sequence-cut-status">Cutting the movie on this phone…</p><button class="button ghost" id="sequence-cut-cancel">Cancel</button>');$('#sequence-cut-cancel').onclick=()=>controller.abort();const dlg=$('#dialog'),cancel=()=>controller.abort();dlg.addEventListener('cancel',cancel,{once:true});
   try{await ForgeSequenceMovies.trim(studioOwner(),c,{signal:controller.signal,progress:t=>{if($('#sequence-cut-status'))$('#sequence-cut-status').textContent=t;}});}
   catch(e){undo();toast(e.name==='AbortError'?'Cut cancelled.':e.message,true);return false;}
   finally{dlg.removeEventListener('cancel',cancel);dlg.close();}
  }
  const errors=ForgeMotion.validate(p.clips);if(errors.length){undo();toast(errors[0],true);return false;}
  studioState.selected=index;studioChange();updateTimes();return true;
 }
 renderStudioTimeline=function(){if(advanced)return old.timeline();drawMoves();};
 async function myUnits(){
  await flushSave();const rows=await Native.call('projects');rows.sort((a,b)=>String(b.updatedAt||'').localeCompare(String(a.updatedAt||''))||String(a.name).localeCompare(String(b.name)));
  const panel=modal('My units','<label class="field">Find your unit<input id="sequence-unit-search" type="search" placeholder="Unit name or custom ID…"></label><div id="sequence-units"></div>');
  const draw=()=>{const query=$('#sequence-unit-search').value,list=rows.filter(r=>S.matches([r.name,r.targetId,r.sourceName,r.key===state.project?.key?'current':''].join(' '),query));$('#sequence-units').innerHTML=list.length?list.map(r=>'<button type="button" class="sequence-unit-choice" data-sequence-unit="'+h(r.key)+'"><strong>'+h(r.name)+'</strong><span>'+h(r.sourceName?'Based on '+r.sourceName:'Your unit')+(r.key===state.project?.key?' · Current unit':'')+'</span></button>').join(''):'<p>No units match. Try part of the name.</p>';panel.querySelectorAll('[data-sequence-unit]').forEach(b=>b.onclick=async()=>{try{b.disabled=true;await flushSave();if(ForgeFormsUI.active())await ForgeFormsUI.leave('editor');await ForgeAnimationGallery.exit();await openUnit(b.dataset.sequenceUnit);studioState.unitId=0;studioState.search='';studioState.sourceDatabase=state.project.source?.database||'eclipse';closePicker();await navigate('animations');if(!studioProject()?.clips.length){studioState.unitId=Number(state.project.source.cardId);studioState.characterName=state.project.source.name;studioState.kind='all';studioState.tab='characters';await browse();}}catch(e){b.disabled=false;toast(e.message,true);}});};$('#sequence-unit-search').oninput=draw;draw();$('#sequence-unit-search').focus();
 }
 async function songs(){
  const unit=studioOwner(),p=studioProject();if(!p)throw Error('Start an animation first.');
  const panel=modal('Music','<button type="button" class="song-upload" data-studio="song-import"><span aria-hidden="true">📁</span><span><strong>Upload my own song</strong><small>Any song from your phone or computer — MP3, M4A, WAV, OGG, AAC or FLAC (up to 160 MB). It plays across the whole animation and goes into the game with your unit.</small></span></button><div class="row">'+button('Scene audio only','song-original')+button('No music','song-none')+'</div><p class="hint">Now playing: <strong>'+h(songLabel(p))+'</strong></p><label class="field">Or pick game music<input id="sequence-song-search" type="search" placeholder="Song title or number…"></label><div id="sequence-songs">Loading songs…</div>');bindStudio(panel);
  const rows=await Native.call('query',{table:'jukebox_tracks',limit:5000});if(!panel.isConnected||studioOwner()!==unit)return;
  const dedup=[...new Map(rows.filter(r=>/^bgm_\d{3,10}$/.test(r.bgm_filename)).map(r=>[r.bgm_filename,r])).values()];
  const draw=()=>{const found=dedup.filter(r=>S.matches(r.title+' '+r.description+' '+r.bgm_filename,$('#sequence-song-search').value));$('#sequence-songs').innerHTML=found.slice(0,100).map(r=>'<button type="button" class="sequence-unit-choice" data-song="'+h(r.bgm_filename)+'"><strong>'+h(r.title||r.bgm_filename)+'</strong><span>'+h(r.bgm_filename)+'</span></button>').join('')||'<p>No matching songs. You can import your own.</p>';panel.querySelectorAll('[data-song]').forEach(b=>b.onclick=()=>{if(studioOwner()!==unit)return;const row=dedup.find(r=>r.bgm_filename===b.dataset.song);p.music=S.music({kind:'game',package:row.bgm_filename,title:row.title||row.bgm_filename});studioChange();renderStudio();});};$('#sequence-song-search').oninput=draw;draw();
 }
 async function importSong(){
  const unit=studioOwner(),p=studioProject();closePicker();const result=await Native.call('import');if(studioOwner()!==unit)throw Error('Your unit changed. Import the song again.');if(!result||!Object.keys(result).length||result.cancelled||result.canceled)return;const a=result.asset;if(!a)throw Error('Select one audio file.');const extension=String(a.name||a.path||'').match(/\.(mp3|m4a|aac|wav|ogg|flac)$/i)?.[1]?.toLowerCase();if(!extension)throw Error('Choose an MP3, M4A, WAV, OGG, AAC or FLAC song.');if(a.size>160*1024*1024)throw Error('Choose a song smaller than 160 MB.');const path='bgm/forge_sequence_'+String(unit.targetId)+'_'+Date.now().toString(36)+'.'+extension;unit.assets=unit.assets||[];unit.assets.push({key:a.key,path,owner:'forge-sequence-music',name:a.name});p.music=S.music({kind:'file',path,title:a.name||'My song'});studioChange();await flushSave();await renderStudio();toast('Song selected. It will play across your combined video.');
 }
 studioAssignDialog=function(){if(ForgeAnimationGallery.current())return ForgeAnimationGallery.chooseUnit(ForgeAnimationGallery.current());if(advanced)return old.assign();const r=old.assign();$('#dialog-title').textContent='Use animation on my unit';const confirm=$('#studio-assign-confirm');if(confirm)confirm.textContent='Use animation & save';return r;};
 studioAction=async function(action){
  if(action==='simple-toggle'){advanced=!advanced;try{localStorage.setItem('forge-animation-editor-v2',advanced?'advanced':'simple');}catch{}return renderStudio();}
  if(ForgeAnimationGallery.current()&&(action==='undo'||action==='redo'))return ForgeAnimationGallery.undo(action==='redo');
  if(action==='gallery-new')return ForgeAnimationGallery.create();if(action==='gallery')return ForgeAnimationGallery.show({unit:ForgeAnimationGallery.current()?null:state.project,target:studioProject()?.target||''});if(action==='gallery-save')return ForgeAnimationGallery.save();
  if(action==='my-units')return myUnits();if(action==='song')return songs();if(action==='song-import')return importSong();
  if(action==='movie-editor'){closePicker();return ForgeMovieEditor.open();}
  if(action==='pose'){closePicker();return old.action(action);}
  if(action==='song-original'||action==='song-none'){const p=studioProject();p.music=action==='song-none'?{kind:'none'}:null;studioChange();return renderStudio();}
  // The selection follows a move when it is moved; a deleted move leaves nothing selected.
  {const m=/^(up|down|remove):(\d+)$/.exec(action);if(m){const i=Number(m[2]),n=studioProject()?.clips.length||0;studioState.selected=m[1]==='remove'?-1:m[1]==='up'?Math.max(0,i-1):Math.min(n-1,i+1);}}
  if(/^copy:\d+$/.test(action)){const p=studioProject(),i=Number(action.slice(5)),c=p?.clips[i];if(!c)return;if(p.clips.length>=24)throw Error('Use up to 24 clips in one animation.');p.clips.splice(i+1,0,{...Forge.clone(c),key:'clip-'+Math.random().toString(36).slice(2)});studioState.selected=i+1;studioChange();renderStudioTimeline();toast('Copied. The copy sits right after the original.');return;}
  if(action==='save-video'){const p=studioProject();if(!p?.clips.length)throw Error('Add an animation first.');const timeline=S.timeline(p.clips),frames=Math.ceil(timeline.slice(-1)[0].end*30);const text='-- FORGE_SEQUENCE_EXPORT '+frames+'\n'+ForgeMotion.compile(p.clips,{damage:false,music:p.music});await flushSave();return Native.call('previewAnimation',{name:p.name,text,...studioPreviewRequest()});}
  if(!advanced){
   if(action==='browse')return browse();
   if(action==='choose-character'){
    const panel=modal('Choose a character','<div id="sequence-character-picker"></div>');
    return ForgeGuideUI.pickUnit('Find a character’s animations',async card=>{studioState.unitId=Number(card.id);studioState.characterName=card.name;studioState.kind='all';studioState.search='';studioState.offset=0;studioState.tab='characters';await browse();},{sourceDatabase:studioState.sourceDatabase,mount:panel.querySelector('#sequence-character-picker'),onBack:browse});
   }
   if(action==='all-characters'||action==='unit-moves'){if(action==='unit-moves')studioState.sourceDatabase=state.project?.source?.database||'eclipse';studioState.unitId=action==='unit-moves'?Number(state.project?.source?.cardId)||0:0;studioState.characterName=state.project?.source?.name;studioState.kind='all';studioState.search='';studioState.tab='characters';studioState.offset=0;return browse();}
   if(action==='characters'||action==='files'){studioState.tab=action;studioState.offset=0;studioState.unitId=0;studioState.search='';return browse();}

  }
  const controls=picker?.open?[...picker.querySelectorAll('button')].map(b=>[b,b.disabled,b.textContent]):[];for(const [b]of controls){b.disabled=true;if(b.dataset.studio===action&&/^(add|edit):/.test(action))b.textContent='Adding…';}
  const before=studioProject()?.clips.length||0;
  try{
   const result=await old.action(action);
   // a new part: go straight to choosing which part of it to keep
   if(/^add:/.test(action)&&!advanced&&!pickFor){const p=studioProject();if(p&&p.clips.length>before&&document.getElementById('tl')){const i=Number.isInteger(studioState.selected)&&studioState.selected>=0?studioState.selected:p.clips.length-1;setTimeout(()=>{if(document.getElementById('sl-moves')){drawMoves();choosePart(Math.min(i,p.clips.length-1));}},50);}}
   return result;
  }catch(e){if(picker?.open)showPickerError(e,()=>studioAction(action));throw e;}finally{for(const [b,disabled,label]of controls)if(b.isConnected){b.disabled=disabled;b.textContent=label;}}
 };
 window.ForgeBeginnerAnimations={advanced:()=>advanced};
})();
