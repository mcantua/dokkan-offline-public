package com.personal.aihub;
public final class EclpCodec {
    private static final long KDF_HEAP_REQUIRED = 100663296;
    private static final String KDF_MEMORY_MESSAGE = "There is not enough memory to convert this Eclipse patch. Close previews and try again, or use Forge on a device with more memory.";
    public static final long MAX_FILE = 536870912;
    public static final long MAX_TOTAL = 4294967296;

    private EclpCodec()
    {
        return;
    }

    private static long copy(java.io.InputStream p6, java.io.OutputStream p7, long p8)
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
                return v1;
            }
        }
        throw new java.io.IOException("ECLP file exceeds its declared or supported size");
    }

    public static byte[] derive(String p11, String p12, String p13, byte[] p14)
    {
        org.bouncycastle.crypto.generators.Argon2BytesGenerator v2_4 = 0;
        while (v2_4 < 3) {
            int v3_0 = new String[] {p11, p12, p13})[v2_4];
            if ((v3_0 == 0) || ((v3_0.trim().isEmpty()) || (v3_0.length() > 1000))) {
                throw new java.io.IOException("Patch UUID, name, and version are required (maximum 1,000 characters)");
            } else {
                v2_4++;
            }
        }
        byte[] v0_5 = Runtime.getRuntime();
        int v4_5 = ((v0_5.maxMemory() - v0_5.totalMemory()) + v0_5.freeMemory());
        if (v4_5 < 100663296) {
            if (v0_5.maxMemory() >= 100663296) {
                System.gc();
                v4_5 = ((v0_5.maxMemory() - v0_5.totalMemory()) + v0_5.freeMemory());
            }
            if (v4_5 < 100663296) {
                throw new java.io.IOException("There is not enough memory to convert this Eclipse patch. Close previews and try again, or use a device with more memory.");
            }
        }
        byte[] v0_4 = java.security.MessageDigest.getInstance("SHA-256");
        org.bouncycastle.crypto.generators.Argon2BytesGenerator v2_8 = new StringBuilder();
        v2_8.append(String.valueOf(p11));
        v2_8.append("|");
        v2_8.append(p12);
        v2_8.append("|");
        v2_8.append(p13);
        java.io.IOException v11_9 = v0_4.digest(v2_8.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8));
        byte[] v12_4 = new byte[64];
        System.arraycopy(v11_9, 0, v12_4, 0, 32);
        byte[] v0_1 = 0;
        while (v0_1 < 32) {
            org.bouncycastle.crypto.generators.Argon2BytesGenerator v2_0 = (v0_1 * 2);
            v12_4[(v0_1 + 32)] = ((byte) Integer.parseInt("ef16bc5f9378dc3fef16bc5f937ed622f910b35a9e76b8478b15d32be96dbf4c".substring(v2_0, (v2_0 + 2)), 16));
            v0_1++;
        }
        try {
            java.io.IOException v14_2 = new org.bouncycastle.crypto.params.Argon2Parameters$Builder(2).withVersion(19).withIterations(3).withMemoryAsKB(65536).withParallelism(4).withSalt(p14).build();
            org.bouncycastle.crypto.generators.Argon2BytesGenerator v2_16 = new org.bouncycastle.crypto.generators.Argon2BytesGenerator();
            v2_16.init(v14_2);
            byte[] v0_6 = new byte[32];
            v2_16.generateBytes(v12_4, v0_6);
            java.util.Arrays.fill(v12_4, 0);
            java.util.Arrays.fill(v11_9, 0);
            return v0_6;
        } catch (Throwable v13_3) {
            java.util.Arrays.fill(v12_4, 0);
            java.util.Arrays.fill(v11_9, 0);
            throw v13_3;
        } catch (Throwable v13_2) {
            if (v0_6 != null) {
                java.util.Arrays.fill(v0_6, 0);
            }
            System.gc();
            throw new java.io.IOException("There is not enough memory to convert this Eclipse patch. Close previews and try again, or use a device with more memory.", v13_2);
        }
    }

    private static byte[] exact(java.io.InputStream p3, int p4)
    {
        byte[] v0 = new byte[p4];
        int v1 = 0;
        while (v1 < p4) {
            int v2_1 = p3.read(v0, v1, (p4 - v1));
            if (v2_1 < 0) {
                throw new java.io.EOFException("Truncated ECLP file");
            } else {
                v1 += v2_1;
            }
        }
        return v0;
    }

    public static java.util.List extract(java.io.File p20, java.io.File p21, java.io.File p22, String p23, String p24, String p25)
    {
        int v0_0 = com.personal.aihub.EclpCodec.header(p20);
        java.io.File v1_3 = com.personal.aihub.EclpCodec.derive(p23, p24, p25, v0_0.salt);
        long[] v8_1 = new org.bouncycastle.crypto.modes.GCMBlockCipher(new org.bouncycastle.crypto.engines.AESEngine());
        try {
            v8_1.init(0, new org.bouncycastle.crypto.params.AEADParameters(new org.bouncycastle.crypto.params.KeyParameter(v1_3), 128, v0_0.nonce));
            java.util.Arrays.fill(v1_3, 0);
            int v2_19 = new StringBuilder("eclp-payload-");
            v2_19.append(java.util.UUID.randomUUID());
            java.io.File v1_2 = new java.io.File(p22, v2_19.toString());
            java.util.ArrayList v10_0 = new java.util.ArrayList();
            java.util.HashSet v11_1 = new java.util.HashSet();
            try {
                com.personal.aihub.EclpCodec$2 v12_6 = new java.io.FileInputStream(p20);
                try {
                    String v13_4 = new java.io.FileOutputStream(v1_2);
                    try {
                        int v2_20 = v0_0.offset;
                    } catch (int v0_21) {
                        int v2_21 = v0_21;
                        try {
                            v13_4.close();
                        } catch (int v0_22) {
                            v2_21.addSuppressed(v0_22);
                        }
                        throw v2_21;
                    }
                    while (v2_20 > 0) {
                        java.util.ArrayList v4_12 = v12_6.skip(v2_20);
                        if (v4_12 <= 0) {
                            throw new java.io.EOFException();
                        } else {
                            v2_20 -= v4_12;
                        }
                    }
                    int v0_29 = new byte[65536];
                    while(true) {
                        String v5_8 = v12_6.read(v0_29);
                        if (v5_8 == -1) {
                            break;
                        }
                        int v7_0 = new byte[v8_1.getOutputSize(v5_8)];
                        v13_4.write(v7_0, 0, v8_1.processBytes(v0_29, 0, v5_8, v7_0, 0));
                    }
                    int v0_31 = new byte[v8_1.getOutputSize(0)];
                    try {
                        v13_4.write(v0_31, 0, v8_1.doFinal(v0_31, 0));
                    } catch (int v0_32) {
                        throw new java.io.IOException("ECLP authentication failed: file damaged or metadata changed", v0_32);
                    }
                    v13_4.close();
                    v12_6.close();
                    Throwable v3_13 = new java.io.BufferedInputStream(new java.io.FileInputStream(v1_2));
                    try {
                        java.util.ArrayList v4_10 = com.personal.aihub.EclpCodec.number(v3_13, 4);
                    } catch (int v0_16) {
                        int v2_15 = v0_16;
                        try {
                            v3_13.close();
                        } catch (int v0_17) {
                            v2_15.addSuppressed(v0_17);
                        }
                        throw v2_15;
                    }
                    if (v4_10 > 100000) {
                        throw new java.io.IOException("Too many ECLP files");
                    } else {
                        int v0_15 = 0;
                        long v6_0 = 0;
                        while (((long) v0_15) < v4_10) {
                            long[] v8_0 = ((int) com.personal.aihub.EclpCodec.number(v3_13, 2));
                            if ((v8_0 < 1) || (v8_0 > 4096)) {
                                throw new java.io.IOException("Invalid ECLP path length");
                            } else {
                                String v13_2 = new String(com.personal.aihub.EclpCodec.exact(v3_13, v8_0), java.nio.charset.StandardCharsets.UTF_8);
                                if ((!com.personal.aihub.EclpCodec.safePath(v13_2)) || (!v11_1.add(v13_2))) {
                                    throw new java.io.IOException("Unsafe or duplicate ECLP path");
                                } else {
                                    java.io.File v14_1 = com.personal.aihub.EclpCodec.number(v3_13, 8);
                                    java.util.ArrayList v25_1 = v10_0;
                                    int v9_1 = com.personal.aihub.EclpCodec.number(v3_13, 8);
                                    v6_0 += v9_1;
                                    if ((v14_1 < 1) || ((v14_1 > 536870912) || ((v9_1 > 536870912) || (v6_0 > 4294967296)))) {
                                        throw new java.io.IOException("Invalid ECLP entry size");
                                    } else {
                                        long[] v8_10 = new long[1];
                                        v8_10[0] = v14_1;
                                        com.personal.aihub.EclpCodec$2 v12_4 = new com.personal.aihub.EclpCodec$2(v8_10, v3_13);
                                        java.io.File v14_3 = new java.io.File(p21, v13_2);
                                        v14_3.getParentFile().mkdirs();
                                        int v2_5 = v14_3.getCanonicalPath();
                                        java.util.ArrayList v16_4 = v4_10;
                                        java.util.ArrayList v4_2 = new StringBuilder();
                                        v4_2.append(p21.getCanonicalPath());
                                        v4_2.append(java.io.File.separator);
                                        if (!v2_5.startsWith(v4_2.toString())) {
                                            throw new java.io.IOException("Unsafe ECLP destination");
                                        } else {
                                            int v2_9 = new com.github.luben.zstd.ZstdInputStream(v12_4);
                                            try {
                                                java.util.ArrayList v4_5 = new java.io.FileOutputStream(v14_3);
                                                try {
                                                    if ((com.personal.aihub.EclpCodec.copy(v2_9, v4_5, v9_1) != v9_1) || (v8_10[0] != 0)) {
                                                        throw new java.io.IOException("ECLP entry size mismatch");
                                                    } else {
                                                        v4_5.close();
                                                        v2_9.close();
                                                        java.util.ArrayList v4_9 = v25_1;
                                                        v4_9.add(new com.personal.aihub.EclpCodec$Entry(v13_2, v14_3, 0));
                                                        v0_15++;
                                                        v10_0 = v4_9;
                                                        v4_10 = v16_4;
                                                        int v9 = 0;
                                                    }
                                                } catch (int v0_11) {
                                                    String v5_7 = v0_11;
                                                    try {
                                                        v4_5.close();
                                                    } catch (int v0_12) {
                                                        v5_7.addSuppressed(v0_12);
                                                    }
                                                    throw v5_7;
                                                }
                                            } catch (int v0_13) {
                                                java.util.ArrayList v4_7 = v0_13;
                                                try {
                                                    v2_9.close();
                                                } catch (int v0_14) {
                                                    v4_7.addSuppressed(v0_14);
                                                }
                                                throw v4_7;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        java.util.ArrayList v4_14 = v10_0;
                        if (v3_13.read() != -1) {
                            throw new java.io.IOException("Unexpected trailing ECLP payload data");
                        } else {
                            v3_13.close();
                            v1_2.delete();
                            return v4_14;
                        }
                    }
                } catch (int v0_23) {
                    int v2_22 = v0_23;
                    try {
                        v12_6.close();
                    } catch (int v0_24) {
                        v2_22.addSuppressed(v0_24);
                    }
                    throw v2_22;
                }
            } catch (int v0_25) {
                v1_2.delete();
                throw v0_25;
            }
        } catch (int v0_26) {
            java.util.Arrays.fill(v1_2, 0);
            throw v0_26;
        }
    }

    public static com.personal.aihub.EclpCodec$Header header(java.io.File p10)
    {
        Throwable v0_1 = new java.io.FileInputStream(p10);
        try {
            java.nio.charset.Charset v2_3 = com.personal.aihub.EclpCodec.exact(v0_1, 4);
            String v3_6 = new byte[4];
            v3_6 = {69, 67, 76, 80};
        } catch (com.personal.aihub.EclpCodec$Header v10_6) {
            try {
                v0_1.close();
            } catch (Throwable v0_2) {
                v10_6.addSuppressed(v0_2);
            }
            throw v10_6;
        }
        if ((!java.util.Arrays.equals(v2_3, v3_6)) || (com.personal.aihub.EclpCodec.number(v0_1, 2) != 1)) {
            throw new java.io.IOException("Unsupported ECLP header or version");
        } else {
            byte[] v1_2 = com.personal.aihub.EclpCodec.number(v0_1, 4);
            long v6_1 = (54 + v1_2);
            if ((v1_2 < 1) || ((v1_2 > 4194304) || ((p10.length() < (70 + v1_2)) || (p10.length() > 4299161600)))) {
                throw new java.io.IOException("Invalid ECLP length");
            } else {
                com.personal.aihub.EclpCodec$Header v10_8 = new com.personal.aihub.EclpCodec$Header();
                v10_8.metadata = new String(com.personal.aihub.EclpCodec.exact(v0_1, ((int) v1_2)), java.nio.charset.StandardCharsets.UTF_8);
                v10_8.salt = com.personal.aihub.EclpCodec.exact(v0_1, 32);
                v10_8.nonce = com.personal.aihub.EclpCodec.exact(v0_1, 12);
                v10_8.offset = v6_1;
                v0_1.close();
                return v10_8;
            }
        }
    }

    private static long number(java.io.InputStream p6, int p7)
    {
        java.io.IOException v6_1 = com.personal.aihub.EclpCodec.exact(p6, p7);
        String v7_1 = (p7 - 1);
        long v2_1 = 0;
        while (v7_1 >= null) {
            v2_1 = ((v2_1 << 8) | ((long) (v6_1[v7_1] & 255)));
            v7_1--;
        }
        if (v2_1 < 0) {
            throw new java.io.IOException("Invalid ECLP integer");
        } else {
            return v2_1;
        }
    }

    private static void number(java.io.OutputStream p3, long p4, int p6)
    {
        int v0 = 0;
        while (v0 < p6) {
            p3.write(((int) (255 & p4)));
            p4 >>= 8;
            v0++;
        }
        return;
    }

    private static void remove(java.io.File p4)
    {
        if (p4.isDirectory()) {
            java.io.File[] v0_1 = p4.listFiles();
            if (v0_1 != null) {
                int v1 = v0_1.length;
                int v2 = 0;
                while (v2 < v1) {
                    com.personal.aihub.EclpCodec.remove(v0_1[v2]);
                    v2++;
                }
            }
        }
        p4.delete();
        return;
    }

    public static boolean safePath(String p5)
    {
        if ((p5 == 0) || ((p5.isEmpty()) || ((p5.length() > 4096) || ((p5.startsWith("/")) || ((p5.contains("\\")) || (p5.matches(".*[:\\x00-\\x1f].*"))))))) {
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

    public static void write(java.io.OutputStream p18, java.io.File p19, java.util.List p20, String p21, String p22, String p23, String p24)
    {
        if (p20.size() > 100000) {
            throw new java.io.IOException("Too many patch files");
        } else {
            String v1_0 = p21.getBytes(java.nio.charset.StandardCharsets.UTF_8);
            if (v1_0.length > 4194304) {
                throw new java.io.IOException("Patch metadata too large");
            } else {
                Throwable v3_6 = new StringBuilder("eclp-write-");
                v3_6.append(java.util.UUID.randomUUID());
                java.io.File v2_4 = new java.io.File(p19, v3_6.toString());
                v2_4.mkdirs();
                Throwable v3_9 = new java.util.HashSet();
                java.util.ArrayList v4_4 = new java.util.ArrayList();
                try {
                    java.io.FileInputStream v5_4 = p20.iterator();
                    java.io.File v6_2 = 0;
                } catch (java.io.IOException v0_17) {
                    com.personal.aihub.EclpCodec.remove(v2_4);
                    throw v0_17;
                }
                while (v5_4.hasNext()) {
                    long v8_2 = ((com.personal.aihub.EclpCodec$Entry) v5_4.next());
                    if ((!com.personal.aihub.EclpCodec.safePath(v8_2.path)) || ((v8_2.path.getBytes(java.nio.charset.StandardCharsets.UTF_8).length > 4096) || (!v3_9.add(v8_2.path)))) {
                        throw new java.io.IOException("Invalid or duplicate ECLP path");
                    } else {
                        v6_2 += v8_2.size();
                        if ((v8_2.size() > 536870912) || (v6_2 > 4294967296)) {
                            throw new java.io.IOException("ECLP exceeds the 512 MB per file or 4 GB total limit");
                        } else {
                            java.io.File v11_17 = new java.io.File(v2_4, Integer.toString(v4_4.size()));
                            long v12_6 = v8_2.input();
                            try {
                                com.github.luben.zstd.ZstdOutputStream v13_1 = new com.github.luben.zstd.ZstdOutputStream(new java.io.FileOutputStream(v11_17), 3);
                            } catch (java.io.IOException v0_13) {
                                String v1_8 = v0_13;
                                if (v12_6 != 0) {
                                    try {
                                        v12_6.close();
                                    } catch (java.io.IOException v0_14) {
                                        v1_8.addSuppressed(v0_14);
                                    }
                                }
                                throw v1_8;
                            }
                            try {
                                if (com.personal.aihub.EclpCodec.copy(v12_6, v13_1, 536870912) != v8_2.size()) {
                                    throw new java.io.IOException("Resource changed during export");
                                } else {
                                    v13_1.close();
                                    if (v12_6 != 0) {
                                        v12_6.close();
                                    }
                                    if (v11_17.length() > 536870912) {
                                        throw new java.io.IOException("Compressed entry exceeds Eclipse\u2019s 512 MB limit");
                                    } else {
                                        v4_4.add(v11_17);
                                    }
                                }
                            } catch (java.io.IOException v0_11) {
                                String v1_6 = v0_11;
                                try {
                                    v13_1.close();
                                } catch (java.io.IOException v0_12) {
                                    v1_6.addSuppressed(v0_12);
                                }
                                throw v1_6;
                            }
                        }
                    }
                }
                Throwable v3_11 = new byte[32];
                java.io.FileInputStream v5_6 = new byte[12];
                java.io.File v6_4 = new java.security.SecureRandom();
                v6_4.nextBytes(v3_11);
                v6_4.nextBytes(v5_6);
                java.io.File v6_6 = com.personal.aihub.EclpCodec.derive(p22, p23, p24, v3_11);
                javax.crypto.Cipher v7_2 = javax.crypto.Cipher.getInstance("AES/GCM/NoPadding");
                long v8_0 = 0;
                try {
                    v7_2.init(1, new javax.crypto.spec.SecretKeySpec(v6_6, "AES"), new javax.crypto.spec.GCMParameterSpec(128, v5_6));
                } catch (java.io.IOException v0_19) {
                    java.util.Arrays.fill(v6_6, 0);
                    throw v0_19;
                }
                java.util.Arrays.fill(v6_6, 0);
                java.io.File v11_20 = new byte[4];
                v11_20 = {69, 67, 76, 80};
                p18.write(v11_20);
                com.personal.aihub.EclpCodec.number(p18, 1, 2);
                com.personal.aihub.EclpCodec.number(p18, ((long) v1_0.length), 4);
                p18.write(v1_0);
                p18.write(v3_11);
                p18.write(v5_6);
                String v1_12 = new com.personal.aihub.EclpCodec$1(v7_2, p18);
                com.personal.aihub.EclpCodec.number(v1_12, ((long) p20.size()), 4);
                while (v8_0 < p20.size()) {
                    java.io.FileInputStream v5_1 = ((com.personal.aihub.EclpCodec$Entry) p20.get(v8_0));
                    java.io.File v6_1 = ((java.io.File) v4_4.get(v8_0));
                    java.io.File v11_1 = v5_1.path.getBytes(java.nio.charset.StandardCharsets.UTF_8);
                    com.personal.aihub.EclpCodec.number(v1_12, ((long) v11_1.length), 2);
                    v1_12.write(v11_1);
                    com.personal.aihub.EclpCodec.number(v1_12, v6_1.length(), 8);
                    com.personal.aihub.EclpCodec.number(v1_12, v5_1.size(), 8);
                    java.io.FileInputStream v5_3 = new java.io.FileInputStream(v6_1);
                    try {
                        com.personal.aihub.EclpCodec.copy(v5_3, v1_12, 536870912);
                    } catch (java.io.IOException v0_1) {
                        String v1_1 = v0_1;
                        try {
                            v5_3.close();
                        } catch (java.io.IOException v0_2) {
                            v1_1.addSuppressed(v0_2);
                        }
                        throw v1_1;
                    }
                    v5_3.close();
                    v8_0++;
                }
                p18.write(v7_2.doFinal());
                p18.flush();
                com.personal.aihub.EclpCodec.remove(v2_4);
                return;
            }
        }
    }
}
