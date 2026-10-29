.class Lcom/personal/aihub/MovieStorage$1;
.super Ljava/lang/Object;

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method getAsLong()J
  0000 invoke-static Ljava/lang/System;->currentTimeMillis()J
  0006 move-result-wide v0
  0008 return-wide v0
.end method