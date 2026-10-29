.class Lcom/personal/aihub/GameDirectory;
.super Ljava/lang/Object;
.field assets Lcom/personal/aihub/GameAssets;
.field overlays Lorg/json/JSONArray;
.field preferred Ljava/lang/String;
.field root Ljava/io/File;

.method <init>(Ljava/io/File;)V
  0000 const/4 v0, 0
  0002 invoke-direct v1, v2, v0, v0, Lcom/personal/aihub/GameDirectory;-><init>(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray;)V
  0008 return-void 
.end method

.method <init>(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray;)V
  0000 invoke-direct v1, Ljava/lang/Object;-><init>()V
  0006 iput-object v2, v1, Lcom/personal/aihub/GameDirectory;->root Ljava/io/File;
  000a iput-object v3, v1, Lcom/personal/aihub/GameDirectory;->preferred Ljava/lang/String;
  000e iput-object v4, v1, Lcom/personal/aihub/GameDirectory;->overlays Lorg/json/JSONArray;
  0012 new-instance v0, Lcom/personal/aihub/GameAssets;
  0016 invoke-direct v0, v2, v3, v4, Lcom/personal/aihub/GameAssets;-><init>(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray;)V
  001c iput-object v0, v1, Lcom/personal/aihub/GameDirectory;->assets Lcom/personal/aihub/GameAssets;
  0020 return-void 
.end method

.method bound(Ljava/util/Map;)V
  0000 invoke-interface v1, Ljava/util/Map;->size()I
  0006 move-result v1
  0008 const/16 v0, 200
  000c if-gt v1, v0, +003h
  0010 return-void 
  0012 new-instance v1, Ljava/io/IOException;
  0016 const-string v0, "This visual pack has more than 200 files. Choose a smaller pack."
  001a invoke-direct v1, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0020 throw v1
.end method

.method directory(Ljava/lang/String;)Ljava/io/File;
  0000 iget-object v0, v6, Lcom/personal/aihub/GameDirectory;->root Ljava/io/File;
  0004 invoke-virtual v0, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  000a move-result-object v0
  000c iget-object v1, v6, Lcom/personal/aihub/GameDirectory;->root Ljava/io/File;
  0010 const-string v2, "/"
  0014 invoke-virtual v7, v2, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  001a move-result-object v7
  001c array-length v2, v7
  001e const/4 v3, 0
  0020 if-ge v3, v2, +027h
  0024 new-instance v4, Ljava/io/File;
  0028 aget-object v5, v7, v3
  002c invoke-direct v4, v1, v5, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0032 invoke-virtual v4, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0038 move-result-object v1
  003a invoke-static v1, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  0040 move-result v1
  0042 if-nez v1, +00eh
  0046 invoke-virtual v4, Ljava/io/File;->isDirectory()Z
  004c move-result v1
  004e if-nez v1, +004h
  0052 const/4 v7, 0
  0054 return-object v7
  0056 add-int/lit8 v3, v3, 1
  005a move-object v1, v4
  005c goto -1eh
  005e new-instance v7, Ljava/io/IOException;
  0062 const-string v0, "Imported game assets cannot use symbolic links"
  0066 invoke-direct v7, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  006c throw v7
  006e invoke-virtual v1, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  0074 move-result-object v7
  0076 invoke-virtual v7, Ljava/io/File;->getPath()Ljava/lang/String;
  007c move-result-object v1
  007e new-instance v2, Ljava/lang/StringBuilder;
  0082 invoke-direct v2, Ljava/lang/StringBuilder;-><init>()V
  0088 invoke-static v0, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  008e move-result-object v0
  0090 invoke-virtual v2, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0096 sget-object v0, Ljava/io/File;->separator Ljava/lang/String;
  009a invoke-virtual v2, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00a0 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00a6 move-result-object v0
  00a8 invoke-virtual v1, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00ae move-result v0
  00b0 if-eqz v0, +003h
  00b4 return-object v7
  00b6 new-instance v7, Ljava/io/IOException;
  00ba const-string v0, "Imported game folder escapes its resource folder"
  00be invoke-direct v7, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00c4 throw v7
.end method

