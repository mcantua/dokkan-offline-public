.class Lcom/personal/aihub/CreatorActivity$10;
.super Ljava/lang/Object;
.field this$0 Lcom/personal/aihub/CreatorActivity;
.field val$originalNames Ljava/util/HashMap;

.method <init>(Lcom/personal/aihub/CreatorActivity; Ljava/util/HashMap;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/CreatorActivity$10;->this$0 Lcom/personal/aihub/CreatorActivity;
  0004 iput-object v2, v0, Lcom/personal/aihub/CreatorActivity$10;->val$originalNames Ljava/util/HashMap;
  0008 invoke-direct v0, Ljava/lang/Object;-><init>()V
  000e return-void 
.end method

.method compare(Ljava/io/File; Ljava/io/File;)I
  0000 iget-object v0, v1, Lcom/personal/aihub/CreatorActivity$10;->val$originalNames Ljava/util/HashMap;
  0004 invoke-virtual v0, v3, Ljava/util/HashMap;->get(Ljava/lang/Object;)Ljava/lang/Object;
  000a move-result-object v3
  000c check-cast v3, Ljava/lang/String;
  0010 invoke-static v3, Lcom/personal/aihub/CreatorActivity;->access$400(Ljava/lang/String;)I
  0016 move-result v3
  0018 iget-object v0, v1, Lcom/personal/aihub/CreatorActivity$10;->val$originalNames Ljava/util/HashMap;
  001c invoke-virtual v0, v2, Ljava/util/HashMap;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0022 move-result-object v2
  0024 check-cast v2, Ljava/lang/String;
  0028 invoke-static v2, Lcom/personal/aihub/CreatorActivity;->access$400(Ljava/lang/String;)I
  002e move-result v2
  0030 invoke-static v3, v2, Ljava/lang/Integer;->compare(I I)I
  0036 move-result v2
  0038 return v2
.end method

.method compare(Ljava/lang/Object; Ljava/lang/Object;)I
  0000 check-cast v1, Ljava/io/File;
  0004 check-cast v2, Ljava/io/File;
  0008 invoke-virtual v0, v1, v2, Lcom/personal/aihub/CreatorActivity$10;->compare(Ljava/io/File; Ljava/io/File;)I
  000e move-result v1
  0010 return v1
.end method