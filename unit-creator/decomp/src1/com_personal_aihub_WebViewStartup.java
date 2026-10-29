package com.personal.aihub;
final class WebViewStartup {
    private static final long NOTICE_AFTER_MS = 45000;
    private final android.app.Activity activity;
    private boolean closed;
    private final android.widget.LinearLayout content;
    private long epoch;
    private final android.os.Handler handler;
    private final android.widget.TextView message;
    private final android.widget.ScrollView overlay;
    private String phase;
    private boolean probingWorkspace;
    private final android.widget.Button reportButton;
    private final android.widget.Button retryButton;
    private final String screen;
    private final android.widget.ProgressBar spinner;
    private String stage;
    private long started;
    private final android.widget.TextView title;
    private final android.widget.Button waitButton;
    private android.webkit.WebView web;

    public static synthetic void $r8$lambda$Nr7AFoG44zQXMBr3YK0Yr9GH898(com.personal.aihub.WebViewStartup p0)
    {
        p0.copyReport();
        return;
    }

    WebViewStartup(android.app.Activity p8, android.widget.FrameLayout p9, String p10, Runnable p11)
    {
        this.handler = new android.os.Handler(android.os.Looper.getMainLooper());
        this.phase = "created";
        this.stage = "created";
        this.activity = p8;
        this.screen = p10;
        android.widget.ScrollView v0_2 = new android.widget.ScrollView(p8);
        this.overlay = v0_2;
        v0_2.setFillViewport(1);
        android.widget.LinearLayout v2_1 = new android.widget.LinearLayout(p8);
        this.content = v2_1;
        v2_1.setOrientation(1);
        v2_1.setGravity(16);
        v0_2.addView(v2_1);
        int v3_5 = ((int) (p8.getResources().getDisplayMetrics().density * 1103101952));
        v2_1.setPadding(v3_5, v3_5, v3_5, v3_5);
        v0_2.setBackgroundColor(-15654870);
        android.widget.TextView v5_2 = new android.widget.ProgressBar(p8);
        this.spinner = v5_2;
        v2_1.addView(v5_2);
        android.widget.TextView v5_4 = new android.widget.TextView(p8);
        this.title = v5_4;
        v5_4.setTextColor(-789003);
        v5_4.setTextSize(1103101952);
        v2_1.addView(v5_4);
        android.widget.TextView v4_2 = new android.widget.TextView(p8);
        this.message = v4_2;
        v4_2.setTextColor(-3418405);
        v4_2.setTextSize(1098907648);
        v4_2.setPadding(0, (v3_5 / 2), 0, (v3_5 / 2));
        v4_2.setAccessibilityLiveRegion(1);
        v2_1.addView(v4_2);
        this.retryButton = this.button("Try again", new com.personal.aihub.WebViewStartup$$ExternalSyntheticLambda2(this, p11));
        this.waitButton = this.button("Keep waiting", new com.personal.aihub.WebViewStartup$$ExternalSyntheticLambda3(this, p10));
        this.reportButton = this.button("Copy startup report", new com.personal.aihub.WebViewStartup$$ExternalSyntheticLambda4(this));
        p9.addView(v0_2, new android.widget.FrameLayout$LayoutParams(-1, -1));
        v0_2.setVisibility(8);
        return;
    }

    private android.widget.Button button(String p4, Runnable p5)
    {
        android.widget.Button v0_1 = new android.widget.Button(this.activity);
        v0_1.setText(p4);
        v0_1.setOnClickListener(new com.personal.aihub.WebViewStartup$$ExternalSyntheticLambda6(p5));
        this.content.addView(v0_1, new android.widget.LinearLayout$LayoutParams(-1, -2));
        return v0_1;
    }

    private void copyReport()
    {
        try {
            ((android.content.ClipboardManager) this.activity.getSystemService("clipboard")).setPrimaryClip(android.content.ClipData.newPlainText("Dokkan Unit Creator startup", this.diagnostics().toString(2)));
            this.message.setText("Startup report copied. You can paste it into your support conversation. It contains device and startup details, without unit data, account details, or preview links.");
        } catch (Exception) {
            this.message.setText("Could not copy the report. You can still retry or return to the previous screen.");
        }
        return;
    }

