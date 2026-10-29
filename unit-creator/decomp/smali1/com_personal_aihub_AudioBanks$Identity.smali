.class Lcom/personal/aihub/AudioBanks$Identity;
.super Ljava/lang/Object;
.field kind Ljava/lang/String;
.field locale Ljava/lang/String;
.field pkg Ljava/lang/String;

.method <init>(Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 iput-object v1, v0, Lcom/personal/aihub/AudioBanks$Identity;->kind Ljava/lang/String;
  000a iput-object v2, v0, Lcom/personal/aihub/AudioBanks$Identity;->pkg Ljava/lang/String;
  000e iput-object v3, v0, Lcom/personal/aihub/AudioBanks$Identity;->locale Ljava/lang/String;
  0012 return-void 
.end method

.method logical()Ljava/lang/String;
  0000 new-instance v0, Ljava/lang/StringBuilder;
  0004 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  000a iget-object v1, v3, Lcom/personal/aihub/AudioBanks$Identity;->kind Ljava/lang/String;
  000e invoke-static v1, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0014 move-result-object v1
  0016 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  001c const-string v1, "|"
  0020 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0026 iget-object v2, v3, Lcom/personal/aihub/AudioBanks$Identity;->locale Ljava/lang/String;
  002a invoke-virtual v0, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0030 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0036 iget-object v1, v3, Lcom/personal/aihub/AudioBanks$Identity;->pkg Ljava/lang/String;
  003a sget-object v2, Ljava/text/Normalizer$Form;->NFC Ljava/text/Normalizer$Form;
  003e invoke-static v1, v2, Ljava/text/Normalizer;->normalize(Ljava/lang/CharSequence; Ljava/text/Normalizer$Form;)Ljava/lang/String;
  0044 move-result-object v1
  0046 sget-object v2, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  004a invoke-virtual v1, v2, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  0050 move-result-object v1
  0052 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0058 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  005e move-result-object v0
  0060 return-object v0
.end method