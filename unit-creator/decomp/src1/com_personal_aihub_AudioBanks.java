package com.personal.aihub;
public final class AudioBanks {
    public static final long ACB_MAX = 33554432;
    public static final long AWB_MAX = 167772160;
    private static final int MAX_BANKS = 4096;
    private static final int MAX_GROUPS = 512;
    private static final int MAX_SCANNED = 50000;
    private org.json.JSONObject cached;
    private boolean closed;
    private long comparedBytes;
    private final boolean onlyAliases;
    private final org.json.JSONArray overlays;
    private final String preferredKey;
    private final java.util.Map records;
    private final java.io.File root;
    private int scanned;

    public AudioBanks(java.io.File p2)
    {
        this(p2, 0, 0);
        return;
    }

    public AudioBanks(java.io.File p2, String p3, org.json.JSONArray p4)
    {
        this(p2, p3, p4, 0);
        return;
    }

    public AudioBanks(java.io.File p2, String p3, org.json.JSONArray p4, boolean p5)
    {
        this.records = new java.util.HashMap();
        this.root = p2;
        this.preferredKey = p3;
        this.overlays = p4;
        this.onlyAliases = p5;
        return;
    }

    private void add(java.util.Map p8, String p9, String p10, String p11, boolean p12, boolean p13)
    {
        String v9_1 = com.personal.aihub.AudioBanks.identity(p9);
        if (v9_1 != null) {
            java.io.File v0_1 = this.checked(p10, 33554432, 0);
            if (v0_1 != null) {
                java.io.File v2_0;
                if (p11 == null) {
                    v2_0 = 0;
                } else {
                    long v3_1 = new java.io.File(p10);
                    String v4_1 = new java.io.File(p11);
                    if ((!java.util.Objects.equals(v3_1.getParent(), v4_1.getParent())) || (!v3_1.getName().replaceFirst("(?i)\\.acb$", "").equalsIgnoreCase(v4_1.getName().replaceFirst("(?i)\\.awb$", "")))) {
                        throw new java.io.IOException("Audio bank companions must belong to the same collection and folder");
                    } else {
                        v2_0 = this.checked(p11, 167772160, 0);
                        if ((v2_0 == null) && (p13 != null)) {
                            throw new java.io.IOException("The selected audio companion is unavailable");
                        }
                    }
                }
                com.personal.aihub.AudioBanks$Candidate v13_2 = new com.personal.aihub.AudioBanks$Candidate(0);
                v13_2.identity = v9_1;
                v13_2.key = p10;
                if (v2_0 == null) {
                    p11 = 0;
                }
                v13_2.awbKey = p11;
                v13_2.acb = v0_1;
                v13_2.awb = v2_0;
                v13_2.explicit = p12;
                if (!p8.containsKey(v9_1.logical())) {
                    p8.put(v9_1.logical(), new java.util.LinkedHashMap());
                }
                ((java.util.Map) p8.get(v9_1.logical())).put(p10, v13_2);
                return;
            } else {
                if (p12 != null) {
                    throw new java.io.IOException("The selected audio bank is unavailable");
                } else {
                    return;
                }
            }
        } else {
            return;
        }
    }

    public static String assetRoute(String p3)
    {
        try {
            if ((p3 != null) && ((!p3.matches("(?s).*[\\\\%\\x00-\\x20\\x7f].*")) && (!java.util.regex.Pattern.compile("/(?:\\.|\\.\\.)(?:/|$)").matcher(p3).find()))) {
                if (p3.startsWith("/")) {
                    int v2_5 = new StringBuilder("https://dokkan-eclipse.com");
                    v2_5.append(p3);
                    p3 = v2_5.toString();
                }
                int v0_2 = new java.net.URI(p3);
                if (("https".equals(v0_2.getScheme())) && (("dokkan-eclipse.com".equals(v0_2.getHost())) && ((v0_2.getPort() == -1) && ((v0_2.getRawQuery() == null) && ((v0_2.getRawFragment() == null) && (v0_2.getUserInfo() == null)))))) {
                    String v3_11 = java.util.regex.Pattern.compile("^/_forge/audio-bank-assets/([A-Za-z0-9_-]{16,128}\\.(?:acb|awb))$").matcher(v0_2.getRawPath());
                    if (v3_11.matches()) {
                        return v3_11.group(1);
                    }
                }
            }
        } catch (Exception) {
        }
        return 0;
    }

