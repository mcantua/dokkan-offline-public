(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory(require('./vendor/luaparse/luaparse.js'));else root.ForgeSparkingScriptResources=factory(root.luaparse);})(typeof globalThis==='object'?globalThis:this,function(parser){
  'use strict';
  const APIs=new Set(['entryEffect','entryEffectLife','entryEffectUnpausable','setupMovie']),MAX_VALUES=64,MAX_SOURCE=2*1024*1024;
  const unknown=()=>({values:new Set(),unknown:true}),value=n=>({values:new Set([n]),unknown:false});
  function join(values){const set=new Set();let uncertain=false;for(const v of values){uncertain=uncertain||v.unknown;for(const n of v.values){if(set.size<MAX_VALUES)set.add(n);else uncertain=true;}}return {values:set,unknown:uncertain};}
  function inventory(text){
    if(typeof text!=='string'||text.length>MAX_SOURCE)throw Error('Choose an original Lua animation up to2MiB.');
    if(!parser?.parse)throw Error('The bundled Lua resource parser is unavailable.');
    const effects=new Set(),unresolved=[],uses=[],diagnostics=new Set();let visited=0;
    function note(node,command,reason){const line=node?.loc?.start?.line||0,column=node?.loc?.start?.column||0,key=[command,line,column,reason].join(':');if(!diagnostics.has(key)){diagnostics.add(key);unresolved.push({command,line,column,reason});}}
    const scope='Static recognized effect/movie references only; conservative branch union, no Lua execution, audio/helper/resource closure not implied.';
    let ast;try{ast=parser.parse(text,{luaVersion:'5.1',locations:true,comments:false,encodingMode:'none'});}catch(e){return {effectIds:[],effectUses:[],unresolved:[{command:'parse',line:e.line||0,column:e.column||0,reason:'The original Lua could not be parsed: '+e.message}],complete:false,scope};}
    const cloneEnv=env=>env.map(m=>new Map(m)),lookup=(env,name)=>{for(let i=env.length-1;i>=0;i--)if(env[i].has(name))return env[i].get(name);return unknown();};
    function assign(env,name,v,local){if(local){env[env.length-1].set(name,v);return;}for(let i=env.length-1;i>=0;i--)if(env[i].has(name)){env[i].set(name,v);return;}env[0].set(name,v);}
    function combine(env,branches){for(let i=0;i<env.length;i++){const keys=new Set(branches.flatMap(b=>Array.from(b[i].keys())));for(const k of keys)env[i].set(k,join(branches.map(b=>b[i].get(k)||unknown())));}}
    function expr(node,env,depth=0){
      if(!node||depth>256)return unknown();
      if(node.type==='NumericLiteral')return Number.isFinite(node.value)?value(node.value):unknown();
      if(node.type==='Identifier')return lookup(env,node.name);
      if(node.type==='UnaryExpression'&&node.operator==='-'){const a=expr(node.argument,env,depth+1);return {values:new Set(Array.from(a.values,n=>-n)),unknown:a.unknown};}
      if(node.type==='BinaryExpression'){
        const a=expr(node.left,env,depth+1),b=expr(node.right,env,depth+1),result={values:new Set(),unknown:a.unknown||b.unknown};
        for(const x of a.values)for(const y of b.values){let n;switch(node.operator){case '+':n=x+y;break;case '-':n=x-y;break;case '*':n=x*y;break;case '/':n=x/y;break;case '%':n=x-Math.floor(x/y)*y;break;case '^':n=Math.pow(x,y);break;default:result.unknown=true;continue;}if(!Number.isFinite(n)||result.values.size>=MAX_VALUES)result.unknown=true;else result.values.add(n);}return result;
      }
      return unknown();
    }
    function expressions(node,env,dynamic,depth=0){
      if(!node||typeof node!=='object')return;if(depth>512||++visited>300000)throw Error('The Lua resource inventory exceeds its safe complexity limit.');
      if(node.type==='FunctionDeclaration'){const inner=cloneEnv(env);inner.push(new Map());for(const p of node.parameters||[])if(p.type==='Identifier')inner[inner.length-1].set(p.name,unknown());body(node.body,inner,true);return;}
      if(node.type==='CallExpression'||node.type==='StringCallExpression'||node.type==='TableCallExpression'){
        const command=node.base?.type==='Identifier'?node.base.name:null;
        if(command&&(/^(?:showCardCutin(?:Ex|Offset)?|entryEffectTraining|entryEffectAwaken|entryKakimoji)$/.test(command)))note(node,command,'This resource-bearing helper needs its own source/context inventory; direct effect references do not cover it.');
        if(APIs.has(command)){
          const shadowed=env.some(m=>m.has(command)),id=shadowed?unknown():expr(node.arguments?.[1],env);
          for(const n of id.values){if(Number.isSafeInteger(n)&&n>0&&n<=2147483647){if(effects.size<5000)effects.add(n);else note(node,command,'The source has too many distinct effect references.');if(uses.length<20000)uses.push({effectId:n,command,line:node.loc.start.line,column:node.loc.start.column});else note(node,command,'The source has too many effect calls to inventory safely.');}else note(node,command,'The effect reference is not a supported positive native32-bit ID.');}
          if(shadowed||id.unknown||!id.values.size||dynamic)note(node,command,shadowed?'The native command name is shadowed by a Lua variable.':dynamic?'This reference is inside an unexpanded loop or function; its full invocation values are unknown.':'The effect reference depends on a dynamic or unsupported expression.');
        }
      }
      for(const [key,v] of Object.entries(node)){if(key==='loc'||key==='range')continue;if(Array.isArray(v)){for(const x of v)expressions(x,env,dynamic,depth+1);}else if(v&&typeof v==='object')expressions(v,env,dynamic,depth+1);}
    }
    function scoped(statements,env,dynamic){env.push(new Map());body(statements,env,dynamic);env.pop();}
    function body(statements,env,dynamic=false){for(const s of statements||[]){
      if(++visited>300000)throw Error('The Lua resource inventory exceeds its safe complexity limit.');
      if(s.type==='LocalStatement'||s.type==='AssignmentStatement'){
        for(const e of s.init||[])expressions(e,env,dynamic);const values=(s.init||[]).map(e=>expr(e,env));
        (s.variables||[]).forEach((v,i)=>{if(v.type==='Identifier')assign(env,v.name,values[i]||unknown(),s.type==='LocalStatement');else expressions(v,env,dynamic);});
      }else if(s.type==='IfStatement'){
        const branches=[];for(const c of s.clauses){expressions(c.condition,env,dynamic);const branch=cloneEnv(env);scoped(c.body,branch,dynamic);branches.push(branch);}if(!s.clauses.some(c=>c.type==='ElseClause'))branches.push(cloneEnv(env));combine(env,branches);
      }else if(s.type==='ForNumericStatement'){
        expressions(s.start,env,dynamic);expressions(s.end,env,dynamic);expressions(s.step,env,dynamic);const a=expr(s.start,env),b=expr(s.end,env),c=s.step?expr(s.step,env):value(1),single=v=>!v.unknown&&v.values.size===1,start=Array.from(a.values)[0],end=Array.from(b.values)[0],step=Array.from(c.values)[0],count=step?Math.max(0,Math.floor((end-start)/step)+1):Infinity;
        if([a,b,c].every(single)&&Number.isSafeInteger(count)&&count<=64&&step!==0){for(let i=0;i<count;i++){env.push(new Map([[s.variable.name,value(start+i*step)]]));body(s.body,env,dynamic);env.pop();}}
        else {const before=cloneEnv(env);env.push(new Map([[s.variable.name,unknown()]]));body(s.body,env,true);env.pop();combine(env,[before,env]);for(const m of env)for(const [k,v] of m)m.set(k,join([v,unknown()]));}
      }else if(['WhileStatement','RepeatStatement','ForGenericStatement'].includes(s.type)){
        expressions(s.condition,env,dynamic);for(const e of s.iterators||[])expressions(e,env,dynamic);const before=cloneEnv(env);env.push(new Map((s.variables||[]).map(v=>[v.name,unknown()])));body(s.body,env,true);env.pop();combine(env,[before,env]);for(const m of env)for(const [k,v] of m)m.set(k,join([v,unknown()]));
      }else if(s.type==='DoStatement')scoped(s.body,env,dynamic);
      else if(s.type==='FunctionDeclaration'){
        expressions(s,env,dynamic);if(s.identifier?.type==='Identifier')assign(env,s.identifier.name,unknown(),s.isLocal);
      }else expressions(s,env,dynamic);
    }}
    try{body(ast.body,[new Map()]);}catch(e){note(null,'inventory',e.message);}
    return {effectIds:Array.from(effects).sort((a,b)=>a-b),effectUses:uses,unresolved,complete:unresolved.length===0,scope};
  }
  return {inventory};
});
