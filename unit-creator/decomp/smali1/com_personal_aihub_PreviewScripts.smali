.class Lcom/personal/aihub/PreviewScripts;
.super Ljava/lang/Object;
.field PATH Ljava/util/regex/Pattern;

.method <clinit>()V
  0000 const-string v0, "(?i)ab_script/[a-z0-9_/-]+\.lua"
  0004 invoke-static v0, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;)Ljava/util/regex/Pattern;
  000a move-result-object v0
  000c sput-object v0, Lcom/personal/aihub/PreviewScripts;->PATH Ljava/util/regex/Pattern;
  0010 return-void 
.end method

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method add(Ljava/util/Set; Lorg/json/JSONArray;)V
  0000 if-nez v4, +003h
  0004 return-void 
  0006 const/4 v0, 0
  0008 invoke-virtual v4, Lorg/json/JSONArray;->length()I
  000e move-result v1
  0010 if-ge v0, v1, +028h
  0014 invoke-virtual v4, v0, Lorg/json/JSONArray;->opt(I)Ljava/lang/Object;
  001a move-result-object v1
  001c instance-of v2, v1, Lorg/json/JSONObject;
  0020 if-eqz v2, +00bh
  0024 check-cast v1, Lorg/json/JSONObject;
  0028 const-string v2, "path"
  002c invoke-virtual v1, v2, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0032 move-result-object v1
  0034 goto +ah
  0036 instance-of v2, v1, Ljava/lang/String;
  003a if-eqz v2, +005h
  003e check-cast v1, Ljava/lang/String;
  0042 goto +3h
  0044 const-string v1, ""
  0048 invoke-static v1, Lcom/personal/aihub/PreviewScripts;->valid(Ljava/lang/String;)Z
  004e move-result v2
  0050 if-eqz v2, +005h
  0054 invoke-interface v3, v1, Ljava/util/Set;->add(Ljava/lang/Object;)Z
  005a add-int/lit8 v0, v0, 1
  005e goto -2bh
  0060 return-void 
.end method

