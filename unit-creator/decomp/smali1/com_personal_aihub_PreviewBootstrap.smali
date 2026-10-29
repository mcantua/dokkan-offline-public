.class Lcom/personal/aihub/PreviewBootstrap;
.super Ljava/lang/Object;
.field MAX_CHUNK_UNITS I
.field MAX_REQUEST_BYTES I
.field SEQUENCE Ljava/util/concurrent/atomic/AtomicLong;
.field STATE Ljava/lang/String;
.field chunks Ljava/util/List;
.field documentId Ljava/lang/String;
.field generation J
.field nonce Ljava/lang/String;
.field requestBytes I
.field requestUnits I

.method <clinit>()V
  0000 new-instance v0, Ljava/util/concurrent/atomic/AtomicLong;
  0004 invoke-direct v0, Ljava/util/concurrent/atomic/AtomicLong;-><init>()V
  000a sput-object v0, Lcom/personal/aihub/PreviewBootstrap;->SEQUENCE Ljava/util/concurrent/atomic/AtomicLong;
  000e return-void 
.end method

.method <init>(Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)V
  0000 invoke-direct v4, Ljava/lang/Object;-><init>()V
  0006 const-string v0, "session nonce"
  000a invoke-static v5, v0, Lcom/personal/aihub/PreviewBootstrap;->identifier(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0010 move-result-object v5
  0012 iput-object v5, v4, Lcom/personal/aihub/PreviewBootstrap;->nonce Ljava/lang/String;
  0016 const-string v5, "document identifier"
  001a invoke-static v6, v5, Lcom/personal/aihub/PreviewBootstrap;->identifier(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0020 move-result-object v5
  0022 iput-object v5, v4, Lcom/personal/aihub/PreviewBootstrap;->documentId Ljava/lang/String;
  0026 if-eqz v7, +0d7h
  002a invoke-virtual v7, Ljava/lang/String;->isEmpty()Z
  0030 move-result v5
  0032 if-nez v5, +0d1h
  0036 invoke-virtual v7, Ljava/lang/String;->length()I
  003c move-result v5
  003e const/high16 v6, 3145728
  0042 if-gt v5, v6, +0c9h
  0046 const/4 v5, 0
  0048 move v0, v5
  004a invoke-virtual v7, Ljava/lang/String;->length()I
  0050 move-result v1
  0052 if-ge v0, v1, +036h
  0056 invoke-virtual v7, v0, Ljava/lang/String;->charAt(I)C
  005c move-result v1
  005e invoke-static v1, Ljava/lang/Character;->isHighSurrogate(C)Z
  0064 move-result v2
  0066 const-string v3, "Preview request contains an incomplete Unicode character."
  006a if-eqz v2, +01bh
  006e add-int/lit8 v0, v0, 1
  0072 invoke-virtual v7, Ljava/lang/String;->length()I
  0078 move-result v1
  007a if-ge v0, v1, +00dh
  007e invoke-virtual v7, v0, Ljava/lang/String;->charAt(I)C
  0084 move-result v1
  0086 invoke-static v1, Ljava/lang/Character;->isLowSurrogate(C)Z
  008c move-result v1
  008e if-eqz v1, +003h
  0092 goto +dh
  0094 new-instance v5, Ljava/lang/IllegalArgumentException;
  0098 invoke-direct v5, v3, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V
  009e throw v5
  00a0 invoke-static v1, Ljava/lang/Character;->isLowSurrogate(C)Z
  00a6 move-result v1
  00a8 if-nez v1, +005h
  00ac add-int/lit8 v0, v0, 1
  00b0 goto -33h
  00b2 new-instance v5, Ljava/lang/IllegalArgumentException;
  00b6 invoke-direct v5, v3, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V
  00bc throw v5
  00be sget-object v0, Ljava/nio/charset/StandardCharsets;->UTF_8 Ljava/nio/charset/Charset;
  00c2 invoke-virtual v7, v0, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B
  00c8 move-result-object v0
  00ca array-length v0, v0
  00cc iput v0, v4, Lcom/personal/aihub/PreviewBootstrap;->requestBytes I
  00d0 invoke-virtual v7, Ljava/lang/String;->length()I
  00d6 move-result v1
  00d8 iput v1, v4, Lcom/personal/aihub/PreviewBootstrap;->requestUnits I
  00dc if-gt v0, v6, +074h
  00e0 new-instance v6, Lorg/json/JSONObject;
  00e4 invoke-direct v6, v7, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V
  00ea new-instance v6, Ljava/util/ArrayList;
  00ee invoke-direct v6, Ljava/util/ArrayList;-><init>()V
  00f4 invoke-virtual v7, Ljava/lang/String;->length()I
  00fa move-result v0
  00fc if-ge v5, v0, +035h
  0100 const v0, 48000
  0106 add-int/2addr v0, v5
  0108 invoke-virtual v7, Ljava/lang/String;->length()I
  010e move-result v1
  0110 invoke-static v0, v1, Ljava/lang/Math;->min(I I)I
  0116 move-result v0
  0118 invoke-virtual v7, Ljava/lang/String;->length()I
  011e move-result v1
  0120 if-ge v0, v1, +01ah
  0124 add-int/lit8 v1, v0, -1
  0128 invoke-virtual v7, v1, Ljava/lang/String;->charAt(I)C
  012e move-result v1
  0130 invoke-static v1, Ljava/lang/Character;->isHighSurrogate(C)Z
  0136 move-result v1
  0138 if-eqz v1, +00eh
  013c invoke-virtual v7, v0, Ljava/lang/String;->charAt(I)C
  0142 move-result v1
  0144 invoke-static v1, Ljava/lang/Character;->isLowSurrogate(C)Z
  014a move-result v1
  014c if-eqz v1, +004h
  0150 add-int/lit8 v0, v0, -1
  0154 invoke-virtual v7, v5, v0, Ljava/lang/String;->substring(I I)Ljava/lang/String;
  015a move-result-object v5
  015c invoke-virtual v6, v5, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0162 move v5, v0
  0164 goto -38h
  0166 invoke-static v6, Ljava/util/Collections;->unmodifiableList(Ljava/util/List;)Ljava/util/List;
  016c move-result-object v5
  016e iput-object v5, v4, Lcom/personal/aihub/PreviewBootstrap;->chunks Ljava/util/List;
  0172 sget-object v5, Lcom/personal/aihub/PreviewBootstrap;->SEQUENCE Ljava/util/concurrent/atomic/AtomicLong;
  0176 invoke-virtual v5, Ljava/util/concurrent/atomic/AtomicLong;->incrementAndGet()J
  017c move-result-wide v5
  017e iput-wide v5, v4, Lcom/personal/aihub/PreviewBootstrap;->generation J
  0182 const-wide/16 v0, 1
  0186 cmp-long v7, v5, v0
  018a if-ltz v7, +00ch
  018e const-wide v0, 9007199254740991
  0198 cmp-long v5, v5, v0
  019c if-gtz v5, +003h
  01a0 return-void 
  01a2 new-instance v5, Ljava/lang/IllegalStateException;
  01a6 const-string v6, "Preview session sequence exhausted."
  01aa invoke-direct v5, v6, Ljava/lang/IllegalStateException;-><init>(Ljava/lang/String;)V
  01b0 throw v5
  01b2 move-exception v5
  01b4 new-instance v6, Ljava/lang/IllegalArgumentException;
  01b8 const-string v7, "Preview request must be a JSON object."
  01bc invoke-direct v6, v7, v5, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String; Ljava/lang/Throwable;)V
  01c2 throw v6
  01c4 new-instance v5, Ljava/lang/IllegalArgumentException;
  01c8 const-string v6, "Preview request exceeds 3 MiB of UTF-8."
  01cc invoke-direct v5, v6, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V
  01d2 throw v5
  01d4 new-instance v5, Ljava/lang/IllegalArgumentException;
  01d8 const-string v6, "Preview request exceeds its transport bounds."
  01dc invoke-direct v5, v6, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V
  01e2 throw v5
.end method

.method documentGuard()Ljava/lang/String;
  0000 new-instance v0, Ljava/lang/StringBuilder;
  0004 const-string v1, "if(window.__forgeNativeDocumentId!=="
  0008 invoke-direct v0, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  000e iget-object v1, v2, Lcom/personal/aihub/PreviewBootstrap;->documentId Ljava/lang/String;
  0012 invoke-static v1, Lcom/personal/aihub/PreviewBootstrap;->quote(Ljava/lang/String;)Ljava/lang/String;
  0018 move-result-object v1
  001a invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0020 const-string v1, ")return false;"
  0024 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  002a invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0030 move-result-object v0
  0032 return-object v0
.end method

.method identifier(Ljava/lang/String; Ljava/lang/String;)Ljava/lang/String;
  0000 if-eqz v2, +00bh
  0004 const-string v0, "[A-Za-z0-9_-]{16,128}"
  0008 invoke-virtual v2, v0, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  000e move-result v0
  0010 if-eqz v0, +003h
  0014 return-object v2
  0016 new-instance v2, Ljava/lang/IllegalArgumentException;
  001a new-instance v0, Ljava/lang/StringBuilder;
  001e const-string v1, "Invalid preview "
  0022 invoke-direct v0, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0028 invoke-virtual v0, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  002e const-string v3, "."
  0032 invoke-virtual v0, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0038 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  003e move-result-object v3
  0040 invoke-direct v2, v3, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V
  0046 throw v2
.end method

.method quote(Ljava/lang/String;)Ljava/lang/String;
  0000 invoke-static v2, Lorg/json/JSONObject;->quote(Ljava/lang/String;)Ljava/lang/String;
  0006 move-result-object v2
  0008 const-string v0, " "
  000c const-string v1, "\u2028"
  0010 invoke-virtual v2, v0, v1, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  0016 move-result-object v2
  0018 const-string v0, " "
  001c const-string v1, "\u2029"
  0020 invoke-virtual v2, v0, v1, Ljava/lang/String;->replace(Ljava/lang/CharSequence; Ljava/lang/CharSequence;)Ljava/lang/String;
  0026 move-result-object v2
  0028 return-object v2
.end method

.method sessionGuard()Ljava/lang/String;
  0000 new-instance v0, Ljava/lang/StringBuilder;
  0004 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  000a invoke-direct v3, Lcom/personal/aihub/PreviewBootstrap;->documentGuard()Ljava/lang/String;
  0010 move-result-object v1
  0012 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0018 const-string v1, "var s=window.__forgePreviewBootstrap;if(!s||s.generation!=="
  001c invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0022 iget-wide v1, v3, Lcom/personal/aihub/PreviewBootstrap;->generation J
  0026 invoke-virtual v0, v1, v2, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  002c const-string v1, "||s.nonce!=="
  0030 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0036 iget-object v1, v3, Lcom/personal/aihub/PreviewBootstrap;->nonce Ljava/lang/String;
  003a invoke-static v1, Lcom/personal/aihub/PreviewBootstrap;->quote(Ljava/lang/String;)Ljava/lang/String;
  0040 move-result-object v1
  0042 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0048 const-string v1, "||s.phase!=='pending')return false;"
  004c invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0052 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0058 move-result-object v0
  005a return-object v0
.end method

.method beginScript()Ljava/lang/String;
  0000 new-instance v0, Ljava/lang/StringBuilder;
  0004 const-string v1, "(function(){"
  0008 invoke-direct v0, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  000e invoke-direct v3, Lcom/personal/aihub/PreviewBootstrap;->documentGuard()Ljava/lang/String;
  0014 move-result-object v1
  0016 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  001c const-string v1, "var old=window.__forgePreviewBootstrap;if(old&&(old.mounted||old.generation>="
  0020 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0026 iget-wide v1, v3, Lcom/personal/aihub/PreviewBootstrap;->generation J
  002a invoke-virtual v0, v1, v2, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0030 const-string v1, "))return false;window.__forgePreviewBootstrap={generation:"
  0034 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  003a iget-wide v1, v3, Lcom/personal/aihub/PreviewBootstrap;->generation J
  003e invoke-virtual v0, v1, v2, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;
  0044 const-string v1, ",nonce:"
  0048 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  004e iget-object v1, v3, Lcom/personal/aihub/PreviewBootstrap;->nonce Ljava/lang/String;
  0052 invoke-static v1, Lcom/personal/aihub/PreviewBootstrap;->quote(Ljava/lang/String;)Ljava/lang/String;
  0058 move-result-object v1
  005a invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0060 const-string v1, ",phase:'pending',mounted:false,next:0,bytes:0,units:0,chunks:[]};return true;})()"
  0064 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  006a invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0070 move-result-object v0
  0072 return-object v0
.end method

.method cancelScript()Ljava/lang/String;
  0000 new-instance v0, Ljava/lang/StringBuilder;
  0004 const-string v1, "(function(){"
  0008 invoke-direct v0, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  000e invoke-direct v2, Lcom/personal/aihub/PreviewBootstrap;->sessionGuard()Ljava/lang/String;
  0014 move-result-object v1
  0016 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  001c const-string v1, "delete s.chunks;s.phase='canceled';return true;})()"
  0020 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0026 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  002c move-result-object v0
  002e return-object v0
.end method

.method chunkCount()I
  0000 iget-object v0, v1, Lcom/personal/aihub/PreviewBootstrap;->chunks Ljava/util/List;
  0004 invoke-interface v0, Ljava/util/List;->size()I
  000a move-result v0
  000c return v0
.end method

.method chunkScript(I)Ljava/lang/String;
  0000 iget-object v0, v3, Lcom/personal/aihub/PreviewBootstrap;->chunks Ljava/util/List;
  0004 invoke-interface v0, v4, Ljava/util/List;->get(I)Ljava/lang/Object;
  000a move-result-object v0
  000c check-cast v0, Ljava/lang/String;
  0010 new-instance v1, Ljava/lang/StringBuilder;
  0014 const-string v2, "(function(){"
  0018 invoke-direct v1, v2, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  001e invoke-direct v3, Lcom/personal/aihub/PreviewBootstrap;->sessionGuard()Ljava/lang/String;
  0024 move-result-object v2
  0026 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  002c const-string v2, "if(s.next!=="
  0030 invoke-virtual v1, v2, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0036 invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  003c const-string v4, ")return false;var text="
  0040 invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0046 invoke-static v0, Lcom/personal/aihub/PreviewBootstrap;->quote(Ljava/lang/String;)Ljava/lang/String;
  004c move-result-object v4
  004e invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0054 const-string v4, ";var bytes=new TextEncoder().encode(text).length;if(text.length>48000||s.units+text.length>"
  0058 invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  005e iget v4, v3, Lcom/personal/aihub/PreviewBootstrap;->requestUnits I
  0062 invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  0068 const-string v4, "||s.bytes+bytes>"
  006c invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0072 iget v4, v3, Lcom/personal/aihub/PreviewBootstrap;->requestBytes I
  0076 invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  007c const-string v4, "||s.bytes+bytes>3145728){delete s.chunks;s.phase='canceled';return false;}s.chunks.push(text);s.next++;s.units+=text.length;s.bytes+=bytes;return true;})()"
  0080 invoke-virtual v1, v4, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0086 invoke-virtual v1, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  008c move-result-object v4
  008e return-object v4
.end method

.method chunkScripts()Ljava/util/List;
  0000 new-instance v0, Ljava/util/ArrayList;
  0004 iget-object v1, v3, Lcom/personal/aihub/PreviewBootstrap;->chunks Ljava/util/List;
  0008 invoke-interface v1, Ljava/util/List;->size()I
  000e move-result v1
  0010 invoke-direct v0, v1, Ljava/util/ArrayList;-><init>(I)V
  0016 const/4 v1, 0
  0018 iget-object v2, v3, Lcom/personal/aihub/PreviewBootstrap;->chunks Ljava/util/List;
  001c invoke-interface v2, Ljava/util/List;->size()I
  0022 move-result v2
  0024 if-ge v1, v2, +00ch
  0028 invoke-virtual v3, v1, Lcom/personal/aihub/PreviewBootstrap;->chunkScript(I)Ljava/lang/String;
  002e move-result-object v2
  0030 invoke-virtual v0, v2, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0036 add-int/lit8 v1, v1, 1
  003a goto -11h
  003c invoke-static v0, Ljava/util/Collections;->unmodifiableList(Ljava/util/List;)Ljava/util/List;
  0042 move-result-object v0
  0044 return-object v0
.end method

.method documentId()Ljava/lang/String;
  0000 iget-object v0, v1, Lcom/personal/aihub/PreviewBootstrap;->documentId Ljava/lang/String;
  0004 return-object v0
.end method

.method mountScript(Ljava/lang/String;)Ljava/lang/String;
  0000 if-eqz v3, +04ah
  0004 invoke-virtual v3, Ljava/lang/String;->isEmpty()Z
  000a move-result v0
  000c if-nez v0, +044h
  0010 new-instance v0, Ljava/lang/StringBuilder;
  0014 const-string v1, "(function(){"
  0018 invoke-direct v0, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  001e invoke-direct v2, Lcom/personal/aihub/PreviewBootstrap;->sessionGuard()Ljava/lang/String;
  0024 move-result-object v1
  0026 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  002c const-string v1, "if(s.next!=="
  0030 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0036 iget-object v1, v2, Lcom/personal/aihub/PreviewBootstrap;->chunks Ljava/util/List;
  003a invoke-interface v1, Ljava/util/List;->size()I
  0040 move-result v1
  0042 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  0048 const-string v1, "||s.units!=="
  004c invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0052 iget v1, v2, Lcom/personal/aihub/PreviewBootstrap;->requestUnits I
  0056 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  005c const-string v1, "||s.bytes!=="
  0060 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0066 iget v1, v2, Lcom/personal/aihub/PreviewBootstrap;->requestBytes I
  006a invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
  0070 const-string v1, ")return false;var request;try{request=JSON.parse(s.chunks.join(''));}catch(error){delete s.chunks;s.phase='canceled';return false;}delete s.chunks;s.phase='mounted';s.mounted=true;window.__forgeAnimation=request;(function(){
"
  0074 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  007a invoke-virtual v0, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0080 const-string v3, "
}).call(window);return true;})()"
  0084 invoke-virtual v0, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  008a invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0090 move-result-object v3
  0092 return-object v3
  0094 new-instance v3, Ljava/lang/IllegalArgumentException;
  0098 const-string v0, "Preview page script is required."
  009c invoke-direct v3, v0, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V
  00a2 throw v3
.end method

.method nonce()Ljava/lang/String;
  0000 iget-object v0, v1, Lcom/personal/aihub/PreviewBootstrap;->nonce Ljava/lang/String;
  0004 return-object v0
.end method

.method requestBytes()I
  0000 iget v0, v1, Lcom/personal/aihub/PreviewBootstrap;->requestBytes I
  0004 return v0
.end method