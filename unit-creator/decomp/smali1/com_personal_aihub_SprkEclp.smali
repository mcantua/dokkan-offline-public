.class Lcom/personal/aihub/SprkEclp;
.super Ljava/lang/Object;

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method convert(Ljava/io/File; Ljava/io/File; Ljava/io/File; Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 move-object/from16 v0, v21
  0004 invoke-virtual/range v18, Ljava/io/File;->isDirectory()Z
  000a move-result v1
  000c if-eqz v1, +238h
  0010 invoke-virtual/range v19, Ljava/io/File;->exists()Z
  0016 move-result v1
  0018 if-nez v1, +22ah
  001c new-instance v1, Ljava/io/File;
  0020 const-string v2, "payload"
  0024 move-object/from16 v3, v18
  0028 invoke-direct v1, v3, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  002e move-object/from16 v2, v17
  0032 invoke-static v2, v1, Lcom/personal/aihub/SprkCodec;->inspect(Ljava/io/File; Ljava/io/File;)Lorg/json/JSONObject;
  0038 move-result-object v3
  003a const-string v4, "canConvertToEclp"
  003e invoke-virtual v3, v4, Lorg/json/JSONObject;->getBoolean(Ljava/lang/String;)Z
  0044 move-result v4
  0046 const/4 v5, 0
  0048 if-nez v4, +02eh
  004c const-string v0, "warnings"
  0050 invoke-virtual v3, v0, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0056 move-result-object v0
  0058 new-instance v1, Ljava/lang/StringBuilder;
  005c const-string v2, "This patch uses Sparking features that cannot yet be converted safely to Eclipse."
  0060 invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0066 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  006c move-result v2
  006e if-ge v5, v2, +011h
  0072 const-string v2, " "
  0076 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  007c invoke-virtual v0, v5, Lorg/json/JSONArray;->getString(I)Ljava/lang/String;
  0082 move-result-object v2
  0084 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  008a add-int/lit8 v5, v5, 1
  008e goto -14h
  0090 new-instance v0, Ljava/io/IOException;
  0094 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  009a move-result-object v1
  009c invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00a2 throw v0
  00a4 const-string v4, "patchInfo"
  00a8 invoke-virtual v3, v4, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  00ae move-result-object v4
  00b0 const-string v6, "(?i)\.sprk$"
  00b4 const-string v7, ""
  00b8 invoke-virtual v0, v6, v7, Ljava/lang/String;->replaceFirst(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  00be move-result-object v6
  00c0 const-string v8, "patch_name"
  00c4 invoke-virtual v4, v8, v6, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  00ca move-result-object v6
  00cc const-string v8, "name"
  00d0 invoke-virtual v4, v8, v6, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  00d6 move-result-object v6
  00d8 invoke-virtual v6, Ljava/lang/String;->trim()Ljava/lang/String;
  00de move-result-object v6
  00e0 invoke-virtual v6, Ljava/lang/String;->isEmpty()Z
  00e6 move-result v9
  00e8 if-eqz v9, +004h
  00ec const-string v6, "Imported Sparking patch"
  00f0 invoke-virtual v6, Ljava/lang/String;->length()I
  00f6 move-result v9
  00f8 const/16 v10, 160
  00fc if-le v9, v10, +006h
  0100 invoke-virtual v6, v5, v10, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  0106 move-result-object v6
  0108 move-object v14, v6
  010a const-string v6, "version"
  010e const-string v9, "1.0"
  0112 invoke-virtual v4, v6, v9, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0118 move-result-object v10
  011a invoke-virtual v10, Ljava/lang/String;->trim()Ljava/lang/String;
  0120 move-result-object v10
  0122 invoke-virtual v10, Ljava/lang/String;->isEmpty()Z
  0128 move-result v11
  012a if-nez v11, +00dh
  012e invoke-virtual v10, Ljava/lang/String;->length()I
  0134 move-result v11
  0136 const/16 v12, 50
  013a if-le v11, v12, +003h
  013e goto +3h
  0140 move-object v15, v10
  0142 goto +2h
  0144 move-object v15, v9
  0146 new-instance v9, Lorg/json/JSONObject;
  014a invoke-direct v9, Lorg/json/JSONObject;-><init>()V
  0150 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0156 move-result-object v10
  0158 invoke-virtual v10, Ljava/util/UUID;->toString()Ljava/lang/String;
  015e move-result-object v10
  0160 const-string v11, "uuid"
  0164 invoke-virtual v9, v11, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  016a move-result-object v9
  016c invoke-virtual v9, v8, v14, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0172 move-result-object v8
  0174 invoke-virtual v8, v6, v15, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  017a move-result-object v6
  017c const-string v8, "creatorName"
  0180 invoke-virtual v3, v8, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0186 move-result-object v8
  0188 const-string v9, "author"
  018c invoke-virtual v6, v9, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0192 move-result-object v6
  0194 const-string v8, "description"
  0198 invoke-virtual v4, v8, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  019e move-result-object v9
  01a0 invoke-virtual v6, v8, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01a6 move-result-object v6
  01a8 const-string v8, "sourceFormat"
  01ac const-string v9, "sparking-sprk"
  01b0 invoke-virtual v6, v8, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01b6 move-result-object v6
  01b8 const-string v8, "sourceFilename"
  01bc invoke-virtual v6, v8, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01c2 move-result-object v0
  01c4 const-string v6, "sourceZIPsha256"
  01c8 invoke-static/range v17, Lcom/personal/aihub/GameDataStore;->hash(Ljava/io/File;)Ljava/lang/String;
  01ce move-result-object v2
  01d0 invoke-virtual v0, v6, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01d6 move-result-object v0
  01d8 const-string v2, "compatibility"
  01dc const-string v6, "Format converted; Eclipse SQL and gameplay compatibility need validation in Eclipse."
  01e0 invoke-virtual v0, v2, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01e6 move-result-object v0
  01e8 new-instance v2, Ljava/util/ArrayList;
  01ec invoke-direct v2, Ljava/util/ArrayList;-><init>()V
  01f2 new-instance v6, Ljava/util/HashSet;
  01f6 invoke-direct v6, Ljava/util/HashSet;-><init>()V
  01fc const-string v8, "entries"
  0200 invoke-virtual v3, v8, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0206 move-result-object v8
  0208 move v9, v5
  020a invoke-virtual v8, Lorg/json/JSONArray;->length()I
  0210 move-result v10
  0212 if-ge v9, v10, +09dh
  0216 invoke-virtual v8, v9, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  021c move-result-object v10
  021e const-string v13, "kind"
  0222 invoke-virtual v10, v13, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0228 move-result-object v13
  022a const-string v5, "gameSql"
  022e invoke-virtual v13, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0234 move-result v16
  0236 const-string v12, "asset"
  023a if-nez v16, +00dh
  023e invoke-virtual v13, v12, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0244 move-result v16
  0246 if-nez v16, +007h
  024a move-object/from16 v16, v7
  024e move-object/from16 v21, v8
  0252 goto +6ch
  0254 move-object/from16 v16, v7
  0258 const-string v7, "relativePath"
  025c invoke-virtual v10, v7, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0262 move-result-object v7
  0264 invoke-virtual v13, v12, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  026a move-result v12
  026c if-eqz v12, +01bh
  0270 sget-object v12, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  0274 invoke-virtual v7, v12, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  027a move-result-object v12
  027c move-object/from16 v21, v8
  0280 const-string v8, ".sql"
  0284 invoke-virtual v12, v8, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  028a move-result v8
  028c if-nez v8, +003h
  0290 goto +bh
  0292 new-instance v0, Ljava/io/IOException;
  0296 const-string v1, "A Sparking asset ends in .sql and could be executed by Eclipse. Conversion was stopped."
  029a invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02a0 throw v0
  02a2 move-object/from16 v21, v8
  02a6 new-instance v8, Ljava/lang/StringBuilder;
  02aa const-string v12, "files/"
  02ae invoke-direct v8, v12, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  02b4 invoke-virtual v13, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  02ba move-result v5
  02bc if-eqz v5, +005h
  02c0 const-string v5, "sparking-sql/"
  02c4 goto +3h
  02c6 move-object/from16 v5, v16
  02ca invoke-virtual v8, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02d0 invoke-virtual v8, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02d6 invoke-virtual v8, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  02dc move-result-object v5
  02de sget-object v7, Ljava/text/Normalizer$Form;->NFC Ljava/text/Normalizer$Form;
  02e2 invoke-static v5, v7, Ljava/text/Normalizer;->normalize(Ljava/lang/CharSequence; Ljava/text/Normalizer$Form;)Ljava/lang/String;
  02e8 move-result-object v7
  02ea sget-object v8, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  02ee invoke-virtual v7, v8, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  02f4 move-result-object v7
  02f6 invoke-interface v6, v7, Ljava/util/Set;->add(Ljava/lang/Object;)Z
  02fc move-result v7
  02fe if-eqz v7, +01fh
  0302 new-instance v7, Lcom/personal/aihub/EclpCodec$Entry;
  0306 new-instance v8, Ljava/io/File;
  030a const-string v12, "path"
  030e invoke-virtual v10, v12, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0314 move-result-object v10
  0316 invoke-direct v8, v1, v10, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  031c const/4 v10, 0
  031e invoke-direct v7, v5, v8, v10, Lcom/personal/aihub/EclpCodec$Entry;-><init>(Ljava/lang/String; Ljava/io/File; [B)V
  0324 invoke-virtual v2, v7, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  032a add-int/lit8 v9, v9, 1
  032e move-object/from16 v8, v21
  0332 move-object/from16 v7, v16
  0336 const/4 v5, 0
  0338 goto/16 -097h
  033c new-instance v0, Ljava/io/IOException;
  0340 const-string v1, "Sparking SQL and assets would overwrite the same Eclipse file."
  0344 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  034a throw v0
  034c invoke-interface v6, Ljava/util/Set;->iterator()Ljava/util/Iterator;
  0352 move-result-object v1
  0354 invoke-interface v1, Ljava/util/Iterator;->hasNext()Z
  035a move-result v5
  035c if-eqz v5, +02ah
  0360 invoke-interface v1, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0366 move-result-object v5
  0368 check-cast v5, Ljava/lang/String;
  036c const/16 v7, 47
  0370 invoke-virtual v5, v7, Ljava/lang/String;->indexOf(I)I
  0376 move-result v8
  0378 if-ltz v8, -012h
  037c const/4 v9, 0
  037e invoke-virtual v5, v9, v8, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  0384 move-result-object v10
  0386 invoke-interface v6, v10, Ljava/util/Set;->contains(Ljava/lang/Object;)Z
  038c move-result v10
  038e if-nez v10, +009h
  0392 add-int/lit8 v8, v8, 1
  0396 invoke-virtual v5, v7, v8, Ljava/lang/String;->indexOf(I I)I
  039c move-result v8
  039e goto -13h
  03a0 new-instance v0, Ljava/io/IOException;
  03a4 const-string v1, "An Eclipse file would overwrite a converted resource folder."
  03a8 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03ae throw v0
  03b0 new-instance v1, Lcom/personal/aihub/EclpCodec$Entry;
  03b4 invoke-virtual v4, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  03ba move-result-object v4
  03bc sget-object v5, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  03c0 invoke-virtual v4, v5, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  03c6 move-result-object v4
  03c8 const-string v5, "sparking-source.json"
  03cc const/4 v6, 0
  03ce invoke-direct v1, v5, v6, v4, Lcom/personal/aihub/EclpCodec$Entry;-><init>(Ljava/lang/String; Ljava/io/File; [B)V
  03d4 invoke-virtual v2, v1, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  03da new-instance v1, Lcom/personal/aihub/EclpCodec$Entry;
  03de invoke-virtual v0, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  03e4 move-result-object v4
  03e6 sget-object v5, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  03ea invoke-virtual v4, v5, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  03f0 move-result-object v4
  03f2 const-string v5, "metadata.json"
  03f6 invoke-direct v1, v5, v6, v4, Lcom/personal/aihub/EclpCodec$Entry;-><init>(Ljava/lang/String; Ljava/io/File; [B)V
  03fc invoke-virtual v2, v1, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0402 new-instance v1, Ljava/io/FileOutputStream;
  0406 move-object/from16 v4, v19
  040a invoke-direct v1, v4, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0410 invoke-virtual v0, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0416 move-result-object v12
  0418 invoke-virtual v0, v11, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  041e move-result-object v13
  0420 move-object v9, v1
  0422 move-object/from16 v10, v20
  0426 move-object v11, v2
  0428 invoke-static/range v9 ... v15, Lcom/personal/aihub/EclpCodec;->write(Ljava/io/OutputStream; Ljava/io/File; Ljava/util/List; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)V
  042e invoke-virtual v1, Ljava/io/FileOutputStream;->close()V
  0434 const-string v1, "metadata"
  0438 invoke-virtual v3, v1, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  043e move-result-object v0
  0440 return-object v0
  0442 move-exception v0
  0444 move-object v2, v0
  0446 invoke-virtual v1, Ljava/io/FileOutputStream;->close()V
  044c goto +6h
  044e move-exception v0
  0450 move-object v1, v0
  0452 invoke-virtual v2, v1, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0458 throw v2
  045a move-exception v0
  045c goto +4h
  045e move-exception v0
  0460 move-object/from16 v4, v19
  0464 invoke-virtual/range v19, Ljava/io/File;->delete()Z
  046a throw v0
  046c new-instance v0, Ljava/io/IOException;
  0470 const-string v1, "Choose a new output file for Sparking conversion."
  0474 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  047a throw v0
  047c new-instance v0, Ljava/io/IOException;
  0480 const-string v1, "Could not create Sparking conversion staging."
  0484 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  048a throw v0
.end method