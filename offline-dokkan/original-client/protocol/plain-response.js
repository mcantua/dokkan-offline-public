/* Plain JSON response encoding for proved original WebAPI consumers only.
 * Endpoint DTO validation, routing and native owner admission belong to callers.
 * Root `sign` selects the original encoded path even when its value is null.
 */
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  else Object.defineProperty(root,'ODOriginalPlainResponse',{value:api,writable:false});
})(typeof globalThis==='object'?globalThis:this,function(){
  'use strict';
  const own=(value,key)=>Object.prototype.hasOwnProperty.call(value,key);
  const object=value=>value!==null&&typeof value==='object'&&!Array.isArray(value);
  function encode(value){
    if(!object(value)||own(value,'sign'))throw Error('PLAIN_RESPONSE_ROOT_REJECTED');
    let body,encoded;
    try{
      body=JSON.stringify(value);
      encoded=JSON.parse(body);
    }catch(_){throw Error('PLAIN_RESPONSE_JSON_REJECTED');}
    // Validate the serialized root too: toJSON/getters may change the input.
    if(!object(encoded)||own(encoded,'sign'))throw Error('PLAIN_RESPONSE_ROOT_REJECTED');
    return Object.freeze({status_code:200,content_type:'application/json',body_json:body,
      dto_validated:false,http_route_admitted:false,original_iphone_runtime_verified:false});
  }
  return Object.freeze({encode});
});
