.class Lcom/personal/aihub/DecorationStorage;
.super Ljava/lang/Object;
.field LIMIT I

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method inspect([B)Lorg/json/JSONObject;
  0000 array-length v0, v9
  0002 if-eqz v0, +164h
  0006 array-length v0, v9
  0008 const/high16 v1, 131072
  000c if-gt v0, v1, +15fh
  0010 sget-object v0, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0014 invoke-virtual v0, Ljava/nio/charset/Charset;->newDecoder()Ljava/nio/charset/CharsetDecoder;
  001a move-result-object v0
  001c sget-object v1, Ljava/nio/charset/CodingErrorAction;->REPORT Ljava/nio/charset/CodingErrorAction;
  0020 invoke-virtual v0, v1, Ljava/nio/charset/CharsetDecoder;->onMalformedInput(Ljava/nio/charset/CodingErrorAction;)Ljava/nio/charset/CharsetDecoder;
  0026 move-result-object v0
  0028 sget-object v1, Ljava/nio/charset/CodingErrorAction;->REPORT Ljava/nio/charset/CodingErrorAction;
  002c invoke-virtual v0, v1, Ljava/nio/charset/CharsetDecoder;->onUnmappableCharacter(Ljava/nio/charset/CodingErrorAction;)Ljava/nio/charset/CharsetDecoder;
  0032 move-result-object v0
  0034 invoke-static v9, Ljava/nio/ByteBuffer;->wrap([B)Ljava/nio/ByteBuffer;
  003a move-result-object v9
  003c invoke-virtual v0, v9, Ljava/nio/charset/CharsetDecoder;->decode(Ljava/nio/ByteBuffer;)Ljava/nio/CharBuffer;
  0042 move-result-object v9
  0044 invoke-virtual v9, Ljava/nio/CharBuffer;->toString()Ljava/lang/String;
  004a move-result-object v9
  004c invoke-virtual v9, Ljava/lang/String;->trim()Ljava/lang/String;
  0052 move-result-object v9
  0054 const/4 v0, 0
  0056 move v1, v0
  0058 move v2, v1
  005a move v3, v2
  005c move v4, v3
  005e invoke-virtual v9, Ljava/lang/String;->length()I
  0064 move-result v5
  0066 if-ge v1, v5, +046h
  006a invoke-virtual v9, v1, Ljava/lang/String;->charAt(I)C
  0070 move-result v5
  0072 const/16 v6, 34
  0076 const/4 v7, 1
  0078 if-eqz v2, +010h
  007c if-eqz v4, +004h
  0080 move v4, v0
  0082 goto +30h
  0084 const/16 v8, 92
  0088 if-ne v5, v8, +004h
  008c move v4, v7
  008e goto +2ah
  0090 if-ne v5, v6, +029h
  0094 move v2, v0
  0096 goto +26h
  0098 if-ne v5, v6, +004h
  009c move v2, v7
  009e goto +22h
  00a0 const/16 v6, 123
  00a4 if-eq v5, v6, +019h
  00a8 const/16 v6, 91
  00ac if-ne v5, v6, +003h
  00b0 goto +13h
  00b2 const/16 v6, 125
  00b6 if-eq v5, v6, +006h
  00ba const/16 v6, 93
  00be if-ne v5, v6, +012h
  00c2 add-int/lit8 v3, v3, -1
  00c6 if-ltz v3, +003h
  00ca goto +ch
  00cc invoke-static Lcom/personal/aihub/DecorationStorage;->invalid()Ljava/io/IOException;
  00d2 move-result-object v9
  00d4 throw v9
  00d6 add-int/lit8 v3, v3, 1
  00da const/16 v5, 32
  00de if-gt v3, v5, +005h
  00e2 add-int/lit8 v1, v1, 1
  00e6 goto -44h
  00e8 invoke-static Lcom/personal/aihub/DecorationStorage;->invalid()Ljava/io/IOException;
  00ee move-result-object v9
  00f0 throw v9
  00f2 if-nez v2, +0e7h
  00f6 if-nez v3, +0e5h
  00fa const-string v1, "{"
  00fe invoke-virtual v9, v1, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0104 move-result v1
  0106 if-eqz v1, +0ddh
  010a const-string v1, "}"
  010e invoke-virtual v9, v1, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  0114 move-result v1
  0116 if-eqz v1, +0d5h
  011a new-instance v1, Lorg/json/JSONTokener;
  011e invoke-direct v1, v9, Lorg/json/JSONTokener;-><init>(Ljava/lang/String;)V
  0124 invoke-virtual v1, Lorg/json/JSONTokener;->nextValue()Ljava/lang/Object;
  012a move-result-object v9
  012c instance-of v2, v9, Lorg/json/JSONObject;
  0130 if-eqz v2, +0c3h
  0134 invoke-virtual v1, Lorg/json/JSONTokener;->nextClean()C
  013a move-result v1
  013c if-nez v1, +0bdh
  0140 check-cast v9, Lorg/json/JSONObject;
  0144 const-string v1, "card_id"
  0148 invoke-virtual v9, v1, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  014e move-result-object v1
  0150 instance-of v2, v1, Ljava/lang/Number;
  0154 if-eqz v2, +0ach
  0158 check-cast v1, Ljava/lang/Number;
  015c invoke-virtual v1, Ljava/lang/Number;->doubleValue()D
  0162 move-result-wide v2
  0164 invoke-virtual v1, Ljava/lang/Number;->longValue()J
  016a move-result-wide v4
  016c long-to-double v4, v4
  016e cmpl-double v2, v2, v4
  0172 if-nez v2, +09dh
  0176 invoke-virtual v1, Ljava/lang/Number;->longValue()J
  017c move-result-wide v2
  017e const-wide/16 v4, 1
  0182 cmp-long v2, v2, v4
  0186 if-ltz v2, +093h
  018a invoke-virtual v1, Ljava/lang/Number;->longValue()J
  0190 move-result-wide v1
  0192 const-wide/32 v3, 2147483647
  0198 cmp-long v1, v1, v3
  019c if-gtz v1, +088h
  01a0 const-string v1, "shader_file"
  01a4 invoke-virtual v9, v1, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  01aa move-result-object v1
  01ac invoke-static v1, Lcom/personal/aihub/DecorationStorage;->safe(Ljava/lang/String;)Z
  01b2 move-result v1
  01b4 if-eqz v1, +07ch
  01b8 const-string v1, "parameters"
  01bc invoke-virtual v9, v1, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  01c2 move-result-object v9
  01c4 invoke-virtual v9, Lorg/json/JSONArray;->length()I
  01ca move-result v1
  01cc const/16 v2, 128
  01d0 if-gt v1, v2, +069h
  01d4 move v1, v0
  01d6 invoke-virtual v9, Lorg/json/JSONArray;->length()I
  01dc move-result v2
  01de if-ge v1, v2, +048h
  01e2 invoke-virtual v9, v1, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  01e8 move-result-object v2
  01ea const-string v3, "type"
  01ee invoke-virtual v2, v3, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  01f4 move-result-object v4
  01f6 instance-of v4, v4, Ljava/lang/String;
  01fa if-eqz v4, +035h
  01fe const-string v4, "name"
  0202 invoke-virtual v2, v4, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  0208 move-result-object v4
  020a instance-of v4, v4, Ljava/lang/String;
  020e if-eqz v4, +02bh
  0212 const-string v4, "sampler2D"
  0216 invoke-virtual v2, v3, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  021c move-result-object v3
  021e invoke-virtual v4, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0224 move-result v3
  0226 if-eqz v3, +01ch
  022a const-string v3, "value"
  022e invoke-virtual v2, v3, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  0234 move-result-object v4
  0236 instance-of v4, v4, Ljava/lang/String;
  023a if-eqz v4, +00dh
  023e invoke-virtual v2, v3, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0244 move-result-object v2
  0246 invoke-static v2, Lcom/personal/aihub/DecorationStorage;->safe(Ljava/lang/String;)Z
  024c move-result v2
  024e if-eqz v2, +003h
  0252 goto +6h
  0254 invoke-static Lcom/personal/aihub/DecorationStorage;->invalid()Ljava/io/IOException;
  025a move-result-object v9
  025c throw v9
  025e add-int/lit8 v1, v1, 1
  0262 goto -46h
  0264 invoke-static Lcom/personal/aihub/DecorationStorage;->invalid()Ljava/io/IOException;
  026a move-result-object v9
  026c throw v9
  026e new-instance v9, Lorg/json/JSONObject;
  0272 invoke-direct v9, Lorg/json/JSONObject;-><init>()V
  0278 const-string v1, "width"
  027c invoke-virtual v9, v1, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0282 move-result-object v9
  0284 const-string v1, "height"
  0288 invoke-virtual v9, v1, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  028e move-result-object v9
  0290 const-string v0, "mime"
  0294 const-string v1, "application/json"
  0298 invoke-virtual v9, v0, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  029e move-result-object v9
  02a0 return-object v9
  02a2 invoke-static Lcom/personal/aihub/DecorationStorage;->invalid()Ljava/io/IOException;
  02a8 move-result-object v9
  02aa throw v9
  02ac invoke-static Lcom/personal/aihub/DecorationStorage;->invalid()Ljava/io/IOException;
  02b2 move-result-object v9
  02b4 throw v9
  02b6 invoke-static Lcom/personal/aihub/DecorationStorage;->invalid()Ljava/io/IOException;
  02bc move-result-object v9
  02be throw v9
  02c0 invoke-static Lcom/personal/aihub/DecorationStorage;->invalid()Ljava/io/IOException;
  02c6 move-result-object v9
  02c8 throw v9
  02ca invoke-static Lcom/personal/aihub/DecorationStorage;->invalid()Ljava/io/IOException;
  02d0 move-result-object v9
  02d2 throw v9
.end method

.method invalid()Ljava/io/IOException;
  0000 new-instance v0, Ljava/io/IOException;
  0004 const-string v1, "The card decoration metadata is invalid. Import its original artwork again."
  0008 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  000e return-object v0
.end method

.method safe(Ljava/lang/String;)Z
  0000 invoke-virtual v5, Ljava/lang/String;->isEmpty()Z
  0006 move-result v0
  0008 const/4 v1, 0
  000a if-nez v0, +03bh
  000e invoke-virtual v5, Ljava/lang/String;->length()I
  0014 move-result v0
  0016 const/16 v2, 500
  001a if-gt v0, v2, +033h
  001e const-string v0, "/"
  0022 invoke-virtual v5, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0028 move-result v2
  002a if-nez v2, +02bh
  002e const-string v2, ".*[\\:\x00-\x1f\x7f%].*"
  0032 invoke-virtual v5, v2, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0038 move-result v2
  003a if-eqz v2, +003h
  003e goto +21h
  0040 const/4 v2, -1
  0042 invoke-virtual v5, v0, v2, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  0048 move-result-object v5
  004a array-length v0, v5
  004c move v2, v1
  004e if-ge v2, v0, +017h
  0052 aget-object v3, v5, v2
  0056 invoke-virtual v3, Ljava/lang/String;->isEmpty()Z
  005c move-result v4
  005e if-nez v4, +00eh
  0062 const-string v4, "."
  0066 invoke-virtual v3, v4, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  006c move-result v3
  006e if-eqz v3, +003h
  0072 goto +4h
  0074 add-int/lit8 v2, v2, 1
  0078 goto -15h
  007a return v1
  007c const/4 v5, 1
  007e return v5
  0080 return v1
.end method

.method store(Ljava/io/File; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 const-string v0, "text"
  0004 invoke-virtual v9, v0, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  000a move-result-object v9
  000c instance-of v0, v9, Ljava/lang/String;
  0010 if-eqz v0, +0a7h
  0014 check-cast v9, Ljava/lang/String;
  0018 invoke-virtual v9, Ljava/lang/String;->length()I
  001e move-result v0
  0020 const/high16 v1, 131072
  0024 if-gt v0, v1, +09dh
  0028 sget-object v0, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  002c invoke-virtual v9, v0, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0032 move-result-object v9
  0034 invoke-static v9, Lcom/personal/aihub/DecorationStorage;->inspect([B)Lorg/json/JSONObject;
  003a move-result-object v0
  003c invoke-virtual v8, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0042 move-result-object v1
  0044 invoke-static v1, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  004a move-result v1
  004c if-nez v1, +084h
  0050 invoke-virtual v8, Ljava/io/File;->isDirectory()Z
  0056 move-result v1
  0058 if-eqz v1, +07eh
  005c new-instance v1, Ljava/io/File;
  0060 new-instance v2, Ljava/lang/StringBuilder;
  0064 const-string v3, "generated-decoration-"
  0068 invoke-direct v2, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  006e invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0074 move-result-object v3
  0076 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  007c invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0082 move-result-object v2
  0084 invoke-direct v1, v8, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  008a invoke-virtual v1, Ljava/io/File;->mkdir()Z
  0090 move-result v8
  0092 if-eqz v8, +05ch
  0096 new-instance v8, Ljava/io/File;
  009a const-string v2, "decoration.json"
  009e invoke-direct v8, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00a4 invoke-virtual v8, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  00aa move-result-object v3
  00ac const/4 v4, 2
  00ae new-array v4, v4, [Ljava/nio/file/OpenOption;
  00b2 sget-object v5, Ljava/nio/file/StandardOpenOption;->CREATE_NEW Ljava/nio/file/StandardOpenOption;
  00b6 const/4 v6, 0
  00b8 aput-object v5, v4, v6
  00bc sget-object v5, Ljava/nio/file/StandardOpenOption;->WRITE Ljava/nio/file/StandardOpenOption;
  00c0 const/4 v7, 1
  00c2 aput-object v5, v4, v7
  00c6 invoke-static v3, v9, v4, Ljava/nio/file/Files;->write(Ljava/nio/file/Path; [B [Ljava/nio/file/OpenOption;)Ljava/nio/file/Path;
  00cc const-string v3, "key"
  00d0 new-instance v4, Ljava/lang/StringBuilder;
  00d4 invoke-direct v4, Ljava/lang/StringBuilder;-><init>()V
  00da invoke-virtual v1, Ljava/io/File;->getName()Ljava/lang/String;
  00e0 move-result-object v5
  00e2 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00e8 const-string v5, "/decoration.json"
  00ec invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00f2 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00f8 move-result-object v4
  00fa invoke-virtual v0, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0100 move-result-object v0
  0102 const-string v3, "path"
  0106 invoke-virtual v0, v3, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  010c move-result-object v0
  010e const-string v2, "name"
  0112 const-string v3, "Custom card decoration"
  0116 invoke-virtual v0, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  011c move-result-object v0
  011e const-string v2, "size"
  0122 array-length v9, v9
  0124 invoke-virtual v0, v2, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  012a move-result-object v9
  012c const-string v0, "image"
  0130 invoke-virtual v9, v0, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0136 move-result-object v8
  0138 return-object v8
  013a move-exception v9
  013c invoke-virtual v8, Ljava/io/File;->delete()Z
  0142 invoke-virtual v1, Ljava/io/File;->delete()Z
  0148 throw v9
  014a invoke-static Lcom/personal/aihub/DecorationStorage;->invalid()Ljava/io/IOException;
  0150 move-result-object v8
  0152 throw v8
  0154 invoke-static Lcom/personal/aihub/DecorationStorage;->invalid()Ljava/io/IOException;
  015a move-result-object v8
  015c throw v8
  015e invoke-static Lcom/personal/aihub/DecorationStorage;->invalid()Ljava/io/IOException;
  0164 move-result-object v8
  0166 throw v8
.end method