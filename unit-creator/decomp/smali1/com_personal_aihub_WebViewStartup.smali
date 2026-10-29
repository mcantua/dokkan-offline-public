.class Lcom/personal/aihub/WebViewStartup;
.super Ljava/lang/Object;
.field NOTICE_AFTER_MS J
.field activity Landroid/app/Activity;
.field closed Z
.field content Landroid/widget/LinearLayout;
.field epoch J
.field handler Landroid/os/Handler;
.field message Landroid/widget/TextView;
.field overlay Landroid/widget/ScrollView;
.field phase Ljava/lang/String;
.field probingWorkspace Z
.field reportButton Landroid/widget/Button;
.field retryButton Landroid/widget/Button;
.field screen Ljava/lang/String;
.field spinner Landroid/widget/ProgressBar;
.field stage Ljava/lang/String;
.field started J
.field title Landroid/widget/TextView;
.field waitButton Landroid/widget/Button;
.field web Landroid/webkit/WebView;

.method $r8$lambda$Nr7AFoG44zQXMBr3YK0Yr9GH898(Lcom/personal/aihub/WebViewStartup;)V
  0000 invoke-direct v0, Lcom/personal/aihub/WebViewStartup;->copyReport()V
  0006 return-void 
.end method

.method <init>(Landroid/app/Activity; Landroid/widget/FrameLayout; Ljava/lang/String; Ljava/lang/Runnable;)V
  0000 invoke-direct v7, Ljava/lang/Object;-><init>()V
  0006 new-instance v0, Landroid/os/Handler;
  000a invoke-static Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;
  0010 move-result-object v1
  0012 invoke-direct v0, v1, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V
  0018 iput-object v0, v7, Lcom/personal/aihub/WebViewStartup;->handler Landroid/os/Handler;
  001c const-string v0, "created"
  0020 iput-object v0, v7, Lcom/personal/aihub/WebViewStartup;->phase Ljava/lang/String;
  0024 iput-object v0, v7, Lcom/personal/aihub/WebViewStartup;->stage Ljava/lang/String;
  0028 iput-object v8, v7, Lcom/personal/aihub/WebViewStartup;->activity Landroid/app/Activity;
  002c iput-object v10, v7, Lcom/personal/aihub/WebViewStartup;->screen Ljava/lang/String;
  0030 new-instance v0, Landroid/widget/ScrollView;
  0034 invoke-direct v0, v8, Landroid/widget/ScrollView;-><init>(Landroid/content/Context;)V
  003a iput-object v0, v7, Lcom/personal/aihub/WebViewStartup;->overlay Landroid/widget/ScrollView;
  003e const/4 v1, 1
  0040 invoke-virtual v0, v1, Landroid/widget/ScrollView;->setFillViewport(Z)V
  0046 new-instance v2, Landroid/widget/LinearLayout;
  004a invoke-direct v2, v8, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
  0050 iput-object v2, v7, Lcom/personal/aihub/WebViewStartup;->content Landroid/widget/LinearLayout;
  0054 invoke-virtual v2, v1, Landroid/widget/LinearLayout;->setOrientation(I)V
  005a const/16 v3, 16
  005e invoke-virtual v2, v3, Landroid/widget/LinearLayout;->setGravity(I)V
  0064 invoke-virtual v0, v2, Landroid/widget/ScrollView;->addView(Landroid/view/View;)V
  006a invoke-virtual v8, Landroid/app/Activity;->getResources()Landroid/content/res/Resources;
  0070 move-result-object v3
  0072 invoke-virtual v3, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
  0078 move-result-object v3
  007a iget v3, v3, Landroid/util/DisplayMetrics;->density F
  007e const/high16 v4, 1103101952
  0082 mul-float/2addr v3, v4
  0084 float-to-int v3, v3
  0086 invoke-virtual v2, v3, v3, v3, v3, Landroid/widget/LinearLayout;->setPadding(I I I I)V
  008c const v5, -15654870
  0092 invoke-virtual v0, v5, Landroid/widget/ScrollView;->setBackgroundColor(I)V
  0098 new-instance v5, Landroid/widget/ProgressBar;
  009c invoke-direct v5, v8, Landroid/widget/ProgressBar;-><init>(Landroid/content/Context;)V
  00a2 iput-object v5, v7, Lcom/personal/aihub/WebViewStartup;->spinner Landroid/widget/ProgressBar;
  00a6 invoke-virtual v2, v5, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  00ac new-instance v5, Landroid/widget/TextView;
  00b0 invoke-direct v5, v8, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
  00b6 iput-object v5, v7, Lcom/personal/aihub/WebViewStartup;->title Landroid/widget/TextView;
  00ba const v6, -789003
  00c0 invoke-virtual v5, v6, Landroid/widget/TextView;->setTextColor(I)V
  00c6 invoke-virtual v5, v4, Landroid/widget/TextView;->setTextSize(F)V
  00cc invoke-virtual v2, v5, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  00d2 new-instance v4, Landroid/widget/TextView;
  00d6 invoke-direct v4, v8, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
  00dc iput-object v4, v7, Lcom/personal/aihub/WebViewStartup;->message Landroid/widget/TextView;
  00e0 const v8, -3418405
  00e6 invoke-virtual v4, v8, Landroid/widget/TextView;->setTextColor(I)V
  00ec const/high16 v8, 1098907648
  00f0 invoke-virtual v4, v8, Landroid/widget/TextView;->setTextSize(F)V
  00f6 div-int/lit8 v3, v3, 2
  00fa const/4 v8, 0
  00fc invoke-virtual v4, v8, v3, v8, v3, Landroid/widget/TextView;->setPadding(I I I I)V
  0102 invoke-virtual v4, v1, Landroid/widget/TextView;->setAccessibilityLiveRegion(I)V
  0108 invoke-virtual v2, v4, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  010e new-instance v8, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda2;
  0112 invoke-direct v8, v7, v11, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda2;-><init>(Lcom/personal/aihub/WebViewStartup; Ljava/lang/Runnable;)V
  0118 const-string v11, "Try again"
  011c invoke-direct v7, v11, v8, Lcom/personal/aihub/WebViewStartup;->button(Ljava/lang/String; Ljava/lang/Runnable;)Landroid/widget/Button;
  0122 move-result-object v8
  0124 iput-object v8, v7, Lcom/personal/aihub/WebViewStartup;->retryButton Landroid/widget/Button;
  0128 new-instance v8, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda3;
  012c invoke-direct v8, v7, v10, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda3;-><init>(Lcom/personal/aihub/WebViewStartup; Ljava/lang/String;)V
  0132 const-string v10, "Keep waiting"
  0136 invoke-direct v7, v10, v8, Lcom/personal/aihub/WebViewStartup;->button(Ljava/lang/String; Ljava/lang/Runnable;)Landroid/widget/Button;
  013c move-result-object v8
  013e iput-object v8, v7, Lcom/personal/aihub/WebViewStartup;->waitButton Landroid/widget/Button;
  0142 new-instance v8, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda4;
  0146 invoke-direct v8, v7, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda4;-><init>(Lcom/personal/aihub/WebViewStartup;)V
  014c const-string v10, "Copy startup report"
  0150 invoke-direct v7, v10, v8, Lcom/personal/aihub/WebViewStartup;->button(Ljava/lang/String; Ljava/lang/Runnable;)Landroid/widget/Button;
  0156 move-result-object v8
  0158 iput-object v8, v7, Lcom/personal/aihub/WebViewStartup;->reportButton Landroid/widget/Button;
  015c new-instance v8, Landroid/widget/FrameLayout$LayoutParams;
  0160 const/4 v10, -1
  0162 invoke-direct v8, v10, v10, Landroid/widget/FrameLayout$LayoutParams;-><init>(I I)V
  0168 invoke-virtual v9, v0, v8, Landroid/widget/FrameLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  016e const/16 v8, 8
  0172 invoke-virtual v0, v8, Landroid/widget/ScrollView;->setVisibility(I)V
  0178 return-void 
