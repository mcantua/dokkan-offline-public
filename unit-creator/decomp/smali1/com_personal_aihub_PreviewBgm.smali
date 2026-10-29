.class Lcom/personal/aihub/PreviewBgm;
.super Ljava/lang/Object;
.field assets Lcom/personal/aihub/GameAssets;
.field banks Lcom/personal/aihub/AudioBanks;
.field cached Lorg/json/JSONObject;
.field closed Z
.field context Lorg/json/JSONObject;
.field root Ljava/io/File;

.method <init>(Landroid/database/sqlite/SQLiteDatabase; Ljava/io/File; Lcom/personal/aihub/GameAssets; Ljava/lang/String;)V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 iput-object v2, v0, Lcom/personal/aihub/PreviewBgm;->root Ljava/io/File;
  000a iput-object v3, v0, Lcom/personal/aihub/PreviewBgm;->assets Lcom/personal/aihub/GameAssets;
  000e invoke-static v1, v4, Lcom/personal/aihub/GameBgm;->context(Landroid/database/sqlite/SQLiteDatabase; Ljava/lang/String;)Lorg/json/JSONObject;
  0014 move-result-object v1
  0016 iput-object v1, v0, Lcom/personal/aihub/PreviewBgm;->context Lorg/json/JSONObject;
  001a return-void 
.end method

.method close()V
  0000 monitor-enter v1
  0002 const/4 v0, 1
  0004 iput-boolean v0, v1, Lcom/personal/aihub/PreviewBgm;->closed Z
  0008 iget-object v0, v1, Lcom/personal/aihub/PreviewBgm;->banks Lcom/personal/aihub/AudioBanks;
  000c if-eqz v0, +005h
  0010 invoke-virtual v0, Lcom/personal/aihub/AudioBanks;->close()V
  0016 const/4 v0, 0
  0018 iput-object v0, v1, Lcom/personal/aihub/PreviewBgm;->cached Lorg/json/JSONObject;
  001c monitor-exit v1
  001e return-void 
  0020 move-exception v0
  0022 monitor-exit v1
  0024 throw v0
.end method

