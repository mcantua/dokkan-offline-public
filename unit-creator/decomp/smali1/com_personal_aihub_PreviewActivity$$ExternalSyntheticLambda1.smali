.class Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;
.super Ljava/lang/Object;
.field f$0 Lcom/personal/aihub/PreviewActivity;
.field f$1 Landroid/webkit/WebView;
.field f$2 J
.field f$3 Lcom/personal/aihub/PreviewBootstrap;
.field f$4 Landroid/widget/TextView;
.field f$5 I
.field f$6 Ljava/lang/String;

.method <init>(Lcom/personal/aihub/PreviewActivity; Landroid/webkit/WebView; J Lcom/personal/aihub/PreviewBootstrap; Landroid/widget/TextView; I Ljava/lang/String;)V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 iput-object v1, v0, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;->f$0 Lcom/personal/aihub/PreviewActivity;
  000a iput-object v2, v0, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;->f$1 Landroid/webkit/WebView;
  000e iput-wide v3, v0, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;->f$2 J
  0012 iput-object v5, v0, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;->f$3 Lcom/personal/aihub/PreviewBootstrap;
  0016 iput-object v6, v0, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;->f$4 Landroid/widget/TextView;
  001a iput v7, v0, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;->f$5 I
  001e iput-object v8, v0, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;->f$6 Ljava/lang/String;
  0022 return-void 
.end method

.method onReceiveValue(Ljava/lang/Object;)V
  0000 iget-object v0, v9, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;->f$0 Lcom/personal/aihub/PreviewActivity;
  0004 iget-object v1, v9, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;->f$1 Landroid/webkit/WebView;
  0008 iget-wide v2, v9, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;->f$2 J
  000c iget-object v4, v9, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;->f$3 Lcom/personal/aihub/PreviewBootstrap;
  0010 iget-object v5, v9, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;->f$4 Landroid/widget/TextView;
  0014 iget v6, v9, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;->f$5 I
  0018 iget-object v7, v9, Lcom/personal/aihub/PreviewActivity$$ExternalSyntheticLambda1;->f$6 Ljava/lang/String;
  001c move-object v8, v10
  001e check-cast v8, Ljava/lang/String;
  0022 invoke-virtual/range v0 ... v8, Lcom/personal/aihub/PreviewActivity;->lambda$sendBootstrap$0$com-personal-aihub-PreviewActivity(Landroid/webkit/WebView; J Lcom/personal/aihub/PreviewBootstrap; Landroid/widget/TextView; I Ljava/lang/String; Ljava/lang/String;)V
  0028 return-void 
.end method