    private java.io.File checked(String p7, long p8, boolean p10)
    {
        if ((java.nio.file.Files.isSymbolicLink(this.root.toPath())) || (!this.root.isDirectory())) {
            throw new java.io.IOException("Invalid imported audio folder");
        } else {
            if (!com.personal.aihub.GameAssets.safe(p7)) {
                throw new java.io.IOException("Invalid imported audio resource");
            } else {
                long v0_3 = this.root;
                java.io.IOException v7_5 = p7.split("/");
                long v1_1 = v7_5.length;
                String v2_0 = 0;
                while (v2_0 < v1_1) {
                    java.io.File v4_1 = new java.io.File(v0_3, v7_5[v2_0]);
                    if (java.nio.file.Files.isSymbolicLink(v4_1.toPath())) {
                        throw new java.io.IOException("Imported audio banks cannot use symbolic links");
                    } else {
                        if (v4_1.exists()) {
                            v2_0++;
                            v0_3 = v4_1;
                        } else {
                            return 0;
                        }
                    }
                }
                if (p10 == 0) {
                    if (!v0_3.isFile()) {
                        return 0;
                    }
                } else {
                    if (!v0_3.isDirectory()) {
                        return 0;
                    }
                }
                java.io.IOException v7_8 = v0_3.getCanonicalFile();
                long v1_2 = v7_8.getPath();
                String v2_2 = new StringBuilder();
                v2_2.append(String.valueOf(this.root.getCanonicalPath()));
                v2_2.append(java.io.File.separator);
                if (!v1_2.startsWith(v2_2.toString())) {
                    throw new java.io.IOException("Imported audio bank escapes its resource folder");
                } else {
                    if ((p10 == 0) && ((v0_3.length() == 0) || (v0_3.length() > p8))) {
                        throw new java.io.IOException("Imported audio bank exceeds its supported size");
                    } else {
                        return v7_8;
                    }
                }
            }
        }
    }

    private java.util.List entries(String p8)
    {
        java.io.IOException v8_7 = this.checked(p8.replaceAll("/$", ""), 0, 1);
        String v0_5 = new java.util.ArrayList();
        if (v8_7 != null) {
            java.io.IOException v8_1 = v8_7.listFiles();
            if (v8_1 == null) {
                throw new java.io.IOException("Imported audio folder cannot be read");
            } else {
                int v1_1 = v8_1.length;
                int v3 = 0;
                while (v3 < v1_1) {
                    String v4_0 = v8_1[v3];
                    boolean v5_1 = (this.scanned + 1);
                    this.scanned = v5_1;
                    if (v5_1 > 50000) {
                        throw new java.io.IOException("Imported audio discovery exceeds its 50,000-entry limit");
                    } else {
                        if ((com.personal.aihub.GameAssets.safe(v4_0.getName())) && (!v4_0.getName().contains("/"))) {
                            v0_5.add(v4_0.getName());
                        }
                        v3++;
                    }
                }
                java.util.Collections.sort(v0_5);
                return v0_5;
            }
        } else {
            return v0_5;
        }
    }

