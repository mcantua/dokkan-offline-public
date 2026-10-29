.class Lcom/personal/aihub/StageCapture$1;
.super Ljava/lang/Object;
.field this$0 Lcom/personal/aihub/StageCapture;
.field val$completableFuture Ljava/util/concurrent/CompletableFuture;

.method <init>(Lcom/personal/aihub/StageCapture; Ljava/util/concurrent/CompletableFuture;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/StageCapture$1;->this$0 Lcom/personal/aihub/StageCapture;
  0004 iput-object v2, v0, Lcom/personal/aihub/StageCapture$1;->val$completableFuture Ljava/util/concurrent/CompletableFuture;
  0008 invoke-direct v0, Ljava/lang/Object;-><init>()V
  000e return-void 
.end method

.method run()V
  0000 iget-object v0, v2, Lcom/personal/aihub/StageCapture$1;->this$0 Lcom/personal/aihub/StageCapture;
  0004 iget-object v1, v2, Lcom/personal/aihub/StageCapture$1;->val$completableFuture Ljava/util/concurrent/CompletableFuture;
  0008 invoke-virtual v0, v1, Lcom/personal/aihub/StageCapture;->m36lambda$0$compersonalaihubStageCapture(Ljava/util/concurrent/CompletableFuture;)V
  000e return-void 
.end method