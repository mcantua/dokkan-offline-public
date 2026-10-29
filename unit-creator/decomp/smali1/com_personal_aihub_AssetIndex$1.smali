.class Lcom/personal/aihub/AssetIndex$1;
.super Ljava/lang/Object;

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method apply(Ljava/lang/Object;)Ljava/lang/Object;
  0000 check-cast v1, Ljava/io/File;
  0004 invoke-static v1, Lcom/personal/aihub/AssetIndex;->lambda$0(Ljava/io/File;)Ljava/lang/String;
  000a move-result-object v1
  000c return-object v1
.end method