package com.personal.aihub;
final class PreviewTools {
    private static final java.util.Map JOBS = None;
    private static final String ORIGIN = "https://dokkan-eclipse.com";
    private final com.personal.aihub.PreviewCache cache;
    private final java.util.List entries;
    private final String key;
    private final long total;
    private final String version;

    static PreviewTools()
    {
        com.personal.aihub.PreviewTools.JOBS = new java.util.HashMap();
        return;
    }

    PreviewTools(android.content.Context p19, java.io.File p20)
    {
        this.entries = new java.util.ArrayList();
        this.cache = new com.personal.aihub.PreviewCache(p20);
        this.key = p20.getCanonicalPath();
        String v2_1 = p19.getAssets().open("ui/data/preview-bootstrap.json");
        try {
            int v3_6 = new java.io.ByteArrayOutputStream();
        } catch (java.io.IOException v0_15) {
            int v3_11 = v0_15;
            if (v2_1 != null) {
                try {
                    v2_1.close();
                } catch (java.io.IOException v0_16) {
                    v3_11.addSuppressed(v0_16);
                }
            }
            throw v3_11;
        }
        try {
            java.io.IOException v0_6 = new byte[8192];
        } catch (java.io.IOException v0_13) {
            String v4_2 = v0_13;
            try {
                v3_6.close();
            } catch (java.io.IOException v0_14) {
                v4_2.addSuppressed(v0_14);
            }
            throw v4_2;
        }
        while(true) {
            String v4_0 = v2_1.read(v0_6);
            int v6_5 = -1;
            if (v4_0 == -1) {
                break;
            }
            if ((v3_6.size() + v4_0) > 262144) {
                throw new java.io.IOException("Preview tools manifest is too large");
            } else {
                v3_6.write(v0_6, 0, v4_0);
            }
        }
        java.io.IOException v0_19 = new org.json.JSONObject(new String(v3_6.toByteArray(), java.nio.charset.StandardCharsets.UTF_8));
        v3_6.close();
        if (v2_1 != null) {
            v2_1.close();
        }
        if ((v0_19.getInt("schemaVersion") != 1) || (!"https://dokkan-eclipse.com".equals(v0_19.getString("origin")))) {
            throw new java.io.IOException("Unsupported preview tools manifest");
        } else {
            String v2_13 = v0_19.getString("version");
            this.version = v2_13;
            if (!v2_13.matches("[a-f0-9]{64}")) {
                throw new java.io.IOException("Invalid preview tools version");
            } else {
                java.io.IOException v0_25 = v0_19.getJSONArray("resources");
                if ((v0_25.length() < 1) || (v0_25.length() > 256)) {
                    throw new java.io.IOException("Invalid preview tools count");
                } else {
                    String v2_22 = new java.util.HashSet();
                    long v7_0 = 0;
                    int v9 = 0;
                    while (v9 < v0_25.length()) {
                        int v3_4;
                        String v10_11 = v0_25.getJSONObject(v9);
                        com.personal.aihub.PreviewTools$Entry v11_1 = new com.personal.aihub.PreviewTools$Entry(0);
                        v11_1.path = v10_11.getString("path");
                        v11_1.hash = v10_11.getString("sha256");
                        v11_1.label = v10_11.getString("label");
                        Number v13_0 = v10_11.get("bytes");
                        long v14 = v10_11.getLong("bytes");
                        String v10_1 = new java.net.URI(v11_1.path);
                        double v12_4 = v10_1.getPath();
                        if ((!v11_1.path.equals("/api/scripts")) && (!v11_1.path.equals("/api/script?path=ab_script%2Fcommon%2Fcommon.lua"))) {
                            v3_4 = 0;
                        } else {
                            v3_4 = 1;
                        }
                        if (((v10_1.isAbsolute()) || ((v10_1.getRawAuthority() != null) || ((v10_1.getRawFragment() != null) || ((v12_4 == 0) || ((v12_4.contains("\\")) || ((!v12_4.startsWith("/")) || ((v12_4.contains("//")) || ((v12_4.matches(".*[\\x00-\\x1f\\x7f].*")) || ((java.util.Arrays.asList(v12_4.split("/", v6_5)).contains("..")) || ((java.util.Arrays.asList(v12_4.split("/", -1)).contains(".")) || ((!v12_4.startsWith("/tools/")) && ((!v12_4.startsWith("/static/")) && ((!v12_4.startsWith("/css/")) && (v3_4 == 0)))))))))))))) || (!v2_22.add(v11_1.path))) {
                            throw new java.io.IOException("Invalid preview tools resource");
                        } else {
                            if ((v13_0 instanceof Number)) {
                                long v16 = v7_0;
                                if ((((Number) v13_0).doubleValue() == ((double) v14)) && ((v14 >= 1) && ((v14 <= 2097152) && ((v11_1.hash.matches("[a-f0-9]{64}")) && (v11_1.label.length() <= 160))))) {
                                    v11_1.bytes = ((int) v14);
                                    v7_0 = (v16 + v14);
                                    if (v7_0 > 16777216) {
                                        throw new java.io.IOException("Preview tools exceed their size limit");
                                    } else {
                                        this.entries.add(v11_1);
                                        v9++;
                                        int v5 = 0;
                                        v6_5 = -1;
                                    }
                                }
                            }
                            throw new java.io.IOException("Invalid preview tools checksum or size");
                        }
                    }
                    this.total = v7_0;
                    return;
                }
            }
        }
    }

