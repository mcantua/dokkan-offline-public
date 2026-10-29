package com.personal.aihub;
 class ConverterActivity$AnonymousClass1 extends android.webkit.WebViewClient {
    final synthetic com.personal.aihub.ConverterActivity this$0;

    ConverterActivity$AnonymousClass1(com.personal.aihub.ConverterActivity p1)
    {
        this.this$0 = p1;
        return;
    }

    void m7lambda$0$compersonalaihubConverterActivity$1()
    {
        this.this$0.recreate();
        return;
    }

    public void onPageFinished(android.webkit.WebView p5, String p6)
    {
        if (("https".equals(android.net.Uri.parse(p6).getScheme())) && ("dokkan-eclipse.com".equals(android.net.Uri.parse(p6).getHost()))) {
            try {
                Throwable v5_5 = this.this$0.getAssets().open("ui/converter-page.js");
                try {
                    Throwable v6_4 = new java.io.ByteArrayOutputStream();
                } catch (Throwable v6_6) {
                    if (v5_5 != null) {
                        try {
                            v5_5.close();
                        } catch (Throwable v5_8) {
                            v6_6.addSuppressed(v5_8);
                        }
                    }
                    throw v6_6;
                }
                try {
                    android.webkit.WebView v0_1 = new byte[8192];
                } catch (android.webkit.WebView v0_5) {
                    try {
                        v6_4.close();
                    } catch (Throwable v6_5) {
                        v0_5.addSuppressed(v6_5);
                    }
                    throw v0_5;
                }
                while(true) {
                    String v1_0 = v5_5.read(v0_1);
                    if (v1_0 == -1) {
                        break;
                    }
                    v6_4.write(v0_1, 0, v1_0);
                }
                android.webkit.WebView v0_3 = com.personal.aihub.ConverterActivity.access$200(this.this$0);
                String v1_2 = new StringBuilder();
                v1_2.append("window.__forgePatch=");
                v1_2.append(new org.json.JSONObject(com.personal.aihub.ConverterActivity.access$300(this.this$0)).toString());
                v1_2.append(";");
                v1_2.append(v6_4.toString("UTF-8"));
                v0_3.evaluateJavascript(v1_2.toString(), 0);
                v6_4.close();
                if (v5_5 != null) {
                    v5_5.close();
                }
            } catch (Exception) {
                com.personal.aihub.ConverterActivity.access$100(this.this$0).setText("Choose the patch ZIP and enter its metadata on Eclipse\u2019s converter.");
            }
        }
        return;
    }

    public void onReceivedError(android.webkit.WebView p1, android.webkit.WebResourceRequest p2, android.webkit.WebResourceError p3)
    {
        if (p2.isForMainFrame()) {
            com.personal.aihub.ConverterActivity.access$100(this.this$0).setText("Connection failed. Check Internet access and tap Converter to retry.");
        }
        return;
    }

    public boolean onRenderProcessGone(android.webkit.WebView p2, android.webkit.RenderProcessGoneDetail p3)
    {
        if ((p2.getParent() instanceof android.view.ViewGroup)) {
            ((android.view.ViewGroup) p2.getParent()).removeView(p2);
        }
        p2.destroy();
        com.personal.aihub.ConverterActivity.access$202(this.this$0, 0);
        com.personal.aihub.WebViewFailure.show(this.this$0, "converter", new com.personal.aihub.ConverterActivity$AnonymousClass1$1(this));
        return 1;
    }

    public boolean shouldOverrideUrlLoading(android.webkit.WebView p1, android.webkit.WebResourceRequest p2)
    {
        return (com.personal.aihub.ConverterActivity.allowed(p2.getUrl().toString(), 0) ^ 1);
    }
}
