.class Lcom/personal/aihub/PreviewServer$3;
.super Ljava/lang/Object;
.field this$0 Lcom/personal/aihub/PreviewServer;
.field val$socketAccept Ljava/net/Socket;

.method <init>(Lcom/personal/aihub/PreviewServer; Ljava/net/Socket;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/PreviewServer$3;->this$0 Lcom/personal/aihub/PreviewServer;
  0004 iput-object v2, v0, Lcom/personal/aihub/PreviewServer$3;->val$socketAccept Ljava/net/Socket;
  0008 invoke-direct v0, Ljava/lang/Object;-><init>()V
  000e return-void 
.end method

.method run()V
  0000 iget-object v0, v2, Lcom/personal/aihub/PreviewServer$3;->this$0 Lcom/personal/aihub/PreviewServer;
  0004 iget-object v1, v2, Lcom/personal/aihub/PreviewServer$3;->val$socketAccept Ljava/net/Socket;
  0008 invoke-virtual v0, v1, Lcom/personal/aihub/PreviewServer;->m34lambda$2$compersonalaihubPreviewServer(Ljava/net/Socket;)V
  000e return-void 
.end method