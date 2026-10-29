package com.personal.aihub;
public final class ConverterActivity extends android.app.Activity {
    private static final String HOME = "https://dokkan-eclipse.com/#convert-eclp";
    private String downloadAgent;
    private String downloadUrl;
    private String metadata;
    private java.io.File patch;
    private android.widget.TextView status;
    private String token;
    private android.webkit.WebView web;
    private final java.util.concurrent.ExecutorService worker;

    public ConverterActivity()
    {
        this.worker = java.util.concurrent.Executors.newSingleThreadExecutor();
        return;
    }

    static synthetic String access$000(com.personal.aihub.ConverterActivity p0)
    {
        return p0.token;
    }

    static synthetic android.widget.TextView access$100(com.personal.aihub.ConverterActivity p0)
    {
        return p0.status;
    }

    static synthetic android.webkit.WebView access$200(com.personal.aihub.ConverterActivity p0)
    {
        return p0.web;
    }

    static synthetic android.webkit.WebView access$202(com.personal.aihub.ConverterActivity p0, android.webkit.WebView p1)
    {
        p0.web = p1;
        return p1;
    }

    static synthetic String access$300(com.personal.aihub.ConverterActivity p0)
    {
        return p0.metadata;
    }

    public static boolean allowed(String p5, boolean p6)
    {
        try {
            boolean v5_2 = android.net.Uri.parse(p5);
        } catch (Exception) {
            return 0;
        }
        if ("https".equals(v5_2.getScheme())) {
            boolean v5_1 = v5_2.getHost();
            if (!"dokkan-eclipse.com".equals(v5_1)) {
                if (p6 == null) {
                    if (!java.util.Arrays.asList(new String[] {"discord.com", "www.discord.com", "discordapp.com", "www.discordapp.com"})).contains(v5_1)) {
                        return 0;
                    } else {
                        return 1;
                    }
                } else {
                    if (!"cdn.dokkan-eclipse.com".equals(v5_1)) {
                        return 0;
                    } else {
                        return 1;
                    }
                }
            } else {
                return 1;
            }
        } else {
            return 0;
        }
    }

    private void download(String p12, String p13, android.net.Uri p14)
    {
        String v1_0 = 0;
        while (v1_0 < 6) {
            java.net.HttpURLConnection v3 = 0;
            try {
                if (!com.personal.aihub.ConverterActivity.allowed(p12, 1)) {
                    throw new java.io.IOException("Unrecognized download destination");
                } else {
                    int v2_3 = new java.net.URL(p12);
                    java.net.HttpURLConnection v4_0 = ((java.net.HttpURLConnection) v2_3.openConnection());
                    try {
                        android.content.ContentResolver v6;
                        v4_0.setConnectTimeout(20000);
                        v4_0.setReadTimeout(60000);
                        v4_0.setInstanceFollowRedirects(0);
                    } catch (Throwable v12_3) {
                        this.getContentResolver().delete(p14, 0, 0);
                        throw v12_3;
                    }
                    if (p13 != null) {
                        v6 = p13;
                    } else {
                        v6 = "DokkanUnitCreator/2.1";
                    }
                    v4_0.setRequestProperty("User-Agent", v6);
                    Throwable v12_8 = android.webkit.CookieManager.getInstance().getCookie(p12);
                    if (v12_8 != null) {
                        v4_0.setRequestProperty("Cookie", v12_8);
                    }
                    Throwable v12_10 = v4_0.getResponseCode();
                    if ((v12_10 < 300) || (v12_10 >= 400)) {
                        if (v12_10 != 200) {
                            java.io.IOException v0_5 = new StringBuilder();
                            v0_5.append("Eclipse returned HTTP ");
                            v0_5.append(v12_10);
                            throw new java.io.IOException(v0_5.toString());
                        } else {
                            if (String.valueOf(v4_0.getContentType()).toLowerCase(java.util.Locale.ROOT).contains("text/html")) {
                                throw new java.io.IOException("The download link returned a web page. Sign in again or reconvert.");
                            } else {
                                Throwable v12_19 = v4_0.getInputStream();
                                try {
                                    Throwable v13_13 = this.getContentResolver().openOutputStream(p14, "w");
                                } catch (Throwable v13_2) {
                                    if (v12_19 != null) {
                                        try {
                                            v12_19.close();
                                        } catch (Throwable v12_1) {
                                            v13_2.addSuppressed(v12_1);
                                        }
                                    }
                                    throw v13_2;
                                }
                                if (v13_13 == null) {
                                    throw new java.io.IOException("Cannot write selected file");
                                } else {
                                    String v1_6 = new byte[65536];
                                    long v7 = 0;
                                    while(true) {
                                        int v2_5 = v12_19.read(v1_6);
                                        if (v2_5 == -1) {
                                            if (v7 == 0) {
                                                throw new java.io.IOException("Empty download");
                                            } else {
                                                if (v13_13 != null) {
                                                    v13_13.close();
                                                }
                                                if (v12_19 != null) {
                                                    v12_19.close();
                                                }
                                                if (v4_0 != null) {
                                                    v4_0.disconnect();
                                                }
                                                return;
                                            }
                                        } else {
                                            v7 += ((long) v2_5);
                                            if (v7 > 4294967296) {
                                                break;
                                            }
                                            v13_13.write(v1_6, 0, v2_5);
                                        }
                                    }
                                    throw new java.io.IOException("ECLP exceeds 4 GB");
                                }
                            }
                        }
                    } else {
                        p12 = new java.net.URL(v2_3, v4_0.getHeaderField("Location")).toString();
                        if (v4_0 != null) {
                            v4_0.disconnect();
                        }
                        v1_0++;
                    }
                }
                if (v3 != null) {
                    v3.disconnect();
                }
                throw Throwable v12_4;
            } catch (Throwable v12_3) {
                v4_0 = 0;
            } catch (Throwable v12_4) {
            } catch (Throwable v12_4) {
                v3 = v4_0;
            }
        }
        throw new java.io.IOException("Too many redirects");
    }

    static android.view.WindowInsets lambda$0(android.view.View p4, android.view.WindowInsets p5)
    {
        int v0_4 = p5.getInsets(((android.view.WindowInsets$Type.systemBars() | android.view.WindowInsets$Type.displayCutout()) | android.view.WindowInsets$Type.ime()));
        p4.setPadding(v0_4.left, v0_4.top, v0_4.right, v0_4.bottom);
        return p5;
    }

    void m0lambda$1$compersonalaihubConverterActivity(android.view.View p1)
    {
        this.finish();
        return;
    }

    void m1lambda$2$compersonalaihubConverterActivity(android.view.View p2)
    {
        this.web.loadUrl("https://dokkan-eclipse.com/#convert-eclp");
        return;
    }

    void m2lambda$3$compersonalaihubConverterActivity(android.view.View p2)
    {
        this.web.loadUrl("https://dokkan-eclipse.com/account");
        return;
    }

    void m3lambda$4$compersonalaihubConverterActivity(String p1, String p2, String p3, String p4, long p5)
    {
        if (this.downloadUrl == null) {
            if (com.personal.aihub.ConverterActivity.allowed(p1, 1)) {
                this.downloadUrl = p1;
                this.downloadAgent = p2;
                android.widget.TextView v1_1 = android.webkit.URLUtil.guessFileName(p1, p3, p4).replaceAll("[\\\\/:*?\"<>|\\x00-\\x1f]", "_");
                if (!v1_1.toLowerCase(java.util.Locale.ROOT).endsWith(".eclp")) {
                    v1_1 = "custom-unit.eclp";
                }
                try {
                    this.startActivityForResult(new android.content.Intent("android.intent.action.CREATE_DOCUMENT").addCategory("android.intent.category.OPENABLE").setType("application/octet-stream").putExtra("android.intent.extra.TITLE", v1_1), 701);
                } catch (Exception) {
                    this.downloadUrl = 0;
                    this.status.setText("Cannot open the system save dialog.");
                }
                return;
            } else {
                this.status.setText("Unsupported download address. Use the official converter download link.");
                return;
            }
        } else {
            this.status.setText("Finish saving the current download first.");
            return;
        }
    }

    void m4lambda$5$compersonalaihubConverterActivity(String p1, String p2, android.net.Uri p3)
    {
        try {
            this.download(p1, p2, p3);
            this.runOnUiThread(new com.personal.aihub.ConverterActivity$8(this));
        } catch (Exception v1_3) {
            this.runOnUiThread(new com.personal.aihub.ConverterActivity$9(this, v1_3));
        }
        return;
    }

    void m5lambda$6$compersonalaihubConverterActivity()
    {
        this.status.setText("ECLP saved. You can now import it into Eclipse.");
        return;
    }

    void m6lambda$7$compersonalaihubConverterActivity(Exception p4)
    {
        android.widget.TextView v0 = this.status;
        StringBuilder v1_1 = new StringBuilder("Download failed: ");
        v1_1.append(p4.getMessage());
        v1_1.append(". Tap the download link to retry.");
        v0.setText(v1_1.toString());
        return;
    }

    protected void onActivityResult(int p3, int p4, android.content.Intent p5)
    {
        super.onActivityResult(p3, p4, p5);
        if (p3 == 701) {
            String v3_1 = this.downloadUrl;
            String v0_1 = this.downloadAgent;
            this.downloadUrl = 0;
            if ((p4 == -1) && ((p5 != null) && ((p5.getData() != null) && (v3_1 != null)))) {
                android.net.Uri v4_2 = p5.getData();
                this.status.setText("Saving converted ECLP\u2026");
                this.worker.execute(new com.personal.aihub.ConverterActivity$7(this, v3_1, v0_1, v4_2));
            }
            return;
        } else {
            return;
        }
    }

    public void onBackPressed()
    {
        android.webkit.WebView v0_0 = this.web;
        if ((v0_0 != null) && (v0_0.canGoBack())) {
            this.web.goBack();
        } else {
            this.finish();
        }
        return;
    }

    public void onCreate(android.os.Bundle p7)
    {
        super.onCreate(p7);
        this.token = this.getIntent().getStringExtra("token");
        this.metadata = this.getIntent().getStringExtra("patch");
        android.webkit.WebView v7_8 = this.token;
        if ((v7_8 != null) && (v7_8.matches("[a-f0-9-]{36}"))) {
            android.webkit.WebView v7_12 = new java.io.File(new java.io.File(new java.io.File(this.getCacheDir(), "converter"), this.token), "unit-patch.zip");
            this.patch = v7_12;
            if (v7_12.isFile()) {
                android.webkit.WebView v7_15 = new android.widget.LinearLayout(this);
                v7_15.setOrientation(1);
                v7_15.setBackgroundColor(-15391959);
                this.setContentView(v7_15);
                if (android.os.Build$VERSION.SDK_INT >= 30) {
                    this.getWindow().setDecorFitsSystemWindows(0);
                    v7_15.setOnApplyWindowInsetsListener(new com.personal.aihub.ConverterActivity$1(this));
                }
                android.webkit.WebView v1_9 = new android.widget.LinearLayout(this);
                android.widget.LinearLayout$LayoutParams v2_4 = new android.widget.Button(this);
                v2_4.setText("Close");
                v2_4.setOnClickListener(new com.personal.aihub.ConverterActivity$2(this));
                v1_9.addView(v2_4);
                android.widget.LinearLayout$LayoutParams v2_6 = new android.widget.Button(this);
                v2_6.setText("Converter");
                v2_6.setOnClickListener(new com.personal.aihub.ConverterActivity$3(this));
                v1_9.addView(v2_6);
                android.widget.LinearLayout$LayoutParams v2_8 = new android.widget.Button(this);
                v2_8.setText("Sign in");
                v2_8.setOnClickListener(new com.personal.aihub.ConverterActivity$4(this));
                v1_9.addView(v2_8);
                v7_15.addView(v1_9);
                android.webkit.WebView v1_11 = new android.widget.TextView(this);
                this.status = v1_11;
                v1_11.setTextColor(-1118482);
                this.status.setPadding(16, 8, 16, 8);
                this.status.setText("Eclipse online \u2022 choose the prepared ZIP, convert, then download.");
                v7_15.addView(this.status);
                android.webkit.WebView v1_16 = new android.webkit.WebView(this);
                this.web = v1_16;
                v7_15.addView(v1_16, new android.widget.LinearLayout$LayoutParams(-1, 0, 1065353216));
                android.webkit.WebView v7_2 = this.web.getSettings();
                v7_2.setJavaScriptEnabled(1);
                v7_2.setDomStorageEnabled(1);
                v7_2.setAllowFileAccess(0);
                v7_2.setAllowContentAccess(1);
                v7_2.setMixedContentMode(1);
                this.web.setWebViewClient(new com.personal.aihub.ConverterActivity$AnonymousClass1(this));
                this.web.setWebChromeClient(new com.personal.aihub.ConverterActivity$5(this));
                this.web.setDownloadListener(new com.personal.aihub.ConverterActivity$6(this));
                this.web.loadUrl("https://dokkan-eclipse.com/#convert-eclp");
                return;
            } else {
                this.finish();
                return;
            }
        } else {
            this.finish();
            return;
        }
    }

    protected void onDestroy()
    {
        this.worker.shutdown();
        java.io.File v0_3 = this.web;
        if (v0_3 != null) {
            v0_3.stopLoading();
            this.web.destroy();
        }
        if ((this.patch != null) && (this.isFinishing())) {
            this.patch.delete();
        }
        super.onDestroy();
        return;
    }
}
