package com.personal.aihub;
 class PreviewActivity$AnonymousClass1$1 implements java.lang.Runnable {
    final synthetic com.personal.aihub.PreviewActivity$AnonymousClass1 this$1;
    final synthetic String val$str;
    final synthetic android.widget.TextView val$textView;
    final synthetic android.webkit.WebView val$webView;

    PreviewActivity$AnonymousClass1$1(com.personal.aihub.PreviewActivity$AnonymousClass1 p1, android.webkit.WebView p2, android.widget.TextView p3, String p4)
    {
        this.this$1 = p1;
        this.val$webView = p2;
        this.val$textView = p3;
        this.val$str = p4;
        return;
    }

    public final void run()
    {
        this.this$1.m30lambda$0$compersonalaihubPreviewActivity$1(this.val$webView, this.val$textView, this.val$str);
        return;
    }
}
