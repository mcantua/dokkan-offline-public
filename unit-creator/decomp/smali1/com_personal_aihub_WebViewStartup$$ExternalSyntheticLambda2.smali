.class Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda2;
.super Ljava/lang/Object;
.field f$0 Lcom/personal/aihub/WebViewStartup;
.field f$1 Ljava/lang/Runnable;

.method <init>(Lcom/personal/aihub/WebViewStartup; Ljava/lang/Runnable;)V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 iput-object v1, v0, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda2;->f$0 Lcom/personal/aihub/WebViewStartup;
  000a iput-object v2, v0, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda2;->f$1 Ljava/lang/Runnable;
  000e return-void 
.end method

.method run()V
  0000 iget-object v0, v2, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda2;->f$0 Lcom/personal/aihub/WebViewStartup;
  0004 iget-object v1, v2, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda2;->f$1 Ljava/lang/Runnable;
  0008 invoke-virtual v0, v1, Lcom/personal/aihub/WebViewStartup;->lambda$new$0$com-personal-aihub-WebViewStartup(Ljava/lang/Runnable;)V
  000e return-void 
.end method