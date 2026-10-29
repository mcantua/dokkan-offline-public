.class Lcom/personal/aihub/PreviewActivity$AnonymousClass1$1;
.super Ljava/lang/Object;
.field this$1 Lcom/personal/aihub/PreviewActivity$AnonymousClass1;
.field val$str Ljava/lang/String;
.field val$textView Landroid/widget/TextView;
.field val$webView Landroid/webkit/WebView;

.method <init>(Lcom/personal/aihub/PreviewActivity$AnonymousClass1; Landroid/webkit/WebView; Landroid/widget/TextView; Ljava/lang/String;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$1;->this$1 Lcom/personal/aihub/PreviewActivity$AnonymousClass1;
  0004 iput-object v2, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$1;->val$webView Landroid/webkit/WebView;
  0008 iput-object v3, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$1;->val$textView Landroid/widget/TextView;
  000c iput-object v4, v0, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$1;->val$str Ljava/lang/String;
  0010 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0016 return-void 
.end method

.method run()V
  0000 iget-object v0, v4, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$1;->this$1 Lcom/personal/aihub/PreviewActivity$AnonymousClass1;
  0004 iget-object v1, v4, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$1;->val$webView Landroid/webkit/WebView;
  0008 iget-object v2, v4, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$1;->val$textView Landroid/widget/TextView;
  000c iget-object v3, v4, Lcom/personal/aihub/PreviewActivity$AnonymousClass1$1;->val$str Ljava/lang/String;
  0010 invoke-virtual v0, v1, v2, v3, Lcom/personal/aihub/PreviewActivity$AnonymousClass1;->m30lambda$0$compersonalaihubPreviewActivity$1(Landroid/webkit/WebView; Landroid/widget/TextView; Ljava/lang/String;)V
  0016 return-void 
.end method