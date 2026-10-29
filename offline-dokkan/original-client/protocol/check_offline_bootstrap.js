'use strict';
const crypto=require('crypto');
const fs=require('fs');
const path=require('path');
const auth=require('./bootstrap-auth');
const fresh=require('./fresh-state-policy');
const projector=require('./resources-projector');

const failures=[];
let passed=0;
function check(name,fn){
  try{fn();passed++;}catch(error){failures.push(name+': '+(error&&error.message?error.message:String(error)));}
}
function throws(fn,code){
  try{fn();}catch(error){if(error&&error.message===code)return;throw Error('expected '+code+' got '+(error&&error.message));}
  throw Error('expected '+code);
}

const local={
  auth_transaction_id:'local-transaction',
  nonce:'local-nonce',
  access_token:'local-token',
  expires_in:-30,
  native_time:100
};
check('reader-relative candidate',()=>{
  const issued=auth.issue(local);
  if(issued.expiry_unix!==70)throw Error('expiry');
  if(issued.http_body_json!==null||issued.http_route_admitted!==false||issued.wire_body_envelope_verified!==false)throw Error('admission');
  if(issued.wire_wrapper!==null||Object.prototype.hasOwnProperty.call(issued,'data'))throw Error('wrapper');
  const nonce=issued.reader_relative.nonce,sign=issued.reader_relative.sign_in;
  if(Object.keys(nonce).join()!=='auth_transaction_id,nonce')throw Error('nonce fields');
  if(Object.keys(sign).join()!=='access_token,expires_in')throw Error('token fields');
  if(sign.expires_in!==-30||typeof sign.expires_in==='string')throw Error('ttl shape');
  if(issued.secret_or_captcha_admitted||issued.remote_account_called||issued.source_or_server_key_shipped)throw Error('privacy');
  if(issued.routes.nonce.method!=='GET'||issued.routes.nonce.path!=='/auth/nonce')throw Error('nonce route');
  if(issued.routes.sign_in.method!=='POST'||issued.routes.sign_in.path!=='/auth/sign_in')throw Error('sign-in route');
});
check('string expiry rejected',()=>throws(()=>auth.issue(Object.assign({},local,{expires_in:'3600'})),'STRING_EXPIRY_UNSUPPORTED'));
check('secret rejected',()=>throws(()=>auth.issue(Object.assign({},local,{secret:'no'})),'SECRET_OR_CAPTCHA_REJECTED'));
check('captcha key rejected',()=>throws(()=>auth.issue(Object.assign({},local,{captcha_session_key:'no'})),'SECRET_OR_CAPTCHA_REJECTED'));
check('data wrapper rejected',()=>throws(()=>auth.issue(Object.assign({},local,{data:{}})),'UNVERIFIED_AUTH_FIELD'));
check('empty token rejected',()=>throws(()=>auth.issue(Object.assign({},local,{nonce:''})),'INVALID_OFFLINE_AUTH_STRING'));
check('fractional ttl rejected',()=>throws(()=>auth.issue(Object.assign({},local,{expires_in:1.5})),'INVALID_SIGNED32_TTL'));
check('signed32 overflow rejected',()=>throws(()=>auth.issue(Object.assign({},local,{native_time:2147483647,expires_in:1})),'SIGNED32_EXPIRY_OVERFLOW'));
check('negative native time rejected',()=>throws(()=>auth.issue(Object.assign({},local,{native_time:-1})),'INVALID_NATIVE_TIME'));

