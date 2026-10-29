package com.personal.aihub;
public final class PreviewBgm {
    private final com.personal.aihub.GameAssets assets;
    private com.personal.aihub.AudioBanks banks;
    private org.json.JSONObject cached;
    private boolean closed;
    public final org.json.JSONObject context;
    private final java.io.File root;

    public PreviewBgm(android.database.sqlite.SQLiteDatabase p1, java.io.File p2, com.personal.aihub.GameAssets p3, String p4)
    {
        this.root = p2;
        this.assets = p3;
        this.context = com.personal.aihub.GameBgm.context(p1, p4);
        return;
    }

    public declared_synchronized void close()
    {
        try {
            this.closed = 1;
            int v0_1 = this.banks;
        } catch (int v0_2) {
            throw v0_2;
        }
        if (v0_1 != 0) {
            v0_1.close();
        }
        this.cached = 0;
        return;
    }

    public declared_synchronized org.json.JSONObject descriptor()
    {
        try {
            if (this.closed) {
                throw new java.io.IOException("This music preview has closed");
            } else {
                org.json.JSONObject v0_16;
                if (this.cached == null) {
                    org.json.JSONObject v2_3 = new org.json.JSONObject().put("version", 1).put("context", this.context);
                    if (!this.context.optBoolean("found")) {
                        this.cached = v2_3.put("source", org.json.JSONObject.NULL);
                        v0_16 = new org.json.JSONObject(this.cached.toString());
                    } else {
                        org.json.JSONObject v0_11;
                        String v3_14 = com.personal.aihub.GameBgm.source(this.root, this.assets, this.context);
                        String v5_8 = this.context.getString("package");
                        if (v3_14 == null) {
                            v0_11 = new org.json.JSONObject().put("kind", "public").put("acb", new org.json.JSONObject().put("url", "/_forge/bgm-source.acb")).put("awb", new org.json.JSONObject().put("url", "/_forge/bgm-source.awb"));
                        } else {
                            String v7_2 = this.root;
                            org.json.JSONObject v8_1 = new org.json.JSONArray();
                            String v9_1 = new org.json.JSONObject();
                            StringBuilder v11_1 = new StringBuilder("se/");
                            v11_1.append(v5_8);
                            v11_1.append(".acb");
                            String v1_24 = v8_1.put(v9_1.put("path", v11_1.toString()).put("key", v3_14[0]));
                            org.json.JSONObject v8_3 = new org.json.JSONObject();
                            StringBuilder v11_4 = new StringBuilder("se/");
                            v11_4.append(v5_8);
                            v11_4.append(".awb");
                            com.personal.aihub.AudioBanks v6_0 = new com.personal.aihub.AudioBanks(v7_2, 0, v1_24.put(v8_3.put("path", v11_4.toString()).put("key", v3_14[1])), 1);
                            org.json.JSONObject v0_6 = v6_0.catalogue().getJSONArray("banks");
                            if (v0_6.length() != 1) {
                                throw new java.io.IOException("Imported move music is ambiguous");
                            } else {
                                String v1_6 = v0_6.getJSONObject(0).getJSONObject("acb");
                                org.json.JSONObject v0_10 = v0_6.getJSONObject(0).getJSONObject("awb");
                                v1_6.put("url", v1_6.getString("url").replace("/audio-bank-assets/", "/bgm-bank-assets/"));
                                v0_10.put("url", v0_10.getString("url").replace("/audio-bank-assets/", "/bgm-bank-assets/"));
                                this.banks = v6_0;
                                v0_11 = new org.json.JSONObject().put("kind", "imported").put("acb", v1_6).put("awb", v0_10);
                            }
                        }
                        this.cached = v2_3.put("source", v0_11);
                        return new org.json.JSONObject(this.cached.toString());
                    }
                } else {
                    v0_16 = new org.json.JSONObject(this.cached.toString());
                }
                return v0_16;
            }
        } catch (org.json.JSONObject v0_17) {
            throw v0_17;
        }
    }

    public declared_synchronized String publicAddress(String p5)
    {
        try {
            if ((!"/_forge/bgm-source.acb".equals(p5)) && (!"/_forge/bgm-source.awb".equals(p5))) {
                String v5_2 = 0;
            } else {
                StringBuilder v1_2 = this.descriptor().optJSONObject("source");
                if ((v1_2 == null) || (!"public".equals(v1_2.optString("kind")))) {
                } else {
                    StringBuilder v1_6 = new StringBuilder("https://dokkan-eclipse.com/cdn/uncompressed/bgm/");
                    v1_6.append(this.context.getString("package"));
                    v1_6.append(".");
                    v1_6.append(p5.substring((p5.length() - 3)));
                    v5_2 = v1_6.toString();
                }
            }
        } catch (String v5_1) {
            throw v5_1;
        }
        return v5_2;
    }

    public declared_synchronized java.io.File resolve(String p4)
    {
        try {
            if ((p4 == null) || (!p4.startsWith("https://dokkan-eclipse.com/_forge/bgm-bank-assets/"))) {
                java.io.File v4_1 = 0;
            } else {
                this.descriptor();
                com.personal.aihub.AudioBanks v0_2 = this.banks;
                if (v0_2 == null) {
                } else {
                    v4_1 = v0_2.resolve(p4.replace("/bgm-bank-assets/", "/audio-bank-assets/"));
                }
            }
        } catch (java.io.File v4_3) {
            throw v4_3;
        }
        return v4_1;
    }
}
