.class Lcom/personal/aihub/LwfStorage;
.super Ljava/lang/Object;
.field LIMIT I

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method inspect([B)Lorg/json/JSONObject;
  0000 move-object/from16 v0, v18
  0004 array-length v1, v0
  0006 const/16 v2, 324
  000a if-lt v1, v2, +107h
  000e array-length v1, v0
  0010 const/high16 v3, 12582912
  0014 if-gt v1, v3, +102h
  0018 const/4 v1, 0
  001a aget-byte v1, v0, v1
  001e const/16 v3, 76
  0022 if-ne v1, v3, +0fbh
  0026 const/4 v1, 1
  0028 aget-byte v1, v0, v1
  002c const/16 v3, 87
  0030 if-ne v1, v3, +0f4h
  0034 const/4 v1, 2
  0036 aget-byte v1, v0, v1
  003a const/16 v3, 70
  003e if-ne v1, v3, +0edh
  0042 const/4 v1, 3
  0044 aget-byte v1, v0, v1
  0048 if-nez v1, +0e8h
  004c const/4 v1, 4
  004e aget-byte v3, v0, v1
  0052 and-int/lit16 v3, v3, 255
  0056 const/16 v4, 16
  005a shl-int/2addr v3, v4
  005c const/4 v5, 5
  005e aget-byte v5, v0, v5
  0062 and-int/lit16 v5, v5, 255
  0066 const/16 v6, 8
  006a shl-int/2addr v5, v6
  006c or-int/2addr v3, v5
  006e const/4 v5, 6
  0070 aget-byte v5, v0, v5
  0074 and-int/lit16 v5, v5, 255
  0078 or-int/2addr v3, v5
  007a const v5, 1315345
  0080 if-ne v3, v5, +004h
  0084 const/16 v2, 332
  0088 const v7, 1183760
  008e if-eq v3, v7, +009h
  0092 const v7, 1249809
  0098 if-eq v3, v7, +004h
  009c if-ne v3, v5, +0b9h
  00a0 array-length v3, v0
  00a2 if-lt v3, v2, +0b6h
  00a6 const/4 v3, 7
  00a8 aget-byte v3, v0, v3
  00ac and-int/2addr v1, v3
  00ae if-nez v1, +0b0h
  00b2 add-int/lit8 v1, v2, -4
  00b6 invoke-static v0, v1, Lcom/personal/aihub/LwfStorage;->word([B I)J
  00bc move-result-wide v7
  00be array-length v3, v0
  00c0 int-to-long v9, v3
  00c2 cmp-long v3, v7, v9
  00c6 if-nez v3, +0a4h
  00ca invoke-static v0, v6, Lcom/personal/aihub/LwfStorage;->word([B I)J
  00d0 move-result-wide v7
  00d2 const/16 v3, 12
  00d6 invoke-static v0, v3, Lcom/personal/aihub/LwfStorage;->word([B I)J
  00dc move-result-wide v9
  00de invoke-static v0, v4, Lcom/personal/aihub/LwfStorage;->word([B I)J
  00e4 move-result-wide v3
  00e6 int-to-long v11, v2
  00e8 const-wide/16 v13, 1
  00ec cmp-long v5, v7, v13
  00f0 if-ltz v5, +08ah
  00f4 cmp-long v5, v9, v13
  00f8 if-ltz v5, +086h
  00fc const-wide/16 v15, 16384
  0100 cmp-long v5, v7, v15
  0104 if-gtz v5, +080h
  0108 cmp-long v5, v9, v15
  010c if-gtz v5, +07ch
  0110 cmp-long v5, v3, v13
  0114 if-ltz v5, +078h
  0118 const-wide/16 v13, 240
  011c cmp-long v3, v3, v13
  0120 if-gtz v3, +072h
  0124 const/16 v3, 32
  0128 if-ge v3, v1, +030h
  012c invoke-static v0, v3, Lcom/personal/aihub/LwfStorage;->word([B I)J
  0132 move-result-wide v4
  0134 add-int/lit8 v13, v3, 4
  0138 invoke-static v0, v13, Lcom/personal/aihub/LwfStorage;->word([B I)J
  013e move-result-wide v13
  0140 const-wide/16 v15, 0
  0144 cmp-long v17, v4, v15
  0148 if-nez v17, +006h
  014c cmp-long v15, v13, v15
  0150 if-eqz v15, +014h
  0154 cmp-long v11, v4, v11
  0158 if-ltz v11, +013h
  015c array-length v11, v0
  015e int-to-long v11, v11
  0160 cmp-long v11, v4, v11
  0164 if-gtz v11, +00dh
  0168 array-length v11, v0
  016a int-to-long v11, v11
  016c sub-long/2addr v11, v4
  016e cmp-long v11, v13, v11
  0172 if-gtz v11, +006h
  0176 move-wide v11, v4
  0178 add-int/lit8 v3, v3, 8
  017c goto -2ah
  017e invoke-static Lcom/personal/aihub/LwfStorage;->invalid()Ljava/io/IOException;
  0184 move-result-object v0
  0186 throw v0
  0188 const/16 v1, 20
  018c invoke-static v0, v1, Lcom/personal/aihub/LwfStorage;->word([B I)J
  0192 move-result-wide v3
  0194 add-int/lit8 v1, v2, -24
  0198 invoke-static v0, v1, Lcom/personal/aihub/LwfStorage;->word([B I)J
  019e move-result-wide v11
  01a0 cmp-long v1, v3, v11
  01a4 if-gez v1, +02bh
  01a8 const/16 v1, 24
  01ac invoke-static v0, v1, Lcom/personal/aihub/LwfStorage;->word([B I)J
  01b2 move-result-wide v3
  01b4 sub-int/2addr v2, v6
  01b6 invoke-static v0, v2, Lcom/personal/aihub/LwfStorage;->word([B I)J
  01bc move-result-wide v0
  01be cmp-long v0, v3, v0
  01c2 if-gez v0, +01ch
  01c6 new-instance v0, Lorg/json/JSONObject;
  01ca invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  01d0 const-string v1, "mime"
  01d4 const-string v2, "application/octet-stream"
  01d8 invoke-virtual v0, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01de move-result-object v0
  01e0 const-string v1, "width"
  01e4 invoke-virtual v0, v1, v7, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  01ea move-result-object v0
  01ec const-string v1, "height"
  01f0 invoke-virtual v0, v1, v9, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  01f6 move-result-object v0
  01f8 return-object v0
  01fa invoke-static Lcom/personal/aihub/LwfStorage;->invalid()Ljava/io/IOException;
  0200 move-result-object v0
  0202 throw v0
  0204 invoke-static Lcom/personal/aihub/LwfStorage;->invalid()Ljava/io/IOException;
  020a move-result-object v0
  020c throw v0
  020e invoke-static Lcom/personal/aihub/LwfStorage;->invalid()Ljava/io/IOException;
  0214 move-result-object v0
  0216 throw v0
  0218 invoke-static Lcom/personal/aihub/LwfStorage;->invalid()Ljava/io/IOException;
  021e move-result-object v0
  0220 throw v0
.end method

.method invalid()Ljava/io/IOException;
  0000 new-instance v0, Ljava/io/IOException;
  0004 const-string v1, "Choose a complete, uncompressed supported LWF animation up to 12 MB."
  0008 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  000e return-object v0
.end method

.method store(Ljava/io/File; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 const-string v0, "name"
  0004 const-string v1, "animation.lwf"
  0008 const-string v2, "generated-lwf-"
  000c const-string v3, "data"
  0010 invoke-virtual v12, v3, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  0016 move-result-object v3
  0018 instance-of v4, v3, Ljava/lang/String;
  001c if-eqz v4, +0fah
  0020 check-cast v3, Ljava/lang/String;
  0024 invoke-virtual v3, Ljava/lang/String;->length()I
  002a move-result v4
  002c const/high16 v5, 16777216
  0030 if-gt v4, v5, +0ebh
  0034 invoke-virtual v3, Ljava/lang/String;->length()I
  003a move-result v4
  003c rem-int/lit8 v4, v4, 4
  0040 if-nez v4, +0e3h
  0044 const-string v4, "[A-Za-z0-9+/]*={0,2}"
  0048 invoke-virtual v3, v4, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  004e move-result v4
  0050 if-eqz v4, +0dbh
  0054 invoke-static Ljava/util/Base64;->getDecoder()Ljava/util/Base64$Decoder;
  005a move-result-object v4
  005c invoke-virtual v4, v3, Ljava/util/Base64$Decoder;->decode(Ljava/lang/String;)[B
  0062 move-result-object v4
  0064 invoke-static Ljava/util/Base64;->getEncoder()Ljava/util/Base64$Encoder;
  006a move-result-object v5
  006c invoke-virtual v5, v4, Ljava/util/Base64$Encoder;->encodeToString([B)Ljava/lang/String;
  0072 move-result-object v5
  0074 invoke-virtual v5, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  007a move-result v3
  007c if-eqz v3, +0bbh
  0080 invoke-static v4, Lcom/personal/aihub/LwfStorage;->inspect([B)Lorg/json/JSONObject;
  0086 move-result-object v3
  0088 invoke-virtual v11, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  008e move-result-object v5
  0090 invoke-static v5, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  0096 move-result v5
  0098 if-nez v5, +0a8h
  009c invoke-virtual v11, Ljava/io/File;->isDirectory()Z
  00a2 move-result v5
  00a4 if-eqz v5, +0a2h
  00a8 new-instance v5, Ljava/lang/StringBuilder;
  00ac invoke-direct v5, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00b2 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  00b8 move-result-object v2
  00ba invoke-virtual v5, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  00c0 invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00c6 move-result-object v2
  00c8 new-instance v5, Ljava/lang/StringBuilder;
  00cc invoke-direct v5, Ljava/lang/StringBuilder;-><init>()V
  00d2 invoke-static v2, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  00d8 move-result-object v6
  00da invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00e0 const-string v6, "/animation.lwf"
  00e4 invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00ea invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00f0 move-result-object v5
  00f2 new-instance v6, Ljava/io/File;
  00f6 invoke-direct v6, v11, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00fc invoke-virtual v6, Ljava/io/File;->mkdir()Z
  0102 move-result v11
  0104 if-eqz v11, +06dh
  0108 new-instance v11, Ljava/io/File;
  010c invoke-direct v11, v6, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0112 invoke-virtual v11, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0118 move-result-object v2
  011a const/4 v7, 2
  011c new-array v7, v7, [Ljava/nio/file/OpenOption;
  0120 sget-object v8, Ljava/nio/file/StandardOpenOption;->CREATE_NEW Ljava/nio/file/StandardOpenOption;
  0124 const/4 v9, 0
  0126 aput-object v8, v7, v9
  012a sget-object v8, Ljava/nio/file/StandardOpenOption;->WRITE Ljava/nio/file/StandardOpenOption;
  012e const/4 v10, 1
  0130 aput-object v8, v7, v10
  0134 invoke-static v2, v7, Ljava/nio/file/Files;->newOutputStream(Ljava/nio/file/Path; [Ljava/nio/file/OpenOption;)Ljava/io/OutputStream;
  013a move-result-object v2
  013c invoke-virtual v2, v4, Ljava/io/OutputStream;->write([B)V
  0142 if-eqz v2, +005h
  0146 invoke-virtual v2, Ljava/io/OutputStream;->close()V
  014c const-string v7, "Custom character animation"
  0150 invoke-virtual v12, v0, v7, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0156 move-result-object v12
  0158 const-string v7, "[\x00-\x1f\x7f]"
  015c const-string v8, ""
  0160 invoke-virtual v12, v7, v8, Ljava/lang/String;->replaceAll(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0166 move-result-object v12
  0168 invoke-virtual v12, Ljava/lang/String;->length()I
  016e move-result v7
  0170 const/16 v8, 160
  0174 if-le v7, v8, +006h
  0178 invoke-virtual v12, v9, v8, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  017e move-result-object v12
  0180 const-string v7, "key"
  0184 invoke-virtual v3, v7, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  018a move-result-object v3
  018c const-string v5, "path"
  0190 invoke-virtual v3, v5, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0196 move-result-object v1
  0198 invoke-virtual v1, v0, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  019e move-result-object v12
  01a0 const-string v0, "size"
  01a4 array-length v1, v4
  01a6 invoke-virtual v12, v0, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  01ac move-result-object v12
  01ae const-string v0, "image"
  01b2 invoke-virtual v12, v0, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  01b8 move-result-object v11
  01ba return-object v11
  01bc move-exception v12
  01be if-eqz v2, +005h
  01c2 invoke-virtual v2, Ljava/io/OutputStream;->close()V
  01c8 throw v12
  01ca move-exception v12
  01cc throw v12
  01ce move-exception v12
  01d0 invoke-virtual v11, Ljava/io/File;->delete()Z
  01d6 invoke-virtual v6, Ljava/io/File;->delete()Z
  01dc throw v12
  01de invoke-static Lcom/personal/aihub/LwfStorage;->invalid()Ljava/io/IOException;
  01e4 move-result-object v11
  01e6 throw v11
  01e8 invoke-static Lcom/personal/aihub/LwfStorage;->invalid()Ljava/io/IOException;
  01ee move-result-object v11
  01f0 throw v11
  01f2 invoke-static Lcom/personal/aihub/LwfStorage;->invalid()Ljava/io/IOException;
  01f8 move-result-object v11
  01fa throw v11
  01fc invoke-static Lcom/personal/aihub/LwfStorage;->invalid()Ljava/io/IOException;
  0202 move-result-object v11
  0204 throw v11
  0206 invoke-static Lcom/personal/aihub/LwfStorage;->invalid()Ljava/io/IOException;
  020c move-result-object v11
  020e throw v11
  0210 invoke-static Lcom/personal/aihub/LwfStorage;->invalid()Ljava/io/IOException;
  0216 move-result-object v11
  0218 throw v11
.end method

.method word([B I)J
  0000 add-int/lit8 v0, v8, 3
  0004 aget-byte v0, v7, v0
  0008 int-to-long v0, v0
  000a const-wide/16 v2, 255
  000e and-long/2addr v0, v2
  0010 const/16 v4, 24
  0014 shl-long/2addr v0, v4
  0016 aget-byte v4, v7, v8
  001a int-to-long v4, v4
  001c and-long/2addr v4, v2
  001e or-long/2addr v0, v4
  0020 add-int/lit8 v4, v8, 1
  0024 aget-byte v4, v7, v4
  0028 int-to-long v4, v4
  002a and-long/2addr v4, v2
  002c const/16 v6, 8
  0030 shl-long/2addr v4, v6
  0032 or-long/2addr v0, v4
  0034 add-int/lit8 v8, v8, 2
  0038 aget-byte v7, v7, v8
  003c int-to-long v7, v7
  003e and-long/2addr v7, v2
  0040 const/16 v2, 16
  0044 shl-long/2addr v7, v2
  0046 or-long/2addr v7, v0
  0048 return-wide v7
.end method