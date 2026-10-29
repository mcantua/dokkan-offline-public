.class Lcom/personal/aihub/AudioBanks;
.super Ljava/lang/Object;
.field ACB_MAX J
.field AWB_MAX J
.field MAX_BANKS I
.field MAX_GROUPS I
.field MAX_SCANNED I
.field cached Lorg/json/JSONObject;
.field closed Z
.field comparedBytes J
.field onlyAliases Z
.field overlays Lorg/json/JSONArray;
.field preferredKey Ljava/lang/String;
.field records Ljava/util/Map;
.field root Ljava/io/File;
.field scanned I

.method <init>(Ljava/io/File;)V
  0000 const/4 v0, 0
  0002 invoke-direct v1, v2, v0, v0, Lcom/personal/aihub/AudioBanks;-><init>(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray;)V
  0008 return-void 
.end method

.method <init>(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray;)V
  0000 const/4 v0, 0
  0002 invoke-direct v1, v2, v3, v4, v0, Lcom/personal/aihub/AudioBanks;-><init>(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray; Z)V
  0008 return-void 
.end method

.method <init>(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray; Z)V
  0000 invoke-direct v1, Ljava/lang/Object;-><init>()V
  0006 new-instance v0, Ljava/util/HashMap;
  000a invoke-direct v0, Ljava/util/HashMap;-><init>()V
  0010 iput-object v0, v1, Lcom/personal/aihub/AudioBanks;->records Ljava/util/Map;
  0014 iput-object v2, v1, Lcom/personal/aihub/AudioBanks;->root Ljava/io/File;
  0018 iput-object v3, v1, Lcom/personal/aihub/AudioBanks;->preferredKey Ljava/lang/String;
  001c iput-object v4, v1, Lcom/personal/aihub/AudioBanks;->overlays Lorg/json/JSONArray;
  0020 iput-boolean v5, v1, Lcom/personal/aihub/AudioBanks;->onlyAliases Z
  0024 return-void 
.end method

.method add(Ljava/util/Map; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Z Z)V
  0000 invoke-static v9, Lcom/personal/aihub/AudioBanks;->identity(Ljava/lang/String;)Lcom/personal/aihub/AudioBanks$Identity;
  0006 move-result-object v9
  0008 if-nez v9, +003h
  000c return-void 
  000e const-wide/32 v0, 33554432
  0014 const/4 v2, 0
  0016 invoke-direct v7, v10, v0, v1, v2, Lcom/personal/aihub/AudioBanks;->checked(Ljava/lang/String; J Z)Ljava/io/File;
  001c move-result-object v0
  001e if-nez v0, +00dh
  0022 if-nez v12, +003h
  0026 return-void 
  0028 new-instance v8, Ljava/io/IOException;
  002c const-string v9, "The selected audio bank is unavailable"
  0030 invoke-direct v8, v9, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0036 throw v8
  0038 const/4 v1, 0
  003a if-eqz v11, +052h
  003e new-instance v3, Ljava/io/File;
  0042 invoke-direct v3, v10, Ljava/io/File;-><init>(Ljava/lang/String;)V
  0048 new-instance v4, Ljava/io/File;
  004c invoke-direct v4, v11, Ljava/io/File;-><init>(Ljava/lang/String;)V
  0052 invoke-virtual v3, Ljava/io/File;->getParent()Ljava/lang/String;
  0058 move-result-object v5
  005a invoke-virtual v4, Ljava/io/File;->getParent()Ljava/lang/String;
  0060 move-result-object v6
  0062 invoke-static v5, v6, Ljava/util/Objects;->equals(Ljava/lang/Object; Ljava/lang/Object;)Z
  0068 move-result v5
  006a if-eqz v5, +032h
  006e invoke-virtual v3, Ljava/io/File;->getName()Ljava/lang/String;
  0074 move-result-object v3
  0076 const-string v5, "(?i)\.acb$"
  007a const-string v6, ""
  007e invoke-virtual v3, v5, v6, Ljava/lang/String;->replaceFirst(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0084 move-result-object v3
  0086 invoke-virtual v4, Ljava/io/File;->getName()Ljava/lang/String;
  008c move-result-object v4
  008e const-string v5, "(?i)\.awb$"
  0092 invoke-virtual v4, v5, v6, Ljava/lang/String;->replaceFirst(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0098 move-result-object v4
  009a invoke-virtual v3, v4, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z
  00a0 move-result v3
  00a2 if-eqz v3, +016h
  00a6 const-wide/32 v3, 167772160
  00ac invoke-direct v7, v11, v3, v4, v2, Lcom/personal/aihub/AudioBanks;->checked(Ljava/lang/String; J Z)Ljava/io/File;
  00b2 move-result-object v2
  00b4 if-nez v2, +016h
  00b8 if-nez v13, +003h
  00bc goto +12h
  00be new-instance v8, Ljava/io/IOException;
  00c2 const-string v9, "The selected audio companion is unavailable"
  00c6 invoke-direct v8, v9, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00cc throw v8
  00ce new-instance v8, Ljava/io/IOException;
  00d2 const-string v9, "Audio bank companions must belong to the same collection and folder"
  00d6 invoke-direct v8, v9, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00dc throw v8
  00de move-object v2, v1
  00e0 new-instance v13, Lcom/personal/aihub/AudioBanks$Candidate;
  00e4 invoke-direct v13, v1, Lcom/personal/aihub/AudioBanks$Candidate;-><init>(Lcom/personal/aihub/AudioBanks$Candidate;)V
  00ea iput-object v9, v13, Lcom/personal/aihub/AudioBanks$Candidate;->identity Lcom/personal/aihub/AudioBanks$Identity;
  00ee iput-object v10, v13, Lcom/personal/aihub/AudioBanks$Candidate;->key Ljava/lang/String;
  00f2 if-nez v2, +003h
  00f6 move-object v11, v1
  00f8 iput-object v11, v13, Lcom/personal/aihub/AudioBanks$Candidate;->awbKey Ljava/lang/String;
  00fc iput-object v0, v13, Lcom/personal/aihub/AudioBanks$Candidate;->acb Ljava/io/File;
  0100 iput-object v2, v13, Lcom/personal/aihub/AudioBanks$Candidate;->awb Ljava/io/File;
  0104 iput-boolean v12, v13, Lcom/personal/aihub/AudioBanks$Candidate;->explicit Z
  0108 invoke-virtual v9, Lcom/personal/aihub/AudioBanks$Identity;->logical()Ljava/lang/String;
  010e move-result-object v11
  0110 invoke-interface v8, v11, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z
  0116 move-result v11
  0118 if-nez v11, +00eh
  011c invoke-virtual v9, Lcom/personal/aihub/AudioBanks$Identity;->logical()Ljava/lang/String;
  0122 move-result-object v11
  0124 new-instance v12, Ljava/util/LinkedHashMap;
  0128 invoke-direct v12, Ljava/util/LinkedHashMap;-><init>()V
  012e invoke-interface v8, v11, v12, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0134 invoke-virtual v9, Lcom/personal/aihub/AudioBanks$Identity;->logical()Ljava/lang/String;
  013a move-result-object v9
  013c invoke-interface v8, v9, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0142 move-result-object v8
  0144 check-cast v8, Ljava/util/Map;
  0148 invoke-interface v8, v10, v13, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  014e return-void 
.end method

.method assetRoute(Ljava/lang/String;)Ljava/lang/String;
  0000 const-string v0, "https://dokkan-eclipse.com"
  0004 const/4 v1, 0
  0006 if-eqz v3, +07eh
  000a const-string v2, "(?s).*[\\%\x00-\x20\x7f].*"
  000e invoke-virtual v3, v2, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0014 move-result v2
  0016 if-nez v2, +076h
  001a const-string v2, "/(?:\.|\.\.)(?:/|$)"
  001e invoke-static v2, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;)Ljava/util/regex/Pattern;
  0024 move-result-object v2
  0026 invoke-virtual v2, v3, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  002c move-result-object v2
  002e invoke-virtual v2, Ljava/util/regex/Matcher;->find()Z
  0034 move-result v2
  0036 if-nez v2, +066h
  003a const-string v2, "/"
  003e invoke-virtual v3, v2, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0044 move-result v2
  0046 if-eqz v2, +00eh
  004a new-instance v2, Ljava/lang/StringBuilder;
  004e invoke-direct v2, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0054 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  005a invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0060 move-result-object v3
  0062 new-instance v0, Ljava/net/URI;
  0066 invoke-direct v0, v3, Ljava/net/URI;-><init>(Ljava/lang/String;)V
  006c const-string v3, "https"
  0070 invoke-virtual v0, Ljava/net/URI;->getScheme()Ljava/lang/String;
  0076 move-result-object v2
  0078 invoke-virtual v3, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  007e move-result v3
  0080 if-eqz v3, +041h
  0084 const-string v3, "dokkan-eclipse.com"
  0088 invoke-virtual v0, Ljava/net/URI;->getHost()Ljava/lang/String;
  008e move-result-object v2
  0090 invoke-virtual v3, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0096 move-result v3
  0098 if-eqz v3, +035h
  009c invoke-virtual v0, Ljava/net/URI;->getPort()I
  00a2 move-result v3
  00a4 const/4 v2, -1
  00a6 if-ne v3, v2, +02eh
  00aa invoke-virtual v0, Ljava/net/URI;->getRawQuery()Ljava/lang/String;
  00b0 move-result-object v3
  00b2 if-nez v3, +028h
  00b6 invoke-virtual v0, Ljava/net/URI;->getRawFragment()Ljava/lang/String;
  00bc move-result-object v3
  00be if-nez v3, +022h
  00c2 invoke-virtual v0, Ljava/net/URI;->getUserInfo()Ljava/lang/String;
  00c8 move-result-object v3
  00ca if-nez v3, +01ch
  00ce const-string v3, "^/_forge/audio-bank-assets/([A-Za-z0-9_-]{16,128}\.(?:acb|awb))$"
  00d2 invoke-static v3, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;)Ljava/util/regex/Pattern;
  00d8 move-result-object v3
  00da invoke-virtual v0, Ljava/net/URI;->getRawPath()Ljava/lang/String;
  00e0 move-result-object v0
  00e2 invoke-virtual v3, v0, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  00e8 move-result-object v3
  00ea invoke-virtual v3, Ljava/util/regex/Matcher;->matches()Z
  00f0 move-result v0
  00f2 if-eqz v0, +008h
  00f6 const/4 v0, 1
  00f8 invoke-virtual v3, v0, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  00fe move-result-object v3
  0100 return-object v3
  0102 return-object v1
