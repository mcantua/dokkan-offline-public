.class Lcom/personal/aihub/CpkWriter$Source;
.super Ljava/lang/Object;
.field file Ljava/io/File;
.field key Ljava/lang/String;
.field offset J
.field path Ljava/lang/String;
.field size J

.method <init>(Ljava/lang/String; Ljava/lang/String; Ljava/io/File; J)V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 iput-object v1, v0, Lcom/personal/aihub/CpkWriter$Source;->path Ljava/lang/String;
  000a iput-object v2, v0, Lcom/personal/aihub/CpkWriter$Source;->key Ljava/lang/String;
  000e iput-object v3, v0, Lcom/personal/aihub/CpkWriter$Source;->file Ljava/io/File;
  0012 iput-wide v4, v0, Lcom/personal/aihub/CpkWriter$Source;->size J
  0016 return-void 
.end method