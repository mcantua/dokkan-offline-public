.class Lcom/personal/aihub/MainActivity;
.super Landroid/app/Activity;
.field BG I
.field LIME I
.field MUTED I
.field TEXT I
.field badges Ljava/util/List;
.field content Landroid/widget/LinearLayout;
.field preference Landroid/widget/Button;
.field prefs Landroid/content/SharedPreferences;

.method <clinit>()V
  0000 const/16 v0, 21
  0004 const/16 v1, 26
  0008 const/16 v2, 17
  000c invoke-static v2, v0, v1, Landroid/graphics/Color;->rgb(I I I)I
  0012 move-result v0
  0014 sput v0, Lcom/personal/aihub/MainActivity;->BG I
  0018 const/16 v0, 246
  001c const/16 v1, 241
  0020 const/16 v2, 244
  0024 invoke-static v2, v0, v1, Landroid/graphics/Color;->rgb(I I I)I
  002a move-result v0
  002c sput v0, Lcom/personal/aihub/MainActivity;->TEXT I
  0030 const/16 v0, 172
  0034 const/16 v1, 182
  0038 const/16 v2, 162
  003c invoke-static v2, v0, v1, Landroid/graphics/Color;->rgb(I I I)I
  0042 move-result v0
  0044 sput v0, Lcom/personal/aihub/MainActivity;->MUTED I
  0048 const/16 v0, 242
  004c const/16 v1, 114
  0050 const/16 v2, 180
  0054 invoke-static v2, v0, v1, Landroid/graphics/Color;->rgb(I I I)I
  005a move-result v0
  005c sput v0, Lcom/personal/aihub/MainActivity;->LIME I
  0060 return-void 
.end method

.method <init>()V
  0000 invoke-direct v1, Landroid/app/Activity;-><init>()V
  0006 new-instance v0, Ljava/util/ArrayList;
  000a invoke-direct v0, Ljava/util/ArrayList;-><init>()V
  0010 iput-object v0, v1, Lcom/personal/aihub/MainActivity;->badges Ljava/util/List;
  0014 return-void 
.end method

