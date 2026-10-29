.class Lcom/personal/aihub/ImageAssets;
.super Ljava/lang/Object;
.field LIMIT I
.field root Ljava/io/File;

.method <init>(Ljava/io/File;)V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 iput-object v1, v0, Lcom/personal/aihub/ImageAssets;->root Ljava/io/File;
  000a return-void 
.end method

.method be([B I I)J
  0000 const-wide/16 v0, 0
  0004 const/4 v2, 0
  0006 if-ge v2, v7, +010h
  000a const/16 v3, 8
  000e shl-long/2addr v0, v3
  0010 add-int v3, v6, v2
  0014 invoke-static v5, v3, Lcom/personal/aihub/ImageAssets;->u([B I)I
  001a move-result v3
  001c int-to-long v3, v3
  001e or-long/2addr v0, v3
  0020 add-int/lit8 v2, v2, 1
  0024 goto -fh
  0026 return-wide v0
.end method

.method dimensions(J J Ljava/lang/String;)Lorg/json/JSONObject;
  0000 const-wide/16 v0, 1
  0004 cmp-long v2, v4, v0
  0008 if-ltz v2, +031h
  000c cmp-long v0, v6, v0
  0010 if-ltz v0, +02dh
  0014 const-wide/16 v0, 4096
  0018 cmp-long v2, v4, v0
  001c if-gtz v2, +027h
  0020 cmp-long v0, v6, v0
  0024 if-gtz v0, +023h
  0028 mul-long v0, v4, v6
  002c const-wide/32 v2, 16000000
  0032 cmp-long v0, v0, v2
  0036 if-gtz v0, +01ah
  003a new-instance v0, Lorg/json/JSONObject;
  003e invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  0044 const-string v1, "width"
  0048 invoke-virtual v0, v1, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  004e move-result-object v4
  0050 const-string v5, "height"
  0054 invoke-virtual v4, v5, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  005a move-result-object v4
  005c const-string v5, "mime"
  0060 invoke-virtual v4, v5, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0066 move-result-object v4
  0068 return-object v4
  006a invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  0070 move-result-object v4
  0072 throw v4
.end method

.method file(Ljava/lang/String;)Ljava/io/File;
  0000 invoke-direct v5, Lcom/personal/aihub/ImageAssets;->rootValid()V
  0006 invoke-static v6, Lcom/personal/aihub/ImageAssets;->safe(Ljava/lang/String;)Z
  000c move-result v0
  000e if-eqz v0, +059h
  0012 iget-object v0, v5, Lcom/personal/aihub/ImageAssets;->root Ljava/io/File;
  0016 const-string v1, "/"
  001a invoke-virtual v6, v1, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  0020 move-result-object v6
  0022 array-length v1, v6
  0024 const/4 v2, 0
  0026 if-ge v2, v1, +01ch
  002a new-instance v3, Ljava/io/File;
  002e aget-object v4, v6, v2
  0032 invoke-direct v3, v0, v4, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0038 invoke-virtual v3, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  003e move-result-object v0
  0040 invoke-static v0, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  0046 move-result v0
  0048 if-nez v0, +006h
  004c add-int/lit8 v2, v2, 1
  0050 move-object v0, v3
  0052 goto -16h
  0054 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  005a move-result-object v6
  005c throw v6
  005e invoke-virtual v0, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  0064 move-result-object v6
  0066 new-instance v1, Ljava/lang/StringBuilder;
  006a invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  0070 iget-object v2, v5, Lcom/personal/aihub/ImageAssets;->root Ljava/io/File;
  0074 invoke-virtual v2, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  007a move-result-object v2
  007c invoke-static v2, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0082 move-result-object v2
  0084 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  008a sget-object v2, Ljava/io/File;->separator Ljava/lang/String;
  008e invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0094 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  009a move-result-object v1
  009c invoke-virtual v6, v1, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00a2 move-result v6
  00a4 if-eqz v6, +009h
  00a8 invoke-virtual v0, Ljava/io/File;->isFile()Z
  00ae move-result v6
  00b0 if-eqz v6, +003h
  00b4 return-object v0
  00b6 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  00bc move-result-object v6
  00be throw v6
  00c0 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  00c6 move-result-object v6
  00c8 throw v6
.end method

.method inspect([B Z)Lorg/json/JSONObject;
  0000 move-object/from16 v0, v32
  0004 array-length v1, v0
  0006 const/16 v2, 12
  000a if-lt v1, v2, +438h
  000e array-length v1, v0
  0010 const/high16 v3, 12582912
  0014 if-gt v1, v3, +433h
  0018 const/16 v1, 8
  001c invoke-static v0, v1, Ljava/util/Arrays;->copyOf([B I)[B
  0022 move-result-object v3
  0024 new-array v4, v1, [B
  0028 fill-array-data v4, +000042eh
  002e invoke-static v3, v4, Ljava/util/Arrays;->equals([B [B)Z
  0034 move-result v3
  0036 const-wide/16 v4, 12
  003a const/4 v9, 0
  003c const/4 v12, 4
  003e if-eqz v3, +1bch
  0042 new-instance v2, Ljava/io/ByteArrayOutputStream;
  0046 invoke-direct v2, Ljava/io/ByteArrayOutputStream;-><init>()V
  004c const/4 v3, 0
  004e move v13, v1
  0050 move v14, v9
  0052 add-int/lit8 v15, v13, 12
  0056 array-length v6, v0
  0058 if-le v15, v6, +005h
  005c move-object v7, v2
  005e goto/16 +0fbh
  0062 move-object/from16 v16, v2
  0066 invoke-static v0, v13, v12, Lcom/personal/aihub/ImageAssets;->be([B I I)J
  006c move-result-wide v1
  006e const-wide/32 v17, 12582912
  0074 cmp-long v17, v1, v17
  0078 if-gtz v17, +19ah
  007c int-to-long v10, v13
  007e add-long/2addr v10, v4
  0080 add-long/2addr v10, v1
  0082 array-length v6, v0
  0084 int-to-long v4, v6
  0086 cmp-long v4, v10, v4
  008a if-gtz v4, +191h
  008e long-to-int v1, v1
  0090 add-int v2, v15, v1
  0094 add-int/lit8 v4, v13, 4
  0098 invoke-static v0, v4, v12, Lcom/personal/aihub/ImageAssets;->text([B I I)Ljava/lang/String;
  009e move-result-object v5
  00a0 const-string v6, "[A-Za-z]{2}[A-Z][A-Za-z]"
  00a4 invoke-virtual v5, v6, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  00aa move-result v6
  00ac if-eqz v6, +17bh
  00b0 const-string v10, "IEND"
  00b4 const-string v11, "IDAT"
  00b8 const-string v6, "IHDR"
  00bc if-eqz v33, +01ah
  00c0 invoke-virtual v5, v9, Ljava/lang/String;->charAt(I)C
  00c6 move-result v22
  00c8 invoke-static/range v22, Ljava/lang/Character;->isUpperCase(C)Z
  00ce move-result v22
  00d0 if-eqz v22, +010h
  00d4 filled-new-array v6, v11, v10, [Ljava/lang/String;
  00da move-result-object v22
  00dc invoke-static/range v22, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  00e2 move-result-object v9
  00e4 invoke-interface v9, v5, Ljava/util/List;->contains(Ljava/lang/Object;)Z
  00ea move-result v9
  00ec if-eqz v9, +15bh
  00f0 new-instance v9, Ljava/util/zip/CRC32;
  00f4 invoke-direct v9, Ljava/util/zip/CRC32;-><init>()V
  00fa add-int/lit8 v8, v1, 4
  00fe invoke-virtual v9, v0, v4, v8, Ljava/util/zip/CRC32;->update([B I I)V
  0104 add-int/lit8 v4, v13, 8
  0108 invoke-virtual v9, Ljava/util/zip/CRC32;->getValue()J
  010e move-result-wide v8
  0110 add-int v7, v4, v1
  0114 invoke-static v0, v7, v12, Lcom/personal/aihub/ImageAssets;->be([B I I)J
  011a move-result-wide v25
  011c cmp-long v7, v8, v25
  0120 if-nez v7, +13ch
  0124 if-nez v3, +071h
  0128 invoke-virtual v5, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  012e move-result v3
  0130 if-eqz v3, +066h
  0134 const/16 v3, 13
  0138 if-ne v1, v3, +062h
  013c invoke-static v0, v4, v12, Lcom/personal/aihub/ImageAssets;->be([B I I)J
  0142 move-result-wide v6
  0144 invoke-static v0, v15, v12, Lcom/personal/aihub/ImageAssets;->be([B I I)J
  014a move-result-wide v8
  014c const-string v3, "image/png"
  0150 invoke-static v6, v7, v8, v9, v3, Lcom/personal/aihub/ImageAssets;->dimensions(J J Ljava/lang/String;)Lorg/json/JSONObject;
  0156 move-result-object v3
  0158 add-int/lit8 v7, v13, 20
  015c add-int/lit8 v6, v13, 18
  0160 invoke-static v0, v6, Lcom/personal/aihub/ImageAssets;->u([B I)I
  0166 move-result v6
  0168 if-nez v6, +045h
  016c add-int/lit8 v6, v13, 19
  0170 invoke-static v0, v6, Lcom/personal/aihub/ImageAssets;->u([B I)I
  0176 move-result v6
  0178 if-nez v6, +03dh
  017c invoke-static v0, v7, Lcom/personal/aihub/ImageAssets;->u([B I)I
  0182 move-result v6
  0184 const/4 v8, 1
  0186 if-gt v6, v8, +036h
  018a add-int/lit8 v8, v13, 17
  018e if-eqz v33, +026h
  0192 add-int/lit8 v13, v13, 16
  0196 invoke-static v0, v13, Lcom/personal/aihub/ImageAssets;->u([B I)I
  019c move-result v6
  019e const/16 v9, 8
  01a2 if-ne v6, v9, +017h
  01a6 invoke-static v0, v8, Lcom/personal/aihub/ImageAssets;->u([B I)I
  01ac move-result v9
  01ae const/4 v13, 2
  01b0 if-eq v9, v13, +009h
  01b4 invoke-static v0, v8, Lcom/personal/aihub/ImageAssets;->u([B I)I
  01ba move-result v9
  01bc const/4 v13, 6
  01be if-ne v9, v13, +009h
  01c2 invoke-static v0, v7, Lcom/personal/aihub/ImageAssets;->u([B I)I
  01c8 move-result v7
  01ca if-nez v7, +003h
  01ce goto +6h
  01d0 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  01d6 move-result-object v0
  01d8 throw v0
  01da invoke-static v0, v8, Lcom/personal/aihub/ImageAssets;->u([B I)I
  01e0 move-result v7
  01e2 const/4 v8, 6
  01e4 if-ne v7, v8, +004h
  01e8 move v7, v12
  01ea goto +2h
  01ec const/4 v7, 3
  01ee move v14, v7
  01f0 goto +12h
  01f2 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  01f8 move-result-object v0
  01fa throw v0
  01fc invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  0202 move-result-object v0
  0204 throw v0
  0206 move-object v7, v6
  0208 invoke-virtual v5, v7, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  020e move-result v7
  0210 if-nez v7, +0bfh
  0214 invoke-virtual v5, v11, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  021a move-result v7
  021c if-eqz v7, +008h
  0220 move-object/from16 v7, v16
  0224 invoke-virtual v7, v0, v4, v1, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  022a goto +3h
  022c move-object/from16 v7, v16
  0230 invoke-virtual v5, v10, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0236 move-result v4
  0238 if-eqz v4, +082h
  023c if-nez v1, +07bh
  0240 array-length v0, v0
  0242 if-ne v2, v0, +078h
  0246 invoke-virtual v7, Ljava/io/ByteArrayOutputStream;->size()I
  024c move-result v0
  024e if-eqz v0, +072h
  0252 const/4 v9, 1
  0254 if-eqz v9, +06ah
  0258 if-eqz v33, +067h
  025c const-string v0, "width"
  0260 invoke-virtual v3, v0, Lorg/json/JSONObject;->getInt(Ljava/lang/String;)I
  0266 move-result v0
  0268 mul-int/2addr v0, v14
  026a const/4 v1, 1
  026c add-int/2addr v0, v1
  026e const-string v1, "height"
  0272 invoke-virtual v3, v1, Lorg/json/JSONObject;->getInt(Ljava/lang/String;)I
  0278 move-result v1
  027a mul-int/2addr v1, v0
  027c new-instance v2, Ljava/util/zip/Inflater;
  0280 invoke-direct v2, Ljava/util/zip/Inflater;-><init>()V
  0286 invoke-virtual v7, Ljava/io/ByteArrayOutputStream;->toByteArray()[B
  028c move-result-object v4
  028e invoke-virtual v2, v4, Ljava/util/zip/Inflater;->setInput([B)V
  0294 const/high16 v4, 65536
  0298 new-array v4, v4, [B
  029c const/4 v5, 0
  029e invoke-virtual v2, Ljava/util/zip/Inflater;->finished()Z
  02a4 move-result v6
  02a6 if-nez v6, +02ah
  02aa invoke-virtual v2, v4, Ljava/util/zip/Inflater;->inflate([B)I
  02b0 move-result v6
  02b2 if-eqz v6, +01fh
  02b6 sub-int v7, v1, v5
  02ba if-gt v6, v7, +01bh
  02be const/4 v7, 0
  02c0 if-ge v7, v6, +016h
  02c4 add-int v8, v5, v7
  02c8 rem-int/2addr v8, v0
  02ca if-nez v8, +00eh
  02ce invoke-static v4, v7, Lcom/personal/aihub/ImageAssets;->u([B I)I
  02d4 move-result v8
  02d6 if-gt v8, v12, +003h
  02da goto +6h
  02dc invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  02e2 move-result-object v0
  02e4 throw v0
  02e6 add-int/lit8 v7, v7, 1
  02ea goto -15h
  02ec add-int/2addr v5, v6
  02ee goto -28h
  02f0 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  02f6 move-result-object v0
  02f8 throw v0
  02fa if-ne v5, v1, +00ch
  02fe invoke-virtual v2, Ljava/util/zip/Inflater;->getRemaining()I
  0304 move-result v0
  0306 if-nez v0, +006h
  030a invoke-virtual v2, Ljava/util/zip/Inflater;->end()V
  0310 goto +bh
  0312 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  0318 move-result-object v0
  031a throw v0
  031c move-exception v0
  031e invoke-virtual v2, Ljava/util/zip/Inflater;->end()V
  0324 throw v0
  0326 return-object v3
  0328 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  032e move-result-object v0
  0330 throw v0
  0332 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  0338 move-result-object v0
  033a throw v0
  033c if-eqz v33, +020h
  0340 const-string v1, "acTL"
  0344 invoke-virtual v5, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  034a move-result v1
  034c if-nez v1, +013h
  0350 const-string v1, "fcTL"
  0354 invoke-virtual v5, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  035a move-result v1
  035c if-nez v1, +00bh
  0360 const-string v1, "fdAT"
  0364 invoke-virtual v5, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  036a move-result v1
  036c if-nez v1, +003h
  0370 goto +6h
  0372 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  0378 move-result-object v0
  037a throw v0
  037c move v13, v2
  037e move-object v2, v7
  0380 const/16 v1, 8
  0384 const-wide/16 v4, 12
  0388 const/4 v9, 0
  038a goto/16 -19ch
  038e invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  0394 move-result-object v0
  0396 throw v0
  0398 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  039e move-result-object v0
  03a0 throw v0
  03a2 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  03a8 move-result-object v0
  03aa throw v0
  03ac invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  03b2 move-result-object v0
  03b4 throw v0
  03b6 if-nez v33, +25ah
  03ba const/4 v1, 0
  03bc invoke-static v0, v1, Lcom/personal/aihub/ImageAssets;->u([B I)I
  03c2 move-result v3
  03c4 const/16 v1, 255
  03c8 if-ne v3, v1, +0e5h
  03cc const/4 v3, 1
  03ce invoke-static v0, v3, Lcom/personal/aihub/ImageAssets;->u([B I)I
  03d4 move-result v4
  03d6 const/16 v3, 216
  03da if-eq v4, v3, +004h
  03de goto/16 +0dah
  03e2 new-instance v2, Ljava/util/HashSet;
  03e6 const/16 v3, 192
  03ea invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  03f0 move-result-object v19
  03f2 const/16 v3, 193
  03f6 invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  03fc move-result-object v20
  03fe const/16 v3, 194
  0402 invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0408 move-result-object v21
  040a const/16 v3, 195
  040e invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0414 move-result-object v22
  0416 const/16 v3, 197
  041a invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0420 move-result-object v23
  0422 const/16 v3, 198
  0426 invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  042c move-result-object v24
  042e const/16 v3, 199
  0432 invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0438 move-result-object v25
  043a const/16 v3, 201
  043e invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0444 move-result-object v26
  0446 const/16 v3, 202
  044a invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0450 move-result-object v27
  0452 const/16 v3, 203
  0456 invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  045c move-result-object v28
  045e const/16 v3, 205
  0462 invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0468 move-result-object v29
  046a const/16 v3, 206
  046e invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0474 move-result-object v30
  0476 const/16 v3, 207
  047a invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0480 move-result-object v31
  0482 filled-new-array/range v19 ... v31, [Ljava/lang/Integer;
  0488 move-result-object v3
  048a invoke-static v3, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  0490 move-result-object v3
  0492 invoke-direct v2, v3, Ljava/util/HashSet;-><init>(Ljava/util/Collection;)V
  0498 const/4 v3, 2
  049a add-int/lit8 v4, v3, 4
  049e array-length v5, v0
  04a0 if-gt v4, v5, +074h
  04a4 add-int/lit8 v4, v3, 1
  04a8 invoke-static v0, v3, Lcom/personal/aihub/ImageAssets;->u([B I)I
  04ae move-result v3
  04b0 if-ne v3, v1, +067h
  04b4 array-length v3, v0
  04b6 if-ge v4, v3, +00bh
  04ba invoke-static v0, v4, Lcom/personal/aihub/ImageAssets;->u([B I)I
  04c0 move-result v3
  04c2 if-ne v3, v1, +005h
  04c6 add-int/lit8 v4, v4, 1
  04ca goto -bh
  04cc add-int/lit8 v3, v4, 3
  04d0 array-length v5, v0
  04d2 if-gt v3, v5, +051h
  04d6 add-int/lit8 v3, v4, 1
  04da invoke-static v0, v4, Lcom/personal/aihub/ImageAssets;->u([B I)I
  04e0 move-result v5
  04e2 const/16 v7, 217
  04e6 if-eq v5, v7, +051h
  04ea const/16 v7, 218
  04ee if-eq v5, v7, +04dh
  04f2 const/4 v7, 1
  04f4 if-eq v5, v7, -02dh
  04f8 const/16 v7, 208
  04fc if-lt v5, v7, +006h
  0500 const/16 v7, 215
  0504 if-le v5, v7, -035h
  0508 const/4 v7, 2
  050a invoke-static v0, v3, v7, Lcom/personal/aihub/ImageAssets;->be([B I I)J
  0510 move-result-wide v8
  0512 long-to-int v8, v8
  0514 if-lt v8, v7, +02bh
  0518 add-int/2addr v3, v8
  051a array-length v9, v0
  051c if-gt v3, v9, +027h
  0520 invoke-static v5, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0526 move-result-object v5
  0528 invoke-virtual v2, v5, Ljava/util/HashSet;->contains(Ljava/lang/Object;)Z
  052e move-result v5
  0530 if-eqz v5, -04bh
  0534 const/16 v5, 8
  0538 if-lt v8, v5, +014h
  053c add-int/lit8 v1, v4, 6
  0540 invoke-static v0, v1, v7, Lcom/personal/aihub/ImageAssets;->be([B I I)J
  0546 move-result-wide v1
  0548 add-int/2addr v4, v12
  054a invoke-static v0, v4, v7, Lcom/personal/aihub/ImageAssets;->be([B I I)J
  0550 move-result-wide v3
  0552 const-string v0, "image/jpeg"
  0556 invoke-static v1, v2, v3, v4, v0, Lcom/personal/aihub/ImageAssets;->dimensions(J J Ljava/lang/String;)Lorg/json/JSONObject;
  055c move-result-object v0
  055e return-object v0
  0560 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  0566 move-result-object v0
  0568 throw v0
  056a invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  0570 move-result-object v0
  0572 throw v0
  0574 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  057a move-result-object v0
  057c throw v0
  057e invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  0584 move-result-object v0
  0586 throw v0
  0588 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  058e move-result-object v0
  0590 throw v0
  0592 const/4 v1, 6
  0594 const/4 v3, 0
  0596 invoke-static v0, v3, v1, Lcom/personal/aihub/ImageAssets;->text([B I I)Ljava/lang/String;
  059c move-result-object v4
  059e const-string v5, "GIF87a"
  05a2 invoke-virtual v4, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  05a8 move-result v4
  05aa if-nez v4, +013h
  05ae invoke-static v0, v3, v1, Lcom/personal/aihub/ImageAssets;->text([B I I)Ljava/lang/String;
  05b4 move-result-object v4
  05b6 const-string v3, "GIF89a"
  05ba invoke-virtual v4, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  05c0 move-result v3
  05c2 if-eqz v3, +003h
  05c6 goto +5h
  05c8 const/4 v1, 0
  05ca const/16 v4, 8
  05ce goto +1bh
  05d0 array-length v3, v0
  05d2 const/16 v4, 13
  05d6 if-lt v3, v4, +014h
  05da const/4 v3, 2
  05dc invoke-static v0, v1, v3, Lcom/personal/aihub/ImageAssets;->le([B I I)J
  05e2 move-result-wide v1
  05e4 const/16 v4, 8
  05e8 invoke-static v0, v4, v3, Lcom/personal/aihub/ImageAssets;->le([B I I)J
  05ee move-result-wide v3
  05f0 const-string v0, "image/gif"
  05f4 invoke-static v1, v2, v3, v4, v0, Lcom/personal/aihub/ImageAssets;->dimensions(J J Ljava/lang/String;)Lorg/json/JSONObject;
  05fa move-result-object v0
  05fc return-object v0
  05fe const/16 v4, 8
  0602 const/4 v1, 0
  0604 invoke-static v0, v1, v12, Lcom/personal/aihub/ImageAssets;->text([B I I)Ljava/lang/String;
  060a move-result-object v3
  060c const-string v1, "RIFF"
  0610 invoke-virtual v3, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0616 move-result v1
  0618 const/16 v3, 14
  061c if-eqz v1, +0ceh
  0620 invoke-static v0, v4, v12, Lcom/personal/aihub/ImageAssets;->text([B I I)Ljava/lang/String;
  0626 move-result-object v1
  0628 const-string v4, "WEBP"
  062c invoke-virtual v1, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0632 move-result v1
  0634 if-eqz v1, +0c2h
  0638 invoke-static v0, v12, v12, Lcom/personal/aihub/ImageAssets;->le([B I I)J
  063e move-result-wide v4
  0640 const-wide/16 v6, 8
  0644 add-long/2addr v4, v6
  0646 array-length v1, v0
  0648 int-to-long v6, v1
  064a cmp-long v1, v4, v6
  064e if-eqz v1, +004h
  0652 goto/16 +0b3h
  0656 add-int/lit8 v1, v2, 8
  065a array-length v4, v0
  065c if-gt v1, v4, +0a9h
  0660 invoke-static v0, v2, v12, Lcom/personal/aihub/ImageAssets;->text([B I I)Ljava/lang/String;
  0666 move-result-object v4
  0668 add-int/lit8 v5, v2, 4
  066c invoke-static v0, v5, v12, Lcom/personal/aihub/ImageAssets;->le([B I I)J
  0672 move-result-wide v5
  0674 int-to-long v7, v1
  0676 add-long/2addr v7, v5
  0678 array-length v9, v0
  067a int-to-long v9, v9
  067c cmp-long v7, v7, v9
  0680 if-gtz v7, +092h
  0684 long-to-int v5, v5
  0686 const-string v6, "VP8X"
  068a invoke-virtual v4, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0690 move-result v6
  0692 const-string v7, "image/webp"
  0696 const-wide/16 v8, 1
  069a const/16 v10, 10
  069e if-eqz v6, +019h
  06a2 if-ge v5, v10, +003h
  06a6 goto +15h
  06a8 add-int/lit8 v1, v2, 12
  06ac const/4 v6, 3
  06ae invoke-static v0, v1, v6, Lcom/personal/aihub/ImageAssets;->le([B I I)J
  06b4 move-result-wide v3
  06b6 add-long/2addr v3, v8
  06b8 add-int/lit8 v2, v2, 15
  06bc invoke-static v0, v2, v6, Lcom/personal/aihub/ImageAssets;->le([B I I)J
  06c2 move-result-wide v0
  06c4 add-long/2addr v0, v8
  06c6 invoke-static v3, v4, v0, v1, v7, Lcom/personal/aihub/ImageAssets;->dimensions(J J Ljava/lang/String;)Lorg/json/JSONObject;
  06cc move-result-object v0
  06ce return-object v0
  06d0 const/4 v6, 3
  06d2 const-string v11, "VP8L"
  06d6 invoke-virtual v4, v11, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  06dc move-result v11
  06de const-wide/16 v13, 16383
  06e2 if-eqz v11, +01fh
  06e6 const/4 v11, 5
  06e8 if-lt v5, v11, +01ch
  06ec invoke-static v0, v1, Lcom/personal/aihub/ImageAssets;->u([B I)I
  06f2 move-result v11
  06f4 const/16 v15, 47
  06f8 if-eq v11, v15, +003h
  06fc goto +12h
  06fe add-int/lit8 v2, v2, 9
  0702 invoke-static v0, v2, v12, Lcom/personal/aihub/ImageAssets;->le([B I I)J
  0708 move-result-wide v0
  070a and-long v4, v0, v13
  070e add-long/2addr v4, v8
  0710 ushr-long/2addr v0, v3
  0712 and-long/2addr v0, v13
  0714 add-long/2addr v0, v8
  0716 invoke-static v4, v5, v0, v1, v7, Lcom/personal/aihub/ImageAssets;->dimensions(J J Ljava/lang/String;)Lorg/json/JSONObject;
  071c move-result-object v0
  071e return-object v0
  0720 const-string v8, "VP8 "
  0724 invoke-virtual v4, v8, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  072a move-result v4
  072c if-eqz v4, +035h
  0730 if-lt v5, v10, +033h
  0734 add-int/lit8 v4, v2, 11
  0738 invoke-static v0, v4, Lcom/personal/aihub/ImageAssets;->u([B I)I
  073e move-result v4
  0740 const/16 v8, 157
  0744 if-ne v4, v8, +029h
  0748 add-int/lit8 v4, v2, 12
  074c invoke-static v0, v4, Lcom/personal/aihub/ImageAssets;->u([B I)I
  0752 move-result v4
  0754 const/4 v8, 1
  0756 if-ne v4, v8, +021h
  075a add-int/lit8 v4, v2, 13
  075e invoke-static v0, v4, Lcom/personal/aihub/ImageAssets;->u([B I)I
  0764 move-result v4
  0766 const/16 v9, 42
  076a if-ne v4, v9, +017h
  076e add-int/lit8 v1, v2, 14
  0772 const/4 v3, 2
  0774 invoke-static v0, v1, v3, Lcom/personal/aihub/ImageAssets;->le([B I I)J
  077a move-result-wide v4
  077c and-long/2addr v4, v13
  077e add-int/lit8 v2, v2, 16
  0782 invoke-static v0, v2, v3, Lcom/personal/aihub/ImageAssets;->le([B I I)J
  0788 move-result-wide v0
  078a and-long/2addr v0, v13
  078c invoke-static v4, v5, v0, v1, v7, Lcom/personal/aihub/ImageAssets;->dimensions(J J Ljava/lang/String;)Lorg/json/JSONObject;
  0792 move-result-object v0
  0794 return-object v0
  0796 const/4 v8, 1
  0798 and-int/lit8 v2, v5, 1
  079c add-int/2addr v2, v1
  079e add-int/2addr v2, v5
  07a0 goto/16 -0a5h
  07a4 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  07aa move-result-object v0
  07ac throw v0
  07ae invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  07b4 move-result-object v0
  07b6 throw v0
  07b8 const/4 v1, 0
  07ba const/4 v2, 2
  07bc invoke-static v0, v1, v2, Lcom/personal/aihub/ImageAssets;->text([B I I)Ljava/lang/String;
  07c2 move-result-object v1
  07c4 const-string v4, "BM"
  07c8 invoke-virtual v1, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  07ce move-result v1
  07d0 if-eqz v1, +048h
  07d4 array-length v1, v0
  07d6 const/16 v4, 26
  07da if-lt v1, v4, +043h
  07de invoke-static v0, v3, v12, Lcom/personal/aihub/ImageAssets;->le([B I I)J
  07e4 move-result-wide v3
  07e6 const-wide/16 v5, 12
  07ea cmp-long v1, v3, v5
  07ee const/16 v5, 18
  07f2 if-nez v1, +013h
  07f6 invoke-static v0, v5, v2, Lcom/personal/aihub/ImageAssets;->le([B I I)J
  07fc move-result-wide v3
  07fe const/16 v1, 20
  0802 invoke-static v0, v1, v2, Lcom/personal/aihub/ImageAssets;->le([B I I)J
  0808 move-result-wide v0
  080a const-string v2, "image/bmp"
  080e invoke-static v3, v4, v0, v1, v2, Lcom/personal/aihub/ImageAssets;->dimensions(J J Ljava/lang/String;)Lorg/json/JSONObject;
  0814 move-result-object v0
  0816 return-object v0
  0818 const-wide/16 v1, 40
  081c cmp-long v1, v3, v1
  0820 if-ltz v1, +020h
  0824 array-length v1, v0
  0826 const/16 v2, 54
  082a if-lt v1, v2, +01bh
  082e invoke-static v0, v5, v12, Lcom/personal/aihub/ImageAssets;->le([B I I)J
  0834 move-result-wide v1
  0836 long-to-int v1, v1
  0838 int-to-long v1, v1
  083a const/16 v3, 22
  083e invoke-static v0, v3, v12, Lcom/personal/aihub/ImageAssets;->le([B I I)J
  0844 move-result-wide v3
  0846 long-to-int v0, v3
  0848 invoke-static v0, Ljava/lang/Math;->abs(I)I
  084e move-result v0
  0850 int-to-long v3, v0
  0852 const-string v0, "image/bmp"
  0856 invoke-static v1, v2, v3, v4, v0, Lcom/personal/aihub/ImageAssets;->dimensions(J J Ljava/lang/String;)Lorg/json/JSONObject;
  085c move-result-object v0
  085e return-object v0
  0860 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  0866 move-result-object v0
  0868 throw v0
  086a new-instance v0, Ljava/io/IOException;
  086e const-string v1, "Artwork edits must be PNG images."
  0872 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0878 throw v0
  087a invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  0880 move-result-object v0
  0882 throw v0
  0884 fill-array-data-payload b'\x89PNG\r\n\x1a\n' | \x89\x50\x4e\x47\x0d\x0a\x1a\x0a
.end method

.method invalid()Ljava/io/IOException;
  0000 new-instance v0, Ljava/io/IOException;
  0004 const-string v1, "Choose a complete supported image (up to 12 MB,4096px per side)."
  0008 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  000e return-object v0
.end method

.method le([B I I)J
  0000 add-int/lit8 v6, v6, -1
  0004 const-wide/16 v0, 0
  0008 if-ltz v6, +010h
  000c const/16 v2, 8
  0010 shl-long/2addr v0, v2
  0012 add-int v2, v5, v6
  0016 invoke-static v4, v2, Lcom/personal/aihub/ImageAssets;->u([B I)I
  001c move-result v2
  001e int-to-long v2, v2
  0020 or-long/2addr v0, v2
  0022 add-int/lit8 v6, v6, -1
  0026 goto -fh
  0028 return-wide v0
.end method

.method rootValid()V
  0000 iget-object v0, v1, Lcom/personal/aihub/ImageAssets;->root Ljava/io/File;
  0004 invoke-virtual v0, Ljava/io/File;->isDirectory()Z
  000a move-result v0
  000c if-eqz v0, +00fh
  0010 iget-object v0, v1, Lcom/personal/aihub/ImageAssets;->root Ljava/io/File;
  0014 invoke-virtual v0, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  001a move-result-object v0
  001c invoke-static v0, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  0022 move-result v0
  0024 if-nez v0, +003h
  0028 return-void 
  002a invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  0030 move-result-object v0
  0032 throw v0
.end method

.method safe(Ljava/lang/String;)Z
  0000 const/4 v0, 0
  0002 if-eqz v8, +079h
  0006 invoke-virtual v8, Ljava/lang/String;->isEmpty()Z
  000c move-result v1
  000e if-nez v1, +073h
  0012 invoke-virtual v8, Ljava/lang/String;->length()I
  0018 move-result v1
  001a const/16 v2, 500
  001e if-gt v1, v2, +06bh
  0022 const-string v1, "(?i).*\.(png|jpe?g|webp|gif|bmp|lwf|json)$"
  0026 invoke-virtual v8, v1, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  002c move-result v1
  002e if-eqz v1, +063h
  0032 invoke-virtual v8, Ljava/lang/String;->toCharArray()[C
  0038 move-result-object v1
  003a array-length v2, v1
  003c move v3, v0
  003e if-ge v3, v2, +01dh
  0042 aget-char v4, v1, v3
  0046 const/16 v5, 92
  004a if-eq v4, v5, +016h
  004e const/16 v5, 58
  0052 if-eq v4, v5, +012h
  0056 const/16 v5, 37
  005a if-eq v4, v5, +00eh
  005e const/16 v5, 32
  0062 if-lt v4, v5, +00ah
  0066 const/16 v5, 127
  006a if-ne v4, v5, +003h
  006e goto +4h
  0070 add-int/lit8 v3, v3, 1
  0074 goto -1bh
  0076 return v0
  0078 const-string v1, "/"
  007c const/4 v2, -1
  007e invoke-virtual v8, v1, v2, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  0084 move-result-object v8
  0086 array-length v1, v8
  0088 move v2, v0
  008a if-ge v2, v1, +033h
  008e aget-object v3, v8, v2
  0092 invoke-virtual v3, Ljava/lang/String;->isEmpty()Z
  0098 move-result v4
  009a if-nez v4, +02ah
  009e const-string v4, "."
  00a2 invoke-virtual v3, v4, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00a8 move-result v4
  00aa if-nez v4, +022h
  00ae const-string v4, "patches"
  00b2 const-string v5, "exports"
  00b6 const-string v6, "_databases"
  00ba const-string v7, "projects"
  00be filled-new-array v6, v7, v4, v5, [Ljava/lang/String;
  00c4 move-result-object v4
  00c6 invoke-static v4, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  00cc move-result-object v4
  00ce sget-object v5, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  00d2 invoke-virtual v3, v5, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  00d8 move-result-object v3
  00da invoke-interface v4, v3, Ljava/util/List;->contains(Ljava/lang/Object;)Z
  00e0 move-result v3
  00e2 if-eqz v3, +003h
  00e6 goto +4h
  00e8 add-int/lit8 v2, v2, 1
  00ec goto -31h
  00ee return v0
  00f0 const/4 v8, 1
  00f2 return v8
  00f4 return v0
.end method

.method text([B I I)Ljava/lang/String;
  0000 new-instance v0, Ljava/lang/String;
  0004 sget-object v1, Ljava/nio/charset/StandardCharsets;->US_ASCII Ljava/nio/charset/Charset;
  0008 invoke-direct v0, v2, v3, v4, v1, Ljava/lang/String;-><init>([B I I Ljava/nio/charset/Charset;)V
  000e return-object v0
.end method

.method u([B I)I
  0000 aget-byte v0, v0, v1
  0004 and-int/lit16 v0, v0, 255
  0008 return v0
.end method

.method read(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 const-string v0, "maxBytes"
  0004 invoke-virtual v11, v0, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  000a move-result-object v0
  000c const/high16 v1, 12582912
  0010 if-nez v0, +004h
  0014 move v0, v1
  0016 goto +18h
  0018 instance-of v2, v0, Ljava/lang/Number;
  001c if-eqz v2, +0f2h
  0020 check-cast v0, Ljava/lang/Number;
  0024 invoke-virtual v0, Ljava/lang/Number;->doubleValue()D
  002a move-result-wide v2
  002c invoke-virtual v0, Ljava/lang/Number;->intValue()I
  0032 move-result v4
  0034 int-to-double v4, v4
  0036 cmpl-double v2, v2, v4
  003a if-nez v2, +0deh
  003e invoke-virtual v0, Ljava/lang/Number;->intValue()I
  0044 move-result v0
  0046 const/4 v2, 1
  0048 if-lt v0, v2, +0d2h
  004c if-gt v0, v1, +0d0h
  0050 const-string v3, "key"
  0054 invoke-virtual v11, v3, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  005a move-result-object v11
  005c invoke-direct v10, v11, Lcom/personal/aihub/ImageAssets;->file(Ljava/lang/String;)Ljava/io/File;
  0062 move-result-object v4
  0064 invoke-virtual v4, Ljava/io/File;->length()J
  006a move-result-wide v5
  006c int-to-long v7, v0
  006e cmp-long v5, v5, v7
  0072 if-gtz v5, +0b8h
  0076 new-instance v5, Ljava/io/ByteArrayOutputStream;
  007a invoke-direct v5, Ljava/io/ByteArrayOutputStream;-><init>()V
  0080 new-instance v6, Ljava/io/FileInputStream;
  0084 invoke-direct v6, v4, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  008a const/high16 v4, 65536
  008e new-array v4, v4, [B
  0092 invoke-virtual v6, v4, Ljava/io/FileInputStream;->read([B)I
  0098 move-result v7
  009a const/4 v8, -1
  009c const/4 v9, 0
  009e if-eq v7, v8, +013h
  00a2 invoke-virtual v5, Ljava/io/ByteArrayOutputStream;->size()I
  00a8 move-result v8
  00aa sub-int v8, v0, v8
  00ae if-gt v7, v8, +006h
  00b2 invoke-virtual v5, v4, v9, v7, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  00b8 goto -13h
  00ba invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  00c0 move-result-object v11
  00c2 throw v11
  00c4 invoke-virtual v6, Ljava/io/FileInputStream;->close()V
  00ca invoke-virtual v5, Ljava/io/ByteArrayOutputStream;->toByteArray()[B
  00d0 move-result-object v0
  00d2 sget-object v4, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  00d6 invoke-virtual v11, v4, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  00dc move-result-object v4
  00de const-string v5, ".json"
  00e2 invoke-virtual v4, v5, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  00e8 move-result v4
  00ea if-eqz v4, +007h
  00ee invoke-static v0, Lcom/personal/aihub/DecorationStorage;->inspect([B)Lorg/json/JSONObject;
  00f4 move-result-object v1
  00f6 goto +4dh
  00f8 sget-object v4, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  00fc invoke-virtual v11, v4, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  0102 move-result-object v4
  0104 const-string v5, ".lwf"
  0108 invoke-virtual v4, v5, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  010e move-result v4
  0110 if-nez v4, +007h
  0114 invoke-static v0, v9, Lcom/personal/aihub/ImageAssets;->inspect([B Z)Lorg/json/JSONObject;
  011a move-result-object v1
  011c goto +3ah
  011e array-length v4, v0
  0120 const/16 v5, 16
  0124 if-lt v4, v5, +050h
  0128 array-length v4, v0
  012a if-gt v4, v1, +04dh
  012e aget-byte v1, v0, v9
  0132 const/16 v4, 76
  0136 if-ne v1, v4, +047h
  013a aget-byte v1, v0, v2
  013e const/16 v2, 87
  0142 if-ne v1, v2, +041h
  0146 const/4 v1, 2
  0148 aget-byte v1, v0, v1
  014c const/16 v2, 70
  0150 if-ne v1, v2, +03ah
  0154 const/4 v1, 3
  0156 aget-byte v1, v0, v1
  015a if-nez v1, +035h
  015e new-instance v1, Lorg/json/JSONObject;
  0162 invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  0168 const-string v2, "width"
  016c invoke-virtual v1, v2, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0172 move-result-object v1
  0174 const-string v2, "height"
  0178 invoke-virtual v1, v2, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  017e move-result-object v1
  0180 const-string v2, "mime"
  0184 const-string v4, "application/octet-stream"
  0188 invoke-virtual v1, v2, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  018e move-result-object v1
  0190 invoke-virtual v1, v3, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0196 move-result-object v11
  0198 invoke-static Ljava/util/Base64;->getEncoder()Ljava/util/Base64$Encoder;
  019e move-result-object v1
  01a0 invoke-virtual v1, v0, Ljava/util/Base64$Encoder;->encodeToString([B)Ljava/lang/String;
  01a6 move-result-object v1
  01a8 const-string v2, "base64"
  01ac invoke-virtual v11, v2, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01b2 move-result-object v11
  01b4 const-string v1, "bytes"
  01b8 array-length v0, v0
  01ba invoke-virtual v11, v1, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  01c0 move-result-object v11
  01c2 return-object v11
  01c4 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  01ca move-result-object v11
  01cc throw v11
  01ce move-exception v11
  01d0 invoke-virtual v6, Ljava/io/FileInputStream;->close()V
  01d6 goto +5h
  01d8 move-exception v0
  01da invoke-virtual v11, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  01e0 throw v11
  01e2 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  01e8 move-result-object v11
  01ea throw v11
  01ec invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  01f2 move-result-object v11
  01f4 throw v11
  01f6 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  01fc move-result-object v11
  01fe throw v11
  0200 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  0206 move-result-object v11
  0208 throw v11
.end method

.method store(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 const-string v0, "name"
  0004 const-string v1, "image.png"
  0008 const-string v2, "data"
  000c invoke-virtual v12, v2, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  0012 move-result-object v2
  0014 instance-of v3, v2, Ljava/lang/String;
  0018 if-eqz v3, +0efh
  001c check-cast v2, Ljava/lang/String;
  0020 invoke-virtual v2, Ljava/lang/String;->length()I
  0026 move-result v3
  0028 const/high16 v4, 16777216
  002c if-gt v3, v4, +0e0h
  0030 invoke-virtual v2, Ljava/lang/String;->length()I
  0036 move-result v3
  0038 rem-int/lit8 v3, v3, 4
  003c if-nez v3, +0d8h
  0040 const-string v3, "[A-Za-z0-9+/]*={0,2}"
  0044 invoke-virtual v2, v3, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  004a move-result v3
  004c if-eqz v3, +0d0h
  0050 invoke-static Ljava/util/Base64;->getDecoder()Ljava/util/Base64$Decoder;
  0056 move-result-object v3
  0058 invoke-virtual v3, v2, Ljava/util/Base64$Decoder;->decode(Ljava/lang/String;)[B
  005e move-result-object v3
  0060 invoke-static Ljava/util/Base64;->getEncoder()Ljava/util/Base64$Encoder;
  0066 move-result-object v4
  0068 invoke-virtual v4, v3, Ljava/util/Base64$Encoder;->encodeToString([B)Ljava/lang/String;
  006e move-result-object v4
  0070 invoke-virtual v4, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0076 move-result v2
  0078 if-eqz v2, +0b5h
  007c const/4 v2, 1
  007e invoke-static v3, v2, Lcom/personal/aihub/ImageAssets;->inspect([B Z)Lorg/json/JSONObject;
  0084 move-result-object v4
  0086 invoke-direct v11, Lcom/personal/aihub/ImageAssets;->rootValid()V
  008c new-instance v5, Ljava/lang/StringBuilder;
  0090 const-string v6, "generated-"
  0094 invoke-direct v5, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  009a invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  00a0 move-result-object v6
  00a2 invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  00a8 invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00ae move-result-object v5
  00b0 new-instance v6, Ljava/lang/StringBuilder;
  00b4 invoke-direct v6, Ljava/lang/StringBuilder;-><init>()V
  00ba invoke-static v5, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  00c0 move-result-object v7
  00c2 invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00c8 const-string v7, "/image.png"
  00cc invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00d2 invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00d8 move-result-object v6
  00da new-instance v7, Ljava/io/File;
  00de iget-object v8, v11, Lcom/personal/aihub/ImageAssets;->root Ljava/io/File;
  00e2 invoke-direct v7, v8, v5, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00e8 invoke-virtual v7, Ljava/io/File;->mkdir()Z
  00ee move-result v5
  00f0 if-eqz v5, +074h
  00f4 new-instance v5, Ljava/io/File;
  00f8 invoke-direct v5, v7, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00fe invoke-virtual v5, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0104 move-result-object v5
  0106 const/4 v8, 2
  0108 new-array v8, v8, [Ljava/nio/file/OpenOption;
  010c sget-object v9, Ljava/nio/file/StandardOpenOption;->CREATE_NEW Ljava/nio/file/StandardOpenOption;
  0110 const/4 v10, 0
  0112 aput-object v9, v8, v10
  0116 sget-object v9, Ljava/nio/file/StandardOpenOption;->WRITE Ljava/nio/file/StandardOpenOption;
  011a aput-object v9, v8, v2
  011e invoke-static v5, v8, Ljava/nio/file/Files;->newOutputStream(Ljava/nio/file/Path; [Ljava/nio/file/OpenOption;)Ljava/io/OutputStream;
  0124 move-result-object v5
  0126 invoke-virtual v5, v3, Ljava/io/OutputStream;->write([B)V
  012c if-eqz v5, +005h
  0130 invoke-virtual v5, Ljava/io/OutputStream;->close()V
  0136 const-string v5, "Custom artwork"
  013a invoke-virtual v12, v0, v5, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0140 move-result-object v12
  0142 const-string v5, "[\x00-\x1f\x7f]"
  0146 const-string v8, ""
  014a invoke-virtual v12, v5, v8, Ljava/lang/String;->replaceAll(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0150 move-result-object v12
  0152 invoke-virtual v12, Ljava/lang/String;->length()I
  0158 move-result v5
  015a const/16 v8, 160
  015e if-le v5, v8, +006h
  0162 invoke-virtual v12, v10, v8, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  0168 move-result-object v12
  016a const-string v5, "key"
  016e invoke-virtual v4, v5, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0174 move-result-object v4
  0176 const-string v5, "path"
  017a invoke-virtual v4, v5, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0180 move-result-object v4
  0182 invoke-virtual v4, v0, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0188 move-result-object v12
  018a const-string v0, "size"
  018e array-length v3, v3
  0190 invoke-virtual v12, v0, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0196 move-result-object v12
  0198 const-string v0, "image"
  019c invoke-virtual v12, v0, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  01a2 move-result-object v12
  01a4 return-object v12
  01a6 move-exception v12
  01a8 if-eqz v5, +00ah
  01ac invoke-virtual v5, Ljava/io/OutputStream;->close()V
  01b2 goto +5h
  01b4 move-exception v0
  01b6 invoke-virtual v12, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  01bc throw v12
  01be move-exception v12
  01c0 new-instance v0, Ljava/io/File;
  01c4 invoke-direct v0, v7, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  01ca invoke-virtual v0, Ljava/io/File;->delete()Z
  01d0 invoke-virtual v7, Ljava/io/File;->delete()Z
  01d6 throw v12
  01d8 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  01de move-result-object v12
  01e0 throw v12
  01e2 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  01e8 move-result-object v12
  01ea throw v12
  01ec invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  01f2 move-result-object v12
  01f4 throw v12
  01f6 invoke-static Lcom/personal/aihub/ImageAssets;->invalid()Ljava/io/IOException;
  01fc move-result-object v12
  01fe throw v12
.end method