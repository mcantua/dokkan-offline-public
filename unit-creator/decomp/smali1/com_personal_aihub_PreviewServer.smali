.class Lcom/personal/aihub/PreviewServer;
.super Ljava/lang/Object;
.field MAX_MOVIE J
.field MAX_PREPARED J
.field audioBanks Lcom/personal/aihub/AudioBanks;
.field bgm Lcom/personal/aihub/PreviewBgm;
.field cache Lcom/personal/aihub/PreviewCache;
.field clients Ljava/util/Set;
.field context Landroid/content/Context;
.field cookie Ljava/lang/String;
.field effectPacks Lorg/json/JSONArray;
.field gameAssets Lcom/personal/aihub/GameAssets;
.field listener Ljava/net/ServerSocket;
.field movieRoot Ljava/io/File;
.field movies Ljava/util/Map;
.field origin Ljava/lang/String;
.field overlays Lorg/json/JSONArray;
.field preferredKey Ljava/lang/String;
.field preparedBytes J
.field preparing I
.field sourceDatabase Ljava/lang/String;
.field sparkingEffectIds Lorg/json/JSONArray;
.field sparkingVersion J
.field stageCapture Lcom/personal/aihub/StageCapture;
.field stageExport Lcom/personal/aihub/StageExport;
.field stopped Z
.field token Ljava/lang/String;
.field workers Ljava/util/concurrent/ThreadPoolExecutor;

.method <init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache;)V
  0000 const-string v0, ""
  0004 invoke-direct v1, v2, v3, v0, Lcom/personal/aihub/PreviewServer;-><init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String;)V
  000a return-void 
.end method

.method <init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String;)V
  0000 const/4 v0, 0
  0002 invoke-direct v1, v2, v3, v4, v0, Lcom/personal/aihub/PreviewServer;-><init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Lorg/json/JSONArray;)V
  0008 return-void 
.end method

.method <init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Lorg/json/JSONArray;)V
  0000 const/4 v5, 0
  0002 move-object v0, v6
  0004 move-object v1, v7
  0006 move-object v2, v8
  0008 move-object v3, v9
  000a move-object v4, v10
  000c invoke-direct/range v0 ... v5, Lcom/personal/aihub/PreviewServer;-><init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray;)V
  0012 return-void 
.end method

.method <init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray;)V
  0000 const-string v6, ""
  0004 move-object v0, v7
  0006 move-object v1, v8
  0008 move-object v2, v9
  000a move-object v3, v10
  000c move-object v4, v11
  000e move-object v5, v12
  0010 invoke-direct/range v0 ... v6, Lcom/personal/aihub/PreviewServer;-><init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String;)V
  0016 return-void 
.end method

.method <init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String;)V
  0000 const-string v7, ""
  0004 move-object v0, v8
  0006 move-object v1, v9
  0008 move-object v2, v10
  000a move-object v3, v11
  000c move-object v4, v12
  000e move-object v5, v13
  0010 move-object v6, v14
  0012 invoke-direct/range v0 ... v7, Lcom/personal/aihub/PreviewServer;-><init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String; Ljava/lang/String;)V
  0018 return-void 
.end method

.method <init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String; Ljava/lang/String;)V
  0000 const/4 v8, 0
  0002 move-object v0, v9
  0004 move-object v1, v10
  0006 move-object v2, v11
  0008 move-object v3, v12
  000a move-object v4, v13
  000c move-object v5, v14
  000e move-object v6, v15
  0010 move-object/from16 v7, v16
  0014 invoke-direct/range v0 ... v8, Lcom/personal/aihub/PreviewServer;-><init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray;)V
  001a return-void 
.end method

.method <init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray;)V
  0000 const-wide/16 v9, 0
  0004 move-object v0, v11
  0006 move-object v1, v12
  0008 move-object v2, v13
  000a move-object v3, v14
  000c move-object v4, v15
  000e move-object/from16 v5, v16
  0012 move-object/from16 v6, v17
  0016 move-object/from16 v7, v18
  001a move-object/from16 v8, v19
  001e invoke-direct/range v0 ... v10, Lcom/personal/aihub/PreviewServer;-><init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray; J)V
  0024 return-void 
.end method

.method <init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray; J)V
  0000 move-object/from16 v1, v16
  0004 move-object/from16 v0, v19
  0008 move-wide/from16 v2, v25
  000c const-string v4, "forge_preview_"
  0010 const-string v5, "http://127.0.0.1:"
  0014 invoke-direct/range v16, Ljava/lang/Object;-><init>()V
  001a new-instance v6, Ljava/util/HashSet;
  001e invoke-direct v6, Ljava/util/HashSet;-><init>()V
  0024 iput-object v6, v1, Lcom/personal/aihub/PreviewServer;->clients Ljava/util/Set;
  0028 new-instance v6, Ljava/util/HashMap;
  002c invoke-direct v6, Ljava/util/HashMap;-><init>()V
  0032 iput-object v6, v1, Lcom/personal/aihub/PreviewServer;->movies Ljava/util/Map;
  0036 new-instance v6, Ljava/lang/StringBuilder;
  003a invoke-direct v6, Ljava/lang/StringBuilder;-><init>()V
  0040 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0046 move-result-object v7
  0048 invoke-virtual v7, Ljava/util/UUID;->toString()Ljava/lang/String;
  004e move-result-object v7
  0050 const-string v8, "-"
  0054 const-string v9, ""
  0058 invoke-virtual v7, v8, v9, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  005e move-result-object v7
  0060 invoke-static v7, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0066 move-result-object v7
  0068 invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  006e invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0074 move-result-object v7
  0076 invoke-virtual v7, Ljava/util/UUID;->toString()Ljava/lang/String;
  007c move-result-object v7
  007e invoke-virtual v7, v8, v9, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  0084 move-result-object v7
  0086 invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  008c invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0092 move-result-object v6
  0094 iput-object v6, v1, Lcom/personal/aihub/PreviewServer;->token Ljava/lang/String;
  0098 invoke-virtual/range v17, Landroid/content/Context;->getApplicationContext()Landroid/content/Context;
  009e move-result-object v6
  00a0 iput-object v6, v1, Lcom/personal/aihub/PreviewServer;->context Landroid/content/Context;
  00a4 move-object/from16 v7, v18
  00a8 iput-object v7, v1, Lcom/personal/aihub/PreviewServer;->cache Lcom/personal/aihub/PreviewCache;
  00ac iput-object v0, v1, Lcom/personal/aihub/PreviewServer;->preferredKey Ljava/lang/String;
  00b0 invoke-static/range v23, Lcom/personal/aihub/PreviewMetadata;->normalizeSource(Ljava/lang/String;)Ljava/lang/String;
  00b6 move-result-object v7
  00b8 iput-object v7, v1, Lcom/personal/aihub/PreviewServer;->sourceDatabase Ljava/lang/String;
  00bc invoke-static/range v24, Lcom/personal/aihub/PreviewMetadata;->sparkingEffects(Ljava/lang/Object;)Lorg/json/JSONArray;
  00c2 move-result-object v8
  00c4 iput-object v8, v1, Lcom/personal/aihub/PreviewServer;->sparkingEffectIds Lorg/json/JSONArray;
  00c8 const-wide/16 v9, 0
  00cc cmp-long v9, v2, v9
  00d0 if-ltz v9, +1a8h
  00d4 const-wide v9, 9007199254740991
  00de cmp-long v9, v2, v9
  00e2 if-gtz v9, +19fh
  00e6 iput-wide v2, v1, Lcom/personal/aihub/PreviewServer;->sparkingVersion J
  00ea invoke-static/range v21, Lcom/personal/aihub/PreviewEffectPacks;->normalize(Ljava/lang/Object;)Lorg/json/JSONArray;
  00f0 move-result-object v9
  00f2 iput-object v9, v1, Lcom/personal/aihub/PreviewServer;->effectPacks Lorg/json/JSONArray;
  00f6 invoke-static v9, v8, Lcom/personal/aihub/PreviewMetadata;->validateEffectSources(Lorg/json/JSONArray; Lorg/json/JSONArray;)V
  00fc const-string v9, "sparking"
  0100 invoke-virtual v7, v9, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0106 move-result v10
  0108 const-string v11, "forge"
  010c if-nez v10, +008h
  0110 invoke-virtual v8, Lorg/json/JSONArray;->length()I
  0116 move-result v8
  0118 if-lez v8, +00eh
  011c new-instance v8, Ljava/io/File;
  0120 invoke-virtual v6, Landroid/content/Context;->getFilesDir()Ljava/io/File;
  0126 move-result-object v10
  0128 invoke-direct v8, v10, v11, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  012e invoke-static v8, v9, v2, v3, Lcom/personal/aihub/PreviewMetadata;->databaseFile(Ljava/io/File; Ljava/lang/String; J)Ljava/io/File;
  0134 invoke-static/range v20, Lcom/personal/aihub/GameAssets;->overlayMap(Lorg/json/JSONArray;)Ljava/util/Map;
  013a if-nez v20, +004h
  013e const/4 v10, 0
  0140 goto +ah
  0142 new-instance v10, Lorg/json/JSONArray;
  0146 invoke-virtual/range v20, Lorg/json/JSONArray;->toString()Ljava/lang/String;
  014c move-result-object v12
  014e invoke-direct v10, v12, Lorg/json/JSONArray;-><init>(Ljava/lang/String;)V
  0154 iput-object v10, v1, Lcom/personal/aihub/PreviewServer;->overlays Lorg/json/JSONArray;
  0158 new-instance v12, Lcom/personal/aihub/GameAssets;
  015c new-instance v13, Ljava/io/File;
  0160 invoke-virtual v6, Landroid/content/Context;->getFilesDir()Ljava/io/File;
  0166 move-result-object v14
  0168 const-string v15, "forge/assets"
  016c invoke-direct v13, v14, v15, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0172 invoke-direct v12, v13, v0, v10, Lcom/personal/aihub/GameAssets;-><init>(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray;)V
  0178 iput-object v12, v1, Lcom/personal/aihub/PreviewServer;->gameAssets Lcom/personal/aihub/GameAssets;
  017c new-instance v12, Ljava/io/File;
  0180 invoke-virtual v6, Landroid/content/Context;->getCacheDir()Ljava/io/File;
  0186 move-result-object v13
  0188 new-instance v14, Ljava/lang/StringBuilder;
  018c const-string v8, "preview-movies-"
  0190 invoke-direct v14, v8, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0196 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  019c move-result-object v8
  019e invoke-virtual v14, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  01a4 invoke-virtual v14, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01aa move-result-object v8
  01ac invoke-direct v12, v13, v8, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  01b2 iput-object v12, v1, Lcom/personal/aihub/PreviewServer;->movieRoot Ljava/io/File;
  01b6 new-instance v8, Lcom/personal/aihub/AudioBanks;
  01ba new-instance v12, Ljava/io/File;
  01be invoke-virtual v6, Landroid/content/Context;->getFilesDir()Ljava/io/File;
  01c4 move-result-object v13
  01c6 invoke-direct v12, v13, v15, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  01cc invoke-direct v8, v12, v0, v10, Lcom/personal/aihub/AudioBanks;-><init>(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray;)V
  01d2 iput-object v8, v1, Lcom/personal/aihub/PreviewServer;->audioBanks Lcom/personal/aihub/AudioBanks;
  01d6 const/4 v8, 1
  01d8 new-instance v0, Ljava/io/File;
  01dc invoke-virtual v6, Landroid/content/Context;->getFilesDir()Ljava/io/File;
  01e2 move-result-object v6
  01e4 invoke-direct v0, v6, v11, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  01ea invoke-static v0, v7, v2, v3, Lcom/personal/aihub/PreviewMetadata;->databaseFile(Ljava/io/File; Ljava/lang/String; J)Ljava/io/File;
  01f0 move-result-object v0
  01f2 invoke-virtual v0, Ljava/io/File;->isFile()Z
  01f8 move-result v2
  01fa if-eqz v2, +00eh
  01fe invoke-virtual v0, Ljava/io/File;->getPath()Ljava/lang/String;
  0204 move-result-object v0
  0206 const/4 v2, 0
  0208 invoke-static v0, v2, v8, Landroid/database/sqlite/SQLiteDatabase;->openDatabase(Ljava/lang/String; Landroid/database/sqlite/SQLiteDatabase$CursorFactory; I)Landroid/database/sqlite/SQLiteDatabase;
  020e move-result-object v0
  0210 goto +5h
  0212 move-exception v0
  0214 goto +7h
  0216 const/4 v2, 0
  0218 move-object v0, v2
  021a move-object v2, v0
  021c goto +bh
  021e move-exception v0
  0220 const/4 v2, 0
  0222 iget-object v3, v1, Lcom/personal/aihub/PreviewServer;->sourceDatabase Ljava/lang/String;
  0226 invoke-virtual v3, v9, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  022c move-result v3
  022e if-nez v3, +0d0h
  0232 new-instance v0, Lcom/personal/aihub/PreviewBgm;
  0236 new-instance v3, Ljava/io/File;
  023a iget-object v6, v1, Lcom/personal/aihub/PreviewServer;->context Landroid/content/Context;
  023e invoke-virtual v6, Landroid/content/Context;->getFilesDir()Ljava/io/File;
  0244 move-result-object v6
  0246 invoke-direct v3, v6, v15, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  024c iget-object v6, v1, Lcom/personal/aihub/PreviewServer;->gameAssets Lcom/personal/aihub/GameAssets;
  0250 move-object/from16 v7, v22
  0254 invoke-direct v0, v2, v3, v6, v7, Lcom/personal/aihub/PreviewBgm;-><init>(Landroid/database/sqlite/SQLiteDatabase; Ljava/io/File; Lcom/personal/aihub/GameAssets; Ljava/lang/String;)V
  025a iput-object v0, v1, Lcom/personal/aihub/PreviewServer;->bgm Lcom/personal/aihub/PreviewBgm;
  025e if-eqz v2, +005h
  0262 invoke-virtual v2, Landroid/database/sqlite/SQLiteDatabase;->close()V
  0268 iget-object v0, v1, Lcom/personal/aihub/PreviewServer;->movieRoot Ljava/io/File;
  026c invoke-virtual v0, Ljava/io/File;->mkdirs()Z
  0272 move-result v0
  0274 if-eqz v0, +095h
  0278 new-instance v0, Ljava/net/ServerSocket;
  027c invoke-direct v0, Ljava/net/ServerSocket;-><init>()V
  0282 iput-object v0, v1, Lcom/personal/aihub/PreviewServer;->listener Ljava/net/ServerSocket;
  0286 new-instance v3, Ljava/net/InetSocketAddress;
  028a const-string v6, "127.0.0.1"
  028e invoke-static v6, Ljava/net/InetAddress;->getByName(Ljava/lang/String;)Ljava/net/InetAddress;
  0294 move-result-object v6
  0296 const/4 v7, 0
  0298 invoke-direct v3, v6, v7, Ljava/net/InetSocketAddress;-><init>(Ljava/net/InetAddress; I)V
  029e const/16 v6, 32
  02a2 invoke-virtual v0, v3, v6, Ljava/net/ServerSocket;->bind(Ljava/net/SocketAddress; I)V
  02a8 new-instance v3, Ljava/lang/StringBuilder;
  02ac invoke-direct v3, v5, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  02b2 invoke-virtual v0, Ljava/net/ServerSocket;->getLocalPort()I
  02b8 move-result v5
  02ba invoke-virtual v3, v5, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  02c0 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  02c6 move-result-object v3
  02c8 iput-object v3, v1, Lcom/personal/aihub/PreviewServer;->origin Ljava/lang/String;
  02cc new-instance v3, Ljava/lang/StringBuilder;
  02d0 invoke-direct v3, v4, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  02d6 invoke-virtual v0, Ljava/net/ServerSocket;->getLocalPort()I
  02dc move-result v0
  02de invoke-virtual v3, v0, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  02e4 const-string v0, "="
  02e8 invoke-virtual v3, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02ee iget-object v0, v1, Lcom/personal/aihub/PreviewServer;->token Ljava/lang/String;
  02f2 invoke-virtual v3, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02f8 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  02fe move-result-object v0
  0300 iput-object v0, v1, Lcom/personal/aihub/PreviewServer;->cookie Ljava/lang/String;
  0304 new-instance v0, Ljava/util/concurrent/ThreadPoolExecutor;
  0308 sget-object v3, Ljava/util/concurrent/TimeUnit;->SECONDS Ljava/util/concurrent/TimeUnit;
  030c new-instance v4, Ljava/util/concurrent/ArrayBlockingQueue;
  0310 invoke-direct v4, v6, Ljava/util/concurrent/ArrayBlockingQueue;-><init>(I)V
  0316 new-instance v5, Lcom/personal/aihub/PreviewServer$1;
  031a invoke-direct v5, v1, Lcom/personal/aihub/PreviewServer$1;-><init>(Lcom/personal/aihub/PreviewServer;)V
  0320 new-instance v6, Ljava/util/concurrent/ThreadPoolExecutor$AbortPolicy;
  0324 invoke-direct v6, Ljava/util/concurrent/ThreadPoolExecutor$AbortPolicy;-><init>()V
  032a const/16 v7, 8
  032e const/16 v9, 8
  0332 const-wide/16 v10, 30
  0336 move-object/from16 v17, v0
  033a move/from16 v18, v7
  033e move/from16 v19, v9
  0342 move-wide/from16 v20, v10
  0346 move-object/from16 v22, v3
  034a move-object/from16 v23, v4
  034e move-object/from16 v24, v5
  0352 move-object/from16 v25, v6
  0356 invoke-direct/range v17 ... v25, Ljava/util/concurrent/ThreadPoolExecutor;-><init>(I I J Ljava/util/concurrent/TimeUnit; Ljava/util/concurrent/BlockingQueue; Ljava/util/concurrent/ThreadFactory; Ljava/util/concurrent/RejectedExecutionHandler;)V
  035c iput-object v0, v1, Lcom/personal/aihub/PreviewServer;->workers Ljava/util/concurrent/ThreadPoolExecutor;
  0360 new-instance v0, Ljava/lang/Thread;
  0364 new-instance v3, Lcom/personal/aihub/PreviewServer$2;
  0368 invoke-direct v3, v1, Lcom/personal/aihub/PreviewServer$2;-><init>(Lcom/personal/aihub/PreviewServer;)V
  036e const-string v4, "forge-preview-listener"
  0372 invoke-direct v0, v3, v4, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable; Ljava/lang/String;)V
  0378 invoke-virtual v0, v8, Ljava/lang/Thread;->setDaemon(Z)V
  037e invoke-virtual v0, Ljava/lang/Thread;->start()V
  0384 return-void 
  0386 move-exception v0
  0388 iget-object v3, v1, Lcom/personal/aihub/PreviewServer;->listener Ljava/net/ServerSocket;
  038c invoke-virtual v3, Ljava/net/ServerSocket;->close()V
  0392 iget-object v3, v1, Lcom/personal/aihub/PreviewServer;->movieRoot Ljava/io/File;
  0396 invoke-static v3, Lcom/personal/aihub/PreviewServer;->remove(Ljava/io/File;)V
  039c throw v0
  039e new-instance v0, Ljava/io/IOException;
  03a2 const-string v3, "Could not prepare temporary preview storage."
  03a6 invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03ac throw v0
  03ae move-exception v0
  03b0 if-eqz v2, +005h
  03b4 invoke-virtual v2, Landroid/database/sqlite/SQLiteDatabase;->close()V
  03ba throw v0
  03bc move-exception v0
  03be new-instance v2, Ljava/io/IOException;
  03c2 const-string v3, "Could not prepare move music"
  03c6 invoke-direct v2, v3, v0, Ljava/io/IOException;-><init>(Ljava/lang/String; Ljava/lang/Throwable;)V
  03cc throw v2
  03ce throw v0
  03d0 move-exception v0
  03d2 new-instance v2, Ljava/io/IOException;
  03d6 const-string v3, "Invalid edited movie preview"
  03da invoke-direct v2, v3, v0, Ljava/io/IOException;-><init>(Ljava/lang/String; Ljava/lang/Throwable;)V
  03e0 throw v2
  03e2 move-exception v0
  03e4 new-instance v2, Ljava/io/IOException;
  03e8 const-string v3, "Invalid preview asset manifest"
  03ec invoke-direct v2, v3, v0, Ljava/io/IOException;-><init>(Ljava/lang/String; Ljava/lang/Throwable;)V
  03f2 throw v2
  03f4 move-exception v0
  03f6 new-instance v2, Ljava/io/IOException;
  03fa invoke-virtual v0, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  0400 move-result-object v3
  0402 invoke-direct v2, v3, v0, Ljava/io/IOException;-><init>(Ljava/lang/String; Ljava/lang/Throwable;)V
  0408 throw v2
  040a move-exception v0
  040c new-instance v2, Ljava/io/IOException;
  0410 invoke-virtual v0, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  0416 move-result-object v3
  0418 invoke-direct v2, v3, v0, Ljava/io/IOException;-><init>(Ljava/lang/String; Ljava/lang/Throwable;)V
  041e throw v2
  0420 new-instance v0, Ljava/io/IOException;
  0424 const-string v2, "Choose a valid Sparking content version."
  0428 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  042e throw v0
