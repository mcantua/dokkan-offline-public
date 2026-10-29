.class Lcom/personal/aihub/GameDataStore;
.super Ljava/lang/Object;
.field directory Ljava/io/File;
.field pointer Ljava/io/File;
.field reference Ljava/io/File;
.field root Ljava/io/File;

.method <init>(Ljava/io/File; Ljava/io/File;)V
  0000 invoke-direct v1, Ljava/lang/Object;-><init>()V
  0006 iput-object v2, v1, Lcom/personal/aihub/GameDataStore;->root Ljava/io/File;
  000a iput-object v3, v1, Lcom/personal/aihub/GameDataStore;->reference Ljava/io/File;
  000e new-instance v3, Ljava/io/File;
  0012 const-string v0, "databases"
  0016 invoke-direct v3, v2, v0, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  001c iput-object v3, v1, Lcom/personal/aihub/GameDataStore;->directory Ljava/io/File;
  0020 invoke-virtual v3, Ljava/io/File;->mkdirs()Z
  0026 new-instance v3, Ljava/io/File;
  002a const-string v0, "database-state.json"
  002e invoke-direct v3, v2, v0, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0034 iput-object v3, v1, Lcom/personal/aihub/GameDataStore;->pointer Ljava/io/File;
  0038 return-void 
.end method

