.class Lcom/personal/aihub/MainActivity$5;
.super Ljava/lang/Object;
.field this$0 Lcom/personal/aihub/MainActivity;
.field val$provider Lcom/personal/aihub/Provider;

.method <init>(Lcom/personal/aihub/MainActivity; Lcom/personal/aihub/Provider;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/MainActivity$5;->this$0 Lcom/personal/aihub/MainActivity;
  0004 iput-object v2, v0, Lcom/personal/aihub/MainActivity$5;->val$provider Lcom/personal/aihub/Provider;
  0008 invoke-direct v0, Ljava/lang/Object;-><init>()V
  000e return-void 
.end method

.method onClick(Landroid/view/View;)V
  0000 iget-object v0, v2, Lcom/personal/aihub/MainActivity$5;->this$0 Lcom/personal/aihub/MainActivity;
  0004 iget-object v1, v2, Lcom/personal/aihub/MainActivity$5;->val$provider Lcom/personal/aihub/Provider;
  0008 invoke-virtual v0, v1, v3, Lcom/personal/aihub/MainActivity;->m24lambda$4$compersonalaihubMainActivity(Lcom/personal/aihub/Provider; Landroid/view/View;)V
  000e return-void 
.end method