.method item(Ljava/lang/String; Ljava/lang/String; Ljava/io/File;)Lorg/json/JSONObject;
  0000 new-instance v0, Lorg/json/JSONObject;
  0004 invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  000a const-string v1, "type"
  000e const-string v2, "file"
  0012 invoke-virtual v0, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0018 move-result-object v0
  001a const-string v1, "name"
  001e invoke-virtual v0, v1, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0024 move-result-object v0
  0026 new-instance v1, Ljava/lang/StringBuilder;
  002a invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  0030 invoke-static v3, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0036 move-result-object v3
  0038 invoke-virtual v1, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  003e const-string v3, "/"
  0042 invoke-virtual v1, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0048 invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  004e invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0054 move-result-object v3
  0056 const-string v4, "path"
  005a invoke-virtual v0, v4, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0060 move-result-object v3
  0062 const-string v4, "size"
  0066 invoke-virtual v5, Ljava/io/File;->length()J
  006c move-result-wide v0
  006e invoke-virtual v3, v4, v0, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0074 move-result-object v3
  0076 const-string v4, "source"
  007a const-string v5, "imported"
  007e invoke-virtual v3, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0084 move-result-object v3
  0086 return-object v3
.end method

.method lambda$0(Ljava/io/File; Ljava/io/File;)I
  0000 invoke-virtual v5, Ljava/io/File;->lastModified()J
  0006 move-result-wide v0
  0008 invoke-virtual v4, Ljava/io/File;->lastModified()J
  000e move-result-wide v2
  0010 invoke-static v0, v1, v2, v3, Ljava/lang/Long;->compare(J J)I
  0016 move-result v0
  0018 if-eqz v0, +003h
  001c goto +dh
  001e invoke-virtual v4, Ljava/io/File;->getName()Ljava/lang/String;
  0024 move-result-object v4
  0026 invoke-virtual v5, Ljava/io/File;->getName()Ljava/lang/String;
  002c move-result-object v5
  002e invoke-virtual v4, v5, Ljava/lang/String;->compareTo(Ljava/lang/String;)I
  0034 move-result v0
  0036 return v0
.end method

