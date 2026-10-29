.class Lcom/personal/aihub/CpkArchive$Table;
.super Ljava/lang/Object;
.field b [B
.field be Ljava/nio/ByteBuffer;
.field data I
.field length I
.field rows I
.field strings I

.method <init>([B)V
  0000 invoke-direct v12, Ljava/lang/Object;-><init>()V
  0006 invoke-virtual v13, [B->clone()Ljava/lang/Object;
  000c move-result-object v13
  000e check-cast v13, [B
  0012 iput-object v13, v12, Lcom/personal/aihub/CpkArchive$Table;->b [B
  0016 array-length v0, v13
  0018 const-string v1, "@UTF"
  001c const/4 v2, 0
  001e const/4 v3, 4
  0020 if-lt v0, v3, +00fh
  0024 new-instance v0, Ljava/lang/String;
  0028 sget-object v4, Ljava/nio/charset/StandardCharsets;->US_ASCII Ljava/nio/charset/Charset;
  002c invoke-direct v0, v13, v2, v3, v4, Ljava/lang/String;-><init>([B I I Ljava/nio/charset/Charset;)V
  0032 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0038 move-result v13
  003a if-nez v13, +018h
  003e const/16 v13, 95
  0042 move v0, v2
  0044 iget-object v4, v12, Lcom/personal/aihub/CpkArchive$Table;->b [B
  0048 array-length v5, v4
  004a if-ge v0, v5, +010h
  004e aget-byte v5, v4, v0
  0052 int-to-byte v6, v13
  0054 xor-int/2addr v5, v6
  0056 int-to-byte v5, v5
  0058 aput-byte v5, v4, v0
  005c mul-int/lit16 v13, v13, 16661
  0060 and-int/lit16 v13, v13, 255
  0064 add-int/lit8 v0, v0, 1
  0068 goto -12h
  006a iget-object v13, v12, Lcom/personal/aihub/CpkArchive$Table;->b [B
  006e array-length v0, v13
  0070 const/16 v4, 32
  0074 if-lt v0, v4, +06ah
  0078 new-instance v0, Ljava/lang/String;
  007c sget-object v5, Ljava/nio/charset/StandardCharsets;->US_ASCII Ljava/nio/charset/Charset;
  0080 invoke-direct v0, v13, v2, v3, v5, Ljava/lang/String;-><init>([B I I Ljava/nio/charset/Charset;)V
  0086 invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  008c move-result v13
  008e if-eqz v13, +05dh
  0092 iget-object v13, v12, Lcom/personal/aihub/CpkArchive$Table;->b [B
  0096 invoke-static v13, Ljava/nio/ByteBuffer;->wrap([B)Ljava/nio/ByteBuffer;
  009c move-result-object v13
  009e sget-object v0, Ljava/nio/ByteOrder;->BIG_ENDIAN Ljava/nio/ByteOrder;
  00a2 invoke-virtual v13, v0, Ljava/nio/ByteBuffer;->order(Ljava/nio/ByteOrder;)Ljava/nio/ByteBuffer;
  00a8 move-result-object v13
  00aa iput-object v13, v12, Lcom/personal/aihub/CpkArchive$Table;->be Ljava/nio/ByteBuffer;
  00ae invoke-virtual v12, v3, Lcom/personal/aihub/CpkArchive$Table;->u32(I)J
  00b4 move-result-wide v0
  00b6 const-wide/16 v2, 8
  00ba add-long/2addr v0, v2
  00bc iget-object v13, v12, Lcom/personal/aihub/CpkArchive$Table;->b [B
  00c0 array-length v13, v13
  00c2 int-to-long v9, v13
  00c4 const-string v11, "UTF table"
  00c8 const-wide/16 v5, 0
  00cc move-wide v7, v0
  00ce invoke-static/range v5 ... v11, Lcom/personal/aihub/CpkArchive;->range(J J J Ljava/lang/String;)V
  00d4 long-to-int v13, v0
  00d6 iput v13, v12, Lcom/personal/aihub/CpkArchive$Table;->length I
  00da const/16 v0, 8
  00de invoke-virtual v12, v0, Lcom/personal/aihub/CpkArchive$Table;->u32(I)J
  00e4 move-result-wide v0
  00e6 add-long/2addr v0, v2
  00e8 invoke-virtual v12, v0, v1, Lcom/personal/aihub/CpkArchive$Table;->position(J)I
  00ee move-result v0
  00f0 iput v0, v12, Lcom/personal/aihub/CpkArchive$Table;->rows I
  00f4 const/16 v1, 12
  00f8 invoke-virtual v12, v1, Lcom/personal/aihub/CpkArchive$Table;->u32(I)J
  00fe move-result-wide v5
  0100 add-long/2addr v5, v2
  0102 invoke-virtual v12, v5, v6, Lcom/personal/aihub/CpkArchive$Table;->position(J)I
  0108 move-result v1
  010a iput v1, v12, Lcom/personal/aihub/CpkArchive$Table;->strings I
  010e const/16 v5, 16
  0112 invoke-virtual v12, v5, Lcom/personal/aihub/CpkArchive$Table;->u32(I)J
  0118 move-result-wide v5
  011a add-long/2addr v5, v2
  011c invoke-virtual v12, v5, v6, Lcom/personal/aihub/CpkArchive$Table;->position(J)I
  0122 move-result v2
  0124 iput v2, v12, Lcom/personal/aihub/CpkArchive$Table;->data I
  0128 if-lt v0, v4, +009h
  012c if-lt v1, v0, +007h
  0130 if-lt v2, v1, +005h
  0134 if-gt v2, v13, +003h
  0138 return-void 
  013a const-string v13, "Invalid table layout"
  013e invoke-static v13, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  0144 move-result-object v13
  0146 throw v13
  0148 const-string v13, "Unsupported table signature"
  014c invoke-static v13, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  0152 move-result-object v13
  0154 throw v13
.end method

.method position(J)I
  0000 const-wide/32 v0, 2147483647
  0006 cmp-long v0, v3, v0
  000a if-gtz v0, +004h
  000e long-to-int v3, v3
  0010 return v3
  0012 const-string v3, "Invalid UTF position"
  0016 invoke-static v3, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  001c move-result-object v3
  001e throw v3
.end method

.method string(J)Ljava/lang/String;
  0000 iget v0, v9, Lcom/personal/aihub/CpkArchive$Table;->strings I
  0004 int-to-long v0, v0
  0006 add-long/2addr v0, v10
  0008 iget v10, v9, Lcom/personal/aihub/CpkArchive$Table;->data I
  000c int-to-long v6, v10
  000e const-string v8, "UTF string"
  0012 const-wide/16 v4, 1
  0016 move-wide v2, v0
  0018 invoke-static/range v2 ... v8, Lcom/personal/aihub/CpkArchive;->range(J J J Ljava/lang/String;)V
  001e long-to-int v10, v0
  0020 move v11, v10
  0022 iget v0, v9, Lcom/personal/aihub/CpkArchive$Table;->data I
  0026 if-ge v11, v0, +00bh
  002a iget-object v1, v9, Lcom/personal/aihub/CpkArchive$Table;->b [B
  002e aget-byte v1, v1, v11
  0032 if-eqz v1, +005h
  0036 add-int/lit8 v11, v11, 1
  003a goto -ch
  003c if-eq v11, v0, +03fh
  0040 const-string v0, "UTF-8"
  0044 const-string v1, "Shift_JIS"
  0048 filled-new-array v0, v1, [Ljava/lang/String;
  004e move-result-object v0
  0050 const/4 v1, 0
  0052 const/4 v2, 2
  0054 if-ge v1, v2, +02ch
  0058 aget-object v2, v0, v1
  005c invoke-static v2, Ljava/nio/charset/Charset;->forName(Ljava/lang/String;)Ljava/nio/charset/Charset;
  0062 move-result-object v2
  0064 invoke-virtual v2, Ljava/nio/charset/Charset;->newDecoder()Ljava/nio/charset/CharsetDecoder;
  006a move-result-object v2
  006c sget-object v3, Ljava/nio/charset/CodingErrorAction;->REPORT Ljava/nio/charset/CodingErrorAction;
  0070 invoke-virtual v2, v3, Ljava/nio/charset/CharsetDecoder;->onMalformedInput(Ljava/nio/charset/CodingErrorAction;)Ljava/nio/charset/CharsetDecoder;
  0076 move-result-object v2
  0078 sget-object v3, Ljava/nio/charset/CodingErrorAction;->REPORT Ljava/nio/charset/CodingErrorAction;
  007c invoke-virtual v2, v3, Ljava/nio/charset/CharsetDecoder;->onUnmappableCharacter(Ljava/nio/charset/CodingErrorAction;)Ljava/nio/charset/CharsetDecoder;
  0082 move-result-object v2
  0084 iget-object v3, v9, Lcom/personal/aihub/CpkArchive$Table;->b [B
  0088 sub-int v4, v11, v10
  008c invoke-static v3, v10, v4, Ljava/nio/ByteBuffer;->wrap([B I I)Ljava/nio/ByteBuffer;
  0092 move-result-object v3
  0094 invoke-virtual v2, v3, Ljava/nio/charset/CharsetDecoder;->decode(Ljava/nio/ByteBuffer;)Ljava/nio/CharBuffer;
  009a move-result-object v2
  009c invoke-virtual v2, Ljava/nio/CharBuffer;->toString()Ljava/lang/String;
  00a2 move-result-object v10
  00a4 return-object v10
  00a6 add-int/lit8 v1, v1, 1
  00aa goto -2ch
  00ac const-string v10, "Unsupported filename encoding"
  00b0 invoke-static v10, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  00b6 move-result-object v10
  00b8 throw v10
  00ba const-string v10, "Unterminated UTF string"
  00be invoke-static v10, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  00c4 move-result-object v10
  00c6 throw v10
.end method

.method u32(I)J
  0000 int-to-long v0, v8
  0002 iget-object v2, v7, Lcom/personal/aihub/CpkArchive$Table;->b [B
  0006 array-length v2, v2
  0008 int-to-long v4, v2
  000a const-string v6, "UTF number"
  000e const-wide/16 v2, 4
  0012 invoke-static/range v0 ... v6, Lcom/personal/aihub/CpkArchive;->range(J J J Ljava/lang/String;)V
  0018 iget-object v0, v7, Lcom/personal/aihub/CpkArchive$Table;->be Ljava/nio/ByteBuffer;
  001c invoke-virtual v0, v8, Ljava/nio/ByteBuffer;->getInt(I)I
  0022 move-result v8
  0024 int-to-long v0, v8
  0026 const-wide v2, 4294967295
  0030 and-long/2addr v0, v2
  0032 return-wide v0
.end method

.method value(I I I)Ljava/lang/Object;
  0000 const/16 v0, 12
  0004 new-array v1, v0, [I
  0008 fill-array-data v1, +00000f6h
  000e if-ge v12, v0, +0cfh
  0012 int-to-long v2, v13
  0014 aget v0, v1, v12
  0018 int-to-long v4, v0
  001a int-to-long v6, v14
  001c const-string v8, "UTF value"
  0020 invoke-static/range v2 ... v8, Lcom/personal/aihub/CpkArchive;->range(J J J Ljava/lang/String;)V
  0026 packed-switch v12, +00000cbh
  002c const-string v12, "Unsupported UTF type"
  0030 invoke-static v12, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  0036 move-result-object v12
  0038 throw v12
  003a iget v12, v11, Lcom/personal/aihub/CpkArchive$Table;->data I
  003e int-to-long v0, v12
  0040 invoke-virtual v11, v13, Lcom/personal/aihub/CpkArchive$Table;->u32(I)J
  0046 move-result-wide v2
  0048 add-long/2addr v0, v2
  004a add-int/lit8 v13, v13, 4
  004e invoke-virtual v11, v13, Lcom/personal/aihub/CpkArchive$Table;->u32(I)J
  0054 move-result-wide v12
  0056 iget v14, v11, Lcom/personal/aihub/CpkArchive$Table;->length I
  005a int-to-long v8, v14
  005c const-string v10, "UTF byte data"
  0060 move-wide v4, v0
  0062 move-wide v6, v12
  0064 invoke-static/range v4 ... v10, Lcom/personal/aihub/CpkArchive;->range(J J J Ljava/lang/String;)V
  006a iget-object v14, v11, Lcom/personal/aihub/CpkArchive$Table;->b [B
  006e long-to-int v2, v0
  0070 add-long/2addr v0, v12
  0072 long-to-int v12, v0
  0074 invoke-static v14, v2, v12, Ljava/util/Arrays;->copyOfRange([B I I)[B
  007a move-result-object v12
  007c return-object v12
  007e invoke-virtual v11, v13, Lcom/personal/aihub/CpkArchive$Table;->u32(I)J
  0084 move-result-wide v12
  0086 invoke-virtual v11, v12, v13, Lcom/personal/aihub/CpkArchive$Table;->string(J)Ljava/lang/String;
  008c move-result-object v12
  008e return-object v12
  0090 iget-object v12, v11, Lcom/personal/aihub/CpkArchive$Table;->be Ljava/nio/ByteBuffer;
  0094 invoke-virtual v12, v13, Ljava/nio/ByteBuffer;->getDouble(I)D
  009a move-result-wide v12
  009c invoke-static v12, v13, Ljava/lang/Double;->valueOf(D)Ljava/lang/Double;
  00a2 move-result-object v12
  00a4 return-object v12
  00a6 iget-object v12, v11, Lcom/personal/aihub/CpkArchive$Table;->be Ljava/nio/ByteBuffer;
  00aa invoke-virtual v12, v13, Ljava/nio/ByteBuffer;->getFloat(I)F
  00b0 move-result v12
  00b2 float-to-double v12, v12
  00b4 invoke-static v12, v13, Ljava/lang/Double;->valueOf(D)Ljava/lang/Double;
  00ba move-result-object v12
  00bc return-object v12
  00be iget-object v12, v11, Lcom/personal/aihub/CpkArchive$Table;->be Ljava/nio/ByteBuffer;
  00c2 invoke-virtual v12, v13, Ljava/nio/ByteBuffer;->getLong(I)J
  00c8 move-result-wide v12
  00ca const-wide v0, -9007199254740991
  00d4 cmp-long v14, v12, v0
  00d8 if-ltz v14, +010h
  00dc const-wide v0, 9007199254740991
  00e6 cmp-long v14, v12, v0
  00ea if-gtz v14, +007h
  00ee invoke-static v12, v13, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  00f4 move-result-object v12
  00f6 return-object v12
  00f8 const-string v12, "64-bit value exceeds safe range"
  00fc invoke-static v12, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  0102 move-result-object v12
  0104 throw v12
  0106 iget-object v12, v11, Lcom/personal/aihub/CpkArchive$Table;->b [B
  010a const/4 v14, 0
  010c invoke-static v12, v13, v14, Lcom/personal/aihub/CpkArchive;->u64([B I Z)J
  0112 move-result-wide v12
  0114 invoke-static v12, v13, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  011a move-result-object v12
  011c return-object v12
  011e iget-object v12, v11, Lcom/personal/aihub/CpkArchive$Table;->be Ljava/nio/ByteBuffer;
  0122 invoke-virtual v12, v13, Ljava/nio/ByteBuffer;->getInt(I)I
  0128 move-result v12
  012a int-to-long v12, v12
  012c invoke-static v12, v13, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  0132 move-result-object v12
  0134 return-object v12
  0136 invoke-virtual v11, v13, Lcom/personal/aihub/CpkArchive$Table;->u32(I)J
  013c move-result-wide v12
  013e invoke-static v12, v13, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  0144 move-result-object v12
  0146 return-object v12
  0148 iget-object v12, v11, Lcom/personal/aihub/CpkArchive$Table;->be Ljava/nio/ByteBuffer;
  014c invoke-virtual v12, v13, Ljava/nio/ByteBuffer;->getShort(I)S
  0152 move-result v12
  0154 int-to-long v12, v12
  0156 invoke-static v12, v13, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  015c move-result-object v12
  015e return-object v12
  0160 iget-object v12, v11, Lcom/personal/aihub/CpkArchive$Table;->be Ljava/nio/ByteBuffer;
  0164 invoke-virtual v12, v13, Ljava/nio/ByteBuffer;->getShort(I)S
  016a move-result v12
  016c const v13, 65535
  0172 and-int/2addr v12, v13
  0174 int-to-long v12, v12
  0176 invoke-static v12, v13, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  017c move-result-object v12
  017e return-object v12
  0180 iget-object v12, v11, Lcom/personal/aihub/CpkArchive$Table;->b [B
  0184 aget-byte v12, v12, v13
  0188 int-to-long v12, v12
  018a invoke-static v12, v13, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  0190 move-result-object v12
  0192 return-object v12
  0194 iget-object v12, v11, Lcom/personal/aihub/CpkArchive$Table;->b [B
  0198 aget-byte v12, v12, v13
  019c and-int/lit16 v12, v12, 255
  01a0 int-to-long v12, v12
  01a2 invoke-static v12, v13, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  01a8 move-result-object v12
  01aa return-object v12
  01ac const-string v12, "Unsupported UTF column type"
  01b0 invoke-static v12, Lcom/personal/aihub/CpkArchive;->error(Ljava/lang/String;)Ljava/io/IOException;
  01b6 move-result-object v12
  01b8 throw v12
  01ba nop 
  01bc packed-switch-payload 0 1 2 3 4 5 6 7 8 9 a b
  01f4 fill-array-data-payload b'\x01\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00\x02\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00\x08\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00' | \x01\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00\x02\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00\x08\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00
.end method