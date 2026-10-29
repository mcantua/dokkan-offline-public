package com.personal.aihub;
public final class PreviewActivity extends android.app.Activity {
    private com.personal.aihub.PreviewBootstrap bootstrap;
    private long bootstrapEpoch;
    private java.io.File directory;
    private com.personal.aihub.StageExport recordingExport;
    private com.personal.aihub.PreviewServer server;
    private com.personal.aihub.WebViewStartup startup;
    private android.webkit.WebView web;

    public PreviewActivity()
    {
        this.bootstrapEpoch = -1;
        return;
    }

    static synthetic com.personal.aihub.WebViewStartup access$000(com.personal.aihub.PreviewActivity p0)
    {
        return p0.startup;
    }

    static synthetic com.personal.aihub.PreviewServer access$100(com.personal.aihub.PreviewActivity p0)
    {
        return p0.server;
    }

    static synthetic com.personal.aihub.PreviewBootstrap access$202(com.personal.aihub.PreviewActivity p0, com.personal.aihub.PreviewBootstrap p1)
    {
        p0.bootstrap = p1;
        return p1;
    }

    static synthetic long access$300(com.personal.aihub.PreviewActivity p2)
    {
        return p2.bootstrapEpoch;
    }

    static synthetic long access$302(com.personal.aihub.PreviewActivity p0, long p1)
    {
        p0.bootstrapEpoch = p1;
        return p1;
    }

    static synthetic android.webkit.WebView access$400(com.personal.aihub.PreviewActivity p0)
    {
        return p0.web;
    }

    static synthetic android.webkit.WebView access$402(com.personal.aihub.PreviewActivity p0, android.webkit.WebView p1)
    {
        p0.web = p1;
        return p1;
    }

    static synthetic void access$500(com.personal.aihub.PreviewActivity p0, android.webkit.WebView p1, com.personal.aihub.PreviewBootstrap p2, long p3, int p5, String p6, android.widget.TextView p7)
    {
        p0.sendBootstrap(p1, p2, p3, p5, p6, p7);
        return;
    }

    static android.view.WindowInsets lambda$0(android.view.View p4, android.view.WindowInsets p5)
    {
        int v0_3 = p5.getInsets((android.view.WindowInsets$Type.systemBars() | android.view.WindowInsets$Type.displayCutout()));
        p4.setPadding(v0_3.left, v0_3.top, v0_3.right, v0_3.bottom);
        return p5;
    }

    public static String read(java.io.InputStream p6, int p7)
    {
        try {
            Throwable v0_1 = new java.io.ByteArrayOutputStream();
        } catch (java.io.IOException v7_6) {
            if (p6 != null) {
                try {
                    p6.close();
                } catch (Throwable v6_1) {
                    v7_6.addSuppressed(v6_1);
                }
            }
            throw v7_6;
        }
        try {
            String v1_2 = new byte[8192];
            int v3 = 0;
        } catch (java.io.IOException v7_5) {
            try {
                v0_1.close();
            } catch (Throwable v0_2) {
                v7_5.addSuppressed(v0_2);
            }
            throw v7_5;
        }
        while(true) {
            int v4 = p6.read(v1_2);
            if (v4 == -1) {
                java.io.IOException v7_2 = v0_1.toString("UTF-8");
                v0_1.close();
                if (p6 != null) {
                    p6.close();
                }
                return v7_2;
            } else {
                v3 += v4;
                if (v3 > p7) {
                    break;
                }
                v0_1.write(v1_2, 0, v4);
            }
        }
        throw new java.io.IOException("Preview too large");
    }

