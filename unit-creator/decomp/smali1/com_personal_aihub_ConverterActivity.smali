.class Lcom/personal/aihub/ConverterActivity;
.super Landroid/app/Activity;
.field HOME Ljava/lang/String;
.field downloadAgent Ljava/lang/String;
.field downloadUrl Ljava/lang/String;
.field metadata Ljava/lang/String;
.field patch Ljava/io/File;
.field status Landroid/widget/TextView;
.field token Ljava/lang/String;
.field web Landroid/webkit/WebView;
.field worker Ljava/util/concurrent/ExecutorService;

.method <init>()V
  0000 invoke-direct v1, Landroid/app/Activity;-><init>()V
  0006 invoke-static Ljava/util/concurrent/Executors;->newSingleThreadExecutor()Ljava/util/concurrent/ExecutorService;
  000c move-result-object v0
  000e iput-object v0, v1, Lcom/personal/aihub/ConverterActivity;->worker Ljava/util/concurrent/ExecutorService;
  0012 return-void 
.end method

.method access$000(Lcom/personal/aihub/ConverterActivity;)Ljava/lang/String;
  0000 iget-object v0, v0, Lcom/personal/aihub/ConverterActivity;->token Ljava/lang/String;
  0004 return-object v0
.end method

.method access$100(Lcom/personal/aihub/ConverterActivity;)Landroid/widget/TextView;
  0000 iget-object v0, v0, Lcom/personal/aihub/ConverterActivity;->status Landroid/widget/TextView;
  0004 return-object v0
.end method

.method access$200(Lcom/personal/aihub/ConverterActivity;)Landroid/webkit/WebView;
  0000 iget-object v0, v0, Lcom/personal/aihub/ConverterActivity;->web Landroid/webkit/WebView;
  0004 return-object v0
.end method

.method access$202(Lcom/personal/aihub/ConverterActivity; Landroid/webkit/WebView;)Landroid/webkit/WebView;
  0000 iput-object v1, v0, Lcom/personal/aihub/ConverterActivity;->web Landroid/webkit/WebView;
  0004 return-object v1
.end method

.method access$300(Lcom/personal/aihub/ConverterActivity;)Ljava/lang/String;
  0000 iget-object v0, v0, Lcom/personal/aihub/ConverterActivity;->metadata Ljava/lang/String;
  0004 return-object v0
.end method

