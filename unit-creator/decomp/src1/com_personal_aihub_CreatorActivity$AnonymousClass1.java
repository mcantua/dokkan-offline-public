package com.personal.aihub;
 class CreatorActivity$AnonymousClass1 extends android.webkit.WebViewClient {
    final synthetic com.personal.aihub.CreatorActivity this$0;

    CreatorActivity$AnonymousClass1(com.personal.aihub.CreatorActivity p1)
    {
        this.this$0 = p1;
        return;
    }

    void m18lambda$0$compersonalaihubCreatorActivity$1()
    {
        this.this$0.recreate();
        return;
    }

    public void onPageFinished(android.webkit.WebView p2, String p3)
    {
        if ((com.personal.aihub.CreatorActivity.access$000(this.this$0) != null) && ("forge.local".equals(android.net.Uri.parse(p3).getHost()))) {
            com.personal.aihub.CreatorActivity.access$000(this.this$0).workspaceFinished(p2);
        }
        return;
    }

    public void onPageStarted(android.webkit.WebView p1, String p2, android.graphics.Bitmap p3)
    {
        if ((com.personal.aihub.CreatorActivity.access$000(this.this$0) != null) && ("forge.local".equals(android.net.Uri.parse(p2).getHost()))) {
            com.personal.aihub.CreatorActivity.access$000(this.this$0).begin(p1);
        }
        return;
    }

    public void onReceivedError(android.webkit.WebView p3, android.webkit.WebResourceRequest p4, android.webkit.WebResourceError p5)
    {
        if ((p4.isForMainFrame()) && (com.personal.aihub.CreatorActivity.access$000(this.this$0) != null)) {
            com.personal.aihub.CreatorActivity.access$000(this.this$0).failed(p3, com.personal.aihub.CreatorActivity.access$000(this.this$0).epoch(), "Could not open the workspace screen. Try again or copy a startup report. Your saved units stay on this device.");
        }
        return;
    }

    public boolean onRenderProcessGone(android.webkit.WebView p2, android.webkit.RenderProcessGoneDetail p3)
    {
        com.personal.aihub.CreatorActivity$AnonymousClass1$1 v3_0 = this.this$0;
        com.personal.aihub.ForgeFixes.noteRendererCrash(v3_0);
        if (com.personal.aihub.CreatorActivity.access$000(v3_0) != null) {
            com.personal.aihub.CreatorActivity.access$000(this.this$0).close();
        }
        if ((p2.getParent() instanceof android.view.ViewGroup)) {
            ((android.view.ViewGroup) p2.getParent()).removeView(p2);
        }
        p2.destroy();
        com.personal.aihub.CreatorActivity.access$102(this.this$0, 0);
        com.personal.aihub.WebViewFailure.show(this.this$0, "creator", new com.personal.aihub.CreatorActivity$AnonymousClass1$1(this));
        return 1;
    }

    public android.webkit.WebResourceResponse shouldInterceptRequest(android.webkit.WebView p11, android.webkit.WebResourceRequest p12)
    {
        boolean v0_0 = com.personal.aihub.ForgeFixes.intercept(p12);
        if (!v0_0) {
            boolean v12_3 = p12.getUrl();
            String v1_0 = 0;
            if ("forge.local".equals(v12_3.getHost())) {
                try {
                    boolean v12_2 = v12_3.getPath().substring(1);
                } catch (Exception) {
                    java.io.InputStream v11_6 = new android.webkit.WebResourceResponse;
                    boolean v12_7 = new byte[0];
                    v11_6("text/plain", "UTF-8", 404, "Not Found", java.util.Collections.emptyMap(), new java.io.ByteArrayInputStream(v12_7));
                    return v11_6;
                }
                if (v12_2.isEmpty()) {
                    v12_2 = "index.html";
                }
                java.io.InputStream v11_2;
                if (v12_2.startsWith("local-asset/")) {
                    v11_2 = new java.io.FileInputStream(this.this$0.assetFile(v12_2.substring(12)));
                } else {
                    if ((!com.personal.aihub.CreatorActivity.safePath(v12_2)) || ((v12_2.startsWith("data/")) && ((!v12_2.equals("data/mechanics.js")) && ((!v12_2.equals("data/guide-data.js")) && ((!v12_2.equals("data/animation-availability.js")) && ((!v12_2.equals("data/movie-catalog.js")) && (!v12_2.equals("data/sparking-reference.json")))))))) {
                        throw new java.io.IOException("Unavailable resource");
                    } else {
                        boolean v0_24 = this.this$0.getAssets();
                        StringBuilder v2_3 = new StringBuilder("ui/");
                        v2_3.append(v12_2);
                        v11_2 = v0_24.open(v2_3.toString());
                    }
                }
                StringBuilder v2_4 = com.personal.aihub.CreatorActivity.mime(v12_2);
                if ((com.personal.aihub.CreatorActivity.mime(v12_2).startsWith("text/")) || (v12_2.endsWith(".js"))) {
                    v1_0 = "UTF-8";
                }
                return new android.webkit.WebResourceResponse(v2_4, v1_0, v11_2);
            } else {
                return 0;
            }
        } else {
            return v0_0;
        }
    }

    public boolean shouldOverrideUrlLoading(android.webkit.WebView p1, android.webkit.WebResourceRequest p2)
    {
        return ("forge.local".equals(p2.getUrl().getHost()) ^ 1);
    }
}