.end method

.method button(Ljava/lang/String; Ljava/lang/Runnable;)Landroid/widget/Button;
  0000 new-instance v0, Landroid/widget/Button;
  0004 iget-object v1, v3, Lcom/personal/aihub/WebViewStartup;->activity Landroid/app/Activity;
  0008 invoke-direct v0, v1, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
  000e invoke-virtual v0, v4, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V
  0014 new-instance v4, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda6;
  0018 invoke-direct v4, v5, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda6;-><init>(Ljava/lang/Runnable;)V
  001e invoke-virtual v0, v4, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
  0024 iget-object v4, v3, Lcom/personal/aihub/WebViewStartup;->content Landroid/widget/LinearLayout;
  0028 new-instance v5, Landroid/widget/LinearLayout$LayoutParams;
  002c const/4 v1, -1
  002e const/4 v2, -2
  0030 invoke-direct v5, v1, v2, Landroid/widget/LinearLayout$LayoutParams;-><init>(I I)V
  0036 invoke-virtual v4, v0, v5, Landroid/widget/LinearLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  003c return-object v0
.end method

.method copyReport()V
  0000 iget-object v0, v4, Lcom/personal/aihub/WebViewStartup;->activity Landroid/app/Activity;
  0004 const-string v1, "clipboard"
  0008 invoke-virtual v0, v1, Landroid/app/Activity;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;
  000e move-result-object v0
  0010 check-cast v0, Landroid/content/ClipboardManager;
  0014 const-string v1, "Dokkan Unit Creator startup"
  0018 invoke-virtual v4, Lcom/personal/aihub/WebViewStartup;->diagnostics()Lorg/json/JSONObject;
  001e move-result-object v2
  0020 const/4 v3, 2
  0022 invoke-virtual v2, v3, Lorg/json/JSONObject;->toString(I)Ljava/lang/String;
  0028 move-result-object v2
  002a invoke-static v1, v2, Landroid/content/ClipData;->newPlainText(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Landroid/content/ClipData;
  0030 move-result-object v1
  0032 invoke-virtual v0, v1, Landroid/content/ClipboardManager;->setPrimaryClip(Landroid/content/ClipData;)V
  0038 iget-object v0, v4, Lcom/personal/aihub/WebViewStartup;->message Landroid/widget/TextView;
  003c const-string v1, "Startup report copied. You can paste it into your support conversation. It contains device and startup details, without unit data, account details, or preview links."
  0040 invoke-virtual v0, v1, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0046 goto +8h
  0048 iget-object v0, v4, Lcom/personal/aihub/WebViewStartup;->message Landroid/widget/TextView;
  004c const-string v1, "Could not copy the report. You can still retry or return to the previous screen."
  0050 invoke-virtual v0, v1, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0056 return-void 
.end method

.method disableRetry()V
  0000 iget-object v0, v2, Lcom/personal/aihub/WebViewStartup;->retryButton Landroid/widget/Button;
  0004 const/4 v1, 0
  0006 invoke-virtual v0, v1, Landroid/widget/Button;->setEnabled(Z)V
  000c return-void 
.end method

.method finish(Landroid/webkit/WebView; J Ljava/lang/String;)V
  0000 invoke-virtual v0, v1, v2, v3, Lcom/personal/aihub/WebViewStartup;->current(Landroid/webkit/WebView; J)Z
  0006 move-result v1
  0008 if-nez v1, +003h
  000c return-void 
  000e iget-object v1, v0, Lcom/personal/aihub/WebViewStartup;->handler Landroid/os/Handler;
  0012 const/4 v2, 0
  0014 invoke-virtual v1, v2, Landroid/os/Handler;->removeCallbacksAndMessages(Ljava/lang/Object;)V
  001a iput-object v4, v0, Lcom/personal/aihub/WebViewStartup;->phase Ljava/lang/String;
  001e iget-object v1, v0, Lcom/personal/aihub/WebViewStartup;->overlay Landroid/widget/ScrollView;
  0022 const/16 v2, 8
  0026 invoke-virtual v1, v2, Landroid/widget/ScrollView;->setVisibility(I)V
  002c return-void 
.end method

.method lambda$button$2(Ljava/lang/Runnable; Landroid/view/View;)V
  0000 invoke-interface v0, Ljava/lang/Runnable;->run()V
  0006 return-void 
.end method

.method probeWorkspace(Landroid/webkit/WebView; J)V
  0000 invoke-virtual v1, v2, v3, v4, Lcom/personal/aihub/WebViewStartup;->current(Landroid/webkit/WebView; J)Z
  0006 move-result v0
  0008 if-nez v0, +003h
  000c return-void 
  000e new-instance v0, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda0;
  0012 invoke-direct v0, v1, v2, v3, v4, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda0;-><init>(Lcom/personal/aihub/WebViewStartup; Landroid/webkit/WebView; J)V
  0018 const-string v3, "String(window.__forgeWorkspaceStartup || 'loading')"
  001c invoke-virtual v2, v3, v0, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String; Landroid/webkit/ValueCallback;)V
  0022 return-void 
