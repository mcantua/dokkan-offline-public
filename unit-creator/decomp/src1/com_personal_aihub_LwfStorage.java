package com.personal.aihub;
public final class LwfStorage {
    static final int LIMIT = 12582912;

    public LwfStorage()
    {
        return;
    }

    public static org.json.JSONObject inspect(byte[] p18)
    {
        String v2_2 = 324;
        if ((p18.length < 324) || ((p18.length > 12582912) || ((p18[0] != 76) || ((p18[1] != 87) || ((p18[2] != 70) || (p18[3] != 0)))))) {
            throw com.personal.aihub.LwfStorage.invalid();
        } else {
            int v3_8 = ((((p18[4] & 255) << 16) | ((p18[5] & 255) << 8)) | (p18[6] & 255));
            if (v3_8 == 1315345) {
                v2_2 = 332;
            }
            if (((v3_8 == 1183760) || ((v3_8 == 1249809) || (v3_8 == 1315345))) && ((p18.length >= v2_2) && ((4 & p18[7]) == 0))) {
                String v1_14 = (v2_2 - 4);
                if (com.personal.aihub.LwfStorage.word(p18, v1_14) == ((long) p18.length)) {
                    long v7_3 = com.personal.aihub.LwfStorage.word(p18, 8);
                    long v9_1 = com.personal.aihub.LwfStorage.word(p18, 12);
                    int v3_16 = com.personal.aihub.LwfStorage.word(p18, 16);
                    long v11_8 = ((long) v2_2);
                    if ((v7_3 < 1) || ((v9_1 < 1) || ((v7_3 > 16384) || ((v9_1 > 16384) || ((v3_16 < 1) || (v3_16 > 240)))))) {
                        throw com.personal.aihub.LwfStorage.invalid();
                    } else {
                        int v3_2 = 32;
                        while (v3_2 < v1_14) {
                            long v4_0 = com.personal.aihub.LwfStorage.word(p18, v3_2);
                            long v13_1 = com.personal.aihub.LwfStorage.word(p18, (v3_2 + 4));
                            if ((v4_0 != 0) || (v13_1 != 0)) {
                                if ((v4_0 < v11_8) || ((v4_0 > ((long) p18.length)) || (v13_1 > (((long) p18.length) - v4_0)))) {
                                    throw com.personal.aihub.LwfStorage.invalid();
                                } else {
                                    v11_8 = v4_0;
                                }
                            }
                            v3_2 += 8;
                        }
                        if ((com.personal.aihub.LwfStorage.word(p18, 20) >= com.personal.aihub.LwfStorage.word(p18, (v2_2 - 24))) || (com.personal.aihub.LwfStorage.word(p18, 24) >= com.personal.aihub.LwfStorage.word(p18, (v2_2 - 8)))) {
                            throw com.personal.aihub.LwfStorage.invalid();
                        } else {
                            return new org.json.JSONObject().put("mime", "application/octet-stream").put("width", v7_3).put("height", v9_1);
                        }
                    }
                }
            }
            throw com.personal.aihub.LwfStorage.invalid();
        }
    }

    private static java.io.IOException invalid()
    {
        return new java.io.IOException("Choose a complete, uncompressed supported LWF animation up to 12 MB.");
    }

    public static org.json.JSONObject store(java.io.File p11, org.json.JSONObject p12)
    {
        org.json.JSONObject v3_5 = p12.opt("data");
        if (!(v3_5 instanceof String)) {
            throw com.personal.aihub.LwfStorage.invalid();
        } else {
            org.json.JSONObject v3_0 = ((String) v3_5);
            if ((v3_0.length() > 16777216) || (((v3_0.length() % 4) != 0) || (!v3_0.matches("[A-Za-z0-9+/]*={0,2}")))) {
                throw com.personal.aihub.LwfStorage.invalid();
            } else {
                try {
                    byte[] v4_6 = java.util.Base64.getDecoder().decode(v3_0);
                } catch (IllegalArgumentException) {
                    throw com.personal.aihub.LwfStorage.invalid();
                }
                if (!java.util.Base64.getEncoder().encodeToString(v4_6).equals(v3_0)) {
                    throw com.personal.aihub.LwfStorage.invalid();
                } else {
                    org.json.JSONObject v3_4 = com.personal.aihub.LwfStorage.inspect(v4_6);
                    if ((java.nio.file.Files.isSymbolicLink(p11.toPath())) || (!p11.isDirectory())) {
                        throw com.personal.aihub.LwfStorage.invalid();
                    } else {
                        String v5_8 = new StringBuilder("generated-lwf-");
                        v5_8.append(java.util.UUID.randomUUID());
                        java.io.OutputStream v2_2 = v5_8.toString();
                        String v5_10 = new StringBuilder();
                        v5_10.append(String.valueOf(v2_2));
                        v5_10.append("/animation.lwf");
                        String v5_11 = v5_10.toString();
                        java.io.File v6_3 = new java.io.File(p11, v2_2);
                        if (!v6_3.mkdir()) {
                            throw com.personal.aihub.LwfStorage.invalid();
                        } else {
                            org.json.JSONObject v11_9 = new java.io.File(v6_3, "animation.lwf");
                            try {
                                java.io.OutputStream v2_3 = v11_9.toPath();
                                String v7_3 = new java.nio.file.OpenOption[2];
                                v7_3[0] = java.nio.file.StandardOpenOption.CREATE_NEW;
                                v7_3[1] = java.nio.file.StandardOpenOption.WRITE;
                                java.io.OutputStream v2_4 = java.nio.file.Files.newOutputStream(v2_3, v7_3);
                                try {
                                    v2_4.write(v4_6);
                                } catch (org.json.JSONObject v12_2) {
                                    if (v2_4 != null) {
                                        v2_4.close();
                                    }
                                    throw v12_2;
                                }
                                if (v2_4 != null) {
                                    v2_4.close();
                                }
                                org.json.JSONObject v12_1 = p12.optString("name", "Custom character animation").replaceAll("[\\x00-\\x1f\\x7f]", "");
                                if (v12_1.length() > 160) {
                                    v12_1 = v12_1.substring(0, 160);
                                }
                                return v3_4.put("key", v5_11).put("path", "animation.lwf").put("name", v12_1).put("size", v3_4.put("key", v5_11).put("path", "animation.lwf").length).put("image", 0);
                            } catch (org.json.JSONObject v12_3) {
                                try {
                                    throw v12_3;
                                } catch (org.json.JSONObject v12_4) {
                                    v11_9.delete();
                                    v6_3.delete();
                                    throw v12_4;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private static long word(byte[] p7, int p8)
    {
        return (((((long) p7[(p8 + 2)]) & 255) << 16) | ((((((long) p7[(p8 + 3)]) & 255) << 24) | (((long) p7[p8]) & 255)) | ((((long) p7[(p8 + 1)]) & 255) << 8)));
    }
}