.end method

.method checked(Ljava/lang/String; J Z)Ljava/io/File;
  0000 iget-object v0, v6, Lcom/personal/aihub/AudioBanks;->root Ljava/io/File;
  0004 invoke-virtual v0, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  000a move-result-object v0
  000c invoke-static v0, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  0012 move-result v0
  0014 if-nez v0, +0a8h
  0018 iget-object v0, v6, Lcom/personal/aihub/AudioBanks;->root Ljava/io/File;
  001c invoke-virtual v0, Ljava/io/File;->isDirectory()Z
  0022 move-result v0
  0024 if-eqz v0, +0a0h
  0028 invoke-static v7, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  002e move-result v0
  0030 if-eqz v0, +092h
  0034 iget-object v0, v6, Lcom/personal/aihub/AudioBanks;->root Ljava/io/File;
  0038 const-string v1, "/"
  003c invoke-virtual v7, v1, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  0042 move-result-object v7
  0044 array-length v1, v7
  0046 const/4 v2, 0
  0048 const/4 v3, 0
  004a if-ge v2, v1, +026h
  004e new-instance v4, Ljava/io/File;
  0052 aget-object v5, v7, v2
  0056 invoke-direct v4, v0, v5, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  005c invoke-virtual v4, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0062 move-result-object v0
  0064 invoke-static v0, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  006a move-result v0
  006c if-nez v0, +00dh
  0070 invoke-virtual v4, Ljava/io/File;->exists()Z
  0076 move-result v0
  0078 if-nez v0, +003h
  007c return-object v3
  007e add-int/lit8 v2, v2, 1
  0082 move-object v0, v4
  0084 goto -1eh
  0086 new-instance v7, Ljava/io/IOException;
  008a const-string v8, "Imported audio banks cannot use symbolic links"
  008e invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0094 throw v7
  0096 if-eqz v10, +009h
  009a invoke-virtual v0, Ljava/io/File;->isDirectory()Z
  00a0 move-result v7
  00a2 if-nez v7, +00ah
  00a6 goto +7h
  00a8 invoke-virtual v0, Ljava/io/File;->isFile()Z
  00ae move-result v7
  00b0 if-nez v7, +003h
  00b4 return-object v3
  00b6 invoke-virtual v0, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  00bc move-result-object v7
  00be invoke-virtual v7, Ljava/io/File;->getPath()Ljava/lang/String;
  00c4 move-result-object v1
  00c6 new-instance v2, Ljava/lang/StringBuilder;
  00ca invoke-direct v2, Ljava/lang/StringBuilder;-><init>()V
  00d0 iget-object v3, v6, Lcom/personal/aihub/AudioBanks;->root Ljava/io/File;
  00d4 invoke-virtual v3, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  00da move-result-object v3
  00dc invoke-static v3, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  00e2 move-result-object v3
  00e4 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00ea sget-object v3, Ljava/io/File;->separator Ljava/lang/String;
  00ee invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00f4 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00fa move-result-object v2
  00fc invoke-virtual v1, v2, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0102 move-result v1
  0104 if-eqz v1, +020h
  0108 if-nez v10, +01dh
  010c invoke-virtual v0, Ljava/io/File;->length()J
  0112 move-result-wide v1
  0114 const-wide/16 v3, 0
  0118 cmp-long v10, v1, v3
  011c if-eqz v10, +00bh
  0120 invoke-virtual v0, Ljava/io/File;->length()J
  0126 move-result-wide v0
  0128 cmp-long v8, v0, v8
  012c if-gtz v8, +003h
  0130 goto +9h
  0132 new-instance v7, Ljava/io/IOException;
  0136 const-string v8, "Imported audio bank exceeds its supported size"
  013a invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0140 throw v7
  0142 return-object v7
  0144 new-instance v7, Ljava/io/IOException;
  0148 const-string v8, "Imported audio bank escapes its resource folder"
  014c invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0152 throw v7
  0154 new-instance v7, Ljava/io/IOException;
  0158 const-string v8, "Invalid imported audio resource"
  015c invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0162 throw v7
  0164 new-instance v7, Ljava/io/IOException;
  0168 const-string v8, "Invalid imported audio folder"
  016c invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0172 throw v7
.end method

