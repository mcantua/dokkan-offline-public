.class Lcom/personal/aihub/ProjectFormsData;
.super Ljava/lang/Object;

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method replace(Ljava/lang/Object; Ljava/util/Map; I)V
  0000 const/16 v0, 80
  0004 if-gt v6, v0, +070h
  0008 instance-of v0, v4, Lorg/json/JSONObject;
  000c if-eqz v0, +038h
  0010 check-cast v4, Lorg/json/JSONObject;
  0014 invoke-virtual v4, Lorg/json/JSONObject;->keys()Ljava/util/Iterator;
  001a move-result-object v0
  001c invoke-interface v0, Ljava/util/Iterator;->hasNext()Z
  0022 move-result v1
  0024 if-eqz v1, +05fh
  0028 invoke-interface v0, Ljava/util/Iterator;->next()Ljava/lang/Object;
  002e move-result-object v1
  0030 check-cast v1, Ljava/lang/String;
  0034 invoke-virtual v4, v1, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  003a move-result-object v2
  003c instance-of v3, v2, Ljava/lang/String;
  0040 if-eqz v3, +010h
  0044 invoke-interface v5, v2, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z
  004a move-result v3
  004c if-eqz v3, +00ah
  0050 invoke-interface v5, v2, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0056 move-result-object v2
  0058 invoke-virtual v4, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  005e goto -21h
  0060 instance-of v1, v2, Lorg/json/JSONObject;
  0064 if-nez v1, +006h
  0068 instance-of v1, v2, Lorg/json/JSONArray;
  006c if-eqz v1, -028h
  0070 add-int/lit8 v1, v6, 1
  0074 invoke-static v2, v5, v1, Lcom/personal/aihub/ProjectFormsData;->replace(Ljava/lang/Object; Ljava/util/Map; I)V
  007a goto -2fh
  007c instance-of v0, v4, Lorg/json/JSONArray;
  0080 if-eqz v0, +031h
  0084 check-cast v4, Lorg/json/JSONArray;
  0088 const/4 v0, 0
  008a invoke-virtual v4, Lorg/json/JSONArray;->length()I
  0090 move-result v1
  0092 if-ge v0, v1, +028h
  0096 invoke-virtual v4, v0, Lorg/json/JSONArray;->get(I)Ljava/lang/Object;
  009c move-result-object v1
  009e instance-of v2, v1, Ljava/lang/String;
  00a2 if-eqz v2, +010h
  00a6 invoke-interface v5, v1, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z
  00ac move-result v2
  00ae if-eqz v2, +00ah
  00b2 invoke-interface v5, v1, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  00b8 move-result-object v1
  00ba invoke-virtual v4, v0, v1, Lorg/json/JSONArray;->put(I Ljava/lang/Object;)Lorg/json/JSONArray;
  00c0 goto +eh
  00c2 instance-of v2, v1, Lorg/json/JSONObject;
  00c6 if-nez v2, +006h
  00ca instance-of v2, v1, Lorg/json/JSONArray;
  00ce if-eqz v2, +007h
  00d2 add-int/lit8 v2, v6, 1
  00d6 invoke-static v1, v5, v2, Lcom/personal/aihub/ProjectFormsData;->replace(Ljava/lang/Object; Ljava/util/Map; I)V
  00dc add-int/lit8 v0, v0, 1
  00e0 goto -2bh
  00e2 return-void 
  00e4 new-instance v4, Ljava/io/IOException;
  00e8 const-string v5, "The embedded unit is too deeply nested."
  00ec invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00f2 throw v4
.end method

.method reservedIds(Lorg/json/JSONObject;)Lorg/json/JSONArray;
  0000 new-instance v0, Lorg/json/JSONArray;
  0004 invoke-direct v0, Lorg/json/JSONArray;-><init>()V
  000a const-string v1, "targetId"
  000e invoke-virtual v5, v1, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0014 move-result-wide v2
  0016 invoke-virtual v0, v2, v3, Lorg/json/JSONArray;->put(J)Lorg/json/JSONArray;
  001c move-result-object v0
  001e const-string v2, "formProjects"
  0022 invoke-virtual v5, v2, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0028 move-result-object v5
  002a if-eqz v5, +026h
  002e invoke-virtual v5, Lorg/json/JSONArray;->length()I
  0034 move-result v2
  0036 const/4 v3, 4
  0038 if-gt v2, v3, +017h
  003c const/4 v2, 0
  003e invoke-virtual v5, Lorg/json/JSONArray;->length()I
  0044 move-result v3
  0046 if-ge v2, v3, +018h
  004a invoke-virtual v5, v2, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  0050 move-result-object v3
  0052 invoke-virtual v3, v1, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0058 move-result-wide v3
  005a invoke-virtual v0, v3, v4, Lorg/json/JSONArray;->put(J)Lorg/json/JSONArray;
  0060 add-int/lit8 v2, v2, 1
  0064 goto -13h
  0066 new-instance v5, Ljava/io/IOException;
  006a const-string v0, "A unit supports up to four transformation forms."
  006e invoke-direct v5, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0074 throw v5
  0076 return-object v0
