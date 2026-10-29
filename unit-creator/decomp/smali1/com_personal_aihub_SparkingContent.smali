.class Lcom/personal/aihub/SparkingContent;
.super Ljava/lang/Object;
.field DATABASE_PATH Ljava/lang/String;
.field MANIFEST Ljava/lang/String;
.field MAX_DATABASE J
.field MAX_MANIFEST J

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method allowed(Ljava/lang/String; Z)Ljava/net/URI;
  0000 new-instance v0, Ljava/net/URI;
  0004 invoke-direct v0, v4, Ljava/net/URI;-><init>(Ljava/lang/String;)V
  000a if-eqz v5, +005h
  000e const-string v4, "dokkan-sparking.com"
  0012 goto +3h
  0014 const-string v4, "ddl.dokkan-sparking.com"
  0018 if-eqz v5, +005h
  001c const-string v1, "/client_assets"
  0020 goto +3h
  0022 const-string v1, "/dokkan/assets/global/en/sqlite/current/en/database.db"
  0026 const-string v2, "https"
  002a invoke-virtual v0, Ljava/net/URI;->getScheme()Ljava/lang/String;
  0030 move-result-object v3
  0032 invoke-virtual v2, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0038 move-result v2
  003a if-eqz v2, +03ah
  003e invoke-virtual v0, Ljava/net/URI;->getHost()Ljava/lang/String;
  0044 move-result-object v2
  0046 invoke-virtual v4, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  004c move-result v4
  004e if-eqz v4, +030h
  0052 invoke-virtual v0, Ljava/net/URI;->getRawPath()Ljava/lang/String;
  0058 move-result-object v4
  005a invoke-virtual v1, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0060 move-result v4
  0062 if-eqz v4, +026h
  0066 invoke-virtual v0, Ljava/net/URI;->getRawUserInfo()Ljava/lang/String;
  006c move-result-object v4
  006e if-nez v4, +020h
  0072 invoke-virtual v0, Ljava/net/URI;->getRawFragment()Ljava/lang/String;
  0078 move-result-object v4
  007a if-nez v4, +01ah
  007e invoke-virtual v0, Ljava/net/URI;->getPort()I
  0084 move-result v4
  0086 const/4 v1, -1
  0088 if-eq v4, v1, +00ah
  008c invoke-virtual v0, Ljava/net/URI;->getPort()I
  0092 move-result v4
  0094 const/16 v1, 443
  0098 if-ne v4, v1, +00bh
  009c if-eqz v5, +008h
  00a0 invoke-virtual v0, Ljava/net/URI;->getRawQuery()Ljava/lang/String;
  00a6 move-result-object v4
  00a8 if-nez v4, +003h
  00ac return-object v0
  00ae new-instance v4, Ljava/io/IOException;
  00b2 const-string v5, "The Sparking server returned an unsupported download address."
  00b6 invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00bc throw v4
.end method

