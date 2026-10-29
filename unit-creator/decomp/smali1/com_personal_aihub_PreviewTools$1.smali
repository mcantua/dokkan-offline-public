.class Lcom/personal/aihub/PreviewTools$1;
.super Ljava/lang/Object;
.field this$0 Lcom/personal/aihub/PreviewTools;
.field val$jRevision J
.field val$job Lcom/personal/aihub/PreviewTools$Job;

.method <init>(Lcom/personal/aihub/PreviewTools; Lcom/personal/aihub/PreviewTools$Job; J)V
  0000 iput-object v1, v0, Lcom/personal/aihub/PreviewTools$1;->this$0 Lcom/personal/aihub/PreviewTools;
  0004 iput-object v2, v0, Lcom/personal/aihub/PreviewTools$1;->val$job Lcom/personal/aihub/PreviewTools$Job;
  0008 iput-wide v3, v0, Lcom/personal/aihub/PreviewTools$1;->val$jRevision J
  000c invoke-direct v0, Ljava/lang/Object;-><init>()V
  0012 return-void 
.end method

.method run()V
  0000 iget-object v0, v4, Lcom/personal/aihub/PreviewTools$1;->this$0 Lcom/personal/aihub/PreviewTools;
  0004 iget-object v1, v4, Lcom/personal/aihub/PreviewTools$1;->val$job Lcom/personal/aihub/PreviewTools$Job;
  0008 iget-wide v2, v4, Lcom/personal/aihub/PreviewTools$1;->val$jRevision J
  000c invoke-virtual v0, v1, v2, v3, Lcom/personal/aihub/PreviewTools;->m35lambda$0$compersonalaihubPreviewTools(Lcom/personal/aihub/PreviewTools$Job; J)V
  0012 return-void 
.end method