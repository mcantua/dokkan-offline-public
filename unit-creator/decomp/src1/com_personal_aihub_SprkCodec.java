package com.personal.aihub;
public final class SprkCodec {
    private static final int LIBRARY_MAX = 16777216;
    public static final String LIBRARY_SHA256 = "9d3f2749e391d990496b632b6adc135492f71e0baec7125d7b613a56e771dca0";
    public static final long MAX_ARCHIVE = 536870912;
    public static final int MAX_ENTRIES = 10000;
    public static final long MAX_ENTRY = 536870912;
    public static final int MAX_METADATA = 1048576;
    public static final long MAX_TOTAL = 1073741824;
    private static final int SEED_LENGTH = 16;
    private static final int SEED_OFFSET = 648423;

    private SprkCodec()
    {
        return;
    }

    private static byte[] bounded(java.io.InputStream p4, int p5)
    {
        java.io.ByteArrayOutputStream v0_1 = new java.io.ByteArrayOutputStream();
        byte[] v1_1 = new byte[65536];
        while(true) {
            int v2 = p4.read(v1_1);
            if (v2 == -1) {
                break;
            }
            if ((v0_1.size() + v2) > p5) {
                throw new java.io.IOException("This Sparking resource exceeds its size limit.");
            } else {
                v0_1.write(v1_1, 0, v2);
            }
        }
        return v0_1.toByteArray();
    }

