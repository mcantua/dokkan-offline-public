.class Lcom/personal/aihub/PreviewTools;
.super Ljava/lang/Object;
.field JOBS Ljava/util/Map;
.field ORIGIN Ljava/lang/String;
.field cache Lcom/personal/aihub/PreviewCache;
.field entries Ljava/util/List;
.field key Ljava/lang/String;
.field total J
.field version Ljava/lang/String;

.method <clinit>()V
  0000 new-instance v0, Ljava/util/HashMap;
  0004 invoke-direct v0, Ljava/util/HashMap;-><init>()V
  000a sput-object v0, Lcom/personal/aihub/PreviewTools;->JOBS Ljava/util/Map;
  000e return-void 
.end method

.method <init>(Landroid/content/Context; Ljava/io/File;)V
  0000 move-object/from16 v1, v18
  0004 invoke-direct/range v18, Ljava/lang/Object;-><init>()V
  000a new-instance v0, Ljava/util/ArrayList;
  000e invoke-direct v0, Ljava/util/ArrayList;-><init>()V
  0014 iput-object v0, v1, Lcom/personal/aihub/PreviewTools;->entries Ljava/util/List;
  0018 new-instance v0, Lcom/personal/aihub/PreviewCache;
  001c move-object/from16 v2, v20
  0020 invoke-direct v0, v2, Lcom/personal/aihub/PreviewCache;-><init>(Ljava/io/File;)V
  0026 iput-object v0, v1, Lcom/personal/aihub/PreviewTools;->cache Lcom/personal/aihub/PreviewCache;
  002a invoke-virtual/range v20, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  0030 move-result-object v0
  0032 iput-object v0, v1, Lcom/personal/aihub/PreviewTools;->key Ljava/lang/String;
  0036 invoke-virtual/range v19, Landroid/content/Context;->getAssets()Landroid/content/res/AssetManager;
  003c move-result-object v0
  003e const-string v2, "ui/data/preview-bootstrap.json"
  0042 invoke-virtual v0, v2, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;
  0048 move-result-object v2
  004a new-instance v3, Ljava/io/ByteArrayOutputStream;
  004e invoke-direct v3, Ljava/io/ByteArrayOutputStream;-><init>()V
  0054 const/16 v0, 8192
  0058 new-array v0, v0, [B
  005c invoke-virtual v2, v0, Ljava/io/InputStream;->read([B)I
  0062 move-result v4
  0064 const/4 v5, 0
  0066 const/4 v6, -1
  0068 if-eq v4, v6, +017h
  006c invoke-virtual v3, Ljava/io/ByteArrayOutputStream;->size()I
  0072 move-result v6
  0074 add-int/2addr v6, v4
  0076 const/high16 v7, 262144
  007a if-gt v6, v7, +006h
  007e invoke-virtual v3, v0, v5, v4, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  0084 goto -14h
  0086 new-instance v0, Ljava/io/IOException;
  008a const-string v4, "Preview tools manifest is too large"
  008e invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0094 throw v0
  0096 new-instance v0, Lorg/json/JSONObject;
  009a new-instance v4, Ljava/lang/String;
  009e invoke-virtual v3, Ljava/io/ByteArrayOutputStream;->toByteArray()[B
  00a4 move-result-object v7
  00a6 sget-object v8, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  00aa invoke-direct v4, v7, v8, Ljava/lang/String;-><init>([B Ljava/nio/charset/Charset;)V
  00b0 invoke-direct v0, v4, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  00b6 invoke-virtual v3, Ljava/io/ByteArrayOutputStream;->close()V
  00bc if-eqz v2, +005h
  00c0 invoke-virtual v2, Ljava/io/InputStream;->close()V
  00c6 const-string v2, "schemaVersion"
  00ca invoke-virtual v0, v2, Lorg/json/JSONObject;->getInt(Ljava/lang/String;)I
  00d0 move-result v2
  00d2 const/4 v3, 1
  00d4 if-ne v2, v3, +17bh
  00d8 const-string v2, "origin"
  00dc invoke-virtual v0, v2, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  00e2 move-result-object v2
  00e4 const-string v4, "https://dokkan-eclipse.com"
  00e8 invoke-virtual v4, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00ee move-result v2
  00f0 if-eqz v2, +16dh
  00f4 const-string v2, "version"
  00f8 invoke-virtual v0, v2, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  00fe move-result-object v2
  0100 iput-object v2, v1, Lcom/personal/aihub/PreviewTools;->version Ljava/lang/String;
  0104 const-string v4, "[a-f0-9]{64}"
  0108 invoke-virtual v2, v4, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  010e move-result v2
  0110 if-eqz v2, +155h
  0114 const-string v2, "resources"
  0118 invoke-virtual v0, v2, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  011e move-result-object v0
  0120 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  0126 move-result v2
  0128 if-lt v2, v3, +141h
  012c invoke-virtual v0, Lorg/json/JSONArray;->length()I
  0132 move-result v2
  0134 const/16 v7, 256
  0138 if-gt v2, v7, +139h
  013c new-instance v2, Ljava/util/HashSet;
  0140 invoke-direct v2, Ljava/util/HashSet;-><init>()V
  0146 const-wide/16 v7, 0
  014a move v9, v5
  014c invoke-virtual v0, Lorg/json/JSONArray;->length()I
  0152 move-result v10
  0154 if-ge v9, v10, +128h
  0158 invoke-virtual v0, v9, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  015e move-result-object v10
  0160 new-instance v11, Lcom/personal/aihub/PreviewTools$Entry;
  0164 const/4 v12, 0
  0166 invoke-direct v11, v12, Lcom/personal/aihub/PreviewTools$Entry;-><init>(Lcom/personal/aihub/PreviewTools$Entry;)V
  016c const-string v12, "path"
  0170 invoke-virtual v10, v12, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0176 move-result-object v12
  0178 iput-object v12, v11, Lcom/personal/aihub/PreviewTools$Entry;->path Ljava/lang/String;
  017c const-string v12, "sha256"
  0180 invoke-virtual v10, v12, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0186 move-result-object v12
  0188 iput-object v12, v11, Lcom/personal/aihub/PreviewTools$Entry;->hash Ljava/lang/String;
  018c const-string v12, "label"
  0190 invoke-virtual v10, v12, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0196 move-result-object v12
  0198 iput-object v12, v11, Lcom/personal/aihub/PreviewTools$Entry;->label Ljava/lang/String;
  019c const-string v12, "bytes"
  01a0 invoke-virtual v10, v12, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  01a6 move-result-object v13
  01a8 invoke-virtual v10, v12, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  01ae move-result-wide v14
  01b0 new-instance v10, Ljava/net/URI;
  01b4 iget-object v12, v11, Lcom/personal/aihub/PreviewTools$Entry;->path Ljava/lang/String;
  01b8 invoke-direct v10, v12, Ljava/net/URI;-><init>(Ljava/lang/String;)V
  01be invoke-virtual v10, Ljava/net/URI;->getPath()Ljava/lang/String;
  01c4 move-result-object v12
  01c6 iget-object v3, v11, Lcom/personal/aihub/PreviewTools$Entry;->path Ljava/lang/String;
  01ca const-string v5, "/api/scripts"
  01ce invoke-virtual v3, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01d4 move-result v3
  01d6 if-nez v3, +00fh
  01da iget-object v3, v11, Lcom/personal/aihub/PreviewTools$Entry;->path Ljava/lang/String;
  01de const-string v5, "/api/script?path=ab_script%2Fcommon%2Fcommon.lua"
  01e2 invoke-virtual v3, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01e8 move-result v3
  01ea if-eqz v3, +003h
  01ee goto +3h
  01f0 const/4 v3, 0
  01f2 goto +2h
  01f4 const/4 v3, 1
  01f6 invoke-virtual v10, Ljava/net/URI;->isAbsolute()Z
  01fc move-result v5
  01fe if-nez v5, +0cbh
  0202 invoke-virtual v10, Ljava/net/URI;->getRawAuthority()Ljava/lang/String;
  0208 move-result-object v5
  020a if-nez v5, +0c5h
  020e invoke-virtual v10, Ljava/net/URI;->getRawFragment()Ljava/lang/String;
  0214 move-result-object v5
  0216 if-nez v5, +0bfh
  021a if-eqz v12, +0bdh
  021e const-string v5, "\"
  0222 invoke-virtual v12, v5, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  0228 move-result v5
  022a if-nez v5, +0b5h
  022e const-string v5, "/"
  0232 invoke-virtual v12, v5, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0238 move-result v10
  023a if-eqz v10, +0adh
  023e const-string v10, "//"
  0242 invoke-virtual v12, v10, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  0248 move-result v10
  024a if-nez v10, +0a5h
  024e const-string v10, ".*[\x00-\x1f\x7f].*"
  0252 invoke-virtual v12, v10, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0258 move-result v10
  025a if-nez v10, +09dh
  025e invoke-virtual v12, v5, v6, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  0264 move-result-object v10
  0266 invoke-static v10, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  026c move-result-object v10
  026e const-string v6, ".."
  0272 invoke-interface v10, v6, Ljava/util/List;->contains(Ljava/lang/Object;)Z
  0278 move-result v6
  027a if-nez v6, +08dh
  027e const/4 v6, -1
  0280 invoke-virtual v12, v5, v6, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  0286 move-result-object v5
  0288 invoke-static v5, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  028e move-result-object v5
  0290 const-string v10, "."
  0294 invoke-interface v5, v10, Ljava/util/List;->contains(Ljava/lang/Object;)Z
  029a move-result v5
  029c if-nez v5, +07ch
  02a0 const-string v5, "/tools/"
  02a4 invoke-virtual v12, v5, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  02aa move-result v5
  02ac if-nez v5, +014h
  02b0 const-string v5, "/static/"
  02b4 invoke-virtual v12, v5, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  02ba move-result v5
  02bc if-nez v5, +00ch
  02c0 const-string v5, "/css/"
  02c4 invoke-virtual v12, v5, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  02ca move-result v5
  02cc if-nez v5, +004h
  02d0 if-eqz v3, +062h
  02d4 iget-object v3, v11, Lcom/personal/aihub/PreviewTools$Entry;->path Ljava/lang/String;
  02d8 invoke-virtual v2, v3, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  02de move-result v3
  02e0 if-eqz v3, +05ah
  02e4 instance-of v3, v13, Ljava/lang/Number;
  02e8 if-eqz v3, +04eh
  02ec check-cast v13, Ljava/lang/Number;
  02f0 invoke-virtual v13, Ljava/lang/Number;->doubleValue()D
  02f6 move-result-wide v12
  02f8 move-wide/from16 v16, v7
  02fc long-to-double v6, v14
  02fe cmpl-double v5, v12, v6
  0302 if-nez v5, +041h
  0306 const-wide/16 v5, 1
  030a cmp-long v5, v14, v5
  030e if-ltz v5, +03bh
  0312 const-wide/32 v5, 2097152
  0318 cmp-long v5, v14, v5
  031c if-gtz v5, +034h
  0320 iget-object v5, v11, Lcom/personal/aihub/PreviewTools$Entry;->hash Ljava/lang/String;
  0324 invoke-virtual v5, v4, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  032a move-result v5
  032c if-eqz v5, +02ch
  0330 iget-object v5, v11, Lcom/personal/aihub/PreviewTools$Entry;->label Ljava/lang/String;
  0334 invoke-virtual v5, Ljava/lang/String;->length()I
  033a move-result v5
  033c const/16 v6, 160
  0340 if-gt v5, v6, +022h
  0344 long-to-int v5, v14
  0346 iput v5, v11, Lcom/personal/aihub/PreviewTools$Entry;->bytes I
  034a add-long v7, v16, v14
  034e const-wide/32 v5, 16777216
  0354 cmp-long v5, v7, v5
  0358 if-gtz v5, +00eh
  035c iget-object v5, v1, Lcom/personal/aihub/PreviewTools;->entries Ljava/util/List;
  0360 invoke-interface v5, v11, Ljava/util/List;->add(Ljava/lang/Object;)Z
  0366 add-int/lit8 v9, v9, 1
  036a const/4 v3, 1
  036c const/4 v5, 0
  036e const/4 v6, -1
  0370 goto/16 -112h
  0374 new-instance v0, Ljava/io/IOException;
  0378 const-string v2, "Preview tools exceed their size limit"
  037c invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0382 throw v0
  0384 new-instance v0, Ljava/io/IOException;
  0388 const-string v2, "Invalid preview tools checksum or size"
  038c invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0392 throw v0
  0394 new-instance v0, Ljava/io/IOException;
  0398 const-string v2, "Invalid preview tools resource"
  039c invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03a2 throw v0
  03a4 iput-wide v7, v1, Lcom/personal/aihub/PreviewTools;->total J
  03a8 return-void 
  03aa new-instance v0, Ljava/io/IOException;
  03ae const-string v2, "Invalid preview tools count"
  03b2 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03b8 throw v0
  03ba new-instance v0, Ljava/io/IOException;
  03be const-string v2, "Invalid preview tools version"
  03c2 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03c8 throw v0
  03ca new-instance v0, Ljava/io/IOException;
  03ce const-string v2, "Unsupported preview tools manifest"
  03d2 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03d8 throw v0
  03da move-exception v0
  03dc move-object v4, v0
  03de invoke-virtual v3, Ljava/io/ByteArrayOutputStream;->close()V
  03e4 goto +6h
  03e6 move-exception v0
  03e8 move-object v3, v0
  03ea invoke-virtual v4, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  03f0 throw v4
  03f2 move-exception v0
  03f4 move-object v3, v0
  03f6 if-eqz v2, +00bh
  03fa invoke-virtual v2, Ljava/io/InputStream;->close()V
  0400 goto +6h
  0402 move-exception v0
  0404 move-object v2, v0
  0406 invoke-virtual v3, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  040c throw v3
.end method

.method job()Lcom/personal/aihub/PreviewTools$Job;
  0000 sget-object v0, Lcom/personal/aihub/PreviewTools;->JOBS Ljava/util/Map;
  0004 monitor-enter v0
  0006 iget-object v1, v3, Lcom/personal/aihub/PreviewTools;->key Ljava/lang/String;
  000a invoke-interface v0, v1, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0010 move-result-object v1
  0012 check-cast v1, Lcom/personal/aihub/PreviewTools$Job;
  0016 if-nez v1, +00dh
  001a new-instance v1, Lcom/personal/aihub/PreviewTools$Job;
  001e const/4 v2, 0
  0020 invoke-direct v1, v2, Lcom/personal/aihub/PreviewTools$Job;-><init>(Lcom/personal/aihub/PreviewTools$Job;)V
  0026 iget-object v2, v3, Lcom/personal/aihub/PreviewTools;->key Ljava/lang/String;
  002a invoke-interface v0, v2, v1, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0030 monitor-exit v0
  0032 return-object v1
  0034 move-exception v1
  0036 monitor-exit v0
  0038 throw v1
.end method

.method matches(Lcom/personal/aihub/PreviewTools$Entry;)Z
  0000 iget-object v0, v9, Lcom/personal/aihub/PreviewTools;->cache Lcom/personal/aihub/PreviewCache;
  0004 new-instance v1, Ljava/lang/StringBuilder;
  0008 const-string v2, "https://dokkan-eclipse.com"
  000c invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0012 iget-object v2, v10, Lcom/personal/aihub/PreviewTools$Entry;->path Ljava/lang/String;
  0016 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  001c invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0022 move-result-object v1
  0024 invoke-virtual v0, v1, Lcom/personal/aihub/PreviewCache;->cachedBody(Ljava/lang/String;)Ljava/io/File;
  002a move-result-object v0
  002c const/4 v1, 0
  002e if-eqz v0, +07dh
  0032 invoke-virtual v0, Ljava/io/File;->length()J
  0038 move-result-wide v2
  003a iget v4, v10, Lcom/personal/aihub/PreviewTools$Entry;->bytes I
  003e int-to-long v4, v4
  0040 cmp-long v2, v2, v4
  0044 if-eqz v2, +003h
  0048 goto +70h
  004a const-string v2, "SHA-256"
  004e invoke-static v2, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;
  0054 move-result-object v2
  0056 new-instance v3, Ljava/io/FileInputStream;
  005a invoke-direct v3, v0, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0060 const/16 v0, 8192
  0064 new-array v0, v0, [B
  0068 const-wide/16 v4, 0
  006c invoke-virtual v3, v0, Ljava/io/FileInputStream;->read([B)I
  0072 move-result v6
  0074 const/4 v7, -1
  0076 if-eq v6, v7, +013h
  007a int-to-long v7, v6
  007c add-long/2addr v4, v7
  007e iget v7, v10, Lcom/personal/aihub/PreviewTools$Entry;->bytes I
  0082 int-to-long v7, v7
  0084 cmp-long v7, v4, v7
  0088 if-lez v7, +006h
  008c invoke-virtual v3, Ljava/io/FileInputStream;->close()V
  0092 return v1
  0094 invoke-virtual v2, v0, v1, v6, Ljava/security/MessageDigest;->update([B I I)V
  009a goto -17h
  009c invoke-virtual v3, Ljava/io/FileInputStream;->close()V
  00a2 iget v0, v10, Lcom/personal/aihub/PreviewTools$Entry;->bytes I
  00a6 int-to-long v6, v0
  00a8 cmp-long v0, v4, v6
  00ac if-eqz v0, +003h
  00b0 return v1
  00b2 new-instance v0, Ljava/lang/StringBuilder;
  00b6 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  00bc invoke-virtual v2, Ljava/security/MessageDigest;->digest()[B
  00c2 move-result-object v2
  00c4 array-length v3, v2
  00c6 if-ge v1, v3, +01ch
  00ca aget-byte v4, v2, v1
  00ce sget-object v5, Ljava/util/Locale;->US Ljava/util/Locale;
  00d2 and-int/lit16 v4, v4, 255
  00d6 invoke-static v4, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  00dc move-result-object v4
  00de filled-new-array v4, [Ljava/lang/Object;
  00e4 move-result-object v4
  00e6 const-string v6, "%02x"
  00ea invoke-static v5, v6, v4, Ljava/lang/String;->format(Ljava/util/Locale; Ljava/lang/String; [Ljava/lang/Object;)Ljava/lang/String;
  00f0 move-result-object v4
  00f2 invoke-virtual v0, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00f8 add-int/lit8 v1, v1, 1
  00fc goto -1bh
  00fe iget-object v10, v10, Lcom/personal/aihub/PreviewTools$Entry;->hash Ljava/lang/String;
  0102 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0108 move-result-object v0
  010a invoke-virtual v10, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0110 move-result v10
  0112 return v10
  0114 move-exception v10
  0116 invoke-virtual v3, Ljava/io/FileInputStream;->close()V
  011c goto +5h
  011e move-exception v0
  0120 invoke-virtual v10, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0126 throw v10
  0128 return v1
.end method

.method status(Lcom/personal/aihub/PreviewTools$Job;)Lorg/json/JSONObject;
  0000 iget-object v0, v11, Lcom/personal/aihub/PreviewTools;->entries Ljava/util/List;
  0004 invoke-interface v0, Ljava/util/List;->iterator()Ljava/util/Iterator;
  000a move-result-object v0
  000c const-wide/16 v1, 0
  0010 const/4 v3, 0
  0012 move v4, v3
  0014 move v5, v4
  0016 move v6, v5
  0018 invoke-interface v0, Ljava/util/Iterator;->hasNext()Z
  001e move-result v7
  0020 if-eqz v7, +036h
  0024 invoke-interface v0, Ljava/util/Iterator;->next()Ljava/lang/Object;
  002a move-result-object v7
  002c check-cast v7, Lcom/personal/aihub/PreviewTools$Entry;
  0030 iget-object v8, v11, Lcom/personal/aihub/PreviewTools;->cache Lcom/personal/aihub/PreviewCache;
  0034 new-instance v9, Ljava/lang/StringBuilder;
  0038 invoke-direct v9, Ljava/lang/StringBuilder;-><init>()V
  003e const-string v10, "https://dokkan-eclipse.com"
  0042 invoke-virtual v9, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0048 iget-object v10, v7, Lcom/personal/aihub/PreviewTools$Entry;->path Ljava/lang/String;
  004c invoke-virtual v9, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0052 invoke-virtual v9, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0058 move-result-object v9
  005a invoke-virtual v8, v9, Lcom/personal/aihub/PreviewCache;->cachedBody(Ljava/lang/String;)Ljava/io/File;
  0060 move-result-object v8
  0062 if-nez v8, +005h
  0066 add-int/lit8 v5, v5, 1
  006a goto -29h
  006c invoke-direct v11, v7, Lcom/personal/aihub/PreviewTools;->matches(Lcom/personal/aihub/PreviewTools$Entry;)Z
  0072 move-result v8
  0074 if-eqz v8, +009h
  0078 add-int/lit8 v4, v4, 1
  007c iget v7, v7, Lcom/personal/aihub/PreviewTools$Entry;->bytes I
  0080 int-to-long v7, v7
  0082 add-long/2addr v1, v7
  0084 goto -36h
  0086 add-int/lit8 v6, v6, 1
  008a goto -39h
  008c monitor-enter v12
  008e new-instance v0, Lorg/json/JSONArray;
  0092 iget-object v7, v12, Lcom/personal/aihub/PreviewTools$Job;->failures Lorg/json/JSONArray;
  0096 invoke-virtual v7, Lorg/json/JSONArray;->toString()Ljava/lang/String;
  009c move-result-object v7
  009e invoke-direct v0, v7, Lorg/json/JSONArray;-><init>(Ljava/lang/String;)V
  00a4 monitor-exit v12
  00a6 new-instance v7, Lorg/json/JSONObject;
  00aa invoke-direct v7, Lorg/json/JSONObject;-><init>()V
  00b0 const-string v8, "version"
  00b4 iget-object v9, v11, Lcom/personal/aihub/PreviewTools;->version Ljava/lang/String;
  00b8 invoke-virtual v7, v8, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00be move-result-object v7
  00c0 const-string v8, "ready"
  00c4 iget-object v9, v11, Lcom/personal/aihub/PreviewTools;->entries Ljava/util/List;
  00c8 invoke-interface v9, Ljava/util/List;->size()I
  00ce move-result v9
  00d0 if-ne v4, v9, +003h
  00d4 const/4 v3, 1
  00d6 invoke-virtual v7, v8, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  00dc move-result-object v3
  00de const-string v7, "preparing"
  00e2 iget-boolean v8, v12, Lcom/personal/aihub/PreviewTools$Job;->preparing Z
  00e6 invoke-virtual v3, v7, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  00ec move-result-object v3
  00ee const-string v7, "preparedFiles"
  00f2 invoke-virtual v3, v7, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  00f8 move-result-object v3
  00fa const-string v4, "totalFiles"
  00fe iget-object v7, v11, Lcom/personal/aihub/PreviewTools;->entries Ljava/util/List;
  0102 invoke-interface v7, Ljava/util/List;->size()I
  0108 move-result v7
  010a invoke-virtual v3, v4, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0110 move-result-object v3
  0112 const-string v4, "preparedBytes"
  0116 invoke-virtual v3, v4, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  011c move-result-object v1
  011e const-string v2, "totalBytes"
  0122 iget-wide v3, v11, Lcom/personal/aihub/PreviewTools;->total J
  0126 invoke-virtual v1, v2, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  012c move-result-object v1
  012e const-string v2, "missingFiles"
  0132 invoke-virtual v1, v2, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0138 move-result-object v1
  013a const-string v2, "invalidFiles"
  013e invoke-virtual v1, v2, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0144 move-result-object v1
  0146 const-string v2, "offline"
  014a iget-object v3, v11, Lcom/personal/aihub/PreviewTools;->cache Lcom/personal/aihub/PreviewCache;
  014e invoke-virtual v3, Lcom/personal/aihub/PreviewCache;->offline()Z
  0154 move-result v3
  0156 invoke-virtual v1, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  015c move-result-object v1
  015e const-string v2, "failures"
  0162 invoke-virtual v1, v2, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0168 move-result-object v0
  016a const-string v1, "currentLabel"
  016e iget-object v12, v12, Lcom/personal/aihub/PreviewTools$Job;->label Ljava/lang/String;
  0172 invoke-virtual v0, v1, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0178 move-result-object v12
  017a return-object v12
  017c move-exception v0
  017e monitor-exit v12
  0180 throw v0
.end method

.method m35lambda$0$compersonalaihubPreviewTools(Lcom/personal/aihub/PreviewTools$Job; J)V
  0000 const/4 v0, 0
  0002 iget-object v1, v7, Lcom/personal/aihub/PreviewTools;->entries Ljava/util/List;
  0006 invoke-interface v1, Ljava/util/List;->iterator()Ljava/util/Iterator;
  000c move-result-object v1
  000e invoke-interface v1, Ljava/util/Iterator;->hasNext()Z
  0014 move-result v2
  0016 if-eqz v2, +0d3h
  001a invoke-interface v1, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0020 move-result-object v2
  0022 check-cast v2, Lcom/personal/aihub/PreviewTools$Entry;
  0026 iget-object v3, v7, Lcom/personal/aihub/PreviewTools;->cache Lcom/personal/aihub/PreviewCache;
  002a invoke-virtual v3, Lcom/personal/aihub/PreviewCache;->revision()J
  0030 move-result-wide v3
  0032 cmp-long v3, v3, v9
  0036 if-eqz v3, +004h
  003a goto/16 +0c1h
  003e iget-object v3, v2, Lcom/personal/aihub/PreviewTools$Entry;->label Ljava/lang/String;
  0042 iput-object v3, v8, Lcom/personal/aihub/PreviewTools$Job;->label Ljava/lang/String;
  0046 invoke-direct v7, v2, Lcom/personal/aihub/PreviewTools;->matches(Lcom/personal/aihub/PreviewTools$Entry;)Z
  004c move-result v3
  004e if-nez v3, -020h
  0052 iget-object v3, v7, Lcom/personal/aihub/PreviewTools;->cache Lcom/personal/aihub/PreviewCache;
  0056 invoke-virtual v3, Lcom/personal/aihub/PreviewCache;->offline()Z
  005c move-result v3
  005e if-nez v3, +05bh
  0062 iget-object v3, v7, Lcom/personal/aihub/PreviewTools;->cache Lcom/personal/aihub/PreviewCache;
  0066 new-instance v4, Ljava/lang/StringBuilder;
  006a invoke-direct v4, Ljava/lang/StringBuilder;-><init>()V
  0070 const-string v5, "https://dokkan-eclipse.com"
  0074 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  007a iget-object v5, v2, Lcom/personal/aihub/PreviewTools$Entry;->path Ljava/lang/String;
  007e invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0084 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  008a move-result-object v4
  008c invoke-virtual v3, v4, Lcom/personal/aihub/PreviewCache;->discard(Ljava/lang/String;)V
  0092 iget-object v3, v7, Lcom/personal/aihub/PreviewTools;->cache Lcom/personal/aihub/PreviewCache;
  0096 new-instance v4, Ljava/lang/StringBuilder;
  009a invoke-direct v4, Ljava/lang/StringBuilder;-><init>()V
  00a0 const-string v5, "https://dokkan-eclipse.com"
  00a4 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00aa iget-object v5, v2, Lcom/personal/aihub/PreviewTools$Entry;->path Ljava/lang/String;
  00ae invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00b4 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00ba move-result-object v4
  00bc iget v5, v2, Lcom/personal/aihub/PreviewTools$Entry;->bytes I
  00c0 invoke-virtual v3, v4, v5, v9, v10, Lcom/personal/aihub/PreviewCache;->prepareBody(Ljava/lang/String; I J)Ljava/io/File;
  00c6 invoke-direct v7, v2, Lcom/personal/aihub/PreviewTools;->matches(Lcom/personal/aihub/PreviewTools$Entry;)Z
  00cc move-result v3
  00ce if-eqz v3, +003h
  00d2 goto -62h
  00d4 iget-object v3, v7, Lcom/personal/aihub/PreviewTools;->cache Lcom/personal/aihub/PreviewCache;
  00d8 new-instance v4, Ljava/lang/StringBuilder;
  00dc invoke-direct v4, Ljava/lang/StringBuilder;-><init>()V
  00e2 const-string v5, "https://dokkan-eclipse.com"
  00e6 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00ec iget-object v5, v2, Lcom/personal/aihub/PreviewTools$Entry;->path Ljava/lang/String;
  00f0 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00f6 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00fc move-result-object v4
  00fe invoke-virtual v3, v4, Lcom/personal/aihub/PreviewCache;->discard(Ljava/lang/String;)V
  0104 new-instance v3, Ljava/io/IOException;
  0108 const-string v4, "The hosted tool changed. Update the app before saving this version."
  010c invoke-direct v3, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0112 throw v3
  0114 new-instance v3, Ljava/io/IOException;
  0118 const-string v4, "Offline preview is enabled. Connect again to finish preparing the player."
  011c invoke-direct v3, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0122 throw v3
  0124 move-exception v3
  0126 monitor-enter v8
  0128 iget-object v4, v8, Lcom/personal/aihub/PreviewTools$Job;->failures Lorg/json/JSONArray;
  012c invoke-virtual v4, Lorg/json/JSONArray;->length()I
  0132 move-result v4
  0134 const/16 v5, 20
  0138 if-ge v4, v5, +027h
  013c iget-object v4, v8, Lcom/personal/aihub/PreviewTools$Job;->failures Lorg/json/JSONArray;
  0140 new-instance v5, Lorg/json/JSONObject;
  0144 invoke-direct v5, Lorg/json/JSONObject;-><init>()V
  014a const-string v6, "path"
  014e iget-object v2, v2, Lcom/personal/aihub/PreviewTools$Entry;->path Ljava/lang/String;
  0152 invoke-virtual v5, v6, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0158 move-result-object v2
  015a const-string v5, "message"
  015e invoke-virtual v3, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  0164 move-result-object v6
  0166 if-nez v6, +005h
  016a const-string v3, "Could not save preview tool"
  016e goto +5h
  0170 invoke-virtual v3, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  0176 move-result-object v3
  0178 invoke-virtual v2, v5, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  017e move-result-object v2
  0180 invoke-virtual v4, v2, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0186 iget-object v2, v7, Lcom/personal/aihub/PreviewTools;->cache Lcom/personal/aihub/PreviewCache;
  018a invoke-virtual v2, Lcom/personal/aihub/PreviewCache;->offline()Z
  0190 move-result v2
  0192 if-nez v2, +010h
  0196 iget-object v2, v7, Lcom/personal/aihub/PreviewTools;->cache Lcom/personal/aihub/PreviewCache;
  019a invoke-virtual v2, Lcom/personal/aihub/PreviewCache;->revision()J
  01a0 move-result-wide v2
  01a2 cmp-long v2, v2, v9
  01a6 if-eqz v2, +003h
  01aa goto +4h
  01ac monitor-exit v8
  01ae goto/16 -0d0h
  01b2 monitor-exit v8
  01b4 goto +4h
  01b6 move-exception v9
  01b8 monitor-exit v8
  01ba throw v9
  01bc const-string v9, ""
  01c0 iput-object v9, v8, Lcom/personal/aihub/PreviewTools$Job;->label Ljava/lang/String;
  01c4 iput-boolean v0, v8, Lcom/personal/aihub/PreviewTools$Job;->preparing Z
  01c8 return-void 
  01ca move-exception v9
  01cc const-string v10, ""
  01d0 iput-object v10, v8, Lcom/personal/aihub/PreviewTools$Job;->label Ljava/lang/String;
  01d4 iput-boolean v0, v8, Lcom/personal/aihub/PreviewTools$Job;->preparing Z
  01d8 throw v9
.end method

.method request(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 invoke-virtual v6, Lorg/json/JSONObject;->keys()Ljava/util/Iterator;
  0006 move-result-object v0
  0008 invoke-interface v0, Ljava/util/Iterator;->hasNext()Z
  000e move-result v1
  0010 if-eqz v1, +021h
  0014 invoke-interface v0, Ljava/util/Iterator;->next()Ljava/lang/Object;
  001a move-result-object v1
  001c check-cast v1, Ljava/lang/String;
  0020 const-string v2, "prepare"
  0024 invoke-virtual v1, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  002a move-result v2
  002c if-eqz v2, +00bh
  0030 invoke-virtual v6, v1, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  0036 move-result-object v1
  0038 instance-of v1, v1, Ljava/lang/Boolean;
  003c if-eqz v1, +003h
  0040 goto -1ch
  0042 new-instance v6, Ljava/io/IOException;
  0046 const-string v0, "Invalid preview tools request"
  004a invoke-direct v6, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0050 throw v6
  0052 invoke-direct v5, Lcom/personal/aihub/PreviewTools;->job()Lcom/personal/aihub/PreviewTools$Job;
  0058 move-result-object v0
  005a const-string v1, "prepare"
  005e invoke-virtual v6, v1, Lorg/json/JSONObject;->optBoolean(Ljava/lang/String;)Z
  0064 move-result v6
  0066 if-eqz v6, +03fh
  006a monitor-enter v0
  006c iget-boolean v6, v0, Lcom/personal/aihub/PreviewTools$Job;->preparing Z
  0070 if-nez v6, +035h
  0074 iget-object v6, v5, Lcom/personal/aihub/PreviewTools;->cache Lcom/personal/aihub/PreviewCache;
  0078 invoke-virtual v6, Lcom/personal/aihub/PreviewCache;->offline()Z
  007e move-result v6
  0080 if-nez v6, +025h
  0084 const/4 v6, 1
  0086 iput-boolean v6, v0, Lcom/personal/aihub/PreviewTools$Job;->preparing Z
  008a new-instance v1, Lorg/json/JSONArray;
  008e invoke-direct v1, Lorg/json/JSONArray;-><init>()V
  0094 iput-object v1, v0, Lcom/personal/aihub/PreviewTools$Job;->failures Lorg/json/JSONArray;
  0098 iget-object v1, v5, Lcom/personal/aihub/PreviewTools;->cache Lcom/personal/aihub/PreviewCache;
  009c invoke-virtual v1, Lcom/personal/aihub/PreviewCache;->revision()J
  00a2 move-result-wide v1
  00a4 new-instance v3, Ljava/lang/Thread;
  00a8 new-instance v4, Lcom/personal/aihub/PreviewTools$1;
  00ac invoke-direct v4, v5, v0, v1, v2, Lcom/personal/aihub/PreviewTools$1;-><init>(Lcom/personal/aihub/PreviewTools; Lcom/personal/aihub/PreviewTools$Job; J)V
  00b2 const-string v1, "forge-preview-tools"
  00b6 invoke-direct v3, v4, v1, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable; Ljava/lang/String;)V
  00bc invoke-virtual v3, v6, Ljava/lang/Thread;->setDaemon(Z)V
  00c2 invoke-virtual v3, Ljava/lang/Thread;->start()V
  00c8 goto +9h
  00ca new-instance v6, Ljava/io/IOException;
  00ce const-string v1, "Connect once and switch off Offline preview to prepare the player tools."
  00d2 invoke-direct v6, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00d8 throw v6
  00da monitor-exit v0
  00dc goto +4h
  00de move-exception v6
  00e0 monitor-exit v0
  00e2 throw v6
  00e4 invoke-direct v5, v0, Lcom/personal/aihub/PreviewTools;->status(Lcom/personal/aihub/PreviewTools$Job;)Lorg/json/JSONObject;
  00ea move-result-object v6
  00ec return-object v6
.end method