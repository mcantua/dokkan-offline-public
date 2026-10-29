package com.personal.aihub;
public final class SparkingContent {
    private static final String DATABASE_PATH = "/dokkan/assets/global/en/sqlite/current/en/database.db";
    private static final String MANIFEST = "https://dokkan-sparking.com/client_assets";
    public static final long MAX_DATABASE = 201326592;
    public static final long MAX_MANIFEST = 33554432;

    private SparkingContent()
    {
        return;
    }

    private static java.net.URI allowed(String p4, boolean p5)
    {
        String v4_6;
        java.net.URI v0_1 = new java.net.URI(p4);
        if (p5 == null) {
            v4_6 = "ddl.dokkan-sparking.com";
        } else {
            v4_6 = "dokkan-sparking.com";
        }
        int v1_2;
        if (p5 == null) {
            v1_2 = "/dokkan/assets/global/en/sqlite/current/en/database.db";
        } else {
            v1_2 = "/client_assets";
        }
        if (((!"https".equals(v0_1.getScheme())) || ((!v4_6.equals(v0_1.getHost())) || ((!v1_2.equals(v0_1.getRawPath())) || ((v0_1.getRawUserInfo() != null) || ((v0_1.getRawFragment() != null) || ((v0_1.getPort() != -1) && (v0_1.getPort() != 443))))))) || ((p5 != null) && (v0_1.getRawQuery() != null))) {
            throw new java.io.IOException("The Sparking server returned an unsupported download address.");
        } else {
            return v0_1;
        }
    }

    static org.json.JSONObject assetRecord(org.json.JSONObject p7, String p8)
    {
        com.personal.aihub.SparkingContent.gamePath(p8);
        int v7_11 = p7.getJSONArray("assets");
        if (v7_11.length() > 100000) {
            throw new java.io.IOException("The Sparking manifest contains too many entries.");
        } else {
            String v1_0 = 0;
            org.json.JSONObject v2 = 0;
            while (v1_0 < v7_11.length()) {
                StringBuilder v3_0 = v7_11.getJSONObject(v1_0);
                if (p8.equals(v3_0.optString("file_path"))) {
                    if (v2 != null) {
                        throw new java.io.IOException("The Sparking manifest repeats this game resource.");
                    } else {
                        v2 = v3_0;
                    }
                }
                v1_0++;
            }
            if (v2 == null) {
                throw new java.io.IOException("This resource is not listed in the downloaded Sparking manifest.");
            } else {
                int v7_10 = v2.get("size");
                if (((v7_10 instanceof Integer)) || ((v7_10 instanceof Long))) {
                    int v7_12 = ((Number) v7_10);
                    if ((v7_12.longValue() > 0) && ((v7_12.longValue() <= 201326592) && ("xxhash".equals(v2.optString("algorithm"))))) {
                        int v7_20 = v2.getString("hash");
                        if (!v7_20.matches("[0-9]{1,20}")) {
                            throw new java.io.IOException("Invalid Sparking resource checksum.");
                        } else {
                            try {
                                Long.parseUnsignedLong(v7_20);
                                int v7_24 = new java.net.URI(v2.getString("url"));
                                StringBuilder v3_6 = new StringBuilder("/dokkan/assets/global/en/");
                                v3_6.append(p8);
                                int v8_10 = new java.net.URI(0, 0, v3_6.toString(), 0).toASCIIString();
                            } catch (NumberFormatException) {
                                throw new java.io.IOException(v3_6);
                            }
                            if ((!"https".equals(v7_24.getScheme())) || ((!"ddl.dokkan-sparking.com".equals(v7_24.getHost())) || ((!v8_10.equals(v7_24.getRawPath())) || ((v7_24.getRawUserInfo() != null) || ((v7_24.getRawFragment() != null) || ((v7_24.getPort() != -1) && (v7_24.getPort() != 443))))))) {
                                throw new java.io.IOException("The Sparking resource download address does not match its manifest path.");
                            } else {
                                return v2;
                            }
                        }
                    }
                }
                throw new java.io.IOException("Unsupported Sparking game resource size or checksum.");
            }
        }
    }

    static org.json.JSONArray audioRecords(org.json.JSONObject p9)
    {
        String v0_2 = p9.getJSONArray("assets");
        org.json.JSONArray v1_1 = new org.json.JSONArray();
        if (v0_2.length() > 100000) {
            throw new java.io.IOException("The Sparking manifest contains too many entries.");
        } else {
            int v2_0 = 0;
            while (v2_0 < v0_2.length()) {
                org.json.JSONObject v3_2 = v0_2.getJSONObject(v2_0).optString("file_path");
                if ((v3_2.startsWith("se/")) || (v3_2.startsWith("voice/"))) {
                    if (v1_1.length() >= 128) {
                        throw new java.io.IOException("The Sparking manifest contains too many audio banks.");
                    } else {
                        org.json.JSONObject v3_4;
                        org.json.JSONObject vtmp12 = new org.json.JSONObject().put("path", v3_2).put("bytes", com.personal.aihub.SparkingContent.assetRecord(p9, v3_2).getLong("size"));
                        if (!v3_2.startsWith("se/")) {
                            v3_4 = "voice";
                        } else {
                            v3_4 = "se";
                        }
                        v1_1.put(vtmp12.put("kind", v3_4));
                    }
                }
                v2_0++;
            }
            return v1_1;
        }
    }

