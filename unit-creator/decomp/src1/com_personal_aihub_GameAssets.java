package com.personal.aihub;
public final class GameAssets {
    private static final java.util.regex.Pattern DATABASE = None;
    public static final int MAX_BYTES = 167772160;
    private static final java.util.regex.Pattern PREFIX;
    private static final java.util.Set PRIVATE;
    private final org.json.JSONArray overlays;
    private final String preferredKey;
    private final java.io.File root;

    static GameAssets()
    {
        String v3 = "exports";
        String v5 = "metadata.json";
        String v7 = "database-meta.json";
        String v9 = "account.txt";
        com.personal.aihub.GameAssets.PRIVATE = new java.util.HashSet(java.util.Arrays.asList(new String[] {"projects", "secrets.json"})));
        com.personal.aihub.GameAssets.DATABASE = java.util.regex.Pattern.compile("(?i).*\\.(db|sqlite|sqlite3)([-.].*)?$");
        com.personal.aihub.GameAssets.PREFIX = java.util.regex.Pattern.compile("^(lua|script|character|ingame|movie|layout|bgm|outgame|origin|item|se|voice|comic_text|fonts|shader|dokkan_field|card_[a-z0-9_]+)/");
        return;
    }

    public GameAssets(java.io.File p2)
    {
        this(p2, 0);
        return;
    }

    public GameAssets(java.io.File p2, String p3)
    {
        this(p2, p3, 0);
        return;
    }

    public GameAssets(java.io.File p1, String p2, org.json.JSONArray p3)
    {
        this.root = p1;
        if ((p2 == 0) || (p2.isEmpty())) {
            p2 = 0;
        }
        this.preferredKey = p2;
        this.overlays = p3;
        return;
    }

    public static String fontFallback(String p4)
    {
        if ((p4 != null) && ((p4.startsWith("fonts/")) && (!p4.startsWith("fonts/default/")))) {
            boolean v2_4 = p4.substring((p4.lastIndexOf(46) + 1)).toLowerCase(java.util.Locale.ROOT);
            if ((!v2_4.equals("otf")) && (!v2_4.equals("ttf"))) {
                return 0;
            } else {
                StringBuilder v0_2 = new StringBuilder("fonts/default/");
                v0_2.append(p4.substring(6));
                return v0_2.toString();
            }
        } else {
            return 0;
        }
    }

    public static String gamePath(String p3)
    {
        try {
            boolean v1_1 = new java.net.URI(p3);
            String v3_6 = v1_1.getPath();
        } catch (Exception) {
            return 0;
        }
        if ((v3_6 == null) || ((v3_6.indexOf(92) < 0) && (!java.util.regex.Pattern.compile("(^|/)\\.{1,2}(/|$)").matcher(v3_6).find()))) {
            String v3_5 = new java.net.URI("https://dokkan-eclipse.com").resolve(v1_1);
            if ("https".equals(v3_5.getScheme())) {
                if (((!"dokkan-eclipse.com".equals(v3_5.getHost())) && (!"cdn.dokkan-eclipse.com".equals(v3_5.getHost()))) || ((v3_5.getUserInfo() != null) || (v3_5.getPort() != -1))) {
                    return 0;
                } else {
                    String v3_7 = v3_5.getPath();
                    if (v3_7 != null) {
                        String v3_8;
                        if (!v3_7.startsWith("/cdn/uncompressed/")) {
                            if (v3_7.startsWith("/assets/")) {
                                v3_8 = v3_7.substring(8);
                            } else {
                                return 0;
                            }
                        } else {
                            v3_8 = v3_7.substring(18);
                        }
                        if ((!com.personal.aihub.GameAssets.safe(v3_8)) || (!com.personal.aihub.GameAssets.PREFIX.matcher(v3_8).find())) {
                            return 0;
                        } else {
                            return v3_8;
                        }
                    } else {
                        return 0;
                    }
                }
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    static int lambda$0(java.io.File p4, java.io.File p5)
    {
        int v0_1 = Long.compare(p5.lastModified(), p4.lastModified());
        if (v0_1 == 0) {
            v0_1 = p4.getName().compareTo(p5.getName());
        }
        return v0_1;
    }

    public static String mime(String p6)
    {
        boolean v6_22 = p6.substring((p6.lastIndexOf(46) + 1)).toLowerCase(java.util.Locale.ROOT);
        String v1 = "video/mp4";
        String v2 = "video/mpeg";
        String v3 = "image/jpeg";
        String v4 = "text/plain";
        String v5 = "application/octet-stream";
        switch (v6_22.hashCode()) {
            case 97669:
                if (v6_22.equals("bmp")) {
                    v5 = "image/bmp";
                }
                return v5;
            case 101548:
                if (!v6_22.equals("fnt")) {
                    v4 = "application/octet-stream";
                }
                return v4;
            case 101691:
                if (!v6_22.equals("fsh")) {
                    v4 = "application/octet-stream";
                }
                return v4;
            case 102340:
                if (v6_22.equals("gif")) {
                    v5 = "image/gif";
                }
                return v5;
            case 105441:
                if (!v6_22.equals("jpg")) {
                    v3 = "application/octet-stream";
                }
                return v3;
            case 106386:
                if (!v6_22.equals("m1v")) {
                    v2 = "application/octet-stream";
                }
                return v2;
            case 106417:
                if (!v6_22.equals("m2v")) {
                    v2 = "application/octet-stream";
                }
                return v2;
            case 106479:
                if (!v6_22.equals("m4v")) {
                    v1 = "application/octet-stream";
                }
                return v1;
            case 107512:
                if (!v6_22.equals("lua")) {
                    v4 = "application/octet-stream";
                }
                return v4;
            case 108272:
                if (v6_22.equals("mp3")) {
                    v5 = "audio/mpeg";
                }
                return v5;
            case 108273:
                if (!v6_22.equals("mp4")) {
                    v1 = "application/octet-stream";
                }
                return v1;
            case 109967:
                if (v6_22.equals("ogg")) {
                    v5 = "audio/ogg";
                }
                return v5;
            case 110369:
                if (v6_22.equals("otf")) {
                    v5 = "font/otf";
                }
                return v5;
            case 111145:
                if (v6_22.equals("png")) {
                    v5 = "image/png";
                }
                return v5;
            case 115174:
                if (v6_22.equals("ttf")) {
                    v5 = "font/ttf";
                }
                return v5;
            case 115312:
                if (!v6_22.equals("txt")) {
                    v4 = "application/octet-stream";
                }
                return v4;
            case 117067:
                if (!v6_22.equals("vsh")) {
                    v4 = "application/octet-stream";
                }
                return v4;
            case 117484:
                if (v6_22.equals("wav")) {
                    v5 = "audio/wav";
                }
                return v5;
            case 118807:
                if (v6_22.equals("xml")) {
                    v5 = "application/xml";
                }
                return v5;
            case 3268712:
                if (!v6_22.equals("jpeg")) {
                    v3 = "application/octet-stream";
                }
                return v3;
            case 3271912:
                if (v6_22.equals("json")) {
                    v5 = "application/json";
                }
                return v5;
            case 3645337:
                if (v6_22.equals("webm")) {
                    v5 = "video/webm";
                }
                return v5;
            case 3645340:
                if (v6_22.equals("webp")) {
                    v5 = "image/webp";
                }
                return v5;
            default:
                return "application/octet-stream";
        }
    }

    public static java.util.Map overlayMap(org.json.JSONArray p8)
    {
        String v0_1 = new java.util.LinkedHashMap();
        if (p8 != null) {
            if (p8.length() > 2000) {
                throw new java.io.IOException("Invalid preview asset manifest");
            } else {
                java.util.HashSet v1_1 = new java.util.HashSet();
                int v2_0 = 0;
                while (v2_0 < p8.length()) {
                    String v5_1;
                    boolean v3_1 = p8.optJSONObject(v2_0);
                    String v4_0 = "";
                    if (v3_1) {
                        v5_1 = v3_1.optString("path");
                    } else {
                        v5_1 = "";
                    }
                    if (v3_1) {
                        v4_0 = v3_1.optString("key");
                    }
                    boolean v3_3 = new StringBuilder("/assets/");
                    v3_3.append(v5_1);
                    if ((!v5_1.equals(com.personal.aihub.GameAssets.gamePath(v3_3.toString()))) || ((!com.personal.aihub.GameAssets.safe(v4_0)) || (v4_0.split("/").length < 2))) {
                        throw new java.io.IOException("Invalid preview asset alias");
                    } else {
                        java.util.Locale v6_5 = v5_1.substring((v5_1.lastIndexOf(46) + 1)).toLowerCase(java.util.Locale.ROOT);
                        boolean v3_15 = v4_0.substring((v4_0.lastIndexOf(46) + 1)).toLowerCase(java.util.Locale.ROOT);
                        if ((!v6_5.matches("png|jpe?g|webp|gif|bmp|lwf|lua|usm|cpk|kks|ogg|mp3|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|fsh|vsh|fnt|ttf|otf|strings|txt|bin")) || (!v6_5.equals(v3_15))) {
                            throw new java.io.IOException("Preview aliases need matching supported resource types");
                        } else {
                            if (!v1_1.add(java.text.Normalizer.normalize(v5_1, java.text.Normalizer$Form.NFC).toLowerCase(java.util.Locale.ROOT))) {
                                throw new java.io.IOException("Conflicting preview asset aliases");
                            } else {
                                v0_1.put(v5_1, v4_0);
                                v2_0++;
                            }
                        }
                    }
                }
                return v0_1;
            }
        } else {
            return v0_1;
        }
    }

    public static String preferredPath(String p5)
    {
        if (!com.personal.aihub.GameAssets.safe(p5)) {
            throw new java.io.IOException("Invalid selected game asset");
        } else {
            boolean v0_1 = new java.util.ArrayList(java.util.Arrays.asList(p5.split("/")));
            if (v0_1.size() < 2) {
                throw new java.io.IOException("Invalid selected game asset");
            } else {
                v0_1.remove(0);
                if ((!v0_1.isEmpty()) && (((String) v0_1.get(0)).equals("files"))) {
                    v0_1.remove(0);
                }
                if ((!v0_1.isEmpty()) && (((String) v0_1.get(0)).equals("tutorial0"))) {
                    v0_1.remove(0);
                }
                java.io.IOException v5_8 = String.join("/", v0_1);
                if ((!com.personal.aihub.GameAssets.safe(v5_8)) || (!com.personal.aihub.GameAssets.PREFIX.matcher(v5_8).find())) {
                    throw new java.io.IOException("Invalid selected game asset");
                } else {
                    return v5_8;
                }
            }
        }
    }

    private java.io.File regular(String p8)
    {
        String v0_1 = this.root.getCanonicalPath();
        String v1_1 = this.root;
        java.io.IOException v8_10 = p8.split("/");
        StringBuilder v2_4 = v8_10.length;
        int v3 = 0;
        while (v3 < v2_4) {
            java.io.File v5_1 = new java.io.File(v1_1, v8_10[v3]);
            if (java.nio.file.Files.isSymbolicLink(v5_1.toPath())) {
                throw new java.io.IOException("Imported game assets cannot use symbolic links");
            } else {
                if (v5_1.exists()) {
                    v3++;
                    v1_1 = v5_1;
                } else {
                    return 0;
                }
            }
        }
        if (v1_1.isFile()) {
            if (v1_1.length() > 167772160) {
                throw new java.io.IOException("Imported game asset exceeds the 160 MB preview limit");
            } else {
                java.io.IOException v8_5 = v1_1.getCanonicalFile();
                String v1_0 = v8_5.getPath();
                StringBuilder v2_2 = new StringBuilder();
                v2_2.append(String.valueOf(v0_1));
                v2_2.append(java.io.File.separator);
                if (!v1_0.startsWith(v2_2.toString())) {
                    throw new java.io.IOException("Imported game asset escapes its resource folder");
                } else {
                    return v8_5;
                }
            }
        } else {
            return 0;
        }
    }

    public static boolean safe(String p7)
    {
        if ((p7 == 0) || ((p7.isEmpty()) || ((p7.length() > 500) || (p7.startsWith("/"))))) {
            return 0;
        } else {
            int v2_1 = p7.toCharArray();
            boolean v4_0 = 0;
            while (v4_0 < v2_1.length) {
                java.util.Set v5_4 = v2_1[v4_0];
                if ((v5_4 != 92) && ((v5_4 != 58) && ((v5_4 != 37) && ((v5_4 >= 32) && (v5_4 != 127))))) {
                    v4_0++;
                } else {
                    return 0;
                }
            }
            String[] v1_0 = p7.split("/", -1);
            int v3_1 = 0;
            while (v3_1 < v1_0.length) {
                boolean v4_1 = v1_0[v3_1];
                if ((!v4_1.isEmpty()) && ((!v4_1.equals(".")) && ((!v4_1.equals("..")) && ((!v4_1.startsWith(".")) && (!com.personal.aihub.GameAssets.PRIVATE.contains(v4_1.toLowerCase(java.util.Locale.ROOT))))))) {
                    v3_1++;
                } else {
                    return 0;
                }
            }
            return (com.personal.aihub.GameAssets.DATABASE.matcher(p7).matches() ^ 1);
        }
    }

    public byte[] read(String p7, int p8)
    {
        if ((!com.personal.aihub.GameAssets.safe(p7)) || (!com.personal.aihub.GameAssets.PREFIX.matcher(p7).find())) {
            throw new java.io.IOException("Invalid game asset path");
        } else {
            java.io.FileInputStream v0_2 = new StringBuilder("/assets/");
            v0_2.append(p7);
            Throwable v7_3 = this.resolve(v0_2.toString());
            if (v7_3 != null) {
                if ((p8 < null) || ((p8 > 167772160) || (v7_3.length() > ((long) p8)))) {
                    throw new java.io.IOException("Imported game asset exceeds the supported size");
                } else {
                    java.io.FileInputStream v0_8 = new java.io.FileInputStream(v7_3);
                    try {
                        Throwable v7_7 = new java.io.ByteArrayOutputStream();
                        try {
                            String v1_2 = new byte[65536];
                            int v3 = 0;
                        } catch (java.io.IOException v8_6) {
                            try {
                                v7_7.close();
                            } catch (Throwable v7_8) {
                                v8_6.addSuppressed(v7_8);
                            }
                            throw v8_6;
                        }
                        while(true) {
                            int v4 = v0_8.read(v1_2);
                            if (v4 == -1) {
                                java.io.IOException v8_3 = v7_7.toByteArray();
                                v7_7.close();
                                v0_8.close();
                                return v8_3;
                            } else {
                                v3 += v4;
                                if (v3 > p8) {
                                    break;
                                }
                                v7_7.write(v1_2, 0, v4);
                            }
                        }
                        throw new java.io.IOException("Imported game asset changed or exceeds the supported size");
                    } catch (Throwable v7_9) {
                        try {
                            v0_8.close();
                        } catch (java.io.IOException v8_7) {
                            v7_9.addSuppressed(v8_7);
                        }
                        throw v7_9;
                    }
                }
            } else {
                return 0;
            }
        }
    }

    public java.io.File resolve(String p13)
    {
        String v13_1 = com.personal.aihub.GameAssets.gamePath(p13);
        if (v13_1 != null) {
            java.util.Iterator v1_11 = com.personal.aihub.GameAssets.overlayMap(this.overlays);
            String[] v2_4 = ((String) v1_11.get(v13_1));
            if (v2_4 == null) {
                java.util.Iterator v1_1 = v1_11.entrySet().iterator();
                int v5_7 = -1;
                while (v1_1.hasNext()) {
                    int v6_3 = ((java.util.Map$Entry) v1_1.next());
                    int v7_3 = ((String) v6_3.getKey());
                    int v6_5 = ((String) v6_3.getValue());
                    if ((v7_3.endsWith(".cpk")) && (v6_5.endsWith(".cpk"))) {
                        java.io.File v8_11 = new StringBuilder();
                        v8_11.append(v7_3.substring(0, (v7_3.length() - 4)));
                        v8_11.append("/");
                        int v7_5 = v8_11.toString();
                        if ((v13_1.startsWith(v7_5)) && (v7_5.length() > v5_7)) {
                            String[] v2_6 = new StringBuilder();
                            v2_6.append(v6_5.substring(0, (v6_5.length() - 4)));
                            v2_6.append("/");
                            v2_6.append(v13_1.substring(v7_5.length()));
                            v2_4 = v2_6.toString();
                            v5_7 = v7_5.length();
                        }
                    }
                }
            }
            java.util.Iterator v1_8;
            if (v2_4 != null) {
                v1_8 = 1;
            } else {
                java.util.Iterator v1_2 = this.preferredKey;
                if ((v1_2 == null) || ((!com.personal.aihub.GameAssets.preferredPath(v1_2).equals(v13_1)) && (!com.personal.aihub.GameAssets.preferredPath(this.preferredKey).equals(com.personal.aihub.GameAssets.fontFallback(v13_1))))) {
                    v1_8 = 0;
                }
            }
            if (this.root.exists()) {
                if ((java.nio.file.Files.isSymbolicLink(this.root.toPath())) || (!this.root.isDirectory())) {
                    throw new java.io.IOException("Invalid imported resource folder");
                } else {
                    if (v1_8 == null) {
                        java.util.Iterator v1_12 = this.root.listFiles();
                        if (v1_12 != null) {
                            String[] v2_8 = new java.util.ArrayList();
                            int v5_22 = v1_12.length;
                            int v6_1 = 0;
                            while (v6_1 < v5_22) {
                                int v7_1 = v1_12[v6_1];
                                if ((com.personal.aihub.GameAssets.safe(v7_1.getName())) && ((v7_1.isDirectory()) && (!java.nio.file.Files.isSymbolicLink(v7_1.toPath())))) {
                                    v2_8.add(v7_1);
                                }
                                v6_1++;
                            }
                            v2_8.sort(new com.personal.aihub.GameAssets$1(this));
                            java.util.Iterator v1_15 = v2_8.iterator();
                            while (v1_15.hasNext()) {
                                int v5_3 = ((java.io.File) v1_15.next());
                                java.io.File v9_6 = new StringBuilder();
                                v9_6.append(String.valueOf(v5_3.getName()));
                                v9_6.append("/");
                                v9_6.append(v13_1);
                                java.io.File v9_7 = v9_6.toString();
                                StringBuilder v10_7 = new StringBuilder();
                                v10_7.append(String.valueOf(v5_3.getName()));
                                v10_7.append("/files/");
                                v10_7.append(v13_1);
                                java.io.File v8_0 = v10_7.toString();
                                StringBuilder v10_9 = new StringBuilder();
                                v10_9.append(String.valueOf(v5_3.getName()));
                                v10_9.append("/tutorial0/");
                                v10_9.append(v13_1);
                                int v5_6 = v10_9.toString();
                                int v7_0 = 0;
                                while (v7_0 < 3) {
                                    java.io.File v8_2 = this.regular(new String[] {v9_7, v8_0, v5_6})[v7_0]);
                                    if (v8_2 == null) {
                                        v7_0++;
                                    } else {
                                        return v8_2;
                                    }
                                }
                            }
                            String v13_9 = com.personal.aihub.GameAssets.fontFallback(v13_1);
                            if (v13_9 != null) {
                                java.util.Iterator v1_16 = v2_8.iterator();
                                while (v1_16.hasNext()) {
                                    String[] v2_12 = ((java.io.File) v1_16.next());
                                    int v5_25 = new StringBuilder();
                                    v5_25.append(String.valueOf(v2_12.getName()));
                                    v5_25.append("/");
                                    v5_25.append(v13_9);
                                    int v5_0 = v5_25.toString();
                                    java.io.File v9_1 = new StringBuilder();
                                    v9_1.append(String.valueOf(v2_12.getName()));
                                    v9_1.append("/files/");
                                    v9_1.append(v13_9);
                                    java.io.File v9_2 = v9_1.toString();
                                    StringBuilder v10_3 = new StringBuilder();
                                    v10_3.append(String.valueOf(v2_12.getName()));
                                    v10_3.append("/tutorial0/");
                                    v10_3.append(v13_9);
                                    String[] v2_2 = v10_3.toString();
                                    int v5_1 = 0;
                                    while (v5_1 < 3) {
                                        java.io.File v9_4 = this.regular(new String[] {v5_0, v9_2, v2_2})[v5_1]);
                                        if (v9_4 == null) {
                                            v5_1++;
                                        } else {
                                            return v9_4;
                                        }
                                    }
                                }
                            }
                            return 0;
                        } else {
                            return 0;
                        }
                    } else {
                        if (v2_4 == null) {
                            v2_4 = this.preferredKey;
                        }
                        String v13_2 = this.regular(v2_4);
                        if (v13_2 == null) {
                            throw new java.io.IOException("The selected imported asset is unavailable. Choose it again.");
                        } else {
                            return v13_2;
                        }
                    }
                }
            } else {
                if (v1_8 != null) {
                    throw new java.io.IOException("The selected imported asset is unavailable. Choose it again.");
                } else {
                    return 0;
                }
            }
        } else {
            return 0;
        }
    }

    public android.webkit.WebResourceResponse response(android.webkit.WebResourceRequest p22)
    {
        Throwable v1_17 = this.resolve(p22.getUrl().toString());
        if (v1_17 != null) {
            byte[] v4_0 = p22.getMethod();
            java.util.HashMap v10_1 = new java.util.HashMap();
            v10_1.put("Accept-Ranges", "bytes");
            v10_1.put("Cache-Control", "no-store");
            v10_1.put("Cross-Origin-Resource-Policy", "same-origin");
            Throwable v5_8 = v1_17.length();
            java.io.ByteArrayInputStream v11_8 = (v5_8 - 1);
            if ((v4_0.equals("GET")) || (v4_0.equals("HEAD"))) {
                String v9_8 = p22.getRequestHeaders().entrySet().iterator();
                int v7_7 = 0;
                while (v9_8.hasNext()) {
                    Throwable v8_3 = ((java.util.Map$Entry) v9_8.next());
                    if (((String) v8_3.getKey()).equalsIgnoreCase("Range")) {
                        v7_7 = ((String) v8_3.getValue());
                    }
                    long v15 = 0;
                }
                Throwable v5_3;
                Throwable v0_2;
                byte[] v18_0;
                Throwable v1_9;
                if (v7_7 == 0) {
                    v18_0 = v1_17;
                    v1_9 = 0;
                    v0_2 = 200;
                    v5_3 = 0;
                } else {
                    try {
                        int v7_10 = java.util.regex.Pattern.compile("^bytes=(\\d*)-(\\d*)$").matcher(v7_7);
                    } catch (NumberFormatException) {
                        Throwable v1_5 = new StringBuilder("bytes */");
                        v1_5.append(v5_8);
                        v10_1.put("Content-Range", v1_5.toString());
                        v10_1.put("Content-Length", "0");
                        Throwable v0_1 = new android.webkit.WebResourceResponse;
                        Throwable v1_8 = new byte[0];
                        v0_1("text/plain", "UTF-8", 416, "Range Not Satisfiable", v10_1, new java.io.ByteArrayInputStream(v1_8));
                        return v0_1;
                    }
                    if (!v7_10.matches()) {
                        throw new NumberFormatException();
                    } else {
                        Throwable v1_3;
                        if (!v7_10.group(1).isEmpty()) {
                            v18_0 = v1_17;
                            long v19_1 = Long.parseLong(v7_10.group(1));
                            if (!v7_10.group(2).isEmpty()) {
                                v11_8 = Math.min(v11_8, Long.parseLong(v7_10.group(2)));
                            }
                            if ((v19_1 >= v5_8) || (v11_8 < v19_1)) {
                                throw new NumberFormatException();
                            } else {
                                v1_3 = v19_1;
                            }
                        } else {
                            long v19_0 = Long.parseLong(v7_10.group(2));
                            if ((v19_0 <= 0) || (v5_8 <= 0)) {
                                throw new NumberFormatException();
                            } else {
                                v18_0 = v1_17;
                                v1_3 = Math.max(0, (v5_8 - v19_0));
                            }
                        }
                        int v7_2 = new StringBuilder("bytes ");
                        v7_2.append(v1_3);
                        v7_2.append("-");
                        v7_2.append(v11_8);
                        v7_2.append("/");
                        v7_2.append(v5_8);
                        v10_1.put("Content-Range", v7_2.toString());
                        v5_3 = v1_3;
                        v0_2 = 206;
                        v1_9 = 0;
                    }
                }
                long v15_0;
                Throwable v2_3 = ((int) Math.max(0, ((v11_8 - v5_3) + 1)));
                v10_1.put("Content-Length", Integer.toString(v2_3));
                if (!v4_0.equals("HEAD")) {
                    v15_0 = v2_3;
                } else {
                    v15_0 = v1_9;
                }
                byte[] v4_1;
                Throwable v1_10 = new byte[v15_0];
                if (v15_0 <= 0) {
                    v4_1 = v18_0;
                } else {
                    v4_1 = v18_0;
                    Throwable v2_5 = new java.io.RandomAccessFile(v4_1, "r");
                    try {
                        v2_5.seek(v5_3);
                        v2_5.readFully(v1_10);
                        v2_5.close();
                    } catch (Throwable v0_3) {
                        Throwable v1_11 = v0_3;
                        try {
                            v2_5.close();
                        } catch (Throwable v0_4) {
                            v1_11.addSuppressed(v0_4);
                        }
                        throw v1_11;
                    }
                }
                int v7_5;
                String v6_3 = com.personal.aihub.GameAssets.mime(v4_1.getName());
                if ((!v6_3.startsWith("text/")) && ((!v6_3.equals("application/json")) && (!v6_3.equals("application/xml")))) {
                    v7_5 = 0;
                } else {
                    v7_5 = "UTF-8";
                }
                String v3_4;
                Throwable v2_14 = new android.webkit.WebResourceResponse;
                if (v0_2 != 206) {
                    v3_4 = "OK";
                } else {
                    v3_4 = "Partial Content";
                }
                v2_14(v6_3, v7_5, v0_2, v3_4, v10_1, new java.io.ByteArrayInputStream(v1_10));
                return v2_14;
            } else {
                v10_1.put("Content-Length", "0");
                Throwable v0_5 = new android.webkit.WebResourceResponse;
                Throwable v1_13 = new byte[0];
                v0_5("text/plain", "UTF-8", 405, "Method Not Allowed", v10_1, new java.io.ByteArrayInputStream(v1_13));
                return v0_5;
            }
        } else {
            return 0;
        }
    }
}
