package com.personal.aihub;
public final class GameDirectory {
    private final com.personal.aihub.GameAssets assets;
    private final org.json.JSONArray overlays;
    private final String preferred;
    private final java.io.File root;

    public GameDirectory(java.io.File p2)
    {
        this(p2, 0, 0);
        return;
    }

    public GameDirectory(java.io.File p2, String p3, org.json.JSONArray p4)
    {
        this.root = p2;
        this.preferred = p3;
        this.overlays = p4;
        this.assets = new com.personal.aihub.GameAssets(p2, p3, p4);
        return;
    }

    private static void bound(java.util.Map p1)
    {
        if (p1.size() > 200) {
            throw new java.io.IOException("This visual pack has more than 200 files. Choose a smaller pack.");
        } else {
            return;
        }
    }

    private java.io.File directory(String p7)
    {
        String v0_3 = this.root.getCanonicalPath();
        java.io.File v1_1 = this.root;
        int v7_7 = p7.split("/");
        StringBuilder v2_3 = v7_7.length;
        int v3 = 0;
        while (v3 < v2_3) {
            java.io.File v4_1 = new java.io.File(v1_1, v7_7[v3]);
            if (java.nio.file.Files.isSymbolicLink(v4_1.toPath())) {
                throw new java.io.IOException("Imported game assets cannot use symbolic links");
            } else {
                if (v4_1.isDirectory()) {
                    v3++;
                    v1_1 = v4_1;
                } else {
                    return 0;
                }
            }
        }
        int v7_1 = v1_1.getCanonicalFile();
        java.io.File v1_0 = v7_1.getPath();
        StringBuilder v2_1 = new StringBuilder();
        v2_1.append(String.valueOf(v0_3));
        v2_1.append(java.io.File.separator);
        if (!v1_0.startsWith(v2_1.toString())) {
            throw new java.io.IOException("Imported game folder escapes its resource folder");
        } else {
            return v7_1;
        }
    }

    private static org.json.JSONObject item(String p3, String p4, java.io.File p5)
    {
        long v0_4 = new org.json.JSONObject().put("type", "file").put("name", p4);
        StringBuilder v1_0 = new StringBuilder();
        v1_0.append(String.valueOf(p3));
        v1_0.append("/");
        v1_0.append(p4);
        return v0_4.put("path", v1_0.toString()).put("size", p5.length()).put("source", "imported");
    }

    static int lambda$0(java.io.File p4, java.io.File p5)
    {
        int v0_1 = Long.compare(p5.lastModified(), p4.lastModified());
        if (v0_1 == 0) {
            v0_1 = p4.getName().compareTo(p5.getName());
        }
        return v0_1;
    }

    public static org.json.JSONObject merge(org.json.JSONObject p17, org.json.JSONObject p18)
    {
        org.json.JSONObject v0_0 = p17;
        if ((p17 != null) && ((p18 != null) && ((p17.optString("path").equals(p18.optString("path"))) && (p18.optJSONArray("items") != null)))) {
            org.json.JSONObject v4_2 = new java.util.TreeMap();
            String v1_2 = p18.getJSONArray("items");
            String v5_0 = p17.getString("path");
            int v7 = 0;
            while (v7 < v1_2.length()) {
                org.json.JSONObject v16_0;
                String v8_1 = v1_2.optJSONObject(v7);
                if (v8_1 != null) {
                    String v10 = v8_1.optString("name");
                    String v11 = v8_1.optString("path");
                    long v12_1 = v8_1.optLong("size", -1);
                    if ((!v8_1.optString("type").equals("file")) || ((v10.contains("/")) || (!com.personal.aihub.GameDirectory.visual(v10)))) {
                        v16_0 = v1_2;
                    } else {
                        v16_0 = v1_2;
                        String v1_7 = new StringBuilder();
                        v1_7.append(String.valueOf(v5_0));
                        v1_7.append("/");
                        v1_7.append(v10);
                        if (v11.equals(v1_7.toString())) {
                            org.json.JSONObject v0_1 = new StringBuilder("/assets/");
                            v0_1.append(v11);
                            if ((v11.equals(com.personal.aihub.GameAssets.gamePath(v0_1.toString()))) && ((v12_1 >= 0) && (v12_1 <= 167772160))) {
                                v4_2.put(v10, new org.json.JSONObject().put("name", v10).put("path", v11).put("type", "file").put("size", v12_1).put("source", "public"));
                            }
                        }
                    }
                }
                v7++;
                v0_0 = p17;
                v1_2 = v16_0;
            }
            String v1_3 = v0_0.getJSONArray("items");
            String v6_1 = 0;
            while (v6_1 < v1_3.length()) {
                java.util.Iterator v2_4 = v1_3.getJSONObject(v6_1);
                v4_2.put(v2_4.getString("name"), v2_4);
                v6_1++;
            }
            com.personal.aihub.GameDirectory.bound(v4_2);
            String v1_5 = new org.json.JSONObject(p17.toString());
            org.json.JSONObject v0_18 = new org.json.JSONArray();
            java.util.Iterator v2_3 = v4_2.values().iterator();
            while (v2_3.hasNext()) {
                v0_18.put(((org.json.JSONObject) v2_3.next()));
            }
            v0_0 = v1_5.put("items", v0_18);
        }
        return v0_0;
    }

