.class Lcom/personal/aihub/GameDirectory$$ExternalSyntheticLambda0;
.super Ljava/lang/Object;

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method compare(Ljava/lang/Object; Ljava/lang/Object;)I
  0000 check-cast v1, Ljava/io/File;
  0004 check-cast v2, Ljava/io/File;
  0008 invoke-static v1, v2, Lcom/personal/aihub/GameDirectory;->lambda$0(Ljava/io/File; Ljava/io/File;)I
  000e move-result v1
  0010 return v1
.end method