    private void disableRetry()
    {
        this.retryButton.setEnabled(0);
        return;
    }

    private void finish(android.webkit.WebView p1, long p2, String p4)
    {
        if (this.current(p1, p2)) {
            this.handler.removeCallbacksAndMessages(0);
            this.phase = p4;
            this.overlay.setVisibility(8);
            return;
        } else {
            return;
        }
    }

    static synthetic void lambda$button$2(Runnable p0, android.view.View p1)
    {
        p0.run();
        return;
    }

    private void probeWorkspace(android.webkit.WebView p2, long p3)
    {
        if (this.current(p2, p3)) {
            p2.evaluateJavascript("String(window.__forgeWorkspaceStartup || \'loading\')", new com.personal.aihub.WebViewStartup$$ExternalSyntheticLambda0(this, p2, p3));
            return;
        } else {
            return;
        }
    }

    private void slow(String p3)
    {
        this.phase = "not-responding";
        this.title.setText("Taking longer than usual");
        this.message.setText(p3);
        this.spinner.setVisibility(8);
        this.retryButton.setVisibility(0);
        this.waitButton.setVisibility(0);
        this.reportButton.setVisibility(0);
        return;
    }

    long begin(android.webkit.WebView p7)
    {
        if (!this.closed) {
            this.handler.removeCallbacksAndMessages(0);
            this.web = p7;
            this.epoch = (this.epoch + 1);
            this.started = android.os.SystemClock.elapsedRealtime();
            this.phase = "loading";
            this.stage = "navigation";
            this.probingWorkspace = 0;
            android.widget.ScrollView v1_0 = this.title;
            android.os.Handler v2_1 = new StringBuilder("Opening ");
            v2_1.append(this.screen);
            v1_0.setText(v2_1.toString());
            this.message.setText("Preparing this screen. Your saved units stay on this device.");
            this.spinner.setVisibility(0);
            this.retryButton.setEnabled(1);
            this.retryButton.setVisibility(8);
            this.waitButton.setVisibility(8);
            this.reportButton.setVisibility(8);
            this.overlay.setVisibility(0);
            long v0_6 = this.epoch;
            this.handler.postDelayed(new com.personal.aihub.WebViewStartup$$ExternalSyntheticLambda1(this, p7, v0_6), 45000);
            return v0_6;
        } else {
            return -1;
        }
    }

    void close()
    {
        this.closed = 1;
        this.epoch = (this.epoch + 1);
        this.phase = "closed";
        this.handler.removeCallbacksAndMessages(0);
        this.web = 0;
        this.overlay.setVisibility(8);
        return;
    }

    boolean controlsReady()
    {
        if ((this.closed) || (!"ready".equals(this.phase))) {
            int v0_3 = 0;
        } else {
            v0_3 = 1;
        }
        return v0_3;
    }

    boolean current(android.webkit.WebView p3, long p4)
    {
        if ((this.closed) || ((this.web != p3) || ((this.epoch != p4) || ((this.activity.isFinishing()) || (this.activity.isDestroyed()))))) {
            int v3_3 = 0;
        } else {
            v3_3 = 1;
        }
        return v3_3;
    }

