package com.personal.aihub;
public final class SprkEclp {

    private SprkEclp()
    {
        return;
    }

    public static org.json.JSONObject convert(java.io.File p17, java.io.File p18, java.io.File p19, java.io.File p20, String p21)
    {
        if (!p18.isDirectory()) {
            throw new java.io.IOException("Could not create Sparking conversion staging.");
        } else {
            if (p19.exists()) {
                throw new java.io.IOException("Choose a new output file for Sparking conversion.");
            } else {
                Throwable v1_11 = new java.io.File(p18, "payload");
                org.json.JSONObject v3_1 = com.personal.aihub.SprkCodec.inspect(p17, v1_11);
                String v5_11 = 0;
                if (v3_1.getBoolean("canConvertToEclp")) {
                    java.io.File v4_8 = v3_1.getJSONObject("patchInfo");
                    com.personal.aihub.EclpCodec$Entry v7_9 = "";
                    int v6_8 = v4_8.optString("name", v4_8.optString("patch_name", p21.replaceFirst("(?i)\\.sprk$", ""))).trim();
                    if (v6_8.isEmpty()) {
                        v6_8 = "Imported Sparking patch";
                    }
                    if (v6_8.length() > 160) {
                        v6_8 = v6_8.substring(0, 160);
                    }
                    String v15;
                    String v14 = v6_8;
                    int v10_9 = v4_8.optString("version", "1.0").trim();
                    if ((!v10_9.isEmpty()) && (v10_9.length() <= 50)) {
                        v15 = v10_9;
                    } else {
                        v15 = "1.0";
                    }
                    Throwable v0_2 = new org.json.JSONObject().put("uuid", java.util.UUID.randomUUID().toString()).put("name", v14).put("version", v15).put("author", v3_1.optString("creatorName")).put("description", v4_8.optString("description")).put("sourceFormat", "sparking-sprk").put("sourceFilename", p21).put("sourceZIPsha256", com.personal.aihub.GameDataStore.hash(p17)).put("compatibility", "Format converted; Eclipse SQL and gameplay compatibility need validation in Eclipse.");
                    Throwable v2_3 = new java.util.ArrayList();
                    int v6_2 = new java.util.HashSet();
                    java.io.File v8_1 = v3_1.getJSONArray("entries");
                    String v9_0 = 0;
                    while (v9_0 < v8_1.length()) {
                        boolean v21_1;
                        String v16_2;
                        int v10_4 = v8_1.getJSONObject(v9_0);
                        String v13_2 = v10_4.getString("kind");
                        if ((v13_2.equals("gameSql")) || (v13_2.equals("asset"))) {
                            v16_2 = v7_9;
                            com.personal.aihub.EclpCodec$Entry v7_2 = v10_4.getString("relativePath");
                            if (!v13_2.equals("asset")) {
                                v21_1 = v8_1;
                            } else {
                                v21_1 = v8_1;
                                if (v7_2.toLowerCase(java.util.Locale.ROOT).endsWith(".sql")) {
                                    throw new java.io.IOException("A Sparking asset ends in .sql and could be executed by Eclipse. Conversion was stopped.");
                                }
                            }
                            String v5_9;
                            java.io.File v8_7 = new StringBuilder("files/");
                            if (!v13_2.equals("gameSql")) {
                                v5_9 = v16_2;
                            } else {
                                v5_9 = "sparking-sql/";
                            }
                            v8_7.append(v5_9);
                            v8_7.append(v7_2);
                            String v5_10 = v8_7.toString();
                            if (!v6_2.add(java.text.Normalizer.normalize(v5_10, java.text.Normalizer$Form.NFC).toLowerCase(java.util.Locale.ROOT))) {
                                throw new java.io.IOException("Sparking SQL and assets would overwrite the same Eclipse file.");
                            } else {
                                v2_3.add(new com.personal.aihub.EclpCodec$Entry(v5_10, new java.io.File(v1_11, v10_4.getString("path")), 0));
                            }
                        } else {
                            v16_2 = v7_9;
                            v21_1 = v8_1;
                        }
                        v9_0++;
                        v8_1 = v21_1;
                        v7_9 = v16_2;
                    }
                    Throwable v1_1 = v6_2.iterator();
                    while (v1_1.hasNext()) {
                        String v5_6 = ((String) v1_1.next());
                        java.io.File v8_2 = v5_6.indexOf(47);
                        while (v8_2 >= null) {
                            if (v6_2.contains(v5_6.substring(0, v8_2))) {
                                throw new java.io.IOException("An Eclipse file would overwrite a converted resource folder.");
                            } else {
                                v8_2 = v5_6.indexOf(47, (v8_2 + 1));
                            }
                        }
                    }
                    v2_3.add(new com.personal.aihub.EclpCodec$Entry("sparking-source.json", 0, v4_8.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8)));
                    v2_3.add(new com.personal.aihub.EclpCodec$Entry("metadata.json", 0, v0_2.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8)));
                    try {
                        try {
                            Throwable v1_7 = new java.io.FileOutputStream(p19);
                            try {
                                com.personal.aihub.EclpCodec.write(v1_7, p20, v2_3, v0_2.toString(), v0_2.getString("uuid"), v14, v15);
                            } catch (Throwable v0_6) {
                                Throwable v2_4 = v0_6;
                                try {
                                    v1_7.close();
                                } catch (Throwable v0_7) {
                                    v2_4.addSuppressed(v0_7);
                                }
                                throw v2_4;
                            }
                            v1_7.close();
                            return v3_1.put("metadata", v0_2);
                        } catch (Throwable v0_5) {
                            p19.delete();
                            throw v0_5;
                        }
                    } catch (Throwable v0_5) {
                    }
                } else {
                    Throwable v0_16 = v3_1.getJSONArray("warnings");
                    Throwable v1_17 = new StringBuilder("This patch uses Sparking features that cannot yet be converted safely to Eclipse.");
                    while (v5_11 < v0_16.length()) {
                        v1_17.append(" ");
                        v1_17.append(v0_16.getString(v5_11));
                        v5_11++;
                    }
                    throw new java.io.IOException(v1_17.toString());
                }
            }
        }
    }
}
