.class Lcom/personal/aihub/PreviewCache$1;
.super Ljava/io/FilterInputStream;
.field left J
.field this$0 Lcom/personal/aihub/PreviewCache;
.field val$length J

.method <init>(Lcom/personal/aihub/PreviewCache; Ljava/io/InputStream; J)V
  0000 iput-object v1, v0, Lcom/personal/aihub/PreviewCache$1;->this$0 Lcom/personal/aihub/PreviewCache;
  0004 iput-wide v3, v0, Lcom/personal/aihub/PreviewCache$1;->val$length J
  0008 invoke-direct v0, v2, Ljava/io/FilterInputStream;-><init>(Ljava/io/InputStream;)V
  000e iput-wide v3, v0, Lcom/personal/aihub/PreviewCache$1;->left J
  0012 return-void 
.end method

.method read()I
  0000 iget-wide v0, v5, Lcom/personal/aihub/PreviewCache$1;->left J
  0004 const-wide/16 v2, 0
  0008 cmp-long v0, v0, v2
  000c const/4 v1, -1
  000e if-gtz v0, +003h
  0012 return v1
  0014 invoke-super v5, Ljava/io/FilterInputStream;->read()I
  001a move-result v0
  001c if-eq v0, v1, +009h
  0020 iget-wide v1, v5, Lcom/personal/aihub/PreviewCache$1;->left J
  0024 const-wide/16 v3, 1
  0028 sub-long/2addr v1, v3
  002a iput-wide v1, v5, Lcom/personal/aihub/PreviewCache$1;->left J
  002e return v0
.end method

.method read([B I I)I
  0000 if-nez v8, +004h
  0004 const/4 v6, 0
  0006 return v6
  0008 iget-wide v0, v5, Lcom/personal/aihub/PreviewCache$1;->left J
  000c const-wide/16 v2, 0
  0010 cmp-long v0, v0, v2
  0014 if-gtz v0, +004h
  0018 const/4 v6, -1
  001a return v6
  001c iget-object v0, v5, Lcom/personal/aihub/PreviewCache$1;->in Ljava/io/InputStream;
  0020 int-to-long v1, v8
  0022 iget-wide v3, v5, Lcom/personal/aihub/PreviewCache$1;->left J
  0026 invoke-static v1, v2, v3, v4, Ljava/lang/Math;->min(J J)J
  002c move-result-wide v1
  002e long-to-int v8, v1
  0030 invoke-virtual v0, v6, v7, v8, Ljava/io/InputStream;->read([B I I)I
  0036 move-result v6
  0038 if-lez v6, +008h
  003c iget-wide v7, v5, Lcom/personal/aihub/PreviewCache$1;->left J
  0040 int-to-long v0, v6
  0042 sub-long/2addr v7, v0
  0044 iput-wide v7, v5, Lcom/personal/aihub/PreviewCache$1;->left J
  0048 return v6
.end method