package com.personal.aihub;
final class PreviewScripts {
    private static final java.util.regex.Pattern PATH;

    static PreviewScripts()
    {
        com.personal.aihub.PreviewScripts.PATH = java.util.regex.Pattern.compile("(?i)ab_script/[a-z0-9_/-]+\\.lua");
        return;
    }

    PreviewScripts()
    {
        return;
    }

    static void add(java.util.Set p3, org.json.JSONArray p4)
    {
        if (p4 != null) {
            int v0 = 0;
            while (v0 < p4.length()) {
                String v1_0;
                String v1_3 = p4.opt(v0);
                if (!(v1_3 instanceof org.json.JSONObject)) {
                    if (!(v1_3 instanceof String)) {
                        v1_0 = "";
                    } else {
                        v1_0 = ((String) v1_3);
                    }
                } else {
                    v1_0 = ((org.json.JSONObject) v1_3).optString("path");
                }
                if (com.personal.aihub.PreviewScripts.valid(v1_0)) {
                    p3.add(v1_0);
                }
                v0++;
            }
            return;
        } else {
            return;
        }
    }

    static void imported(java.io.File p14, java.util.Set p15)
    {
        if ((p14 != null) && (p14.exists())) {
            if ((java.nio.file.Files.isSymbolicLink(p14.toPath())) || (!p14.isDirectory())) {
                throw new java.io.IOException("Invalid imported animation folder");
            } else {
                java.io.File[] v0_1 = p14.listFiles();
                if (v0_1 == null) {
                    throw new java.io.IOException("Imported animations cannot be read");
                } else {
                    if (v0_1.length > 4096) {
                        throw new java.io.IOException("Too many imported animation collections");
                    } else {
                        int[] v1_2 = new int[1];
                        int v8 = v0_1.length;
                        int v10 = 0;
                        while (v10 < v8) {
                            java.io.File v11 = v0_1[v10];
                            if ((v11.isDirectory()) && ((!java.nio.file.Files.isSymbolicLink(v11.toPath())) && (com.personal.aihub.GameAssets.safe(v11.getName())))) {
                                int v13 = 0;
                                while (v13 < 3) {
                                    com.personal.aihub.PreviewScripts.walk(new java.io.File(v11, new String[] {"lua/ab_script", "files/lua/ab_script", "tutorial0/lua/ab_script"})[v13]), "ab_script", p15, v1_2, 0, p14);
                                    v13++;
                                }
                            }
                            v10++;
                        }
                        return;
                    }
                }
            }
        } else {
            return;
        }
    }

    static org.json.JSONObject listing(android.content.Context p9, java.io.File p10)
    {
        org.json.JSONObject v9_8 = p9.getAssets().open("ui/data/preview-script-index.json");
        try {
            int v0_3 = new java.io.ByteArrayOutputStream();
        } catch (org.json.JSONObject v10_10) {
            if (v9_8 != null) {
                try {
                    v9_8.close();
                } catch (org.json.JSONObject v9_14) {
                    v10_10.addSuppressed(v9_14);
                }
            }
            throw v10_10;
        }
        try {
            org.json.JSONObject v1_4 = new byte[8192];
        } catch (org.json.JSONObject v10_9) {
            try {
                v0_3.close();
            } catch (int v0_4) {
                v10_9.addSuppressed(v0_4);
            }
            throw v10_9;
        }
        while(true) {
            String v2_0 = v9_8.read(v1_4);
            int v4 = 0;
            if (v2_0 == -1) {
                break;
            }
            if ((v0_3.size() + v2_0) > 2097152) {
                throw new java.io.IOException("The packaged script index is too large");
            } else {
                v0_3.write(v1_4, 0, v2_0);
            }
        }
        org.json.JSONObject v1_1 = new org.json.JSONObject(new String(v0_3.toByteArray(), java.nio.charset.StandardCharsets.UTF_8));
        v0_3.close();
        if (v9_8 != null) {
            v9_8.close();
        }
        if (v1_1.optInt("schemaVersion") != 1) {
            throw new java.io.IOException("Update Dokkan Unit Creator to load the packaged animation catalog");
        } else {
            org.json.JSONObject v9_7 = new java.util.TreeSet();
            com.personal.aihub.PreviewScripts.add(v9_7, v1_1.optJSONArray("scripts"));
            if (v9_7.isEmpty()) {
                throw new java.io.IOException("The packaged animation catalog is empty");
            } else {
                int v3_4 = v9_7.size();
                com.personal.aihub.PreviewScripts.imported(p10, v9_7);
                org.json.JSONObject v10_4 = new org.json.JSONArray();
                java.util.Iterator v5_1 = v9_7.iterator();
                while (v5_1.hasNext()) {
                    v10_4.put(new org.json.JSONObject().put("path", ((String) v5_1.next())));
                }
                org.json.JSONObject v10_6 = v1_1.put("scripts", v10_4).put("count", v10_4.length());
                if (v9_7.size() > v3_4) {
                    v4 = 1;
                }
                return v10_6.put("includesImported", v4);
            }
        }
    }

    static boolean valid(String p2)
    {
        if ((p2 == 0) || ((p2.length() >= 240) || ((!com.personal.aihub.PreviewScripts.PATH.matcher(p2).matches()) || (!com.personal.aihub.GameAssets.safe(p2))))) {
            int v2_2 = 0;
        } else {
            v2_2 = 1;
        }
        return v2_2;
    }

    private static void walk(java.io.File p10, String p11, java.util.Set p12, int[] p13, int p14, java.io.File p15)
    {
        if ((p14 <= 24) && (p10.exists())) {
            int v0_4 = p10;
            while ((v0_4 != 0) && (!v0_4.equals(p15))) {
                if (java.nio.file.Files.isSymbolicLink(v0_4.toPath())) {
                    throw new java.io.IOException("Imported animations cannot use symbolic links");
                } else {
                    v0_4 = v0_4.getParentFile();
                }
            }
            if (p10.isDirectory()) {
                java.io.IOException v10_1 = p10.listFiles();
                if (v10_1 == null) {
                    throw new java.io.IOException("Imported animations cannot be read");
                } else {
                    int v0_2 = v10_1.length;
                    int v3 = 0;
                    while (v3 < v0_2) {
                        boolean v4_0 = v10_1[v3];
                        String v5_1 = (p13[0] + 1);
                        p13[0] = v5_1;
                        if (v5_1 > 50000) {
                            throw new java.io.IOException("The imported animation catalog exceeds its 50,000-entry limit");
                        } else {
                            if (com.personal.aihub.GameAssets.safe(v4_0.getName())) {
                                if (java.nio.file.Files.isSymbolicLink(v4_0.toPath())) {
                                    throw new java.io.IOException("Imported animations cannot use symbolic links");
                                } else {
                                    String v5_7 = new StringBuilder();
                                    v5_7.append(String.valueOf(p11));
                                    v5_7.append("/");
                                    v5_7.append(v4_0.getName());
                                    String v5_8 = v5_7.toString();
                                    if (!v4_0.isDirectory()) {
                                        if ((v4_0.isFile()) && ((v4_0.length() > 0) && ((v4_0.length() <= 2097152) && (com.personal.aihub.PreviewScripts.valid(v5_8))))) {
                                            p12.add(v5_8);
                                        }
                                    } else {
                                        com.personal.aihub.PreviewScripts.walk(v4_0, v5_8, p12, p13, (p14 + 1), p15);
                                    }
                                }
                            }
                            v3++;
                        }
                    }
                }
            }
        }
        return;
    }
}