.method descriptor()Lorg/json/JSONObject;
  0000 const-string v0, "se/"
  0004 const-string v1, "se/"
  0008 monitor-enter v12
  000a iget-boolean v2, v12, Lcom/personal/aihub/PreviewBgm;->closed Z
  000e if-nez v2, +170h
  0012 iget-object v2, v12, Lcom/personal/aihub/PreviewBgm;->cached Lorg/json/JSONObject;
  0016 if-eqz v2, +00fh
  001a new-instance v0, Lorg/json/JSONObject;
  001e iget-object v1, v12, Lcom/personal/aihub/PreviewBgm;->cached Lorg/json/JSONObject;
  0022 invoke-virtual v1, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0028 move-result-object v1
  002a invoke-direct v0, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0030 goto/16 +15dh
  0034 new-instance v2, Lorg/json/JSONObject;
  0038 invoke-direct v2, Lorg/json/JSONObject;-><init>()V
  003e const-string v3, "version"
  0042 const/4 v4, 1
  0044 invoke-virtual v2, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  004a move-result-object v2
  004c const-string v3, "context"
  0050 iget-object v5, v12, Lcom/personal/aihub/PreviewBgm;->context Lorg/json/JSONObject;
  0054 invoke-virtual v2, v3, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  005a move-result-object v2
  005c iget-object v3, v12, Lcom/personal/aihub/PreviewBgm;->context Lorg/json/JSONObject;
  0060 const-string v5, "found"
  0064 invoke-virtual v3, v5, Lorg/json/JSONObject;->optBoolean(Ljava/lang/String;)Z
  006a move-result v3
  006c if-eqz v3, +12ah
  0070 iget-object v3, v12, Lcom/personal/aihub/PreviewBgm;->root Ljava/io/File;
  0074 iget-object v5, v12, Lcom/personal/aihub/PreviewBgm;->assets Lcom/personal/aihub/GameAssets;
  0078 iget-object v6, v12, Lcom/personal/aihub/PreviewBgm;->context Lorg/json/JSONObject;
  007c invoke-static v3, v5, v6, Lcom/personal/aihub/GameBgm;->source(Ljava/io/File; Lcom/personal/aihub/GameAssets; Lorg/json/JSONObject;)[Ljava/lang/String;
  0082 move-result-object v3
  0084 iget-object v5, v12, Lcom/personal/aihub/PreviewBgm;->context Lorg/json/JSONObject;
  0088 const-string v6, "package"
  008c invoke-virtual v5, v6, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0092 move-result-object v5
  0094 if-eqz v3, +0ceh
  0098 new-instance v6, Lcom/personal/aihub/AudioBanks;
  009c iget-object v7, v12, Lcom/personal/aihub/PreviewBgm;->root Ljava/io/File;
  00a0 new-instance v8, Lorg/json/JSONArray;
  00a4 invoke-direct v8, Lorg/json/JSONArray;-><init>()V
  00aa new-instance v9, Lorg/json/JSONObject;
  00ae invoke-direct v9, Lorg/json/JSONObject;-><init>()V
  00b4 const-string v10, "path"
  00b8 new-instance v11, Ljava/lang/StringBuilder;
  00bc invoke-direct v11, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  00c2 invoke-virtual v11, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00c8 const-string v1, ".acb"
  00cc invoke-virtual v11, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00d2 invoke-virtual v11, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00d8 move-result-object v1
  00da invoke-virtual v9, v10, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00e0 move-result-object v1
  00e2 const-string v9, "key"
  00e6 const/4 v10, 0
  00e8 aget-object v11, v3, v10
  00ec invoke-virtual v1, v9, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00f2 move-result-object v1
  00f4 invoke-virtual v8, v1, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  00fa move-result-object v1
  00fc new-instance v8, Lorg/json/JSONObject;
  0100 invoke-direct v8, Lorg/json/JSONObject;-><init>()V
  0106 const-string v9, "path"
  010a new-instance v11, Ljava/lang/StringBuilder;
  010e invoke-direct v11, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0114 invoke-virtual v11, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  011a const-string v0, ".awb"
  011e invoke-virtual v11, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0124 invoke-virtual v11, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  012a move-result-object v0
  012c invoke-virtual v8, v9, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0132 move-result-object v0
  0134 const-string v5, "key"
  0138 aget-object v3, v3, v4
  013c invoke-virtual v0, v5, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0142 move-result-object v0
  0144 invoke-virtual v1, v0, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  014a move-result-object v0
  014c const/4 v1, 0
  014e invoke-direct v6, v7, v1, v0, v4, Lcom/personal/aihub/AudioBanks;-><init>(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray; Z)V
  0154 invoke-virtual v6, Lcom/personal/aihub/AudioBanks;->catalogue()Lorg/json/JSONObject;
  015a move-result-object v0
  015c const-string v1, "banks"
  0160 invoke-virtual v0, v1, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0166 move-result-object v0
  0168 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  016e move-result v1
  0170 if-ne v1, v4, +058h
  0174 invoke-virtual v0, v10, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  017a move-result-object v1
  017c const-string v3, "acb"
  0180 invoke-virtual v1, v3, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0186 move-result-object v1
  0188 invoke-virtual v0, v10, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  018e move-result-object v0
  0190 const-string v3, "awb"
  0194 invoke-virtual v0, v3, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  019a move-result-object v0
  019c const-string v3, "url"
  01a0 const-string v4, "url"
  01a4 invoke-virtual v1, v4, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  01aa move-result-object v4
  01ac const-string v5, "/audio-bank-assets/"
  01b0 const-string v7, "/bgm-bank-assets/"
  01b4 invoke-virtual v4, v5, v7, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  01ba move-result-object v4
  01bc invoke-virtual v1, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01c2 const-string v3, "url"
  01c6 const-string v4, "url"
  01ca invoke-virtual v0, v4, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  01d0 move-result-object v4
  01d2 const-string v5, "/audio-bank-assets/"
  01d6 const-string v7, "/bgm-bank-assets/"
  01da invoke-virtual v4, v5, v7, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  01e0 move-result-object v4
  01e2 invoke-virtual v0, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01e8 iput-object v6, v12, Lcom/personal/aihub/PreviewBgm;->banks Lcom/personal/aihub/AudioBanks;
  01ec new-instance v3, Lorg/json/JSONObject;
  01f0 invoke-direct v3, Lorg/json/JSONObject;-><init>()V
  01f6 const-string v4, "kind"
  01fa const-string v5, "imported"
  01fe invoke-virtual v3, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0204 move-result-object v3
  0206 const-string v4, "acb"
  020a invoke-virtual v3, v4, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0210 move-result-object v1
  0212 const-string v3, "awb"
  0216 invoke-virtual v1, v3, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  021c move-result-object v0
  021e goto +3ch
  0220 new-instance v0, Ljava/io/IOException;
  0224 const-string v1, "Imported move music is ambiguous"
  0228 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  022e throw v0
  0230 new-instance v0, Lorg/json/JSONObject;
  0234 invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  023a const-string v1, "kind"
  023e const-string v3, "public"
  0242 invoke-virtual v0, v1, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0248 move-result-object v0
  024a const-string v1, "acb"
  024e new-instance v3, Lorg/json/JSONObject;
  0252 invoke-direct v3, Lorg/json/JSONObject;-><init>()V
  0258 const-string v4, "url"
  025c const-string v5, "/_forge/bgm-source.acb"
  0260 invoke-virtual v3, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0266 move-result-object v3
  0268 invoke-virtual v0, v1, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  026e move-result-object v0
  0270 const-string v1, "awb"
  0274 new-instance v3, Lorg/json/JSONObject;
  0278 invoke-direct v3, Lorg/json/JSONObject;-><init>()V
  027e const-string v4, "url"
  0282 const-string v5, "/_forge/bgm-source.awb"
  0286 invoke-virtual v3, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  028c move-result-object v3
  028e invoke-virtual v0, v1, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0294 move-result-object v0
  0296 const-string v1, "source"
  029a invoke-virtual v2, v1, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02a0 move-result-object v0
  02a2 iput-object v0, v12, Lcom/personal/aihub/PreviewBgm;->cached Lorg/json/JSONObject;
  02a6 new-instance v0, Lorg/json/JSONObject;
  02aa iget-object v1, v12, Lcom/personal/aihub/PreviewBgm;->cached Lorg/json/JSONObject;
  02ae invoke-virtual v1, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  02b4 move-result-object v1
  02b6 invoke-direct v0, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  02bc monitor-exit v12
  02be return-object v0
  02c0 const-string v0, "source"
  02c4 sget-object v1, Lorg/json/JSONObject;->NULL Ljava/lang/Object;
  02c8 invoke-virtual v2, v0, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02ce move-result-object v0
  02d0 iput-object v0, v12, Lcom/personal/aihub/PreviewBgm;->cached Lorg/json/JSONObject;
  02d4 new-instance v0, Lorg/json/JSONObject;
  02d8 iget-object v1, v12, Lcom/personal/aihub/PreviewBgm;->cached Lorg/json/JSONObject;
  02dc invoke-virtual v1, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  02e2 move-result-object v1
  02e4 invoke-direct v0, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  02ea monitor-exit v12
  02ec return-object v0
  02ee new-instance v0, Ljava/io/IOException;
  02f2 const-string v1, "This music preview has closed"
  02f6 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  02fc throw v0
  02fe move-exception v0
  0300 monitor-exit v12
  0302 throw v0
.end method

.method publicAddress(Ljava/lang/String;)Ljava/lang/String;
  0000 const-string v0, "https://dokkan-eclipse.com/cdn/uncompressed/bgm/"
  0004 monitor-enter v4
  0006 const-string v1, "/_forge/bgm-source.acb"
  000a invoke-virtual v1, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0010 move-result v1
  0012 if-nez v1, +00ah
  0016 const-string v1, "/_forge/bgm-source.awb"
  001a invoke-virtual v1, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0020 move-result v1
  0022 if-eqz v1, +043h
  0026 invoke-virtual v4, Lcom/personal/aihub/PreviewBgm;->descriptor()Lorg/json/JSONObject;
  002c move-result-object v1
  002e const-string v2, "source"
  0032 invoke-virtual v1, v2, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0038 move-result-object v1
  003a if-eqz v1, +037h
  003e const-string v2, "public"
  0042 const-string v3, "kind"
  0046 invoke-virtual v1, v3, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  004c move-result-object v1
  004e invoke-virtual v2, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0054 move-result v1
  0056 if-eqz v1, +029h
  005a new-instance v1, Ljava/lang/StringBuilder;
  005e invoke-direct v1, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0064 iget-object v0, v4, Lcom/personal/aihub/PreviewBgm;->context Lorg/json/JSONObject;
  0068 const-string v2, "package"
  006c invoke-virtual v0, v2, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0072 move-result-object v0
  0074 invoke-virtual v1, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  007a const-string v0, "."
  007e invoke-virtual v1, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0084 invoke-virtual v5, Ljava/lang/String;->length()I
  008a move-result v0
  008c add-int/lit8 v0, v0, -3
  0090 invoke-virtual v5, v0, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0096 move-result-object v5
  0098 invoke-virtual v1, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  009e invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00a4 move-result-object v5
  00a6 goto +2h
  00a8 const/4 v5, 0
  00aa monitor-exit v4
  00ac return-object v5
  00ae move-exception v5
  00b0 monitor-exit v4
  00b2 throw v5
.end method

.method resolve(Ljava/lang/String;)Ljava/io/File;
  0000 monitor-enter v3
  0002 if-eqz v4, +021h
  0006 const-string v0, "https://dokkan-eclipse.com/_forge/bgm-bank-assets/"
  000a invoke-virtual v4, v0, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0010 move-result v0
  0012 if-eqz v0, +019h
  0016 invoke-virtual v3, Lcom/personal/aihub/PreviewBgm;->descriptor()Lorg/json/JSONObject;
  001c iget-object v0, v3, Lcom/personal/aihub/PreviewBgm;->banks Lcom/personal/aihub/AudioBanks;
  0020 if-eqz v0, +012h
  0024 const-string v1, "/bgm-bank-assets/"
  0028 const-string v2, "/audio-bank-assets/"
  002c invoke-virtual v4, v1, v2, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  0032 move-result-object v4
  0034 invoke-virtual v0, v4, Lcom/personal/aihub/AudioBanks;->resolve(Ljava/lang/String;)Ljava/io/File;
  003a move-result-object v4
  003c goto +5h
  003e move-exception v4
  0040 monitor-exit v3
  0042 throw v4
  0044 const/4 v4, 0
  0046 monitor-exit v3
  0048 return-object v4
.end method