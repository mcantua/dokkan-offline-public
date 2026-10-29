.class Lcom/personal/aihub/MovieStorage$Job;
.super Ljava/lang/Object;
.field bytes J
.field name Ljava/lang/String;
.field touched J

.method <init>(Ljava/lang/String; J)V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 iput-object v1, v0, Lcom/personal/aihub/MovieStorage$Job;->name Ljava/lang/String;
  000a iput-wide v2, v0, Lcom/personal/aihub/MovieStorage$Job;->touched J
  000e return-void 
.end method