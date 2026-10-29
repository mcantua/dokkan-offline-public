.class Lcom/personal/aihub/CreatorActivity$9;
.super Ljava/lang/Object;
.field this$0 Lcom/personal/aihub/CreatorActivity;
.field val$data Landroid/net/Uri;
.field val$i I
.field val$i3 I
.field val$jSONObject Lorg/json/JSONObject;
.field val$str Ljava/lang/String;

.method <init>(Lcom/personal/aihub/CreatorActivity; I Landroid/net/Uri; Lorg/json/JSONObject; Ljava/lang/String; I)V
  0000 iput-object v1, v0, Lcom/personal/aihub/CreatorActivity$9;->this$0 Lcom/personal/aihub/CreatorActivity;
  0004 iput v2, v0, Lcom/personal/aihub/CreatorActivity$9;->val$i I
  0008 iput-object v3, v0, Lcom/personal/aihub/CreatorActivity$9;->val$data Landroid/net/Uri;
  000c iput-object v4, v0, Lcom/personal/aihub/CreatorActivity$9;->val$jSONObject Lorg/json/JSONObject;
  0010 iput-object v5, v0, Lcom/personal/aihub/CreatorActivity$9;->val$str Ljava/lang/String;
  0014 iput v6, v0, Lcom/personal/aihub/CreatorActivity$9;->val$i3 I
  0018 invoke-direct v0, Ljava/lang/Object;-><init>()V
  001e return-void 
.end method

.method run()V
  0000 iget-object v0, v6, Lcom/personal/aihub/CreatorActivity$9;->this$0 Lcom/personal/aihub/CreatorActivity;
  0004 iget v1, v6, Lcom/personal/aihub/CreatorActivity$9;->val$i I
  0008 iget-object v2, v6, Lcom/personal/aihub/CreatorActivity$9;->val$data Landroid/net/Uri;
  000c iget-object v3, v6, Lcom/personal/aihub/CreatorActivity$9;->val$jSONObject Lorg/json/JSONObject;
  0010 iget-object v4, v6, Lcom/personal/aihub/CreatorActivity$9;->val$str Ljava/lang/String;
  0014 iget v5, v6, Lcom/personal/aihub/CreatorActivity$9;->val$i3 I
  0018 invoke-virtual/range v0 ... v5, Lcom/personal/aihub/CreatorActivity;->m17lambda$8$compersonalaihubCreatorActivity(I Landroid/net/Uri; Lorg/json/JSONObject; Ljava/lang/String; I)V
  001e return-void 
.end method