/* Offline bootstrap auth candidate for the unified Duo host.
 * Reader-relative fields only: GET /auth/nonce reads auth_transaction_id and
 * nonce as strings; POST /auth/sign_in reads access_token as a string and
 * expires_in as a signed32 second count added to native time(NULL).
 * The current client's ordinary, non-zstd JSON response feeds its document
 * root directly to these readers. issuePlainJSON adds encoded body candidates
 * for that path; it does not admit a route or claim a complete login response.
 * This module does not call an account service or accept a secret/captcha field. Token text is supplied
 * by the local issuer. No source or server key is embedded here. */
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  else Object.defineProperty(root,'ODOfflineBootstrapAuth',{value:api,writable:false});
})(typeof globalThis==='object'?globalThis:this,function(){
  'use strict';
  const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
  const object=x=>x!==null&&typeof x==='object'&&!Array.isArray(x);
  const SIGNED32_MIN=-2147483648,SIGNED32_MAX=2147483647,LOCAL_TOKEN_MAX=128;
  const ALLOWED=['auth_transaction_id','nonce','access_token','expires_in','native_time'];
  function localString(value){
    return typeof value==='string'&&value.length>0&&value.length<=LOCAL_TOKEN_MAX;
  }
  function signed32(value){
    return Number.isSafeInteger(value)&&value>=SIGNED32_MIN&&value<=SIGNED32_MAX;
  }
  function issue(local){
    if(!object(local))throw Error('INVALID_OFFLINE_AUTH');
    if(own(local,'secret')||own(local,'captcha_session_key'))throw Error('SECRET_OR_CAPTCHA_REJECTED');
    for(const key of Object.keys(local))if(!ALLOWED.includes(key))throw Error('UNVERIFIED_AUTH_FIELD');
    if(!localString(local.auth_transaction_id)||!localString(local.nonce)||!localString(local.access_token))
      throw Error('INVALID_OFFLINE_AUTH_STRING');
    if(typeof local.expires_in==='string')throw Error('STRING_EXPIRY_UNSUPPORTED');
    if(!signed32(local.expires_in))throw Error('INVALID_SIGNED32_TTL');
    if(!Number.isSafeInteger(local.native_time)||local.native_time<0||local.native_time>SIGNED32_MAX)
      throw Error('INVALID_NATIVE_TIME');
    const expiry=local.native_time+local.expires_in;
    if(expiry<SIGNED32_MIN||expiry>SIGNED32_MAX)throw Error('SIGNED32_EXPIRY_OVERFLOW');
    return {
      schema:1,
      kind:'offline-bootstrap-auth-reader-relative-candidate',
      routes:{
        nonce:{method:'GET',path:'/auth/nonce'},
        sign_in:{method:'POST',path:'/auth/sign_in'}
      },
      reader_relative:{
        nonce:{auth_transaction_id:local.auth_transaction_id,nonce:local.nonce},
        sign_in:{access_token:local.access_token,expires_in:local.expires_in}
      },
      expiry_unix:expiry,
      expiry_semantics:'native time(NULL) plus signed32 expires_in',
      local_token_max:LOCAL_TOKEN_MAX,
      field_value_format_verified:false,
      field_requiredness_verified:false,
      wire_body_envelope_verified:false,
      wire_wrapper:null,
      http_body_json:null,
      http_route_admitted:false,
      secret_or_captcha_admitted:false,
      remote_account_called:false,
      source_or_server_key_shipped:false
    };
  }
  function issuePlainJSON(local){
    const issued=issue(local);
    return Object.assign({},issued,{
      kind:'offline-bootstrap-auth-plain-json-candidate',
      plain_json_body_candidates:{
        nonce:JSON.stringify(issued.reader_relative.nonce),
        sign_in:JSON.stringify(issued.reader_relative.sign_in)
      },
      response_content_type:'application/json',
      parsed_payload_root_verified:true,
      plain_json_body_envelope_verified:true,
      full_success_response_verified:false,
      original_iphone_runtime_verified:false
    });
  }
  return Object.freeze({issue,issuePlainJSON,SIGNED32_MIN,SIGNED32_MAX,LOCAL_TOKEN_MAX});
});
