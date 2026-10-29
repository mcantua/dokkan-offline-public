package com.personal.aihub;
public final class GameMetadata {
    private final com.personal.aihub.GameAssets assets;
    private final com.personal.aihub.GameMetadata$Query query;
    private final org.json.JSONObject rules;

    public GameMetadata(java.io.File p2, com.personal.aihub.GameMetadata$Query p3, org.json.JSONObject p4)
    {
        this(p2, p3, p4, 0);
        return;
    }

    public GameMetadata(java.io.File p7, com.personal.aihub.GameMetadata$Query p8, org.json.JSONObject p9, String p10)
    {
        this(p7, p8, p9, p10, 0);
        return;
    }

    public GameMetadata(java.io.File p2, com.personal.aihub.GameMetadata$Query p3, org.json.JSONObject p4, String p5, org.json.JSONArray p6)
    {
        this.assets = new com.personal.aihub.GameAssets(p2, p5, p6);
        this.query = p3;
        this.rules = p4;
        return;
    }

    private static org.json.JSONObject clean(org.json.JSONObject p1)
    {
        if (p1 != null) {
            org.json.JSONObject v0_1 = new org.json.JSONObject(p1.toString());
            v0_1.remove("fsPath");
            return v0_1;
        } else {
            return 0;
        }
    }

    private org.json.JSONObject descriptor(String p5)
    {
        String v0_0 = this.assets;
        String v1_6 = new StringBuilder("/assets/");
        v1_6.append(p5);
        String v0_2 = v0_0.resolve(v1_6.toString());
        if (v0_2 != null) {
            String v1_3 = new org.json.JSONObject().put("rel", p5);
            StringBuilder v3_2 = new StringBuilder("/assets/");
            v3_2.append(p5);
            org.json.JSONObject v5_4 = v1_3.put("url", v3_2.toString()).put("bytes", v0_2.length()).put("source", "imported");
            String v1_8 = new StringBuilder("imported:");
            v1_8.append(v0_2.lastModified());
            v1_8.append(":");
            v1_8.append(v0_2.length());
            return v5_4.put("stamp", v1_8.toString());
        } else {
            return 0;
        }
    }

    private org.json.JSONObject first(java.util.List p2)
    {
        int v2_1 = p2.iterator();
        while (v2_1.hasNext()) {
            org.json.JSONObject v0_0 = this.descriptor(((String) v2_1.next()));
            if (v0_0 != null) {
                return v0_0;
            }
        }
        return 0;
    }