    private void sendBootstrap(android.webkit.WebView p14, com.personal.aihub.PreviewBootstrap p15, long p16, int p18, String p19, android.widget.TextView p20)
    {
        com.personal.aihub.PreviewActivity$$ExternalSyntheticLambda1 v0_4 = this.startup;
        if ((v0_4 != null) && ((v0_4.current(p14, p16)) && (this.bootstrap == p15))) {
            com.personal.aihub.PreviewActivity$$ExternalSyntheticLambda1 v0_2;
            if (p18 >= 0) {
                if (p18 >= p15.chunkCount()) {
                    v0_2 = p15.mountScript(p19);
                } else {
                    v0_2 = p15.chunkScript(p18);
                }
            } else {
                v0_2 = p15.beginScript();
            }
            String v11 = v0_2;
            com.personal.aihub.PreviewActivity$$ExternalSyntheticLambda1 v12 = new com.personal.aihub.PreviewActivity$$ExternalSyntheticLambda1;
            v12(this, p14, p16, p15, p20, p18, p19);
            p14.evaluateJavascript(v11, v12);
        }
        return;
    }

    synthetic void lambda$sendBootstrap$0$com-personal-aihub-PreviewActivity(android.webkit.WebView p10, long p11, com.personal.aihub.PreviewBootstrap p13, android.widget.TextView p14, int p15, String p16, String p17)
    {
        long v3 = p11;
        if ((this.startup.current(p10, p11)) && (this.bootstrap == p13)) {
            if ("true".equals(p17)) {
                if (p15 != p13.chunkCount()) {
                    this.sendBootstrap(p10, p13, p11, (p15 + 1), p16, p14);
                } else {
                    this.startup.stage(p10, p11, "controls-ready");
                    this.startup.ready(p10, p11);
                }
            } else {
                p10.evaluateJavascript(p13.cancelScript(), 0);
                p14.setText("This preview did not finish opening. Reopen it to try again.");
                this.startup.failed(p10, p11, "This animation screen did not finish opening. Try again or copy a startup report.");
                return;
            }
        }
        return;
    }

    void m26lambda$1$compersonalaihubPreviewActivity(android.view.View p1)
    {
        this.finish();
        return;
    }

    void m27lambda$2$compersonalaihubPreviewActivity(String p4, android.widget.TextView p5, android.view.View p6)
    {
        try {
            StringBuilder v2_1 = new StringBuilder("https://play.google.com/store/apps/details?id=");
            v2_1.append(p4);
            this.startActivity(new android.content.Intent("android.intent.action.VIEW", android.net.Uri.parse(v2_1.toString())));
        } catch (Exception) {
            p5.setText("Update Android System WebView or Chrome through your device\u2019s app store.");
        }
        return;
    }

    void m28lambda$3$compersonalaihubPreviewActivity(android.widget.TextView p3, android.view.View p4)
    {
        try {
            this.startActivity(new android.content.Intent("android.intent.action.VIEW", android.net.Uri.parse("https://play.google.com/store/apps/details?id=com.google.android.webview")));
        } catch (Exception) {
            p3.setText("Update Android System WebView or Chrome through your device\u2019s app store, then reopen this preview.");
        }
        return;
    }

    void m29lambda$4$compersonalaihubPreviewActivity(android.view.View p1)
    {
        this.recreate();
        return;
    }

    protected void onActivityResult(int p2, int p3, android.content.Intent p4)
    {
        super.onActivityResult(p2, p3, p4);
        com.personal.aihub.StageExport v0 = this.recordingExport;
        if (v0 != null) {
            v0.result(p2, p3, p4);
        }
        return;
    }