.method addProvider(Lcom/personal/aihub/Provider;)V
  0000 iget-object v0, v15, Lcom/personal/aihub/Provider;->color Ljava/lang/String;
  0004 invoke-static v0, Landroid/graphics/Color;->parseColor(Ljava/lang/String;)I
  000a move-result v0
  000c new-instance v1, Landroid/widget/LinearLayout;
  0010 invoke-direct v1, v14, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
  0016 const/4 v2, 1
  0018 invoke-virtual v1, v2, Landroid/widget/LinearLayout;->setOrientation(I)V
  001e const/16 v3, 20
  0022 invoke-direct v14, v3, Lcom/personal/aihub/MainActivity;->dp(I)I
  0028 move-result v4
  002a invoke-direct v14, v3, Lcom/personal/aihub/MainActivity;->dp(I)I
  0030 move-result v5
  0032 invoke-direct v14, v3, Lcom/personal/aihub/MainActivity;->dp(I)I
  0038 move-result v3
  003a const/16 v6, 16
  003e invoke-direct v14, v6, Lcom/personal/aihub/MainActivity;->dp(I)I
  0044 move-result v7
  0046 invoke-virtual v1, v4, v5, v3, v7, Landroid/widget/LinearLayout;->setPadding(I I I I)V
  004c const/16 v3, 26
  0050 const/16 v4, 32
  0054 const/16 v5, 39
  0058 invoke-static v3, v4, v5, Landroid/graphics/Color;->rgb(I I I)I
  005e move-result v3
  0060 const/16 v4, 62
  0064 const/16 v7, 45
  0068 const/16 v8, 53
  006c invoke-static v7, v8, v4, Landroid/graphics/Color;->rgb(I I I)I
  0072 move-result v4
  0074 const/16 v7, 22
  0078 invoke-direct v14, v3, v4, v7, Lcom/personal/aihub/MainActivity;->shape(I I I)Landroid/graphics/drawable/GradientDrawable;
  007e move-result-object v3
  0080 invoke-virtual v1, v3, Landroid/widget/LinearLayout;->setBackground(Landroid/graphics/drawable/Drawable;)V
  0086 invoke-direct v14, Lcom/personal/aihub/MainActivity;->row()Landroid/widget/LinearLayout;
  008c move-result-object v3
  008e iget-object v4, v15, Lcom/personal/aihub/Provider;->mark Ljava/lang/String;
  0092 const/16 v9, 24
  0096 invoke-direct v14, v4, v9, v0, v2, Lcom/personal/aihub/MainActivity;->text(Ljava/lang/String; I I Z)Landroid/widget/TextView;
  009c move-result-object v4
  009e const/16 v9, 17
  00a2 invoke-virtual v4, v9, Landroid/widget/TextView;->setGravity(I)V
  00a8 const/16 v9, 46
  00ac invoke-static v5, v9, v8, Landroid/graphics/Color;->rgb(I I I)I
  00b2 move-result v5
  00b4 const/4 v8, 0
  00b6 const/16 v9, 14
  00ba invoke-direct v14, v5, v8, v9, Lcom/personal/aihub/MainActivity;->shape(I I I)Landroid/graphics/drawable/GradientDrawable;
  00c0 move-result-object v5
  00c2 invoke-virtual v4, v5, Landroid/widget/TextView;->setBackground(Landroid/graphics/drawable/Drawable;)V
  00c8 new-instance v5, Landroid/widget/LinearLayout$LayoutParams;
  00cc const/16 v10, 48
  00d0 invoke-direct v14, v10, Lcom/personal/aihub/MainActivity;->dp(I)I
  00d6 move-result v11
  00d8 invoke-direct v14, v10, Lcom/personal/aihub/MainActivity;->dp(I)I
  00de move-result v12
  00e0 invoke-direct v5, v11, v12, Landroid/widget/LinearLayout$LayoutParams;-><init>(I I)V
  00e6 invoke-virtual v3, v4, v5, Landroid/widget/LinearLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  00ec new-instance v4, Landroid/widget/LinearLayout;
  00f0 invoke-direct v4, v14, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
  00f6 invoke-virtual v4, v2, Landroid/widget/LinearLayout;->setOrientation(I)V
  00fc new-instance v5, Landroid/widget/LinearLayout$LayoutParams;
  0100 const/4 v11, -2
  0102 const/high16 v12, 1065353216
  0106 invoke-direct v5, v8, v11, v12, Landroid/widget/LinearLayout$LayoutParams;-><init>(I I F)V
  010c invoke-direct v14, v9, Lcom/personal/aihub/MainActivity;->dp(I)I
  0112 move-result v13
  0114 iput v13, v5, Landroid/widget/LinearLayout$LayoutParams;->leftMargin I
  0118 invoke-virtual v3, v4, v5, Landroid/widget/LinearLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  011e iget-object v5, v15, Lcom/personal/aihub/Provider;->label Ljava/lang/String;
  0122 sget v13, Lcom/personal/aihub/MainActivity;->TEXT I
  0126 invoke-direct v14, v5, v7, v13, v2, Lcom/personal/aihub/MainActivity;->text(Ljava/lang/String; I I Z)Landroid/widget/TextView;
  012c move-result-object v5
  012e invoke-virtual v4, v5, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  0134 const-string v5, ""
  0138 const/16 v7, 10
  013c invoke-direct v14, v5, v7, v0, v2, Lcom/personal/aihub/MainActivity;->text(Ljava/lang/String; I I Z)Landroid/widget/TextView;
  0142 move-result-object v2
  0144 const v5, 1034147594
  014a invoke-virtual v2, v5, Landroid/widget/TextView;->setLetterSpacing(F)V
  0150 invoke-virtual v4, v2, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  0156 iget-object v4, v14, Lcom/personal/aihub/MainActivity;->badges Ljava/util/List;
  015a invoke-interface v4, v2, Ljava/util/List;->add(Ljava/lang/Object;)Z
  0160 invoke-virtual v1, v3, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  0166 iget-object v2, v15, Lcom/personal/aihub/Provider;->description Ljava/lang/String;
  016a sget v3, Lcom/personal/aihub/MainActivity;->MUTED I
  016e invoke-direct v14, v2, v9, v3, v8, Lcom/personal/aihub/MainActivity;->text(Ljava/lang/String; I I Z)Landroid/widget/TextView;
  0174 move-result-object v2
  0176 new-instance v4, Landroid/widget/LinearLayout$LayoutParams;
  017a const/4 v5, -1
  017c invoke-direct v4, v5, v11, Landroid/widget/LinearLayout$LayoutParams;-><init>(I I)V
  0182 invoke-direct v14, v6, Lcom/personal/aihub/MainActivity;->dp(I)I
  0188 move-result v7
  018a iput v7, v4, Landroid/widget/LinearLayout$LayoutParams;->topMargin I
  018e invoke-direct v14, v6, Lcom/personal/aihub/MainActivity;->dp(I)I
  0194 move-result v6
  0196 iput v6, v4, Landroid/widget/LinearLayout$LayoutParams;->bottomMargin I
  019a invoke-virtual v1, v2, v4, Landroid/widget/LinearLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  01a0 invoke-direct v14, Lcom/personal/aihub/MainActivity;->row()Landroid/widget/LinearLayout;
  01a6 move-result-object v2
  01a8 new-instance v4, Ljava/lang/StringBuilder;
  01ac const-string v6, "Open "
  01b0 invoke-direct v4, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  01b6 iget-object v7, v15, Lcom/personal/aihub/Provider;->label Ljava/lang/String;
  01ba invoke-virtual v4, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01c0 const-string v7, "  ↗"
  01c4 invoke-virtual v4, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01ca invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  01d0 move-result-object v4
  01d2 sget v7, Lcom/personal/aihub/MainActivity;->BG I
  01d6 invoke-direct v14, v4, v7, v0, Lcom/personal/aihub/MainActivity;->button(Ljava/lang/String; I I)Landroid/widget/Button;
  01dc move-result-object v0
  01de new-instance v4, Ljava/lang/StringBuilder;
  01e2 invoke-direct v4, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  01e8 iget-object v7, v15, Lcom/personal/aihub/Provider;->label Ljava/lang/String;
  01ec invoke-virtual v4, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01f2 const-string v7, " using your launch preference"
  01f6 invoke-virtual v4, v7, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  01fc invoke-virtual v4, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0202 move-result-object v4
  0204 invoke-virtual v0, v4, Landroid/widget/Button;->setContentDescription(Ljava/lang/CharSequence;)V
  020a new-instance v4, Lcom/personal/aihub/MainActivity$4;
  020e invoke-direct v4, v14, v15, Lcom/personal/aihub/MainActivity$4;-><init>(Lcom/personal/aihub/MainActivity; Lcom/personal/aihub/Provider;)V
  0214 invoke-virtual v0, v4, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
  021a new-instance v4, Landroid/widget/LinearLayout$LayoutParams;
  021e const/16 v7, 50
  0222 invoke-direct v14, v7, Lcom/personal/aihub/MainActivity;->dp(I)I
  0228 move-result v7
  022a invoke-direct v4, v8, v7, v12, Landroid/widget/LinearLayout$LayoutParams;-><init>(I I F)V
  0230 invoke-virtual v2, v0, v4, Landroid/widget/LinearLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  0236 invoke-virtual v1, v2, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  023c const-string v0, "Open website"
  0240 invoke-direct v14, v0, v3, v8, Lcom/personal/aihub/MainActivity;->button(Ljava/lang/String; I I)Landroid/widget/Button;
  0246 move-result-object v0
  0248 const/high16 v2, 1094713344
  024c invoke-virtual v0, v2, Landroid/widget/Button;->setTextSize(F)V
  0252 new-instance v2, Ljava/lang/StringBuilder;
  0256 invoke-direct v2, v6, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  025c iget-object v3, v15, Lcom/personal/aihub/Provider;->label Ljava/lang/String;
  0260 invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0266 const-string v3, " website in browser"
  026a invoke-virtual v2, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0270 invoke-virtual v2, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0276 move-result-object v2
  0278 invoke-virtual v0, v2, Landroid/widget/Button;->setContentDescription(Ljava/lang/CharSequence;)V
  027e new-instance v2, Lcom/personal/aihub/MainActivity$5;
  0282 invoke-direct v2, v14, v15, Lcom/personal/aihub/MainActivity$5;-><init>(Lcom/personal/aihub/MainActivity; Lcom/personal/aihub/Provider;)V
  0288 invoke-virtual v0, v2, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
  028e new-instance v15, Landroid/widget/LinearLayout$LayoutParams;
  0292 invoke-direct v14, v10, Lcom/personal/aihub/MainActivity;->dp(I)I
  0298 move-result v2
  029a invoke-direct v15, v5, v2, Landroid/widget/LinearLayout$LayoutParams;-><init>(I I)V
  02a0 const/4 v2, 4
  02a2 invoke-direct v14, v2, Lcom/personal/aihub/MainActivity;->dp(I)I
  02a8 move-result v2
  02aa iput v2, v15, Landroid/widget/LinearLayout$LayoutParams;->topMargin I
  02ae invoke-virtual v1, v0, v15, Landroid/widget/LinearLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  02b4 iget-object v15, v14, Lcom/personal/aihub/MainActivity;->content Landroid/widget/LinearLayout;
  02b8 new-instance v0, Landroid/widget/LinearLayout$LayoutParams;
  02bc invoke-direct v0, v5, v11, Landroid/widget/LinearLayout$LayoutParams;-><init>(I I)V
  02c2 invoke-virtual v15, v1, v0, Landroid/widget/LinearLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  02c8 return-void 
.end method

