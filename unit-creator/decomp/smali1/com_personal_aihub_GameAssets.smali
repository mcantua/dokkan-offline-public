.class Lcom/personal/aihub/GameAssets;
.super Ljava/lang/Object;
.field DATABASE Ljava/util/regex/Pattern;
.field MAX_BYTES I
.field PREFIX Ljava/util/regex/Pattern;
.field PRIVATE Ljava/util/Set;
.field overlays Lorg/json/JSONArray;
.field preferredKey Ljava/lang/String;
.field root Ljava/io/File;

.method <clinit>()V
  0000 new-instance v0, Ljava/util/HashSet;
  0004 const-string v10, "credentials.json"
  0008 const-string v11, "secrets.json"
  000c const-string v1, "projects"
  0010 const-string v2, "patches"
  0014 const-string v3, "exports"
  0018 const-string v4, "_databases"
  001c const-string v5, "metadata.json"
  0020 const-string v6, "forge-project.json"
  0024 const-string v7, "database-meta.json"
  0028 const-string v8, "database-state.json"
  002c const-string v9, "account.txt"
  0030 filled-new-array/range v1 ... v11, [Ljava/lang/String;
  0036 move-result-object v1
  0038 invoke-static v1, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  003e move-result-object v1
  0040 invoke-direct v0, v1, Ljava/util/HashSet;-><init>(Ljava/util/Collection;)V
  0046 sput-object v0, Lcom/personal/aihub/GameAssets;->PRIVATE Ljava/util/Set;
  004a const-string v0, "(?i).*\.(db|sqlite|sqlite3)([-.].*)?$"
  004e invoke-static v0, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;)Ljava/util/regex/Pattern;
  0054 move-result-object v0
  0056 sput-object v0, Lcom/personal/aihub/GameAssets;->DATABASE Ljava/util/regex/Pattern;
  005a const-string v0, "^(lua|script|character|ingame|movie|layout|bgm|outgame|origin|item|se|voice|comic_text|fonts|shader|dokkan_field|card_[a-z0-9_]+)/"
  005e invoke-static v0, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;)Ljava/util/regex/Pattern;
  0064 move-result-object v0
  0066 sput-object v0, Lcom/personal/aihub/GameAssets;->PREFIX Ljava/util/regex/Pattern;
  006a return-void 
.end method

.method <init>(Ljava/io/File;)V
  0000 const/4 v0, 0
  0002 invoke-direct v1, v2, v0, Lcom/personal/aihub/GameAssets;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0008 return-void 
.end method

.method <init>(Ljava/io/File; Ljava/lang/String;)V
  0000 const/4 v0, 0
  0002 invoke-direct v1, v2, v3, v0, Lcom/personal/aihub/GameAssets;-><init>(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray;)V
  0008 return-void 
.end method

.method <init>(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray;)V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 iput-object v1, v0, Lcom/personal/aihub/GameAssets;->root Ljava/io/File;
  000a if-eqz v2, +008h
  000e invoke-virtual v2, Ljava/lang/String;->isEmpty()Z
  0014 move-result v1
  0016 if-eqz v1, +003h
  001a const/4 v2, 0
  001c iput-object v2, v0, Lcom/personal/aihub/GameAssets;->preferredKey Ljava/lang/String;
  0020 iput-object v3, v0, Lcom/personal/aihub/GameAssets;->overlays Lorg/json/JSONArray;
  0024 return-void 
.end method

.method fontFallback(Ljava/lang/String;)Ljava/lang/String;
  0000 const/4 v0, 0
  0002 if-eqz v4, +049h
  0006 const-string v1, "fonts/"
  000a invoke-virtual v4, v1, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0010 move-result v1
  0012 if-eqz v1, +041h
  0016 const-string v1, "fonts/default/"
  001a invoke-virtual v4, v1, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0020 move-result v2
  0022 if-eqz v2, +003h
  0026 goto +37h
  0028 const/16 v2, 46
  002c invoke-virtual v4, v2, Ljava/lang/String;->lastIndexOf(I)I
  0032 move-result v2
  0034 add-int/lit8 v2, v2, 1
  0038 invoke-virtual v4, v2, Ljava/lang/String;->substring(I)Ljava/lang/String;
  003e move-result-object v2
  0040 sget-object v3, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  0044 invoke-virtual v2, v3, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  004a move-result-object v2
  004c const-string v3, "otf"
  0050 invoke-virtual v2, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0056 move-result v3
  0058 if-nez v3, +00ch
  005c const-string v3, "ttf"
  0060 invoke-virtual v2, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0066 move-result v2
  0068 if-eqz v2, +003h
  006c goto +2h
  006e return-object v0
  0070 new-instance v0, Ljava/lang/StringBuilder;
  0074 invoke-direct v0, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  007a const/4 v1, 6
  007c invoke-virtual v4, v1, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0082 move-result-object v4
  0084 invoke-virtual v0, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  008a invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0090 move-result-object v4
  0092 return-object v4
  0094 return-object v0
.end method

.method gamePath(Ljava/lang/String;)Ljava/lang/String;
  0000 const/4 v0, 0
  0002 new-instance v1, Ljava/net/URI;
  0006 invoke-direct v1, v3, Ljava/net/URI;-><init>(Ljava/lang/String;)V
  000c invoke-virtual v1, Ljava/net/URI;->getPath()Ljava/lang/String;
  0012 move-result-object v3
  0014 if-eqz v3, +01bh
  0018 const/16 v2, 92
  001c invoke-virtual v3, v2, Ljava/lang/String;->indexOf(I)I
  0022 move-result v2
  0024 if-gez v2, +012h
  0028 const-string v2, "(^|/)\.{1,2}(/|$)"
  002c invoke-static v2, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;)Ljava/util/regex/Pattern;
  0032 move-result-object v2
  0034 invoke-virtual v2, v3, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  003a move-result-object v3
  003c invoke-virtual v3, Ljava/util/regex/Matcher;->find()Z
  0042 move-result v3
  0044 if-eqz v3, +003h
  0048 return-object v0
  004a new-instance v3, Ljava/net/URI;
  004e const-string v2, "https://dokkan-eclipse.com"
  0052 invoke-direct v3, v2, Ljava/net/URI;-><init>(Ljava/lang/String;)V
  0058 invoke-virtual v3, v1, Ljava/net/URI;->resolve(Ljava/net/URI;)Ljava/net/URI;
  005e move-result-object v3
  0060 const-string v1, "https"
  0064 invoke-virtual v3, Ljava/net/URI;->getScheme()Ljava/lang/String;
  006a move-result-object v2
  006c invoke-virtual v1, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0072 move-result v1
  0074 if-nez v1, +003h
  0078 return-object v0
  007a const-string v1, "dokkan-eclipse.com"
  007e invoke-virtual v3, Ljava/net/URI;->getHost()Ljava/lang/String;
  0084 move-result-object v2
  0086 invoke-virtual v1, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  008c move-result v1
  008e if-nez v1, +00eh
  0092 const-string v1, "cdn.dokkan-eclipse.com"
  0096 invoke-virtual v3, Ljava/net/URI;->getHost()Ljava/lang/String;
  009c move-result-object v2
  009e invoke-virtual v1, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00a4 move-result v1
  00a6 if-eqz v1, +047h
  00aa invoke-virtual v3, Ljava/net/URI;->getUserInfo()Ljava/lang/String;
  00b0 move-result-object v1
  00b2 if-nez v1, +041h
  00b6 invoke-virtual v3, Ljava/net/URI;->getPort()I
  00bc move-result v1
  00be const/4 v2, -1
  00c0 if-ne v1, v2, +03ah
  00c4 invoke-virtual v3, Ljava/net/URI;->getPath()Ljava/lang/String;
  00ca move-result-object v3
  00cc if-nez v3, +003h
  00d0 goto +32h
  00d2 const-string v1, "/cdn/uncompressed/"
  00d6 invoke-virtual v3, v1, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00dc move-result v1
  00de if-eqz v1, +009h
  00e2 const/16 v1, 18
  00e6 invoke-virtual v3, v1, Ljava/lang/String;->substring(I)Ljava/lang/String;
  00ec move-result-object v3
  00ee goto +10h
  00f0 const-string v1, "/assets/"
  00f4 invoke-virtual v3, v1, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00fa move-result v1
  00fc if-nez v1, +003h
  0100 return-object v0
  0102 const/16 v1, 8
  0106 invoke-virtual v3, v1, Ljava/lang/String;->substring(I)Ljava/lang/String;
  010c move-result-object v3
  010e invoke-static v3, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  0114 move-result v1
  0116 if-eqz v1, +00fh
  011a sget-object v1, Lcom/personal/aihub/GameAssets;->PREFIX Ljava/util/regex/Pattern;
  011e invoke-virtual v1, v3, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  0124 move-result-object v1
  0126 invoke-virtual v1, Ljava/util/regex/Matcher;->find()Z
  012c move-result v1
  012e if-eqz v1, +003h
  0132 return-object v3
  0134 return-object v0
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

