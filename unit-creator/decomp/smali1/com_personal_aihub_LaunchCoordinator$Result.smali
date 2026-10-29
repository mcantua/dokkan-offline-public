.class Lcom/personal/aihub/LaunchCoordinator$Result;
.super Ljava/lang/Enum;
.field $VALUES [Lcom/personal/aihub/LaunchCoordinator$Result;
.field APP Lcom/personal/aihub/LaunchCoordinator$Result;
.field UNAVAILABLE Lcom/personal/aihub/LaunchCoordinator$Result;
.field WEBSITE Lcom/personal/aihub/LaunchCoordinator$Result;

.method $values()[Lcom/personal/aihub/LaunchCoordinator$Result;
  0000 sget-object v0, Lcom/personal/aihub/LaunchCoordinator$Result;->APP Lcom/personal/aihub/LaunchCoordinator$Result;
  0004 sget-object v1, Lcom/personal/aihub/LaunchCoordinator$Result;->WEBSITE Lcom/personal/aihub/LaunchCoordinator$Result;
  0008 sget-object v2, Lcom/personal/aihub/LaunchCoordinator$Result;->UNAVAILABLE Lcom/personal/aihub/LaunchCoordinator$Result;
  000c filled-new-array v0, v1, v2, [Lcom/personal/aihub/LaunchCoordinator$Result;
  0012 move-result-object v0
  0014 return-object v0
.end method

.method <clinit>()V
  0000 new-instance v0, Lcom/personal/aihub/LaunchCoordinator$Result;
  0004 const-string v1, "APP"
  0008 const/4 v2, 0
  000a invoke-direct v0, v1, v2, Lcom/personal/aihub/LaunchCoordinator$Result;-><init>(Ljava/lang/String; I)V
  0010 sput-object v0, Lcom/personal/aihub/LaunchCoordinator$Result;->APP Lcom/personal/aihub/LaunchCoordinator$Result;
  0014 new-instance v0, Lcom/personal/aihub/LaunchCoordinator$Result;
  0018 const-string v1, "WEBSITE"
  001c const/4 v2, 1
  001e invoke-direct v0, v1, v2, Lcom/personal/aihub/LaunchCoordinator$Result;-><init>(Ljava/lang/String; I)V
  0024 sput-object v0, Lcom/personal/aihub/LaunchCoordinator$Result;->WEBSITE Lcom/personal/aihub/LaunchCoordinator$Result;
  0028 new-instance v0, Lcom/personal/aihub/LaunchCoordinator$Result;
  002c const-string v1, "UNAVAILABLE"
  0030 const/4 v2, 2
  0032 invoke-direct v0, v1, v2, Lcom/personal/aihub/LaunchCoordinator$Result;-><init>(Ljava/lang/String; I)V
  0038 sput-object v0, Lcom/personal/aihub/LaunchCoordinator$Result;->UNAVAILABLE Lcom/personal/aihub/LaunchCoordinator$Result;
  003c invoke-static Lcom/personal/aihub/LaunchCoordinator$Result;->$values()[Lcom/personal/aihub/LaunchCoordinator$Result;
  0042 move-result-object v0
  0044 sput-object v0, Lcom/personal/aihub/LaunchCoordinator$Result;->$VALUES [Lcom/personal/aihub/LaunchCoordinator$Result;
  0048 return-void 
.end method

.method <init>(Ljava/lang/String; I)V
  0000 invoke-direct v0, v1, v2, Ljava/lang/Enum;-><init>(Ljava/lang/String; I)V
  0006 return-void 
.end method

.method valueOf(Ljava/lang/String;)Lcom/personal/aihub/LaunchCoordinator$Result;
  0000 const-class v0, Lcom/personal/aihub/LaunchCoordinator$Result;
  0004 invoke-static v0, v1, Ljava/lang/Enum;->valueOf(Ljava/lang/Class; Ljava/lang/String;)Ljava/lang/Enum;
  000a move-result-object v1
  000c check-cast v1, Lcom/personal/aihub/LaunchCoordinator$Result;
  0010 return-object v1
.end method

.method values()[Lcom/personal/aihub/LaunchCoordinator$Result;
  0000 sget-object v0, Lcom/personal/aihub/LaunchCoordinator$Result;->$VALUES [Lcom/personal/aihub/LaunchCoordinator$Result;
  0004 invoke-virtual v0, [Lcom/personal/aihub/LaunchCoordinator$Result;->clone()Ljava/lang/Object;
  000a move-result-object v0
  000c check-cast v0, [Lcom/personal/aihub/LaunchCoordinator$Result;
  0010 return-object v0
.end method

.method valuesCustom()[Lcom/personal/aihub/LaunchCoordinator$Result;
  0000 invoke-static Lcom/personal/aihub/LaunchCoordinator$Result;->values()[Lcom/personal/aihub/LaunchCoordinator$Result;
  0006 move-result-object v0
  0008 array-length v1, v0
  000a new-array v2, v1, [Lcom/personal/aihub/LaunchCoordinator$Result;
  000e const/4 v3, 0
  0010 invoke-static v0, v3, v2, v3, v1, Ljava/lang/System;->arraycopy(Ljava/lang/Object; I Ljava/lang/Object; I I)V
  0016 return-object v2
.end method