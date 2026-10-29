package com.personal.aihub;
final class AiHandoff {

    AiHandoff()
    {
        return;
    }

    static org.json.JSONObject compose(android.app.Activity p10, org.json.JSONObject p11)
    {
        try {
            com.personal.aihub.Provider v4 = com.personal.aihub.Provider.valueOf(p11.optString("provider").toUpperCase(java.util.Locale.ROOT));
            String v3 = p11.optString("prompt");
        } catch (IllegalArgumentException) {
            throw new java.io.IOException("Choose ChatGPT, Claude, or Grok.");
        }
        if ((v3.trim().isEmpty()) || ((v3.length() > 64000) || (v3.indexOf(0) >= 0))) {
            throw new java.io.IOException("Use a prompt between 1 and 64,000 characters.");
        } else {
            String v11_9 = new java.util.concurrent.atomic.AtomicReference();
            java.util.concurrent.atomic.AtomicReference v0_4 = new java.util.concurrent.atomic.AtomicReference();
            java.util.concurrent.CountDownLatch v8_1 = new java.util.concurrent.CountDownLatch(1);
            com.personal.aihub.AiHandoff$$ExternalSyntheticLambda0 v9 = new com.personal.aihub.AiHandoff$$ExternalSyntheticLambda0;
            v9(p10, v3, v4, v11_9, v0_4, v8_1);
            if (android.os.Looper.myLooper() != android.os.Looper.getMainLooper()) {
                p10.runOnUiThread(v9);
            } else {
                v9.run();
            }
            if (!v8_1.await(15, java.util.concurrent.TimeUnit.SECONDS)) {
                throw new java.io.IOException("Opening the assistant is taking too long. Check the selected app before retrying.");
            } else {
                if (v0_4.get() != null) {
                    throw ((Exception) v0_4.get());
                } else {
                    return ((org.json.JSONObject) v11_9.get());
                }
            }
        }
    }

    static synthetic void lambda$compose$0(android.app.Activity p3, String p4, com.personal.aihub.Provider p5, java.util.concurrent.atomic.AtomicReference p6, java.util.concurrent.atomic.AtomicReference p7, java.util.concurrent.CountDownLatch p8)
    {
        try {
            if ((p3.isFinishing()) || (p3.isDestroyed())) {
                throw new java.io.IOException("Return to the creator and try again.");
            } else {
                String v1_2 = ((android.content.ClipboardManager) p3.getSystemService("clipboard"));
                if (v1_2 == null) {
                    throw new java.io.IOException("The clipboard is unavailable.");
                } else {
                    String v3_3;
                    v1_2.setPrimaryClip(android.content.ClipData.newPlainText("Dokkan Unit Creator AI prompt", p4));
                    android.content.Intent v4_3 = new android.content.Intent("android.intent.action.SEND").setType("text/plain").putExtra("android.intent.extra.TEXT", p4).setPackage(p5.packageName);
                    if (v4_3.resolveActivity(p3.getPackageManager()) == null) {
                        android.content.Intent v4_5 = p3.getPackageManager().getLaunchIntentForPackage(p5.packageName);
                        if (v4_5 == null) {
                            p3.startActivity(new android.content.Intent("android.intent.action.VIEW", android.net.Uri.parse(p5.website)));
                            v3_3 = "clipboard-web";
                        } else {
                            p3.startActivity(v4_5);
                            v3_3 = "clipboard-app";
                        }
                    } else {
                        p3.startActivity(v4_3);
                        v3_3 = "share";
                    }
                    p6.set(new org.json.JSONObject().put("requested", 1).put("copied", 1).put("provider", p5.label).put("transport", v3_3));
                }
            }
        } catch (String v3_6) {
            StringBuilder v6_2 = new StringBuilder("Could not open ");
            v6_2.append(p5.label);
            v6_2.append(". Your prompt may already be copied; open its official app and paste it.");
            p7.set(new java.io.IOException(v6_2.toString(), v3_6));
        } catch (String v3_7) {
            p8.countDown();
            throw v3_7;
        }
        p8.countDown();
        return;
    }
}
