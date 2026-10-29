package com.personal.aihub;
final class PreviewCache {
    private static final Object LOCK = None;
    private static final long MAX_FILE = 167772160;
    private static final long MAX_TOTAL = 2147483648;
    private static volatile long revision;
    private final java.io.File root;

    static PreviewCache()
    {
        com.personal.aihub.PreviewCache.LOCK = new Object();
        return;
    }

    PreviewCache(java.io.File p3)
    {
        java.io.File v0_1 = new java.io.File(p3, "preview-cache");
        this.root = v0_1;
        v0_1.mkdirs();
        return;
    }

    private static boolean budget(long p9)
    {
        if (p9 != 536870912) {
            int[] v2 = new int[6];
            v2 = {1, 2, 4, 8, 16, 32};
            int v4 = 0;
            while (v4 < 6) {
                if (p9 != (((long) v2[v4]) * 1073741824)) {
                    v4++;
                } else {
                    return 1;
                }
            }
            return 0;
        } else {
            return 1;
        }
    }

    private org.json.JSONObject config()
    {
        try {
            return new org.json.JSONObject(com.personal.aihub.PreviewCache.read(new java.io.File(this.root, "settings.json")));
        } catch (Exception) {
            return new org.json.JSONObject();
        }
    }

    private java.io.File ensure(String p3)
    {
        return this.ensure(p3, 167772160);
    }

