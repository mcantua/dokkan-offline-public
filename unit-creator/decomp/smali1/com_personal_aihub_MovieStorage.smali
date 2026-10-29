.class Lcom/personal/aihub/MovieStorage;
.super Ljava/lang/Object;
.field CHUNK_LIMIT I
.field FILE_LIMIT J
.field ID Ljava/lang/String;
.field OWNER Ljava/lang/String;
.field TOTAL_LIMIT J
.field TTL J
.field clock Ljava/util/function/LongSupplier;
.field jobs Ljava/util/Map;
.field root Ljava/io/File;
.field staging Ljava/io/File;

.method <init>(Ljava/io/File;)V
  0000 new-instance v0, Lcom/personal/aihub/MovieStorage$1;
  0004 invoke-direct v0, Lcom/personal/aihub/MovieStorage$1;-><init>()V
  000a invoke-direct v1, v2, v0, Lcom/personal/aihub/MovieStorage;-><init>(Ljava/io/File; Ljava/util/function/LongSupplier;)V
  0010 return-void 
.end method

.method <init>(Ljava/io/File; Ljava/util/function/LongSupplier;)V
  0000 invoke-direct v7, Ljava/lang/Object;-><init>()V
  0006 new-instance v0, Ljava/util/LinkedHashMap;
  000a invoke-direct v0, Ljava/util/LinkedHashMap;-><init>()V
  0010 iput-object v0, v7, Lcom/personal/aihub/MovieStorage;->jobs Ljava/util/Map;
  0014 invoke-virtual v8, Ljava/io/File;->getAbsoluteFile()Ljava/io/File;
  001a move-result-object v8
  001c iput-object v8, v7, Lcom/personal/aihub/MovieStorage;->root Ljava/io/File;
  0020 iput-object v9, v7, Lcom/personal/aihub/MovieStorage;->clock Ljava/util/function/LongSupplier;
  0024 new-instance v9, Ljava/io/File;
  0028 invoke-virtual v8, Ljava/io/File;->getParentFile()Ljava/io/File;
  002e move-result-object v0
  0030 const-string v1, ".forge-movie-uploads-v1"
  0034 invoke-direct v9, v0, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  003a iput-object v9, v7, Lcom/personal/aihub/MovieStorage;->staging Ljava/io/File;
  003e invoke-static v8, Lcom/personal/aihub/MovieStorage;->directories(Ljava/io/File;)V
  0044 invoke-virtual v9, Ljava/io/File;->getParentFile()Ljava/io/File;
  004a move-result-object v8
  004c invoke-static v8, Lcom/personal/aihub/MovieStorage;->directories(Ljava/io/File;)V
  0052 invoke-virtual v9, Ljava/io/File;->mkdir()Z
  0058 move-result v8
  005a const/4 v0, 0
  005c const-string v1, "Dokkan Unit Forge movie uploads v1
