package com.personal.aihub;
public final class MainActivity extends android.app.Activity implements com.personal.aihub.LaunchCoordinator$Platform {
    private static final int BG;
    private static final int LIME;
    private static final int MUTED;
    private static final int TEXT;
    private final java.util.List badges;
    private android.widget.LinearLayout content;
    private android.widget.Button preference;
    private android.content.SharedPreferences prefs;

    static MainActivity()
    {
        com.personal.aihub.MainActivity.BG = android.graphics.Color.rgb(17, 21, 26);
        com.personal.aihub.MainActivity.TEXT = android.graphics.Color.rgb(244, 246, 241);
        com.personal.aihub.MainActivity.MUTED = android.graphics.Color.rgb(162, 172, 182);
        com.personal.aihub.MainActivity.LIME = android.graphics.Color.rgb(180, 242, 114);
        return;
    }

    public MainActivity()
    {
        this.badges = new java.util.ArrayList();
        return;
    }

    private void addProvider(com.personal.aihub.Provider p15)
    {
        android.widget.LinearLayout$LayoutParams v0_6 = android.graphics.Color.parseColor(p15.color);
        android.widget.LinearLayout v1_1 = new android.widget.LinearLayout(this);
        v1_1.setOrientation(1);
        v1_1.setPadding(this.dp(20), this.dp(20), this.dp(20), this.dp(16));
        v1_1.setBackground(this.shape(android.graphics.Color.rgb(26, 32, 39), android.graphics.Color.rgb(45, 53, 62), 22));
        String v3_6 = this.row();
        android.widget.LinearLayout$LayoutParams v4_13 = this.text(p15.mark, 24, v0_6, 1);
        v4_13.setGravity(17);
        v4_13.setBackground(this.shape(android.graphics.Color.rgb(39, 46, 53), 0, 14));
        v3_6.addView(v4_13, new android.widget.LinearLayout$LayoutParams(this.dp(48), this.dp(48)));
        android.widget.LinearLayout$LayoutParams v4_15 = new android.widget.LinearLayout(this);
        v4_15.setOrientation(1);
        int v5_7 = new android.widget.LinearLayout$LayoutParams(0, -2, 1065353216);
        v5_7.leftMargin = this.dp(14);
        v3_6.addView(v4_15, v5_7);
        v4_15.addView(this.text(p15.label, 22, com.personal.aihub.MainActivity.TEXT, 1));
        int v2_10 = this.text("", 10, v0_6, 1);
        v2_10.setLetterSpacing(1034147594);
        v4_15.addView(v2_10);
        this.badges.add(v2_10);
        v1_1.addView(v3_6);
        String v3_8 = com.personal.aihub.MainActivity.MUTED;
        int v2_12 = this.text(p15.description, 14, v3_8, 0);
        android.widget.LinearLayout$LayoutParams v4_18 = new android.widget.LinearLayout$LayoutParams(-1, -2);
        v4_18.topMargin = this.dp(16);
        v4_18.bottomMargin = this.dp(16);
        v1_1.addView(v2_12, v4_18);
        int v2_13 = this.row();
        android.widget.LinearLayout$LayoutParams v4_0 = new StringBuilder("Open ");
        v4_0.append(p15.label);
        v4_0.append("  \u2197");
        android.widget.LinearLayout$LayoutParams v0_1 = this.button(v4_0.toString(), com.personal.aihub.MainActivity.BG, v0_6);
        android.widget.LinearLayout$LayoutParams v4_3 = new StringBuilder("Open ");
        v4_3.append(p15.label);
        v4_3.append(" using your launch preference");
        v0_1.setContentDescription(v4_3.toString());
        v0_1.setOnClickListener(new com.personal.aihub.MainActivity$4(this, p15));
        v2_13.addView(v0_1, new android.widget.LinearLayout$LayoutParams(0, this.dp(50), 1065353216));
        v1_1.addView(v2_13);
        android.widget.LinearLayout$LayoutParams v0_3 = this.button("Open website", v3_8, 0);
        v0_3.setTextSize(1094713344);
        int v2_2 = new StringBuilder("Open ");
        v2_2.append(p15.label);
        v2_2.append(" website in browser");
        v0_3.setContentDescription(v2_2.toString());
        v0_3.setOnClickListener(new com.personal.aihub.MainActivity$5(this, p15));
        android.widget.LinearLayout v15_2 = new android.widget.LinearLayout$LayoutParams(-1, this.dp(48));
        v15_2.topMargin = this.dp(4);
        v1_1.addView(v0_3, v15_2);
        this.content.addView(v1_1, new android.widget.LinearLayout$LayoutParams(-1, -2));
        return;
    }

