.class Lcom/personal/aihub/CpkArchive$Bits;
.super Ljava/lang/Object;
.field bytes [B
.field cache I
.field pool I
.field source I

.method <init>([B I)V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 iput-object v1, v0, Lcom/personal/aihub/CpkArchive$Bits;->bytes [B
  000a iput v2, v0, Lcom/personal/aihub/CpkArchive$Bits;->source I
  000e return-void 
.end method

.method take(I)I
  0000 const/4 v0, 0
  0002 if-lez v7, +03dh
  0006 iget v1, v6, Lcom/personal/aihub/CpkArchive$Bits;->pool I
  000a if-nez v1, +020h
  000e iget v1, v6, Lcom/personal/aihub/CpkArchive$Bits;->source I
  0012 const/16 v2, 16
  0016 if-lt v1, v2, +013h
  001a iget-object v2, v6, Lcom/personal/aihub/CpkArchive$Bits;->bytes [B
  001e add-int/lit8 v3, v1, -1
  0022 iput v3, v6, Lcom/personal/aihub/CpkArchive$Bits;->source I
  0026 aget-byte v1, v2, v1
  002a and-int/lit16 v1, v1, 255
  002e iput v1, v6, Lcom/personal/aihub/CpkArchive$Bits;->cache I
  0032 const/16 v1, 8
  0036 iput v1, v6, Lcom/personal/aihub/CpkArchive$Bits;->pool I
  003a goto +8h
  003c const-string v7, "Truncated CRILAYLA bit stream"
  0040 invoke-static v7, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  0046 move-result-object v7
  0048 throw v7
  004a iget v1, v6, Lcom/personal/aihub/CpkArchive$Bits;->pool I
  004e invoke-static v7, v1, Ljava/lang/Math;->min(I I)I
  0054 move-result v1
  0056 shl-int/2addr v0, v1
  0058 iget v2, v6, Lcom/personal/aihub/CpkArchive$Bits;->cache I
  005c iget v3, v6, Lcom/personal/aihub/CpkArchive$Bits;->pool I
  0060 sub-int v4, v3, v1
  0064 shr-int/2addr v2, v4
  0066 const/4 v4, 1
  0068 shl-int v5, v4, v1
  006c sub-int/2addr v5, v4
  006e and-int/2addr v2, v5
  0070 or-int/2addr v0, v2
  0072 sub-int/2addr v3, v1
  0074 iput v3, v6, Lcom/personal/aihub/CpkArchive$Bits;->pool I
  0078 sub-int/2addr v7, v1
  007a goto -3ch
  007c return v0
.end method