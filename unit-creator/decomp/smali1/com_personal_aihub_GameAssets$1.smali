.class Lcom/personal/aihub/GameAssets$1;
.super Ljava/lang/Object;
.field this$0 Lcom/personal/aihub/GameAssets;

.method <init>(Lcom/personal/aihub/GameAssets;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/GameAssets$1;->this$0 Lcom/personal/aihub/GameAssets;
  0004 invoke-direct v0, Ljava/lang/Object;-><init>()V
  000a return-void 
.end method

.method compare(Ljava/lang/Object; Ljava/lang/Object;)I
  0000 check-cast v1, Ljava/io/File;
  0004 check-cast v2, Ljava/io/File;
  0008 invoke-static v1, v2, Lcom/personal/aihub/GameAssets;->lambda$0(Ljava/io/File; Ljava/io/File;)I
  000e move-result v1
  0010 return v1
.end method