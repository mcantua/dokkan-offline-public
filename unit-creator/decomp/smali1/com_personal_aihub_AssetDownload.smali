.class Lcom/personal/aihub/AssetDownload;
.super Ljava/lang/Object;
.field GROUP Ljava/lang/String;
.field LIMIT J

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method destination(Ljava/io/File; Ljava/lang/String;)Ljava/io/File;
  0000 invoke-static v5, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  0006 move-result v0
  0008 if-eqz v0, +091h
  000c invoke-virtual v4, Ljava/io/File;->isDirectory()Z
  0012 move-result v0
  0014 if-eqz v0, +08bh
  0018 invoke-virtual v4, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  001e move-result-object v0
  0020 invoke-static v0, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  0026 move-result v0
  0028 if-nez v0, +081h
  002c const-string v0, "/"
  0030 invoke-virtual v5, v0, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  0036 move-result-object v5
  0038 const/4 v0, 0
  003a move-object v1, v4
  003c array-length v2, v5
  003e add-int/lit8 v2, v2, -1
  0042 if-ge v0, v2, +034h
  0046 new-instance v2, Ljava/io/File;
  004a aget-object v3, v5, v0
  004e invoke-direct v2, v1, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0054 invoke-virtual v2, Ljava/io/File;->isDirectory()Z
  005a move-result v1
  005c if-nez v1, +011h
  0060 invoke-virtual v2, Ljava/io/File;->mkdir()Z
  0066 move-result v1
  0068 if-eqz v1, +003h
  006c goto +9h
  006e new-instance v4, Ljava/io/IOException;
  0072 const-string v5, "Cannot create asset collection."
  0076 invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  007c throw v4
  007e invoke-virtual v2, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0084 move-result-object v1
  0086 invoke-static v1, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  008c move-result v1
  008e if-nez v1, +006h
  0092 add-int/lit8 v0, v0, 1
  0096 move-object v1, v2
  0098 goto -2eh
  009a new-instance v4, Ljava/io/IOException;
  009e const-string v5, "Asset collections cannot use symbolic links."
  00a2 invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00a8 throw v4
  00aa new-instance v0, Ljava/io/File;
  00ae array-length v2, v5
  00b0 add-int/lit8 v2, v2, -1
  00b4 aget-object v5, v5, v2
  00b8 invoke-direct v0, v1, v5, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00be invoke-virtual v0, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  00c4 move-result-object v5
  00c6 invoke-static v5, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  00cc move-result v5
  00ce if-nez v5, +026h
  00d2 invoke-virtual v0, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  00d8 move-result-object v5
  00da new-instance v1, Ljava/lang/StringBuilder;
  00de invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  00e4 invoke-virtual v4, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  00ea move-result-object v4
  00ec invoke-static v4, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  00f2 move-result-object v4
  00f4 invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00fa sget-object v4, Ljava/io/File;->separator Ljava/lang/String;
  00fe invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0104 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  010a move-result-object v4
  010c invoke-virtual v5, v4, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0112 move-result v4
  0114 if-eqz v4, +003h
  0118 return-object v0
  011a new-instance v4, Ljava/io/IOException;
  011e const-string v5, "Invalid asset destination."
  0122 invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0128 throw v4
  012a new-instance v4, Ljava/io/IOException;
  012e const-string v5, "Invalid asset collection."
  0132 invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0138 throw v4
.end method

.method openOfficial(Ljava/lang/String;)Ljava/net/HttpURLConnection;
  0000 new-instance v0, Ljava/net/URL;
  0004 invoke-direct v0, v1, Ljava/net/URL;-><init>(Ljava/lang/String;)V
  000a const/4 v1, 0
  000c invoke-static v0, v1, Lcom/personal/aihub/AssetDownload;->openOfficial(Ljava/net/URL; I)Ljava/net/HttpURLConnection;
  0012 move-result-object v1
  0014 return-object v1
.end method

