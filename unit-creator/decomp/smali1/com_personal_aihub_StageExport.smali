.class Lcom/personal/aihub/StageExport;
.super Ljava/lang/Object;
.field REQUEST I
.field closed Z
.field file Ljava/io/File;
.field owner Landroid/app/Activity;
.field pending Ljava/util/concurrent/CompletableFuture;

.method <init>(Landroid/app/Activity;)V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 iput-object v1, v0, Lcom/personal/aihub/StageExport;->owner Landroid/app/Activity;
  000a return-void 
.end method

.method finish(Z Ljava/lang/Exception;)V
  0000 monitor-enter v1
  0002 iget-object v0, v1, Lcom/personal/aihub/StageExport;->pending Ljava/util/concurrent/CompletableFuture;
  0006 if-eqz v0, +00fh
  000a if-nez v3, +00ah
  000e invoke-static v2, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;
  0014 move-result-object v2
  0016 invoke-virtual v0, v2, Ljava/util/concurrent/CompletableFuture;->complete(Ljava/lang/Object;)Z
  001c goto +4h
  001e invoke-virtual v0, v3, Ljava/util/concurrent/CompletableFuture;->completeExceptionally(Ljava/lang/Throwable;)Z
  0024 monitor-exit v1
  0026 return-void 
  0028 move-exception v2
  002a monitor-exit v1
  002c throw v2
.end method

.method close()V
  0000 monitor-enter v2
  0002 const/4 v0, 1
  0004 iput-boolean v0, v2, Lcom/personal/aihub/StageExport;->closed Z
  0008 new-instance v0, Ljava/io/IOException;
  000c const-string v1, "The animation preview was closed."
  0010 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0016 const/4 v1, 0
  0018 invoke-direct v2, v1, v0, Lcom/personal/aihub/StageExport;->finish(Z Ljava/lang/Exception;)V
  001e monitor-exit v2
  0020 return-void 
  0022 move-exception v0
  0024 monitor-exit v2
  0026 throw v0
.end method

.method m39lambda$0$compersonalaihubStageExport()V
  0000 iget-object v0, v4, Lcom/personal/aihub/StageExport;->owner Landroid/app/Activity;
  0004 invoke-virtual v0, Landroid/app/Activity;->isFinishing()Z
  000a move-result v0
  000c if-nez v0, +025h
  0010 iget-object v0, v4, Lcom/personal/aihub/StageExport;->owner Landroid/app/Activity;
  0014 new-instance v1, Landroid/content/Intent;
  0018 const-string v2, "android.intent.action.CREATE_DOCUMENT"
  001c invoke-direct v1, v2, Landroid/content/Intent;-><init>(Ljava/lang/String;)V
  0022 const-string v2, "android.intent.category.OPENABLE"
  0026 invoke-virtual v1, v2, Landroid/content/Intent;->addCategory(Ljava/lang/String;)Landroid/content/Intent;
  002c move-result-object v1
  002e const-string v2, "video/mp4"
  0032 invoke-virtual v1, v2, Landroid/content/Intent;->setType(Ljava/lang/String;)Landroid/content/Intent;
  0038 move-result-object v1
  003a const-string v2, "android.intent.extra.TITLE"
  003e const-string v3, "animation-recording.mp4"
  0042 invoke-virtual v1, v2, v3, Landroid/content/Intent;->putExtra(Ljava/lang/String; Ljava/lang/String;)Landroid/content/Intent;
  0048 move-result-object v1
  004a const/16 v2, 531
  004e invoke-virtual v0, v1, v2, Landroid/app/Activity;->startActivityForResult(Landroid/content/Intent; I)V
  0054 goto +eh
  0056 new-instance v0, Ljava/io/IOException;
  005a const-string v1, "The animation preview is closed."
  005e invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0064 throw v0
  0066 move-exception v0
  0068 const/4 v1, 0
  006a invoke-direct v4, v1, v0, Lcom/personal/aihub/StageExport;->finish(Z Ljava/lang/Exception;)V
  0070 return-void 
.end method