    private java.io.File ensure(String p19, long p20)
    {
        if (Thread.currentThread().isInterrupted()) {
            throw new java.io.InterruptedIOException("Preview closed");
        } else {
            java.io.File v2_1 = com.personal.aihub.PreviewCache.normalized(p19);
            String v3_2 = this.file(v2_1);
            java.io.File v5_1 = new StringBuilder();
            v5_1.append(v3_2);
            v5_1.append(".body");
            boolean v4_3 = new java.io.File(v5_1.toString());
            Object v6_2 = new StringBuilder();
            v6_2.append(v3_2);
            v6_2.append(".json");
            java.io.File v5_4 = new java.io.File(v6_2.toString());
            if ((!v4_3.isFile()) || (!v5_4.isFile())) {
                if (this.offline()) {
                    throw new java.io.IOException("This resource has not been saved for offline preview");
                } else {
                    try {
                        if (Thread.currentThread().isInterrupted()) {
                            throw new java.io.InterruptedIOException("Preview closed");
                        } else {
                            if ((!v4_3.isFile()) || (!v5_4.isFile())) {
                                java.net.HttpURLConnection v7_8 = ((java.net.HttpURLConnection) new java.net.URL(v2_1).openConnection());
                                v7_8.setConnectTimeout(20000);
                                v7_8.setReadTimeout(60000);
                                v7_8.setInstanceFollowRedirects(0);
                                v7_8.setRequestProperty("User-Agent", "DokkanUnitCreator/2.5");
                                long v10_4 = new StringBuilder();
                                v10_4.append(v3_2);
                                v10_4.append(".tmp");
                                String v9_1 = new java.io.File(v10_4.toString());
                                try {
                                    java.io.File v2_0;
                                    if (v7_8.getResponseCode() != 200) {
                                        v2_0 = v9_1;
                                        boolean v4_6 = new StringBuilder("Eclipse returned HTTP ");
                                        v4_6.append(v7_8.getResponseCode());
                                        throw new java.io.IOException(v4_6.toString());
                                    } else {
                                        long v10_0 = v7_8.getContentLengthLong();
                                        if (v10_0 > p20) {
                                            v2_0 = v9_1;
                                            throw new java.io.IOException("Preview resource exceeds 160 MB");
                                        } else {
                                            java.io.InputStream v12 = v7_8.getInputStream();
                                            try {
                                                java.io.FileOutputStream v13_1 = new java.io.FileOutputStream(v9_1);
                                                try {
                                                    java.io.IOException v0_7 = new byte[65536];
                                                    long v16 = 0;
                                                } catch (java.io.IOException v0_8) {
                                                    v2_0 = v9_1;
                                                    String v3_1 = v0_8;
                                                    try {
                                                        v13_1.close();
                                                    } catch (java.io.IOException v0_32) {
                                                        v3_1.addSuppressed(v0_32);
                                                    } catch (java.io.IOException v0_6) {
                                                        String v3_5 = v0_6;
                                                        if (v12 != null) {
                                                            try {
                                                                v12.close();
                                                            } catch (java.io.IOException v0_33) {
                                                                v3_5.addSuppressed(v0_33);
                                                            }
                                                        }
                                                        throw v3_5;
                                                    }
                                                    throw v3_1;
                                                }
                                                while(true) {
                                                    int v14 = v12.read(v0_7);
                                                    if (v14 == -1) {
                                                        break;
                                                    }
                                                    try {
                                                        java.io.File v15_4;
                                                        if (Thread.currentThread().isInterrupted()) {
                                                            v15_4 = v9_1;
                                                            throw new java.io.InterruptedIOException("Preview closed");
                                                        } else {
                                                            v15_4 = v9_1;
                                                            v16 += ((long) v14);
                                                            if (v16 > p20) {
                                                                throw new java.io.IOException("Preview resource exceeds 160 MB");
                                                            } else {
                                                                v13_1.write(v0_7, 0, v14);
                                                                v9_1 = v15_4;
                                                            }
                                                        }
                                                        v3_1 = java.io.IOException v0_27;
                                                        v2_0 = v15_4;
                                                    } catch (java.io.IOException v0_27) {
                                                        v15_4 = v9_1;
                                                    } catch (java.io.IOException v0_27) {
                                                    }
                                                }
                                                java.io.File v15_1 = v9_1;
                                                try {
                                                    v13_1.close();
                                                    try {
                                                        if (v12 != null) {
                                                            v12.close();
                                                        }
                                                    } catch (java.io.IOException v0_4) {
                                                        v2_0 = v15_1;
                                                    }
                                                    if (((v7_8.getContentEncoding() == null) || (v7_8.getContentEncoding().equalsIgnoreCase("identity"))) && (v10_0 > 0)) {
                                                        if (v10_0 != v16) {
                                                            throw new java.io.IOException("Incomplete preview download");
                                                        } else {
                                                        }
                                                    }
                                                    if ((this.settings(new org.json.JSONObject()).getLong("bytes") + v16) > this.storageLimit()) {
                                                        v2_0 = v15_1;
                                                        throw new java.io.IOException("Saved preview storage is full. Increase its size or clear downloaded previews in Animation Studio.");
                                                    } else {
                                                        java.io.IOException v0_22 = v7_8.getContentType();
                                                        org.json.JSONObject vtmp39 = new org.json.JSONObject().put("url", v2_1);
                                                        if (v0_22 == null) {
                                                            v0_22 = "application/octet-stream";
                                                        }
                                                        java.io.IOException v0_23 = vtmp39.put("type", v0_22);
                                                        v2_0 = v15_1;
                                                        if (!v2_0.renameTo(v4_3)) {
                                                            throw new java.io.IOException("Could not save preview");
                                                        } else {
                                                            com.personal.aihub.PreviewCache.write(v5_4, v0_23.toString());
                                                            v7_8.disconnect();
                                                            v2_0.delete();
                                                            return v3_2;
                                                        }
                                                    }
                                                } catch (java.io.IOException v0_6) {
                                                    v2_0 = v15_1;
                                                }
                                            } catch (java.io.IOException v0_6) {
                                                v2_0 = v9_1;
                                            }
                                        }
                                    }
                                } catch (java.io.IOException v0_4) {
                                    v2_0 = v9_1;
                                } catch (java.io.IOException v0_4) {
                                }
                                v7_8.disconnect();
                                v2_0.delete();
                                throw v0_4;
                            } else {
                                return v3_2;
                            }
                        }
                    } catch (java.io.IOException v0_34) {
                        throw v0_34;
                    }
                }
            } else {
                return v3_2;
            }
        }
    }

