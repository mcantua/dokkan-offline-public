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
  // Actual iPhone User decoder: the 492-byte getter converts through unsigned
  // W0, the 404-byte getter through unsigned X0, and act_at through signed X0.
  // JSON numbers outside JS's exact integer range need a native integer bridge;
  // never round, clamp or emit an integer the original reader cannot represent.
  const userUint32Fields=Object.freeze([
    'rank','act','act_max','card_capacity','total_card_capacity','zeni','stone',
    'exchange_point','friends_capacity','support_item_capacity','gasha_point',
    'wallpaper_item_id','achievement_id','mainpage_card_id','act_cure_shortened_sec'
  ]);
  const userUint64Fields=Object.freeze(['id','exp','total_score','mainpage_user_card_id']);
  function checkNativeUserIntegers(user,issues){
    // The native member-with-prior-value helper preserves the prior value for
    // absent/null fields. This check does not invent a replacement/default.
    for(const name of userUint32Fields){
      if(own(user,name)&&user[name]!==null&&(!integer(user[name])||user[name]<0||user[name]>4294967295))
        issue(issues,'$.user.'+name,'NATIVE_UINT32_REQUIRED');
    }
    for(const name of userUint64Fields){
      if(own(user,name)&&user[name]!==null&&(!integer(user[name])||user[name]<0))
        issue(issues,'$.user.'+name,'NATIVE_UINT64_EXACT_INTEGER_REQUIRED');
    }
    if(own(user,'act_at')&&user.act_at!==null&&!integer(user.act_at))
      issue(issues,'$.user.act_at','NATIVE_INT64_EXACT_INTEGER_REQUIRED');
    if(object(user.tutorial)){
      for(const name of ['contents_lv','progress']){
        if(own(user.tutorial,name)&&user.tutorial[name]!==null&&
           (!integer(user.tutorial[name])||user.tutorial[name]<0||user.tutorial[name]>4294967295))
          issue(issues,'$.user.tutorial.'+name,'NATIVE_UINT32_REQUIRED');
      }
    }
  }
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
  function nativeMetadata(value){
    if(typeof value!=='string')return false;
    let bytes=0;
    for(let i=0;i<value.length;i++){
      const c=value.charCodeAt(i);
      if(c===0)return false;
      if(c<0x80)bytes++;
      else if(c<0x800)bytes+=2;
      else if(c>=0xd800&&c<=0xdbff){
        const next=value.charCodeAt(++i);
        if(!(next>=0xdc00&&next<=0xdfff))return false;
        bytes+=4;
      }else if(c>=0xdc00&&c<=0xdfff)return false;
      else bytes+=3;
      // This is the Core's own storage budget, not a claimed game UI limit.
      if(bytes>4096)return false;
    }
    return true;
  }
  const teamReferenceKeys=Object.freeze(['referenced_sugoroku_map_id','referenced_z_battle_stage_id','referenced_card_ids']);
  const teamContextKeys=Object.freeze(['sugoroku_map_id','z_battle_stage_id','origin_battle_id']);
  const signed32=x=>integer(x)&&x>=-2147483648&&x<=2147483647;
  const unsigned32=x=>integer(x)&&x>=0&&x<=4294967295;
  function nativeTeamReferences(value){
    return object(value)&&Object.keys(value).length===3&&teamReferenceKeys.every(key=>own(value,key))&&
      signed32(value.referenced_sugoroku_map_id)&&signed32(value.referenced_z_battle_stage_id)&&
      Array.isArray(value.referenced_card_ids)&&value.referenced_card_ids.length<=1024&&value.referenced_card_ids.every(signed32);
  }
  function nativeTeamContext(value){
    return object(value)&&Object.keys(value).every(key=>teamContextKeys.includes(key)&&unsigned32(value[key]));
  }
  function teams(snapshot,provided,issues){
    if(!Array.isArray(snapshot.teams)){
      issue(issues,'$.teams','CANONICAL_TEAMS_UNAVAILABLE');return undefined;
    }
    const persisted=snapshot.original_client_teams;
    if(!object(persisted)||persisted.schema!==1||!Array.isArray(persisted.bindings)||!object(persisted.selection)){
      issue(issues,'$.teams','NATIVE_TEAM_BINDING_REQUIRED');return undefined;
    }
    if(provided!==undefined&&!object(provided))throw Error('INVALID_NATIVE_TEAM_POLICY');
    if(own(persisted,'advisory_context')&&!nativeTeamContext(persisted.advisory_context))throw Error('INVALID_NATIVE_TEAM_CONTEXT');
    const owned=new Set();
    for(const card of snapshot.cards){
      if(!object(card)||!integer(card.instance_id)||card.instance_id<=0||owned.has(card.instance_id))throw Error('INVALID_OWN_CARDS');
      owned.add(card.instance_id);
    }
    const canonical=new Map();
    for(const team of snapshot.teams){
      if(!object(team)||!integer(team.slot)||team.slot<0||team.slot>19||canonical.has(team.slot)||
         !Array.isArray(team.members)||team.members.length>6||
         team.members.some(id=>!integer(id)||id<=0||!owned.has(id))||new Set(team.members).size!==team.members.length)
        throw Error('INVALID_OWN_TEAMS');
      canonical.set(team.slot,team.members);
    }
    if(persisted.bindings.length!==canonical.size){
      issue(issues,'$.teams','NATIVE_TEAM_BINDING_REQUIRED');return undefined;
    }
    const nums=new Set(),slots=new Set(),rows=[];
    for(const binding of persisted.bindings){
      if(!object(binding)||!integer(binding.slot)||!canonical.has(binding.slot)||slots.has(binding.slot)||
         !integer(binding.native_num)||binding.native_num<1||binding.native_num>2147483647||nums.has(binding.native_num)||
         !nativeMetadata(binding.name)||!own(binding,'team_bgm_filename')||
         !(binding.team_bgm_filename===null||nativeMetadata(binding.team_bgm_filename))||
         !Array.isArray(binding.card_slots)||binding.card_slots.length!==6)
        throw Error('INVALID_NATIVE_TEAM_BINDING');
      const members=[];
      for(const id of binding.card_slots){
        if(!integer(id)||id<0||id!==0&&!owned.has(id))throw Error('NATIVE_TEAM_MEMBER_NOT_OWNED');
        if(id!==0)members.push(id);
      }
      if(new Set(members).size!==members.length||!equal(members,canonical.get(binding.slot)))throw Error('NATIVE_TEAM_LAYOUT_CONFLICT');
      slots.add(binding.slot);nums.add(binding.native_num);
      const row={num:binding.native_num,name:binding.name,user_card_ids:binding.card_slots.slice(),team_bgm_filename:binding.team_bgm_filename};
      if(binding.references===undefined||binding.references===null)issue(issues,'$.teams.user_card_teams','NATIVE_TEAM_REFERENCE_METADATA_REQUIRED');
      else {
        if(!nativeTeamReferences(binding.references))throw Error('INVALID_NATIVE_TEAM_REFERENCES');
        Object.assign(row,clone(binding.references));
      }
      rows.push(row);
    }
    rows.sort((a,b)=>a.num-b.num);
    const result=provided===undefined?{}:clone(provided);
    if(own(result,'user_card_teams')){
      const configured=result.user_card_teams;
      if(!Array.isArray(configured)||configured.length!==rows.length)throw Error('POLICY_OVERRIDES_OWNED_TEAMS');
      const sorted=configured.slice().sort((a,b)=>(object(a)?a.num:0)-(object(b)?b.num:0));
      for(let i=0;i<rows.length;i++){
        const a=sorted[i],b=rows[i];
        if(!object(a)||Object.keys(a).length!==Object.keys(b).length||Object.keys(b).some(key=>!equal(a[key],b[key])))
          throw Error('POLICY_OVERRIDES_OWNED_TEAMS');
      }
    }
    result.user_card_teams=rows;
    for(const key of Object.keys(persisted.selection)){
      if(key!=='selected_team_num'&&key!=='selected_kobetu_team_num')throw Error('INVALID_NATIVE_TEAM_SELECTION');
      const value=persisted.selection[key];
      if(!integer(value)||value<1||value>2147483647||!nums.has(value))throw Error('NATIVE_TEAM_SELECTION_NOT_OWNED');
      if(own(result,key)&&result[key]!==value)throw Error('POLICY_OVERRIDES_OWNED_TEAMS');
      result[key]=value;
    }
    for(const key of ['selected_team_num','selected_kobetu_team_num']){
      if(own(result,key)&&!own(persisted.selection,key))throw Error('POLICY_OVERRIDES_OWNED_TEAMS');
    }
    return result;
  }
  function currentTeamStructure(structure,response){
    const rows=object(response.teams)?response.teams.user_card_teams:undefined;
    if(!Array.isArray(rows)||!rows.some(row=>object(row)&&own(row,'referenced_card_ids')))return structure;
    const current=clone(structure);
    const team=current.properties&&current.properties.teams;
    const list=team&&team.properties&&team.properties.user_card_teams;
    if(list&&Array.isArray(list.items))for(const row of list.items){
      if(row.type==='object'&&object(row.properties))Object.assign(row.properties,{
        referenced_sugoroku_map_id:{type:'integer'},referenced_z_battle_stage_id:{type:'integer'},
        referenced_card_ids:{type:'array',items:[{type:'integer'}]}
      });
    }
    return current;
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
    checkNativeUserIntegers(user,issues);
    response.user=user;
    const projectedCards=cards(snapshot,response.cards,issues);
    if(projectedCards!==undefined)response.cards=projectedCards;
    const projectedTeams=teams(snapshot,response.teams,issues);
    if(projectedTeams!==undefined)response.teams=projectedTeams;
    if(admission.clean!==true&&snapshot.cards.some(row=>object(row)&&(row.created_definition||row.tournament_definition||row.official_upgrade)))
      issue(issues,'$.cards','NATIVE_PROJECTION_PENDING');
    const shape=validateObserved(currentTeamStructure(evidence.structure,response),response);issues.push(...shape.issues);
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
  function projectTeams(envelope,expected){
    if(!object(envelope)||!object(envelope.admission)||!object(envelope.player_snapshot)||!object(expected))throw Error('INVALID_NATIVE_SNAPSHOT');
    const admission=envelope.admission,snapshot=envelope.player_snapshot;
    for(const key of ['profile_id','content_id','save_scope_sha256']){
      if(typeof expected[key]!=='string'||admission[key]!==expected[key])throw Error('CANONICAL_PLAYER_SCOPE_CHANGED');
    }
    if(snapshot.profile_id!==expected.profile_id||snapshot.content_id!==expected.content_id||!Array.isArray(snapshot.cards))throw Error('CANONICAL_PLAYER_SCOPE_CHANGED');
    const issues=[],response=teams(snapshot,undefined,issues);
    if(response){
      if(!response.user_card_teams.length)issue(issues,'$.user_card_teams','ORIGINAL_EMPTY_TEAM_RUNTIME_UNVERIFIED');
      if(!own(response,'selected_team_num'))issue(issues,'$.selected_team_num','NATIVE_TEAM_SELECTION_REQUIRED');
      const used=new Set(response.user_card_teams.flatMap(row=>row.user_card_ids.filter(id=>id!==0)));
      if(admission.clean!==true&&snapshot.cards.some(card=>used.has(card.instance_id)&&
          (card.created_definition||card.tournament_definition||card.official_upgrade)))
        issue(issues,'$.user_card_teams','NATIVE_PROJECTION_PENDING');
    }
    return {
      schema:1,kind:'own-player-team-projection',profile_id:expected.profile_id,content_id:expected.content_id,
      save_scope_sha256:expected.save_scope_sha256,core_revision:snapshot.revision,response:response||null,issues,
      body_json:response&&issues.length===0?JSON.stringify(response):null,
      http_route_admitted:false,original_iphone_runtime_verified:false,captured_player_values_used:false
    };
  }
  function normalizeTeamUpdate(envelope,expected,body){
    // The native transport must supply an already decoded JSON object. This
    // does not decode a signed/compressed body or validate timewarp's lifecycle.
    const current=projectTeams(envelope,expected),snapshot=envelope.player_snapshot;
    if(!current.response)throw Error('NATIVE_TEAM_BINDING_REQUIRED');
    if(!snapshot.teams.length)throw Error('ORIGINAL_EMPTY_TEAM_RUNTIME_UNVERIFIED');
    if(!object(body))throw Error('INVALID_NATIVE_TEAM_REQUEST');
    const keys=new Set(['selected_team_num','selected_kobetu_team_num','user_card_teams','timewarp',...teamContextKeys]);
    if(Object.keys(body).some(key=>!keys.has(key)))throw Error('UNSUPPORTED_NATIVE_TEAM_FIELD');
    const bindings=new Map(snapshot.original_client_teams.bindings.map(row=>[row.native_num,row]));
    const owned=new Set(snapshot.cards.map(row=>row.instance_id)),seen=new Set();
    const mutation={teams:[]};
    const rows=own(body,'user_card_teams')?body.user_card_teams:[];
    if(!Array.isArray(rows)||rows.length>20)throw Error('INVALID_NATIVE_TEAM_REQUEST');
    for(const row of rows){
      if(!object(row)||Object.keys(row).length!==6||
         Object.keys(row).some(key=>!['num','name','user_card_ids',...teamReferenceKeys].includes(key))||
         !signed32(row.num)||row.num<1||seen.has(row.num)||!nativeMetadata(row.name)||
         !Array.isArray(row.user_card_ids)||row.user_card_ids.length!==6)throw Error('INVALID_NATIVE_TEAM_REQUEST');
      const binding=bindings.get(row.num);
      if(!binding||!own(binding,'team_bgm_filename')||
         !(binding.team_bgm_filename===null||nativeMetadata(binding.team_bgm_filename)))throw Error('NATIVE_TEAM_METADATA_REQUIRED');
      const members=[];
      for(const id of row.user_card_ids){
        if(!integer(id)||id<0||id!==0&&!owned.has(id))throw Error('NATIVE_TEAM_MEMBER_NOT_OWNED');
        if(id!==0)members.push(id);
      }
      if(new Set(members).size!==members.length)throw Error('DUPLICATE_NATIVE_TEAM_MEMBER');
      const references=Object.fromEntries(teamReferenceKeys.map(key=>[key,row[key]]));
      if(!nativeTeamReferences(references))throw Error('INVALID_NATIVE_TEAM_REFERENCES');
      seen.add(row.num);
      mutation.teams.push({native_num:row.num,name:row.name,team_bgm_filename:binding.team_bgm_filename,
        card_slots:row.user_card_ids.slice(),references:clone(references)});
    }
    for(const key of ['selected_team_num','selected_kobetu_team_num'])if(own(body,key)){
      if(!signed32(body[key])||body[key]<1||!bindings.has(body[key]))throw Error('NATIVE_TEAM_SELECTION_NOT_OWNED');
      mutation[key]=body[key];
    }
    for(const key of teamContextKeys)if(own(body,key)){
      if(!unsigned32(body[key]))throw Error('INVALID_NATIVE_TEAM_CONTEXT');
      if(!own(mutation,'advisory_context'))mutation.advisory_context={};
      mutation.advisory_context[key]=body[key];
    }
    const transport={};
    if(own(body,'timewarp')){
      if(!integer(body.timewarp))throw Error('NATIVE_TRANSPORT_INTEGER_PRECISION_REQUIRED');
      transport.timewarp=body.timewarp;
    }
    return {schema:1,kind:'own-player-team-update-normalization',profile_id:expected.profile_id,content_id:expected.content_id,
      save_scope_sha256:expected.save_scope_sha256,expected_revision:snapshot.revision,mutation,transport_metadata:transport,
      http_route_admitted:false,original_iphone_runtime_verified:false};
  }
  return Object.freeze({project,projectTeams,normalizeTeamUpdate,validateObserved});
});