.method m40lambda$1$compersonalaihubStageExport(Ljava/io/File; Landroid/net/Uri;)V
  0000 const/4 v0, 0
  0002 if-eqz v11, +08ah
  0006 invoke-virtual v11, Ljava/io/File;->length()J
  000c move-result-wide v1
  000e const-wide/16 v3, 12
  0012 cmp-long v1, v1, v3
  0016 if-ltz v1, +080h
  001a invoke-virtual v11, Ljava/io/File;->length()J
  0020 move-result-wide v1
  0022 const-wide/32 v3, 167772160
  0028 cmp-long v1, v1, v3
  002c if-gtz v1, +075h
  0030 new-instance v1, Ljava/io/FileInputStream;
  0034 invoke-direct v1, v11, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  003a iget-object v11, v10, Lcom/personal/aihub/StageExport;->owner Landroid/app/Activity;
  003e invoke-virtual v11, Landroid/app/Activity;->getContentResolver()Landroid/content/ContentResolver;
  0044 move-result-object v11
  0046 const-string v2, "wt"
  004a invoke-virtual v11, v12, v2, Landroid/content/ContentResolver;->openOutputStream(Landroid/net/Uri; Ljava/lang/String;)Ljava/io/OutputStream;
  0050 move-result-object v11
  0052 if-eqz v11, +045h
  0056 const/high16 v2, 65536
  005a new-array v2, v2, [B
  005e const-wide/16 v5, 0
  0062 invoke-virtual v1, v2, Ljava/io/FileInputStream;->read([B)I
  0068 move-result v7
  006a const/4 v8, -1
  006c if-eq v7, v8, +025h
  0070 monitor-enter v10
  0072 iget-boolean v8, v10, Lcom/personal/aihub/StageExport;->closed Z
  0076 if-nez v8, +015h
  007a monitor-exit v10
  007c int-to-long v8, v7
  007e add-long/2addr v5, v8
  0080 cmp-long v8, v5, v3
  0084 if-gtz v8, +006h
  0088 invoke-virtual v11, v2, v0, v7, Ljava/io/OutputStream;->write([B I I)V
  008e goto -16h
  0090 new-instance v2, Ljava/io/IOException;
  0094 const-string v3, "The recording exceeds160MiB."
  0098 invoke-direct v2, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  009e throw v2
  00a0 new-instance v2, Ljava/io/IOException;
  00a4 const-string v3, "The animation preview is closed."
  00a8 invoke-direct v2, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00ae throw v2
  00b0 move-exception v2
  00b2 monitor-exit v10
  00b4 throw v2
  00b6 invoke-virtual v11, Ljava/io/OutputStream;->flush()V
  00bc if-eqz v11, +005h
  00c0 invoke-virtual v11, Ljava/io/OutputStream;->close()V
  00c6 invoke-virtual v1, Ljava/io/FileInputStream;->close()V
  00cc const/4 v11, 1
  00ce const/4 v1, 0
  00d0 invoke-direct v10, v11, v1, Lcom/personal/aihub/StageExport;->finish(Z Ljava/lang/Exception;)V
  00d6 goto +35h
  00d8 move-exception v2
  00da goto +9h
  00dc new-instance v2, Ljava/io/IOException;
  00e0 const-string v3, "The selected destination is unavailable."
  00e4 invoke-direct v2, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00ea throw v2
  00ec if-eqz v11, +00ah
  00f0 invoke-virtual v11, Ljava/io/OutputStream;->close()V
  00f6 goto +5h
  00f8 move-exception v11
  00fa invoke-virtual v2, v11, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0100 throw v2
  0102 move-exception v11
  0104 invoke-virtual v1, Ljava/io/FileInputStream;->close()V
  010a goto +5h
  010c move-exception v1
  010e invoke-virtual v11, v1, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0114 throw v11
  0116 new-instance v11, Ljava/io/IOException;
  011a const-string v1, "The recording is unavailable."
  011e invoke-direct v11, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0124 throw v11
  0126 move-exception v11
  0128 iget-object v1, v10, Lcom/personal/aihub/StageExport;->owner Landroid/app/Activity;
  012c invoke-virtual v1, Landroid/app/Activity;->getContentResolver()Landroid/content/ContentResolver;
  0132 move-result-object v1
  0134 invoke-static v1, v12, Landroid/provider/DocumentsContract;->deleteDocument(Landroid/content/ContentResolver; Landroid/net/Uri;)Z
  013a invoke-direct v10, v0, v11, Lcom/personal/aihub/StageExport;->finish(Z Ljava/lang/Exception;)V
  0140 return-void 
.end method

.method result(I I Landroid/content/Intent;)V
  0000 const/16 v0, 531
  0004 if-eq v2, v0, +003h
  0008 return-void 
  000a monitor-enter v1
  000c iget-object v2, v1, Lcom/personal/aihub/StageExport;->pending Ljava/util/concurrent/CompletableFuture;
  0010 if-nez v2, +004h
  0014 monitor-exit v1
  0016 return-void 
  0018 iget-object v2, v1, Lcom/personal/aihub/StageExport;->file Ljava/io/File;
  001c const/4 v0, -1
  001e if-ne v3, v0, +01fh
  0022 if-eqz v4, +01dh
  0026 invoke-virtual v4, Landroid/content/Intent;->getData()Landroid/net/Uri;
  002c move-result-object v3
  002e if-nez v3, +003h
  0032 goto +15h
  0034 invoke-virtual v4, Landroid/content/Intent;->getData()Landroid/net/Uri;
  003a move-result-object v3
  003c new-instance v4, Ljava/lang/Thread;
  0040 new-instance v0, Lcom/personal/aihub/StageExport$2;
  0044 invoke-direct v0, v1, v2, v3, Lcom/personal/aihub/StageExport$2;-><init>(Lcom/personal/aihub/StageExport; Ljava/io/File; Landroid/net/Uri;)V
  004a const-string v2, "forge-recording-save"
  004e invoke-direct v4, v0, v2, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable; Ljava/lang/String;)V
  0054 invoke-virtual v4, Ljava/lang/Thread;->start()V
  005a goto +6h
  005c const/4 v2, 0
  005e const/4 v3, 0
  0060 invoke-direct v1, v2, v3, Lcom/personal/aihub/StageExport;->finish(Z Ljava/lang/Exception;)V
  0066 monitor-exit v1
  0068 return-void 
  006a move-exception v2
  006c monitor-exit v1
  006e throw v2
.end method

.method save(Ljava/io/File;)Z
  0000 monitor-enter v3
  0002 iget-boolean v0, v3, Lcom/personal/aihub/StageExport;->closed Z
  0006 if-nez v0, +041h
  000a iget-object v0, v3, Lcom/personal/aihub/StageExport;->pending Ljava/util/concurrent/CompletableFuture;
  000e if-nez v0, +03dh
  0012 new-instance v0, Ljava/util/concurrent/CompletableFuture;
  0016 invoke-direct v0, Ljava/util/concurrent/CompletableFuture;-><init>()V
  001c iput-object v0, v3, Lcom/personal/aihub/StageExport;->pending Ljava/util/concurrent/CompletableFuture;
  0020 iput-object v4, v3, Lcom/personal/aihub/StageExport;->file Ljava/io/File;
  0024 monitor-exit v3
  0026 iget-object v4, v3, Lcom/personal/aihub/StageExport;->owner Landroid/app/Activity;
  002a new-instance v1, Lcom/personal/aihub/StageExport$1;
  002e invoke-direct v1, v3, Lcom/personal/aihub/StageExport$1;-><init>(Lcom/personal/aihub/StageExport;)V
  0034 invoke-virtual v4, v1, Landroid/app/Activity;->runOnUiThread(Ljava/lang/Runnable;)V
  003a const/4 v4, 0
  003c invoke-virtual v0, Ljava/util/concurrent/CompletableFuture;->get()Ljava/lang/Object;
  0042 move-result-object v1
  0044 check-cast v1, Ljava/lang/Boolean;
  0048 invoke-virtual v1, Ljava/lang/Boolean;->booleanValue()Z
  004e move-result v1
  0050 monitor-enter v3
  0052 iget-object v2, v3, Lcom/personal/aihub/StageExport;->pending Ljava/util/concurrent/CompletableFuture;
  0056 if-ne v2, v0, +006h
  005a iput-object v4, v3, Lcom/personal/aihub/StageExport;->pending Ljava/util/concurrent/CompletableFuture;
  005e iput-object v4, v3, Lcom/personal/aihub/StageExport;->file Ljava/io/File;
  0062 monitor-exit v3
  0064 return v1
  0066 move-exception v1
  0068 monitor-exit v3
  006a throw v1
  006c move-exception v1
  006e monitor-enter v3
  0070 iget-object v2, v3, Lcom/personal/aihub/StageExport;->pending Ljava/util/concurrent/CompletableFuture;
  0074 if-ne v2, v0, +006h
  0078 iput-object v4, v3, Lcom/personal/aihub/StageExport;->pending Ljava/util/concurrent/CompletableFuture;
  007c iput-object v4, v3, Lcom/personal/aihub/StageExport;->file Ljava/io/File;
  0080 throw v1
  0082 move-exception v4
  0084 monitor-exit v3
  0086 throw v4
  0088 new-instance v4, Ljava/io/IOException;
  008c const-string v0, "Finish the existing recording save dialog first."
  0090 invoke-direct v4, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0096 throw v4
  0098 move-exception v4
  009a monitor-exit v3
  009c throw v4
.end method