    private java.io.File file(String p7)
    {
        java.io.File v7_4 = java.security.MessageDigest.getInstance("SHA-256").digest(p7.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        String v0_4 = new StringBuilder();
        java.io.File v1_0 = v7_4.length;
        int v2 = 0;
        while (v2 < v1_0) {
            v0_4.append(String.format(java.util.Locale.US, "%02x", new Object[] {Integer.valueOf((v7_4[v2] & 255))})));
            v2++;
        }
        return new java.io.File(this.root, v0_4.toString());
    }

    private static String normalized(String p11)
    {
        String v0_1 = new java.net.URI(p11);
        if ((!"https".equals(v0_1.getScheme())) || ((!"dokkan-eclipse.com".equals(v0_1.getHost())) || ((v0_1.getPort() != -1) || ((v0_1.getUserInfo() != null) || (!v0_1.getPath().matches("/(tools/.*|assets/.*|static/.*|css/.*|cdn/uncompressed/.*|api/.*)")))))) {
            throw new java.io.IOException("Unsupported public preview resource");
        } else {
            java.io.IOException v11_12 = new java.util.TreeMap();
            String v2_0 = "";
            if (v0_1.getRawQuery() != null) {
                StringBuilder v1_6 = v0_1.getRawQuery().split("&");
                String v4_1 = v1_6.length;
                int v6 = 0;
                while (v6 < v4_1) {
                    String v7_1;
                    String v7_0 = v1_6[v6].split("=", 2);
                    String v8_1 = java.net.URLDecoder.decode(v7_0[0], "UTF-8");
                    if (v7_0.length <= 1) {
                        v7_1 = "";
                    } else {
                        v7_1 = java.net.URLDecoder.decode(v7_0[1], "UTF-8");
                    }
                    if (v8_1.equals("patch")) {
                        throw new java.io.IOException("Private patch previews are not cached");
                    } else {
                        if ((!v8_1.matches("_|_t|t|ts|timestamp|cacheBust|nocache")) || (!v7_1.matches("[0-9]+"))) {
                            v11_12.put(v8_1, v7_1);
                        }
                        v6++;
                    }
                }
            }
            StringBuilder v1_8 = new StringBuilder();
            java.io.IOException v11_14 = v11_12.entrySet().iterator();
            while (v11_14.hasNext()) {
                String v4_4 = ((java.util.Map$Entry) v11_14.next());
                if (v1_8.length() > 0) {
                    v1_8.append(38);
                }
                v1_8.append(java.net.URLEncoder.encode(((String) v4_4.getKey()), "UTF-8"));
                v1_8.append(61);
                v1_8.append(java.net.URLEncoder.encode(((String) v4_4.getValue()), "UTF-8"));
            }
            java.io.IOException v11_16 = new StringBuilder("https://dokkan-eclipse.com");
            v11_16.append(v0_1.getRawPath());
            if (v1_8.length() > 0) {
                String v0_7 = new StringBuilder("?");
                v0_7.append(v1_8);
                v2_0 = v0_7.toString();
            }
            v11_16.append(v2_0);
            return v11_16.toString();
        }
    }

    private static String read(java.io.File p4)
    {
        Throwable v0_1 = new java.io.FileInputStream(p4);
        try {
            Throwable v4_4 = new java.io.ByteArrayOutputStream();
            try {
                String v1_4 = new byte[8192];
            } catch (String v1_2) {
                try {
                    v4_4.close();
                } catch (Throwable v4_2) {
                    v1_2.addSuppressed(v4_2);
                }
                throw v1_2;
            }
            while(true) {
                int v2 = v0_1.read(v1_4);
                if (v2 == -1) {
                    break;
                }
                v4_4.write(v1_4, 0, v2);
            }
            String v1_1 = v4_4.toString("UTF-8");
            v4_4.close();
            v0_1.close();
            return v1_1;
        } catch (Throwable v4_3) {
            try {
                v0_1.close();
            } catch (Throwable v0_2) {
                v4_3.addSuppressed(v0_2);
            }
            throw v4_3;
        }
    }