    private static javax.net.ssl.HttpsURLConnection connect(String p0, boolean p1)
    {
        return com.personal.aihub.SparkingContent.open(com.personal.aihub.SparkingContent.allowed(p0, p1), p1);
    }

    static org.json.JSONObject databaseRecord(org.json.JSONObject p6)
    {
        java.io.IOException v6_2 = p6.getJSONArray("assets");
        if (v6_2.length() > 100000) {
            throw new java.io.IOException("The Sparking manifest contains too many entries.");
        } else {
            org.json.JSONObject v1_0 = 0;
            boolean v2_0 = 0;
            while (v2_0 < v6_2.length()) {
                String v3_2 = v6_2.getJSONObject(v2_0);
                if ("sqlite/current/en/database.db".equals(v3_2.optString("file_path"))) {
                    if (v1_0 != null) {
                        throw new java.io.IOException("The Sparking manifest has duplicate game databases.");
                    } else {
                        v1_0 = v3_2;
                    }
                }
                v2_0++;
            }
            if (v1_0 == null) {
                throw new java.io.IOException("The Sparking manifest does not list its game database.");
            } else {
                java.io.IOException v6_5 = v1_0.get("size");
                if ((!(v6_5 instanceof Number)) || (((v6_5 instanceof Double)) || ((v6_5 instanceof Float)))) {
                    throw new java.io.IOException("Invalid Sparking database size.");
                } else {
                    boolean v2_4 = ((Number) v6_5).longValue();
                    if ((v2_4 <= 0) || ((v2_4 > 201326592) || (!"xxhash".equals(v1_0.optString("algorithm"))))) {
                        throw new java.io.IOException("Unsupported Sparking database size or checksum format.");
                    } else {
                        java.io.IOException v6_17 = v1_0.getString("hash");
                        if (!v6_17.matches("[0-9]{1,20}")) {
                            throw new java.io.IOException("Invalid Sparking database checksum.");
                        } else {
                            try {
                                Long.parseUnsignedLong(v6_17);
                                com.personal.aihub.SparkingContent.allowed(v1_0.getString("url"), 0);
                                return v1_0;
                            } catch (NumberFormatException) {
                                throw new java.io.IOException("Invalid Sparking database checksum.");
                            }
                        }
                    }
                }
            }
        }
    }

    private static java.io.File destination(java.io.File p2)
    {
        java.io.IOException v2_1 = p2.getAbsoluteFile();
        String v0_3 = v2_1.getParentFile().getCanonicalFile();
        if (!v0_3.isDirectory()) {
            throw new java.io.IOException("Create a private Sparking download staging directory first.");
        } else {
            java.io.File v1_1 = new java.io.File(v0_3, v2_1.getName());
            if ((v1_1.exists()) && ((!v1_1.isFile()) || (!v1_1.getCanonicalFile().equals(v1_1)))) {
                throw new java.io.IOException("Unsafe Sparking download destination.");
            } else {
                return v1_1;
            }
        }
    }

