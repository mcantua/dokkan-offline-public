package com.personal.offlinedokkan;

import android.app.Activity;
import android.content.pm.ApplicationInfo;
import android.net.Uri;
import android.os.Bundle;
import android.webkit.JavascriptInterface;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

/** Actual shared Creator in our data-free Offline host, not an original-game button/hook. */
public final class OfflineCreatorActivity extends Activity {
    private static final String ORIGIN="https://offline.creator.local";
    private static final int MESSAGE_LIMIT=24*1024*1024,REPLY_LIMIT=32*1024*1024,CHUNK=24000;
    private final ExecutorService worker=Executors.newSingleThreadExecutor();
    private volatile boolean destroyed;
    private OfflineCreatorSession session;
    private OfflineCore core;
    private WebView web;
    private TextView status;
    private volatile OfflineBattleCoordinator battleCoordinator;
    interface NativeBattleReply {void complete(Object result,String error);}
    /** Trusted native coordinator entrypoint; completion runs on the serialized session worker.
     * No JavascriptInterface annotation and no public transport dispatch to this API. */
    void nativeBattleOperation(String operation,JSONObject args,NativeBattleReply reply){
        if(destroyed){reply.complete(null,"CREATOR_CLOSED");return;}
        worker.execute(()->{try{
            if(session==null)throw new IllegalStateException("CREATOR_NOT_READY");reply.complete(session.nativeBattleOperation(operation,args),null);
        }catch(Exception|StackOverflowError error){String code=error.getMessage();reply.complete(null,code!=null&&code.matches("[A-Z_]{1,100}")?code:"BATTLE_STORAGE_OPERATION_FAILED");}});
    }
    /** Native planner entrypoints only; no JavascriptInterface method accepts a plan/reference. */
    void startTrustedBattlePlan(JSONObject plan,OfflineBattleCoordinator.Reply reply){
        worker.execute(()->{try{if(destroyed||session==null)throw new IllegalStateException("CREATOR_CLOSED");session.startTrustedBattlePlan(plan,reply);}catch(Exception error){reply.complete(null,"BATTLE_TRUSTED_PLAN_UNAVAILABLE");}});
    }
    void openTrustedBattlePlan(JSONObject reference,OfflineBattleCoordinator.Reply reply){
        worker.execute(()->{try{if(destroyed||session==null)throw new IllegalStateException("CREATOR_CLOSED");session.openTrustedBattlePlan(reference,reply);}catch(Exception error){reply.complete(null,"BATTLE_TRUSTED_PLAN_UNAVAILABLE");}});
    }
    private OfflineBattleCoordinator coordinatorOnWorker()throws Exception {
        if(destroyed)throw new IllegalStateException("CREATOR_CLOSED");if(battleCoordinator!=null)return battleCoordinator;
        // Read only fixed authored assets; ordinary Creator startup never creates this engine.
        String runtime=readAsset("offline-creator/gameplay/coordinator-runtime.js",1024*1024),battle=readAsset("offline-creator/gameplay/battle.js",1024*1024),saved=readAsset("offline-creator/gameplay/session.js",1024*1024);
        CountDownLatch created=new CountDownLatch(1);AtomicReference<Throwable> failure=new AtomicReference<>();
        runOnUiThread(()->{try{
            if(destroyed)throw new IllegalStateException("CREATOR_CLOSED");
            if(battleCoordinator==null)battleCoordinator=new OfflineBattleCoordinator(this,worker,(operation,args)->{if(destroyed||session==null)throw new IllegalStateException("CREATOR_CLOSED");return session.nativeBattleOperation(operation,args);},runtime,battle,saved);
        }catch(Exception|LinkageError error){failure.set(error);}finally{created.countDown();}});
        if(!created.await(10,TimeUnit.SECONDS)||failure.get()!=null||battleCoordinator==null)throw new IllegalStateException("BATTLE_ENGINE_UNAVAILABLE");return battleCoordinator;
    }

