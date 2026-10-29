.class Lcom/personal/aihub/PreviewActivity$AnonymousClass1;
.super Landroid/webkit/WebViewClient;
.field this$0 Lcom/personal/aihub/PreviewActivity;
.field val$cache Lcom/personal/aihub/PreviewCache;
.field val$layout Landroid/widget/LinearLayout;
.field val$request Lorg/json/JSONObject;
.field val$status Landroid/widget/TextView;

.method <init>(Lcom/personal/aihub/PreviewActivity; Lcom/personal/aihub/PreviewCache; Landroid/widget/TextView; Landroid/widget/LinearLayout; Lorg/json/JSONObject;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0004 invoke-direct v0, Landroid/webkit/WebViewClient;-><init>()V
  000a iput-object v2, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->val$cache Lcom/personal/aihub/PreviewCache;
  000e iput-object v3, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->val$status Landroid/widget/TextView;
  0012 iput-object v4, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->val$layout Landroid/widget/LinearLayout;
  0016 iput-object v5, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->val$request Lorg/json/JSONObject;
  001a return-void 
.end method

.method m30lambda$0$compersonalaihubPreviewActivity$1(Landroid/webkit/WebView; Landroid/widget/TextView; Ljava/lang/String;)V
  0000 iget-object v0, v1, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0004 invoke-static v0, Lcom/personal/aihub/PreviewActivity;->access$400(Lcom/personal/aihub/PreviewActivity;)Landroid/webkit/WebView;
  000a move-result-object v0
  000c if-ne v0, v2, +005h
  0010 invoke-virtual v3, v4, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0016 return-void 
.end method

.method m31lambda$1$compersonalaihubPreviewActivity$1()V
  0000 iget-object v0, v1, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0004 invoke-virtual v0, Lcom/personal/aihub/PreviewActivity;->recreate()V
  000a return-void 
.end method

.method m32lambda$2$compersonalaihubPreviewActivity$1(Landroid/webkit/WebView; Ljava/lang/String; Landroid/widget/LinearLayout; Landroid/widget/TextView; Lorg/json/JSONObject; Lcom/personal/aihub/PreviewCache; Ljava/lang/String;)V
  0000 move-object v0, v13
  0002 move-object v9, v14
  0004 move-object/from16 v10, v17
  0008 move-object/from16 v1, v18
  000c const-string v2, "["
  0010 iget-object v3, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0014 invoke-static v3, Lcom/personal/aihub/PreviewActivity;->access$400(Lcom/personal/aihub/PreviewActivity;)Landroid/webkit/WebView;
  001a move-result-object v3
  001c if-ne v3, v9, +0cdh
  0020 iget-object v3, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0024 invoke-static v3, Lcom/personal/aihub/PreviewActivity;->access$100(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/PreviewServer;
  002a move-result-object v3
  002c if-eqz v3, +0c5h
  0030 iget-object v3, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0034 invoke-virtual v3, Lcom/personal/aihub/PreviewActivity;->isFinishing()Z
  003a move-result v3
  003c if-nez v3, +0bdh
  0040 invoke-virtual v14, Landroid/webkit/WebView;->getUrl()Ljava/lang/String;
  0046 move-result-object v3
  0048 move-object v4, v15
  004a invoke-virtual v15, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0050 move-result v3
  0052 if-nez v3, +004h
  0056 goto/16 +0b0h
  005a iget-object v3, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  005e invoke-static v3, Lcom/personal/aihub/PreviewActivity;->access$300(Lcom/personal/aihub/PreviewActivity;)J
  0064 move-result-wide v11
  0066 new-instance v3, Lorg/json/JSONObject;
  006a new-instance v4, Lorg/json/JSONArray;
  006e new-instance v5, Ljava/lang/StringBuilder;
  0072 invoke-direct v5, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0078 move-object/from16 v2, v20
  007c invoke-virtual v5, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0082 const-string v2, "]"
  0086 invoke-virtual v5, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  008c invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0092 move-result-object v2
  0094 invoke-direct v4, v2, Lorg/json/JSONArray;-><init>(Ljava/lang/String;)V
  009a const/4 v2, 0
  009c invoke-virtual v4, v2, Lorg/json/JSONArray;->getString(I)Ljava/lang/String;
  00a2 move-result-object v2
  00a4 invoke-direct v3, v2, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  00aa const-string v2, "healthy"
  00ae invoke-virtual v3, v2, Lorg/json/JSONObject;->optBoolean(Ljava/lang/String;)Z
  00b4 move-result v2
  00b6 if-nez v2, +00ah
  00ba iget-object v1, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  00be move-object/from16 v2, v16
  00c2 invoke-virtual v1, v2, v10, v14, Lcom/personal/aihub/PreviewActivity;->unreliableRuntime(Landroid/widget/LinearLayout; Landroid/widget/TextView; Landroid/webkit/WebView;)V
  00c8 return-void 
  00ca const-string v2, "offline"
  00ce invoke-virtual/range v19, Lcom/personal/aihub/PreviewCache;->offline()Z
  00d4 move-result v4
  00d6 invoke-virtual v1, v2, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  00dc const-string v2, "localPreview"
  00e0 const/4 v4, 1
  00e2 invoke-virtual v1, v2, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  00e8 new-instance v4, Lcom/personal/aihub/PreviewBootstrap;
  00ec invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  00f2 move-result-object v2
  00f4 invoke-virtual v2, Ljava/util/UUID;->toString()Ljava/lang/String;
  00fa move-result-object v2
  00fc const-string v5, "documentId"
  0100 invoke-virtual v3, v5, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0106 move-result-object v3
  0108 invoke-virtual/range v18, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  010e move-result-object v5
  0110 invoke-direct v4, v2, v3, v5, Lcom/personal/aihub/PreviewBootstrap;-><init>(Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)V
  0116 iget-object v2, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  011a invoke-virtual v2, Lcom/personal/aihub/PreviewActivity;->getAssets()Landroid/content/res/AssetManager;
  0120 move-result-object v2
  0122 const-string v3, "mode"
  0126 invoke-virtual v1, v3, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  012c move-result-object v1
  012e const-string v3, "movie"
  0132 invoke-virtual v1, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0138 move-result v1
  013a if-eqz v1, +005h
  013e const-string v1, "ui/movie-page.js"
  0142 goto +3h
  0144 const-string v1, "ui/animation-page.js"
  0148 invoke-virtual v2, v1, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;
  014e move-result-object v1
  0150 const v2, 200000
  0156 invoke-static v1, v2, Lcom/personal/aihub/PreviewActivity;->read(Ljava/io/InputStream; I)Ljava/lang/String;
  015c move-result-object v7
  015e iget-object v1, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0162 invoke-static v1, v4, Lcom/personal/aihub/PreviewActivity;->access$202(Lcom/personal/aihub/PreviewActivity; Lcom/personal/aihub/PreviewBootstrap;)Lcom/personal/aihub/PreviewBootstrap;
  0168 iget-object v1, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  016c invoke-static v1, Lcom/personal/aihub/PreviewActivity;->access$000(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/WebViewStartup;
  0172 move-result-object v1
  0174 const-string v2, "request-transfer"
  0178 invoke-virtual v1, v14, v11, v12, v2, Lcom/personal/aihub/WebViewStartup;->stage(Landroid/webkit/WebView; J Ljava/lang/String;)V
  017e iget-object v1, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0182 const/4 v6, -1
  0184 move-object v2, v14
  0186 move-object v3, v4
  0188 move-wide v4, v11
  018a move-object/from16 v8, v17
  018e invoke-static/range v1 ... v8, Lcom/personal/aihub/PreviewActivity;->access$500(Lcom/personal/aihub/PreviewActivity; Landroid/webkit/WebView; Lcom/personal/aihub/PreviewBootstrap; J I Ljava/lang/String; Landroid/widget/TextView;)V
  0194 goto +11h
  0196 const-string v1, "Could not prepare this preview. Return and try a shorter sequence."
  019a invoke-virtual v10, v1, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  01a0 iget-object v1, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  01a4 invoke-static v1, Lcom/personal/aihub/PreviewActivity;->access$000(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/WebViewStartup;
  01aa move-result-object v1
  01ac const-string v2, "Could not prepare this animation screen. Try a shorter sequence or copy a startup report."
  01b0 invoke-virtual v1, v14, v11, v12, v2, Lcom/personal/aihub/WebViewStartup;->failed(Landroid/webkit/WebView; J Ljava/lang/String;)V
  01b6 return-void 
.end method

.method onPageFinished(Landroid/webkit/WebView; Ljava/lang/String;)V
  0000 move-object/from16 v10, v16
  0004 move-object/from16 v11, v17
  0008 iget-object v0, v10, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  000c invoke-static v0, Lcom/personal/aihub/PreviewActivity;->access$100(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/PreviewServer;
  0012 move-result-object v0
  0014 if-eqz v0, +095h
  0018 iget-object v0, v10, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  001c invoke-static v0, Lcom/personal/aihub/PreviewActivity;->access$100(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/PreviewServer;
  0022 move-result-object v0
  0024 move-object/from16 v5, v18
  0028 invoke-virtual v0, v5, Lcom/personal/aihub/PreviewServer;->local(Ljava/lang/String;)Z
  002e move-result v0
  0030 if-eqz v0, +087h
  0034 invoke-static/range v18, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  003a move-result-object v0
  003c invoke-virtual v0, Landroid/net/Uri;->getPath()Ljava/lang/String;
  0042 move-result-object v0
  0044 const-string v1, "/tools/(lua|lwf|usm)-player/.*"
  0048 invoke-virtual v0, v1, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  004e move-result v0
  0050 if-nez v0, +004h
  0054 goto/16 +075h
  0058 iget-object v0, v10, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  005c invoke-static v0, Lcom/personal/aihub/PreviewActivity;->access$000(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/WebViewStartup;
  0062 move-result-object v0
  0064 invoke-virtual v0, Lcom/personal/aihub/WebViewStartup;->epoch()J
  006a move-result-wide v12
  006c iget-object v0, v10, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0070 invoke-static v0, Lcom/personal/aihub/PreviewActivity;->access$300(Lcom/personal/aihub/PreviewActivity;)J
  0076 move-result-wide v0
  0078 cmp-long v0, v0, v12
  007c if-nez v0, +003h
  0080 return-void 
  0082 iget-object v0, v10, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0086 invoke-static v0, v12, v13, Lcom/personal/aihub/PreviewActivity;->access$302(Lcom/personal/aihub/PreviewActivity; J)J
  008c iget-object v0, v10, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0090 invoke-static v0, Lcom/personal/aihub/PreviewActivity;->access$000(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/WebViewStartup;
  0096 move-result-object v0
  0098 const-string v1, "player-runtime"
  009c invoke-virtual v0, v11, v12, v13, v1, Lcom/personal/aihub/WebViewStartup;->stage(Landroid/webkit/WebView; J Ljava/lang/String;)V
  00a2 new-instance v0, Ljava/lang/StringBuilder;
  00a6 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  00ac iget-object v1, v10, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  00b0 invoke-virtual v1, Lcom/personal/aihub/PreviewActivity;->getAssets()Landroid/content/res/AssetManager;
  00b6 move-result-object v1
  00b8 const-string v2, "ui/preview-runtime.js"
  00bc invoke-virtual v1, v2, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;
  00c2 move-result-object v1
  00c4 const/16 v2, 20000
  00c8 invoke-static v1, v2, Lcom/personal/aihub/PreviewActivity;->read(Ljava/io/InputStream; I)Ljava/lang/String;
  00ce move-result-object v1
  00d0 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00d6 const-string v1, ";JSON.stringify({healthy:Boolean(window.ForgePreviewRuntime && window.ForgePreviewRuntime.healthy()),documentId:String(window.__forgeNativeDocumentId||'')})"
  00da invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00e0 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00e6 move-result-object v14
  00e8 iget-object v6, v10, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->val$layout Landroid/widget/LinearLayout;
  00ec iget-object v7, v10, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->val$status Landroid/widget/TextView;
  00f0 iget-object v8, v10, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->val$request Lorg/json/JSONObject;
  00f4 iget-object v9, v10, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->val$cache Lcom/personal/aihub/PreviewCache;
  00f8 new-instance v15, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;
  00fc move-object v0, v15
  00fe move-object/from16 v1, v16
  0102 move-object/from16 v2, v17
  0106 move-wide v3, v12
  0108 move-object/from16 v5, v18
  010c invoke-direct/range v0 ... v9, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;-><init>(Lcom/personal/aihub/PreviewActivity$AnonymousClass1; Landroid/webkit/WebView; J Ljava/lang/String; Landroid/widget/LinearLayout; Landroid/widget/TextView; Lorg/json/JSONObject; Lcom/personal/aihub/PreviewCache;)V
  0112 invoke-virtual v11, v14, v15, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String; Landroid/webkit/ValueCallback;)V
  0118 goto +13h
  011a iget-object v0, v10, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->val$status Landroid/widget/TextView;
  011e const-string v1, "Could not check the animation player. Return to the Studio and reopen this preview."
  0122 invoke-virtual v0, v1, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0128 iget-object v0, v10, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  012c invoke-static v0, Lcom/personal/aihub/PreviewActivity;->access$000(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/WebViewStartup;
  0132 move-result-object v0
  0134 const-string v1, "Could not check this animation screen. Try again or copy a startup report."
  0138 invoke-virtual v0, v11, v12, v13, v1, Lcom/personal/aihub/WebViewStartup;->failed(Landroid/webkit/WebView; J Ljava/lang/String;)V
  013e return-void 
.end method

.method onPageStarted(Landroid/webkit/WebView; Ljava/lang/String; Landroid/graphics/Bitmap;)V
  0000 iget-object v5, v2, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0004 invoke-static v5, Lcom/personal/aihub/PreviewActivity;->access$000(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/WebViewStartup;
  000a move-result-object v5
  000c if-eqz v5, +02ch
  0010 iget-object v5, v2, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0014 invoke-static v5, Lcom/personal/aihub/PreviewActivity;->access$100(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/PreviewServer;
  001a move-result-object v5
  001c if-eqz v5, +024h
  0020 iget-object v5, v2, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0024 invoke-static v5, Lcom/personal/aihub/PreviewActivity;->access$100(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/PreviewServer;
  002a move-result-object v5
  002c invoke-virtual v5, v4, Lcom/personal/aihub/PreviewServer;->local(Ljava/lang/String;)Z
  0032 move-result v4
  0034 if-eqz v4, +018h
  0038 iget-object v4, v2, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  003c const/4 v5, 0
  003e invoke-static v4, v5, Lcom/personal/aihub/PreviewActivity;->access$202(Lcom/personal/aihub/PreviewActivity; Lcom/personal/aihub/PreviewBootstrap;)Lcom/personal/aihub/PreviewBootstrap;
  0044 iget-object v4, v2, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0048 const-wide/16 v0, -1
  004c invoke-static v4, v0, v1, Lcom/personal/aihub/PreviewActivity;->access$302(Lcom/personal/aihub/PreviewActivity; J)J
  0052 iget-object v4, v2, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0056 invoke-static v4, Lcom/personal/aihub/PreviewActivity;->access$000(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/WebViewStartup;
  005c move-result-object v4
  005e invoke-virtual v4, v3, Lcom/personal/aihub/WebViewStartup;->begin(Landroid/webkit/WebView;)J
  0064 return-void 
.end method

.method onReceivedError(Landroid/webkit/WebView; Landroid/webkit/WebResourceRequest; Landroid/webkit/WebResourceError;)V
  0000 iget-object v5, v2, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0004 invoke-static v5, Lcom/personal/aihub/PreviewActivity;->access$400(Lcom/personal/aihub/PreviewActivity;)Landroid/webkit/WebView;
  000a move-result-object v5
  000c if-ne v5, v3, +02ch
  0010 invoke-interface v4, Landroid/webkit/WebResourceRequest;->isForMainFrame()Z
  0016 move-result v4
  0018 if-eqz v4, +026h
  001c iget-object v4, v2, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->val$status Landroid/widget/TextView;
  0020 const-string v5, "Could not open the local animation player. Return to the Studio and reopen this preview."
  0024 invoke-virtual v4, v5, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  002a iget-object v4, v2, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  002e invoke-static v4, Lcom/personal/aihub/PreviewActivity;->access$000(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/WebViewStartup;
  0034 move-result-object v4
  0036 if-eqz v4, +017h
  003a iget-object v4, v2, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  003e invoke-static v4, Lcom/personal/aihub/PreviewActivity;->access$000(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/WebViewStartup;
  0044 move-result-object v4
  0046 iget-object v5, v2, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  004a invoke-static v5, Lcom/personal/aihub/PreviewActivity;->access$000(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/WebViewStartup;
  0050 move-result-object v5
  0052 invoke-virtual v5, Lcom/personal/aihub/WebViewStartup;->epoch()J
  0058 move-result-wide v0
  005a const-string v5, "Could not open the animation screen. Try again or copy a startup report."
  005e invoke-virtual v4, v3, v0, v1, v5, Lcom/personal/aihub/WebViewStartup;->failed(Landroid/webkit/WebView; J Ljava/lang/String;)V
  0064 return-void 
.end method

.method onReceivedHttpError(Landroid/webkit/WebView; Landroid/webkit/WebResourceRequest; Landroid/webkit/WebResourceResponse;)V
  0000 invoke-virtual v5, Landroid/webkit/WebResourceResponse;->getStatusCode()I
  0006 move-result v5
  0008 const/16 v0, 503
  000c if-ne v5, v0, +039h
  0010 invoke-interface v4, Landroid/webkit/WebResourceRequest;->getUrl()Landroid/net/Uri;
  0016 move-result-object v4
  0018 invoke-virtual v4, Landroid/net/Uri;->getPath()Ljava/lang/String;
  001e move-result-object v4
  0020 if-eqz v4, +02fh
  0024 const-string v5, "/account/"
  0028 invoke-virtual v4, v5, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  002e move-result v5
  0030 if-eqz v5, +003h
  0034 goto +25h
  0036 const-string v5, "/_forge/stage-"
  003a invoke-virtual v4, v5, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0040 move-result v4
  0042 if-eqz v4, +005h
  0046 const-string v4, "The recording could not be captured or saved. Check the player message, then try again."
  004a goto +eh
  004c iget-object v4, v2, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->val$cache Lcom/personal/aihub/PreviewCache;
  0050 invoke-virtual v4, Lcom/personal/aihub/PreviewCache;->offline()Z
  0056 move-result v4
  0058 if-eqz v4, +005h
  005c const-string v4, "A file needed for this preview is not saved on this device. Turn off Offline preview in Animation Studio, then load the animation again."
  0060 goto +3h
  0062 const-string v4, "A preview file could not be loaded. Check your connection or import the matching game assets, then retry. Player tools show the details."
  0066 iget-object v5, v2, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  006a iget-object v0, v2, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->val$status Landroid/widget/TextView;
  006e new-instance v1, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$1;
  0072 invoke-direct v1, v2, v3, v0, v4, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$1;-><init>(Lcom/personal/aihub/PreviewActivity$AnonymousClass1; Landroid/webkit/WebView; Landroid/widget/TextView; Ljava/lang/String;)V
  0078 invoke-virtual v5, v1, Lcom/personal/aihub/PreviewActivity;->runOnUiThread(Ljava/lang/Runnable;)V
  007e return-void 
.end method

.method onRenderProcessGone(Landroid/webkit/WebView; Landroid/webkit/RenderProcessGoneDetail;)Z
  0000 iget-object v3, v1, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0004 invoke-static v3, Lcom/personal/aihub/PreviewActivity;->access$000(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/WebViewStartup;
  000a move-result-object v3
  000c if-eqz v3, +00bh
  0010 iget-object v3, v1, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0014 invoke-static v3, Lcom/personal/aihub/PreviewActivity;->access$000(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/WebViewStartup;
  001a move-result-object v3
  001c invoke-virtual v3, Lcom/personal/aihub/WebViewStartup;->close()V
  0022 invoke-virtual v2, Landroid/webkit/WebView;->getParent()Landroid/view/ViewParent;
  0028 move-result-object v3
  002a instance-of v3, v3, Landroid/view/ViewGroup;
  002e if-eqz v3, +00bh
  0032 invoke-virtual v2, Landroid/webkit/WebView;->getParent()Landroid/view/ViewParent;
  0038 move-result-object v3
  003a check-cast v3, Landroid/view/ViewGroup;
  003e invoke-virtual v3, v2, Landroid/view/ViewGroup;->removeView(Landroid/view/View;)V
  0044 invoke-virtual v2, Landroid/webkit/WebView;->destroy()V
  004a iget-object v2, v1, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  004e const/4 v3, 0
  0050 invoke-static v2, v3, Lcom/personal/aihub/PreviewActivity;->access$402(Lcom/personal/aihub/PreviewActivity; Landroid/webkit/WebView;)Landroid/webkit/WebView;
  0056 iget-object v2, v1, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  005a invoke-virtual v2, Lcom/personal/aihub/PreviewActivity;->stopServer()V
  0060 iget-object v2, v1, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0064 new-instance v3, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$2;
  0068 invoke-direct v3, v1, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$2;-><init>(Lcom/personal/aihub/PreviewActivity$AnonymousClass1;)V
  006e const-string v0, "animation preview"
  0072 invoke-static v2, v0, v3, Lcom/personal/aihub/WebViewFailure;->show(Landroid/app/Activity; Ljava/lang/String; Ljava/lang/Runnable;)V
  0078 const/4 v2, 1
  007a return v2
.end method

.method shouldInterceptRequest(Landroid/webkit/WebView; Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;
  0000 iget-object v8, v7, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0004 invoke-static v8, Lcom/personal/aihub/PreviewActivity;->access$100(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/PreviewServer;
  000a move-result-object v8
  000c if-eqz v8, +019h
  0010 iget-object v8, v7, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0014 invoke-static v8, Lcom/personal/aihub/PreviewActivity;->access$100(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/PreviewServer;
  001a move-result-object v8
  001c invoke-interface v9, Landroid/webkit/WebResourceRequest;->getUrl()Landroid/net/Uri;
  0022 move-result-object v9
  0024 invoke-virtual v9, Landroid/net/Uri;->toString()Ljava/lang/String;
  002a move-result-object v9
  002c invoke-virtual v8, v9, Lcom/personal/aihub/PreviewServer;->local(Ljava/lang/String;)Z
  0032 move-result v8
  0034 if-nez v8, +003h
  0038 goto +3h
  003a const/4 v8, 0
  003c return-object v8
  003e new-instance v8, Landroid/webkit/WebResourceResponse;
  0042 const-string v9, "Cache-Control"
  0046 const-string v0, "no-store"
  004a invoke-static v9, v0, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  0050 move-result-object v5
  0052 new-instance v6, Ljava/io/ByteArrayInputStream;
  0056 const-string v9, "Preview requests must use the isolated local player."
  005a sget-object v0, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  005e invoke-virtual v9, v0, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0064 move-result-object v9
  0066 invoke-direct v6, v9, Ljava/io/ByteArrayInputStream;-><init>([B)V
  006c const-string v1, "text/plain"
  0070 const-string v2, "UTF-8"
  0074 const/16 v3, 403
  0078 const-string v4, "Blocked"
  007c move-object v0, v8
  007e invoke-direct/range v0 ... v6, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String; Ljava/lang/String; I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)V
  0084 return-object v8
.end method

.method shouldOverrideUrlLoading(Landroid/webkit/WebView; Landroid/webkit/WebResourceRequest;)Z
  0000 iget-object v1, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0004 invoke-static v1, Lcom/personal/aihub/PreviewActivity;->access$100(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/PreviewServer;
  000a move-result-object v1
  000c if-eqz v1, +019h
  0010 iget-object v1, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0014 invoke-static v1, Lcom/personal/aihub/PreviewActivity;->access$100(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/PreviewServer;
  001a move-result-object v1
  001c invoke-interface v2, Landroid/webkit/WebResourceRequest;->getUrl()Landroid/net/Uri;
  0022 move-result-object v2
  0024 invoke-virtual v2, Landroid/net/Uri;->toString()Ljava/lang/String;
  002a move-result-object v2
  002c invoke-virtual v1, v2, Lcom/personal/aihub/PreviewServer;->local(Ljava/lang/String;)Z
  0032 move-result v1
  0034 if-nez v1, +003h
  0038 goto +3h
  003a const/4 v1, 0
  003c goto +2h
  003e const/4 v1, 1
  0040 return v1
.end method