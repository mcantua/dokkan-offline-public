(function(root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory(require('./core'), require('./motion'), require('./guide-model'));
  else root.ForgeCombatProject = factory(root.Forge, root.ForgeMotion, root.ForgeGuide);
})(typeof globalThis !== 'undefined' ? globalThis : this, function(Forge, Motion, Guide) {
  'use strict';
  const actions = Object.freeze(['normal','super','ultimate','ex','active','dash','launcher','combo','counter','dodge','transform','intro','victory']);
  const actionSet = new Set(actions), forbidden = new Set(['__proto__','prototype','constructor']);
  const aliases = {normal:'normal',super:'super',ultra:'ultimate',ultimate:'ultimate',ex:'ex',active:'active',counter:'counter',dodge:'dodge',transform:'transform',intro:'intro'};
  const localPurposes = new Set(['dash','launcher','combo','victory']);
  const passiveWarning = 'Workshop uses card stats; native passive/leader/conditional rules not simulated';
  const fail = message => { throw new Error(message); };
  function clone(value) {
    let nodes=0, bytes=0;
    function copy(v,depth) {
      if (++nodes>150000 || depth>45) fail('This workshop project is too complex.');
      if (v===null || typeof v==='boolean') return v;
      if (typeof v==='number') {if(!Number.isFinite(v))fail('Choose finite workshop values.');return v;}
      if (typeof v==='string') {bytes+=v.length;if(bytes>32*1024*1024)fail('Workshop data exceeds 32 MB.');return v;}
      if (typeof v!=='object') fail('Workshop data must contain plain saved values.');
      if(Object.getOwnPropertySymbols(v).length)fail('Unsupported workshop keys.');
      const proto=Object.getPrototypeOf(v);
      if(Array.isArray(v)) {
        if(proto!==Array.prototype||v.length>100000)fail('Invalid workshop list.');
      } else if(proto!==Object.prototype&&proto!==null)fail('Workshop data must contain plain saved objects.');
      const out=Array.isArray(v)?[]:{};
      for(const key of Object.keys(v)) {
        if(forbidden.has(key))fail('Unsafe workshop object key.');
        const field=Object.getOwnPropertyDescriptor(v,key);if(!field||!('value'in field))fail('Unsupported workshop field.');
        if(field.value===undefined&&!Array.isArray(v))continue;
        out[key]=copy(field.value,depth+1);
      }
      return out;
    }
    return copy(value,0);
  }
  function object(value,label){if(!value||typeof value!=='object'||Array.isArray(value))fail('Choose valid '+label+'.');return value;}
  function id(value,label) {if(typeof value!=='number'||!Number.isSafeInteger(value)||value<1)fail('Choose a valid '+label+'.');return value;}
  // The editor assigns negative IDs to newly authored database rows until export.
  // They are valid draft records; card identities and external game references
  // still use the positive-only id() validation above.
  function recordId(value,label) {if(typeof value!=='number'||!Number.isSafeInteger(value)||value===0)fail('Choose a valid '+label+'.');return value;}
  function action(value){if(typeof value!=='string'||!actionSet.has(value))fail('Choose a supported workshop action.');return value;}
  function name(value,fallback) {if(value==null)value=fallback;if(typeof value!=='string'||!value.trim()||value.length>160||/[\x00-\x1f\x7f]/.test(value))fail('Choose a readable workshop name.');return value.trim();}
  function path(value){return typeof value==='string'&&value.length<=500&&!/[\\\x00-\x20%?#:]/.test(value)&&!value.startsWith('/')&&value.split('/').every(x=>x&&x!=='.'&&x!=='..'&&!forbidden.has(x));}
  function fingerprints(value) {
    if(value.sourceDatabase!=null&&!['eclipse','sparking'].includes(value.sourceDatabase))fail('Unknown animation database.');
    for(const key of ['sourceVersion','sparkingVersion','version'])if(value[key]!=null)id(value[key],'animation version');
    if(value.sha256!=null&&(typeof value.sha256!=='string'||! /^[a-f0-9]{64}$/i.test(value.sha256)))fail('Invalid animation fingerprint.');
    for(const key of ['path','assetKey','resourcePath','file'])if(value[key]!=null&&!path(value[key]))fail('Unsafe animation path.');
    for(const key of ['cardId','effectId','movieEffectPackId'])if(value[key]!=null)id(value[key],'animation reference');
    if(value.catalog){object(value.catalog,'animation catalogue');fingerprints(value.catalog);}
  }
  function stable(value){if(Array.isArray(value))return '['+value.map(stable).join(',')+']';if(value&&typeof value==='object')return '{'+Object.keys(value).sort().map(k=>JSON.stringify(k)+':'+stable(value[k])).join(',')+'}';return JSON.stringify(value);}
  function binding(value,key) {
    const out=clone(object(value,'workshop binding'));out.name=name(out.name,key);
    if(out.targetKey!=null&&(typeof out.targetKey!=='string'||! /^(?:[a-z][a-z0-9_-]*:)?[a-zA-Z0-9:_-]{1,140}$/.test(out.targetKey)||out.targetKey.split(':').some(x=>forbidden.has(x))))fail('Invalid workshop target.');
    if(out.mode!=null&&!['original','composition'].includes(out.mode))fail('Unknown workshop animation mode.');
    if(!Array.isArray(out.clips)||!out.clips.length||out.clips.length>24)fail('Choose one to 24 real animation clips.');
    for(const clip of out.clips) {
      object(clip,'animation section');object(clip.source,'animation source');fingerprints(clip.source);
      if(typeof clip.source.text!=='string'||!clip.source.text.trim()||clip.source.text.length>2*1024*1024)fail('An animation section needs its bounded original source.');
    }
    const errors=Motion.validate(out.clips);
    if(out.mode==='original') {
      fingerprints(object(out.originalSource,'whole original source'));
      const original=out.originalSource;
      if(!Guide.canReuseOriginal(original,{kind:original.catalog?.kind})||out.clips.length!==1)fail('Choose an unchanged whole original animation.');
      const actual=out.clips[0],canonical=Motion.createClip(original);
      for(const field of ['from','to','x','y','zoom','rotation','opacity','mirror','mute','actor'])if(actual[field]!==canonical[field])fail('Whole original animations cannot be edited in the workshop.');
      if(stable(actual.source)!==stable(original))fail('The original animation fingerprint changed.');
    } else if(errors.length)fail(errors.join('\n'));
    if(out.originalSource)fingerprints(out.originalSource);
    if(out.id!=null)recordId(out.id,'saved animation ID');
    fingerprints(out);out.targetKey=out.targetKey||'workshop:'+key;out.localOnly=true;out.nativeExport=false;
    return out;
  }
  function validateBindings(value) {
    const map=clone(object(value,'workshop bindings')),out={};
    for(const key of Object.keys(map)){action(key);out[key]=binding(map[key],key);}
    return out;
  }
  function savedBindings(p) {
    if(p.combatWorkshop==null)return{};
    const saved=object(p.combatWorkshop,'saved workshop');
    if(saved.version!==1)fail('Unsupported saved workshop version.');
    return validateBindings(saved.bindings);
  }
  function project(p){object(p,'unit project');if(!p.tables||!Array.isArray(p.tables.cards)||p.tables.cards.length!==1)fail('Open a unit with one real card record.');id(p.targetId,'unit ID');object(p.source,'source card');id(p.source.cardId,'source card ID');const row=object(p.tables.cards[0],'card record');if(id(row.id,'card record ID')!==p.source.cardId)fail('The card record must match its source ID.');if(p.cardOverrides!=null){object(p.cardOverrides,'card overrides');if(Object.prototype.hasOwnProperty.call(p.cardOverrides,'id'))fail('Keep the original source card ID unchanged.');}if(p.source.database!=null&&!['eclipse','sparking'].includes(p.source.database))fail('Unknown project database.');return p;}
  function fromProject(input) {
    const p=project(clone(input)),card=Forge.card(p),warnings=[passiveWarning],bindings={},nativeKinds=new Set();
    const targets=Guide.targets(p),byKey=new Map(targets.map(t=>[t.key,t]));
    for(const target of targets){if(target.row!=null)recordId(target.row,'saved move ID');if(aliases[target.kind]&&!target.virtual)nativeKinds.add(aliases[target.kind]);}
    if(p.animationAssignments!=null)object(p.animationAssignments,'saved animation assignments');
    for(const [key,saved]of Object.entries(p.animationAssignments||{})) {
      const target=byKey.get(key),kind=target&&aliases[target.kind];
      if(!target)fail('A saved animation points to an unknown move target: '+key);
      if(!kind){warnings.push('A saved animation target is not a supported workshop action: '+key);continue;}
      if(bindings[kind]){warnings.push('More than one saved '+kind+' animation exists; the first is selected for this workshop.');continue;}
      bindings[kind]=binding({...saved,name:saved.name||target.name,targetKey:key},kind);
    }
    if(p.actionHooks?.dodge)bindings.dodge=binding({...p.actionHooks.dodge,targetKey:'dodge:unit'},'dodge');
    const sequence=p.composition||p.animationStudio;
    if(sequence&&localPurposes.has(sequence.purpose)&&Array.isArray(sequence.clips)&&sequence.clips.length) {
      bindings[sequence.purpose]=binding({name:sequence.name,clips:sequence.clips,targetKey:'workshop:'+sequence.purpose},sequence.purpose);
      warnings.push('The '+sequence.purpose+' sequence is used locally in the workshop; this does not add an Eclipse gameplay hook.');
    }
    Object.assign(bindings,savedBindings(p));
    function stat(key){const v=card[key+'_max']??card[key]??card[key+'_init'];const n=typeof v==='string'&&/^\d+(?:\.\d+)?$/.test(v)?Number(v):v;if(typeof n!=='number'||!Number.isFinite(n)||n<=0)fail('Choose positive finite '+key.toUpperCase()+' stats.');if(n>1e9)warnings.push('Workshop '+key.toUpperCase()+' is capped at 1,000,000,000.');return Math.max(1,Math.min(1e9,Math.round(n)));}
    const element=card.element??0;if(!Number.isInteger(element)||![0,1,2,3,4,10,11,12,13,14,20,21,22,23,24].includes(element))fail('Choose a valid character type.');
    return {unit:{id:p.targetId,name:name(card.name,p.source.name||'Custom unit'),hp:stat('hp'),atk:stat('atk'),def:stat('def'),element,kiMax:24},source:{database:p.source.database||'eclipse',cardId:p.source.cardId,name:name(p.source.name,card.name)},bindings,warnings:[...new Set(warnings)],coverage:{supported:actions.filter(k=>Object.prototype.hasOwnProperty.call(bindings,k)),inherited:actions.filter(k=>nativeKinds.has(k)&&!Object.prototype.hasOwnProperty.call(bindings,k))}};
  }
  function assign(input,key,value) {
    action(key);const next=project(clone(input)),current=savedBindings(next),ready=binding(value,key);
    current[key]=ready;next.combatWorkshop={version:1,bindings:current};return next;
  }
  function clear(input,key) {
    action(key);const next=project(clone(input)),current=savedBindings(next);delete current[key];next.combatWorkshop={version:1,bindings:current};return next;
  }
  return {actions,fromProject,validateBindings,assign,clear};
});
