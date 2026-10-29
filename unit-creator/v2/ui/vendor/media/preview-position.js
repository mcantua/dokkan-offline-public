/* Original Forge adapter for native setLastPosKey. MIT.
 * Native callback/insertion proof: tests/native-preview-position.py.
 * Prior battle positions are explicit preview choices, never guessed from IDs. */
const own=(object,key)=>Object.prototype.hasOwnProperty.call(object,key);
const choices=Object.freeze({left:-.25,center:0,right:.25,outside:-2});
export function positionKeyCommands(commands,positions={}) {
  if(!Array.isArray(commands))return [];
  if(!commands.some(command=>command.type==='setLastPosKey'))return commands;
  const ordered=commands.map((command,index)=>({command,index,order:Number.isSafeInteger(command.forgeOrder)?command.forgeOrder:index})).sort((a,b)=>a.order-b.order||a.index-b.index);
  const result=[],seen=new Map();
  for(const {command}of ordered){
    let key=command;
    if(command.type==='setLastPosKey'){
      const actor=Number(command.args?.[1]),frame=Math.trunc(Number(command.args?.[0]??command.frame));
      if(!own(positions,actor))continue;
      const position=positions[actor];
      if(!Number.isInteger(actor)||!Number.isFinite(frame)||frame<0||!position||![position.x,position.y,position.z??0].every(Number.isFinite))throw Error('Invalid starting-position preview context.');
      key={...command,type:'setMoveKey',frame,chara:actor,x:position.x,y:position.y,z:position.z??0,forgePreviousPosition:true};
    }
    if(key.type==='setMoveKey'){
      const actor=Number(key.chara),frame=Number(key.frame),identity=actor+':'+frame;
      // The original native position tree retains the first insertion at a key.
      // Selection order is native Lua invocation order, before timeline sorting.
      if(seen.has(identity))continue;
      seen.set(identity,true);
    }
    result.push(key);
  }
  return result;
}
export class PositionCommands {
  constructor(runner){this.runner=runner;this.positions={};this.selection={};this.panel=null;this.notice=null;this.commands=null;this.hidden=new Map();this.unknownUntil=new Map();this.frame=0;}
  _host(){return this.runner.chara?.host||this.runner.lwf?.host;}
  async preload(commands=[]){
    if(this.commands===commands)return;
    this.panel?.remove();this.panel=null;this.commands=commands;this.positions={};this.selection={};
    const actors=[...new Set(commands.filter(command=>command.type==='setLastPosKey').map(command=>Number(command.args?.[1])))].filter(Number.isInteger);
    if(!actors.length)return;
    const panel=document.createElement('details');panel.open=true;panel.dataset.forgeStartingPositions='true';panel.style.cssText='margin:12px;padding:12px;background:#19212e;color:white;border:1px solid #64748b;border-radius:8px;font:16px sans-serif;';
    const title=document.createElement('summary');title.textContent='Choose starting positions';panel.appendChild(title);
    const explanation=document.createElement('p');explanation.textContent='This move continues from an earlier battle position. Choose where the characters start for this preview.';panel.appendChild(explanation);
    const fields=[];
    for(const[additional,actor]of actors.entries()){
      const label=document.createElement('label');label.style.cssText='display:block;margin:12px 0;';label.textContent=actor===0?'Attacker':actor===1?'Opponent':'Additional character '+(additional+1);
      const select=document.createElement('select');select.style.cssText='display:block;width:100%;font:16px sans-serif;padding:10px;';
      for(const[value,text]of[['','Choose a position'],['left','Left side'],['center','Center'],['right','Right side'],['outside','Outside the screen']]){const option=document.createElement('option');option.value=value;option.textContent=text;select.appendChild(option);}
      label.appendChild(select);panel.appendChild(label);fields.push({actor,select});
    }
    const button=document.createElement('button');button.type='button';button.textContent='Apply & restart preview';button.style.cssText='font:16px sans-serif;padding:10px 12px;';panel.appendChild(button);
    const status=document.createElement('p');status.setAttribute('role','status');panel.appendChild(status);
    button.addEventListener('click',()=>{try{
      if(!this.runner.ready)throw Error('Wait for this move to finish loading.');
      const width=Number(this.runner.chara?._size?.w);if(!Number.isFinite(width)||width<=0)throw Error('The preview stage is not ready.');
      const positions={},selection={};for(const {actor,select}of fields){if(!own(choices,select.value))throw Error('Choose a starting position for each character.');positions[actor]={x:width*choices[select.value],y:0,z:0};selection[actor]=select.value;}
      this.positions=positions;this.selection=selection;this.runner.stop?.({silent:true});if(this.runner.play?.()===false)throw Error('The move could not restart.');status.textContent='Preview restarted with your starting positions.';
    }catch(error){status.textContent=error.message;}});
    const host=this._host(),mode=host?.closest?.('#modeLua');if(mode)mode.appendChild(panel);else document.body.appendChild(panel);this.panel=panel;
  }
  characterCommands(commands){return positionKeyCommands(commands,this.positions);}
  prepare(){
    this.clear();
    for(const command of this.commands||[]){
      if(command.type!=='setLastPosKey')continue;
      const actor=Number(command.args?.[1]),at=Number(command.args?.[0]??command.frame);if(own(this.positions,actor))continue;
      const next=(this.commands||[]).filter(key=>key.type==='setMoveKey'&&Number(key.chara)===actor&&Number(key.frame)>=at).map(key=>Number(key.frame));
      this.unknownUntil.set(actor,Math.max(this.unknownUntil.get(actor)||0,next.length?Math.min(...next):Infinity));
    }
  }
  update(frame){this.frame=Number(frame)||0;}
  render(){
    for(const[actor,end]of this.unknownUntil){
      const style=this.runner.chara?.chars?.get?.(actor)?.wrap?.style;if(!style)continue;
      if(this.frame<end){if(!this.hidden.has(style))this.hidden.set(style,{value:style.getPropertyValue('visibility'),priority:style.getPropertyPriority('visibility')});style.setProperty('visibility','hidden');}
      else if(this.hidden.has(style)){this._restore(style,this.hidden.get(style));this.hidden.delete(style);}
    }
  }
  execute(command){
    if(command.type!=='setLastPosKey')return false;
    const actor=Number(command.args?.[1]);if(!own(this.positions,actor)&&!this.notice){
      const host=this._host();if(host){const note=document.createElement('div');note.dataset.forgePositionNotice='true';note.setAttribute('role','status');note.textContent='Choose starting positions below to preview this continuation from battle.';note.style.cssText='position:absolute;left:12px;right:12px;top:12px;padding:8px;background:rgba(20,24,32,.92);color:white;z-index:10001;font:16px sans-serif;pointer-events:none;';host.appendChild(note);this.notice=note;}
      this.runner.log?.('Starting-position preview requires an explicit previous battle placement.');
    }
    return true;
  }
  _restore(style,saved){if(style.getPropertyValue('visibility')!=='hidden')return;if(saved.value)style.setProperty('visibility',saved.value,saved.priority);else style.removeProperty('visibility');}
  clear(){this.notice?.remove();this.notice=null;for(const[style,saved]of this.hidden)this._restore(style,saved);this.hidden.clear();this.unknownUntil.clear();this.frame=0;}
}