.end method

.method slow(Ljava/lang/String;)V
  0000 const-string v0, "not-responding"
  0004 iput-object v0, v2, Lcom/personal/aihub/WebViewStartup;->phase Ljava/lang/String;
  0008 iget-object v0, v2, Lcom/personal/aihub/WebViewStartup;->title Landroid/widget/TextView;
  000c const-string v1, "Taking longer than usual"
  0010 invoke-virtual v0, v1, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0016 iget-object v0, v2, Lcom/personal/aihub/WebViewStartup;->message Landroid/widget/TextView;
  001a invoke-virtual v0, v3, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0020 iget-object v3, v2, Lcom/personal/aihub/WebViewStartup;->spinner Landroid/widget/ProgressBar;
  0024 const/16 v0, 8
  0028 invoke-virtual v3, v0, Landroid/widget/ProgressBar;->setVisibility(I)V
  002e iget-object v3, v2, Lcom/personal/aihub/WebViewStartup;->retryButton Landroid/widget/Button;
  0032 const/4 v0, 0
  0034 invoke-virtual v3, v0, Landroid/widget/Button;->setVisibility(I)V
  003a iget-object v3, v2, Lcom/personal/aihub/WebViewStartup;->waitButton Landroid/widget/Button;
  003e invoke-virtual v3, v0, Landroid/widget/Button;->setVisibility(I)V
  0044 iget-object v3, v2, Lcom/personal/aihub/WebViewStartup;->reportButton Landroid/widget/Button;
  0048 invoke-virtual v3, v0, Landroid/widget/Button;->setVisibility(I)V
  004e return-void 
