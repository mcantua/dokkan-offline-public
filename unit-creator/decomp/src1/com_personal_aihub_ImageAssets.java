package com.personal.aihub;
public final class ImageAssets {
    public static final int LIMIT = 12582912;
    private final java.io.File root;

    public ImageAssets(java.io.File p1)
    {
        this.root = p1;
        return;
    }

    private static long be(byte[] p5, int p6, int p7)
    {
        long v0_0 = 0;
        int v2 = 0;
        while (v2 < p7) {
            v0_0 = ((v0_0 << 8) | ((long) com.personal.aihub.ImageAssets.u(p5, (p6 + v2))));
            v2++;
        }
        return v0_0;
    }

    private static org.json.JSONObject dimensions(long p4, long p6, String p8)
    {
        if ((p4 < 1) || ((p6 < 1) || ((p4 > 4096) || ((p6 > 4096) || ((p4 * p6) > 16000000))))) {
            throw com.personal.aihub.ImageAssets.invalid();
        } else {
            return new org.json.JSONObject().put("width", p4).put("height", p6).put("mime", p8);
        }
    }

    private java.io.File file(String p6)
    {
        this.rootValid();
        if (!com.personal.aihub.ImageAssets.safe(p6)) {
            throw com.personal.aihub.ImageAssets.invalid();
        } else {
            java.io.File v0_3 = this.root;
            java.io.IOException v6_1 = p6.split("/");
            String v1_0 = v6_1.length;
            int v2_0 = 0;
            while (v2_0 < v1_0) {
                java.io.File v3_1 = new java.io.File(v0_3, v6_1[v2_0]);
                if (java.nio.file.Files.isSymbolicLink(v3_1.toPath())) {
                    throw com.personal.aihub.ImageAssets.invalid();
                } else {
                    v2_0++;
                    v0_3 = v3_1;
                }
            }
            java.io.IOException v6_2 = v0_3.getCanonicalPath();
            String v1_2 = new StringBuilder();
            v1_2.append(String.valueOf(this.root.getCanonicalPath()));
            v1_2.append(java.io.File.separator);
            if ((!v6_2.startsWith(v1_2.toString())) || (!v0_3.isFile())) {
                throw com.personal.aihub.ImageAssets.invalid();
            } else {
                return v0_3;
            }
        }
    }

