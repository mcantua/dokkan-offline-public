.class Lcom/personal/aihub/PreviewResources;
.super Ljava/lang/Object;

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method error(I Ljava/lang/String;)Landroid/webkit/WebResourceResponse;
  0000 new-instance v7, Landroid/webkit/WebResourceResponse;
  0004 const-string v0, "Cache-Control"
  0008 const-string v1, "no-store"
  000c invoke-static v0, v1, Ljava/util/Collections;->singletonMap(Ljava/lang/Object; Ljava/lang/Object;)Ljava/util/Map;
  0012 move-result-object v5
  0014 new-instance v6, Ljava/io/ByteArrayInputStream;
  0018 sget-object v0, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  001c invoke-virtual v9, v0, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0022 move-result-object v9
  0024 invoke-direct v6, v9, Ljava/io/ByteArrayInputStream;-><init>([B)V
  002a const-string v1, "text/plain"
  002e const-string v2, "UTF-8"
  0032 const-string v4, "Unavailable"
  0036 move-object v0, v7
  0038 move v3, v8
  003a invoke-direct/range v0 ... v6, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String; Ljava/lang/String; I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)V
  0040 return-object v7
.end method

.method response(Landroid/content/Context; Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;
  0000 const-string v0, "-"
  0004 const-string v1, "bytes "
  0008 invoke-interface/range v24, Landroid/webkit/WebResourceRequest;->getUrl()Landroid/net/Uri;
  000e move-result-object v2
  0010 const-string v3, "https"
  0014 invoke-virtual v2, Landroid/net/Uri;->getScheme()Ljava/lang/String;
  001a move-result-object v4
  001c invoke-virtual v3, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0022 move-result v3
  0024 const/4 v4, 0
  0026 if-eqz v3, +27bh
  002a const-string v3, "dokkan-eclipse.com"
  002e invoke-virtual v2, Landroid/net/Uri;->getHost()Ljava/lang/String;
  0034 move-result-object v5
  0036 invoke-virtual v3, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  003c move-result v3
  003e if-eqz v3, +26fh
  0042 invoke-virtual v2, Landroid/net/Uri;->getPort()I
  0048 move-result v3
  004a const/4 v5, -1
  004c if-ne v3, v5, +268h
  0050 invoke-virtual v2, Landroid/net/Uri;->getUserInfo()Ljava/lang/String;
  0056 move-result-object v3
  0058 if-eqz v3, +004h
  005c goto/16 +260h
  0060 invoke-virtual v2, Landroid/net/Uri;->getPath()Ljava/lang/String;
  0066 move-result-object v2
  0068 const-string v3, "/_forge/training-context.js"
  006c invoke-virtual v3, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0072 move-result v3
  0074 if-eqz v3, +006h
  0078 const-string v2, "ui/training-context.js"
  007c goto/16 +095h
  0080 const-string v3, "/_forge/native-audio.js"
  0084 invoke-virtual v3, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  008a move-result v3
  008c if-eqz v3, +006h
  0090 const-string v2, "ui/native-audio.js"
  0094 goto/16 +089h
  0098 const-string v3, "/_forge/audio-bank.js"
  009c invoke-virtual v3, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00a2 move-result v3
  00a4 if-eqz v3, +006h
  00a8 const-string v2, "ui/audio-bank.js"
  00ac goto/16 +07dh
  00b0 const-string v3, "/_forge/imported-audio.js"
  00b4 invoke-virtual v3, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00ba move-result v3
  00bc if-eqz v3, +006h
  00c0 const-string v2, "ui/imported-audio.js"
  00c4 goto/16 +071h
  00c8 const-string v3, "/_forge/media/movie-edit-plan.js"
  00cc invoke-virtual v3, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00d2 move-result v3
  00d4 if-eqz v3, +006h
  00d8 const-string v2, "ui/movie-edit-plan.js"
  00dc goto/16 +065h
  00e0 const-string v3, "/_forge/media/usm-writer.js"
  00e4 invoke-virtual v3, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00ea move-result v3
  00ec if-eqz v3, +005h
  00f0 const-string v2, "ui/usm-writer.js"
  00f4 goto +59h
  00f6 const-string v3, "/_forge/media/native-adx.js"
  00fa invoke-virtual v3, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0100 move-result v3
  0102 if-eqz v3, +005h
  0106 const-string v2, "ui/native-adx.js"
  010a goto +4eh
  010c const-string v3, "/_forge/media/hca-metadata.js"
  0110 invoke-virtual v3, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0116 move-result v3
  0118 if-eqz v3, +005h
  011c const-string v2, "ui/hca-metadata.js"
  0120 goto +43h
  0122 const-string v3, "/tools/usm-player/js/pipeline.js"
  0126 invoke-virtual v3, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  012c move-result v3
  012e if-eqz v3, +005h
  0132 const-string v2, "ui/media-pipeline.js"
  0136 goto +38h
  0138 const-string v3, "/tools/lua-player/js/forge-imported.js"
  013c invoke-virtual v3, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0142 move-result v3
  0144 if-eqz v3, +005h
  0148 const-string v2, "ui/imported-preview.js"
  014c goto +2dh
  014e const-string v3, "/tools/usm-player/js/forge-metadata.js"
  0152 invoke-virtual v3, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0158 move-result v3
  015a if-eqz v3, +005h
  015e const-string v2, "ui/media-metadata.js"
  0162 goto +22h
  0164 if-eqz v2, +020h
  0168 const-string v3, "/_forge/media/(libav/)?[A-Za-z0-9][A-Za-z0-9_.-]*"
  016c invoke-virtual v2, v3, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0172 move-result v3
  0174 if-nez v3, +003h
  0178 goto +16h
  017a new-instance v3, Ljava/lang/StringBuilder;
  017e const-string v6, "ui/vendor/media/"
  0182 invoke-direct v3, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0188 const/16 v6, 14
  018c invoke-virtual v2, v6, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0192 move-result-object v2
  0194 invoke-virtual v3, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  019a invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01a0 move-result-object v2
  01a2 goto +2h
  01a4 move-object v2, v4
  01a6 if-nez v2, +003h
  01aa return-object v4
  01ac invoke-interface/range v24, Landroid/webkit/WebResourceRequest;->getMethod()Ljava/lang/String;
  01b2 move-result-object v3
  01b4 const-string v6, "GET"
  01b8 invoke-virtual v3, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01be move-result v3
  01c0 const-string v6, "HEAD"
  01c4 if-nez v3, +015h
  01c8 invoke-interface/range v24, Landroid/webkit/WebResourceRequest;->getMethod()Ljava/lang/String;
  01ce move-result-object v3
  01d0 invoke-virtual v3, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01d6 move-result v3
  01d8 if-nez v3, +00bh
  01dc const/16 v0, 405
  01e0 const-string v1, "Method not allowed"
  01e4 invoke-static v0, v1, Lcom/personal/aihub/PreviewResources;->error(I Ljava/lang/String;)Landroid/webkit/WebResourceResponse;
  01ea move-result-object v0
  01ec return-object v0
  01ee invoke-virtual/range v23, Landroid/content/Context;->getAssets()Landroid/content/res/AssetManager;
  01f4 move-result-object v3
  01f6 invoke-virtual v3, v2, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;
  01fc move-result-object v3
  01fe invoke-virtual v3, Ljava/io/InputStream;->available()I
  0204 move-result v7
  0206 int-to-long v7, v7
  0208 const-wide/16 v9, 1
  020c sub-long v11, v7, v9
  0210 invoke-interface/range v24, Landroid/webkit/WebResourceRequest;->getRequestHeaders()Ljava/util/Map;
  0216 move-result-object v13
  0218 const-string v14, "Range"
  021c invoke-interface v13, v14, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0222 move-result-object v13
  0224 check-cast v13, Ljava/lang/String;
  0228 if-nez v13, +00eh
  022c invoke-interface/range v24, Landroid/webkit/WebResourceRequest;->getRequestHeaders()Ljava/util/Map;
  0232 move-result-object v13
  0234 const-string v14, "range"
  0238 invoke-interface v13, v14, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  023e move-result-object v13
  0240 check-cast v13, Ljava/lang/String;
  0244 new-instance v15, Ljava/util/HashMap;
  0248 invoke-direct v15, Ljava/util/HashMap;-><init>()V
  024e const-string v14, "Cache-Control"
  0252 const-string v4, "no-store"
  0256 invoke-virtual v15, v14, v4, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  025c const-string v4, "Accept-Ranges"
  0260 const-string v14, "bytes"
  0264 invoke-virtual v15, v4, v14, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  026a const-string v4, "Cross-Origin-Resource-Policy"
  026e const-string v14, "same-origin"
  0272 invoke-virtual v15, v4, v14, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0278 const-wide/16 v9, 0
  027c if-nez v13, +007h
  0280 const/16 v0, 200
  0284 move-wide v4, v9
  0286 goto/16 +07fh
  028a const-string v4, "bytes=([0-9]+-[0-9]*|-[0-9]+)"
  028e invoke-virtual v13, v4, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0294 move-result v4
  0296 const-string v14, "Invalid byte range"
  029a if-eqz v4, +12eh
  029e cmp-long v4, v7, v9
  02a2 if-eqz v4, +12ah
  02a6 const/4 v4, 6
  02a8 invoke-virtual v13, v4, Ljava/lang/String;->substring(I)Ljava/lang/String;
  02ae move-result-object v4
  02b0 invoke-virtual v4, v0, v5, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  02b6 move-result-object v4
  02b8 const/4 v5, 0
  02ba aget-object v13, v4, v5
  02be invoke-virtual v13, Ljava/lang/String;->isEmpty()Z
  02c4 move-result v5
  02c6 const/4 v13, 1
  02c8 if-eqz v5, +019h
  02cc aget-object v4, v4, v13
  02d0 invoke-static v4, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  02d6 move-result-wide v4
  02d8 cmp-long v13, v4, v9
  02dc if-lez v13, +009h
  02e0 sub-long v4, v7, v4
  02e4 invoke-static v9, v10, v4, v5, Ljava/lang/Math;->max(J J)J
  02ea move-result-wide v4
  02ec goto +23h
  02ee new-instance v0, Ljava/io/IOException;
  02f2 invoke-direct v0, Ljava/io/IOException;-><init>()V
  02f8 throw v0
  02fa const/4 v5, 0
  02fc aget-object v21, v4, v5
  0300 invoke-static/range v21, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  0306 move-result-wide v21
  0308 aget-object v5, v4, v13
  030c invoke-virtual v5, Ljava/lang/String;->isEmpty()Z
  0312 move-result v5
  0314 if-nez v5, +00dh
  0318 aget-object v4, v4, v13
  031c invoke-static v4, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  0322 move-result-wide v4
  0324 invoke-static v11, v12, v4, v5, Ljava/lang/Math;->min(J J)J
  032a move-result-wide v4
  032c move-wide v11, v4
  032e move-wide/from16 v4, v21
  0332 cmp-long v13, v4, v7
  0336 if-gez v13, +0d0h
  033a cmp-long v13, v11, v4
  033e if-ltz v13, +0cch
  0342 const-string v13, "Content-Range"
  0346 new-instance v9, Ljava/lang/StringBuilder;
  034a invoke-direct v9, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0350 invoke-virtual v9, v4, v5, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0356 invoke-virtual v9, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  035c invoke-virtual v9, v11, v12, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0362 const-string v0, "/"
  0366 invoke-virtual v9, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  036c invoke-virtual v9, v7, v8, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0372 invoke-virtual v9, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0378 move-result-object v0
  037a invoke-virtual v15, v13, v0, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0380 const/16 v0, 206
  0384 sub-long/2addr v11, v4
  0386 const-wide/16 v7, 1
  038a add-long/2addr v11, v7
  038c const-string v1, "Content-Length"
  0390 invoke-static v11, v12, Ljava/lang/Long;->toString(J)Ljava/lang/String;
  0396 move-result-object v7
  0398 invoke-virtual v15, v1, v7, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  039e invoke-interface/range v24, Landroid/webkit/WebResourceRequest;->getMethod()Ljava/lang/String;
  03a4 move-result-object v1
  03a6 invoke-virtual v1, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  03ac move-result v1
  03ae const-string v6, "Partial Content"
  03b2 const-string v7, "OK"
  03b6 const-string v8, "UTF-8"
  03ba const-string v9, ".wasm"
  03be if-eqz v1, +036h
  03c2 invoke-virtual v3, Ljava/io/InputStream;->close()V
  03c8 new-instance v1, Landroid/webkit/WebResourceResponse;
  03cc invoke-static v2, Lcom/personal/aihub/PreviewResources;->type(Ljava/lang/String;)Ljava/lang/String;
  03d2 move-result-object v3
  03d4 invoke-virtual v2, v9, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  03da move-result v2
  03dc if-eqz v2, +007h
  03e0 const/16 v2, 206
  03e4 const/16 v16, 0
  03e8 goto +5h
  03ea move-object/from16 v16, v8
  03ee const/16 v2, 206
  03f2 if-ne v0, v2, +005h
  03f6 move-object/from16 v18, v6
  03fa goto +3h
  03fc move-object/from16 v18, v7
  0400 new-instance v2, Ljava/io/ByteArrayInputStream;
  0404 const/4 v4, 0
  0406 new-array v4, v4, [B
  040a invoke-direct v2, v4, Ljava/io/ByteArrayInputStream;-><init>([B)V
  0410 move-object v14, v1
  0412 move-object v10, v15
  0414 move-object v15, v3
  0416 move/from16 v17, v0
  041a move-object/from16 v19, v10
  041e move-object/from16 v20, v2
  0422 invoke-direct/range v14 ... v20, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String; Ljava/lang/String; I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)V
  0428 return-object v1
  042a move-object v10, v15
  042c const-wide/16 v13, 0
  0430 cmp-long v1, v13, v4
  0434 if-gez v1, +022h
  0438 move-object/from16 v24, v6
  043c move-object v1, v7
  043e sub-long v6, v4, v13
  0442 invoke-virtual v3, v6, v7, Ljava/io/InputStream;->skip(J)J
  0448 move-result-wide v6
  044a const-wide/16 v17, 0
  044e cmp-long v15, v6, v17
  0452 if-gtz v15, +00eh
  0456 invoke-virtual v3, Ljava/io/InputStream;->close()V
  045c const-string v0, "Invalid byte offset"
  0460 const/16 v1, 416
  0464 invoke-static v1, v0, Lcom/personal/aihub/PreviewResources;->error(I Ljava/lang/String;)Landroid/webkit/WebResourceResponse;
  046a move-result-object v0
  046c return-object v0
  046e add-long/2addr v13, v6
  0470 move-object/from16 v6, v24
  0474 move-object v7, v1
  0476 goto -23h
  0478 move-object/from16 v24, v6
  047c move-object v1, v7
  047e new-instance v4, Landroid/webkit/WebResourceResponse;
  0482 invoke-static v2, Lcom/personal/aihub/PreviewResources;->type(Ljava/lang/String;)Ljava/lang/String;
  0488 move-result-object v15
  048a invoke-virtual v2, v9, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  0490 move-result v2
  0492 if-eqz v2, +007h
  0496 const/16 v2, 206
  049a const/16 v16, 0
  049e goto +5h
  04a0 move-object/from16 v16, v8
  04a4 const/16 v2, 206
  04a8 if-ne v0, v2, +005h
  04ac move-object/from16 v18, v24
  04b0 goto +3h
  04b2 move-object/from16 v18, v1
  04b6 new-instance v1, Lcom/personal/aihub/PreviewResources$1;
  04ba invoke-direct v1, v3, v11, v12, Lcom/personal/aihub/PreviewResources$1;-><init>(Ljava/io/InputStream; J)V
  04c0 move-object v14, v4
  04c2 move/from16 v17, v0
  04c6 move-object/from16 v19, v10
  04ca move-object/from16 v20, v1
  04ce invoke-direct/range v14 ... v20, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String; Ljava/lang/String; I Ljava/lang/String; Ljava/util/Map; Ljava/io/InputStream;)V
  04d4 return-object v4
  04d6 new-instance v0, Ljava/io/IOException;
  04da invoke-direct v0, Ljava/io/IOException;-><init>()V
  04e0 throw v0
  04e2 invoke-virtual v3, Ljava/io/InputStream;->close()V
  04e8 const/16 v0, 416
  04ec invoke-static v0, v14, Lcom/personal/aihub/PreviewResources;->error(I Ljava/lang/String;)Landroid/webkit/WebResourceResponse;
  04f2 move-result-object v0
  04f4 return-object v0
  04f6 const/16 v0, 416
  04fa invoke-virtual v3, Ljava/io/InputStream;->close()V
  0500 invoke-static v0, v14, Lcom/personal/aihub/PreviewResources;->error(I Ljava/lang/String;)Landroid/webkit/WebResourceResponse;
  0506 move-result-object v0
  0508 return-object v0
  050a const/16 v0, 404
  050e const-string v1, "A packaged movie component is missing. Reinstall the app."
  0512 invoke-static v0, v1, Lcom/personal/aihub/PreviewResources;->error(I Ljava/lang/String;)Landroid/webkit/WebResourceResponse;
  0518 move-result-object v0
  051a return-object v0
  051c move-object v0, v4
  051e return-object v0
.end method

.method type(Ljava/lang/String;)Ljava/lang/String;
  0000 const-string v0, ".wasm"
  0004 invoke-virtual v1, v0, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  000a move-result v0
  000c if-eqz v0, +005h
  0010 const-string v1, "application/wasm"
  0014 return-object v1
  0016 const-string v0, ".js"
  001a invoke-virtual v1, v0, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  0020 move-result v0
  0022 if-eqz v0, +005h
  0026 const-string v1, "application/javascript"
  002a return-object v1
  002c const-string v0, ".json"
  0030 invoke-virtual v1, v0, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  0036 move-result v1
  0038 if-eqz v1, +005h
  003c const-string v1, "application/json"
  0040 goto +3h
  0042 const-string v1, "text/plain"
  0046 return-object v1
.end method