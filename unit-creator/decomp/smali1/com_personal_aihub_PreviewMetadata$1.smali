.class Lcom/personal/aihub/PreviewMetadata$1;
.super Ljava/lang/Object;
.field val$database Ljava/io/File;

.method <init>(Ljava/io/File;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/PreviewMetadata$1;->val$database Ljava/io/File;
  0004 invoke-direct v0, Ljava/lang/Object;-><init>()V
  000a return-void 
.end method

.method row(Ljava/lang/String; J)Lorg/json/JSONObject;
  0000 iget-object v0, v1, Lcom/personal/aihub/PreviewMetadata$1;->val$database Ljava/io/File;
  0004 invoke-static v0, v2, v3, v4, Lcom/personal/aihub/PreviewMetadata;->access$000(Ljava/io/File; Ljava/lang/String; J)Lorg/json/JSONObject;
  000a move-result-object v2
  000c return-object v2
.end method