.end method

.method begin(Landroid/webkit/WebView;)J
  0000 iget-boolean v0, v6, Lcom/personal/aihub/WebViewStartup;->closed Z
  0004 if-eqz v0, +005h
  0008 const-wide/16 v0, -1
  000c return-wide v0
  000e iget-object v0, v6, Lcom/personal/aihub/WebViewStartup;->handler Landroid/os/Handler;
  0012 const/4 v1, 0
  0014 invoke-virtual v0, v1, Landroid/os/Handler;->removeCallbacksAndMessages(Ljava/lang/Object;)V
  001a iput-object v7, v6, Lcom/personal/aihub/WebViewStartup;->web Landroid/webkit/WebView;
  001e iget-wide v0, v6, Lcom/personal/aihub/WebViewStartup;->epoch J
  0022 const-wide/16 v2, 1
  0026 add-long/2addr v0, v2
  0028 iput-wide v0, v6, Lcom/personal/aihub/WebViewStartup;->epoch J
  002c invoke-static Landroid/os/SystemClock;->elapsedRealtime()J
  0032 move-result-wide v0
  0034 iput-wide v0, v6, Lcom/personal/aihub/WebViewStartup;->started J
  0038 const-string v0, "loading"
  003c iput-object v0, v6, Lcom/personal/aihub/WebViewStartup;->phase Ljava/lang/String;
  0040 const-string v0, "navigation"
  0044 iput-object v0, v6, Lcom/personal/aihub/WebViewStartup;->stage Ljava/lang/String;
  0048 const/4 v0, 0
  004a iput-boolean v0, v6, Lcom/personal/aihub/WebViewStartup;->probingWorkspace Z
  004e iget-object v1, v6, Lcom/personal/aihub/WebViewStartup;->title Landroid/widget/TextView;
  0052 new-instance v2, Ljava/lang/StringBuilder;
  0056 const-string v3, "Opening "
  005a invoke-direct v2, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0060 iget-object v3, v6, Lcom/personal/aihub/WebViewStartup;->screen Ljava/lang/String;
  0064 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  006a invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0070 move-result-object v2
  0072 invoke-virtual v1, v2, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0078 iget-object v1, v6, Lcom/personal/aihub/WebViewStartup;->message Landroid/widget/TextView;
  007c const-string v2, "Preparing this screen. Your saved units stay on this device."
  0080 invoke-virtual v1, v2, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0086 iget-object v1, v6, Lcom/personal/aihub/WebViewStartup;->spinner Landroid/widget/ProgressBar;
  008a invoke-virtual v1, v0, Landroid/widget/ProgressBar;->setVisibility(I)V
  0090 iget-object v1, v6, Lcom/personal/aihub/WebViewStartup;->retryButton Landroid/widget/Button;
  0094 const/4 v2, 1
  0096 invoke-virtual v1, v2, Landroid/widget/Button;->setEnabled(Z)V
  009c iget-object v1, v6, Lcom/personal/aihub/WebViewStartup;->retryButton Landroid/widget/Button;
  00a0 const/16 v2, 8
  00a4 invoke-virtual v1, v2, Landroid/widget/Button;->setVisibility(I)V
  00aa iget-object v1, v6, Lcom/personal/aihub/WebViewStartup;->waitButton Landroid/widget/Button;
  00ae invoke-virtual v1, v2, Landroid/widget/Button;->setVisibility(I)V
  00b4 iget-object v1, v6, Lcom/personal/aihub/WebViewStartup;->reportButton Landroid/widget/Button;
  00b8 invoke-virtual v1, v2, Landroid/widget/Button;->setVisibility(I)V
  00be iget-object v1, v6, Lcom/personal/aihub/WebViewStartup;->overlay Landroid/widget/ScrollView;
  00c2 invoke-virtual v1, v0, Landroid/widget/ScrollView;->setVisibility(I)V
  00c8 iget-wide v0, v6, Lcom/personal/aihub/WebViewStartup;->epoch J
  00cc iget-object v2, v6, Lcom/personal/aihub/WebViewStartup;->handler Landroid/os/Handler;
  00d0 new-instance v3, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda1;
  00d4 invoke-direct v3, v6, v7, v0, v1, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda1;-><init>(Lcom/personal/aihub/WebViewStartup; Landroid/webkit/WebView; J)V
  00da const-wide/32 v4, 45000
  00e0 invoke-virtual v2, v3, v4, v5, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable; J)Z
  00e6 return-wide v0
