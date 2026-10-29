.class Lcom/personal/aihub/LaunchCoordinator;
.super Ljava/lang/Object;

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method open(Lcom/personal/aihub/Provider; Z Lcom/personal/aihub/LaunchCoordinator$Platform;)Lcom/personal/aihub/LaunchCoordinator$Result;
  0000 if-eqz v1, +00bh
  0004 invoke-interface v2, v0, Lcom/personal/aihub/LaunchCoordinator$Platform;->openApp(Lcom/personal/aihub/Provider;)Z
  000a move-result v1
  000c if-eqz v1, +005h
  0010 sget-object v0, Lcom/personal/aihub/LaunchCoordinator$Result;->APP Lcom/personal/aihub/LaunchCoordinator$Result;
  0014 return-object v0
  0016 invoke-interface v2, v0, Lcom/personal/aihub/LaunchCoordinator$Platform;->openWebsite(Lcom/personal/aihub/Provider;)Z
  001c move-result v0
  001e if-eqz v0, +005h
  0022 sget-object v0, Lcom/personal/aihub/LaunchCoordinator$Result;->WEBSITE Lcom/personal/aihub/LaunchCoordinator$Result;
  0026 goto +3h
  0028 sget-object v0, Lcom/personal/aihub/LaunchCoordinator$Result;->UNAVAILABLE Lcom/personal/aihub/LaunchCoordinator$Result;
  002c return-object v0
.end method