package com.personal.offlinedokkan;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.util.JsonReader;
import android.util.JsonToken;
import android.view.View;
import android.webkit.JavascriptInterface;
import android.webkit.JsPromptResult;
import android.webkit.JsResult;
import android.webkit.PermissionRequest;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.ByteArrayInputStream;
import java.io.StringReader;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.Executor;

/** Separate hidden engine context. Its private interface is never installed on the game/Creator view. */
final class OfflineBattleCoordinator implements AutoCloseable {
    interface Reply {void complete(Object result,String error);}
    interface NativeStore {Object execute(String operation,JSONObject args)throws Exception;}
    private static final int RPC_LIMIT=24*1024*1024,REPLY_LIMIT=12*1024*1024,CHUNK=24000;
    private static final long SAFE=9007199254740991L;
    private final Handler main=new Handler(Looper.getMainLooper());
    private final Executor worker;
    private final NativeStore store;
    private final WebView engine;
    private final String nonce=UUID.randomUUID().toString()+UUID.randomUUID().toString();
    private final Map<Long,Pending> pending=new LinkedHashMap<>();
    private volatile boolean closed,ready;
    private String terminalError;
    private boolean initialized;
    private long sequence;
    private static final class Pending {
        final long id;final String request;final boolean page;final Reply reply;Runnable timeout;
        Pending(long id,String request,boolean page,Reply reply){this.id=id;this.request=request;this.page=page;this.reply=reply;}
    }
    OfflineBattleCoordinator(Activity activity,Executor worker,NativeStore store,String runtime,String battle,String session){
        if(Looper.myLooper()!=Looper.getMainLooper())throw new IllegalStateException("BATTLE_MAIN_THREAD_REQUIRED");
        this.worker=worker;this.store=store;engine=new WebView(activity);
        engine.setVisibility(View.GONE);engine.setFocusable(false);engine.setFocusableInTouchMode(false);engine.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO);
        engine.getSettings().setJavaScriptEnabled(true);engine.getSettings().setDomStorageEnabled(false);engine.getSettings().setDatabaseEnabled(false);
        engine.getSettings().setAllowFileAccess(false);engine.getSettings().setAllowContentAccess(false);engine.getSettings().setAllowFileAccessFromFileURLs(false);engine.getSettings().setAllowUniversalAccessFromFileURLs(false);
        engine.getSettings().setBlockNetworkLoads(true);engine.getSettings().setBlockNetworkImage(true);engine.getSettings().setLoadsImagesAutomatically(false);engine.getSettings().setGeolocationEnabled(false);
        engine.getSettings().setJavaScriptCanOpenWindowsAutomatically(false);engine.getSettings().setSupportMultipleWindows(false);engine.getSettings().setMixedContentMode(android.webkit.WebSettings.MIXED_CONTENT_NEVER_ALLOW);engine.getSettings().setCacheMode(android.webkit.WebSettings.LOAD_NO_CACHE);
        engine.addJavascriptInterface(new PrivateBridge(),"OfflineBattleNative");
        engine.setWebChromeClient(new WebChromeClient(){
            @Override public boolean onJsAlert(WebView view,String url,String message,JsResult result){result.cancel();return true;}
            @Override public boolean onJsConfirm(WebView view,String url,String message,JsResult result){result.cancel();return true;}
            @Override public boolean onJsPrompt(WebView view,String url,String message,String value,JsPromptResult result){result.cancel();return true;}
            @Override public void onPermissionRequest(PermissionRequest request){request.deny();}
            @Override public boolean onCreateWindow(WebView view,boolean dialog,boolean gesture,android.os.Message message){return false;}
        });
        engine.setDownloadListener((url,agent,disposition,mime,length)->{});
        engine.setWebViewClient(new WebViewClient(){
            @Override public boolean shouldOverrideUrlLoading(WebView view,WebResourceRequest request){return true;}
            @Override public WebResourceResponse shouldInterceptRequest(WebView view,WebResourceRequest request){return new WebResourceResponse("text/plain","utf-8",403,"Unavailable",java.util.Collections.emptyMap(),new ByteArrayInputStream(new byte[0]));}
            @Override public void onPageFinished(WebView view,String url){
                if(closed||initialized||view!=engine||!"about:blank".equals(url))return;initialized=true;
                // Native-authored scripts only. Runtime installs native SHA before the other modules load.
                engine.evaluateJavascript(bootstrap()+"\n"+runtime+"\n"+battle+"\n"+session+"\n;typeof OfflineBattleCoordinator==='object'",value->{
                    if(closed)return;if(!"true".equals(value)){failAll("BATTLE_ENGINE_BOOTSTRAP_FAILED");return;}ready=true;for(Pending request:new ArrayList<>(pending.values()))send(request);
                });
            }
        });
        String csp="default-src 'none';script-src 'none';connect-src 'none';frame-src 'none';child-src 'none';worker-src 'none';object-src 'none';base-uri 'none';form-action 'none'";
        engine.loadDataWithBaseURL(null,"<!doctype html><meta http-equiv=\"Content-Security-Policy\" content=\""+csp+"\"><title>Private battle engine</title>","text/html","utf-8",null);
        main.postDelayed(()->{if(!closed&&!ready)failAll("BATTLE_ENGINE_BOOTSTRAP_TIMEOUT");},30000);
    }
    void handlePage(String operation,JSONObject args,Reply reply){submit(operation,args,true,reply);}
    void startTrustedPlan(JSONObject plan,Reply reply){try{submit("startTrustedPlan",new JSONObject().put("plan",plan),false,reply);}catch(Exception error){reply.complete(null,"BATTLE_REQUEST_INVALID");}}
    void openTrustedPlan(JSONObject reference,Reply reply){try{submit("openTrustedPlan",new JSONObject().put("reference",reference),false,reply);}catch(Exception error){reply.complete(null,"BATTLE_REQUEST_INVALID");}}
    private void submit(String operation,JSONObject args,boolean page,Reply reply){
        final String copied;
        try{if(args==null||page&&!operation.equals("load")&&!operation.equals("dispatch"))throw new IllegalArgumentException();copied=args.toString();if(copied.getBytes(StandardCharsets.UTF_8).length>(page?65536:1024*1024))throw new IllegalArgumentException();}catch(Exception error){reply.complete(null,"BATTLE_REQUEST_INVALID");return;}
        main.post(()->{
            if(closed||terminalError!=null){reply.complete(null,closed?"BATTLE_COORDINATOR_CLOSED":terminalError);return;}if(pending.size()>=16||sequence>=SAFE){reply.complete(null,"BATTLE_COORDINATOR_BUSY");return;}
            try{long id=++sequence;Pending request=new Pending(id,new JSONObject().put("id",id).put("op",operation).put("args",new JSONObject(copied)).toString(),page,reply);
                request.timeout=()->{if(pending.remove(id)!=null)reply.complete(null,"BATTLE_COORDINATOR_TIMEOUT");};pending.put(id,request);main.postDelayed(request.timeout,120000);if(ready)send(request);
            }catch(Exception error){reply.complete(null,"BATTLE_REQUEST_INVALID");}
        });
    }
    private void send(Pending request){sendChunks("__offlineBattleRequest",request.id,request.request,request.page);}
    private static String literal(String value){return JSONObject.quote(value).replace("\u2028","\\u2028").replace("\u2029","\\u2029");}
    private void sendChunks(String function,long id,String text,boolean page){
        if(closed)return;ArrayList<String> chunks=new ArrayList<>();
        for(int start=0;start<text.length();){int end=Math.min(start+CHUNK,text.length());if(end<text.length()&&Character.isHighSurrogate(text.charAt(end-1)))end--;chunks.add(text.substring(start,end));start=end;}
        for(int index=0;index<chunks.size();index++)engine.evaluateJavascript(function+"("+id+","+index+","+chunks.size()+","+literal(chunks.get(index))+","+page+");",null);
    }
    private static String code(Throwable error){String value=error.getMessage();return value!=null&&value.matches("[A-Z][A-Z0-9_]{0,95}")?value:"BATTLE_NATIVE_RPC_FAILED";}
    private void rpcReply(long id,Object result,String error){
        try{JSONObject message=new JSONObject().put("id",id).put("ok",error==null);if(error==null)message.put("result",result==null?JSONObject.NULL:result);else message.put("error",error);String text=message.toString();if(text.getBytes(StandardCharsets.UTF_8).length>RPC_LIMIT)throw new IllegalStateException("BATTLE_NATIVE_REPLY_TOO_LARGE");main.post(()->sendChunks("__offlineBattleRPCReply",id,text,false));}catch(Exception failure){main.post(()->failAll("BATTLE_NATIVE_REPLY_INVALID"));}
    }
    private final class PrivateBridge {
        @JavascriptInterface public void rpc(String proof,String raw){
            if(closed||!ready||!nonce.equals(proof)||raw==null||raw.length()>RPC_LIMIT)return;
            worker.execute(()->rpcOnWorker(raw));
        }
        @JavascriptInterface public void complete(String proof,String raw){
            if(closed||!ready||!nonce.equals(proof)||raw==null||raw.length()>REPLY_LIMIT)return;
            worker.execute(()->{try{
                if(raw.getBytes(StandardCharsets.UTF_8).length>REPLY_LIMIT)throw new IllegalStateException();JSONObject value=new JSONObject(raw);Object rawId=value.get("id");if(!(rawId instanceof Number))throw new IllegalStateException();long id=((Number)rawId).longValue();if(id<1||id>SAFE||((Number)rawId).doubleValue()!=id||value.length()!=2||value.has("result")==value.has("error"))throw new IllegalStateException();
                Object result=value.opt("result");String error=null;if(value.has("error")){JSONObject detail=value.getJSONObject("error");if(detail.length()!=2||!detail.has("code")||!detail.has("message"))throw new IllegalStateException();error=detail.getString("code");if(!error.matches("[A-Z][A-Z0-9_]{0,95}"))throw new IllegalStateException();}
                final String failed=error;main.post(()->{Pending request=pending.remove(id);if(request==null)return;main.removeCallbacks(request.timeout);request.reply.complete(result,failed);});
            }catch(Exception|StackOverflowError failure){main.post(()->failAll("BATTLE_COORDINATOR_REPLY_INVALID"));}});
        }
    }
    private static void name(JsonReader input,String expected)throws Exception {if(!expected.equals(input.nextName()))throw new IllegalStateException("BATTLE_NATIVE_REQUEST_INVALID");}
    private void rpcOnWorker(String raw){
        long id=0;
        try(JsonReader input=new JsonReader(new StringReader(raw))){
            if(closed)return;if(raw.getBytes(StandardCharsets.UTF_8).length>RPC_LIMIT)throw new IllegalStateException("BATTLE_NATIVE_REQUEST_TOO_LARGE");input.setLenient(false);input.beginObject();name(input,"id");if(input.peek()!=JsonToken.NUMBER)throw new IllegalStateException("BATTLE_NATIVE_REQUEST_INVALID");id=Long.parseLong(input.nextString());if(id<1||id>SAFE)throw new IllegalStateException("BATTLE_NATIVE_REQUEST_INVALID");name(input,"op");String operation=input.nextString();name(input,"args");input.beginObject();Object result=null;String storeOperation=null;JSONObject storeArgs=null;
            if(operation.equals("sha256")){
                name(input,"bytes");input.beginArray();MessageDigest digest=MessageDigest.getInstance("SHA-256");byte[] block=new byte[65536];int used=0,total=0;
                while(input.hasNext()){if(input.peek()!=JsonToken.NUMBER)throw new IllegalStateException("BATTLE_HASH_INPUT_INVALID");int value=Integer.parseInt(input.nextString());if(value<0||value>255||++total>4*1024*1024)throw new IllegalStateException("BATTLE_HASH_INPUT_INVALID");block[used++]=(byte)value;if(used==block.length){digest.update(block);used=0;}}
                input.endArray();if(used>0)digest.update(block,0,used);JSONArray bytes=new JSONArray();for(byte value:digest.digest())bytes.put(value&255);result=bytes;
            }else if(operation.equals("read")){storeOperation="offlineBattleRead";storeArgs=new JSONObject();}
            else if(operation.equals("cas")){
                JSONObject args=new JSONObject();Set<String> seen=new HashSet<>();while(input.hasNext()){String key=input.nextName();if(!seen.add(key))throw new IllegalStateException("BATTLE_NATIVE_REQUEST_INVALID");if(key.equals("expectedToken")){if(input.peek()==JsonToken.NULL){input.nextNull();args.put(key,JSONObject.NULL);}else if(input.peek()==JsonToken.STRING)args.put(key,input.nextString());else throw new IllegalStateException("BATTLE_NATIVE_REQUEST_INVALID");}else if(key.equals("data")&&input.peek()==JsonToken.STRING)args.put(key,input.nextString());else throw new IllegalStateException("BATTLE_NATIVE_REQUEST_INVALID");}if(seen.size()!=2)throw new IllegalStateException("BATTLE_NATIVE_REQUEST_INVALID");storeOperation="offlineBattleCompareSwap";storeArgs=args;
            }else throw new IllegalStateException("UNSUPPORTED_NATIVE_BATTLE_RPC");
            input.endObject();input.endObject();if(input.peek()!=JsonToken.END_DOCUMENT)throw new IllegalStateException("BATTLE_NATIVE_REQUEST_INVALID");if(storeOperation!=null)result=store.execute(storeOperation,storeArgs);rpcReply(id,result,null);
        }catch(Exception|StackOverflowError error){rpcReply(id,null,code(error));}
    }
    private void failAll(String error){terminalError=error;ready=false;for(Pending request:new ArrayList<>(pending.values())){main.removeCallbacks(request.timeout);request.reply.complete(null,error);}pending.clear();}
    @Override public void close(){main.post(()->{if(closed)return;closed=true;ready=false;failAll("BATTLE_COORDINATOR_CLOSED");engine.removeJavascriptInterface("OfflineBattleNative");engine.stopLoading();engine.destroy();});}
    private String bootstrap(){return String.join("\n",
        "(function(){'use strict';if(window.top!==window)throw Error('BATTLE_MAIN_FRAME_REQUIRED');",
        "const proof="+literal(nonce)+",waiting=new Map(),rpcFragments=new Map(),requests=new Map();let serial=0;",
        "function receive(m){const p=waiting.get(m.id);if(!p)return;waiting.delete(m.id);rpcFragments.delete(m.id);clearTimeout(p.timer);m.ok===true?p.resolve(m.result):p.reject(Error(m.error||'BATTLE_NATIVE_RPC_FAILED'));}",
        "function chunk(map,id,index,total,text,page){if(!Number.isSafeInteger(id)||!Number.isInteger(index)||!Number.isInteger(total)||total<1||total>2048||typeof text!=='string'||text.length>24000)throw Error('BATTLE_NATIVE_CHUNK_INVALID');let f=map.get(id);if(!f){if(index!==0)throw Error('BATTLE_NATIVE_CHUNK_ORDER');f={next:0,total,page,parts:[],length:0};map.set(id,f);}if(f.next!==index||f.total!==total||f.page!==page||(f.length+=text.length)>25165824)throw Error('BATTLE_NATIVE_CHUNK_ORDER');f.parts.push(text);if(++f.next!==total)return null;map.delete(id);const raw=f.parts.join('');if(new TextEncoder().encode(raw).length>25165824)throw Error('BATTLE_NATIVE_CHUNK_TOO_LARGE');const message=JSON.parse(raw);if(message.id!==id)throw Error('BATTLE_NATIVE_CHUNK_ID');return message;}",
        "Object.defineProperty(globalThis,'nativeBattleRPC',{value:(op,args)=>new Promise((resolve,reject)=>{if(waiting.size>=64||!Number.isSafeInteger(++serial))return reject(Error('BATTLE_NATIVE_RPC_BUSY'));const id=serial,timer=setTimeout(()=>{waiting.delete(id);rpcFragments.delete(id);reject(Error('BATTLE_NATIVE_RPC_TIMEOUT'));},120000);waiting.set(id,{resolve,reject,timer});try{OfflineBattleNative.rpc(proof,JSON.stringify({id,op,args}));}catch(e){receive({id,ok:false,error:'BATTLE_NATIVE_RPC_FAILED'});}}),writable:false,configurable:false});",
        "globalThis.__offlineBattleRPCReply=(id,index,total,text,page)=>{if(!waiting.has(id))return;try{const m=chunk(rpcFragments,id,index,total,text,page);if(m)receive(m);}catch(e){receive({id,ok:false,error:'BATTLE_NATIVE_REPLY_INVALID'});}};",
        "globalThis.__offlineBattleRequest=(id,index,total,text,page)=>{try{const request=chunk(requests,id,index,total,text,page);if(!request)return;Promise.resolve().then(()=>page?OfflineBattleCoordinator.handlePage(request):OfflineBattleCoordinator.handle(request)).then(reply=>OfflineBattleNative.complete(proof,JSON.stringify(reply)),()=>OfflineBattleNative.complete(proof,JSON.stringify({id,error:{code:'BATTLE_COORDINATOR_FAILED',message:'BATTLE_COORDINATOR_FAILED'}})));}catch(e){requests.delete(id);OfflineBattleNative.complete(proof,JSON.stringify({id,error:{code:'BATTLE_NATIVE_REQUEST_INVALID',message:'BATTLE_NATIVE_REQUEST_INVALID'}}));}};",
        "})();");}
}
