.class Lcom/personal/aihub/PreviewMetadata;
.super Ljava/lang/Object;

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method access$000(Ljava/io/File; Ljava/lang/String; J)Lorg/json/JSONObject;
  0000 invoke-static v0, v1, v2, v3, Lcom/personal/aihub/PreviewMetadata;->rowFromFile(Ljava/io/File; Ljava/lang/String; J)Lorg/json/JSONObject;
  0006 move-result-object v0
  0008 return-object v0
.end method

.method databaseFile(Ljava/io/File; Ljava/lang/String;)Ljava/io/File;
  0000 const-wide/16 v0, 0
  0004 invoke-static v2, v3, v0, v1, Lcom/personal/aihub/PreviewMetadata;->databaseFile(Ljava/io/File; Ljava/lang/String; J)Ljava/io/File;
  000a move-result-object v2
  000c return-object v2
.end method

.method databaseFile(Ljava/io/File; Ljava/lang/String; J)Ljava/io/File;
  0000 const-wide/16 v0, 0
  0004 cmp-long v0, v9, v0
  0008 if-ltz v0, +0abh
  000c const-wide v1, 9007199254740991
  0016 cmp-long v1, v9, v1
  001a if-gtz v1, +0a2h
  001e invoke-static v8, Lcom/personal/aihub/PreviewMetadata;->normalizeSource(Ljava/lang/String;)Ljava/lang/String;
  0024 move-result-object v8
  0026 const-string v1, "sparking"
  002a invoke-virtual v8, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0030 move-result v8
  0032 if-eqz v8, +085h
  0036 new-instance v8, Ljava/io/File;
  003a invoke-direct v8, v7, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0040 new-instance v1, Lcom/personal/aihub/GameDataStore;
  0044 new-instance v2, Ljava/io/File;
  0048 const-string v3, "sparking-unavailable.db"
  004c invoke-direct v2, v7, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0052 invoke-direct v1, v8, v2, Lcom/personal/aihub/GameDataStore;-><init>(Ljava/io/File; Ljava/io/File;)V
  0058 invoke-virtual v1, Lcom/personal/aihub/GameDataStore;->state()Lorg/json/JSONObject;
  005e move-result-object v7
  0060 if-lez v0, +055h
  0064 if-eqz v7, +03ah
  0068 const-string v8, "active"
  006c const-string v0, "previous"
  0070 filled-new-array v8, v0, [Ljava/lang/String;
  0076 move-result-object v8
  0078 const/4 v0, 0
  007a const/4 v2, 2
  007c if-ge v0, v2, +02eh
  0080 aget-object v2, v8, v0
  0084 invoke-virtual v7, v2, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  008a move-result-object v2
  008c if-nez v2, +004h
  0090 const/4 v3, 0
  0092 goto +7h
  0094 const-string v3, "meta"
  0098 invoke-virtual v2, v3, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  009e move-result-object v3
  00a0 if-eqz v3, +019h
  00a4 const-string v4, "latestVersion"
  00a8 const-wide/16 v5, -1
  00ac invoke-virtual v3, v4, v5, v6, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  00b2 move-result-wide v3
  00b4 cmp-long v3, v3, v9
  00b8 if-nez v3, +00dh
  00bc invoke-virtual v1, v2, Lcom/personal/aihub/GameDataStore;->file(Lorg/json/JSONObject;)Ljava/io/File;
  00c2 move-result-object v2
  00c4 invoke-virtual v2, Ljava/io/File;->isFile()Z
  00ca move-result v3
  00cc if-eqz v3, +003h
  00d0 return-object v2
  00d2 add-int/lit8 v0, v0, 1
  00d6 goto -2eh
  00d8 new-instance v7, Ljava/io/IOException;
  00dc new-instance v8, Ljava/lang/StringBuilder;
  00e0 const-string v0, "This animation needs Sparking content version "
  00e4 invoke-direct v8, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00ea invoke-virtual v8, v9, v10, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  00f0 const-string v9, ". Restore or import that version before previewing; another version was not substituted."
  00f4 invoke-virtual v8, v9, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00fa invoke-virtual v8, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0100 move-result-object v8
  0102 invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0108 throw v7
  010a if-eqz v7, +011h
  010e invoke-virtual v1, Lcom/personal/aihub/GameDataStore;->current()Ljava/io/File;
  0114 move-result-object v7
  0116 invoke-virtual v7, Ljava/io/File;->isFile()Z
  011c move-result v7
  011e if-eqz v7, +007h
  0122 invoke-virtual v1, Lcom/personal/aihub/GameDataStore;->current()Ljava/io/File;
  0128 move-result-object v7
  012a return-object v7
  012c new-instance v7, Ljava/io/IOException;
  0130 const-string v8, "Download Sparking characters from Library before previewing this source."
  0134 invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  013a throw v7
  013c new-instance v8, Lcom/personal/aihub/GameDataStore;
  0140 new-instance v9, Ljava/io/File;
  0144 const-string v10, "bundled-database.db"
  0148 invoke-direct v9, v7, v10, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  014e invoke-direct v8, v7, v9, Lcom/personal/aihub/GameDataStore;-><init>(Ljava/io/File; Ljava/io/File;)V
  0154 invoke-virtual v8, Lcom/personal/aihub/GameDataStore;->current()Ljava/io/File;
  015a move-result-object v7
  015c return-object v7
  015e new-instance v7, Ljava/io/IOException;
  0162 const-string v8, "Choose a valid Sparking content version."
  0166 invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  016c throw v7
.end method

.method lambda$0(Ljava/util/Map; Ljava/io/File; Ljava/lang/String; J)Lorg/json/JSONObject;
  0000 const-string v0, "effect_packs"
  0004 invoke-virtual v3, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  000a move-result v0
  000c if-eqz v0, +017h
  0010 invoke-static v4, v5, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  0016 move-result-object v0
  0018 invoke-interface v1, v0, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z
  001e move-result v0
  0020 if-eqz v0, +00dh
  0024 invoke-static v4, v5, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  002a move-result-object v2
  002c invoke-interface v1, v2, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0032 move-result-object v1
  0034 check-cast v1, Lorg/json/JSONObject;
  0038 goto +5h
  003a invoke-static v2, v3, v4, v5, Lcom/personal/aihub/PreviewMetadata;->row(Ljava/io/File; Ljava/lang/String; J)Lorg/json/JSONObject;
  0040 move-result-object v1
  0042 return-object v1
.end method

.method localOnly(Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray;)Z
  0000 invoke-static v5, Lcom/personal/aihub/PreviewMetadata;->normalizeSource(Ljava/lang/String;)Ljava/lang/String;
  0006 move-result-object v5
  0008 const-string v0, "sparking"
  000c invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0012 move-result v5
  0014 const/4 v0, 1
  0016 if-eqz v5, +003h
  001a return v0
  001c const-string v5, "/api/effect-pack/([1-9][0-9]*)(?:\?enemy=1)?$"
  0020 invoke-static v5, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;)Ljava/util/regex/Pattern;
  0026 move-result-object v5
  0028 invoke-virtual v5, v6, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  002e move-result-object v5
  0030 invoke-virtual v5, Ljava/util/regex/Matcher;->find()Z
  0036 move-result v6
  0038 const/4 v1, 0
  003a if-nez v6, +003h
  003e return v1
  0040 invoke-virtual v5, v0, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  0046 move-result-object v5
  0048 invoke-static v5, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  004e move-result-wide v5
  0050 move v2, v1
  0052 invoke-virtual v7, Lorg/json/JSONArray;->length()I
  0058 move-result v3
  005a if-ge v2, v3, +00eh
  005e invoke-virtual v7, v2, Lorg/json/JSONArray;->getLong(I)J
  0064 move-result-wide v3
  0066 cmp-long v3, v3, v5
  006a if-nez v3, +003h
  006e return v0
  0070 add-int/lit8 v2, v2, 1
  0074 goto -11h
  0076 return v1
