.class Lcom/personal/aihub/SparkingContent$XXH64;
.super Ljava/lang/Object;
.field P1 J
.field P2 J
.field P3 J
.field P4 J
.field P5 J
.field pending [B
.field total J
.field used I
.field v1 J
.field v2 J
.field v3 J
.field v4 J

.method <init>()V
  0000 invoke-direct v2, Ljava/lang/Object;-><init>()V
  0006 const-wide v0, 6983438078262162902
  0010 iput-wide v0, v2, Lcom/personal/aihub/SparkingContent$XXH64;->v1 J
  0014 const-wide v0, -4417276706812531889
  001e iput-wide v0, v2, Lcom/personal/aihub/SparkingContent$XXH64;->v2 J
  0022 const-wide/16 v0, 0
  0026 iput-wide v0, v2, Lcom/personal/aihub/SparkingContent$XXH64;->v3 J
  002a const-wide v0, 7046029288634856825
  0034 iput-wide v0, v2, Lcom/personal/aihub/SparkingContent$XXH64;->v4 J
  0038 const/16 v0, 32
  003c new-array v0, v0, [B
  0040 iput-object v0, v2, Lcom/personal/aihub/SparkingContent$XXH64;->pending [B
  0044 return-void 
.end method

.method block([B I)V
  0000 iget-wide v0, v4, Lcom/personal/aihub/SparkingContent$XXH64;->v1 J
  0004 invoke-static v5, v6, Lcom/personal/aihub/SparkingContent$XXH64;->read64([B I)J
  000a move-result-wide v2
  000c invoke-static v0, v1, v2, v3, Lcom/personal/aihub/SparkingContent$XXH64;->round(J J)J
  0012 move-result-wide v0
  0014 iput-wide v0, v4, Lcom/personal/aihub/SparkingContent$XXH64;->v1 J
  0018 iget-wide v0, v4, Lcom/personal/aihub/SparkingContent$XXH64;->v2 J
  001c add-int/lit8 v2, v6, 8
  0020 invoke-static v5, v2, Lcom/personal/aihub/SparkingContent$XXH64;->read64([B I)J
  0026 move-result-wide v2
  0028 invoke-static v0, v1, v2, v3, Lcom/personal/aihub/SparkingContent$XXH64;->round(J J)J
  002e move-result-wide v0
  0030 iput-wide v0, v4, Lcom/personal/aihub/SparkingContent$XXH64;->v2 J
  0034 iget-wide v0, v4, Lcom/personal/aihub/SparkingContent$XXH64;->v3 J
  0038 add-int/lit8 v2, v6, 16
  003c invoke-static v5, v2, Lcom/personal/aihub/SparkingContent$XXH64;->read64([B I)J
  0042 move-result-wide v2
  0044 invoke-static v0, v1, v2, v3, Lcom/personal/aihub/SparkingContent$XXH64;->round(J J)J
  004a move-result-wide v0
  004c iput-wide v0, v4, Lcom/personal/aihub/SparkingContent$XXH64;->v3 J
  0050 iget-wide v0, v4, Lcom/personal/aihub/SparkingContent$XXH64;->v4 J
  0054 add-int/lit8 v6, v6, 24
  0058 invoke-static v5, v6, Lcom/personal/aihub/SparkingContent$XXH64;->read64([B I)J
  005e move-result-wide v5
  0060 invoke-static v0, v1, v5, v6, Lcom/personal/aihub/SparkingContent$XXH64;->round(J J)J
  0066 move-result-wide v5
  0068 iput-wide v5, v4, Lcom/personal/aihub/SparkingContent$XXH64;->v4 J
  006c return-void 
.end method

.method merge(J J)J
  0000 const-wide/16 v0, 0
  0004 invoke-static v0, v1, v4, v5, Lcom/personal/aihub/SparkingContent$XXH64;->round(J J)J
  000a move-result-wide v4
  000c xor-long/2addr v2, v4
  000e const-wide v4, -7046029288634856825
  0018 mul-long/2addr v2, v4
  001a const-wide v4, -8796714831421723037
  0024 add-long/2addr v2, v4
  0026 return-wide v2
.end method

.method read32([B I)J
  0000 aget-byte v0, v7, v8
  0004 int-to-long v0, v0
  0006 const-wide/16 v2, 255
  000a and-long/2addr v0, v2
  000c add-int/lit8 v4, v8, 1
  0010 aget-byte v4, v7, v4
  0014 int-to-long v4, v4
  0016 and-long/2addr v4, v2
  0018 const/16 v6, 8
  001c shl-long/2addr v4, v6
  001e or-long/2addr v0, v4
  0020 add-int/lit8 v4, v8, 2
  0024 aget-byte v4, v7, v4
  0028 int-to-long v4, v4
  002a and-long/2addr v4, v2
  002c const/16 v6, 16
  0030 shl-long/2addr v4, v6
  0032 or-long/2addr v0, v4
  0034 add-int/lit8 v8, v8, 3
  0038 aget-byte v7, v7, v8
  003c int-to-long v7, v7
  003e and-long/2addr v7, v2
  0040 const/16 v2, 24
  0044 shl-long/2addr v7, v2
  0046 or-long/2addr v7, v0
  0048 return-wide v7
.end method

.method read64([B I)J
  0000 const-wide/16 v0, 0
  0004 const/4 v2, 0
  0006 const/16 v3, 8
  000a if-ge v2, v3, +011h
  000e add-int v3, v8, v2
  0012 aget-byte v3, v7, v3
  0016 int-to-long v3, v3
  0018 const-wide/16 v5, 255
  001c and-long/2addr v3, v5
  001e mul-int/lit8 v5, v2, 8
  0022 shl-long/2addr v3, v5
  0024 or-long/2addr v0, v3
  0026 add-int/lit8 v2, v2, 1
  002a goto -12h
  002c return-wide v0
.end method

.method round(J J)J
  0000 const-wide v0, -4417276706812531889
  000a mul-long/2addr v4, v0
  000c add-long/2addr v2, v4
  000e const/16 v4, 31
  0012 invoke-static v2, v3, v4, Ljava/lang/Long;->rotateLeft(J I)J
  0018 move-result-wide v2
  001a const-wide v4, -7046029288634856825
  0024 mul-long/2addr v2, v4
  0026 return-wide v2
.end method

.method update([B I I)V
  0000 if-ltz v7, +048h
  0004 if-ltz v8, +046h
  0008 array-length v0, v6
  000a sub-int/2addr v0, v8
  000c if-gt v7, v0, +042h
  0010 iget-wide v0, v5, Lcom/personal/aihub/SparkingContent$XXH64;->total J
  0014 int-to-long v2, v8
  0016 add-long/2addr v0, v2
  0018 iput-wide v0, v5, Lcom/personal/aihub/SparkingContent$XXH64;->total J
  001c iget v0, v5, Lcom/personal/aihub/SparkingContent$XXH64;->used I
  0020 add-int v1, v0, v8
  0024 const/16 v2, 32
  0028 if-ge v1, v2, +00dh
  002c iget-object v1, v5, Lcom/personal/aihub/SparkingContent$XXH64;->pending [B
  0030 invoke-static v6, v7, v1, v0, v8, Ljava/lang/System;->arraycopy(Ljava/lang/Object; I Ljava/lang/Object; I I)V
  0036 iget v6, v5, Lcom/personal/aihub/SparkingContent$XXH64;->used I
  003a add-int/2addr v6, v8
  003c iput v6, v5, Lcom/personal/aihub/SparkingContent$XXH64;->used I
  0040 return-void 
  0042 const/4 v1, 0
  0044 if-lez v0, +012h
  0048 rsub-int/lit8 v3, v0, 32
  004c iget-object v4, v5, Lcom/personal/aihub/SparkingContent$XXH64;->pending [B
  0050 invoke-static v6, v7, v4, v0, v3, Ljava/lang/System;->arraycopy(Ljava/lang/Object; I Ljava/lang/Object; I I)V
  0056 iget-object v0, v5, Lcom/personal/aihub/SparkingContent$XXH64;->pending [B
  005a invoke-direct v5, v0, v1, Lcom/personal/aihub/SparkingContent$XXH64;->block([B I)V
  0060 add-int/2addr v7, v3
  0062 sub-int/2addr v8, v3
  0064 iput v1, v5, Lcom/personal/aihub/SparkingContent$XXH64;->used I
  0068 if-lt v8, v2, +00ah
  006c invoke-direct v5, v6, v7, Lcom/personal/aihub/SparkingContent$XXH64;->block([B I)V
  0072 add-int/lit8 v7, v7, 32
  0076 add-int/lit8 v8, v8, -32
  007a goto -9h
  007c if-lez v8, +009h
  0080 iget-object v0, v5, Lcom/personal/aihub/SparkingContent$XXH64;->pending [B
  0084 invoke-static v6, v7, v0, v1, v8, Ljava/lang/System;->arraycopy(Ljava/lang/Object; I Ljava/lang/Object; I I)V
  008a iput v8, v5, Lcom/personal/aihub/SparkingContent$XXH64;->used I
  008e return-void 
  0090 new-instance v6, Ljava/lang/IndexOutOfBoundsException;
  0094 invoke-direct v6, Ljava/lang/IndexOutOfBoundsException;-><init>()V
  009a throw v6
.end method

.method value()J
  0000 move-object/from16 v0, v18
  0004 iget-wide v1, v0, Lcom/personal/aihub/SparkingContent$XXH64;->total J
  0008 const-wide/16 v3, 32
  000c cmp-long v1, v1, v3
  0010 const-wide v2, 2870177450012600261
  001a if-ltz v1, +03ch
  001e iget-wide v4, v0, Lcom/personal/aihub/SparkingContent$XXH64;->v1 J
  0022 const/4 v1, 1
  0024 invoke-static v4, v5, v1, Ljava/lang/Long;->rotateLeft(J I)J
  002a move-result-wide v4
  002c iget-wide v6, v0, Lcom/personal/aihub/SparkingContent$XXH64;->v2 J
  0030 const/4 v1, 7
  0032 invoke-static v6, v7, v1, Ljava/lang/Long;->rotateLeft(J I)J
  0038 move-result-wide v6
  003a add-long/2addr v4, v6
  003c iget-wide v6, v0, Lcom/personal/aihub/SparkingContent$XXH64;->v3 J
  0040 const/16 v1, 12
  0044 invoke-static v6, v7, v1, Ljava/lang/Long;->rotateLeft(J I)J
  004a move-result-wide v6
  004c add-long/2addr v4, v6
  004e iget-wide v6, v0, Lcom/personal/aihub/SparkingContent$XXH64;->v4 J
  0052 const/16 v1, 18
  0056 invoke-static v6, v7, v1, Ljava/lang/Long;->rotateLeft(J I)J
  005c move-result-wide v6
  005e add-long/2addr v4, v6
  0060 iget-wide v6, v0, Lcom/personal/aihub/SparkingContent$XXH64;->v1 J
  0064 invoke-static v4, v5, v6, v7, Lcom/personal/aihub/SparkingContent$XXH64;->merge(J J)J
  006a move-result-wide v4
  006c iget-wide v6, v0, Lcom/personal/aihub/SparkingContent$XXH64;->v2 J
  0070 invoke-static v4, v5, v6, v7, Lcom/personal/aihub/SparkingContent$XXH64;->merge(J J)J
  0076 move-result-wide v4
  0078 iget-wide v6, v0, Lcom/personal/aihub/SparkingContent$XXH64;->v3 J
  007c invoke-static v4, v5, v6, v7, Lcom/personal/aihub/SparkingContent$XXH64;->merge(J J)J
  0082 move-result-wide v4
  0084 iget-wide v6, v0, Lcom/personal/aihub/SparkingContent$XXH64;->v4 J
  0088 invoke-static v4, v5, v6, v7, Lcom/personal/aihub/SparkingContent$XXH64;->merge(J J)J
  008e move-result-wide v4
  0090 goto +2h
  0092 move-wide v4, v2
  0094 iget-wide v6, v0, Lcom/personal/aihub/SparkingContent$XXH64;->total J
  0098 add-long/2addr v4, v6
  009a const/4 v1, 0
  009c add-int/lit8 v6, v1, 8
  00a0 iget v7, v0, Lcom/personal/aihub/SparkingContent$XXH64;->used I
  00a4 const-wide v8, -7046029288634856825
  00ae if-gt v6, v7, +01eh
  00b2 iget-object v7, v0, Lcom/personal/aihub/SparkingContent$XXH64;->pending [B
  00b6 invoke-static v7, v1, Lcom/personal/aihub/SparkingContent$XXH64;->read64([B I)J
  00bc move-result-wide v10
  00be const-wide/16 v12, 0
  00c2 invoke-static v12, v13, v10, v11, Lcom/personal/aihub/SparkingContent$XXH64;->round(J J)J
  00c8 move-result-wide v10
  00ca xor-long/2addr v4, v10
  00cc const/16 v1, 27
  00d0 invoke-static v4, v5, v1, Ljava/lang/Long;->rotateLeft(J I)J
  00d6 move-result-wide v4
  00d8 mul-long/2addr v4, v8
  00da const-wide v7, -8796714831421723037
  00e4 add-long/2addr v4, v7
  00e6 move v1, v6
  00e8 goto -26h
  00ea add-int/lit8 v6, v1, 4
  00ee const-wide v10, 1609587929392839161
  00f8 const-wide v12, -4417276706812531889
  0102 if-gt v6, v7, +013h
  0106 iget-object v7, v0, Lcom/personal/aihub/SparkingContent$XXH64;->pending [B
  010a invoke-static v7, v1, Lcom/personal/aihub/SparkingContent$XXH64;->read32([B I)J
  0110 move-result-wide v14
  0112 mul-long/2addr v14, v8
  0114 xor-long/2addr v4, v14
  0116 const/16 v1, 23
  011a invoke-static v4, v5, v1, Ljava/lang/Long;->rotateLeft(J I)J
  0120 move-result-wide v4
  0122 mul-long/2addr v4, v12
  0124 add-long/2addr v4, v10
  0126 move v1, v6
  0128 iget v6, v0, Lcom/personal/aihub/SparkingContent$XXH64;->used I
  012c if-ge v1, v6, +018h
  0130 iget-object v6, v0, Lcom/personal/aihub/SparkingContent$XXH64;->pending [B
  0134 add-int/lit8 v7, v1, 1
  0138 aget-byte v1, v6, v1
  013c int-to-long v14, v1
  013e const-wide/16 v16, 255
  0142 and-long v14, v14, v16
  0146 mul-long/2addr v14, v2
  0148 xor-long/2addr v4, v14
  014a const/16 v1, 11
  014e invoke-static v4, v5, v1, Ljava/lang/Long;->rotateLeft(J I)J
  0154 move-result-wide v4
  0156 mul-long/2addr v4, v8
  0158 move v1, v7
  015a goto -19h
  015c const/16 v1, 33
  0160 ushr-long v1, v4, v1
  0164 xor-long/2addr v1, v4
  0166 mul-long/2addr v1, v12
  0168 const/16 v3, 29
  016c ushr-long v3, v1, v3
  0170 xor-long/2addr v1, v3
  0172 mul-long/2addr v1, v10
  0174 const/16 v3, 32
  0178 ushr-long v3, v1, v3
  017c xor-long/2addr v1, v3
  017e return-wide v1
.end method