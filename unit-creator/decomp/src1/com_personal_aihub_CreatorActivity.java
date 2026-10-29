package com.personal.aihub;
public final class CreatorActivity extends android.app.Activity {
    private static final Object DATABASE_WRITES = None;
    private static final String ORIGIN = "https://forge.local";
    private static final Object PROJECT_WRITES;
    private java.io.File assets;
    private android.database.sqlite.SQLiteDatabase db;
    private volatile org.json.JSONObject importProgress;
    private com.personal.aihub.MovieStorage movieUploads;
    private org.json.JSONObject pendingExport;
    private int pendingId;
    private String pendingMethod;
    private java.io.File projects;
    private java.io.File root;
    private org.json.JSONObject schema;
    private android.database.sqlite.SQLiteDatabase sparkingDb;
    private org.json.JSONObject sparkingSchema;
    private com.personal.aihub.WebViewStartup startup;
    private android.webkit.WebView web;
    private final java.util.concurrent.ExecutorService worker;

    static CreatorActivity()
    {
        com.personal.aihub.CreatorActivity.DATABASE_WRITES = new Object();
        com.personal.aihub.CreatorActivity.PROJECT_WRITES = new Object();
        return;
    }

    public CreatorActivity()
    {
        this.worker = java.util.concurrent.Executors.newSingleThreadExecutor();
        this.pendingId = -1;
        this.pendingMethod = "";
        this.importProgress = new org.json.JSONObject();
        return;
    }

    static synthetic com.personal.aihub.WebViewStartup access$000(com.personal.aihub.CreatorActivity p0)
    {
        return p0.startup;
    }

    static synthetic android.webkit.WebView access$102(com.personal.aihub.CreatorActivity p0, android.webkit.WebView p1)
    {
        p0.web = p1;
        return p1;
    }

    static synthetic org.json.JSONObject access$200(com.personal.aihub.CreatorActivity p0)
    {
        return p0.importProgress;
    }

    static synthetic java.util.concurrent.ExecutorService access$300(com.personal.aihub.CreatorActivity p0)
    {
        return p0.worker;
    }

    static synthetic int access$400(String p0)
    {
        return com.personal.aihub.CreatorActivity.apkDatabaseRank(p0);
    }

    private org.json.JSONObject animationCatalog(org.json.JSONObject p19)
    {
        void v18_1 = this.ensureDb();
        int v3_3 = "sparking".equals(p19.optString("sourceDatabase"));
        if (v3_3 != 0) {
            v18_1.ensureSparkingDb();
        }
        android.database.Cursor v5_0;
        if (v3_3 == 0) {
            v5_0 = this.db;
        } else {
            v5_0 = this.sparkingDb;
        }
        org.json.JSONArray v6_0;
        if (v3_3 == 0) {
            v6_0 = this.schema;
        } else {
            v6_0 = this.sparkingSchema;
        }
        String v7_1 = new org.json.JSONArray(this.readTextAsset("ui/data/animation-queries.json", 100000));
        org.json.JSONObject v8_13 = new java.util.ArrayList();
        int v10 = 0;
        int v11_0 = 0;
        while (v11_0 < v7_1.length()) {
            String v1_4 = v7_1.getJSONObject(v11_0);
            String v12_3 = v1_4.getJSONArray("tables");
            int v14_0 = 0;
            String v13_6 = 1;
            while (v14_0 < v12_3.length()) {
                if (!v6_0.has(v12_3.getString(v14_0))) {
                    v13_6 = 0;
                }
                v14_0++;
            }
            if (v13_6 != null) {
                v8_13.add(v1_4.getString("sql"));
            }
            v11_0++;
        }
        if (!v8_13.isEmpty()) {
            org.json.JSONArray v6_6 = new java.util.ArrayList();
            String v12_6 = new java.util.ArrayList();
            int v14_2 = p19.optString("search");
            boolean v15_4 = p19.optString("kind", "all");
            if (v14_2.length() > 100) {
                v14_2 = v14_2.substring(0, 100);
            }
            if (!v14_2.isEmpty()) {
                v12_6.add("(unitName LIKE ? OR moveName LIKE ?)");
                String v1_10 = new StringBuilder("%");
                v1_10.append(v14_2);
                v1_10.append("%");
                v6_6.add(v1_10.toString());
                String v1_13 = new StringBuilder("%");
                v1_13.append(v14_2);
                v1_13.append("%");
                v6_6.add(v1_13.toString());
            }
            if (!v15_4.equals("all")) {
                v12_6.add("kind=?");
                v6_6.add(v15_4);
            }
            if (p19.optLong("unitId") > 0) {
                v12_6.add("unitId=?");
                v6_6.add(String.valueOf(p19.optLong("unitId")));
            }
            org.json.JSONObject v8_5;
            org.json.JSONObject v0_3 = Math.max(0, Math.min(100000, p19.optInt("offset")));
            v6_6.add("13");
            v6_6.add(String.valueOf(v0_3));
            String[] v9_6 = new StringBuilder();
            v9_6.append("SELECT * FROM (");
            v9_6.append(String.join(" UNION ALL ", v8_13));
            v9_6.append(")");
            if (!v12_6.isEmpty()) {
                org.json.JSONObject v8_4 = new StringBuilder();
                v8_4.append(" WHERE ");
                v8_4.append(String.join(" AND ", v12_6));
                v8_5 = v8_4.toString();
            } else {
                v8_5 = "";
            }
            v9_6.append(v8_5);
            v9_6.append(" ORDER BY unitId=0, unitName, moveName, unitId, key LIMIT ? OFFSET ?");
            String[] v9_7 = new String[0];
            android.database.Cursor v5_1 = v5_0.rawQuery(v9_6.toString(), ((String[]) v6_6.toArray(v9_7)));
            try {
                org.json.JSONArray v6_3 = com.personal.aihub.CreatorActivity.rows(v5_1);
            } catch (org.json.JSONObject v0_5) {
                if (v5_1 != null) {
                    v5_1.close();
                }
                throw v0_5;
            }
            if (v3_3 != 0) {
                int v3_0 = 0;
                while (v3_0 < v6_3.length()) {
                    v6_3.getJSONObject(v3_0).put("sourceDatabase", "sparking");
                    v3_0++;
                }
            }
            if (v5_1 != null) {
                v5_1.close();
            }
            if (v6_3.length() > 12) {
                v10 = 1;
            }
            if (v10 != 0) {
                v6_3.remove(12);
            }
            return new org.json.JSONObject().put("items", v6_3).put("more", v10).put("offset", v0_3);
        } else {
            return new org.json.JSONObject().put("items", new org.json.JSONArray()).put("more", 0);
        }
    }

    private org.json.JSONArray animationFiles(boolean p7)
    {
        java.util.Iterator v0_1 = new java.io.File(this.root, "animation-files.json");
        String v1_2 = new java.util.TreeSet();
        java.util.Iterator v2_0 = new com.personal.aihub.PreviewCache(this.root).offline();
        if ((v0_1.exists()) && ((p7 == null) || (v2_0 != null))) {
            com.personal.aihub.PreviewScripts.add(v1_2, new org.json.JSONArray(com.personal.aihub.CreatorActivity.readText(v0_1, 2097152)));
        }
        if ((p7 != null) && (v2_0 == null)) {
            com.personal.aihub.PreviewScripts.add(v1_2, new org.json.JSONObject(this.fetchText("https://dokkan-eclipse.com/api/scripts", 2097152)).optJSONArray("scripts"));
        }
        try {
            if ((v1_2.isEmpty()) && (v0_1.exists())) {
                com.personal.aihub.PreviewScripts.add(v1_2, new org.json.JSONArray(com.personal.aihub.CreatorActivity.readText(v0_1, 2097152)));
            }
        } catch (Exception) {
        }
        if (v1_2.isEmpty()) {
            com.personal.aihub.PreviewScripts.add(v1_2, com.personal.aihub.PreviewScripts.listing(this, 0).getJSONArray("scripts"));
        }
        org.json.JSONArray v7_13 = new org.json.JSONArray();
        java.util.Iterator v2_5 = v1_2.iterator();
        while (v2_5.hasNext()) {
            v7_13.put(((String) v2_5.next()));
        }
        com.personal.aihub.CreatorActivity.writeText(v0_1, v7_13.toString());
        com.personal.aihub.PreviewScripts.imported(this.assets, v1_2);
        org.json.JSONArray v7_17 = new org.json.JSONArray();
        java.util.Iterator v0_2 = v1_2.iterator();
        while (v0_2.hasNext()) {
            v7_17.put(((String) v0_2.next()));
        }
        return v7_17;
    }

    private org.json.JSONObject animationSource(String p2)
    {
        return this.animationSource(p2, "");
    }

    private org.json.JSONObject animationSource(String p2, String p3)
    {
        return this.animationSource(p2, p3, 0);
    }

    private org.json.JSONObject animationSource(String p11, String p12, boolean p13)
    {
        if (!com.personal.aihub.CreatorActivity.validAnimationPath(p11)) {
            throw new java.io.IOException("Choose an animation from the browser");
        } else {
            String v12_13;
            if (p13 == null) {
                String v13_1 = new com.personal.aihub.GameAssets(this.assets, p12);
                String v12_11 = new StringBuilder("lua/");
                v12_11.append(p11);
                v12_13 = v13_1.read(v12_11.toString(), 2097152);
            } else {
                v12_13 = 0;
            }
            if (v12_13 == null) {
                String v12_15 = this.dataStore().meta();
                String v12_18 = v12_15.optString("date", v12_15.optString("sha256", "bundled")).replaceAll("[^a-zA-Z0-9_-]", "");
                if (v12_18.length() > 80) {
                    v12_18 = v12_18.substring(0, 80);
                }
                String v0_3;
                java.io.File v5_6 = new java.io.File(new java.io.File(new java.io.File(this.root, "animation-sources"), v12_18), p11);
                String v12_19 = v5_6.exists();
                if (v12_19 == null) {
                    String v6_7 = new StringBuilder("https://dokkan-eclipse.com/cdn/uncompressed/lua/");
                    v6_7.append(p11);
                    v0_3 = this.fetchText(v6_7.toString(), 2097152);
                } else {
                    v0_3 = com.personal.aihub.CreatorActivity.readText(v5_6, 2097152);
                }
                if ((v0_3.trim().isEmpty()) || ((v0_3.trim().startsWith("<")) || (v0_3.indexOf(0) >= 0))) {
                    throw new java.io.IOException("Unreadable animation file");
                } else {
                    if (v12_19 == null) {
                        v5_6.getParentFile().mkdirs();
                        com.personal.aihub.CreatorActivity.writeText(v5_6, v0_3);
                    }
                    return new org.json.JSONObject().put("path", p11).put("text", v0_3).put("cached", v12_19);
                }
            } else {
                String v0_2 = new String(v12_13, java.nio.charset.StandardCharsets.UTF_8);
                if ((v0_2.trim().isEmpty()) || ((v0_2.trim().startsWith("<")) || (v0_2.indexOf(0) >= 0))) {
                    throw new java.io.IOException("Unreadable imported animation file");
                } else {
                    return new org.json.JSONObject().put("path", p11).put("text", v0_2).put("cached", 1).put("local", 1);
                }
            }
        }
    }