.method addSpace(I)V
  0000 iget-object v0, v4, Lcom/personal/aihub/MainActivity;->content Landroid/widget/LinearLayout;
  0004 new-instance v1, Landroid/view/View;
  0008 invoke-direct v1, v4, Landroid/view/View;-><init>(Landroid/content/Context;)V
  000e new-instance v2, Landroid/widget/LinearLayout$LayoutParams;
  0012 const/4 v3, 1
  0014 invoke-direct v4, v5, Lcom/personal/aihub/MainActivity;->dp(I)I
  001a move-result v5
  001c invoke-direct v2, v3, v5, Landroid/widget/LinearLayout$LayoutParams;-><init>(I I)V
  0022 invoke-virtual v0, v1, v2, Landroid/widget/LinearLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  0028 return-void 
.end method

.method blend(I)I
  0000 invoke-static v7, Landroid/graphics/Color;->red(I)I
  0006 move-result v0
  0008 int-to-double v0, v0
  000a const-wide v2, 4605380978949069210
  0014 mul-double/2addr v0, v2
  0016 double-to-int v0, v0
  0018 invoke-static v7, Landroid/graphics/Color;->green(I)I
  001e move-result v1
  0020 int-to-double v4, v1
  0022 mul-double/2addr v4, v2
  0024 double-to-int v1, v4
  0026 invoke-static v7, Landroid/graphics/Color;->blue(I)I
  002c move-result v7
  002e int-to-double v4, v7
  0030 mul-double/2addr v4, v2
  0032 double-to-int v7, v4
  0034 invoke-static v0, v1, v7, Landroid/graphics/Color;->rgb(I I I)I
  003a move-result v7
  003c return v7
.end method

