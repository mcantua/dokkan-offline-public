package com.personal.aihub;
public final class DecorationStorage {
    static final int LIMIT = 131072;

    public DecorationStorage()
    {
        return;
    }

    public static org.json.JSONObject inspect(byte[] p9)
    {
        if ((p9.length == 0) || (p9.length > 131072)) {
            throw com.personal.aihub.DecorationStorage.invalid();
        } else {
            java.io.IOException v9_13 = java.nio.charset.StandardCharsets.UTF_8.newDecoder().onMalformedInput(java.nio.charset.CodingErrorAction.REPORT).onUnmappableCharacter(java.nio.charset.CodingErrorAction.REPORT).decode(java.nio.ByteBuffer.wrap(p9)).toString().trim();
            int v1_6 = 0;
            boolean v2_4 = 0;
            String v3_4 = 0;
            boolean v4_8 = 0;
            while (v1_6 < v9_13.length()) {
                int v5_0 = v9_13.charAt(v1_6);
                if (!v2_4) {
                    if (v5_0 != 34) {
                        if ((v5_0 != 123) && (v5_0 != 91)) {
                            if ((v5_0 == 125) || (v5_0 == 93)) {
                                v3_4--;
                                if (v3_4 < null) {
                                    throw com.personal.aihub.DecorationStorage.invalid();
                                }
                            }
                        } else {
                            v3_4++;
                            if (v3_4 > 32) {
                                throw com.personal.aihub.DecorationStorage.invalid();
                            }
                        }
                    } else {
                        v2_4 = 1;
                    }
                } else {
                    if (!v4_8) {
                        if (v5_0 != 92) {
                            if (v5_0 == 34) {
                                v2_4 = 0;
                            }
                        } else {
                            v4_8 = 1;
                        }
                    } else {
                        v4_8 = 0;
                    }
                }
                v1_6++;
            }
            if ((v2_4) || ((v3_4 != null) || ((!v9_13.startsWith("{")) || (!v9_13.endsWith("}"))))) {
                throw com.personal.aihub.DecorationStorage.invalid();
            } else {
                int v1_13 = new org.json.JSONTokener(v9_13);
                java.io.IOException v9_15 = v1_13.nextValue();
                if ((!(v9_15 instanceof org.json.JSONObject)) || (v1_13.nextClean() != 0)) {
                    throw com.personal.aihub.DecorationStorage.invalid();
                } else {
                    java.io.IOException v9_17 = ((org.json.JSONObject) v9_15);
                    int v1_16 = v9_17.opt("card_id");
                    if ((v1_16 instanceof Number)) {
                        int v1_17 = ((Number) v1_16);
                        if ((v1_17.doubleValue() == ((double) v1_17.longValue())) && ((v1_17.longValue() >= 1) && ((v1_17.longValue() <= 2147483647) && (com.personal.aihub.DecorationStorage.safe(v9_17.getString("shader_file")))))) {
                            java.io.IOException v9_20 = v9_17.getJSONArray("parameters");
                            if (v9_20.length() > 128) {
                                throw com.personal.aihub.DecorationStorage.invalid();
                            } else {
                                int v1_0 = 0;
                                while (v1_0 < v9_20.length()) {
                                    boolean v2_1 = v9_20.getJSONObject(v1_0);
                                    if ((!(v2_1.opt("type") instanceof String)) || (!(v2_1.opt("name") instanceof String))) {
                                        throw com.personal.aihub.DecorationStorage.invalid();
                                    } else {
                                        if (("sampler2D".equals(v2_1.getString("type"))) && ((!(v2_1.opt("value") instanceof String)) || (!com.personal.aihub.DecorationStorage.safe(v2_1.getString("value"))))) {
                                            throw com.personal.aihub.DecorationStorage.invalid();
                                        } else {
                                            v1_0++;
                                        }
                                    }
                                }
                                return new org.json.JSONObject().put("width", 0).put("height", 0).put("mime", "application/json");
                            }
                        }
                    }
                    throw com.personal.aihub.DecorationStorage.invalid();
                }
            }
        }
    }

    static java.io.IOException invalid()
    {
        return new java.io.IOException("The card decoration metadata is invalid. Import its original artwork again.");
    }

    static boolean safe(String p5)
    {
        if ((!p5.isEmpty()) && ((p5.length() <= 500) && ((!p5.startsWith("/")) && (!p5.matches(".*[\\\\:\\x00-\\x1f\\x7f%].*"))))) {
            int v5_1 = p5.split("/", -1);
            int v2_4 = 0;
            while (v2_4 < v5_1.length) {
                boolean v3_0 = v5_1[v2_4];
                if ((!v3_0.isEmpty()) && (!v3_0.startsWith("."))) {
                    v2_4++;
                } else {
                    return 0;
                }
            }
            return 1;
        } else {
            return 0;
        }
    }

    public static org.json.JSONObject store(java.io.File p8, org.json.JSONObject p9)
    {
        Exception v9_2 = p9.opt("text");
        if ((v9_2 instanceof String)) {
            Exception v9_3 = ((String) v9_2);
            if (v9_3.length() <= 131072) {
                Exception v9_1 = v9_3.getBytes(java.nio.charset.StandardCharsets.UTF_8);
                String v0_2 = com.personal.aihub.DecorationStorage.inspect(v9_1);
                if ((java.nio.file.Files.isSymbolicLink(p8.toPath())) || (!p8.isDirectory())) {
                    throw com.personal.aihub.DecorationStorage.invalid();
                } else {
                    String v2_1 = new StringBuilder("generated-decoration-");
                    v2_1.append(java.util.UUID.randomUUID());
                    java.io.File v1_4 = new java.io.File(p8, v2_1.toString());
                    if (!v1_4.mkdir()) {
                        throw com.personal.aihub.DecorationStorage.invalid();
                    } else {
                        try {
                            String v3_2 = new java.io.File(v1_4, "decoration.json").toPath();
                            String v4_1 = new java.nio.file.OpenOption[2];
                            v4_1[0] = java.nio.file.StandardOpenOption.CREATE_NEW;
                            v4_1[1] = java.nio.file.StandardOpenOption.WRITE;
                            java.nio.file.Files.write(v3_2, v9_1, v4_1);
                            String v4_3 = new StringBuilder();
                            v4_3.append(v1_4.getName());
                            v4_3.append("/decoration.json");
                            org.json.JSONObject v8_7 = v0_2.put("key", v4_3.toString()).put("path", "decoration.json").put("name", "Custom card decoration").put("size", v9_1.length).put("image", 0);
                            return v8_7;
                        } catch (Exception v9_6) {
                            v8_7.delete();
                            v1_4.delete();
                            throw v9_6;
                        }
                    }
                }
            }
        }
        throw com.personal.aihub.DecorationStorage.invalid();
    }
}