.method allowed(Ljava/lang/String; Z)Z
  0000 const/4 v0, 0
  0002 invoke-static v5, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  0008 move-result-object v5
  000a const-string v1, "https"
  000e invoke-virtual v5, Landroid/net/Uri;->getScheme()Ljava/lang/String;
  0014 move-result-object v2
  0016 invoke-virtual v1, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  001c move-result v1
  001e if-nez v1, +003h
  0022 return v0
  0024 invoke-virtual v5, Landroid/net/Uri;->getHost()Ljava/lang/String;
  002a move-result-object v5
  002c const-string v1, "dokkan-eclipse.com"
  0030 invoke-virtual v1, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0036 move-result v1
  0038 const/4 v2, 1
  003a if-eqz v1, +003h
  003e return v2
  0040 if-eqz v6, +00bh
  0044 const-string v6, "cdn.dokkan-eclipse.com"
  0048 invoke-virtual v6, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  004e move-result v5
  0050 if-eqz v5, +01ah
  0054 return v2
  0056 const-string v6, "discord.com"
  005a const-string v1, "www.discord.com"
  005e const-string v3, "discordapp.com"
  0062 const-string v4, "www.discordapp.com"
  0066 filled-new-array v6, v1, v3, v4, [Ljava/lang/String;
  006c move-result-object v6
  006e invoke-static v6, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  0074 move-result-object v6
  0076 invoke-interface v6, v5, Ljava/util/List;->contains(Ljava/lang/Object;)Z
  007c move-result v5
  007e if-eqz v5, +003h
  0082 return v2
  0084 return v0
.end method

.method download(Ljava/lang/String; Ljava/lang/String; Landroid/net/Uri;)V
  0000 const/4 v0, 0
  0002 move v1, v0
  0004 const/4 v2, 6
  0006 if-ge v1, v2, +12bh
  000a const/4 v2, 1
  000c const/4 v3, 0
  000e invoke-static v12, v2, Lcom/personal/aihub/ConverterActivity;->allowed(Ljava/lang/String; Z)Z
  0014 move-result v2
  0016 if-eqz v2, +105h
  001a new-instance v2, Ljava/net/URL;
  001e invoke-direct v2, v12, Ljava/net/URL;-><init>(Ljava/lang/String;)V
  0024 invoke-virtual v2, Ljava/net/URL;->openConnection()Ljava/net/URLConnection;
  002a move-result-object v4
  002c check-cast v4, Ljava/net/HttpURLConnection;
  0030 const/16 v5, 20000
  0034 invoke-virtual v4, v5, Ljava/net/HttpURLConnection;->setConnectTimeout(I)V
  003a const v5, 60000
  0040 invoke-virtual v4, v5, Ljava/net/HttpURLConnection;->setReadTimeout(I)V
  0046 invoke-virtual v4, v0, Ljava/net/HttpURLConnection;->setInstanceFollowRedirects(Z)V
  004c const-string v5, "User-Agent"
  0050 if-nez v13, +005h
  0054 const-string v6, "DokkanUnitCreator/2.1"
  0058 goto +2h
  005a move-object v6, v13
  005c invoke-virtual v4, v5, v6, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String; Ljava/lang/String;)V
  0062 invoke-static Landroid/webkit/CookieManager;->getInstance()Landroid/webkit/CookieManager;
  0068 move-result-object v5
  006a invoke-virtual v5, v12, Landroid/webkit/CookieManager;->getCookie(Ljava/lang/String;)Ljava/lang/String;
  0070 move-result-object v12
  0072 if-eqz v12, +007h
  0076 const-string v5, "Cookie"
  007a invoke-virtual v4, v5, v12, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String; Ljava/lang/String;)V
  0080 invoke-virtual v4, Ljava/net/HttpURLConnection;->getResponseCode()I
  0086 move-result v12
  0088 const/16 v5, 300
  008c if-lt v12, v5, +01dh
  0090 const/16 v5, 400
  0094 if-ge v12, v5, +019h
  0098 new-instance v12, Ljava/net/URL;
  009c const-string v5, "Location"
  00a0 invoke-virtual v4, v5, Ljava/net/HttpURLConnection;->getHeaderField(Ljava/lang/String;)Ljava/lang/String;
  00a6 move-result-object v5
  00a8 invoke-direct v12, v2, v5, Ljava/net/URL;-><init>(Ljava/net/URL; Ljava/lang/String;)V
  00ae invoke-virtual v12, Ljava/net/URL;->toString()Ljava/lang/String;
  00b4 move-result-object v12
  00b6 if-eqz v4, +005h
  00ba invoke-virtual v4, Ljava/net/HttpURLConnection;->disconnect()V
  00c0 add-int/lit8 v1, v1, 1
  00c4 goto -60h
  00c6 const/16 v13, 200
  00ca if-ne v12, v13, +092h
  00ce invoke-virtual v4, Ljava/net/HttpURLConnection;->getContentType()Ljava/lang/String;
  00d4 move-result-object v12
  00d6 invoke-static v12, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  00dc move-result-object v12
  00de sget-object v13, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  00e2 invoke-virtual v12, v13, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  00e8 move-result-object v12
  00ea const-string v13, "text/html"
  00ee invoke-virtual v12, v13, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  00f4 move-result v12
  00f6 if-nez v12, +074h
  00fa invoke-virtual v4, Ljava/net/HttpURLConnection;->getInputStream()Ljava/io/InputStream;
  0100 move-result-object v12
  0102 invoke-virtual v11, Lcom/personal/aihub/ConverterActivity;->getContentResolver()Landroid/content/ContentResolver;
  0108 move-result-object v13
  010a const-string v1, "w"
  010e invoke-virtual v13, v14, v1, Landroid/content/ContentResolver;->openOutputStream(Landroid/net/Uri; Ljava/lang/String;)Ljava/io/OutputStream;
  0114 move-result-object v13
  0116 if-eqz v13, +045h
  011a const/high16 v1, 65536
  011e new-array v1, v1, [B
  0122 const-wide/16 v5, 0
  0126 move-wide v7, v5
  0128 invoke-virtual v12, v1, Ljava/io/InputStream;->read([B)I
  012e move-result v2
  0130 const/4 v9, -1
  0132 if-eq v2, v9, +019h
  0136 int-to-long v9, v2
  0138 add-long/2addr v7, v9
  013a const-wide v9, 4294967296
  0144 cmp-long v9, v7, v9
  0148 if-gtz v9, +006h
  014c invoke-virtual v13, v1, v0, v2, Ljava/io/OutputStream;->write([B I I)V
  0152 goto -15h
  0154 new-instance v0, Ljava/io/IOException;
  0158 const-string v1, "ECLP exceeds 4 GB"
  015c invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0162 throw v0
  0164 cmp-long v0, v7, v5
  0168 if-eqz v0, +012h
  016c if-eqz v13, +005h
  0170 invoke-virtual v13, Ljava/io/OutputStream;->close()V
  0176 if-eqz v12, +005h
  017a invoke-virtual v12, Ljava/io/InputStream;->close()V
  0180 if-eqz v4, +005h
  0184 invoke-virtual v4, Ljava/net/HttpURLConnection;->disconnect()V
  018a return-void 
  018c new-instance v0, Ljava/io/IOException;
  0190 const-string v1, "Empty download"
  0194 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  019a throw v0
  019c move-exception v0
  019e goto +9h
  01a0 new-instance v0, Ljava/io/IOException;
  01a4 const-string v1, "Cannot write selected file"
  01a8 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01ae throw v0
  01b0 if-eqz v13, +00ah
  01b4 invoke-virtual v13, Ljava/io/OutputStream;->close()V
  01ba goto +5h
  01bc move-exception v13
  01be invoke-virtual v0, v13, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  01c4 throw v0
  01c6 move-exception v13
  01c8 if-eqz v12, +00ah
  01cc invoke-virtual v12, Ljava/io/InputStream;->close()V
  01d2 goto +5h
  01d4 move-exception v12
  01d6 invoke-virtual v13, v12, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  01dc throw v13
  01de new-instance v12, Ljava/io/IOException;
  01e2 const-string v13, "The download link returned a web page. Sign in again or reconvert."
  01e6 invoke-direct v12, v13, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01ec throw v12
  01ee new-instance v13, Ljava/io/IOException;
  01f2 new-instance v0, Ljava/lang/StringBuilder;
  01f6 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  01fc const-string v1, "Eclipse returned HTTP "
  0200 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0206 invoke-virtual v0, v12, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  020c invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0212 move-result-object v12
  0214 invoke-direct v13, v12, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  021a throw v13
  021c move-exception v12
  021e goto +dh
  0220 new-instance v12, Ljava/io/IOException;
  0224 const-string v13, "Unrecognized download destination"
  0228 invoke-direct v12, v13, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  022e throw v12
  0230 move-exception v12
  0232 goto +fh
  0234 move-exception v12
  0236 move-object v4, v3
  0238 invoke-virtual v11, Lcom/personal/aihub/ConverterActivity;->getContentResolver()Landroid/content/ContentResolver;
  023e move-result-object v13
  0240 invoke-virtual v13, v14, v3, v3, Landroid/content/ContentResolver;->delete(Landroid/net/Uri; Ljava/lang/String; [Ljava/lang/String;)I
  0246 goto +4h
  0248 move-exception v12
  024a move-object v3, v4
  024c goto +2h
  024e throw v12
  0250 if-eqz v3, +005h
  0254 invoke-virtual v3, Ljava/net/HttpURLConnection;->disconnect()V
  025a throw v12
  025c new-instance v12, Ljava/io/IOException;
  0260 const-string v13, "Too many redirects"
  0264 invoke-direct v12, v13, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  026a throw v12
.end method

.method lambda$0(Landroid/view/View; Landroid/view/WindowInsets;)Landroid/view/WindowInsets;
  0000 invoke-static Landroid/view/WindowInsets$Type;->systemBars()I
  0006 move-result v0
  0008 invoke-static Landroid/view/WindowInsets$Type;->displayCutout()I
  000e move-result v1
  0010 or-int/2addr v0, v1
  0012 invoke-static Landroid/view/WindowInsets$Type;->ime()I
  0018 move-result v1
  001a or-int/2addr v0, v1
  001c invoke-virtual v5, v0, Landroid/view/WindowInsets;->getInsets(I)Landroid/graphics/Insets;
  0022 move-result-object v0
  0024 iget v1, v0, Landroid/graphics/Insets;->left I
  0028 iget v2, v0, Landroid/graphics/Insets;->top I
  002c iget v3, v0, Landroid/graphics/Insets;->right I
  0030 iget v0, v0, Landroid/graphics/Insets;->bottom I
  0034 invoke-virtual v4, v1, v2, v3, v0, Landroid/view/View;->setPadding(I I I I)V
  003a return-object v5
.end method

.method m0lambda$1$compersonalaihubConverterActivity(Landroid/view/View;)V
  0000 invoke-virtual v0, Lcom/personal/aihub/ConverterActivity;->finish()V
  0006 return-void 
.end method

.method m1lambda$2$compersonalaihubConverterActivity(Landroid/view/View;)V
  0000 iget-object v2, v1, Lcom/personal/aihub/ConverterActivity;->web Landroid/webkit/WebView;
  0004 const-string v0, "https://dokkan-eclipse.com/#convert-eclp"
  0008 invoke-virtual v2, v0, Landroid/webkit/WebView;->loadUrl(Ljava/lang/String;)V
  000e return-void 
.end method

.method m2lambda$3$compersonalaihubConverterActivity(Landroid/view/View;)V
  0000 iget-object v2, v1, Lcom/personal/aihub/ConverterActivity;->web Landroid/webkit/WebView;
  0004 const-string v0, "https://dokkan-eclipse.com/account"
  0008 invoke-virtual v2, v0, Landroid/webkit/WebView;->loadUrl(Ljava/lang/String;)V
  000e return-void 
.end method

.method m3lambda$4$compersonalaihubConverterActivity(Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; J)V
  0000 iget-object v5, v0, Lcom/personal/aihub/ConverterActivity;->downloadUrl Ljava/lang/String;
  0004 if-eqz v5, +00ah
  0008 iget-object v1, v0, Lcom/personal/aihub/ConverterActivity;->status Landroid/widget/TextView;
  000c const-string v2, "Finish saving the current download first."
  0010 invoke-virtual v1, v2, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0016 return-void 
  0018 const/4 v5, 1
  001a invoke-static v1, v5, Lcom/personal/aihub/ConverterActivity;->allowed(Ljava/lang/String; Z)Z
  0020 move-result v5
  0022 if-nez v5, +00ah
  0026 iget-object v1, v0, Lcom/personal/aihub/ConverterActivity;->status Landroid/widget/TextView;
  002a const-string v2, "Unsupported download address. Use the official converter download link."
  002e invoke-virtual v1, v2, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0034 return-void 
  0036 iput-object v1, v0, Lcom/personal/aihub/ConverterActivity;->downloadUrl Ljava/lang/String;
  003a iput-object v2, v0, Lcom/personal/aihub/ConverterActivity;->downloadAgent Ljava/lang/String;
  003e invoke-static v1, v3, v4, Landroid/webkit/URLUtil;->guessFileName(Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0044 move-result-object v1
  0046 const-string v2, "[\\/:*?"<>|\x00-\x1f]"
  004a const-string v3, "_"
  004e invoke-virtual v1, v2, v3, Ljava/lang/String;->replaceAll(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0054 move-result-object v1
  0056 sget-object v2, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  005a invoke-virtual v1, v2, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  0060 move-result-object v2
  0062 const-string v3, ".eclp"
  0066 invoke-virtual v2, v3, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z
  006c move-result v2
  006e if-nez v2, +004h
  0072 const-string v1, "custom-unit.eclp"
  0076 new-instance v2, Landroid/content/Intent;
  007a const-string v3, "android.intent.action.CREATE_DOCUMENT"
  007e invoke-direct v2, v3, Landroid/content/Intent;-><init>(Ljava/lang/String;)V
  0084 const-string v3, "android.intent.category.OPENABLE"
  0088 invoke-virtual v2, v3, Landroid/content/Intent;->addCategory(Ljava/lang/String;)Landroid/content/Intent;
  008e move-result-object v2
  0090 const-string v3, "application/octet-stream"
  0094 invoke-virtual v2, v3, Landroid/content/Intent;->setType(Ljava/lang/String;)Landroid/content/Intent;
  009a move-result-object v2
  009c const-string v3, "android.intent.extra.TITLE"
  00a0 invoke-virtual v2, v3, v1, Landroid/content/Intent;->putExtra(Ljava/lang/String; Ljava/lang/String;)Landroid/content/Intent;
  00a6 move-result-object v1
  00a8 const/16 v2, 701
  00ac invoke-virtual v0, v1, v2, Lcom/personal/aihub/ConverterActivity;->startActivityForResult(Landroid/content/Intent; I)V
  00b2 goto +bh
  00b4 const/4 v1, 0
  00b6 iput-object v1, v0, Lcom/personal/aihub/ConverterActivity;->downloadUrl Ljava/lang/String;
  00ba iget-object v1, v0, Lcom/personal/aihub/ConverterActivity;->status Landroid/widget/TextView;
  00be const-string v2, "Cannot open the system save dialog."
  00c2 invoke-virtual v1, v2, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  00c8 return-void 
.end method

.method m4lambda$5$compersonalaihubConverterActivity(Ljava/lang/String; Ljava/lang/String; Landroid/net/Uri;)V
  0000 invoke-direct v0, v1, v2, v3, Lcom/personal/aihub/ConverterActivity;->download(Ljava/lang/String; Ljava/lang/String; Landroid/net/Uri;)V
  0006 new-instance v1, Lcom/personal/aihub/ConverterActivity$8;
  000a invoke-direct v1, v0, Lcom/personal/aihub/ConverterActivity$8;-><init>(Lcom/personal/aihub/ConverterActivity;)V
  0010 invoke-virtual v0, v1, Lcom/personal/aihub/ConverterActivity;->runOnUiThread(Ljava/lang/Runnable;)V
  0016 goto +ah
  0018 move-exception v1
  001a new-instance v2, Lcom/personal/aihub/ConverterActivity$9;
  001e invoke-direct v2, v0, v1, Lcom/personal/aihub/ConverterActivity$9;-><init>(Lcom/personal/aihub/ConverterActivity; Ljava/lang/Exception;)V
  0024 invoke-virtual v0, v2, Lcom/personal/aihub/ConverterActivity;->runOnUiThread(Ljava/lang/Runnable;)V
  002a return-void 
.end method

.method m5lambda$6$compersonalaihubConverterActivity()V
  0000 iget-object v0, v2, Lcom/personal/aihub/ConverterActivity;->status Landroid/widget/TextView;
  0004 const-string v1, "ECLP saved. You can now import it into Eclipse."
  0008 invoke-virtual v0, v1, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  000e return-void 
.end method

.method m6lambda$7$compersonalaihubConverterActivity(Ljava/lang/Exception;)V
  0000 iget-object v0, v3, Lcom/personal/aihub/ConverterActivity;->status Landroid/widget/TextView;
  0004 new-instance v1, Ljava/lang/StringBuilder;
  0008 const-string v2, "Download failed: "
  000c invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0012 invoke-virtual v4, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  0018 move-result-object v4
  001a invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0020 const-string v4, ". Tap the download link to retry."
  0024 invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  002a invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0030 move-result-object v4
  0032 invoke-virtual v0, v4, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0038 return-void 
.end method

.method onActivityResult(I I Landroid/content/Intent;)V
  0000 invoke-super v2, v3, v4, v5, Landroid/app/Activity;->onActivityResult(I I Landroid/content/Intent;)V
  0006 const/16 v0, 701
  000a if-eq v3, v0, +003h
  000e return-void 
  0010 iget-object v3, v2, Lcom/personal/aihub/ConverterActivity;->downloadUrl Ljava/lang/String;
  0014 iget-object v0, v2, Lcom/personal/aihub/ConverterActivity;->downloadAgent Ljava/lang/String;
  0018 const/4 v1, 0
  001a iput-object v1, v2, Lcom/personal/aihub/ConverterActivity;->downloadUrl Ljava/lang/String;
  001e const/4 v1, -1
  0020 if-ne v4, v1, +022h
  0024 if-eqz v5, +020h
  0028 invoke-virtual v5, Landroid/content/Intent;->getData()Landroid/net/Uri;
  002e move-result-object v4
  0030 if-eqz v4, +01ah
  0034 if-nez v3, +003h
  0038 goto +16h
  003a invoke-virtual v5, Landroid/content/Intent;->getData()Landroid/net/Uri;
  0040 move-result-object v4
  0042 iget-object v5, v2, Lcom/personal/aihub/ConverterActivity;->status Landroid/widget/TextView;
  0046 const-string v1, "Saving converted ECLP…"
  004a invoke-virtual v5, v1, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0050 iget-object v5, v2, Lcom/personal/aihub/ConverterActivity;->worker Ljava/util/concurrent/ExecutorService;
  0054 new-instance v1, Lcom/personal/aihub/ConverterActivity$7;
  0058 invoke-direct v1, v2, v3, v0, v4, Lcom/personal/aihub/ConverterActivity$7;-><init>(Lcom/personal/aihub/ConverterActivity; Ljava/lang/String; Ljava/lang/String; Landroid/net/Uri;)V
  005e invoke-interface v5, v1, Ljava/util/concurrent/ExecutorService;->execute(Ljava/lang/Runnable;)V
  0064 return-void 
.end method

.method onBackPressed()V
  0000 iget-object v0, v1, Lcom/personal/aihub/ConverterActivity;->web Landroid/webkit/WebView;
  0004 if-eqz v0, +00fh
  0008 invoke-virtual v0, Landroid/webkit/WebView;->canGoBack()Z
  000e move-result v0
  0010 if-nez v0, +003h
  0014 goto +7h
  0016 iget-object v0, v1, Lcom/personal/aihub/ConverterActivity;->web Landroid/webkit/WebView;
  001a invoke-virtual v0, Landroid/webkit/WebView;->goBack()V
  0020 goto +4h
  0022 invoke-virtual v1, Lcom/personal/aihub/ConverterActivity;->finish()V
  0028 return-void 
.end method

.method onCreate(Landroid/os/Bundle;)V
  0000 invoke-super v6, v7, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V
  0006 invoke-virtual v6, Lcom/personal/aihub/ConverterActivity;->getIntent()Landroid/content/Intent;
  000c move-result-object v7
  000e const-string v0, "token"
  0012 invoke-virtual v7, v0, Landroid/content/Intent;->getStringExtra(Ljava/lang/String;)Ljava/lang/String;
  0018 move-result-object v7
  001a iput-object v7, v6, Lcom/personal/aihub/ConverterActivity;->token Ljava/lang/String;
  001e invoke-virtual v6, Lcom/personal/aihub/ConverterActivity;->getIntent()Landroid/content/Intent;
  0024 move-result-object v7
  0026 const-string v0, "patch"
  002a invoke-virtual v7, v0, Landroid/content/Intent;->getStringExtra(Ljava/lang/String;)Ljava/lang/String;
  0030 move-result-object v7
  0032 iput-object v7, v6, Lcom/personal/aihub/ConverterActivity;->metadata Ljava/lang/String;
  0036 iget-object v7, v6, Lcom/personal/aihub/ConverterActivity;->token Ljava/lang/String;
  003a if-eqz v7, +10fh
  003e const-string v0, "[a-f0-9-]{36}"
  0042 invoke-virtual v7, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0048 move-result v7
  004a if-nez v7, +004h
  004e goto/16 +105h
  0052 new-instance v7, Ljava/io/File;
  0056 new-instance v0, Ljava/io/File;
  005a new-instance v1, Ljava/io/File;
  005e invoke-virtual v6, Lcom/personal/aihub/ConverterActivity;->getCacheDir()Ljava/io/File;
  0064 move-result-object v2
  0066 const-string v3, "converter"
  006a invoke-direct v1, v2, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0070 iget-object v2, v6, Lcom/personal/aihub/ConverterActivity;->token Ljava/lang/String;
  0074 invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  007a const-string v1, "unit-patch.zip"
  007e invoke-direct v7, v0, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0084 iput-object v7, v6, Lcom/personal/aihub/ConverterActivity;->patch Ljava/io/File;
  0088 invoke-virtual v7, Ljava/io/File;->isFile()Z
  008e move-result v7
  0090 if-nez v7, +006h
  0094 invoke-virtual v6, Lcom/personal/aihub/ConverterActivity;->finish()V
  009a return-void 
  009c new-instance v7, Landroid/widget/LinearLayout;
  00a0 invoke-direct v7, v6, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
  00a6 const/4 v0, 1
  00a8 invoke-virtual v7, v0, Landroid/widget/LinearLayout;->setOrientation(I)V
  00ae const v1, -15391959
  00b4 invoke-virtual v7, v1, Landroid/widget/LinearLayout;->setBackgroundColor(I)V
  00ba invoke-virtual v6, v7, Lcom/personal/aihub/ConverterActivity;->setContentView(Landroid/view/View;)V
  00c0 sget v1, Landroid/os/Build$VERSION;->SDK_INT I
  00c4 const/16 v2, 30
  00c8 const/4 v3, 0
  00ca if-lt v1, v2, +011h
  00ce invoke-virtual v6, Lcom/personal/aihub/ConverterActivity;->getWindow()Landroid/view/Window;
  00d4 move-result-object v1
  00d6 invoke-virtual v1, v3, Landroid/view/Window;->setDecorFitsSystemWindows(Z)V
  00dc new-instance v1, Lcom/personal/aihub/ConverterActivity$1;
  00e0 invoke-direct v1, v6, Lcom/personal/aihub/ConverterActivity$1;-><init>(Lcom/personal/aihub/ConverterActivity;)V
  00e6 invoke-virtual v7, v1, Landroid/widget/LinearLayout;->setOnApplyWindowInsetsListener(Landroid/view/View$OnApplyWindowInsetsListener;)V
  00ec new-instance v1, Landroid/widget/LinearLayout;
  00f0 invoke-direct v1, v6, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
  00f6 new-instance v2, Landroid/widget/Button;
  00fa invoke-direct v2, v6, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
  0100 const-string v4, "Close"
  0104 invoke-virtual v2, v4, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V
  010a new-instance v4, Lcom/personal/aihub/ConverterActivity$2;
  010e invoke-direct v4, v6, Lcom/personal/aihub/ConverterActivity$2;-><init>(Lcom/personal/aihub/ConverterActivity;)V
  0114 invoke-virtual v2, v4, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
  011a invoke-virtual v1, v2, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  0120 new-instance v2, Landroid/widget/Button;
  0124 invoke-direct v2, v6, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
  012a const-string v4, "Converter"
  012e invoke-virtual v2, v4, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V
  0134 new-instance v4, Lcom/personal/aihub/ConverterActivity$3;
  0138 invoke-direct v4, v6, Lcom/personal/aihub/ConverterActivity$3;-><init>(Lcom/personal/aihub/ConverterActivity;)V
  013e invoke-virtual v2, v4, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
  0144 invoke-virtual v1, v2, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  014a new-instance v2, Landroid/widget/Button;
  014e invoke-direct v2, v6, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
  0154 const-string v4, "Sign in"
  0158 invoke-virtual v2, v4, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V
  015e new-instance v4, Lcom/personal/aihub/ConverterActivity$4;
  0162 invoke-direct v4, v6, Lcom/personal/aihub/ConverterActivity$4;-><init>(Lcom/personal/aihub/ConverterActivity;)V
  0168 invoke-virtual v2, v4, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
  016e invoke-virtual v1, v2, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  0174 invoke-virtual v7, v1, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  017a new-instance v1, Landroid/widget/TextView;
  017e invoke-direct v1, v6, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
  0184 iput-object v1, v6, Lcom/personal/aihub/ConverterActivity;->status Landroid/widget/TextView;
  0188 const v2, -1118482
  018e invoke-virtual v1, v2, Landroid/widget/TextView;->setTextColor(I)V
  0194 iget-object v1, v6, Lcom/personal/aihub/ConverterActivity;->status Landroid/widget/TextView;
  0198 const/16 v2, 16
  019c const/16 v4, 8
  01a0 invoke-virtual v1, v2, v4, v2, v4, Landroid/widget/TextView;->setPadding(I I I I)V
  01a6 iget-object v1, v6, Lcom/personal/aihub/ConverterActivity;->status Landroid/widget/TextView;
  01aa const-string v2, "Eclipse online • choose the prepared ZIP, convert, then download."
  01ae invoke-virtual v1, v2, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  01b4 iget-object v1, v6, Lcom/personal/aihub/ConverterActivity;->status Landroid/widget/TextView;
  01b8 invoke-virtual v7, v1, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  01be new-instance v1, Landroid/webkit/WebView;
  01c2 invoke-direct v1, v6, Landroid/webkit/WebView;-><init>(Landroid/content/Context;)V
  01c8 iput-object v1, v6, Lcom/personal/aihub/ConverterActivity;->web Landroid/webkit/WebView;
  01cc new-instance v2, Landroid/widget/LinearLayout$LayoutParams;
  01d0 const/4 v4, -1
  01d2 const/high16 v5, 1065353216
  01d6 invoke-direct v2, v4, v3, v5, Landroid/widget/LinearLayout$LayoutParams;-><init>(I I F)V
  01dc invoke-virtual v7, v1, v2, Landroid/widget/LinearLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  01e2 iget-object v7, v6, Lcom/personal/aihub/ConverterActivity;->web Landroid/webkit/WebView;
  01e6 invoke-virtual v7, Landroid/webkit/WebView;->getSettings()Landroid/webkit/WebSettings;
  01ec move-result-object v7
  01ee invoke-virtual v7, v0, Landroid/webkit/WebSettings;->setJavaScriptEnabled(Z)V
  01f4 invoke-virtual v7, v0, Landroid/webkit/WebSettings;->setDomStorageEnabled(Z)V
  01fa invoke-virtual v7, v3, Landroid/webkit/WebSettings;->setAllowFileAccess(Z)V
  0200 invoke-virtual v7, v0, Landroid/webkit/WebSettings;->setAllowContentAccess(Z)V
  0206 invoke-virtual v7, v0, Landroid/webkit/WebSettings;->setMixedContentMode(I)V
  020c iget-object v7, v6, Lcom/personal/aihub/ConverterActivity;->web Landroid/webkit/WebView;
  0210 new-instance v0, Lcom/personal/aihub/ConverterActivity$AnonymousClass1;
  0214 invoke-direct v0, v6, Lcom/personal/aihub/ConverterActivity$AnonymousClass1;-><init>(Lcom/personal/aihub/ConverterActivity;)V
  021a invoke-virtual v7, v0, Landroid/webkit/WebView;->setWebViewClient(Landroid/webkit/WebViewClient;)V
  0220 iget-object v7, v6, Lcom/personal/aihub/ConverterActivity;->web Landroid/webkit/WebView;
  0224 new-instance v0, Lcom/personal/aihub/ConverterActivity$5;
  0228 invoke-direct v0, v6, Lcom/personal/aihub/ConverterActivity$5;-><init>(Lcom/personal/aihub/ConverterActivity;)V
  022e invoke-virtual v7, v0, Landroid/webkit/WebView;->setWebChromeClient(Landroid/webkit/WebChromeClient;)V
  0234 iget-object v7, v6, Lcom/personal/aihub/ConverterActivity;->web Landroid/webkit/WebView;
  0238 new-instance v0, Lcom/personal/aihub/ConverterActivity$6;
  023c invoke-direct v0, v6, Lcom/personal/aihub/ConverterActivity$6;-><init>(Lcom/personal/aihub/ConverterActivity;)V
  0242 invoke-virtual v7, v0, Landroid/webkit/WebView;->setDownloadListener(Landroid/webkit/DownloadListener;)V
  0248 iget-object v7, v6, Lcom/personal/aihub/ConverterActivity;->web Landroid/webkit/WebView;
  024c const-string v0, "https://dokkan-eclipse.com/#convert-eclp"
  0250 invoke-virtual v7, v0, Landroid/webkit/WebView;->loadUrl(Ljava/lang/String;)V
  0256 return-void 
  0258 invoke-virtual v6, Lcom/personal/aihub/ConverterActivity;->finish()V
  025e return-void 
.end method

.method onDestroy()V
  0000 iget-object v0, v1, Lcom/personal/aihub/ConverterActivity;->worker Ljava/util/concurrent/ExecutorService;
  0004 invoke-interface v0, Ljava/util/concurrent/ExecutorService;->shutdown()V
  000a iget-object v0, v1, Lcom/personal/aihub/ConverterActivity;->web Landroid/webkit/WebView;
  000e if-eqz v0, +00ah
  0012 invoke-virtual v0, Landroid/webkit/WebView;->stopLoading()V
  0018 iget-object v0, v1, Lcom/personal/aihub/ConverterActivity;->web Landroid/webkit/WebView;
  001c invoke-virtual v0, Landroid/webkit/WebView;->destroy()V
  0022 iget-object v0, v1, Lcom/personal/aihub/ConverterActivity;->patch Ljava/io/File;
  0026 if-eqz v0, +00dh
  002a invoke-virtual v1, Lcom/personal/aihub/ConverterActivity;->isFinishing()Z
  0030 move-result v0
  0032 if-eqz v0, +007h
  0036 iget-object v0, v1, Lcom/personal/aihub/ConverterActivity;->patch Ljava/io/File;
  003a invoke-virtual v0, Ljava/io/File;->delete()Z
  0040 invoke-super v1, Landroid/app/Activity;->onDestroy()V
  0046 return-void 
.end method