    private org.json.JSONObject animationVisuals(long p12)
    {
        if (p12 < 1) {
            throw new java.io.IOException("Choose a character");
        } else {
            org.json.JSONArray v0_5 = new com.personal.aihub.PreviewCache(this.root);
            String v1_1 = new StringBuilder("https://dokkan-eclipse.com/api/card/");
            v1_1.append(p12);
            String v13_1 = "";
            org.json.JSONObject v12_6 = com.personal.aihub.PreviewMetadata.resolve(this, v0_5, v1_1.toString(), "");
            org.json.JSONArray v0_3 = new org.json.JSONArray();
            StringBuilder v3_0 = 0;
            while (v3_0 < 4) {
                String v7_0;
                org.json.JSONObject v4_0 = new String[][] {new String[] {"battle", "Battle poses"}), new String[] {"idle", "Idle poses"}), new String[] {"sp", "Attack poses"}), new String[] {"card_bg", "Animated card background"})})[v3_0];
                StringBuilder v9_1 = v12_6.optJSONObject(v4_0[0]);
                if (v9_1 != null) {
                    v7_0 = v9_1.optString("rel");
                } else {
                    v7_0 = "";
                }
                if ((v7_0.matches("(?i)[a-z0-9_./-]+\\.lwf")) && (com.personal.aihub.CreatorActivity.safePath(v7_0))) {
                    org.json.JSONObject v6_3 = new org.json.JSONObject();
                    StringBuilder v9_3 = new StringBuilder();
                    v9_3.append(String.valueOf(v12_6.optString("name")));
                    v9_3.append(" \u00b7 ");
                    v9_3.append(v4_0[1]);
                    v0_3.put(v6_3.put("name", v9_3.toString()).put("path", v7_0));
                }
                v3_0++;
            }
            try {
                if (v12_6.optLong("aura_effect_id") > 0) {
                    String v2_8 = new com.personal.aihub.PreviewCache(this.root);
                    StringBuilder v3_6 = new StringBuilder();
                    v3_6.append("https://dokkan-eclipse.com/api/effect-pack/");
                    v3_6.append(v12_6.optLong("aura_effect_id"));
                    String v1_7 = com.personal.aihub.PreviewMetadata.resolve(this, v2_8, v3_6.toString(), "");
                    String v2_10 = v1_7.optJSONObject("lwf");
                    if (v2_10 != null) {
                        v13_1 = v2_10.optString("rel");
                    }
                    if ((v13_1.matches("(?i)[a-z0-9_./-]+\\.lwf")) && (com.personal.aihub.CreatorActivity.safePath(v13_1))) {
                        String v2_14 = new org.json.JSONObject();
                        StringBuilder v3_8 = new StringBuilder();
                        v3_8.append(String.valueOf(v12_6.optString("name")));
                        v3_8.append(" \u00b7 Aura");
                        v0_3.put(v2_14.put("name", v3_8.toString()).put("path", v13_1).put("scene", v1_7.optString("scene_name")));
                    }
                }
            } catch (Exception) {
            }
            return new org.json.JSONObject().put("items", v0_3);
        }
    }

    private static int apkDatabaseRank(String p1)
    {
        if (!p1.contains("/sqlite/current/en/")) {
            return 1;
        } else {
            int v1_1;
            if (!p1.contains("_decrypted")) {
                v1_1 = 2;
            } else {
                v1_1 = 3;
            }
            return v1_1;
        }
    }

    private java.net.HttpURLConnection connection(String p2)
    {
        return this.connection(p2, 0);
    }

    private java.net.HttpURLConnection connection(String p4, int p5)
    {
        if (p5 > 5) {
            throw new java.io.IOException("Too many Eclipse redirects");
        } else {
            String v0_4 = new java.net.URL(p4);
            if ((!v0_4.getProtocol().equals("https")) || (!v0_4.getHost().equals("dokkan-eclipse.com"))) {
                throw new java.io.IOException("Only official Eclipse resource routes are supported");
            } else {
                java.io.IOException v4_8 = ((java.net.HttpURLConnection) v0_4.openConnection());
                v4_8.setConnectTimeout(20000);
                v4_8.setReadTimeout(60000);
                v4_8.setInstanceFollowRedirects(0);
                v4_8.setRequestProperty("User-Agent", "DokkanUnitCreator/2.3");
                String v1_6 = v4_8.getResponseCode();
                if ((v1_6 < 300) || (v1_6 >= 400)) {
                    if (v1_6 != 200) {
                        v4_8.disconnect();
                        String v5_5 = new StringBuilder("Eclipse returned HTTP ");
                        v5_5.append(v1_6);
                        v5_5.append(". You can import a local database or resource pack instead.");
                        throw new java.io.IOException(v5_5.toString());
                    } else {
                        return v4_8;
                    }
                } else {
                    String v1_8 = v4_8.getHeaderField("Location");
                    v4_8.disconnect();
                    return this.connection(new java.net.URL(v0_4, v1_8).toString(), (p5 + 1));
                }
            }
        }
    }

    private static void copy(java.io.InputStream p6, java.io.OutputStream p7, long p8)
    {
        byte[] v0_1 = new byte[65536];
        long v1 = 0;
        while(true) {
            int v3 = p6.read(v0_1);
            if (v3 != -1) {
                v1 += ((long) v3);
                if (v1 > p8) {
                    break;
                }
                p7.write(v0_1, 0, v3);
            } else {
                return;
            }
        }
        throw new java.io.IOException("File exceeds the supported import size.");
    }

    private static void cpkWarning(org.json.JSONArray p2, String p3)
    {
        if (p2.length() >= 200) {
            if (p2.length() == 200) {
                p3 = "Additional CPK warnings were omitted. Original archives were kept.";
            } else {
                return;
            }
        }
        p2.put(p3);
        return;
    }

    private com.personal.aihub.GameDataStore dataStore()
    {
        return new com.personal.aihub.GameDataStore(this.root, new java.io.File(this.root, "bundled-database.db"));
    }

    private static void deleteTree(java.io.File p4)
    {
        if (p4.isDirectory()) {
            java.io.File[] v0_1 = p4.listFiles();
            if (v0_1 != null) {
                int v1 = v0_1.length;
                int v2 = 0;
                while (v2 < v1) {
                    com.personal.aihub.CreatorActivity.deleteTree(v0_1[v2]);
                    v2++;
                }
            }
        }
        p4.delete();
        return;
    }

    private org.json.JSONObject downloadAsset(String p2)
    {
        return this.downloadAsset(p2, 0);
    }

    private org.json.JSONObject downloadAsset(String p6, String p7)
    {
        if ((!com.personal.aihub.CreatorActivity.safePath(p6)) || (!p6.matches("(?i).*\\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$"))) {
            throw new java.io.IOException("Choose a supported resource file");
        } else {
            if ((p7 != null) && (!p7.matches("^art-download-[0-9]{10,16}-[A-Za-z0-9_-]{6,64}$"))) {
                throw new java.io.IOException("Invalid artwork collection.");
            } else {
                long v1_0;
                String v0_4 = new StringBuilder();
                if (p7 != null) {
                    v1_0 = p7;
                } else {
                    v1_0 = "eclipse";
                }
                org.json.JSONObject v7_2;
                v0_4.append(String.valueOf(v1_0));
                v0_4.append("/");
                v0_4.append(p6);
                String v0_6 = v0_4.toString();
                java.io.File v2_1 = com.personal.aihub.AssetDownload.destination(this.assets, v0_6);
                String v0_9 = new org.json.JSONObject().put("key", v0_6).put("path", p6).put("name", v2_1.getName());
                long v3_5 = new StringBuilder("https://dokkan-eclipse.com/cdn/uncompressed/");
                v3_5.append(android.net.Uri.encode(p6, "/"));
                long v1_5 = com.personal.aihub.AssetDownload.openOfficial(v3_5.toString());
                if (p7 == null) {
                    v7_2 = 0;
                } else {
                    v7_2 = 1;
                }
                return v0_9.put("size", com.personal.aihub.AssetDownload.write(v1_5, v2_1, v7_2, 167772160)).put("image", p6.matches("(?i).*\\.(png|jpe?g|webp|gif|bmp)$"));
            }
        }
    }

    private org.json.JSONObject downloadCurrentDatabase(org.json.JSONObject p26)
    {
        String v1_5 = this.root;
        String v2_9 = new StringBuilder("database-download-");
        v2_9.append(java.util.UUID.randomUUID());
        v2_9.append(".tmp");
        java.io.File v9_0 = new java.io.File(v1_5, v2_9.toString());
        try {
            this.progress("download", "Downloading Eclipse\u2019s current full English database", 0, 0);
            java.net.HttpURLConnection v10 = this.connection("https://dokkan-eclipse.com/cdn/uncompressed/sqlite/current/en/database_decrypted.db");
            long v11_0 = v10.getContentLengthLong();
        } catch (java.io.IOException v0_7) {
            if (v10 != null) {
                v10.disconnect();
            }
            v9_0.delete();
            throw v0_7;
        }
        if (v11_0 > 536870912) {
            throw new java.io.IOException("Database download exceeds 512 MB");
        } else {
            long v6_1 = v10.getInputStream();
            try {
                java.io.FileOutputStream v7_0 = new java.io.FileOutputStream(v9_0);
                try {
                    String v4_1 = new byte[65536];
                    String v2_3 = 0;
                } catch (java.io.IOException v0_3) {
                    java.io.InputStream v18 = v6_1;
                    java.io.FileOutputStream v24_0 = v7_0;
                    String v1_1 = v0_3;
                    try {
                        v24_0.close();
                    } catch (java.io.IOException v0_4) {
                        v1_1.addSuppressed(v0_4);
                    }
                    throw v1_1;
                } catch (java.io.IOException v0_5) {
                    String v1_2 = v0_5;
                    if (v18 != null) {
                        try {
                            v18.close();
                        } catch (java.io.IOException v0_6) {
                            v1_2.addSuppressed(v0_6);
                        }
                    }
                    throw v1_2;
                }
                while(true) {
                    String v1_7 = v6_1.read(v4_1);
                    if (v1_7 == -1) {
                        v18 = v6_1;
                        v7_0.close();
                        if (v18 != null) {
                            v18.close();
                        }
                        if (v11_0 > 0) {
                            if (v2_3 != v11_0) {
                                throw new java.io.IOException("The database download was incomplete");
                            } else {
                            }
                        }
                        long v13_1 = v2_3;
                        this.progress("verify", "Checking downloaded database", 0, 0);
                        this.verifyDb(v9_0, 1);
                        java.io.IOException v0_15 = this.useDb(v9_0, "Eclipse current full English database", new org.json.JSONObject(p26.toString()).put("sourceType", "eclipse-current").put("downloadUrl", "https://dokkan-eclipse.com/cdn/uncompressed/sqlite/current/en/database_decrypted.db").put("publishedAt", v10.getHeaderField("Last-Modified")).put("downloadedBytes", v13_1));
                        if (v10 != null) {
                            v10.disconnect();
                        }
                        v9_0.delete();
                        return v0_15;
                    } else {
                        v18 = v6_1;
                        long v19 = (v2_3 + ((long) v1_7));
                        try {
                            if (v19 > 536870912) {
                                break;
                            }
                            v7_0.write(v4_1, 0, v1_7);
                            byte[] v23 = v4_1;
                            v24_0 = v7_0;
                            this.progress("download", "Downloading Eclipse\u2019s current full English database", v19, Math.max(0, v11_0));
                            v6_1 = v18;
                            v2_3 = v19;
                            v4_1 = v23;
                            v7_0 = v24_0;
                        } catch (java.io.IOException v0_3) {
                        }
                    }
                }
                v24_0 = v7_0;
                throw new java.io.IOException("Database download exceeds 512 MB");
            } catch (java.io.IOException v0_5) {
                v18 = v6_1;
            }
        }
    }

    private org.json.JSONObject downloadSparkingAssets(org.json.JSONObject p31)
    {
        com.personal.aihub.CreatorActivity v1_0 = this;
        Throwable v2_0 = "hash";
        java.io.File v4_2 = this.sparkingAssetManifest(p31.optLong("version", -1));
        int v5_3 = this.sparkingStore().meta().getLong("latestVersion");
        org.json.JSONObject v7_0 = new org.json.JSONObject(com.personal.aihub.CreatorActivity.readText(v4_2, 33554432));
        java.io.File v8_3 = new java.io.File(new java.io.File(this.root, "sparking"), "resource-cache");
        v8_3.mkdirs();
        Throwable v0_24 = p31.getJSONArray("paths");
        if ((v0_24.length() < 1) || (v0_24.length() > 32)) {
            throw new java.io.IOException("Choose between 1 and 32 game resource files at a time.");
        } else {
            String v9_6 = new StringBuilder("sparking-");
            v9_6.append(java.util.UUID.randomUUID());
            String v9_7 = v9_6.toString();
            java.io.File v10_6 = this.assetFile(v9_7);
            v10_6.mkdirs();
            org.json.JSONArray v12_17 = new org.json.JSONArray();
            java.util.HashSet v13_8 = new java.util.HashSet();
            long v14_6 = 0;
            int v5_4 = 0;
            long v16_1 = v5_3;
            try {
                while (v5_4 < v0_24.length()) {
                    try {
                        long v6_3 = v0_24.getString(v5_4);
                    } catch (Throwable v0_14) {
                        com.personal.aihub.CreatorActivity.deleteTree(v10_6);
                        throw v0_14;
                    }
                    if (!com.personal.aihub.CreatorActivity.safePath(v6_3)) {
                        throw new java.io.IOException("Invalid Sparking game resource path.");
                    } else {
                        Exception v31_1 = v0_24;
                        org.json.JSONArray v18_1 = v5_4;
                        if (!v13_8.add(java.text.Normalizer.normalize(v6_3, java.text.Normalizer$Form.NFC).toLowerCase(java.util.Locale.ROOT))) {
                            throw new java.io.IOException("Selected resources have conflicting game paths.");
                        } else {
                            Throwable v0_4 = com.personal.aihub.SparkingContent.assetRecord(v7_0, v6_3);
                            long v14_0 = (v14_6 + v0_4.getLong("size"));
                            int v5_1 = v12_17;
                            java.util.HashSet v19_1 = v13_8;
                            if (v14_0 > 536870912) {
                                throw new java.io.IOException("This resource batch exceeds512MB. Choose fewer resources.");
                            } else {
                                org.json.JSONObject v24_1;
                                org.json.JSONArray v12_2 = new StringBuilder();
                                v12_2.append(v0_4.getString(v2_0));
                                v12_2.append("-");
                                long v21 = v14_0;
                                v12_2.append(v0_4.getLong("size"));
                                org.json.JSONArray v12_3 = v12_2.toString();
                                long v14_2 = new StringBuilder();
                                v14_2.append(v12_3);
                                v14_2.append(".data");
                                java.util.HashSet v13_4 = new java.io.File(v8_3, v14_2.toString());
                                String v15_2 = new StringBuilder();
                                v15_2.append(v12_3);
                                v15_2.append(".json");
                                long v14_5 = new java.io.File(v8_3, v15_2.toString());
                                java.io.FileInputStream v23_0 = 0;
                                try {
                                    if ((!v13_4.isFile()) || ((v13_4.length() != v0_4.getLong("size")) || (!v14_5.isFile()))) {
                                        v24_1 = v7_0;
                                    } else {
                                        v24_1 = v7_0;
                                        v7_0 = 8192;
                                        org.json.JSONArray v12_10 = new org.json.JSONObject(com.personal.aihub.CreatorActivity.readText(v14_5, 8192));
                                        if ((v0_4.getString(v2_0).equals(v12_10.getString("xxhash64"))) && (com.personal.aihub.GameDataStore.hash(v13_4).equals(v12_10.getString("sha256")))) {
                                            v23_0 = v12_10;
                                        }
                                    }
                                    if (v23_0 == null) {
                                        v23_0 = com.personal.aihub.SparkingContent.downloadAsset(v4_2, v6_3, v13_4, new com.personal.aihub.CreatorActivity$$ExternalSyntheticLambda1(v1_0));
                                        com.personal.aihub.CreatorActivity.writeText(v14_5, v23_0.toString());
                                    }
                                    Throwable v0_15 = v23_0;
                                    org.json.JSONObject v7_7 = new java.io.File(v10_6, v6_3);
                                    v7_7.getParentFile().mkdirs();
                                    org.json.JSONArray v12_13 = new java.io.FileInputStream(v13_4);
                                    try {
                                        java.util.HashSet v13_6 = new java.io.FileOutputStream(v7_7);
                                        java.io.FileInputStream v23_1 = v2_0;
                                        try {
                                            com.personal.aihub.CreatorActivity.copy(v12_13, v13_6, 536870912);
                                        } catch (Throwable v0_16) {
                                            com.personal.aihub.CreatorActivity v1_4 = v0_16;
                                            try {
                                                v13_6.close();
                                            } catch (Throwable v0_17) {
                                                v1_4.addSuppressed(v0_17);
                                            }
                                            throw v1_4;
                                        }
                                        v13_6.close();
                                        v12_13.close();
                                        com.personal.aihub.CreatorActivity v1_7 = new org.json.JSONObject();
                                        org.json.JSONArray v12_15 = new StringBuilder();
                                        v12_15.append(v9_7);
                                        v12_15.append("/");
                                        v12_15.append(v6_3);
                                        v5_1.put(v1_7.put("key", v12_15.toString()).put("path", v6_3).put("sourcePath", v6_3).put("size", v7_7.length()).put("sha256", v0_15.getString("sha256")).put("source", "sparking"));
                                        v1_0 = this;
                                        v12_17 = v5_1;
                                        v13_8 = v19_1;
                                        v14_6 = v21;
                                        v2_0 = v23_1;
                                        v7_0 = v24_1;
                                        v5_4 = (v18_1 + 1);
                                        v0_24 = v31_1;
                                    } catch (Throwable v0_18) {
                                        com.personal.aihub.CreatorActivity v1_5 = v0_18;
                                        try {
                                            v12_13.close();
                                        } catch (Throwable v0_19) {
                                            v1_5.addSuppressed(v0_19);
                                        }
                                        throw v1_5;
                                    }
                                } catch (Exception) {
                                } catch (Exception) {
                                }
                            }
                        }
                    }
                }
            } catch (Throwable v0_14) {
            }
            int v5_6 = v12_17;
            return this.expandCpkResources(v10_6, v5_6.length(), v14_6).put("assets", v5_6).put("sourceVersion", v16_1);
        }
    }

    private void ensureDb()
    {
        if (this.db == null) {
            com.personal.aihub.ForgeFixes.refreshBundledDatabase(this, this.root);
            java.io.IOException v0_17 = new java.io.File(this.root, "bundled-database.db");
            if (!v0_17.exists()) {
                Throwable v1_2 = new java.io.File(this.root, "bundled.tmp");
                Throwable v2_2 = this.getAssets().open("reference.db");
                try {
                    android.database.Cursor v3_3 = new java.io.FileOutputStream(v1_2);
                } catch (java.io.IOException v0_4) {
                    if (v2_2 != null) {
                        try {
                            v2_2.close();
                        } catch (Throwable v1_4) {
                            v0_4.addSuppressed(v1_4);
                        }
                    }
                    throw v0_4;
                }
                try {
                    com.personal.aihub.CreatorActivity.copy(v2_2, v3_3, 536870912);
                } catch (java.io.IOException v0_3) {
                    try {
                        v3_3.close();
                    } catch (Throwable v1_3) {
                        v0_3.addSuppressed(v1_3);
                    }
                    throw v0_3;
                }
                v3_3.close();
                if (v2_2 != null) {
                    v2_2.close();
                }
                if (!v1_2.renameTo(v0_17)) {
                    throw new java.io.IOException("Could not prepare the card database.");
                }
            }
            this.db = android.database.sqlite.SQLiteDatabase.openDatabase(this.dataStore().current().getPath(), 0, 1);
            this.schema = new org.json.JSONObject();
            java.io.IOException v0_16 = this.db.rawQuery("SELECT name FROM sqlite_master WHERE type=\'table\'", 0);
            try {
                while (v0_16.moveToNext()) {
                    Throwable v1_11 = v0_16.getString(0);
                    if (v1_11.matches("[a-zA-Z_][a-zA-Z0-9_]*")) {
                        android.database.Cursor v3_6 = this.db;
                        org.json.JSONObject v4_2 = new StringBuilder();
                        v4_2.append("PRAGMA table_info(");
                        v4_2.append(com.personal.aihub.CreatorActivity.identifier(v1_11));
                        v4_2.append(")");
                        android.database.Cursor v3_7 = v3_6.rawQuery(v4_2.toString(), 0);
                        try {
                            this.schema.put(v1_11, com.personal.aihub.CreatorActivity.rows(v3_7));
                        } catch (Throwable v1_13) {
                            if (v3_7 != null) {
                                try {
                                    v3_7.close();
                                } catch (Throwable v2_5) {
                                    v1_13.addSuppressed(v2_5);
                                }
                            }
                            throw v1_13;
                        }
                        if (v3_7 != null) {
                            v3_7.close();
                        }
                    }
                }
            } catch (Throwable v1_0) {
                if (v0_16 != null) {
                    try {
                        v0_16.close();
                    } catch (java.io.IOException v0_1) {
                        v1_0.addSuppressed(v0_1);
                    }
                }
                throw v1_0;
            }
            if (v0_16 != null) {
                v0_16.close();
            }
            return;
        } else {
            return;
        }
    }

    private void ensureSparkingDb()
    {
        if (this.sparkingDb == null) {
            this.prepareSparkingSnapshot();
            android.database.sqlite.SQLiteDatabase v0_1 = android.database.sqlite.SQLiteDatabase.openDatabase(this.sparkingStore().current().getPath(), 0, 1);
            Throwable v1_1 = new org.json.JSONObject();
            try {
                android.database.Cursor v3_1 = v0_1.rawQuery("SELECT name FROM sqlite_master WHERE type=\'table\'", 0);
                try {
                    while (v3_1.moveToNext()) {
                        String v4_2 = v3_1.getString(0);
                        if (v4_2.matches("[a-zA-Z_][a-zA-Z0-9_]*")) {
                            android.database.Cursor v5_3 = new StringBuilder();
                            v5_3.append("PRAGMA table_info(");
                            v5_3.append(com.personal.aihub.CreatorActivity.identifier(v4_2));
                            v5_3.append(")");
                            android.database.Cursor v5_5 = v0_1.rawQuery(v5_3.toString(), 0);
                            try {
                                v1_1.put(v4_2, com.personal.aihub.CreatorActivity.rows(v5_5));
                            } catch (Throwable v1_2) {
                                if (v5_5 != null) {
                                    try {
                                        v5_5.close();
                                    } catch (Throwable v2_1) {
                                        v1_2.addSuppressed(v2_1);
                                    }
                                }
                                throw v1_2;
                            }
                            if (v5_5 != null) {
                                v5_5.close();
                            }
                        }
                    }
                } catch (Throwable v1_3) {
                    if (v3_1 != null) {
                        try {
                            v3_1.close();
                        } catch (Throwable v2_2) {
                            v1_3.addSuppressed(v2_2);
                        }
                    }
                    throw v1_3;
                }
                if (v3_1 != null) {
                    v3_1.close();
                }
                this.sparkingSchema = v1_1;
                this.sparkingDb = v0_1;
                return;
            } catch (Throwable v1_4) {
                v0_1.close();
                throw v1_4;
            }
        } else {
            return;
        }
    }

    private org.json.JSONObject expandCpkResources(java.io.File p25, int p26, long p27)
    {
        String v2_0 = " The original archive was kept.";
        Throwable v3_0 = ": ";
        Throwable v0_25 = new java.util.ArrayList();
        java.util.HashSet v4_1 = new java.util.HashSet();
        org.json.JSONArray v5_3 = new java.util.ArrayDeque();
        v5_3.add(p25);
        do {
            int v7_0 = 0;
            if (v5_3.isEmpty()) {
                org.json.JSONArray v5_1 = new org.json.JSONArray();
                long v8_4 = 4294967296;
                if (p27 > 4294967296) {
                    throw new java.io.IOException("Resource import exceeds 4 GB");
                } else {
                    String v6_4 = v0_25.iterator();
                    int v10_0 = p26;
                    long v11_0 = p27;
                    int v13 = 0;
                    while (v6_4.hasNext()) {
                        Throwable v0_29 = ((java.io.File) v6_4.next());
                        String v14_2 = p25.toURI().relativize(v0_29.toURI()).getPath();
                        try {
                            com.personal.aihub.CpkArchive v15_2 = new com.personal.aihub.CpkArchive(v0_29);
                            String v14_3 = v14_2.substring(v7_0, (v14_2.length() - 4));
                            java.util.Iterator v16 = v15_2.entries.iterator();
                        } catch (Throwable v0_2) {
                            String v19 = v6_4;
                            long v17 = v8_4;
                            String v6_7 = new StringBuilder();
                            v6_7.append(v14_3);
                            v6_7.append(v3_0);
                            v6_7.append(v0_2.getMessage());
                            v6_7.append(v2_0);
                            com.personal.aihub.CreatorActivity.cpkWarning(v5_1, v6_7.toString());
                            v8_4 = v17;
                            v6_4 = v19;
                            v7_0 = 0;
                        }
                        while (v16.hasNext()) {
                            Throwable v0_35 = ((com.personal.aihub.CpkArchive$Entry) v16.next());
                            int v7_2 = new StringBuilder();
                            v7_2.append(v14_3);
                            try {
                                v7_2.append("/");
                                v7_2.append(v0_35.path);
                                int v7_3 = v7_2.toString();
                                try {
                                    if (!com.personal.aihub.CreatorActivity.safePath(v7_3)) {
                                        v19 = v6_4;
                                        v17 = 4294967296;
                                        throw new java.io.IOException("Unsafe expanded CPK path");
                                    } else {
                                        long v8_1 = java.text.Normalizer.normalize(v7_3, java.text.Normalizer$Form.NFC).toLowerCase(java.util.Locale.ROOT);
                                        v19 = v6_4;
                                        if (v4_1.contains(v8_1)) {
                                            v17 = 4294967296;
                                            long v8_3 = new StringBuilder();
                                            v8_3.append("Imported resources have conflicting destinations: ");
                                            v8_3.append(v7_3);
                                            throw new java.io.IOException(v8_3.toString());
                                        } else {
                                            if (v10_0 >= 100000) {
                                                v17 = 4294967296;
                                            } else {
                                                String v20 = v2_0;
                                                String v21 = v3_0;
                                                v17 = 4294967296;
                                                v2_0 = ((long) v0_35.size) cmp (4294967296 - v11_0);
                                                if (v2_0 > null) {
                                                    v2_0 = v20;
                                                    v3_0 = v21;
                                                } else {
                                                    try {
                                                        Throwable v0_5 = v15_2.read(v0_35);
                                                    } catch (Throwable v0_6) {
                                                        String v2_2 = v0_6;
                                                        Throwable v0_8 = new StringBuilder();
                                                        v0_8.append(v7_3);
                                                        v3_0 = v21;
                                                        v0_8.append(v3_0);
                                                        v0_8.append(v2_2.getMessage());
                                                        v2_0 = v20;
                                                        v0_8.append(v2_0);
                                                        com.personal.aihub.CreatorActivity.cpkWarning(v5_1, v0_8.toString());
                                                        v8_4 = 4294967296;
                                                        v6_4 = v19;
                                                    }
                                                    String v2_5 = new java.io.File(p25, v7_3);
                                                    if (v2_5.exists()) {
                                                        String v2_7 = new StringBuilder();
                                                        v2_7.append("Imported resources have conflicting destinations: ");
                                                        v2_7.append(v7_3);
                                                        throw new java.io.IOException(v2_7.toString());
                                                    } else {
                                                        v2_5.getParentFile().mkdirs();
                                                        Throwable v3_4 = new java.io.FileOutputStream(v2_5);
                                                        try {
                                                            v3_4.write(v0_5);
                                                        } catch (Throwable v0_12) {
                                                            String v2_9 = v0_12;
                                                            try {
                                                                v3_4.close();
                                                            } catch (Throwable v0_13) {
                                                                v2_9.addSuppressed(v0_13);
                                                            }
                                                            throw v2_9;
                                                        }
                                                        v3_4.close();
                                                        v4_1.add(v8_1);
                                                        v11_0 += ((long) v0_5.length);
                                                        v10_0++;
                                                        v13++;
                                                        v8_4 = 4294967296;
                                                        v6_4 = v19;
                                                        v2_0 = v20;
                                                        v3_0 = v21;
                                                    }
                                                }
                                            }
                                            throw new java.io.IOException("Expanded CPK resources exceed the import limit");
                                        }
                                    }
                                } catch (Throwable v0_2) {
                                }
                            } catch (Throwable v0_2) {
                                v19 = v6_4;
                                v17 = 4294967296;
                            }
                        }
                        v19 = v6_4;
                        v17 = v8_4;
                    }
                    return new org.json.JSONObject().put("count", v10_0).put("bytes", v11_0).put("expanded", v13).put("warnings", v5_1);
                }
            } else {
                String v6_10 = ((java.io.File) v5_3.remove()).listFiles();
                if (v6_10 != null) {
                    long v8_5 = v6_10.length;
                }
            }
        } while(v7_0 >= v8_5);
        int v9_4 = v6_10[v7_0];
        if (!v9_4.isDirectory()) {
            v4_1.add(java.text.Normalizer.normalize(p25.toURI().relativize(v9_4.toURI()).getPath(), java.text.Normalizer$Form.NFC).toLowerCase(java.util.Locale.ROOT));
            if (v9_4.getName().toLowerCase(java.util.Locale.ROOT).endsWith(".cpk")) {
                v0_25.add(v9_4);
            }
        } else {
            v5_3.add(v9_4);
        }
        v7_0++;
        while (v7_0 < v8_5) {
        }
    }

    private java.io.File exportSource(org.json.JSONObject p5, java.io.File p6, int p7)
    {
        if (!p5.has("cpk")) {
            if (!p5.has("assetKey")) {
                return 0;
            } else {
                return this.assetFile(p5.getString("assetKey"));
            }
        } else {
            if ((!p5.getString("path").endsWith(".cpk")) || ((p5.has("assetKey")) || (p5.has("text")))) {
                throw new java.io.IOException("Invalid packed artwork entry.");
            } else {
                StringBuilder v2_2 = new StringBuilder();
                v2_2.append(String.valueOf(p7));
                v2_2.append(".cpk");
                java.io.File v1_8 = new java.io.File(p6, v2_2.toString());
                com.personal.aihub.CpkWriter.write(this.assets, p5.getJSONArray("cpk"), v1_8);
                return v1_8;
            }
        }
    }

    private String fetchText(String p5, int p6)
    {
        java.net.HttpURLConnection v5_1 = this.connection(p5);
        try {
            Throwable v0_1 = v5_1.getInputStream();
            try {
                Throwable v1_2 = new java.io.ByteArrayOutputStream();
            } catch (Throwable v6_3) {
                if (v0_1 != null) {
                    try {
                        v0_1.close();
                    } catch (Throwable v0_0) {
                        v6_3.addSuppressed(v0_0);
                    }
                }
                throw v6_3;
            }
            try {
                com.personal.aihub.CreatorActivity.copy(v0_1, v1_2, ((long) p6));
                Throwable v6_1 = v1_2.toString("UTF-8");
            } catch (Throwable v6_2) {
                try {
                    v1_2.close();
                } catch (Throwable v1_0) {
                    v6_2.addSuppressed(v1_0);
                }
                throw v6_2;
            }
            v1_2.close();
            if (v0_1 != null) {
                v0_1.close();
            }
            v5_1.disconnect();
            return v6_1;
        } catch (Throwable v6_4) {
            v5_1.disconnect();
            throw v6_4;
        }
    }

    private static boolean hasSparkingAnimations(org.json.JSONObject p1)
    {
        int v1_4;
        int v1_3 = p1.optJSONObject("sourceDependencies");
        if (v1_3 != 0) {
            v1_4 = v1_3.optJSONArray("animations");
        } else {
            v1_4 = 0;
        }
        if ((v1_4 == 0) || (v1_4.length() <= 0)) {
            int v1_2 = 0;
        } else {
            v1_2 = 1;
        }
        return v1_2;
    }

    private static String identifier(String p2)
    {
        if (!p2.matches("[a-zA-Z_][a-zA-Z0-9_]*")) {
            throw new java.io.IOException("Invalid database name");
        } else {
            String v0_1 = new StringBuilder("\"");
            v0_1.append(p2);
            v0_1.append("\"");
            return v0_1.toString();
        }
    }

    private org.json.JSONObject importArchive(java.io.File p18, String p19)
    {
        void v1 = this;
        java.io.IOException v0_15 = new StringBuilder("import-");
        v0_15.append(java.util.UUID.randomUUID());
        java.io.IOException v2_0 = this.assetFile(v0_15.toString());
        v2_0.mkdirs();
        java.io.IOException v0_6 = new java.util.HashSet();
        try {
            String v3_1 = new java.util.zip.ZipFile(p18);
            try {
                String v4_7 = v3_1.entries();
                long v6 = 0;
                Throwable v8 = 0;
                boolean v9_7 = 0;
                String v10_1 = 0;
            } catch (java.io.IOException v0_11) {
                String v4_5 = v0_11;
                try {
                    v3_1.close();
                } catch (java.io.IOException v0_12) {
                    v4_5.addSuppressed(v0_12);
                }
                throw v4_5;
            }
            while (v4_7.hasMoreElements()) {
                java.io.InputStream v11_3 = ((java.util.zip.ZipEntry) v4_7.nextElement());
                v10_1++;
                if (v10_1 > 100000) {
                    throw new java.io.IOException("Archive contains too many entries");
                } else {
                    if (!v11_3.isDirectory()) {
                        String v13_1 = v11_3.getName();
                        if (!com.personal.aihub.CreatorActivity.safePath(v13_1)) {
                            throw new java.io.IOException("Archive contains an unsafe file path");
                        } else {
                            boolean v14_2 = v13_1.matches("(?i).*\\.(db|sqlite|sqlite3)$");
                            if ((v14_2) || (v13_1.matches("(?i).*\\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$"))) {
                                boolean v9_8 = (v9_7 + 1);
                                if (v9_8 > 100000) {
                                    throw new java.io.IOException("Archive contains too many files");
                                } else {
                                    java.io.FileOutputStream v12_5;
                                    if (!v14_2) {
                                        v12_5 = com.personal.aihub.CreatorActivity.normalizeAsset(v13_1);
                                    } else {
                                        java.io.FileOutputStream v12_7 = new StringBuilder();
                                        v12_7.append("_databases/");
                                        v12_7.append(new java.io.File(v13_1).getName());
                                        v12_5 = v12_7.toString();
                                    }
                                    if (!v0_6.add(java.text.Normalizer.normalize(v12_5, java.text.Normalizer$Form.NFC).toLowerCase(java.util.Locale.ROOT))) {
                                        throw new java.io.IOException("Archive contains conflicting resource paths");
                                    } else {
                                        Throwable v5_4 = new java.io.File(v2_0, v12_5);
                                        v5_4.getParentFile().mkdirs();
                                        java.io.InputStream v11_0 = v3_1.getInputStream(v11_3);
                                        try {
                                            java.io.FileOutputStream v12_2 = new java.io.FileOutputStream(v5_4);
                                            int v16 = v9_8;
                                            int v15_2 = v10_1;
                                        } catch (java.io.IOException v0_7) {
                                            String v4_2 = v0_7;
                                            if (v11_0 != null) {
                                                try {
                                                    v11_0.close();
                                                } catch (java.io.IOException v0_8) {
                                                    v4_2.addSuppressed(v0_8);
                                                }
                                            }
                                            throw v4_2;
                                        }
                                        try {
                                            com.personal.aihub.CreatorActivity.copy(v11_0, v12_2, 1073741824);
                                        } catch (java.io.IOException v0_4) {
                                            String v4_1 = v0_4;
                                            try {
                                                v12_2.close();
                                            } catch (java.io.IOException v0_5) {
                                                v4_1.addSuppressed(v0_5);
                                            }
                                            throw v4_1;
                                        }
                                        v12_2.close();
                                        if (v11_0 != null) {
                                            v11_0.close();
                                        }
                                        v6 += v5_4.length();
                                        if (v6 > 4294967296) {
                                            throw new java.io.IOException("Resource import is larger than 4 GB");
                                        } else {
                                            try {
                                                if (v14_2) {
                                                    v1 = v1.verifyDb(v5_4);
                                                    if ((v8 == null) || (v13_1.toLowerCase(java.util.Locale.ROOT).contains("decrypted"))) {
                                                        v8 = v5_4;
                                                    }
                                                }
                                                v10_1 = v15_2;
                                                v9_7 = v16;
                                            } catch (Exception) {
                                            }
                                        }
                                    }
                                }
                            } else {
                            }
                        }
                    } else {
                    }
                }
            }
            v3_1.close();
            java.io.IOException v0_14 = v1.expandCpkResources(v2_0, v9_7, v6);
            if (v8 != null) {
                v1.useDb(v8, p19);
            }
            Throwable v5_7;
            org.json.JSONObject vtmp15 = v0_14.put("kind", "archive");
            if (v8 == null) {
                v5_7 = 0;
            } else {
                v5_7 = 1;
            }
            String v4_10;
            java.io.IOException v0_17 = vtmp15.put("database", v5_7);
            if (v8 == null) {
                v4_10 = "No readable game database found; the previous database was kept. Resource files were imported where available.";
            } else {
                v4_10 = "Readable game database imported.";
            }
            return v0_17.put("note", v4_10);
        } catch (java.io.IOException v0_13) {
            com.personal.aihub.CreatorActivity.deleteTree(v2_0);
            String v3_4 = new StringBuilder("Could not import this ZIP/APK. ");
            v3_4.append(v0_13.getMessage());
            throw new java.io.IOException(v3_4.toString(), v0_13);
        }
    }

    private org.json.JSONObject importEclipseApk(java.io.File p31, String p32)
    {
        int v10_0 = "bytes";
        boolean v12_9 = "apk";
        this.progress("inspect", "Checking Eclipse APK", 0, 0);
        long v13_0 = this.inspectEclipseApk(p31, p32);
        void v30_1 = this.ensureDb();
        String v1_9 = new StringBuilder("apk-");
        v1_9.append(java.util.UUID.randomUUID());
        boolean v14_0 = v1_9.toString();
        java.nio.charset.Charset v15 = this.assetFile(v14_0);
        String v1_26 = v30_1.getCacheDir();
        int v2_29 = new StringBuilder("apk-work-");
        v2_29.append(java.util.UUID.randomUUID());
        long v6_4 = new java.io.File(v1_26, v2_29.toString());
        v15.mkdirs();
        v6_4.mkdirs();
        try {
            java.io.IOException v0_29 = new java.util.HashMap();
            org.json.JSONObject v9_5 = new java.util.HashSet();
            long v16_1 = v6_4;
            java.nio.charset.Charset v17_2 = new java.util.ArrayList();
            try {
                v30_1.progress("extract", "Reading APK database and resources", 0, 0);
                String v1_33 = new java.util.zip.ZipFile(p31);
                try {
                    int v2_38 = v1_33.entries();
                    int v3_15 = 0;
                    long v6_5 = 0;
                    long v4_12 = 0;
                    int v5_5 = 0;
                } catch (java.io.IOException v0_30) {
                    java.nio.charset.Charset v17_0 = v15;
                    int v2_39 = v0_30;
                    try {
                        v1_33.close();
                    } catch (java.io.IOException v0_27) {
                        v2_39.addSuppressed(v0_27);
                    }
                    throw v2_39;
                } catch (java.io.IOException v0_9) {
                    com.personal.aihub.CreatorActivity.deleteTree(v17_0);
                    v30_1.progress("error", "Update failed; previous data and saved units were kept", 0, 0);
                    int v2_42 = new StringBuilder();
                    v2_42.append(String.valueOf(v0_9.getMessage()));
                    v2_42.append(" Your previous database and saved units were kept.");
                    throw new java.io.IOException(v2_42.toString(), v0_9);
                }
                while(true) {
                    int v31_1 = v5_5;
                    if (!v2_38.hasMoreElements()) {
                        boolean v27_1 = v12_9;
                        long v26_1 = v13_0;
                        boolean v23_1 = v14_0;
                        int v2_47 = v17_2;
                        boolean v14_11 = v10_0;
                        v1_33.close();
                        org.json.JSONObject v9_6 = this.expandCpkResources(v15, v3_15, v6_5);
                        int v10_1 = v9_6.getInt("count");
                        boolean v12_10 = v14_11;
                        long v13_10 = v9_6.getLong(v12_10);
                        v2_47.sort(new com.personal.aihub.CreatorActivity$10(this, v0_29));
                        String v1_36 = v2_47.iterator();
                        while (v1_36.hasNext()) {
                            int v2_1 = ((java.io.File) v1_36.next());
                            int v3_1 = new byte[16];
                            long v4_2 = new java.io.FileInputStream(v2_1);
                            try {
                                v4_2.read(v3_1);
                            } catch (java.io.IOException v0_1) {
                                String v1_1 = v0_1;
                                try {
                                    v4_2.close();
                                } catch (java.io.IOException v0_2) {
                                    v1_1.addSuppressed(v0_2);
                                }
                                throw v1_1;
                            }
                            v4_2.close();
                            if (new String(v3_1, java.nio.charset.StandardCharsets.UTF_8).equals("SQLite format 3\u0000")) {
                                this.verifyDb(v2_1, 1);
                            }
                            boolean v12_0;
                            java.io.IOException v0_4;
                            org.json.JSONObject v9_0;
                            int v19_0;
                            String v29;
                            org.json.JSONObject v24_0;
                            long v6_0 = v2_1;
                            org.json.JSONObject v7_0 = v26_1;
                            v7_0.put("resourceCount", v10_1);
                            int v5_1 = v27_1;
                            int v3_5 = new org.json.JSONObject().put(v5_1, v7_0).put("resourceGroup", v23_1);
                            if (v6_0 == 0) {
                                int v2_6;
                                v29 = "embedded";
                                java.io.IOException v0_3 = v3_5;
                                v24_0 = v9_6;
                                v19_0 = v12_10;
                                v17_0 = v15;
                                v15 = v5_1;
                                v9_0 = v7_0;
                                if (v31_1 == 0) {
                                    v2_6 = "not-included";
                                } else {
                                    v2_6 = "starter-or-encrypted";
                                }
                                v9_0.put("embeddedDatabase", v2_6);
                                v0_4 = this.downloadCurrentDatabase(v0_3);
                                v12_0 = "downloaded";
                            } else {
                                v7_0.put("embeddedDatabase", v0_29.get(v6_0));
                                v3_5.put("sourceType", "apk-embedded");
                                v29 = "embedded";
                                java.io.IOException v0_8 = v3_5;
                                v24_0 = v9_6;
                                v17_0 = v15;
                                v15 = v5_1;
                                v9_0 = v7_0;
                                v19_0 = v12_10;
                                boolean v12_1 = v6_0;
                                v30_1.progress("verify", "Validating the database inside the APK", 0, 0);
                                String v1_12 = new StringBuilder();
                                v1_12.append("Database inside ");
                                v1_12.append(p32);
                                v0_4 = this.useDb(v12_1, v1_12.toString(), v0_8);
                                v12_0 = "embedded";
                            }
                            int v2_23;
                            v30_1.progress("done", "Eclipse APK imported; game data ready", 0, 0);
                            int v3_9 = "expanded";
                            int v2_18 = v24_0;
                            int v3_10 = "warnings";
                            org.json.JSONObject vtmp63 = new org.json.JSONObject().put("kind", v15).put("database", 1).put("mode", v12_0).put(v15, v9_0).put("count", v10_1).put(v19_0, v13_10).put(v3_9, v2_18.getInt(v3_9)).put(v3_10, v2_18.getJSONArray(v3_10)).put("info", v0_4);
                            if (!v12_0.equals(v29)) {
                                v2_23 = "The APK contains starter or encrypted data. Eclipse\u2019s current full English database was downloaded and validated; saved units were kept.";
                            } else {
                                v2_23 = "APK database validated and activated. Saved units were kept.";
                            }
                            java.io.IOException v0_11 = vtmp63.put("note", v2_23);
                            com.personal.aihub.CreatorActivity.deleteTree(v16_1);
                            return v0_11;
                        }
                        v2_1 = 0;
                    } else {
                        try {
                            int v19_1 = v2_38;
                            int v2_25 = ((java.util.zip.ZipEntry) v2_38.nextElement());
                            long v4_8 = (v4_12 + 1);
                        } catch (java.io.IOException v0_26) {
                            v2_39 = v0_26;
                            v17_0 = v15;
                        }
                        if (v4_8 > 100000) {
                            break;
                        }
                        boolean v23_0;
                        long v22_2;
                        if (!v2_25.isDirectory()) {
                            int v5_4 = v2_25.getName();
                            if (!com.personal.aihub.CreatorActivity.safePath(v5_4)) {
                                throw new java.io.IOException("Unsafe APK file path");
                            } else {
                                v22_2 = v4_8;
                                long v4_10 = v5_4.matches("assets/(sqlite/current/en/database(_decrypted)?\\.db|database\\.db)");
                                if (v4_10 != 0) {
                                    v23_0 = v14_0;
                                } else {
                                    v23_0 = v14_0;
                                    if ((!v5_4.startsWith("assets/")) || ((v5_4.matches("assets/(patcher|dexopt|org)/.*")) || (!v5_4.matches("(?i).*\\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$")))) {
                                        v5_5 = v31_1;
                                        v2_38 = v19_1;
                                        v4_12 = v22_2;
                                        v14_0 = v23_0;
                                    }
                                }
                                boolean v14_7 = v12_9;
                                long v26_0 = v13_0;
                                if (v2_25.getSize() > 536870912) {
                                    throw new java.io.IOException("APK resource exceeds 512 MB");
                                } else {
                                    boolean v12_3;
                                    if (v4_10 == 0) {
                                        v12_3 = com.personal.aihub.CreatorActivity.normalizeAsset(v5_4);
                                    } else {
                                        boolean v12_5 = new StringBuilder();
                                        v12_5.append("database-");
                                        v12_5.append(v17_2.size());
                                        v12_5.append(".db");
                                        v12_3 = v12_5.toString();
                                    }
                                    boolean v27_0 = v14_7;
                                    if (!v9_5.add(java.text.Normalizer.normalize(v12_3, java.text.Normalizer$Form.NFC).toLowerCase(java.util.Locale.ROOT))) {
                                        throw new java.io.IOException("Conflicting APK resource paths");
                                    } else {
                                        boolean v14_9;
                                        if (v4_10 == 0) {
                                            v14_9 = v15;
                                        } else {
                                            v14_9 = v16_1;
                                        }
                                        long v13_9 = new java.io.File(v14_9, v12_3);
                                        v13_9.getParentFile().mkdirs();
                                        int v2_32 = v1_33.getInputStream(v2_25);
                                        try {
                                            boolean v12_8 = new java.io.FileOutputStream(v13_9);
                                            org.json.JSONObject v28 = v9_5;
                                            boolean v14_10 = v10_0;
                                        } catch (java.io.IOException v0_22) {
                                            int v3_14 = v0_22;
                                            if (v2_32 != 0) {
                                                try {
                                                    v2_32.close();
                                                } catch (java.io.IOException v0_23) {
                                                    v3_14.addSuppressed(v0_23);
                                                }
                                            }
                                            throw v3_14;
                                        }
                                        try {
                                            com.personal.aihub.CreatorActivity.copy(v2_32, v12_8, 536870912);
                                        } catch (java.io.IOException v0_20) {
                                            int v3_13 = v0_20;
                                            try {
                                                v12_8.close();
                                            } catch (java.io.IOException v0_21) {
                                                v3_13.addSuppressed(v0_21);
                                            }
                                            throw v3_13;
                                        }
                                        v12_8.close();
                                        if (v2_32 != 0) {
                                            v2_32.close();
                                        }
                                        v6_5 += v13_9.length();
                                        if (v6_5 > 4294967296) {
                                            throw new java.io.IOException("APK resources exceed 4 GB");
                                        } else {
                                            int v2_37;
                                            if (v4_10 == 0) {
                                                v2_37 = v17_2;
                                                v3_15++;
                                                v5_5 = v31_1;
                                            } else {
                                                v2_37 = v17_2;
                                                v2_37.add(v13_9);
                                                v0_29.put(v13_9, v5_4);
                                                v5_5 = 1;
                                            }
                                            v17_2 = v2_37;
                                            v10_0 = v14_10;
                                            v2_38 = v19_1;
                                            v4_12 = v22_2;
                                            v14_0 = v23_0;
                                            v13_0 = v26_0;
                                            v12_9 = v27_0;
                                            v9_5 = v28;
                                        }
                                    }
                                }
                            }
                        } else {
                            v22_2 = v4_8;
                            v23_0 = v14_0;
                        }
                    }
                }
                throw new java.io.IOException("Too many APK entries");
            } catch (java.io.IOException v0_9) {
                v17_0 = v15;
            }
        } catch (java.io.IOException v0_9) {
            v16_1 = 0;
        } catch (java.io.IOException v0_28) {
            v16_1 = 0;
            com.personal.aihub.CreatorActivity.deleteTree(v16_1);
            throw v0_28;
        } catch (java.io.IOException v0_28) {
        }
    }

    private org.json.JSONObject importEclp(java.io.File p20, String p21)
    {
        String v4_2 = java.util.UUID.randomUUID().toString();
        java.io.File v5_0 = new StringBuilder("patch-");
        v5_0.append(v4_2);
        java.io.File v5_2 = this.assetFile(v5_0.toString());
        v5_2.mkdirs();
        String v12_0 = this.patchFile(v4_2);
        com.personal.aihub.CreatorActivity v6_1 = v12_0.getParentFile();
        String v7_3 = new StringBuilder();
        v7_3.append(v4_2);
        v7_3.append(".json");
        String v13_1 = new java.io.File(v6_1, v7_3.toString());
        try {
            org.json.JSONObject v14_1 = new org.json.JSONObject(com.personal.aihub.EclpCodec.header(p20).metadata);
            com.personal.aihub.CreatorActivity v6_8 = com.personal.aihub.EclpCodec.extract(p20, v5_2, this.getCacheDir(), v14_1.getString("uuid"), v14_1.getString("name"), v14_1.getString("version"));
            String v7_7 = new org.json.JSONArray();
            String v8_4 = v6_8.iterator();
            String v9_6 = 0;
            try {
                while (v8_4.hasNext()) {
                    Object v11_2 = ((com.personal.aihub.EclpCodec$Entry) v8_4.next());
                    java.util.Iterator v16 = v8_4;
                    String v17 = v12_0;
                    String v18 = v13_1;
                    v7_7.put(new org.json.JSONObject().put("path", v11_2.path).put("size", v11_2.file.length()));
                    v9_6 += v11_2.file.length();
                    v8_4 = v16;
                    v12_0 = v17;
                    v13_1 = v18;
                }
            } catch (org.json.JSONObject v0_13) {
                String v3_8 = v17;
                String v4_0 = v18;
                com.personal.aihub.CreatorActivity.deleteTree(v5_2);
                v3_8.delete();
                v4_0.delete();
                throw v0_13;
            }
            Object v11_0;
            long v15_0;
            v17 = v12_0;
            v18 = v13_1;
            String v1_29 = new java.io.File(v5_2, "forge-project.json");
            String v8_7 = com.personal.aihub.CreatorActivity.isoStamp();
            if (!v1_29.isFile()) {
                v15_0 = v9_6;
                v11_0 = 0;
            } else {
                v11_0 = new org.json.JSONObject(com.personal.aihub.CreatorActivity.readText(v1_29, 20971520));
                if ((!v11_0.optString("format").equals("dokkan-unit-forge")) || ((v11_0.optInt("version") != 1) || (v11_0.getJSONObject("tables").getJSONArray("cards").length() != 1))) {
                    throw new java.io.IOException("Invalid embedded unit project");
                } else {
                    String v1_3 = new StringBuilder();
                    v1_3.append("unit-");
                    v15_0 = v9_6;
                    v1_3.append(v11_0.getLong("targetId"));
                    v1_3.append("-");
                    v1_3.append(v4_2);
                    v11_0.put("key", v1_3.toString());
                    v11_0.put("libraryOrigin", "uploaded");
                    v11_0.put("provenance", new org.json.JSONObject().put("file", p21).put("patchKey", v4_2).put("author", v14_1.optString("author")).put("importedAt", v8_7));
                    com.personal.aihub.ProjectFormsData.restore(v11_0, v4_2, v5_2);
                }
            }
            String v2_5;
            org.json.JSONObject v0_7 = new org.json.JSONObject().put("key", v4_2).put("metadata", v14_1).put("filename", p21).put("importedAt", v8_7).put("count", v6_8.size()).put("bytes", v15_0).put("entries", v7_7);
            if (v11_0 != null) {
                v2_5 = v11_0.getString("key");
            } else {
                v2_5 = org.json.JSONObject.NULL;
            }
            org.json.JSONObject v0_8 = v0_7.put("projectKey", v2_5);
            String v1_16 = new java.io.FileInputStream(p20);
            try {
                v3_8 = v17;
                try {
                    String v2_8 = new java.io.FileOutputStream(v3_8);
                    try {
                        com.personal.aihub.CreatorActivity.copy(v1_16, v2_8, 4294967296);
                    } catch (org.json.JSONObject v0_10) {
                        v4_0 = v18;
                        String v7_0 = v0_10;
                        try {
                            v2_8.close();
                        } catch (org.json.JSONObject v0_11) {
                            v7_0.addSuppressed(v0_11);
                        } catch (org.json.JSONObject v0_9) {
                            String v2_10 = v0_9;
                            try {
                                v1_16.close();
                            } catch (org.json.JSONObject v0_12) {
                                v2_10.addSuppressed(v0_12);
                            }
                            throw v2_10;
                        }
                        throw v7_0;
                    }
                    v2_8.close();
                    try {
                        v1_16.close();
                        v4_0 = v18;
                        try {
                            com.personal.aihub.CreatorActivity.writeText(v4_0, v0_8.toString());
                        } catch (org.json.JSONObject v0_13) {
                        }
                        if (v11_0 == null) {
                        } else {
                            this.saveProject(v11_0);
                        }
                        String v9_5;
                        String v1_20 = new org.json.JSONObject();
                        if (v11_0 != null) {
                            v9_5 = "project";
                        } else {
                            v9_5 = "patch";
                        }
                        String v1_21 = v1_20.put("kind", v9_5);
                        if (v11_0 == null) {
                            v11_0 = org.json.JSONObject.NULL;
                        }
                        return v1_21.put("project", v11_0).put("patch", v0_8).put("note", "ECLP authenticated and added to Library. SQL stays inside the patch and is never executed by this app.");
                    } catch (org.json.JSONObject v0_13) {
                    }
                } catch (org.json.JSONObject v0_9) {
                    v4_0 = v18;
                }
            } catch (org.json.JSONObject v0_9) {
                v3_8 = v17;
            } catch (org.json.JSONObject v0_13) {
            }
        } catch (org.json.JSONObject v0_13) {
            v3_8 = v12_0;
            v4_0 = v13_1;
        }
    }

    private org.json.JSONObject importPatchZip(java.io.File p17, String p18)
    {
        Throwable v1_1 = new java.util.zip.ZipFile(p17);
        try {
            java.io.IOException v0_26 = v1_1.getEntry("metadata.json");
        } catch (java.io.IOException v0_15) {
            String v2_9 = v0_15;
            try {
                v1_1.close();
            } catch (java.io.IOException v0_19) {
                v2_9.addSuppressed(v0_19);
            }
            throw v2_9;
        }
        if (v0_26 != null) {
            Throwable v3_4 = v1_1.entries();
            Throwable v4_0 = 0;
            com.personal.aihub.CreatorActivity v5_1 = 0;
            while (v3_4.hasMoreElements()) {
                String v6_2 = v3_4.nextElement();
                v5_1++;
                if (v5_1 > 100000) {
                    throw new java.io.IOException("Too many ZIP entries");
                } else {
                    if (((java.util.zip.ZipEntry) v6_2).getName().matches("(?i)files/.*\\.sql")) {
                        v4_0 = 1;
                    }
                }
            }
            if (v4_0 != null) {
                Throwable v3_0 = v1_1.getInputStream(v0_26);
                try {
                    Throwable v4_5 = new java.io.ByteArrayOutputStream();
                    try {
                        com.personal.aihub.CreatorActivity.copy(v3_0, v4_5, 4194304);
                        java.io.IOException v0_20 = new org.json.JSONObject(v4_5.toString("UTF-8"));
                    } catch (java.io.IOException v0_21) {
                        String v2_10 = v0_21;
                        try {
                            v4_5.close();
                        } catch (java.io.IOException v0_23) {
                            v2_10.addSuppressed(v0_23);
                        } catch (java.io.IOException v0_24) {
                            String v2_11 = v0_24;
                            if (v3_0 != null) {
                                try {
                                    v3_0.close();
                                } catch (java.io.IOException v0_25) {
                                    v2_11.addSuppressed(v0_25);
                                }
                            }
                            throw v2_11;
                        }
                        throw v2_10;
                    }
                    v4_5.close();
                    if (v3_0 != null) {
                        v3_0.close();
                    }
                    Throwable v4_7 = this.getCacheDir();
                    com.personal.aihub.CreatorActivity v5_7 = new StringBuilder();
                    v5_7.append("forge-zip-");
                    v5_7.append(java.util.UUID.randomUUID());
                    Throwable v3_3 = new java.io.File(v4_7, v5_7.toString());
                    Throwable v4_9 = new java.io.File(v3_3, "converted.eclp");
                    v3_3.mkdirs();
                    try {
                        java.util.ArrayList v8_3 = new java.util.ArrayList();
                        com.personal.aihub.CreatorActivity v5_11 = new java.util.HashSet();
                        String v6_8 = v1_1.entries();
                        long v9_0 = 0;
                    } catch (java.io.IOException v0_6) {
                        com.personal.aihub.CreatorActivity.deleteTree(v3_3);
                        throw v0_6;
                    }
                    while (v6_8.hasMoreElements()) {
                        String v7_1 = ((java.util.zip.ZipEntry) v6_8.nextElement());
                        if (!v7_1.isDirectory()) {
                            if ((!com.personal.aihub.CreatorActivity.safePath(v7_1.getName())) || (!v5_11.add(v7_1.getName()))) {
                                throw new java.io.IOException("Unsafe or duplicate ZIP patch path");
                            } else {
                                com.personal.aihub.EclpCodec$Entry v12_1 = new StringBuilder();
                                v12_1.append("files/");
                                v12_1.append(v7_1.getName());
                                java.io.File v11_6 = new java.io.File(v3_3, v12_1.toString());
                                v11_6.getParentFile().mkdirs();
                                com.personal.aihub.EclpCodec$Entry v12_4 = v1_1.getInputStream(v7_1);
                                try {
                                    java.io.FileOutputStream v13_3 = new java.io.FileOutputStream(v11_6);
                                } catch (java.io.IOException v0_11) {
                                    String v2_6 = v0_11;
                                    if (v12_4 != null) {
                                        try {
                                            v12_4.close();
                                        } catch (java.io.IOException v0_12) {
                                            v2_6.addSuppressed(v0_12);
                                        }
                                    }
                                    throw v2_6;
                                }
                                try {
                                    com.personal.aihub.CreatorActivity.copy(v12_4, v13_3, 536870912);
                                } catch (java.io.IOException v0_9) {
                                    String v2_5 = v0_9;
                                    try {
                                        v13_3.close();
                                    } catch (java.io.IOException v0_10) {
                                        v2_5.addSuppressed(v0_10);
                                    }
                                    throw v2_5;
                                }
                                v13_3.close();
                                if (v12_4 != null) {
                                    v12_4.close();
                                }
                                v9_0 += v11_6.length();
                                if (v9_0 > 4294967296) {
                                    throw new java.io.IOException("Patch ZIP too large");
                                } else {
                                    v8_3.add(new com.personal.aihub.EclpCodec$Entry(v7_1.getName(), v11_6, 0));
                                }
                            }
                        } else {
                        }
                    }
                    String v2_14 = new java.io.FileOutputStream(v4_9);
                    try {
                        com.personal.aihub.EclpCodec.write(v2_14, this.getCacheDir(), v8_3, v0_20.toString(), v0_20.getString("uuid"), v0_20.getString("name"), v0_20.getString("version"));
                    } catch (java.io.IOException v0_27) {
                        Throwable v4_10 = v0_27;
                        try {
                            v2_14.close();
                        } catch (java.io.IOException v0_28) {
                            v4_10.addSuppressed(v0_28);
                        }
                        throw v4_10;
                    } catch (java.io.IOException v0_6) {
                    }
                    v2_14.close();
                    java.io.IOException v0_2 = new StringBuilder();
                    v0_2.append(p18.replaceFirst("(?i)\\.zip$", ""));
                    v0_2.append(".eclp");
                    java.io.IOException v0_5 = this.importEclp(v4_9, v0_2.toString()).put("note", "Patch ZIP converted to ECLP locally and added to Library.");
                    com.personal.aihub.CreatorActivity.deleteTree(v3_3);
                    v1_1.close();
                    return v0_5;
                } catch (java.io.IOException v0_24) {
                } catch (java.io.IOException v0_15) {
                }
            } else {
                v1_1.close();
                return 0;
            }
        } else {
            v1_1.close();
            return 0;
        }
    }

    private org.json.JSONObject importSparkingApk(java.io.File p13, String p14)
    {
        this.progress("inspect", "Reading Sparking resources and patch format", 0, 0);
        byte[] v0_1 = com.personal.aihub.SprkCodec.keyFromApk(p13);
        byte[] v1_0 = com.personal.aihub.SprkCodec.databaseKeyFromApk(p13).getBytes(java.nio.charset.StandardCharsets.US_ASCII);
        try {
            Throwable v13_1 = this.importArchive(p13, p14);
            this.saveFormatKey(this.sparkingFormatKey(), v0_1);
            this.saveFormatKey(this.sparkingDatabaseKey(), v1_0);
            v13_1.put("sourceFormat", "sparking-apk").put("formatKeyConfigured", 1).put("note", "Sparking import is ready. Browse the included characters in Library \u2192 Sparking, or choose Update characters for current game data. You can also import supported .sprk patches and save ECLP from Library. Artwork and other game resources download separately.");
            this.progress("done", "Sparking import ready", 0, 0);
            java.util.Arrays.fill(v0_1, 0);
            java.util.Arrays.fill(v1_0, 0);
            return v13_1;
        } catch (Throwable v13_2) {
            java.util.Arrays.fill(v0_1, 0);
            java.util.Arrays.fill(v1_0, 0);
            throw v13_2;
        }
    }

    private org.json.JSONObject importSparkingPatch(java.io.File p11, String p12)
    {
        java.io.File v0_0 = this.sparkingFormatKey();
        if ((!v0_0.isFile()) || (v0_0.length() != 32)) {
            throw new java.io.IOException("First choose Import file and select the original Sparking 6.5.5 APK or its ZIP. Then import your .sprk patch here.");
        } else {
            byte[] v1_1 = new byte[32];
            int v2_1 = new java.io.DataInputStream(new java.io.FileInputStream(v0_0));
            try {
                v2_1.readFully(v1_1);
                v2_1.close();
                int v2_2 = this.getCacheDir();
                String v3_3 = new StringBuilder("sparking-");
                v3_3.append(java.util.UUID.randomUUID());
                java.io.File v0_2 = new java.io.File(v2_2, v3_3.toString());
                int v2_3 = v0_2.mkdir();
            } catch (Throwable v11_3) {
                try {
                    v2_3.close();
                } catch (Throwable v12_2) {
                    v11_3.addSuppressed(v12_2);
                }
                throw v11_3;
            }
            if (v2_3 == 0) {
                throw new java.io.IOException("Could not prepare Sparking conversion.");
            } else {
                try {
                    this.progress("convert", "Opening Sparking patch", 0, 0);
                    String v3_7 = new java.io.File(v0_2, "decoded.zip");
                    java.io.File v4_5 = new java.io.File(v0_2, "converted.eclp");
                    com.personal.aihub.SprkCodec.decode(p11, v3_7, v1_1);
                    com.personal.aihub.SprkEclp.convert(v3_7, v0_2, v4_5, this.getCacheDir(), p12);
                    Throwable v11_8 = new StringBuilder();
                    v11_8.append(p12.replaceFirst("(?i)\\.sprk$", ""));
                    v11_8.append(".eclp");
                    Throwable v11_12 = this.importEclp(v4_5, v11_8.toString()).put("sourceFormat", "sparking-sprk").put("note", "Sparking patch converted and added to the Sparking category in Library. Save ECLP to install it in Eclipse. Format conversion does not verify its SQL or gameplay compatibility; the original creator metadata was preserved.");
                    java.util.Arrays.fill(v1_1, 0);
                    com.personal.aihub.CreatorActivity.deleteTree(v0_2);
                    return v11_12;
                } catch (Throwable v11_13) {
                    java.util.Arrays.fill(v1_1, 0);
                    com.personal.aihub.CreatorActivity.deleteTree(v0_2);
                    throw v11_13;
                }
            }
        }
    }

    private org.json.JSONObject importUri(android.net.Uri p2)
    {
        return this.importUri(p2, 0);
    }

    private org.json.JSONObject importUri(android.net.Uri p12, boolean p13)
    {
        String v5_6;
        java.io.File v3_0 = this.getContentResolver().query(p12, new String[] {"_display_name"}), 0, 0, 0);
        try {
            if ((v3_0 == null) || (!v3_0.moveToFirst())) {
                v5_6 = "import";
            } else {
                v5_6 = v3_0.getString(0);
            }
        } catch (org.json.JSONObject v12_23) {
            if (v3_0 == null) {
                throw v12_23;
            } else {
                try {
                    v3_0.close();
                } catch (org.json.JSONObject v13_9) {
                    v12_23.addSuppressed(v13_9);
                }
            }
        }
        if (v3_0 != null) {
            v3_0.close();
        }
        int v9_4;
        String v6_2 = this.getCacheDir();
        long v7_5 = new StringBuilder("forge-import-");
        v7_5.append(System.currentTimeMillis());
        if ((p13 == null) && (!v5_6.toLowerCase(java.util.Locale.ROOT).endsWith(".apk"))) {
            v9_4 = "";
        } else {
            v9_4 = ".apk";
        }
        v7_5.append(v9_4);
        java.io.File v3_3 = new java.io.File(v6_2, v7_5.toString());
        try {
            org.json.JSONObject v12_41 = this.getContentResolver().openInputStream(p12);
            try {
                String v6_5 = new java.io.FileOutputStream(v3_3);
            } catch (org.json.JSONObject v13_27) {
                if (v12_41 != null) {
                    try {
                        v12_41.close();
                    } catch (org.json.JSONObject v12_42) {
                        v13_27.addSuppressed(v12_42);
                    }
                }
                throw v13_27;
            }
            try {
                if (v12_41 == null) {
                    throw new java.io.IOException("Cannot read selected file");
                } else {
                    com.personal.aihub.CreatorActivity.copy(v12_41, v6_5, 4294967296);
                    v6_5.close();
                    if (v12_41 != null) {
                        v12_41.close();
                    }
                    if (p13 == null) {
                        if (v5_6.toLowerCase(java.util.Locale.ROOT).endsWith(".apk")) {
                            org.json.JSONObject v12_47 = this.getPackageManager().getPackageArchiveInfo(v3_3.getPath(), 0);
                            if ((v12_47 == null) || (!"com.sparkingDokkan.GLB".equals(v12_47.packageName))) {
                                org.json.JSONObject v12_1 = new java.util.zip.ZipFile(v3_3);
                                try {
                                    if (v12_1.getEntry("assets/patcher/maps/android_current.json") == null) {
                                        v12_1.close();
                                    } else {
                                        org.json.JSONObject v13_22 = this.importEclipseApk(v3_3, v5_6);
                                        v12_1.close();
                                        v3_3.delete();
                                        return v13_22;
                                    }
                                } catch (org.json.JSONObject v13_23) {
                                    try {
                                        v12_1.close();
                                    } catch (org.json.JSONObject v12_37) {
                                        v13_23.addSuppressed(v12_37);
                                    }
                                    throw v13_23;
                                }
                            } else {
                                org.json.JSONObject v12_39 = this.importSparkingApk(v3_3, v5_6);
                                v3_3.delete();
                                return v12_39;
                            }
                        }
                        if (!v5_6.toLowerCase(java.util.Locale.ROOT).endsWith(".json")) {
                            org.json.JSONObject v12_6 = new byte[16];
                            Throwable v0_2 = new java.io.FileInputStream(v3_3);
                            try {
                                v0_2.read(v12_6);
                            } catch (org.json.JSONObject v12_7) {
                                try {
                                    v0_2.close();
                                } catch (org.json.JSONObject v13_5) {
                                    v12_7.addSuppressed(v13_5);
                                }
                                throw v12_7;
                            }
                            v0_2.close();
                            Throwable v0_3 = v12_6[0];
                            if ((v0_3 != 69) || ((v12_6[1] != 67) || ((v12_6[2] != 76) || (v12_6[3] != 80)))) {
                                if ((v0_3 != 83) || ((v12_6[1] != 80) || ((v12_6[2] != 82) || (v12_6[3] != 75)))) {
                                    if (!new String(v12_6, java.nio.charset.StandardCharsets.UTF_8).equals("SQLite format 3\u0000")) {
                                        if (v5_6.matches("(?i).*\\.zip$")) {
                                            org.json.JSONObject v12_12 = this.importWrappedApk(v3_3, v5_6);
                                            if (v12_12 == null) {
                                                org.json.JSONObject v12_13 = this.importPatchZip(v3_3, v5_6);
                                                if (v12_13 != null) {
                                                    v3_3.delete();
                                                    return v12_13;
                                                }
                                            } else {
                                                v3_3.delete();
                                                return v12_12;
                                            }
                                        }
                                        if (!v5_6.matches("(?i).*\\.(zip|apk|apks|ipa|eclp)$")) {
                                            if (!v5_6.matches("(?i).*\\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|m4a|aac|flac|awb|acb|atlas|plist|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$")) {
                                                throw new java.io.IOException("Choose a unit JSON, ECLP or SPRK patch, readable SQLite database, image, ZIP, or APK archive.");
                                            } else {
                                                org.json.JSONObject v12_21 = new StringBuilder("import-");
                                                v12_21.append(java.util.UUID.randomUUID());
                                                org.json.JSONObject v12_22 = v12_21.toString();
                                                Throwable v0_11 = new StringBuilder();
                                                v0_11.append(v12_22);
                                                v0_11.append("/");
                                                v0_11.append(new java.io.File(v5_6).getName());
                                                Throwable v0_12 = v0_11.toString();
                                                boolean v1_5 = this.assetFile(v0_12);
                                                org.json.JSONObject v12_24 = this.assetFile(v12_22);
                                                v1_5.getParentFile().mkdirs();
                                                try {
                                                    org.json.JSONObject v2_11 = new java.io.FileInputStream(v3_3);
                                                    try {
                                                        String v4_4 = new java.io.FileOutputStream(v1_5);
                                                        try {
                                                            com.personal.aihub.CreatorActivity.copy(v2_11, v4_4, 1073741824);
                                                        } catch (org.json.JSONObject v13_7) {
                                                            try {
                                                                v4_4.close();
                                                            } catch (Throwable v0_13) {
                                                                v13_7.addSuppressed(v0_13);
                                                            }
                                                            throw v13_7;
                                                        }
                                                        v4_4.close();
                                                        v2_11.close();
                                                        v12_24 = this.expandCpkResources(v12_24, 1, v1_5.length()).put("kind", "assets").put("asset", new org.json.JSONObject().put("key", v0_12).put("path", v1_5.getName()).put("name", v1_5.getName()).put("size", v1_5.length()).put("image", v1_5.getName().matches("(?i).*\\.(png|jpe?g|webp|gif|bmp)$")));
                                                        v3_3.delete();
                                                        return v12_24;
                                                    } catch (org.json.JSONObject v13_8) {
                                                        try {
                                                            v2_11.close();
                                                        } catch (Throwable v0_14) {
                                                            v13_8.addSuppressed(v0_14);
                                                        }
                                                        throw v13_8;
                                                    }
                                                } catch (org.json.JSONObject v13_15) {
                                                    com.personal.aihub.CreatorActivity.deleteTree(v12_24);
                                                    throw v13_15;
                                                }
                                            }
                                        } else {
                                            org.json.JSONObject v12_25 = this.importArchive(v3_3, v5_6);
                                            v3_3.delete();
                                            return v12_25;
                                        }
                                    } else {
                                        org.json.JSONObject v12_29 = new org.json.JSONObject().put("kind", "database").put("info", this.useDb(v3_3, v5_6));
                                        v3_3.delete();
                                        return v12_29;
                                    }
                                } else {
                                    org.json.JSONObject v12_30 = this.importSparkingPatch(v3_3, v5_6);
                                    v3_3.delete();
                                    return v12_30;
                                }
                            } else {
                                org.json.JSONObject v12_31 = this.importEclp(v3_3, v5_6);
                                v3_3.delete();
                                return v12_31;
                            }
                        } else {
                            org.json.JSONObject v12_33 = new org.json.JSONObject(com.personal.aihub.CreatorActivity.readText(v3_3, 20971520));
                            if (!v12_33.optString("format").equals("dokkan-unit-forge")) {
                                throw new java.io.IOException("This JSON is not a Dokkan Unit Creator project. Use a SQLite database for game data.");
                            } else {
                                v12_33.put("libraryOrigin", "uploaded");
                                v12_33.put("provenance", new org.json.JSONObject().put("file", v5_6).put("importedAt", com.personal.aihub.CreatorActivity.isoStamp()));
                                boolean v1_16 = new StringBuilder("unit-");
                                v1_16.append(v12_33.getLong("targetId"));
                                v1_16.append("-");
                                v1_16.append(System.currentTimeMillis());
                                v12_33.put("key", v1_16.toString());
                                this.saveProject(v12_33);
                                org.json.JSONObject v12_36 = new org.json.JSONObject().put("kind", "project").put("project", v12_33);
                                v3_3.delete();
                                return v12_36;
                            }
                        }
                    } else {
                        org.json.JSONObject v12_40 = this.importEclipseApk(v3_3, v5_6);
                        v3_3.delete();
                        return v12_40;
                    }
                }
            } catch (org.json.JSONObject v13_26) {
                try {
                    v6_5.close();
                } catch (Throwable v0_21) {
                    v13_26.addSuppressed(v0_21);
                }
                throw v13_26;
            }
        } catch (org.json.JSONObject v12_38) {
            v3_3.delete();
            throw v12_38;
        }
    }

    private org.json.JSONObject importWrappedApk(java.io.File p12, String p13)
    {
        java.util.zip.ZipFile v0_1 = new java.util.zip.ZipFile(p12);
        try {
            java.io.IOException v12_10 = v0_1.entries();
            java.util.zip.ZipEntry v4 = 0;
            String v3_0 = 0;
            long v5_0 = 0;
        } catch (java.io.IOException v12_5) {
            try {
                v0_1.close();
            } catch (org.json.JSONObject v13_6) {
                v12_5.addSuppressed(v13_6);
            }
            throw v12_5;
        }
        while (v12_10.hasMoreElements()) {
            java.util.zip.ZipEntry v6_2 = ((java.util.zip.ZipEntry) v12_10.nextElement());
            v5_0++;
            if (v5_0 > 100000) {
                throw new java.io.IOException("Too many ZIP entries");
            } else {
                String v8_3;
                if (!v6_2.isDirectory()) {
                    v8_3 = v6_2.getName();
                } else {
                    v8_3 = v6_2.getName().replaceFirst("/$", "");
                }
                if (!com.personal.aihub.CreatorActivity.safePath(v8_3)) {
                    throw new java.io.IOException("Unsafe ZIP path");
                } else {
                    if (!v6_2.isDirectory()) {
                        v3_0++;
                        if (v6_2.getName().toLowerCase(java.util.Locale.ROOT).endsWith(".apk")) {
                            v4 = v6_2;
                        }
                    } else {
                    }
                }
            }
        }
        if (v3_0 == 1) {
            if (v4 != null) {
                if (v4.getSize() > 536870912) {
                    throw new java.io.IOException("The APK inside this ZIP exceeds 512 MB.");
                } else {
                    boolean v1_0 = this.getCacheDir();
                    String v3_2 = new StringBuilder();
                    v3_2.append("wrapped-");
                    v3_2.append(java.util.UUID.randomUUID());
                    v3_2.append(".apk");
                    java.io.IOException v12_11 = new java.io.File(v1_0, v3_2.toString());
                    try {
                        boolean v1_3 = new java.util.zip.CRC32();
                        String v3_5 = new java.util.zip.CheckedInputStream(v0_1.getInputStream(v4), v1_3);
                        try {
                            long v5_6 = new java.io.FileOutputStream(v12_11);
                            try {
                                com.personal.aihub.CreatorActivity.copy(v3_5, v5_6, 536870912);
                            } catch (org.json.JSONObject v13_8) {
                                try {
                                    v5_6.close();
                                } catch (boolean v1_4) {
                                    v13_8.addSuppressed(v1_4);
                                }
                                throw v13_8;
                            }
                            v5_6.close();
                            v3_5.close();
                            if ((v12_11.length() != v4.getSize()) || (v1_3.getValue() != v4.getCrc())) {
                                throw new java.io.IOException("The APK inside this ZIP is incomplete or corrupted. Download the original ZIP again.");
                            } else {
                                boolean v1_9 = this.getPackageManager().getPackageArchiveInfo(v12_11.getPath(), 0);
                                if ((!v1_9) || (!"com.sparkingDokkan.GLB".equals(v1_9.packageName))) {
                                    if ((!v1_9) || (!"com.anthen.eclipse".equals(v1_9.packageName))) {
                                        org.json.JSONObject v13_12 = this.importArchive(v12_11, p13);
                                        v12_11.delete();
                                        v0_1.close();
                                        return v13_12;
                                    } else {
                                        org.json.JSONObject v13_1 = this.importEclipseApk(v12_11, p13);
                                        v12_11.delete();
                                        v0_1.close();
                                        return v13_1;
                                    }
                                } else {
                                    org.json.JSONObject v13_2 = this.importSparkingApk(v12_11, p13);
                                    v12_11.delete();
                                    v0_1.close();
                                    return v13_2;
                                }
                            }
                        } catch (org.json.JSONObject v13_9) {
                            try {
                                v3_5.close();
                            } catch (boolean v1_5) {
                                v13_9.addSuppressed(v1_5);
                            }
                            throw v13_9;
                        }
                    } catch (org.json.JSONObject v13_3) {
                        v12_11.delete();
                        throw v13_3;
                    }
                }
            } else {
            }
        }
        v0_1.close();
        return 0;
    }

    private org.json.JSONObject info()
    {
        this.ensureDb();
        org.json.JSONObject v0_2 = this.dataStore().state();
        android.database.Cursor v1_1 = this.db.rawQuery("SELECT count(*) FROM cards", 0);
        try {
            v1_1.moveToFirst();
            int v2_0 = 0;
            org.json.JSONObject v3_0 = v1_1.getLong(0);
        } catch (org.json.JSONObject v0_3) {
            if (v1_1 != null) {
                v1_1.close();
                throw v0_3;
            } else {
                throw v0_3;
            }
            return org.json.JSONObject v3_2.put("database", org.json.JSONObject v4_2.put("canRestore", v2_0));
        }
        if (v1_1 != null) {
            v1_1.close();
        }
        v3_2 = new org.json.JSONObject().put("schema", this.schema).put("count", v3_0).put("meta", this.dataStore().meta());
        v4_2 = new org.json.JSONObject();
        if ((v0_2 != null) && (v0_2.optJSONObject("previous") != null)) {
            v2_0 = 1;
        }
        return v3_2.put("database", v4_2.put("canRestore", v2_0));
    }

    private org.json.JSONObject inspectEclipseApk(java.io.File p10, String p11)
    {
        String v0_3 = this.getPackageManager().getPackageArchiveInfo(p10.getPath(), 0);
        if ((v0_3 == null) || (!"com.anthen.eclipse".equals(v0_3.packageName))) {
            throw new java.io.IOException("Choose the Eclipse Android APK (com.anthen.eclipse). The selected app was not installed or run.");
        } else {
            String v1_3 = new java.util.zip.ZipFile(p10);
            try {
                Object v3_2;
                Object v3_1 = v1_3.getEntry("assets/patcher/maps/android_current.json");
                long v4_0 = "";
            } catch (org.json.JSONObject v10_8) {
                try {
                    v1_3.close();
                } catch (org.json.JSONObject v11_5) {
                    v10_8.addSuppressed(v11_5);
                }
                throw v10_8;
            }
            if (v3_1 == null) {
                v3_2 = "";
            } else {
                if (v3_1.getSize() > 8388608) {
                    throw new java.io.IOException("APK version map too large");
                } else {
                    String v5_3 = new android.util.JsonReader(new java.io.InputStreamReader(v1_3.getInputStream(v3_1), java.nio.charset.StandardCharsets.UTF_8));
                    try {
                        v5_3.beginObject();
                    } catch (org.json.JSONObject v10_7) {
                        try {
                            v5_3.close();
                        } catch (org.json.JSONObject v11_4) {
                            v10_7.addSuppressed(v11_4);
                        }
                        throw v10_7;
                    }
                    while (v5_3.hasNext()) {
                        if (!v5_3.nextName().equals("version")) {
                            v5_3.skipValue();
                        } else {
                            v3_2 = v5_3.nextString();
                        }
                        v5_3.close();
                    }
                    v3_2 = "";
                }
            }
            v1_3.close();
            if (v3_2.length() > 100) {
                v3_2 = v3_2.substring(0, 100);
            }
            org.json.JSONObject vtmp10 = new org.json.JSONObject().put("packageName", v0_3.packageName);
            if (v0_3.versionName != null) {
                v4_0 = v0_3.versionName;
            }
            long v4_2;
            String v1_10 = vtmp10.put("versionName", v4_0);
            if (android.os.Build$VERSION.SDK_INT < 28) {
                v4_2 = ((long) v0_3.versionCode);
            } else {
                v4_2 = v0_3.getLongVersionCode();
            }
            String v0_6 = v1_10.put("versionCode", v4_2);
            if (v3_2.isEmpty()) {
                v3_2 = org.json.JSONObject.NULL;
            }
            return v0_6.put("gameVersion", v3_2).put("filename", p11).put("sha256", com.personal.aihub.GameDataStore.hash(p10));
        }
    }

    private static String isoStamp()
    {
        String v0_2 = new java.text.SimpleDateFormat("yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'", java.util.Locale.US);
        v0_2.setTimeZone(java.util.TimeZone.getTimeZone("UTC"));
        return v0_2.format(new java.util.Date());
    }

    static android.view.WindowInsets lambda$1(android.view.View p4, android.view.WindowInsets p5)
    {
        int v0_4 = p5.getInsets(((android.view.WindowInsets$Type.systemBars() | android.view.WindowInsets$Type.displayCutout()) | android.view.WindowInsets$Type.ime()));
        p4.setPadding(v0_4.left, v0_4.top, v0_4.right, v0_4.bottom);
        return p5;
    }

    private org.json.JSONArray listPatches()
    {
        org.json.JSONArray v0_1 = new org.json.JSONArray();
        java.io.File[] v1_2 = new java.io.File(this.root, "patches").listFiles();
        if (v1_2 != null) {
            int v2_1 = v1_2.length;
            int v3_0 = 0;
            while (v3_0 < v2_1) {
                String v4_0 = v1_2[v3_0];
                try {
                    if (v4_0.getName().endsWith(".json")) {
                        v0_1.put(new org.json.JSONObject(com.personal.aihub.CreatorActivity.readText(v4_0, 20971520)));
                    }
                    v3_0++;
                } catch (Exception) {
                }
            }
        }
        return v0_1;
    }

    private org.json.JSONArray listProjects()
    {
        org.json.JSONObject v2_0 = "updatedAt";
        String v3_6 = "targetId";
        org.json.JSONArray v5_1 = new org.json.JSONArray();
        java.io.File[] v7_0 = this.projects.listFiles();
        if (v7_0 != null) {
            int v8 = v7_0.length;
            String v9_6 = 0;
            int v10 = 0;
            while (v10 < v8) {
                long v17_1;
                String v18;
                String v11_2 = v7_0[v10];
                try {
                    if (!v11_2.getName().endsWith(".json")) {
                        v17_1 = v2_0;
                        v18 = v3_6;
                    } else {
                        String v9_8;
                        org.json.JSONObject v12_3 = new org.json.JSONObject(com.personal.aihub.CreatorActivity.readText(v11_2, 20971520));
                        String v11_7 = v12_3.getJSONObject("tables").getJSONArray("cards").getJSONObject(v9_6);
                        org.json.JSONObject v13_4 = v12_3.optJSONObject("cardOverrides");
                        String v14_2 = new org.json.JSONObject().put("key", v12_3.getString("key"));
                        if (v13_4 != null) {
                            v9_8 = v13_4.optString("name", v11_7.optString("name"));
                        } else {
                            v9_8 = v11_7.optString("name");
                        }
                        String v15_4;
                        String v9_12 = v14_2.put("name", v9_8).put(v3_6, v12_3.getLong(v3_6)).put("reservedIds", com.personal.aihub.ProjectFormsData.reservedIds(v12_3)).put(v2_0, v12_3.optString(v2_0));
                        if (v13_4 != null) {
                            v15_4 = v13_4.optInt("rarity", v11_7.optInt("rarity"));
                        } else {
                            v15_4 = v11_7.optInt("rarity");
                        }
                        String v15_6;
                        String v9_13 = v9_12.put("rarity", v15_4);
                        if (v13_4 != null) {
                            v15_6 = v13_4.optInt("element", v11_7.optInt("element"));
                        } else {
                            v15_6 = v11_7.optInt("element");
                        }
                        String v9_14 = v9_13.put("element", v15_6);
                        if (v13_4 != null) {
                            v17_1 = v2_0;
                            v18 = v3_6;
                            v2_0 = v13_4.optLong("resource_id", v11_7.optLong("resource_id"));
                        } else {
                            v17_1 = v2_0;
                            v18 = v3_6;
                            v2_0 = v11_7.optLong("resource_id");
                        }
                        String v9_5;
                        org.json.JSONObject v2_3 = v9_14.put("resourceId", v2_0).put("origin", v12_3.optString("libraryOrigin", "created")).put("sparkingAnimations", com.personal.aihub.CreatorActivity.hasSparkingAnimations(v12_3));
                        if (v12_3.optJSONObject("source") != null) {
                            v9_5 = v12_3.getJSONObject("source").optString("database");
                        } else {
                            v9_5 = "";
                        }
                        v5_1.put(v2_3.put("sourceDatabase", v9_5).put("author", v12_3.getJSONObject("patch").optString("author")));
                    }
                    v10++;
                    v2_0 = v17_1;
                    v3_6 = v18;
                    v9_6 = 0;
                } catch (Exception) {
                } catch (Exception) {
                }
            }
        }
        return v5_1;
    }

    public static String mime(String p1)
    {
        String v1_1 = p1.toLowerCase(java.util.Locale.ROOT);
        if (!v1_1.endsWith(".wasm")) {
            if (!v1_1.endsWith(".html")) {
                if (!v1_1.endsWith(".js")) {
                    if (!v1_1.endsWith(".css")) {
                        if (!v1_1.endsWith(".json")) {
                            if (!v1_1.endsWith(".png")) {
                                if (!v1_1.endsWith(".svg")) {
                                    if ((!v1_1.endsWith(".jpg")) && (!v1_1.endsWith(".jpeg"))) {
                                        if (!v1_1.endsWith(".webp")) {
                                            String v1_3;
                                            if (!v1_1.endsWith(".gif")) {
                                                v1_3 = "application/octet-stream";
                                            } else {
                                                v1_3 = "image/gif";
                                            }
                                            return v1_3;
                                        } else {
                                            return "image/webp";
                                        }
                                    } else {
                                        return "image/jpeg";
                                    }
                                } else {
                                    return "image/svg+xml";
                                }
                            } else {
                                return "image/png";
                            }
                        } else {
                            return "application/json";
                        }
                    } else {
                        return "text/css";
                    }
                } else {
                    return "application/javascript";
                }
            } else {
                return "text/html";
            }
        } else {
            return "application/wasm";
        }
    }

    private static String normalizeAsset(String p24)
    {
        if (!com.personal.aihub.CreatorActivity.safePath(p24)) {
            throw new java.io.IOException("Unsafe archive path");
        } else {
            String v2_0 = p24.split("/");
            String v6 = "lua";
            String v8 = "layout";
            String v10 = "movie";
            String v12 = "card_metamorphic";
            String v14 = "card_costume";
            String v16 = "origin";
            String v18 = "item";
            String v20 = "fonts";
            java.util.HashSet v3_1 = new java.util.HashSet(java.util.Arrays.asList(new String[] {"tutorial0", "voice"})));
            int v4_3 = 0;
            while (v4_3 < v2_0.length) {
                if (!v3_1.contains(v2_0[v4_3])) {
                    v4_3++;
                } else {
                    return String.join("/", ((CharSequence[]) java.util.Arrays.copyOfRange(v2_0, v4_3, v2_0.length)));
                }
            }
            return p24.replaceFirst("^(assets|files|uncompressed)/", "");
        }
    }

    private java.io.File patchFile(String p4)
    {
        if (!p4.matches("[a-f0-9-]{36}")) {
            throw new java.io.IOException("Invalid patch key");
        } else {
            String v0_1 = new java.io.File(this.root, "patches");
            v0_1.mkdirs();
            StringBuilder v2_2 = new StringBuilder();
            v2_2.append(String.valueOf(p4));
            v2_2.append(".eclp");
            return new java.io.File(v0_1, v2_2.toString());
        }
    }

    private void prepareSparkingSnapshot()
    {
        if (this.sparkingStore().state() == null) {
            java.io.IOException v1_10 = this.getCacheDir();
            String v2_0 = new StringBuilder("sparking-snapshot-");
            v2_0.append(java.util.UUID.randomUUID());
            v2_0.append(".db");
            java.io.File v0_1 = new java.io.File(v1_10, v2_0.toString());
            try {
                java.io.IOException v1_1 = this.getAssets().open("sparking-reference.db");
                try {
                    String v2_4 = new java.io.FileOutputStream(v0_1);
                } catch (String v2_6) {
                    if (v1_1 != null) {
                        try {
                            v1_1.close();
                        } catch (java.io.IOException v1_2) {
                            v2_6.addSuppressed(v1_2);
                        }
                    }
                    throw v2_6;
                }
                try {
                    com.personal.aihub.CreatorActivity.copy(v1_1, v2_4, 536870912);
                } catch (com.personal.aihub.GameDataStore v3_3) {
                    try {
                        v2_4.close();
                    } catch (String v2_5) {
                        v3_3.addSuppressed(v2_5);
                    }
                    throw v3_3;
                }
                v2_4.close();
                if (v1_1 != null) {
                    v1_1.close();
                }
                if (!"cf13b8553448507ad723e17a7b347e6eac4d7627a2e4fff56c0f7747660dffd8".equals(com.personal.aihub.GameDataStore.hash(v0_1))) {
                    throw new java.io.IOException("The built-in Sparking catalogue is incomplete. Reinstall the complete APK.");
                } else {
                    this.sparkingStore().commit(v0_1, new org.json.JSONObject().put("source", "Sparking game database \u00b7 built-in snapshot").put("sourceType", "sparking-bundled").put("date", "2026-10-17").put("latestVersion", 1791992148).put("count", this.verifyDb(v0_1, 1)));
                    v0_1.delete();
                    return;
                }
            } catch (java.io.IOException v1_7) {
                v0_1.delete();
                throw v1_7;
            }
        } else {
            return;
        }
    }

    private org.json.JSONObject previewAnimation(org.json.JSONObject p38)
    {
        String v9_2;
        long v8_0 = "previewAppearance";
        if (!p38.has("previewAppearance")) {
            v9_2 = 0;
        } else {
            java.io.IOException v0_62 = p38.optJSONObject("previewAppearance");
            if ((v0_62 == null) || (v0_62.length() != 2)) {
                throw new java.io.IOException("Choose valid preview artwork");
            } else {
                int v5_3 = new org.json.JSONObject();
                String v10_1 = 0;
                while (v10_1 < 2) {
                    String[] v11_4 = new String[] {"actorId", "artCardId"})[v10_1];
                    String v12_5 = v0_62.opt(v11_4);
                    if (!(v12_5 instanceof Number)) {
                        throw new java.io.IOException("Choose valid preview artwork");
                    } else {
                        String v12_7 = ((Number) v12_5).doubleValue();
                        if ((!Double.isFinite(v12_7)) || ((v12_7 != Math.floor(v12_7)) || ((v12_7 < 4607182418800017408) || (v12_7 > 4845873199050653695)))) {
                            throw new java.io.IOException("Choose valid preview artwork");
                        } else {
                            v5_3.put(v11_4, ((long) v12_7));
                            v10_1++;
                        }
                    }
                }
                v9_2 = v5_3;
            }
        }
        if ((p38.has("effectPacks")) && (p38.optJSONArray("effectPacks") == null)) {
            throw new java.io.IOException("Choose valid edited movies");
        } else {
            java.io.IOException v0_50;
            String[] v11_2 = com.personal.aihub.PreviewEffectPacks.normalize(p38.optJSONArray("effectPacks"));
            if (!p38.has("sparkingEffectIds")) {
                v0_50 = 0;
            } else {
                v0_50 = p38.get("sparkingEffectIds");
            }
            java.io.IOException v0_54;
            String v13_3 = com.personal.aihub.PreviewMetadata.sparkingEffects(v0_50);
            com.personal.aihub.PreviewMetadata.validateEffectSources(v11_2, v13_3);
            if (!p38.has("sparkingVersion")) {
                v0_54 = 0;
            } else {
                v0_54 = p38.get("sparkingVersion");
            }
            int v4_31 = com.personal.aihub.PreviewMetadata.normalizeVersion(v0_54);
            if ((v13_3.length() > 0) || ("sparking".equals(p38.optString("sourceDatabase")))) {
                this = this.prepareSparkingSnapshot();
                com.personal.aihub.PreviewMetadata.databaseFile(this.root, "sparking", v4_31);
            }
            org.json.JSONArray v17 = p38.optJSONArray("assets");
            if ((p38.has("assets")) && (v17 == null)) {
                throw new java.io.IOException("Choose valid preview pictures");
            } else {
                com.personal.aihub.GameAssets.overlayMap(v17);
                String v1_44 = new com.personal.aihub.PreviewCache(this.root);
                void v2_14 = p38.optString("mode", "lua");
                long v21 = v4_31;
                org.json.JSONObject v6_1 = "training";
                if (!java.util.Arrays.asList(new String[] {"lua", "pack", "movie", "training", "awakening"})).contains(v2_14)) {
                    throw new java.io.IOException("Choose a supported preview type");
                } else {
                    java.io.IOException v0_7;
                    if (!v2_14.equals("pack")) {
                        if (!v2_14.equals("movie")) {
                            v0_7 = "lua-player";
                        } else {
                            v0_7 = "usm-player";
                        }
                    } else {
                        v0_7 = "lwf-player";
                    }
                    int v24_1;
                    String v25;
                    if (!v1_44.offline()) {
                        v24_1 = "sparkingEffectIds";
                        v25 = v13_3;
                    } else {
                        v24_1 = "sparkingEffectIds";
                        v25 = v13_3;
                        String v12_1 = new StringBuilder("https://dokkan-eclipse.com/tools/");
                        v12_1.append(v0_7);
                        v12_1.append("/");
                        v1_44.text(v12_1.toString(), 2097152);
                    }
                    String v12_3 = p38.optString("text");
                    String v13_1 = p38.optString("path");
                    String v1_3 = p38.optString("resourcePath");
                    if (!v2_14.equals("pack")) {
                        if (!v2_14.equals("movie")) {
                            if ((v12_3.length() > 2097152) || ((v12_3.isEmpty()) && (!com.personal.aihub.CreatorActivity.validAnimationPath(v13_1)))) {
                                throw new java.io.IOException("Choose a valid animation or a shorter composition");
                            }
                        } else {
                            if ((!v1_3.matches("(?i)movie/[a-z0-9_./-]+\\.usm")) || (!com.personal.aihub.CreatorActivity.safePath(v1_3))) {
                                throw new java.io.IOException("Choose a movie from the game video browser");
                            }
                        }
                    } else {
                        if ((!v1_3.matches("(?i)[a-z0-9_./-]+\\.lwf")) || (!com.personal.aihub.CreatorActivity.safePath(v1_3))) {
                            throw new java.io.IOException("Choose a valid visual pack");
                        }
                    }
                    String v16_0;
                    long v29_0;
                    String v30_0;
                    String v27 = v11_2;
                    if ((!v2_14.equals("training")) && (!v2_14.equals("awakening"))) {
                        v29_0 = "previewAppearance";
                        v30_0 = v9_2;
                        v16_0 = 0;
                    } else {
                        int v4_15 = new StringBuilder("ab_script/");
                        if (!v2_14.equals("training")) {
                            v6_1 = "awaken";
                        }
                        v4_15.append(v6_1);
                        v4_15.append("/a[0-9]{4}\\.lua");
                        if (!v13_1.matches(v4_15.toString())) {
                            throw new java.io.IOException("Choose the matching item animation");
                        } else {
                            int v4_19 = p38.optJSONArray("trainingItems");
                            if ((v4_19 == 0) || (v4_19.length() > 5)) {
                                throw new java.io.IOException("Choose up to five items for this scene");
                            } else {
                                int v5_8 = 0;
                                while (v5_8 < v4_19.length()) {
                                    org.json.JSONObject v6_5 = v4_19.optJSONObject(v5_8);
                                    if (v6_5 == null) {
                                        throw new java.io.IOException("Choose valid scene items");
                                    } else {
                                        String v10_4 = "id";
                                        String[] v11_0 = new String[] {"id", "rarity"});
                                        String v16_1 = v4_19;
                                        int v4_26 = 2;
                                        int v14_2 = 0;
                                        while (v14_2 < v4_26) {
                                            long v31_1;
                                            int v4_27 = v11_0[v14_2];
                                            String[] v28 = v11_0;
                                            String[] v11_1 = v6_5.opt(v4_27);
                                            long v29_1 = v8_0;
                                            String v30_1 = v9_2;
                                            long v8_3 = v6_5.optLong(v4_27, -1);
                                            if (!v4_27.equals(v10_4)) {
                                                v31_1 = 0;
                                            } else {
                                                v31_1 = 1;
                                            }
                                            long v33;
                                            if (!v4_27.equals(v10_4)) {
                                                v33 = 4;
                                            } else {
                                                v33 = 9999999;
                                            }
                                            if ((!(v11_1 instanceof Number)) || ((((Number) v11_1).doubleValue() != ((double) v8_3)) || ((v8_3 < v31_1) || (v8_3 > v33)))) {
                                                throw new java.io.IOException("Choose valid scene items");
                                            } else {
                                                v14_2++;
                                                v11_0 = v28;
                                                v8_0 = v29_1;
                                                v9_2 = v30_1;
                                                v4_26 = 2;
                                            }
                                        }
                                        String v30 = v9_2;
                                        v5_8++;
                                        v4_19 = v16_1;
                                    }
                                }
                                v16_0 = v4_19;
                                v29_0 = v8_0;
                                v30_0 = v9_2;
                            }
                        }
                    }
                    String v10_3 = v21;
                    java.io.IOException v0_30 = new org.json.JSONObject().put("mode", v2_14).put("assetKey", p38.optString("assetKey")).put("resourcePath", v1_3).put("scene", p38.optString("scene")).put("text", v12_3).put("path", v13_1).put("forgeVerifiedMusicPath", this.verifiedMusicPath(v2_14, v13_1, v12_3, p38.optString("assetKey"), v17)).put("name", p38.optString("name", "Animation preview")).put("attackerId", Math.max(1, p38.optLong("attackerId", 1000010))).put("enemyId", Math.max(1, p38.optLong("enemyId", 1000020)));
                    if ("sparking".equals(p38.optString("sourceDatabase"))) {
                        v0_30.put("sourceDatabase", "sparking");
                    }
                    if (v17 != null) {
                        v0_30.put("assets", new org.json.JSONArray(v17.toString()));
                    }
                    if (v16_0 != null) {
                        v0_30.put("trainingItems", new org.json.JSONArray(v16_0.toString()));
                    }
                    if (v30_0 != null) {
                        v0_30.put(v29_0, v30_0);
                    }
                    v0_30.put("effectPacks", v27);
                    if (v25.length() > 0) {
                        v0_30.put(v24_1, v25);
                    }
                    if (v10_3 > 0) {
                        v0_30.put("sparkingVersion", v10_3);
                    }
                    String v1_36 = java.util.UUID.randomUUID().toString();
                    void v2_10 = new java.io.File(new java.io.File(this.getCacheDir(), "animation-preview"), v1_36);
                    v2_10.mkdirs();
                    com.personal.aihub.CreatorActivity.writeText(new java.io.File(v2_10, "request.json"), v0_30.toString());
                    this.runOnUiThread(new com.personal.aihub.CreatorActivity$8(this, v1_36));
                    return new org.json.JSONObject().put("opened", 1).put("online", 1);
                }
            }
        }
    }

    private void progress(String p3, String p4, long p5, long p7)
    {
        try {
            this.importProgress = new org.json.JSONObject().put("phase", p3).put("label", p4).put("bytes", p5).put("total", p7);
        } catch (Exception) {
        }
        return;
    }

    private java.io.File projectFile(String p4)
    {
        if ((p4 == null) || (!p4.matches("[a-zA-Z0-9_-]{1,100}"))) {
            throw new java.io.IOException("Invalid project key");
        } else {
            java.io.File v1 = this.projects;
            StringBuilder v2_1 = new StringBuilder();
            v2_1.append(String.valueOf(p4));
            v2_1.append(".json");
            return new java.io.File(v1, v2_1.toString());
        }
    }

    private org.json.JSONArray query(org.json.JSONObject p3)
    {
        this.ensureDb();
        return this.queryDatabase(this.db, this.schema, p3);
    }

    private org.json.JSONArray queryDatabase(android.database.sqlite.SQLiteDatabase p10, org.json.JSONObject p11, org.json.JSONObject p12)
    {
        String[] v0_16 = p12.getString("table");
        Throwable v11_9 = p11.optJSONArray(v0_16);
        if (v11_9 == null) {
            throw new java.io.IOException("Table is not in this database.");
        } else {
            StringBuilder v1_1 = new java.util.HashSet();
            int v3_0 = 0;
            while (v3_0 < v11_9.length()) {
                v1_1.add(v11_9.getJSONObject(v3_0).getString("name"));
                v3_0++;
            }
            Throwable v11_6 = new java.util.ArrayList();
            int v3_6 = new java.util.ArrayList();
            String v4_6 = p12.optJSONObject("filters");
            if (v4_6 != null) {
                String v5_5 = v4_6.keys();
                while (v5_5.hasNext()) {
                    String v6_2 = ((String) v5_5.next());
                    if (!v1_1.contains(v6_2)) {
                        throw new java.io.IOException("Unknown column");
                    } else {
                        if (!v4_6.isNull(v6_2)) {
                            String v7_8 = new StringBuilder();
                            v7_8.append(String.valueOf(com.personal.aihub.CreatorActivity.identifier(v6_2)));
                            v7_8.append(" = ?");
                            v3_6.add(v7_8.toString());
                            v11_6.add(String.valueOf(v4_6.get(v6_2)));
                        } else {
                            String v7_11 = new StringBuilder();
                            v7_11.append(String.valueOf(com.personal.aihub.CreatorActivity.identifier(v6_2)));
                            v7_11.append(" IS NULL");
                            v3_6.add(v7_11.toString());
                        }
                    }
                }
            }
            String v4_10 = p12.optJSONArray("ids");
            if (v4_10 != null) {
                if (v4_10.length() != 0) {
                    if (v4_10.length() > 1000) {
                        throw new java.io.IOException("Too many row IDs");
                    } else {
                        String v5_9 = new java.util.ArrayList();
                        String v6_0 = 0;
                        while (v6_0 < v4_10.length()) {
                            v5_9.add("?");
                            v11_6.add(String.valueOf(v4_10.getLong(v6_0)));
                            v6_0++;
                        }
                        String v4_12 = new StringBuilder("\"id\" IN (");
                        v4_12.append(String.join(",", v5_9));
                        v4_12.append(")");
                        v3_6.add(v4_12.toString());
                    }
                } else {
                    return new org.json.JSONArray();
                }
            }
            String v4_15 = p12.optJSONObject("search");
            if ((v4_15 != null) && (!v4_15.optString("text").isEmpty())) {
                String v6_16 = v4_15.getString("column");
                if (!v1_1.contains(v6_16)) {
                    throw new java.io.IOException("Unknown search column");
                } else {
                    String v7_15 = new StringBuilder();
                    v7_15.append(String.valueOf(com.personal.aihub.CreatorActivity.identifier(v6_16)));
                    v7_15.append(" LIKE ?");
                    v3_6.add(v7_15.toString());
                    String v4_16 = v4_15.getString("text");
                    String v5_14 = new StringBuilder("%");
                    v5_14.append(v4_16.substring(0, Math.min(v4_16.length(), 200)));
                    v5_14.append("%");
                    v11_6.add(v5_14.toString());
                }
            }
            String v4_3 = p12.optString("order", "id");
            if (!v1_1.contains(v4_3)) {
                throw new java.io.IOException("Unknown sort column");
            } else {
                String[] v0_5;
                StringBuilder v1_4 = new StringBuilder("SELECT * FROM ");
                v1_4.append(com.personal.aihub.CreatorActivity.identifier(v0_16));
                if (!v3_6.isEmpty()) {
                    String[] v0_4 = new StringBuilder(" WHERE ");
                    v0_4.append(String.join(" AND ", v3_6));
                    v0_5 = v0_4.toString();
                } else {
                    v0_5 = "";
                }
                v1_4.append(v0_5);
                v1_4.append(" ORDER BY ");
                v1_4.append(com.personal.aihub.CreatorActivity.identifier(v4_3));
                v1_4.append(" LIMIT ");
                v1_4.append(Math.max(1, Math.min(5000, p12.optInt("limit", 100))));
                v1_4.append(" OFFSET ");
                v1_4.append(Math.max(0, p12.optInt("offset", 0)));
                String[] v0_15 = new String[0];
                android.database.Cursor v10_3 = p10.rawQuery(v1_4.toString(), ((String[]) v11_6.toArray(v0_15)));
                try {
                    Throwable v11_5 = com.personal.aihub.CreatorActivity.rows(v10_3);
                } catch (Throwable v11_7) {
                    if (v10_3 != null) {
                        v10_3.close();
                    }
                    throw v11_7;
                }
                if (v10_3 != null) {
                    v10_3.close();
                }
                return v11_5;
            }
        }
    }

    private static String readText(java.io.File p3, int p4)
    {
        java.io.FileInputStream v0_1 = new java.io.FileInputStream(p3);
        try {
            Throwable v3_4 = new java.io.ByteArrayOutputStream();
            try {
                com.personal.aihub.CreatorActivity.copy(v0_1, v3_4, ((long) p4));
                Throwable v4_3 = v3_4.toString("UTF-8");
            } catch (Throwable v4_4) {
                try {
                    v3_4.close();
                } catch (Throwable v3_1) {
                    v4_4.addSuppressed(v3_1);
                }
                throw v4_4;
            }
            v3_4.close();
            v0_1.close();
            return v4_3;
        } catch (Throwable v3_2) {
            try {
                v0_1.close();
            } catch (Throwable v4_1) {
                v3_2.addSuppressed(v4_1);
            }
            throw v3_2;
        }
    }

    private String readTextAsset(String p4, int p5)
    {
        Throwable v4_2 = this.getAssets().open(p4);
        try {
            Throwable v0_3 = new java.io.ByteArrayOutputStream();
        } catch (Throwable v5_3) {
            if (v4_2 != null) {
                try {
                    v4_2.close();
                } catch (Throwable v4_1) {
                    v5_3.addSuppressed(v4_1);
                }
            }
            throw v5_3;
        }
        try {
            com.personal.aihub.CreatorActivity.copy(v4_2, v0_3, ((long) p5));
            Throwable v5_1 = v0_3.toString("UTF-8");
        } catch (Throwable v5_2) {
            try {
                v0_3.close();
            } catch (Throwable v0_1) {
                v5_2.addSuppressed(v0_1);
            }
            throw v5_2;
        }
        v0_3.close();
        if (v4_2 != null) {
            v4_2.close();
        }
        return v5_1;
    }

    private org.json.JSONObject restoreDatabase()
    {
        try {
            this.progress("restore", "Checking the previous database", 0, 0);
            try {
                org.json.JSONObject v1_8 = this.dataStore();
                void v2_1 = v1_8.state();
            } catch (org.json.JSONObject v1_5) {
                this.progress("error", "Restore failed; the active database was kept", 0, 0);
                throw v1_5;
            }
            if ((v2_1 == 0) || (v2_1.optJSONObject("previous") == null)) {
                throw new java.io.IOException("No previous database is available");
            } else {
                this.verifyDb(v1_8.file(v2_1.getJSONObject("previous")));
                v1_8.restore();
                org.json.JSONObject v1_2 = this.db;
                if (v1_2 != null) {
                    v1_2.close();
                }
                this.db = 0;
                org.json.JSONObject v1_4 = this.info();
                this.progress("done", "Previous database restored; saved units kept", 0, 0);
                return v1_4;
            }
        } catch (org.json.JSONObject v1_6) {
            throw v1_6;
        }
    }

    private static org.json.JSONArray rows(android.database.Cursor p6)
    {
        org.json.JSONArray v0_1 = new org.json.JSONArray();
        String[] v1 = p6.getColumnNames();
        while (p6.moveToNext()) {
            org.json.JSONObject v2_2 = new org.json.JSONObject();
            int v3 = 0;
            while (v3 < v1.length) {
                Double v4_2;
                Double v4_1 = p6.getType(v3);
                if (v4_1 == null) {
                    v4_2 = org.json.JSONObject.NULL;
                } else {
                    if (v4_1 == 1) {
                        v4_2 = Long.valueOf(p6.getLong(v3));
                    } else {
                        if (v4_1 == 2) {
                            v4_2 = Double.valueOf(p6.getDouble(v3));
                        } else {
                            v4_2 = p6.getString(v3);
                        }
                    }
                }
                v2_2.put(v1[v3], v4_2);
                v3++;
            }
            v0_1.put(v2_2);
        }
        return v0_1;
    }

    public static boolean safePath(String p5)
    {
        if ((p5 == 0) || ((p5.isEmpty()) || ((p5.length() > 500) || ((p5.startsWith("/")) || ((p5.contains("\\")) || (p5.matches(".*[:\\x00-\\x1f].*"))))))) {
            return 0;
        } else {
            int v5_1 = p5.split("/", -1);
            int v2_6 = 0;
            while (v2_6 < v5_1.length) {
                boolean v3_0 = v5_1[v2_6];
                if ((!v3_0.isEmpty()) && ((!v3_0.equals(".")) && (!v3_0.equals("..")))) {
                    v2_6++;
                } else {
                    return 0;
                }
            }
            return 1;
        }
    }

    private void saveFormatKey(java.io.File p5, byte[] p6)
    {
        int v1_0 = this.root;
        Throwable v2_6 = new StringBuilder("format-");
        v2_6.append(java.util.UUID.randomUUID());
        v2_6.append(".tmp");
        java.io.File v0_1 = new java.io.File(v1_0, v2_6.toString());
        try {
            Throwable v2_2 = new java.io.FileOutputStream(v0_1);
            try {
                v2_2.write(p6);
                v2_2.getFD().sync();
            } catch (java.io.IOException v5_1) {
                try {
                    v2_2.close();
                } catch (Throwable v2_4) {
                    v5_1.addSuppressed(v2_4);
                }
                throw v5_1;
            }
            v2_2.close();
            if (!v0_1.renameTo(p5)) {
                throw new java.io.IOException("Could not save this game\'s import format.");
            } else {
                v0_1.delete();
                java.util.Arrays.fill(p6, 0);
                return;
            }
        } catch (java.io.IOException v5_5) {
            v0_1.delete();
            java.util.Arrays.fill(p6, 0);
            throw v5_5;
        }
    }

    private org.json.JSONObject saveProject(org.json.JSONObject p13)
    {
        if ((p13.optString("format").equals("dokkan-unit-forge")) && (((p13.opt("version") instanceof Number)) && (p13.optDouble("version") == 4607182418800017408))) {
            Long v0_17 = p13.optDouble("targetId");
            if ((v0_17 > 0) && ((v0_17 <= 4746794007244308480) && (v0_17 == ((double) ((long) v0_17))))) {
                Long v0_31 = p13.optJSONObject("tables");
                if (v0_31 != null) {
                    Long v0_32 = v0_31.optJSONArray("cards");
                    if ((v0_32 != null) && ((v0_32.length() == 1) && (v0_32.optJSONObject(0) != null))) {
                        p13.put("targetId", p13.optLong("targetId"));
                        if (p13.has("formProjects")) {
                            int v5_0 = p13.optJSONArray("formProjects");
                            if (v5_0 == 0) {
                                throw new java.io.IOException("Unsupported project");
                            } else {
                                int v7 = v5_0.length();
                                if (v7 > 4) {
                                } else {
                                    boolean v6_1 = new java.util.ArrayList();
                                    v6_1.add(Long.valueOf(p13.optLong("targetId")));
                                    int v8 = 0;
                                    while (v8 < v7) {
                                        org.json.JSONObject v9 = v5_0.optJSONObject(v8);
                                        if ((v9 != null) && (("dokkan-unit-forge".equals(v9.optString("format"))) && ((!v9.has("formProjects")) && ((!v9.has("transformLinks")) && (((v9.opt("version") instanceof Number)) && (v9.optDouble("version") == 4607182418800017408)))))) {
                                            Long v0_12 = v9.optDouble("targetId");
                                            if ((v0_12 > 0) && ((v0_12 <= 4746794007244308480) && (v0_12 == ((double) ((long) v0_12))))) {
                                                Long v0_15 = v9.optJSONObject("tables");
                                                if (v0_15 != null) {
                                                    Long v0_16 = v0_15.optJSONArray("cards");
                                                    if ((v0_16 != null) && ((v0_16.length() == 1) && (v0_16.optJSONObject(0) != null))) {
                                                        v9.put("targetId", v9.optLong("targetId"));
                                                        int v10 = 0;
                                                        int v11 = v6_1.size();
                                                        while (v10 < v11) {
                                                            if (Math.abs((v9.optLong("targetId") - ((Number) v6_1.get(v10)).longValue())) >= 1000) {
                                                                v10++;
                                                            }
                                                        }
                                                        v6_1.add(Long.valueOf(v9.optLong("targetId")));
                                                        v8++;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        try {
                            int v1_18 = this.projectFile(p13.getString("key"));
                            long v2_26 = p13.optString("updatedAt");
                        } catch (org.json.JSONObject v13_8) {
                            throw v13_8;
                        }
                        if (v1_18.isFile()) {
                            String v3_5 = new org.json.JSONObject(com.personal.aihub.CreatorActivity.readText(v1_18, 20971520)).optString("updatedAt");
                            if ((v3_5.matches("\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z")) && ((v2_26.matches("\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z")) && (v3_5.compareTo(v2_26) > 0))) {
                                p13 = new org.json.JSONObject().put("saved", 1).put("superseded", 1);
                                return p13;
                            }
                        }
                        org.json.JSONObject v13_2 = p13.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8);
                        if (v13_2.length > 20971520) {
                            throw new java.io.IOException("Project exceeds 20 MiB.");
                        } else {
                            com.personal.aihub.ProjectVersions.atomic(v1_18, v13_2);
                            return new org.json.JSONObject().put("saved", 1).put("revision", com.personal.aihub.ProjectVersions.revision(v13_2));
                        }
                    }
                }
            }
        }
    }

    private org.json.JSONArray sparkingAnimationFiles()
    {
        this.prepareSparkingSnapshot();
        java.util.Iterator v0_5 = this.sparkingStore().meta();
        java.util.TreeSet v1_1 = new java.util.TreeSet();
        String v4_0 = 0;
        if (v0_5.optLong("latestVersion") != 1791992148) {
            boolean v3_3 = new org.json.JSONObject(com.personal.aihub.CreatorActivity.readText(this.sparkingAssetManifest(v0_5.getLong("latestVersion")), 33554432)).getJSONArray("assets");
            while (v4_0 < v3_3.length()) {
                String v5_7 = v3_3.getJSONObject(v4_0).optString("file_path");
                if ((v5_7.startsWith("lua/")) && (com.personal.aihub.CreatorActivity.validAnimationPath(v5_7.substring(4)))) {
                    v1_1.add(v5_7.substring(4));
                }
                v4_0++;
            }
            java.util.Iterator v0_4 = new com.personal.aihub.CpkArchive(this.sparkingBaseScripts(this.sparkingAssetManifest(v0_5.getLong("latestVersion")))).entries.iterator();
            while (v0_4.hasNext()) {
                String v2_2 = ((com.personal.aihub.CpkArchive$Entry) v0_4.next());
                boolean v3_7 = new StringBuilder("ab_script/");
                v3_7.append(v2_2.path);
                String v2_4 = v3_7.toString();
                if (com.personal.aihub.CreatorActivity.validAnimationPath(v2_4)) {
                    v1_1.add(v2_4);
                }
            }
        } else {
            java.util.Iterator v0_7 = new org.json.JSONArray(this.readTextAsset("ui/data/sparking-animation-paths.json", 4194304));
            while (v4_0 < v0_7.length()) {
                if (com.personal.aihub.CreatorActivity.validAnimationPath(v0_7.getString(v4_0))) {
                    v1_1.add(v0_7.getString(v4_0));
                }
                v4_0++;
            }
        }
        return new org.json.JSONArray(v1_1);
    }

    private org.json.JSONObject sparkingAnimationSource(String p13, String p14)
    {
        if (!com.personal.aihub.CreatorActivity.validAnimationPath(p13)) {
            throw new java.io.IOException("Choose a Sparking animation from the browser.");
        } else {
            this.prepareSparkingSnapshot();
            if (p14.isEmpty()) {
                Throwable v14_4 = new StringBuilder("sparking-source-");
                v14_4.append(this.sparkingStore().meta().getLong("latestVersion"));
                v14_4.append("/lua/");
                v14_4.append(p13);
                p14 = v14_4.toString();
            }
            String v0_9 = this.assetFile(p14);
            if (!v0_9.isFile()) {
                v0_9.getParentFile().mkdirs();
                boolean v1_6 = this.sparkingAssetManifest(-1);
                java.io.File v5_9 = new org.json.JSONObject(com.personal.aihub.CreatorActivity.readText(v1_6, 33554432));
                java.io.FileOutputStream v6_8 = v5_9.getJSONArray("assets");
                String v7_1 = 0;
                while (v7_1 < v6_8.length()) {
                    String v8_3 = new StringBuilder("lua/");
                    v8_3.append(p13);
                    if (!v8_3.toString().equals(v6_8.getJSONObject(v7_1).optString("file_path"))) {
                        v7_1++;
                    } else {
                        java.io.FileOutputStream v6_1 = new StringBuilder("lua/");
                        v6_1.append(p13);
                        if (com.personal.aihub.SparkingContent.assetRecord(v5_9, v6_1.toString()).getLong("size") > 2097152) {
                            throw new java.io.IOException("This original animation exceeds the supported script size.");
                        } else {
                            java.io.File v5_4 = new StringBuilder("lua/");
                            v5_4.append(p13);
                            com.personal.aihub.SparkingContent.downloadAsset(v1_6, v5_4.toString(), v0_9, new com.personal.aihub.CreatorActivity$$ExternalSyntheticLambda0(this));
                        }
                    }
                }
                java.io.File v5_11 = new com.personal.aihub.CpkArchive(this.sparkingBaseScripts(v1_6));
                boolean v1_9 = p13.substring(10);
                java.io.FileOutputStream v6_10 = v5_11.entries.iterator();
                String v7_0 = 0;
                while (v6_10.hasNext()) {
                    String v8_1 = ((com.personal.aihub.CpkArchive$Entry) v6_10.next());
                    if (v1_9.equals(v8_1.path)) {
                        if (v7_0 != null) {
                            throw new java.io.IOException("Conflicting original animation entries.");
                        } else {
                            v7_0 = v8_1;
                        }
                    }
                }
                if ((v7_0 == null) || (v7_0.size > 2097152)) {
                    throw new java.io.IOException("This animation is not present in Sparking\'s original collection or exceeds the supported size.");
                } else {
                    boolean v1_11 = v5_11.read(v7_0);
                    java.io.FileOutputStream v6_11 = v0_9.getParentFile();
                    String v7_4 = new StringBuilder("source-");
                    v7_4.append(java.util.UUID.randomUUID());
                    v7_4.append(".tmp");
                    java.io.File v5_13 = new java.io.File(v6_11, v7_4.toString());
                    try {
                        java.io.FileOutputStream v6_13 = new java.io.FileOutputStream(v5_13);
                        try {
                            v6_13.write(v1_11);
                            v6_13.getFD().sync();
                        } catch (java.io.IOException v13_22) {
                            try {
                                v6_13.close();
                            } catch (Throwable v14_13) {
                                v13_22.addSuppressed(v14_13);
                            }
                            throw v13_22;
                        }
                        v6_13.close();
                        if (!v5_13.renameTo(v0_9)) {
                            throw new java.io.IOException("Could not save the original animation.");
                        } else {
                            v5_13.delete();
                        }
                    } catch (java.io.IOException v13_3) {
                        v5_13.delete();
                        throw v13_3;
                    }
                }
            }
            boolean v1_1 = com.personal.aihub.CreatorActivity.readText(v0_9, 2097152);
            if ((v1_1.trim().isEmpty()) || ((v1_1.trim().startsWith("<")) || (v1_1.indexOf(0) >= 0))) {
                throw new java.io.IOException("This Sparking animation file could not be opened.");
            } else {
                return new org.json.JSONObject().put("path", p13).put("text", v1_1).put("assetKey", p14).put("size", v0_9.length()).put("sha256", com.personal.aihub.GameDataStore.hash(v0_9)).put("cached", 1).put("local", 1).put("sourceDatabase", "sparking");
            }
        }
    }

    private java.io.File sparkingAssetManifest(long p8)
    {
        this.prepareSparkingSnapshot();
        String v0_3 = this.sparkingStore().meta();
        long v2 = v0_3.getLong("latestVersion");
        if ((p8 != -1) && (p8 != v2)) {
            throw new java.io.IOException("This unit uses a different Sparking content version. Keep its original attached assets or recreate its copy from the matching catalogue.");
        } else {
            java.io.IOException v8_5 = new java.io.File(this.root, "sparking");
            java.io.File v9_3 = new StringBuilder("catalog-assets-");
            v9_3.append(v2);
            v9_3.append(".json");
            java.io.File v9_5 = v0_3.optString("assetsManifest", v9_3.toString());
            if (!v9_5.matches("(assets-[a-f0-9]{64}|catalog-assets-[0-9]+)\\.json")) {
                throw new java.io.IOException("Invalid Sparking resource-list reference.");
            } else {
                String v0_5 = new java.io.File(v8_5, v9_5);
                if (!v0_5.isFile()) {
                    StringBuilder v5_2 = new StringBuilder("manifest-");
                    v5_2.append(java.util.UUID.randomUUID());
                    v5_2.append(".json");
                    java.io.File v9_9 = new java.io.File(v8_5, v5_2.toString());
                    try {
                        if (com.personal.aihub.SparkingContent.downloadManifest(v9_9, new com.personal.aihub.CreatorActivity$$ExternalSyntheticLambda5(this)).getLong("latestVersion") != v2) {
                            throw new java.io.IOException("Sparking\'s server has newer game content. Import the supported APK and update characters before downloading these resources.");
                        } else {
                            if (!v9_9.renameTo(v0_5)) {
                                throw new java.io.IOException("Could not save the resource list.");
                            } else {
                                v9_9.delete();
                            }
                        }
                    } catch (java.io.IOException v8_17) {
                        v9_9.delete();
                        throw v8_17;
                    }
                }
                return v0_5;
            }
        }
    }

    private java.io.File sparkingBaseScripts(java.io.File p6)
    {
        com.personal.aihub.CreatorActivity$$ExternalSyntheticLambda6 v1_4 = new java.io.File(this.root, "sparking");
        String v2_4 = new StringBuilder("base-scripts-");
        v2_4.append(this.sparkingStore().meta().getLong("latestVersion"));
        v2_4.append(".cpk");
        java.io.File v0_1 = new java.io.File(v1_4, v2_4.toString());
        if (!v0_1.isFile()) {
            com.personal.aihub.SparkingContent.downloadAsset(p6, "lua/ab_script.cpk", v0_1, new com.personal.aihub.CreatorActivity$$ExternalSyntheticLambda6(this));
        }
        return v0_1;
    }

    private java.io.File sparkingDatabaseKey()
    {
        return new java.io.File(this.root, "sparking-database-format.bin");
    }

    private java.io.File sparkingFormatKey()
    {
        return new java.io.File(this.root, "sprk-format-key.bin");
    }

    private org.json.JSONObject sparkingInfo()
    {
        Throwable v0_7;
        this.prepareSparkingSnapshot();
        Throwable v1_0 = 1;
        if (this.sparkingStore().state() == null) {
            v0_7 = 0;
        } else {
            v0_7 = 1;
        }
        String v3_2 = new org.json.JSONObject().put("available", v0_7);
        if (this.sparkingDatabaseKey().length() != 64) {
            v1_0 = 0;
        }
        Throwable v1_1 = v3_2.put("keyConfigured", v1_0);
        if (v0_7 != null) {
            this.ensureSparkingDb();
            Throwable v0_2 = this.sparkingDb.rawQuery("SELECT count(*) FROM cards", 0);
            try {
                v0_2.moveToFirst();
                v1_1.put("count", v0_2.getLong(0));
            } catch (Throwable v1_2) {
                if (v0_2 != null) {
                    try {
                        v0_2.close();
                    } catch (Throwable v0_4) {
                        v1_2.addSuppressed(v0_4);
                    }
                }
                throw v1_2;
            }
            if (v0_2 != null) {
                v0_2.close();
            }
            v1_1.put("schema", this.sparkingSchema).put("meta", this.sparkingStore().meta());
        }
        return v1_1;
    }

    private com.personal.aihub.GameDataStore sparkingStore()
    {
        return new com.personal.aihub.GameDataStore(new java.io.File(this.root, "sparking"), new java.io.File(this.root, "sparking-unavailable.db"));
    }

    private org.json.JSONObject syncDatabase()
    {
        try {
            Exception v0_3 = this.downloadCurrentDatabase(new org.json.JSONObject());
            this.progress("done", "Game database updated", 0, 0);
            return v0_3;
        } catch (Exception v0_2) {
            this.progress("error", "Update failed; previous data was kept", 0, 0);
            throw v0_2;
        }
    }

    private org.json.JSONObject updateSparking()
    {
        void v1_5 = this.sparkingDatabaseKey();
        if ((!v1_5.isFile()) || (v1_5.length() != 64)) {
            throw new java.io.IOException("Import the original Sparking 6.5.5 APK or its ZIP first. Then download characters here.");
        } else {
            byte[] v9 = new byte[64];
            String v2_5 = new java.io.DataInputStream(new java.io.FileInputStream(v1_5));
            try {
                v2_5.readFully(v9);
                v2_5.close();
                void v1_4 = this.getCacheDir();
                String v2_7 = new StringBuilder("sparking-data-");
                v2_7.append(java.util.UUID.randomUUID());
                String v2_8 = v2_7.toString();
                java.io.File v10_1 = new java.io.File(v1_4, v2_8);
            } catch (org.json.JSONObject v0_11) {
                void v1_7 = v0_11;
                try {
                    v2_8.close();
                } catch (org.json.JSONObject v0_12) {
                    v1_7.addSuppressed(v0_12);
                }
                throw v1_7;
            }
            if (!v10_1.mkdir()) {
                throw new java.io.IOException("Could not prepare Sparking game data.");
            } else {
                try {
                    java.io.File v12_1 = new java.io.File(v10_1, "database.db");
                    java.io.File v13_1 = new java.io.File(v10_1, "assets.json");
                    java.io.File v14_1 = new java.io.File(v10_1, "readable.db");
                    org.json.JSONObject v15 = com.personal.aihub.SparkingContent.download(v12_1, v13_1, new com.personal.aihub.CreatorActivity$$ExternalSyntheticLambda4(this));
                    v15.put("sourceEncryptedSHA256", v15.getString("sha256"));
                    this.progress("decrypt", "Opening and authenticating Sparking game data", 0, 0);
                    com.personal.aihub.LegacyDatabase.decrypt(v12_1, v14_1, v9, 4);
                    this.progress("verify", "Checking Sparking characters and skills", 0, 0);
                    void v1_19 = this.verifyDb(v14_1, 1);
                    String v3_10 = new java.io.File(this.root, "sparking");
                    v3_10.mkdirs();
                    long v4_9 = new StringBuilder("assets-");
                    v4_9.append(com.personal.aihub.GameDataStore.hash(v13_1));
                    v4_9.append(".json");
                    org.json.JSONObject v0_17 = v4_9.toString();
                    long v4_1 = new java.io.File(v3_10, v0_17);
                } catch (org.json.JSONObject v0_10) {
                    java.util.Arrays.fill(v9, 0);
                    com.personal.aihub.CreatorActivity.deleteTree(v10_1);
                    throw v0_10;
                }
                if (!v4_1.exists()) {
                    if (!v13_1.renameTo(v4_1)) {
                        throw new java.io.IOException("Could not save Sparking\'s resource list.");
                    } else {
                    }
                }
                this.sparkingStore().commit(v14_1, v15.put("source", "Sparking game database").put("sourceType", "sparking-current").put("date", com.personal.aihub.CreatorActivity.isoStamp()).put("count", v1_19).put("assetsManifest", v0_17));
                org.json.JSONObject v0_5 = this.sparkingDb;
                if (v0_5 != null) {
                    v0_5.close();
                }
                this.sparkingDb = 0;
                this.sparkingSchema = 0;
                this.progress("done", "Sparking characters are ready in Library", 0, 0);
                org.json.JSONObject v0_9 = this.sparkingInfo();
                java.util.Arrays.fill(v9, 0);
                com.personal.aihub.CreatorActivity.deleteTree(v10_1);
                return v0_9;
            }
        }
    }

    private org.json.JSONObject useDb(java.io.File p2, String p3)
    {
        return this.useDb(p2, p3, new org.json.JSONObject());
    }

    private org.json.JSONObject useDb(java.io.File p5, String p6, org.json.JSONObject p7)
    {
        try {
            this.ensureDb();
            this.dataStore().commit(p5, new org.json.JSONObject(p7.toString()).put("source", p6).put("date", com.personal.aihub.CreatorActivity.isoStamp()).put("count", this.verifyDb(p5, 0)));
            new java.io.File(this.root, "animation-files.json").delete();
            org.json.JSONObject v5_3 = this.db;
        } catch (org.json.JSONObject v5_6) {
            throw v5_6;
        }
        if (v5_3 != null) {
            v5_3.close();
        }
        this.db = 0;
        return this.info();
    }

    private static boolean validAnimationPath(String p2)
    {
        if ((p2 == 0) || ((p2.length() >= 240) || ((!p2.matches("(?i)ab_script/[a-z0-9_/-]+\\.lua")) || (!com.personal.aihub.CreatorActivity.safePath(p2))))) {
            int v2_2 = 0;
        } else {
            v2_2 = 1;
        }
        return v2_2;
    }

    private String verifiedMusicPath(String p7, String p8, String p9, String p10, org.json.JSONArray p11)
    {
        try {
            if ((p7.equals("lua")) && (p8.matches("ab_script/finish_skill/[A-Za-z0-9_]{1,80}\\.lua"))) {
                if (!p9.isEmpty()) {
                    byte[] v7_3 = new com.personal.aihub.GameAssets(this.assets, p10, p11);
                    java.io.File v10_2 = new StringBuilder("lua/");
                    v10_2.append(p8);
                    byte[] v7_4 = v7_3.read(v10_2.toString(), 2097152);
                    if (v7_4 == null) {
                        byte[] v7_6 = this.dataStore().meta();
                        byte[] v7_9 = v7_6.optString("date", v7_6.optString("sha256", "bundled")).replaceAll("[^a-zA-Z0-9_-]", "");
                        if (v7_9.length() > 80) {
                            v7_9 = v7_9.substring(0, 80);
                        }
                        java.io.File v10_9 = new java.io.File(new java.io.File(new java.io.File(this.root, "animation-sources"), v7_9), p8);
                        if (v10_9.isFile()) {
                            if (v10_9.length() <= 2097152) {
                                v7_4 = java.nio.file.Files.readAllBytes(v10_9.toPath());
                                if (!java.util.Arrays.equals(v7_4, p9.getBytes(java.nio.charset.StandardCharsets.UTF_8))) {
                                    p8 = "";
                                }
                                return p8;
                            } else {
                            }
                        }
                        return "";
                    }
                } else {
                    return p8;
                }
            } else {
                return "";
            }
        } catch (Exception) {
            return "";
        }
    }

    private long verifyDb(java.io.File p28, boolean p29)
    {
        int v4 = 1;
        Throwable v2_2 = android.database.sqlite.SQLiteDatabase.openDatabase(p28.getPath(), 0, 1);
        try {
            long v5_0 = v2_2.rawQuery("PRAGMA quick_check", 0);
            try {
                if ((!v5_0.moveToFirst()) || (!"ok".equals(v5_0.getString(0)))) {
                    throw new java.io.IOException("Database integrity check failed");
                } else {
                    if (v5_0 != 0) {
                        v5_0.close();
                    }
                    String v10 = "name";
                    String v12 = "element";
                    String v14 = "hp_max";
                    String v16 = "def_max";
                    String[] v21 = new String[] {"link_skills", "id", "name"});
                    String[] v24 = new String[] {"passive_skill_sets", "id"});
                    int v1_6 = 0;
                    while (v1_6 < 8) {
                        long v5_1 = new String[][] {new String[] {"cards", "leader_skill_set_id"}), new String[] {"passive_skill_set_relations", "id", "passive_skill_set_id", "passive_skill_id"})})[v1_6];
                        android.database.Cursor v6_1 = new java.util.HashSet();
                        boolean v8_1 = new StringBuilder();
                        v8_1.append("PRAGMA table_info(");
                        v8_1.append(com.personal.aihub.CreatorActivity.identifier(v5_1[0]));
                        v8_1.append(")");
                        boolean v8_3 = v2_2.rawQuery(v8_1.toString(), 0);
                        try {
                            while (v8_3.moveToNext()) {
                                v6_1.add(v8_3.getString(1));
                            }
                        } catch (Throwable v0_1) {
                            int v1_1 = v0_1;
                            if (v8_3) {
                                try {
                                    v8_3.close();
                                } catch (Throwable v0_2) {
                                    v1_1.addSuppressed(v0_2);
                                }
                            }
                            throw v1_1;
                        }
                        if (v8_3) {
                            v8_3.close();
                        }
                        boolean v8_4 = 1;
                        while (v8_4 < v5_1.length) {
                            if (!v6_1.contains(v5_1[v8_4])) {
                                int v1_8 = new StringBuilder();
                                v1_8.append("Database is missing game fields: ");
                                v1_8.append(v5_1[0]);
                                throw new java.io.IOException(v1_8.toString());
                            } else {
                                v8_4++;
                            }
                        }
                        android.database.Cursor v6_5 = v2_2.rawQuery("SELECT type FROM sqlite_master WHERE name=?", new String[] {v5_1[0]}));
                        try {
                            if ((!v6_5.moveToFirst()) || (!"table".equals(v6_5.getString(0)))) {
                                int v1_3 = new StringBuilder();
                                v1_3.append("Expected game data table: ");
                                v1_3.append(v5_1[0]);
                                throw new java.io.IOException(v1_3.toString());
                            } else {
                                if (v6_5 != null) {
                                    v6_5.close();
                                }
                                v1_6++;
                            }
                        } catch (Throwable v0_5) {
                            int v1_5 = v0_5;
                            if (v6_5 != null) {
                                try {
                                    v6_5.close();
                                } catch (Throwable v0_6) {
                                    v1_5.addSuppressed(v0_6);
                                }
                            }
                            throw v1_5;
                        }
                    }
                    int v1_13 = v2_2.rawQuery("SELECT count(*) FROM cards", 0);
                    try {
                        v1_13.moveToFirst();
                        long v5_8 = v1_13.getLong(0);
                    } catch (Throwable v0_25) {
                        Throwable v3_10 = v0_25;
                        if (v1_13 != 0) {
                            try {
                                v1_13.close();
                            } catch (Throwable v0_26) {
                                v3_10.addSuppressed(v0_26);
                            }
                        }
                        throw v3_10;
                    }
                    if (p29) {
                        v4 = 1000;
                    }
                    if (v5_8 < ((long) v4)) {
                        throw new java.io.IOException("The database contains starter or incomplete card data");
                    } else {
                        if (v1_13 != 0) {
                            v1_13.close();
                        }
                        if (v2_2 != null) {
                            v2_2.close();
                        }
                        return v5_8;
                    }
                }
            } catch (Throwable v0_13) {
                int v1_12 = v0_13;
                if (v5_0 != 0) {
                    try {
                        v5_0.close();
                    } catch (Throwable v0_14) {
                        v1_12.addSuppressed(v0_14);
                    }
                }
                throw v1_12;
            }
        } catch (Throwable v0_9) {
            int v1_10 = v0_9;
            if (v2_2 != null) {
                try {
                    v2_2.close();
                } catch (Throwable v0_10) {
                    v1_10.addSuppressed(v0_10);
                }
            }
            throw v1_10;
        }
    }

    private void verifyDb(java.io.File p2)
    {
        this.verifyDb(p2, 0);
        return;
    }

    private org.json.JSONObject writeExport(android.net.Uri p20, org.json.JSONObject p21)
    {
        android.net.Uri v5_4 = this.getCacheDir();
        long v6_6 = new StringBuilder("forge-export-cpk-");
        v6_6.append(java.util.UUID.randomUUID());
        Throwable v4_1 = new java.io.File(v5_4, v6_6.toString());
        if (!v4_1.mkdirs()) {
            throw new java.io.IOException("Cannot prepare artwork export.");
        } else {
            android.net.Uri v5_3 = new java.io.File(v4_1, "prepared-export.bin");
            try {
                long v6_4 = new java.io.FileOutputStream(v5_3);
                try {
                    long v11_0;
                    if (!p21.has("patchKey")) {
                        int v8_0 = 0;
                        if (!p21.optString("kind").equals("eclp")) {
                            try {
                                if (!p21.optString("kind").equals("zip")) {
                                    v11_0 = v4_1;
                                    v6_4.write(p21.optString("text").getBytes(java.nio.charset.StandardCharsets.UTF_8));
                                } else {
                                    org.json.JSONObject v2_27 = new java.util.zip.ZipOutputStream(v6_4);
                                    try {
                                        Throwable v3_3 = p21.getJSONArray("entries");
                                        java.util.HashSet v9_4 = new java.util.HashSet();
                                    } catch (Throwable v0_3) {
                                        v11_0 = v4_1;
                                        Throwable v3_4 = v0_3;
                                        try {
                                            v2_27.close();
                                        } catch (Throwable v0_4) {
                                            v3_4.addSuppressed(v0_4);
                                        }
                                        throw v3_4;
                                    }
                                    while (v8_0 < v3_3.length()) {
                                        String v13_9 = v3_3.getJSONObject(v8_0);
                                        long v15_4 = v13_9.getString("path");
                                        try {
                                            if ((!com.personal.aihub.CreatorActivity.safePath(v15_4)) || (!v9_4.add(v15_4))) {
                                                v11_0 = v4_1;
                                                throw new java.io.IOException("Invalid or duplicate patch path");
                                            } else {
                                                long v15_0;
                                                long v11_4 = this.exportSource(v13_9, v4_1, v8_0);
                                                v2_27.putNextEntry(new java.util.zip.ZipEntry(v15_4));
                                                if (v11_4 == 0) {
                                                    v15_0 = v3_3;
                                                    v11_0 = v4_1;
                                                    v2_27.write(v13_9.optString("text").getBytes(java.nio.charset.StandardCharsets.UTF_8));
                                                } else {
                                                    java.io.FileInputStream v12_1 = new java.io.FileInputStream(v11_4);
                                                    v15_0 = v3_3;
                                                    v11_0 = v4_1;
                                                    try {
                                                        com.personal.aihub.CreatorActivity.copy(v12_1, v2_27, 1073741824);
                                                    } catch (Throwable v0_1) {
                                                        Throwable v3_2 = v0_1;
                                                        try {
                                                            v12_1.close();
                                                        } catch (Throwable v0_2) {
                                                            v3_2.addSuppressed(v0_2);
                                                        }
                                                        throw v3_2;
                                                    }
                                                    v12_1.close();
                                                }
                                                v2_27.closeEntry();
                                                v8_0++;
                                                v4_1 = v11_0;
                                                v3_3 = v15_0;
                                                v11_0 = 4294967296;
                                            }
                                        } catch (Throwable v0_3) {
                                        }
                                    }
                                    v11_0 = v4_1;
                                    v2_27.close();
                                }
                            } catch (Throwable v0_5) {
                                org.json.JSONObject v2_1 = v0_5;
                                try {
                                    v6_4.close();
                                } catch (Throwable v0_15) {
                                    v2_1.addSuppressed(v0_15);
                                }
                                throw v2_1;
                            }
                        } else {
                            org.json.JSONObject v2_2 = p21.getJSONArray("entries");
                            java.util.HashSet v9_1 = new java.util.ArrayList();
                            Throwable v3_6 = p21.optJSONObject("metadata");
                            long v11_2 = new java.util.HashSet();
                            while (v8_0 < v2_2.length()) {
                                long v15_2 = v2_2.getJSONObject(v8_0);
                                java.io.FileInputStream v12_3 = v15_2.getString("path");
                                if ((!com.personal.aihub.CreatorActivity.safePath(v12_3)) || (!v11_2.add(v12_3))) {
                                    throw new java.io.IOException("Unsafe or duplicate ECLP path.");
                                } else {
                                    if ((v12_3.equals("metadata.json")) && (v3_6 == null)) {
                                        v3_6 = new org.json.JSONObject(v15_2.getString("text"));
                                    }
                                    String v17 = v2_2;
                                    java.io.OutputStream v18 = v3_6;
                                    v9_1.add(new com.personal.aihub.EclpCodec$Entry(v12_3, this.exportSource(v15_2, v4_1, v8_0), v15_2.optString("text").getBytes(java.nio.charset.StandardCharsets.UTF_8)));
                                    v8_0++;
                                    v2_2 = v17;
                                    v3_6 = v18;
                                }
                            }
                            if (v3_6 == null) {
                                throw new java.io.IOException("Missing ECLP metadata");
                            } else {
                                com.personal.aihub.EclpCodec.write(v6_4, this.getCacheDir(), v9_1, v3_6.toString(), v3_6.getString("uuid"), v3_6.getString("name"), v3_6.getString("version"));
                                v11_0 = v4_1;
                            }
                        }
                    } else {
                        org.json.JSONObject v2_11 = new java.io.FileInputStream(this.patchFile(p21.getString("patchKey")));
                        try {
                            com.personal.aihub.CreatorActivity.copy(v2_11, v6_4, 4294967296);
                        } catch (Throwable v0_11) {
                            Throwable v3_12 = v0_11;
                            try {
                                v2_11.close();
                            } catch (Throwable v0_13) {
                                v3_12.addSuppressed(v0_13);
                            }
                            throw v3_12;
                        }
                        v2_11.close();
                    }
                } catch (Throwable v0_5) {
                    v11_0 = v4_1;
                } catch (Throwable v0_14) {
                    v2_1 = v0_14;
                    v11_0 = v4_1;
                } catch (Throwable v0_26) {
                    com.personal.aihub.CreatorActivity.deleteTree(v11_0);
                    throw v0_26;
                }
                v6_4.close();
                if (v5_3.length() > 4294967296) {
                    throw new java.io.IOException("Export exceeds the 4 GB output limit.");
                } else {
                    org.json.JSONObject v2_17 = new java.io.FileInputStream(v5_3);
                    try {
                        Throwable v3_15 = this.getContentResolver().openOutputStream(p20, "w");
                        try {
                            if (v3_15 == null) {
                                throw new java.io.IOException("Cannot write this destination.");
                            } else {
                                com.personal.aihub.CreatorActivity.copy(v2_17, v3_15, 4294967296);
                                if (v3_15 != null) {
                                    v3_15.close();
                                }
                                v2_17.close();
                                Throwable v0_25 = new org.json.JSONObject().put("saved", 1).put("name", p21.optString(String v14));
                                com.personal.aihub.CreatorActivity.deleteTree(v11_0);
                                return v0_25;
                            }
                        } catch (Throwable v0_20) {
                            Throwable v4_5 = v0_20;
                            if (v3_15 != null) {
                                try {
                                    v3_15.close();
                                } catch (Throwable v0_21) {
                                    v4_5.addSuppressed(v0_21);
                                }
                            }
                            throw v4_5;
                        }
                    } catch (Throwable v0_22) {
                        Throwable v3_17 = v0_22;
                        try {
                            v2_17.close();
                        } catch (Throwable v0_23) {
                            v3_17.addSuppressed(v0_23);
                        }
                        throw v3_17;
                    }
                }
            } catch (Throwable v0_26) {
                v11_0 = v4_1;
            }
        }
    }

    private static void writeText(java.io.File p1, String p2)
    {
        java.io.FileOutputStream v0_0 = p1.getParentFile();
        if (v0_0 != null) {
            v0_0.mkdirs();
        }
        java.io.FileOutputStream v0_2 = new java.io.FileOutputStream(p1);
        try {
            v0_2.write(p2.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            v0_2.close();
            return;
        } catch (Throwable v1_1) {
            try {
                v0_2.close();
            } catch (Throwable v2_1) {
                v1_1.addSuppressed(v2_1);
            }
            throw v1_1;
        }
    }

    public java.io.File assetFile(String p4)
    {
        if (!com.personal.aihub.CreatorActivity.safePath(p4)) {
            throw new java.io.IOException("Invalid asset key");
        } else {
            String v0_4 = new java.io.File(this.assets, p4);
            java.io.IOException v4_1 = v0_4.getCanonicalPath();
            String v1_1 = new StringBuilder();
            v1_1.append(String.valueOf(this.assets.getCanonicalPath()));
            v1_1.append(java.io.File.separator);
            if (!v4_1.startsWith(v1_1.toString())) {
                throw new java.io.IOException("Unsafe path");
            } else {
                return v0_4;
            }
        }
    }

    public Object dispatch(String p7, org.json.JSONObject p8)
    {
        String v0_22 = com.personal.aihub.ForgeFixes.dispatch(this.root, p7, p8);
        if (v0_22 == null) {
            if (!p7.equals("aiCompose")) {
                com.personal.aihub.CreatorActivity$7 v1_0 = 0;
                if (!p7.equals("openEclipse")) {
                    if (!p7.equals("sparkingInfo")) {
                        if ((!p7.equals("animationFiles")) || (!"sparking".equals(p8.optString("sourceDatabase")))) {
                            if (!p7.equals("updateSparking")) {
                                if (!p7.equals("downloadSparkingAssets")) {
                                    org.json.JSONObject v3_6 = 0;
                                    if (!p7.equals("sparkingAudioCatalog")) {
                                        if (!p7.equals("findSparkingAssets")) {
                                            if (!p7.equals("querySparking")) {
                                                if ((!p7.equals("listProjectVersions")) && ((!p7.equals("saveProjectVersion")) && ((!p7.equals("loadProjectVersion")) && (!p7.equals("restoreProjectVersion"))))) {
                                                    if (!p7.equals("storeDecoration")) {
                                                        if (!p7.equals("assetStatus")) {
                                                            switch (p7.hashCode()) {
                                                                case -2049564681:
                                                                    if (!p7.equals("importStatus")) {
                                                                    } else {
                                                                        return this.importProgress;
                                                                    }
                                                                case -1820761141:
                                                                    if (!p7.equals("external")) {
                                                                    } else {
                                                                        java.io.IOException v7_82;
                                                                        java.io.IOException v7_74 = p8.getString("target");
                                                                        if (!v7_74.equals("converter")) {
                                                                            if (!v7_74.equals("documentation")) {
                                                                                if (!v7_74.equals("downloads")) {
                                                                                    if (!v7_74.equals("files")) {
                                                                                        if (!v7_74.equals("sparkingLicense")) {
                                                                                            if (!v7_74.equals("sparkingWiki")) {
                                                                                                throw new java.io.IOException("Unknown destination");
                                                                                            } else {
                                                                                                java.io.IOException v7_79 = p8.optString("revision");
                                                                                                if (!v7_79.matches("[1-9][0-9]{0,14}")) {
                                                                                                    throw new java.io.IOException("Invalid wiki revision");
                                                                                                } else {
                                                                                                    String v8_37 = new StringBuilder("https://dokkansparking.miraheze.org/w/index.php?oldid=");
                                                                                                    v8_37.append(v7_79);
                                                                                                    v7_82 = v8_37.toString();
                                                                                                }
                                                                                            }
                                                                                        } else {
                                                                                            v7_82 = "https://creativecommons.org/licenses/by-sa/4.0/";
                                                                                        }
                                                                                    } else {
                                                                                        v7_82 = "https://dokkan-eclipse.com/files";
                                                                                    }
                                                                                } else {
                                                                                    v7_82 = "https://dokkan-eclipse.com/downloads";
                                                                                }
                                                                            } else {
                                                                                v7_82 = "https://dokkan-eclipse.com/wiki/documentation";
                                                                            }
                                                                        } else {
                                                                            v7_82 = "https://dokkan-eclipse.com/#convert-eclp";
                                                                        }
                                                                        this.runOnUiThread(new com.personal.aihub.CreatorActivity$4(this, v7_82));
                                                                        return new org.json.JSONObject().put("opened", 1);
                                                                    }
                                                                case -1470545581:
                                                                    if (!p7.equals("animationFiles")) {
                                                                    } else {
                                                                        return this.animationFiles(p8.optBoolean("refresh"));
                                                                    }
                                                                case -1408207997:
                                                                    if (!p7.equals("assets")) {
                                                                    } else {
                                                                        return com.personal.aihub.AssetIndex.list(this.assets, p8);
                                                                    }
                                                                case -1389102950:
                                                                    if (!p7.equals("previewCache")) {
                                                                    } else {
                                                                        return new com.personal.aihub.PreviewCache(new java.io.File(this.getFilesDir(), "forge")).settings(p8);
                                                                    }
                                                                case -1372974349:
                                                                    if (!p7.equals("previewTools")) {
                                                                    } else {
                                                                        return new com.personal.aihub.PreviewTools(this, new java.io.File(this.getFilesDir(), "forge")).request(p8);
                                                                    }
                                                                case -1141166342:
                                                                    if (!p7.equals("readAsset")) {
                                                                    } else {
                                                                        return new com.personal.aihub.ImageAssets(this.assets).read(p8);
                                                                    }
                                                                case -998696838:
                                                                    if (!p7.equals("projects")) {
                                                                    } else {
                                                                        return this.listProjects();
                                                                    }
                                                                case -822087853:
                                                                    if (!p7.equals("loadProject")) {
                                                                    } else {
                                                                        return new org.json.JSONObject(com.personal.aihub.CreatorActivity.readText(this.projectFile(p8.getString("key")), 20971520));
                                                                    }
                                                                case -791594250:
                                                                    if (!p7.equals("patches")) {
                                                                    } else {
                                                                        return this.listPatches();
                                                                    }
                                                                case -373212065:
                                                                    if (!p7.equals("assetUrl")) {
                                                                    } else {
                                                                        java.io.IOException v7_53 = new StringBuilder("https://forge.local/local-asset/");
                                                                        v7_53.append(android.net.Uri.encode(p8.getString("key"), "/"));
                                                                        return v7_53.toString();
                                                                    }
                                                                case -289138532:
                                                                    if (!p7.equals("previewAnimation")) {
                                                                    } else {
                                                                        return this.previewAnimation(p8);
                                                                    }
                                                                case 3112:
                                                                    if (!p7.equals("ai")) {
                                                                    } else {
                                                                        this.runOnUiThread(new com.personal.aihub.CreatorActivity$5(this));
                                                                        return new org.json.JSONObject().put("opened", 1);
                                                                    }
                                                                case 3059573:
                                                                    if (!p7.equals("copy")) {
                                                                    } else {
                                                                        this.runOnUiThread(new com.personal.aihub.CreatorActivity$6(this, p8.optString("text")));
                                                                        return new org.json.JSONObject().put("copied", 1);
                                                                    }
                                                                case 3237038:
                                                                    if (!p7.equals("info")) {
                                                                    } else {
                                                                        return this.info();
                                                                    }
                                                                case 3545755:
                                                                    if (!p7.equals("sync")) {
                                                                    } else {
                                                                        return this.syncDatabase();
                                                                    }
                                                                case 4147016:
                                                                    if (!p7.equals("downloadAsset")) {
                                                                    } else {
                                                                        return this.downloadAsset(p8.getString("path"), p8.optString("group", 0));
                                                                    }
                                                                case 107944136:
                                                                    if (!p7.equals("query")) {
                                                                    } else {
                                                                        return this.query(p8);
                                                                    }
                                                                case 116513321:
                                                                    if (!p7.equals("restoreDatabase")) {
                                                                    } else {
                                                                        return this.restoreDatabase();
                                                                    }
                                                                case 368211629:
                                                                    if (!p7.equals("browseAssets")) {
                                                                    } else {
                                                                        java.io.IOException v7_28 = p8.optString("path");
                                                                        if ((!v7_28.isEmpty()) && (!com.personal.aihub.CreatorActivity.safePath(v7_28))) {
                                                                            throw new java.io.IOException("Invalid resource path");
                                                                        } else {
                                                                            String v0_31 = new StringBuilder("https://dokkan-eclipse.com/api/file-browser?path=");
                                                                            v0_31.append(android.net.Uri.encode(v7_28));
                                                                            return new org.json.JSONObject(this.fetchText(v0_31.toString(), 8388608));
                                                                        }
                                                                    }
                                                                case 381348572:
                                                                    if (!p7.equals("saveProject")) {
                                                                    } else {
                                                                        return this.saveProject(p8.getJSONObject("project"));
                                                                    }
                                                                case 894199439:
                                                                    if (!p7.equals("storeAsset")) {
                                                                    } else {
                                                                        return new com.personal.aihub.ImageAssets(this.assets).store(p8);
                                                                    }
                                                                case 905165519:
                                                                    if (!p7.equals("storeMovie")) {
                                                                    } else {
                                                                        if (this.movieUploads == null) {
                                                                            this.movieUploads = new com.personal.aihub.MovieStorage(this.assets.getCanonicalFile());
                                                                        }
                                                                        return this.movieUploads.call(p8);
                                                                    }
                                                                case 951590323:
                                                                    if (!p7.equals("convert")) {
                                                                    } else {
                                                                        java.io.IOException v7_11 = java.util.UUID.randomUUID().toString();
                                                                        String v0_13 = new java.io.File(new java.io.File(this.getCacheDir(), "converter"), v7_11);
                                                                        v0_13.mkdirs();
                                                                        com.personal.aihub.CreatorActivity$7 v1_4 = new java.io.File(v0_13, "unit-patch.zip");
                                                                        org.json.JSONObject v3_3 = new org.json.JSONObject(p8.toString());
                                                                        v3_3.put("kind", "zip");
                                                                        try {
                                                                            this.writeExport(android.net.Uri.fromFile(v1_4), v3_3);
                                                                            this.runOnUiThread(new com.personal.aihub.CreatorActivity$7(this, v7_11, p8.getJSONObject("patch").toString()));
                                                                            return new org.json.JSONObject().put("opened", 1);
                                                                        } catch (java.io.IOException v7_15) {
                                                                            com.personal.aihub.CreatorActivity.deleteTree(v0_13);
                                                                            throw v7_15;
                                                                        }
                                                                    }
                                                                case 1172021519:
                                                                    if (!p7.equals("animationVisuals")) {
                                                                    } else {
                                                                        return this.animationVisuals(p8.optLong("unitId"));
                                                                    }
                                                                case 1260625909:
                                                                    if (!p7.equals("animationCatalog")) {
                                                                    } else {
                                                                        return this.animationCatalog(p8);
                                                                    }
                                                                case 1717140378:
                                                                    if (!p7.equals("storeLwf")) {
                                                                    } else {
                                                                        return com.personal.aihub.LwfStorage.store(this.assets, p8);
                                                                    }
                                                                case 2035727551:
                                                                    if (!p7.equals("animationSource")) {
                                                                    } else {
                                                                        if (!"sparking".equals(p8.optString("sourceDatabase"))) {
                                                                            return this.animationSource(p8.getString("path"), p8.optString("assetKey"), p8.optBoolean("originalOnly", 0));
                                                                        } else {
                                                                            return this.sparkingAnimationSource(p8.getString("path"), p8.optString("assetKey"));
                                                                        }
                                                                    }
                                                                default:
                                                            }
                                                            String v0_93 = new StringBuilder("Unsupported action: ");
                                                            v0_93.append(p7);
                                                            throw new java.io.IOException(v0_93.toString());
                                                        } else {
                                                            return com.personal.aihub.ExportAssetAudit.check(this.assets, p8.getJSONArray("keys"));
                                                        }
                                                    } else {
                                                        return com.personal.aihub.DecorationStorage.store(this.assets, p8);
                                                    }
                                                } else {
                                                    try {
                                                        com.personal.aihub.CreatorActivity$7 v1_14 = p8.getString("key");
                                                        String v2_4 = new com.personal.aihub.ProjectVersions(this.root, this.projectFile(v1_14), v1_14);
                                                    } catch (java.io.IOException v7_97) {
                                                        throw v7_97;
                                                    }
                                                    if (!p7.equals("listProjectVersions")) {
                                                        if (!p7.equals("saveProjectVersion")) {
                                                            if (!p7.equals("loadProjectVersion")) {
                                                                return v2_4.restore(p8);
                                                            } else {
                                                                return v2_4.load(p8);
                                                            }
                                                        } else {
                                                            return v2_4.save(p8);
                                                        }
                                                    } else {
                                                        return v2_4.list();
                                                    }
                                                }
                                            } else {
                                                this.ensureSparkingDb();
                                                return this.queryDatabase(this.sparkingDb, this.sparkingSchema, p8);
                                            }
                                        } else {
                                            String v0_100 = new org.json.JSONObject(com.personal.aihub.CreatorActivity.readText(this.sparkingAssetManifest(p8.optLong("version", -1)), 33554432));
                                            java.io.IOException v7_104 = new java.util.HashSet();
                                            String v0_102 = v0_100.getJSONArray("assets");
                                            String v2_8 = 0;
                                            while (v2_8 < v0_102.length()) {
                                                v7_104.add(v0_102.getJSONObject(v2_8).optString("file_path"));
                                                v2_8++;
                                            }
                                            String v8_46 = p8.getJSONArray("paths");
                                            String v0_105 = new org.json.JSONArray();
                                            String v2_10 = new org.json.JSONArray();
                                            if (v8_46.length() > 128) {
                                                throw new java.io.IOException("Choose fewer game resources at a time.");
                                            }
                                            while (v1_0 < v8_46.length()) {
                                                org.json.JSONObject v3_11 = v8_46.getString(v1_0);
                                                if (!com.personal.aihub.CreatorActivity.safePath(v3_11)) {
                                                    throw new java.io.IOException("Invalid resource path.");
                                                } else {
                                                    String v4_8;
                                                    if (!v7_104.contains(v3_11)) {
                                                        v4_8 = v2_10;
                                                    } else {
                                                        v4_8 = v0_105;
                                                    }
                                                    v4_8.put(v3_11);
                                                    v1_0++;
                                                }
                                            }
                                            return new org.json.JSONObject().put("available", v0_105).put("missing", v2_10);
                                        }
                                    } else {
                                        if (p8.has("version")) {
                                            v3_6 = p8.get("version");
                                        }
                                        java.io.IOException v7_116 = com.personal.aihub.PreviewMetadata.normalizeVersion(v3_6);
                                        if (v7_116 <= 0) {
                                            throw new java.io.IOException("Choose a recorded Sparking content version before preparing its audio.");
                                        } else {
                                            return new org.json.JSONObject().put("version", v7_116).put("files", com.personal.aihub.SparkingContent.audioRecords(new org.json.JSONObject(com.personal.aihub.CreatorActivity.readText(this.sparkingAssetManifest(v7_116), 33554432))));
                                        }
                                    }
                                } else {
                                    return this.downloadSparkingAssets(p8);
                                }
                            } else {
                                return this.updateSparking();
                            }
                        } else {
                            return this.sparkingAnimationFiles();
                        }
                    } else {
                        return this.sparkingInfo();
                    }
                } else {
                    java.io.IOException v7_126 = this.getPackageManager().getLaunchIntentForPackage("com.anthen.eclipse");
                    if (v7_126 != null) {
                        v1_0 = 1;
                    }
                    if (v1_0 == null) {
                        v7_126 = new android.content.Intent("android.intent.action.VIEW", android.net.Uri.parse("https://dokkan-eclipse.com/downloads"));
                    }
                    this.runOnUiThread(new com.personal.aihub.CreatorActivity$$ExternalSyntheticLambda2(this, v7_126));
                    return new org.json.JSONObject().put("requested", 1).put("installed", v1_0);
                }
            } else {
                return com.personal.aihub.AiHandoff.compose(this, p8);
            }
        } else {
            return v0_22;
        }
    }

    synthetic void lambda$dispatch$0$com-personal-aihub-CreatorActivity(android.content.Intent p2)
    {
        if ((!this.isFinishing()) && (!this.isDestroyed())) {
            try {
                this.startActivity(p2);
            } catch (Exception) {
                android.widget.Toast.makeText(this, "Could not open Eclipse. Open it from your device\'s app list.", 1).show();
            }
        }
        return;
    }

    synthetic void lambda$downloadSparkingAssets$5$com-personal-aihub-CreatorActivity(String p8, long p9, long p11)
    {
        this.progress("download", "Downloading Sparking game resources", p9, p11);
        return;
    }

    synthetic void lambda$sparkingAnimationSource$2$com-personal-aihub-CreatorActivity(String p8, long p9, long p11)
    {
        this.progress("download", "Downloading the original Sparking animation", p9, p11);
        return;
    }

    synthetic void lambda$sparkingAssetManifest$4$com-personal-aihub-CreatorActivity(String p8, long p9, long p11)
    {
        this.progress("manifest", "Opening Sparking resources", p9, p11);
        return;
    }

    synthetic void lambda$sparkingBaseScripts$1$com-personal-aihub-CreatorActivity(String p8, long p9, long p11)
    {
        this.progress("download", "Preparing Sparking\'s original animation collection", p9, p11);
        return;
    }

    synthetic void lambda$updateSparking$3$com-personal-aihub-CreatorActivity(String p9, long p10, long p12)
    {
        String v0_2;
        if (!p9.equals("manifest")) {
            v0_2 = "Downloading Sparking characters";
        } else {
            v0_2 = "Reading Sparking\'s game-content list";
        }
        this.progress(p9, v0_2, p10, p12);
        return;
    }

    void m10lambda$11$compersonalaihubCreatorActivity()
    {
        android.database.sqlite.SQLiteDatabase v0_0 = this.sparkingDb;
        if (v0_0 != null) {
            v0_0.close();
            this.sparkingDb = 0;
        }
        android.database.sqlite.SQLiteDatabase v0_1 = this.db;
        if (v0_1 != null) {
            v0_1.close();
            this.db = 0;
        }
        return;
    }

    void m11lambda$2$compersonalaihubCreatorActivity(int p9, Exception p10, Object p11)
    {
        try {
            if ((this.web != null) && (!this.isFinishing())) {
                if (!this.isDestroyed()) {
                    String v7_2;
                    String v4_3 = new org.json.JSONObject();
                    v4_3.put("id", p9);
                    StringBuilder v6_2 = 0;
                    if (p10 != null) {
                        v7_2 = 0;
                    } else {
                        v7_2 = 1;
                    }
                    v4_3.put("ok", v7_2);
                    if (p10 != null) {
                        android.webkit.WebView v10_3;
                        if (p10.getMessage() != null) {
                            v10_3 = p10.getMessage();
                        } else {
                            v10_3 = "The operation failed.";
                        }
                        v4_3.put("error", v10_3);
                    } else {
                        if (p11 == null) {
                            p11 = org.json.JSONObject.NULL;
                        }
                        v4_3.put("result", p11);
                    }
                    android.webkit.WebView v10_5 = v4_3.toString();
                    String v11_6 = new StringBuilder("Reply ");
                    v11_6.append(p9);
                    v11_6.append(" chars=");
                    v11_6.append(v10_5.length());
                    android.util.Log.d("ForgeBridge", v11_6.toString());
                    if (v10_5.length() >= 24000) {
                        String v11_9 = String.valueOf(p9);
                        android.webkit.WebView v2_1 = this.web;
                        String v4_7 = new StringBuilder("window.__forgeReplyParts=window.__forgeReplyParts||{};window.__forgeReplyParts[");
                        v4_7.append(v11_9);
                        v4_7.append("]=[]");
                        v2_1.evaluateJavascript(v4_7.toString(), 0);
                        while (v6_2 < v10_5.length()) {
                            int v1_10 = Math.min((v6_2 + 24000), v10_5.length());
                            if ((v1_10 < v10_5.length()) && (Character.isHighSurrogate(v10_5.charAt((v1_10 - 1))))) {
                                v1_10--;
                            }
                            android.webkit.WebView v2_9 = this.web;
                            String v4_10 = new StringBuilder();
                            v4_10.append("window.__forgeReplyParts[");
                            v4_10.append(v11_9);
                            v4_10.append("].push(");
                            v4_10.append(org.json.JSONObject.quote(v10_5.substring(v6_2, v1_10)));
                            v4_10.append(")");
                            v2_9.evaluateJavascript(v4_10.toString(), 0);
                            v6_2 = v1_10;
                        }
                        android.webkit.WebView v10_6 = this.web;
                        int v1_8 = new StringBuilder();
                        v1_8.append("window.__forgeReply(JSON.parse(window.__forgeReplyParts[");
                        v1_8.append(v11_9);
                        v1_8.append("].join(\'\')));delete window.__forgeReplyParts[");
                        v1_8.append(v11_9);
                        v1_8.append("]");
                        v10_6.evaluateJavascript(v1_8.toString(), 0);
                        return;
                    } else {
                        String v11_1 = this.web;
                        int v1_2 = new StringBuilder("window.__forgeReply(");
                        v1_2.append(v10_5);
                        v1_2.append(")");
                        v11_1.evaluateJavascript(v1_2.toString(), 0);
                        return;
                    }
                } else {
                }
            }
        } catch (android.webkit.WebView v10_2) {
            String v11_3 = new StringBuilder("Could not deliver reply ");
            v11_3.append(p9);
            v11_3.append(": ");
            v11_3.append(v10_2.getClass().getSimpleName());
            android.util.Log.e("ForgeBridge", v11_3.toString());
            return;
        }
        return;
    }

    void m12lambda$3$compersonalaihubCreatorActivity(String p3, String p4)
    {
        this.startActivity(new android.content.Intent(this, com.personal.aihub.ConverterActivity).putExtra("token", p3).putExtra("patch", p4));
        return;
    }

    void m13lambda$4$compersonalaihubCreatorActivity()
    {
        this.startActivity(new android.content.Intent(this, com.personal.aihub.MainActivity));
        return;
    }

    void m14lambda$5$compersonalaihubCreatorActivity(String p3)
    {
        ((android.content.ClipboardManager) this.getSystemService("clipboard")).setPrimaryClip(android.content.ClipData.newPlainText("Dokkan unit design", p3));
        return;
    }

    void m15lambda$6$compersonalaihubCreatorActivity(String p3)
    {
        try {
            this.startActivity(new android.content.Intent("android.intent.action.VIEW", android.net.Uri.parse(p3)));
        } catch (Exception) {
        }
        return;
    }

    void m16lambda$7$compersonalaihubCreatorActivity(String p3)
    {
        if (!com.personal.aihub.ForgeFixes.openPreview(this, p3)) {
            this.startActivity(new android.content.Intent(this, com.personal.aihub.PreviewActivity).putExtra("token", p3));
            return;
        } else {
            return;
        }
    }

    void m17lambda$8$compersonalaihubCreatorActivity(int p3, android.net.Uri p4, org.json.JSONObject p5, String p6, int p7)
    {
        try {
            Exception v3_4;
            if (p3 != 502) {
                v3_4 = this.importUri(p4, p6.equals("importApk"));
                this.reply(p7, v3_4, 0);
            } else {
                v3_4 = this.writeExport(p4, p5);
            }
        } catch (Exception v3_1) {
            this.reply(p7, 0, v3_1);
        }
        return;
    }

    void m8lambda$0$compersonalaihubCreatorActivity()
    {
        try {
            this.movieUploads = new com.personal.aihub.MovieStorage(this.assets.getCanonicalFile());
        } catch (Exception) {
            this.movieUploads = 0;
        }
        return;
    }

    void m9lambda$10$compersonalaihubCreatorActivity(String p2)
    {
        if (!"true".equals(p2)) {
            this.finish();
            return;
        } else {
            return;
        }
    }

    protected void onActivityResult(int p9, int p10, android.content.Intent p11)
    {
        super.onActivityResult(p9, p10, p11);
        com.personal.aihub.ForgeFixes.activityResult(this, p9, p10, p11);
        if ((p9 == 501) || (p9 == 502)) {
            int v7 = this.pendingId;
            String v6 = this.pendingMethod;
            org.json.JSONObject v5 = this.pendingExport;
            this.pendingId = -1;
            this.pendingExport = 0;
            if (v7 >= 0) {
                if ((p10 == -1) && ((p11 != null) && (p11.getData() != null))) {
                    java.util.concurrent.ExecutorService v10_2 = this.worker;
                    com.personal.aihub.CreatorActivity$9 v11_1 = new com.personal.aihub.CreatorActivity$9;
                    v11_1(this, p9, p11.getData(), v5, v6, v7);
                    v10_2.execute(v11_1);
                } else {
                    this.reply(v7, new org.json.JSONObject(), 0);
                }
            } else {
                return;
            }
        }
        return;
    }

    public void onBackPressed()
    {
        if (this.web == null) {
            this.finish();
        } else {
            android.webkit.WebView v0_1 = this.startup;
            if ((v0_1 == null) || (v0_1.controlsReady())) {
                this.web.evaluateJavascript("Boolean(window.forgeHandleBack && window.forgeHandleBack())", new com.personal.aihub.CreatorActivity$11(this));
            }
        }
        return;
    }

    public void onCreate(android.os.Bundle p7)
    {
        super.onCreate(p7);
        this.root = new java.io.File(this.getFilesDir(), "forge");
        this.assets = new java.io.File(this.root, "assets");
        this.projects = new java.io.File(this.root, "projects");
        this.assets.mkdirs();
        this.projects.mkdirs();
        this.worker.execute(new com.personal.aihub.CreatorActivity$1(this));
        android.webkit.WebView v7_9 = new android.widget.FrameLayout(this);
        v7_9.setBackgroundColor(-15657702);
        this.setContentView(v7_9);
        if (android.os.Build$VERSION.SDK_INT >= 30) {
            this.getWindow().setDecorFitsSystemWindows(0);
            v7_9.setOnApplyWindowInsetsListener(new com.personal.aihub.CreatorActivity$2(this));
        }
        com.personal.aihub.CreatorActivity$$ExternalSyntheticLambda3 v1_7 = new android.webkit.WebView(this);
        this.web = v1_7;
        com.personal.aihub.ForgeFixes.configureWebView(this, v1_7);
        v7_9.addView(this.web, new android.widget.FrameLayout$LayoutParams(-1, -1));
        com.personal.aihub.CreatorActivity$$ExternalSyntheticLambda3 v1_10 = this.web.getSettings();
        v1_10.setJavaScriptEnabled(1);
        v1_10.setDomStorageEnabled(1);
        v1_10.setAllowFileAccess(0);
        v1_10.setAllowContentAccess(0);
        v1_10.setMixedContentMode(1);
        this.web.setBackgroundColor(-15657702);
        this.web.addJavascriptInterface(new com.personal.aihub.CreatorActivity$Bridge(this), "ForgeAndroid");
        this.web.setWebViewClient(new com.personal.aihub.CreatorActivity$AnonymousClass1(this));
        String v0_8 = new com.personal.aihub.WebViewStartup(this, v7_9, "your workspace", new com.personal.aihub.CreatorActivity$$ExternalSyntheticLambda3(this));
        this.startup = v0_8;
        v0_8.begin(this.web);
        this.web.loadUrl("https://forge.local/index.html");
        return;
    }

    protected void onDestroy()
    {
        int v0_0 = this.startup;
        if (v0_0 != 0) {
            v0_0.close();
        }
        this.worker.execute(new com.personal.aihub.CreatorActivity$12(this));
        this.worker.shutdown();
        int v0_5 = this.web;
        if (v0_5 != 0) {
            v0_5.removeJavascriptInterface("ForgeAndroid");
            this.web.destroy();
            this.web = 0;
        }
        super.onDestroy();
        return;
    }

    protected void onPause()
    {
        super.onPause();
        if (this.web != null) {
            android.webkit.WebView v0_1 = this.startup;
            if ((v0_1 == null) || (v0_1.controlsReady())) {
                this.web.evaluateJavascript("window.forgePersist && window.forgePersist()", 0);
            }
        }
        return;
    }

    public void pick(int p12, String p13, org.json.JSONObject p14)
    {
        if (this.pendingId == -1) {
            String v3_0;
            this.pendingId = p12;
            this.pendingMethod = p13;
            if (!p13.equals("export")) {
                v3_0 = 0;
            } else {
                v3_0 = p14;
            }
            this.pendingExport = v3_0;
            if (!p13.equals("export")) {
                String v3_4;
                if (!p13.equals("importApk")) {
                    v3_4 = "Choose a file to import";
                } else {
                    v3_4 = "Choose the latest Eclipse APK";
                }
                this.progress("select", v3_4, 0, 0);
            }
            String v4_2;
            if (!p13.equals("export")) {
                v4_2 = "android.intent.action.OPEN_DOCUMENT";
            } else {
                v4_2 = "android.intent.action.CREATE_DOCUMENT";
            }
            String v4_5;
            String v3_6 = new android.content.Intent(v4_2);
            v3_6.addCategory("android.intent.category.OPENABLE");
            if (!p13.equals("export")) {
                v4_5 = "*/*";
            } else {
                if (!p14.optString("kind").equals("zip")) {
                    v4_5 = "application/octet-stream";
                } else {
                    v4_5 = "application/zip";
                }
            }
            v3_6.setType(v4_5);
            if (p13.equals("export")) {
                v3_6.putExtra("android.intent.extra.TITLE", p14.optString("name", "custom-unit.json"));
            }
            try {
                int v13_2;
                if (!p13.equals("export")) {
                    v13_2 = 501;
                    this.startActivityForResult(v3_6, v13_2);
                } else {
                    v13_2 = 502;
                }
            } catch (int v13_3) {
                this.pendingId = -1;
                this.pendingExport = 0;
                this.reply(p12, 0, v13_3);
            }
            return;
        } else {
            this.reply(p12, 0, new java.io.IOException("Finish the existing file picker first."));
            return;
        }
    }

    public void reply(int p2, Object p3, Exception p4)
    {
        this.runOnUiThread(new com.personal.aihub.CreatorActivity$3(this, p2, p4, p3));
        return;
    }
}