    org.json.JSONObject diagnostics()
    {
        org.json.JSONObject v1_1 = new org.json.JSONObject();
        try {
            String v6_3;
            org.json.JSONObject v2_0 = this.activity.getPackageManager().getPackageInfo(this.activity.getPackageName(), 0);
            String v3_0 = android.webkit.WebView.getCurrentWebViewPackage();
            String v4_3 = v1_1.put("kind", "dokkan-unit-creation-startup").put("schemaVersion", 1).put("appVersion", v2_0.versionName);
        } catch (org.json.JSONObject v2_13) {
            v1_1.put("phase", this.phase).put("reportError", v2_13.getClass().getSimpleName());
            return v1_1;
        } catch (Exception) {
            return v1_1;
        }
        if (android.os.Build$VERSION.SDK_INT < 28) {
            v6_3 = ((long) v2_0.versionCode);
        } else {
            v6_3 = v2_0.getLongVersionCode();
        }
        String v6_4;
        org.json.JSONObject v2_11 = v4_3.put("versionCode", v6_3).put("androidAPI", android.os.Build$VERSION.SDK_INT).put("deviceModel", android.os.Build.MODEL).put("screen", this.screen).put("phase", this.phase).put("stage", this.stage).put("navigation", this.epoch).put("elapsedMs", Math.max(0, (android.os.SystemClock.elapsedRealtime() - this.started)));
        String v5_12 = "unavailable";
        if (v3_0 != null) {
            v6_4 = v3_0.packageName;
        } else {
            v6_4 = "unavailable";
        }
        org.json.JSONObject v2_12 = v2_11.put("webViewPackage", v6_4);
        if (v3_0 != null) {
            v5_12 = v3_0.versionName;
        } else {
        }
        v2_12.put("webViewVersion", v5_12).put("scope", "Screen startup only; no animation playback or gameplay verification.");
        return v1_1;
    }

    long epoch()
    {
        return this.epoch;
    }

    void failed(android.webkit.WebView p1, long p2, String p4)
    {
        if (this.current(p1, p2)) {
            this.handler.removeCallbacksAndMessages(0);
            this.slow(p4);
            return;
        } else {
            return;
        }
    }

    synthetic void lambda$begin$3$com-personal-aihub-WebViewStartup(android.webkit.WebView p1, long p2)
    {
        if ((this.current(p1, p2)) && ((!"ready".equals(this.phase)) && (!"workspace-error".equals(this.phase)))) {
            this.slow("This screen has not responded yet. Keep waiting, try again, or copy a report to help diagnose it.");
        }
        return;
    }

    synthetic void lambda$new$0$com-personal-aihub-WebViewStartup(Runnable p3)
    {
        if (!this.closed) {
            this.phase = "retry-requested";
            this.handler.removeCallbacksAndMessages(0);
            this.disableRetry();
            p3.run();
            return;
        } else {
            return;
        }
    }

    synthetic void lambda$new$1$com-personal-aihub-WebViewStartup(String p4)
    {
        this.phase = "waiting";
        int v0_3 = this.title;
        StringBuilder v1_1 = new StringBuilder("Opening ");
        v1_1.append(p4);
        v0_3.setText(v1_1.toString());
        this.message.setText("Waiting for Android to open this screen. You can retry or copy a report at any time.");
        this.spinner.setVisibility(0);
        return;
    }

    synthetic void lambda$probeWorkspace$4$com-personal-aihub-WebViewStartup(android.webkit.WebView p1, long p2)
    {
        this.probeWorkspace(p1, p2);
        return;
    }

    synthetic void lambda$probeWorkspace$5$com-personal-aihub-WebViewStartup(android.webkit.WebView p2, long p3, String p5)
    {
        if (this.current(p2, p3)) {
            if (!"\"ready\"".equals(p5)) {
                if (!"\"failed\"".equals(p5)) {
                    this.handler.postDelayed(new com.personal.aihub.WebViewStartup$$ExternalSyntheticLambda5(this, p2, p3), 500);
                } else {
                    this.finish(p2, p3, "workspace-error");
                }
            } else {
                this.ready(p2, p3);
            }
            return;
        } else {
            return;
        }
    }

    void ready(android.webkit.WebView p2, long p3)
    {
        this.finish(p2, p3, "ready");
        return;
    }

    void stage(android.webkit.WebView p1, long p2, String p4)
    {
        if (this.current(p1, p2)) {
            this.stage = p4;
        }
        return;
    }

    void workspaceFinished(android.webkit.WebView p4)
    {
        if ((!this.probingWorkspace) && ((!"ready".equals(this.phase)) && (!"workspace-error".equals(this.phase)))) {
            this.probingWorkspace = 1;
            long v0_3 = this.epoch;
            this.stage(p4, v0_3, "workspace-startup");
            this.probeWorkspace(p4, v0_3);
        }
        return;
    }
}
