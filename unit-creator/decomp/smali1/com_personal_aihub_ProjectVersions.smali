.class Lcom/personal/aihub/ProjectVersions;
.super Ljava/lang/Object;
.field BUDGET I
.field HEADER I
.field MAX I
.field current Ljava/io/File;
.field dir Ljava/io/File;
.field index Ljava/io/File;
.field key Ljava/lang/String;

.method <init>(Ljava/io/File; Ljava/io/File; Ljava/lang/String;)V
  0000 invoke-direct v5, Ljava/lang/Object;-><init>()V
  0006 if-eqz v8, +0a1h
  000a const-string v0, "[a-zA-Z0-9_-]{1,100}"
  000e invoke-virtual v8, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0014 move-result v0
  0016 if-eqz v0, +099h
  001a invoke-virtual v6, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  0020 move-result-object v0
  0022 new-instance v1, Ljava/io/File;
  0026 new-instance v2, Ljava/io/File;
  002a const-string v3, "projects"
  002e invoke-direct v2, v6, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0034 new-instance v6, Ljava/lang/StringBuilder;
  0038 invoke-direct v6, Ljava/lang/StringBuilder;-><init>()V
  003e invoke-virtual v6, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0044 const-string v4, ".json"
  0048 invoke-virtual v6, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  004e invoke-virtual v6, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0054 move-result-object v6
  0056 invoke-direct v1, v2, v6, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  005c invoke-virtual v7, Ljava/io/File;->getAbsoluteFile()Ljava/io/File;
  0062 move-result-object v6
  0064 invoke-virtual v1, Ljava/io/File;->getAbsoluteFile()Ljava/io/File;
  006a move-result-object v7
  006c invoke-virtual v6, v7, Ljava/io/File;->equals(Ljava/lang/Object;)Z
  0072 move-result v6
  0074 if-eqz v6, +062h
  0078 new-instance v6, Ljava/io/File;
  007c new-instance v7, Ljava/io/File;
  0080 invoke-direct v7, v0, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0086 new-instance v1, Ljava/lang/StringBuilder;
  008a invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  0090 invoke-virtual v1, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0096 invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  009c invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00a2 move-result-object v1
  00a4 invoke-direct v6, v7, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00aa iput-object v6, v5, Lcom/personal/aihub/ProjectVersions;->current Ljava/io/File;
  00ae iput-object v8, v5, Lcom/personal/aihub/ProjectVersions;->key Ljava/lang/String;
  00b2 new-instance v6, Ljava/io/File;
  00b6 new-instance v7, Ljava/io/File;
  00ba const-string v1, "project-versions"
  00be invoke-direct v7, v0, v1, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00c4 invoke-direct v6, v7, v8, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00ca iput-object v6, v5, Lcom/personal/aihub/ProjectVersions;->dir Ljava/io/File;
  00ce invoke-virtual v6, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  00d4 move-result-object v7
  00d6 invoke-virtual v6, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;
  00dc move-result-object v8
  00de invoke-virtual v7, v8, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00e4 move-result v7
  00e6 if-eqz v7, +021h
  00ea invoke-virtual v6, Ljava/io/File;->mkdirs()Z
  00f0 move-result v7
  00f2 if-nez v7, +011h
  00f6 invoke-virtual v6, Ljava/io/File;->isDirectory()Z
  00fc move-result v7
  00fe if-eqz v7, +003h
  0102 goto +9h
  0104 new-instance v6, Ljava/io/IOException;
  0108 const-string v7, "Cannot create saved versions."
  010c invoke-direct v6, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0112 throw v6
  0114 new-instance v7, Ljava/io/File;
  0118 const-string v8, "index.json"
  011c invoke-direct v7, v6, v8, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0122 iput-object v7, v5, Lcom/personal/aihub/ProjectVersions;->index Ljava/io/File;
  0126 return-void 
  0128 new-instance v6, Ljava/io/IOException;
  012c const-string v7, "Unsafe backup directory."
  0130 invoke-direct v6, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0136 throw v6
  0138 new-instance v6, Ljava/io/IOException;
  013c const-string v7, "Current project is outside its storage directory."
  0140 invoke-direct v6, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0146 throw v6
  0148 new-instance v6, Ljava/io/IOException;
  014c const-string v7, "Invalid project key."
  0150 invoke-direct v6, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0156 throw v6
.end method

