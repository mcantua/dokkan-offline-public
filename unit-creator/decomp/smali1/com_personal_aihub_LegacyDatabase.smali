.class Lcom/personal/aihub/LegacyDatabase;
.super Ljava/lang/Object;
.field LIMIT I

.method <init>()V
  0000 invoke-direct v0, Ljava/lang/Object;-><init>()V
  0006 return-void 
.end method

.method decrypt(Ljava/io/File; Ljava/io/File; [B)V
  0000 const/4 v0, 3
  0002 invoke-static v1, v2, v3, v0, Lcom/personal/aihub/LegacyDatabase;->decrypt(Ljava/io/File; Ljava/io/File; [B I)V
  0008 return-void 
.end method

.method decrypt(Ljava/io/File; Ljava/io/File; [B I)V
  0000 move-object/from16 v0, v28
  0004 move/from16 v1, v29
  0008 const/4 v2, 4
  000a const/4 v3, 3
  000c if-eq v1, v3, +00dh
  0010 if-ne v1, v2, +003h
  0014 goto +9h
  0016 new-instance v0, Ljava/io/IOException;
  001a const-string v1, "Unsupported database cipher mode."
  001e invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0024 throw v0
  0026 const/16 v4, 4096
  002a if-ne v1, v3, +005h
  002e const/16 v5, 1024
  0032 goto +2h
  0034 move v5, v4
  0036 if-ne v1, v3, +005h
  003a const/16 v6, 48
  003e goto +3h
  0040 const/16 v6, 80
  0044 sub-int v7, v5, v6
  0048 if-ne v1, v3, +005h
  004c const/16 v9, 20
  0050 goto +3h
  0052 const/16 v9, 64
  0056 if-ne v1, v3, +005h
  005a const-string v10, "HmacSHA1"
  005e goto +3h
  0060 const-string v10, "HmacSHA512"
  0064 if-eqz v0, +2b9h
  0068 array-length v11, v0
  006a if-eqz v11, +2b6h
  006e array-length v11, v0
  0070 if-gt v11, v4, +2b3h
  0074 invoke-virtual/range v26, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  007a move-result-object v4
  007c invoke-virtual/range v27, Ljava/io/File;->getAbsoluteFile()Ljava/io/File;
  0082 move-result-object v11
  0084 invoke-virtual v11, Ljava/io/File;->getParentFile()Ljava/io/File;
  008a move-result-object v11
  008c invoke-virtual v11, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  0092 move-result-object v11
  0094 new-instance v12, Ljava/io/File;
  0098 invoke-virtual/range v27, Ljava/io/File;->getName()Ljava/lang/String;
  009e move-result-object v13
  00a0 invoke-direct v12, v11, v13, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00a6 invoke-virtual v11, Ljava/io/File;->isDirectory()Z
  00ac move-result v13
  00ae if-eqz v13, +28ch
  00b2 invoke-virtual v4, v12, Ljava/io/File;->equals(Ljava/lang/Object;)Z
  00b8 move-result v13
  00ba if-nez v13, +286h
  00be invoke-virtual v12, Ljava/io/File;->exists()Z
  00c4 move-result v13
  00c6 if-eqz v13, +00ch
  00ca invoke-virtual v12, Ljava/io/File;->getCanonicalFile()Ljava/io/File;
  00d0 move-result-object v13
  00d2 invoke-virtual v13, v12, Ljava/io/File;->equals(Ljava/lang/Object;)Z
  00d8 move-result v13
  00da if-eqz v13, +276h
  00de invoke-virtual v4, Ljava/io/File;->length()J
  00e4 move-result-wide v13
  00e6 invoke-virtual v4, Ljava/io/File;->isFile()Z
  00ec move-result v15
  00ee if-eqz v15, +264h
  00f2 move/from16 v16, v9
  00f6 int-to-long v8, v5
  00f8 cmp-long v17, v13, v8
  00fc if-ltz v17, +25dh
  0100 const-wide/32 v17, 536870912
  0106 cmp-long v17, v13, v17
  010a if-gtz v17, +256h
  010e rem-long v17, v13, v8
  0112 const-wide/16 v19, 0
  0116 cmp-long v17, v17, v19
  011a if-nez v17, +24eh
  011e new-instance v15, Ljava/io/File;
  0122 new-instance v2, Ljava/lang/StringBuilder;
  0126 const-string v3, "legacy-db-"
  012a invoke-direct v2, v3, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0130 invoke-static Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
  0136 move-result-object v3
  0138 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
  013e const-string v3, ".tmp"
  0142 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0148 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  014e move-result-object v2
  0150 invoke-direct v15, v11, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  0156 new-instance v11, Ljava/io/DataInputStream;
  015a new-instance v2, Ljava/io/BufferedInputStream;
  015e new-instance v3, Ljava/io/FileInputStream;
  0162 invoke-direct v3, v4, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V
  0168 invoke-direct v2, v3, Ljava/io/BufferedInputStream;-><init>(Ljava/io/InputStream;)V
  016e invoke-direct v11, v2, Ljava/io/DataInputStream;-><init>(Ljava/io/InputStream;)V
  0174 new-instance v2, Ljava/io/FileOutputStream;
  0178 invoke-direct v2, v15, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
  017e new-instance v3, Ljava/io/BufferedOutputStream;
  0182 invoke-direct v3, v2, Ljava/io/BufferedOutputStream;-><init>(Ljava/io/OutputStream;)V
  0188 new-array v4, v5, [B
  018c invoke-virtual v11, v4, Ljava/io/DataInputStream;->readFully([B)V
  0192 move-object/from16 v20, v12
  0196 const/16 v12, 16
  019a move-object/from16 v21, v15
  019e invoke-static v4, v12, Ljava/util/Arrays;->copyOf([B I)[B
  01a4 move-result-object v15
  01a6 invoke-virtual v15, [B->clone()Ljava/lang/Object;
  01ac move-result-object v22
  01ae move-object/from16 v12, v22
  01b2 check-cast v12, [B
  01b6 move-object/from16 v22, v2
  01ba move-object/from16 v23, v3
  01be const/4 v2, 0
  01c0 array-length v3, v12
  01c2 if-ge v2, v3, +014h
  01c6 aget-byte v3, v12, v2
  01ca xor-int/lit8 v3, v3, 58
  01ce int-to-byte v3, v3
  01d0 aput-byte v3, v12, v2
  01d4 add-int/lit8 v2, v2, 1
  01d8 goto -ch
  01da move-exception v0
  01dc move-object v4, v0
  01de move-object/from16 v1, v21
  01e2 move-object/from16 v15, v23
  01e6 goto/16 +19bh
  01ea const/4 v2, 3
  01ec if-ne v1, v2, +006h
  01f0 const v1, 64000
  01f6 goto +4h
  01f8 const v1, 256000
  01fe const/16 v2, 32
  0202 invoke-static v0, v15, v1, v2, v10, Lcom/personal/aihub/LegacyDatabase;->derive([B [B I I Ljava/lang/String;)[B
  0208 move-result-object v1
  020a const/4 v0, 2
  020c invoke-static v1, v12, v0, v2, v10, Lcom/personal/aihub/LegacyDatabase;->derive([B [B I I Ljava/lang/String;)[B
  0212 move-result-object v3
  0214 invoke-static v10, Ljavax/crypto/Mac;->getInstance(Ljava/lang/String;)Ljavax/crypto/Mac;
  021a move-result-object v12
  021c new-instance v15, Ljavax/crypto/spec/SecretKeySpec;
  0220 invoke-direct v15, v3, v10, Ljavax/crypto/spec/SecretKeySpec;-><init>([B Ljava/lang/String;)V
  0226 invoke-virtual v12, v15, Ljavax/crypto/Mac;->init(Ljava/security/Key;)V
  022c const-string v10, "AES/CBC/NoPadding"
  0230 invoke-static v10, Ljavax/crypto/Cipher;->getInstance(Ljava/lang/String;)Ljavax/crypto/Cipher;
  0236 move-result-object v10
  0238 const/4 v15, 1
  023a move-object/from16 v28, v1
  023e move v2, v15
  0240 int-to-long v0, v2
  0242 div-long v24, v13, v8
  0246 cmp-long v0, v0, v24
  024a if-gtz v0, +0d9h
  024e if-le v2, v15, +010h
  0252 invoke-virtual v11, v4, Ljava/io/DataInputStream;->readFully([B)V
  0258 goto +bh
  025a move-exception v0
  025c move-object/from16 v2, v28
  0260 move-object v4, v0
  0262 move-object/from16 v1, v21
  0266 move-object/from16 v15, v23
  026a goto/16 +15bh
  026e if-ne v2, v15, +005h
  0272 const/16 v0, 16
  0276 goto +2h
  0278 const/4 v0, 0
  027a add-int/lit8 v1, v7, 16
  027e sub-int v15, v1, v0
  0282 invoke-virtual v12, v4, v0, v15, Ljavax/crypto/Mac;->update([B I I)V
  0288 int-to-byte v15, v2
  028a invoke-virtual v12, v15, Ljavax/crypto/Mac;->update(B)V
  0290 ushr-int/lit8 v15, v2, 8
  0294 int-to-byte v15, v15
  0296 invoke-virtual v12, v15, Ljavax/crypto/Mac;->update(B)V
  029c ushr-int/lit8 v15, v2, 16
  02a0 int-to-byte v15, v15
  02a2 invoke-virtual v12, v15, Ljavax/crypto/Mac;->update(B)V
  02a8 ushr-int/lit8 v15, v2, 24
  02ac int-to-byte v15, v15
  02ae invoke-virtual v12, v15, Ljavax/crypto/Mac;->update(B)V
  02b4 invoke-virtual v12, Ljavax/crypto/Mac;->doFinal()[B
  02ba move-result-object v15
  02bc move-wide/from16 v24, v8
  02c0 add-int v8, v1, v16
  02c4 invoke-static v4, v1, v8, Ljava/util/Arrays;->copyOfRange([B I I)[B
  02ca move-result-object v1
  02cc invoke-static v15, v1, Ljava/security/MessageDigest;->isEqual([B [B)Z
  02d2 move-result v1
  02d4 if-eqz v1, +07bh
  02d8 new-instance v1, Ljavax/crypto/spec/SecretKeySpec;
  02dc const-string v8, "AES"
  02e0 move-object/from16 v9, v28
  02e4 invoke-direct v1, v9, v8, Ljavax/crypto/spec/SecretKeySpec;-><init>([B Ljava/lang/String;)V
  02ea new-instance v8, Ljavax/crypto/spec/IvParameterSpec;
  02ee const/16 v15, 16
  02f2 invoke-direct v8, v4, v7, v15, Ljavax/crypto/spec/IvParameterSpec;-><init>([B I I)V
  02f8 const/4 v15, 2
  02fa invoke-virtual v10, v15, v1, v8, Ljavax/crypto/Cipher;->init(I Ljava/security/Key; Ljava/security/spec/AlgorithmParameterSpec;)V
  0300 sub-int v1, v7, v0
  0304 invoke-virtual v10, v4, v0, v1, Ljavax/crypto/Cipher;->doFinal([B I I)[B
  030a move-result-object v0
  030c const/4 v1, 1
  030e if-ne v2, v1, +042h
  0312 const/4 v8, 0
  0314 aget-byte v15, v0, v8
  0318 and-int/lit16 v8, v15, 255
  031c shl-int/lit8 v8, v8, 8
  0320 aget-byte v15, v0, v1
  0324 and-int/lit16 v15, v15, 255
  0328 or-int/2addr v8, v15
  032a if-ne v8, v5, +02ah
  032e const/4 v8, 4
  0330 aget-byte v15, v0, v8
  0334 and-int/lit16 v15, v15, 255
  0338 if-lt v15, v6, +023h
  033c const/4 v15, 5
  033e aget-byte v15, v0, v15
  0342 const/16 v1, 64
  0346 if-ne v15, v1, +01ch
  034a const/4 v15, 6
  034c aget-byte v15, v0, v15
  0350 const/16 v1, 32
  0354 if-ne v15, v1, +015h
  0358 const/4 v15, 7
  035a aget-byte v15, v0, v15
  035e if-ne v15, v1, +010h
  0362 const-string v15, "SQLite format 3 "
  0366 sget-object v1, Ljava/nio/charset/StandardCharsets;->US_ASCII Ljava/nio/charset/Charset;
  036a invoke-virtual v15, v1, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  0370 move-result-object v1
  0372 move-object/from16 v15, v23
  0376 invoke-virtual v15, v1, Ljava/io/BufferedOutputStream;->write([B)V
  037c goto +eh
  037e move-object/from16 v15, v23
  0382 new-instance v0, Ljava/io/IOException;
  0386 const-string v1, "The decrypted database has an unsupported SQLite header."
  038a invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0390 throw v0
  0392 move-object/from16 v15, v23
  0396 const/4 v8, 4
  0398 invoke-virtual v15, v0, Ljava/io/BufferedOutputStream;->write([B)V
  039e new-array v1, v6, [B
  03a2 invoke-virtual v15, v1, Ljava/io/BufferedOutputStream;->write([B)V
  03a8 const/4 v1, 0
  03aa invoke-static v0, v1, Ljava/util/Arrays;->fill([B B)V
  03b0 add-int/lit8 v2, v2, 1
  03b4 move-object/from16 v28, v9
  03b8 move-object/from16 v23, v15
  03bc move-wide/from16 v8, v24
  03c0 const/4 v15, 1
  03c2 goto/16 -0c1h
  03c6 move-exception v0
  03c8 goto +12h
  03ca move-object/from16 v9, v28
  03ce move-object/from16 v15, v23
  03d2 new-instance v0, Ljava/io/IOException;
  03d6 const-string v1, "Database authentication failed. The file is damaged or does not match this imported APK's supported format."
  03da invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  03e0 throw v0
  03e2 move-exception v0
  03e4 goto +6h
  03e6 move-exception v0
  03e8 move-object/from16 v9, v28
  03ec move-object/from16 v15, v23
  03f0 move-object v4, v0
  03f2 move-object v2, v9
  03f4 move-object/from16 v1, v21
  03f8 goto/16 +094h
  03fc move-object/from16 v9, v28
  0400 move-object/from16 v15, v23
  0404 invoke-virtual v11, Ljava/io/DataInputStream;->read()I
  040a move-result v0
  040c const/4 v1, -1
  040e if-ne v0, v1, +04eh
  0412 invoke-virtual v15, Ljava/io/BufferedOutputStream;->flush()V
  0418 invoke-virtual/range v22, Ljava/io/FileOutputStream;->getFD()Ljava/io/FileDescriptor;
  041e move-result-object v0
  0420 invoke-virtual v0, Ljava/io/FileDescriptor;->sync()V
  0426 invoke-virtual v15, Ljava/io/BufferedOutputStream;->close()V
  042c invoke-virtual/range v22, Ljava/io/FileOutputStream;->close()V
  0432 invoke-virtual v11, Ljava/io/DataInputStream;->close()V
  0438 const/4 v1, 0
  043a if-eqz v9, +005h
  043e invoke-static v9, v1, Ljava/util/Arrays;->fill([B B)V
  0444 if-eqz v3, +005h
  0448 invoke-static v3, v1, Ljava/util/Arrays;->fill([B B)V
  044e move-object/from16 v0, v20
  0452 move-object/from16 v1, v21
  0456 invoke-virtual v1, v0, Ljava/io/File;->renameTo(Ljava/io/File;)Z
  045c move-result v0
  045e if-eqz v0, +003h
  0462 return-void 
  0464 invoke-virtual v1, Ljava/io/File;->delete()Z
  046a new-instance v0, Ljava/io/IOException;
  046e const-string v1, "Could not save the authenticated database."
  0472 invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  0478 throw v0
  047a move-exception v0
  047c move-object v2, v9
  047e goto/16 +090h
  0482 move-exception v0
  0484 move-object/from16 v1, v21
  0488 move-object v2, v9
  048a goto/16 +085h
  048e move-exception v0
  0490 move-object/from16 v1, v21
  0494 move-object v4, v0
  0496 move-object v2, v9
  0498 goto/16 +06ah
  049c move-exception v0
  049e move-object/from16 v1, v21
  04a2 move-object v4, v0
  04a4 move-object v2, v9
  04a6 goto/16 +051h
  04aa move-object/from16 v1, v21
  04ae new-instance v0, Ljava/io/IOException;
  04b2 const-string v2, "The legacy database changed during import."
  04b6 invoke-direct v0, v2, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  04bc throw v0
  04be move-exception v0
  04c0 goto +fh
  04c2 move-exception v0
  04c4 move-object/from16 v1, v21
  04c8 goto +bh
  04ca move-exception v0
  04cc move-object/from16 v9, v28
  04d0 goto +3h
  04d2 move-exception v0
  04d4 move-object v9, v1
  04d6 move-object/from16 v1, v21
  04da move-object/from16 v15, v23
  04de move-object v4, v0
  04e0 move-object v2, v9
  04e2 goto +1fh
  04e4 move-exception v0
  04e6 move-object v9, v1
  04e8 move-object/from16 v1, v21
  04ec move-object/from16 v15, v23
  04f0 move-object v4, v0
  04f2 move-object v2, v9
  04f4 goto +15h
  04f6 move-exception v0
  04f8 move-object/from16 v1, v21
  04fc move-object/from16 v15, v23
  0500 goto +dh
  0502 move-exception v0
  0504 move-object/from16 v22, v2
  0508 move-object v15, v3
  050a move-object/from16 v1, v21
  050e goto +6h
  0510 move-exception v0
  0512 move-object/from16 v22, v2
  0516 move-object v1, v15
  0518 move-object v15, v3
  051a move-object v4, v0
  051c const/4 v2, 0
  051e const/4 v3, 0
  0520 invoke-virtual v15, Ljava/io/BufferedOutputStream;->close()V
  0526 goto +6h
  0528 move-exception v0
  052a move-object v5, v0
  052c invoke-virtual v4, v5, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  0532 throw v4
  0534 move-exception v0
  0536 move-object v4, v0
  0538 goto +8h
  053a move-exception v0
  053c move-object/from16 v22, v2
  0540 move-object v1, v15
  0542 move-object v4, v0
  0544 const/4 v2, 0
  0546 const/4 v3, 0
  0548 invoke-virtual/range v22, Ljava/io/FileOutputStream;->close()V
  054e goto +6h
  0550 move-exception v0
  0552 move-object v5, v0
  0554 invoke-virtual v4, v5, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  055a throw v4
  055c move-exception v0
  055e move-object v4, v0
  0560 goto +6h
  0562 move-exception v0
  0564 move-object v1, v15
  0566 move-object v4, v0
  0568 const/4 v2, 0
  056a const/4 v3, 0
  056c invoke-virtual v11, Ljava/io/DataInputStream;->close()V
  0572 goto +6h
  0574 move-exception v0
  0576 move-object v5, v0
  0578 invoke-virtual v4, v5, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V
  057e throw v4
  0580 move-exception v0
  0582 goto +9h
  0584 move-exception v0
  0586 const/4 v2, 0
  0588 const/4 v3, 0
  058a goto +ah
  058c move-exception v0
  058e move-object v1, v15
  0590 const/4 v2, 0
  0592 const/4 v3, 0
  0594 invoke-virtual v1, Ljava/io/File;->delete()Z
  059a throw v0
  059c move-exception v0
  059e const/4 v1, 0
  05a0 if-eqz v2, +005h
  05a4 invoke-static v2, v1, Ljava/util/Arrays;->fill([B B)V
  05aa if-eqz v3, +005h
  05ae invoke-static v3, v1, Ljava/util/Arrays;->fill([B B)V
  05b4 throw v0
  05b6 new-instance v0, Ljava/io/IOException;
  05ba const-string v1, "This legacy database is incomplete or uses an unsupported page format."
  05be invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  05c4 throw v0
  05c6 new-instance v0, Ljava/io/IOException;
  05ca const-string v1, "Choose a separate safe database output file."
  05ce invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  05d4 throw v0
  05d6 new-instance v0, Ljava/io/IOException;
  05da const-string v1, "The imported APK did not provide a supported database format."
  05de invoke-direct v0, v1, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
  05e4 throw v0
.end method

.method derive([B [B I I Ljava/lang/String;)[B
  0000 invoke-static v15, Ljavax/crypto/Mac;->getInstance(Ljava/lang/String;)Ljavax/crypto/Mac;
  0006 move-result-object v0
  0008 new-instance v1, Ljavax/crypto/spec/SecretKeySpec;
  000c invoke-direct v1, v11, v15, Ljavax/crypto/spec/SecretKeySpec;-><init>([B Ljava/lang/String;)V
  0012 invoke-virtual v0, v1, Ljavax/crypto/Mac;->init(Ljava/security/Key;)V
  0018 new-array v11, v14, [B
  001c array-length v15, v12
  001e add-int/lit8 v15, v15, 4
  0022 new-array v15, v15, [B
  0026 array-length v1, v12
  0028 const/4 v2, 0
  002a invoke-static v12, v2, v15, v2, v1, Ljava/lang/System;->arraycopy(Ljava/lang/Object; I Ljava/lang/Object; I I)V
  0030 const/4 v1, 1
  0032 move v4, v1
  0034 move v3, v2
  0036 if-ge v3, v14, +054h
  003a array-length v5, v12
  003c ushr-int/lit8 v6, v4, 24
  0040 int-to-byte v6, v6
  0042 aput-byte v6, v15, v5
  0046 array-length v5, v12
  0048 add-int/2addr v5, v1
  004a ushr-int/lit8 v6, v4, 16
  004e int-to-byte v6, v6
  0050 aput-byte v6, v15, v5
  0054 array-length v5, v12
  0056 add-int/lit8 v5, v5, 2
  005a ushr-int/lit8 v6, v4, 8
  005e int-to-byte v6, v6
  0060 aput-byte v6, v15, v5
  0064 array-length v5, v12
  0066 add-int/lit8 v5, v5, 3
  006a int-to-byte v6, v4
  006c aput-byte v6, v15, v5
  0070 invoke-virtual v0, v15, Ljavax/crypto/Mac;->doFinal([B)[B
  0076 move-result-object v5
  0078 invoke-virtual v5, [B->clone()Ljava/lang/Object;
  007e move-result-object v6
  0080 check-cast v6, [B
  0084 move v7, v1
  0086 if-ge v7, v13, +018h
  008a invoke-virtual v0, v5, Ljavax/crypto/Mac;->doFinal([B)[B
  0090 move-result-object v5
  0092 move v8, v2
  0094 array-length v9, v6
  0096 if-ge v8, v9, +00dh
  009a aget-byte v9, v6, v8
  009e aget-byte v10, v5, v8
  00a2 xor-int/2addr v9, v10
  00a4 int-to-byte v9, v9
  00a6 aput-byte v9, v6, v8
  00aa add-int/lit8 v8, v8, 1
  00ae goto -dh
  00b0 add-int/lit8 v7, v7, 1
  00b4 goto -17h
  00b6 array-length v7, v6
  00b8 sub-int v8, v14, v3
  00bc invoke-static v7, v8, Ljava/lang/Math;->min(I I)I
  00c2 move-result v7
  00c4 invoke-static v6, v2, v11, v3, v7, Ljava/lang/System;->arraycopy(Ljava/lang/Object; I Ljava/lang/Object; I I)V
  00ca add-int/2addr v3, v7
  00cc invoke-static v6, v2, Ljava/util/Arrays;->fill([B B)V
  00d2 invoke-static v5, v2, Ljava/util/Arrays;->fill([B B)V
  00d8 add-int/lit8 v4, v4, 1
  00dc goto -53h
  00de return-object v11
.end method