.class Lcom/personal/aihub/ConverterActivity$AnonymousClass1;
.super Landroid/webkit/WebViewClient;
.field this$0 Lcom/personal/aihub/ConverterActivity;

.method <init>(Lcom/personal/aihub/ConverterActivity;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/ConverterActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/ConverterActivity;
  0004 invoke-direct v0, Landroid/webkit/WebViewClient;-><init>()V
  000a return-void 
.end method

.method m7lambda$0$compersonalaihubConverterActivity$1()V
  0000 iget-object v0, v1, Lcom/personal/aihub/ConverterActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/ConverterActivity;
  0004 invoke-virtual v0, Lcom/personal/aihub/ConverterActivity;->recreate()V
  000a return-void 
.end method

.method onPageFinished(Landroid/webkit/WebView; Ljava/lang/String;)V
  0000 invoke-static v6, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  0006 move-result-object v5
  0008 invoke-virtual v5, Landroid/net/Uri;->getScheme()Ljava/lang/String;
  000e move-result-object v5
  0010 const-string v0, "https"
  0014 invoke-virtual v0, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  001a move-result v5
  001c if-eqz v5, +097h
  0020 invoke-static v6, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  0026 move-result-object v5
  0028 invoke-virtual v5, Landroid/net/Uri;->getHost()Ljava/lang/String;
  002e move-result-object v5
  0030 const-string v6, "dokkan-eclipse.com"
  0034 invoke-virtual v6, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  003a move-result v5
  003c if-nez v5, +004h
  0040 goto/16 +085h
  0044 iget-object v5, v4, Lcom/personal/aihub/ConverterActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/ConverterActivity;
  0048 invoke-virtual v5, Lcom/personal/aihub/ConverterActivity;->getAssets()Landroid/content/res/AssetManager;
  004e move-result-object v5
  0050 const-string v6, "ui/converter-page.js"
  0054 invoke-virtual v5, v6, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;
  005a move-result-object v5
  005c new-instance v6, Ljava/io/ByteArrayOutputStream;
  0060 invoke-direct v6, Ljava/io/ByteArrayOutputStream;-><init>()V
  0066 const/16 v0, 8192
  006a new-array v0, v0, [B
  006e invoke-virtual v5, v0, Ljava/io/InputStream;->read([B)I
  0074 move-result v1
  0076 const/4 v2, -1
  0078 if-eq v1, v2, +007h
  007c const/4 v2, 0
  007e invoke-virtual v6, v0, v2, v1, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  0084 goto -bh
  0086 iget-object v0, v4, Lcom/personal/aihub/ConverterActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/ConverterActivity;
  008a invoke-static v0, Lcom/personal/aihub/ConverterActivity;->access$200(Lcom/personal/aihub/ConverterActivity;)Landroid/webkit/WebView;
  0090 move-result-object v0
  0092 new-instance v1, Ljava/lang/StringBuilder;
  0096 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  009c const-string v2, "window.__forgePatch="
  00a0 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00a6 new-instance v2, Lorg/json/JSONObject;
  00aa iget-object v3, v4, Lcom/personal/aihub/ConverterActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/ConverterActivity;
  00ae invoke-static v3, Lcom/personal/aihub/ConverterActivity;->access$300(Lcom/personal/aihub/ConverterActivity;)Ljava/lang/String;
  00b4 move-result-object v3
  00b6 invoke-direct v2, v3, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  00bc invoke-virtual v2, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  00c2 move-result-object v2
  00c4 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00ca const-string v2, ";"
  00ce invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00d4 const-string v2, "UTF-8"
  00d8 invoke-virtual v6, v2, Ljava/io/ByteArrayOutputStream;->toString(Ljava/lang/String;)Ljava/lang/String;
  00de move-result-object v2
  00e0 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00e6 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00ec move-result-object v1
  00ee const/4 v2, 0
  00f0 invoke-virtual v0, v1, v2, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String; Landroid/webkit/ValueCallback;)V
  00f6 invoke-virtual v6, Ljava/io/ByteArrayOutputStream;->close()V
  00fc if-eqz v5, +027h
  0100 invoke-virtual v5, Ljava/io/InputStream;->close()V
  0106 goto +22h
  0108 move-exception v0
  010a invoke-virtual v6, Ljava/io/ByteArrayOutputStream;->close()V
  0110 goto +5h
  0112 move-exception v6
  0114 invoke-virtual v0, v6, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  011a throw v0
  011c move-exception v6
  011e if-eqz v5, +00ah
  0122 invoke-virtual v5, Ljava/io/InputStream;->close()V
  0128 goto +5h
  012a move-exception v5
  012c invoke-virtual v6, v5, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0132 throw v6
  0134 iget-object v5, v4, Lcom/personal/aihub/ConverterActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/ConverterActivity;
  0138 invoke-static v5, Lcom/personal/aihub/ConverterActivity;->access$100(Lcom/personal/aihub/ConverterActivity;)Landroid/widget/TextView;
  013e move-result-object v5
  0140 const-string v6, "Choose the patch ZIP and enter its metadata on Eclipse’s converter."
  0144 invoke-virtual v5, v6, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  014a return-void 
.end method

.method onReceivedError(Landroid/webkit/WebView; Landroid/webkit/WebResourceRequest; Landroid/webkit/WebResourceError;)V
  0000 invoke-interface v2, Landroid/webkit/WebResourceRequest;->isForMainFrame()Z
  0006 move-result v1
  0008 if-eqz v1, +00dh
  000c iget-object v1, v0, Lcom/personal/aihub/ConverterActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/ConverterActivity;
  0010 invoke-static v1, Lcom/personal/aihub/ConverterActivity;->access$100(Lcom/personal/aihub/ConverterActivity;)Landroid/widget/TextView;
  0016 move-result-object v1
  0018 const-string v2, "Connection failed. Check Internet access and tap Converter to retry."
  001c invoke-virtual v1, v2, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0022 return-void 
.end method

.method onRenderProcessGone(Landroid/webkit/WebView; Landroid/webkit/RenderProcessGoneDetail;)Z
  0000 invoke-virtual v2, Landroid/webkit/WebView;->getParent()Landroid/view/ViewParent;
  0006 move-result-object v3
  0008 instance-of v3, v3, Landroid/view/ViewGroup;
  000c if-eqz v3, +00bh
  0010 invoke-virtual v2, Landroid/webkit/WebView;->getParent()Landroid/view/ViewParent;
  0016 move-result-object v3
  0018 check-cast v3, Landroid/view/ViewGroup;
  001c invoke-virtual v3, v2, Landroid/view/ViewGroup;->removeView(Landroid/view/View;)V
  0022 invoke-virtual v2, Landroid/webkit/WebView;->destroy()V
  0028 iget-object v2, v1, Lcom/personal/aihub/ConverterActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/ConverterActivity;
  002c const/4 v3, 0
  002e invoke-static v2, v3, Lcom/personal/aihub/ConverterActivity;->access$202(Lcom/personal/aihub/ConverterActivity; Landroid/webkit/WebView;)Landroid/webkit/WebView;
  0034 iget-object v2, v1, Lcom/personal/aihub/ConverterActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/ConverterActivity;
  0038 new-instance v3, Lcom/personal/aihub/ConverterActivity$AnonymousClass1$1;
  003c invoke-direct v3, v1, Lcom/personal/aihub/ConverterActivity$AnonymousClass1$1;-><init>(Lcom/personal/aihub/ConverterActivity$AnonymousClass1;)V
  0042 const-string v0, "converter"
  0046 invoke-static v2, v0, v3, Lcom/personal/aihub/WebViewFailure;->show(Landroid/app/Activity; Ljava/lang/String; Ljava/lang/Runnable;)V
  004c const/4 v2, 1
  004e return v2
.end method

.method shouldOverrideUrlLoading(Landroid/webkit/WebView; Landroid/webkit/WebResourceRequest;)Z
  0000 invoke-interface v2, Landroid/webkit/WebResourceRequest;->getUrl()Landroid/net/Uri;
  0006 move-result-object v1
  0008 invoke-virtual v1, Landroid/net/Uri;->toString()Ljava/lang/String;
  000e move-result-object v1
  0010 const/4 v2, 0
  0012 invoke-static v1, v2, Lcom/personal/aihub/ConverterActivity;->allowed(Ljava/lang/String; Z)Z
  0018 move-result v1
  001a xor-int/lit8 v1, v1, 1
  001e return v1
.end method