.end method

.method close()V
  0000 const/4 v0, 1
  0002 iput-boolean v0, v4, Lcom/personal/aihub/WebViewStartup;->closed Z
  0006 iget-wide v0, v4, Lcom/personal/aihub/WebViewStartup;->epoch J
  000a const-wide/16 v2, 1
  000e add-long/2addr v0, v2
  0010 iput-wide v0, v4, Lcom/personal/aihub/WebViewStartup;->epoch J
  0014 const-string v0, "closed"
  0018 iput-object v0, v4, Lcom/personal/aihub/WebViewStartup;->phase Ljava/lang/String;
  001c iget-object v0, v4, Lcom/personal/aihub/WebViewStartup;->handler Landroid/os/Handler;
  0020 const/4 v1, 0
  0022 invoke-virtual v0, v1, Landroid/os/Handler;->removeCallbacksAndMessages(Ljava/lang/Object;)V
  0028 iput-object v1, v4, Lcom/personal/aihub/WebViewStartup;->web Landroid/webkit/WebView;
  002c iget-object v0, v4, Lcom/personal/aihub/WebViewStartup;->overlay Landroid/widget/ScrollView;
  0030 const/16 v1, 8
  0034 invoke-virtual v0, v1, Landroid/widget/ScrollView;->setVisibility(I)V
  003a return-void 
.end method

.method controlsReady()Z
  0000 iget-boolean v0, v2, Lcom/personal/aihub/WebViewStartup;->closed Z
  0004 if-nez v0, +00eh
  0008 const-string v0, "ready"
  000c iget-object v1, v2, Lcom/personal/aihub/WebViewStartup;->phase Ljava/lang/String;
  0010 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0016 move-result v0
  0018 if-eqz v0, +004h
  001c const/4 v0, 1
  001e goto +2h
  0020 const/4 v0, 0
  0022 return v0
.end method

.method current(Landroid/webkit/WebView; J)Z
  0000 iget-boolean v0, v2, Lcom/personal/aihub/WebViewStartup;->closed Z
  0004 if-nez v0, +01eh
  0008 iget-object v0, v2, Lcom/personal/aihub/WebViewStartup;->web Landroid/webkit/WebView;
  000c if-ne v0, v3, +01ah
  0010 iget-wide v0, v2, Lcom/personal/aihub/WebViewStartup;->epoch J
  0014 cmp-long v3, v0, v4
  0018 if-nez v3, +014h
  001c iget-object v3, v2, Lcom/personal/aihub/WebViewStartup;->activity Landroid/app/Activity;
  0020 invoke-virtual v3, Landroid/app/Activity;->isFinishing()Z
  0026 move-result v3
  0028 if-nez v3, +00ch
  002c iget-object v3, v2, Lcom/personal/aihub/WebViewStartup;->activity Landroid/app/Activity;
  0030 invoke-virtual v3, Landroid/app/Activity;->isDestroyed()Z
  0036 move-result v3
  0038 if-nez v3, +004h
  003c const/4 v3, 1
  003e goto +2h
  0040 const/4 v3, 0
  0042 return v3
.end method

