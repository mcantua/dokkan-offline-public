.class Lcom/personal/aihub/EclpCodec$1;
.super Ljava/io/OutputStream;
.field val$cipher Ljavax/crypto/Cipher;
.field val$output Ljava/io/OutputStream;

.method <init>(Ljavax/crypto/Cipher; Ljava/io/OutputStream;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/EclpCodec$1;->val$cipher Ljavax/crypto/Cipher;
  0004 iput-object v2, v0, Lcom/personal/aihub/EclpCodec$1;->val$output Ljava/io/OutputStream;
  0008 invoke-direct v0, Ljava/io/OutputStream;-><init>()V
  000e return-void 
.end method

.method write(I)V
  0000 int-to-byte v4, v4
  0002 const/4 v0, 1
  0004 new-array v1, v0, [B
  0008 const/4 v2, 0
  000a aput-byte v4, v1, v2
  000e invoke-virtual v3, v1, v2, v0, Lcom/personal/aihub/EclpCodec$1;->write([B I I)V
  0014 return-void 
.end method

.method write([B I I)V
  0000 iget-object v0, v1, Lcom/personal/aihub/EclpCodec$1;->val$cipher Ljavax/crypto/Cipher;
  0004 invoke-virtual v0, v2, v3, v4, Ljavax/crypto/Cipher;->update([B I I)[B
  000a move-result-object v2
  000c if-eqz v2, +007h
  0010 iget-object v3, v1, Lcom/personal/aihub/EclpCodec$1;->val$output Ljava/io/OutputStream;
  0014 invoke-virtual v3, v2, Ljava/io/OutputStream;->write([B)V
  001a return-void 
.end method