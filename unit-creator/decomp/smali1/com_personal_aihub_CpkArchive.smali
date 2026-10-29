.class Lcom/personal/aihub/CpkArchive;
.super Ljava/lang/Object;
.field MAX_FILES I
.field MAX_FILE_BYTES I
.field MAX_METADATA_BYTES I
.field MAX_TOTAL_BYTES J
.field entries Ljava/util/List;
.field file Ljava/io/File;
.field totalBytes J

.method <init>(Ljava/io/File;)V
  0000 move-object/from16 v1, v27
  0004 move-object/from16 v0, v28
  0008 invoke-direct/range v27, Ljava/lang/Object;-><init>()V
  000e iput-object v0, v1, Lcom/personal/aihub/CpkArchive;->file Ljava/io/File;
  0012 new-instance v2, Ljava/util/ArrayList;
  0016 invoke-direct v2, Ljava/util/ArrayList;-><init>()V
  001c new-instance v3, Ljava/io/RandomAccessFile;
  0020 const-string v4, "r"
  0024 invoke-direct v3, v0, v4, Ljava/io/RandomAccessFile;-><init>(Ljava/io/File; Ljava/lang/String;)V
  002a const-string v0, "CPK "
  002e const-wide/16 v4, 0
  0032 invoke-static v3, v4, v5, v0, Lcom/personal/aihub/CpkArchive;->packet(Ljava/io/RandomAccessFile; J Ljava/lang/String;)Ljava/util/List;
  0038 move-result-object v0
  003a invoke-interface v0, Ljava/util/List;->size()I
  0040 move-result v6
  0042 const/4 v7, 1
  0044 if-ne v6, v7, +172h
  0048 const/4 v6, 0
  004a invoke-interface v0, v6, Ljava/util/List;->get(I)Ljava/lang/Object;
  0050 move-result-object v0
  0052 check-cast v0, Ljava/util/Map;
  0056 const-string v6, "TocOffset"
  005a invoke-static v0, v6, Lcom/personal/aihub/CpkArchive;->number(Ljava/util/Map; Ljava/lang/String;)J
  0060 move-result-wide v6
  0062 const-string v8, "ContentOffset"
  0066 invoke-static v0, v8, Lcom/personal/aihub/CpkArchive;->number(Ljava/util/Map; Ljava/lang/String;)J
  006c move-result-wide v8
  006e cmp-long v10, v6, v4
  0072 if-eqz v10, +154h
  0076 const-string v10, "TOC "
  007a invoke-static v3, v6, v7, v10, Lcom/personal/aihub/CpkArchive;->packet(Ljava/io/RandomAccessFile; J Ljava/lang/String;)Ljava/util/List;
  0080 move-result-object v10
  0082 invoke-interface v10, Ljava/util/List;->size()I
  0088 move-result v11
  008a int-to-long v11, v11
  008c const-string v13, "Files"
  0090 invoke-static v0, v13, Lcom/personal/aihub/CpkArchive;->number(Ljava/util/Map; Ljava/lang/String;)J
  0096 move-result-wide v13
  0098 cmp-long v0, v11, v13
  009c if-nez v0, +138h
  00a0 invoke-static v8, v9, v6, v7, Ljava/lang/Math;->min(J J)J
  00a6 move-result-wide v6
  00a8 new-instance v0, Ljava/util/HashSet;
  00ac invoke-direct v0, Ljava/util/HashSet;-><init>()V
  00b2 invoke-interface v10, Ljava/util/List;->iterator()Ljava/util/Iterator;
  00b8 move-result-object v10
  00ba move-wide v11, v4
  00bc invoke-interface v10, Ljava/util/Iterator;->hasNext()Z
  00c2 move-result v13
  00c4 if-eqz v13, +116h
  00c8 invoke-interface v10, Ljava/util/Iterator;->next()Ljava/lang/Object;
  00ce move-result-object v13
  00d0 check-cast v13, Ljava/util/Map;
  00d4 const-string v14, "FileName"
  00d8 invoke-interface v13, v14, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  00de move-result-object v14
  00e0 const-string v15, "DirName"
  00e4 invoke-interface v13, v15, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  00ea move-result-object v15
  00ec instance-of v4, v14, Ljava/lang/String;
  00f0 if-eqz v4, +0f5h
  00f4 instance-of v4, v15, Ljava/lang/String;
  00f8 if-nez v4, +011h
  00fc move-object/from16 v28, v10
  0100 const-wide/16 v4, 0
  0104 invoke-static v4, v5, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  010a move-result-object v10
  010c invoke-virtual v10, v15, Ljava/lang/Long;->equals(Ljava/lang/Object;)Z
  0112 move-result v10
  0114 if-eqz v10, +0e3h
  0118 goto +5h
  011a move-object/from16 v28, v10
  011e const-wide/16 v4, 0
  0122 instance-of v10, v15, Ljava/lang/String;
  0126 const-string v16, ""
  012a if-eqz v10, +005h
  012e check-cast v15, Ljava/lang/String;
  0132 goto +3h
  0134 move-object/from16 v15, v16
  0138 new-instance v10, Ljava/lang/StringBuilder;
  013c invoke-direct v10, Ljava/lang/StringBuilder;-><init>()V
  0142 invoke-virtual v15, Ljava/lang/String;->isEmpty()Z
  0148 move-result v17
  014a if-nez v17, +01ch
  014e const-string v4, "<NULL>"
  0152 invoke-virtual v15, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0158 move-result v4
  015a if-eqz v4, +003h
  015e goto +12h
  0160 new-instance v4, Ljava/lang/StringBuilder;
  0164 invoke-direct v4, Ljava/lang/StringBuilder;-><init>()V
  016a invoke-virtual v4, v15, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0170 const-string v5, "/"
  0174 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  017a invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0180 move-result-object v16
  0182 move-object/from16 v4, v16
  0186 invoke-virtual v10, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  018c invoke-virtual v10, v14, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0192 invoke-virtual v10, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0198 move-result-object v4
  019a invoke-static v4, Lcom/personal/aihub/CpkArchive;->safePath(Ljava/lang/String;)Z
  01a0 move-result v5
  01a2 if-eqz v5, +095h
  01a6 sget-object v5, Ljava/text/Normalizer$Form;->NFC Ljava/text/Normalizer$Form;
  01aa invoke-static v4, v5, Ljava/text/Normalizer;->normalize(Ljava/lang/CharSequence; Ljava/text/Normalizer$Form;)Ljava/lang/String;
  01b0 move-result-object v5
  01b2 sget-object v10, Ljava/util/Locale;->ROOT Ljava/util/Locale;
  01b6 invoke-virtual v5, v10, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;
  01bc move-result-object v5
  01be invoke-virtual v0, v5, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  01c4 move-result v5
  01c6 if-eqz v5, +07ch
  01ca const-string v5, "FileSize"
  01ce invoke-static v13, v5, Lcom/personal/aihub/CpkArchive;->number(Ljava/util/Map; Ljava/lang/String;)J
  01d4 move-result-wide v14
  01d6 const-string v5, "ExtractSize"
  01da move-object v10, v0
  01dc invoke-static v13, v5, Lcom/personal/aihub/CpkArchive;->number(Ljava/util/Map; Ljava/lang/String;)J
  01e2 move-result-wide v0
  01e4 const-string v5, "FileOffset"
  01e8 invoke-static v13, v5, Lcom/personal/aihub/CpkArchive;->number(Ljava/util/Map; Ljava/lang/String;)J
  01ee move-result-wide v18
  01f0 const-wide/32 v20, 167772160
  01f6 cmp-long v5, v14, v20
  01fa if-gtz v5, +05bh
  01fe cmp-long v5, v0, v20
  0202 if-gtz v5, +057h
  0206 const-wide v20, 2147483648
  0210 sub-long v20, v20, v11
  0214 cmp-long v5, v0, v20
  0218 if-gtz v5, +04ch
  021c const-wide v20, 9223372036854775807
  0226 sub-long v20, v20, v6
  022a cmp-long v5, v18, v20
  022e if-gtz v5, +03ah
  0232 add-long v25, v18, v6
  0236 invoke-virtual v3, Ljava/io/RandomAccessFile;->length()J
  023c move-result-wide v22
  023e const-string v24, "file contents"
  0242 move-wide/from16 v18, v25
  0246 move-wide/from16 v20, v14
  024a invoke-static/range v18 ... v24, Lcom/personal/aihub/CpkArchive;->range(J J J Ljava/lang/String;)V
  0250 cmp-long v5, v25, v8
  0254 if-ltz v5, +020h
  0258 new-instance v5, Lcom/personal/aihub/CpkArchive$Entry;
  025c long-to-int v13, v14
  025e long-to-int v14, v0
  0260 move-object/from16 v18, v5
  0264 move-object/from16 v19, v4
  0268 move-wide/from16 v20, v25
  026c move/from16 v22, v13
  0270 move/from16 v23, v14
  0274 invoke-direct/range v18 ... v23, Lcom/personal/aihub/CpkArchive$Entry;-><init>(Ljava/lang/String; J I I)V
  027a invoke-virtual v2, v5, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0280 add-long/2addr v11, v0
  0282 const-wide/16 v4, 0
  0286 move-object/from16 v1, v27
  028a move-object v0, v10
  028c move-object/from16 v10, v28
  0290 goto/16 -0eah
  0294 const-string v0, "File overlaps archive metadata"
  0298 invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  029e move-result-object v0
  02a0 throw v0
  02a2 const-string v0, "Invalid file offset"
  02a6 invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  02ac move-result-object v0
  02ae throw v0
  02b0 const-string v0, "Extracted data exceeds limit"
  02b4 invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  02ba move-result-object v0
  02bc throw v0
  02be const-string v0, "Duplicate entry path"
  02c2 invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  02c8 move-result-object v0
  02ca throw v0
  02cc const-string v0, "Unsafe entry path"
  02d0 invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  02d6 move-result-object v0
  02d8 throw v0
  02da const-string v0, "Invalid file name"
  02de invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  02e4 move-result-object v0
  02e6 throw v0
  02e8 move-exception v0
  02ea move-object/from16 v1, v27
  02ee goto +25h
  02f0 invoke-virtual v3, Ljava/io/RandomAccessFile;->close()V
  02f6 invoke-static v2, Ljava/util/Collections;->unmodifiableList(Ljava/util/List;)Ljava/util/List;
  02fc move-result-object v0
  02fe move-object/from16 v1, v27
  0302 iput-object v0, v1, Lcom/personal/aihub/CpkArchive;->entries Ljava/util/List;
  0306 iput-wide v11, v1, Lcom/personal/aihub/CpkArchive;->totalBytes J
  030a return-void 
  030c const-string v0, "Archive file count does not match TOC"
  0310 invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  0316 move-result-object v0
  0318 throw v0
  031a const-string v0, "Archive has no named TOC; an external name map is required"
  031e invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  0324 move-result-object v0
  0326 throw v0
  0328 const-string v0, "Invalid archive header"
  032c invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  0332 move-result-object v0
  0334 throw v0
  0336 move-exception v0
  0338 move-object v2, v0
  033a invoke-virtual v3, Ljava/io/RandomAccessFile;->close()V
  0340 goto +6h
  0342 move-exception v0
  0344 move-object v3, v0
  0346 invoke-virtual v2, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  034c throw v2
