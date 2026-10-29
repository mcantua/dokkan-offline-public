.class Lcom/personal/aihub/StageExport$2;
.super Ljava/lang/Object;
.field this$0 Lcom/personal/aihub/StageExport;
.field val$data Landroid/net/Uri;
.field val$file Ljava/io/File;

.method <init>(Lcom/personal/aihub/StageExport; Ljava/io/File; Landroid/net/Uri;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/StageExport$2;->this$0 Lcom/personal/aihub/StageExport;
  0004 iput-object v2, v0, Lcom/personal/aihub/StageExport$2;->val$file Ljava/io/File;
  0008 iput-object v3, v0, Lcom/personal/aihub/StageExport$2;->val$data Landroid/net/Uri;
  000c invoke-direct v0, Ljava/lang/Object;-><init>()V
  0012 return-void 
.end method

.method run()V
  0000 iget-object v0, v3, Lcom/personal/aihub/StageExport$2;->this$0 Lcom/personal/aihub/StageExport;
  0004 iget-object v1, v3, Lcom/personal/aihub/StageExport$2;->val$file Ljava/io/File;
  0008 iget-object v2, v3, Lcom/personal/aihub/StageExport$2;->val$data Landroid/net/Uri;
  000c invoke-virtual v0, v1, v2, Lcom/personal/aihub/StageExport;->m40lambda$1$compersonalaihubStageExport(Ljava/io/File; Landroid/net/Uri;)V
  0012 return-void 
.end method