.end method

.method restore(Lorg/json/JSONObject; Ljava/lang/String; Ljava/io/File;)V
  0000 move-object/from16 v0, v18
  0004 move-object/from16 v1, v19
  0008 new-instance v2, Lorg/json/JSONArray;
  000c invoke-direct v2, Lorg/json/JSONArray;-><init>()V
  0012 invoke-virtual v2, v0, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0018 move-result-object v2
  001a const-string v3, "formProjects"
  001e invoke-virtual v0, v3, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0024 move-result-object v4
  0026 const-string v5, "transformLinks"
  002a if-eqz v4, +036h
  002e invoke-virtual v4, Lorg/json/JSONArray;->length()I
  0034 move-result v7
  0036 const/4 v8, 4
  0038 if-gt v7, v8, +027h
  003c const/4 v7, 0
  003e invoke-virtual v4, Lorg/json/JSONArray;->length()I
  0044 move-result v8
  0046 if-ge v7, v8, +028h
  004a invoke-virtual v4, v7, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  0050 move-result-object v8
  0052 invoke-virtual v8, v3, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  0058 move-result v9
  005a if-nez v9, +00eh
  005e invoke-virtual v8, v5, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  0064 move-result v9
  0066 if-nez v9, +008h
  006a invoke-virtual v2, v8, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0070 add-int/lit8 v7, v7, 1
  0074 goto -1bh
  0076 new-instance v0, Ljava/io/IOException;
  007a const-string v1, "Nested transformation forms are not supported."
  007e invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0084 throw v0
  0086 new-instance v0, Ljava/io/IOException;
  008a const-string v1, "Too many embedded forms."
  008e invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0094 throw v0
  0096 new-instance v3, Ljava/util/HashMap;
  009a invoke-direct v3, Ljava/util/HashMap;-><init>()V
  00a0 new-instance v4, Ljava/util/HashMap;
  00a4 invoke-direct v4, Ljava/util/HashMap;-><init>()V
  00aa const/4 v7, 0
  00ac invoke-virtual v2, Lorg/json/JSONArray;->length()I
  00b2 move-result v8
  00b4 if-ge v7, v8, +0f1h
  00b8 invoke-virtual v2, v7, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  00be move-result-object v8
  00c0 const-string v9, "format"
  00c4 invoke-virtual v8, v9, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  00ca move-result-object v9
  00cc const-string v10, "dokkan-unit-forge"
  00d0 invoke-virtual v10, v9, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00d6 move-result v9
  00d8 if-eqz v9, +0d7h
  00dc const-string v9, "version"
  00e0 invoke-virtual v8, v9, Lorg/json/JSONObject;->optInt(Ljava/lang/String;)I
  00e6 move-result v9
  00e8 const/4 v10, 1
  00ea if-ne v9, v10, +0ceh
  00ee const-string v9, "tables"
  00f2 invoke-virtual v8, v9, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  00f8 move-result-object v9
  00fa const-string v11, "cards"
  00fe invoke-virtual v9, v11, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0104 move-result-object v9
  0106 invoke-virtual v9, Lorg/json/JSONArray;->length()I
  010c move-result v9
  010e if-ne v9, v10, +0bch
  0112 const-string v9, "key"
  0116 invoke-virtual v8, v9, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  011c move-result-object v10
  011e new-instance v11, Ljava/lang/StringBuilder;
  0122 const-string v12, "unit-"
  0126 invoke-direct v11, v12, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  012c const-string v12, "targetId"
  0130 invoke-virtual v8, v12, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0136 move-result-wide v12
  0138 invoke-virtual v11, v12, v13, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  013e const-string v12, "-"
  0142 invoke-virtual v11, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0148 invoke-virtual v11, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  014e invoke-virtual v11, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0154 move-result-object v11
  0156 invoke-interface v4, v10, v11, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  015c invoke-virtual v8, v9, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0162 const-string v10, "assets"
  0166 invoke-virtual v8, v10, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  016c move-result-object v10
  016e const-string v11, "previewKey"
  0172 const/4 v12, 0
  0174 if-eqz v10, +078h
  0178 const/4 v13, 0
  017a invoke-virtual v10, Lorg/json/JSONArray;->length()I
  0180 move-result v14
  0182 if-ge v13, v14, +071h
  0186 invoke-virtual v10, v13, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  018c move-result-object v14
  018e new-instance v15, Ljava/lang/StringBuilder;
  0192 const-string v6, "files/"
  0196 invoke-direct v15, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  019c const-string v6, "path"
  01a0 invoke-virtual v14, v6, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  01a6 move-result-object v6
  01a8 invoke-virtual v15, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01ae invoke-virtual v15, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01b4 move-result-object v6
  01b6 invoke-static v6, Lcom/personal/aihub/EclpCodec;->safePath(Ljava/lang/String;)Z
  01bc move-result v15
  01be if-eqz v15, +04bh
  01c2 new-instance v15, Ljava/io/File;
  01c6 move-object/from16 v16, v2
  01ca move-object/from16 v2, v20
  01ce invoke-direct v15, v2, v6, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  01d4 invoke-virtual v15, Ljava/io/File;->isFile()Z
  01da move-result v15
  01dc if-eqz v15, +03ch
  01e0 invoke-virtual v14, v9, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  01e6 move-result-object v15
  01e8 new-instance v2, Ljava/lang/StringBuilder;
  01ec move-object/from16 v17, v10
  01f0 const-string v10, "patch-"
  01f4 invoke-direct v2, v10, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  01fa invoke-virtual v2, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0200 const-string v10, "/"
  0204 invoke-virtual v2, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  020a invoke-virtual v2, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0210 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0216 move-result-object v2
  0218 invoke-virtual v8, v11, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  021e move-result-object v6
  0220 invoke-virtual v15, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0226 move-result v6
  0228 if-eqz v6, +003h
  022c move-object v12, v2
  022e invoke-interface v3, v15, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z
  0234 move-result v6
  0236 if-nez v6, +005h
  023a invoke-interface v3, v15, v2, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0240 invoke-virtual v14, v9, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0246 add-int/lit8 v13, v13, 1
  024a move-object/from16 v2, v16
  024e move-object/from16 v10, v17
  0252 goto -6ch
  0254 new-instance v0, Ljava/io/IOException;
  0258 const-string v1, "Embedded form resource missing."
  025c invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0262 throw v0
  0264 move-object/from16 v16, v2
  0268 if-eqz v12, +006h
  026c invoke-virtual v8, v11, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0272 goto +4h
  0274 invoke-virtual v8, v11, Lorg/json/JSONObject;->remove(Ljava/lang/String;)Ljava/lang/Object;
  027a add-int/lit8 v7, v7, 1
  027e move-object/from16 v2, v16
  0282 goto/16 -0ebh
  0286 new-instance v0, Ljava/io/IOException;
  028a const-string v1, "Invalid embedded unit form."
  028e invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0294 throw v0
  0296 invoke-virtual v0, v5, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  029c move-result-object v1
  029e if-eqz v1, +029h
  02a2 const/4 v2, 0
  02a4 invoke-virtual v1, Lorg/json/JSONArray;->length()I
  02aa move-result v5
  02ac if-ge v2, v5, +022h
  02b0 invoke-virtual v1, v2, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  02b6 move-result-object v5
  02b8 const-string v6, "targetKey"
  02bc invoke-virtual v5, v6, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  02c2 move-result-object v7
  02c4 invoke-interface v4, v7, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  02ca move-result-object v7
  02cc check-cast v7, Ljava/lang/String;
  02d0 if-eqz v7, +008h
  02d4 invoke-virtual v5, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02da add-int/lit8 v2, v2, 1
  02de goto -1dh
  02e0 new-instance v0, Ljava/io/IOException;
  02e4 const-string v1, "An embedded transformation form is missing."
  02e8 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02ee throw v0
  02f0 const/4 v1, 0
  02f2 invoke-static v0, v3, v1, Lcom/personal/aihub/ProjectFormsData;->replace(Ljava/lang/Object; Ljava/util/Map; I)V
  02f8 return-void 
.end method