function snapshot(friends,act){
  return {
    profile_id:'local-player',content_id:'sparking:sha256:'+'ab'.repeat(32),revision:1,
    stamina:act,stamina_max:act,rank:1,rank_experience:0,inventory:[],cards:[],
    source_rank:{rank:1,exp_total:0,act_max:act,friends_capacity:friends}
  };
}
check('fresh policy omits sentinels',()=>{
  const policy=fresh.evaluate(snapshot(40,15),null);
  if(policy.http_body_json!==null||policy.http_route_admitted!==false)throw Error('admission');
  if(policy.pre_server_sentinels_adopted||policy.played_cache_values_adopted||policy.starting_stats_invented)throw Error('flags');
  if(Object.keys(policy.sections).length!==0)throw Error('sections');
  if(policy.admitted_source_facts.join()!=='rank,exp_total,act_max,friends_capacity')throw Error('facts');
  if(policy.unresolved.indexOf('tutorial.is_finished')<0||policy.unresolved.indexOf('card_capacity')<0)throw Error('unresolved');
  const text=JSON.stringify(policy);
  if(text.indexOf('is_finished')>=0&&text.indexOf('tutorial.is_finished')<0)throw Error('sentinel value');
  if(/"act_max":15|"friends_capacity":40|"act_max":20/.test(text))throw Error('echoed stats');
});
check('different master facts stay on the snapshot',()=>{
  const row=snapshot(40,15);
  const policy=fresh.evaluate(row,{user:{}});
  const evidence={
    all_scalar_values_removed:true,player_state_adopted:false,
    structure:{type:'object',properties:{
      user:{type:'object',properties:{
        rank:{type:'integer'},act:{type:'integer'},act_max:{type:'integer'},exp:{type:'integer'},
        friends_capacity:{type:'integer'},stone:{type:'integer'},zeni:{type:'integer'},
        id:{type:'integer'},name:{type:'string'}
      }},
      tutorial:{type:'object',properties:{
        progress:{type:'integer'},contents_lv:{type:'integer'},is_finished:{type:'boolean'}
      }}
    }}
  };
  const expected={profile_id:row.profile_id,content_id:row.content_id,save_scope_sha256:'cd'.repeat(32)};
  const envelope={admission:Object.assign({clean:true},expected),player_snapshot:row,wire_identity:{id:7,name:'Offline Player'}};
  const projected=projector.project(evidence,envelope,expected,policy.sections);
  if(projected.body_json!==null||projected.http_route_admitted!==false)throw Error('body admitted');
  if(projected.response.user.friends_capacity!==40||projected.response.user.act_max!==15||projected.response.user.rank!==1)throw Error('canonical facts');
  if(Object.prototype.hasOwnProperty.call(projected.response,'tutorial'))throw Error('tutorial filled');
  if(Object.prototype.hasOwnProperty.call(projected.response,'card_capacity'))throw Error('capacity filled');
  if(projected.response.user.is_finished===true)throw Error('sentinel adopted');
});
check('finished tutorial sentinel rejected',()=>throws(()=>fresh.evaluate(snapshot(50,20),{tutorial:{is_finished:true,progress:0,contents_lv:0}}),'PRE_SERVER_SENTINEL_REJECTED'));
check('zero card capacity rejected',()=>throws(()=>fresh.evaluate(snapshot(50,20),{card_capacity:0}),'PRE_SERVER_SENTINEL_REJECTED'));
check('nested finished flag rejected',()=>throws(()=>fresh.evaluate(snapshot(50,20),{user:{is_finished:true}}),'PRE_SERVER_SENTINEL_REJECTED'));
check('missing source rank rejected',()=>{
  const row=snapshot(50,20);delete row.source_rank;
  throws(()=>fresh.evaluate(row,null),'SOURCE_RANK_REQUIRED');
});
check('mismatched max ACT rejected',()=>{
  const row=snapshot(50,20);row.stamina_max=19;
  throws(()=>fresh.evaluate(row,null),'SOURCE_RANK_SCOPE_MISMATCH');
});
check('ranked profile is not reset',()=>{
  const row=snapshot(50,20);row.rank=2;row.source_rank.rank=2;
  throws(()=>fresh.evaluate(row,null),'FRESH_RANK_NOT_ESTABLISHED');
});

if(failures.length){
  process.stderr.write(failures.join('\n')+'\n');
  process.exit(1);
}
const dir=__dirname;
function sha(name){return crypto.createHash('sha256').update(fs.readFileSync(path.join(dir,name))).digest('hex');}
const evidence={
  schema:1,
  kind:'offline-bootstrap-auth-and-fresh-state-policy-check',
  assertions:passed,
  failures:0,
  auth_http_body_admitted:false,
  auth_route_admitted:false,
  wire_body_envelope_verified:false,
  string_expires_in_rejected:true,
  secret_and_captcha_rejected:true,
  guessed_data_wrapper_rejected:true,
  fresh_sentinels_adopted:false,
  tutorial_and_capacity_left_unresolved:true,
  starting_stats_invented:false,
  master_numbers_hardcoded:false,
  played_cache_values_used:false,
  original_iphone_runtime_verified:false,
  native_host_compiled:false,
  modules:{
    'bootstrap-auth.js':sha('bootstrap-auth.js'),
    'fresh-state-policy.js':sha('fresh-state-policy.js'),
    'resources-projector.js':sha('resources-projector.js')
  }
};
fs.writeFileSync(path.join(dir,'offline-bootstrap-evidence.json'),JSON.stringify(evidence,null,2)+'\n');
process.stdout.write('offline bootstrap auth and fresh-state policy: '+passed+' assertions passed\n');
