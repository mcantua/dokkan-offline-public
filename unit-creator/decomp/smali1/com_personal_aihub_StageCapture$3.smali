.class Lcom/personal/aihub/StageCapture$3;
.super Ljava/lang/Object;
.field this$0 Lcom/personal/aihub/StageCapture;
.field val$bitmapCreateBitmap Landroid/graphics/Bitmap;
.field val$completableFuture Ljava/util/concurrent/CompletableFuture;

.method <init>(Lcom/personal/aihub/StageCapture; Landroid/graphics/Bitmap; Ljava/util/concurrent/CompletableFuture;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/StageCapture$3;->this$0 Lcom/personal/aihub/StageCapture;
  0004 iput-object v2, v0, Lcom/personal/aihub/StageCapture$3;->val$bitmapCreateBitmap Landroid/graphics/Bitmap;
  0008 iput-object v3, v0, Lcom/personal/aihub/StageCapture$3;->val$completableFuture Ljava/util/concurrent/CompletableFuture;
  000c invoke-direct v0, Ljava/lang/Object;-><init>()V
  0012 return-void 
.end method

.method onPixelCopyFinished(I)V
  0000 iget-object v0, v3, Lcom/personal/aihub/StageCapture$3;->this$0 Lcom/personal/aihub/StageCapture;
  0004 iget-object v1, v3, Lcom/personal/aihub/StageCapture$3;->val$bitmapCreateBitmap Landroid/graphics/Bitmap;
  0008 iget-object v2, v3, Lcom/personal/aihub/StageCapture$3;->val$completableFuture Ljava/util/concurrent/CompletableFuture;
  000c invoke-virtual v0, v1, v2, v4, Lcom/personal/aihub/StageCapture;->m38lambda$2$compersonalaihubStageCapture(Landroid/graphics/Bitmap; Ljava/util/concurrent/CompletableFuture; I)V
  0012 return-void 
.end method