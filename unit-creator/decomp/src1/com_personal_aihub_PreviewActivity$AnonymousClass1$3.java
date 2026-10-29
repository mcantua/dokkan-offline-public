package com.personal.aihub;
 class PreviewActivity$AnonymousClass1$3 implements android.webkit.ValueCallback {
    final synthetic com.personal.aihub.PreviewActivity$AnonymousClass1 this$1;
    final synthetic long val$epoch;
    final synthetic org.json.JSONObject val$jSONObject;
    final synthetic android.widget.LinearLayout val$linearLayout;
    final synthetic com.personal.aihub.PreviewCache val$previewCache;
    final synthetic String val$str;
    final synthetic android.widget.TextView val$textView;
    final synthetic android.webkit.WebView val$webView;

    PreviewActivity$AnonymousClass1$3(com.personal.aihub.PreviewActivity$AnonymousClass1 p1, android.webkit.WebView p2, long p3, String p5, android.widget.LinearLayout p6, android.widget.TextView p7, org.json.JSONObject p8, com.personal.aihub.PreviewCache p9)
    {
        this.this$1 = p1;
        this.val$webView = p2;
        this.val$epoch = p3;
        this.val$str = p5;
        this.val$linearLayout = p6;
        this.val$textView = p7;
        this.val$jSONObject = p8;
        this.val$previewCache = p9;
        return;
    }

    public final void onReceiveValue(Object p10)
    {
        if (com.personal.aihub.PreviewActivity.access$000(this.this$1.this$0).current(this.val$webView, this.val$epoch)) {
            this.this$1.m32lambda$2$compersonalaihubPreviewActivity$1(this.val$webView, this.val$str, this.val$linearLayout, this.val$textView, this.val$jSONObject, this.val$previewCache, ((String) p10));
        }
        return;
    }
}
