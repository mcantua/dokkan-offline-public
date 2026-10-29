package com.personal.aihub;
final class PreviewServer implements java.io.Closeable {
    static final long MAX_MOVIE = 167772160;
    static final long MAX_PREPARED = 536870912;
    private final com.personal.aihub.AudioBanks audioBanks;
    private final com.personal.aihub.PreviewBgm bgm;
    private final com.personal.aihub.PreviewCache cache;
    private final java.util.Set clients;
    private final android.content.Context context;
    final String cookie;
    private final org.json.JSONArray effectPacks;
    private final com.personal.aihub.GameAssets gameAssets;
    private final java.net.ServerSocket listener;
    private final java.io.File movieRoot;
    private final java.util.Map movies;
    final String origin;
    private final org.json.JSONArray overlays;
    private final String preferredKey;
    private long preparedBytes;
    private int preparing;
    private final String sourceDatabase;
    private final org.json.JSONArray sparkingEffectIds;
    private final long sparkingVersion;
    private volatile com.personal.aihub.StageCapture stageCapture;
    private volatile com.personal.aihub.StageExport stageExport;
    private boolean stopped;
    private final String token;
    private final java.util.concurrent.ThreadPoolExecutor workers;

    PreviewServer(android.content.Context p2, com.personal.aihub.PreviewCache p3)
    {
        this(p2, p3, "");
        return;
    }

    PreviewServer(android.content.Context p2, com.personal.aihub.PreviewCache p3, String p4)
    {
        this(p2, p3, p4, 0);
        return;
    }

    PreviewServer(android.content.Context p7, com.personal.aihub.PreviewCache p8, String p9, org.json.JSONArray p10)
    {
        this(p7, p8, p9, p10, 0);
        return;
    }

    PreviewServer(android.content.Context p8, com.personal.aihub.PreviewCache p9, String p10, org.json.JSONArray p11, org.json.JSONArray p12)
    {
        this(p8, p9, p10, p11, p12, "");
        return;
    }

    PreviewServer(android.content.Context p9, com.personal.aihub.PreviewCache p10, String p11, org.json.JSONArray p12, org.json.JSONArray p13, String p14)
    {
        this(p9, p10, p11, p12, p13, p14, "");
        return;
    }

    PreviewServer(android.content.Context p10, com.personal.aihub.PreviewCache p11, String p12, org.json.JSONArray p13, org.json.JSONArray p14, String p15, String p16)
    {
        this(p10, p11, p12, p13, p14, p15, p16, 0);
        return;
    }

    PreviewServer(android.content.Context p12, com.personal.aihub.PreviewCache p13, String p14, org.json.JSONArray p15, org.json.JSONArray p16, String p17, String p18, org.json.JSONArray p19)
    {
        this(p12, p13, p14, p15, p16, p17, p18, p19, 0);
        return;
    }

    PreviewServer(android.content.Context p17, com.personal.aihub.PreviewCache p18, String p19, org.json.JSONArray p20, org.json.JSONArray p21, String p22, String p23, org.json.JSONArray p24, long p25)
    {
        this.clients = new java.util.HashSet();
        this.movies = new java.util.HashMap();
        java.util.concurrent.ThreadPoolExecutor$AbortPolicy v6_2 = new StringBuilder();
        v6_2.append(String.valueOf(java.util.UUID.randomUUID().toString().replace("-", "")));
        v6_2.append(java.util.UUID.randomUUID().toString().replace("-", ""));
        this.token = v6_2.toString();
        java.util.concurrent.ThreadPoolExecutor$AbortPolicy v6_13 = p17.getApplicationContext();
        this.context = v6_13;
        this.cache = p18;
        this.preferredKey = p19;
        int v7_11 = com.personal.aihub.PreviewMetadata.normalizeSource(p23);
        this.sourceDatabase = v7_11;
        int v8_7 = com.personal.aihub.PreviewMetadata.sparkingEffects(p24);
        this.sparkingEffectIds = v8_7;
        if ((p25 < 0) || (p25 > 9007199254740991)) {
            throw new java.io.IOException("Choose a valid Sparking content version.");
        } else {
            this.sparkingVersion = p25;
            try {
                int v9_6 = com.personal.aihub.PreviewEffectPacks.normalize(p21);
                this.effectPacks = v9_6;
                com.personal.aihub.PreviewMetadata.validateEffectSources(v9_6, v8_7);
            } catch (java.io.IOException v0_28) {
                throw new java.io.IOException(v0_28.getMessage(), v0_28);
            }
            if ((v7_11.equals("sparking")) || (v8_7.length() > 0)) {
                try {
                    com.personal.aihub.PreviewMetadata.databaseFile(new java.io.File(v6_13.getFilesDir(), "forge"), "sparking", p25);
                } catch (java.io.IOException v0_29) {
                    throw new java.io.IOException(v0_29.getMessage(), v0_29);
                }
            }
            long v10_4;
            com.personal.aihub.GameAssets.overlayMap(p20);
            if (p20 != 0) {
                try {
                    v10_4 = new org.json.JSONArray(p20.toString());
                } catch (java.io.IOException v0_30) {
                    throw new java.io.IOException("Invalid preview asset manifest", v0_30);
                }
            } else {
                v10_4 = 0;
            }
            this.overlays = v10_4;
            this.gameAssets = new com.personal.aihub.GameAssets(new java.io.File(v6_13.getFilesDir(), "forge/assets"), p19, v10_4);
            java.io.File v13_2 = v6_13.getCacheDir();
            StringBuilder v14_2 = new StringBuilder("preview-movies-");
            v14_2.append(java.util.UUID.randomUUID());
            this.movieRoot = new java.io.File(v13_2, v14_2.toString());
            try {
                this.audioBanks = new com.personal.aihub.AudioBanks(new java.io.File(v6_13.getFilesDir(), "forge/assets"), p19, v10_4);
                try {
                    java.io.IOException v2_1;
                    java.io.IOException v0_5;
                    java.io.IOException v0_3 = com.personal.aihub.PreviewMetadata.databaseFile(new java.io.File(v6_13.getFilesDir(), "forge"), v7_11, p25);
                } catch (java.io.IOException v0_4) {
                    v2_1 = 0;
                    if (this.sourceDatabase.equals("sparking")) {
                        throw v0_4;
                    } else {
                        try {
                            this.bgm = new com.personal.aihub.PreviewBgm(v2_1, new java.io.File(this.context.getFilesDir(), "forge/assets"), this.gameAssets, p22);
                        } catch (java.io.IOException v0_23) {
                            try {
                                if (v2_1 != null) {
                                    v2_1.close();
                                }
                            } catch (java.io.IOException v0_24) {
                                throw new java.io.IOException("Could not prepare move music", v0_24);
                            }
                            throw v0_23;
                        }
                        if (v2_1 != null) {
                            v2_1.close();
                        }
                        if (!this.movieRoot.mkdirs()) {
                            throw new java.io.IOException("Could not prepare temporary preview storage.");
                        } else {
                            java.io.IOException v0_14 = new java.net.ServerSocket();
                            this.listener = v0_14;
                            try {
                                v0_14.bind(new java.net.InetSocketAddress(java.net.InetAddress.getByName("127.0.0.1"), 0), 32);
                                java.io.File v3_8 = new StringBuilder("http://127.0.0.1:");
                                v3_8.append(v0_14.getLocalPort());
                                this.origin = v3_8.toString();
                                java.io.File v3_11 = new StringBuilder("forge_preview_");
                                v3_11.append(v0_14.getLocalPort());
                                v3_11.append("=");
                                v3_11.append(this.token);
                                this.cookie = v3_11.toString();
                                java.io.IOException v0_19 = new java.util.concurrent.ThreadPoolExecutor;
                                v0_19(8, 8, 30, java.util.concurrent.TimeUnit.SECONDS, new java.util.concurrent.ArrayBlockingQueue(32), new com.personal.aihub.PreviewServer$1(this), new java.util.concurrent.ThreadPoolExecutor$AbortPolicy());
                                this.workers = v0_19;
                                java.io.IOException v0_21 = new Thread(new com.personal.aihub.PreviewServer$2(this), "forge-preview-listener");
                                v0_21.setDaemon(1);
                                v0_21.start();
                                return;
                            } catch (java.io.IOException v0_22) {
                                this.listener.close();
                                com.personal.aihub.PreviewServer.remove(this.movieRoot);
                                throw v0_22;
                            }
                        }
                    }
                    v2_1 = v0_5;
                }
                if (!v0_3.isFile()) {
                    v0_5 = 0;
                } else {
                    v2_1 = 0;
                    try {
                        v0_5 = android.database.sqlite.SQLiteDatabase.openDatabase(v0_3.getPath(), 0, 1);
                    } catch (java.io.IOException v0_4) {
                    }
                }
            } catch (java.io.IOException v0_25) {
                throw new java.io.IOException("Invalid edited movie preview", v0_25);
            }
        }
    }

