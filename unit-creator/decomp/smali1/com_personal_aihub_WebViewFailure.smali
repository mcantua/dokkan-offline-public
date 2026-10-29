.class Lcom/personal/aihub/WebViewFailure;
.super Ljava/lang/Object;

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method show(Landroid/app/Activity; Ljava/lang/String; Ljava/lang/Runnable;)V
  0000 new-instance v0, Landroid/widget/LinearLayout;
  0004 invoke-direct v0, v4, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
  000a const/4 v1, 1
  000c invoke-virtual v0, v1, Landroid/widget/LinearLayout;->setOrientation(I)V
  0012 const/16 v1, 16
  0016 invoke-virtual v0, v1, Landroid/widget/LinearLayout;->setGravity(I)V
  001c const/16 v1, 40
  0020 const/16 v2, 80
  0024 invoke-virtual v0, v1, v2, v1, v2, Landroid/widget/LinearLayout;->setPadding(I I I I)V
  002a const v1, -15657702
  0030 invoke-virtual v0, v1, Landroid/widget/LinearLayout;->setBackgroundColor(I)V
  0036 new-instance v1, Landroid/widget/TextView;
  003a invoke-direct v1, v4, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
  0040 const-string v2, "Android’s WebView stopped"
  0044 invoke-virtual v1, v2, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  004a const v2, -1118482
  0050 invoke-virtual v1, v2, Landroid/widget/TextView;->setTextColor(I)V
  0056 const/high16 v2, 1103101952
  005a invoke-virtual v1, v2, Landroid/widget/TextView;->setTextSize(F)V
  0060 invoke-virtual v0, v1, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  0066 new-instance v1, Landroid/widget/TextView;
  006a invoke-direct v1, v4, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
  0070 new-instance v2, Ljava/lang/StringBuilder;
  0074 const-string v3, "Your saved units are still on this device. Reopen "
  0078 invoke-direct v2, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  007e invoke-virtual v2, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0084 const-string v3, " to try again. If this repeats, update Android System WebView in your device’s app store and restart the app."
  0088 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  008e invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0094 move-result-object v2
  0096 invoke-virtual v1, v2, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  009c const v2, -4473925
  00a2 invoke-virtual v1, v2, Landroid/widget/TextView;->setTextColor(I)V
  00a8 const/high16 v2, 1098907648
  00ac invoke-virtual v1, v2, Landroid/widget/TextView;->setTextSize(F)V
  00b2 const/4 v2, 0
  00b4 const/16 v3, 24
  00b8 invoke-virtual v1, v2, v3, v2, v3, Landroid/widget/TextView;->setPadding(I I I I)V
  00be invoke-virtual v0, v1, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  00c4 new-instance v1, Landroid/widget/Button;
  00c8 invoke-direct v1, v4, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
  00ce new-instance v2, Ljava/lang/StringBuilder;
  00d2 const-string v3, "Reopen "
  00d6 invoke-direct v2, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00dc invoke-virtual v2, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00e2 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00e8 move-result-object v5
  00ea invoke-virtual v1, v5, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V
  00f0 new-instance v5, Lcom/personal/aihub/WebViewFailure$1;
  00f4 invoke-direct v5, v6, Lcom/personal/aihub/WebViewFailure$1;-><init>(Ljava/lang/Runnable;)V
  00fa invoke-virtual v1, v5, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
  0100 invoke-virtual v0, v1, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  0106 new-instance v5, Landroid/widget/Button;
  010a invoke-direct v5, v4, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
  0110 const-string v6, "Close"
  0114 invoke-virtual v5, v6, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V
  011a new-instance v6, Lcom/personal/aihub/WebViewFailure$2;
  011e invoke-direct v6, v4, Lcom/personal/aihub/WebViewFailure$2;-><init>(Landroid/app/Activity;)V
  0124 invoke-virtual v5, v6, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
  012a invoke-virtual v0, v5, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  0130 invoke-virtual v4, v0, Landroid/app/Activity;->setContentView(Landroid/view/View;)V
  0136 return-void 
.end method