.method atomic(Ljava/io/File; [B)V
  0000 new-instance v0, Ljava/io/File;
  0004 invoke-virtual v4, Ljava/io/File;->getParentFile()Ljava/io/File;
  000a move-result-object v1
  000c new-instance v2, Ljava/lang/StringBuilder;
  0010 invoke-direct v2, Ljava/lang/StringBuilder;-><init>()V
  0016 invoke-virtual v4, Ljava/io/File;->getName()Ljava/lang/String;
  001c move-result-object v3
  001e invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0024 const-string v3, "."
  0028 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  002e invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0034 move-result-object v3
  0036 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  003c const-string v3, ".tmp"
  0040 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0046 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  004c move-result-object v2
  004e invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0054 new-instance v1, Ljava/io/FileOutputStream;
  0058 invoke-direct v1, v0, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  005e invoke-virtual v1, v5, Ljava/io/FileOutputStream;->write([B)V
  0064 invoke-virtual v1, Ljava/io/FileOutputStream;->getFD()Ljava/io/FileDescriptor;
  006a move-result-object v5
  006c invoke-virtual v5, Ljava/io/FileDescriptor;->sync()V
  0072 invoke-virtual v1, Ljava/io/FileOutputStream;->close()V
  0078 invoke-virtual v0, v4, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  007e move-result v4
  0080 if-eqz v4, +006h
  0084 invoke-virtual v0, Ljava/io/File;->delete()Z
  008a return-void 
  008c new-instance v4, Ljava/io/IOException;
  0090 const-string v5, "Could not commit saved project version."
  0094 invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  009a throw v4
  009c move-exception v4
  009e invoke-virtual v1, Ljava/io/FileOutputStream;->close()V
  00a4 goto +5h
  00a6 move-exception v5
  00a8 invoke-virtual v4, v5, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  00ae throw v4
  00b0 move-exception v4
  00b2 invoke-virtual v0, Ljava/io/File;->delete()Z
  00b8 throw v4
.end method

.method bytes(Ljava/io/File; I)[B
  0000 invoke-virtual v4, Ljava/io/File;->isFile()Z
  0006 move-result v0
  0008 if-eqz v0, +061h
  000c invoke-virtual v4, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  0012 move-result-object v0
  0014 invoke-virtual v4, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;
  001a move-result-object v1
  001c invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0022 move-result v0
  0024 if-eqz v0, +053h
  0028 invoke-virtual v4, Ljava/io/File;->length()J
  002e move-result-wide v0
  0030 int-to-long v2, v5
  0032 cmp-long v0, v0, v2
  0036 if-gtz v0, +04ah
  003a new-instance v0, Ljava/io/FileInputStream;
  003e invoke-direct v0, v4, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0044 new-instance v4, Ljava/io/ByteArrayOutputStream;
  0048 invoke-direct v4, Ljava/io/ByteArrayOutputStream;-><init>()V
  004e const/high16 v1, 65536
  0052 new-array v1, v1, [B
  0056 invoke-virtual v0, v1, Ljava/io/InputStream;->read([B)I
  005c move-result v2
  005e const/4 v3, -1
  0060 if-eq v2, v3, +016h
  0064 invoke-virtual v4, Ljava/io/ByteArrayOutputStream;->size()I
  006a move-result v3
  006c add-int/2addr v3, v2
  006e if-gt v3, v5, +007h
  0072 const/4 v3, 0
  0074 invoke-virtual v4, v1, v3, v2, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  007a goto -12h
  007c new-instance v5, Ljava/io/IOException;
  0080 const-string v1, "Project backup exceeds its size limit."
  0084 invoke-direct v5, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  008a throw v5
  008c invoke-virtual v4, Ljava/io/ByteArrayOutputStream;->toByteArray()[B
  0092 move-result-object v5
  0094 invoke-virtual v4, Ljava/io/ByteArrayOutputStream;->close()V
  009a invoke-virtual v0, Ljava/io/InputStream;->close()V
  00a0 return-object v5
  00a2 move-exception v5
  00a4 invoke-virtual v4, Ljava/io/ByteArrayOutputStream;->close()V
  00aa goto +5h
  00ac move-exception v4
  00ae invoke-virtual v5, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  00b4 throw v5
  00b6 move-exception v4
  00b8 invoke-virtual v0, Ljava/io/InputStream;->close()V
  00be goto +5h
  00c0 move-exception v5
  00c2 invoke-virtual v4, v5, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  00c8 throw v4
  00ca new-instance v4, Ljava/io/IOException;
  00ce const-string v5, "Project backup is invalid or too large."
  00d2 invoke-direct v4, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00d8 throw v4
.end method

.method revision([B)Ljava/lang/String;
  0000 const-string v0, "SHA-256"
  0004 invoke-static v0, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;
  000a move-result-object v0
  000c invoke-virtual v0, v6, Ljava/security/MessageDigest;->digest([B)[B
  0012 move-result-object v6
  0014 new-instance v0, Ljava/lang/StringBuilder;
  0018 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  001e array-length v1, v6
  0020 const/4 v2, 0
  0022 if-ge v2, v1, +01ch
  0026 aget-byte v3, v6, v2
  002a sget-object v4, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  002e and-int/lit16 v3, v3, 255
  0032 invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0038 move-result-object v3
  003a filled-new-array v3, [Ljava/lang/Object;
  0040 move-result-object v3
  0042 const-string v5, "%02x"
  0046 invoke-static v4, v5, v3, Ljava/lang/String;->format(Ljava/util/Locale; Ljava/lang/String; [Ljava/lang/Object;)Ljava/lang/String;
  004c move-result-object v3
  004e invoke-virtual v0, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0054 add-int/lit8 v2, v2, 1
  0058 goto -1bh
  005a invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0060 move-result-object v6
  0062 return-object v6
.end method

.method text([B)Ljava/lang/String;
  0000 new-instance v0, Ljava/lang/String;
  0004 sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0008 invoke-direct v0, v2, v1, Ljava/lang/String;-><init>([B Ljava/nio/charset/Charset;)V
  000e return-object v0
.end method

.method validVersion(Ljava/lang/String;)Z
  0000 if-eqz v1, +00ch
  0004 const-string v0, "[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}"
  0008 invoke-virtual v1, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  000e move-result v1
  0010 if-eqz v1, +004h
  0014 const/4 v1, 1
  0016 goto +2h
  0018 const/4 v1, 0
  001a return v1
.end method

.method candidate([B Ljava/lang/String;)Lorg/json/JSONObject;
  0000 if-eqz v7, +0d2h
  0004 invoke-virtual v7, Ljava/lang/String;->trim()Ljava/lang/String;
  000a move-result-object v7
  000c invoke-virtual v7, Ljava/lang/String;->isEmpty()Z
  0012 move-result v0
  0014 if-nez v0, +0c0h
  0018 const/4 v0, 0
  001a invoke-virtual v7, Ljava/lang/String;->length()I
  0020 move-result v1
  0022 invoke-virtual v7, v0, v1, Ljava/lang/String;->codePointCount(I I)I
  0028 move-result v0
  002a const/16 v1, 80
  002e if-gt v0, v1, +0b3h
  0032 const-string v0, "(?s).*[\x00-\x1f\x7f].*"
  0036 invoke-virtual v7, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  003c move-result v0
  003e if-nez v0, +0abh
  0042 new-instance v0, Lorg/json/JSONObject;
  0046 invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  004c invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0052 move-result-object v1
  0054 invoke-virtual v1, Ljava/util/UUID;->toString()Ljava/lang/String;
  005a move-result-object v1
  005c const-string v2, "versionKey"
  0060 invoke-virtual v0, v2, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0066 move-result-object v0
  0068 const-string v1, "label"
  006c invoke-virtual v0, v1, v7, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0072 move-result-object v7
  0074 new-instance v0, Lcom/personal/aihub/ProjectVersions$1;
  0078 const-string v1, "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
  007c sget-object v3, Ljava/util/Locale;->US Ljava/util/Locale;
  0080 invoke-direct v0, v5, v1, v3, Lcom/personal/aihub/ProjectVersions$1;-><init>(Lcom/personal/aihub/ProjectVersions; Ljava/lang/String; Ljava/util/Locale;)V
  0086 new-instance v1, Ljava/util/Date;
  008a invoke-direct v1, Ljava/util/Date;-><init>()V
  0090 invoke-virtual v0, v1, Lcom/personal/aihub/ProjectVersions$1;->format(Ljava/util/Date;)Ljava/lang/String;
  0096 move-result-object v0
  0098 const-string v1, "createdAt"
  009c invoke-virtual v7, v1, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00a2 move-result-object v7
  00a4 const-string v0, "bytes"
  00a8 array-length v1, v6
  00aa invoke-virtual v7, v0, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  00b0 move-result-object v7
  00b2 new-instance v0, Lorg/json/JSONObject;
  00b6 invoke-virtual v7, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  00bc move-result-object v1
  00be invoke-direct v0, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  00c4 const-string v1, "key"
  00c8 iget-object v3, v5, Lcom/personal/aihub/ProjectVersions;->key Ljava/lang/String;
  00cc invoke-virtual v0, v1, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00d2 move-result-object v0
  00d4 const-string v1, "revision"
  00d8 invoke-static v6, Lcom/personal/aihub/ProjectVersions;->revision([B)Ljava/lang/String;
  00de move-result-object v3
  00e0 invoke-virtual v0, v1, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00e6 move-result-object v0
  00e8 new-instance v1, Ljava/lang/StringBuilder;
  00ec invoke-direct v1, Ljava/lang/StringBuilder;-><init>()V
  00f2 invoke-virtual v0, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  00f8 move-result-object v0
  00fa invoke-virtual v1, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0100 const-string v0, "
"
  0104 invoke-virtual v1, v0, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  010a invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0110 move-result-object v0
  0112 sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0116 invoke-virtual v0, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  011c move-result-object v0
  011e new-instance v1, Ljava/io/ByteArrayOutputStream;
  0122 array-length v3, v0
  0124 array-length v4, v6
  0126 add-int/2addr v3, v4
  0128 invoke-direct v1, v3, Ljava/io/ByteArrayOutputStream;-><init>(I)V
  012e invoke-virtual v1, v0, Ljava/io/ByteArrayOutputStream;->write([B)V
  0134 invoke-virtual v1, v6, Ljava/io/ByteArrayOutputStream;->write([B)V
  013a const-string v6, "fileBytes"
  013e invoke-virtual v1, Ljava/io/ByteArrayOutputStream;->size()I
  0144 move-result v0
  0146 invoke-virtual v7, v6, v0, Lorg/json/JSONObject;->put(Ljava/lang/String; I)Lorg/json/JSONObject;
  014c new-instance v6, Ljava/io/File;
  0150 iget-object v0, v5, Lcom/personal/aihub/ProjectVersions;->dir Ljava/io/File;
  0154 new-instance v3, Ljava/lang/StringBuilder;
  0158 invoke-direct v3, Ljava/lang/StringBuilder;-><init>()V
  015e invoke-virtual v7, v2, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0164 move-result-object v2
  0166 invoke-virtual v3, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  016c const-string v2, ".version"
  0170 invoke-virtual v3, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0176 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  017c move-result-object v2
  017e invoke-direct v6, v0, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0184 invoke-virtual v1, Ljava/io/ByteArrayOutputStream;->toByteArray()[B
  018a move-result-object v0
  018c invoke-static v6, v0, Lcom/personal/aihub/ProjectVersions;->atomic(Ljava/io/File; [B)V
  0192 return-object v7
  0194 new-instance v6, Ljava/io/IOException;
  0198 const-string v7, "Use a readable version name of 1–80 characters."
  019c invoke-direct v6, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01a2 throw v6
  01a4 new-instance v6, Ljava/io/IOException;
  01a8 const-string v7, "Give this version a readable name."
  01ac invoke-direct v6, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01b2 throw v6
.end method

.method check(Lorg/json/JSONObject; [B Z)V
  0000 const-string v0, "expectedCurrentRevision"
  0004 if-nez v4, +008h
  0008 invoke-virtual v2, v0, Lorg/json/JSONObject;->has(Ljava/lang/String;)Z
  000e move-result v4
  0010 if-eqz v4, +018h
  0014 invoke-virtual v2, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  001a move-result-object v2
  001c const-string v4, "[a-f0-9]{64}"
  0020 invoke-virtual v2, v4, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0026 move-result v4
  0028 if-eqz v4, +00dh
  002c invoke-static v3, Lcom/personal/aihub/ProjectVersions;->revision([B)Ljava/lang/String;
  0032 move-result-object v3
  0034 invoke-virtual v2, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  003a move-result v2
  003c if-eqz v2, +003h
  0040 return-void 
  0042 new-instance v2, Ljava/io/IOException;
  0046 const-string v3, "This project changed after the version list was opened. Close it and reopen Saved versions."
  004a invoke-direct v2, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0050 throw v2
.end method

.method clean(Lorg/json/JSONArray;)V
  0000 new-instance v0, Ljava/util/HashSet;
  0004 invoke-direct v0, Ljava/util/HashSet;-><init>()V
  000a const/4 v1, 0
  000c move v2, v1
  000e invoke-virtual v7, Lorg/json/JSONArray;->length()I
  0014 move-result v3
  0016 if-ge v2, v3, +023h
  001a new-instance v3, Ljava/lang/StringBuilder;
  001e invoke-direct v3, Ljava/lang/StringBuilder;-><init>()V
  0024 invoke-virtual v7, v2, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  002a move-result-object v4
  002c const-string v5, "versionKey"
  0030 invoke-virtual v4, v5, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0036 move-result-object v4
  0038 invoke-virtual v3, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  003e const-string v4, ".version"
  0042 invoke-virtual v3, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0048 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  004e move-result-object v3
  0050 invoke-interface v0, v3, Ljava/util/Set;->add(Ljava/lang/Object;)Z
  0056 add-int/lit8 v2, v2, 1
  005a goto -26h
  005c iget-object v7, v6, Lcom/personal/aihub/ProjectVersions;->dir Ljava/io/File;
  0060 invoke-virtual v7, Ljava/io/File;->listFiles()[Ljava/io/File;
  0066 move-result-object v7
  0068 if-eqz v7, +023h
  006c array-length v2, v7
  006e if-ge v1, v2, +020h
  0072 aget-object v3, v7, v1
  0076 invoke-virtual v3, Ljava/io/File;->getName()Ljava/lang/String;
  007c move-result-object v4
  007e const-string v5, "[0-9a-f-]{36}\.version"
  0082 invoke-virtual v4, v5, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  0088 move-result v4
  008a if-eqz v4, +00fh
  008e invoke-virtual v3, Ljava/io/File;->getName()Ljava/lang/String;
  0094 move-result-object v4
  0096 invoke-interface v0, v4, Ljava/util/Set;->contains(Ljava/lang/Object;)Z
  009c move-result v4
  009e if-nez v4, +005h
  00a2 invoke-virtual v3, Ljava/io/File;->delete()Z
  00a8 add-int/lit8 v1, v1, 1
  00ac goto -1fh
  00ae return-void 
.end method

.method commit(Lorg/json/JSONArray;)V
  0000 iget-object v0, v2, Lcom/personal/aihub/ProjectVersions;->index Ljava/io/File;
  0004 invoke-virtual v3, Lorg/json/JSONArray;->toString()Ljava/lang/String;
  000a move-result-object v3
  000c sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0010 invoke-virtual v3, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0016 move-result-object v3
  0018 invoke-static v0, v3, Lcom/personal/aihub/ProjectVersions;->atomic(Ljava/io/File; [B)V
  001e return-void 
.end method

.method current()[B
  0000 iget-object v0, v2, Lcom/personal/aihub/ProjectVersions;->current Ljava/io/File;
  0004 const/high16 v1, 20971520
  0008 invoke-static v0, v1, Lcom/personal/aihub/ProjectVersions;->bytes(Ljava/io/File; I)[B
  000e move-result-object v0
  0010 invoke-virtual v2, v0, Lcom/personal/aihub/ProjectVersions;->project([B)Lorg/json/JSONObject;
  0016 return-object v0
.end method

.method list()Lorg/json/JSONObject;
  0000 invoke-virtual v5, Lcom/personal/aihub/ProjectVersions;->rows()Lorg/json/JSONArray;
  0006 move-result-object v0
  0008 new-instance v1, Lorg/json/JSONArray;
  000c invoke-direct v1, Lorg/json/JSONArray;-><init>()V
  0012 const/4 v2, 0
  0014 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  001a move-result v3
  001c if-ge v2, v3, +01ah
  0020 new-instance v3, Lorg/json/JSONObject;
  0024 invoke-virtual v0, v2, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  002a move-result-object v4
  002c invoke-virtual v4, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  0032 move-result-object v4
  0034 invoke-direct v3, v4, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  003a const-string v4, "fileBytes"
  003e invoke-virtual v3, v4, Lorg/json/JSONObject;->remove(Ljava/lang/String;)Ljava/lang/Object;
  0044 invoke-virtual v1, v3, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  004a add-int/lit8 v2, v2, 1
  004e goto -1dh
  0050 new-instance v0, Lorg/json/JSONObject;
  0054 invoke-direct v0, Lorg/json/JSONObject;-><init>()V
  005a const-string v2, "versions"
  005e invoke-virtual v0, v2, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0064 move-result-object v0
  0066 invoke-virtual v5, Lcom/personal/aihub/ProjectVersions;->current()[B
  006c move-result-object v1
  006e invoke-static v1, Lcom/personal/aihub/ProjectVersions;->revision([B)Ljava/lang/String;
  0074 move-result-object v1
  0076 const-string v2, "currentRevision"
  007a invoke-virtual v0, v2, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0080 move-result-object v0
  0082 return-object v0
.end method

.method load(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 const-string v0, "versionKey"
  0004 invoke-virtual v2, v0, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  000a move-result-object v2
  000c invoke-virtual v1, v2, Lcom/personal/aihub/ProjectVersions;->read(Ljava/lang/String;)[B
  0012 move-result-object v2
  0014 invoke-virtual v1, v2, Lcom/personal/aihub/ProjectVersions;->project([B)Lorg/json/JSONObject;
  001a move-result-object v2
  001c return-object v2
.end method

.method project([B)Lorg/json/JSONObject;
  0000 array-length v0, v3
  0002 const/high16 v1, 20971520
  0006 if-gt v0, v1, +030h
  000a new-instance v0, Lorg/json/JSONObject;
  000e invoke-static v3, Lcom/personal/aihub/ProjectVersions;->text([B)Ljava/lang/String;
  0014 move-result-object v3
  0016 invoke-direct v0, v3, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  001c const-string v3, "format"
  0020 invoke-virtual v0, v3, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0026 move-result-object v3
  0028 const-string v1, "dokkan-unit-forge"
  002c invoke-virtual v1, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0032 move-result v3
  0034 if-eqz v3, +011h
  0038 iget-object v3, v2, Lcom/personal/aihub/ProjectVersions;->key Ljava/lang/String;
  003c const-string v1, "key"
  0040 invoke-virtual v0, v1, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0046 move-result-object v1
  0048 invoke-virtual v3, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  004e move-result v3
  0050 if-eqz v3, +003h
  0054 return-object v0
  0056 new-instance v3, Ljava/io/IOException;
  005a const-string v0, "Backup does not belong to this project."
  005e invoke-direct v3, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0064 throw v3
  0066 new-instance v3, Ljava/io/IOException;
  006a const-string v0, "Project exceeds 20 MiB."
  006e invoke-direct v3, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0074 throw v3
.end method

.method read(Ljava/lang/String;)[B
  0000 invoke-static v8, Lcom/personal/aihub/ProjectVersions;->validVersion(Ljava/lang/String;)Z
  0006 move-result v0
  0008 if-eqz v0, +0b1h
  000c invoke-virtual v7, Lcom/personal/aihub/ProjectVersions;->rows()Lorg/json/JSONArray;
  0012 move-result-object v0
  0014 const/4 v1, 0
  0016 move v2, v1
  0018 move v3, v2
  001a invoke-virtual v0, Lorg/json/JSONArray;->length()I
  0020 move-result v4
  0022 const-string v5, "versionKey"
  0026 const/4 v6, 1
  0028 if-ge v2, v4, +014h
  002c invoke-virtual v0, v2, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  0032 move-result-object v4
  0034 invoke-virtual v4, v5, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  003a move-result-object v4
  003c invoke-virtual v8, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0042 move-result v4
  0044 if-eqz v4, +003h
  0048 move v3, v6
  004a add-int/lit8 v2, v2, 1
  004e goto -1ah
  0050 if-eqz v3, +085h
  0054 new-instance v0, Ljava/io/File;
  0058 iget-object v2, v7, Lcom/personal/aihub/ProjectVersions;->dir Ljava/io/File;
  005c new-instance v3, Ljava/lang/StringBuilder;
  0060 invoke-direct v3, Ljava/lang/StringBuilder;-><init>()V
  0066 invoke-virtual v3, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  006c const-string v4, ".version"
  0070 invoke-virtual v3, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0076 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  007c move-result-object v3
  007e invoke-direct v0, v2, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0084 const/high16 v2, 21037056
  0088 invoke-static v0, v2, Lcom/personal/aihub/ProjectVersions;->bytes(Ljava/io/File; I)[B
  008e move-result-object v0
  0090 move v2, v1
  0092 array-length v3, v0
  0094 if-ge v2, v3, +00bh
  0098 aget-byte v3, v0, v2
  009c const/16 v4, 10
  00a0 if-eq v3, v4, +005h
  00a4 add-int/lit8 v2, v2, 1
  00a8 goto -bh
  00aa if-lt v2, v6, +050h
  00ae const/high16 v3, 65536
  00b2 if-ge v2, v3, +04ch
  00b6 array-length v3, v0
  00b8 if-eq v2, v3, +049h
  00bc new-instance v3, Lorg/json/JSONObject;
  00c0 invoke-static v0, v1, v2, Ljava/util/Arrays;->copyOfRange([B I I)[B
  00c6 move-result-object v1
  00c8 invoke-static v1, Lcom/personal/aihub/ProjectVersions;->text([B)Ljava/lang/String;
  00ce move-result-object v1
  00d0 invoke-direct v3, v1, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  00d6 add-int/2addr v2, v6
  00d8 array-length v1, v0
  00da invoke-static v0, v2, v1, Ljava/util/Arrays;->copyOfRange([B I I)[B
  00e0 move-result-object v0
  00e2 invoke-virtual v3, v5, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  00e8 move-result-object v1
  00ea invoke-virtual v8, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00f0 move-result v8
  00f2 if-eqz v8, +024h
  00f6 iget-object v8, v7, Lcom/personal/aihub/ProjectVersions;->key Ljava/lang/String;
  00fa const-string v1, "key"
  00fe invoke-virtual v3, v1, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0104 move-result-object v1
  0106 invoke-virtual v8, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  010c move-result v8
  010e if-eqz v8, +016h
  0112 invoke-static v0, Lcom/personal/aihub/ProjectVersions;->revision([B)Ljava/lang/String;
  0118 move-result-object v8
  011a const-string v1, "revision"
  011e invoke-virtual v3, v1, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0124 move-result-object v1
  0126 invoke-virtual v8, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  012c move-result v8
  012e if-eqz v8, +006h
  0132 invoke-virtual v7, v0, Lcom/personal/aihub/ProjectVersions;->project([B)Lorg/json/JSONObject;
  0138 return-object v0
  013a new-instance v8, Ljava/io/IOException;
  013e const-string v0, "Backup checksum does not match."
  0142 invoke-direct v8, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0148 throw v8
  014a new-instance v8, Ljava/io/IOException;
  014e const-string v0, "Invalid backup envelope."
  0152 invoke-direct v8, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0158 throw v8
  015a new-instance v8, Ljava/io/IOException;
  015e const-string v0, "This saved version is no longer available."
  0162 invoke-direct v8, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0168 throw v8
  016a new-instance v8, Ljava/io/IOException;
  016e const-string v0, "Invalid backup key."
  0172 invoke-direct v8, v0, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0178 throw v8
.end method

.method restore(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 const-string v0, "updatedAt"
  0004 invoke-virtual v14, Lcom/personal/aihub/ProjectVersions;->current()[B
  000a move-result-object v1
  000c const/4 v2, 1
  000e invoke-virtual v14, v15, v1, v2, Lcom/personal/aihub/ProjectVersions;->check(Lorg/json/JSONObject; [B Z)V
  0014 const-string v3, "versionKey"
  0018 invoke-virtual v15, v3, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  001e move-result-object v15
  0020 invoke-virtual v14, v15, Lcom/personal/aihub/ProjectVersions;->read(Ljava/lang/String;)[B
  0026 move-result-object v15
  0028 invoke-virtual v14, Lcom/personal/aihub/ProjectVersions;->rows()Lorg/json/JSONArray;
  002e move-result-object v4
  0030 const-string v5, "Before restoring an earlier version"
  0034 invoke-virtual v14, v1, v5, Lcom/personal/aihub/ProjectVersions;->candidate([B Ljava/lang/String;)Lorg/json/JSONObject;
  003a move-result-object v5
  003c invoke-virtual v14, v5, v4, Lcom/personal/aihub/ProjectVersions;->with(Lorg/json/JSONObject; Lorg/json/JSONArray;)Lorg/json/JSONArray;
  0042 move-result-object v6
  0044 invoke-virtual v14, v6, Lcom/personal/aihub/ProjectVersions;->commit(Lorg/json/JSONArray;)V
  004a invoke-virtual v14, v15, Lcom/personal/aihub/ProjectVersions;->project([B)Lorg/json/JSONObject;
  0050 move-result-object v15
  0052 new-instance v7, Ljava/text/SimpleDateFormat;
  0056 const-string v8, "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
  005a sget-object v9, Ljava/util/Locale;->US Ljava/util/Locale;
  005e invoke-direct v7, v8, v9, Ljava/text/SimpleDateFormat;-><init>(Ljava/lang/String; Ljava/util/Locale;)V
  0064 const-string v8, "UTC"
  0068 invoke-static v8, Ljava/util/TimeZone;->getTimeZone(Ljava/lang/String;)Ljava/util/TimeZone;
  006e move-result-object v8
  0070 invoke-virtual v7, v8, Ljava/text/SimpleDateFormat;->setTimeZone(Ljava/util/TimeZone;)V
  0076 const/4 v8, 0
  0078 invoke-virtual v7, v8, Ljava/text/SimpleDateFormat;->setLenient(Z)V
  007e invoke-static Ljava/lang/System;->currentTimeMillis()J
  0084 move-result-wide v8
  0086 invoke-virtual v14, v1, Lcom/personal/aihub/ProjectVersions;->project([B)Lorg/json/JSONObject;
  008c move-result-object v1
  008e invoke-virtual v1, v0, Lorg/json/JSONObject;->optString(Ljava/lang/String;)Ljava/lang/String;
  0094 move-result-object v1
  0096 const-string v10, "\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z"
  009a invoke-virtual v1, v10, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  00a0 move-result v10
  00a2 if-eqz v10, +011h
  00a6 invoke-virtual v7, v1, Ljava/text/SimpleDateFormat;->parse(Ljava/lang/String;)Ljava/util/Date;
  00ac move-result-object v1
  00ae invoke-virtual v1, Ljava/util/Date;->getTime()J
  00b4 move-result-wide v10
  00b6 const-wide/16 v12, 1
  00ba add-long/2addr v10, v12
  00bc invoke-static v8, v9, v10, v11, Ljava/lang/Math;->max(J J)J
  00c2 move-result-wide v8
  00c4 new-instance v1, Ljava/util/Date;
  00c8 invoke-direct v1, v8, v9, Ljava/util/Date;-><init>(J)V
  00ce invoke-virtual v7, v1, Ljava/text/SimpleDateFormat;->format(Ljava/util/Date;)Ljava/lang/String;
  00d4 move-result-object v1
  00d6 invoke-virtual v15, v0, v1, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  00dc invoke-virtual v15, Lorg/json/JSONObject;->toString()Ljava/lang/String;
  00e2 move-result-object v15
  00e4 sget-object v0, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  00e8 invoke-virtual v15, v0, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  00ee move-result-object v15
  00f0 iget-object v0, v14, Lcom/personal/aihub/ProjectVersions;->current Ljava/io/File;
  00f4 invoke-static v0, v15, Lcom/personal/aihub/ProjectVersions;->atomic(Ljava/io/File; [B)V
  00fa invoke-virtual v14, v6, Lcom/personal/aihub/ProjectVersions;->clean(Lorg/json/JSONArray;)V
  0100 invoke-virtual v14, Lcom/personal/aihub/ProjectVersions;->list()Lorg/json/JSONObject;
  0106 move-result-object v0
  0108 const-string v1, "saved"
  010c invoke-virtual v0, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0112 move-result-object v0
  0114 const-string v1, "project"
  0118 invoke-virtual v14, v15, Lcom/personal/aihub/ProjectVersions;->project([B)Lorg/json/JSONObject;
  011e move-result-object v15
  0120 invoke-virtual v0, v1, v15, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0126 move-result-object v15
  0128 return-object v15
  012a move-exception v15
  012c invoke-virtual v14, v4, Lcom/personal/aihub/ProjectVersions;->commit(Lorg/json/JSONArray;)V
  0132 throw v15
  0134 move-exception v15
  0136 new-instance v0, Ljava/io/File;
  013a iget-object v1, v14, Lcom/personal/aihub/ProjectVersions;->dir Ljava/io/File;
  013e new-instance v2, Ljava/lang/StringBuilder;
  0142 invoke-direct v2, Ljava/lang/StringBuilder;-><init>()V
  0148 invoke-virtual v5, v3, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  014e move-result-object v3
  0150 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0156 const-string v3, ".version"
  015a invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0160 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0166 move-result-object v2
  0168 invoke-direct v0, v1, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  016e invoke-virtual v0, Ljava/io/File;->delete()Z
  0174 throw v15
.end method

.method rows()Lorg/json/JSONArray;
  0000 iget-object v0, v13, Lcom/personal/aihub/ProjectVersions;->index Ljava/io/File;
  0004 invoke-virtual v0, Ljava/io/File;->exists()Z
  000a move-result v0
  000c if-nez v0, +008h
  0010 new-instance v0, Lorg/json/JSONArray;
  0014 invoke-direct v0, Lorg/json/JSONArray;-><init>()V
  001a return-object v0
  001c new-instance v0, Lorg/json/JSONArray;
  0020 iget-object v1, v13, Lcom/personal/aihub/ProjectVersions;->index Ljava/io/File;
  0024 const/high16 v2, 65536
  0028 invoke-static v1, v2, Lcom/personal/aihub/ProjectVersions;->bytes(Ljava/io/File; I)[B
  002e move-result-object v1
  0030 invoke-static v1, Lcom/personal/aihub/ProjectVersions;->text([B)Ljava/lang/String;
  0036 move-result-object v1
  0038 invoke-direct v0, v1, Lorg/json/JSONArray;-><init>(Ljava/lang/String;)V
  003e new-instance v1, Ljava/util/HashSet;
  0042 invoke-direct v1, Ljava/util/HashSet;-><init>()V
  0048 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  004e move-result v2
  0050 const/16 v3, 10
  0054 const-string v4, "Invalid saved version index."
  0058 if-gt v2, v3, +073h
  005c const-wide/16 v2, 0
  0060 const/4 v5, 0
  0062 invoke-virtual v0, Lorg/json/JSONArray;->length()I
  0068 move-result v6
  006a if-ge v5, v6, +05ah
  006e invoke-virtual v0, v5, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  0074 move-result-object v6
  0076 const-string v7, "bytes"
  007a invoke-virtual v6, v7, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0080 move-result-wide v7
  0082 const-string v9, "fileBytes"
  0086 invoke-virtual v6, v9, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  008c move-result-wide v9
  008e const-string v11, "versionKey"
  0092 invoke-virtual v6, v11, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  0098 move-result-object v11
  009a invoke-static v11, Lcom/personal/aihub/ProjectVersions;->validVersion(Ljava/lang/String;)Z
  00a0 move-result v12
  00a2 if-eqz v12, +038h
  00a6 invoke-interface v1, v11, Ljava/util/Set;->add(Ljava/lang/Object;)Z
  00ac move-result v11
  00ae if-eqz v11, +032h
  00b2 const-wide/16 v11, 1
  00b6 cmp-long v11, v7, v11
  00ba if-ltz v11, +02ch
  00be const-wide/32 v11, 20971520
  00c4 cmp-long v11, v7, v11
  00c8 if-gtz v11, +025h
  00cc cmp-long v11, v9, v7
  00d0 if-ltz v11, +021h
  00d4 const-wide/32 v11, 65536
  00da add-long/2addr v7, v11
  00dc cmp-long v7, v9, v7
  00e0 if-gtz v7, +019h
  00e4 const-string v7, "label"
  00e8 invoke-virtual v6, v7, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  00ee move-result-object v7
  00f0 invoke-virtual v7, Ljava/lang/String;->length()I
  00f6 move-result v7
  00f8 const/16 v8, 160
  00fc if-gt v7, v8, +00bh
  0100 const-string v7, "createdAt"
  0104 invoke-virtual v6, v7, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  010a add-long/2addr v2, v9
  010c add-int/lit8 v5, v5, 1
  0110 goto -57h
  0112 new-instance v0, Ljava/io/IOException;
  0116 invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  011c throw v0
  011e const-wide/32 v4, 41943040
  0124 cmp-long v1, v2, v4
  0128 if-gtz v1, +003h
  012c return-object v0
  012e new-instance v0, Ljava/io/IOException;
  0132 const-string v1, "Saved versions exceed their size limit."
  0136 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  013c throw v0
  013e new-instance v0, Ljava/io/IOException;
  0142 invoke-direct v0, v4, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0148 throw v0
.end method

.method save(Lorg/json/JSONObject;)Lorg/json/JSONObject;
  0000 invoke-virtual v5, Lcom/personal/aihub/ProjectVersions;->current()[B
  0006 move-result-object v0
  0008 const/4 v1, 0
  000a invoke-virtual v5, v6, v0, v1, Lcom/personal/aihub/ProjectVersions;->check(Lorg/json/JSONObject; [B Z)V
  0010 invoke-virtual v5, Lcom/personal/aihub/ProjectVersions;->rows()Lorg/json/JSONArray;
  0016 move-result-object v1
  0018 const-string v2, "label"
  001c const/4 v3, 0
  001e invoke-virtual v6, v2, v3, Lorg/json/JSONObject;->optString(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0024 move-result-object v6
  0026 invoke-virtual v5, v0, v6, Lcom/personal/aihub/ProjectVersions;->candidate([B Ljava/lang/String;)Lorg/json/JSONObject;
  002c move-result-object v6
  002e invoke-virtual v5, v6, v1, Lcom/personal/aihub/ProjectVersions;->with(Lorg/json/JSONObject; Lorg/json/JSONArray;)Lorg/json/JSONArray;
  0034 move-result-object v0
  0036 invoke-virtual v5, v0, Lcom/personal/aihub/ProjectVersions;->commit(Lorg/json/JSONArray;)V
  003c invoke-virtual v5, v0, Lcom/personal/aihub/ProjectVersions;->clean(Lorg/json/JSONArray;)V
  0042 invoke-virtual v5, Lcom/personal/aihub/ProjectVersions;->list()Lorg/json/JSONObject;
  0048 move-result-object v0
  004a const-string v1, "saved"
  004e const/4 v2, 1
  0050 invoke-virtual v0, v1, v2, Lorg/json/JSONObject;->put(Ljava/lang/String; Z)Lorg/json/JSONObject;
  0056 move-result-object v0
  0058 invoke-virtual v6, Lorg/json/JSONObject;->keys()Ljava/util/Iterator;
  005e move-result-object v1
  0060 invoke-interface v1, Ljava/util/Iterator;->hasNext()Z
  0066 move-result v2
  0068 if-eqz v2, +018h
  006c invoke-interface v1, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0072 move-result-object v2
  0074 check-cast v2, Ljava/lang/String;
  0078 const-string v3, "fileBytes"
  007c invoke-virtual v2, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0082 move-result v3
  0084 if-nez v3, -012h
  0088 invoke-virtual v6, v2, Lorg/json/JSONObject;->get(Ljava/lang/String;)Ljava/lang/Object;
  008e move-result-object v3
  0090 invoke-virtual v0, v2, v3, Lorg/json/JSONObject;->put(Ljava/lang/String; Ljava/lang/Object;)Lorg/json/JSONObject;
  0096 goto -1bh
  0098 return-object v0
  009a move-exception v0
  009c new-instance v1, Ljava/io/File;
  00a0 iget-object v2, v5, Lcom/personal/aihub/ProjectVersions;->dir Ljava/io/File;
  00a4 new-instance v3, Ljava/lang/StringBuilder;
  00a8 invoke-direct v3, Ljava/lang/StringBuilder;-><init>()V
  00ae const-string v4, "versionKey"
  00b2 invoke-virtual v6, v4, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  00b8 move-result-object v6
  00ba invoke-virtual v3, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00c0 const-string v6, ".version"
  00c4 invoke-virtual v3, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00ca invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00d0 move-result-object v6
  00d2 invoke-direct v1, v2, v6, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00d8 invoke-virtual v1, Ljava/io/File;->delete()Z
  00de throw v0
.end method

.method with(Lorg/json/JSONObject; Lorg/json/JSONArray;)Lorg/json/JSONArray;
  0000 new-instance v0, Lorg/json/JSONArray;
  0004 invoke-direct v0, Lorg/json/JSONArray;-><init>()V
  000a invoke-virtual v0, v10, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  0010 move-result-object v0
  0012 const-string v1, "fileBytes"
  0016 invoke-virtual v10, v1, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  001c move-result-wide v2
  001e const/4 v10, 0
  0020 invoke-virtual v11, Lorg/json/JSONArray;->length()I
  0026 move-result v4
  0028 if-ge v10, v4, +026h
  002c invoke-virtual v0, Lorg/json/JSONArray;->length()I
  0032 move-result v4
  0034 const/16 v5, 10
  0038 if-ge v4, v5, +01eh
  003c invoke-virtual v11, v10, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  0042 move-result-object v4
  0044 invoke-virtual v4, v1, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  004a move-result-wide v5
  004c add-long/2addr v5, v2
  004e const-wide/32 v7, 41943040
  0054 cmp-long v5, v5, v7
  0058 if-lez v5, +003h
  005c goto +ch
  005e invoke-virtual v4, v1, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J
  0064 move-result-wide v5
  0066 add-long/2addr v2, v5
  0068 invoke-virtual v0, v4, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;
  006e add-int/lit8 v10, v10, 1
  0072 goto -29h
  0074 return-object v0
.end method