.method hash(Ljava/io/File;)Ljava/lang/String;
  0000 const-string v0, "SHA-256"
  0004 invoke-static v0, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;
  000a move-result-object v0
  000c new-instance v1, Ljava/io/FileInputStream;
  0010 invoke-direct v1, v6, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0016 const/high16 v6, 65536
  001a new-array v6, v6, [B
  001e invoke-virtual v1, v6, Ljava/io/FileInputStream;->read([B)I
  0024 move-result v2
  0026 const/4 v3, -1
  0028 const/4 v4, 0
  002a if-eq v2, v3, +006h
  002e invoke-virtual v0, v6, v4, v2, Ljava/security/MessageDigest;->update([B I I)V
  0034 goto -bh
  0036 invoke-virtual v1, Ljava/io/FileInputStream;->close()V
  003c new-instance v6, Ljava/lang/StringBuilder;
  0040 invoke-direct v6, Ljava/lang/StringBuilder;-><init>()V
  0046 invoke-virtual v0, Ljava/security/MessageDigest;->digest()[B
  004c move-result-object v0
  004e array-length v1, v0
  0050 if-ge v4, v1, +01ch
  0054 aget-byte v2, v0, v4
  0058 sget-object v3, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  005c and-int/lit16 v2, v2, 255
  0060 invoke-static v2, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0066 move-result-object v2
  0068 filled-new-array v2, [Ljava/lang/Object;
  006e move-result-object v2
  0070 const-string v5, "%02x"
  0074 invoke-static v3, v5, v2, Ljava/lang/String;->format(Ljava/util/Locale; Ljava/lang/String; [Ljava/lang/Object;)Ljava/lang/String;
  007a move-result-object v2
  007c invoke-virtual v6, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0082 add-int/lit8 v4, v4, 1
  0086 goto -1bh
  0088 invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  008e move-result-object v6
  0090 return-object v6
  0092 move-exception v6
  0094 invoke-virtual v1, Ljava/io/FileInputStream;->close()V
  009a goto +5h
  009c move-exception v0
  009e invoke-virtual v6, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  00a4 throw v6
.end method

.method prune()V
  0000 const-string v0, "previous"
  0004 const-string v1, "file"
  0008 invoke-virtual v7, Lcom/personal/aihub/GameDataStore;->state()Lorg/json/JSONObject;
  000e move-result-object v2
  0010 new-instance v3, Ljava/util/HashSet;
  0014 invoke-direct v3, Ljava/util/HashSet;-><init>()V
  001a const-string v4, "active"
  001e invoke-virtual v2, v4, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0024 move-result-object v4
  0026 invoke-virtual v4, v1, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  002c move-result-object v4
  002e invoke-virtual v3, v4, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  0034 invoke-virtual v2, v0, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  003a move-result-object v4
  003c if-eqz v4, +00dh
  0040 invoke-virtual v2, v0, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0046 move-result-object v0
  0048 invoke-virtual v0, v1, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  004e move-result-object v0
  0050 invoke-virtual v3, v0, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  0056 iget-object v0, v7, Lcom/personal/aihub/GameDataStore;->directory Ljava/io/File;
  005a invoke-virtual v0, Ljava/io/File;->listFiles()[Ljava/io/File;
  0060 move-result-object v0
  0062 if-eqz v0, +024h
  0066 array-length v1, v0
  0068 const/4 v2, 0
  006a if-ge v2, v1, +020h
  006e aget-object v4, v0, v2
  0072 invoke-virtual v4, Ljava/io/File;->getName()Ljava/lang/String;
  0078 move-result-object v5
  007a const-string v6, "db-[a-f0-9]{64}\.db"
  007e invoke-virtual v5, v6, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0084 move-result v5
  0086 if-eqz v5, +00fh
  008a invoke-virtual v4, Ljava/io/File;->getName()Ljava/lang/String;
  0090 move-result-object v5
  0092 invoke-virtual v3, v5, Ljava/util/HashSet;->contains(Ljava/lang/Object;)Z
  0098 move-result v5
  009a if-nez v5, +005h
  009e invoke-virtual v4, Ljava/io/File;->delete()Z
  00a4 add-int/lit8 v2, v2, 1
  00a8 goto -1fh
  00aa return-void 
.end method

.method slot(Ljava/io/File; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 new-instance v0, Ljava/io/File;
  0004 iget-object v1, v8, Lcom/personal/aihub/GameDataStore;->directory Ljava/io/File;
  0008 new-instance v2, Ljava/lang/StringBuilder;
  000c const-string v3, "stage-"
  0010 invoke-direct v2, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0016 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  001c move-result-object v3
  001e invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0024 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  002a move-result-object v2
  002c invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0032 new-instance v1, Ljava/io/FileInputStream;
  0036 invoke-direct v1, v9, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  003c new-instance v9, Ljava/io/FileOutputStream;
  0040 invoke-direct v9, v0, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0046 const/high16 v2, 65536
  004a new-array v2, v2, [B
  004e const-wide/16 v3, 0
  0052 invoke-virtual v1, v2, Ljava/io/FileInputStream;->read([B)I
  0058 move-result v5
  005a const/4 v6, -1
  005c if-eq v5, v6, +018h
  0060 int-to-long v6, v5
  0062 add-long/2addr v3, v6
  0064 const-wide/32 v6, 536870912
  006a cmp-long v6, v3, v6
  006e if-gtz v6, +007h
  0072 const/4 v6, 0
  0074 invoke-virtual v9, v2, v6, v5, Ljava/io/FileOutputStream;->write([B I I)V
  007a goto -14h
  007c new-instance v10, Ljava/io/IOException;
  0080 const-string v2, "Database exceeds 512 MB"
  0084 invoke-direct v10, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  008a throw v10
  008c invoke-virtual v9, Ljava/io/FileOutputStream;->getFD()Ljava/io/FileDescriptor;
  0092 move-result-object v2
  0094 invoke-virtual v2, Ljava/io/FileDescriptor;->sync()V
  009a invoke-virtual v9, Ljava/io/FileOutputStream;->close()V
  00a0 invoke-virtual v1, Ljava/io/FileInputStream;->close()V
  00a6 invoke-static v0, Lcom/personal/aihub/GameDataStore;->hash(Ljava/io/File;)Ljava/lang/String;
  00ac move-result-object v9
  00ae new-instance v1, Ljava/lang/StringBuilder;
  00b2 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  00b8 const-string v2, "db-"
  00bc invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00c2 invoke-virtual v1, v9, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00c8 const-string v2, ".db"
  00cc invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00d2 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00d8 move-result-object v1
  00da new-instance v2, Ljava/io/File;
  00de iget-object v3, v8, Lcom/personal/aihub/GameDataStore;->directory Ljava/io/File;
  00e2 invoke-direct v2, v3, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00e8 invoke-virtual v2, Ljava/io/File;->exists()Z
  00ee move-result v3
  00f0 if-nez v3, +011h
  00f4 invoke-virtual v0, v2, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  00fa move-result v3
  00fc if-eqz v3, +003h
  0100 goto +9h
  0102 new-instance v9, Ljava/io/IOException;
  0106 const-string v10, "Could not stage database"
  010a invoke-direct v9, v10, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0110 throw v9
  0112 new-instance v3, Lorg/json/JSONObject;
  0116 invoke-direct v3, Lorg/json/JSONObject;-><init>()V
  011c const-string v4, "file"
  0120 invoke-virtual v3, v4, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0126 move-result-object v1
  0128 const-string v3, "meta"
  012c new-instance v4, Lorg/json/JSONObject;
  0130 invoke-virtual v10, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0136 move-result-object v10
  0138 invoke-direct v4, v10, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  013e const-string v10, "sha256"
  0142 invoke-virtual v4, v10, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0148 move-result-object v9
  014a const-string v10, "bytes"
  014e invoke-virtual v2, Ljava/io/File;->length()J
  0154 move-result-wide v4
  0156 invoke-virtual v9, v10, v4, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; J)Lorg/json/JSONObject;
  015c move-result-object v9
  015e invoke-virtual v1, v3, v9, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0164 move-result-object v9
  0166 invoke-virtual v0, Ljava/io/File;->delete()Z
  016c return-object v9
  016e move-exception v10
  0170 invoke-virtual v9, Ljava/io/FileOutputStream;->close()V
  0176 goto +5h
  0178 move-exception v9
  017a invoke-virtual v10, v9, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0180 throw v10
  0182 move-exception v9
  0184 invoke-virtual v1, Ljava/io/FileInputStream;->close()V
  018a goto +5h
  018c move-exception v10
  018e invoke-virtual v9, v10, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0194 throw v9
  0196 move-exception v9
  0198 invoke-virtual v0, Ljava/io/File;->delete()Z
  019e throw v9
.end method

.method text(Ljava/io/File;)Ljava/lang/String;
  0000 invoke-virtual v4, Ljava/io/File;->length()J
  0006 move-result-wide v0
  0008 const-wide/32 v2, 1048576
  000e cmp-long v0, v0, v2
  0012 if-gtz v0, +03dh
  0016 new-instance v0, Ljava/io/FileInputStream;
  001a invoke-direct v0, v4, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0020 new-instance v4, Ljava/io/ByteArrayOutputStream;
  0024 invoke-direct v4, Ljava/io/ByteArrayOutputStream;-><init>()V
  002a const/16 v1, 8192
  002e new-array v1, v1, [B
  0032 invoke-virtual v0, v1, Ljava/io/FileInputStream;->read([B)I
  0038 move-result v2
  003a const/4 v3, -1
  003c if-eq v2, v3, +007h
  0040 const/4 v3, 0
  0042 invoke-virtual v4, v1, v3, v2, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  0048 goto -bh
  004a const-string v1, "UTF-8"
  004e invoke-virtual v4, v1, Ljava/io/ByteArrayOutputStream;->toString(Ljava/lang/String;)Ljava/lang/String;
  0054 move-result-object v1
  0056 invoke-virtual v4, Ljava/io/ByteArrayOutputStream;->close()V
  005c invoke-virtual v0, Ljava/io/FileInputStream;->close()V
  0062 return-object v1
  0064 move-exception v1
  0066 invoke-virtual v4, Ljava/io/ByteArrayOutputStream;->close()V
  006c goto +5h
  006e move-exception v4
  0070 invoke-virtual v1, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0076 throw v1
  0078 move-exception v4
  007a invoke-virtual v0, Ljava/io/FileInputStream;->close()V
  0080 goto +5h
  0082 move-exception v0
  0084 invoke-virtual v4, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  008a throw v4
  008c new-instance v4, Ljava/io/IOException;
  0090 const-string v0, "Database state is too large"
  0094 invoke-direct v4, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  009a throw v4
.end method

.method write(Lorg/json/JSONObject;)V
  0000 new-instance v0, Ljava/io/File;
  0004 new-instance v1, Ljava/lang/StringBuilder;
  0008 invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  000e iget-object v2, v3, Lcom/personal/aihub/GameDataStore;->pointer Ljava/io/File;
  0012 invoke-virtual v2, Ljava/io/File;->getPath()Ljava/lang/String;
  0018 move-result-object v2
  001a invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0020 const-string v2, ".tmp"
  0024 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  002a invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0030 move-result-object v1
  0032 invoke-direct v0, v1, Ljava/io/File;-><init>(Ljava/lang/String;)V
  0038 new-instance v1, Ljava/io/FileOutputStream;
  003c invoke-direct v1, v0, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  0042 invoke-virtual v4, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0048 move-result-object v4
  004a const-string v2, "UTF-8"
  004e invoke-virtual v4, v2, Ljava/lang/String;->getBytes(Ljava/lang/String;)[B
  0054 move-result-object v4
  0056 invoke-virtual v1, v4, Ljava/io/FileOutputStream;->write([B)V
  005c invoke-virtual v1, Ljava/io/FileOutputStream;->getFD()Ljava/io/FileDescriptor;
  0062 move-result-object v4
  0064 invoke-virtual v4, Ljava/io/FileDescriptor;->sync()V
  006a invoke-virtual v1, Ljava/io/FileOutputStream;->close()V
  0070 iget-object v4, v3, Lcom/personal/aihub/GameDataStore;->pointer Ljava/io/File;
  0074 invoke-virtual v0, v4, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  007a move-result v4
  007c if-eqz v4, +006h
  0080 invoke-virtual v0, Ljava/io/File;->delete()Z
  0086 return-void 
  0088 new-instance v4, Ljava/io/IOException;
  008c const-string v1, "Could not activate the database; previous data was kept"
  0090 invoke-direct v4, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0096 throw v4
  0098 move-exception v4
  009a invoke-virtual v1, Ljava/io/FileOutputStream;->close()V
  00a0 goto +5h
  00a2 move-exception v1
  00a4 invoke-virtual v4, v1, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  00aa throw v4
  00ac move-exception v4
  00ae invoke-virtual v0, Ljava/io/File;->delete()Z
  00b4 throw v4
.end method

.method commit(Ljava/io/File; Lorg/json/JSONObject;)V
  0000 monitor-enter v4
  0002 invoke-virtual v4, Lcom/personal/aihub/GameDataStore;->state()Lorg/json/JSONObject;
  0008 move-result-object v0
  000a new-instance v1, Lorg/json/JSONObject;
  000e invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  0014 const-string v2, "version"
  0018 const/4 v3, 1
  001a invoke-virtual v1, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0020 move-result-object v1
  0022 const-string v2, "active"
  0026 invoke-direct v4, v5, v6, Lcom/personal/aihub/GameDataStore;->slot(Ljava/io/File; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  002c move-result-object v5
  002e invoke-virtual v1, v2, v5, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0034 move-result-object v5
  0036 if-eqz v0, +00eh
  003a const-string v6, "previous"
  003e const-string v1, "active"
  0042 invoke-virtual v0, v1, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0048 move-result-object v0
  004a invoke-virtual v5, v6, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0050 goto +1ch
  0052 invoke-virtual v4, Lcom/personal/aihub/GameDataStore;->current()Ljava/io/File;
  0058 move-result-object v6
  005a invoke-virtual v6, Ljava/io/File;->isFile()Z
  0060 move-result v6
  0062 if-eqz v6, +013h
  0066 const-string v6, "previous"
  006a invoke-virtual v4, Lcom/personal/aihub/GameDataStore;->current()Ljava/io/File;
  0070 move-result-object v0
  0072 invoke-virtual v4, Lcom/personal/aihub/GameDataStore;->meta()Lorg/json/JSONObject;
  0078 move-result-object v1
  007a invoke-direct v4, v0, v1, Lcom/personal/aihub/GameDataStore;->slot(Ljava/io/File; Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0080 move-result-object v0
  0082 invoke-virtual v5, v6, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0088 invoke-direct v4, v5, Lcom/personal/aihub/GameDataStore;->write(Lorg/json/JSONObject;)V
  008e invoke-direct v4, Lcom/personal/aihub/GameDataStore;->prune()V
  0094 monitor-exit v4
  0096 return-void 
  0098 move-exception v5
  009a monitor-exit v4
  009c throw v5
.end method

.method current()Ljava/io/File;
  0000 invoke-virtual v3, Lcom/personal/aihub/GameDataStore;->state()Lorg/json/JSONObject;
  0006 move-result-object v0
  0008 if-eqz v0, +00dh
  000c const-string v1, "active"
  0010 invoke-virtual v0, v1, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0016 move-result-object v0
  0018 invoke-virtual v3, v0, Lcom/personal/aihub/GameDataStore;->file(Lorg/json/JSONObject;)Ljava/io/File;
  001e move-result-object v0
  0020 return-object v0
  0022 new-instance v0, Ljava/io/File;
  0026 iget-object v1, v3, Lcom/personal/aihub/GameDataStore;->root Ljava/io/File;
  002a const-string v2, "database.db"
  002e invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0034 invoke-virtual v0, Ljava/io/File;->exists()Z
  003a move-result v1
  003c if-eqz v1, +003h
  0040 goto +3h
  0042 iget-object v0, v3, Lcom/personal/aihub/GameDataStore;->reference Ljava/io/File;
  0046 return-object v0
.end method

.method file(Lorg/json/JSONObject;)Ljava/io/File;
  0000 const-string v0, "file"
  0004 invoke-virtual v3, v0, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  000a move-result-object v3
  000c const-string v0, "db-[a-f0-9]{64}\.db"
  0010 invoke-virtual v3, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0016 move-result v0
  0018 if-eqz v0, +00ah
  001c new-instance v0, Ljava/io/File;
  0020 iget-object v1, v2, Lcom/personal/aihub/GameDataStore;->directory Ljava/io/File;
  0024 invoke-direct v0, v1, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  002a return-object v0
  002c new-instance v3, Ljava/io/IOException;
  0030 const-string v0, "Invalid stored database name"
  0034 invoke-direct v3, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  003a throw v3
.end method

.method meta()Lorg/json/JSONObject;
  0000 invoke-virtual v3, Lcom/personal/aihub/GameDataStore;->state()Lorg/json/JSONObject;
  0006 move-result-object v0
  0008 if-eqz v0, +00fh
  000c const-string v1, "active"
  0010 invoke-virtual v0, v1, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0016 move-result-object v0
  0018 const-string v1, "meta"
  001c invoke-virtual v0, v1, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0022 move-result-object v0
  0024 return-object v0
  0026 new-instance v0, Ljava/io/File;
  002a iget-object v1, v3, Lcom/personal/aihub/GameDataStore;->root Ljava/io/File;
  002e const-string v2, "database-meta.json"
  0032 invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0038 invoke-virtual v0, Ljava/io/File;->exists()Z
  003e move-result v1
  0040 if-eqz v1, +00ch
  0044 new-instance v1, Lorg/json/JSONObject;
  0048 invoke-static v0, Lcom/personal/aihub/GameDataStore;->text(Ljava/io/File;)Ljava/lang/String;
  004e move-result-object v0
  0050 invoke-direct v1, v0, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  0056 goto +16h
  0058 new-instance v0, Lorg/json/JSONObject;
  005c invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  0062 const-string v1, "source"
  0066 const-string v2, "Bundled Eclipse English snapshot · 2026-10-14"
  006a invoke-virtual v0, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0070 move-result-object v0
  0072 const-string v1, "date"
  0076 const-string v2, "2026-10-14"
  007a invoke-virtual v0, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0080 move-result-object v1
  0082 return-object v1
.end method

.method restore()V
  0000 monitor-enter v4
  0002 invoke-virtual v4, Lcom/personal/aihub/GameDataStore;->state()Lorg/json/JSONObject;
  0008 move-result-object v0
  000a if-eqz v0, +033h
  000e const-string v1, "previous"
  0012 invoke-virtual v0, v1, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0018 move-result-object v1
  001a if-eqz v1, +02bh
  001e new-instance v1, Lorg/json/JSONObject;
  0022 invoke-direct v1, Lorg/json/JSONObject;-><init>()V
  0028 const-string v2, "version"
  002c const/4 v3, 1
  002e invoke-virtual v1, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  0034 move-result-object v1
  0036 const-string v2, "active"
  003a const-string v3, "previous"
  003e invoke-virtual v0, v3, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0044 move-result-object v3
  0046 invoke-virtual v1, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  004c move-result-object v1
  004e const-string v2, "previous"
  0052 const-string v3, "active"
  0056 invoke-virtual v0, v3, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  005c move-result-object v0
  005e invoke-virtual v1, v2, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0064 move-result-object v0
  0066 invoke-direct v4, v0, Lcom/personal/aihub/GameDataStore;->write(Lorg/json/JSONObject;)V
  006c monitor-exit v4
  006e return-void 
  0070 new-instance v0, Ljava/io/IOException;
  0074 const-string v1, "No previous database is available"
  0078 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  007e throw v0
  0080 move-exception v0
  0082 monitor-exit v4
  0084 throw v0
.end method

.method state()Lorg/json/JSONObject;
  0000 iget-object v0, v3, Lcom/personal/aihub/GameDataStore;->pointer Ljava/io/File;
  0004 invoke-virtual v0, Ljava/io/File;->exists()Z
  000a move-result v0
  000c if-nez v0, +004h
  0010 const/4 v0, 0
  0012 return-object v0
  0014 new-instance v0, Lorg/json/JSONObject;
  0018 iget-object v1, v3, Lcom/personal/aihub/GameDataStore;->pointer Ljava/io/File;
  001c invoke-static v1, Lcom/personal/aihub/GameDataStore;->text(Ljava/io/File;)Ljava/lang/String;
  0022 move-result-object v1
  0024 invoke-direct v0, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  002a const-string v1, "version"
  002e invoke-virtual v0, v1, Lorg/json/JSONObject;->optInt(Ljava/lang/String;)I
  0034 move-result v1
  0036 const/4 v2, 1
  0038 if-ne v1, v2, +01bh
  003c const-string v1, "active"
  0040 invoke-virtual v0, v1, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0046 move-result-object v1
  0048 invoke-virtual v3, v1, Lcom/personal/aihub/GameDataStore;->file(Lorg/json/JSONObject;)Ljava/io/File;
  004e const-string v1, "previous"
  0052 invoke-virtual v0, v1, Lorg/json/JSONObject;->optJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0058 move-result-object v2
  005a if-eqz v2, +009h
  005e invoke-virtual v0, v1, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;
  0064 move-result-object v1
  0066 invoke-virtual v3, v1, Lcom/personal/aihub/GameDataStore;->file(Lorg/json/JSONObject;)Ljava/io/File;
  006c return-object v0
  006e new-instance v0, Ljava/io/IOException;
  0072 const-string v1, "Unsupported database state"
  0076 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  007c throw v0
.end method