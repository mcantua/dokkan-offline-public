.class Lcom/personal/aihub/AiHandoff$$ExternalSyntheticLambda0;
.super Ljava/lang/Object;
.field f$0 Landroid/app/Activity;
.field f$1 Ljava/lang/String;
.field f$2 Lcom/personal/aihub/Provider;
.field f$3 Ljava/util/concurrent/atomic/AtomicReference;
.field f$4 Ljava/util/concurrent/atomic/AtomicReference;
.field f$5 Ljava/util/concurrent/CountDownLatch;

.method <init>(Landroid/app/Activity; Ljava/lang/String; Lcom/personal/aihub/Provider; Ljava/util/concurrent/atomic/AtomicReference; Ljava/util/concurrent/atomic/AtomicReference; Ljava/util/concurrent/CountDownLatch;)V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 iput-object v1, v0, Lcom/personal/aihub/AiHandoff$$ExternalSyntheticLambda0;->f$0 Landroid/app/Activity;
  000a iput-object v2, v0, Lcom/personal/aihub/AiHandoff$$ExternalSyntheticLambda0;->f$1 Ljava/lang/String;
  000e iput-object v3, v0, Lcom/personal/aihub/AiHandoff$$ExternalSyntheticLambda0;->f$2 Lcom/personal/aihub/Provider;
  0012 iput-object v4, v0, Lcom/personal/aihub/AiHandoff$$ExternalSyntheticLambda0;->f$3 Ljava/util/concurrent/atomic/AtomicReference;
  0016 iput-object v5, v0, Lcom/personal/aihub/AiHandoff$$ExternalSyntheticLambda0;->f$4 Ljava/util/concurrent/atomic/AtomicReference;
  001a iput-object v6, v0, Lcom/personal/aihub/AiHandoff$$ExternalSyntheticLambda0;->f$5 Ljava/util/concurrent/CountDownLatch;
  001e return-void 
.end method

.method run()V
  0000 iget-object v0, v6, Lcom/personal/aihub/AiHandoff$$ExternalSyntheticLambda0;->f$0 Landroid/app/Activity;
  0004 iget-object v1, v6, Lcom/personal/aihub/AiHandoff$$ExternalSyntheticLambda0;->f$1 Ljava/lang/String;
  0008 iget-object v2, v6, Lcom/personal/aihub/AiHandoff$$ExternalSyntheticLambda0;->f$2 Lcom/personal/aihub/Provider;
  000c iget-object v3, v6, Lcom/personal/aihub/AiHandoff$$ExternalSyntheticLambda0;->f$3 Ljava/util/concurrent/atomic/AtomicReference;
  0010 iget-object v4, v6, Lcom/personal/aihub/AiHandoff$$ExternalSyntheticLambda0;->f$4 Ljava/util/concurrent/atomic/AtomicReference;
  0014 iget-object v5, v6, Lcom/personal/aihub/AiHandoff$$ExternalSyntheticLambda0;->f$5 Ljava/util/concurrent/CountDownLatch;
  0018 invoke-static/range v0 ... v5, Lcom/personal/aihub/AiHandoff;->lambda$compose$0(Landroid/app/Activity; Ljava/lang/String; Lcom/personal/aihub/Provider; Ljava/util/concurrent/atomic/AtomicReference; Ljava/util/concurrent/atomic/AtomicReference; Ljava/util/concurrent/CountDownLatch;)V
  001e return-void 
.end method