.method mime(Ljava/lang/String;)Ljava/lang/String;
  0000 const/16 v0, 46
  0004 invoke-virtual v6, v0, Ljava/lang/String;->lastIndexOf(I)I
  000a move-result v0
  000c add-int/lit8 v0, v0, 1
  0010 invoke-virtual v6, v0, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0016 move-result-object v6
  0018 sget-object v0, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  001c invoke-virtual v6, v0, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  0022 move-result-object v6
  0024 invoke-virtual v6, Ljava/lang/String;->hashCode()I
  002a move-result v0
  002c const-string v1, "video/mp4"
  0030 const-string v2, "video/mpeg"
  0034 const-string v3, "image/jpeg"
  0038 const-string v4, "text/plain"
  003c const-string v5, "application/octet-stream"
  0040 sparse-switch v0, +0000102h
  0046 return-object v5
  0048 const-string v0, "webp"
  004c invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0052 move-result v6
  0054 if-nez v6, +003h
  0058 goto +3h
  005a const-string v5, "image/webp"
  005e return-object v5
  0060 const-string v0, "webm"
  0064 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  006a move-result v6
  006c if-nez v6, +003h
  0070 goto +3h
  0072 const-string v5, "video/webm"
  0076 return-object v5
  0078 const-string v0, "json"
  007c invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0082 move-result v6
  0084 if-nez v6, +003h
  0088 goto +3h
  008a const-string v5, "application/json"
  008e return-object v5
  0090 const-string v0, "jpeg"
  0094 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  009a move-result v6
  009c if-nez v6, +003h
  00a0 move-object v3, v5
  00a2 return-object v3
  00a4 const-string v0, "xml"
  00a8 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00ae move-result v6
  00b0 if-nez v6, +003h
  00b4 goto +3h
  00b6 const-string v5, "application/xml"
  00ba return-object v5
  00bc const-string v0, "wav"
  00c0 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00c6 move-result v6
  00c8 if-nez v6, +003h
  00cc goto +3h
  00ce const-string v5, "audio/wav"
  00d2 return-object v5
  00d4 const-string v0, "vsh"
  00d8 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00de move-result v6
  00e0 if-nez v6, +003h
  00e4 move-object v4, v5
  00e6 return-object v4
  00e8 const-string v0, "txt"
  00ec invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00f2 move-result v6
  00f4 if-nez v6, +003h
  00f8 move-object v4, v5
  00fa return-object v4
  00fc const-string v0, "ttf"
  0100 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0106 move-result v6
  0108 if-nez v6, +003h
  010c goto +3h
  010e const-string v5, "font/ttf"
  0112 return-object v5
  0114 const-string v0, "png"
  0118 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  011e move-result v6
  0120 if-nez v6, +003h
  0124 goto +3h
  0126 const-string v5, "image/png"
  012a return-object v5
  012c const-string v0, "otf"
  0130 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0136 move-result v6
  0138 if-nez v6, +003h
  013c goto +3h
  013e const-string v5, "font/otf"
  0142 return-object v5
  0144 const-string v0, "ogg"
  0148 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  014e move-result v6
  0150 if-nez v6, +003h
  0154 goto +3h
  0156 const-string v5, "audio/ogg"
  015a return-object v5
  015c const-string v0, "mp4"
  0160 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0166 move-result v6
  0168 if-nez v6, +003h
  016c move-object v1, v5
  016e return-object v1
  0170 const-string v0, "mp3"
  0174 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  017a move-result v6
  017c if-nez v6, +003h
  0180 goto +3h
  0182 const-string v5, "audio/mpeg"
  0186 return-object v5
  0188 const-string v0, "lua"
  018c invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0192 move-result v6
  0194 if-nez v6, +003h
  0198 move-object v4, v5
  019a return-object v4
  019c const-string v0, "m4v"
  01a0 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01a6 move-result v6
  01a8 if-nez v6, +003h
  01ac move-object v1, v5
  01ae return-object v1
  01b0 const-string v0, "m2v"
  01b4 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01ba move-result v6
  01bc if-nez v6, +003h
  01c0 move-object v2, v5
  01c2 return-object v2
  01c4 const-string v0, "m1v"
  01c8 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01ce move-result v6
  01d0 if-nez v6, +003h
  01d4 move-object v2, v5
  01d6 return-object v2
  01d8 const-string v0, "jpg"
  01dc invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01e2 move-result v6
  01e4 if-nez v6, +003h
  01e8 move-object v3, v5
  01ea return-object v3
  01ec const-string v0, "gif"
  01f0 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01f6 move-result v6
  01f8 if-nez v6, +003h
  01fc goto +3h
  01fe const-string v5, "image/gif"
  0202 return-object v5
  0204 const-string v0, "fsh"
  0208 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  020e move-result v6
  0210 if-nez v6, +003h
  0214 move-object v4, v5
  0216 return-object v4
  0218 const-string v0, "fnt"
  021c invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0222 move-result v6
  0224 if-nez v6, +003h
  0228 move-object v4, v5
  022a return-object v4
  022c const-string v0, "bmp"
  0230 invoke-virtual v6, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0236 move-result v6
  0238 if-nez v6, +003h
  023c goto +3h
  023e const-string v5, "image/bmp"
  0242 return-object v5
  0244 sparse-switch-payload 17d85 18cac 18d3b 18fc4 19be1 19f92 19fb1 19fef 1a3f8 1a6f0 1a6f1 1ad8f 1af21 1b229 1c1e6 1c270 1c94b 1caec 1d017 31e068 31ece8 379f99 379f9c