    public static org.json.JSONObject merge(org.json.JSONObject p12, org.json.JSONObject p13)
    {
        if (p12 != null) {
            if ((p13 != null) && (p13.optBoolean("found"))) {
                if (p12.has("character_id")) {
                    if ((p12.optLong("character_id") == p13.optLong("character_id")) && (p12.optLong("art_id") == p13.optLong("art_id"))) {
                        org.json.JSONObject v0_12 = new org.json.JSONObject(p13.toString());
                        String v1_8 = p12.keys();
                        while (v1_8.hasNext()) {
                            String v2_1 = ((String) v1_8.next());
                            v0_12.put(v2_1, p12.get(v2_1));
                        }
                        String v5_0 = 0;
                        while (v5_0 < 4) {
                            Object v7_4;
                            Object v6_7 = new String[] {"battle", "idle", "sp", "card_bg"})[v5_0];
                            if (v6_7.equals("sp")) {
                                if (p12.optInt("special_motion", 0) == p13.optInt("special_motion", 0)) {
                                    v7_4 = 1;
                                } else {
                                    v7_4 = 0;
                                }
                            } else {
                                if ((!v6_7.equals("card_bg")) || (p12.optLong("bg_effect_id", 0) == p13.optLong("bg_effect_id", 0))) {
                                }
                            }
                            org.json.JSONObject v8_1 = p12.optJSONObject(v6_7);
                            if ((v8_1 == null) && (v7_4 != null)) {
                                v8_1 = p13.optJSONObject(v6_7);
                            }
                            v0_12.put(v6_7, com.personal.aihub.GameMetadata.nullable(com.personal.aihub.GameMetadata.clean(v8_1)));
                            v5_0++;
                        }
                        String v1_12 = new org.json.JSONObject();
                        long v3_6 = p13.optJSONObject("textures");
                        org.json.JSONObject v4_2 = p12.optJSONObject("textures");
                        if (v3_6 != 0) {
                            String v5_3 = v3_6.keys();
                            while (v5_3.hasNext()) {
                                Object v6_6 = ((String) v5_3.next());
                                v1_12.put(v6_6, com.personal.aihub.GameMetadata.nullable(com.personal.aihub.GameMetadata.clean(v3_6.optJSONObject(v6_6))));
                            }
                        }
                        if (v4_2 != null) {
                            long v3_7 = v4_2.keys();
                            while (v3_7.hasNext()) {
                                String v5_7 = ((String) v3_7.next());
                                v1_12.put(v5_7, com.personal.aihub.GameMetadata.nullable(com.personal.aihub.GameMetadata.clean(v4_2.optJSONObject(v5_7))));
                            }
                        }
                        v0_12.put("textures", v1_12);
                        if ((p12.isNull("aura_effect_id")) && (p12.optLong("aura_id", 0) == p13.optLong("aura_id", 0))) {
                            v0_12.put("aura_effect_id", com.personal.aihub.GameMetadata.value(p13, "aura_effect_id"));
                        }
                        return v0_12;
                    }
                } else {
                    if ((p12.optString("pack_name").equals(p13.optString("pack_name"))) && (p12.optInt("category", -1) == p13.optInt("category", -1))) {
                        org.json.JSONObject v0_7 = new org.json.JSONObject(p13.toString());
                        String v1_4 = p12.keys();
                        while (v1_4.hasNext()) {
                            String v2_6 = ((String) v1_4.next());
                            v0_7.put(v2_6, p12.get(v2_6));
                        }
                        String v1_5 = "lwf";
                        String v2_4 = p12.optJSONObject("lwf");
                        org.json.JSONObject v4_0 = p12.optJSONObject("usm");
                        if (v2_4 == null) {
                            v2_4 = p13.optJSONObject("lwf");
                        }
                        if ((v4_0 == null) && (p12.optBoolean("enemy") == p13.optBoolean("enemy"))) {
                            v4_0 = p13.optJSONObject("usm");
                        }
                        Object v12_5 = v0_7.put("lwf", com.personal.aihub.GameMetadata.nullable(com.personal.aihub.GameMetadata.clean(v2_4))).put("usm", com.personal.aihub.GameMetadata.nullable(com.personal.aihub.GameMetadata.clean(v4_0)));
                        if ((v2_4 == null) || (v4_0 == null)) {
                            if (v2_4 == null) {
                                if (v4_0 == null) {
                                    v1_5 = "missing";
                                } else {
                                    v1_5 = "usm";
                                }
                            }
                        } else {
                            v1_5 = "both";
                        }
                        p12 = v12_5.put("media", v1_5);
                    }
                    return p12;
                }
            }
            return p12;
        } else {
            return p13;
        }
    }

    private static Object nullable(Object p0)
    {
        if (p0 == null) {
            p0 = org.json.JSONObject.NULL;
        }
        return p0;
    }

    private java.util.List paths(org.json.JSONArray p5, String p6)
    {
        java.util.ArrayList v0_1 = new java.util.ArrayList();
        int v1 = 0;
        while (v1 < p5.length()) {
            v0_1.add(p5.getString(v1).replace("{pack}", p6));
            v1++;
        }
        return v0_1;
    }

    private org.json.JSONObject row(String p2, long p3)
    {
        try {
            return this.query.row(p2, p3);
        } catch (Exception) {
            return 0;
        }
    }

    private static Object value(org.json.JSONObject p1, String p2)
    {
        Object v1_1;
        if (p1.opt(p2) != null) {
            v1_1 = p1.opt(p2);
        } else {
            v1_1 = org.json.JSONObject.NULL;
        }
        return v1_1;
    }

    public org.json.JSONObject resolve(String p36)
    {
        org.json.JSONObject v1_0 = p36;
        org.json.JSONObject v11_0 = "bg_effect_id";
        try {
            if (p36.startsWith("/")) {
                String v14_3 = new StringBuilder("https://dokkan-eclipse.com");
                v14_3.append(p36);
                v1_0 = v14_3.toString();
            }
        } catch (Exception) {
            org.json.JSONObject v1_45 = 0;
            return v1_45;
        } catch (Exception) {
            return v1_45;
        }
        double v12_2 = new java.net.URI(v1_0);
        if (!"https".equals(v12_2.getScheme())) {
            return 0;
        } else {
            if (((!"dokkan-eclipse.com".equals(v12_2.getHost())) && (!"cdn.dokkan-eclipse.com".equals(v12_2.getHost()))) || ((v12_2.getUserInfo() != null) || (v12_2.getPort() != -1))) {
                return 0;
            } else {
                org.json.JSONObject v1_34;
                boolean v20_1;
                org.json.JSONObject v1_29 = v12_2.getQuery();
                if (v1_29 == null) {
                    v20_1 = "bg_effect_id";
                    v1_34 = 0;
                } else {
                    org.json.JSONObject v1_35 = v1_29.split("&");
                    int v13_4 = v1_35.length;
                    String v14_8 = 0;
                    int v17_2 = 0;
                    while (v14_8 < v13_4) {
                        org.json.JSONObject v18_5 = v13_4;
                        int v19_3 = v1_35;
                        boolean v20_2 = v11_0;
                        org.json.JSONObject v1_42 = v1_35[v14_8].split("=", 2);
                        if (!v1_42[0].equals("patch")) {
                            if ((v1_42.length == 2) && ((v1_42[0].equals("enemy")) && (v1_42[1].equals("1")))) {
                                v17_2 = 1;
                            }
                            v14_8++;
                            v13_4 = v18_5;
                            v1_35 = v19_3;
                            v11_0 = v20_2;
                        } else {
                            return 0;
                        }
                    }
                    v20_1 = v11_0;
                    v1_34 = v17_2;
                }
                double v12_20;
                org.json.JSONObject v11_27 = java.util.regex.Pattern.compile("^/api/(card|effect-pack)/([1-9][0-9]{0,14})$");
                if (v12_2.getPath() != null) {
                    v12_20 = v12_2.getPath();
                } else {
                    v12_20 = "";
                }
                org.json.JSONObject v11_28 = v11_27.matcher(v12_20);
                if (v11_28.matches()) {
                    double v12_18 = Long.parseLong(v11_28.group(2));
                    if (!v11_28.group(1).equals("effect-pack")) {
                        v1_45 = 0;
                        int v7_0 = this.row("cards", v12_18);
                        if (v7_0 != 0) {
                            int v8_1 = v7_0.optLong("character_id", -1);
                            int v36_1 = "name";
                            org.json.JSONObject v18_0 = v7_0.optLong("resource_id", 0);
                            if (v18_0 == 0) {
                                v18_0 = v7_0.optLong("id", 0);
                            }
                            if ((v8_1 > 0) && (v8_1 <= 9007199254740991)) {
                                if (v18_0 > 0) {
                                    if (v18_0 <= 9007199254740991) {
                                        int v8_3;
                                        String v3_1 = ((v18_0 / 10) * 10);
                                        org.json.JSONObject v18_2 = "resource_id";
                                        org.json.JSONObject v25_0 = this.row("characters", v8_1);
                                        String v2_1 = String.format(java.util.Locale.ROOT, "%05d", new Object[] {Long.valueOf(v8_1), Long.valueOf(v8_1)}));
                                        int v19_1 = "character_id";
                                        org.json.JSONObject v1_5 = String.format(java.util.Locale.ROOT, "%02d", new Object[] {Integer.valueOf(v7_0.optInt("special_motion", 0))}));
                                        org.json.JSONObject v11_11 = new StringBuilder();
                                        v11_11.append("ingame/battle/character/");
                                        v11_11.append(v2_1);
                                        v11_11.append("/battle/battle_character_");
                                        v11_11.append(v2_1);
                                        v11_11.append(".lwf");
                                        org.json.JSONObject v11_13 = this.descriptor(v11_11.toString());
                                        int v15_4 = new StringBuilder();
                                        v15_4.append("ingame/battle/character/");
                                        v15_4.append(v2_1);
                                        org.json.JSONObject v26_1 = "special_motion";
                                        v15_4.append("/idle/idle_character_");
                                        v15_4.append(v2_1);
                                        v15_4.append(".lwf");
                                        org.json.JSONObject v6_2 = this.descriptor(v15_4.toString());
                                        int v15_6 = new StringBuilder();
                                        v15_6.append("ingame/battle/character/");
                                        v15_6.append(v2_1);
                                        v15_6.append("/sp");
                                        v15_6.append(v1_5);
                                        v15_6.append("/sp_character_");
                                        v15_6.append(v2_1);
                                        String v2_2 = "_";
                                        v15_6.append("_");
                                        v15_6.append(v1_5);
                                        v15_6.append(".lwf");
                                        org.json.JSONObject v1_7 = this.descriptor(v15_6.toString());
                                        Object v23_0 = v8_1;
                                        org.json.JSONObject v5_2 = v20_1;
                                        if (v7_0.optLong(v5_2, 0) == 0) {
                                            v8_3 = 0;
                                        } else {
                                            int v15_9 = new StringBuilder();
                                            v15_9.append("character/card_bg/");
                                            v15_9.append(((v7_0.optLong(v5_2, 0) / 10) * 10));
                                            v15_9.append("/card_");
                                            v15_9.append(((v7_0.optLong(v5_2, 0) / 10) * 10));
                                            v15_9.append(".lwf");
                                            v8_3 = this.descriptor(v15_9.toString());
                                        }
                                        Object v9_1 = new StringBuilder();
                                        v9_1.append("character/card/");
                                        v9_1.append(v3_1);
                                        v9_1.append("/card_");
                                        v9_1.append(v3_1);
                                        Object v9_2 = v9_1.toString();
                                        org.json.JSONObject v10_4 = new org.json.JSONObject();
                                        boolean v20_0 = v5_2;
                                        String[] v29 = new String[] {"bg", "_bg.png"});
                                        String[] v31 = new String[] {"cutin", "sp_cutin_1.png"});
                                        int v15_16 = 0;
                                        while (v15_16 < 6) {
                                            org.json.JSONObject v5_11 = v7_0;
                                            org.json.JSONObject v16_0 = v25_0;
                                            org.json.JSONObject v22 = v26_1;
                                            int v7_1 = v36_1;
                                            org.json.JSONObject v24 = v18_2;
                                            Object v23_1 = v19_1;
                                            org.json.JSONObject v18_3 = v23_0;
                                            org.json.JSONObject v25_1 = new String[][] {new String[] {"character", "_character.png"}), new String[] {"sp_cutin", "sp_cutin_1.png"})})[v15_16];
                                            int v36_2 = v1_7;
                                            org.json.JSONObject v1_10 = new StringBuilder();
                                            org.json.JSONObject v26_2 = v2_2;
                                            v1_10.append(String.valueOf(v9_2));
                                            String v27_4 = v3_1;
                                            v1_10.append(v25_1[1]);
                                            org.json.JSONObject v1_13 = this.descriptor(v1_10.toString());
                                            if (v1_13 != null) {
                                                v10_4.put(v25_1[0], v1_13);
                                            }
                                            v15_16++;
                                            v1_7 = v36_2;
                                            v36_1 = v7_1;
                                            v25_0 = v16_0;
                                            v2_2 = v26_2;
                                            v3_1 = v27_4;
                                            v7_0 = v5_11;
                                            v26_1 = v22;
                                            v19_1 = v23_1;
                                            v18_2 = v24;
                                            v23_0 = v18_3;
                                        }
                                        org.json.JSONObject v5_13 = new String[] {"sp_name", "sp_phrase"});
                                        org.json.JSONObject v16_1 = v7_0;
                                        int v7_2 = 2;
                                        int v15_18 = 0;
                                        while (v15_18 < v7_2) {
                                            int v7_10 = v5_13[v15_18];
                                            int v17_1 = v5_13;
                                            org.json.JSONObject v5_18 = new StringBuilder();
                                            String v27_6 = v12_18;
                                            v5_18.append("character/card/");
                                            v5_18.append(v3_1);
                                            v5_18.append("/en/card_");
                                            v5_18.append(v3_1);
                                            v5_18.append(v2_2);
                                            v5_18.append(v7_10);
                                            v5_18.append(".png");
                                            org.json.JSONObject v5_19 = v5_18.toString();
                                            double v12_16 = new StringBuilder();
                                            v12_16.append(String.valueOf(v9_2));
                                            v12_16.append(v2_2);
                                            v12_16.append(v7_10);
                                            v12_16.append(".png");
                                            org.json.JSONObject v5_22 = this.first(java.util.Arrays.asList(new String[] {v5_19, v12_16.toString()})));
                                            if (v5_22 != null) {
                                                v10_4.put(v7_10, v5_22);
                                            }
                                            v15_18++;
                                            v5_13 = v17_1;
                                            v12_18 = v27_6;
                                            v7_2 = 2;
                                        }
                                        if ((v11_13 != null) || ((v6_2 != null) || ((v1_7 != null) || ((v8_3 != 0) || (v10_4.length() != 0))))) {
                                            Object v9_5;
                                            int v7_4 = v36_1;
                                            org.json.JSONObject v5_16 = v16_1;
                                            String v2_13 = new org.json.JSONObject().put("found", 1).put("forge_local", 1).put("id", v12_18).put(v7_4, v5_16.optString(v7_4)).put(v19_1, v23_0);
                                            if (v25_0 != null) {
                                                v9_5 = com.personal.aihub.GameMetadata.value(v25_0, "size");
                                            } else {
                                                v9_5 = org.json.JSONObject.NULL;
                                            }
                                            int v13_0;
                                            int v7_7 = v18_2;
                                            String v3_5 = v20_0;
                                            String v3_6 = v26_1;
                                            String v2_23 = v2_13.put("character_size", v9_5).put(v7_7, com.personal.aihub.GameMetadata.value(v5_16, v7_7)).put("art_id", v3_1).put(v3_5, com.personal.aihub.GameMetadata.value(v5_16, v3_5)).put(v3_6, com.personal.aihub.GameMetadata.value(v5_16, v3_6)).put("aura_id", com.personal.aihub.GameMetadata.value(v5_16, "aura_id")).put("aura_effect_id", org.json.JSONObject.NULL).put("aura_scale", v5_16.optDouble("aura_scale", 4607182418800017408)).put("aura_offset_x", v5_16.optDouble("aura_offset_x", 0)).put("aura_offset_y", v5_16.optDouble("aura_offset_y", 0));
                                            if (v5_16.optInt("is_aura_front", 0) == 0) {
                                                v13_0 = 0;
                                            } else {
                                                v13_0 = 1;
                                            }
                                            return v2_23.put("is_aura_front", v13_0).put("battle", com.personal.aihub.GameMetadata.nullable(v11_13)).put("idle", com.personal.aihub.GameMetadata.nullable(v6_2)).put("sp", com.personal.aihub.GameMetadata.nullable(v1_7)).put("card_bg", com.personal.aihub.GameMetadata.nullable(v8_3)).put("textures", v10_4).put("dbSource", "imported");
                                        } else {
                                            return 0;
                                        }
                                    } else {
                                        return 0;
                                    }
                                } else {
                                }
                            }
                            return 0;
                        } else {
                            return 0;
                        }
                    } else {
                        String v2_32 = this.row("effect_packs", v12_18);
                        if (v2_32 != null) {
                            if (v2_32.optString("pack_name").matches("[-a-zA-Z0-9_]{1,100}")) {
                                String v3_20 = v2_32.getString("pack_name");
                                org.json.JSONObject v5_27 = this.rules.getJSONObject("categories").optJSONObject(String.valueOf(v2_32.optInt("category", -1)));
                                if (v5_27 != null) {
                                    org.json.JSONObject v18_4;
                                    long v21_2;
                                    int v36_3;
                                    int v19_2;
                                    org.json.JSONObject v6_9 = this.first(this.paths(v5_27.getJSONArray("lwf"), v3_20));
                                    org.json.JSONObject v10_6 = new java.util.ArrayList();
                                    if (v1_34 == null) {
                                        v36_3 = v1_34;
                                        v19_2 = "lwf";
                                        v21_2 = "pack_name";
                                        v18_4 = "enemy";
                                    } else {
                                        v36_3 = v1_34;
                                        org.json.JSONObject v1_28 = v5_27.getJSONArray("usm");
                                        v18_4 = "enemy";
                                        int v15_20 = new StringBuilder();
                                        v19_2 = "lwf";
                                        v15_20.append(String.valueOf(v3_20));
                                        v21_2 = "pack_name";
                                        v15_20.append(this.rules.getString("enemyMovieSuffix"));
                                        v10_6.addAll(this.paths(v1_28, v15_20.toString()));
                                    }
                                    v10_6.addAll(this.paths(v5_27.getJSONArray("usm"), v3_20));
                                    org.json.JSONObject v1_33 = this.first(v10_6);
                                    if ((v6_9 != null) || (v1_33 != null)) {
                                        Object v4_18;
                                        org.json.JSONObject vtmp74 = new org.json.JSONObject().put("found", 1).put("forge_local", 1).put("id", v12_18).put("category", v2_32.optInt("category")).put("name", v2_32.optString("name")).put(v21_2, v3_20).put("scene_name", v2_32.optString("scene_name")).put("rgba", new org.json.JSONObject().put("r", com.personal.aihub.GameMetadata.value(v2_32, "red")).put("g", com.personal.aihub.GameMetadata.value(v2_32, "green")).put("b", com.personal.aihub.GameMetadata.value(v2_32, "blue")).put("a", com.personal.aihub.GameMetadata.value(v2_32, "alpha"))).put("lite_flicker_rate", com.personal.aihub.GameMetadata.value(v2_32, "lite_flicker_rate"));
                                        if (v6_9 == null) {
                                            if (v6_9 == null) {
                                                v4_18 = "usm";
                                            } else {
                                                v4_18 = v19_2;
                                            }
                                        } else {
                                            if (v1_33 != null) {
                                                v4_18 = "both";
                                            } else {
                                            }
                                        }
                                        return vtmp74.put("media", v4_18).put(v19_2, com.personal.aihub.GameMetadata.nullable(v6_9)).put("usm", com.personal.aihub.GameMetadata.nullable(v1_33)).put(v18_4, v36_3).put("dbSource", "imported");
                                    } else {
                                        return 0;
                                    }
                                } else {
                                    return 0;
                                }
                            } else {
                            }
                        }
                        return 0;
                    }
                } else {
                    return 0;
                }
            }
        }
    }
}
