.class Lcom/personal/aihub/EclpCodec;
.super Ljava/lang/Object;
.field KDF_HEAP_REQUIRED J
.field KDF_MEMORY_MESSAGE Ljava/lang/String;
.field MAX_FILE J
.field MAX_TOTAL J

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)J
  0000 const/high16 v0, 65536
  0004 new-array v0, v0, [B
  0008 const-wide/16 v1, 0
  000c invoke-virtual v6, v0, Ljava/io/InputStream;->read([B)I
  0012 move-result v3
  0014 const/4 v4, -1
  0016 if-ne v3, v4, +003h
  001a return-wide v1
  001c int-to-long v4, v3
  001e add-long/2addr v1, v4
  0020 cmp-long v4, v1, v8
  0024 if-gtz v4, +007h
  0028 const/4 v4, 0
  002a invoke-virtual v7, v0, v4, v3, Ljava/io/OutputStream;->write([B I I)V
  0030 goto -12h
  0032 new-instance v6, Ljava/io/IOException;
  0036 const-string v7, "ECLP file exceeds its declared or supported size"
  003a invoke-direct v6, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0040 throw v6
.end method

.method derive(Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; [B)[B
  0000 filled-new-array v11, v12, v13, [Ljava/lang/String;
  0006 move-result-object v0
  0008 const/4 v1, 0
  000a move v2, v1
  000c const/4 v3, 3
  000e if-ge v2, v3, +023h
  0012 aget-object v3, v0, v2
  0016 if-eqz v3, +017h
  001a invoke-virtual v3, Ljava/lang/String;->trim()Ljava/lang/String;
  0020 move-result-object v4
  0022 invoke-virtual v4, Ljava/lang/String;->isEmpty()Z
  0028 move-result v4
  002a if-nez v4, +00dh
  002e invoke-virtual v3, Ljava/lang/String;->length()I
  0034 move-result v3
  0036 const/16 v4, 1000
  003a if-gt v3, v4, +005h
  003e add-int/lit8 v2, v2, 1
  0042 goto -1bh
  0044 new-instance v11, Ljava/io/IOException;
  0048 const-string v12, "Patch UUID, name, and version are required (maximum 1,000 characters)"
  004c invoke-direct v11, v12, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0052 throw v11
  0054 invoke-static Ljava/lang/Runtime;->getRuntime()Ljava/lang/Runtime;
  005a move-result-object v0
  005c invoke-virtual v0, Ljava/lang/Runtime;->maxMemory()J
  0062 move-result-wide v4
  0064 invoke-virtual v0, Ljava/lang/Runtime;->totalMemory()J
  006a move-result-wide v6
  006c sub-long/2addr v4, v6
  006e invoke-virtual v0, Ljava/lang/Runtime;->freeMemory()J
  0074 move-result-wide v6
  0076 add-long/2addr v4, v6
  0078 const-wide/32 v6, 100663296
  007e cmp-long v2, v4, v6
  0082 const-string v8, "There is not enough memory to convert this Eclipse patch. Close previews and try again, or use a device with more memory."
  0086 if-gez v2, +026h
  008a invoke-virtual v0, Ljava/lang/Runtime;->maxMemory()J
  0090 move-result-wide v9
  0092 cmp-long v2, v9, v6
  0096 if-ltz v2, +013h
  009a invoke-static Ljava/lang/System;->gc()V
  00a0 invoke-virtual v0, Ljava/lang/Runtime;->maxMemory()J
  00a6 move-result-wide v4
  00a8 invoke-virtual v0, Ljava/lang/Runtime;->totalMemory()J
  00ae move-result-wide v9
  00b0 sub-long/2addr v4, v9
  00b2 invoke-virtual v0, Ljava/lang/Runtime;->freeMemory()J
  00b8 move-result-wide v9
  00ba add-long/2addr v4, v9
  00bc cmp-long v0, v4, v6
  00c0 if-ltz v0, +003h
  00c4 goto +7h
  00c6 new-instance v11, Ljava/io/IOException;
  00ca invoke-direct v11, v8, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00d0 throw v11
  00d2 const-string v0, "SHA-256"
  00d6 invoke-static v0, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;
  00dc move-result-object v0
  00de new-instance v2, Ljava/lang/StringBuilder;
  00e2 invoke-direct v2, Ljava/lang/StringBuilder;-><init>()V
  00e8 invoke-static v11, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;
  00ee move-result-object v11
  00f0 invoke-virtual v2, v11, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  00f6 const-string v11, "|"
  00fa invoke-virtual v2, v11, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0100 invoke-virtual v2, v12, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0106 invoke-virtual v2, v11, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  010c invoke-virtual v2, v13, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0112 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0118 move-result-object v11
  011a sget-object v12, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  011e invoke-virtual v11, v12, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0124 move-result-object v11
  0126 invoke-virtual v0, v11, Ljava/security/MessageDigest;->digest([B)[B
  012c move-result-object v11
  012e const/16 v12, 64
  0132 new-array v12, v12, [B
  0136 const/16 v13, 32
  013a invoke-static v11, v1, v12, v1, v13, Ljava/lang/System;->arraycopy(Ljava/lang/Object; I Ljava/lang/Object; I I)V
  0140 move v0, v1
  0142 if-ge v0, v13, +01ah
  0146 mul-int/lit8 v2, v0, 2
  014a add-int/lit8 v4, v0, 32
  014e add-int/lit8 v5, v2, 2
  0152 const-string v6, "ef16bc5f9378dc3fef16bc5f937ed622f910b35a9e76b8478b15d32be96dbf4c"
  0156 invoke-virtual v6, v2, v5, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  015c move-result-object v2
  015e const/16 v5, 16
  0162 invoke-static v2, v5, Ljava/lang/Integer;->parseInt(Ljava/lang/String; I)I
  0168 move-result v2
  016a int-to-byte v2, v2
  016c aput-byte v2, v12, v4
  0170 add-int/lit8 v0, v0, 1
  0174 goto -19h
  0176 const/4 v0, 0
  0178 new-instance v2, Lorg/bouncycastle/crypto/params/Argon2Parameters$Builder;
  017c const/4 v4, 2
  017e invoke-direct v2, v4, Lorg/bouncycastle/crypto/params/Argon2Parameters$Builder;-><init>(I)V
  0184 const/16 v4, 19
  0188 invoke-virtual v2, v4, Lorg/bouncycastle/crypto/params/Argon2Parameters$Builder;->withVersion(I)Lorg/bouncycastle/crypto/params/Argon2Parameters$Builder;
  018e move-result-object v2
  0190 invoke-virtual v2, v3, Lorg/bouncycastle/crypto/params/Argon2Parameters$Builder;->withIterations(I)Lorg/bouncycastle/crypto/params/Argon2Parameters$Builder;
  0196 move-result-object v2
  0198 const/high16 v3, 65536
  019c invoke-virtual v2, v3, Lorg/bouncycastle/crypto/params/Argon2Parameters$Builder;->withMemoryAsKB(I)Lorg/bouncycastle/crypto/params/Argon2Parameters$Builder;
  01a2 move-result-object v2
  01a4 const/4 v3, 4
  01a6 invoke-virtual v2, v3, Lorg/bouncycastle/crypto/params/Argon2Parameters$Builder;->withParallelism(I)Lorg/bouncycastle/crypto/params/Argon2Parameters$Builder;
  01ac move-result-object v2
  01ae invoke-virtual v2, v14, Lorg/bouncycastle/crypto/params/Argon2Parameters$Builder;->withSalt([B)Lorg/bouncycastle/crypto/params/Argon2Parameters$Builder;
  01b4 move-result-object v14
  01b6 invoke-virtual v14, Lorg/bouncycastle/crypto/params/Argon2Parameters$Builder;->build()Lorg/bouncycastle/crypto/params/Argon2Parameters;
  01bc move-result-object v14
  01be new-instance v2, Lorg/bouncycastle/crypto/generators/Argon2BytesGenerator;
  01c2 invoke-direct v2, Lorg/bouncycastle/crypto/generators/Argon2BytesGenerator;-><init>()V
  01c8 invoke-virtual v2, v14, Lorg/bouncycastle/crypto/generators/Argon2BytesGenerator;->init(Lorg/bouncycastle/crypto/params/Argon2Parameters;)V
  01ce new-array v0, v13, [B
  01d2 invoke-virtual v2, v12, v0, Lorg/bouncycastle/crypto/generators/Argon2BytesGenerator;->generateBytes([B [B)I
  01d8 invoke-static v12, v1, Ljava/util/Arrays;->fill([B B)V
  01de invoke-static v11, v1, Ljava/util/Arrays;->fill([B B)V
  01e4 return-object v0
  01e6 move-exception v13
  01e8 goto +10h
  01ea move-exception v13
  01ec if-eqz v0, +005h
  01f0 invoke-static v0, v1, Ljava/util/Arrays;->fill([B B)V
  01f6 invoke-static Ljava/lang/System;->gc()V
  01fc new-instance v14, Ljava/io/IOException;
  0200 invoke-direct v14, v8, v13, Ljava/io/IOException;-><init>(Ljava/lang/String; Ljava/lang/Throwable;)V
  0206 throw v14
  0208 invoke-static v12, v1, Ljava/util/Arrays;->fill([B B)V
  020e invoke-static v11, v1, Ljava/util/Arrays;->fill([B B)V
  0214 throw v13
.end method

.method exact(Ljava/io/InputStream; I)[B
  0000 new-array v0, v4, [B
  0004 const/4 v1, 0
  0006 if-ge v1, v4, +014h
  000a sub-int v2, v4, v1
  000e invoke-virtual v3, v0, v1, v2, Ljava/io/InputStream;->read([B I I)I
  0014 move-result v2
  0016 if-ltz v2, +004h
  001a add-int/2addr v1, v2
  001c goto -bh
  001e new-instance v3, Ljava/io/EOFException;
  0022 const-string v4, "Truncated ECLP file"
  0026 invoke-direct v3, v4, Ljava/io/EOFException;-><init>(Ljava/lang/String;)V
  002c throw v3
  002e return-object v0
.end method

.method extract(Ljava/io/File; Ljava/io/File; Ljava/io/File; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)Ljava/util/List;
  0000 invoke-static/range v20, Lcom/personal/aihub/EclpCodec;->header(Ljava/io/File;)Lcom/personal/aihub/EclpCodec$Header;
  0006 move-result-object v0
  0008 iget-object v1, v0, Lcom/personal/aihub/EclpCodec$Header;->salt [B
  000c move-object/from16 v2, v23
  0010 move-object/from16 v3, v24
  0014 move-object/from16 v4, v25
  0018 invoke-static v2, v3, v4, v1, Lcom/personal/aihub/EclpCodec;->derive(Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; [B)[B
  001e move-result-object v1
  0020 new-instance v8, Lorg/bouncycastle/crypto/modes/GCMBlockCipher;
  0024 new-instance v2, Lorg/bouncycastle/crypto/engines/AESEngine;
  0028 invoke-direct v2, Lorg/bouncycastle/crypto/engines/AESEngine;-><init>()V
  002e invoke-direct v8, v2, Lorg/bouncycastle/crypto/modes/GCMBlockCipher;-><init>(Lorg/bouncycastle/crypto/BlockCipher;)V
  0034 const/4 v9, 0
  0036 new-instance v2, Lorg/bouncycastle/crypto/params/AEADParameters;
  003a new-instance v3, Lorg/bouncycastle/crypto/params/KeyParameter;
  003e invoke-direct v3, v1, Lorg/bouncycastle/crypto/params/KeyParameter;-><init>([B)V
  0044 iget-object v4, v0, Lcom/personal/aihub/EclpCodec$Header;->nonce [B
  0048 const/16 v5, 128
  004c invoke-direct v2, v3, v5, v4, Lorg/bouncycastle/crypto/params/AEADParameters;-><init>(Lorg/bouncycastle/crypto/params/KeyParameter; I [B)V
  0052 invoke-virtual v8, v9, v2, Lorg/bouncycastle/crypto/modes/GCMBlockCipher;->init(Z Lorg/bouncycastle/crypto/CipherParameters;)V
  0058 invoke-static v1, v9, Ljava/util/Arrays;->fill([B B)V
  005e new-instance v1, Ljava/io/File;
  0062 new-instance v2, Ljava/lang/StringBuilder;
  0066 const-string v3, "eclp-payload-"
  006a invoke-direct v2, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0070 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0076 move-result-object v3
  0078 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  007e invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0084 move-result-object v2
  0086 move-object/from16 v3, v22
  008a invoke-direct v1, v3, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0090 new-instance v10, Ljava/util/ArrayList;
  0094 invoke-direct v10, Ljava/util/ArrayList;-><init>()V
  009a new-instance v11, Ljava/util/HashSet;
  009e invoke-direct v11, Ljava/util/HashSet;-><init>()V
  00a4 new-instance v12, Ljava/io/FileInputStream;
  00a8 move-object/from16 v2, v20
  00ac invoke-direct v12, v2, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  00b2 new-instance v13, Ljava/io/FileOutputStream;
  00b6 invoke-direct v13, v1, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  00bc iget-wide v2, v0, Lcom/personal/aihub/EclpCodec$Header;->offset J
  00c0 const-wide/16 v14, 0
  00c4 cmp-long v0, v2, v14
  00c8 if-lez v0, +012h
  00cc invoke-virtual v12, v2, v3, Ljava/io/FileInputStream;->skip(J)J
  00d2 move-result-wide v4
  00d4 cmp-long v0, v4, v14
  00d8 if-lez v0, +004h
  00dc sub-long/2addr v2, v4
  00de goto -fh
  00e0 new-instance v0, Ljava/io/EOFException;
  00e4 invoke-direct v0, Ljava/io/EOFException;-><init>()V
  00ea throw v0
  00ec const/high16 v0, 65536
  00f0 new-array v0, v0, [B
  00f4 invoke-virtual v12, v0, Ljava/io/FileInputStream;->read([B)I
  00fa move-result v5
  00fc const/4 v2, -1
  00fe if-eq v5, v2, +01bh
  0102 invoke-virtual v8, v5, Lorg/bouncycastle/crypto/modes/GCMBlockCipher;->getOutputSize(I)I
  0108 move-result v2
  010a new-array v7, v2, [B
  010e const/4 v4, 0
  0110 const/16 v16, 0
  0114 move-object v2, v8
  0116 move-object v3, v0
  0118 move-object v6, v7
  011a move-object v14, v7
  011c move/from16 v7, v16
  0120 invoke-virtual/range v2 ... v7, Lorg/bouncycastle/crypto/modes/GCMBlockCipher;->processBytes([B I I [B I)I
  0126 move-result v2
  0128 invoke-virtual v13, v14, v9, v2, Ljava/io/FileOutputStream;->write([B I I)V
  012e const-wide/16 v14, 0
  0132 goto -1fh
  0134 invoke-virtual v8, v9, Lorg/bouncycastle/crypto/modes/GCMBlockCipher;->getOutputSize(I)I
  013a move-result v0
  013c new-array v0, v0, [B
  0140 invoke-virtual v8, v0, v9, Lorg/bouncycastle/crypto/modes/GCMBlockCipher;->doFinal([B I)I
  0146 move-result v3
  0148 invoke-virtual v13, v0, v9, v3, Ljava/io/FileOutputStream;->write([B I I)V
  014e invoke-virtual v13, Ljava/io/FileOutputStream;->close()V
  0154 invoke-virtual v12, Ljava/io/FileInputStream;->close()V
  015a new-instance v3, Ljava/io/BufferedInputStream;
  015e new-instance v0, Ljava/io/FileInputStream;
  0162 invoke-direct v0, v1, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0168 invoke-direct v3, v0, Ljava/io/BufferedInputStream;-><init>(Ljava/io/InputStream;)V
  016e const/4 v0, 4
  0170 invoke-static v3, v0, Lcom/personal/aihub/EclpCodec;->number(Ljava/io/InputStream; I)J
  0176 move-result-wide v4
  0178 const-wide/32 v6, 100000
  017e cmp-long v0, v4, v6
  0182 if-gtz v0, +11ah
  0186 move v0, v9
  0188 const-wide/16 v6, 0
  018c int-to-long v12, v0
  018e cmp-long v8, v12, v4
  0192 if-gez v8, +0fbh
  0196 const/4 v8, 2
  0198 invoke-static v3, v8, Lcom/personal/aihub/EclpCodec;->number(Ljava/io/InputStream; I)J
  019e move-result-wide v12
  01a0 long-to-int v8, v12
  01a2 const/4 v12, 1
  01a4 if-lt v8, v12, +0eah
  01a8 const/16 v13, 4096
  01ac if-gt v8, v13, +0e6h
  01b0 new-instance v13, Ljava/lang/String;
  01b4 invoke-static v3, v8, Lcom/personal/aihub/EclpCodec;->exact(Ljava/io/InputStream; I)[B
  01ba move-result-object v8
  01bc sget-object v14, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  01c0 invoke-direct v13, v8, v14, Ljava/lang/String;-><init>([B Ljava/nio/charset/Charset;)V
  01c6 invoke-static v13, Lcom/personal/aihub/EclpCodec;->safePath(Ljava/lang/String;)Z
  01cc move-result v8
  01ce if-eqz v8, +0cdh
  01d2 invoke-virtual v11, v13, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  01d8 move-result v8
  01da if-eqz v8, +0c7h
  01de const/16 v8, 8
  01e2 invoke-static v3, v8, Lcom/personal/aihub/EclpCodec;->number(Ljava/io/InputStream; I)J
  01e8 move-result-wide v14
  01ea move-object/from16 v25, v10
  01ee invoke-static v3, v8, Lcom/personal/aihub/EclpCodec;->number(Ljava/io/InputStream; I)J
  01f4 move-result-wide v9
  01f6 add-long/2addr v6, v9
  01f8 const-wide/16 v16, 1
  01fc cmp-long v8, v14, v16
  0200 if-ltz v8, +0ach
  0204 const-wide/32 v16, 536870912
  020a cmp-long v8, v14, v16
  020e if-gtz v8, +0a5h
  0212 cmp-long v8, v9, v16
  0216 if-gtz v8, +0a1h
  021a const-wide v16, 4294967296
  0224 cmp-long v8, v6, v16
  0228 if-gtz v8, +098h
  022c new-array v8, v12, [J
  0230 const/4 v12, 0
  0232 aput-wide v14, v8, v12
  0236 new-instance v12, Lcom/personal/aihub/EclpCodec$2;
  023a invoke-direct v12, v8, v3, Lcom/personal/aihub/EclpCodec$2;-><init>([J Ljava/io/BufferedInputStream;)V
  0240 new-instance v14, Ljava/io/File;
  0244 move-object/from16 v15, v21
  0248 invoke-direct v14, v15, v13, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  024e invoke-virtual v14, Ljava/io/File;->getParentFile()Ljava/io/File;
  0254 move-result-object v16
  0256 invoke-virtual/range v16, Ljava/io/File;->mkdirs()Z
  025c invoke-virtual v14, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  0262 move-result-object v2
  0264 move-wide/from16 v16, v4
  0268 new-instance v4, Ljava/lang/StringBuilder;
  026c invoke-direct v4, Ljava/lang/StringBuilder;-><init>()V
  0272 invoke-virtual/range v21, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
  0278 move-result-object v5
  027a invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0280 sget-object v5, Ljava/io/File;->separator Ljava/lang/String;
  0284 invoke-virtual v4, v5, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  028a invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0290 move-result-object v4
  0292 invoke-virtual v2, v4, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  0298 move-result v2
  029a if-eqz v2, +057h
  029e new-instance v2, Lcom/github/luben/zstd/ZstdInputStream;
  02a2 invoke-direct v2, v12, Lcom/github/luben/zstd/ZstdInputStream;-><init>(Ljava/io/InputStream;)V
  02a8 new-instance v4, Ljava/io/FileOutputStream;
  02ac invoke-direct v4, v14, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  02b2 invoke-static v2, v4, v9, v10, Lcom/personal/aihub/EclpCodec;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)J
  02b8 move-result-wide v18
  02ba cmp-long v5, v18, v9
  02be if-nez v5, +025h
  02c2 const/4 v5, 0
  02c4 aget-wide v9, v8, v5
  02c8 const-wide/16 v18, 0
  02cc cmp-long v5, v9, v18
  02d0 if-nez v5, +01ch
  02d4 invoke-virtual v4, Ljava/io/FileOutputStream;->close()V
  02da invoke-virtual v2, Lcom/github/luben/zstd/ZstdInputStream;->close()V
  02e0 new-instance v2, Lcom/personal/aihub/EclpCodec$Entry;
  02e4 const/4 v4, 0
  02e6 invoke-direct v2, v13, v14, v4, Lcom/personal/aihub/EclpCodec$Entry;-><init>(Ljava/lang/String; Ljava/io/File; [B)V
  02ec move-object/from16 v4, v25
  02f0 invoke-virtual v4, v2, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  02f6 add-int/lit8 v0, v0, 1
  02fa move-object v10, v4
  02fc move-wide/from16 v4, v16
  0300 const/4 v2, -1
  0302 const/4 v9, 0
  0304 goto/16 -0bch
  0308 new-instance v0, Ljava/io/IOException;
  030c const-string v5, "ECLP entry size mismatch"
  0310 invoke-direct v0, v5, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0316 throw v0
  0318 move-exception v0
  031a move-object v5, v0
  031c invoke-virtual v4, Ljava/io/FileOutputStream;->close()V
  0322 goto +6h
  0324 move-exception v0
  0326 move-object v4, v0
  0328 invoke-virtual v5, v4, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  032e throw v5
  0330 move-exception v0
  0332 move-object v4, v0
  0334 invoke-virtual v2, Lcom/github/luben/zstd/ZstdInputStream;->close()V
  033a goto +6h
  033c move-exception v0
  033e move-object v2, v0
  0340 invoke-virtual v4, v2, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0346 throw v4
  0348 new-instance v0, Ljava/io/IOException;
  034c const-string v2, "Unsafe ECLP destination"
  0350 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0356 throw v0
  0358 new-instance v0, Ljava/io/IOException;
  035c const-string v2, "Invalid ECLP entry size"
  0360 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0366 throw v0
  0368 new-instance v0, Ljava/io/IOException;
  036c const-string v2, "Unsafe or duplicate ECLP path"
  0370 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0376 throw v0
  0378 new-instance v0, Ljava/io/IOException;
  037c const-string v2, "Invalid ECLP path length"
  0380 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0386 throw v0
  0388 move-object v4, v10
  038a invoke-virtual v3, Ljava/io/BufferedInputStream;->read()I
  0390 move-result v0
  0392 const/4 v2, -1
  0394 if-ne v0, v2, +009h
  0398 invoke-virtual v3, Ljava/io/BufferedInputStream;->close()V
  039e invoke-virtual v1, Ljava/io/File;->delete()Z
  03a4 return-object v4
  03a6 new-instance v0, Ljava/io/IOException;
  03aa const-string v2, "Unexpected trailing ECLP payload data"
  03ae invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03b4 throw v0
  03b6 new-instance v0, Ljava/io/IOException;
  03ba const-string v2, "Too many ECLP files"
  03be invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03c4 throw v0
  03c6 move-exception v0
  03c8 move-object v2, v0
  03ca invoke-virtual v3, Ljava/io/BufferedInputStream;->close()V
  03d0 goto +6h
  03d2 move-exception v0
  03d4 move-object v3, v0
  03d6 invoke-virtual v2, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  03dc throw v2
  03de move-exception v0
  03e0 new-instance v2, Ljava/io/IOException;
  03e4 const-string v3, "ECLP authentication failed: file damaged or metadata changed"
  03e8 invoke-direct v2, v3, v0, Ljava/io/IOException;-><init>(Ljava/lang/String; Ljava/lang/Throwable;)V
  03ee throw v2
  03f0 move-exception v0
  03f2 move-object v2, v0
  03f4 invoke-virtual v13, Ljava/io/FileOutputStream;->close()V
  03fa goto +6h
  03fc move-exception v0
  03fe move-object v3, v0
  0400 invoke-virtual v2, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0406 throw v2
  0408 move-exception v0
  040a move-object v2, v0
  040c invoke-virtual v12, Ljava/io/FileInputStream;->close()V
  0412 goto +6h
  0414 move-exception v0
  0416 move-object v3, v0
  0418 invoke-virtual v2, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  041e throw v2
  0420 move-exception v0
  0422 invoke-virtual v1, Ljava/io/File;->delete()Z
  0428 throw v0
  042a move-exception v0
  042c const/4 v2, 0
  042e invoke-static v1, v2, Ljava/util/Arrays;->fill([B B)V
  0434 throw v0
.end method

.method header(Ljava/io/File;)Lcom/personal/aihub/EclpCodec$Header;
  0000 new-instance v0, Ljava/io/FileInputStream;
  0004 invoke-direct v0, v10, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  000a const/4 v1, 4
  000c invoke-static v0, v1, Lcom/personal/aihub/EclpCodec;->exact(Ljava/io/InputStream; I)[B
  0012 move-result-object v2
  0014 new-array v3, v1, [B
  0018 fill-array-data v3, +0000082h
  001e invoke-static v2, v3, Ljava/util/Arrays;->equals([B [B)Z
  0024 move-result v2
  0026 if-eqz v2, +068h
  002a const/4 v2, 2
  002c invoke-static v0, v2, Lcom/personal/aihub/EclpCodec;->number(Ljava/io/InputStream; I)J
  0032 move-result-wide v2
  0034 const-wide/16 v4, 1
  0038 cmp-long v2, v2, v4
  003c if-nez v2, +05dh
  0040 invoke-static v0, v1, Lcom/personal/aihub/EclpCodec;->number(Ljava/io/InputStream; I)J
  0046 move-result-wide v1
  0048 const-wide/16 v6, 54
  004c add-long/2addr v6, v1
  004e cmp-long v3, v1, v4
  0052 if-ltz v3, +04ah
  0056 const-wide/32 v3, 4194304
  005c cmp-long v3, v1, v3
  0060 if-gtz v3, +043h
  0064 invoke-virtual v10, Ljava/io/File;->length()J
  006a move-result-wide v3
  006c const-wide/16 v8, 70
  0070 add-long/2addr v8, v1
  0072 cmp-long v3, v3, v8
  0076 if-ltz v3, +038h
  007a invoke-virtual v10, Ljava/io/File;->length()J
  0080 move-result-wide v3
  0082 const-wide v8, 4299161600
  008c cmp-long v10, v3, v8
  0090 if-gtz v10, +02bh
  0094 new-instance v10, Lcom/personal/aihub/EclpCodec$Header;
  0098 invoke-direct v10, Lcom/personal/aihub/EclpCodec$Header;-><init>()V
  009e new-instance v3, Ljava/lang/String;
  00a2 long-to-int v1, v1
  00a4 invoke-static v0, v1, Lcom/personal/aihub/EclpCodec;->exact(Ljava/io/InputStream; I)[B
  00aa move-result-object v1
  00ac sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  00b0 invoke-direct v3, v1, v2, Ljava/lang/String;-><init>([B Ljava/nio/charset/Charset;)V
  00b6 iput-object v3, v10, Lcom/personal/aihub/EclpCodec$Header;->metadata Ljava/lang/String;
  00ba const/16 v1, 32
  00be invoke-static v0, v1, Lcom/personal/aihub/EclpCodec;->exact(Ljava/io/InputStream; I)[B
  00c4 move-result-object v1
  00c6 iput-object v1, v10, Lcom/personal/aihub/EclpCodec$Header;->salt [B
  00ca const/16 v1, 12
  00ce invoke-static v0, v1, Lcom/personal/aihub/EclpCodec;->exact(Ljava/io/InputStream; I)[B
  00d4 move-result-object v1
  00d6 iput-object v1, v10, Lcom/personal/aihub/EclpCodec$Header;->nonce [B
  00da iput-wide v6, v10, Lcom/personal/aihub/EclpCodec$Header;->offset J
  00de invoke-virtual v0, Ljava/io/FileInputStream;->close()V
  00e4 return-object v10
  00e6 new-instance v10, Ljava/io/IOException;
  00ea const-string v1, "Invalid ECLP length"
  00ee invoke-direct v10, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  00f4 throw v10
  00f6 new-instance v10, Ljava/io/IOException;
  00fa const-string v1, "Unsupported ECLP header or version"
  00fe invoke-direct v10, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0104 throw v10
  0106 move-exception v10
  0108 invoke-virtual v0, Ljava/io/FileInputStream;->close()V
  010e goto +5h
  0110 move-exception v0
  0112 invoke-virtual v10, v0, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0118 throw v10
  011a nop 
  011c fill-array-data-payload b'ECLP' | \x45\x43\x4c\x50
.end method

.method number(Ljava/io/InputStream; I)J
  0000 invoke-static v6, v7, Lcom/personal/aihub/EclpCodec;->exact(Ljava/io/InputStream; I)[B
  0006 move-result-object v6
  0008 add-int/lit8 v7, v7, -1
  000c const-wide/16 v0, 0
  0010 move-wide v2, v0
  0012 if-ltz v7, +00eh
  0016 const/16 v4, 8
  001a shl-long/2addr v2, v4
  001c aget-byte v4, v6, v7
  0020 and-int/lit16 v4, v4, 255
  0024 int-to-long v4, v4
  0026 or-long/2addr v2, v4
  0028 add-int/lit8 v7, v7, -1
  002c goto -dh
  002e cmp-long v6, v2, v0
  0032 if-ltz v6, +003h
  0036 return-wide v2
  0038 new-instance v6, Ljava/io/IOException;
  003c const-string v7, "Invalid ECLP integer"
  0040 invoke-direct v6, v7, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0046 throw v6
.end method

.method number(Ljava/io/OutputStream; J I)V
  0000 const/4 v0, 0
  0002 if-ge v0, v6, +00fh
  0006 const-wide/16 v1, 255
  000a and-long/2addr v1, v4
  000c long-to-int v1, v1
  000e invoke-virtual v3, v1, Ljava/io/OutputStream;->write(I)V
  0014 const/16 v1, 8
  0018 ushr-long/2addr v4, v1
  001a add-int/lit8 v0, v0, 1
  001e goto -eh
  0020 return-void 
.end method

.method remove(Ljava/io/File;)V
  0000 invoke-virtual v4, Ljava/io/File;->isDirectory()Z
  0006 move-result v0
  0008 if-eqz v0, +014h
  000c invoke-virtual v4, Ljava/io/File;->listFiles()[Ljava/io/File;
  0012 move-result-object v0
  0014 if-eqz v0, +00eh
  0018 array-length v1, v0
  001a const/4 v2, 0
  001c if-ge v2, v1, +00ah
  0020 aget-object v3, v0, v2
  0024 invoke-static v3, Lcom/personal/aihub/EclpCodec;->remove(Ljava/io/File;)V
  002a add-int/lit8 v2, v2, 1
  002e goto -9h
  0030 invoke-virtual v4, Ljava/io/File;->delete()Z
  0036 return-void 
.end method

.method safePath(Ljava/lang/String;)Z
  0000 const/4 v0, 0
  0002 if-eqz v5, +050h
  0006 invoke-virtual v5, Ljava/lang/String;->isEmpty()Z
  000c move-result v1
  000e if-nez v1, +04ah
  0012 invoke-virtual v5, Ljava/lang/String;->length()I
  0018 move-result v1
  001a const/16 v2, 4096
  001e if-gt v1, v2, +042h
  0022 const-string v1, "/"
  0026 invoke-virtual v5, v1, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
  002c move-result v2
  002e if-nez v2, +03ah
  0032 const-string v2, "\"
  0036 invoke-virtual v5, v2, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
  003c move-result v2
  003e if-nez v2, +032h
  0042 const-string v2, ".*[:\x00-\x1f].*"
  0046 invoke-virtual v5, v2, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  004c move-result v2
  004e if-nez v2, +02ah
  0052 const/4 v2, -1
  0054 invoke-virtual v5, v1, v2, Ljava/lang/String;->split(Ljava/lang/String; I)[Ljava/lang/String;
  005a move-result-object v5
  005c array-length v1, v5
  005e move v2, v0
  0060 if-ge v2, v1, +01fh
  0064 aget-object v3, v5, v2
  0068 invoke-virtual v3, Ljava/lang/String;->isEmpty()Z
  006e move-result v4
  0070 if-nez v4, +016h
  0074 const-string v4, "."
  0078 invoke-virtual v3, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  007e move-result v4
  0080 if-nez v4, +00eh
  0084 const-string v4, ".."
  0088 invoke-virtual v3, v4, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  008e move-result v3
  0090 if-eqz v3, +003h
  0094 goto +4h
  0096 add-int/lit8 v2, v2, 1
  009a goto -1dh
  009c return v0
  009e const/4 v5, 1
  00a0 return v5
  00a2 return v0
.end method

.method write(Ljava/io/OutputStream; Ljava/io/File; Ljava/util/List; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)V
  0000 move-object/from16 v0, v18
  0004 invoke-interface/range v20, Ljava/util/List;->size()I
  000a move-result v1
  000c const v2, 100000
  0012 if-gt v1, v2, +1c4h
  0016 sget-object v1, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  001a move-object/from16 v2, v21
  001e invoke-virtual v2, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0024 move-result-object v1
  0026 array-length v2, v1
  0028 const/high16 v3, 4194304
  002c if-gt v2, v3, +1afh
  0030 new-instance v2, Ljava/io/File;
  0034 new-instance v3, Ljava/lang/StringBuilder;
  0038 const-string v4, "eclp-write-"
  003c invoke-direct v3, v4, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0042 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0048 move-result-object v4
  004a invoke-virtual v3, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  0050 invoke-virtual v3, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0056 move-result-object v3
  0058 move-object/from16 v4, v19
  005c invoke-direct v2, v4, v3, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0062 invoke-virtual v2, Ljava/io/File;->mkdirs()Z
  0068 new-instance v3, Ljava/util/HashSet;
  006c invoke-direct v3, Ljava/util/HashSet;-><init>()V
  0072 new-instance v4, Ljava/util/ArrayList;
  0076 invoke-direct v4, Ljava/util/ArrayList;-><init>()V
  007c invoke-interface/range v20, Ljava/util/List;->iterator()Ljava/util/Iterator;
  0082 move-result-object v5
  0084 const-wide/16 v6, 0
  0088 invoke-interface v5, Ljava/util/Iterator;->hasNext()Z
  008e move-result v8
  0090 const-wide/32 v9, 536870912
  0096 if-eqz v8, +0b1h
  009a invoke-interface v5, Ljava/util/Iterator;->next()Ljava/lang/Object;
  00a0 move-result-object v8
  00a2 check-cast v8, Lcom/personal/aihub/EclpCodec$Entry;
  00a6 iget-object v11, v8, Lcom/personal/aihub/EclpCodec$Entry;->path Ljava/lang/String;
  00aa invoke-static v11, Lcom/personal/aihub/EclpCodec;->safePath(Ljava/lang/String;)Z
  00b0 move-result v11
  00b2 if-eqz v11, +09bh
  00b6 iget-object v11, v8, Lcom/personal/aihub/EclpCodec$Entry;->path Ljava/lang/String;
  00ba sget-object v12, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  00be invoke-virtual v11, v12, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  00c4 move-result-object v11
  00c6 array-length v11, v11
  00c8 const/16 v12, 4096
  00cc if-gt v11, v12, +08eh
  00d0 iget-object v11, v8, Lcom/personal/aihub/EclpCodec$Entry;->path Ljava/lang/String;
  00d4 invoke-virtual v3, v11, Ljava/util/HashSet;->add(Ljava/lang/Object;)Z
  00da move-result v11
  00dc if-eqz v11, +086h
  00e0 invoke-virtual v8, Lcom/personal/aihub/EclpCodec$Entry;->size()J
  00e6 move-result-wide v11
  00e8 add-long/2addr v6, v11
  00ea invoke-virtual v8, Lcom/personal/aihub/EclpCodec$Entry;->size()J
  00f0 move-result-wide v11
  00f2 cmp-long v11, v11, v9
  00f6 if-gtz v11, +071h
  00fa const-wide v11, 4294967296
  0104 cmp-long v11, v6, v11
  0108 if-gtz v11, +068h
  010c new-instance v11, Ljava/io/File;
  0110 invoke-virtual v4, Ljava/util/ArrayList;->size()I
  0116 move-result v12
  0118 invoke-static v12, Ljava/lang/Integer;->toString(I)Ljava/lang/String;
  011e move-result-object v12
  0120 invoke-direct v11, v2, v12, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0126 invoke-virtual v8, Lcom/personal/aihub/EclpCodec$Entry;->input()Ljava/io/InputStream;
  012c move-result-object v12
  012e new-instance v13, Lcom/github/luben/zstd/ZstdOutputStream;
  0132 new-instance v14, Ljava/io/FileOutputStream;
  0136 invoke-direct v14, v11, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  013c const/4 v15, 3
  013e invoke-direct v13, v14, v15, Lcom/github/luben/zstd/ZstdOutputStream;-><init>(Ljava/io/OutputStream; I)V
  0144 invoke-static v12, v13, v9, v10, Lcom/personal/aihub/EclpCodec;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)J
  014a move-result-wide v14
  014c invoke-virtual v8, Lcom/personal/aihub/EclpCodec$Entry;->size()J
  0152 move-result-wide v16
  0154 cmp-long v8, v14, v16
  0158 if-nez v8, +01eh
  015c invoke-virtual v13, Lcom/github/luben/zstd/ZstdOutputStream;->close()V
  0162 if-eqz v12, +005h
  0166 invoke-virtual v12, Ljava/io/InputStream;->close()V
  016c invoke-virtual v11, Ljava/io/File;->length()J
  0172 move-result-wide v12
  0174 cmp-long v8, v12, v9
  0178 if-gtz v8, +006h
  017c invoke-virtual v4, v11, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0182 goto -7dh
  0184 new-instance v0, Ljava/io/IOException;
  0188 const-string v1, "Compressed entry exceeds Eclipse’s 512 MB limit"
  018c invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0192 throw v0
  0194 new-instance v0, Ljava/io/IOException;
  0198 const-string v1, "Resource changed during export"
  019c invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01a2 throw v0
  01a4 move-exception v0
  01a6 move-object v1, v0
  01a8 invoke-virtual v13, Lcom/github/luben/zstd/ZstdOutputStream;->close()V
  01ae goto +6h
  01b0 move-exception v0
  01b2 move-object v3, v0
  01b4 invoke-virtual v1, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  01ba throw v1
  01bc move-exception v0
  01be move-object v1, v0
  01c0 if-eqz v12, +00bh
  01c4 invoke-virtual v12, Ljava/io/InputStream;->close()V
  01ca goto +6h
  01cc move-exception v0
  01ce move-object v3, v0
  01d0 invoke-virtual v1, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  01d6 throw v1
  01d8 new-instance v0, Ljava/io/IOException;
  01dc const-string v1, "ECLP exceeds the 512 MB per file or 4 GB total limit"
  01e0 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01e6 throw v0
  01e8 new-instance v0, Ljava/io/IOException;
  01ec const-string v1, "Invalid or duplicate ECLP path"
  01f0 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  01f6 throw v0
  01f8 const/16 v3, 32
  01fc new-array v3, v3, [B
  0200 const/16 v5, 12
  0204 new-array v5, v5, [B
  0208 new-instance v6, Ljava/security/SecureRandom;
  020c invoke-direct v6, Ljava/security/SecureRandom;-><init>()V
  0212 invoke-virtual v6, v3, Ljava/security/SecureRandom;->nextBytes([B)V
  0218 invoke-virtual v6, v5, Ljava/security/SecureRandom;->nextBytes([B)V
  021e move-object/from16 v6, v22
  0222 move-object/from16 v7, v23
  0226 move-object/from16 v8, v24
  022a invoke-static v6, v7, v8, v3, Lcom/personal/aihub/EclpCodec;->derive(Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; [B)[B
  0230 move-result-object v6
  0232 const-string v7, "AES/GCM/NoPadding"
  0236 invoke-static v7, Ljavax/crypto/Cipher;->getInstance(Ljava/lang/String;)Ljavax/crypto/Cipher;
  023c move-result-object v7
  023e const/4 v8, 0
  0240 new-instance v11, Ljavax/crypto/spec/SecretKeySpec;
  0244 const-string v12, "AES"
  0248 invoke-direct v11, v6, v12, Ljavax/crypto/spec/SecretKeySpec;-><init>([B Ljava/lang/String;)V
  024e new-instance v12, Ljavax/crypto/spec/GCMParameterSpec;
  0252 const/16 v13, 128
  0256 invoke-direct v12, v13, v5, Ljavax/crypto/spec/GCMParameterSpec;-><init>(I [B)V
  025c const/4 v13, 1
  025e invoke-virtual v7, v13, v11, v12, Ljavax/crypto/Cipher;->init(I Ljava/security/Key; Ljava/security/spec/AlgorithmParameterSpec;)V
  0264 invoke-static v6, v8, Ljava/util/Arrays;->fill([B B)V
  026a const/4 v6, 4
  026c new-array v11, v6, [B
  0270 fill-array-data v11, +000009eh
  0276 invoke-virtual v0, v11, Ljava/io/OutputStream;->write([B)V
  027c const-wide/16 v11, 1
  0280 const/4 v13, 2
  0282 invoke-static v0, v11, v12, v13, Lcom/personal/aihub/EclpCodec;->number(Ljava/io/OutputStream; J I)V
  0288 array-length v11, v1
  028a int-to-long v11, v11
  028c invoke-static v0, v11, v12, v6, Lcom/personal/aihub/EclpCodec;->number(Ljava/io/OutputStream; J I)V
  0292 invoke-virtual v0, v1, Ljava/io/OutputStream;->write([B)V
  0298 invoke-virtual v0, v3, Ljava/io/OutputStream;->write([B)V
  029e invoke-virtual v0, v5, Ljava/io/OutputStream;->write([B)V
  02a4 new-instance v1, Lcom/personal/aihub/EclpCodec$1;
  02a8 invoke-direct v1, v7, v0, Lcom/personal/aihub/EclpCodec$1;-><init>(Ljavax/crypto/Cipher; Ljava/io/OutputStream;)V
  02ae invoke-interface/range v20, Ljava/util/List;->size()I
  02b4 move-result v3
  02b6 int-to-long v11, v3
  02b8 invoke-static v1, v11, v12, v6, Lcom/personal/aihub/EclpCodec;->number(Ljava/io/OutputStream; J I)V
  02be invoke-interface/range v20, Ljava/util/List;->size()I
  02c4 move-result v3
  02c6 if-ge v8, v3, +04ah
  02ca move-object/from16 v3, v20
  02ce invoke-interface v3, v8, Ljava/util/List;->get(I)Ljava/lang/Object;
  02d4 move-result-object v5
  02d6 check-cast v5, Lcom/personal/aihub/EclpCodec$Entry;
  02da invoke-virtual v4, v8, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;
  02e0 move-result-object v6
  02e2 check-cast v6, Ljava/io/File;
  02e6 iget-object v11, v5, Lcom/personal/aihub/EclpCodec$Entry;->path Ljava/lang/String;
  02ea sget-object v12, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  02ee invoke-virtual v11, v12, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  02f4 move-result-object v11
  02f6 array-length v12, v11
  02f8 int-to-long v14, v12
  02fa invoke-static v1, v14, v15, v13, Lcom/personal/aihub/EclpCodec;->number(Ljava/io/OutputStream; J I)V
  0300 invoke-virtual v1, v11, Ljava/io/OutputStream;->write([B)V
  0306 invoke-virtual v6, Ljava/io/File;->length()J
  030c move-result-wide v11
  030e const/16 v14, 8
  0312 invoke-static v1, v11, v12, v14, Lcom/personal/aihub/EclpCodec;->number(Ljava/io/OutputStream; J I)V
  0318 invoke-virtual v5, Lcom/personal/aihub/EclpCodec$Entry;->size()J
  031e move-result-wide v11
  0320 invoke-static v1, v11, v12, v14, Lcom/personal/aihub/EclpCodec;->number(Ljava/io/OutputStream; J I)V
  0326 new-instance v5, Ljava/io/FileInputStream;
  032a invoke-direct v5, v6, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0330 invoke-static v5, v1, v9, v10, Lcom/personal/aihub/EclpCodec;->copy(Ljava/io/InputStream; Ljava/io/OutputStream; J)J
  0336 invoke-virtual v5, Ljava/io/FileInputStream;->close()V
  033c add-int/lit8 v8, v8, 1
  0340 goto -41h
  0342 move-exception v0
  0344 move-object v1, v0
  0346 invoke-virtual v5, Ljava/io/FileInputStream;->close()V
  034c goto +6h
  034e move-exception v0
  0350 move-object v3, v0
  0352 invoke-virtual v1, v3, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0358 throw v1
  035a invoke-virtual v7, Ljavax/crypto/Cipher;->doFinal()[B
  0360 move-result-object v1
  0362 invoke-virtual v0, v1, Ljava/io/OutputStream;->write([B)V
  0368 invoke-virtual/range v18, Ljava/io/OutputStream;->flush()V
  036e invoke-static v2, Lcom/personal/aihub/EclpCodec;->remove(Ljava/io/File;)V
  0374 return-void 
  0376 move-exception v0
  0378 invoke-static v6, v8, Ljava/util/Arrays;->fill([B B)V
  037e throw v0
  0380 move-exception v0
  0382 invoke-static v2, Lcom/personal/aihub/EclpCodec;->remove(Ljava/io/File;)V
  0388 throw v0
  038a new-instance v0, Ljava/io/IOException;
  038e const-string v1, "Patch metadata too large"
  0392 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0398 throw v0
  039a new-instance v0, Ljava/io/IOException;
  039e const-string v1, "Too many patch files"
  03a2 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03a8 throw v0
  03aa nop 
  03ac fill-array-data-payload b'ECLP' | \x45\x43\x4c\x50
.end method