    private void folder(java.util.Map p12, String p13, String p14)
    {
        String v1_1 = new StringBuilder();
        v1_1.append(String.valueOf(p13));
        v1_1.append("/");
        v1_1.append(p14);
        String v1_3 = this.entries(v1_1.toString());
        java.util.HashMap v10_1 = new java.util.HashMap();
        void v3_0 = v1_3.iterator();
        while (v3_0.hasNext()) {
            java.util.Map v4_12 = ((String) v3_0.next());
            if (v10_1.put(java.text.Normalizer.normalize(v4_12, java.text.Normalizer$Form.NFC).toLowerCase(java.util.Locale.ROOT), v4_12) != null) {
                throw new java.io.IOException("Imported audio filenames are ambiguous");
            }
        }
        String v1_4 = v1_3.iterator();
        while (v1_4.hasNext()) {
            void v3_3 = ((String) v1_4.next());
            if (v3_3.toLowerCase(java.util.Locale.ROOT).endsWith(".acb")) {
                void v3_6;
                java.util.Map v4_9 = ((String) v10_1.get(java.text.Normalizer.normalize(v3_3.replaceFirst("(?i)\\.acb$", ".awb"), java.text.Normalizer$Form.NFC).toLowerCase(java.util.Locale.ROOT)));
                String v5_5 = new StringBuilder();
                v5_5.append(String.valueOf(p14));
                v5_5.append("/");
                v5_5.append(v3_3);
                String v5_6 = v5_5.toString();
                String v6_2 = new StringBuilder();
                v6_2.append(String.valueOf(p13));
                v6_2.append("/");
                v6_2.append(p14);
                v6_2.append("/");
                v6_2.append(v3_3);
                String v6_3 = v6_2.toString();
                if (v4_9 != null) {
                    void v3_5 = new StringBuilder();
                    v3_5.append(String.valueOf(p13));
                    v3_5.append("/");
                    v3_5.append(p14);
                    v3_5.append("/");
                    v3_5.append(v4_9);
                    v3_6 = v3_5.toString();
                } else {
                    v3_6 = 0;
                }
                this.add(p12, v5_6, v6_3, v3_6, 0, 0);
            }
        }
        return;
    }

    private static String group(String p3)
    {
        if ((!com.personal.aihub.GameAssets.safe(p3)) || (p3.split("/").length < 2)) {
            throw new java.io.IOException("Invalid selected audio collection");
        } else {
            return p3.split("/")[0];
        }
    }