    private static android.webkit.WebResourceResponse result(int p7, String p8, java.util.Map p9, java.io.InputStream p10)
    {
        p10 = new android.webkit.WebResourceResponse;
        p10("text/plain", "UTF-8", p7, "Unavailable", p9, new java.io.ByteArrayInputStream(p8.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        return p10;
    }

    private long storageLimit()
    {
        long v0_1 = this.config().optLong("maxBytes", 2147483648);
        if (!com.personal.aihub.PreviewCache.budget(v0_1)) {
            return 2147483648;
        } else {
            return v0_1;
        }
    }

    private static void write(java.io.File p3, String p4)
    {
        java.io.FileOutputStream v1_2 = new StringBuilder();
        v1_2.append(p3);
        v1_2.append(".tmp");
        java.io.File v0_1 = new java.io.File(v1_2.toString());
        java.io.FileOutputStream v1_1 = new java.io.FileOutputStream(v0_1);
        try {
            v1_1.write(p4.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            v1_1.close();
        } catch (java.io.IOException v3_2) {
            try {
                v1_1.close();
            } catch (Throwable v4_2) {
                v3_2.addSuppressed(v4_2);
            }
            throw v3_2;
        }
        if (!v0_1.renameTo(p3)) {
            throw new java.io.IOException("Could not save preview settings");
        } else {
            return;
        }
    }

    java.io.File cachedBody(String p4)
    {
        int v4_7 = this.file(com.personal.aihub.PreviewCache.normalized(p4));
        java.io.File v1_4 = new StringBuilder();
        v1_4.append(v4_7);
        v1_4.append(".body");
        java.io.File v0_0 = new java.io.File(v1_4.toString());
        StringBuilder v2_1 = new StringBuilder();
        v2_1.append(v4_7);
        v2_1.append(".json");
        java.io.File v1_2 = new java.io.File(v2_1.toString());
        if ((!v0_0.isFile()) || (!v1_2.isFile())) {
            return 0;
        } else {
            return v0_0;
        }
    }

    void discard(String p7)
    {
        try {
            java.io.IOException v7_5 = this.file(com.personal.aihub.PreviewCache.normalized(p7));
            int v2_0 = 0;
        } catch (java.io.IOException v7_4) {
            throw v7_4;
        }
        while (v2_0 < 4) {
            boolean v4_1 = new StringBuilder();
            v4_1.append(v7_5);
            v4_1.append(new String[] {".body", ".json", ".tmp", ".json.tmp"})[v2_0]);
            boolean v3_2 = new java.io.File(v4_1.toString());
            if (v3_2.exists()) {
                if (!v3_2.delete()) {
                    throw new java.io.IOException("Could not repair a saved preview tool");
                } else {
                }
            }
            v2_0++;
        }
        return;
    }

    boolean offline()
    {
        try {
            return new org.json.JSONObject(com.personal.aihub.PreviewCache.read(new java.io.File(this.root, "settings.json"))).optBoolean("offline");
        } catch (Exception) {
            return 0;
        }
    }

    java.io.File prepareBody(String p4, int p5, long p6)
    {
        try {
            if ((com.personal.aihub.PreviewCache.revision != p6) || (this.offline())) {
                throw new java.io.IOException("Preview preparation stopped because storage or offline settings changed.");
            } else {
                if ((p5 < 1) || (p5 > 16777216)) {
                    throw new java.io.IOException("Invalid preview tool size");
                } else {
                    StringBuilder v7_1 = new StringBuilder();
                    v7_1.append(this.ensure(p4, ((long) p5)));
                    v7_1.append(".body");
                    return new java.io.File(v7_1.toString());
                }
            }
        } catch (String v4_6) {
            throw v4_6;
        }
    }

    java.io.File resourceBody(String p4, long p5)
    {
        if ((p5 < 1) || (p5 > 167772160)) {
            throw new java.io.IOException("Invalid preview resource limit");
        } else {
            long v1_1 = new StringBuilder();
            v1_1.append(this.ensure(p4, p5));
            v1_1.append(".body");
            java.io.File v0_3 = new java.io.File(v1_1.toString());
            if (v0_3.length() > p5) {
                throw new java.io.IOException("This music resource exceeds its preview size limit");
            } else {
                return v0_3;
            }
        }
    }

    android.webkit.WebResourceResponse response(android.webkit.WebResourceRequest p23)
    {
        java.util.HashMap v12_1 = new java.util.HashMap();
        v12_1.put("Access-Control-Allow-Origin", "*");
        v12_1.put("Accept-Ranges", "bytes");
        v12_1.put("Cache-Control", "no-store");
        try {
            if ((p23.getMethod().equals("GET")) || (p23.getMethod().equals("HEAD"))) {
                android.webkit.WebResourceResponse v5_17 = this.ensure(p23.getUrl().toString());
                java.io.IOException v8_6 = new StringBuilder();
                v8_6.append(v5_17);
                v8_6.append(".body");
                int v7_5 = new java.io.File(v8_6.toString());
                java.util.HashMap v10_4 = new StringBuilder();
                v10_4.append(v5_17);
                v10_4.append(".json");
                String v9_5 = new org.json.JSONObject(com.personal.aihub.PreviewCache.read(new java.io.File(v10_4.toString()))).getString("type").split(";")[0];
                java.util.HashMap v10_5 = v7_5.length();
                String v16 = v9_5;
                java.io.IOException v8_0 = (v10_5 - 1);
                android.webkit.WebResourceResponse v5_27 = ((String) p23.getRequestHeaders().get("Range"));
                if (v5_27 == null) {
                    v5_27 = ((String) p23.getRequestHeaders().get("range"));
                }
                int v0_7;
                android.webkit.WebResourceResponse v5_4;
                long v17_2;
                if (v5_27 == null) {
                    v17_2 = "HEAD";
                    v0_7 = 200;
                    v5_4 = 0;
                } else {
                    if ((!v5_27.matches("bytes=([0-9]+-[0-9]*|-[0-9]+)")) || (v10_5 == 0)) {
                        throw new java.io.IOException();
                    } else {
                        StringBuilder v13_1 = v5_27.substring(6).split("-", -1);
                        if (!v13_1[0].isEmpty()) {
                            v17_2 = "HEAD";
                            long v20 = Long.parseLong(v13_1[0]);
                            if (!v13_1[1].isEmpty()) {
                                v8_0 = Math.min(v8_0, Long.parseLong(v13_1[1]));
                            }
                            v5_4 = v20;
                        } else {
                            long v19_1 = Long.parseLong(v13_1[1]);
                            if (v19_1 <= 0) {
                                throw new java.io.IOException();
                            } else {
                                v17_2 = "HEAD";
                                v5_4 = Math.max(0, (v10_5 - v19_1));
                            }
                        }
                        if ((v5_4 >= v10_5) || (v8_0 < v5_4)) {
                            throw new java.io.IOException();
                        } else {
                            StringBuilder v13_5 = new StringBuilder("bytes ");
                            v13_5.append(v5_4);
                            v13_5.append("-");
                            v13_5.append(v8_0);
                            v13_5.append("/");
                            v13_5.append(v10_5);
                            v12_1.put("Content-Range", v13_5.toString());
                            v0_7 = 206;
                        }
                    }
                }
                java.io.IOException v8_2 = ((v8_0 - v5_4) + 1);
                v12_1.put("Content-Length", Long.toString(v8_2));
                if (!p23.getMethod().equals(v17_2)) {
                    android.webkit.WebResourceResponse v2_6 = new java.io.FileInputStream(v7_5);
                    java.util.HashMap v10_0 = 0;
                    while (v10_0 < v5_4) {
                        try {
                            StringBuilder v13_7 = v2_6.skip((v5_4 - v10_0));
                        } catch (int v0_15) {
                            v2_6.close();
                            throw v0_15;
                        }
                        if (v13_7 <= 0) {
                            throw new java.io.IOException("Invalid byte offset");
                        } else {
                            v10_0 += v13_7;
                        }
                    }
                    String v9_0;
                    com.personal.aihub.PreviewCache$1 v11_1 = new com.personal.aihub.PreviewCache$1(this, v2_6, v8_2);
                    android.webkit.WebResourceResponse v2_7 = new android.webkit.WebResourceResponse;
                    if (v0_7 != 206) {
                        v9_0 = "OK";
                    } else {
                        v9_0 = "Partial Content";
                    }
                    v2_7(v16, 0, v0_7, v9_0, v12_1, v11_1);
                    return v2_7;
                } else {
                    String v9_1;
                    android.webkit.WebResourceResponse v2_9 = new android.webkit.WebResourceResponse;
                    if (v0_7 != 206) {
                        v9_1 = "OK";
                    } else {
                        v9_1 = "Partial Content";
                    }
                    String v3_6 = new byte[0];
                    v2_9(v16, 0, v0_7, v9_1, v12_1, new java.io.ByteArrayInputStream(v3_6));
                    return v2_9;
                }
            } else {
                return com.personal.aihub.PreviewCache.result(405, "Method not allowed", v12_1, 0);
            }
        } catch (int v0_18) {
            return com.personal.aihub.PreviewCache.result(503, String.valueOf(v0_18.getMessage()), v12_1, 0);
        }
    }

    long revision()
    {
        return com.personal.aihub.PreviewCache.revision;
    }

    org.json.JSONObject settings(org.json.JSONObject p10)
    {
        try {
            if (p10.has("clear")) {
                if (!(p10.get("clear") instanceof Boolean)) {
                    throw new java.io.IOException("Invalid preview storage request.");
                } else {
                }
            }
        } catch (java.io.IOException v10_9) {
            throw v10_9;
        }
        long v1_6 = this.config();
        if (p10.has("maxBytes")) {
            long v2_4 = p10.get("maxBytes");
            String v3_3 = p10.getLong("maxBytes");
            if ((!(v2_4 instanceof Number)) || ((((Number) v2_4).doubleValue() != ((double) v3_3)) || (!com.personal.aihub.PreviewCache.budget(v3_3)))) {
                throw new java.io.IOException("Choose one of the preview storage sizes.");
            } else {
                v1_6.put("maxBytes", v3_3);
            }
        }
        if (p10.has("offline")) {
            long v2_12 = p10.getBoolean("offline");
            if (v2_12 != this.offline()) {
                com.personal.aihub.PreviewCache.revision = (com.personal.aihub.PreviewCache.revision + 1);
            }
            v1_6.put("offline", v2_12);
        }
        int v5_0 = 0;
        if (p10.optBoolean("clear")) {
            com.personal.aihub.PreviewCache.revision = (com.personal.aihub.PreviewCache.revision + 1);
            long v2_16 = this.root.listFiles();
            if (v2_16 != 0) {
                int v4_2 = 0;
                while (v4_2 < v2_16.length) {
                    long v6_2 = v2_16[v4_2];
                    if (v6_2.getName().matches("[a-f0-9]{64}\\.(body|json|tmp)(\\.tmp)?$")) {
                        if (!v6_2.delete()) {
                            throw new java.io.IOException("Could not clear a saved preview file.");
                        } else {
                        }
                    }
                    v4_2++;
                }
            }
        }
        if ((p10.has("offline")) || (p10.has("maxBytes"))) {
            com.personal.aihub.PreviewCache.write(new java.io.File(this.root, "settings.json"), v1_6.toString());
        }
        java.io.IOException v10_16 = this.root.listFiles();
        long v1_4 = 0;
        if (v10_16 != null) {
            String v3_7 = v10_16.length;
            int v4_1 = 0;
            while (v5_0 < v3_7) {
                long v6_0 = v10_16[v5_0];
                if (v6_0.getName().matches("[a-f0-9]{64}\\.body")) {
                    v1_4 += v6_0.length();
                    v4_1++;
                }
                v5_0++;
            }
            v5_0 = v4_1;
        }
        return new org.json.JSONObject().put("offline", this.offline()).put("bytes", v1_4).put("count", v5_0).put("maxBytes", this.storageLimit());
    }

    String text(String p4, int p5)
    {
        long v1_2 = new StringBuilder();
        v1_2.append(this.ensure(p4));
        v1_2.append(".body");
        java.io.File v0_1 = new java.io.File(v1_2.toString());
        if (v0_1.length() > ((long) p5)) {
            throw new java.io.IOException("Preview text exceeds the size limit");
        } else {
            return com.personal.aihub.PreviewCache.read(v0_1);
        }
    }
}