.method merge(Lorg/json/JSONObject; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 move-object/from16 v0, v17
  0004 move-object/from16 v1, v18
  0008 if-eqz v0, +119h
  000c if-eqz v1, +117h
  0010 const-string v2, "path"
  0014 invoke-virtual v0, v2, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  001a move-result-object v3
  001c invoke-virtual v1, v2, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0022 move-result-object v4
  0024 invoke-virtual v3, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  002a move-result v3
  002c if-eqz v3, +107h
  0030 const-string v3, "items"
  0034 invoke-virtual v1, v3, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  003a move-result-object v4
  003c if-eqz v4, +0ffh
  0040 new-instance v4, Ljava/util/TreeMap;
  0044 invoke-direct v4, Ljava/util/TreeMap;-><init>()V
  004a invoke-virtual v1, v3, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0050 move-result-object v1
  0052 invoke-virtual v0, v2, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0058 move-result-object v5
  005a const/4 v7, 0
  005c invoke-virtual v1, Lorg/json/JSONArray;->length()I
  0062 move-result v8
  0064 const-string v9, "name"
  0068 if-ge v7, v8, +0a3h
  006c invoke-virtual v1, v7, Lorg/json/JSONArray;->optJSONObject(I)Lorg/json/JSONObject;
  0072 move-result-object v8
  0074 if-nez v8, +006h
  0078 move-object/from16 v16, v1
  007c goto/16 +091h
  0080 invoke-virtual v8, v9, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0086 move-result-object v10
  0088 invoke-virtual v8, v2, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  008e move-result-object v11
  0090 const-wide/16 v12, -1
  0094 const-string v14, "size"
  0098 invoke-virtual v8, v14, v12, v13, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  009e move-result-wide v12
  00a0 const-string v15, "type"
  00a4 invoke-virtual v8, v15, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  00aa move-result-object v8
  00ac const-string v6, "file"
  00b0 invoke-virtual v8, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00b6 move-result v8
  00b8 if-eqz v8, -020h
  00bc const-string v8, "/"
  00c0 invoke-virtual v10, v8, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  00c6 move-result v16
  00c8 if-nez v16, -028h
  00cc invoke-static v10, Lcom/personal/aihub/GameDirectory;->visual(Ljava/lang/String;)Z
  00d2 move-result v16
  00d4 if-eqz v16, -02eh
  00d8 move-object/from16 v16, v1
  00dc new-instance v1, Ljava/lang/StringBuilder;
  00e0 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  00e6 invoke-static v5, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  00ec move-result-object v0
  00ee invoke-virtual v1, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00f4 invoke-virtual v1, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00fa invoke-virtual v1, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0100 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0106 move-result-object v0
  0108 invoke-virtual v11, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  010e move-result v0
  0110 if-eqz v0, +047h
  0114 new-instance v0, Ljava/lang/StringBuilder;
  0118 const-string v1, "/assets/"
  011c invoke-direct v0, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0122 invoke-virtual v0, v11, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0128 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  012e move-result-object v0
  0130 invoke-static v0, Lcom/personal/aihub/GameAssets;->gamePath(Ljava/lang/String;)Ljava/lang/String;
  0136 move-result-object v0
  0138 invoke-virtual v11, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  013e move-result v0
  0140 if-eqz v0, +02fh
  0144 const-wide/16 v0, 0
  0148 cmp-long v0, v12, v0
  014c if-ltz v0, +029h
  0150 const-wide/32 v0, 167772160
  0156 cmp-long v0, v12, v0
  015a if-gtz v0, +022h
  015e new-instance v0, Lorg/json/JSONObject;
  0162 invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  0168 invoke-virtual v0, v9, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  016e move-result-object v0
  0170 invoke-virtual v0, v2, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0176 move-result-object v0
  0178 invoke-virtual v0, v15, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  017e move-result-object v0
  0180 invoke-virtual v0, v14, v12, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0186 move-result-object v0
  0188 const-string v1, "source"
  018c const-string v6, "public"
  0190 invoke-virtual v0, v1, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0196 move-result-object v0
  0198 invoke-virtual v4, v10, v0, Ljava/util/TreeMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  019e add-int/lit8 v7, v7, 1
  01a2 move-object/from16 v0, v17
  01a6 move-object/from16 v1, v16
  01aa goto/16 -0a7h
  01ae invoke-virtual v0, v3, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  01b4 move-result-object v1
  01b6 const/4 v6, 0
  01b8 invoke-virtual v1, Lorg/json/JSONArray;->length()I
  01be move-result v2
  01c0 if-ge v6, v2, +010h
  01c4 invoke-virtual v1, v6, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  01ca move-result-object v2
  01cc invoke-virtual v2, v9, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  01d2 move-result-object v5
  01d4 invoke-virtual v4, v5, v2, Ljava/util/TreeMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  01da add-int/lit8 v6, v6, 1
  01de goto -13h
  01e0 invoke-static v4, Lcom/personal/aihub/GameDirectory;->bound(Ljava/util/Map;)V
  01e6 new-instance v1, Lorg/json/JSONObject;
  01ea invoke-virtual/range v17, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  01f0 move-result-object v0
  01f2 invoke-direct v1, v0, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  01f8 new-instance v0, Lorg/json/JSONArray;
  01fc invoke-direct v0, Lorg/json/JSONArray;-><init>()V
  0202 invoke-virtual v4, Ljava/util/TreeMap;->values()Ljava/util/Collection;
  0208 move-result-object v2
  020a invoke-interface v2, Ljava/util/Collection;->iterator()Ljava/util/Iterator;
  0210 move-result-object v2
  0212 invoke-interface v2, Ljava/util/Iterator;->hasNext()Z
  0218 move-result v4
  021a if-eqz v4, +00ch
  021e invoke-interface v2, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0224 move-result-object v4
  0226 check-cast v4, Lorg/json/JSONObject;
  022a invoke-virtual v0, v4, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0230 goto -fh
  0232 invoke-virtual v1, v3, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0238 move-result-object v0
  023a return-object v0
.end method

.method route(Ljava/lang/String;)Ljava/lang/String;
  0000 const-string v0, "/forge-directory-probe.lwf"
  0004 const-string v1, "UTF-8"
  0008 const-string v2, "https://dokkan-eclipse.com"
  000c const/4 v3, 0
  000e const-string v4, "/"
  0012 invoke-virtual v11, v4, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0018 move-result v4
  001a if-eqz v4, +00eh
  001e new-instance v4, Ljava/lang/StringBuilder;
  0022 invoke-direct v4, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0028 invoke-virtual v4, v11, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  002e invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0034 move-result-object v11
  0036 new-instance v2, Ljava/net/URI;
  003a invoke-direct v2, v11, Ljava/net/URI;-><init>(Ljava/lang/String;)V
  0040 const-string v11, "https"
  0044 invoke-virtual v2, Ljava/net/URI;->getScheme()Ljava/lang/String;
  004a move-result-object v4
  004c invoke-virtual v11, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0052 move-result v11
  0054 if-eqz v11, +09dh
  0058 const-string v11, "dokkan-eclipse.com"
  005c invoke-virtual v2, Ljava/net/URI;->getHost()Ljava/lang/String;
  0062 move-result-object v4
  0064 invoke-virtual v11, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  006a move-result v11
  006c if-eqz v11, +091h
  0070 invoke-virtual v2, Ljava/net/URI;->getPort()I
  0076 move-result v11
  0078 const/4 v4, -1
  007a if-ne v11, v4, +08ah
  007e invoke-virtual v2, Ljava/net/URI;->getUserInfo()Ljava/lang/String;
  0084 move-result-object v11
  0086 if-nez v11, +084h
  008a const-string v11, "/api/file-browser"
  008e invoke-virtual v2, Ljava/net/URI;->getPath()Ljava/lang/String;
  0094 move-result-object v5
  0096 invoke-virtual v11, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  009c move-result v11
  009e if-eqz v11, +078h
  00a2 invoke-virtual v2, Ljava/net/URI;->getRawQuery()Ljava/lang/String;
  00a8 move-result-object v11
  00aa if-eqz v11, +072h
  00ae invoke-virtual v2, Ljava/net/URI;->getRawQuery()Ljava/lang/String;
  00b4 move-result-object v11
  00b6 const-string v2, "&"
  00ba invoke-virtual v11, v2, v4, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  00c0 move-result-object v11
  00c2 array-length v2, v11
  00c4 const/4 v4, 0
  00c6 move-object v6, v3
  00c8 move v5, v4
  00ca if-ge v5, v2, +028h
  00ce aget-object v7, v11, v5
  00d2 const-string v8, "="
  00d6 const/4 v9, 2
  00d8 invoke-virtual v7, v8, v9, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  00de move-result-object v7
  00e0 aget-object v8, v7, v4
  00e4 invoke-static v8, v1, Ljava/net/URLDecoder;->decode(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  00ea move-result-object v8
  00ec const-string v10, "path"
  00f0 invoke-virtual v8, v10, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00f6 move-result v8
  00f8 if-eqz v8, +00eh
  00fc array-length v8, v7
  00fe if-ne v8, v9, +00bh
  0102 if-nez v6, +009h
  0106 const/4 v6, 1
  0108 aget-object v6, v7, v6
  010c invoke-static v6, v1, Ljava/net/URLDecoder;->decode(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0112 move-result-object v6
  0114 add-int/lit8 v5, v5, 1
  0118 goto -27h
  011a if-eqz v6, +03ah
  011e invoke-static v6, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  0124 move-result v11
  0126 if-eqz v11, +034h
  012a new-instance v11, Ljava/lang/StringBuilder;
  012e invoke-direct v11, Ljava/lang/StringBuilder;-><init>()V
  0134 invoke-static v6, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  013a move-result-object v1
  013c invoke-virtual v11, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0142 invoke-virtual v11, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0148 invoke-virtual v11, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  014e move-result-object v11
  0150 new-instance v1, Ljava/lang/StringBuilder;
  0154 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  015a const-string v2, "/assets/"
  015e invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0164 invoke-virtual v1, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  016a invoke-virtual v1, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0170 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0176 move-result-object v0
  0178 invoke-static v0, Lcom/personal/aihub/GameAssets;->gamePath(Ljava/lang/String;)Ljava/lang/String;
  017e move-result-object v0
  0180 invoke-virtual v11, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0186 move-result v11
  0188 if-eqz v11, +003h
  018c return-object v6
  018e return-object v3
.end method

.method visual(Ljava/lang/String;)Z
  0000 const-string v0, "(?i).*\.(png|lwf)$"
  0004 invoke-virtual v1, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  000a move-result v1
  000c return v1
.end method

.method resolve(Ljava/lang/String;)Lorg/json/JSONObject;
  0000 move-object/from16 v1, v21
  0004 invoke-static/range v22, Lcom/personal/aihub/GameDirectory;->route(Ljava/lang/String;)Ljava/lang/String;
  000a move-result-object v0
  000c const/4 v2, 0
  000e if-nez v0, +003h
  0012 return-object v2
  0014 new-instance v3, Ljava/util/LinkedHashMap;
  0018 invoke-direct v3, Ljava/util/LinkedHashMap;-><init>()V
  001e iget-object v4, v1, Lcom/personal/aihub/GameDirectory;->overlays Lorg/json/JSONArray;
  0022 invoke-static v4, Lcom/personal/aihub/GameAssets;->overlayMap(Lorg/json/JSONArray;)Ljava/util/Map;
  0028 move-result-object v4
  002a invoke-interface v4, Ljava/util/Map;->entrySet()Ljava/util/Set;
  0030 move-result-object v4
  0032 invoke-interface v4, Ljava/util/Set;->iterator()Ljava/util/Iterator;
  0038 move-result-object v4
  003a invoke-interface v4, Ljava/util/Iterator;->hasNext()Z
  0040 move-result v5
  0042 const/4 v6, 0
  0044 const/16 v7, 47
  0048 if-eqz v5, +032h
  004c invoke-interface v4, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0052 move-result-object v5
  0054 check-cast v5, Ljava/util/Map$Entry;
  0058 invoke-interface v5, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;
  005e move-result-object v8
  0060 check-cast v8, Ljava/lang/String;
  0064 invoke-virtual v8, v7, Ljava/lang/String;->lastIndexOf(I)I
  006a move-result v9
  006c if-lez v9, -019h
  0070 invoke-virtual v8, v7, Ljava/lang/String;->lastIndexOf(I)I
  0076 move-result v7
  0078 invoke-virtual v8, v6, v7, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  007e move-result-object v6
  0080 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0086 move-result v6
  0088 if-eqz v6, -027h
  008c invoke-static v8, Lcom/personal/aihub/GameDirectory;->visual(Ljava/lang/String;)Z
  0092 move-result v6
  0094 if-eqz v6, -02dh
  0098 invoke-interface v5, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;
  009e move-result-object v5
  00a0 check-cast v5, Ljava/lang/String;
  00a4 invoke-interface v3, v8, v5, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  00aa goto -38h
  00ac iget-object v4, v1, Lcom/personal/aihub/GameDirectory;->root Ljava/io/File;
  00b0 invoke-virtual v4, Ljava/io/File;->exists()Z
  00b6 move-result v4
  00b8 const-string v5, "/"
  00bc if-nez v4, +036h
  00c0 invoke-interface v3, Ljava/util/Map;->isEmpty()Z
  00c6 move-result v3
  00c8 if-eqz v3, +028h
  00cc iget-object v3, v1, Lcom/personal/aihub/GameDirectory;->preferred Ljava/lang/String;
  00d0 if-eqz v3, +023h
  00d4 invoke-virtual v3, Ljava/lang/String;->isEmpty()Z
  00da move-result v3
  00dc if-nez v3, +01dh
  00e0 iget-object v3, v1, Lcom/personal/aihub/GameDirectory;->preferred Ljava/lang/String;
  00e4 invoke-static v3, Lcom/personal/aihub/GameAssets;->preferredPath(Ljava/lang/String;)Ljava/lang/String;
  00ea move-result-object v3
  00ec new-instance v4, Ljava/lang/StringBuilder;
  00f0 invoke-direct v4, Ljava/lang/StringBuilder;-><init>()V
  00f6 invoke-virtual v4, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00fc invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0102 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0108 move-result-object v0
  010a invoke-virtual v3, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0110 move-result v0
  0112 if-nez v0, +003h
  0116 return-object v2
  0118 new-instance v0, Ljava/io/IOException;
  011c const-string v2, "The selected imported asset is unavailable. Choose it again."
  0120 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0126 throw v0
  0128 iget-object v4, v1, Lcom/personal/aihub/GameDirectory;->root Ljava/io/File;
  012c invoke-virtual v4, Ljava/io/File;->isDirectory()Z
  0132 move-result v4
  0134 if-eqz v4, +268h
  0138 iget-object v4, v1, Lcom/personal/aihub/GameDirectory;->root Ljava/io/File;
  013c invoke-virtual v4, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0142 move-result-object v4
  0144 invoke-static v4, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  014a move-result v4
  014c if-nez v4, +25ch
  0150 new-instance v4, Ljava/util/ArrayList;
  0154 invoke-direct v4, Ljava/util/ArrayList;-><init>()V
  015a iget-object v8, v1, Lcom/personal/aihub/GameDirectory;->root Ljava/io/File;
  015e invoke-virtual v8, Ljava/io/File;->listFiles()[Ljava/io/File;
  0164 move-result-object v8
  0166 if-eqz v8, +039h
  016a array-length v9, v8
  016c move v10, v6
  016e if-ge v10, v9, +035h
  0172 aget-object v11, v8, v10
  0176 invoke-virtual v11, Ljava/io/File;->getName()Ljava/lang/String;
  017c move-result-object v12
  017e invoke-static v12, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  0184 move-result v12
  0186 if-eqz v12, +026h
  018a invoke-virtual v11, Ljava/io/File;->isDirectory()Z
  0190 move-result v12
  0192 if-eqz v12, +020h
  0196 invoke-virtual v11, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  019c move-result-object v12
  019e invoke-static v12, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  01a4 move-result v12
  01a6 if-nez v12, +016h
  01aa invoke-virtual v4, v11, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  01b0 invoke-virtual v4, Ljava/util/ArrayList;->size()I
  01b6 move-result v11
  01b8 const/16 v12, 4096
  01bc if-gt v11, v12, +003h
  01c0 goto +9h
  01c2 new-instance v0, Ljava/io/IOException;
  01c6 const-string v2, "Too many imported resource groups for a visual preview"
  01ca invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01d0 throw v0
  01d2 add-int/lit8 v10, v10, 1
  01d6 goto -34h
  01d8 new-instance v8, Lcom/personal/aihub/GameDirectory$$ExternalSyntheticLambda0;
  01dc invoke-direct v8, Lcom/personal/aihub/GameDirectory$$ExternalSyntheticLambda0;-><init>()V
  01e2 invoke-virtual v4, v8, Ljava/util/ArrayList;->sort(Ljava/util/Comparator;)V
  01e8 new-instance v8, Ljava/util/TreeMap;
  01ec invoke-direct v8, Ljava/util/TreeMap;-><init>()V
  01f2 invoke-virtual v4, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
  01f8 move-result-object v4
  01fa move v9, v6
  01fc invoke-interface v4, Ljava/util/Iterator;->hasNext()Z
  0202 move-result v10
  0204 const-string v11, "/assets/"
  0208 if-eqz v10, +11ch
  020c invoke-interface v4, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0212 move-result-object v10
  0214 check-cast v10, Ljava/io/File;
  0218 invoke-virtual v10, Ljava/io/File;->getName()Ljava/lang/String;
  021e move-result-object v12
  0220 new-instance v13, Ljava/lang/StringBuilder;
  0224 invoke-direct v13, Ljava/lang/StringBuilder;-><init>()V
  022a invoke-virtual v10, Ljava/io/File;->getName()Ljava/lang/String;
  0230 move-result-object v14
  0232 invoke-virtual v13, v14, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0238 const-string v14, "/files"
  023c invoke-virtual v13, v14, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0242 invoke-virtual v13, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0248 move-result-object v13
  024a new-instance v14, Ljava/lang/StringBuilder;
  024e invoke-direct v14, Ljava/lang/StringBuilder;-><init>()V
  0254 invoke-virtual v10, Ljava/io/File;->getName()Ljava/lang/String;
  025a move-result-object v10
  025c invoke-virtual v14, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0262 const-string v10, "/tutorial0"
  0266 invoke-virtual v14, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  026c invoke-virtual v14, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0272 move-result-object v10
  0274 filled-new-array v12, v13, v10, [Ljava/lang/String;
  027a move-result-object v10
  027c move v12, v6
  027e const/4 v13, 3
  0280 if-ge v12, v13, -042h
  0284 aget-object v13, v10, v12
  0288 new-instance v14, Ljava/lang/StringBuilder;
  028c invoke-direct v14, Ljava/lang/StringBuilder;-><init>()V
  0292 invoke-virtual v14, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0298 invoke-virtual v14, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  029e invoke-virtual v14, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02a4 invoke-virtual v14, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  02aa move-result-object v13
  02ac invoke-direct v1, v13, Lcom/personal/aihub/GameDirectory;->directory(Ljava/lang/String;)Ljava/io/File;
  02b2 move-result-object v13
  02b4 if-nez v13, +004h
  02b8 goto/16 +0aeh
  02bc invoke-virtual v13, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  02c2 move-result-object v13
  02c4 invoke-static v13, Ljava/nio/file/Files;->newDirectoryStream(Ljava/nio/file/Path;)Ljava/nio/file/DirectoryStream;
  02ca move-result-object v13
  02cc invoke-interface v13, Ljava/nio/file/DirectoryStream;->iterator()Ljava/util/Iterator;
  02d2 move-result-object v14
  02d4 invoke-interface v14, Ljava/util/Iterator;->hasNext()Z
  02da move-result v15
  02dc if-eqz v15, +097h
  02e0 invoke-interface v14, Ljava/util/Iterator;->next()Ljava/lang/Object;
  02e6 move-result-object v15
  02e8 check-cast v15, Ljava/nio/file/Path;
  02ec add-int/lit8 v9, v9, 1
  02f0 const/16 v2, 10000
  02f4 if-gt v9, v2, +083h
  02f8 invoke-interface v15, Ljava/nio/file/Path;->getFileName()Ljava/nio/file/Path;
  02fe move-result-object v2
  0300 invoke-interface v2, Ljava/nio/file/Path;->toString()Ljava/lang/String;
  0306 move-result-object v2
  0308 invoke-static v2, Lcom/personal/aihub/GameDirectory;->visual(Ljava/lang/String;)Z
  030e move-result v16
  0310 if-eqz v16, +06fh
  0314 new-instance v6, Ljava/lang/StringBuilder;
  0318 invoke-direct v6, Ljava/lang/StringBuilder;-><init>()V
  031e invoke-virtual v6, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0324 invoke-virtual v6, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  032a invoke-virtual v6, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0330 invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0336 move-result-object v6
  0338 new-instance v7, Ljava/lang/StringBuilder;
  033c invoke-direct v7, Ljava/lang/StringBuilder;-><init>()V
  0342 invoke-virtual v7, v11, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0348 invoke-virtual v7, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  034e invoke-virtual v7, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0354 invoke-virtual v7, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  035a invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0360 move-result-object v7
  0362 invoke-static v7, Lcom/personal/aihub/GameAssets;->gamePath(Ljava/lang/String;)Ljava/lang/String;
  0368 move-result-object v7
  036a invoke-virtual v6, v7, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0370 move-result v6
  0372 if-eqz v6, +03eh
  0376 invoke-static v15, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  037c move-result v6
  037e if-nez v6, +030h
  0382 invoke-interface v15, Ljava/nio/file/Path;->toFile()Ljava/io/File;
  0388 move-result-object v6
  038a invoke-virtual v6, Ljava/io/File;->isFile()Z
  0390 move-result v7
  0392 if-eqz v7, +02eh
  0396 invoke-virtual v8, v2, Ljava/util/TreeMap;->containsKey(Ljava/lang/Object;)Z
  039c move-result v7
  039e if-nez v7, +028h
  03a2 invoke-virtual v6, Ljava/io/File;->length()J
  03a8 move-result-wide v17
  03aa const-wide/32 v19, 167772160
  03b0 cmp-long v7, v17, v19
  03b4 if-gtz v7, +00dh
  03b8 invoke-static v0, v2, v6, Lcom/personal/aihub/GameDirectory;->item(Ljava/lang/String; Ljava/lang/String; Ljava/io/File;)Lorg/json/JSONObject;
  03be move-result-object v6
  03c0 invoke-virtual v8, v2, v6, Ljava/util/TreeMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  03c6 invoke-static v8, Lcom/personal/aihub/GameDirectory;->bound(Ljava/util/Map;)V
  03cc goto +11h
  03ce new-instance v0, Ljava/io/IOException;
  03d2 const-string v2, "Imported game asset exceeds the 160 MB preview limit"
  03d6 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03dc throw v0
  03de new-instance v0, Ljava/io/IOException;
  03e2 const-string v2, "Imported game assets cannot use symbolic links"
  03e6 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03ec throw v0
  03ee const/4 v2, 0
  03f0 const/4 v6, 0
  03f2 const/16 v7, 47
  03f6 goto/16 -091h
  03fa new-instance v0, Ljava/io/IOException;
  03fe const-string v2, "This visual folder exceeds the preview listing limit"
  0402 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0408 throw v0
  040a if-eqz v13, +005h
  040e invoke-interface v13, Ljava/nio/file/DirectoryStream;->close()V
  0414 add-int/lit8 v12, v12, 1
  0418 const/4 v2, 0
  041a const/4 v6, 0
  041c const/16 v7, 47
  0420 goto/16 -0d1h
  0424 move-exception v0
  0426 move-object v2, v0
  0428 if-eqz v13, +00bh
  042c invoke-interface v13, Ljava/nio/file/DirectoryStream;->close()V
  0432 goto +6h
  0434 move-exception v0
  0436 move-object v3, v0
  0438 invoke-virtual v2, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  043e throw v2
  0440 iget-object v2, v1, Lcom/personal/aihub/GameDirectory;->preferred Ljava/lang/String;
  0444 const/4 v4, 1
  0446 if-eqz v2, +04ch
  044a invoke-virtual v2, Ljava/lang/String;->isEmpty()Z
  0450 move-result v2
  0452 if-nez v2, +046h
  0456 iget-object v2, v1, Lcom/personal/aihub/GameDirectory;->preferred Ljava/lang/String;
  045a invoke-static v2, Lcom/personal/aihub/GameAssets;->preferredPath(Ljava/lang/String;)Ljava/lang/String;
  0460 move-result-object v2
  0462 const/16 v6, 47
  0466 invoke-virtual v2, v6, Ljava/lang/String;->lastIndexOf(I)I
  046c move-result v7
  046e const/4 v6, 0
  0470 invoke-virtual v2, v6, v7, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  0476 move-result-object v7
  0478 invoke-virtual v7, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  047e move-result v6
  0480 if-eqz v6, +02fh
  0484 invoke-static v2, Lcom/personal/aihub/GameDirectory;->visual(Ljava/lang/String;)Z
  048a move-result v6
  048c if-eqz v6, +029h
  0490 iget-object v6, v1, Lcom/personal/aihub/GameDirectory;->assets Lcom/personal/aihub/GameAssets;
  0494 new-instance v7, Ljava/lang/StringBuilder;
  0498 invoke-direct v7, v11, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  049e invoke-virtual v7, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  04a4 invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  04aa move-result-object v7
  04ac invoke-virtual v6, v7, Lcom/personal/aihub/GameAssets;->resolve(Ljava/lang/String;)Ljava/io/File;
  04b2 move-result-object v6
  04b4 const/16 v7, 47
  04b8 invoke-virtual v2, v7, Ljava/lang/String;->lastIndexOf(I)I
  04be move-result v9
  04c0 add-int/2addr v9, v4
  04c2 invoke-virtual v2, v9, Ljava/lang/String;->substring(I)Ljava/lang/String;
  04c8 move-result-object v2
  04ca invoke-static v0, v2, v6, Lcom/personal/aihub/GameDirectory;->item(Ljava/lang/String; Ljava/lang/String; Ljava/io/File;)Lorg/json/JSONObject;
  04d0 move-result-object v6
  04d2 invoke-virtual v8, v2, v6, Ljava/util/TreeMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  04d8 invoke-static v8, Lcom/personal/aihub/GameDirectory;->bound(Ljava/util/Map;)V
  04de invoke-interface v3, Ljava/util/Map;->keySet()Ljava/util/Set;
  04e4 move-result-object v2
  04e6 invoke-interface v2, Ljava/util/Set;->iterator()Ljava/util/Iterator;
  04ec move-result-object v2
  04ee invoke-interface v2, Ljava/util/Iterator;->hasNext()Z
  04f4 move-result v3
  04f6 if-eqz v3, +030h
  04fa invoke-interface v2, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0500 move-result-object v3
  0502 check-cast v3, Ljava/lang/String;
  0506 iget-object v6, v1, Lcom/personal/aihub/GameDirectory;->assets Lcom/personal/aihub/GameAssets;
  050a new-instance v7, Ljava/lang/StringBuilder;
  050e invoke-direct v7, v11, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0514 invoke-virtual v7, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  051a invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0520 move-result-object v7
  0522 invoke-virtual v6, v7, Lcom/personal/aihub/GameAssets;->resolve(Ljava/lang/String;)Ljava/io/File;
  0528 move-result-object v6
  052a const/16 v7, 47
  052e invoke-virtual v3, v7, Ljava/lang/String;->lastIndexOf(I)I
  0534 move-result v9
  0536 add-int/2addr v9, v4
  0538 invoke-virtual v3, v9, Ljava/lang/String;->substring(I)Ljava/lang/String;
  053e move-result-object v3
  0540 invoke-static v0, v3, v6, Lcom/personal/aihub/GameDirectory;->item(Ljava/lang/String; Ljava/lang/String; Ljava/io/File;)Lorg/json/JSONObject;
  0546 move-result-object v6
  0548 invoke-virtual v8, v3, v6, Ljava/util/TreeMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  054e invoke-static v8, Lcom/personal/aihub/GameDirectory;->bound(Ljava/util/Map;)V
  0554 goto -33h
  0556 invoke-virtual v8, Ljava/util/TreeMap;->isEmpty()Z
  055c move-result v2
  055e if-eqz v2, +004h
  0562 const/4 v2, 0
  0564 return-object v2
  0566 new-instance v2, Lorg/json/JSONArray;
  056a invoke-direct v2, Lorg/json/JSONArray;-><init>()V
  0570 invoke-virtual v8, Ljava/util/TreeMap;->values()Ljava/util/Collection;
  0576 move-result-object v3
  0578 invoke-interface v3, Ljava/util/Collection;->iterator()Ljava/util/Iterator;
  057e move-result-object v3
  0580 invoke-interface v3, Ljava/util/Iterator;->hasNext()Z
  0586 move-result v6
  0588 if-eqz v6, +00ch
  058c invoke-interface v3, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0592 move-result-object v6
  0594 check-cast v6, Lorg/json/JSONObject;
  0598 invoke-virtual v2, v6, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  059e goto -fh
  05a0 new-instance v3, Lorg/json/JSONObject;
  05a4 invoke-direct v3, Lorg/json/JSONObject;-><init>()V
  05aa const-string v6, "path"
  05ae invoke-virtual v3, v6, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  05b4 move-result-object v3
  05b6 invoke-virtual v0, v5, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  05bc move-result v5
  05be if-eqz v5, +00eh
  05c2 const/16 v5, 47
  05c6 invoke-virtual v0, v5, Ljava/lang/String;->lastIndexOf(I)I
  05cc move-result v5
  05ce const/4 v6, 0
  05d0 invoke-virtual v0, v6, v5, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  05d6 move-result-object v0
  05d8 goto +3h
  05da const-string v0, ""
  05de const-string v5, "parentPath"
  05e2 invoke-virtual v3, v5, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  05e8 move-result-object v0
  05ea const-string v3, "items"
  05ee invoke-virtual v0, v3, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  05f4 move-result-object v0
  05f6 const-string v2, "forge_local"
  05fa invoke-virtual v0, v2, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0600 move-result-object v0
  0602 return-object v0
  0604 new-instance v0, Ljava/io/IOException;
  0608 const-string v2, "Invalid imported resource folder"
  060c invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0612 throw v0
.end method