    public static org.json.JSONObject download(java.io.File p27, java.io.File p28, com.personal.aihub.SparkingContent$Progress p29)
    {
        String v1_0 = com.personal.aihub.SparkingContent.destination(p27);
        String v2_0 = com.personal.aihub.SparkingContent.destination(p28);
        if (v1_0.equals(v2_0)) {
            throw new java.io.IOException("Use separate private files for the Sparking database and manifest.");
        } else {
            Throwable v0_5 = java.util.UUID.randomUUID().toString();
            java.io.IOException v4_1 = v1_0.getParentFile();
            java.io.File v5_1 = new StringBuilder("sparking-");
            v5_1.append(v0_5);
            v5_1.append(".database.tmp");
            int v3_0 = new java.io.File(v4_1, v5_1.toString());
            java.io.File v5_3 = v2_0.getParentFile();
            Throwable v7_2 = new StringBuilder("sparking-");
            v7_2.append(v0_5);
            v7_2.append(".manifest.tmp");
            java.io.IOException v4_3 = new java.io.File(v5_3, v7_2.toString());
            Throwable v7_4 = v1_0.getParentFile();
            String v8_12 = new StringBuilder("sparking-");
            v8_12.append(v0_5);
            v8_12.append(".database.old");
            java.io.File v5_5 = new java.io.File(v7_4, v8_12.toString());
            String v8_17 = v2_0.getParentFile();
            int v9_11 = new StringBuilder("sparking-");
            v9_11.append(v0_5);
            v9_11.append(".manifest.old");
            Throwable v7_9 = new java.io.File(v8_17, v9_11.toString());
            try {
                int v9_9 = com.personal.aihub.SparkingContent.connect("https://dokkan-sparking.com/client_assets", 1);
                try {
                    java.io.BufferedInputStream v12_0;
                    String v11_1;
                    int v28_1;
                    long v13_0;
                    long v16_1 = v9_9.getContentLengthLong();
                    String v14_7 = "The Sparking manifest exceeds32MiB.";
                    try {
                        if (v16_1 > 33554432) {
                            v13_0 = v3_0;
                            v12_0 = v4_3;
                            v11_1 = v7_9;
                            v28_1 = v9_9;
                            v3_0 = 0;
                            throw new java.io.IOException("The Sparking manifest exceeds32MiB.");
                        } else {
                            Throwable v0_65 = new java.io.ByteArrayOutputStream();
                            java.io.FileOutputStream v15_2 = new java.io.BufferedInputStream(v9_9.getInputStream());
                            try {
                                java.io.BufferedInputStream v12_11 = new byte[65536];
                            } catch (Throwable v0_46) {
                                v13_0 = v3_0;
                                v12_0 = v4_3;
                                v11_1 = v7_9;
                                v28_1 = v9_9;
                                int v6_0 = v15_2;
                                v3_0 = 0;
                                java.io.IOException v4_16 = v0_46;
                                try {
                                    v6_0.close();
                                } catch (Throwable v0_50) {
                                    v4_16.addSuppressed(v0_50);
                                }
                                throw v4_16;
                            }
                            while(true) {
                                int v10_0 = v15_2.read(v12_11);
                                if (v10_0 == -1) {
                                    String v20_0 = v7_9;
                                    v28_1 = v9_9;
                                    try {
                                        v15_2.close();
                                        Throwable v0_0 = v0_65.toByteArray();
                                        int v6_2 = 0;
                                    } catch (Throwable v0_4) {
                                        v13_0 = v3_0;
                                        v12_0 = v4_3;
                                        v11_1 = v20_0;
                                        v3_0 = 0;
                                        v28_1.disconnect();
                                        throw v0_4;
                                    }
                                    if (v16_1 >= 0) {
                                        if (((long) v0_0.length) != v16_1) {
                                            throw new java.io.IOException("The Sparking manifest download is incomplete.");
                                        } else {
                                        }
                                    }
                                    try {
                                        v28_1.disconnect();
                                        String v8_5 = new org.json.JSONObject(new String(v0_0, java.nio.charset.StandardCharsets.UTF_8));
                                        int v9_2 = com.personal.aihub.SparkingContent.databaseRecord(v8_5);
                                        long v18_0 = v9_2.getLong("size");
                                        String v8_6 = v8_5.get("latest_version");
                                    } catch (Throwable v0_13) {
                                        v13_0 = v3_0;
                                        v12_0 = v4_3;
                                        v11_1 = v20_0;
                                        v3_0 = 0;
                                        java.io.IOException v4_8 = v0_13;
                                        Throwable v0_24 = v3_0;
                                        int v6_8 = v0_24;
                                        int v9_6 = v6_8;
                                        int v10_17 = v9_6;
                                        v13_0.delete();
                                        v12_0.delete();
                                        if (v6_8 != 0) {
                                            v5_5.delete();
                                            v11_1.delete();
                                        } else {
                                            if (v3_0 != 0) {
                                                v1_0.delete();
                                            }
                                            if (v0_24 != null) {
                                                v2_0.delete();
                                            }
                                            if (v9_6 != 0) {
                                                if (!v5_5.renameTo(v1_0)) {
                                                    String v1_2 = new StringBuilder("Sparking download rollback needs recovery: the previous database is retained in ");
                                                    v1_2.append(v5_5.getName());
                                                    throw new java.io.IOException(v1_2.toString());
                                                }
                                            }
                                            if (v10_17 != 0) {
                                                if (!v11_1.renameTo(v2_0)) {
                                                    String v1_5 = new StringBuilder("Sparking download rollback needs recovery: the previous manifest is retained in ");
                                                    v1_5.append(v11_1.getName());
                                                    throw new java.io.IOException(v1_5.toString());
                                                }
                                            }
                                        }
                                        throw v4_8;
                                    }
                                    if ((!(v8_6 instanceof Number)) || (((v8_6 instanceof Double)) || (((v8_6 instanceof Float)) || (((Number) v8_6).longValue() < 0)))) {
                                        v13_0 = v3_0;
                                        v12_0 = v4_3;
                                        v11_1 = v20_0;
                                        v3_0 = 0;
                                        throw new java.io.IOException("Invalid Sparking content version.");
                                    } else {
                                        int v10_11 = new java.io.FileOutputStream(v4_3);
                                        try {
                                            v10_11.write(v0_0);
                                            v10_11.getFD().sync();
                                        } catch (Throwable v0_9) {
                                            v13_0 = v3_0;
                                            v12_0 = v4_3;
                                            v11_1 = v20_0;
                                            v3_0 = 0;
                                            java.io.IOException v4_2 = v0_9;
                                            try {
                                                v10_11.close();
                                            } catch (Throwable v0_10) {
                                                v4_2.addSuppressed(v0_10);
                                            }
                                            throw v4_2;
                                        }
                                        v10_11.close();
                                        Throwable v0_12 = java.security.MessageDigest.getInstance("SHA-256");
                                        int v10_13 = new com.personal.aihub.SparkingContent$XXH64();
                                        try {
                                            javax.net.ssl.HttpsURLConnection v22 = com.personal.aihub.SparkingContent.connect(v9_2.getString("url"), 0);
                                            try {
                                                java.io.BufferedInputStream v12_4 = v22.getContentLengthLong();
                                            } catch (Throwable v0_16) {
                                                v13_0 = v3_0;
                                                v12_0 = v4_3;
                                                v11_1 = v20_0;
                                                v3_0 = 0;
                                                v22.disconnect();
                                                throw v0_16;
                                            }
                                            if (v12_4 >= 0) {
                                                if (v12_4 != v18_0) {
                                                    throw new java.io.IOException("The Sparking database size differs from its manifest.");
                                                } else {
                                                }
                                            }
                                            String v14_2 = new java.io.BufferedInputStream(v22.getInputStream());
                                            try {
                                                java.io.FileOutputStream v15_1 = new java.io.FileOutputStream(v3_0);
                                                try {
                                                    long v13_2 = new byte[131072];
                                                } catch (Throwable v0_18) {
                                                    v13_0 = v3_0;
                                                    v12_0 = v4_3;
                                                    v4_3 = v14_2;
                                                    java.io.FileOutputStream v25 = v15_1;
                                                    v11_1 = v20_0;
                                                    v3_0 = 0;
                                                    int v6_7 = v0_18;
                                                    try {
                                                        v25.close();
                                                    } catch (Throwable v0_44) {
                                                        v6_7.addSuppressed(v0_44);
                                                    } catch (Throwable v0_17) {
                                                        int v6_11 = v0_17;
                                                        try {
                                                            v4_3.close();
                                                        } catch (Throwable v0_45) {
                                                            v6_11.addSuppressed(v0_45);
                                                        } catch (Throwable v0_16) {
                                                        }
                                                        throw v6_11;
                                                    }
                                                    throw v6_7;
                                                }
                                                while(true) {
                                                    java.io.BufferedInputStream v12_8 = v14_2.read(v13_2);
                                                    if (v12_8 == -1) {
                                                        long v23_0 = v3_0;
                                                        java.io.BufferedInputStream v24_0 = v4_3;
                                                        v4_3 = v14_2;
                                                        v25 = v15_1;
                                                        v3_0 = 0;
                                                        try {
                                                            v25.getFD().sync();
                                                            try {
                                                                v25.close();
                                                                try {
                                                                    v4_3.close();
                                                                    try {
                                                                        v22.disconnect();
                                                                        java.io.IOException v4_4 = Long.toUnsignedString(v10_13.value());
                                                                    } catch (Throwable v0_13) {
                                                                        v11_1 = v20_0;
                                                                        v13_0 = v23_0;
                                                                        v12_0 = v24_0;
                                                                    }
                                                                    if ((v6_2 != v18_0) || (!v4_4.equals(v9_2.getString("hash")))) {
                                                                        v11_1 = v20_0;
                                                                        v13_0 = v23_0;
                                                                        v12_0 = v24_0;
                                                                        throw new java.io.IOException("The Sparking database checksum does not match. Existing content was kept.");
                                                                    } else {
                                                                        if (!v1_0.exists()) {
                                                                            v9_6 = 0;
                                                                            try {
                                                                                if (!v2_0.exists()) {
                                                                                    v11_1 = v20_0;
                                                                                    v10_17 = 0;
                                                                                    v12_0 = v24_0;
                                                                                } else {
                                                                                    v11_1 = v20_0;
                                                                                    try {
                                                                                        if (!v2_0.renameTo(v11_1)) {
                                                                                            throw new java.io.IOException("Could not preserve the previous Sparking manifest.");
                                                                                        } else {
                                                                                            v12_0 = v24_0;
                                                                                            v10_17 = 1;
                                                                                        }
                                                                                    } catch (Throwable v0_28) {
                                                                                        v4_8 = v0_28;
                                                                                        v0_24 = 0;
                                                                                        v6_8 = 0;
                                                                                        v10_17 = 0;
                                                                                        v13_0 = v23_0;
                                                                                        v12_0 = v24_0;
                                                                                    }
                                                                                }
                                                                                try {
                                                                                    if (!v12_0.renameTo(v2_0)) {
                                                                                        int v28_2 = v9_6;
                                                                                        v13_0 = v23_0;
                                                                                        try {
                                                                                            throw new java.io.IOException("Could not commit the Sparking manifest.");
                                                                                        } catch (Throwable v0_29) {
                                                                                            v9_6 = v28_2;
                                                                                        }
                                                                                    } else {
                                                                                        v13_0 = v23_0;
                                                                                        try {
                                                                                            if (!v13_0.renameTo(v1_0)) {
                                                                                                int v28_3 = v9_6;
                                                                                                try {
                                                                                                    throw new java.io.IOException("Could not commit the Sparking database.");
                                                                                                } catch (Throwable v0_32) {
                                                                                                    v9_6 = v28_3;
                                                                                                }
                                                                                            } else {
                                                                                                try {
                                                                                                    int v28_4 = v9_6;
                                                                                                    try {
                                                                                                        Throwable v0_40 = new org.json.JSONObject().put("latestVersion", ((Number) v8_6).longValue()).put("bytes", v6_2).put("sha256", com.personal.aihub.SparkingContent.hex(v0_12.digest())).put("xxhash64", v4_4).put("sourceURL", "https://ddl.dokkan-sparking.com/dokkan/assets/global/en/sqlite/current/en/database.db");
                                                                                                        v13_0.delete();
                                                                                                        v12_0.delete();
                                                                                                        v5_5.delete();
                                                                                                        v11_1.delete();
                                                                                                        return v0_40;
                                                                                                    } catch (Throwable v0_35) {
                                                                                                        v9_6 = v28_4;
                                                                                                        v4_8 = v0_35;
                                                                                                        v0_24 = 1;
                                                                                                        v3_0 = 1;
                                                                                                        v6_8 = 1;
                                                                                                    }
                                                                                                } catch (Throwable v0_35) {
                                                                                                }
                                                                                                v0_40 = new org.json.JSONObject().put("latestVersion", ((Number) v8_6).longValue()).put("bytes", v6_2).put("sha256", com.personal.aihub.SparkingContent.hex(v0_12.digest())).put("xxhash64", v4_4).put("sourceURL", "https://ddl.dokkan-sparking.com/dokkan/assets/global/en/sqlite/current/en/database.db");
                                                                                                v13_0.delete();
                                                                                                v12_0.delete();
                                                                                                v5_5.delete();
                                                                                                v11_1.delete();
                                                                                                return v0_40;
                                                                                            }
                                                                                        } catch (Throwable v0_32) {
                                                                                        }
                                                                                        v4_8 = v0_32;
                                                                                        v6_8 = 0;
                                                                                        v0_24 = 1;
                                                                                    }
                                                                                } catch (Throwable v0_29) {
                                                                                    v13_0 = v23_0;
                                                                                }
                                                                                v4_8 = v0_29;
                                                                                v0_24 = 0;
                                                                                v6_8 = 0;
                                                                            } catch (Throwable v0_25) {
                                                                                v11_1 = v20_0;
                                                                                v13_0 = v23_0;
                                                                                v12_0 = v24_0;
                                                                                v4_8 = v0_25;
                                                                                v0_24 = 0;
                                                                                v6_8 = 0;
                                                                                v10_17 = 0;
                                                                            }
                                                                        } else {
                                                                            try {
                                                                                if (!v1_0.renameTo(v5_5)) {
                                                                                    throw new java.io.IOException("Could not preserve the previous Sparking database.");
                                                                                } else {
                                                                                    v9_6 = 1;
                                                                                }
                                                                            } catch (Throwable v0_23) {
                                                                                v4_8 = v0_23;
                                                                                v0_24 = 0;
                                                                                v6_8 = 0;
                                                                                v9_6 = 0;
                                                                                v10_17 = 0;
                                                                                v11_1 = v20_0;
                                                                            }
                                                                        }
                                                                    }
                                                                } catch (Throwable v0_16) {
                                                                    v11_1 = v20_0;
                                                                    v13_0 = v23_0;
                                                                    v12_0 = v24_0;
                                                                }
                                                            } catch (Throwable v0_17) {
                                                                v11_1 = v20_0;
                                                                v13_0 = v23_0;
                                                                v12_0 = v24_0;
                                                            }
                                                        } catch (Throwable v0_18) {
                                                            v11_1 = v20_0;
                                                            v13_0 = v23_0;
                                                            v12_0 = v24_0;
                                                        }
                                                    } else {
                                                        long v23_1 = v3_0;
                                                        java.io.BufferedInputStream v24_1 = v4_3;
                                                        v6_2 += ((long) v12_8);
                                                        try {
                                                            if ((v6_2 > v18_0) || (v6_2 > 201326592)) {
                                                                break;
                                                            }
                                                            v3_0 = 0;
                                                            v15_1.write(v13_2, 0, v12_8);
                                                            v0_12.update(v13_2, 0, v12_8);
                                                            v10_13.update(v13_2, 0, v12_8);
                                                            long v21 = v13_2;
                                                            java.io.IOException v4_14 = v14_2;
                                                            v25 = v15_1;
                                                            String v14_5 = v6_2;
                                                            com.personal.aihub.SparkingContent.progress(p29, "database", v14_5, v18_0);
                                                            v14_2 = v4_14;
                                                            v13_2 = v21;
                                                            v3_0 = v23_1;
                                                            v4_3 = v24_1;
                                                            v15_1 = v25;
                                                        } catch (Throwable v0_43) {
                                                            v6_7 = v0_43;
                                                            v11_1 = v20_0;
                                                            v13_0 = v23_1;
                                                            v12_0 = v24_1;
                                                        }
                                                    }
                                                }
                                                v4_3 = v14_2;
                                                v25 = v15_1;
                                                v3_0 = 0;
                                                throw new java.io.IOException("The Sparking database exceeds its declared size.");
                                            } catch (Throwable v0_17) {
                                                v13_0 = v3_0;
                                                v12_0 = v4_3;
                                                v4_3 = v14_2;
                                                v11_1 = v20_0;
                                                v3_0 = 0;
                                            }
                                        } catch (Throwable v0_13) {
                                            v12_0 = v4_3;
                                            v11_1 = v20_0;
                                            v13_0 = v3_0;
                                            v3_0 = 0;
                                        }
                                    }
                                } else {
                                    try {
                                        v28_1 = v9_9;
                                        String v20_1 = v7_9;
                                        try {
                                            if ((((long) v0_65.size()) + ((long) v10_0)) > 33554432) {
                                                break;
                                            }
                                            v0_65.write(v12_11, 0, v10_0);
                                            String v8_16 = v12_11;
                                            Throwable v7_8 = v14_7;
                                            v6_0 = v15_2;
                                            com.personal.aihub.SparkingContent.progress(p29, "manifest", ((long) v0_65.size()), v16_1);
                                            v9_9 = v28_1;
                                            v15_2 = v6_0;
                                            v14_7 = v7_8;
                                            v12_11 = v8_16;
                                            v7_9 = v20_1;
                                        } catch (Throwable v0_46) {
                                            v13_0 = v3_0;
                                            v12_0 = v4_3;
                                            v11_1 = v20_1;
                                        }
                                    } catch (Throwable v0_46) {
                                        v20_1 = v7_9;
                                        v28_1 = v9_9;
                                        v6_0 = v15_2;
                                    }
                                }
                            }
                            v6_0 = v15_2;
                            throw new java.io.IOException(v14_7);
                        }
                    } catch (Throwable v0_4) {
                    }
                } catch (Throwable v0_4) {
                    v13_0 = v3_0;
                    v12_0 = v4_3;
                    v11_1 = v7_9;
                    v28_1 = v9_9;
                } catch (Throwable v0_13) {
                }
            } catch (Throwable v0_13) {
                v13_0 = v3_0;
                v12_0 = v4_3;
                v11_1 = v7_9;
            }
        }
    }

