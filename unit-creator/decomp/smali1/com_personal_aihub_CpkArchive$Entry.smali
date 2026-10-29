.class Lcom/personal/aihub/CpkArchive$Entry;
.super Ljava/lang/Object;
.field offset J
.field path Ljava/lang/String;
.field size I
.field storedSize I

.method <init>(Ljava/lang/String; J I I)V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 iput-object v1, v0, Lcom/personal/aihub/CpkArchive$Entry;->path Ljava/lang/String;
  000a iput-wide v2, v0, Lcom/personal/aihub/CpkArchive$Entry;->offset J
  000e iput v4, v0, Lcom/personal/aihub/CpkArchive$Entry;->storedSize I
  0012 iput v5, v0, Lcom/personal/aihub/CpkArchive$Entry;->size I
  0016 return-void 
.end method