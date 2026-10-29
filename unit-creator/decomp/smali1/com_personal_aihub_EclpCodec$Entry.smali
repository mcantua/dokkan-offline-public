.class Lcom/personal/aihub/EclpCodec$Entry;
.super Ljava/lang/Object;
.field file Ljava/io/File;
.field path Ljava/lang/String;
.field text [B

.method <init>(Ljava/lang/String; Ljava/io/File; [B)V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 iput-object v1, v0, Lcom/personal/aihub/EclpCodec$Entry;->path Ljava/lang/String;
  000a iput-object v2, v0, Lcom/personal/aihub/EclpCodec$Entry;->file Ljava/io/File;
  000e iput-object v3, v0, Lcom/personal/aihub/EclpCodec$Entry;->text [B
  0012 return-void 
.end method

.method input()Ljava/io/InputStream;
  0000 iget-object v0, v2, Lcom/personal/aihub/EclpCodec$Entry;->file Ljava/io/File;
  0004 if-nez v0, +00ah
  0008 new-instance v0, Ljava/io/ByteArrayInputStream;
  000c iget-object v1, v2, Lcom/personal/aihub/EclpCodec$Entry;->text [B
  0010 invoke-direct v0, v1, Ljava/io/ByteArrayInputStream;-><init>([B)V
  0016 goto +8h
  0018 new-instance v0, Ljava/io/FileInputStream;
  001c iget-object v1, v2, Lcom/personal/aihub/EclpCodec$Entry;->file Ljava/io/File;
  0020 invoke-direct v0, v1, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0026 return-object v0
.end method

.method size()J
  0000 iget-object v0, v2, Lcom/personal/aihub/EclpCodec$Entry;->file Ljava/io/File;
  0004 if-nez v0, +007h
  0008 iget-object v0, v2, Lcom/personal/aihub/EclpCodec$Entry;->text [B
  000c array-length v0, v0
  000e int-to-long v0, v0
  0010 goto +5h
  0012 invoke-virtual v0, Ljava/io/File;->length()J
  0018 move-result-wide v0
  001a return-wide v0
.end method