.method diagnostics()Lorg/json/JSONObject;
  0000 const-string v0, "phase"
  0004 new-instance v1, Lorg/json/JSONObject;
  0008 invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  000e iget-object v2, v9, Lcom/personal/aihub/WebViewStartup;->activity Landroid/app/Activity;
  0012 invoke-virtual v2, Landroid/app/Activity;->getPackageManager()Landroid/content/pm/PackageManager;
  0018 move-result-object v2
  001a iget-object v3, v9, Lcom/personal/aihub/WebViewStartup;->activity Landroid/app/Activity;
  001e invoke-virtual v3, Landroid/app/Activity;->getPackageName()Ljava/lang/String;
  0024 move-result-object v3
  0026 const/4 v4, 0
  0028 invoke-virtual v2, v3, v4, Landroid/content/pm/PackageManager;->getPackageInfo(Ljava/lang/String; I)Landroid/content/pm/PackageInfo;
  002e move-result-object v2
  0030 invoke-static Landroid/webkit/WebView;->getCurrentWebViewPackage()Landroid/content/pm/PackageInfo;
  0036 move-result-object v3
  0038 const-string v4, "kind"
  003c const-string v5, "dokkan-unit-creation-startup"
  0040 invoke-virtual v1, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0046 move-result-object v4
  0048 const-string v5, "schemaVersion"
  004c const/4 v6, 1
  004e invoke-virtual v4, v5, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0054 move-result-object v4
  0056 const-string v5, "appVersion"
  005a iget-object v6, v2, Landroid/content/pm/PackageInfo;->versionName Ljava/lang/String;
  005e invoke-virtual v4, v5, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0064 move-result-object v4
  0066 const-string v5, "versionCode"
  006a sget v6, Landroid/os/Build$VERSION;->SDK_INT I
  006e const/16 v7, 28
  0072 if-lt v6, v7, +007h
  0076 invoke-virtual v2, Landroid/content/pm/PackageInfo;->getLongVersionCode()J
  007c move-result-wide v6
  007e goto +4h
  0080 iget v2, v2, Landroid/content/pm/PackageInfo;->versionCode I
  0084 int-to-long v6, v2
  0086 invoke-virtual v4, v5, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  008c move-result-object v2
  008e const-string v4, "androidAPI"
  0092 sget v5, Landroid/os/Build$VERSION;->SDK_INT I
  0096 invoke-virtual v2, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  009c move-result-object v2
  009e const-string v4, "deviceModel"
  00a2 sget-object v5, Landroid/os/Build;->MODEL Ljava/lang/String;
  00a6 invoke-virtual v2, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00ac move-result-object v2
  00ae const-string v4, "screen"
  00b2 iget-object v5, v9, Lcom/personal/aihub/WebViewStartup;->screen Ljava/lang/String;
  00b6 invoke-virtual v2, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00bc move-result-object v2
  00be iget-object v4, v9, Lcom/personal/aihub/WebViewStartup;->phase Ljava/lang/String;
  00c2 invoke-virtual v2, v0, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00c8 move-result-object v2
  00ca const-string v4, "stage"
  00ce iget-object v5, v9, Lcom/personal/aihub/WebViewStartup;->stage Ljava/lang/String;
  00d2 invoke-virtual v2, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00d8 move-result-object v2
  00da const-string v4, "navigation"
  00de iget-wide v5, v9, Lcom/personal/aihub/WebViewStartup;->epoch J
  00e2 invoke-virtual v2, v4, v5, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  00e8 move-result-object v2
  00ea const-string v4, "elapsedMs"
  00ee invoke-static Landroid/os/SystemClock;->elapsedRealtime()J
  00f4 move-result-wide v5
  00f6 iget-wide v7, v9, Lcom/personal/aihub/WebViewStartup;->started J
  00fa sub-long/2addr v5, v7
  00fc const-wide/16 v7, 0
  0100 invoke-static v7, v8, v5, v6, Ljava/lang/Math;->max(J J)J
  0106 move-result-wide v5
  0108 invoke-virtual v2, v4, v5, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  010e move-result-object v2
  0110 const-string v4, "webViewPackage"
  0114 const-string v5, "unavailable"
  0118 if-nez v3, +004h
  011c move-object v6, v5
  011e goto +3h
  0120 iget-object v6, v3, Landroid/content/pm/PackageInfo;->packageName Ljava/lang/String;
  0124 invoke-virtual v2, v4, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  012a move-result-object v2
  012c const-string v4, "webViewVersion"
  0130 if-nez v3, +003h
  0134 goto +3h
  0136 iget-object v5, v3, Landroid/content/pm/PackageInfo;->versionName Ljava/lang/String;
  013a invoke-virtual v2, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0140 move-result-object v2
  0142 const-string v3, "scope"
  0146 const-string v4, "Screen startup only; no animation playback or gameplay verification."
  014a invoke-virtual v2, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0150 goto +15h
  0152 move-exception v2
  0154 iget-object v3, v9, Lcom/personal/aihub/WebViewStartup;->phase Ljava/lang/String;
  0158 invoke-virtual v1, v0, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  015e move-result-object v0
  0160 const-string v3, "reportError"
  0164 invoke-virtual v2, Ljava/lang/Object;->getClass()Ljava/lang/Class;
  016a move-result-object v2
  016c invoke-virtual v2, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;
  0172 move-result-object v2
  0174 invoke-virtual v0, v3, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  017a return-object v1
