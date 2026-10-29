.class Lcom/personal/aihub/StageCapture;
.super Ljava/lang/Object;
.field SCRIPT Ljava/lang/String;
.field busy Ljava/util/concurrent/atomic/AtomicBoolean;
.field closed Ljava/util/concurrent/atomic/AtomicBoolean;
.field origin Ljava/lang/String;
.field owner Landroid/app/Activity;
.field web Landroid/webkit/WebView;

.method <init>(Landroid/app/Activity; Landroid/webkit/WebView; Ljava/lang/String;)V
  0000 invoke-direct v1, Ljava/lang/Object;-><init>()V
  0006 new-instance v0, Ljava/util/concurrent/atomic/AtomicBoolean;
  000a invoke-direct v0, Ljava/util/concurrent/atomic/AtomicBoolean;-><init>()V
  0010 iput-object v0, v1, Lcom/personal/aihub/StageCapture;->busy Ljava/util/concurrent/atomic/AtomicBoolean;
  0014 new-instance v0, Ljava/util/concurrent/atomic/AtomicBoolean;
  0018 invoke-direct v0, Ljava/util/concurrent/atomic/AtomicBoolean;-><init>()V
  001e iput-object v0, v1, Lcom/personal/aihub/StageCapture;->closed Ljava/util/concurrent/atomic/AtomicBoolean;
  0022 iput-object v2, v1, Lcom/personal/aihub/StageCapture;->owner Landroid/app/Activity;
  0026 iput-object v3, v1, Lcom/personal/aihub/StageCapture;->web Landroid/webkit/WebView;
  002a iput-object v4, v1, Lcom/personal/aihub/StageCapture;->origin Ljava/lang/String;
  002e return-void 
.end method