.end method

.method overlayMap(Lorg/json/JSONArray;)Ljava/util/Map;
  0000 new-instance v0, Ljava/util/LinkedHashMap;
  0004 invoke-direct v0, Ljava/util/LinkedHashMap;-><init>()V
  000a if-nez v8, +003h
  000e return-object v0
  0010 invoke-virtual v8, Lorg/json/JSONArray;->length()I
  0016 move-result v1
  0018 const/16 v2, 2000
  001c if-gt v1, v2, +0b0h
  0020 new-instance v1, Ljava/util/HashSet;
  0024 invoke-direct v1, Ljava/util/HashSet;-><init>()V
  002a const/4 v2, 0
  002c invoke-virtual v8, Lorg/json/JSONArray;->length()I
  0032 move-result v3
  0034 if-ge v2, v3, +0a3h
  0038 invoke-virtual v8, v2, Lorg/json/JSONArray;->optJSONObject(I)Lorg/json/JSONObject;
  003e move-result-object v3
  0040 const-string v4, ""
  0044 if-nez v3, +004h
  0048 move-object v5, v4
  004a goto +7h
  004c const-string v5, "path"
  0050 invoke-virtual v3, v5, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0056 move-result-object v5
  0058 if-eqz v3, +008h
  005c const-string v4, "key"
  0060 invoke-virtual v3, v4, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0066 move-result-object v4
  0068 new-instance v3, Ljava/lang/StringBuilder;
  006c const-string v6, "/assets/"
  0070 invoke-direct v3, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0076 invoke-virtual v3, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  007c invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0082 move-result-object v3
  0084 invoke-static v3, Lcom/personal/aihub/GameAssets;->gamePath(Ljava/lang/String;)Ljava/lang/String;
  008a move-result-object v3
  008c invoke-virtual v5, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0092 move-result v3
  0094 if-eqz v3, +06bh
  0098 invoke-static v4, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  009e move-result v3
  00a0 if-eqz v3, +065h
  00a4 const-string v3, "/"
  00a8 invoke-virtual v4, v3, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  00ae move-result-object v3
  00b0 array-length v3, v3
  00b2 const/4 v6, 2
  00b4 if-lt v3, v6, +05bh
  00b8 const/16 v3, 46
  00bc invoke-virtual v5, v3, Ljava/lang/String;->lastIndexOf(I)I
  00c2 move-result v6
  00c4 add-int/lit8 v6, v6, 1
  00c8 invoke-virtual v5, v6, Ljava/lang/String;->substring(I)Ljava/lang/String;
  00ce move-result-object v6
  00d0 sget-object v7, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  00d4 invoke-virtual v6, v7, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  00da move-result-object v6
  00dc invoke-virtual v4, v3, Ljava/lang/String;->lastIndexOf(I)I
  00e2 move-result v3
  00e4 add-int/lit8 v3, v3, 1
  00e8 invoke-virtual v4, v3, Ljava/lang/String;->substring(I)Ljava/lang/String;
  00ee move-result-object v3
  00f0 sget-object v7, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  00f4 invoke-virtual v3, v7, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  00fa move-result-object v3
  00fc const-string v7, "png|jpe?g|webp|gif|bmp|lwf|lua|usm|cpk|kks|ogg|mp3|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|fsh|vsh|fnt|ttf|otf|strings|txt|bin"
  0100 invoke-virtual v6, v7, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0106 move-result v7
  0108 if-eqz v7, +029h
  010c invoke-virtual v6, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0112 move-result v3
  0114 if-eqz v3, +023h
  0118 sget-object v3, Ljava/text/Normalizer$Form;->NFC Ljava/text/Normalizer$Form;
  011c invoke-static v5, v3, Ljava/text/Normalizer;->normalize(Ljava/lang/CharSequence; Ljava/text/Normalizer$Form;)Ljava/lang/String;
  0122 move-result-object v3
  0124 sget-object v6, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  0128 invoke-virtual v3, v6, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  012e move-result-object v3
  0130 invoke-virtual v1, v3, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  0136 move-result v3
  0138 if-eqz v3, +009h
  013c invoke-virtual v0, v5, v4, Ljava/util/LinkedHashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0142 add-int/lit8 v2, v2, 1
  0146 goto/16 -08dh
  014a new-instance v8, Ljava/io/IOException;
  014e const-string v0, "Conflicting preview asset aliases"
  0152 invoke-direct v8, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0158 throw v8
  015a new-instance v8, Ljava/io/IOException;
  015e const-string v0, "Preview aliases need matching supported resource types"
  0162 invoke-direct v8, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0168 throw v8
  016a new-instance v8, Ljava/io/IOException;
  016e const-string v0, "Invalid preview asset alias"
  0172 invoke-direct v8, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0178 throw v8
  017a return-object v0
  017c new-instance v8, Ljava/io/IOException;
  0180 const-string v0, "Invalid preview asset manifest"
  0184 invoke-direct v8, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  018a throw v8
.end method

.method preferredPath(Ljava/lang/String;)Ljava/lang/String;
  0000 invoke-static v5, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  0006 move-result v0
  0008 const-string v1, "Invalid selected game asset"
  000c if-eqz v0, +06dh
  0010 new-instance v0, Ljava/util/ArrayList;
  0014 const-string v2, "/"
  0018 invoke-virtual v5, v2, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  001e move-result-object v5
  0020 invoke-static v5, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  0026 move-result-object v5
  0028 invoke-direct v0, v5, Ljava/util/ArrayList;-><init>(Ljava/util/Collection;)V
  002e invoke-virtual v0, Ljava/util/ArrayList;->size()I
  0034 move-result v5
  0036 const/4 v3, 2
  0038 if-lt v5, v3, +051h
  003c const/4 v5, 0
  003e invoke-virtual v0, v5, Ljava/util/ArrayList;->remove(I)Ljava/lang/Object;
  0044 invoke-virtual v0, Ljava/util/ArrayList;->isEmpty()Z
  004a move-result v3
  004c if-nez v3, +013h
  0050 invoke-virtual v0, v5, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;
  0056 move-result-object v3
  0058 check-cast v3, Ljava/lang/String;
  005c const-string v4, "files"
  0060 invoke-virtual v3, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0066 move-result v3
  0068 if-eqz v3, +005h
  006c invoke-virtual v0, v5, Ljava/util/ArrayList;->remove(I)Ljava/lang/Object;
  0072 invoke-virtual v0, Ljava/util/ArrayList;->isEmpty()Z
  0078 move-result v3
  007a if-nez v3, +013h
  007e invoke-virtual v0, v5, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;
  0084 move-result-object v3
  0086 check-cast v3, Ljava/lang/String;
  008a const-string v4, "tutorial0"
  008e invoke-virtual v3, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0094 move-result v3
  0096 if-eqz v3, +005h
  009a invoke-virtual v0, v5, Ljava/util/ArrayList;->remove(I)Ljava/lang/Object;
  00a0 invoke-static v2, v0, Ljava/lang/String;->join(Ljava/lang/CharSequence; Ljava/lang/Iterable;)Ljava/lang/String;
  00a6 move-result-object v5
  00a8 invoke-static v5, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  00ae move-result v0
  00b0 if-eqz v0, +00fh
  00b4 sget-object v0, Lcom/personal/aihub/GameAssets;->PREFIX Ljava/util/regex/Pattern;
  00b8 invoke-virtual v0, v5, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  00be move-result-object v0
  00c0 invoke-virtual v0, Ljava/util/regex/Matcher;->find()Z
  00c6 move-result v0
  00c8 if-eqz v0, +003h
  00cc return-object v5
  00ce new-instance v5, Ljava/io/IOException;
  00d2 invoke-direct v5, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00d8 throw v5
  00da new-instance v5, Ljava/io/IOException;
  00de invoke-direct v5, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00e4 throw v5
  00e6 new-instance v5, Ljava/io/IOException;
  00ea invoke-direct v5, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00f0 throw v5
