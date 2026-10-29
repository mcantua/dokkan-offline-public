.class Lcom/personal/aihub/AiHandoff;
.super Ljava/lang/Object;

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method compose(Landroid/app/Activity; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 const-string v0, "provider"
  0004 invoke-virtual v11, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  000a move-result-object v0
  000c sget-object v1, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  0010 invoke-virtual v0, v1, Ljava/lang/String;->toUpperCase(Ljava/util/Locale;)Ljava/lang/String;
  0016 move-result-object v0
  0018 invoke-static v0, Lcom/personal/aihub/Provider;->valueOf(Ljava/lang/String;)Lcom/personal/aihub/Provider;
  001e move-result-object v4
  0020 const-string v0, "prompt"
  0024 invoke-virtual v11, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  002a move-result-object v3
  002c invoke-virtual v3, Ljava/lang/String;->trim()Ljava/lang/String;
  0032 move-result-object v11
  0034 invoke-virtual v11, Ljava/lang/String;->isEmpty()Z
  003a move-result v11
  003c if-nez v11, +063h
  0040 invoke-virtual v3, Ljava/lang/String;->length()I
  0046 move-result v11
  0048 const v0, 64000
  004e if-gt v11, v0, +05ah
  0052 const/4 v11, 0
  0054 invoke-virtual v3, v11, Ljava/lang/String;->indexOf(I)I
  005a move-result v11
  005c if-gez v11, +053h
  0060 new-instance v11, Ljava/util/concurrent/atomic/AtomicReference;
  0064 invoke-direct v11, Ljava/util/concurrent/atomic/AtomicReference;-><init>()V
  006a new-instance v0, Ljava/util/concurrent/atomic/AtomicReference;
  006e invoke-direct v0, Ljava/util/concurrent/atomic/AtomicReference;-><init>()V
  0074 new-instance v8, Ljava/util/concurrent/CountDownLatch;
  0078 const/4 v1, 1
  007a invoke-direct v8, v1, Ljava/util/concurrent/CountDownLatch;-><init>(I)V
  0080 new-instance v9, Lcom/personal/aihub/AiHandoff$$ExternalSyntheticLambda0;
  0084 move-object v1, v9
  0086 move-object v2, v10
  0088 move-object v5, v11
  008a move-object v6, v0
  008c move-object v7, v8
  008e invoke-direct/range v1 ... v7, Lcom/personal/aihub/AiHandoff$$ExternalSyntheticLambda0;-><init>(Landroid/app/Activity; Ljava/lang/String; Lcom/personal/aihub/Provider; Ljava/util/concurrent/atomic/AtomicReference; Ljava/util/concurrent/atomic/AtomicReference; Ljava/util/concurrent/CountDownLatch;)V
  0094 invoke-static Landroid/os/Looper;->myLooper()Landroid/os/Looper;
  009a move-result-object v1
  009c invoke-static Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;
  00a2 move-result-object v2
  00a4 if-ne v1, v2, +006h
  00a8 invoke-interface v9, Ljava/lang/Runnable;->run()V
  00ae goto +4h
  00b0 invoke-virtual v10, v9, Landroid/app/Activity;->runOnUiThread(Ljava/lang/Runnable;)V
  00b6 const-wide/16 v1, 15
  00ba sget-object v10, Ljava/util/concurrent/TimeUnit;->SECONDS Ljava/util/concurrent/TimeUnit;
  00be invoke-virtual v8, v1, v2, v10, Ljava/util/concurrent/CountDownLatch;->await(J Ljava/util/concurrent/TimeUnit;)Z
  00c4 move-result v10
  00c6 if-eqz v10, +016h
  00ca invoke-virtual v0, Ljava/util/concurrent/atomic/AtomicReference;->get()Ljava/lang/Object;
  00d0 move-result-object v10
  00d2 if-nez v10, +009h
  00d6 invoke-virtual v11, Ljava/util/concurrent/atomic/AtomicReference;->get()Ljava/lang/Object;
  00dc move-result-object v10
  00de check-cast v10, Lorg/json/JSONObject;
  00e2 return-object v10
  00e4 invoke-virtual v0, Ljava/util/concurrent/atomic/AtomicReference;->get()Ljava/lang/Object;
  00ea move-result-object v10
  00ec check-cast v10, Ljava/lang/Exception;
  00f0 throw v10
  00f2 new-instance v10, Ljava/io/IOException;
  00f6 const-string v11, "Opening the assistant is taking too long. Check the selected app before retrying."
  00fa invoke-direct v10, v11, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0100 throw v10
  0102 new-instance v10, Ljava/io/IOException;
  0106 const-string v11, "Use a prompt between 1 and 64,000 characters."
  010a invoke-direct v10, v11, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0110 throw v10
  0112 new-instance v10, Ljava/io/IOException;
  0116 const-string v11, "Choose ChatGPT, Claude, or Grok."
  011a invoke-direct v10, v11, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0120 throw v10
.end method

.method lambda$compose$0(Landroid/app/Activity; Ljava/lang/String; Lcom/personal/aihub/Provider; Ljava/util/concurrent/atomic/AtomicReference; Ljava/util/concurrent/atomic/AtomicReference; Ljava/util/concurrent/CountDownLatch;)V
  0000 const-string v0, "Could not open "
  0004 invoke-virtual v3, Landroid/app/Activity;->isFinishing()Z
  000a move-result v1
  000c if-nez v1, +094h
  0010 invoke-virtual v3, Landroid/app/Activity;->isDestroyed()Z
  0016 move-result v1
  0018 if-nez v1, +08eh
  001c const-string v1, "clipboard"
  0020 invoke-virtual v3, v1, Landroid/app/Activity;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;
  0026 move-result-object v1
  0028 check-cast v1, Landroid/content/ClipboardManager;
  002c if-eqz v1, +07ch
  0030 const-string v2, "Dokkan Unit Creator AI prompt"
  0034 invoke-static v2, v4, Landroid/content/ClipData;->newPlainText(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Landroid/content/ClipData;
  003a move-result-object v2
  003c invoke-virtual v1, v2, Landroid/content/ClipboardManager;->setPrimaryClip(Landroid/content/ClipData;)V
  0042 new-instance v1, Landroid/content/Intent;
  0046 const-string v2, "android.intent.action.SEND"
  004a invoke-direct v1, v2, Landroid/content/Intent;-><init>(Ljava/lang/String;)V
  0050 const-string v2, "text/plain"
  0054 invoke-virtual v1, v2, Landroid/content/Intent;->setType(Ljava/lang/String;)Landroid/content/Intent;
  005a move-result-object v1
  005c const-string v2, "android.intent.extra.TEXT"
  0060 invoke-virtual v1, v2, v4, Landroid/content/Intent;->putExtra(Ljava/lang/String; Ljava/lang/String;)Landroid/content/Intent;
  0066 move-result-object v4
  0068 iget-object v1, v5, Lcom/personal/aihub/Provider;->packageName Ljava/lang/String;
  006c invoke-virtual v4, v1, Landroid/content/Intent;->setPackage(Ljava/lang/String;)Landroid/content/Intent;
  0072 move-result-object v4
  0074 invoke-virtual v3, Landroid/app/Activity;->getPackageManager()Landroid/content/pm/PackageManager;
  007a move-result-object v1
  007c invoke-virtual v4, v1, Landroid/content/Intent;->resolveActivity(Landroid/content/pm/PackageManager;)Landroid/content/ComponentName;
  0082 move-result-object v1
  0084 if-eqz v1, +008h
  0088 invoke-virtual v3, v4, Landroid/app/Activity;->startActivity(Landroid/content/Intent;)V
  008e const-string v3, "share"
  0092 goto +25h
  0094 invoke-virtual v3, Landroid/app/Activity;->getPackageManager()Landroid/content/pm/PackageManager;
  009a move-result-object v4
  009c iget-object v1, v5, Lcom/personal/aihub/Provider;->packageName Ljava/lang/String;
  00a0 invoke-virtual v4, v1, Landroid/content/pm/PackageManager;->getLaunchIntentForPackage(Ljava/lang/String;)Landroid/content/Intent;
  00a6 move-result-object v4
  00a8 if-eqz v4, +008h
  00ac invoke-virtual v3, v4, Landroid/app/Activity;->startActivity(Landroid/content/Intent;)V
  00b2 const-string v3, "clipboard-app"
  00b6 goto +13h
  00b8 new-instance v4, Landroid/content/Intent;
  00bc const-string v1, "android.intent.action.VIEW"
  00c0 iget-object v2, v5, Lcom/personal/aihub/Provider;->website Ljava/lang/String;
  00c4 invoke-static v2, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  00ca move-result-object v2
  00cc invoke-direct v4, v1, v2, Landroid/content/Intent;-><init>(Ljava/lang/String; Landroid/net/Uri;)V
  00d2 invoke-virtual v3, v4, Landroid/app/Activity;->startActivity(Landroid/content/Intent;)V
  00d8 const-string v3, "clipboard-web"
  00dc new-instance v4, Lorg/json/JSONObject;
  00e0 invoke-direct v4, Lorg/json/JSONObject;-><init>()V
  00e6 const-string v1, "requested"
  00ea const/4 v2, 1
  00ec invoke-virtual v4, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  00f2 move-result-object v4
  00f4 const-string v1, "copied"
  00f8 invoke-virtual v4, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  00fe move-result-object v4
  0100 const-string v1, "provider"
  0104 iget-object v2, v5, Lcom/personal/aihub/Provider;->label Ljava/lang/String;
  0108 invoke-virtual v4, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  010e move-result-object v4
  0110 const-string v1, "transport"
  0114 invoke-virtual v4, v1, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  011a move-result-object v3
  011c invoke-virtual v6, v3, Ljava/util/concurrent/atomic/AtomicReference;->set(Ljava/lang/Object;)V
  0122 goto +2fh
  0124 new-instance v3, Ljava/io/IOException;
  0128 const-string v4, "The clipboard is unavailable."
  012c invoke-direct v3, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0132 throw v3
  0134 new-instance v3, Ljava/io/IOException;
  0138 const-string v4, "Return to the creator and try again."
  013c invoke-direct v3, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0142 throw v3
  0144 move-exception v3
  0146 goto +21h
  0148 move-exception v3
  014a new-instance v4, Ljava/io/IOException;
  014e new-instance v6, Ljava/lang/StringBuilder;
  0152 invoke-direct v6, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0158 iget-object v5, v5, Lcom/personal/aihub/Provider;->label Ljava/lang/String;
  015c invoke-virtual v6, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0162 const-string v5, ". Your prompt may already be copied; open its official app and paste it."
  0166 invoke-virtual v6, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  016c invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0172 move-result-object v5
  0174 invoke-direct v4, v5, v3, Ljava/io/IOException;-><init>(Ljava/lang/String; Ljava/lang/Throwable;)V
  017a invoke-virtual v7, v4, Ljava/util/concurrent/atomic/AtomicReference;->set(Ljava/lang/Object;)V
  0180 invoke-virtual v8, Ljava/util/concurrent/CountDownLatch;->countDown()V
  0186 return-void 
  0188 invoke-virtual v8, Ljava/util/concurrent/CountDownLatch;->countDown()V
  018e throw v3
.end method