.end method

.method decodeCriLayla([B I)[B
  0000 move-object/from16 v0, v16
  0004 array-length v1, v0
  0006 const/16 v2, 272
  000a if-lt v1, v2, +0e9h
  000e new-instance v1, Ljava/lang/String;
  0012 sget-object v2, Ljava/nio/charset/StandardCharsets;->US_ASCII Ljava/nio/charset/Charset;
  0016 const/4 v3, 0
  0018 const/16 v4, 8
  001c invoke-direct v1, v0, v3, v4, v2, Ljava/lang/String;-><init>([B I I Ljava/nio/charset/Charset;)V
  0022 const-string v2, "CRILAYLA"
  0026 invoke-virtual v1, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  002c move-result v1
  002e if-eqz v1, +0d7h
  0032 invoke-static/range v16, Ljava/nio/ByteBuffer;->wrap([B)Ljava/nio/ByteBuffer;
  0038 move-result-object v1
  003a sget-object v2, Ljava/nio/ByteOrder;->LITTLE_ENDIAN Ljava/nio/ByteOrder;
  003e invoke-virtual v1, v2, Ljava/nio/ByteBuffer;->order(Ljava/nio/ByteOrder;)Ljava/nio/ByteBuffer;
  0044 move-result-object v1
  0046 invoke-virtual v1, v4, Ljava/nio/ByteBuffer;->getInt(I)I
  004c move-result v2
  004e int-to-long v5, v2
  0050 const-wide v7, 4294967295
  005a and-long/2addr v5, v7
  005c const-wide/16 v9, 256
  0060 add-long/2addr v5, v9
  0062 const/16 v2, 12
  0066 invoke-virtual v1, v2, Ljava/nio/ByteBuffer;->getInt(I)I
  006c move-result v1
  006e int-to-long v1, v1
  0070 and-long/2addr v1, v7
  0072 const-wide/32 v7, 167772160
  0078 cmp-long v7, v5, v7
  007c if-gtz v7, +0a9h
  0080 move/from16 v7, v17
  0084 int-to-long v7, v7
  0086 cmp-long v7, v5, v7
  008a if-nez v7, +0a2h
  008e const-wide/16 v7, 16
  0092 add-long/2addr v7, v1
  0094 array-length v9, v0
  0096 int-to-long v13, v9
  0098 const-string v15, "CRILAYLA header"
  009c const-wide/16 v11, 256
  00a0 move-wide v9, v7
  00a2 invoke-static/range v9 ... v15, Lcom/personal/aihub/CpkArchive;->range(J J J Ljava/lang/String;)V
  00a8 const-wide/16 v9, 272
  00ac add-long/2addr v9, v1
  00ae array-length v11, v0
  00b0 int-to-long v11, v11
  00b2 cmp-long v9, v9, v11
  00b6 if-nez v9, +085h
  00ba long-to-int v9, v5
  00bc new-array v10, v9, [B
  00c0 long-to-int v7, v7
  00c2 const/16 v8, 256
  00c6 invoke-static v0, v7, v10, v3, v8, Ljava/lang/System;->arraycopy(Ljava/lang/Object; I Ljava/lang/Object; I I)V
  00cc new-instance v7, Lcom/personal/aihub/CpkArchive$Bits;
  00d0 const-wide/16 v11, 15
  00d4 add-long/2addr v1, v11
  00d6 long-to-int v1, v1
  00d8 invoke-direct v7, v0, v1, Lcom/personal/aihub/CpkArchive$Bits;-><init>([B I)V
  00de const/4 v0, 1
  00e0 sub-int/2addr v9, v0
  00e2 if-lt v9, v8, +06eh
  00e6 invoke-virtual v7, v0, Lcom/personal/aihub/CpkArchive$Bits;->take(I)I
  00ec move-result v1
  00ee if-nez v1, +00ch
  00f2 invoke-virtual v7, v4, Lcom/personal/aihub/CpkArchive$Bits;->take(I)I
  00f8 move-result v1
  00fa int-to-byte v1, v1
  00fc aput-byte v1, v10, v9
  0100 add-int/lit8 v9, v9, -1
  0104 goto -11h
  0106 const/16 v1, 13
  010a invoke-virtual v7, v1, Lcom/personal/aihub/CpkArchive$Bits;->take(I)I
  0110 move-result v1
  0112 const/4 v2, 3
  0114 add-int/2addr v1, v2
  0116 const/4 v11, 2
  0118 const/4 v12, 5
  011a filled-new-array v11, v2, v12, v4, [I
  0120 move-result-object v11
  0122 move v12, v3
  0124 const/4 v13, 4
  0126 if-lt v12, v13, +004h
  012a move v11, v0
  012c goto +eh
  012e aget v13, v11, v12
  0132 invoke-virtual v7, v13, Lcom/personal/aihub/CpkArchive$Bits;->take(I)I
  0138 move-result v14
  013a add-int/2addr v2, v14
  013c shl-int v13, v0, v13
  0140 sub-int/2addr v13, v0
  0142 if-eq v14, v13, +03bh
  0146 move v11, v3
  0148 if-eqz v11, +017h
  014c invoke-virtual v7, v4, Lcom/personal/aihub/CpkArchive$Bits;->take(I)I
  0152 move-result v11
  0154 add-int/2addr v2, v11
  0156 add-int/lit16 v12, v9, -255
  015a if-gt v2, v12, +007h
  015e const/16 v12, 255
  0162 if-eq v11, v12, -00bh
  0166 goto +8h
  0168 const-string v0, "CRILAYLA match exceeds output"
  016c invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  0172 move-result-object v0
  0174 throw v0
  0176 add-int/lit16 v11, v9, -255
  017a if-gt v2, v11, +018h
  017e add-int v11, v9, v1
  0182 int-to-long v11, v11
  0184 cmp-long v11, v11, v5
  0188 if-gez v11, +011h
  018c add-int/lit8 v11, v2, -1
  0190 if-gtz v2, +003h
  0194 goto -59h
  0196 add-int v2, v9, v1
  019a aget-byte v2, v10, v2
  019e aput-byte v2, v10, v9
  01a2 add-int/lit8 v9, v9, -1
  01a6 move v2, v11
  01a8 goto -eh
  01aa const-string v0, "Invalid CRILAYLA back-reference"
  01ae invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  01b4 move-result-object v0
  01b6 throw v0
  01b8 add-int/lit8 v12, v12, 1
  01bc goto -4ch
  01be return-object v10
  01c0 const-string v0, "Unexpected trailing CRILAYLA data"
  01c4 invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  01ca move-result-object v0
  01cc throw v0
  01ce const-string v0, "Compressed output size does not match file table"
  01d2 invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  01d8 move-result-object v0
  01da throw v0
  01dc const-string v0, "Unsupported compressed entry"
  01e0 invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  01e6 move-result-object v0
  01e8 throw v0
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

.method number(Ljava/util/Map; Ljava/lang/String;)J
  0000 invoke-interface v4, v5, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
  0006 move-result-object v4
  0008 instance-of v0, v4, Ljava/lang/Long;
  000c if-eqz v0, +013h
  0010 check-cast v4, Ljava/lang/Long;
  0014 invoke-virtual v4, Ljava/lang/Long;->longValue()J
  001a move-result-wide v0
  001c const-wide/16 v2, 0
  0020 cmp-long v0, v0, v2
  0024 if-ltz v0, +007h
  0028 invoke-virtual v4, Ljava/lang/Long;->longValue()J
  002e move-result-wide v4
  0030 return-wide v4
  0032 new-instance v4, Ljava/lang/StringBuilder;
  0036 const-string v0, "Invalid "
  003a invoke-direct v4, v0, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0040 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0046 invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  004c move-result-object v4
  004e invoke-static v4, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  0054 move-result-object v4
  0056 throw v4
.end method

.method packet(Ljava/io/RandomAccessFile; J Ljava/lang/String;)Ljava/util/List;
  0000 const/16 v0, 16
  0004 invoke-static v5, v6, v7, v0, Lcom/personal/aihub/CpkArchive;->read(Ljava/io/RandomAccessFile; J I)[B
  000a move-result-object v0
  000c new-instance v1, Ljava/lang/String;
  0010 const/4 v2, 4
  0012 sget-object v3, Ljava/nio/charset/StandardCharsets;->US_ASCII Ljava/nio/charset/Charset;
  0016 const/4 v4, 0
  0018 invoke-direct v1, v0, v4, v2, v3, Ljava/lang/String;-><init>([B I I Ljava/nio/charset/Charset;)V
  001e invoke-virtual v1, v8, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0024 move-result v1
  0026 if-eqz v1, +024h
  002a const/16 v8, 8
  002e const/4 v1, 1
  0030 invoke-static v0, v8, v1, Lcom/personal/aihub/CpkArchive;->u64([B I Z)J
  0036 move-result-wide v0
  0038 const-wide/32 v2, 33554432
  003e cmp-long v8, v0, v2
  0042 if-gtz v8, +00fh
  0046 const-wide/16 v2, 16
  004a add-long/2addr v6, v2
  004c long-to-int v8, v0
  004e invoke-static v5, v6, v7, v8, Lcom/personal/aihub/CpkArchive;->read(Ljava/io/RandomAccessFile; J I)[B
  0054 move-result-object v5
  0056 invoke-static v5, Lcom/personal/aihub/CpkArchive;->utf([B)Ljava/util/List;
  005c move-result-object v5
  005e return-object v5
  0060 const-string v5, "Metadata exceeds limit"
  0064 invoke-static v5, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  006a move-result-object v5
  006c throw v5
  006e new-instance v5, Ljava/lang/StringBuilder;
  0072 const-string v6, "Invalid "
  0076 invoke-direct v5, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  007c invoke-virtual v5, v8, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0082 const-string v6, " packet"
  0086 invoke-virtual v5, v6, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  008c invoke-virtual v5, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0092 move-result-object v5
  0094 invoke-static v5, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  009a move-result-object v5
  009c throw v5
.end method

.method range(J J J Ljava/lang/String;)V
  0000 const-wide/16 v0, 0
  0004 cmp-long v2, v3, v0
  0008 if-ltz v2, +010h
  000c cmp-long v0, v5, v0
  0010 if-ltz v0, +00ch
  0014 cmp-long v0, v3, v7
  0018 if-gtz v0, +008h
  001c sub-long/2addr v7, v3
  001e cmp-long v3, v5, v7
  0022 if-gtz v3, +003h
  0026 return-void 
  0028 new-instance v3, Ljava/lang/StringBuilder;
  002c const-string v4, "Truncated or invalid "
  0030 invoke-direct v3, v4, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0036 invoke-virtual v3, v9, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  003c invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0042 move-result-object v3
  0044 invoke-static v3, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  004a move-result-object v3
  004c throw v3
.end method

.method read(Ljava/io/RandomAccessFile; J I)[B
  0000 int-to-long v2, v10
  0002 invoke-virtual v7, Ljava/io/RandomAccessFile;->length()J
  0008 move-result-wide v4
  000a const-string v6, "archive range"
  000e move-wide v0, v8
  0010 invoke-static/range v0 ... v6, Lcom/personal/aihub/CpkArchive;->range(J J J Ljava/lang/String;)V
  0016 new-array v10, v10, [B
  001a invoke-virtual v7, v8, v9, Ljava/io/RandomAccessFile;->seek(J)V
  0020 invoke-virtual v7, v10, Ljava/io/RandomAccessFile;->readFully([B)V
  0026 return-object v10
.end method

.method safePath(Ljava/lang/String;)Z
  0000 const/4 v0, 0
  0002 if-eqz v7, +05fh
  0006 invoke-virtual v7, Ljava/lang/String;->isEmpty()Z
  000c move-result v1
  000e if-nez v1, +059h
  0012 invoke-virtual v7, Ljava/lang/String;->length()I
  0018 move-result v1
  001a const/16 v2, 500
  001e if-gt v1, v2, +051h
  0022 const-string v1, "/"
  0026 invoke-virtual v7, v1, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  002c move-result v2
  002e if-nez v2, +049h
  0032 invoke-virtual v7, Ljava/lang/String;->toCharArray()[C
  0038 move-result-object v2
  003a array-length v3, v2
  003c move v4, v0
  003e if-ge v4, v3, +019h
  0042 aget-char v5, v2, v4
  0046 const/16 v6, 92
  004a if-eq v5, v6, +012h
  004e const/16 v6, 58
  0052 if-eq v5, v6, +00eh
  0056 const/16 v6, 32
  005a if-lt v5, v6, +00ah
  005e const/16 v6, 127
  0062 if-ne v5, v6, +003h
  0066 goto +4h
  0068 add-int/lit8 v4, v4, 1
  006c goto -17h
  006e return v0
  0070 const/4 v2, -1
  0072 invoke-virtual v7, v1, v2, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  0078 move-result-object v7
  007a array-length v1, v7
  007c move v2, v0
  007e if-ge v2, v1, +01fh
  0082 aget-object v3, v7, v2
  0086 invoke-virtual v3, Ljava/lang/String;->isEmpty()Z
  008c move-result v4
  008e if-nez v4, +016h
  0092 const-string v4, "."
  0096 invoke-virtual v3, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  009c move-result v4
  009e if-nez v4, +00eh
  00a2 const-string v4, ".."
  00a6 invoke-virtual v3, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  00ac move-result v3
  00ae if-eqz v3, +003h
  00b2 goto +4h
  00b4 add-int/lit8 v2, v2, 1
  00b8 goto -1dh
  00ba return v0
  00bc const/4 v7, 1
  00be return v7
  00c0 return v0
.end method

.method u64([B I Z)J
  0000 int-to-long v0, v8
  0002 array-length v2, v7
  0004 int-to-long v4, v2
  0006 const-string v6, "64-bit value"
  000a const-wide/16 v2, 8
  000e invoke-static/range v0 ... v6, Lcom/personal/aihub/CpkArchive;->range(J J J Ljava/lang/String;)V
  0014 const-wide/16 v0, 0
  0018 const/4 v2, 0
  001a const-string v3, "64-bit value exceeds safe range"
  001e const/16 v4, 8
  0022 if-ge v2, v4, +01eh
  0026 if-eqz v9, +006h
  002a add-int/lit8 v5, v8, 7
  002e sub-int/2addr v5, v2
  0030 goto +3h
  0032 add-int v5, v8, v2
  0036 aget-byte v5, v7, v5
  003a and-int/lit16 v5, v5, 255
  003e if-nez v2, +00ah
  0042 if-gtz v5, +003h
  0046 goto +6h
  0048 invoke-static v3, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  004e move-result-object v7
  0050 throw v7
  0052 shl-long/2addr v0, v4
  0054 int-to-long v3, v5
  0056 or-long/2addr v0, v3
  0058 add-int/lit8 v2, v2, 1
  005c goto -21h
  005e const-wide v7, 9007199254740991
  0068 cmp-long v7, v0, v7
  006c if-gtz v7, +003h
  0070 return-wide v0
  0072 invoke-static v3, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  0078 move-result-object v7
  007a throw v7
.end method

.method utf([B)Ljava/util/List;
  0000 new-instance v0, Lcom/personal/aihub/CpkArchive$Table;
  0004 move-object/from16 v1, v22
  0008 invoke-direct v0, v1, Lcom/personal/aihub/CpkArchive$Table;-><init>([B)V
  000e iget-object v1, v0, Lcom/personal/aihub/CpkArchive$Table;->be Ljava/nio/ByteBuffer;
  0012 const/16 v2, 24
  0016 invoke-virtual v1, v2, Ljava/nio/ByteBuffer;->getShort(I)S
  001c move-result v1
  001e const v2, 65535
  0024 and-int/2addr v1, v2
  0026 iget-object v3, v0, Lcom/personal/aihub/CpkArchive$Table;->be Ljava/nio/ByteBuffer;
  002a const/16 v4, 26
  002e invoke-virtual v3, v4, Ljava/nio/ByteBuffer;->getShort(I)S
  0034 move-result v3
  0036 and-int/2addr v2, v3
  0038 const/16 v3, 28
  003c invoke-virtual v0, v3, Lcom/personal/aihub/CpkArchive$Table;->u32(I)J
  0042 move-result-wide v3
  0044 const/16 v5, 512
  0048 if-gt v1, v5, +0f9h
  004c const-wide/16 v5, 10000
  0050 cmp-long v5, v3, v5
  0054 if-gtz v5, +0f3h
  0058 iget v5, v0, Lcom/personal/aihub/CpkArchive$Table;->rows I
  005c int-to-long v6, v5
  005e int-to-long v8, v2
  0060 mul-long/2addr v8, v3
  0062 iget v5, v0, Lcom/personal/aihub/CpkArchive$Table;->strings I
  0066 int-to-long v10, v5
  0068 const-string v12, "UTF rows"
  006c invoke-static/range v6 ... v12, Lcom/personal/aihub/CpkArchive;->range(J J J Ljava/lang/String;)V
  0072 const/16 v5, 20
  0076 invoke-virtual v0, v5, Lcom/personal/aihub/CpkArchive$Table;->u32(I)J
  007c move-result-wide v5
  007e invoke-virtual v0, v5, v6, Lcom/personal/aihub/CpkArchive$Table;->string(J)Ljava/lang/String;
  0084 const/16 v5, 12
  0088 new-array v6, v5, [I
  008c fill-array-data v6, +00000deh
  0092 new-instance v7, Ljava/util/ArrayList;
  0096 invoke-direct v7, Ljava/util/ArrayList;-><init>()V
  009c new-instance v8, Ljava/util/HashSet;
  00a0 invoke-direct v8, Ljava/util/HashSet;-><init>()V
  00a6 const/16 v10, 32
  00aa const/4 v11, 0
  00ac const/4 v12, 0
  00ae const/16 v13, 80
  00b2 if-ge v11, v1, +06ch
  00b6 int-to-long v14, v10
  00b8 iget v9, v0, Lcom/personal/aihub/CpkArchive$Table;->rows I
  00bc move-object/from16 v21, v6
  00c0 int-to-long v5, v9
  00c2 const-string v20, "UTF columns"
  00c6 const-wide/16 v16, 5
  00ca move-wide/from16 v18, v5
  00ce invoke-static/range v14 ... v20, Lcom/personal/aihub/CpkArchive;->range(J J J Ljava/lang/String;)V
  00d4 iget-object v5, v0, Lcom/personal/aihub/CpkArchive$Table;->b [B
  00d8 aget-byte v5, v5, v10
  00dc and-int/lit8 v6, v5, 15
  00e0 and-int/lit16 v5, v5, 240
  00e4 add-int/lit8 v9, v10, 1
  00e8 invoke-virtual v0, v9, Lcom/personal/aihub/CpkArchive$Table;->u32(I)J
  00ee move-result-wide v14
  00f0 invoke-virtual v0, v14, v15, Lcom/personal/aihub/CpkArchive$Table;->string(J)Ljava/lang/String;
  00f6 move-result-object v9
  00f8 add-int/lit8 v10, v10, 5
  00fc invoke-virtual v8, v9, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  0102 move-result v14
  0104 if-eqz v14, +03ch
  0108 const/16 v14, 12
  010c if-ge v6, v14, +031h
  0110 const/16 v15, 16
  0114 const/16 v14, 48
  0118 if-eq v5, v15, +006h
  011c if-eq v5, v14, +004h
  0120 if-ne v5, v13, +027h
  0124 const-wide/16 v15, 0
  0128 invoke-static/range v15 ... v16, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  012e move-result-object v15
  0130 if-ne v5, v14, +00bh
  0134 iget v14, v0, Lcom/personal/aihub/CpkArchive$Table;->rows I
  0138 invoke-virtual v0, v6, v10, v14, Lcom/personal/aihub/CpkArchive$Table;->value(I I I)Ljava/lang/Object;
  013e move-result-object v15
  0140 aget v14, v21, v6
  0144 add-int/2addr v10, v14
  0146 if-ne v5, v13, +005h
  014a aget v13, v21, v6
  014e add-int/2addr v12, v13
  0150 new-instance v13, Lcom/personal/aihub/CpkArchive$Column;
  0154 invoke-direct v13, v9, v6, v5, v15, Lcom/personal/aihub/CpkArchive$Column;-><init>(Ljava/lang/String; I I Ljava/lang/Object;)V
  015a invoke-virtual v7, v13, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0160 add-int/lit8 v11, v11, 1
  0164 move-object/from16 v6, v21
  0168 const/16 v5, 12
  016c goto -5fh
  016e const-string v0, "Unsupported UTF storage"
  0172 invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  0178 move-result-object v0
  017a throw v0
  017c const-string v0, "Duplicate UTF column"
  0180 invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  0186 move-result-object v0
  0188 throw v0
  018a move-object/from16 v21, v6
  018e if-gt v12, v2, +04fh
  0192 new-instance v1, Ljava/util/ArrayList;
  0196 invoke-direct v1, Ljava/util/ArrayList;-><init>()V
  019c const/4 v9, 0
  019e long-to-int v5, v3
  01a0 if-ge v9, v5, +045h
  01a4 iget v5, v0, Lcom/personal/aihub/CpkArchive$Table;->rows I
  01a8 mul-int v6, v9, v2
  01ac add-int/2addr v5, v6
  01ae new-instance v6, Ljava/util/HashMap;
  01b2 invoke-direct v6, Ljava/util/HashMap;-><init>()V
  01b8 invoke-virtual v7, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
  01be move-result-object v8
  01c0 invoke-interface v8, Ljava/util/Iterator;->hasNext()Z
  01c6 move-result v10
  01c8 if-eqz v10, +02bh
  01cc invoke-interface v8, Ljava/util/Iterator;->next()Ljava/lang/Object;
  01d2 move-result-object v10
  01d4 check-cast v10, Lcom/personal/aihub/CpkArchive$Column;
  01d8 iget v11, v10, Lcom/personal/aihub/CpkArchive$Column;->storage I
  01dc if-ne v11, v13, +019h
  01e0 iget-object v11, v10, Lcom/personal/aihub/CpkArchive$Column;->name Ljava/lang/String;
  01e4 iget v12, v10, Lcom/personal/aihub/CpkArchive$Column;->type I
  01e8 iget v14, v0, Lcom/personal/aihub/CpkArchive$Table;->rows I
  01ec add-int/lit8 v15, v9, 1
  01f0 mul-int/2addr v15, v2
  01f2 add-int/2addr v14, v15
  01f4 invoke-virtual v0, v12, v5, v14, Lcom/personal/aihub/CpkArchive$Table;->value(I I I)Ljava/lang/Object;
  01fa move-result-object v12
  01fc invoke-virtual v6, v11, v12, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  0202 iget v10, v10, Lcom/personal/aihub/CpkArchive$Column;->type I
  0206 aget v10, v21, v10
  020a add-int/2addr v5, v10
  020c goto -26h
  020e iget-object v11, v10, Lcom/personal/aihub/CpkArchive$Column;->name Ljava/lang/String;
  0212 iget-object v10, v10, Lcom/personal/aihub/CpkArchive$Column;->constant Ljava/lang/Object;
  0216 invoke-virtual v6, v11, v10, Ljava/util/HashMap;->put(Ljava/lang/Object; Ljava/lang/Object;)Ljava/lang/Object;
  021c goto -2eh
  021e invoke-virtual v1, v6, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0224 add-int/lit8 v9, v9, 1
  0228 goto -45h
  022a return-object v1
  022c const-string v0, "UTF row size does not match columns"
  0230 invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  0236 move-result-object v0
  0238 throw v0
  023a const-string v0, "Invalid table layout"
  023e invoke-static v0, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  0244 move-result-object v0
  0246 throw v0
  0248 fill-array-data-payload b'\x01\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00\x02\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00\x08\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00' | \x01\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00\x02\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00\x08\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00
.end method

.method read(Lcom/personal/aihub/CpkArchive$Entry;)[B
  0000 iget v0, v7, Lcom/personal/aihub/CpkArchive$Entry;->size I
  0004 if-ltz v0, +05bh
  0008 iget v0, v7, Lcom/personal/aihub/CpkArchive$Entry;->size I
  000c const/high16 v1, 167772160
  0010 if-gt v0, v1, +055h
  0014 iget v0, v7, Lcom/personal/aihub/CpkArchive$Entry;->storedSize I
  0018 if-ltz v0, +051h
  001c iget v0, v7, Lcom/personal/aihub/CpkArchive$Entry;->storedSize I
  0020 if-gt v0, v1, +04dh
  0024 new-instance v0, Ljava/io/RandomAccessFile;
  0028 iget-object v1, v6, Lcom/personal/aihub/CpkArchive;->file Ljava/io/File;
  002c const-string v2, "r"
  0030 invoke-direct v0, v1, v2, Ljava/io/RandomAccessFile;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0036 iget-wide v1, v7, Lcom/personal/aihub/CpkArchive$Entry;->offset J
  003a iget v3, v7, Lcom/personal/aihub/CpkArchive$Entry;->storedSize I
  003e invoke-static v0, v1, v2, v3, Lcom/personal/aihub/CpkArchive;->read(Ljava/io/RandomAccessFile; J I)[B
  0044 move-result-object v1
  0046 array-length v2, v1
  0048 const/16 v3, 8
  004c if-lt v2, v3, +01ch
  0050 new-instance v2, Ljava/lang/String;
  0054 sget-object v4, Ljava/nio/charset/StandardCharsets;->US_ASCII Ljava/nio/charset/Charset;
  0058 const/4 v5, 0
  005a invoke-direct v2, v1, v5, v3, v4, Ljava/lang/String;-><init>([B I I Ljava/nio/charset/Charset;)V
  0060 const-string v3, "CRILAYLA"
  0064 invoke-virtual v2, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  006a move-result v2
  006c if-eqz v2, +00ch
  0070 iget v7, v7, Lcom/personal/aihub/CpkArchive$Entry;->size I
  0074 invoke-static v1, v7, Lcom/personal/aihub/CpkArchive;->decodeCriLayla([B I)[B
  007a move-result-object v7
  007c invoke-virtual v0, Ljava/io/RandomAccessFile;->close()V
  0082 return-object v7
  0084 iget v2, v7, Lcom/personal/aihub/CpkArchive$Entry;->size I
  0088 iget v7, v7, Lcom/personal/aihub/CpkArchive$Entry;->storedSize I
  008c if-ne v2, v7, +006h
  0090 invoke-virtual v0, Ljava/io/RandomAccessFile;->close()V
  0096 return-object v1
  0098 const-string v7, "Unsupported compression format"
  009c invoke-static v7, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  00a2 move-result-object v7
  00a4 throw v7
  00a6 move-exception v7
  00a8 invoke-virtual v0, Ljava/io/RandomAccessFile;->close()V
  00ae goto +5h
  00b0 move-exception v0
  00b2 invoke-virtual v7, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  00b8 throw v7
  00ba const-string v7, "Entry exceeds limit"
  00be invoke-static v7, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  00c4 move-result-object v7
  00c6 throw v7
.end method