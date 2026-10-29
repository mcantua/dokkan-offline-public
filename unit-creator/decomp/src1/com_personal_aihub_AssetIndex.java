package com.personal.aihub;
public final class AssetIndex {

    public AssetIndex()
    {
        return;
    }

    static String lambda$0(java.io.File p2)
    {
        String v2_1;
        StringBuilder v0_1 = new StringBuilder();
        v0_1.append(String.valueOf(p2.getName()));
        if (!p2.isDirectory()) {
            v2_1 = "";
        } else {
            v2_1 = "/";
        }
        v0_1.append(v2_1);
        return v0_1.toString();
    }

    public static org.json.JSONArray list(java.io.File p7, org.json.JSONObject p8)
    {
        if ((java.nio.file.Files.isSymbolicLink(p7.toPath())) || (!p7.isDirectory())) {
            throw new java.io.IOException("The imported asset folder is unavailable.");
        } else {
            org.json.JSONArray v0_2 = new org.json.JSONArray();
            com.personal.aihub.AssetIndex.walk(p7, p7, p8.optString("query").toLowerCase(java.util.Locale.ROOT), v0_2, new int[] {Math.max(0, p8.optInt("offset", 0))}), Math.max(1, Math.min(500, p8.optInt("limit", 100))));
            return v0_2;
        }
    }

    private static void walk(java.io.File p9, java.io.File p10, String p11, org.json.JSONArray p12, int[] p13, int p14)
    {
        java.io.File[] v10_1 = p10.listFiles();
        if (v10_1 != null) {
            java.util.Arrays.sort(v10_1, java.util.Comparator.comparing(new com.personal.aihub.AssetIndex$1()));
            int v0_3 = v10_1.length;
            int v2 = 0;
            while (v2 < v0_3) {
                boolean v4_0 = v10_1[v2];
                if (p12.length() < p14) {
                    if ((!v4_0.getName().equals("_databases")) && (!java.nio.file.Files.isSymbolicLink(v4_0.toPath()))) {
                        if (!v4_0.isDirectory()) {
                            org.json.JSONObject v3_8 = p9.toURI().relativize(v4_0.toURI()).getPath();
                            if (v3_8.toLowerCase(java.util.Locale.ROOT).contains(p11)) {
                                String v5_5 = p13[0];
                                if (v5_5 <= null) {
                                    String v5_8 = new org.json.JSONObject().put("key", v3_8);
                                    if (v3_8.contains("/")) {
                                        v3_8 = v3_8.substring((v3_8.indexOf(47) + 1));
                                    }
                                    p12.put(v5_8.put("path", v3_8.replaceFirst("^files/", "")).put("name", v4_0.getName()).put("size", v4_0.length()).put("image", v4_0.getName().matches("(?i).*\\.(png|jpe?g|webp|gif|bmp)$")));
                                } else {
                                    p13[0] = (v5_5 - 1);
                                }
                            }
                        } else {
                            com.personal.aihub.AssetIndex.walk(p9, v4_0, p11, p12, p13, p14);
                        }
                    }
                    v2++;
                } else {
                    return;
                }
            }
            return;
        } else {
            return;
        }
    }
}