.method capture()[B
  0000 iget-object v0, v5, Lcom/personal/aihub/StageCapture;->closed Ljava/util/concurrent/atomic/AtomicBoolean;
  0004 invoke-virtual v0, Ljava/util/concurrent/atomic/AtomicBoolean;->get()Z
  000a move-result v0
  000c if-nez v0, +038h
  0010 iget-object v0, v5, Lcom/personal/aihub/StageCapture;->busy Ljava/util/concurrent/atomic/AtomicBoolean;
  0014 const/4 v1, 1
  0016 const/4 v2, 0
  0018 invoke-virtual v0, v2, v1, Ljava/util/concurrent/atomic/AtomicBoolean;->compareAndSet(Z Z)Z
  001e move-result v0
  0020 if-eqz v0, +02eh
  0024 new-instance v0, Ljava/util/concurrent/CompletableFuture;
  0028 invoke-direct v0, Ljava/util/concurrent/CompletableFuture;-><init>()V
  002e iget-object v1, v5, Lcom/personal/aihub/StageCapture;->owner Landroid/app/Activity;
  0032 new-instance v3, Lcom/personal/aihub/StageCapture$1;
  0036 invoke-direct v3, v5, v0, Lcom/personal/aihub/StageCapture$1;-><init>(Lcom/personal/aihub/StageCapture; Ljava/util/concurrent/CompletableFuture;)V
  003c invoke-virtual v1, v3, Landroid/app/Activity;->runOnUiThread(Ljava/lang/Runnable;)V
  0042 sget-object v1, Ljava/util/concurrent/TimeUnit;->SECONDS Ljava/util/concurrent/TimeUnit;
  0046 const-wide/16 v3, 15
  004a invoke-virtual v0, v3, v4, v1, Ljava/util/concurrent/CompletableFuture;->get(J Ljava/util/concurrent/TimeUnit;)Ljava/lang/Object;
  0050 move-result-object v1
  0052 check-cast v1, [B
  0056 invoke-virtual v0, v2, Ljava/util/concurrent/CompletableFuture;->cancel(Z)Z
  005c iget-object v0, v5, Lcom/personal/aihub/StageCapture;->busy Ljava/util/concurrent/atomic/AtomicBoolean;
  0060 invoke-virtual v0, v2, Ljava/util/concurrent/atomic/AtomicBoolean;->set(Z)V
  0066 return-object v1
  0068 move-exception v1
  006a invoke-virtual v0, v2, Ljava/util/concurrent/CompletableFuture;->cancel(Z)Z
  0070 iget-object v0, v5, Lcom/personal/aihub/StageCapture;->busy Ljava/util/concurrent/atomic/AtomicBoolean;
  0074 invoke-virtual v0, v2, Ljava/util/concurrent/atomic/AtomicBoolean;->set(Z)V
  007a throw v1
  007c new-instance v0, Ljava/io/IOException;
  0080 const-string v1, "The animation snapshot is unavailable."
  0084 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  008a throw v0
.end method

.method close()V
  0000 iget-object v0, v2, Lcom/personal/aihub/StageCapture;->closed Ljava/util/concurrent/atomic/AtomicBoolean;
  0004 const/4 v1, 1
  0006 invoke-virtual v0, v1, Ljava/util/concurrent/atomic/AtomicBoolean;->set(Z)V
  000c return-void 
.end method

.method m36lambda$0$compersonalaihubStageCapture(Ljava/util/concurrent/CompletableFuture;)V
  0000 iget-object v0, v3, Lcom/personal/aihub/StageCapture;->closed Ljava/util/concurrent/atomic/AtomicBoolean;
  0004 invoke-virtual v0, Ljava/util/concurrent/atomic/AtomicBoolean;->get()Z
  000a move-result v0
  000c if-nez v0, +04bh
  0010 iget-object v0, v3, Lcom/personal/aihub/StageCapture;->owner Landroid/app/Activity;
  0014 invoke-virtual v0, Landroid/app/Activity;->isFinishing()Z
  001a move-result v0
  001c if-nez v0, +043h
  0020 iget-object v0, v3, Lcom/personal/aihub/StageCapture;->web Landroid/webkit/WebView;
  0024 invoke-virtual v0, Landroid/webkit/WebView;->isAttachedToWindow()Z
  002a move-result v0
  002c if-eqz v0, +03bh
  0030 iget-object v0, v3, Lcom/personal/aihub/StageCapture;->web Landroid/webkit/WebView;
  0034 invoke-virtual v0, Landroid/webkit/WebView;->getUrl()Ljava/lang/String;
  003a move-result-object v0
  003c if-eqz v0, +033h
  0040 iget-object v0, v3, Lcom/personal/aihub/StageCapture;->web Landroid/webkit/WebView;
  0044 invoke-virtual v0, Landroid/webkit/WebView;->getUrl()Ljava/lang/String;
  004a move-result-object v0
  004c new-instance v1, Ljava/lang/StringBuilder;
  0050 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  0056 iget-object v2, v3, Lcom/personal/aihub/StageCapture;->origin Ljava/lang/String;
  005a invoke-static v2, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0060 move-result-object v2
  0062 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0068 const-string v2, "/tools/lua-player/"
  006c invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0072 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0078 move-result-object v1
  007a invoke-virtual v0, v1, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0080 move-result v0
  0082 if-nez v0, +003h
  0086 goto +eh
  0088 iget-object v0, v3, Lcom/personal/aihub/StageCapture;->web Landroid/webkit/WebView;
  008c new-instance v1, Lcom/personal/aihub/StageCapture$2;
  0090 invoke-direct v1, v3, v4, Lcom/personal/aihub/StageCapture$2;-><init>(Lcom/personal/aihub/StageCapture; Ljava/util/concurrent/CompletableFuture;)V
  0096 const-string v4, "(()=>{const e=document.getElementById('stage');if(!e)return null;const p=e.parentElement;const r=e.dataset.phone==='1'&&(p&&p.classList.contains('stage-fit'))?p.getBoundingClientRect():e.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,vw:innerWidth,vh:innerHeight};})()"
  009a invoke-virtual v0, v4, v1, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String; Landroid/webkit/ValueCallback;)V
  00a0 goto +bh
  00a2 new-instance v0, Ljava/io/IOException;
  00a6 const-string v1, "Open the animation player before recording."
  00aa invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00b0 invoke-virtual v4, v0, Ljava/util/concurrent/CompletableFuture;->completeExceptionally(Ljava/lang/Throwable;)Z
  00b6 return-void 
.end method

.method m37lambda$1$compersonalaihubStageCapture(Ljava/util/concurrent/CompletableFuture; Ljava/lang/String;)V
  0000 move-object/from16 v1, v18
  0004 move-object/from16 v2, v19
  0008 new-instance v0, Lorg/json/JSONObject;
  000c move-object/from16 v3, v20
  0010 invoke-direct v0, v3, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0016 const-string v3, "x"
  001a invoke-virtual v0, v3, Lorg/json/JSONObject;->getDouble(Ljava/lang/String;)D
  0020 move-result-wide v3
  0022 const-string v5, "y"
  0026 invoke-virtual v0, v5, Lorg/json/JSONObject;->getDouble(Ljava/lang/String;)D
  002c move-result-wide v5
  002e const-string v7, "width"
  0032 invoke-virtual v0, v7, Lorg/json/JSONObject;->getDouble(Ljava/lang/String;)D
  0038 move-result-wide v7
  003a const-string v9, "height"
  003e invoke-virtual v0, v9, Lorg/json/JSONObject;->getDouble(Ljava/lang/String;)D
  0044 move-result-wide v9
  0046 const-string v11, "vw"
  004a invoke-virtual v0, v11, Lorg/json/JSONObject;->getDouble(Ljava/lang/String;)D
  0050 move-result-wide v11
  0052 const-string v13, "vh"
  0056 invoke-virtual v0, v13, Lorg/json/JSONObject;->getDouble(Ljava/lang/String;)D
  005c move-result-wide v13
  005e iget-object v0, v1, Lcom/personal/aihub/StageCapture;->web Landroid/webkit/WebView;
  0062 invoke-virtual v0, Landroid/webkit/WebView;->getScale()F
  0068 move-result v0
  006a invoke-static v3, v4, Ljava/lang/Double;->isFinite(D)Z
  0070 move-result v15
  0072 if-eqz v15, +0d3h
  0076 invoke-static v5, v6, Ljava/lang/Double;->isFinite(D)Z
  007c move-result v15
  007e if-eqz v15, +0cdh
  0082 invoke-static v7, v8, Ljava/lang/Double;->isFinite(D)Z
  0088 move-result v15
  008a if-eqz v15, +0c7h
  008e invoke-static v9, v10, Ljava/lang/Double;->isFinite(D)Z
  0094 move-result v15
  0096 if-eqz v15, +0c1h
  009a invoke-static v11, v12, Ljava/lang/Double;->isFinite(D)Z
  00a0 move-result v15
  00a2 if-eqz v15, +0bbh
  00a6 invoke-static v13, v14, Ljava/lang/Double;->isFinite(D)Z
  00ac move-result v15
  00ae if-eqz v15, +0b5h
  00b2 invoke-static v0, Ljava/lang/Float;->isFinite(F)Z
  00b8 move-result v15
  00ba if-eqz v15, +0afh
  00be const/4 v15, 0
  00c0 cmpl-float v15, v0, v15
  00c4 if-lez v15, +0aah
  00c8 const-wide/16 v15, 0
  00cc cmpl-double v17, v3, v15
  00d0 if-ltz v17, +0a4h
  00d4 cmpl-double v15, v5, v15
  00d8 if-ltz v15, +0a0h
  00dc const-wide/high16 v15, 4611686018427387904
  00e0 cmpl-double v17, v7, v15
  00e4 if-ltz v17, +09ah
  00e8 cmpl-double v15, v9, v15
  00ec if-ltz v15, +096h
  00f0 const-wide/high16 v15, 4661225614328463360
  00f4 cmpg-double v17, v7, v15
  00f8 if-gtz v17, +090h
  00fc cmpg-double v15, v9, v15
  0100 if-gtz v15, +08ch
  0104 add-double/2addr v7, v3
  0106 const-wide/high16 v15, 4607182418800017408
  010a add-double/2addr v11, v15
  010c cmpg-double v11, v7, v11
  0110 if-gtz v11, +084h
  0114 add-double/2addr v9, v5
  0116 add-double/2addr v13, v15
  0118 cmpg-double v11, v9, v13
  011c if-gtz v11, +07eh
  0120 float-to-double v11, v0
  0122 mul-double/2addr v3, v11
  0124 invoke-static v3, v4, Ljava/lang/Math;->ceil(D)D
  012a move-result-wide v3
  012c double-to-int v0, v3
  012e mul-double/2addr v5, v11
  0130 invoke-static v5, v6, Ljava/lang/Math;->ceil(D)D
  0136 move-result-wide v3
  0138 double-to-int v3, v3
  013a mul-double/2addr v7, v11
  013c invoke-static v7, v8, Ljava/lang/Math;->floor(D)D
  0142 move-result-wide v4
  0144 double-to-int v4, v4
  0146 sub-int/2addr v4, v0
  0148 mul-double/2addr v9, v11
  014a invoke-static v9, v10, Ljava/lang/Math;->floor(D)D
  0150 move-result-wide v5
  0152 double-to-int v5, v5
  0154 sub-int/2addr v5, v3
  0156 const/4 v6, 2
  0158 if-lt v4, v6, +058h
  015c if-lt v5, v6, +056h
  0160 const/16 v7, 4096
  0164 if-gt v4, v7, +052h
  0168 if-gt v5, v7, +050h
  016c add-int v7, v0, v4
  0170 iget-object v8, v1, Lcom/personal/aihub/StageCapture;->web Landroid/webkit/WebView;
  0174 invoke-virtual v8, Landroid/webkit/WebView;->getWidth()I
  017a move-result v8
  017c const/4 v9, 1
  017e add-int/2addr v8, v9
  0180 if-gt v7, v8, +044h
  0184 add-int v7, v3, v5
  0188 iget-object v8, v1, Lcom/personal/aihub/StageCapture;->web Landroid/webkit/WebView;
  018c invoke-virtual v8, Landroid/webkit/WebView;->getHeight()I
  0192 move-result v8
  0194 add-int/2addr v8, v9
  0196 if-gt v7, v8, +039h
  019a new-array v6, v6, [I
  019e iget-object v7, v1, Lcom/personal/aihub/StageCapture;->web Landroid/webkit/WebView;
  01a2 invoke-virtual v7, v6, Landroid/webkit/WebView;->getLocationInWindow([I)V
  01a8 new-instance v7, Landroid/graphics/Rect;
  01ac const/4 v8, 0
  01ae aget v8, v6, v8
  01b2 add-int v10, v8, v0
  01b6 aget v6, v6, v9
  01ba add-int v9, v6, v3
  01be add-int/2addr v8, v0
  01c0 add-int/2addr v8, v4
  01c2 add-int/2addr v6, v3
  01c4 add-int/2addr v6, v5
  01c6 invoke-direct v7, v10, v9, v8, v6, Landroid/graphics/Rect;-><init>(I I I I)V
  01cc sget-object v0, Landroid/graphics/Bitmap$Config;->ARGB_8888 Landroid/graphics/Bitmap$Config;
  01d0 invoke-static v4, v5, v0, Landroid/graphics/Bitmap;->createBitmap(I I Landroid/graphics/Bitmap$Config;)Landroid/graphics/Bitmap;
  01d6 move-result-object v0
  01d8 iget-object v3, v1, Lcom/personal/aihub/StageCapture;->owner Landroid/app/Activity;
  01dc invoke-virtual v3, Landroid/app/Activity;->getWindow()Landroid/view/Window;
  01e2 move-result-object v3
  01e4 new-instance v4, Lcom/personal/aihub/StageCapture$3;
  01e8 invoke-direct v4, v1, v0, v2, Lcom/personal/aihub/StageCapture$3;-><init>(Lcom/personal/aihub/StageCapture; Landroid/graphics/Bitmap; Ljava/util/concurrent/CompletableFuture;)V
  01ee new-instance v5, Landroid/os/Handler;
  01f2 invoke-static Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;
  01f8 move-result-object v6
  01fa invoke-direct v5, v6, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V
  0200 invoke-static v3, v7, v0, v4, v5, Landroid/view/PixelCopy;->request(Landroid/view/Window; Landroid/graphics/Rect; Landroid/graphics/Bitmap; Landroid/view/PixelCopy$OnPixelCopyFinishedListener; Landroid/os/Handler;)V
  0206 return-void 
  0208 new-instance v0, Ljava/io/IOException;
  020c const-string v3, "The animation stage is outside this preview."
  0210 invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0216 throw v0
  0218 new-instance v0, Ljava/io/IOException;
  021c const-string v3, "Keep the complete animation stage visible before recording."
  0220 invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0226 throw v0
  0228 move-exception v0
  022a invoke-virtual v2, v0, Ljava/util/concurrent/CompletableFuture;->completeExceptionally(Ljava/lang/Throwable;)Z
  0230 return-void 
.end method

.method m38lambda$2$compersonalaihubStageCapture(Landroid/graphics/Bitmap; Ljava/util/concurrent/CompletableFuture; I)V
  0000 const-string v0, "The device could not capture the current animation frame ("
  0004 iget-object v1, v3, Lcom/personal/aihub/StageCapture;->closed Ljava/util/concurrent/atomic/AtomicBoolean;
  0008 invoke-virtual v1, Ljava/util/concurrent/atomic/AtomicBoolean;->get()Z
  000e move-result v1
  0010 if-nez v1, +049h
  0014 invoke-virtual v5, Ljava/util/concurrent/CompletableFuture;->isDone()Z
  001a move-result v1
  001c if-eqz v1, +003h
  0020 goto +41h
  0022 if-nez v6, +029h
  0026 new-instance v6, Ljava/io/ByteArrayOutputStream;
  002a invoke-direct v6, Ljava/io/ByteArrayOutputStream;-><init>()V
  0030 sget-object v0, Landroid/graphics/Bitmap$CompressFormat;->PNG Landroid/graphics/Bitmap$CompressFormat;
  0034 const/16 v1, 100
  0038 invoke-virtual v4, v0, v1, v6, Landroid/graphics/Bitmap;->compress(Landroid/graphics/Bitmap$CompressFormat; I Ljava/io/OutputStream;)Z
  003e move-result v0
  0040 if-eqz v0, +012h
  0044 invoke-virtual v6, Ljava/io/ByteArrayOutputStream;->size()I
  004a move-result v0
  004c const/high16 v1, 8388608
  0050 if-gt v0, v1, +00ah
  0054 invoke-virtual v6, Ljava/io/ByteArrayOutputStream;->toByteArray()[B
  005a move-result-object v6
  005c invoke-virtual v5, v6, Ljava/util/concurrent/CompletableFuture;->complete(Ljava/lang/Object;)Z
  0062 goto +2ah
  0064 new-instance v6, Ljava/io/IOException;
  0068 const-string v0, "The animation snapshot exceeds8MiB."
  006c invoke-direct v6, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0072 throw v6
  0074 new-instance v1, Ljava/io/IOException;
  0078 new-instance v2, Ljava/lang/StringBuilder;
  007c invoke-direct v2, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0082 invoke-virtual v2, v6, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  0088 const-string v6, ")."
  008c invoke-virtual v2, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0092 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0098 move-result-object v6
  009a invoke-direct v1, v6, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00a0 throw v1
  00a2 invoke-virtual v4, Landroid/graphics/Bitmap;->recycle()V
  00a8 return-void 
  00aa move-exception v5
  00ac goto +9h
  00ae move-exception v6
  00b0 invoke-virtual v5, v6, Ljava/util/concurrent/CompletableFuture;->completeExceptionally(Ljava/lang/Throwable;)Z
  00b6 invoke-virtual v4, Landroid/graphics/Bitmap;->recycle()V
  00bc return-void 
  00be invoke-virtual v4, Landroid/graphics/Bitmap;->recycle()V
  00c4 throw v5
.end method