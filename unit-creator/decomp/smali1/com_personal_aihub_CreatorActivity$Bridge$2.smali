.class Lcom/personal/aihub/CreatorActivity$Bridge$2;
.super Ljava/lang/Object;
.field this$1 Lcom/personal/aihub/CreatorActivity$Bridge;
.field val$i I
.field val$jSONObjectOptJSONObject Lorg/json/JSONObject;
.field val$string Ljava/lang/String;

.method <init>(Lcom/personal/aihub/CreatorActivity$Bridge; I Ljava/lang/String; Lorg/json/JSONObject;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/CreatorActivity$Bridge$2;->this$1 Lcom/personal/aihub/CreatorActivity$Bridge;
  0004 iput v2, v0, Lcom/personal/aihub/CreatorActivity$Bridge$2;->val$i I
  0008 iput-object v3, v0, Lcom/personal/aihub/CreatorActivity$Bridge$2;->val$string Ljava/lang/String;
  000c iput-object v4, v0, Lcom/personal/aihub/CreatorActivity$Bridge$2;->val$jSONObjectOptJSONObject Lorg/json/JSONObject;
  0010 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0016 return-void 
.end method

.method run()V
  0000 iget-object v0, v4, Lcom/personal/aihub/CreatorActivity$Bridge$2;->this$1 Lcom/personal/aihub/CreatorActivity$Bridge;
  0004 iget v1, v4, Lcom/personal/aihub/CreatorActivity$Bridge$2;->val$i I
  0008 iget-object v2, v4, Lcom/personal/aihub/CreatorActivity$Bridge$2;->val$string Ljava/lang/String;
  000c iget-object v3, v4, Lcom/personal/aihub/CreatorActivity$Bridge$2;->val$jSONObjectOptJSONObject Lorg/json/JSONObject;
  0010 invoke-virtual v0, v1, v2, v3, Lcom/personal/aihub/CreatorActivity$Bridge;->m19lambda$0$compersonalaihubCreatorActivity$Bridge(I Ljava/lang/String; Lorg/json/JSONObject;)V
  0016 return-void 
.end method