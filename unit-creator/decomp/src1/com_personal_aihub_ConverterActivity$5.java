package com.personal.aihub;
 class ConverterActivity$5 extends android.webkit.WebChromeClient {
    final synthetic com.personal.aihub.ConverterActivity this$0;

    ConverterActivity$5(com.personal.aihub.ConverterActivity p1)
    {
        this.this$0 = p1;
        return;
    }

    public boolean onShowFileChooser(android.webkit.WebView p2, android.webkit.ValueCallback p3, android.webkit.WebChromeClient$FileChooserParams p4)
    {
        android.widget.TextView v2_6;
        if (p2.getUrl() != null) {
            v2_6 = p2.getUrl();
        } else {
            v2_6 = "";
        }
        android.widget.TextView v2_12 = android.net.Uri.parse(v2_6);
        if ((!"https".equals(v2_12.getScheme())) || (!"dokkan-eclipse.com".equals(v2_12.getHost()))) {
            p3.onReceiveValue(0);
            return 1;
        } else {
            android.widget.TextView v2_5 = new StringBuilder("content://");
            v2_5.append(this.this$0.getPackageName());
            v2_5.append(".patch/");
            v2_5.append(com.personal.aihub.ConverterActivity.access$000(this.this$0));
            v2_5.append("/unit-patch.zip");
            p3.onReceiveValue(new android.net.Uri[] {android.net.Uri.parse(v2_5.toString())}));
            com.personal.aihub.ConverterActivity.access$100(this.this$0).setText("Patch ZIP attached. Choose Convert Zip to ECLP, then its download link.");
            return 1;
        }
    }
}
