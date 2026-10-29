package com.personal.aihub;
 class PreviewActivity$AnonymousClass1 extends android.webkit.WebViewClient {
    final synthetic com.personal.aihub.PreviewActivity this$0;
    private final com.personal.aihub.PreviewCache val$cache;
    private final android.widget.LinearLayout val$layout;
    private final org.json.JSONObject val$request;
    private final android.widget.TextView val$status;

    PreviewActivity$AnonymousClass1(com.personal.aihub.PreviewActivity p1, com.personal.aihub.PreviewCache p2, android.widget.TextView p3, android.widget.LinearLayout p4, org.json.JSONObject p5)
    {
        this.this$0 = p1;
        this.val$cache = p2;
        this.val$status = p3;
        this.val$layout = p4;
        this.val$request = p5;
        return;
    }

    void m30lambda$0$compersonalaihubPreviewActivity$1(android.webkit.WebView p2, android.widget.TextView p3, String p4)
    {
        if (com.personal.aihub.PreviewActivity.access$400(this.this$0) == p2) {
            p3.setText(p4);
        }
        return;
    }

    void m31lambda$1$compersonalaihubPreviewActivity$1()
    {
        this.this$0.recreate();
        return;
    }

    void m32lambda$2$compersonalaihubPreviewActivity$1(android.webkit.WebView p14, String p15, android.widget.LinearLayout p16, android.widget.TextView p17, org.json.JSONObject p18, com.personal.aihub.PreviewCache p19, String p20)
    {
        if ((com.personal.aihub.PreviewActivity.access$400(this.this$0) == p14) && ((com.personal.aihub.PreviewActivity.access$100(this.this$0) != null) && ((!this.this$0.isFinishing()) && (p15.equals(p14.getUrl()))))) {
            long v11 = com.personal.aihub.PreviewActivity.access$300(this.this$0);
            try {
                String v5_1 = new StringBuilder("[");
                v5_1.append(p20);
                v5_1.append("]");
                com.personal.aihub.PreviewBootstrap v3_7 = new org.json.JSONObject(new org.json.JSONArray(v5_1.toString()).getString(0));
            } catch (Exception) {
                p17.setText("Could not prepare this preview. Return and try a shorter sequence.");
                com.personal.aihub.PreviewActivity.access$000(this.this$0).failed(p14, v11, "Could not prepare this animation screen. Try a shorter sequence or copy a startup report.");
            }
            if (v3_7.optBoolean("healthy")) {
                com.personal.aihub.PreviewActivity v1_5;
                p18.put("offline", p19.offline());
                p18.put("localPreview", 1);
                long v4_5 = new com.personal.aihub.PreviewBootstrap(java.util.UUID.randomUUID().toString(), v3_7.getString("documentId"), p18.toString());
                android.content.res.AssetManager vtmp20 = this.this$0.getAssets();
                if (!p18.optString("mode").equals("movie")) {
                    v1_5 = "ui/animation-page.js";
                } else {
                    v1_5 = "ui/movie-page.js";
                }
                String v7 = com.personal.aihub.PreviewActivity.read(vtmp20.open(v1_5), 200000);
                com.personal.aihub.PreviewActivity.access$202(this.this$0, v4_5);
                com.personal.aihub.PreviewActivity.access$000(this.this$0).stage(p14, v11, "request-transfer");
                com.personal.aihub.PreviewActivity.access$500(this.this$0, p14, v4_5, v11, -1, v7, p17);
            } else {
                this.this$0.unreliableRuntime(p16, p17, p14);
                return;
            }
        }
        return;
    }

    public void onPageFinished(android.webkit.WebView p17, String p18)
    {
        if ((com.personal.aihub.PreviewActivity.access$100(this.this$0) != null) && ((com.personal.aihub.PreviewActivity.access$100(this.this$0).local(p18)) && (android.net.Uri.parse(p18).getPath().matches("/tools/(lua|lwf|usm)-player/.*")))) {
            long v12 = com.personal.aihub.PreviewActivity.access$000(this.this$0).epoch();
            if (com.personal.aihub.PreviewActivity.access$300(this.this$0) != v12) {
                com.personal.aihub.PreviewActivity.access$302(this.this$0, v12);
                com.personal.aihub.PreviewActivity.access$000(this.this$0).stage(p17, v12, "player-runtime");
                try {
                    com.personal.aihub.WebViewStartup v0_14 = new StringBuilder();
                    v0_14.append(com.personal.aihub.PreviewActivity.read(this.this$0.getAssets().open("ui/preview-runtime.js"), 20000));
                    v0_14.append(";JSON.stringify({healthy:Boolean(window.ForgePreviewRuntime && window.ForgePreviewRuntime.healthy()),documentId:String(window.__forgeNativeDocumentId||\'\')})");
                    String v14 = v0_14.toString();
                    com.personal.aihub.PreviewActivity$AnonymousClass1$3 v15 = new com.personal.aihub.PreviewActivity$AnonymousClass1$3;
                    v15(this, p17, v12, p18, this.val$layout, this.val$status, this.val$request, this.val$cache);
                    p17.evaluateJavascript(v14, v15);
                } catch (Exception) {
                    this.val$status.setText("Could not check the animation player. Return to the Studio and reopen this preview.");
                    com.personal.aihub.PreviewActivity.access$000(this.this$0).failed(p17, v12, "Could not check this animation screen. Try again or copy a startup report.");
                }
            } else {
                return;
            }
        }
        return;
    }

    public void onPageStarted(android.webkit.WebView p3, String p4, android.graphics.Bitmap p5)
    {
        if ((com.personal.aihub.PreviewActivity.access$000(this.this$0) != null) && ((com.personal.aihub.PreviewActivity.access$100(this.this$0) != null) && (com.personal.aihub.PreviewActivity.access$100(this.this$0).local(p4)))) {
            com.personal.aihub.PreviewActivity.access$202(this.this$0, 0);
            com.personal.aihub.PreviewActivity.access$302(this.this$0, -1);
            com.personal.aihub.PreviewActivity.access$000(this.this$0).begin(p3);
        }
        return;
    }

    public void onReceivedError(android.webkit.WebView p3, android.webkit.WebResourceRequest p4, android.webkit.WebResourceError p5)
    {
        if ((com.personal.aihub.PreviewActivity.access$400(this.this$0) == p3) && (p4.isForMainFrame())) {
            this.val$status.setText("Could not open the local animation player. Return to the Studio and reopen this preview.");
            if (com.personal.aihub.PreviewActivity.access$000(this.this$0) != null) {
                com.personal.aihub.PreviewActivity.access$000(this.this$0).failed(p3, com.personal.aihub.PreviewActivity.access$000(this.this$0).epoch(), "Could not open the animation screen. Try again or copy a startup report.");
            }
        }
        return;
    }

    public void onReceivedHttpError(android.webkit.WebView p3, android.webkit.WebResourceRequest p4, android.webkit.WebResourceResponse p5)
    {
        if (p5.getStatusCode() == 503) {
            String v4_6 = p4.getUrl().getPath();
            if ((v4_6 != null) && (!v4_6.startsWith("/account/"))) {
                String v4_4;
                if (!v4_6.startsWith("/_forge/stage-")) {
                    if (!this.val$cache.offline()) {
                        v4_4 = "A preview file could not be loaded. Check your connection or import the matching game assets, then retry. Player tools show the details.";
                    } else {
                        v4_4 = "A file needed for this preview is not saved on this device. Turn off Offline preview in Animation Studio, then load the animation again.";
                    }
                } else {
                    v4_4 = "The recording could not be captured or saved. Check the player message, then try again.";
                }
                this.this$0.runOnUiThread(new com.personal.aihub.PreviewActivity$AnonymousClass1$1(this, p3, this.val$status, v4_4));
            }
        }
        return;
    }

    public boolean onRenderProcessGone(android.webkit.WebView p2, android.webkit.RenderProcessGoneDetail p3)
    {
        if (com.personal.aihub.PreviewActivity.access$000(this.this$0) != null) {
            com.personal.aihub.PreviewActivity.access$000(this.this$0).close();
        }
        if ((p2.getParent() instanceof android.view.ViewGroup)) {
            ((android.view.ViewGroup) p2.getParent()).removeView(p2);
        }
        p2.destroy();
        com.personal.aihub.PreviewActivity.access$402(this.this$0, 0);
        this.this$0.stopServer();
        com.personal.aihub.WebViewFailure.show(this.this$0, "animation preview", new com.personal.aihub.PreviewActivity$AnonymousClass1$2(this));
        return 1;
    }

    public android.webkit.WebResourceResponse shouldInterceptRequest(android.webkit.WebView p8, android.webkit.WebResourceRequest p9)
    {
        if ((com.personal.aihub.PreviewActivity.access$100(this.this$0) != null) && (com.personal.aihub.PreviewActivity.access$100(this.this$0).local(p9.getUrl().toString()))) {
            return 0;
        } else {
            int v8_3 = new android.webkit.WebResourceResponse;
            v8_3("text/plain", "UTF-8", 403, "Blocked", java.util.Collections.singletonMap("Cache-Control", "no-store"), new java.io.ByteArrayInputStream("Preview requests must use the isolated local player.".getBytes(java.nio.charset.StandardCharsets.UTF_8)));
            return v8_3;
        }
    }

    public boolean shouldOverrideUrlLoading(android.webkit.WebView p1, android.webkit.WebResourceRequest p2)
    {
        if ((com.personal.aihub.PreviewActivity.access$100(this.this$0) != null) && (com.personal.aihub.PreviewActivity.access$100(this.this$0).local(p2.getUrl().toString()))) {
            int v1_2 = 0;
        } else {
            v1_2 = 1;
        }
        return v1_2;
    }
}
