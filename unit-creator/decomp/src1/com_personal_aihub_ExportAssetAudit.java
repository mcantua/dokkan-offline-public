package com.personal.aihub;
public final class ExportAssetAudit {

    public ExportAssetAudit()
    {
        return;
    }

    public static org.json.JSONArray check(java.io.File p16, org.json.JSONArray p17)
    {
        int v2_1 = 500;
        if ((p17.length() > 500) || ((!p16.isDirectory()) || (java.nio.file.Files.isSymbolicLink(p16.toPath())))) {
            throw new java.io.IOException("The attached files could not be checked safely.");
        } else {
            String v1_4 = new org.json.JSONArray();
            String v3_1 = new StringBuilder();
            v3_1.append(p16.getCanonicalPath());
            v3_1.append(java.io.File.separator);
            String v3_2 = v3_1.toString();
            int v5 = 0;
            while (v5 < p17.length()) {
                if (!(p17.get(v5) instanceof String)) {
                    throw new java.io.IOException("Invalid attachment key.");
                } else {
                    int v6_6 = p17.getString(v5);
                    if ((v6_6.isEmpty()) || ((v6_6.length() > v2_1) || ((v6_6.startsWith("/")) || (v6_6.matches(".*[\\\\:\\x00-\\x1f\\x7f%].*"))))) {
                        throw new java.io.IOException("Invalid attachment key.");
                    } else {
                        String[] v8_3 = v6_6.split("/", -1);
                        long v9_4 = v8_3.length;
                        org.json.JSONObject v11_2 = p16;
                        int v10 = 0;
                        while (v10 < v9_4) {
                            String v12_0 = v8_3[v10];
                            if ((v12_0.isEmpty()) || ((v12_0.startsWith(".")) || (java.util.Arrays.asList(new String[] {"_databases", "projects", "patches", "exports"})).contains(v12_0.toLowerCase(java.util.Locale.ROOT))))) {
                                throw new java.io.IOException("Invalid attachment key.");
                            } else {
                                int v2_7 = new java.io.File(v11_2, v12_0);
                                if (java.nio.file.Files.isSymbolicLink(v2_7.toPath())) {
                                    throw new java.io.IOException("Attached files cannot use symbolic links.");
                                } else {
                                    v10++;
                                    v11_2 = v2_7;
                                }
                            }
                        }
                        if (!v11_2.getCanonicalPath().startsWith(v3_2)) {
                            throw new java.io.IOException("Invalid attachment location.");
                        } else {
                            long v9_5;
                            if (!v11_2.isFile()) {
                                v9_5 = 0;
                            } else {
                                v9_5 = v11_2.length();
                            }
                            int v6_2;
                            org.json.JSONObject vtmp30 = new org.json.JSONObject().put("key", v6_6).put("bytes", v9_5);
                            if ((!v11_2.isFile()) || ((!v11_2.canRead()) || ((v9_5 <= 0) || (v9_5 > 536870912)))) {
                                v6_2 = 0;
                            } else {
                                v6_2 = 1;
                            }
                            v1_4.put(vtmp30.put("available", v6_2));
                            v5++;
                            v2_1 = 500;
                        }
                    }
                }
            }
            return v1_4;
        }
    }
}