.end method

.method metadataQuery(Lcom/personal/aihub/GameMetadata$Query; Lcom/personal/aihub/GameMetadata$Query; Lorg/json/JSONArray; Lorg/json/JSONArray;)Lcom/personal/aihub/GameMetadata$Query;
  0000 invoke-static v8, Lcom/personal/aihub/PreviewEffectPacks;->normalize(Ljava/lang/Object;)Lorg/json/JSONArray;
  0006 move-result-object v8
  0008 invoke-static v9, Lcom/personal/aihub/PreviewMetadata;->sparkingEffects(Ljava/lang/Object;)Lorg/json/JSONArray;
  000e move-result-object v9
  0010 invoke-static v8, v9, Lcom/personal/aihub/PreviewMetadata;->validateEffectSources(Lorg/json/JSONArray; Lorg/json/JSONArray;)V
  0016 new-instance v0, Ljava/util/HashSet;
  001a invoke-direct v0, Ljava/util/HashSet;-><init>()V
  0020 new-instance v1, Ljava/util/HashMap;
  0024 invoke-direct v1, Ljava/util/HashMap;-><init>()V
  002a const/4 v2, 0
  002c move v3, v2
  002e invoke-virtual v9, Lorg/json/JSONArray;->length()I
  0034 move-result v4
  0036 if-ge v3, v4, +010h
  003a invoke-virtual v9, v3, Lorg/json/JSONArray;->getLong(I)J
  0040 move-result-wide v4
  0042 invoke-static v4, v5, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  0048 move-result-object v4
  004a invoke-interface v0, v4, Ljava/util/Set;->add(Ljava/lang/Object;)Z
  0050 add-int/lit8 v3, v3, 1
  0054 goto -13h
  0056 invoke-virtual v8, Lorg/json/JSONArray;->length()I
  005c move-result v9
  005e if-ge v2, v9, +016h
  0062 invoke-virtual v8, v2, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  0068 move-result-object v9
  006a const-string v3, "id"
  006e invoke-virtual v9, v3, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0074 move-result-wide v3
  0076 invoke-static v3, v4, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  007c move-result-object v3
  007e invoke-interface v1, v3, v9, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0084 add-int/lit8 v2, v2, 1
  0088 goto -19h
  008a new-instance v8, Lcom/personal/aihub/PreviewMetadata$3;
  008e invoke-direct v8, v1, v0, v7, v6, Lcom/personal/aihub/PreviewMetadata$3;-><init>(Ljava/util/Map; Ljava/util/Set; Lcom/personal/aihub/GameMetadata$Query; Lcom/personal/aihub/GameMetadata$Query;)V
  0094 return-object v8
