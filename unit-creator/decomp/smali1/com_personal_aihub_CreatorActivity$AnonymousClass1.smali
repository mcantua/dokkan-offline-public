.class Lcom/personal/aihub/CreatorActivity$AnonymousClass1;
.super Landroid/webkit/WebViewClient;
.field this$0 Lcom/personal/aihub/CreatorActivity;

.method <init>(Lcom/personal/aihub/CreatorActivity;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/CreatorActivity;
  0004 invoke-direct v0, Landroid/webkit/WebViewClient;-><init>()V
  000a return-void 
.end method

.method m18lambda$0$compersonalaihubCreatorActivity$1()V
  0000 iget-object v0, v1, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/CreatorActivity;
  0004 invoke-virtual v0, Lcom/personal/aihub/CreatorActivity;->recreate()V
  000a return-void 
.end method

.method onPageFinished(Landroid/webkit/WebView; Ljava/lang/String;)V
  0000 iget-object v0, v1, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/CreatorActivity;
  0004 invoke-static v0, Lcom/personal/aihub/CreatorActivity;->access$000(Lcom/personal/aihub/CreatorActivity;)Lcom/personal/aihub/WebViewStartup;
  000a move-result-object v0
  000c if-eqz v0, +01bh
  0010 invoke-static v3, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  0016 move-result-object v3
  0018 invoke-virtual v3, Landroid/net/Uri;->getHost()Ljava/lang/String;
  001e move-result-object v3
  0020 const-string v0, "forge.local"
  0024 invoke-virtual v0, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  002a move-result v3
  002c if-eqz v3, +00bh
  0030 iget-object v3, v1, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/CreatorActivity;
  0034 invoke-static v3, Lcom/personal/aihub/CreatorActivity;->access$000(Lcom/personal/aihub/CreatorActivity;)Lcom/personal/aihub/WebViewStartup;
  003a move-result-object v3
  003c invoke-virtual v3, v2, Lcom/personal/aihub/WebViewStartup;->workspaceFinished(Landroid/webkit/WebView;)V
  0042 return-void 
.end method

.method onPageStarted(Landroid/webkit/WebView; Ljava/lang/String; Landroid/graphics/Bitmap;)V
  0000 iget-object v3, v0, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/CreatorActivity;
  0004 invoke-static v3, Lcom/personal/aihub/CreatorActivity;->access$000(Lcom/personal/aihub/CreatorActivity;)Lcom/personal/aihub/WebViewStartup;
  000a move-result-object v3
  000c if-eqz v3, +01bh
  0010 invoke-static v2, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  0016 move-result-object v2
  0018 invoke-virtual v2, Landroid/net/Uri;->getHost()Ljava/lang/String;
  001e move-result-object v2
  0020 const-string v3, "forge.local"
  0024 invoke-virtual v3, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  002a move-result v2
  002c if-eqz v2, +00bh
  0030 iget-object v2, v0, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/CreatorActivity;
  0034 invoke-static v2, Lcom/personal/aihub/CreatorActivity;->access$000(Lcom/personal/aihub/CreatorActivity;)Lcom/personal/aihub/WebViewStartup;
  003a move-result-object v2
  003c invoke-virtual v2, v1, Lcom/personal/aihub/WebViewStartup;->begin(Landroid/webkit/WebView;)J
  0042 return-void 
.end method

.method onReceivedError(Landroid/webkit/WebView; Landroid/webkit/WebResourceRequest; Landroid/webkit/WebResourceError;)V
  0000 invoke-interface v4, Landroid/webkit/WebResourceRequest;->isForMainFrame()Z
  0006 move-result v4
  0008 if-eqz v4, +01fh
  000c iget-object v4, v2, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/CreatorActivity;
  0010 invoke-static v4, Lcom/personal/aihub/CreatorActivity;->access$000(Lcom/personal/aihub/CreatorActivity;)Lcom/personal/aihub/WebViewStartup;
  0016 move-result-object v4
  0018 if-eqz v4, +017h
  001c iget-object v4, v2, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/CreatorActivity;
  0020 invoke-static v4, Lcom/personal/aihub/CreatorActivity;->access$000(Lcom/personal/aihub/CreatorActivity;)Lcom/personal/aihub/WebViewStartup;
  0026 move-result-object v4
  0028 iget-object v5, v2, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/CreatorActivity;
  002c invoke-static v5, Lcom/personal/aihub/CreatorActivity;->access$000(Lcom/personal/aihub/CreatorActivity;)Lcom/personal/aihub/WebViewStartup;
  0032 move-result-object v5
  0034 invoke-virtual v5, Lcom/personal/aihub/WebViewStartup;->epoch()J
  003a move-result-wide v0
  003c const-string v5, "Could not open the workspace screen. Try again or copy a startup report. Your saved units stay on this device."
  0040 invoke-virtual v4, v3, v0, v1, v5, Lcom/personal/aihub/WebViewStartup;->failed(Landroid/webkit/WebView; J Ljava/lang/String;)V
  0046 return-void 
.end method

.method onRenderProcessGone(Landroid/webkit/WebView; Landroid/webkit/RenderProcessGoneDetail;)Z
  0000 iget-object v3, v1, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/CreatorActivity;
  0004 invoke-static v3, Lcom/personal/aihub/ForgeFixes;->noteRendererCrash(Landroid/content/Context;)V
  000a invoke-static v3, Lcom/personal/aihub/CreatorActivity;->access$000(Lcom/personal/aihub/CreatorActivity;)Lcom/personal/aihub/WebViewStartup;
  0010 move-result-object v3
  0012 if-eqz v3, +00bh
  0016 iget-object v3, v1, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/CreatorActivity;
  001a invoke-static v3, Lcom/personal/aihub/CreatorActivity;->access$000(Lcom/personal/aihub/CreatorActivity;)Lcom/personal/aihub/WebViewStartup;
  0020 move-result-object v3
  0022 invoke-virtual v3, Lcom/personal/aihub/WebViewStartup;->close()V
  0028 invoke-virtual v2, Landroid/webkit/WebView;->getParent()Landroid/view/ViewParent;
  002e move-result-object v3
  0030 instance-of v3, v3, Landroid/view/ViewGroup;
  0034 if-eqz v3, +00bh
  0038 invoke-virtual v2, Landroid/webkit/WebView;->getParent()Landroid/view/ViewParent;
  003e move-result-object v3
  0040 check-cast v3, Landroid/view/ViewGroup;
  0044 invoke-virtual v3, v2, Landroid/view/ViewGroup;->removeView(Landroid/view/View;)V
  004a invoke-virtual v2, Landroid/webkit/WebView;->destroy()V
  0050 iget-object v2, v1, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/CreatorActivity;
  0054 const/4 v3, 0
  0056 invoke-static v2, v3, Lcom/personal/aihub/CreatorActivity;->access$102(Lcom/personal/aihub/CreatorActivity; Landroid/webkit/WebView;)Landroid/webkit/WebView;
  005c iget-object v2, v1, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/CreatorActivity;
  0060 new-instance v3, Lcom/personal/aihub/CreatorActivity$AnonymousClass1$1;
  0064 invoke-direct v3, v1, Lcom/personal/aihub/CreatorActivity$AnonymousClass1$1;-><init>(Lcom/personal/aihub/CreatorActivity$AnonymousClass1;)V
  006a const-string v0, "creator"
  006e invoke-static v2, v0, v3, Lcom/personal/aihub/WebViewFailure;->show(Landroid/app/Activity; Ljava/lang/String; Ljava/lang/Runnable;)V
  0074 const/4 v2, 1
  0076 return v2
.end method

.method shouldInterceptRequest(Landroid/webkit/WebView; Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;
  0000 invoke-static v12, Lcom/personal/aihub/ForgeFixes;->intercept(Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;
  0006 move-result-object v0
  0008 if-eqz v0, +003h
  000c return-object v0
  000e const-string v11, "ui/"
  0012 invoke-interface v12, Landroid/webkit/WebResourceRequest;->getUrl()Landroid/net/Uri;
  0018 move-result-object v12
  001a const-string v0, "forge.local"
  001e invoke-virtual v12, Landroid/net/Uri;->getHost()Ljava/lang/String;
  0024 move-result-object v1
  0026 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  002c move-result v0
  002e const/4 v1, 0
  0030 if-nez v0, +003h
  0034 return-object v1
  0036 invoke-virtual v12, Landroid/net/Uri;->getPath()Ljava/lang/String;
  003c move-result-object v12
  003e const/4 v0, 1
  0040 invoke-virtual v12, v0, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0046 move-result-object v12
  0048 invoke-virtual v12, Ljava/lang/String;->isEmpty()Z
  004e move-result v0
  0050 if-eqz v0, +004h
  0054 const-string v12, "index.html"
  0058 const-string v0, "local-asset/"
  005c invoke-virtual v12, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0062 move-result v0
  0064 if-nez v0, +057h
  0068 invoke-static v12, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  006e move-result v0
  0070 if-eqz v0, +049h
  0074 const-string v0, "data/"
  0078 invoke-virtual v12, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  007e move-result v0
  0080 if-eqz v0, +02ah
  0084 const-string v0, "data/mechanics.js"
  0088 invoke-virtual v12, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  008e move-result v0
  0090 if-nez v0, +022h
  0094 const-string v0, "data/guide-data.js"
  0098 invoke-virtual v12, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  009e move-result v0
  00a0 if-nez v0, +01ah
  00a4 const-string v0, "data/animation-availability.js"
  00a8 invoke-virtual v12, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00ae move-result v0
  00b0 if-nez v0, +012h
  00b4 const-string v0, "data/movie-catalog.js"
  00b8 invoke-virtual v12, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00be move-result v0
  00c0 if-nez v0, +00ah
  00c4 const-string v0, "data/sparking-reference.json"
  00c8 invoke-virtual v12, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00ce move-result v0
  00d0 if-eqz v0, +019h
  00d4 iget-object v0, v10, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/CreatorActivity;
  00d8 invoke-virtual v0, Lcom/personal/aihub/CreatorActivity;->getAssets()Landroid/content/res/AssetManager;
  00de move-result-object v0
  00e0 new-instance v2, Ljava/lang/StringBuilder;
  00e4 invoke-direct v2, v11, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00ea invoke-virtual v2, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00f0 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00f6 move-result-object v11
  00f8 invoke-virtual v0, v11, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;
  00fe move-result-object v11
  0100 goto +1ah
  0102 new-instance v11, Ljava/io/IOException;
  0106 const-string v12, "Unavailable resource"
  010a invoke-direct v11, v12, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0110 throw v11
  0112 new-instance v11, Ljava/io/FileInputStream;
  0116 iget-object v0, v10, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/CreatorActivity;
  011a const/16 v2, 12
  011e invoke-virtual v12, v2, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0124 move-result-object v2
  0126 invoke-virtual v0, v2, Lcom/personal/aihub/CreatorActivity;->assetFile(Ljava/lang/String;)Ljava/io/File;
  012c move-result-object v0
  012e invoke-direct v11, v0, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0134 new-instance v0, Landroid/webkit/WebResourceResponse;
  0138 invoke-static v12, Lcom/personal/aihub/CreatorActivity;->mime(Ljava/lang/String;)Ljava/lang/String;
  013e move-result-object v2
  0140 invoke-static v12, Lcom/personal/aihub/CreatorActivity;->mime(Ljava/lang/String;)Ljava/lang/String;
  0146 move-result-object v3
  0148 const-string v4, "text/"
  014c invoke-virtual v3, v4, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0152 move-result v3
  0154 if-nez v3, +00ah
  0158 const-string v3, ".js"
  015c invoke-virtual v12, v3, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  0162 move-result v12
  0164 if-eqz v12, +004h
  0168 const-string v1, "UTF-8"
  016c invoke-direct v0, v2, v1, v11, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String; Ljava/lang/String; Ljava/io/InputStream;)V
  0172 return-object v0
  0174 new-instance v11, Landroid/webkit/WebResourceResponse;
  0178 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  017e move-result-object v8
  0180 new-instance v9, Ljava/io/ByteArrayInputStream;
  0184 const/4 v12, 0
  0186 new-array v12, v12, [B
  018a invoke-direct v9, v12, Ljava/io/ByteArrayInputStream;-><init>([B)V
  0190 const-string v4, "text/plain"
  0194 const-string v5, "UTF-8"
  0198 const/16 v6, 404
  019c const-string v7, "Not Found"
  01a0 move-object v3, v11
  01a2 invoke-direct/range v3 ... v9, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String; Ljava/lang/String; I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)V
  01a8 return-object v11
.end method

.method shouldOverrideUrlLoading(Landroid/webkit/WebView; Landroid/webkit/WebResourceRequest;)Z
  0000 invoke-interface v2, Landroid/webkit/WebResourceRequest;->getUrl()Landroid/net/Uri;
  0006 move-result-object v1
  0008 invoke-virtual v1, Landroid/net/Uri;->getHost()Ljava/lang/String;
  000e move-result-object v1
  0010 const-string v2, "forge.local"
  0014 invoke-virtual v2, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  001a move-result v1
  001c xor-int/lit8 v1, v1, 1
  0020 return v1
.end method