    private boolean identical(com.personal.aihub.AudioBanks$Candidate p17, com.personal.aihub.AudioBanks$Candidate p18)
    {
        if ((com.personal.aihub.AudioBanks.group(p17.key).equals(com.personal.aihub.AudioBanks.group(p18.key))) && (p17.acb.length() == p18.acb.length())) {
            Throwable v3_7;
            if (p17.awb != null) {
                v3_7 = 0;
            } else {
                v3_7 = 1;
            }
            int v6_5;
            if (p18.awb != null) {
                v6_5 = 0;
            } else {
                v6_5 = 1;
            }
            if (v3_7 == v6_5) {
                if ((p17.awb == null) || (p17.awb.length() == p18.awb.length())) {
                    java.io.RandomAccessFile v10_4;
                    int v6_7 = p17.acb.length();
                    int v8_0 = 0;
                    if (p17.awb != null) {
                        v10_4 = p17.awb.length();
                    } else {
                        v10_4 = 0;
                    }
                    int v6_9 = ((v6_7 + v10_4) * 2);
                    java.io.RandomAccessFile v10_6 = this.comparedBytes;
                    if ((v10_6 + v6_9) <= 536870912) {
                        Throwable v3_20;
                        this.comparedBytes = (v10_6 + v6_9);
                        if (p17.awb != null) {
                            v3_20 = new String[][2];
                            v3_20[0] = new String[] {p17.key, p18.key});
                            v3_20[1] = new String[] {p17.awbKey, p18.awbKey});
                        } else {
                            v3_20 = new String[][1];
                            v3_20[0] = new String[] {p17.key, p18.key});
                        }
                        Throwable v0_9 = v3_20.length;
                        int v2_0 = 0;
                        while (v2_0 < v0_9) {
                            java.io.RandomAccessFile v10_10;
                            int v6_12 = v3_20[v2_0];
                            if (!v6_12[0].toLowerCase(java.util.Locale.ROOT).endsWith(".acb")) {
                                v10_10 = 167772160;
                            } else {
                                v10_10 = 33554432;
                            }
                            int v7_9 = this.checked(v6_12[0], v10_10, 0);
                            int v6_0 = this.checked(v6_12[1], v10_10, 0);
                            if ((v7_9 != 0) && ((v6_0 != 0) && (v7_9.length() == v6_0.length()))) {
                                java.io.RandomAccessFile v10_3 = new java.io.RandomAccessFile(v7_9, "r");
                                try {
                                    java.io.RandomAccessFile v12_2 = new java.io.RandomAccessFile(v6_0, "r");
                                    int v6_1 = 65536;
                                    try {
                                        byte[] v11_1 = new byte[65536];
                                        byte[] v13 = new byte[65536];
                                        long v14_0 = v7_9.length();
                                    } catch (Throwable v0_1) {
                                        int v2_1 = v0_1;
                                        try {
                                            v12_2.close();
                                        } catch (Throwable v0_2) {
                                            v2_1.addSuppressed(v0_2);
                                        }
                                        throw v2_1;
                                    }
                                    while (v14_0 > v8_0) {
                                        int v7_2 = ((int) Math.min(((long) v6_1), v14_0));
                                        v10_3.readFully(v11_1, 0, v7_2);
                                        v12_2.readFully(v13, 0, v7_2);
                                        int v8_2 = 0;
                                        while (v8_2 < v7_2) {
                                            if (v11_1[v8_2] == v13[v8_2]) {
                                                v8_2++;
                                            } else {
                                                v12_2.close();
                                                v10_3.close();
                                                return 0;
                                            }
                                        }
                                        v14_0 -= ((long) v7_2);
                                        v6_1 = 65536;
                                        v8_0 = 0;
                                    }
                                    v12_2.close();
                                    v10_3.close();
                                    v2_0++;
                                    v8_0 = 0;
                                } catch (Throwable v0_3) {
                                    int v2_2 = v0_3;
                                    try {
                                        v10_3.close();
                                    } catch (Throwable v0_4) {
                                        v2_2.addSuppressed(v0_4);
                                    }
                                    throw v2_2;
                                }
                            } else {
                                return 0;
                            }
                        }
                        return 1;
                    } else {
                        return 0;
                    }
                } else {
                    return 0;
                }
            }
        }
        return 0;
    }

    private static com.personal.aihub.AudioBanks$Identity identity(String p5)
    {
        String v0_9 = java.util.regex.Pattern.compile("^se/([A-Za-z0-9_-]{1,80})\\.acb$", 2).matcher(p5);
        String v4 = "";
        if (!v0_9.matches()) {
            com.personal.aihub.AudioBanks$Identity v5_1 = java.util.regex.Pattern.compile("^voice/(?:(en|ja)/)?([A-Za-z0-9_-]{1,80})/([A-Za-z0-9_-]{1,80})\\.acb$", 2).matcher(p5);
            if ((v5_1.matches()) && (v5_1.group(2).equals(v5_1.group(3)))) {
                String v0_6 = v5_1.group(2);
                if (v5_1.group(1) != null) {
                    v4 = v5_1.group(1).toLowerCase(java.util.Locale.ROOT);
                }
                return new com.personal.aihub.AudioBanks$Identity("voice", v0_6, v4);
            } else {
                return 0;
            }
        } else {
            return new com.personal.aihub.AudioBanks$Identity("se", v0_9.group(1), "");
        }
    }

    public declared_synchronized org.json.JSONObject catalogue()
    {
        void v8 = this;
        try {
            if (this.closed) {
                throw new java.io.IOException("This audio preview has closed");
            } else {
                java.io.IOException v0_21;
                if (this.cached == null) {
                    java.io.IOException v0_1 = com.personal.aihub.GameAssets.overlayMap(this.overlays);
                    java.util.HashSet v9_1 = new java.util.HashSet();
                    String v1_7 = this.preferredKey;
                    if ((v1_7 != null) && (!v1_7.isEmpty())) {
                        v9_1.add(com.personal.aihub.AudioBanks.group(this.preferredKey));
                    }
                    String v1_13 = v0_1.values().iterator();
                    while (v1_13.hasNext()) {
                        v9_1.add(com.personal.aihub.AudioBanks.group(((String) v1_13.next())));
                    }
                    if (java.nio.file.Files.isSymbolicLink(this.root.toPath())) {
                        throw new java.io.IOException("Invalid imported audio folder");
                    } else {
                        if (!this.root.exists()) {
                            this.cached = new org.json.JSONObject().put("version", 1).put("banks", new org.json.JSONArray()).put("warnings", new org.json.JSONArray());
                            v0_21 = new org.json.JSONObject(this.cached.toString());
                        } else {
                            if ((java.nio.file.Files.isSymbolicLink(this.root.toPath())) || (!this.root.isDirectory())) {
                                throw new java.io.IOException("Invalid imported audio folder");
                            } else {
                                boolean v2_29;
                                com.personal.aihub.AudioBanks$Record v11_4 = 0;
                                this.scanned = 0;
                                String v1_42 = new java.util.ArrayList();
                                if (!this.onlyAliases) {
                                    v2_29 = this.root.listFiles();
                                } else {
                                    v2_29 = new java.io.File[0];
                                }
                                if (!v2_29) {
                                    throw new java.io.IOException("Imported audio folder cannot be read");
                                } else {
                                    String v3_23 = v2_29.length;
                                    String v4_38 = 0;
                                    while (v4_38 < v3_23) {
                                        org.json.JSONObject v5_41 = v2_29[v4_38];
                                        if ((v5_41.isDirectory()) && ((!java.nio.file.Files.isSymbolicLink(v5_41.toPath())) && (com.personal.aihub.GameAssets.safe(v5_41.getName())))) {
                                            if (v1_42.size() >= 512) {
                                                throw new java.io.IOException("Imported audio discovery exceeds its collection limit");
                                            } else {
                                                v1_42.add(v5_41.getName());
                                            }
                                        }
                                        v4_38++;
                                    }
                                    java.util.Collections.sort(v1_42);
                                    String v12_0 = new java.util.TreeMap();
                                    String v1_0 = v1_42.iterator();
                                    while (v1_0.hasNext()) {
                                        boolean v2_18 = ((String) v1_0.next());
                                        String v4_26 = new StringBuilder();
                                        v4_26.append(String.valueOf(v2_18));
                                        v4_26.append("/files");
                                        String v4_27 = v4_26.toString();
                                        org.json.JSONObject v5_30 = new StringBuilder();
                                        v5_30.append(String.valueOf(v2_18));
                                        v5_30.append("/tutorial0");
                                        String v3_19 = new java.util.ArrayList(java.util.Arrays.asList(new String[] {v2_18, v4_27, v5_30.toString()})));
                                        String v4_31 = new StringBuilder();
                                        v4_31.append(String.valueOf(v2_18));
                                        v4_31.append("/Payload");
                                        String v4_34 = v8.entries(v4_31.toString()).iterator();
                                        while (v4_34.hasNext()) {
                                            org.json.JSONObject v5_38 = ((String) v4_34.next());
                                            if (v5_38.matches("[A-Za-z0-9_. -]{1,120}\\.app")) {
                                                java.util.Map v6_23 = new StringBuilder();
                                                v6_23.append(String.valueOf(v2_18));
                                                v6_23.append("/Payload/");
                                                v6_23.append(v5_38);
                                                v3_19.add(v6_23.toString());
                                                java.util.Map v6_26 = new StringBuilder();
                                                v6_26.append(String.valueOf(v2_18));
                                                v6_26.append("/Payload/");
                                                v6_26.append(v5_38);
                                                v6_26.append("/tutorial0");
                                                v3_19.add(v6_26.toString());
                                            }
                                        }
                                        boolean v2_19 = v3_19.iterator();
                                        while (v2_19.hasNext()) {
                                            String v3_22 = ((String) v2_19.next());
                                            v8 = v8.folder(v12_0, v3_22, "se");
                                            org.json.JSONObject v5_36 = 0;
                                            while (v5_36 < 3) {
                                                java.util.Map v6_19 = new String[] {"", "en/", "ja/"})[v5_36];
                                                boolean v7_29 = new StringBuilder();
                                                v7_29.append(String.valueOf(v3_22));
                                                v7_29.append("/voice/");
                                                v7_29.append(v6_19);
                                                boolean v7_32 = v8.entries(v7_29.toString()).iterator();
                                                while (v7_32.hasNext()) {
                                                    long v13_14 = ((String) v7_32.next());
                                                    if ((v13_14.matches("[A-Za-z0-9_-]{1,80}")) && ((!v13_14.equals("en")) && (!v13_14.equals("ja")))) {
                                                        long v14_11 = new StringBuilder();
                                                        v14_11.append("voice/");
                                                        v14_11.append(v6_19);
                                                        v14_11.append(v13_14);
                                                        v8 = v8.folder(v12_0, v3_22, v14_11.toString());
                                                    }
                                                }
                                                v5_36++;
                                            }
                                        }
                                    }
                                    long v13_0 = v0_1.entrySet().iterator();
                                    while (v13_0.hasNext()) {
                                        String v1_19 = ((java.util.Map$Entry) v13_0.next());
                                        if (com.personal.aihub.AudioBanks.identity(((String) v1_19.getKey())) != null) {
                                            org.json.JSONObject v5_26;
                                            boolean v2_15 = ((String) v0_1.get(((String) v1_19.getKey()).replaceFirst("(?i)\\.acb$", ".awb")));
                                            if (!v2_15) {
                                                v5_26 = ((String) v1_19.getValue()).replaceFirst("(?i)\\.acb$", ".awb");
                                            } else {
                                                v5_26 = v2_15;
                                            }
                                            boolean v7_27;
                                            if (!v2_15) {
                                                v7_27 = 0;
                                            } else {
                                                v7_27 = 1;
                                            }
                                            this.add(v12_0, ((String) v1_19.getKey()), ((String) v1_19.getValue()), v5_26, 1, v7_27);
                                        }
                                    }
                                    java.io.IOException v0_3 = new org.json.JSONArray();
                                    String v1_4 = new org.json.JSONArray();
                                    boolean v2_2 = v12_0.values().iterator();
                                    while (v2_2.hasNext()) {
                                        String v3_4 = new java.util.ArrayList(((java.util.Map) v2_2.next()).values());
                                        String v4_4 = new java.util.ArrayList();
                                        org.json.JSONObject v5_1 = new java.util.ArrayList();
                                        java.util.Map v6_0 = v3_4.iterator();
                                        while (v6_0.hasNext()) {
                                            boolean v7_26 = ((com.personal.aihub.AudioBanks$Candidate) v6_0.next());
                                            if (v7_26.explicit) {
                                                v4_4.add(v7_26);
                                            }
                                            if (v9_1.contains(com.personal.aihub.AudioBanks.group(v7_26.key))) {
                                                v5_1.add(v7_26);
                                            }
                                        }
                                        if (v4_4.isEmpty()) {
                                            if (!v5_1.isEmpty()) {
                                                v3_4 = v5_1;
                                            }
                                        } else {
                                            v3_4 = v4_4;
                                        }
                                        if (v3_4.size() > 1) {
                                            v3_4.sort(new com.personal.aihub.AudioBanks$1(v8));
                                            String v4_10 = new java.util.ArrayList();
                                            String v3_5 = v3_4.iterator();
                                            while (v3_5.hasNext()) {
                                                org.json.JSONObject v5_24 = ((com.personal.aihub.AudioBanks$Candidate) v3_5.next());
                                                java.util.Map v6_12 = v4_10.iterator();
                                                while (v6_12.hasNext()) {
                                                    if (v8.identical(((com.personal.aihub.AudioBanks$Candidate) v6_12.next()), v5_24)) {
                                                    }
                                                    return v0_21;
                                                }
                                                v4_10.add(v5_24);
                                            }
                                            v3_4 = v4_10;
                                        }
                                        if (v3_4.size() == 1) {
                                            if (v0_3.length() >= 4096) {
                                                throw new java.io.IOException("Imported audio discovery exceeds its 4,096-bank limit");
                                            } else {
                                                String v3_7 = ((com.personal.aihub.AudioBanks$Candidate) v3_4.get(v11_4));
                                                String v4_15 = java.util.UUID.randomUUID().toString().replace("-", "");
                                                org.json.JSONObject v5_10 = new org.json.JSONObject().put("id", v4_15).put("kind", v3_7.identity.kind).put("package", v3_7.identity.pkg).put("locale", v3_7.identity.locale);
                                                boolean v7_8 = new org.json.JSONObject();
                                                long v13_2 = new StringBuilder();
                                                v13_2.append("/_forge/audio-bank-assets/");
                                                v13_2.append(v4_15);
                                                v13_2.append(".acb");
                                                org.json.JSONObject v5_11 = v5_10.put("acb", v7_8.put("url", v13_2.toString()).put("size", v3_7.acb.length()));
                                                java.util.Map v6_8 = v8.records;
                                                boolean v7_12 = new StringBuilder();
                                                v7_12.append(String.valueOf(v4_15));
                                                v7_12.append(".acb");
                                                boolean v7_13 = v7_12.toString();
                                                long v14_2 = new com.personal.aihub.AudioBanks$Record;
                                                com.personal.aihub.AudioBanks$Record v11_0 = v14_2;
                                                v14_2(v3_7.key, v3_7.acb.length(), 33554432);
                                                v6_8.put(v7_13, v11_0);
                                                if (v3_7.awb != null) {
                                                    boolean v7_15 = new org.json.JSONObject();
                                                    String v12_8 = new StringBuilder();
                                                    v12_8.append("/_forge/audio-bank-assets/");
                                                    v12_8.append(v4_15);
                                                    v12_8.append(".awb");
                                                    v5_11.put("awb", v7_15.put("url", v12_8.toString()).put("size", v3_7.awb.length()));
                                                    java.util.Map v6_11 = v8.records;
                                                    boolean v7_19 = new StringBuilder();
                                                    v7_19.append(String.valueOf(v4_15));
                                                    v7_19.append(".awb");
                                                    String v4_18 = v7_19.toString();
                                                    boolean v7_20 = new com.personal.aihub.AudioBanks$Record;
                                                    v7_20(v3_7.awbKey, v3_7.awb.length(), 167772160);
                                                    v6_11.put(v4_18, v7_20);
                                                }
                                                v0_3.put(v5_11);
                                            }
                                        } else {
                                            String v3_10 = ((com.personal.aihub.AudioBanks$Candidate) v3_4.get(v11_4));
                                            if (v1_4.length() < 64) {
                                                String v3_12;
                                                String v4_21 = new StringBuilder();
                                                v4_21.append("More than one imported ");
                                                v4_21.append(v3_10.identity.kind);
                                                v4_21.append(" bank supplies ");
                                                v4_21.append(v3_10.identity.pkg);
                                                v4_21.append(" (");
                                                if (!v3_10.identity.locale.isEmpty()) {
                                                    v3_12 = v3_10.identity.locale;
                                                } else {
                                                    v3_12 = "default";
                                                }
                                                v4_21.append(v3_12);
                                                v4_21.append("). Select a single source collection to preview it.");
                                                v1_4.put(v4_21.toString());
                                            }
                                        }
                                        v11_4 = 0;
                                    }
                                    v8.cached = new org.json.JSONObject().put("version", 1).put("banks", v0_3).put("warnings", v1_4);
                                    return new org.json.JSONObject(v8.cached.toString());
                                }
                            }
                        }
                    }
                } else {
                    v0_21 = new org.json.JSONObject(this.cached.toString());
                }
                return v0_21;
            }
        } catch (java.io.IOException v0_22) {
            throw v0_22;
        }
    }

    public declared_synchronized void close()
    {
        try {
            this.closed = 1;
            this.records.clear();
            this.cached = 0;
            return;
        } catch (Throwable v0_3) {
            throw v0_3;
        }
    }

    public declared_synchronized java.io.File resolve(String p6)
    {
        try {
            String v0_1;
            java.io.IOException v6_1 = com.personal.aihub.AudioBanks.assetRoute(p6);
        } catch (java.io.IOException v6_5) {
            throw v6_5;
        }
        if (v6_1 == null) {
            v0_1 = 0;
        } else {
            this.catalogue();
            java.io.IOException v6_7 = ((com.personal.aihub.AudioBanks$Record) this.records.get(v6_1));
            if (v6_7 == null) {
            } else {
                v0_1 = this.checked(v6_7.key, v6_7.max, 0);
                if ((v0_1 == null) || (v0_1.length() != v6_7.size)) {
                    throw new java.io.IOException("The selected imported audio bank changed or is unavailable");
                } else {
                }
            }
        }
        return v0_1;
    }
}