"
  0060 const-string v2, ".owner"
  0064 if-eqz v8, +020h
  0068 new-instance v8, Ljava/io/File;
  006c invoke-direct v8, v9, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0072 invoke-virtual v8, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0078 move-result-object v8
  007a sget-object v3, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  007e invoke-virtual v1, v3, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0084 move-result-object v3
  0086 const/4 v4, 2
  0088 new-array v4, v4, [Ljava/nio/file/OpenOption;
  008c sget-object v5, Ljava/nio/file/StandardOpenOption;->CREATE_NEW Ljava/nio/file/StandardOpenOption;
  0090 aput-object v5, v4, v0
  0094 sget-object v5, Ljava/nio/file/StandardOpenOption;->WRITE Ljava/nio/file/StandardOpenOption;
  0098 const/4 v6, 1
  009a aput-object v5, v4, v6
  009e invoke-static v8, v3, v4, Ljava/nio/file/Files;->write(Ljava/nio/file/Path; [B [Ljava/nio/file/OpenOption;)Ljava/nio/file/Path;
  00a4 invoke-static v9, Lcom/personal/aihub/MovieStorage;->directories(Ljava/io/File;)V
  00aa new-instance v8, Ljava/io/File;
  00ae invoke-direct v8, v9, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00b4 invoke-virtual v8, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  00ba move-result-object v2
  00bc invoke-static v2, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  00c2 move-result v2
  00c4 if-nez v2, +061h
  00c8 invoke-virtual v8, Ljava/io/File;->isFile()Z
  00ce move-result v2
  00d0 if-eqz v2, +05bh
  00d4 invoke-virtual v8, Ljava/io/File;->length()J
  00da move-result-wide v2
  00dc const/16 v4, 35
  00e0 int-to-long v4, v4
  00e2 cmp-long v2, v2, v4
  00e6 if-nez v2, +050h
  00ea new-instance v2, Ljava/lang/String;
  00ee invoke-virtual v8, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  00f4 move-result-object v8
  00f6 invoke-static v8, Ljava/nio/file/Files;->readAllBytes(Ljava/nio/file/Path;)[B
  00fc move-result-object v8
  00fe sget-object v3, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0102 invoke-direct v2, v8, v3, Ljava/lang/String;-><init>([B Ljava/nio/charset/Charset;)V
  0108 invoke-virtual v2, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  010e move-result v8
  0110 if-eqz v8, +03bh
  0114 invoke-virtual v9, Ljava/io/File;->listFiles()[Ljava/io/File;
  011a move-result-object v8
  011c if-eqz v8, +02eh
  0120 array-length v9, v8
  0122 if-ge v0, v9, +02ah
  0126 aget-object v1, v8, v0
  012a invoke-virtual v1, Ljava/io/File;->getName()Ljava/lang/String;
  0130 move-result-object v2
  0132 const-string v3, "upload-[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.part"
  0136 invoke-virtual v2, v3, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  013c move-result v2
  013e if-eqz v2, +019h
  0142 invoke-virtual v1, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0148 move-result-object v2
  014a sget-object v3, Ljava/nio/file/LinkOption;->NOFOLLOW_LINKS Ljava/nio/file/LinkOption;
  014e filled-new-array v3, [Ljava/nio/file/LinkOption;
  0154 move-result-object v3
  0156 invoke-static v2, v3, Ljava/nio/file/Files;->isDirectory(Ljava/nio/file/Path; [Ljava/nio/file/LinkOption;)Z
  015c move-result v2
  015e if-nez v2, +009h
  0162 invoke-virtual v1, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0168 move-result-object v1
  016a invoke-static v1, Ljava/nio/file/Files;->delete(Ljava/nio/file/Path;)V
  0170 add-int/lit8 v0, v0, 1
  0174 goto -29h
  0176 return-void 
  0178 const-string v8, "The private upload folder is unavailable."
  017c invoke-static v8, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0182 move-result-object v8
  0184 throw v8
  0186 const-string v8, "The private upload folder is not owned by this app."
  018a invoke-static v8, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0190 move-result-object v8
  0192 throw v8
.end method

.method directories(Ljava/io/File;)V
  0000 invoke-virtual v3, Ljava/io/File;->getAbsoluteFile()Ljava/io/File;
  0006 move-result-object v0
  0008 invoke-virtual v0, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  000e move-result-object v0
  0010 invoke-interface v0, Ljava/nio/file/Path;->normalize()Ljava/nio/file/Path;
  0016 move-result-object v0
  0018 invoke-interface v0, Ljava/nio/file/Path;->getRoot()Ljava/nio/file/Path;
  001e move-result-object v0
  0020 invoke-virtual v3, Ljava/io/File;->getAbsoluteFile()Ljava/io/File;
  0026 move-result-object v3
  0028 invoke-virtual v3, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  002e move-result-object v3
  0030 invoke-interface v3, Ljava/nio/file/Path;->normalize()Ljava/nio/file/Path;
  0036 move-result-object v3
  0038 invoke-interface v3, Ljava/nio/file/Path;->iterator()Ljava/util/Iterator;
  003e move-result-object v3
  0040 invoke-interface v3, Ljava/util/Iterator;->hasNext()Z
  0046 move-result v1
  0048 if-eqz v1, +02ch
  004c invoke-interface v3, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0052 move-result-object v1
  0054 check-cast v1, Ljava/nio/file/Path;
  0058 invoke-interface v0, v1, Ljava/nio/file/Path;->resolve(Ljava/nio/file/Path;)Ljava/nio/file/Path;
  005e move-result-object v0
  0060 const-class v1, Ljava/nio/file/attribute/BasicFileAttributes;
  0064 sget-object v2, Ljava/nio/file/LinkOption;->NOFOLLOW_LINKS Ljava/nio/file/LinkOption;
  0068 filled-new-array v2, [Ljava/nio/file/LinkOption;
  006e move-result-object v2
  0070 invoke-static v0, v1, v2, Ljava/nio/file/Files;->readAttributes(Ljava/nio/file/Path; Ljava/lang/Class; [Ljava/nio/file/LinkOption;)Ljava/nio/file/attribute/BasicFileAttributes;
  0076 move-result-object v1
  0078 invoke-interface v1, Ljava/nio/file/attribute/BasicFileAttributes;->isDirectory()Z
  007e move-result v2
  0080 if-eqz v2, +009h
  0084 invoke-interface v1, Ljava/nio/file/attribute/BasicFileAttributes;->isSymbolicLink()Z
  008a move-result v1
  008c if-nez v1, +003h
  0090 goto -28h
  0092 const-string v3, "The private movie folder is unsafe."
  0096 invoke-static v3, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  009c move-result-object v3
  009e throw v3
  00a0 return-void 
.end method

.method discard(Ljava/lang/String;)V
  0000 iget-object v0, v1, Lcom/personal/aihub/MovieStorage;->jobs Ljava/util/Map;
  0004 invoke-interface v0, v2, Ljava/util/Map;->remove(Ljava/lang/Object;)Ljava/lang/Object;
  000a invoke-direct v1, v2, Lcom/personal/aihub/MovieStorage;->temporary(Ljava/lang/String;)Ljava/io/File;
  0010 move-result-object v2
  0012 invoke-virtual v2, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0018 move-result-object v2
  001a invoke-static v2, Ljava/nio/file/Files;->deleteIfExists(Ljava/nio/file/Path;)Z
  0020 return-void 
.end method

.method fail(Ljava/lang/String;)Ljava/io/IOException;
  0000 new-instance v0, Ljava/io/IOException;
  0004 new-instance v1, Ljava/lang/StringBuilder;
  0008 const-string v2, "Movie: "
  000c invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0012 invoke-virtual v1, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0018 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  001e move-result-object v3
  0020 invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0026 return-object v0
.end method

.method inspect(Ljava/io/File;)Lorg/json/JSONObject;
  0000 const-string v0, "stmid"
  0004 new-instance v8, Ljava/io/RandomAccessFile;
  0008 const-string v1, "r"
  000c move-object/from16 v2, v72
  0010 invoke-direct v8, v2, v1, Ljava/io/RandomAccessFile;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0016 invoke-virtual v8, Ljava/io/RandomAccessFile;->length()J
  001c move-result-wide v9
  001e const-wide/16 v11, 2048
  0022 cmp-long v1, v9, v11
  0026 if-ltz v1, +745h
  002a const-wide/32 v1, 100663296
  0030 cmp-long v1, v9, v1
  0034 if-gtz v1, +73eh
  0038 new-instance v13, Ljava/util/ArrayList;
  003c invoke-direct v13, Ljava/util/ArrayList;-><init>()V
  0042 new-instance v14, Ljava/util/ArrayList;
  0046 invoke-direct v14, Ljava/util/ArrayList;-><init>()V
  004c const/4 v1, 0
  004e const/4 v15, 0
  0050 const-wide/16 v16, 0
  0054 move-object v4, v1
  0056 move-object v5, v4
  0058 move-object v6, v5
  005a move-object v7, v6
  005c move v1, v15
  005e move/from16 v20, v1
  0062 move/from16 v23, v20
  0066 move/from16 v24, v23
  006a move/from16 v25, v24
  006e move/from16 v26, v25
  0072 move/from16 v27, v26
  0076 move-wide/from16 v2, v16
  007a move-wide/from16 v18, v2
  007e move-wide/from16 v21, v18
  0082 move-wide/from16 v28, v21
  0086 move-wide/from16 v30, v28
  008a move-wide/from16 v32, v30
  008e move-wide/from16 v34, v32
  0092 move-wide/from16 v36, v34
  0096 move-wide/from16 v38, v36
  009a cmp-long v40, v18, v9
  009e const-wide/16 v41, 36
  00a2 move-object/from16 v72, v7
  00a6 const-string v7, "filesize"
  00aa move-object/from16 v43, v7
  00ae const-string v7, "total_frames"
  00b2 move-object/from16 v44, v7
  00b6 const-string v7, "height"
  00ba move-object/from16 v45, v7
  00be const-string v7, "width"
  00c2 const-wide/16 v46, 32
  00c6 move-object/from16 v48, v7
  00ca const/4 v7, 3
  00cc const/4 v12, 1
  00ce if-gez v40, +59fh
  00d2 add-int/2addr v1, v12
  00d4 const v11, 70000
  00da if-gt v1, v11, +592h
  00de const/16 v11, 32
  00e2 move/from16 v51, v1
  00e6 move-object v1, v8
  00e8 move-wide/from16 v52, v2
  00ec move-wide/from16 v2, v18
  00f0 move-object/from16 v54, v4
  00f4 move v4, v11
  00f6 move-object v11, v5
  00f8 move-object/from16 v55, v6
  00fc move-wide v5, v9
  00fe invoke-static/range v1 ... v6, Lcom/personal/aihub/MovieStorage;->read(Ljava/io/RandomAccessFile; J I J)[B
  0104 move-result-object v1
  0106 const/4 v5, 4
  0108 invoke-static v1, v15, v5, Lcom/personal/aihub/MovieStorage;->text([B I I)Ljava/lang/String;
  010e move-result-object v2
  0110 invoke-static v1, v5, Lcom/personal/aihub/MovieStorage;->u32([B I)J
  0116 move-result-wide v3
  0118 const-wide/16 v56, 8
  011c add-long v56, v3, v56
  0120 const/16 v6, 8
  0124 invoke-static v1, v6, Lcom/personal/aihub/MovieStorage;->u16([B I)I
  012a move-result v3
  012c add-int/2addr v3, v6
  012e int-to-long v3, v3
  0130 sub-long v58, v56, v3
  0134 const/16 v5, 10
  0138 invoke-static v1, v5, Lcom/personal/aihub/MovieStorage;->u16([B I)I
  013e move-result v5
  0140 move-object/from16 v60, v13
  0144 int-to-long v12, v5
  0146 sub-long v12, v58, v12
  014a add-long v58, v18, v3
  014e const/16 v5, 15
  0152 aget-byte v5, v1, v5
  0156 and-int/lit16 v5, v5, 255
  015a cmp-long v62, v56, v46
  015e if-ltz v62, +549h
  0162 rem-long v62, v56, v46
  0166 cmp-long v62, v62, v16
  016a if-nez v62, +543h
  016e cmp-long v3, v3, v46
  0172 if-nez v3, +53fh
  0176 cmp-long v3, v12, v16
  017a if-ltz v3, +53bh
  017e sub-long v3, v9, v18
  0182 cmp-long v3, v56, v3
  0186 if-gtz v3, +535h
  018a const/16 v4, 12
  018e aget-byte v3, v1, v4
  0192 if-nez v3, +52fh
  0196 const/16 v3, 13
  019a aget-byte v3, v1, v3
  019e if-nez v3, +529h
  01a2 const/16 v3, 14
  01a6 aget-byte v1, v1, v3
  01aa if-nez v1, +523h
  01ae if-gt v5, v7, +521h
  01b2 cmp-long v1, v18, v16
  01b6 if-nez v1, +096h
  01ba const-string v1, "CRID"
  01be invoke-virtual v2, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01c4 move-result v1
  01c6 if-eqz v1, +087h
  01ca const/4 v1, 1
  01cc if-ne v5, v1, +084h
  01d0 const-wide/16 v49, 2048
  01d4 cmp-long v1, v56, v49
  01d8 if-nez v1, +07eh
  01dc long-to-int v4, v12
  01de const/4 v11, 3
  01e0 move-object v1, v8
  01e2 move-wide/from16 v2, v58
  01e6 move-wide v5, v9
  01e8 move-object/from16 v12, v72
  01ec move v15, v7
  01ee move-object/from16 v13, v43
  01f2 move v7, v11
  01f4 invoke-static/range v1 ... v7, Lcom/personal/aihub/MovieStorage;->utf(Ljava/io/RandomAccessFile; J I J I)Ljava/util/List;
  01fa move-result-object v1
  01fc invoke-interface v1, Ljava/util/List;->size()I
  0202 move-result v2
  0204 const/4 v3, 2
  0206 if-eq v2, v3, +008h
  020a invoke-interface v1, Ljava/util/List;->size()I
  0210 move-result v2
  0212 if-ne v2, v15, +05ah
  0216 const/4 v2, 0
  0218 invoke-interface v1, v2, Ljava/util/List;->get(I)Ljava/lang/Object;
  021e move-result-object v3
  0220 check-cast v3, Ljava/util/Map;
  0224 invoke-static v3, v13, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  022a move-result-wide v3
  022c cmp-long v3, v3, v9
  0230 if-nez v3, +04bh
  0234 invoke-interface v1, v2, Ljava/util/List;->get(I)Ljava/lang/Object;
  023a move-result-object v3
  023c check-cast v3, Ljava/util/Map;
  0240 invoke-static v3, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0246 move-result-wide v2
  0248 cmp-long v2, v2, v16
  024c if-nez v2, +03dh
  0250 const/4 v2, 1
  0252 invoke-interface v1, v2, Ljava/util/List;->get(I)Ljava/lang/Object;
  0258 move-result-object v2
  025a check-cast v2, Ljava/util/Map;
  025e invoke-static v2, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0264 move-result-wide v2
  0266 const-wide/32 v4, 1079199318
  026c cmp-long v2, v2, v4
  0270 if-nez v2, +02bh
  0274 invoke-interface v1, Ljava/util/List;->size()I
  027a move-result v2
  027c if-ne v2, v15, +014h
  0280 const/4 v2, 2
  0282 invoke-interface v1, v2, Ljava/util/List;->get(I)Ljava/lang/Object;
  0288 move-result-object v2
  028a check-cast v2, Ljava/util/Map;
  028e invoke-static v2, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0294 move-result-wide v2
  0296 const-wide/32 v4, 1079199297
  029c cmp-long v2, v2, v4
  02a0 if-nez v2, +013h
  02a4 move-object/from16 v44, v0
  02a8 move-object v5, v1
  02aa move-wide/from16 v66, v9
  02ae move-object v7, v12
  02b0 move-object v10, v14
  02b2 move-wide/from16 v2, v52
  02b6 move-object/from16 v4, v54
  02ba move-object/from16 v6, v55
  02be move-object/from16 v11, v60
  02c2 goto/16 +47ah
  02c6 const-string v0, "Invalid authored movie directory."
  02ca invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  02d0 move-result-object v0
  02d2 throw v0
  02d4 const-string v0, "The movie directory is missing."
  02d8 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  02de move-result-object v0
  02e0 throw v0
  02e2 const-wide/16 v49, 2048
  02e6 move v15, v7
  02e8 move-object/from16 v7, v72
  02ec const-string v1, "@SFV"
  02f0 invoke-virtual v2, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  02f6 move-result v43
  02f8 if-nez v43, +012h
  02fc const-string v1, "@SFA"
  0300 invoke-virtual v2, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0306 move-result v1
  0308 if-eqz v1, +003h
  030c goto +8h
  030e const-string v0, "Unsupported movie stream."
  0312 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0318 move-result-object v0
  031a throw v0
  031c const-string v15, "metadata_size"
  0320 const-wide/16 v63, 1
  0324 const/4 v1, 1
  0326 if-ne v5, v1, +13ah
  032a const-wide/32 v1, 65536
  0330 cmp-long v1, v12, v1
  0334 if-gtz v1, +12ch
  0338 long-to-int v4, v12
  033a const/4 v12, 1
  033c const-wide/16 v5, 4096
  0340 move-object v1, v8
  0342 move-wide/from16 v2, v58
  0346 move-object/from16 v65, v14
  034a move-wide v13, v5
  034c move-wide v5, v9
  034e move-object v13, v7
  0350 move-wide/from16 v66, v9
  0354 move-object/from16 v14, v44
  0358 move-object/from16 v9, v48
  035c move-object/from16 v44, v0
  0360 move-object/from16 v0, v45
  0364 move v7, v12
  0366 invoke-static/range v1 ... v7, Lcom/personal/aihub/MovieStorage;->utf(Ljava/io/RandomAccessFile; J I J I)Ljava/util/List;
  036c move-result-object v1
  036e invoke-interface v1, Ljava/util/List;->size()I
  0374 move-result v2
  0376 const/4 v3, 1
  0378 if-ne v2, v3, +103h
  037c const/4 v2, 0
  037e invoke-interface v1, v2, Ljava/util/List;->get(I)Ljava/lang/Object;
  0384 move-result-object v1
  0386 move-object v7, v1
  0388 check-cast v7, Ljava/util/Map;
  038c if-eqz v43, +096h
  0390 invoke-static v7, v9, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0396 move-result-wide v1
  0398 invoke-static v7, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  039e move-result-wide v3
  03a0 invoke-static v7, v14, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  03a6 move-result-wide v5
  03a8 const-string v0, "framerate_n"
  03ac invoke-static v7, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  03b2 move-result-wide v9
  03b4 const-string v0, "framerate_d"
  03b8 move-object/from16 v45, v11
  03bc invoke-static v7, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  03c2 move-result-wide v11
  03c4 if-nez v13, +073h
  03c8 move-wide/from16 v13, v52
  03cc cmp-long v0, v13, v16
  03d0 if-gtz v0, +06dh
  03d4 const-string v0, "mpeg_codec"
  03d8 invoke-static v7, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  03de move-result-wide v40
  03e0 const-wide/16 v42, 9
  03e4 cmp-long v0, v40, v42
  03e8 if-nez v0, +061h
  03ec const-string v0, "metadata_count"
  03f0 invoke-static v7, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  03f6 move-result-wide v40
  03f8 cmp-long v0, v40, v63
  03fc if-nez v0, +057h
  0400 invoke-static v7, v15, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0406 move-result-wide v40
  0408 cmp-long v0, v40, v46
  040c if-ltz v0, +04fh
  0410 invoke-static v7, v15, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0416 move-result-wide v40
  0418 const-wide/32 v42, 1048576
  041e cmp-long v0, v40, v42
  0422 if-gtz v0, +044h
  0426 cmp-long v0, v1, v63
  042a if-ltz v0, +040h
  042e cmp-long v0, v3, v63
  0432 if-ltz v0, +03ch
  0436 const-wide/16 v40, 4096
  043a cmp-long v0, v1, v40
  043e if-gtz v0, +036h
  0442 cmp-long v0, v3, v40
  0446 if-gtz v0, +032h
  044a mul-long/2addr v1, v3
  044c const-wide/32 v3, 16777216
  0452 cmp-long v0, v1, v3
  0456 if-gtz v0, +02ah
  045a cmp-long v0, v5, v63
  045e if-ltz v0, +026h
  0462 const-wide/16 v0, 10000
  0466 cmp-long v0, v5, v0
  046a if-gtz v0, +020h
  046e cmp-long v0, v11, v63
  0472 if-ltz v0, +01ch
  0476 long-to-double v0, v9
  0478 long-to-double v2, v11
  047a div-double/2addr v0, v2
  047c const-wide/high16 v2, 4607182418800017408
  0480 cmpg-double v2, v0, v2
  0484 if-ltz v2, +00ch
  0488 const-wide/high16 v2, 4638144666238189568
  048c cmpl-double v0, v0, v2
  0490 if-gtz v0, +006h
  0494 move-wide v10, v13
  0496 move-object/from16 v4, v54
  049a goto +65h
  049c const-string v0, "Unsupported VP9 movie metadata."
  04a0 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  04a6 move-result-object v0
  04a8 throw v0
  04aa const-string v0, "Unsupported VP9 movie metadata."
  04ae invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  04b4 move-result-object v0
  04b6 throw v0
  04b8 move-object/from16 v45, v11
  04bc move-wide/from16 v10, v52
  04c0 move-object/from16 v12, v54
  04c4 if-nez v12, +056h
  04c8 cmp-long v0, v28, v16
  04cc if-gtz v0, +052h
  04d0 invoke-interface/range v45, Ljava/util/List;->size()I
  04d6 move-result v0
  04d8 const/4 v1, 3
  04da if-ne v0, v1, +04bh
  04de const-string v0, "audio_codec"
  04e2 invoke-static v7, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  04e8 move-result-wide v0
  04ea const-wide/16 v2, 2
  04ee cmp-long v0, v0, v2
  04f2 if-nez v0, +03fh
  04f6 const-string v0, "metadata_count"
  04fa invoke-static v7, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0500 move-result-wide v0
  0502 cmp-long v0, v0, v16
  0506 if-nez v0, +035h
  050a invoke-static v7, v15, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0510 move-result-wide v0
  0512 cmp-long v0, v0, v16
  0516 if-nez v0, +02dh
  051a const-string v0, "sampling_rate"
  051e invoke-static v7, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0524 move-result-wide v0
  0526 const-wide/32 v2, 48000
  052c cmp-long v0, v0, v2
  0530 if-nez v0, +020h
  0534 const-string v0, "num_channels"
  0538 invoke-static v7, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  053e move-result-wide v0
  0540 const-wide/16 v2, 2
  0544 cmp-long v0, v0, v2
  0548 if-nez v0, +014h
  054c const-string v0, "total_samples"
  0550 invoke-static v7, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0556 move-result-wide v0
  0558 cmp-long v0, v0, v63
  055c if-ltz v0, +00ah
  0560 move-object v4, v7
  0562 move-object v7, v13
  0564 move-wide v2, v10
  0566 move-object/from16 v5, v45
  056a move-object/from16 v6, v55
  056e goto +5ah
  0570 const-string v0, "Unsupported ADX movie metadata."
  0574 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  057a move-result-object v0
  057c throw v0
  057e const-string v0, "Invalid stream metadata."
  0582 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0588 move-result-object v0
  058a throw v0
  058c const-string v0, "Movie metadata is too large."
  0590 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0596 move-result-object v0
  0598 throw v0
  059a move-wide/from16 v66, v9
  059e move-wide v1, v12
  05a0 move-object/from16 v65, v14
  05a4 move-object/from16 v14, v44
  05a8 move-object/from16 v9, v48
  05ac move-object/from16 v12, v54
  05b0 move-object/from16 v44, v0
  05b4 move-object v13, v7
  05b6 move-object/from16 v0, v45
  05ba const/4 v7, 3
  05bc move-object/from16 v45, v11
  05c0 move-wide/from16 v10, v52
  05c4 if-ne v5, v7, +03ch
  05c8 if-eqz v43, +033h
  05cc if-eqz v13, +031h
  05d0 cmp-long v0, v10, v16
  05d4 if-gtz v0, +02dh
  05d8 move-object/from16 v7, v55
  05dc if-nez v7, +029h
  05e0 invoke-static v13, v15, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  05e6 move-result-wide v3
  05e8 cmp-long v0, v3, v56
  05ec if-nez v0, +021h
  05f0 const-wide/32 v3, 1048576
  05f6 cmp-long v0, v1, v3
  05fa if-gtz v0, +01ah
  05fe long-to-int v4, v1
  0600 const/16 v7, 10000
  0604 move-object v1, v8
  0606 move-wide/from16 v2, v58
  060a move-wide/from16 v5, v66
  060e invoke-static/range v1 ... v7, Lcom/personal/aihub/MovieStorage;->utf(Ljava/io/RandomAccessFile; J I J I)Ljava/util/List;
  0614 move-result-object v0
  0616 move-object v6, v0
  0618 move-wide v2, v10
  061a move-object v4, v12
  061c move-object v7, v13
  061e move-object/from16 v5, v45
  0622 move-object/from16 v11, v60
  0626 move-object/from16 v10, v65
  062a goto/16 +2c6h
  062e const-string v0, "Invalid movie seek metadata."
  0632 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0638 move-result-object v0
  063a throw v0
  063c move-object/from16 v7, v55
  0640 const/4 v15, 2
  0642 if-ne v5, v15, +0a0h
  0646 const-wide/16 v3, 64
  064a cmp-long v0, v1, v3
  064e if-gtz v0, +093h
  0652 long-to-int v0, v1
  0654 move-object v1, v8
  0656 move-wide/from16 v2, v58
  065a move v4, v0
  065c move-wide/from16 v5, v66
  0660 invoke-static/range v1 ... v6, Lcom/personal/aihub/MovieStorage;->read(Ljava/io/RandomAccessFile; J I J)[B
  0666 move-result-object v1
  0668 const/4 v2, 0
  066a invoke-static v1, v2, v0, Lcom/personal/aihub/MovieStorage;->text([B I I)Ljava/lang/String;
  0670 move-result-object v0
  0672 const-string v1, "#HEADER END     =============== "
  0676 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  067c move-result v1
  067e if-eqz v1, +028h
  0682 if-eqz v43, +014h
  0686 if-eqz v13, +00bh
  068a if-nez v24, +009h
  068e cmp-long v0, v10, v16
  0692 if-gtz v0, +005h
  0696 const/16 v24, 1
  069a goto +5ch
  069c const-string v0, "Invalid video header marker."
  06a0 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  06a6 move-result-object v0
  06a8 throw v0
  06aa if-eqz v12, +00bh
  06ae if-nez v23, +009h
  06b2 cmp-long v0, v28, v16
  06b6 if-gtz v0, +005h
  06ba const/16 v23, 1
  06be goto +4ah
  06c0 const-string v0, "Invalid audio header marker."
  06c4 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  06ca move-result-object v0
  06cc throw v0
  06ce const-string v1, "#METADATA END   =============== "
  06d2 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  06d8 move-result v1
  06da if-eqz v1, +01ch
  06de if-eqz v43, +013h
  06e2 if-eqz v7, +011h
  06e6 invoke-interface v7, Ljava/util/List;->isEmpty()Z
  06ec move-result v0
  06ee if-nez v0, +00bh
  06f2 if-nez v26, +009h
  06f6 cmp-long v0, v10, v16
  06fa if-gtz v0, +005h
  06fe const/16 v26, 1
  0702 goto +28h
  0704 const-string v0, "Invalid seek marker."
  0708 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  070e move-result-object v0
  0710 throw v0
  0712 const-string v1, "#CONTENTS END   =============== "
  0716 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  071c move-result v0
  071e if-eqz v0, +024h
  0722 if-eqz v43, +012h
  0726 cmp-long v0, v10, v16
  072a if-eqz v0, +007h
  072e if-nez v20, +005h
  0732 const/16 v20, 1
  0736 goto +eh
  0738 const-string v0, "Invalid video end marker."
  073c invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0742 move-result-object v0
  0744 throw v0
  0746 if-eqz v27, +009h
  074a if-nez v25, +007h
  074e const/16 v25, 1
  0752 move-object v6, v7
  0754 goto/16 -09eh
  0758 const-string v0, "Invalid audio end marker."
  075c invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0762 move-result-object v0
  0764 throw v0
  0766 const-string v0, "Unsupported movie marker."
  076a invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0770 move-result-object v0
  0772 throw v0
  0774 const-string v0, "Invalid movie marker."
  0778 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  077e move-result-object v0
  0780 throw v0
  0782 if-eqz v43, +137h
  0786 if-eqz v13, +12eh
  078a if-eqz v24, +12ch
  078e if-eqz v26, +12ah
  0792 if-nez v20, +128h
  0796 const-wide/16 v41, 13
  079a cmp-long v5, v1, v41
  079e if-ltz v5, +122h
  07a2 cmp-long v41, v10, v16
  07a6 if-nez v41, +0a5h
  07aa const/16 v5, 32
  07ae move-wide/from16 v68, v1
  07b2 move-object v1, v8
  07b4 move-wide/from16 v2, v58
  07b8 move v4, v5
  07ba const/4 v15, 4
  07bc move-wide/from16 v5, v66
  07c0 invoke-static/range v1 ... v6, Lcom/personal/aihub/MovieStorage;->read(Ljava/io/RandomAccessFile; J I J)[B
  07c6 move-result-object v1
  07c8 const-wide/16 v2, 45
  07cc move-wide/from16 v5, v68
  07d0 cmp-long v2, v5, v2
  07d4 if-ltz v2, +087h
  07d8 const/4 v2, 0
  07da invoke-static v1, v2, v15, Lcom/personal/aihub/MovieStorage;->text([B I I)Ljava/lang/String;
  07e0 move-result-object v3
  07e2 const-string v2, "DKIF"
  07e6 invoke-virtual v3, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  07ec move-result v2
  07ee if-eqz v2, +07ah
  07f2 const/4 v2, 2
  07f4 invoke-static v1, v15, v2, Lcom/personal/aihub/MovieStorage;->le([B I I)J
  07fa move-result-wide v3
  07fc cmp-long v3, v3, v16
  0800 if-nez v3, +071h
  0804 const/4 v3, 6
  0806 invoke-static v1, v3, v2, Lcom/personal/aihub/MovieStorage;->le([B I I)J
  080c move-result-wide v30
  080e cmp-long v3, v30, v46
  0812 if-nez v3, +068h
  0816 const/16 v4, 8
  081a invoke-static v1, v4, v15, Lcom/personal/aihub/MovieStorage;->text([B I I)Ljava/lang/String;
  0820 move-result-object v3
  0822 const-string v4, "VP90"
  0826 invoke-virtual v3, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  082c move-result v3
  082e if-eqz v3, +05ah
  0832 const/16 v4, 12
  0836 invoke-static v1, v4, v2, Lcom/personal/aihub/MovieStorage;->le([B I I)J
  083c move-result-wide v30
  083e invoke-static v13, v9, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0844 move-result-wide v32
  0846 cmp-long v3, v30, v32
  084a if-nez v3, +04ch
  084e const/16 v9, 14
  0852 invoke-static v1, v9, v2, Lcom/personal/aihub/MovieStorage;->le([B I I)J
  0858 move-result-wide v30
  085a invoke-static v13, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0860 move-result-wide v2
  0862 cmp-long v0, v30, v2
  0866 if-nez v0, +03eh
  086a const/16 v0, 16
  086e invoke-static v1, v0, v15, Lcom/personal/aihub/MovieStorage;->le([B I I)J
  0874 move-result-wide v2
  0876 const/16 v0, 20
  087a invoke-static v1, v0, v15, Lcom/personal/aihub/MovieStorage;->le([B I I)J
  0880 move-result-wide v30
  0882 const-string v0, "framerate_n"
  0886 invoke-static v13, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  088c move-result-wide v32
  088e cmp-long v0, v2, v32
  0892 if-nez v0, +021h
  0896 const-string v0, "framerate_d"
  089a invoke-static v13, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  08a0 move-result-wide v32
  08a2 cmp-long v0, v30, v32
  08a6 if-nez v0, +017h
  08aa const/16 v0, 24
  08ae invoke-static v1, v0, v15, Lcom/personal/aihub/MovieStorage;->le([B I I)J
  08b4 move-result-wide v0
  08b6 invoke-static v13, v14, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  08bc move-result-wide v32
  08be cmp-long v0, v0, v32
  08c2 if-nez v0, +009h
  08c6 const/16 v0, 32
  08ca move-wide/from16 v32, v30
  08ce move-wide/from16 v30, v2
  08d2 goto +12h
  08d4 const-string v0, "Movie frame timing differs from its metadata."
  08d8 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  08de move-result-object v0
  08e0 throw v0
  08e2 const-string v0, "Unsupported IVF movie header."
  08e6 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  08ec move-result-object v0
  08ee throw v0
  08f0 move-wide v5, v1
  08f2 const/4 v15, 4
  08f4 const/4 v0, 0
  08f6 int-to-long v2, v0
  08f8 add-long v46, v58, v2
  08fc const/16 v0, 13
  0900 move-object v1, v8
  0902 move-wide/from16 v52, v2
  0906 move-wide/from16 v2, v46
  090a move v9, v4
  090c const/16 v14, 8
  0910 move v4, v0
  0912 move-wide/from16 v70, v5
  0916 move-wide/from16 v5, v66
  091a invoke-static/range v1 ... v6, Lcom/personal/aihub/MovieStorage;->read(Ljava/io/RandomAccessFile; J I J)[B
  0920 move-result-object v0
  0922 const/4 v1, 0
  0924 invoke-static v0, v1, v15, Lcom/personal/aihub/MovieStorage;->le([B I I)J
  092a move-result-wide v2
  092c aget-byte v1, v0, v9
  0930 and-int/lit16 v4, v1, 255
  0934 cmp-long v5, v2, v63
  0938 if-ltz v5, +04eh
  093c const-wide/16 v5, 12
  0940 add-long/2addr v2, v5
  0942 add-long v2, v2, v52
  0946 move-wide/from16 v5, v70
  094a cmp-long v2, v2, v5
  094e if-nez v2, +043h
  0952 invoke-static v0, v15, v14, Lcom/personal/aihub/MovieStorage;->le([B I I)J
  0958 move-result-wide v2
  095a cmp-long v0, v2, v10
  095e if-nez v0, +03bh
  0962 const/4 v0, 6
  0964 shr-int/lit8 v0, v4, 6
  0968 const/4 v2, 2
  096a if-ne v0, v2, +035h
  096e and-int/lit8 v0, v1, 48
  0972 if-nez v0, +031h
  0976 if-nez v41, +006h
  097a and-int/lit8 v0, v1, 12
  097e if-nez v0, +02bh
  0982 invoke-static/range v18 ... v19, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  0988 move-result-object v0
  098a move-object/from16 v4, v60
  098e invoke-virtual v4, v0, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0994 and-int/lit8 v0, v1, 12
  0998 if-nez v0, +005h
  099c const/16 v61, 1
  09a0 goto +3h
  09a2 const/16 v61, 0
  09a6 invoke-static/range v61, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;
  09ac move-result-object v0
  09ae move-object/from16 v2, v65
  09b2 invoke-virtual v2, v0, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  09b8 add-long v0, v10, v63
  09bc add-long v21, v21, v5
  09c0 move-object v10, v2
  09c2 move-object v11, v4
  09c4 move-object v6, v7
  09c6 move-object v4, v12
  09c8 move-object v7, v13
  09ca move-object/from16 v5, v45
  09ce move-wide v2, v0
  09d0 goto/16 +0f3h
  09d4 const-string v0, "Invalid authored VP9 frame."
  09d8 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  09de move-result-object v0
  09e0 throw v0
  09e2 const-string v0, "Incomplete VP9 packet."
  09e6 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  09ec move-result-object v0
  09ee throw v0
  09f0 move v9, v3
  09f2 move v0, v4
  09f4 move v14, v6
  09f6 move-object/from16 v4, v60
  09fa const/4 v15, 4
  09fc move-wide v5, v1
  09fe move-object/from16 v2, v65
  0a02 if-eqz v12, +0f0h
  0a06 if-eqz v23, +0eeh
  0a0a if-nez v25, +0ech
  0a0e if-nez v27, +0eah
  0a12 cmp-long v1, v5, v63
  0a16 if-ltz v1, +0e6h
  0a1a move-wide/from16 v52, v10
  0a1e const-wide/16 v9, 4096
  0a22 invoke-static v5, v6, v9, v10, Ljava/lang/Math;->min(J J)J
  0a28 move-result-wide v0
  0a2a long-to-int v0, v0
  0a2c move-object v1, v8
  0a2e move-object v10, v2
  0a30 move-wide/from16 v2, v58
  0a34 move-object v11, v4
  0a36 move v4, v0
  0a38 move-wide/from16 v58, v5
  0a3c move-wide/from16 v5, v66
  0a40 invoke-static/range v1 ... v6, Lcom/personal/aihub/MovieStorage;->read(Ljava/io/RandomAccessFile; J I J)[B
  0a46 move-result-object v0
  0a48 cmp-long v1, v28, v16
  0a4c if-nez v1, +086h
  0a50 const-wide/16 v1, 24
  0a54 cmp-long v1, v58, v1
  0a58 if-ltz v1, +079h
  0a5c const/4 v1, 0
  0a5e invoke-static v0, v1, Lcom/personal/aihub/MovieStorage;->u16([B I)I
  0a64 move-result v2
  0a66 const v1, 32768
  0a6c if-ne v2, v1, +06fh
  0a70 const/4 v1, 2
  0a72 invoke-static v0, v1, Lcom/personal/aihub/MovieStorage;->u16([B I)I
  0a78 move-result v2
  0a7a add-int/2addr v2, v15
  0a7c int-to-long v1, v2
  0a7e const/16 v3, 12
  0a82 invoke-static v0, v3, Lcom/personal/aihub/MovieStorage;->u32([B I)J
  0a88 move-result-wide v3
  0a8a cmp-long v5, v1, v58
  0a8e if-nez v5, +057h
  0a92 const-wide/16 v5, 4096
  0a96 cmp-long v5, v1, v5
  0a9a if-gtz v5, +051h
  0a9e aget-byte v5, v0, v15
  0aa2 const/4 v6, 3
  0aa4 if-ne v5, v6, +04ch
  0aa8 const/4 v5, 5
  0aaa aget-byte v5, v0, v5
  0aae const/16 v6, 18
  0ab2 if-ne v5, v6, +045h
  0ab6 const/4 v5, 6
  0ab8 aget-byte v6, v0, v5
  0abc if-ne v6, v15, +040h
  0ac0 const/4 v5, 7
  0ac2 aget-byte v5, v0, v5
  0ac6 const/4 v6, 2
  0ac8 if-ne v5, v6, +03ah
  0acc invoke-static v0, v14, Lcom/personal/aihub/MovieStorage;->u32([B I)J
  0ad2 move-result-wide v5
  0ad4 const-wide/32 v36, 48000
  0ada cmp-long v5, v5, v36
  0ade if-nez v5, +02fh
  0ae2 const-string v5, "total_samples"
  0ae6 invoke-static v12, v5, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0aec move-result-wide v5
  0aee cmp-long v5, v3, v5
  0af2 if-nez v5, +025h
  0af6 const/16 v5, 18
  0afa aget-byte v5, v0, v5
  0afe const/4 v6, 3
  0b00 if-eq v5, v6, +004h
  0b04 if-ne v5, v15, +01ch
  0b08 const/16 v5, 19
  0b0c aget-byte v5, v0, v5
  0b10 if-nez v5, +016h
  0b14 long-to-int v5, v1
  0b16 const/4 v6, 6
  0b18 sub-int/2addr v5, v6
  0b1a invoke-static v0, v5, v6, Lcom/personal/aihub/MovieStorage;->text([B I I)Ljava/lang/String;
  0b20 move-result-object v0
  0b22 const-string v5, "(c)CRI"
  0b26 invoke-virtual v0, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0b2c move-result v0
  0b2e if-eqz v0, +007h
  0b32 move-wide/from16 v36, v1
  0b36 move-wide/from16 v38, v3
  0b3a goto +35h
  0b3c const-string v0, "Unsupported plain stereo ADX header."
  0b40 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0b46 move-result-object v0
  0b48 throw v0
  0b4a const-string v0, "Invalid ADX header."
  0b4e invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0b54 move-result-object v0
  0b56 throw v0
  0b58 const-wide/16 v1, 18
  0b5c cmp-long v1, v58, v1
  0b60 if-nez v1, +018h
  0b64 const/4 v1, 0
  0b66 invoke-static v0, v1, Lcom/personal/aihub/MovieStorage;->u16([B I)I
  0b6c move-result v2
  0b6e const v1, 32769
  0b74 if-ne v2, v1, +00eh
  0b78 const/4 v1, 2
  0b7a invoke-static v0, v1, Lcom/personal/aihub/MovieStorage;->u16([B I)I
  0b80 move-result v0
  0b82 const/16 v1, 14
  0b86 if-ne v0, v1, +005h
  0b8a const/16 v27, 1
  0b8e goto +bh
  0b90 rem-long v0, v58, v41
  0b94 cmp-long v0, v0, v16
  0b98 if-nez v0, +01eh
  0b9c div-long v0, v58, v41
  0ba0 add-long v34, v34, v0
  0ba4 add-long v28, v28, v58
  0ba8 move-object v6, v7
  0baa move-object v4, v12
  0bac move-object v7, v13
  0bae move-object/from16 v5, v45
  0bb2 move-wide/from16 v2, v52
  0bb6 add-long v18, v18, v56
  0bba move-object v14, v10
  0bbc move-object v13, v11
  0bbe move-object/from16 v0, v44
  0bc2 move-wide/from16 v11, v49
  0bc6 move/from16 v1, v51
  0bca move-wide/from16 v9, v66
  0bce const/4 v15, 0
  0bd0 goto/16 -59bh
  0bd4 const-string v0, "ADX audio ends inside a sample block."
  0bd8 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0bde move-result-object v0
  0be0 throw v0
  0be2 const-string v0, "Incomplete ADX packet."
  0be6 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0bec move-result-object v0
  0bee throw v0
  0bf0 const-string v0, "Invalid authored movie packet."
  0bf4 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0bfa move-result-object v0
  0bfc throw v0
  0bfe const-string v0, "The movie contains too many packets."
  0c02 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0c08 move-result-object v0
  0c0a throw v0
  0c0c move-wide/from16 v52, v2
  0c10 move-object v12, v4
  0c12 move-object v7, v6
  0c14 move-object v11, v13
  0c16 move-object v10, v14
  0c18 move-object/from16 v1, v43
  0c1c move-object/from16 v14, v44
  0c20 move-object/from16 v0, v45
  0c24 move-object/from16 v9, v48
  0c28 move-object/from16 v13, v72
  0c2c move-object/from16 v45, v5
  0c30 if-eqz v13, +139h
  0c34 if-eqz v20, +137h
  0c38 invoke-static v13, v14, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0c3e move-result-wide v2
  0c40 cmp-long v2, v52, v2
  0c44 if-nez v2, +12fh
  0c48 move-object/from16 v5, v45
  0c4c const/4 v2, 1
  0c4e invoke-interface v5, v2, Ljava/util/List;->get(I)Ljava/lang/Object;
  0c54 move-result-object v3
  0c56 check-cast v3, Ljava/util/Map;
  0c5a invoke-static v3, v1, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0c60 move-result-wide v3
  0c62 cmp-long v3, v21, v3
  0c66 if-nez v3, +11eh
  0c6a if-eqz v7, +11ch
  0c6e invoke-interface v7, Ljava/util/List;->isEmpty()Z
  0c74 move-result v3
  0c76 if-nez v3, +116h
  0c7a const/4 v3, 0
  0c7c invoke-interface v7, v3, Ljava/util/List;->get(I)Ljava/lang/Object;
  0c82 move-result-object v4
  0c84 check-cast v4, Ljava/util/Map;
  0c88 const-string v6, "ofs_frmid"
  0c8c invoke-static v4, v6, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0c92 move-result-wide v14
  0c94 cmp-long v4, v14, v16
  0c98 if-nez v4, +0feh
  0c9c invoke-interface v7, Ljava/util/List;->iterator()Ljava/util/Iterator;
  0ca2 move-result-object v4
  0ca4 invoke-interface v4, Ljava/util/Iterator;->hasNext()Z
  0caa move-result v6
  0cac if-eqz v6, +046h
  0cb0 invoke-interface v4, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0cb6 move-result-object v6
  0cb8 check-cast v6, Ljava/util/Map;
  0cbc const-string v7, "ofs_frmid"
  0cc0 invoke-static v6, v7, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0cc6 move-result-wide v14
  0cc8 cmp-long v7, v14, v16
  0ccc if-ltz v7, +02fh
  0cd0 invoke-virtual v11, Ljava/util/ArrayList;->size()I
  0cd6 move-result v7
  0cd8 int-to-long v2, v7
  0cda cmp-long v2, v14, v2
  0cde if-gez v2, +026h
  0ce2 long-to-int v2, v14
  0ce4 invoke-virtual v10, v2, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;
  0cea move-result-object v3
  0cec check-cast v3, Ljava/lang/Boolean;
  0cf0 invoke-virtual v3, Ljava/lang/Boolean;->booleanValue()Z
  0cf6 move-result v3
  0cf8 if-eqz v3, +019h
  0cfc invoke-virtual v11, v2, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;
  0d02 move-result-object v2
  0d04 check-cast v2, Ljava/lang/Long;
  0d08 invoke-virtual v2, Ljava/lang/Long;->longValue()J
  0d0e move-result-wide v2
  0d10 const-string v7, "ofs_byte"
  0d14 invoke-static v6, v7, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0d1a move-result-wide v6
  0d1c cmp-long v2, v2, v6
  0d20 if-nez v2, +005h
  0d24 const/4 v2, 1
  0d26 const/4 v3, 0
  0d28 goto -42h
  0d2a const-string v0, "Movie seek positions do not match its frames."
  0d2e invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0d34 move-result-object v0
  0d36 throw v0
  0d38 invoke-interface v5, Ljava/util/List;->size()I
  0d3e move-result v2
  0d40 const/4 v3, 3
  0d42 if-ne v2, v3, +05bh
  0d46 if-eqz v12, +052h
  0d4a if-eqz v25, +050h
  0d4e if-eqz v27, +04eh
  0d52 const-wide/16 v2, 31
  0d56 move-wide/from16 v6, v38
  0d5a add-long v38, v6, v2
  0d5e div-long v38, v38, v46
  0d62 cmp-long v2, v34, v38
  0d66 if-nez v2, +042h
  0d6a mul-long v34, v34, v41
  0d6e add-long v36, v36, v34
  0d72 const-wide/16 v2, 18
  0d76 add-long v36, v36, v2
  0d7a cmp-long v2, v28, v36
  0d7e if-nez v2, +036h
  0d82 const/4 v2, 2
  0d84 invoke-interface v5, v2, Ljava/util/List;->get(I)Ljava/lang/Object;
  0d8a move-result-object v2
  0d8c check-cast v2, Ljava/util/Map;
  0d90 invoke-static v2, v1, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0d96 move-result-wide v1
  0d98 cmp-long v1, v28, v1
  0d9c if-nez v1, +027h
  0da0 long-to-double v1, v6
  0da2 const-wide v3, 4676829883349860352
  0dac div-double/2addr v1, v3
  0dae move-wide/from16 v3, v52
  0db2 long-to-double v6, v3
  0db4 move-wide/from16 v10, v32
  0db8 long-to-double v14, v10
  0dba mul-double/2addr v6, v14
  0dbc move-wide/from16 v16, v10
  0dc0 move-wide/from16 v10, v30
  0dc4 long-to-double v3, v10
  0dc6 div-double/2addr v6, v3
  0dc8 sub-double/2addr v1, v6
  0dca invoke-static v1, v2, Ljava/lang/Math;->abs(D)D
  0dd0 move-result-wide v1
  0dd2 div-double/2addr v14, v3
  0dd4 const-wide v3, 4536770139825955493
  0dde add-double/2addr v14, v3
  0de0 cmpl-double v1, v1, v14
  0de4 if-gtz v1, +003h
  0de8 goto +ch
  0dea const-string v0, "The movie ends before its declared audio content."
  0dee invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0df4 move-result-object v0
  0df6 throw v0
  0df8 move-wide/from16 v10, v30
  0dfc move-wide/from16 v16, v32
  0e00 new-instance v1, Lorg/json/JSONObject;
  0e04 invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  0e0a invoke-static v13, v9, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0e10 move-result-wide v2
  0e12 invoke-virtual v1, v9, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0e18 move-result-object v1
  0e1a invoke-static v13, v0, Lcom/personal/aihub/MovieStorage;->n(Ljava/util/Map; Ljava/lang/String;)J
  0e20 move-result-wide v2
  0e22 invoke-virtual v1, v0, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0e28 move-result-object v0
  0e2a const-string v1, "frames"
  0e2e move-wide/from16 v2, v52
  0e32 invoke-virtual v0, v1, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0e38 move-result-object v0
  0e3a const-string v1, "rate"
  0e3e new-instance v2, Lorg/json/JSONObject;
  0e42 invoke-direct v2, Lorg/json/JSONObject;-><init>()V
  0e48 const-string v3, "n"
  0e4c invoke-virtual v2, v3, v10, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0e52 move-result-object v2
  0e54 const-string v3, "d"
  0e58 move-wide/from16 v6, v16
  0e5c invoke-virtual v2, v3, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0e62 move-result-object v2
  0e64 invoke-virtual v0, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0e6a move-result-object v0
  0e6c const-string v1, "preservedAudio"
  0e70 invoke-interface v5, Ljava/util/List;->size()I
  0e76 move-result v2
  0e78 const/4 v3, 3
  0e7a if-ne v2, v3, +004h
  0e7e const/4 v15, 1
  0e80 goto +2h
  0e82 const/4 v15, 0
  0e84 invoke-virtual v0, v1, v15, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0e8a move-result-object v0
  0e8c invoke-virtual v8, Ljava/io/RandomAccessFile;->close()V
  0e92 return-object v0
  0e94 const-string v0, "The first movie seek must point to its first frame."
  0e98 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0e9e move-result-object v0
  0ea0 throw v0
  0ea2 const-string v0, "The movie ends before its declared video content."
  0ea6 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0eac move-result-object v0
  0eae throw v0
  0eb0 const-string v0, "Choose a complete authored movie up to 96 MB."
  0eb4 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0eba move-result-object v0
  0ebc throw v0
  0ebe move-exception v0
  0ec0 move-object v1, v0
  0ec2 invoke-virtual v8, Ljava/io/RandomAccessFile;->close()V
  0ec8 goto +6h
  0eca move-exception v0
  0ecc move-object v2, v0
  0ece invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0ed4 throw v1
.end method

.method integer(Ljava/lang/Object;)Z
  0000 instance-of v0, v6, Ljava/lang/Number;
  0004 const/4 v1, 0
  0006 if-eqz v0, +021h
  000a instance-of v0, v6, Ljava/lang/Boolean;
  000e if-eqz v0, +003h
  0012 goto +1bh
  0014 check-cast v6, Ljava/lang/Number;
  0018 invoke-virtual v6, Ljava/lang/Number;->doubleValue()D
  001e move-result-wide v2
  0020 invoke-static v2, v3, Ljava/lang/Double;->isFinite(D)Z
  0026 move-result v0
  0028 if-eqz v0, +010h
  002c invoke-virtual v6, Ljava/lang/Number;->doubleValue()D
  0032 move-result-wide v2
  0034 invoke-virtual v6, Ljava/lang/Number;->longValue()J
  003a move-result-wide v4
  003c long-to-double v4, v4
  003e cmpl-double v6, v2, v4
  0042 if-nez v6, +003h
  0046 const/4 v1, 1
  0048 return v1
.end method

.method le([B I I)J
  0000 add-int/lit8 v6, v6, -1
  0004 const-wide/16 v0, 0
  0008 if-ltz v6, +020h
  000c const-wide v2, 35184372088831
  0016 cmp-long v2, v0, v2
  001a if-gtz v2, +010h
  001e const-wide/16 v2, 256
  0022 mul-long/2addr v0, v2
  0024 add-int v2, v5, v6
  0028 aget-byte v2, v4, v2
  002c and-int/lit16 v2, v2, 255
  0030 int-to-long v2, v2
  0032 add-long/2addr v0, v2
  0034 add-int/lit8 v6, v6, -1
  0038 goto -18h
  003a const-string v4, "Invalid movie number."
  003e invoke-static v4, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0044 move-result-object v4
  0046 throw v4
  0048 return-wide v0
.end method

.method n(Ljava/util/Map; Ljava/lang/String;)J
  0000 invoke-interface v4, v5, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0006 move-result-object v4
  0008 instance-of v5, v4, Ljava/lang/Number;
  000c if-eqz v5, +016h
  0010 check-cast v4, Ljava/lang/Number;
  0014 invoke-virtual v4, Ljava/lang/Number;->doubleValue()D
  001a move-result-wide v0
  001c invoke-virtual v4, Ljava/lang/Number;->longValue()J
  0022 move-result-wide v2
  0024 long-to-double v2, v2
  0026 cmpl-double v5, v0, v2
  002a if-nez v5, +007h
  002e invoke-virtual v4, Ljava/lang/Number;->longValue()J
  0034 move-result-wide v4
  0036 return-wide v4
  0038 const-string v4, "Invalid movie metadata."
  003c invoke-static v4, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0042 move-result-object v4
  0044 throw v4
.end method

.method read(Ljava/io/RandomAccessFile; J I J)[B
  0000 const-wide/16 v0, 0
  0004 cmp-long v0, v3, v0
  0008 if-ltz v0, +01bh
  000c if-ltz v5, +019h
  0010 const/high16 v0, 1048576
  0014 if-gt v5, v0, +015h
  0018 cmp-long v0, v3, v6
  001c if-gtz v0, +011h
  0020 int-to-long v0, v5
  0022 sub-long/2addr v6, v3
  0024 cmp-long v6, v0, v6
  0028 if-gtz v6, +00bh
  002c new-array v5, v5, [B
  0030 invoke-virtual v2, v3, v4, Ljava/io/RandomAccessFile;->seek(J)V
  0036 invoke-virtual v2, v5, Ljava/io/RandomAccessFile;->readFully([B)V
  003c return-object v5
  003e const-string v2, "The movie contains a truncated or oversized packet."
  0042 invoke-static v2, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0048 move-result-object v2
  004a throw v2
.end method

.method temporary(Ljava/lang/String;)Ljava/io/File;
  0000 new-instance v0, Ljava/io/File;
  0004 iget-object v1, v4, Lcom/personal/aihub/MovieStorage;->staging Ljava/io/File;
  0008 new-instance v2, Ljava/lang/StringBuilder;
  000c const-string v3, "upload-"
  0010 invoke-direct v2, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0016 invoke-virtual v2, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  001c const-string v5, ".part"
  0020 invoke-virtual v2, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0026 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  002c move-result-object v5
  002e invoke-direct v0, v1, v5, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0034 return-object v0
.end method

.method text([B I I)Ljava/lang/String;
  0000 new-instance v0, Ljava/lang/String;
  0004 sget-object v1, Ljava/nio/charset/StandardCharsets;->US_ASCII Ljava/nio/charset/Charset;
  0008 invoke-direct v0, v2, v3, v4, v1, Ljava/lang/String;-><init>([B I I Ljava/nio/charset/Charset;)V
  000e return-object v0
.end method

.method u16([B I)I
  0000 add-int/lit8 v0, v2, 1
  0004 aget-byte v0, v1, v0
  0008 and-int/lit16 v0, v0, 255
  000c aget-byte v1, v1, v2
  0010 and-int/lit16 v1, v1, 255
  0014 shl-int/lit8 v1, v1, 8
  0018 or-int/2addr v1, v0
  001a return v1
.end method

.method u32([B I)J
  0000 add-int/lit8 v0, v8, 3
  0004 aget-byte v0, v7, v0
  0008 int-to-long v0, v0
  000a const-wide/16 v2, 255
  000e and-long/2addr v0, v2
  0010 aget-byte v4, v7, v8
  0014 int-to-long v4, v4
  0016 and-long/2addr v4, v2
  0018 const/16 v6, 24
  001c shl-long/2addr v4, v6
  001e or-long/2addr v0, v4
  0020 add-int/lit8 v4, v8, 1
  0024 aget-byte v4, v7, v4
  0028 int-to-long v4, v4
  002a and-long/2addr v4, v2
  002c const/16 v6, 16
  0030 shl-long/2addr v4, v6
  0032 or-long/2addr v0, v4
  0034 add-int/lit8 v8, v8, 2
  0038 aget-byte v7, v7, v8
  003c int-to-long v7, v7
  003e and-long/2addr v7, v2
  0040 const/16 v2, 8
  0044 shl-long/2addr v7, v2
  0046 or-long/2addr v7, v0
  0048 return-wide v7
.end method

.method utf(Ljava/io/RandomAccessFile; J I J I)Ljava/util/List;
  0000 invoke-static/range v0 ... v5, Lcom/personal/aihub/MovieStorage;->read(Ljava/io/RandomAccessFile; J I J)[B
  0006 move-result-object v0
  0008 array-length v1, v0
  000a const/16 v2, 32
  000e if-lt v1, v2, +020h
  0012 const/4 v1, 0
  0014 const/4 v2, 4
  0016 invoke-static v0, v1, v2, Lcom/personal/aihub/MovieStorage;->text([B I I)Ljava/lang/String;
  001c move-result-object v1
  001e const-string v2, "@UTF"
  0022 invoke-virtual v1, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0028 move-result v1
  002a if-eqz v1, +012h
  002e const/16 v1, 28
  0032 invoke-static v0, v1, Lcom/personal/aihub/MovieStorage;->u32([B I)J
  0038 move-result-wide v1
  003a int-to-long v3, v6
  003c cmp-long v1, v1, v3
  0040 if-gtz v1, +007h
  0044 invoke-static v0, Lcom/personal/aihub/CpkArchive;->utf([B)Ljava/util/List;
  004a move-result-object v0
  004c return-object v0
  004e const-string v0, "Invalid authored movie metadata."
  0052 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0058 move-result-object v0
  005a throw v0
.end method

.method call(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 monitor-enter v11
  0002 iget-object v0, v11, Lcom/personal/aihub/MovieStorage;->root Ljava/io/File;
  0006 invoke-static v0, Lcom/personal/aihub/MovieStorage;->directories(Ljava/io/File;)V
  000c iget-object v0, v11, Lcom/personal/aihub/MovieStorage;->staging Ljava/io/File;
  0010 invoke-static v0, Lcom/personal/aihub/MovieStorage;->directories(Ljava/io/File;)V
  0016 new-instance v0, Ljava/util/ArrayList;
  001a iget-object v1, v11, Lcom/personal/aihub/MovieStorage;->jobs Ljava/util/Map;
  001e invoke-interface v1, Ljava/util/Map;->keySet()Ljava/util/Set;
  0024 move-result-object v1
  0026 invoke-direct v0, v1, Ljava/util/ArrayList;-><init>(Ljava/util/Collection;)V
  002c invoke-virtual v0, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
  0032 move-result-object v0
  0034 invoke-interface v0, Ljava/util/Iterator;->hasNext()Z
  003a move-result v1
  003c if-eqz v1, +024h
  0040 invoke-interface v0, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0046 move-result-object v1
  0048 check-cast v1, Ljava/lang/String;
  004c iget-object v2, v11, Lcom/personal/aihub/MovieStorage;->clock Ljava/util/function/LongSupplier;
  0050 invoke-interface v2, Ljava/util/function/LongSupplier;->getAsLong()J
  0056 move-result-wide v2
  0058 iget-object v4, v11, Lcom/personal/aihub/MovieStorage;->jobs Ljava/util/Map;
  005c invoke-interface v4, v1, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0062 move-result-object v4
  0064 check-cast v4, Lcom/personal/aihub/MovieStorage$Job;
  0068 iget-wide v4, v4, Lcom/personal/aihub/MovieStorage$Job;->touched J
  006c sub-long/2addr v2, v4
  006e const-wide/32 v4, 600000
  0074 cmp-long v2, v2, v4
  0078 if-ltz v2, -022h
  007c invoke-direct v11, v1, Lcom/personal/aihub/MovieStorage;->discard(Ljava/lang/String;)V
  0082 goto -27h
  0084 const-string v0, "action"
  0088 invoke-virtual v12, v0, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  008e move-result-object v0
  0090 instance-of v1, v0, Ljava/lang/String;
  0094 if-eqz v1, +361h
  0098 check-cast v0, Ljava/lang/String;
  009c const-string v1, "begin"
  00a0 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00a6 move-result v1
  00a8 if-eqz v1, +00bh
  00ac const-string v1, "action"
  00b0 const-string v2, "name"
  00b4 filled-new-array v1, v2, [Ljava/lang/String;
  00ba move-result-object v1
  00bc goto +36h
  00be const-string v1, "append"
  00c2 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00c8 move-result v1
  00ca if-eqz v1, +00fh
  00ce const-string v1, "action"
  00d2 const-string v2, "uploadId"
  00d6 const-string v3, "offset"
  00da const-string v4, "data"
  00de filled-new-array v1, v2, v3, v4, [Ljava/lang/String;
  00e4 move-result-object v1
  00e6 goto +21h
  00e8 const-string v1, "finish"
  00ec invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00f2 move-result v1
  00f4 if-nez v1, +012h
  00f8 const-string v1, "cancel"
  00fc invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0102 move-result v1
  0104 if-eqz v1, +003h
  0108 goto +8h
  010a const-string v12, "Invalid movie upload action."
  010e invoke-static v12, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0114 move-result-object v12
  0116 throw v12
  0118 const-string v1, "action"
  011c const-string v2, "uploadId"
  0120 filled-new-array v1, v2, [Ljava/lang/String;
  0126 move-result-object v1
  0128 new-instance v2, Ljava/util/HashSet;
  012c invoke-static v1, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  0132 move-result-object v1
  0134 invoke-direct v2, v1, Ljava/util/HashSet;-><init>(Ljava/util/Collection;)V
  013a invoke-virtual v12, Lorg/json/JSONObject;->keys()Ljava/util/Iterator;
  0140 move-result-object v1
  0142 invoke-interface v1, Ljava/util/Iterator;->hasNext()Z
  0148 move-result v3
  014a if-eqz v3, +014h
  014e invoke-interface v1, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0154 move-result-object v3
  0156 invoke-virtual v2, v3, Ljava/util/HashSet;->contains(Ljava/lang/Object;)Z
  015c move-result v3
  015e if-eqz v3, +003h
  0162 goto -10h
  0164 const-string v12, "Invalid movie upload arguments."
  0168 invoke-static v12, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  016e move-result-object v12
  0170 throw v12
  0172 const-string v1, "begin"
  0176 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  017c move-result v1
  017e const/4 v2, 4
  0180 const/4 v3, 1
  0182 const/4 v4, 0
  0184 if-eqz v1, +08ah
  0188 iget-object v0, v11, Lcom/personal/aihub/MovieStorage;->jobs Ljava/util/Map;
  018c invoke-interface v0, Ljava/util/Map;->size()I
  0192 move-result v0
  0194 if-ge v0, v2, +07bh
  0198 const-string v0, "name"
  019c invoke-virtual v12, v0, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  01a2 move-result-object v0
  01a4 const-string v1, "name"
  01a8 invoke-virtual v12, v1, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  01ae move-result v1
  01b0 if-eqz v1, +018h
  01b4 instance-of v1, v0, Ljava/lang/String;
  01b8 if-eqz v1, +00dh
  01bc check-cast v0, Ljava/lang/String;
  01c0 invoke-virtual v0, Ljava/lang/String;->length()I
  01c6 move-result v0
  01c8 const/16 v1, 160
  01cc if-gt v0, v1, +003h
  01d0 goto +8h
  01d2 const-string v12, "Choose a movie name of 160 characters or less."
  01d6 invoke-static v12, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  01dc move-result-object v12
  01de throw v12
  01e0 const-string v0, "name"
  01e4 const-string v1, "Custom movie"
  01e8 invoke-virtual v12, v0, v1, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  01ee move-result-object v12
  01f0 const-string v0, "[\x00-\x1f\x7f]"
  01f4 const-string v1, ""
  01f8 invoke-virtual v12, v0, v1, Ljava/lang/String;->replaceAll(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  01fe move-result-object v12
  0200 invoke-virtual v12, Ljava/lang/String;->isEmpty()Z
  0206 move-result v0
  0208 if-eqz v0, +004h
  020c const-string v12, "Custom movie"
  0210 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0216 move-result-object v0
  0218 invoke-virtual v0, Ljava/util/UUID;->toString()Ljava/lang/String;
  021e move-result-object v0
  0220 invoke-direct v11, v0, Lcom/personal/aihub/MovieStorage;->temporary(Ljava/lang/String;)Ljava/io/File;
  0226 move-result-object v1
  0228 invoke-virtual v1, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  022e move-result-object v1
  0230 new-array v2, v4, [B
  0234 const/4 v5, 2
  0236 new-array v5, v5, [Ljava/nio/file/OpenOption;
  023a sget-object v6, Ljava/nio/file/StandardOpenOption;->CREATE_NEW Ljava/nio/file/StandardOpenOption;
  023e aput-object v6, v5, v4
  0242 sget-object v4, Ljava/nio/file/StandardOpenOption;->WRITE Ljava/nio/file/StandardOpenOption;
  0246 aput-object v4, v5, v3
  024a invoke-static v1, v2, v5, Ljava/nio/file/Files;->write(Ljava/nio/file/Path; [B [Ljava/nio/file/OpenOption;)Ljava/nio/file/Path;
  0250 iget-object v1, v11, Lcom/personal/aihub/MovieStorage;->jobs Ljava/util/Map;
  0254 new-instance v2, Lcom/personal/aihub/MovieStorage$Job;
  0258 iget-object v3, v11, Lcom/personal/aihub/MovieStorage;->clock Ljava/util/function/LongSupplier;
  025c invoke-interface v3, Ljava/util/function/LongSupplier;->getAsLong()J
  0262 move-result-wide v3
  0264 invoke-direct v2, v12, v3, v4, Lcom/personal/aihub/MovieStorage$Job;-><init>(Ljava/lang/String; J)V
  026a invoke-interface v1, v0, v2, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0270 new-instance v12, Lorg/json/JSONObject;
  0274 invoke-direct v12, Lorg/json/JSONObject;-><init>()V
  027a const-string v1, "uploadId"
  027e invoke-virtual v12, v1, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0284 move-result-object v12
  0286 monitor-exit v11
  0288 return-object v12
  028a const-string v12, "Finish or cancel another movie upload first."
  028e invoke-static v12, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0294 move-result-object v12
  0296 throw v12
  0298 const-string v1, "uploadId"
  029c invoke-virtual v12, v1, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  02a2 move-result-object v1
  02a4 instance-of v5, v1, Ljava/lang/String;
  02a8 if-eqz v5, +250h
  02ac move-object v5, v1
  02ae check-cast v5, Ljava/lang/String;
  02b2 const-string v6, "[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}"
  02b6 invoke-virtual v5, v6, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  02bc move-result v5
  02be if-eqz v5, +245h
  02c2 iget-object v5, v11, Lcom/personal/aihub/MovieStorage;->jobs Ljava/util/Map;
  02c6 invoke-interface v5, v1, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z
  02cc move-result v5
  02ce if-eqz v5, +23dh
  02d2 check-cast v1, Ljava/lang/String;
  02d6 iget-object v5, v11, Lcom/personal/aihub/MovieStorage;->jobs Ljava/util/Map;
  02da invoke-interface v5, v1, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  02e0 move-result-object v5
  02e2 check-cast v5, Lcom/personal/aihub/MovieStorage$Job;
  02e6 invoke-direct v11, v1, Lcom/personal/aihub/MovieStorage;->temporary(Ljava/lang/String;)Ljava/io/File;
  02ec move-result-object v6
  02ee const-string v7, "cancel"
  02f2 invoke-virtual v0, v7, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  02f8 move-result v7
  02fa if-eqz v7, +012h
  02fe invoke-direct v11, v1, Lcom/personal/aihub/MovieStorage;->discard(Ljava/lang/String;)V
  0304 new-instance v12, Lorg/json/JSONObject;
  0308 invoke-direct v12, Lorg/json/JSONObject;-><init>()V
  030e const-string v0, "canceled"
  0312 invoke-virtual v12, v0, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0318 move-result-object v12
  031a monitor-exit v11
  031c return-object v12
  031e const-string v7, "append"
  0322 invoke-virtual v0, v7, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0328 move-result v0
  032a if-eqz v0, +143h
  032e const-string v0, "offset"
  0332 invoke-virtual v12, v0, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  0338 move-result-object v0
  033a const-string v3, "data"
  033e invoke-virtual v12, v3, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  0344 move-result-object v12
  0346 invoke-static v0, Lcom/personal/aihub/MovieStorage;->integer(Ljava/lang/Object;)Z
  034c move-result v3
  034e if-eqz v3, +12ah
  0352 check-cast v0, Ljava/lang/Number;
  0356 invoke-virtual v0, Ljava/lang/Number;->longValue()J
  035c move-result-wide v3
  035e iget-wide v7, v5, Lcom/personal/aihub/MovieStorage$Job;->bytes J
  0362 cmp-long v0, v3, v7
  0366 if-nez v0, +11eh
  036a instance-of v0, v12, Ljava/lang/String;
  036e if-eqz v0, +113h
  0372 check-cast v12, Ljava/lang/String;
  0376 invoke-virtual v12, Ljava/lang/String;->isEmpty()Z
  037c move-result v0
  037e if-nez v0, +104h
  0382 invoke-virtual v12, Ljava/lang/String;->length()I
  0388 move-result v0
  038a const v3, 349528
  0390 if-gt v0, v3, +0fbh
  0394 invoke-virtual v12, Ljava/lang/String;->length()I
  039a move-result v0
  039c rem-int/2addr v0, v2
  039e if-nez v0, +0f4h
  03a2 const-string v0, "[A-Za-z0-9+/]*={0,2}"
  03a6 invoke-virtual v12, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  03ac move-result v0
  03ae if-eqz v0, +0ech
  03b2 invoke-static Ljava/util/Base64;->getDecoder()Ljava/util/Base64$Decoder;
  03b8 move-result-object v0
  03ba invoke-virtual v0, v12, Ljava/util/Base64$Decoder;->decode(Ljava/lang/String;)[B
  03c0 move-result-object v0
  03c2 array-length v2, v0
  03c4 if-eqz v2, +0d3h
  03c8 array-length v2, v0
  03ca const/high16 v3, 262144
  03ce if-gt v2, v3, +0ceh
  03d2 invoke-static Ljava/util/Base64;->getEncoder()Ljava/util/Base64$Encoder;
  03d8 move-result-object v2
  03da invoke-virtual v2, v0, Ljava/util/Base64$Encoder;->encodeToString([B)Ljava/lang/String;
  03e0 move-result-object v2
  03e2 invoke-virtual v2, v12, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  03e8 move-result v12
  03ea if-eqz v12, +0c0h
  03ee iget-object v12, v11, Lcom/personal/aihub/MovieStorage;->jobs Ljava/util/Map;
  03f2 invoke-interface v12, Ljava/util/Map;->values()Ljava/util/Collection;
  03f8 move-result-object v12
  03fa invoke-interface v12, Ljava/util/Collection;->iterator()Ljava/util/Iterator;
  0400 move-result-object v12
  0402 const-wide/16 v2, 0
  0406 invoke-interface v12, Ljava/util/Iterator;->hasNext()Z
  040c move-result v4
  040e if-eqz v4, +00ch
  0412 invoke-interface v12, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0418 move-result-object v4
  041a check-cast v4, Lcom/personal/aihub/MovieStorage$Job;
  041e iget-wide v7, v4, Lcom/personal/aihub/MovieStorage$Job;->bytes J
  0422 add-long/2addr v2, v7
  0424 goto -fh
  0426 iget-wide v7, v5, Lcom/personal/aihub/MovieStorage$Job;->bytes J
  042a array-length v12, v0
  042c int-to-long v9, v12
  042e add-long/2addr v7, v9
  0430 const-wide/32 v9, 100663296
  0436 cmp-long v12, v7, v9
  043a if-gtz v12, +08eh
  043e array-length v12, v0
  0440 int-to-long v7, v12
  0442 add-long/2addr v2, v7
  0444 const-wide/32 v7, 402653184
  044a cmp-long v12, v2, v7
  044e if-gtz v12, +084h
  0452 invoke-virtual v6, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0458 move-result-object v12
  045a invoke-static v12, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  0460 move-result v12
  0462 if-nez v12, +06eh
  0466 invoke-virtual v6, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  046c move-result-object v12
  046e sget-object v2, Ljava/nio/file/LinkOption;->NOFOLLOW_LINKS Ljava/nio/file/LinkOption;
  0472 filled-new-array v2, [Ljava/nio/file/LinkOption;
  0478 move-result-object v2
  047a invoke-static v12, v2, Ljava/nio/file/Files;->isRegularFile(Ljava/nio/file/Path; [Ljava/nio/file/LinkOption;)Z
  0480 move-result v12
  0482 if-eqz v12, +05eh
  0486 invoke-virtual v6, Ljava/io/File;->length()J
  048c move-result-wide v2
  048e iget-wide v7, v5, Lcom/personal/aihub/MovieStorage$Job;->bytes J
  0492 cmp-long v12, v2, v7
  0496 if-nez v12, +054h
  049a new-instance v12, Ljava/io/RandomAccessFile;
  049e const-string v2, "rw"
  04a2 invoke-direct v12, v6, v2, Ljava/io/RandomAccessFile;-><init>(Ljava/io/File; Ljava/lang/String;)V
  04a8 invoke-virtual v12, Ljava/io/RandomAccessFile;->length()J
  04ae move-result-wide v2
  04b0 iget-wide v6, v5, Lcom/personal/aihub/MovieStorage$Job;->bytes J
  04b4 cmp-long v2, v2, v6
  04b8 if-nez v2, +032h
  04bc iget-wide v2, v5, Lcom/personal/aihub/MovieStorage$Job;->bytes J
  04c0 invoke-virtual v12, v2, v3, Ljava/io/RandomAccessFile;->seek(J)V
  04c6 invoke-virtual v12, v0, Ljava/io/RandomAccessFile;->write([B)V
  04cc invoke-virtual v12, Ljava/io/RandomAccessFile;->getFD()Ljava/io/FileDescriptor;
  04d2 move-result-object v2
  04d4 invoke-virtual v2, Ljava/io/FileDescriptor;->sync()V
  04da invoke-virtual v12, Ljava/io/RandomAccessFile;->close()V
  04e0 iget-wide v2, v5, Lcom/personal/aihub/MovieStorage$Job;->bytes J
  04e4 array-length v12, v0
  04e6 int-to-long v6, v12
  04e8 add-long/2addr v2, v6
  04ea iput-wide v2, v5, Lcom/personal/aihub/MovieStorage$Job;->bytes J
  04ee iget-object v12, v11, Lcom/personal/aihub/MovieStorage;->clock Ljava/util/function/LongSupplier;
  04f2 invoke-interface v12, Ljava/util/function/LongSupplier;->getAsLong()J
  04f8 move-result-wide v2
  04fa iput-wide v2, v5, Lcom/personal/aihub/MovieStorage$Job;->touched J
  04fe new-instance v12, Lorg/json/JSONObject;
  0502 invoke-direct v12, Lorg/json/JSONObject;-><init>()V
  0508 const-string v0, "bytes"
  050c iget-wide v2, v5, Lcom/personal/aihub/MovieStorage$Job;->bytes J
  0510 invoke-virtual v12, v0, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0516 move-result-object v12
  0518 monitor-exit v11
  051a return-object v12
  051c const-string v0, "The temporary movie file changed."
  0520 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0526 move-result-object v0
  0528 throw v0
  052a move-exception v0
  052c invoke-virtual v12, Ljava/io/RandomAccessFile;->close()V
  0532 goto +5h
  0534 move-exception v12
  0536 invoke-virtual v0, v12, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  053c throw v0
  053e const-string v12, "The temporary movie file changed."
  0542 invoke-static v12, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0548 move-result-object v12
  054a throw v12
  054c move-exception v12
  054e invoke-direct v11, v1, Lcom/personal/aihub/MovieStorage;->discard(Ljava/lang/String;)V
  0554 throw v12
  0556 invoke-direct v11, v1, Lcom/personal/aihub/MovieStorage;->discard(Ljava/lang/String;)V
  055c const-string v12, "Movie uploads are limited to 96 MB per movie and 384 MB total."
  0560 invoke-static v12, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0566 move-result-object v12
  0568 throw v12
  056a const-string v12, "Invalid movie chunk."
  056e invoke-static v12, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0574 move-result-object v12
  0576 throw v12
  0578 const-string v12, "Invalid movie chunk."
  057c invoke-static v12, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0582 move-result-object v12
  0584 throw v12
  0586 const-string v12, "Invalid movie chunk."
  058a invoke-static v12, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0590 move-result-object v12
  0592 throw v12
  0594 const-string v12, "Invalid movie chunk."
  0598 invoke-static v12, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  059e move-result-object v12
  05a0 throw v12
  05a2 const-string v12, "Movie chunks must arrive in their original order. Retry this chunk."
  05a6 invoke-static v12, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  05ac move-result-object v12
  05ae throw v12
  05b0 const/4 v12, 0
  05b2 invoke-virtual v6, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  05b8 move-result-object v0
  05ba invoke-static v0, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  05c0 move-result v0
  05c2 if-nez v0, +0b0h
  05c6 invoke-virtual v6, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  05cc move-result-object v0
  05ce sget-object v2, Ljava/nio/file/LinkOption;->NOFOLLOW_LINKS Ljava/nio/file/LinkOption;
  05d2 filled-new-array v2, [Ljava/nio/file/LinkOption;
  05d8 move-result-object v2
  05da invoke-static v0, v2, Ljava/nio/file/Files;->isRegularFile(Ljava/nio/file/Path; [Ljava/nio/file/LinkOption;)Z
  05e0 move-result v0
  05e2 if-eqz v0, +0a0h
  05e6 invoke-virtual v6, Ljava/io/File;->length()J
  05ec move-result-wide v7
  05ee iget-wide v9, v5, Lcom/personal/aihub/MovieStorage$Job;->bytes J
  05f2 cmp-long v0, v7, v9
  05f6 if-nez v0, +096h
  05fa invoke-static v6, Lcom/personal/aihub/MovieStorage;->inspect(Ljava/io/File;)Lorg/json/JSONObject;
  0600 move-result-object v0
  0602 new-instance v2, Ljava/lang/StringBuilder;
  0606 invoke-direct v2, Ljava/lang/StringBuilder;-><init>()V
  060c const-string v7, "generated-movie-"
  0610 invoke-virtual v2, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0616 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  061c move-result-object v7
  061e invoke-virtual v2, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0624 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  062a move-result-object v2
  062c new-instance v7, Ljava/io/File;
  0630 iget-object v8, v11, Lcom/personal/aihub/MovieStorage;->root Ljava/io/File;
  0634 invoke-direct v7, v8, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  063a invoke-virtual v7, Ljava/io/File;->mkdir()Z
  0640 move-result v12
  0642 if-eqz v12, +067h
  0646 invoke-static v7, Lcom/personal/aihub/MovieStorage;->directories(Ljava/io/File;)V
  064c invoke-virtual v6, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0652 move-result-object v12
  0654 new-instance v6, Ljava/io/File;
  0658 const-string v8, "movie.usm"
  065c invoke-direct v6, v7, v8, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0662 invoke-virtual v6, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0668 move-result-object v6
  066a new-array v3, v3, [Ljava/nio/file/CopyOption;
  066e sget-object v8, Ljava/nio/file/StandardCopyOption;->ATOMIC_MOVE Ljava/nio/file/StandardCopyOption;
  0672 aput-object v8, v3, v4
  0676 invoke-static v12, v6, v3, Ljava/nio/file/Files;->move(Ljava/nio/file/Path; Ljava/nio/file/Path; [Ljava/nio/file/CopyOption;)Ljava/nio/file/Path;
  067c iget-object v12, v11, Lcom/personal/aihub/MovieStorage;->jobs Ljava/util/Map;
  0680 invoke-interface v12, v1, Ljava/util/Map;->remove(Ljava/lang/Object;)Ljava/lang/Object;
  0686 const-string v12, "storageTag"
  068a const-string v3, "-"
  068e const-string v6, ""
  0692 invoke-virtual v1, v3, v6, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  0698 move-result-object v3
  069a invoke-virtual v0, v12, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  06a0 move-result-object v12
  06a2 const-string v0, "key"
  06a6 new-instance v3, Ljava/lang/StringBuilder;
  06aa invoke-direct v3, Ljava/lang/StringBuilder;-><init>()V
  06b0 invoke-virtual v3, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  06b6 const-string v2, "/movie.usm"
  06ba invoke-virtual v3, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  06c0 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  06c6 move-result-object v2
  06c8 invoke-virtual v12, v0, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  06ce move-result-object v12
  06d0 const-string v0, "path"
  06d4 const-string v2, "movie.usm"
  06d8 invoke-virtual v12, v0, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  06de move-result-object v12
  06e0 const-string v0, "size"
  06e4 iget-wide v2, v5, Lcom/personal/aihub/MovieStorage$Job;->bytes J
  06e8 invoke-virtual v12, v0, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  06ee move-result-object v12
  06f0 const-string v0, "name"
  06f4 iget-object v2, v5, Lcom/personal/aihub/MovieStorage$Job;->name Ljava/lang/String;
  06f8 invoke-virtual v12, v0, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  06fe move-result-object v12
  0700 const-string v0, "image"
  0704 invoke-virtual v12, v0, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  070a move-result-object v12
  070c monitor-exit v11
  070e return-object v12
  0710 const-string v12, "The movie destination is unavailable."
  0714 invoke-static v12, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  071a move-result-object v12
  071c throw v12
  071e move-exception v12
  0720 goto +bh
  0722 const-string v0, "The temporary movie file changed."
  0726 invoke-static v0, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  072c move-result-object v0
  072e throw v0
  0730 move-exception v0
  0732 move-object v7, v12
  0734 move-object v12, v0
  0736 invoke-direct v11, v1, Lcom/personal/aihub/MovieStorage;->discard(Ljava/lang/String;)V
  073c if-eqz v7, +005h
  0740 invoke-virtual v7, Ljava/io/File;->delete()Z
  0746 throw v12
  0748 const-string v12, "This movie upload expired or was canceled. Start it again."
  074c invoke-static v12, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0752 move-result-object v12
  0754 throw v12
  0756 const-string v12, "Choose a valid movie upload action."
  075a invoke-static v12, Lcom/personal/aihub/MovieStorage;->fail(Ljava/lang/String;)Ljava/io/IOException;
  0760 move-result-object v12
  0762 throw v12
  0764 move-exception v12
  0766 monitor-exit v11
  0768 throw v12
.end method