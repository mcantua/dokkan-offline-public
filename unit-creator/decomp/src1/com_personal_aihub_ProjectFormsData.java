package com.personal.aihub;
final class ProjectFormsData {

    ProjectFormsData()
    {
        return;
    }

    private static void replace(Object p4, java.util.Map p5, int p6)
    {
        if (p6 > 80) {
            throw new java.io.IOException("The embedded unit is too deeply nested.");
        } else {
            if (!(p4 instanceof org.json.JSONObject)) {
                if ((p4 instanceof org.json.JSONArray)) {
                    int v0_1 = 0;
                    while (v0_1 < ((org.json.JSONArray) p4).length()) {
                        Object v1_1 = ((org.json.JSONArray) p4).get(v0_1);
                        if ((!(v1_1 instanceof String)) || (!p5.containsKey(v1_1))) {
                            if (((v1_1 instanceof org.json.JSONObject)) || ((v1_1 instanceof org.json.JSONArray))) {
                                com.personal.aihub.ProjectFormsData.replace(v1_1, p5, (p6 + 1));
                            }
                        } else {
                            ((org.json.JSONArray) p4).put(v0_1, p5.get(v1_1));
                        }
                        v0_1++;
                    }
                }
            } else {
                int v0_2 = ((org.json.JSONObject) p4).keys();
                while (v0_2.hasNext()) {
                    Object v1_5 = ((String) v0_2.next());
                    int v2_5 = ((org.json.JSONObject) p4).get(v1_5);
                    if ((!(v2_5 instanceof String)) || (!p5.containsKey(v2_5))) {
                        if (((v2_5 instanceof org.json.JSONObject)) || ((v2_5 instanceof org.json.JSONArray))) {
                            com.personal.aihub.ProjectFormsData.replace(v2_5, p5, (p6 + 1));
                        }
                    } else {
                        ((org.json.JSONObject) p4).put(v1_5, p5.get(v2_5));
                    }
                }
            }
            return;
        }
    }

    static org.json.JSONArray reservedIds(org.json.JSONObject p5)
    {
        String v0_3 = new org.json.JSONArray().put(p5.getLong("targetId"));
        java.io.IOException v5_3 = p5.optJSONArray("formProjects");
        if (v5_3 != null) {
            if (v5_3.length() > 4) {
                throw new java.io.IOException("A unit supports up to four transformation forms.");
            } else {
                int v2_1 = 0;
                while (v2_1 < v5_3.length()) {
                    v0_3.put(v5_3.getJSONObject(v2_1).getLong("targetId"));
                    v2_1++;
                }
            }
        }
        return v0_3;
    }

    static void restore(org.json.JSONObject p18, String p19, java.io.File p20)
    {
        int v2_0 = new org.json.JSONArray().put(p18);
        java.util.HashMap v4_2 = p18.optJSONArray("formProjects");
        if (v4_2 != null) {
            if (v4_2.length() > 4) {
                throw new java.io.IOException("Too many embedded forms.");
            } else {
                int v7_2 = 0;
                while (v7_2 < v4_2.length()) {
                    org.json.JSONObject v8_1 = v4_2.getJSONObject(v7_2);
                    if ((v8_1.has("formProjects")) || (v8_1.has("transformLinks"))) {
                        throw new java.io.IOException("Nested transformation forms are not supported.");
                    } else {
                        v2_0.put(v8_1);
                        v7_2++;
                    }
                }
            }
        }
        java.util.HashMap v3_1 = new java.util.HashMap();
        java.util.HashMap v4_1 = new java.util.HashMap();
        int v7_0 = 0;
        while (v7_0 < v2_0.length()) {
            org.json.JSONObject v8_4 = v2_0.getJSONObject(v7_0);
            if ((!"dokkan-unit-forge".equals(v8_4.optString("format"))) || ((v8_4.optInt("version") != 1) || (v8_4.getJSONObject("tables").getJSONArray("cards").length() != 1))) {
                throw new java.io.IOException("Invalid embedded unit form.");
            } else {
                org.json.JSONArray v10_6 = v8_4.getString("key");
                String v11_3 = new StringBuilder("unit-");
                v11_3.append(v8_4.getLong("targetId"));
                v11_3.append("-");
                v11_3.append(p19);
                String v11_4 = v11_3.toString();
                v4_1.put(v10_6, v11_4);
                v8_4.put("key", v11_4);
                org.json.JSONArray v10_1 = v8_4.optJSONArray("assets");
                String v12_0 = 0;
                if (v10_1 != null) {
                    int v13 = 0;
                    while (v13 < v10_1.length()) {
                        org.json.JSONObject v14_1 = v10_1.getJSONObject(v13);
                        String v15_1 = new StringBuilder("files/");
                        v15_1.append(v14_1.getString("path"));
                        boolean v6_3 = v15_1.toString();
                        if (com.personal.aihub.EclpCodec.safePath(v6_3)) {
                            int v16_1 = v2_0;
                            if (new java.io.File(p20, v6_3).isFile()) {
                                String v15_6 = v14_1.getString("key");
                                org.json.JSONArray v17 = v10_1;
                                int v2_3 = new StringBuilder("patch-");
                                v2_3.append(p19);
                                v2_3.append("/");
                                v2_3.append(v6_3);
                                int v2_4 = v2_3.toString();
                                if (v15_6.equals(v8_4.optString("previewKey"))) {
                                    v12_0 = v2_4;
                                }
                                if (!v3_1.containsKey(v15_6)) {
                                    v3_1.put(v15_6, v2_4);
                                }
                                v14_1.put("key", v2_4);
                                v13++;
                                v2_0 = v16_1;
                                v10_1 = v17;
                            }
                        }
                        throw new java.io.IOException("Embedded form resource missing.");
                    }
                }
                int v16_0 = v2_0;
                if (v12_0 == null) {
                    v8_4.remove("previewKey");
                } else {
                    v8_4.put("previewKey", v12_0);
                }
                v7_0++;
                v2_0 = v16_0;
            }
        }
        String v1_4 = p18.optJSONArray("transformLinks");
        if (v1_4 != null) {
            int v2_7 = 0;
            while (v2_7 < v1_4.length()) {
                org.json.JSONObject v5_1 = v1_4.getJSONObject(v2_7);
                int v7_5 = ((String) v4_1.get(v5_1.getString("targetKey")));
                if (v7_5 == 0) {
                    throw new java.io.IOException("An embedded transformation form is missing.");
                } else {
                    v5_1.put("targetKey", v7_5);
                    v2_7++;
                }
            }
        }
        com.personal.aihub.ProjectFormsData.replace(p18, v3_1, 0);
        return;
    }
}
