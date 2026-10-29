.class Lcom/personal/aihub/PreviewServer$4;
.super Ljava/lang/Object;
.field this$0 Lcom/personal/aihub/PreviewServer;
.field val$request Lcom/personal/aihub/PreviewServer$Request;

.method <init>(Lcom/personal/aihub/PreviewServer; Lcom/personal/aihub/PreviewServer$Request;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/PreviewServer$4;->this$0 Lcom/personal/aihub/PreviewServer;
  0004 iput-object v2, v0, Lcom/personal/aihub/PreviewServer$4;->val$request Lcom/personal/aihub/PreviewServer$Request;
  0008 invoke-direct v0, Ljava/lang/Object;-><init>()V
  000e return-void 
.end method

.method getMethod()Ljava/lang/String;
  0000 const-string v0, "GET"
  0004 return-object v0
.end method

.method getRequestHeaders()Ljava/util/Map;
  0000 invoke-static Ljava/util/Collections;->emptyMap()Ljava/util/Map;
  0006 move-result-object v0
  0008 return-object v0
.end method

.method getUrl()Landroid/net/Uri;
  0000 new-instance v0, Ljava/lang/StringBuilder;
  0004 const-string v1, "https://dokkan-eclipse.com"
  0008 invoke-direct v0, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  000e iget-object v1, v2, Lcom/personal/aihub/PreviewServer$4;->val$request Lcom/personal/aihub/PreviewServer$Request;
  0012 iget-object v1, v1, Lcom/personal/aihub/PreviewServer$Request;->target Ljava/lang/String;
  0016 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  001c invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0022 move-result-object v0
  0024 invoke-static v0, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  002a move-result-object v0
  002c return-object v0
.end method

.method hasGesture()Z
  0000 const/4 v0, 0
  0002 return v0
.end method

.method isForMainFrame()Z
  0000 const/4 v0, 0
  0002 return v0
.end method

.method isRedirect()Z
  0000 const/4 v0, 0
  0002 return v0
.end method