    public static org.json.JSONObject downloadAsset(java.io.File p21, String p22, java.io.File p23, com.personal.aihub.SparkingContent$Progress p24)
    {
        if (p21.isFile()) {
            String v3_2 = 0;
            if ((p21.length() > 0) && (p21.length() <= 33554432)) {
                String v1_18 = new java.io.FileInputStream(p21);
                try {
                    String v7_1 = new java.io.ByteArrayOutputStream();
                    try {
                        java.security.MessageDigest v8_1 = new byte[65536];
                    } catch (java.io.IOException v0_21) {
                        java.io.File v2_2 = v0_21;
                        try {
                            v7_1.close();
                        } catch (java.io.IOException v0_22) {
                            v2_2.addSuppressed(v0_22);
                        }
                        throw v2_2;
                    }
                    while(true) {
                        String v9_2 = v1_18.read(v8_1);
                        int v10_4 = -1;
                        if (v9_2 == -1) {
                            break;
                        }
                        if ((((long) v7_1.size()) + ((long) v9_2)) > 33554432) {
                            throw new java.io.IOException("The Sparking manifest exceeds32MiB.");
                        } else {
                            v7_1.write(v8_1, 0, v9_2);
                        }
                    }
                    String v5_2 = v7_1.toByteArray();
                    v7_1.close();
                    v1_18.close();
                    v1_18 = com.personal.aihub.SparkingContent.assetRecord(new org.json.JSONObject(new String(v5_2, java.nio.charset.StandardCharsets.UTF_8)), p22);
                    String v5_3 = com.personal.aihub.SparkingContent.destination(p23);
                    if (v5_3.equals(p21.getCanonicalFile())) {
                        throw new java.io.IOException("Do not overwrite the Sparking manifest with a game resource.");
                    } else {
                        String v6_4 = v5_3.getParentFile();
                        String v7_4 = new StringBuilder("sparking-asset-");
                        v7_4.append(java.util.UUID.randomUUID());
                        v7_4.append(".tmp");
                        java.io.File v2_7 = new java.io.File(v6_4, v7_4.toString());
                        String v6_6 = v1_18.getLong("size");
                        java.security.MessageDigest v8_6 = java.security.MessageDigest.getInstance("SHA-256");
                        String v9_4 = new com.personal.aihub.SparkingContent$XXH64();
                        try {
                            javax.net.ssl.HttpsURLConnection v18 = com.personal.aihub.SparkingContent.open(new java.net.URI(v1_18.getString("url")), 0);
                            try {
                                com.personal.aihub.SparkingContent$Progress v12_6 = v18.getContentLengthLong();
                            } catch (java.io.IOException v0_17) {
                                v18.disconnect();
                                throw v0_17;
                            }
                            if (v12_6 >= 0) {
                                if (v12_6 != v6_6) {
                                    throw new java.io.IOException("The Sparking resource size differs from its manifest.");
                                } else {
                                }
                            }
                            Throwable v14_1 = new java.io.BufferedInputStream(v18.getInputStream());
                            try {
                                java.io.FileOutputStream v15_0 = new java.io.FileOutputStream(v2_7);
                                try {
                                    byte[] v13_0 = new byte[131072];
                                } catch (java.io.IOException v0_10) {
                                    int v11_0 = v14_1;
                                    java.io.FileOutputStream v20 = v15_0;
                                    String v1_15 = v0_10;
                                    try {
                                        v20.close();
                                    } catch (java.io.IOException v0_14) {
                                        v1_15.addSuppressed(v0_14);
                                    }
                                    throw v1_15;
                                } catch (java.io.IOException v0_15) {
                                    String v1_16 = v0_15;
                                    try {
                                        v11_0.close();
                                    } catch (java.io.IOException v0_16) {
                                        v1_16.addSuppressed(v0_16);
                                    }
                                    throw v1_16;
                                }
                                while(true) {
                                    com.personal.aihub.SparkingContent$Progress v12_0 = v14_1.read(v13_0);
                                    if (v12_0 == v10_4) {
                                        v11_0 = v14_1;
                                        v20 = v15_0;
                                        v20.getFD().sync();
                                        v20.close();
                                        v11_0.close();
                                        v18.disconnect();
                                        String v9_1 = Long.toUnsignedString(v9_4.value());
                                        if ((v3_2 != v6_6) || (!v9_1.equals(v1_18.getString("hash")))) {
                                            throw new java.io.IOException("The Sparking resource checksum does not match. Existing content was kept.");
                                        } else {
                                            if (!v2_7.renameTo(v5_3)) {
                                                throw new java.io.IOException("Could not commit the Sparking game resource.");
                                            } else {
                                                java.io.IOException v0_9 = new org.json.JSONObject().put("file_path", p22).put("bytes", v3_2).put("sha256", com.personal.aihub.SparkingContent.hex(v8_6.digest())).put("xxhash64", v9_1);
                                                v2_7.delete();
                                                return v0_9;
                                            }
                                        }
                                    } else {
                                        v3_2 += ((long) v12_0);
                                        if (v3_2 > v6_6) {
                                            break;
                                        }
                                        v15_0.write(v13_0, 0, v12_0);
                                        v8_6.update(v13_0, 0, v12_0);
                                        v9_4.update(v13_0, 0, v12_0);
                                        byte[] v19 = v13_0;
                                        int v11_2 = v14_1;
                                        v20 = v15_0;
                                        com.personal.aihub.SparkingContent.progress(p24, "asset", v3_2, v6_6);
                                        v14_1 = v11_2;
                                        v13_0 = v19;
                                        v15_0 = v20;
                                        v11_0 = 0;
                                        v10_4 = -1;
                                    }
                                }
                                v11_0 = v14_1;
                                v20 = v15_0;
                                throw new java.io.IOException("The Sparking resource exceeds its declared size.");
                            } catch (java.io.IOException v0_15) {
                                v11_0 = v14_1;
                            }
                        } catch (java.io.IOException v0_18) {
                            v2_7.delete();
                            throw v0_18;
                        }
                    }
                } catch (java.io.IOException v0_23) {
                    java.io.File v2_3 = v0_23;
                    try {
                        v1_18.close();
                    } catch (java.io.IOException v0_24) {
                        v2_3.addSuppressed(v0_24);
                    }
                    throw v2_3;
                }
            }
        }
        throw new java.io.IOException("Update the Sparking content manifest first.");
    }