.end method

.method epoch()J
  0000 iget-wide v0, v2, Lcom/personal/aihub/WebViewStartup;->epoch J
  0004 return-wide v0
.end method

.method failed(Landroid/webkit/WebView; J Ljava/lang/String;)V
  0000 invoke-virtual v0, v1, v2, v3, Lcom/personal/aihub/WebViewStartup;->current(Landroid/webkit/WebView; J)Z
  0006 move-result v1
  0008 if-nez v1, +003h
  000c return-void 
  000e iget-object v1, v0, Lcom/personal/aihub/WebViewStartup;->handler Landroid/os/Handler;
  0012 const/4 v2, 0
  0014 invoke-virtual v1, v2, Landroid/os/Handler;->removeCallbacksAndMessages(Ljava/lang/Object;)V
  001a invoke-direct v0, v4, Lcom/personal/aihub/WebViewStartup;->slow(Ljava/lang/String;)V
  0020 return-void 
.end method

.method lambda$begin$3$com-personal-aihub-WebViewStartup(Landroid/webkit/WebView; J)V
  0000 invoke-virtual v0, v1, v2, v3, Lcom/personal/aihub/WebViewStartup;->current(Landroid/webkit/WebView; J)Z
  0006 move-result v1
  0008 if-eqz v1, +01bh
  000c const-string v1, "ready"
  0010 iget-object v2, v0, Lcom/personal/aihub/WebViewStartup;->phase Ljava/lang/String;
  0014 invoke-virtual v1, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  001a move-result v1
  001c if-nez v1, +011h
  0020 const-string v1, "workspace-error"
  0024 iget-object v2, v0, Lcom/personal/aihub/WebViewStartup;->phase Ljava/lang/String;
  0028 invoke-virtual v1, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  002e move-result v1
  0030 if-nez v1, +007h
  0034 const-string v1, "This screen has not responded yet. Keep waiting, try again, or copy a report to help diagnose it."
  0038 invoke-direct v0, v1, Lcom/personal/aihub/WebViewStartup;->slow(Ljava/lang/String;)V
  003e return-void 
.end method

.method lambda$new$0$com-personal-aihub-WebViewStartup(Ljava/lang/Runnable;)V
  0000 iget-boolean v0, v2, Lcom/personal/aihub/WebViewStartup;->closed Z
  0004 if-eqz v0, +003h
  0008 return-void 
  000a const-string v0, "retry-requested"
  000e iput-object v0, v2, Lcom/personal/aihub/WebViewStartup;->phase Ljava/lang/String;
  0012 iget-object v0, v2, Lcom/personal/aihub/WebViewStartup;->handler Landroid/os/Handler;
  0016 const/4 v1, 0
  0018 invoke-virtual v0, v1, Landroid/os/Handler;->removeCallbacksAndMessages(Ljava/lang/Object;)V
  001e invoke-direct v2, Lcom/personal/aihub/WebViewStartup;->disableRetry()V
  0024 invoke-interface v3, Ljava/lang/Runnable;->run()V
  002a return-void 
.end method

.method lambda$new$1$com-personal-aihub-WebViewStartup(Ljava/lang/String;)V
  0000 const-string v0, "waiting"
  0004 iput-object v0, v3, Lcom/personal/aihub/WebViewStartup;->phase Ljava/lang/String;
  0008 iget-object v0, v3, Lcom/personal/aihub/WebViewStartup;->title Landroid/widget/TextView;
  000c new-instance v1, Ljava/lang/StringBuilder;
  0010 const-string v2, "Opening "
  0014 invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  001a invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0020 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0026 move-result-object v4
  0028 invoke-virtual v0, v4, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  002e iget-object v4, v3, Lcom/personal/aihub/WebViewStartup;->message Landroid/widget/TextView;
  0032 const-string v0, "Waiting for Android to open this screen. You can retry or copy a report at any time."
  0036 invoke-virtual v4, v0, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  003c iget-object v4, v3, Lcom/personal/aihub/WebViewStartup;->spinner Landroid/widget/ProgressBar;
  0040 const/4 v0, 0
  0042 invoke-virtual v4, v0, Landroid/widget/ProgressBar;->setVisibility(I)V
  0048 return-void 
