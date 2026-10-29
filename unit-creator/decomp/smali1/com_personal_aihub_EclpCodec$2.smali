.class Lcom/personal/aihub/EclpCodec$2;
.super Ljava/io/InputStream;
.field val$input Ljava/io/BufferedInputStream;
.field val$remaining [J

.method <init>([J Ljava/io/BufferedInputStream;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/EclpCodec$2;->val$remaining [J
  0004 iput-object v2, v0, Lcom/personal/aihub/EclpCodec$2;->val$input Ljava/io/BufferedInputStream;
  0008 invoke-direct v0, Ljava/io/InputStream;-><init>()V
  000e return-void 
.end method

.method close()V
  0000 return-void 
.end method

.method read()I
  0000 iget-object v0, v7, Lcom/personal/aihub/EclpCodec$2;->val$remaining [J
  0004 const/4 v1, 0
  0006 aget-wide v2, v0, v1
  000a const-wide/16 v4, 0
  000e cmp-long v0, v2, v4
  0012 if-nez v0, +004h
  0016 const/4 v0, -1
  0018 return v0
  001a iget-object v0, v7, Lcom/personal/aihub/EclpCodec$2;->val$input Ljava/io/BufferedInputStream;
  001e invoke-virtual v0, Ljava/io/BufferedInputStream;->read()I
  0024 move-result v0
  0026 if-ltz v0, +00ch
  002a iget-object v2, v7, Lcom/personal/aihub/EclpCodec$2;->val$remaining [J
  002e aget-wide v3, v2, v1
  0032 const-wide/16 v5, 1
  0036 sub-long/2addr v3, v5
  0038 aput-wide v3, v2, v1
  003c return v0
  003e new-instance v0, Ljava/io/EOFException;
  0042 invoke-direct v0, Ljava/io/EOFException;-><init>()V
  0048 throw v0
.end method

.method read([B I I)I
  0000 const/4 v0, 0
  0002 if-nez v9, +003h
  0006 return v0
  0008 iget-object v1, v6, Lcom/personal/aihub/EclpCodec$2;->val$remaining [J
  000c aget-wide v2, v1, v0
  0010 const-wide/16 v4, 0
  0014 cmp-long v1, v2, v4
  0018 if-nez v1, +004h
  001c const/4 v7, -1
  001e return v7
  0020 iget-object v1, v6, Lcom/personal/aihub/EclpCodec$2;->val$input Ljava/io/BufferedInputStream;
  0024 int-to-long v4, v9
  0026 invoke-static v4, v5, v2, v3, Ljava/lang/Math;->min(J J)J
  002c move-result-wide v2
  002e long-to-int v9, v2
  0030 invoke-virtual v1, v7, v8, v9, Ljava/io/BufferedInputStream;->read([B I I)I
  0036 move-result v7
  0038 if-ltz v7, +00bh
  003c iget-object v8, v6, Lcom/personal/aihub/EclpCodec$2;->val$remaining [J
  0040 aget-wide v1, v8, v0
  0044 int-to-long v3, v7
  0046 sub-long/2addr v1, v3
  0048 aput-wide v1, v8, v0
  004c return v7
  004e new-instance v7, Ljava/io/EOFException;
  0052 invoke-direct v7, Ljava/io/EOFException;-><init>()V
  0058 throw v7
.end method