    public static org.json.JSONObject downloadManifest(java.io.File p19, com.personal.aihub.SparkingContent$Progress p20)
    {
        Throwable v0_0 = com.personal.aihub.SparkingContent.destination(p19);
        String v2_4 = v0_0.getParentFile();
        Throwable v3_14 = new StringBuilder("sparking-list-");
        v3_14.append(java.util.UUID.randomUUID());
        v3_14.append(".tmp");
        java.io.File v1_0 = new java.io.File(v2_4, v3_14.toString());
        try {
            String v2_3 = com.personal.aihub.SparkingContent.connect("https://dokkan-sparking.com/client_assets", 1);
            Throwable v3_6 = v2_3.getContentLengthLong();
        } catch (Throwable v0_12) {
            v1_0.delete();
            throw v0_12;
        }
        if (v3_6 > 33554432) {
            throw new java.io.IOException("The Sparking content list exceeds32MiB.");
        } else {
            java.io.InputStream v7_1 = v2_3.getInputStream();
            try {
                java.io.ByteArrayOutputStream v9_1 = new java.io.ByteArrayOutputStream();
            } catch (Throwable v0_9) {
                Throwable v3_4 = v0_9;
                if (v7_1 != null) {
                    try {
                        v7_1.close();
                    } catch (Throwable v0_10) {
                        v3_4.addSuppressed(v0_10);
                    }
                }
                throw v3_4;
            }
            try {
                byte[] v10_1 = new byte[65536];
            } catch (Throwable v0_7) {
                Throwable v3_2 = v0_7;
                try {
                    v9_1.close();
                } catch (Throwable v0_8) {
                    v3_2.addSuppressed(v0_8);
                }
                throw v3_2;
            }
            while(true) {
                long v11_2 = v7_1.read(v10_1);
                if (v11_2 == -1) {
                    break;
                }
                if (((long) (v9_1.size() + v11_2)) > 33554432) {
                    throw new java.io.IOException("The Sparking content list exceeds32MiB.");
                } else {
                    v9_1.write(v10_1, 0, v11_2);
                    com.personal.aihub.SparkingContent.progress(p20, "manifest", ((long) v9_1.size()), v2_3.getContentLengthLong());
                }
            }
            byte[] v5_1 = v9_1.toByteArray();
            v9_1.close();
            if (v7_1 != null) {
                v7_1.close();
            }
            v2_3.disconnect();
            if (v3_6 >= 0) {
                if (((long) v5_1.length) != v3_6) {
                    throw new java.io.IOException("The Sparking content list download is incomplete.");
                } else {
                }
            }
            String v2_10 = new org.json.JSONObject(new String(v5_1, java.nio.charset.StandardCharsets.UTF_8));
            com.personal.aihub.SparkingContent.databaseRecord(v2_10);
            String v2_11 = v2_10.get("latest_version");
            if (((!(v2_11 instanceof Integer)) && (!(v2_11 instanceof Long))) || (((Number) v2_11).longValue() <= 0)) {
                throw new java.io.IOException("Invalid Sparking content version.");
            } else {
                Throwable v3_19 = new java.io.FileOutputStream(v1_0);
                try {
                    v3_19.write(v5_1);
                    v3_19.getFD().sync();
                } catch (Throwable v0_19) {
                    String v2_13 = v0_19;
                    try {
                        v3_19.close();
                    } catch (Throwable v0_20) {
                        v2_13.addSuppressed(v0_20);
                    }
                    throw v2_13;
                }
                v3_19.close();
                if (!v1_0.renameTo(v0_0)) {
                    throw new java.io.IOException("Could not save Sparking\'s content list.");
                } else {
                    Throwable v0_4 = new org.json.JSONObject().put("latestVersion", ((Number) v2_11).longValue()).put("bytes", v5_1.length);
                    v1_0.delete();
                    return v0_4;
                }
            }
        }
    }

