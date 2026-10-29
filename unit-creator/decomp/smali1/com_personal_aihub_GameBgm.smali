.class Lcom/personal/aihub/GameBgm;
.super Ljava/lang/Object;
.field SQL Ljava/lang/String;

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method context(Landroid/database/sqlite/SQLiteDatabase; Ljava/lang/String;)Lorg/json/JSONObject;
  0000 new-instance v0, Lorg/json/JSONObject;
  0004 invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  000a const-string v1, "version"
  000e const/4 v2, 1
  0010 invoke-virtual v0, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0016 move-result-object v0
  0018 const-string v1, "found"
  001c const/4 v3, 0
  001e invoke-virtual v0, v1, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0024 move-result-object v0
  0026 const-string v4, "reason"
  002a if-eqz v12, +0a6h
  002e const-string v5, "ab_script/finish_skill/[A-Za-z0-9_]{1,80}\.lua"
  0032 invoke-virtual v12, v5, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0038 move-result v5
  003a if-nez v5, +004h
  003e goto/16 +09ch
  0042 const-string v5, "SELECT DISTINCT f.bgm_id AS id FROM finish_skill_sets f JOIN special_views v ON v.id=f.special_view_id WHERE v.script_name=? LIMIT 3"
  0046 const/16 v6, 47
  004a invoke-virtual v12, v6, Ljava/lang/String;->lastIndexOf(I)I
  0050 move-result v6
  0052 add-int/2addr v6, v2
  0054 invoke-virtual v12, Ljava/lang/String;->length()I
  005a move-result v7
  005c add-int/lit8 v7, v7, -4
  0060 invoke-virtual v12, v6, v7, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  0066 move-result-object v6
  0068 filled-new-array v6, [Ljava/lang/String;
  006e move-result-object v6
  0070 invoke-virtual v11, v5, v6, Landroid/database/sqlite/SQLiteDatabase;->rawQuery(Ljava/lang/String; [Ljava/lang/String;)Landroid/database/Cursor;
  0076 move-result-object v11
  0078 invoke-interface v11, Landroid/database/Cursor;->getCount()I
  007e move-result v5
  0080 if-eq v5, v2, +017h
  0084 invoke-interface v11, Landroid/database/Cursor;->getCount()I
  008a move-result v12
  008c if-nez v12, +005h
  0090 const-string v12, "This move has no music selected in the imported game database."
  0094 goto +3h
  0096 const-string v12, "This move has multiple different music contexts."
  009a invoke-virtual v0, v4, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00a0 move-result-object v12
  00a2 if-eqz v11, +005h
  00a6 invoke-interface v11, Landroid/database/Cursor;->close()V
  00ac return-object v12
  00ae invoke-interface v11, Landroid/database/Cursor;->moveToFirst()Z
  00b4 invoke-interface v11, v3, Landroid/database/Cursor;->getLong(I)J
  00ba move-result-wide v5
  00bc const-wide/16 v7, 0
  00c0 cmp-long v7, v5, v7
  00c4 if-lez v7, +03eh
  00c8 const-wide/32 v7, 2147483647
  00ce cmp-long v7, v5, v7
  00d2 if-gtz v7, +037h
  00d6 invoke-interface v11, v3, Landroid/database/Cursor;->getDouble(I)D
  00dc move-result-wide v7
  00de long-to-double v9, v5
  00e0 cmpl-double v3, v7, v9
  00e4 if-nez v3, +02eh
  00e8 invoke-virtual v0, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  00ee move-result-object v1
  00f0 const-string v2, "scriptPath"
  00f4 invoke-virtual v1, v2, v12, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00fa move-result-object v12
  00fc const-string v1, "id"
  0100 invoke-virtual v12, v1, v5, v6, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  0106 move-result-object v12
  0108 const-string v1, "package"
  010c sget-object v2, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  0110 const-string v3, "bgm_%03d"
  0114 invoke-static v5, v6, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  011a move-result-object v5
  011c filled-new-array v5, [Ljava/lang/Object;
  0122 move-result-object v5
  0124 invoke-static v2, v3, v5, Ljava/lang/String;->format(Ljava/util/Locale; Ljava/lang/String; [Ljava/lang/Object;)Ljava/lang/String;
  012a move-result-object v2
  012c invoke-virtual v12, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0132 move-result-object v12
  0134 if-eqz v11, +005h
  0138 invoke-interface v11, Landroid/database/Cursor;->close()V
  013e return-object v12
  0140 new-instance v12, Ljava/io/IOException;
  0144 const-string v1, "Invalid game music context"
  0148 invoke-direct v12, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  014e throw v12
  0150 move-exception v12
  0152 if-eqz v11, +00ah
  0156 invoke-interface v11, Landroid/database/Cursor;->close()V
  015c goto +5h
  015e move-exception v11
  0160 invoke-virtual v12, v11, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0166 throw v12
  0168 const-string v11, "The imported game database cannot resolve this move’s music."
  016c invoke-virtual v0, v4, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0172 move-result-object v11
  0174 return-object v11
  0176 const-string v11, "This preview has no verified finish-skill music context."
  017a invoke-virtual v0, v4, v11, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0180 move-result-object v11
  0182 return-object v11
.end method

.method source(Ljava/io/File; Lcom/personal/aihub/GameAssets; Lorg/json/JSONObject;)[Ljava/lang/String;
  0000 const-string v0, "package"
  0004 invoke-virtual v6, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  000a move-result-object v0
  000c const-string v1, "found"
  0010 invoke-virtual v6, v1, Lorg/json/JSONObject;->optBoolean(Ljava/lang/String;)Z
  0016 move-result v6
  0018 const/4 v1, 0
  001a if-eqz v6, +0a6h
  001e const-string v6, "bgm_[0-9]{3,10}"
  0022 invoke-virtual v0, v6, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0028 move-result v6
  002a if-nez v6, +004h
  002e goto/16 +09ch
  0032 new-instance v6, Ljava/lang/StringBuilder;
  0036 const-string v2, "/assets/bgm/"
  003a invoke-direct v6, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0040 invoke-virtual v6, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0046 const-string v3, ".acb"
  004a invoke-virtual v6, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0050 invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0056 move-result-object v6
  0058 invoke-virtual v5, v6, Lcom/personal/aihub/GameAssets;->resolve(Ljava/lang/String;)Ljava/io/File;
  005e move-result-object v6
  0060 new-instance v3, Ljava/lang/StringBuilder;
  0064 invoke-direct v3, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  006a invoke-virtual v3, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0070 const-string v0, ".awb"
  0074 invoke-virtual v3, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  007a invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0080 move-result-object v0
  0082 invoke-virtual v5, v0, Lcom/personal/aihub/GameAssets;->resolve(Ljava/lang/String;)Ljava/io/File;
  0088 move-result-object v5
  008a if-nez v6, +005h
  008e if-nez v5, +003h
  0092 return-object v1
  0094 if-eqz v6, +061h
  0098 if-eqz v5, +05fh
  009c invoke-virtual v6, Ljava/io/File;->getParentFile()Ljava/io/File;
  00a2 move-result-object v0
  00a4 invoke-virtual v5, Ljava/io/File;->getParentFile()Ljava/io/File;
  00aa move-result-object v1
  00ac invoke-virtual v0, v1, Ljava/io/File;->equals(Ljava/lang/Object;)Z
  00b2 move-result v0
  00b4 if-eqz v0, +049h
  00b8 invoke-virtual v4, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  00be move-result-object v4
  00c0 invoke-virtual v4, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  00c6 move-result-object v4
  00c8 invoke-virtual v6, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  00ce move-result-object v6
  00d0 invoke-interface v4, v6, Ljava/nio/file/Path;->relativize(Ljava/nio/file/Path;)Ljava/nio/file/Path;
  00d6 move-result-object v6
  00d8 invoke-interface v6, Ljava/nio/file/Path;->toString()Ljava/lang/String;
  00de move-result-object v6
  00e0 sget-char v0, Ljava/io/File;->separatorChar C
  00e4 const/16 v1, 47
  00e8 invoke-virtual v6, v0, v1, Ljava/lang/String;->replace(C C)Ljava/lang/String;
  00ee move-result-object v6
  00f0 invoke-virtual v5, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  00f6 move-result-object v5
  00f8 invoke-interface v4, v5, Ljava/nio/file/Path;->relativize(Ljava/nio/file/Path;)Ljava/nio/file/Path;
  00fe move-result-object v4
  0100 invoke-interface v4, Ljava/nio/file/Path;->toString()Ljava/lang/String;
  0106 move-result-object v4
  0108 sget-char v5, Ljava/io/File;->separatorChar C
  010c invoke-virtual v4, v5, v1, Ljava/lang/String;->replace(C C)Ljava/lang/String;
  0112 move-result-object v4
  0114 invoke-static v6, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  011a move-result v5
  011c if-eqz v5, +00dh
  0120 invoke-static v4, Lcom/personal/aihub/GameAssets;->safe(Ljava/lang/String;)Z
  0126 move-result v5
  0128 if-eqz v5, +007h
  012c filled-new-array v6, v4, [Ljava/lang/String;
  0132 move-result-object v4
  0134 return-object v4
  0136 new-instance v4, Ljava/io/IOException;
  013a const-string v5, "Invalid imported music resource"
  013e invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0144 throw v4
  0146 new-instance v4, Ljava/io/IOException;
  014a const-string v5, "Imported move music must use a cue sheet and waveform from the same collection and folder."
  014e invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0154 throw v4
  0156 new-instance v4, Ljava/io/IOException;
  015a const-string v5, "Imported move music is missing its matching cue sheet or waveform bank. Import the complete music pair."
  015e invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0164 throw v4
  0166 return-object v1
.end method