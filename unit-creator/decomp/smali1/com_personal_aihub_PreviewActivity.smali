.class Lcom/personal/aihub/PreviewActivity;
.super Landroid/app/Activity;
.field bootstrap Lcom/personal/aihub/PreviewBootstrap;
.field bootstrapEpoch J
.field directory Ljava/io/File;
.field recordingExport Lcom/personal/aihub/StageExport;
.field server Lcom/personal/aihub/PreviewServer;
.field startup Lcom/personal/aihub/WebViewStartup;
.field web Landroid/webkit/WebView;

.method <init>()V
  0000 invoke-direct v2, Landroid/app/Activity;-><init>()V
  0006 const-wide/16 v0, -1
  000a iput-wide v0, v2, Lcom/personal/aihub/PreviewActivity;->bootstrapEpoch J
  000e return-void 
.end method

.method access$000(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/WebViewStartup;
  0000 iget-object v0, v0, Lcom/personal/aihub/PreviewActivity;->startup Lcom/personal/aihub/WebViewStartup;
  0004 return-object v0
.end method

.method access$100(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/PreviewServer;
  0000 iget-object v0, v0, Lcom/personal/aihub/PreviewActivity;->server Lcom/personal/aihub/PreviewServer;
  0004 return-object v0
.end method

.method access$202(Lcom/personal/aihub/PreviewActivity; Lcom/personal/aihub/PreviewBootstrap;)Lcom/personal/aihub/PreviewBootstrap;
  0000 iput-object v1, v0, Lcom/personal/aihub/PreviewActivity;->bootstrap Lcom/personal/aihub/PreviewBootstrap;
  0004 return-object v1
.end method

.method access$300(Lcom/personal/aihub/PreviewActivity;)J
  0000 iget-wide v0, v2, Lcom/personal/aihub/PreviewActivity;->bootstrapEpoch J
  0004 return-wide v0
.end method

.method access$302(Lcom/personal/aihub/PreviewActivity; J)J
  0000 iput-wide v1, v0, Lcom/personal/aihub/PreviewActivity;->bootstrapEpoch J
  0004 return-wide v1
.end method

.method access$400(Lcom/personal/aihub/PreviewActivity;)Landroid/webkit/WebView;
  0000 iget-object v0, v0, Lcom/personal/aihub/PreviewActivity;->web Landroid/webkit/WebView;
  0004 return-object v0
.end method

.method access$402(Lcom/personal/aihub/PreviewActivity; Landroid/webkit/WebView;)Landroid/webkit/WebView;
  0000 iput-object v1, v0, Lcom/personal/aihub/PreviewActivity;->web Landroid/webkit/WebView;
  0004 return-object v1
.end method

.method access$500(Lcom/personal/aihub/PreviewActivity; Landroid/webkit/WebView; Lcom/personal/aihub/PreviewBootstrap; J I Ljava/lang/String; Landroid/widget/TextView;)V
  0000 invoke-direct/range v0 ... v7, Lcom/personal/aihub/PreviewActivity;->sendBootstrap(Landroid/webkit/WebView; Lcom/personal/aihub/PreviewBootstrap; J I Ljava/lang/String; Landroid/widget/TextView;)V
  0006 return-void 
.end method

.method lambda$0(Landroid/view/View; Landroid/view/WindowInsets;)Landroid/view/WindowInsets;
  0000 invoke-static Landroid/view/WindowInsets$Type;->systemBars()I
  0006 move-result v0
  0008 invoke-static Landroid/view/WindowInsets$Type;->displayCutout()I
  000e move-result v1
  0010 or-int/2addr v0, v1
  0012 invoke-virtual v5, v0, Landroid/view/WindowInsets;->getInsets(I)Landroid/graphics/Insets;
  0018 move-result-object v0
  001a iget v1, v0, Landroid/graphics/Insets;->left I
  001e iget v2, v0, Landroid/graphics/Insets;->top I
  0022 iget v3, v0, Landroid/graphics/Insets;->right I
  0026 iget v0, v0, Landroid/graphics/Insets;->bottom I
  002a invoke-virtual v4, v1, v2, v3, v0, Landroid/view/View;->setPadding(I I I I)V
  0030 return-object v5
.end method

.method read(Ljava/io/InputStream; I)Ljava/lang/String;
  0000 new-instance v0, Ljava/io/ByteArrayOutputStream;
  0004 invoke-direct v0, Ljava/io/ByteArrayOutputStream;-><init>()V
  000a const/16 v1, 8192
  000e new-array v1, v1, [B
  0012 const/4 v2, 0
  0014 move v3, v2
  0016 invoke-virtual v6, v1, Ljava/io/InputStream;->read([B)I
  001c move-result v4
  001e const/4 v5, -1
  0020 if-eq v4, v5, +011h
  0024 add-int/2addr v3, v4
  0026 if-gt v3, v7, +006h
  002a invoke-virtual v0, v1, v2, v4, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  0030 goto -dh
  0032 new-instance v7, Ljava/io/IOException;
  0036 const-string v1, "Preview too large"
  003a invoke-direct v7, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0040 throw v7
  0042 const-string v7, "UTF-8"
  0046 invoke-virtual v0, v7, Ljava/io/ByteArrayOutputStream;->toString(Ljava/lang/String;)Ljava/lang/String;
  004c move-result-object v7
  004e invoke-virtual v0, Ljava/io/ByteArrayOutputStream;->close()V
  0054 if-eqz v6, +005h
  0058 invoke-virtual v6, Ljava/io/InputStream;->close()V
  005e return-object v7
  0060 move-exception v7
  0062 invoke-virtual v0, Ljava/io/ByteArrayOutputStream;->close()V
  0068 goto +5h
  006a move-exception v0
  006c invoke-virtual v7, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0072 throw v7
  0074 move-exception v7
  0076 if-eqz v6, +00ah
  007a invoke-virtual v6, Ljava/io/InputStream;->close()V
  0080 goto +5h
  0082 move-exception v6
  0084 invoke-virtual v7, v6, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  008a throw v7
.end method

.method sendBootstrap(Landroid/webkit/WebView; Lcom/personal/aihub/PreviewBootstrap; J I Ljava/lang/String; Landroid/widget/TextView;)V
  0000 move-object v9, v13
  0002 move-object v10, v14
  0004 move-object v5, v15
  0006 move/from16 v7, v18
  000a iget-object v0, v9, Lcom/personal/aihub/PreviewActivity;->startup Lcom/personal/aihub/WebViewStartup;
  000e if-eqz v0, +03fh
  0012 move-wide/from16 v3, v16
  0016 invoke-virtual v0, v14, v3, v4, Lcom/personal/aihub/WebViewStartup;->current(Landroid/webkit/WebView; J)Z
  001c move-result v0
  001e if-eqz v0, +037h
  0022 iget-object v0, v9, Lcom/personal/aihub/PreviewActivity;->bootstrap Lcom/personal/aihub/PreviewBootstrap;
  0026 if-eq v0, v5, +003h
  002a goto +31h
  002c if-gez v7, +00ah
  0030 invoke-virtual v15, Lcom/personal/aihub/PreviewBootstrap;->beginScript()Ljava/lang/String;
  0036 move-result-object v0
  0038 move-object/from16 v8, v19
  003c move-object v11, v0
  003e goto +13h
  0040 invoke-virtual v15, Lcom/personal/aihub/PreviewBootstrap;->chunkCount()I
  0046 move-result v0
  0048 if-ge v7, v0, +007h
  004c invoke-virtual v15, v7, Lcom/personal/aihub/PreviewBootstrap;->chunkScript(I)Ljava/lang/String;
  0052 move-result-object v0
  0054 goto -eh
  0056 move-object/from16 v8, v19
  005a invoke-virtual v15, v8, Lcom/personal/aihub/PreviewBootstrap;->mountScript(Ljava/lang/String;)Ljava/lang/String;
  0060 move-result-object v0
  0062 goto -13h
  0064 new-instance v12, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;
  0068 move-object v0, v12
  006a move-object v1, v13
  006c move-object v2, v14
  006e move-wide/from16 v3, v16
  0072 move-object v5, v15
  0074 move-object/from16 v6, v20
  0078 move/from16 v7, v18
  007c move-object/from16 v8, v19
  0080 invoke-direct/range v0 ... v8, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;-><init>(Lcom/personal/aihub/PreviewActivity; Landroid/webkit/WebView; J Lcom/personal/aihub/PreviewBootstrap; Landroid/widget/TextView; I Ljava/lang/String;)V
  0086 invoke-virtual v14, v11, v12, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String; Landroid/webkit/ValueCallback;)V
  008c return-void 
.end method

.method lambda$sendBootstrap$0$com-personal-aihub-PreviewActivity(Landroid/webkit/WebView; J Lcom/personal/aihub/PreviewBootstrap; Landroid/widget/TextView; I Ljava/lang/String; Ljava/lang/String;)V
  0000 move-object v8, v9
  0002 move-object v1, v10
  0004 move-wide v3, v11
  0006 move v0, v15
  0008 iget-object v2, v8, Lcom/personal/aihub/PreviewActivity;->startup Lcom/personal/aihub/WebViewStartup;
  000c invoke-virtual v2, v10, v11, v12, Lcom/personal/aihub/WebViewStartup;->current(Landroid/webkit/WebView; J)Z
  0012 move-result v2
  0014 if-eqz v2, +049h
  0018 iget-object v2, v8, Lcom/personal/aihub/PreviewActivity;->bootstrap Lcom/personal/aihub/PreviewBootstrap;
  001c move-object v5, v13
  001e if-eq v2, v5, +003h
  0022 goto +42h
  0024 const-string v2, "true"
  0028 move-object/from16 v6, v17
  002c invoke-virtual v2, v6, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0032 move-result v2
  0034 if-nez v2, +018h
  0038 invoke-virtual v13, Lcom/personal/aihub/PreviewBootstrap;->cancelScript()Ljava/lang/String;
  003e move-result-object v0
  0040 const/4 v2, 0
  0042 invoke-virtual v10, v0, v2, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String; Landroid/webkit/ValueCallback;)V
  0048 const-string v0, "This preview did not finish opening. Reopen it to try again."
  004c move-object v7, v14
  004e invoke-virtual v14, v0, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0054 iget-object v0, v8, Lcom/personal/aihub/PreviewActivity;->startup Lcom/personal/aihub/WebViewStartup;
  0058 const-string v2, "This animation screen did not finish opening. Try again or copy a startup report."
  005c invoke-virtual v0, v10, v11, v12, v2, Lcom/personal/aihub/WebViewStartup;->failed(Landroid/webkit/WebView; J Ljava/lang/String;)V
  0062 return-void 
  0064 move-object v7, v14
  0066 invoke-virtual v13, Lcom/personal/aihub/PreviewBootstrap;->chunkCount()I
  006c move-result v2
  006e if-ne v0, v2, +00fh
  0072 iget-object v0, v8, Lcom/personal/aihub/PreviewActivity;->startup Lcom/personal/aihub/WebViewStartup;
  0076 const-string v2, "controls-ready"
  007a invoke-virtual v0, v10, v11, v12, v2, Lcom/personal/aihub/WebViewStartup;->stage(Landroid/webkit/WebView; J Ljava/lang/String;)V
  0080 iget-object v0, v8, Lcom/personal/aihub/PreviewActivity;->startup Lcom/personal/aihub/WebViewStartup;
  0084 invoke-virtual v0, v10, v11, v12, Lcom/personal/aihub/WebViewStartup;->ready(Landroid/webkit/WebView; J)V
  008a goto +eh
  008c add-int/lit8 v6, v0, 1
  0090 move-object v0, v9
  0092 move-object v1, v10
  0094 move-object v2, v13
  0096 move-wide v3, v11
  0098 move v5, v6
  009a move-object/from16 v6, v16
  009e move-object v7, v14
  00a0 invoke-direct/range v0 ... v7, Lcom/personal/aihub/PreviewActivity;->sendBootstrap(Landroid/webkit/WebView; Lcom/personal/aihub/PreviewBootstrap; J I Ljava/lang/String; Landroid/widget/TextView;)V
  00a6 return-void 
.end method

.method m26lambda$1$compersonalaihubPreviewActivity(Landroid/view/View;)V
  0000 invoke-virtual v0, Lcom/personal/aihub/PreviewActivity;->finish()V
  0006 return-void 
.end method

.method m27lambda$2$compersonalaihubPreviewActivity(Ljava/lang/String; Landroid/widget/TextView; Landroid/view/View;)V
  0000 const-string v6, "https://play.google.com/store/apps/details?id="
  0004 new-instance v0, Landroid/content/Intent;
  0008 const-string v1, "android.intent.action.VIEW"
  000c new-instance v2, Ljava/lang/StringBuilder;
  0010 invoke-direct v2, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0016 invoke-virtual v2, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  001c invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0022 move-result-object v4
  0024 invoke-static v4, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  002a move-result-object v4
  002c invoke-direct v0, v1, v4, Landroid/content/Intent;-><init>(Ljava/lang/String; Landroid/net/Uri;)V
  0032 invoke-virtual v3, v0, Lcom/personal/aihub/PreviewActivity;->startActivity(Landroid/content/Intent;)V
  0038 goto +6h
  003a const-string v4, "Update Android System WebView or Chrome through your device’s app store."
  003e invoke-virtual v5, v4, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0044 return-void 
.end method

.method m28lambda$3$compersonalaihubPreviewActivity(Landroid/widget/TextView; Landroid/view/View;)V
  0000 new-instance v4, Landroid/content/Intent;
  0004 const-string v0, "android.intent.action.VIEW"
  0008 const-string v1, "https://play.google.com/store/apps/details?id=com.google.android.webview"
  000c invoke-static v1, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  0012 move-result-object v1
  0014 invoke-direct v4, v0, v1, Landroid/content/Intent;-><init>(Ljava/lang/String; Landroid/net/Uri;)V
  001a invoke-virtual v2, v4, Lcom/personal/aihub/PreviewActivity;->startActivity(Landroid/content/Intent;)V
  0020 goto +6h
  0022 const-string v4, "Update Android System WebView or Chrome through your device’s app store, then reopen this preview."
  0026 invoke-virtual v3, v4, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  002c return-void 
.end method

.method m29lambda$4$compersonalaihubPreviewActivity(Landroid/view/View;)V
  0000 invoke-virtual v0, Lcom/personal/aihub/PreviewActivity;->recreate()V
  0006 return-void 
.end method

.method onActivityResult(I I Landroid/content/Intent;)V
  0000 invoke-super v1, v2, v3, v4, Landroid/app/Activity;->onActivityResult(I I Landroid/content/Intent;)V
  0006 iget-object v0, v1, Lcom/personal/aihub/PreviewActivity;->recordingExport Lcom/personal/aihub/StageExport;
  000a if-eqz v0, +005h
  000e invoke-virtual v0, v2, v3, v4, Lcom/personal/aihub/StageExport;->result(I I Landroid/content/Intent;)V
  0014 return-void 
.end method

.method onCreate(Landroid/os/Bundle;)V
  0000 move-object/from16 v12, v30
  0004 const-string v0, "forgeVerifiedMusicPath"
  0008 const-string v13, "effectPacks"
  000c const-string v14, "assets"
  0010 const-string v15, "assetKey"
  0014 const-string v1, "com.android.chrome"
  0018 const-string v10, "sparkingVersion"
  001c const-string v11, "sparkingEffectIds"
  0020 const-string v9, "Could not open this preview: "
  0024 invoke-super/range v30 ... v31, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V
  002a invoke-virtual/range v30, Lcom/personal/aihub/PreviewActivity;->getIntent()Landroid/content/Intent;
  0030 move-result-object v2
  0032 const-string v3, "token"
  0036 invoke-virtual v2, v3, Landroid/content/Intent;->getStringExtra(Ljava/lang/String;)Ljava/lang/String;
  003c move-result-object v2
  003e if-eqz v2, +226h
  0042 const-string v3, "[a-f0-9-]{36}"
  0046 invoke-virtual v2, v3, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  004c move-result v3
  004e if-eqz v3, +21eh
  0052 new-instance v3, Ljava/io/File;
  0056 new-instance v4, Ljava/io/File;
  005a invoke-virtual/range v30, Lcom/personal/aihub/PreviewActivity;->getCacheDir()Ljava/io/File;
  0060 move-result-object v5
  0062 const-string v6, "animation-preview"
  0066 invoke-direct v4, v5, v6, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  006c invoke-direct v3, v4, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0072 iput-object v3, v12, Lcom/personal/aihub/PreviewActivity;->directory Ljava/io/File;
  0076 new-instance v2, Ljava/io/File;
  007a iget-object v3, v12, Lcom/personal/aihub/PreviewActivity;->directory Ljava/io/File;
  007e const-string v4, "request.json"
  0082 invoke-direct v2, v3, v4, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0088 invoke-virtual v2, Ljava/io/File;->isFile()Z
  008e move-result v3
  0090 if-eqz v3, +1fdh
  0094 new-instance v8, Lorg/json/JSONObject;
  0098 new-instance v3, Ljava/io/FileInputStream;
  009c invoke-direct v3, v2, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  00a2 const/high16 v2, 3145728
  00a6 invoke-static v3, v2, Lcom/personal/aihub/PreviewActivity;->read(Ljava/io/InputStream; I)Ljava/lang/String;
  00ac move-result-object v2
  00ae invoke-direct v8, v2, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  00b4 new-instance v7, Landroid/widget/LinearLayout;
  00b8 invoke-direct v7, v12, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
  00be const/4 v6, 1
  00c0 invoke-virtual v7, v6, Landroid/widget/LinearLayout;->setOrientation(I)V
  00c6 const v2, -15391959
  00cc invoke-virtual v7, v2, Landroid/widget/LinearLayout;->setBackgroundColor(I)V
  00d2 invoke-virtual v12, v7, Lcom/personal/aihub/PreviewActivity;->setContentView(Landroid/view/View;)V
  00d8 sget v2, Landroid/os/Build$VERSION;->SDK_INT I
  00dc const/16 v3, 30
  00e0 const/4 v5, 0
  00e2 if-lt v2, v3, +011h
  00e6 invoke-virtual/range v30, Lcom/personal/aihub/PreviewActivity;->getWindow()Landroid/view/Window;
  00ec move-result-object v2
  00ee invoke-virtual v2, v5, Landroid/view/Window;->setDecorFitsSystemWindows(Z)V
  00f4 new-instance v2, Lcom/personal/aihub/PreviewActivity$1;
  00f8 invoke-direct v2, v12, Lcom/personal/aihub/PreviewActivity$1;-><init>(Lcom/personal/aihub/PreviewActivity;)V
  00fe invoke-virtual v7, v2, Landroid/widget/LinearLayout;->setOnApplyWindowInsetsListener(Landroid/view/View$OnApplyWindowInsetsListener;)V
  0104 new-instance v2, Landroid/widget/Button;
  0108 invoke-direct v2, v12, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
  010e const-string v3, "Back to Animation Studio"
  0112 invoke-virtual v2, v3, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V
  0118 new-instance v3, Lcom/personal/aihub/PreviewActivity$2;
  011c invoke-direct v3, v12, Lcom/personal/aihub/PreviewActivity$2;-><init>(Lcom/personal/aihub/PreviewActivity;)V
  0122 invoke-virtual v2, v3, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
  0128 invoke-virtual v7, v2, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  012e new-instance v4, Landroid/widget/TextView;
  0132 invoke-direct v4, v12, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
  0138 const v2, -1118482
  013e invoke-virtual v4, v2, Landroid/widget/TextView;->setTextColor(I)V
  0144 const/16 v2, 8
  0148 const/16 v3, 16
  014c invoke-virtual v4, v3, v2, v3, v2, Landroid/widget/TextView;->setPadding(I I I I)V
  0152 const-string v2, "Animation preview • loaded resources are saved on this device"
  0156 invoke-virtual v4, v2, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  015c invoke-virtual v7, v4, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  0162 invoke-static Landroid/webkit/WebView;->getCurrentWebViewPackage()Landroid/content/pm/PackageInfo;
  0168 move-result-object v2
  016a if-nez v2, +004h
  016e move v3, v5
  0170 goto +fh
  0172 iget-object v3, v2, Landroid/content/pm/PackageInfo;->versionName Ljava/lang/String;
  0176 const-string v6, "\."
  017a invoke-virtual v3, v6, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  0180 move-result-object v3
  0182 aget-object v3, v3, v5
  0186 invoke-static v3, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I
  018c move-result v3
  018e if-lez v3, +02ch
  0192 const/16 v6, 120
  0196 if-ge v3, v6, +028h
  019a const-string v3, "Animation previews need a current Android System WebView or Chrome. Update it, then reopen this preview. You can keep editing and exporting units."
  019e invoke-virtual v4, v3, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  01a4 new-instance v3, Landroid/widget/Button;
  01a8 invoke-direct v3, v12, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
  01ae const-string v6, "Open WebView update page"
  01b2 invoke-virtual v3, v6, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V
  01b8 iget-object v2, v2, Landroid/content/pm/PackageInfo;->packageName Ljava/lang/String;
  01bc invoke-virtual v2, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01c2 move-result v2
  01c4 if-eqz v2, +003h
  01c8 goto +3h
  01ca const-string v1, "com.google.android.webview"
  01ce new-instance v2, Lcom/personal/aihub/PreviewActivity$3;
  01d2 invoke-direct v2, v12, v1, v4, Lcom/personal/aihub/PreviewActivity$3;-><init>(Lcom/personal/aihub/PreviewActivity; Ljava/lang/String; Landroid/widget/TextView;)V
  01d8 invoke-virtual v3, v2, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
  01de invoke-virtual v7, v3, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  01e4 return-void 
  01e6 new-instance v6, Lcom/personal/aihub/PreviewCache;
  01ea new-instance v1, Ljava/io/File;
  01ee invoke-virtual/range v30, Lcom/personal/aihub/PreviewActivity;->getFilesDir()Ljava/io/File;
  01f4 move-result-object v2
  01f6 const-string v3, "forge"
  01fa invoke-direct v1, v2, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0200 invoke-direct v6, v1, Lcom/personal/aihub/PreviewCache;-><init>(Ljava/io/File;)V
  0206 invoke-virtual v8, v11, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  020c move-result v1
  020e const/4 v2, 0
  0210 if-eqz v1, +007h
  0214 invoke-virtual v8, v11, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  021a move-result-object v1
  021c goto +2h
  021e move-object v1, v2
  0220 invoke-static v1, Lcom/personal/aihub/PreviewMetadata;->sparkingEffects(Ljava/lang/Object;)Lorg/json/JSONArray;
  0226 move-result-object v16
  0228 invoke-virtual v8, v10, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  022e move-result v1
  0230 if-eqz v1, +006h
  0234 invoke-virtual v8, v10, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  023a move-result-object v2
  023c invoke-static v2, Lcom/personal/aihub/PreviewMetadata;->normalizeVersion(Ljava/lang/Object;)J
  0242 move-result-wide v17
  0244 new-instance v3, Lcom/personal/aihub/PreviewServer;
  0248 invoke-virtual v8, v15, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  024e move-result-object v19
  0250 invoke-virtual v8, v14, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0256 move-result-object v20
  0258 invoke-virtual v8, v13, Lorg/json/JSONObject;->optJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  025e move-result-object v21
  0260 invoke-virtual v8, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0266 move-result-object v22
  0268 const-string v1, "sourceDatabase"
  026c invoke-virtual v8, v1, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0272 move-result-object v23
  0274 move-object v1, v3
  0276 move-object/from16 v2, v30
  027a move-object/from16 v24, v0
  027e move-object v0, v3
  0280 move-object v3, v6
  0282 move-object/from16 v25, v4
  0286 move-object/from16 v4, v19
  028a move-object/from16 v5, v20
  028e move-object/from16 v19, v6
  0292 move-object/from16 v6, v21
  0296 move-object/from16 v26, v7
  029a move-object/from16 v7, v22
  029e move-object/from16 v20, v13
  02a2 move-object v13, v8
  02a4 move-object/from16 v8, v23
  02a8 move-object/from16 v27, v9
  02ac move-object/from16 v9, v16
  02b0 move-object/from16 v29, v10
  02b4 move-object/from16 v28, v11
  02b8 move-wide/from16 v10, v17
  02bc invoke-direct/range v1 ... v11, Lcom/personal/aihub/PreviewServer;-><init>(Landroid/content/Context; Lcom/personal/aihub/PreviewCache; Ljava/lang/String; Lorg/json/JSONArray; Lorg/json/JSONArray; Ljava/lang/String; Ljava/lang/String; Lorg/json/JSONArray; J)V
  02c2 iput-object v0, v12, Lcom/personal/aihub/PreviewActivity;->server Lcom/personal/aihub/PreviewServer;
  02c6 invoke-virtual v13, v15, Lorg/json/JSONObject;->remove(Ljava/lang/String;)Ljava/lang/Object;
  02cc invoke-virtual v13, v14, Lorg/json/JSONObject;->remove(Ljava/lang/String;)Ljava/lang/Object;
  02d2 move-object/from16 v0, v20
  02d6 invoke-virtual v13, v0, Lorg/json/JSONObject;->remove(Ljava/lang/String;)Ljava/lang/Object;
  02dc move-object/from16 v0, v28
  02e0 invoke-virtual v13, v0, Lorg/json/JSONObject;->remove(Ljava/lang/String;)Ljava/lang/Object;
  02e6 move-object/from16 v0, v29
  02ea invoke-virtual v13, v0, Lorg/json/JSONObject;->remove(Ljava/lang/String;)Ljava/lang/Object;
  02f0 move-object/from16 v0, v24
  02f4 invoke-virtual v13, v0, Lorg/json/JSONObject;->remove(Ljava/lang/String;)Ljava/lang/Object;
  02fa const-string v0, "bgmContext"
  02fe iget-object v1, v12, Lcom/personal/aihub/PreviewActivity;->server Lcom/personal/aihub/PreviewServer;
  0302 invoke-virtual v1, Lcom/personal/aihub/PreviewServer;->bgmContext()Lorg/json/JSONObject;
  0308 move-result-object v1
  030a invoke-virtual v13, v0, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0310 new-instance v0, Landroid/webkit/WebView;
  0314 invoke-direct v0, v12, Landroid/webkit/WebView;-><init>(Landroid/content/Context;)V
  031a iput-object v0, v12, Lcom/personal/aihub/PreviewActivity;->web Landroid/webkit/WebView;
  031e new-instance v0, Landroid/widget/FrameLayout;
  0322 invoke-direct v0, v12, Landroid/widget/FrameLayout;-><init>(Landroid/content/Context;)V
  0328 new-instance v1, Landroid/widget/LinearLayout$LayoutParams;
  032c const/high16 v2, 1065353216
  0330 const/4 v3, -1
  0332 const/4 v4, 0
  0334 invoke-direct v1, v3, v4, v2, Landroid/widget/LinearLayout$LayoutParams;-><init>(I I F)V
  033a move-object/from16 v5, v26
  033e invoke-virtual v5, v0, v1, Landroid/widget/LinearLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  0344 iget-object v1, v12, Lcom/personal/aihub/PreviewActivity;->web Landroid/webkit/WebView;
  0348 new-instance v2, Landroid/widget/FrameLayout$LayoutParams;
  034c invoke-direct v2, v3, v3, Landroid/widget/FrameLayout$LayoutParams;-><init>(I I)V
  0352 invoke-virtual v0, v1, v2, Landroid/widget/FrameLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  0358 new-instance v1, Lcom/personal/aihub/WebViewStartup;
  035c const-string v2, "animation preview"
  0360 new-instance v3, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda0;
  0364 invoke-direct v3, v12, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda0;-><init>(Lcom/personal/aihub/PreviewActivity;)V
  036a invoke-direct v1, v12, v0, v2, v3, Lcom/personal/aihub/WebViewStartup;-><init>(Landroid/app/Activity; Landroid/widget/FrameLayout; Ljava/lang/String; Ljava/lang/Runnable;)V
  0370 iput-object v1, v12, Lcom/personal/aihub/PreviewActivity;->startup Lcom/personal/aihub/WebViewStartup;
  0374 iget-object v0, v12, Lcom/personal/aihub/PreviewActivity;->web Landroid/webkit/WebView;
  0378 invoke-virtual v1, v0, Lcom/personal/aihub/WebViewStartup;->begin(Landroid/webkit/WebView;)J
  037e iget-object v0, v12, Lcom/personal/aihub/PreviewActivity;->web Landroid/webkit/WebView;
  0382 invoke-virtual v0, Landroid/webkit/WebView;->getSettings()Landroid/webkit/WebSettings;
  0388 move-result-object v0
  038a const/4 v1, 1
  038c invoke-virtual v0, v1, Landroid/webkit/WebSettings;->setJavaScriptEnabled(Z)V
  0392 invoke-virtual v0, v1, Landroid/webkit/WebSettings;->setDomStorageEnabled(Z)V
  0398 invoke-virtual v0, v4, Landroid/webkit/WebSettings;->setAllowFileAccess(Z)V
  039e invoke-virtual v0, v4, Landroid/webkit/WebSettings;->setAllowContentAccess(Z)V
  03a4 invoke-virtual v0, v4, Landroid/webkit/WebSettings;->setMediaPlaybackRequiresUserGesture(Z)V
  03aa invoke-virtual v0, v1, Landroid/webkit/WebSettings;->setMixedContentMode(I)V
  03b0 iget-object v0, v12, Lcom/personal/aihub/PreviewActivity;->server Lcom/personal/aihub/PreviewServer;
  03b4 new-instance v1, Lcom/personal/aihub/StageCapture;
  03b8 iget-object v2, v12, Lcom/personal/aihub/PreviewActivity;->web Landroid/webkit/WebView;
  03bc iget-object v3, v0, Lcom/personal/aihub/PreviewServer;->origin Ljava/lang/String;
  03c0 invoke-direct v1, v12, v2, v3, Lcom/personal/aihub/StageCapture;-><init>(Landroid/app/Activity; Landroid/webkit/WebView; Ljava/lang/String;)V
  03c6 invoke-virtual v0, v1, Lcom/personal/aihub/PreviewServer;->stageCapture(Lcom/personal/aihub/StageCapture;)V
  03cc new-instance v0, Lcom/personal/aihub/StageExport;
  03d0 invoke-direct v0, v12, Lcom/personal/aihub/StageExport;-><init>(Landroid/app/Activity;)V
  03d6 iput-object v0, v12, Lcom/personal/aihub/PreviewActivity;->recordingExport Lcom/personal/aihub/StageExport;
  03da iget-object v1, v12, Lcom/personal/aihub/PreviewActivity;->server Lcom/personal/aihub/PreviewServer;
  03de invoke-virtual v1, v0, Lcom/personal/aihub/PreviewServer;->stageExport(Lcom/personal/aihub/StageExport;)V
  03e4 iget-object v0, v12, Lcom/personal/aihub/PreviewActivity;->web Landroid/webkit/WebView;
  03e8 new-instance v1, Landroid/webkit/WebChromeClient;
  03ec invoke-direct v1, Landroid/webkit/WebChromeClient;-><init>()V
  03f2 invoke-virtual v0, v1, Landroid/webkit/WebView;->setWebChromeClient(Landroid/webkit/WebChromeClient;)V
  03f8 iget-object v0, v12, Lcom/personal/aihub/PreviewActivity;->web Landroid/webkit/WebView;
  03fc new-instance v7, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;
  0400 move-object v1, v7
  0402 move-object/from16 v2, v30
  0406 move-object/from16 v3, v19
  040a move-object/from16 v4, v25
  040e move-object v6, v13
  0410 invoke-direct/range v1 ... v6, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;-><init>(Lcom/personal/aihub/PreviewActivity; Lcom/personal/aihub/PreviewCache; Landroid/widget/TextView; Landroid/widget/LinearLayout; Lorg/json/JSONObject;)V
  0416 invoke-virtual v0, v7, Landroid/webkit/WebView;->setWebViewClient(Landroid/webkit/WebViewClient;)V
  041c iget-object v0, v12, Lcom/personal/aihub/PreviewActivity;->web Landroid/webkit/WebView;
  0420 iget-object v1, v12, Lcom/personal/aihub/PreviewActivity;->server Lcom/personal/aihub/PreviewServer;
  0424 const-string v2, "mode"
  0428 const-string v3, "lua"
  042c invoke-virtual v13, v2, v3, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0432 move-result-object v2
  0434 invoke-virtual v1, v2, Lcom/personal/aihub/PreviewServer;->entryURL(Ljava/lang/String;)Ljava/lang/String;
  043a move-result-object v1
  043c invoke-virtual v0, v1, Landroid/webkit/WebView;->loadUrl(Ljava/lang/String;)V
  0442 return-void 
  0444 move-exception v0
  0446 goto +6h
  0448 move-exception v0
  044a move-object/from16 v25, v4
  044e move-object/from16 v27, v9
  0452 new-instance v1, Ljava/lang/StringBuilder;
  0456 move-object/from16 v2, v27
  045a invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0460 invoke-virtual v0, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
  0466 move-result-object v0
  0468 invoke-virtual v1, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  046e invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0474 move-result-object v0
  0476 move-object/from16 v1, v25
  047a invoke-virtual v1, v0, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0480 return-void 
  0482 invoke-virtual/range v30, Lcom/personal/aihub/PreviewActivity;->finish()V
  0488 return-void 
  048a invoke-virtual/range v30, Lcom/personal/aihub/PreviewActivity;->finish()V
  0490 return-void 
.end method

.method onDestroy()V
  0000 iget-object v0, v3, Lcom/personal/aihub/PreviewActivity;->startup Lcom/personal/aihub/WebViewStartup;
  0004 if-eqz v0, +005h
  0008 invoke-virtual v0, Lcom/personal/aihub/WebViewStartup;->close()V
  000e const/4 v0, 0
  0010 iput-object v0, v3, Lcom/personal/aihub/PreviewActivity;->bootstrap Lcom/personal/aihub/PreviewBootstrap;
  0014 iget-object v0, v3, Lcom/personal/aihub/PreviewActivity;->web Landroid/webkit/WebView;
  0018 if-eqz v0, +00ah
  001c invoke-virtual v0, Landroid/webkit/WebView;->stopLoading()V
  0022 iget-object v0, v3, Lcom/personal/aihub/PreviewActivity;->web Landroid/webkit/WebView;
  0026 invoke-virtual v0, Landroid/webkit/WebView;->destroy()V
  002c invoke-virtual v3, Lcom/personal/aihub/PreviewActivity;->stopServer()V
  0032 invoke-virtual v3, Lcom/personal/aihub/PreviewActivity;->isFinishing()Z
  0038 move-result v0
  003a if-eqz v0, +017h
  003e iget-object v0, v3, Lcom/personal/aihub/PreviewActivity;->directory Ljava/io/File;
  0042 if-eqz v0, +013h
  0046 new-instance v0, Ljava/io/File;
  004a iget-object v1, v3, Lcom/personal/aihub/PreviewActivity;->directory Ljava/io/File;
  004e const-string v2, "request.json"
  0052 invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0058 invoke-virtual v0, Ljava/io/File;->delete()Z
  005e iget-object v0, v3, Lcom/personal/aihub/PreviewActivity;->directory Ljava/io/File;
  0062 invoke-virtual v0, Ljava/io/File;->delete()Z
  0068 invoke-super v3, Landroid/app/Activity;->onDestroy()V
  006e return-void 
.end method

.method stopServer()V
  0000 iget-object v0, v5, Lcom/personal/aihub/PreviewActivity;->server Lcom/personal/aihub/PreviewServer;
  0004 if-eqz v0, +02ch
  0008 iget-object v0, v0, Lcom/personal/aihub/PreviewServer;->origin Ljava/lang/String;
  000c iget-object v1, v5, Lcom/personal/aihub/PreviewActivity;->server Lcom/personal/aihub/PreviewServer;
  0010 iget-object v1, v1, Lcom/personal/aihub/PreviewServer;->cookie Ljava/lang/String;
  0014 iget-object v2, v5, Lcom/personal/aihub/PreviewActivity;->server Lcom/personal/aihub/PreviewServer;
  0018 invoke-virtual v2, Lcom/personal/aihub/PreviewServer;->close()V
  001e const/4 v2, 0
  0020 iput-object v2, v5, Lcom/personal/aihub/PreviewActivity;->server Lcom/personal/aihub/PreviewServer;
  0024 invoke-static Landroid/webkit/CookieManager;->getInstance()Landroid/webkit/CookieManager;
  002a move-result-object v3
  002c new-instance v4, Ljava/lang/StringBuilder;
  0030 invoke-direct v4, Ljava/lang/StringBuilder;-><init>()V
  0036 invoke-static v1, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  003c move-result-object v1
  003e invoke-virtual v4, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0044 const-string v1, "; Path=/; Max-Age=0; HttpOnly; SameSite=Strict"
  0048 invoke-virtual v4, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  004e invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0054 move-result-object v1
  0056 invoke-virtual v3, v0, v1, v2, Landroid/webkit/CookieManager;->setCookie(Ljava/lang/String; Ljava/lang/String; Landroid/webkit/ValueCallback;)V
  005c return-void 
.end method

.method unreliableRuntime(Landroid/widget/LinearLayout; Landroid/widget/TextView; Landroid/webkit/WebView;)V
  0000 iget-object v0, v2, Lcom/personal/aihub/PreviewActivity;->startup Lcom/personal/aihub/WebViewStartup;
  0004 if-eqz v0, +005h
  0008 invoke-virtual v0, Lcom/personal/aihub/WebViewStartup;->close()V
  000e const/4 v0, 0
  0010 iput-object v0, v2, Lcom/personal/aihub/PreviewActivity;->bootstrap Lcom/personal/aihub/PreviewBootstrap;
  0014 invoke-virtual v5, Landroid/webkit/WebView;->getParent()Landroid/view/ViewParent;
  001a move-result-object v1
  001c instance-of v1, v1, Landroid/view/ViewGroup;
  0020 if-eqz v1, +00eh
  0024 invoke-virtual v5, Landroid/webkit/WebView;->getParent()Landroid/view/ViewParent;
  002a move-result-object v1
  002c check-cast v1, Landroid/view/ViewGroup;
  0030 invoke-virtual v1, v5, Landroid/view/ViewGroup;->removeView(Landroid/view/View;)V
  0036 invoke-virtual v3, v1, Landroid/widget/LinearLayout;->removeView(Landroid/view/View;)V
  003c iput-object v0, v2, Lcom/personal/aihub/PreviewActivity;->web Landroid/webkit/WebView;
  0040 invoke-virtual v5, Landroid/webkit/WebView;->stopLoading()V
  0046 invoke-virtual v5, Landroid/webkit/WebView;->destroy()V
  004c invoke-virtual v2, Lcom/personal/aihub/PreviewActivity;->stopServer()V
  0052 const-string v5, "This device could not run animation previews reliably. Update Android System WebView or Chrome, then restart the device and reopen this preview. If you use an Android emulator, update the emulator too. Your saved creations and imported files are still on this device."
  0056 invoke-virtual v4, v5, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  005c new-instance v5, Landroid/widget/Button;
  0060 invoke-direct v5, v2, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
  0066 const-string v0, "Open WebView update page"
  006a invoke-virtual v5, v0, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V
  0070 new-instance v0, Lcom/personal/aihub/PreviewActivity$4;
  0074 invoke-direct v0, v2, v4, Lcom/personal/aihub/PreviewActivity$4;-><init>(Lcom/personal/aihub/PreviewActivity; Landroid/widget/TextView;)V
  007a invoke-virtual v5, v0, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
  0080 invoke-virtual v3, v5, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  0086 new-instance v4, Landroid/widget/Button;
  008a invoke-direct v4, v2, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
  0090 const-string v5, "Reopen animation preview"
  0094 invoke-virtual v4, v5, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V
  009a new-instance v5, Lcom/personal/aihub/PreviewActivity$5;
  009e invoke-direct v5, v2, Lcom/personal/aihub/PreviewActivity$5;-><init>(Lcom/personal/aihub/PreviewActivity;)V
  00a4 invoke-virtual v4, v5, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
  00aa invoke-virtual v3, v4, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  00b0 return-void 
.end method