    private static void gamePath(String p13)
    {
        if ((p13 == null) || ((p13.length() > 500) || ((p13.indexOf(92) >= 0) || ((p13.indexOf(58) >= 0) || (p13.matches("(?s).*[\\x00-\\x1f\\x7f].*")))))) {
            throw new java.io.IOException("Unsupported Sparking game resource path.");
        } else {
            String v0_7 = p13.split("/", -1);
            String v3 = 0;
            while (v3 < v0_7.length) {
                String v4_0 = v0_7[v3];
                if ((v4_0.isEmpty()) || ((v4_0.equals(".")) || (v4_0.equals("..")))) {
                    throw new java.io.IOException("Unsafe Sparking game resource path.");
                } else {
                    v3++;
                }
            }
            String v0_9;
            if (p13.indexOf(47) >= 0) {
                v0_9 = p13.indexOf(47);
            } else {
                v0_9 = p13.length();
            }
            String v0_10 = p13.substring(0, v0_9);
            if (!v0_10.equals("se")) {
                if (!v0_10.equals("voice")) {
                    v3 = "script";
                    String v5 = "sound";
                    String v7 = "bgm";
                    String v9 = "card_category";
                    if (!java.util.Arrays.asList(new String[] {"character", "sugoroku"})).contains(v0_10)) {
                        throw new java.io.IOException("This download is not a supported game resource. Account and user-state files are excluded.");
                    } else {
                        return;
                    }
                } else {
                    java.io.IOException v13_10 = java.util.regex.Pattern.compile("voice/(?:(en|ja)/)?([A-Za-z0-9_-]{1,80})/([A-Za-z0-9_-]{1,80})\\.(acb|awb)").matcher(p13);
                    if ((!v13_10.matches()) || (!v13_10.group(2).equals(v13_10.group(3)))) {
                        throw new java.io.IOException("Unsupported Sparking voice bank path.");
                    } else {
                        return;
                    }
                }
            } else {
                if (!p13.matches("se/[A-Za-z0-9_-]{1,80}\\.(acb|awb)")) {
                    throw new java.io.IOException("Unsupported Sparking sound-effect bank path.");
                } else {
                    return;
                }
            }
        }
    }

    private static String hex(byte[] p6)
    {
        StringBuilder v0_1 = new StringBuilder();
        int v1 = p6.length;
        int v2 = 0;
        while (v2 < v1) {
            v0_1.append(String.format(java.util.Locale.ROOT, "%02x", new Object[] {Integer.valueOf((p6[v2] & 255))})));
            v2++;
        }
        return v0_1.toString();
    }

    private static javax.net.ssl.HttpsURLConnection open(java.net.URI p3, boolean p4)
    {
        java.io.IOException v3_4 = ((javax.net.ssl.HttpsURLConnection) p3.toURL().openConnection());
        v3_4.setInstanceFollowRedirects(0);
        v3_4.setConnectTimeout(20000);
        v3_4.setReadTimeout(60000);
        v3_4.setRequestProperty("Accept-Encoding", "identity");
        v3_4.setRequestProperty("User-Agent", "Dokkan-Unit-Creation-Sparking-Content");
        if (p4 != null) {
            v3_4.setRequestProperty("Accept", "application/json");
            v3_4.setRequestProperty("X-AssetVersion", "0");
            v3_4.setRequestProperty("Sparking_Asset_Version", "0");
        }
        String v4_4 = v3_4.getResponseCode();
        if (v4_4 == 200) {
            String v4_6 = v3_4.getHeaderField("Content-Encoding");
            if ((v4_6 != null) && (!v4_6.equalsIgnoreCase("identity"))) {
                v3_4.disconnect();
                throw new java.io.IOException("The Sparking server changed its download encoding.");
            } else {
                return v3_4;
            }
        } else {
            String v4_10;
            v3_4.disconnect();
            if ((v4_4 != 401) && (v4_4 != 403)) {
                StringBuilder v0_9 = new StringBuilder("The Sparking public content server returned HTTP ");
                v0_9.append(v4_4);
                v0_9.append(". Try again later.");
                v4_10 = v0_9.toString();
            } else {
                v4_10 = "The Sparking public content server refused this request. No account credentials were sent.";
            }
            throw new java.io.IOException(v4_10);
        }
    }

    private static void progress(com.personal.aihub.SparkingContent$Progress p0, String p1, long p2, long p4)
    {
        if (p0 != null) {
            p0.update(p1, p2, p4);
        }
        return;
    }
}
