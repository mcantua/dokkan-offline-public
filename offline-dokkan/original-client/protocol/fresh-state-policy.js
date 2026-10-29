/* Fresh-state policy for the unified Duo host.
 * Rank, rank EXP, max ACT and friends capacity are admitted only when they
 * already match on the canonical snapshot and its selected-master source_rank.
 * This module does not hard-code those numbers and does not invent them when
 * the master row is missing. Tutorial finished=true and zero capacities are
 * pre-server model sentinels. They are rejected, never copied into sections.
 * Native-owned original_client_tutorial is separate from proposed sections:
 * only an actually new persisted profile has the admitted start/ checkpoint
 * state. Migrated profiles remain unresolved. Missing contents/capacity fields
 * stay omitted. No played cache value is read. No resource success
 * body or HTTP route is produced. */
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  else Object.defineProperty(root,'ODFreshStatePolicy',{value:api,writable:false});
})(typeof globalThis==='object'?globalThis:this,function(){
  'use strict';
  const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
  const object=x=>x!==null&&typeof x==='object'&&!Array.isArray(x);
  const integer=x=>Number.isSafeInteger(x);
  const SENTINEL_KEYS=new Set([
    'tutorial','is_finished','contents_lv','card_capacity','total_card_capacity',
    'support_item_capacity','is_support_item_capacity_extended'
  ]);
  const UNRESOLVED=[
    'tutorial.progress','tutorial.contents_lv','tutorial.is_finished',
    'card_capacity','total_card_capacity','support_item_capacity',
    'is_support_item_capacity_extended'
  ];
  function sentinel(value,depth){
    if(depth>24)throw Error('INVALID_FRESH_POLICY');
    if(Array.isArray(value)){
      for(const item of value)sentinel(item,depth+1);
      return;
    }
    if(!object(value))return;
    for(const key of Object.keys(value)){
      if(SENTINEL_KEYS.has(key))throw Error('PRE_SERVER_SENTINEL_REJECTED');
      sentinel(value[key],depth+1);
    }
  }
  function jsonCopy(value){
    let text;
    try{text=JSON.stringify(value);}catch(error){throw Error('INVALID_FRESH_POLICY');}
    if(typeof text!=='string')throw Error('INVALID_FRESH_POLICY');
    return JSON.parse(text);
  }
  function evaluate(snapshot,proposed){
    if(!object(snapshot)||!object(snapshot.source_rank))throw Error('SOURCE_RANK_REQUIRED');
    const source=snapshot.source_rank;
    if(!integer(snapshot.rank)||!integer(snapshot.rank_experience)||!integer(snapshot.stamina_max)||
       !integer(source.rank)||!integer(source.exp_total)||!integer(source.act_max)||!integer(source.friends_capacity))
      throw Error('INVALID_FRESH_SNAPSHOT');
    if(source.act_max<1||source.friends_capacity<0)throw Error('SOURCE_RANK_REQUIRED');
    if(source.rank!==snapshot.rank||source.exp_total!==snapshot.rank_experience||source.act_max!==snapshot.stamina_max)
      throw Error('SOURCE_RANK_SCOPE_MISMATCH');
    if(snapshot.rank!==1||snapshot.rank_experience!==0||source.exp_total!==0)throw Error('FRESH_RANK_NOT_ESTABLISHED');
    if(proposed!==undefined&&proposed!==null){
      if(!object(proposed))throw Error('INVALID_FRESH_POLICY');
      sentinel(proposed,0);
    }
    const sections=proposed===undefined||proposed===null?{}:jsonCopy(proposed);
    const unresolved=UNRESOLVED.slice(),admitted=[];
    const tutorial=snapshot.original_client_tutorial;
    if(tutorial!==undefined&&tutorial!==null){
      if(!object(tutorial)||Object.keys(tutorial).length!==4||tutorial.schema!==1||
         tutorial.policy!=='original-tutorial-entry-v1'||!integer(tutorial.progress)||
         tutorial.progress<0||tutorial.progress>2147483647||tutorial.is_finished!==false)
        throw Error('INVALID_CANONICAL_TUTORIAL');
      if(own(sections,'user')&&!object(sections.user))throw Error('INVALID_FRESH_POLICY');
      const user=sections.user||{};
      user.tutorial={progress:tutorial.progress,is_finished:false};sections.user=user;
      for(const field of ['tutorial.progress','tutorial.is_finished']){
        unresolved.splice(unresolved.indexOf(field),1);admitted.push(field);
      }
    }
    return {
      schema:1,
      kind:'fresh-state-policy',
      sections,
      admitted_source_facts:['rank','exp_total','act_max','friends_capacity'],
      admitted_canonical_tutorial_fields:admitted,
      unresolved,
      pre_server_sentinels_adopted:false,
      played_cache_values_adopted:false,
      starting_stats_invented:false,
      http_body_json:null,
      http_route_admitted:false
    };
  }
  return Object.freeze({evaluate,SENTINEL_KEYS,UNRESOLVED});
});
