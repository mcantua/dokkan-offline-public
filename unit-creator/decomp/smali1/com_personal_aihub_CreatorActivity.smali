.class Lcom/personal/aihub/CreatorActivity;
.super Landroid/app/Activity;
.field DATABASE_WRITES Ljava/lang/Object;
.field ORIGIN Ljava/lang/String;
.field PROJECT_WRITES Ljava/lang/Object;
.field assets Ljava/io/File;
.field db Landroid/database/sqlite/SQLiteDatabase;
.field importProgress Lorg/json/JSONObject;
.field movieUploads Lcom/personal/aihub/MovieStorage;
.field pendingExport Lorg/json/JSONObject;
.field pendingId I
.field pendingMethod Ljava/lang/String;
.field projects Ljava/io/File;
.field root Ljava/io/File;
.field schema Lorg/json/JSONObject;
.field sparkingDb Landroid/database/sqlite/SQLiteDatabase;
.field sparkingSchema Lorg/json/JSONObject;
.field startup Lcom/personal/aihub/WebViewStartup;
.field web Landroid/webkit/WebView;
.field worker Ljava/util/concurrent/ExecutorService;

.method <clinit>()V
  0000 new-instance v0, Ljava/lang/Object;
  0004 invoke-direct v0, Ljava/lang/Object;-><init>()V
  000a sput-object v0, Lcom/personal/aihub/CreatorActivity;->DATABASE_WRITES Ljava/lang/Object;
  000e new-instance v0, Ljava/lang/Object;
  0012 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0018 sput-object v0, Lcom/personal/aihub/CreatorActivity;->PROJECT_WRITES Ljava/lang/Object;
  001c return-void 
.end method

.method <init>()V
  0000 invoke-direct v1, Landroid/app/Activity;-><init>()V
  0006 invoke-static Ljava/util/concurrent/Executors;->newSingleThreadExecutor()Ljava/util/concurrent/ExecutorService;
  000c move-result-object v0
  000e iput-object v0, v1, Lcom/personal/aihub/CreatorActivity;->worker Ljava/util/concurrent/ExecutorService;
  0012 const/4 v0, -1
  0014 iput v0, v1, Lcom/personal/aihub/CreatorActivity;->pendingId I
  0018 const-string v0, ""
  001c iput-object v0, v1, Lcom/personal/aihub/CreatorActivity;->pendingMethod Ljava/lang/String;
  0020 new-instance v0, Lorg/json/JSONObject;
  0024 invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  002a iput-object v0, v1, Lcom/personal/aihub/CreatorActivity;->importProgress Lorg/json/JSONObject;
  002e return-void 
.end method

.method access$000(Lcom/personal/aihub/CreatorActivity;)Lcom/personal/aihub/WebViewStartup;
  0000 iget-object v0, v0, Lcom/personal/aihub/CreatorActivity;->startup Lcom/personal/aihub/WebViewStartup;
  0004 return-object v0
.end method

.method access$102(Lcom/personal/aihub/CreatorActivity; Landroid/webkit/WebView;)Landroid/webkit/WebView;
  0000 iput-object v1, v0, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  0004 return-object v1
.end method

.method access$200(Lcom/personal/aihub/CreatorActivity;)Lorg/json/JSONObject;
  0000 iget-object v0, v0, Lcom/personal/aihub/CreatorActivity;->importProgress Lorg/json/JSONObject;
  0004 return-object v0
.end method

.method access$300(Lcom/personal/aihub/CreatorActivity;)Ljava/util/concurrent/ExecutorService;
  0000 iget-object v0, v0, Lcom/personal/aihub/CreatorActivity;->worker Ljava/util/concurrent/ExecutorService;
  0004 return-object v0
.end method

.method access$400(Ljava/lang/String;)I
  0000 invoke-static v0, Lcom/personal/aihub/CreatorActivity;->apkDatabaseRank(Ljava/lang/String;)I
  0006 move-result v0
  0008 return v0
.end method

.method animationCatalog(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 move-object/from16 v1, v18
  0004 move-object/from16 v0, v19
  0008 invoke-direct/range v18, Lcom/personal/aihub/CreatorActivity;->ensureDb()V
  000e const-string v2, "sourceDatabase"
  0012 invoke-virtual v0, v2, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0018 move-result-object v3
  001a const-string v4, "sparking"
  001e invoke-virtual v4, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0024 move-result v3
  0026 if-eqz v3, +005h
  002a invoke-direct/range v18, Lcom/personal/aihub/CreatorActivity;->ensureSparkingDb()V
  0030 if-eqz v3, +005h
  0034 iget-object v5, v1, Lcom/personal/aihub/CreatorActivity;->sparkingDb Landroid/database/sqlite/SQLiteDatabase;
  0038 goto +3h
  003a iget-object v5, v1, Lcom/personal/aihub/CreatorActivity;->db Landroid/database/sqlite/SQLiteDatabase;
  003e if-eqz v3, +005h
  0042 iget-object v6, v1, Lcom/personal/aihub/CreatorActivity;->sparkingSchema Lorg/json/JSONObject;
  0046 goto +3h
  0048 iget-object v6, v1, Lcom/personal/aihub/CreatorActivity;->schema Lorg/json/JSONObject;
  004c new-instance v7, Lorg/json/JSONArray;
  0050 const-string v8, "ui/data/animation-queries.json"
  0054 const v9, 100000
  005a invoke-direct v1, v8, v9, Lcom/personal/aihub/CreatorActivity;->readTextAsset(Ljava/lang/String; I)Ljava/lang/String;
  0060 move-result-object v8
  0062 invoke-direct v7, v8, Lorg/json/JSONArray;-><init>(Ljava/lang/String;)V
  0068 new-instance v8, Ljava/util/ArrayList;
  006c invoke-direct v8, Ljava/util/ArrayList;-><init>()V
  0072 const/4 v10, 0
  0074 move v11, v10
  0076 invoke-virtual v7, Lorg/json/JSONArray;->length()I
  007c move-result v12
  007e if-lt v11, v12, +14eh
  0082 invoke-virtual v8, Ljava/util/ArrayList;->isEmpty()Z
  0088 move-result v6
  008a const-string v7, "more"
  008e const-string v11, "items"
  0092 if-eqz v6, +015h
  0096 new-instance v0, Lorg/json/JSONObject;
  009a invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  00a0 new-instance v2, Lorg/json/JSONArray;
  00a4 invoke-direct v2, Lorg/json/JSONArray;-><init>()V
  00aa invoke-virtual v0, v11, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00b0 move-result-object v0
  00b2 invoke-virtual v0, v7, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  00b8 move-result-object v0
  00ba return-object v0
  00bc new-instance v6, Ljava/util/ArrayList;
  00c0 invoke-direct v6, Ljava/util/ArrayList;-><init>()V
  00c6 new-instance v12, Ljava/util/ArrayList;
  00ca invoke-direct v12, Ljava/util/ArrayList;-><init>()V
  00d0 const-string v14, "search"
  00d4 invoke-virtual v0, v14, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  00da move-result-object v14
  00dc const-string v15, "kind"
  00e0 const-string v13, "all"
  00e4 invoke-virtual v0, v15, v13, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  00ea move-result-object v15
  00ec invoke-virtual v14, Ljava/lang/String;->length()I
  00f2 move-result v9
  00f4 const/16 v1, 100
  00f8 if-le v9, v1, +006h
  00fc invoke-virtual v14, v10, v1, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  0102 move-result-object v14
  0104 invoke-virtual v14, Ljava/lang/String;->isEmpty()Z
  010a move-result v1
  010c if-nez v1, +02dh
  0110 const-string v1, "(unitName LIKE ? OR moveName LIKE ?)"
  0114 invoke-virtual v12, v1, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  011a new-instance v1, Ljava/lang/StringBuilder;
  011e const-string v9, "%"
  0122 invoke-direct v1, v9, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0128 invoke-virtual v1, v14, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  012e invoke-virtual v1, v9, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0134 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  013a move-result-object v1
  013c invoke-virtual v6, v1, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0142 new-instance v1, Ljava/lang/StringBuilder;
  0146 invoke-direct v1, v9, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  014c invoke-virtual v1, v14, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0152 invoke-virtual v1, v9, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0158 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  015e move-result-object v1
  0160 invoke-virtual v6, v1, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0166 invoke-virtual v15, v13, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  016c move-result v1
  016e if-nez v1, +00ah
  0172 const-string v1, "kind=?"
  0176 invoke-virtual v12, v1, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  017c invoke-virtual v6, v15, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0182 const-string v1, "unitId"
  0186 invoke-virtual v0, v1, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  018c move-result-wide v13
  018e const-wide/16 v16, 0
  0192 cmp-long v9, v13, v16
  0196 if-lez v9, +012h
  019a const-string v9, "unitId=?"
  019e invoke-virtual v12, v9, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  01a4 invoke-virtual v0, v1, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  01aa move-result-wide v13
  01ac invoke-static v13, v14, Ljava/lang/String;->valueOf(J)Ljava/lang/String;
  01b2 move-result-object v1
  01b4 invoke-virtual v6, v1, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  01ba const-string v1, "offset"
  01be invoke-virtual v0, v1, Lorg/json/JSONObject;->optInt(Ljava/lang/String;)I
  01c4 move-result v0
  01c6 const v9, 100000
  01cc invoke-static v9, v0, Ljava/lang/Math;->min(I I)I
  01d2 move-result v0
  01d4 invoke-static v10, v0, Ljava/lang/Math;->max(I I)I
  01da move-result v0
  01dc const-string v9, "13"
  01e0 invoke-virtual v6, v9, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  01e6 invoke-static v0, Ljava/lang/String;->valueOf(I)Ljava/lang/String;
  01ec move-result-object v9
  01ee invoke-virtual v6, v9, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  01f4 new-instance v9, Ljava/lang/StringBuilder;
  01f8 invoke-direct v9, Ljava/lang/StringBuilder;-><init>()V
  01fe const-string v13, "SELECT * FROM ("
  0202 invoke-virtual v9, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0208 const-string v13, " UNION ALL "
  020c invoke-static v13, v8, Ljava/lang/String;->join(Ljava/lang/CharSequence; Ljava/lang/Iterable;)Ljava/lang/String;
  0212 move-result-object v8
  0214 invoke-virtual v9, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  021a const-string v8, ")"
  021e invoke-virtual v9, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0224 invoke-virtual v12, Ljava/util/ArrayList;->isEmpty()Z
  022a move-result v8
  022c if-eqz v8, +005h
  0230 const-string v8, ""
  0234 goto +18h
  0236 new-instance v8, Ljava/lang/StringBuilder;
  023a invoke-direct v8, Ljava/lang/StringBuilder;-><init>()V
  0240 const-string v13, " WHERE "
  0244 invoke-virtual v8, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  024a const-string v13, " AND "
  024e invoke-static v13, v12, Ljava/lang/String;->join(Ljava/lang/CharSequence; Ljava/lang/Iterable;)Ljava/lang/String;
  0254 move-result-object v12
  0256 invoke-virtual v8, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  025c invoke-virtual v8, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0262 move-result-object v8
  0264 invoke-virtual v9, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  026a const-string v8, " ORDER BY unitId=0, unitName, moveName, unitId, key LIMIT ? OFFSET ?"
  026e invoke-virtual v9, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0274 invoke-virtual v9, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  027a move-result-object v8
  027c new-array v9, v10, [Ljava/lang/String;
  0280 invoke-virtual v6, v9, Ljava/util/ArrayList;->toArray([Ljava/lang/Object;)[Ljava/lang/Object;
  0286 move-result-object v6
  0288 check-cast v6, [Ljava/lang/String;
  028c invoke-virtual v5, v8, v6, Landroid/database/sqlite/SQLiteDatabase;->rawQuery(Ljava/lang/String; [Ljava/lang/String;)Landroid/database/Cursor;
  0292 move-result-object v5
  0294 invoke-static v5, Lcom/personal/aihub/CreatorActivity;->rows(Landroid/database/Cursor;)Lorg/json/JSONArray;
  029a move-result-object v6
  029c if-eqz v3, +013h
  02a0 move v3, v10
  02a2 invoke-virtual v6, Lorg/json/JSONArray;->length()I
  02a8 move-result v8
  02aa if-ge v3, v8, +00ch
  02ae invoke-virtual v6, v3, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  02b4 move-result-object v8
  02b6 invoke-virtual v8, v2, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02bc add-int/lit8 v3, v3, 1
  02c0 goto -fh
  02c2 if-eqz v5, +005h
  02c6 invoke-interface v5, Landroid/database/Cursor;->close()V
  02cc invoke-virtual v6, Lorg/json/JSONArray;->length()I
  02d2 move-result v2
  02d4 const/16 v3, 12
  02d8 if-le v2, v3, +003h
  02dc const/4 v10, 1
  02de if-eqz v10, +005h
  02e2 invoke-virtual v6, v3, Lorg/json/JSONArray;->remove(I)Ljava/lang/Object;
  02e8 new-instance v2, Lorg/json/JSONObject;
  02ec invoke-direct v2, Lorg/json/JSONObject;-><init>()V
  02f2 invoke-virtual v2, v11, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02f8 move-result-object v2
  02fa invoke-virtual v2, v7, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0300 move-result-object v2
  0302 invoke-virtual v2, v1, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0308 move-result-object v0
  030a return-object v0
  030c move-exception v0
  030e if-eqz v5, +005h
  0312 invoke-interface v5, Landroid/database/Cursor;->close()V
  0318 throw v0
  031a invoke-virtual v7, v11, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  0320 move-result-object v1
  0322 const-string v12, "tables"
  0326 invoke-virtual v1, v12, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  032c move-result-object v12
  032e move v14, v10
  0330 const/4 v13, 1
  0332 invoke-virtual v12, Lorg/json/JSONArray;->length()I
  0338 move-result v15
  033a if-ge v14, v15, +010h
  033e invoke-virtual v12, v14, Lorg/json/JSONArray;->getString(I)Ljava/lang/String;
  0344 move-result-object v15
  0346 invoke-virtual v6, v15, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  034c move-result v15
  034e if-nez v15, +003h
  0352 move v13, v10
  0354 add-int/lit8 v14, v14, 1
  0358 goto -13h
  035a if-eqz v13, +00bh
  035e const-string v12, "sql"
  0362 invoke-virtual v1, v12, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0368 move-result-object v1
  036a invoke-virtual v8, v1, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0370 add-int/lit8 v11, v11, 1
  0374 move-object/from16 v1, v18
  0378 goto/16 -181h
.end method

.method animationFiles(Z)Lorg/json/JSONArray;
  0000 new-instance v0, Ljava/io/File;
  0004 iget-object v1, v6, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0008 const-string v2, "animation-files.json"
  000c invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0012 new-instance v1, Ljava/util/TreeSet;
  0016 invoke-direct v1, Ljava/util/TreeSet;-><init>()V
  001c new-instance v2, Lcom/personal/aihub/PreviewCache;
  0020 iget-object v3, v6, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0024 invoke-direct v2, v3, Lcom/personal/aihub/PreviewCache;-><init>(Ljava/io/File;)V
  002a invoke-virtual v2, Lcom/personal/aihub/PreviewCache;->offline()Z
  0030 move-result v2
  0032 invoke-virtual v0, Ljava/io/File;->exists()Z
  0038 move-result v3
  003a const/high16 v4, 2097152
  003e if-eqz v3, +012h
  0042 if-eqz v7, +004h
  0046 if-eqz v2, +00eh
  004a new-instance v3, Lorg/json/JSONArray;
  004e invoke-static v0, v4, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  0054 move-result-object v5
  0056 invoke-direct v3, v5, Lorg/json/JSONArray;-><init>(Ljava/lang/String;)V
  005c invoke-static v1, v3, Lcom/personal/aihub/PreviewScripts;->add(Ljava/util/Set; Lorg/json/JSONArray;)V
  0062 const-string v3, "scripts"
  0066 if-eqz v7, +016h
  006a if-nez v2, +014h
  006e new-instance v7, Lorg/json/JSONObject;
  0072 const-string v2, "https://dokkan-eclipse.com/api/scripts"
  0076 invoke-direct v6, v2, v4, Lcom/personal/aihub/CreatorActivity;->fetchText(Ljava/lang/String; I)Ljava/lang/String;
  007c move-result-object v2
  007e invoke-direct v7, v2, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0084 invoke-virtual v7, v3, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  008a move-result-object v7
  008c invoke-static v1, v7, Lcom/personal/aihub/PreviewScripts;->add(Ljava/util/Set; Lorg/json/JSONArray;)V
  0092 invoke-virtual v1, Ljava/util/TreeSet;->isEmpty()Z
  0098 move-result v7
  009a if-eqz v7, +014h
  009e invoke-virtual v0, Ljava/io/File;->exists()Z
  00a4 move-result v7
  00a6 if-eqz v7, +00eh
  00aa new-instance v7, Lorg/json/JSONArray;
  00ae invoke-static v0, v4, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  00b4 move-result-object v2
  00b6 invoke-direct v7, v2, Lorg/json/JSONArray;-><init>(Ljava/lang/String;)V
  00bc invoke-static v1, v7, Lcom/personal/aihub/PreviewScripts;->add(Ljava/util/Set; Lorg/json/JSONArray;)V
  00c2 invoke-virtual v1, Ljava/util/TreeSet;->isEmpty()Z
  00c8 move-result v7
  00ca if-eqz v7, +00eh
  00ce const/4 v7, 0
  00d0 invoke-static v6, v7, Lcom/personal/aihub/PreviewScripts;->listing(Landroid/content/Context; Ljava/io/File;)Lorg/json/JSONObject;
  00d6 move-result-object v7
  00d8 invoke-virtual v7, v3, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  00de move-result-object v7
  00e0 invoke-static v1, v7, Lcom/personal/aihub/PreviewScripts;->add(Ljava/util/Set; Lorg/json/JSONArray;)V
  00e6 new-instance v7, Lorg/json/JSONArray;
  00ea invoke-direct v7, Lorg/json/JSONArray;-><init>()V
  00f0 invoke-virtual v1, Ljava/util/TreeSet;->iterator()Ljava/util/Iterator;
  00f6 move-result-object v2
  00f8 invoke-interface v2, Ljava/util/Iterator;->hasNext()Z
  00fe move-result v3
  0100 if-eqz v3, +00ch
  0104 invoke-interface v2, Ljava/util/Iterator;->next()Ljava/lang/Object;
  010a move-result-object v3
  010c check-cast v3, Ljava/lang/String;
  0110 invoke-virtual v7, v3, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0116 goto -fh
  0118 invoke-virtual v7, Lorg/json/JSONArray;->toString()Ljava/lang/String;
  011e move-result-object v7
  0120 invoke-static v0, v7, Lcom/personal/aihub/CreatorActivity;->writeText(Ljava/io/File; Ljava/lang/String;)V
  0126 iget-object v7, v6, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  012a invoke-static v7, v1, Lcom/personal/aihub/PreviewScripts;->imported(Ljava/io/File; Ljava/util/Set;)V
  0130 new-instance v7, Lorg/json/JSONArray;
  0134 invoke-direct v7, Lorg/json/JSONArray;-><init>()V
  013a invoke-virtual v1, Ljava/util/TreeSet;->iterator()Ljava/util/Iterator;
  0140 move-result-object v0
  0142 invoke-interface v0, Ljava/util/Iterator;->hasNext()Z
  0148 move-result v1
  014a if-eqz v1, +00ch
  014e invoke-interface v0, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0154 move-result-object v1
  0156 check-cast v1, Ljava/lang/String;
  015a invoke-virtual v7, v1, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0160 goto -fh
  0162 return-object v7
.end method

.method animationSource(Ljava/lang/String;)Lorg/json/JSONObject;
  0000 const-string v0, ""
  0004 invoke-direct v1, v2, v0, Lcom/personal/aihub/CreatorActivity;->animationSource(Ljava/lang/String; Ljava/lang/String;)Lorg/json/JSONObject;
  000a move-result-object v2
  000c return-object v2
.end method

.method animationSource(Ljava/lang/String; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 const/4 v0, 0
  0002 invoke-direct v1, v2, v3, v0, Lcom/personal/aihub/CreatorActivity;->animationSource(Ljava/lang/String; Ljava/lang/String; Z)Lorg/json/JSONObject;
  0008 move-result-object v2
  000a return-object v2
.end method

.method animationSource(Ljava/lang/String; Ljava/lang/String; Z)Lorg/json/JSONObject;
  0000 invoke-static v11, Lcom/personal/aihub/CreatorActivity;->validAnimationPath(Ljava/lang/String;)Z
  0006 move-result v0
  0008 if-eqz v0, +108h
  000c const/high16 v0, 2097152
  0010 if-eqz v13, +004h
  0014 const/4 v12, 0
  0016 goto +1ah
  0018 new-instance v13, Lcom/personal/aihub/GameAssets;
  001c iget-object v1, v10, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  0020 invoke-direct v13, v1, v12, Lcom/personal/aihub/GameAssets;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0026 new-instance v12, Ljava/lang/StringBuilder;
  002a const-string v1, "lua/"
  002e invoke-direct v12, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0034 invoke-virtual v12, v11, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  003a invoke-virtual v12, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0040 move-result-object v12
  0042 invoke-virtual v13, v12, v0, Lcom/personal/aihub/GameAssets;->read(Ljava/lang/String; I)[B
  0048 move-result-object v12
  004a const-string v13, "cached"
  004e const-string v1, "text"
  0052 const-string v2, "path"
  0056 const-string v3, "<"
  005a const/4 v4, 0
  005c if-eqz v12, +044h
  0060 new-instance v0, Ljava/lang/String;
  0064 sget-object v5, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0068 invoke-direct v0, v12, v5, Ljava/lang/String;-><init>([B Ljava/nio/charset/Charset;)V
  006e invoke-virtual v0, Ljava/lang/String;->trim()Ljava/lang/String;
  0074 move-result-object v12
  0076 invoke-virtual v12, Ljava/lang/String;->isEmpty()Z
  007c move-result v12
  007e if-nez v12, +02bh
  0082 invoke-virtual v0, Ljava/lang/String;->trim()Ljava/lang/String;
  0088 move-result-object v12
  008a invoke-virtual v12, v3, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0090 move-result v12
  0092 if-nez v12, +021h
  0096 invoke-virtual v0, v4, Ljava/lang/String;->indexOf(I)I
  009c move-result v12
  009e if-gez v12, +01bh
  00a2 new-instance v12, Lorg/json/JSONObject;
  00a6 invoke-direct v12, Lorg/json/JSONObject;-><init>()V
  00ac invoke-virtual v12, v2, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00b2 move-result-object v11
  00b4 invoke-virtual v11, v1, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00ba move-result-object v11
  00bc const/4 v12, 1
  00be invoke-virtual v11, v13, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  00c4 move-result-object v11
  00c6 const-string v13, "local"
  00ca invoke-virtual v11, v13, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  00d0 move-result-object v11
  00d2 return-object v11
  00d4 new-instance v11, Ljava/io/IOException;
  00d8 const-string v12, "Unreadable imported animation file"
  00dc invoke-direct v11, v12, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00e2 throw v11
  00e4 invoke-direct v10, Lcom/personal/aihub/CreatorActivity;->dataStore()Lcom/personal/aihub/GameDataStore;
  00ea move-result-object v12
  00ec invoke-virtual v12, Lcom/personal/aihub/GameDataStore;->meta()Lorg/json/JSONObject;
  00f2 move-result-object v12
  00f4 const-string v5, "sha256"
  00f8 const-string v6, "bundled"
  00fc invoke-virtual v12, v5, v6, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0102 move-result-object v5
  0104 const-string v6, "date"
  0108 invoke-virtual v12, v6, v5, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  010e move-result-object v12
  0110 const-string v5, "[^a-zA-Z0-9_-]"
  0114 const-string v6, ""
  0118 invoke-virtual v12, v5, v6, Ljava/lang/String;->replaceAll(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  011e move-result-object v12
  0120 invoke-virtual v12, Ljava/lang/String;->length()I
  0126 move-result v5
  0128 const/16 v6, 80
  012c if-le v5, v6, +006h
  0130 invoke-virtual v12, v4, v6, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  0136 move-result-object v12
  0138 new-instance v5, Ljava/io/File;
  013c new-instance v6, Ljava/io/File;
  0140 new-instance v7, Ljava/io/File;
  0144 iget-object v8, v10, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0148 const-string v9, "animation-sources"
  014c invoke-direct v7, v8, v9, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0152 invoke-direct v6, v7, v12, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0158 invoke-direct v5, v6, v11, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  015e invoke-virtual v5, Ljava/io/File;->exists()Z
  0164 move-result v12
  0166 if-eqz v12, +007h
  016a invoke-static v5, v0, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  0170 move-result-object v0
  0172 goto +13h
  0174 new-instance v6, Ljava/lang/StringBuilder;
  0178 const-string v7, "https://dokkan-eclipse.com/cdn/uncompressed/lua/"
  017c invoke-direct v6, v7, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0182 invoke-virtual v6, v11, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0188 invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  018e move-result-object v6
  0190 invoke-direct v10, v6, v0, Lcom/personal/aihub/CreatorActivity;->fetchText(Ljava/lang/String; I)Ljava/lang/String;
  0196 move-result-object v0
  0198 invoke-virtual v0, Ljava/lang/String;->trim()Ljava/lang/String;
  019e move-result-object v6
  01a0 invoke-virtual v6, Ljava/lang/String;->isEmpty()Z
  01a6 move-result v6
  01a8 if-nez v6, +030h
  01ac invoke-virtual v0, Ljava/lang/String;->trim()Ljava/lang/String;
  01b2 move-result-object v6
  01b4 invoke-virtual v6, v3, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  01ba move-result v3
  01bc if-nez v3, +026h
  01c0 invoke-virtual v0, v4, Ljava/lang/String;->indexOf(I)I
  01c6 move-result v3
  01c8 if-gez v3, +020h
  01cc if-nez v12, +00ch
  01d0 invoke-virtual v5, Ljava/io/File;->getParentFile()Ljava/io/File;
  01d6 move-result-object v3
  01d8 invoke-virtual v3, Ljava/io/File;->mkdirs()Z
  01de invoke-static v5, v0, Lcom/personal/aihub/CreatorActivity;->writeText(Ljava/io/File; Ljava/lang/String;)V
  01e4 new-instance v3, Lorg/json/JSONObject;
  01e8 invoke-direct v3, Lorg/json/JSONObject;-><init>()V
  01ee invoke-virtual v3, v2, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01f4 move-result-object v11
  01f6 invoke-virtual v11, v1, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01fc move-result-object v11
  01fe invoke-virtual v11, v13, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0204 move-result-object v11
  0206 return-object v11
  0208 new-instance v11, Ljava/io/IOException;
  020c const-string v12, "Unreadable animation file"
  0210 invoke-direct v11, v12, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0216 throw v11
  0218 new-instance v11, Ljava/io/IOException;
  021c const-string v12, "Choose an animation from the browser"
  0220 invoke-direct v11, v12, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0226 throw v11
.end method

.method animationVisuals(J)Lorg/json/JSONObject;
  0000 const-wide/16 v0, 1
  0004 cmp-long v0, v12, v0
  0008 if-ltz v0, +126h
  000c new-instance v0, Lcom/personal/aihub/PreviewCache;
  0010 iget-object v1, v11, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0014 invoke-direct v0, v1, Lcom/personal/aihub/PreviewCache;-><init>(Ljava/io/File;)V
  001a new-instance v1, Ljava/lang/StringBuilder;
  001e const-string v2, "https://dokkan-eclipse.com/api/card/"
  0022 invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0028 invoke-virtual v1, v12, v13, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  002e invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0034 move-result-object v12
  0036 const-string v13, ""
  003a invoke-static v11, v0, v12, v13, Lcom/personal/aihub/PreviewMetadata;->resolve(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Ljava/lang/String;)Lorg/json/JSONObject;
  0040 move-result-object v12
  0042 new-instance v0, Lorg/json/JSONArray;
  0046 invoke-direct v0, Lorg/json/JSONArray;-><init>()V
  004c const-string v1, "battle"
  0050 const-string v2, "Battle poses"
  0054 filled-new-array v1, v2, [Ljava/lang/String;
  005a move-result-object v1
  005c const-string v2, "idle"
  0060 const-string v3, "Idle poses"
  0064 filled-new-array v2, v3, [Ljava/lang/String;
  006a move-result-object v2
  006c const-string v3, "sp"
  0070 const-string v4, "Attack poses"
  0074 filled-new-array v3, v4, [Ljava/lang/String;
  007a move-result-object v3
  007c const-string v4, "card_bg"
  0080 const-string v5, "Animated card background"
  0084 filled-new-array v4, v5, [Ljava/lang/String;
  008a move-result-object v4
  008c filled-new-array v1, v2, v3, v4, [[Ljava/lang/String;
  0092 move-result-object v1
  0094 const/4 v2, 0
  0096 move v3, v2
  0098 const/4 v4, 4
  009a const-string v5, "path"
  009e const-string v6, "(?i)[a-z0-9_./-]+\.lwf"
  00a2 const-string v7, "rel"
  00a6 const-string v8, "name"
  00aa if-ge v3, v4, +050h
  00ae aget-object v4, v1, v3
  00b2 aget-object v9, v4, v2
  00b6 invoke-virtual v12, v9, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  00bc move-result-object v9
  00be if-nez v9, +004h
  00c2 move-object v7, v13
  00c4 goto +5h
  00c6 invoke-virtual v9, v7, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  00cc move-result-object v7
  00ce invoke-virtual v7, v6, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  00d4 move-result v6
  00d6 if-eqz v6, +037h
  00da invoke-static v7, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  00e0 move-result v6
  00e2 if-eqz v6, +031h
  00e6 new-instance v6, Lorg/json/JSONObject;
  00ea invoke-direct v6, Lorg/json/JSONObject;-><init>()V
  00f0 new-instance v9, Ljava/lang/StringBuilder;
  00f4 invoke-direct v9, Ljava/lang/StringBuilder;-><init>()V
  00fa invoke-virtual v12, v8, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0100 move-result-object v10
  0102 invoke-static v10, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0108 move-result-object v10
  010a invoke-virtual v9, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0110 const-string v10, " · "
  0114 invoke-virtual v9, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  011a const/4 v10, 1
  011c aget-object v4, v4, v10
  0120 invoke-virtual v9, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0126 invoke-virtual v9, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  012c move-result-object v4
  012e invoke-virtual v6, v8, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0134 move-result-object v4
  0136 invoke-virtual v4, v5, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  013c move-result-object v4
  013e invoke-virtual v0, v4, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0144 add-int/lit8 v3, v3, 1
  0148 goto -58h
  014a const-string v1, "aura_effect_id"
  014e invoke-virtual v12, v1, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  0154 move-result-wide v2
  0156 const-wide/16 v9, 0
  015a cmp-long v2, v2, v9
  015e if-lez v2, +06fh
  0162 new-instance v2, Lcom/personal/aihub/PreviewCache;
  0166 iget-object v3, v11, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  016a invoke-direct v2, v3, Lcom/personal/aihub/PreviewCache;-><init>(Ljava/io/File;)V
  0170 new-instance v3, Ljava/lang/StringBuilder;
  0174 invoke-direct v3, Ljava/lang/StringBuilder;-><init>()V
  017a const-string v4, "https://dokkan-eclipse.com/api/effect-pack/"
  017e invoke-virtual v3, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0184 invoke-virtual v12, v1, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  018a move-result-wide v9
  018c invoke-virtual v3, v9, v10, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0192 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0198 move-result-object v1
  019a invoke-static v11, v2, v1, v13, Lcom/personal/aihub/PreviewMetadata;->resolve(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Ljava/lang/String;)Lorg/json/JSONObject;
  01a0 move-result-object v1
  01a2 const-string v2, "lwf"
  01a6 invoke-virtual v1, v2, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  01ac move-result-object v2
  01ae if-eqz v2, +006h
  01b2 invoke-virtual v2, v7, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  01b8 move-result-object v13
  01ba invoke-virtual v13, v6, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  01c0 move-result v2
  01c2 if-eqz v2, +03dh
  01c6 invoke-static v13, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  01cc move-result v2
  01ce if-eqz v2, +037h
  01d2 new-instance v2, Lorg/json/JSONObject;
  01d6 invoke-direct v2, Lorg/json/JSONObject;-><init>()V
  01dc new-instance v3, Ljava/lang/StringBuilder;
  01e0 invoke-direct v3, Ljava/lang/StringBuilder;-><init>()V
  01e6 invoke-virtual v12, v8, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  01ec move-result-object v12
  01ee invoke-static v12, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  01f4 move-result-object v12
  01f6 invoke-virtual v3, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01fc const-string v12, " · Aura"
  0200 invoke-virtual v3, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0206 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  020c move-result-object v12
  020e invoke-virtual v2, v8, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0214 move-result-object v12
  0216 invoke-virtual v12, v5, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  021c move-result-object v12
  021e const-string v13, "scene"
  0222 const-string v2, "scene_name"
  0226 invoke-virtual v1, v2, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  022c move-result-object v1
  022e invoke-virtual v12, v13, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0234 move-result-object v12
  0236 invoke-virtual v0, v12, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  023c new-instance v12, Lorg/json/JSONObject;
  0240 invoke-direct v12, Lorg/json/JSONObject;-><init>()V
  0246 const-string v13, "items"
  024a invoke-virtual v12, v13, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0250 move-result-object v12
  0252 return-object v12
  0254 new-instance v12, Ljava/io/IOException;
  0258 const-string v13, "Choose a character"
  025c invoke-direct v12, v13, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0262 throw v12
.end method

.method apkDatabaseRank(Ljava/lang/String;)I
  0000 const-string v0, "/sqlite/current/en/"
  0004 invoke-virtual v1, v0, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  000a move-result v0
  000c if-eqz v0, +00eh
  0010 const-string v0, "_decrypted"
  0014 invoke-virtual v1, v0, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  001a move-result v1
  001c if-eqz v1, +004h
  0020 const/4 v1, 3
  0022 goto +2h
  0024 const/4 v1, 2
  0026 return v1
  0028 const/4 v1, 1
  002a return v1
.end method

.method connection(Ljava/lang/String;)Ljava/net/HttpURLConnection;
  0000 const/4 v0, 0
  0002 invoke-direct v1, v2, v0, Lcom/personal/aihub/CreatorActivity;->connection(Ljava/lang/String; I)Ljava/net/HttpURLConnection;
  0008 move-result-object v2
  000a return-object v2
.end method

.method connection(Ljava/lang/String; I)Ljava/net/HttpURLConnection;
  0000 const/4 v0, 5
  0002 if-gt v5, v0, +089h
  0006 new-instance v0, Ljava/net/URL;
  000a invoke-direct v0, v4, Ljava/net/URL;-><init>(Ljava/lang/String;)V
  0010 invoke-virtual v0, Ljava/net/URL;->getProtocol()Ljava/lang/String;
  0016 move-result-object v4
  0018 const-string v1, "https"
  001c invoke-virtual v4, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0022 move-result v4
  0024 if-eqz v4, +070h
  0028 invoke-virtual v0, Ljava/net/URL;->getHost()Ljava/lang/String;
  002e move-result-object v4
  0030 const-string v1, "dokkan-eclipse.com"
  0034 invoke-virtual v4, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  003a move-result v4
  003c if-eqz v4, +064h
  0040 invoke-virtual v0, Ljava/net/URL;->openConnection()Ljava/net/URLConnection;
  0046 move-result-object v4
  0048 check-cast v4, Ljava/net/HttpURLConnection;
  004c const/16 v1, 20000
  0050 invoke-virtual v4, v1, Ljava/net/HttpURLConnection;->setConnectTimeout(I)V
  0056 const v1, 60000
  005c invoke-virtual v4, v1, Ljava/net/HttpURLConnection;->setReadTimeout(I)V
  0062 const/4 v1, 0
  0064 invoke-virtual v4, v1, Ljava/net/HttpURLConnection;->setInstanceFollowRedirects(Z)V
  006a const-string v1, "User-Agent"
  006e const-string v2, "DokkanUnitCreator/2.3"
  0072 invoke-virtual v4, v1, v2, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String; Ljava/lang/String;)V
  0078 invoke-virtual v4, Ljava/net/HttpURLConnection;->getResponseCode()I
  007e move-result v1
  0080 const/16 v2, 300
  0084 if-lt v1, v2, +01fh
  0088 const/16 v2, 400
  008c if-ge v1, v2, +01bh
  0090 const-string v1, "Location"
  0094 invoke-virtual v4, v1, Ljava/net/HttpURLConnection;->getHeaderField(Ljava/lang/String;)Ljava/lang/String;
  009a move-result-object v1
  009c invoke-virtual v4, Ljava/net/HttpURLConnection;->disconnect()V
  00a2 new-instance v4, Ljava/net/URL;
  00a6 invoke-direct v4, v0, v1, Ljava/net/URL;-><init>(Ljava/net/URL; Ljava/lang/String;)V
  00ac invoke-virtual v4, Ljava/net/URL;->toString()Ljava/lang/String;
  00b2 move-result-object v4
  00b4 add-int/lit8 v5, v5, 1
  00b8 invoke-direct v3, v4, v5, Lcom/personal/aihub/CreatorActivity;->connection(Ljava/lang/String; I)Ljava/net/HttpURLConnection;
  00be move-result-object v4
  00c0 return-object v4
  00c2 const/16 v5, 200
  00c6 if-ne v1, v5, +003h
  00ca return-object v4
  00cc invoke-virtual v4, Ljava/net/HttpURLConnection;->disconnect()V
  00d2 new-instance v4, Ljava/io/IOException;
  00d6 new-instance v5, Ljava/lang/StringBuilder;
  00da const-string v0, "Eclipse returned HTTP "
  00de invoke-direct v5, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00e4 invoke-virtual v5, v1, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  00ea const-string v0, ". You can import a local database or resource pack instead."
  00ee invoke-virtual v5, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00f4 invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00fa move-result-object v5
  00fc invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0102 throw v4
  0104 new-instance v4, Ljava/io/IOException;
  0108 const-string v5, "Only official Eclipse resource routes are supported"
  010c invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0112 throw v4
  0114 new-instance v4, Ljava/io/IOException;
  0118 const-string v5, "Too many Eclipse redirects"
  011c invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0122 throw v4
.end method

.method copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  0000 const/high16 v0, 65536
  0004 new-array v0, v0, [B
  0008 const-wide/16 v1, 0
  000c invoke-virtual v6, v0, Ljava/io/InputStream;->read([B)I
  0012 move-result v3
  0014 const/4 v4, -1
  0016 if-ne v3, v4, +003h
  001a return-void 
  001c int-to-long v4, v3
  001e add-long/2addr v1, v4
  0020 cmp-long v4, v1, v8
  0024 if-gtz v4, +007h
  0028 const/4 v4, 0
  002a invoke-virtual v7, v0, v4, v3, Ljava/io/OutputStream;->write([B I I)V
  0030 goto -12h
  0032 new-instance v6, Ljava/io/IOException;
  0036 const-string v7, "File exceeds the supported import size."
  003a invoke-direct v6, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0040 throw v6
.end method

.method cpkWarning(Lorg/json/JSONArray; Ljava/lang/String;)V
  0000 invoke-virtual v2, Lorg/json/JSONArray;->length()I
  0006 move-result v0
  0008 const/16 v1, 200
  000c if-lt v0, v1, +00bh
  0010 invoke-virtual v2, Lorg/json/JSONArray;->length()I
  0016 move-result v3
  0018 if-eq v3, v1, +003h
  001c return-void 
  001e const-string v3, "Additional CPK warnings were omitted. Original archives were kept."
  0022 invoke-virtual v2, v3, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0028 return-void 
.end method

.method dataStore()Lcom/personal/aihub/GameDataStore;
  0000 new-instance v0, Lcom/personal/aihub/GameDataStore;
  0004 iget-object v1, v5, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0008 new-instance v2, Ljava/io/File;
  000c iget-object v3, v5, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0010 const-string v4, "bundled-database.db"
  0014 invoke-direct v2, v3, v4, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  001a invoke-direct v0, v1, v2, Lcom/personal/aihub/GameDataStore;-><init>(Ljava/io/File; Ljava/io/File;)V
  0020 return-object v0
.end method

.method deleteTree(Ljava/io/File;)V
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
  0024 invoke-static v3, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  002a add-int/lit8 v2, v2, 1
  002e goto -9h
  0030 invoke-virtual v4, Ljava/io/File;->delete()Z
  0036 return-void 
.end method

.method downloadAsset(Ljava/lang/String;)Lorg/json/JSONObject;
  0000 const/4 v0, 0
  0002 invoke-direct v1, v2, v0, Lcom/personal/aihub/CreatorActivity;->downloadAsset(Ljava/lang/String; Ljava/lang/String;)Lorg/json/JSONObject;
  0008 move-result-object v2
  000a return-object v2
.end method

.method downloadAsset(Ljava/lang/String; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 invoke-static v6, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  0006 move-result v0
  0008 if-eqz v0, +091h
  000c const-string v0, "(?i).*\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$"
  0010 invoke-virtual v6, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0016 move-result v0
  0018 if-eqz v0, +089h
  001c if-eqz v7, +013h
  0020 const-string v0, "^art-download-[0-9]{10,16}-[A-Za-z0-9_-]{6,64}$"
  0024 invoke-virtual v7, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  002a move-result v0
  002c if-eqz v0, +003h
  0030 goto +9h
  0032 new-instance v6, Ljava/io/IOException;
  0036 const-string v7, "Invalid artwork collection."
  003a invoke-direct v6, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0040 throw v6
  0042 new-instance v0, Ljava/lang/StringBuilder;
  0046 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  004c if-nez v7, +005h
  0050 const-string v1, "eclipse"
  0054 goto +2h
  0056 move-object v1, v7
  0058 invoke-static v1, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  005e move-result-object v1
  0060 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0066 const-string v1, "/"
  006a invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0070 invoke-virtual v0, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0076 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  007c move-result-object v0
  007e iget-object v2, v5, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  0082 invoke-static v2, v0, Lcom/personal/aihub/AssetDownload;->destination(Ljava/io/File; Ljava/lang/String;)Ljava/io/File;
  0088 move-result-object v2
  008a new-instance v3, Lorg/json/JSONObject;
  008e invoke-direct v3, Lorg/json/JSONObject;-><init>()V
  0094 const-string v4, "key"
  0098 invoke-virtual v3, v4, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  009e move-result-object v0
  00a0 const-string v3, "path"
  00a4 invoke-virtual v0, v3, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00aa move-result-object v0
  00ac const-string v3, "name"
  00b0 invoke-virtual v2, Ljava/io/File;->getName()Ljava/lang/String;
  00b6 move-result-object v4
  00b8 invoke-virtual v0, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00be move-result-object v0
  00c0 new-instance v3, Ljava/lang/StringBuilder;
  00c4 const-string v4, "https://dokkan-eclipse.com/cdn/uncompressed/"
  00c8 invoke-direct v3, v4, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00ce invoke-static v6, v1, Landroid/net/Uri;->encode(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  00d4 move-result-object v1
  00d6 invoke-virtual v3, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00dc invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00e2 move-result-object v1
  00e4 invoke-static v1, Lcom/personal/aihub/AssetDownload;->openOfficial(Ljava/lang/String;)Ljava/net/HttpURLConnection;
  00ea move-result-object v1
  00ec if-eqz v7, +004h
  00f0 const/4 v7, 1
  00f2 goto +2h
  00f4 const/4 v7, 0
  00f6 const-wide/32 v3, 167772160
  00fc invoke-static v1, v2, v7, v3, v4, Lcom/personal/aihub/AssetDownload;->write(Ljava/net/HttpURLConnection; Ljava/io/File; Z J)J
  0102 move-result-wide v1
  0104 const-string v7, "size"
  0108 invoke-virtual v0, v7, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  010e move-result-object v7
  0110 const-string v0, "(?i).*\.(png|jpe?g|webp|gif|bmp)$"
  0114 invoke-virtual v6, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  011a move-result v6
  011c const-string v0, "image"
  0120 invoke-virtual v7, v0, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0126 move-result-object v6
  0128 return-object v6
  012a new-instance v6, Ljava/io/IOException;
  012e const-string v7, "Choose a supported resource file"
  0132 invoke-direct v6, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0138 throw v6
.end method

.method downloadCurrentDatabase(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 move-object/from16 v8, v25
  0004 const-string v0, "https://dokkan-eclipse.com/cdn/uncompressed/sqlite/current/en/database_decrypted.db"
  0008 new-instance v9, Ljava/io/File;
  000c iget-object v1, v8, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0010 new-instance v2, Ljava/lang/StringBuilder;
  0014 const-string v3, "database-download-"
  0018 invoke-direct v2, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  001e invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0024 move-result-object v3
  0026 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  002c const-string v3, ".tmp"
  0030 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0036 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  003c move-result-object v2
  003e invoke-direct v9, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0044 const/4 v10, 0
  0046 const-string v2, "download"
  004a const-string v3, "Downloading Eclipse’s current full English database"
  004e const-wide/16 v4, 0
  0052 const-wide/16 v6, 0
  0056 move-object/from16 v1, v25
  005a invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  0060 invoke-direct v8, v0, Lcom/personal/aihub/CreatorActivity;->connection(Ljava/lang/String;)Ljava/net/HttpURLConnection;
  0066 move-result-object v10
  0068 invoke-virtual v10, Ljava/net/HttpURLConnection;->getContentLengthLong()J
  006e move-result-wide v11
  0070 const-wide/32 v13, 536870912
  0076 cmp-long v1, v11, v13
  007a const-string v15, "Database download exceeds 512 MB"
  007e if-gtz v1, +0e4h
  0082 invoke-virtual v10, Ljava/net/HttpURLConnection;->getInputStream()Ljava/io/InputStream;
  0088 move-result-object v6
  008a new-instance v7, Ljava/io/FileOutputStream;
  008e invoke-direct v7, v9, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0094 const/high16 v1, 65536
  0098 new-array v4, v1, [B
  009c const-wide/16 v2, 0
  00a0 invoke-virtual v6, v4, Ljava/io/InputStream;->read([B)I
  00a6 move-result v1
  00a8 const/4 v5, -1
  00aa if-eq v1, v5, +03fh
  00ae move-object/from16 v18, v6
  00b2 int-to-long v5, v1
  00b4 add-long v19, v2, v5
  00b8 cmp-long v2, v19, v13
  00bc if-gtz v2, +02bh
  00c0 const/4 v2, 0
  00c2 invoke-virtual v7, v4, v2, v1, Ljava/io/FileOutputStream;->write([B I I)V
  00c8 const-string v2, "download"
  00cc const-string v3, "Downloading Eclipse’s current full English database"
  00d0 const-wide/16 v5, 0
  00d4 invoke-static v5, v6, v11, v12, Ljava/lang/Math;->max(J J)J
  00da move-result-wide v16
  00dc move-object/from16 v1, v25
  00e0 move-wide/from16 v21, v5
  00e4 move-object/from16 v23, v4
  00e8 move-wide/from16 v4, v19
  00ec move-object/from16 v24, v7
  00f0 move-wide/from16 v6, v16
  00f4 invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  00fa move-object/from16 v6, v18
  00fe move-wide/from16 v2, v19
  0102 move-object/from16 v4, v23
  0106 move-object/from16 v7, v24
  010a goto -35h
  010c move-exception v0
  010e goto/16 +07fh
  0112 move-object/from16 v24, v7
  0116 new-instance v0, Ljava/io/IOException;
  011a invoke-direct v0, v15, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0120 throw v0
  0122 move-exception v0
  0124 goto/16 +076h
  0128 move-object/from16 v18, v6
  012c move-object/from16 v24, v7
  0130 const-wide/16 v21, 0
  0134 invoke-virtual/range v24, Ljava/io/FileOutputStream;->close()V
  013a if-eqz v18, +005h
  013e invoke-virtual/range v18, Ljava/io/InputStream;->close()V
  0144 cmp-long v1, v11, v21
  0148 if-lez v1, +00fh
  014c cmp-long v1, v2, v11
  0150 if-nez v1, +003h
  0154 goto +9h
  0156 new-instance v0, Ljava/io/IOException;
  015a const-string v1, "The database download was incomplete"
  015e invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0164 throw v0
  0166 const-string v4, "verify"
  016a const-string v5, "Checking downloaded database"
  016e const-wide/16 v6, 0
  0172 const-wide/16 v11, 0
  0176 move-object/from16 v1, v25
  017a move-wide v13, v2
  017c move-object v2, v4
  017e move-object v3, v5
  0180 move-wide v4, v6
  0182 move-wide v6, v11
  0184 invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  018a const/4 v1, 1
  018c invoke-direct v8, v9, v1, Lcom/personal/aihub/CreatorActivity;->verifyDb(Ljava/io/File; Z)J
  0192 const-string v1, "Eclipse current full English database"
  0196 new-instance v2, Lorg/json/JSONObject;
  019a invoke-virtual/range v26, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  01a0 move-result-object v3
  01a2 invoke-direct v2, v3, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  01a8 const-string v3, "sourceType"
  01ac const-string v4, "eclipse-current"
  01b0 invoke-virtual v2, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01b6 move-result-object v2
  01b8 const-string v3, "downloadUrl"
  01bc invoke-virtual v2, v3, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01c2 move-result-object v0
  01c4 const-string v2, "publishedAt"
  01c8 const-string v3, "Last-Modified"
  01cc invoke-virtual v10, v3, Ljava/net/HttpURLConnection;->getHeaderField(Ljava/lang/String;)Ljava/lang/String;
  01d2 move-result-object v3
  01d4 invoke-virtual v0, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01da move-result-object v0
  01dc const-string v2, "downloadedBytes"
  01e0 invoke-virtual v0, v2, v13, v14, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  01e6 move-result-object v0
  01e8 invoke-direct v8, v9, v1, v0, Lcom/personal/aihub/CreatorActivity;->useDb(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  01ee move-result-object v0
  01f0 if-eqz v10, +005h
  01f4 invoke-virtual v10, Ljava/net/HttpURLConnection;->disconnect()V
  01fa invoke-virtual v9, Ljava/io/File;->delete()Z
  0200 return-object v0
  0202 move-exception v0
  0204 goto +14h
  0206 move-exception v0
  0208 move-object/from16 v18, v6
  020c move-object/from16 v24, v7
  0210 move-object v1, v0
  0212 invoke-virtual/range v24, Ljava/io/FileOutputStream;->close()V
  0218 goto +6h
  021a move-exception v0
  021c move-object v2, v0
  021e invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0224 throw v1
  0226 move-exception v0
  0228 move-object/from16 v18, v6
  022c move-object v1, v0
  022e if-eqz v18, +00bh
  0232 invoke-virtual/range v18, Ljava/io/InputStream;->close()V
  0238 goto +6h
  023a move-exception v0
  023c move-object v2, v0
  023e invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0244 throw v1
  0246 new-instance v0, Ljava/io/IOException;
  024a invoke-direct v0, v15, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0250 throw v0
  0252 move-exception v0
  0254 if-eqz v10, +005h
  0258 invoke-virtual v10, Ljava/net/HttpURLConnection;->disconnect()V
  025e invoke-virtual v9, Ljava/io/File;->delete()Z
  0264 throw v0
.end method

.method downloadSparkingAssets(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 move-object/from16 v1, v30
  0004 move-object/from16 v0, v31
  0008 const-string v2, "hash"
  000c const-string v3, "size"
  0010 const-string v4, "version"
  0014 const-wide/16 v5, -1
  0018 invoke-virtual v0, v4, v5, v6, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  001e move-result-wide v4
  0020 invoke-direct v1, v4, v5, Lcom/personal/aihub/CreatorActivity;->sparkingAssetManifest(J)Ljava/io/File;
  0026 move-result-object v4
  0028 invoke-direct/range v30, Lcom/personal/aihub/CreatorActivity;->sparkingStore()Lcom/personal/aihub/GameDataStore;
  002e move-result-object v5
  0030 invoke-virtual v5, Lcom/personal/aihub/GameDataStore;->meta()Lorg/json/JSONObject;
  0036 move-result-object v5
  0038 const-string v6, "latestVersion"
  003c invoke-virtual v5, v6, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0042 move-result-wide v5
  0044 new-instance v7, Lorg/json/JSONObject;
  0048 const/high16 v8, 33554432
  004c invoke-static v4, v8, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  0052 move-result-object v8
  0054 invoke-direct v7, v8, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  005a new-instance v8, Ljava/io/File;
  005e new-instance v9, Ljava/io/File;
  0062 iget-object v10, v1, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0066 const-string v11, "sparking"
  006a invoke-direct v9, v10, v11, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0070 const-string v10, "resource-cache"
  0074 invoke-direct v8, v9, v10, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  007a invoke-virtual v8, Ljava/io/File;->mkdirs()Z
  0080 const-string v9, "paths"
  0084 invoke-virtual v0, v9, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  008a move-result-object v0
  008c invoke-virtual v0, Lorg/json/JSONArray;->length()I
  0092 move-result v9
  0094 const/4 v10, 1
  0096 if-lt v9, v10, +1e8h
  009a invoke-virtual v0, Lorg/json/JSONArray;->length()I
  00a0 move-result v9
  00a2 const/16 v10, 32
  00a6 if-gt v9, v10, +1e0h
  00aa new-instance v9, Ljava/lang/StringBuilder;
  00ae const-string v10, "sparking-"
  00b2 invoke-direct v9, v10, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00b8 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  00be move-result-object v10
  00c0 invoke-virtual v9, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  00c6 invoke-virtual v9, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00cc move-result-object v9
  00ce invoke-virtual v1, v9, Lcom/personal/aihub/CreatorActivity;->assetFile(Ljava/lang/String;)Ljava/io/File;
  00d4 move-result-object v10
  00d6 invoke-virtual v10, Ljava/io/File;->mkdirs()Z
  00dc new-instance v12, Lorg/json/JSONArray;
  00e0 invoke-direct v12, Lorg/json/JSONArray;-><init>()V
  00e6 new-instance v13, Ljava/util/HashSet;
  00ea invoke-direct v13, Ljava/util/HashSet;-><init>()V
  00f0 const-wide/16 v14, 0
  00f4 const/16 v16, 0
  00f8 move-wide/from16 v28, v5
  00fc move/from16 v5, v16
  0100 move-wide/from16 v16, v28
  0104 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  010a move-result v6
  010c if-ge v5, v6, +18ah
  0110 invoke-virtual v0, v5, Lorg/json/JSONArray;->getString(I)Ljava/lang/String;
  0116 move-result-object v6
  0118 invoke-static v6, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  011e move-result v18
  0120 if-eqz v18, +178h
  0124 move-object/from16 v31, v0
  0128 sget-object v0, Ljava/text/Normalizer$Form;->NFC Ljava/text/Normalizer$Form;
  012c invoke-static v6, v0, Ljava/text/Normalizer;->normalize(Ljava/lang/CharSequence; Ljava/text/Normalizer$Form;)Ljava/lang/String;
  0132 move-result-object v0
  0134 move/from16 v18, v5
  0138 sget-object v5, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  013c invoke-virtual v0, v5, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  0142 move-result-object v0
  0144 invoke-virtual v13, v0, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  014a move-result v0
  014c if-eqz v0, +15ah
  0150 invoke-static v7, v6, Lcom/personal/aihub/SparkingContent;->assetRecord(Lorg/json/JSONObject; Ljava/lang/String;)Lorg/json/JSONObject;
  0156 move-result-object v0
  0158 invoke-virtual v0, v3, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  015e move-result-wide v19
  0160 add-long v14, v14, v19
  0164 move-object v5, v12
  0166 move-object/from16 v19, v13
  016a const-wide/32 v12, 536870912
  0170 cmp-long v20, v14, v12
  0174 if-gtz v20, +13eh
  0178 new-instance v12, Ljava/lang/StringBuilder;
  017c invoke-direct v12, Ljava/lang/StringBuilder;-><init>()V
  0182 invoke-virtual v0, v2, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0188 move-result-object v13
  018a invoke-virtual v12, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0190 const-string v13, "-"
  0194 invoke-virtual v12, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  019a move-wide/from16 v21, v14
  019e invoke-virtual v0, v3, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  01a4 move-result-wide v13
  01a6 invoke-virtual v12, v13, v14, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  01ac invoke-virtual v12, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01b2 move-result-object v12
  01b4 new-instance v13, Ljava/io/File;
  01b8 new-instance v14, Ljava/lang/StringBuilder;
  01bc invoke-direct v14, Ljava/lang/StringBuilder;-><init>()V
  01c2 invoke-virtual v14, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01c8 const-string v15, ".data"
  01cc invoke-virtual v14, v15, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01d2 invoke-virtual v14, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01d8 move-result-object v14
  01da invoke-direct v13, v8, v14, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  01e0 new-instance v14, Ljava/io/File;
  01e4 new-instance v15, Ljava/lang/StringBuilder;
  01e8 invoke-direct v15, Ljava/lang/StringBuilder;-><init>()V
  01ee invoke-virtual v15, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01f4 const-string v12, ".json"
  01f8 invoke-virtual v15, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01fe invoke-virtual v15, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0204 move-result-object v12
  0206 invoke-direct v14, v8, v12, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  020c invoke-virtual v13, Ljava/io/File;->isFile()Z
  0212 move-result v12
  0214 const-string v15, "sha256"
  0218 const/16 v23, 0
  021c if-eqz v12, +042h
  0220 invoke-virtual v13, Ljava/io/File;->length()J
  0226 move-result-wide v24
  0228 invoke-virtual v0, v3, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  022e move-result-wide v26
  0230 cmp-long v12, v24, v26
  0234 if-nez v12, +036h
  0238 invoke-virtual v14, Ljava/io/File;->isFile()Z
  023e move-result v12
  0240 if-eqz v12, +030h
  0244 new-instance v12, Lorg/json/JSONObject;
  0248 move-object/from16 v24, v7
  024c const/16 v7, 8192
  0250 invoke-static v14, v7, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  0256 move-result-object v7
  0258 invoke-direct v12, v7, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  025e invoke-virtual v0, v2, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0264 move-result-object v0
  0266 const-string v7, "xxhash64"
  026a invoke-virtual v12, v7, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0270 move-result-object v7
  0272 invoke-virtual v0, v7, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0278 move-result v0
  027a if-eqz v0, +015h
  027e invoke-static v13, Lcom/personal/aihub/GameDataStore;->hash(Ljava/io/File;)Ljava/lang/String;
  0284 move-result-object v0
  0286 invoke-virtual v12, v15, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  028c move-result-object v7
  028e invoke-virtual v0, v7, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0294 move-result v0
  0296 if-eqz v0, +007h
  029a move-object/from16 v23, v12
  029e goto +3h
  02a0 move-object/from16 v24, v7
  02a4 if-nez v23, +012h
  02a8 new-instance v0, Lcom/personal/aihub/CreatorActivity$$ExternalSyntheticLambda1;
  02ac invoke-direct v0, v1, Lcom/personal/aihub/CreatorActivity$$ExternalSyntheticLambda1;-><init>(Lcom/personal/aihub/CreatorActivity;)V
  02b2 invoke-static v4, v6, v13, v0, Lcom/personal/aihub/SparkingContent;->downloadAsset(Ljava/io/File; Ljava/lang/String; Ljava/io/File; Lcom/personal/aihub/SparkingContent$Progress;)Lorg/json/JSONObject;
  02b8 move-result-object v23
  02ba invoke-virtual/range v23, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  02c0 move-result-object v0
  02c2 invoke-static v14, v0, Lcom/personal/aihub/CreatorActivity;->writeText(Ljava/io/File; Ljava/lang/String;)V
  02c8 move-object/from16 v0, v23
  02cc new-instance v7, Ljava/io/File;
  02d0 invoke-direct v7, v10, v6, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  02d6 invoke-virtual v7, Ljava/io/File;->getParentFile()Ljava/io/File;
  02dc move-result-object v12
  02de invoke-virtual v12, Ljava/io/File;->mkdirs()Z
  02e4 new-instance v12, Ljava/io/FileInputStream;
  02e8 invoke-direct v12, v13, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  02ee new-instance v13, Ljava/io/FileOutputStream;
  02f2 invoke-direct v13, v7, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  02f8 move-object/from16 v23, v2
  02fc const-wide/32 v1, 536870912
  0302 invoke-static v12, v13, v1, v2, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  0308 invoke-virtual v13, Ljava/io/FileOutputStream;->close()V
  030e invoke-virtual v12, Ljava/io/InputStream;->close()V
  0314 new-instance v1, Lorg/json/JSONObject;
  0318 invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  031e const-string v2, "key"
  0322 new-instance v12, Ljava/lang/StringBuilder;
  0326 invoke-direct v12, Ljava/lang/StringBuilder;-><init>()V
  032c invoke-virtual v12, v9, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0332 const-string v13, "/"
  0336 invoke-virtual v12, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  033c invoke-virtual v12, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0342 invoke-virtual v12, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0348 move-result-object v12
  034a invoke-virtual v1, v2, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0350 move-result-object v1
  0352 const-string v2, "path"
  0356 invoke-virtual v1, v2, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  035c move-result-object v1
  035e const-string v2, "sourcePath"
  0362 invoke-virtual v1, v2, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0368 move-result-object v1
  036a invoke-virtual v7, Ljava/io/File;->length()J
  0370 move-result-wide v6
  0372 invoke-virtual v1, v3, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0378 move-result-object v1
  037a invoke-virtual v0, v15, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0380 move-result-object v0
  0382 invoke-virtual v1, v15, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0388 move-result-object v0
  038a const-string v1, "source"
  038e invoke-virtual v0, v1, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0394 move-result-object v0
  0396 invoke-virtual v5, v0, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  039c add-int/lit8 v0, v18, 1
  03a0 move-object/from16 v1, v30
  03a4 move-object v12, v5
  03a6 move-object/from16 v13, v19
  03aa move-wide/from16 v14, v21
  03ae move-object/from16 v2, v23
  03b2 move-object/from16 v7, v24
  03b6 move v5, v0
  03b8 move-object/from16 v0, v31
  03bc goto/16 -15ch
  03c0 move-exception v0
  03c2 move-object v1, v0
  03c4 invoke-virtual v13, Ljava/io/FileOutputStream;->close()V
  03ca goto +6h
  03cc move-exception v0
  03ce move-object v2, v0
  03d0 invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  03d6 throw v1
  03d8 move-exception v0
  03da move-object v1, v0
  03dc invoke-virtual v12, Ljava/io/InputStream;->close()V
  03e2 goto +6h
  03e4 move-exception v0
  03e6 move-object v2, v0
  03e8 invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  03ee throw v1
  03f0 new-instance v0, Ljava/io/IOException;
  03f4 const-string v1, "This resource batch exceeds512MB. Choose fewer resources."
  03f8 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03fe throw v0
  0400 new-instance v0, Ljava/io/IOException;
  0404 const-string v1, "Selected resources have conflicting game paths."
  0408 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  040e throw v0
  0410 new-instance v0, Ljava/io/IOException;
  0414 const-string v1, "Invalid Sparking game resource path."
  0418 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  041e throw v0
  0420 move-object v5, v12
  0422 invoke-virtual v5, Lorg/json/JSONArray;->length()I
  0428 move-result v0
  042a move-object/from16 v1, v30
  042e invoke-direct v1, v10, v0, v14, v15, Lcom/personal/aihub/CreatorActivity;->expandCpkResources(Ljava/io/File; I J)Lorg/json/JSONObject;
  0434 move-result-object v0
  0436 const-string v2, "assets"
  043a invoke-virtual v0, v2, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0440 move-result-object v0
  0442 const-string v2, "sourceVersion"
  0446 move-wide/from16 v3, v16
  044a invoke-virtual v0, v2, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0450 move-result-object v0
  0452 return-object v0
  0454 move-exception v0
  0456 move-object/from16 v1, v30
  045a goto +2h
  045c move-exception v0
  045e invoke-static v10, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  0464 throw v0
  0466 new-instance v0, Ljava/io/IOException;
  046a const-string v2, "Choose between 1 and 32 game resource files at a time."
  046e invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0474 throw v0
.end method

.method ensureDb()V
  0000 iget-object v0, v6, Lcom/personal/aihub/CreatorActivity;->db Landroid/database/sqlite/SQLiteDatabase;
  0004 if-eqz v0, +003h
  0008 return-void 
  000a iget-object v0, v6, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  000e invoke-static v6, v0, Lcom/personal/aihub/ForgeFixes;->refreshBundledDatabase(Landroid/content/Context; Ljava/io/File;)V
  0014 new-instance v0, Ljava/io/File;
  0018 iget-object v1, v6, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  001c const-string v2, "bundled-database.db"
  0020 invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0026 invoke-virtual v0, Ljava/io/File;->exists()Z
  002c move-result v1
  002e if-nez v1, +04dh
  0032 new-instance v1, Ljava/io/File;
  0036 iget-object v2, v6, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  003a const-string v3, "bundled.tmp"
  003e invoke-direct v1, v2, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0044 invoke-virtual v6, Lcom/personal/aihub/CreatorActivity;->getAssets()Landroid/content/res/AssetManager;
  004a move-result-object v2
  004c const-string v3, "reference.db"
  0050 invoke-virtual v2, v3, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;
  0056 move-result-object v2
  0058 new-instance v3, Ljava/io/FileOutputStream;
  005c invoke-direct v3, v1, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0062 const-wide/32 v4, 536870912
  0068 invoke-static v2, v3, v4, v5, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  006e invoke-virtual v3, Ljava/io/FileOutputStream;->close()V
  0074 if-eqz v2, +005h
  0078 invoke-virtual v2, Ljava/io/InputStream;->close()V
  007e invoke-virtual v1, v0, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  0084 move-result v0
  0086 if-eqz v0, +003h
  008a goto +1fh
  008c new-instance v0, Ljava/io/IOException;
  0090 const-string v1, "Could not prepare the card database."
  0094 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  009a throw v0
  009c move-exception v0
  009e invoke-virtual v3, Ljava/io/FileOutputStream;->close()V
  00a4 goto +5h
  00a6 move-exception v1
  00a8 invoke-virtual v0, v1, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  00ae throw v0
  00b0 move-exception v0
  00b2 if-eqz v2, +00ah
  00b6 invoke-virtual v2, Ljava/io/InputStream;->close()V
  00bc goto +5h
  00be move-exception v1
  00c0 invoke-virtual v0, v1, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  00c6 throw v0
  00c8 invoke-direct v6, Lcom/personal/aihub/CreatorActivity;->dataStore()Lcom/personal/aihub/GameDataStore;
  00ce move-result-object v0
  00d0 invoke-virtual v0, Lcom/personal/aihub/GameDataStore;->current()Ljava/io/File;
  00d6 move-result-object v0
  00d8 invoke-virtual v0, Ljava/io/File;->getPath()Ljava/lang/String;
  00de move-result-object v0
  00e0 const/4 v1, 1
  00e2 const/4 v2, 0
  00e4 invoke-static v0, v2, v1, Landroid/database/sqlite/SQLiteDatabase;->openDatabase(Ljava/lang/String; Landroid/database/sqlite/SQLiteDatabase$CursorFactory; I)Landroid/database/sqlite/SQLiteDatabase;
  00ea move-result-object v0
  00ec iput-object v0, v6, Lcom/personal/aihub/CreatorActivity;->db Landroid/database/sqlite/SQLiteDatabase;
  00f0 new-instance v0, Lorg/json/JSONObject;
  00f4 invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  00fa iput-object v0, v6, Lcom/personal/aihub/CreatorActivity;->schema Lorg/json/JSONObject;
  00fe iget-object v0, v6, Lcom/personal/aihub/CreatorActivity;->db Landroid/database/sqlite/SQLiteDatabase;
  0102 const-string v1, "SELECT name FROM sqlite_master WHERE type='table'"
  0106 invoke-virtual v0, v1, v2, Landroid/database/sqlite/SQLiteDatabase;->rawQuery(Ljava/lang/String; [Ljava/lang/String;)Landroid/database/Cursor;
  010c move-result-object v0
  010e invoke-interface v0, Landroid/database/Cursor;->moveToNext()Z
  0114 move-result v1
  0116 if-eqz v1, +04ah
  011a const/4 v1, 0
  011c invoke-interface v0, v1, Landroid/database/Cursor;->getString(I)Ljava/lang/String;
  0122 move-result-object v1
  0124 const-string v3, "[a-zA-Z_][a-zA-Z0-9_]*"
  0128 invoke-virtual v1, v3, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  012e move-result v3
  0130 if-eqz v3, -011h
  0134 iget-object v3, v6, Lcom/personal/aihub/CreatorActivity;->db Landroid/database/sqlite/SQLiteDatabase;
  0138 new-instance v4, Ljava/lang/StringBuilder;
  013c invoke-direct v4, Ljava/lang/StringBuilder;-><init>()V
  0142 const-string v5, "PRAGMA table_info("
  0146 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  014c invoke-static v1, Lcom/personal/aihub/CreatorActivity;->identifier(Ljava/lang/String;)Ljava/lang/String;
  0152 move-result-object v5
  0154 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  015a const-string v5, ")"
  015e invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0164 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  016a move-result-object v4
  016c invoke-virtual v3, v4, v2, Landroid/database/sqlite/SQLiteDatabase;->rawQuery(Ljava/lang/String; [Ljava/lang/String;)Landroid/database/Cursor;
  0172 move-result-object v3
  0174 iget-object v4, v6, Lcom/personal/aihub/CreatorActivity;->schema Lorg/json/JSONObject;
  0178 invoke-static v3, Lcom/personal/aihub/CreatorActivity;->rows(Landroid/database/Cursor;)Lorg/json/JSONArray;
  017e move-result-object v5
  0180 invoke-virtual v4, v1, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0186 if-eqz v3, -03ch
  018a invoke-interface v3, Landroid/database/Cursor;->close()V
  0190 goto -41h
  0192 move-exception v1
  0194 if-eqz v3, +00ah
  0198 invoke-interface v3, Landroid/database/Cursor;->close()V
  019e goto +5h
  01a0 move-exception v2
  01a2 invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  01a8 throw v1
  01aa if-eqz v0, +005h
  01ae invoke-interface v0, Landroid/database/Cursor;->close()V
  01b4 return-void 
  01b6 move-exception v1
  01b8 if-eqz v0, +00ah
  01bc invoke-interface v0, Landroid/database/Cursor;->close()V
  01c2 goto +5h
  01c4 move-exception v0
  01c6 invoke-virtual v1, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  01cc throw v1
.end method

.method ensureSparkingDb()V
  0000 iget-object v0, v7, Lcom/personal/aihub/CreatorActivity;->sparkingDb Landroid/database/sqlite/SQLiteDatabase;
  0004 if-eqz v0, +003h
  0008 return-void 
  000a invoke-direct v7, Lcom/personal/aihub/CreatorActivity;->prepareSparkingSnapshot()V
  0010 invoke-direct v7, Lcom/personal/aihub/CreatorActivity;->sparkingStore()Lcom/personal/aihub/GameDataStore;
  0016 move-result-object v0
  0018 invoke-virtual v0, Lcom/personal/aihub/GameDataStore;->current()Ljava/io/File;
  001e move-result-object v0
  0020 invoke-virtual v0, Ljava/io/File;->getPath()Ljava/lang/String;
  0026 move-result-object v0
  0028 const/4 v1, 1
  002a const/4 v2, 0
  002c invoke-static v0, v2, v1, Landroid/database/sqlite/SQLiteDatabase;->openDatabase(Ljava/lang/String; Landroid/database/sqlite/SQLiteDatabase$CursorFactory; I)Landroid/database/sqlite/SQLiteDatabase;
  0032 move-result-object v0
  0034 new-instance v1, Lorg/json/JSONObject;
  0038 invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  003e const-string v3, "SELECT name FROM sqlite_master WHERE type='table'"
  0042 invoke-virtual v0, v3, v2, Landroid/database/sqlite/SQLiteDatabase;->rawQuery(Ljava/lang/String; [Ljava/lang/String;)Landroid/database/Cursor;
  0048 move-result-object v3
  004a invoke-interface v3, Landroid/database/Cursor;->moveToNext()Z
  0050 move-result v4
  0052 if-eqz v4, +046h
  0056 const/4 v4, 0
  0058 invoke-interface v3, v4, Landroid/database/Cursor;->getString(I)Ljava/lang/String;
  005e move-result-object v4
  0060 const-string v5, "[a-zA-Z_][a-zA-Z0-9_]*"
  0064 invoke-virtual v4, v5, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  006a move-result v5
  006c if-eqz v5, -011h
  0070 new-instance v5, Ljava/lang/StringBuilder;
  0074 invoke-direct v5, Ljava/lang/StringBuilder;-><init>()V
  007a const-string v6, "PRAGMA table_info("
  007e invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0084 invoke-static v4, Lcom/personal/aihub/CreatorActivity;->identifier(Ljava/lang/String;)Ljava/lang/String;
  008a move-result-object v6
  008c invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0092 const-string v6, ")"
  0096 invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  009c invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00a2 move-result-object v5
  00a4 invoke-virtual v0, v5, v2, Landroid/database/sqlite/SQLiteDatabase;->rawQuery(Ljava/lang/String; [Ljava/lang/String;)Landroid/database/Cursor;
  00aa move-result-object v5
  00ac invoke-static v5, Lcom/personal/aihub/CreatorActivity;->rows(Landroid/database/Cursor;)Lorg/json/JSONArray;
  00b2 move-result-object v6
  00b4 invoke-virtual v1, v4, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00ba if-eqz v5, -038h
  00be invoke-interface v5, Landroid/database/Cursor;->close()V
  00c4 goto -3dh
  00c6 move-exception v1
  00c8 if-eqz v5, +00ah
  00cc invoke-interface v5, Landroid/database/Cursor;->close()V
  00d2 goto +5h
  00d4 move-exception v2
  00d6 invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  00dc throw v1
  00de if-eqz v3, +005h
  00e2 invoke-interface v3, Landroid/database/Cursor;->close()V
  00e8 iput-object v1, v7, Lcom/personal/aihub/CreatorActivity;->sparkingSchema Lorg/json/JSONObject;
  00ec iput-object v0, v7, Lcom/personal/aihub/CreatorActivity;->sparkingDb Landroid/database/sqlite/SQLiteDatabase;
  00f0 return-void 
  00f2 move-exception v1
  00f4 if-eqz v3, +00ah
  00f8 invoke-interface v3, Landroid/database/Cursor;->close()V
  00fe goto +5h
  0100 move-exception v2
  0102 invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0108 throw v1
  010a move-exception v1
  010c invoke-virtual v0, Landroid/database/sqlite/SQLiteDatabase;->close()V
  0112 throw v1
.end method

.method expandCpkResources(Ljava/io/File; I J)Lorg/json/JSONObject;
  0000 move-object/from16 v1, v25
  0004 const-string v2, " The original archive was kept."
  0008 const-string v3, ": "
  000c new-instance v0, Ljava/util/ArrayList;
  0010 invoke-direct v0, Ljava/util/ArrayList;-><init>()V
  0016 new-instance v4, Ljava/util/HashSet;
  001a invoke-direct v4, Ljava/util/HashSet;-><init>()V
  0020 new-instance v5, Ljava/util/ArrayDeque;
  0024 invoke-direct v5, Ljava/util/ArrayDeque;-><init>()V
  002a invoke-virtual v5, v1, Ljava/util/ArrayDeque;->add(Ljava/lang/Object;)Z
  0030 invoke-virtual v5, Ljava/util/ArrayDeque;->isEmpty()Z
  0036 move-result v6
  0038 const/4 v7, 0
  003a if-nez v6, +055h
  003e invoke-virtual v5, Ljava/util/ArrayDeque;->remove()Ljava/lang/Object;
  0044 move-result-object v6
  0046 check-cast v6, Ljava/io/File;
  004a invoke-virtual v6, Ljava/io/File;->listFiles()[Ljava/io/File;
  0050 move-result-object v6
  0052 if-nez v6, +003h
  0056 goto -13h
  0058 array-length v8, v6
  005a if-ge v7, v8, -015h
  005e aget-object v9, v6, v7
  0062 invoke-virtual v9, Ljava/io/File;->isDirectory()Z
  0068 move-result v10
  006a if-eqz v10, +006h
  006e invoke-virtual v5, v9, Ljava/util/ArrayDeque;->add(Ljava/lang/Object;)Z
  0074 goto +35h
  0076 invoke-virtual/range v25, Ljava/io/File;->toURI()Ljava/net/URI;
  007c move-result-object v10
  007e invoke-virtual v9, Ljava/io/File;->toURI()Ljava/net/URI;
  0084 move-result-object v11
  0086 invoke-virtual v10, v11, Ljava/net/URI;->relativize(Ljava/net/URI;)Ljava/net/URI;
  008c move-result-object v10
  008e invoke-virtual v10, Ljava/net/URI;->getPath()Ljava/lang/String;
  0094 move-result-object v10
  0096 sget-object v11, Ljava/text/Normalizer$Form;->NFC Ljava/text/Normalizer$Form;
  009a invoke-static v10, v11, Ljava/text/Normalizer;->normalize(Ljava/lang/CharSequence; Ljava/text/Normalizer$Form;)Ljava/lang/String;
  00a0 move-result-object v10
  00a2 sget-object v11, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  00a6 invoke-virtual v10, v11, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  00ac move-result-object v10
  00ae invoke-virtual v4, v10, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  00b4 invoke-virtual v9, Ljava/io/File;->getName()Ljava/lang/String;
  00ba move-result-object v10
  00bc sget-object v11, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  00c0 invoke-virtual v10, v11, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  00c6 move-result-object v10
  00c8 const-string v11, ".cpk"
  00cc invoke-virtual v10, v11, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  00d2 move-result v10
  00d4 if-eqz v10, +005h
  00d8 invoke-virtual v0, v9, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  00de add-int/lit8 v7, v7, 1
  00e2 goto -44h
  00e4 new-instance v5, Lorg/json/JSONArray;
  00e8 invoke-direct v5, Lorg/json/JSONArray;-><init>()V
  00ee const-wide v8, 4294967296
  00f8 cmp-long v6, v27, v8
  00fc if-gtz v6, +1ach
  0100 invoke-virtual v0, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
  0106 move-result-object v6
  0108 move/from16 v10, v26
  010c move-wide/from16 v11, v27
  0110 move v13, v7
  0112 invoke-interface v6, Ljava/util/Iterator;->hasNext()Z
  0118 move-result v0
  011a if-eqz v0, +17fh
  011e invoke-interface v6, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0124 move-result-object v0
  0126 check-cast v0, Ljava/io/File;
  012a invoke-virtual/range v25, Ljava/io/File;->toURI()Ljava/net/URI;
  0130 move-result-object v14
  0132 invoke-virtual v0, Ljava/io/File;->toURI()Ljava/net/URI;
  0138 move-result-object v15
  013a invoke-virtual v14, v15, Ljava/net/URI;->relativize(Ljava/net/URI;)Ljava/net/URI;
  0140 move-result-object v14
  0142 invoke-virtual v14, Ljava/net/URI;->getPath()Ljava/lang/String;
  0148 move-result-object v14
  014a new-instance v15, Lcom/personal/aihub/CpkArchive;
  014e invoke-direct v15, v0, Lcom/personal/aihub/CpkArchive;-><init>(Ljava/io/File;)V
  0154 invoke-virtual v14, Ljava/lang/String;->length()I
  015a move-result v0
  015c add-int/lit8 v0, v0, -4
  0160 invoke-virtual v14, v7, v0, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  0166 move-result-object v14
  0168 iget-object v0, v15, Lcom/personal/aihub/CpkArchive;->entries Ljava/util/List;
  016c invoke-interface v0, Ljava/util/List;->iterator()Ljava/util/Iterator;
  0172 move-result-object v16
  0174 invoke-interface/range v16, Ljava/util/Iterator;->hasNext()Z
  017a move-result v0
  017c if-eqz v0, +121h
  0180 invoke-interface/range v16, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0186 move-result-object v0
  0188 check-cast v0, Lcom/personal/aihub/CpkArchive$Entry;
  018c new-instance v7, Ljava/lang/StringBuilder;
  0190 invoke-direct v7, Ljava/lang/StringBuilder;-><init>()V
  0196 invoke-virtual v7, v14, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  019c const-string v8, "/"
  01a0 invoke-virtual v7, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01a6 iget-object v8, v0, Lcom/personal/aihub/CpkArchive$Entry;->path Ljava/lang/String;
  01aa invoke-virtual v7, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01b0 invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01b6 move-result-object v7
  01b8 invoke-static v7, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  01be move-result v8
  01c0 if-eqz v8, +0e5h
  01c4 sget-object v8, Ljava/text/Normalizer$Form;->NFC Ljava/text/Normalizer$Form;
  01c8 invoke-static v7, v8, Ljava/text/Normalizer;->normalize(Ljava/lang/CharSequence; Ljava/text/Normalizer$Form;)Ljava/lang/String;
  01ce move-result-object v8
  01d0 sget-object v9, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  01d4 invoke-virtual v8, v9, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  01da move-result-object v8
  01dc invoke-virtual v4, v8, Ljava/util/HashSet;->contains(Ljava/lang/Object;)Z
  01e2 move-result v9
  01e4 move-object/from16 v19, v6
  01e8 const-string v6, "Imported resources have conflicting destinations: "
  01ec if-nez v9, +0b5h
  01f0 const v9, 100000
  01f6 if-ge v10, v9, +0a3h
  01fa iget v9, v0, Lcom/personal/aihub/CpkArchive$Entry;->size I
  01fe move-object/from16 v20, v2
  0202 move-object/from16 v21, v3
  0206 int-to-long v2, v9
  0208 const-wide v17, 4294967296
  0212 sub-long v22, v17, v11
  0216 cmp-long v2, v2, v22
  021a if-gtz v2, +08ah
  021e invoke-virtual v15, v0, Lcom/personal/aihub/CpkArchive;->read(Lcom/personal/aihub/CpkArchive$Entry;)[B
  0224 move-result-object v0
  0226 new-instance v2, Ljava/io/File;
  022a invoke-direct v2, v1, v7, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0230 invoke-virtual v2, Ljava/io/File;->exists()Z
  0236 move-result v3
  0238 if-nez v3, +033h
  023c invoke-virtual v2, Ljava/io/File;->getParentFile()Ljava/io/File;
  0242 move-result-object v3
  0244 invoke-virtual v3, Ljava/io/File;->mkdirs()Z
  024a new-instance v3, Ljava/io/FileOutputStream;
  024e invoke-direct v3, v2, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0254 invoke-virtual v3, v0, Ljava/io/FileOutputStream;->write([B)V
  025a invoke-virtual v3, Ljava/io/FileOutputStream;->close()V
  0260 invoke-virtual v4, v8, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  0266 array-length v0, v0
  0268 int-to-long v2, v0
  026a add-long/2addr v11, v2
  026c add-int/lit8 v10, v10, 1
  0270 add-int/lit8 v13, v13, 1
  0274 move-wide/from16 v8, v17
  0278 move-object/from16 v6, v19
  027c move-object/from16 v2, v20
  0280 move-object/from16 v3, v21
  0284 goto +48h
  0286 move-exception v0
  0288 move-object v2, v0
  028a invoke-virtual v3, Ljava/io/FileOutputStream;->close()V
  0290 goto +6h
  0292 move-exception v0
  0294 move-object v3, v0
  0296 invoke-virtual v2, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  029c throw v2
  029e new-instance v0, Ljava/io/IOException;
  02a2 new-instance v2, Ljava/lang/StringBuilder;
  02a6 invoke-direct v2, Ljava/lang/StringBuilder;-><init>()V
  02ac invoke-virtual v2, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02b2 invoke-virtual v2, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02b8 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  02be move-result-object v2
  02c0 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02c6 throw v0
  02c8 move-exception v0
  02ca move-object v2, v0
  02cc new-instance v0, Ljava/lang/StringBuilder;
  02d0 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  02d6 invoke-virtual v0, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02dc move-object/from16 v3, v21
  02e0 invoke-virtual v0, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02e6 invoke-virtual v2, Ljava/io/IOException;->getMessage()Ljava/lang/String;
  02ec move-result-object v2
  02ee invoke-virtual v0, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02f4 move-object/from16 v2, v20
  02f8 invoke-virtual v0, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02fe invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0304 move-result-object v0
  0306 invoke-static v5, v0, Lcom/personal/aihub/CreatorActivity;->cpkWarning(Lorg/json/JSONArray; Ljava/lang/String;)V
  030c move-wide/from16 v8, v17
  0310 move-object/from16 v6, v19
  0314 const/4 v7, 0
  0316 goto/16 -0d1h
  031a move-exception v0
  031c move-object/from16 v2, v20
  0320 goto +59h
  0322 move-exception v0
  0324 move-object/from16 v2, v20
  0328 move-object/from16 v3, v21
  032c goto +53h
  032e move-object/from16 v2, v20
  0332 move-object/from16 v3, v21
  0336 goto +8h
  0338 move-exception v0
  033a goto +3ch
  033c const-wide v17, 4294967296
  0346 new-instance v0, Ljava/io/IOException;
  034a const-string v6, "Expanded CPK resources exceed the import limit"
  034e invoke-direct v0, v6, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0354 throw v0
  0356 const-wide v17, 4294967296
  0360 new-instance v0, Ljava/io/IOException;
  0364 new-instance v8, Ljava/lang/StringBuilder;
  0368 invoke-direct v8, Ljava/lang/StringBuilder;-><init>()V
  036e invoke-virtual v8, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0374 invoke-virtual v8, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  037a invoke-virtual v8, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0380 move-result-object v6
  0382 invoke-direct v0, v6, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0388 throw v0
  038a move-object/from16 v19, v6
  038e const-wide v17, 4294967296
  0398 new-instance v0, Ljava/io/IOException;
  039c const-string v6, "Unsafe expanded CPK path"
  03a0 invoke-direct v0, v6, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03a6 throw v0
  03a8 move-exception v0
  03aa goto +14h
  03ac move-exception v0
  03ae move-object/from16 v19, v6
  03b2 const-wide v17, 4294967296
  03bc goto +bh
  03be move-object/from16 v19, v6
  03c2 move-wide/from16 v17, v8
  03c6 goto +22h
  03c8 move-exception v0
  03ca move-object/from16 v19, v6
  03ce move-wide/from16 v17, v8
  03d2 new-instance v6, Ljava/lang/StringBuilder;
  03d6 invoke-direct v6, Ljava/lang/StringBuilder;-><init>()V
  03dc invoke-virtual v6, v14, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  03e2 invoke-virtual v6, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  03e8 invoke-virtual v0, Ljava/io/IOException;->getMessage()Ljava/lang/String;
  03ee move-result-object v0
  03f0 invoke-virtual v6, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  03f6 invoke-virtual v6, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  03fc invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0402 move-result-object v0
  0404 invoke-static v5, v0, Lcom/personal/aihub/CreatorActivity;->cpkWarning(Lorg/json/JSONArray; Ljava/lang/String;)V
  040a move-wide/from16 v8, v17
  040e move-object/from16 v6, v19
  0412 const/4 v7, 0
  0414 goto/16 -181h
  0418 new-instance v0, Lorg/json/JSONObject;
  041c invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  0422 const-string v1, "count"
  0426 invoke-virtual v0, v1, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  042c move-result-object v0
  042e const-string v1, "bytes"
  0432 invoke-virtual v0, v1, v11, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0438 move-result-object v0
  043a const-string v1, "expanded"
  043e invoke-virtual v0, v1, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0444 move-result-object v0
  0446 const-string v1, "warnings"
  044a invoke-virtual v0, v1, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0450 move-result-object v0
  0452 return-object v0
  0454 new-instance v0, Ljava/io/IOException;
  0458 const-string v1, "Resource import exceeds 4 GB"
  045c invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0462 throw v0
.end method

.method exportSource(Lorg/json/JSONObject; Ljava/io/File; I)Ljava/io/File;
  0000 const-string v0, "cpk"
  0004 invoke-virtual v5, v0, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  000a move-result v1
  000c const-string v2, "assetKey"
  0010 if-eqz v1, +048h
  0014 const-string v1, "path"
  0018 invoke-virtual v5, v1, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  001e move-result-object v1
  0020 const-string v3, ".cpk"
  0024 invoke-virtual v1, v3, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  002a move-result v1
  002c if-eqz v1, +032h
  0030 invoke-virtual v5, v2, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  0036 move-result v1
  0038 if-nez v1, +02ch
  003c const-string v1, "text"
  0040 invoke-virtual v5, v1, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  0046 move-result v1
  0048 if-nez v1, +024h
  004c new-instance v1, Ljava/io/File;
  0050 new-instance v2, Ljava/lang/StringBuilder;
  0054 invoke-direct v2, Ljava/lang/StringBuilder;-><init>()V
  005a invoke-static v7, Ljava/lang/String;->valueOf(I)Ljava/lang/String;
  0060 move-result-object v7
  0062 invoke-virtual v2, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0068 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  006e invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0074 move-result-object v7
  0076 invoke-direct v1, v6, v7, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  007c iget-object v6, v4, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  0080 invoke-virtual v5, v0, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0086 move-result-object v5
  0088 invoke-static v6, v5, v1, Lcom/personal/aihub/CpkWriter;->write(Ljava/io/File; Lorg/json/JSONArray; Ljava/io/File;)V
  008e return-object v1
  0090 new-instance v5, Ljava/io/IOException;
  0094 const-string v6, "Invalid packed artwork entry."
  0098 invoke-direct v5, v6, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  009e throw v5
  00a0 invoke-virtual v5, v2, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  00a6 move-result v6
  00a8 if-eqz v6, +00bh
  00ac invoke-virtual v5, v2, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  00b2 move-result-object v5
  00b4 invoke-virtual v4, v5, Lcom/personal/aihub/CreatorActivity;->assetFile(Ljava/lang/String;)Ljava/io/File;
  00ba move-result-object v5
  00bc return-object v5
  00be const/4 v5, 0
  00c0 return-object v5
.end method

.method fetchText(Ljava/lang/String; I)Ljava/lang/String;
  0000 invoke-direct v4, v5, Lcom/personal/aihub/CreatorActivity;->connection(Ljava/lang/String;)Ljava/net/HttpURLConnection;
  0006 move-result-object v5
  0008 invoke-virtual v5, Ljava/net/HttpURLConnection;->getInputStream()Ljava/io/InputStream;
  000e move-result-object v0
  0010 new-instance v1, Ljava/io/ByteArrayOutputStream;
  0014 invoke-direct v1, Ljava/io/ByteArrayOutputStream;-><init>()V
  001a int-to-long v2, v6
  001c invoke-static v0, v1, v2, v3, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  0022 const-string v6, "UTF-8"
  0026 invoke-virtual v1, v6, Ljava/io/ByteArrayOutputStream;->toString(Ljava/lang/String;)Ljava/lang/String;
  002c move-result-object v6
  002e invoke-virtual v1, Ljava/io/ByteArrayOutputStream;->close()V
  0034 if-eqz v0, +005h
  0038 invoke-virtual v0, Ljava/io/InputStream;->close()V
  003e invoke-virtual v5, Ljava/net/HttpURLConnection;->disconnect()V
  0044 return-object v6
  0046 move-exception v6
  0048 invoke-virtual v1, Ljava/io/ByteArrayOutputStream;->close()V
  004e goto +5h
  0050 move-exception v1
  0052 invoke-virtual v6, v1, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0058 throw v6
  005a move-exception v6
  005c if-eqz v0, +00ah
  0060 invoke-virtual v0, Ljava/io/InputStream;->close()V
  0066 goto +5h
  0068 move-exception v0
  006a invoke-virtual v6, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0070 throw v6
  0072 move-exception v6
  0074 invoke-virtual v5, Ljava/net/HttpURLConnection;->disconnect()V
  007a throw v6
.end method

.method hasSparkingAnimations(Lorg/json/JSONObject;)Z
  0000 const-string v0, "sourceDependencies"
  0004 invoke-virtual v1, v0, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  000a move-result-object v1
  000c if-nez v1, +004h
  0010 const/4 v1, 0
  0012 goto +7h
  0014 const-string v0, "animations"
  0018 invoke-virtual v1, v0, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  001e move-result-object v1
  0020 if-eqz v1, +00ah
  0024 invoke-virtual v1, Lorg/json/JSONArray;->length()I
  002a move-result v1
  002c if-lez v1, +004h
  0030 const/4 v1, 1
  0032 goto +2h
  0034 const/4 v1, 0
  0036 return v1
.end method

.method identifier(Ljava/lang/String;)Ljava/lang/String;
  0000 const-string v0, "[a-zA-Z_][a-zA-Z0-9_]*"
  0004 invoke-virtual v2, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  000a move-result v0
  000c if-eqz v0, +014h
  0010 new-instance v0, Ljava/lang/StringBuilder;
  0014 const-string v1, """
  0018 invoke-direct v0, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  001e invoke-virtual v0, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0024 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  002a invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0030 move-result-object v2
  0032 return-object v2
  0034 new-instance v2, Ljava/io/IOException;
  0038 const-string v0, "Invalid database name"
  003c invoke-direct v2, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0042 throw v2
.end method

.method importArchive(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 move-object/from16 v1, v17
  0004 new-instance v0, Ljava/lang/StringBuilder;
  0008 const-string v2, "import-"
  000c invoke-direct v0, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0012 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0018 move-result-object v2
  001a invoke-virtual v0, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0020 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0026 move-result-object v0
  0028 invoke-virtual v1, v0, Lcom/personal/aihub/CreatorActivity;->assetFile(Ljava/lang/String;)Ljava/io/File;
  002e move-result-object v2
  0030 invoke-virtual v2, Ljava/io/File;->mkdirs()Z
  0036 new-instance v0, Ljava/util/HashSet;
  003a invoke-direct v0, Ljava/util/HashSet;-><init>()V
  0040 new-instance v3, Ljava/util/zip/ZipFile;
  0044 move-object/from16 v4, v18
  0048 invoke-direct v3, v4, Ljava/util/zip/ZipFile;-><init>(Ljava/io/File;)V
  004e invoke-virtual v3, Ljava/util/zip/ZipFile;->entries()Ljava/util/Enumeration;
  0054 move-result-object v4
  0056 const-wide/16 v6, 0
  005a const/4 v8, 0
  005c const/4 v9, 0
  005e const/4 v10, 0
  0060 invoke-interface v4, Ljava/util/Enumeration;->hasMoreElements()Z
  0066 move-result v11
  0068 const/4 v12, 1
  006a if-eqz v11, +0f8h
  006e invoke-interface v4, Ljava/util/Enumeration;->nextElement()Ljava/lang/Object;
  0074 move-result-object v11
  0076 check-cast v11, Ljava/util/zip/ZipEntry;
  007a add-int/2addr v10, v12
  007c const v12, 100000
  0082 if-gt v10, v12, +0e4h
  0086 invoke-virtual v11, Ljava/util/zip/ZipEntry;->isDirectory()Z
  008c move-result v13
  008e if-eqz v13, +003h
  0092 goto -19h
  0094 invoke-virtual v11, Ljava/util/zip/ZipEntry;->getName()Ljava/lang/String;
  009a move-result-object v13
  009c invoke-static v13, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  00a2 move-result v14
  00a4 if-eqz v14, +0cbh
  00a8 const-string v14, "(?i).*\.(db|sqlite|sqlite3)$"
  00ac invoke-virtual v13, v14, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  00b2 move-result v14
  00b4 if-nez v14, +00bh
  00b8 const-string v15, "(?i).*\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$"
  00bc invoke-virtual v13, v15, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  00c2 move-result v15
  00c4 if-nez v15, +003h
  00c8 goto -34h
  00ca add-int/lit8 v9, v9, 1
  00ce if-gt v9, v12, +0aeh
  00d2 if-eqz v14, +01dh
  00d6 new-instance v12, Ljava/lang/StringBuilder;
  00da invoke-direct v12, Ljava/lang/StringBuilder;-><init>()V
  00e0 const-string v15, "_databases/"
  00e4 invoke-virtual v12, v15, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00ea new-instance v15, Ljava/io/File;
  00ee invoke-direct v15, v13, Ljava/io/File;-><init>(Ljava/lang/String;)V
  00f4 invoke-virtual v15, Ljava/io/File;->getName()Ljava/lang/String;
  00fa move-result-object v15
  00fc invoke-virtual v12, v15, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0102 invoke-virtual v12, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0108 move-result-object v12
  010a goto +5h
  010c invoke-static v13, Lcom/personal/aihub/CreatorActivity;->normalizeAsset(Ljava/lang/String;)Ljava/lang/String;
  0112 move-result-object v12
  0114 sget-object v15, Ljava/text/Normalizer$Form;->NFC Ljava/text/Normalizer$Form;
  0118 invoke-static v12, v15, Ljava/text/Normalizer;->normalize(Ljava/lang/CharSequence; Ljava/text/Normalizer$Form;)Ljava/lang/String;
  011e move-result-object v15
  0120 sget-object v5, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  0124 invoke-virtual v15, v5, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  012a move-result-object v5
  012c invoke-virtual v0, v5, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  0132 move-result v5
  0134 if-eqz v5, +073h
  0138 new-instance v5, Ljava/io/File;
  013c invoke-direct v5, v2, v12, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0142 invoke-virtual v5, Ljava/io/File;->getParentFile()Ljava/io/File;
  0148 move-result-object v12
  014a invoke-virtual v12, Ljava/io/File;->mkdirs()Z
  0150 invoke-virtual v3, v11, Ljava/util/zip/ZipFile;->getInputStream(Ljava/util/zip/ZipEntry;)Ljava/io/InputStream;
  0156 move-result-object v11
  0158 new-instance v12, Ljava/io/FileOutputStream;
  015c invoke-direct v12, v5, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0162 move/from16 v16, v9
  0166 move v15, v10
  0168 const-wide/32 v9, 1073741824
  016e invoke-static v11, v12, v9, v10, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  0174 invoke-virtual v12, Ljava/io/FileOutputStream;->close()V
  017a if-eqz v11, +005h
  017e invoke-virtual v11, Ljava/io/InputStream;->close()V
  0184 invoke-virtual v5, Ljava/io/File;->length()J
  018a move-result-wide v9
  018c add-long/2addr v6, v9
  018e const-wide v9, 4294967296
  0198 cmp-long v9, v6, v9
  019c if-gtz v9, +01dh
  01a0 if-eqz v14, +016h
  01a4 invoke-direct v1, v5, Lcom/personal/aihub/CreatorActivity;->verifyDb(Ljava/io/File;)V
  01aa if-eqz v8, +010h
  01ae sget-object v9, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  01b2 invoke-virtual v13, v9, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  01b8 move-result-object v9
  01ba const-string v10, "decrypted"
  01be invoke-virtual v9, v10, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  01c4 move-result v9
  01c6 if-eqz v9, +003h
  01ca move-object v8, v5
  01cc move v10, v15
  01ce move/from16 v9, v16
  01d2 goto/16 -0b9h
  01d6 new-instance v0, Ljava/io/IOException;
  01da const-string v4, "Resource import is larger than 4 GB"
  01de invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01e4 throw v0
  01e6 move-exception v0
  01e8 move-object v4, v0
  01ea invoke-virtual v12, Ljava/io/FileOutputStream;->close()V
  01f0 goto +6h
  01f2 move-exception v0
  01f4 move-object v5, v0
  01f6 invoke-virtual v4, v5, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  01fc throw v4
  01fe move-exception v0
  0200 move-object v4, v0
  0202 if-eqz v11, +00bh
  0206 invoke-virtual v11, Ljava/io/InputStream;->close()V
  020c goto +6h
  020e move-exception v0
  0210 move-object v5, v0
  0212 invoke-virtual v4, v5, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0218 throw v4
  021a new-instance v0, Ljava/io/IOException;
  021e const-string v4, "Archive contains conflicting resource paths"
  0222 invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0228 throw v0
  022a new-instance v0, Ljava/io/IOException;
  022e const-string v4, "Archive contains too many files"
  0232 invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0238 throw v0
  023a new-instance v0, Ljava/io/IOException;
  023e const-string v4, "Archive contains an unsafe file path"
  0242 invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0248 throw v0
  024a new-instance v0, Ljava/io/IOException;
  024e const-string v4, "Archive contains too many entries"
  0252 invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0258 throw v0
  025a invoke-virtual v3, Ljava/util/zip/ZipFile;->close()V
  0260 invoke-direct v1, v2, v9, v6, v7, Lcom/personal/aihub/CreatorActivity;->expandCpkResources(Ljava/io/File; I J)Lorg/json/JSONObject;
  0266 move-result-object v0
  0268 if-eqz v8, +007h
  026c move-object/from16 v3, v19
  0270 invoke-direct v1, v8, v3, Lcom/personal/aihub/CreatorActivity;->useDb(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0276 const-string v3, "kind"
  027a const-string v4, "archive"
  027e invoke-virtual v0, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0284 move-result-object v0
  0286 const-string v3, "database"
  028a if-eqz v8, +004h
  028e move v5, v12
  0290 goto +2h
  0292 const/4 v5, 0
  0294 invoke-virtual v0, v3, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  029a move-result-object v0
  029c const-string v3, "note"
  02a0 if-eqz v8, +005h
  02a4 const-string v4, "Readable game database imported."
  02a8 goto +3h
  02aa const-string v4, "No readable game database found; the previous database was kept. Resource files were imported where available."
  02ae invoke-virtual v0, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02b4 move-result-object v0
  02b6 return-object v0
  02b8 move-exception v0
  02ba move-object v4, v0
  02bc invoke-virtual v3, Ljava/util/zip/ZipFile;->close()V
  02c2 goto +6h
  02c4 move-exception v0
  02c6 move-object v3, v0
  02c8 invoke-virtual v4, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  02ce throw v4
  02d0 move-exception v0
  02d2 invoke-static v2, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  02d8 new-instance v2, Ljava/io/IOException;
  02dc new-instance v3, Ljava/lang/StringBuilder;
  02e0 const-string v4, "Could not import this ZIP/APK. "
  02e4 invoke-direct v3, v4, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  02ea invoke-virtual v0, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  02f0 move-result-object v4
  02f2 invoke-virtual v3, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02f8 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  02fe move-result-object v3
  0300 invoke-direct v2, v3, v0, Ljava/io/IOException;-><init>(Ljava/lang/String; Ljava/lang/Throwable;)V
  0306 throw v2
.end method

.method importEclipseApk(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 move-object/from16 v8, v30
  0004 const-string v0, "warnings"
  0008 const-string v9, "expanded"
  000c const-string v10, "bytes"
  0010 const-string v11, "count"
  0014 const-string v12, "apk"
  0018 const-wide/16 v4, 0
  001c const-wide/16 v6, 0
  0020 const-string v2, "inspect"
  0024 const-string v3, "Checking Eclipse APK"
  0028 move-object/from16 v1, v30
  002c invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  0032 invoke-direct/range v30 ... v32, Lcom/personal/aihub/CreatorActivity;->inspectEclipseApk(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0038 move-result-object v13
  003a invoke-direct/range v30, Lcom/personal/aihub/CreatorActivity;->ensureDb()V
  0040 new-instance v1, Ljava/lang/StringBuilder;
  0044 const-string v2, "apk-"
  0048 invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  004e invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0054 move-result-object v2
  0056 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  005c invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0062 move-result-object v14
  0064 invoke-virtual v8, v14, Lcom/personal/aihub/CreatorActivity;->assetFile(Ljava/lang/String;)Ljava/io/File;
  006a move-result-object v15
  006c new-instance v6, Ljava/io/File;
  0070 invoke-virtual/range v30, Lcom/personal/aihub/CreatorActivity;->getCacheDir()Ljava/io/File;
  0076 move-result-object v1
  0078 new-instance v2, Ljava/lang/StringBuilder;
  007c const-string v3, "apk-work-"
  0080 invoke-direct v2, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0086 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  008c move-result-object v3
  008e invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0094 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  009a move-result-object v2
  009c invoke-direct v6, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00a2 invoke-virtual v15, Ljava/io/File;->mkdirs()Z
  00a8 invoke-virtual v6, Ljava/io/File;->mkdirs()Z
  00ae new-instance v7, Ljava/util/ArrayList;
  00b2 invoke-direct v7, Ljava/util/ArrayList;-><init>()V
  00b8 new-instance v4, Ljava/util/HashMap;
  00bc invoke-direct v4, Ljava/util/HashMap;-><init>()V
  00c2 new-instance v5, Ljava/util/HashSet;
  00c6 invoke-direct v5, Ljava/util/HashSet;-><init>()V
  00cc const-string v2, "extract"
  00d0 const-string v3, "Reading APK database and resources"
  00d4 const-wide/16 v16, 0
  00d8 const-wide/16 v18, 0
  00dc move-object/from16 v1, v30
  00e0 move-object/from16 v20, v0
  00e4 move-object v0, v4
  00e6 move-object/from16 v21, v9
  00ea move-object v9, v5
  00ec move-wide/from16 v4, v16
  00f0 move-object/from16 v16, v6
  00f4 move-object/from16 v17, v7
  00f8 move-wide/from16 v6, v18
  00fc invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  0102 new-instance v1, Ljava/util/zip/ZipFile;
  0106 move-object/from16 v2, v31
  010a invoke-direct v1, v2, Ljava/util/zip/ZipFile;-><init>(Ljava/io/File;)V
  0110 invoke-virtual v1, Ljava/util/zip/ZipFile;->entries()Ljava/util/Enumeration;
  0116 move-result-object v2
  0118 const/4 v3, 0
  011a const-wide/16 v4, 0
  011e move-wide v6, v4
  0120 move v4, v3
  0122 move v5, v4
  0124 invoke-interface v2, Ljava/util/Enumeration;->hasMoreElements()Z
  012a move-result v18
  012c move/from16 v31, v5
  0130 const/4 v5, 1
  0132 if-eqz v18, +13eh
  0136 invoke-interface v2, Ljava/util/Enumeration;->nextElement()Ljava/lang/Object;
  013c move-result-object v18
  013e move-object/from16 v19, v2
  0142 move-object/from16 v2, v18
  0146 check-cast v2, Ljava/util/zip/ZipEntry;
  014a add-int/2addr v4, v5
  014c const v5, 100000
  0152 if-gt v4, v5, +120h
  0156 invoke-virtual v2, Ljava/util/zip/ZipEntry;->isDirectory()Z
  015c move-result v5
  015e if-eqz v5, +007h
  0162 move/from16 v22, v4
  0166 move-object/from16 v23, v14
  016a goto +2fh
  016c invoke-virtual v2, Ljava/util/zip/ZipEntry;->getName()Ljava/lang/String;
  0172 move-result-object v5
  0174 invoke-static v5, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  017a move-result v22
  017c if-eqz v22, +103h
  0180 move/from16 v22, v4
  0184 const-string v4, "assets/(sqlite/current/en/database(_decrypted)?\.db|database\.db)"
  0188 invoke-virtual v5, v4, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  018e move-result v4
  0190 if-nez v4, +025h
  0194 move-object/from16 v23, v14
  0198 const-string v14, "assets/"
  019c invoke-virtual v5, v14, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  01a2 move-result v14
  01a4 if-eqz v14, +012h
  01a8 const-string v14, "assets/(patcher|dexopt|org)/.*"
  01ac invoke-virtual v5, v14, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  01b2 move-result v14
  01b4 if-nez v14, +00ah
  01b8 const-string v14, "(?i).*\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$"
  01bc invoke-virtual v5, v14, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  01c2 move-result v14
  01c4 if-nez v14, +00dh
  01c8 move/from16 v5, v31
  01cc move-object/from16 v2, v19
  01d0 move/from16 v4, v22
  01d4 move-object/from16 v14, v23
  01d8 goto -5ah
  01da move-object/from16 v23, v14
  01de invoke-virtual v2, Ljava/util/zip/ZipEntry;->getSize()J
  01e4 move-result-wide v24
  01e6 move-object v14, v12
  01e8 move-object/from16 v26, v13
  01ec const-wide/32 v12, 536870912
  01f2 cmp-long v24, v24, v12
  01f6 if-gtz v24, +0beh
  01fa if-eqz v4, +01dh
  01fe new-instance v12, Ljava/lang/StringBuilder;
  0202 invoke-direct v12, Ljava/lang/StringBuilder;-><init>()V
  0208 const-string v13, "database-"
  020c invoke-virtual v12, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0212 invoke-virtual/range v17, Ljava/util/ArrayList;->size()I
  0218 move-result v13
  021a invoke-virtual v12, v13, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  0220 const-string v13, ".db"
  0224 invoke-virtual v12, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  022a invoke-virtual v12, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0230 move-result-object v12
  0232 goto +5h
  0234 invoke-static v5, Lcom/personal/aihub/CreatorActivity;->normalizeAsset(Ljava/lang/String;)Ljava/lang/String;
  023a move-result-object v12
  023c sget-object v13, Ljava/text/Normalizer$Form;->NFC Ljava/text/Normalizer$Form;
  0240 invoke-static v12, v13, Ljava/text/Normalizer;->normalize(Ljava/lang/CharSequence; Ljava/text/Normalizer$Form;)Ljava/lang/String;
  0246 move-result-object v13
  0248 move-object/from16 v27, v14
  024c sget-object v14, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  0250 invoke-virtual v13, v14, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  0256 move-result-object v13
  0258 invoke-virtual v9, v13, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  025e move-result v13
  0260 if-eqz v13, +081h
  0264 new-instance v13, Ljava/io/File;
  0268 if-eqz v4, +005h
  026c move-object/from16 v14, v16
  0270 goto +2h
  0272 move-object v14, v15
  0274 invoke-direct v13, v14, v12, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  027a invoke-virtual v13, Ljava/io/File;->getParentFile()Ljava/io/File;
  0280 move-result-object v12
  0282 invoke-virtual v12, Ljava/io/File;->mkdirs()Z
  0288 invoke-virtual v1, v2, Ljava/util/zip/ZipFile;->getInputStream(Ljava/util/zip/ZipEntry;)Ljava/io/InputStream;
  028e move-result-object v2
  0290 new-instance v12, Ljava/io/FileOutputStream;
  0294 invoke-direct v12, v13, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  029a move-object/from16 v28, v9
  029e move-object v14, v10
  02a0 const-wide/32 v9, 536870912
  02a6 invoke-static v2, v12, v9, v10, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  02ac invoke-virtual v12, Ljava/io/FileOutputStream;->close()V
  02b2 if-eqz v2, +005h
  02b6 invoke-virtual v2, Ljava/io/InputStream;->close()V
  02bc invoke-virtual v13, Ljava/io/File;->length()J
  02c2 move-result-wide v9
  02c4 add-long/2addr v6, v9
  02c6 const-wide v9, 4294967296
  02d0 cmp-long v2, v6, v9
  02d4 if-gtz v2, +025h
  02d8 if-eqz v4, +00ch
  02dc move-object/from16 v2, v17
  02e0 invoke-virtual v2, v13, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  02e6 invoke-virtual v0, v13, v5, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  02ec const/4 v5, 1
  02ee goto +7h
  02f0 move-object/from16 v2, v17
  02f4 add-int/lit8 v3, v3, 1
  02f8 move/from16 v5, v31
  02fc move-object/from16 v17, v2
  0300 move-object v10, v14
  0302 move-object/from16 v2, v19
  0306 move/from16 v4, v22
  030a move-object/from16 v14, v23
  030e move-object/from16 v13, v26
  0312 move-object/from16 v12, v27
  0316 move-object/from16 v9, v28
  031a goto/16 -0fbh
  031e new-instance v0, Ljava/io/IOException;
  0322 const-string v2, "APK resources exceed 4 GB"
  0326 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  032c throw v0
  032e move-exception v0
  0330 move-object v3, v0
  0332 invoke-virtual v12, Ljava/io/FileOutputStream;->close()V
  0338 goto +6h
  033a move-exception v0
  033c move-object v4, v0
  033e invoke-virtual v3, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0344 throw v3
  0346 move-exception v0
  0348 move-object v3, v0
  034a if-eqz v2, +00bh
  034e invoke-virtual v2, Ljava/io/InputStream;->close()V
  0354 goto +6h
  0356 move-exception v0
  0358 move-object v2, v0
  035a invoke-virtual v3, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0360 throw v3
  0362 new-instance v0, Ljava/io/IOException;
  0366 const-string v2, "Conflicting APK resource paths"
  036a invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0370 throw v0
  0372 new-instance v0, Ljava/io/IOException;
  0376 const-string v2, "APK resource exceeds 512 MB"
  037a invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0380 throw v0
  0382 new-instance v0, Ljava/io/IOException;
  0386 const-string v2, "Unsafe APK file path"
  038a invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0390 throw v0
  0392 new-instance v0, Ljava/io/IOException;
  0396 const-string v2, "Too many APK entries"
  039a invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03a0 throw v0
  03a2 move-exception v0
  03a4 move-object v2, v0
  03a6 move-object/from16 v17, v15
  03aa goto/16 +156h
  03ae move-object/from16 v27, v12
  03b2 move-object/from16 v26, v13
  03b6 move-object/from16 v23, v14
  03ba move-object/from16 v2, v17
  03be move-object v14, v10
  03c0 invoke-virtual v1, Ljava/util/zip/ZipFile;->close()V
  03c6 invoke-direct v8, v15, v3, v6, v7, Lcom/personal/aihub/CreatorActivity;->expandCpkResources(Ljava/io/File; I J)Lorg/json/JSONObject;
  03cc move-result-object v9
  03ce invoke-virtual v9, v11, Lorg/json/JSONObject;->getInt(Ljava/lang/String;)I
  03d4 move-result v10
  03d6 move-object v12, v14
  03d8 invoke-virtual v9, v12, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  03de move-result-wide v13
  03e0 new-instance v1, Lcom/personal/aihub/CreatorActivity$10;
  03e4 invoke-direct v1, v8, v0, Lcom/personal/aihub/CreatorActivity$10;-><init>(Lcom/personal/aihub/CreatorActivity; Ljava/util/HashMap;)V
  03ea invoke-virtual v2, v1, Ljava/util/ArrayList;->sort(Ljava/util/Comparator;)V
  03f0 invoke-virtual v2, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
  03f6 move-result-object v1
  03f8 invoke-interface v1, Ljava/util/Iterator;->hasNext()Z
  03fe move-result v2
  0400 if-eqz v2, +039h
  0404 invoke-interface v1, Ljava/util/Iterator;->next()Ljava/lang/Object;
  040a move-result-object v2
  040c check-cast v2, Ljava/io/File;
  0410 const/16 v3, 16
  0414 new-array v3, v3, [B
  0418 new-instance v4, Ljava/io/FileInputStream;
  041c invoke-direct v4, v2, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0422 invoke-virtual v4, v3, Ljava/io/FileInputStream;->read([B)I
  0428 invoke-virtual v4, Ljava/io/FileInputStream;->close()V
  042e new-instance v4, Ljava/lang/String;
  0432 sget-object v5, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0436 invoke-direct v4, v3, v5, Ljava/lang/String;-><init>([B Ljava/nio/charset/Charset;)V
  043c const-string v3, "SQLite format 3 "
  0440 invoke-virtual v4, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0446 move-result v3
  0448 if-eqz v3, +007h
  044c const/4 v4, 1
  044e invoke-direct v8, v2, v4, Lcom/personal/aihub/CreatorActivity;->verifyDb(Ljava/io/File; Z)J
  0454 goto +11h
  0456 const/4 v4, 1
  0458 goto -30h
  045a move-exception v0
  045c move-object v1, v0
  045e invoke-virtual v4, Ljava/io/FileInputStream;->close()V
  0464 goto +6h
  0466 move-exception v0
  0468 move-object v2, v0
  046a invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0470 throw v1
  0472 const/4 v4, 1
  0474 const/4 v2, 0
  0476 move-object v6, v2
  0478 const-string v1, "resourceCount"
  047c move-object/from16 v7, v26
  0480 invoke-virtual v7, v1, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0486 new-instance v1, Lorg/json/JSONObject;
  048a invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  0490 move-object/from16 v5, v27
  0494 invoke-virtual v1, v5, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  049a move-result-object v1
  049c const-string v2, "resourceGroup"
  04a0 move-object/from16 v3, v23
  04a4 invoke-virtual v1, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  04aa move-result-object v3
  04ac const-string v2, "embedded"
  04b0 const-string v1, "embeddedDatabase"
  04b4 if-eqz v6, +04bh
  04b8 invoke-virtual v0, v6, Ljava/util/HashMap;->get(Ljava/lang/Object;)Ljava/lang/Object;
  04be move-result-object v0
  04c0 invoke-virtual v7, v1, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  04c6 const-string v0, "sourceType"
  04ca const-string v1, "apk-embedded"
  04ce invoke-virtual v3, v0, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  04d4 const-string v0, "verify"
  04d8 const-string v17, "Validating the database inside the APK"
  04dc const-wide/16 v18, 0
  04e0 const-wide/16 v22, 0
  04e4 move-object/from16 v1, v30
  04e8 move-object/from16 v29, v2
  04ec move-object v2, v0
  04ee move-object v0, v3
  04f0 move-object/from16 v3, v17
  04f4 move-object/from16 v24, v9
  04f8 move-object/from16 v17, v15
  04fc move v9, v4
  04fe move-object v15, v5
  0500 move-wide/from16 v4, v18
  0504 move-object v9, v7
  0506 move-object/from16 v19, v12
  050a move-object v12, v6
  050c move-wide/from16 v6, v22
  0510 invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  0516 new-instance v1, Ljava/lang/StringBuilder;
  051a invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  0520 const-string v2, "Database inside "
  0524 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  052a move-object/from16 v2, v32
  052e invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0534 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  053a move-result-object v1
  053c invoke-direct v8, v12, v1, v0, Lcom/personal/aihub/CreatorActivity;->useDb(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0542 move-result-object v0
  0544 move-object/from16 v12, v29
  0548 goto +1dh
  054a move-object/from16 v29, v2
  054e move-object v0, v3
  0550 move-object/from16 v24, v9
  0554 move-object/from16 v19, v12
  0558 move-object/from16 v17, v15
  055c move-object v15, v5
  055e move-object v9, v7
  0560 if-eqz v31, +005h
  0564 const-string v2, "starter-or-encrypted"
  0568 goto +3h
  056a const-string v2, "not-included"
  056e invoke-virtual v9, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0574 invoke-direct v8, v0, Lcom/personal/aihub/CreatorActivity;->downloadCurrentDatabase(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  057a move-result-object v0
  057c const-string v2, "downloaded"
  0580 move-object v12, v2
  0582 const-string v2, "done"
  0586 const-string v3, "Eclipse APK imported; game data ready"
  058a const-wide/16 v4, 0
  058e const-wide/16 v6, 0
  0592 move-object/from16 v1, v30
  0596 invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  059c new-instance v1, Lorg/json/JSONObject;
  05a0 invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  05a6 const-string v2, "kind"
  05aa invoke-virtual v1, v2, v15, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  05b0 move-result-object v1
  05b2 const-string v2, "database"
  05b6 const/4 v3, 1
  05b8 invoke-virtual v1, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  05be move-result-object v1
  05c0 const-string v2, "mode"
  05c4 invoke-virtual v1, v2, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  05ca move-result-object v1
  05cc invoke-virtual v1, v15, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  05d2 move-result-object v1
  05d4 invoke-virtual v1, v11, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  05da move-result-object v1
  05dc move-object/from16 v2, v19
  05e0 invoke-virtual v1, v2, v13, v14, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  05e6 move-result-object v1
  05e8 move-object/from16 v3, v21
  05ec move-object/from16 v2, v24
  05f0 invoke-virtual v2, v3, Lorg/json/JSONObject;->getInt(Ljava/lang/String;)I
  05f6 move-result v4
  05f8 invoke-virtual v1, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  05fe move-result-object v1
  0600 move-object/from16 v3, v20
  0604 invoke-virtual v2, v3, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  060a move-result-object v2
  060c invoke-virtual v1, v3, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0612 move-result-object v1
  0614 const-string v2, "info"
  0618 invoke-virtual v1, v2, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  061e move-result-object v0
  0620 const-string v1, "note"
  0624 move-object/from16 v2, v29
  0628 invoke-virtual v12, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  062e move-result v2
  0630 if-eqz v2, +005h
  0634 const-string v2, "APK database validated and activated. Saved units were kept."
  0638 goto +3h
  063a const-string v2, "The APK contains starter or encrypted data. Eclipse’s current full English database was downloaded and validated; saved units were kept."
  063e invoke-virtual v0, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0644 move-result-object v0
  0646 invoke-static/range v16, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  064c return-object v0
  064e move-exception v0
  0650 move-object/from16 v17, v15
  0654 move-object v2, v0
  0656 invoke-virtual v1, Ljava/util/zip/ZipFile;->close()V
  065c goto +6h
  065e move-exception v0
  0660 move-object v1, v0
  0662 invoke-virtual v2, v1, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0668 throw v2
  066a move-exception v0
  066c goto +ch
  066e move-exception v0
  0670 goto +8h
  0672 move-exception v0
  0674 move-object/from16 v16, v6
  0678 goto +36h
  067a move-exception v0
  067c move-object/from16 v16, v6
  0680 move-object/from16 v17, v15
  0684 invoke-static/range v17, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  068a const-string v2, "error"
  068e const-string v3, "Update failed; previous data and saved units were kept"
  0692 const-wide/16 v4, 0
  0696 const-wide/16 v6, 0
  069a move-object/from16 v1, v30
  069e invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  06a4 new-instance v1, Ljava/io/IOException;
  06a8 new-instance v2, Ljava/lang/StringBuilder;
  06ac invoke-direct v2, Ljava/lang/StringBuilder;-><init>()V
  06b2 invoke-virtual v0, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  06b8 move-result-object v3
  06ba invoke-static v3, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  06c0 move-result-object v3
  06c2 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  06c8 const-string v3, " Your previous database and saved units were kept."
  06cc invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  06d2 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  06d8 move-result-object v2
  06da invoke-direct v1, v2, v0, Ljava/io/IOException;-><init>(Ljava/lang/String; Ljava/lang/Throwable;)V
  06e0 throw v1
  06e2 move-exception v0
  06e4 invoke-static/range v16, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  06ea throw v0
.end method

.method importEclp(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 move-object/from16 v1, v19
  0004 move-object/from16 v0, v21
  0008 const-string v2, "author"
  000c const-string v3, "version"
  0010 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0016 move-result-object v4
  0018 invoke-virtual v4, Ljava/util/UUID;->toString()Ljava/lang/String;
  001e move-result-object v4
  0020 new-instance v5, Ljava/lang/StringBuilder;
  0024 const-string v6, "patch-"
  0028 invoke-direct v5, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  002e invoke-virtual v5, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0034 invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  003a move-result-object v5
  003c invoke-virtual v1, v5, Lcom/personal/aihub/CreatorActivity;->assetFile(Ljava/lang/String;)Ljava/io/File;
  0042 move-result-object v5
  0044 invoke-virtual v5, Ljava/io/File;->mkdirs()Z
  004a invoke-direct v1, v4, Lcom/personal/aihub/CreatorActivity;->patchFile(Ljava/lang/String;)Ljava/io/File;
  0050 move-result-object v12
  0052 new-instance v13, Ljava/io/File;
  0056 invoke-virtual v12, Ljava/io/File;->getParentFile()Ljava/io/File;
  005c move-result-object v6
  005e new-instance v7, Ljava/lang/StringBuilder;
  0062 invoke-direct v7, Ljava/lang/StringBuilder;-><init>()V
  0068 invoke-virtual v7, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  006e const-string v8, ".json"
  0072 invoke-virtual v7, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0078 invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  007e move-result-object v7
  0080 invoke-direct v13, v6, v7, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0086 new-instance v14, Lorg/json/JSONObject;
  008a invoke-static/range v20, Lcom/personal/aihub/EclpCodec;->header(Ljava/io/File;)Lcom/personal/aihub/EclpCodec$Header;
  0090 move-result-object v6
  0092 iget-object v6, v6, Lcom/personal/aihub/EclpCodec$Header;->metadata Ljava/lang/String;
  0096 invoke-direct v14, v6, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  009c invoke-virtual/range v19, Lcom/personal/aihub/CreatorActivity;->getCacheDir()Ljava/io/File;
  00a2 move-result-object v8
  00a4 const-string v6, "uuid"
  00a8 invoke-virtual v14, v6, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  00ae move-result-object v9
  00b0 const-string v6, "name"
  00b4 invoke-virtual v14, v6, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  00ba move-result-object v10
  00bc invoke-virtual v14, v3, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  00c2 move-result-object v11
  00c4 move-object/from16 v6, v20
  00c8 move-object v7, v5
  00ca invoke-static/range v6 ... v11, Lcom/personal/aihub/EclpCodec;->extract(Ljava/io/File; Ljava/io/File; Ljava/io/File; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)Ljava/util/List;
  00d0 move-result-object v6
  00d2 new-instance v7, Lorg/json/JSONArray;
  00d6 invoke-direct v7, Lorg/json/JSONArray;-><init>()V
  00dc invoke-interface v6, Ljava/util/List;->iterator()Ljava/util/Iterator;
  00e2 move-result-object v8
  00e4 const-wide/16 v9, 0
  00e8 invoke-interface v8, Ljava/util/Iterator;->hasNext()Z
  00ee move-result v11
  00f0 if-eqz v11, +041h
  00f4 invoke-interface v8, Ljava/util/Iterator;->next()Ljava/lang/Object;
  00fa move-result-object v11
  00fc check-cast v11, Lcom/personal/aihub/EclpCodec$Entry;
  0100 new-instance v15, Lorg/json/JSONObject;
  0104 invoke-direct v15, Lorg/json/JSONObject;-><init>()V
  010a move-object/from16 v16, v8
  010e const-string v8, "path"
  0112 iget-object v1, v11, Lcom/personal/aihub/EclpCodec$Entry;->path Ljava/lang/String;
  0116 invoke-virtual v15, v8, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  011c move-result-object v1
  011e const-string v8, "size"
  0122 iget-object v15, v11, Lcom/personal/aihub/EclpCodec$Entry;->file Ljava/io/File;
  0126 move-object/from16 v17, v12
  012a move-object/from16 v18, v13
  012e invoke-virtual v15, Ljava/io/File;->length()J
  0134 move-result-wide v12
  0136 invoke-virtual v1, v8, v12, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  013c move-result-object v1
  013e invoke-virtual v7, v1, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0144 iget-object v1, v11, Lcom/personal/aihub/EclpCodec$Entry;->file Ljava/io/File;
  0148 invoke-virtual v1, Ljava/io/File;->length()J
  014e move-result-wide v11
  0150 add-long/2addr v9, v11
  0152 move-object/from16 v1, v19
  0156 move-object/from16 v8, v16
  015a move-object/from16 v12, v17
  015e move-object/from16 v13, v18
  0162 goto -3dh
  0164 move-exception v0
  0166 move-object/from16 v17, v12
  016a move-object/from16 v18, v13
  016e goto/16 +171h
  0172 move-object/from16 v17, v12
  0176 move-object/from16 v18, v13
  017a new-instance v1, Ljava/io/File;
  017e const-string v8, "forge-project.json"
  0182 invoke-direct v1, v5, v8, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0188 invoke-static Lcom/personal/aihub/CreatorActivity;->isoStamp()Ljava/lang/String;
  018e move-result-object v8
  0190 invoke-virtual v1, Ljava/io/File;->isFile()Z
  0196 move-result v11
  0198 const-string v12, "importedAt"
  019c const-string v13, "key"
  01a0 if-eqz v11, +08ch
  01a4 new-instance v11, Lorg/json/JSONObject;
  01a8 const/high16 v15, 20971520
  01ac invoke-static v1, v15, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  01b2 move-result-object v1
  01b4 invoke-direct v11, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  01ba const-string v1, "format"
  01be invoke-virtual v11, v1, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  01c4 move-result-object v1
  01c6 const-string v15, "dokkan-unit-forge"
  01ca invoke-virtual v1, v15, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01d0 move-result v1
  01d2 if-eqz v1, +06bh
  01d6 invoke-virtual v11, v3, Lorg/json/JSONObject;->optInt(Ljava/lang/String;)I
  01dc move-result v1
  01de const/4 v3, 1
  01e0 if-ne v1, v3, +064h
  01e4 const-string v1, "tables"
  01e8 invoke-virtual v11, v1, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  01ee move-result-object v1
  01f0 const-string v15, "cards"
  01f4 invoke-virtual v1, v15, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  01fa move-result-object v1
  01fc invoke-virtual v1, Lorg/json/JSONArray;->length()I
  0202 move-result v1
  0204 if-ne v1, v3, +052h
  0208 new-instance v1, Ljava/lang/StringBuilder;
  020c invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  0212 const-string v3, "unit-"
  0216 invoke-virtual v1, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  021c const-string v3, "targetId"
  0220 move-wide v15, v9
  0222 invoke-virtual v11, v3, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0228 move-result-wide v9
  022a invoke-virtual v1, v9, v10, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0230 const-string v3, "-"
  0234 invoke-virtual v1, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  023a invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0240 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0246 move-result-object v1
  0248 invoke-virtual v11, v13, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  024e const-string v1, "libraryOrigin"
  0252 const-string v3, "uploaded"
  0256 invoke-virtual v11, v1, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  025c const-string v1, "provenance"
  0260 new-instance v3, Lorg/json/JSONObject;
  0264 invoke-direct v3, Lorg/json/JSONObject;-><init>()V
  026a const-string v9, "file"
  026e invoke-virtual v3, v9, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0274 move-result-object v3
  0276 const-string v9, "patchKey"
  027a invoke-virtual v3, v9, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0280 move-result-object v3
  0282 invoke-virtual v14, v2, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0288 move-result-object v9
  028a invoke-virtual v3, v2, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0290 move-result-object v2
  0292 invoke-virtual v2, v12, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0298 move-result-object v2
  029a invoke-virtual v11, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02a0 invoke-static v11, v4, v5, Lcom/personal/aihub/ProjectFormsData;->restore(Lorg/json/JSONObject; Ljava/lang/String; Ljava/io/File;)V
  02a6 goto +bh
  02a8 new-instance v0, Ljava/io/IOException;
  02ac const-string v1, "Invalid embedded unit project"
  02b0 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02b6 throw v0
  02b8 move-wide v15, v9
  02ba const/4 v11, 0
  02bc new-instance v1, Lorg/json/JSONObject;
  02c0 invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  02c6 invoke-virtual v1, v13, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02cc move-result-object v1
  02ce const-string v2, "metadata"
  02d2 invoke-virtual v1, v2, v14, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02d8 move-result-object v1
  02da const-string v2, "filename"
  02de invoke-virtual v1, v2, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02e4 move-result-object v0
  02e6 invoke-virtual v0, v12, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02ec move-result-object v0
  02ee const-string v1, "count"
  02f2 invoke-interface v6, Ljava/util/List;->size()I
  02f8 move-result v2
  02fa invoke-virtual v0, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0300 move-result-object v0
  0302 const-string v1, "bytes"
  0306 move-wide v9, v15
  0308 invoke-virtual v0, v1, v9, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  030e move-result-object v0
  0310 const-string v1, "entries"
  0314 invoke-virtual v0, v1, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  031a move-result-object v0
  031c const-string v1, "projectKey"
  0320 if-nez v11, +005h
  0324 sget-object v2, Lorg/json/JSONObject;->NULL Ljava/lang/Object;
  0328 goto +5h
  032a invoke-virtual v11, v13, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0330 move-result-object v2
  0332 invoke-virtual v0, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0338 move-result-object v0
  033a new-instance v1, Ljava/io/FileInputStream;
  033e move-object/from16 v2, v20
  0342 invoke-direct v1, v2, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0348 new-instance v2, Ljava/io/FileOutputStream;
  034c move-object/from16 v3, v17
  0350 invoke-direct v2, v3, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0356 const-wide v6, 4294967296
  0360 invoke-static v1, v2, v6, v7, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  0366 invoke-virtual v2, Ljava/io/FileOutputStream;->close()V
  036c invoke-virtual v1, Ljava/io/FileInputStream;->close()V
  0372 invoke-virtual v0, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0378 move-result-object v1
  037a move-object/from16 v4, v18
  037e invoke-static v4, v1, Lcom/personal/aihub/CreatorActivity;->writeText(Ljava/io/File; Ljava/lang/String;)V
  0384 if-eqz v11, +008h
  0388 move-object/from16 v6, v19
  038c invoke-direct v6, v11, Lcom/personal/aihub/CreatorActivity;->saveProject(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0392 goto +3h
  0394 move-object/from16 v6, v19
  0398 new-instance v1, Lorg/json/JSONObject;
  039c invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  03a2 const-string v2, "kind"
  03a6 const-string v7, "patch"
  03aa const-string v8, "project"
  03ae if-nez v11, +004h
  03b2 move-object v9, v7
  03b4 goto +2h
  03b6 move-object v9, v8
  03b8 invoke-virtual v1, v2, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  03be move-result-object v1
  03c0 if-nez v11, +004h
  03c4 sget-object v11, Lorg/json/JSONObject;->NULL Ljava/lang/Object;
  03c8 invoke-virtual v1, v8, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  03ce move-result-object v1
  03d0 invoke-virtual v1, v7, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  03d6 move-result-object v0
  03d8 const-string v1, "note"
  03dc const-string v2, "ECLP authenticated and added to Library. SQL stays inside the patch and is never executed by this app."
  03e0 invoke-virtual v0, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  03e6 move-result-object v0
  03e8 return-object v0
  03ea move-exception v0
  03ec move-object/from16 v6, v19
  03f0 goto +3bh
  03f2 move-exception v0
  03f4 move-object/from16 v6, v19
  03f8 goto +30h
  03fa move-exception v0
  03fc move-object/from16 v6, v19
  0400 move-object/from16 v4, v18
  0404 move-object v7, v0
  0406 invoke-virtual v2, Ljava/io/FileOutputStream;->close()V
  040c goto +6h
  040e move-exception v0
  0410 move-object v2, v0
  0412 invoke-virtual v7, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0418 throw v7
  041a move-exception v0
  041c goto +ch
  041e move-exception v0
  0420 move-object/from16 v6, v19
  0424 goto +6h
  0426 move-exception v0
  0428 move-object/from16 v6, v19
  042c move-object/from16 v3, v17
  0430 move-object/from16 v4, v18
  0434 move-object v2, v0
  0436 invoke-virtual v1, Ljava/io/FileInputStream;->close()V
  043c goto +6h
  043e move-exception v0
  0440 move-object v1, v0
  0442 invoke-virtual v2, v1, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0448 throw v2
  044a move-exception v0
  044c goto +dh
  044e move-exception v0
  0450 move-object/from16 v6, v19
  0454 move-object/from16 v3, v17
  0458 move-object/from16 v4, v18
  045c goto +5h
  045e move-exception v0
  0460 move-object v6, v1
  0462 move-object v3, v12
  0464 move-object v4, v13
  0466 invoke-static v5, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  046c invoke-virtual v3, Ljava/io/File;->delete()Z
  0472 invoke-virtual v4, Ljava/io/File;->delete()Z
  0478 throw v0
.end method

.method importPatchZip(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 new-instance v1, Ljava/util/zip/ZipFile;
  0004 move-object/from16 v0, v17
  0008 invoke-direct v1, v0, Ljava/util/zip/ZipFile;-><init>(Ljava/io/File;)V
  000e const-string v0, "metadata.json"
  0012 invoke-virtual v1, v0, Ljava/util/zip/ZipFile;->getEntry(Ljava/lang/String;)Ljava/util/zip/ZipEntry;
  0018 move-result-object v0
  001a const/4 v2, 0
  001c if-nez v0, +006h
  0020 invoke-virtual v1, Ljava/util/zip/ZipFile;->close()V
  0026 return-object v2
  0028 invoke-virtual v1, Ljava/util/zip/ZipFile;->entries()Ljava/util/Enumeration;
  002e move-result-object v3
  0030 const/4 v4, 0
  0032 move v5, v4
  0034 invoke-interface v3, Ljava/util/Enumeration;->hasMoreElements()Z
  003a move-result v6
  003c if-eqz v6, +025h
  0040 invoke-interface v3, Ljava/util/Enumeration;->nextElement()Ljava/lang/Object;
  0046 move-result-object v6
  0048 check-cast v6, Ljava/util/zip/ZipEntry;
  004c const/4 v7, 1
  004e add-int/2addr v5, v7
  0050 const v8, 100000
  0056 if-gt v5, v8, +010h
  005a invoke-virtual v6, Ljava/util/zip/ZipEntry;->getName()Ljava/lang/String;
  0060 move-result-object v6
  0062 const-string v8, "(?i)files/.*\.sql"
  0066 invoke-virtual v6, v8, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  006c move-result v6
  006e if-eqz v6, -01dh
  0072 move v4, v7
  0074 goto -20h
  0076 new-instance v0, Ljava/io/IOException;
  007a const-string v2, "Too many ZIP entries"
  007e invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0084 throw v0
  0086 if-nez v4, +006h
  008a invoke-virtual v1, Ljava/util/zip/ZipFile;->close()V
  0090 return-object v2
  0092 invoke-virtual v1, v0, Ljava/util/zip/ZipFile;->getInputStream(Ljava/util/zip/ZipEntry;)Ljava/io/InputStream;
  0098 move-result-object v3
  009a new-instance v4, Ljava/io/ByteArrayOutputStream;
  009e invoke-direct v4, Ljava/io/ByteArrayOutputStream;-><init>()V
  00a4 const-wide/32 v5, 4194304
  00aa invoke-static v3, v4, v5, v6, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  00b0 new-instance v0, Lorg/json/JSONObject;
  00b4 const-string v5, "UTF-8"
  00b8 invoke-virtual v4, v5, Ljava/io/ByteArrayOutputStream;->toString(Ljava/lang/String;)Ljava/lang/String;
  00be move-result-object v5
  00c0 invoke-direct v0, v5, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  00c6 invoke-virtual v4, Ljava/io/ByteArrayOutputStream;->close()V
  00cc if-eqz v3, +005h
  00d0 invoke-virtual v3, Ljava/io/InputStream;->close()V
  00d6 new-instance v3, Ljava/io/File;
  00da invoke-virtual/range v16, Lcom/personal/aihub/CreatorActivity;->getCacheDir()Ljava/io/File;
  00e0 move-result-object v4
  00e2 new-instance v5, Ljava/lang/StringBuilder;
  00e6 invoke-direct v5, Ljava/lang/StringBuilder;-><init>()V
  00ec const-string v6, "forge-zip-"
  00f0 invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00f6 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  00fc move-result-object v6
  00fe invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0104 invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  010a move-result-object v5
  010c invoke-direct v3, v4, v5, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0112 new-instance v4, Ljava/io/File;
  0116 const-string v5, "converted.eclp"
  011a invoke-direct v4, v3, v5, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0120 invoke-virtual v3, Ljava/io/File;->mkdirs()Z
  0126 new-instance v8, Ljava/util/ArrayList;
  012a invoke-direct v8, Ljava/util/ArrayList;-><init>()V
  0130 new-instance v5, Ljava/util/HashSet;
  0134 invoke-direct v5, Ljava/util/HashSet;-><init>()V
  013a invoke-virtual v1, Ljava/util/zip/ZipFile;->entries()Ljava/util/Enumeration;
  0140 move-result-object v6
  0142 const-wide/16 v9, 0
  0146 invoke-interface v6, Ljava/util/Enumeration;->hasMoreElements()Z
  014c move-result v7
  014e if-eqz v7, +0a0h
  0152 invoke-interface v6, Ljava/util/Enumeration;->nextElement()Ljava/lang/Object;
  0158 move-result-object v7
  015a check-cast v7, Ljava/util/zip/ZipEntry;
  015e invoke-virtual v7, Ljava/util/zip/ZipEntry;->isDirectory()Z
  0164 move-result v11
  0166 if-eqz v11, +003h
  016a goto -12h
  016c invoke-virtual v7, Ljava/util/zip/ZipEntry;->getName()Ljava/lang/String;
  0172 move-result-object v11
  0174 invoke-static v11, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  017a move-result v11
  017c if-eqz v11, +081h
  0180 invoke-virtual v7, Ljava/util/zip/ZipEntry;->getName()Ljava/lang/String;
  0186 move-result-object v11
  0188 invoke-virtual v5, v11, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  018e move-result v11
  0190 if-eqz v11, +077h
  0194 new-instance v11, Ljava/io/File;
  0198 new-instance v12, Ljava/lang/StringBuilder;
  019c invoke-direct v12, Ljava/lang/StringBuilder;-><init>()V
  01a2 const-string v13, "files/"
  01a6 invoke-virtual v12, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01ac invoke-virtual v7, Ljava/util/zip/ZipEntry;->getName()Ljava/lang/String;
  01b2 move-result-object v13
  01b4 invoke-virtual v12, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01ba invoke-virtual v12, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01c0 move-result-object v12
  01c2 invoke-direct v11, v3, v12, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  01c8 invoke-virtual v11, Ljava/io/File;->getParentFile()Ljava/io/File;
  01ce move-result-object v12
  01d0 invoke-virtual v12, Ljava/io/File;->mkdirs()Z
  01d6 invoke-virtual v1, v7, Ljava/util/zip/ZipFile;->getInputStream(Ljava/util/zip/ZipEntry;)Ljava/io/InputStream;
  01dc move-result-object v12
  01de new-instance v13, Ljava/io/FileOutputStream;
  01e2 invoke-direct v13, v11, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  01e8 const-wide/32 v14, 536870912
  01ee invoke-static v12, v13, v14, v15, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  01f4 invoke-virtual v13, Ljava/io/FileOutputStream;->close()V
  01fa if-eqz v12, +005h
  01fe invoke-virtual v12, Ljava/io/InputStream;->close()V
  0204 invoke-virtual v11, Ljava/io/File;->length()J
  020a move-result-wide v12
  020c add-long/2addr v9, v12
  020e const-wide v12, 4294967296
  0218 cmp-long v12, v9, v12
  021c if-gtz v12, +00fh
  0220 new-instance v12, Lcom/personal/aihub/EclpCodec$Entry;
  0224 invoke-virtual v7, Ljava/util/zip/ZipEntry;->getName()Ljava/lang/String;
  022a move-result-object v7
  022c invoke-direct v12, v7, v11, v2, Lcom/personal/aihub/EclpCodec$Entry;-><init>(Ljava/lang/String; Ljava/io/File; [B)V
  0232 invoke-virtual v8, v12, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0238 goto -79h
  023a new-instance v0, Ljava/io/IOException;
  023e const-string v2, "Patch ZIP too large"
  0242 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0248 throw v0
  024a move-exception v0
  024c move-object v2, v0
  024e invoke-virtual v13, Ljava/io/FileOutputStream;->close()V
  0254 goto +6h
  0256 move-exception v0
  0258 move-object v4, v0
  025a invoke-virtual v2, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0260 throw v2
  0262 move-exception v0
  0264 move-object v2, v0
  0266 if-eqz v12, +00bh
  026a invoke-virtual v12, Ljava/io/InputStream;->close()V
  0270 goto +6h
  0272 move-exception v0
  0274 move-object v4, v0
  0276 invoke-virtual v2, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  027c throw v2
  027e new-instance v0, Ljava/io/IOException;
  0282 const-string v2, "Unsafe or duplicate ZIP patch path"
  0286 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  028c throw v0
  028e new-instance v2, Ljava/io/FileOutputStream;
  0292 invoke-direct v2, v4, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0298 invoke-virtual/range v16, Lcom/personal/aihub/CreatorActivity;->getCacheDir()Ljava/io/File;
  029e move-result-object v7
  02a0 invoke-virtual v0, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  02a6 move-result-object v9
  02a8 const-string v5, "uuid"
  02ac invoke-virtual v0, v5, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  02b2 move-result-object v10
  02b4 const-string v5, "name"
  02b8 invoke-virtual v0, v5, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  02be move-result-object v11
  02c0 const-string v5, "version"
  02c4 invoke-virtual v0, v5, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  02ca move-result-object v12
  02cc move-object v6, v2
  02ce invoke-static/range v6 ... v12, Lcom/personal/aihub/EclpCodec;->write(Ljava/io/OutputStream; Ljava/io/File; Ljava/util/List; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)V
  02d4 invoke-virtual v2, Ljava/io/FileOutputStream;->close()V
  02da new-instance v0, Ljava/lang/StringBuilder;
  02de invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  02e4 const-string v2, "(?i)\.zip$"
  02e8 const-string v5, ""
  02ec move-object/from16 v6, v18
  02f0 invoke-virtual v6, v2, v5, Ljava/lang/String;->replaceFirst(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  02f6 move-result-object v2
  02f8 invoke-virtual v0, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02fe const-string v2, ".eclp"
  0302 invoke-virtual v0, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0308 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  030e move-result-object v0
  0310 move-object/from16 v5, v16
  0314 invoke-direct v5, v4, v0, Lcom/personal/aihub/CreatorActivity;->importEclp(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  031a move-result-object v0
  031c const-string v2, "note"
  0320 const-string v4, "Patch ZIP converted to ECLP locally and added to Library."
  0324 invoke-virtual v0, v2, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  032a move-result-object v0
  032c invoke-static v3, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  0332 invoke-virtual v1, Ljava/util/zip/ZipFile;->close()V
  0338 return-object v0
  033a move-exception v0
  033c move-object/from16 v5, v16
  0340 move-object v4, v0
  0342 invoke-virtual v2, Ljava/io/FileOutputStream;->close()V
  0348 goto +6h
  034a move-exception v0
  034c move-object v2, v0
  034e invoke-virtual v4, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0354 throw v4
  0356 move-exception v0
  0358 goto +4h
  035a move-exception v0
  035c move-object/from16 v5, v16
  0360 invoke-static v3, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  0366 throw v0
  0368 move-exception v0
  036a move-object/from16 v5, v16
  036e move-object v2, v0
  0370 invoke-virtual v4, Ljava/io/ByteArrayOutputStream;->close()V
  0376 goto +6h
  0378 move-exception v0
  037a move-object v4, v0
  037c invoke-virtual v2, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0382 throw v2
  0384 move-exception v0
  0386 goto +4h
  0388 move-exception v0
  038a move-object/from16 v5, v16
  038e move-object v2, v0
  0390 if-eqz v3, +00bh
  0394 invoke-virtual v3, Ljava/io/InputStream;->close()V
  039a goto +6h
  039c move-exception v0
  039e move-object v3, v0
  03a0 invoke-virtual v2, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  03a6 throw v2
  03a8 move-exception v0
  03aa goto +4h
  03ac move-exception v0
  03ae move-object/from16 v5, v16
  03b2 move-object v2, v0
  03b4 invoke-virtual v1, Ljava/util/zip/ZipFile;->close()V
  03ba goto +6h
  03bc move-exception v0
  03be move-object v1, v0
  03c0 invoke-virtual v2, v1, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  03c6 throw v2
.end method

.method importSparkingApk(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 const-wide/16 v3, 0
  0004 const-wide/16 v5, 0
  0008 const-string v1, "inspect"
  000c const-string v2, "Reading Sparking resources and patch format"
  0010 move-object v0, v12
  0012 invoke-direct/range v0 ... v6, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  0018 invoke-static v13, Lcom/personal/aihub/SprkCodec;->keyFromApk(Ljava/io/File;)[B
  001e move-result-object v0
  0020 invoke-static v13, Lcom/personal/aihub/SprkCodec;->databaseKeyFromApk(Ljava/io/File;)Ljava/lang/String;
  0026 move-result-object v1
  0028 sget-object v2, Ljava/nio/charset/StandardCharsets;->US_ASCII Ljava/nio/charset/Charset;
  002c invoke-virtual v1, v2, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0032 move-result-object v1
  0034 const/4 v2, 0
  0036 invoke-direct v12, v13, v14, Lcom/personal/aihub/CreatorActivity;->importArchive(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  003c move-result-object v13
  003e invoke-direct v12, Lcom/personal/aihub/CreatorActivity;->sparkingFormatKey()Ljava/io/File;
  0044 move-result-object v14
  0046 invoke-direct v12, v14, v0, Lcom/personal/aihub/CreatorActivity;->saveFormatKey(Ljava/io/File; [B)V
  004c invoke-direct v12, Lcom/personal/aihub/CreatorActivity;->sparkingDatabaseKey()Ljava/io/File;
  0052 move-result-object v14
  0054 invoke-direct v12, v14, v1, Lcom/personal/aihub/CreatorActivity;->saveFormatKey(Ljava/io/File; [B)V
  005a const-string v14, "sourceFormat"
  005e const-string v3, "sparking-apk"
  0062 invoke-virtual v13, v14, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0068 move-result-object v14
  006a const-string v3, "formatKeyConfigured"
  006e const/4 v4, 1
  0070 invoke-virtual v14, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0076 move-result-object v14
  0078 const-string v3, "note"
  007c const-string v4, "Sparking import is ready. Browse the included characters in Library → Sparking, or choose Update characters for current game data. You can also import supported .sprk patches and save ECLP from Library. Artwork and other game resources download separately."
  0080 invoke-virtual v14, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0086 const-string v6, "done"
  008a const-string v7, "Sparking import ready"
  008e const-wide/16 v8, 0
  0092 const-wide/16 v10, 0
  0096 move-object v5, v12
  0098 invoke-direct/range v5 ... v11, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  009e invoke-static v0, v2, Ljava/util/Arrays;->fill([B B)V
  00a4 invoke-static v1, v2, Ljava/util/Arrays;->fill([B B)V
  00aa return-object v13
  00ac move-exception v13
  00ae invoke-static v0, v2, Ljava/util/Arrays;->fill([B B)V
  00b4 invoke-static v1, v2, Ljava/util/Arrays;->fill([B B)V
  00ba throw v13
.end method

.method importSparkingPatch(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 invoke-direct v10, Lcom/personal/aihub/CreatorActivity;->sparkingFormatKey()Ljava/io/File;
  0006 move-result-object v0
  0008 invoke-virtual v0, Ljava/io/File;->isFile()Z
  000e move-result v1
  0010 if-eqz v1, +0b4h
  0014 invoke-virtual v0, Ljava/io/File;->length()J
  001a move-result-wide v1
  001c const-wide/16 v3, 32
  0020 cmp-long v1, v1, v3
  0024 if-nez v1, +0aah
  0028 const/16 v1, 32
  002c new-array v1, v1, [B
  0030 new-instance v2, Ljava/io/DataInputStream;
  0034 new-instance v3, Ljava/io/FileInputStream;
  0038 invoke-direct v3, v0, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  003e invoke-direct v2, v3, Ljava/io/DataInputStream;-><init>(Ljava/io/InputStream;)V
  0044 invoke-virtual v2, v1, Ljava/io/DataInputStream;->readFully([B)V
  004a invoke-virtual v2, Ljava/io/DataInputStream;->close()V
  0050 new-instance v0, Ljava/io/File;
  0054 invoke-virtual v10, Lcom/personal/aihub/CreatorActivity;->getCacheDir()Ljava/io/File;
  005a move-result-object v2
  005c new-instance v3, Ljava/lang/StringBuilder;
  0060 const-string v4, "sparking-"
  0064 invoke-direct v3, v4, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  006a invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0070 move-result-object v4
  0072 invoke-virtual v3, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0078 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  007e move-result-object v3
  0080 invoke-direct v0, v2, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0086 invoke-virtual v0, Ljava/io/File;->mkdir()Z
  008c move-result v2
  008e if-eqz v2, +063h
  0092 const/4 v2, 0
  0094 const-string v4, "convert"
  0098 const-string v5, "Opening Sparking patch"
  009c const-wide/16 v6, 0
  00a0 const-wide/16 v8, 0
  00a4 move-object v3, v10
  00a6 invoke-direct/range v3 ... v9, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  00ac new-instance v3, Ljava/io/File;
  00b0 const-string v4, "decoded.zip"
  00b4 invoke-direct v3, v0, v4, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00ba new-instance v4, Ljava/io/File;
  00be const-string v5, "converted.eclp"
  00c2 invoke-direct v4, v0, v5, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00c8 invoke-static v11, v3, v1, Lcom/personal/aihub/SprkCodec;->decode(Ljava/io/File; Ljava/io/File; [B)V
  00ce invoke-virtual v10, Lcom/personal/aihub/CreatorActivity;->getCacheDir()Ljava/io/File;
  00d4 move-result-object v11
  00d6 invoke-static v3, v0, v4, v11, v12, Lcom/personal/aihub/SprkEclp;->convert(Ljava/io/File; Ljava/io/File; Ljava/io/File; Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  00dc new-instance v11, Ljava/lang/StringBuilder;
  00e0 invoke-direct v11, Ljava/lang/StringBuilder;-><init>()V
  00e6 const-string v3, "(?i)\.sprk$"
  00ea const-string v5, ""
  00ee invoke-virtual v12, v3, v5, Ljava/lang/String;->replaceFirst(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  00f4 move-result-object v12
  00f6 invoke-virtual v11, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00fc const-string v12, ".eclp"
  0100 invoke-virtual v11, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0106 invoke-virtual v11, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  010c move-result-object v11
  010e invoke-direct v10, v4, v11, Lcom/personal/aihub/CreatorActivity;->importEclp(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0114 move-result-object v11
  0116 const-string v12, "sourceFormat"
  011a const-string v3, "sparking-sprk"
  011e invoke-virtual v11, v12, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0124 move-result-object v11
  0126 const-string v12, "note"
  012a const-string v3, "Sparking patch converted and added to the Sparking category in Library. Save ECLP to install it in Eclipse. Format conversion does not verify its SQL or gameplay compatibility; the original creator metadata was preserved."
  012e invoke-virtual v11, v12, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0134 move-result-object v11
  0136 invoke-static v1, v2, Ljava/util/Arrays;->fill([B B)V
  013c invoke-static v0, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  0142 return-object v11
  0144 move-exception v11
  0146 invoke-static v1, v2, Ljava/util/Arrays;->fill([B B)V
  014c invoke-static v0, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  0152 throw v11
  0154 new-instance v11, Ljava/io/IOException;
  0158 const-string v12, "Could not prepare Sparking conversion."
  015c invoke-direct v11, v12, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0162 throw v11
  0164 move-exception v11
  0166 invoke-virtual v2, Ljava/io/DataInputStream;->close()V
  016c goto +5h
  016e move-exception v12
  0170 invoke-virtual v11, v12, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0176 throw v11
  0178 new-instance v11, Ljava/io/IOException;
  017c const-string v12, "First choose Import file and select the original Sparking 6.5.5 APK or its ZIP. Then import your .sprk patch here."
  0180 invoke-direct v11, v12, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0186 throw v11
.end method

.method importUri(Landroid/net/Uri;)Lorg/json/JSONObject;
  0000 const/4 v0, 0
  0002 invoke-direct v1, v2, v0, Lcom/personal/aihub/CreatorActivity;->importUri(Landroid/net/Uri; Z)Lorg/json/JSONObject;
  0008 move-result-object v2
  000a return-object v2
.end method

.method importUri(Landroid/net/Uri; Z)Lorg/json/JSONObject;
  0000 const-string v0, "project"
  0004 const-string v1, "import-"
  0008 const-string v2, "unit-"
  000c invoke-virtual v11, Lcom/personal/aihub/CreatorActivity;->getContentResolver()Landroid/content/ContentResolver;
  0012 move-result-object v3
  0014 const-string v4, "_display_name"
  0018 filled-new-array v4, [Ljava/lang/String;
  001e move-result-object v5
  0020 const/4 v7, 0
  0022 const/4 v8, 0
  0024 const/4 v6, 0
  0026 move-object v4, v12
  0028 invoke-virtual/range v3 ... v8, Landroid/content/ContentResolver;->query(Landroid/net/Uri; [Ljava/lang/String; Ljava/lang/String; [Ljava/lang/String; Ljava/lang/String;)Landroid/database/Cursor;
  002e move-result-object v3
  0030 const/4 v4, 0
  0032 if-eqz v3, +019h
  0036 invoke-interface v3, Landroid/database/Cursor;->moveToFirst()Z
  003c move-result v5
  003e if-eqz v5, +013h
  0042 invoke-interface v3, v4, Landroid/database/Cursor;->getString(I)Ljava/lang/String;
  0048 move-result-object v5
  004a goto +fh
  004c move-exception v12
  004e if-eqz v3, +00ah
  0052 invoke-interface v3, Landroid/database/Cursor;->close()V
  0058 goto +5h
  005a move-exception v13
  005c invoke-virtual v12, v13, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0062 throw v12
  0064 const-string v5, "import"
  0068 if-eqz v3, +005h
  006c invoke-interface v3, Landroid/database/Cursor;->close()V
  0072 new-instance v3, Ljava/io/File;
  0076 invoke-virtual v11, Lcom/personal/aihub/CreatorActivity;->getCacheDir()Ljava/io/File;
  007c move-result-object v6
  007e new-instance v7, Ljava/lang/StringBuilder;
  0082 const-string v8, "forge-import-"
  0086 invoke-direct v7, v8, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  008c invoke-static Ljava/lang/System;->currentTimeMillis()J
  0092 move-result-wide v8
  0094 invoke-virtual v7, v8, v9, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  009a const-string v8, ".apk"
  009e if-nez v13, +012h
  00a2 sget-object v9, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  00a6 invoke-virtual v5, v9, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  00ac move-result-object v9
  00ae invoke-virtual v9, v8, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  00b4 move-result v9
  00b6 if-eqz v9, +003h
  00ba goto +4h
  00bc const-string v9, ""
  00c0 goto +2h
  00c2 move-object v9, v8
  00c4 invoke-virtual v7, v9, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00ca invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00d0 move-result-object v7
  00d2 invoke-direct v3, v6, v7, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00d8 invoke-virtual v11, Lcom/personal/aihub/CreatorActivity;->getContentResolver()Landroid/content/ContentResolver;
  00de move-result-object v6
  00e0 invoke-virtual v6, v12, Landroid/content/ContentResolver;->openInputStream(Landroid/net/Uri;)Ljava/io/InputStream;
  00e6 move-result-object v12
  00e8 new-instance v6, Ljava/io/FileOutputStream;
  00ec invoke-direct v6, v3, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  00f2 if-eqz v12, +26fh
  00f6 const-wide v9, 4294967296
  0100 invoke-static v12, v6, v9, v10, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  0106 invoke-virtual v6, Ljava/io/FileOutputStream;->close()V
  010c if-eqz v12, +005h
  0110 invoke-virtual v12, Ljava/io/InputStream;->close()V
  0116 if-eqz v13, +00ah
  011a invoke-direct v11, v3, v5, Lcom/personal/aihub/CreatorActivity;->importEclipseApk(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0120 move-result-object v12
  0122 invoke-virtual v3, Ljava/io/File;->delete()Z
  0128 return-object v12
  012a sget-object v12, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  012e invoke-virtual v5, v12, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  0134 move-result-object v12
  0136 invoke-virtual v12, v8, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  013c move-result v12
  013e if-eqz v12, +048h
  0142 invoke-virtual v11, Lcom/personal/aihub/CreatorActivity;->getPackageManager()Landroid/content/pm/PackageManager;
  0148 move-result-object v12
  014a invoke-virtual v3, Ljava/io/File;->getPath()Ljava/lang/String;
  0150 move-result-object v13
  0152 invoke-virtual v12, v13, v4, Landroid/content/pm/PackageManager;->getPackageArchiveInfo(Ljava/lang/String; I)Landroid/content/pm/PackageInfo;
  0158 move-result-object v12
  015a if-eqz v12, +014h
  015e const-string v13, "com.sparkingDokkan.GLB"
  0162 iget-object v12, v12, Landroid/content/pm/PackageInfo;->packageName Ljava/lang/String;
  0166 invoke-virtual v13, v12, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  016c move-result v12
  016e if-eqz v12, +00ah
  0172 invoke-direct v11, v3, v5, Lcom/personal/aihub/CreatorActivity;->importSparkingApk(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0178 move-result-object v12
  017a invoke-virtual v3, Ljava/io/File;->delete()Z
  0180 return-object v12
  0182 new-instance v12, Ljava/util/zip/ZipFile;
  0186 invoke-direct v12, v3, Ljava/util/zip/ZipFile;-><init>(Ljava/io/File;)V
  018c const-string v13, "assets/patcher/maps/android_current.json"
  0190 invoke-virtual v12, v13, Ljava/util/zip/ZipFile;->getEntry(Ljava/lang/String;)Ljava/util/zip/ZipEntry;
  0196 move-result-object v13
  0198 if-eqz v13, +00dh
  019c invoke-direct v11, v3, v5, Lcom/personal/aihub/CreatorActivity;->importEclipseApk(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  01a2 move-result-object v13
  01a4 invoke-virtual v12, Ljava/util/zip/ZipFile;->close()V
  01aa invoke-virtual v3, Ljava/io/File;->delete()Z
  01b0 return-object v13
  01b2 invoke-virtual v12, Ljava/util/zip/ZipFile;->close()V
  01b8 goto +bh
  01ba move-exception v13
  01bc invoke-virtual v12, Ljava/util/zip/ZipFile;->close()V
  01c2 goto +5h
  01c4 move-exception v12
  01c6 invoke-virtual v13, v12, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  01cc throw v13
  01ce sget-object v12, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  01d2 invoke-virtual v5, v12, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  01d8 move-result-object v12
  01da const-string v13, ".json"
  01de invoke-virtual v12, v13, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  01e4 move-result v12
  01e6 const-string v13, "key"
  01ea const-string v6, "kind"
  01ee if-eqz v12, +079h
  01f2 new-instance v12, Lorg/json/JSONObject;
  01f6 const/high16 v1, 20971520
  01fa invoke-static v3, v1, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  0200 move-result-object v1
  0202 invoke-direct v12, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0208 const-string v1, "format"
  020c invoke-virtual v12, v1, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0212 move-result-object v1
  0214 const-string v4, "dokkan-unit-forge"
  0218 invoke-virtual v1, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  021e move-result v1
  0220 if-eqz v1, +058h
  0224 const-string v1, "libraryOrigin"
  0228 const-string v4, "uploaded"
  022c invoke-virtual v12, v1, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0232 const-string v1, "provenance"
  0236 new-instance v4, Lorg/json/JSONObject;
  023a invoke-direct v4, Lorg/json/JSONObject;-><init>()V
  0240 const-string v7, "file"
  0244 invoke-virtual v4, v7, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  024a move-result-object v4
  024c const-string v5, "importedAt"
  0250 invoke-static Lcom/personal/aihub/CreatorActivity;->isoStamp()Ljava/lang/String;
  0256 move-result-object v7
  0258 invoke-virtual v4, v5, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  025e move-result-object v4
  0260 invoke-virtual v12, v1, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0266 new-instance v1, Ljava/lang/StringBuilder;
  026a invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0270 const-string v2, "targetId"
  0274 invoke-virtual v12, v2, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  027a move-result-wide v4
  027c invoke-virtual v1, v4, v5, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0282 const-string v2, "-"
  0286 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  028c invoke-static Ljava/lang/System;->currentTimeMillis()J
  0292 move-result-wide v4
  0294 invoke-virtual v1, v4, v5, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  029a invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  02a0 move-result-object v1
  02a2 invoke-virtual v12, v13, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02a8 invoke-direct v11, v12, Lcom/personal/aihub/CreatorActivity;->saveProject(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  02ae new-instance v13, Lorg/json/JSONObject;
  02b2 invoke-direct v13, Lorg/json/JSONObject;-><init>()V
  02b8 invoke-virtual v13, v6, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02be move-result-object v13
  02c0 invoke-virtual v13, v0, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02c6 move-result-object v12
  02c8 invoke-virtual v3, Ljava/io/File;->delete()Z
  02ce return-object v12
  02d0 new-instance v12, Ljava/io/IOException;
  02d4 const-string v13, "This JSON is not a Dokkan Unit Creator project. Use a SQLite database for game data."
  02d8 invoke-direct v12, v13, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02de throw v12
  02e0 const/16 v12, 16
  02e4 new-array v12, v12, [B
  02e8 new-instance v0, Ljava/io/FileInputStream;
  02ec invoke-direct v0, v3, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  02f2 invoke-virtual v0, v12, Ljava/io/FileInputStream;->read([B)I
  02f8 invoke-virtual v0, Ljava/io/FileInputStream;->close()V
  02fe aget-byte v0, v12, v4
  0302 const/16 v2, 69
  0306 const/4 v4, 3
  0308 const/16 v7, 80
  030c const/4 v8, 2
  030e const/4 v9, 1
  0310 if-ne v0, v2, +01ah
  0314 aget-byte v2, v12, v9
  0318 const/16 v10, 67
  031c if-ne v2, v10, +014h
  0320 aget-byte v2, v12, v8
  0324 const/16 v10, 76
  0328 if-ne v2, v10, +00eh
  032c aget-byte v2, v12, v4
  0330 if-ne v2, v7, +00ah
  0334 invoke-direct v11, v3, v5, Lcom/personal/aihub/CreatorActivity;->importEclp(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  033a move-result-object v12
  033c invoke-virtual v3, Ljava/io/File;->delete()Z
  0342 return-object v12
  0344 const/16 v2, 83
  0348 if-ne v0, v2, +01ah
  034c aget-byte v0, v12, v9
  0350 if-ne v0, v7, +016h
  0354 aget-byte v0, v12, v8
  0358 const/16 v2, 82
  035c if-ne v0, v2, +010h
  0360 aget-byte v0, v12, v4
  0364 const/16 v2, 75
  0368 if-ne v0, v2, +00ah
  036c invoke-direct v11, v3, v5, Lcom/personal/aihub/CreatorActivity;->importSparkingPatch(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0372 move-result-object v12
  0374 invoke-virtual v3, Ljava/io/File;->delete()Z
  037a return-object v12
  037c new-instance v0, Ljava/lang/String;
  0380 sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0384 invoke-direct v0, v12, v2, Ljava/lang/String;-><init>([B Ljava/nio/charset/Charset;)V
  038a const-string v12, "SQLite format 3 "
  038e invoke-virtual v0, v12, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0394 move-result v12
  0396 if-eqz v12, +01bh
  039a new-instance v12, Lorg/json/JSONObject;
  039e invoke-direct v12, Lorg/json/JSONObject;-><init>()V
  03a4 const-string v13, "database"
  03a8 invoke-virtual v12, v6, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  03ae move-result-object v12
  03b0 const-string v13, "info"
  03b4 invoke-direct v11, v3, v5, Lcom/personal/aihub/CreatorActivity;->useDb(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  03ba move-result-object v0
  03bc invoke-virtual v12, v13, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  03c2 move-result-object v12
  03c4 invoke-virtual v3, Ljava/io/File;->delete()Z
  03ca return-object v12
  03cc const-string v12, "(?i).*\.zip$"
  03d0 invoke-virtual v5, v12, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  03d6 move-result v12
  03d8 if-eqz v12, +016h
  03dc invoke-direct v11, v3, v5, Lcom/personal/aihub/CreatorActivity;->importWrappedApk(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  03e2 move-result-object v12
  03e4 if-eqz v12, +006h
  03e8 invoke-virtual v3, Ljava/io/File;->delete()Z
  03ee return-object v12
  03f0 invoke-direct v11, v3, v5, Lcom/personal/aihub/CreatorActivity;->importPatchZip(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  03f6 move-result-object v12
  03f8 if-eqz v12, +006h
  03fc invoke-virtual v3, Ljava/io/File;->delete()Z
  0402 return-object v12
  0404 const-string v12, "(?i).*\.(zip|apk|apks|ipa|eclp)$"
  0408 invoke-virtual v5, v12, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  040e move-result v12
  0410 if-eqz v12, +00ah
  0414 invoke-direct v11, v3, v5, Lcom/personal/aihub/CreatorActivity;->importArchive(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  041a move-result-object v12
  041c invoke-virtual v3, Ljava/io/File;->delete()Z
  0422 return-object v12
  0424 const-string v12, "(?i).*\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|m4a|aac|flac|awb|acb|atlas|plist|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$"
  0428 invoke-virtual v5, v12, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  042e move-result v12
  0430 if-eqz v12, +0bch
  0434 new-instance v12, Ljava/lang/StringBuilder;
  0438 invoke-direct v12, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  043e invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0444 move-result-object v0
  0446 invoke-virtual v12, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  044c invoke-virtual v12, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0452 move-result-object v12
  0454 new-instance v0, Ljava/lang/StringBuilder;
  0458 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  045e invoke-virtual v0, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0464 const-string v1, "/"
  0468 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  046e new-instance v1, Ljava/io/File;
  0472 invoke-direct v1, v5, Ljava/io/File;-><init>(Ljava/lang/String;)V
  0478 invoke-virtual v1, Ljava/io/File;->getName()Ljava/lang/String;
  047e move-result-object v1
  0480 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0486 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  048c move-result-object v0
  048e invoke-virtual v11, v0, Lcom/personal/aihub/CreatorActivity;->assetFile(Ljava/lang/String;)Ljava/io/File;
  0494 move-result-object v1
  0496 invoke-virtual v11, v12, Lcom/personal/aihub/CreatorActivity;->assetFile(Ljava/lang/String;)Ljava/io/File;
  049c move-result-object v12
  049e invoke-virtual v1, Ljava/io/File;->getParentFile()Ljava/io/File;
  04a4 move-result-object v2
  04a6 invoke-virtual v2, Ljava/io/File;->mkdirs()Z
  04ac new-instance v2, Ljava/io/FileInputStream;
  04b0 invoke-direct v2, v3, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  04b6 new-instance v4, Ljava/io/FileOutputStream;
  04ba invoke-direct v4, v1, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  04c0 const-wide/32 v7, 1073741824
  04c6 invoke-static v2, v4, v7, v8, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  04cc invoke-virtual v4, Ljava/io/FileOutputStream;->close()V
  04d2 invoke-virtual v2, Ljava/io/FileInputStream;->close()V
  04d8 invoke-virtual v1, Ljava/io/File;->length()J
  04de move-result-wide v4
  04e0 invoke-direct v11, v12, v9, v4, v5, Lcom/personal/aihub/CreatorActivity;->expandCpkResources(Ljava/io/File; I J)Lorg/json/JSONObject;
  04e6 move-result-object v2
  04e8 const-string v4, "assets"
  04ec invoke-virtual v2, v6, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  04f2 move-result-object v2
  04f4 const-string v4, "asset"
  04f8 new-instance v5, Lorg/json/JSONObject;
  04fc invoke-direct v5, Lorg/json/JSONObject;-><init>()V
  0502 invoke-virtual v5, v13, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0508 move-result-object v13
  050a const-string v0, "path"
  050e invoke-virtual v1, Ljava/io/File;->getName()Ljava/lang/String;
  0514 move-result-object v5
  0516 invoke-virtual v13, v0, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  051c move-result-object v13
  051e const-string v0, "name"
  0522 invoke-virtual v1, Ljava/io/File;->getName()Ljava/lang/String;
  0528 move-result-object v5
  052a invoke-virtual v13, v0, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0530 move-result-object v13
  0532 const-string v0, "size"
  0536 invoke-virtual v1, Ljava/io/File;->length()J
  053c move-result-wide v5
  053e invoke-virtual v13, v0, v5, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0544 move-result-object v13
  0546 const-string v0, "image"
  054a invoke-virtual v1, Ljava/io/File;->getName()Ljava/lang/String;
  0550 move-result-object v1
  0552 const-string v5, "(?i).*\.(png|jpe?g|webp|gif|bmp)$"
  0556 invoke-virtual v1, v5, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  055c move-result v1
  055e invoke-virtual v13, v0, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0564 move-result-object v13
  0566 invoke-virtual v2, v4, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  056c move-result-object v12
  056e invoke-virtual v3, Ljava/io/File;->delete()Z
  0574 return-object v12
  0576 move-exception v13
  0578 invoke-virtual v4, Ljava/io/FileOutputStream;->close()V
  057e goto +5h
  0580 move-exception v0
  0582 invoke-virtual v13, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0588 throw v13
  058a move-exception v13
  058c invoke-virtual v2, Ljava/io/FileInputStream;->close()V
  0592 goto +5h
  0594 move-exception v0
  0596 invoke-virtual v13, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  059c throw v13
  059e move-exception v13
  05a0 invoke-static v12, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  05a6 throw v13
  05a8 new-instance v12, Ljava/io/IOException;
  05ac const-string v13, "Choose a unit JSON, ECLP or SPRK patch, readable SQLite database, image, ZIP, or APK archive."
  05b0 invoke-direct v12, v13, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  05b6 throw v12
  05b8 move-exception v12
  05ba invoke-virtual v0, Ljava/io/FileInputStream;->close()V
  05c0 goto +5h
  05c2 move-exception v13
  05c4 invoke-virtual v12, v13, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  05ca throw v12
  05cc move-exception v13
  05ce goto +9h
  05d0 new-instance v13, Ljava/io/IOException;
  05d4 const-string v0, "Cannot read selected file"
  05d8 invoke-direct v13, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  05de throw v13
  05e0 invoke-virtual v6, Ljava/io/FileOutputStream;->close()V
  05e6 goto +5h
  05e8 move-exception v0
  05ea invoke-virtual v13, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  05f0 throw v13
  05f2 move-exception v13
  05f4 if-eqz v12, +00ah
  05f8 invoke-virtual v12, Ljava/io/InputStream;->close()V
  05fe goto +5h
  0600 move-exception v12
  0602 invoke-virtual v13, v12, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0608 throw v13
  060a move-exception v12
  060c invoke-virtual v3, Ljava/io/File;->delete()Z
  0612 throw v12
.end method

.method importWrappedApk(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 new-instance v0, Ljava/util/zip/ZipFile;
  0004 invoke-direct v0, v12, Ljava/util/zip/ZipFile;-><init>(Ljava/io/File;)V
  000a invoke-virtual v0, Ljava/util/zip/ZipFile;->entries()Ljava/util/Enumeration;
  0010 move-result-object v12
  0012 const/4 v1, 0
  0014 const/4 v2, 0
  0016 move-object v4, v1
  0018 move v3, v2
  001a move v5, v3
  001c invoke-interface v12, Ljava/util/Enumeration;->hasMoreElements()Z
  0022 move-result v6
  0024 const-string v7, ".apk"
  0028 const/4 v8, 1
  002a if-eqz v6, +056h
  002e invoke-interface v12, Ljava/util/Enumeration;->nextElement()Ljava/lang/Object;
  0034 move-result-object v6
  0036 check-cast v6, Ljava/util/zip/ZipEntry;
  003a add-int/2addr v5, v8
  003c const v8, 100000
  0042 if-gt v5, v8, +042h
  0046 invoke-virtual v6, Ljava/util/zip/ZipEntry;->isDirectory()Z
  004c move-result v8
  004e if-eqz v8, +00fh
  0052 invoke-virtual v6, Ljava/util/zip/ZipEntry;->getName()Ljava/lang/String;
  0058 move-result-object v8
  005a const-string v9, "/$"
  005e const-string v10, ""
  0062 invoke-virtual v8, v9, v10, Ljava/lang/String;->replaceFirst(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0068 move-result-object v8
  006a goto +5h
  006c invoke-virtual v6, Ljava/util/zip/ZipEntry;->getName()Ljava/lang/String;
  0072 move-result-object v8
  0074 invoke-static v8, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  007a move-result v8
  007c if-eqz v8, +01dh
  0080 invoke-virtual v6, Ljava/util/zip/ZipEntry;->isDirectory()Z
  0086 move-result v8
  0088 if-eqz v8, +003h
  008c goto -38h
  008e add-int/lit8 v3, v3, 1
  0092 invoke-virtual v6, Ljava/util/zip/ZipEntry;->getName()Ljava/lang/String;
  0098 move-result-object v8
  009a sget-object v9, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  009e invoke-virtual v8, v9, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  00a4 move-result-object v8
  00a6 invoke-virtual v8, v7, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  00ac move-result v7
  00ae if-eqz v7, -049h
  00b2 move-object v4, v6
  00b4 goto -4ch
  00b6 new-instance v12, Ljava/io/IOException;
  00ba const-string v13, "Unsafe ZIP path"
  00be invoke-direct v12, v13, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00c4 throw v12
  00c6 new-instance v12, Ljava/io/IOException;
  00ca const-string v13, "Too many ZIP entries"
  00ce invoke-direct v12, v13, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00d4 throw v12
  00d6 if-ne v3, v8, +0d4h
  00da if-nez v4, +004h
  00de goto/16 +0d0h
  00e2 invoke-virtual v4, Ljava/util/zip/ZipEntry;->getSize()J
  00e8 move-result-wide v5
  00ea const-wide/32 v8, 536870912
  00f0 cmp-long v12, v5, v8
  00f4 if-gtz v12, +0bdh
  00f8 new-instance v12, Ljava/io/File;
  00fc invoke-virtual v11, Lcom/personal/aihub/CreatorActivity;->getCacheDir()Ljava/io/File;
  0102 move-result-object v1
  0104 new-instance v3, Ljava/lang/StringBuilder;
  0108 invoke-direct v3, Ljava/lang/StringBuilder;-><init>()V
  010e const-string v5, "wrapped-"
  0112 invoke-virtual v3, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0118 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  011e move-result-object v5
  0120 invoke-virtual v3, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0126 invoke-virtual v3, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  012c invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0132 move-result-object v3
  0134 invoke-direct v12, v1, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  013a new-instance v1, Ljava/util/zip/CRC32;
  013e invoke-direct v1, Ljava/util/zip/CRC32;-><init>()V
  0144 new-instance v3, Ljava/util/zip/CheckedInputStream;
  0148 invoke-virtual v0, v4, Ljava/util/zip/ZipFile;->getInputStream(Ljava/util/zip/ZipEntry;)Ljava/io/InputStream;
  014e move-result-object v5
  0150 invoke-direct v3, v5, v1, Ljava/util/zip/CheckedInputStream;-><init>(Ljava/io/InputStream; Ljava/util/zip/Checksum;)V
  0156 new-instance v5, Ljava/io/FileOutputStream;
  015a invoke-direct v5, v12, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0160 invoke-static v3, v5, v8, v9, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  0166 invoke-virtual v5, Ljava/io/FileOutputStream;->close()V
  016c invoke-virtual v3, Ljava/io/InputStream;->close()V
  0172 invoke-virtual v12, Ljava/io/File;->length()J
  0178 move-result-wide v5
  017a invoke-virtual v4, Ljava/util/zip/ZipEntry;->getSize()J
  0180 move-result-wide v7
  0182 cmp-long v3, v5, v7
  0186 if-nez v3, +053h
  018a invoke-virtual v1, Ljava/util/zip/CRC32;->getValue()J
  0190 move-result-wide v5
  0192 invoke-virtual v4, Ljava/util/zip/ZipEntry;->getCrc()J
  0198 move-result-wide v3
  019a cmp-long v1, v5, v3
  019e if-nez v1, +047h
  01a2 invoke-virtual v11, Lcom/personal/aihub/CreatorActivity;->getPackageManager()Landroid/content/pm/PackageManager;
  01a8 move-result-object v1
  01aa invoke-virtual v12, Ljava/io/File;->getPath()Ljava/lang/String;
  01b0 move-result-object v3
  01b2 invoke-virtual v1, v3, v2, Landroid/content/pm/PackageManager;->getPackageArchiveInfo(Ljava/lang/String; I)Landroid/content/pm/PackageInfo;
  01b8 move-result-object v1
  01ba if-eqz v1, +017h
  01be const-string v2, "com.sparkingDokkan.GLB"
  01c2 iget-object v3, v1, Landroid/content/pm/PackageInfo;->packageName Ljava/lang/String;
  01c6 invoke-virtual v2, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01cc move-result v2
  01ce if-eqz v2, +00dh
  01d2 invoke-direct v11, v12, v13, Lcom/personal/aihub/CreatorActivity;->importSparkingApk(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  01d8 move-result-object v13
  01da invoke-virtual v12, Ljava/io/File;->delete()Z
  01e0 invoke-virtual v0, Ljava/util/zip/ZipFile;->close()V
  01e6 return-object v13
  01e8 if-eqz v1, +017h
  01ec const-string v2, "com.anthen.eclipse"
  01f0 iget-object v1, v1, Landroid/content/pm/PackageInfo;->packageName Ljava/lang/String;
  01f4 invoke-virtual v2, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01fa move-result v1
  01fc if-eqz v1, +00dh
  0200 invoke-direct v11, v12, v13, Lcom/personal/aihub/CreatorActivity;->importEclipseApk(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0206 move-result-object v13
  0208 invoke-virtual v12, Ljava/io/File;->delete()Z
  020e invoke-virtual v0, Ljava/util/zip/ZipFile;->close()V
  0214 return-object v13
  0216 invoke-direct v11, v12, v13, Lcom/personal/aihub/CreatorActivity;->importArchive(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  021c move-result-object v13
  021e invoke-virtual v12, Ljava/io/File;->delete()Z
  0224 invoke-virtual v0, Ljava/util/zip/ZipFile;->close()V
  022a return-object v13
  022c new-instance v13, Ljava/io/IOException;
  0230 const-string v1, "The APK inside this ZIP is incomplete or corrupted. Download the original ZIP again."
  0234 invoke-direct v13, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  023a throw v13
  023c move-exception v13
  023e invoke-virtual v5, Ljava/io/FileOutputStream;->close()V
  0244 goto +5h
  0246 move-exception v1
  0248 invoke-virtual v13, v1, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  024e throw v13
  0250 move-exception v13
  0252 invoke-virtual v3, Ljava/io/InputStream;->close()V
  0258 goto +5h
  025a move-exception v1
  025c invoke-virtual v13, v1, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0262 throw v13
  0264 move-exception v13
  0266 invoke-virtual v12, Ljava/io/File;->delete()Z
  026c throw v13
  026e new-instance v12, Ljava/io/IOException;
  0272 const-string v13, "The APK inside this ZIP exceeds 512 MB."
  0276 invoke-direct v12, v13, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  027c throw v12
  027e invoke-virtual v0, Ljava/util/zip/ZipFile;->close()V
  0284 return-object v1
  0286 move-exception v12
  0288 invoke-virtual v0, Ljava/util/zip/ZipFile;->close()V
  028e goto +5h
  0290 move-exception v13
  0292 invoke-virtual v12, v13, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0298 throw v12
.end method

.method info()Lorg/json/JSONObject;
  0000 invoke-direct v8, Lcom/personal/aihub/CreatorActivity;->ensureDb()V
  0006 invoke-direct v8, Lcom/personal/aihub/CreatorActivity;->dataStore()Lcom/personal/aihub/GameDataStore;
  000c move-result-object v0
  000e invoke-virtual v0, Lcom/personal/aihub/GameDataStore;->state()Lorg/json/JSONObject;
  0014 move-result-object v0
  0016 iget-object v1, v8, Lcom/personal/aihub/CreatorActivity;->db Landroid/database/sqlite/SQLiteDatabase;
  001a const-string v2, "SELECT count(*) FROM cards"
  001e const/4 v3, 0
  0020 invoke-virtual v1, v2, v3, Landroid/database/sqlite/SQLiteDatabase;->rawQuery(Ljava/lang/String; [Ljava/lang/String;)Landroid/database/Cursor;
  0026 move-result-object v1
  0028 invoke-interface v1, Landroid/database/Cursor;->moveToFirst()Z
  002e const/4 v2, 0
  0030 invoke-interface v1, v2, Landroid/database/Cursor;->getLong(I)J
  0036 move-result-wide v3
  0038 if-eqz v1, +005h
  003c invoke-interface v1, Landroid/database/Cursor;->close()V
  0042 new-instance v5, Lorg/json/JSONObject;
  0046 invoke-direct v5, Lorg/json/JSONObject;-><init>()V
  004c const-string v6, "schema"
  0050 iget-object v7, v8, Lcom/personal/aihub/CreatorActivity;->schema Lorg/json/JSONObject;
  0054 invoke-virtual v5, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  005a move-result-object v5
  005c const-string v6, "count"
  0060 invoke-virtual v5, v6, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0066 move-result-object v3
  0068 const-string v4, "meta"
  006c invoke-direct v8, Lcom/personal/aihub/CreatorActivity;->dataStore()Lcom/personal/aihub/GameDataStore;
  0072 move-result-object v5
  0074 invoke-virtual v5, Lcom/personal/aihub/GameDataStore;->meta()Lorg/json/JSONObject;
  007a move-result-object v5
  007c invoke-virtual v3, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0082 move-result-object v3
  0084 new-instance v4, Lorg/json/JSONObject;
  0088 invoke-direct v4, Lorg/json/JSONObject;-><init>()V
  008e if-eqz v0, +00bh
  0092 const-string v5, "previous"
  0096 invoke-virtual v0, v5, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  009c move-result-object v0
  009e if-eqz v0, +003h
  00a2 const/4 v2, 1
  00a4 const-string v0, "database"
  00a8 const-string v5, "canRestore"
  00ac invoke-virtual v4, v5, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  00b2 move-result-object v2
  00b4 invoke-virtual v3, v0, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00ba move-result-object v0
  00bc return-object v0
  00be move-exception v0
  00c0 if-nez v1, +003h
  00c4 throw v0
  00c6 invoke-interface v1, Landroid/database/Cursor;->close()V
  00cc throw v0
.end method

.method inspectEclipseApk(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 invoke-virtual v9, Lcom/personal/aihub/CreatorActivity;->getPackageManager()Landroid/content/pm/PackageManager;
  0006 move-result-object v0
  0008 invoke-virtual v10, Ljava/io/File;->getPath()Ljava/lang/String;
  000e move-result-object v1
  0010 const/4 v2, 0
  0012 invoke-virtual v0, v1, v2, Landroid/content/pm/PackageManager;->getPackageArchiveInfo(Ljava/lang/String; I)Landroid/content/pm/PackageInfo;
  0018 move-result-object v0
  001a if-eqz v0, +0d2h
  001e const-string v1, "com.anthen.eclipse"
  0022 iget-object v3, v0, Landroid/content/pm/PackageInfo;->packageName Ljava/lang/String;
  0026 invoke-virtual v1, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  002c move-result v1
  002e if-eqz v1, +0c8h
  0032 new-instance v1, Ljava/util/zip/ZipFile;
  0036 invoke-direct v1, v10, Ljava/util/zip/ZipFile;-><init>(Ljava/io/File;)V
  003c const-string v3, "assets/patcher/maps/android_current.json"
  0040 invoke-virtual v1, v3, Ljava/util/zip/ZipFile;->getEntry(Ljava/lang/String;)Ljava/util/zip/ZipEntry;
  0046 move-result-object v3
  0048 const-string v4, ""
  004c if-eqz v3, +052h
  0050 invoke-virtual v3, Ljava/util/zip/ZipEntry;->getSize()J
  0056 move-result-wide v5
  0058 const-wide/32 v7, 8388608
  005e cmp-long v5, v5, v7
  0062 if-gtz v5, +03fh
  0066 new-instance v5, Landroid/util/JsonReader;
  006a new-instance v6, Ljava/io/InputStreamReader;
  006e invoke-virtual v1, v3, Ljava/util/zip/ZipFile;->getInputStream(Ljava/util/zip/ZipEntry;)Ljava/io/InputStream;
  0074 move-result-object v3
  0076 sget-object v7, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  007a invoke-direct v6, v3, v7, Ljava/io/InputStreamReader;-><init>(Ljava/io/InputStream; Ljava/nio/charset/Charset;)V
  0080 invoke-direct v5, v6, Landroid/util/JsonReader;-><init>(Ljava/io/Reader;)V
  0086 invoke-virtual v5, Landroid/util/JsonReader;->beginObject()V
  008c invoke-virtual v5, Landroid/util/JsonReader;->hasNext()Z
  0092 move-result v3
  0094 if-eqz v3, +017h
  0098 invoke-virtual v5, Landroid/util/JsonReader;->nextName()Ljava/lang/String;
  009e move-result-object v3
  00a0 const-string v6, "version"
  00a4 invoke-virtual v3, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00aa move-result v3
  00ac if-eqz v3, +007h
  00b0 invoke-virtual v5, Landroid/util/JsonReader;->nextString()Ljava/lang/String;
  00b6 move-result-object v3
  00b8 goto +6h
  00ba invoke-virtual v5, Landroid/util/JsonReader;->skipValue()V
  00c0 goto -1ah
  00c2 move-object v3, v4
  00c4 invoke-virtual v5, Landroid/util/JsonReader;->close()V
  00ca goto +14h
  00cc move-exception v10
  00ce invoke-virtual v5, Landroid/util/JsonReader;->close()V
  00d4 goto +5h
  00d6 move-exception v11
  00d8 invoke-virtual v10, v11, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  00de throw v10
  00e0 new-instance v10, Ljava/io/IOException;
  00e4 const-string v11, "APK version map too large"
  00e8 invoke-direct v10, v11, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00ee throw v10
  00f0 move-object v3, v4
  00f2 invoke-virtual v1, Ljava/util/zip/ZipFile;->close()V
  00f8 invoke-virtual v3, Ljava/lang/String;->length()I
  00fe move-result v1
  0100 const/16 v5, 100
  0104 if-le v1, v5, +006h
  0108 invoke-virtual v3, v2, v5, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  010e move-result-object v3
  0110 new-instance v1, Lorg/json/JSONObject;
  0114 invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  011a const-string v2, "packageName"
  011e iget-object v5, v0, Landroid/content/pm/PackageInfo;->packageName Ljava/lang/String;
  0122 invoke-virtual v1, v2, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0128 move-result-object v1
  012a iget-object v2, v0, Landroid/content/pm/PackageInfo;->versionName Ljava/lang/String;
  012e if-nez v2, +003h
  0132 goto +3h
  0134 iget-object v4, v0, Landroid/content/pm/PackageInfo;->versionName Ljava/lang/String;
  0138 const-string v2, "versionName"
  013c invoke-virtual v1, v2, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0142 move-result-object v1
  0144 sget v2, Landroid/os/Build$VERSION;->SDK_INT I
  0148 const/16 v4, 28
  014c if-lt v2, v4, +007h
  0150 invoke-virtual v0, Landroid/content/pm/PackageInfo;->getLongVersionCode()J
  0156 move-result-wide v4
  0158 goto +4h
  015a iget v0, v0, Landroid/content/pm/PackageInfo;->versionCode I
  015e int-to-long v4, v0
  0160 const-string v0, "versionCode"
  0164 invoke-virtual v1, v0, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  016a move-result-object v0
  016c invoke-virtual v3, Ljava/lang/String;->isEmpty()Z
  0172 move-result v1
  0174 if-eqz v1, +004h
  0178 sget-object v3, Lorg/json/JSONObject;->NULL Ljava/lang/Object;
  017c const-string v1, "gameVersion"
  0180 invoke-virtual v0, v1, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0186 move-result-object v0
  0188 const-string v1, "filename"
  018c invoke-virtual v0, v1, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0192 move-result-object v11
  0194 const-string v0, "sha256"
  0198 invoke-static v10, Lcom/personal/aihub/GameDataStore;->hash(Ljava/io/File;)Ljava/lang/String;
  019e move-result-object v10
  01a0 invoke-virtual v11, v0, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01a6 move-result-object v10
  01a8 return-object v10
  01aa move-exception v10
  01ac invoke-virtual v1, Ljava/util/zip/ZipFile;->close()V
  01b2 goto +5h
  01b4 move-exception v11
  01b6 invoke-virtual v10, v11, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  01bc throw v10
  01be new-instance v10, Ljava/io/IOException;
  01c2 const-string v11, "Choose the Eclipse Android APK (com.anthen.eclipse). The selected app was not installed or run."
  01c6 invoke-direct v10, v11, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01cc throw v10
.end method

.method isoStamp()Ljava/lang/String;
  0000 new-instance v0, Ljava/text/SimpleDateFormat;
  0004 const-string v1, "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
  0008 sget-object v2, Ljava/util/Locale;->US Ljava/util/Locale;
  000c invoke-direct v0, v1, v2, Ljava/text/SimpleDateFormat;-><init>(Ljava/lang/String; Ljava/util/Locale;)V
  0012 const-string v1, "UTC"
  0016 invoke-static v1, Ljava/util/TimeZone;->getTimeZone(Ljava/lang/String;)Ljava/util/TimeZone;
  001c move-result-object v1
  001e invoke-virtual v0, v1, Ljava/text/SimpleDateFormat;->setTimeZone(Ljava/util/TimeZone;)V
  0024 new-instance v1, Ljava/util/Date;
  0028 invoke-direct v1, Ljava/util/Date;-><init>()V
  002e invoke-virtual v0, v1, Ljava/text/SimpleDateFormat;->format(Ljava/util/Date;)Ljava/lang/String;
  0034 move-result-object v0
  0036 return-object v0
.end method

.method lambda$1(Landroid/view/View; Landroid/view/WindowInsets;)Landroid/view/WindowInsets;
  0000 invoke-static Landroid/view/WindowInsets$Type;->systemBars()I
  0006 move-result v0
  0008 invoke-static Landroid/view/WindowInsets$Type;->displayCutout()I
  000e move-result v1
  0010 or-int/2addr v0, v1
  0012 invoke-static Landroid/view/WindowInsets$Type;->ime()I
  0018 move-result v1
  001a or-int/2addr v0, v1
  001c invoke-virtual v5, v0, Landroid/view/WindowInsets;->getInsets(I)Landroid/graphics/Insets;
  0022 move-result-object v0
  0024 iget v1, v0, Landroid/graphics/Insets;->left I
  0028 iget v2, v0, Landroid/graphics/Insets;->top I
  002c iget v3, v0, Landroid/graphics/Insets;->right I
  0030 iget v0, v0, Landroid/graphics/Insets;->bottom I
  0034 invoke-virtual v4, v1, v2, v3, v0, Landroid/view/View;->setPadding(I I I I)V
  003a return-object v5
.end method

.method listPatches()Lorg/json/JSONArray;
  0000 new-instance v0, Lorg/json/JSONArray;
  0004 invoke-direct v0, Lorg/json/JSONArray;-><init>()V
  000a new-instance v1, Ljava/io/File;
  000e iget-object v2, v7, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0012 const-string v3, "patches"
  0016 invoke-direct v1, v2, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  001c invoke-virtual v1, Ljava/io/File;->listFiles()[Ljava/io/File;
  0022 move-result-object v1
  0024 if-eqz v1, +025h
  0028 array-length v2, v1
  002a const/4 v3, 0
  002c if-ge v3, v2, +021h
  0030 aget-object v4, v1, v3
  0034 invoke-virtual v4, Ljava/io/File;->getName()Ljava/lang/String;
  003a move-result-object v5
  003c const-string v6, ".json"
  0040 invoke-virtual v5, v6, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  0046 move-result v5
  0048 if-eqz v5, +010h
  004c new-instance v5, Lorg/json/JSONObject;
  0050 const/high16 v6, 20971520
  0054 invoke-static v4, v6, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  005a move-result-object v4
  005c invoke-direct v5, v4, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0062 invoke-virtual v0, v5, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0068 add-int/lit8 v3, v3, 1
  006c goto -20h
  006e return-object v0
.end method

.method listProjects()Lorg/json/JSONArray;
  0000 const-string v0, "author"
  0004 const-string v1, "source"
  0008 const-string v2, "updatedAt"
  000c const-string v3, "targetId"
  0010 const-string v4, "key"
  0014 new-instance v5, Lorg/json/JSONArray;
  0018 invoke-direct v5, Lorg/json/JSONArray;-><init>()V
  001e move-object/from16 v6, v21
  0022 iget-object v7, v6, Lcom/personal/aihub/CreatorActivity;->projects Ljava/io/File;
  0026 invoke-virtual v7, Ljava/io/File;->listFiles()[Ljava/io/File;
  002c move-result-object v7
  002e if-eqz v7, +111h
  0032 array-length v8, v7
  0034 const/4 v9, 0
  0036 move v10, v9
  0038 if-ge v10, v8, +10ch
  003c aget-object v11, v7, v10
  0040 invoke-virtual v11, Ljava/io/File;->getName()Ljava/lang/String;
  0046 move-result-object v12
  0048 const-string v13, ".json"
  004c invoke-virtual v12, v13, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  0052 move-result v12
  0054 if-eqz v12, +0f1h
  0058 new-instance v12, Lorg/json/JSONObject;
  005c const/high16 v13, 20971520
  0060 invoke-static v11, v13, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  0066 move-result-object v11
  0068 invoke-direct v12, v11, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  006e const-string v11, "tables"
  0072 invoke-virtual v12, v11, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0078 move-result-object v11
  007a const-string v13, "cards"
  007e invoke-virtual v11, v13, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0084 move-result-object v11
  0086 invoke-virtual v11, v9, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  008c move-result-object v11
  008e const-string v13, "cardOverrides"
  0092 invoke-virtual v12, v13, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0098 move-result-object v13
  009a new-instance v14, Lorg/json/JSONObject;
  009e invoke-direct v14, Lorg/json/JSONObject;-><init>()V
  00a4 invoke-virtual v12, v4, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  00aa move-result-object v15
  00ac invoke-virtual v14, v4, v15, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00b2 move-result-object v14
  00b4 const-string v15, "name"
  00b8 if-nez v13, +009h
  00bc invoke-virtual v11, v15, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  00c2 move-result-object v16
  00c4 move-object/from16 v9, v16
  00c8 goto +9h
  00ca invoke-virtual v11, v15, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  00d0 move-result-object v9
  00d2 invoke-virtual v13, v15, v9, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  00d8 move-result-object v9
  00da invoke-virtual v14, v15, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00e0 move-result-object v9
  00e2 invoke-virtual v12, v3, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  00e8 move-result-wide v14
  00ea invoke-virtual v9, v3, v14, v15, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  00f0 move-result-object v9
  00f2 const-string v14, "reservedIds"
  00f6 invoke-static v12, Lcom/personal/aihub/ProjectFormsData;->reservedIds(Lorg/json/JSONObject;)Lorg/json/JSONArray;
  00fc move-result-object v15
  00fe invoke-virtual v9, v14, v15, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0104 move-result-object v9
  0106 invoke-virtual v12, v2, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  010c move-result-object v14
  010e invoke-virtual v9, v2, v14, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0114 move-result-object v9
  0116 const-string v14, "rarity"
  011a if-nez v13, +007h
  011e invoke-virtual v11, v14, Lorg/json/JSONObject;->optInt(Ljava/lang/String;)I
  0124 move-result v15
  0126 goto +9h
  0128 invoke-virtual v11, v14, Lorg/json/JSONObject;->optInt(Ljava/lang/String;)I
  012e move-result v15
  0130 invoke-virtual v13, v14, v15, Lorg/json/JSONObject;->optInt(Ljava/lang/String; I)I
  0136 move-result v15
  0138 invoke-virtual v9, v14, v15, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  013e move-result-object v9
  0140 const-string v14, "element"
  0144 if-nez v13, +007h
  0148 invoke-virtual v11, v14, Lorg/json/JSONObject;->optInt(Ljava/lang/String;)I
  014e move-result v15
  0150 goto +9h
  0152 invoke-virtual v11, v14, Lorg/json/JSONObject;->optInt(Ljava/lang/String;)I
  0158 move-result v15
  015a invoke-virtual v13, v14, v15, Lorg/json/JSONObject;->optInt(Ljava/lang/String; I)I
  0160 move-result v15
  0162 invoke-virtual v9, v14, v15, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0168 move-result-object v9
  016a const-string v14, "resourceId"
  016e const-string v15, "resource_id"
  0172 if-nez v13, +00fh
  0176 invoke-virtual v11, v15, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  017c move-result-wide v17
  017e move-wide/from16 v19, v17
  0182 move-object/from16 v17, v2
  0186 move-object/from16 v18, v3
  018a move-wide/from16 v2, v19
  018e goto +dh
  0190 move-object/from16 v17, v2
  0194 move-object/from16 v18, v3
  0198 invoke-virtual v11, v15, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  019e move-result-wide v2
  01a0 invoke-virtual v13, v15, v2, v3, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  01a6 move-result-wide v2
  01a8 invoke-virtual v9, v14, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  01ae move-result-object v2
  01b0 const-string v3, "origin"
  01b4 const-string v9, "libraryOrigin"
  01b8 const-string v11, "created"
  01bc invoke-virtual v12, v9, v11, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  01c2 move-result-object v9
  01c4 invoke-virtual v2, v3, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01ca move-result-object v2
  01cc const-string v3, "sparkingAnimations"
  01d0 invoke-static v12, Lcom/personal/aihub/CreatorActivity;->hasSparkingAnimations(Lorg/json/JSONObject;)Z
  01d6 move-result v9
  01d8 invoke-virtual v2, v3, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  01de move-result-object v2
  01e0 const-string v3, "sourceDatabase"
  01e4 invoke-virtual v12, v1, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  01ea move-result-object v9
  01ec if-nez v9, +005h
  01f0 const-string v9, ""
  01f4 goto +bh
  01f6 invoke-virtual v12, v1, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  01fc move-result-object v9
  01fe const-string v11, "database"
  0202 invoke-virtual v9, v11, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0208 move-result-object v9
  020a invoke-virtual v2, v3, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0210 move-result-object v2
  0212 const-string v3, "patch"
  0216 invoke-virtual v12, v3, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  021c move-result-object v3
  021e invoke-virtual v3, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0224 move-result-object v3
  0226 invoke-virtual v2, v0, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  022c move-result-object v2
  022e invoke-virtual v5, v2, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0234 goto +5h
  0236 move-object/from16 v17, v2
  023a move-object/from16 v18, v3
  023e add-int/lit8 v10, v10, 1
  0242 move-object/from16 v2, v17
  0246 move-object/from16 v3, v18
  024a const/4 v9, 0
  024c goto/16 -10ah
  0250 return-object v5
.end method

.method mime(Ljava/lang/String;)Ljava/lang/String;
  0000 sget-object v0, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  0004 invoke-virtual v1, v0, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  000a move-result-object v1
  000c const-string v0, ".wasm"
  0010 invoke-virtual v1, v0, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  0016 move-result v0
  0018 if-eqz v0, +005h
  001c const-string v1, "application/wasm"
  0020 return-object v1
  0022 const-string v0, ".html"
  0026 invoke-virtual v1, v0, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  002c move-result v0
  002e if-eqz v0, +005h
  0032 const-string v1, "text/html"
  0036 return-object v1
  0038 const-string v0, ".js"
  003c invoke-virtual v1, v0, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  0042 move-result v0
  0044 if-eqz v0, +005h
  0048 const-string v1, "application/javascript"
  004c return-object v1
  004e const-string v0, ".css"
  0052 invoke-virtual v1, v0, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  0058 move-result v0
  005a if-eqz v0, +005h
  005e const-string v1, "text/css"
  0062 return-object v1
  0064 const-string v0, ".json"
  0068 invoke-virtual v1, v0, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  006e move-result v0
  0070 if-eqz v0, +005h
  0074 const-string v1, "application/json"
  0078 return-object v1
  007a const-string v0, ".png"
  007e invoke-virtual v1, v0, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  0084 move-result v0
  0086 if-eqz v0, +005h
  008a const-string v1, "image/png"
  008e return-object v1
  0090 const-string v0, ".svg"
  0094 invoke-virtual v1, v0, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  009a move-result v0
  009c if-eqz v0, +005h
  00a0 const-string v1, "image/svg+xml"
  00a4 return-object v1
  00a6 const-string v0, ".jpg"
  00aa invoke-virtual v1, v0, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  00b0 move-result v0
  00b2 if-nez v0, +024h
  00b6 const-string v0, ".jpeg"
  00ba invoke-virtual v1, v0, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  00c0 move-result v0
  00c2 if-eqz v0, +003h
  00c6 goto +1ah
  00c8 const-string v0, ".webp"
  00cc invoke-virtual v1, v0, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  00d2 move-result v0
  00d4 if-eqz v0, +005h
  00d8 const-string v1, "image/webp"
  00dc return-object v1
  00de const-string v0, ".gif"
  00e2 invoke-virtual v1, v0, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  00e8 move-result v1
  00ea if-eqz v1, +005h
  00ee const-string v1, "image/gif"
  00f2 goto +3h
  00f4 const-string v1, "application/octet-stream"
  00f8 return-object v1
  00fa const-string v1, "image/jpeg"
  00fe return-object v1
.end method

.method normalizeAsset(Ljava/lang/String;)Ljava/lang/String;
  0000 move-object/from16 v0, v24
  0004 invoke-static/range v24, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  000a move-result v1
  000c if-eqz v1, +061h
  0010 const-string v1, "/"
  0014 invoke-virtual v0, v1, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  001a move-result-object v2
  001c new-instance v3, Ljava/util/HashSet;
  0020 const-string v22, "se"
  0024 const-string v23, "voice"
  0028 const-string v4, "tutorial0"
  002c const-string v5, "character"
  0030 const-string v6, "lua"
  0034 const-string v7, "ingame"
  0038 const-string v8, "layout"
  003c const-string v9, "bgm"
  0040 const-string v10, "movie"
  0044 const-string v11, "card_transform"
  0048 const-string v12, "card_metamorphic"
  004c const-string v13, "card_category"
  0050 const-string v14, "card_costume"
  0054 const-string v15, "dokkan_field"
  0058 const-string v16, "origin"
  005c const-string v17, "outgame"
  0060 const-string v18, "item"
  0064 const-string v19, "comic_text"
  0068 const-string v20, "fonts"
  006c const-string v21, "shader"
  0070 filled-new-array/range v4 ... v23, [Ljava/lang/String;
  0076 move-result-object v4
  0078 invoke-static v4, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  007e move-result-object v4
  0080 invoke-direct v3, v4, Ljava/util/HashSet;-><init>(Ljava/util/Collection;)V
  0086 const/4 v4, 0
  0088 array-length v5, v2
  008a if-ge v4, v5, +019h
  008e aget-object v5, v2, v4
  0092 invoke-virtual v3, v5, Ljava/util/HashSet;->contains(Ljava/lang/Object;)Z
  0098 move-result v5
  009a if-eqz v5, +00eh
  009e array-length v0, v2
  00a0 invoke-static v2, v4, v0, Ljava/util/Arrays;->copyOfRange([Ljava/lang/Object; I I)[Ljava/lang/Object;
  00a6 move-result-object v0
  00a8 check-cast v0, [Ljava/lang/CharSequence;
  00ac invoke-static v1, v0, Ljava/lang/String;->join(Ljava/lang/CharSequence; [Ljava/lang/CharSequence;)Ljava/lang/String;
  00b2 move-result-object v0
  00b4 return-object v0
  00b6 add-int/lit8 v4, v4, 1
  00ba goto -19h
  00bc const-string v1, "^(assets|files|uncompressed)/"
  00c0 const-string v2, ""
  00c4 invoke-virtual v0, v1, v2, Ljava/lang/String;->replaceFirst(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  00ca move-result-object v0
  00cc return-object v0
  00ce new-instance v0, Ljava/io/IOException;
  00d2 const-string v1, "Unsafe archive path"
  00d6 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00dc throw v0
.end method

.method patchFile(Ljava/lang/String;)Ljava/io/File;
  0000 const-string v0, "[a-f0-9-]{36}"
  0004 invoke-virtual v4, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  000a move-result v0
  000c if-eqz v0, +029h
  0010 new-instance v0, Ljava/io/File;
  0014 iget-object v1, v3, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0018 const-string v2, "patches"
  001c invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0022 invoke-virtual v0, Ljava/io/File;->mkdirs()Z
  0028 new-instance v1, Ljava/io/File;
  002c new-instance v2, Ljava/lang/StringBuilder;
  0030 invoke-direct v2, Ljava/lang/StringBuilder;-><init>()V
  0036 invoke-static v4, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  003c move-result-object v4
  003e invoke-virtual v2, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0044 const-string v4, ".eclp"
  0048 invoke-virtual v2, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  004e invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0054 move-result-object v4
  0056 invoke-direct v1, v0, v4, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  005c return-object v1
  005e new-instance v4, Ljava/io/IOException;
  0062 const-string v0, "Invalid patch key"
  0066 invoke-direct v4, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  006c throw v4
.end method

.method prepareSparkingSnapshot()V
  0000 invoke-direct v8, Lcom/personal/aihub/CreatorActivity;->sparkingStore()Lcom/personal/aihub/GameDataStore;
  0006 move-result-object v0
  0008 invoke-virtual v0, Lcom/personal/aihub/GameDataStore;->state()Lorg/json/JSONObject;
  000e move-result-object v0
  0010 if-eqz v0, +003h
  0014 return-void 
  0016 new-instance v0, Ljava/io/File;
  001a invoke-virtual v8, Lcom/personal/aihub/CreatorActivity;->getCacheDir()Ljava/io/File;
  0020 move-result-object v1
  0022 new-instance v2, Ljava/lang/StringBuilder;
  0026 const-string v3, "sparking-snapshot-"
  002a invoke-direct v2, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0030 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0036 move-result-object v3
  0038 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  003e const-string v3, ".db"
  0042 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0048 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  004e move-result-object v2
  0050 invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0056 invoke-virtual v8, Lcom/personal/aihub/CreatorActivity;->getAssets()Landroid/content/res/AssetManager;
  005c move-result-object v1
  005e const-string v2, "sparking-reference.db"
  0062 invoke-virtual v1, v2, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;
  0068 move-result-object v1
  006a new-instance v2, Ljava/io/FileOutputStream;
  006e invoke-direct v2, v0, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0074 const-wide/32 v3, 536870912
  007a invoke-static v1, v2, v3, v4, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  0080 invoke-virtual v2, Ljava/io/FileOutputStream;->close()V
  0086 if-eqz v1, +005h
  008a invoke-virtual v1, Ljava/io/InputStream;->close()V
  0090 const-string v1, "cf13b8553448507ad723e17a7b347e6eac4d7627a2e4fff56c0f7747660dffd8"
  0094 invoke-static v0, Lcom/personal/aihub/GameDataStore;->hash(Ljava/io/File;)Ljava/lang/String;
  009a move-result-object v2
  009c invoke-virtual v1, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00a2 move-result v1
  00a4 if-eqz v1, +03eh
  00a8 const/4 v1, 1
  00aa invoke-direct v8, v0, v1, Lcom/personal/aihub/CreatorActivity;->verifyDb(Ljava/io/File; Z)J
  00b0 move-result-wide v1
  00b2 invoke-direct v8, Lcom/personal/aihub/CreatorActivity;->sparkingStore()Lcom/personal/aihub/GameDataStore;
  00b8 move-result-object v3
  00ba new-instance v4, Lorg/json/JSONObject;
  00be invoke-direct v4, Lorg/json/JSONObject;-><init>()V
  00c4 const-string v5, "source"
  00c8 const-string v6, "Sparking game database · built-in snapshot"
  00cc invoke-virtual v4, v5, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00d2 move-result-object v4
  00d4 const-string v5, "sourceType"
  00d8 const-string v6, "sparking-bundled"
  00dc invoke-virtual v4, v5, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00e2 move-result-object v4
  00e4 const-string v5, "date"
  00e8 const-string v6, "2026-10-17"
  00ec invoke-virtual v4, v5, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00f2 move-result-object v4
  00f4 const-string v5, "latestVersion"
  00f8 const-wide/32 v6, 1791992148
  00fe invoke-virtual v4, v5, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0104 move-result-object v4
  0106 const-string v5, "count"
  010a invoke-virtual v4, v5, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0110 move-result-object v1
  0112 invoke-virtual v3, v0, v1, Lcom/personal/aihub/GameDataStore;->commit(Ljava/io/File; Lorg/json/JSONObject;)V
  0118 invoke-virtual v0, Ljava/io/File;->delete()Z
  011e return-void 
  0120 new-instance v1, Ljava/io/IOException;
  0124 const-string v2, "The built-in Sparking catalogue is incomplete. Reinstall the complete APK."
  0128 invoke-direct v1, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  012e throw v1
  0130 move-exception v3
  0132 invoke-virtual v2, Ljava/io/FileOutputStream;->close()V
  0138 goto +5h
  013a move-exception v2
  013c invoke-virtual v3, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0142 throw v3
  0144 move-exception v2
  0146 if-eqz v1, +00ah
  014a invoke-virtual v1, Ljava/io/InputStream;->close()V
  0150 goto +5h
  0152 move-exception v1
  0154 invoke-virtual v2, v1, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  015a throw v2
  015c move-exception v1
  015e invoke-virtual v0, Ljava/io/File;->delete()Z
  0164 throw v1
.end method

.method previewAnimation(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 move-object/from16 v6, v37
  0004 move-object/from16 v7, v38
  0008 const-string v8, "previewAppearance"
  000c invoke-virtual v7, v8, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  0012 move-result v0
  0014 const/4 v2, 2
  0016 if-eqz v0, +068h
  001a invoke-virtual v7, v8, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0020 move-result-object v0
  0022 const-string v4, "Choose valid preview artwork"
  0026 if-eqz v0, +05ah
  002a invoke-virtual v0, Lorg/json/JSONObject;->length()I
  0030 move-result v5
  0032 if-ne v5, v2, +054h
  0036 new-instance v5, Lorg/json/JSONObject;
  003a invoke-direct v5, Lorg/json/JSONObject;-><init>()V
  0040 const-string v9, "actorId"
  0044 const-string v10, "artCardId"
  0048 filled-new-array v9, v10, [Ljava/lang/String;
  004e move-result-object v9
  0050 const/4 v10, 0
  0052 if-ge v10, v2, +042h
  0056 aget-object v11, v9, v10
  005a invoke-virtual v0, v11, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  0060 move-result-object v12
  0062 instance-of v13, v12, Ljava/lang/Number;
  0066 if-eqz v13, +032h
  006a check-cast v12, Ljava/lang/Number;
  006e invoke-virtual v12, Ljava/lang/Number;->doubleValue()D
  0074 move-result-wide v12
  0076 invoke-static v12, v13, Ljava/lang/Double;->isFinite(D)Z
  007c move-result v14
  007e if-eqz v14, +020h
  0082 invoke-static v12, v13, Ljava/lang/Math;->floor(D)D
  0088 move-result-wide v14
  008a cmpl-double v14, v12, v14
  008e if-nez v14, +018h
  0092 const-wide/high16 v14, 4607182418800017408
  0096 cmpg-double v14, v12, v14
  009a if-ltz v14, +012h
  009e const-wide v14, 4845873199050653695
  00a8 cmpl-double v14, v12, v14
  00ac if-gtz v14, +009h
  00b0 double-to-long v12, v12
  00b2 invoke-virtual v5, v11, v12, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  00b8 add-int/lit8 v10, v10, 1
  00bc goto -35h
  00be new-instance v0, Ljava/io/IOException;
  00c2 invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00c8 throw v0
  00ca new-instance v0, Ljava/io/IOException;
  00ce invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00d4 throw v0
  00d6 move-object v9, v5
  00d8 goto +8h
  00da new-instance v0, Ljava/io/IOException;
  00de invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00e4 throw v0
  00e6 const/4 v9, 0
  00e8 const-string v10, "effectPacks"
  00ec invoke-virtual v7, v10, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  00f2 move-result v0
  00f4 if-eqz v0, +011h
  00f8 invoke-virtual v7, v10, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  00fe move-result-object v0
  0100 if-eqz v0, +003h
  0104 goto +9h
  0106 new-instance v0, Ljava/io/IOException;
  010a const-string v1, "Choose valid edited movies"
  010e invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0114 throw v0
  0116 invoke-virtual v7, v10, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  011c move-result-object v0
  011e invoke-static v0, Lcom/personal/aihub/PreviewEffectPacks;->normalize(Ljava/lang/Object;)Lorg/json/JSONArray;
  0124 move-result-object v11
  0126 const-string v12, "sparkingEffectIds"
  012a invoke-virtual v7, v12, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  0130 move-result v0
  0132 if-eqz v0, +007h
  0136 invoke-virtual v7, v12, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  013c move-result-object v0
  013e goto +2h
  0140 const/4 v0, 0
  0142 invoke-static v0, Lcom/personal/aihub/PreviewMetadata;->sparkingEffects(Ljava/lang/Object;)Lorg/json/JSONArray;
  0148 move-result-object v13
  014a invoke-static v11, v13, Lcom/personal/aihub/PreviewMetadata;->validateEffectSources(Lorg/json/JSONArray; Lorg/json/JSONArray;)V
  0150 const-string v14, "sparkingVersion"
  0154 invoke-virtual v7, v14, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  015a move-result v0
  015c if-eqz v0, +007h
  0160 invoke-virtual v7, v14, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  0166 move-result-object v0
  0168 goto +2h
  016a const/4 v0, 0
  016c invoke-static v0, Lcom/personal/aihub/PreviewMetadata;->normalizeVersion(Ljava/lang/Object;)J
  0172 move-result-wide v4
  0174 invoke-virtual v13, Lorg/json/JSONArray;->length()I
  017a move-result v0
  017c const-string v15, "sourceDatabase"
  0180 const-string v2, "sparking"
  0184 if-gtz v0, +00ch
  0188 invoke-virtual v7, v15, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  018e move-result-object v0
  0190 invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0196 move-result v0
  0198 if-eqz v0, +00ah
  019c invoke-direct/range v37, Lcom/personal/aihub/CreatorActivity;->prepareSparkingSnapshot()V
  01a2 iget-object v0, v6, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  01a6 invoke-static v0, v2, v4, v5, Lcom/personal/aihub/PreviewMetadata;->databaseFile(Ljava/io/File; Ljava/lang/String; J)Ljava/io/File;
  01ac const-string v0, "assets"
  01b0 invoke-virtual v7, v0, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  01b6 move-result-object v17
  01b8 invoke-virtual v7, v0, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  01be move-result v18
  01c0 if-eqz v18, +00dh
  01c4 if-eqz v17, +003h
  01c8 goto +9h
  01ca new-instance v0, Ljava/io/IOException;
  01ce const-string v1, "Choose valid preview pictures"
  01d2 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01d8 throw v0
  01da invoke-static/range v17, Lcom/personal/aihub/GameAssets;->overlayMap(Lorg/json/JSONArray;)Ljava/util/Map;
  01e0 new-instance v1, Lcom/personal/aihub/PreviewCache;
  01e4 iget-object v3, v6, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  01e8 invoke-direct v1, v3, Lcom/personal/aihub/PreviewCache;-><init>(Ljava/io/File;)V
  01ee const-string v3, "mode"
  01f2 move-object/from16 v19, v0
  01f6 const-string v0, "lua"
  01fa move-object/from16 v20, v2
  01fe invoke-virtual v7, v3, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0204 move-result-object v2
  0206 move-wide/from16 v21, v4
  020a const-string v4, "pack"
  020e const-string v5, "movie"
  0212 const-string v6, "training"
  0216 move-object/from16 v23, v14
  021a const-string v14, "awakening"
  021e filled-new-array v0, v4, v5, v6, v14, [Ljava/lang/String;
  0224 move-result-object v0
  0226 invoke-static v0, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  022c move-result-object v0
  022e invoke-interface v0, v2, Ljava/util/List;->contains(Ljava/lang/Object;)Z
  0234 move-result v0
  0236 if-eqz v0, +2a4h
  023a invoke-virtual v2, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0240 move-result v0
  0242 if-eqz v0, +005h
  0246 const-string v0, "lwf-player"
  024a goto +ch
  024c invoke-virtual v2, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0252 move-result v0
  0254 if-eqz v0, +005h
  0258 const-string v0, "usm-player"
  025c goto +3h
  025e const-string v0, "lua-player"
  0262 invoke-virtual v1, Lcom/personal/aihub/PreviewCache;->offline()Z
  0268 move-result v24
  026a if-eqz v24, +01fh
  026e move-object/from16 v24, v12
  0272 new-instance v12, Ljava/lang/StringBuilder;
  0276 move-object/from16 v25, v13
  027a const-string v13, "https://dokkan-eclipse.com/tools/"
  027e invoke-direct v12, v13, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0284 invoke-virtual v12, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  028a const-string v0, "/"
  028e invoke-virtual v12, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0294 invoke-virtual v12, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  029a move-result-object v0
  029c const/high16 v12, 2097152
  02a0 invoke-virtual v1, v0, v12, Lcom/personal/aihub/PreviewCache;->text(Ljava/lang/String; I)Ljava/lang/String;
  02a6 goto +5h
  02a8 move-object/from16 v24, v12
  02ac move-object/from16 v25, v13
  02b0 const-string v0, "text"
  02b4 invoke-virtual v7, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  02ba move-result-object v12
  02bc const-string v1, "path"
  02c0 invoke-virtual v7, v1, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  02c6 move-result-object v13
  02c8 const-string v1, "resourcePath"
  02cc invoke-virtual v7, v1, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  02d2 move-result-object v1
  02d4 invoke-virtual v2, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  02da move-result v4
  02dc if-eqz v4, +019h
  02e0 const-string v4, "(?i)[a-z0-9_./-]+\.lwf"
  02e4 invoke-virtual v1, v4, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  02ea move-result v4
  02ec if-eqz v4, +009h
  02f0 invoke-static v1, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  02f6 move-result v4
  02f8 if-eqz v4, +003h
  02fc goto +3ah
  02fe new-instance v0, Ljava/io/IOException;
  0302 const-string v1, "Choose a valid visual pack"
  0306 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  030c throw v0
  030e invoke-virtual v2, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0314 move-result v4
  0316 if-eqz v4, +019h
  031a const-string v4, "(?i)movie/[a-z0-9_./-]+\.usm"
  031e invoke-virtual v1, v4, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0324 move-result v4
  0326 if-eqz v4, +009h
  032a invoke-static v1, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  0330 move-result v4
  0332 if-eqz v4, +003h
  0336 goto +1dh
  0338 new-instance v0, Ljava/io/IOException;
  033c const-string v1, "Choose a movie from the game video browser"
  0340 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0346 throw v0
  0348 invoke-virtual v12, Ljava/lang/String;->length()I
  034e move-result v4
  0350 const/high16 v5, 2097152
  0354 if-gt v4, v5, +20bh
  0358 invoke-virtual v12, Ljava/lang/String;->isEmpty()Z
  035e move-result v4
  0360 if-eqz v4, +008h
  0364 invoke-static v13, Lcom/personal/aihub/CreatorActivity;->validAnimationPath(Ljava/lang/String;)Z
  036a move-result v4
  036c if-eqz v4, +1ffh
  0370 invoke-virtual v2, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0376 move-result v4
  0378 move-object/from16 v26, v10
  037c move-object/from16 v27, v11
  0380 if-nez v4, +011h
  0384 invoke-virtual v2, v14, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  038a move-result v4
  038c if-eqz v4, +003h
  0390 goto +9h
  0392 move-object/from16 v29, v8
  0396 move-object/from16 v30, v9
  039a const/16 v16, 0
  039e goto/16 +0b9h
  03a2 new-instance v4, Ljava/lang/StringBuilder;
  03a6 const-string v5, "ab_script/"
  03aa invoke-direct v4, v5, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  03b0 invoke-virtual v2, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  03b6 move-result v5
  03b8 if-eqz v5, +003h
  03bc goto +3h
  03be const-string v6, "awaken"
  03c2 invoke-virtual v4, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  03c8 const-string v5, "/a[0-9]{4}\.lua"
  03cc invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  03d2 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  03d8 move-result-object v4
  03da invoke-virtual v13, v4, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  03e0 move-result v4
  03e2 if-eqz v4, +1bah
  03e6 const-string v4, "trainingItems"
  03ea invoke-virtual v7, v4, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  03f0 move-result-object v4
  03f2 if-eqz v4, +1a8h
  03f6 invoke-virtual v4, Lorg/json/JSONArray;->length()I
  03fc move-result v5
  03fe const/4 v6, 5
  0400 if-gt v5, v6, +1a1h
  0404 const/4 v5, 0
  0406 invoke-virtual v4, Lorg/json/JSONArray;->length()I
  040c move-result v6
  040e if-ge v5, v6, +07bh
  0412 invoke-virtual v4, v5, Lorg/json/JSONArray;->optJSONObject(I)Lorg/json/JSONObject;
  0418 move-result-object v6
  041a if-eqz v6, +06dh
  041e const-string v14, "rarity"
  0422 const-string v10, "id"
  0426 filled-new-array v10, v14, [Ljava/lang/String;
  042c move-result-object v11
  042e move-object/from16 v16, v4
  0432 const/4 v4, 2
  0434 const/4 v14, 0
  0436 if-ge v14, v4, +056h
  043a aget-object v4, v11, v14
  043e move-object/from16 v28, v11
  0442 invoke-virtual v6, v4, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  0448 move-result-object v11
  044a move-object/from16 v29, v8
  044e move-object/from16 v30, v9
  0452 const-wide/16 v8, -1
  0456 invoke-virtual v6, v4, v8, v9, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  045c move-result-wide v8
  045e invoke-virtual v4, v10, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0464 move-result v31
  0466 if-eqz v31, +005h
  046a const-wide/16 v31, 1
  046e goto +3h
  0470 const-wide/16 v31, 0
  0474 invoke-virtual v4, v10, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  047a move-result v4
  047c if-eqz v4, +006h
  0480 const-wide/32 v33, 9999999
  0486 goto +3h
  0488 const-wide/16 v33, 4
  048c instance-of v4, v11, Ljava/lang/Number;
  0490 if-eqz v4, +021h
  0494 check-cast v11, Ljava/lang/Number;
  0498 invoke-virtual v11, Ljava/lang/Number;->doubleValue()D
  049e move-result-wide v35
  04a0 move-object v4, v10
  04a2 long-to-double v10, v8
  04a4 cmpl-double v10, v35, v10
  04a8 if-nez v10, +015h
  04ac cmp-long v10, v8, v31
  04b0 if-ltz v10, +011h
  04b4 cmp-long v8, v8, v33
  04b8 if-gtz v8, +00dh
  04bc add-int/lit8 v14, v14, 1
  04c0 move-object v10, v4
  04c2 move-object/from16 v11, v28
  04c6 move-object/from16 v8, v29
  04ca move-object/from16 v9, v30
  04ce const/4 v4, 2
  04d0 goto -4dh
  04d2 new-instance v0, Ljava/io/IOException;
  04d6 const-string v1, "Choose valid scene items"
  04da invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  04e0 throw v0
  04e2 move-object/from16 v29, v8
  04e6 move-object/from16 v30, v9
  04ea add-int/lit8 v5, v5, 1
  04ee move-object/from16 v4, v16
  04f2 goto -76h
  04f4 new-instance v0, Ljava/io/IOException;
  04f8 const-string v1, "Choose valid scene items"
  04fc invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0502 throw v0
  0504 move-object/from16 v16, v4
  0508 move-object/from16 v29, v8
  050c move-object/from16 v30, v9
  0510 new-instance v4, Lorg/json/JSONObject;
  0514 invoke-direct v4, Lorg/json/JSONObject;-><init>()V
  051a invoke-virtual v4, v3, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0520 move-result-object v3
  0522 const-string v4, "assetKey"
  0526 invoke-virtual v7, v4, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  052c move-result-object v5
  052e invoke-virtual v3, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0534 move-result-object v3
  0536 const-string v5, "resourcePath"
  053a invoke-virtual v3, v5, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0540 move-result-object v1
  0542 const-string v3, "scene"
  0546 invoke-virtual v7, v3, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  054c move-result-object v3
  054e const-string v5, "scene"
  0552 invoke-virtual v1, v5, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0558 move-result-object v1
  055a invoke-virtual v1, v0, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0560 move-result-object v0
  0562 const-string v1, "path"
  0566 invoke-virtual v0, v1, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  056c move-result-object v6
  056e invoke-virtual v7, v4, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0574 move-result-object v4
  0576 move-object/from16 v8, v19
  057a move-object/from16 v0, v37
  057e move-object v1, v2
  0580 move-object/from16 v9, v20
  0584 move-object v2, v13
  0586 move-object v3, v12
  0588 move-wide/from16 v10, v21
  058c move-object/from16 v5, v17
  0590 invoke-direct/range v0 ... v5, Lcom/personal/aihub/CreatorActivity;->verifiedMusicPath(Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray;)Ljava/lang/String;
  0596 move-result-object v0
  0598 const-string v1, "forgeVerifiedMusicPath"
  059c invoke-virtual v6, v1, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  05a2 move-result-object v0
  05a4 const-string v1, "name"
  05a8 const-string v2, "Animation preview"
  05ac invoke-virtual v7, v1, v2, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  05b2 move-result-object v1
  05b4 const-string v2, "name"
  05b8 invoke-virtual v0, v2, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  05be move-result-object v0
  05c0 const-string v1, "attackerId"
  05c4 const-wide/32 v2, 1000010
  05ca invoke-virtual v7, v1, v2, v3, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  05d0 move-result-wide v1
  05d2 const-wide/16 v3, 1
  05d6 invoke-static v3, v4, v1, v2, Ljava/lang/Math;->max(J J)J
  05dc move-result-wide v1
  05de const-string v5, "attackerId"
  05e2 invoke-virtual v0, v5, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  05e8 move-result-object v0
  05ea const-string v1, "enemyId"
  05ee const-wide/32 v5, 1000020
  05f4 invoke-virtual v7, v1, v5, v6, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  05fa move-result-wide v1
  05fc invoke-static v3, v4, v1, v2, Ljava/lang/Math;->max(J J)J
  0602 move-result-wide v1
  0604 const-string v3, "enemyId"
  0608 invoke-virtual v0, v3, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  060e move-result-object v0
  0610 invoke-virtual v7, v15, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0616 move-result-object v1
  0618 invoke-virtual v9, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  061e move-result v1
  0620 if-eqz v1, +005h
  0624 invoke-virtual v0, v15, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  062a if-eqz v17, +00eh
  062e new-instance v1, Lorg/json/JSONArray;
  0632 invoke-virtual/range v17, Lorg/json/JSONArray;->toString()Ljava/lang/String;
  0638 move-result-object v2
  063a invoke-direct v1, v2, Lorg/json/JSONArray;-><init>(Ljava/lang/String;)V
  0640 invoke-virtual v0, v8, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0646 if-eqz v16, +010h
  064a new-instance v1, Lorg/json/JSONArray;
  064e invoke-virtual/range v16, Lorg/json/JSONArray;->toString()Ljava/lang/String;
  0654 move-result-object v2
  0656 invoke-direct v1, v2, Lorg/json/JSONArray;-><init>(Ljava/lang/String;)V
  065c const-string v2, "trainingItems"
  0660 invoke-virtual v0, v2, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0666 if-eqz v30, +009h
  066a move-object/from16 v1, v29
  066e move-object/from16 v3, v30
  0672 invoke-virtual v0, v1, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0678 move-object/from16 v2, v26
  067c move-object/from16 v1, v27
  0680 invoke-virtual v0, v2, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0686 invoke-virtual/range v25, Lorg/json/JSONArray;->length()I
  068c move-result v1
  068e if-lez v1, +009h
  0692 move-object/from16 v2, v24
  0696 move-object/from16 v1, v25
  069a invoke-virtual v0, v2, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  06a0 const-wide/16 v1, 0
  06a4 cmp-long v1, v10, v1
  06a8 if-lez v1, +007h
  06ac move-object/from16 v1, v23
  06b0 invoke-virtual v0, v1, v10, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  06b6 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  06bc move-result-object v1
  06be invoke-virtual v1, Ljava/util/UUID;->toString()Ljava/lang/String;
  06c4 move-result-object v1
  06c6 new-instance v2, Ljava/io/File;
  06ca new-instance v3, Ljava/io/File;
  06ce invoke-virtual/range v37, Lcom/personal/aihub/CreatorActivity;->getCacheDir()Ljava/io/File;
  06d4 move-result-object v4
  06d6 const-string v5, "animation-preview"
  06da invoke-direct v3, v4, v5, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  06e0 invoke-direct v2, v3, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  06e6 invoke-virtual v2, Ljava/io/File;->mkdirs()Z
  06ec new-instance v3, Ljava/io/File;
  06f0 const-string v4, "request.json"
  06f4 invoke-direct v3, v2, v4, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  06fa invoke-virtual v0, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0700 move-result-object v0
  0702 invoke-static v3, v0, Lcom/personal/aihub/CreatorActivity;->writeText(Ljava/io/File; Ljava/lang/String;)V
  0708 new-instance v0, Lcom/personal/aihub/CreatorActivity$8;
  070c move-object/from16 v2, v37
  0710 invoke-direct v0, v2, v1, Lcom/personal/aihub/CreatorActivity$8;-><init>(Lcom/personal/aihub/CreatorActivity; Ljava/lang/String;)V
  0716 invoke-virtual v2, v0, Lcom/personal/aihub/CreatorActivity;->runOnUiThread(Ljava/lang/Runnable;)V
  071c new-instance v0, Lorg/json/JSONObject;
  0720 invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  0726 const-string v1, "opened"
  072a const/4 v3, 1
  072c invoke-virtual v0, v1, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0732 move-result-object v0
  0734 const-string v1, "online"
  0738 invoke-virtual v0, v1, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  073e move-result-object v0
  0740 return-object v0
  0742 move-object/from16 v2, v37
  0746 new-instance v0, Ljava/io/IOException;
  074a const-string v1, "Choose up to five items for this scene"
  074e invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0754 throw v0
  0756 move-object/from16 v2, v37
  075a new-instance v0, Ljava/io/IOException;
  075e const-string v1, "Choose the matching item animation"
  0762 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0768 throw v0
  076a move-object/from16 v2, v37
  076e new-instance v0, Ljava/io/IOException;
  0772 const-string v1, "Choose a valid animation or a shorter composition"
  0776 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  077c throw v0
  077e move-object/from16 v2, v37
  0782 new-instance v0, Ljava/io/IOException;
  0786 const-string v1, "Choose a supported preview type"
  078a invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0790 throw v0
.end method

.method progress(Ljava/lang/String; Ljava/lang/String; J J)V
  0000 new-instance v0, Lorg/json/JSONObject;
  0004 invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  000a const-string v1, "phase"
  000e invoke-virtual v0, v1, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0014 move-result-object v3
  0016 const-string v0, "label"
  001a invoke-virtual v3, v0, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0020 move-result-object v3
  0022 const-string v4, "bytes"
  0026 invoke-virtual v3, v4, v5, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  002c move-result-object v3
  002e const-string v4, "total"
  0032 invoke-virtual v3, v4, v7, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0038 move-result-object v3
  003a iput-object v3, v2, Lcom/personal/aihub/CreatorActivity;->importProgress Lorg/json/JSONObject;
  003e return-void 
.end method

.method projectFile(Ljava/lang/String;)Ljava/io/File;
  0000 if-eqz v4, +027h
  0004 const-string v0, "[a-zA-Z0-9_-]{1,100}"
  0008 invoke-virtual v4, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  000e move-result v0
  0010 if-eqz v0, +01fh
  0014 new-instance v0, Ljava/io/File;
  0018 iget-object v1, v3, Lcom/personal/aihub/CreatorActivity;->projects Ljava/io/File;
  001c new-instance v2, Ljava/lang/StringBuilder;
  0020 invoke-direct v2, Ljava/lang/StringBuilder;-><init>()V
  0026 invoke-static v4, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  002c move-result-object v4
  002e invoke-virtual v2, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0034 const-string v4, ".json"
  0038 invoke-virtual v2, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  003e invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0044 move-result-object v4
  0046 invoke-direct v0, v1, v4, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  004c return-object v0
  004e new-instance v4, Ljava/io/IOException;
  0052 const-string v0, "Invalid project key"
  0056 invoke-direct v4, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  005c throw v4
.end method

.method query(Lorg/json/JSONObject;)Lorg/json/JSONArray;
  0000 invoke-direct v2, Lcom/personal/aihub/CreatorActivity;->ensureDb()V
  0006 iget-object v0, v2, Lcom/personal/aihub/CreatorActivity;->db Landroid/database/sqlite/SQLiteDatabase;
  000a iget-object v1, v2, Lcom/personal/aihub/CreatorActivity;->schema Lorg/json/JSONObject;
  000e invoke-direct v2, v0, v1, v3, Lcom/personal/aihub/CreatorActivity;->queryDatabase(Landroid/database/sqlite/SQLiteDatabase; Lorg/json/JSONObject; Lorg/json/JSONObject;)Lorg/json/JSONArray;
  0014 move-result-object v3
  0016 return-object v3
.end method

.method queryDatabase(Landroid/database/sqlite/SQLiteDatabase; Lorg/json/JSONObject; Lorg/json/JSONObject;)Lorg/json/JSONArray;
  0000 const-string v0, "table"
  0004 invoke-virtual v12, v0, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  000a move-result-object v0
  000c invoke-virtual v11, v0, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0012 move-result-object v11
  0014 if-eqz v11, +203h
  0018 new-instance v1, Ljava/util/HashSet;
  001c invoke-direct v1, Ljava/util/HashSet;-><init>()V
  0022 const/4 v2, 0
  0024 move v3, v2
  0026 invoke-virtual v11, Lorg/json/JSONArray;->length()I
  002c move-result v4
  002e if-ge v3, v4, +012h
  0032 invoke-virtual v11, v3, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  0038 move-result-object v4
  003a const-string v5, "name"
  003e invoke-virtual v4, v5, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0044 move-result-object v4
  0046 invoke-virtual v1, v4, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  004c add-int/lit8 v3, v3, 1
  0050 goto -15h
  0052 new-instance v11, Ljava/util/ArrayList;
  0056 invoke-direct v11, Ljava/util/ArrayList;-><init>()V
  005c new-instance v3, Ljava/util/ArrayList;
  0060 invoke-direct v3, Ljava/util/ArrayList;-><init>()V
  0066 const-string v4, "filters"
  006a invoke-virtual v12, v4, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0070 move-result-object v4
  0072 if-eqz v4, +06bh
  0076 invoke-virtual v4, Lorg/json/JSONObject;->keys()Ljava/util/Iterator;
  007c move-result-object v5
  007e invoke-interface v5, Ljava/util/Iterator;->hasNext()Z
  0084 move-result v6
  0086 if-eqz v6, +061h
  008a invoke-interface v5, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0090 move-result-object v6
  0092 check-cast v6, Ljava/lang/String;
  0096 invoke-virtual v1, v6, Ljava/util/HashSet;->contains(Ljava/lang/Object;)Z
  009c move-result v7
  009e if-eqz v7, +04dh
  00a2 invoke-virtual v4, v6, Lorg/json/JSONObject;->isNull(Ljava/lang/String;)Z
  00a8 move-result v7
  00aa if-eqz v7, +01fh
  00ae new-instance v7, Ljava/lang/StringBuilder;
  00b2 invoke-direct v7, Ljava/lang/StringBuilder;-><init>()V
  00b8 invoke-static v6, Lcom/personal/aihub/CreatorActivity;->identifier(Ljava/lang/String;)Ljava/lang/String;
  00be move-result-object v6
  00c0 invoke-static v6, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  00c6 move-result-object v6
  00c8 invoke-virtual v7, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00ce const-string v6, " IS NULL"
  00d2 invoke-virtual v7, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00d8 invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00de move-result-object v6
  00e0 invoke-virtual v3, v6, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  00e6 goto -34h
  00e8 new-instance v7, Ljava/lang/StringBuilder;
  00ec invoke-direct v7, Ljava/lang/StringBuilder;-><init>()V
  00f2 invoke-static v6, Lcom/personal/aihub/CreatorActivity;->identifier(Ljava/lang/String;)Ljava/lang/String;
  00f8 move-result-object v8
  00fa invoke-static v8, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0100 move-result-object v8
  0102 invoke-virtual v7, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0108 const-string v8, " = ?"
  010c invoke-virtual v7, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0112 invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0118 move-result-object v7
  011a invoke-virtual v3, v7, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0120 invoke-virtual v4, v6, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  0126 move-result-object v6
  0128 invoke-static v6, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  012e move-result-object v6
  0130 invoke-virtual v11, v6, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0136 goto -5ch
  0138 new-instance v10, Ljava/io/IOException;
  013c const-string v11, "Unknown column"
  0140 invoke-direct v10, v11, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0146 throw v10
  0148 const-string v4, "ids"
  014c invoke-virtual v12, v4, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0152 move-result-object v4
  0154 if-eqz v4, +05ah
  0158 invoke-virtual v4, Lorg/json/JSONArray;->length()I
  015e move-result v5
  0160 if-nez v5, +008h
  0164 new-instance v10, Lorg/json/JSONArray;
  0168 invoke-direct v10, Lorg/json/JSONArray;-><init>()V
  016e return-object v10
  0170 invoke-virtual v4, Lorg/json/JSONArray;->length()I
  0176 move-result v5
  0178 const/16 v6, 1000
  017c if-gt v5, v6, +03eh
  0180 new-instance v5, Ljava/util/ArrayList;
  0184 invoke-direct v5, Ljava/util/ArrayList;-><init>()V
  018a move v6, v2
  018c invoke-virtual v4, Lorg/json/JSONArray;->length()I
  0192 move-result v7
  0194 if-ge v6, v7, +015h
  0198 const-string v7, "?"
  019c invoke-virtual v5, v7, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  01a2 invoke-virtual v4, v6, Lorg/json/JSONArray;->getLong(I)J
  01a8 move-result-wide v7
  01aa invoke-static v7, v8, Ljava/lang/String;->valueOf(J)Ljava/lang/String;
  01b0 move-result-object v7
  01b2 invoke-virtual v11, v7, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  01b8 add-int/lit8 v6, v6, 1
  01bc goto -18h
  01be new-instance v4, Ljava/lang/StringBuilder;
  01c2 const-string v6, ""id" IN ("
  01c6 invoke-direct v4, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  01cc const-string v6, ","
  01d0 invoke-static v6, v5, Ljava/lang/String;->join(Ljava/lang/CharSequence; Ljava/lang/Iterable;)Ljava/lang/String;
  01d6 move-result-object v5
  01d8 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01de const-string v5, ")"
  01e2 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01e8 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01ee move-result-object v4
  01f0 invoke-virtual v3, v4, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  01f6 goto +9h
  01f8 new-instance v10, Ljava/io/IOException;
  01fc const-string v11, "Too many row IDs"
  0200 invoke-direct v10, v11, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0206 throw v10
  0208 const-string v4, "search"
  020c invoke-virtual v12, v4, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0212 move-result-object v4
  0214 if-eqz v4, +065h
  0218 const-string v5, "text"
  021c invoke-virtual v4, v5, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0222 move-result-object v6
  0224 invoke-virtual v6, Ljava/lang/String;->isEmpty()Z
  022a move-result v6
  022c if-nez v6, +059h
  0230 const-string v6, "column"
  0234 invoke-virtual v4, v6, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  023a move-result-object v6
  023c invoke-virtual v1, v6, Ljava/util/HashSet;->contains(Ljava/lang/Object;)Z
  0242 move-result v7
  0244 if-eqz v7, +045h
  0248 new-instance v7, Ljava/lang/StringBuilder;
  024c invoke-direct v7, Ljava/lang/StringBuilder;-><init>()V
  0252 invoke-static v6, Lcom/personal/aihub/CreatorActivity;->identifier(Ljava/lang/String;)Ljava/lang/String;
  0258 move-result-object v6
  025a invoke-static v6, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0260 move-result-object v6
  0262 invoke-virtual v7, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0268 const-string v6, " LIKE ?"
  026c invoke-virtual v7, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0272 invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0278 move-result-object v6
  027a invoke-virtual v3, v6, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0280 invoke-virtual v4, v5, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0286 move-result-object v4
  0288 new-instance v5, Ljava/lang/StringBuilder;
  028c const-string v6, "%"
  0290 invoke-direct v5, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0296 invoke-virtual v4, Ljava/lang/String;->length()I
  029c move-result v7
  029e const/16 v8, 200
  02a2 invoke-static v7, v8, Ljava/lang/Math;->min(I I)I
  02a8 move-result v7
  02aa invoke-virtual v4, v2, v7, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  02b0 move-result-object v4
  02b2 invoke-virtual v5, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02b8 invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02be invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  02c4 move-result-object v4
  02c6 invoke-virtual v11, v4, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  02cc goto +9h
  02ce new-instance v10, Ljava/io/IOException;
  02d2 const-string v11, "Unknown search column"
  02d6 invoke-direct v10, v11, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02dc throw v10
  02de const-string v4, "order"
  02e2 const-string v5, "id"
  02e6 invoke-virtual v12, v4, v5, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  02ec move-result-object v4
  02ee invoke-virtual v1, v4, Ljava/util/HashSet;->contains(Ljava/lang/Object;)Z
  02f4 move-result v1
  02f6 if-eqz v1, +08ah
  02fa new-instance v1, Ljava/lang/StringBuilder;
  02fe const-string v5, "SELECT * FROM "
  0302 invoke-direct v1, v5, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0308 invoke-static v0, Lcom/personal/aihub/CreatorActivity;->identifier(Ljava/lang/String;)Ljava/lang/String;
  030e move-result-object v0
  0310 invoke-virtual v1, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0316 invoke-virtual v3, Ljava/util/ArrayList;->isEmpty()Z
  031c move-result v0
  031e if-eqz v0, +005h
  0322 const-string v0, ""
  0326 goto +15h
  0328 new-instance v0, Ljava/lang/StringBuilder;
  032c const-string v5, " WHERE "
  0330 invoke-direct v0, v5, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0336 const-string v5, " AND "
  033a invoke-static v5, v3, Ljava/lang/String;->join(Ljava/lang/CharSequence; Ljava/lang/Iterable;)Ljava/lang/String;
  0340 move-result-object v3
  0342 invoke-virtual v0, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0348 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  034e move-result-object v0
  0350 invoke-virtual v1, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0356 const-string v0, " ORDER BY "
  035a invoke-virtual v1, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0360 invoke-static v4, Lcom/personal/aihub/CreatorActivity;->identifier(Ljava/lang/String;)Ljava/lang/String;
  0366 move-result-object v0
  0368 invoke-virtual v1, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  036e const-string v0, " LIMIT "
  0372 invoke-virtual v1, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0378 const-string v0, "limit"
  037c const/16 v3, 100
  0380 invoke-virtual v12, v0, v3, Lorg/json/JSONObject;->optInt(Ljava/lang/String; I)I
  0386 move-result v0
  0388 const/16 v3, 5000
  038c invoke-static v3, v0, Ljava/lang/Math;->min(I I)I
  0392 move-result v0
  0394 const/4 v3, 1
  0396 invoke-static v3, v0, Ljava/lang/Math;->max(I I)I
  039c move-result v0
  039e invoke-virtual v1, v0, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  03a4 const-string v0, " OFFSET "
  03a8 invoke-virtual v1, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  03ae const-string v0, "offset"
  03b2 invoke-virtual v12, v0, v2, Lorg/json/JSONObject;->optInt(Ljava/lang/String; I)I
  03b8 move-result v12
  03ba invoke-static v2, v12, Ljava/lang/Math;->max(I I)I
  03c0 move-result v12
  03c2 invoke-virtual v1, v12, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  03c8 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  03ce move-result-object v12
  03d0 new-array v0, v2, [Ljava/lang/String;
  03d4 invoke-virtual v11, v0, Ljava/util/ArrayList;->toArray([Ljava/lang/Object;)[Ljava/lang/Object;
  03da move-result-object v11
  03dc check-cast v11, [Ljava/lang/String;
  03e0 invoke-virtual v10, v12, v11, Landroid/database/sqlite/SQLiteDatabase;->rawQuery(Ljava/lang/String; [Ljava/lang/String;)Landroid/database/Cursor;
  03e6 move-result-object v10
  03e8 invoke-static v10, Lcom/personal/aihub/CreatorActivity;->rows(Landroid/database/Cursor;)Lorg/json/JSONArray;
  03ee move-result-object v11
  03f0 if-eqz v10, +005h
  03f4 invoke-interface v10, Landroid/database/Cursor;->close()V
  03fa return-object v11
  03fc move-exception v11
  03fe if-eqz v10, +005h
  0402 invoke-interface v10, Landroid/database/Cursor;->close()V
  0408 throw v11
  040a new-instance v10, Ljava/io/IOException;
  040e const-string v11, "Unknown sort column"
  0412 invoke-direct v10, v11, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0418 throw v10
  041a new-instance v10, Ljava/io/IOException;
  041e const-string v11, "Table is not in this database."
  0422 invoke-direct v10, v11, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0428 throw v10
.end method

.method readText(Ljava/io/File; I)Ljava/lang/String;
  0000 new-instance v0, Ljava/io/FileInputStream;
  0004 invoke-direct v0, v3, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  000a new-instance v3, Ljava/io/ByteArrayOutputStream;
  000e invoke-direct v3, Ljava/io/ByteArrayOutputStream;-><init>()V
  0014 int-to-long v1, v4
  0016 invoke-static v0, v3, v1, v2, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  001c const-string v4, "UTF-8"
  0020 invoke-virtual v3, v4, Ljava/io/ByteArrayOutputStream;->toString(Ljava/lang/String;)Ljava/lang/String;
  0026 move-result-object v4
  0028 invoke-virtual v3, Ljava/io/ByteArrayOutputStream;->close()V
  002e invoke-virtual v0, Ljava/io/FileInputStream;->close()V
  0034 return-object v4
  0036 move-exception v4
  0038 invoke-virtual v3, Ljava/io/ByteArrayOutputStream;->close()V
  003e goto +5h
  0040 move-exception v3
  0042 invoke-virtual v4, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0048 throw v4
  004a move-exception v3
  004c invoke-virtual v0, Ljava/io/FileInputStream;->close()V
  0052 goto +5h
  0054 move-exception v4
  0056 invoke-virtual v3, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  005c throw v3
.end method

.method readTextAsset(Ljava/lang/String; I)Ljava/lang/String;
  0000 invoke-virtual v3, Lcom/personal/aihub/CreatorActivity;->getAssets()Landroid/content/res/AssetManager;
  0006 move-result-object v0
  0008 invoke-virtual v0, v4, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;
  000e move-result-object v4
  0010 new-instance v0, Ljava/io/ByteArrayOutputStream;
  0014 invoke-direct v0, Ljava/io/ByteArrayOutputStream;-><init>()V
  001a int-to-long v1, v5
  001c invoke-static v4, v0, v1, v2, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  0022 const-string v5, "UTF-8"
  0026 invoke-virtual v0, v5, Ljava/io/ByteArrayOutputStream;->toString(Ljava/lang/String;)Ljava/lang/String;
  002c move-result-object v5
  002e invoke-virtual v0, Ljava/io/ByteArrayOutputStream;->close()V
  0034 if-eqz v4, +005h
  0038 invoke-virtual v4, Ljava/io/InputStream;->close()V
  003e return-object v5
  0040 move-exception v5
  0042 invoke-virtual v0, Ljava/io/ByteArrayOutputStream;->close()V
  0048 goto +5h
  004a move-exception v0
  004c invoke-virtual v5, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0052 throw v5
  0054 move-exception v5
  0056 if-eqz v4, +00ah
  005a invoke-virtual v4, Ljava/io/InputStream;->close()V
  0060 goto +5h
  0062 move-exception v4
  0064 invoke-virtual v5, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  006a throw v5
.end method

.method restoreDatabase()Lorg/json/JSONObject;
  0000 sget-object v0, Lcom/personal/aihub/CreatorActivity;->DATABASE_WRITES Ljava/lang/Object;
  0004 monitor-enter v0
  0006 const-string v2, "restore"
  000a const-string v3, "Checking the previous database"
  000e const-wide/16 v4, 0
  0012 const-wide/16 v6, 0
  0016 move-object v1, v9
  0018 invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  001e invoke-direct v9, Lcom/personal/aihub/CreatorActivity;->dataStore()Lcom/personal/aihub/GameDataStore;
  0024 move-result-object v1
  0026 invoke-virtual v1, Lcom/personal/aihub/GameDataStore;->state()Lorg/json/JSONObject;
  002c move-result-object v2
  002e if-eqz v2, +036h
  0032 const-string v3, "previous"
  0036 invoke-virtual v2, v3, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  003c move-result-object v3
  003e if-eqz v3, +02eh
  0042 const-string v3, "previous"
  0046 invoke-virtual v2, v3, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  004c move-result-object v2
  004e invoke-virtual v1, v2, Lcom/personal/aihub/GameDataStore;->file(Lorg/json/JSONObject;)Ljava/io/File;
  0054 move-result-object v2
  0056 invoke-direct v9, v2, Lcom/personal/aihub/CreatorActivity;->verifyDb(Ljava/io/File;)V
  005c invoke-virtual v1, Lcom/personal/aihub/GameDataStore;->restore()V
  0062 iget-object v1, v9, Lcom/personal/aihub/CreatorActivity;->db Landroid/database/sqlite/SQLiteDatabase;
  0066 if-eqz v1, +005h
  006a invoke-virtual v1, Landroid/database/sqlite/SQLiteDatabase;->close()V
  0070 const/4 v1, 0
  0072 iput-object v1, v9, Lcom/personal/aihub/CreatorActivity;->db Landroid/database/sqlite/SQLiteDatabase;
  0076 invoke-direct v9, Lcom/personal/aihub/CreatorActivity;->info()Lorg/json/JSONObject;
  007c move-result-object v1
  007e const-string v3, "done"
  0082 const-string v4, "Previous database restored; saved units kept"
  0086 const-wide/16 v5, 0
  008a const-wide/16 v7, 0
  008e move-object v2, v9
  0090 invoke-direct/range v2 ... v8, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  0096 monitor-exit v0
  0098 return-object v1
  009a new-instance v1, Ljava/io/IOException;
  009e const-string v2, "No previous database is available"
  00a2 invoke-direct v1, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00a8 throw v1
  00aa move-exception v1
  00ac const-string v3, "error"
  00b0 const-string v4, "Restore failed; the active database was kept"
  00b4 const-wide/16 v5, 0
  00b8 const-wide/16 v7, 0
  00bc move-object v2, v9
  00be invoke-direct/range v2 ... v8, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  00c4 throw v1
  00c6 move-exception v1
  00c8 monitor-exit v0
  00ca throw v1
.end method

.method rows(Landroid/database/Cursor;)Lorg/json/JSONArray;
  0000 new-instance v0, Lorg/json/JSONArray;
  0004 invoke-direct v0, Lorg/json/JSONArray;-><init>()V
  000a invoke-interface v6, Landroid/database/Cursor;->getColumnNames()[Ljava/lang/String;
  0010 move-result-object v1
  0012 invoke-interface v6, Landroid/database/Cursor;->moveToNext()Z
  0018 move-result v2
  001a if-eqz v2, +03ch
  001e new-instance v2, Lorg/json/JSONObject;
  0022 invoke-direct v2, Lorg/json/JSONObject;-><init>()V
  0028 const/4 v3, 0
  002a array-length v4, v1
  002c if-ge v3, v4, +02fh
  0030 invoke-interface v6, v3, Landroid/database/Cursor;->getType(I)I
  0036 move-result v4
  0038 if-eqz v4, +01fh
  003c const/4 v5, 1
  003e if-eq v4, v5, +013h
  0042 const/4 v5, 2
  0044 if-eq v4, v5, +007h
  0048 invoke-interface v6, v3, Landroid/database/Cursor;->getString(I)Ljava/lang/String;
  004e move-result-object v4
  0050 goto +15h
  0052 invoke-interface v6, v3, Landroid/database/Cursor;->getDouble(I)D
  0058 move-result-wide v4
  005a invoke-static v4, v5, Ljava/lang/Double;->valueOf(D)Ljava/lang/Double;
  0060 move-result-object v4
  0062 goto +ch
  0064 invoke-interface v6, v3, Landroid/database/Cursor;->getLong(I)J
  006a move-result-wide v4
  006c invoke-static v4, v5, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  0072 move-result-object v4
  0074 goto +3h
  0076 sget-object v4, Lorg/json/JSONObject;->NULL Ljava/lang/Object;
  007a aget-object v5, v1, v3
  007e invoke-virtual v2, v5, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0084 add-int/lit8 v3, v3, 1
  0088 goto -2fh
  008a invoke-virtual v0, v2, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0090 goto -3fh
  0092 return-object v0
.end method

.method safePath(Ljava/lang/String;)Z
  0000 const/4 v0, 0
  0002 if-eqz v5, +050h
  0006 invoke-virtual v5, Ljava/lang/String;->isEmpty()Z
  000c move-result v1
  000e if-nez v1, +04ah
  0012 invoke-virtual v5, Ljava/lang/String;->length()I
  0018 move-result v1
  001a const/16 v2, 500
  001e if-gt v1, v2, +042h
  0022 const-string v1, "/"
  0026 invoke-virtual v5, v1, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  002c move-result v2
  002e if-nez v2, +03ah
  0032 const-string v2, "\"
  0036 invoke-virtual v5, v2, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  003c move-result v2
  003e if-nez v2, +032h
  0042 const-string v2, ".*[:\x00-\x1f].*"
  0046 invoke-virtual v5, v2, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  004c move-result v2
  004e if-nez v2, +02ah
  0052 const/4 v2, -1
  0054 invoke-virtual v5, v1, v2, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  005a move-result-object v5
  005c array-length v1, v5
  005e move v2, v0
  0060 if-ge v2, v1, +01fh
  0064 aget-object v3, v5, v2
  0068 invoke-virtual v3, Ljava/lang/String;->isEmpty()Z
  006e move-result v4
  0070 if-nez v4, +016h
  0074 const-string v4, "."
  0078 invoke-virtual v3, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  007e move-result v4
  0080 if-nez v4, +00eh
  0084 const-string v4, ".."
  0088 invoke-virtual v3, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  008e move-result v3
  0090 if-eqz v3, +003h
  0094 goto +4h
  0096 add-int/lit8 v2, v2, 1
  009a goto -1dh
  009c return v0
  009e const/4 v5, 1
  00a0 return v5
  00a2 return v0
.end method

.method saveFormatKey(Ljava/io/File; [B)V
  0000 new-instance v0, Ljava/io/File;
  0004 iget-object v1, v4, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0008 new-instance v2, Ljava/lang/StringBuilder;
  000c const-string v3, "format-"
  0010 invoke-direct v2, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0016 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  001c move-result-object v3
  001e invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0024 const-string v3, ".tmp"
  0028 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  002e invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0034 move-result-object v2
  0036 invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  003c const/4 v1, 0
  003e new-instance v2, Ljava/io/FileOutputStream;
  0042 invoke-direct v2, v0, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0048 invoke-virtual v2, v6, Ljava/io/FileOutputStream;->write([B)V
  004e invoke-virtual v2, Ljava/io/FileOutputStream;->getFD()Ljava/io/FileDescriptor;
  0054 move-result-object v3
  0056 invoke-virtual v3, Ljava/io/FileDescriptor;->sync()V
  005c invoke-virtual v2, Ljava/io/FileOutputStream;->close()V
  0062 invoke-virtual v0, v5, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  0068 move-result v5
  006a if-eqz v5, +009h
  006e invoke-virtual v0, Ljava/io/File;->delete()Z
  0074 invoke-static v6, v1, Ljava/util/Arrays;->fill([B B)V
  007a return-void 
  007c new-instance v5, Ljava/io/IOException;
  0080 const-string v2, "Could not save this game's import format."
  0084 invoke-direct v5, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  008a throw v5
  008c move-exception v5
  008e invoke-virtual v2, Ljava/io/FileOutputStream;->close()V
  0094 goto +5h
  0096 move-exception v2
  0098 invoke-virtual v5, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  009e throw v5
  00a0 move-exception v5
  00a2 invoke-virtual v0, Ljava/io/File;->delete()Z
  00a8 invoke-static v6, v1, Ljava/util/Arrays;->fill([B B)V
  00ae throw v5
.end method

.method saveProject(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 const-string v0, "format"
  0004 invoke-virtual v13, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  000a move-result-object v0
  000c const-string v1, "dokkan-unit-forge"
  0010 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0016 move-result v0
  0018 if-eqz v0, +1bbh
  001c const-string v0, "version"
  0020 invoke-virtual v13, v0, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  0026 move-result-object v1
  0028 instance-of v1, v1, Ljava/lang/Number;
  002c if-eqz v1, +1b1h
  0030 invoke-virtual v13, v0, Lorg/json/JSONObject;->optDouble(Ljava/lang/String;)D
  0036 move-result-wide v0
  0038 const-wide/high16 v2, 4607182418800017408
  003c cmpl-double v4, v0, v2
  0040 if-nez v4, +1a7h
  0044 const-string v0, "targetId"
  0048 invoke-virtual v13, v0, Lorg/json/JSONObject;->optDouble(Ljava/lang/String;)D
  004e move-result-wide v0
  0050 const-wide/16 v2, 0
  0054 cmpl-double v4, v0, v2
  0058 if-lez v4, +19bh
  005c const-wide v2, 4746794007244308480
  0066 cmpg-double v4, v0, v2
  006a if-gtz v4, +192h
  006e double-to-long v2, v0
  0070 long-to-double v2, v2
  0072 cmpl-double v4, v0, v2
  0076 if-nez v4, +18ch
  007a const-string v0, "tables"
  007e invoke-virtual v13, v0, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0084 move-result-object v0
  0086 if-eqz v0, +184h
  008a const-string v1, "cards"
  008e invoke-virtual v0, v1, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0094 move-result-object v0
  0096 if-eqz v0, +17ch
  009a invoke-virtual v0, Lorg/json/JSONArray;->length()I
  00a0 move-result v1
  00a2 const/4 v2, 1
  00a4 if-ne v1, v2, +175h
  00a8 const/4 v1, 0
  00aa invoke-virtual v0, v1, Lorg/json/JSONArray;->optJSONObject(I)Lorg/json/JSONObject;
  00b0 move-result-object v0
  00b2 if-eqz v0, +16eh
  00b6 const-string v0, "targetId"
  00ba invoke-virtual v13, v0, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  00c0 move-result-wide v2
  00c2 invoke-virtual v13, v0, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  00c8 const-string v0, "formProjects"
  00cc invoke-virtual v13, v0, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  00d2 move-result v1
  00d4 if-eqz v1, +0d5h
  00d8 invoke-virtual v13, v0, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  00de move-result-object v5
  00e0 if-eqz v5, +157h
  00e4 invoke-virtual v5, Lorg/json/JSONArray;->length()I
  00ea move-result v7
  00ec const/4 v0, 4
  00ee if-gt v7, v0, +150h
  00f2 new-instance v6, Ljava/util/ArrayList;
  00f6 invoke-direct v6, Ljava/util/ArrayList;-><init>()V
  00fc const-string v0, "targetId"
  0100 invoke-virtual v13, v0, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  0106 move-result-wide v0
  0108 invoke-static v0, v1, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  010e move-result-object v0
  0110 invoke-virtual v6, v0, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0116 const/4 v8, 0
  0118 if-ge v8, v7, +0b3h
  011c invoke-virtual v5, v8, Lorg/json/JSONArray;->optJSONObject(I)Lorg/json/JSONObject;
  0122 move-result-object v9
  0124 if-eqz v9, +135h
  0128 const-string v0, "format"
  012c invoke-virtual v9, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0132 move-result-object v0
  0134 const-string v1, "dokkan-unit-forge"
  0138 invoke-virtual v1, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  013e move-result v0
  0140 if-eqz v0, +127h
  0144 const-string v0, "formProjects"
  0148 invoke-virtual v9, v0, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  014e move-result v0
  0150 if-nez v0, +11fh
  0154 const-string v0, "transformLinks"
  0158 invoke-virtual v9, v0, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  015e move-result v0
  0160 if-nez v0, +117h
  0164 const-string v0, "version"
  0168 invoke-virtual v9, v0, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  016e move-result-object v1
  0170 instance-of v1, v1, Ljava/lang/Number;
  0174 if-eqz v1, +10dh
  0178 invoke-virtual v9, v0, Lorg/json/JSONObject;->optDouble(Ljava/lang/String;)D
  017e move-result-wide v0
  0180 const-wide/high16 v2, 4607182418800017408
  0184 cmpl-double v4, v0, v2
  0188 if-nez v4, +103h
  018c const-string v0, "targetId"
  0190 invoke-virtual v9, v0, Lorg/json/JSONObject;->optDouble(Ljava/lang/String;)D
  0196 move-result-wide v0
  0198 const-wide/16 v2, 0
  019c cmpl-double v4, v0, v2
  01a0 if-lez v4, +0f7h
  01a4 const-wide v2, 4746794007244308480
  01ae cmpg-double v4, v0, v2
  01b2 if-gtz v4, +0eeh
  01b6 double-to-long v2, v0
  01b8 long-to-double v2, v2
  01ba cmpl-double v4, v0, v2
  01be if-nez v4, +0e8h
  01c2 const-string v0, "tables"
  01c6 invoke-virtual v9, v0, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  01cc move-result-object v0
  01ce if-eqz v0, +0e0h
  01d2 const-string v1, "cards"
  01d6 invoke-virtual v0, v1, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  01dc move-result-object v0
  01de if-eqz v0, +0d8h
  01e2 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  01e8 move-result v1
  01ea const/4 v2, 1
  01ec if-ne v1, v2, +0d1h
  01f0 const/4 v1, 0
  01f2 invoke-virtual v0, v1, Lorg/json/JSONArray;->optJSONObject(I)Lorg/json/JSONObject;
  01f8 move-result-object v0
  01fa if-eqz v0, +0cah
  01fe const-string v0, "targetId"
  0202 invoke-virtual v9, v0, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  0208 move-result-wide v2
  020a invoke-virtual v9, v0, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0210 const/4 v10, 0
  0212 invoke-virtual v6, Ljava/util/ArrayList;->size()I
  0218 move-result v11
  021a if-ge v10, v11, +021h
  021e invoke-virtual v6, v10, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;
  0224 move-result-object v0
  0226 check-cast v0, Ljava/lang/Number;
  022a invoke-virtual v0, Ljava/lang/Number;->longValue()J
  0230 move-result-wide v0
  0232 const-string v2, "targetId"
  0236 invoke-virtual v9, v2, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  023c move-result-wide v2
  023e sub-long v0, v2, v0
  0242 invoke-static v0, v1, Ljava/lang/Math;->abs(J)J
  0248 move-result-wide v0
  024a const-wide/16 v2, 1000
  024e cmp-long v4, v0, v2
  0252 if-ltz v4, +09eh
  0256 add-int/lit8 v10, v10, 1
  025a goto -20h
  025c const-string v0, "targetId"
  0260 invoke-virtual v9, v0, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  0266 move-result-wide v0
  0268 invoke-static v0, v1, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  026e move-result-object v0
  0270 invoke-virtual v6, v0, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0276 add-int/lit8 v8, v8, 1
  027a goto/16 -0b1h
  027e sget-object v0, Lcom/personal/aihub/CreatorActivity;->PROJECT_WRITES Ljava/lang/Object;
  0282 monitor-enter v0
  0284 const-string v1, "key"
  0288 invoke-virtual v13, v1, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  028e move-result-object v1
  0290 invoke-direct v12, v1, Lcom/personal/aihub/CreatorActivity;->projectFile(Ljava/lang/String;)Ljava/io/File;
  0296 move-result-object v1
  0298 const-string v2, "updatedAt"
  029c invoke-virtual v13, v2, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  02a2 move-result-object v2
  02a4 invoke-virtual v1, Ljava/io/File;->isFile()Z
  02aa move-result v3
  02ac const/high16 v4, 20971520
  02b0 const/4 v5, 1
  02b2 if-eqz v3, +03ch
  02b6 new-instance v3, Lorg/json/JSONObject;
  02ba invoke-static v1, v4, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  02c0 move-result-object v6
  02c2 invoke-direct v3, v6, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  02c8 const-string v6, "updatedAt"
  02cc invoke-virtual v3, v6, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  02d2 move-result-object v3
  02d4 const-string v6, "\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z"
  02d8 invoke-virtual v3, v6, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  02de move-result v6
  02e0 if-eqz v6, +025h
  02e4 const-string v6, "\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z"
  02e8 invoke-virtual v2, v6, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  02ee move-result v6
  02f0 if-eqz v6, +01dh
  02f4 invoke-virtual v3, v2, Ljava/lang/String;->compareTo(Ljava/lang/String;)I
  02fa move-result v2
  02fc if-lez v2, +017h
  0300 new-instance v2, Lorg/json/JSONObject;
  0304 invoke-direct v2, Lorg/json/JSONObject;-><init>()V
  030a const-string v3, "saved"
  030e invoke-virtual v2, v3, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0314 move-result-object v2
  0316 const-string v3, "superseded"
  031a invoke-virtual v2, v3, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0320 move-result-object v13
  0322 monitor-exit v0
  0324 return-object v13
  0326 move-exception v13
  0328 throw v13
  032a invoke-virtual v13, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0330 move-result-object v13
  0332 sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0336 invoke-virtual v13, v2, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  033c move-result-object v13
  033e array-length v2, v13
  0340 if-gt v2, v4, +01ch
  0344 invoke-static v1, v13, Lcom/personal/aihub/ProjectVersions;->atomic(Ljava/io/File; [B)V
  034a new-instance v1, Lorg/json/JSONObject;
  034e invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  0354 const-string v2, "saved"
  0358 invoke-virtual v1, v2, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  035e move-result-object v1
  0360 const-string v2, "revision"
  0364 invoke-static v13, Lcom/personal/aihub/ProjectVersions;->revision([B)Ljava/lang/String;
  036a move-result-object v13
  036c invoke-virtual v1, v2, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0372 move-result-object v13
  0374 monitor-exit v0
  0376 return-object v13
  0378 new-instance v13, Ljava/io/IOException;
  037c const-string v1, "Project exceeds 20 MiB."
  0380 invoke-direct v13, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0386 throw v13
  0388 move-exception v13
  038a monitor-exit v0
  038c throw v13
  038e new-instance v13, Ljava/io/IOException;
  0392 const-string v0, "Unsupported project"
  0396 invoke-direct v13, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  039c throw v13
.end method

.method sparkingAnimationFiles()Lorg/json/JSONArray;
  0000 invoke-direct v8, Lcom/personal/aihub/CreatorActivity;->prepareSparkingSnapshot()V
  0006 invoke-direct v8, Lcom/personal/aihub/CreatorActivity;->sparkingStore()Lcom/personal/aihub/GameDataStore;
  000c move-result-object v0
  000e invoke-virtual v0, Lcom/personal/aihub/GameDataStore;->meta()Lorg/json/JSONObject;
  0014 move-result-object v0
  0016 new-instance v1, Ljava/util/TreeSet;
  001a invoke-direct v1, Ljava/util/TreeSet;-><init>()V
  0020 const-string v2, "latestVersion"
  0024 invoke-virtual v0, v2, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  002a move-result-wide v3
  002c const-wide/32 v5, 1791992148
  0032 cmp-long v3, v3, v5
  0036 const/4 v4, 0
  0038 if-nez v3, +029h
  003c new-instance v0, Lorg/json/JSONArray;
  0040 const-string v2, "ui/data/sparking-animation-paths.json"
  0044 const/high16 v3, 4194304
  0048 invoke-direct v8, v2, v3, Lcom/personal/aihub/CreatorActivity;->readTextAsset(Ljava/lang/String; I)Ljava/lang/String;
  004e move-result-object v2
  0050 invoke-direct v0, v2, Lorg/json/JSONArray;-><init>(Ljava/lang/String;)V
  0056 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  005c move-result v2
  005e if-ge v4, v2, +099h
  0062 invoke-virtual v0, v4, Lorg/json/JSONArray;->getString(I)Ljava/lang/String;
  0068 move-result-object v2
  006a invoke-static v2, Lcom/personal/aihub/CreatorActivity;->validAnimationPath(Ljava/lang/String;)Z
  0070 move-result v2
  0072 if-eqz v2, +009h
  0076 invoke-virtual v0, v4, Lorg/json/JSONArray;->getString(I)Ljava/lang/String;
  007c move-result-object v2
  007e invoke-virtual v1, v2, Ljava/util/TreeSet;->add(Ljava/lang/Object;)Z
  0084 add-int/lit8 v4, v4, 1
  0088 goto -19h
  008a new-instance v3, Lorg/json/JSONObject;
  008e invoke-virtual v0, v2, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0094 move-result-wide v5
  0096 invoke-direct v8, v5, v6, Lcom/personal/aihub/CreatorActivity;->sparkingAssetManifest(J)Ljava/io/File;
  009c move-result-object v5
  009e const/high16 v6, 33554432
  00a2 invoke-static v5, v6, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  00a8 move-result-object v5
  00aa invoke-direct v3, v5, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  00b0 const-string v5, "assets"
  00b4 invoke-virtual v3, v5, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  00ba move-result-object v3
  00bc invoke-virtual v3, Lorg/json/JSONArray;->length()I
  00c2 move-result v5
  00c4 if-ge v4, v5, +029h
  00c8 invoke-virtual v3, v4, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  00ce move-result-object v5
  00d0 const-string v6, "file_path"
  00d4 invoke-virtual v5, v6, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  00da move-result-object v5
  00dc const-string v6, "lua/"
  00e0 invoke-virtual v5, v6, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00e6 move-result v6
  00e8 if-eqz v6, +014h
  00ec const/4 v6, 4
  00ee invoke-virtual v5, v6, Ljava/lang/String;->substring(I)Ljava/lang/String;
  00f4 move-result-object v7
  00f6 invoke-static v7, Lcom/personal/aihub/CreatorActivity;->validAnimationPath(Ljava/lang/String;)Z
  00fc move-result v7
  00fe if-eqz v7, +009h
  0102 invoke-virtual v5, v6, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0108 move-result-object v5
  010a invoke-virtual v1, v5, Ljava/util/TreeSet;->add(Ljava/lang/Object;)Z
  0110 add-int/lit8 v4, v4, 1
  0114 goto -2ch
  0116 new-instance v3, Lcom/personal/aihub/CpkArchive;
  011a invoke-virtual v0, v2, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0120 move-result-wide v4
  0122 invoke-direct v8, v4, v5, Lcom/personal/aihub/CreatorActivity;->sparkingAssetManifest(J)Ljava/io/File;
  0128 move-result-object v0
  012a invoke-direct v8, v0, Lcom/personal/aihub/CreatorActivity;->sparkingBaseScripts(Ljava/io/File;)Ljava/io/File;
  0130 move-result-object v0
  0132 invoke-direct v3, v0, Lcom/personal/aihub/CpkArchive;-><init>(Ljava/io/File;)V
  0138 iget-object v0, v3, Lcom/personal/aihub/CpkArchive;->entries Ljava/util/List;
  013c invoke-interface v0, Ljava/util/List;->iterator()Ljava/util/Iterator;
  0142 move-result-object v0
  0144 invoke-interface v0, Ljava/util/Iterator;->hasNext()Z
  014a move-result v2
  014c if-eqz v2, +022h
  0150 invoke-interface v0, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0156 move-result-object v2
  0158 check-cast v2, Lcom/personal/aihub/CpkArchive$Entry;
  015c new-instance v3, Ljava/lang/StringBuilder;
  0160 const-string v4, "ab_script/"
  0164 invoke-direct v3, v4, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  016a iget-object v2, v2, Lcom/personal/aihub/CpkArchive$Entry;->path Ljava/lang/String;
  016e invoke-virtual v3, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0174 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  017a move-result-object v2
  017c invoke-static v2, Lcom/personal/aihub/CreatorActivity;->validAnimationPath(Ljava/lang/String;)Z
  0182 move-result v3
  0184 if-eqz v3, -020h
  0188 invoke-virtual v1, v2, Ljava/util/TreeSet;->add(Ljava/lang/Object;)Z
  018e goto -25h
  0190 new-instance v0, Lorg/json/JSONArray;
  0194 invoke-direct v0, v1, Lorg/json/JSONArray;-><init>(Ljava/util/Collection;)V
  019a return-object v0
.end method

.method sparkingAnimationSource(Ljava/lang/String; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 invoke-static v13, Lcom/personal/aihub/CreatorActivity;->validAnimationPath(Ljava/lang/String;)Z
  0006 move-result v0
  0008 if-eqz v0, +1bfh
  000c invoke-direct v12, Lcom/personal/aihub/CreatorActivity;->prepareSparkingSnapshot()V
  0012 invoke-virtual v14, Ljava/lang/String;->isEmpty()Z
  0018 move-result v0
  001a if-eqz v0, +026h
  001e new-instance v14, Ljava/lang/StringBuilder;
  0022 const-string v0, "sparking-source-"
  0026 invoke-direct v14, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  002c invoke-direct v12, Lcom/personal/aihub/CreatorActivity;->sparkingStore()Lcom/personal/aihub/GameDataStore;
  0032 move-result-object v0
  0034 invoke-virtual v0, Lcom/personal/aihub/GameDataStore;->meta()Lorg/json/JSONObject;
  003a move-result-object v0
  003c const-string v1, "latestVersion"
  0040 invoke-virtual v0, v1, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0046 move-result-wide v0
  0048 invoke-virtual v14, v0, v1, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  004e const-string v0, "/lua/"
  0052 invoke-virtual v14, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0058 invoke-virtual v14, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  005e invoke-virtual v14, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0064 move-result-object v14
  0066 invoke-virtual v12, v14, Lcom/personal/aihub/CreatorActivity;->assetFile(Ljava/lang/String;)Ljava/io/File;
  006c move-result-object v0
  006e invoke-virtual v0, Ljava/io/File;->isFile()Z
  0074 move-result v1
  0076 const-string v2, "size"
  007a const/4 v3, 0
  007c const/high16 v4, 2097152
  0080 if-nez v1, +11ch
  0084 invoke-virtual v0, Ljava/io/File;->getParentFile()Ljava/io/File;
  008a move-result-object v1
  008c invoke-virtual v1, Ljava/io/File;->mkdirs()Z
  0092 const-wide/16 v5, -1
  0096 invoke-direct v12, v5, v6, Lcom/personal/aihub/CreatorActivity;->sparkingAssetManifest(J)Ljava/io/File;
  009c move-result-object v1
  009e new-instance v5, Lorg/json/JSONObject;
  00a2 const/high16 v6, 33554432
  00a6 invoke-static v1, v6, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  00ac move-result-object v6
  00ae invoke-direct v5, v6, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  00b4 const-string v6, "assets"
  00b8 invoke-virtual v5, v6, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  00be move-result-object v6
  00c0 move v7, v3
  00c2 invoke-virtual v6, Lorg/json/JSONArray;->length()I
  00c8 move-result v8
  00ca if-ge v7, v8, +05ch
  00ce new-instance v8, Ljava/lang/StringBuilder;
  00d2 const-string v9, "lua/"
  00d6 invoke-direct v8, v9, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00dc invoke-virtual v8, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00e2 invoke-virtual v8, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00e8 move-result-object v8
  00ea invoke-virtual v6, v7, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  00f0 move-result-object v10
  00f2 const-string v11, "file_path"
  00f6 invoke-virtual v10, v11, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  00fc move-result-object v10
  00fe invoke-virtual v8, v10, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0104 move-result v8
  0106 if-eqz v8, +03bh
  010a new-instance v6, Ljava/lang/StringBuilder;
  010e invoke-direct v6, v9, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0114 invoke-virtual v6, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  011a invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0120 move-result-object v6
  0122 invoke-static v5, v6, Lcom/personal/aihub/SparkingContent;->assetRecord(Lorg/json/JSONObject; Ljava/lang/String;)Lorg/json/JSONObject;
  0128 move-result-object v5
  012a invoke-virtual v5, v2, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0130 move-result-wide v5
  0132 const-wide/32 v7, 2097152
  0138 cmp-long v5, v5, v7
  013c if-gtz v5, +018h
  0140 new-instance v5, Ljava/lang/StringBuilder;
  0144 invoke-direct v5, v9, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  014a invoke-virtual v5, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0150 invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0156 move-result-object v5
  0158 new-instance v6, Lcom/personal/aihub/CreatorActivity$$ExternalSyntheticLambda0;
  015c invoke-direct v6, v12, Lcom/personal/aihub/CreatorActivity$$ExternalSyntheticLambda0;-><init>(Lcom/personal/aihub/CreatorActivity;)V
  0162 invoke-static v1, v5, v0, v6, Lcom/personal/aihub/SparkingContent;->downloadAsset(Ljava/io/File; Ljava/lang/String; Ljava/io/File; Lcom/personal/aihub/SparkingContent$Progress;)Lorg/json/JSONObject;
  0168 goto/16 +0a8h
  016c new-instance v13, Ljava/io/IOException;
  0170 const-string v14, "This original animation exceeds the supported script size."
  0174 invoke-direct v13, v14, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  017a throw v13
  017c add-int/lit8 v7, v7, 1
  0180 goto -5fh
  0182 invoke-direct v12, v1, Lcom/personal/aihub/CreatorActivity;->sparkingBaseScripts(Ljava/io/File;)Ljava/io/File;
  0188 move-result-object v1
  018a new-instance v5, Lcom/personal/aihub/CpkArchive;
  018e invoke-direct v5, v1, Lcom/personal/aihub/CpkArchive;-><init>(Ljava/io/File;)V
  0194 const/16 v1, 10
  0198 invoke-virtual v13, v1, Ljava/lang/String;->substring(I)Ljava/lang/String;
  019e move-result-object v1
  01a0 iget-object v6, v5, Lcom/personal/aihub/CpkArchive;->entries Ljava/util/List;
  01a4 invoke-interface v6, Ljava/util/List;->iterator()Ljava/util/Iterator;
  01aa move-result-object v6
  01ac const/4 v7, 0
  01ae invoke-interface v6, Ljava/util/Iterator;->hasNext()Z
  01b4 move-result v8
  01b6 if-eqz v8, +01ch
  01ba invoke-interface v6, Ljava/util/Iterator;->next()Ljava/lang/Object;
  01c0 move-result-object v8
  01c2 check-cast v8, Lcom/personal/aihub/CpkArchive$Entry;
  01c6 iget-object v9, v8, Lcom/personal/aihub/CpkArchive$Entry;->path Ljava/lang/String;
  01ca invoke-virtual v1, v9, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01d0 move-result v9
  01d2 if-eqz v9, -012h
  01d6 if-nez v7, +004h
  01da move-object v7, v8
  01dc goto -17h
  01de new-instance v13, Ljava/io/IOException;
  01e2 const-string v14, "Conflicting original animation entries."
  01e6 invoke-direct v13, v14, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01ec throw v13
  01ee if-eqz v7, +05dh
  01f2 iget v1, v7, Lcom/personal/aihub/CpkArchive$Entry;->size I
  01f6 if-gt v1, v4, +059h
  01fa invoke-virtual v5, v7, Lcom/personal/aihub/CpkArchive;->read(Lcom/personal/aihub/CpkArchive$Entry;)[B
  0200 move-result-object v1
  0202 new-instance v5, Ljava/io/File;
  0206 invoke-virtual v0, Ljava/io/File;->getParentFile()Ljava/io/File;
  020c move-result-object v6
  020e new-instance v7, Ljava/lang/StringBuilder;
  0212 const-string v8, "source-"
  0216 invoke-direct v7, v8, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  021c invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0222 move-result-object v8
  0224 invoke-virtual v7, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  022a const-string v8, ".tmp"
  022e invoke-virtual v7, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0234 invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  023a move-result-object v7
  023c invoke-direct v5, v6, v7, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0242 new-instance v6, Ljava/io/FileOutputStream;
  0246 invoke-direct v6, v5, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  024c invoke-virtual v6, v1, Ljava/io/FileOutputStream;->write([B)V
  0252 invoke-virtual v6, Ljava/io/FileOutputStream;->getFD()Ljava/io/FileDescriptor;
  0258 move-result-object v1
  025a invoke-virtual v1, Ljava/io/FileDescriptor;->sync()V
  0260 invoke-virtual v6, Ljava/io/FileOutputStream;->close()V
  0266 invoke-virtual v5, v0, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  026c move-result v1
  026e if-eqz v1, +006h
  0272 invoke-virtual v5, Ljava/io/File;->delete()Z
  0278 goto +20h
  027a new-instance v13, Ljava/io/IOException;
  027e const-string v14, "Could not save the original animation."
  0282 invoke-direct v13, v14, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0288 throw v13
  028a move-exception v13
  028c invoke-virtual v6, Ljava/io/FileOutputStream;->close()V
  0292 goto +5h
  0294 move-exception v14
  0296 invoke-virtual v13, v14, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  029c throw v13
  029e move-exception v13
  02a0 invoke-virtual v5, Ljava/io/File;->delete()Z
  02a6 throw v13
  02a8 new-instance v13, Ljava/io/IOException;
  02ac const-string v14, "This animation is not present in Sparking's original collection or exceeds the supported size."
  02b0 invoke-direct v13, v14, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02b6 throw v13
  02b8 invoke-static v0, v4, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  02be move-result-object v1
  02c0 invoke-virtual v1, Ljava/lang/String;->trim()Ljava/lang/String;
  02c6 move-result-object v4
  02c8 invoke-virtual v4, Ljava/lang/String;->isEmpty()Z
  02ce move-result v4
  02d0 if-nez v4, +053h
  02d4 invoke-virtual v1, Ljava/lang/String;->trim()Ljava/lang/String;
  02da move-result-object v4
  02dc const-string v5, "<"
  02e0 invoke-virtual v4, v5, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  02e6 move-result v4
  02e8 if-nez v4, +047h
  02ec invoke-virtual v1, v3, Ljava/lang/String;->indexOf(I)I
  02f2 move-result v3
  02f4 if-gez v3, +041h
  02f8 new-instance v3, Lorg/json/JSONObject;
  02fc invoke-direct v3, Lorg/json/JSONObject;-><init>()V
  0302 const-string v4, "path"
  0306 invoke-virtual v3, v4, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  030c move-result-object v13
  030e const-string v3, "text"
  0312 invoke-virtual v13, v3, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0318 move-result-object v13
  031a const-string v1, "assetKey"
  031e invoke-virtual v13, v1, v14, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0324 move-result-object v13
  0326 invoke-virtual v0, Ljava/io/File;->length()J
  032c move-result-wide v3
  032e invoke-virtual v13, v2, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0334 move-result-object v13
  0336 const-string v14, "sha256"
  033a invoke-static v0, Lcom/personal/aihub/GameDataStore;->hash(Ljava/io/File;)Ljava/lang/String;
  0340 move-result-object v0
  0342 invoke-virtual v13, v14, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0348 move-result-object v13
  034a const-string v14, "cached"
  034e const/4 v0, 1
  0350 invoke-virtual v13, v14, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0356 move-result-object v13
  0358 const-string v14, "local"
  035c invoke-virtual v13, v14, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0362 move-result-object v13
  0364 const-string v14, "sourceDatabase"
  0368 const-string v0, "sparking"
  036c invoke-virtual v13, v14, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0372 move-result-object v13
  0374 return-object v13
  0376 new-instance v13, Ljava/io/IOException;
  037a const-string v14, "This Sparking animation file could not be opened."
  037e invoke-direct v13, v14, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0384 throw v13
  0386 new-instance v13, Ljava/io/IOException;
  038a const-string v14, "Choose a Sparking animation from the browser."
  038e invoke-direct v13, v14, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0394 throw v13
.end method

.method sparkingAssetManifest(J)Ljava/io/File;
  0000 invoke-direct v7, Lcom/personal/aihub/CreatorActivity;->prepareSparkingSnapshot()V
  0006 invoke-direct v7, Lcom/personal/aihub/CreatorActivity;->sparkingStore()Lcom/personal/aihub/GameDataStore;
  000c move-result-object v0
  000e invoke-virtual v0, Lcom/personal/aihub/GameDataStore;->meta()Lorg/json/JSONObject;
  0014 move-result-object v0
  0016 const-string v1, "latestVersion"
  001a invoke-virtual v0, v1, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0020 move-result-wide v2
  0022 const-wide/16 v4, -1
  0026 cmp-long v4, v8, v4
  002a if-eqz v4, +00fh
  002e cmp-long v8, v8, v2
  0032 if-nez v8, +003h
  0036 goto +9h
  0038 new-instance v8, Ljava/io/IOException;
  003c const-string v9, "This unit uses a different Sparking content version. Keep its original attached assets or recreate its copy from the matching catalogue."
  0040 invoke-direct v8, v9, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0046 throw v8
  0048 new-instance v8, Ljava/io/File;
  004c iget-object v9, v7, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0050 const-string v4, "sparking"
  0054 invoke-direct v8, v9, v4, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  005a new-instance v9, Ljava/lang/StringBuilder;
  005e const-string v4, "catalog-assets-"
  0062 invoke-direct v9, v4, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0068 invoke-virtual v9, v2, v3, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  006e const-string v4, ".json"
  0072 invoke-virtual v9, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0078 invoke-virtual v9, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  007e move-result-object v9
  0080 const-string v5, "assetsManifest"
  0084 invoke-virtual v0, v5, v9, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  008a move-result-object v9
  008c const-string v0, "(assets-[a-f0-9]{64}|catalog-assets-[0-9]+)\.json"
  0090 invoke-virtual v9, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0096 move-result v0
  0098 if-eqz v0, +058h
  009c new-instance v0, Ljava/io/File;
  00a0 invoke-direct v0, v8, v9, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00a6 invoke-virtual v0, Ljava/io/File;->isFile()Z
  00ac move-result v9
  00ae if-nez v9, +04ch
  00b2 new-instance v9, Ljava/io/File;
  00b6 new-instance v5, Ljava/lang/StringBuilder;
  00ba const-string v6, "manifest-"
  00be invoke-direct v5, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00c4 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  00ca move-result-object v6
  00cc invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  00d2 invoke-virtual v5, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00d8 invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00de move-result-object v4
  00e0 invoke-direct v9, v8, v4, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00e6 new-instance v8, Lcom/personal/aihub/CreatorActivity$$ExternalSyntheticLambda5;
  00ea invoke-direct v8, v7, Lcom/personal/aihub/CreatorActivity$$ExternalSyntheticLambda5;-><init>(Lcom/personal/aihub/CreatorActivity;)V
  00f0 invoke-static v9, v8, Lcom/personal/aihub/SparkingContent;->downloadManifest(Ljava/io/File; Lcom/personal/aihub/SparkingContent$Progress;)Lorg/json/JSONObject;
  00f6 move-result-object v8
  00f8 invoke-virtual v8, v1, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  00fe move-result-wide v4
  0100 cmp-long v8, v4, v2
  0104 if-nez v8, +014h
  0108 invoke-virtual v9, v0, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  010e move-result v8
  0110 if-eqz v8, +006h
  0114 invoke-virtual v9, Ljava/io/File;->delete()Z
  011a goto +16h
  011c new-instance v8, Ljava/io/IOException;
  0120 const-string v0, "Could not save the resource list."
  0124 invoke-direct v8, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  012a throw v8
  012c new-instance v8, Ljava/io/IOException;
  0130 const-string v0, "Sparking's server has newer game content. Import the supported APK and update characters before downloading these resources."
  0134 invoke-direct v8, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  013a throw v8
  013c move-exception v8
  013e invoke-virtual v9, Ljava/io/File;->delete()Z
  0144 throw v8
  0146 return-object v0
  0148 new-instance v8, Ljava/io/IOException;
  014c const-string v9, "Invalid Sparking resource-list reference."
  0150 invoke-direct v8, v9, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0156 throw v8
.end method

.method sparkingBaseScripts(Ljava/io/File;)Ljava/io/File;
  0000 new-instance v0, Ljava/io/File;
  0004 new-instance v1, Ljava/io/File;
  0008 iget-object v2, v5, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  000c const-string v3, "sparking"
  0010 invoke-direct v1, v2, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0016 new-instance v2, Ljava/lang/StringBuilder;
  001a const-string v3, "base-scripts-"
  001e invoke-direct v2, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0024 invoke-direct v5, Lcom/personal/aihub/CreatorActivity;->sparkingStore()Lcom/personal/aihub/GameDataStore;
  002a move-result-object v3
  002c invoke-virtual v3, Lcom/personal/aihub/GameDataStore;->meta()Lorg/json/JSONObject;
  0032 move-result-object v3
  0034 const-string v4, "latestVersion"
  0038 invoke-virtual v3, v4, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  003e move-result-wide v3
  0040 invoke-virtual v2, v3, v4, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0046 const-string v3, ".cpk"
  004a invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0050 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0056 move-result-object v2
  0058 invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  005e invoke-virtual v0, Ljava/io/File;->isFile()Z
  0064 move-result v1
  0066 if-nez v1, +00ch
  006a new-instance v1, Lcom/personal/aihub/CreatorActivity$$ExternalSyntheticLambda6;
  006e invoke-direct v1, v5, Lcom/personal/aihub/CreatorActivity$$ExternalSyntheticLambda6;-><init>(Lcom/personal/aihub/CreatorActivity;)V
  0074 const-string v2, "lua/ab_script.cpk"
  0078 invoke-static v6, v2, v0, v1, Lcom/personal/aihub/SparkingContent;->downloadAsset(Ljava/io/File; Ljava/lang/String; Ljava/io/File; Lcom/personal/aihub/SparkingContent$Progress;)Lorg/json/JSONObject;
  007e return-object v0
.end method

.method sparkingDatabaseKey()Ljava/io/File;
  0000 new-instance v0, Ljava/io/File;
  0004 iget-object v1, v3, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0008 const-string v2, "sparking-database-format.bin"
  000c invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0012 return-object v0
.end method

.method sparkingFormatKey()Ljava/io/File;
  0000 new-instance v0, Ljava/io/File;
  0004 iget-object v1, v3, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0008 const-string v2, "sprk-format-key.bin"
  000c invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0012 return-object v0
.end method

.method sparkingInfo()Lorg/json/JSONObject;
  0000 invoke-direct v8, Lcom/personal/aihub/CreatorActivity;->prepareSparkingSnapshot()V
  0006 invoke-direct v8, Lcom/personal/aihub/CreatorActivity;->sparkingStore()Lcom/personal/aihub/GameDataStore;
  000c move-result-object v0
  000e invoke-virtual v0, Lcom/personal/aihub/GameDataStore;->state()Lorg/json/JSONObject;
  0014 move-result-object v0
  0016 const/4 v1, 1
  0018 const/4 v2, 0
  001a if-eqz v0, +004h
  001e move v0, v1
  0020 goto +2h
  0022 move v0, v2
  0024 new-instance v3, Lorg/json/JSONObject;
  0028 invoke-direct v3, Lorg/json/JSONObject;-><init>()V
  002e const-string v4, "available"
  0032 invoke-virtual v3, v4, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0038 move-result-object v3
  003a invoke-direct v8, Lcom/personal/aihub/CreatorActivity;->sparkingDatabaseKey()Ljava/io/File;
  0040 move-result-object v4
  0042 invoke-virtual v4, Ljava/io/File;->length()J
  0048 move-result-wide v4
  004a const-wide/16 v6, 64
  004e cmp-long v4, v4, v6
  0052 if-nez v4, +003h
  0056 goto +2h
  0058 move v1, v2
  005a const-string v4, "keyConfigured"
  005e invoke-virtual v3, v4, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0064 move-result-object v1
  0066 if-eqz v0, +041h
  006a invoke-direct v8, Lcom/personal/aihub/CreatorActivity;->ensureSparkingDb()V
  0070 iget-object v0, v8, Lcom/personal/aihub/CreatorActivity;->sparkingDb Landroid/database/sqlite/SQLiteDatabase;
  0074 const-string v3, "SELECT count(*) FROM cards"
  0078 const/4 v4, 0
  007a invoke-virtual v0, v3, v4, Landroid/database/sqlite/SQLiteDatabase;->rawQuery(Ljava/lang/String; [Ljava/lang/String;)Landroid/database/Cursor;
  0080 move-result-object v0
  0082 invoke-interface v0, Landroid/database/Cursor;->moveToFirst()Z
  0088 const-string v3, "count"
  008c invoke-interface v0, v2, Landroid/database/Cursor;->getLong(I)J
  0092 move-result-wide v4
  0094 invoke-virtual v1, v3, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  009a if-eqz v0, +005h
  009e invoke-interface v0, Landroid/database/Cursor;->close()V
  00a4 const-string v0, "schema"
  00a8 iget-object v2, v8, Lcom/personal/aihub/CreatorActivity;->sparkingSchema Lorg/json/JSONObject;
  00ac invoke-virtual v1, v0, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00b2 move-result-object v0
  00b4 invoke-direct v8, Lcom/personal/aihub/CreatorActivity;->sparkingStore()Lcom/personal/aihub/GameDataStore;
  00ba move-result-object v2
  00bc invoke-virtual v2, Lcom/personal/aihub/GameDataStore;->meta()Lorg/json/JSONObject;
  00c2 move-result-object v2
  00c4 const-string v3, "meta"
  00c8 invoke-virtual v0, v3, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00ce goto +dh
  00d0 move-exception v1
  00d2 if-eqz v0, +00ah
  00d6 invoke-interface v0, Landroid/database/Cursor;->close()V
  00dc goto +5h
  00de move-exception v0
  00e0 invoke-virtual v1, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  00e6 throw v1
  00e8 return-object v1
.end method

.method sparkingStore()Lcom/personal/aihub/GameDataStore;
  0000 new-instance v0, Lcom/personal/aihub/GameDataStore;
  0004 new-instance v1, Ljava/io/File;
  0008 iget-object v2, v5, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  000c const-string v3, "sparking"
  0010 invoke-direct v1, v2, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0016 new-instance v2, Ljava/io/File;
  001a iget-object v3, v5, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  001e const-string v4, "sparking-unavailable.db"
  0022 invoke-direct v2, v3, v4, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0028 invoke-direct v0, v1, v2, Lcom/personal/aihub/GameDataStore;-><init>(Ljava/io/File; Ljava/io/File;)V
  002e return-object v0
.end method

.method syncDatabase()Lorg/json/JSONObject;
  0000 new-instance v0, Lorg/json/JSONObject;
  0004 invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  000a invoke-direct v8, v0, Lcom/personal/aihub/CreatorActivity;->downloadCurrentDatabase(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0010 move-result-object v0
  0012 const-string v2, "done"
  0016 const-string v3, "Game database updated"
  001a const-wide/16 v4, 0
  001e const-wide/16 v6, 0
  0022 move-object v1, v8
  0024 invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  002a return-object v0
  002c move-exception v0
  002e const-wide/16 v4, 0
  0032 const-wide/16 v6, 0
  0036 const-string v2, "error"
  003a const-string v3, "Update failed; previous data was kept"
  003e move-object v1, v8
  0040 invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  0046 throw v0
.end method

.method updateSparking()Lorg/json/JSONObject;
  0000 move-object/from16 v8, v16
  0004 const-string v0, "assets-"
  0008 invoke-direct/range v16, Lcom/personal/aihub/CreatorActivity;->sparkingDatabaseKey()Ljava/io/File;
  000e move-result-object v1
  0010 invoke-virtual v1, Ljava/io/File;->isFile()Z
  0016 move-result v2
  0018 if-eqz v2, +13dh
  001c invoke-virtual v1, Ljava/io/File;->length()J
  0022 move-result-wide v2
  0024 const-wide/16 v4, 64
  0028 cmp-long v2, v2, v4
  002c if-nez v2, +133h
  0030 const/16 v2, 64
  0034 new-array v9, v2, [B
  0038 new-instance v2, Ljava/io/DataInputStream;
  003c new-instance v3, Ljava/io/FileInputStream;
  0040 invoke-direct v3, v1, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0046 invoke-direct v2, v3, Ljava/io/DataInputStream;-><init>(Ljava/io/InputStream;)V
  004c invoke-virtual v2, v9, Ljava/io/DataInputStream;->readFully([B)V
  0052 invoke-virtual v2, Ljava/io/DataInputStream;->close()V
  0058 new-instance v10, Ljava/io/File;
  005c invoke-virtual/range v16, Lcom/personal/aihub/CreatorActivity;->getCacheDir()Ljava/io/File;
  0062 move-result-object v1
  0064 new-instance v2, Ljava/lang/StringBuilder;
  0068 const-string v3, "sparking-data-"
  006c invoke-direct v2, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0072 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0078 move-result-object v3
  007a invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0080 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0086 move-result-object v2
  0088 invoke-direct v10, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  008e invoke-virtual v10, Ljava/io/File;->mkdir()Z
  0094 move-result v1
  0096 if-eqz v1, +0eah
  009a const/4 v11, 0
  009c new-instance v12, Ljava/io/File;
  00a0 const-string v1, "database.db"
  00a4 invoke-direct v12, v10, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00aa new-instance v13, Ljava/io/File;
  00ae const-string v1, "assets.json"
  00b2 invoke-direct v13, v10, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00b8 new-instance v14, Ljava/io/File;
  00bc const-string v1, "readable.db"
  00c0 invoke-direct v14, v10, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00c6 new-instance v1, Lcom/personal/aihub/CreatorActivity$$ExternalSyntheticLambda4;
  00ca invoke-direct v1, v8, Lcom/personal/aihub/CreatorActivity$$ExternalSyntheticLambda4;-><init>(Lcom/personal/aihub/CreatorActivity;)V
  00d0 invoke-static v12, v13, v1, Lcom/personal/aihub/SparkingContent;->download(Ljava/io/File; Ljava/io/File; Lcom/personal/aihub/SparkingContent$Progress;)Lorg/json/JSONObject;
  00d6 move-result-object v15
  00d8 const-string v1, "sourceEncryptedSHA256"
  00dc const-string v2, "sha256"
  00e0 invoke-virtual v15, v2, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  00e6 move-result-object v2
  00e8 invoke-virtual v15, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00ee const-string v2, "decrypt"
  00f2 const-string v3, "Opening and authenticating Sparking game data"
  00f6 const-wide/16 v4, 0
  00fa const-wide/16 v6, 0
  00fe move-object/from16 v1, v16
  0102 invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  0108 const/4 v1, 4
  010a invoke-static v12, v14, v9, v1, Lcom/personal/aihub/LegacyDatabase;->decrypt(Ljava/io/File; Ljava/io/File; [B I)V
  0110 const-string v2, "verify"
  0114 const-string v3, "Checking Sparking characters and skills"
  0118 const-wide/16 v4, 0
  011c const-wide/16 v6, 0
  0120 move-object/from16 v1, v16
  0124 invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  012a const/4 v1, 1
  012c invoke-direct v8, v14, v1, Lcom/personal/aihub/CreatorActivity;->verifyDb(Ljava/io/File; Z)J
  0132 move-result-wide v1
  0134 new-instance v3, Ljava/io/File;
  0138 iget-object v4, v8, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  013c const-string v5, "sparking"
  0140 invoke-direct v3, v4, v5, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0146 invoke-virtual v3, Ljava/io/File;->mkdirs()Z
  014c new-instance v4, Ljava/lang/StringBuilder;
  0150 invoke-direct v4, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0156 invoke-static v13, Lcom/personal/aihub/GameDataStore;->hash(Ljava/io/File;)Ljava/lang/String;
  015c move-result-object v0
  015e invoke-virtual v4, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0164 const-string v0, ".json"
  0168 invoke-virtual v4, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  016e invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0174 move-result-object v0
  0176 new-instance v4, Ljava/io/File;
  017a invoke-direct v4, v3, v0, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0180 invoke-virtual v4, Ljava/io/File;->exists()Z
  0186 move-result v3
  0188 if-nez v3, +011h
  018c invoke-virtual v13, v4, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  0192 move-result v3
  0194 if-eqz v3, +003h
  0198 goto +9h
  019a new-instance v0, Ljava/io/IOException;
  019e const-string v1, "Could not save Sparking's resource list."
  01a2 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01a8 throw v0
  01aa sget-object v3, Lcom/personal/aihub/CreatorActivity;->DATABASE_WRITES Ljava/lang/Object;
  01ae monitor-enter v3
  01b0 invoke-direct/range v16, Lcom/personal/aihub/CreatorActivity;->sparkingStore()Lcom/personal/aihub/GameDataStore;
  01b6 move-result-object v4
  01b8 const-string v5, "source"
  01bc const-string v6, "Sparking game database"
  01c0 invoke-virtual v15, v5, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01c6 move-result-object v5
  01c8 const-string v6, "sourceType"
  01cc const-string v7, "sparking-current"
  01d0 invoke-virtual v5, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01d6 move-result-object v5
  01d8 const-string v6, "date"
  01dc invoke-static Lcom/personal/aihub/CreatorActivity;->isoStamp()Ljava/lang/String;
  01e2 move-result-object v7
  01e4 invoke-virtual v5, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01ea move-result-object v5
  01ec const-string v6, "count"
  01f0 invoke-virtual v5, v6, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  01f6 move-result-object v1
  01f8 const-string v2, "assetsManifest"
  01fc invoke-virtual v1, v2, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0202 move-result-object v0
  0204 invoke-virtual v4, v14, v0, Lcom/personal/aihub/GameDataStore;->commit(Ljava/io/File; Lorg/json/JSONObject;)V
  020a iget-object v0, v8, Lcom/personal/aihub/CreatorActivity;->sparkingDb Landroid/database/sqlite/SQLiteDatabase;
  020e if-eqz v0, +005h
  0212 invoke-virtual v0, Landroid/database/sqlite/SQLiteDatabase;->close()V
  0218 const/4 v0, 0
  021a iput-object v0, v8, Lcom/personal/aihub/CreatorActivity;->sparkingDb Landroid/database/sqlite/SQLiteDatabase;
  021e iput-object v0, v8, Lcom/personal/aihub/CreatorActivity;->sparkingSchema Lorg/json/JSONObject;
  0222 monitor-exit v3
  0224 const-string v2, "done"
  0228 const-string v3, "Sparking characters are ready in Library"
  022c const-wide/16 v4, 0
  0230 const-wide/16 v6, 0
  0234 move-object/from16 v1, v16
  0238 invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  023e invoke-direct/range v16, Lcom/personal/aihub/CreatorActivity;->sparkingInfo()Lorg/json/JSONObject;
  0244 move-result-object v0
  0246 invoke-static v9, v11, Ljava/util/Arrays;->fill([B B)V
  024c invoke-static v10, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  0252 return-object v0
  0254 move-exception v0
  0256 monitor-exit v3
  0258 throw v0
  025a move-exception v0
  025c invoke-static v9, v11, Ljava/util/Arrays;->fill([B B)V
  0262 invoke-static v10, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  0268 throw v0
  026a new-instance v0, Ljava/io/IOException;
  026e const-string v1, "Could not prepare Sparking game data."
  0272 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0278 throw v0
  027a move-exception v0
  027c move-object v1, v0
  027e invoke-virtual v2, Ljava/io/DataInputStream;->close()V
  0284 goto +6h
  0286 move-exception v0
  0288 move-object v2, v0
  028a invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0290 throw v1
  0292 new-instance v0, Ljava/io/IOException;
  0296 const-string v1, "Import the original Sparking 6.5.5 APK or its ZIP first. Then download characters here."
  029a invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02a0 throw v0
.end method

.method useDb(Ljava/io/File; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 new-instance v0, Lorg/json/JSONObject;
  0004 invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  000a invoke-direct v1, v2, v3, v0, Lcom/personal/aihub/CreatorActivity;->useDb(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0010 move-result-object v2
  0012 return-object v2
.end method

.method useDb(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 sget-object v0, Lcom/personal/aihub/CreatorActivity;->DATABASE_WRITES Ljava/lang/Object;
  0004 monitor-enter v0
  0006 invoke-direct v4, Lcom/personal/aihub/CreatorActivity;->ensureDb()V
  000c invoke-direct v4, Lcom/personal/aihub/CreatorActivity;->dataStore()Lcom/personal/aihub/GameDataStore;
  0012 move-result-object v1
  0014 new-instance v2, Lorg/json/JSONObject;
  0018 invoke-virtual v7, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  001e move-result-object v7
  0020 invoke-direct v2, v7, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0026 const-string v7, "source"
  002a invoke-virtual v2, v7, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0030 move-result-object v6
  0032 const-string v7, "date"
  0036 invoke-static Lcom/personal/aihub/CreatorActivity;->isoStamp()Ljava/lang/String;
  003c move-result-object v2
  003e invoke-virtual v6, v7, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0044 move-result-object v6
  0046 const-string v7, "count"
  004a const/4 v2, 0
  004c invoke-direct v4, v5, v2, Lcom/personal/aihub/CreatorActivity;->verifyDb(Ljava/io/File; Z)J
  0052 move-result-wide v2
  0054 invoke-virtual v6, v7, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  005a move-result-object v6
  005c invoke-virtual v1, v5, v6, Lcom/personal/aihub/GameDataStore;->commit(Ljava/io/File; Lorg/json/JSONObject;)V
  0062 new-instance v5, Ljava/io/File;
  0066 iget-object v6, v4, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  006a const-string v7, "animation-files.json"
  006e invoke-direct v5, v6, v7, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0074 invoke-virtual v5, Ljava/io/File;->delete()Z
  007a iget-object v5, v4, Lcom/personal/aihub/CreatorActivity;->db Landroid/database/sqlite/SQLiteDatabase;
  007e if-eqz v5, +005h
  0082 invoke-virtual v5, Landroid/database/sqlite/SQLiteDatabase;->close()V
  0088 const/4 v5, 0
  008a iput-object v5, v4, Lcom/personal/aihub/CreatorActivity;->db Landroid/database/sqlite/SQLiteDatabase;
  008e invoke-direct v4, Lcom/personal/aihub/CreatorActivity;->info()Lorg/json/JSONObject;
  0094 move-result-object v5
  0096 monitor-exit v0
  0098 return-object v5
  009a move-exception v5
  009c monitor-exit v0
  009e throw v5
.end method

.method validAnimationPath(Ljava/lang/String;)Z
  0000 if-eqz v2, +01ah
  0004 invoke-virtual v2, Ljava/lang/String;->length()I
  000a move-result v0
  000c const/16 v1, 240
  0010 if-ge v0, v1, +012h
  0014 const-string v0, "(?i)ab_script/[a-z0-9_/-]+\.lua"
  0018 invoke-virtual v2, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  001e move-result v0
  0020 if-eqz v0, +00ah
  0024 invoke-static v2, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  002a move-result v2
  002c if-eqz v2, +004h
  0030 const/4 v2, 1
  0032 goto +2h
  0034 const/4 v2, 0
  0036 return v2
.end method

.method verifiedMusicPath(Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray;)Ljava/lang/String;
  0000 const-string v0, "lua/"
  0004 const-string v1, "lua"
  0008 invoke-virtual v7, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  000e move-result v7
  0010 const-string v1, ""
  0014 if-eqz v7, +095h
  0018 const-string v7, "ab_script/finish_skill/[A-Za-z0-9_]{1,80}\.lua"
  001c invoke-virtual v8, v7, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0022 move-result v7
  0024 if-nez v7, +004h
  0028 goto/16 +08bh
  002c invoke-virtual v9, Ljava/lang/String;->isEmpty()Z
  0032 move-result v7
  0034 if-eqz v7, +003h
  0038 return-object v8
  003a new-instance v7, Lcom/personal/aihub/GameAssets;
  003e iget-object v2, v6, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  0042 invoke-direct v7, v2, v10, v11, Lcom/personal/aihub/GameAssets;-><init>(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray;)V
  0048 new-instance v10, Ljava/lang/StringBuilder;
  004c invoke-direct v10, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0052 invoke-virtual v10, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0058 invoke-virtual v10, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  005e move-result-object v10
  0060 const/high16 v11, 2097152
  0064 invoke-virtual v7, v10, v11, Lcom/personal/aihub/GameAssets;->read(Ljava/lang/String; I)[B
  006a move-result-object v7
  006c if-nez v7, +05ah
  0070 invoke-direct v6, Lcom/personal/aihub/CreatorActivity;->dataStore()Lcom/personal/aihub/GameDataStore;
  0076 move-result-object v7
  0078 invoke-virtual v7, Lcom/personal/aihub/GameDataStore;->meta()Lorg/json/JSONObject;
  007e move-result-object v7
  0080 const-string v10, "date"
  0084 const-string v11, "sha256"
  0088 const-string v0, "bundled"
  008c invoke-virtual v7, v11, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0092 move-result-object v11
  0094 invoke-virtual v7, v10, v11, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  009a move-result-object v7
  009c const-string v10, "[^a-zA-Z0-9_-]"
  00a0 invoke-virtual v7, v10, v1, Ljava/lang/String;->replaceAll(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  00a6 move-result-object v7
  00a8 invoke-virtual v7, Ljava/lang/String;->length()I
  00ae move-result v10
  00b0 const/16 v11, 80
  00b4 if-le v10, v11, +007h
  00b8 const/4 v10, 0
  00ba invoke-virtual v7, v10, v11, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  00c0 move-result-object v7
  00c2 new-instance v10, Ljava/io/File;
  00c6 new-instance v11, Ljava/io/File;
  00ca new-instance v0, Ljava/io/File;
  00ce iget-object v2, v6, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  00d2 const-string v3, "animation-sources"
  00d6 invoke-direct v0, v2, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00dc invoke-direct v11, v0, v7, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00e2 invoke-direct v10, v11, v8, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00e8 invoke-virtual v10, Ljava/io/File;->isFile()Z
  00ee move-result v7
  00f0 if-eqz v7, +017h
  00f4 invoke-virtual v10, Ljava/io/File;->length()J
  00fa move-result-wide v2
  00fc const-wide/32 v4, 2097152
  0102 cmp-long v7, v2, v4
  0106 if-lez v7, +003h
  010a goto +ah
  010c invoke-virtual v10, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0112 move-result-object v7
  0114 invoke-static v7, Ljava/nio/file/Files;->readAllBytes(Ljava/nio/file/Path;)[B
  011a move-result-object v7
  011c goto +2h
  011e return-object v1
  0120 sget-object v10, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0124 invoke-virtual v9, v10, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  012a move-result-object v9
  012c invoke-static v7, v9, Ljava/util/Arrays;->equals([B [B)Z
  0132 move-result v7
  0134 if-eqz v7, +003h
  0138 goto +2h
  013a move-object v8, v1
  013c return-object v8
  013e return-object v1
.end method

.method verifyDb(Ljava/io/File; Z)J
  0000 const-string v0, "name"
  0004 const-string v1, "id"
  0008 invoke-virtual/range v28, Ljava/io/File;->getPath()Ljava/lang/String;
  000e move-result-object v2
  0010 const/4 v3, 0
  0012 const/4 v4, 1
  0014 invoke-static v2, v3, v4, Landroid/database/sqlite/SQLiteDatabase;->openDatabase(Ljava/lang/String; Landroid/database/sqlite/SQLiteDatabase$CursorFactory; I)Landroid/database/sqlite/SQLiteDatabase;
  001a move-result-object v2
  001c const-string v5, "PRAGMA quick_check"
  0020 invoke-virtual v2, v5, v3, Landroid/database/sqlite/SQLiteDatabase;->rawQuery(Ljava/lang/String; [Ljava/lang/String;)Landroid/database/Cursor;
  0026 move-result-object v5
  0028 invoke-interface v5, Landroid/database/Cursor;->moveToFirst()Z
  002e move-result v6
  0030 if-eqz v6, +15ch
  0034 const-string v6, "ok"
  0038 const/4 v7, 0
  003a invoke-interface v5, v7, Landroid/database/Cursor;->getString(I)Ljava/lang/String;
  0040 move-result-object v8
  0042 invoke-virtual v6, v8, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0048 move-result v6
  004a if-eqz v6, +14fh
  004e if-eqz v5, +005h
  0052 invoke-interface v5, Landroid/database/Cursor;->close()V
  0058 const-string v8, "cards"
  005c const-string v9, "id"
  0060 const-string v10, "name"
  0064 const-string v11, "rarity"
  0068 const-string v12, "element"
  006c const-string v13, "resource_id"
  0070 const-string v14, "hp_max"
  0074 const-string v15, "atk_max"
  0078 const-string v16, "def_max"
  007c const-string v17, "passive_skill_set_id"
  0080 const-string v18, "leader_skill_set_id"
  0084 filled-new-array/range v8 ... v18, [Ljava/lang/String;
  008a move-result-object v19
  008c const-string v5, "card_categories"
  0090 filled-new-array v5, v1, v0, [Ljava/lang/String;
  0096 move-result-object v20
  0098 const-string v5, "link_skills"
  009c filled-new-array v5, v1, v0, [Ljava/lang/String;
  00a2 move-result-object v21
  00a4 const-string v0, "leader_skill_sets"
  00a8 filled-new-array v0, v1, [Ljava/lang/String;
  00ae move-result-object v22
  00b0 const-string v0, "leader_skills"
  00b4 const-string v5, "leader_skill_set_id"
  00b8 filled-new-array v0, v1, v5, [Ljava/lang/String;
  00be move-result-object v23
  00c0 const-string v0, "passive_skill_sets"
  00c4 filled-new-array v0, v1, [Ljava/lang/String;
  00ca move-result-object v24
  00cc const-string v0, "passive_skills"
  00d0 filled-new-array v0, v1, [Ljava/lang/String;
  00d6 move-result-object v25
  00d8 const-string v0, "passive_skill_set_relations"
  00dc const-string v5, "passive_skill_set_id"
  00e0 const-string v6, "passive_skill_id"
  00e4 filled-new-array v0, v1, v5, v6, [Ljava/lang/String;
  00ea move-result-object v26
  00ec filled-new-array/range v19 ... v26, [[Ljava/lang/String;
  00f2 move-result-object v0
  00f4 move v1, v7
  00f6 const/16 v5, 8
  00fa if-ge v1, v5, +0c0h
  00fe aget-object v5, v0, v1
  0102 new-instance v6, Ljava/util/HashSet;
  0106 invoke-direct v6, Ljava/util/HashSet;-><init>()V
  010c new-instance v8, Ljava/lang/StringBuilder;
  0110 invoke-direct v8, Ljava/lang/StringBuilder;-><init>()V
  0116 const-string v9, "PRAGMA table_info("
  011a invoke-virtual v8, v9, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0120 aget-object v9, v5, v7
  0124 invoke-static v9, Lcom/personal/aihub/CreatorActivity;->identifier(Ljava/lang/String;)Ljava/lang/String;
  012a move-result-object v9
  012c invoke-virtual v8, v9, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0132 const-string v9, ")"
  0136 invoke-virtual v8, v9, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  013c invoke-virtual v8, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0142 move-result-object v8
  0144 invoke-virtual v2, v8, v3, Landroid/database/sqlite/SQLiteDatabase;->rawQuery(Ljava/lang/String; [Ljava/lang/String;)Landroid/database/Cursor;
  014a move-result-object v8
  014c invoke-interface v8, Landroid/database/Cursor;->moveToNext()Z
  0152 move-result v9
  0154 if-eqz v9, +00ah
  0158 invoke-interface v8, v4, Landroid/database/Cursor;->getString(I)Ljava/lang/String;
  015e move-result-object v9
  0160 invoke-virtual v6, v9, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  0166 goto -dh
  0168 if-eqz v8, +005h
  016c invoke-interface v8, Landroid/database/Cursor;->close()V
  0172 move v8, v4
  0174 array-length v9, v5
  0176 if-ge v8, v9, +026h
  017a aget-object v9, v5, v8
  017e invoke-virtual v6, v9, Ljava/util/HashSet;->contains(Ljava/lang/Object;)Z
  0184 move-result v9
  0186 if-eqz v9, +005h
  018a add-int/lit8 v8, v8, 1
  018e goto -dh
  0190 new-instance v0, Ljava/io/IOException;
  0194 new-instance v1, Ljava/lang/StringBuilder;
  0198 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  019e const-string v3, "Database is missing game fields: "
  01a2 invoke-virtual v1, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01a8 aget-object v3, v5, v7
  01ac invoke-virtual v1, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01b2 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01b8 move-result-object v1
  01ba invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01c0 throw v0
  01c2 const-string v6, "SELECT type FROM sqlite_master WHERE name=?"
  01c6 aget-object v8, v5, v7
  01ca filled-new-array v8, [Ljava/lang/String;
  01d0 move-result-object v8
  01d2 invoke-virtual v2, v6, v8, Landroid/database/sqlite/SQLiteDatabase;->rawQuery(Ljava/lang/String; [Ljava/lang/String;)Landroid/database/Cursor;
  01d8 move-result-object v6
  01da invoke-interface v6, Landroid/database/Cursor;->moveToFirst()Z
  01e0 move-result v8
  01e2 if-eqz v8, +017h
  01e6 const-string v8, "table"
  01ea invoke-interface v6, v7, Landroid/database/Cursor;->getString(I)Ljava/lang/String;
  01f0 move-result-object v9
  01f2 invoke-virtual v8, v9, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01f8 move-result v8
  01fa if-eqz v8, +00bh
  01fe if-eqz v6, +005h
  0202 invoke-interface v6, Landroid/database/Cursor;->close()V
  0208 add-int/lit8 v1, v1, 1
  020c goto/16 -08bh
  0210 new-instance v0, Ljava/io/IOException;
  0214 new-instance v1, Ljava/lang/StringBuilder;
  0218 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  021e const-string v3, "Expected game data table: "
  0222 invoke-virtual v1, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0228 aget-object v3, v5, v7
  022c invoke-virtual v1, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0232 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0238 move-result-object v1
  023a invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0240 throw v0
  0242 move-exception v0
  0244 move-object v1, v0
  0246 if-eqz v6, +00bh
  024a invoke-interface v6, Landroid/database/Cursor;->close()V
  0250 goto +6h
  0252 move-exception v0
  0254 move-object v3, v0
  0256 invoke-virtual v1, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  025c throw v1
  025e move-exception v0
  0260 move-object v1, v0
  0262 if-eqz v8, +00bh
  0266 invoke-interface v8, Landroid/database/Cursor;->close()V
  026c goto +6h
  026e move-exception v0
  0270 move-object v3, v0
  0272 invoke-virtual v1, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0278 throw v1
  027a const-string v0, "SELECT count(*) FROM cards"
  027e invoke-virtual v2, v0, v3, Landroid/database/sqlite/SQLiteDatabase;->rawQuery(Ljava/lang/String; [Ljava/lang/String;)Landroid/database/Cursor;
  0284 move-result-object v1
  0286 invoke-interface v1, Landroid/database/Cursor;->moveToFirst()Z
  028c invoke-interface v1, v7, Landroid/database/Cursor;->getLong(I)J
  0292 move-result-wide v5
  0294 if-eqz v29, +004h
  0298 const/16 v4, 1000
  029c int-to-long v3, v4
  029e cmp-long v0, v5, v3
  02a2 if-ltz v0, +00dh
  02a6 if-eqz v1, +005h
  02aa invoke-interface v1, Landroid/database/Cursor;->close()V
  02b0 if-eqz v2, +005h
  02b4 invoke-virtual v2, Landroid/database/sqlite/SQLiteDatabase;->close()V
  02ba return-wide v5
  02bc new-instance v0, Ljava/io/IOException;
  02c0 const-string v3, "The database contains starter or incomplete card data"
  02c4 invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02ca throw v0
  02cc move-exception v0
  02ce move-object v3, v0
  02d0 if-eqz v1, +00bh
  02d4 invoke-interface v1, Landroid/database/Cursor;->close()V
  02da goto +6h
  02dc move-exception v0
  02de move-object v1, v0
  02e0 invoke-virtual v3, v1, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  02e6 throw v3
  02e8 new-instance v0, Ljava/io/IOException;
  02ec const-string v1, "Database integrity check failed"
  02f0 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02f6 throw v0
  02f8 move-exception v0
  02fa move-object v1, v0
  02fc if-eqz v5, +00bh
  0300 invoke-interface v5, Landroid/database/Cursor;->close()V
  0306 goto +6h
  0308 move-exception v0
  030a move-object v3, v0
  030c invoke-virtual v1, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0312 throw v1
  0314 move-exception v0
  0316 move-object v1, v0
  0318 if-eqz v2, +00bh
  031c invoke-virtual v2, Landroid/database/sqlite/SQLiteDatabase;->close()V
  0322 goto +6h
  0324 move-exception v0
  0326 move-object v2, v0
  0328 invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  032e throw v1
.end method

.method verifyDb(Ljava/io/File;)V
  0000 const/4 v0, 0
  0002 invoke-direct v1, v2, v0, Lcom/personal/aihub/CreatorActivity;->verifyDb(Ljava/io/File; Z)J
  0008 return-void 
.end method

.method writeExport(Landroid/net/Uri; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 move-object/from16 v1, v19
  0004 move-object/from16 v0, v21
  0008 const-string v2, "kind"
  000c const-string v3, "patchKey"
  0010 new-instance v4, Ljava/io/File;
  0014 invoke-virtual/range v19, Lcom/personal/aihub/CreatorActivity;->getCacheDir()Ljava/io/File;
  001a move-result-object v5
  001c new-instance v6, Ljava/lang/StringBuilder;
  0020 const-string v7, "forge-export-cpk-"
  0024 invoke-direct v6, v7, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  002a invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0030 move-result-object v7
  0032 invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0038 invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  003e move-result-object v6
  0040 invoke-direct v4, v5, v6, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0046 invoke-virtual v4, Ljava/io/File;->mkdirs()Z
  004c move-result v5
  004e if-eqz v5, +225h
  0052 new-instance v5, Ljava/io/File;
  0056 const-string v6, "prepared-export.bin"
  005a invoke-direct v5, v4, v6, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0060 new-instance v6, Ljava/io/FileOutputStream;
  0064 invoke-direct v6, v5, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  006a invoke-virtual v0, v3, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  0070 move-result v7
  0072 const-string v14, "name"
  0076 const-wide v12, 4294967296
  0080 if-eqz v7, +029h
  0084 new-instance v2, Ljava/io/FileInputStream;
  0088 invoke-virtual v0, v3, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  008e move-result-object v3
  0090 invoke-direct v1, v3, Lcom/personal/aihub/CreatorActivity;->patchFile(Ljava/lang/String;)Ljava/io/File;
  0096 move-result-object v3
  0098 invoke-direct v2, v3, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  009e invoke-static v2, v6, v12, v13, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  00a4 invoke-virtual v2, Ljava/io/FileInputStream;->close()V
  00aa move-object v11, v4
  00ac goto/16 +169h
  00b0 move-exception v0
  00b2 move-object v3, v0
  00b4 invoke-virtual v2, Ljava/io/FileInputStream;->close()V
  00ba goto +6h
  00bc move-exception v0
  00be move-object v2, v0
  00c0 invoke-virtual v3, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  00c6 throw v3
  00c8 move-exception v0
  00ca move-object v2, v0
  00cc move-object v11, v4
  00ce goto/16 +1d3h
  00d2 invoke-virtual v0, v2, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  00d8 move-result-object v3
  00da const-string v7, "eclp"
  00de invoke-virtual v3, v7, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00e4 move-result v3
  00e6 const-string v7, "path"
  00ea const/4 v8, 0
  00ec const-string v9, "entries"
  00f0 const-string v10, "text"
  00f4 if-eqz v3, +09eh
  00f8 invoke-virtual v0, v9, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  00fe move-result-object v2
  0100 new-instance v9, Ljava/util/ArrayList;
  0104 invoke-direct v9, Ljava/util/ArrayList;-><init>()V
  010a const-string v3, "metadata"
  010e invoke-virtual v0, v3, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0114 move-result-object v3
  0116 new-instance v11, Ljava/util/HashSet;
  011a invoke-direct v11, Ljava/util/HashSet;-><init>()V
  0120 invoke-virtual v2, Lorg/json/JSONArray;->length()I
  0126 move-result v15
  0128 if-ge v8, v15, +057h
  012c invoke-virtual v2, v8, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  0132 move-result-object v15
  0134 invoke-virtual v15, v7, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  013a move-result-object v12
  013c invoke-static v12, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  0142 move-result v13
  0144 if-eqz v13, +041h
  0148 invoke-virtual v11, v12, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  014e move-result v13
  0150 if-eqz v13, +03bh
  0154 const-string v13, "metadata.json"
  0158 invoke-virtual v12, v13, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  015e move-result v13
  0160 if-eqz v13, +00dh
  0164 if-nez v3, +00bh
  0168 new-instance v3, Lorg/json/JSONObject;
  016c invoke-virtual v15, v10, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0172 move-result-object v13
  0174 invoke-direct v3, v13, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  017a new-instance v13, Lcom/personal/aihub/EclpCodec$Entry;
  017e move-object/from16 v17, v2
  0182 invoke-direct v1, v15, v4, v8, Lcom/personal/aihub/CreatorActivity;->exportSource(Lorg/json/JSONObject; Ljava/io/File; I)Ljava/io/File;
  0188 move-result-object v2
  018a invoke-virtual v15, v10, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0190 move-result-object v15
  0192 move-object/from16 v18, v3
  0196 sget-object v3, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  019a invoke-virtual v15, v3, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  01a0 move-result-object v3
  01a2 invoke-direct v13, v12, v2, v3, Lcom/personal/aihub/EclpCodec$Entry;-><init>(Ljava/lang/String; Ljava/io/File; [B)V
  01a8 invoke-virtual v9, v13, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  01ae add-int/lit8 v8, v8, 1
  01b2 move-object/from16 v2, v17
  01b6 move-object/from16 v3, v18
  01ba const-wide v12, 4294967296
  01c4 goto -52h
  01c6 new-instance v0, Ljava/io/IOException;
  01ca const-string v2, "Unsafe or duplicate ECLP path."
  01ce invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01d4 throw v0
  01d6 if-eqz v3, +025h
  01da invoke-virtual/range v19, Lcom/personal/aihub/CreatorActivity;->getCacheDir()Ljava/io/File;
  01e0 move-result-object v8
  01e2 invoke-virtual v3, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  01e8 move-result-object v10
  01ea const-string v2, "uuid"
  01ee invoke-virtual v3, v2, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  01f4 move-result-object v11
  01f6 invoke-virtual v3, v14, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  01fc move-result-object v12
  01fe const-string v2, "version"
  0202 invoke-virtual v3, v2, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0208 move-result-object v13
  020a move-object v7, v6
  020c const-wide v2, 4294967296
  0216 invoke-static/range v7 ... v13, Lcom/personal/aihub/EclpCodec;->write(Ljava/io/OutputStream; Ljava/io/File; Ljava/util/List; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)V
  021c goto/16 -0b9h
  0220 new-instance v0, Ljava/io/IOException;
  0224 const-string v2, "Missing ECLP metadata"
  0228 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  022e throw v0
  0230 move-wide v11, v12
  0232 invoke-virtual v0, v2, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0238 move-result-object v2
  023a const-string v3, "zip"
  023e invoke-virtual v2, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0244 move-result v2
  0246 if-eqz v2, +08eh
  024a new-instance v2, Ljava/util/zip/ZipOutputStream;
  024e invoke-direct v2, v6, Ljava/util/zip/ZipOutputStream;-><init>(Ljava/io/OutputStream;)V
  0254 invoke-virtual v0, v9, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  025a move-result-object v3
  025c new-instance v9, Ljava/util/HashSet;
  0260 invoke-direct v9, Ljava/util/HashSet;-><init>()V
  0266 invoke-virtual v3, Lorg/json/JSONArray;->length()I
  026c move-result v13
  026e if-ge v8, v13, +068h
  0272 invoke-virtual v3, v8, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  0278 move-result-object v13
  027a invoke-virtual v13, v7, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0280 move-result-object v15
  0282 invoke-static v15, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  0288 move-result v16
  028a if-eqz v16, +04fh
  028e invoke-virtual v9, v15, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  0294 move-result v16
  0296 if-eqz v16, +049h
  029a invoke-direct v1, v13, v4, v8, Lcom/personal/aihub/CreatorActivity;->exportSource(Lorg/json/JSONObject; Ljava/io/File; I)Ljava/io/File;
  02a0 move-result-object v11
  02a2 new-instance v12, Ljava/util/zip/ZipEntry;
  02a6 invoke-direct v12, v15, Ljava/util/zip/ZipEntry;-><init>(Ljava/lang/String;)V
  02ac invoke-virtual v2, v12, Ljava/util/zip/ZipOutputStream;->putNextEntry(Ljava/util/zip/ZipEntry;)V
  02b2 if-eqz v11, +01fh
  02b6 new-instance v12, Ljava/io/FileInputStream;
  02ba invoke-direct v12, v11, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  02c0 move-object v15, v3
  02c2 move-object v11, v4
  02c4 const-wide/32 v3, 1073741824
  02ca invoke-static v12, v2, v3, v4, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  02d0 invoke-virtual v12, Ljava/io/FileInputStream;->close()V
  02d6 goto +1ch
  02d8 move-exception v0
  02da move-object v3, v0
  02dc invoke-virtual v12, Ljava/io/FileInputStream;->close()V
  02e2 goto +6h
  02e4 move-exception v0
  02e6 move-object v4, v0
  02e8 invoke-virtual v3, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  02ee throw v3
  02f0 move-object v15, v3
  02f2 move-object v11, v4
  02f4 invoke-virtual v13, v10, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  02fa move-result-object v3
  02fc sget-object v4, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0300 invoke-virtual v3, v4, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0306 move-result-object v3
  0308 invoke-virtual v2, v3, Ljava/util/zip/ZipOutputStream;->write([B)V
  030e invoke-virtual v2, Ljava/util/zip/ZipOutputStream;->closeEntry()V
  0314 add-int/lit8 v8, v8, 1
  0318 move-object v4, v11
  031a move-object v3, v15
  031c const-wide v11, 4294967296
  0326 goto -60h
  0328 move-object v11, v4
  032a new-instance v0, Ljava/io/IOException;
  032e const-string v3, "Invalid or duplicate patch path"
  0332 invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0338 throw v0
  033a move-exception v0
  033c goto +8h
  033e move-object v11, v4
  0340 invoke-virtual v2, Ljava/util/zip/ZipOutputStream;->close()V
  0346 goto +1ch
  0348 move-exception v0
  034a move-object v11, v4
  034c move-object v3, v0
  034e invoke-virtual v2, Ljava/util/zip/ZipOutputStream;->close()V
  0354 goto +6h
  0356 move-exception v0
  0358 move-object v2, v0
  035a invoke-virtual v3, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0360 throw v3
  0362 move-object v11, v4
  0364 invoke-virtual v0, v10, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  036a move-result-object v2
  036c sget-object v3, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0370 invoke-virtual v2, v3, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0376 move-result-object v2
  0378 invoke-virtual v6, v2, Ljava/io/FileOutputStream;->write([B)V
  037e invoke-virtual v6, Ljava/io/FileOutputStream;->close()V
  0384 invoke-virtual v5, Ljava/io/File;->length()J
  038a move-result-wide v2
  038c const-wide v6, 4294967296
  0396 cmp-long v2, v2, v6
  039a if-gtz v2, +060h
  039e new-instance v2, Ljava/io/FileInputStream;
  03a2 invoke-direct v2, v5, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  03a8 invoke-virtual/range v19, Lcom/personal/aihub/CreatorActivity;->getContentResolver()Landroid/content/ContentResolver;
  03ae move-result-object v3
  03b0 const-string v4, "w"
  03b4 move-object/from16 v5, v20
  03b8 invoke-virtual v3, v5, v4, Landroid/content/ContentResolver;->openOutputStream(Landroid/net/Uri; Ljava/lang/String;)Ljava/io/OutputStream;
  03be move-result-object v3
  03c0 if-eqz v3, +02dh
  03c4 const-wide v4, 4294967296
  03ce invoke-static v2, v3, v4, v5, Lcom/personal/aihub/CreatorActivity;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)V
  03d4 if-eqz v3, +005h
  03d8 invoke-virtual v3, Ljava/io/OutputStream;->close()V
  03de invoke-virtual v2, Ljava/io/FileInputStream;->close()V
  03e4 new-instance v2, Lorg/json/JSONObject;
  03e8 invoke-direct v2, Lorg/json/JSONObject;-><init>()V
  03ee const-string v3, "saved"
  03f2 const/4 v4, 1
  03f4 invoke-virtual v2, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  03fa move-result-object v2
  03fc invoke-virtual v0, v14, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0402 move-result-object v0
  0404 invoke-virtual v2, v14, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  040a move-result-object v0
  040c invoke-static v11, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  0412 return-object v0
  0414 move-exception v0
  0416 move-object v4, v0
  0418 goto +9h
  041a new-instance v0, Ljava/io/IOException;
  041e const-string v4, "Cannot write this destination."
  0422 invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0428 throw v0
  042a if-eqz v3, +00bh
  042e invoke-virtual v3, Ljava/io/OutputStream;->close()V
  0434 goto +6h
  0436 move-exception v0
  0438 move-object v3, v0
  043a invoke-virtual v4, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0440 throw v4
  0442 move-exception v0
  0444 move-object v3, v0
  0446 invoke-virtual v2, Ljava/io/FileInputStream;->close()V
  044c goto +6h
  044e move-exception v0
  0450 move-object v2, v0
  0452 invoke-virtual v3, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0458 throw v3
  045a new-instance v0, Ljava/io/IOException;
  045e const-string v2, "Export exceeds the 4 GB output limit."
  0462 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0468 throw v0
  046a move-exception v0
  046c goto +3h
  046e move-exception v0
  0470 move-object v11, v4
  0472 move-object v2, v0
  0474 invoke-virtual v6, Ljava/io/FileOutputStream;->close()V
  047a goto +6h
  047c move-exception v0
  047e move-object v3, v0
  0480 invoke-virtual v2, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0486 throw v2
  0488 move-exception v0
  048a goto +3h
  048c move-exception v0
  048e move-object v11, v4
  0490 invoke-static v11, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  0496 throw v0
  0498 new-instance v0, Ljava/io/IOException;
  049c const-string v2, "Cannot prepare artwork export."
  04a0 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  04a6 throw v0
.end method

.method writeText(Ljava/io/File; Ljava/lang/String;)V
  0000 invoke-virtual v1, Ljava/io/File;->getParentFile()Ljava/io/File;
  0006 move-result-object v0
  0008 if-eqz v0, +005h
  000c invoke-virtual v0, Ljava/io/File;->mkdirs()Z
  0012 new-instance v0, Ljava/io/FileOutputStream;
  0016 invoke-direct v0, v1, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  001c sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0020 invoke-virtual v2, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0026 move-result-object v1
  0028 invoke-virtual v0, v1, Ljava/io/FileOutputStream;->write([B)V
  002e invoke-virtual v0, Ljava/io/FileOutputStream;->close()V
  0034 return-void 
  0036 move-exception v1
  0038 invoke-virtual v0, Ljava/io/FileOutputStream;->close()V
  003e goto +5h
  0040 move-exception v2
  0042 invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0048 throw v1
.end method

.method assetFile(Ljava/lang/String;)Ljava/io/File;
  0000 invoke-static v4, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  0006 move-result v0
  0008 if-eqz v0, +037h
  000c new-instance v0, Ljava/io/File;
  0010 iget-object v1, v3, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  0014 invoke-direct v0, v1, v4, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  001a invoke-virtual v0, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  0020 move-result-object v4
  0022 new-instance v1, Ljava/lang/StringBuilder;
  0026 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  002c iget-object v2, v3, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  0030 invoke-virtual v2, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  0036 move-result-object v2
  0038 invoke-static v2, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  003e move-result-object v2
  0040 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0046 sget-object v2, Ljava/io/File;->separator Ljava/lang/String;
  004a invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0050 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0056 move-result-object v1
  0058 invoke-virtual v4, v1, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  005e move-result v4
  0060 if-eqz v4, +003h
  0064 return-object v0
  0066 new-instance v4, Ljava/io/IOException;
  006a const-string v0, "Unsafe path"
  006e invoke-direct v4, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0074 throw v4
  0076 new-instance v4, Ljava/io/IOException;
  007a const-string v0, "Invalid asset key"
  007e invoke-direct v4, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0084 throw v4
.end method

.method dispatch(Ljava/lang/String; Lorg/json/JSONObject;)Ljava/lang/Object;
  0000 iget-object v0, v6, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0004 invoke-static v0, v7, v8, Lcom/personal/aihub/ForgeFixes;->dispatch(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONObject;)Ljava/lang/Object;
  000a move-result-object v0
  000c if-eqz v0, +003h
  0010 return-object v0
  0012 const-string v0, "aiCompose"
  0016 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  001c move-result v0
  001e if-eqz v0, +007h
  0022 invoke-static v6, v8, Lcom/personal/aihub/AiHandoff;->compose(Landroid/app/Activity; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0028 move-result-object v7
  002a return-object v7
  002c const-string v0, "openEclipse"
  0030 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0036 move-result v0
  0038 const/4 v1, 0
  003a const/4 v2, 1
  003c if-eqz v0, +039h
  0040 invoke-virtual v6, Lcom/personal/aihub/CreatorActivity;->getPackageManager()Landroid/content/pm/PackageManager;
  0046 move-result-object v7
  0048 const-string v8, "com.anthen.eclipse"
  004c invoke-virtual v7, v8, Landroid/content/pm/PackageManager;->getLaunchIntentForPackage(Ljava/lang/String;)Landroid/content/Intent;
  0052 move-result-object v7
  0054 if-eqz v7, +003h
  0058 move v1, v2
  005a if-eqz v1, +003h
  005e goto +eh
  0060 new-instance v7, Landroid/content/Intent;
  0064 const-string v8, "android.intent.action.VIEW"
  0068 const-string v0, "https://dokkan-eclipse.com/downloads"
  006c invoke-static v0, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  0072 move-result-object v0
  0074 invoke-direct v7, v8, v0, Landroid/content/Intent;-><init>(Ljava/lang/String; Landroid/net/Uri;)V
  007a new-instance v8, Lcom/personal/aihub/CreatorActivity$$ExternalSyntheticLambda2;
  007e invoke-direct v8, v6, v7, Lcom/personal/aihub/CreatorActivity$$ExternalSyntheticLambda2;-><init>(Lcom/personal/aihub/CreatorActivity; Landroid/content/Intent;)V
  0084 invoke-virtual v6, v8, Lcom/personal/aihub/CreatorActivity;->runOnUiThread(Ljava/lang/Runnable;)V
  008a new-instance v7, Lorg/json/JSONObject;
  008e invoke-direct v7, Lorg/json/JSONObject;-><init>()V
  0094 const-string v8, "requested"
  0098 invoke-virtual v7, v8, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  009e move-result-object v7
  00a0 const-string v8, "installed"
  00a4 invoke-virtual v7, v8, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  00aa move-result-object v7
  00ac return-object v7
  00ae const-string v0, "sparkingInfo"
  00b2 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00b8 move-result v0
  00ba if-eqz v0, +007h
  00be invoke-direct v6, Lcom/personal/aihub/CreatorActivity;->sparkingInfo()Lorg/json/JSONObject;
  00c4 move-result-object v7
  00c6 return-object v7
  00c8 const-string v0, "animationFiles"
  00cc invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00d2 move-result v0
  00d4 if-eqz v0, +015h
  00d8 const-string v0, "sparking"
  00dc const-string v3, "sourceDatabase"
  00e0 invoke-virtual v8, v3, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  00e6 move-result-object v3
  00e8 invoke-virtual v0, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00ee move-result v0
  00f0 if-eqz v0, +007h
  00f4 invoke-direct v6, Lcom/personal/aihub/CreatorActivity;->sparkingAnimationFiles()Lorg/json/JSONArray;
  00fa move-result-object v7
  00fc return-object v7
  00fe const-string v0, "updateSparking"
  0102 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0108 move-result v0
  010a if-eqz v0, +007h
  010e invoke-direct v6, Lcom/personal/aihub/CreatorActivity;->updateSparking()Lorg/json/JSONObject;
  0114 move-result-object v7
  0116 return-object v7
  0118 const-string v0, "downloadSparkingAssets"
  011c invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0122 move-result v0
  0124 if-eqz v0, +007h
  0128 invoke-direct v6, v8, Lcom/personal/aihub/CreatorActivity;->downloadSparkingAssets(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  012e move-result-object v7
  0130 return-object v7
  0132 const-string v0, "sparkingAudioCatalog"
  0136 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  013c move-result v0
  013e const/4 v3, 0
  0140 const/high16 v4, 33554432
  0144 if-eqz v0, +045h
  0148 const-string v7, "version"
  014c invoke-virtual v8, v7, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  0152 move-result v7
  0154 if-eqz v7, +008h
  0158 const-string v7, "version"
  015c invoke-virtual v8, v7, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  0162 move-result-object v3
  0164 invoke-static v3, Lcom/personal/aihub/PreviewMetadata;->normalizeVersion(Ljava/lang/Object;)J
  016a move-result-wide v7
  016c const-wide/16 v0, 0
  0170 cmp-long v0, v7, v0
  0174 if-lez v0, +025h
  0178 invoke-direct v6, v7, v8, Lcom/personal/aihub/CreatorActivity;->sparkingAssetManifest(J)Ljava/io/File;
  017e move-result-object v0
  0180 new-instance v1, Lorg/json/JSONObject;
  0184 invoke-static v0, v4, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  018a move-result-object v0
  018c invoke-direct v1, v0, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0192 new-instance v0, Lorg/json/JSONObject;
  0196 invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  019c const-string v2, "version"
  01a0 invoke-virtual v0, v2, v7, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  01a6 move-result-object v7
  01a8 const-string v8, "files"
  01ac invoke-static v1, Lcom/personal/aihub/SparkingContent;->audioRecords(Lorg/json/JSONObject;)Lorg/json/JSONArray;
  01b2 move-result-object v0
  01b4 invoke-virtual v7, v8, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01ba move-result-object v7
  01bc return-object v7
  01be new-instance v7, Ljava/io/IOException;
  01c2 const-string v8, "Choose a recorded Sparking content version before preparing its audio."
  01c6 invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01cc throw v7
  01ce const-string v0, "findSparkingAssets"
  01d2 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01d8 move-result v0
  01da if-eqz v0, +092h
  01de const-string v7, "version"
  01e2 const-wide/16 v2, -1
  01e6 invoke-virtual v8, v7, v2, v3, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  01ec move-result-wide v2
  01ee invoke-direct v6, v2, v3, Lcom/personal/aihub/CreatorActivity;->sparkingAssetManifest(J)Ljava/io/File;
  01f4 move-result-object v7
  01f6 new-instance v0, Lorg/json/JSONObject;
  01fa invoke-static v7, v4, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  0200 move-result-object v7
  0202 invoke-direct v0, v7, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0208 new-instance v7, Ljava/util/HashSet;
  020c invoke-direct v7, Ljava/util/HashSet;-><init>()V
  0212 const-string v2, "assets"
  0216 invoke-virtual v0, v2, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  021c move-result-object v0
  021e move v2, v1
  0220 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  0226 move-result v3
  0228 if-ge v2, v3, +012h
  022c invoke-virtual v0, v2, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  0232 move-result-object v3
  0234 const-string v4, "file_path"
  0238 invoke-virtual v3, v4, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  023e move-result-object v3
  0240 invoke-virtual v7, v3, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  0246 add-int/lit8 v2, v2, 1
  024a goto -15h
  024c const-string v0, "paths"
  0250 invoke-virtual v8, v0, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0256 move-result-object v8
  0258 new-instance v0, Lorg/json/JSONArray;
  025c invoke-direct v0, Lorg/json/JSONArray;-><init>()V
  0262 new-instance v2, Lorg/json/JSONArray;
  0266 invoke-direct v2, Lorg/json/JSONArray;-><init>()V
  026c invoke-virtual v8, Lorg/json/JSONArray;->length()I
  0272 move-result v3
  0274 const/16 v4, 128
  0278 if-gt v3, v4, +03bh
  027c invoke-virtual v8, Lorg/json/JSONArray;->length()I
  0282 move-result v3
  0284 if-ge v1, v3, +023h
  0288 invoke-virtual v8, v1, Lorg/json/JSONArray;->getString(I)Ljava/lang/String;
  028e move-result-object v3
  0290 invoke-static v3, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  0296 move-result v4
  0298 if-eqz v4, +011h
  029c invoke-virtual v7, v3, Ljava/util/HashSet;->contains(Ljava/lang/Object;)Z
  02a2 move-result v4
  02a4 if-eqz v4, +004h
  02a8 move-object v4, v0
  02aa goto +2h
  02ac move-object v4, v2
  02ae invoke-virtual v4, v3, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  02b4 add-int/lit8 v1, v1, 1
  02b8 goto -1eh
  02ba new-instance v7, Ljava/io/IOException;
  02be const-string v8, "Invalid resource path."
  02c2 invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02c8 throw v7
  02ca new-instance v7, Lorg/json/JSONObject;
  02ce invoke-direct v7, Lorg/json/JSONObject;-><init>()V
  02d4 const-string v8, "available"
  02d8 invoke-virtual v7, v8, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02de move-result-object v7
  02e0 const-string v8, "missing"
  02e4 invoke-virtual v7, v8, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02ea move-result-object v7
  02ec return-object v7
  02ee new-instance v7, Ljava/io/IOException;
  02f2 const-string v8, "Choose fewer game resources at a time."
  02f6 invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02fc throw v7
  02fe const-string v0, "querySparking"
  0302 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0308 move-result v0
  030a if-eqz v0, +00eh
  030e invoke-direct v6, Lcom/personal/aihub/CreatorActivity;->ensureSparkingDb()V
  0314 iget-object v7, v6, Lcom/personal/aihub/CreatorActivity;->sparkingDb Landroid/database/sqlite/SQLiteDatabase;
  0318 iget-object v0, v6, Lcom/personal/aihub/CreatorActivity;->sparkingSchema Lorg/json/JSONObject;
  031c invoke-direct v6, v7, v0, v8, Lcom/personal/aihub/CreatorActivity;->queryDatabase(Landroid/database/sqlite/SQLiteDatabase; Lorg/json/JSONObject; Lorg/json/JSONObject;)Lorg/json/JSONArray;
  0322 move-result-object v7
  0324 return-object v7
  0326 const-string v0, "listProjectVersions"
  032a invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0330 move-result v0
  0332 if-nez v0, +3b1h
  0336 const-string v0, "saveProjectVersion"
  033a invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0340 move-result v0
  0342 if-nez v0, +3a9h
  0346 const-string v0, "loadProjectVersion"
  034a invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0350 move-result v0
  0352 if-nez v0, +3a1h
  0356 const-string v0, "restoreProjectVersion"
  035a invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0360 move-result v0
  0362 if-eqz v0, +004h
  0366 goto/16 +397h
  036a const-string v0, "storeDecoration"
  036e invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0374 move-result v0
  0376 if-eqz v0, +009h
  037a iget-object v7, v6, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  037e invoke-static v7, v8, Lcom/personal/aihub/DecorationStorage;->store(Ljava/io/File; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0384 move-result-object v7
  0386 return-object v7
  0388 const-string v0, "assetStatus"
  038c invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0392 move-result v0
  0394 if-eqz v0, +00fh
  0398 iget-object v7, v6, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  039c const-string v0, "keys"
  03a0 invoke-virtual v8, v0, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  03a6 move-result-object v8
  03a8 invoke-static v7, v8, Lcom/personal/aihub/ExportAssetAudit;->check(Ljava/io/File; Lorg/json/JSONArray;)Lorg/json/JSONArray;
  03ae move-result-object v7
  03b0 return-object v7
  03b2 invoke-virtual v7, Ljava/lang/String;->hashCode()I
  03b8 move-result v0
  03ba sparse-switch v0, +00003b5h
  03c0 goto/16 +356h
  03c4 const-string v0, "animationSource"
  03c8 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  03ce move-result v0
  03d0 if-eqz v0, +34eh
  03d4 const-string v7, "sparking"
  03d8 const-string v0, "sourceDatabase"
  03dc invoke-virtual v8, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  03e2 move-result-object v0
  03e4 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  03ea move-result v7
  03ec if-eqz v7, +013h
  03f0 const-string v7, "path"
  03f4 invoke-virtual v8, v7, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  03fa move-result-object v7
  03fc const-string v0, "assetKey"
  0400 invoke-virtual v8, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0406 move-result-object v8
  0408 invoke-direct v6, v7, v8, Lcom/personal/aihub/CreatorActivity;->sparkingAnimationSource(Ljava/lang/String; Ljava/lang/String;)Lorg/json/JSONObject;
  040e move-result-object v7
  0410 return-object v7
  0412 const-string v7, "path"
  0416 invoke-virtual v8, v7, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  041c move-result-object v7
  041e const-string v0, "assetKey"
  0422 invoke-virtual v8, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0428 move-result-object v0
  042a const-string v2, "originalOnly"
  042e invoke-virtual v8, v2, v1, Lorg/json/JSONObject;->optBoolean(Ljava/lang/String; Z)Z
  0434 move-result v8
  0436 invoke-direct v6, v7, v0, v8, Lcom/personal/aihub/CreatorActivity;->animationSource(Ljava/lang/String; Ljava/lang/String; Z)Lorg/json/JSONObject;
  043c move-result-object v7
  043e return-object v7
  0440 const-string v0, "storeLwf"
  0444 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  044a move-result v0
  044c if-eqz v0, +310h
  0450 iget-object v7, v6, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  0454 invoke-static v7, v8, Lcom/personal/aihub/LwfStorage;->store(Ljava/io/File; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  045a move-result-object v7
  045c return-object v7
  045e const-string v0, "animationCatalog"
  0462 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0468 move-result v0
  046a if-eqz v0, +301h
  046e invoke-direct v6, v8, Lcom/personal/aihub/CreatorActivity;->animationCatalog(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0474 move-result-object v7
  0476 return-object v7
  0478 const-string v0, "animationVisuals"
  047c invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0482 move-result v0
  0484 if-eqz v0, +2f4h
  0488 const-string v7, "unitId"
  048c invoke-virtual v8, v7, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  0492 move-result-wide v7
  0494 invoke-direct v6, v7, v8, Lcom/personal/aihub/CreatorActivity;->animationVisuals(J)Lorg/json/JSONObject;
  049a move-result-object v7
  049c return-object v7
  049e const-string v0, "convert"
  04a2 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  04a8 move-result v0
  04aa if-eqz v0, +2e1h
  04ae invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  04b4 move-result-object v7
  04b6 invoke-virtual v7, Ljava/util/UUID;->toString()Ljava/lang/String;
  04bc move-result-object v7
  04be new-instance v0, Ljava/io/File;
  04c2 new-instance v1, Ljava/io/File;
  04c6 invoke-virtual v6, Lcom/personal/aihub/CreatorActivity;->getCacheDir()Ljava/io/File;
  04cc move-result-object v3
  04ce const-string v4, "converter"
  04d2 invoke-direct v1, v3, v4, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  04d8 invoke-direct v0, v1, v7, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  04de invoke-virtual v0, Ljava/io/File;->mkdirs()Z
  04e4 new-instance v1, Ljava/io/File;
  04e8 const-string v3, "unit-patch.zip"
  04ec invoke-direct v1, v0, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  04f2 new-instance v3, Lorg/json/JSONObject;
  04f6 invoke-virtual v8, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  04fc move-result-object v4
  04fe invoke-direct v3, v4, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0504 const-string v4, "kind"
  0508 const-string v5, "zip"
  050c invoke-virtual v3, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0512 invoke-static v1, Landroid/net/Uri;->fromFile(Ljava/io/File;)Landroid/net/Uri;
  0518 move-result-object v1
  051a invoke-direct v6, v1, v3, Lcom/personal/aihub/CreatorActivity;->writeExport(Landroid/net/Uri; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0520 const-string v1, "patch"
  0524 invoke-virtual v8, v1, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  052a move-result-object v8
  052c invoke-virtual v8, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0532 move-result-object v8
  0534 new-instance v1, Lcom/personal/aihub/CreatorActivity$7;
  0538 invoke-direct v1, v6, v7, v8, Lcom/personal/aihub/CreatorActivity$7;-><init>(Lcom/personal/aihub/CreatorActivity; Ljava/lang/String; Ljava/lang/String;)V
  053e invoke-virtual v6, v1, Lcom/personal/aihub/CreatorActivity;->runOnUiThread(Ljava/lang/Runnable;)V
  0544 new-instance v7, Lorg/json/JSONObject;
  0548 invoke-direct v7, Lorg/json/JSONObject;-><init>()V
  054e const-string v8, "opened"
  0552 invoke-virtual v7, v8, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0558 move-result-object v7
  055a return-object v7
  055c move-exception v7
  055e invoke-static v0, Lcom/personal/aihub/CreatorActivity;->deleteTree(Ljava/io/File;)V
  0564 throw v7
  0566 const-string v0, "storeMovie"
  056a invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0570 move-result v0
  0572 if-eqz v0, +27dh
  0576 iget-object v7, v6, Lcom/personal/aihub/CreatorActivity;->movieUploads Lcom/personal/aihub/MovieStorage;
  057a if-nez v7, +00fh
  057e new-instance v7, Lcom/personal/aihub/MovieStorage;
  0582 iget-object v0, v6, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  0586 invoke-virtual v0, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  058c move-result-object v0
  058e invoke-direct v7, v0, Lcom/personal/aihub/MovieStorage;-><init>(Ljava/io/File;)V
  0594 iput-object v7, v6, Lcom/personal/aihub/CreatorActivity;->movieUploads Lcom/personal/aihub/MovieStorage;
  0598 iget-object v7, v6, Lcom/personal/aihub/CreatorActivity;->movieUploads Lcom/personal/aihub/MovieStorage;
  059c invoke-virtual v7, v8, Lcom/personal/aihub/MovieStorage;->call(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  05a2 move-result-object v7
  05a4 return-object v7
  05a6 const-string v0, "storeAsset"
  05aa invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  05b0 move-result v0
  05b2 if-eqz v0, +25dh
  05b6 new-instance v7, Lcom/personal/aihub/ImageAssets;
  05ba iget-object v0, v6, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  05be invoke-direct v7, v0, Lcom/personal/aihub/ImageAssets;-><init>(Ljava/io/File;)V
  05c4 invoke-virtual v7, v8, Lcom/personal/aihub/ImageAssets;->store(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  05ca move-result-object v7
  05cc return-object v7
  05ce const-string v0, "saveProject"
  05d2 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  05d8 move-result v0
  05da if-eqz v0, +249h
  05de const-string v7, "project"
  05e2 invoke-virtual v8, v7, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  05e8 move-result-object v7
  05ea invoke-direct v6, v7, Lcom/personal/aihub/CreatorActivity;->saveProject(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  05f0 move-result-object v7
  05f2 return-object v7
  05f4 const-string v0, "browseAssets"
  05f8 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  05fe move-result v0
  0600 if-eqz v0, +236h
  0604 const-string v7, "path"
  0608 invoke-virtual v8, v7, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  060e move-result-object v7
  0610 invoke-virtual v7, Ljava/lang/String;->isEmpty()Z
  0616 move-result v8
  0618 if-nez v8, +011h
  061c invoke-static v7, Lcom/personal/aihub/CreatorActivity;->safePath(Ljava/lang/String;)Z
  0622 move-result v8
  0624 if-eqz v8, +003h
  0628 goto +9h
  062a new-instance v7, Ljava/io/IOException;
  062e const-string v8, "Invalid resource path"
  0632 invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0638 throw v7
  063a new-instance v8, Lorg/json/JSONObject;
  063e new-instance v0, Ljava/lang/StringBuilder;
  0642 const-string v1, "https://dokkan-eclipse.com/api/file-browser?path="
  0646 invoke-direct v0, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  064c invoke-static v7, Landroid/net/Uri;->encode(Ljava/lang/String;)Ljava/lang/String;
  0652 move-result-object v7
  0654 invoke-virtual v0, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  065a invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0660 move-result-object v7
  0662 const/high16 v0, 8388608
  0666 invoke-direct v6, v7, v0, Lcom/personal/aihub/CreatorActivity;->fetchText(Ljava/lang/String; I)Ljava/lang/String;
  066c move-result-object v7
  066e invoke-direct v8, v7, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0674 return-object v8
  0676 const-string v8, "restoreDatabase"
  067a invoke-virtual v7, v8, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0680 move-result v8
  0682 if-eqz v8, +1f5h
  0686 invoke-direct v6, Lcom/personal/aihub/CreatorActivity;->restoreDatabase()Lorg/json/JSONObject;
  068c move-result-object v7
  068e return-object v7
  0690 const-string v0, "query"
  0694 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  069a move-result v0
  069c if-eqz v0, +1e8h
  06a0 invoke-direct v6, v8, Lcom/personal/aihub/CreatorActivity;->query(Lorg/json/JSONObject;)Lorg/json/JSONArray;
  06a6 move-result-object v7
  06a8 return-object v7
  06aa const-string v0, "downloadAsset"
  06ae invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  06b4 move-result v0
  06b6 if-eqz v0, +1dbh
  06ba const-string v7, "path"
  06be invoke-virtual v8, v7, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  06c4 move-result-object v7
  06c6 const-string v0, "group"
  06ca invoke-virtual v8, v0, v3, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  06d0 move-result-object v8
  06d2 invoke-direct v6, v7, v8, Lcom/personal/aihub/CreatorActivity;->downloadAsset(Ljava/lang/String; Ljava/lang/String;)Lorg/json/JSONObject;
  06d8 move-result-object v7
  06da return-object v7
  06dc const-string v8, "sync"
  06e0 invoke-virtual v7, v8, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  06e6 move-result v8
  06e8 if-eqz v8, +1c2h
  06ec invoke-direct v6, Lcom/personal/aihub/CreatorActivity;->syncDatabase()Lorg/json/JSONObject;
  06f2 move-result-object v7
  06f4 return-object v7
  06f6 const-string v8, "info"
  06fa invoke-virtual v7, v8, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0700 move-result v8
  0702 if-eqz v8, +1b5h
  0706 invoke-direct v6, Lcom/personal/aihub/CreatorActivity;->info()Lorg/json/JSONObject;
  070c move-result-object v7
  070e return-object v7
  0710 const-string v0, "copy"
  0714 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  071a move-result v0
  071c if-eqz v0, +1a8h
  0720 const-string v7, "text"
  0724 invoke-virtual v8, v7, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  072a move-result-object v7
  072c new-instance v8, Lcom/personal/aihub/CreatorActivity$6;
  0730 invoke-direct v8, v6, v7, Lcom/personal/aihub/CreatorActivity$6;-><init>(Lcom/personal/aihub/CreatorActivity; Ljava/lang/String;)V
  0736 invoke-virtual v6, v8, Lcom/personal/aihub/CreatorActivity;->runOnUiThread(Ljava/lang/Runnable;)V
  073c new-instance v7, Lorg/json/JSONObject;
  0740 invoke-direct v7, Lorg/json/JSONObject;-><init>()V
  0746 const-string v8, "copied"
  074a invoke-virtual v7, v8, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0750 move-result-object v7
  0752 return-object v7
  0754 const-string v8, "ai"
  0758 invoke-virtual v7, v8, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  075e move-result v8
  0760 if-eqz v8, +186h
  0764 new-instance v7, Lcom/personal/aihub/CreatorActivity$5;
  0768 invoke-direct v7, v6, Lcom/personal/aihub/CreatorActivity$5;-><init>(Lcom/personal/aihub/CreatorActivity;)V
  076e invoke-virtual v6, v7, Lcom/personal/aihub/CreatorActivity;->runOnUiThread(Ljava/lang/Runnable;)V
  0774 new-instance v7, Lorg/json/JSONObject;
  0778 invoke-direct v7, Lorg/json/JSONObject;-><init>()V
  077e const-string v8, "opened"
  0782 invoke-virtual v7, v8, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0788 move-result-object v7
  078a return-object v7
  078c const-string v0, "previewAnimation"
  0790 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0796 move-result v0
  0798 if-eqz v0, +16ah
  079c invoke-direct v6, v8, Lcom/personal/aihub/CreatorActivity;->previewAnimation(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  07a2 move-result-object v7
  07a4 return-object v7
  07a6 const-string v0, "assetUrl"
  07aa invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  07b0 move-result v0
  07b2 if-eqz v0, +15dh
  07b6 new-instance v7, Ljava/lang/StringBuilder;
  07ba const-string v0, "https://forge.local/local-asset/"
  07be invoke-direct v7, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  07c4 const-string v0, "key"
  07c8 invoke-virtual v8, v0, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  07ce move-result-object v8
  07d0 const-string v0, "/"
  07d4 invoke-static v8, v0, Landroid/net/Uri;->encode(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  07da move-result-object v8
  07dc invoke-virtual v7, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  07e2 invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  07e8 move-result-object v7
  07ea return-object v7
  07ec const-string v8, "patches"
  07f0 invoke-virtual v7, v8, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  07f6 move-result v8
  07f8 if-eqz v8, +13ah
  07fc invoke-direct v6, Lcom/personal/aihub/CreatorActivity;->listPatches()Lorg/json/JSONArray;
  0802 move-result-object v7
  0804 return-object v7
  0806 const-string v0, "loadProject"
  080a invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0810 move-result v0
  0812 if-eqz v0, +12dh
  0816 new-instance v7, Lorg/json/JSONObject;
  081a const-string v0, "key"
  081e invoke-virtual v8, v0, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0824 move-result-object v8
  0826 invoke-direct v6, v8, Lcom/personal/aihub/CreatorActivity;->projectFile(Ljava/lang/String;)Ljava/io/File;
  082c move-result-object v8
  082e const/high16 v0, 20971520
  0832 invoke-static v8, v0, Lcom/personal/aihub/CreatorActivity;->readText(Ljava/io/File; I)Ljava/lang/String;
  0838 move-result-object v8
  083a invoke-direct v7, v8, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0840 return-object v7
  0842 const-string v8, "projects"
  0846 invoke-virtual v7, v8, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  084c move-result v8
  084e if-eqz v8, +10fh
  0852 invoke-direct v6, Lcom/personal/aihub/CreatorActivity;->listProjects()Lorg/json/JSONArray;
  0858 move-result-object v7
  085a return-object v7
  085c const-string v0, "readAsset"
  0860 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0866 move-result v0
  0868 if-eqz v0, +102h
  086c new-instance v7, Lcom/personal/aihub/ImageAssets;
  0870 iget-object v0, v6, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  0874 invoke-direct v7, v0, Lcom/personal/aihub/ImageAssets;-><init>(Ljava/io/File;)V
  087a invoke-virtual v7, v8, Lcom/personal/aihub/ImageAssets;->read(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0880 move-result-object v7
  0882 return-object v7
  0884 const-string v0, "previewTools"
  0888 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  088e move-result v0
  0890 if-eqz v0, +0eeh
  0894 new-instance v7, Lcom/personal/aihub/PreviewTools;
  0898 new-instance v0, Ljava/io/File;
  089c invoke-virtual v6, Lcom/personal/aihub/CreatorActivity;->getFilesDir()Ljava/io/File;
  08a2 move-result-object v1
  08a4 const-string v2, "forge"
  08a8 invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  08ae invoke-direct v7, v6, v0, Lcom/personal/aihub/PreviewTools;-><init>(Landroid/content/Context; Ljava/io/File;)V
  08b4 invoke-virtual v7, v8, Lcom/personal/aihub/PreviewTools;->request(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  08ba move-result-object v7
  08bc return-object v7
  08be const-string v0, "previewCache"
  08c2 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  08c8 move-result v0
  08ca if-eqz v0, +0d1h
  08ce new-instance v7, Lcom/personal/aihub/PreviewCache;
  08d2 new-instance v0, Ljava/io/File;
  08d6 invoke-virtual v6, Lcom/personal/aihub/CreatorActivity;->getFilesDir()Ljava/io/File;
  08dc move-result-object v1
  08de const-string v2, "forge"
  08e2 invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  08e8 invoke-direct v7, v0, Lcom/personal/aihub/PreviewCache;-><init>(Ljava/io/File;)V
  08ee invoke-virtual v7, v8, Lcom/personal/aihub/PreviewCache;->settings(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  08f4 move-result-object v7
  08f6 return-object v7
  08f8 const-string v0, "assets"
  08fc invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0902 move-result v0
  0904 if-eqz v0, +0b4h
  0908 iget-object v7, v6, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  090c invoke-static v7, v8, Lcom/personal/aihub/AssetIndex;->list(Ljava/io/File; Lorg/json/JSONObject;)Lorg/json/JSONArray;
  0912 move-result-object v7
  0914 return-object v7
  0916 const-string v0, "animationFiles"
  091a invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0920 move-result v0
  0922 if-eqz v0, +0a5h
  0926 const-string v7, "refresh"
  092a invoke-virtual v8, v7, Lorg/json/JSONObject;->optBoolean(Ljava/lang/String;)Z
  0930 move-result v7
  0932 invoke-direct v6, v7, Lcom/personal/aihub/CreatorActivity;->animationFiles(Z)Lorg/json/JSONArray;
  0938 move-result-object v7
  093a return-object v7
  093c const-string v0, "external"
  0940 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0946 move-result v0
  0948 if-eqz v0, +092h
  094c const-string v7, "target"
  0950 invoke-virtual v8, v7, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0956 move-result-object v7
  0958 const-string v0, "converter"
  095c invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0962 move-result v0
  0964 if-eqz v0, +005h
  0968 const-string v7, "https://dokkan-eclipse.com/#convert-eclp"
  096c goto +51h
  096e const-string v0, "documentation"
  0972 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0978 move-result v0
  097a if-eqz v0, +005h
  097e const-string v7, "https://dokkan-eclipse.com/wiki/documentation"
  0982 goto +46h
  0984 const-string v0, "downloads"
  0988 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  098e move-result v0
  0990 if-eqz v0, +005h
  0994 const-string v7, "https://dokkan-eclipse.com/downloads"
  0998 goto +3bh
  099a const-string v0, "files"
  099e invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  09a4 move-result v0
  09a6 if-eqz v0, +005h
  09aa const-string v7, "https://dokkan-eclipse.com/files"
  09ae goto +30h
  09b0 const-string v0, "sparkingLicense"
  09b4 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  09ba move-result v0
  09bc if-eqz v0, +005h
  09c0 const-string v7, "https://creativecommons.org/licenses/by-sa/4.0/"
  09c4 goto +25h
  09c6 const-string v0, "sparkingWiki"
  09ca invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  09d0 move-result v7
  09d2 if-eqz v7, +03ah
  09d6 const-string v7, "revision"
  09da invoke-virtual v8, v7, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  09e0 move-result-object v7
  09e2 const-string v8, "[1-9][0-9]{0,14}"
  09e6 invoke-virtual v7, v8, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  09ec move-result v8
  09ee if-eqz v8, +024h
  09f2 new-instance v8, Ljava/lang/StringBuilder;
  09f6 const-string v0, "https://dokkansparking.miraheze.org/w/index.php?oldid="
  09fa invoke-direct v8, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0a00 invoke-virtual v8, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0a06 invoke-virtual v8, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0a0c move-result-object v7
  0a0e new-instance v8, Lcom/personal/aihub/CreatorActivity$4;
  0a12 invoke-direct v8, v6, v7, Lcom/personal/aihub/CreatorActivity$4;-><init>(Lcom/personal/aihub/CreatorActivity; Ljava/lang/String;)V
  0a18 invoke-virtual v6, v8, Lcom/personal/aihub/CreatorActivity;->runOnUiThread(Ljava/lang/Runnable;)V
  0a1e new-instance v7, Lorg/json/JSONObject;
  0a22 invoke-direct v7, Lorg/json/JSONObject;-><init>()V
  0a28 const-string v8, "opened"
  0a2c invoke-virtual v7, v8, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0a32 move-result-object v7
  0a34 return-object v7
  0a36 new-instance v7, Ljava/io/IOException;
  0a3a const-string v8, "Invalid wiki revision"
  0a3e invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0a44 throw v7
  0a46 new-instance v7, Ljava/io/IOException;
  0a4a const-string v8, "Unknown destination"
  0a4e invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0a54 throw v7
  0a56 const-string v8, "importStatus"
  0a5a invoke-virtual v7, v8, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0a60 move-result v8
  0a62 if-eqz v8, +005h
  0a66 iget-object v7, v6, Lcom/personal/aihub/CreatorActivity;->importProgress Lorg/json/JSONObject;
  0a6a return-object v7
  0a6c new-instance v8, Ljava/io/IOException;
  0a70 new-instance v0, Ljava/lang/StringBuilder;
  0a74 const-string v1, "Unsupported action: "
  0a78 invoke-direct v0, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0a7e invoke-virtual v0, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0a84 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0a8a move-result-object v7
  0a8c invoke-direct v8, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0a92 throw v8
  0a94 sget-object v0, Lcom/personal/aihub/CreatorActivity;->PROJECT_WRITES Ljava/lang/Object;
  0a98 monitor-enter v0
  0a9a const-string v1, "key"
  0a9e invoke-virtual v8, v1, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0aa4 move-result-object v1
  0aa6 new-instance v2, Lcom/personal/aihub/ProjectVersions;
  0aaa iget-object v3, v6, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0aae invoke-direct v6, v1, Lcom/personal/aihub/CreatorActivity;->projectFile(Ljava/lang/String;)Ljava/io/File;
  0ab4 move-result-object v4
  0ab6 invoke-direct v2, v3, v4, v1, Lcom/personal/aihub/ProjectVersions;-><init>(Ljava/io/File; Ljava/io/File; Ljava/lang/String;)V
  0abc const-string v1, "listProjectVersions"
  0ac0 invoke-virtual v7, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0ac6 move-result v1
  0ac8 if-eqz v1, +008h
  0acc invoke-virtual v2, Lcom/personal/aihub/ProjectVersions;->list()Lorg/json/JSONObject;
  0ad2 move-result-object v7
  0ad4 monitor-exit v0
  0ad6 return-object v7
  0ad8 const-string v1, "saveProjectVersion"
  0adc invoke-virtual v7, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0ae2 move-result v1
  0ae4 if-eqz v1, +008h
  0ae8 invoke-virtual v2, v8, Lcom/personal/aihub/ProjectVersions;->save(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0aee move-result-object v7
  0af0 monitor-exit v0
  0af2 return-object v7
  0af4 const-string v1, "loadProjectVersion"
  0af8 invoke-virtual v7, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0afe move-result v7
  0b00 if-eqz v7, +008h
  0b04 invoke-virtual v2, v8, Lcom/personal/aihub/ProjectVersions;->load(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0b0a move-result-object v7
  0b0c monitor-exit v0
  0b0e return-object v7
  0b10 invoke-virtual v2, v8, Lcom/personal/aihub/ProjectVersions;->restore(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0b16 move-result-object v7
  0b18 monitor-exit v0
  0b1a return-object v7
  0b1c move-exception v7
  0b1e monitor-exit v0
  0b20 throw v7
  0b22 nop 
  0b24 sparse-switch-payload -7a29e009 -6c869c35 -57a6bead -53ef8c7d -52cc0766 -51d5ed0d -4404d106 -3b86e786 -310010ad -2f2ec50a -163ec3a1 -113be764 c28 2eaf75 3164ae 361a9b 3f4748 66f18c8 6f1da29 15f276ad 16baeadc 354c668f 35f3bacf 38b81db3 45dba10f 4b239ff5 66597b9a 7956bcbf
.end method

.method lambda$dispatch$0$com-personal-aihub-CreatorActivity(Landroid/content/Intent;)V
  0000 invoke-virtual v1, Lcom/personal/aihub/CreatorActivity;->isFinishing()Z
  0006 move-result v0
  0008 if-nez v0, +017h
  000c invoke-virtual v1, Lcom/personal/aihub/CreatorActivity;->isDestroyed()Z
  0012 move-result v0
  0014 if-eqz v0, +003h
  0018 goto +fh
  001a invoke-virtual v1, v2, Lcom/personal/aihub/CreatorActivity;->startActivity(Landroid/content/Intent;)V
  0020 goto +bh
  0022 const-string v2, "Could not open Eclipse. Open it from your device's app list."
  0026 const/4 v0, 1
  0028 invoke-static v1, v2, v0, Landroid/widget/Toast;->makeText(Landroid/content/Context; Ljava/lang/CharSequence; I)Landroid/widget/Toast;
  002e move-result-object v2
  0030 invoke-virtual v2, Landroid/widget/Toast;->show()V
  0036 return-void 
.end method

.method lambda$downloadSparkingAssets$5$com-personal-aihub-CreatorActivity(Ljava/lang/String; J J)V
  0000 const-string v1, "download"
  0004 const-string v2, "Downloading Sparking game resources"
  0008 move-object v0, v7
  000a move-wide v3, v9
  000c move-wide v5, v11
  000e invoke-direct/range v0 ... v6, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  0014 return-void 
.end method

.method lambda$sparkingAnimationSource$2$com-personal-aihub-CreatorActivity(Ljava/lang/String; J J)V
  0000 const-string v1, "download"
  0004 const-string v2, "Downloading the original Sparking animation"
  0008 move-object v0, v7
  000a move-wide v3, v9
  000c move-wide v5, v11
  000e invoke-direct/range v0 ... v6, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  0014 return-void 
.end method

.method lambda$sparkingAssetManifest$4$com-personal-aihub-CreatorActivity(Ljava/lang/String; J J)V
  0000 const-string v1, "manifest"
  0004 const-string v2, "Opening Sparking resources"
  0008 move-object v0, v7
  000a move-wide v3, v9
  000c move-wide v5, v11
  000e invoke-direct/range v0 ... v6, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  0014 return-void 
.end method

.method lambda$sparkingBaseScripts$1$com-personal-aihub-CreatorActivity(Ljava/lang/String; J J)V
  0000 const-string v1, "download"
  0004 const-string v2, "Preparing Sparking's original animation collection"
  0008 move-object v0, v7
  000a move-wide v3, v9
  000c move-wide v5, v11
  000e invoke-direct/range v0 ... v6, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  0014 return-void 
.end method

.method lambda$updateSparking$3$com-personal-aihub-CreatorActivity(Ljava/lang/String; J J)V
  0000 const-string v0, "manifest"
  0004 invoke-virtual v9, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  000a move-result v0
  000c if-eqz v0, +005h
  0010 const-string v0, "Reading Sparking's game-content list"
  0014 goto +3h
  0016 const-string v0, "Downloading Sparking characters"
  001a move-object v3, v0
  001c move-object v1, v8
  001e move-object v2, v9
  0020 move-wide v4, v10
  0022 move-wide v6, v12
  0024 invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  002a return-void 
.end method

.method m10lambda$11$compersonalaihubCreatorActivity()V
  0000 iget-object v0, v2, Lcom/personal/aihub/CreatorActivity;->sparkingDb Landroid/database/sqlite/SQLiteDatabase;
  0004 const/4 v1, 0
  0006 if-eqz v0, +007h
  000a invoke-virtual v0, Landroid/database/sqlite/SQLiteDatabase;->close()V
  0010 iput-object v1, v2, Lcom/personal/aihub/CreatorActivity;->sparkingDb Landroid/database/sqlite/SQLiteDatabase;
  0014 iget-object v0, v2, Lcom/personal/aihub/CreatorActivity;->db Landroid/database/sqlite/SQLiteDatabase;
  0018 if-eqz v0, +007h
  001c invoke-virtual v0, Landroid/database/sqlite/SQLiteDatabase;->close()V
  0022 iput-object v1, v2, Lcom/personal/aihub/CreatorActivity;->db Landroid/database/sqlite/SQLiteDatabase;
  0026 return-void 
.end method

.method m11lambda$2$compersonalaihubCreatorActivity(I Ljava/lang/Exception; Ljava/lang/Object;)V
  0000 const-string v0, "ForgeBridge"
  0004 const-string v1, "window.__forgeReplyParts=window.__forgeReplyParts||{};window.__forgeReplyParts["
  0008 const-string v2, "window.__forgeReply("
  000c const-string v3, "Reply "
  0010 iget-object v4, v8, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  0014 if-eqz v4, +10fh
  0018 invoke-virtual v8, Lcom/personal/aihub/CreatorActivity;->isFinishing()Z
  001e move-result v4
  0020 if-nez v4, +109h
  0024 invoke-virtual v8, Lcom/personal/aihub/CreatorActivity;->isDestroyed()Z
  002a move-result v4
  002c if-eqz v4, +004h
  0030 goto/16 +101h
  0034 new-instance v4, Lorg/json/JSONObject;
  0038 invoke-direct v4, Lorg/json/JSONObject;-><init>()V
  003e const-string v5, "id"
  0042 invoke-virtual v4, v5, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0048 const-string v5, "ok"
  004c const/4 v6, 0
  004e if-nez v10, +004h
  0052 const/4 v7, 1
  0054 goto +2h
  0056 move v7, v6
  0058 invoke-virtual v4, v5, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  005e if-nez v10, +00ch
  0062 if-nez v11, +004h
  0066 sget-object v11, Lorg/json/JSONObject;->NULL Ljava/lang/Object;
  006a const-string v10, "result"
  006e invoke-virtual v4, v10, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0074 goto +13h
  0076 const-string v11, "error"
  007a invoke-virtual v10, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  0080 move-result-object v5
  0082 if-nez v5, +005h
  0086 const-string v10, "The operation failed."
  008a goto +5h
  008c invoke-virtual v10, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  0092 move-result-object v10
  0094 invoke-virtual v4, v11, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  009a invoke-virtual v4, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  00a0 move-result-object v10
  00a2 new-instance v11, Ljava/lang/StringBuilder;
  00a6 invoke-direct v11, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00ac invoke-virtual v11, v9, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  00b2 const-string v3, " chars="
  00b6 invoke-virtual v11, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00bc invoke-virtual v10, Ljava/lang/String;->length()I
  00c2 move-result v3
  00c4 invoke-virtual v11, v3, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  00ca invoke-virtual v11, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00d0 move-result-object v11
  00d2 invoke-static v0, v11, Landroid/util/Log;->d(Ljava/lang/String; Ljava/lang/String;)I
  00d8 invoke-virtual v10, Ljava/lang/String;->length()I
  00de move-result v11
  00e0 const-string v3, ")"
  00e4 const/16 v4, 24000
  00e8 const/4 v5, 0
  00ea if-ge v11, v4, +017h
  00ee iget-object v11, v8, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  00f2 new-instance v1, Ljava/lang/StringBuilder;
  00f6 invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00fc invoke-virtual v1, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0102 invoke-virtual v1, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0108 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  010e move-result-object v10
  0110 invoke-virtual v11, v10, v5, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String; Landroid/webkit/ValueCallback;)V
  0116 return-void 
  0118 invoke-static v9, Ljava/lang/String;->valueOf(I)Ljava/lang/String;
  011e move-result-object v11
  0120 iget-object v2, v8, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  0124 new-instance v4, Ljava/lang/StringBuilder;
  0128 invoke-direct v4, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  012e invoke-virtual v4, v11, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0134 const-string v1, "]=[]"
  0138 invoke-virtual v4, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  013e invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0144 move-result-object v1
  0146 invoke-virtual v2, v1, v5, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String; Landroid/webkit/ValueCallback;)V
  014c invoke-virtual v10, Ljava/lang/String;->length()I
  0152 move-result v1
  0154 if-ge v6, v1, +04bh
  0158 add-int/lit16 v1, v6, 24000
  015c invoke-virtual v10, Ljava/lang/String;->length()I
  0162 move-result v2
  0164 invoke-static v1, v2, Ljava/lang/Math;->min(I I)I
  016a move-result v1
  016c invoke-virtual v10, Ljava/lang/String;->length()I
  0172 move-result v2
  0174 if-ge v1, v2, +010h
  0178 add-int/lit8 v2, v1, -1
  017c invoke-virtual v10, v2, Ljava/lang/String;->charAt(I)C
  0182 move-result v2
  0184 invoke-static v2, Ljava/lang/Character;->isHighSurrogate(C)Z
  018a move-result v2
  018c if-eqz v2, +004h
  0190 add-int/lit8 v1, v1, -1
  0194 iget-object v2, v8, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  0198 new-instance v4, Ljava/lang/StringBuilder;
  019c invoke-direct v4, Ljava/lang/StringBuilder;-><init>()V
  01a2 const-string v7, "window.__forgeReplyParts["
  01a6 invoke-virtual v4, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01ac invoke-virtual v4, v11, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01b2 const-string v7, "].push("
  01b6 invoke-virtual v4, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01bc invoke-virtual v10, v6, v1, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  01c2 move-result-object v6
  01c4 invoke-static v6, Lorg/json/JSONObject;->quote(Ljava/lang/String;)Ljava/lang/String;
  01ca move-result-object v6
  01cc invoke-virtual v4, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01d2 invoke-virtual v4, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01d8 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01de move-result-object v4
  01e0 invoke-virtual v2, v4, v5, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String; Landroid/webkit/ValueCallback;)V
  01e6 move v6, v1
  01e8 goto -4eh
  01ea iget-object v10, v8, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  01ee new-instance v1, Ljava/lang/StringBuilder;
  01f2 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  01f8 const-string v2, "window.__forgeReply(JSON.parse(window.__forgeReplyParts["
  01fc invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0202 invoke-virtual v1, v11, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0208 const-string v2, "].join('')));delete window.__forgeReplyParts["
  020c invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0212 invoke-virtual v1, v11, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0218 const-string v11, "]"
  021c invoke-virtual v1, v11, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0222 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0228 move-result-object v11
  022a invoke-virtual v10, v11, v5, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String; Landroid/webkit/ValueCallback;)V
  0230 goto +24h
  0232 return-void 
  0234 move-exception v10
  0236 new-instance v11, Ljava/lang/StringBuilder;
  023a const-string v1, "Could not deliver reply "
  023e invoke-direct v11, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0244 invoke-virtual v11, v9, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  024a const-string v9, ": "
  024e invoke-virtual v11, v9, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0254 invoke-virtual v10, Ljava/lang/Object;->getClass()Ljava/lang/Class;
  025a move-result-object v9
  025c invoke-virtual v9, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;
  0262 move-result-object v9
  0264 invoke-virtual v11, v9, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  026a invoke-virtual v11, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0270 move-result-object v9
  0272 invoke-static v0, v9, Landroid/util/Log;->e(Ljava/lang/String; Ljava/lang/String;)I
  0278 return-void 
.end method

.method m12lambda$3$compersonalaihubCreatorActivity(Ljava/lang/String; Ljava/lang/String;)V
  0000 new-instance v0, Landroid/content/Intent;
  0004 const-class v1, Lcom/personal/aihub/ConverterActivity;
  0008 invoke-direct v0, v2, v1, Landroid/content/Intent;-><init>(Landroid/content/Context; Ljava/lang/Class;)V
  000e const-string v1, "token"
  0012 invoke-virtual v0, v1, v3, Landroid/content/Intent;->putExtra(Ljava/lang/String; Ljava/lang/String;)Landroid/content/Intent;
  0018 move-result-object v3
  001a const-string v0, "patch"
  001e invoke-virtual v3, v0, v4, Landroid/content/Intent;->putExtra(Ljava/lang/String; Ljava/lang/String;)Landroid/content/Intent;
  0024 move-result-object v3
  0026 invoke-virtual v2, v3, Lcom/personal/aihub/CreatorActivity;->startActivity(Landroid/content/Intent;)V
  002c return-void 
.end method

.method m13lambda$4$compersonalaihubCreatorActivity()V
  0000 new-instance v0, Landroid/content/Intent;
  0004 const-class v1, Lcom/personal/aihub/MainActivity;
  0008 invoke-direct v0, v2, v1, Landroid/content/Intent;-><init>(Landroid/content/Context; Ljava/lang/Class;)V
  000e invoke-virtual v2, v0, Lcom/personal/aihub/CreatorActivity;->startActivity(Landroid/content/Intent;)V
  0014 return-void 
.end method

.method m14lambda$5$compersonalaihubCreatorActivity(Ljava/lang/String;)V
  0000 const-string v0, "clipboard"
  0004 invoke-virtual v2, v0, Lcom/personal/aihub/CreatorActivity;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;
  000a move-result-object v0
  000c check-cast v0, Landroid/content/ClipboardManager;
  0010 const-string v1, "Dokkan unit design"
  0014 invoke-static v1, v3, Landroid/content/ClipData;->newPlainText(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Landroid/content/ClipData;
  001a move-result-object v3
  001c invoke-virtual v0, v3, Landroid/content/ClipboardManager;->setPrimaryClip(Landroid/content/ClipData;)V
  0022 return-void 
.end method

.method m15lambda$6$compersonalaihubCreatorActivity(Ljava/lang/String;)V
  0000 new-instance v0, Landroid/content/Intent;
  0004 const-string v1, "android.intent.action.VIEW"
  0008 invoke-static v3, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  000e move-result-object v3
  0010 invoke-direct v0, v1, v3, Landroid/content/Intent;-><init>(Ljava/lang/String; Landroid/net/Uri;)V
  0016 invoke-virtual v2, v0, Lcom/personal/aihub/CreatorActivity;->startActivity(Landroid/content/Intent;)V
  001c return-void 
.end method

.method m16lambda$7$compersonalaihubCreatorActivity(Ljava/lang/String;)V
  0000 invoke-static v2, v3, Lcom/personal/aihub/ForgeFixes;->openPreview(Landroid/app/Activity; Ljava/lang/String;)Z
  0006 move-result v0
  0008 if-eqz v0, +003h
  000c return-void 
  000e new-instance v0, Landroid/content/Intent;
  0012 const-class v1, Lcom/personal/aihub/PreviewActivity;
  0016 invoke-direct v0, v2, v1, Landroid/content/Intent;-><init>(Landroid/content/Context; Ljava/lang/Class;)V
  001c const-string v1, "token"
  0020 invoke-virtual v0, v1, v3, Landroid/content/Intent;->putExtra(Ljava/lang/String; Ljava/lang/String;)Landroid/content/Intent;
  0026 move-result-object v3
  0028 invoke-virtual v2, v3, Lcom/personal/aihub/CreatorActivity;->startActivity(Landroid/content/Intent;)V
  002e return-void 
.end method

.method m17lambda$8$compersonalaihubCreatorActivity(I Landroid/net/Uri; Lorg/json/JSONObject; Ljava/lang/String; I)V
  0000 const/16 v0, 502
  0004 const/4 v1, 0
  0006 if-ne v3, v0, +007h
  000a invoke-direct v2, v4, v5, Lcom/personal/aihub/CreatorActivity;->writeExport(Landroid/net/Uri; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0010 move-result-object v3
  0012 goto +bh
  0014 const-string v3, "importApk"
  0018 invoke-virtual v6, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  001e move-result v3
  0020 invoke-direct v2, v4, v3, Lcom/personal/aihub/CreatorActivity;->importUri(Landroid/net/Uri; Z)Lorg/json/JSONObject;
  0026 move-result-object v3
  0028 invoke-virtual v2, v7, v3, v1, Lcom/personal/aihub/CreatorActivity;->reply(I Ljava/lang/Object; Ljava/lang/Exception;)V
  002e goto +5h
  0030 move-exception v3
  0032 invoke-virtual v2, v7, v1, v3, Lcom/personal/aihub/CreatorActivity;->reply(I Ljava/lang/Object; Ljava/lang/Exception;)V
  0038 return-void 
.end method

.method m8lambda$0$compersonalaihubCreatorActivity()V
  0000 new-instance v0, Lcom/personal/aihub/MovieStorage;
  0004 iget-object v1, v2, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  0008 invoke-virtual v1, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  000e move-result-object v1
  0010 invoke-direct v0, v1, Lcom/personal/aihub/MovieStorage;-><init>(Ljava/io/File;)V
  0016 iput-object v0, v2, Lcom/personal/aihub/CreatorActivity;->movieUploads Lcom/personal/aihub/MovieStorage;
  001a goto +4h
  001c const/4 v0, 0
  001e iput-object v0, v2, Lcom/personal/aihub/CreatorActivity;->movieUploads Lcom/personal/aihub/MovieStorage;
  0022 return-void 
.end method

.method m9lambda$10$compersonalaihubCreatorActivity(Ljava/lang/String;)V
  0000 const-string v0, "true"
  0004 invoke-virtual v0, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  000a move-result v2
  000c if-eqz v2, +003h
  0010 return-void 
  0012 invoke-virtual v1, Lcom/personal/aihub/CreatorActivity;->finish()V
  0018 return-void 
.end method

.method onActivityResult(I I Landroid/content/Intent;)V
  0000 invoke-super v8, v9, v10, v11, Landroid/app/Activity;->onActivityResult(I I Landroid/content/Intent;)V
  0006 invoke-static v8, v9, v10, v11, Lcom/personal/aihub/ForgeFixes;->activityResult(Landroid/app/Activity; I I Landroid/content/Intent;)V
  000c const/16 v0, 501
  0010 if-eq v9, v0, +006h
  0014 const/16 v0, 502
  0018 if-ne v9, v0, +036h
  001c iget v7, v8, Lcom/personal/aihub/CreatorActivity;->pendingId I
  0020 iget-object v6, v8, Lcom/personal/aihub/CreatorActivity;->pendingMethod Ljava/lang/String;
  0024 iget-object v5, v8, Lcom/personal/aihub/CreatorActivity;->pendingExport Lorg/json/JSONObject;
  0028 const/4 v0, -1
  002a iput v0, v8, Lcom/personal/aihub/CreatorActivity;->pendingId I
  002e const/4 v1, 0
  0030 iput-object v1, v8, Lcom/personal/aihub/CreatorActivity;->pendingExport Lorg/json/JSONObject;
  0034 if-gez v7, +003h
  0038 return-void 
  003a if-ne v10, v0, +01dh
  003e if-eqz v11, +01bh
  0042 invoke-virtual v11, Landroid/content/Intent;->getData()Landroid/net/Uri;
  0048 move-result-object v10
  004a if-nez v10, +003h
  004e goto +13h
  0050 invoke-virtual v11, Landroid/content/Intent;->getData()Landroid/net/Uri;
  0056 move-result-object v4
  0058 iget-object v10, v8, Lcom/personal/aihub/CreatorActivity;->worker Ljava/util/concurrent/ExecutorService;
  005c new-instance v11, Lcom/personal/aihub/CreatorActivity$9;
  0060 move-object v1, v11
  0062 move-object v2, v8
  0064 move v3, v9
  0066 invoke-direct/range v1 ... v7, Lcom/personal/aihub/CreatorActivity$9;-><init>(Lcom/personal/aihub/CreatorActivity; I Landroid/net/Uri; Lorg/json/JSONObject; Ljava/lang/String; I)V
  006c invoke-interface v10, v11, Ljava/util/concurrent/ExecutorService;->execute(Ljava/lang/Runnable;)V
  0072 goto +9h
  0074 new-instance v9, Lorg/json/JSONObject;
  0078 invoke-direct v9, Lorg/json/JSONObject;-><init>()V
  007e invoke-virtual v8, v7, v9, v1, Lcom/personal/aihub/CreatorActivity;->reply(I Ljava/lang/Object; Ljava/lang/Exception;)V
  0084 return-void 
.end method

.method onBackPressed()V
  0000 iget-object v0, v3, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  0004 if-eqz v0, +01ah
  0008 iget-object v0, v3, Lcom/personal/aihub/CreatorActivity;->startup Lcom/personal/aihub/WebViewStartup;
  000c if-eqz v0, +009h
  0010 invoke-virtual v0, Lcom/personal/aihub/WebViewStartup;->controlsReady()Z
  0016 move-result v0
  0018 if-nez v0, +003h
  001c goto +eh
  001e iget-object v0, v3, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  0022 new-instance v1, Lcom/personal/aihub/CreatorActivity$11;
  0026 invoke-direct v1, v3, Lcom/personal/aihub/CreatorActivity$11;-><init>(Lcom/personal/aihub/CreatorActivity;)V
  002c const-string v2, "Boolean(window.forgeHandleBack && window.forgeHandleBack())"
  0030 invoke-virtual v0, v2, v1, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String; Landroid/webkit/ValueCallback;)V
  0036 goto +4h
  0038 invoke-virtual v3, Lcom/personal/aihub/CreatorActivity;->finish()V
  003e return-void 
.end method

.method onCreate(Landroid/os/Bundle;)V
  0000 invoke-super v6, v7, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V
  0006 new-instance v7, Ljava/io/File;
  000a invoke-virtual v6, Lcom/personal/aihub/CreatorActivity;->getFilesDir()Ljava/io/File;
  0010 move-result-object v0
  0012 const-string v1, "forge"
  0016 invoke-direct v7, v0, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  001c iput-object v7, v6, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0020 new-instance v7, Ljava/io/File;
  0024 iget-object v0, v6, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  0028 const-string v1, "assets"
  002c invoke-direct v7, v0, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0032 iput-object v7, v6, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  0036 new-instance v7, Ljava/io/File;
  003a iget-object v0, v6, Lcom/personal/aihub/CreatorActivity;->root Ljava/io/File;
  003e const-string v1, "projects"
  0042 invoke-direct v7, v0, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0048 iput-object v7, v6, Lcom/personal/aihub/CreatorActivity;->projects Ljava/io/File;
  004c iget-object v7, v6, Lcom/personal/aihub/CreatorActivity;->assets Ljava/io/File;
  0050 invoke-virtual v7, Ljava/io/File;->mkdirs()Z
  0056 iget-object v7, v6, Lcom/personal/aihub/CreatorActivity;->projects Ljava/io/File;
  005a invoke-virtual v7, Ljava/io/File;->mkdirs()Z
  0060 iget-object v7, v6, Lcom/personal/aihub/CreatorActivity;->worker Ljava/util/concurrent/ExecutorService;
  0064 new-instance v0, Lcom/personal/aihub/CreatorActivity$1;
  0068 invoke-direct v0, v6, Lcom/personal/aihub/CreatorActivity$1;-><init>(Lcom/personal/aihub/CreatorActivity;)V
  006e invoke-interface v7, v0, Ljava/util/concurrent/ExecutorService;->execute(Ljava/lang/Runnable;)V
  0074 new-instance v7, Landroid/widget/FrameLayout;
  0078 invoke-direct v7, v6, Landroid/widget/FrameLayout;-><init>(Landroid/content/Context;)V
  007e const v0, -15657702
  0084 invoke-virtual v7, v0, Landroid/widget/FrameLayout;->setBackgroundColor(I)V
  008a invoke-virtual v6, v7, Lcom/personal/aihub/CreatorActivity;->setContentView(Landroid/view/View;)V
  0090 sget v1, Landroid/os/Build$VERSION;->SDK_INT I
  0094 const/16 v2, 30
  0098 const/4 v3, 0
  009a if-lt v1, v2, +011h
  009e invoke-virtual v6, Lcom/personal/aihub/CreatorActivity;->getWindow()Landroid/view/Window;
  00a4 move-result-object v1
  00a6 invoke-virtual v1, v3, Landroid/view/Window;->setDecorFitsSystemWindows(Z)V
  00ac new-instance v1, Lcom/personal/aihub/CreatorActivity$2;
  00b0 invoke-direct v1, v6, Lcom/personal/aihub/CreatorActivity$2;-><init>(Lcom/personal/aihub/CreatorActivity;)V
  00b6 invoke-virtual v7, v1, Landroid/widget/FrameLayout;->setOnApplyWindowInsetsListener(Landroid/view/View$OnApplyWindowInsetsListener;)V
  00bc new-instance v1, Landroid/webkit/WebView;
  00c0 invoke-direct v1, v6, Landroid/webkit/WebView;-><init>(Landroid/content/Context;)V
  00c6 iput-object v1, v6, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  00ca const/4 v2, 0
  00cc const/4 v4, 1
  00ce invoke-static v6, v1, Lcom/personal/aihub/ForgeFixes;->configureWebView(Landroid/content/Context; Landroid/webkit/WebView;)V
  00d4 iget-object v1, v6, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  00d8 new-instance v2, Landroid/widget/FrameLayout$LayoutParams;
  00dc const/4 v5, -1
  00de invoke-direct v2, v5, v5, Landroid/widget/FrameLayout$LayoutParams;-><init>(I I)V
  00e4 invoke-virtual v7, v1, v2, Landroid/widget/FrameLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  00ea iget-object v1, v6, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  00ee invoke-virtual v1, Landroid/webkit/WebView;->getSettings()Landroid/webkit/WebSettings;
  00f4 move-result-object v1
  00f6 invoke-virtual v1, v4, Landroid/webkit/WebSettings;->setJavaScriptEnabled(Z)V
  00fc invoke-virtual v1, v4, Landroid/webkit/WebSettings;->setDomStorageEnabled(Z)V
  0102 invoke-virtual v1, v3, Landroid/webkit/WebSettings;->setAllowFileAccess(Z)V
  0108 invoke-virtual v1, v3, Landroid/webkit/WebSettings;->setAllowContentAccess(Z)V
  010e invoke-virtual v1, v4, Landroid/webkit/WebSettings;->setMixedContentMode(I)V
  0114 iget-object v1, v6, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  0118 invoke-virtual v1, v0, Landroid/webkit/WebView;->setBackgroundColor(I)V
  011e iget-object v0, v6, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  0122 new-instance v1, Lcom/personal/aihub/CreatorActivity$Bridge;
  0126 invoke-direct v1, v6, Lcom/personal/aihub/CreatorActivity$Bridge;-><init>(Lcom/personal/aihub/CreatorActivity;)V
  012c const-string v2, "ForgeAndroid"
  0130 invoke-virtual v0, v1, v2, Landroid/webkit/WebView;->addJavascriptInterface(Ljava/lang/Object; Ljava/lang/String;)V
  0136 iget-object v0, v6, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  013a new-instance v1, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;
  013e invoke-direct v1, v6, Lcom/personal/aihub/CreatorActivity$AnonymousClass1;-><init>(Lcom/personal/aihub/CreatorActivity;)V
  0144 invoke-virtual v0, v1, Landroid/webkit/WebView;->setWebViewClient(Landroid/webkit/WebViewClient;)V
  014a new-instance v0, Lcom/personal/aihub/WebViewStartup;
  014e new-instance v1, Lcom/personal/aihub/CreatorActivity$$ExternalSyntheticLambda3;
  0152 invoke-direct v1, v6, Lcom/personal/aihub/CreatorActivity$$ExternalSyntheticLambda3;-><init>(Lcom/personal/aihub/CreatorActivity;)V
  0158 const-string v2, "your workspace"
  015c invoke-direct v0, v6, v7, v2, v1, Lcom/personal/aihub/WebViewStartup;-><init>(Landroid/app/Activity; Landroid/widget/FrameLayout; Ljava/lang/String; Ljava/lang/Runnable;)V
  0162 iput-object v0, v6, Lcom/personal/aihub/CreatorActivity;->startup Lcom/personal/aihub/WebViewStartup;
  0166 iget-object v7, v6, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  016a invoke-virtual v0, v7, Lcom/personal/aihub/WebViewStartup;->begin(Landroid/webkit/WebView;)J
  0170 iget-object v7, v6, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  0174 const-string v0, "https://forge.local/index.html"
  0178 invoke-virtual v7, v0, Landroid/webkit/WebView;->loadUrl(Ljava/lang/String;)V
  017e return-void 
.end method

.method onDestroy()V
  0000 iget-object v0, v2, Lcom/personal/aihub/CreatorActivity;->startup Lcom/personal/aihub/WebViewStartup;
  0004 if-eqz v0, +005h
  0008 invoke-virtual v0, Lcom/personal/aihub/WebViewStartup;->close()V
  000e iget-object v0, v2, Lcom/personal/aihub/CreatorActivity;->worker Ljava/util/concurrent/ExecutorService;
  0012 new-instance v1, Lcom/personal/aihub/CreatorActivity$12;
  0016 invoke-direct v1, v2, Lcom/personal/aihub/CreatorActivity$12;-><init>(Lcom/personal/aihub/CreatorActivity;)V
  001c invoke-interface v0, v1, Ljava/util/concurrent/ExecutorService;->execute(Ljava/lang/Runnable;)V
  0022 iget-object v0, v2, Lcom/personal/aihub/CreatorActivity;->worker Ljava/util/concurrent/ExecutorService;
  0026 invoke-interface v0, Ljava/util/concurrent/ExecutorService;->shutdown()V
  002c iget-object v0, v2, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  0030 if-eqz v0, +00fh
  0034 const-string v1, "ForgeAndroid"
  0038 invoke-virtual v0, v1, Landroid/webkit/WebView;->removeJavascriptInterface(Ljava/lang/String;)V
  003e iget-object v0, v2, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  0042 invoke-virtual v0, Landroid/webkit/WebView;->destroy()V
  0048 const/4 v0, 0
  004a iput-object v0, v2, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  004e invoke-super v2, Landroid/app/Activity;->onDestroy()V
  0054 return-void 
.end method

.method onPause()V
  0000 invoke-super v3, Landroid/app/Activity;->onPause()V
  0006 iget-object v0, v3, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  000a if-eqz v0, +014h
  000e iget-object v0, v3, Lcom/personal/aihub/CreatorActivity;->startup Lcom/personal/aihub/WebViewStartup;
  0012 if-eqz v0, +008h
  0016 invoke-virtual v0, Lcom/personal/aihub/WebViewStartup;->controlsReady()Z
  001c move-result v0
  001e if-eqz v0, +00ah
  0022 iget-object v0, v3, Lcom/personal/aihub/CreatorActivity;->web Landroid/webkit/WebView;
  0026 const-string v1, "window.forgePersist && window.forgePersist()"
  002a const/4 v2, 0
  002c invoke-virtual v0, v1, v2, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String; Landroid/webkit/ValueCallback;)V
  0032 return-void 
.end method

.method pick(I Ljava/lang/String; Lorg/json/JSONObject;)V
  0000 iget v0, v11, Lcom/personal/aihub/CreatorActivity;->pendingId I
  0004 const/4 v1, 0
  0006 const/4 v2, -1
  0008 if-eq v0, v2, +00dh
  000c new-instance v13, Ljava/io/IOException;
  0010 const-string v14, "Finish the existing file picker first."
  0014 invoke-direct v13, v14, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  001a invoke-virtual v11, v12, v1, v13, Lcom/personal/aihub/CreatorActivity;->reply(I Ljava/lang/Object; Ljava/lang/Exception;)V
  0020 return-void 
  0022 iput v12, v11, Lcom/personal/aihub/CreatorActivity;->pendingId I
  0026 iput-object v13, v11, Lcom/personal/aihub/CreatorActivity;->pendingMethod Ljava/lang/String;
  002a const-string v0, "export"
  002e invoke-virtual v13, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0034 move-result v3
  0036 if-eqz v3, +004h
  003a move-object v3, v14
  003c goto +2h
  003e move-object v3, v1
  0040 iput-object v3, v11, Lcom/personal/aihub/CreatorActivity;->pendingExport Lorg/json/JSONObject;
  0044 invoke-virtual v13, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  004a move-result v3
  004c if-nez v3, +01ah
  0050 const-string v3, "importApk"
  0054 invoke-virtual v13, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  005a move-result v3
  005c if-eqz v3, +005h
  0060 const-string v3, "Choose the latest Eclipse APK"
  0064 goto +3h
  0066 const-string v3, "Choose a file to import"
  006a move-object v6, v3
  006c const-wide/16 v7, 0
  0070 const-wide/16 v9, 0
  0074 const-string v5, "select"
  0078 move-object v4, v11
  007a invoke-direct/range v4 ... v10, Lcom/personal/aihub/CreatorActivity;->progress(Ljava/lang/String; Ljava/lang/String; J J)V
  0080 new-instance v3, Landroid/content/Intent;
  0084 invoke-virtual v13, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  008a move-result v4
  008c if-eqz v4, +005h
  0090 const-string v4, "android.intent.action.CREATE_DOCUMENT"
  0094 goto +3h
  0096 const-string v4, "android.intent.action.OPEN_DOCUMENT"
  009a invoke-direct v3, v4, Landroid/content/Intent;-><init>(Ljava/lang/String;)V
  00a0 const-string v4, "android.intent.category.OPENABLE"
  00a4 invoke-virtual v3, v4, Landroid/content/Intent;->addCategory(Ljava/lang/String;)Landroid/content/Intent;
  00aa invoke-virtual v13, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00b0 move-result v4
  00b2 if-eqz v4, +016h
  00b6 const-string v4, "kind"
  00ba invoke-virtual v14, v4, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  00c0 move-result-object v4
  00c2 const-string v5, "zip"
  00c6 invoke-virtual v4, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00cc move-result v4
  00ce if-eqz v4, +005h
  00d2 const-string v4, "application/zip"
  00d6 goto +6h
  00d8 const-string v4, "application/octet-stream"
  00dc goto +3h
  00de const-string v4, "*/*"
  00e2 invoke-virtual v3, v4, Landroid/content/Intent;->setType(Ljava/lang/String;)Landroid/content/Intent;
  00e8 invoke-virtual v13, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00ee move-result v4
  00f0 if-eqz v4, +00fh
  00f4 const-string v4, "name"
  00f8 const-string v5, "custom-unit.json"
  00fc invoke-virtual v14, v4, v5, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0102 move-result-object v14
  0104 const-string v4, "android.intent.extra.TITLE"
  0108 invoke-virtual v3, v4, v14, Landroid/content/Intent;->putExtra(Ljava/lang/String; Ljava/lang/String;)Landroid/content/Intent;
  010e invoke-virtual v13, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0114 move-result v13
  0116 if-eqz v13, +005h
  011a const/16 v13, 502
  011e goto +3h
  0120 const/16 v13, 501
  0124 invoke-virtual v11, v3, v13, Lcom/personal/aihub/CreatorActivity;->startActivityForResult(Landroid/content/Intent; I)V
  012a goto +9h
  012c move-exception v13
  012e iput v2, v11, Lcom/personal/aihub/CreatorActivity;->pendingId I
  0132 iput-object v1, v11, Lcom/personal/aihub/CreatorActivity;->pendingExport Lorg/json/JSONObject;
  0136 invoke-virtual v11, v12, v1, v13, Lcom/personal/aihub/CreatorActivity;->reply(I Ljava/lang/Object; Ljava/lang/Exception;)V
  013c return-void 
.end method

.method reply(I Ljava/lang/Object; Ljava/lang/Exception;)V
  0000 new-instance v0, Lcom/personal/aihub/CreatorActivity$3;
  0004 invoke-direct v0, v1, v2, v4, v3, Lcom/personal/aihub/CreatorActivity$3;-><init>(Lcom/personal/aihub/CreatorActivity; I Ljava/lang/Exception; Ljava/lang/Object;)V
  000a invoke-virtual v1, v0, Lcom/personal/aihub/CreatorActivity;->runOnUiThread(Ljava/lang/Runnable;)V
  0010 return-void 
.end method