.method assetRecord(Lorg/json/JSONObject; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 invoke-static v8, Lcom/personal/aihub/SparkingContent;->gamePath(Ljava/lang/String;)V
  0006 const-string v0, "assets"
  000a invoke-virtual v7, v0, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0010 move-result-object v7
  0012 invoke-virtual v7, Lorg/json/JSONArray;->length()I
  0018 move-result v0
  001a const v1, 100000
  0020 if-gt v0, v1, +0f6h
  0024 const/4 v0, 0
  0026 const/4 v1, 0
  0028 move-object v2, v0
  002a invoke-virtual v7, Lorg/json/JSONArray;->length()I
  0030 move-result v3
  0032 if-ge v1, v3, +021h
  0036 invoke-virtual v7, v1, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  003c move-result-object v3
  003e const-string v4, "file_path"
  0042 invoke-virtual v3, v4, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0048 move-result-object v4
  004a invoke-virtual v8, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0050 move-result v4
  0052 if-eqz v4, +00eh
  0056 if-nez v2, +004h
  005a move-object v2, v3
  005c goto +9h
  005e new-instance v7, Ljava/io/IOException;
  0062 const-string v8, "The Sparking manifest repeats this game resource."
  0066 invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  006c throw v7
  006e add-int/lit8 v1, v1, 1
  0072 goto -24h
  0074 if-eqz v2, +0c4h
  0078 const-string v7, "size"
  007c invoke-virtual v2, v7, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  0082 move-result-object v7
  0084 instance-of v1, v7, Ljava/lang/Integer;
  0088 if-nez v1, +006h
  008c instance-of v1, v7, Ljava/lang/Long;
  0090 if-eqz v1, +0aeh
  0094 check-cast v7, Ljava/lang/Number;
  0098 invoke-virtual v7, Ljava/lang/Number;->longValue()J
  009e move-result-wide v3
  00a0 const-wide/16 v5, 0
  00a4 cmp-long v1, v3, v5
  00a8 if-lez v1, +0a2h
  00ac invoke-virtual v7, Ljava/lang/Number;->longValue()J
  00b2 move-result-wide v3
  00b4 const-wide/32 v5, 201326592
  00ba cmp-long v7, v3, v5
  00be if-gtz v7, +097h
  00c2 const-string v7, "algorithm"
  00c6 invoke-virtual v2, v7, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  00cc move-result-object v7
  00ce const-string v1, "xxhash"
  00d2 invoke-virtual v1, v7, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00d8 move-result v7
  00da if-eqz v7, +089h
  00de const-string v7, "hash"
  00e2 invoke-virtual v2, v7, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  00e8 move-result-object v7
  00ea const-string v1, "[0-9]{1,20}"
  00ee invoke-virtual v7, v1, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  00f4 move-result v1
  00f6 const-string v3, "Invalid Sparking resource checksum."
  00fa if-eqz v1, +073h
  00fe invoke-static v7, Ljava/lang/Long;->parseUnsignedLong(Ljava/lang/String;)J
  0104 new-instance v7, Ljava/net/URI;
  0108 const-string v1, "url"
  010c invoke-virtual v2, v1, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0112 move-result-object v1
  0114 invoke-direct v7, v1, Ljava/net/URI;-><init>(Ljava/lang/String;)V
  011a new-instance v1, Ljava/net/URI;
  011e new-instance v3, Ljava/lang/StringBuilder;
  0122 const-string v4, "/dokkan/assets/global/en/"
  0126 invoke-direct v3, v4, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  012c invoke-virtual v3, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0132 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0138 move-result-object v8
  013a invoke-direct v1, v0, v0, v8, v0, Ljava/net/URI;-><init>(Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)V
  0140 invoke-virtual v1, Ljava/net/URI;->toASCIIString()Ljava/lang/String;
  0146 move-result-object v8
  0148 const-string v0, "https"
  014c invoke-virtual v7, Ljava/net/URI;->getScheme()Ljava/lang/String;
  0152 move-result-object v1
  0154 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  015a move-result v0
  015c if-eqz v0, +034h
  0160 const-string v0, "ddl.dokkan-sparking.com"
  0164 invoke-virtual v7, Ljava/net/URI;->getHost()Ljava/lang/String;
  016a move-result-object v1
  016c invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0172 move-result v0
  0174 if-eqz v0, +028h
  0178 invoke-virtual v7, Ljava/net/URI;->getRawPath()Ljava/lang/String;
  017e move-result-object v0
  0180 invoke-virtual v8, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0186 move-result v8
  0188 if-eqz v8, +01eh
  018c invoke-virtual v7, Ljava/net/URI;->getRawUserInfo()Ljava/lang/String;
  0192 move-result-object v8
  0194 if-nez v8, +018h
  0198 invoke-virtual v7, Ljava/net/URI;->getRawFragment()Ljava/lang/String;
  019e move-result-object v8
  01a0 if-nez v8, +012h
  01a4 invoke-virtual v7, Ljava/net/URI;->getPort()I
  01aa move-result v8
  01ac const/4 v0, -1
  01ae if-eq v8, v0, +00ah
  01b2 invoke-virtual v7, Ljava/net/URI;->getPort()I
  01b8 move-result v7
  01ba const/16 v8, 443
  01be if-ne v7, v8, +003h
  01c2 return-object v2
  01c4 new-instance v7, Ljava/io/IOException;
  01c8 const-string v8, "The Sparking resource download address does not match its manifest path."
  01cc invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01d2 throw v7
  01d4 new-instance v7, Ljava/io/IOException;
  01d8 invoke-direct v7, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01de throw v7
  01e0 new-instance v7, Ljava/io/IOException;
  01e4 invoke-direct v7, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01ea throw v7
  01ec new-instance v7, Ljava/io/IOException;
  01f0 const-string v8, "Unsupported Sparking game resource size or checksum."
  01f4 invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01fa throw v7
  01fc new-instance v7, Ljava/io/IOException;
  0200 const-string v8, "This resource is not listed in the downloaded Sparking manifest."
  0204 invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  020a throw v7
  020c new-instance v7, Ljava/io/IOException;
  0210 const-string v8, "The Sparking manifest contains too many entries."
  0214 invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  021a throw v7
.end method

.method audioRecords(Lorg/json/JSONObject;)Lorg/json/JSONArray;
  0000 const-string v0, "assets"
  0004 invoke-virtual v9, v0, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  000a move-result-object v0
  000c new-instance v1, Lorg/json/JSONArray;
  0010 invoke-direct v1, Lorg/json/JSONArray;-><init>()V
  0016 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  001c move-result v2
  001e const v3, 100000
  0024 if-gt v2, v3, +067h
  0028 const/4 v2, 0
  002a invoke-virtual v0, Lorg/json/JSONArray;->length()I
  0030 move-result v3
  0032 if-ge v2, v3, +05fh
  0036 invoke-virtual v0, v2, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  003c move-result-object v3
  003e const-string v4, "file_path"
  0042 invoke-virtual v3, v4, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0048 move-result-object v3
  004a const-string v4, "se/"
  004e invoke-virtual v3, v4, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0054 move-result v5
  0056 if-nez v5, +00bh
  005a const-string v5, "voice/"
  005e invoke-virtual v3, v5, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0064 move-result v5
  0066 if-nez v5, +003h
  006a goto +38h
  006c invoke-virtual v1, Lorg/json/JSONArray;->length()I
  0072 move-result v5
  0074 const/16 v6, 128
  0078 if-ge v5, v6, +034h
  007c invoke-static v9, v3, Lcom/personal/aihub/SparkingContent;->assetRecord(Lorg/json/JSONObject; Ljava/lang/String;)Lorg/json/JSONObject;
  0082 move-result-object v5
  0084 new-instance v6, Lorg/json/JSONObject;
  0088 invoke-direct v6, Lorg/json/JSONObject;-><init>()V
  008e const-string v7, "path"
  0092 invoke-virtual v6, v7, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0098 move-result-object v6
  009a const-string v7, "size"
  009e invoke-virtual v5, v7, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  00a4 move-result-wide v7
  00a6 const-string v5, "bytes"
  00aa invoke-virtual v6, v5, v7, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  00b0 move-result-object v5
  00b2 invoke-virtual v3, v4, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00b8 move-result v3
  00ba if-eqz v3, +005h
  00be const-string v3, "se"
  00c2 goto +3h
  00c4 const-string v3, "voice"
  00c8 const-string v4, "kind"
  00cc invoke-virtual v5, v4, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00d2 move-result-object v3
  00d4 invoke-virtual v1, v3, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  00da add-int/lit8 v2, v2, 1
  00de goto -5ah
  00e0 new-instance v9, Ljava/io/IOException;
  00e4 const-string v0, "The Sparking manifest contains too many audio banks."
  00e8 invoke-direct v9, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00ee throw v9
  00f0 return-object v1
  00f2 new-instance v9, Ljava/io/IOException;
  00f6 const-string v0, "The Sparking manifest contains too many entries."
  00fa invoke-direct v9, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0100 throw v9
.end method

.method connect(Ljava/lang/String; Z)Ljavax/net/ssl/HttpsURLConnection;
  0000 invoke-static v0, v1, Lcom/personal/aihub/SparkingContent;->allowed(Ljava/lang/String; Z)Ljava/net/URI;
  0006 move-result-object v0
  0008 invoke-static v0, v1, Lcom/personal/aihub/SparkingContent;->open(Ljava/net/URI; Z)Ljavax/net/ssl/HttpsURLConnection;
  000e move-result-object v0
  0010 return-object v0
.end method

.method databaseRecord(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 const-string v0, "assets"
  0004 invoke-virtual v6, v0, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  000a move-result-object v6
  000c invoke-virtual v6, Lorg/json/JSONArray;->length()I
  0012 move-result v0
  0014 const v1, 100000
  001a if-gt v0, v1, +0a2h
  001e const/4 v0, 0
  0020 const/4 v1, 0
  0022 move v2, v0
  0024 invoke-virtual v6, Lorg/json/JSONArray;->length()I
  002a move-result v3
  002c if-ge v2, v3, +023h
  0030 invoke-virtual v6, v2, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  0036 move-result-object v3
  0038 const-string v4, "file_path"
  003c invoke-virtual v3, v4, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0042 move-result-object v4
  0044 const-string v5, "sqlite/current/en/database.db"
  0048 invoke-virtual v5, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  004e move-result v4
  0050 if-eqz v4, +00eh
  0054 if-nez v1, +004h
  0058 move-object v1, v3
  005a goto +9h
  005c new-instance v6, Ljava/io/IOException;
  0060 const-string v0, "The Sparking manifest has duplicate game databases."
  0064 invoke-direct v6, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  006a throw v6
  006c add-int/lit8 v2, v2, 1
  0070 goto -26h
  0072 if-eqz v1, +06eh
  0076 const-string v6, "size"
  007a invoke-virtual v1, v6, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  0080 move-result-object v6
  0082 instance-of v2, v6, Ljava/lang/Number;
  0086 if-eqz v2, +05ch
  008a instance-of v2, v6, Ljava/lang/Double;
  008e if-nez v2, +058h
  0092 instance-of v2, v6, Ljava/lang/Float;
  0096 if-nez v2, +054h
  009a check-cast v6, Ljava/lang/Number;
  009e invoke-virtual v6, Ljava/lang/Number;->longValue()J
  00a4 move-result-wide v2
  00a6 const-wide/16 v4, 0
  00aa cmp-long v6, v2, v4
  00ae if-lez v6, +040h
  00b2 const-wide/32 v4, 201326592
  00b8 cmp-long v6, v2, v4
  00bc if-gtz v6, +039h
  00c0 const-string v6, "algorithm"
  00c4 invoke-virtual v1, v6, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  00ca move-result-object v6
  00cc const-string v2, "xxhash"
  00d0 invoke-virtual v2, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00d6 move-result v6
  00d8 if-eqz v6, +02bh
  00dc const-string v6, "hash"
  00e0 invoke-virtual v1, v6, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  00e6 move-result-object v6
  00e8 const-string v2, "[0-9]{1,20}"
  00ec invoke-virtual v6, v2, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  00f2 move-result v2
  00f4 const-string v3, "Invalid Sparking database checksum."
  00f8 if-eqz v2, +015h
  00fc invoke-static v6, Ljava/lang/Long;->parseUnsignedLong(Ljava/lang/String;)J
  0102 const-string v6, "url"
  0106 invoke-virtual v1, v6, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  010c move-result-object v6
  010e invoke-static v6, v0, Lcom/personal/aihub/SparkingContent;->allowed(Ljava/lang/String; Z)Ljava/net/URI;
  0114 return-object v1
  0116 new-instance v6, Ljava/io/IOException;
  011a invoke-direct v6, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0120 throw v6
  0122 new-instance v6, Ljava/io/IOException;
  0126 invoke-direct v6, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  012c throw v6
  012e new-instance v6, Ljava/io/IOException;
  0132 const-string v0, "Unsupported Sparking database size or checksum format."
  0136 invoke-direct v6, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  013c throw v6
  013e new-instance v6, Ljava/io/IOException;
  0142 const-string v0, "Invalid Sparking database size."
  0146 invoke-direct v6, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  014c throw v6
  014e new-instance v6, Ljava/io/IOException;
  0152 const-string v0, "The Sparking manifest does not list its game database."
  0156 invoke-direct v6, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  015c throw v6
  015e new-instance v6, Ljava/io/IOException;
  0162 const-string v0, "The Sparking manifest contains too many entries."
  0166 invoke-direct v6, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  016c throw v6
.end method

.method destination(Ljava/io/File;)Ljava/io/File;
  0000 invoke-virtual v2, Ljava/io/File;->getAbsoluteFile()Ljava/io/File;
  0006 move-result-object v2
  0008 invoke-virtual v2, Ljava/io/File;->getParentFile()Ljava/io/File;
  000e move-result-object v0
  0010 invoke-virtual v0, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  0016 move-result-object v0
  0018 invoke-virtual v0, Ljava/io/File;->isDirectory()Z
  001e move-result v1
  0020 if-eqz v1, +02bh
  0024 new-instance v1, Ljava/io/File;
  0028 invoke-virtual v2, Ljava/io/File;->getName()Ljava/lang/String;
  002e move-result-object v2
  0030 invoke-direct v1, v0, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0036 invoke-virtual v1, Ljava/io/File;->exists()Z
  003c move-result v2
  003e if-eqz v2, +01bh
  0042 invoke-virtual v1, Ljava/io/File;->isFile()Z
  0048 move-result v2
  004a if-eqz v2, +00dh
  004e invoke-virtual v1, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  0054 move-result-object v2
  0056 invoke-virtual v2, v1, Ljava/io/File;->equals(Ljava/lang/Object;)Z
  005c move-result v2
  005e if-eqz v2, +003h
  0062 goto +9h
  0064 new-instance v2, Ljava/io/IOException;
  0068 const-string v0, "Unsafe Sparking download destination."
  006c invoke-direct v2, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0072 throw v2
  0074 return-object v1
  0076 new-instance v2, Ljava/io/IOException;
  007a const-string v0, "Create a private Sparking download staging directory first."
  007e invoke-direct v2, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0084 throw v2
.end method

.method download(Ljava/io/File; Ljava/io/File; Lcom/personal/aihub/SparkingContent$Progress;)Lorg/json/JSONObject;
  0000 invoke-static/range v27, Lcom/personal/aihub/SparkingContent;->destination(Ljava/io/File;)Ljava/io/File;
  0006 move-result-object v1
  0008 invoke-static/range v28, Lcom/personal/aihub/SparkingContent;->destination(Ljava/io/File;)Ljava/io/File;
  000e move-result-object v2
  0010 invoke-virtual v1, v2, Ljava/io/File;->equals(Ljava/lang/Object;)Z
  0016 move-result v0
  0018 if-nez v0, +424h
  001c invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0022 move-result-object v0
  0024 invoke-virtual v0, Ljava/util/UUID;->toString()Ljava/lang/String;
  002a move-result-object v0
  002c new-instance v3, Ljava/io/File;
  0030 invoke-virtual v1, Ljava/io/File;->getParentFile()Ljava/io/File;
  0036 move-result-object v4
  0038 new-instance v5, Ljava/lang/StringBuilder;
  003c const-string v6, "sparking-"
  0040 invoke-direct v5, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0046 invoke-virtual v5, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  004c const-string v7, ".database.tmp"
  0050 invoke-virtual v5, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0056 invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  005c move-result-object v5
  005e invoke-direct v3, v4, v5, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0064 new-instance v4, Ljava/io/File;
  0068 invoke-virtual v2, Ljava/io/File;->getParentFile()Ljava/io/File;
  006e move-result-object v5
  0070 new-instance v7, Ljava/lang/StringBuilder;
  0074 invoke-direct v7, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  007a invoke-virtual v7, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0080 const-string v8, ".manifest.tmp"
  0084 invoke-virtual v7, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  008a invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0090 move-result-object v7
  0092 invoke-direct v4, v5, v7, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0098 new-instance v5, Ljava/io/File;
  009c invoke-virtual v1, Ljava/io/File;->getParentFile()Ljava/io/File;
  00a2 move-result-object v7
  00a4 new-instance v8, Ljava/lang/StringBuilder;
  00a8 invoke-direct v8, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00ae invoke-virtual v8, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00b4 const-string v9, ".database.old"
  00b8 invoke-virtual v8, v9, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00be invoke-virtual v8, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00c4 move-result-object v8
  00c6 invoke-direct v5, v7, v8, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00cc new-instance v7, Ljava/io/File;
  00d0 invoke-virtual v2, Ljava/io/File;->getParentFile()Ljava/io/File;
  00d6 move-result-object v8
  00d8 new-instance v9, Ljava/lang/StringBuilder;
  00dc invoke-direct v9, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00e2 invoke-virtual v9, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00e8 const-string v0, ".manifest.old"
  00ec invoke-virtual v9, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00f2 invoke-virtual v9, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00f8 move-result-object v0
  00fa invoke-direct v7, v8, v0, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0100 const-string v0, "https://dokkan-sparking.com/client_assets"
  0104 const/4 v8, 1
  0106 invoke-static v0, v8, Lcom/personal/aihub/SparkingContent;->connect(Ljava/lang/String; Z)Ljavax/net/ssl/HttpsURLConnection;
  010c move-result-object v9
  010e invoke-virtual v9, Ljavax/net/ssl/HttpsURLConnection;->getContentLengthLong()J
  0114 move-result-wide v16
  0116 const-wide/32 v18, 33554432
  011c cmp-long v0, v16, v18
  0120 const-string v14, "The Sparking manifest exceeds32MiB."
  0124 if-gtz v0, +31eh
  0128 new-instance v0, Ljava/io/ByteArrayOutputStream;
  012c invoke-direct v0, Ljava/io/ByteArrayOutputStream;-><init>()V
  0132 new-instance v15, Ljava/io/BufferedInputStream;
  0136 invoke-virtual v9, Ljavax/net/ssl/HttpsURLConnection;->getInputStream()Ljava/io/InputStream;
  013c move-result-object v10
  013e invoke-direct v15, v10, Ljava/io/BufferedInputStream;-><init>(Ljava/io/InputStream;)V
  0144 const/high16 v10, 65536
  0148 new-array v12, v10, [B
  014c invoke-virtual v15, v12, Ljava/io/InputStream;->read([B)I
  0152 move-result v10
  0154 const/4 v11, -1
  0156 if-eq v10, v11, +048h
  015a invoke-virtual v0, Ljava/io/ByteArrayOutputStream;->size()I
  0160 move-result v11
  0162 move-object/from16 v28, v9
  0166 int-to-long v8, v11
  0168 move-object/from16 v20, v7
  016c int-to-long v6, v10
  016e add-long/2addr v8, v6
  0170 cmp-long v6, v8, v18
  0174 if-gtz v6, +023h
  0178 const/4 v6, 0
  017a invoke-virtual v0, v12, v6, v10, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  0180 const-string v11, "manifest"
  0184 invoke-virtual v0, Ljava/io/ByteArrayOutputStream;->size()I
  018a move-result v6
  018c int-to-long v6, v6
  018e move-object/from16 v10, v29
  0192 move-object v8, v12
  0194 move-wide v12, v6
  0196 move-object v7, v14
  0198 move-object v6, v15
  019a move-wide/from16 v14, v16
  019e invoke-static/range v10 ... v15, Lcom/personal/aihub/SparkingContent;->progress(Lcom/personal/aihub/SparkingContent$Progress; Ljava/lang/String; J J)V
  01a4 move-object/from16 v9, v28
  01a8 move-object v15, v6
  01aa move-object v14, v7
  01ac move-object v12, v8
  01ae move-object/from16 v7, v20
  01b2 const/4 v8, 1
  01b4 goto -34h
  01b6 move-exception v0
  01b8 goto +10h
  01ba move-object v7, v14
  01bc move-object v6, v15
  01be new-instance v0, Ljava/io/IOException;
  01c2 invoke-direct v0, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01c8 throw v0
  01ca move-exception v0
  01cc goto +7h
  01ce move-exception v0
  01d0 move-object/from16 v20, v7
  01d4 move-object/from16 v28, v9
  01d8 move-object v6, v15
  01da move-object v13, v3
  01dc move-object v12, v4
  01de move-object/from16 v11, v20
  01e2 goto/16 +2b3h
  01e6 move-object/from16 v20, v7
  01ea move-object/from16 v28, v9
  01ee move-object v6, v15
  01f0 invoke-virtual v6, Ljava/io/InputStream;->close()V
  01f6 invoke-virtual v0, Ljava/io/ByteArrayOutputStream;->toByteArray()[B
  01fc move-result-object v0
  01fe const-wide/16 v6, 0
  0202 cmp-long v8, v16, v6
  0206 if-ltz v8, +011h
  020a array-length v8, v0
  020c int-to-long v8, v8
  020e cmp-long v8, v8, v16
  0212 if-nez v8, +003h
  0216 goto +9h
  0218 new-instance v0, Ljava/io/IOException;
  021c const-string v6, "The Sparking manifest download is incomplete."
  0220 invoke-direct v0, v6, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0226 throw v0
  0228 invoke-virtual/range v28, Ljavax/net/ssl/HttpsURLConnection;->disconnect()V
  022e new-instance v8, Lorg/json/JSONObject;
  0232 new-instance v9, Ljava/lang/String;
  0236 sget-object v10, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  023a invoke-direct v9, v0, v10, Ljava/lang/String;-><init>([B Ljava/nio/charset/Charset;)V
  0240 invoke-direct v8, v9, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0246 invoke-static v8, Lcom/personal/aihub/SparkingContent;->databaseRecord(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  024c move-result-object v9
  024e const-string v10, "size"
  0252 invoke-virtual v9, v10, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0258 move-result-wide v18
  025a const-string v10, "latest_version"
  025e invoke-virtual v8, v10, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  0264 move-result-object v8
  0266 instance-of v10, v8, Ljava/lang/Number;
  026a if-eqz v10, +24fh
  026e instance-of v10, v8, Ljava/lang/Double;
  0272 if-nez v10, +24bh
  0276 instance-of v10, v8, Ljava/lang/Float;
  027a if-nez v10, +247h
  027e move-object v10, v8
  0280 check-cast v10, Ljava/lang/Number;
  0284 invoke-virtual v10, Ljava/lang/Number;->longValue()J
  028a move-result-wide v12
  028c cmp-long v10, v12, v6
  0290 if-ltz v10, +23ch
  0294 new-instance v10, Ljava/io/FileOutputStream;
  0298 invoke-direct v10, v4, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  029e invoke-virtual v10, v0, Ljava/io/FileOutputStream;->write([B)V
  02a4 invoke-virtual v10, Ljava/io/FileOutputStream;->getFD()Ljava/io/FileDescriptor;
  02aa move-result-object v0
  02ac invoke-virtual v0, Ljava/io/FileDescriptor;->sync()V
  02b2 invoke-virtual v10, Ljava/io/FileOutputStream;->close()V
  02b8 const-string v0, "SHA-256"
  02bc invoke-static v0, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;
  02c2 move-result-object v0
  02c4 new-instance v10, Lcom/personal/aihub/SparkingContent$XXH64;
  02c8 invoke-direct v10, Lcom/personal/aihub/SparkingContent$XXH64;-><init>()V
  02ce const-string v12, "url"
  02d2 invoke-virtual v9, v12, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  02d8 move-result-object v12
  02da const/4 v13, 0
  02dc invoke-static v12, v13, Lcom/personal/aihub/SparkingContent;->connect(Ljava/lang/String; Z)Ljavax/net/ssl/HttpsURLConnection;
  02e2 move-result-object v22
  02e4 invoke-virtual/range v22, Ljavax/net/ssl/HttpsURLConnection;->getContentLengthLong()J
  02ea move-result-wide v12
  02ec cmp-long v14, v12, v6
  02f0 if-ltz v14, +00fh
  02f4 cmp-long v12, v12, v18
  02f8 if-nez v12, +003h
  02fc goto +9h
  02fe new-instance v0, Ljava/io/IOException;
  0302 const-string v6, "The Sparking database size differs from its manifest."
  0306 invoke-direct v0, v6, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  030c throw v0
  030e new-instance v14, Ljava/io/BufferedInputStream;
  0312 invoke-virtual/range v22, Ljavax/net/ssl/HttpsURLConnection;->getInputStream()Ljava/io/InputStream;
  0318 move-result-object v12
  031a invoke-direct v14, v12, Ljava/io/BufferedInputStream;-><init>(Ljava/io/InputStream;)V
  0320 new-instance v15, Ljava/io/FileOutputStream;
  0324 invoke-direct v15, v3, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  032a const/high16 v12, 131072
  032e new-array v13, v12, [B
  0332 invoke-virtual v14, v13, Ljava/io/InputStream;->read([B)I
  0338 move-result v12
  033a if-eq v12, v11, +052h
  033e move-object/from16 v23, v3
  0342 move-object/from16 v24, v4
  0346 int-to-long v3, v12
  0348 add-long/2addr v6, v3
  034a cmp-long v3, v6, v18
  034e if-gtz v3, +032h
  0352 const-wide/32 v3, 201326592
  0358 cmp-long v3, v6, v3
  035c if-gtz v3, +02bh
  0360 const/4 v3, 0
  0362 invoke-virtual v15, v13, v3, v12, Ljava/io/FileOutputStream;->write([B I I)V
  0368 invoke-virtual v0, v13, v3, v12, Ljava/security/MessageDigest;->update([B I I)V
  036e invoke-virtual v10, v13, v3, v12, Lcom/personal/aihub/SparkingContent$XXH64;->update([B I I)V
  0374 const-string v4, "database"
  0378 move-object/from16 v12, v29
  037c move-object/from16 v21, v13
  0380 move-object v13, v4
  0382 move-object v4, v14
  0384 move-object/from16 v25, v15
  0388 move-wide v14, v6
  038a move-wide/from16 v16, v18
  038e invoke-static/range v12 ... v17, Lcom/personal/aihub/SparkingContent;->progress(Lcom/personal/aihub/SparkingContent$Progress; Ljava/lang/String; J J)V
  0394 move-object v14, v4
  0396 move-object/from16 v13, v21
  039a move-object/from16 v3, v23
  039e move-object/from16 v4, v24
  03a2 move-object/from16 v15, v25
  03a6 goto -3ah
  03a8 move-exception v0
  03aa move-object v4, v14
  03ac move-object/from16 v25, v15
  03b0 goto +eh
  03b2 move-object v4, v14
  03b4 move-object/from16 v25, v15
  03b8 const/4 v3, 0
  03ba new-instance v0, Ljava/io/IOException;
  03be const-string v6, "The Sparking database exceeds its declared size."
  03c2 invoke-direct v0, v6, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03c8 throw v0
  03ca move-exception v0
  03cc move-object v6, v0
  03ce move-object/from16 v11, v20
  03d2 move-object/from16 v13, v23
  03d6 move-object/from16 v12, v24
  03da goto/16 +151h
  03de move-object/from16 v23, v3
  03e2 move-object/from16 v24, v4
  03e6 move-object v4, v14
  03e8 move-object/from16 v25, v15
  03ec const/4 v3, 0
  03ee invoke-virtual/range v25, Ljava/io/FileOutputStream;->getFD()Ljava/io/FileDescriptor;
  03f4 move-result-object v11
  03f6 invoke-virtual v11, Ljava/io/FileDescriptor;->sync()V
  03fc invoke-virtual/range v25, Ljava/io/FileOutputStream;->close()V
  0402 invoke-virtual v4, Ljava/io/InputStream;->close()V
  0408 invoke-virtual/range v22, Ljavax/net/ssl/HttpsURLConnection;->disconnect()V
  040e invoke-virtual v10, Lcom/personal/aihub/SparkingContent$XXH64;->value()J
  0414 move-result-wide v10
  0416 invoke-static v10, v11, Ljava/lang/Long;->toUnsignedString(J)Ljava/lang/String;
  041c move-result-object v4
  041e cmp-long v10, v6, v18
  0422 if-nez v10, +0f4h
  0426 const-string v10, "hash"
  042a invoke-virtual v9, v10, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0430 move-result-object v9
  0432 invoke-virtual v4, v9, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0438 move-result v9
  043a if-eqz v9, +0e8h
  043e invoke-virtual v1, Ljava/io/File;->exists()Z
  0444 move-result v9
  0446 if-eqz v9, +020h
  044a invoke-virtual v1, v5, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  0450 move-result v9
  0452 if-eqz v9, +004h
  0456 const/4 v9, 1
  0458 goto +18h
  045a new-instance v0, Ljava/io/IOException;
  045e const-string v4, "Could not preserve the previous Sparking database."
  0462 invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0468 throw v0
  046a move-exception v0
  046c move-object v4, v0
  046e move v0, v3
  0470 move v6, v0
  0472 move v9, v6
  0474 move v10, v9
  0476 move-object/from16 v11, v20
  047a move-object/from16 v13, v23
  047e move-object/from16 v12, v24
  0482 goto/16 +195h
  0486 move v9, v3
  0488 invoke-virtual v2, Ljava/io/File;->exists()Z
  048e move-result v10
  0490 if-eqz v10, +01ch
  0494 move-object/from16 v11, v20
  0498 invoke-virtual v2, v11, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  049e move-result v10
  04a0 if-eqz v10, +006h
  04a4 move-object/from16 v12, v24
  04a8 const/4 v10, 1
  04aa goto +14h
  04ac new-instance v0, Ljava/io/IOException;
  04b0 const-string v4, "Could not preserve the previous Sparking manifest."
  04b4 invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  04ba throw v0
  04bc move-exception v0
  04be move-object v4, v0
  04c0 move v0, v3
  04c2 move v6, v0
  04c4 move v10, v6
  04c6 goto -26h
  04c8 move-object/from16 v11, v20
  04cc move v10, v3
  04ce move-object/from16 v12, v24
  04d2 invoke-virtual v12, v2, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  04d8 move-result v13
  04da if-eqz v13, +06fh
  04de move-object/from16 v13, v23
  04e2 invoke-virtual v13, v1, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  04e8 move-result v14
  04ea if-eqz v14, +051h
  04ee new-instance v3, Lorg/json/JSONObject;
  04f2 invoke-direct v3, Lorg/json/JSONObject;-><init>()V
  04f8 const-string v14, "latestVersion"
  04fc check-cast v8, Ljava/lang/Number;
  0500 move/from16 v28, v9
  0504 invoke-virtual v8, Ljava/lang/Number;->longValue()J
  050a move-result-wide v8
  050c invoke-virtual v3, v14, v8, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0512 move-result-object v3
  0514 const-string v8, "bytes"
  0518 invoke-virtual v3, v8, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  051e move-result-object v3
  0520 const-string v6, "sha256"
  0524 invoke-virtual v0, Ljava/security/MessageDigest;->digest()[B
  052a move-result-object v0
  052c invoke-static v0, Lcom/personal/aihub/SparkingContent;->hex([B)Ljava/lang/String;
  0532 move-result-object v0
  0534 invoke-virtual v3, v6, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  053a move-result-object v0
  053c const-string v3, "xxhash64"
  0540 invoke-virtual v0, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0546 move-result-object v0
  0548 const-string v3, "sourceURL"
  054c const-string v4, "https://ddl.dokkan-sparking.com/dokkan/assets/global/en/sqlite/current/en/database.db"
  0550 invoke-virtual v0, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0556 move-result-object v0
  0558 invoke-virtual v13, Ljava/io/File;->delete()Z
  055e invoke-virtual v12, Ljava/io/File;->delete()Z
  0564 invoke-virtual v5, Ljava/io/File;->delete()Z
  056a invoke-virtual v11, Ljava/io/File;->delete()Z
  0570 return-object v0
  0572 move-exception v0
  0574 move/from16 v9, v28
  0578 goto +4h
  057a move-exception v0
  057c move/from16 v28, v9
  0580 move-object v4, v0
  0582 const/4 v0, 1
  0584 const/4 v3, 1
  0586 const/4 v6, 1
  0588 goto/16 +112h
  058c move/from16 v28, v9
  0590 new-instance v0, Ljava/io/IOException;
  0594 const-string v4, "Could not commit the Sparking database."
  0598 invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  059e throw v0
  05a0 move-exception v0
  05a2 move/from16 v9, v28
  05a6 goto +4h
  05a8 move-exception v0
  05aa move/from16 v28, v9
  05ae move-object v4, v0
  05b0 move v6, v3
  05b2 const/4 v0, 1
  05b4 goto/16 +0fch
  05b8 move/from16 v28, v9
  05bc move-object/from16 v13, v23
  05c0 new-instance v0, Ljava/io/IOException;
  05c4 const-string v4, "Could not commit the Sparking manifest."
  05c8 invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  05ce throw v0
  05d0 move-exception v0
  05d2 move/from16 v9, v28
  05d6 goto +6h
  05d8 move-exception v0
  05da move/from16 v28, v9
  05de move-object/from16 v13, v23
  05e2 move-object v4, v0
  05e4 move v0, v3
  05e6 move v6, v0
  05e8 goto/16 +0e2h
  05ec move-exception v0
  05ee move/from16 v28, v9
  05f2 move-object/from16 v11, v20
  05f6 move-object/from16 v13, v23
  05fa move-object/from16 v12, v24
  05fe move-object v4, v0
  0600 move v0, v3
  0602 move v6, v0
  0604 move v10, v6
  0606 goto/16 +0d3h
  060a move-object/from16 v11, v20
  060e move-object/from16 v13, v23
  0612 move-object/from16 v12, v24
  0616 new-instance v0, Ljava/io/IOException;
  061a const-string v4, "The Sparking database checksum does not match. Existing content was kept."
  061e invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0624 throw v0
  0626 move-exception v0
  0628 move-object/from16 v11, v20
  062c move-object/from16 v13, v23
  0630 move-object/from16 v12, v24
  0634 goto/16 +0b7h
  0638 move-exception v0
  063a move-object/from16 v11, v20
  063e move-object/from16 v13, v23
  0642 move-object/from16 v12, v24
  0646 goto +41h
  0648 move-exception v0
  064a move-object/from16 v11, v20
  064e move-object/from16 v13, v23
  0652 move-object/from16 v12, v24
  0656 goto +26h
  0658 move-exception v0
  065a move-object/from16 v11, v20
  065e move-object/from16 v13, v23
  0662 move-object/from16 v12, v24
  0666 goto +ah
  0668 move-exception v0
  066a move-object v13, v3
  066c move-object v12, v4
  066e move-object v4, v14
  0670 move-object/from16 v25, v15
  0674 move-object/from16 v11, v20
  0678 const/4 v3, 0
  067a move-object v6, v0
  067c invoke-virtual/range v25, Ljava/io/FileOutputStream;->close()V
  0682 goto +6h
  0684 move-exception v0
  0686 move-object v7, v0
  0688 invoke-virtual v6, v7, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  068e throw v6
  0690 move-exception v0
  0692 goto +8h
  0694 move-exception v0
  0696 move-object v13, v3
  0698 move-object v12, v4
  069a move-object v4, v14
  069c move-object/from16 v11, v20
  06a0 const/4 v3, 0
  06a2 move-object v6, v0
  06a4 invoke-virtual v4, Ljava/io/InputStream;->close()V
  06aa goto +6h
  06ac move-exception v0
  06ae move-object v4, v0
  06b0 invoke-virtual v6, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  06b6 throw v6
  06b8 move-exception v0
  06ba goto +7h
  06bc move-exception v0
  06be move-object v13, v3
  06c0 move-object v12, v4
  06c2 move-object/from16 v11, v20
  06c6 const/4 v3, 0
  06c8 invoke-virtual/range v22, Ljavax/net/ssl/HttpsURLConnection;->disconnect()V
  06ce throw v0
  06d0 move-exception v0
  06d2 move-object v12, v4
  06d4 move-object/from16 v11, v20
  06d8 move/from16 v26, v13
  06dc move-object v13, v3
  06de move/from16 v3, v26
  06e2 goto/16 +060h
  06e6 move-exception v0
  06e8 move-object v13, v3
  06ea move-object v12, v4
  06ec move-object/from16 v11, v20
  06f0 const/4 v3, 0
  06f2 move-object v4, v0
  06f4 invoke-virtual v10, Ljava/io/FileOutputStream;->close()V
  06fa goto +6h
  06fc move-exception v0
  06fe move-object v6, v0
  0700 invoke-virtual v4, v6, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0706 throw v4
  0708 move-object v13, v3
  070a move-object v12, v4
  070c move-object/from16 v11, v20
  0710 const/4 v3, 0
  0712 new-instance v0, Ljava/io/IOException;
  0716 const-string v4, "Invalid Sparking content version."
  071a invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0720 throw v0
  0722 move-exception v0
  0724 move-object v13, v3
  0726 move-object v12, v4
  0728 move-object/from16 v11, v20
  072c goto +3ah
  072e move-exception v0
  0730 move-object v13, v3
  0732 move-object v12, v4
  0734 move-object/from16 v11, v20
  0738 goto +29h
  073a move-exception v0
  073c move-object v13, v3
  073e move-object v12, v4
  0740 move-object v11, v7
  0742 move-object/from16 v28, v9
  0746 move-object v6, v15
  0748 const/4 v3, 0
  074a move-object v4, v0
  074c invoke-virtual v6, Ljava/io/InputStream;->close()V
  0752 goto +6h
  0754 move-exception v0
  0756 move-object v6, v0
  0758 invoke-virtual v4, v6, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  075e throw v4
  0760 move-object v13, v3
  0762 move-object v12, v4
  0764 move-object v11, v7
  0766 move-object/from16 v28, v9
  076a move-object v7, v14
  076c const/4 v3, 0
  076e new-instance v0, Ljava/io/IOException;
  0772 invoke-direct v0, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0778 throw v0
  077a move-exception v0
  077c goto +8h
  077e move-exception v0
  0780 move-object v13, v3
  0782 move-object v12, v4
  0784 move-object v11, v7
  0786 move-object/from16 v28, v9
  078a const/4 v3, 0
  078c invoke-virtual/range v28, Ljavax/net/ssl/HttpsURLConnection;->disconnect()V
  0792 throw v0
  0794 move-exception v0
  0796 goto +6h
  0798 move-exception v0
  079a move-object v13, v3
  079c move-object v12, v4
  079e move-object v11, v7
  07a0 const/4 v3, 0
  07a2 move-object v4, v0
  07a4 move v0, v3
  07a6 move v6, v0
  07a8 move v9, v6
  07aa move v10, v9
  07ac invoke-virtual v13, Ljava/io/File;->delete()Z
  07b2 invoke-virtual v12, Ljava/io/File;->delete()Z
  07b8 if-nez v6, +04dh
  07bc if-eqz v3, +005h
  07c0 invoke-virtual v1, Ljava/io/File;->delete()Z
  07c6 if-eqz v0, +005h
  07ca invoke-virtual v2, Ljava/io/File;->delete()Z
  07d0 if-eqz v9, +021h
  07d4 invoke-virtual v5, v1, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  07da move-result v0
  07dc if-eqz v0, +003h
  07e0 goto +19h
  07e2 new-instance v0, Ljava/io/IOException;
  07e6 new-instance v1, Ljava/lang/StringBuilder;
  07ea const-string v2, "Sparking download rollback needs recovery: the previous database is retained in "
  07ee invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  07f4 invoke-virtual v5, Ljava/io/File;->getName()Ljava/lang/String;
  07fa move-result-object v2
  07fc invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0802 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0808 move-result-object v1
  080a invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0810 throw v0
  0812 if-eqz v10, +026h
  0816 invoke-virtual v11, v2, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  081c move-result v0
  081e if-nez v0, +020h
  0822 new-instance v0, Ljava/io/IOException;
  0826 new-instance v1, Ljava/lang/StringBuilder;
  082a const-string v2, "Sparking download rollback needs recovery: the previous manifest is retained in "
  082e invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0834 invoke-virtual v11, Ljava/io/File;->getName()Ljava/lang/String;
  083a move-result-object v2
  083c invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0842 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0848 move-result-object v1
  084a invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0850 throw v0
  0852 invoke-virtual v5, Ljava/io/File;->delete()Z
  0858 invoke-virtual v11, Ljava/io/File;->delete()Z
  085e throw v4
  0860 new-instance v0, Ljava/io/IOException;
  0864 const-string v1, "Use separate private files for the Sparking database and manifest."
  0868 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  086e throw v0
.end method

.method downloadAsset(Ljava/io/File; Ljava/lang/String; Ljava/io/File; Lcom/personal/aihub/SparkingContent$Progress;)Lorg/json/JSONObject;
  0000 move-object/from16 v0, v22
  0004 invoke-virtual/range v21, Ljava/io/File;->isFile()Z
  000a move-result v1
  000c if-eqz v1, +1c2h
  0010 invoke-virtual/range v21, Ljava/io/File;->length()J
  0016 move-result-wide v1
  0018 const-wide/16 v3, 0
  001c cmp-long v1, v1, v3
  0020 if-lez v1, +1b8h
  0024 invoke-virtual/range v21, Ljava/io/File;->length()J
  002a move-result-wide v1
  002c const-wide/32 v5, 33554432
  0032 cmp-long v1, v1, v5
  0036 if-gtz v1, +1adh
  003a new-instance v1, Ljava/io/FileInputStream;
  003e move-object/from16 v2, v21
  0042 invoke-direct v1, v2, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0048 new-instance v7, Ljava/io/ByteArrayOutputStream;
  004c invoke-direct v7, Ljava/io/ByteArrayOutputStream;-><init>()V
  0052 const/high16 v8, 65536
  0056 new-array v8, v8, [B
  005a invoke-virtual v1, v8, Ljava/io/InputStream;->read([B)I
  0060 move-result v9
  0062 const/4 v10, -1
  0064 const/4 v11, 0
  0066 if-eq v9, v10, +019h
  006a invoke-virtual v7, Ljava/io/ByteArrayOutputStream;->size()I
  0070 move-result v10
  0072 int-to-long v12, v10
  0074 int-to-long v14, v9
  0076 add-long/2addr v12, v14
  0078 cmp-long v10, v12, v5
  007c if-gtz v10, +006h
  0080 invoke-virtual v7, v8, v11, v9, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  0086 goto -16h
  0088 new-instance v0, Ljava/io/IOException;
  008c const-string v2, "The Sparking manifest exceeds32MiB."
  0090 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0096 throw v0
  0098 invoke-virtual v7, Ljava/io/ByteArrayOutputStream;->toByteArray()[B
  009e move-result-object v5
  00a0 invoke-virtual v7, Ljava/io/ByteArrayOutputStream;->close()V
  00a6 invoke-virtual v1, Ljava/io/InputStream;->close()V
  00ac new-instance v1, Lorg/json/JSONObject;
  00b0 new-instance v6, Ljava/lang/String;
  00b4 sget-object v7, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  00b8 invoke-direct v6, v5, v7, Ljava/lang/String;-><init>([B Ljava/nio/charset/Charset;)V
  00be invoke-direct v1, v6, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  00c4 invoke-static v1, v0, Lcom/personal/aihub/SparkingContent;->assetRecord(Lorg/json/JSONObject; Ljava/lang/String;)Lorg/json/JSONObject;
  00ca move-result-object v1
  00cc invoke-static/range v23, Lcom/personal/aihub/SparkingContent;->destination(Ljava/io/File;)Ljava/io/File;
  00d2 move-result-object v5
  00d4 invoke-virtual/range v21, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  00da move-result-object v2
  00dc invoke-virtual v5, v2, Ljava/io/File;->equals(Ljava/lang/Object;)Z
  00e2 move-result v2
  00e4 if-nez v2, +136h
  00e8 new-instance v2, Ljava/io/File;
  00ec invoke-virtual v5, Ljava/io/File;->getParentFile()Ljava/io/File;
  00f2 move-result-object v6
  00f4 new-instance v7, Ljava/lang/StringBuilder;
  00f8 const-string v8, "sparking-asset-"
  00fc invoke-direct v7, v8, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0102 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0108 move-result-object v8
  010a invoke-virtual v7, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0110 const-string v8, ".tmp"
  0114 invoke-virtual v7, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  011a invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0120 move-result-object v7
  0122 invoke-direct v2, v6, v7, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0128 const-string v6, "size"
  012c invoke-virtual v1, v6, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0132 move-result-wide v6
  0134 const-string v8, "SHA-256"
  0138 invoke-static v8, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;
  013e move-result-object v8
  0140 new-instance v9, Lcom/personal/aihub/SparkingContent$XXH64;
  0144 invoke-direct v9, Lcom/personal/aihub/SparkingContent$XXH64;-><init>()V
  014a new-instance v12, Ljava/net/URI;
  014e const-string v13, "url"
  0152 invoke-virtual v1, v13, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0158 move-result-object v13
  015a invoke-direct v12, v13, Ljava/net/URI;-><init>(Ljava/lang/String;)V
  0160 invoke-static v12, v11, Lcom/personal/aihub/SparkingContent;->open(Ljava/net/URI; Z)Ljavax/net/ssl/HttpsURLConnection;
  0166 move-result-object v18
  0168 invoke-virtual/range v18, Ljavax/net/ssl/HttpsURLConnection;->getContentLengthLong()J
  016e move-result-wide v12
  0170 cmp-long v14, v12, v3
  0174 if-ltz v14, +00fh
  0178 cmp-long v12, v12, v6
  017c if-nez v12, +003h
  0180 goto +9h
  0182 new-instance v0, Ljava/io/IOException;
  0186 const-string v1, "The Sparking resource size differs from its manifest."
  018a invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0190 throw v0
  0192 new-instance v14, Ljava/io/BufferedInputStream;
  0196 invoke-virtual/range v18, Ljavax/net/ssl/HttpsURLConnection;->getInputStream()Ljava/io/InputStream;
  019c move-result-object v12
  019e invoke-direct v14, v12, Ljava/io/BufferedInputStream;-><init>(Ljava/io/InputStream;)V
  01a4 new-instance v15, Ljava/io/FileOutputStream;
  01a8 invoke-direct v15, v2, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  01ae const/high16 v12, 131072
  01b2 new-array v13, v12, [B
  01b6 invoke-virtual v14, v13, Ljava/io/InputStream;->read([B)I
  01bc move-result v12
  01be if-eq v12, v10, +035h
  01c2 int-to-long v10, v12
  01c4 add-long/2addr v3, v10
  01c6 cmp-long v10, v3, v6
  01ca if-gtz v10, +024h
  01ce const/4 v10, 0
  01d0 invoke-virtual v15, v13, v10, v12, Ljava/io/FileOutputStream;->write([B I I)V
  01d6 invoke-virtual v8, v13, v10, v12, Ljava/security/MessageDigest;->update([B I I)V
  01dc invoke-virtual v9, v13, v10, v12, Lcom/personal/aihub/SparkingContent$XXH64;->update([B I I)V
  01e2 const-string v11, "asset"
  01e6 move-object/from16 v12, v24
  01ea move-object/from16 v19, v13
  01ee move-object v13, v11
  01f0 move-object v11, v14
  01f2 move-object/from16 v20, v15
  01f6 move-wide v14, v3
  01f8 move-wide/from16 v16, v6
  01fc invoke-static/range v12 ... v17, Lcom/personal/aihub/SparkingContent;->progress(Lcom/personal/aihub/SparkingContent$Progress; Ljava/lang/String; J J)V
  0202 move-object v14, v11
  0204 move-object/from16 v13, v19
  0208 move-object/from16 v15, v20
  020c move v11, v10
  020e const/4 v10, -1
  0210 goto -2dh
  0212 move-object v11, v14
  0214 move-object/from16 v20, v15
  0218 new-instance v0, Ljava/io/IOException;
  021c const-string v1, "The Sparking resource exceeds its declared size."
  0220 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0226 throw v0
  0228 move-object v11, v14
  022a move-object/from16 v20, v15
  022e invoke-virtual/range v20, Ljava/io/FileOutputStream;->getFD()Ljava/io/FileDescriptor;
  0234 move-result-object v10
  0236 invoke-virtual v10, Ljava/io/FileDescriptor;->sync()V
  023c invoke-virtual/range v20, Ljava/io/FileOutputStream;->close()V
  0242 invoke-virtual v11, Ljava/io/InputStream;->close()V
  0248 invoke-virtual/range v18, Ljavax/net/ssl/HttpsURLConnection;->disconnect()V
  024e invoke-virtual v9, Lcom/personal/aihub/SparkingContent$XXH64;->value()J
  0254 move-result-wide v9
  0256 invoke-static v9, v10, Ljava/lang/Long;->toUnsignedString(J)Ljava/lang/String;
  025c move-result-object v9
  025e cmp-long v6, v3, v6
  0262 if-nez v6, +045h
  0266 const-string v6, "hash"
  026a invoke-virtual v1, v6, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0270 move-result-object v1
  0272 invoke-virtual v9, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0278 move-result v1
  027a if-eqz v1, +039h
  027e invoke-virtual v2, v5, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  0284 move-result v1
  0286 if-eqz v1, +02bh
  028a new-instance v1, Lorg/json/JSONObject;
  028e invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  0294 const-string v5, "file_path"
  0298 invoke-virtual v1, v5, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  029e move-result-object v0
  02a0 const-string v1, "bytes"
  02a4 invoke-virtual v0, v1, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  02aa move-result-object v0
  02ac const-string v1, "sha256"
  02b0 invoke-virtual v8, Ljava/security/MessageDigest;->digest()[B
  02b6 move-result-object v3
  02b8 invoke-static v3, Lcom/personal/aihub/SparkingContent;->hex([B)Ljava/lang/String;
  02be move-result-object v3
  02c0 invoke-virtual v0, v1, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02c6 move-result-object v0
  02c8 const-string v1, "xxhash64"
  02cc invoke-virtual v0, v1, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02d2 move-result-object v0
  02d4 invoke-virtual v2, Ljava/io/File;->delete()Z
  02da return-object v0
  02dc new-instance v0, Ljava/io/IOException;
  02e0 const-string v1, "Could not commit the Sparking game resource."
  02e4 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02ea throw v0
  02ec new-instance v0, Ljava/io/IOException;
  02f0 const-string v1, "The Sparking resource checksum does not match. Existing content was kept."
  02f4 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02fa throw v0
  02fc move-exception v0
  02fe goto +5h
  0300 move-exception v0
  0302 move-object v11, v14
  0304 move-object/from16 v20, v15
  0308 move-object v1, v0
  030a invoke-virtual/range v20, Ljava/io/FileOutputStream;->close()V
  0310 goto +6h
  0312 move-exception v0
  0314 move-object v3, v0
  0316 invoke-virtual v1, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  031c throw v1
  031e move-exception v0
  0320 goto +3h
  0322 move-exception v0
  0324 move-object v11, v14
  0326 move-object v1, v0
  0328 invoke-virtual v11, Ljava/io/InputStream;->close()V
  032e goto +6h
  0330 move-exception v0
  0332 move-object v3, v0
  0334 invoke-virtual v1, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  033a throw v1
  033c move-exception v0
  033e invoke-virtual/range v18, Ljavax/net/ssl/HttpsURLConnection;->disconnect()V
  0344 throw v0
  0346 move-exception v0
  0348 invoke-virtual v2, Ljava/io/File;->delete()Z
  034e throw v0
  0350 new-instance v0, Ljava/io/IOException;
  0354 const-string v1, "Do not overwrite the Sparking manifest with a game resource."
  0358 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  035e throw v0
  0360 move-exception v0
  0362 move-object v2, v0
  0364 invoke-virtual v7, Ljava/io/ByteArrayOutputStream;->close()V
  036a goto +6h
  036c move-exception v0
  036e move-object v3, v0
  0370 invoke-virtual v2, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0376 throw v2
  0378 move-exception v0
  037a move-object v2, v0
  037c invoke-virtual v1, Ljava/io/InputStream;->close()V
  0382 goto +6h
  0384 move-exception v0
  0386 move-object v1, v0
  0388 invoke-virtual v2, v1, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  038e throw v2
  0390 new-instance v0, Ljava/io/IOException;
  0394 const-string v1, "Update the Sparking content manifest first."
  0398 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  039e throw v0
.end method

.method downloadManifest(Ljava/io/File; Lcom/personal/aihub/SparkingContent$Progress;)Lorg/json/JSONObject;
  0000 invoke-static/range v19, Lcom/personal/aihub/SparkingContent;->destination(Ljava/io/File;)Ljava/io/File;
  0006 move-result-object v0
  0008 new-instance v1, Ljava/io/File;
  000c invoke-virtual v0, Ljava/io/File;->getParentFile()Ljava/io/File;
  0012 move-result-object v2
  0014 new-instance v3, Ljava/lang/StringBuilder;
  0018 const-string v4, "sparking-list-"
  001c invoke-direct v3, v4, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0022 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0028 move-result-object v4
  002a invoke-virtual v3, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0030 const-string v4, ".tmp"
  0034 invoke-virtual v3, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  003a invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0040 move-result-object v3
  0042 invoke-direct v1, v2, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0048 const-string v2, "https://dokkan-sparking.com/client_assets"
  004c const/4 v3, 1
  004e invoke-static v2, v3, Lcom/personal/aihub/SparkingContent;->connect(Ljava/lang/String; Z)Ljavax/net/ssl/HttpsURLConnection;
  0054 move-result-object v2
  0056 invoke-virtual v2, Ljavax/net/ssl/HttpsURLConnection;->getContentLengthLong()J
  005c move-result-wide v3
  005e const-wide/32 v5, 33554432
  0064 cmp-long v7, v3, v5
  0068 const-string v8, "The Sparking content list exceeds32MiB."
  006c if-gtz v7, +0f4h
  0070 invoke-virtual v2, Ljavax/net/ssl/HttpsURLConnection;->getInputStream()Ljava/io/InputStream;
  0076 move-result-object v7
  0078 new-instance v9, Ljava/io/ByteArrayOutputStream;
  007c invoke-direct v9, Ljava/io/ByteArrayOutputStream;-><init>()V
  0082 const/high16 v10, 65536
  0086 new-array v10, v10, [B
  008a invoke-virtual v7, v10, Ljava/io/InputStream;->read([B)I
  0090 move-result v11
  0092 const/4 v12, -1
  0094 if-eq v11, v12, +028h
  0098 invoke-virtual v9, Ljava/io/ByteArrayOutputStream;->size()I
  009e move-result v12
  00a0 add-int/2addr v12, v11
  00a2 int-to-long v12, v12
  00a4 cmp-long v12, v12, v5
  00a8 if-gtz v12, +018h
  00ac const/4 v12, 0
  00ae invoke-virtual v9, v10, v12, v11, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  00b4 const-string v14, "manifest"
  00b8 invoke-virtual v9, Ljava/io/ByteArrayOutputStream;->size()I
  00be move-result v11
  00c0 int-to-long v11, v11
  00c2 invoke-virtual v2, Ljavax/net/ssl/HttpsURLConnection;->getContentLengthLong()J
  00c8 move-result-wide v17
  00ca move-object/from16 v13, v20
  00ce move-wide v15, v11
  00d0 invoke-static/range v13 ... v18, Lcom/personal/aihub/SparkingContent;->progress(Lcom/personal/aihub/SparkingContent$Progress; Ljava/lang/String; J J)V
  00d6 goto -26h
  00d8 new-instance v0, Ljava/io/IOException;
  00dc invoke-direct v0, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00e2 throw v0
  00e4 invoke-virtual v9, Ljava/io/ByteArrayOutputStream;->toByteArray()[B
  00ea move-result-object v5
  00ec invoke-virtual v9, Ljava/io/ByteArrayOutputStream;->close()V
  00f2 if-eqz v7, +005h
  00f6 invoke-virtual v7, Ljava/io/InputStream;->close()V
  00fc invoke-virtual v2, Ljavax/net/ssl/HttpsURLConnection;->disconnect()V
  0102 const-wide/16 v6, 0
  0106 cmp-long v2, v3, v6
  010a if-ltz v2, +011h
  010e array-length v2, v5
  0110 int-to-long v8, v2
  0112 cmp-long v2, v8, v3
  0116 if-nez v2, +003h
  011a goto +9h
  011c new-instance v0, Ljava/io/IOException;
  0120 const-string v2, "The Sparking content list download is incomplete."
  0124 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  012a throw v0
  012c new-instance v2, Lorg/json/JSONObject;
  0130 new-instance v3, Ljava/lang/String;
  0134 sget-object v4, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0138 invoke-direct v3, v5, v4, Ljava/lang/String;-><init>([B Ljava/nio/charset/Charset;)V
  013e invoke-direct v2, v3, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0144 invoke-static v2, Lcom/personal/aihub/SparkingContent;->databaseRecord(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  014a const-string v3, "latest_version"
  014e invoke-virtual v2, v3, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  0154 move-result-object v2
  0156 instance-of v3, v2, Ljava/lang/Integer;
  015a if-nez v3, +006h
  015e instance-of v3, v2, Ljava/lang/Long;
  0162 if-eqz v3, +055h
  0166 move-object v3, v2
  0168 check-cast v3, Ljava/lang/Number;
  016c invoke-virtual v3, Ljava/lang/Number;->longValue()J
  0172 move-result-wide v3
  0174 cmp-long v3, v3, v6
  0178 if-lez v3, +04ah
  017c new-instance v3, Ljava/io/FileOutputStream;
  0180 invoke-direct v3, v1, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0186 invoke-virtual v3, v5, Ljava/io/FileOutputStream;->write([B)V
  018c invoke-virtual v3, Ljava/io/FileOutputStream;->getFD()Ljava/io/FileDescriptor;
  0192 move-result-object v4
  0194 invoke-virtual v4, Ljava/io/FileDescriptor;->sync()V
  019a invoke-virtual v3, Ljava/io/FileOutputStream;->close()V
  01a0 invoke-virtual v1, v0, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  01a6 move-result v0
  01a8 if-eqz v0, +01eh
  01ac new-instance v0, Lorg/json/JSONObject;
  01b0 invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  01b6 const-string v3, "latestVersion"
  01ba check-cast v2, Ljava/lang/Number;
  01be invoke-virtual v2, Ljava/lang/Number;->longValue()J
  01c4 move-result-wide v6
  01c6 invoke-virtual v0, v3, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  01cc move-result-object v0
  01ce const-string v2, "bytes"
  01d2 array-length v3, v5
  01d4 invoke-virtual v0, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  01da move-result-object v0
  01dc invoke-virtual v1, Ljava/io/File;->delete()Z
  01e2 return-object v0
  01e4 new-instance v0, Ljava/io/IOException;
  01e8 const-string v2, "Could not save Sparking's content list."
  01ec invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01f2 throw v0
  01f4 move-exception v0
  01f6 move-object v2, v0
  01f8 invoke-virtual v3, Ljava/io/FileOutputStream;->close()V
  01fe goto +6h
  0200 move-exception v0
  0202 move-object v3, v0
  0204 invoke-virtual v2, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  020a throw v2
  020c new-instance v0, Ljava/io/IOException;
  0210 const-string v2, "Invalid Sparking content version."
  0214 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  021a throw v0
  021c move-exception v0
  021e move-object v3, v0
  0220 invoke-virtual v9, Ljava/io/ByteArrayOutputStream;->close()V
  0226 goto +6h
  0228 move-exception v0
  022a move-object v4, v0
  022c invoke-virtual v3, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0232 throw v3
  0234 move-exception v0
  0236 move-object v3, v0
  0238 if-eqz v7, +00bh
  023c invoke-virtual v7, Ljava/io/InputStream;->close()V
  0242 goto +6h
  0244 move-exception v0
  0246 move-object v4, v0
  0248 invoke-virtual v3, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  024e throw v3
  0250 move-exception v0
  0252 goto +7h
  0254 new-instance v0, Ljava/io/IOException;
  0258 invoke-direct v0, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  025e throw v0
  0260 invoke-virtual v2, Ljavax/net/ssl/HttpsURLConnection;->disconnect()V
  0266 throw v0
  0268 move-exception v0
  026a invoke-virtual v1, Ljava/io/File;->delete()Z
  0270 throw v0
.end method

.method gamePath(Ljava/lang/String;)V
  0000 if-eqz v13, +0dfh
  0004 invoke-virtual v13, Ljava/lang/String;->length()I
  000a move-result v0
  000c const/16 v1, 500
  0010 if-gt v0, v1, +0d7h
  0014 const/16 v0, 92
  0018 invoke-virtual v13, v0, Ljava/lang/String;->indexOf(I)I
  001e move-result v0
  0020 if-gez v0, +0cfh
  0024 const/16 v0, 58
  0028 invoke-virtual v13, v0, Ljava/lang/String;->indexOf(I)I
  002e move-result v0
  0030 if-gez v0, +0c7h
  0034 const-string v0, "(?s).*[\x00-\x1f\x7f].*"
  0038 invoke-virtual v13, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  003e move-result v0
  0040 if-nez v0, +0bfh
  0044 const-string v0, "/"
  0048 const/4 v1, -1
  004a invoke-virtual v13, v0, v1, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  0050 move-result-object v0
  0052 array-length v1, v0
  0054 const/4 v2, 0
  0056 move v3, v2
  0058 if-ge v3, v1, +025h
  005c aget-object v4, v0, v3
  0060 invoke-virtual v4, Ljava/lang/String;->isEmpty()Z
  0066 move-result v5
  0068 if-nez v5, +015h
  006c const-string v5, "."
  0070 invoke-virtual v4, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0076 move-result v5
  0078 if-nez v5, +00dh
  007c const-string v5, ".."
  0080 invoke-virtual v4, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0086 move-result v4
  0088 if-nez v4, +005h
  008c add-int/lit8 v3, v3, 1
  0090 goto -1ch
  0092 new-instance v13, Ljava/io/IOException;
  0096 const-string v0, "Unsafe Sparking game resource path."
  009a invoke-direct v13, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00a0 throw v13
  00a2 const/16 v0, 47
  00a6 invoke-virtual v13, v0, Ljava/lang/String;->indexOf(I)I
  00ac move-result v1
  00ae if-gez v1, +007h
  00b2 invoke-virtual v13, Ljava/lang/String;->length()I
  00b8 move-result v0
  00ba goto +5h
  00bc invoke-virtual v13, v0, Ljava/lang/String;->indexOf(I)I
  00c2 move-result v0
  00c4 invoke-virtual v13, v2, v0, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  00ca move-result-object v0
  00cc const-string v1, "se"
  00d0 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00d6 move-result v1
  00d8 if-eqz v1, +013h
  00dc const-string v0, "se/[A-Za-z0-9_-]{1,80}\.(acb|awb)"
  00e0 invoke-virtual v13, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  00e6 move-result v13
  00e8 if-eqz v13, +003h
  00ec return-void 
  00ee new-instance v13, Ljava/io/IOException;
  00f2 const-string v0, "Unsupported Sparking sound-effect bank path."
  00f6 invoke-direct v13, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00fc throw v13
  00fe const-string v1, "voice"
  0102 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0108 move-result v1
  010a if-eqz v1, +02bh
  010e const-string v0, "voice/(?:(en|ja)/)?([A-Za-z0-9_-]{1,80})/([A-Za-z0-9_-]{1,80})\.(acb|awb)"
  0112 invoke-static v0, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;)Ljava/util/regex/Pattern;
  0118 move-result-object v0
  011a invoke-virtual v0, v13, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  0120 move-result-object v13
  0122 invoke-virtual v13, Ljava/util/regex/Matcher;->matches()Z
  0128 move-result v0
  012a if-eqz v0, +013h
  012e const/4 v0, 2
  0130 invoke-virtual v13, v0, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  0136 move-result-object v0
  0138 const/4 v1, 3
  013a invoke-virtual v13, v1, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  0140 move-result-object v13
  0142 invoke-virtual v0, v13, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0148 move-result v13
  014a if-eqz v13, +003h
  014e return-void 
  0150 new-instance v13, Ljava/io/IOException;
  0154 const-string v0, "Unsupported Sparking voice bank path."
  0158 invoke-direct v13, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  015e throw v13
  0160 const-string v11, "outgame"
  0164 const-string v12, "sugoroku"
  0168 const-string v1, "character"
  016c const-string v2, "ingame"
  0170 const-string v3, "script"
  0174 const-string v4, "movie"
  0178 const-string v5, "sound"
  017c const-string v6, "lua"
  0180 const-string v7, "bgm"
  0184 const-string v8, "item"
  0188 const-string v9, "card_category"
  018c const-string v10, "sd_battle"
  0190 filled-new-array/range v1 ... v12, [Ljava/lang/String;
  0196 move-result-object v13
  0198 invoke-static v13, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  019e move-result-object v13
  01a0 invoke-interface v13, v0, Ljava/util/List;->contains(Ljava/lang/Object;)Z
  01a6 move-result v13
  01a8 if-eqz v13, +003h
  01ac return-void 
  01ae new-instance v13, Ljava/io/IOException;
  01b2 const-string v0, "This download is not a supported game resource. Account and user-state files are excluded."
  01b6 invoke-direct v13, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01bc throw v13
  01be new-instance v13, Ljava/io/IOException;
  01c2 const-string v0, "Unsupported Sparking game resource path."
  01c6 invoke-direct v13, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01cc throw v13
.end method

.method hex([B)Ljava/lang/String;
  0000 new-instance v0, Ljava/lang/StringBuilder;
  0004 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  000a array-length v1, v6
  000c const/4 v2, 0
  000e if-ge v2, v1, +01ch
  0012 aget-byte v3, v6, v2
  0016 sget-object v4, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  001a and-int/lit16 v3, v3, 255
  001e invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0024 move-result-object v3
  0026 filled-new-array v3, [Ljava/lang/Object;
  002c move-result-object v3
  002e const-string v5, "%02x"
  0032 invoke-static v4, v5, v3, Ljava/lang/String;->format(Ljava/util/Locale; Ljava/lang/String; [Ljava/lang/Object;)Ljava/lang/String;
  0038 move-result-object v3
  003a invoke-virtual v0, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0040 add-int/lit8 v2, v2, 1
  0044 goto -1bh
  0046 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  004c move-result-object v6
  004e return-object v6
.end method

.method open(Ljava/net/URI; Z)Ljavax/net/ssl/HttpsURLConnection;
  0000 invoke-virtual v3, Ljava/net/URI;->toURL()Ljava/net/URL;
  0006 move-result-object v3
  0008 invoke-virtual v3, Ljava/net/URL;->openConnection()Ljava/net/URLConnection;
  000e move-result-object v3
  0010 check-cast v3, Ljavax/net/ssl/HttpsURLConnection;
  0014 const/4 v0, 0
  0016 invoke-virtual v3, v0, Ljavax/net/ssl/HttpsURLConnection;->setInstanceFollowRedirects(Z)V
  001c const/16 v0, 20000
  0020 invoke-virtual v3, v0, Ljavax/net/ssl/HttpsURLConnection;->setConnectTimeout(I)V
  0026 const v0, 60000
  002c invoke-virtual v3, v0, Ljavax/net/ssl/HttpsURLConnection;->setReadTimeout(I)V
  0032 const-string v0, "Accept-Encoding"
  0036 const-string v1, "identity"
  003a invoke-virtual v3, v0, v1, Ljavax/net/ssl/HttpsURLConnection;->setRequestProperty(Ljava/lang/String; Ljava/lang/String;)V
  0040 const-string v0, "User-Agent"
  0044 const-string v2, "Dokkan-Unit-Creation-Sparking-Content"
  0048 invoke-virtual v3, v0, v2, Ljavax/net/ssl/HttpsURLConnection;->setRequestProperty(Ljava/lang/String; Ljava/lang/String;)V
  004e if-eqz v4, +015h
  0052 const-string v4, "Accept"
  0056 const-string v0, "application/json"
  005a invoke-virtual v3, v4, v0, Ljavax/net/ssl/HttpsURLConnection;->setRequestProperty(Ljava/lang/String; Ljava/lang/String;)V
  0060 const-string v4, "X-AssetVersion"
  0064 const-string v0, "0"
  0068 invoke-virtual v3, v4, v0, Ljavax/net/ssl/HttpsURLConnection;->setRequestProperty(Ljava/lang/String; Ljava/lang/String;)V
  006e const-string v4, "Sparking_Asset_Version"
  0072 invoke-virtual v3, v4, v0, Ljavax/net/ssl/HttpsURLConnection;->setRequestProperty(Ljava/lang/String; Ljava/lang/String;)V
  0078 invoke-virtual v3, Ljavax/net/ssl/HttpsURLConnection;->getResponseCode()I
  007e move-result v4
  0080 const/16 v0, 200
  0084 if-eq v4, v0, +02ah
  0088 invoke-virtual v3, Ljavax/net/ssl/HttpsURLConnection;->disconnect()V
  008e new-instance v3, Ljava/io/IOException;
  0092 const/16 v0, 401
  0096 if-eq v4, v0, +01bh
  009a const/16 v0, 403
  009e if-ne v4, v0, +003h
  00a2 goto +15h
  00a4 new-instance v0, Ljava/lang/StringBuilder;
  00a8 const-string v1, "The Sparking public content server returned HTTP "
  00ac invoke-direct v0, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00b2 invoke-virtual v0, v4, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  00b8 const-string v4, ". Try again later."
  00bc invoke-virtual v0, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00c2 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00c8 move-result-object v4
  00ca goto +3h
  00cc const-string v4, "The Sparking public content server refused this request. No account credentials were sent."
  00d0 invoke-direct v3, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00d6 throw v3
  00d8 const-string v4, "Content-Encoding"
  00dc invoke-virtual v3, v4, Ljavax/net/ssl/HttpsURLConnection;->getHeaderField(Ljava/lang/String;)Ljava/lang/String;
  00e2 move-result-object v4
  00e4 if-eqz v4, +014h
  00e8 invoke-virtual v4, v1, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z
  00ee move-result v4
  00f0 if-eqz v4, +003h
  00f4 goto +ch
  00f6 invoke-virtual v3, Ljavax/net/ssl/HttpsURLConnection;->disconnect()V
  00fc new-instance v3, Ljava/io/IOException;
  0100 const-string v4, "The Sparking server changed its download encoding."
  0104 invoke-direct v3, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  010a throw v3
  010c return-object v3
.end method

.method progress(Lcom/personal/aihub/SparkingContent$Progress; Ljava/lang/String; J J)V
  0000 if-eqz v0, +005h
  0004 invoke-interface/range v0 ... v5, Lcom/personal/aihub/SparkingContent$Progress;->update(Ljava/lang/String; J J)V
  000a return-void 
.end method