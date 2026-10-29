.class Lcom/personal/aihub/ExportAssetAudit;
.super Ljava/lang/Object;

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method check(Ljava/io/File; Lorg/json/JSONArray;)Lorg/json/JSONArray;
  0000 move-object/from16 v0, v17
  0004 invoke-virtual/range v17, Lorg/json/JSONArray;->length()I
  000a move-result v1
  000c const/16 v2, 500
  0010 if-gt v1, v2, +11fh
  0014 invoke-virtual/range v16, Ljava/io/File;->isDirectory()Z
  001a move-result v1
  001c if-eqz v1, +119h
  0020 invoke-virtual/range v16, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0026 move-result-object v1
  0028 invoke-static v1, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  002e move-result v1
  0030 if-nez v1, +10fh
  0034 new-instance v1, Lorg/json/JSONArray;
  0038 invoke-direct v1, Lorg/json/JSONArray;-><init>()V
  003e new-instance v3, Ljava/lang/StringBuilder;
  0042 invoke-direct v3, Ljava/lang/StringBuilder;-><init>()V
  0048 invoke-virtual/range v16, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  004e move-result-object v4
  0050 invoke-virtual v3, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0056 sget-object v4, Ljava/io/File;->separator Ljava/lang/String;
  005a invoke-virtual v3, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0060 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0066 move-result-object v3
  0068 const/4 v4, 0
  006a move v5, v4
  006c invoke-virtual/range v17, Lorg/json/JSONArray;->length()I
  0072 move-result v6
  0074 if-ge v5, v6, +0ech
  0078 invoke-virtual v0, v5, Lorg/json/JSONArray;->get(I)Ljava/lang/Object;
  007e move-result-object v6
  0080 instance-of v6, v6, Ljava/lang/String;
  0084 const-string v7, "Invalid attachment key."
  0088 if-eqz v6, +0dch
  008c invoke-virtual v0, v5, Lorg/json/JSONArray;->getString(I)Ljava/lang/String;
  0092 move-result-object v6
  0094 invoke-virtual v6, Ljava/lang/String;->isEmpty()Z
  009a move-result v8
  009c if-nez v8, +0cch
  00a0 invoke-virtual v6, Ljava/lang/String;->length()I
  00a6 move-result v8
  00a8 if-gt v8, v2, +0c6h
  00ac const-string v8, "/"
  00b0 invoke-virtual v6, v8, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00b6 move-result v9
  00b8 if-nez v9, +0beh
  00bc const-string v9, ".*[\\:\x00-\x1f\x7f%].*"
  00c0 invoke-virtual v6, v9, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  00c6 move-result v9
  00c8 if-nez v9, +0b6h
  00cc const/4 v9, -1
  00ce invoke-virtual v6, v8, v9, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  00d4 move-result-object v8
  00d6 array-length v9, v8
  00d8 move-object/from16 v11, v16
  00dc move v10, v4
  00de if-ge v10, v9, +051h
  00e2 aget-object v12, v8, v10
  00e6 invoke-virtual v12, Ljava/lang/String;->isEmpty()Z
  00ec move-result v13
  00ee if-nez v13, +043h
  00f2 const-string v13, "."
  00f6 invoke-virtual v12, v13, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00fc move-result v13
  00fe if-nez v13, +03bh
  0102 const-string v13, "patches"
  0106 const-string v14, "exports"
  010a const-string v15, "_databases"
  010e const-string v2, "projects"
  0112 filled-new-array v15, v2, v13, v14, [Ljava/lang/String;
  0118 move-result-object v2
  011a invoke-static v2, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  0120 move-result-object v2
  0122 sget-object v13, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  0126 invoke-virtual v12, v13, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  012c move-result-object v13
  012e invoke-interface v2, v13, Ljava/util/List;->contains(Ljava/lang/Object;)Z
  0134 move-result v2
  0136 if-nez v2, +01fh
  013a new-instance v2, Ljava/io/File;
  013e invoke-direct v2, v11, v12, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0144 invoke-virtual v2, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  014a move-result-object v11
  014c invoke-static v11, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  0152 move-result v11
  0154 if-nez v11, +008h
  0158 add-int/lit8 v10, v10, 1
  015c move-object v11, v2
  015e const/16 v2, 500
  0162 goto -42h
  0164 new-instance v0, Ljava/io/IOException;
  0168 const-string v1, "Attached files cannot use symbolic links."
  016c invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0172 throw v0
  0174 new-instance v0, Ljava/io/IOException;
  0178 invoke-direct v0, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  017e throw v0
  0180 invoke-virtual v11, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  0186 move-result-object v2
  0188 invoke-virtual v2, v3, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  018e move-result v2
  0190 if-eqz v2, +04ah
  0194 invoke-virtual v11, Ljava/io/File;->isFile()Z
  019a move-result v2
  019c const-wide/16 v7, 0
  01a0 if-eqz v2, +007h
  01a4 invoke-virtual v11, Ljava/io/File;->length()J
  01aa move-result-wide v9
  01ac goto +2h
  01ae move-wide v9, v7
  01b0 new-instance v2, Lorg/json/JSONObject;
  01b4 invoke-direct v2, Lorg/json/JSONObject;-><init>()V
  01ba const-string v12, "key"
  01be invoke-virtual v2, v12, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01c4 move-result-object v2
  01c6 const-string v6, "bytes"
  01ca invoke-virtual v2, v6, v9, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  01d0 move-result-object v2
  01d2 invoke-virtual v11, Ljava/io/File;->isFile()Z
  01d8 move-result v6
  01da if-eqz v6, +015h
  01de invoke-virtual v11, Ljava/io/File;->canRead()Z
  01e4 move-result v6
  01e6 if-eqz v6, +00fh
  01ea cmp-long v6, v9, v7
  01ee if-lez v6, +00bh
  01f2 const-wide/32 v6, 536870912
  01f8 cmp-long v6, v9, v6
  01fc if-gtz v6, +004h
  0200 const/4 v6, 1
  0202 goto +2h
  0204 move v6, v4
  0206 const-string v7, "available"
  020a invoke-virtual v2, v7, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0210 move-result-object v2
  0212 invoke-virtual v1, v2, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0218 add-int/lit8 v5, v5, 1
  021c const/16 v2, 500
  0220 goto/16 -0dah
  0224 new-instance v0, Ljava/io/IOException;
  0228 const-string v1, "Invalid attachment location."
  022c invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0232 throw v0
  0234 new-instance v0, Ljava/io/IOException;
  0238 invoke-direct v0, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  023e throw v0
  0240 new-instance v0, Ljava/io/IOException;
  0244 invoke-direct v0, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  024a throw v0
  024c return-object v1
  024e new-instance v0, Ljava/io/IOException;
  0252 const-string v1, "The attached files could not be checked safely."
  0256 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  025c throw v0
.end method