.class Lcom/personal/aihub/CpkWriter;
.super Ljava/lang/Object;
.field ALIGN I
.field MAX_FILES I
.field MAX_FILE_BYTES I
.field MAX_TOTAL_BYTES I
.field PRIVATE Ljava/util/Set;

.method <clinit>()V
  0000 new-instance v0, Ljava/util/HashSet;
  0004 const-string v10, "credentials.json"
  0008 const-string v11, "secrets.json"
  000c const-string v1, "projects"
  0010 const-string v2, "patches"
  0014 const-string v3, "exports"
  0018 const-string v4, "_databases"
  001c const-string v5, "metadata.json"
  0020 const-string v6, "forge-project.json"
  0024 const-string v7, "database-meta.json"
  0028 const-string v8, "database-state.json"
  002c const-string v9, "account.txt"
  0030 filled-new-array/range v1 ... v11, [Ljava/lang/String;
  0036 move-result-object v1
  0038 invoke-static v1, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;
  003e move-result-object v1
  0040 invoke-direct v0, v1, Ljava/util/HashSet;-><init>(Ljava/util/Collection;)V
  0046 sput-object v0, Lcom/personal/aihub/CpkWriter;->PRIVATE Ljava/util/Set;
  004a return-void 
.end method

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method align(J)I
  0000 const-wide/16 v0, 2047
  0004 add-long/2addr v2, v0
  0006 const-wide/16 v0, 2048
  000a div-long/2addr v2, v0
  000c mul-long/2addr v2, v0
  000e const-wide/32 v0, 536870912
  0014 cmp-long v0, v2, v0
  0018 if-gtz v0, +004h
  001c long-to-int v2, v2
  001e return v2
  0020 const-string v2, "Archive exceeds512MB."
  0024 invoke-static v2, Lcom/personal/aihub/CpkWriter;->error(Ljava/lang/String;)Ljava/io/IOException;
  002a move-result-object v2
  002c throw v2
.end method

.method c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  0000 new-instance v0, Lcom/personal/aihub/CpkWriter$Col;
  0004 invoke-direct v0, v1, v2, Lcom/personal/aihub/CpkWriter$Col;-><init>(Ljava/lang/String; I)V
  000a return-object v0
.end method

.method compareCriPaths(Ljava/lang/String; Ljava/lang/String;)I
  0000 sget-object v0, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0004 invoke-virtual v5, v0, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  000a move-result-object v5
  000c sget-object v0, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0010 invoke-virtual v6, v0, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0016 move-result-object v6
  0018 const/4 v0, 0
  001a array-length v1, v5
  001c array-length v2, v6
  001e invoke-static v1, v2, Ljava/lang/Math;->min(I I)I
  0024 move-result v1
  0026 if-ge v0, v1, +021h
  002a aget-byte v1, v5, v0
  002e and-int/lit16 v1, v1, 255
  0032 aget-byte v2, v6, v0
  0036 and-int/lit16 v2, v2, 255
  003a const/16 v3, 122
  003e const/16 v4, 97
  0042 if-lt v1, v4, +006h
  0046 if-gt v1, v3, +004h
  004a add-int/lit8 v1, v1, -32
  004e if-lt v2, v4, +006h
  0052 if-gt v2, v3, +004h
  0056 add-int/lit8 v2, v2, -32
  005a if-eq v1, v2, +004h
  005e sub-int/2addr v1, v2
  0060 return v1
  0062 add-int/lit8 v0, v0, 1
  0066 goto -26h
  0068 array-length v5, v5
  006a array-length v6, v6
  006c sub-int/2addr v5, v6
  006e return v5
.end method

.method compareUtf8(Ljava/lang/String; Ljava/lang/String;)I
  0000 sget-object v0, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0004 invoke-virtual v3, v0, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  000a move-result-object v3
  000c sget-object v0, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  0010 invoke-virtual v4, v0, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0016 move-result-object v4
  0018 const/4 v0, 0
  001a array-length v1, v3
  001c array-length v2, v4
  001e invoke-static v1, v2, Ljava/lang/Math;->min(I I)I
  0024 move-result v1
  0026 if-ge v0, v1, +011h
  002a aget-byte v1, v3, v0
  002e and-int/lit16 v1, v1, 255
  0032 aget-byte v2, v4, v0
  0036 and-int/lit16 v2, v2, 255
  003a sub-int/2addr v1, v2
  003c if-eqz v1, +003h
  0040 return v1
  0042 add-int/lit8 v0, v0, 1
  0046 goto -16h
  0048 array-length v3, v3
  004a array-length v4, v4
  004c sub-int/2addr v3, v4
  004e return v3
.end method

.method error(Ljava/lang/String;)Ljava/io/IOException;
  0000 new-instance v0, Ljava/io/IOException;
  0004 new-instance v1, Ljava/lang/StringBuilder;
  0008 const-string v2, "CPK: "
  000c invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0012 invoke-virtual v1, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0018 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  001e move-result-object v3
  0020 invoke-direct v0, v3, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0026 return-object v0
.end method

.method header(J J J I J)[B
  0000 const/16 v0, 15
  0004 new-array v0, v0, [Lcom/personal/aihub/CpkWriter$Col;
  0008 const-string v1, "ContentOffset"
  000c const/4 v2, 6
  000e invoke-static v1, v2, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  0014 move-result-object v1
  0016 const/4 v3, 0
  0018 aput-object v1, v0, v3
  001c const-string v1, "ContentSize"
  0020 invoke-static v1, v2, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  0026 move-result-object v1
  0028 const/4 v4, 1
  002a invoke-static v4, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0030 move-result-object v28
  0032 move-object/from16 v22, v28
  0036 move-object/from16 v24, v28
  003a aput-object v1, v0, v4
  003e const-string v1, "TocOffset"
  0042 invoke-static v1, v2, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  0048 move-result-object v1
  004a const/4 v4, 2
  004c aput-object v1, v0, v4
  0050 const-string v1, "TocSize"
  0054 invoke-static v1, v2, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  005a move-result-object v1
  005c const/4 v5, 3
  005e aput-object v1, v0, v5
  0062 const-string v1, "Files"
  0066 const/4 v5, 4
  0068 invoke-static v1, v5, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  006e move-result-object v1
  0070 aput-object v1, v0, v5
  0074 const-string v1, "Version"
  0078 invoke-static v1, v4, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  007e move-result-object v1
  0080 const/4 v6, 5
  0082 aput-object v1, v0, v6
  0086 const-string v1, "Revision"
  008a invoke-static v1, v4, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  0090 move-result-object v1
  0092 aput-object v1, v0, v2
  0096 const-string v1, "Align"
  009a invoke-static v1, v4, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  00a0 move-result-object v1
  00a2 const/4 v7, 7
  00a4 aput-object v1, v0, v7
  00a8 const-string v1, "Sorted"
  00ac invoke-static v1, v4, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  00b2 move-result-object v1
  00b4 const/16 v6, 8
  00b8 aput-object v1, v0, v6
  00bc const-string v1, "EnableFileName"
  00c0 invoke-static v1, v4, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  00c6 move-result-object v1
  00c8 const/16 v6, 9
  00cc aput-object v1, v0, v6
  00d0 const-string v1, "EID"
  00d4 invoke-static v1, v4, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  00da move-result-object v1
  00dc const/16 v4, 10
  00e0 aput-object v1, v0, v4
  00e4 const-string v1, "CpkMode"
  00e8 invoke-static v1, v5, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  00ee move-result-object v1
  00f0 const/16 v5, 11
  00f4 aput-object v1, v0, v5
  00f8 const-string v1, "Tvers"
  00fc invoke-static v1, v4, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  0102 move-result-object v1
  0104 const/16 v4, 12
  0108 aput-object v1, v0, v4
  010c const-string v1, "EnabledPackedSize"
  0110 invoke-static v1, v2, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  0116 move-result-object v1
  0118 const/16 v4, 13
  011c aput-object v1, v0, v4
  0120 const-string v1, "EnabledDataSize"
  0124 invoke-static v1, v2, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  012a move-result-object v1
  012c const/16 v2, 14
  0130 aput-object v1, v0, v2
  0134 invoke-static/range v35 ... v36, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  013a move-result-object v6
  013c invoke-static/range v37 ... v38, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  0142 move-result-object v8
  0144 const/16 v1, 2048
  0148 invoke-static v1, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  014e move-result-object v10
  0150 move-object/from16 v20, v10
  0154 invoke-static/range v39 ... v40, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  015a move-result-object v12
  015c invoke-static/range v41, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0162 move-result-object v14
  0164 invoke-static v7, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  016a move-result-object v16
  016c invoke-static v2, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0172 move-result-object v18
  0174 invoke-static v3, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  017a move-result-object v26
  017c invoke-static/range v42 ... v43, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  0182 move-result-object v32
  0184 const-string v33, "EnabledDataSize"
  0188 invoke-static/range v42 ... v43, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  018e move-result-object v34
  0190 const-string v5, "ContentOffset"
  0194 const-string v7, "ContentSize"
  0198 const-string v9, "TocOffset"
  019c const-string v11, "TocSize"
  01a0 const-string v13, "Files"
  01a4 const-string v15, "Version"
  01a8 const-string v17, "Revision"
  01ac const-string v19, "Align"
  01b0 const-string v21, "Sorted"
  01b4 const-string v23, "EnableFileName"
  01b8 const-string v25, "EID"
  01bc const-string v27, "CpkMode"
  01c0 const-string v29, "Tvers"
  01c4 const-string v30, "Dokkan Unit Creator"
  01c8 const-string v31, "EnabledPackedSize"
  01cc filled-new-array/range v5 ... v34, [Ljava/lang/Object;
  01d2 move-result-object v1
  01d4 invoke-static v1, Lcom/personal/aihub/CpkWriter;->row([Ljava/lang/Object;)Ljava/util/Map;
  01da move-result-object v1
  01dc invoke-static v1, Ljava/util/Collections;->singletonList(Ljava/lang/Object;)Ljava/util/List;
  01e2 move-result-object v1
  01e4 const-string v2, "CpkHeader"
  01e8 invoke-static v2, v0, v1, Lcom/personal/aihub/CpkWriter;->utf(Ljava/lang/String; [Lcom/personal/aihub/CpkWriter$Col; Ljava/util/List;)[B
  01ee move-result-object v0
  01f0 const-string v1, "CPK "
  01f4 invoke-static v1, v0, Lcom/personal/aihub/CpkWriter;->packet(Ljava/lang/String; [B)[B
  01fa move-result-object v0
  01fc return-object v0
.end method

.method lambda$0(Ljava/util/Map; Ljava/io/ByteArrayOutputStream; Ljava/lang/String;)Ljava/lang/Integer;
  0000 invoke-interface v4, v6, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0006 move-result-object v0
  0008 check-cast v0, Ljava/lang/Integer;
  000c if-eqz v0, +003h
  0010 return-object v0
  0012 invoke-virtual v5, Ljava/io/ByteArrayOutputStream;->size()I
  0018 move-result v0
  001a sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  001e invoke-virtual v6, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0024 move-result-object v1
  0026 array-length v2, v1
  0028 const/4 v3, 0
  002a invoke-virtual v5, v1, v3, v2, Ljava/io/ByteArrayOutputStream;->write([B I I)V
  0030 invoke-virtual v5, v3, Ljava/io/ByteArrayOutputStream;->write(I)V
  0036 invoke-static v0, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  003c move-result-object v5
  003e invoke-interface v4, v6, v5, Ljava/util/Map;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0044 invoke-static v0, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  004a move-result-object v4
  004c return-object v4
.end method

.method packet(Ljava/lang/String; [B)[B
  0000 array-length v0, v4
  0002 add-int/lit8 v0, v0, 16
  0006 invoke-static v0, Ljava/nio/ByteBuffer;->allocate(I)Ljava/nio/ByteBuffer;
  000c move-result-object v0
  000e sget-object v1, Ljava/nio/ByteOrder;->LITTLE_ENDIAN Ljava/nio/ByteOrder;
  0012 invoke-virtual v0, v1, Ljava/nio/ByteBuffer;->order(Ljava/nio/ByteOrder;)Ljava/nio/ByteBuffer;
  0018 move-result-object v0
  001a sget-object v1, Ljava/nio/charset/StandardCharsets;->US_ASCII Ljava/nio/charset/Charset;
  001e invoke-virtual v3, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0024 move-result-object v3
  0026 invoke-virtual v0, v3, Ljava/nio/ByteBuffer;->put([B)Ljava/nio/ByteBuffer;
  002c move-result-object v3
  002e const/16 v1, 255
  0032 invoke-virtual v3, v1, Ljava/nio/ByteBuffer;->putInt(I)Ljava/nio/ByteBuffer;
  0038 move-result-object v3
  003a array-length v1, v4
  003c int-to-long v1, v1
  003e invoke-virtual v3, v1, v2, Ljava/nio/ByteBuffer;->putLong(J)Ljava/nio/ByteBuffer;
  0044 move-result-object v3
  0046 invoke-virtual v3, v4, Ljava/nio/ByteBuffer;->put([B)Ljava/nio/ByteBuffer;
  004c invoke-virtual v0, Ljava/nio/ByteBuffer;->array()[B
  0052 move-result-object v3
  0054 return-object v3
.end method

.method padding(Ljava/io/OutputStream; J)V
  0000 const/16 v0, 2048
  0004 new-array v0, v0, [B
  0008 const-wide/16 v1, 0
  000c cmp-long v1, v4, v1
  0010 if-lez v1, +010h
  0014 const-wide/16 v1, 2048
  0018 invoke-static v4, v5, v1, v2, Ljava/lang/Math;->min(J J)J
  001e move-result-wide v1
  0020 long-to-int v1, v1
  0022 const/4 v2, 0
  0024 invoke-virtual v3, v0, v2, v1, Ljava/io/OutputStream;->write([B I I)V
  002a int-to-long v1, v1
  002c sub-long/2addr v4, v1
  002e goto -13h
  0030 return-void 
.end method

.method row([Ljava/lang/Object;)Ljava/util/Map;
  0000 new-instance v0, Ljava/util/LinkedHashMap;
  0004 invoke-direct v0, Ljava/util/LinkedHashMap;-><init>()V
  000a const/4 v1, 0
  000c array-length v2, v4
  000e if-ge v1, v2, +010h
  0012 aget-object v2, v4, v1
  0016 check-cast v2, Ljava/lang/String;
  001a add-int/lit8 v3, v1, 1
  001e aget-object v3, v4, v3
  0022 invoke-virtual v0, v2, v3, Ljava/util/LinkedHashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0028 add-int/lit8 v1, v1, 2
  002c goto -10h
  002e return-object v0
.end method

.method safe(Ljava/lang/String;)Z
  0000 const/4 v0, 0
  0002 if-eqz v7, +070h
  0006 invoke-virtual v7, Ljava/lang/String;->isEmpty()Z
  000c move-result v1
  000e if-nez v1, +06ah
  0012 invoke-virtual v7, Ljava/lang/String;->length()I
  0018 move-result v1
  001a const/16 v2, 500
  001e if-gt v1, v2, +062h
  0022 const-string v1, "/"
  0026 invoke-virtual v7, v1, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  002c move-result v2
  002e if-nez v2, +05ah
  0032 invoke-virtual v7, Ljava/lang/String;->toCharArray()[C
  0038 move-result-object v2
  003a array-length v3, v2
  003c move v4, v0
  003e if-ge v4, v3, +01dh
  0042 aget-char v5, v2, v4
  0046 const/16 v6, 92
  004a if-eq v5, v6, +016h
  004e const/16 v6, 58
  0052 if-eq v5, v6, +012h
  0056 const/16 v6, 37
  005a if-eq v5, v6, +00eh
  005e const/16 v6, 32
  0062 if-lt v5, v6, +00ah
  0066 const/16 v6, 127
  006a if-ne v5, v6, +003h
  006e goto +4h
  0070 add-int/lit8 v4, v4, 1
  0074 goto -1bh
  0076 return v0
  0078 const/4 v2, -1
  007a invoke-virtual v7, v1, v2, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  0080 move-result-object v1
  0082 array-length v2, v1
  0084 move v3, v0
  0086 if-ge v3, v2, +025h
  008a aget-object v4, v1, v3
  008e invoke-virtual v4, Ljava/lang/String;->isEmpty()Z
  0094 move-result v5
  0096 if-nez v5, +01ch
  009a const-string v5, "."
  009e invoke-virtual v4, v5, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00a4 move-result v5
  00a6 if-nez v5, +014h
  00aa sget-object v5, Lcom/personal/aihub/CpkWriter;->PRIVATE Ljava/util/Set;
  00ae sget-object v6, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  00b2 invoke-virtual v4, v6, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  00b8 move-result-object v4
  00ba invoke-interface v5, v4, Ljava/util/Set;->contains(Ljava/lang/Object;)Z
  00c0 move-result v4
  00c2 if-eqz v4, +003h
  00c6 goto +4h
  00c8 add-int/lit8 v3, v3, 1
  00cc goto -23h
  00ce return v0
  00d0 const-string v0, "(?i).*\.(db|sqlite|sqlite3)([-.].*)?$"
  00d4 invoke-virtual v7, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  00da move-result v7
  00dc xor-int/lit8 v7, v7, 1
  00e0 return v7
  00e2 return v0
.end method

.method source(Ljava/io/File; Ljava/lang/String;)Ljava/io/File;
  0000 invoke-static v6, Lcom/personal/aihub/CpkWriter;->safe(Ljava/lang/String;)Z
  0006 move-result v0
  0008 if-eqz v0, +075h
  000c invoke-virtual v5, Ljava/io/File;->isDirectory()Z
  0012 move-result v0
  0014 if-eqz v0, +06fh
  0018 invoke-virtual v5, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  001e move-result-object v0
  0020 invoke-static v0, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  0026 move-result v0
  0028 if-nez v0, +065h
  002c const-string v0, "/"
  0030 invoke-virtual v6, v0, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
  0036 move-result-object v6
  0038 array-length v0, v6
  003a const/4 v1, 0
  003c move-object v2, v5
  003e if-ge v1, v0, +01eh
  0042 new-instance v3, Ljava/io/File;
  0046 aget-object v4, v6, v1
  004a invoke-direct v3, v2, v4, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0050 invoke-virtual v3, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0056 move-result-object v2
  0058 invoke-static v2, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  005e move-result v2
  0060 if-nez v2, +006h
  0064 add-int/lit8 v1, v1, 1
  0068 move-object v2, v3
  006a goto -16h
  006c const-string v5, "Imported assets cannot use symbolic links."
  0070 invoke-static v5, Lcom/personal/aihub/CpkWriter;->error(Ljava/lang/String;)Ljava/io/IOException;
  0076 move-result-object v5
  0078 throw v5
  007a invoke-virtual v2, Ljava/io/File;->isFile()Z
  0080 move-result v6
  0082 if-eqz v6, +031h
  0086 invoke-virtual v2, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  008c move-result-object v6
  008e new-instance v0, Ljava/lang/StringBuilder;
  0092 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  0098 invoke-virtual v5, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  009e move-result-object v5
  00a0 invoke-static v5, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  00a6 move-result-object v5
  00a8 invoke-virtual v0, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00ae sget-object v5, Ljava/io/File;->separator Ljava/lang/String;
  00b2 invoke-virtual v0, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00b8 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  00be move-result-object v5
  00c0 invoke-virtual v6, v5, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  00c6 move-result v5
  00c8 if-eqz v5, +00eh
  00cc invoke-virtual v2, Ljava/io/File;->length()J
  00d2 move-result-wide v5
  00d4 const-wide/32 v0, 167772160
  00da cmp-long v5, v5, v0
  00de if-gtz v5, +003h
  00e2 return-object v2
  00e4 const-string v5, "Missing or oversized imported asset."
  00e8 invoke-static v5, Lcom/personal/aihub/CpkWriter;->error(Ljava/lang/String;)Ljava/io/IOException;
  00ee move-result-object v5
  00f0 throw v5
  00f2 const-string v5, "Invalid imported asset key."
  00f6 invoke-static v5, Lcom/personal/aihub/CpkWriter;->error(Ljava/lang/String;)Ljava/io/IOException;
  00fc move-result-object v5
  00fe throw v5
.end method

.method toc(Ljava/util/List;)[B
  0000 new-instance v0, Ljava/util/ArrayList;
  0004 invoke-direct v0, Ljava/util/ArrayList;-><init>()V
  000a const/4 v1, 0
  000c move v2, v1
  000e invoke-interface/range v21, Ljava/util/List;->size()I
  0014 move-result v3
  0016 if-ge v2, v3, +05dh
  001a move-object/from16 v3, v21
  001e invoke-interface v3, v2, Ljava/util/List;->get(I)Ljava/lang/Object;
  0024 move-result-object v4
  0026 check-cast v4, Lcom/personal/aihub/CpkWriter$Source;
  002a iget-object v5, v4, Lcom/personal/aihub/CpkWriter$Source;->path Ljava/lang/String;
  002e const/16 v6, 47
  0032 invoke-virtual v5, v6, Ljava/lang/String;->lastIndexOf(I)I
  0038 move-result v5
  003a if-gez v5, +005h
  003e const-string v6, ""
  0042 goto +7h
  0044 iget-object v6, v4, Lcom/personal/aihub/CpkWriter$Source;->path Ljava/lang/String;
  0048 invoke-virtual v6, v1, v5, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  004e move-result-object v6
  0050 move-object v8, v6
  0052 iget-object v6, v4, Lcom/personal/aihub/CpkWriter$Source;->path Ljava/lang/String;
  0056 add-int/lit8 v5, v5, 1
  005a invoke-virtual v6, v5, Ljava/lang/String;->substring(I)Ljava/lang/String;
  0060 move-result-object v10
  0062 iget-wide v5, v4, Lcom/personal/aihub/CpkWriter$Source;->size J
  0066 invoke-static v5, v6, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  006c move-result-object v12
  006e iget-wide v5, v4, Lcom/personal/aihub/CpkWriter$Source;->size J
  0072 invoke-static v5, v6, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  0078 move-result-object v14
  007a iget-wide v4, v4, Lcom/personal/aihub/CpkWriter$Source;->offset J
  007e const-wide/16 v6, 2048
  0082 sub-long/2addr v4, v6
  0084 invoke-static v4, v5, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  008a move-result-object v16
  008c invoke-static v2, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
  0092 move-result-object v18
  0094 const-string v19, "UserString"
  0098 const-string v20, ""
  009c const-string v7, "DirName"
  00a0 const-string v9, "FileName"
  00a4 const-string v11, "FileSize"
  00a8 const-string v13, "ExtractSize"
  00ac const-string v15, "FileOffset"
  00b0 const-string v17, "ID"
  00b4 filled-new-array/range v7 ... v20, [Ljava/lang/Object;
  00ba move-result-object v4
  00bc invoke-static v4, Lcom/personal/aihub/CpkWriter;->row([Ljava/lang/Object;)Ljava/util/Map;
  00c2 move-result-object v4
  00c4 invoke-virtual v0, v4, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  00ca add-int/lit8 v2, v2, 1
  00ce goto -60h
  00d0 const/4 v2, 7
  00d2 new-array v2, v2, [Lcom/personal/aihub/CpkWriter$Col;
  00d6 const-string v3, "DirName"
  00da const/16 v4, 10
  00de invoke-static v3, v4, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  00e4 move-result-object v3
  00e6 aput-object v3, v2, v1
  00ea const-string v1, "FileName"
  00ee invoke-static v1, v4, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  00f4 move-result-object v1
  00f6 const/4 v3, 1
  00f8 aput-object v1, v2, v3
  00fc const-string v1, "FileSize"
  0100 const/4 v3, 4
  0102 invoke-static v1, v3, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  0108 move-result-object v1
  010a const/4 v5, 2
  010c aput-object v1, v2, v5
  0110 const-string v1, "ExtractSize"
  0114 invoke-static v1, v3, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  011a move-result-object v1
  011c const/4 v5, 3
  011e aput-object v1, v2, v5
  0122 const-string v1, "FileOffset"
  0126 const/4 v5, 6
  0128 invoke-static v1, v5, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  012e move-result-object v1
  0130 aput-object v1, v2, v3
  0134 const-string v1, "ID"
  0138 invoke-static v1, v3, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  013e move-result-object v1
  0140 const/4 v3, 5
  0142 aput-object v1, v2, v3
  0146 const-string v1, "UserString"
  014a invoke-static v1, v4, Lcom/personal/aihub/CpkWriter;->c(Ljava/lang/String; I)Lcom/personal/aihub/CpkWriter$Col;
  0150 move-result-object v1
  0152 aput-object v1, v2, v5
  0156 const-string v1, "CpkTocInfo"
  015a invoke-static v1, v2, v0, Lcom/personal/aihub/CpkWriter;->utf(Ljava/lang/String; [Lcom/personal/aihub/CpkWriter$Col; Ljava/util/List;)[B
  0160 move-result-object v0
  0162 const-string v1, "TOC "
  0166 invoke-static v1, v0, Lcom/personal/aihub/CpkWriter;->packet(Ljava/lang/String; [B)[B
  016c move-result-object v0
  016e return-object v0
.end method

.method utf(Ljava/lang/String; [Lcom/personal/aihub/CpkWriter$Col; Ljava/util/List;)[B
  0000 move-object/from16 v0, v17
  0004 new-instance v1, Ljava/io/ByteArrayOutputStream;
  0008 invoke-direct v1, Ljava/io/ByteArrayOutputStream;-><init>()V
  000e const-string v2, "<NULL> "
  0012 sget-object v3, Ljava/nio/charset/StandardCharsets;->US_ASCII Ljava/nio/charset/Charset;
  0016 invoke-virtual v2, v3, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  001c move-result-object v2
  001e invoke-virtual v1, v2, Ljava/io/ByteArrayOutputStream;->write([B)V
  0024 new-instance v2, Ljava/util/LinkedHashMap;
  0028 invoke-direct v2, Ljava/util/LinkedHashMap;-><init>()V
  002e new-instance v3, Lcom/personal/aihub/CpkWriter$1;
  0032 invoke-direct v3, v2, v1, Lcom/personal/aihub/CpkWriter$1;-><init>(Ljava/util/LinkedHashMap; Ljava/io/ByteArrayOutputStream;)V
  0038 const-string v4, ""
  003c invoke-interface v3, v4, Ljava/util/function/Function;->apply(Ljava/lang/Object;)Ljava/lang/Object;
  0042 move-object/from16 v4, v16
  0046 invoke-interface v3, v4, Ljava/util/function/Function;->apply(Ljava/lang/Object;)Ljava/lang/Object;
  004c move-result-object v4
  004e check-cast v4, Ljava/lang/Integer;
  0052 invoke-virtual v4, Ljava/lang/Integer;->intValue()I
  0058 move-result v4
  005a array-length v5, v0
  005c const/4 v6, 0
  005e move v7, v6
  0060 if-ge v7, v5, +00ch
  0064 aget-object v8, v0, v7
  0068 iget-object v8, v8, Lcom/personal/aihub/CpkWriter$Col;->name Ljava/lang/String;
  006c invoke-interface v3, v8, Ljava/util/function/Function;->apply(Ljava/lang/Object;)Ljava/lang/Object;
  0072 add-int/lit8 v7, v7, 1
  0076 goto -bh
  0078 invoke-interface/range v18, Ljava/util/List;->iterator()Ljava/util/Iterator;
  007e move-result-object v5
  0080 invoke-interface v5, Ljava/util/Iterator;->hasNext()Z
  0086 move-result v7
  0088 const/16 v8, 10
  008c if-eqz v7, +022h
  0090 invoke-interface v5, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0096 move-result-object v7
  0098 check-cast v7, Ljava/util/Map;
  009c array-length v9, v0
  009e move v10, v6
  00a0 if-ge v10, v9, -010h
  00a4 aget-object v11, v0, v10
  00a8 iget v12, v11, Lcom/personal/aihub/CpkWriter$Col;->type I
  00ac if-ne v12, v8, +00fh
  00b0 iget-object v11, v11, Lcom/personal/aihub/CpkWriter$Col;->name Ljava/lang/String;
  00b4 invoke-interface v7, v11, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  00ba move-result-object v11
  00bc invoke-static v11, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  00c2 move-result-object v11
  00c4 invoke-interface v3, v11, Ljava/util/function/Function;->apply(Ljava/lang/Object;)Ljava/lang/Object;
  00ca add-int/lit8 v10, v10, 1
  00ce goto -17h
  00d0 array-length v3, v0
  00d2 move v5, v6
  00d4 move v7, v5
  00d6 const/4 v9, 6
  00d8 const/4 v10, 2
  00da const/16 v11, 8
  00de if-lt v5, v3, +0edh
  00e2 array-length v3, v0
  00e4 mul-int/lit8 v3, v3, 5
  00e8 add-int/lit8 v5, v3, 32
  00ec invoke-interface/range v18, Ljava/util/List;->size()I
  00f2 move-result v12
  00f4 mul-int/2addr v12, v7
  00f6 add-int/2addr v12, v5
  00f8 invoke-virtual v1, Ljava/io/ByteArrayOutputStream;->size()I
  00fe move-result v5
  0100 add-int/2addr v5, v12
  0102 const/high16 v13, 33554432
  0106 if-gt v5, v13, +0d2h
  010a add-int/lit8 v13, v5, 7
  010e div-int/2addr v13, v11
  0110 mul-int/2addr v13, v11
  0112 invoke-static v13, Ljava/nio/ByteBuffer;->allocate(I)Ljava/nio/ByteBuffer;
  0118 move-result-object v13
  011a sget-object v14, Ljava/nio/ByteOrder;->BIG_ENDIAN Ljava/nio/ByteOrder;
  011e invoke-virtual v13, v14, Ljava/nio/ByteBuffer;->order(Ljava/nio/ByteOrder;)Ljava/nio/ByteBuffer;
  0124 move-result-object v13
  0126 const-string v14, "@UTF"
  012a sget-object v15, Ljava/nio/charset/StandardCharsets;->US_ASCII Ljava/nio/charset/Charset;
  012e invoke-virtual v14, v15, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0134 move-result-object v14
  0136 invoke-virtual v13, v14, Ljava/nio/ByteBuffer;->put([B)Ljava/nio/ByteBuffer;
  013c move-result-object v14
  013e invoke-virtual v13, Ljava/nio/ByteBuffer;->capacity()I
  0144 move-result v15
  0146 sub-int/2addr v15, v11
  0148 invoke-virtual v14, v15, Ljava/nio/ByteBuffer;->putInt(I)Ljava/nio/ByteBuffer;
  014e move-result-object v14
  0150 add-int/lit8 v3, v3, 24
  0154 invoke-virtual v14, v3, Ljava/nio/ByteBuffer;->putInt(I)Ljava/nio/ByteBuffer;
  015a move-result-object v3
  015c sub-int/2addr v12, v11
  015e invoke-virtual v3, v12, Ljava/nio/ByteBuffer;->putInt(I)Ljava/nio/ByteBuffer;
  0164 move-result-object v3
  0166 sub-int/2addr v5, v11
  0168 invoke-virtual v3, v5, Ljava/nio/ByteBuffer;->putInt(I)Ljava/nio/ByteBuffer;
  016e move-result-object v3
  0170 invoke-virtual v3, v4, Ljava/nio/ByteBuffer;->putInt(I)Ljava/nio/ByteBuffer;
  0176 move-result-object v3
  0178 array-length v4, v0
  017a int-to-short v4, v4
  017c invoke-virtual v3, v4, Ljava/nio/ByteBuffer;->putShort(S)Ljava/nio/ByteBuffer;
  0182 move-result-object v3
  0184 int-to-short v4, v7
  0186 invoke-virtual v3, v4, Ljava/nio/ByteBuffer;->putShort(S)Ljava/nio/ByteBuffer;
  018c move-result-object v3
  018e invoke-interface/range v18, Ljava/util/List;->size()I
  0194 move-result v4
  0196 invoke-virtual v3, v4, Ljava/nio/ByteBuffer;->putInt(I)Ljava/nio/ByteBuffer;
  019c array-length v3, v0
  019e move v4, v6
  01a0 if-ge v4, v3, +01fh
  01a4 aget-object v5, v0, v4
  01a8 iget v7, v5, Lcom/personal/aihub/CpkWriter$Col;->type I
  01ac or-int/lit8 v7, v7, 80
  01b0 int-to-byte v7, v7
  01b2 invoke-virtual v13, v7, Ljava/nio/ByteBuffer;->put(B)Ljava/nio/ByteBuffer;
  01b8 move-result-object v7
  01ba iget-object v5, v5, Lcom/personal/aihub/CpkWriter$Col;->name Ljava/lang/String;
  01be invoke-virtual v2, v5, Ljava/util/LinkedHashMap;->get(Ljava/lang/Object;)Ljava/lang/Object;
  01c4 move-result-object v5
  01c6 check-cast v5, Ljava/lang/Integer;
  01ca invoke-virtual v5, Ljava/lang/Integer;->intValue()I
  01d0 move-result v5
  01d2 invoke-virtual v7, v5, Ljava/nio/ByteBuffer;->putInt(I)Ljava/nio/ByteBuffer;
  01d8 add-int/lit8 v4, v4, 1
  01dc goto -1eh
  01de invoke-interface/range v18, Ljava/util/List;->iterator()Ljava/util/Iterator;
  01e4 move-result-object v3
  01e6 invoke-interface v3, Ljava/util/Iterator;->hasNext()Z
  01ec move-result v4
  01ee if-eqz v4, +052h
  01f2 invoke-interface v3, Ljava/util/Iterator;->next()Ljava/lang/Object;
  01f8 move-result-object v4
  01fa check-cast v4, Ljava/util/Map;
  01fe array-length v5, v0
  0200 move v7, v6
  0202 if-ge v7, v5, -00eh
  0206 aget-object v11, v0, v7
  020a iget-object v12, v11, Lcom/personal/aihub/CpkWriter$Col;->name Ljava/lang/String;
  020e invoke-interface v4, v12, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0214 move-result-object v12
  0216 iget v14, v11, Lcom/personal/aihub/CpkWriter$Col;->type I
  021a if-ne v14, v8, +014h
  021e invoke-static v12, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  0224 move-result-object v11
  0226 invoke-virtual v2, v11, Ljava/util/LinkedHashMap;->get(Ljava/lang/Object;)Ljava/lang/Object;
  022c move-result-object v11
  022e check-cast v11, Ljava/lang/Integer;
  0232 invoke-virtual v11, Ljava/lang/Integer;->intValue()I
  0238 move-result v11
  023a invoke-virtual v13, v11, Ljava/nio/ByteBuffer;->putInt(I)Ljava/nio/ByteBuffer;
  0240 goto +26h
  0242 iget v14, v11, Lcom/personal/aihub/CpkWriter$Col;->type I
  0246 if-ne v14, v9, +00ch
  024a check-cast v12, Ljava/lang/Number;
  024e invoke-virtual v12, Ljava/lang/Number;->longValue()J
  0254 move-result-wide v11
  0256 invoke-virtual v13, v11, v12, Ljava/nio/ByteBuffer;->putLong(J)Ljava/nio/ByteBuffer;
  025c goto +18h
  025e iget v11, v11, Lcom/personal/aihub/CpkWriter$Col;->type I
  0262 if-ne v11, v10, +00ch
  0266 check-cast v12, Ljava/lang/Number;
  026a invoke-virtual v12, Ljava/lang/Number;->shortValue()S
  0270 move-result v11
  0272 invoke-virtual v13, v11, Ljava/nio/ByteBuffer;->putShort(S)Ljava/nio/ByteBuffer;
  0278 goto +ah
  027a check-cast v12, Ljava/lang/Number;
  027e invoke-virtual v12, Ljava/lang/Number;->intValue()I
  0284 move-result v11
  0286 invoke-virtual v13, v11, Ljava/nio/ByteBuffer;->putInt(I)Ljava/nio/ByteBuffer;
  028c add-int/lit8 v7, v7, 1
  0290 goto -47h
  0292 invoke-virtual v1, Ljava/io/ByteArrayOutputStream;->toByteArray()[B
  0298 move-result-object v0
  029a invoke-virtual v13, v0, Ljava/nio/ByteBuffer;->put([B)Ljava/nio/ByteBuffer;
  02a0 invoke-virtual v13, Ljava/nio/ByteBuffer;->array()[B
  02a6 move-result-object v0
  02a8 return-object v0
  02aa const-string v0, "Metadata exceeds32MB."
  02ae invoke-static v0, Lcom/personal/aihub/CpkWriter;->error(Ljava/lang/String;)Ljava/io/IOException;
  02b4 move-result-object v0
  02b6 throw v0
  02b8 aget-object v12, v0, v5
  02bc iget v13, v12, Lcom/personal/aihub/CpkWriter$Col;->type I
  02c0 if-ne v13, v9, +004h
  02c4 move v10, v11
  02c6 goto +6h
  02c8 iget v9, v12, Lcom/personal/aihub/CpkWriter$Col;->type I
  02cc if-eq v9, v10, +003h
  02d0 const/4 v10, 4
  02d2 add-int/2addr v7, v10
  02d4 add-int/lit8 v5, v5, 1
  02d8 goto/16 -101h
.end method

.method write(Ljava/io/File; Ljava/util/List; Ljava/io/File;)V
  0000 move-object/from16 v0, v21
  0004 if-eqz v22, +1f7h
  0008 invoke-interface/range v22, Ljava/util/List;->isEmpty()Z
  000e move-result v1
  0010 if-nez v1, +1f1h
  0014 invoke-interface/range v22, Ljava/util/List;->size()I
  001a move-result v1
  001c const/16 v2, 5000
  0020 if-gt v1, v2, +1e9h
  0024 new-instance v1, Ljava/util/ArrayList;
  0028 invoke-direct v1, Ljava/util/ArrayList;-><init>()V
  002e new-instance v2, Ljava/util/HashSet;
  0032 invoke-direct v2, Ljava/util/HashSet;-><init>()V
  0038 invoke-interface/range v22, Ljava/util/List;->iterator()Ljava/util/Iterator;
  003e move-result-object v3
  0040 const-wide/16 v13, 0
  0044 invoke-interface v3, Ljava/util/Iterator;->hasNext()Z
  004a move-result v6
  004c if-eqz v6, +05fh
  0050 invoke-interface v3, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0056 move-result-object v6
  0058 check-cast v6, Lcom/personal/aihub/CpkWriter$Entry;
  005c if-eqz v6, +050h
  0060 iget-object v7, v6, Lcom/personal/aihub/CpkWriter$Entry;->path Ljava/lang/String;
  0064 invoke-static v7, Lcom/personal/aihub/CpkWriter;->safe(Ljava/lang/String;)Z
  006a move-result v7
  006c if-eqz v7, +048h
  0070 iget-object v7, v6, Lcom/personal/aihub/CpkWriter$Entry;->path Ljava/lang/String;
  0074 sget-object v8, Ljava/text/Normalizer$Form;->NFC Ljava/text/Normalizer$Form;
  0078 invoke-static v7, v8, Ljava/text/Normalizer;->normalize(Ljava/lang/CharSequence; Ljava/text/Normalizer$Form;)Ljava/lang/String;
  007e move-result-object v7
  0080 sget-object v8, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  0084 invoke-virtual v7, v8, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  008a move-result-object v8
  008c invoke-virtual v2, v8, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  0092 move-result v8
  0094 if-eqz v8, +02dh
  0098 iget-object v8, v6, Lcom/personal/aihub/CpkWriter$Entry;->assetKey Ljava/lang/String;
  009c invoke-static v0, v8, Lcom/personal/aihub/CpkWriter;->source(Ljava/io/File; Ljava/lang/String;)Ljava/io/File;
  00a2 move-result-object v18
  00a4 invoke-virtual/range v18, Ljava/io/File;->length()J
  00aa move-result-wide v19
  00ac const-wide/32 v8, 536870912
  00b2 sub-long/2addr v8, v13
  00b4 cmp-long v8, v19, v8
  00b8 if-gtz v8, +014h
  00bc add-long v13, v13, v19
  00c0 new-instance v8, Lcom/personal/aihub/CpkWriter$Source;
  00c4 iget-object v6, v6, Lcom/personal/aihub/CpkWriter$Entry;->assetKey Ljava/lang/String;
  00c8 move-object v15, v8
  00ca move-object/from16 v16, v7
  00ce move-object/from16 v17, v6
  00d2 invoke-direct/range v15 ... v20, Lcom/personal/aihub/CpkWriter$Source;-><init>(Ljava/lang/String; Ljava/lang/String; Ljava/io/File; J)V
  00d8 invoke-virtual v1, v8, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  00de goto -4dh
  00e0 const-string v0, "Archive exceeds512MB."
  00e4 invoke-static v0, Lcom/personal/aihub/CpkWriter;->error(Ljava/lang/String;)Ljava/io/IOException;
  00ea move-result-object v0
  00ec throw v0
  00ee const-string v0, "Duplicate archive path."
  00f2 invoke-static v0, Lcom/personal/aihub/CpkWriter;->error(Ljava/lang/String;)Ljava/io/IOException;
  00f8 move-result-object v0
  00fa throw v0
  00fc const-string v0, "Unsafe archive path."
  0100 invoke-static v0, Lcom/personal/aihub/CpkWriter;->error(Ljava/lang/String;)Ljava/io/IOException;
  0106 move-result-object v0
  0108 throw v0
  010a new-instance v2, Lcom/personal/aihub/CpkWriter$2;
  010e invoke-direct v2, Lcom/personal/aihub/CpkWriter$2;-><init>()V
  0114 invoke-virtual v1, v2, Ljava/util/ArrayList;->sort(Ljava/util/Comparator;)V
  011a invoke-static v1, Lcom/personal/aihub/CpkWriter;->toc(Ljava/util/List;)[B
  0120 move-result-object v2
  0122 array-length v2, v2
  0124 const/16 v3, 2048
  0128 add-int/2addr v2, v3
  012a int-to-long v6, v2
  012c invoke-static v6, v7, Lcom/personal/aihub/CpkWriter;->align(J)I
  0132 move-result v2
  0134 int-to-long v10, v2
  0136 invoke-virtual v1, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
  013c move-result-object v6
  013e move-wide v7, v10
  0140 invoke-interface v6, Ljava/util/Iterator;->hasNext()Z
  0146 move-result v9
  0148 if-eqz v9, +013h
  014c invoke-interface v6, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0152 move-result-object v9
  0154 check-cast v9, Lcom/personal/aihub/CpkWriter$Source;
  0158 iput-wide v7, v9, Lcom/personal/aihub/CpkWriter$Source;->offset J
  015c iget-wide v4, v9, Lcom/personal/aihub/CpkWriter$Source;->size J
  0160 add-long/2addr v7, v4
  0162 invoke-static v7, v8, Lcom/personal/aihub/CpkWriter;->align(J)I
  0168 move-result v4
  016a int-to-long v7, v4
  016c goto -16h
  016e invoke-static v1, Lcom/personal/aihub/CpkWriter;->toc(Ljava/util/List;)[B
  0174 move-result-object v4
  0176 sub-long v8, v7, v10
  017a array-length v5, v4
  017c int-to-long v5, v5
  017e invoke-virtual v1, Ljava/util/ArrayList;->size()I
  0184 move-result v12
  0186 move-wide/from16 v17, v5
  018a move-wide v6, v10
  018c move-wide/from16 v19, v10
  0190 move-wide/from16 v10, v17
  0194 invoke-static/range v6 ... v14, Lcom/personal/aihub/CpkWriter;->header(J J J I J)[B
  019a move-result-object v5
  019c array-length v6, v5
  019e if-gt v6, v3, +123h
  01a2 invoke-virtual/range v23, Ljava/io/File;->exists()Z
  01a8 move-result v6
  01aa if-nez v6, +116h
  01ae invoke-virtual/range v23, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  01b4 move-result-object v6
  01b6 invoke-static v6, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  01bc move-result v6
  01be if-nez v6, +10ch
  01c2 invoke-virtual/range v23, Ljava/io/File;->getParentFile()Ljava/io/File;
  01c8 move-result-object v6
  01ca if-eqz v6, +106h
  01ce invoke-virtual/range v23, Ljava/io/File;->getParentFile()Ljava/io/File;
  01d4 move-result-object v6
  01d6 invoke-virtual v6, Ljava/io/File;->isDirectory()Z
  01dc move-result v6
  01de if-eqz v6, +0fch
  01e2 invoke-virtual/range v23, Ljava/io/File;->getParentFile()Ljava/io/File;
  01e8 move-result-object v6
  01ea invoke-virtual v6, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  01f0 move-result-object v6
  01f2 invoke-static v6, Ljava/nio/file/Files;->isSymbolicLink(Ljava/nio/file/Path;)Z
  01f8 move-result v6
  01fa if-nez v6, +0eeh
  01fe const/4 v6, 0
  0200 invoke-virtual/range v23, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  0206 move-result-object v7
  0208 const/4 v8, 2
  020a new-array v8, v8, [Ljava/nio/file/OpenOption;
  020e sget-object v9, Ljava/nio/file/StandardOpenOption;->CREATE_NEW Ljava/nio/file/StandardOpenOption;
  0212 aput-object v9, v8, v6
  0216 sget-object v9, Ljava/nio/file/StandardOpenOption;->WRITE Ljava/nio/file/StandardOpenOption;
  021a const/4 v10, 1
  021c aput-object v9, v8, v10
  0220 invoke-static v7, v8, Ljava/nio/file/Files;->newOutputStream(Ljava/nio/file/Path; [Ljava/nio/file/OpenOption;)Ljava/io/OutputStream;
  0226 move-result-object v7
  0228 invoke-virtual v7, v5, Ljava/io/OutputStream;->write([B)V
  022e array-length v5, v5
  0230 rsub-int v5, v5, 2048
  0234 int-to-long v8, v5
  0236 invoke-static v7, v8, v9, Lcom/personal/aihub/CpkWriter;->padding(Ljava/io/OutputStream; J)V
  023c invoke-virtual v7, v4, Ljava/io/OutputStream;->write([B)V
  0242 sub-int/2addr v2, v3
  0244 array-length v3, v4
  0246 sub-int/2addr v2, v3
  0248 int-to-long v2, v2
  024a invoke-static v7, v2, v3, Lcom/personal/aihub/CpkWriter;->padding(Ljava/io/OutputStream; J)V
  0250 const/high16 v2, 65536
  0254 new-array v3, v2, [B
  0258 invoke-virtual v1, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
  025e move-result-object v1
  0260 invoke-interface v1, Ljava/util/Iterator;->hasNext()Z
  0266 move-result v4
  0268 if-eqz v4, +095h
  026c invoke-interface v1, Ljava/util/Iterator;->next()Ljava/lang/Object;
  0272 move-result-object v4
  0274 check-cast v4, Lcom/personal/aihub/CpkWriter$Source;
  0278 iget-object v5, v4, Lcom/personal/aihub/CpkWriter$Source;->key Ljava/lang/String;
  027c invoke-static v0, v5, Lcom/personal/aihub/CpkWriter;->source(Ljava/io/File; Ljava/lang/String;)Ljava/io/File;
  0282 move-result-object v5
  0284 invoke-virtual v5, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  028a move-result-object v8
  028c iget-object v9, v4, Lcom/personal/aihub/CpkWriter$Source;->file Ljava/io/File;
  0290 invoke-virtual v9, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  0296 move-result-object v9
  0298 invoke-virtual v8, v9, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  029e move-result v8
  02a0 const-string v9, "Asset changed during export."
  02a4 if-eqz v8, +072h
  02a8 invoke-virtual v5, Ljava/io/File;->length()J
  02ae move-result-wide v11
  02b0 iget-wide v13, v4, Lcom/personal/aihub/CpkWriter$Source;->size J
  02b4 cmp-long v8, v11, v13
  02b8 if-nez v8, +068h
  02bc new-instance v8, Ljava/io/FileInputStream;
  02c0 invoke-direct v8, v5, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  02c6 const-wide/16 v11, 0
  02ca iget-wide v13, v4, Lcom/personal/aihub/CpkWriter$Source;->size J
  02ce cmp-long v13, v11, v13
  02d2 if-gez v13, +022h
  02d6 int-to-long v13, v2
  02d8 move-object/from16 v17, v3
  02dc iget-wide v2, v4, Lcom/personal/aihub/CpkWriter$Source;->size J
  02e0 sub-long/2addr v2, v11
  02e2 invoke-static v13, v14, v2, v3, Ljava/lang/Math;->min(J J)J
  02e8 move-result-wide v2
  02ea long-to-int v2, v2
  02ec move-object/from16 v3, v17
  02f0 invoke-virtual v8, v3, v6, v2, Ljava/io/FileInputStream;->read([B I I)I
  02f6 move-result v2
  02f8 if-lez v2, +00ah
  02fc invoke-virtual v7, v3, v6, v2, Ljava/io/OutputStream;->write([B I I)V
  0302 int-to-long v13, v2
  0304 add-long/2addr v11, v13
  0306 const/high16 v2, 65536
  030a goto -20h
  030c invoke-static v9, Lcom/personal/aihub/CpkWriter;->error(Ljava/lang/String;)Ljava/io/IOException;
  0312 move-result-object v0
  0314 throw v0
  0316 invoke-virtual v8, Ljava/io/FileInputStream;->read()I
  031c move-result v2
  031e const/4 v11, -1
  0320 if-ne v2, v11, +023h
  0324 invoke-virtual v5, Ljava/io/File;->length()J
  032a move-result-wide v11
  032c iget-wide v13, v4, Lcom/personal/aihub/CpkWriter$Source;->size J
  0330 cmp-long v2, v11, v13
  0334 if-nez v2, +019h
  0338 invoke-virtual v8, Ljava/io/FileInputStream;->close()V
  033e iget-wide v4, v4, Lcom/personal/aihub/CpkWriter$Source;->size J
  0342 add-long v19, v19, v4
  0346 invoke-static/range v19 ... v20, Lcom/personal/aihub/CpkWriter;->align(J)I
  034c move-result v2
  034e int-to-long v4, v2
  0350 sub-long v8, v4, v19
  0354 invoke-static v7, v8, v9, Lcom/personal/aihub/CpkWriter;->padding(Ljava/io/OutputStream; J)V
  035a move-wide/from16 v19, v4
  035e const/high16 v2, 65536
  0362 goto/16 -081h
  0366 invoke-static v9, Lcom/personal/aihub/CpkWriter;->error(Ljava/lang/String;)Ljava/io/IOException;
  036c move-result-object v0
  036e throw v0
  0370 move-exception v0
  0372 move-object v1, v0
  0374 invoke-virtual v8, Ljava/io/FileInputStream;->close()V
  037a goto +6h
  037c move-exception v0
  037e move-object v2, v0
  0380 invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0386 throw v1
  0388 invoke-static v9, Lcom/personal/aihub/CpkWriter;->error(Ljava/lang/String;)Ljava/io/IOException;
  038e move-result-object v0
  0390 throw v0
  0392 if-eqz v7, +005h
  0396 invoke-virtual v7, Ljava/io/OutputStream;->close()V
  039c return-void 
  039e move-exception v0
  03a0 move-object v1, v0
  03a2 if-eqz v7, +00bh
  03a6 invoke-virtual v7, Ljava/io/OutputStream;->close()V
  03ac goto +6h
  03ae move-exception v0
  03b0 move-object v2, v0
  03b2 invoke-virtual v1, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  03b8 throw v1
  03ba move-exception v0
  03bc move v6, v10
  03be goto +2h
  03c0 move-exception v0
  03c2 if-eqz v6, +009h
  03c6 invoke-virtual/range v23, Ljava/io/File;->toPath()Ljava/nio/file/Path;
  03cc move-result-object v1
  03ce invoke-static v1, Ljava/nio/file/Files;->deleteIfExists(Ljava/nio/file/Path;)Z
  03d4 throw v0
  03d6 const-string v0, "Invalid archive output."
  03da invoke-static v0, Lcom/personal/aihub/CpkWriter;->error(Ljava/lang/String;)Ljava/io/IOException;
  03e0 move-result-object v0
  03e2 throw v0
  03e4 const-string v0, "Header exceeds alignment."
  03e8 invoke-static v0, Lcom/personal/aihub/CpkWriter;->error(Ljava/lang/String;)Ljava/io/IOException;
  03ee move-result-object v0
  03f0 throw v0
  03f2 const-string v0, "Choose1–5000 files."
  03f6 invoke-static v0, Lcom/personal/aihub/CpkWriter;->error(Ljava/lang/String;)Ljava/io/IOException;
  03fc move-result-object v0
  03fe throw v0
.end method

.method write(Ljava/io/File; Lorg/json/JSONArray; Ljava/io/File;)V
  0000 new-instance v0, Ljava/util/ArrayList;
  0004 invoke-direct v0, Ljava/util/ArrayList;-><init>()V
  000a invoke-virtual v7, Lorg/json/JSONArray;->length()I
  0010 move-result v1
  0012 const/16 v2, 5000
  0016 if-gt v1, v2, +028h
  001a const/4 v1, 0
  001c invoke-virtual v7, Lorg/json/JSONArray;->length()I
  0022 move-result v2
  0024 if-ge v1, v2, +01dh
  0028 invoke-virtual v7, v1, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;
  002e move-result-object v2
  0030 new-instance v3, Lcom/personal/aihub/CpkWriter$Entry;
  0034 const-string v4, "path"
  0038 invoke-virtual v2, v4, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  003e move-result-object v4
  0040 const-string v5, "assetKey"
  0044 invoke-virtual v2, v5, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;
  004a move-result-object v2
  004c invoke-direct v3, v4, v2, Lcom/personal/aihub/CpkWriter$Entry;-><init>(Ljava/lang/String; Ljava/lang/String;)V
  0052 invoke-virtual v0, v3, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0058 add-int/lit8 v1, v1, 1
  005c goto -20h
  005e invoke-static v6, v0, v8, Lcom/personal/aihub/CpkWriter;->write(Ljava/io/File; Ljava/util/List; Ljava/io/File;)V
  0064 return-void 
  0066 const-string v6, "Too many files."
  006a invoke-static v6, Lcom/personal/aihub/CpkWriter;->error(Ljava/lang/String;)Ljava/io/IOException;
  0070 move-result-object v6
  0072 throw v6
.end method