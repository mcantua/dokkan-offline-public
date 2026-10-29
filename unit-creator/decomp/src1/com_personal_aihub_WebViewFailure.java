package com.personal.aihub;
final class WebViewFailure {

    WebViewFailure()
    {
        return;
    }

    static void show(android.app.Activity p4, String p5, Runnable p6)
    {
        android.widget.LinearLayout v0_1 = new android.widget.LinearLayout(p4);
        v0_1.setOrientation(1);
        v0_1.setGravity(16);
        v0_1.setPadding(40, 80, 40, 80);
        v0_1.setBackgroundColor(-15657702);
        android.widget.Button v1_1 = new android.widget.TextView(p4);
        v1_1.setText("Android\u2019s WebView stopped");
        v1_1.setTextColor(-1118482);
        v1_1.setTextSize(1103101952);
        v0_1.addView(v1_1);
        android.widget.Button v1_4 = new android.widget.TextView(p4);
        StringBuilder v2_4 = new StringBuilder("Your saved units are still on this device. Reopen ");
        v2_4.append(p5);
        v2_4.append(" to try again. If this repeats, update Android System WebView in your device\u2019s app store and restart the app.");
        v1_4.setText(v2_4.toString());
        v1_4.setTextColor(-4473925);
        v1_4.setTextSize(1098907648);
        v1_4.setPadding(0, 24, 0, 24);
        v0_1.addView(v1_4);
        android.widget.Button v1_7 = new android.widget.Button(p4);
        StringBuilder v2_10 = new StringBuilder("Reopen ");
        v2_10.append(p5);
        v1_7.setText(v2_10.toString());
        v1_7.setOnClickListener(new com.personal.aihub.WebViewFailure$1(p6));
        v0_1.addView(v1_7);
        android.widget.Button v5_5 = new android.widget.Button(p4);
        v5_5.setText("Close");
        v5_5.setOnClickListener(new com.personal.aihub.WebViewFailure$2(p4));
        v0_1.addView(v5_5);
        p4.setContentView(v0_1);
        return;
    }
}