    public static String route(String p11)
    {
        try {
            if (!p11.startsWith("/")) {
                String v2_1 = new java.net.URI(p11);
                if (("https".equals(v2_1.getScheme())) && (("dokkan-eclipse.com".equals(v2_1.getHost())) && ((v2_1.getPort() == -1) && ((v2_1.getUserInfo() == null) && (("/api/file-browser".equals(v2_1.getPath())) && (v2_1.getRawQuery() != null)))))) {
                    boolean v11_11 = v2_1.getRawQuery().split("&", -1);
                    String v2_4 = v11_11.length;
                    String v6_0 = 0;
                    int v5_1 = 0;
                    while (v5_1 < v2_4) {
                        String[] v7_1 = v11_11[v5_1].split("=", 2);
                        if ((java.net.URLDecoder.decode(v7_1[0], "UTF-8").equals("path")) && ((v7_1.length == 2) && (v6_0 == null))) {
                            v6_0 = java.net.URLDecoder.decode(v7_1[1], "UTF-8");
                        }
                        v5_1++;
                    }
                    if ((v6_0 != null) && (com.personal.aihub.GameAssets.safe(v6_0))) {
                        boolean v11_14 = new StringBuilder();
                        v11_14.append(String.valueOf(v6_0));
                        v11_14.append("/forge-directory-probe.lwf");
                        boolean v11_15 = v11_14.toString();
                        StringBuilder v1_3 = new StringBuilder();
                        v1_3.append("/assets/");
                        v1_3.append(v6_0);
                        v1_3.append("/forge-directory-probe.lwf");
                        if (v11_15.equals(com.personal.aihub.GameAssets.gamePath(v1_3.toString()))) {
                            return v6_0;
                        }
                    }
                }
            } else {
                int v4_7 = new StringBuilder("https://dokkan-eclipse.com");
                v4_7.append(p11);
                p11 = v4_7.toString();
            }
        } catch (Exception) {
        }
        return 0;
    }

    private static boolean visual(String p1)
    {
        return p1.matches("(?i).*\\.(png|lwf)$");
    }

