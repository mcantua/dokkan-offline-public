.class Lcom/personal/aihub/PreviewServer$Request;
.super Ljava/lang/Object;
.field headers Ljava/util/Map;
.field input Ljava/io/BufferedInputStream;
.field method Ljava/lang/String;
.field target Ljava/lang/String;
.field uri Ljava/net/URI;

.method <init>()V
  0000 invoke-direct v1, Ljava/lang/Object;-><init>()V
  0006 new-instance v0, Ljava/util/HashMap;
  000a invoke-direct v0, Ljava/util/HashMap;-><init>()V
  0010 iput-object v0, v1, Lcom/personal/aihub/PreviewServer$Request;->headers Ljava/util/Map;
  0014 return-void 
.end method

.method <init>(Lcom/personal/aihub/PreviewServer$Request;)V
  0000 invoke-direct v0, Lcom/personal/aihub/PreviewServer$Request;-><init>()V
  0006 return-void 
.end method