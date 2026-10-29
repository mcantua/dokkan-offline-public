.class Lcom/personal/aihub/GameMetadata;
.super Ljava/lang/Object;
.field assets Lcom/personal/aihub/GameAssets;
.field query Lcom/personal/aihub/GameMetadata$Query;
.field rules Lorg/json/JSONObject;

.method <init>(Ljava/io/File; Lcom/personal/aihub/GameMetadata$Query; Lorg/json/JSONObject;)V
  0000 const/4 v0, 0
  0002 invoke-direct v1, v2, v3, v4, v0, Lcom/personal/aihub/GameMetadata;-><init>(Ljava/io/File; Lcom/personal/aihub/GameMetadata$Query; Lorg/json/JSONObject; Ljava/lang/String;)V
  0008 return-void 
.end method

.method <init>(Ljava/io/File; Lcom/personal/aihub/GameMetadata$Query; Lorg/json/JSONObject; Ljava/lang/String;)V
  0000 const/4 v5, 0
  0002 move-object v0, v6
  0004 move-object v1, v7
  0006 move-object v2, v8
  0008 move-object v3, v9
  000a move-object v4, v10
  000c invoke-direct/range v0 ... v5, Lcom/personal/aihub/GameMetadata;-><init>(Ljava/io/File; Lcom/personal/aihub/GameMetadata$Query; Lorg/json/JSONObject; Ljava/lang/String; Lorg/json/JSONArray;)V
  0012 return-void 
.end method

.method <init>(Ljava/io/File; Lcom/personal/aihub/GameMetadata$Query; Lorg/json/JSONObject; Ljava/lang/String; Lorg/json/JSONArray;)V
  0000 invoke-direct v1, Ljava/lang/Object;-><init>()V
  0006 new-instance v0, Lcom/personal/aihub/GameAssets;
  000a invoke-direct v0, v2, v5, v6, Lcom/personal/aihub/GameAssets;-><init>(Ljava/io/File; Ljava/lang/String; Lorg/json/JSONArray;)V
  0010 iput-object v0, v1, Lcom/personal/aihub/GameMetadata;->assets Lcom/personal/aihub/GameAssets;
  0014 iput-object v3, v1, Lcom/personal/aihub/GameMetadata;->query Lcom/personal/aihub/GameMetadata$Query;
  0018 iput-object v4, v1, Lcom/personal/aihub/GameMetadata;->rules Lorg/json/JSONObject;
  001c return-void 
.end method

