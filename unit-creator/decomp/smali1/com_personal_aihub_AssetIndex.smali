.class Lcom/personal/aihub/AssetIndex;
.super Ljava/lang/Object;

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method lambda$0(Ljava/io/File;)Ljava/lang/String;
  0000 new-instance v0, Ljava/lang/StringBuilder;
  0004 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  000a invoke-virtual v2, Ljava/io/File;->getName()Ljava/lang/String;
  0010 move-result-object v1
  0012 invoke-static v1, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0018 move-result-object v1
  001a invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0020 invoke-virtual v2, Ljava/io/File;->isDirectory()Z
  0026 move-result v2
  0028 if-eqz v2, +005h
  002c const-string v2, "/"
  0030 goto +3h
  0032 const-string v2, ""
  0036 invoke-virtual v0, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  003c invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0042 move-result-object v2
  0044 return-object v2
.end method

.method list(Ljava/io/File; Lorg/json/JSONObject;)Lorg/json/JSONArray;
  0000 invoke-virtual v7, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0006 move-result-object v0
  0008 invoke-static v0, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  000e move-result v0
  0010 if-nez v0, +042h
  0014 invoke-virtual v7, Ljava/io/File;->isDirectory()Z
  001a move-result v0
  001c if-eqz v0, +03ch
  0020 new-instance v0, Lorg/json/JSONArray;
  0024 invoke-direct v0, Lorg/json/JSONArray;-><init>()V
  002a const-string v1, "query"
  002e invoke-virtual v8, v1, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0034 move-result-object v1
  0036 sget-object v2, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  003a invoke-virtual v1, v2, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  0040 move-result-object v3
  0042 const-string v1, "offset"
  0046 const/4 v2, 0
  0048 invoke-virtual v8, v1, v2, Lorg/json/JSONObject;->optInt(Ljava/lang/String; I)I
  004e move-result v1
  0050 invoke-static v2, v1, Ljava/lang/Math;->max(I I)I
  0056 move-result v1
  0058 filled-new-array v1, [I
  005e move-result-object v5
  0060 const-string v1, "limit"
  0064 const/16 v2, 100
  0068 invoke-virtual v8, v1, v2, Lorg/json/JSONObject;->optInt(Ljava/lang/String; I)I
  006e move-result v8
  0070 const/16 v1, 500
  0074 invoke-static v1, v8, Ljava/lang/Math;->min(I I)I
  007a move-result v8
  007c const/4 v1, 1
  007e invoke-static v1, v8, Ljava/lang/Math;->max(I I)I
  0084 move-result v6
  0086 move-object v1, v7
  0088 move-object v2, v7
  008a move-object v4, v0
  008c invoke-static/range v1 ... v6, Lcom/personal/aihub/AssetIndex;->walk(Ljava/io/File; Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray; [I I)V
  0092 return-object v0
  0094 new-instance v7, Ljava/io/IOException;
  0098 const-string v8, "The imported asset folder is unavailable."
  009c invoke-direct v7, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00a2 throw v7
.end method

.method walk(Ljava/io/File; Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray; [I I)V
  0000 invoke-virtual v10, Ljava/io/File;->listFiles()[Ljava/io/File;
  0006 move-result-object v10
  0008 if-nez v10, +003h
  000c return-void 
  000e new-instance v0, Lcom/personal/aihub/AssetIndex$1;
  0012 invoke-direct v0, Lcom/personal/aihub/AssetIndex$1;-><init>()V
  0018 invoke-static v0, Ljava/util/Comparator;->comparing(Ljava/util/function/Function;)Ljava/util/Comparator;
  001e move-result-object v0
  0020 invoke-static v10, v0, Ljava/util/Arrays;->sort([Ljava/lang/Object; Ljava/util/Comparator;)V
  0026 array-length v0, v10
  0028 const/4 v1, 0
  002a move v2, v1
  002c if-ge v2, v0, +0aeh
  0030 aget-object v4, v10, v2
  0034 invoke-virtual v12, Lorg/json/JSONArray;->length()I
  003a move-result v3
  003c if-lt v3, v14, +003h
  0040 return-void 
  0042 invoke-virtual v4, Ljava/io/File;->getName()Ljava/lang/String;
  0048 move-result-object v3
  004a const-string v5, "_databases"
  004e invoke-virtual v3, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0054 move-result v3
  0056 if-nez v3, +095h
  005a invoke-virtual v4, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0060 move-result-object v3
  0062 invoke-static v3, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  0068 move-result v3
  006a if-nez v3, +08bh
  006e invoke-virtual v4, Ljava/io/File;->isDirectory()Z
  0074 move-result v3
  0076 if-eqz v3, +00ch
  007a move-object v3, v9
  007c move-object v5, v11
  007e move-object v6, v12
  0080 move-object v7, v13
  0082 move v8, v14
  0084 invoke-static/range v3 ... v8, Lcom/personal/aihub/AssetIndex;->walk(Ljava/io/File; Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray; [I I)V
  008a goto/16 +07bh
  008e invoke-virtual v9, Ljava/io/File;->toURI()Ljava/net/URI;
  0094 move-result-object v3
  0096 invoke-virtual v4, Ljava/io/File;->toURI()Ljava/net/URI;
  009c move-result-object v5
  009e invoke-virtual v3, v5, Ljava/net/URI;->relativize(Ljava/net/URI;)Ljava/net/URI;
  00a4 move-result-object v3
  00a6 invoke-virtual v3, Ljava/net/URI;->getPath()Ljava/lang/String;
  00ac move-result-object v3
  00ae sget-object v5, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  00b2 invoke-virtual v3, v5, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  00b8 move-result-object v5
  00ba invoke-virtual v5, v11, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  00c0 move-result v5
  00c2 if-eqz v5, +05fh
  00c6 aget v5, v13, v1
  00ca if-lez v5, +007h
  00ce add-int/lit8 v5, v5, -1
  00d2 aput v5, v13, v1
  00d6 goto +55h
  00d8 new-instance v5, Lorg/json/JSONObject;
  00dc invoke-direct v5, Lorg/json/JSONObject;-><init>()V
  00e2 const-string v6, "key"
  00e6 invoke-virtual v5, v6, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00ec move-result-object v5
  00ee const-string v6, "/"
  00f2 invoke-virtual v3, v6, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  00f8 move-result v6
  00fa if-eqz v6, +00eh
  00fe const/16 v6, 47
  0102 invoke-virtual v3, v6, Ljava/lang/String;->indexOf(I)I
  0108 move-result v6
  010a add-int/lit8 v6, v6, 1
  010e invoke-virtual v3, v6, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0114 move-result-object v3
  0116 const-string v6, "^files/"
  011a const-string v7, ""
  011e invoke-virtual v3, v6, v7, Ljava/lang/String;->replaceFirst(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0124 move-result-object v3
  0126 const-string v6, "path"
  012a invoke-virtual v5, v6, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0130 move-result-object v3
  0132 const-string v5, "name"
  0136 invoke-virtual v4, Ljava/io/File;->getName()Ljava/lang/String;
  013c move-result-object v6
  013e invoke-virtual v3, v5, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0144 move-result-object v3
  0146 const-string v5, "size"
  014a invoke-virtual v4, Ljava/io/File;->length()J
  0150 move-result-wide v6
  0152 invoke-virtual v3, v5, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0158 move-result-object v3
  015a invoke-virtual v4, Ljava/io/File;->getName()Ljava/lang/String;
  0160 move-result-object v4
  0162 const-string v5, "(?i).*\.(png|jpe?g|webp|gif|bmp)$"
  0166 invoke-virtual v4, v5, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  016c move-result v4
  016e const-string v5, "image"
  0172 invoke-virtual v3, v5, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0178 move-result-object v3
  017a invoke-virtual v12, v3, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0180 add-int/lit8 v2, v2, 1
  0184 goto/16 -0ach
  0188 return-void 
.end method