    public org.json.JSONObject resolve(String p22)
    {
        java.io.IOException v0_4 = com.personal.aihub.GameDirectory.route(p22);
        if (v0_4 != null) {
            String v3_17 = new java.util.LinkedHashMap();
            int v4_1 = com.personal.aihub.GameAssets.overlayMap(this.overlays).entrySet().iterator();
            do {
                org.json.JSONObject v6_7 = 0;
                if (!v4_1.hasNext()) {
                    if (this.root.exists()) {
                        if ((!this.root.isDirectory()) || (java.nio.file.Files.isSymbolicLink(this.root.toPath()))) {
                            throw new java.io.IOException("Invalid imported resource folder");
                        } else {
                            int v4_12 = new java.util.ArrayList();
                            java.util.TreeMap v8_3 = this.root.listFiles();
                            if (v8_3 != null) {
                                int v9_4 = v8_3.length;
                                int v10_6 = 0;
                                while (v10_6 < v9_4) {
                                    int v11_0 = v8_3[v10_6];
                                    if ((com.personal.aihub.GameAssets.safe(v11_0.getName())) && ((v11_0.isDirectory()) && (!java.nio.file.Files.isSymbolicLink(v11_0.toPath())))) {
                                        v4_12.add(v11_0);
                                        if (v4_12.size() > 4096) {
                                            throw new java.io.IOException("Too many imported resource groups for a visual preview");
                                        }
                                    }
                                    v10_6++;
                                }
                            }
                            v4_12.sort(new com.personal.aihub.GameDirectory$$ExternalSyntheticLambda0());
                            java.util.TreeMap v8_7 = new java.util.TreeMap();
                            int v4_13 = v4_12.iterator();
                            int v9_2 = 0;
                            while (v4_13.hasNext()) {
                                int v10_1 = ((java.io.File) v4_13.next());
                                int v12_0 = v10_1.getName();
                                java.nio.file.DirectoryStream v13_1 = new StringBuilder();
                                v13_1.append(v10_1.getName());
                                v13_1.append("/files");
                                java.nio.file.DirectoryStream v13_2 = v13_1.toString();
                                java.util.Iterator v14_3 = new StringBuilder();
                                v14_3.append(v10_1.getName());
                                v14_3.append("/tutorial0");
                                int v10_5 = new String[] {v12_0, v13_2, v14_3.toString()});
                                int v12_1 = v6_7;
                                while (v12_1 < 3) {
                                    java.nio.file.DirectoryStream v13_4 = v10_5[v12_1];
                                    java.util.Iterator v14_5 = new StringBuilder();
                                    v14_5.append(v13_4);
                                    v14_5.append("/");
                                    v14_5.append(v0_4);
                                    java.nio.file.DirectoryStream v13_6 = this.directory(v14_5.toString());
                                    if (v13_6 != null) {
                                        java.nio.file.DirectoryStream v13_8 = java.nio.file.Files.newDirectoryStream(v13_6.toPath());
                                        try {
                                            java.util.Iterator v14_6 = v13_8.iterator();
                                        } catch (java.io.IOException v0_11) {
                                            String v2_12 = v0_11;
                                            if (v13_8 != null) {
                                                try {
                                                    v13_8.close();
                                                } catch (java.io.IOException v0_12) {
                                                    v2_12.addSuppressed(v0_12);
                                                }
                                            }
                                            throw v2_12;
                                        }
                                        while (v14_6.hasNext()) {
                                            java.nio.file.Path v15_2 = ((java.nio.file.Path) v14_6.next());
                                            v9_2++;
                                            if (v9_2 > 10000) {
                                                throw new java.io.IOException("This visual folder exceeds the preview listing limit");
                                            } else {
                                                String v2_9 = v15_2.getFileName().toString();
                                                if (com.personal.aihub.GameDirectory.visual(v2_9)) {
                                                    org.json.JSONObject v6_10 = new StringBuilder();
                                                    v6_10.append(v0_4);
                                                    v6_10.append("/");
                                                    v6_10.append(v2_9);
                                                    org.json.JSONObject v6_11 = v6_10.toString();
                                                    long v7_6 = new StringBuilder();
                                                    v7_6.append("/assets/");
                                                    v7_6.append(v0_4);
                                                    v7_6.append("/");
                                                    v7_6.append(v2_9);
                                                    if (v6_11.equals(com.personal.aihub.GameAssets.gamePath(v7_6.toString()))) {
                                                        if (java.nio.file.Files.isSymbolicLink(v15_2)) {
                                                            throw new java.io.IOException("Imported game assets cannot use symbolic links");
                                                        } else {
                                                            org.json.JSONObject v6_14 = v15_2.toFile();
                                                            if ((v6_14.isFile()) && (!v8_7.containsKey(v2_9))) {
                                                                if (v6_14.length() > 167772160) {
                                                                    throw new java.io.IOException("Imported game asset exceeds the 160 MB preview limit");
                                                                } else {
                                                                    v8_7.put(v2_9, com.personal.aihub.GameDirectory.item(v0_4, v2_9, v6_14));
                                                                    com.personal.aihub.GameDirectory.bound(v8_7);
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                org.json.JSONObject v6 = 0;
                                            }
                                        }
                                        if (v13_8 != null) {
                                            v13_8.close();
                                        }
                                    }
                                    v12_1++;
                                    v6_7 = 0;
                                }
                            }
                            String v2_17 = this.preferred;
                            if ((v2_17 != null) && (!v2_17.isEmpty())) {
                                String v2_20 = com.personal.aihub.GameAssets.preferredPath(this.preferred);
                                if ((v2_20.substring(0, v2_20.lastIndexOf(47)).equals(v0_4)) && (com.personal.aihub.GameDirectory.visual(v2_20))) {
                                    org.json.JSONObject v6_23 = this.assets;
                                    long v7_16 = new StringBuilder("/assets/");
                                    v7_16.append(v2_20);
                                    org.json.JSONObject v6_24 = v6_23.resolve(v7_16.toString());
                                    String v2_21 = v2_20.substring((v2_20.lastIndexOf(47) + 1));
                                    v8_7.put(v2_21, com.personal.aihub.GameDirectory.item(v0_4, v2_21, v6_24));
                                    com.personal.aihub.GameDirectory.bound(v8_7);
                                }
                            }
                            String v2_0 = v3_17.keySet().iterator();
                            while (v2_0.hasNext()) {
                                String v3_8 = ((String) v2_0.next());
                                org.json.JSONObject v6_5 = this.assets;
                                long v7_1 = new StringBuilder("/assets/");
                                v7_1.append(v3_8);
                                org.json.JSONObject v6_6 = v6_5.resolve(v7_1.toString());
                                String v3_9 = v3_8.substring((v3_8.lastIndexOf(47) + 1));
                                v8_7.put(v3_9, com.personal.aihub.GameDirectory.item(v0_4, v3_9, v6_6));
                                com.personal.aihub.GameDirectory.bound(v8_7);
                            }
                            if (!v8_7.isEmpty()) {
                                String v2_3 = new org.json.JSONArray();
                                String v3_2 = v8_7.values().iterator();
                                while (v3_2.hasNext()) {
                                    v2_3.put(((org.json.JSONObject) v3_2.next()));
                                }
                                java.io.IOException v0_0;
                                String v3_5 = new org.json.JSONObject().put("path", v0_4);
                                if (!v0_4.contains("/")) {
                                    v0_0 = "";
                                } else {
                                    v0_0 = v0_4.substring(0, v0_4.lastIndexOf(47));
                                }
                                return v3_5.put("parentPath", v0_0).put("items", v2_3).put("forge_local", 1);
                            } else {
                                return 0;
                            }
                        }
                    } else {
                        if (v3_17.isEmpty()) {
                            String v3_12 = this.preferred;
                            if ((v3_12 != null) && (!v3_12.isEmpty())) {
                                String v3_15 = com.personal.aihub.GameAssets.preferredPath(this.preferred);
                                int v4_10 = new StringBuilder();
                                v4_10.append(v0_4);
                                v4_10.append("/");
                                if (v3_15.startsWith(v4_10.toString())) {
                                    throw new java.io.IOException("The selected imported asset is unavailable. Choose it again.");
                                }
                            }
                            return 0;
                        }
                    }
                } else {
                    String v5_7 = ((java.util.Map$Entry) v4_1.next());
                    java.util.TreeMap v8_1 = ((String) v5_7.getKey());
                }
            } while((v8_1.lastIndexOf(47) <= 0) || ((!v8_1.substring(0, v8_1.lastIndexOf(47)).equals(v0_4)) || (!com.personal.aihub.GameDirectory.visual(v8_1))));
            v3_17.put(v8_1, ((String) v5_7.getValue()));
        } else {
            return 0;
        }
    }
}