    public void onCreate(android.os.Bundle p31)
    {
        com.personal.aihub.PreviewActivity v12 = this;
        String v1_0 = "com.android.chrome";
        void v30_1 = super.onCreate(p31);
        com.personal.aihub.PreviewActivity$3 v2_4 = v30_1.getIntent().getStringExtra("token");
        if ((v2_4 != null) && (v2_4.matches("[a-f0-9-]{36}"))) {
            this.directory = new java.io.File(new java.io.File(v30_1.getCacheDir(), "animation-preview"), v2_4);
            com.personal.aihub.PreviewActivity$3 v2_18 = new java.io.File(this.directory, "request.json");
            if (v2_18.isFile()) {
                try {
                    String v8_2 = new org.json.JSONObject(com.personal.aihub.PreviewActivity.read(new java.io.FileInputStream(v2_18), 3145728));
                    com.personal.aihub.PreviewActivity$AnonymousClass1 v7_3 = new android.widget.LinearLayout(this);
                    v7_3.setOrientation(1);
                    v7_3.setBackgroundColor(-15391959);
                    this.setContentView(v7_3);
                } catch (Exception) {
                    v30_1.finish();
                    return;
                }
                if (android.os.Build$VERSION.SDK_INT >= 30) {
                    v30_1.getWindow().setDecorFitsSystemWindows(0);
                    v7_3.setOnApplyWindowInsetsListener(new com.personal.aihub.PreviewActivity$1(this));
                }
                com.personal.aihub.PreviewActivity$3 v2_27 = new android.widget.Button(this);
                v2_27.setText("Back to Animation Studio");
                v2_27.setOnClickListener(new com.personal.aihub.PreviewActivity$2(this));
                v7_3.addView(v2_27);
                android.widget.TextView v4_7 = new android.widget.TextView(this);
                v4_7.setTextColor(-1118482);
                v4_7.setPadding(16, 8, 16, 8);
                v4_7.setText("Animation preview \u2022 loaded resources are saved on this device");
                v7_3.addView(v4_7);
                String v3_26;
                com.personal.aihub.PreviewActivity$3 v2_31 = android.webkit.WebView.getCurrentWebViewPackage();
            }
        }
        v30_1.finish();
        return;
    }

    protected void onDestroy()
    {
        java.io.File v0_0 = this.startup;
        if (v0_0 != null) {
            v0_0.close();
        }
        this.bootstrap = 0;
        java.io.File v0_7 = this.web;
        if (v0_7 != null) {
            v0_7.stopLoading();
            this.web.destroy();
        }
        this.stopServer();
        if ((this.isFinishing()) && (this.directory != null)) {
            new java.io.File(this.directory, "request.json").delete();
            this.directory.delete();
        }
        super.onDestroy();
        return;
    }

    public void stopServer()
    {
        String v0_0 = this.server;
        if (v0_0 != null) {
            String v0_1 = v0_0.origin;
            String v1_4 = this.server.cookie;
            this.server.close();
            this.server = 0;
            android.webkit.CookieManager v3 = android.webkit.CookieManager.getInstance();
            StringBuilder v4_1 = new StringBuilder();
            v4_1.append(String.valueOf(v1_4));
            v4_1.append("; Path=/; Max-Age=0; HttpOnly; SameSite=Strict");
            v3.setCookie(v0_1, v4_1.toString(), 0);
        }
        return;
    }

    public void unreliableRuntime(android.widget.LinearLayout p3, android.widget.TextView p4, android.webkit.WebView p5)
    {
        com.personal.aihub.PreviewActivity$4 v0_0 = this.startup;
        if (v0_0 != null) {
            v0_0.close();
        }
        this.bootstrap = 0;
        if ((p5.getParent() instanceof android.view.ViewGroup)) {
            android.view.ViewGroup v1_1 = ((android.view.ViewGroup) p5.getParent());
            v1_1.removeView(p5);
            p3.removeView(v1_1);
        }
        this.web = 0;
        p5.stopLoading();
        p5.destroy();
        this.stopServer();
        p4.setText("This device could not run animation previews reliably. Update Android System WebView or Chrome, then restart the device and reopen this preview. If you use an Android emulator, update the emulator too. Your saved creations and imported files are still on this device.");
        com.personal.aihub.PreviewActivity$5 v5_3 = new android.widget.Button(this);
        v5_3.setText("Open WebView update page");
        v5_3.setOnClickListener(new com.personal.aihub.PreviewActivity$4(this, p4));
        p3.addView(v5_3);
        android.widget.Button v4_2 = new android.widget.Button(this);
        v4_2.setText("Reopen animation preview");
        v4_2.setOnClickListener(new com.personal.aihub.PreviewActivity$5(this));
        p3.addView(v4_2);
        return;
    }
}
