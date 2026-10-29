.class Lcom/personal/aihub/PreviewCache;
.super Ljava/lang/Object;
.field LOCK Ljava/lang/Object;
.field MAX_FILE J
.field MAX_TOTAL J
.field revision J
.field root Ljava/io/File;

.method <clinit>()V
  0000 new-instance v0, Ljava/lang/Object;
  0004 invoke-direct v0, Ljava/lang/Object;-><init>()V
  000a sput-object v0, Lcom/personal/aihub/PreviewCache;->LOCK Ljava/lang/Object;
  000e return-void 
.end method

.method <init>(Ljava/io/File;)V
  0000 invoke-direct v2, Ljava/lang/Object;-><init>()V
  0006 new-instance v0, Ljava/io/File;
  000a const-string v1, "preview-cache"
  000e invoke-direct v0, v3, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0014 iput-object v0, v2, Lcom/personal/aihub/PreviewCache;->root Ljava/io/File;
  0018 invoke-virtual v0, Ljava/io/File;->mkdirs()Z
  001e return-void 
.end method

.method budget(J)Z
  0000 const-wide/32 v0, 536870912
  0006 cmp-long v0, v9, v0
  000a const/4 v1, 1
  000c if-nez v0, +003h
  0010 return v1
  0012 const/4 v0, 6
  0014 new-array v2, v0, [I
  0018 fill-array-data v2, +0000018h
  001e const/4 v3, 0
  0020 move v4, v3
  0022 if-ge v4, v0, +011h
  0026 aget v5, v2, v4
  002a int-to-long v5, v5
  002c const-wide/32 v7, 1073741824
  0032 mul-long/2addr v5, v7
  0034 cmp-long v5, v9, v5
  0038 if-nez v5, +003h
  003c return v1
  003e add-int/lit8 v4, v4, 1
  0042 goto -10h
  0044 return v3
  0046 nop 
  0048 fill-array-data-payload b'\x01\x00\x00\x00\x02\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00\x10\x00\x00\x00 \x00\x00\x00' | \x01\x00\x00\x00\x02\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00\x10\x00\x00\x00\x20\x00\x00\x00
.end method

.method config()Lorg/json/JSONObject;
  0000 new-instance v0, Lorg/json/JSONObject;
  0004 new-instance v1, Ljava/io/File;
  0008 iget-object v2, v4, Lcom/personal/aihub/PreviewCache;->root Ljava/io/File;
  000c const-string v3, "settings.json"
  0010 invoke-direct v1, v2, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0016 invoke-static v1, Lcom/personal/aihub/PreviewCache;->read(Ljava/io/File;)Ljava/lang/String;
  001c move-result-object v1
  001e invoke-direct v0, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0024 return-object v0
  0026 new-instance v0, Lorg/json/JSONObject;
  002a invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  0030 return-object v0
.end method

.method ensure(Ljava/lang/String;)Ljava/io/File;
  0000 const-wide/32 v0, 167772160
  0006 invoke-direct v2, v3, v0, v1, Lcom/personal/aihub/PreviewCache;->ensure(Ljava/lang/String; J)Ljava/io/File;
  000c move-result-object v3
  000e return-object v3
.end method

.method ensure(Ljava/lang/String; J)Ljava/io/File;
  0000 move-object/from16 v1, v18
  0004 const-string v0, "Eclipse returned HTTP "
  0008 invoke-static Ljava/lang/Thread;->currentThread()Ljava/lang/Thread;
  000e move-result-object v2
  0010 invoke-virtual v2, Ljava/lang/Thread;->isInterrupted()Z
  0016 move-result v2
  0018 if-nez v2, +1dbh
  001c invoke-static/range v19, Lcom/personal/aihub/PreviewCache;->normalized(Ljava/lang/String;)Ljava/lang/String;
  0022 move-result-object v2
  0024 invoke-direct v1, v2, Lcom/personal/aihub/PreviewCache;->file(Ljava/lang/String;)Ljava/io/File;
  002a move-result-object v3
  002c new-instance v4, Ljava/io/File;
  0030 new-instance v5, Ljava/lang/StringBuilder;
  0034 invoke-direct v5, Ljava/lang/StringBuilder;-><init>()V
  003a invoke-virtual v5, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0040 const-string v6, ".body"
  0044 invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  004a invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0050 move-result-object v5
  0052 invoke-direct v4, v5, Ljava/io/File;-><init>(Ljava/lang/String;)V
  0058 new-instance v5, Ljava/io/File;
  005c new-instance v6, Ljava/lang/StringBuilder;
  0060 invoke-direct v6, Ljava/lang/StringBuilder;-><init>()V
  0066 invoke-virtual v6, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  006c const-string v7, ".json"
  0070 invoke-virtual v6, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0076 invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  007c move-result-object v6
  007e invoke-direct v5, v6, Ljava/io/File;-><init>(Ljava/lang/String;)V
  0084 invoke-virtual v4, Ljava/io/File;->isFile()Z
  008a move-result v6
  008c if-eqz v6, +009h
  0090 invoke-virtual v5, Ljava/io/File;->isFile()Z
  0096 move-result v6
  0098 if-eqz v6, +003h
  009c return-object v3
  009e invoke-virtual/range v18, Lcom/personal/aihub/PreviewCache;->offline()Z
  00a4 move-result v6
  00a6 if-nez v6, +18ch
  00aa sget-object v6, Lcom/personal/aihub/PreviewCache;->LOCK Ljava/lang/Object;
  00ae monitor-enter v6
  00b0 invoke-static Ljava/lang/Thread;->currentThread()Ljava/lang/Thread;
  00b6 move-result-object v7
  00b8 invoke-virtual v7, Ljava/lang/Thread;->isInterrupted()Z
  00be move-result v7
  00c0 if-nez v7, +174h
  00c4 invoke-virtual v4, Ljava/io/File;->isFile()Z
  00ca move-result v7
  00cc if-eqz v7, +00ah
  00d0 invoke-virtual v5, Ljava/io/File;->isFile()Z
  00d6 move-result v7
  00d8 if-eqz v7, +004h
  00dc monitor-exit v6
  00de return-object v3
  00e0 new-instance v7, Ljava/net/URL;
  00e4 invoke-direct v7, v2, Ljava/net/URL;-><init>(Ljava/lang/String;)V
  00ea invoke-virtual v7, Ljava/net/URL;->openConnection()Ljava/net/URLConnection;
  00f0 move-result-object v7
  00f2 check-cast v7, Ljava/net/HttpURLConnection;
  00f6 const/16 v8, 20000
  00fa invoke-virtual v7, v8, Ljava/net/HttpURLConnection;->setConnectTimeout(I)V
  0100 const v8, 60000
  0106 invoke-virtual v7, v8, Ljava/net/HttpURLConnection;->setReadTimeout(I)V
  010c const/4 v8, 0
  010e invoke-virtual v7, v8, Ljava/net/HttpURLConnection;->setInstanceFollowRedirects(Z)V
  0114 const-string v9, "User-Agent"
  0118 const-string v10, "DokkanUnitCreator/2.5"
  011c invoke-virtual v7, v9, v10, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String; Ljava/lang/String;)V
  0122 new-instance v9, Ljava/io/File;
  0126 new-instance v10, Ljava/lang/StringBuilder;
  012a invoke-direct v10, Ljava/lang/StringBuilder;-><init>()V
  0130 invoke-virtual v10, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0136 const-string v11, ".tmp"
  013a invoke-virtual v10, v11, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0140 invoke-virtual v10, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0146 move-result-object v10
  0148 invoke-direct v9, v10, Ljava/io/File;-><init>(Ljava/lang/String;)V
  014e invoke-virtual v7, Ljava/net/HttpURLConnection;->getResponseCode()I
  0154 move-result v10
  0156 const/16 v11, 200
  015a if-ne v10, v11, +105h
  015e invoke-virtual v7, Ljava/net/HttpURLConnection;->getContentLengthLong()J
  0164 move-result-wide v10
  0166 cmp-long v0, v10, v20
  016a if-gtz v0, +0f4h
  016e invoke-virtual v7, Ljava/net/HttpURLConnection;->getInputStream()Ljava/io/InputStream;
  0174 move-result-object v12
  0176 new-instance v13, Ljava/io/FileOutputStream;
  017a invoke-direct v13, v9, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0180 const/high16 v0, 65536
  0184 new-array v0, v0, [B
  0188 const-wide/16 v16, 0
  018c invoke-virtual v12, v0, Ljava/io/InputStream;->read([B)I
  0192 move-result v14
  0194 const/4 v15, -1
  0196 if-eq v14, v15, +033h
  019a invoke-static Ljava/lang/Thread;->currentThread()Ljava/lang/Thread;
  01a0 move-result-object v15
  01a2 invoke-virtual v15, Ljava/lang/Thread;->isInterrupted()Z
  01a8 move-result v15
  01aa if-nez v15, +018h
  01ae move-object v15, v9
  01b0 int-to-long v8, v14
  01b2 add-long v16, v16, v8
  01b6 cmp-long v8, v16, v20
  01ba if-gtz v8, +008h
  01be const/4 v8, 0
  01c0 invoke-virtual v13, v0, v8, v14, Ljava/io/FileOutputStream;->write([B I I)V
  01c6 move-object v9, v15
  01c8 goto -1eh
  01ca new-instance v0, Ljava/io/IOException;
  01ce const-string v2, "Preview resource exceeds 160 MB"
  01d2 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01d8 throw v0
  01da move-object v15, v9
  01dc new-instance v0, Ljava/io/InterruptedIOException;
  01e0 const-string v2, "Preview closed"
  01e4 invoke-direct v0, v2, Ljava/io/InterruptedIOException;-><init>(Ljava/lang/String;)V
  01ea throw v0
  01ec move-exception v0
  01ee goto +3h
  01f0 move-exception v0
  01f2 move-object v15, v9
  01f4 move-object v3, v0
  01f6 move-object v2, v15
  01f8 goto/16 +092h
  01fc move-object v15, v9
  01fe invoke-virtual v13, Ljava/io/FileOutputStream;->close()V
  0204 if-eqz v12, +005h
  0208 invoke-virtual v12, Ljava/io/InputStream;->close()V
  020e invoke-virtual v7, Ljava/net/HttpURLConnection;->getContentEncoding()Ljava/lang/String;
  0214 move-result-object v0
  0216 if-eqz v0, +00eh
  021a invoke-virtual v7, Ljava/net/HttpURLConnection;->getContentEncoding()Ljava/lang/String;
  0220 move-result-object v0
  0222 const-string v8, "identity"
  0226 invoke-virtual v0, v8, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z
  022c move-result v0
  022e if-eqz v0, +015h
  0232 const-wide/16 v8, 0
  0236 cmp-long v0, v10, v8
  023a if-lez v0, +00fh
  023e cmp-long v0, v10, v16
  0242 if-nez v0, +003h
  0246 goto +9h
  0248 new-instance v0, Ljava/io/IOException;
  024c const-string v2, "Incomplete preview download"
  0250 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0256 throw v0
  0258 new-instance v0, Lorg/json/JSONObject;
  025c invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  0262 invoke-virtual v1, v0, Lcom/personal/aihub/PreviewCache;->settings(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0268 move-result-object v0
  026a const-string v8, "bytes"
  026e invoke-virtual v0, v8, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0274 move-result-wide v8
  0276 add-long v8, v8, v16
  027a invoke-direct/range v18, Lcom/personal/aihub/PreviewCache;->storageLimit()J
  0280 move-result-wide v10
  0282 cmp-long v0, v8, v10
  0286 if-gtz v0, +039h
  028a invoke-virtual v7, Ljava/net/HttpURLConnection;->getContentType()Ljava/lang/String;
  0290 move-result-object v0
  0292 new-instance v8, Lorg/json/JSONObject;
  0296 invoke-direct v8, Lorg/json/JSONObject;-><init>()V
  029c const-string v9, "url"
  02a0 invoke-virtual v8, v9, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02a6 move-result-object v2
  02a8 const-string v8, "type"
  02ac if-nez v0, +004h
  02b0 const-string v0, "application/octet-stream"
  02b4 invoke-virtual v2, v8, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02ba move-result-object v0
  02bc move-object v2, v15
  02be invoke-virtual v2, v4, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  02c4 move-result v4
  02c6 if-eqz v4, +011h
  02ca invoke-virtual v0, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  02d0 move-result-object v0
  02d2 invoke-static v5, v0, Lcom/personal/aihub/PreviewCache;->write(Ljava/io/File; Ljava/lang/String;)V
  02d8 invoke-virtual v7, Ljava/net/HttpURLConnection;->disconnect()V
  02de invoke-virtual v2, Ljava/io/File;->delete()Z
  02e4 monitor-exit v6
  02e6 return-object v3
  02e8 new-instance v0, Ljava/io/IOException;
  02ec const-string v3, "Could not save preview"
  02f0 invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02f6 throw v0
  02f8 move-object v2, v15
  02fa new-instance v0, Ljava/io/IOException;
  02fe const-string v3, "Saved preview storage is full. Increase its size or clear downloaded previews in Animation Studio."
  0302 invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0308 throw v0
  030a move-exception v0
  030c move-object v2, v15
  030e goto +46h
  0310 move-exception v0
  0312 move-object v2, v15
  0314 goto +12h
  0316 move-exception v0
  0318 move-object v2, v9
  031a move-object v3, v0
  031c invoke-virtual v13, Ljava/io/FileOutputStream;->close()V
  0322 goto +6h
  0324 move-exception v0
  0326 move-object v4, v0
  0328 invoke-virtual v3, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  032e throw v3
  0330 move-exception v0
  0332 goto +3h
  0334 move-exception v0
  0336 move-object v2, v9
  0338 move-object v3, v0
  033a if-eqz v12, +00bh
  033e invoke-virtual v12, Ljava/io/InputStream;->close()V
  0344 goto +6h
  0346 move-exception v0
  0348 move-object v4, v0
  034a invoke-virtual v3, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0350 throw v3
  0352 move-object v2, v9
  0354 new-instance v0, Ljava/io/IOException;
  0358 const-string v3, "Preview resource exceeds 160 MB"
  035c invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0362 throw v0
  0364 move-object v2, v9
  0366 new-instance v3, Ljava/io/IOException;
  036a new-instance v4, Ljava/lang/StringBuilder;
  036e invoke-direct v4, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0374 invoke-virtual v7, Ljava/net/HttpURLConnection;->getResponseCode()I
  037a move-result v0
  037c invoke-virtual v4, v0, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  0382 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0388 move-result-object v0
  038a invoke-direct v3, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0390 throw v3
  0392 move-exception v0
  0394 goto +3h
  0396 move-exception v0
  0398 move-object v2, v9
  039a invoke-virtual v7, Ljava/net/HttpURLConnection;->disconnect()V
  03a0 invoke-virtual v2, Ljava/io/File;->delete()Z
  03a6 throw v0
  03a8 new-instance v0, Ljava/io/InterruptedIOException;
  03ac const-string v2, "Preview closed"
  03b0 invoke-direct v0, v2, Ljava/io/InterruptedIOException;-><init>(Ljava/lang/String;)V
  03b6 throw v0
  03b8 move-exception v0
  03ba monitor-exit v6
  03bc throw v0
  03be new-instance v0, Ljava/io/IOException;
  03c2 const-string v2, "This resource has not been saved for offline preview"
  03c6 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03cc throw v0
  03ce new-instance v0, Ljava/io/InterruptedIOException;
  03d2 const-string v2, "Preview closed"
  03d6 invoke-direct v0, v2, Ljava/io/InterruptedIOException;-><init>(Ljava/lang/String;)V
  03dc throw v0
.end method

.method file(Ljava/lang/String;)Ljava/io/File;
  0000 const-string v0, "SHA-256"
  0004 invoke-static v0, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;
  000a move-result-object v0
  000c sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0010 invoke-virtual v7, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0016 move-result-object v7
  0018 invoke-virtual v0, v7, Ljava/security/MessageDigest;->digest([B)[B
  001e move-result-object v7
  0020 new-instance v0, Ljava/lang/StringBuilder;
  0024 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  002a array-length v1, v7
  002c const/4 v2, 0
  002e if-ge v2, v1, +01ch
  0032 aget-byte v3, v7, v2
  0036 sget-object v4, Ljava/util/Locale;->US Ljava/util/Locale;
  003a and-int/lit16 v3, v3, 255
  003e invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0044 move-result-object v3
  0046 filled-new-array v3, [Ljava/lang/Object;
  004c move-result-object v3
  004e const-string v5, "%02x"
  0052 invoke-static v4, v5, v3, Ljava/lang/String;->format(Ljava/util/Locale; Ljava/lang/String; [Ljava/lang/Object;)Ljava/lang/String;
  0058 move-result-object v3
  005a invoke-virtual v0, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0060 add-int/lit8 v2, v2, 1
  0064 goto -1bh
  0066 new-instance v7, Ljava/io/File;
  006a iget-object v1, v6, Lcom/personal/aihub/PreviewCache;->root Ljava/io/File;
  006e invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0074 move-result-object v0
  0076 invoke-direct v7, v1, v0, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  007c return-object v7
.end method

.method normalized(Ljava/lang/String;)Ljava/lang/String;
  0000 new-instance v0, Ljava/net/URI;
  0004 invoke-direct v0, v11, Ljava/net/URI;-><init>(Ljava/lang/String;)V
  000a const-string v11, "https"
  000e invoke-virtual v0, Ljava/net/URI;->getScheme()Ljava/lang/String;
  0014 move-result-object v1
  0016 invoke-virtual v11, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  001c move-result v11
  001e if-eqz v11, +0f4h
  0022 const-string v11, "dokkan-eclipse.com"
  0026 invoke-virtual v0, Ljava/net/URI;->getHost()Ljava/lang/String;
  002c move-result-object v1
  002e invoke-virtual v11, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0034 move-result v11
  0036 if-eqz v11, +0e8h
  003a invoke-virtual v0, Ljava/net/URI;->getPort()I
  0040 move-result v11
  0042 const/4 v1, -1
  0044 if-ne v11, v1, +0e1h
  0048 invoke-virtual v0, Ljava/net/URI;->getUserInfo()Ljava/lang/String;
  004e move-result-object v11
  0050 if-nez v11, +0dbh
  0054 invoke-virtual v0, Ljava/net/URI;->getPath()Ljava/lang/String;
  005a move-result-object v11
  005c const-string v1, "/(tools/.*|assets/.*|static/.*|css/.*|cdn/uncompressed/.*|api/.*)"
  0060 invoke-virtual v11, v1, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0066 move-result v11
  0068 if-eqz v11, +0cfh
  006c new-instance v11, Ljava/util/TreeMap;
  0070 invoke-direct v11, Ljava/util/TreeMap;-><init>()V
  0076 invoke-virtual v0, Ljava/net/URI;->getRawQuery()Ljava/lang/String;
  007c move-result-object v1
  007e const-string v2, ""
  0082 const-string v3, "UTF-8"
  0086 if-eqz v1, +052h
  008a invoke-virtual v0, Ljava/net/URI;->getRawQuery()Ljava/lang/String;
  0090 move-result-object v1
  0092 const-string v4, "&"
  0096 invoke-virtual v1, v4, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  009c move-result-object v1
  009e array-length v4, v1
  00a0 const/4 v5, 0
  00a2 move v6, v5
  00a4 if-ge v6, v4, +043h
  00a8 aget-object v7, v1, v6
  00ac const-string v8, "="
  00b0 const/4 v9, 2
  00b2 invoke-virtual v7, v8, v9, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  00b8 move-result-object v7
  00ba aget-object v8, v7, v5
  00be invoke-static v8, v3, Ljava/net/URLDecoder;->decode(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  00c4 move-result-object v8
  00c6 array-length v9, v7
  00c8 const/4 v10, 1
  00ca if-le v9, v10, +009h
  00ce aget-object v7, v7, v10
  00d2 invoke-static v7, v3, Ljava/net/URLDecoder;->decode(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  00d8 move-result-object v7
  00da goto +2h
  00dc move-object v7, v2
  00de const-string v9, "patch"
  00e2 invoke-virtual v8, v9, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00e8 move-result v9
  00ea if-nez v9, +018h
  00ee const-string v9, "_|_t|t|ts|timestamp|cacheBust|nocache"
  00f2 invoke-virtual v8, v9, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  00f8 move-result v9
  00fa if-eqz v9, +00ah
  00fe const-string v9, "[0-9]+"
  0102 invoke-virtual v7, v9, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0108 move-result v9
  010a if-nez v9, +005h
  010e invoke-virtual v11, v8, v7, Ljava/util/TreeMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0114 add-int/lit8 v6, v6, 1
  0118 goto -3ah
  011a new-instance v11, Ljava/io/IOException;
  011e const-string v0, "Private patch previews are not cached"
  0122 invoke-direct v11, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0128 throw v11
  012a new-instance v1, Ljava/lang/StringBuilder;
  012e invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  0134 invoke-virtual v11, Ljava/util/TreeMap;->entrySet()Ljava/util/Set;
  013a move-result-object v11
  013c invoke-interface v11, Ljava/util/Set;->iterator()Ljava/util/Iterator;
  0142 move-result-object v11
  0144 invoke-interface v11, Ljava/util/Iterator;->hasNext()Z
  014a move-result v4
  014c if-eqz v4, +033h
  0150 invoke-interface v11, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0156 move-result-object v4
  0158 check-cast v4, Ljava/util/Map$Entry;
  015c invoke-virtual v1, Ljava/lang/StringBuilder;->length()I
  0162 move-result v5
  0164 if-lez v5, +007h
  0168 const/16 v5, 38
  016c invoke-virtual v1, v5, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;
  0172 invoke-interface v4, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;
  0178 move-result-object v5
  017a check-cast v5, Ljava/lang/String;
  017e invoke-static v5, v3, Ljava/net/URLEncoder;->encode(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0184 move-result-object v5
  0186 invoke-virtual v1, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  018c const/16 v5, 61
  0190 invoke-virtual v1, v5, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;
  0196 invoke-interface v4, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;
  019c move-result-object v4
  019e check-cast v4, Ljava/lang/String;
  01a2 invoke-static v4, v3, Ljava/net/URLEncoder;->encode(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  01a8 move-result-object v4
  01aa invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01b0 goto -36h
  01b2 new-instance v11, Ljava/lang/StringBuilder;
  01b6 const-string v3, "https://dokkan-eclipse.com"
  01ba invoke-direct v11, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  01c0 invoke-virtual v0, Ljava/net/URI;->getRawPath()Ljava/lang/String;
  01c6 move-result-object v0
  01c8 invoke-virtual v11, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01ce invoke-virtual v1, Ljava/lang/StringBuilder;->length()I
  01d4 move-result v0
  01d6 if-lez v0, +010h
  01da new-instance v0, Ljava/lang/StringBuilder;
  01de const-string v2, "?"
  01e2 invoke-direct v0, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  01e8 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  01ee invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01f4 move-result-object v2
  01f6 invoke-virtual v11, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01fc invoke-virtual v11, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0202 move-result-object v11
  0204 return-object v11
  0206 new-instance v11, Ljava/io/IOException;
  020a const-string v0, "Unsupported public preview resource"
  020e invoke-direct v11, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0214 throw v11
.end method

.method read(Ljava/io/File;)Ljava/lang/String;
  0000 new-instance v0, Ljava/io/FileInputStream;
  0004 invoke-direct v0, v4, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  000a new-instance v4, Ljava/io/ByteArrayOutputStream;
  000e invoke-direct v4, Ljava/io/ByteArrayOutputStream;-><init>()V
  0014 const/16 v1, 8192
  0018 new-array v1, v1, [B
  001c invoke-virtual v0, v1, Ljava/io/FileInputStream;->read([B)I
  0022 move-result v2
  0024 const/4 v3, -1
  0026 if-eq v2, v3, +007h
  002a const/4 v3, 0
  002c invoke-virtual v4, v1, v3, v2, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  0032 goto -bh
  0034 const-string v1, "UTF-8"
  0038 invoke-virtual v4, v1, Ljava/io/ByteArrayOutputStream;->toString(Ljava/lang/String;)Ljava/lang/String;
  003e move-result-object v1
  0040 invoke-virtual v4, Ljava/io/ByteArrayOutputStream;->close()V
  0046 invoke-virtual v0, Ljava/io/FileInputStream;->close()V
  004c return-object v1
  004e move-exception v1
  0050 invoke-virtual v4, Ljava/io/ByteArrayOutputStream;->close()V
  0056 goto +5h
  0058 move-exception v4
  005a invoke-virtual v1, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0060 throw v1
  0062 move-exception v4
  0064 invoke-virtual v0, Ljava/io/FileInputStream;->close()V
  006a goto +5h
  006c move-exception v0
  006e invoke-virtual v4, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0074 throw v4
.end method

.method result(I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)Landroid/webkit/WebResourceResponse;
  0000 new-instance v10, Landroid/webkit/WebResourceResponse;
  0004 new-instance v6, Ljava/io/ByteArrayInputStream;
  0008 sget-object v0, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  000c invoke-virtual v8, v0, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0012 move-result-object v8
  0014 invoke-direct v6, v8, Ljava/io/ByteArrayInputStream;-><init>([B)V
  001a const-string v1, "text/plain"
  001e const-string v2, "UTF-8"
  0022 const-string v4, "Unavailable"
  0026 move-object v0, v10
  0028 move v3, v7
  002a move-object v5, v9
  002c invoke-direct/range v0 ... v6, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String; Ljava/lang/String; I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)V
  0032 return-object v10
.end method

.method storageLimit()J
  0000 invoke-direct v5, Lcom/personal/aihub/PreviewCache;->config()Lorg/json/JSONObject;
  0006 move-result-object v0
  0008 const-string v1, "maxBytes"
  000c const-wide v2, 2147483648
  0016 invoke-virtual v0, v1, v2, v3, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  001c move-result-wide v0
  001e invoke-static v0, v1, Lcom/personal/aihub/PreviewCache;->budget(J)Z
  0024 move-result v4
  0026 if-eqz v4, +003h
  002a return-wide v0
  002c return-wide v2
.end method

.method write(Ljava/io/File; Ljava/lang/String;)V
  0000 new-instance v0, Ljava/io/File;
  0004 new-instance v1, Ljava/lang/StringBuilder;
  0008 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  000e invoke-virtual v1, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0014 const-string v2, ".tmp"
  0018 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  001e invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0024 move-result-object v1
  0026 invoke-direct v0, v1, Ljava/io/File;-><init>(Ljava/lang/String;)V
  002c new-instance v1, Ljava/io/FileOutputStream;
  0030 invoke-direct v1, v0, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0036 sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  003a invoke-virtual v4, v2, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0040 move-result-object v4
  0042 invoke-virtual v1, v4, Ljava/io/FileOutputStream;->write([B)V
  0048 invoke-virtual v1, Ljava/io/FileOutputStream;->close()V
  004e invoke-virtual v0, v3, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  0054 move-result v3
  0056 if-eqz v3, +003h
  005a return-void 
  005c new-instance v3, Ljava/io/IOException;
  0060 const-string v4, "Could not save preview settings"
  0064 invoke-direct v3, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  006a throw v3
  006c move-exception v3
  006e invoke-virtual v1, Ljava/io/FileOutputStream;->close()V
  0074 goto +5h
  0076 move-exception v4
  0078 invoke-virtual v3, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  007e throw v3
.end method

.method cachedBody(Ljava/lang/String;)Ljava/io/File;
  0000 invoke-static v4, Lcom/personal/aihub/PreviewCache;->normalized(Ljava/lang/String;)Ljava/lang/String;
  0006 move-result-object v4
  0008 invoke-direct v3, v4, Lcom/personal/aihub/PreviewCache;->file(Ljava/lang/String;)Ljava/io/File;
  000e move-result-object v4
  0010 new-instance v0, Ljava/io/File;
  0014 new-instance v1, Ljava/lang/StringBuilder;
  0018 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  001e invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0024 const-string v2, ".body"
  0028 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  002e invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0034 move-result-object v1
  0036 invoke-direct v0, v1, Ljava/io/File;-><init>(Ljava/lang/String;)V
  003c new-instance v1, Ljava/io/File;
  0040 new-instance v2, Ljava/lang/StringBuilder;
  0044 invoke-direct v2, Ljava/lang/StringBuilder;-><init>()V
  004a invoke-virtual v2, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0050 const-string v4, ".json"
  0054 invoke-virtual v2, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  005a invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0060 move-result-object v4
  0062 invoke-direct v1, v4, Ljava/io/File;-><init>(Ljava/lang/String;)V
  0068 invoke-virtual v0, Ljava/io/File;->isFile()Z
  006e move-result v4
  0070 if-eqz v4, +009h
  0074 invoke-virtual v1, Ljava/io/File;->isFile()Z
  007a move-result v4
  007c if-eqz v4, +003h
  0080 return-object v0
  0082 const/4 v4, 0
  0084 return-object v4
.end method

.method discard(Ljava/lang/String;)V
  0000 sget-object v0, Lcom/personal/aihub/PreviewCache;->LOCK Ljava/lang/Object;
  0004 monitor-enter v0
  0006 invoke-static v7, Lcom/personal/aihub/PreviewCache;->normalized(Ljava/lang/String;)Ljava/lang/String;
  000c move-result-object v7
  000e invoke-direct v6, v7, Lcom/personal/aihub/PreviewCache;->file(Ljava/lang/String;)Ljava/io/File;
  0014 move-result-object v7
  0016 const-string v1, ".body"
  001a const-string v2, ".json"
  001e const-string v3, ".tmp"
  0022 const-string v4, ".json.tmp"
  0026 filled-new-array v1, v2, v3, v4, [Ljava/lang/String;
  002c move-result-object v1
  002e const/4 v2, 0
  0030 const/4 v3, 4
  0032 if-ge v2, v3, +030h
  0036 new-instance v3, Ljava/io/File;
  003a new-instance v4, Ljava/lang/StringBuilder;
  003e invoke-direct v4, Ljava/lang/StringBuilder;-><init>()V
  0044 invoke-virtual v4, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  004a aget-object v5, v1, v2
  004e invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0054 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  005a move-result-object v4
  005c invoke-direct v3, v4, Ljava/io/File;-><init>(Ljava/lang/String;)V
  0062 invoke-virtual v3, Ljava/io/File;->exists()Z
  0068 move-result v4
  006a if-eqz v4, +011h
  006e invoke-virtual v3, Ljava/io/File;->delete()Z
  0074 move-result v3
  0076 if-eqz v3, +003h
  007a goto +9h
  007c new-instance v7, Ljava/io/IOException;
  0080 const-string v1, "Could not repair a saved preview tool"
  0084 invoke-direct v7, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  008a throw v7
  008c add-int/lit8 v2, v2, 1
  0090 goto -30h
  0092 monitor-exit v0
  0094 return-void 
  0096 move-exception v7
  0098 monitor-exit v0
  009a throw v7
.end method

.method offline()Z
  0000 new-instance v0, Lorg/json/JSONObject;
  0004 new-instance v1, Ljava/io/File;
  0008 iget-object v2, v4, Lcom/personal/aihub/PreviewCache;->root Ljava/io/File;
  000c const-string v3, "settings.json"
  0010 invoke-direct v1, v2, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0016 invoke-static v1, Lcom/personal/aihub/PreviewCache;->read(Ljava/io/File;)Ljava/lang/String;
  001c move-result-object v1
  001e invoke-direct v0, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0024 const-string v1, "offline"
  0028 invoke-virtual v0, v1, Lorg/json/JSONObject;->optBoolean(Ljava/lang/String;)Z
  002e move-result v0
  0030 return v0
  0032 const/4 v0, 0
  0034 return v0
.end method

.method prepareBody(Ljava/lang/String; I J)Ljava/io/File;
  0000 sget-object v0, Lcom/personal/aihub/PreviewCache;->LOCK Ljava/lang/Object;
  0004 monitor-enter v0
  0006 sget-wide v1, Lcom/personal/aihub/PreviewCache;->revision J
  000a cmp-long v6, v1, v6
  000e if-nez v6, +034h
  0012 invoke-virtual v3, Lcom/personal/aihub/PreviewCache;->offline()Z
  0018 move-result v6
  001a if-nez v6, +02eh
  001e const/4 v6, 1
  0020 if-lt v5, v6, +023h
  0024 const/high16 v6, 16777216
  0028 if-gt v5, v6, +01fh
  002c new-instance v6, Ljava/io/File;
  0030 new-instance v7, Ljava/lang/StringBuilder;
  0034 invoke-direct v7, Ljava/lang/StringBuilder;-><init>()V
  003a int-to-long v1, v5
  003c invoke-direct v3, v4, v1, v2, Lcom/personal/aihub/PreviewCache;->ensure(Ljava/lang/String; J)Ljava/io/File;
  0042 move-result-object v4
  0044 invoke-virtual v7, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  004a const-string v4, ".body"
  004e invoke-virtual v7, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0054 invoke-virtual v7, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  005a move-result-object v4
  005c invoke-direct v6, v4, Ljava/io/File;-><init>(Ljava/lang/String;)V
  0062 monitor-exit v0
  0064 return-object v6
  0066 new-instance v4, Ljava/io/IOException;
  006a const-string v5, "Invalid preview tool size"
  006e invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0074 throw v4
  0076 new-instance v4, Ljava/io/IOException;
  007a const-string v5, "Preview preparation stopped because storage or offline settings changed."
  007e invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0084 throw v4
  0086 move-exception v4
  0088 monitor-exit v0
  008a throw v4
.end method

.method resourceBody(Ljava/lang/String; J)Ljava/io/File;
  0000 const-wide/16 v0, 1
  0004 cmp-long v0, v5, v0
  0008 if-ltz v0, +034h
  000c const-wide/32 v0, 167772160
  0012 cmp-long v0, v5, v0
  0016 if-gtz v0, +02dh
  001a new-instance v0, Ljava/io/File;
  001e new-instance v1, Ljava/lang/StringBuilder;
  0022 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  0028 invoke-direct v3, v4, v5, v6, Lcom/personal/aihub/PreviewCache;->ensure(Ljava/lang/String; J)Ljava/io/File;
  002e move-result-object v4
  0030 invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0036 const-string v4, ".body"
  003a invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0040 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0046 move-result-object v4
  0048 invoke-direct v0, v4, Ljava/io/File;-><init>(Ljava/lang/String;)V
  004e invoke-virtual v0, Ljava/io/File;->length()J
  0054 move-result-wide v1
  0056 cmp-long v4, v1, v5
  005a if-gtz v4, +003h
  005e return-object v0
  0060 new-instance v4, Ljava/io/IOException;
  0064 const-string v5, "This music resource exceeds its preview size limit"
  0068 invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  006e throw v4
  0070 new-instance v4, Ljava/io/IOException;
  0074 const-string v5, "Invalid preview resource limit"
  0078 invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  007e throw v4
.end method

.method response(Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;
  0000 move-object/from16 v1, v22
  0004 const-string v0, "-"
  0008 const-string v2, "Content-Range"
  000c const-string v3, "bytes "
  0010 const-string v4, "bytes */"
  0014 new-instance v12, Ljava/util/HashMap;
  0018 invoke-direct v12, Ljava/util/HashMap;-><init>()V
  001e const-string v5, "Access-Control-Allow-Origin"
  0022 const-string v6, "*"
  0026 invoke-interface v12, v5, v6, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  002c const-string v5, "Accept-Ranges"
  0030 const-string v6, "bytes"
  0034 invoke-interface v12, v5, v6, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  003a const-string v5, "Cache-Control"
  003e const-string v6, "no-store"
  0042 invoke-interface v12, v5, v6, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0048 const/4 v13, 0
  004a invoke-interface/range v23, Landroid/webkit/WebResourceRequest;->getMethod()Ljava/lang/String;
  0050 move-result-object v5
  0052 const-string v6, "GET"
  0056 invoke-virtual v5, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  005c move-result v5
  005e const-string v6, "HEAD"
  0062 if-nez v5, +015h
  0066 invoke-interface/range v23, Landroid/webkit/WebResourceRequest;->getMethod()Ljava/lang/String;
  006c move-result-object v5
  006e invoke-virtual v5, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0074 move-result v5
  0076 if-nez v5, +00bh
  007a const-string v0, "Method not allowed"
  007e const/16 v2, 405
  0082 invoke-static v2, v0, v12, v13, Lcom/personal/aihub/PreviewCache;->result(I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)Landroid/webkit/WebResourceResponse;
  0088 move-result-object v0
  008a return-object v0
  008c invoke-interface/range v23, Landroid/webkit/WebResourceRequest;->getUrl()Landroid/net/Uri;
  0092 move-result-object v5
  0094 invoke-virtual v5, Landroid/net/Uri;->toString()Ljava/lang/String;
  009a move-result-object v5
  009c invoke-direct v1, v5, Lcom/personal/aihub/PreviewCache;->ensure(Ljava/lang/String;)Ljava/io/File;
  00a2 move-result-object v5
  00a4 new-instance v7, Ljava/io/File;
  00a8 new-instance v8, Ljava/lang/StringBuilder;
  00ac invoke-direct v8, Ljava/lang/StringBuilder;-><init>()V
  00b2 invoke-virtual v8, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  00b8 const-string v9, ".body"
  00bc invoke-virtual v8, v9, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00c2 invoke-virtual v8, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00c8 move-result-object v8
  00ca invoke-direct v7, v8, Ljava/io/File;-><init>(Ljava/lang/String;)V
  00d0 new-instance v8, Lorg/json/JSONObject;
  00d4 new-instance v9, Ljava/io/File;
  00d8 new-instance v10, Ljava/lang/StringBuilder;
  00dc invoke-direct v10, Ljava/lang/StringBuilder;-><init>()V
  00e2 invoke-virtual v10, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  00e8 const-string v5, ".json"
  00ec invoke-virtual v10, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00f2 invoke-virtual v10, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00f8 move-result-object v5
  00fa invoke-direct v9, v5, Ljava/io/File;-><init>(Ljava/lang/String;)V
  0100 invoke-static v9, Lcom/personal/aihub/PreviewCache;->read(Ljava/io/File;)Ljava/lang/String;
  0106 move-result-object v5
  0108 invoke-direct v8, v5, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  010e const-string v5, "type"
  0112 invoke-virtual v8, v5, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0118 move-result-object v5
  011a const-string v8, ";"
  011e invoke-virtual v5, v8, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  0124 move-result-object v5
  0126 const/4 v8, 0
  0128 aget-object v9, v5, v8
  012c invoke-virtual v7, Ljava/io/File;->length()J
  0132 move-result-wide v10
  0134 const-wide/16 v14, 1
  0138 move-object/from16 v16, v9
  013c sub-long v8, v10, v14
  0140 invoke-interface/range v23, Landroid/webkit/WebResourceRequest;->getRequestHeaders()Ljava/util/Map;
  0146 move-result-object v5
  0148 const-string v14, "Range"
  014c invoke-interface v5, v14, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0152 move-result-object v5
  0154 check-cast v5, Ljava/lang/String;
  0158 if-nez v5, +00eh
  015c invoke-interface/range v23, Landroid/webkit/WebResourceRequest;->getRequestHeaders()Ljava/util/Map;
  0162 move-result-object v5
  0164 const-string v14, "range"
  0168 invoke-interface v5, v14, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  016e move-result-object v5
  0170 check-cast v5, Ljava/lang/String;
  0174 const-wide/16 v14, 0
  0178 if-eqz v5, +0a6h
  017c const-string v13, "bytes=([0-9]+-[0-9]*|-[0-9]+)"
  0180 invoke-virtual v5, v13, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0186 move-result v13
  0188 if-eqz v13, +07fh
  018c cmp-long v13, v10, v14
  0190 if-eqz v13, +07bh
  0194 const/4 v13, 6
  0196 invoke-virtual v5, v13, Ljava/lang/String;->substring(I)Ljava/lang/String;
  019c move-result-object v5
  019e const/4 v13, -1
  01a0 invoke-virtual v5, v0, v13, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  01a6 move-result-object v13
  01a8 const/4 v5, 0
  01aa aget-object v17, v13, v5
  01ae invoke-virtual/range v17, Ljava/lang/String;->isEmpty()Z
  01b4 move-result v17
  01b6 const/16 v19, 1
  01ba if-eqz v17, +01bh
  01be aget-object v13, v13, v19
  01c2 invoke-static v13, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  01c8 move-result-wide v19
  01ca cmp-long v13, v19, v14
  01ce if-lez v13, +00bh
  01d2 move-object/from16 v17, v6
  01d6 sub-long v5, v10, v19
  01da invoke-static v14, v15, v5, v6, Ljava/lang/Math;->max(J J)J
  01e0 move-result-wide v5
  01e2 goto +24h
  01e4 new-instance v0, Ljava/io/IOException;
  01e8 invoke-direct v0, Ljava/io/IOException;-><init>()V
  01ee throw v0
  01f0 move-object/from16 v17, v6
  01f4 const/4 v5, 0
  01f6 aget-object v6, v13, v5
  01fa invoke-static v6, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  0200 move-result-wide v20
  0202 aget-object v6, v13, v19
  0206 invoke-virtual v6, Ljava/lang/String;->isEmpty()Z
  020c move-result v6
  020e if-nez v6, +00ch
  0212 aget-object v6, v13, v19
  0216 invoke-static v6, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  021c move-result-wide v5
  021e invoke-static v8, v9, v5, v6, Ljava/lang/Math;->min(J J)J
  0224 move-result-wide v8
  0226 move-wide/from16 v5, v20
  022a cmp-long v19, v5, v10
  022e if-gez v19, +026h
  0232 cmp-long v19, v8, v5
  0236 if-ltz v19, +022h
  023a new-instance v13, Ljava/lang/StringBuilder;
  023e invoke-direct v13, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0244 invoke-virtual v13, v5, v6, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  024a invoke-virtual v13, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0250 invoke-virtual v13, v8, v9, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0256 const-string v0, "/"
  025a invoke-virtual v13, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0260 invoke-virtual v13, v10, v11, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0266 invoke-virtual v13, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  026c move-result-object v0
  026e invoke-interface v12, v2, v0, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0274 const/16 v0, 206
  0278 goto +2bh
  027a new-instance v0, Ljava/io/IOException;
  027e invoke-direct v0, Ljava/io/IOException;-><init>()V
  0284 throw v0
  0286 new-instance v0, Ljava/io/IOException;
  028a invoke-direct v0, Ljava/io/IOException;-><init>()V
  0290 throw v0
  0292 new-instance v0, Ljava/lang/StringBuilder;
  0296 invoke-direct v0, v4, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  029c invoke-virtual v0, v10, v11, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  02a2 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  02a8 move-result-object v0
  02aa invoke-interface v12, v2, v0, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  02b0 const-string v0, "Invalid byte range"
  02b4 const/16 v2, 416
  02b8 const/4 v3, 0
  02ba invoke-static v2, v0, v12, v3, Lcom/personal/aihub/PreviewCache;->result(I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)Landroid/webkit/WebResourceResponse;
  02c0 move-result-object v0
  02c2 return-object v0
  02c4 move-object/from16 v17, v6
  02c8 const/16 v0, 200
  02cc move-wide v5, v14
  02ce sub-long/2addr v8, v5
  02d0 const-wide/16 v2, 1
  02d4 add-long/2addr v8, v2
  02d6 const-string v2, "Content-Length"
  02da invoke-static v8, v9, Ljava/lang/Long;->toString(J)Ljava/lang/String;
  02e0 move-result-object v3
  02e2 invoke-interface v12, v2, v3, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  02e8 invoke-interface/range v23, Landroid/webkit/WebResourceRequest;->getMethod()Ljava/lang/String;
  02ee move-result-object v2
  02f0 move-object/from16 v3, v17
  02f4 invoke-virtual v2, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  02fa move-result v2
  02fc const-string v3, "Partial Content"
  0300 const-string v4, "OK"
  0304 if-eqz v2, +01dh
  0308 new-instance v2, Landroid/webkit/WebResourceResponse;
  030c const/16 v5, 206
  0310 if-ne v0, v5, +004h
  0314 move-object v9, v3
  0316 goto +2h
  0318 move-object v9, v4
  031a new-instance v11, Ljava/io/ByteArrayInputStream;
  031e const/4 v3, 0
  0320 new-array v3, v3, [B
  0324 invoke-direct v11, v3, Ljava/io/ByteArrayInputStream;-><init>([B)V
  032a const/4 v7, 0
  032c move-object v5, v2
  032e move-object/from16 v6, v16
  0332 move v8, v0
  0334 move-object v10, v12
  0336 invoke-direct/range v5 ... v11, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String; Ljava/lang/String; I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)V
  033c return-object v2
  033e new-instance v2, Ljava/io/FileInputStream;
  0342 invoke-direct v2, v7, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0348 move-wide v10, v14
  034a cmp-long v7, v10, v5
  034e if-gez v7, +01fh
  0352 sub-long v14, v5, v10
  0356 invoke-virtual v2, v14, v15, Ljava/io/FileInputStream;->skip(J)J
  035c move-result-wide v13
  035e const-wide/16 v17, 0
  0362 cmp-long v7, v13, v17
  0366 if-lez v7, +006h
  036a add-long/2addr v10, v13
  036c move-wide/from16 v14, v17
  0370 goto -13h
  0372 new-instance v0, Ljava/io/IOException;
  0376 const-string v3, "Invalid byte offset"
  037a invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0380 throw v0
  0382 move-exception v0
  0384 invoke-virtual v2, Ljava/io/FileInputStream;->close()V
  038a throw v0
  038c new-instance v11, Lcom/personal/aihub/PreviewCache$1;
  0390 invoke-direct v11, v1, v2, v8, v9, Lcom/personal/aihub/PreviewCache$1;-><init>(Lcom/personal/aihub/PreviewCache; Ljava/io/InputStream; J)V
  0396 new-instance v2, Landroid/webkit/WebResourceResponse;
  039a const/16 v5, 206
  039e if-ne v0, v5, +004h
  03a2 move-object v9, v3
  03a4 goto +2h
  03a6 move-object v9, v4
  03a8 const/4 v7, 0
  03aa move-object v5, v2
  03ac move-object/from16 v6, v16
  03b0 move v8, v0
  03b2 move-object v10, v12
  03b4 invoke-direct/range v5 ... v11, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String; Ljava/lang/String; I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)V
  03ba return-object v2
  03bc move-exception v0
  03be invoke-virtual v0, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  03c4 move-result-object v0
  03c6 invoke-static v0, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  03cc move-result-object v0
  03ce const/16 v2, 503
  03d2 const/4 v3, 0
  03d4 invoke-static v2, v0, v12, v3, Lcom/personal/aihub/PreviewCache;->result(I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)Landroid/webkit/WebResourceResponse;
  03da move-result-object v0
  03dc return-object v0
.end method

.method revision()J
  0000 sget-wide v0, Lcom/personal/aihub/PreviewCache;->revision J
  0004 return-wide v0
.end method

.method settings(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 sget-object v0, Lcom/personal/aihub/PreviewCache;->LOCK Ljava/lang/Object;
  0004 monitor-enter v0
  0006 const-string v1, "clear"
  000a invoke-virtual v10, v1, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  0010 move-result v1
  0012 if-eqz v1, +015h
  0016 const-string v1, "clear"
  001a invoke-virtual v10, v1, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  0020 move-result-object v1
  0022 instance-of v1, v1, Ljava/lang/Boolean;
  0026 if-eqz v1, +003h
  002a goto +9h
  002c new-instance v10, Ljava/io/IOException;
  0030 const-string v1, "Invalid preview storage request."
  0034 invoke-direct v10, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  003a throw v10
  003c invoke-direct v9, Lcom/personal/aihub/PreviewCache;->config()Lorg/json/JSONObject;
  0042 move-result-object v1
  0044 const-string v2, "maxBytes"
  0048 invoke-virtual v10, v2, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  004e move-result v2
  0050 if-eqz v2, +031h
  0054 const-string v2, "maxBytes"
  0058 invoke-virtual v10, v2, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  005e move-result-object v2
  0060 const-string v3, "maxBytes"
  0064 invoke-virtual v10, v3, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  006a move-result-wide v3
  006c instance-of v5, v2, Ljava/lang/Number;
  0070 if-eqz v5, +019h
  0074 check-cast v2, Ljava/lang/Number;
  0078 invoke-virtual v2, Ljava/lang/Number;->doubleValue()D
  007e move-result-wide v5
  0080 long-to-double v7, v3
  0082 cmpl-double v2, v5, v7
  0086 if-nez v2, +00eh
  008a invoke-static v3, v4, Lcom/personal/aihub/PreviewCache;->budget(J)Z
  0090 move-result v2
  0092 if-eqz v2, +008h
  0096 const-string v2, "maxBytes"
  009a invoke-virtual v1, v2, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  00a0 goto +9h
  00a2 new-instance v10, Ljava/io/IOException;
  00a6 const-string v1, "Choose one of the preview storage sizes."
  00aa invoke-direct v10, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00b0 throw v10
  00b2 const-string v2, "offline"
  00b6 invoke-virtual v10, v2, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  00bc move-result v2
  00be const-wide/16 v3, 1
  00c2 if-eqz v2, +018h
  00c6 const-string v2, "offline"
  00ca invoke-virtual v10, v2, Lorg/json/JSONObject;->getBoolean(Ljava/lang/String;)Z
  00d0 move-result v2
  00d2 invoke-virtual v9, Lcom/personal/aihub/PreviewCache;->offline()Z
  00d8 move-result v5
  00da if-eq v2, v5, +007h
  00de sget-wide v5, Lcom/personal/aihub/PreviewCache;->revision J
  00e2 add-long/2addr v5, v3
  00e4 sput-wide v5, Lcom/personal/aihub/PreviewCache;->revision J
  00e8 const-string v5, "offline"
  00ec invoke-virtual v1, v5, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  00f2 const-string v2, "clear"
  00f6 invoke-virtual v10, v2, Lorg/json/JSONObject;->optBoolean(Ljava/lang/String;)Z
  00fc move-result v2
  00fe const/4 v5, 0
  0100 if-eqz v2, +033h
  0104 sget-wide v6, Lcom/personal/aihub/PreviewCache;->revision J
  0108 add-long/2addr v6, v3
  010a sput-wide v6, Lcom/personal/aihub/PreviewCache;->revision J
  010e iget-object v2, v9, Lcom/personal/aihub/PreviewCache;->root Ljava/io/File;
  0112 invoke-virtual v2, Ljava/io/File;->listFiles()[Ljava/io/File;
  0118 move-result-object v2
  011a if-eqz v2, +026h
  011e array-length v3, v2
  0120 move v4, v5
  0122 if-ge v4, v3, +022h
  0126 aget-object v6, v2, v4
  012a invoke-virtual v6, Ljava/io/File;->getName()Ljava/lang/String;
  0130 move-result-object v7
  0132 const-string v8, "[a-f0-9]{64}\.(body|json|tmp)(\.tmp)?$"
  0136 invoke-virtual v7, v8, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  013c move-result v7
  013e if-eqz v7, +011h
  0142 invoke-virtual v6, Ljava/io/File;->delete()Z
  0148 move-result v6
  014a if-eqz v6, +003h
  014e goto +9h
  0150 new-instance v10, Ljava/io/IOException;
  0154 const-string v1, "Could not clear a saved preview file."
  0158 invoke-direct v10, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  015e throw v10
  0160 add-int/lit8 v4, v4, 1
  0164 goto -21h
  0166 const-string v2, "offline"
  016a invoke-virtual v10, v2, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  0170 move-result v2
  0172 if-nez v2, +00ah
  0176 const-string v2, "maxBytes"
  017a invoke-virtual v10, v2, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  0180 move-result v10
  0182 if-eqz v10, +012h
  0186 new-instance v10, Ljava/io/File;
  018a iget-object v2, v9, Lcom/personal/aihub/PreviewCache;->root Ljava/io/File;
  018e const-string v3, "settings.json"
  0192 invoke-direct v10, v2, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0198 invoke-virtual v1, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  019e move-result-object v1
  01a0 invoke-static v10, v1, Lcom/personal/aihub/PreviewCache;->write(Ljava/io/File; Ljava/lang/String;)V
  01a6 iget-object v10, v9, Lcom/personal/aihub/PreviewCache;->root Ljava/io/File;
  01aa invoke-virtual v10, Ljava/io/File;->listFiles()[Ljava/io/File;
  01b0 move-result-object v10
  01b2 const-wide/16 v1, 0
  01b6 if-eqz v10, +01fh
  01ba array-length v3, v10
  01bc move v4, v5
  01be if-ge v5, v3, +01ah
  01c2 aget-object v6, v10, v5
  01c6 invoke-virtual v6, Ljava/io/File;->getName()Ljava/lang/String;
  01cc move-result-object v7
  01ce const-string v8, "[a-f0-9]{64}\.body"
  01d2 invoke-virtual v7, v8, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  01d8 move-result v7
  01da if-eqz v7, +009h
  01de invoke-virtual v6, Ljava/io/File;->length()J
  01e4 move-result-wide v6
  01e6 add-long/2addr v1, v6
  01e8 add-int/lit8 v4, v4, 1
  01ec add-int/lit8 v5, v5, 1
  01f0 goto -19h
  01f2 move v5, v4
  01f4 new-instance v10, Lorg/json/JSONObject;
  01f8 invoke-direct v10, Lorg/json/JSONObject;-><init>()V
  01fe const-string v3, "offline"
  0202 invoke-virtual v9, Lcom/personal/aihub/PreviewCache;->offline()Z
  0208 move-result v4
  020a invoke-virtual v10, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0210 move-result-object v10
  0212 const-string v3, "bytes"
  0216 invoke-virtual v10, v3, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  021c move-result-object v10
  021e const-string v1, "count"
  0222 invoke-virtual v10, v1, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0228 move-result-object v10
  022a const-string v1, "maxBytes"
  022e invoke-direct v9, Lcom/personal/aihub/PreviewCache;->storageLimit()J
  0234 move-result-wide v2
  0236 invoke-virtual v10, v1, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  023c move-result-object v10
  023e monitor-exit v0
  0240 return-object v10
  0242 move-exception v10
  0244 monitor-exit v0
  0246 throw v10
.end method

.method text(Ljava/lang/String; I)Ljava/lang/String;
  0000 new-instance v0, Ljava/io/File;
  0004 new-instance v1, Ljava/lang/StringBuilder;
  0008 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  000e invoke-direct v3, v4, Lcom/personal/aihub/PreviewCache;->ensure(Ljava/lang/String;)Ljava/io/File;
  0014 move-result-object v4
  0016 invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  001c const-string v4, ".body"
  0020 invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0026 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  002c move-result-object v4
  002e invoke-direct v0, v4, Ljava/io/File;-><init>(Ljava/lang/String;)V
  0034 invoke-virtual v0, Ljava/io/File;->length()J
  003a move-result-wide v1
  003c int-to-long v4, v5
  003e cmp-long v4, v1, v4
  0042 if-gtz v4, +007h
  0046 invoke-static v0, Lcom/personal/aihub/PreviewCache;->read(Ljava/io/File;)Ljava/lang/String;
  004c move-result-object v4
  004e return-object v4
  0050 new-instance v4, Ljava/io/IOException;
  0054 const-string v5, "Preview text exceeds the size limit"
  0058 invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  005e throw v4
.end method