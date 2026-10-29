.class Lcom/personal/aihub/PatchProvider;
.super Landroid/content/ContentProvider;

.method <init>()V
  0000 invoke-direct v0, Landroid/content/ContentProvider;-><init>()V
  0006 return-void 
.end method

.method file(Landroid/net/Uri;)Ljava/io/File;
  0000 new-instance v0, Ljava/lang/StringBuilder;
  0004 invoke-direct v0, Ljava/lang/StringBuilder;-><init>()V
  000a invoke-virtual v7, Lcom/personal/aihub/PatchProvider;->getContext()Landroid/content/Context;
  0010 move-result-object v1
  0012 invoke-virtual v1, Landroid/content/Context;->getPackageName()Ljava/lang/String;
  0018 move-result-object v1
  001a invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0020 const-string v1, ".patch"
  0024 invoke-virtual v0, v1, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  002a invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0030 move-result-object v0
  0032 invoke-virtual v8, Landroid/net/Uri;->getAuthority()Ljava/lang/String;
  0038 move-result-object v1
  003a invoke-virtual v0, v1, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0040 move-result v0
  0042 if-eqz v0, +05ch
  0046 invoke-virtual v8, Landroid/net/Uri;->getPathSegments()Ljava/util/List;
  004c move-result-object v0
  004e invoke-interface v0, Ljava/util/List;->size()I
  0054 move-result v0
  0056 const/4 v1, 2
  0058 if-ne v0, v1, +051h
  005c invoke-virtual v8, Landroid/net/Uri;->getPathSegments()Ljava/util/List;
  0062 move-result-object v0
  0064 const/4 v1, 0
  0066 invoke-interface v0, v1, Ljava/util/List;->get(I)Ljava/lang/Object;
  006c move-result-object v0
  006e check-cast v0, Ljava/lang/String;
  0072 const-string v2, "[a-f0-9-]{36}"
  0076 invoke-virtual v0, v2, Ljava/lang/String;->matches(Ljava/lang/String;)Z
  007c move-result v0
  007e if-eqz v0, +03eh
  0082 invoke-virtual v8, Landroid/net/Uri;->getLastPathSegment()Ljava/lang/String;
  0088 move-result-object v0
  008a const-string v2, "unit-patch.zip"
  008e invoke-virtual v2, v0, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0094 move-result v0
  0096 if-eqz v0, +032h
  009a new-instance v0, Ljava/io/File;
  009e new-instance v3, Ljava/io/File;
  00a2 new-instance v4, Ljava/io/File;
  00a6 invoke-virtual v7, Lcom/personal/aihub/PatchProvider;->getContext()Landroid/content/Context;
  00ac move-result-object v5
  00ae invoke-virtual v5, Landroid/content/Context;->getCacheDir()Ljava/io/File;
  00b4 move-result-object v5
  00b6 const-string v6, "converter"
  00ba invoke-direct v4, v5, v6, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00c0 invoke-virtual v8, Landroid/net/Uri;->getPathSegments()Ljava/util/List;
  00c6 move-result-object v8
  00c8 invoke-interface v8, v1, Ljava/util/List;->get(I)Ljava/lang/Object;
  00ce move-result-object v8
  00d0 check-cast v8, Ljava/lang/String;
  00d4 invoke-direct v3, v4, v8, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00da invoke-direct v0, v3, v2, Ljava/io/File;-><init>(Ljava/io/File; Ljava/lang/String;)V
  00e0 invoke-virtual v0, Ljava/io/File;->isFile()Z
  00e6 move-result v8
  00e8 if-eqz v8, +003h
  00ec return-object v0
  00ee new-instance v8, Ljava/io/FileNotFoundException;
  00f2 invoke-direct v8, Ljava/io/FileNotFoundException;-><init>()V
  00f8 throw v8
  00fa new-instance v8, Ljava/io/FileNotFoundException;
  00fe invoke-direct v8, Ljava/io/FileNotFoundException;-><init>()V
  0104 throw v8
.end method

