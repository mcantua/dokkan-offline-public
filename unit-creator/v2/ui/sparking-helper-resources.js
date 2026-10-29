(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory(require('./vendor/luaparse/luaparse.js'),require('./sparking-script-resources.js'),async bytes=>require('node:crypto').createHash('sha256').update(bytes).digest('hex'));else root.ForgeSparkingHelperResources=factory(root.luaparse,root.ForgeSparkingScriptResources,async bytes=>{if(!root.crypto?.subtle)throw Error('Source fingerprint verification is unavailable.');return Array.from(new Uint8Array(await root.crypto.subtle.digest('SHA-256',bytes)),n=>n.toString(16).padStart(2,'0')).join('');});})(typeof globalThis==='object'?globalThis:this,function(parser,Inventory,digest){
 'use strict';
 const COMMON_SHA256='21cea0d7a6115ac6dbe0a39235f3c0d2d2ee93de4e9c98094e72cbaa9c57aa67',NAMES=Object.freeze(['showCardCutin','showCardCutinEx','showCardCutinOffset']),known=new Set(NAMES),MAX_BYTES=2*1024*1024,MAX_VISITS=300000,MAX_CALLS=10000,MAX_VALUES=64;
 const scope='Static source-verified common cut-in helper effect references only; conservative branch union, no Lua execution, preview, audio-asset download, full dependency closure or gameplay proof.';
 const empty=()=>({values:new Set(),unknown:true}),numeric=n=>({values:new Set([n]),unknown:false});
 const merge=values=>{const result={values:new Set(),unknown:false};for(const value of values){result.unknown=result.unknown||value.unknown;for(const n of value.values){if(result.values.size<MAX_VALUES)result.values.add(n);else result.unknown=true;}}return result;};
 const options={luaVersion:'5.1',locations:true,ranges:true,comments:false,encodingMode:'none'};
 function bytes(text,label){if(typeof text!=='string'||text.length>MAX_BYTES)throw Error('Choose '+label+' Lua source up to2MiB.');const result=new TextEncoder().encode(text);if(result.length>MAX_BYTES)throw Error('Choose '+label+' Lua source up to2MiB.');return result;}
 function collectCalls(ast,note){
  const calls=[],guards=new Set([...NAMES,'entryEffect','entryEffectLife','entryEffectUnpausable','setupMovie','playSe']),initial=new Map(NAMES.map(name=>[name,{trusted:true,value:empty()}]));let visited=0;
  const clone=env=>env.map(map=>new Map(map)),lookup=(env,name)=>{for(let i=env.length-1;i>=0;i--)if(env[i].has(name))return {binding:env[i].get(name),index:i};return {binding:null,index:-1};};
  function value(node,env,depth=0){
   if(!node||depth>128)return empty();if(node.type==='NumericLiteral')return Number.isFinite(node.value)?numeric(node.value):empty();if(node.type==='Identifier')return lookup(env,node.name).binding?.value||empty();
   if(node.type==='UnaryExpression'&&node.operator==='-'){const a=value(node.argument,env,depth+1);return {values:new Set(Array.from(a.values,n=>-n)),unknown:a.unknown};}
   if(node.type==='BinaryExpression'){
    const a=value(node.left,env,depth+1),b=value(node.right,env,depth+1),out={values:new Set(),unknown:a.unknown||b.unknown};
    for(const x of a.values)for(const y of b.values){let n;switch(node.operator){case '+':n=x+y;break;case '-':n=x-y;break;case '*':n=x*y;break;case '/':n=x/y;break;case '%':n=x-Math.floor(x/y)*y;break;case '^':n=Math.pow(x,y);break;default:out.unknown=true;continue;}if(Number.isFinite(n)&&out.values.size<MAX_VALUES)out.values.add(n);else out.unknown=true;}return out;
   }return empty();
  }
  function assign(env,name,v,local){const previous=lookup(env,name),index=local?env.length-1:previous.index<0?0:previous.index;env[index].set(name,{trusted:false,value:v});}
  function invalidate(env,name){if(name)env[0].set(name,{trusted:false,value:empty()});else for(const key of guards)env[0].set(key,{trusted:false,value:empty()});}
  function combine(env,branches){for(let i=0;i<env.length;i++){const keys=new Set(branches.flatMap(branch=>Array.from(branch[i].keys())));for(const key of keys){const bindings=branches.map(branch=>branch[i].get(key));env[i].set(key,{trusted:bindings.every(binding=>binding?.trusted===true),value:merge(bindings.map(binding=>binding?.value||empty()))});}}}
  function checkArguments(node,env,name){
   if(node.type!=='CallExpression'){note(node,name,'This helper requires ordinary numeric Lua arguments.');return false;}
   const args=node.arguments||[],maximum=name==='showCardCutinOffset'?3:2,minimum=name==='showCardCutinOffset'?3:1;if(args.length<minimum||args.length>maximum){note(node,name,'This helper has an unsupported argument count.');return false;}
   let valid=true;for(let i=0;i<args.length;i++){
    const arg=args[i];if(i===1&&['NilLiteral','BooleanLiteral'].includes(arg.type))continue;
    if(['StringLiteral','TableConstructorExpression','FunctionDeclaration','BooleanLiteral','NilLiteral'].includes(arg.type)){note(node,name,'A helper timing or placement argument is not numeric.');valid=false;continue;}
    const result=value(arg,env),limit=i===1?2147483647:1000000;
    if(Array.from(result.values).some(n=>!Number.isFinite(n)||Math.abs(n)>limit||(i===1&&!Number.isInteger(n)))){note(node,name,'A helper argument exceeds the bounded numeric inventory range.');valid=false;}
    if(result.unknown||!result.values.size)note(node,name,'A helper argument depends on a dynamic expression; only source-independent effect IDs are covered.');
   }return valid;
  }
  function walk(node,env,dynamic=false,depth=0){
   if(!node||typeof node!=='object')return;if(depth>512||++visited>MAX_VISITS)throw Error('Helper inventory exceeds its safe complexity limit.');
   if(node.type==='Identifier'&&node.name==='_G'&&lookup(env,'_G').index<1){invalidate(env);note(node,'_G','The global environment is used indirectly; common helper bindings are not assumed.');return;}
   if(node.type==='Identifier'&&known.has(node.name)&&lookup(env,node.name).binding?.trusted){note(node,node.name,'The common helper is used as a value or alias; indirect invocations were not expanded.');return;}
   if(node.type==='FunctionDeclaration'){
    const inner=clone(env);inner.push(new Map());for(const parameter of node.parameters||[])if(parameter.type==='Identifier')inner[inner.length-1].set(parameter.name,{trusted:false,value:empty()});body(node.body,inner,true);
    // An unexpanded function may change global bindings when later invoked.
    for(const key of guards)if(inner[0].has(key)&&inner[0].get(key)!==env[0].get(key))invalidate(env,key);
    return;
   }
   if(['CallExpression','StringCallExpression','TableCallExpression'].includes(node.type)){
    const name=node.base?.type==='Identifier'?node.base.name:null;
    if(known.has(name)){
     const found=lookup(env,name);
     if(!found.binding?.trusted||found.index!==0)note(node,name,'The helper name is shadowed or may have been redefined; its common resources were not assumed.');
     else if(dynamic)note(node,name,'The helper occurs inside an unexpanded function or loop; its invocation is not established.');
     else if(checkArguments(node,env,name)){
      const changed=Array.from(guards).filter(key=>!known.has(key)&&lookup([env[0]],key).binding);
      if(changed.length)note(node,name,'A native command used by the common helper may have been redefined; its resources were not assumed.');
      else if(calls.length<MAX_CALLS)calls.push({name,node});else throw Error('Too many cut-in helper calls to inventory safely.');
     }
    }
    if(name&&lookup(env,name).index<1&&['setfenv','getfenv','load','loadstring','dofile','require'].includes(name))invalidate(env);
    if(name==='rawset'&&lookup(env,name).index<1&&node.arguments?.[0]?.type==='Identifier'&&node.arguments[0].name==='_G'&&lookup(env,'_G').index<1)invalidate(env);
    if(node.base?.base?.type==='Identifier'&&node.base.base.name==='_G'&&lookup(env,'_G').index<1&&(node.base.type==='IndexExpression'||known.has(node.base.identifier?.name)))note(node,node.base.identifier?.name||'_G','An indirect global helper call is not expanded by this named-helper inventory.');
   }
   for(const[key,child]of Object.entries(node)){if(key==='loc'||key==='range'||(node.type==='MemberExpression'&&key==='identifier')||(node.type==='TableKeyString'&&key==='key')||(['CallExpression','StringCallExpression','TableCallExpression'].includes(node.type)&&key==='base'&&child?.type==='Identifier'))continue;if(Array.isArray(child)){for(const item of child)walk(item,env,dynamic,depth+1);}else if(child&&typeof child==='object')walk(child,env,dynamic,depth+1);}
  }
  function scoped(statements,env,dynamic){env.push(new Map());body(statements,env,dynamic);env.pop();}
  function body(statements,env,dynamic=false){for(const statement of statements||[]){
   if(++visited>MAX_VISITS)throw Error('Helper inventory exceeds its safe complexity limit.');
   if(statement.type==='LocalStatement'||statement.type==='AssignmentStatement'){
    for(const expression of statement.init||[])walk(expression,env,dynamic);const values=(statement.init||[]).map(expression=>value(expression,env));
    (statement.variables||[]).forEach((variable,index)=>{if(variable.type==='Identifier'){assign(env,variable.name,values[index]||empty(),statement.type==='LocalStatement');if(variable.name==='_G'&&statement.type!=='LocalStatement'&&lookup(env,'_G').index===0)invalidate(env);}else{walk(variable,env,dynamic);if(variable.base?.type==='Identifier'&&variable.base.name==='_G'&&lookup(env,'_G').index<1){if(variable.type==='MemberExpression'&&guards.has(variable.identifier?.name))invalidate(env,variable.identifier.name);else if(variable.type==='IndexExpression')invalidate(env);}}});
   }else if(statement.type==='IfStatement'){
    const branches=[];for(const clause of statement.clauses){walk(clause.condition,env,dynamic);const branch=clone(env);scoped(clause.body,branch,dynamic);branches.push(branch);}if(!statement.clauses.some(clause=>clause.type==='ElseClause'))branches.push(clone(env));combine(env,branches);
   }else if(statement.type==='DoStatement')scoped(statement.body,env,dynamic);
   else if(statement.type==='ForNumericStatement'){
    walk(statement.start,env,dynamic);walk(statement.end,env,dynamic);walk(statement.step,env,dynamic);const a=value(statement.start,env),b=value(statement.end,env),c=statement.step?value(statement.step,env):numeric(1),single=v=>!v.unknown&&v.values.size===1,start=Array.from(a.values)[0],end=Array.from(b.values)[0],step=Array.from(c.values)[0],count=step?Math.max(0,Math.floor((end-start)/step)+1):Infinity;
    if([a,b,c].every(single)&&Number.isSafeInteger(count)&&count<=64&&step!==0){for(let n=0;n<count;n++){env.push(new Map([[statement.variable.name,{trusted:false,value:numeric(start+n*step)}]]));body(statement.body,env,dynamic);env.pop();}}
    else{const before=clone(env);env.push(new Map([[statement.variable.name,{trusted:false,value:empty()}]]));body(statement.body,env,true);env.pop();combine(env,[before,env]);}
   }else if(['WhileStatement','RepeatStatement','ForGenericStatement'].includes(statement.type)){
    walk(statement.condition,env,dynamic);for(const iterator of statement.iterators||[])walk(iterator,env,dynamic);const before=clone(env);env.push(new Map((statement.variables||[]).map(variable=>[variable.name,{trusted:false,value:empty()}])));body(statement.body,env,true);env.pop();combine(env,[before,env]);
   }else if(statement.type==='FunctionDeclaration'){
    // local function names are already in scope inside their own body.
    if(statement.isLocal&&statement.identifier?.type==='Identifier')assign(env,statement.identifier.name,empty(),true);
    walk(statement,env,dynamic);if(!statement.isLocal&&statement.identifier?.type==='Identifier')assign(env,statement.identifier.name,empty(),false);else if(statement.identifier&&statement.identifier.type!=='Identifier')walk(statement.identifier,env,dynamic);
   }else walk(statement,env,dynamic);
  }}
  body(ast.body,[initial,new Map()]);return calls;
 }
 async function inventory(text,{commonText,commonSHA256}={}){
  const effectIds=new Set(),soundIds=new Set(),helpers=[],helperUses=[],unresolved=[],seen=new Set();let verifiedCommonSHA256=null;
  const note=(node,command,reason)=>{const line=node?.loc?.start?.line||0,column=node?.loc?.start?.column||0,key=JSON.stringify([command,line,column,reason]);if(!seen.has(key)&&unresolved.length<MAX_CALLS){seen.add(key);unresolved.push(unresolved.length===MAX_CALLS-1?{command:'inventory',line:0,column:0,reason:'Further helper diagnostics exceed the safe inventory limit.'}:{command,line,column,reason});}};
  const result=()=>({effectIds:Array.from(effectIds).sort((a,b)=>a-b),soundIds:Array.from(soundIds).sort((a,b)=>a-b),helpers,helperUses,unresolved,complete:unresolved.length===0,verifiedCommonSHA256,scope});
  let calls;try{bytes(text,'original');if(parser?.version!=='0.3.1'||!parser.parse||typeof Inventory?.inventory!=='function')throw Error('The pinned bundled Lua resource parser is unavailable.');calls=collectCalls(parser.parse(text,options),note);}catch(error){note(null,'inventory',String(error.message||error));return result();}
  if(!calls.length)return result();
  let common,commonAST;try{common=bytes(commonText,'common helper');if(commonSHA256!==COMMON_SHA256||await digest(common)!==COMMON_SHA256)throw Error('The common helper source is missing, changed or not the supported verified version.');commonAST=parser.parse(commonText,options);verifiedCommonSHA256=COMMON_SHA256;}catch(error){for(const call of calls)note(call.node,call.name,String(error.message||error));return result();}
  for(const name of Array.from(new Set(calls.map(call=>call.name)))){
   const selected=commonAST.body.filter(node=>node.type==='FunctionDeclaration'&&!node.isLocal&&node.identifier?.type==='Identifier'&&node.identifier.name===name);
   if(selected.length!==1){for(const call of calls.filter(call=>call.name===name))note(call.node,name,'The verified common source has no unique named helper declaration.');continue;}
   const declaration=selected[0],statements=declaration.body;if(!statements?.length){note(declaration,name,'The named helper has no resource-bearing body.');continue;}
   const start=statements[0].range?.[0],end=statements[statements.length-1].range?.[1];if(!Number.isInteger(start)||!Number.isInteger(end)||start<declaration.range[0]||end>declaration.range[1]||start>=end){note(declaration,name,'The named helper body range is invalid.');continue;}
   const selectedText=commonText.slice(start,end),details=Inventory.inventory(selectedText);for(const id of details.effectIds)effectIds.add(id);
   for(const issue of details.unresolved)note(declaration,name,'The selected helper has an unresolved effect reference: '+issue.reason);
   // Only literal native sound IDs are recorded. This does not collect audio assets.
   const scan=node=>{if(!node||typeof node!=='object')return;if(node.type==='CallExpression'&&node.base?.type==='Identifier'&&node.base.name==='playSe'){const id=node.arguments?.[1];if(id?.type==='NumericLiteral'&&Number.isSafeInteger(id.value)&&id.value>0&&id.value<=2147483647)soundIds.add(id.value);else note(node,name,'The selected helper has a dynamic sound reference; no sound asset coverage is implied.');}for(const[key,child]of Object.entries(node)){if(key==='loc'||key==='range')continue;if(Array.isArray(child)){for(const item of child)scan(item);}else if(child&&typeof child==='object')scan(child);}};for(const statement of statements)scan(statement);
   helpers.push(name);for(const call of calls.filter(call=>call.name===name))helperUses.push({name,command:name,line:call.node.loc.start.line,column:call.node.loc.start.column,commonFunctionRange:declaration.range.slice(),effectIds:details.effectIds.slice()});
  }return result();
 }
 return {inventory,COMMON_SHA256,helperNames:NAMES};
});
