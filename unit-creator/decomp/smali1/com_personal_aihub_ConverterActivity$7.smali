.class Lcom/personal/aihub/ConverterActivity$7;
.super Ljava/lang/Object;
.field this$0 Lcom/personal/aihub/ConverterActivity;
.field val$data Landroid/net/Uri;
.field val$str Ljava/lang/String;
.field val$str2 Ljava/lang/String;

.method <init>(Lcom/personal/aihub/ConverterActivity; Ljava/lang/String; Ljava/lang/String; Landroid/net/Uri;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/ConverterActivity$7;->this$0 Lcom/personal/aihub/ConverterActivity;
  0004 iput-object v2, v0, Lcom/personal/aihub/ConverterActivity$7;->val$str Ljava/lang/String;
  0008 iput-object v3, v0, Lcom/personal/aihub/ConverterActivity$7;->val$str2 Ljava/lang/String;
  000c iput-object v4, v0, Lcom/personal/aihub/ConverterActivity$7;->val$data Landroid/net/Uri;
  0010 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0016 return-void 
.end method

.method run()V
  0000 iget-object v0, v4, Lcom/personal/aihub/ConverterActivity$7;->this$0 Lcom/personal/aihub/ConverterActivity;
  0004 iget-object v1, v4, Lcom/personal/aihub/ConverterActivity$7;->val$str Ljava/lang/String;
  0008 iget-object v2, v4, Lcom/personal/aihub/ConverterActivity$7;->val$str2 Ljava/lang/String;
  000c iget-object v3, v4, Lcom/personal/aihub/ConverterActivity$7;->val$data Landroid/net/Uri;
  0010 invoke-virtual v0, v1, v2, v3, Lcom/personal/aihub/ConverterActivity;->m4lambda$5$compersonalaihubConverterActivity(Ljava/lang/String; Ljava/lang/String; Landroid/net/Uri;)V
  0016 return-void 
.end method