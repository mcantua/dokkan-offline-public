package com.personal.aihub;
final class PreviewEffectPacks {

    PreviewEffectPacks()
    {
        return;
    }

    private static long integer(Object p8, long p9, long p11)
    {
        if (!(p8 instanceof Number)) {
            throw new java.io.IOException("The edited movie preview is invalid. Reopen it from your unit.");
        } else {
            long v2 = ((Number) p8).longValue();
            if ((((Number) p8).doubleValue() != ((double) v2)) || ((v2 < p9) || (v2 > p11))) {
                throw new java.io.IOException("The edited movie preview is invalid. Reopen it from your unit.");
            } else {
                return v2;
            }
        }
    }

    static org.json.JSONArray normalize(Object p22)
    {
        if (p22 != null) {
            if (!(p22 instanceof org.json.JSONArray)) {
                throw new java.io.IOException("Choose a supported number of edited movies.");
            } else {
                java.io.IOException v0_9 = ((org.json.JSONArray) p22);
                if (((org.json.JSONArray) p22).length() > 128) {
                    throw new java.io.IOException("Choose a supported number of edited movies.");
                } else {
                    Integer v4 = "pack_name";
                    int v6 = "name";
                    long v8 = "green";
                    java.util.HashSet v1_5 = new java.util.HashSet(java.util.Arrays.asList(new String[] {"id", "lite_flicker_rate"})));
                    int v2_14 = new java.util.HashSet();
                    java.util.HashSet v3_6 = new java.util.HashSet();
                    Integer v4_2 = new org.json.JSONArray();
                    int v6_0 = 0;
                    while (v6_0 < v0_9.length()) {
                        org.json.JSONObject v7_1 = v0_9.getJSONObject(v6_0);
                        long v8_3 = v7_1.keys();
                        while (v8_3.hasNext()) {
                            if (!v1_5.contains(v8_3.next())) {
                                throw new java.io.IOException("The edited movie preview is invalid. Reopen it from your unit.");
                            }
                        }
                        long v11_2 = com.personal.aihub.PreviewEffectPacks.integer(v7_1.opt("id"), 1, 2147483647);
                        int v16 = v6_0;
                        java.io.IOException v17 = v0_9;
                        java.util.HashSet v18 = v1_5;
                        java.io.IOException v0_16 = com.personal.aihub.PreviewEffectPacks.integer(v7_1.opt("category"), 1, 5);
                        String v5_2 = v7_1.opt("pack_name");
                        if ((v5_2 instanceof String)) {
                            int v6_4 = ((String) v5_2);
                            if (((v6_4.matches("forge_movie_[1-9][0-9]{0,9}_[0-9]{1,2}_[0-9a-f]{32}")) && ((com.personal.aihub.PreviewEffectPacks.validPack(v6_4)) && ((v0_16 == 1) || (v0_16 == 5)))) && ((v3_6.add(Long.valueOf(v11_2))) && (v2_14.add(v6_4)))) {
                                long v10_1;
                                Object v13_0 = "";
                                if (!v7_1.has("scene_name")) {
                                    v10_1 = "";
                                } else {
                                    v10_1 = v7_1.get("scene_name");
                                }
                                if (v7_1.has("name")) {
                                    v13_0 = v7_1.get("name");
                                }
                                org.json.JSONArray v19_1 = v2_14;
                                if ((v10_1 instanceof String)) {
                                    java.util.HashSet v20 = v3_6;
                                    if ((((String) v10_1).matches("[A-Za-z0-9_]{0,100}")) && ((v13_0 instanceof String))) {
                                        int v2_6 = ((String) v13_0);
                                        org.json.JSONArray v21 = v4_2;
                                        if ((v2_6.length() <= 160) && (!v2_6.matches("(?s).*[\\x00-\\x1f\\x7f].*"))) {
                                            java.io.IOException v0_8 = new org.json.JSONObject().put("id", v11_2).put("category", v0_16).put("pack_name", v5_2).put("scene_name", v10_1).put("name", v13_0);
                                            int v2_12 = 0;
                                            while (v2_12 < 5) {
                                                Integer v4_6;
                                                java.util.HashSet v3_7 = new String[] {"red", "green", "blue", "alpha", "lite_flicker_rate"})[v2_12];
                                                int v6_1 = 255;
                                                if (!v7_1.has(v3_7)) {
                                                    Integer v4_5;
                                                    if (!v3_7.equals("lite_flicker_rate")) {
                                                        v4_5 = 255;
                                                    } else {
                                                        v4_5 = 70;
                                                    }
                                                    v4_6 = Integer.valueOf(v4_5);
                                                } else {
                                                    v4_6 = v7_1.get(v3_7);
                                                }
                                                if (v3_7.equals("lite_flicker_rate")) {
                                                    v6_1 = 100;
                                                }
                                                v0_8.put(v3_7, com.personal.aihub.PreviewEffectPacks.integer(v4_6, 0, ((long) v6_1)));
                                                v2_12++;
                                            }
                                            int v2_13 = v21;
                                            v2_13.put(v0_8);
                                            v6_0 = (v16 + 1);
                                            v4_2 = v2_13;
                                            v0_9 = v17;
                                            v1_5 = v18;
                                            v2_14 = v19_1;
                                            v3_6 = v20;
                                        }
                                    }
                                }
                                throw new java.io.IOException("The edited movie label is invalid.");
                            }
                        }
                        throw new java.io.IOException("The edited movie preview is invalid. Reopen it from your unit.");
                    }
                    return v4_2;
                }
            }
        } else {
            return new org.json.JSONArray();
        }
    }

    private static boolean validPack(String p7)
    {
        boolean v7_2 = p7.split("_");
        int v1 = 0;
        try {
            String v2_3 = Long.parseLong(v7_2[2]);
            int v4_0 = Integer.parseInt(v7_2[3]);
        } catch (Exception) {
            return v1;
        }
        if ((v2_3 > 1999999000) || ((v4_0 > 47) || (!Integer.toString(v4_0).equals(v7_2[3])))) {
            return v1;
        } else {
            v1 = 1;
            return v1;
        }
    }
}
