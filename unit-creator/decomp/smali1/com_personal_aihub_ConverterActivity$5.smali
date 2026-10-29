.class Lcom/personal/aihub/ConverterActivity$5;
.super Landroid/webkit/WebChromeClient;
.field this$0 Lcom/personal/aihub/ConverterActivity;

.method <init>(Lcom/personal/aihub/ConverterActivity;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/ConverterActivity$5;->this$0 Lcom/personal/aihub/ConverterActivity;
  0004 invoke-direct v0, Landroid/webkit/WebChromeClient;-><init>()V
  000a return-void 
.end method

.method onShowFileChooser(Landroid/webkit/WebView; Landroid/webkit/ValueCallback; Landroid/webkit/WebChromeClient$FileChooserParams;)Z
  0000 invoke-virtual v2, Landroid/webkit/WebView;->getUrl()Ljava/lang/String;
  0006 move-result-object v4
  0008 if-nez v4, +005h
  000c const-string v2, ""
  0010 goto +5h
  0012 invoke-virtual v2, Landroid/webkit/WebView;->getUrl()Ljava/lang/String;
  0018 move-result-object v2
  001a invoke-static v2, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  0020 move-result-object v2
  0022 const-string v4, "https"
  0026 invoke-virtual v2, Landroid/net/Uri;->getScheme()Ljava/lang/String;
  002c move-result-object v0
  002e invoke-virtual v4, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0034 move-result v4
  0036 const/4 v0, 1
  0038 if-eqz v4, +04ch
  003c const-string v4, "dokkan-eclipse.com"
  0040 invoke-virtual v2, Landroid/net/Uri;->getHost()Ljava/lang/String;
  0046 move-result-object v2
  0048 invoke-virtual v4, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  004e move-result v2
  0050 if-eqz v2, +040h
  0054 new-instance v2, Ljava/lang/StringBuilder;
  0058 const-string v4, "content://"
  005c invoke-direct v2, v4, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0062 iget-object v4, v1, Lcom/personal/aihub/ConverterActivity$5;->this$0 Lcom/personal/aihub/ConverterActivity;
  0066 invoke-virtual v4, Lcom/personal/aihub/ConverterActivity;->getPackageName()Ljava/lang/String;
  006c move-result-object v4
  006e invoke-virtual v2, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0074 const-string v4, ".patch/"
  0078 invoke-virtual v2, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  007e iget-object v4, v1, Lcom/personal/aihub/ConverterActivity$5;->this$0 Lcom/personal/aihub/ConverterActivity;
  0082 invoke-static v4, Lcom/personal/aihub/ConverterActivity;->access$000(Lcom/personal/aihub/ConverterActivity;)Ljava/lang/String;
  0088 move-result-object v4
  008a invoke-virtual v2, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0090 const-string v4, "/unit-patch.zip"
  0094 invoke-virtual v2, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  009a invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00a0 move-result-object v2
  00a2 invoke-static v2, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  00a8 move-result-object v2
  00aa filled-new-array v2, [Landroid/net/Uri;
  00b0 move-result-object v2
  00b2 invoke-interface v3, v2, Landroid/webkit/ValueCallback;->onReceiveValue(Ljava/lang/Object;)V
  00b8 iget-object v2, v1, Lcom/personal/aihub/ConverterActivity$5;->this$0 Lcom/personal/aihub/ConverterActivity;
  00bc invoke-static v2, Lcom/personal/aihub/ConverterActivity;->access$100(Lcom/personal/aihub/ConverterActivity;)Landroid/widget/TextView;
  00c2 move-result-object v2
  00c4 const-string v3, "Patch ZIP attached. Choose Convert Zip to ECLP, then its download link."
  00c8 invoke-virtual v2, v3, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  00ce return v0
  00d0 const/4 v2, 0
  00d2 invoke-interface v3, v2, Landroid/webkit/ValueCallback;->onReceiveValue(Ljava/lang/Object;)V
  00d8 return v0
.end method