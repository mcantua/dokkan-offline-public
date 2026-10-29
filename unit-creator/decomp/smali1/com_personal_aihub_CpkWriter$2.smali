.class Lcom/personal/aihub/CpkWriter$2;
.super Ljava/lang/Object;

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method compare(Ljava/lang/Object; Ljava/lang/Object;)I
  0000 check-cast v1, Lcom/personal/aihub/CpkWriter$Source;
  0004 iget-object v1, v1, Lcom/personal/aihub/CpkWriter$Source;->path Ljava/lang/String;
  0008 check-cast v2, Lcom/personal/aihub/CpkWriter$Source;
  000c iget-object v2, v2, Lcom/personal/aihub/CpkWriter$Source;->path Ljava/lang/String;
  0010 invoke-static v1, v2, Lcom/personal/aihub/CpkWriter;->compareCriPaths(Ljava/lang/String; Ljava/lang/String;)I
  0016 move-result v1
  0018 return v1
.end method