    private com.personal.aihub.PreviewTools$Job job()
    {
        java.util.Map v0 = com.personal.aihub.PreviewTools.JOBS;
        try {
            com.personal.aihub.PreviewTools$Job v1_3 = ((com.personal.aihub.PreviewTools$Job) v0.get(this.key));
        } catch (com.personal.aihub.PreviewTools$Job v1_1) {
            throw v1_1;
        }
        if (v1_3 == null) {
            v1_3 = new com.personal.aihub.PreviewTools$Job(0);
            v0.put(this.key, v1_3);
        }
        return v1_3;
    }

    private boolean matches(com.personal.aihub.PreviewTools$Entry p10)
    {
        String v0_0 = this.cache;
        int v1_2 = new StringBuilder("https://dokkan-eclipse.com");
        v1_2.append(p10.path);
        String v0_9 = v0_0.cachedBody(v1_2.toString());
        int v1_1 = 0;
        if ((v0_9 != null) && (v0_9.length() == ((long) p10.bytes))) {
            byte[] v2_4 = java.security.MessageDigest.getInstance("SHA-256");
            int v3_1 = new java.io.FileInputStream(v0_9);
            try {
                String v0_2 = new byte[8192];
                String v4_2 = 0;
            } catch (boolean v10_3) {
                try {
                    v3_1.close();
                } catch (String v0_8) {
                    v10_3.addSuppressed(v0_8);
                }
                throw v10_3;
            }
            while(true) {
                String v6_0 = v3_1.read(v0_2);
                if (v6_0 == -1) {
                    break;
                }
                v4_2 += ((long) v6_0);
                if (v4_2 <= ((long) p10.bytes)) {
                    v2_4.update(v0_2, 0, v6_0);
                } else {
                    v3_1.close();
                    return 0;
                }
            }
            v3_1.close();
            if (v4_2 == ((long) p10.bytes)) {
                String v0_6 = new StringBuilder();
                byte[] v2_5 = v2_4.digest();
                int v3_2 = v2_5.length;
                while (v1_1 < v3_2) {
                    v0_6.append(String.format(java.util.Locale.US, "%02x", new Object[] {Integer.valueOf((v2_5[v1_1] & 255))})));
                    v1_1++;
                }
                return p10.hash.equals(v0_6.toString());
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    private org.json.JSONObject status(com.personal.aihub.PreviewTools$Job p12)
    {
        org.json.JSONObject v0_3 = this.entries.iterator();
        long v1_0 = 0;
        boolean v3_0 = 0;
        int v4_2 = 0;
        int v5 = 0;
        int v6 = 0;
        while (v0_3.hasNext()) {
            long v7_10 = ((com.personal.aihub.PreviewTools$Entry) v0_3.next());
            boolean v8_3 = this.cache;
            int v9_4 = new StringBuilder();
            v9_4.append("https://dokkan-eclipse.com");
            v9_4.append(v7_10.path);
            if (v8_3.cachedBody(v9_4.toString()) != null) {
                if (!this.matches(v7_10)) {
                    v6++;
                } else {
                    v4_2++;
                    v1_0 += ((long) v7_10.bytes);
                }
            } else {
                v5++;
            }
        }
        org.json.JSONObject v0_2 = new org.json.JSONArray(p12.failures.toString());
        org.json.JSONObject vtmp9 = new org.json.JSONObject().put("version", this.version);
        if (v4_2 == this.entries.size()) {
            v3_0 = 1;
        }
        return vtmp9.put("ready", v3_0).put("preparing", p12.preparing).put("preparedFiles", v4_2).put("totalFiles", this.entries.size()).put("preparedBytes", v1_0).put("totalBytes", this.total).put("missingFiles", v5).put("invalidFiles", v6).put("offline", this.cache.offline()).put("failures", v0_2).put("currentLabel", p12.label);
    }

    public void m35lambda$0$compersonalaihubPreviewTools(com.personal.aihub.PreviewTools$Job p8, long p9)
    {
        try {
            java.util.Iterator v1_1 = this.entries.iterator();
        } catch (Throwable v9_1) {
            p8.label = "";
            p8.preparing = 0;
            throw v9_1;
        }
        while (v1_1.hasNext()) {
            org.json.JSONObject v2_6 = ((com.personal.aihub.PreviewTools$Entry) v1_1.next());
            if (this.cache.revision() == p9) {
                p8.label = v2_6.label;
                try {
                    if (!this.matches(v2_6)) {
                        if (this.cache.offline()) {
                            throw new java.io.IOException("Offline preview is enabled. Connect again to finish preparing the player.");
                        } else {
                            String v3_9 = this.cache;
                            org.json.JSONArray v4_2 = new StringBuilder();
                            v4_2.append("https://dokkan-eclipse.com");
                            v4_2.append(v2_6.path);
                            v3_9.discard(v4_2.toString());
                            String v3_10 = this.cache;
                            org.json.JSONArray v4_5 = new StringBuilder();
                            v4_5.append("https://dokkan-eclipse.com");
                            v4_5.append(v2_6.path);
                            v3_10.prepareBody(v4_5.toString(), v2_6.bytes, p9);
                            if (!this.matches(v2_6)) {
                                String v3_12 = this.cache;
                                org.json.JSONArray v4_8 = new StringBuilder();
                                v4_8.append("https://dokkan-eclipse.com");
                                v4_8.append(v2_6.path);
                                v3_12.discard(v4_8.toString());
                                throw new java.io.IOException("The hosted tool changed. Update the app before saving this version.");
                            } else {
                            }
                        }
                    }
                } catch (String v3_15) {
                    if (p8.failures.length() < 20) {
                        org.json.JSONArray v4_13 = p8.failures;
                        org.json.JSONObject v2_2 = new org.json.JSONObject().put("path", v2_6.path);
                        if (v3_15.getMessage() != null) {
                            String v3_16 = v3_15.getMessage();
                        } else {
                            v3_16 = "Could not save preview tool";
                        }
                        v4_13.put(v2_2.put("message", v3_16));
                    }
                    if (!this.cache.offline()) {
                        if (this.cache.revision() == p9) {
                        } else {
                        }
                    }
                    break;
                }
            } else {
                break;
            }
        }
        p8.label = "";
        p8.preparing = 0;
        return;
    }

    org.json.JSONObject request(org.json.JSONObject p6)
    {
        String v0_0 = p6.keys();
        while (v0_0.hasNext()) {
            String v1_8 = ((String) v0_0.next());
            if ((!v1_8.equals("prepare")) || (!(p6.get(v1_8) instanceof Boolean))) {
                throw new java.io.IOException("Invalid preview tools request");
            }
        }
        String v0_2 = this.job();
        if (p6.optBoolean("prepare")) {
            try {
                if (!v0_2.preparing) {
                    if (this.cache.offline()) {
                        throw new java.io.IOException("Connect once and switch off Offline preview to prepare the player tools.");
                    } else {
                        v0_2.preparing = 1;
                        v0_2.failures = new org.json.JSONArray();
                        Thread v3_1 = new Thread(new com.personal.aihub.PreviewTools$1(this, v0_2, this.cache.revision()), "forge-preview-tools");
                        v3_1.setDaemon(1);
                        v3_1.start();
                    }
                }
            } catch (java.io.IOException v6_7) {
                throw v6_7;
            }
        }
        return this.status(v0_2);
    }
}
