'use strict';
// One changed-flow scenario only. Existing SQL allocation/ownership/replay
// receipts are reused. This executes the actual JS, not native Core or UI.
const fs=require('fs'),crypto=require('crypto'),assert=require('assert');
const api=require('../resources-projector'),copy=x=>JSON.parse(JSON.stringify(x));
const expected={profile_id:'synthetic-owner',content_id:'synthetic-master',save_scope_sha256:'ab'.repeat(32)};
const envelope={admission:{...expected,clean:true},player_snapshot:{profile_id:expected.profile_id,
  content_id:expected.content_id,revision:9,rank:1,wire_identity:{id:7,name:'Synthetic Player'},cards:[],teams:[],
  original_client_teams:{schema:1,bindings:[],selection:{},advisory_context:{}},
  original_client_tutorial:{schema:1,policy:'offline-new-player-skip-v1',progress:0,is_finished:true}}};
const initial=JSON.stringify(envelope);
assert.deepStrictEqual(JSON.parse(api.projectTeams(envelope,expected).body_json),{user_card_teams:[]});
assert.strictEqual(JSON.stringify(envelope),initial);
envelope.player_snapshot.cards=[{instance_id:11,created_definition:{synthetic:true}},{instance_id:12}];
const user=api.projectNewProfilePlayer(envelope,expected);
assert.deepStrictEqual(Object.keys(user.response),['user']);
assert.strictEqual(user.response.user.tutorial.is_finished,true);
assert.strictEqual(user.full_home_projection,false);
const row={num:23,name:'User chosen formation',user_card_ids:[11,0,12,0,0,0],
  referenced_sugoroku_map_id:0,referenced_z_battle_stage_id:0,referenced_card_ids:[]};
// Reference values are synthetic submitted fields, never fresh-account grants.
const body={selected_team_num:23,user_card_teams:[row]},before=JSON.stringify(envelope);
const result=api.normalizeTeamUpdate(envelope,expected,body),binding=result.mutation.teams[0];
assert.strictEqual(result.expected_revision,9);
assert.strictEqual(binding.team_bgm_filename,'');
assert.strictEqual(binding.name,row.name);
assert.deepStrictEqual(binding.card_slots,row.user_card_ids);
assert.strictEqual(result.mutation.selected_team_num,23);
assert.strictEqual(JSON.stringify(envelope),before);
// Simulate only the postcommit snapshot shape. Actual new-row SQL allocation
// and native transaction/revision guards are unchanged and reuse prior evidence.
const saved=copy(envelope);saved.player_snapshot.revision=10;
saved.player_snapshot.teams=[{slot:0,members:[11,12]}];
saved.player_snapshot.original_client_teams.bindings=[{slot:0,...binding,name:binding.name}];
saved.player_snapshot.original_client_teams.selection={selected_team_num:23};
const projected=api.projectTeams(saved,expected);
assert(projected.body_json);
assert.deepStrictEqual(projected.response.user_card_teams[0].user_card_ids,row.user_card_ids);
assert.strictEqual(api.projectNewProfilePlayer(saved,expected).response.user.id,7);
const noSelection=copy(body);delete noSelection.selected_team_num;
assert(!Object.hasOwn(api.normalizeTeamUpdate(envelope,expected,noSelection).mutation,'selected_team_num'));
for(const bgm of ['existing-custom-music',null]){
  saved.player_snapshot.original_client_teams.bindings[0].team_bgm_filename=bgm;
  assert.strictEqual(api.normalizeTeamUpdate(saved,expected,body).mutation.teams[0].team_bgm_filename,bgm);
}
const rejects=(input,code,source=envelope)=>assert.throws(()=>api.normalizeTeamUpdate(source,expected,input),e=>e.message===code);
const foreign=copy(body);foreign.user_card_teams[0].user_card_ids[2]=99;rejects(foreign,'NATIVE_TEAM_MEMBER_NOT_OWNED');
const duplicate=copy(body);duplicate.user_card_teams[0].user_card_ids[2]=11;rejects(duplicate,'DUPLICATE_NATIVE_TEAM_MEMBER');
rejects({...body,selected_team_num:24},'NATIVE_TEAM_SELECTION_NOT_OWNED');
const extra=copy(body);extra.user_card_teams[0].team_bgm_filename='forged';rejects(extra,'INVALID_NATIVE_TEAM_REQUEST');
const dirty=copy(envelope);dirty.admission.clean=false;rejects(body,'NATIVE_PROJECTION_PENDING',dirty);
const old=copy(envelope);old.player_snapshot.original_client_tutorial={schema:1,policy:'original-tutorial-entry-v1',progress:2,is_finished:false};
assert.throws(()=>api.projectInitialTutorialPlayer(old,expected),e=>e.message==='INITIAL_TUTORIAL_EXISTING_COLLECTION_REQUIRES_FULL_PROJECTION');
assert.strictEqual(JSON.stringify(envelope),before);
const receipt={kind:'explicit-user-submitted-first-formation-and-user-continuity',runs:1,
  empty_actual_team_list_emitted_without_selection:true,new_native_row_creates_revision_bound_mutation:true,
  new_formation_no_custom_music_policy:'empty string; own app policy only',existing_saved_bgm_preserved:true,
  user_submitted_number_name_references_and_six_positions_preserved:true,selection_only_if_actually_submitted:true,
  foreign_duplicate_dirty_or_extra_fields_rejected:true,skip_policy_user_remains_available_after_creation:true,
  collection_models_not_emitted_or_synchronized_by_user_only_dto:true,
  prior_core_new_row_allocation_and_ownership_sql_evidence_reused:'core-team-projection-evidence.json',
  core_c_or_objc_execution:false,original_client_empty_ui_or_encoded_post_execution:false,app_builds:0,
  module_sha256:crypto.createHash('sha256').update(fs.readFileSync(require.resolve('../resources-projector'))).digest('hex')};
fs.writeFileSync(__dirname+'/first-formation-evidence.json',JSON.stringify(receipt,null,2)+'\n');
process.stdout.write('First-formation and User continuity targeted scenario passed; native UI/codec/Core execution pending.\n');
