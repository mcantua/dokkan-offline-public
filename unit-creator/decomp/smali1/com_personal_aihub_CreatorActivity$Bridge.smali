.class Lcom/personal/aihub/CreatorActivity$Bridge;
.super Ljava/lang/Object;
.field parts Ljava/util/Map;
.field this$0 Lcom/personal/aihub/CreatorActivity;

.method <init>(Lcom/personal/aihub/CreatorActivity;)V
  0000 iput-object v1, v0, Lcom/personal/aihub/CreatorActivity$Bridge;->this$0 Lcom/personal/aihub/CreatorActivity;
  0004 invoke-direct v0, Ljava/lang/Object;-><init>()V
  000a new-instance v1, Ljava/util/HashMap;
  000e invoke-direct v1, Ljava/util/HashMap;-><init>()V
  0014 iput-object v1, v0, Lcom/personal/aihub/CreatorActivity$Bridge;->parts Ljava/util/Map;
  0018 return-void 
.end method

.method m19lambda$0$compersonalaihubCreatorActivity$Bridge(I Ljava/lang/String; Lorg/json/JSONObject;)V
  0000 iget-object v0, v1, Lcom/personal/aihub/CreatorActivity$Bridge;->this$0 Lcom/personal/aihub/CreatorActivity;
  0004 invoke-virtual v0, v2, v3, v4, Lcom/personal/aihub/CreatorActivity;->pick(I Ljava/lang/String; Lorg/json/JSONObject;)V
  000a return-void 
.end method

.method m20lambda$1$compersonalaihubCreatorActivity$Bridge(I Ljava/lang/String; Lorg/json/JSONObject;)V
  0000 const/4 v0, 0
  0002 iget-object v1, v2, Lcom/personal/aihub/CreatorActivity$Bridge;->this$0 Lcom/personal/aihub/CreatorActivity;
  0006 invoke-virtual v1, v4, v5, Lcom/personal/aihub/CreatorActivity;->dispatch(Ljava/lang/String; Lorg/json/JSONObject;)Ljava/lang/Object;
  000c move-result-object v4
  000e invoke-virtual v1, v3, v4, v0, Lcom/personal/aihub/CreatorActivity;->reply(I Ljava/lang/Object; Ljava/lang/Exception;)V
  0014 goto +7h
  0016 move-exception v4
  0018 iget-object v5, v2, Lcom/personal/aihub/CreatorActivity$Bridge;->this$0 Lcom/personal/aihub/CreatorActivity;
  001c invoke-virtual v5, v3, v0, v4, Lcom/personal/aihub/CreatorActivity;->reply(I Ljava/lang/Object; Ljava/lang/Exception;)V
  0022 return-void 
.end method

.method postMessage(Ljava/lang/String;)V
  0000 const-string v0, "args"
  0004 const-string v1, "Request "
  0008 new-instance v2, Lorg/json/JSONObject;
  000c invoke-direct v2, v7, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0012 const-string v7, "id"
  0016 invoke-virtual v2, v7, Lorg/json/JSONObject;->getInt(Ljava/lang/String;)I
  001c move-result v7
  001e const-string v3, "method"
  0022 invoke-virtual v2, v3, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0028 move-result-object v3
  002a const-string v4, "ForgeBridge"
  002e new-instance v5, Ljava/lang/StringBuilder;
  0032 invoke-direct v5, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0038 invoke-virtual v5, v7, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  003e const-string v1, " "
  0042 invoke-virtual v5, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0048 invoke-virtual v5, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  004e invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0054 move-result-object v1
  0056 invoke-static v4, v1, Landroid/util/Log;->d(Ljava/lang/String; Ljava/lang/String;)I
  005c invoke-virtual v2, v0, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0062 move-result-object v1
  0064 if-nez v1, +008h
  0068 new-instance v0, Lorg/json/JSONObject;
  006c invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  0072 goto +5h
  0074 invoke-virtual v2, v0, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  007a move-result-object v0
  007c const-string v1, "importStatus"
  0080 invoke-virtual v3, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0086 move-result v1
  0088 if-eqz v1, +00dh
  008c iget-object v0, v6, Lcom/personal/aihub/CreatorActivity$Bridge;->this$0 Lcom/personal/aihub/CreatorActivity;
  0090 invoke-static v0, Lcom/personal/aihub/CreatorActivity;->access$200(Lcom/personal/aihub/CreatorActivity;)Lorg/json/JSONObject;
  0096 move-result-object v1
  0098 const/4 v2, 0
  009a invoke-virtual v0, v7, v1, v2, Lcom/personal/aihub/CreatorActivity;->reply(I Ljava/lang/Object; Ljava/lang/Exception;)V
  00a0 return-void 
  00a2 const-string v1, "import"
  00a6 invoke-virtual v3, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00ac move-result v1
  00ae if-nez v1, +021h
  00b2 const-string v1, "importApk"
  00b6 invoke-virtual v3, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00bc move-result v1
  00be if-nez v1, +019h
  00c2 const-string v1, "export"
  00c6 invoke-virtual v3, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00cc move-result v1
  00ce if-nez v1, +011h
  00d2 iget-object v1, v6, Lcom/personal/aihub/CreatorActivity$Bridge;->this$0 Lcom/personal/aihub/CreatorActivity;
  00d6 invoke-static v1, Lcom/personal/aihub/CreatorActivity;->access$300(Lcom/personal/aihub/CreatorActivity;)Ljava/util/concurrent/ExecutorService;
  00dc move-result-object v1
  00de new-instance v2, Lcom/personal/aihub/CreatorActivity$Bridge$1;
  00e2 invoke-direct v2, v6, v7, v3, v0, Lcom/personal/aihub/CreatorActivity$Bridge$1;-><init>(Lcom/personal/aihub/CreatorActivity$Bridge; I Ljava/lang/String; Lorg/json/JSONObject;)V
  00e8 invoke-interface v1, v2, Ljava/util/concurrent/ExecutorService;->execute(Ljava/lang/Runnable;)V
  00ee return-void 
  00f0 iget-object v1, v6, Lcom/personal/aihub/CreatorActivity$Bridge;->this$0 Lcom/personal/aihub/CreatorActivity;
  00f4 new-instance v2, Lcom/personal/aihub/CreatorActivity$Bridge$2;
  00f8 invoke-direct v2, v6, v7, v3, v0, Lcom/personal/aihub/CreatorActivity$Bridge$2;-><init>(Lcom/personal/aihub/CreatorActivity$Bridge; I Ljava/lang/String; Lorg/json/JSONObject;)V
  00fe invoke-virtual v1, v2, Lcom/personal/aihub/CreatorActivity;->runOnUiThread(Ljava/lang/Runnable;)V
  0104 return-void 