    @Override public void onCreate(Bundle state){
        super.onCreate(state);LinearLayout layout=new LinearLayout(this);layout.setOrientation(LinearLayout.VERTICAL);
        Button back=new Button(this);back.setText("Back to local player");back.setOnClickListener(v->onBackPressed());layout.addView(back);
        status=new TextView(this);status.setText("Opening Creator with your imported content…");layout.addView(status);
        web=new WebView(this);layout.addView(web,new LinearLayout.LayoutParams(-1,0,1));setContentView(layout);
        layout.setOnApplyWindowInsetsListener((view,insets)->{view.setPadding(insets.getSystemWindowInsetLeft(),insets.getSystemWindowInsetTop(),insets.getSystemWindowInsetRight(),insets.getSystemWindowInsetBottom());return insets;});layout.requestApplyInsets();
        web.getSettings().setJavaScriptEnabled(true);web.getSettings().setDomStorageEnabled(true);
        web.getSettings().setAllowFileAccess(false);web.getSettings().setAllowContentAccess(false);
        web.getSettings().setAllowFileAccessFromFileURLs(false);web.getSettings().setAllowUniversalAccessFromFileURLs(false);
        web.getSettings().setMixedContentMode(android.webkit.WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        web.getSettings().setJavaScriptCanOpenWindowsAutomatically(false);web.getSettings().setSupportMultipleWindows(false);
        // This own-app package is explicitly a development host. Release manifests
        // must omit debuggable; never enable WebView inspection unconditionally.
        if((getApplicationInfo().flags&ApplicationInfo.FLAG_DEBUGGABLE)!=0)WebView.setWebContentsDebuggingEnabled(true);
        web.addJavascriptInterface(new Transport(),"OfflineCreator");
        web.setWebViewClient(new WebViewClient(){
            @Override public boolean shouldOverrideUrlLoading(WebView view,WebResourceRequest request){return !local(request.getUrl())||!"/index.html".equals(request.getUrl().getPath());}
            @Override public WebResourceResponse shouldInterceptRequest(WebView view,WebResourceRequest request){return resource(request);}
            @Override public void onPageFinished(WebView view,String url){if(local(Uri.parse(url)))status.setText("Offline Creator · editable projects stay in this app. Finish adds your completed unit to your collection.");}
        });
        worker.execute(()->{try{
            OfflinePlayerStore.Selection selected=OfflinePlayerStore.active(this);if(selected==null)throw new IllegalStateException("MASTER_REQUIRED");
            File directory=selected.directory,master=selected.master;String hash=selected.hash;
            JSONArray tables=new JSONArray(readAsset("offline-creator/projection-tables.json",65536));
            core=new OfflineCore(new File(directory,"player.db").getPath(),master.getPath(),"sha256:"+hash);
            core.execute("profile.create","local-player","bootstrap-player-v1","{}");
            session=new OfflineCreatorSession(master,new File(directory,"creator-workspace.db"),core,selected.source,"sha256:"+hash,"local-player",tables);
            session.attachBattleDispatcher((operation,args,page,reply)->{OfflineBattleCoordinator coordinator=coordinatorOnWorker();if(page)coordinator.handlePage(operation,args,reply);else if(operation.equals("startTrustedPlan"))coordinator.startTrustedPlan(args.getJSONObject("plan"),reply);else if(operation.equals("openTrustedPlan"))coordinator.openTrustedPlan(args.getJSONObject("reference"),reply);else throw new IllegalStateException("UNSUPPORTED_NATIVE_BATTLE_OPERATION");});
            runOnUiThread(()->{if(!destroyed)web.loadUrl(ORIGIN+"/index.html");});
        }catch(Exception|LinkageError error){runOnUiThread(()->{if(!destroyed)status.setText("Could not open this Creator. Return to your local player and choose a compatible game database. Existing designs were kept.");});}});
    }
    private String readAsset(String name,int limit)throws Exception {try(InputStream input=getAssets().open(name);ByteArrayOutputStream out=new ByteArrayOutputStream()){byte[] buffer=new byte[65536];int n;while((n=input.read(buffer))!=-1){if(out.size()+n>limit)throw new IllegalStateException("CREATOR_ASSET_TOO_LARGE");out.write(buffer,0,n);}return new String(out.toByteArray(),StandardCharsets.UTF_8);}}
    private static boolean local(Uri uri){return "https".equals(uri.getScheme())&&"offline.creator.local".equals(uri.getHost())&&uri.getPort()==-1&&uri.getUserInfo()==null;}
    private WebResourceResponse resource(WebResourceRequest request){
        try{
            if(!"GET".equals(request.getMethod())||!local(request.getUrl()))return blocked();
            String path=request.getUrl().getPath();if(path==null||path.equals("/"))path="/index.html";
            if(!path.matches("/[A-Za-z0-9_./+%-]+")||path.indexOf('\\')>=0) return blocked();
            for(String part:path.split("/"))if(part.equals("..")||part.equals("."))return blocked();
            String mime=path.endsWith(".html")?"text/html":path.endsWith(".js")?"application/javascript":path.endsWith(".css")?"text/css":path.endsWith(".json")?"application/json":path.endsWith(".wasm")?"application/wasm":path.endsWith(".woff2")?"font/woff2":path.endsWith(".woff")?"font/woff":path.endsWith(".ttf")?"font/ttf":path.endsWith(".svg")?"image/svg+xml":path.endsWith(".png")?"image/png":"application/octet-stream";
            InputStream bytes=getAssets().open("offline-creator"+path);
            return new WebResourceResponse(mime,mime.startsWith("text/")||mime.contains("javascript")||mime.contains("json")?"utf-8":null,200,"OK",Collections.singletonMap("Cache-Control","no-store"),bytes);
        }catch(Exception error){return blocked();}
    }
    private static WebResourceResponse blocked(){return new WebResourceResponse("text/plain","utf-8",403,"Unavailable",Collections.singletonMap("Cache-Control","no-store"),new ByteArrayInputStream(new byte[0]));}
    private final class Transport {
        @JavascriptInterface public void closeAfterSave(){runOnUiThread(()->{if(!destroyed)finish();});}
        @JavascriptInterface public void postMessage(String raw){
            if(destroyed||raw==null||raw.length()>MESSAGE_LIMIT)return;
            worker.execute(()->{long id=0;JSONObject response=new JSONObject();try{
                if(raw.getBytes(StandardCharsets.UTF_8).length>MESSAGE_LIMIT)throw new IllegalStateException("CREATOR_MESSAGE_TOO_LARGE");
                JSONObject request=new JSONObject(raw);if(request.length()!=3||!request.has("id")||!request.has("op")||!request.has("args"))throw new IllegalStateException("INVALID_CREATOR_REQUEST");
                Object token=request.get("id");if(!(token instanceof Number))throw new IllegalStateException("INVALID_CREATOR_REQUEST");
                id=((Number)token).longValue();if(id<1||id>9007199254740991L||((Number)token).doubleValue()!=(double)id)throw new IllegalStateException("INVALID_CREATOR_REQUEST");
                if(session==null)throw new IllegalStateException("CREATOR_NOT_READY");final long requestId=id;
                if(session.forwardPublicBattle(request.getString("op"),request.getJSONObject("args"),(value,error)->{try{JSONObject message=new JSONObject().put("id",requestId).put("ok",error==null);if(error==null)message.put("result",value==null?JSONObject.NULL:value);else message.put("error",error);reply(requestId,message);}catch(Exception ignored){}}))return;
                Object result=session.call(request.getString("op"),request.getJSONObject("args"));response.put("id",id).put("ok",true).put("result",result);
            }catch(Exception|StackOverflowError error){try{String code=error.getMessage();response=new JSONObject().put("id",id).put("ok",false).put("error",code!=null&&code.matches("[A-Z_]{1,100}")?code:"CREATOR_OPERATION_FAILED");}catch(Exception ignored){return;}}
            reply(id,response);
            });
        }
    }
    private static String literal(String text){return JSONObject.quote(text).replace("\u2028","\\u2028").replace("\u2029","\\u2029");}
    private void reply(long id,JSONObject response){
        String text=response.toString();if(text.getBytes(StandardCharsets.UTF_8).length>REPLY_LIMIT){try{text=new JSONObject().put("id",id).put("ok",false).put("error","CREATOR_REPLY_TOO_LARGE").toString();}catch(Exception impossible){return;}}
        final String body=text;runOnUiThread(()->{if(destroyed)return;
            if(body.length()<=CHUNK){web.evaluateJavascript("window.__offlineCreatorReply("+body.replace("\u2028","\\u2028").replace("\u2029","\\u2029")+");",null);return;}
            java.util.List<String> chunks=new java.util.ArrayList<>();for(int start=0;start<body.length();){int end=Math.min(start+CHUNK,body.length());if(end<body.length()&&Character.isHighSurrogate(body.charAt(end-1)))end--;chunks.add(body.substring(start,end));start=end;}
            for(int n=0;n<chunks.size();n++)web.evaluateJavascript("window.__offlineCreatorReplyChunk("+id+","+n+","+chunks.size()+","+literal(chunks.get(n))+");",null);
        });
    }
    @Override public void onBackPressed(){
        if(web==null||session==null){super.onBackPressed();return;}
        status.setText("Saving your latest edits…");
        web.evaluateJavascript("Promise.resolve(typeof flushSave==='function'?flushSave():null).then(()=>window.OfflineCreator.closeAfterSave(),()=>{if(typeof toast==='function')toast('Could not save your latest edits. Keep the Creator open and retry.',true);});",null);
    }
    @Override protected void onDestroy(){destroyed=true;if(battleCoordinator!=null)battleCoordinator.close();if(web!=null){web.removeJavascriptInterface("OfflineCreator");web.destroy();}worker.execute(()->{if(session!=null)session.close();if(core!=null)core.close();});worker.shutdown();super.onDestroy();}
}