    private static void closeSocket(java.net.Socket p0)
    {
        try {
            p0.close();
        } catch (java.io.IOException) {
        }
        return;
    }

    private void deleteMovie(java.net.Socket p12, com.personal.aihub.PreviewServer$Request p13)
    {
        long v0_5 = p13.uri.getPath().substring(24);
        if ((v0_5.matches("[a-f0-9]{32}\\.mp4")) && (p13.uri.getRawQuery() == null)) {
            if ((!p13.headers.containsKey("content-length")) || (((String) p13.headers.get("content-length")).equals("0"))) {
                try {
                    java.util.Map v13_7 = ((java.io.File) this.movies.get(v0_5));
                } catch (Throwable v12_1) {
                    throw v12_1;
                }
                if (v13_7 != null) {
                    void v3_1 = v13_7.length();
                    if (v13_7.delete()) {
                        this.movies.remove(v0_5);
                        this.preparedBytes = Math.max(0, (this.preparedBytes - v3_1));
                        byte[] v7_0 = new byte[0];
                        this.respond(p12, 204, java.util.Collections.emptyMap(), v7_0, 0);
                        return;
                    } else {
                        byte[] v9 = new byte[0];
                        this.respond(p12, 503, java.util.Collections.emptyMap(), v9, 0);
                        return;
                    }
                } else {
                    byte[] v7_2 = new byte[0];
                    this.respond(p12, 404, java.util.Collections.emptyMap(), v7_2, 0);
                    return;
                }
            } else {
                byte[] v7_3 = new byte[0];
                this.respond(p12, 400, java.util.Collections.emptyMap(), v7_3, 0);
                return;
            }
        } else {
            Throwable v4_3 = new byte[0];
            this.respond(p12, 404, java.util.Collections.emptyMap(), v4_3, 0);
            return;
        }
    }

    private static void finishSocket(java.net.Socket p6)
    {
        try {
            p6.shutdownOutput();
            p6.setSoTimeout(100);
            Throwable v0_1 = p6.getInputStream();
            byte[] v2 = new byte[8192];
            int v3 = 65536;
        } catch (java.io.IOException) {
            com.personal.aihub.PreviewServer.closeSocket(p6);
            return;
        } catch (Throwable v0_2) {
            com.personal.aihub.PreviewServer.closeSocket(p6);
            throw v0_2;
        }
        while (v3 > 0) {
            int v4_1 = v0_1.read(v2, 0, Math.min(8192, v3));
            if (v4_1 < 0) {
                break;
            }
            v3 -= v4_1;
        }
        com.personal.aihub.PreviewServer.closeSocket(p6);
        return;
    }

    static Thread lambda$0(Runnable p2)
    {
        Thread v0_1 = new Thread(p2, "forge-preview-http");
        v0_1.setDaemon(1);
        return v0_1;
    }

    private org.json.JSONObject manifest(String p5)
    {
        java.io.InputStream v5_1 = this.context.getAssets().open(p5);
        try {
            Throwable v0_1 = new org.json.JSONObject(new String(com.personal.aihub.PreviewServer.readBytes(v5_1, 2097152), java.nio.charset.StandardCharsets.UTF_8));
        } catch (Throwable v0_2) {
            if (v5_1 != null) {
                v5_1.close();
            }
            throw v0_2;
        }
        if (v5_1 != null) {
            v5_1.close();
        }
        return v0_1;
    }

    private static String mime(String p5)
    {
        boolean v5_17 = p5.substring((p5.lastIndexOf(46) + 1)).toLowerCase(java.util.Locale.ROOT);
        String v1 = "application/xml";
        String v2 = "image/jpeg";
        String v3 = "text/plain";
        String v4 = "application/octet-stream";
        switch (v5_17.hashCode()) {
            case 97669:
                if (v5_17.equals("bmp")) {
                    v4 = "image/bmp";
                }
                return v4;
            case 101691:
                if (!v5_17.equals("fsh")) {
                    v3 = "application/octet-stream";
                }
                return v3;
            case 102340:
                if (v5_17.equals("gif")) {
                    v4 = "image/gif";
                }
                return v4;
            case 105441:
                if (!v5_17.equals("jpg")) {
                    v2 = "application/octet-stream";
                }
                return v2;
            case 107512:
                if (!v5_17.equals("lua")) {
                    v3 = "application/octet-stream";
                }
                return v3;
            case 108272:
                if (v5_17.equals("mp3")) {
                    v4 = "audio/mpeg";
                }
                return v4;
            case 109967:
                if (v5_17.equals("ogg")) {
                    v4 = "audio/ogg";
                }
                return v4;
            case 110369:
                if (v5_17.equals("otf")) {
                    v4 = "font/otf";
                }
                return v4;
            case 111145:
                if (v5_17.equals("png")) {
                    v4 = "image/png";
                }
                return v4;
            case 115174:
                if (v5_17.equals("ttf")) {
                    v4 = "font/ttf";
                }
                return v4;
            case 115312:
                if (!v5_17.equals("txt")) {
                    v3 = "application/octet-stream";
                }
                return v3;
            case 117067:
                if (!v5_17.equals("vsh")) {
                    v3 = "application/octet-stream";
                }
                return v3;
            case 117484:
                if (v5_17.equals("wav")) {
                    v4 = "audio/wav";
                }
                return v4;
            case 118807:
                if (!v5_17.equals("xml")) {
                    v1 = "application/octet-stream";
                }
                return v1;
            case 3268712:
                if (!v5_17.equals("jpeg")) {
                    v2 = "application/octet-stream";
                }
                return v2;
            case 3271912:
                if (v5_17.equals("json")) {
                    v4 = "application/json";
                }
                return v4;
            case 3645340:
                if (v5_17.equals("webp")) {
                    v4 = "image/webp";
                }
                return v4;
            case 106756366:
                if (!v5_17.equals("plist")) {
                    v1 = "application/octet-stream";
                }
                return v1;
            default:
                return "application/octet-stream";
        }
    }

    private void movie(java.net.Socket p10, com.personal.aihub.PreviewServer$Request p11)
    {
        java.io.FileInputStream v0_11 = p11.uri.getPath().substring(24);
        void v1_4 = ((java.io.File) this.movies.get(v0_11));
        if ((v0_11.matches("[a-f0-9]{32}\\.mp4")) && ((v1_4 != 0) && (p11.uri.getRawQuery() == null))) {
            java.util.HashMap v5_1 = new java.util.HashMap();
            v5_1.put("Content-Type", "video/mp4");
            v5_1.put("Accept-Ranges", "bytes");
            java.io.FileInputStream v0_8 = new java.io.FileInputStream(v1_4);
            try {
                this.sendStream(p10, p11, v5_1, v0_8, v1_4.length());
                v0_8.close();
                return;
            } catch (Throwable v10_2) {
                v0_8.close();
                throw v10_2;
            }
        } else {
            java.util.HashMap v5_2 = new byte[0];
            this.respond(p10, 404, java.util.Collections.emptyMap(), v5_2, p11.method.equals("HEAD"));
            return;
        }
    }

