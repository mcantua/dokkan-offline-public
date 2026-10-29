.class Lcom/personal/aihub/PreviewTools$Job;
.super Ljava/lang/Object;
.field failures Lorg/json/JSONArray;
.field label Ljava/lang/String;
.field preparing Z

.method <init>()V
  0000 invoke-direct v1, Ljava/lang/Object;-><init>()V
  0006 const-string v0, ""
  000a iput-object v0, v1, Lcom/personal/aihub/PreviewTools$Job;->label Ljava/lang/String;
  000e new-instance v0, Lorg/json/JSONArray;
  0012 invoke-direct v0, Lorg/json/JSONArray;-><init>()V
  0018 iput-object v0, v1, Lcom/personal/aihub/PreviewTools$Job;->failures Lorg/json/JSONArray;
  001c return-void 
.end method

.method <init>(Lcom/personal/aihub/PreviewTools$Job;)V
  0000 invoke-direct v0, Lcom/personal/aihub/PreviewTools$Job;-><init>()V
  0006 return-void 
.end method