.method entries(Ljava/lang/String;)Ljava/util/List;
  0000 const-string v0, "/$"
  0004 const-string v1, ""
  0008 invoke-virtual v8, v0, v1, Ljava/lang/String;->replaceAll(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  000e move-result-object v8
  0010 const-wide/16 v0, 0
  0014 const/4 v2, 1
  0016 invoke-direct v7, v8, v0, v1, v2, Lcom/personal/aihub/AudioBanks;->checked(Ljava/lang/String; J Z)Ljava/io/File;
  001c move-result-object v8
  001e new-instance v0, Ljava/util/ArrayList;
  0022 invoke-direct v0, Ljava/util/ArrayList;-><init>()V
  0028 if-nez v8, +003h
  002c return-object v0
  002e invoke-virtual v8, Ljava/io/File;->listFiles()[Ljava/io/File;
  0034 move-result-object v8
  0036 if-eqz v8, +03eh
  003a array-length v1, v8
  003c const/4 v3, 0
  003e if-ge v3, v1, +036h
  0042 aget-object v4, v8, v3
  0046 iget v5, v7, Lcom/personal/aihub/AudioBanks;->scanned I
  004a add-int/2addr v5, v2
  004c iput v5, v7, Lcom/personal/aihub/AudioBanks;->scanned I
  0050 const v6, 50000
  0056 if-gt v5, v6, +022h
  005a invoke-virtual v4, Ljava/io/File;->getName()Ljava/lang/String;
  0060 move-result-object v5
  0062 invoke-static v5, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  0068 move-result v5
  006a if-eqz v5, +015h
  006e invoke-virtual v4, Ljava/io/File;->getName()Ljava/lang/String;
  0074 move-result-object v5
  0076 const-string v6, "/"
  007a invoke-virtual v5, v6, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  0080 move-result v5
  0082 if-nez v5, +009h
  0086 invoke-virtual v4, Ljava/io/File;->getName()Ljava/lang/String;
  008c move-result-object v4
  008e invoke-virtual v0, v4, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0094 add-int/lit8 v3, v3, 1
  0098 goto -2dh
  009a new-instance v8, Ljava/io/IOException;
  009e const-string v0, "Imported audio discovery exceeds its 50,000-entry limit"
  00a2 invoke-direct v8, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00a8 throw v8
  00aa invoke-static v0, Ljava/util/Collections;->sort(Ljava/util/List;)V
  00b0 return-object v0
  00b2 new-instance v8, Ljava/io/IOException;
  00b6 const-string v0, "Imported audio folder cannot be read"
  00ba invoke-direct v8, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00c0 throw v8
.end method

.method folder(Ljava/util/Map; Ljava/lang/String; Ljava/lang/String;)V
  0000 new-instance v1, Ljava/lang/StringBuilder;
  0004 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  000a invoke-static v13, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0010 move-result-object v2
  0012 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0018 const-string v2, "/"
  001c invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0022 invoke-virtual v1, v14, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0028 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  002e move-result-object v1
  0030 invoke-direct v11, v1, Lcom/personal/aihub/AudioBanks;->entries(Ljava/lang/String;)Ljava/util/List;
  0036 move-result-object v1
  0038 new-instance v10, Ljava/util/HashMap;
  003c invoke-direct v10, Ljava/util/HashMap;-><init>()V
  0042 invoke-interface v1, Ljava/util/List;->iterator()Ljava/util/Iterator;
  0048 move-result-object v3
  004a invoke-interface v3, Ljava/util/Iterator;->hasNext()Z
  0050 move-result v4
  0052 if-eqz v4, +023h
  0056 invoke-interface v3, Ljava/util/Iterator;->next()Ljava/lang/Object;
  005c move-result-object v4
  005e check-cast v4, Ljava/lang/String;
  0062 sget-object v5, Ljava/text/Normalizer$Form;->NFC Ljava/text/Normalizer$Form;
  0066 invoke-static v4, v5, Ljava/text/Normalizer;->normalize(Ljava/lang/CharSequence; Ljava/text/Normalizer$Form;)Ljava/lang/String;
  006c move-result-object v5
  006e sget-object v6, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  0072 invoke-virtual v5, v6, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  0078 move-result-object v5
  007a invoke-virtual v10, v5, v4, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0080 move-result-object v4
  0082 if-nez v4, +003h
  0086 goto -1eh
  0088 new-instance v0, Ljava/io/IOException;
  008c const-string v1, "Imported audio filenames are ambiguous"
  0090 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0096 throw v0
  0098 invoke-interface v1, Ljava/util/List;->iterator()Ljava/util/Iterator;
  009e move-result-object v1
  00a0 invoke-interface v1, Ljava/util/Iterator;->hasNext()Z
  00a6 move-result v3
  00a8 if-eqz v3, +08ch
  00ac invoke-interface v1, Ljava/util/Iterator;->next()Ljava/lang/Object;
  00b2 move-result-object v3
  00b4 check-cast v3, Ljava/lang/String;
  00b8 sget-object v4, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  00bc invoke-virtual v3, v4, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  00c2 move-result-object v4
  00c4 const-string v5, ".acb"
  00c8 invoke-virtual v4, v5, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  00ce move-result v4
  00d0 if-eqz v4, -018h
  00d4 const-string v4, "(?i)\.acb$"
  00d8 const-string v5, ".awb"
  00dc invoke-virtual v3, v4, v5, Ljava/lang/String;->replaceFirst(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  00e2 move-result-object v4
  00e4 sget-object v5, Ljava/text/Normalizer$Form;->NFC Ljava/text/Normalizer$Form;
  00e8 invoke-static v4, v5, Ljava/text/Normalizer;->normalize(Ljava/lang/CharSequence; Ljava/text/Normalizer$Form;)Ljava/lang/String;
  00ee move-result-object v4
  00f0 sget-object v5, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  00f4 invoke-virtual v4, v5, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  00fa move-result-object v4
  00fc invoke-virtual v10, v4, Ljava/util/HashMap;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0102 move-result-object v4
  0104 check-cast v4, Ljava/lang/String;
  0108 new-instance v5, Ljava/lang/StringBuilder;
  010c invoke-direct v5, Ljava/lang/StringBuilder;-><init>()V
  0112 invoke-static v14, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0118 move-result-object v6
  011a invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0120 invoke-virtual v5, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0126 invoke-virtual v5, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  012c invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0132 move-result-object v5
  0134 new-instance v6, Ljava/lang/StringBuilder;
  0138 invoke-direct v6, Ljava/lang/StringBuilder;-><init>()V
  013e invoke-static v13, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0144 move-result-object v7
  0146 invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  014c invoke-virtual v6, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0152 invoke-virtual v6, v14, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0158 invoke-virtual v6, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  015e invoke-virtual v6, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0164 invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  016a move-result-object v6
  016c if-nez v4, +004h
  0170 const/4 v3, 0
  0172 goto +1dh
  0174 new-instance v3, Ljava/lang/StringBuilder;
  0178 invoke-direct v3, Ljava/lang/StringBuilder;-><init>()V
  017e invoke-static v13, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0184 move-result-object v7
  0186 invoke-virtual v3, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  018c invoke-virtual v3, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0192 invoke-virtual v3, v14, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0198 invoke-virtual v3, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  019e invoke-virtual v3, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01a4 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01aa move-result-object v3
  01ac move-object v7, v3
  01ae const/4 v8, 0
  01b0 const/4 v9, 0
  01b2 move-object v3, v11
  01b4 move-object v4, v12
  01b6 invoke-direct/range v3 ... v9, Lcom/personal/aihub/AudioBanks;->add(Ljava/util/Map; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Z Z)V
  01bc goto/16 -08eh
  01c0 return-void 
.end method

.method group(Ljava/lang/String;)Ljava/lang/String;
  0000 invoke-static v3, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  0006 move-result v0
  0008 if-eqz v0, +014h
  000c const-string v0, "/"
  0010 invoke-virtual v3, v0, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  0016 move-result-object v1
  0018 array-length v1, v1
  001a const/4 v2, 2
  001c if-lt v1, v2, +00ah
  0020 invoke-virtual v3, v0, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  0026 move-result-object v3
  0028 const/4 v0, 0
  002a aget-object v3, v3, v0
  002e return-object v3
  0030 new-instance v3, Ljava/io/IOException;
  0034 const-string v0, "Invalid selected audio collection"
  0038 invoke-direct v3, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  003e throw v3
.end method

.method identical(Lcom/personal/aihub/AudioBanks$Candidate; Lcom/personal/aihub/AudioBanks$Candidate;)Z
  0000 move-object/from16 v1, v16
  0004 move-object/from16 v0, v17
  0008 move-object/from16 v2, v18
  000c iget-object v3, v0, Lcom/personal/aihub/AudioBanks$Candidate;->key Ljava/lang/String;
  0010 invoke-static v3, Lcom/personal/aihub/AudioBanks;->group(Ljava/lang/String;)Ljava/lang/String;
  0016 move-result-object v3
  0018 iget-object v4, v2, Lcom/personal/aihub/AudioBanks$Candidate;->key Ljava/lang/String;
  001c invoke-static v4, Lcom/personal/aihub/AudioBanks;->group(Ljava/lang/String;)Ljava/lang/String;
  0022 move-result-object v4
  0024 invoke-virtual v3, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  002a move-result v3
  002c const/4 v4, 0
  002e if-eqz v3, +12bh
  0032 iget-object v3, v0, Lcom/personal/aihub/AudioBanks$Candidate;->acb Ljava/io/File;
  0036 invoke-virtual v3, Ljava/io/File;->length()J
  003c move-result-wide v5
  003e iget-object v3, v2, Lcom/personal/aihub/AudioBanks$Candidate;->acb Ljava/io/File;
  0042 invoke-virtual v3, Ljava/io/File;->length()J
  0048 move-result-wide v7
  004a cmp-long v3, v5, v7
  004e if-nez v3, +11bh
  0052 iget-object v3, v0, Lcom/personal/aihub/AudioBanks$Candidate;->awb Ljava/io/File;
  0056 const/4 v5, 1
  0058 if-nez v3, +004h
  005c move v3, v5
  005e goto +2h
  0060 move v3, v4
  0062 iget-object v6, v2, Lcom/personal/aihub/AudioBanks$Candidate;->awb Ljava/io/File;
  0066 if-nez v6, +004h
  006a move v6, v5
  006c goto +2h
  006e move v6, v4
  0070 if-eq v3, v6, +004h
  0074 goto/16 +108h
  0078 iget-object v3, v0, Lcom/personal/aihub/AudioBanks$Candidate;->awb Ljava/io/File;
  007c if-eqz v3, +013h
  0080 iget-object v3, v0, Lcom/personal/aihub/AudioBanks$Candidate;->awb Ljava/io/File;
  0084 invoke-virtual v3, Ljava/io/File;->length()J
  008a move-result-wide v6
  008c iget-object v3, v2, Lcom/personal/aihub/AudioBanks$Candidate;->awb Ljava/io/File;
  0090 invoke-virtual v3, Ljava/io/File;->length()J
  0096 move-result-wide v8
  0098 cmp-long v3, v6, v8
  009c if-eqz v3, +003h
  00a0 return v4
  00a2 iget-object v3, v0, Lcom/personal/aihub/AudioBanks$Candidate;->acb Ljava/io/File;
  00a6 invoke-virtual v3, Ljava/io/File;->length()J
  00ac move-result-wide v6
  00ae iget-object v3, v0, Lcom/personal/aihub/AudioBanks$Candidate;->awb Ljava/io/File;
  00b2 const-wide/16 v8, 0
  00b6 if-nez v3, +004h
  00ba move-wide v10, v8
  00bc goto +7h
  00be iget-object v3, v0, Lcom/personal/aihub/AudioBanks$Candidate;->awb Ljava/io/File;
  00c2 invoke-virtual v3, Ljava/io/File;->length()J
  00c8 move-result-wide v10
  00ca add-long/2addr v6, v10
  00cc const-wide/16 v10, 2
  00d0 mul-long/2addr v6, v10
  00d2 iget-wide v10, v1, Lcom/personal/aihub/AudioBanks;->comparedBytes J
  00d6 add-long v12, v10, v6
  00da const-wide/32 v14, 536870912
  00e0 cmp-long v3, v12, v14
  00e4 if-lez v3, +003h
  00e8 return v4
  00ea add-long/2addr v10, v6
  00ec iput-wide v10, v1, Lcom/personal/aihub/AudioBanks;->comparedBytes J
  00f0 iget-object v3, v0, Lcom/personal/aihub/AudioBanks$Candidate;->awb Ljava/io/File;
  00f4 if-nez v3, +00fh
  00f8 new-array v3, v5, [[Ljava/lang/String;
  00fc iget-object v0, v0, Lcom/personal/aihub/AudioBanks$Candidate;->key Ljava/lang/String;
  0100 iget-object v2, v2, Lcom/personal/aihub/AudioBanks$Candidate;->key Ljava/lang/String;
  0104 filled-new-array v0, v2, [Ljava/lang/String;
  010a move-result-object v0
  010c aput-object v0, v3, v4
  0110 goto +18h
  0112 const/4 v3, 2
  0114 new-array v3, v3, [[Ljava/lang/String;
  0118 iget-object v6, v0, Lcom/personal/aihub/AudioBanks$Candidate;->key Ljava/lang/String;
  011c iget-object v7, v2, Lcom/personal/aihub/AudioBanks$Candidate;->key Ljava/lang/String;
  0120 filled-new-array v6, v7, [Ljava/lang/String;
  0126 move-result-object v6
  0128 aput-object v6, v3, v4
  012c iget-object v0, v0, Lcom/personal/aihub/AudioBanks$Candidate;->awbKey Ljava/lang/String;
  0130 iget-object v2, v2, Lcom/personal/aihub/AudioBanks$Candidate;->awbKey Ljava/lang/String;
  0134 filled-new-array v0, v2, [Ljava/lang/String;
  013a move-result-object v0
  013c aput-object v0, v3, v5
  0140 array-length v0, v3
  0142 move v2, v4
  0144 if-ge v2, v0, +09fh
  0148 aget-object v6, v3, v2
  014c aget-object v7, v6, v4
  0150 sget-object v10, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  0154 invoke-virtual v7, v10, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  015a move-result-object v7
  015c const-string v10, ".acb"
  0160 invoke-virtual v7, v10, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  0166 move-result v7
  0168 if-eqz v7, +006h
  016c const-wide/32 v10, 33554432
  0172 goto +4h
  0174 const-wide/32 v10, 167772160
  017a aget-object v7, v6, v4
  017e invoke-direct v1, v7, v10, v11, v4, Lcom/personal/aihub/AudioBanks;->checked(Ljava/lang/String; J Z)Ljava/io/File;
  0184 move-result-object v7
  0186 aget-object v6, v6, v5
  018a invoke-direct v1, v6, v10, v11, v4, Lcom/personal/aihub/AudioBanks;->checked(Ljava/lang/String; J Z)Ljava/io/File;
  0190 move-result-object v6
  0192 if-eqz v7, +077h
  0196 if-eqz v6, +075h
  019a invoke-virtual v7, Ljava/io/File;->length()J
  01a0 move-result-wide v10
  01a2 invoke-virtual v6, Ljava/io/File;->length()J
  01a8 move-result-wide v12
  01aa cmp-long v10, v10, v12
  01ae if-eqz v10, +003h
  01b2 goto +67h
  01b4 new-instance v10, Ljava/io/RandomAccessFile;
  01b8 const-string v11, "r"
  01bc invoke-direct v10, v7, v11, Ljava/io/RandomAccessFile;-><init>(Ljava/io/File; Ljava/lang/String;)V
  01c2 new-instance v12, Ljava/io/RandomAccessFile;
  01c6 invoke-direct v12, v6, v11, Ljava/io/RandomAccessFile;-><init>(Ljava/io/File; Ljava/lang/String;)V
  01cc const/high16 v6, 65536
  01d0 new-array v11, v6, [B
  01d4 new-array v13, v6, [B
  01d8 invoke-virtual v7, Ljava/io/File;->length()J
  01de move-result-wide v14
  01e0 cmp-long v7, v14, v8
  01e4 if-lez v7, +02ah
  01e8 int-to-long v8, v6
  01ea invoke-static v8, v9, v14, v15, Ljava/lang/Math;->min(J J)J
  01f0 move-result-wide v7
  01f2 long-to-int v7, v7
  01f4 invoke-virtual v10, v11, v4, v7, Ljava/io/RandomAccessFile;->readFully([B I I)V
  01fa invoke-virtual v12, v13, v4, v7, Ljava/io/RandomAccessFile;->readFully([B I I)V
  0200 move v8, v4
  0202 if-ge v8, v7, +014h
  0206 aget-byte v9, v11, v8
  020a aget-byte v6, v13, v8
  020e if-eq v9, v6, +009h
  0212 invoke-virtual v12, Ljava/io/RandomAccessFile;->close()V
  0218 invoke-virtual v10, Ljava/io/RandomAccessFile;->close()V
  021e return v4
  0220 add-int/lit8 v8, v8, 1
  0224 const/high16 v6, 65536
  0228 goto -13h
  022a int-to-long v6, v7
  022c sub-long/2addr v14, v6
  022e const/high16 v6, 65536
  0232 const-wide/16 v8, 0
  0236 goto -2bh
  0238 invoke-virtual v12, Ljava/io/RandomAccessFile;->close()V
  023e invoke-virtual v10, Ljava/io/RandomAccessFile;->close()V
  0244 add-int/lit8 v2, v2, 1
  0248 const-wide/16 v8, 0
  024c goto/16 -084h
  0250 move-exception v0
  0252 move-object v2, v0
  0254 invoke-virtual v12, Ljava/io/RandomAccessFile;->close()V
  025a goto +6h
  025c move-exception v0
  025e move-object v3, v0
  0260 invoke-virtual v2, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0266 throw v2
  0268 move-exception v0
  026a move-object v2, v0
  026c invoke-virtual v10, Ljava/io/RandomAccessFile;->close()V
  0272 goto +6h
  0274 move-exception v0
  0276 move-object v3, v0
  0278 invoke-virtual v2, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  027e throw v2
  0280 return v4
  0282 return v5
  0284 return v4
.end method

.method identity(Ljava/lang/String;)Lcom/personal/aihub/AudioBanks$Identity;
  0000 const-string v0, "^se/([A-Za-z0-9_-]{1,80})\.acb$"
  0004 const/4 v1, 2
  0006 invoke-static v0, v1, Ljava/util/regex/Pattern;->compile(Ljava/lang/String; I)Ljava/util/regex/Pattern;
  000c move-result-object v0
  000e invoke-virtual v0, v5, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  0014 move-result-object v0
  0016 invoke-virtual v0, Ljava/util/regex/Matcher;->matches()Z
  001c move-result v2
  001e const/4 v3, 1
  0020 const-string v4, ""
  0024 if-eqz v2, +00eh
  0028 new-instance v5, Lcom/personal/aihub/AudioBanks$Identity;
  002c const-string v1, "se"
  0030 invoke-virtual v0, v3, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  0036 move-result-object v0
  0038 invoke-direct v5, v1, v0, v4, Lcom/personal/aihub/AudioBanks$Identity;-><init>(Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)V
  003e return-object v5
  0040 const-string v0, "^voice/(?:(en|ja)/)?([A-Za-z0-9_-]{1,80})/([A-Za-z0-9_-]{1,80})\.acb$"
  0044 invoke-static v0, v1, Ljava/util/regex/Pattern;->compile(Ljava/lang/String; I)Ljava/util/regex/Pattern;
  004a move-result-object v0
  004c invoke-virtual v0, v5, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  0052 move-result-object v5
  0054 invoke-virtual v5, Ljava/util/regex/Matcher;->matches()Z
  005a move-result v0
  005c if-eqz v0, +02eh
  0060 invoke-virtual v5, v1, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  0066 move-result-object v0
  0068 const/4 v2, 3
  006a invoke-virtual v5, v2, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  0070 move-result-object v2
  0072 invoke-virtual v0, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0078 move-result v0
  007a if-nez v0, +003h
  007e goto +1dh
  0080 invoke-virtual v5, v1, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  0086 move-result-object v0
  0088 invoke-virtual v5, v3, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  008e move-result-object v1
  0090 if-eqz v1, +00ch
  0094 invoke-virtual v5, v3, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  009a move-result-object v5
  009c sget-object v1, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  00a0 invoke-virtual v5, v1, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  00a6 move-result-object v4
  00a8 new-instance v5, Lcom/personal/aihub/AudioBanks$Identity;
  00ac const-string v1, "voice"
  00b0 invoke-direct v5, v1, v0, v4, Lcom/personal/aihub/AudioBanks$Identity;-><init>(Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)V
  00b6 return-object v5
  00b8 const/4 v5, 0
  00ba return-object v5
.end method

.method catalogue()Lorg/json/JSONObject;
  0000 move-object/from16 v8, v19
  0004 monitor-enter v19
  0006 iget-boolean v0, v8, Lcom/personal/aihub/AudioBanks;->closed Z
  000a if-nez v0, +4ech
  000e iget-object v0, v8, Lcom/personal/aihub/AudioBanks;->cached Lorg/json/JSONObject;
  0012 if-eqz v0, +00fh
  0016 new-instance v0, Lorg/json/JSONObject;
  001a iget-object v1, v8, Lcom/personal/aihub/AudioBanks;->cached Lorg/json/JSONObject;
  001e invoke-virtual v1, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0024 move-result-object v1
  0026 invoke-direct v0, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  002c goto/16 +4d1h
  0030 iget-object v0, v8, Lcom/personal/aihub/AudioBanks;->overlays Lorg/json/JSONArray;
  0034 invoke-static v0, Lcom/personal/aihub/GameAssets;->overlayMap(Lorg/json/JSONArray;)Ljava/util/Map;
  003a move-result-object v0
  003c new-instance v9, Ljava/util/HashSet;
  0040 invoke-direct v9, Ljava/util/HashSet;-><init>()V
  0046 iget-object v1, v8, Lcom/personal/aihub/AudioBanks;->preferredKey Ljava/lang/String;
  004a if-eqz v1, +011h
  004e invoke-virtual v1, Ljava/lang/String;->isEmpty()Z
  0054 move-result v1
  0056 if-nez v1, +00bh
  005a iget-object v1, v8, Lcom/personal/aihub/AudioBanks;->preferredKey Ljava/lang/String;
  005e invoke-static v1, Lcom/personal/aihub/AudioBanks;->group(Ljava/lang/String;)Ljava/lang/String;
  0064 move-result-object v1
  0066 invoke-virtual v9, v1, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  006c invoke-interface v0, Ljava/util/Map;->values()Ljava/util/Collection;
  0072 move-result-object v1
  0074 invoke-interface v1, Ljava/util/Collection;->iterator()Ljava/util/Iterator;
  007a move-result-object v1
  007c invoke-interface v1, Ljava/util/Iterator;->hasNext()Z
  0082 move-result v2
  0084 if-eqz v2, +010h
  0088 invoke-interface v1, Ljava/util/Iterator;->next()Ljava/lang/Object;
  008e move-result-object v2
  0090 check-cast v2, Ljava/lang/String;
  0094 invoke-static v2, Lcom/personal/aihub/AudioBanks;->group(Ljava/lang/String;)Ljava/lang/String;
  009a move-result-object v2
  009c invoke-virtual v9, v2, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  00a2 goto -13h
  00a4 iget-object v1, v8, Lcom/personal/aihub/AudioBanks;->root Ljava/io/File;
  00a8 invoke-virtual v1, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  00ae move-result-object v1
  00b0 invoke-static v1, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  00b6 move-result v1
  00b8 if-nez v1, +48dh
  00bc iget-object v1, v8, Lcom/personal/aihub/AudioBanks;->root Ljava/io/File;
  00c0 invoke-virtual v1, Ljava/io/File;->exists()Z
  00c6 move-result v1
  00c8 const/4 v10, 1
  00ca if-eqz v1, +454h
  00ce iget-object v1, v8, Lcom/personal/aihub/AudioBanks;->root Ljava/io/File;
  00d2 invoke-virtual v1, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  00d8 move-result-object v1
  00da invoke-static v1, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  00e0 move-result v1
  00e2 if-nez v1, +440h
  00e6 iget-object v1, v8, Lcom/personal/aihub/AudioBanks;->root Ljava/io/File;
  00ea invoke-virtual v1, Ljava/io/File;->isDirectory()Z
  00f0 move-result v1
  00f2 if-eqz v1, +438h
  00f6 const/4 v11, 0
  00f8 iput v11, v8, Lcom/personal/aihub/AudioBanks;->scanned I
  00fc new-instance v1, Ljava/util/ArrayList;
  0100 invoke-direct v1, Ljava/util/ArrayList;-><init>()V
  0106 iget-boolean v2, v8, Lcom/personal/aihub/AudioBanks;->onlyAliases Z
  010a if-eqz v2, +005h
  010e new-array v2, v11, [Ljava/io/File;
  0112 goto +7h
  0114 iget-object v2, v8, Lcom/personal/aihub/AudioBanks;->root Ljava/io/File;
  0118 invoke-virtual v2, Ljava/io/File;->listFiles()[Ljava/io/File;
  011e move-result-object v2
  0120 if-eqz v2, +419h
  0124 array-length v3, v2
  0126 move v4, v11
  0128 if-ge v4, v3, +039h
  012c aget-object v5, v2, v4
  0130 invoke-virtual v5, Ljava/io/File;->isDirectory()Z
  0136 move-result v6
  0138 if-eqz v6, +02eh
  013c invoke-virtual v5, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0142 move-result-object v6
  0144 invoke-static v6, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  014a move-result v6
  014c if-nez v6, +024h
  0150 invoke-virtual v5, Ljava/io/File;->getName()Ljava/lang/String;
  0156 move-result-object v6
  0158 invoke-static v6, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  015e move-result v6
  0160 if-eqz v6, +01ah
  0164 invoke-virtual v1, Ljava/util/ArrayList;->size()I
  016a move-result v6
  016c const/16 v7, 512
  0170 if-ge v6, v7, +00ah
  0174 invoke-virtual v5, Ljava/io/File;->getName()Ljava/lang/String;
  017a move-result-object v5
  017c invoke-virtual v1, v5, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0182 goto +9h
  0184 new-instance v0, Ljava/io/IOException;
  0188 const-string v1, "Imported audio discovery exceeds its collection limit"
  018c invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0192 throw v0
  0194 add-int/lit8 v4, v4, 1
  0198 goto -38h
  019a invoke-static v1, Ljava/util/Collections;->sort(Ljava/util/List;)V
  01a0 new-instance v12, Ljava/util/TreeMap;
  01a4 invoke-direct v12, Ljava/util/TreeMap;-><init>()V
  01aa invoke-virtual v1, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
  01b0 move-result-object v1
  01b2 invoke-interface v1, Ljava/util/Iterator;->hasNext()Z
  01b8 move-result v2
  01ba if-eqz v2, +130h
  01be invoke-interface v1, Ljava/util/Iterator;->next()Ljava/lang/Object;
  01c4 move-result-object v2
  01c6 check-cast v2, Ljava/lang/String;
  01ca new-instance v3, Ljava/util/ArrayList;
  01ce new-instance v4, Ljava/lang/StringBuilder;
  01d2 invoke-direct v4, Ljava/lang/StringBuilder;-><init>()V
  01d8 invoke-static v2, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  01de move-result-object v5
  01e0 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01e6 const-string v5, "/files"
  01ea invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01f0 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01f6 move-result-object v4
  01f8 new-instance v5, Ljava/lang/StringBuilder;
  01fc invoke-direct v5, Ljava/lang/StringBuilder;-><init>()V
  0202 invoke-static v2, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0208 move-result-object v6
  020a invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0210 const-string v6, "/tutorial0"
  0214 invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  021a invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0220 move-result-object v5
  0222 filled-new-array v2, v4, v5, [Ljava/lang/String;
  0228 move-result-object v4
  022a invoke-static v4, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  0230 move-result-object v4
  0232 invoke-direct v3, v4, Ljava/util/ArrayList;-><init>(Ljava/util/Collection;)V
  0238 new-instance v4, Ljava/lang/StringBuilder;
  023c invoke-direct v4, Ljava/lang/StringBuilder;-><init>()V
  0242 invoke-static v2, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0248 move-result-object v5
  024a invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0250 const-string v5, "/Payload"
  0254 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  025a invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0260 move-result-object v4
  0262 invoke-direct v8, v4, Lcom/personal/aihub/AudioBanks;->entries(Ljava/lang/String;)Ljava/util/List;
  0268 move-result-object v4
  026a invoke-interface v4, Ljava/util/List;->iterator()Ljava/util/Iterator;
  0270 move-result-object v4
  0272 invoke-interface v4, Ljava/util/Iterator;->hasNext()Z
  0278 move-result v5
  027a if-eqz v5, +04ch
  027e invoke-interface v4, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0284 move-result-object v5
  0286 check-cast v5, Ljava/lang/String;
  028a const-string v6, "[A-Za-z0-9_. -]{1,120}\.app"
  028e invoke-virtual v5, v6, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0294 move-result v6
  0296 if-eqz v6, -012h
  029a new-instance v6, Ljava/lang/StringBuilder;
  029e invoke-direct v6, Ljava/lang/StringBuilder;-><init>()V
  02a4 invoke-static v2, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  02aa move-result-object v7
  02ac invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02b2 const-string v7, "/Payload/"
  02b6 invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02bc invoke-virtual v6, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02c2 invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  02c8 move-result-object v6
  02ca invoke-virtual v3, v6, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  02d0 new-instance v6, Ljava/lang/StringBuilder;
  02d4 invoke-direct v6, Ljava/lang/StringBuilder;-><init>()V
  02da invoke-static v2, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  02e0 move-result-object v7
  02e2 invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02e8 const-string v7, "/Payload/"
  02ec invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02f2 invoke-virtual v6, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02f8 const-string v5, "/tutorial0"
  02fc invoke-virtual v6, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0302 invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0308 move-result-object v5
  030a invoke-virtual v3, v5, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0310 goto -4fh
  0312 invoke-virtual v3, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
  0318 move-result-object v2
  031a invoke-interface v2, Ljava/util/Iterator;->hasNext()Z
  0320 move-result v3
  0322 if-eqz v3, -0b8h
  0326 invoke-interface v2, Ljava/util/Iterator;->next()Ljava/lang/Object;
  032c move-result-object v3
  032e check-cast v3, Ljava/lang/String;
  0332 const-string v4, "se"
  0336 invoke-direct v8, v12, v3, v4, Lcom/personal/aihub/AudioBanks;->folder(Ljava/util/Map; Ljava/lang/String; Ljava/lang/String;)V
  033c const-string v4, ""
  0340 const-string v5, "en/"
  0344 const-string v6, "ja/"
  0348 filled-new-array v4, v5, v6, [Ljava/lang/String;
  034e move-result-object v4
  0350 move v5, v11
  0352 const/4 v6, 3
  0354 if-ge v5, v6, -01dh
  0358 aget-object v6, v4, v5
  035c new-instance v7, Ljava/lang/StringBuilder;
  0360 invoke-direct v7, Ljava/lang/StringBuilder;-><init>()V
  0366 invoke-static v3, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  036c move-result-object v13
  036e invoke-virtual v7, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0374 const-string v13, "/voice/"
  0378 invoke-virtual v7, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  037e invoke-virtual v7, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0384 invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  038a move-result-object v7
  038c invoke-direct v8, v7, Lcom/personal/aihub/AudioBanks;->entries(Ljava/lang/String;)Ljava/util/List;
  0392 move-result-object v7
  0394 invoke-interface v7, Ljava/util/List;->iterator()Ljava/util/Iterator;
  039a move-result-object v7
  039c invoke-interface v7, Ljava/util/Iterator;->hasNext()Z
  03a2 move-result v13
  03a4 if-eqz v13, +038h
  03a8 invoke-interface v7, Ljava/util/Iterator;->next()Ljava/lang/Object;
  03ae move-result-object v13
  03b0 check-cast v13, Ljava/lang/String;
  03b4 const-string v14, "[A-Za-z0-9_-]{1,80}"
  03b8 invoke-virtual v13, v14, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  03be move-result v14
  03c0 if-eqz v14, -012h
  03c4 const-string v14, "en"
  03c8 invoke-virtual v13, v14, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  03ce move-result v14
  03d0 if-nez v14, -01ah
  03d4 const-string v14, "ja"
  03d8 invoke-virtual v13, v14, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  03de move-result v14
  03e0 if-nez v14, -022h
  03e4 new-instance v14, Ljava/lang/StringBuilder;
  03e8 invoke-direct v14, Ljava/lang/StringBuilder;-><init>()V
  03ee const-string v15, "voice/"
  03f2 invoke-virtual v14, v15, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  03f8 invoke-virtual v14, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  03fe invoke-virtual v14, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0404 invoke-virtual v14, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  040a move-result-object v13
  040c invoke-direct v8, v12, v3, v13, Lcom/personal/aihub/AudioBanks;->folder(Ljava/util/Map; Ljava/lang/String; Ljava/lang/String;)V
  0412 goto -3bh
  0414 add-int/lit8 v5, v5, 1
  0418 goto -63h
  041a invoke-interface v0, Ljava/util/Map;->entrySet()Ljava/util/Set;
  0420 move-result-object v1
  0422 invoke-interface v1, Ljava/util/Set;->iterator()Ljava/util/Iterator;
  0428 move-result-object v13
  042a invoke-interface v13, Ljava/util/Iterator;->hasNext()Z
  0430 move-result v1
  0432 if-eqz v1, +054h
  0436 invoke-interface v13, Ljava/util/Iterator;->next()Ljava/lang/Object;
  043c move-result-object v1
  043e check-cast v1, Ljava/util/Map$Entry;
  0442 invoke-interface v1, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;
  0448 move-result-object v2
  044a check-cast v2, Ljava/lang/String;
  044e invoke-static v2, Lcom/personal/aihub/AudioBanks;->identity(Ljava/lang/String;)Lcom/personal/aihub/AudioBanks$Identity;
  0454 move-result-object v2
  0456 if-eqz v2, -016h
  045a invoke-interface v1, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;
  0460 move-result-object v2
  0462 check-cast v2, Ljava/lang/String;
  0466 const-string v3, "(?i)\.acb$"
  046a const-string v4, ".awb"
  046e invoke-virtual v2, v3, v4, Ljava/lang/String;->replaceFirst(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0474 move-result-object v2
  0476 invoke-interface v0, v2, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  047c move-result-object v2
  047e check-cast v2, Ljava/lang/String;
  0482 invoke-interface v1, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;
  0488 move-result-object v3
  048a check-cast v3, Ljava/lang/String;
  048e invoke-interface v1, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;
  0494 move-result-object v4
  0496 check-cast v4, Ljava/lang/String;
  049a if-eqz v2, +004h
  049e move-object v5, v2
  04a0 goto +10h
  04a2 invoke-interface v1, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;
  04a8 move-result-object v1
  04aa check-cast v1, Ljava/lang/String;
  04ae const-string v5, "(?i)\.acb$"
  04b2 const-string v6, ".awb"
  04b6 invoke-virtual v1, v5, v6, Ljava/lang/String;->replaceFirst(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  04bc move-result-object v1
  04be move-object v5, v1
  04c0 if-eqz v2, +004h
  04c4 move v7, v10
  04c6 goto +2h
  04c8 move v7, v11
  04ca const/4 v6, 1
  04cc move-object/from16 v1, v19
  04d0 move-object v2, v12
  04d2 invoke-direct/range v1 ... v7, Lcom/personal/aihub/AudioBanks;->add(Ljava/util/Map; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Z Z)V
  04d8 goto -57h
  04da new-instance v0, Lorg/json/JSONArray;
  04de invoke-direct v0, Lorg/json/JSONArray;-><init>()V
  04e4 new-instance v1, Lorg/json/JSONArray;
  04e8 invoke-direct v1, Lorg/json/JSONArray;-><init>()V
  04ee invoke-virtual v12, Ljava/util/TreeMap;->values()Ljava/util/Collection;
  04f4 move-result-object v2
  04f6 invoke-interface v2, Ljava/util/Collection;->iterator()Ljava/util/Iterator;
  04fc move-result-object v2
  04fe invoke-interface v2, Ljava/util/Iterator;->hasNext()Z
  0504 move-result v3
  0506 if-eqz v3, +200h
  050a new-instance v3, Ljava/util/ArrayList;
  050e invoke-interface v2, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0514 move-result-object v4
  0516 check-cast v4, Ljava/util/Map;
  051a invoke-interface v4, Ljava/util/Map;->values()Ljava/util/Collection;
  0520 move-result-object v4
  0522 invoke-direct v3, v4, Ljava/util/ArrayList;-><init>(Ljava/util/Collection;)V
  0528 new-instance v4, Ljava/util/ArrayList;
  052c invoke-direct v4, Ljava/util/ArrayList;-><init>()V
  0532 new-instance v5, Ljava/util/ArrayList;
  0536 invoke-direct v5, Ljava/util/ArrayList;-><init>()V
  053c invoke-virtual v3, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
  0542 move-result-object v6
  0544 invoke-interface v6, Ljava/util/Iterator;->hasNext()Z
  054a move-result v7
  054c if-eqz v7, +01fh
  0550 invoke-interface v6, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0556 move-result-object v7
  0558 check-cast v7, Lcom/personal/aihub/AudioBanks$Candidate;
  055c iget-boolean v12, v7, Lcom/personal/aihub/AudioBanks$Candidate;->explicit Z
  0560 if-eqz v12, +005h
  0564 invoke-virtual v4, v7, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  056a iget-object v12, v7, Lcom/personal/aihub/AudioBanks$Candidate;->key Ljava/lang/String;
  056e invoke-static v12, Lcom/personal/aihub/AudioBanks;->group(Ljava/lang/String;)Ljava/lang/String;
  0574 move-result-object v12
  0576 invoke-virtual v9, v12, Ljava/util/HashSet;->contains(Ljava/lang/Object;)Z
  057c move-result v12
  057e if-eqz v12, -01dh
  0582 invoke-virtual v5, v7, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0588 goto -22h
  058a invoke-virtual v4, Ljava/util/ArrayList;->isEmpty()Z
  0590 move-result v6
  0592 if-nez v6, +004h
  0596 move-object v3, v4
  0598 goto +8h
  059a invoke-virtual v5, Ljava/util/ArrayList;->isEmpty()Z
  05a0 move-result v4
  05a2 if-nez v4, +003h
  05a6 move-object v3, v5
  05a8 invoke-virtual v3, Ljava/util/ArrayList;->size()I
  05ae move-result v4
  05b0 if-le v4, v10, +03bh
  05b4 new-instance v4, Lcom/personal/aihub/AudioBanks$1;
  05b8 invoke-direct v4, v8, Lcom/personal/aihub/AudioBanks$1;-><init>(Lcom/personal/aihub/AudioBanks;)V
  05be invoke-virtual v3, v4, Ljava/util/ArrayList;->sort(Ljava/util/Comparator;)V
  05c4 new-instance v4, Ljava/util/ArrayList;
  05c8 invoke-direct v4, Ljava/util/ArrayList;-><init>()V
  05ce invoke-virtual v3, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
  05d4 move-result-object v3
  05d6 invoke-interface v3, Ljava/util/Iterator;->hasNext()Z
  05dc move-result v5
  05de if-eqz v5, +023h
  05e2 invoke-interface v3, Ljava/util/Iterator;->next()Ljava/lang/Object;
  05e8 move-result-object v5
  05ea check-cast v5, Lcom/personal/aihub/AudioBanks$Candidate;
  05ee invoke-virtual v4, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
  05f4 move-result-object v6
  05f6 invoke-interface v6, Ljava/util/Iterator;->hasNext()Z
  05fc move-result v7
  05fe if-nez v7, +006h
  0602 invoke-virtual v4, v5, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0608 goto -19h
  060a invoke-interface v6, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0610 move-result-object v7
  0612 check-cast v7, Lcom/personal/aihub/AudioBanks$Candidate;
  0616 invoke-direct v8, v7, v5, Lcom/personal/aihub/AudioBanks;->identical(Lcom/personal/aihub/AudioBanks$Candidate; Lcom/personal/aihub/AudioBanks$Candidate;)Z
  061c move-result v7
  061e if-eqz v7, -014h
  0622 goto -26h
  0624 move-object v3, v4
  0626 invoke-virtual v3, Ljava/util/ArrayList;->size()I
  062c move-result v4
  062e if-eq v4, v10, +054h
  0632 invoke-virtual v3, v11, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;
  0638 move-result-object v3
  063a check-cast v3, Lcom/personal/aihub/AudioBanks$Candidate;
  063e invoke-virtual v1, Lorg/json/JSONArray;->length()I
  0644 move-result v4
  0646 const/16 v5, 64
  064a if-ge v4, v5, +153h
  064e new-instance v4, Ljava/lang/StringBuilder;
  0652 invoke-direct v4, Ljava/lang/StringBuilder;-><init>()V
  0658 const-string v5, "More than one imported "
  065c invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0662 iget-object v5, v3, Lcom/personal/aihub/AudioBanks$Candidate;->identity Lcom/personal/aihub/AudioBanks$Identity;
  0666 iget-object v5, v5, Lcom/personal/aihub/AudioBanks$Identity;->kind Ljava/lang/String;
  066a invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0670 const-string v5, " bank supplies "
  0674 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  067a iget-object v5, v3, Lcom/personal/aihub/AudioBanks$Candidate;->identity Lcom/personal/aihub/AudioBanks$Identity;
  067e iget-object v5, v5, Lcom/personal/aihub/AudioBanks$Identity;->pkg Ljava/lang/String;
  0682 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0688 const-string v5, " ("
  068c invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0692 iget-object v5, v3, Lcom/personal/aihub/AudioBanks$Candidate;->identity Lcom/personal/aihub/AudioBanks$Identity;
  0696 iget-object v5, v5, Lcom/personal/aihub/AudioBanks$Identity;->locale Ljava/lang/String;
  069a invoke-virtual v5, Ljava/lang/String;->isEmpty()Z
  06a0 move-result v5
  06a2 if-eqz v5, +005h
  06a6 const-string v3, "default"
  06aa goto +5h
  06ac iget-object v3, v3, Lcom/personal/aihub/AudioBanks$Candidate;->identity Lcom/personal/aihub/AudioBanks$Identity;
  06b0 iget-object v3, v3, Lcom/personal/aihub/AudioBanks$Identity;->locale Ljava/lang/String;
  06b4 invoke-virtual v4, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  06ba const-string v3, "). Select a single source collection to preview it."
  06be invoke-virtual v4, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  06c4 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  06ca move-result-object v3
  06cc invoke-virtual v1, v3, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  06d2 goto/16 +10fh
  06d6 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  06dc move-result v4
  06de const/16 v5, 4096
  06e2 if-ge v4, v5, +10ah
  06e6 invoke-virtual v3, v11, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;
  06ec move-result-object v3
  06ee check-cast v3, Lcom/personal/aihub/AudioBanks$Candidate;
  06f2 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  06f8 move-result-object v4
  06fa invoke-virtual v4, Ljava/util/UUID;->toString()Ljava/lang/String;
  0700 move-result-object v4
  0702 const-string v5, "-"
  0706 const-string v6, ""
  070a invoke-virtual v4, v5, v6, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  0710 move-result-object v4
  0712 new-instance v5, Lorg/json/JSONObject;
  0716 invoke-direct v5, Lorg/json/JSONObject;-><init>()V
  071c const-string v6, "id"
  0720 invoke-virtual v5, v6, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0726 move-result-object v5
  0728 const-string v6, "kind"
  072c iget-object v7, v3, Lcom/personal/aihub/AudioBanks$Candidate;->identity Lcom/personal/aihub/AudioBanks$Identity;
  0730 iget-object v7, v7, Lcom/personal/aihub/AudioBanks$Identity;->kind Ljava/lang/String;
  0734 invoke-virtual v5, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  073a move-result-object v5
  073c const-string v6, "package"
  0740 iget-object v7, v3, Lcom/personal/aihub/AudioBanks$Candidate;->identity Lcom/personal/aihub/AudioBanks$Identity;
  0744 iget-object v7, v7, Lcom/personal/aihub/AudioBanks$Identity;->pkg Ljava/lang/String;
  0748 invoke-virtual v5, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  074e move-result-object v5
  0750 const-string v6, "locale"
  0754 iget-object v7, v3, Lcom/personal/aihub/AudioBanks$Candidate;->identity Lcom/personal/aihub/AudioBanks$Identity;
  0758 iget-object v7, v7, Lcom/personal/aihub/AudioBanks$Identity;->locale Ljava/lang/String;
  075c invoke-virtual v5, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0762 move-result-object v5
  0764 const-string v6, "acb"
  0768 new-instance v7, Lorg/json/JSONObject;
  076c invoke-direct v7, Lorg/json/JSONObject;-><init>()V
  0772 const-string v12, "url"
  0776 new-instance v13, Ljava/lang/StringBuilder;
  077a invoke-direct v13, Ljava/lang/StringBuilder;-><init>()V
  0780 const-string v14, "/_forge/audio-bank-assets/"
  0784 invoke-virtual v13, v14, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  078a invoke-virtual v13, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0790 const-string v14, ".acb"
  0794 invoke-virtual v13, v14, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  079a invoke-virtual v13, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  07a0 move-result-object v13
  07a2 invoke-virtual v7, v12, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  07a8 move-result-object v7
  07aa const-string v12, "size"
  07ae iget-object v13, v3, Lcom/personal/aihub/AudioBanks$Candidate;->acb Ljava/io/File;
  07b2 invoke-virtual v13, Ljava/io/File;->length()J
  07b8 move-result-wide v13
  07ba invoke-virtual v7, v12, v13, v14, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  07c0 move-result-object v7
  07c2 invoke-virtual v5, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  07c8 move-result-object v5
  07ca iget-object v6, v8, Lcom/personal/aihub/AudioBanks;->records Ljava/util/Map;
  07ce new-instance v7, Ljava/lang/StringBuilder;
  07d2 invoke-direct v7, Ljava/lang/StringBuilder;-><init>()V
  07d8 invoke-static v4, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  07de move-result-object v12
  07e0 invoke-virtual v7, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  07e6 const-string v12, ".acb"
  07ea invoke-virtual v7, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  07f0 invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  07f6 move-result-object v7
  07f8 new-instance v14, Lcom/personal/aihub/AudioBanks$Record;
  07fc iget-object v13, v3, Lcom/personal/aihub/AudioBanks$Candidate;->key Ljava/lang/String;
  0800 iget-object v12, v3, Lcom/personal/aihub/AudioBanks$Candidate;->acb Ljava/io/File;
  0804 invoke-virtual v12, Ljava/io/File;->length()J
  080a move-result-wide v15
  080c const-wide/32 v17, 33554432
  0812 move-object v12, v14
  0814 move-object v11, v14
  0816 move-wide v14, v15
  0818 move-wide/from16 v16, v17
  081c invoke-direct/range v12 ... v17, Lcom/personal/aihub/AudioBanks$Record;-><init>(Ljava/lang/String; J J)V
  0822 invoke-interface v6, v7, v11, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0828 iget-object v6, v3, Lcom/personal/aihub/AudioBanks$Candidate;->awb Ljava/io/File;
  082c if-eqz v6, +05fh
  0830 const-string v6, "awb"
  0834 new-instance v7, Lorg/json/JSONObject;
  0838 invoke-direct v7, Lorg/json/JSONObject;-><init>()V
  083e const-string v11, "url"
  0842 new-instance v12, Ljava/lang/StringBuilder;
  0846 invoke-direct v12, Ljava/lang/StringBuilder;-><init>()V
  084c const-string v13, "/_forge/audio-bank-assets/"
  0850 invoke-virtual v12, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0856 invoke-virtual v12, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  085c const-string v13, ".awb"
  0860 invoke-virtual v12, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0866 invoke-virtual v12, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  086c move-result-object v12
  086e invoke-virtual v7, v11, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0874 move-result-object v7
  0876 const-string v11, "size"
  087a iget-object v12, v3, Lcom/personal/aihub/AudioBanks$Candidate;->awb Ljava/io/File;
  087e invoke-virtual v12, Ljava/io/File;->length()J
  0884 move-result-wide v12
  0886 invoke-virtual v7, v11, v12, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  088c move-result-object v7
  088e invoke-virtual v5, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0894 iget-object v6, v8, Lcom/personal/aihub/AudioBanks;->records Ljava/util/Map;
  0898 new-instance v7, Ljava/lang/StringBuilder;
  089c invoke-direct v7, Ljava/lang/StringBuilder;-><init>()V
  08a2 invoke-static v4, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  08a8 move-result-object v4
  08aa invoke-virtual v7, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  08b0 const-string v4, ".awb"
  08b4 invoke-virtual v7, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  08ba invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  08c0 move-result-object v4
  08c2 new-instance v7, Lcom/personal/aihub/AudioBanks$Record;
  08c6 iget-object v12, v3, Lcom/personal/aihub/AudioBanks$Candidate;->awbKey Ljava/lang/String;
  08ca iget-object v3, v3, Lcom/personal/aihub/AudioBanks$Candidate;->awb Ljava/io/File;
  08ce invoke-virtual v3, Ljava/io/File;->length()J
  08d4 move-result-wide v13
  08d6 const-wide/32 v15, 167772160
  08dc move-object v11, v7
  08de invoke-direct/range v11 ... v16, Lcom/personal/aihub/AudioBanks$Record;-><init>(Ljava/lang/String; J J)V
  08e4 invoke-interface v6, v4, v7, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  08ea invoke-virtual v0, v5, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  08f0 const/4 v11, 0
  08f2 goto/16 -1fah
  08f6 new-instance v0, Ljava/io/IOException;
  08fa const-string v1, "Imported audio discovery exceeds its 4,096-bank limit"
  08fe invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0904 throw v0
  0906 new-instance v2, Lorg/json/JSONObject;
  090a invoke-direct v2, Lorg/json/JSONObject;-><init>()V
  0910 const-string v3, "version"
  0914 invoke-virtual v2, v3, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  091a move-result-object v2
  091c const-string v3, "banks"
  0920 invoke-virtual v2, v3, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0926 move-result-object v0
  0928 const-string v2, "warnings"
  092c invoke-virtual v0, v2, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0932 move-result-object v0
  0934 iput-object v0, v8, Lcom/personal/aihub/AudioBanks;->cached Lorg/json/JSONObject;
  0938 new-instance v0, Lorg/json/JSONObject;
  093c iget-object v1, v8, Lcom/personal/aihub/AudioBanks;->cached Lorg/json/JSONObject;
  0940 invoke-virtual v1, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0946 move-result-object v1
  0948 invoke-direct v0, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  094e monitor-exit v19
  0950 return-object v0
  0952 new-instance v0, Ljava/io/IOException;
  0956 const-string v1, "Imported audio folder cannot be read"
  095a invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0960 throw v0
  0962 new-instance v0, Ljava/io/IOException;
  0966 const-string v1, "Invalid imported audio folder"
  096a invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0970 throw v0
  0972 new-instance v0, Lorg/json/JSONObject;
  0976 invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  097c const-string v1, "version"
  0980 invoke-virtual v0, v1, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0986 move-result-object v0
  0988 const-string v1, "banks"
  098c new-instance v2, Lorg/json/JSONArray;
  0990 invoke-direct v2, Lorg/json/JSONArray;-><init>()V
  0996 invoke-virtual v0, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  099c move-result-object v0
  099e const-string v1, "warnings"
  09a2 new-instance v2, Lorg/json/JSONArray;
  09a6 invoke-direct v2, Lorg/json/JSONArray;-><init>()V
  09ac invoke-virtual v0, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  09b2 move-result-object v0
  09b4 iput-object v0, v8, Lcom/personal/aihub/AudioBanks;->cached Lorg/json/JSONObject;
  09b8 new-instance v0, Lorg/json/JSONObject;
  09bc iget-object v1, v8, Lcom/personal/aihub/AudioBanks;->cached Lorg/json/JSONObject;
  09c0 invoke-virtual v1, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  09c6 move-result-object v1
  09c8 invoke-direct v0, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  09ce monitor-exit v19
  09d0 return-object v0
  09d2 new-instance v0, Ljava/io/IOException;
  09d6 const-string v1, "Invalid imported audio folder"
  09da invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  09e0 throw v0
  09e2 new-instance v0, Ljava/io/IOException;
  09e6 const-string v1, "This audio preview has closed"
  09ea invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  09f0 throw v0
  09f2 move-exception v0
  09f4 monitor-exit v19
  09f6 throw v0
.end method

.method close()V
  0000 monitor-enter v1
  0002 const/4 v0, 1
  0004 iput-boolean v0, v1, Lcom/personal/aihub/AudioBanks;->closed Z
  0008 iget-object v0, v1, Lcom/personal/aihub/AudioBanks;->records Ljava/util/Map;
  000c invoke-interface v0, Ljava/util/Map;->clear()V
  0012 const/4 v0, 0
  0014 iput-object v0, v1, Lcom/personal/aihub/AudioBanks;->cached Lorg/json/JSONObject;
  0018 monitor-exit v1
  001a return-void 
  001c move-exception v0
  001e monitor-exit v1
  0020 throw v0
.end method

.method resolve(Ljava/lang/String;)Ljava/io/File;
  0000 monitor-enter v5
  0002 invoke-static v6, Lcom/personal/aihub/AudioBanks;->assetRoute(Ljava/lang/String;)Ljava/lang/String;
  0008 move-result-object v6
  000a if-eqz v6, +02dh
  000e invoke-virtual v5, Lcom/personal/aihub/AudioBanks;->catalogue()Lorg/json/JSONObject;
  0014 iget-object v0, v5, Lcom/personal/aihub/AudioBanks;->records Ljava/util/Map;
  0018 invoke-interface v0, v6, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  001e move-result-object v6
  0020 check-cast v6, Lcom/personal/aihub/AudioBanks$Record;
  0024 if-eqz v6, +020h
  0028 iget-object v0, v6, Lcom/personal/aihub/AudioBanks$Record;->key Ljava/lang/String;
  002c iget-wide v1, v6, Lcom/personal/aihub/AudioBanks$Record;->max J
  0030 const/4 v3, 0
  0032 invoke-direct v5, v0, v1, v2, v3, Lcom/personal/aihub/AudioBanks;->checked(Ljava/lang/String; J Z)Ljava/io/File;
  0038 move-result-object v0
  003a if-eqz v0, +00dh
  003e invoke-virtual v0, Ljava/io/File;->length()J
  0044 move-result-wide v1
  0046 iget-wide v3, v6, Lcom/personal/aihub/AudioBanks$Record;->size J
  004a cmp-long v6, v1, v3
  004e if-nez v6, +003h
  0052 goto +ah
  0054 new-instance v6, Ljava/io/IOException;
  0058 const-string v0, "The selected imported audio bank changed or is unavailable"
  005c invoke-direct v6, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0062 throw v6
  0064 const/4 v0, 0
  0066 monitor-exit v5
  0068 return-object v0
  006a move-exception v6
  006c monitor-exit v5
  006e throw v6
.end method