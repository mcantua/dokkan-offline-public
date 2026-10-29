.class Lcom/personal/aihub/PreviewMetadata$3;
.super Ljava/lang/Object;
.field val$ids Ljava/util/Set;
.field val$own Ljava/util/Map;
.field val$project Lcom/personal/aihub/GameMetadata$Query;
.field val$sparking Lcom/personal/aihub/GameMetadata$Query;

.method <init>(Ljava/util/Map; Ljava/util/Set; Lcom/personal/aihub/GameMetadata$Query; Lcom/personal/aihub/GameMetadata$Query;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/PreviewMetadata$3;->val$own Ljava/util/Map;
  0004 iput-object v2, v0, Lcom/personal/aihub/PreviewMetadata$3;->val$ids Ljava/util/Set;
  0008 iput-object v3, v0, Lcom/personal/aihub/PreviewMetadata$3;->val$sparking Lcom/personal/aihub/GameMetadata$Query;
  000c iput-object v4, v0, Lcom/personal/aihub/PreviewMetadata$3;->val$project Lcom/personal/aihub/GameMetadata$Query;
  0010 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0016 return-void 
.end method

.method row(Ljava/lang/String; J)Lorg/json/JSONObject;
  0000 const-string v0, "effect_packs"
  0004 invoke-virtual v3, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  000a move-result v0
  000c if-eqz v0, +02eh
  0010 iget-object v0, v2, Lcom/personal/aihub/PreviewMetadata$3;->val$own Ljava/util/Map;
  0014 invoke-static v4, v5, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  001a move-result-object v1
  001c invoke-interface v0, v1, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z
  0022 move-result v0
  0024 if-eqz v0, +00fh
  0028 iget-object v3, v2, Lcom/personal/aihub/PreviewMetadata$3;->val$own Ljava/util/Map;
  002c invoke-static v4, v5, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  0032 move-result-object v4
  0034 invoke-interface v3, v4, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  003a move-result-object v3
  003c check-cast v3, Lorg/json/JSONObject;
  0040 return-object v3
  0042 iget-object v0, v2, Lcom/personal/aihub/PreviewMetadata$3;->val$ids Ljava/util/Set;
  0046 invoke-static v4, v5, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  004c move-result-object v1
  004e invoke-interface v0, v1, Ljava/util/Set;->contains(Ljava/lang/Object;)Z
  0054 move-result v0
  0056 if-eqz v0, +009h
  005a iget-object v0, v2, Lcom/personal/aihub/PreviewMetadata$3;->val$sparking Lcom/personal/aihub/GameMetadata$Query;
  005e invoke-interface v0, v3, v4, v5, Lcom/personal/aihub/GameMetadata$Query;->row(Ljava/lang/String; J)Lorg/json/JSONObject;
  0064 move-result-object v3
  0066 return-object v3
  0068 iget-object v0, v2, Lcom/personal/aihub/PreviewMetadata$3;->val$project Lcom/personal/aihub/GameMetadata$Query;
  006c invoke-interface v0, v3, v4, v5, Lcom/personal/aihub/GameMetadata$Query;->row(Ljava/lang/String; J)Lorg/json/JSONObject;
  0072 move-result-object v3
  0074 return-object v3
.end method