.end method

.method regular(Ljava/lang/String;)Ljava/io/File;
  0000 iget-object v0, v7, Lcom/personal/aihub/GameAssets;->root Ljava/io/File;
  0004 invoke-virtual v0, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  000a move-result-object v0
  000c iget-object v1, v7, Lcom/personal/aihub/GameAssets;->root Ljava/io/File;
  0010 const-string v2, "/"
  0014 invoke-virtual v8, v2, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  001a move-result-object v8
  001c array-length v2, v8
  001e const/4 v3, 0
  0020 const/4 v4, 0
  0022 if-ge v3, v2, +026h
  0026 new-instance v5, Ljava/io/File;
  002a aget-object v6, v8, v3
  002e invoke-direct v5, v1, v6, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0034 invoke-virtual v5, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  003a move-result-object v1
  003c invoke-static v1, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  0042 move-result v1
  0044 if-nez v1, +00dh
  0048 invoke-virtual v5, Ljava/io/File;->exists()Z
  004e move-result v1
  0050 if-nez v1, +003h
  0054 return-object v4
  0056 add-int/lit8 v3, v3, 1
  005a move-object v1, v5
  005c goto -1eh
  005e new-instance v8, Ljava/io/IOException;
  0062 const-string v0, "Imported game assets cannot use symbolic links"
  0066 invoke-direct v8, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  006c throw v8
  006e invoke-virtual v1, Ljava/io/File;->isFile()Z
  0074 move-result v8
  0076 if-nez v8, +003h
  007a return-object v4
  007c invoke-virtual v1, Ljava/io/File;->length()J
  0082 move-result-wide v2
  0084 const-wide/32 v4, 167772160
  008a cmp-long v8, v2, v4
  008e if-gtz v8, +02eh
  0092 invoke-virtual v1, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  0098 move-result-object v8
  009a invoke-virtual v8, Ljava/io/File;->getPath()Ljava/lang/String;
  00a0 move-result-object v1
  00a2 new-instance v2, Ljava/lang/StringBuilder;
  00a6 invoke-direct v2, Ljava/lang/StringBuilder;-><init>()V
  00ac invoke-static v0, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  00b2 move-result-object v0
  00b4 invoke-virtual v2, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00ba sget-object v0, Ljava/io/File;->separator Ljava/lang/String;
  00be invoke-virtual v2, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00c4 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00ca move-result-object v0
  00cc invoke-virtual v1, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00d2 move-result v0
  00d4 if-eqz v0, +003h
  00d8 return-object v8
  00da new-instance v8, Ljava/io/IOException;
  00de const-string v0, "Imported game asset escapes its resource folder"
  00e2 invoke-direct v8, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00e8 throw v8
  00ea new-instance v8, Ljava/io/IOException;
  00ee const-string v0, "Imported game asset exceeds the 160 MB preview limit"
  00f2 invoke-direct v8, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00f8 throw v8
.end method

