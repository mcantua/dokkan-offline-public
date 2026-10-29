package com.personal.aihub;
 class PreviewServer$4 implements android.webkit.WebResourceRequest {
    final synthetic com.personal.aihub.PreviewServer this$0;
    final synthetic com.personal.aihub.PreviewServer$Request val$request;

    PreviewServer$4(com.personal.aihub.PreviewServer p1, com.personal.aihub.PreviewServer$Request p2)
    {
        this.this$0 = p1;
        this.val$request = p2;
        return;
    }

    public String getMethod()
    {
        return "GET";
    }

    public java.util.Map getRequestHeaders()
    {
        return java.util.Collections.emptyMap();
    }

    public android.net.Uri getUrl()
    {
        android.net.Uri v0_1 = new StringBuilder("https://dokkan-eclipse.com");
        v0_1.append(this.val$request.target);
        return android.net.Uri.parse(v0_1.toString());
    }

    public boolean hasGesture()
    {
        return 0;
    }

    public boolean isForMainFrame()
    {
        return 0;
    }

    public boolean isRedirect()
    {
        return 0;
    }
}