.method openOfficial(Ljava/net/URL; I)Ljava/net/HttpURLConnection;
  0000 const/4 v0, 5
  0002 if-gt v4, v0, +097h
  0006 const-string v0, "https"
  000a invoke-virtual v3, Ljava/net/URL;->getProtocol()Ljava/lang/String;
  0010 move-result-object v1
  0012 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0018 move-result v0
  001a if-eqz v0, +08bh
  001e const-string v0, "dokkan-eclipse.com"
  0022 invoke-virtual v3, Ljava/net/URL;->getHost()Ljava/lang/String;
  0028 move-result-object v1
  002a invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0030 move-result v0
  0032 if-eqz v0, +07fh
  0036 invoke-virtual v3, Ljava/net/URL;->getUserInfo()Ljava/lang/String;
  003c move-result-object v0
  003e if-nez v0, +079h
  0042 invoke-virtual v3, Ljava/net/URL;->getPort()I
  0048 move-result v0
  004a const/4 v1, -1
  004c if-ne v0, v1, +072h
  0050 invoke-virtual v3, Ljava/net/URL;->openConnection()Ljava/net/URLConnection;
  0056 move-result-object v0
  0058 check-cast v0, Ljava/net/HttpURLConnection;
  005c const/16 v1, 20000
  0060 invoke-virtual v0, v1, Ljava/net/HttpURLConnection;->setConnectTimeout(I)V
  0066 const v1, 60000
  006c invoke-virtual v0, v1, Ljava/net/HttpURLConnection;->setReadTimeout(I)V
  0072 const/4 v1, 0
  0074 invoke-virtual v0, v1, Ljava/net/HttpURLConnection;->setInstanceFollowRedirects(Z)V
  007a const-string v1, "User-Agent"
  007e const-string v2, "DokkanUnitCreator/2.7"
  0082 invoke-virtual v0, v1, v2, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String; Ljava/lang/String;)V
  0088 const-string v1, "Accept-Encoding"
  008c const-string v2, "identity"
  0090 invoke-virtual v0, v1, v2, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String; Ljava/lang/String;)V
  0096 invoke-virtual v0, Ljava/net/HttpURLConnection;->getResponseCode()I
  009c move-result v1
  009e const/16 v2, 300
  00a2 if-lt v1, v2, +026h
  00a6 const/16 v2, 400
  00aa if-lt v1, v2, +003h
  00ae goto +20h
  00b0 const-string v1, "Location"
  00b4 invoke-virtual v0, v1, Ljava/net/HttpURLConnection;->getHeaderField(Ljava/lang/String;)Ljava/lang/String;
  00ba move-result-object v1
  00bc invoke-virtual v0, Ljava/net/HttpURLConnection;->disconnect()V
  00c2 if-eqz v1, +00eh
  00c6 new-instance v0, Ljava/net/URL;
  00ca invoke-direct v0, v3, v1, Ljava/net/URL;-><init>(Ljava/net/URL; Ljava/lang/String;)V
  00d0 add-int/lit8 v4, v4, 1
  00d4 invoke-static v0, v4, Lcom/personal/aihub/AssetDownload;->openOfficial(Ljava/net/URL; I)Ljava/net/HttpURLConnection;
  00da move-result-object v3
  00dc return-object v3
  00de new-instance v3, Ljava/io/IOException;
  00e2 const-string v4, "Invalid Eclipse redirect."
  00e6 invoke-direct v3, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00ec throw v3
  00ee const/16 v3, 200
  00f2 if-ne v1, v3, +003h
  00f6 return-object v0
  00f8 invoke-virtual v0, Ljava/net/HttpURLConnection;->disconnect()V
  00fe new-instance v3, Ljava/io/IOException;
  0102 new-instance v4, Ljava/lang/StringBuilder;
  0106 const-string v0, "Eclipse returned HTTP "
  010a invoke-direct v4, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0110 invoke-virtual v4, v1, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  0116 const-string v0, "."
  011a invoke-virtual v4, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0120 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0126 move-result-object v4
  0128 invoke-direct v3, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  012e throw v3
  0130 new-instance v3, Ljava/io/IOException;
  0134 const-string v4, "Only official Eclipse resource routes are supported."
  0138 invoke-direct v3, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  013e throw v3
.end method