.method imported(Ljava/io/File; Ljava/util/Set;)V
  0000 if-eqz v14, +086h
  0004 invoke-virtual v14, Ljava/io/File;->exists()Z
  000a move-result v0
  000c if-nez v0, +004h
  0010 goto/16 +07eh
  0014 invoke-virtual v14, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  001a move-result-object v0
  001c invoke-static v0, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  0022 move-result v0
  0024 if-nez v0, +06ch
  0028 invoke-virtual v14, Ljava/io/File;->isDirectory()Z
  002e move-result v0
  0030 if-eqz v0, +066h
  0034 invoke-virtual v14, Ljava/io/File;->listFiles()[Ljava/io/File;
  003a move-result-object v0
  003c if-eqz v0, +058h
  0040 array-length v1, v0
  0042 const/16 v2, 4096
  0046 if-gt v1, v2, +04bh
  004a const/4 v1, 1
  004c new-array v1, v1, [I
  0050 array-length v8, v0
  0052 const/4 v9, 0
  0054 move v10, v9
  0056 if-ge v10, v8, +042h
  005a aget-object v11, v0, v10
  005e invoke-virtual v11, Ljava/io/File;->isDirectory()Z
  0064 move-result v2
  0066 if-eqz v2, +037h
  006a invoke-virtual v11, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0070 move-result-object v2
  0072 invoke-static v2, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  0078 move-result v2
  007a if-nez v2, +02dh
  007e invoke-virtual v11, Ljava/io/File;->getName()Ljava/lang/String;
  0084 move-result-object v2
  0086 invoke-static v2, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  008c move-result v2
  008e if-eqz v2, +023h
  0092 const-string v2, "files/lua/ab_script"
  0096 const-string v3, "tutorial0/lua/ab_script"
  009a const-string v4, "lua/ab_script"
  009e filled-new-array v4, v2, v3, [Ljava/lang/String;
  00a4 move-result-object v12
  00a6 move v13, v9
  00a8 const/4 v2, 3
  00aa if-ge v13, v2, +015h
  00ae new-instance v2, Ljava/io/File;
  00b2 aget-object v3, v12, v13
  00b6 invoke-direct v2, v11, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00bc const-string v3, "ab_script"
  00c0 const/4 v6, 0
  00c2 move-object v4, v15
  00c4 move-object v5, v1
  00c6 move-object v7, v14
  00c8 invoke-static/range v2 ... v7, Lcom/personal/aihub/PreviewScripts;->walk(Ljava/io/File; Ljava/lang/String; Ljava/util/Set; [I I Ljava/io/File;)V
  00ce add-int/lit8 v13, v13, 1
  00d2 goto -15h
  00d4 add-int/lit8 v10, v10, 1
  00d8 goto -41h
  00da return-void 
  00dc new-instance v14, Ljava/io/IOException;
  00e0 const-string v15, "Too many imported animation collections"
  00e4 invoke-direct v14, v15, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00ea throw v14
  00ec new-instance v14, Ljava/io/IOException;
  00f0 const-string v15, "Imported animations cannot be read"
  00f4 invoke-direct v14, v15, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00fa throw v14
  00fc new-instance v14, Ljava/io/IOException;
  0100 const-string v15, "Invalid imported animation folder"
  0104 invoke-direct v14, v15, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  010a throw v14
  010c return-void 
.end method

.method listing(Landroid/content/Context; Ljava/io/File;)Lorg/json/JSONObject;
  0000 invoke-virtual v9, Landroid/content/Context;->getAssets()Landroid/content/res/AssetManager;
  0006 move-result-object v9
  0008 const-string v0, "ui/data/preview-script-index.json"
  000c invoke-virtual v9, v0, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;
  0012 move-result-object v9
  0014 new-instance v0, Ljava/io/ByteArrayOutputStream;
  0018 invoke-direct v0, Ljava/io/ByteArrayOutputStream;-><init>()V
  001e const/16 v1, 8192
  0022 new-array v1, v1, [B
  0026 invoke-virtual v9, v1, Ljava/io/InputStream;->read([B)I
  002c move-result v2
  002e const/4 v3, -1
  0030 const/4 v4, 0
  0032 if-eq v2, v3, +017h
  0036 invoke-virtual v0, Ljava/io/ByteArrayOutputStream;->size()I
  003c move-result v3
  003e add-int/2addr v3, v2
  0040 const/high16 v5, 2097152
  0044 if-gt v3, v5, +006h
  0048 invoke-virtual v0, v1, v4, v2, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  004e goto -14h
  0050 new-instance v10, Ljava/io/IOException;
  0054 const-string v1, "The packaged script index is too large"
  0058 invoke-direct v10, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  005e throw v10
  0060 new-instance v1, Lorg/json/JSONObject;
  0064 new-instance v2, Ljava/lang/String;
  0068 invoke-virtual v0, Ljava/io/ByteArrayOutputStream;->toByteArray()[B
  006e move-result-object v3
  0070 sget-object v5, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0074 invoke-direct v2, v3, v5, Ljava/lang/String;-><init>([B Ljava/nio/charset/Charset;)V
  007a invoke-direct v1, v2, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0080 invoke-virtual v0, Ljava/io/ByteArrayOutputStream;->close()V
  0086 if-eqz v9, +005h
  008a invoke-virtual v9, Ljava/io/InputStream;->close()V
  0090 const-string v9, "schemaVersion"
  0094 invoke-virtual v1, v9, Lorg/json/JSONObject;->optInt(Ljava/lang/String;)I
  009a move-result v9
  009c const/4 v0, 1
  009e if-ne v9, v0, +065h
  00a2 new-instance v9, Ljava/util/TreeSet;
  00a6 invoke-direct v9, Ljava/util/TreeSet;-><init>()V
  00ac const-string v2, "scripts"
  00b0 invoke-virtual v1, v2, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  00b6 move-result-object v3
  00b8 invoke-static v9, v3, Lcom/personal/aihub/PreviewScripts;->add(Ljava/util/Set; Lorg/json/JSONArray;)V
  00be invoke-virtual v9, Ljava/util/TreeSet;->isEmpty()Z
  00c4 move-result v3
  00c6 if-nez v3, +049h
  00ca invoke-virtual v9, Ljava/util/TreeSet;->size()I
  00d0 move-result v3
  00d2 invoke-static v10, v9, Lcom/personal/aihub/PreviewScripts;->imported(Ljava/io/File; Ljava/util/Set;)V
  00d8 new-instance v10, Lorg/json/JSONArray;
  00dc invoke-direct v10, Lorg/json/JSONArray;-><init>()V
  00e2 invoke-virtual v9, Ljava/util/TreeSet;->iterator()Ljava/util/Iterator;
  00e8 move-result-object v5
  00ea invoke-interface v5, Ljava/util/Iterator;->hasNext()Z
  00f0 move-result v6
  00f2 if-eqz v6, +017h
  00f6 invoke-interface v5, Ljava/util/Iterator;->next()Ljava/lang/Object;
  00fc move-result-object v6
  00fe check-cast v6, Ljava/lang/String;
  0102 new-instance v7, Lorg/json/JSONObject;
  0106 invoke-direct v7, Lorg/json/JSONObject;-><init>()V
  010c const-string v8, "path"
  0110 invoke-virtual v7, v8, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0116 move-result-object v6
  0118 invoke-virtual v10, v6, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  011e goto -1ah
  0120 invoke-virtual v1, v2, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0126 move-result-object v1
  0128 const-string v2, "count"
  012c invoke-virtual v10, Lorg/json/JSONArray;->length()I
  0132 move-result v10
  0134 invoke-virtual v1, v2, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  013a move-result-object v10
  013c invoke-virtual v9, Ljava/util/TreeSet;->size()I
  0142 move-result v9
  0144 if-le v9, v3, +003h
  0148 move v4, v0
  014a const-string v9, "includesImported"
  014e invoke-virtual v10, v9, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0154 move-result-object v9
  0156 return-object v9
  0158 new-instance v9, Ljava/io/IOException;
  015c const-string v10, "The packaged animation catalog is empty"
  0160 invoke-direct v9, v10, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0166 throw v9
  0168 new-instance v9, Ljava/io/IOException;
  016c const-string v10, "Update Dokkan Unit Creator to load the packaged animation catalog"
  0170 invoke-direct v9, v10, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0176 throw v9
  0178 move-exception v10
  017a invoke-virtual v0, Ljava/io/ByteArrayOutputStream;->close()V
  0180 goto +5h
  0182 move-exception v0
  0184 invoke-virtual v10, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  018a throw v10
  018c move-exception v10
  018e if-eqz v9, +00ah
  0192 invoke-virtual v9, Ljava/io/InputStream;->close()V
  0198 goto +5h
  019a move-exception v9
  019c invoke-virtual v10, v9, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  01a2 throw v10
.end method

.method valid(Ljava/lang/String;)Z
  0000 if-eqz v2, +01eh
  0004 invoke-virtual v2, Ljava/lang/String;->length()I
  000a move-result v0
  000c const/16 v1, 240
  0010 if-ge v0, v1, +016h
  0014 sget-object v0, Lcom/personal/aihub/PreviewScripts;->PATH Ljava/util/regex/Pattern;
  0018 invoke-virtual v0, v2, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  001e move-result-object v0
  0020 invoke-virtual v0, Ljava/util/regex/Matcher;->matches()Z
  0026 move-result v0
  0028 if-eqz v0, +00ah
  002c invoke-static v2, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  0032 move-result v2
  0034 if-eqz v2, +004h
  0038 const/4 v2, 1
  003a goto +2h
  003c const/4 v2, 0
  003e return v2
.end method

.method walk(Ljava/io/File; Ljava/lang/String; Ljava/util/Set; [I I Ljava/io/File;)V
  0000 const/16 v0, 24
  0004 if-gt v14, v0, +0c5h
  0008 invoke-virtual v10, Ljava/io/File;->exists()Z
  000e move-result v0
  0010 if-nez v0, +004h
  0014 goto/16 +0bdh
  0018 move-object v0, v10
  001a const-string v1, "Imported animations cannot use symbolic links"
  001e if-eqz v0, +01dh
  0022 invoke-virtual v0, v15, Ljava/io/File;->equals(Ljava/lang/Object;)Z
  0028 move-result v2
  002a if-nez v2, +017h
  002e invoke-virtual v0, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0034 move-result-object v2
  0036 invoke-static v2, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  003c move-result v2
  003e if-nez v2, +007h
  0042 invoke-virtual v0, Ljava/io/File;->getParentFile()Ljava/io/File;
  0048 move-result-object v0
  004a goto -18h
  004c new-instance v10, Ljava/io/IOException;
  0050 invoke-direct v10, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0056 throw v10
  0058 invoke-virtual v10, Ljava/io/File;->isDirectory()Z
  005e move-result v0
  0060 if-eqz v0, +097h
  0064 invoke-virtual v10, Ljava/io/File;->listFiles()[Ljava/io/File;
  006a move-result-object v10
  006c if-eqz v10, +089h
  0070 array-length v0, v10
  0072 const/4 v2, 0
  0074 move v3, v2
  0076 if-ge v3, v0, +08ch
  007a aget-object v4, v10, v3
  007e aget v5, v13, v2
  0082 add-int/lit8 v5, v5, 1
  0086 aput v5, v13, v2
  008a const v6, 50000
  0090 if-gt v5, v6, +06fh
  0094 invoke-virtual v4, Ljava/io/File;->getName()Ljava/lang/String;
  009a move-result-object v5
  009c invoke-static v5, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  00a2 move-result v5
  00a4 if-eqz v5, +062h
  00a8 invoke-virtual v4, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  00ae move-result-object v5
  00b0 invoke-static v5, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  00b6 move-result v5
  00b8 if-nez v5, +052h
  00bc new-instance v5, Ljava/lang/StringBuilder;
  00c0 invoke-direct v5, Ljava/lang/StringBuilder;-><init>()V
  00c6 invoke-static v11, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  00cc move-result-object v6
  00ce invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00d4 const-string v6, "/"
  00d8 invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00de invoke-virtual v4, Ljava/io/File;->getName()Ljava/lang/String;
  00e4 move-result-object v6
  00e6 invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00ec invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00f2 move-result-object v5
  00f4 invoke-virtual v4, Ljava/io/File;->isDirectory()Z
  00fa move-result v6
  00fc if-eqz v6, +00bh
  0100 add-int/lit8 v8, v14, 1
  0104 move-object v6, v12
  0106 move-object v7, v13
  0108 move-object v9, v15
  010a invoke-static/range v4 ... v9, Lcom/personal/aihub/PreviewScripts;->walk(Ljava/io/File; Ljava/lang/String; Ljava/util/Set; [I I Ljava/io/File;)V
  0110 goto +2ch
  0112 invoke-virtual v4, Ljava/io/File;->isFile()Z
  0118 move-result v6
  011a if-eqz v6, +027h
  011e invoke-virtual v4, Ljava/io/File;->length()J
  0124 move-result-wide v6
  0126 const-wide/16 v8, 0
  012a cmp-long v6, v6, v8
  012e if-lez v6, +01dh
  0132 invoke-virtual v4, Ljava/io/File;->length()J
  0138 move-result-wide v6
  013a const-wide/32 v8, 2097152
  0140 cmp-long v4, v6, v8
  0144 if-gtz v4, +012h
  0148 invoke-static v5, Lcom/personal/aihub/PreviewScripts;->valid(Ljava/lang/String;)Z
  014e move-result v4
  0150 if-eqz v4, +00ch
  0154 invoke-interface v12, v5, Ljava/util/Set;->add(Ljava/lang/Object;)Z
  015a goto +7h
  015c new-instance v10, Ljava/io/IOException;
  0160 invoke-direct v10, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0166 throw v10
  0168 add-int/lit8 v3, v3, 1
  016c goto -7bh
  016e new-instance v10, Ljava/io/IOException;
  0172 const-string v11, "The imported animation catalog exceeds its 50,000-entry limit"
  0176 invoke-direct v10, v11, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  017c throw v10
  017e new-instance v10, Ljava/io/IOException;
  0182 const-string v11, "Imported animations cannot be read"
  0186 invoke-direct v10, v11, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  018c throw v10
  018e return-void 
.end method