.end method

.method lambda$probeWorkspace$4$com-personal-aihub-WebViewStartup(Landroid/webkit/WebView; J)V
  0000 invoke-direct v0, v1, v2, v3, Lcom/personal/aihub/WebViewStartup;->probeWorkspace(Landroid/webkit/WebView; J)V
  0006 return-void 
.end method

.method lambda$probeWorkspace$5$com-personal-aihub-WebViewStartup(Landroid/webkit/WebView; J Ljava/lang/String;)V
  0000 invoke-virtual v1, v2, v3, v4, Lcom/personal/aihub/WebViewStartup;->current(Landroid/webkit/WebView; J)Z
  0006 move-result v0
  0008 if-nez v0, +003h
  000c return-void 
  000e const-string v0, ""ready""
  0012 invoke-virtual v0, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0018 move-result v0
  001a if-eqz v0, +006h
  001e invoke-virtual v1, v2, v3, v4, Lcom/personal/aihub/WebViewStartup;->ready(Landroid/webkit/WebView; J)V
  0024 goto +1bh
  0026 const-string v0, ""failed""
  002a invoke-virtual v0, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0030 move-result v5
  0032 if-eqz v5, +008h
  0036 const-string v5, "workspace-error"
  003a invoke-direct v1, v2, v3, v4, v5, Lcom/personal/aihub/WebViewStartup;->finish(Landroid/webkit/WebView; J Ljava/lang/String;)V
  0040 goto +dh
  0042 iget-object v5, v1, Lcom/personal/aihub/WebViewStartup;->handler Landroid/os/Handler;
  0046 new-instance v0, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda5;
  004a invoke-direct v0, v1, v2, v3, v4, Lcom/personal/aihub/WebViewStartup$$ExternalSyntheticLambda5;-><init>(Lcom/personal/aihub/WebViewStartup; Landroid/webkit/WebView; J)V
  0050 const-wide/16 v2, 500
  0054 invoke-virtual v5, v0, v2, v3, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable; J)Z
  005a return-void 
.end method

.method ready(Landroid/webkit/WebView; J)V
  0000 const-string v0, "ready"
  0004 invoke-direct v1, v2, v3, v4, v0, Lcom/personal/aihub/WebViewStartup;->finish(Landroid/webkit/WebView; J Ljava/lang/String;)V
  000a return-void 
.end method

.method stage(Landroid/webkit/WebView; J Ljava/lang/String;)V
  0000 invoke-virtual v0, v1, v2, v3, Lcom/personal/aihub/WebViewStartup;->current(Landroid/webkit/WebView; J)Z
  0006 move-result v1
  0008 if-eqz v1, +004h
  000c iput-object v4, v0, Lcom/personal/aihub/WebViewStartup;->stage Ljava/lang/String;
  0010 return-void 
.end method

.method workspaceFinished(Landroid/webkit/WebView;)V
  0000 iget-boolean v0, v3, Lcom/personal/aihub/WebViewStartup;->probingWorkspace Z
  0004 if-nez v0, +024h
  0008 const-string v0, "ready"
  000c iget-object v1, v3, Lcom/personal/aihub/WebViewStartup;->phase Ljava/lang/String;
  0010 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0016 move-result v0
  0018 if-nez v0, +01ah
  001c const-string v0, "workspace-error"
  0020 iget-object v1, v3, Lcom/personal/aihub/WebViewStartup;->phase Ljava/lang/String;
  0024 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  002a move-result v0
  002c if-eqz v0, +003h
  0030 goto +eh
  0032 const/4 v0, 1
  0034 iput-boolean v0, v3, Lcom/personal/aihub/WebViewStartup;->probingWorkspace Z
  0038 iget-wide v0, v3, Lcom/personal/aihub/WebViewStartup;->epoch J
  003c const-string v2, "workspace-startup"
  0040 invoke-virtual v3, v4, v0, v1, v2, Lcom/personal/aihub/WebViewStartup;->stage(Landroid/webkit/WebView; J Ljava/lang/String;)V
  0046 invoke-direct v3, v4, v0, v1, Lcom/personal/aihub/WebViewStartup;->probeWorkspace(Landroid/webkit/WebView; J)V
  004c return-void 
.end method