.end method

.method normalizeSource(Ljava/lang/String;)Ljava/lang/String;
  0000 const-string v0, "eclipse"
  0004 if-eqz v2, +020h
  0008 invoke-virtual v2, Ljava/lang/String;->isEmpty()Z
  000e move-result v1
  0010 if-nez v1, +01ah
  0014 invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  001a move-result v1
  001c if-eqz v1, +003h
  0020 goto +12h
  0022 const-string v0, "sparking"
  0026 invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  002c move-result v0
  002e if-eqz v0, +003h
  0032 return-object v2
  0034 new-instance v2, Ljava/io/IOException;
  0038 const-string v0, "Unsupported preview database source."
  003c invoke-direct v2, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0042 throw v2
  0044 return-object v0
.end method

.method normalizeVersion(Ljava/lang/Object;)J
  0000 if-nez v8, +005h
  0004 const-wide/16 v0, 0
  0008 return-wide v0
  000a instance-of v0, v8, Ljava/lang/Number;
  000e const-string v1, "Choose a valid Sparking content version."
  0012 if-eqz v0, +031h
  0016 check-cast v8, Ljava/lang/Number;
  001a invoke-virtual v8, Ljava/lang/Number;->longValue()J
  0020 move-result-wide v2
  0022 invoke-virtual v8, Ljava/lang/Number;->doubleValue()D
  0028 move-result-wide v4
  002a invoke-static v4, v5, Ljava/lang/Double;->isFinite(D)Z
  0030 move-result v0
  0032 if-eqz v0, +01bh
  0036 invoke-virtual v8, Ljava/lang/Number;->doubleValue()D
  003c move-result-wide v4
  003e long-to-double v6, v2
  0040 cmpl-double v8, v4, v6
  0044 if-nez v8, +012h
  0048 const-wide/16 v4, 1
  004c cmp-long v8, v2, v4
  0050 if-ltz v8, +00ch
  0054 const-wide v4, 9007199254740991
  005e cmp-long v8, v2, v4
  0062 if-gtz v8, +003h
  0066 return-wide v2
  0068 new-instance v8, Ljava/io/IOException;
  006c invoke-direct v8, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0072 throw v8
  0074 new-instance v8, Ljava/io/IOException;
  0078 invoke-direct v8, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  007e throw v8
.end method

