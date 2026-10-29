'use strict';
// One integrated scenario, fed by the combined Core SQL migration scenario.
// It verifies the actual persisted opaque key and six-position layout across
// the existing resource projector. It does not claim game/native execution.
const fs=require('fs'),crypto=require('crypto');
const projector=require('../resources-projector');
const fixture=JSON.parse(fs.readFileSync(0,'utf8'));
const copy=x=>JSON.parse(JSON.stringify(x));
const assert=(value,code)=>{if(!value)throw Error(code);};
const fails=(fn,code)=>{try{fn();}catch(error){if(error.message===code)return;throw error;}throw Error('Expected '+code);};
const record=fixture.original_client_teams;
assert(record&&record.bindings.length>0,'Persisted SQL binding fixture required');
const bound=record.bindings[0];
assert(bound.card_slots.length===6&&bound.card_slots.includes(0),'Actual gapped SQL layout required');
const members=bound.card_slots.filter(id=>id!==0);
const cards=[...new Set(record.bindings.flatMap(row=>row.card_slots.filter(id=>id!==0)))].map((id,i)=>({instance_id:id,master_id:100+i,sa_level:1,experience:0}));
const expected={profile_id:'synthetic-owner',content_id:'synthetic-master',save_scope_sha256:'ab'.repeat(32)};
const snapshot={profile_id:expected.profile_id,content_id:expected.content_id,revision:fixture.revision||1,rank:1,rank_experience:0,stamina:1,stamina_max:1,inventory:[],cards,teams:fixture.teams,original_client_teams:record};
const envelope={admission:Object.assign({clean:true},expected),player_snapshot:snapshot,wire_identity:{id:7,name:'Synthetic Player'}};
const sections={cards:cards.map(card=>({id:card.instance_id,card_id:card.master_id,skill_lv:card.sa_level,exp:card.experience}))};
// Shape evidence remains separately guarded in production. This scenario
// checks persisted team/ownership mapping, without admitting a partial body.
const evidence={all_scalar_values_removed:true,player_state_adopted:false,structure:{type:'object',properties:{}}};
const project=(env=envelope,policy=sections)=>projector.project(evidence,env,expected,policy);
const before=JSON.stringify(fixture),result=project();
const row=result.response.teams.user_card_teams.find(row=>row.num===bound.native_num);
assert(row&&JSON.stringify(row.user_card_ids)===JSON.stringify(bound.card_slots),'Gapped formation changed');
assert(row.name===bound.name&&row.team_bgm_filename===bound.team_bgm_filename,'Persisted metadata changed');
assert(!result.http_route_admitted&&!result.original_iphone_runtime_verified&&result.body_json===null,'Partial scenario admitted as game response');
assert(JSON.stringify(fixture)===before,'Input SQL snapshot mutated');
const missing=copy(envelope);delete missing.player_snapshot.original_client_teams;
assert(project(missing).issues.some(issue=>issue.code==='NATIVE_TEAM_BINDING_REQUIRED'),'Missing binding invented');
const stale=copy(envelope);stale.player_snapshot.teams.find(team=>team.slot===bound.slot).members=members.slice().reverse();
if(members.length>1)fails(()=>project(stale),'NATIVE_TEAM_LAYOUT_CONFLICT');
const foreign=copy(envelope);foreign.player_snapshot.original_client_teams.bindings[0].card_slots[0]=Number.MAX_SAFE_INTEGER;
fails(()=>project(foreign),'NATIVE_TEAM_MEMBER_NOT_OWNED');
fails(()=>project(envelope,Object.assign({},sections,{teams:{selected_team_num:2147483647}})),'POLICY_OVERRIDES_OWNED_TEAMS');
const fresh=copy(envelope);fresh.player_snapshot.cards=[];fresh.player_snapshot.teams=[];fresh.player_snapshot.original_client_teams={schema:1,bindings:[],selection:{}};
const empty=project(fresh,{cards:[]}).response.teams;
assert(empty.user_card_teams.length===0&&!Object.prototype.hasOwnProperty.call(empty,'selected_team_num'),'Empty account received invented team/selection');
const output={kind:'actual-core-sql-team-snapshot-resource-projection',verification:'one combined synthetic SQL-to-projector scenario; no C/native compile or gameplay',opaque_native_key_preserved:true,exact_six_positions_and_metadata_preserved:true,missing_binding_and_stale_layout_rejected:true,unowned_member_and_policy_override_rejected:true,fresh_account_received_no_team_or_selection:true,http_route_admitted:false,native_runtime_execution_verified:false,module_sha256:crypto.createHash('sha256').update(fs.readFileSync(require.resolve('../resources-projector'))).digest('hex'),persisted_sql_record_sha256:crypto.createHash('sha256').update(JSON.stringify(record)).digest('hex')};
fs.writeFileSync(__dirname+'/core-team-projection-evidence.json',JSON.stringify(output,null,2)+'\n');
console.log('Persisted original-team SQL-to-projector scenario passed.');
