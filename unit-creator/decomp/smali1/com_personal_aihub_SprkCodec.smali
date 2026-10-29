.class Lcom/personal/aihub/SprkCodec;
.super Ljava/lang/Object;
.field LIBRARY_MAX I
.field LIBRARY_SHA256 Ljava/lang/String;
.field MAX_ARCHIVE J
.field MAX_ENTRIES I
.field MAX_ENTRY J
.field MAX_METADATA I
.field MAX_TOTAL J
.field SEED_LENGTH I
.field SEED_OFFSET I

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method bounded(Ljava/io/InputStream; I)[B
  0000 new-instance v0, Ljava/io/ByteArrayOutputStream;
  0004 invoke-direct v0, Ljava/io/ByteArrayOutputStream;-><init>()V
  000a const/high16 v1, 65536
  000e new-array v1, v1, [B
  0012 invoke-virtual v4, v1, Ljava/io/InputStream;->read([B)I
  0018 move-result v2
  001a const/4 v3, -1
  001c if-eq v2, v3, +016h
  0020 invoke-virtual v0, Ljava/io/ByteArrayOutputStream;->size()I
  0026 move-result v3
  0028 add-int/2addr v3, v2
  002a if-gt v3, v5, +007h
  002e const/4 v3, 0
  0030 invoke-virtual v0, v1, v3, v2, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  0036 goto -12h
  0038 new-instance v4, Ljava/io/IOException;
  003c const-string v5, "This Sparking resource exceeds its size limit."
  0040 invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0046 throw v4
  0048 invoke-virtual v0, Ljava/io/ByteArrayOutputStream;->toByteArray()[B
  004e move-result-object v4
  0050 return-object v4
.end method

.method central(Ljava/io/File;)Ljava/util/List;
  0000 invoke-virtual/range v28, Ljava/io/File;->isFile()Z
  0006 move-result v0
  0008 if-eqz v0, +30fh
  000c invoke-virtual/range v28, Ljava/io/File;->length()J
  0012 move-result-wide v0
  0014 const-wide/32 v2, 536870912
  001a cmp-long v0, v0, v2
  001e if-gtz v0, +304h
  0022 new-instance v1, Ljava/io/RandomAccessFile;
  0026 const-string v0, "r"
  002a move-object/from16 v4, v28
  002e invoke-direct v1, v4, v0, Ljava/io/RandomAccessFile;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0034 invoke-virtual v1, Ljava/io/RandomAccessFile;->length()J
  003a move-result-wide v4
  003c const-wide/32 v6, 65557
  0042 invoke-static v6, v7, v4, v5, Ljava/lang/Math;->min(J J)J
  0048 move-result-wide v4
  004a long-to-int v0, v4
  004c const/16 v4, 22
  0050 if-lt v0, v4, +2d7h
  0054 new-array v4, v0, [B
  0058 invoke-virtual v1, Ljava/io/RandomAccessFile;->length()J
  005e move-result-wide v5
  0060 int-to-long v7, v0
  0062 sub-long/2addr v5, v7
  0064 invoke-virtual v1, v5, v6, Ljava/io/RandomAccessFile;->seek(J)V
  006a invoke-virtual v1, v4, Ljava/io/RandomAccessFile;->readFully([B)V
  0070 add-int/lit8 v5, v0, -22
  0074 if-ltz v5, +01ch
  0078 invoke-static v4, v5, Lcom/personal/aihub/SprkCodec;->u32([B I)J
  007e move-result-wide v9
  0080 const-wide/32 v11, 101010256
  0086 cmp-long v6, v9, v11
  008a if-nez v6, +00eh
  008e add-int/lit8 v6, v5, 22
  0092 add-int/lit8 v9, v5, 20
  0096 invoke-static v4, v9, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  009c move-result v9
  009e add-int/2addr v6, v9
  00a0 if-ne v6, v0, +003h
  00a4 goto +5h
  00a6 add-int/lit8 v5, v5, -1
  00aa goto -1bh
  00ac const/4 v5, -1
  00ae if-ltz v5, +2a0h
  00b2 add-int/lit8 v0, v5, 4
  00b6 invoke-static v4, v0, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  00bc move-result v0
  00be if-nez v0, +298h
  00c2 add-int/lit8 v0, v5, 6
  00c6 invoke-static v4, v0, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  00cc move-result v0
  00ce if-nez v0, +290h
  00d2 add-int/lit8 v0, v5, 8
  00d6 invoke-static v4, v0, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  00dc move-result v0
  00de add-int/lit8 v6, v5, 10
  00e2 invoke-static v4, v6, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  00e8 move-result v9
  00ea if-ne v0, v9, +282h
  00ee invoke-static v4, v6, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  00f4 move-result v0
  00f6 add-int/lit8 v6, v5, 12
  00fa invoke-static v4, v6, Lcom/personal/aihub/SprkCodec;->u32([B I)J
  0100 move-result-wide v9
  0102 add-int/lit8 v6, v5, 16
  0106 invoke-static v4, v6, Lcom/personal/aihub/SprkCodec;->u32([B I)J
  010c move-result-wide v11
  010e invoke-virtual v1, Ljava/io/RandomAccessFile;->length()J
  0114 move-result-wide v13
  0116 sub-long/2addr v13, v7
  0118 int-to-long v4, v5
  011a add-long/2addr v13, v4
  011c const/4 v4, 1
  011e if-lt v0, v4, +260h
  0122 const/16 v5, 10000
  0126 if-gt v0, v5, +25ch
  012a const-wide/32 v5, 16777216
  0130 cmp-long v5, v9, v5
  0134 if-gtz v5, +255h
  0138 add-long v5, v11, v9
  013c cmp-long v7, v5, v13
  0140 if-nez v7, +24fh
  0144 const-wide v7, 4294967295
  014e cmp-long v13, v11, v7
  0152 if-eqz v13, +246h
  0156 cmp-long v7, v9, v7
  015a if-eqz v7, +242h
  015e invoke-virtual v1, v11, v12, Ljava/io/RandomAccessFile;->seek(J)V
  0164 new-instance v7, Ljava/util/ArrayList;
  0168 invoke-direct v7, Ljava/util/ArrayList;-><init>()V
  016e new-instance v8, Ljava/util/HashSet;
  0172 invoke-direct v8, Ljava/util/HashSet;-><init>()V
  0178 new-instance v9, Ljava/util/HashMap;
  017c invoke-direct v9, Ljava/util/HashMap;-><init>()V
  0182 const/4 v10, 0
  0184 move v15, v10
  0186 const-wide/16 v16, 0
  018a const/16 v13, 28
  018e const/16 v14, 30
  0192 const/16 v4, 8
  0196 if-ge v15, v0, +156h
  019a const/16 v2, 46
  019e new-array v2, v2, [B
  01a2 invoke-virtual v1, v2, Ljava/io/RandomAccessFile;->readFully([B)V
  01a8 invoke-static v2, v10, Lcom/personal/aihub/SprkCodec;->u32([B I)J
  01ae move-result-wide v22
  01b0 const-wide/32 v24, 33639248
  01b6 cmp-long v3, v22, v24
  01ba if-nez v3, +13ch
  01be new-instance v3, Lcom/personal/aihub/SprkCodec$Member;
  01c2 const/4 v10, 0
  01c4 invoke-direct v3, v10, Lcom/personal/aihub/SprkCodec$Member;-><init>(Lcom/personal/aihub/SprkCodec$1;)V
  01ca invoke-static v2, v4, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  01d0 move-result v10
  01d2 iput v10, v3, Lcom/personal/aihub/SprkCodec$Member;->flags I
  01d6 const/16 v10, 10
  01da invoke-static v2, v10, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  01e0 move-result v10
  01e2 iput v10, v3, Lcom/personal/aihub/SprkCodec$Member;->method I
  01e6 const/16 v10, 16
  01ea move-wide/from16 v23, v5
  01ee invoke-static v2, v10, Lcom/personal/aihub/SprkCodec;->u32([B I)J
  01f4 move-result-wide v4
  01f6 iput-wide v4, v3, Lcom/personal/aihub/SprkCodec$Member;->crc J
  01fa const/16 v4, 20
  01fe invoke-static v2, v4, Lcom/personal/aihub/SprkCodec;->u32([B I)J
  0204 move-result-wide v4
  0206 iput-wide v4, v3, Lcom/personal/aihub/SprkCodec$Member;->compressed J
  020a const/16 v4, 24
  020e invoke-static v2, v4, Lcom/personal/aihub/SprkCodec;->u32([B I)J
  0214 move-result-wide v4
  0216 iput-wide v4, v3, Lcom/personal/aihub/SprkCodec$Member;->size J
  021a const/16 v4, 42
  021e invoke-static v2, v4, Lcom/personal/aihub/SprkCodec;->u32([B I)J
  0224 move-result-wide v4
  0226 iput-wide v4, v3, Lcom/personal/aihub/SprkCodec$Member;->local J
  022a invoke-static v2, v13, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  0230 move-result v4
  0232 invoke-static v2, v14, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  0238 move-result v5
  023a const/16 v13, 32
  023e invoke-static v2, v13, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  0244 move-result v13
  0246 const/16 v14, 38
  024a invoke-static v2, v14, Lcom/personal/aihub/SprkCodec;->u32([B I)J
  0250 move-result-wide v25
  0252 move-object/from16 v27, v7
  0256 ushr-long v6, v25, v10
  025a long-to-int v6, v6
  025c const v7, 61440
  0262 and-int/2addr v6, v7
  0264 iget v7, v3, Lcom/personal/aihub/SprkCodec$Member;->flags I
  0268 and-int/lit8 v7, v7, 65
  026c if-nez v7, +0dbh
  0270 iget v7, v3, Lcom/personal/aihub/SprkCodec$Member;->method I
  0274 if-eqz v7, +008h
  0278 iget v7, v3, Lcom/personal/aihub/SprkCodec$Member;->method I
  027c const/16 v10, 8
  0280 if-ne v7, v10, +0d1h
  0284 move v7, v15
  0286 iget-wide v14, v3, Lcom/personal/aihub/SprkCodec$Member;->size J
  028a const-wide/32 v20, 536870912
  0290 cmp-long v10, v14, v20
  0294 if-gtz v10, +0c7h
  0298 iget-wide v14, v3, Lcom/personal/aihub/SprkCodec$Member;->compressed J
  029c cmp-long v10, v14, v20
  02a0 if-gtz v10, +0c1h
  02a4 iget-wide v14, v3, Lcom/personal/aihub/SprkCodec$Member;->local J
  02a8 cmp-long v10, v14, v11
  02ac if-gez v10, +0bbh
  02b0 const/4 v10, 1
  02b2 if-lt v4, v10, +0b8h
  02b6 const/16 v10, 2000
  02ba if-gt v4, v10, +0b4h
  02be const/16 v10, 34
  02c2 invoke-static v2, v10, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  02c8 move-result v2
  02ca if-nez v2, +0ach
  02ce const/16 v2, 16384
  02d2 if-eqz v6, +009h
  02d6 const v10, 32768
  02dc if-eq v6, v10, +004h
  02e0 if-ne v6, v2, +0a1h
  02e4 new-array v4, v4, [B
  02e8 invoke-virtual v1, v4, Ljava/io/RandomAccessFile;->readFully([B)V
  02ee iget v10, v3, Lcom/personal/aihub/SprkCodec$Member;->flags I
  02f2 invoke-static v4, v10, Lcom/personal/aihub/SprkCodec;->name([B I)Ljava/lang/String;
  02f8 move-result-object v4
  02fa iput-object v4, v3, Lcom/personal/aihub/SprkCodec$Member;->name Ljava/lang/String;
  02fe iget-object v4, v3, Lcom/personal/aihub/SprkCodec$Member;->name Ljava/lang/String;
  0302 const-string v10, "/"
  0306 invoke-virtual v4, v10, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  030c move-result v4
  030e iput-boolean v4, v3, Lcom/personal/aihub/SprkCodec$Member;->directory Z
  0312 iget-boolean v4, v3, Lcom/personal/aihub/SprkCodec$Member;->directory Z
  0316 if-eqz v4, +012h
  031a iget-object v4, v3, Lcom/personal/aihub/SprkCodec$Member;->name Ljava/lang/String;
  031e iget-object v10, v3, Lcom/personal/aihub/SprkCodec$Member;->name Ljava/lang/String;
  0322 invoke-virtual v10, Ljava/lang/String;->length()I
  0328 move-result v10
  032a const/4 v14, 1
  032c sub-int/2addr v10, v14
  032e const/4 v14, 0
  0330 invoke-virtual v4, v14, v10, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  0336 move-result-object v4
  0338 goto +3h
  033a iget-object v4, v3, Lcom/personal/aihub/SprkCodec$Member;->name Ljava/lang/String;
  033e invoke-static v4, Lcom/personal/aihub/SprkCodec;->safe(Ljava/lang/String;)V
  0344 invoke-interface v8, v4, Ljava/util/Set;->add(Ljava/lang/Object;)Z
  034a move-result v10
  034c if-eqz v10, +063h
  0350 iget-boolean v10, v3, Lcom/personal/aihub/SprkCodec$Member;->directory Z
  0354 invoke-static v10, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;
  035a move-result-object v10
  035c invoke-interface v9, v4, v10, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0362 iget-boolean v4, v3, Lcom/personal/aihub/SprkCodec$Member;->directory Z
  0366 if-eqz v4, +00bh
  036a iget-wide v14, v3, Lcom/personal/aihub/SprkCodec$Member;->size J
  036e const-wide/16 v18, 0
  0372 cmp-long v4, v14, v18
  0376 if-nez v4, +00ch
  037a goto +3h
  037c const-wide/16 v18, 0
  0380 if-ne v6, v2, +00fh
  0384 iget-boolean v2, v3, Lcom/personal/aihub/SprkCodec$Member;->directory Z
  0388 if-eqz v2, +003h
  038c goto +9h
  038e new-instance v0, Ljava/io/IOException;
  0392 const-string v2, "Invalid Sparking ZIP directory entry."
  0396 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  039c throw v0
  039e iget-wide v14, v3, Lcom/personal/aihub/SprkCodec$Member;->size J
  03a2 add-long v16, v16, v14
  03a6 const-wide/32 v14, 1073741824
  03ac cmp-long v2, v16, v14
  03b0 if-gtz v2, +029h
  03b4 invoke-virtual v1, Ljava/io/RandomAccessFile;->getFilePointer()J
  03ba move-result-wide v14
  03bc int-to-long v4, v5
  03be add-long/2addr v14, v4
  03c0 int-to-long v4, v13
  03c2 add-long/2addr v14, v4
  03c4 cmp-long v2, v14, v23
  03c8 if-gtz v2, +015h
  03cc invoke-virtual v1, v14, v15, Ljava/io/RandomAccessFile;->seek(J)V
  03d2 move-object/from16 v2, v27
  03d6 invoke-interface v2, v3, Ljava/util/List;->add(Ljava/lang/Object;)Z
  03dc add-int/lit8 v15, v7, 1
  03e0 move-object v7, v2
  03e2 move-wide/from16 v2, v20
  03e6 move-wide/from16 v5, v23
  03ea const/4 v4, 1
  03ec const/4 v10, 0
  03ee goto/16 -132h
  03f2 new-instance v0, Ljava/io/IOException;
  03f6 const-string v2, "Truncated Sparking ZIP metadata."
  03fa invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0400 throw v0
  0402 new-instance v0, Ljava/io/IOException;
  0406 const-string v2, "Expanded Sparking patch exceeds1GiB."
  040a invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0410 throw v0
  0412 new-instance v0, Ljava/io/IOException;
  0416 const-string v2, "The Sparking ZIP contains duplicate file paths."
  041a invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0420 throw v0
  0422 new-instance v0, Ljava/io/IOException;
  0426 const-string v2, "This Sparking ZIP contains an encrypted, linked, special or unsupported entry."
  042a invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0430 throw v0
  0432 new-instance v0, Ljava/io/IOException;
  0436 const-string v2, "Corrupt Sparking ZIP directory."
  043a invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0440 throw v0
  0442 move-wide/from16 v23, v5
  0446 move-object v2, v7
  0448 invoke-virtual v1, Ljava/io/RandomAccessFile;->getFilePointer()J
  044e move-result-wide v3
  0450 cmp-long v0, v3, v23
  0454 if-nez v0, +0bdh
  0458 invoke-interface v2, Ljava/util/List;->iterator()Ljava/util/Iterator;
  045e move-result-object v0
  0460 invoke-interface v0, Ljava/util/Iterator;->hasNext()Z
  0466 move-result v3
  0468 if-eqz v3, +0afh
  046c invoke-interface v0, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0472 move-result-object v3
  0474 check-cast v3, Lcom/personal/aihub/SprkCodec$Member;
  0478 iget-boolean v4, v3, Lcom/personal/aihub/SprkCodec$Member;->directory Z
  047c if-eqz v4, +012h
  0480 iget-object v4, v3, Lcom/personal/aihub/SprkCodec$Member;->name Ljava/lang/String;
  0484 iget-object v5, v3, Lcom/personal/aihub/SprkCodec$Member;->name Ljava/lang/String;
  0488 invoke-virtual v5, Ljava/lang/String;->length()I
  048e move-result v5
  0490 const/4 v7, 1
  0492 sub-int/2addr v5, v7
  0494 const/4 v8, 0
  0496 invoke-virtual v4, v8, v5, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  049c move-result-object v4
  049e goto +4h
  04a0 const/4 v7, 1
  04a2 iget-object v4, v3, Lcom/personal/aihub/SprkCodec$Member;->name Ljava/lang/String;
  04a6 const/16 v5, 47
  04aa invoke-virtual v4, v5, Ljava/lang/String;->indexOf(I)I
  04b0 move-result v8
  04b2 if-ltz v8, +022h
  04b6 sget-object v10, Ljava/lang/Boolean;->FALSE Ljava/lang/Boolean;
  04ba const/4 v15, 0
  04bc invoke-virtual v4, v15, v8, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  04c2 move-result-object v6
  04c4 invoke-interface v9, v6, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  04ca move-result-object v6
  04cc invoke-virtual v10, v6, Ljava/lang/Boolean;->equals(Ljava/lang/Object;)Z
  04d2 move-result v6
  04d4 if-nez v6, +009h
  04d8 add-int/lit8 v8, v8, 1
  04dc invoke-virtual v4, v5, v8, Ljava/lang/String;->indexOf(I I)I
  04e2 move-result v8
  04e4 goto -19h
  04e6 new-instance v0, Ljava/io/IOException;
  04ea const-string v2, "A Sparking file conflicts with a folder."
  04ee invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  04f4 throw v0
  04f6 iget-wide v4, v3, Lcom/personal/aihub/SprkCodec$Member;->local J
  04fa invoke-virtual v1, v4, v5, Ljava/io/RandomAccessFile;->seek(J)V
  0500 new-array v4, v14, [B
  0504 invoke-virtual v1, v4, Ljava/io/RandomAccessFile;->readFully([B)V
  050a const/4 v5, 0
  050c invoke-static v4, v5, Lcom/personal/aihub/SprkCodec;->u32([B I)J
  0512 move-result-wide v15
  0514 const-wide/32 v17, 67324752
  051a cmp-long v6, v15, v17
  051e if-nez v6, +04ch
  0522 const/16 v6, 8
  0526 invoke-static v4, v6, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  052c move-result v8
  052e iget v10, v3, Lcom/personal/aihub/SprkCodec$Member;->method I
  0532 if-ne v8, v10, +042h
  0536 const/4 v8, 6
  0538 invoke-static v4, v8, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  053e move-result v8
  0540 iget v10, v3, Lcom/personal/aihub/SprkCodec$Member;->flags I
  0544 if-ne v8, v10, +039h
  0548 const/16 v8, 26
  054c invoke-static v4, v8, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  0552 move-result v8
  0554 invoke-static v4, v13, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  055a move-result v4
  055c new-array v10, v8, [B
  0560 invoke-virtual v1, v10, Ljava/io/RandomAccessFile;->readFully([B)V
  0566 iget v15, v3, Lcom/personal/aihub/SprkCodec$Member;->flags I
  056a invoke-static v10, v15, Lcom/personal/aihub/SprkCodec;->name([B I)Ljava/lang/String;
  0570 move-result-object v10
  0572 iget-object v15, v3, Lcom/personal/aihub/SprkCodec$Member;->name Ljava/lang/String;
  0576 invoke-virtual v10, v15, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  057c move-result v10
  057e if-eqz v10, +014h
  0582 iget-wide v5, v3, Lcom/personal/aihub/SprkCodec$Member;->local J
  0586 const-wide/16 v15, 30
  058a add-long/2addr v5, v15
  058c int-to-long v7, v8
  058e add-long/2addr v5, v7
  0590 int-to-long v7, v4
  0592 add-long/2addr v5, v7
  0594 iget-wide v3, v3, Lcom/personal/aihub/SprkCodec$Member;->compressed J
  0598 add-long/2addr v5, v3
  059a cmp-long v3, v5, v11
  059e if-gtz v3, +004h
  05a2 goto/16 -0a1h
  05a6 new-instance v0, Ljava/io/IOException;
  05aa const-string v2, "Invalid Sparking ZIP file bounds."
  05ae invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  05b4 throw v0
  05b6 new-instance v0, Ljava/io/IOException;
  05ba const-string v2, "Sparking ZIP local and directory headers do not match."
  05be invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  05c4 throw v0
  05c6 invoke-virtual v1, Ljava/io/RandomAccessFile;->close()V
  05cc return-object v2
  05ce new-instance v0, Ljava/io/IOException;
  05d2 const-string v2, "Sparking ZIP directory size does not match."
  05d6 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  05dc throw v0
  05de new-instance v0, Ljava/io/IOException;
  05e2 const-string v2, "This Sparking ZIP exceeds supported limits or needs unsupported ZIP64 handling."
  05e6 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  05ec throw v0
  05ee new-instance v0, Ljava/io/IOException;
  05f2 const-string v2, "Unsupported or incomplete Sparking ZIP directory."
  05f6 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  05fc throw v0
  05fe new-instance v0, Ljava/io/IOException;
  0602 const-string v2, "The decrypted Sparking file is not a complete ZIP."
  0606 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  060c throw v0
  060e move-exception v0
  0610 move-object v2, v0
  0612 invoke-virtual v1, Ljava/io/RandomAccessFile;->close()V
  0618 goto +6h
  061a move-exception v0
  061c move-object v1, v0
  061e invoke-virtual v2, v1, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0624 throw v2
  0626 new-instance v0, Ljava/io/IOException;
  062a const-string v1, "Invalid or oversized Sparking ZIP."
  062e invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0634 throw v0
.end method

.method creatorId(Lorg/json/JSONObject;)J
  0000 invoke-static v5, Lcom/personal/aihub/SprkCodec;->id(Lorg/json/JSONObject;)J
  0006 move-result-wide v0
  0008 const-wide/16 v2, 0
  000c cmp-long v4, v0, v2
  0010 if-lez v4, +003h
  0014 return-wide v0
  0016 const-string v0, "creator"
  001a invoke-virtual v5, v0, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0020 move-result-object v5
  0022 if-nez v5, +003h
  0026 goto +5h
  0028 invoke-static v5, Lcom/personal/aihub/SprkCodec;->id(Lorg/json/JSONObject;)J
  002e move-result-wide v2
  0030 return-wide v2
.end method

.method creatorName(Lorg/json/JSONObject;)Ljava/lang/String;
  0000 const-string v0, "creator_name"
  0004 const-string v1, "creatorName"
  0008 const-string v2, "creator"
  000c filled-new-array v0, v1, v2, [Ljava/lang/String;
  0012 move-result-object v3
  0014 const/4 v4, 0
  0016 move v5, v4
  0018 const/4 v6, 3
  001a if-ge v5, v6, +020h
  001e aget-object v6, v3, v5
  0022 invoke-virtual v8, v6, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  0028 move-result-object v6
  002a instance-of v7, v6, Ljava/lang/String;
  002e if-eqz v7, +013h
  0032 check-cast v6, Ljava/lang/String;
  0036 invoke-virtual v6, Ljava/lang/String;->trim()Ljava/lang/String;
  003c move-result-object v7
  003e invoke-virtual v7, Ljava/lang/String;->isEmpty()Z
  0044 move-result v7
  0046 if-nez v7, +007h
  004a invoke-virtual v6, Ljava/lang/String;->trim()Ljava/lang/String;
  0050 move-result-object v8
  0052 return-object v8
  0054 add-int/lit8 v5, v5, 1
  0058 goto -20h
  005a invoke-virtual v8, v2, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0060 move-result-object v8
  0062 if-eqz v8, +028h
  0066 const-string v2, "name"
  006a filled-new-array v2, v0, v1, [Ljava/lang/String;
  0070 move-result-object v0
  0072 if-ge v4, v6, +020h
  0076 aget-object v1, v0, v4
  007a invoke-virtual v8, v1, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  0080 move-result-object v1
  0082 instance-of v2, v1, Ljava/lang/String;
  0086 if-eqz v2, +013h
  008a check-cast v1, Ljava/lang/String;
  008e invoke-virtual v1, Ljava/lang/String;->trim()Ljava/lang/String;
  0094 move-result-object v2
  0096 invoke-virtual v2, Ljava/lang/String;->isEmpty()Z
  009c move-result v2
  009e if-nez v2, +007h
  00a2 invoke-virtual v1, Ljava/lang/String;->trim()Ljava/lang/String;
  00a8 move-result-object v8
  00aa return-object v8
  00ac add-int/lit8 v4, v4, 1
  00b0 goto -1fh
  00b2 const-string v8, ""
  00b6 return-object v8
.end method

.method databaseKeyFromApk(Ljava/io/File;)Ljava/lang/String;
  0000 invoke-static v4, Lcom/personal/aihub/SprkCodec;->supportedLibrary(Ljava/io/File;)[B
  0006 move-result-object v4
  0008 array-length v0, v4
  000a const v1, 487156
  0010 if-le v0, v1, +03eh
  0014 aget-byte v0, v4, v1
  0018 if-nez v0, +03ah
  001c const/4 v0, 0
  001e const v1, 487092
  0024 const/16 v2, 64
  0028 if-ge v0, v2, +02ah
  002c add-int/2addr v1, v0
  002e aget-byte v1, v4, v1
  0032 and-int/lit16 v1, v1, 255
  0036 const/16 v2, 48
  003a if-lt v1, v2, +006h
  003e const/16 v2, 57
  0042 if-le v1, v2, +012h
  0046 const/16 v2, 97
  004a if-lt v1, v2, +006h
  004e const/16 v2, 102
  0052 if-le v1, v2, +00ah
  0056 const/16 v2, 65
  005a if-lt v1, v2, +009h
  005e const/16 v2, 70
  0062 if-gt v1, v2, +005h
  0066 add-int/lit8 v0, v0, 1
  006a goto -26h
  006c new-instance v4, Ljava/io/IOException;
  0070 const-string v0, "The supported Sparking database format key is invalid."
  0074 invoke-direct v4, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  007a throw v4
  007c new-instance v0, Ljava/lang/String;
  0080 sget-object v3, Ljava/nio/charset/StandardCharsets;->US_ASCII Ljava/nio/charset/Charset;
  0084 invoke-direct v0, v4, v1, v2, v3, Ljava/lang/String;-><init>([B I I Ljava/nio/charset/Charset;)V
  008a return-object v0
  008c new-instance v4, Ljava/io/IOException;
  0090 const-string v0, "The supported Sparking database format key is unavailable."
  0094 invoke-direct v4, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  009a throw v4
.end method

.method decode(Ljava/io/File; Ljava/io/File; [B)V
  0000 if-eqz v13, +14bh
  0004 array-length v0, v13
  0006 const/16 v1, 32
  000a if-ne v0, v1, +146h
  000e invoke-virtual v11, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  0014 move-result-object v11
  0016 invoke-virtual v12, Ljava/io/File;->getAbsoluteFile()Ljava/io/File;
  001c move-result-object v0
  001e invoke-virtual v0, Ljava/io/File;->getParentFile()Ljava/io/File;
  0024 move-result-object v0
  0026 invoke-virtual v0, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  002c move-result-object v0
  002e new-instance v1, Ljava/io/File;
  0032 invoke-virtual v12, Ljava/io/File;->getName()Ljava/lang/String;
  0038 move-result-object v12
  003a invoke-direct v1, v0, v12, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0040 invoke-virtual v0, Ljava/io/File;->isDirectory()Z
  0046 move-result v12
  0048 if-eqz v12, +11fh
  004c invoke-virtual v11, v1, Ljava/io/File;->equals(Ljava/lang/Object;)Z
  0052 move-result v12
  0054 if-nez v12, +119h
  0058 invoke-virtual v1, Ljava/io/File;->exists()Z
  005e move-result v12
  0060 if-eqz v12, +00ch
  0064 invoke-virtual v1, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  006a move-result-object v12
  006c invoke-virtual v12, v1, Ljava/io/File;->equals(Ljava/lang/Object;)Z
  0072 move-result v12
  0074 if-eqz v12, +109h
  0078 invoke-virtual v11, Ljava/io/File;->isFile()Z
  007e move-result v12
  0080 if-eqz v12, +0fbh
  0084 invoke-virtual v11, Ljava/io/File;->length()J
  008a move-result-wide v2
  008c const-wide/16 v4, 21
  0090 cmp-long v12, v2, v4
  0094 if-lez v12, +0f1h
  0098 invoke-virtual v11, Ljava/io/File;->length()J
  009e move-result-wide v2
  00a0 sub-long/2addr v2, v4
  00a2 const-wide/32 v4, 536870912
  00a8 cmp-long v12, v2, v4
  00ac if-gtz v12, +0e5h
  00b0 new-instance v12, Ljava/io/File;
  00b4 new-instance v2, Ljava/lang/StringBuilder;
  00b8 const-string v3, "sprk-decode-"
  00bc invoke-direct v2, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00c2 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  00c8 move-result-object v3
  00ca invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  00d0 const-string v3, ".zip.tmp"
  00d4 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00da invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00e0 move-result-object v2
  00e2 invoke-direct v12, v0, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00e8 new-instance v0, Ljava/io/BufferedInputStream;
  00ec new-instance v2, Ljava/io/FileInputStream;
  00f0 invoke-direct v2, v11, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  00f6 invoke-direct v0, v2, Ljava/io/BufferedInputStream;-><init>(Ljava/io/InputStream;)V
  00fc new-instance v11, Ljava/io/FileOutputStream;
  0100 invoke-direct v11, v12, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0106 const/16 v2, 21
  010a invoke-static v0, v2, Lcom/personal/aihub/SprkCodec;->exact(Ljava/io/InputStream; I)[B
  0110 move-result-object v3
  0112 const/4 v6, 0
  0114 aget-byte v7, v3, v6
  0118 const/16 v8, 83
  011c if-ne v7, v8, +08ch
  0120 const/4 v7, 1
  0122 aget-byte v8, v3, v7
  0126 const/16 v9, 80
  012a if-ne v8, v9, +085h
  012e const/4 v8, 2
  0130 aget-byte v9, v3, v8
  0134 const/16 v10, 82
  0138 if-ne v9, v10, +07eh
  013c const/4 v9, 3
  013e aget-byte v9, v3, v9
  0142 const/16 v10, 75
  0146 if-ne v9, v10, +077h
  014a const/4 v9, 4
  014c aget-byte v9, v3, v9
  0150 if-ne v9, v7, +072h
  0154 const-string v7, "AES/CTR/NoPadding"
  0158 invoke-static v7, Ljavax/crypto/Cipher;->getInstance(Ljava/lang/String;)Ljavax/crypto/Cipher;
  015e move-result-object v7
  0160 new-instance v9, Ljavax/crypto/spec/SecretKeySpec;
  0164 invoke-virtual v13, [B->clone()Ljava/lang/Object;
  016a move-result-object v13
  016c check-cast v13, [B
  0170 const-string v10, "AES"
  0174 invoke-direct v9, v13, v10, Ljavax/crypto/spec/SecretKeySpec;-><init>([B Ljava/lang/String;)V
  017a new-instance v13, Ljavax/crypto/spec/IvParameterSpec;
  017e const/4 v10, 5
  0180 invoke-static v3, v10, v2, Ljava/util/Arrays;->copyOfRange([B I I)[B
  0186 move-result-object v2
  0188 invoke-direct v13, v2, Ljavax/crypto/spec/IvParameterSpec;-><init>([B)V
  018e invoke-virtual v7, v8, v9, v13, Ljavax/crypto/Cipher;->init(I Ljava/security/Key; Ljava/security/spec/AlgorithmParameterSpec;)V
  0194 const/high16 v13, 1048576
  0198 new-array v13, v13, [B
  019c const-wide/16 v2, 0
  01a0 invoke-virtual v0, v13, Ljava/io/InputStream;->read([B)I
  01a6 move-result v8
  01a8 const/4 v9, -1
  01aa if-eq v8, v9, +01ah
  01ae int-to-long v9, v8
  01b0 add-long/2addr v2, v9
  01b2 cmp-long v9, v2, v4
  01b6 if-gtz v9, +00ch
  01ba invoke-virtual v7, v13, v6, v8, Ljavax/crypto/Cipher;->update([B I I)[B
  01c0 move-result-object v8
  01c2 if-eqz v8, -011h
  01c6 invoke-virtual v11, v8, Ljava/io/FileOutputStream;->write([B)V
  01cc goto -16h
  01ce new-instance v13, Ljava/io/IOException;
  01d2 const-string v1, "Sparking patch exceeds the512MiB conversion limit."
  01d6 invoke-direct v13, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01dc throw v13
  01de invoke-virtual v7, Ljavax/crypto/Cipher;->doFinal()[B
  01e4 move-result-object v13
  01e6 if-eqz v13, +005h
  01ea invoke-virtual v11, v13, Ljava/io/FileOutputStream;->write([B)V
  01f0 invoke-virtual v11, Ljava/io/FileOutputStream;->getFD()Ljava/io/FileDescriptor;
  01f6 move-result-object v13
  01f8 invoke-virtual v13, Ljava/io/FileDescriptor;->sync()V
  01fe invoke-virtual v11, Ljava/io/FileOutputStream;->close()V
  0204 invoke-virtual v0, Ljava/io/InputStream;->close()V
  020a invoke-static v12, Lcom/personal/aihub/SprkCodec;->central(Ljava/io/File;)Ljava/util/List;
  0210 invoke-virtual v12, v1, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  0216 move-result v11
  0218 if-eqz v11, +006h
  021c invoke-virtual v12, Ljava/io/File;->delete()Z
  0222 return-void 
  0224 new-instance v11, Ljava/io/IOException;
  0228 const-string v13, "Could not commit the decoded Sparking archive."
  022c invoke-direct v11, v13, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0232 throw v11
  0234 new-instance v13, Ljava/io/IOException;
  0238 const-string v1, "Unsupported Sparking patch header. Only the verified SPRK version1 format is supported."
  023c invoke-direct v13, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0242 throw v13
  0244 move-exception v13
  0246 invoke-virtual v11, Ljava/io/FileOutputStream;->close()V
  024c goto +5h
  024e move-exception v11
  0250 invoke-virtual v13, v11, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0256 throw v13
  0258 move-exception v11
  025a invoke-virtual v0, Ljava/io/InputStream;->close()V
  0260 goto +5h
  0262 move-exception v13
  0264 invoke-virtual v11, v13, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  026a throw v11
  026c move-exception v11
  026e invoke-virtual v12, Ljava/io/File;->delete()Z
  0274 throw v11
  0276 new-instance v11, Ljava/io/IOException;
  027a const-string v12, "This Sparking patch is empty or exceeds the512MiB conversion limit."
  027e invoke-direct v11, v12, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0284 throw v11
  0286 new-instance v11, Ljava/io/IOException;
  028a const-string v12, "Choose a separate, safe staging file for this Sparking patch."
  028e invoke-direct v11, v12, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0294 throw v11
  0296 new-instance v11, Ljava/io/IOException;
  029a const-string v12, "Import the supported Sparking APK before opening an SPRK patch."
  029e invoke-direct v11, v12, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02a4 throw v11
.end method

.method erase(Ljava/io/File;)V
  0000 invoke-virtual v4, Ljava/io/File;->isDirectory()Z
  0006 move-result v0
  0008 if-eqz v0, +014h
  000c invoke-virtual v4, Ljava/io/File;->listFiles()[Ljava/io/File;
  0012 move-result-object v0
  0014 if-eqz v0, +00eh
  0018 array-length v1, v0
  001a const/4 v2, 0
  001c if-ge v2, v1, +00ah
  0020 aget-object v3, v0, v2
  0024 invoke-static v3, Lcom/personal/aihub/SprkCodec;->erase(Ljava/io/File;)V
  002a add-int/lit8 v2, v2, 1
  002e goto -9h
  0030 invoke-virtual v4, Ljava/io/File;->delete()Z
  0036 return-void 
.end method

.method exact(Ljava/io/InputStream; I)[B
  0000 new-array v0, v4, [B
  0004 const/4 v1, 0
  0006 if-ge v1, v4, +014h
  000a sub-int v2, v4, v1
  000e invoke-virtual v3, v0, v1, v2, Ljava/io/InputStream;->read([B I I)I
  0014 move-result v2
  0016 if-ltz v2, +004h
  001a add-int/2addr v1, v2
  001c goto -bh
  001e new-instance v3, Ljava/io/EOFException;
  0022 const-string v4, "The Sparking file is truncated."
  0026 invoke-direct v3, v4, Ljava/io/EOFException;-><init>(Ljava/lang/String;)V
  002c throw v3
  002e return-object v0
.end method

.method hash([B)Ljava/lang/String;
  0000 const-string v0, "SHA-256"
  0004 invoke-static v0, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;
  000a move-result-object v0
  000c invoke-virtual v0, v1, Ljava/security/MessageDigest;->digest([B)[B
  0012 move-result-object v1
  0014 invoke-static v1, Lcom/personal/aihub/SprkCodec;->hex([B)Ljava/lang/String;
  001a move-result-object v1
  001c return-object v1
.end method

.method hex([B)Ljava/lang/String;
  0000 new-instance v0, Ljava/lang/StringBuilder;
  0004 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  000a array-length v1, v6
  000c const/4 v2, 0
  000e if-ge v2, v1, +01ch
  0012 aget-byte v3, v6, v2
  0016 sget-object v4, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  001a and-int/lit16 v3, v3, 255
  001e invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0024 move-result-object v3
  0026 filled-new-array v3, [Ljava/lang/Object;
  002c move-result-object v3
  002e const-string v5, "%02x"
  0032 invoke-static v4, v5, v3, Ljava/lang/String;->format(Ljava/util/Locale; Ljava/lang/String; [Ljava/lang/Object;)Ljava/lang/String;
  0038 move-result-object v3
  003a invoke-virtual v0, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0040 add-int/lit8 v2, v2, 1
  0044 goto -1bh
  0046 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  004c move-result-object v6
  004e return-object v6
.end method

.method id(Lorg/json/JSONObject;)J
  0000 const-string v0, "creatorId"
  0004 const-string v1, "creatorID"
  0008 const-string v2, "creator_id"
  000c filled-new-array v2, v0, v1, [Ljava/lang/String;
  0012 move-result-object v0
  0014 const/4 v1, 0
  0016 const-wide/16 v2, 0
  001a const/4 v4, 3
  001c if-ge v1, v4, +02fh
  0020 aget-object v4, v0, v1
  0024 invoke-virtual v6, v4, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  002a move-result-object v4
  002c if-eqz v4, +024h
  0030 instance-of v5, v4, Ljava/lang/Boolean;
  0034 if-eqz v5, +003h
  0038 goto +1eh
  003a invoke-static v4, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0040 move-result-object v4
  0042 const-string v5, "[0-9]{1,10}"
  0046 invoke-virtual v4, v5, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  004c move-result v5
  004e if-nez v5, +003h
  0052 goto +11h
  0054 invoke-static v4, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  005a move-result-wide v4
  005c cmp-long v2, v4, v2
  0060 if-lez v2, +00ah
  0064 const-wide/32 v2, 2147483647
  006a cmp-long v2, v4, v2
  006e if-gtz v2, +003h
  0072 return-wide v4
  0074 add-int/lit8 v1, v1, 1
  0078 goto -31h
  007a return-wide v2
.end method

.method inspect(Ljava/io/File; Ljava/io/File;)Lorg/json/JSONObject;
  0000 invoke-static/range v32, Lcom/personal/aihub/SprkCodec;->central(Ljava/io/File;)Ljava/util/List;
  0006 move-result-object v0
  0008 invoke-virtual/range v33, Ljava/io/File;->getAbsoluteFile()Ljava/io/File;
  000e move-result-object v1
  0010 invoke-virtual v1, Ljava/io/File;->getParentFile()Ljava/io/File;
  0016 move-result-object v1
  0018 invoke-virtual v1, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  001e move-result-object v1
  0020 new-instance v2, Ljava/io/File;
  0024 invoke-virtual/range v33, Ljava/io/File;->getName()Ljava/lang/String;
  002a move-result-object v3
  002c invoke-direct v2, v1, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0032 invoke-virtual v1, Ljava/io/File;->isDirectory()Z
  0038 move-result v3
  003a if-eqz v3, +3edh
  003e invoke-virtual v2, Ljava/io/File;->exists()Z
  0044 move-result v3
  0046 if-nez v3, +3e7h
  004a new-instance v3, Ljava/io/File;
  004e new-instance v4, Ljava/lang/StringBuilder;
  0052 const-string v5, "sprk-inspect-"
  0056 invoke-direct v4, v5, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  005c invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0062 move-result-object v5
  0064 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  006a invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0070 move-result-object v4
  0072 invoke-direct v3, v1, v4, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0078 invoke-virtual v3, Ljava/io/File;->mkdir()Z
  007e move-result v1
  0080 if-eqz v1, +3c2h
  0084 new-instance v1, Lorg/json/JSONArray;
  0088 invoke-direct v1, Lorg/json/JSONArray;-><init>()V
  008e new-instance v4, Lorg/json/JSONArray;
  0092 invoke-direct v4, Lorg/json/JSONArray;-><init>()V
  0098 new-instance v5, Lorg/json/JSONArray;
  009c invoke-direct v5, Lorg/json/JSONArray;-><init>()V
  00a2 new-instance v6, Lorg/json/JSONArray;
  00a6 invoke-direct v6, Lorg/json/JSONArray;-><init>()V
  00ac new-instance v7, Lorg/json/JSONArray;
  00b0 invoke-direct v7, Lorg/json/JSONArray;-><init>()V
  00b6 new-instance v8, Lorg/json/JSONArray;
  00ba invoke-direct v8, Lorg/json/JSONArray;-><init>()V
  00c0 new-instance v9, Lorg/json/JSONObject;
  00c4 invoke-direct v9, Lorg/json/JSONObject;-><init>()V
  00ca new-instance v10, Ljava/util/HashSet;
  00ce invoke-direct v10, Ljava/util/HashSet;-><init>()V
  00d4 new-instance v11, Ljava/util/zip/ZipFile;
  00d8 const-string v12, "CP437"
  00dc invoke-static v12, Ljava/nio/charset/Charset;->forName(Ljava/lang/String;)Ljava/nio/charset/Charset;
  00e2 move-result-object v12
  00e4 move-object/from16 v13, v32
  00e8 invoke-direct v11, v13, v12, Ljava/util/zip/ZipFile;-><init>(Ljava/io/File; Ljava/nio/charset/Charset;)V
  00ee invoke-interface v0, Ljava/util/List;->iterator()Ljava/util/Iterator;
  00f4 move-result-object v0
  00f6 const-wide/16 v12, 0
  00fa const/4 v15, 0
  00fc const/16 v16, 0
  0100 invoke-interface v0, Ljava/util/Iterator;->hasNext()Z
  0106 move-result v17
  0108 const-string v14, "bytes"
  010c move-object/from16 v18, v2
  0110 const-string v2, "localSql"
  0114 move-wide/from16 v19, v12
  0118 const-string v12, "gameSql"
  011c if-eqz v17, +27ch
  0120 invoke-interface v0, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0126 move-result-object v17
  0128 move-object/from16 v13, v17
  012c check-cast v13, Lcom/personal/aihub/SprkCodec$Member;
  0130 move-object/from16 v17, v0
  0134 iget-boolean v0, v13, Lcom/personal/aihub/SprkCodec$Member;->directory Z
  0138 if-eqz v0, +009h
  013c move-object/from16 v0, v17
  0140 move-object/from16 v2, v18
  0144 move-wide/from16 v12, v19
  0148 goto -24h
  014a new-instance v0, Ljava/io/File;
  014e move-object/from16 v21, v9
  0152 iget-object v9, v13, Lcom/personal/aihub/SprkCodec$Member;->name Ljava/lang/String;
  0156 invoke-direct v0, v3, v9, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  015c invoke-virtual v0, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  0162 move-result-object v0
  0164 invoke-virtual v0, Ljava/io/File;->getPath()Ljava/lang/String;
  016a move-result-object v9
  016c move-object/from16 v22, v8
  0170 new-instance v8, Ljava/lang/StringBuilder;
  0174 invoke-direct v8, Ljava/lang/StringBuilder;-><init>()V
  017a move/from16 v23, v15
  017e invoke-virtual v3, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  0184 move-result-object v15
  0186 invoke-virtual v8, v15, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  018c sget-object v15, Ljava/io/File;->separator Ljava/lang/String;
  0190 invoke-virtual v8, v15, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0196 invoke-virtual v8, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  019c move-result-object v8
  019e invoke-virtual v9, v8, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  01a4 move-result v8
  01a6 if-eqz v8, +21fh
  01aa invoke-virtual v0, Ljava/io/File;->getParentFile()Ljava/io/File;
  01b0 move-result-object v8
  01b2 invoke-virtual v8, Ljava/io/File;->mkdirs()Z
  01b8 move-result v9
  01ba if-nez v9, +018h
  01be invoke-virtual v8, Ljava/io/File;->isDirectory()Z
  01c4 move-result v8
  01c6 if-eqz v8, +003h
  01ca goto +10h
  01cc new-instance v0, Ljava/io/IOException;
  01d0 const-string v1, "Could not stage Sparking resources."
  01d4 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01da throw v0
  01dc move-exception v0
  01de move-object v1, v0
  01e0 move-object v2, v3
  01e2 move-object/from16 v25, v11
  01e6 goto/16 +2f7h
  01ea iget-object v8, v13, Lcom/personal/aihub/SprkCodec$Member;->name Ljava/lang/String;
  01ee invoke-virtual v11, v8, Ljava/util/zip/ZipFile;->getEntry(Ljava/lang/String;)Ljava/util/zip/ZipEntry;
  01f4 move-result-object v8
  01f6 if-eqz v8, +1ebh
  01fa const-string v9, "SHA-256"
  01fe invoke-static v9, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;
  0204 move-result-object v9
  0206 new-instance v15, Ljava/util/zip/CRC32;
  020a invoke-direct v15, Ljava/util/zip/CRC32;-><init>()V
  0210 move-object/from16 v24, v3
  0214 const/high16 v3, 65536
  0218 new-array v3, v3, [B
  021c invoke-virtual v11, v8, Ljava/util/zip/ZipFile;->getInputStream(Ljava/util/zip/ZipEntry;)Ljava/io/InputStream;
  0222 move-result-object v8
  0224 move-object/from16 v25, v11
  0228 new-instance v11, Ljava/io/FileOutputStream;
  022c invoke-direct v11, v0, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0232 move-object/from16 v26, v6
  0236 move-object/from16 v27, v7
  023a move-object/from16 v28, v10
  023e const-wide/16 v6, 0
  0242 invoke-virtual v8, v3, Ljava/io/InputStream;->read([B)I
  0248 move-result v10
  024a move-object/from16 v29, v5
  024e const/4 v5, -1
  0250 if-eq v10, v5, +033h
  0254 move-object/from16 v30, v4
  0258 int-to-long v4, v10
  025a add-long/2addr v6, v4
  025c add-long v19, v19, v4
  0260 iget-wide v4, v13, Lcom/personal/aihub/SprkCodec$Member;->size J
  0264 cmp-long v4, v6, v4
  0268 if-gtz v4, +01fh
  026c const-wide/32 v4, 536870912
  0272 cmp-long v4, v6, v4
  0276 if-gtz v4, +018h
  027a const-wide/32 v4, 1073741824
  0280 cmp-long v4, v19, v4
  0284 if-gtz v4, +011h
  0288 const/4 v4, 0
  028a invoke-virtual v15, v3, v4, v10, Ljava/util/zip/CRC32;->update([B I I)V
  0290 invoke-virtual v9, v3, v4, v10, Ljava/security/MessageDigest;->update([B I I)V
  0296 invoke-virtual v11, v3, v4, v10, Ljava/io/OutputStream;->write([B I I)V
  029c move-object/from16 v5, v29
  02a0 move-object/from16 v4, v30
  02a4 goto -31h
  02a6 new-instance v0, Ljava/io/IOException;
  02aa const-string v1, "Expanded Sparking patch exceeds its supported size."
  02ae invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02b4 throw v0
  02b6 move-object/from16 v30, v4
  02ba invoke-virtual v11, Ljava/io/OutputStream;->close()V
  02c0 if-eqz v8, +005h
  02c4 invoke-virtual v8, Ljava/io/InputStream;->close()V
  02ca iget-wide v3, v13, Lcom/personal/aihub/SprkCodec$Member;->size J
  02ce cmp-long v3, v6, v3
  02d2 if-nez v3, +159h
  02d6 invoke-virtual v15, Ljava/util/zip/CRC32;->getValue()J
  02dc move-result-wide v3
  02de iget-wide v10, v13, Lcom/personal/aihub/SprkCodec$Member;->crc J
  02e2 cmp-long v3, v3, v10
  02e6 if-nez v3, +14fh
  02ea iget-object v3, v13, Lcom/personal/aihub/SprkCodec$Member;->name Ljava/lang/String;
  02ee invoke-static v3, Lcom/personal/aihub/SprkCodec;->role(Ljava/lang/String;)[Ljava/lang/String;
  02f4 move-result-object v3
  02f6 const/4 v4, 1
  02f8 aget-object v5, v3, v4
  02fc invoke-static v5, Lcom/personal/aihub/SprkCodec;->safe(Ljava/lang/String;)V
  0302 new-instance v4, Lorg/json/JSONObject;
  0306 invoke-direct v4, Lorg/json/JSONObject;-><init>()V
  030c const-string v5, "path"
  0310 iget-object v8, v13, Lcom/personal/aihub/SprkCodec$Member;->name Ljava/lang/String;
  0314 invoke-virtual v4, v5, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  031a move-result-object v4
  031c const-string v5, "relativePath"
  0320 const/4 v8, 1
  0322 aget-object v10, v3, v8
  0326 invoke-virtual v4, v5, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  032c move-result-object v4
  032e invoke-virtual v4, v14, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0334 move-result-object v4
  0336 const-string v5, "sha256"
  033a invoke-virtual v9, Ljava/security/MessageDigest;->digest()[B
  0340 move-result-object v8
  0342 invoke-static v8, Lcom/personal/aihub/SprkCodec;->hex([B)Ljava/lang/String;
  0348 move-result-object v8
  034a invoke-virtual v4, v5, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0350 move-result-object v4
  0352 const-string v5, "kind"
  0356 const/4 v8, 0
  0358 aget-object v9, v3, v8
  035c invoke-virtual v4, v5, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0362 move-result-object v4
  0364 invoke-virtual v1, v4, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  036a aget-object v5, v3, v8
  036e const-string v8, "metadata"
  0372 invoke-virtual v5, v8, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0378 move-result v5
  037a if-eqz v5, +041h
  037e const-wide/32 v4, 1048576
  0384 cmp-long v2, v6, v4
  0388 if-gtz v2, +032h
  038c new-instance v2, Ljava/io/FileInputStream;
  0390 invoke-direct v2, v0, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0396 new-instance v0, Lorg/json/JSONObject;
  039a const/high16 v4, 1048576
  039e invoke-static v2, v4, Lcom/personal/aihub/SprkCodec;->bounded(Ljava/io/InputStream; I)[B
  03a4 move-result-object v4
  03a6 invoke-static v4, Lcom/personal/aihub/SprkCodec;->metadata([B)Ljava/lang/String;
  03ac move-result-object v4
  03ae invoke-direct v0, v4, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  03b4 invoke-virtual v2, Ljava/io/InputStream;->close()V
  03ba move-object v9, v0
  03bc move-object/from16 v5, v26
  03c0 move-object/from16 v7, v27
  03c4 move-object/from16 v6, v29
  03c8 move-object/from16 v0, v30
  03cc const/4 v4, 0
  03ce const/4 v15, 1
  03d0 goto/16 +08fh
  03d4 move-exception v0
  03d6 move-object v1, v0
  03d8 invoke-virtual v2, Ljava/io/InputStream;->close()V
  03de goto +6h
  03e0 move-exception v0
  03e2 move-object v2, v0
  03e4 invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  03ea throw v1
  03ec new-instance v0, Ljava/io/IOException;
  03f0 const-string v1, "Sparking metadata exceeds1MiB."
  03f4 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03fa throw v0
  03fc const/4 v0, 0
  03fe aget-object v5, v3, v0
  0402 invoke-virtual v5, v12, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0408 move-result v0
  040a if-eqz v0, +02ch
  040e move-object/from16 v0, v30
  0412 invoke-virtual v0, v4, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0418 iget-object v2, v13, Lcom/personal/aihub/SprkCodec$Member;->name Ljava/lang/String;
  041c sget-object v4, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  0420 invoke-virtual v2, v4, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  0426 move-result-object v2
  0428 const-string v4, ".sql"
  042c invoke-virtual v2, v4, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  0432 move-result v2
  0434 if-nez v2, +010h
  0438 move-object/from16 v9, v21
  043c move/from16 v15, v23
  0440 move-object/from16 v5, v26
  0444 move-object/from16 v7, v27
  0448 move-object/from16 v6, v29
  044c const/4 v4, 0
  044e const/16 v16, 1
  0452 goto +4eh
  0454 move-object/from16 v5, v26
  0458 move-object/from16 v7, v27
  045c move-object/from16 v6, v29
  0460 goto +3ah
  0462 move-object/from16 v0, v30
  0466 const/4 v5, 0
  0468 aget-object v6, v3, v5
  046c invoke-virtual v6, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0472 move-result v2
  0474 if-eqz v2, +00ch
  0478 move-object/from16 v6, v29
  047c invoke-virtual v6, v4, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0482 move-object/from16 v5, v26
  0486 move-object/from16 v7, v27
  048a goto +25h
  048c move-object/from16 v6, v29
  0490 aget-object v2, v3, v5
  0494 const-string v5, "asset"
  0498 invoke-virtual v2, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  049e move-result v2
  04a0 if-eqz v2, +008h
  04a4 move-object/from16 v5, v26
  04a8 invoke-virtual v5, v4, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  04ae goto -14h
  04b0 move-object/from16 v5, v26
  04b4 const/4 v2, 0
  04b6 aget-object v7, v3, v2
  04ba const-string v2, "area"
  04be invoke-virtual v7, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  04c4 move-result v2
  04c6 if-eqz v2, +00dh
  04ca move-object/from16 v7, v27
  04ce invoke-virtual v7, v4, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  04d4 move-object/from16 v9, v21
  04d8 move/from16 v15, v23
  04dc const/4 v4, 0
  04de goto +8h
  04e0 move-object/from16 v7, v27
  04e4 move-object/from16 v9, v21
  04e8 move/from16 v15, v23
  04ec goto -50h
  04ee aget-object v2, v3, v4
  04f2 const-string v8, "other"
  04f6 invoke-virtual v2, v8, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  04fc move-result v2
  04fe if-nez v2, +02ch
  0502 new-instance v2, Ljava/lang/StringBuilder;
  0506 invoke-direct v2, Ljava/lang/StringBuilder;-><init>()V
  050c aget-object v8, v3, v4
  0510 invoke-virtual v2, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0516 const-string v8, ":"
  051a invoke-virtual v2, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0520 const/4 v8, 1
  0522 aget-object v3, v3, v8
  0526 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  052c invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0532 move-result-object v2
  0534 move-object/from16 v3, v28
  0538 invoke-interface v3, v2, Ljava/util/Set;->add(Ljava/lang/Object;)Z
  053e move-result v2
  0540 if-eqz v2, +003h
  0544 goto +bh
  0546 new-instance v0, Ljava/io/IOException;
  054a const-string v1, "Sparking payload aliases would overwrite the same converted file."
  054e invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0554 throw v0
  0556 move-object/from16 v3, v28
  055a move-object v4, v0
  055c move-object v10, v3
  055e move-object/from16 v0, v17
  0562 move-object/from16 v2, v18
  0566 move-wide/from16 v12, v19
  056a move-object/from16 v8, v22
  056e move-object/from16 v3, v24
  0572 move-object/from16 v11, v25
  0576 move-object/from16 v31, v6
  057a move-object v6, v5
  057c move-object/from16 v5, v31
  0580 goto/16 -240h
  0584 new-instance v0, Ljava/io/IOException;
  0588 const-string v1, "Sparking resource checksum does not match."
  058c invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0592 throw v0
  0594 move-exception v0
  0596 move-object v1, v0
  0598 invoke-virtual v11, Ljava/io/OutputStream;->close()V
  059e goto +6h
  05a0 move-exception v0
  05a2 move-object v2, v0
  05a4 invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  05aa throw v1
  05ac move-exception v0
  05ae move-object v1, v0
  05b0 if-eqz v8, +00bh
  05b4 invoke-virtual v8, Ljava/io/InputStream;->close()V
  05ba goto +6h
  05bc move-exception v0
  05be move-object v2, v0
  05c0 invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  05c6 throw v1
  05c8 move-exception v0
  05ca goto +1eh
  05cc move-object/from16 v24, v3
  05d0 move-object/from16 v25, v11
  05d4 new-instance v0, Ljava/io/IOException;
  05d8 const-string v1, "Missing Sparking ZIP entry."
  05dc invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  05e2 throw v0
  05e4 move-object/from16 v24, v3
  05e8 move-object/from16 v25, v11
  05ec new-instance v0, Ljava/io/IOException;
  05f0 const-string v1, "Unsafe Sparking path."
  05f4 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  05fa throw v0
  05fc move-exception v0
  05fe goto +6h
  0600 move-exception v0
  0602 move-object/from16 v24, v3
  0606 move-object/from16 v25, v11
  060a move-object v1, v0
  060c move-object/from16 v2, v24
  0610 goto/16 +0e2h
  0614 move-object/from16 v24, v3
  0618 move-object v0, v4
  061a move-object/from16 v22, v8
  061e move-object/from16 v21, v9
  0622 move-object/from16 v25, v11
  0626 move/from16 v23, v15
  062a const/4 v4, 0
  062c move-object/from16 v31, v6
  0630 move-object v6, v5
  0632 move-object/from16 v5, v31
  0636 invoke-virtual/range v25, Ljava/util/zip/ZipFile;->close()V
  063c if-nez v23, +00ah
  0640 const-string v3, "This patch has no patch_info.json; keep its file name and supply a creation name."
  0644 move-object/from16 v8, v22
  0648 invoke-virtual v8, v3, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  064e goto +3h
  0650 move-object/from16 v8, v22
  0654 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  065a move-result v3
  065c if-nez v3, +007h
  0660 const-string v3, "No patches/sql game-database payload is present. Assets or local roster data alone cannot create an Eclipse unit."
  0664 invoke-virtual v8, v3, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  066a invoke-virtual v6, Lorg/json/JSONArray;->length()I
  0670 move-result v3
  0672 if-lez v3, +007h
  0676 const-string v3, "This patch contains Sparking-only local roster SQL. It cannot be applied to Eclipse's game database."
  067a invoke-virtual v8, v3, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0680 invoke-virtual v7, Lorg/json/JSONArray;->length()I
  0686 move-result v3
  0688 if-lez v3, +007h
  068c const-string v3, "This patch contains Sparking Areas content whose Eclipse mapping is unverified."
  0690 invoke-virtual v8, v3, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0696 if-eqz v16, +007h
  069a const-string v3, "This archive has payloads outside the verified conversion layout. They need inspection before an Eclipse conversion."
  069e invoke-virtual v8, v3, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  06a4 new-instance v3, Lorg/json/JSONObject;
  06a8 invoke-direct v3, Lorg/json/JSONObject;-><init>()V
  06ae const-string v9, "format"
  06b2 const-string v10, "sparking-sprk"
  06b6 invoke-virtual v3, v9, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  06bc move-result-object v3
  06be const-string v9, "formatVersion"
  06c2 const/4 v10, 1
  06c4 invoke-virtual v3, v9, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  06ca move-result-object v3
  06cc const-string v9, "patchInfo"
  06d0 move-object/from16 v11, v21
  06d4 invoke-virtual v3, v9, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  06da move-result-object v3
  06dc const-string v9, "creatorName"
  06e0 invoke-static v11, Lcom/personal/aihub/SprkCodec;->creatorName(Lorg/json/JSONObject;)Ljava/lang/String;
  06e6 move-result-object v13
  06e8 invoke-virtual v3, v9, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  06ee move-result-object v3
  06f0 const-string v9, "creatorId"
  06f4 invoke-static v11, Lcom/personal/aihub/SprkCodec;->creatorId(Lorg/json/JSONObject;)J
  06fa move-result-wide v10
  06fc invoke-virtual v3, v9, v10, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0702 move-result-object v3
  0704 const-string v9, "entries"
  0708 invoke-virtual v3, v9, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  070e move-result-object v1
  0710 invoke-virtual v1, v12, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0716 move-result-object v1
  0718 invoke-virtual v1, v2, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  071e move-result-object v1
  0720 const-string v2, "assets"
  0724 invoke-virtual v1, v2, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  072a move-result-object v1
  072c const-string v2, "areas"
  0730 invoke-virtual v1, v2, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0736 move-result-object v1
  0738 const-string v2, "warnings"
  073c invoke-virtual v1, v2, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0742 move-result-object v1
  0744 move-wide/from16 v12, v19
  0748 invoke-virtual v1, v14, v12, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  074e move-result-object v1
  0750 const-string v2, "canConvertToEclp"
  0754 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  075a move-result v0
  075c if-lez v0, +012h
  0760 invoke-virtual v6, Lorg/json/JSONArray;->length()I
  0766 move-result v0
  0768 if-nez v0, +00ch
  076c invoke-virtual v7, Lorg/json/JSONArray;->length()I
  0772 move-result v0
  0774 if-nez v0, +006h
  0778 if-nez v16, +004h
  077c const/4 v14, 1
  077e goto +2h
  0780 move v14, v4
  0782 invoke-virtual v1, v2, v14, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0788 move-result-object v0
  078a move-object/from16 v1, v18
  078e move-object/from16 v2, v24
  0792 invoke-virtual v2, v1, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  0798 move-result v1
  079a if-eqz v1, +00ch
  079e invoke-virtual v2, Ljava/io/File;->exists()Z
  07a4 move-result v1
  07a6 if-eqz v1, +005h
  07aa invoke-static v2, Lcom/personal/aihub/SprkCodec;->erase(Ljava/io/File;)V
  07b0 return-object v0
  07b2 new-instance v0, Ljava/io/IOException;
  07b6 const-string v1, "Could not commit staged Sparking resources."
  07ba invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  07c0 throw v0
  07c2 move-exception v0
  07c4 move-object/from16 v2, v24
  07c8 goto +14h
  07ca move-exception v0
  07cc move-object v2, v3
  07ce move-object/from16 v25, v11
  07d2 move-object v1, v0
  07d4 invoke-virtual/range v25, Ljava/util/zip/ZipFile;->close()V
  07da goto +6h
  07dc move-exception v0
  07de move-object v3, v0
  07e0 invoke-virtual v1, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  07e6 throw v1
  07e8 move-exception v0
  07ea goto +3h
  07ec move-exception v0
  07ee move-object v2, v3
  07f0 invoke-virtual v2, Ljava/io/File;->exists()Z
  07f6 move-result v1
  07f8 if-eqz v1, +005h
  07fc invoke-static v2, Lcom/personal/aihub/SprkCodec;->erase(Ljava/io/File;)V
  0802 throw v0
  0804 new-instance v0, Ljava/io/IOException;
  0808 const-string v1, "Could not create Sparking conversion staging."
  080c invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0812 throw v0
  0814 new-instance v0, Ljava/io/IOException;
  0818 const-string v1, "Choose a new empty location for Sparking conversion."
  081c invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0822 throw v0
.end method

.method keyFromApk(Ljava/io/File;)[B
  0000 invoke-static v4, Lcom/personal/aihub/SprkCodec;->supportedLibrary(Ljava/io/File;)[B
  0006 move-result-object v4
  0008 const/16 v0, 32
  000c new-array v0, v0, [B
  0010 const/4 v1, 0
  0012 const/16 v2, 16
  0016 const v3, 648423
  001c invoke-static v4, v3, v0, v1, v2, Ljava/lang/System;->arraycopy(Ljava/lang/Object; I Ljava/lang/Object; I I)V
  0022 return-object v0
.end method

.method metadata([B)Ljava/lang/String;
  0000 sget-object v0, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0004 invoke-virtual v0, Ljava/nio/charset/Charset;->newDecoder()Ljava/nio/charset/CharsetDecoder;
  000a move-result-object v0
  000c sget-object v1, Ljava/nio/charset/CodingErrorAction;->REPORT Ljava/nio/charset/CodingErrorAction;
  0010 invoke-virtual v0, v1, Ljava/nio/charset/CharsetDecoder;->onMalformedInput(Ljava/nio/charset/CodingErrorAction;)Ljava/nio/charset/CharsetDecoder;
  0016 move-result-object v0
  0018 invoke-static v9, Ljava/nio/ByteBuffer;->wrap([B)Ljava/nio/ByteBuffer;
  001e move-result-object v9
  0020 invoke-virtual v0, v9, Ljava/nio/charset/CharsetDecoder;->decode(Ljava/nio/ByteBuffer;)Ljava/nio/CharBuffer;
  0026 move-result-object v9
  0028 invoke-virtual v9, Ljava/nio/CharBuffer;->toString()Ljava/lang/String;
  002e move-result-object v9
  0030 const/4 v0, 0
  0032 move v1, v0
  0034 move v2, v1
  0036 move v3, v2
  0038 move v4, v3
  003a invoke-virtual v9, Ljava/lang/String;->length()I
  0040 move-result v5
  0042 if-ge v1, v5, +042h
  0046 invoke-virtual v9, v1, Ljava/lang/String;->charAt(I)C
  004c move-result v5
  004e const/16 v6, 34
  0052 const/4 v7, 1
  0054 if-eqz v2, +010h
  0058 if-eqz v3, +004h
  005c move v3, v0
  005e goto +29h
  0060 const/16 v8, 92
  0064 if-ne v5, v8, +004h
  0068 move v3, v7
  006a goto +23h
  006c if-ne v5, v6, +022h
  0070 move v2, v0
  0072 goto +1fh
  0074 if-ne v5, v6, +004h
  0078 move v2, v7
  007a goto +1bh
  007c const/16 v6, 123
  0080 if-eq v5, v6, +012h
  0084 const/16 v6, 91
  0088 if-ne v5, v6, +003h
  008c goto +ch
  008e const/16 v6, 125
  0092 if-eq v5, v6, +006h
  0096 const/16 v6, 93
  009a if-ne v5, v6, +00bh
  009e add-int/lit8 v4, v4, -1
  00a2 goto +7h
  00a4 add-int/lit8 v4, v4, 1
  00a8 const/16 v5, 32
  00ac if-gt v4, v5, +005h
  00b0 add-int/lit8 v1, v1, 1
  00b4 goto -3dh
  00b6 new-instance v9, Ljava/io/IOException;
  00ba const-string v0, "Sparking patch metadata is nested too deeply."
  00be invoke-direct v9, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00c4 throw v9
  00c6 return-object v9
.end method

.method name([B I)Ljava/lang/String;
  0000 and-int/lit16 v2, v2, 2048
  0004 if-eqz v2, +005h
  0008 sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  000c goto +7h
  000e const-string v2, "CP437"
  0012 invoke-static v2, Ljava/nio/charset/Charset;->forName(Ljava/lang/String;)Ljava/nio/charset/Charset;
  0018 move-result-object v2
  001a invoke-virtual v2, Ljava/nio/charset/Charset;->newDecoder()Ljava/nio/charset/CharsetDecoder;
  0020 move-result-object v2
  0022 sget-object v0, Ljava/nio/charset/CodingErrorAction;->REPORT Ljava/nio/charset/CodingErrorAction;
  0026 invoke-virtual v2, v0, Ljava/nio/charset/CharsetDecoder;->onMalformedInput(Ljava/nio/charset/CodingErrorAction;)Ljava/nio/charset/CharsetDecoder;
  002c move-result-object v2
  002e sget-object v0, Ljava/nio/charset/CodingErrorAction;->REPORT Ljava/nio/charset/CodingErrorAction;
  0032 invoke-virtual v2, v0, Ljava/nio/charset/CharsetDecoder;->onUnmappableCharacter(Ljava/nio/charset/CodingErrorAction;)Ljava/nio/charset/CharsetDecoder;
  0038 move-result-object v2
  003a invoke-static v1, Ljava/nio/ByteBuffer;->wrap([B)Ljava/nio/ByteBuffer;
  0040 move-result-object v1
  0042 invoke-virtual v2, v1, Ljava/nio/charset/CharsetDecoder;->decode(Ljava/nio/ByteBuffer;)Ljava/nio/CharBuffer;
  0048 move-result-object v1
  004a invoke-virtual v1, Ljava/nio/CharBuffer;->toString()Ljava/lang/String;
  0050 move-result-object v1
  0052 return-object v1
.end method

.method role(Ljava/lang/String;)[Ljava/lang/String;
  0000 const-string v0, "patch_info.json"
  0004 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  000a move-result v0
  000c if-eqz v0, +009h
  0010 const-string v0, "metadata"
  0014 filled-new-array v0, v6, [Ljava/lang/String;
  001a move-result-object v6
  001c return-object v6
  001e const-string v0, "patches/localsql/"
  0022 const-string v1, "localsql/"
  0026 filled-new-array v0, v1, [Ljava/lang/String;
  002c move-result-object v0
  002e const/4 v1, 0
  0030 move v2, v1
  0032 const/4 v3, 2
  0034 if-ge v2, v3, +01ch
  0038 aget-object v3, v0, v2
  003c invoke-virtual v6, v3, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0042 move-result v4
  0044 if-eqz v4, +011h
  0048 invoke-virtual v3, Ljava/lang/String;->length()I
  004e move-result v0
  0050 invoke-virtual v6, v0, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0056 move-result-object v6
  0058 const-string v0, "localSql"
  005c filled-new-array v0, v6, [Ljava/lang/String;
  0062 move-result-object v6
  0064 return-object v6
  0066 add-int/lit8 v2, v2, 1
  006a goto -1ch
  006c const-string v0, "patches/sql/"
  0070 invoke-virtual v6, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0076 move-result v0
  0078 if-eqz v0, +00fh
  007c const/16 v0, 12
  0080 invoke-virtual v6, v0, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0086 move-result-object v6
  0088 const-string v0, "gameSql"
  008c filled-new-array v0, v6, [Ljava/lang/String;
  0092 move-result-object v6
  0094 return-object v6
  0096 const-string v0, "patches/assets/"
  009a const-string v2, "assets/"
  009e filled-new-array v0, v2, [Ljava/lang/String;
  00a4 move-result-object v0
  00a6 move v2, v1
  00a8 if-ge v2, v3, +01ch
  00ac aget-object v4, v0, v2
  00b0 invoke-virtual v6, v4, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00b6 move-result v5
  00b8 if-eqz v5, +011h
  00bc invoke-virtual v4, Ljava/lang/String;->length()I
  00c2 move-result v0
  00c4 invoke-virtual v6, v0, Ljava/lang/String;->substring(I)Ljava/lang/String;
  00ca move-result-object v6
  00cc const-string v0, "asset"
  00d0 filled-new-array v0, v6, [Ljava/lang/String;
  00d6 move-result-object v6
  00d8 return-object v6
  00da add-int/lit8 v2, v2, 1
  00de goto -1bh
  00e0 const-string v0, "Areas/"
  00e4 const-string v2, "areas/"
  00e8 const-string v3, "patches/Areas/"
  00ec filled-new-array v3, v0, v2, [Ljava/lang/String;
  00f2 move-result-object v0
  00f4 const/4 v2, 3
  00f6 if-ge v1, v2, +01ch
  00fa aget-object v2, v0, v1
  00fe invoke-virtual v6, v2, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0104 move-result v3
  0106 if-eqz v3, +011h
  010a invoke-virtual v2, Ljava/lang/String;->length()I
  0110 move-result v0
  0112 invoke-virtual v6, v0, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0118 move-result-object v6
  011a const-string v0, "area"
  011e filled-new-array v0, v6, [Ljava/lang/String;
  0124 move-result-object v6
  0126 return-object v6
  0128 add-int/lit8 v1, v1, 1
  012c goto -1ch
  012e const-string v0, "other"
  0132 filled-new-array v0, v6, [Ljava/lang/String;
  0138 move-result-object v6
  013a return-object v6
.end method

.method safe(Ljava/lang/String;)V
  0000 invoke-virtual v5, Ljava/lang/String;->isEmpty()Z
  0006 move-result v0
  0008 const-string v1, "The Sparking archive contains an unsafe file path."
  000c if-nez v0, +04dh
  0010 invoke-virtual v5, Ljava/lang/String;->length()I
  0016 move-result v0
  0018 const/16 v2, 500
  001c if-gt v0, v2, +045h
  0020 const-string v0, "/"
  0024 invoke-virtual v5, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  002a move-result v2
  002c if-nez v2, +03dh
  0030 const/16 v2, 92
  0034 invoke-virtual v5, v2, Ljava/lang/String;->indexOf(I)I
  003a move-result v2
  003c if-gez v2, +035h
  0040 const-string v2, "(?s).*[:\x00-\x1f\x7f].*"
  0044 invoke-virtual v5, v2, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  004a move-result v2
  004c if-nez v2, +02dh
  0050 const/4 v2, -1
  0052 invoke-virtual v5, v0, v2, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  0058 move-result-object v5
  005a array-length v0, v5
  005c const/4 v2, 0
  005e if-ge v2, v0, +023h
  0062 aget-object v3, v5, v2
  0066 invoke-virtual v3, Ljava/lang/String;->isEmpty()Z
  006c move-result v4
  006e if-nez v4, +015h
  0072 const-string v4, "."
  0076 invoke-virtual v3, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  007c move-result v4
  007e if-nez v4, +00dh
  0082 const-string v4, ".."
  0086 invoke-virtual v3, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  008c move-result v3
  008e if-nez v3, +005h
  0092 add-int/lit8 v2, v2, 1
  0096 goto -1ch
  0098 new-instance v5, Ljava/io/IOException;
  009c invoke-direct v5, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00a2 throw v5
  00a4 return-void 
  00a6 new-instance v5, Ljava/io/IOException;
  00aa invoke-direct v5, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00b0 throw v5
.end method

.method supportedLibrary(Ljava/io/File;)[B
  0000 invoke-virtual v6, Ljava/io/File;->isFile()Z
  0006 move-result v0
  0008 if-eqz v0, +09bh
  000c new-instance v0, Ljava/util/zip/ZipFile;
  0010 invoke-direct v0, v6, Ljava/util/zip/ZipFile;-><init>(Ljava/io/File;)V
  0016 invoke-virtual v0, Ljava/util/zip/ZipFile;->entries()Ljava/util/Enumeration;
  001c move-result-object v6
  001e const/4 v1, 0
  0020 invoke-interface v6, Ljava/util/Enumeration;->hasMoreElements()Z
  0026 move-result v2
  0028 if-eqz v2, +020h
  002c invoke-interface v6, Ljava/util/Enumeration;->nextElement()Ljava/lang/Object;
  0032 move-result-object v2
  0034 check-cast v2, Ljava/util/zip/ZipEntry;
  0038 invoke-virtual v2, Ljava/util/zip/ZipEntry;->getName()Ljava/lang/String;
  003e move-result-object v3
  0040 const-string v4, "lib/arm64-v8a/libbase.so"
  0044 invoke-virtual v3, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  004a move-result v3
  004c if-eqz v3, -016h
  0050 if-nez v1, +004h
  0054 move-object v1, v2
  0056 goto -1bh
  0058 new-instance v6, Ljava/io/IOException;
  005c const-string v1, "The APK has duplicate native libraries."
  0060 invoke-direct v6, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0066 throw v6
  0068 if-eqz v1, +059h
  006c invoke-virtual v1, Ljava/util/zip/ZipEntry;->isDirectory()Z
  0072 move-result v6
  0074 if-nez v6, +053h
  0078 invoke-virtual v1, Ljava/util/zip/ZipEntry;->getSize()J
  007e move-result-wide v2
  0080 const-wide/32 v4, 648439
  0086 cmp-long v6, v2, v4
  008a if-ltz v6, +048h
  008e invoke-virtual v1, Ljava/util/zip/ZipEntry;->getSize()J
  0094 move-result-wide v2
  0096 const-wide/32 v4, 16777216
  009c cmp-long v6, v2, v4
  00a0 if-gtz v6, +03dh
  00a4 invoke-virtual v1, Ljava/util/zip/ZipEntry;->getCompressedSize()J
  00aa move-result-wide v2
  00ac cmp-long v6, v2, v4
  00b0 if-gtz v6, +035h
  00b4 invoke-virtual v0, v1, Ljava/util/zip/ZipFile;->getInputStream(Ljava/util/zip/ZipEntry;)Ljava/io/InputStream;
  00ba move-result-object v6
  00bc const/high16 v1, 16777216
  00c0 invoke-static v6, v1, Lcom/personal/aihub/SprkCodec;->bounded(Ljava/io/InputStream; I)[B
  00c6 move-result-object v1
  00c8 if-eqz v6, +005h
  00cc invoke-virtual v6, Ljava/io/InputStream;->close()V
  00d2 const-string v6, "9d3f2749e391d990496b632b6adc135492f71e0baec7125d7b613a56e771dca0"
  00d6 invoke-static v1, Lcom/personal/aihub/SprkCodec;->hash([B)Ljava/lang/String;
  00dc move-result-object v2
  00de invoke-virtual v6, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00e4 move-result v6
  00e6 if-eqz v6, +006h
  00ea invoke-virtual v0, Ljava/util/zip/ZipFile;->close()V
  00f0 return-object v1
  00f2 new-instance v6, Ljava/io/IOException;
  00f6 const-string v1, "This Sparking APK version is not supported for SPRK conversion. Its native format must be checked before importing encrypted patches."
  00fa invoke-direct v6, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0100 throw v6
  0102 move-exception v1
  0104 if-eqz v6, +00ah
  0108 invoke-virtual v6, Ljava/io/InputStream;->close()V
  010e goto +5h
  0110 move-exception v6
  0112 invoke-virtual v1, v6, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0118 throw v1
  011a new-instance v6, Ljava/io/IOException;
  011e const-string v1, "This APK does not contain the supported Sparking6.5.5 Android format library."
  0122 invoke-direct v6, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0128 throw v6
  012a move-exception v6
  012c invoke-virtual v0, Ljava/util/zip/ZipFile;->close()V
  0132 goto +5h
  0134 move-exception v0
  0136 invoke-virtual v6, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  013c throw v6
  013e new-instance v6, Ljava/io/IOException;
  0142 const-string v0, "Import the original Sparking6.5.5 Android APK first."
  0146 invoke-direct v6, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  014c throw v6
.end method

.method u16([B I)I
  0000 aget-byte v0, v1, v2
  0004 and-int/lit16 v0, v0, 255
  0008 add-int/lit8 v2, v2, 1
  000c aget-byte v1, v1, v2
  0010 and-int/lit16 v1, v1, 255
  0014 shl-int/lit8 v1, v1, 8
  0018 or-int/2addr v1, v0
  001a return v1
.end method

.method u32([B I)J
  0000 invoke-static v3, v4, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  0006 move-result v0
  0008 int-to-long v0, v0
  000a add-int/lit8 v4, v4, 2
  000e invoke-static v3, v4, Lcom/personal/aihub/SprkCodec;->u16([B I)I
  0014 move-result v3
  0016 int-to-long v3, v3
  0018 const/16 v2, 16
  001c shl-long/2addr v3, v2
  001e or-long/2addr v3, v0
  0020 return-wide v3
.end method