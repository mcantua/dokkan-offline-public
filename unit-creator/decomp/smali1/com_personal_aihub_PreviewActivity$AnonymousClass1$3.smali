.class Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;
.super Ljava/lang/Object;
.field this$1 Lcom/personal/aihub/PreviewActivity$AnonymousClass1;
.field val$epoch J
.field val$jSONObject Lorg/json/JSONObject;
.field val$linearLayout Landroid/widget/LinearLayout;
.field val$previewCache Lcom/personal/aihub/PreviewCache;
.field val$str Ljava/lang/String;
.field val$textView Landroid/widget/TextView;
.field val$webView Landroid/webkit/WebView;

.method <init>(Lcom/personal/aihub/PreviewActivity$AnonymousClass1; Landroid/webkit/WebView; J Ljava/lang/String; Landroid/widget/LinearLayout; Landroid/widget/TextView; Lorg/json/JSONObject; Lcom/personal/aihub/PreviewCache;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->this$1 Lcom/personal/aihub/PreviewActivity$AnonymousClass1;
  0004 iput-object v2, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->val$webView Landroid/webkit/WebView;
  0008 iput-wide v3, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->val$epoch J
  000c iput-object v5, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->val$str Ljava/lang/String;
  0010 iput-object v6, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->val$linearLayout Landroid/widget/LinearLayout;
  0014 iput-object v7, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->val$textView Landroid/widget/TextView;
  0018 iput-object v8, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->val$jSONObject Lorg/json/JSONObject;
  001c iput-object v9, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->val$previewCache Lcom/personal/aihub/PreviewCache;
  0020 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0026 return-void 
.end method

.method onReceiveValue(Ljava/lang/Object;)V
  0000 iget-object v0, v9, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->this$1 Lcom/personal/aihub/PreviewActivity$AnonymousClass1;
  0004 iget-object v0, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->this$0 Lcom/personal/aihub/PreviewActivity;
  0008 invoke-static v0, Lcom/personal/aihub/PreviewActivity;->access$000(Lcom/personal/aihub/PreviewActivity;)Lcom/personal/aihub/WebViewStartup;
  000e move-result-object v0
  0010 iget-object v1, v9, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->val$webView Landroid/webkit/WebView;
  0014 iget-wide v2, v9, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->val$epoch J
  0018 invoke-virtual v0, v1, v2, v3, Lcom/personal/aihub/WebViewStartup;->current(Landroid/webkit/WebView; J)Z
  001e move-result v0
  0020 if-eqz v0, +016h
  0024 iget-object v1, v9, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->this$1 Lcom/personal/aihub/PreviewActivity$AnonymousClass1;
  0028 iget-object v2, v9, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->val$webView Landroid/webkit/WebView;
  002c iget-object v3, v9, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->val$str Ljava/lang/String;
  0030 iget-object v4, v9, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->val$linearLayout Landroid/widget/LinearLayout;
  0034 iget-object v5, v9, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->val$textView Landroid/widget/TextView;
  0038 iget-object v6, v9, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->val$jSONObject Lorg/json/JSONObject;
  003c iget-object v7, v9, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$3;->val$previewCache Lcom/personal/aihub/PreviewCache;
  0040 move-object v8, v10
  0042 check-cast v8, Ljava/lang/String;
  0046 invoke-virtual/range v1 ... v8, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->m32lambda$2$compersonalaihubPreviewActivity$1(Landroid/webkit/WebView; Ljava/lang/String; Landroid/widget/LinearLayout; Landroid/widget/TextView; Lorg/json/JSONObject; Lcom/personal/aihub/PreviewCache; Ljava/lang/String;)V
  004c return-void 
.end method