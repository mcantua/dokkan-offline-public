.class Lcom/personal/aihub/ProjectVersions$1;
.super Ljava/text/SimpleDateFormat;
.field this$0 Lcom/personal/aihub/ProjectVersions;

.method <init>(Lcom/personal/aihub/ProjectVersions; Ljava/lang/String; Ljava/util/Locale;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/ProjectVersions$1;->this$0 Lcom/personal/aihub/ProjectVersions;
  0004 invoke-direct v0, v2, v3, Ljava/text/SimpleDateFormat;-><init>(Ljava/lang/String; Ljava/util/Locale;)V
  000a const-string v1, "UTC"
  000e invoke-static v1, Ljava/util/TimeZone;->getTimeZone(Ljava/lang/String;)Ljava/util/TimeZone;
  0014 move-result-object v1
  0016 invoke-virtual v0, v1, Lcom/personal/aihub/ProjectVersions$1;->setTimeZone(Ljava/util/TimeZone;)V
  001c return-void 
.end method