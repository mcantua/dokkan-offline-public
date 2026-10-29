.class Lcom/personal/aihub/WebViewFailure$2;
.super Ljava/lang/Object;
.field val$activity Landroid/app/Activity;

.method <init>(Landroid/app/Activity;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/WebViewFailure$2;->val$activity Landroid/app/Activity;
  0004 invoke-direct v0, Ljava/lang/Object;-><init>()V
  000a return-void 
.end method

.method onClick(Landroid/view/View;)V
  0000 iget-object v1, v0, Lcom/personal/aihub/WebViewFailure$2;->val$activity Landroid/app/Activity;
  0004 invoke-virtual v1, Landroid/app/Activity;->finish()V
  000a return-void 
.end method