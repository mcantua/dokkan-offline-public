.class Lcom/personal/aihub/CpkWriter$1;
.super Ljava/lang/Object;
.field val$byteArrayOutputStream Ljava/io/ByteArrayOutputStream;
.field val$linkedHashMap Ljava/util/LinkedHashMap;

.method <init>(Ljava/util/LinkedHashMap; Ljava/io/ByteArrayOutputStream;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/CpkWriter$1;->val$linkedHashMap Ljava/util/LinkedHashMap;
  0004 iput-object v2, v0, Lcom/personal/aihub/CpkWriter$1;->val$byteArrayOutputStream Ljava/io/ByteArrayOutputStream;
  0008 invoke-direct v0, Ljava/lang/Object;-><init>()V
  000e return-void 
.end method

.method apply(Ljava/lang/Object;)Ljava/lang/Object;
  0000 iget-object v0, v2, Lcom/personal/aihub/CpkWriter$1;->val$linkedHashMap Ljava/util/LinkedHashMap;
  0004 iget-object v1, v2, Lcom/personal/aihub/CpkWriter$1;->val$byteArrayOutputStream Ljava/io/ByteArrayOutputStream;
  0008 check-cast v3, Ljava/lang/String;
  000c invoke-static v0, v1, v3, Lcom/personal/aihub/CpkWriter;->lambda$0(Ljava/util/Map; Ljava/io/ByteArrayOutputStream; Ljava/lang/String;)Ljava/lang/Integer;
  0012 move-result-object v3
  0014 return-object v3
.end method