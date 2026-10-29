package com.personal.aihub;
final class PreviewMetadata {

    PreviewMetadata()
    {
        return;
    }

    static synthetic org.json.JSONObject access$000(java.io.File p0, String p1, long p2)
    {
        return com.personal.aihub.PreviewMetadata.rowFromFile(p0, p1, p2);
    }

    static java.io.File databaseFile(java.io.File p2, String p3)
    {
        return com.personal.aihub.PreviewMetadata.databaseFile(p2, p3, 0);
    }

    static java.io.File databaseFile(java.io.File p7, String p8, long p9)
    {
        int v0_1 = p9 cmp 0;
        if ((v0_1 < 0) || (p9 > 9007199254740991)) {
            throw new java.io.IOException("Choose a valid Sparking content version.");
        } else {
            if (!com.personal.aihub.PreviewMetadata.normalizeSource(p8).equals("sparking")) {
                return new com.personal.aihub.GameDataStore(p7, new java.io.File(p7, "bundled-database.db")).current();
            } else {
                com.personal.aihub.GameDataStore v1_3 = new com.personal.aihub.GameDataStore(new java.io.File(p7, "sparking"), new java.io.File(p7, "sparking-unavailable.db"));
                java.io.File v7_2 = v1_3.state();
                if (v0_1 <= 0) {
                    if ((v7_2 == null) || (!v1_3.current().isFile())) {
                        throw new java.io.IOException("Download Sparking characters from Library before previewing this source.");
                    } else {
                        return v1_3.current();
                    }
                } else {
                    if (v7_2 != null) {
                        int v0_3 = 0;
                        while (v0_3 < 2) {
                            boolean v3_2;
                            java.io.File v2_4 = v7_2.optJSONObject(new String[] {"active", "previous"})[v0_3]);
                            if (v2_4 != null) {
                                v3_2 = v2_4.optJSONObject("meta");
                            } else {
                                v3_2 = 0;
                            }
                            if ((v3_2) && (v3_2.optLong("latestVersion", -1) == p9)) {
                                java.io.File v2_5 = v1_3.file(v2_4);
                                if (v2_5.isFile()) {
                                    return v2_5;
                                }
                            }
                            v0_3++;
                        }
                    }
                    String v8_11 = new StringBuilder("This animation needs Sparking content version ");
                    v8_11.append(p9);
                    v8_11.append(". Restore or import that version before previewing; another version was not substituted.");
                    throw new java.io.IOException(v8_11.toString());
                }
            }
        }
    }

    static org.json.JSONObject lambda$0(java.util.Map p1, java.io.File p2, String p3, long p4)
    {
        if ((!p3.equals("effect_packs")) || (!p1.containsKey(Long.valueOf(p4)))) {
            org.json.JSONObject v1_1 = com.personal.aihub.PreviewMetadata.row(p2, p3, p4);
        } else {
            v1_1 = ((org.json.JSONObject) p1.get(Long.valueOf(p4)));
        }
        return v1_1;
    }

    static boolean localOnly(String p5, String p6, org.json.JSONArray p7)
    {
        if (!com.personal.aihub.PreviewMetadata.normalizeSource(p5).equals("sparking")) {
            long v5_2 = java.util.regex.Pattern.compile("/api/effect-pack/([1-9][0-9]*)(?:\\?enemy=1)?$").matcher(p6);
            if (v5_2.find()) {
                long v5_4 = Long.parseLong(v5_2.group(1));
                int v2 = 0;
                while (v2 < p7.length()) {
                    if (p7.getLong(v2) != v5_4) {
                        v2++;
                    } else {
                        return 1;
                    }
                }
                return 0;
            } else {
                return 0;
            }
        } else {
            return 1;
        }
    }

    static com.personal.aihub.GameMetadata$Query metadataQuery(com.personal.aihub.GameMetadata$Query p6, com.personal.aihub.GameMetadata$Query p7, org.json.JSONArray p8, org.json.JSONArray p9)
    {
        com.personal.aihub.PreviewMetadata$3 v8_1 = com.personal.aihub.PreviewEffectPacks.normalize(p8);
        org.json.JSONObject v9_3 = com.personal.aihub.PreviewMetadata.sparkingEffects(p9);
        com.personal.aihub.PreviewMetadata.validateEffectSources(v8_1, v9_3);
        java.util.HashSet v0_1 = new java.util.HashSet();
        java.util.HashMap v1_1 = new java.util.HashMap();
        int v2 = 0;
        Long v3_0 = 0;
        while (v3_0 < v9_3.length()) {
            v0_1.add(Long.valueOf(v9_3.getLong(v3_0)));
            v3_0++;
        }
        while (v2 < v8_1.length()) {
            org.json.JSONObject v9_2 = v8_1.getJSONObject(v2);
            v1_1.put(Long.valueOf(v9_2.getLong("id")), v9_2);
            v2++;
        }
        return new com.personal.aihub.PreviewMetadata$3(v1_1, v0_1, p7, p6);
    }

    static String normalizeSource(String p2)
    {
        if ((p2 != null) && ((!p2.isEmpty()) && (!p2.equals("eclipse")))) {
            if (!p2.equals("sparking")) {
                throw new java.io.IOException("Unsupported preview database source.");
            } else {
                return p2;
            }
        } else {
            return "eclipse";
        }
    }

    static long normalizeVersion(Object p8)
    {
        if (p8 != 0) {
            if (!(p8 instanceof Number)) {
                throw new java.io.IOException("Choose a valid Sparking content version.");
            } else {
                long v2 = ((Number) p8).longValue();
                if ((!Double.isFinite(((Number) p8).doubleValue())) || ((((Number) p8).doubleValue() != ((double) v2)) || ((v2 < 1) || (v2 > 9007199254740991)))) {
                    throw new java.io.IOException("Choose a valid Sparking content version.");
                } else {
                    return v2;
                }
            }
        } else {
            return 0;
        }
    }

    static org.json.JSONObject resolve(android.content.Context p1, com.personal.aihub.PreviewCache p2, String p3, String p4)
    {
        return com.personal.aihub.PreviewMetadata.resolve(p1, p2, p3, p4, 0);
    }

    static org.json.JSONObject resolve(android.content.Context p6, com.personal.aihub.PreviewCache p7, String p8, String p9, org.json.JSONArray p10)
    {
        return com.personal.aihub.PreviewMetadata.resolve(p6, p7, p8, p9, p10, 0);
    }

    static org.json.JSONObject resolve(android.content.Context p7, com.personal.aihub.PreviewCache p8, String p9, String p10, org.json.JSONArray p11, org.json.JSONArray p12)
    {
        return com.personal.aihub.PreviewMetadata.resolve(p7, p8, p9, p10, p11, p12, "");
    }

    static org.json.JSONObject resolve(android.content.Context p8, com.personal.aihub.PreviewCache p9, String p10, String p11, org.json.JSONArray p12, org.json.JSONArray p13, String p14)
    {
        return com.personal.aihub.PreviewMetadata.resolve(p8, p9, p10, p11, p12, p13, p14, 0);
    }

    static org.json.JSONObject resolve(android.content.Context p10, com.personal.aihub.PreviewCache p11, String p12, String p13, org.json.JSONArray p14, org.json.JSONArray p15, String p16, org.json.JSONArray p17)
    {
        return com.personal.aihub.PreviewMetadata.resolve(p10, p11, p12, p13, p14, p15, p16, p17, 0);
    }

    static org.json.JSONObject resolve(android.content.Context p21, com.personal.aihub.PreviewCache p22, String p23, String p24, org.json.JSONArray p25, org.json.JSONArray p26, String p27, org.json.JSONArray p28, long p29)
    {
        String v1_6;
        com.personal.aihub.PreviewCache v3_1 = com.personal.aihub.PreviewMetadata.sparkingEffects(p28);
        Long v4_0 = com.personal.aihub.PreviewEffectPacks.normalize(p26);
        com.personal.aihub.PreviewMetadata.validateEffectSources(v4_0, v3_1);
        int v5_0 = new java.io.File(p21.getFilesDir(), "forge");
        String v6_0 = com.personal.aihub.PreviewMetadata.normalizeSource(p27);
        com.personal.aihub.PreviewMetadata$2 v7_1 = com.personal.aihub.PreviewMetadata.databaseFile(v5_0, v6_0, p29);
        if (v3_1.length() != 0) {
            v1_6 = com.personal.aihub.PreviewMetadata.databaseFile(v5_0, "sparking", p29);
        } else {
            v1_6 = 0;
        }
        org.json.JSONObject v2_2 = p21.getAssets().open("ui/data/preview-metadata-rules.json");
        try {
            com.personal.aihub.PreviewMetadata$1 v8_5 = new java.io.ByteArrayOutputStream();
        } catch (org.json.JSONObject v0_10) {
            String v1_5 = v0_10;
            if (v2_2 != null) {
                try {
                    v2_2.close();
                } catch (org.json.JSONObject v0_11) {
                    v1_5.addSuppressed(v0_11);
                }
            }
            throw v1_5;
        }
        try {
            org.json.JSONObject v10_1 = new byte[8192];
        } catch (org.json.JSONObject v0_8) {
            String v1_4 = v0_8;
            try {
                v8_5.close();
            } catch (org.json.JSONObject v0_9) {
                v1_4.addSuppressed(v0_9);
            }
            throw v1_4;
        }
        while(true) {
            java.io.File v11_3 = v2_2.read(v10_1);
            int v13 = 0;
            if (v11_3 == -1) {
                break;
            }
            if ((v8_5.size() + v11_3) > 1048576) {
                throw new java.io.IOException("Preview metadata rules exceed the limit");
            } else {
                v8_5.write(v10_1, 0, v11_3);
            }
        }
        org.json.JSONObject v10_3 = new org.json.JSONObject(v8_5.toString("UTF-8"));
        v8_5.close();
        if (v2_2 != null) {
            v2_2.close();
        }
        org.json.JSONObject v2_4 = new java.util.HashMap();
        while (v13 < v4_0.length()) {
            com.personal.aihub.PreviewMetadata$1 v8_0 = v4_0.getJSONObject(v13);
            v2_4.put(Long.valueOf(v8_0.getLong("id")), v8_0);
            v13++;
        }
        String v1_7 = new com.personal.aihub.GameMetadata;
        v1_7(new java.io.File(v5_0, "assets"), com.personal.aihub.PreviewMetadata.metadataQuery(new com.personal.aihub.PreviewMetadata$1(v7_1), new com.personal.aihub.PreviewMetadata$2(v1_6), v4_0, v3_1), v10_3, p24, p25);
        String v1_8 = v1_7.resolve(p23);
        Long v4_3 = java.util.regex.Pattern.compile("/api/effect-pack/([1-9][0-9]*)(?:\\?enemy=1)?$").matcher(p23);
        if ((!v4_3.find()) || (!v2_4.containsKey(Long.valueOf(Long.parseLong(v4_3.group(1)))))) {
            if (!com.personal.aihub.PreviewMetadata.localOnly(v6_0, p23, v3_1)) {
                try {
                    org.json.JSONObject v9_1 = new org.json.JSONObject(p22.text(p23, 1048576));
                } catch (org.json.JSONObject v0_13) {
                    if (v1_8 == null) {
                        throw v0_13;
                    } else {
                    }
                }
                return com.personal.aihub.GameMetadata.merge(v1_8, v9_1);
            } else {
                if (v1_8 == null) {
                    throw new java.io.IOException("This Sparking preview needs its matching imported character/effect resources. Download the selected unit\'s resources from Library; Eclipse metadata was not substituted.");
                } else {
                    return v1_8;
                }
            }
        } else {
            if (v1_8 == null) {
                throw new java.io.IOException("Your edited movie is missing. Reopen or reattach it.");
            } else {
                return v1_8;
            }
        }
    }

    static boolean route(String p1)
    {
        return p1.matches("/api/(card|effect-pack)/[1-9][0-9]*(\\?enemy=1)?");
    }

    private static org.json.JSONObject row(java.io.File p1, String p2, long p3)
    {
        return com.personal.aihub.PreviewMetadata.rowFromFile(com.personal.aihub.PreviewMetadata.databaseFile(p1, ""), p2, p3);
    }

    private static org.json.JSONObject rowFromFile(java.io.File p4, String p5, long p6)
    {
        if ((p6 < 1) || (!java.util.Arrays.asList(new String[] {"cards", "characters", "effect_packs"})).contains(p5))) {
            throw new java.io.IOException("Unsupported preview metadata query");
        } else {
            if (p4.isFile()) {
                Throwable v4_4 = android.database.sqlite.SQLiteDatabase.openDatabase(p4.getPath(), 0, 1);
                try {
                    String v3_1 = new StringBuilder("SELECT * FROM \"");
                    v3_1.append(p5);
                    v3_1.append("\" WHERE id=? LIMIT 1");
                    Throwable v5_4 = v4_4.rawQuery(v3_1.toString(), new String[] {Long.toString(p6)}));
                    try {
                        if (v5_4.moveToFirst()) {
                            org.json.JSONObject v6_5 = new org.json.JSONObject();
                            String[] v7 = v5_4.getColumnNames();
                            int v0_1 = 0;
                            while (v0_1 < v7.length) {
                                Double v2_4;
                                Double v2_3 = v5_4.getType(v0_1);
                                if (v2_3 == null) {
                                    v2_4 = org.json.JSONObject.NULL;
                                } else {
                                    if (v2_3 == 1) {
                                        v2_4 = Long.valueOf(v5_4.getLong(v0_1));
                                    } else {
                                        if (v2_3 == 2) {
                                            v2_4 = Double.valueOf(v5_4.getDouble(v0_1));
                                        } else {
                                            v2_4 = v5_4.getString(v0_1);
                                        }
                                    }
                                }
                                v6_5.put(v7[v0_1], v2_4);
                                v0_1++;
                            }
                            if (v5_4 != null) {
                                v5_4.close();
                            }
                            if (v4_4 != null) {
                                v4_4.close();
                            }
                            return v6_5;
                        } else {
                            if (v5_4 != null) {
                                v5_4.close();
                            }
                            if (v4_4 != null) {
                                v4_4.close();
                            }
                            return 0;
                        }
                    } catch (org.json.JSONObject v6_6) {
                        if (v5_4 != null) {
                            try {
                                v5_4.close();
                            } catch (Throwable v5_5) {
                                v6_6.addSuppressed(v5_5);
                            }
                        }
                        throw v6_6;
                    }
                } catch (Throwable v5_6) {
                    if (v4_4 != null) {
                        try {
                            v4_4.close();
                        } catch (Throwable v4_5) {
                            v5_6.addSuppressed(v4_5);
                        }
                    }
                    throw v5_6;
                }
            } else {
                return 0;
            }
        }
    }

    static org.json.JSONArray sparkingEffects(Object p11)
    {
        if (p11 != null) {
            if (!(p11 instanceof org.json.JSONArray)) {
                throw new java.io.IOException("Choose valid Sparking animation effects.");
            } else {
                String v0_4 = new org.json.JSONArray();
                if (((org.json.JSONArray) p11).length() > 1024) {
                    throw new java.io.IOException("Choose up to 1024 Sparking animation effects.");
                } else {
                    java.util.HashSet v2_2 = new java.util.HashSet();
                    int v3_1 = 0;
                    while (v3_1 < ((org.json.JSONArray) p11).length()) {
                        boolean v4_1 = ((org.json.JSONArray) p11).opt(v3_1);
                        if (!(v4_1 instanceof Number)) {
                            throw new java.io.IOException("Choose valid Sparking animation effects.");
                        } else {
                            boolean v4_2 = ((Number) v4_1);
                            long v5_1 = v4_2.longValue();
                            if ((!Double.isFinite(v4_2.doubleValue())) || ((v4_2.doubleValue() != ((double) v5_1)) || ((v5_1 < 1) || ((v5_1 > 2147483647) || (!v2_2.add(Long.valueOf(v5_1))))))) {
                                throw new java.io.IOException("Choose unique valid Sparking animation effects.");
                            } else {
                                v0_4.put(v5_1);
                                v3_1++;
                            }
                        }
                    }
                    return v0_4;
                }
            }
        } else {
            return new org.json.JSONArray();
        }
    }

    static void validateEffectSources(org.json.JSONArray p5, org.json.JSONArray p6)
    {
        java.util.HashSet v0_1 = new java.util.HashSet();
        int v1 = 0;
        long v2_2 = 0;
        while (v2_2 < p6.length()) {
            v0_1.add(Long.valueOf(p6.getLong(v2_2)));
            v2_2++;
        }
        while (v1 < p5.length()) {
            if (v0_1.contains(Long.valueOf(p5.getJSONObject(v1).getLong("id")))) {
                throw new java.io.IOException("An edited movie and a Sparking effect cannot share the same preview effect ID.");
            } else {
                v1++;
            }
        }
        return;
    }
}