.method resolve(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 const/4 v0, 0
  0002 invoke-static v1, v2, v3, v4, v0, Lcom/personal/aihub/PreviewMetadata;->resolve(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray;)Lorg/json/JSONObject;
  0008 move-result-object v1
  000a return-object v1
.end method

.method resolve(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray;)Lorg/json/JSONObject;
  0000 const/4 v5, 0
  0002 move-object v0, v6
  0004 move-object v1, v7
  0006 move-object v2, v8
  0008 move-object v3, v9
  000a move-object v4, v10
  000c invoke-static/range v0 ... v5, Lcom/personal/aihub/PreviewMetadata;->resolve(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray;)Lorg/json/JSONObject;
  0012 move-result-object v6
  0014 return-object v6
.end method

.method resolve(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray;)Lorg/json/JSONObject;
  0000 const-string v6, ""
  0004 move-object v0, v7
  0006 move-object v1, v8
  0008 move-object v2, v9
  000a move-object v3, v10
  000c move-object v4, v11
  000e move-object v5, v12
  0010 invoke-static/range v0 ... v6, Lcom/personal/aihub/PreviewMetadata;->resolve(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String;)Lorg/json/JSONObject;
  0016 move-result-object v7
  0018 return-object v7
.end method

.method resolve(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 const/4 v7, 0
  0002 move-object v0, v8
  0004 move-object v1, v9
  0006 move-object v2, v10
  0008 move-object v3, v11
  000a move-object v4, v12
  000c move-object v5, v13
  000e move-object v6, v14
  0010 invoke-static/range v0 ... v7, Lcom/personal/aihub/PreviewMetadata;->resolve(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String; Lorg/json/JSONArray;)Lorg/json/JSONObject;
  0016 move-result-object v8
  0018 return-object v8
.end method

.method resolve(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String; Lorg/json/JSONArray;)Lorg/json/JSONObject;
  0000 const-wide/16 v8, 0
  0004 move-object v0, v10
  0006 move-object v1, v11
  0008 move-object v2, v12
  000a move-object v3, v13
  000c move-object v4, v14
  000e move-object v5, v15
  0010 move-object/from16 v6, v16
  0014 move-object/from16 v7, v17
  0018 invoke-static/range v0 ... v9, Lcom/personal/aihub/PreviewMetadata;->resolve(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String; Lorg/json/JSONArray; J)Lorg/json/JSONObject;
  001e move-result-object v0
  0020 return-object v0
.end method

.method resolve(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String; Lorg/json/JSONArray; J)Lorg/json/JSONObject;
  0000 move-object/from16 v0, v23
  0004 move-wide/from16 v1, v29
  0008 invoke-static/range v28, Lcom/personal/aihub/PreviewMetadata;->sparkingEffects(Ljava/lang/Object;)Lorg/json/JSONArray;
  000e move-result-object v3
  0010 invoke-static/range v26, Lcom/personal/aihub/PreviewEffectPacks;->normalize(Ljava/lang/Object;)Lorg/json/JSONArray;
  0016 move-result-object v4
  0018 invoke-static v4, v3, Lcom/personal/aihub/PreviewMetadata;->validateEffectSources(Lorg/json/JSONArray; Lorg/json/JSONArray;)V
  001e new-instance v5, Ljava/io/File;
  0022 invoke-virtual/range v21, Landroid/content/Context;->getFilesDir()Ljava/io/File;
  0028 move-result-object v6
  002a const-string v7, "forge"
  002e invoke-direct v5, v6, v7, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0034 invoke-static/range v27, Lcom/personal/aihub/PreviewMetadata;->normalizeSource(Ljava/lang/String;)Ljava/lang/String;
  003a move-result-object v6
  003c invoke-static v5, v6, v1, v2, Lcom/personal/aihub/PreviewMetadata;->databaseFile(Ljava/io/File; Ljava/lang/String; J)Ljava/io/File;
  0042 move-result-object v7
  0044 invoke-virtual v3, Lorg/json/JSONArray;->length()I
  004a move-result v8
  004c const/4 v9, 0
  004e if-nez v8, +004h
  0052 move-object v1, v9
  0054 goto +7h
  0056 const-string v8, "sparking"
  005a invoke-static v5, v8, v1, v2, Lcom/personal/aihub/PreviewMetadata;->databaseFile(Ljava/io/File; Ljava/lang/String; J)Ljava/io/File;
  0060 move-result-object v1
  0062 invoke-virtual/range v21, Landroid/content/Context;->getAssets()Landroid/content/res/AssetManager;
  0068 move-result-object v2
  006a const-string v8, "ui/data/preview-metadata-rules.json"
  006e invoke-virtual v2, v8, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;
  0074 move-result-object v2
  0076 new-instance v8, Ljava/io/ByteArrayOutputStream;
  007a invoke-direct v8, Ljava/io/ByteArrayOutputStream;-><init>()V
  0080 const/16 v10, 8192
  0084 new-array v10, v10, [B
  0088 invoke-virtual v2, v10, Ljava/io/InputStream;->read([B)I
  008e move-result v11
  0090 const/4 v12, -1
  0092 const/4 v13, 0
  0094 const/high16 v14, 1048576
  0098 if-eq v11, v12, +015h
  009c invoke-virtual v8, Ljava/io/ByteArrayOutputStream;->size()I
  00a2 move-result v12
  00a4 add-int/2addr v12, v11
  00a6 if-gt v12, v14, +006h
  00aa invoke-virtual v8, v10, v13, v11, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  00b0 goto -14h
  00b2 new-instance v0, Ljava/io/IOException;
  00b6 const-string v1, "Preview metadata rules exceed the limit"
  00ba invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00c0 throw v0
  00c2 new-instance v10, Lorg/json/JSONObject;
  00c6 const-string v11, "UTF-8"
  00ca invoke-virtual v8, v11, Ljava/io/ByteArrayOutputStream;->toString(Ljava/lang/String;)Ljava/lang/String;
  00d0 move-result-object v11
  00d2 invoke-direct v10, v11, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  00d8 invoke-virtual v8, Ljava/io/ByteArrayOutputStream;->close()V
  00de if-eqz v2, +005h
  00e2 invoke-virtual v2, Ljava/io/InputStream;->close()V
  00e8 new-instance v2, Ljava/util/HashMap;
  00ec invoke-direct v2, Ljava/util/HashMap;-><init>()V
  00f2 invoke-virtual v4, Lorg/json/JSONArray;->length()I
  00f8 move-result v8
  00fa if-ge v13, v8, +016h
  00fe invoke-virtual v4, v13, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  0104 move-result-object v8
  0106 const-string v11, "id"
  010a invoke-virtual v8, v11, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0110 move-result-wide v11
  0112 invoke-static v11, v12, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  0118 move-result-object v11
  011a invoke-interface v2, v11, v8, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0120 add-int/lit8 v13, v13, 1
  0124 goto -19h
  0126 new-instance v8, Lcom/personal/aihub/PreviewMetadata$1;
  012a invoke-direct v8, v7, Lcom/personal/aihub/PreviewMetadata$1;-><init>(Ljava/io/File;)V
  0130 new-instance v7, Lcom/personal/aihub/PreviewMetadata$2;
  0134 invoke-direct v7, v1, Lcom/personal/aihub/PreviewMetadata$2;-><init>(Ljava/io/File;)V
  013a new-instance v1, Lcom/personal/aihub/GameMetadata;
  013e new-instance v11, Ljava/io/File;
  0142 const-string v12, "assets"
  0146 invoke-direct v11, v5, v12, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  014c invoke-static v8, v7, v4, v3, Lcom/personal/aihub/PreviewMetadata;->metadataQuery(Lcom/personal/aihub/GameMetadata$Query; Lcom/personal/aihub/GameMetadata$Query; Lorg/json/JSONArray; Lorg/json/JSONArray;)Lcom/personal/aihub/GameMetadata$Query;
  0152 move-result-object v17
  0154 move-object v15, v1
  0156 move-object/from16 v16, v11
  015a move-object/from16 v18, v10
  015e move-object/from16 v19, v24
  0162 move-object/from16 v20, v25
  0166 invoke-direct/range v15 ... v20, Lcom/personal/aihub/GameMetadata;-><init>(Ljava/io/File; Lcom/personal/aihub/GameMetadata$Query; Lorg/json/JSONObject; Ljava/lang/String; Lorg/json/JSONArray;)V
  016c invoke-virtual v1, v0, Lcom/personal/aihub/GameMetadata;->resolve(Ljava/lang/String;)Lorg/json/JSONObject;
  0172 move-result-object v1
  0174 const-string v4, "/api/effect-pack/([1-9][0-9]*)(?:\?enemy=1)?$"
  0178 invoke-static v4, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;)Ljava/util/regex/Pattern;
  017e move-result-object v4
  0180 invoke-virtual v4, v0, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  0186 move-result-object v4
  0188 invoke-virtual v4, Ljava/util/regex/Matcher;->find()Z
  018e move-result v5
  0190 if-eqz v5, +020h
  0194 const/4 v5, 1
  0196 invoke-virtual v4, v5, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  019c move-result-object v4
  019e invoke-static v4, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  01a4 move-result-wide v4
  01a6 invoke-static v4, v5, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  01ac move-result-object v4
  01ae invoke-interface v2, v4, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z
  01b4 move-result v2
  01b6 if-eqz v2, +00dh
  01ba if-eqz v1, +003h
  01be return-object v1
  01c0 new-instance v0, Ljava/io/IOException;
  01c4 const-string v1, "Your edited movie is missing. Reopen or reattach it."
  01c8 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01ce throw v0
  01d0 invoke-static v6, v0, v3, Lcom/personal/aihub/PreviewMetadata;->localOnly(Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray;)Z
  01d6 move-result v2
  01d8 if-eqz v2, +00dh
  01dc if-eqz v1, +003h
  01e0 return-object v1
  01e2 new-instance v0, Ljava/io/IOException;
  01e6 const-string v1, "This Sparking preview needs its matching imported character/effect resources. Download the selected unit's resources from Library; Eclipse metadata was not substituted."
  01ea invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01f0 throw v0
  01f2 new-instance v2, Lorg/json/JSONObject;
  01f6 move-object/from16 v3, v22
  01fa invoke-virtual v3, v0, v14, Lcom/personal/aihub/PreviewCache;->text(Ljava/lang/String; I)Ljava/lang/String;
  0200 move-result-object v0
  0202 invoke-direct v2, v0, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0208 move-object v9, v2
  020a goto +4h
  020c move-exception v0
  020e if-eqz v1, +007h
  0212 invoke-static v1, v9, Lcom/personal/aihub/GameMetadata;->merge(Lorg/json/JSONObject; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0218 move-result-object v0
  021a return-object v0
  021c throw v0
  021e move-exception v0
  0220 move-object v1, v0
  0222 invoke-virtual v8, Ljava/io/ByteArrayOutputStream;->close()V
  0228 goto +6h
  022a move-exception v0
  022c move-object v3, v0
  022e invoke-virtual v1, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0234 throw v1
  0236 move-exception v0
  0238 move-object v1, v0
  023a if-eqz v2, +00bh
  023e invoke-virtual v2, Ljava/io/InputStream;->close()V
  0244 goto +6h
  0246 move-exception v0
  0248 move-object v2, v0
  024a invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0250 throw v1
.end method

.method route(Ljava/lang/String;)Z
  0000 const-string v0, "/api/(card|effect-pack)/[1-9][0-9]*(\?enemy=1)?"
  0004 invoke-virtual v1, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  000a move-result v1
  000c return v1
.end method

.method row(Ljava/io/File; Ljava/lang/String; J)Lorg/json/JSONObject;
  0000 const-string v0, ""
  0004 invoke-static v1, v0, Lcom/personal/aihub/PreviewMetadata;->databaseFile(Ljava/io/File; Ljava/lang/String;)Ljava/io/File;
  000a move-result-object v1
  000c invoke-static v1, v2, v3, v4, Lcom/personal/aihub/PreviewMetadata;->rowFromFile(Ljava/io/File; Ljava/lang/String; J)Lorg/json/JSONObject;
  0012 move-result-object v1
  0014 return-object v1
.end method

.method rowFromFile(Ljava/io/File; Ljava/lang/String; J)Lorg/json/JSONObject;
  0000 const-string v0, "SELECT * FROM ""
  0004 const-wide/16 v1, 1
  0008 cmp-long v1, v6, v1
  000c if-ltz v1, +0b1h
  0010 const-string v1, "characters"
  0014 const-string v2, "effect_packs"
  0018 const-string v3, "cards"
  001c filled-new-array v3, v1, v2, [Ljava/lang/String;
  0022 move-result-object v1
  0024 invoke-static v1, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  002a move-result-object v1
  002c invoke-interface v1, v5, Ljava/util/List;->contains(Ljava/lang/Object;)Z
  0032 move-result v1
  0034 if-eqz v1, +09dh
  0038 invoke-virtual v4, Ljava/io/File;->isFile()Z
  003e move-result v1
  0040 const/4 v2, 0
  0042 if-nez v1, +003h
  0046 return-object v2
  0048 invoke-virtual v4, Ljava/io/File;->getPath()Ljava/lang/String;
  004e move-result-object v4
  0050 const/4 v1, 1
  0052 invoke-static v4, v2, v1, Landroid/database/sqlite/SQLiteDatabase;->openDatabase(Ljava/lang/String; Landroid/database/sqlite/SQLiteDatabase$CursorFactory; I)Landroid/database/sqlite/SQLiteDatabase;
  0058 move-result-object v4
  005a new-instance v3, Ljava/lang/StringBuilder;
  005e invoke-direct v3, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0064 invoke-virtual v3, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  006a const-string v5, "" WHERE id=? LIMIT 1"
  006e invoke-virtual v3, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0074 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  007a move-result-object v5
  007c invoke-static v6, v7, Ljava/lang/Long;->toString(J)Ljava/lang/String;
  0082 move-result-object v6
  0084 filled-new-array v6, [Ljava/lang/String;
  008a move-result-object v6
  008c invoke-virtual v4, v5, v6, Landroid/database/sqlite/SQLiteDatabase;->rawQuery(Ljava/lang/String; [Ljava/lang/String;)Landroid/database/Cursor;
  0092 move-result-object v5
  0094 invoke-interface v5, Landroid/database/Cursor;->moveToFirst()Z
  009a move-result v6
  009c if-nez v6, +00dh
  00a0 if-eqz v5, +005h
  00a4 invoke-interface v5, Landroid/database/Cursor;->close()V
  00aa if-eqz v4, +005h
  00ae invoke-virtual v4, Landroid/database/sqlite/SQLiteDatabase;->close()V
  00b4 return-object v2
  00b6 new-instance v6, Lorg/json/JSONObject;
  00ba invoke-direct v6, Lorg/json/JSONObject;-><init>()V
  00c0 invoke-interface v5, Landroid/database/Cursor;->getColumnNames()[Ljava/lang/String;
  00c6 move-result-object v7
  00c8 const/4 v0, 0
  00ca array-length v2, v7
  00cc if-ge v0, v2, +02eh
  00d0 invoke-interface v5, v0, Landroid/database/Cursor;->getType(I)I
  00d6 move-result v2
  00d8 if-eqz v2, +01eh
  00dc if-eq v2, v1, +013h
  00e0 const/4 v3, 2
  00e2 if-eq v2, v3, +007h
  00e6 invoke-interface v5, v0, Landroid/database/Cursor;->getString(I)Ljava/lang/String;
  00ec move-result-object v2
  00ee goto +15h
  00f0 invoke-interface v5, v0, Landroid/database/Cursor;->getDouble(I)D
  00f6 move-result-wide v2
  00f8 invoke-static v2, v3, Ljava/lang/Double;->valueOf(D)Ljava/lang/Double;
  00fe move-result-object v2
  0100 goto +ch
  0102 invoke-interface v5, v0, Landroid/database/Cursor;->getLong(I)J
  0108 move-result-wide v2
  010a invoke-static v2, v3, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  0110 move-result-object v2
  0112 goto +3h
  0114 sget-object v2, Lorg/json/JSONObject;->NULL Ljava/lang/Object;
  0118 aget-object v3, v7, v0
  011c invoke-virtual v6, v3, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0122 add-int/lit8 v0, v0, 1
  0126 goto -2eh
  0128 if-eqz v5, +005h
  012c invoke-interface v5, Landroid/database/Cursor;->close()V
  0132 if-eqz v4, +005h
  0136 invoke-virtual v4, Landroid/database/sqlite/SQLiteDatabase;->close()V
  013c return-object v6
  013e move-exception v6
  0140 if-eqz v5, +00ah
  0144 invoke-interface v5, Landroid/database/Cursor;->close()V
  014a goto +5h
  014c move-exception v5
  014e invoke-virtual v6, v5, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0154 throw v6
  0156 move-exception v5
  0158 if-eqz v4, +00ah
  015c invoke-virtual v4, Landroid/database/sqlite/SQLiteDatabase;->close()V
  0162 goto +5h
  0164 move-exception v4
  0166 invoke-virtual v5, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  016c throw v5
  016e new-instance v4, Ljava/io/IOException;
  0172 const-string v5, "Unsupported preview metadata query"
  0176 invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  017c throw v4
.end method

.method sparkingEffects(Ljava/lang/Object;)Lorg/json/JSONArray;
  0000 if-nez v11, +008h
  0004 new-instance v11, Lorg/json/JSONArray;
  0008 invoke-direct v11, Lorg/json/JSONArray;-><init>()V
  000e return-object v11
  0010 instance-of v0, v11, Lorg/json/JSONArray;
  0014 const-string v1, "Choose valid Sparking animation effects."
  0018 if-eqz v0, +072h
  001c check-cast v11, Lorg/json/JSONArray;
  0020 new-instance v0, Lorg/json/JSONArray;
  0024 invoke-direct v0, Lorg/json/JSONArray;-><init>()V
  002a invoke-virtual v11, Lorg/json/JSONArray;->length()I
  0030 move-result v2
  0032 const/16 v3, 1024
  0036 if-gt v2, v3, +05bh
  003a new-instance v2, Ljava/util/HashSet;
  003e invoke-direct v2, Ljava/util/HashSet;-><init>()V
  0044 const/4 v3, 0
  0046 invoke-virtual v11, Lorg/json/JSONArray;->length()I
  004c move-result v4
  004e if-ge v3, v4, +04eh
  0052 invoke-virtual v11, v3, Lorg/json/JSONArray;->opt(I)Ljava/lang/Object;
  0058 move-result-object v4
  005a instance-of v5, v4, Ljava/lang/Number;
  005e if-eqz v5, +040h
  0062 check-cast v4, Ljava/lang/Number;
  0066 invoke-virtual v4, Ljava/lang/Number;->longValue()J
  006c move-result-wide v5
  006e invoke-virtual v4, Ljava/lang/Number;->doubleValue()D
  0074 move-result-wide v7
  0076 invoke-static v7, v8, Ljava/lang/Double;->isFinite(D)Z
  007c move-result v7
  007e if-eqz v7, +028h
  0082 invoke-virtual v4, Ljava/lang/Number;->doubleValue()D
  0088 move-result-wide v7
  008a long-to-double v9, v5
  008c cmpl-double v4, v7, v9
  0090 if-nez v4, +01fh
  0094 const-wide/16 v7, 1
  0098 cmp-long v4, v5, v7
  009c if-ltz v4, +019h
  00a0 const-wide/32 v7, 2147483647
  00a6 cmp-long v4, v5, v7
  00aa if-gtz v4, +012h
  00ae invoke-static v5, v6, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  00b4 move-result-object v4
  00b6 invoke-interface v2, v4, Ljava/util/Set;->add(Ljava/lang/Object;)Z
  00bc move-result v4
  00be if-eqz v4, +008h
  00c2 invoke-virtual v0, v5, v6, Lorg/json/JSONArray;->put(J)Lorg/json/JSONArray;
  00c8 add-int/lit8 v3, v3, 1
  00cc goto -43h
  00ce new-instance v11, Ljava/io/IOException;
  00d2 const-string v0, "Choose unique valid Sparking animation effects."
  00d6 invoke-direct v11, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00dc throw v11
  00de new-instance v11, Ljava/io/IOException;
  00e2 invoke-direct v11, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00e8 throw v11
  00ea return-object v0
  00ec new-instance v11, Ljava/io/IOException;
  00f0 const-string v0, "Choose up to 1024 Sparking animation effects."
  00f4 invoke-direct v11, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00fa throw v11
  00fc new-instance v11, Ljava/io/IOException;
  0100 invoke-direct v11, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0106 throw v11
.end method

.method validateEffectSources(Lorg/json/JSONArray; Lorg/json/JSONArray;)V
  0000 new-instance v0, Ljava/util/HashSet;
  0004 invoke-direct v0, Ljava/util/HashSet;-><init>()V
  000a const/4 v1, 0
  000c move v2, v1
  000e invoke-virtual v6, Lorg/json/JSONArray;->length()I
  0014 move-result v3
  0016 if-ge v2, v3, +010h
  001a invoke-virtual v6, v2, Lorg/json/JSONArray;->getLong(I)J
  0020 move-result-wide v3
  0022 invoke-static v3, v4, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  0028 move-result-object v3
  002a invoke-interface v0, v3, Ljava/util/Set;->add(Ljava/lang/Object;)Z
  0030 add-int/lit8 v2, v2, 1
  0034 goto -13h
  0036 invoke-virtual v5, Lorg/json/JSONArray;->length()I
  003c move-result v6
  003e if-ge v1, v6, +021h
  0042 invoke-virtual v5, v1, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  0048 move-result-object v6
  004a const-string v2, "id"
  004e invoke-virtual v6, v2, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0054 move-result-wide v2
  0056 invoke-static v2, v3, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  005c move-result-object v6
  005e invoke-interface v0, v6, Ljava/util/Set;->contains(Ljava/lang/Object;)Z
  0064 move-result v6
  0066 if-nez v6, +005h
  006a add-int/lit8 v1, v1, 1
  006e goto -1ch
  0070 new-instance v5, Ljava/io/IOException;
  0074 const-string v6, "An edited movie and a Sparking effect cannot share the same preview effect ID."
  0078 invoke-direct v5, v6, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  007e throw v5
  0080 return-void 
.end method