    private void addSpace(int p5)
    {
        this.content.addView(new android.view.View(this), new android.widget.LinearLayout$LayoutParams(1, this.dp(p5)));
        return;
    }

    private int blend(int p7)
    {
        return android.graphics.Color.rgb(((int) (((double) android.graphics.Color.red(p7)) * 4605380978949069210)), ((int) (((double) android.graphics.Color.green(p7)) * 4605380978949069210)), ((int) (((double) android.graphics.Color.blue(p7)) * 4605380978949069210)));
    }

    private android.widget.Button button(String p7, int p8, int p9)
    {
        android.graphics.drawable.GradientDrawable v3_1;
        android.widget.Button v0_1 = new android.widget.Button(this);
        v0_1.setText(p7);
        v0_1.setTextColor(p8);
        v0_1.setTextSize(1096810496);
        v0_1.setAllCaps(0);
        v0_1.setTypeface(android.graphics.Typeface.create("sans-serif-medium", 0));
        v0_1.setMinHeight(0);
        v0_1.setMinimumHeight(0);
        v0_1.setMinWidth(0);
        v0_1.setMinimumWidth(0);
        v0_1.setPadding(this.dp(12), this.dp(5), this.dp(12), this.dp(5));
        android.graphics.drawable.StateListDrawable v1_2 = new android.graphics.drawable.StateListDrawable();
        if (p9 != 0) {
            v3_1 = this.blend(p9);
        } else {
            v3_1 = android.graphics.Color.rgb(45, 53, 62);
        }
        v1_2.addState(new int[] {16842919}), this.shape(v3_1, 0, 12));
        int[] v2_4 = new int[0];
        v1_2.addState(v2_4, this.shape(p9, 0, 12));
        v0_1.setBackground(v1_2);
        return v0_1;
    }

    private void choosePreference()
    {
        new android.app.AlertDialog$Builder(this).setTitle("How should Dokkan Unit Creator open your AI?").setSingleChoiceItems(new String[] {"App first, then website", "Always use the browser"}), (this.prefs.getBoolean("preferApp", 1) ^ 1), new com.personal.aihub.MainActivity$6(this)).setNegativeButton("Cancel", 0).show();
        return;
    }

    private int dp(int p2)
    {
        return Math.round((((float) p2) * this.getResources().getDisplayMetrics().density));
    }

    static android.view.WindowInsets lambda$0(android.view.View p4, android.view.WindowInsets p5)
    {
        int v0_3 = p5.getInsets((android.view.WindowInsets$Type.systemBars() | android.view.WindowInsets$Type.displayCutout()));
        p4.setPadding(v0_3.left, v0_3.top, v0_3.right, v0_3.bottom);
        return p5;
    }

    private void launch(com.personal.aihub.Provider p3, boolean p4)
    {
        if (com.personal.aihub.LaunchCoordinator.open(p3, p4, this) == com.personal.aihub.LaunchCoordinator$Result.UNAVAILABLE) {
            int v4_5 = new android.app.AlertDialog$Builder(this);
            String v0_4 = new StringBuilder("Unable to open ");
            v0_4.append(p3.label);
            v4_5.setTitle(v0_4.toString()).setMessage("No available app or web browser could open this service. Install or enable a browser, then try again.").setPositiveButton("OK", 0).show();
        }
        return;
    }

    private void refreshStatus()
    {
        android.widget.Button v0_0 = com.personal.aihub.Provider.valuesCustom();
        int v1_0 = 0;
        while (v1_0 < this.badges.size()) {
            String v3_2;
            if (this.getPackageManager().getLaunchIntentForPackage(v0_0[v1_0].packageName) == null) {
                v3_2 = "OPENS WEBSITE";
            } else {
                v3_2 = "APP INSTALLED";
            }
            ((android.widget.TextView) this.badges.get(v1_0)).setText(v3_2);
            v1_0++;
        }
        android.widget.Button v0_1 = this.preference;
        if (v0_1 != null) {
            int v1_3;
            if (!this.prefs.getBoolean("preferApp", 1)) {
                v1_3 = "\u25ce  Always open in browser";
            } else {
                v1_3 = "\u2197  App first \u00b7 website if unavailable";
            }
            v0_1.setText(v1_3);
        }
        return;
    }

    private android.widget.LinearLayout row()
    {
        android.widget.LinearLayout v0_1 = new android.widget.LinearLayout(this);
        v0_1.setOrientation(0);
        v0_1.setGravity(16);
        return v0_1;
    }

    private android.graphics.drawable.GradientDrawable shape(int p2, int p3, int p4)
    {
        android.graphics.drawable.GradientDrawable v0_1 = new android.graphics.drawable.GradientDrawable();
        v0_1.setColor(p2);
        v0_1.setCornerRadius(((float) this.dp(p4)));
        if (p3 != 0) {
            v0_1.setStroke(this.dp(1), p3);
        }
        return v0_1;
    }

    private void showAbout()
    {
        new android.app.AlertDialog$Builder(this).setTitle("Your accounts. Your choice.").setMessage("Dokkan Unit Creator opens the official ChatGPT, Grok, and Claude apps or websites. Your existing subscriptions apply there, subject to each provider\u2019s plan.\n\nDokkan Unit Creator does not read chats, collect passwords, or use paid APIs. Conversations remain with each provider; the assistants do not share a conversation automatically.\n\nThis is an independent launcher, unaffiliated with OpenAI, xAI, or Anthropic.").setPositiveButton("Got it", 0).show();
        return;
    }

    private android.widget.TextView text(String p2, int p3, int p4, boolean p5)
    {
        android.widget.TextView v0_1 = new android.widget.TextView(this);
        v0_1.setText(p2);
        v0_1.setTextSize(((float) p3));
        v0_1.setTextColor(p4);
        v0_1.setFontFeatureSettings("kern");
        if (p5) {
            v0_1.setTypeface(android.graphics.Typeface.create("sans-serif-medium", 0));
        }
        v0_1.setLineSpacing(((float) this.dp(3)), 1065353216);
        v0_1.setGravity(16);
        return v0_1;
    }

    void m21lambda$1$compersonalaihubMainActivity(android.view.View p1)
    {
        this.showAbout();
        return;
    }

    void m22lambda$2$compersonalaihubMainActivity(android.view.View p1)
    {
        this.choosePreference();
        return;
    }

    void m23lambda$3$compersonalaihubMainActivity(com.personal.aihub.Provider p3, android.view.View p4)
    {
        this.launch(p3, this.prefs.getBoolean("preferApp", 1));
        return;
    }

    void m24lambda$4$compersonalaihubMainActivity(com.personal.aihub.Provider p1, android.view.View p2)
    {
        this.launch(p1, 0);
        return;
    }

    void m25lambda$5$compersonalaihubMainActivity(android.content.DialogInterface p3, int p4)
    {
        android.content.SharedPreferences$Editor v4_1;
        android.content.SharedPreferences$Editor vtmp1 = this.prefs.edit();
        if (p4 != null) {
            v4_1 = 0;
        } else {
            v4_1 = 1;
        }
        vtmp1.putBoolean("preferApp", v4_1).apply();
        p3.dismiss();
        this.refreshStatus();
        return;
    }

    public void onCreate(android.os.Bundle p14)
    {
        super.onCreate(p14);
        this.prefs = this.getSharedPreferences("orbit", 0);
        int v1_18 = com.personal.aihub.MainActivity.BG;
        this.getWindow().setStatusBarColor(v1_18);
        this.getWindow().setNavigationBarColor(v1_18);
        android.widget.TextView v14_6 = new android.widget.FrameLayout(this);
        v14_6.setBackgroundColor(v1_18);
        this.setContentView(v14_6);
        if (android.os.Build$VERSION.SDK_INT >= 30) {
            this.getWindow().setDecorFitsSystemWindows(0);
            v14_6.setOnApplyWindowInsetsListener(new com.personal.aihub.MainActivity$1(this));
        }
        int v1_12 = new android.widget.ScrollView(this);
        v1_12.setFillViewport(1);
        v14_6.addView(v1_12, new android.widget.FrameLayout$LayoutParams(-1, -1));
        android.widget.TextView v14_14 = new android.widget.FrameLayout(this);
        v1_12.addView(v14_14, new android.widget.FrameLayout$LayoutParams(-1, -2));
        int v1_14 = new android.widget.LinearLayout(this);
        this.content = v1_14;
        v1_14.setOrientation(1);
        this.content.setPadding(this.dp(24), this.dp(26), this.dp(24), this.dp(28));
        v14_14.addView(this.content, new android.widget.FrameLayout$LayoutParams(Math.min(this.getResources().getDisplayMetrics().widthPixels, this.dp(680)), -2, 49));
        android.widget.TextView v14_17 = this.row();
        int v1_17 = com.personal.aihub.MainActivity.LIME;
        android.widget.LinearLayout$LayoutParams v6_7 = this.text("\u25c9  AI ASSISTANTS", 16, v1_17, 1);
        v6_7.setLetterSpacing(1042536202);
        v14_17.addView(v6_7, new android.widget.LinearLayout$LayoutParams(0, this.dp(48), 1065353216));
        android.widget.LinearLayout$LayoutParams v6_8 = com.personal.aihub.MainActivity.TEXT;
        int v8_14 = this.button("About", v6_8, android.graphics.Color.rgb(34, 41, 48));
        v8_14.setTextSize(1095761920);
        v8_14.setOnClickListener(new com.personal.aihub.MainActivity$2(this));
        v14_17.addView(v8_14, new android.widget.LinearLayout$LayoutParams(this.dp(78), this.dp(48)));
        this.content.addView(v14_17);
        this.addSpace(30);
        this.content.addView(this.text("Your AI,\none place.", 40, v6_8, 1));
        this.addSpace(12);
        int v8_2 = com.personal.aihub.MainActivity.MUTED;
        this.content.addView(this.text("Pick your assistant. Keep your own accounts.", 16, v8_2, 0));
        this.addSpace(24);
        int v1_0 = this.button("", v1_17, android.graphics.Color.rgb(30, 40, 30));
        this.preference = v1_0;
        v1_0.setTextSize(1095761920);
        this.preference.setOnClickListener(new com.personal.aihub.MainActivity$3(this));
        this.content.addView(this.preference, new android.widget.LinearLayout$LayoutParams(-1, this.dp(50)));
        this.addSpace(24);
        int v1_4 = this.text("YOUR ASSISTANTS", 11, v8_2, 1);
        v1_4.setLetterSpacing(1041194025);
        this.content.addView(v1_4);
        this.addSpace(12);
        android.widget.TextView v14_7 = com.personal.aihub.Provider.valuesCustom();
        int v1_5 = v14_7.length;
        String v2_7 = 0;
        while (v2_7 < v1_5) {
            this.addProvider(v14_7[v2_7]);
            this.addSpace(14);
            v2_7++;
        }
        this.addSpace(6);
        int v1_6 = com.personal.aihub.MainActivity.MUTED;
        this.content.addView(this.text("Your subscriptions stay with each provider. Sign in in their app or website.", 13, v1_6, 0));
        this.addSpace(18);
        android.widget.TextView v14_12 = this.text("DOKKAN UNIT CREATION  /  AI ASSISTANTS", 10, v1_6, 1);
        v14_12.setLetterSpacing(1040522936);
        this.content.addView(v14_12);
        return;
    }

    public void onResume()
    {
        super.onResume();
        this.refreshStatus();
        return;
    }

    public boolean openApp(com.personal.aihub.Provider p3)
    {
        try {
            int v3_2 = this.getPackageManager().getLaunchIntentForPackage(p3.packageName);
        } catch (SecurityException) {
            return 0;
        }
        if (v3_2 != 0) {
            this.startActivity(v3_2);
            return 1;
        } else {
            return 0;
        }
    }

    public boolean openWebsite(com.personal.aihub.Provider p10)
    {
        String v0_5 = new android.content.Intent("android.intent.action.VIEW", android.net.Uri.parse("https://example.org/"));
        v0_5.addCategory("android.intent.category.BROWSABLE");
        int v3_1 = this.getPackageManager();
        android.content.Intent v5_0 = v3_1.queryIntentActivities(v0_5, 65536);
        android.net.Uri v6_1 = new java.util.ArrayList();
        android.content.Intent v5_1 = v5_0.iterator();
        while (v5_1.hasNext()) {
            String v7_4 = ((android.content.pm.ResolveInfo) v5_1.next()).activityInfo.packageName;
            if ((!v6_1.contains(v7_4)) && (!v7_4.equals(this.getPackageName()))) {
                v6_1.add(v7_4);
            }
        }
        String v0_1 = v3_1.resolveActivity(v0_5, 65536);
        if ((v0_1 != null) && (v6_1.remove(v0_1.activityInfo.packageName))) {
            v6_1.add(0, v0_1.activityInfo.packageName);
        }
        String v0_4 = v6_1.iterator();
        while (v0_4.hasNext()) {
            String v4_6 = ((String) v0_4.next());
            android.content.Intent v5_3 = new android.content.Intent("android.intent.action.VIEW", android.net.Uri.parse(p10.website));
            v5_3.addCategory("android.intent.category.BROWSABLE");
            v5_3.setPackage(v4_6);
            this.startActivity(v5_3);
            p10 = 1;
            return 1;
        }
        return 0;
    }
}
