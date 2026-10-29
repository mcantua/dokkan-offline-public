.class Lcom/personal/aihub/PreviewEffectPacks;
.super Ljava/lang/Object;

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method integer(Ljava/lang/Object; J J)J
  0000 instance-of v0, v8, Ljava/lang/Number;
  0004 const-string v1, "The edited movie preview is invalid. Reopen it from your unit."
  0008 if-eqz v0, +020h
  000c check-cast v8, Ljava/lang/Number;
  0010 invoke-virtual v8, Ljava/lang/Number;->longValue()J
  0016 move-result-wide v2
  0018 invoke-virtual v8, Ljava/lang/Number;->doubleValue()D
  001e move-result-wide v4
  0020 long-to-double v6, v2
  0022 cmpl-double v8, v4, v6
  0026 if-nez v8, +00bh
  002a cmp-long v8, v2, v9
  002e if-ltz v8, +007h
  0032 cmp-long v8, v2, v11
  0036 if-gtz v8, +003h
  003a return-wide v2
  003c new-instance v8, Ljava/io/IOException;
  0040 invoke-direct v8, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0046 throw v8
  0048 new-instance v8, Ljava/io/IOException;
  004c invoke-direct v8, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0052 throw v8
.end method

.method normalize(Ljava/lang/Object;)Lorg/json/JSONArray;
  0000 move-object/from16 v0, v22
  0004 if-nez v0, +008h
  0008 new-instance v0, Lorg/json/JSONArray;
  000c invoke-direct v0, Lorg/json/JSONArray;-><init>()V
  0012 return-object v0
  0014 instance-of v1, v0, Lorg/json/JSONArray;
  0018 const-string v2, "Choose a supported number of edited movies."
  001c if-eqz v1, +189h
  0020 check-cast v0, Lorg/json/JSONArray;
  0024 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  002a move-result v1
  002c const/16 v3, 128
  0030 if-gt v1, v3, +179h
  0034 new-instance v1, Ljava/util/HashSet;
  0038 const-string v10, "alpha"
  003c const-string v11, "lite_flicker_rate"
  0040 const-string v2, "id"
  0044 const-string v3, "category"
  0048 const-string v4, "pack_name"
  004c const-string v5, "scene_name"
  0050 const-string v6, "name"
  0054 const-string v7, "red"
  0058 const-string v8, "green"
  005c const-string v9, "blue"
  0060 filled-new-array/range v2 ... v11, [Ljava/lang/String;
  0066 move-result-object v2
  0068 invoke-static v2, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  006e move-result-object v2
  0070 invoke-direct v1, v2, Ljava/util/HashSet;-><init>(Ljava/util/Collection;)V
  0076 new-instance v2, Ljava/util/HashSet;
  007a invoke-direct v2, Ljava/util/HashSet;-><init>()V
  0080 new-instance v3, Ljava/util/HashSet;
  0084 invoke-direct v3, Ljava/util/HashSet;-><init>()V
  008a new-instance v4, Lorg/json/JSONArray;
  008e invoke-direct v4, Lorg/json/JSONArray;-><init>()V
  0094 const/4 v6, 0
  0096 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  009c move-result v7
  009e if-ge v6, v7, +140h
  00a2 invoke-virtual v0, v6, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  00a8 move-result-object v7
  00aa invoke-virtual v7, Lorg/json/JSONObject;->keys()Ljava/util/Iterator;
  00b0 move-result-object v8
  00b2 invoke-interface v8, Ljava/util/Iterator;->hasNext()Z
  00b8 move-result v9
  00ba const-string v10, "The edited movie preview is invalid. Reopen it from your unit."
  00be if-eqz v9, +013h
  00c2 invoke-interface v8, Ljava/util/Iterator;->next()Ljava/lang/Object;
  00c8 move-result-object v9
  00ca invoke-virtual v1, v9, Ljava/util/HashSet;->contains(Ljava/lang/Object;)Z
  00d0 move-result v9
  00d2 if-eqz v9, +003h
  00d6 goto -12h
  00d8 new-instance v0, Ljava/io/IOException;
  00dc invoke-direct v0, v10, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00e2 throw v0
  00e4 const-string v8, "id"
  00e8 invoke-virtual v7, v8, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  00ee move-result-object v9
  00f0 const-wide/32 v11, 2147483647
  00f6 const-wide/16 v13, 1
  00fa invoke-static v9, v13, v14, v11, v12, Lcom/personal/aihub/PreviewEffectPacks;->integer(Ljava/lang/Object; J J)J
  0100 move-result-wide v11
  0102 const-string v9, "category"
  0106 invoke-virtual v7, v9, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  010c move-result-object v15
  010e move/from16 v16, v6
  0112 const-wide/16 v5, 5
  0116 move-object/from16 v17, v0
  011a move-object/from16 v18, v1
  011e invoke-static v15, v13, v14, v5, v6, Lcom/personal/aihub/PreviewEffectPacks;->integer(Ljava/lang/Object; J J)J
  0124 move-result-wide v0
  0126 const-string v15, "pack_name"
  012a invoke-virtual v7, v15, Lorg/json/JSONObject;->opt(Ljava/lang/String;)Ljava/lang/Object;
  0130 move-result-object v5
  0132 instance-of v6, v5, Ljava/lang/String;
  0136 if-eqz v6, +0eeh
  013a move-object v6, v5
  013c check-cast v6, Ljava/lang/String;
  0140 const-string v13, "forge_movie_[1-9][0-9]{0,9}_[0-9]{1,2}_[0-9a-f]{32}"
  0144 invoke-virtual v6, v13, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  014a move-result v13
  014c if-eqz v13, +0e3h
  0150 invoke-static v6, Lcom/personal/aihub/PreviewEffectPacks;->validPack(Ljava/lang/String;)Z
  0156 move-result v13
  0158 if-eqz v13, +0ddh
  015c const-wide/16 v13, 1
  0160 cmp-long v13, v0, v13
  0164 if-eqz v13, +008h
  0168 const-wide/16 v13, 5
  016c cmp-long v13, v0, v13
  0170 if-nez v13, +0d1h
  0174 invoke-static v11, v12, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  017a move-result-object v13
  017c invoke-virtual v3, v13, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  0182 move-result v13
  0184 if-eqz v13, +0c7h
  0188 invoke-virtual v2, v6, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  018e move-result v6
  0190 if-eqz v6, +0c1h
  0194 const-string v6, "scene_name"
  0198 invoke-virtual v7, v6, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  019e move-result v10
  01a0 const-string v13, ""
  01a4 if-eqz v10, +007h
  01a8 invoke-virtual v7, v6, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  01ae move-result-object v10
  01b0 goto +2h
  01b2 move-object v10, v13
  01b4 const-string v14, "name"
  01b8 invoke-virtual v7, v14, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  01be move-result v19
  01c0 if-eqz v19, +006h
  01c4 invoke-virtual v7, v14, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  01ca move-result-object v13
  01cc move-object/from16 v19, v2
  01d0 instance-of v2, v10, Ljava/lang/String;
  01d4 if-eqz v2, +097h
  01d8 move-object v2, v10
  01da check-cast v2, Ljava/lang/String;
  01de move-object/from16 v20, v3
  01e2 const-string v3, "[A-Za-z0-9_]{0,100}"
  01e6 invoke-virtual v2, v3, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  01ec move-result v2
  01ee if-eqz v2, +08ah
  01f2 instance-of v2, v13, Ljava/lang/String;
  01f6 if-eqz v2, +086h
  01fa move-object v2, v13
  01fc check-cast v2, Ljava/lang/String;
  0200 invoke-virtual v2, Ljava/lang/String;->length()I
  0206 move-result v3
  0208 move-object/from16 v21, v4
  020c const/16 v4, 160
  0210 if-gt v3, v4, +079h
  0214 const-string v3, "(?s).*[\x00-\x1f\x7f].*"
  0218 invoke-virtual v2, v3, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  021e move-result v2
  0220 if-nez v2, +071h
  0224 new-instance v2, Lorg/json/JSONObject;
  0228 invoke-direct v2, Lorg/json/JSONObject;-><init>()V
  022e invoke-virtual v2, v8, v11, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0234 move-result-object v2
  0236 invoke-virtual v2, v9, v0, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  023c move-result-object v0
  023e invoke-virtual v0, v15, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0244 move-result-object v0
  0246 invoke-virtual v0, v6, v10, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  024c move-result-object v0
  024e invoke-virtual v0, v14, v13, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0254 move-result-object v0
  0256 const-string v1, "blue"
  025a const-string v2, "alpha"
  025e const-string v3, "red"
  0262 const-string v4, "green"
  0266 const-string v5, "lite_flicker_rate"
  026a filled-new-array v3, v4, v1, v2, v5, [Ljava/lang/String;
  0270 move-result-object v1
  0272 const/4 v2, 0
  0274 const/4 v3, 5
  0276 if-ge v2, v3, +034h
  027a aget-object v3, v1, v2
  027e invoke-virtual v7, v3, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  0284 move-result v4
  0286 const/16 v6, 255
  028a if-eqz v4, +007h
  028e invoke-virtual v7, v3, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  0294 move-result-object v4
  0296 goto +fh
  0298 invoke-virtual v3, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  029e move-result v4
  02a0 if-eqz v4, +005h
  02a4 const/16 v4, 70
  02a8 goto +2h
  02aa move v4, v6
  02ac invoke-static v4, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  02b2 move-result-object v4
  02b4 invoke-virtual v3, v5, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  02ba move-result v8
  02bc if-eqz v8, +004h
  02c0 const/16 v6, 100
  02c4 const-wide/16 v8, 0
  02c8 int-to-long v10, v6
  02ca invoke-static v4, v8, v9, v10, v11, Lcom/personal/aihub/PreviewEffectPacks;->integer(Ljava/lang/Object; J J)J
  02d0 move-result-wide v8
  02d2 invoke-virtual v0, v3, v8, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  02d8 add-int/lit8 v2, v2, 1
  02dc goto -34h
  02de move-object/from16 v2, v21
  02e2 invoke-virtual v2, v0, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  02e8 add-int/lit8 v6, v16, 1
  02ec move-object v4, v2
  02ee move-object/from16 v0, v17
  02f2 move-object/from16 v1, v18
  02f6 move-object/from16 v2, v19
  02fa move-object/from16 v3, v20
  02fe goto/16 -134h
  0302 new-instance v0, Ljava/io/IOException;
  0306 const-string v1, "The edited movie label is invalid."
  030a invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0310 throw v0
  0312 new-instance v0, Ljava/io/IOException;
  0316 invoke-direct v0, v10, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  031c throw v0
  031e move-object v2, v4
  0320 return-object v2
  0322 new-instance v0, Ljava/io/IOException;
  0326 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  032c throw v0
  032e new-instance v0, Ljava/io/IOException;
  0332 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0338 throw v0
.end method

.method validPack(Ljava/lang/String;)Z
  0000 const-string v0, "_"
  0004 invoke-virtual v7, v0, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  000a move-result-object v7
  000c const/4 v0, 2
  000e const/4 v1, 0
  0010 aget-object v0, v7, v0
  0014 invoke-static v0, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J
  001a move-result-wide v2
  001c const/4 v0, 3
  001e aget-object v4, v7, v0
  0022 invoke-static v4, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I
  0028 move-result v4
  002a const-wide/32 v5, 1999999000
  0030 cmp-long v2, v2, v5
  0034 if-gtz v2, +013h
  0038 const/16 v2, 47
  003c if-gt v4, v2, +00fh
  0040 invoke-static v4, Ljava/lang/Integer;->toString(I)Ljava/lang/String;
  0046 move-result-object v2
  0048 aget-object v7, v7, v0
  004c invoke-virtual v2, v7, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0052 move-result v7
  0054 if-eqz v7, +003h
  0058 const/4 v1, 1
  005a return v1
.end method