package com.personal.aihub;
public final class ProjectVersions {
    public static final int BUDGET = 41943040;
    public static final int HEADER = 65536;
    public static final int MAX = 20971520;
    private final java.io.File current;
    private final java.io.File dir;
    private final java.io.File index;
    private final String key;

    public ProjectVersions(java.io.File p6, java.io.File p7, String p8)
    {
        if ((p8 == null) || (!p8.matches("[a-zA-Z0-9_-]{1,100}"))) {
            throw new java.io.IOException("Invalid project key.");
        } else {
            java.io.File v0_0 = p6.getCanonicalFile();
            java.io.File v2_1 = new java.io.File(p6, "projects");
            java.io.IOException v6_2 = new StringBuilder();
            v6_2.append(p8);
            v6_2.append(".json");
            if (!p7.getAbsoluteFile().equals(new java.io.File(v2_1, v6_2.toString()).getAbsoluteFile())) {
                throw new java.io.IOException("Current project is outside its storage directory.");
            } else {
                String v7_4 = new java.io.File(v0_0, "projects");
                String v1_3 = new StringBuilder();
                v1_3.append(p8);
                v1_3.append(".json");
                this.current = new java.io.File(v7_4, v1_3.toString());
                this.key = p8;
                java.io.IOException v6_11 = new java.io.File(new java.io.File(v0_0, "project-versions"), p8);
                this.dir = v6_11;
                if (!v6_11.getCanonicalPath().equals(v6_11.getAbsolutePath())) {
                    throw new java.io.IOException("Unsafe backup directory.");
                } else {
                    if ((!v6_11.mkdirs()) && (!v6_11.isDirectory())) {
                        throw new java.io.IOException("Cannot create saved versions.");
                    } else {
                        this.index = new java.io.File(v6_11, "index.json");
                        return;
                    }
                }
            }
        }
    }

    public static void atomic(java.io.File p4, byte[] p5)
    {
        java.io.FileOutputStream v1_2 = p4.getParentFile();
        String v2_2 = new StringBuilder();
        v2_2.append(p4.getName());
        v2_2.append(".");
        v2_2.append(java.util.UUID.randomUUID());
        v2_2.append(".tmp");
        java.io.File v0_1 = new java.io.File(v1_2, v2_2.toString());
        try {
            java.io.FileOutputStream v1_1 = new java.io.FileOutputStream(v0_1);
            try {
                v1_1.write(p5);
                v1_1.getFD().sync();
            } catch (java.io.IOException v4_1) {
                try {
                    v1_1.close();
                } catch (Throwable v5_2) {
                    v4_1.addSuppressed(v5_2);
                }
                throw v4_1;
            }
            v1_1.close();
            if (!v0_1.renameTo(p4)) {
                throw new java.io.IOException("Could not commit saved project version.");
            } else {
                v0_1.delete();
                return;
            }
        } catch (java.io.IOException v4_5) {
            v0_1.delete();
            throw v4_5;
        }
    }

    static byte[] bytes(java.io.File p4, int p5)
    {
        if ((!p4.isFile()) || ((!p4.getCanonicalPath().equals(p4.getAbsolutePath())) || (p4.length() > ((long) p5)))) {
            throw new java.io.IOException("Project backup is invalid or too large.");
        } else {
            java.io.FileInputStream v0_4 = new java.io.FileInputStream(p4);
            try {
                Throwable v4_4 = new java.io.ByteArrayOutputStream();
                try {
                    String v1_1 = new byte[65536];
                } catch (java.io.IOException v5_5) {
                    try {
                        v4_4.close();
                    } catch (Throwable v4_5) {
                        v5_5.addSuppressed(v4_5);
                    }
                    throw v5_5;
                }
                while(true) {
                    int v2_1 = v0_4.read(v1_1);
                    if (v2_1 == -1) {
                        break;
                    }
                    if ((v4_4.size() + v2_1) > p5) {
                        throw new java.io.IOException("Project backup exceeds its size limit.");
                    } else {
                        v4_4.write(v1_1, 0, v2_1);
                    }
                }
                java.io.IOException v5_2 = v4_4.toByteArray();
                v4_4.close();
                v0_4.close();
                return v5_2;
            } catch (Throwable v4_6) {
                try {
                    v0_4.close();
                } catch (java.io.IOException v5_6) {
                    v4_6.addSuppressed(v5_6);
                }
                throw v4_6;
            }
        }
    }

