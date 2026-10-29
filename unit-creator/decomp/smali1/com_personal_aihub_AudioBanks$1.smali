.class Lcom/personal/aihub/AudioBanks$1;
.super Ljava/lang/Object;
.field this$0 Lcom/personal/aihub/AudioBanks;

.method <init>(Lcom/personal/aihub/AudioBanks;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/AudioBanks$1;->this$0 Lcom/personal/aihub/AudioBanks;
  0004 invoke-direct v0, Ljava/lang/Object;-><init>()V
  000a return-void 
.end method

.method compare(Ljava/lang/Object; Ljava/lang/Object;)I
  0000 check-cast v1, Lcom/personal/aihub/AudioBanks$Candidate;
  0004 iget-object v1, v1, Lcom/personal/aihub/AudioBanks$Candidate;->key Ljava/lang/String;
  0008 check-cast v2, Lcom/personal/aihub/AudioBanks$Candidate;
  000c iget-object v2, v2, Lcom/personal/aihub/AudioBanks$Candidate;->key Ljava/lang/String;
  0010 invoke-virtual v1, v2, Ljava/lang/String;->compareTo(Ljava/lang/String;)I
  0016 move-result v1
  0018 return v1
.end method