    public static org.json.JSONObject inspect(byte[] p32, boolean p33)
    {
        int v2_0 = 12;
        if ((p32.length < 12) || (p32.length > 12582912)) {
            throw com.personal.aihub.ImageAssets.invalid();
        } else {
            int v3_1 = java.util.Arrays.copyOf(p32, 8);
            long v4_0 = new byte[8];
            v4_0 = {-119, 80, 78, 71, 13, 10, 26, 10};
            long v4_8 = 12;
            int v9_1 = 0;
            if (!java.util.Arrays.equals(v3_1, v4_0)) {
                if (p33) {
                    throw new java.io.IOException("Artwork edits must be PNG images.");
                } else {
                    if ((com.personal.aihub.ImageAssets.u(p32, 0) == 255) && (com.personal.aihub.ImageAssets.u(p32, 1) == 216)) {
                        Integer v19 = Integer.valueOf(192);
                        Integer.valueOf(193);
                        Integer.valueOf(194);
                        Integer.valueOf(195);
                        Integer.valueOf(197);
                        Integer.valueOf(198);
                        Integer.valueOf(199);
                        Integer.valueOf(201);
                        Integer.valueOf(202);
                        Integer.valueOf(203);
                        Integer.valueOf(205);
                        Integer.valueOf(206);
                        int v2_15 = new java.util.HashSet(java.util.Arrays.asList(new Integer[] {v19, Integer.valueOf(207)})));
                        int v3_0 = 2;
                        while ((v3_0 + 4) <= p32.length) {
                            long v4_2 = (v3_0 + 1);
                            if (com.personal.aihub.ImageAssets.u(p32, v3_0) != 255) {
                                throw com.personal.aihub.ImageAssets.invalid();
                            }
                            while ((v4_2 < p32.length) && (com.personal.aihub.ImageAssets.u(p32, v4_2) == 255)) {
                                v4_2++;
                            }
                            if ((v4_2 + 3) > p32.length) {
                                throw com.personal.aihub.ImageAssets.invalid();
                            } else {
                                v3_0 = (v4_2 + 1);
                                int v5_0 = com.personal.aihub.ImageAssets.u(p32, v4_2);
                                if ((v5_0 == 217) || (v5_0 == 218)) {
                                    break;
                                }
                                if ((v5_0 != 1) && ((v5_0 < 208) || (v5_0 > 215))) {
                                    int v8_1 = ((int) com.personal.aihub.ImageAssets.be(p32, v3_0, 2));
                                    if (v8_1 >= 2) {
                                        v3_0 += v8_1;
                                        if (v3_0 <= p32.length) {
                                            if (v2_15.contains(Integer.valueOf(v5_0))) {
                                                if (v8_1 < 8) {
                                                    throw com.personal.aihub.ImageAssets.invalid();
                                                } else {
                                                    return com.personal.aihub.ImageAssets.dimensions(com.personal.aihub.ImageAssets.be(p32, (v4_2 + 6), 2), com.personal.aihub.ImageAssets.be(p32, (v4_2 + 4), 2), "image/jpeg");
                                                }
                                            }
                                        }
                                    }
                                    throw com.personal.aihub.ImageAssets.invalid();
                                }
                            }
                        }
                        throw com.personal.aihub.ImageAssets.invalid();
                    } else {
                        if ((!com.personal.aihub.ImageAssets.text(p32, 0, 6).equals("GIF87a")) && (!com.personal.aihub.ImageAssets.text(p32, 0, 6).equals("GIF89a"))) {
                            int v1_5 = 0;
                            long v4_6 = 8;
                        } else {
                            if (p32.length < 13) {
                                v4_6 = 8;
                                v1_5 = 0;
                            } else {
                                return com.personal.aihub.ImageAssets.dimensions(com.personal.aihub.ImageAssets.le(p32, 6, 2), com.personal.aihub.ImageAssets.le(p32, 8, 2), "image/gif");
                            }
                        }
                        if ((!com.personal.aihub.ImageAssets.text(p32, v1_5, 4).equals("RIFF")) || ((!com.personal.aihub.ImageAssets.text(p32, v4_6, 4).equals("WEBP")) || ((com.personal.aihub.ImageAssets.le(p32, 4, 4) + 8) != ((long) p32.length)))) {
                            if ((com.personal.aihub.ImageAssets.text(p32, 0, 2).equals("BM")) && (p32.length >= 26)) {
                                int v3_14 = com.personal.aihub.ImageAssets.le(p32, 14, 4);
                                if (v3_14 != 12) {
                                    if ((v3_14 >= 40) && (p32.length >= 54)) {
                                        return com.personal.aihub.ImageAssets.dimensions(((long) ((int) com.personal.aihub.ImageAssets.le(p32, 18, 4))), ((long) Math.abs(((int) com.personal.aihub.ImageAssets.le(p32, 22, 4)))), "image/bmp");
                                    }
                                } else {
                                    return com.personal.aihub.ImageAssets.dimensions(com.personal.aihub.ImageAssets.le(p32, 18, 2), com.personal.aihub.ImageAssets.le(p32, 20, 2), "image/bmp");
                                }
                            }
                            throw com.personal.aihub.ImageAssets.invalid();
                        }
                        while(true) {
                            int v1_12 = (v2_0 + 8);
                            if (v1_12 > p32.length) {
                                throw com.personal.aihub.ImageAssets.invalid();
                            } else {
                                long v4_13 = com.personal.aihub.ImageAssets.text(p32, v2_0, 4);
                                int v5_6 = com.personal.aihub.ImageAssets.le(p32, (v2_0 + 4), 4);
                                if ((((long) v1_12) + v5_6) > ((long) p32.length)) {
                                    throw com.personal.aihub.ImageAssets.invalid();
                                } else {
                                    int v5_7 = ((int) v5_6);
                                    if ((v4_13.equals("VP8X")) && (v5_7 >= 10)) {
                                        return com.personal.aihub.ImageAssets.dimensions((com.personal.aihub.ImageAssets.le(p32, (v2_0 + 12), 3) + 1), (com.personal.aihub.ImageAssets.le(p32, (v2_0 + 15), 3) + 1), "image/webp");
                                    } else {
                                        if ((v4_13.equals("VP8L")) && ((v5_7 >= 5) && (com.personal.aihub.ImageAssets.u(p32, v1_12) == 47))) {
                                            org.json.JSONObject v0_14 = com.personal.aihub.ImageAssets.le(p32, (v2_0 + 9), 4);
                                            return com.personal.aihub.ImageAssets.dimensions(((v0_14 & 16383) + 1), (((v0_14 >> 14) & 16383) + 1), "image/webp");
                                        } else {
                                            if ((v4_13.equals("VP8 ")) && ((v5_7 >= 10) && ((com.personal.aihub.ImageAssets.u(p32, (v2_0 + 11)) == 157) && ((com.personal.aihub.ImageAssets.u(p32, (v2_0 + 12)) == 1) && (com.personal.aihub.ImageAssets.u(p32, (v2_0 + 13)) == 42))))) {
                                                break;
                                            }
                                            v2_0 = (((v5_7 & 1) + v1_12) + v5_7);
                                        }
                                    }
                                }
                            }
                        }
                        return com.personal.aihub.ImageAssets.dimensions((com.personal.aihub.ImageAssets.le(p32, (v2_0 + 14), 2) & 16383), (com.personal.aihub.ImageAssets.le(p32, (v2_0 + 16), 2) & 16383), "image/webp");
                    }
                }
            } else {
                int v2_10 = new java.io.ByteArrayOutputStream();
                int v3_23 = 0;
                int v13_1 = 8;
                int v14 = 0;
                while(true) {
                    int v7_19;
                    int v15_1 = (v13_1 + 12);
                    if (v15_1 <= p32.length) {
                        java.io.ByteArrayOutputStream v16 = v2_10;
                        int v1_31 = com.personal.aihub.ImageAssets.be(p32, v13_1, 4);
                        if ((v1_31 > 12582912) || (((((long) v13_1) + v4_8) + v1_31) > ((long) p32.length))) {
                            break;
                        }
                        int v1_32 = ((int) v1_31);
                        int v2_12 = (v15_1 + v1_32);
                        long v4_31 = (v13_1 + 4);
                        int v5_10 = com.personal.aihub.ImageAssets.text(p32, v4_31, 4);
                        if ((!v5_10.matches("[A-Za-z]{2}[A-Z][A-Za-z]")) || ((p33) && ((Character.isUpperCase(v5_10.charAt(v9_1))) && (!java.util.Arrays.asList(new String[] {"IHDR", "IDAT", "IEND"})).contains(v5_10))))) {
                            throw com.personal.aihub.ImageAssets.invalid();
                        } else {
                            int v9_8 = new java.util.zip.CRC32();
                            v9_8.update(p32, v4_31, (v1_32 + 4));
                            long v4_32 = (v13_1 + 8);
                            if (v9_8.getValue() != com.personal.aihub.ImageAssets.be(p32, (v4_32 + v1_32), 4)) {
                                throw com.personal.aihub.ImageAssets.invalid();
                            } else {
                                if (v3_23 != 0) {
                                    if (v5_10.equals("IHDR")) {
                                        throw com.personal.aihub.ImageAssets.invalid();
                                    }
                                } else {
                                    if ((!v5_10.equals("IHDR")) || (v1_32 != 13)) {
                                        throw com.personal.aihub.ImageAssets.invalid();
                                    } else {
                                        v3_23 = com.personal.aihub.ImageAssets.dimensions(com.personal.aihub.ImageAssets.be(p32, v4_32, 4), com.personal.aihub.ImageAssets.be(p32, v15_1, 4), "image/png");
                                        int v7_14 = (v13_1 + 20);
                                        if ((com.personal.aihub.ImageAssets.u(p32, (v13_1 + 18)) != 0) || ((com.personal.aihub.ImageAssets.u(p32, (v13_1 + 19)) != 0) || (com.personal.aihub.ImageAssets.u(p32, v7_14) > 1))) {
                                            throw com.personal.aihub.ImageAssets.invalid();
                                        } else {
                                            int v8_10 = (v13_1 + 17);
                                            if ((p33) && (((com.personal.aihub.ImageAssets.u(p32, (v13_1 + 16)) != 8) || ((com.personal.aihub.ImageAssets.u(p32, v8_10) != 2) && (com.personal.aihub.ImageAssets.u(p32, v8_10) != 6))) || (com.personal.aihub.ImageAssets.u(p32, v7_14) != 0))) {
                                                throw com.personal.aihub.ImageAssets.invalid();
                                            } else {
                                                int v7_17;
                                                if (com.personal.aihub.ImageAssets.u(p32, v8_10) != 6) {
                                                    v7_17 = 3;
                                                } else {
                                                    v7_17 = 4;
                                                }
                                                v14 = v7_17;
                                            }
                                        }
                                    }
                                }
                                if (!v5_10.equals("IDAT")) {
                                    v7_19 = v16;
                                } else {
                                    v7_19 = v16;
                                    v7_19.write(p32, v4_32, v1_32);
                                }
                                if (!v5_10.equals("IEND")) {
                                    if ((p33) && ((v5_10.equals("acTL")) || ((v5_10.equals("fcTL")) || (v5_10.equals("fdAT"))))) {
                                        throw com.personal.aihub.ImageAssets.invalid();
                                    } else {
                                        v13_1 = v2_12;
                                        v2_10 = v7_19;
                                        v4_8 = 12;
                                        v9_1 = 0;
                                    }
                                } else {
                                    if ((v1_32 != 0) || ((v2_12 != p32.length) || (v7_19.size() == 0))) {
                                        throw com.personal.aihub.ImageAssets.invalid();
                                    } else {
                                        v9_1 = 1;
                                    }
                                }
                            }
                        }
                    } else {
                        v7_19 = v2_10;
                    }
                    if (v9_1 == 0) {
                        throw com.personal.aihub.ImageAssets.invalid();
                    } else {
                        if (p33) {
                            org.json.JSONObject v0_46 = ((v3_23.getInt("width") * v14) + 1);
                            int v1_43 = (v3_23.getInt("height") * v0_46);
                            int v2_14 = new java.util.zip.Inflater();
                            try {
                                v2_14.setInput(v7_19.toByteArray());
                                long v4_36 = new byte[65536];
                                int v5_11 = 0;
                            } catch (org.json.JSONObject v0_51) {
                                v2_14.end();
                                throw v0_51;
                            }
                            while (!v2_14.finished()) {
                                int v6_18 = v2_14.inflate(v4_36);
                                if ((v6_18 == 0) || (v6_18 > (v1_43 - v5_11))) {
                                    throw com.personal.aihub.ImageAssets.invalid();
                                } else {
                                    int v7_21 = 0;
                                    while (v7_21 < v6_18) {
                                        if (((v5_11 + v7_21) % v0_46) == 0) {
                                            if (com.personal.aihub.ImageAssets.u(v4_36, v7_21) > 4) {
                                                throw com.personal.aihub.ImageAssets.invalid();
                                            } else {
                                            }
                                        }
                                        v7_21++;
                                    }
                                    v5_11 += v6_18;
                                }
                            }
                            if ((v5_11 != v1_43) || (v2_14.getRemaining() != 0)) {
                                throw com.personal.aihub.ImageAssets.invalid();
                            } else {
                                v2_14.end();
                            }
                        }
                        return v3_23;
                    }
                }
                throw com.personal.aihub.ImageAssets.invalid();
            }
        }
    }

    private static java.io.IOException invalid()
    {
        return new java.io.IOException("Choose a complete supported image (up to 12 MB,4096px per side).");
    }

    private static long le(byte[] p4, int p5, int p6)
    {
        int v6_1 = (p6 - 1);
        long v0_0 = 0;
        while (v6_1 >= 0) {
            v0_0 = ((v0_0 << 8) | ((long) com.personal.aihub.ImageAssets.u(p4, (p5 + v6_1))));
            v6_1--;
        }
        return v0_0;
    }

    private void rootValid()
    {
        if ((!this.root.isDirectory()) || (java.nio.file.Files.isSymbolicLink(this.root.toPath()))) {
            throw com.personal.aihub.ImageAssets.invalid();
        } else {
            return;
        }
    }

    private static boolean safe(String p8)
    {
        if ((p8 == 0) || ((p8.isEmpty()) || ((p8.length() > 500) || (!p8.matches("(?i).*\\.(png|jpe?g|webp|gif|bmp|lwf|json)$"))))) {
            return 0;
        } else {
            int v1_1 = p8.toCharArray();
            int v3_0 = 0;
            while (v3_0 < v1_1.length) {
                java.util.List v4_6 = v1_1[v3_0];
                if ((v4_6 != 92) && ((v4_6 != 58) && ((v4_6 != 37) && ((v4_6 >= 32) && (v4_6 != 127))))) {
                    v3_0++;
                } else {
                    return 0;
                }
            }
            int v8_1 = p8.split("/", -1);
            int v2_2 = 0;
            while (v2_2 < v8_1.length) {
                int v3_1 = v8_1[v2_2];
                if ((!v3_1.isEmpty()) && ((!v3_1.startsWith(".")) && (!java.util.Arrays.asList(new String[] {"_databases", "projects", "patches", "exports"})).contains(v3_1.toLowerCase(java.util.Locale.ROOT))))) {
                    v2_2++;
                } else {
                    return 0;
                }
            }
            return 1;
        }
    }

    private static String text(byte[] p2, int p3, int p4)
    {
        return new String(p2, p3, p4, java.nio.charset.StandardCharsets.US_ASCII);
    }

    private static int u(byte[] p0, int p1)
    {
        return (p0[p1] & 255);
    }

    public org.json.JSONObject read(org.json.JSONObject p11)
    {
        int v0_5;
        int v0_4 = p11.opt("maxBytes");
        if (v0_4 != 0) {
            if (!(v0_4 instanceof Number)) {
                throw com.personal.aihub.ImageAssets.invalid();
            } else {
                int v0_1 = ((Number) v0_4);
                if (v0_1.doubleValue() != ((double) v0_1.intValue())) {
                    throw com.personal.aihub.ImageAssets.invalid();
                } else {
                    v0_5 = v0_1.intValue();
                }
            }
        } else {
            v0_5 = 12582912;
        }
        if ((v0_5 < 1) || (v0_5 > 12582912)) {
            throw com.personal.aihub.ImageAssets.invalid();
        } else {
            java.io.IOException v11_8 = p11.getString("key");
            String v4_3 = this.file(v11_8);
            if (v4_3.length() > ((long) v0_5)) {
                throw com.personal.aihub.ImageAssets.invalid();
            } else {
                int v5_3 = new java.io.ByteArrayOutputStream();
                java.io.FileInputStream v6_1 = new java.io.FileInputStream(v4_3);
                try {
                    String v4_5 = new byte[65536];
                } catch (java.io.IOException v11_5) {
                    try {
                        v6_1.close();
                    } catch (int v0_3) {
                        v11_5.addSuppressed(v0_3);
                    }
                    throw v11_5;
                }
                while(true) {
                    int v7_1 = v6_1.read(v4_5);
                    if (v7_1 == -1) {
                        break;
                    }
                    if (v7_1 > (v0_5 - v5_3.size())) {
                        throw com.personal.aihub.ImageAssets.invalid();
                    } else {
                        v5_3.write(v4_5, 0, v7_1);
                    }
                }
                org.json.JSONObject v1_0;
                v6_1.close();
                int v0_6 = v5_3.toByteArray();
                if (!v11_8.toLowerCase(java.util.Locale.ROOT).endsWith(".json")) {
                    if (v11_8.toLowerCase(java.util.Locale.ROOT).endsWith(".lwf")) {
                        if ((v0_6.length < 16) || ((v0_6.length > 12582912) || ((v0_6[0] != 76) || ((v0_6[1] != 87) || ((v0_6[2] != 70) || (v0_6[3] != 0)))))) {
                            throw com.personal.aihub.ImageAssets.invalid();
                        } else {
                            v1_0 = new org.json.JSONObject().put("width", 0).put("height", 0).put("mime", "application/octet-stream");
                        }
                    } else {
                        v1_0 = com.personal.aihub.ImageAssets.inspect(v0_6, 0);
                    }
                } else {
                    v1_0 = com.personal.aihub.DecorationStorage.inspect(v0_6);
                }
                return v1_0.put("key", v11_8).put("base64", java.util.Base64.getEncoder().encodeToString(v0_6)).put("bytes", v0_6.length);
            }
        }
    }

    public org.json.JSONObject store(org.json.JSONObject p12)
    {
        int v2_3 = p12.opt("data");
        if (!(v2_3 instanceof String)) {
            throw com.personal.aihub.ImageAssets.invalid();
        } else {
            int v2_0 = ((String) v2_3);
            if ((v2_0.length() > 16777216) || (((v2_0.length() % 4) != 0) || (!v2_0.matches("[A-Za-z0-9+/]*={0,2}")))) {
                throw com.personal.aihub.ImageAssets.invalid();
            } else {
                int v3_7 = java.util.Base64.getDecoder().decode(v2_0);
                if (!java.util.Base64.getEncoder().encodeToString(v3_7).equals(v2_0)) {
                    throw com.personal.aihub.ImageAssets.invalid();
                } else {
                    org.json.JSONObject v4_5 = com.personal.aihub.ImageAssets.inspect(v3_7, 1);
                    this.rootValid();
                    String v5_4 = new StringBuilder("generated-");
                    v5_4.append(java.util.UUID.randomUUID());
                    String v5_5 = v5_4.toString();
                    String v6_3 = new StringBuilder();
                    v6_3.append(String.valueOf(v5_5));
                    v6_3.append("/image.png");
                    String v6_4 = v6_3.toString();
                    java.io.File v7_3 = new java.io.File(this.root, v5_5);
                    if (!v7_3.mkdir()) {
                        throw com.personal.aihub.ImageAssets.invalid();
                    } else {
                        try {
                            String v5_9 = new java.io.File(v7_3, "image.png").toPath();
                            int v8_3 = new java.nio.file.OpenOption[2];
                            v8_3[0] = java.nio.file.StandardOpenOption.CREATE_NEW;
                            v8_3[1] = java.nio.file.StandardOpenOption.WRITE;
                            String v5_10 = java.nio.file.Files.newOutputStream(v5_9, v8_3);
                            try {
                                v5_10.write(v3_7);
                            } catch (org.json.JSONObject v12_10) {
                                if (v5_10 != null) {
                                    try {
                                        v5_10.close();
                                    } catch (Throwable v0_5) {
                                        v12_10.addSuppressed(v0_5);
                                    }
                                }
                                throw v12_10;
                            }
                            if (v5_10 != null) {
                                v5_10.close();
                            }
                            org.json.JSONObject v12_1 = p12.optString("name", "Custom artwork").replaceAll("[\\x00-\\x1f\\x7f]", "");
                            if (v12_1.length() > 160) {
                                v12_1 = v12_1.substring(0, 160);
                            }
                            return v4_5.put("key", v6_4).put("path", "image.png").put("name", v12_1).put("size", v4_5.put("key", v6_4).put("path", "image.png").length).put("image", 1);
                        } catch (org.json.JSONObject v12_2) {
                            new java.io.File(v7_3, "image.png").delete();
                            v7_3.delete();
                            throw v12_2;
                        }
                    }
                }
            }
        }
    }
}