    public static String revision(byte[] p6)
    {
        String v6_2 = java.security.MessageDigest.getInstance("SHA-256").digest(p6);
        StringBuilder v0_3 = new StringBuilder();
        int v1 = v6_2.length;
        int v2 = 0;
        while (v2 < v1) {
            v0_3.append(String.format(java.util.Locale.ROOT, "%02x", new Object[] {Integer.valueOf((v6_2[v2] & 255))})));
            v2++;
        }
        return v0_3.toString();
    }

    static String text(byte[] p2)
    {
        return new String(p2, java.nio.charset.StandardCharsets.UTF_8);
    }

    static boolean validVersion(String p1)
    {
        if ((p1 == 0) || (!p1.matches("[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}"))) {
            int v1_2 = 0;
        } else {
            v1_2 = 1;
        }
        return v1_2;
    }

    org.json.JSONObject candidate(byte[] p6, String p7)
    {
        if (p7 == null) {
            throw new java.io.IOException("Give this version a readable name.");
        } else {
            org.json.JSONObject v7_6 = p7.trim();
            if ((v7_6.isEmpty()) || ((v7_6.codePointCount(0, v7_6.length()) > 80) || (v7_6.matches("(?s).*[\\x00-\\x1f\\x7f].*")))) {
                throw new java.io.IOException("Use a readable version name of 1\u201380 characters.");
            } else {
                org.json.JSONObject v7_5 = new org.json.JSONObject().put("versionKey", java.util.UUID.randomUUID().toString()).put("label", v7_6).put("createdAt", new com.personal.aihub.ProjectVersions$1(this, "yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'", java.util.Locale.US).format(new java.util.Date())).put("bytes", new org.json.JSONObject().put("versionKey", java.util.UUID.randomUUID().toString()).put("label", v7_6).length);
                byte[] v0_15 = new org.json.JSONObject(v7_5.toString()).put("key", this.key).put("revision", com.personal.aihub.ProjectVersions.revision(p6));
                java.io.ByteArrayOutputStream v1_14 = new StringBuilder();
                v1_14.append(v0_15.toString());
                v1_14.append("\n");
                byte[] v0_19 = v1_14.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8);
                java.io.ByteArrayOutputStream v1_17 = new java.io.ByteArrayOutputStream((v0_19.length + p6.length));
                v1_17.write(v0_19);
                v1_17.write(p6);
                v7_5.put("fileBytes", v1_17.size());
                byte[] v0_22 = this.dir;
                StringBuilder v3_6 = new StringBuilder();
                v3_6.append(v7_5.getString("versionKey"));
                v3_6.append(".version");
                com.personal.aihub.ProjectVersions.atomic(new java.io.File(v0_22, v3_6.toString()), v1_17.toByteArray());
                return v7_5;
            }
        }
    }

    void check(org.json.JSONObject p2, byte[] p3, boolean p4)
    {
        if ((p4) || (p2.has("expectedCurrentRevision"))) {
            java.io.IOException v2_4 = p2.optString("expectedCurrentRevision");
            if ((!v2_4.matches("[a-f0-9]{64}")) || (!v2_4.equals(com.personal.aihub.ProjectVersions.revision(p3)))) {
                throw new java.io.IOException("This project changed after the version list was opened. Close it and reopen Saved versions.");
            }
        }
        return;
    }

    void clean(org.json.JSONArray p7)
    {
        java.util.HashSet v0_1 = new java.util.HashSet();
        int v1 = 0;
        int v2_1 = 0;
        while (v2_1 < p7.length()) {
            java.io.File v3_2 = new StringBuilder();
            v3_2.append(p7.getJSONObject(v2_1).getString("versionKey"));
            v3_2.append(".version");
            v0_1.add(v3_2.toString());
            v2_1++;
        }
        java.io.File[] v7_2 = this.dir.listFiles();
        if (v7_2 != null) {
            int v2_0 = v7_2.length;
            while (v1 < v2_0) {
                java.io.File v3_0 = v7_2[v1];
                if ((v3_0.getName().matches("[0-9a-f-]{36}\\.version")) && (!v0_1.contains(v3_0.getName()))) {
                    v3_0.delete();
                }
                v1++;
            }
        }
        return;
    }

    void commit(org.json.JSONArray p3)
    {
        com.personal.aihub.ProjectVersions.atomic(this.index, p3.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8));
        return;
    }

    byte[] current()
    {
        byte[] v0_1 = com.personal.aihub.ProjectVersions.bytes(this.current, 20971520);
        this.project(v0_1);
        return v0_1;
    }

    public org.json.JSONObject list()
    {
        org.json.JSONObject v0_0 = this.rows();
        String v1_3 = new org.json.JSONArray();
        String v2_2 = 0;
        while (v2_2 < v0_0.length()) {
            org.json.JSONObject v3_1 = new org.json.JSONObject(v0_0.getJSONObject(v2_2).toString());
            v3_1.remove("fileBytes");
            v1_3.put(v3_1);
            v2_2++;
        }
        return new org.json.JSONObject().put("versions", v1_3).put("currentRevision", com.personal.aihub.ProjectVersions.revision(this.current()));
    }

    public org.json.JSONObject load(org.json.JSONObject p2)
    {
        return this.project(this.read(p2.getString("versionKey")));
    }

    org.json.JSONObject project(byte[] p3)
    {
        if (p3.length > 20971520) {
            throw new java.io.IOException("Project exceeds 20 MiB.");
        } else {
            String v0_1 = new org.json.JSONObject(com.personal.aihub.ProjectVersions.text(p3));
            if ((!"dokkan-unit-forge".equals(v0_1.optString("format"))) || (!this.key.equals(v0_1.optString("key")))) {
                throw new java.io.IOException("Backup does not belong to this project.");
            } else {
                return v0_1;
            }
        }
    }

    byte[] read(String p8)
    {
        if (!com.personal.aihub.ProjectVersions.validVersion(p8)) {
            throw new java.io.IOException("Invalid backup key.");
        } else {
            String v0_8 = this.rows();
            int v2_0 = 0;
            org.json.JSONObject v3_0 = 0;
            while (v2_0 < v0_8.length()) {
                if (p8.equals(v0_8.getJSONObject(v2_0).getString("versionKey"))) {
                    v3_0 = 1;
                }
                v2_0++;
            }
            if (v3_0 == null) {
                throw new java.io.IOException("This saved version is no longer available.");
            } else {
                int v2_1 = this.dir;
                org.json.JSONObject v3_2 = new StringBuilder();
                v3_2.append(p8);
                v3_2.append(".version");
                String v0_4 = com.personal.aihub.ProjectVersions.bytes(new java.io.File(v2_1, v3_2.toString()), 21037056);
                int v2_3 = 0;
                while ((v2_3 < v0_4.length) && (v0_4[v2_3] != 10)) {
                    v2_3++;
                }
                if ((v2_3 < 1) || ((v2_3 >= 65536) || (v2_3 == v0_4.length))) {
                    throw new java.io.IOException("Invalid backup envelope.");
                } else {
                    org.json.JSONObject v3_9 = new org.json.JSONObject(com.personal.aihub.ProjectVersions.text(java.util.Arrays.copyOfRange(v0_4, 0, v2_3)));
                    String v0_7 = java.util.Arrays.copyOfRange(v0_4, (v2_3 + 1), v0_4.length);
                    if ((!p8.equals(v3_9.optString("versionKey"))) || ((!this.key.equals(v3_9.optString("key"))) || (!com.personal.aihub.ProjectVersions.revision(v0_7).equals(v3_9.optString("revision"))))) {
                        throw new java.io.IOException("Backup checksum does not match.");
                    } else {
                        this.project(v0_7);
                        return v0_7;
                    }
                }
            }
        }
    }

    public org.json.JSONObject restore(org.json.JSONObject p15)
    {
        String v1_0 = this.current();
        this.check(p15, v1_0, 1);
        Exception v15_9 = this.read(p15.getString("versionKey"));
        org.json.JSONArray v4 = this.rows();
        org.json.JSONObject v5_1 = this.candidate(v1_0, "Before restoring an earlier version");
        org.json.JSONArray v6 = this.with(v5_1, v4);
        try {
            this.commit(v6);
            Exception v15_1 = this.project(v15_9);
            java.text.SimpleDateFormat v7_1 = new java.text.SimpleDateFormat("yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'", java.util.Locale.US);
            v7_1.setTimeZone(java.util.TimeZone.getTimeZone("UTC"));
            v7_1.setLenient(0);
            long v8_4 = System.currentTimeMillis();
            String v1_2 = this.project(v1_0).optString("updatedAt");
        } catch (Exception v15_8) {
            String v1_9 = this.dir;
            String v2_2 = new StringBuilder();
            v2_2.append(v5_1.getString("versionKey"));
            v2_2.append(".version");
            new java.io.File(v1_9, v2_2.toString()).delete();
            throw v15_8;
        }
        if (v1_2.matches("\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z")) {
            v8_4 = Math.max(v8_4, (v7_1.parse(v1_2).getTime() + 1));
        }
        v15_1.put("updatedAt", v7_1.format(new java.util.Date(v8_4)));
        Exception v15_3 = v15_1.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8);
        try {
            com.personal.aihub.ProjectVersions.atomic(this.current, v15_3);
            this.clean(v6);
            return this.list().put("saved", 1).put("project", this.project(v15_3));
        } catch (Exception v15_7) {
            this.commit(v4);
            throw v15_7;
        }
    }

    org.json.JSONArray rows()
    {
        if (this.index.exists()) {
            java.io.IOException v0_1 = new org.json.JSONArray(com.personal.aihub.ProjectVersions.text(com.personal.aihub.ProjectVersions.bytes(this.index, 65536)));
            String v1_2 = new java.util.HashSet();
            if (v0_1.length() > 10) {
                throw new java.io.IOException("Invalid saved version index.");
            } else {
                long v2_1 = 0;
                int v5 = 0;
                while (v5 < v0_1.length()) {
                    org.json.JSONObject v6_1 = v0_1.getJSONObject(v5);
                    String v7_1 = v6_1.getLong("bytes");
                    long v9_1 = v6_1.getLong("fileBytes");
                    long v11_1 = v6_1.getString("versionKey");
                    if ((!com.personal.aihub.ProjectVersions.validVersion(v11_1)) || ((!v1_2.add(v11_1)) || ((v7_1 < 1) || ((v7_1 > 20971520) || ((v9_1 < v7_1) || ((v9_1 > (v7_1 + 65536)) || (v6_1.getString("label").length() > 160))))))) {
                        throw new java.io.IOException("Invalid saved version index.");
                    } else {
                        v6_1.getString("createdAt");
                        v2_1 += v9_1;
                        v5++;
                    }
                }
                if (v2_1 > 41943040) {
                    throw new java.io.IOException("Saved versions exceed their size limit.");
                } else {
                    return v0_1;
                }
            }
        } else {
            return new org.json.JSONArray();
        }
    }

    public org.json.JSONObject save(org.json.JSONObject p6)
    {
        Exception v0_0 = this.current();
        this.check(p6, v0_0, 0);
        java.io.File v1_5 = this.rows();
        String v6_1 = this.candidate(v0_0, p6.optString("label", 0));
        Exception v0_1 = this.with(v6_1, v1_5);
        try {
            this.commit(v0_1);
            this.clean(v0_1);
            Exception v0_3 = this.list().put("saved", 1);
            java.io.File v1_2 = v6_1.keys();
        } catch (Exception v0_4) {
            String v2_1 = this.dir;
            Object v3_1 = new StringBuilder();
            v3_1.append(v6_1.getString("versionKey"));
            v3_1.append(".version");
            new java.io.File(v2_1, v3_1.toString()).delete();
            throw v0_4;
        }
        while (v1_2.hasNext()) {
            String v2_4 = ((String) v1_2.next());
            if (!v2_4.equals("fileBytes")) {
                v0_3.put(v2_4, v6_1.get(v2_4));
            }
        }
        return v0_3;
    }

    org.json.JSONArray with(org.json.JSONObject p10, org.json.JSONArray p11)
    {
        org.json.JSONArray v0_2 = new org.json.JSONArray().put(p10);
        long v2 = p10.getLong("fileBytes");
        int v10_1 = 0;
        while ((v10_1 < p11.length()) && (v0_2.length() < 10)) {
            org.json.JSONObject v4_1 = p11.getJSONObject(v10_1);
            if ((v4_1.getLong("fileBytes") + v2) > 41943040) {
                break;
            }
            v2 += v4_1.getLong("fileBytes");
            v0_2.put(v4_1);
            v10_1++;
        }
        return v0_2;
    }
}
