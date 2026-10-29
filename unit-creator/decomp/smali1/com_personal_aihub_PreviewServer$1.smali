.class Lcom/personal/aihub/PreviewServer$1;
.super Ljava/lang/Object;
.field this$0 Lcom/personal/aihub/PreviewServer;

.method <init>(Lcom/personal/aihub/PreviewServer;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/PreviewServer$1;->this$0 Lcom/personal/aihub/PreviewServer;
  0004 invoke-direct v0, Ljava/lang/Object;-><init>()V
  000a return-void 
.end method

.method newThread(Ljava/lang/Runnable;)Ljava/lang/Thread;
  0000 invoke-static v1, Lcom/personal/aihub/PreviewServer;->lambda$0(Ljava/lang/Runnable;)Ljava/lang/Thread;
  0006 move-result-object v1
  0008 return-object v1
.end method