.method write(Ljava/net/HttpURLConnection; Ljava/io/File; Z J)J
  0000 move-object/from16 v1, v19
  0004 const-wide/16 v2, 1
  0008 cmp-long v0, v22, v2
  000c if-ltz v0, +185h
  0010 const-wide/32 v2, 167772160
  0016 cmp-long v0, v22, v2
  001a if-gtz v0, +17eh
  001e new-instance v2, Ljava/io/File;
  0022 invoke-virtual/range v20, Ljava/io/File;->getParentFile()Ljava/io/File;
  0028 move-result-object v0
  002a new-instance v3, Ljava/lang/StringBuilder;
  002e const-string v4, ".download-"
  0032 invoke-direct v3, v4, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0038 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  003e move-result-object v4
  0040 invoke-virtual v3, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0046 const-string v4, ".tmp"
  004a invoke-virtual v3, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0050 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0056 move-result-object v3
  0058 invoke-direct v2, v0, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  005e invoke-virtual/range v19, Ljava/net/HttpURLConnection;->getResponseCode()I
  0064 move-result v0
  0066 const/16 v3, 200
  006a if-ne v0, v3, +142h
  006e const-string v0, "Content-Length"
  0072 invoke-virtual v1, v0, Ljava/net/HttpURLConnection;->getHeaderField(Ljava/lang/String;)Ljava/lang/String;
  0078 move-result-object v0
  007a const-string v3, "Resource download exceeds160MB."
  007e if-eqz v0, +027h
  0082 const-string v4, "[0-9]+"
  0086 invoke-virtual v0, v4, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  008c move-result v4
  008e const-string v5, "Invalid resource declared size."
  0092 if-eqz v4, +017h
  0096 invoke-static v0, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  009c move-result-wide v4
  009e cmp-long v0, v4, v22
  00a2 if-gtz v0, +003h
  00a6 goto +15h
  00a8 new-instance v0, Ljava/io/IOException;
  00ac invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00b2 throw v0
  00b4 new-instance v0, Ljava/io/IOException;
  00b8 invoke-direct v0, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00be throw v0
  00c0 new-instance v0, Ljava/io/IOException;
  00c4 invoke-direct v0, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00ca throw v0
  00cc const-wide/16 v4, -1
  00d0 const-string v0, "Content-Encoding"
  00d4 invoke-virtual v1, v0, Ljava/net/HttpURLConnection;->getHeaderField(Ljava/lang/String;)Ljava/lang/String;
  00da move-result-object v0
  00dc if-eqz v0, +013h
  00e0 const-string v6, "identity"
  00e4 invoke-virtual v0, v6, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z
  00ea move-result v0
  00ec if-eqz v0, +003h
  00f0 goto +9h
  00f2 new-instance v0, Ljava/io/IOException;
  00f6 const-string v3, "Unsupported resource HTTP compression."
  00fa invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0100 throw v0
  0102 if-eqz v21, +01bh
  0106 invoke-virtual/range v20, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  010c move-result-object v0
  010e sget-object v6, Ljava/nio/file/LinkOption;->NOFOLLOW_LINKS Ljava/nio/file/LinkOption;
  0112 filled-new-array v6, [Ljava/nio/file/LinkOption;
  0118 move-result-object v6
  011a invoke-static v0, v6, Ljava/nio/file/Files;->exists(Ljava/nio/file/Path; [Ljava/nio/file/LinkOption;)Z
  0120 move-result v0
  0122 if-nez v0, +003h
  0126 goto +9h
  0128 new-instance v0, Ljava/io/IOException;
  012c const-string v3, "This artwork collection already contains that resource."
  0130 invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0136 throw v0
  0138 invoke-virtual/range v19, Ljava/net/HttpURLConnection;->getInputStream()Ljava/io/InputStream;
  013e move-result-object v6
  0140 invoke-virtual v2, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0146 move-result-object v0
  0148 const/4 v7, 2
  014a new-array v8, v7, [Ljava/nio/file/OpenOption;
  014e sget-object v9, Ljava/nio/file/StandardOpenOption;->CREATE_NEW Ljava/nio/file/StandardOpenOption;
  0152 const/4 v10, 0
  0154 aput-object v9, v8, v10
  0158 sget-object v9, Ljava/nio/file/StandardOpenOption;->WRITE Ljava/nio/file/StandardOpenOption;
  015c const/4 v11, 1
  015e aput-object v9, v8, v11
  0162 invoke-static v0, v8, Ljava/nio/file/Files;->newOutputStream(Ljava/nio/file/Path; [Ljava/nio/file/OpenOption;)Ljava/io/OutputStream;
  0168 move-result-object v8
  016a const/high16 v0, 65536
  016e new-array v0, v0, [B
  0172 const-wide/16 v12, 0
  0176 move-wide v14, v12
  0178 invoke-virtual v6, v0, Ljava/io/InputStream;->read([B)I
  017e move-result v9
  0180 const/4 v11, -1
  0182 if-eq v9, v11, +038h
  0186 move-object/from16 v16, v8
  018a int-to-long v7, v9
  018c sub-long v17, v22, v14
  0190 cmp-long v17, v7, v17
  0194 if-gtz v17, +025h
  0198 cmp-long v17, v4, v12
  019c if-ltz v17, +017h
  01a0 sub-long v17, v4, v14
  01a4 cmp-long v17, v7, v17
  01a8 if-gtz v17, +003h
  01ac goto +fh
  01ae new-instance v0, Ljava/io/IOException;
  01b2 const-string v3, "Resource size does not match its download."
  01b6 invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01bc throw v0
  01be move-exception v0
  01c0 move-object v3, v0
  01c2 move-object/from16 v11, v16
  01c6 goto/16 +07ah
  01ca move-object/from16 v11, v16
  01ce invoke-virtual v11, v0, v10, v9, Ljava/io/OutputStream;->write([B I I)V
  01d4 add-long/2addr v14, v7
  01d6 move-object v8, v11
  01d8 const/4 v7, 2
  01da const/4 v11, 1
  01dc goto -32h
  01de move-object/from16 v11, v16
  01e2 new-instance v0, Ljava/io/IOException;
  01e6 invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01ec throw v0
  01ee move-exception v0
  01f0 goto +64h
  01f2 move-object v11, v8
  01f4 if-eqz v11, +005h
  01f8 invoke-virtual v11, Ljava/io/OutputStream;->close()V
  01fe if-eqz v6, +005h
  0202 invoke-virtual v6, Ljava/io/InputStream;->close()V
  0208 cmp-long v0, v4, v12
  020c if-ltz v0, +00fh
  0210 cmp-long v0, v14, v4
  0214 if-nez v0, +003h
  0218 goto +9h
  021a new-instance v0, Ljava/io/IOException;
  021e const-string v3, "The resource download was incomplete."
  0222 invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0228 throw v0
  022a if-eqz v21, +010h
  022e invoke-virtual v2, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0234 move-result-object v0
  0236 invoke-virtual/range v20, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  023c move-result-object v3
  023e new-array v4, v10, [Ljava/nio/file/CopyOption;
  0242 invoke-static v0, v3, v4, Ljava/nio/file/Files;->move(Ljava/nio/file/Path; Ljava/nio/file/Path; [Ljava/nio/file/CopyOption;)Ljava/nio/file/Path;
  0248 goto +2bh
  024a invoke-virtual v2, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0250 move-result-object v0
  0252 invoke-virtual/range v20, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0258 move-result-object v3
  025a const/4 v4, 2
  025c new-array v4, v4, [Ljava/nio/file/CopyOption;
  0260 sget-object v5, Ljava/nio/file/StandardCopyOption;->ATOMIC_MOVE Ljava/nio/file/StandardCopyOption;
  0264 aput-object v5, v4, v10
  0268 sget-object v5, Ljava/nio/file/StandardCopyOption;->REPLACE_EXISTING Ljava/nio/file/StandardCopyOption;
  026c const/4 v6, 1
  026e aput-object v5, v4, v6
  0272 invoke-static v0, v3, v4, Ljava/nio/file/Files;->move(Ljava/nio/file/Path; Ljava/nio/file/Path; [Ljava/nio/file/CopyOption;)Ljava/nio/file/Path;
  0278 goto +13h
  027a invoke-virtual v2, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0280 move-result-object v0
  0282 invoke-virtual/range v20, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0288 move-result-object v3
  028a const/4 v4, 1
  028c new-array v4, v4, [Ljava/nio/file/CopyOption;
  0290 sget-object v5, Ljava/nio/file/StandardCopyOption;->REPLACE_EXISTING Ljava/nio/file/StandardCopyOption;
  0294 aput-object v5, v4, v10
  0298 invoke-static v0, v3, v4, Ljava/nio/file/Files;->move(Ljava/nio/file/Path; Ljava/nio/file/Path; [Ljava/nio/file/CopyOption;)Ljava/nio/file/Path;
  029e invoke-virtual/range v19, Ljava/net/HttpURLConnection;->disconnect()V
  02a4 invoke-virtual v2, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  02aa move-result-object v0
  02ac invoke-static v0, Ljava/nio/file/Files;->deleteIfExists(Ljava/nio/file/Path;)Z
  02b2 return-wide v14
  02b4 move-exception v0
  02b6 move-object v11, v8
  02b8 move-object v3, v0
  02ba if-eqz v11, +00bh
  02be invoke-virtual v11, Ljava/io/OutputStream;->close()V
  02c4 goto +6h
  02c6 move-exception v0
  02c8 move-object v4, v0
  02ca invoke-virtual v3, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  02d0 throw v3
  02d2 move-exception v0
  02d4 move-object v3, v0
  02d6 if-eqz v6, +00bh
  02da invoke-virtual v6, Ljava/io/InputStream;->close()V
  02e0 goto +6h
  02e2 move-exception v0
  02e4 move-object v4, v0
  02e6 invoke-virtual v3, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  02ec throw v3
  02ee new-instance v0, Ljava/io/IOException;
  02f2 const-string v3, "Resource download failed."
  02f6 invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02fc throw v0
  02fe move-exception v0
  0300 invoke-virtual/range v19, Ljava/net/HttpURLConnection;->disconnect()V
  0306 invoke-virtual v2, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  030c move-result-object v1
  030e invoke-static v1, Ljava/nio/file/Files;->deleteIfExists(Ljava/nio/file/Path;)Z
  0314 throw v0
  0316 new-instance v0, Ljava/io/IOException;
  031a const-string v1, "Invalid resource size limit."
  031e invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0324 throw v0
.end method