.method button(Ljava/lang/String; I I)Landroid/widget/Button;
  0000 new-instance v0, Landroid/widget/Button;
  0004 invoke-direct v0, v6, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
  000a invoke-virtual v0, v7, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V
  0010 invoke-virtual v0, v8, Landroid/widget/Button;->setTextColor(I)V
  0016 const/high16 v7, 1096810496
  001a invoke-virtual v0, v7, Landroid/widget/Button;->setTextSize(F)V
  0020 const/4 v7, 0
  0022 invoke-virtual v0, v7, Landroid/widget/Button;->setAllCaps(Z)V
  0028 const-string v8, "sans-serif-medium"
  002c invoke-static v8, v7, Landroid/graphics/Typeface;->create(Ljava/lang/String; I)Landroid/graphics/Typeface;
  0032 move-result-object v8
  0034 invoke-virtual v0, v8, Landroid/widget/Button;->setTypeface(Landroid/graphics/Typeface;)V
  003a invoke-virtual v0, v7, Landroid/widget/Button;->setMinHeight(I)V
  0040 invoke-virtual v0, v7, Landroid/widget/Button;->setMinimumHeight(I)V
  0046 invoke-virtual v0, v7, Landroid/widget/Button;->setMinWidth(I)V
  004c invoke-virtual v0, v7, Landroid/widget/Button;->setMinimumWidth(I)V
  0052 const/16 v8, 12
  0056 invoke-direct v6, v8, Lcom/personal/aihub/MainActivity;->dp(I)I
  005c move-result v1
  005e const/4 v2, 5
  0060 invoke-direct v6, v2, Lcom/personal/aihub/MainActivity;->dp(I)I
  0066 move-result v3
  0068 invoke-direct v6, v8, Lcom/personal/aihub/MainActivity;->dp(I)I
  006e move-result v4
  0070 invoke-direct v6, v2, Lcom/personal/aihub/MainActivity;->dp(I)I
  0076 move-result v2
  0078 invoke-virtual v0, v1, v3, v4, v2, Landroid/widget/Button;->setPadding(I I I I)V
  007e new-instance v1, Landroid/graphics/drawable/StateListDrawable;
  0082 invoke-direct v1, Landroid/graphics/drawable/StateListDrawable;-><init>()V
  0088 const v2, 16842919
  008e filled-new-array v2, [I
  0094 move-result-object v2
  0096 if-nez v9, +00dh
  009a const/16 v3, 53
  009e const/16 v4, 62
  00a2 const/16 v5, 45
  00a6 invoke-static v5, v3, v4, Landroid/graphics/Color;->rgb(I I I)I
  00ac move-result v3
  00ae goto +5h
  00b0 invoke-direct v6, v9, Lcom/personal/aihub/MainActivity;->blend(I)I
  00b6 move-result v3
  00b8 invoke-direct v6, v3, v7, v8, Lcom/personal/aihub/MainActivity;->shape(I I I)Landroid/graphics/drawable/GradientDrawable;
  00be move-result-object v3
  00c0 invoke-virtual v1, v2, v3, Landroid/graphics/drawable/StateListDrawable;->addState([I Landroid/graphics/drawable/Drawable;)V
  00c6 new-array v2, v7, [I
  00ca invoke-direct v6, v9, v7, v8, Lcom/personal/aihub/MainActivity;->shape(I I I)Landroid/graphics/drawable/GradientDrawable;
  00d0 move-result-object v7
  00d2 invoke-virtual v1, v2, v7, Landroid/graphics/drawable/StateListDrawable;->addState([I Landroid/graphics/drawable/Drawable;)V
  00d8 invoke-virtual v0, v1, Landroid/widget/Button;->setBackground(Landroid/graphics/drawable/Drawable;)V
  00de return-object v0
.end method

.method choosePreference()V
  0000 new-instance v0, Landroid/app/AlertDialog$Builder;
  0004 invoke-direct v0, v5, Landroid/app/AlertDialog$Builder;-><init>(Landroid/content/Context;)V
  000a const-string v1, "How should Dokkan Unit Creator open your AI?"
  000e invoke-virtual v0, v1, Landroid/app/AlertDialog$Builder;->setTitle(Ljava/lang/CharSequence;)Landroid/app/AlertDialog$Builder;
  0014 move-result-object v0
  0016 const-string v1, "App first, then website"
  001a const-string v2, "Always use the browser"
  001e filled-new-array v1, v2, [Ljava/lang/String;
  0024 move-result-object v1
  0026 iget-object v2, v5, Lcom/personal/aihub/MainActivity;->prefs Landroid/content/SharedPreferences;
  002a const-string v3, "preferApp"
  002e const/4 v4, 1
  0030 invoke-interface v2, v3, v4, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String; Z)Z
  0036 move-result v2
  0038 xor-int/2addr v2, v4
  003a new-instance v3, Lcom/personal/aihub/MainActivity$6;
  003e invoke-direct v3, v5, Lcom/personal/aihub/MainActivity$6;-><init>(Lcom/personal/aihub/MainActivity;)V
  0044 invoke-virtual v0, v1, v2, v3, Landroid/app/AlertDialog$Builder;->setSingleChoiceItems([Ljava/lang/CharSequence; I Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;
  004a move-result-object v0
  004c const/4 v1, 0
  004e move-object v2, v1
  0050 check-cast v2, Landroid/content/DialogInterface$OnClickListener;
  0054 const-string v2, "Cancel"
  0058 invoke-virtual v0, v2, v1, Landroid/app/AlertDialog$Builder;->setNegativeButton(Ljava/lang/CharSequence; Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;
  005e move-result-object v0
  0060 invoke-virtual v0, Landroid/app/AlertDialog$Builder;->show()Landroid/app/AlertDialog;
  0066 return-void 
.end method

.method dp(I)I
  0000 int-to-float v2, v2
  0002 invoke-virtual v1, Lcom/personal/aihub/MainActivity;->getResources()Landroid/content/res/Resources;
  0008 move-result-object v0
  000a invoke-virtual v0, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
  0010 move-result-object v0
  0012 iget v0, v0, Landroid/util/DisplayMetrics;->density F
  0016 mul-float/2addr v2, v0
  0018 invoke-static v2, Ljava/lang/Math;->round(F)I
  001e move-result v2
  0020 return v2
.end method

.method lambda$0(Landroid/view/View; Landroid/view/WindowInsets;)Landroid/view/WindowInsets;
  0000 invoke-static Landroid/view/WindowInsets$Type;->systemBars()I
  0006 move-result v0
  0008 invoke-static Landroid/view/WindowInsets$Type;->displayCutout()I
  000e move-result v1
  0010 or-int/2addr v0, v1
  0012 invoke-virtual v5, v0, Landroid/view/WindowInsets;->getInsets(I)Landroid/graphics/Insets;
  0018 move-result-object v0
  001a iget v1, v0, Landroid/graphics/Insets;->left I
  001e iget v2, v0, Landroid/graphics/Insets;->top I
  0022 iget v3, v0, Landroid/graphics/Insets;->right I
  0026 iget v0, v0, Landroid/graphics/Insets;->bottom I
  002a invoke-virtual v4, v1, v2, v3, v0, Landroid/view/View;->setPadding(I I I I)V
  0030 return-object v5
.end method

.method launch(Lcom/personal/aihub/Provider; Z)V
  0000 invoke-static v3, v4, v2, Lcom/personal/aihub/LaunchCoordinator;->open(Lcom/personal/aihub/Provider; Z Lcom/personal/aihub/LaunchCoordinator$Platform;)Lcom/personal/aihub/LaunchCoordinator$Result;
  0006 move-result-object v4
  0008 sget-object v0, Lcom/personal/aihub/LaunchCoordinator$Result;->UNAVAILABLE Lcom/personal/aihub/LaunchCoordinator$Result;
  000c if-ne v4, v0, +02eh
  0010 new-instance v4, Landroid/app/AlertDialog$Builder;
  0014 invoke-direct v4, v2, Landroid/app/AlertDialog$Builder;-><init>(Landroid/content/Context;)V
  001a new-instance v0, Ljava/lang/StringBuilder;
  001e const-string v1, "Unable to open "
  0022 invoke-direct v0, v1, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
  0028 iget-object v3, v3, Lcom/personal/aihub/Provider;->label Ljava/lang/String;
  002c invoke-virtual v0, v3, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
  0032 invoke-virtual v0, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
  0038 move-result-object v3
  003a invoke-virtual v4, v3, Landroid/app/AlertDialog$Builder;->setTitle(Ljava/lang/CharSequence;)Landroid/app/AlertDialog$Builder;
  0040 move-result-object v3
  0042 const-string v4, "No available app or web browser could open this service. Install or enable a browser, then try again."
  0046 invoke-virtual v3, v4, Landroid/app/AlertDialog$Builder;->setMessage(Ljava/lang/CharSequence;)Landroid/app/AlertDialog$Builder;
  004c move-result-object v3
  004e const/4 v4, 0
  0050 move-object v0, v4
  0052 check-cast v0, Landroid/content/DialogInterface$OnClickListener;
  0056 const-string v0, "OK"
  005a invoke-virtual v3, v0, v4, Landroid/app/AlertDialog$Builder;->setPositiveButton(Ljava/lang/CharSequence; Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;
  0060 move-result-object v3
  0062 invoke-virtual v3, Landroid/app/AlertDialog$Builder;->show()Landroid/app/AlertDialog;
  0068 return-void 
.end method

.method refreshStatus()V
  0000 invoke-static Lcom/personal/aihub/Provider;->valuesCustom()[Lcom/personal/aihub/Provider;
  0006 move-result-object v0
  0008 const/4 v1, 0
  000a iget-object v2, v5, Lcom/personal/aihub/MainActivity;->badges Ljava/util/List;
  000e invoke-interface v2, Ljava/util/List;->size()I
  0014 move-result v2
  0016 if-lt v1, v2, +01ah
  001a iget-object v0, v5, Lcom/personal/aihub/MainActivity;->preference Landroid/widget/Button;
  001e if-eqz v0, +015h
  0022 iget-object v1, v5, Lcom/personal/aihub/MainActivity;->prefs Landroid/content/SharedPreferences;
  0026 const-string v2, "preferApp"
  002a const/4 v3, 1
  002c invoke-interface v1, v2, v3, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String; Z)Z
  0032 move-result v1
  0034 if-eqz v1, +005h
  0038 const-string v1, "↗  App first · website if unavailable"
  003c goto +3h
  003e const-string v1, "◎  Always open in browser"
  0042 invoke-virtual v0, v1, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V
  0048 return-void 
  004a iget-object v2, v5, Lcom/personal/aihub/MainActivity;->badges Ljava/util/List;
  004e invoke-interface v2, v1, Ljava/util/List;->get(I)Ljava/lang/Object;
  0054 move-result-object v2
  0056 check-cast v2, Landroid/widget/TextView;
  005a invoke-virtual v5, Lcom/personal/aihub/MainActivity;->getPackageManager()Landroid/content/pm/PackageManager;
  0060 move-result-object v3
  0062 aget-object v4, v0, v1
  0066 iget-object v4, v4, Lcom/personal/aihub/Provider;->packageName Ljava/lang/String;
  006a invoke-virtual v3, v4, Landroid/content/pm/PackageManager;->getLaunchIntentForPackage(Ljava/lang/String;)Landroid/content/Intent;
  0070 move-result-object v3
  0072 if-eqz v3, +005h
  0076 const-string v3, "APP INSTALLED"
  007a goto +3h
  007c const-string v3, "OPENS WEBSITE"
  0080 invoke-virtual v2, v3, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0086 add-int/lit8 v1, v1, 1
  008a goto -40h
.end method

.method row()Landroid/widget/LinearLayout;
  0000 new-instance v0, Landroid/widget/LinearLayout;
  0004 invoke-direct v0, v2, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
  000a const/4 v1, 0
  000c invoke-virtual v0, v1, Landroid/widget/LinearLayout;->setOrientation(I)V
  0012 const/16 v1, 16
  0016 invoke-virtual v0, v1, Landroid/widget/LinearLayout;->setGravity(I)V
  001c return-object v0
.end method

.method shape(I I I)Landroid/graphics/drawable/GradientDrawable;
  0000 new-instance v0, Landroid/graphics/drawable/GradientDrawable;
  0004 invoke-direct v0, Landroid/graphics/drawable/GradientDrawable;-><init>()V
  000a invoke-virtual v0, v2, Landroid/graphics/drawable/GradientDrawable;->setColor(I)V
  0010 invoke-direct v1, v4, Lcom/personal/aihub/MainActivity;->dp(I)I
  0016 move-result v2
  0018 int-to-float v2, v2
  001a invoke-virtual v0, v2, Landroid/graphics/drawable/GradientDrawable;->setCornerRadius(F)V
  0020 if-eqz v3, +00ah
  0024 const/4 v2, 1
  0026 invoke-direct v1, v2, Lcom/personal/aihub/MainActivity;->dp(I)I
  002c move-result v2
  002e invoke-virtual v0, v2, v3, Landroid/graphics/drawable/GradientDrawable;->setStroke(I I)V
  0034 return-object v0
.end method

.method showAbout()V
  0000 new-instance v0, Landroid/app/AlertDialog$Builder;
  0004 invoke-direct v0, v3, Landroid/app/AlertDialog$Builder;-><init>(Landroid/content/Context;)V
  000a const-string v1, "Your accounts. Your choice."
  000e invoke-virtual v0, v1, Landroid/app/AlertDialog$Builder;->setTitle(Ljava/lang/CharSequence;)Landroid/app/AlertDialog$Builder;
  0014 move-result-object v0
  0016 const-string v1, "Dokkan Unit Creator opens the official ChatGPT, Grok, and Claude apps or websites. Your existing subscriptions apply there, subject to each provider’s plan.

Dokkan Unit Creator does not read chats, collect passwords, or use paid APIs. Conversations remain with each provider; the assistants do not share a conversation automatically.

This is an independent launcher, unaffiliated with OpenAI, xAI, or Anthropic."
  001a invoke-virtual v0, v1, Landroid/app/AlertDialog$Builder;->setMessage(Ljava/lang/CharSequence;)Landroid/app/AlertDialog$Builder;
  0020 move-result-object v0
  0022 const/4 v1, 0
  0024 move-object v2, v1
  0026 check-cast v2, Landroid/content/DialogInterface$OnClickListener;
  002a const-string v2, "Got it"
  002e invoke-virtual v0, v2, v1, Landroid/app/AlertDialog$Builder;->setPositiveButton(Ljava/lang/CharSequence; Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;
  0034 move-result-object v0
  0036 invoke-virtual v0, Landroid/app/AlertDialog$Builder;->show()Landroid/app/AlertDialog;
  003c return-void 
.end method

.method text(Ljava/lang/String; I I Z)Landroid/widget/TextView;
  0000 new-instance v0, Landroid/widget/TextView;
  0004 invoke-direct v0, v1, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
  000a invoke-virtual v0, v2, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
  0010 int-to-float v2, v3
  0012 invoke-virtual v0, v2, Landroid/widget/TextView;->setTextSize(F)V
  0018 invoke-virtual v0, v4, Landroid/widget/TextView;->setTextColor(I)V
  001e const-string v2, "kern"
  0022 invoke-virtual v0, v2, Landroid/widget/TextView;->setFontFeatureSettings(Ljava/lang/String;)V
  0028 if-eqz v5, +00ch
  002c const-string v2, "sans-serif-medium"
  0030 const/4 v3, 0
  0032 invoke-static v2, v3, Landroid/graphics/Typeface;->create(Ljava/lang/String; I)Landroid/graphics/Typeface;
  0038 move-result-object v2
  003a invoke-virtual v0, v2, Landroid/widget/TextView;->setTypeface(Landroid/graphics/Typeface;)V
  0040 const/4 v2, 3
  0042 invoke-direct v1, v2, Lcom/personal/aihub/MainActivity;->dp(I)I
  0048 move-result v2
  004a int-to-float v2, v2
  004c const/high16 v3, 1065353216
  0050 invoke-virtual v0, v2, v3, Landroid/widget/TextView;->setLineSpacing(F F)V
  0056 const/16 v2, 16
  005a invoke-virtual v0, v2, Landroid/widget/TextView;->setGravity(I)V
  0060 return-object v0
.end method

.method m21lambda$1$compersonalaihubMainActivity(Landroid/view/View;)V
  0000 invoke-direct v0, Lcom/personal/aihub/MainActivity;->showAbout()V
  0006 return-void 
.end method

.method m22lambda$2$compersonalaihubMainActivity(Landroid/view/View;)V
  0000 invoke-direct v0, Lcom/personal/aihub/MainActivity;->choosePreference()V
  0006 return-void 
.end method

.method m23lambda$3$compersonalaihubMainActivity(Lcom/personal/aihub/Provider; Landroid/view/View;)V
  0000 iget-object v4, v2, Lcom/personal/aihub/MainActivity;->prefs Landroid/content/SharedPreferences;
  0004 const-string v0, "preferApp"
  0008 const/4 v1, 1
  000a invoke-interface v4, v0, v1, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String; Z)Z
  0010 move-result v4
  0012 invoke-direct v2, v3, v4, Lcom/personal/aihub/MainActivity;->launch(Lcom/personal/aihub/Provider; Z)V
  0018 return-void 
.end method

.method m24lambda$4$compersonalaihubMainActivity(Lcom/personal/aihub/Provider; Landroid/view/View;)V
  0000 const/4 v2, 0
  0002 invoke-direct v0, v1, v2, Lcom/personal/aihub/MainActivity;->launch(Lcom/personal/aihub/Provider; Z)V
  0008 return-void 
.end method

.method m25lambda$5$compersonalaihubMainActivity(Landroid/content/DialogInterface; I)V
  0000 iget-object v0, v2, Lcom/personal/aihub/MainActivity;->prefs Landroid/content/SharedPreferences;
  0004 invoke-interface v0, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;
  000a move-result-object v0
  000c if-nez v4, +004h
  0010 const/4 v4, 1
  0012 goto +2h
  0014 const/4 v4, 0
  0016 const-string v1, "preferApp"
  001a invoke-interface v0, v1, v4, Landroid/content/SharedPreferences$Editor;->putBoolean(Ljava/lang/String; Z)Landroid/content/SharedPreferences$Editor;
  0020 move-result-object v4
  0022 invoke-interface v4, Landroid/content/SharedPreferences$Editor;->apply()V
  0028 invoke-interface v3, Landroid/content/DialogInterface;->dismiss()V
  002e invoke-direct v2, Lcom/personal/aihub/MainActivity;->refreshStatus()V
  0034 return-void 
.end method

.method onCreate(Landroid/os/Bundle;)V
  0000 invoke-super v13, v14, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V
  0006 const-string v14, "orbit"
  000a const/4 v0, 0
  000c invoke-virtual v13, v14, v0, Lcom/personal/aihub/MainActivity;->getSharedPreferences(Ljava/lang/String; I)Landroid/content/SharedPreferences;
  0012 move-result-object v14
  0014 iput-object v14, v13, Lcom/personal/aihub/MainActivity;->prefs Landroid/content/SharedPreferences;
  0018 invoke-virtual v13, Lcom/personal/aihub/MainActivity;->getWindow()Landroid/view/Window;
  001e move-result-object v14
  0020 sget v1, Lcom/personal/aihub/MainActivity;->BG I
  0024 invoke-virtual v14, v1, Landroid/view/Window;->setStatusBarColor(I)V
  002a invoke-virtual v13, Lcom/personal/aihub/MainActivity;->getWindow()Landroid/view/Window;
  0030 move-result-object v14
  0032 invoke-virtual v14, v1, Landroid/view/Window;->setNavigationBarColor(I)V
  0038 new-instance v14, Landroid/widget/FrameLayout;
  003c invoke-direct v14, v13, Landroid/widget/FrameLayout;-><init>(Landroid/content/Context;)V
  0042 invoke-virtual v14, v1, Landroid/widget/FrameLayout;->setBackgroundColor(I)V
  0048 invoke-virtual v13, v14, Lcom/personal/aihub/MainActivity;->setContentView(Landroid/view/View;)V
  004e sget v1, Landroid/os/Build$VERSION;->SDK_INT I
  0052 const/16 v2, 30
  0056 if-lt v1, v2, +011h
  005a invoke-virtual v13, Lcom/personal/aihub/MainActivity;->getWindow()Landroid/view/Window;
  0060 move-result-object v1
  0062 invoke-virtual v1, v0, Landroid/view/Window;->setDecorFitsSystemWindows(Z)V
  0068 new-instance v1, Lcom/personal/aihub/MainActivity$1;
  006c invoke-direct v1, v13, Lcom/personal/aihub/MainActivity$1;-><init>(Lcom/personal/aihub/MainActivity;)V
  0072 invoke-virtual v14, v1, Landroid/widget/FrameLayout;->setOnApplyWindowInsetsListener(Landroid/view/View$OnApplyWindowInsetsListener;)V
  0078 new-instance v1, Landroid/widget/ScrollView;
  007c invoke-direct v1, v13, Landroid/widget/ScrollView;-><init>(Landroid/content/Context;)V
  0082 const/4 v3, 1
  0084 invoke-virtual v1, v3, Landroid/widget/ScrollView;->setFillViewport(Z)V
  008a new-instance v4, Landroid/widget/FrameLayout$LayoutParams;
  008e const/4 v5, -1
  0090 invoke-direct v4, v5, v5, Landroid/widget/FrameLayout$LayoutParams;-><init>(I I)V
  0096 invoke-virtual v14, v1, v4, Landroid/widget/FrameLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  009c new-instance v14, Landroid/widget/FrameLayout;
  00a0 invoke-direct v14, v13, Landroid/widget/FrameLayout;-><init>(Landroid/content/Context;)V
  00a6 new-instance v4, Landroid/widget/FrameLayout$LayoutParams;
  00aa const/4 v6, -2
  00ac invoke-direct v4, v5, v6, Landroid/widget/FrameLayout$LayoutParams;-><init>(I I)V
  00b2 invoke-virtual v1, v14, v4, Landroid/widget/ScrollView;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  00b8 new-instance v1, Landroid/widget/LinearLayout;
  00bc invoke-direct v1, v13, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
  00c2 iput-object v1, v13, Lcom/personal/aihub/MainActivity;->content Landroid/widget/LinearLayout;
  00c6 invoke-virtual v1, v3, Landroid/widget/LinearLayout;->setOrientation(I)V
  00cc iget-object v1, v13, Lcom/personal/aihub/MainActivity;->content Landroid/widget/LinearLayout;
  00d0 const/16 v4, 24
  00d4 invoke-direct v13, v4, Lcom/personal/aihub/MainActivity;->dp(I)I
  00da move-result v7
  00dc const/16 v8, 26
  00e0 invoke-direct v13, v8, Lcom/personal/aihub/MainActivity;->dp(I)I
  00e6 move-result v8
  00e8 invoke-direct v13, v4, Lcom/personal/aihub/MainActivity;->dp(I)I
  00ee move-result v9
  00f0 const/16 v10, 28
  00f4 invoke-direct v13, v10, Lcom/personal/aihub/MainActivity;->dp(I)I
  00fa move-result v10
  00fc invoke-virtual v1, v7, v8, v9, v10, Landroid/widget/LinearLayout;->setPadding(I I I I)V
  0102 iget-object v1, v13, Lcom/personal/aihub/MainActivity;->content Landroid/widget/LinearLayout;
  0106 new-instance v7, Landroid/widget/FrameLayout$LayoutParams;
  010a invoke-virtual v13, Lcom/personal/aihub/MainActivity;->getResources()Landroid/content/res/Resources;
  0110 move-result-object v8
  0112 invoke-virtual v8, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
  0118 move-result-object v8
  011a iget v8, v8, Landroid/util/DisplayMetrics;->widthPixels I
  011e const/16 v9, 680
  0122 invoke-direct v13, v9, Lcom/personal/aihub/MainActivity;->dp(I)I
  0128 move-result v9
  012a invoke-static v8, v9, Ljava/lang/Math;->min(I I)I
  0130 move-result v8
  0132 const/16 v9, 49
  0136 invoke-direct v7, v8, v6, v9, Landroid/widget/FrameLayout$LayoutParams;-><init>(I I I)V
  013c invoke-virtual v14, v1, v7, Landroid/widget/FrameLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  0142 invoke-direct v13, Lcom/personal/aihub/MainActivity;->row()Landroid/widget/LinearLayout;
  0148 move-result-object v14
  014a sget v1, Lcom/personal/aihub/MainActivity;->LIME I
  014e const-string v6, "◉  AI ASSISTANTS"
  0152 const/16 v7, 16
  0156 invoke-direct v13, v6, v7, v1, v3, Lcom/personal/aihub/MainActivity;->text(Ljava/lang/String; I I Z)Landroid/widget/TextView;
  015c move-result-object v6
  015e const v8, 1042536202
  0164 invoke-virtual v6, v8, Landroid/widget/TextView;->setLetterSpacing(F)V
  016a new-instance v8, Landroid/widget/LinearLayout$LayoutParams;
  016e const/16 v9, 48
  0172 invoke-direct v13, v9, Lcom/personal/aihub/MainActivity;->dp(I)I
  0178 move-result v10
  017a const/high16 v11, 1065353216
  017e invoke-direct v8, v0, v10, v11, Landroid/widget/LinearLayout$LayoutParams;-><init>(I I F)V
  0184 invoke-virtual v14, v6, v8, Landroid/widget/LinearLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  018a sget v6, Lcom/personal/aihub/MainActivity;->TEXT I
  018e const/16 v8, 34
  0192 const/16 v10, 41
  0196 invoke-static v8, v10, v9, Landroid/graphics/Color;->rgb(I I I)I
  019c move-result v8
  019e const-string v10, "About"
  01a2 invoke-direct v13, v10, v6, v8, Lcom/personal/aihub/MainActivity;->button(Ljava/lang/String; I I)Landroid/widget/Button;
  01a8 move-result-object v8
  01aa const/high16 v10, 1095761920
  01ae invoke-virtual v8, v10, Landroid/widget/Button;->setTextSize(F)V
  01b4 new-instance v11, Lcom/personal/aihub/MainActivity$2;
  01b8 invoke-direct v11, v13, Lcom/personal/aihub/MainActivity$2;-><init>(Lcom/personal/aihub/MainActivity;)V
  01be invoke-virtual v8, v11, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
  01c4 new-instance v11, Landroid/widget/LinearLayout$LayoutParams;
  01c8 const/16 v12, 78
  01cc invoke-direct v13, v12, Lcom/personal/aihub/MainActivity;->dp(I)I
  01d2 move-result v12
  01d4 invoke-direct v13, v9, Lcom/personal/aihub/MainActivity;->dp(I)I
  01da move-result v9
  01dc invoke-direct v11, v12, v9, Landroid/widget/LinearLayout$LayoutParams;-><init>(I I)V
  01e2 invoke-virtual v14, v8, v11, Landroid/widget/LinearLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  01e8 iget-object v8, v13, Lcom/personal/aihub/MainActivity;->content Landroid/widget/LinearLayout;
  01ec invoke-virtual v8, v14, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  01f2 invoke-direct v13, v2, Lcom/personal/aihub/MainActivity;->addSpace(I)V
  01f8 iget-object v14, v13, Lcom/personal/aihub/MainActivity;->content Landroid/widget/LinearLayout;
  01fc const-string v8, "Your AI,
one place."
  0200 const/16 v9, 40
  0204 invoke-direct v13, v8, v9, v6, v3, Lcom/personal/aihub/MainActivity;->text(Ljava/lang/String; I I Z)Landroid/widget/TextView;
  020a move-result-object v6
  020c invoke-virtual v14, v6, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  0212 const/16 v14, 12
  0216 invoke-direct v13, v14, Lcom/personal/aihub/MainActivity;->addSpace(I)V
  021c iget-object v6, v13, Lcom/personal/aihub/MainActivity;->content Landroid/widget/LinearLayout;
  0220 sget v8, Lcom/personal/aihub/MainActivity;->MUTED I
  0224 const-string v11, "Pick your assistant. Keep your own accounts."
  0228 invoke-direct v13, v11, v7, v8, v0, Lcom/personal/aihub/MainActivity;->text(Ljava/lang/String; I I Z)Landroid/widget/TextView;
  022e move-result-object v7
  0230 invoke-virtual v6, v7, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  0236 invoke-direct v13, v4, Lcom/personal/aihub/MainActivity;->addSpace(I)V
  023c const-string v6, ""
  0240 invoke-static v2, v9, v2, Landroid/graphics/Color;->rgb(I I I)I
  0246 move-result v2
  0248 invoke-direct v13, v6, v1, v2, Lcom/personal/aihub/MainActivity;->button(Ljava/lang/String; I I)Landroid/widget/Button;
  024e move-result-object v1
  0250 iput-object v1, v13, Lcom/personal/aihub/MainActivity;->preference Landroid/widget/Button;
  0254 invoke-virtual v1, v10, Landroid/widget/Button;->setTextSize(F)V
  025a iget-object v1, v13, Lcom/personal/aihub/MainActivity;->preference Landroid/widget/Button;
  025e new-instance v2, Lcom/personal/aihub/MainActivity$3;
  0262 invoke-direct v2, v13, Lcom/personal/aihub/MainActivity$3;-><init>(Lcom/personal/aihub/MainActivity;)V
  0268 invoke-virtual v1, v2, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
  026e iget-object v1, v13, Lcom/personal/aihub/MainActivity;->content Landroid/widget/LinearLayout;
  0272 iget-object v2, v13, Lcom/personal/aihub/MainActivity;->preference Landroid/widget/Button;
  0276 new-instance v6, Landroid/widget/LinearLayout$LayoutParams;
  027a const/16 v7, 50
  027e invoke-direct v13, v7, Lcom/personal/aihub/MainActivity;->dp(I)I
  0284 move-result v7
  0286 invoke-direct v6, v5, v7, Landroid/widget/LinearLayout$LayoutParams;-><init>(I I)V
  028c invoke-virtual v1, v2, v6, Landroid/widget/LinearLayout;->addView(Landroid/view/View; Landroid/view/ViewGroup$LayoutParams;)V
  0292 invoke-direct v13, v4, Lcom/personal/aihub/MainActivity;->addSpace(I)V
  0298 const-string v1, "YOUR ASSISTANTS"
  029c const/16 v2, 11
  02a0 invoke-direct v13, v1, v2, v8, v3, Lcom/personal/aihub/MainActivity;->text(Ljava/lang/String; I I Z)Landroid/widget/TextView;
  02a6 move-result-object v1
  02a8 const v2, 1041194025
  02ae invoke-virtual v1, v2, Landroid/widget/TextView;->setLetterSpacing(F)V
  02b4 iget-object v2, v13, Lcom/personal/aihub/MainActivity;->content Landroid/widget/LinearLayout;
  02b8 invoke-virtual v2, v1, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  02be invoke-direct v13, v14, Lcom/personal/aihub/MainActivity;->addSpace(I)V
  02c4 invoke-static Lcom/personal/aihub/Provider;->valuesCustom()[Lcom/personal/aihub/Provider;
  02ca move-result-object v14
  02cc array-length v1, v14
  02ce move v2, v0
  02d0 if-ge v2, v1, +00fh
  02d4 aget-object v4, v14, v2
  02d8 invoke-direct v13, v4, Lcom/personal/aihub/MainActivity;->addProvider(Lcom/personal/aihub/Provider;)V
  02de const/16 v4, 14
  02e2 invoke-direct v13, v4, Lcom/personal/aihub/MainActivity;->addSpace(I)V
  02e8 add-int/lit8 v2, v2, 1
  02ec goto -eh
  02ee const/4 v14, 6
  02f0 invoke-direct v13, v14, Lcom/personal/aihub/MainActivity;->addSpace(I)V
  02f6 iget-object v14, v13, Lcom/personal/aihub/MainActivity;->content Landroid/widget/LinearLayout;
  02fa sget v1, Lcom/personal/aihub/MainActivity;->MUTED I
  02fe const-string v2, "Your subscriptions stay with each provider. Sign in in their app or website."
  0302 const/16 v4, 13
  0306 invoke-direct v13, v2, v4, v1, v0, Lcom/personal/aihub/MainActivity;->text(Ljava/lang/String; I I Z)Landroid/widget/TextView;
  030c move-result-object v0
  030e invoke-virtual v14, v0, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  0314 const/16 v14, 18
  0318 invoke-direct v13, v14, Lcom/personal/aihub/MainActivity;->addSpace(I)V
  031e const-string v14, "DOKKAN UNIT CREATION  /  AI ASSISTANTS"
  0322 const/16 v0, 10
  0326 invoke-direct v13, v14, v0, v1, v3, Lcom/personal/aihub/MainActivity;->text(Ljava/lang/String; I I Z)Landroid/widget/TextView;
  032c move-result-object v14
  032e const v0, 1040522936
  0334 invoke-virtual v14, v0, Landroid/widget/TextView;->setLetterSpacing(F)V
  033a iget-object v0, v13, Lcom/personal/aihub/MainActivity;->content Landroid/widget/LinearLayout;
  033e invoke-virtual v0, v14, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V
  0344 return-void 
.end method

.method onResume()V
  0000 invoke-super v0, Landroid/app/Activity;->onResume()V
  0006 invoke-direct v0, Lcom/personal/aihub/MainActivity;->refreshStatus()V
  000c return-void 
.end method

.method openApp(Lcom/personal/aihub/Provider;)Z
  0000 const/4 v0, 0
  0002 invoke-virtual v2, Lcom/personal/aihub/MainActivity;->getPackageManager()Landroid/content/pm/PackageManager;
  0008 move-result-object v1
  000a iget-object v3, v3, Lcom/personal/aihub/Provider;->packageName Ljava/lang/String;
  000e invoke-virtual v1, v3, Landroid/content/pm/PackageManager;->getLaunchIntentForPackage(Ljava/lang/String;)Landroid/content/Intent;
  0014 move-result-object v3
  0016 if-nez v3, +003h
  001a return v0
  001c invoke-virtual v2, v3, Lcom/personal/aihub/MainActivity;->startActivity(Landroid/content/Intent;)V
  0022 const/4 v3, 1
  0024 return v3
  0026 return v0
.end method

.method openWebsite(Lcom/personal/aihub/Provider;)Z
  0000 new-instance v0, Landroid/content/Intent;
  0004 const-string v1, "https://example.org/"
  0008 invoke-static v1, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  000e move-result-object v1
  0010 const-string v2, "android.intent.action.VIEW"
  0014 invoke-direct v0, v2, v1, Landroid/content/Intent;-><init>(Ljava/lang/String; Landroid/net/Uri;)V
  001a const-string v1, "android.intent.category.BROWSABLE"
  001e invoke-virtual v0, v1, Landroid/content/Intent;->addCategory(Ljava/lang/String;)Landroid/content/Intent;
  0024 invoke-virtual v9, Lcom/personal/aihub/MainActivity;->getPackageManager()Landroid/content/pm/PackageManager;
  002a move-result-object v3
  002c const/high16 v4, 65536
  0030 invoke-virtual v3, v0, v4, Landroid/content/pm/PackageManager;->queryIntentActivities(Landroid/content/Intent; I)Ljava/util/List;
  0036 move-result-object v5
  0038 new-instance v6, Ljava/util/ArrayList;
  003c invoke-direct v6, Ljava/util/ArrayList;-><init>()V
  0042 invoke-interface v5, Ljava/util/List;->iterator()Ljava/util/Iterator;
  0048 move-result-object v5
  004a invoke-interface v5, Ljava/util/Iterator;->hasNext()Z
  0050 move-result v7
  0052 if-eqz v7, +020h
  0056 invoke-interface v5, Ljava/util/Iterator;->next()Ljava/lang/Object;
  005c move-result-object v7
  005e check-cast v7, Landroid/content/pm/ResolveInfo;
  0062 iget-object v7, v7, Landroid/content/pm/ResolveInfo;->activityInfo Landroid/content/pm/ActivityInfo;
  0066 iget-object v7, v7, Landroid/content/pm/ActivityInfo;->packageName Ljava/lang/String;
  006a invoke-virtual v6, v7, Ljava/util/ArrayList;->contains(Ljava/lang/Object;)Z
  0070 move-result v8
  0072 if-nez v8, -014h
  0076 invoke-virtual v9, Lcom/personal/aihub/MainActivity;->getPackageName()Ljava/lang/String;
  007c move-result-object v8
  007e invoke-virtual v7, v8, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
  0084 move-result v8
  0086 if-nez v8, -01eh
  008a invoke-virtual v6, v7, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
  0090 goto -23h
  0092 invoke-virtual v3, v0, v4, Landroid/content/pm/PackageManager;->resolveActivity(Landroid/content/Intent; I)Landroid/content/pm/ResolveInfo;
  0098 move-result-object v0
  009a const/4 v3, 0
  009c if-eqz v0, +013h
  00a0 iget-object v4, v0, Landroid/content/pm/ResolveInfo;->activityInfo Landroid/content/pm/ActivityInfo;
  00a4 iget-object v4, v4, Landroid/content/pm/ActivityInfo;->packageName Ljava/lang/String;
  00a8 invoke-virtual v6, v4, Ljava/util/ArrayList;->remove(Ljava/lang/Object;)Z
  00ae move-result v4
  00b0 if-eqz v4, +009h
  00b4 iget-object v0, v0, Landroid/content/pm/ResolveInfo;->activityInfo Landroid/content/pm/ActivityInfo;
  00b8 iget-object v0, v0, Landroid/content/pm/ActivityInfo;->packageName Ljava/lang/String;
  00bc invoke-virtual v6, v3, v0, Ljava/util/ArrayList;->add(I Ljava/lang/Object;)V
  00c2 invoke-virtual v6, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
  00c8 move-result-object v0
  00ca invoke-interface v0, Ljava/util/Iterator;->hasNext()Z
  00d0 move-result v4
  00d2 if-eqz v4, +01eh
  00d6 invoke-interface v0, Ljava/util/Iterator;->next()Ljava/lang/Object;
  00dc move-result-object v4
  00de check-cast v4, Ljava/lang/String;
  00e2 new-instance v5, Landroid/content/Intent;
  00e6 iget-object v6, v10, Lcom/personal/aihub/Provider;->website Ljava/lang/String;
  00ea invoke-static v6, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
  00f0 move-result-object v6
  00f2 invoke-direct v5, v2, v6, Landroid/content/Intent;-><init>(Ljava/lang/String; Landroid/net/Uri;)V
  00f8 invoke-virtual v5, v1, Landroid/content/Intent;->addCategory(Ljava/lang/String;)Landroid/content/Intent;
  00fe invoke-virtual v5, v4, Landroid/content/Intent;->setPackage(Ljava/lang/String;)Landroid/content/Intent;
  0104 invoke-virtual v9, v5, Lcom/personal/aihub/MainActivity;->startActivity(Landroid/content/Intent;)V
  010a const/4 v10, 1
  010c return v10
  010e return v3
.end method