    private static java.util.List central(java.io.File p28)
    {
        if ((!p28.isFile()) || (p28.length() > 536870912)) {
            throw new java.io.IOException("Invalid or oversized Sparking ZIP.");
        } else {
            Throwable v1_1 = new java.io.RandomAccessFile(p28, "r");
            try {
                java.io.IOException v0_12 = ((int) Math.min(65557, v1_1.length()));
            } catch (java.io.IOException v0_29) {
                String v2_20 = v0_29;
                try {
                    v1_1.close();
                } catch (java.io.IOException v0_30) {
                    v2_20.addSuppressed(v0_30);
                }
                throw v2_20;
            }
            if (v0_12 < 22) {
                throw new java.io.IOException("The decrypted Sparking file is not a complete ZIP.");
            } else {
                int v4_19 = new byte[v0_12];
                java.util.ArrayList v7_11 = ((long) v0_12);
                v1_1.seek((v1_1.length() - v7_11));
                v1_1.readFully(v4_19);
                long v5_13 = (v0_12 - 22);
                while (v5_13 >= 0) {
                    if ((com.personal.aihub.SprkCodec.u32(v4_19, v5_13) != 101010256) || (((v5_13 + 22) + com.personal.aihub.SprkCodec.u16(v4_19, (v5_13 + 20))) != v0_12)) {
                        v5_13--;
                    } else {
                    }
                    if ((v5_13 >= 0) && ((com.personal.aihub.SprkCodec.u16(v4_19, (v5_13 + 4)) == 0) && (com.personal.aihub.SprkCodec.u16(v4_19, (v5_13 + 6)) == 0))) {
                        int v6_12 = (v5_13 + 10);
                        if (com.personal.aihub.SprkCodec.u16(v4_19, (v5_13 + 8)) == com.personal.aihub.SprkCodec.u16(v4_19, v6_12)) {
                            java.io.IOException v0_41 = com.personal.aihub.SprkCodec.u16(v4_19, v6_12);
                            java.util.HashMap v9_6 = com.personal.aihub.SprkCodec.u32(v4_19, (v5_13 + 12));
                            long v11_1 = com.personal.aihub.SprkCodec.u32(v4_19, (v5_13 + 16));
                            int v13_3 = v1_1.length();
                            if ((v0_41 >= 1) && ((v0_41 <= 10000) && (v9_6 <= 16777216))) {
                                long v5_14 = (v11_1 + v9_6);
                                if ((v5_14 == ((v13_3 - v7_11) + ((long) v5_13))) && ((v11_1 != 4294967295) && (v9_6 != 4294967295))) {
                                    v1_1.seek(v11_1);
                                    java.util.ArrayList v7_1 = new java.util.ArrayList();
                                    int v8_1 = new java.util.HashSet();
                                    java.util.HashMap v9_1 = new java.util.HashMap();
                                    int v10_0 = 0;
                                    int v15_0 = 0;
                                    long v16 = 0;
                                    while (v15_0 < v0_41) {
                                        String v2_6 = new byte[46];
                                        v1_1.readFully(v2_6);
                                        if (com.personal.aihub.SprkCodec.u32(v2_6, v10_0) != 33639248) {
                                            throw new java.io.IOException("Corrupt Sparking ZIP directory.");
                                        } else {
                                            long v3_8 = new com.personal.aihub.SprkCodec$Member(0);
                                            v3_8.flags = com.personal.aihub.SprkCodec.u16(v2_6, 8);
                                            v3_8.method = com.personal.aihub.SprkCodec.u16(v2_6, 10);
                                            long v23_1 = v5_14;
                                            v3_8.crc = com.personal.aihub.SprkCodec.u32(v2_6, 16);
                                            v3_8.compressed = com.personal.aihub.SprkCodec.u32(v2_6, 20);
                                            v3_8.size = com.personal.aihub.SprkCodec.u32(v2_6, 24);
                                            v3_8.local = com.personal.aihub.SprkCodec.u32(v2_6, 42);
                                            int v4_18 = com.personal.aihub.SprkCodec.u16(v2_6, 28);
                                            long v5_10 = com.personal.aihub.SprkCodec.u16(v2_6, 30);
                                            int v13_2 = com.personal.aihub.SprkCodec.u16(v2_6, 32);
                                            java.util.ArrayList v27 = v7_1;
                                            int v6_8 = (((int) (com.personal.aihub.SprkCodec.u32(v2_6, 38) >> 16)) & 61440);
                                            if (((v3_8.flags & 65) == 0) && ((v3_8.method == 0) || (v3_8.method == 8))) {
                                                java.util.ArrayList v7_10 = v15_0;
                                                if ((v3_8.size <= 536870912) && ((v3_8.compressed <= 536870912) && ((v3_8.local < v11_1) && ((v4_18 >= 1) && ((v4_18 <= 2000) && ((com.personal.aihub.SprkCodec.u16(v2_6, 34) == 0) && ((v6_8 == 0) || ((v6_8 == 32768) || (v6_8 == 16384))))))))) {
                                                    int v4_25;
                                                    int v4_20 = new byte[v4_18];
                                                    v1_1.readFully(v4_20);
                                                    v3_8.name = com.personal.aihub.SprkCodec.name(v4_20, v3_8.flags);
                                                    v3_8.directory = v3_8.name.endsWith("/");
                                                    if (!v3_8.directory) {
                                                        v4_25 = v3_8.name;
                                                    } else {
                                                        v4_25 = v3_8.name.substring(0, (v3_8.name.length() - 1));
                                                    }
                                                    com.personal.aihub.SprkCodec.safe(v4_25);
                                                    if (!v8_1.add(v4_25)) {
                                                        throw new java.io.IOException("The Sparking ZIP contains duplicate file paths.");
                                                    } else {
                                                        v9_1.put(v4_25, Boolean.valueOf(v3_8.directory));
                                                        if (!v3_8.directory) {
                                                            if (v6_8 == 16384) {
                                                                if (!v3_8.directory) {
                                                                    throw new java.io.IOException("Invalid Sparking ZIP directory entry.");
                                                                } else {
                                                                }
                                                            }
                                                            v16 += v3_8.size;
                                                            if (v16 > 1073741824) {
                                                                throw new java.io.IOException("Expanded Sparking patch exceeds1GiB.");
                                                            } else {
                                                                long v14_12 = ((v1_1.getFilePointer() + ((long) v5_10)) + ((long) v13_2));
                                                                if (v14_12 > v23_1) {
                                                                    throw new java.io.IOException("Truncated Sparking ZIP metadata.");
                                                                } else {
                                                                    v1_1.seek(v14_12);
                                                                    String v2_19 = v27;
                                                                    v2_19.add(v3_8);
                                                                    v15_0 = (v7_10 + 1);
                                                                    v7_1 = v2_19;
                                                                    v5_14 = v23_1;
                                                                    v10_0 = 0;
                                                                }
                                                            }
                                                            throw new java.io.IOException("This Sparking ZIP exceeds supported limits or needs unsupported ZIP64 handling.");
                                                        } else {
                                                            if (v3_8.size == 0) {
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            throw new java.io.IOException("This Sparking ZIP contains an encrypted, linked, special or unsupported entry.");
                                        }
                                    }
                                    String v2_0 = v7_1;
                                    if (v1_1.getFilePointer() != v5_14) {
                                        throw new java.io.IOException("Sparking ZIP directory size does not match.");
                                    } else {
                                        java.io.IOException v0_6 = v2_0.iterator();
                                        while (v0_6.hasNext()) {
                                            int v4_2;
                                            long v3_3 = ((com.personal.aihub.SprkCodec$Member) v0_6.next());
                                            if (!v3_3.directory) {
                                                v4_2 = v3_3.name;
                                            } else {
                                                v4_2 = v3_3.name.substring(0, (v3_3.name.length() - 1));
                                            }
                                            int v8_3 = v4_2.indexOf(47);
                                            while (v8_3 >= 0) {
                                                if (Boolean.FALSE.equals(v9_1.get(v4_2.substring(0, v8_3)))) {
                                                    throw new java.io.IOException("A Sparking file conflicts with a folder.");
                                                } else {
                                                    v8_3 = v4_2.indexOf(47, (v8_3 + 1));
                                                }
                                            }
                                            v1_1.seek(v3_3.local);
                                            int v4_6 = new byte[30];
                                            v1_1.readFully(v4_6);
                                            if ((com.personal.aihub.SprkCodec.u32(v4_6, 0) != 67324752) || ((com.personal.aihub.SprkCodec.u16(v4_6, 8) != v3_3.method) || (com.personal.aihub.SprkCodec.u16(v4_6, 6) != v3_3.flags))) {
                                                throw new java.io.IOException("Sparking ZIP local and directory headers do not match.");
                                            } else {
                                                int v8_8 = com.personal.aihub.SprkCodec.u16(v4_6, 26);
                                                int v4_8 = com.personal.aihub.SprkCodec.u16(v4_6, 28);
                                                int v10_3 = new byte[v8_8];
                                                v1_1.readFully(v10_3);
                                                if ((!com.personal.aihub.SprkCodec.name(v10_3, v3_3.flags).equals(v3_3.name)) || (((((v3_3.local + 30) + ((long) v8_8)) + ((long) v4_8)) + v3_3.compressed) > v11_1)) {
                                                    throw new java.io.IOException("Invalid Sparking ZIP file bounds.");
                                                } else {
                                                }
                                            }
                                        }
                                        v1_1.close();
                                        return v2_0;
                                    }
                                }
                            }
                        }
                    }
                    throw new java.io.IOException("Unsupported or incomplete Sparking ZIP directory.");
                }
                v5_13 = -1;
            }
        }
    }

    private static long creatorId(org.json.JSONObject p5)
    {
        String v0_0 = com.personal.aihub.SprkCodec.id(p5);
        long v2 = 0;
        if (v0_0 <= 0) {
            org.json.JSONObject v5_1 = p5.optJSONObject("creator");
            if (v5_1 != null) {
                v2 = com.personal.aihub.SprkCodec.id(v5_1);
            }
            return v2;
        } else {
            return v0_0;
        }
    }

    private static String creatorName(org.json.JSONObject p8)
    {
        int v4 = 0;
        int v5 = 0;
        while (v5 < 3) {
            String v6_1 = p8.opt(new String[] {"creator_name", "creatorName", "creator"})[v5]);
            if ((v6_1 instanceof String)) {
                String v6_2 = ((String) v6_1);
                if (!v6_2.trim().isEmpty()) {
                    return v6_2.trim();
                }
            }
            v5++;
        }
        String v8_1 = p8.optJSONObject("creator");
        if (v8_1 != null) {
            while (v4 < 3) {
                String v1_2 = v8_1.opt(new String[] {"name", "creator_name", "creatorName"})[v4]);
                if ((v1_2 instanceof String)) {
                    String v1_3 = ((String) v1_2);
                    if (!v1_3.trim().isEmpty()) {
                        return v1_3.trim();
                    }
                }
                v4++;
            }
        }
        return "";
    }

    public static String databaseKeyFromApk(java.io.File p4)
    {
        java.io.IOException v4_1 = com.personal.aihub.SprkCodec.supportedLibrary(p4);
        if ((v4_1.length <= 487156) || (v4_1[487156] != null)) {
            throw new java.io.IOException("The supported Sparking database format key is unavailable.");
        } else {
            String v0_0 = 0;
            while (v0_0 < 64) {
                int v1_3 = (v4_1[(487092 + v0_0)] & 255);
                if (((v1_3 < 48) || (v1_3 > 57)) && (((v1_3 < 97) || (v1_3 > 102)) && ((v1_3 < 65) || (v1_3 > 70)))) {
                    throw new java.io.IOException("The supported Sparking database format key is invalid.");
                } else {
                    v0_0++;
                }
            }
            return new String(v4_1, 487092, 64, java.nio.charset.StandardCharsets.US_ASCII);
        }
    }

    public static void decode(java.io.File p11, java.io.File p12, byte[] p13)
    {
        if ((p13 == null) || (p13.length != 32)) {
            throw new java.io.IOException("Import the supported Sparking APK before opening an SPRK patch.");
        } else {
            java.io.IOException v11_15 = p11.getCanonicalFile();
            java.io.BufferedInputStream v0_3 = p12.getAbsoluteFile().getParentFile().getCanonicalFile();
            String v1_2 = new java.io.File(v0_3, p12.getName());
            if ((!v0_3.isDirectory()) || ((v11_15.equals(v1_2)) || ((v1_2.exists()) && (!v1_2.getCanonicalFile().equals(v1_2))))) {
                throw new java.io.IOException("Choose a separate, safe staging file for this Sparking patch.");
            } else {
                if ((!v11_15.isFile()) || ((v11_15.length() <= 21) || ((v11_15.length() - 21) > 536870912))) {
                    throw new java.io.IOException("This Sparking patch is empty or exceeds the512MiB conversion limit.");
                } else {
                    long v2_6 = new StringBuilder("sprk-decode-");
                    v2_6.append(java.util.UUID.randomUUID());
                    v2_6.append(".zip.tmp");
                    java.io.File v12_14 = new java.io.File(v0_3, v2_6.toString());
                    try {
                        java.io.BufferedInputStream v0_5 = new java.io.BufferedInputStream(new java.io.FileInputStream(v11_15));
                        try {
                            java.io.IOException v11_14 = new java.io.FileOutputStream(v12_14);
                            try {
                                byte[] v3_3 = com.personal.aihub.SprkCodec.exact(v0_5, 21);
                            } catch (String v13_12) {
                                try {
                                    v11_14.close();
                                } catch (java.io.IOException v11_4) {
                                    v13_12.addSuppressed(v11_4);
                                }
                                throw v13_12;
                            }
                            if ((v3_3[0] != 83) || ((v3_3[1] != 80) || ((v3_3[2] != 82) || ((v3_3[3] != 75) || (v3_3[4] != 1))))) {
                                throw new java.io.IOException("Unsupported Sparking patch header. Only the verified SPRK version1 format is supported.");
                            } else {
                                javax.crypto.Cipher v7_1 = javax.crypto.Cipher.getInstance("AES/CTR/NoPadding");
                                v7_1.init(2, new javax.crypto.spec.SecretKeySpec(((byte[]) p13.clone()), "AES"), new javax.crypto.spec.IvParameterSpec(java.util.Arrays.copyOfRange(v3_3, 5, 21)));
                                String v13_6 = new byte[1048576];
                                long v2_1 = 0;
                                do {
                                    byte[] v8_0 = v0_5.read(v13_6);
                                    if (v8_0 == -1) {
                                        String v13_7 = v7_1.doFinal();
                                        if (v13_7 != null) {
                                            v11_14.write(v13_7);
                                        }
                                        v11_14.getFD().sync();
                                        v11_14.close();
                                        v0_5.close();
                                        com.personal.aihub.SprkCodec.central(v12_14);
                                        if (!v12_14.renameTo(v1_2)) {
                                            throw new java.io.IOException("Could not commit the decoded Sparking archive.");
                                        } else {
                                            v12_14.delete();
                                            return;
                                        }
                                    } else {
                                        v2_1 += ((long) v8_0);
                                        if (v2_1 > 536870912) {
                                            throw new java.io.IOException("Sparking patch exceeds the512MiB conversion limit.");
                                        } else {
                                            byte[] v8_1 = v7_1.update(v13_6, 0, v8_0);
                                        }
                                    }
                                } while(v8_1 == null);
                                v11_14.write(v8_1);
                            }
                        } catch (java.io.IOException v11_5) {
                            try {
                                v0_5.close();
                            } catch (String v13_13) {
                                v11_5.addSuppressed(v13_13);
                            }
                            throw v11_5;
                        }
                    } catch (java.io.IOException v11_6) {
                        v12_14.delete();
                        throw v11_6;
                    }
                }
            }
        }
    }

    private static void erase(java.io.File p4)
    {
        if (p4.isDirectory()) {
            java.io.File[] v0_1 = p4.listFiles();
            if (v0_1 != null) {
                int v1 = v0_1.length;
                int v2 = 0;
                while (v2 < v1) {
                    com.personal.aihub.SprkCodec.erase(v0_1[v2]);
                    v2++;
                }
            }
        }
        p4.delete();
        return;
    }

    private static byte[] exact(java.io.InputStream p3, int p4)
    {
        byte[] v0 = new byte[p4];
        int v1 = 0;
        while (v1 < p4) {
            int v2_1 = p3.read(v0, v1, (p4 - v1));
            if (v2_1 < 0) {
                throw new java.io.EOFException("The Sparking file is truncated.");
            } else {
                v1 += v2_1;
            }
        }
        return v0;
    }

    private static String hash(byte[] p1)
    {
        return com.personal.aihub.SprkCodec.hex(java.security.MessageDigest.getInstance("SHA-256").digest(p1));
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

    private static long id(org.json.JSONObject p6)
    {
        int v1_1 = 0;
        while (v1_1 < 3) {
            try {
                long v4_1 = p6.opt(new String[] {"creator_id", "creatorId", "creatorID"})[v1_1]);
            } catch (Exception) {
                v1_1++;
            }
            if (v4_1 == 0) {
            } else {
                if (!(v4_1 instanceof Boolean)) {
                    long v4_2 = String.valueOf(v4_1);
                    if (v4_2.matches("[0-9]{1,10}")) {
                        long v4_3 = Long.parseLong(v4_2);
                        if ((v4_3 <= 0) || (v4_3 > 2147483647)) {
                        } else {
                            return v4_3;
                        }
                    } else {
                    }
                } else {
                }
            }
        }
        return 0;
    }

    public static org.json.JSONObject inspect(java.io.File p32, java.io.File p33)
    {
        Throwable v0_0 = com.personal.aihub.SprkCodec.central(p32);
        String v1_30 = p33.getAbsoluteFile().getParentFile().getCanonicalFile();
        java.io.File v2_0 = new java.io.File(v1_30, p33.getName());
        if ((!v1_30.isDirectory()) || (v2_0.exists())) {
            throw new java.io.IOException("Choose a new empty location for Sparking conversion.");
        } else {
            java.io.IOException v4_1 = new StringBuilder("sprk-inspect-");
            v4_1.append(java.util.UUID.randomUUID());
            int v3_24 = new java.io.File(v1_30, v4_1.toString());
            if (!v3_24.mkdir()) {
                throw new java.io.IOException("Could not create Sparking conversion staging.");
            } else {
                String v1_22 = new org.json.JSONArray();
                java.io.IOException v4_19 = new org.json.JSONArray();
                org.json.JSONArray v5_15 = new org.json.JSONArray();
                org.json.JSONArray v6_3 = new org.json.JSONArray();
                org.json.JSONArray v7_1 = new org.json.JSONArray();
                org.json.JSONArray v8_19 = new org.json.JSONArray();
                org.json.JSONObject v9_12 = new org.json.JSONObject();
                java.util.HashSet v10_6 = new java.util.HashSet();
                try {
                    java.util.zip.ZipFile v11_3 = new java.util.zip.ZipFile(p32, java.nio.charset.Charset.forName("CP437"));
                    try {
                        Throwable v0_37 = v0_0.iterator();
                        long v12_1 = 0;
                        int v15_4 = 0;
                        int v16 = 0;
                    } catch (Throwable v0_45) {
                        java.io.File v2_5 = v3_24;
                        java.util.zip.ZipFile v25_0 = v11_3;
                        String v1_14 = v0_45;
                        try {
                            v25_0.close();
                        } catch (Throwable v0_44) {
                            v1_14.addSuppressed(v0_44);
                        }
                        throw v1_14;
                    } catch (Throwable v0_4) {
                        if (v2_5.exists()) {
                            com.personal.aihub.SprkCodec.erase(v2_5);
                        }
                        throw v0_4;
                    }
                    while(true) {
                        java.io.File v18 = v2_0;
                        long v19 = v12_1;
                        if (!v0_37.hasNext()) {
                            int v24_1 = v3_24;
                            Throwable v0_46 = v4_19;
                            org.json.JSONArray v22_1 = v8_19;
                            org.json.JSONObject v21_1 = v9_12;
                            int v23_1 = v15_4;
                            org.json.JSONArray v6_5 = v5_15;
                            org.json.JSONArray v5_16 = v6_3;
                            try {
                                org.json.JSONArray v8_21;
                                v11_3.close();
                            } catch (Throwable v0_4) {
                                v2_5 = v24_1;
                            }
                            if (v23_1 != 0) {
                                v8_21 = v22_1;
                            } else {
                                v8_21 = v22_1;
                                v8_21.put("This patch has no patch_info.json; keep its file name and supply a creation name.");
                            }
                            if (v0_46.length() == 0) {
                                v8_21.put("No patches/sql game-database payload is present. Assets or local roster data alone cannot create an Eclipse unit.");
                            }
                            if (v6_5.length() > 0) {
                                v8_21.put("This patch contains Sparking-only local roster SQL. It cannot be applied to Eclipse\'s game database.");
                            }
                            if (v7_1.length() > 0) {
                                v8_21.put("This patch contains Sparking Areas content whose Eclipse mapping is unverified.");
                            }
                            if (v16 != 0) {
                                v8_21.put("This archive has payloads outside the verified conversion layout. They need inspection before an Eclipse conversion.");
                            }
                            int v14_0;
                            java.util.zip.ZipFile v11_0 = v21_1;
                            org.json.JSONObject vtmp52 = new org.json.JSONObject().put("format", "sparking-sprk").put("formatVersion", 1).put("patchInfo", v11_0).put("creatorName", com.personal.aihub.SprkCodec.creatorName(v11_0)).put("creatorId", com.personal.aihub.SprkCodec.creatorId(v11_0)).put("entries", v1_22).put("gameSql", v0_46).put("localSql", v6_5).put("assets", v5_16).put("areas", v7_1).put("warnings", v8_21).put("bytes", v19);
                            if ((v0_46.length() <= 0) || ((v6_5.length() != 0) || ((v7_1.length() != 0) || (v16 != 0)))) {
                                v14_0 = 0;
                            } else {
                                v14_0 = 1;
                            }
                            Throwable v0_5 = vtmp52.put("canConvertToEclp", v14_0);
                            v2_5 = v24_1;
                            if (!v2_5.renameTo(v18)) {
                                throw new java.io.IOException("Could not commit staged Sparking resources.");
                            } else {
                                if (v2_5.exists()) {
                                    com.personal.aihub.SprkCodec.erase(v2_5);
                                }
                                return v0_5;
                            }
                        } else {
                            try {
                                String v13_2 = ((com.personal.aihub.SprkCodec$Member) v0_37.next());
                                Throwable v17_1 = v0_37;
                            } catch (Throwable v0_21) {
                                int v24_0 = v3_24;
                                v25_0 = v11_3;
                                v1_14 = v0_21;
                                v2_5 = v24_0;
                            }
                            if (!v13_2.directory) {
                                org.json.JSONObject v21_0 = v9_12;
                                Throwable v0_13 = new java.io.File(v3_24, v13_2.name).getCanonicalFile();
                                org.json.JSONObject v9_7 = v0_13.getPath();
                                org.json.JSONArray v22_0 = v8_19;
                                org.json.JSONArray v8_1 = new StringBuilder();
                                int v23_0 = v15_4;
                                v8_1.append(v3_24.getCanonicalPath());
                                v8_1.append(java.io.File.separator);
                                try {
                                    if (!v9_7.startsWith(v8_1.toString())) {
                                        v24_0 = v3_24;
                                        v25_0 = v11_3;
                                        throw new java.io.IOException("Unsafe Sparking path.");
                                    } else {
                                        org.json.JSONArray v8_4 = v0_13.getParentFile();
                                        if (!v8_4.mkdirs()) {
                                            try {
                                                if (!v8_4.isDirectory()) {
                                                    break;
                                                }
                                            } catch (Throwable v0_18) {
                                                v1_14 = v0_18;
                                                v2_5 = v3_24;
                                                v25_0 = v11_3;
                                            }
                                        }
                                        org.json.JSONArray v8_7 = v11_3.getEntry(v13_2.name);
                                        if (v8_7 == null) {
                                            v24_0 = v3_24;
                                            v25_0 = v11_3;
                                            throw new java.io.IOException("Missing Sparking ZIP entry.");
                                        } else {
                                            org.json.JSONObject v9_10 = java.security.MessageDigest.getInstance("SHA-256");
                                            int v15_3 = new java.util.zip.CRC32();
                                            v24_0 = v3_24;
                                            int v3_17 = new byte[65536];
                                            org.json.JSONArray v8_8 = v11_3.getInputStream(v8_7);
                                            v25_0 = v11_3;
                                            try {
                                                java.util.zip.ZipFile v11_2 = new java.io.FileOutputStream(v0_13);
                                                org.json.JSONArray v26 = v6_3;
                                                org.json.JSONArray v27 = v7_1;
                                                java.util.HashSet v28 = v10_6;
                                                org.json.JSONArray v6_0 = 0;
                                            } catch (Throwable v0_42) {
                                                String v1_27 = v0_42;
                                                if (v8_8 != null) {
                                                    try {
                                                        v8_8.close();
                                                    } catch (Throwable v0_43) {
                                                        v1_27.addSuppressed(v0_43);
                                                    }
                                                }
                                                throw v1_27;
                                            }
                                            try {
                                                while(true) {
                                                    java.util.HashSet v10_3 = v8_8.read(v3_17);
                                                    org.json.JSONArray v29 = v5_15;
                                                    v15_3.update(v3_17, 0, v10_3);
                                                    v9_10.update(v3_17, 0, v10_3);
                                                    v11_2.write(v3_17, 0, v10_3);
                                                    v5_15 = v29;
                                                    v4_19 = long v30_1;
                                                }
                                                throw new java.io.IOException("Expanded Sparking patch exceeds its supported size.");
                                            } catch (Throwable v0_40) {
                                                String v1_26 = v0_40;
                                                try {
                                                    v11_2.close();
                                                } catch (Throwable v0_41) {
                                                    v1_26.addSuppressed(v0_41);
                                                }
                                                throw v1_26;
                                            }
                                            if (v10_3 == -1) {
                                                long v30_0 = v4_19;
                                                v11_2.close();
                                                if (v8_8 != null) {
                                                    v8_8.close();
                                                }
                                                if ((v6_0 != v13_2.size) || (v15_3.getValue() != v13_2.crc)) {
                                                    throw new java.io.IOException("Sparking resource checksum does not match.");
                                                } else {
                                                    java.io.IOException v4_13;
                                                    Throwable v0_26;
                                                    org.json.JSONArray v5_13;
                                                    org.json.JSONArray v6_2;
                                                    int v3_23 = com.personal.aihub.SprkCodec.role(v13_2.name);
                                                    com.personal.aihub.SprkCodec.safe(v3_23[1]);
                                                    java.io.IOException v4_10 = new org.json.JSONObject().put("path", v13_2.name).put("relativePath", v3_23[1]).put("bytes", v6_0).put("sha256", com.personal.aihub.SprkCodec.hex(v9_10.digest())).put("kind", v3_23[0]);
                                                    v1_22.put(v4_10);
                                                    if (!v3_23[0].equals("metadata")) {
                                                        if (!v3_23[0].equals("gameSql")) {
                                                            v0_26 = v30_0;
                                                            if (!v3_23[0].equals("localSql")) {
                                                                v6_2 = v29;
                                                                if (!v3_23[0].equals("asset")) {
                                                                    v5_13 = v26;
                                                                    if (!v3_23[0].equals("area")) {
                                                                        v7_1 = v27;
                                                                        v9_12 = v21_0;
                                                                        v15_4 = v23_0;
                                                                        v4_13 = 0;
                                                                        v16 = 1;
                                                                        int v3_25;
                                                                        if (v3_23[v4_13].equals("other")) {
                                                                            v3_25 = v28;
                                                                        } else {
                                                                            java.io.File v2_22 = new StringBuilder();
                                                                            v2_22.append(v3_23[v4_13]);
                                                                            v2_22.append(":");
                                                                            v2_22.append(v3_23[1]);
                                                                            v3_25 = v28;
                                                                            if (!v3_25.add(v2_22.toString())) {
                                                                                throw new java.io.IOException("Sparking payload aliases would overwrite the same converted file.");
                                                                            } else {
                                                                            }
                                                                        }
                                                                        v4_19 = v0_26;
                                                                        v10_6 = v3_25;
                                                                        v0_37 = v17_1;
                                                                        v2_0 = v18;
                                                                        v12_1 = v19;
                                                                        v8_19 = v22_0;
                                                                        v3_24 = v24_0;
                                                                        v11_3 = v25_0;
                                                                        v6_3 = v5_13;
                                                                        v5_15 = v6_2;
                                                                    } else {
                                                                        v7_1 = v27;
                                                                        v7_1.put(v4_10);
                                                                        v9_12 = v21_0;
                                                                        v15_4 = v23_0;
                                                                        v4_13 = 0;
                                                                    }
                                                                } else {
                                                                    v5_13 = v26;
                                                                    v5_13.put(v4_10);
                                                                }
                                                            } else {
                                                                v6_2 = v29;
                                                                v6_2.put(v4_10);
                                                                v5_13 = v26;
                                                            }
                                                            v7_1 = v27;
                                                        } else {
                                                            v0_26 = v30_0;
                                                            v0_26.put(v4_10);
                                                            if (v13_2.name.toLowerCase(java.util.Locale.ROOT).endsWith(".sql")) {
                                                                v5_13 = v26;
                                                                v7_1 = v27;
                                                                v6_2 = v29;
                                                            } else {
                                                                v9_12 = v21_0;
                                                                v15_4 = v23_0;
                                                                v5_13 = v26;
                                                                v7_1 = v27;
                                                                v6_2 = v29;
                                                            }
                                                        }
                                                    } else {
                                                        if (v6_0 > 1048576) {
                                                            throw new java.io.IOException("Sparking metadata exceeds1MiB.");
                                                        } else {
                                                            java.io.File v2_17 = new java.io.FileInputStream(v0_13);
                                                            try {
                                                                Throwable v0_32 = new org.json.JSONObject(com.personal.aihub.SprkCodec.metadata(com.personal.aihub.SprkCodec.bounded(v2_17, 1048576)));
                                                            } catch (Throwable v0_33) {
                                                                String v1_23 = v0_33;
                                                                try {
                                                                    v2_17.close();
                                                                } catch (Throwable v0_34) {
                                                                    v1_23.addSuppressed(v0_34);
                                                                }
                                                                throw v1_23;
                                                            }
                                                            v2_17.close();
                                                            v9_12 = v0_32;
                                                            v5_13 = v26;
                                                            v7_1 = v27;
                                                            v6_2 = v29;
                                                            v0_26 = v30_0;
                                                            v4_13 = 0;
                                                            v15_4 = 1;
                                                        }
                                                    }
                                                }
                                            } else {
                                                v30_1 = v4_19;
                                                java.io.IOException v4_20 = ((long) v10_3);
                                                v6_0 += v4_20;
                                                v19 += v4_20;
                                                if ((v6_0 <= v13_2.size) && ((v6_0 <= 536870912) && (v19 <= 1073741824))) {
                                                }
                                            }
                                        }
                                    }
                                } catch (Throwable v0_21) {
                                }
                            } else {
                                v0_37 = v17_1;
                                v2_0 = v18;
                                v12_1 = v19;
                            }
                        }
                    }
                    throw new java.io.IOException("Could not stage Sparking resources.");
                } catch (Throwable v0_4) {
                    v2_5 = v3_24;
                }
            }
        }
    }

    public static byte[] keyFromApk(java.io.File p4)
    {
        byte[] v0_1 = new byte[32];
        System.arraycopy(com.personal.aihub.SprkCodec.supportedLibrary(p4), 648423, v0_1, 0, 16);
        return v0_1;
    }

    private static String metadata(byte[] p9)
    {
        java.io.IOException v9_1 = java.nio.charset.StandardCharsets.UTF_8.newDecoder().onMalformedInput(java.nio.charset.CodingErrorAction.REPORT).decode(java.nio.ByteBuffer.wrap(p9)).toString();
        int v1_0 = 0;
        int v2 = 0;
        int v3 = 0;
        int v4 = 0;
        while (v1_0 < v9_1.length()) {
            int v5_1 = v9_1.charAt(v1_0);
            if (v2 == 0) {
                if (v5_1 != 34) {
                    if ((v5_1 != 123) && (v5_1 != 91)) {
                        if ((v5_1 == 125) || (v5_1 == 93)) {
                            v4--;
                        }
                    } else {
                        v4++;
                        if (v4 > 32) {
                            throw new java.io.IOException("Sparking patch metadata is nested too deeply.");
                        }
                    }
                } else {
                    v2 = 1;
                }
            } else {
                if (v3 == 0) {
                    if (v5_1 != 92) {
                        if (v5_1 == 34) {
                            v2 = 0;
                        }
                    } else {
                        v3 = 1;
                    }
                } else {
                    v3 = 0;
                }
            }
            v1_0++;
        }
        return v9_1;
    }

    private static String name(byte[] p1, int p2)
    {
        java.nio.charset.CharsetDecoder v2_5;
        if ((p2 & 2048) == 0) {
            v2_5 = java.nio.charset.Charset.forName("CP437");
        } else {
            v2_5 = java.nio.charset.StandardCharsets.UTF_8;
        }
        return v2_5.newDecoder().onMalformedInput(java.nio.charset.CodingErrorAction.REPORT).onUnmappableCharacter(java.nio.charset.CodingErrorAction.REPORT).decode(java.nio.ByteBuffer.wrap(p1)).toString();
    }

    private static String[] role(String p6)
    {
        if (!p6.equals("patch_info.json")) {
            int v1_0 = 0;
            String v2_5 = 0;
            while (v2_5 < 2) {
                boolean v3_3 = new String[] {"patches/localsql/", "localsql/"})[v2_5];
                if (!p6.startsWith(v3_3)) {
                    v2_5++;
                } else {
                    return new String[] {"localSql", p6.substring(v3_3.length())});
                }
            }
            if (!p6.startsWith("patches/sql/")) {
                String v2_1 = 0;
                while (v2_1 < 2) {
                    String v4_0 = new String[] {"patches/assets/", "assets/"})[v2_1];
                    if (!p6.startsWith(v4_0)) {
                        v2_1++;
                    } else {
                        return new String[] {"asset", p6.substring(v4_0.length())});
                    }
                }
                while (v1_0 < 3) {
                    String v2_4 = new String[] {"patches/Areas/", "Areas/", "areas/"})[v1_0];
                    if (!p6.startsWith(v2_4)) {
                        v1_0++;
                    } else {
                        return new String[] {"area", p6.substring(v2_4.length())});
                    }
                }
                return new String[] {"other", p6});
            } else {
                return new String[] {"gameSql", p6.substring(12)});
            }
        } else {
            return new String[] {"metadata", p6});
        }
    }

    private static void safe(String p5)
    {
        if ((p5.isEmpty()) || ((p5.length() > 500) || ((p5.startsWith("/")) || ((p5.indexOf(92) >= 0) || (p5.matches("(?s).*[:\\x00-\\x1f\\x7f].*")))))) {
            throw new java.io.IOException("The Sparking archive contains an unsafe file path.");
        } else {
            java.io.IOException v5_3 = p5.split("/", -1);
            int v2_6 = 0;
            while (v2_6 < v5_3.length) {
                boolean v3_0 = v5_3[v2_6];
                if ((v3_0.isEmpty()) || ((v3_0.equals(".")) || (v3_0.equals("..")))) {
                    throw new java.io.IOException("The Sparking archive contains an unsafe file path.");
                } else {
                    v2_6++;
                }
            }
            return;
        }
    }

    private static byte[] supportedLibrary(java.io.File p6)
    {
        if (!p6.isFile()) {
            throw new java.io.IOException("Import the original Sparking6.5.5 Android APK first.");
        } else {
            Throwable v0_4 = new java.util.zip.ZipFile(p6);
            try {
                Throwable v6_1 = v0_4.entries();
                String v1_0 = 0;
            } catch (Throwable v6_18) {
                try {
                    v0_4.close();
                } catch (Throwable v0_3) {
                    v6_18.addSuppressed(v0_3);
                }
                throw v6_18;
            }
            while (v6_1.hasMoreElements()) {
                String v2_6 = ((java.util.zip.ZipEntry) v6_1.nextElement());
                if (v2_6.getName().equals("lib/arm64-v8a/libbase.so")) {
                    if (v1_0 != null) {
                        throw new java.io.IOException("The APK has duplicate native libraries.");
                    } else {
                        v1_0 = v2_6;
                    }
                }
            }
            if ((v1_0 == null) || ((v1_0.isDirectory()) || ((v1_0.getSize() < 648439) || ((v1_0.getSize() > 16777216) || (v1_0.getCompressedSize() > 16777216))))) {
                throw new java.io.IOException("This APK does not contain the supported Sparking6.5.5 Android format library.");
            } else {
                Throwable v6_9 = v0_4.getInputStream(v1_0);
                try {
                    String v1_3 = com.personal.aihub.SprkCodec.bounded(v6_9, 16777216);
                } catch (String v1_4) {
                    if (v6_9 != null) {
                        try {
                            v6_9.close();
                        } catch (Throwable v6_10) {
                            v1_4.addSuppressed(v6_10);
                        }
                    }
                    throw v1_4;
                }
                if (v6_9 != null) {
                    v6_9.close();
                }
                if (!"9d3f2749e391d990496b632b6adc135492f71e0baec7125d7b613a56e771dca0".equals(com.personal.aihub.SprkCodec.hash(v1_3))) {
                    throw new java.io.IOException("This Sparking APK version is not supported for SPRK conversion. Its native format must be checked before importing encrypted patches.");
                } else {
                    v0_4.close();
                    return v1_3;
                }
            }
        }
    }

    private static int u16(byte[] p1, int p2)
    {
        return (((p1[(p2 + 1)] & 255) << 8) | (p1[p2] & 255));
    }

    private static long u32(byte[] p3, int p4)
    {
        return ((((long) com.personal.aihub.SprkCodec.u16(p3, (p4 + 2))) << 16) | ((long) com.personal.aihub.SprkCodec.u16(p3, p4)));
    }
}
