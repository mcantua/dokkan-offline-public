.class Lcom/personal/aihub/Provider;
.super Ljava/lang/Enum;
.field $VALUES [Lcom/personal/aihub/Provider;
.field CHATGPT Lcom/personal/aihub/Provider;
.field CLAUDE Lcom/personal/aihub/Provider;
.field GROK Lcom/personal/aihub/Provider;
.field color Ljava/lang/String;
.field description Ljava/lang/String;
.field label Ljava/lang/String;
.field mark Ljava/lang/String;
.field packageName Ljava/lang/String;
.field website Ljava/lang/String;

.method $values()[Lcom/personal/aihub/Provider;
  0000 sget-object v0, Lcom/personal/aihub/Provider;->CHATGPT Lcom/personal/aihub/Provider;
  0004 sget-object v1, Lcom/personal/aihub/Provider;->GROK Lcom/personal/aihub/Provider;
  0008 sget-object v2, Lcom/personal/aihub/Provider;->CLAUDE Lcom/personal/aihub/Provider;
  000c filled-new-array v0, v1, v2, [Lcom/personal/aihub/Provider;
  0012 move-result-object v0
  0014 return-object v0
.end method

.method <clinit>()V
  0000 new-instance v9, Lcom/personal/aihub/Provider;
  0004 const-string v7, "#76D8B1"
  0008 const-string v8, "G"
  000c const-string v1, "CHATGPT"
  0010 const/4 v2, 0
  0012 const-string v3, "ChatGPT"
  0016 const-string v4, "com.openai.chatgpt"
  001a const-string v5, "https://chatgpt.com/"
  001e const-string v6, "Think, create, and explore."
  0022 move-object v0, v9
  0024 invoke-direct/range v0 ... v8, Lcom/personal/aihub/Provider;-><init>(Ljava/lang/String; I Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)V
  002a sput-object v9, Lcom/personal/aihub/Provider;->CHATGPT Lcom/personal/aihub/Provider;
  002e new-instance v0, Lcom/personal/aihub/Provider;
  0032 const-string v17, "#CCD5EF"
  0036 const-string v18, "X"
  003a const-string v11, "GROK"
  003e const/4 v12, 1
  0040 const-string v13, "Grok"
  0044 const-string v14, "ai.x.grok"
  0048 const-string v15, "https://grok.com/"
  004c const-string v16, "A fresh perspective on anything."
  0050 move-object v10, v0
  0052 invoke-direct/range v10 ... v18, Lcom/personal/aihub/Provider;-><init>(Ljava/lang/String; I Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)V
  0058 sput-object v0, Lcom/personal/aihub/Provider;->GROK Lcom/personal/aihub/Provider;
  005c new-instance v0, Lcom/personal/aihub/Provider;
  0060 const-string v8, "#E9AA8D"
  0064 const-string v9, "C"
  0068 const-string v2, "CLAUDE"
  006c const/4 v3, 2
  006e const-string v4, "Claude"
  0072 const-string v5, "com.anthropic.claude"
  0076 const-string v6, "https://claude.ai/"
  007a const-string v7, "Make room for your next idea."
  007e move-object v1, v0
  0080 invoke-direct/range v1 ... v9, Lcom/personal/aihub/Provider;-><init>(Ljava/lang/String; I Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)V
  0086 sput-object v0, Lcom/personal/aihub/Provider;->CLAUDE Lcom/personal/aihub/Provider;
  008a invoke-static Lcom/personal/aihub/Provider;->$values()[Lcom/personal/aihub/Provider;
  0090 move-result-object v0
  0092 sput-object v0, Lcom/personal/aihub/Provider;->$VALUES [Lcom/personal/aihub/Provider;
  0096 return-void 
.end method

.method <init>(Ljava/lang/String; I Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String; Ljava/lang/String;)V
  0000 invoke-direct v0, v1, v2, Ljava/lang/Enum;-><init>(Ljava/lang/String; I)V
  0006 iput-object v3, v0, Lcom/personal/aihub/Provider;->label Ljava/lang/String;
  000a iput-object v4, v0, Lcom/personal/aihub/Provider;->packageName Ljava/lang/String;
  000e iput-object v5, v0, Lcom/personal/aihub/Provider;->website Ljava/lang/String;
  0012 iput-object v6, v0, Lcom/personal/aihub/Provider;->description Ljava/lang/String;
  0016 iput-object v7, v0, Lcom/personal/aihub/Provider;->color Ljava/lang/String;
  001a iput-object v8, v0, Lcom/personal/aihub/Provider;->mark Ljava/lang/String;
  001e return-void 
.end method

.method valueOf(Ljava/lang/String;)Lcom/personal/aihub/Provider;
  0000 const-class v0, Lcom/personal/aihub/Provider;
  0004 invoke-static v0, v1, Ljava/lang/Enum;->valueOf(Ljava/lang/Class; Ljava/lang/String;)Ljava/lang/Enum;
  000a move-result-object v1
  000c check-cast v1, Lcom/personal/aihub/Provider;
  0010 return-object v1
.end method

.method values()[Lcom/personal/aihub/Provider;
  0000 sget-object v0, Lcom/personal/aihub/Provider;->$VALUES [Lcom/personal/aihub/Provider;
  0004 invoke-virtual v0, [Lcom/personal/aihub/Provider;->clone()Ljava/lang/Object;
  000a move-result-object v0
  000c check-cast v0, [Lcom/personal/aihub/Provider;
  0010 return-object v0
.end method

.method valuesCustom()[Lcom/personal/aihub/Provider;
  0000 invoke-static Lcom/personal/aihub/Provider;->values()[Lcom/personal/aihub/Provider;
  0006 move-result-object v0
  0008 array-length v1, v0
  000a new-array v2, v1, [Lcom/personal/aihub/Provider;
  000e const/4 v3, 0
  0010 invoke-static v0, v3, v2, v3, v1, Ljava/lang/System;->arraycopy(Ljava/lang/Object; I Ljava/lang/Object; I I)V
  0016 return-object v2
.end method