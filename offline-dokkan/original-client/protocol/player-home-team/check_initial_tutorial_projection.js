'use strict';
// One focused new-mode scenario. Existing Core13/team checks are not rerun.
const fs=require('fs'),crypto=require('crypto'),api=require('../resources-projector');
const assert=(ok,why)=>{if(!ok)throw Error(why);},copy=x=>JSON.parse(JSON.stringify(x));
const expected={profile_id:'synthetic-owner',content_id:'synthetic-master',save_scope_sha256:'ab'.repeat(32)};
const envelope={admission:Object.assign({clean:true},expected),player_snapshot:{profile_id:expected.profile_id,
  content_id:expected.content_id,revision:1,rank:1,wire_identity:{id:7,name:'Synthetic Player'},cards:[],teams:[],
  original_client_tutorial:{schema:1,policy:'original-tutorial-entry-v1',progress:0,is_finished:false}}};
const before=JSON.stringify(envelope),result=api.projectInitialTutorialPlayer(envelope,expected);
assert(JSON.stringify(result.response)===JSON.stringify({user:{id:7,name:'Synthetic Player',rank:1,tutorial:{progress:0,is_finished:false}}}),'Initial DTO changed');
assert(JSON.stringify(JSON.parse(result.body_json))===JSON.stringify(result.response),'Candidate serialization changed');
assert(!result.full_home_projection&&!result.http_route_admitted&&!result.original_iphone_runtime_verified,'Candidate admitted full home or runtime');
assert(JSON.stringify(envelope)===before,'Canonical state mutated');
const resumed=copy(envelope);resumed.player_snapshot.original_client_tutorial.progress=2;
assert(api.projectInitialTutorialPlayer(resumed,expected).response.user.tutorial.progress===2,'Persisted checkpoint reset');
for(const [change,code] of [
  [e=>{e.player_snapshot.rank=0;},'CANONICAL_POSITIVE_RANK_REQUIRED'],
  [e=>{e.player_snapshot.original_client_tutorial=null;},'CANONICAL_ORIGINAL_TUTORIAL_REQUIRED'],
  [e=>{e.player_snapshot.original_client_tutorial.is_finished=true;},'CANONICAL_ORIGINAL_TUTORIAL_REQUIRED'],
  [e=>{e.player_snapshot.cards=[{instance_id:1}];},'INITIAL_TUTORIAL_EXISTING_COLLECTION_REQUIRES_FULL_PROJECTION'],
  [e=>{e.admission.save_scope_sha256='cd'.repeat(32);},'CANONICAL_PLAYER_SCOPE_CHANGED'],
  [e=>{e.admission.clean=false;},'NATIVE_PROJECTION_PENDING']]){
  const e=copy(envelope);change(e);let caught=false;
  try{api.projectInitialTutorialPlayer(e,expected);}catch(error){assert(error.message===code,error.message);caught=true;}
  assert(caught,'Expected '+code);
}
const receipt={kind:'source-specific-initial-original-tutorial-user-projection',runs:1,
  canonical_identity_positive_rank_and_tutorial_preserved:true,unknown_capacities_and_contents_lv_omitted:true,
  positive_persisted_checkpoint_not_reset:true,existing_collection_or_missing_tutorial_rejected:true,
  stale_scope_or_dirty_projection_rejected:true,prior_team_and_numeric_evidence_reused:true,
  http_route_admitted:false,native_runtime_or_objc_execution_verified:false,
  module_sha256:crypto.createHash('sha256').update(fs.readFileSync(require.resolve('../resources-projector'))).digest('hex')};
fs.writeFileSync(__dirname+'/initial-tutorial-projection-evidence.json',JSON.stringify(receipt,null,2)+'\n');
process.stdout.write('Initial tutorial projection targeted scenario passed; no native execution or HTTP admission.\n');