.end method

.method closeSocket(Ljava/net/Socket;)V
  0000 invoke-virtual v0, Ljava/net/Socket;->close()V
  0006 return-void 
.end method

.method deleteMovie(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request;)V
  0000 iget-object v0, v13, Lcom/personal/aihub/PreviewServer$Request;->uri Ljava/net/URI;
  0004 invoke-virtual v0, Ljava/net/URI;->getPath()Ljava/lang/String;
  000a move-result-object v0
  000c const/16 v1, 24
  0010 invoke-virtual v0, v1, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0016 move-result-object v0
  0018 const-string v1, "[a-f0-9]{32}\.mp4"
  001c invoke-virtual v0, v1, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0022 move-result v1
  0024 const/4 v2, 0
  0026 if-eqz v1, +08fh
  002a iget-object v1, v13, Lcom/personal/aihub/PreviewServer$Request;->uri Ljava/net/URI;
  002e invoke-virtual v1, Ljava/net/URI;->getRawQuery()Ljava/lang/String;
  0034 move-result-object v1
  0036 if-eqz v1, +004h
  003a goto/16 +085h
  003e iget-object v1, v13, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  0042 const-string v3, "content-length"
  0046 invoke-interface v1, v3, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z
  004c move-result v1
  004e if-eqz v1, +023h
  0052 iget-object v13, v13, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  0056 const-string v1, "content-length"
  005a invoke-interface v13, v1, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0060 move-result-object v13
  0062 check-cast v13, Ljava/lang/String;
  0066 const-string v1, "0"
  006a invoke-virtual v13, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0070 move-result v13
  0072 if-nez v13, +011h
  0076 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  007c move-result-object v6
  007e new-array v7, v2, [B
  0082 const/4 v8, 0
  0084 const/16 v5, 400
  0088 move-object v3, v11
  008a move-object v4, v12
  008c invoke-direct/range v3 ... v8, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0092 return-void 
  0094 monitor-enter v11
  0096 iget-object v13, v11, Lcom/personal/aihub/PreviewServer;->movies Ljava/util/Map;
  009a invoke-interface v13, v0, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  00a0 move-result-object v13
  00a2 check-cast v13, Ljava/io/File;
  00a6 if-nez v13, +012h
  00aa invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  00b0 move-result-object v6
  00b2 new-array v7, v2, [B
  00b6 const/4 v8, 0
  00b8 const/16 v5, 404
  00bc move-object v3, v11
  00be move-object v4, v12
  00c0 invoke-direct/range v3 ... v8, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  00c6 monitor-exit v11
  00c8 return-void 
  00ca invoke-virtual v13, Ljava/io/File;->length()J
  00d0 move-result-wide v3
  00d2 invoke-virtual v13, Ljava/io/File;->delete()Z
  00d8 move-result v13
  00da if-nez v13, +012h
  00de invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  00e4 move-result-object v8
  00e6 new-array v9, v2, [B
  00ea const/4 v10, 0
  00ec const/16 v7, 503
  00f0 move-object v5, v11
  00f2 move-object v6, v12
  00f4 invoke-direct/range v5 ... v10, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  00fa monitor-exit v11
  00fc return-void 
  00fe iget-object v13, v11, Lcom/personal/aihub/PreviewServer;->movies Ljava/util/Map;
  0102 invoke-interface v13, v0, Ljava/util/Map;->remove(Ljava/lang/Object;)Ljava/lang/Object;
  0108 iget-wide v0, v11, Lcom/personal/aihub/PreviewServer;->preparedBytes J
  010c sub-long/2addr v0, v3
  010e const-wide/16 v3, 0
  0112 invoke-static v3, v4, v0, v1, Ljava/lang/Math;->max(J J)J
  0118 move-result-wide v0
  011a iput-wide v0, v11, Lcom/personal/aihub/PreviewServer;->preparedBytes J
  011e invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  0124 move-result-object v6
  0126 new-array v7, v2, [B
  012a const/4 v8, 0
  012c const/16 v5, 204
  0130 move-object v3, v11
  0132 move-object v4, v12
  0134 invoke-direct/range v3 ... v8, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  013a monitor-exit v11
  013c return-void 
  013e move-exception v12
  0140 monitor-exit v11
  0142 throw v12
  0144 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  014a move-result-object v3
  014c new-array v4, v2, [B
  0150 const/4 v5, 0
  0152 const/16 v2, 404
  0156 move-object v0, v11
  0158 move-object v1, v12
  015a invoke-direct/range v0 ... v5, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0160 return-void 
.end method

.method finishSocket(Ljava/net/Socket;)V
  0000 invoke-virtual v6, Ljava/net/Socket;->shutdownOutput()V
  0006 const/16 v0, 100
  000a invoke-virtual v6, v0, Ljava/net/Socket;->setSoTimeout(I)V
  0010 invoke-virtual v6, Ljava/net/Socket;->getInputStream()Ljava/io/InputStream;
  0016 move-result-object v0
  0018 const/16 v1, 8192
  001c new-array v2, v1, [B
  0020 const/high16 v3, 65536
  0024 if-lez v3, +015h
  0028 invoke-static v1, v3, Ljava/lang/Math;->min(I I)I
  002e move-result v4
  0030 const/4 v5, 0
  0032 invoke-virtual v0, v2, v5, v4, Ljava/io/InputStream;->read([B I I)I
  0038 move-result v4
  003a if-gez v4, +003h
  003e goto +8h
  0040 sub-int/2addr v3, v4
  0042 goto -fh
  0044 move-exception v0
  0046 invoke-static v6, Lcom/personal/aihub/PreviewServer;->closeSocket(Ljava/net/Socket;)V
  004c throw v0
  004e invoke-static v6, Lcom/personal/aihub/PreviewServer;->closeSocket(Ljava/net/Socket;)V
  0054 return-void 
.end method

.method lambda$0(Ljava/lang/Runnable;)Ljava/lang/Thread;
  0000 new-instance v0, Ljava/lang/Thread;
  0004 const-string v1, "forge-preview-http"
  0008 invoke-direct v0, v2, v1, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable; Ljava/lang/String;)V
  000e const/4 v2, 1
  0010 invoke-virtual v0, v2, Ljava/lang/Thread;->setDaemon(Z)V
  0016 return-object v0
.end method

.method manifest(Ljava/lang/String;)Lorg/json/JSONObject;
  0000 iget-object v0, v4, Lcom/personal/aihub/PreviewServer;->context Landroid/content/Context;
  0004 invoke-virtual v0, Landroid/content/Context;->getAssets()Landroid/content/res/AssetManager;
  000a move-result-object v0
  000c invoke-virtual v0, v5, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;
  0012 move-result-object v5
  0014 new-instance v0, Lorg/json/JSONObject;
  0018 new-instance v1, Ljava/lang/String;
  001c const/high16 v2, 2097152
  0020 invoke-static v5, v2, Lcom/personal/aihub/PreviewServer;->readBytes(Ljava/io/InputStream; I)[B
  0026 move-result-object v2
  0028 sget-object v3, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  002c invoke-direct v1, v2, v3, Ljava/lang/String;-><init>([B Ljava/nio/charset/Charset;)V
  0032 invoke-direct v0, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0038 if-eqz v5, +005h
  003c invoke-virtual v5, Ljava/io/InputStream;->close()V
  0042 return-object v0
  0044 move-exception v0
  0046 if-eqz v5, +005h
  004a invoke-virtual v5, Ljava/io/InputStream;->close()V
  0050 throw v0
.end method

.method mime(Ljava/lang/String;)Ljava/lang/String;
  0000 const/16 v0, 46
  0004 invoke-virtual v5, v0, Ljava/lang/String;->lastIndexOf(I)I
  000a move-result v0
  000c add-int/lit8 v0, v0, 1
  0010 invoke-virtual v5, v0, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0016 move-result-object v5
  0018 sget-object v0, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  001c invoke-virtual v5, v0, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  0022 move-result-object v5
  0024 invoke-virtual v5, Ljava/lang/String;->hashCode()I
  002a move-result v0
  002c const-string v1, "application/xml"
  0030 const-string v2, "image/jpeg"
  0034 const-string v3, "text/plain"
  0038 const-string v4, "application/octet-stream"
  003c sparse-switch v0, +00000cch
  0042 return-object v4
  0044 const-string v0, "plist"
  0048 invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  004e move-result v5
  0050 if-nez v5, +003h
  0054 move-object v1, v4
  0056 return-object v1
  0058 const-string v0, "webp"
  005c invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0062 move-result v5
  0064 if-nez v5, +003h
  0068 goto +3h
  006a const-string v4, "image/webp"
  006e return-object v4
  0070 const-string v0, "json"
  0074 invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  007a move-result v5
  007c if-nez v5, +003h
  0080 goto +3h
  0082 const-string v4, "application/json"
  0086 return-object v4
  0088 const-string v0, "jpeg"
  008c invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0092 move-result v5
  0094 if-nez v5, +003h
  0098 move-object v2, v4
  009a return-object v2
  009c const-string v0, "xml"
  00a0 invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00a6 move-result v5
  00a8 if-nez v5, +003h
  00ac move-object v1, v4
  00ae return-object v1
  00b0 const-string v0, "wav"
  00b4 invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00ba move-result v5
  00bc if-nez v5, +003h
  00c0 goto +3h
  00c2 const-string v4, "audio/wav"
  00c6 return-object v4
  00c8 const-string v0, "vsh"
  00cc invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00d2 move-result v5
  00d4 if-nez v5, +003h
  00d8 move-object v3, v4
  00da return-object v3
  00dc const-string v0, "txt"
  00e0 invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00e6 move-result v5
  00e8 if-nez v5, +003h
  00ec move-object v3, v4
  00ee return-object v3
  00f0 const-string v0, "ttf"
  00f4 invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00fa move-result v5
  00fc if-nez v5, +003h
  0100 goto +3h
  0102 const-string v4, "font/ttf"
  0106 return-object v4
  0108 const-string v0, "png"
  010c invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0112 move-result v5
  0114 if-nez v5, +003h
  0118 goto +3h
  011a const-string v4, "image/png"
  011e return-object v4
  0120 const-string v0, "otf"
  0124 invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  012a move-result v5
  012c if-nez v5, +003h
  0130 goto +3h
  0132 const-string v4, "font/otf"
  0136 return-object v4
  0138 const-string v0, "ogg"
  013c invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0142 move-result v5
  0144 if-nez v5, +003h
  0148 goto +3h
  014a const-string v4, "audio/ogg"
  014e return-object v4
  0150 const-string v0, "mp3"
  0154 invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  015a move-result v5
  015c if-nez v5, +003h
  0160 goto +3h
  0162 const-string v4, "audio/mpeg"
  0166 return-object v4
  0168 const-string v0, "lua"
  016c invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0172 move-result v5
  0174 if-nez v5, +003h
  0178 move-object v3, v4
  017a return-object v3
  017c const-string v0, "jpg"
  0180 invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0186 move-result v5
  0188 if-nez v5, +003h
  018c move-object v2, v4
  018e return-object v2
  0190 const-string v0, "gif"
  0194 invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  019a move-result v5
  019c if-nez v5, +003h
  01a0 goto +3h
  01a2 const-string v4, "image/gif"
  01a6 return-object v4
  01a8 const-string v0, "fsh"
  01ac invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01b2 move-result v5
  01b4 if-nez v5, +003h
  01b8 move-object v3, v4
  01ba return-object v3
  01bc const-string v0, "bmp"
  01c0 invoke-virtual v5, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01c6 move-result v5
  01c8 if-nez v5, +003h
  01cc goto +3h
  01ce const-string v4, "image/bmp"
  01d2 return-object v4
  01d4 sparse-switch-payload 17d85 18d3b 18fc4 19be1 1a3f8 1a6f0 1ad8f 1af21 1b229 1c1e6 1c270 1c94b 1caec 1d017 31e068 31ece8 379f9c 65cf90e
.end method

.method movie(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request;)V
  0000 iget-object v0, v11, Lcom/personal/aihub/PreviewServer$Request;->uri Ljava/net/URI;
  0004 invoke-virtual v0, Ljava/net/URI;->getPath()Ljava/lang/String;
  000a move-result-object v0
  000c const/16 v1, 24
  0010 invoke-virtual v0, v1, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0016 move-result-object v0
  0018 monitor-enter v9
  001a iget-object v1, v9, Lcom/personal/aihub/PreviewServer;->movies Ljava/util/Map;
  001e invoke-interface v1, v0, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0024 move-result-object v1
  0026 check-cast v1, Ljava/io/File;
  002a monitor-exit v9
  002c const-string v2, "[a-f0-9]{32}\.mp4"
  0030 invoke-virtual v0, v2, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0036 move-result v0
  0038 if-eqz v0, +039h
  003c if-eqz v1, +037h
  0040 iget-object v0, v11, Lcom/personal/aihub/PreviewServer$Request;->uri Ljava/net/URI;
  0044 invoke-virtual v0, Ljava/net/URI;->getRawQuery()Ljava/lang/String;
  004a move-result-object v0
  004c if-eqz v0, +003h
  0050 goto +2dh
  0052 new-instance v5, Ljava/util/HashMap;
  0056 invoke-direct v5, Ljava/util/HashMap;-><init>()V
  005c const-string v0, "Content-Type"
  0060 const-string v2, "video/mp4"
  0064 invoke-virtual v5, v0, v2, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  006a const-string v0, "Accept-Ranges"
  006e const-string v2, "bytes"
  0072 invoke-virtual v5, v0, v2, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0078 new-instance v0, Ljava/io/FileInputStream;
  007c invoke-direct v0, v1, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0082 invoke-virtual v1, Ljava/io/File;->length()J
  0088 move-result-wide v7
  008a move-object v2, v9
  008c move-object v3, v10
  008e move-object v4, v11
  0090 move-object v6, v0
  0092 invoke-direct/range v2 ... v8, Lcom/personal/aihub/PreviewServer;->sendStream(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request; Ljava/util/Map; Ljava/io/InputStream; J)V
  0098 invoke-virtual v0, Ljava/io/FileInputStream;->close()V
  009e return-void 
  00a0 move-exception v10
  00a2 invoke-virtual v0, Ljava/io/FileInputStream;->close()V
  00a8 throw v10
  00aa invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  00b0 move-result-object v4
  00b2 const/4 v0, 0
  00b4 new-array v5, v0, [B
  00b8 iget-object v11, v11, Lcom/personal/aihub/PreviewServer$Request;->method Ljava/lang/String;
  00bc const-string v0, "HEAD"
  00c0 invoke-virtual v11, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00c6 move-result v6
  00c8 const/16 v3, 404
  00cc move-object v1, v9
  00ce move-object v2, v10
  00d0 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  00d6 return-void 
  00d8 move-exception v10
  00da monitor-exit v9
  00dc throw v10
.end method

.method playerPatches(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0000 const-string v0, "/tools/lua-player/js/usm-player.js"
  0004 invoke-virtual v9, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  000a move-result v0
  000c const-string v1, "path"
  0010 const/4 v2, 0
  0012 if-eqz v0, +00ah
  0016 const-string v0, "ui/media-player-patches.json"
  001a invoke-direct v8, v0, Lcom/personal/aihub/PreviewServer;->manifest(Ljava/lang/String;)Lorg/json/JSONObject;
  0020 move-result-object v0
  0022 goto/16 +08fh
  0026 const-string v0, "/tools/lua-player/js/audio-bus.js"
  002a invoke-virtual v9, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0030 move-result v0
  0032 if-eqz v0, +00ah
  0036 const-string v0, "ui/audio-player-patches.json"
  003a invoke-direct v8, v0, Lcom/personal/aihub/PreviewServer;->manifest(Ljava/lang/String;)Lorg/json/JSONObject;
  0040 move-result-object v0
  0042 goto/16 +07fh
  0046 const-string v0, "/tools/lwf-player/js/lwf-pack.js"
  004a invoke-virtual v9, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0050 move-result v0
  0052 if-eqz v0, +00ah
  0056 const-string v0, "ui/lwf-player-patches.json"
  005a invoke-direct v8, v0, Lcom/personal/aihub/PreviewServer;->manifest(Ljava/lang/String;)Lorg/json/JSONObject;
  0060 move-result-object v0
  0062 goto/16 +06fh
  0066 const-string v0, "/tools/lua-player/js/binders.js"
  006a invoke-virtual v9, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0070 move-result v0
  0072 const/4 v3, 0
  0074 if-nez v0, +03dh
  0078 const-string v0, "/tools/lua-player/js/runner.js"
  007c invoke-virtual v9, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0082 move-result v0
  0084 if-nez v0, +035h
  0088 const-string v0, "/tools/lua-player/js/tcb-keys.js"
  008c invoke-virtual v9, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0092 move-result v0
  0094 if-nez v0, +02dh
  0098 const-string v0, "/tools/lua-player/js/lwf-player.js"
  009c invoke-virtual v9, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00a2 move-result v0
  00a4 if-nez v0, +025h
  00a8 const-string v0, "/tools/lua-player/js/recorder.js"
  00ac invoke-virtual v9, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00b2 move-result v0
  00b4 if-nez v0, +01dh
  00b8 const-string v0, "/tools/lua-player/js/atlas-fit.js"
  00bc invoke-virtual v9, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00c2 move-result v0
  00c4 if-nez v0, +015h
  00c8 const-string v0, "/static/vendor/lwf/lwf.js"
  00cc invoke-virtual v9, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00d2 move-result v0
  00d4 if-nez v0, +00dh
  00d8 const-string v0, "/tools/lua-player/js/app.js"
  00dc invoke-virtual v9, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00e2 move-result v0
  00e4 if-eqz v0, +003h
  00e8 goto +3h
  00ea move-object v0, v3
  00ec goto +2ah
  00ee const-string v0, "ui/training-player-patches.json"
  00f2 invoke-direct v8, v0, Lcom/personal/aihub/PreviewServer;->manifest(Ljava/lang/String;)Lorg/json/JSONObject;
  00f8 move-result-object v0
  00fa const-string v4, "manifests"
  00fe invoke-virtual v0, v4, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0104 move-result-object v0
  0106 move v4, v2
  0108 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  010e move-result v5
  0110 if-lt v4, v5, +004h
  0114 move-object v0, v3
  0116 goto +13h
  0118 invoke-virtual v0, v4, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  011e move-result-object v5
  0120 invoke-virtual v5, v1, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0126 move-result-object v5
  0128 invoke-virtual v9, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  012e move-result v5
  0130 if-eqz v5, +0cch
  0134 invoke-virtual v0, v4, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  013a move-result-object v0
  013c if-eqz v0, +0beh
  0140 if-nez v0, +003h
  0144 return-object v10
  0146 invoke-virtual v0, v1, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  014c move-result-object v1
  014e invoke-virtual v9, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0154 move-result v9
  0156 if-eqz v9, +0a9h
  015a const-string v9, "SHA-256"
  015e invoke-static v9, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;
  0164 move-result-object v9
  0166 sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  016a invoke-virtual v10, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0170 move-result-object v1
  0172 invoke-virtual v9, v1, Ljava/security/MessageDigest;->digest([B)[B
  0178 move-result-object v9
  017a new-instance v1, Ljava/lang/StringBuilder;
  017e invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  0184 array-length v3, v9
  0186 move v4, v2
  0188 if-ge v4, v3, +01ch
  018c aget-byte v5, v9, v4
  0190 sget-object v6, Ljava/util/Locale;->US Ljava/util/Locale;
  0194 and-int/lit16 v5, v5, 255
  0198 invoke-static v5, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  019e move-result-object v5
  01a0 filled-new-array v5, [Ljava/lang/Object;
  01a6 move-result-object v5
  01a8 const-string v7, "%02x"
  01ac invoke-static v6, v7, v5, Ljava/lang/String;->format(Ljava/util/Locale; Ljava/lang/String; [Ljava/lang/Object;)Ljava/lang/String;
  01b2 move-result-object v5
  01b4 invoke-virtual v1, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01ba add-int/lit8 v4, v4, 1
  01be goto -1bh
  01c0 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01c6 move-result-object v9
  01c8 const-string v1, "sourceSha256"
  01cc invoke-virtual v0, v1, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  01d2 move-result-object v1
  01d4 invoke-virtual v9, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01da move-result v9
  01dc const-string v1, "The public player changed. Update Dokkan Unit Creator before previewing this animation."
  01e0 if-eqz v9, +05eh
  01e4 const-string v9, "patches"
  01e8 invoke-virtual v0, v9, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  01ee move-result-object v9
  01f0 move v0, v2
  01f2 invoke-virtual v9, Lorg/json/JSONArray;->length()I
  01f8 move-result v3
  01fa if-ge v0, v3, +050h
  01fe invoke-virtual v9, v0, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  0204 move-result-object v3
  0206 const-string v4, "find"
  020a invoke-virtual v3, v4, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0210 move-result-object v4
  0212 invoke-virtual v10, v4, Ljava/lang/String;->indexOf(Ljava/lang/String;)I
  0218 move-result v5
  021a invoke-virtual v4, Ljava/lang/String;->isEmpty()Z
  0220 move-result v6
  0222 if-nez v6, +036h
  0226 if-ltz v5, +034h
  022a invoke-virtual v10, v4, Ljava/lang/String;->lastIndexOf(Ljava/lang/String;)I
  0230 move-result v6
  0232 if-ne v5, v6, +02eh
  0236 new-instance v6, Ljava/lang/StringBuilder;
  023a invoke-direct v6, Ljava/lang/StringBuilder;-><init>()V
  0240 invoke-virtual v10, v2, v5, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  0246 move-result-object v7
  0248 invoke-static v7, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  024e move-result-object v7
  0250 invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0256 const-string v7, "replace"
  025a invoke-virtual v3, v7, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0260 move-result-object v3
  0262 invoke-virtual v6, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0268 invoke-virtual v4, Ljava/lang/String;->length()I
  026e move-result v3
  0270 add-int/2addr v5, v3
  0272 invoke-virtual v10, v5, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0278 move-result-object v10
  027a invoke-virtual v6, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0280 invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0286 move-result-object v10
  0288 add-int/lit8 v0, v0, 1
  028c goto -4dh
  028e new-instance v9, Ljava/io/IOException;
  0292 invoke-direct v9, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0298 throw v9
  029a return-object v10
  029c new-instance v9, Ljava/io/IOException;
  02a0 invoke-direct v9, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02a6 throw v9
  02a8 new-instance v9, Ljava/io/IOException;
  02ac const-string v10, "The packaged player adapter is incompatible. Update Dokkan Unit Creator."
  02b0 invoke-direct v9, v10, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02b6 throw v9
  02b8 new-instance v9, Ljava/io/IOException;
  02bc const-string v10, "The packaged item scene adapter is incompatible. Update Dokkan Unit Creator."
  02c0 invoke-direct v9, v10, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02c6 throw v9
  02c8 add-int/lit8 v4, v4, 1
  02cc goto/16 -0e2h
.end method

.method prepare(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request;)V
  0000 move-object/from16 v7, v19
  0004 move-object/from16 v0, v21
  0008 iget-object v1, v0, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  000c const-string v2, "content-length"
  0010 invoke-interface v1, v2, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0016 move-result-object v1
  0018 check-cast v1, Ljava/lang/String;
  001c const/4 v8, 0
  001e if-eqz v1, +22fh
  0022 const-string v2, "[0-9]+"
  0026 invoke-virtual v1, v2, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  002c move-result v2
  002e if-eqz v2, +227h
  0032 invoke-static v1, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  0038 move-result-wide v9
  003a const-wide/16 v1, 12
  003e cmp-long v1, v9, v1
  0042 if-ltz v1, +20bh
  0046 const-wide/32 v1, 167772160
  004c cmp-long v1, v9, v1
  0050 if-lez v1, +004h
  0054 goto/16 +202h
  0058 iget-object v1, v0, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  005c const-string v2, "content-type"
  0060 const-string v3, ""
  0064 invoke-interface v1, v2, v3, Ljava/util/Map;->getOrDefault(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  006a move-result-object v1
  006c check-cast v1, Ljava/lang/String;
  0070 const-string v2, ";"
  0074 const/4 v3, 2
  0076 invoke-virtual v1, v2, v3, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  007c move-result-object v1
  007e aget-object v1, v1, v8
  0082 invoke-virtual v1, Ljava/lang/String;->trim()Ljava/lang/String;
  0088 move-result-object v1
  008a const-string v2, "video/mp4"
  008e invoke-virtual v1, v2, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z
  0094 move-result v1
  0096 if-nez v1, +013h
  009a invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  00a0 move-result-object v4
  00a2 new-array v5, v8, [B
  00a6 const/4 v6, 0
  00a8 const/16 v3, 415
  00ac move-object/from16 v1, v19
  00b0 move-object/from16 v2, v20
  00b4 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  00ba return-void 
  00bc new-instance v1, Ljava/lang/StringBuilder;
  00c0 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  00c6 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  00cc move-result-object v2
  00ce invoke-virtual v2, Ljava/util/UUID;->toString()Ljava/lang/String;
  00d4 move-result-object v2
  00d6 const-string v3, "-"
  00da const-string v4, ""
  00de invoke-virtual v2, v3, v4, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  00e4 move-result-object v2
  00e6 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00ec const-string v2, ".mp4"
  00f0 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00f6 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00fc move-result-object v1
  00fe new-instance v11, Ljava/io/File;
  0102 iget-object v2, v7, Lcom/personal/aihub/PreviewServer;->movieRoot Ljava/io/File;
  0106 new-instance v3, Ljava/lang/StringBuilder;
  010a invoke-direct v3, Ljava/lang/StringBuilder;-><init>()V
  0110 invoke-virtual v3, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0116 const-string v4, ".tmp"
  011a invoke-virtual v3, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0120 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0126 move-result-object v3
  0128 invoke-direct v11, v2, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  012e new-instance v12, Ljava/io/File;
  0132 iget-object v2, v7, Lcom/personal/aihub/PreviewServer;->movieRoot Ljava/io/File;
  0136 invoke-direct v12, v2, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  013c monitor-enter v19
  013e iget-boolean v2, v7, Lcom/personal/aihub/PreviewServer;->stopped Z
  0142 if-nez v2, +170h
  0146 iget-object v2, v7, Lcom/personal/aihub/PreviewServer;->movies Ljava/util/Map;
  014a invoke-interface v2, Ljava/util/Map;->size()I
  0150 move-result v2
  0152 iget v3, v7, Lcom/personal/aihub/PreviewServer;->preparing I
  0156 add-int/2addr v2, v3
  0158 const/16 v4, 32
  015c if-ge v2, v4, +163h
  0160 iget-wide v4, v7, Lcom/personal/aihub/PreviewServer;->preparedBytes J
  0164 const-wide/32 v13, 536870912
  016a sub-long/2addr v13, v4
  016c cmp-long v2, v9, v13
  0170 if-lez v2, +004h
  0174 goto/16 +157h
  0178 add-long/2addr v4, v9
  017a iput-wide v4, v7, Lcom/personal/aihub/PreviewServer;->preparedBytes J
  017e const/4 v13, 1
  0180 add-int/2addr v3, v13
  0182 iput v3, v7, Lcom/personal/aihub/PreviewServer;->preparing I
  0186 monitor-exit v19
  0188 const-wide/16 v14, 0
  018c new-instance v2, Ljava/io/FileOutputStream;
  0190 invoke-direct v2, v11, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0196 const/high16 v3, 65536
  019a new-array v4, v3, [B
  019e move-wide v5, v9
  01a0 cmp-long v16, v5, v14
  01a4 if-lez v16, +02ch
  01a8 iget-object v14, v0, Lcom/personal/aihub/PreviewServer$Request;->input Ljava/io/BufferedInputStream;
  01ac move-wide/from16 v17, v9
  01b0 int-to-long v8, v3
  01b2 invoke-static v8, v9, v5, v6, Ljava/lang/Math;->min(J J)J
  01b8 move-result-wide v8
  01ba long-to-int v8, v8
  01bc const/4 v9, 0
  01be invoke-virtual v14, v4, v9, v8, Ljava/io/BufferedInputStream;->read([B I I)I
  01c4 move-result v8
  01c6 if-ltz v8, +013h
  01ca if-nez v8, +008h
  01ce move v8, v9
  01d0 move-wide/from16 v9, v17
  01d4 const-wide/16 v14, 0
  01d8 goto -1ch
  01da invoke-virtual v2, v4, v9, v8, Ljava/io/FileOutputStream;->write([B I I)V
  01e0 int-to-long v8, v8
  01e2 sub-long/2addr v5, v8
  01e4 move-wide/from16 v9, v17
  01e8 const/4 v8, 0
  01ea goto -bh
  01ec new-instance v0, Ljava/io/EOFException;
  01f0 const-string v1, "Incomplete prepared movie"
  01f4 invoke-direct v0, v1, Ljava/io/EOFException;-><init>(Ljava/lang/String;)V
  01fa throw v0
  01fc move-wide/from16 v17, v9
  0200 invoke-virtual v2, Ljava/io/FileOutputStream;->getFD()Ljava/io/FileDescriptor;
  0206 move-result-object v0
  0208 invoke-virtual v0, Ljava/io/FileDescriptor;->sync()V
  020e invoke-virtual v2, Ljava/io/FileOutputStream;->close()V
  0214 new-instance v8, Ljava/io/RandomAccessFile;
  0218 const-string v0, "r"
  021c invoke-direct v8, v11, v0, Ljava/io/RandomAccessFile;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0222 const-wide/16 v2, 4
  0226 invoke-virtual v8, v2, v3, Ljava/io/RandomAccessFile;->seek(J)V
  022c const/4 v0, 4
  022e new-array v2, v0, [B
  0232 invoke-virtual v8, v2, Ljava/io/RandomAccessFile;->readFully([B)V
  0238 new-array v0, v0, [B
  023c fill-array-data v0, +0000138h
  0242 invoke-static v2, v0, Ljava/util/Arrays;->equals([B [B)Z
  0248 move-result v0
  024a if-nez v0, +033h
  024e invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  0254 move-result-object v4
  0256 const/4 v1, 0
  0258 new-array v5, v1, [B
  025c const/4 v6, 0
  025e const/16 v3, 415
  0262 move-object/from16 v1, v19
  0266 move-object/from16 v2, v20
  026a invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0270 invoke-virtual v8, Ljava/io/RandomAccessFile;->close()V
  0276 invoke-virtual v11, Ljava/io/File;->delete()Z
  027c monitor-enter v19
  027e iget v0, v7, Lcom/personal/aihub/PreviewServer;->preparing I
  0282 sub-int/2addr v0, v13
  0284 iput v0, v7, Lcom/personal/aihub/PreviewServer;->preparing I
  0288 iget-wide v0, v7, Lcom/personal/aihub/PreviewServer;->preparedBytes J
  028c sub-long v0, v0, v17
  0290 const-wide/16 v2, 0
  0294 invoke-static v2, v3, v0, v1, Ljava/lang/Math;->max(J J)J
  029a move-result-wide v0
  029c iput-wide v0, v7, Lcom/personal/aihub/PreviewServer;->preparedBytes J
  02a0 invoke-virtual v12, Ljava/io/File;->delete()Z
  02a6 monitor-exit v19
  02a8 return-void 
  02aa move-exception v0
  02ac monitor-exit v19
  02ae throw v0
  02b0 invoke-virtual v8, Ljava/io/RandomAccessFile;->close()V
  02b6 monitor-enter v19
  02b8 iget-boolean v0, v7, Lcom/personal/aihub/PreviewServer;->stopped Z
  02bc if-nez v0, +062h
  02c0 invoke-virtual v11, v12, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  02c6 move-result v0
  02c8 if-eqz v0, +054h
  02cc iget-object v0, v7, Lcom/personal/aihub/PreviewServer;->movies Ljava/util/Map;
  02d0 invoke-interface v0, v1, v12, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  02d6 monitor-exit v19
  02d8 const-string v0, "Content-Type"
  02dc const-string v2, "application/json"
  02e0 invoke-static v0, v2, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  02e6 move-result-object v4
  02e8 new-instance v0, Lorg/json/JSONObject;
  02ec invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  02f2 const-string v2, "url"
  02f6 new-instance v3, Ljava/lang/StringBuilder;
  02fa invoke-direct v3, Ljava/lang/StringBuilder;-><init>()V
  0300 const-string v5, "/_forge/prepared-movies/"
  0304 invoke-virtual v3, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  030a invoke-virtual v3, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0310 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0316 move-result-object v1
  0318 invoke-virtual v0, v2, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  031e move-result-object v0
  0320 invoke-virtual v0, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0326 move-result-object v0
  0328 sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  032c invoke-virtual v0, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0332 move-result-object v5
  0334 const/4 v6, 0
  0336 const/16 v3, 201
  033a move-object/from16 v1, v19
  033e move-object/from16 v2, v20
  0342 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0348 invoke-virtual v11, Ljava/io/File;->delete()Z
  034e monitor-enter v19
  0350 iget v0, v7, Lcom/personal/aihub/PreviewServer;->preparing I
  0354 sub-int/2addr v0, v13
  0356 iput v0, v7, Lcom/personal/aihub/PreviewServer;->preparing I
  035a monitor-exit v19
  035c return-void 
  035e move-exception v0
  0360 monitor-exit v19
  0362 throw v0
  0364 move-exception v0
  0366 move v8, v13
  0368 goto +3eh
  036a move-exception v0
  036c move v8, v13
  036e goto +13h
  0370 new-instance v0, Ljava/io/IOException;
  0374 const-string v1, "Could not retain this prepared movie"
  0378 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  037e throw v0
  0380 new-instance v0, Ljava/io/IOException;
  0384 const-string v1, "Preview closed"
  0388 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  038e throw v0
  0390 move-exception v0
  0392 const/4 v8, 0
  0394 monitor-exit v19
  0396 throw v0
  0398 move-exception v0
  039a goto +25h
  039c move-exception v0
  039e goto -5h
  03a0 move-exception v0
  03a2 move-object v1, v0
  03a4 invoke-virtual v8, Ljava/io/RandomAccessFile;->close()V
  03aa goto +6h
  03ac move-exception v0
  03ae move-object v2, v0
  03b0 invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  03b6 throw v1
  03b8 move-exception v0
  03ba goto +4h
  03bc move-exception v0
  03be move-wide/from16 v17, v9
  03c2 move-object v1, v0
  03c4 invoke-virtual v2, Ljava/io/FileOutputStream;->close()V
  03ca goto +6h
  03cc move-exception v0
  03ce move-object v2, v0
  03d0 invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  03d6 throw v1
  03d8 move-exception v0
  03da goto +4h
  03dc move-exception v0
  03de move-wide/from16 v17, v9
  03e2 const/4 v8, 0
  03e4 invoke-virtual v11, Ljava/io/File;->delete()Z
  03ea monitor-enter v19
  03ec iget v1, v7, Lcom/personal/aihub/PreviewServer;->preparing I
  03f0 sub-int/2addr v1, v13
  03f2 iput v1, v7, Lcom/personal/aihub/PreviewServer;->preparing I
  03f6 if-nez v8, +011h
  03fa iget-wide v1, v7, Lcom/personal/aihub/PreviewServer;->preparedBytes J
  03fe sub-long v1, v1, v17
  0402 const-wide/16 v3, 0
  0406 invoke-static v3, v4, v1, v2, Ljava/lang/Math;->max(J J)J
  040c move-result-wide v1
  040e iput-wide v1, v7, Lcom/personal/aihub/PreviewServer;->preparedBytes J
  0412 invoke-virtual v12, Ljava/io/File;->delete()Z
  0418 monitor-exit v19
  041a throw v0
  041c move-exception v0
  041e monitor-exit v19
  0420 throw v0
  0422 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  0428 move-result-object v4
  042a const-string v0, "Temporary movie storage is full. Return to the Studio and reopen the preview."
  042e sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0432 invoke-virtual v0, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0438 move-result-object v5
  043a const/4 v6, 0
  043c const/16 v3, 507
  0440 move-object/from16 v1, v19
  0444 move-object/from16 v2, v20
  0448 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  044e monitor-exit v19
  0450 return-void 
  0452 move-exception v0
  0454 monitor-exit v19
  0456 throw v0
  0458 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  045e move-result-object v4
  0460 const/4 v1, 0
  0462 new-array v5, v1, [B
  0466 const/4 v6, 0
  0468 const/16 v3, 413
  046c move-object/from16 v1, v19
  0470 move-object/from16 v2, v20
  0474 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  047a return-void 
  047c new-instance v0, Ljava/lang/NumberFormatException;
  0480 invoke-direct v0, Ljava/lang/NumberFormatException;-><init>()V
  0486 throw v0
  0488 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  048e move-result-object v4
  0490 const/4 v1, 0
  0492 new-array v5, v1, [B
  0496 const/4 v6, 0
  0498 const/16 v3, 411
  049c move-object/from16 v1, v19
  04a0 move-object/from16 v2, v20
  04a4 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  04aa return-void 
  04ac fill-array-data-payload b'ftyp' | \x66\x74\x79\x70
.end method

.method range(Ljava/lang/String; J)[J
  0000 const-wide/16 v0, 0
  0004 cmp-long v2, v11, v0
  0008 const/4 v3, 0
  000a if-lez v2, +05eh
  000e const-string v2, "bytes=([0-9]+-[0-9]*|-[0-9]+)"
  0012 invoke-virtual v10, v2, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0018 move-result v2
  001a if-eqz v2, +056h
  001e const/4 v2, 6
  0020 invoke-virtual v10, v2, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0026 move-result-object v10
  0028 const-string v2, "-"
  002c const/4 v4, -1
  002e invoke-virtual v10, v2, v4, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  0034 move-result-object v10
  0036 const-wide/16 v4, 1
  003a sub-long v4, v11, v4
  003e const/4 v2, 0
  0040 aget-object v6, v10, v2
  0044 invoke-virtual v6, Ljava/lang/String;->isEmpty()Z
  004a move-result v6
  004c const/4 v7, 1
  004e if-eqz v6, +014h
  0052 aget-object v10, v10, v7
  0056 invoke-static v10, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  005c move-result-wide v8
  005e cmp-long v10, v8, v0
  0062 if-gtz v10, +003h
  0066 return-object v3
  0068 sub-long v8, v11, v8
  006c invoke-static v0, v1, v8, v9, Ljava/lang/Math;->max(J J)J
  0072 move-result-wide v0
  0074 goto +19h
  0076 aget-object v0, v10, v2
  007a invoke-static v0, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  0080 move-result-wide v0
  0082 aget-object v6, v10, v7
  0086 invoke-virtual v6, Ljava/lang/String;->isEmpty()Z
  008c move-result v6
  008e if-nez v6, +00ch
  0092 aget-object v10, v10, v7
  0096 invoke-static v10, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  009c move-result-wide v8
  009e invoke-static v4, v5, v8, v9, Ljava/lang/Math;->min(J J)J
  00a4 move-result-wide v4
  00a6 cmp-long v10, v0, v11
  00aa if-gez v10, +00eh
  00ae cmp-long v10, v4, v0
  00b2 if-ltz v10, +00ah
  00b6 const/4 v10, 2
  00b8 new-array v10, v10, [J
  00bc aput-wide v0, v10, v2
  00c0 aput-wide v4, v10, v7
  00c4 return-object v10
  00c6 return-object v3
.end method

.method read(Ljava/net/Socket;)Lcom/personal/aihub/PreviewServer$Request;
  0000 new-instance v0, Ljava/io/BufferedInputStream;
  0004 invoke-virtual v11, Ljava/net/Socket;->getInputStream()Ljava/io/InputStream;
  000a move-result-object v11
  000c const/16 v1, 8192
  0010 invoke-direct v0, v11, v1, Ljava/io/BufferedInputStream;-><init>(Ljava/io/InputStream; I)V
  0016 new-instance v11, Ljava/io/ByteArrayOutputStream;
  001a invoke-direct v11, Ljava/io/ByteArrayOutputStream;-><init>()V
  0020 const/4 v2, 0
  0022 move v3, v2
  0024 invoke-virtual v11, Ljava/io/ByteArrayOutputStream;->size()I
  002a move-result v4
  002c const/16 v5, 16384
  0030 const v6, 218762506
  0036 if-ge v4, v5, +019h
  003a invoke-virtual v0, Ljava/io/BufferedInputStream;->read()I
  0040 move-result v4
  0042 if-ltz v4, +00dh
  0046 invoke-virtual v11, v4, Ljava/io/ByteArrayOutputStream;->write(I)V
  004c shl-int/lit8 v3, v3, 8
  0050 and-int/lit16 v4, v4, 255
  0054 or-int/2addr v3, v4
  0056 if-ne v3, v6, -019h
  005a goto +7h
  005c new-instance v11, Ljava/io/EOFException;
  0060 invoke-direct v11, Ljava/io/EOFException;-><init>()V
  0066 throw v11
  0068 if-ne v3, v6, +161h
  006c new-instance v3, Ljava/lang/String;
  0070 invoke-virtual v11, Ljava/io/ByteArrayOutputStream;->toByteArray()[B
  0076 move-result-object v11
  0078 sget-object v4, Ljava/nio/charset/StandardCharsets;->ISO_8859_1 Ljava/nio/charset/Charset;
  007c invoke-direct v3, v11, v4, Ljava/lang/String;-><init>([B Ljava/nio/charset/Charset;)V
  0082 invoke-virtual v3, Ljava/lang/String;->length()I
  0088 move-result v11
  008a add-int/lit8 v11, v11, -4
  008e invoke-virtual v3, v2, v11, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  0094 move-result-object v11
  0096 const-string v3, "
"
  009a invoke-virtual v11, v3, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  00a0 move-result-object v11
  00a2 aget-object v3, v11, v2
  00a6 const-string v4, " "
  00aa const/4 v5, -1
  00ac invoke-virtual v3, v4, v5, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  00b2 move-result-object v3
  00b4 array-length v4, v3
  00b6 const/4 v6, 3
  00b8 if-ne v4, v6, +131h
  00bc const/4 v4, 2
  00be aget-object v4, v3, v4
  00c2 const-string v6, "HTTP/1.1"
  00c6 invoke-virtual v4, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00cc move-result v4
  00ce if-eqz v4, +126h
  00d2 aget-object v4, v3, v2
  00d6 const-string v6, "[A-Z]{3,8}"
  00da invoke-virtual v4, v6, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  00e0 move-result v4
  00e2 if-eqz v4, +11ch
  00e6 const/4 v4, 1
  00e8 aget-object v6, v3, v4
  00ec const-string v7, "/"
  00f0 invoke-virtual v6, v7, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00f6 move-result v6
  00f8 if-eqz v6, +111h
  00fc aget-object v6, v3, v4
  0100 const-string v8, "//"
  0104 invoke-virtual v6, v8, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  010a move-result v6
  010c if-nez v6, +107h
  0110 aget-object v6, v3, v4
  0114 const-string v8, "\"
  0118 invoke-virtual v6, v8, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  011e move-result v6
  0120 if-nez v6, +0fdh
  0124 aget-object v6, v3, v4
  0128 invoke-virtual v6, Ljava/lang/String;->length()I
  012e move-result v6
  0130 if-gt v6, v1, +0f5h
  0134 new-instance v1, Lcom/personal/aihub/PreviewServer$Request;
  0138 const/4 v6, 0
  013a invoke-direct v1, v6, Lcom/personal/aihub/PreviewServer$Request;-><init>(Lcom/personal/aihub/PreviewServer$Request;)V
  0140 aget-object v6, v3, v2
  0144 iput-object v6, v1, Lcom/personal/aihub/PreviewServer$Request;->method Ljava/lang/String;
  0148 aget-object v3, v3, v4
  014c iput-object v3, v1, Lcom/personal/aihub/PreviewServer$Request;->target Ljava/lang/String;
  0150 new-instance v3, Ljava/net/URI;
  0154 iget-object v6, v1, Lcom/personal/aihub/PreviewServer$Request;->target Ljava/lang/String;
  0158 invoke-direct v3, v6, Ljava/net/URI;-><init>(Ljava/lang/String;)V
  015e iput-object v3, v1, Lcom/personal/aihub/PreviewServer$Request;->uri Ljava/net/URI;
  0162 iput-object v0, v1, Lcom/personal/aihub/PreviewServer$Request;->input Ljava/io/BufferedInputStream;
  0166 iget-object v0, v1, Lcom/personal/aihub/PreviewServer$Request;->uri Ljava/net/URI;
  016a invoke-virtual v0, Ljava/net/URI;->getHost()Ljava/lang/String;
  0170 move-result-object v0
  0172 if-nez v0, +0cch
  0176 iget-object v0, v1, Lcom/personal/aihub/PreviewServer$Request;->uri Ljava/net/URI;
  017a invoke-virtual v0, Ljava/net/URI;->getFragment()Ljava/lang/String;
  0180 move-result-object v0
  0182 if-nez v0, +0c4h
  0186 iget-object v0, v1, Lcom/personal/aihub/PreviewServer$Request;->uri Ljava/net/URI;
  018a invoke-virtual v0, Ljava/net/URI;->getPath()Ljava/lang/String;
  0190 move-result-object v0
  0192 invoke-virtual v0, v7, v5, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  0198 move-result-object v3
  019a array-length v5, v3
  019c move v6, v2
  019e const-string v7, "Unsafe request path"
  01a2 if-ge v6, v5, +025h
  01a6 aget-object v8, v3, v6
  01aa const-string v9, "."
  01ae invoke-virtual v8, v9, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01b4 move-result v9
  01b6 if-nez v9, +015h
  01ba const-string v9, ".."
  01be invoke-virtual v8, v9, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01c4 move-result v9
  01c6 if-nez v9, +00dh
  01ca const/16 v9, 92
  01ce invoke-virtual v8, v9, Ljava/lang/String;->indexOf(I)I
  01d4 move-result v8
  01d6 if-gez v8, +005h
  01da add-int/lit8 v6, v6, 1
  01de goto -20h
  01e0 new-instance v11, Ljava/io/IOException;
  01e4 invoke-direct v11, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01ea throw v11
  01ec invoke-virtual v0, Ljava/lang/String;->toCharArray()[C
  01f2 move-result-object v0
  01f4 array-length v3, v0
  01f6 move v5, v2
  01f8 const/16 v6, 127
  01fc const/16 v8, 32
  0200 if-ge v5, v3, +011h
  0204 aget-char v9, v0, v5
  0208 if-lt v9, v8, +007h
  020c if-eq v9, v6, +005h
  0210 add-int/lit8 v5, v5, 1
  0214 goto -eh
  0216 new-instance v11, Ljava/io/IOException;
  021a invoke-direct v11, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0220 throw v11
  0222 array-length v0, v11
  0224 const/16 v3, 65
  0228 if-gt v0, v3, +069h
  022c move v0, v4
  022e array-length v3, v11
  0230 if-ge v0, v3, +064h
  0234 aget-object v3, v11, v0
  0238 const/16 v5, 58
  023c invoke-virtual v3, v5, Ljava/lang/String;->indexOf(I)I
  0242 move-result v3
  0244 if-lt v3, v4, +052h
  0248 aget-object v5, v11, v0
  024c invoke-virtual v5, v2, v3, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  0252 move-result-object v5
  0254 sget-object v7, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  0258 invoke-virtual v5, v7, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  025e move-result-object v5
  0260 aget-object v7, v11, v0
  0264 add-int/lit8 v3, v3, 1
  0268 invoke-virtual v7, v3, Ljava/lang/String;->substring(I)Ljava/lang/String;
  026e move-result-object v3
  0270 invoke-virtual v3, Ljava/lang/String;->trim()Ljava/lang/String;
  0276 move-result-object v3
  0278 const-string v7, "[a-z0-9-]{1,80}"
  027c invoke-virtual v5, v7, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0282 move-result v7
  0284 if-eqz v7, +02ah
  0288 iget-object v7, v1, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  028c invoke-interface v7, v5, v3, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0292 move-result-object v5
  0294 if-nez v5, +022h
  0298 invoke-virtual v3, Ljava/lang/String;->toCharArray()[C
  029e move-result-object v3
  02a0 array-length v5, v3
  02a2 move v7, v2
  02a4 if-ge v7, v5, +017h
  02a8 aget-char v9, v3, v7
  02ac if-ge v9, v8, +006h
  02b0 const/16 v10, 9
  02b4 if-ne v9, v10, +007h
  02b8 if-eq v9, v6, +005h
  02bc add-int/lit8 v7, v7, 1
  02c0 goto -eh
  02c2 new-instance v11, Ljava/io/IOException;
  02c6 const-string v0, "Unsafe HTTP header"
  02ca invoke-direct v11, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02d0 throw v11
  02d2 add-int/lit8 v0, v0, 1
  02d6 goto -54h
  02d8 new-instance v11, Ljava/io/IOException;
  02dc const-string v0, "Duplicate/invalid HTTP header"
  02e0 invoke-direct v11, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02e6 throw v11
  02e8 new-instance v11, Ljava/io/IOException;
  02ec const-string v0, "Invalid HTTP header"
  02f0 invoke-direct v11, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02f6 throw v11
  02f8 return-object v1
  02fa new-instance v11, Ljava/io/IOException;
  02fe const-string v0, "Too many HTTP headers"
  0302 invoke-direct v11, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0308 throw v11
  030a new-instance v11, Ljava/io/IOException;
  030e const-string v0, "Invalid request target"
  0312 invoke-direct v11, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0318 throw v11
  031a new-instance v11, Ljava/io/IOException;
  031e const-string v0, "Invalid HTTP request"
  0322 invoke-direct v11, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0328 throw v11
  032a new-instance v11, Ljava/io/IOException;
  032e const-string v0, "HTTP headers exceed limit"
  0332 invoke-direct v11, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0338 throw v11
.end method

.method readBytes(Ljava/io/InputStream; I)[B
  0000 new-instance v0, Ljava/io/ByteArrayOutputStream;
  0004 invoke-direct v0, Ljava/io/ByteArrayOutputStream;-><init>()V
  000a const/16 v1, 8192
  000e new-array v1, v1, [B
  0012 invoke-virtual v4, v1, Ljava/io/InputStream;->read([B)I
  0018 move-result v2
  001a const/4 v3, -1
  001c if-ne v2, v3, +007h
  0020 invoke-virtual v0, Ljava/io/ByteArrayOutputStream;->toByteArray()[B
  0026 move-result-object v4
  0028 return-object v4
  002a invoke-virtual v0, Ljava/io/ByteArrayOutputStream;->size()I
  0030 move-result v3
  0032 sub-int v3, v5, v3
  0036 if-gt v2, v3, +007h
  003a const/4 v3, 0
  003c invoke-virtual v0, v1, v3, v2, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  0042 goto -18h
  0044 new-instance v4, Ljava/io/IOException;
  0048 const-string v5, "Preview text exceeds the size limit"
  004c invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0052 throw v4
.end method

.method remove(Ljava/io/File;)V
  0000 invoke-virtual v4, Ljava/io/File;->listFiles()[Ljava/io/File;
  0006 move-result-object v0
  0008 if-eqz v0, +00eh
  000c array-length v1, v0
  000e const/4 v2, 0
  0010 if-ge v2, v1, +00ah
  0014 aget-object v3, v0, v2
  0018 invoke-static v3, Lcom/personal/aihub/PreviewServer;->remove(Ljava/io/File;)V
  001e add-int/lit8 v2, v2, 1
  0022 goto -9h
  0024 invoke-virtual v4, Ljava/io/File;->delete()Z
  002a return-void 
.end method

.method respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0000 array-length v0, v11
  0002 int-to-long v5, v0
  0004 move-object v1, v7
  0006 move-object v2, v8
  0008 move v3, v9
  000a move-object v4, v10
  000c invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->writeHeaders(Ljava/net/Socket; I Ljava/util/Map; J)V
  0012 if-eqz v12, +003h
  0016 return-void 
  0018 invoke-virtual v8, Ljava/net/Socket;->getOutputStream()Ljava/io/OutputStream;
  001e move-result-object v9
  0020 invoke-virtual v9, v11, Ljava/io/OutputStream;->write([B)V
  0026 invoke-virtual v8, Ljava/net/Socket;->getOutputStream()Ljava/io/OutputStream;
  002c move-result-object v8
  002e invoke-virtual v8, Ljava/io/OutputStream;->flush()V
  0034 return-void 
.end method

.method rewrite(Ljava/lang/String;)Ljava/lang/String;
  0000 new-instance v0, Ljava/lang/StringBuilder;
  0004 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  000a iget-object v1, v8, Lcom/personal/aihub/PreviewServer;->origin Ljava/lang/String;
  000e invoke-static v1, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0014 move-result-object v1
  0016 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  001c const-string v1, "/cdn/uncompressed"
  0020 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0026 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  002c move-result-object v0
  002e const-string v1, "https://cdn.dokkan-eclipse.com/uncompressed"
  0032 filled-new-array v1, v0, [Ljava/lang/String;
  0038 move-result-object v0
  003a const-string v1, "https://dokkan-eclipse.com"
  003e iget-object v2, v8, Lcom/personal/aihub/PreviewServer;->origin Ljava/lang/String;
  0042 filled-new-array v1, v2, [Ljava/lang/String;
  0048 move-result-object v1
  004a filled-new-array v0, v1, [[Ljava/lang/String;
  0050 move-result-object v0
  0052 const/4 v1, 0
  0054 move v2, v1
  0056 const/4 v3, 2
  0058 if-ge v2, v3, +024h
  005c aget-object v3, v0, v2
  0060 aget-object v4, v3, v1
  0064 const/4 v5, 1
  0066 aget-object v6, v3, v5
  006a invoke-virtual v9, v4, v6, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  0070 move-result-object v9
  0072 aget-object v4, v3, v1
  0076 const-string v6, "/"
  007a const-string v7, "\/"
  007e invoke-virtual v4, v6, v7, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  0084 move-result-object v4
  0086 aget-object v3, v3, v5
  008a invoke-virtual v3, v6, v7, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  0090 move-result-object v3
  0092 invoke-virtual v9, v4, v3, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  0098 move-result-object v9
  009a add-int/lit8 v2, v2, 1
  009e goto -24h
  00a0 return-object v9
.end method

.method sendBytes(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request; Ljava/util/Map; [B)V
  0000 new-instance v7, Ljava/io/ByteArrayInputStream;
  0004 invoke-direct v7, v12, Ljava/io/ByteArrayInputStream;-><init>([B)V
  000a new-instance v3, Ljava/util/HashMap;
  000e invoke-direct v3, v11, Ljava/util/HashMap;-><init>(Ljava/util/Map;)V
  0014 array-length v11, v12
  0016 int-to-long v5, v11
  0018 move-object v0, v8
  001a move-object v1, v9
  001c move-object v2, v10
  001e move-object v4, v7
  0020 invoke-direct/range v0 ... v6, Lcom/personal/aihub/PreviewServer;->sendStream(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request; Ljava/util/Map; Ljava/io/InputStream; J)V
  0026 invoke-virtual v7, Ljava/io/ByteArrayInputStream;->close()V
  002c return-void 
  002e move-exception v9
  0030 invoke-virtual v7, Ljava/io/ByteArrayInputStream;->close()V
  0036 throw v9
.end method

.method sendStream(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request; Ljava/util/Map; Ljava/io/InputStream; J)V
  0000 move-object/from16 v0, v17
  0004 move-object/from16 v1, v19
  0008 move-wide/from16 v2, v20
  000c new-instance v5, Ljava/util/HashMap;
  0010 move-object/from16 v4, v18
  0014 invoke-direct v5, v4, Ljava/util/HashMap;-><init>(Ljava/util/Map;)V
  001a const-wide/16 v8, 1
  001e sub-long v6, v2, v8
  0022 iget-object v4, v0, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  0026 const-string v10, "range"
  002a invoke-interface v4, v10, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0030 move-result-object v4
  0032 check-cast v4, Ljava/lang/String;
  0036 const-string v10, "HEAD"
  003a const/4 v11, 0
  003c if-eqz v4, +059h
  0040 invoke-static v4, v2, v3, Lcom/personal/aihub/PreviewServer;->range(Ljava/lang/String; J)[J
  0046 move-result-object v4
  0048 const-string v6, "Content-Range"
  004c if-nez v4, +026h
  0050 new-instance v1, Ljava/lang/StringBuilder;
  0054 const-string v4, "bytes */"
  0058 invoke-direct v1, v4, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  005e invoke-virtual v1, v2, v3, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0064 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  006a move-result-object v1
  006c invoke-virtual v5, v6, v1, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0072 new-array v4, v11, [B
  0076 iget-object v0, v0, Lcom/personal/aihub/PreviewServer$Request;->method Ljava/lang/String;
  007a invoke-virtual v0, v10, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0080 move-result v6
  0082 const/16 v2, 416
  0086 move-object v0, v15
  0088 move-object/from16 v1, v16
  008c move-object v3, v5
  008e move v5, v6
  0090 invoke-direct/range v0 ... v5, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0096 return-void 
  0098 aget-wide v13, v4, v11
  009c const/4 v7, 1
  009e aget-wide v11, v4, v7
  00a2 new-instance v4, Ljava/lang/StringBuilder;
  00a6 const-string v7, "bytes "
  00aa invoke-direct v4, v7, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00b0 invoke-virtual v4, v13, v14, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  00b6 const-string v7, "-"
  00ba invoke-virtual v4, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00c0 invoke-virtual v4, v11, v12, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  00c6 const-string v7, "/"
  00ca invoke-virtual v4, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00d0 invoke-virtual v4, v2, v3, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  00d6 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00dc move-result-object v2
  00de invoke-virtual v5, v6, v2, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  00e4 const/16 v2, 206
  00e8 move v4, v2
  00ea move-wide v6, v11
  00ec goto +6h
  00ee const/16 v2, 200
  00f2 move v4, v2
  00f4 const-wide/16 v13, 0
  00f8 sub-long/2addr v6, v13
  00fa add-long v11, v6, v8
  00fe move-object v2, v15
  0100 move-object/from16 v3, v16
  0104 move-wide v6, v11
  0106 invoke-direct/range v2 ... v7, Lcom/personal/aihub/PreviewServer;->writeHeaders(Ljava/net/Socket; I Ljava/util/Map; J)V
  010c iget-object v0, v0, Lcom/personal/aihub/PreviewServer$Request;->method Ljava/lang/String;
  0110 invoke-virtual v0, v10, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0116 move-result v0
  0118 if-eqz v0, +003h
  011c return-void 
  011e const-wide/16 v2, 0
  0122 cmp-long v0, v2, v13
  0126 if-gez v0, +01eh
  012a sub-long v4, v13, v2
  012e invoke-virtual v1, v4, v5, Ljava/io/InputStream;->skip(J)J
  0134 move-result-wide v4
  0136 const-wide/16 v6, 0
  013a cmp-long v0, v4, v6
  013e if-gtz v0, +010h
  0142 invoke-virtual/range v19, Ljava/io/InputStream;->read()I
  0148 move-result v0
  014a if-ltz v0, +004h
  014e move-wide v4, v8
  0150 goto +7h
  0152 new-instance v0, Ljava/io/EOFException;
  0156 invoke-direct v0, Ljava/io/EOFException;-><init>()V
  015c throw v0
  015e add-long/2addr v2, v4
  0160 goto -1fh
  0162 invoke-virtual/range v16, Ljava/net/Socket;->getOutputStream()Ljava/io/OutputStream;
  0168 move-result-object v0
  016a const/high16 v2, 65536
  016e new-array v2, v2, [B
  0172 const-wide/16 v3, 0
  0176 cmp-long v5, v11, v3
  017a if-lez v5, +01dh
  017e const-wide/32 v5, 65536
  0184 invoke-static v5, v6, v11, v12, Ljava/lang/Math;->min(J J)J
  018a move-result-wide v5
  018c long-to-int v5, v5
  018e const/4 v6, 0
  0190 invoke-virtual v1, v2, v6, v5, Ljava/io/InputStream;->read([B I I)I
  0196 move-result v5
  0198 if-ltz v5, +008h
  019c invoke-virtual v0, v2, v6, v5, Ljava/io/OutputStream;->write([B I I)V
  01a2 int-to-long v7, v5
  01a4 sub-long/2addr v11, v7
  01a6 goto -18h
  01a8 new-instance v0, Ljava/io/EOFException;
  01ac invoke-direct v0, Ljava/io/EOFException;-><init>()V
  01b2 throw v0
  01b4 invoke-virtual v0, Ljava/io/OutputStream;->flush()V
  01ba return-void 
.end method

.method serve(Ljava/net/Socket;)V
  0000 move-object/from16 v8, v22
  0004 move-object/from16 v9, v23
  0008 const-string v0, "/tools/"
  000c const-string v1, "/_forge/open/"
  0010 const-string v2, "127.0.0.1:"
  0014 const/4 v10, 0
  0016 invoke-static/range v23, Lcom/personal/aihub/PreviewServer;->read(Ljava/net/Socket;)Lcom/personal/aihub/PreviewServer$Request;
  001c move-result-object v3
  001e new-instance v4, Ljava/lang/StringBuilder;
  0022 invoke-direct v4, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0028 iget-object v2, v8, Lcom/personal/aihub/PreviewServer;->listener Ljava/net/ServerSocket;
  002c invoke-virtual v2, Ljava/net/ServerSocket;->getLocalPort()I
  0032 move-result v2
  0034 invoke-virtual v4, v2, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  003a invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0040 move-result-object v2
  0042 iget-object v4, v3, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  0046 const-string v5, "host"
  004a invoke-interface v4, v5, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0050 move-result-object v4
  0052 invoke-virtual v2, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0058 move-result v2
  005a if-nez v2, +013h
  005e invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  0064 move-result-object v4
  0066 new-array v5, v10, [B
  006a const/4 v6, 0
  006c const/16 v3, 403
  0070 move-object/from16 v1, v22
  0074 move-object/from16 v2, v23
  0078 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  007e return-void 
  0080 iget-object v2, v3, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  0084 const-string v4, "transfer-encoding"
  0088 invoke-interface v2, v4, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z
  008e move-result v2
  0090 if-nez v2, +785h
  0094 iget-object v2, v3, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  0098 const-string v4, "expect"
  009c invoke-interface v2, v4, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z
  00a2 move-result v2
  00a4 if-eqz v2, +004h
  00a8 goto/16 +779h
  00ac iget-object v2, v3, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  00b0 const-string v4, "origin"
  00b4 invoke-interface v2, v4, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z
  00ba move-result v2
  00bc if-eqz v2, +023h
  00c0 iget-object v2, v8, Lcom/personal/aihub/PreviewServer;->origin Ljava/lang/String;
  00c4 iget-object v4, v3, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  00c8 const-string v5, "origin"
  00cc invoke-interface v4, v5, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  00d2 move-result-object v4
  00d4 invoke-virtual v2, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00da move-result v2
  00dc if-nez v2, +013h
  00e0 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  00e6 move-result-object v4
  00e8 new-array v5, v10, [B
  00ec const/4 v6, 0
  00ee const/16 v3, 403
  00f2 move-object/from16 v1, v22
  00f6 move-object/from16 v2, v23
  00fa invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0100 return-void 
  0102 iget-object v2, v3, Lcom/personal/aihub/PreviewServer$Request;->uri Ljava/net/URI;
  0106 invoke-virtual v2, Ljava/net/URI;->getPath()Ljava/lang/String;
  010c move-result-object v2
  010e iget-object v4, v3, Lcom/personal/aihub/PreviewServer$Request;->method Ljava/lang/String;
  0112 const-string v5, "HEAD"
  0116 invoke-virtual v4, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  011c move-result v11
  011e iget-object v4, v3, Lcom/personal/aihub/PreviewServer$Request;->method Ljava/lang/String;
  0122 const-string v5, "GET"
  0126 invoke-virtual v4, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  012c move-result v4
  012e if-nez v4, +004h
  0132 if-eqz v11, +07ch
  0136 new-instance v4, Ljava/lang/StringBuilder;
  013a invoke-direct v4, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0140 iget-object v1, v8, Lcom/personal/aihub/PreviewServer;->token Ljava/lang/String;
  0144 invoke-virtual v4, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  014a invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0150 move-result-object v1
  0152 invoke-virtual v2, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0158 move-result v1
  015a if-eqz v1, +068h
  015e iget-object v1, v3, Lcom/personal/aihub/PreviewServer$Request;->target Ljava/lang/String;
  0162 invoke-static v1, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  0168 move-result-object v1
  016a const-string v2, "tool"
  016e invoke-virtual v1, v2, Landroid/net/Uri;->getQueryParameter(Ljava/lang/String;)Ljava/lang/String;
  0174 move-result-object v1
  0176 const-string v2, "lua-player"
  017a const-string v3, "lwf-player"
  017e const-string v4, "usm-player"
  0182 filled-new-array v2, v3, v4, [Ljava/lang/String;
  0188 move-result-object v2
  018a invoke-static v2, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  0190 move-result-object v2
  0192 invoke-interface v2, v1, Ljava/util/List;->contains(Ljava/lang/Object;)Z
  0198 move-result v2
  019a if-nez v2, +004h
  019e const-string v1, "lua-player"
  01a2 new-instance v4, Ljava/util/HashMap;
  01a6 invoke-direct v4, Ljava/util/HashMap;-><init>()V
  01ac const-string v2, "Location"
  01b0 new-instance v3, Ljava/lang/StringBuilder;
  01b4 invoke-direct v3, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  01ba invoke-virtual v3, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01c0 const-string v0, "/"
  01c4 invoke-virtual v3, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01ca invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01d0 move-result-object v0
  01d2 invoke-virtual v4, v2, v0, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  01d8 const-string v0, "Set-Cookie"
  01dc new-instance v1, Ljava/lang/StringBuilder;
  01e0 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  01e6 iget-object v2, v8, Lcom/personal/aihub/PreviewServer;->cookie Ljava/lang/String;
  01ea invoke-static v2, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  01f0 move-result-object v2
  01f2 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01f8 const-string v2, "; Path=/; HttpOnly; SameSite=Strict"
  01fc invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0202 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0208 move-result-object v1
  020a invoke-virtual v4, v0, v1, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0210 new-array v5, v10, [B
  0214 const/16 v3, 302
  0218 move-object/from16 v1, v22
  021c move-object/from16 v2, v23
  0220 move v6, v11
  0222 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0228 return-void 
  022a iget-object v0, v3, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  022e const-string v1, "cookie"
  0232 const-string v4, ""
  0236 invoke-interface v0, v1, v4, Ljava/util/Map;->getOrDefault(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  023c move-result-object v0
  023e check-cast v0, Ljava/lang/String;
  0242 const-string v1, ";"
  0246 invoke-virtual v0, v1, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  024c move-result-object v0
  024e array-length v1, v0
  0250 move v4, v10
  0252 move v5, v4
  0254 if-ge v4, v1, +014h
  0258 aget-object v6, v0, v4
  025c invoke-virtual v6, Ljava/lang/String;->trim()Ljava/lang/String;
  0262 move-result-object v6
  0264 iget-object v7, v8, Lcom/personal/aihub/PreviewServer;->cookie Ljava/lang/String;
  0268 invoke-virtual v6, v7, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  026e move-result v6
  0270 if-eqz v6, +003h
  0274 const/4 v5, 1
  0276 add-int/lit8 v4, v4, 1
  027a goto -13h
  027c if-eqz v5, +67eh
  0280 iget-object v0, v3, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  0284 const-string v1, "origin"
  0288 invoke-interface v0, v1, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z
  028e move-result v0
  0290 if-eqz v0, +014h
  0294 iget-object v0, v8, Lcom/personal/aihub/PreviewServer;->origin Ljava/lang/String;
  0298 iget-object v1, v3, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  029c const-string v4, "origin"
  02a0 invoke-interface v1, v4, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  02a6 move-result-object v1
  02a8 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  02ae move-result v0
  02b0 if-nez v0, +004h
  02b4 goto/16 +662h
  02b8 iget-object v0, v3, Lcom/personal/aihub/PreviewServer$Request;->method Ljava/lang/String;
  02bc const-string v1, "POST"
  02c0 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  02c6 move-result v0
  02c8 if-eqz v0, +016h
  02cc const-string v0, "/_forge/prepared-movies"
  02d0 invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  02d6 move-result v0
  02d8 if-eqz v0, +00eh
  02dc iget-object v0, v3, Lcom/personal/aihub/PreviewServer$Request;->uri Ljava/net/URI;
  02e0 invoke-virtual v0, Ljava/net/URI;->getRawQuery()Ljava/lang/String;
  02e6 move-result-object v0
  02e8 if-nez v0, +006h
  02ec invoke-direct v8, v9, v3, Lcom/personal/aihub/PreviewServer;->prepare(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request;)V
  02f2 return-void 
  02f4 iget-object v0, v3, Lcom/personal/aihub/PreviewServer$Request;->method Ljava/lang/String;
  02f8 const-string v1, "DELETE"
  02fc invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0302 move-result v0
  0304 if-eqz v0, +00eh
  0308 const-string v0, "/_forge/prepared-movies/"
  030c invoke-virtual v2, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0312 move-result v0
  0314 if-eqz v0, +006h
  0318 invoke-direct v8, v9, v3, Lcom/personal/aihub/PreviewServer;->deleteMovie(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request;)V
  031e return-void 
  0320 iget-object v0, v3, Lcom/personal/aihub/PreviewServer$Request;->method Ljava/lang/String;
  0324 const-string v1, "GET"
  0328 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  032e move-result v0
  0330 if-nez v0, +015h
  0334 if-nez v11, +013h
  0338 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  033e move-result-object v4
  0340 new-array v5, v10, [B
  0344 const/4 v6, 0
  0346 const/16 v3, 405
  034a move-object/from16 v1, v22
  034e move-object/from16 v2, v23
  0352 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0358 return-void 
  035a iget-object v0, v3, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  035e const-string v1, "content-length"
  0362 invoke-interface v0, v1, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z
  0368 move-result v0
  036a if-eqz v0, +025h
  036e iget-object v0, v3, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  0372 const-string v1, "content-length"
  0376 invoke-interface v0, v1, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  037c move-result-object v0
  037e check-cast v0, Ljava/lang/String;
  0382 const-string v1, "0"
  0386 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  038c move-result v0
  038e if-nez v0, +013h
  0392 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  0398 move-result-object v4
  039a new-array v5, v10, [B
  039e const/16 v3, 400
  03a2 move-object/from16 v1, v22
  03a6 move-object/from16 v2, v23
  03aa move v6, v11
  03ac invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  03b2 return-void 
  03b4 const-string v0, "/_forge/prepared-movies/"
  03b8 invoke-virtual v2, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  03be move-result v0
  03c0 if-eqz v0, +006h
  03c4 invoke-direct v8, v9, v3, Lcom/personal/aihub/PreviewServer;->movie(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request;)V
  03ca return-void 
  03cc const-string v0, "/_forge/stage-export/"
  03d0 invoke-virtual v2, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  03d6 move-result v0
  03d8 const-wide/32 v4, 167772160
  03de if-eqz v0, +0c8h
  03e2 iget-object v0, v3, Lcom/personal/aihub/PreviewServer$Request;->uri Ljava/net/URI;
  03e6 invoke-virtual v0, Ljava/net/URI;->getRawQuery()Ljava/lang/String;
  03ec move-result-object v0
  03ee if-eqz v0, +013h
  03f2 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  03f8 move-result-object v4
  03fa new-array v5, v10, [B
  03fe const/16 v3, 404
  0402 move-object/from16 v1, v22
  0406 move-object/from16 v2, v23
  040a move v6, v11
  040c invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0412 return-void 
  0414 if-eqz v11, +013h
  0418 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  041e move-result-object v4
  0420 new-array v5, v10, [B
  0424 const/4 v6, 1
  0426 const/16 v3, 405
  042a move-object/from16 v1, v22
  042e move-object/from16 v2, v23
  0432 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0438 return-void 
  043a const/16 v0, 21
  043e invoke-virtual v2, v0, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0444 move-result-object v0
  0446 monitor-enter v22
  0448 iget-object v1, v8, Lcom/personal/aihub/PreviewServer;->movies Ljava/util/Map;
  044c invoke-interface v1, v0, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0452 move-result-object v1
  0454 check-cast v1, Ljava/io/File;
  0458 monitor-exit v22
  045a const-string v2, "[a-f0-9]{32}\.mp4"
  045e invoke-virtual v0, v2, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0464 move-result v0
  0466 if-eqz v0, +070h
  046a if-eqz v1, +06eh
  046e invoke-virtual v1, Ljava/io/File;->isFile()Z
  0474 move-result v0
  0476 if-eqz v0, +068h
  047a invoke-virtual v1, Ljava/io/File;->length()J
  0480 move-result-wide v6
  0482 const-wide/16 v11, 12
  0486 cmp-long v0, v6, v11
  048a if-ltz v0, +05eh
  048e invoke-virtual v1, Ljava/io/File;->length()J
  0494 move-result-wide v6
  0496 cmp-long v0, v6, v4
  049a if-lez v0, +003h
  049e goto +54h
  04a0 iget-object v0, v8, Lcom/personal/aihub/PreviewServer;->stageExport Lcom/personal/aihub/StageExport;
  04a4 if-eqz v0, +027h
  04a8 const-string v2, "Content-Type"
  04ac const-string v4, "application/json"
  04b0 invoke-static v2, v4, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  04b6 move-result-object v2
  04b8 new-instance v4, Lorg/json/JSONObject;
  04bc invoke-direct v4, Lorg/json/JSONObject;-><init>()V
  04c2 const-string v5, "saved"
  04c6 invoke-virtual v0, v1, Lcom/personal/aihub/StageExport;->save(Ljava/io/File;)Z
  04cc move-result v0
  04ce invoke-virtual v4, v5, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  04d4 move-result-object v0
  04d6 invoke-virtual v0, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  04dc move-result-object v0
  04de sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  04e2 invoke-virtual v0, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  04e8 move-result-object v0
  04ea invoke-direct v8, v9, v3, v2, v0, Lcom/personal/aihub/PreviewServer;->sendBytes(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request; Ljava/util/Map; [B)V
  04f0 return-void 
  04f2 new-instance v0, Ljava/io/IOException;
  04f6 const-string v1, "The owning preview cannot save this recording."
  04fa invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0500 throw v0
  0502 move-exception v0
  0504 const-string v1, "Content-Type"
  0508 const-string v2, "text/plain"
  050c invoke-static v1, v2, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  0512 move-result-object v4
  0514 invoke-virtual v0, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  051a move-result-object v0
  051c invoke-static v0, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0522 move-result-object v0
  0524 sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0528 invoke-virtual v0, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  052e move-result-object v5
  0530 const/4 v6, 0
  0532 const/16 v3, 503
  0536 move-object/from16 v1, v22
  053a move-object/from16 v2, v23
  053e invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0544 return-void 
  0546 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  054c move-result-object v4
  054e new-array v5, v10, [B
  0552 const/4 v6, 0
  0554 const/16 v3, 404
  0558 move-object/from16 v1, v22
  055c move-object/from16 v2, v23
  0560 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0566 return-void 
  0568 move-exception v0
  056a monitor-exit v22
  056c throw v0
  056e const-string v0, "/_forge/stage-capture"
  0572 invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0578 move-result v0
  057a if-eqz v0, +06ch
  057e iget-object v0, v3, Lcom/personal/aihub/PreviewServer$Request;->uri Ljava/net/URI;
  0582 invoke-virtual v0, Ljava/net/URI;->getRawQuery()Ljava/lang/String;
  0588 move-result-object v0
  058a if-eqz v0, +013h
  058e invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  0594 move-result-object v4
  0596 new-array v5, v10, [B
  059a const/16 v3, 404
  059e move-object/from16 v1, v22
  05a2 move-object/from16 v2, v23
  05a6 move v6, v11
  05a8 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  05ae return-void 
  05b0 if-eqz v11, +013h
  05b4 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  05ba move-result-object v4
  05bc new-array v5, v10, [B
  05c0 const/4 v6, 1
  05c2 const/16 v3, 405
  05c6 move-object/from16 v1, v22
  05ca move-object/from16 v2, v23
  05ce invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  05d4 return-void 
  05d6 iget-object v0, v8, Lcom/personal/aihub/PreviewServer;->stageCapture Lcom/personal/aihub/StageCapture;
  05da if-eqz v0, +012h
  05de const-string v1, "Content-Type"
  05e2 const-string v2, "image/png"
  05e6 invoke-static v1, v2, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  05ec move-result-object v1
  05ee invoke-virtual v0, Lcom/personal/aihub/StageCapture;->capture()[B
  05f4 move-result-object v0
  05f6 invoke-direct v8, v9, v3, v1, v0, Lcom/personal/aihub/PreviewServer;->sendBytes(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request; Ljava/util/Map; [B)V
  05fc return-void 
  05fe new-instance v0, Ljava/io/IOException;
  0602 const-string v1, "The owning preview cannot capture this animation."
  0606 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  060c throw v0
  060e move-exception v0
  0610 const-string v1, "Content-Type"
  0614 const-string v2, "text/plain"
  0618 invoke-static v1, v2, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  061e move-result-object v4
  0620 invoke-virtual v0, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  0626 move-result-object v0
  0628 invoke-static v0, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  062e move-result-object v0
  0630 sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0634 invoke-virtual v0, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  063a move-result-object v5
  063c const/4 v6, 0
  063e const/16 v3, 503
  0642 move-object/from16 v1, v22
  0646 move-object/from16 v2, v23
  064a invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0650 return-void 
  0652 const-string v0, "/_forge/bgm-source"
  0656 invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  065c move-result v0
  065e const/4 v1, 0
  0660 if-nez v0, +3bch
  0664 const-string v0, "/_forge/bgm-source.acb"
  0668 invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  066e move-result v0
  0670 if-nez v0, +3b4h
  0674 const-string v0, "/_forge/bgm-source.awb"
  0678 invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  067e move-result v0
  0680 if-nez v0, +3ach
  0684 const-string v0, "/_forge/bgm-bank-assets/"
  0688 invoke-virtual v2, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  068e move-result v0
  0690 if-eqz v0, +004h
  0694 goto/16 +3a2h
  0698 const-string v0, "/_forge/audio-banks"
  069c invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  06a2 move-result v0
  06a4 if-nez v0, +2e6h
  06a8 const-string v0, "/_forge/audio-bank-assets/"
  06ac invoke-virtual v2, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  06b2 move-result v0
  06b4 if-eqz v0, +004h
  06b8 goto/16 +2dch
  06bc const-string v0, "/_forge/"
  06c0 invoke-virtual v2, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  06c6 move-result v0
  06c8 if-eqz v0, +03bh
  06cc const-string v0, "/_forge/training-context.js"
  06d0 invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  06d6 move-result v0
  06d8 if-nez v0, +033h
  06dc const-string v0, "/_forge/native-audio.js"
  06e0 invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  06e6 move-result v0
  06e8 if-nez v0, +02bh
  06ec const-string v0, "/_forge/audio-bank.js"
  06f0 invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  06f6 move-result v0
  06f8 if-nez v0, +023h
  06fc const-string v0, "/_forge/imported-audio.js"
  0700 invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0706 move-result v0
  0708 if-nez v0, +01bh
  070c const-string v0, "/_forge/media/(libav/)?[A-Za-z0-9][A-Za-z0-9_.-]*"
  0710 invoke-virtual v2, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0716 move-result v0
  0718 if-nez v0, +013h
  071c invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  0722 move-result-object v4
  0724 new-array v5, v10, [B
  0728 const/16 v3, 404
  072c move-object/from16 v1, v22
  0730 move-object/from16 v2, v23
  0734 move v6, v11
  0736 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  073c return-void 
  073e iget-object v0, v3, Lcom/personal/aihub/PreviewServer$Request;->target Ljava/lang/String;
  0742 const-string v6, "/api/scripts"
  0746 invoke-virtual v0, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  074c move-result v0
  074e if-eqz v0, +04dh
  0752 const-string v0, "Content-Type"
  0756 const-string v1, "application/json"
  075a invoke-static v0, v1, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  0760 move-result-object v0
  0762 iget-object v1, v8, Lcom/personal/aihub/PreviewServer;->context Landroid/content/Context;
  0766 new-instance v2, Ljava/io/File;
  076a iget-object v4, v8, Lcom/personal/aihub/PreviewServer;->context Landroid/content/Context;
  076e invoke-virtual v4, Landroid/content/Context;->getFilesDir()Ljava/io/File;
  0774 move-result-object v4
  0776 const-string v5, "forge/assets"
  077a invoke-direct v2, v4, v5, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0780 invoke-static v1, v2, Lcom/personal/aihub/PreviewScripts;->listing(Landroid/content/Context; Ljava/io/File;)Lorg/json/JSONObject;
  0786 move-result-object v1
  0788 invoke-virtual v1, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  078e move-result-object v1
  0790 sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0794 invoke-virtual v1, v2, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  079a move-result-object v1
  079c invoke-direct v8, v9, v3, v0, v1, Lcom/personal/aihub/PreviewServer;->sendBytes(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request; Ljava/util/Map; [B)V
  07a2 return-void 
  07a4 move-exception v0
  07a6 const-string v1, "Content-Type"
  07aa const-string v2, "text/plain; charset=utf-8"
  07ae invoke-static v1, v2, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  07b4 move-result-object v4
  07b6 invoke-virtual v0, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  07bc move-result-object v0
  07be invoke-static v0, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  07c4 move-result-object v0
  07c6 sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  07ca invoke-virtual v0, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  07d0 move-result-object v5
  07d2 const/16 v3, 503
  07d6 move-object/from16 v1, v22
  07da move-object/from16 v2, v23
  07de move v6, v11
  07e0 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  07e6 return-void 
  07e8 new-instance v0, Lcom/personal/aihub/PreviewServer$4;
  07ec invoke-direct v0, v8, v3, Lcom/personal/aihub/PreviewServer$4;-><init>(Lcom/personal/aihub/PreviewServer; Lcom/personal/aihub/PreviewServer$Request;)V
  07f2 new-instance v6, Ljava/lang/StringBuilder;
  07f6 invoke-direct v6, Ljava/lang/StringBuilder;-><init>()V
  07fc const-string v7, "https://dokkan-eclipse.com"
  0800 invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0806 iget-object v7, v3, Lcom/personal/aihub/PreviewServer$Request;->target Ljava/lang/String;
  080a invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0810 invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0816 move-result-object v6
  0818 invoke-static v6, Lcom/personal/aihub/GameDirectory;->route(Ljava/lang/String;)Ljava/lang/String;
  081e move-result-object v7
  0820 if-eqz v7, +046h
  0824 new-instance v7, Lcom/personal/aihub/GameDirectory;
  0828 new-instance v12, Ljava/io/File;
  082c iget-object v13, v8, Lcom/personal/aihub/PreviewServer;->context Landroid/content/Context;
  0830 invoke-virtual v13, Landroid/content/Context;->getFilesDir()Ljava/io/File;
  0836 move-result-object v13
  0838 const-string v14, "forge/assets"
  083c invoke-direct v12, v13, v14, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0842 iget-object v13, v8, Lcom/personal/aihub/PreviewServer;->preferredKey Ljava/lang/String;
  0846 iget-object v14, v8, Lcom/personal/aihub/PreviewServer;->overlays Lorg/json/JSONArray;
  084a invoke-direct v7, v12, v13, v14, Lcom/personal/aihub/GameDirectory;-><init>(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray;)V
  0850 invoke-virtual v7, v6, Lcom/personal/aihub/GameDirectory;->resolve(Ljava/lang/String;)Lorg/json/JSONObject;
  0856 move-result-object v7
  0858 if-eqz v7, +02ah
  085c new-instance v0, Lorg/json/JSONObject;
  0860 iget-object v2, v8, Lcom/personal/aihub/PreviewServer;->cache Lcom/personal/aihub/PreviewCache;
  0864 const/high16 v4, 2097152
  0868 invoke-virtual v2, v6, v4, Lcom/personal/aihub/PreviewCache;->text(Ljava/lang/String; I)Ljava/lang/String;
  086e move-result-object v2
  0870 invoke-direct v0, v2, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0876 move-object v1, v0
  0878 const-string v0, "Content-Type"
  087c const-string v2, "application/json"
  0880 invoke-static v0, v2, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  0886 move-result-object v0
  0888 invoke-static v7, v1, Lcom/personal/aihub/GameDirectory;->merge(Lorg/json/JSONObject; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  088e move-result-object v1
  0890 invoke-virtual v1, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0896 move-result-object v1
  0898 sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  089c invoke-virtual v1, v2, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  08a2 move-result-object v1
  08a4 invoke-direct v8, v9, v3, v0, v1, Lcom/personal/aihub/PreviewServer;->sendBytes(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request; Ljava/util/Map; [B)V
  08aa return-void 
  08ac iget-object v1, v3, Lcom/personal/aihub/PreviewServer$Request;->target Ljava/lang/String;
  08b0 invoke-static v1, Lcom/personal/aihub/PreviewMetadata;->route(Ljava/lang/String;)Z
  08b6 move-result v1
  08b8 if-eqz v1, +04dh
  08bc const-string v0, "Content-Type"
  08c0 const-string v1, "application/json"
  08c4 invoke-static v0, v1, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  08ca move-result-object v0
  08cc iget-object v12, v8, Lcom/personal/aihub/PreviewServer;->context Landroid/content/Context;
  08d0 iget-object v13, v8, Lcom/personal/aihub/PreviewServer;->cache Lcom/personal/aihub/PreviewCache;
  08d4 new-instance v1, Ljava/lang/StringBuilder;
  08d8 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  08de const-string v2, "https://dokkan-eclipse.com"
  08e2 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  08e8 iget-object v2, v3, Lcom/personal/aihub/PreviewServer$Request;->target Ljava/lang/String;
  08ec invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  08f2 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  08f8 move-result-object v14
  08fa iget-object v15, v8, Lcom/personal/aihub/PreviewServer;->preferredKey Ljava/lang/String;
  08fe iget-object v1, v8, Lcom/personal/aihub/PreviewServer;->overlays Lorg/json/JSONArray;
  0902 iget-object v2, v8, Lcom/personal/aihub/PreviewServer;->effectPacks Lorg/json/JSONArray;
  0906 iget-object v4, v8, Lcom/personal/aihub/PreviewServer;->sourceDatabase Ljava/lang/String;
  090a iget-object v5, v8, Lcom/personal/aihub/PreviewServer;->sparkingEffectIds Lorg/json/JSONArray;
  090e iget-wide v6, v8, Lcom/personal/aihub/PreviewServer;->sparkingVersion J
  0912 move-object/from16 v16, v1
  0916 move-object/from16 v17, v2
  091a move-object/from16 v18, v4
  091e move-object/from16 v19, v5
  0922 move-wide/from16 v20, v6
  0926 invoke-static/range v12 ... v21, Lcom/personal/aihub/PreviewMetadata;->resolve(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String; Lorg/json/JSONArray; J)Lorg/json/JSONObject;
  092c move-result-object v1
  092e invoke-virtual v1, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0934 move-result-object v1
  0936 invoke-direct v8, v1, Lcom/personal/aihub/PreviewServer;->rewrite(Ljava/lang/String;)Ljava/lang/String;
  093c move-result-object v1
  093e sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0942 invoke-virtual v1, v2, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0948 move-result-object v1
  094a invoke-direct v8, v9, v3, v0, v1, Lcom/personal/aihub/PreviewServer;->sendBytes(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request; Ljava/util/Map; [B)V
  0950 return-void 
  0952 iget-object v1, v8, Lcom/personal/aihub/PreviewServer;->gameAssets Lcom/personal/aihub/GameAssets;
  0956 new-instance v6, Ljava/lang/StringBuilder;
  095a invoke-direct v6, Ljava/lang/StringBuilder;-><init>()V
  0960 const-string v7, "https://dokkan-eclipse.com"
  0964 invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  096a iget-object v7, v3, Lcom/personal/aihub/PreviewServer$Request;->target Ljava/lang/String;
  096e invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0974 invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  097a move-result-object v6
  097c invoke-virtual v1, v6, Lcom/personal/aihub/GameAssets;->resolve(Ljava/lang/String;)Ljava/io/File;
  0982 move-result-object v1
  0984 if-nez v1, +011h
  0988 iget-object v1, v8, Lcom/personal/aihub/PreviewServer;->context Landroid/content/Context;
  098c invoke-static v1, v0, Lcom/personal/aihub/PreviewResources;->response(Landroid/content/Context; Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;
  0992 move-result-object v1
  0994 if-nez v1, +03ah
  0998 iget-object v1, v8, Lcom/personal/aihub/PreviewServer;->cache Lcom/personal/aihub/PreviewCache;
  099c invoke-virtual v1, v0, Lcom/personal/aihub/PreviewCache;->response(Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;
  09a2 move-result-object v1
  09a4 goto +32h
  09a6 invoke-virtual v1, Ljava/io/File;->length()J
  09ac move-result-wide v6
  09ae cmp-long v0, v6, v4
  09b2 if-gtz v0, +134h
  09b6 new-instance v0, Landroid/webkit/WebResourceResponse;
  09ba invoke-virtual v1, Ljava/io/File;->getName()Ljava/lang/String;
  09c0 move-result-object v4
  09c2 invoke-static v4, Lcom/personal/aihub/PreviewServer;->mime(Ljava/lang/String;)Ljava/lang/String;
  09c8 move-result-object v13
  09ca const-string v16, "OK"
  09ce const-string v4, "Content-Length"
  09d2 invoke-virtual v1, Ljava/io/File;->length()J
  09d8 move-result-wide v5
  09da invoke-static v5, v6, Ljava/lang/Long;->toString(J)Ljava/lang/String;
  09e0 move-result-object v5
  09e2 invoke-static v4, v5, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  09e8 move-result-object v17
  09ea new-instance v4, Ljava/io/FileInputStream;
  09ee invoke-direct v4, v1, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  09f4 const/4 v14, 0
  09f6 const/16 v15, 200
  09fa move-object v12, v0
  09fc move-object/from16 v18, v4
  0a00 invoke-direct/range v12 ... v18, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String; Ljava/lang/String; I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)V
  0a06 move-object v1, v0
  0a08 new-instance v4, Ljava/util/HashMap;
  0a0c invoke-direct v4, Ljava/util/HashMap;-><init>()V
  0a12 const-string v0, "Content-Type"
  0a16 invoke-virtual v1, Landroid/webkit/WebResourceResponse;->getMimeType()Ljava/lang/String;
  0a1c move-result-object v5
  0a1e invoke-virtual v4, v0, v5, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0a24 const-string v0, "Accept-Ranges"
  0a28 const-string v5, "bytes"
  0a2c invoke-virtual v4, v0, v5, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0a32 invoke-virtual v1, Landroid/webkit/WebResourceResponse;->getData()Ljava/io/InputStream;
  0a38 move-result-object v12
  0a3a invoke-virtual v1, Landroid/webkit/WebResourceResponse;->getStatusCode()I
  0a40 move-result v0
  0a42 const/16 v5, 200
  0a46 if-ne v0, v5, +0c8h
  0a4a invoke-virtual v1, Landroid/webkit/WebResourceResponse;->getMimeType()Ljava/lang/String;
  0a50 move-result-object v0
  0a52 invoke-virtual v1, Landroid/webkit/WebResourceResponse;->getResponseHeaders()Ljava/util/Map;
  0a58 move-result-object v1
  0a5a const-string v5, "Content-Length"
  0a5e invoke-interface v1, v5, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0a64 move-result-object v1
  0a66 check-cast v1, Ljava/lang/String;
  0a6a invoke-static v1, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  0a70 move-result-wide v6
  0a72 const-string v1, "text/"
  0a76 invoke-virtual v0, v1, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0a7c move-result v1
  0a7e if-nez v1, +01dh
  0a82 const-string v1, "javascript"
  0a86 invoke-virtual v0, v1, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  0a8c move-result v1
  0a8e if-nez v1, +015h
  0a92 const-string v1, "json"
  0a96 invoke-virtual v0, v1, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  0a9c move-result v1
  0a9e if-eqz v1, +003h
  0aa2 goto +bh
  0aa4 move-object/from16 v1, v22
  0aa8 move-object/from16 v2, v23
  0aac move-object v5, v12
  0aae invoke-direct/range v1 ... v7, Lcom/personal/aihub/PreviewServer;->sendStream(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request; Ljava/util/Map; Ljava/io/InputStream; J)V
  0ab4 goto/16 +083h
  0ab8 new-instance v1, Ljava/lang/String;
  0abc const/high16 v5, 67108864
  0ac0 invoke-static v12, v5, Lcom/personal/aihub/PreviewServer;->readBytes(Ljava/io/InputStream; I)[B
  0ac6 move-result-object v5
  0ac8 sget-object v6, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0acc invoke-direct v1, v5, v6, Ljava/lang/String;-><init>([B Ljava/nio/charset/Charset;)V
  0ad2 invoke-direct v8, v2, v1, Lcom/personal/aihub/PreviewServer;->playerPatches(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0ad8 move-result-object v1
  0ada invoke-direct v8, v1, Lcom/personal/aihub/PreviewServer;->rewrite(Ljava/lang/String;)Ljava/lang/String;
  0ae0 move-result-object v1
  0ae2 const-string v2, "text/html"
  0ae6 invoke-virtual v0, v2, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0aec move-result v0
  0aee if-eqz v0, +05dh
  0af2 new-instance v0, Ljava/lang/StringBuilder;
  0af6 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  0afc const-string v2, "<script>"
  0b00 invoke-virtual v0, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0b06 invoke-direct/range v22, Lcom/personal/aihub/PreviewServer;->transport()Ljava/lang/String;
  0b0c move-result-object v2
  0b0e invoke-virtual v0, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0b14 const-string v2, "</script><script src="/tools/lua-player/js/forge-imported.js"></script>"
  0b18 invoke-virtual v0, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0b1e invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0b24 move-result-object v0
  0b26 const-string v2, "<head(?:\s[^>]*)?>"
  0b2a const/4 v5, 2
  0b2c invoke-static v2, v5, Ljava/util/regex/Pattern;->compile(Ljava/lang/String; I)Ljava/util/regex/Pattern;
  0b32 move-result-object v2
  0b34 invoke-virtual v2, v1, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  0b3a move-result-object v2
  0b3c invoke-virtual v2, Ljava/util/regex/Matcher;->find()Z
  0b42 move-result v5
  0b44 if-eqz v5, +022h
  0b48 new-instance v5, Ljava/lang/StringBuilder;
  0b4c invoke-virtual v2, Ljava/util/regex/Matcher;->end()I
  0b52 move-result v6
  0b54 invoke-virtual v1, v10, v6, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  0b5a move-result-object v6
  0b5c invoke-static v6, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0b62 move-result-object v6
  0b64 invoke-direct v5, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0b6a invoke-virtual v5, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0b70 invoke-virtual v2, Ljava/util/regex/Matcher;->end()I
  0b76 move-result v0
  0b78 invoke-virtual v1, v0, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0b7e move-result-object v0
  0b80 invoke-virtual v5, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0b86 goto +dh
  0b88 new-instance v5, Ljava/lang/StringBuilder;
  0b8c invoke-static v0, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0b92 move-result-object v0
  0b94 invoke-direct v5, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0b9a invoke-virtual v5, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0ba0 invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0ba6 move-result-object v1
  0ba8 sget-object v0, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0bac invoke-virtual v1, v0, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0bb2 move-result-object v0
  0bb4 invoke-direct v8, v9, v3, v4, v0, Lcom/personal/aihub/PreviewServer;->sendBytes(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request; Ljava/util/Map; [B)V
  0bba if-eqz v12, +008h
  0bbe if-eqz v12, +005h
  0bc2 invoke-virtual v12, Ljava/io/InputStream;->close()V
  0bc8 return-void 
  0bca if-eqz v12, +005h
  0bce invoke-virtual v12, Ljava/io/InputStream;->close()V
  0bd4 return-void 
  0bd6 invoke-virtual v1, Landroid/webkit/WebResourceResponse;->getStatusCode()I
  0bdc move-result v3
  0bde const/high16 v0, 1048576
  0be2 invoke-static v12, v0, Lcom/personal/aihub/PreviewServer;->readBytes(Ljava/io/InputStream; I)[B
  0be8 move-result-object v5
  0bea move-object/from16 v1, v22
  0bee move-object/from16 v2, v23
  0bf2 move v6, v11
  0bf4 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0bfa if-eqz v12, +1f1h
  0bfe invoke-virtual v12, Ljava/io/InputStream;->close()V
  0c04 goto/16 +1ech
  0c08 move-exception v0
  0c0a if-eqz v12, +005h
  0c0e invoke-virtual v12, Ljava/io/InputStream;->close()V
  0c14 throw v0
  0c16 move-exception v0
  0c18 throw v0
  0c1a new-instance v0, Ljava/io/IOException;
  0c1e const-string v1, "This imported preview asset exceeds 160 MB."
  0c22 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0c28 throw v0
  0c2a move-exception v0
  0c2c const-string v1, "Content-Type"
  0c30 const-string v2, "text/plain; charset=utf-8"
  0c34 invoke-static v1, v2, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  0c3a move-result-object v4
  0c3c invoke-virtual v0, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  0c42 move-result-object v0
  0c44 invoke-static v0, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0c4a move-result-object v0
  0c4c sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0c50 invoke-virtual v0, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0c56 move-result-object v5
  0c58 const/16 v3, 503
  0c5c move-object/from16 v1, v22
  0c60 move-object/from16 v2, v23
  0c64 move v6, v11
  0c66 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0c6c goto/16 +1b8h
  0c70 iget-object v0, v3, Lcom/personal/aihub/PreviewServer$Request;->uri Ljava/net/URI;
  0c74 invoke-virtual v0, Ljava/net/URI;->getRawQuery()Ljava/lang/String;
  0c7a move-result-object v0
  0c7c if-eqz v0, +013h
  0c80 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  0c86 move-result-object v4
  0c88 new-array v5, v10, [B
  0c8c const/16 v3, 404
  0c90 move-object/from16 v1, v22
  0c94 move-object/from16 v2, v23
  0c98 move v6, v11
  0c9a invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0ca0 return-void 
  0ca2 const-string v0, "/_forge/audio-banks"
  0ca6 invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0cac move-result v0
  0cae if-eqz v0, +01eh
  0cb2 const-string v0, "Content-Type"
  0cb6 const-string v1, "application/json"
  0cba invoke-static v0, v1, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  0cc0 move-result-object v0
  0cc2 iget-object v1, v8, Lcom/personal/aihub/PreviewServer;->audioBanks Lcom/personal/aihub/AudioBanks;
  0cc6 invoke-virtual v1, Lcom/personal/aihub/AudioBanks;->catalogue()Lorg/json/JSONObject;
  0ccc move-result-object v1
  0cce invoke-virtual v1, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0cd4 move-result-object v1
  0cd6 sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0cda invoke-virtual v1, v2, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0ce0 move-result-object v1
  0ce2 invoke-direct v8, v9, v3, v0, v1, Lcom/personal/aihub/PreviewServer;->sendBytes(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request; Ljava/util/Map; [B)V
  0ce8 return-void 
  0cea iget-object v0, v8, Lcom/personal/aihub/PreviewServer;->audioBanks Lcom/personal/aihub/AudioBanks;
  0cee new-instance v1, Ljava/lang/StringBuilder;
  0cf2 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  0cf8 const-string v2, "https://dokkan-eclipse.com"
  0cfc invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0d02 iget-object v2, v3, Lcom/personal/aihub/PreviewServer$Request;->target Ljava/lang/String;
  0d06 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0d0c invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0d12 move-result-object v1
  0d14 invoke-virtual v0, v1, Lcom/personal/aihub/AudioBanks;->resolve(Ljava/lang/String;)Ljava/io/File;
  0d1a move-result-object v0
  0d1c if-nez v0, +013h
  0d20 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  0d26 move-result-object v4
  0d28 new-array v5, v10, [B
  0d2c const/16 v3, 404
  0d30 move-object/from16 v1, v22
  0d34 move-object/from16 v2, v23
  0d38 move v6, v11
  0d3a invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0d40 return-void 
  0d42 new-instance v12, Ljava/io/FileInputStream;
  0d46 invoke-direct v12, v0, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0d4c new-instance v4, Ljava/util/HashMap;
  0d50 const-string v1, "Content-Type"
  0d54 const-string v2, "application/octet-stream"
  0d58 invoke-static v1, v2, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  0d5e move-result-object v1
  0d60 invoke-direct v4, v1, Ljava/util/HashMap;-><init>(Ljava/util/Map;)V
  0d66 invoke-virtual v0, Ljava/io/File;->length()J
  0d6c move-result-wide v6
  0d6e move-object/from16 v1, v22
  0d72 move-object/from16 v2, v23
  0d76 move-object v5, v12
  0d78 invoke-direct/range v1 ... v7, Lcom/personal/aihub/PreviewServer;->sendStream(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request; Ljava/util/Map; Ljava/io/InputStream; J)V
  0d7e invoke-virtual v12, Ljava/io/FileInputStream;->close()V
  0d84 return-void 
  0d86 move-exception v0
  0d88 invoke-virtual v12, Ljava/io/FileInputStream;->close()V
  0d8e throw v0
  0d90 move-exception v0
  0d92 throw v0
  0d94 move-exception v0
  0d96 const-string v1, "Content-Type"
  0d9a const-string v2, "text/plain; charset=utf-8"
  0d9e invoke-static v1, v2, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  0da4 move-result-object v4
  0da6 invoke-virtual v0, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  0dac move-result-object v0
  0dae invoke-static v0, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0db4 move-result-object v0
  0db6 sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0dba invoke-virtual v0, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0dc0 move-result-object v5
  0dc2 const/16 v3, 503
  0dc6 move-object/from16 v1, v22
  0dca move-object/from16 v2, v23
  0dce move v6, v11
  0dd0 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0dd6 return-void 
  0dd8 iget-object v0, v3, Lcom/personal/aihub/PreviewServer$Request;->uri Ljava/net/URI;
  0ddc invoke-virtual v0, Ljava/net/URI;->getRawQuery()Ljava/lang/String;
  0de2 move-result-object v0
  0de4 if-eqz v0, +013h
  0de8 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  0dee move-result-object v4
  0df0 new-array v5, v10, [B
  0df4 const/16 v3, 404
  0df8 move-object/from16 v1, v22
  0dfc move-object/from16 v2, v23
  0e00 move v6, v11
  0e02 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0e08 return-void 
  0e0a const-string v0, "/_forge/bgm-source"
  0e0e invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0e14 move-result v0
  0e16 if-eqz v0, +01eh
  0e1a const-string v0, "Content-Type"
  0e1e const-string v1, "application/json"
  0e22 invoke-static v0, v1, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  0e28 move-result-object v0
  0e2a iget-object v1, v8, Lcom/personal/aihub/PreviewServer;->bgm Lcom/personal/aihub/PreviewBgm;
  0e2e invoke-virtual v1, Lcom/personal/aihub/PreviewBgm;->descriptor()Lorg/json/JSONObject;
  0e34 move-result-object v1
  0e36 invoke-virtual v1, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0e3c move-result-object v1
  0e3e sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0e42 invoke-virtual v1, v2, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0e48 move-result-object v1
  0e4a invoke-direct v8, v9, v3, v0, v1, Lcom/personal/aihub/PreviewServer;->sendBytes(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request; Ljava/util/Map; [B)V
  0e50 return-void 
  0e52 const-string v0, "/_forge/bgm-bank-assets/"
  0e56 invoke-virtual v2, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0e5c move-result v0
  0e5e if-eqz v0, +01ah
  0e62 iget-object v0, v8, Lcom/personal/aihub/PreviewServer;->bgm Lcom/personal/aihub/PreviewBgm;
  0e66 new-instance v1, Ljava/lang/StringBuilder;
  0e6a invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  0e70 const-string v4, "https://dokkan-eclipse.com"
  0e74 invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0e7a invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0e80 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0e86 move-result-object v1
  0e88 invoke-virtual v0, v1, Lcom/personal/aihub/PreviewBgm;->resolve(Ljava/lang/String;)Ljava/io/File;
  0e8e move-result-object v1
  0e90 goto +1bh
  0e92 iget-object v0, v8, Lcom/personal/aihub/PreviewServer;->bgm Lcom/personal/aihub/PreviewBgm;
  0e96 invoke-virtual v0, v2, Lcom/personal/aihub/PreviewBgm;->publicAddress(Ljava/lang/String;)Ljava/lang/String;
  0e9c move-result-object v0
  0e9e if-nez v0, +003h
  0ea2 goto +12h
  0ea4 iget-object v1, v8, Lcom/personal/aihub/PreviewServer;->cache Lcom/personal/aihub/PreviewCache;
  0ea8 const-string v6, ".acb"
  0eac invoke-virtual v2, v6, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  0eb2 move-result v2
  0eb4 if-eqz v2, +005h
  0eb8 const-wide/32 v4, 33554432
  0ebe invoke-virtual v1, v0, v4, v5, Lcom/personal/aihub/PreviewCache;->resourceBody(Ljava/lang/String; J)Ljava/io/File;
  0ec4 move-result-object v1
  0ec6 if-nez v1, +013h
  0eca invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  0ed0 move-result-object v4
  0ed2 new-array v5, v10, [B
  0ed6 const/16 v3, 404
  0eda move-object/from16 v1, v22
  0ede move-object/from16 v2, v23
  0ee2 move v6, v11
  0ee4 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0eea return-void 
  0eec new-instance v12, Ljava/io/FileInputStream;
  0ef0 invoke-direct v12, v1, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0ef6 const-string v0, "Content-Type"
  0efa const-string v2, "application/octet-stream"
  0efe invoke-static v0, v2, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  0f04 move-result-object v4
  0f06 invoke-virtual v1, Ljava/io/File;->length()J
  0f0c move-result-wide v6
  0f0e move-object/from16 v1, v22
  0f12 move-object/from16 v2, v23
  0f16 move-object v5, v12
  0f18 invoke-direct/range v1 ... v7, Lcom/personal/aihub/PreviewServer;->sendStream(Ljava/net/Socket; Lcom/personal/aihub/PreviewServer$Request; Ljava/util/Map; Ljava/io/InputStream; J)V
  0f1e invoke-virtual v12, Ljava/io/FileInputStream;->close()V
  0f24 return-void 
  0f26 move-exception v0
  0f28 invoke-virtual v12, Ljava/io/FileInputStream;->close()V
  0f2e throw v0
  0f30 move-exception v0
  0f32 throw v0
  0f34 move-exception v0
  0f36 const-string v1, "Content-Type"
  0f3a const-string v2, "text/plain; charset=utf-8"
  0f3e invoke-static v1, v2, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  0f44 move-result-object v4
  0f46 invoke-virtual v0, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  0f4c move-result-object v0
  0f4e invoke-static v0, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0f54 move-result-object v0
  0f56 sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0f5a invoke-virtual v0, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0f60 move-result-object v5
  0f62 const/16 v3, 503
  0f66 move-object/from16 v1, v22
  0f6a move-object/from16 v2, v23
  0f6e move v6, v11
  0f70 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0f76 return-void 
  0f78 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  0f7e move-result-object v4
  0f80 new-array v5, v10, [B
  0f84 const/16 v3, 403
  0f88 move-object/from16 v1, v22
  0f8c move-object/from16 v2, v23
  0f90 move v6, v11
  0f92 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0f98 return-void 
  0f9a invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  0fa0 move-result-object v4
  0fa2 new-array v5, v10, [B
  0fa6 const/4 v6, 0
  0fa8 const/16 v3, 400
  0fac move-object/from16 v1, v22
  0fb0 move-object/from16 v2, v23
  0fb4 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0fba return-void 
  0fbc invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  0fc2 move-result-object v4
  0fc4 new-array v5, v10, [B
  0fc8 const/4 v6, 0
  0fca const/16 v3, 400
  0fce move-object/from16 v1, v22
  0fd2 move-object/from16 v2, v23
  0fd6 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewServer;->respond(Ljava/net/Socket; I Ljava/util/Map; [B Z)V
  0fdc return-void 
.end method

.method transport()Ljava/lang/String;
  0000 new-instance v0, Ljava/lang/StringBuilder;
  0004 const-string v1, "window.__forgeNativeDocumentId="
  0008 invoke-direct v0, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  000e invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0014 move-result-object v1
  0016 invoke-virtual v1, Ljava/util/UUID;->toString()Ljava/lang/String;
  001c move-result-object v1
  001e invoke-static v1, Lorg/json/JSONObject;->quote(Ljava/lang/String;)Ljava/lang/String;
  0024 move-result-object v1
  0026 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  002c const-string v1, ";(()=>{const origin="
  0030 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0036 iget-object v1, v2, Lcom/personal/aihub/PreviewServer;->origin Ljava/lang/String;
  003a invoke-static v1, Lorg/json/JSONObject;->quote(Ljava/lang/String;)Ljava/lang/String;
  0040 move-result-object v1
  0042 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0048 const-string v1, ";const map=u=>{const s=String(u),cdn='https://cdn.dokkan-eclipse.com/uncompressed',site='https://dokkan-eclipse.com';return s.startsWith(cdn+'/')?origin+'/cdn/uncompressed'+s.slice(cdn.length):s.startsWith(site+'/')?origin+s.slice(site.length):s};const fetch=window.fetch;window.fetch=(u,o)=>fetch(u instanceof Request?new Request(map(u.url),u):map(u),o);const open=XMLHttpRequest.prototype.open;XMLHttpRequest.prototype.open=function(m,u,...a){return open.call(this,m,map(u),...a)}})();"
  004c invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0052 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0058 move-result-object v0
  005a return-object v0
.end method

.method writeHeaders(Ljava/net/Socket; I Ljava/util/Map; J)V
  0000 new-instance v0, Ljava/util/LinkedHashMap;
  0004 invoke-direct v0, v5, Ljava/util/LinkedHashMap;-><init>(Ljava/util/Map;)V
  000a const-string v5, "Content-Length"
  000e invoke-static v6, v7, Ljava/lang/Long;->toString(J)Ljava/lang/String;
  0014 move-result-object v6
  0016 invoke-virtual v0, v5, v6, Ljava/util/LinkedHashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  001c const-string v5, "Connection"
  0020 const-string v6, "close"
  0024 invoke-virtual v0, v5, v6, Ljava/util/LinkedHashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  002a const-string v5, "Cache-Control"
  002e const-string v6, "no-store"
  0032 invoke-virtual v0, v5, v6, Ljava/util/LinkedHashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0038 const-string v5, "Cross-Origin-Opener-Policy"
  003c const-string v6, "same-origin"
  0040 invoke-virtual v0, v5, v6, Ljava/util/LinkedHashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0046 const-string v5, "Cross-Origin-Embedder-Policy"
  004a const-string v7, "require-corp"
  004e invoke-virtual v0, v5, v7, Ljava/util/LinkedHashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0054 const-string v5, "Cross-Origin-Resource-Policy"
  0058 invoke-virtual v0, v5, v6, Ljava/util/LinkedHashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  005e const-string v5, "X-Content-Type-Options"
  0062 const-string v6, "nosniff"
  0066 invoke-virtual v0, v5, v6, Ljava/util/LinkedHashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  006c const-string v5, "Referrer-Policy"
  0070 const-string v6, "no-referrer"
  0074 invoke-virtual v0, v5, v6, Ljava/util/LinkedHashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  007a const-string v5, "Content-Security-Policy"
  007e const-string v6, "default-src 'self' data: blob:; script-src 'self' 'unsafe-inline' 'unsafe-eval' blob:; connect-src 'self' blob:; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; media-src 'self' blob: data:; worker-src 'self' blob:; frame-src 'none'; object-src 'none'; base-uri 'self'; form-action 'none'"
  0082 invoke-virtual v0, v5, v6, Ljava/util/LinkedHashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0088 new-instance v5, Ljava/lang/StringBuilder;
  008c new-instance v6, Ljava/lang/StringBuilder;
  0090 const-string v7, "HTTP/1.1 "
  0094 invoke-direct v6, v7, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  009a invoke-virtual v6, v4, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  00a0 const-string v4, " Response
"
  00a4 invoke-virtual v6, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00aa invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00b0 move-result-object v4
  00b2 invoke-direct v5, v4, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00b8 invoke-virtual v0, Ljava/util/LinkedHashMap;->entrySet()Ljava/util/Set;
  00be move-result-object v4
  00c0 invoke-interface v4, Ljava/util/Set;->iterator()Ljava/util/Iterator;
  00c6 move-result-object v4
  00c8 invoke-interface v4, Ljava/util/Iterator;->hasNext()Z
  00ce move-result v6
  00d0 const-string v7, "
"
  00d4 if-eqz v6, +031h
  00d8 invoke-interface v4, Ljava/util/Iterator;->next()Ljava/lang/Object;
  00de move-result-object v6
  00e0 check-cast v6, Ljava/util/Map$Entry;
  00e4 invoke-interface v6, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;
  00ea move-result-object v0
  00ec check-cast v0, Ljava/lang/String;
  00f0 invoke-virtual v5, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00f6 const-string v0, ": "
  00fa invoke-virtual v5, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0100 invoke-interface v6, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;
  0106 move-result-object v6
  0108 check-cast v6, Ljava/lang/String;
  010c const-string v0, ""
  0110 const-string v1, ""
  0114 invoke-virtual v6, v0, v1, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  011a move-result-object v6
  011c const-string v0, "
"
  0120 invoke-virtual v6, v0, v1, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  0126 move-result-object v6
  0128 invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  012e invoke-virtual v5, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0134 goto -36h
  0136 invoke-virtual v5, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  013c invoke-virtual v3, Ljava/net/Socket;->getOutputStream()Ljava/io/OutputStream;
  0142 move-result-object v3
  0144 invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  014a move-result-object v4
  014c sget-object v5, Ljava/nio/charset/StandardCharsets;->ISO_8859_1 Ljava/nio/charset/Charset;
  0150 invoke-virtual v4, v5, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0156 move-result-object v4
  0158 invoke-virtual v3, v4, Ljava/io/OutputStream;->write([B)V
  015e return-void 
.end method

.method bgmContext()Lorg/json/JSONObject;
  0000 new-instance v0, Lorg/json/JSONObject;
  0004 iget-object v1, v2, Lcom/personal/aihub/PreviewServer;->bgm Lcom/personal/aihub/PreviewBgm;
  0008 iget-object v1, v1, Lcom/personal/aihub/PreviewBgm;->context Lorg/json/JSONObject;
  000c invoke-virtual v1, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0012 move-result-object v1
  0014 invoke-direct v0, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  001a return-object v0
.end method

.method close()V
  0000 iget-object v0, v2, Lcom/personal/aihub/PreviewServer;->stageExport Lcom/personal/aihub/StageExport;
  0004 if-eqz v0, +007h
  0008 iget-object v0, v2, Lcom/personal/aihub/PreviewServer;->stageExport Lcom/personal/aihub/StageExport;
  000c invoke-virtual v0, Lcom/personal/aihub/StageExport;->close()V
  0012 iget-object v0, v2, Lcom/personal/aihub/PreviewServer;->stageCapture Lcom/personal/aihub/StageCapture;
  0016 if-eqz v0, +007h
  001a iget-object v0, v2, Lcom/personal/aihub/PreviewServer;->stageCapture Lcom/personal/aihub/StageCapture;
  001e invoke-virtual v0, Lcom/personal/aihub/StageCapture;->close()V
  0024 iget-object v0, v2, Lcom/personal/aihub/PreviewServer;->audioBanks Lcom/personal/aihub/AudioBanks;
  0028 invoke-virtual v0, Lcom/personal/aihub/AudioBanks;->close()V
  002e iget-object v0, v2, Lcom/personal/aihub/PreviewServer;->bgm Lcom/personal/aihub/PreviewBgm;
  0032 invoke-virtual v0, Lcom/personal/aihub/PreviewBgm;->close()V
  0038 monitor-enter v2
  003a iget-boolean v0, v2, Lcom/personal/aihub/PreviewServer;->stopped Z
  003e if-eqz v0, +004h
  0042 monitor-exit v2
  0044 return-void 
  0046 const/4 v0, 1
  0048 iput-boolean v0, v2, Lcom/personal/aihub/PreviewServer;->stopped Z
  004c iget-object v0, v2, Lcom/personal/aihub/PreviewServer;->listener Ljava/net/ServerSocket;
  0050 invoke-virtual v0, Ljava/net/ServerSocket;->close()V
  0056 iget-object v0, v2, Lcom/personal/aihub/PreviewServer;->clients Ljava/util/Set;
  005a invoke-interface v0, Ljava/util/Set;->iterator()Ljava/util/Iterator;
  0060 move-result-object v0
  0062 invoke-interface v0, Ljava/util/Iterator;->hasNext()Z
  0068 move-result v1
  006a if-eqz v1, +00ch
  006e invoke-interface v0, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0074 move-result-object v1
  0076 check-cast v1, Ljava/net/Socket;
  007a invoke-static v1, Lcom/personal/aihub/PreviewServer;->closeSocket(Ljava/net/Socket;)V
  0080 goto -fh
  0082 iget-object v0, v2, Lcom/personal/aihub/PreviewServer;->clients Ljava/util/Set;
  0086 invoke-interface v0, Ljava/util/Set;->clear()V
  008c iget-object v0, v2, Lcom/personal/aihub/PreviewServer;->workers Ljava/util/concurrent/ThreadPoolExecutor;
  0090 invoke-virtual v0, Ljava/util/concurrent/ThreadPoolExecutor;->shutdownNow()Ljava/util/List;
  0096 iget-object v0, v2, Lcom/personal/aihub/PreviewServer;->movies Ljava/util/Map;
  009a invoke-interface v0, Ljava/util/Map;->clear()V
  00a0 const-wide/16 v0, 0
  00a4 iput-wide v0, v2, Lcom/personal/aihub/PreviewServer;->preparedBytes J
  00a8 iget-object v0, v2, Lcom/personal/aihub/PreviewServer;->movieRoot Ljava/io/File;
  00ac invoke-static v0, Lcom/personal/aihub/PreviewServer;->remove(Ljava/io/File;)V
  00b2 monitor-exit v2
  00b4 return-void 
  00b6 move-exception v0
  00b8 monitor-exit v2
  00ba throw v0
.end method

.method entryURL(Ljava/lang/String;)Ljava/lang/String;
  0000 const-string v0, "pack"
  0004 invoke-virtual v3, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  000a move-result v0
  000c if-eqz v0, +005h
  0010 const-string v3, "lwf-player"
  0014 goto +eh
  0016 const-string v0, "movie"
  001a invoke-virtual v3, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0020 move-result v3
  0022 if-eqz v3, +005h
  0026 const-string v3, "usm-player"
  002a goto +3h
  002c const-string v3, "lua-player"
  0030 new-instance v0, Ljava/lang/StringBuilder;
  0034 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  003a iget-object v1, v2, Lcom/personal/aihub/PreviewServer;->origin Ljava/lang/String;
  003e invoke-static v1, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0044 move-result-object v1
  0046 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  004c const-string v1, "/_forge/open/"
  0050 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0056 iget-object v1, v2, Lcom/personal/aihub/PreviewServer;->token Ljava/lang/String;
  005a invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0060 const-string v1, "?tool="
  0064 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  006a invoke-virtual v0, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0070 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0076 move-result-object v3
  0078 return-object v3
.end method

.method local(Ljava/lang/String;)Z
  0000 const/4 v0, 0
  0002 new-instance v1, Ljava/net/URI;
  0006 invoke-direct v1, v4, Ljava/net/URI;-><init>(Ljava/lang/String;)V
  000c const-string v4, "http"
  0010 invoke-virtual v1, Ljava/net/URI;->getScheme()Ljava/lang/String;
  0016 move-result-object v2
  0018 invoke-virtual v4, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  001e move-result v4
  0020 if-eqz v4, +021h
  0024 const-string v4, "127.0.0.1"
  0028 invoke-virtual v1, Ljava/net/URI;->getHost()Ljava/lang/String;
  002e move-result-object v2
  0030 invoke-virtual v4, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0036 move-result v4
  0038 if-eqz v4, +015h
  003c invoke-virtual v1, Ljava/net/URI;->getPort()I
  0042 move-result v4
  0044 iget-object v2, v3, Lcom/personal/aihub/PreviewServer;->listener Ljava/net/ServerSocket;
  0048 invoke-virtual v2, Ljava/net/ServerSocket;->getLocalPort()I
  004e move-result v2
  0050 if-ne v4, v2, +009h
  0054 invoke-virtual v1, Ljava/net/URI;->getUserInfo()Ljava/lang/String;
  005a move-result-object v4
  005c if-nez v4, +003h
  0060 const/4 v0, 1
  0062 return v0
.end method

.method m33lambda$1$compersonalaihubPreviewServer()V
  0000 iget-object v0, v3, Lcom/personal/aihub/PreviewServer;->listener Ljava/net/ServerSocket;
  0004 invoke-virtual v0, Ljava/net/ServerSocket;->accept()Ljava/net/Socket;
  000a move-result-object v0
  000c const/16 v1, 30000
  0010 invoke-virtual v0, v1, Ljava/net/Socket;->setSoTimeout(I)V
  0016 monitor-enter v3
  0018 iget-boolean v1, v3, Lcom/personal/aihub/PreviewServer;->stopped Z
  001c if-nez v1, +02bh
  0020 iget-object v1, v3, Lcom/personal/aihub/PreviewServer;->clients Ljava/util/Set;
  0024 invoke-interface v1, Ljava/util/Set;->size()I
  002a move-result v1
  002c const/16 v2, 32
  0030 if-lt v1, v2, +003h
  0034 goto +1fh
  0036 iget-object v1, v3, Lcom/personal/aihub/PreviewServer;->clients Ljava/util/Set;
  003a invoke-interface v1, v0, Ljava/util/Set;->add(Ljava/lang/Object;)Z
  0040 iget-object v1, v3, Lcom/personal/aihub/PreviewServer;->workers Ljava/util/concurrent/ThreadPoolExecutor;
  0044 new-instance v2, Lcom/personal/aihub/PreviewServer$3;
  0048 invoke-direct v2, v3, v0, Lcom/personal/aihub/PreviewServer$3;-><init>(Lcom/personal/aihub/PreviewServer; Ljava/net/Socket;)V
  004e invoke-virtual v1, v2, Ljava/util/concurrent/ThreadPoolExecutor;->execute(Ljava/lang/Runnable;)V
  0054 goto +12h
  0056 monitor-enter v3
  0058 iget-object v1, v3, Lcom/personal/aihub/PreviewServer;->clients Ljava/util/Set;
  005c invoke-interface v1, v0, Ljava/util/Set;->remove(Ljava/lang/Object;)Z
  0062 invoke-static v0, Lcom/personal/aihub/PreviewServer;->closeSocket(Ljava/net/Socket;)V
  0068 monitor-exit v3
  006a goto +7h
  006c move-exception v0
  006e monitor-exit v3
  0070 throw v0
  0072 invoke-static v0, Lcom/personal/aihub/PreviewServer;->closeSocket(Ljava/net/Socket;)V
  0078 monitor-exit v3
  007a goto -3dh
  007c move-exception v0
  007e monitor-exit v3
  0080 throw v0
  0082 return-void 
.end method

.method m34lambda$2$compersonalaihubPreviewServer(Ljava/net/Socket;)V
  0000 invoke-direct v2, v3, Lcom/personal/aihub/PreviewServer;->serve(Ljava/net/Socket;)V
  0006 monitor-enter v2
  0008 iget-object v0, v2, Lcom/personal/aihub/PreviewServer;->clients Ljava/util/Set;
  000c invoke-interface v0, v3, Ljava/util/Set;->remove(Ljava/lang/Object;)Z
  0012 monitor-exit v2
  0014 goto +19h
  0016 move-exception v0
  0018 monitor-exit v2
  001a throw v0
  001c move-exception v0
  001e monitor-enter v2
  0020 iget-object v1, v2, Lcom/personal/aihub/PreviewServer;->clients Ljava/util/Set;
  0024 invoke-interface v1, v3, Ljava/util/Set;->remove(Ljava/lang/Object;)Z
  002a invoke-static v3, Lcom/personal/aihub/PreviewServer;->finishSocket(Ljava/net/Socket;)V
  0030 throw v0
  0032 move-exception v3
  0034 monitor-exit v2
  0036 throw v3
  0038 monitor-enter v2
  003a iget-object v0, v2, Lcom/personal/aihub/PreviewServer;->clients Ljava/util/Set;
  003e invoke-interface v0, v3, Ljava/util/Set;->remove(Ljava/lang/Object;)Z
  0044 monitor-exit v2
  0046 invoke-static v3, Lcom/personal/aihub/PreviewServer;->finishSocket(Ljava/net/Socket;)V
  004c return-void 
  004e move-exception v3
  0050 monitor-exit v2
  0052 throw v3
.end method

.method stageCapture(Lcom/personal/aihub/StageCapture;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/PreviewServer;->stageCapture Lcom/personal/aihub/StageCapture;
  0004 return-void 
.end method

.method stageExport(Lcom/personal/aihub/StageExport;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/PreviewServer;->stageExport Lcom/personal/aihub/StageExport;
  0004 return-void 
.end method