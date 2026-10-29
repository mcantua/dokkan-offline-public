.class Lcom/personal/aihub/PreviewActivity$3;
.super Ljava/lang/Object;
.field this$0 Lcom/personal/aihub/PreviewActivity;
.field val$str Ljava/lang/String;
.field val$textView2 Landroid/widget/TextView;

.method <init>(Lcom/personal/aihub/PreviewActivity; Ljava/lang/String; Landroid/widget/TextView;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/PreviewActivity$3;->this$0 Lcom/personal/aihub/PreviewActivity;
  0004 iput-object v2, v0, Lcom/personal/aihub/PreviewActivity$3;->val$str Ljava/lang/String;
  0008 iput-object v3, v0, Lcom/personal/aihub/PreviewActivity$3;->val$textView2 Landroid/widget/TextView;
  000c invoke-direct v0, Ljava/lang/Object;-><init>()V
  0012 return-void 
.end method

.method onClick(Landroid/view/View;)V
  0000 iget-object v0, v3, Lcom/personal/aihub/PreviewActivity$3;->this$0 Lcom/personal/aihub/PreviewActivity;
  0004 iget-object v1, v3, Lcom/personal/aihub/PreviewActivity$3;->val$str Ljava/lang/String;
  0008 iget-object v2, v3, Lcom/personal/aihub/PreviewActivity$3;->val$textView2 Landroid/widget/TextView;
  000c invoke-virtual v0, v1, v2, v4, Lcom/personal/aihub/PreviewActivity;->m27lambda$2$compersonalaihubPreviewActivity(Ljava/lang/String; Landroid/widget/TextView; Landroid/view/View;)V
  0012 return-void 
.end method