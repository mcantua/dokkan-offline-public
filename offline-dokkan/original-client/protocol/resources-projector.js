/* Data-only original-client response projection. No scenes, gameplay, network,
 * captured player values, login fixtures or route admission live in this module.
 * The native host supplies one atomic canonical-player snapshot and reviewed
 * master/fresh-player policy sections. Reused unchanged by bundled JSC and Node. */
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  else Object.defineProperty(root,'ODResourcesProjector',{value:api,writable:false});
})(typeof globalThis==='object'?globalThis:this,function(){
  'use strict';
  const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
  const object=x=>x!==null&&typeof x==='object'&&!Array.isArray(x);
  const integer=x=>Number.isSafeInteger(x);
  const clone=x=>JSON.parse(JSON.stringify(x));
  const equal=(a,b)=>JSON.stringify(a)===JSON.stringify(b);
  function issue(list,path,code){list.push({path,code});}
  function check(schema,value,path,issues,depth){
    if(depth>24||!object(schema)){issue(issues,path,'UNSUPPORTED_SCHEMA');return;}
    const type=schema.type;
    if(type==='union'){
      const variants=Array.isArray(schema.variants)?schema.variants:[];
      if(!variants.some(variant=>{const failures=[];check(variant,value,path,failures,depth+1);return failures.length===0;}))issue(issues,path,'UNOBSERVED_VALUE_SHAPE');
      return;
    }
    if(type==='object'){
      if(!object(value)){issue(issues,path,'EXPECTED_OBJECT');return;}
      const properties=object(schema.properties)?schema.properties:{};
      if((schema.redacted_key_count||0)>0||own(properties,'[redacted-key]'))issue(issues,path,'UNREVIEWED_FIELD_NAMES');
      for(const name of Object.keys(properties)){
        if(name==='[redacted-key]')continue;
        if(!own(value,name))issue(issues,path+'.'+name,'NATIVE_POLICY_REQUIRED');
        else check(properties[name],value[name],path+'.'+name,issues,depth+1);
      }
      for(const name of Object.keys(value)){
        if(!own(properties,name))issue(issues,path,'UNOBSERVED_FIELD');
      }
      return;
    }
    if(type==='array'){
      if(!Array.isArray(value)){issue(issues,path,'EXPECTED_ARRAY');return;}
      const variants=Array.isArray(schema.items)?schema.items:[];
      if(value.length&&!variants.length){issue(issues,path,'UNOBSERVED_ARRAY_ITEMS');return;}
      for(let index=0;index<value.length;++index){
        if(!variants.some(variant=>{const failures=[];check(variant,value[index],path+'[]',failures,depth+1);return failures.length===0;})){
          issue(issues,path+'[]','UNOBSERVED_VALUE_SHAPE');break;
        }
      }
      return;
    }
    const valid=type==='integer'?integer(value):type==='number'?(typeof value==='number'&&Number.isFinite(value)):
      type==='string'?typeof value==='string':type==='boolean'?typeof value==='boolean':type==='null'?value===null:false;
    if(!valid)issue(issues,path,type==='not_expanded'?'UNEXPANDED_SCHEMA':'UNOBSERVED_VALUE_SHAPE');
  }
  function balance(inventory,kind){
    let found=false,quantity=0;
    for(const row of inventory){
      if(!object(row)||typeof row.kind!=='string'||!integer(row.id)||!integer(row.quantity)||row.quantity<0)throw Error('INVALID_OWN_INVENTORY');
      if(row.kind!==kind)continue;
      if(row.id!==0||found)throw Error('INVALID_OWN_CURRENCY');
      found=true;quantity=row.quantity;
    }
    // Absence in the actual canonical ledger means no holdings. This does not
    // grant an initial balance or substitute an unknown source collection.
    return quantity;
  }
  function bind(target,key,value,path,issues,predicate){
    if(!predicate(value)){issue(issues,path+'.'+key,'CANONICAL_VALUE_UNAVAILABLE');return;}
    if(own(target,key)&&!equal(target[key],value))throw Error('POLICY_OVERRIDES_CANONICAL_PLAYER');
    target[key]=value;
  }
  function cards(snapshot,provided,issues){
    if(!Array.isArray(snapshot.cards))throw Error('INVALID_OWN_CARDS');
    if(!snapshot.cards.length){
      if(provided!==undefined&&(!Array.isArray(provided)||provided.length))throw Error('POLICY_OVERRIDES_OWNED_CARDS');
      return [];
    }
    if(!Array.isArray(provided)){issue(issues,'$.cards','NATIVE_OWNED_CARD_POLICY_REQUIRED');return undefined;}
    const policies=new Map();
    for(const row of provided){
      if(!object(row)||!integer(row.id)||policies.has(row.id))throw Error('INVALID_NATIVE_CARD_POLICY');
      policies.set(row.id,row);
    }
    if(policies.size!==snapshot.cards.length)throw Error('POLICY_OVERRIDES_OWNED_CARDS');
    return snapshot.cards.map(owned=>{
      if(!object(owned)||!integer(owned.instance_id)||!policies.has(owned.instance_id))throw Error('POLICY_OVERRIDES_OWNED_CARDS');
      const row=clone(policies.get(owned.instance_id));
      bind(row,'id',owned.instance_id,'$.cards[]',issues,x=>integer(x)&&x>0);
      if(owned.created_definition||owned.tournament_definition||owned.official_upgrade){
        // A template ID is not an established engine identity for modified
        // rows. Trusted native policy must resolve its admitted engine binding;
        // no unreviewed numeric allocation or assumed global-cache override.
        if(!integer(row.card_id)||row.card_id<=0)issue(issues,'$.cards[]','NATIVE_ENGINE_CARD_BINDING_REQUIRED');
      }else bind(row,'card_id',owned.master_id,'$.cards[]',issues,x=>integer(x)&&x>0);
      bind(row,'skill_lv',owned.sa_level,'$.cards[]',issues,x=>integer(x)&&x>0);
      bind(row,'exp',owned.experience,'$.cards[]',issues,x=>integer(x)&&x>=0);
      // Other EXP/link/potential/awakening/timestamp fields require actual
      // stored state or verified master/policy projections, never cache values.
      return row;
    });
  }
  function validateObserved(structure,response){
    const issues=[];check(structure,response,'$',issues,0);
    return {shape_compatible:issues.length===0,issues};
  }
  function project(evidence,envelope,expected,configuredSections){
    if(!object(evidence)||!object(evidence.structure)||evidence.all_scalar_values_removed!==true||evidence.player_state_adopted!==false)throw Error('UNREVIEWED_RESOURCE_SCHEMA');
    if(!object(envelope)||!object(envelope.admission)||!object(envelope.player_snapshot)||!object(expected))throw Error('INVALID_NATIVE_SNAPSHOT');
    const admission=envelope.admission,snapshot=envelope.player_snapshot;
    for(const key of ['profile_id','content_id','save_scope_sha256']){
      if(typeof expected[key]!=='string'||admission[key]!==expected[key])throw Error('CANONICAL_PLAYER_SCOPE_CHANGED');
    }
    if(snapshot.profile_id!==expected.profile_id||snapshot.content_id!==expected.content_id||!Array.isArray(snapshot.inventory))throw Error('CANONICAL_PLAYER_SCOPE_CHANGED');
    if(configuredSections!==undefined&&!object(configuredSections))throw Error('INVALID_NATIVE_RESOURCE_POLICY');
    const response=configuredSections===undefined?{}:clone(configuredSections),issues=[];
    if(own(response,'user')&&!object(response.user))throw Error('INVALID_NATIVE_RESOURCE_POLICY');
    const user=response.user||{},identity=envelope.wire_identity||snapshot.wire_identity;
    bind(user,'act',snapshot.stamina,'$.user',issues,x=>integer(x)&&x>=0);
    bind(user,'act_max',snapshot.stamina_max,'$.user',issues,x=>integer(x)&&x>=0);
    bind(user,'rank',snapshot.rank,'$.user',issues,x=>integer(x)&&x>0);
    bind(user,'exp',snapshot.rank_experience,'$.user',issues,x=>integer(x)&&x>=0);
    if(object(snapshot.source_rank)){
      if(snapshot.source_rank.rank!==snapshot.rank)throw Error('SOURCE_RANK_SCOPE_MISMATCH');
      bind(user,'friends_capacity',snapshot.source_rank.friends_capacity,'$.user',issues,x=>integer(x)&&x>=0);
    }
    bind(user,'stone',balance(snapshot.inventory,'stone'),'$.user',issues,x=>integer(x)&&x>=0);
    bind(user,'zeni',balance(snapshot.inventory,'zeni'),'$.user',issues,x=>integer(x)&&x>=0);
    bind(user,'id',object(identity)?identity.id:undefined,'$.user',issues,x=>integer(x)&&x>0);
    bind(user,'name',object(identity)?identity.name:undefined,'$.user',issues,x=>typeof x==='string'&&x.length>0&&x.length<=64);
    response.user=user;
    const projectedCards=cards(snapshot,response.cards,issues);
    if(projectedCards!==undefined)response.cards=projectedCards;
    if(admission.clean!==true&&snapshot.cards.some(row=>object(row)&&(row.created_definition||row.tournament_definition||row.official_upgrade)))
      issue(issues,'$.cards','NATIVE_PROJECTION_PENDING');
    const shape=validateObserved(evidence.structure,response);issues.push(...shape.issues);
    const unique=[];const seen=new Set();
    for(const item of issues){const key=item.path+'\0'+item.code;if(!seen.has(key)){seen.add(key);unique.push(item);}}
    return {
      schema:1,kind:'own-player-resource-projection',profile_id:expected.profile_id,content_id:expected.content_id,
      save_scope_sha256:expected.save_scope_sha256,core_revision:snapshot.revision,
      response,shape_compatible:unique.length===0,issues:unique,
      body_json:unique.length===0?JSON.stringify(response):null,
      http_route_admitted:false,original_iphone_runtime_verified:false,captured_player_values_used:false
    };
  }
  return Object.freeze({project,validateObserved});
});
