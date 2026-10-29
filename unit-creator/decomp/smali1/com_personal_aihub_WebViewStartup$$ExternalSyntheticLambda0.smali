.class Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda0;
.super Ljava/lang/Object;
.field f$0 Lcom/personal/aihub/WebViewStartup;
.field f$1 Landroid/webkit/WebView;
.field f$2 J

.method <init>(Lcom/personal/aihub/WebViewStartup; Landroid/webkit/WebView; J)V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 iput-object v1, v0, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda0;->f$0 Lcom/personal/aihub/WebViewStartup;
  000a iput-object v2, v0, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda0;->f$1 Landroid/webkit/WebView;
  000e iput-wide v3, v0, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda0;->f$2 J
  0012 return-void 
.end method

.method onReceiveValue(Ljava/lang/Object;)V
  0000 iget-object v0, v4, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda0;->f$0 Lcom/personal/aihub/WebViewStartup;
  0004 iget-object v1, v4, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda0;->f$1 Landroid/webkit/WebView;
  0008 iget-wide v2, v4, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda0;->f$2 J
  000c check-cast v5, Ljava/lang/String;
  0010 invoke-virtual v0, v1, v2, v3, v5, Lcom/personal/aihub/WebViewStartup;->lambda$probeWorkspace$5$com-personal-aihub-WebViewStartup(Landroid/webkit/WebView; J Ljava/lang/String;)V
  0016 return-void 
.end method