.end method

.method postMessageChunk(I I I Ljava/lang/String;)V
  0000 monitor-enter v4
  0002 const/4 v0, 1
  0004 if-lt v5, v0, +088h
  0008 if-ltz v6, +086h
  000c if-lt v7, v0, +084h
  0010 const/16 v1, 1024
  0014 if-gt v7, v1, +080h
  0018 if-ge v6, v7, +07eh
  001c if-eqz v8, +07ch
  0020 invoke-virtual v8, Ljava/lang/String;->length()I
  0026 move-result v1
  0028 const/16 v2, 24000
  002c if-gt v1, v2, +074h
  0030 if-nez v6, +023h
  0034 iget-object v1, v4, Lcom/personal/aihub/CreatorActivity$Bridge;->parts Ljava/util/Map;
  0038 invoke-interface v1, Ljava/util/Map;->size()I
  003e move-result v1
  0040 const/16 v2, 8
  0044 if-ge v1, v2, +011h
  0048 iget-object v1, v4, Lcom/personal/aihub/CreatorActivity$Bridge;->parts Ljava/util/Map;
  004c invoke-static v5, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0052 move-result-object v2
  0054 new-instance v3, Ljava/lang/StringBuilder;
  0058 invoke-direct v3, Ljava/lang/StringBuilder;-><init>()V
  005e invoke-interface v1, v2, v3, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0064 goto +9h
  0066 new-instance v6, Ljava/io/IOException;
  006a const-string v7, "Too many pending transfers"
  006e invoke-direct v6, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0074 throw v6
  0076 iget-object v1, v4, Lcom/personal/aihub/CreatorActivity$Bridge;->parts Ljava/util/Map;
  007a invoke-static v5, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0080 move-result-object v2
  0082 invoke-interface v1, v2, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0088 move-result-object v1
  008a check-cast v1, Ljava/lang/StringBuilder;
  008e if-eqz v1, +026h
  0092 invoke-virtual v1, Ljava/lang/StringBuilder;->length()I
  0098 move-result v2
  009a invoke-virtual v8, Ljava/lang/String;->length()I
  00a0 move-result v3
  00a2 add-int/2addr v2, v3
  00a4 const/high16 v3, 20971520
  00a8 if-gt v2, v3, +019h
  00ac invoke-virtual v1, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00b2 sub-int/2addr v7, v0
  00b4 if-ne v6, v7, +030h
  00b8 iget-object v6, v4, Lcom/personal/aihub/CreatorActivity$Bridge;->parts Ljava/util/Map;
  00bc invoke-static v5, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  00c2 move-result-object v7
  00c4 invoke-interface v6, v7, Ljava/util/Map;->remove(Ljava/lang/Object;)Ljava/lang/Object;
  00ca invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00d0 move-result-object v6
  00d2 invoke-virtual v4, v6, Lcom/personal/aihub/CreatorActivity$Bridge;->postMessage(Ljava/lang/String;)V
  00d8 goto +1eh
  00da new-instance v6, Ljava/io/IOException;
  00de const-string v7, "Project transfer exceeds 20 MB"
  00e2 invoke-direct v6, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00e8 throw v6
  00ea move-exception v5
  00ec goto +12h
  00ee move-exception v6
  00f0 iget-object v7, v4, Lcom/personal/aihub/CreatorActivity$Bridge;->parts Ljava/util/Map;
  00f4 invoke-static v5, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  00fa move-result-object v8
  00fc invoke-interface v7, v8, Ljava/util/Map;->remove(Ljava/lang/Object;)Ljava/lang/Object;
  0102 iget-object v7, v4, Lcom/personal/aihub/CreatorActivity$Bridge;->this$0 Lcom/personal/aihub/CreatorActivity;
  0106 const/4 v8, 0
  0108 invoke-virtual v7, v5, v8, v6, Lcom/personal/aihub/CreatorActivity;->reply(I Ljava/lang/Object; Ljava/lang/Exception;)V
  010e goto +3h
  0110 monitor-exit v4
  0112 throw v5
  0114 monitor-exit v4
  0116 return-void 
.end method