.method safe(Ljava/lang/String;)Z
  0000 const/4 v0, 0
  0002 if-eqz v7, +082h
  0006 invoke-virtual v7, Ljava/lang/String;->isEmpty()Z
  000c move-result v1
  000e if-nez v1, +07ch
  0012 invoke-virtual v7, Ljava/lang/String;->length()I
  0018 move-result v1
  001a const/16 v2, 500
  001e if-gt v1, v2, +074h
  0022 const-string v1, "/"
  0026 invoke-virtual v7, v1, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  002c move-result v2
  002e if-nez v2, +06ch
  0032 invoke-virtual v7, Ljava/lang/String;->toCharArray()[C
  0038 move-result-object v2
  003a array-length v3, v2
  003c move v4, v0
  003e if-ge v4, v3, +01dh
  0042 aget-char v5, v2, v4
  0046 const/16 v6, 92
  004a if-eq v5, v6, +016h
  004e const/16 v6, 58
  0052 if-eq v5, v6, +012h
  0056 const/16 v6, 37
  005a if-eq v5, v6, +00eh
  005e const/16 v6, 32
  0062 if-lt v5, v6, +00ah
  0066 const/16 v6, 127
  006a if-ne v5, v6, +003h
  006e goto +4h
  0070 add-int/lit8 v4, v4, 1
  0074 goto -1bh
  0076 return v0
  0078 const/4 v2, -1
  007a invoke-virtual v7, v1, v2, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  0080 move-result-object v1
  0082 array-length v2, v1
  0084 move v3, v0
  0086 if-ge v3, v2, +033h
  008a aget-object v4, v1, v3
  008e invoke-virtual v4, Ljava/lang/String;->isEmpty()Z
  0094 move-result v5
  0096 if-nez v5, +02ah
  009a const-string v5, "."
  009e invoke-virtual v4, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00a4 move-result v6
  00a6 if-nez v6, +022h
  00aa const-string v6, ".."
  00ae invoke-virtual v4, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00b4 move-result v6
  00b6 if-nez v6, +01ah
  00ba invoke-virtual v4, v5, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00c0 move-result v5
  00c2 if-nez v5, +014h
  00c6 sget-object v5, Lcom/personal/aihub/GameAssets;->PRIVATE Ljava/util/Set;
  00ca sget-object v6, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  00ce invoke-virtual v4, v6, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  00d4 move-result-object v4
  00d6 invoke-interface v5, v4, Ljava/util/Set;->contains(Ljava/lang/Object;)Z
  00dc move-result v4
  00de if-eqz v4, +003h
  00e2 goto +4h
  00e4 add-int/lit8 v3, v3, 1
  00e8 goto -31h
  00ea return v0
  00ec sget-object v0, Lcom/personal/aihub/GameAssets;->DATABASE Ljava/util/regex/Pattern;
  00f0 invoke-virtual v0, v7, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  00f6 move-result-object v7
  00f8 invoke-virtual v7, Ljava/util/regex/Matcher;->matches()Z
  00fe move-result v7
  0100 xor-int/lit8 v7, v7, 1
  0104 return v7
  0106 return v0
.end method

.method read(Ljava/lang/String; I)[B
  0000 invoke-static v7, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  0006 move-result v0
  0008 if-eqz v0, +080h
  000c sget-object v0, Lcom/personal/aihub/GameAssets;->PREFIX Ljava/util/regex/Pattern;
  0010 invoke-virtual v0, v7, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  0016 move-result-object v0
  0018 invoke-virtual v0, Ljava/util/regex/Matcher;->find()Z
  001e move-result v0
  0020 if-eqz v0, +074h
  0024 new-instance v0, Ljava/lang/StringBuilder;
  0028 const-string v1, "/assets/"
  002c invoke-direct v0, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0032 invoke-virtual v0, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0038 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  003e move-result-object v7
  0040 invoke-virtual v6, v7, Lcom/personal/aihub/GameAssets;->resolve(Ljava/lang/String;)Ljava/io/File;
  0046 move-result-object v7
  0048 if-nez v7, +004h
  004c const/4 v7, 0
  004e return-object v7
  0050 if-ltz v8, +054h
  0054 const/high16 v0, 167772160
  0058 if-gt v8, v0, +050h
  005c invoke-virtual v7, Ljava/io/File;->length()J
  0062 move-result-wide v0
  0064 int-to-long v2, v8
  0066 cmp-long v0, v0, v2
  006a if-gtz v0, +047h
  006e new-instance v0, Ljava/io/FileInputStream;
  0072 invoke-direct v0, v7, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0078 new-instance v7, Ljava/io/ByteArrayOutputStream;
  007c invoke-direct v7, Ljava/io/ByteArrayOutputStream;-><init>()V
  0082 const/high16 v1, 65536
  0086 new-array v1, v1, [B
  008a const/4 v2, 0
  008c move v3, v2
  008e invoke-virtual v0, v1, Ljava/io/FileInputStream;->read([B)I
  0094 move-result v4
  0096 const/4 v5, -1
  0098 if-eq v4, v5, +011h
  009c add-int/2addr v3, v4
  009e if-gt v3, v8, +006h
  00a2 invoke-virtual v7, v1, v2, v4, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  00a8 goto -dh
  00aa new-instance v8, Ljava/io/IOException;
  00ae const-string v1, "Imported game asset changed or exceeds the supported size"
  00b2 invoke-direct v8, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00b8 throw v8
  00ba invoke-virtual v7, Ljava/io/ByteArrayOutputStream;->toByteArray()[B
  00c0 move-result-object v8
  00c2 invoke-virtual v7, Ljava/io/ByteArrayOutputStream;->close()V
  00c8 invoke-virtual v0, Ljava/io/FileInputStream;->close()V
  00ce return-object v8
  00d0 move-exception v8
  00d2 invoke-virtual v7, Ljava/io/ByteArrayOutputStream;->close()V
  00d8 goto +5h
  00da move-exception v7
  00dc invoke-virtual v8, v7, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  00e2 throw v8
  00e4 move-exception v7
  00e6 invoke-virtual v0, Ljava/io/FileInputStream;->close()V
  00ec goto +5h
  00ee move-exception v8
  00f0 invoke-virtual v7, v8, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  00f6 throw v7
  00f8 new-instance v7, Ljava/io/IOException;
  00fc const-string v8, "Imported game asset exceeds the supported size"
  0100 invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0106 throw v7
  0108 new-instance v7, Ljava/io/IOException;
  010c const-string v8, "Invalid game asset path"
  0110 invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0116 throw v7
.end method

.method resolve(Ljava/lang/String;)Ljava/io/File;
  0000 invoke-static v13, Lcom/personal/aihub/GameAssets;->gamePath(Ljava/lang/String;)Ljava/lang/String;
  0006 move-result-object v13
  0008 const/4 v0, 0
  000a if-nez v13, +003h
  000e return-object v0
  0010 iget-object v1, v12, Lcom/personal/aihub/GameAssets;->overlays Lorg/json/JSONArray;
  0014 invoke-static v1, Lcom/personal/aihub/GameAssets;->overlayMap(Lorg/json/JSONArray;)Ljava/util/Map;
  001a move-result-object v1
  001c invoke-interface v1, v13, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0022 move-result-object v2
  0024 check-cast v2, Ljava/lang/String;
  0028 const-string v3, "/"
  002c const/4 v4, 0
  002e if-nez v2, +080h
  0032 invoke-interface v1, Ljava/util/Map;->entrySet()Ljava/util/Set;
  0038 move-result-object v1
  003a invoke-interface v1, Ljava/util/Set;->iterator()Ljava/util/Iterator;
  0040 move-result-object v1
  0042 const/4 v5, -1
  0044 invoke-interface v1, Ljava/util/Iterator;->hasNext()Z
  004a move-result v6
  004c if-eqz v6, +071h
  0050 invoke-interface v1, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0056 move-result-object v6
  0058 check-cast v6, Ljava/util/Map$Entry;
  005c invoke-interface v6, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;
  0062 move-result-object v7
  0064 check-cast v7, Ljava/lang/String;
  0068 invoke-interface v6, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;
  006e move-result-object v6
  0070 check-cast v6, Ljava/lang/String;
  0074 const-string v8, ".cpk"
  0078 invoke-virtual v7, v8, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  007e move-result v9
  0080 if-eqz v9, -01eh
  0084 invoke-virtual v6, v8, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  008a move-result v8
  008c if-nez v8, +003h
  0090 goto -26h
  0092 new-instance v8, Ljava/lang/StringBuilder;
  0096 invoke-direct v8, Ljava/lang/StringBuilder;-><init>()V
  009c invoke-virtual v7, Ljava/lang/String;->length()I
  00a2 move-result v9
  00a4 add-int/lit8 v9, v9, -4
  00a8 invoke-virtual v7, v4, v9, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  00ae move-result-object v7
  00b0 invoke-virtual v8, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00b6 invoke-virtual v8, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00bc invoke-virtual v8, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00c2 move-result-object v7
  00c4 invoke-virtual v13, v7, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00ca move-result v8
  00cc if-eqz v8, -044h
  00d0 invoke-virtual v7, Ljava/lang/String;->length()I
  00d6 move-result v8
  00d8 if-le v8, v5, -04ah
  00dc new-instance v2, Ljava/lang/StringBuilder;
  00e0 invoke-direct v2, Ljava/lang/StringBuilder;-><init>()V
  00e6 invoke-virtual v6, Ljava/lang/String;->length()I
  00ec move-result v5
  00ee add-int/lit8 v5, v5, -4
  00f2 invoke-virtual v6, v4, v5, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  00f8 move-result-object v5
  00fa invoke-virtual v2, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0100 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0106 invoke-virtual v7, Ljava/lang/String;->length()I
  010c move-result v5
  010e invoke-virtual v13, v5, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0114 move-result-object v5
  0116 invoke-virtual v2, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  011c invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0122 move-result-object v2
  0124 invoke-virtual v7, Ljava/lang/String;->length()I
  012a move-result v5
  012c goto -74h
  012e if-nez v2, +023h
  0132 iget-object v1, v12, Lcom/personal/aihub/GameAssets;->preferredKey Ljava/lang/String;
  0136 if-eqz v1, +01dh
  013a invoke-static v1, Lcom/personal/aihub/GameAssets;->preferredPath(Ljava/lang/String;)Ljava/lang/String;
  0140 move-result-object v1
  0142 invoke-virtual v1, v13, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0148 move-result v1
  014a if-nez v1, +015h
  014e iget-object v1, v12, Lcom/personal/aihub/GameAssets;->preferredKey Ljava/lang/String;
  0152 invoke-static v1, Lcom/personal/aihub/GameAssets;->preferredPath(Ljava/lang/String;)Ljava/lang/String;
  0158 move-result-object v1
  015a invoke-static v13, Lcom/personal/aihub/GameAssets;->fontFallback(Ljava/lang/String;)Ljava/lang/String;
  0160 move-result-object v5
  0162 invoke-virtual v1, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0168 move-result v1
  016a if-eqz v1, +003h
  016e goto +3h
  0170 move v1, v4
  0172 goto +2h
  0174 const/4 v1, 1
  0176 iget-object v5, v12, Lcom/personal/aihub/GameAssets;->root Ljava/io/File;
  017a invoke-virtual v5, Ljava/io/File;->exists()Z
  0180 move-result v5
  0182 const-string v6, "The selected imported asset is unavailable. Choose it again."
  0186 if-nez v5, +00bh
  018a if-nez v1, +003h
  018e return-object v0
  0190 new-instance v13, Ljava/io/IOException;
  0194 invoke-direct v13, v6, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  019a throw v13
  019c iget-object v5, v12, Lcom/personal/aihub/GameAssets;->root Ljava/io/File;
  01a0 invoke-virtual v5, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  01a6 move-result-object v5
  01a8 invoke-static v5, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  01ae move-result v5
  01b0 if-nez v5, +147h
  01b4 iget-object v5, v12, Lcom/personal/aihub/GameAssets;->root Ljava/io/File;
  01b8 invoke-virtual v5, Ljava/io/File;->isDirectory()Z
  01be move-result v5
  01c0 if-eqz v5, +13fh
  01c4 if-eqz v1, +013h
  01c8 if-nez v2, +004h
  01cc iget-object v2, v12, Lcom/personal/aihub/GameAssets;->preferredKey Ljava/lang/String;
  01d0 invoke-direct v12, v2, Lcom/personal/aihub/GameAssets;->regular(Ljava/lang/String;)Ljava/io/File;
  01d6 move-result-object v13
  01d8 if-eqz v13, +003h
  01dc return-object v13
  01de new-instance v13, Ljava/io/IOException;
  01e2 invoke-direct v13, v6, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01e8 throw v13
  01ea iget-object v1, v12, Lcom/personal/aihub/GameAssets;->root Ljava/io/File;
  01ee invoke-virtual v1, Ljava/io/File;->listFiles()[Ljava/io/File;
  01f4 move-result-object v1
  01f6 if-nez v1, +003h
  01fa return-object v0
  01fc new-instance v2, Ljava/util/ArrayList;
  0200 invoke-direct v2, Ljava/util/ArrayList;-><init>()V
  0206 array-length v5, v1
  0208 move v6, v4
  020a if-ge v6, v5, +024h
  020e aget-object v7, v1, v6
  0212 invoke-virtual v7, Ljava/io/File;->getName()Ljava/lang/String;
  0218 move-result-object v8
  021a invoke-static v8, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  0220 move-result v8
  0222 if-eqz v8, +015h
  0226 invoke-virtual v7, Ljava/io/File;->isDirectory()Z
  022c move-result v8
  022e if-eqz v8, +00fh
  0232 invoke-virtual v7, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0238 move-result-object v8
  023a invoke-static v8, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  0240 move-result v8
  0242 if-nez v8, +005h
  0246 invoke-virtual v2, v7, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  024c add-int/lit8 v6, v6, 1
  0250 goto -23h
  0252 new-instance v1, Lcom/personal/aihub/GameAssets$1;
  0256 invoke-direct v1, v12, Lcom/personal/aihub/GameAssets$1;-><init>(Lcom/personal/aihub/GameAssets;)V
  025c invoke-virtual v2, v1, Ljava/util/ArrayList;->sort(Ljava/util/Comparator;)V
  0262 invoke-virtual v2, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
  0268 move-result-object v1
  026a invoke-interface v1, Ljava/util/Iterator;->hasNext()Z
  0270 move-result v5
  0272 const/4 v6, 3
  0274 const-string v7, "/tutorial0/"
  0278 const-string v8, "/files/"
  027c if-eqz v5, +069h
  0280 invoke-interface v1, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0286 move-result-object v5
  0288 check-cast v5, Ljava/io/File;
  028c new-instance v9, Ljava/lang/StringBuilder;
  0290 invoke-direct v9, Ljava/lang/StringBuilder;-><init>()V
  0296 invoke-virtual v5, Ljava/io/File;->getName()Ljava/lang/String;
  029c move-result-object v10
  029e invoke-static v10, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  02a4 move-result-object v10
  02a6 invoke-virtual v9, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02ac invoke-virtual v9, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02b2 invoke-virtual v9, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02b8 invoke-virtual v9, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  02be move-result-object v9
  02c0 new-instance v10, Ljava/lang/StringBuilder;
  02c4 invoke-direct v10, Ljava/lang/StringBuilder;-><init>()V
  02ca invoke-virtual v5, Ljava/io/File;->getName()Ljava/lang/String;
  02d0 move-result-object v11
  02d2 invoke-static v11, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  02d8 move-result-object v11
  02da invoke-virtual v10, v11, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02e0 invoke-virtual v10, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02e6 invoke-virtual v10, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02ec invoke-virtual v10, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  02f2 move-result-object v8
  02f4 new-instance v10, Ljava/lang/StringBuilder;
  02f8 invoke-direct v10, Ljava/lang/StringBuilder;-><init>()V
  02fe invoke-virtual v5, Ljava/io/File;->getName()Ljava/lang/String;
  0304 move-result-object v5
  0306 invoke-static v5, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  030c move-result-object v5
  030e invoke-virtual v10, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0314 invoke-virtual v10, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  031a invoke-virtual v10, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0320 invoke-virtual v10, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0326 move-result-object v5
  0328 filled-new-array v9, v8, v5, [Ljava/lang/String;
  032e move-result-object v5
  0330 move v7, v4
  0332 if-ge v7, v6, -064h
  0336 aget-object v8, v5, v7
  033a invoke-direct v12, v8, Lcom/personal/aihub/GameAssets;->regular(Ljava/lang/String;)Ljava/io/File;
  0340 move-result-object v8
  0342 if-eqz v8, +003h
  0346 return-object v8
  0348 add-int/lit8 v7, v7, 1
  034c goto -dh
  034e invoke-static v13, Lcom/personal/aihub/GameAssets;->fontFallback(Ljava/lang/String;)Ljava/lang/String;
  0354 move-result-object v13
  0356 if-eqz v13, +073h
  035a invoke-virtual v2, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
  0360 move-result-object v1
  0362 invoke-interface v1, Ljava/util/Iterator;->hasNext()Z
  0368 move-result v2
  036a if-eqz v2, +069h
  036e invoke-interface v1, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0374 move-result-object v2
  0376 check-cast v2, Ljava/io/File;
  037a new-instance v5, Ljava/lang/StringBuilder;
  037e invoke-direct v5, Ljava/lang/StringBuilder;-><init>()V
  0384 invoke-virtual v2, Ljava/io/File;->getName()Ljava/lang/String;
  038a move-result-object v9
  038c invoke-static v9, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0392 move-result-object v9
  0394 invoke-virtual v5, v9, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  039a invoke-virtual v5, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  03a0 invoke-virtual v5, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  03a6 invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  03ac move-result-object v5
  03ae new-instance v9, Ljava/lang/StringBuilder;
  03b2 invoke-direct v9, Ljava/lang/StringBuilder;-><init>()V
  03b8 invoke-virtual v2, Ljava/io/File;->getName()Ljava/lang/String;
  03be move-result-object v10
  03c0 invoke-static v10, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  03c6 move-result-object v10
  03c8 invoke-virtual v9, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  03ce invoke-virtual v9, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  03d4 invoke-virtual v9, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  03da invoke-virtual v9, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  03e0 move-result-object v9
  03e2 new-instance v10, Ljava/lang/StringBuilder;
  03e6 invoke-direct v10, Ljava/lang/StringBuilder;-><init>()V
  03ec invoke-virtual v2, Ljava/io/File;->getName()Ljava/lang/String;
  03f2 move-result-object v2
  03f4 invoke-static v2, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  03fa move-result-object v2
  03fc invoke-virtual v10, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0402 invoke-virtual v10, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0408 invoke-virtual v10, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  040e invoke-virtual v10, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0414 move-result-object v2
  0416 filled-new-array v5, v9, v2, [Ljava/lang/String;
  041c move-result-object v2
  041e move v5, v4
  0420 if-ge v5, v6, -05fh
  0424 aget-object v9, v2, v5
  0428 invoke-direct v12, v9, Lcom/personal/aihub/GameAssets;->regular(Ljava/lang/String;)Ljava/io/File;
  042e move-result-object v9
  0430 if-eqz v9, +003h
  0434 return-object v9
  0436 add-int/lit8 v5, v5, 1
  043a goto -dh
  043c return-object v0
  043e new-instance v13, Ljava/io/IOException;
  0442 const-string v0, "Invalid imported resource folder"
  0446 invoke-direct v13, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  044c throw v13
.end method

.method response(Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;
  0000 const-string v0, "Content-Range"
  0004 invoke-interface/range v22, Landroid/webkit/WebResourceRequest;->getUrl()Landroid/net/Uri;
  000a move-result-object v1
  000c invoke-virtual v1, Landroid/net/Uri;->toString()Ljava/lang/String;
  0012 move-result-object v1
  0014 move-object/from16 v2, v21
  0018 invoke-virtual v2, v1, Lcom/personal/aihub/GameAssets;->resolve(Ljava/lang/String;)Ljava/io/File;
  001e move-result-object v1
  0020 const/4 v3, 0
  0022 if-nez v1, +003h
  0026 return-object v3
  0028 invoke-interface/range v22, Landroid/webkit/WebResourceRequest;->getMethod()Ljava/lang/String;
  002e move-result-object v4
  0030 new-instance v10, Ljava/util/HashMap;
  0034 invoke-direct v10, Ljava/util/HashMap;-><init>()V
  003a const-string v5, "Accept-Ranges"
  003e const-string v6, "bytes"
  0042 invoke-interface v10, v5, v6, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0048 const-string v5, "Cache-Control"
  004c const-string v6, "no-store"
  0050 invoke-interface v10, v5, v6, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0056 const-string v5, "Cross-Origin-Resource-Policy"
  005a const-string v6, "same-origin"
  005e invoke-interface v10, v5, v6, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0064 invoke-virtual v1, Ljava/io/File;->length()J
  006a move-result-wide v5
  006c const-wide/16 v7, 1
  0070 sub-long v11, v5, v7
  0074 const-string v9, "GET"
  0078 invoke-virtual v4, v9, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  007e move-result v9
  0080 const-string v13, "0"
  0084 const-string v14, "HEAD"
  0088 const/4 v15, 0
  008a const-string v3, "Content-Length"
  008e if-nez v9, +021h
  0092 invoke-virtual v4, v14, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0098 move-result v9
  009a if-nez v9, +01bh
  009e invoke-interface v10, v3, v13, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  00a4 new-instance v0, Landroid/webkit/WebResourceResponse;
  00a8 new-instance v11, Ljava/io/ByteArrayInputStream;
  00ac new-array v1, v15, [B
  00b0 invoke-direct v11, v1, Ljava/io/ByteArrayInputStream;-><init>([B)V
  00b6 const-string v6, "text/plain"
  00ba const-string v7, "UTF-8"
  00be const/16 v8, 405
  00c2 const-string v9, "Method Not Allowed"
  00c6 move-object v5, v0
  00c8 invoke-direct/range v5 ... v11, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String; Ljava/lang/String; I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)V
  00ce return-object v0
  00d0 invoke-interface/range v22, Landroid/webkit/WebResourceRequest;->getRequestHeaders()Ljava/util/Map;
  00d6 move-result-object v9
  00d8 invoke-interface v9, Ljava/util/Map;->entrySet()Ljava/util/Set;
  00de move-result-object v9
  00e0 invoke-interface v9, Ljava/util/Set;->iterator()Ljava/util/Iterator;
  00e6 move-result-object v9
  00e8 const/4 v7, 0
  00ea invoke-interface v9, Ljava/util/Iterator;->hasNext()Z
  00f0 move-result v8
  00f2 if-eqz v8, +023h
  00f6 invoke-interface v9, Ljava/util/Iterator;->next()Ljava/lang/Object;
  00fc move-result-object v8
  00fe check-cast v8, Ljava/util/Map$Entry;
  0102 invoke-interface v8, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;
  0108 move-result-object v18
  010a move-object/from16 v15, v18
  010e check-cast v15, Ljava/lang/String;
  0112 const-string v2, "Range"
  0116 invoke-virtual v15, v2, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z
  011c move-result v2
  011e if-eqz v2, +009h
  0122 invoke-interface v8, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;
  0128 move-result-object v2
  012a move-object v7, v2
  012c check-cast v7, Ljava/lang/String;
  0130 move-object/from16 v2, v21
  0134 const/4 v15, 0
  0136 goto -26h
  0138 const-wide/16 v8, 0
  013c if-eqz v7, +0c5h
  0140 const-string v15, "^bytes=(\d*)-(\d*)$"
  0144 invoke-static v15, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;)Ljava/util/regex/Pattern;
  014a move-result-object v15
  014c invoke-virtual v15, v7, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  0152 move-result-object v7
  0154 invoke-virtual v7, Ljava/util/regex/Matcher;->matches()Z
  015a move-result v15
  015c if-eqz v15, +084h
  0160 const/4 v15, 1
  0162 invoke-virtual v7, v15, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  0168 move-result-object v18
  016a invoke-virtual/range v18, Ljava/lang/String;->isEmpty()Z
  0170 move-result v18
  0172 const/4 v2, 2
  0174 if-eqz v18, +021h
  0178 invoke-virtual v7, v2, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  017e move-result-object v2
  0180 invoke-static v2, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  0186 move-result-wide v19
  0188 cmp-long v2, v19, v8
  018c if-lez v2, +00fh
  0190 cmp-long v2, v5, v8
  0194 if-lez v2, +00bh
  0198 move-object/from16 v18, v1
  019c sub-long v1, v5, v19
  01a0 invoke-static v8, v9, v1, v2, Ljava/lang/Math;->max(J J)J
  01a6 move-result-wide v1
  01a8 goto +32h
  01aa new-instance v1, Ljava/lang/NumberFormatException;
  01ae invoke-direct v1, Ljava/lang/NumberFormatException;-><init>()V
  01b4 throw v1
  01b6 move-object/from16 v18, v1
  01ba invoke-virtual v7, v15, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  01c0 move-result-object v1
  01c2 invoke-static v1, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  01c8 move-result-wide v19
  01ca invoke-virtual v7, v2, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  01d0 move-result-object v1
  01d2 invoke-virtual v1, Ljava/lang/String;->isEmpty()Z
  01d8 move-result v1
  01da if-nez v1, +00fh
  01de invoke-virtual v7, v2, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  01e4 move-result-object v1
  01e6 invoke-static v1, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  01ec move-result-wide v1
  01ee invoke-static v11, v12, v1, v2, Ljava/lang/Math;->min(J J)J
  01f4 move-result-wide v1
  01f6 move-wide v11, v1
  01f8 cmp-long v1, v19, v5
  01fc if-gez v1, +02eh
  0200 cmp-long v1, v11, v19
  0204 if-ltz v1, +02ah
  0208 move-wide/from16 v1, v19
  020c new-instance v7, Ljava/lang/StringBuilder;
  0210 const-string v13, "bytes "
  0214 invoke-direct v7, v13, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  021a invoke-virtual v7, v1, v2, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0220 const-string v13, "-"
  0224 invoke-virtual v7, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  022a invoke-virtual v7, v11, v12, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0230 const-string v13, "/"
  0234 invoke-virtual v7, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  023a invoke-virtual v7, v5, v6, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0240 invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0246 move-result-object v5
  0248 invoke-interface v10, v0, v5, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  024e move-wide v5, v1
  0250 const/16 v0, 206
  0254 const/4 v1, 0
  0256 goto +3eh
  0258 new-instance v1, Ljava/lang/NumberFormatException;
  025c invoke-direct v1, Ljava/lang/NumberFormatException;-><init>()V
  0262 throw v1
  0264 new-instance v1, Ljava/lang/NumberFormatException;
  0268 invoke-direct v1, Ljava/lang/NumberFormatException;-><init>()V
  026e throw v1
  0270 new-instance v1, Ljava/lang/StringBuilder;
  0274 const-string v2, "bytes */"
  0278 invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  027e invoke-virtual v1, v5, v6, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0284 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  028a move-result-object v1
  028c invoke-interface v10, v0, v1, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0292 invoke-interface v10, v3, v13, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0298 new-instance v0, Landroid/webkit/WebResourceResponse;
  029c new-instance v11, Ljava/io/ByteArrayInputStream;
  02a0 const/4 v1, 0
  02a2 new-array v1, v1, [B
  02a6 invoke-direct v11, v1, Ljava/io/ByteArrayInputStream;-><init>([B)V
  02ac const-string v6, "text/plain"
  02b0 const-string v7, "UTF-8"
  02b4 const/16 v8, 416
  02b8 const-string v9, "Range Not Satisfiable"
  02bc move-object v5, v0
  02be invoke-direct/range v5 ... v11, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String; Ljava/lang/String; I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)V
  02c4 return-object v0
  02c6 move-object/from16 v18, v1
  02ca const/4 v1, 0
  02cc const/16 v0, 200
  02d0 move-wide v5, v8
  02d2 sub-long/2addr v11, v5
  02d4 const-wide/16 v16, 1
  02d8 add-long v11, v11, v16
  02dc invoke-static v8, v9, v11, v12, Ljava/lang/Math;->max(J J)J
  02e2 move-result-wide v7
  02e4 long-to-int v2, v7
  02e6 invoke-static v2, Ljava/lang/Integer;->toString(I)Ljava/lang/String;
  02ec move-result-object v7
  02ee invoke-interface v10, v3, v7, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  02f4 invoke-virtual v4, v14, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  02fa move-result v3
  02fc if-eqz v3, +004h
  0300 move v15, v1
  0302 goto +2h
  0304 move v15, v2
  0306 new-array v1, v15, [B
  030a if-lez v15, +021h
  030e new-instance v2, Ljava/io/RandomAccessFile;
  0312 const-string v3, "r"
  0316 move-object/from16 v4, v18
  031a invoke-direct v2, v4, v3, Ljava/io/RandomAccessFile;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0320 invoke-virtual v2, v5, v6, Ljava/io/RandomAccessFile;->seek(J)V
  0326 invoke-virtual v2, v1, Ljava/io/RandomAccessFile;->readFully([B)V
  032c invoke-virtual v2, Ljava/io/RandomAccessFile;->close()V
  0332 goto +fh
  0334 move-exception v0
  0336 move-object v1, v0
  0338 invoke-virtual v2, Ljava/io/RandomAccessFile;->close()V
  033e goto +6h
  0340 move-exception v0
  0342 move-object v2, v0
  0344 invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  034a throw v1
  034c move-object/from16 v4, v18
  0350 invoke-virtual v4, Ljava/io/File;->getName()Ljava/lang/String;
  0356 move-result-object v2
  0358 invoke-static v2, Lcom/personal/aihub/GameAssets;->mime(Ljava/lang/String;)Ljava/lang/String;
  035e move-result-object v6
  0360 const-string v2, "text/"
  0364 invoke-virtual v6, v2, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  036a move-result v2
  036c if-nez v2, +015h
  0370 const-string v2, "application/json"
  0374 invoke-virtual v6, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  037a move-result v2
  037c if-nez v2, +00dh
  0380 const-string v2, "application/xml"
  0384 invoke-virtual v6, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  038a move-result v2
  038c if-eqz v2, +003h
  0390 goto +3h
  0392 const/4 v7, 0
  0394 goto +4h
  0396 const-string v3, "UTF-8"
  039a move-object v7, v3
  039c new-instance v2, Landroid/webkit/WebResourceResponse;
  03a0 const/16 v3, 206
  03a4 if-ne v0, v3, +005h
  03a8 const-string v3, "Partial Content"
  03ac goto +3h
  03ae const-string v3, "OK"
  03b2 move-object v9, v3
  03b4 new-instance v11, Ljava/io/ByteArrayInputStream;
  03b8 invoke-direct v11, v1, Ljava/io/ByteArrayInputStream;-><init>([B)V
  03be move-object v5, v2
  03c0 move v8, v0
  03c2 invoke-direct/range v5 ... v11, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String; Ljava/lang/String; I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)V
  03c8 return-object v2
.end method