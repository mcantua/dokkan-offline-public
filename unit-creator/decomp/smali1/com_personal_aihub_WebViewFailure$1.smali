.class Lcom/personal/aihub/WebViewFailure$1;
.super Ljava/lang/Object;
.field val$runnable Ljava/lang/Runnable;

.method <init>(Ljava/lang/Runnable;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/WebViewFailure$1;->val$runnable Ljava/lang/Runnable;
  0004 invoke-direct v0, Ljava/lang/Object;-><init>()V
  000a return-void 
.end method

.method onClick(Landroid/view/View;)V
  0000 iget-object v1, v0, Lcom/personal/aihub/WebViewFailure$1;->val$runnable Ljava/lang/Runnable;
  0004 invoke-interface v1, Ljava/lang/Runnable;->run()V
  000a return-void 
.end method