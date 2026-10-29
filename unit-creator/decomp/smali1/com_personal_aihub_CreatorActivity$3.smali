.class Lcom/personal/aihub/CreatorActivity$3;
.super Ljava/lang/Object;
.field this$0 Lcom/personal/aihub/CreatorActivity;
.field val$exc Ljava/lang/Exception;
.field val$i I
.field val$obj Ljava/lang/Object;

.method <init>(Lcom/personal/aihub/CreatorActivity; I Ljava/lang/Exception; Ljava/lang/Object;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/CreatorActivity$3;->this$0 Lcom/personal/aihub/CreatorActivity;
  0004 iput v2, v0, Lcom/personal/aihub/CreatorActivity$3;->val$i I
  0008 iput-object v3, v0, Lcom/personal/aihub/CreatorActivity$3;->val$exc Ljava/lang/Exception;
  000c iput-object v4, v0, Lcom/personal/aihub/CreatorActivity$3;->val$obj Ljava/lang/Object;
  0010 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0016 return-void 
.end method

.method run()V
  0000 iget-object v0, v4, Lcom/personal/aihub/CreatorActivity$3;->this$0 Lcom/personal/aihub/CreatorActivity;
  0004 iget v1, v4, Lcom/personal/aihub/CreatorActivity$3;->val$i I
  0008 iget-object v2, v4, Lcom/personal/aihub/CreatorActivity$3;->val$exc Ljava/lang/Exception;
  000c iget-object v3, v4, Lcom/personal/aihub/CreatorActivity$3;->val$obj Ljava/lang/Object;
  0010 invoke-virtual v0, v1, v2, v3, Lcom/personal/aihub/CreatorActivity;->m11lambda$2$compersonalaihubCreatorActivity(I Ljava/lang/Exception; Ljava/lang/Object;)V
  0016 return-void 
.end method