.method delete(Landroid/net/Uri; Ljava/lang/String; [Ljava/lang/String;)I
  0000 new-instance v1, Ljava/lang/UnsupportedOperationException;
  0004 invoke-direct v1, Ljava/lang/UnsupportedOperationException;-><init>()V
  000a throw v1
.end method

.method getType(Landroid/net/Uri;)Ljava/lang/String;
  0000 const-string v1, "application/zip"
  0004 return-object v1
.end method

.method insert(Landroid/net/Uri; Landroid/content/ContentValues;)Landroid/net/Uri;
  0000 new-instance v1, Ljava/lang/UnsupportedOperationException;
  0004 invoke-direct v1, Ljava/lang/UnsupportedOperationException;-><init>()V
  000a throw v1
.end method

.method onCreate()Z
  0000 const/4 v0, 1
  0002 return v0
.end method

.method openFile(Landroid/net/Uri; Ljava/lang/String;)Landroid/os/ParcelFileDescriptor;
  0000 const-string v0, "r"
  0004 invoke-virtual v0, v3, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  000a move-result v3
  000c if-eqz v3, +00dh
  0010 invoke-direct v1, v2, Lcom/personal/aihub/PatchProvider;->file(Landroid/net/Uri;)Ljava/io/File;
  0016 move-result-object v2
  0018 const/high16 v3, 268435456
  001c invoke-static v2, v3, Landroid/os/ParcelFileDescriptor;->open(Ljava/io/File; I)Landroid/os/ParcelFileDescriptor;
  0022 move-result-object v2
  0024 return-object v2
  0026 new-instance v2, Ljava/io/FileNotFoundException;
  002a const-string v3, "Read-only patch"
  002e invoke-direct v2, v3, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
  0034 throw v2
.end method

.method query(Landroid/net/Uri; [Ljava/lang/String; Ljava/lang/String; [Ljava/lang/String; Ljava/lang/String;)Landroid/database/Cursor;
  0000 invoke-direct v4, v5, Lcom/personal/aihub/PatchProvider;->file(Landroid/net/Uri;)Ljava/io/File;
  0006 move-result-object v5
  0008 const-string v7, "_size"
  000c const-string v8, "_display_name"
  0010 if-nez v6, +006h
  0014 filled-new-array v8, v7, [Ljava/lang/String;
  001a move-result-object v6
  001c new-instance v9, Landroid/database/MatrixCursor;
  0020 invoke-direct v9, v6, Landroid/database/MatrixCursor;-><init>([Ljava/lang/String;)V
  0026 array-length v0, v6
  0028 new-array v0, v0, [Ljava/lang/Object;
  002c const/4 v1, 0
  002e array-length v2, v6
  0030 if-ge v1, v2, +026h
  0034 aget-object v2, v6, v1
  0038 invoke-virtual v8, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  003e move-result v2
  0040 if-eqz v2, +009h
  0044 invoke-virtual v5, Ljava/io/File;->getName()Ljava/lang/String;
  004a move-result-object v2
  004c aput-object v2, v0, v1
  0050 goto +13h
  0052 aget-object v2, v6, v1
  0056 invoke-virtual v7, v2, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  005c move-result v2
  005e if-eqz v2, +00ch
  0062 invoke-virtual v5, Ljava/io/File;->length()J
  0068 move-result-wide v2
  006a invoke-static v2, v3, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
  0070 move-result-object v2
  0072 aput-object v2, v0, v1
  0076 add-int/lit8 v1, v1, 1
  007a goto -26h
  007c invoke-virtual v9, v0, Landroid/database/MatrixCursor;->addRow([Ljava/lang/Object;)V
  0082 return-object v9
  0084 const/4 v5, 0
  0086 return-object v5
.end method

.method update(Landroid/net/Uri; Landroid/content/ContentValues; Ljava/lang/String; [Ljava/lang/String;)I
  0000 new-instance v1, Ljava/lang/UnsupportedOperationException;
  0004 invoke-direct v1, Ljava/lang/UnsupportedOperationException;-><init>()V
  000a throw v1
.end method