    private String playerPatches(String p9, String p10)
    {
        int v0_21;
        if (!p9.equals("/tools/lua-player/js/usm-player.js")) {
            if (!p9.equals("/tools/lua-player/js/audio-bus.js")) {
                if (!p9.equals("/tools/lwf-player/js/lwf-pack.js")) {
                    if ((!p9.equals("/tools/lua-player/js/binders.js")) && ((!p9.equals("/tools/lua-player/js/runner.js")) && ((!p9.equals("/tools/lua-player/js/tcb-keys.js")) && ((!p9.equals("/tools/lua-player/js/lwf-player.js")) && ((!p9.equals("/tools/lua-player/js/recorder.js")) && ((!p9.equals("/tools/lua-player/js/atlas-fit.js")) && ((!p9.equals("/static/vendor/lwf/lwf.js")) && (!p9.equals("/tools/lua-player/js/app.js"))))))))) {
                        v0_21 = 0;
                    } else {
                        int v0_24 = this.manifest("ui/training-player-patches.json").getJSONArray("manifests");
                        String v4_4 = 0;
                        while (v4_4 < v0_24.length()) {
                            if (!p9.equals(v0_24.getJSONObject(v4_4).getString("path"))) {
                                v4_4++;
                            } else {
                                v0_21 = v0_24.getJSONObject(v4_4);
                            }
                            if (v0_21 == 0) {
                                throw new java.io.IOException("The packaged item scene adapter is incompatible. Update Dokkan Unit Creator.");
                            }
                        }
                        v0_21 = 0;
                    }
                } else {
                    v0_21 = this.manifest("ui/lwf-player-patches.json");
                }
            } else {
                v0_21 = this.manifest("ui/audio-player-patches.json");
            }
        } else {
            v0_21 = this.manifest("ui/media-player-patches.json");
        }
        if (v0_21 != 0) {
            if (!p9.equals(v0_21.getString("path"))) {
                throw new java.io.IOException("The packaged player adapter is incompatible. Update Dokkan Unit Creator.");
            } else {
                java.io.IOException v9_1 = java.security.MessageDigest.getInstance("SHA-256").digest(p10.getBytes(java.nio.charset.StandardCharsets.UTF_8));
                String v1_1 = new StringBuilder();
                int v3_0 = v9_1.length;
                String v4_0 = 0;
                while (v4_0 < v3_0) {
                    v1_1.append(String.format(java.util.Locale.US, "%02x", new Object[] {Integer.valueOf((v9_1[v4_0] & 255))})));
                    v4_0++;
                }
                if (!v1_1.toString().equals(v0_21.getString("sourceSha256"))) {
                    throw new java.io.IOException("The public player changed. Update Dokkan Unit Creator before previewing this animation.");
                } else {
                    java.io.IOException v9_7 = v0_21.getJSONArray("patches");
                    int v0_3 = 0;
                    while (v0_3 < v9_7.length()) {
                        int v3_2 = v9_7.getJSONObject(v0_3);
                        String v4_2 = v3_2.getString("find");
                        int v5_0 = p10.indexOf(v4_2);
                        if ((v4_2.isEmpty()) || ((v5_0 < 0) || (v5_0 != p10.lastIndexOf(v4_2)))) {
                            throw new java.io.IOException("The public player changed. Update Dokkan Unit Creator before previewing this animation.");
                        } else {
                            StringBuilder v6_3 = new StringBuilder();
                            v6_3.append(String.valueOf(p10.substring(0, v5_0)));
                            v6_3.append(v3_2.getString("replace"));
                            v6_3.append(p10.substring((v5_0 + v4_2.length())));
                            p10 = v6_3.toString();
                            v0_3++;
                        }
                    }
                    return p10;
                }
            }
        } else {
            return p10;
        }
    }

    private void prepare(java.net.Socket p20, com.personal.aihub.PreviewServer$Request p21)
    {
        void v1_37 = ((String) p21.headers.get("content-length"));
        try {
            if ((v1_37 == 0) || (!v1_37.matches("[0-9]+"))) {
                throw new NumberFormatException();
            } else {
                long v9_1 = Long.parseLong(v1_37);
                if ((v9_1 >= 12) && (v9_1 <= 167772160)) {
                    if (((String) p21.headers.getOrDefault("content-type", "")).split(";", 2)[0].trim().equalsIgnoreCase("video/mp4")) {
                        void v1_36 = new StringBuilder();
                        v1_36.append(java.util.UUID.randomUUID().toString().replace("-", ""));
                        v1_36.append(".mp4");
                        void v1_38 = v1_36.toString();
                        java.net.Socket v2_23 = this.movieRoot;
                        int v3_14 = new StringBuilder();
                        v3_14.append(v1_38);
                        v3_14.append(".tmp");
                        java.io.File v11_1 = new java.io.File(v2_23, v3_14.toString());
                        java.io.File v12_1 = new java.io.File(this.movieRoot, v1_38);
                        try {
                            if (!this.stopped) {
                                int v3_16 = this.preparing;
                                if ((this.movies.size() + v3_16) < 32) {
                                    java.util.Map v4_10 = this.preparedBytes;
                                    if (v9_1 <= (536870912 - v4_10)) {
                                        this.preparedBytes = (v4_10 + v9_1);
                                        this.preparing = (v3_16 + 1);
                                        long v14_1 = 0;
                                        try {
                                            java.net.Socket v2_0 = new java.io.FileOutputStream(v11_1);
                                            try {
                                                java.util.Map v4_0 = new byte[65536];
                                                byte[] v5_0 = v9_1;
                                                try {
                                                    while (v5_0 > v14_1) {
                                                        long v17 = v9_1;
                                                        int v8_6 = p21.input.read(v4_0, 0, ((int) Math.min(((long) 65536), v5_0)));
                                                        if (v8_6 < 0) {
                                                            throw new java.io.EOFException("Incomplete prepared movie");
                                                        } else {
                                                            if (v8_6 != 0) {
                                                                v2_0.write(v4_0, 0, v8_6);
                                                                v5_0 -= ((long) v8_6);
                                                                v9_1 = v17;
                                                            } else {
                                                                v9_1 = v17;
                                                            }
                                                            v14_1 = 0;
                                                        }
                                                    }
                                                } catch (Throwable v0_2) {
                                                    void v1_12 = v0_2;
                                                    try {
                                                        v2_0.close();
                                                    } catch (Throwable v0_36) {
                                                        v1_12.addSuppressed(v0_36);
                                                    }
                                                    throw v1_12;
                                                }
                                                v17 = v9_1;
                                                v2_0.getFD().sync();
                                                v2_0.close();
                                                int v8_1 = new java.io.RandomAccessFile(v11_1, "r");
                                                try {
                                                    v8_1.seek(4);
                                                    java.net.Socket v2_3 = new byte[4];
                                                    v8_1.readFully(v2_3);
                                                    Throwable v0_6 = new byte[4];
                                                    v0_6 = {102, 116, 121, 112};
                                                } catch (Throwable v0_26) {
                                                    void v1_8 = v0_26;
                                                    try {
                                                        v8_1.close();
                                                    } catch (Throwable v0_27) {
                                                        v1_8.addSuppressed(v0_27);
                                                    }
                                                    throw v1_8;
                                                }
                                                if (java.util.Arrays.equals(v2_3, v0_6)) {
                                                    v8_1.close();
                                                    try {
                                                        if (this.stopped) {
                                                            throw new java.io.IOException("Preview closed");
                                                        } else {
                                                            if (!v11_1.renameTo(v12_1)) {
                                                                throw new java.io.IOException("Could not retain this prepared movie");
                                                            } else {
                                                                this.movies.put(v1_38, v12_1);
                                                                try {
                                                                    try {
                                                                        java.util.Map v4_1 = java.util.Collections.singletonMap("Content-Type", "application/json");
                                                                        Throwable v0_20 = new org.json.JSONObject();
                                                                        int v3_2 = new StringBuilder();
                                                                        v3_2.append("/_forge/prepared-movies/");
                                                                        v3_2.append(v1_38);
                                                                        this.respond(p20, 201, v4_1, v0_20.put("url", v3_2.toString()).toString().getBytes(java.nio.charset.StandardCharsets.UTF_8), 0);
                                                                        v11_1.delete();
                                                                        try {
                                                                            this.preparing = (this.preparing - 1);
                                                                            return;
                                                                        } catch (Throwable v0_25) {
                                                                            throw v0_25;
                                                                        }
                                                                    } catch (Throwable v0_1) {
                                                                        int v8_2 = 1;
                                                                        v11_1.delete();
                                                                        this.preparing = (this.preparing - 1);
                                                                        if (v8_2 == 0) {
                                                                            this.preparedBytes = Math.max(0, (this.preparedBytes - v17));
                                                                            v12_1.delete();
                                                                        }
                                                                        throw v0_1;
                                                                    }
                                                                    this.preparing = (this.preparing - 1);
                                                                    return;
                                                                } catch (Throwable v0_17) {
                                                                    v8_2 = 1;
                                                                }
                                                            }
                                                        }
                                                        try {
                                                            while(true) {
                                                            }
                                                        } catch (Throwable v0_17) {
                                                        }
                                                        throw v0_17;
                                                    } catch (Throwable v0_17) {
                                                        v8_2 = 0;
                                                    }
                                                } else {
                                                    byte[] v5_3 = new byte[0];
                                                    this.respond(p20, 415, java.util.Collections.emptyMap(), v5_3, 0);
                                                    v8_1.close();
                                                    v11_1.delete();
                                                    try {
                                                        this.preparing = (this.preparing - 1);
                                                        this.preparedBytes = Math.max(0, (this.preparedBytes - v17));
                                                        v12_1.delete();
                                                        return;
                                                    } catch (Throwable v0_33) {
                                                        throw v0_33;
                                                    }
                                                }
                                            } catch (Throwable v0_2) {
                                                v17 = v9_1;
                                            } catch (Throwable v0_1) {
                                                v8_2 = 0;
                                            }
                                        } catch (Throwable v0_1) {
                                            v17 = v9_1;
                                        }
                                    } else {
                                    }
                                }
                            }
                        } catch (Throwable v0_39) {
                            throw v0_39;
                        }
                        this.respond(p20, 507, java.util.Collections.emptyMap(), "Temporary movie storage is full. Return to the Studio and reopen the preview.".getBytes(java.nio.charset.StandardCharsets.UTF_8), 0);
                        return;
                    } else {
                        byte[] v5_6 = new byte[0];
                        this.respond(p20, 415, java.util.Collections.emptyMap(), v5_6, 0);
                        return;
                    }
                } else {
                    byte[] v5_7 = new byte[0];
                    this.respond(p20, 413, java.util.Collections.emptyMap(), v5_7, 0);
                    return;
                }
            }
        } catch (NumberFormatException) {
            byte[] v5_4 = new byte[0];
            this.respond(p20, 411, java.util.Collections.emptyMap(), v5_4, 0);
            return;
        }
    }

    static long[] range(String p10, long p11)
    {
        try {
            if ((p11 > 0) && (p10.matches("bytes=([0-9]+-[0-9]*|-[0-9]+)"))) {
                long[] v10_2 = p10.substring(6).split("-", -1);
                long v4_2 = (p11 - 1);
                long v0_2;
                if (!v10_2[0].isEmpty()) {
                    v0_2 = Long.parseLong(v10_2[0]);
                    if (!v10_2[1].isEmpty()) {
                        v4_2 = Math.min(v4_2, Long.parseLong(v10_2[1]));
                    }
                } else {
                    long v8_1 = Long.parseLong(v10_2[1]);
                    if (v8_1 > 0) {
                        v0_2 = Math.max(0, (p11 - v8_1));
                    } else {
                        return 0;
                    }
                }
                if ((v0_2 < p11) && (v4_2 >= v0_2)) {
                    long[] v10_9 = new long[2];
                    v10_9[0] = v0_2;
                    v10_9[1] = v4_2;
                    return v10_9;
                }
            }
        } catch (NumberFormatException) {
        }
        return 0;
    }

    private static com.personal.aihub.PreviewServer$Request read(java.net.Socket p11)
    {
        String v0_15 = new java.io.BufferedInputStream(p11.getInputStream(), 8192);
        java.io.IOException v11_26 = new java.io.ByteArrayOutputStream();
        char[] v3_11 = 0;
        while (v11_26.size() < 16384) {
            int v4_1 = v0_15.read();
            if (v4_1 < 0) {
                throw new java.io.EOFException();
            } else {
                v11_26.write(v4_1);
                v3_11 = ((v3_11 << 8) | (v4_1 & 255));
                if (v3_11 == 218762506) {
                    break;
                }
            }
        }
        if (v3_11 != 218762506) {
            throw new java.io.IOException("HTTP headers exceed limit");
        } else {
            char[] v3_13 = new String(v11_26.toByteArray(), java.nio.charset.StandardCharsets.ISO_8859_1);
            java.io.IOException v11_24 = v3_13.substring(0, (v3_13.length() - 4)).split("\r\n");
            char[] v3_16 = v11_24[0].split(" ", -1);
            if ((v3_16.length != 3) || ((!v3_16[2].equals("HTTP/1.1")) || ((!v3_16[0].matches("[A-Z]{3,8}")) || ((!v3_16[1].startsWith("/")) || ((v3_16[1].startsWith("//")) || ((v3_16[1].contains("\\")) || (v3_16[1].length() > 8192))))))) {
                throw new java.io.IOException("Invalid HTTP request");
            } else {
                com.personal.aihub.PreviewServer$Request v1_2 = new com.personal.aihub.PreviewServer$Request(0);
                v1_2.method = v3_16[0];
                v1_2.target = v3_16[1];
                v1_2.uri = new java.net.URI(v1_2.target);
                v1_2.input = v0_15;
                if ((v1_2.uri.getHost() != null) || (v1_2.uri.getFragment() != null)) {
                    throw new java.io.IOException("Invalid request target");
                } else {
                    String v0_6 = v1_2.uri.getPath();
                    char[] v3_0 = v0_6.split("/", -1);
                    int v6_0 = 0;
                    while (v6_0 < v3_0.length) {
                        int v8_1 = v3_0[v6_0];
                        if ((v8_1.equals(".")) || ((v8_1.equals("..")) || (v8_1.indexOf(92) >= 0))) {
                            throw new java.io.IOException("Unsafe request path");
                        } else {
                            v6_0++;
                        }
                    }
                    String v0_7 = v0_6.toCharArray();
                    int v5_2 = 0;
                    while (v5_2 < v0_7.length) {
                        char v9_1 = v0_7[v5_2];
                        if ((v9_1 < 32) || (v9_1 == 127)) {
                            throw new java.io.IOException("Unsafe request path");
                        } else {
                            v5_2++;
                        }
                    }
                    if (v11_24.length > 65) {
                        throw new java.io.IOException("Too many HTTP headers");
                    } else {
                        String v0_10 = 1;
                        while (v0_10 < v11_24.length) {
                            char[] v3_5 = v11_24[v0_10].indexOf(58);
                            if (v3_5 < 1) {
                                throw new java.io.IOException("Invalid HTTP header");
                            } else {
                                int v5_6 = v11_24[v0_10].substring(0, v3_5).toLowerCase(java.util.Locale.ROOT);
                                char[] v3_8 = v11_24[v0_10].substring((v3_5 + 1)).trim();
                                if ((!v5_6.matches("[a-z0-9-]{1,80}")) || (v1_2.headers.put(v5_6, v3_8) != null)) {
                                    throw new java.io.IOException("Duplicate/invalid HTTP header");
                                } else {
                                    char[] v3_9 = v3_8.toCharArray();
                                    int v7_6 = 0;
                                    while (v7_6 < v3_9.length) {
                                        char v9_0 = v3_9[v7_6];
                                        if (((v9_0 < 32) && (v9_0 != 9)) || (v9_0 == 127)) {
                                            throw new java.io.IOException("Unsafe HTTP header");
                                        } else {
                                            v7_6++;
                                        }
                                    }
                                    v0_10++;
                                }
                            }
                        }
                        return v1_2;
                    }
                }
            }
        }
    }

    private static byte[] readBytes(java.io.InputStream p4, int p5)
    {
        java.io.ByteArrayOutputStream v0_1 = new java.io.ByteArrayOutputStream();
        byte[] v1_1 = new byte[8192];
        while(true) {
            int v2 = p4.read(v1_1);
            if (v2 != -1) {
                if (v2 > (p5 - v0_1.size())) {
                    break;
                }
                v0_1.write(v1_1, 0, v2);
            } else {
                return v0_1.toByteArray();
            }
        }
        throw new java.io.IOException("Preview text exceeds the size limit");
    }

    private static void remove(java.io.File p4)
    {
        java.io.File[] v0 = p4.listFiles();
        if (v0 != null) {
            int v1 = v0.length;
            int v2 = 0;
            while (v2 < v1) {
                com.personal.aihub.PreviewServer.remove(v0[v2]);
                v2++;
            }
        }
        p4.delete();
        return;
    }

    private void respond(java.net.Socket p8, int p9, java.util.Map p10, byte[] p11, boolean p12)
    {
        this.writeHeaders(p8, p9, p10, ((long) p11.length));
        if (!p12) {
            p8.getOutputStream().write(p11);
            p8.getOutputStream().flush();
            return;
        } else {
            return;
        }
    }

    private String rewrite(String p9)
    {
        String[][] v0_1 = new StringBuilder();
        v0_1.append(String.valueOf(this.origin));
        v0_1.append("/cdn/uncompressed");
        int v2_1 = 0;
        while (v2_1 < 2) {
            String v3_1 = new String[][] {new String[] {"https://cdn.dokkan-eclipse.com/uncompressed", v0_1.toString()}), new String[] {"https://dokkan-eclipse.com", this.origin})})[v2_1];
            p9 = p9.replace(v3_1[0], v3_1[1]).replace(v3_1[0].replace("/", "\\/"), v3_1[1].replace("/", "\\/"));
            v2_1++;
        }
        return p9;
    }

    private void sendBytes(java.net.Socket p9, com.personal.aihub.PreviewServer$Request p10, java.util.Map p11, byte[] p12)
    {
        java.io.ByteArrayInputStream v7_1 = new java.io.ByteArrayInputStream(p12);
        try {
            this.sendStream(p9, p10, new java.util.HashMap(p11), v7_1, ((long) p12.length));
            v7_1.close();
            return;
        } catch (Throwable v9_1) {
            v7_1.close();
            throw v9_1;
        }
    }

    private void sendStream(java.net.Socket p16, com.personal.aihub.PreviewServer$Request p17, java.util.Map p18, java.io.InputStream p19, long p20)
    {
        long v4_3;
        byte v13;
        int v5_2 = new java.util.HashMap(p18);
        int v6_2 = (p20 - 1);
        long v4_2 = ((String) p17.headers.get("range"));
        if (v4_2 == 0) {
            v4_3 = 200;
            v13 = 0;
        } else {
            long v4_4 = com.personal.aihub.PreviewServer.range(v4_2, p20);
            if (v4_4 != 0) {
                v13 = v4_4[0];
                long v11_1 = v4_4[1];
                long v4_6 = new StringBuilder("bytes ");
                v4_6.append(v13);
                v4_6.append("-");
                v4_6.append(v11_1);
                v4_6.append("/");
                v4_6.append(p20);
                v5_2.put("Content-Range", v4_6.toString());
                v4_3 = 206;
                v6_2 = v11_1;
            } else {
                java.net.Socket v1_3 = new StringBuilder("bytes */");
                v1_3.append(p20);
                v5_2.put("Content-Range", v1_3.toString());
                long v4_0 = new byte[0];
                this.respond(p16, 416, v5_2, v4_0, p17.method.equals("HEAD"));
                return;
            }
        }
        long v11_2 = ((v6_2 - v13) + 1);
        this.writeHeaders(p16, v4_3, v5_2, v11_2);
        if (!p17.method.equals("HEAD")) {
            long v2_6 = 0;
            while (v2_6 < v13) {
                long v4_10 = p19.skip((v13 - v2_6));
                if (v4_10 <= 0) {
                    if (p19.read() < 0) {
                        throw new java.io.EOFException();
                    } else {
                        v4_10 = 1;
                    }
                }
                v2_6 += v4_10;
            }
            java.io.EOFException v0_6 = p16.getOutputStream();
            long v2_8 = new byte[65536];
            while (v11_2 > 0) {
                int v5_7 = p19.read(v2_8, 0, ((int) Math.min(65536, v11_2)));
                if (v5_7 < 0) {
                    throw new java.io.EOFException();
                } else {
                    v0_6.write(v2_8, 0, v5_7);
                    v11_2 -= ((long) v5_7);
                }
            }
            v0_6.flush();
            return;
        } else {
            return;
        }
    }

    private void serve(java.net.Socket p23)
    {
        try {
            int v3_8 = com.personal.aihub.PreviewServer.read(p23);
            java.io.FileInputStream v4_52 = new StringBuilder("127.0.0.1:");
            v4_52.append(this.listener.getLocalPort());
        } catch (Exception) {
            StringBuilder v5_48 = new byte[0];
            this.respond(p23, 400, java.util.Collections.emptyMap(), v5_48, 0);
            return;
        }
        if (v4_52.toString().equals(v3_8.headers.get("host"))) {
            if (!v3_8.headers.containsKey("transfer-encoding")) {
                if (!v3_8.headers.containsKey("expect")) {
                    if ((!v3_8.headers.containsKey("origin")) || (this.origin.equals(v3_8.headers.get("origin")))) {
                        java.net.Socket v2_33 = v3_8.uri.getPath();
                        long v11_0 = v3_8.method.equals("HEAD");
                        if ((v3_8.method.equals("GET")) || (v11_0 != 0)) {
                            java.io.FileInputStream v4_29 = new StringBuilder("/_forge/open/");
                            v4_29.append(this.token);
                            if (v2_33.equals(v4_29.toString())) {
                                String v1_118 = android.net.Uri.parse(v3_8.target).getQueryParameter("tool");
                                if (!java.util.Arrays.asList(new String[] {"lua-player", "lwf-player", "usm-player"})).contains(v1_118)) {
                                    v1_118 = "lua-player";
                                }
                                java.io.FileInputStream v4_56 = new java.util.HashMap();
                                int v3_23 = new StringBuilder("/tools/");
                                v3_23.append(v1_118);
                                v3_23.append("/");
                                v4_56.put("Location", v3_23.toString());
                                String v1_120 = new StringBuilder();
                                v1_120.append(String.valueOf(this.cookie));
                                v1_120.append("; Path=/; HttpOnly; SameSite=Strict");
                                v4_56.put("Set-Cookie", v1_120.toString());
                                StringBuilder v5_44 = new byte[0];
                                this.respond(p23, 302, v4_56, v5_44, v11_0);
                                return;
                            }
                        }
                        String v0_127 = ((String) v3_8.headers.getOrDefault("cookie", "")).split(";");
                        java.io.FileInputStream v4_40 = 0;
                        StringBuilder v5_35 = 0;
                        while (v4_40 < v0_127.length) {
                            if (v0_127[v4_40].trim().equals(this.cookie)) {
                                v5_35 = 1;
                            }
                            v4_40++;
                        }
                        if (v5_35 != null) {
                            if ((!v3_8.headers.containsKey("origin")) || (this.origin.equals(v3_8.headers.get("origin")))) {
                                if ((!v3_8.method.equals("POST")) || ((!v2_33.equals("/_forge/prepared-movies")) || (v3_8.uri.getRawQuery() != null))) {
                                    if ((!v3_8.method.equals("DELETE")) || (!v2_33.startsWith("/_forge/prepared-movies/"))) {
                                        if ((v3_8.method.equals("GET")) || (v11_0 != 0)) {
                                            if ((!v3_8.headers.containsKey("content-length")) || (((String) v3_8.headers.get("content-length")).equals("0"))) {
                                                if (!v2_33.startsWith("/_forge/prepared-movies/")) {
                                                    java.io.FileInputStream v4_0 = 167772160;
                                                    if (!v2_33.startsWith("/_forge/stage-export/")) {
                                                        if (!v2_33.equals("/_forge/stage-capture")) {
                                                            String v1_5 = 0;
                                                            if ((!v2_33.equals("/_forge/bgm-source")) && ((!v2_33.equals("/_forge/bgm-source.acb")) && (!v2_33.equals("/_forge/bgm-source.awb")))) {
                                                                if (!v2_33.startsWith("/_forge/bgm-bank-assets/")) {
                                                                    if (!v2_33.equals("/_forge/audio-banks")) {
                                                                        if (!v2_33.startsWith("/_forge/audio-bank-assets/")) {
                                                                            if ((!v2_33.startsWith("/_forge/")) || ((v2_33.equals("/_forge/training-context.js")) || ((v2_33.equals("/_forge/native-audio.js")) || ((v2_33.equals("/_forge/audio-bank.js")) || ((v2_33.equals("/_forge/imported-audio.js")) || (v2_33.matches("/_forge/media/(libav/)?[A-Za-z0-9][A-Za-z0-9_.-]*"))))))) {
                                                                                if (!v3_8.target.equals("/api/scripts")) {
                                                                                    String v0_50 = new com.personal.aihub.PreviewServer$4(this, v3_8);
                                                                                    try {
                                                                                        String v6_2 = new StringBuilder();
                                                                                        v6_2.append("https://dokkan-eclipse.com");
                                                                                        v6_2.append(v3_8.target);
                                                                                        String v6_3 = v6_2.toString();
                                                                                    } catch (String v0_77) {
                                                                                        this.respond(p23, 503, java.util.Collections.singletonMap("Content-Type", "text/plain; charset=utf-8"), String.valueOf(v0_77.getMessage()).getBytes(java.nio.charset.StandardCharsets.UTF_8), v11_0);
                                                                                        return;
                                                                                    }
                                                                                    if (com.personal.aihub.GameDirectory.route(v6_3) != null) {
                                                                                        String v7_5 = new com.personal.aihub.GameDirectory(new java.io.File(this.context.getFilesDir(), "forge/assets"), this.preferredKey, this.overlays).resolve(v6_3);
                                                                                        if (v7_5 != null) {
                                                                                            this.sendBytes(p23, v3_8, java.util.Collections.singletonMap("Content-Type", "application/json"), com.personal.aihub.GameDirectory.merge(v7_5, new org.json.JSONObject(this.cache.text(v6_3, 2097152))).toString().getBytes(java.nio.charset.StandardCharsets.UTF_8));
                                                                                            return;
                                                                                        }
                                                                                    }
                                                                                    if (!com.personal.aihub.PreviewMetadata.route(v3_8.target)) {
                                                                                        String v1_11;
                                                                                        String v1_8 = this.gameAssets;
                                                                                        String v6_5 = new StringBuilder();
                                                                                        v6_5.append("https://dokkan-eclipse.com");
                                                                                        v6_5.append(v3_8.target);
                                                                                        String v1_9 = v1_8.resolve(v6_5.toString());
                                                                                        if (v1_9 != null) {
                                                                                            if (v1_9.length() > 167772160) {
                                                                                                throw new java.io.IOException("This imported preview asset exceeds 160 MB.");
                                                                                            } else {
                                                                                                String v0_54 = new android.webkit.WebResourceResponse;
                                                                                                v0_54(com.personal.aihub.PreviewServer.mime(v1_9.getName()), 0, 200, "OK", java.util.Collections.singletonMap("Content-Length", Long.toString(v1_9.length())), new java.io.FileInputStream(v1_9));
                                                                                                v1_11 = v0_54;
                                                                                            }
                                                                                        } else {
                                                                                            v1_11 = com.personal.aihub.PreviewResources.response(this.context, v0_50);
                                                                                            if (v1_11 == null) {
                                                                                                v1_11 = this.cache.response(v0_50);
                                                                                            }
                                                                                        }
                                                                                        java.io.FileInputStream v4_9 = new java.util.HashMap();
                                                                                        v4_9.put("Content-Type", v1_11.getMimeType());
                                                                                        v4_9.put("Accept-Ranges", "bytes");
                                                                                        try {
                                                                                            java.io.InputStream v12_3 = v1_11.getData();
                                                                                        } catch (String v0_70) {
                                                                                            throw v0_70;
                                                                                        }
                                                                                        if (v1_11.getStatusCode() != 200) {
                                                                                            this.respond(p23, v1_11.getStatusCode(), v4_9, com.personal.aihub.PreviewServer.readBytes(v12_3, 1048576), v11_0);
                                                                                            if (v12_3 == null) {
                                                                                                return;
                                                                                            } else {
                                                                                                v12_3.close();
                                                                                                return;
                                                                                            }
                                                                                        } else {
                                                                                            String v0_59 = v1_11.getMimeType();
                                                                                            String v6_9 = Long.parseLong(((String) v1_11.getResponseHeaders().get("Content-Length")));
                                                                                            if ((v0_59.startsWith("text/")) || (v0_59.contains("javascript"))) {
                                                                                                String v1_29 = this.rewrite(this.playerPatches(v2_33, new String(com.personal.aihub.PreviewServer.readBytes(v12_3, 67108864), java.nio.charset.StandardCharsets.UTF_8)));
                                                                                                if (v0_59.startsWith("text/html")) {
                                                                                                    StringBuilder v5_14;
                                                                                                    String v0_62 = new StringBuilder();
                                                                                                    v0_62.append("<script>");
                                                                                                    v0_62.append(this.transport());
                                                                                                    v0_62.append("</script><script src=\"/tools/lua-player/js/forge-imported.js\"></script>");
                                                                                                    String v0_63 = v0_62.toString();
                                                                                                    java.net.Socket v2_18 = java.util.regex.Pattern.compile("<head(?:\\s[^>]*)?>", 2).matcher(v1_29);
                                                                                                    if (!v2_18.find()) {
                                                                                                        v5_14 = new StringBuilder(String.valueOf(v0_63));
                                                                                                        v5_14.append(v1_29);
                                                                                                    } else {
                                                                                                        v5_14 = new StringBuilder(String.valueOf(v1_29.substring(0, v2_18.end())));
                                                                                                        v5_14.append(v0_63);
                                                                                                        v5_14.append(v1_29.substring(v2_18.end()));
                                                                                                    }
                                                                                                    v1_29 = v5_14.toString();
                                                                                                }
                                                                                                this.sendBytes(p23, v3_8, v4_9, v1_29.getBytes(java.nio.charset.StandardCharsets.UTF_8));
                                                                                            } else {
                                                                                                if (!v0_59.contains("json")) {
                                                                                                    this.sendStream(p23, v3_8, v4_9, v12_3, v6_9);
                                                                                                } else {
                                                                                                }
                                                                                            }
                                                                                            if (v12_3 == null) {
                                                                                                if (v12_3 != null) {
                                                                                                    v12_3.close();
                                                                                                }
                                                                                                return;
                                                                                            } else {
                                                                                                if (v12_3 != null) {
                                                                                                    v12_3.close();
                                                                                                }
                                                                                                return;
                                                                                            }
                                                                                        }
                                                                                    } else {
                                                                                        String v0_72 = java.util.Collections.singletonMap("Content-Type", "application/json");
                                                                                        java.io.InputStream v12_4 = this.context;
                                                                                        String v13_4 = this.cache;
                                                                                        String v1_32 = new StringBuilder();
                                                                                        v1_32.append("https://dokkan-eclipse.com");
                                                                                        v1_32.append(v3_8.target);
                                                                                        this.sendBytes(p23, v3_8, v0_72, this.rewrite(com.personal.aihub.PreviewMetadata.resolve(v12_4, v13_4, v1_32.toString(), this.preferredKey, this.overlays, this.effectPacks, this.sourceDatabase, this.sparkingEffectIds, this.sparkingVersion).toString()).getBytes(java.nio.charset.StandardCharsets.UTF_8));
                                                                                        return;
                                                                                    }
                                                                                } else {
                                                                                    try {
                                                                                        this.sendBytes(p23, v3_8, java.util.Collections.singletonMap("Content-Type", "application/json"), com.personal.aihub.PreviewScripts.listing(this.context, new java.io.File(this.context.getFilesDir(), "forge/assets")).toString().getBytes(java.nio.charset.StandardCharsets.UTF_8));
                                                                                        return;
                                                                                    } catch (String v0_82) {
                                                                                        this.respond(p23, 503, java.util.Collections.singletonMap("Content-Type", "text/plain; charset=utf-8"), String.valueOf(v0_82.getMessage()).getBytes(java.nio.charset.StandardCharsets.UTF_8), v11_0);
                                                                                        return;
                                                                                    }
                                                                                }
                                                                            } else {
                                                                                StringBuilder v5_22 = new byte[0];
                                                                                this.respond(p23, 404, java.util.Collections.emptyMap(), v5_22, v11_0);
                                                                                return;
                                                                            }
                                                                        } else {
                                                                        }
                                                                    }
                                                                    if (v3_8.uri.getRawQuery() == null) {
                                                                        try {
                                                                            if (!v2_33.equals("/_forge/audio-banks")) {
                                                                                String v0_89 = this.audioBanks;
                                                                                String v1_55 = new StringBuilder();
                                                                                v1_55.append("https://dokkan-eclipse.com");
                                                                                v1_55.append(v3_8.target);
                                                                                String v0_90 = v0_89.resolve(v1_55.toString());
                                                                                if (v0_90 != null) {
                                                                                    try {
                                                                                        java.io.InputStream v12_6 = new java.io.FileInputStream(v0_90);
                                                                                    } catch (String v0_92) {
                                                                                        throw v0_92;
                                                                                    }
                                                                                    this.sendStream(p23, v3_8, new java.util.HashMap(java.util.Collections.singletonMap("Content-Type", "application/octet-stream")), v12_6, v0_90.length());
                                                                                    v12_6.close();
                                                                                    return;
                                                                                } else {
                                                                                    StringBuilder v5_25 = new byte[0];
                                                                                    this.respond(p23, 404, java.util.Collections.emptyMap(), v5_25, v11_0);
                                                                                    return;
                                                                                }
                                                                            } else {
                                                                                this.sendBytes(p23, v3_8, java.util.Collections.singletonMap("Content-Type", "application/json"), this.audioBanks.catalogue().toString().getBytes(java.nio.charset.StandardCharsets.UTF_8));
                                                                                return;
                                                                            }
                                                                        } catch (String v0_95) {
                                                                            this.respond(p23, 503, java.util.Collections.singletonMap("Content-Type", "text/plain; charset=utf-8"), String.valueOf(v0_95.getMessage()).getBytes(java.nio.charset.StandardCharsets.UTF_8), v11_0);
                                                                            return;
                                                                        }
                                                                    } else {
                                                                        StringBuilder v5_27 = new byte[0];
                                                                        this.respond(p23, 404, java.util.Collections.emptyMap(), v5_27, v11_0);
                                                                        return;
                                                                    }
                                                                } else {
                                                                }
                                                            }
                                                            if (v3_8.uri.getRawQuery() == null) {
                                                                try {
                                                                    if (!v2_33.equals("/_forge/bgm-source")) {
                                                                        if (!v2_33.startsWith("/_forge/bgm-bank-assets/")) {
                                                                            String v0_105 = this.bgm.publicAddress(v2_33);
                                                                            if (v0_105 != null) {
                                                                                if (v2_33.endsWith(".acb")) {
                                                                                    v4_0 = 33554432;
                                                                                }
                                                                                v1_5 = this.cache.resourceBody(v0_105, v4_0);
                                                                            } else {
                                                                            }
                                                                        } else {
                                                                            String v0_106 = this.bgm;
                                                                            String v1_74 = new StringBuilder();
                                                                            v1_74.append("https://dokkan-eclipse.com");
                                                                            v1_74.append(v2_33);
                                                                            v1_5 = v0_106.resolve(v1_74.toString());
                                                                        }
                                                                        if (v1_5 != null) {
                                                                            try {
                                                                                java.io.InputStream v12_8 = new java.io.FileInputStream(v1_5);
                                                                            } catch (String v0_109) {
                                                                                throw v0_109;
                                                                            }
                                                                            this.sendStream(p23, v3_8, java.util.Collections.singletonMap("Content-Type", "application/octet-stream"), v12_8, v1_5.length());
                                                                            v12_8.close();
                                                                            return;
                                                                        } else {
                                                                            StringBuilder v5_29 = new byte[0];
                                                                            this.respond(p23, 404, java.util.Collections.emptyMap(), v5_29, v11_0);
                                                                            return;
                                                                        }
                                                                    } else {
                                                                        this.sendBytes(p23, v3_8, java.util.Collections.singletonMap("Content-Type", "application/json"), this.bgm.descriptor().toString().getBytes(java.nio.charset.StandardCharsets.UTF_8));
                                                                        return;
                                                                    }
                                                                } catch (String v0_113) {
                                                                    this.respond(p23, 503, java.util.Collections.singletonMap("Content-Type", "text/plain; charset=utf-8"), String.valueOf(v0_113.getMessage()).getBytes(java.nio.charset.StandardCharsets.UTF_8), v11_0);
                                                                    return;
                                                                }
                                                            } else {
                                                                StringBuilder v5_31 = new byte[0];
                                                                this.respond(p23, 404, java.util.Collections.emptyMap(), v5_31, v11_0);
                                                                return;
                                                            }
                                                        } else {
                                                            if (v3_8.uri.getRawQuery() == null) {
                                                                if (v11_0 == 0) {
                                                                    try {
                                                                        String v0_119 = this.stageCapture;
                                                                    } catch (String v0_124) {
                                                                        this.respond(p23, 503, java.util.Collections.singletonMap("Content-Type", "text/plain"), String.valueOf(v0_124.getMessage()).getBytes(java.nio.charset.StandardCharsets.UTF_8), 0);
                                                                        return;
                                                                    }
                                                                    if (v0_119 == null) {
                                                                        throw new java.io.IOException("The owning preview cannot capture this animation.");
                                                                    } else {
                                                                        this.sendBytes(p23, v3_8, java.util.Collections.singletonMap("Content-Type", "image/png"), v0_119.capture());
                                                                        return;
                                                                    }
                                                                } else {
                                                                    StringBuilder v5_33 = new byte[0];
                                                                    this.respond(p23, 405, java.util.Collections.emptyMap(), v5_33, 1);
                                                                    return;
                                                                }
                                                            } else {
                                                                StringBuilder v5_34 = new byte[0];
                                                                this.respond(p23, 404, java.util.Collections.emptyMap(), v5_34, v11_0);
                                                                return;
                                                            }
                                                        }
                                                    } else {
                                                        if (v3_8.uri.getRawQuery() == null) {
                                                            if (v11_0 == 0) {
                                                                String v0_131 = v2_33.substring(21);
                                                                String v1_101 = ((java.io.File) this.movies.get(v0_131));
                                                                if ((v0_131.matches("[a-f0-9]{32}\\.mp4")) && ((v1_101 != null) && ((v1_101.isFile()) && ((v1_101.length() >= 12) && (v1_101.length() <= 167772160))))) {
                                                                    try {
                                                                        String v0_137 = this.stageExport;
                                                                    } catch (String v0_145) {
                                                                        this.respond(p23, 503, java.util.Collections.singletonMap("Content-Type", "text/plain"), String.valueOf(v0_145.getMessage()).getBytes(java.nio.charset.StandardCharsets.UTF_8), 0);
                                                                        return;
                                                                    }
                                                                    if (v0_137 == null) {
                                                                        throw new java.io.IOException("The owning preview cannot save this recording.");
                                                                    } else {
                                                                        this.sendBytes(p23, v3_8, java.util.Collections.singletonMap("Content-Type", "application/json"), new org.json.JSONObject().put("saved", v0_137.save(v1_101)).toString().getBytes(java.nio.charset.StandardCharsets.UTF_8));
                                                                        return;
                                                                    }
                                                                } else {
                                                                    StringBuilder v5_38 = new byte[0];
                                                                    this.respond(p23, 404, java.util.Collections.emptyMap(), v5_38, 0);
                                                                    return;
                                                                }
                                                            } else {
                                                                StringBuilder v5_39 = new byte[0];
                                                                this.respond(p23, 405, java.util.Collections.emptyMap(), v5_39, 1);
                                                                return;
                                                            }
                                                        } else {
                                                            StringBuilder v5_40 = new byte[0];
                                                            this.respond(p23, 404, java.util.Collections.emptyMap(), v5_40, v11_0);
                                                            return;
                                                        }
                                                    }
                                                } else {
                                                    this.movie(p23, v3_8);
                                                    return;
                                                }
                                            } else {
                                                StringBuilder v5_41 = new byte[0];
                                                this.respond(p23, 400, java.util.Collections.emptyMap(), v5_41, v11_0);
                                                return;
                                            }
                                        } else {
                                            StringBuilder v5_42 = new byte[0];
                                            this.respond(p23, 405, java.util.Collections.emptyMap(), v5_42, 0);
                                            return;
                                        }
                                    } else {
                                        this.deleteMovie(p23, v3_8);
                                        return;
                                    }
                                } else {
                                    this.prepare(p23, v3_8);
                                    return;
                                }
                            } else {
                            }
                        }
                        StringBuilder v5_43 = new byte[0];
                        this.respond(p23, 403, java.util.Collections.emptyMap(), v5_43, v11_0);
                        return;
                    } else {
                        StringBuilder v5_45 = new byte[0];
                        this.respond(p23, 403, java.util.Collections.emptyMap(), v5_45, 0);
                        return;
                    }
                } else {
                }
            }
            StringBuilder v5_46 = new byte[0];
            this.respond(p23, 400, java.util.Collections.emptyMap(), v5_46, 0);
            return;
        } else {
            StringBuilder v5_47 = new byte[0];
            this.respond(p23, 403, java.util.Collections.emptyMap(), v5_47, 0);
            return;
        }
    }

    private String transport()
    {
        String v0_2 = new StringBuilder("window.__forgeNativeDocumentId=");
        v0_2.append(org.json.JSONObject.quote(java.util.UUID.randomUUID().toString()));
        v0_2.append(";(()=>{const origin=");
        v0_2.append(org.json.JSONObject.quote(this.origin));
        v0_2.append(";const map=u=>{const s=String(u),cdn=\'https://cdn.dokkan-eclipse.com/uncompressed\',site=\'https://dokkan-eclipse.com\';return s.startsWith(cdn+\'/\')?origin+\'/cdn/uncompressed\'+s.slice(cdn.length):s.startsWith(site+\'/\')?origin+s.slice(site.length):s};const fetch=window.fetch;window.fetch=(u,o)=>fetch(u instanceof Request?new Request(map(u.url),u):map(u),o);const open=XMLHttpRequest.prototype.open;XMLHttpRequest.prototype.open=function(m,u,...a){return open.call(this,m,map(u),...a)}})();");
        return v0_2.toString();
    }

    private void writeHeaders(java.net.Socket p3, int p4, java.util.Map p5, long p6)
    {
        String v0_1 = new java.util.LinkedHashMap(p5);
        v0_1.put("Content-Length", Long.toString(p6));
        v0_1.put("Connection", "close");
        v0_1.put("Cache-Control", "no-store");
        v0_1.put("Cross-Origin-Opener-Policy", "same-origin");
        v0_1.put("Cross-Origin-Embedder-Policy", "require-corp");
        v0_1.put("Cross-Origin-Resource-Policy", "same-origin");
        v0_1.put("X-Content-Type-Options", "nosniff");
        v0_1.put("Referrer-Policy", "no-referrer");
        v0_1.put("Content-Security-Policy", "default-src \'self\' data: blob:; script-src \'self\' \'unsafe-inline\' \'unsafe-eval\' blob:; connect-src \'self\' blob:; style-src \'self\' \'unsafe-inline\'; img-src \'self\' data: blob:; media-src \'self\' blob: data:; worker-src \'self\' blob:; frame-src \'none\'; object-src \'none\'; base-uri \'self\'; form-action \'none\'");
        String v6_7 = new StringBuilder("HTTP/1.1 ");
        v6_7.append(p4);
        v6_7.append(" Response\r\n");
        java.nio.charset.Charset v5_9 = new StringBuilder(v6_7.toString());
        byte[] v4_4 = v0_1.entrySet().iterator();
        while (v4_4.hasNext()) {
            String v6_11 = ((java.util.Map$Entry) v4_4.next());
            v5_9.append(((String) v6_11.getKey()));
            v5_9.append(": ");
            v5_9.append(((String) v6_11.getValue()).replace("\r", "").replace("\n", ""));
            v5_9.append("\r\n");
        }
        v5_9.append("\r\n");
        p3.getOutputStream().write(v5_9.toString().getBytes(java.nio.charset.StandardCharsets.ISO_8859_1));
        return;
    }

    org.json.JSONObject bgmContext()
    {
        return new org.json.JSONObject(this.bgm.context.toString());
    }

    public void close()
    {
        if (this.stageExport != null) {
            this.stageExport.close();
        }
        if (this.stageCapture != null) {
            this.stageCapture.close();
        }
        this.audioBanks.close();
        this.bgm.close();
        try {
            if (!this.stopped) {
                this.stopped = 1;
                this.listener.close();
                java.io.File v0_7 = this.clients.iterator();
            } else {
                return;
            }
        } catch (java.io.File v0_14) {
            throw v0_14;
        }
    }

    String entryURL(String p3)
    {
        String v3_1;
        if (!p3.equals("pack")) {
            if (!p3.equals("movie")) {
                v3_1 = "lua-player";
            } else {
                v3_1 = "usm-player";
            }
        } else {
            v3_1 = "lwf-player";
        }
        StringBuilder v0_2 = new StringBuilder();
        v0_2.append(String.valueOf(this.origin));
        v0_2.append("/_forge/open/");
        v0_2.append(this.token);
        v0_2.append("?tool=");
        v0_2.append(v3_1);
        return v0_2.toString();
    }

    boolean local(String p4)
    {
        int v0 = 0;
        try {
            java.net.URI v1_1 = new java.net.URI(p4);
        } catch (Exception) {
            return v0;
        }
        if ((!"http".equals(v1_1.getScheme())) || ((!"127.0.0.1".equals(v1_1.getHost())) || ((v1_1.getPort() != this.listener.getLocalPort()) || (v1_1.getUserInfo() != null)))) {
            return v0;
        } else {
            v0 = 1;
            return v0;
        }
    }

    public void m33lambda$1$compersonalaihubPreviewServer()
    {
        try {
            while(true) {
                Throwable v0_1 = this.listener.accept();
                v0_1.setSoTimeout(30000);
            }
        } catch (java.io.IOException) {
            return;
        }
        if (this.stopped) {
            com.personal.aihub.PreviewServer.closeSocket(v0_1);
        } else {
            if (this.clients.size() < 32) {
                this.clients.add(v0_1);
                this.workers.execute(new com.personal.aihub.PreviewServer$3(this, v0_1));
            } else {
            }
        }
    }

    void m34lambda$2$compersonalaihubPreviewServer(java.net.Socket p3)
    {
        try {
            this.serve(p3);
        } catch (Throwable v0_3) {
            try {
                this.clients.remove(p3);
                com.personal.aihub.PreviewServer.finishSocket(p3);
                throw v0_3;
            } catch (Throwable v3_1) {
                throw v3_1;
            }
        }
        this.clients.remove(p3);
        com.personal.aihub.PreviewServer.finishSocket(p3);
        return;
    }

    void stageCapture(com.personal.aihub.StageCapture p1)
    {
        this.stageCapture = p1;
        return;
    }

    void stageExport(com.personal.aihub.StageExport p1)
    {
        this.stageExport = p1;
        return;
    }
}
