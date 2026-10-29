'use strict';
// One changed-policy scenario. Prior migration/team/tutorial checks are reused.
const fs=require('fs'),crypto=require('crypto'),api=require('../resources-projector');
const assert=(ok,why)=>{if(!ok)throw Error(why);},copy=x=>JSON.parse(JSON.stringify(x));
const expected={profile_id:'synthetic-owner',content_id:'synthetic-master',save_scope_sha256:'ab'.repeat(32)};
const envelope={admission:Object.assign({clean:true},expected),player_snapshot:{profile_id:expected.profile_id,
  content_id:expected.content_id,revision:1,rank:1,wire_identity:{id:7,name:'Synthetic Player'},cards:[],teams:[],
  original_client_tutorial:{schema:1,policy:'offline-new-player-skip-v1',progress:0,is_finished:true}}};
const before=JSON.stringify(envelope),result=api.projectNewProfilePlayer(envelope,expected);
assert(JSON.stringify(result.response)===JSON.stringify({user:{id:7,name:'Synthetic Player',rank:1,tutorial:{progress:0,is_finished:true}}}),'Canonical skip tuple changed');
assert(JSON.stringify(envelope)===before,'Canonical profile changed');
assert(JSON.parse(result.body_json).user.tutorial.is_finished===true&&!result.full_home_projection&&!result.http_route_admitted&&!result.original_iphone_runtime_verified,'Wrong response boundary');
const old=copy(envelope);old.player_snapshot.original_client_tutorial={schema:1,policy:'original-tutorial-entry-v1',progress:2,is_finished:false};
for(const [value,code] of [
  [old,'CANONICAL_ORIGINAL_TUTORIAL_REQUIRED'],
  [Object.assign(copy(envelope),{admission:Object.assign({},envelope.admission,{clean:false})}),'NATIVE_PROJECTION_PENDING']]){
  let rejected=false;try{api.projectNewProfilePlayer(value,expected);}catch(e){assert(e.message===code,e.message);rejected=true;}assert(rejected,code);
}
assert(api.projectInitialTutorialPlayer(old,expected).response.user.tutorial.progress===2,'Existing unfinished checkpoint reset');
const collection=copy(envelope);collection.player_snapshot.cards=[{instance_id:1}];
assert(JSON.stringify(api.projectNewProfilePlayer(collection,expected).response)===JSON.stringify(result.response),'User-only DTO changed or emitted collection');
const receipt={kind:'new-profile-original-player-skip-intro-projection',runs:1,
  exact_persisted_new_policy_tuple_emitted:true,existing_unfinished_profile_not_rewritten:true,
  constructor_capacities_and_contents_not_invented:true,user_only_dto_does_not_replace_collection_models:true,
  earlier_core_team_and_tutorial_evidence_reused:true,http_route_admitted:false,
  complete_home_or_native_runtime_verified:false,
  module_sha256:crypto.createHash('sha256').update(fs.readFileSync(require.resolve('../resources-projector'))).digest('hex')};
fs.writeFileSync(__dirname+'/new-profile-skip-projection-evidence.json',JSON.stringify(receipt,null,2)+'\n');
process.stdout.write('New-profile skip-intro projection targeted scenario passed; no native/Home execution.\n');
