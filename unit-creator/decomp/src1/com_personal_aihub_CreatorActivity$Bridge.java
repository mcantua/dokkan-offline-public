package com.personal.aihub;
public final class CreatorActivity$Bridge {
    private final java.util.Map parts;
    final synthetic com.personal.aihub.CreatorActivity this$0;

    public CreatorActivity$Bridge(com.personal.aihub.CreatorActivity p1)
    {
        this.this$0 = p1;
        this.parts = new java.util.HashMap();
        return;
    }

    void m19lambda$0$compersonalaihubCreatorActivity$Bridge(int p2, String p3, org.json.JSONObject p4)
    {
        this.this$0.pick(p2, p3, p4);
        return;
    }

    void m20lambda$1$compersonalaihubCreatorActivity$Bridge(int p3, String p4, org.json.JSONObject p5)
    {
        try {
            com.personal.aihub.CreatorActivity v1 = this.this$0;
            v1.reply(p3, v1.dispatch(p4, p5), 0);
        } catch (Exception v4_2) {
            this.this$0.reply(p3, 0, v4_2);
        }
        return;
    }

    public void postMessage(String p7)
    {
        try {
            com.personal.aihub.CreatorActivity v0_1;
            com.personal.aihub.CreatorActivity$Bridge$1 v2_1 = new org.json.JSONObject(p7);
            int v7_2 = v2_1.getInt("id");
            String v3_1 = v2_1.getString("method");
            StringBuilder v5_1 = new StringBuilder("Request ");
            v5_1.append(v7_2);
            v5_1.append(" ");
            v5_1.append(v3_1);
            android.util.Log.d("ForgeBridge", v5_1.toString());
        } catch (Exception) {
            return;
        }
        if (v2_1.optJSONObject("args") != null) {
            v0_1 = v2_1.getJSONObject("args");
        } else {
            v0_1 = new org.json.JSONObject();
        }
        if (!v3_1.equals("importStatus")) {
            if ((v3_1.equals("import")) || ((v3_1.equals("importApk")) || (v3_1.equals("export")))) {
                this.this$0.runOnUiThread(new com.personal.aihub.CreatorActivity$Bridge$2(this, v7_2, v3_1, v0_1));
                return;
            } else {
                com.personal.aihub.CreatorActivity.access$300(this.this$0).execute(new com.personal.aihub.CreatorActivity$Bridge$1(this, v7_2, v3_1, v0_1));
                return;
            }
        } else {
            com.personal.aihub.CreatorActivity v0_3 = this.this$0;
            v0_3.reply(v7_2, com.personal.aihub.CreatorActivity.access$200(v0_3), 0);
            return;
        }
    }

    public declared_synchronized void postMessageChunk(int p5, int p6, int p7, String p8)
    {
        try {
            if ((p5 >= 1) && ((p6 >= null) && ((p7 >= 1) && ((p7 <= 1024) && ((p6 < p7) && ((p8 != 0) && (p8.length() <= 24000))))))) {
                if (p6 == null) {
                    if (this.parts.size() >= 8) {
                        throw new java.io.IOException("Too many pending transfers");
                    } else {
                        this.parts.put(Integer.valueOf(p5), new StringBuilder());
                    }
                }
                java.util.Map v1_5 = ((StringBuilder) this.parts.get(Integer.valueOf(p5)));
                if ((v1_5 == null) || ((v1_5.length() + p8.length()) > 20971520)) {
                    throw new java.io.IOException("Project transfer exceeds 20 MB");
                } else {
                    v1_5.append(p8);
                    if (p6 == (p7 - 1)) {
                        this.parts.remove(Integer.valueOf(p5));
                        this.postMessage(v1_5.toString());
                    }
                }
            }
        } catch (String v6_7) {
            this.parts.remove(Integer.valueOf(p5));
            this.this$0.reply(p5, 0, v6_7);
        } catch (Throwable v5_1) {
            throw v5_1;
        }
        return;
    }
}