.method clean(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 if-nez v1, +004h
  0004 const/4 v1, 0
  0006 return-object v1
  0008 new-instance v0, Lorg/json/JSONObject;
  000c invoke-virtual v1, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0012 move-result-object v1
  0014 invoke-direct v0, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  001a const-string v1, "fsPath"
  001e invoke-virtual v0, v1, Lorg/json/JSONObject;->remove(Ljava/lang/String;)Ljava/lang/Object;
  0024 return-object v0
.end method

.method descriptor(Ljava/lang/String;)Lorg/json/JSONObject;
  0000 iget-object v0, v4, Lcom/personal/aihub/GameMetadata;->assets Lcom/personal/aihub/GameAssets;
  0004 new-instance v1, Ljava/lang/StringBuilder;
  0008 const-string v2, "/assets/"
  000c invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0012 invoke-virtual v1, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0018 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  001e move-result-object v1
  0020 invoke-virtual v0, v1, Lcom/personal/aihub/GameAssets;->resolve(Ljava/lang/String;)Ljava/io/File;
  0026 move-result-object v0
  0028 if-nez v0, +004h
  002c const/4 v5, 0
  002e return-object v5
  0030 new-instance v1, Lorg/json/JSONObject;
  0034 invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  003a const-string v3, "rel"
  003e invoke-virtual v1, v3, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0044 move-result-object v1
  0046 new-instance v3, Ljava/lang/StringBuilder;
  004a invoke-direct v3, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0050 invoke-virtual v3, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0056 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  005c move-result-object v5
  005e const-string v2, "url"
  0062 invoke-virtual v1, v2, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0068 move-result-object v5
  006a const-string v1, "bytes"
  006e invoke-virtual v0, Ljava/io/File;->length()J
  0074 move-result-wide v2
  0076 invoke-virtual v5, v1, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  007c move-result-object v5
  007e const-string v1, "source"
  0082 const-string v2, "imported"
  0086 invoke-virtual v5, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  008c move-result-object v5
  008e new-instance v1, Ljava/lang/StringBuilder;
  0092 const-string v2, "imported:"
  0096 invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  009c invoke-virtual v0, Ljava/io/File;->lastModified()J
  00a2 move-result-wide v2
  00a4 invoke-virtual v1, v2, v3, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  00aa const-string v2, ":"
  00ae invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00b4 invoke-virtual v0, Ljava/io/File;->length()J
  00ba move-result-wide v2
  00bc invoke-virtual v1, v2, v3, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  00c2 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00c8 move-result-object v0
  00ca const-string v1, "stamp"
  00ce invoke-virtual v5, v1, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00d4 move-result-object v5
  00d6 return-object v5
.end method

.method first(Ljava/util/List;)Lorg/json/JSONObject;
  0000 invoke-interface v2, Ljava/util/List;->iterator()Ljava/util/Iterator;
  0006 move-result-object v2
  0008 invoke-interface v2, Ljava/util/Iterator;->hasNext()Z
  000e move-result v0
  0010 if-eqz v0, +00fh
  0014 invoke-interface v2, Ljava/util/Iterator;->next()Ljava/lang/Object;
  001a move-result-object v0
  001c check-cast v0, Ljava/lang/String;
  0020 invoke-direct v1, v0, Lcom/personal/aihub/GameMetadata;->descriptor(Ljava/lang/String;)Lorg/json/JSONObject;
  0026 move-result-object v0
  0028 if-eqz v0, -010h
  002c return-object v0
  002e const/4 v2, 0
  0030 return-object v2
.end method

.method merge(Lorg/json/JSONObject; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 if-nez v12, +003h
  0004 return-object v13
  0006 if-eqz v13, +1b1h
  000a const-string v0, "found"
  000e invoke-virtual v13, v0, Lorg/json/JSONObject;->optBoolean(Ljava/lang/String;)Z
  0014 move-result v0
  0016 if-nez v0, +004h
  001a goto/16 +1a7h
  001e const-string v0, "character_id"
  0022 invoke-virtual v12, v0, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  0028 move-result v1
  002a if-nez v1, +095h
  002e const-string v0, "pack_name"
  0032 invoke-virtual v12, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0038 move-result-object v1
  003a invoke-virtual v13, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0040 move-result-object v0
  0042 invoke-virtual v1, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0048 move-result v0
  004a if-eqz v0, +084h
  004e const-string v0, "category"
  0052 const/4 v1, -1
  0054 invoke-virtual v12, v0, v1, Lorg/json/JSONObject;->optInt(Ljava/lang/String; I)I
  005a move-result v2
  005c invoke-virtual v13, v0, v1, Lorg/json/JSONObject;->optInt(Ljava/lang/String; I)I
  0062 move-result v0
  0064 if-eq v2, v0, +004h
  0068 goto/16 +075h
  006c new-instance v0, Lorg/json/JSONObject;
  0070 invoke-virtual v13, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0076 move-result-object v1
  0078 invoke-direct v0, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  007e invoke-virtual v12, Lorg/json/JSONObject;->keys()Ljava/util/Iterator;
  0084 move-result-object v1
  0086 invoke-interface v1, Ljava/util/Iterator;->hasNext()Z
  008c move-result v2
  008e if-eqz v2, +010h
  0092 invoke-interface v1, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0098 move-result-object v2
  009a check-cast v2, Ljava/lang/String;
  009e invoke-virtual v12, v2, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  00a4 move-result-object v3
  00a6 invoke-virtual v0, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00ac goto -13h
  00ae const-string v1, "lwf"
  00b2 invoke-virtual v12, v1, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  00b8 move-result-object v2
  00ba const-string v3, "usm"
  00be invoke-virtual v12, v3, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  00c4 move-result-object v4
  00c6 if-nez v2, +006h
  00ca invoke-virtual v13, v1, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  00d0 move-result-object v2
  00d2 if-nez v4, +012h
  00d6 const-string v5, "enemy"
  00da invoke-virtual v12, v5, Lorg/json/JSONObject;->optBoolean(Ljava/lang/String;)Z
  00e0 move-result v12
  00e2 invoke-virtual v13, v5, Lorg/json/JSONObject;->optBoolean(Ljava/lang/String;)Z
  00e8 move-result v5
  00ea if-ne v12, v5, +006h
  00ee invoke-virtual v13, v3, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  00f4 move-result-object v4
  00f6 invoke-static v2, Lcom/personal/aihub/GameMetadata;->clean(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  00fc move-result-object v12
  00fe invoke-static v12, Lcom/personal/aihub/GameMetadata;->nullable(Ljava/lang/Object;)Ljava/lang/Object;
  0104 move-result-object v12
  0106 invoke-virtual v0, v1, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  010c move-result-object v12
  010e invoke-static v4, Lcom/personal/aihub/GameMetadata;->clean(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0114 move-result-object v13
  0116 invoke-static v13, Lcom/personal/aihub/GameMetadata;->nullable(Ljava/lang/Object;)Ljava/lang/Object;
  011c move-result-object v13
  011e invoke-virtual v12, v3, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0124 move-result-object v12
  0126 if-eqz v2, +007h
  012a if-eqz v4, +005h
  012e const-string v1, "both"
  0132 goto +ah
  0134 if-nez v2, +009h
  0138 if-eqz v4, +004h
  013c move-object v1, v3
  013e goto +4h
  0140 const-string v13, "missing"
  0144 move-object v1, v13
  0146 const-string v13, "media"
  014a invoke-virtual v12, v13, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0150 move-result-object v12
  0152 return-object v12
  0154 invoke-virtual v12, v0, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  015a move-result-wide v1
  015c invoke-virtual v13, v0, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  0162 move-result-wide v3
  0164 cmp-long v0, v1, v3
  0168 if-nez v0, +100h
  016c const-string v0, "art_id"
  0170 invoke-virtual v12, v0, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  0176 move-result-wide v1
  0178 invoke-virtual v13, v0, Lorg/json/JSONObject;->optLong(Ljava/lang/String;)J
  017e move-result-wide v3
  0180 cmp-long v0, v1, v3
  0184 if-eqz v0, +004h
  0188 goto/16 +0f0h
  018c new-instance v0, Lorg/json/JSONObject;
  0190 invoke-virtual v13, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0196 move-result-object v1
  0198 invoke-direct v0, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  019e invoke-virtual v12, Lorg/json/JSONObject;->keys()Ljava/util/Iterator;
  01a4 move-result-object v1
  01a6 invoke-interface v1, Ljava/util/Iterator;->hasNext()Z
  01ac move-result v2
  01ae if-eqz v2, +010h
  01b2 invoke-interface v1, Ljava/util/Iterator;->next()Ljava/lang/Object;
  01b8 move-result-object v2
  01ba check-cast v2, Ljava/lang/String;
  01be invoke-virtual v12, v2, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  01c4 move-result-object v3
  01c6 invoke-virtual v0, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  01cc goto -13h
  01ce const-string v1, "battle"
  01d2 const-string v2, "idle"
  01d6 const-string v3, "sp"
  01da const-string v4, "card_bg"
  01de filled-new-array v1, v2, v3, v4, [Ljava/lang/String;
  01e4 move-result-object v1
  01e6 const/4 v2, 0
  01e8 move v5, v2
  01ea const/4 v6, 4
  01ec const-wide/16 v7, 0
  01f0 if-ge v5, v6, +048h
  01f4 aget-object v6, v1, v5
  01f8 invoke-virtual v6, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01fe move-result v9
  0200 if-nez v9, +017h
  0204 invoke-virtual v6, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  020a move-result v9
  020c if-eqz v9, +01fh
  0210 const-string v9, "bg_effect_id"
  0214 invoke-virtual v12, v9, v7, v8, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  021a move-result-wide v10
  021c invoke-virtual v13, v9, v7, v8, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  0222 move-result-wide v7
  0224 cmp-long v7, v10, v7
  0228 if-eqz v7, +011h
  022c goto +dh
  022e const-string v7, "special_motion"
  0232 invoke-virtual v12, v7, v2, Lorg/json/JSONObject;->optInt(Ljava/lang/String; I)I
  0238 move-result v8
  023a invoke-virtual v13, v7, v2, Lorg/json/JSONObject;->optInt(Ljava/lang/String; I)I
  0240 move-result v7
  0242 if-eq v8, v7, +004h
  0246 move v7, v2
  0248 goto +2h
  024a const/4 v7, 1
  024c invoke-virtual v12, v6, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0252 move-result-object v8
  0254 if-nez v8, +008h
  0258 if-eqz v7, +006h
  025c invoke-virtual v13, v6, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0262 move-result-object v8
  0264 invoke-static v8, Lcom/personal/aihub/GameMetadata;->clean(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  026a move-result-object v7
  026c invoke-static v7, Lcom/personal/aihub/GameMetadata;->nullable(Ljava/lang/Object;)Ljava/lang/Object;
  0272 move-result-object v7
  0274 invoke-virtual v0, v6, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  027a add-int/lit8 v5, v5, 1
  027e goto -4ah
  0280 new-instance v1, Lorg/json/JSONObject;
  0284 invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  028a const-string v2, "textures"
  028e invoke-virtual v13, v2, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0294 move-result-object v3
  0296 invoke-virtual v12, v2, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  029c move-result-object v4
  029e if-eqz v3, +022h
  02a2 invoke-virtual v3, Lorg/json/JSONObject;->keys()Ljava/util/Iterator;
  02a8 move-result-object v5
  02aa invoke-interface v5, Ljava/util/Iterator;->hasNext()Z
  02b0 move-result v6
  02b2 if-eqz v6, +018h
  02b6 invoke-interface v5, Ljava/util/Iterator;->next()Ljava/lang/Object;
  02bc move-result-object v6
  02be check-cast v6, Ljava/lang/String;
  02c2 invoke-virtual v3, v6, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  02c8 move-result-object v9
  02ca invoke-static v9, Lcom/personal/aihub/GameMetadata;->clean(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  02d0 move-result-object v9
  02d2 invoke-static v9, Lcom/personal/aihub/GameMetadata;->nullable(Ljava/lang/Object;)Ljava/lang/Object;
  02d8 move-result-object v9
  02da invoke-virtual v1, v6, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  02e0 goto -1bh
  02e2 if-eqz v4, +022h
  02e6 invoke-virtual v4, Lorg/json/JSONObject;->keys()Ljava/util/Iterator;
  02ec move-result-object v3
  02ee invoke-interface v3, Ljava/util/Iterator;->hasNext()Z
  02f4 move-result v5
  02f6 if-eqz v5, +018h
  02fa invoke-interface v3, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0300 move-result-object v5
  0302 check-cast v5, Ljava/lang/String;
  0306 invoke-virtual v4, v5, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  030c move-result-object v6
  030e invoke-static v6, Lcom/personal/aihub/GameMetadata;->clean(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0314 move-result-object v6
  0316 invoke-static v6, Lcom/personal/aihub/GameMetadata;->nullable(Ljava/lang/Object;)Ljava/lang/Object;
  031c move-result-object v6
  031e invoke-virtual v1, v5, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0324 goto -1bh
  0326 invoke-virtual v0, v2, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  032c const-string v1, "aura_effect_id"
  0330 invoke-virtual v12, v1, Lorg/json/JSONObject;->isNull(Ljava/lang/String;)Z
  0336 move-result v2
  0338 if-eqz v2, +017h
  033c const-string v2, "aura_id"
  0340 invoke-virtual v12, v2, v7, v8, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  0346 move-result-wide v3
  0348 invoke-virtual v13, v2, v7, v8, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  034e move-result-wide v5
  0350 cmp-long v12, v3, v5
  0354 if-nez v12, +009h
  0358 invoke-static v13, v1, Lcom/personal/aihub/GameMetadata;->value(Lorg/json/JSONObject; Ljava/lang/String;)Ljava/lang/Object;
  035e move-result-object v12
  0360 invoke-virtual v0, v1, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0366 return-object v0
  0368 return-object v12
.end method

.method nullable(Ljava/lang/Object;)Ljava/lang/Object;
  0000 if-nez v0, +004h
  0004 sget-object v0, Lorg/json/JSONObject;->NULL Ljava/lang/Object;
  0008 return-object v0
.end method

.method paths(Lorg/json/JSONArray; Ljava/lang/String;)Ljava/util/List;
  0000 new-instance v0, Ljava/util/ArrayList;
  0004 invoke-direct v0, Ljava/util/ArrayList;-><init>()V
  000a const/4 v1, 0
  000c invoke-virtual v5, Lorg/json/JSONArray;->length()I
  0012 move-result v2
  0014 if-ge v1, v2, +012h
  0018 invoke-virtual v5, v1, Lorg/json/JSONArray;->getString(I)Ljava/lang/String;
  001e move-result-object v2
  0020 const-string v3, "{pack}"
  0024 invoke-virtual v2, v3, v6, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  002a move-result-object v2
  002c invoke-virtual v0, v2, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0032 add-int/lit8 v1, v1, 1
  0036 goto -15h
  0038 return-object v0
.end method

.method row(Ljava/lang/String; J)Lorg/json/JSONObject;
  0000 iget-object v0, v1, Lcom/personal/aihub/GameMetadata;->query Lcom/personal/aihub/GameMetadata$Query;
  0004 invoke-interface v0, v2, v3, v4, Lcom/personal/aihub/GameMetadata$Query;->row(Ljava/lang/String; J)Lorg/json/JSONObject;
  000a move-result-object v2
  000c return-object v2
  000e const/4 v2, 0
  0010 return-object v2
.end method

.method value(Lorg/json/JSONObject; Ljava/lang/String;)Ljava/lang/Object;
  0000 invoke-virtual v1, v2, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  0006 move-result-object v0
  0008 if-nez v0, +005h
  000c sget-object v1, Lorg/json/JSONObject;->NULL Ljava/lang/Object;
  0010 goto +5h
  0012 invoke-virtual v1, v2, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  0018 move-result-object v1
  001a return-object v1
.end method

.method resolve(Ljava/lang/String;)Lorg/json/JSONObject;
  0000 move-object/from16 v0, v35
  0004 move-object/from16 v1, v36
  0008 const-string v2, "resource_id"
  000c const-string v3, "character_id"
  0010 const-string v4, "_"
  0014 const-string v5, "ingame/battle/character/"
  0018 const-string v6, "special_motion"
  001c const-string v7, "lwf"
  0020 const-string v8, "category"
  0024 const-string v9, "pack_name"
  0028 const-string v10, ".lwf"
  002c const-string v11, "bg_effect_id"
  0030 const-string v12, "https://dokkan-eclipse.com"
  0034 const-string v14, "/"
  0038 invoke-virtual v1, v14, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  003e move-result v14
  0040 if-eqz v14, +00eh
  0044 new-instance v14, Ljava/lang/StringBuilder;
  0048 invoke-direct v14, v12, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  004e invoke-virtual v14, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0054 invoke-virtual v14, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  005a move-result-object v1
  005c new-instance v12, Ljava/net/URI;
  0060 invoke-direct v12, v1, Ljava/net/URI;-><init>(Ljava/lang/String;)V
  0066 const-string v1, "https"
  006a invoke-virtual v12, Ljava/net/URI;->getScheme()Ljava/lang/String;
  0070 move-result-object v14
  0072 invoke-virtual v1, v14, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0078 move-result v1
  007a if-eqz v1, +544h
  007e const-string v1, "dokkan-eclipse.com"
  0082 invoke-virtual v12, Ljava/net/URI;->getHost()Ljava/lang/String;
  0088 move-result-object v14
  008a invoke-virtual v1, v14, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0090 move-result v1
  0092 if-nez v1, +00eh
  0096 const-string v1, "cdn.dokkan-eclipse.com"
  009a invoke-virtual v12, Ljava/net/URI;->getHost()Ljava/lang/String;
  00a0 move-result-object v14
  00a2 invoke-virtual v1, v14, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00a8 move-result v1
  00aa if-eqz v1, +52ah
  00ae invoke-virtual v12, Ljava/net/URI;->getUserInfo()Ljava/lang/String;
  00b4 move-result-object v1
  00b6 if-nez v1, +524h
  00ba invoke-virtual v12, Ljava/net/URI;->getPort()I
  00c0 move-result v1
  00c2 const/4 v14, -1
  00c4 if-ne v1, v14, +51dh
  00c8 invoke-virtual v12, Ljava/net/URI;->getQuery()Ljava/lang/String;
  00ce move-result-object v1
  00d0 const-string v15, "enemy"
  00d4 if-eqz v1, +052h
  00d8 const-string v13, "&"
  00dc invoke-virtual v1, v13, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  00e2 move-result-object v1
  00e4 array-length v13, v1
  00e6 const/4 v14, 0
  00e8 const/16 v17, 0
  00ec if-ge v14, v13, +041h
  00f0 move/from16 v18, v13
  00f4 aget-object v13, v1, v14
  00f8 move-object/from16 v19, v1
  00fc const-string v1, "="
  0100 move-object/from16 v20, v11
  0104 const/4 v11, 2
  0106 invoke-virtual v13, v1, v11, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  010c move-result-object v1
  010e const/4 v11, 0
  0110 aget-object v13, v1, v11
  0114 const-string v11, "patch"
  0118 invoke-virtual v13, v11, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  011e move-result v11
  0120 if-eqz v11, +004h
  0124 const/4 v11, 0
  0126 return-object v11
  0128 array-length v11, v1
  012a const/4 v13, 2
  012c if-ne v11, v13, +018h
  0130 const/4 v11, 0
  0132 aget-object v13, v1, v11
  0136 invoke-virtual v13, v15, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  013c move-result v11
  013e if-eqz v11, +00fh
  0142 const/4 v11, 1
  0144 aget-object v1, v1, v11
  0148 const-string v11, "1"
  014c invoke-virtual v1, v11, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0152 move-result v1
  0154 if-eqz v1, +004h
  0158 const/16 v17, 1
  015c add-int/lit8 v14, v14, 1
  0160 move/from16 v13, v18
  0164 move-object/from16 v1, v19
  0168 move-object/from16 v11, v20
  016c goto -40h
  016e move-object/from16 v20, v11
  0172 move/from16 v1, v17
  0176 goto +4h
  0178 move-object/from16 v20, v11
  017c const/4 v1, 0
  017e const-string v11, "^/api/(card|effect-pack)/([1-9][0-9]{0,14})$"
  0182 invoke-static v11, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;)Ljava/util/regex/Pattern;
  0188 move-result-object v11
  018a invoke-virtual v12, Ljava/net/URI;->getPath()Ljava/lang/String;
  0190 move-result-object v13
  0192 if-nez v13, +005h
  0196 const-string v12, ""
  019a goto +5h
  019c invoke-virtual v12, Ljava/net/URI;->getPath()Ljava/lang/String;
  01a2 move-result-object v12
  01a4 invoke-virtual v11, v12, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;
  01aa move-result-object v11
  01ac invoke-virtual v11, Ljava/util/regex/Matcher;->matches()Z
  01b2 move-result v12
  01b4 if-nez v12, +004h
  01b8 const/4 v12, 0
  01ba return-object v12
  01bc const/4 v12, 2
  01be invoke-virtual v11, v12, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  01c4 move-result-object v13
  01c6 invoke-static v13, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  01cc move-result-wide v12
  01ce const/4 v14, 1
  01d0 invoke-virtual v11, v14, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;
  01d6 move-result-object v11
  01d8 const-string v14, "effect-pack"
  01dc invoke-virtual v11, v14, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  01e2 move-result v11
  01e4 const-string v14, "id"
  01e8 move-object/from16 v17, v4
  01ec const-string v4, "name"
  01f0 if-eqz v11, +14eh
  01f4 const-string v2, "effect_packs"
  01f8 invoke-direct v0, v2, v12, v13, Lcom/personal/aihub/GameMetadata;->row(Ljava/lang/String; J)Lorg/json/JSONObject;
  01fe move-result-object v2
  0200 if-eqz v2, +144h
  0204 invoke-virtual v2, v9, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  020a move-result-object v3
  020c const-string v5, "[-a-zA-Z0-9_]{1,100}"
  0210 invoke-virtual v3, v5, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0216 move-result v3
  0218 if-nez v3, +004h
  021c goto/16 +136h
  0220 invoke-virtual v2, v9, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0226 move-result-object v3
  0228 iget-object v5, v0, Lcom/personal/aihub/GameMetadata;->rules Lorg/json/JSONObject;
  022c const-string v6, "categories"
  0230 invoke-virtual v5, v6, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0236 move-result-object v5
  0238 const/4 v6, -1
  023a invoke-virtual v2, v8, v6, Lorg/json/JSONObject;->optInt(Ljava/lang/String; I)I
  0240 move-result v6
  0242 invoke-static v6, Ljava/lang/String;->valueOf(I)Ljava/lang/String;
  0248 move-result-object v6
  024a invoke-virtual v5, v6, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0250 move-result-object v5
  0252 if-nez v5, +004h
  0256 const/4 v6, 0
  0258 return-object v6
  025a invoke-virtual v5, v7, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  0260 move-result-object v6
  0262 invoke-direct v0, v6, v3, Lcom/personal/aihub/GameMetadata;->paths(Lorg/json/JSONArray; Ljava/lang/String;)Ljava/util/List;
  0268 move-result-object v6
  026a invoke-direct v0, v6, Lcom/personal/aihub/GameMetadata;->first(Ljava/util/List;)Lorg/json/JSONObject;
  0270 move-result-object v6
  0272 new-instance v10, Ljava/util/ArrayList;
  0276 invoke-direct v10, Ljava/util/ArrayList;-><init>()V
  027c const-string v11, "usm"
  0280 if-eqz v1, +031h
  0284 move/from16 v36, v1
  0288 invoke-virtual v5, v11, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  028e move-result-object v1
  0290 move-object/from16 v18, v15
  0294 new-instance v15, Ljava/lang/StringBuilder;
  0298 invoke-direct v15, Ljava/lang/StringBuilder;-><init>()V
  029e move-object/from16 v19, v7
  02a2 invoke-static v3, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  02a8 move-result-object v7
  02aa invoke-virtual v15, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02b0 iget-object v7, v0, Lcom/personal/aihub/GameMetadata;->rules Lorg/json/JSONObject;
  02b4 move-object/from16 v21, v9
  02b8 const-string v9, "enemyMovieSuffix"
  02bc invoke-virtual v7, v9, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  02c2 move-result-object v7
  02c4 invoke-virtual v15, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  02ca invoke-virtual v15, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  02d0 move-result-object v7
  02d2 invoke-direct v0, v1, v7, Lcom/personal/aihub/GameMetadata;->paths(Lorg/json/JSONArray; Ljava/lang/String;)Ljava/util/List;
  02d8 move-result-object v1
  02da invoke-virtual v10, v1, Ljava/util/ArrayList;->addAll(Ljava/util/Collection;)Z
  02e0 goto +9h
  02e2 move/from16 v36, v1
  02e6 move-object/from16 v19, v7
  02ea move-object/from16 v21, v9
  02ee move-object/from16 v18, v15
  02f2 invoke-virtual v5, v11, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;
  02f8 move-result-object v1
  02fa invoke-direct v0, v1, v3, Lcom/personal/aihub/GameMetadata;->paths(Lorg/json/JSONArray; Ljava/lang/String;)Ljava/util/List;
  0300 move-result-object v1
  0302 invoke-virtual v10, v1, Ljava/util/ArrayList;->addAll(Ljava/util/Collection;)Z
  0308 invoke-direct v0, v10, Lcom/personal/aihub/GameMetadata;->first(Ljava/util/List;)Lorg/json/JSONObject;
  030e move-result-object v1
  0310 if-nez v6, +006h
  0314 if-nez v1, +004h
  0318 const/4 v5, 0
  031a return-object v5
  031c new-instance v5, Lorg/json/JSONObject;
  0320 invoke-direct v5, Lorg/json/JSONObject;-><init>()V
  0326 const-string v7, "found"
  032a const/4 v9, 1
  032c invoke-virtual v5, v7, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0332 move-result-object v5
  0334 const-string v7, "forge_local"
  0338 invoke-virtual v5, v7, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  033e move-result-object v5
  0340 invoke-virtual v5, v14, v12, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0346 move-result-object v5
  0348 invoke-virtual v2, v8, Lorg/json/JSONObject;->optInt(Ljava/lang/String;)I
  034e move-result v7
  0350 invoke-virtual v5, v8, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0356 move-result-object v5
  0358 invoke-virtual v2, v4, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  035e move-result-object v7
  0360 invoke-virtual v5, v4, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0366 move-result-object v4
  0368 move-object/from16 v5, v21
  036c invoke-virtual v4, v5, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0372 move-result-object v3
  0374 const-string v4, "scene_name"
  0378 const-string v5, "scene_name"
  037c invoke-virtual v2, v5, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0382 move-result-object v5
  0384 invoke-virtual v3, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  038a move-result-object v3
  038c const-string v4, "rgba"
  0390 new-instance v5, Lorg/json/JSONObject;
  0394 invoke-direct v5, Lorg/json/JSONObject;-><init>()V
  039a const-string v7, "r"
  039e const-string v8, "red"
  03a2 invoke-static v2, v8, Lcom/personal/aihub/GameMetadata;->value(Lorg/json/JSONObject; Ljava/lang/String;)Ljava/lang/Object;
  03a8 move-result-object v8
  03aa invoke-virtual v5, v7, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  03b0 move-result-object v5
  03b2 const-string v7, "g"
  03b6 const-string v8, "green"
  03ba invoke-static v2, v8, Lcom/personal/aihub/GameMetadata;->value(Lorg/json/JSONObject; Ljava/lang/String;)Ljava/lang/Object;
  03c0 move-result-object v8
  03c2 invoke-virtual v5, v7, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  03c8 move-result-object v5
  03ca const-string v7, "b"
  03ce const-string v8, "blue"
  03d2 invoke-static v2, v8, Lcom/personal/aihub/GameMetadata;->value(Lorg/json/JSONObject; Ljava/lang/String;)Ljava/lang/Object;
  03d8 move-result-object v8
  03da invoke-virtual v5, v7, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  03e0 move-result-object v5
  03e2 const-string v7, "a"
  03e6 const-string v8, "alpha"
  03ea invoke-static v2, v8, Lcom/personal/aihub/GameMetadata;->value(Lorg/json/JSONObject; Ljava/lang/String;)Ljava/lang/Object;
  03f0 move-result-object v8
  03f2 invoke-virtual v5, v7, v8, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  03f8 move-result-object v5
  03fa invoke-virtual v3, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0400 move-result-object v3
  0402 const-string v4, "lite_flicker_rate"
  0406 const-string v5, "lite_flicker_rate"
  040a invoke-static v2, v5, Lcom/personal/aihub/GameMetadata;->value(Lorg/json/JSONObject; Ljava/lang/String;)Ljava/lang/Object;
  0410 move-result-object v2
  0412 invoke-virtual v3, v4, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0418 move-result-object v2
  041a const-string v3, "media"
  041e if-eqz v6, +008h
  0422 if-nez v1, +003h
  0426 goto +4h
  0428 const-string v4, "both"
  042c goto +7h
  042e if-eqz v6, +005h
  0432 move-object/from16 v4, v19
  0436 goto +2h
  0438 move-object v4, v11
  043a invoke-virtual v2, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0440 move-result-object v2
  0442 invoke-static v6, Lcom/personal/aihub/GameMetadata;->nullable(Ljava/lang/Object;)Ljava/lang/Object;
  0448 move-result-object v3
  044a move-object/from16 v4, v19
  044e invoke-virtual v2, v4, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0454 move-result-object v2
  0456 invoke-static v1, Lcom/personal/aihub/GameMetadata;->nullable(Ljava/lang/Object;)Ljava/lang/Object;
  045c move-result-object v1
  045e invoke-virtual v2, v11, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0464 move-result-object v1
  0466 move/from16 v2, v36
  046a move-object/from16 v3, v18
  046e invoke-virtual v1, v3, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0474 move-result-object v1
  0476 const-string v2, "dbSource"
  047a const-string v3, "imported"
  047e invoke-virtual v1, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0484 move-result-object v1
  0486 return-object v1
  0488 const/4 v1, 0
  048a return-object v1
  048c const/4 v1, 0
  048e const-string v7, "cards"
  0492 invoke-direct v0, v7, v12, v13, Lcom/personal/aihub/GameMetadata;->row(Ljava/lang/String; J)Lorg/json/JSONObject;
  0498 move-result-object v7
  049a if-nez v7, +003h
  049e return-object v1
  04a0 const-wide/16 v8, -1
  04a4 invoke-virtual v7, v3, v8, v9, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  04aa move-result-wide v8
  04ac move-object v1, v3
  04ae move-object/from16 v36, v4
  04b2 const-wide/16 v3, 0
  04b6 invoke-virtual v7, v2, v3, v4, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  04bc move-result-wide v18
  04be cmp-long v11, v18, v3
  04c2 if-nez v11, +006h
  04c6 invoke-virtual v7, v14, v3, v4, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  04cc move-result-wide v18
  04ce cmp-long v11, v8, v3
  04d2 if-lez v11, +314h
  04d6 const-wide v21, 9007199254740991
  04e0 cmp-long v11, v8, v21
  04e4 if-gtz v11, +30bh
  04e8 cmp-long v11, v18, v3
  04ec if-gtz v11, +004h
  04f0 goto/16 +305h
  04f4 cmp-long v11, v18, v21
  04f8 if-lez v11, +004h
  04fc const/4 v11, 0
  04fe return-object v11
  0500 const-wide/16 v21, 10
  0504 div-long v18, v18, v21
  0508 mul-long v3, v18, v21
  050c const-string v11, "characters"
  0510 invoke-direct v0, v11, v8, v9, Lcom/personal/aihub/GameMetadata;->row(Ljava/lang/String; J)Lorg/json/JSONObject;
  0516 move-result-object v11
  0518 sget-object v15, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  051c move-object/from16 v18, v2
  0520 const-string v2, "%05d"
  0524 invoke-static v8, v9, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  052a move-result-object v19
  052c move-object/from16 v25, v11
  0530 filled-new-array/range v19, [Ljava/lang/Object;
  0536 move-result-object v11
  0538 invoke-static v15, v2, v11, Ljava/lang/String;->format(Ljava/util/Locale; Ljava/lang/String; [Ljava/lang/Object;)Ljava/lang/String;
  053e move-result-object v2
  0540 sget-object v11, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  0544 const-string v15, "%02d"
  0548 move-object/from16 v19, v1
  054c const/4 v1, 0
  054e invoke-virtual v7, v6, v1, Lorg/json/JSONObject;->optInt(Ljava/lang/String; I)I
  0554 move-result v26
  0556 invoke-static/range v26, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  055c move-result-object v1
  055e filled-new-array v1, [Ljava/lang/Object;
  0564 move-result-object v1
  0566 invoke-static v11, v15, v1, Ljava/lang/String;->format(Ljava/util/Locale; Ljava/lang/String; [Ljava/lang/Object;)Ljava/lang/String;
  056c move-result-object v1
  056e new-instance v11, Ljava/lang/StringBuilder;
  0572 invoke-direct v11, Ljava/lang/StringBuilder;-><init>()V
  0578 invoke-virtual v11, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  057e invoke-virtual v11, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0584 const-string v15, "/battle/battle_character_"
  0588 invoke-virtual v11, v15, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  058e invoke-virtual v11, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0594 invoke-virtual v11, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  059a invoke-virtual v11, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  05a0 move-result-object v11
  05a2 invoke-direct v0, v11, Lcom/personal/aihub/GameMetadata;->descriptor(Ljava/lang/String;)Lorg/json/JSONObject;
  05a8 move-result-object v11
  05aa new-instance v15, Ljava/lang/StringBuilder;
  05ae invoke-direct v15, Ljava/lang/StringBuilder;-><init>()V
  05b4 invoke-virtual v15, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  05ba invoke-virtual v15, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  05c0 move-object/from16 v26, v6
  05c4 const-string v6, "/idle/idle_character_"
  05c8 invoke-virtual v15, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  05ce invoke-virtual v15, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  05d4 invoke-virtual v15, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  05da invoke-virtual v15, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  05e0 move-result-object v6
  05e2 invoke-direct v0, v6, Lcom/personal/aihub/GameMetadata;->descriptor(Ljava/lang/String;)Lorg/json/JSONObject;
  05e8 move-result-object v6
  05ea new-instance v15, Ljava/lang/StringBuilder;
  05ee invoke-direct v15, Ljava/lang/StringBuilder;-><init>()V
  05f4 invoke-virtual v15, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  05fa invoke-virtual v15, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0600 const-string v5, "/sp"
  0604 invoke-virtual v15, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  060a invoke-virtual v15, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0610 const-string v5, "/sp_character_"
  0614 invoke-virtual v15, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  061a invoke-virtual v15, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0620 move-object/from16 v2, v17
  0624 invoke-virtual v15, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  062a invoke-virtual v15, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0630 invoke-virtual v15, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0636 invoke-virtual v15, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  063c move-result-object v1
  063e invoke-direct v0, v1, Lcom/personal/aihub/GameMetadata;->descriptor(Ljava/lang/String;)Lorg/json/JSONObject;
  0644 move-result-object v1
  0646 move-wide/from16 v23, v8
  064a move-object/from16 v5, v20
  064e const-wide/16 v8, 0
  0652 invoke-virtual v7, v5, v8, v9, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  0658 move-result-wide v27
  065a cmp-long v15, v27, v8
  065e if-eqz v15, +037h
  0662 new-instance v15, Ljava/lang/StringBuilder;
  0666 invoke-direct v15, Ljava/lang/StringBuilder;-><init>()V
  066c const-string v8, "character/card_bg/"
  0670 invoke-virtual v15, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0676 const-wide/16 v8, 0
  067a invoke-virtual v7, v5, v8, v9, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  0680 move-result-wide v27
  0682 div-long v27, v27, v21
  0686 mul-long v8, v27, v21
  068a invoke-virtual v15, v8, v9, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0690 const-string v8, "/card_"
  0694 invoke-virtual v15, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  069a const-wide/16 v8, 0
  069e invoke-virtual v7, v5, v8, v9, Lorg/json/JSONObject;->optLong(Ljava/lang/String; J)J
  06a4 move-result-wide v8
  06a6 div-long v8, v8, v21
  06aa mul-long v8, v8, v21
  06ae invoke-virtual v15, v8, v9, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  06b4 invoke-virtual v15, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  06ba invoke-virtual v15, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  06c0 move-result-object v8
  06c2 invoke-direct v0, v8, Lcom/personal/aihub/GameMetadata;->descriptor(Ljava/lang/String;)Lorg/json/JSONObject;
  06c8 move-result-object v8
  06ca goto +2h
  06cc const/4 v8, 0
  06ce new-instance v9, Ljava/lang/StringBuilder;
  06d2 invoke-direct v9, Ljava/lang/StringBuilder;-><init>()V
  06d8 const-string v10, "character/card/"
  06dc invoke-virtual v9, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  06e2 invoke-virtual v9, v3, v4, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  06e8 const-string v10, "/card_"
  06ec invoke-virtual v9, v10, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  06f2 invoke-virtual v9, v3, v4, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  06f8 invoke-virtual v9, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  06fe move-result-object v9
  0700 new-instance v10, Lorg/json/JSONObject;
  0704 invoke-direct v10, Lorg/json/JSONObject;-><init>()V
  070a const-string v15, "character"
  070e move-object/from16 v20, v5
  0712 const-string v5, "_character.png"
  0716 filled-new-array v15, v5, [Ljava/lang/String;
  071c move-result-object v27
  071e const-string v5, "effect"
  0722 const-string v15, "_effect.png"
  0726 filled-new-array v5, v15, [Ljava/lang/String;
  072c move-result-object v28
  072e const-string v5, "bg"
  0732 const-string v15, "_bg.png"
  0736 filled-new-array v5, v15, [Ljava/lang/String;
  073c move-result-object v29
  073e const-string v5, "circle"
  0742 const-string v15, "_circle.png"
  0746 filled-new-array v5, v15, [Ljava/lang/String;
  074c move-result-object v30
  074e const-string v5, "cutin"
  0752 const-string v15, "sp_cutin_1.png"
  0756 filled-new-array v5, v15, [Ljava/lang/String;
  075c move-result-object v31
  075e const-string v5, "sp_cutin"
  0762 const-string v15, "sp_cutin_1.png"
  0766 filled-new-array v5, v15, [Ljava/lang/String;
  076c move-result-object v32
  076e filled-new-array/range v27 ... v32, [[Ljava/lang/String;
  0774 move-result-object v5
  0776 move-object/from16 v17, v5
  077a const/4 v15, 0
  077c const/4 v5, 6
  077e if-lt v15, v5, +16ah
  0782 const-string v5, "sp_name"
  0786 const-string v15, "sp_phrase"
  078a filled-new-array v5, v15, [Ljava/lang/String;
  0790 move-result-object v5
  0792 move-object/from16 v16, v7
  0796 const/4 v7, 2
  0798 const/4 v15, 0
  079a if-ge v15, v7, +060h
  079e aget-object v7, v5, v15
  07a2 move-object/from16 v17, v5
  07a6 new-instance v5, Ljava/lang/StringBuilder;
  07aa invoke-direct v5, Ljava/lang/StringBuilder;-><init>()V
  07b0 move-wide/from16 v27, v12
  07b4 const-string v12, "character/card/"
  07b8 invoke-virtual v5, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  07be invoke-virtual v5, v3, v4, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  07c4 const-string v12, "/en/card_"
  07c8 invoke-virtual v5, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  07ce invoke-virtual v5, v3, v4, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  07d4 invoke-virtual v5, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  07da invoke-virtual v5, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  07e0 const-string v12, ".png"
  07e4 invoke-virtual v5, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  07ea invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  07f0 move-result-object v5
  07f2 new-instance v12, Ljava/lang/StringBuilder;
  07f6 invoke-direct v12, Ljava/lang/StringBuilder;-><init>()V
  07fc invoke-static v9, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0802 move-result-object v13
  0804 invoke-virtual v12, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  080a invoke-virtual v12, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0810 invoke-virtual v12, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0816 const-string v13, ".png"
  081a invoke-virtual v12, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0820 invoke-virtual v12, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0826 move-result-object v12
  0828 filled-new-array v5, v12, [Ljava/lang/String;
  082e move-result-object v5
  0830 invoke-static v5, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  0836 move-result-object v5
  0838 invoke-direct v0, v5, Lcom/personal/aihub/GameMetadata;->first(Ljava/util/List;)Lorg/json/JSONObject;
  083e move-result-object v5
  0840 if-eqz v5, +005h
  0844 invoke-virtual v10, v7, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  084a add-int/lit8 v15, v15, 1
  084e move-object/from16 v5, v17
  0852 move-wide/from16 v12, v27
  0856 const/4 v7, 2
  0858 goto -5fh
  085a move-wide/from16 v27, v12
  085e if-nez v11, +010h
  0862 if-nez v6, +00eh
  0866 if-nez v1, +00ch
  086a if-nez v8, +00ah
  086e invoke-virtual v10, Lorg/json/JSONObject;->length()I
  0874 move-result v2
  0876 if-nez v2, +004h
  087a const/4 v2, 0
  087c return-object v2
  087e new-instance v2, Lorg/json/JSONObject;
  0882 invoke-direct v2, Lorg/json/JSONObject;-><init>()V
  0888 const-string v5, "found"
  088c const/4 v7, 1
  088e invoke-virtual v2, v5, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0894 move-result-object v2
  0896 const-string v5, "forge_local"
  089a invoke-virtual v2, v5, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  08a0 move-result-object v2
  08a2 move-wide/from16 v12, v27
  08a6 invoke-virtual v2, v14, v12, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  08ac move-result-object v2
  08ae move-object/from16 v7, v36
  08b2 move-object/from16 v5, v16
  08b6 invoke-virtual v5, v7, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  08bc move-result-object v9
  08be invoke-virtual v2, v7, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  08c4 move-result-object v2
  08c6 move-object/from16 v7, v19
  08ca move-wide/from16 v12, v23
  08ce invoke-virtual v2, v7, v12, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  08d4 move-result-object v2
  08d6 const-string v7, "character_size"
  08da if-nez v25, +005h
  08de sget-object v9, Lorg/json/JSONObject;->NULL Ljava/lang/Object;
  08e2 goto +9h
  08e4 const-string v9, "size"
  08e8 move-object/from16 v12, v25
  08ec invoke-static v12, v9, Lcom/personal/aihub/GameMetadata;->value(Lorg/json/JSONObject; Ljava/lang/String;)Ljava/lang/Object;
  08f2 move-result-object v9
  08f4 invoke-virtual v2, v7, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  08fa move-result-object v2
  08fc move-object/from16 v7, v18
  0900 invoke-static v5, v7, Lcom/personal/aihub/GameMetadata;->value(Lorg/json/JSONObject; Ljava/lang/String;)Ljava/lang/Object;
  0906 move-result-object v9
  0908 invoke-virtual v2, v7, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  090e move-result-object v2
  0910 const-string v7, "art_id"
  0914 invoke-virtual v2, v7, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  091a move-result-object v2
  091c move-object/from16 v3, v20
  0920 invoke-static v5, v3, Lcom/personal/aihub/GameMetadata;->value(Lorg/json/JSONObject; Ljava/lang/String;)Ljava/lang/Object;
  0926 move-result-object v4
  0928 invoke-virtual v2, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  092e move-result-object v2
  0930 move-object/from16 v3, v26
  0934 invoke-static v5, v3, Lcom/personal/aihub/GameMetadata;->value(Lorg/json/JSONObject; Ljava/lang/String;)Ljava/lang/Object;
  093a move-result-object v4
  093c invoke-virtual v2, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0942 move-result-object v2
  0944 const-string v3, "aura_id"
  0948 const-string v4, "aura_id"
  094c invoke-static v5, v4, Lcom/personal/aihub/GameMetadata;->value(Lorg/json/JSONObject; Ljava/lang/String;)Ljava/lang/Object;
  0952 move-result-object v4
  0954 invoke-virtual v2, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  095a move-result-object v2
  095c const-string v3, "aura_effect_id"
  0960 sget-object v4, Lorg/json/JSONObject;->NULL Ljava/lang/Object;
  0964 invoke-virtual v2, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  096a move-result-object v2
  096c const-string v3, "aura_scale"
  0970 const-string v4, "aura_scale"
  0974 const-wide/high16 v12, 4607182418800017408
  0978 invoke-virtual v5, v4, v12, v13, Lorg/json/JSONObject;->optDouble(Ljava/lang/String; D)D
  097e move-result-wide v12
  0980 invoke-virtual v2, v3, v12, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; D)Lorg/json/JSONObject;
  0986 move-result-object v2
  0988 const-string v3, "aura_offset_x"
  098c const-string v4, "aura_offset_x"
  0990 const-wide/16 v12, 0
  0994 invoke-virtual v5, v4, v12, v13, Lorg/json/JSONObject;->optDouble(Ljava/lang/String; D)D
  099a move-result-wide v12
  099c invoke-virtual v2, v3, v12, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; D)Lorg/json/JSONObject;
  09a2 move-result-object v2
  09a4 const-string v3, "aura_offset_y"
  09a8 const-string v4, "aura_offset_y"
  09ac const-wide/16 v12, 0
  09b0 invoke-virtual v5, v4, v12, v13, Lorg/json/JSONObject;->optDouble(Ljava/lang/String; D)D
  09b6 move-result-wide v12
  09b8 invoke-virtual v2, v3, v12, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; D)Lorg/json/JSONObject;
  09be move-result-object v2
  09c0 const-string v3, "is_aura_front"
  09c4 const-string v4, "is_aura_front"
  09c8 const/4 v7, 0
  09ca invoke-virtual v5, v4, v7, Lorg/json/JSONObject;->optInt(Ljava/lang/String; I)I
  09d0 move-result v4
  09d2 if-eqz v4, +004h
  09d6 const/4 v13, 1
  09d8 goto +2h
  09da const/4 v13, 0
  09dc invoke-virtual v2, v3, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  09e2 move-result-object v2
  09e4 const-string v3, "battle"
  09e8 invoke-static v11, Lcom/personal/aihub/GameMetadata;->nullable(Ljava/lang/Object;)Ljava/lang/Object;
  09ee move-result-object v4
  09f0 invoke-virtual v2, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  09f6 move-result-object v2
  09f8 const-string v3, "idle"
  09fc invoke-static v6, Lcom/personal/aihub/GameMetadata;->nullable(Ljava/lang/Object;)Ljava/lang/Object;
  0a02 move-result-object v4
  0a04 invoke-virtual v2, v3, v4, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0a0a move-result-object v2
  0a0c const-string v3, "sp"
  0a10 invoke-static v1, Lcom/personal/aihub/GameMetadata;->nullable(Ljava/lang/Object;)Ljava/lang/Object;
  0a16 move-result-object v1
  0a18 invoke-virtual v2, v3, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0a1e move-result-object v1
  0a20 const-string v2, "card_bg"
  0a24 invoke-static v8, Lcom/personal/aihub/GameMetadata;->nullable(Ljava/lang/Object;)Ljava/lang/Object;
  0a2a move-result-object v3
  0a2c invoke-virtual v1, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0a32 move-result-object v1
  0a34 const-string v2, "textures"
  0a38 invoke-virtual v1, v2, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0a3e move-result-object v1
  0a40 const-string v2, "dbSource"
  0a44 const-string v3, "imported"
  0a48 invoke-virtual v1, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0a4e move-result-object v1
  0a50 return-object v1
  0a52 move-object v5, v7
  0a54 move-object/from16 v16, v25
  0a58 move-object/from16 v22, v26
  0a5c move-object/from16 v7, v36
  0a60 move-wide/from16 v33, v23
  0a64 move-object/from16 v24, v18
  0a68 move-object/from16 v23, v19
  0a6c move-wide/from16 v18, v33
  0a70 aget-object v25, v17, v15
  0a74 move-object/from16 v36, v1
  0a78 new-instance v1, Ljava/lang/StringBuilder;
  0a7c invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  0a82 move-object/from16 v26, v2
  0a86 invoke-static v9, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0a8c move-result-object v2
  0a8e invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0a94 move-wide/from16 v27, v3
  0a98 const/4 v2, 1
  0a9a aget-object v3, v25, v2
  0a9e invoke-virtual v1, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0aa4 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0aaa move-result-object v1
  0aac invoke-direct v0, v1, Lcom/personal/aihub/GameMetadata;->descriptor(Ljava/lang/String;)Lorg/json/JSONObject;
  0ab2 move-result-object v1
  0ab4 if-eqz v1, +009h
  0ab8 const/4 v3, 0
  0aba aget-object v4, v25, v3
  0abe invoke-virtual v10, v4, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0ac4 goto +2h
  0ac6 const/4 v3, 0
  0ac8 add-int/lit8 v15, v15, 1
  0acc move-object/from16 v1, v36
  0ad0 move-object/from16 v36, v7
  0ad4 move-object/from16 v25, v16
  0ad8 move-object/from16 v2, v26
  0adc move-wide/from16 v3, v27
  0ae0 move-object v7, v5
  0ae2 move-object/from16 v26, v22
  0ae6 move-wide/from16 v33, v18
  0aea move-object/from16 v19, v23
  0aee move-object/from16 v18, v24
  0af2 move-wide/from16 v23, v33
  0af6 goto/16 -1bdh
  0afa const/4 v1, 0
  0afc return-object v1
  0afe const/4 v1, 0
  0b00 return-object v1
  0b02 const/4 v1, 0
  0b04 return-object v1
  0b06 const/4 v1, 0
  0b08 return-object v1
.end method