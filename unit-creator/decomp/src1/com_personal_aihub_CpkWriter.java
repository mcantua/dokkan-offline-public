package com.personal.aihub;
public final class CpkWriter {
    private static final int ALIGN = 2048;
    public static final int MAX_FILES = 5000;
    public static final int MAX_FILE_BYTES = 167772160;
    public static final int MAX_TOTAL_BYTES = 536870912;
    private static final java.util.Set PRIVATE;

    static CpkWriter()
    {
        String v3 = "exports";
        String v5 = "metadata.json";
        String v7 = "database-meta.json";
        String v9 = "account.txt";
        com.personal.aihub.CpkWriter.PRIVATE = new java.util.HashSet(java.util.Arrays.asList(new String[] {"projects", "secrets.json"})));
        return;
    }

    public CpkWriter()
    {
        return;
    }

    private static int align(long p2)
    {
        java.io.IOException v2_5 = (((p2 + 2047) / 2048) * 2048);
        if (v2_5 > 536870912) {
            throw com.personal.aihub.CpkWriter.error("Archive exceeds512MB.");
        } else {
            return ((int) v2_5);
        }
    }

    private static com.personal.aihub.CpkWriter$Col c(String p1, int p2)
    {
        return new com.personal.aihub.CpkWriter$Col(p1, p2);
    }

    public static int compareCriPaths(String p5, String p6)
    {
        int v5_3 = p5.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        int v6_2 = p6.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        int v0_1 = 0;
        while (v0_1 < Math.min(v5_3.length, v6_2.length)) {
            int v1_2 = (v5_3[v0_1] & 255);
            int v2_1 = (v6_2[v0_1] & 255);
            if ((v1_2 >= 97) && (v1_2 <= 122)) {
                v1_2 -= 32;
            }
            if ((v2_1 >= 97) && (v2_1 <= 122)) {
                v2_1 -= 32;
            }
            if (v1_2 == v2_1) {
                v0_1++;
            } else {
                return (v1_2 - v2_1);
            }
        }
        return (v5_3.length - v6_2.length);
    }

    public static int compareUtf8(String p3, String p4)
    {
        int v3_3 = p3.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        int v4_2 = p4.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        int v0_1 = 0;
        while (v0_1 < Math.min(v3_3.length, v4_2.length)) {
            int v1_3 = ((v3_3[v0_1] & 255) - (v4_2[v0_1] & 255));
            if (v1_3 == 0) {
                v0_1++;
            } else {
                return v1_3;
            }
        }
        return (v3_3.length - v4_2.length);
    }

    private static java.io.IOException error(String p3)
    {
        StringBuilder v1_1 = new StringBuilder("CPK: ");
        v1_1.append(p3);
        return new java.io.IOException(v1_1.toString());
    }

    private static byte[] header(long p35, long p37, long p39, int p41, long p42)
    {
        byte[] v0_1 = new com.personal.aihub.CpkWriter$Col[15];
        v0_1[0] = com.personal.aihub.CpkWriter.c("ContentOffset", 6);
        Integer v24 = Integer.valueOf(1);
        v0_1[1] = com.personal.aihub.CpkWriter.c("ContentSize", 6);
        v0_1[2] = com.personal.aihub.CpkWriter.c("TocOffset", 6);
        v0_1[3] = com.personal.aihub.CpkWriter.c("TocSize", 6);
        v0_1[4] = com.personal.aihub.CpkWriter.c("Files", 4);
        v0_1[5] = com.personal.aihub.CpkWriter.c("Version", 2);
        v0_1[6] = com.personal.aihub.CpkWriter.c("Revision", 2);
        v0_1[7] = com.personal.aihub.CpkWriter.c("Align", 2);
        v0_1[8] = com.personal.aihub.CpkWriter.c("Sorted", 2);
        v0_1[9] = com.personal.aihub.CpkWriter.c("EnableFileName", 2);
        v0_1[10] = com.personal.aihub.CpkWriter.c("EID", 2);
        v0_1[11] = com.personal.aihub.CpkWriter.c("CpkMode", 4);
        v0_1[12] = com.personal.aihub.CpkWriter.c("Tvers", 10);
        v0_1[13] = com.personal.aihub.CpkWriter.c("EnabledPackedSize", 6);
        v0_1[14] = com.personal.aihub.CpkWriter.c("EnabledDataSize", 6);
        Long.valueOf(p35);
        Long.valueOf(p37);
        Integer.valueOf(2048);
        Long v12 = Long.valueOf(p39);
        Integer.valueOf(p41);
        Integer.valueOf(7);
        Integer.valueOf(14);
        Integer.valueOf(0);
        Long.valueOf(p42);
        String v33 = "EnabledDataSize";
        String v9 = "TocOffset";
        String v13 = "Files";
        String v17 = "Revision";
        String v21 = "Sorted";
        String v25 = "EID";
        String v29 = "Tvers";
        String v31 = "EnabledPackedSize";
        return com.personal.aihub.CpkWriter.packet("CPK ", com.personal.aihub.CpkWriter.utf("CpkHeader", v0_1, java.util.Collections.singletonList(com.personal.aihub.CpkWriter.row(new Object[] {"ContentOffset", Long.valueOf(p42)})))));
    }

    static Integer lambda$0(java.util.Map p4, java.io.ByteArrayOutputStream p5, String p6)
    {
        int v0_1 = ((Integer) p4.get(p6));
        if (v0_1 == 0) {
            int v0_2 = p5.size();
            byte[] v1_1 = p6.getBytes(java.nio.charset.StandardCharsets.UTF_8);
            p5.write(v1_1, 0, v1_1.length);
            p5.write(0);
            p4.put(p6, Integer.valueOf(v0_2));
            return Integer.valueOf(v0_2);
        } else {
            return v0_1;
        }
    }

    private static byte[] packet(String p3, byte[] p4)
    {
        java.nio.ByteBuffer v0_3 = java.nio.ByteBuffer.allocate((p4.length + 16)).order(java.nio.ByteOrder.LITTLE_ENDIAN);
        v0_3.put(p3.getBytes(java.nio.charset.StandardCharsets.US_ASCII)).putInt(255).putLong(((long) p4.length)).put(p4);
        return v0_3.array();
    }

    private static void padding(java.io.OutputStream p3, long p4)
    {
        byte[] v0_1 = new byte[2048];
        while (p4 > 0) {
            long v1_5 = ((int) Math.min(p4, 2048));
            p3.write(v0_1, 0, v1_5);
            p4 -= ((long) v1_5);
        }
        return;
    }

    private static varargs java.util.Map row(Object[] p4)
    {
        java.util.LinkedHashMap v0_1 = new java.util.LinkedHashMap();
        int v1 = 0;
        while (v1 < p4.length) {
            v0_1.put(((String) p4[v1]), p4[(v1 + 1)]);
            v1 += 2;
        }
        return v0_1;
    }

    private static boolean safe(String p7)
    {
        if ((p7 == 0) || ((p7.isEmpty()) || ((p7.length() > 500) || (p7.startsWith("/"))))) {
            return 0;
        } else {
            int v2_1 = p7.toCharArray();
            int v4_0 = 0;
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
                int v4_1 = v1_0[v3_1];
                if ((!v4_1.isEmpty()) && ((!v4_1.startsWith(".")) && (!com.personal.aihub.CpkWriter.PRIVATE.contains(v4_1.toLowerCase(java.util.Locale.ROOT))))) {
                    v3_1++;
                } else {
                    return 0;
                }
            }
            return (p7.matches("(?i).*\\.(db|sqlite|sqlite3)([-.].*)?$") ^ 1);
        }
    }

    private static java.io.File source(java.io.File p5, String p6)
    {
        if ((!com.personal.aihub.CpkWriter.safe(p6)) || ((!p5.isDirectory()) || (java.nio.file.Files.isSymbolicLink(p5.toPath())))) {
            throw com.personal.aihub.CpkWriter.error("Invalid imported asset key.");
        } else {
            String v6_1 = p6.split("/");
            long v0_2 = v6_1.length;
            int v1 = 0;
            java.io.File v2_0 = p5;
            while (v1 < v0_2) {
                java.io.File v3_1 = new java.io.File(v2_0, v6_1[v1]);
                if (java.nio.file.Files.isSymbolicLink(v3_1.toPath())) {
                    throw com.personal.aihub.CpkWriter.error("Imported assets cannot use symbolic links.");
                } else {
                    v1++;
                    v2_0 = v3_1;
                }
            }
            if (v2_0.isFile()) {
                String v6_3 = v2_0.getCanonicalPath();
                long v0_4 = new StringBuilder();
                v0_4.append(String.valueOf(p5.getCanonicalPath()));
                v0_4.append(java.io.File.separator);
                if ((v6_3.startsWith(v0_4.toString())) && (v2_0.length() <= 167772160)) {
                    return v2_0;
                }
            }
            throw com.personal.aihub.CpkWriter.error("Missing or oversized imported asset.");
        }
    }

    private static byte[] toc(java.util.List p21)
    {
        byte[] v0_1 = new java.util.ArrayList();
        int v2_0 = 0;
        while (v2_0 < p21.size()) {
            java.util.Map v4_2 = ((com.personal.aihub.CpkWriter$Source) p21.get(v2_0));
            long v5_4 = v4_2.path.lastIndexOf(47);
            if (v5_4 >= 0) {
                v4_2.path.substring(0, v5_4);
            }
            v4_2.path.substring((v5_4 + 1));
            Long.valueOf(v4_2.size);
            Long.valueOf(v4_2.size);
            Long.valueOf((v4_2.offset - 2048));
            Integer.valueOf(v2_0);
            String v19 = "UserString";
            String v11 = "FileSize";
            String v15 = "FileOffset";
            v0_1.add(com.personal.aihub.CpkWriter.row(new Object[] {"DirName", ""})));
            v2_0++;
        }
        int v2_2 = new com.personal.aihub.CpkWriter$Col[7];
        v2_2[0] = com.personal.aihub.CpkWriter.c("DirName", 10);
        v2_2[1] = com.personal.aihub.CpkWriter.c("FileName", 10);
        v2_2[2] = com.personal.aihub.CpkWriter.c("FileSize", 4);
        v2_2[3] = com.personal.aihub.CpkWriter.c("ExtractSize", 4);
        v2_2[4] = com.personal.aihub.CpkWriter.c("FileOffset", 6);
        v2_2[5] = com.personal.aihub.CpkWriter.c("ID", 4);
        v2_2[6] = com.personal.aihub.CpkWriter.c("UserString", 10);
        return com.personal.aihub.CpkWriter.packet("TOC ", com.personal.aihub.CpkWriter.utf("CpkTocInfo", v2_2, v0_1));
    }

    private static byte[] utf(String p16, com.personal.aihub.CpkWriter$Col[] p17, java.util.List p18)
    {
        java.io.ByteArrayOutputStream v1_1 = new java.io.ByteArrayOutputStream();
        v1_1.write("<NULL>\u0000".getBytes(java.nio.charset.StandardCharsets.US_ASCII));
        java.util.LinkedHashMap v2_3 = new java.util.LinkedHashMap();
        java.util.Iterator v3_3 = new com.personal.aihub.CpkWriter$1(v2_3, v1_1);
        v3_3.apply("");
        java.util.Map v4_9 = ((Integer) v3_3.apply(p16)).intValue();
        int v5_6 = p17.length;
        int v7_7 = 0;
        while (v7_7 < v5_6) {
            v3_3.apply(p17[v7_7].name);
            v7_7++;
        }
        int v5_7 = p18.iterator();
        while (v5_7.hasNext()) {
            int v7_5 = v5_7.next();
            int v9_0 = p17.length;
            int v10_0 = 0;
            while (v10_0 < v9_0) {
                int v11_9 = p17[v10_0];
                if (v11_9.type == 10) {
                    v3_3.apply(String.valueOf(((java.util.Map) v7_5).get(v11_9.name)));
                }
                v10_0++;
            }
        }
        int v5_8 = 0;
        int v7_9 = 0;
        while(true) {
            int v10_1 = 2;
            if (v5_8 >= p17.length) {
                break;
            }
            Number v12_6 = p17[v5_8];
            if (v12_6.type != 6) {
                if (v12_6.type != 2) {
                    v10_1 = 4;
                }
            } else {
                v10_1 = 8;
            }
            v7_9 += v10_1;
            v5_8++;
        }
        java.util.Iterator v3_7 = (p17.length * 5);
        Number v12_9 = ((p18.size() * v7_9) + (v3_7 + 32));
        int v5_11 = (v1_1.size() + v12_9);
        if (v5_11 > 33554432) {
            throw com.personal.aihub.CpkWriter.error("Metadata exceeds32MB.");
        } else {
            java.nio.ByteBuffer v13_6 = java.nio.ByteBuffer.allocate((((v5_11 + 7) / 8) * 8)).order(java.nio.ByteOrder.BIG_ENDIAN);
            v13_6.put("@UTF".getBytes(java.nio.charset.StandardCharsets.US_ASCII)).putInt((v13_6.capacity() - 8)).putInt((v3_7 + 24)).putInt((v12_9 - 8)).putInt((v5_11 - 8)).putInt(v4_9).putShort(((short) p17.length)).putShort(((short) v7_9)).putInt(p18.size());
            java.util.Iterator v3_1 = p17.length;
            java.util.Map v4_1 = 0;
            while (v4_1 < v3_1) {
                int v5_1 = p17[v4_1];
                v13_6.put(((byte) (v5_1.type | 80))).putInt(((Integer) v2_3.get(v5_1.name)).intValue());
                v4_1++;
            }
            java.util.Iterator v3_2 = p18.iterator();
            while (v3_2.hasNext()) {
                java.util.Map v4_4 = ((java.util.Map) v3_2.next());
                int v5_0 = p17.length;
                int v7_0 = 0;
                while (v7_0 < v5_0) {
                    int v11_0 = p17[v7_0];
                    Number v12_1 = v4_4.get(v11_0.name);
                    if (v11_0.type != 10) {
                        if (v11_0.type != 6) {
                            if (v11_0.type != 2) {
                                v13_6.putInt(((Number) v12_1).intValue());
                            } else {
                                v13_6.putShort(((Number) v12_1).shortValue());
                            }
                        } else {
                            v13_6.putLong(((Number) v12_1).longValue());
                        }
                    } else {
                        v13_6.putInt(((Integer) v2_3.get(String.valueOf(v12_1))).intValue());
                    }
                    v7_0++;
                }
            }
            v13_6.put(v1_1.toByteArray());
            return v13_6.array();
        }
    }

    public static void write(java.io.File p21, java.util.List p22, java.io.File p23)
    {
        if ((p22 == null) || ((p22.isEmpty()) || (p22.size() > 5000))) {
            throw com.personal.aihub.CpkWriter.error("Choose1\u20135000 files.");
        } else {
            Throwable v1_2 = new java.util.ArrayList();
            int v2_7 = new java.util.HashSet();
            byte[] v3_2 = p22.iterator();
            long v13_6 = 0;
            while (v3_2.hasNext()) {
                int v6_3 = ((com.personal.aihub.CpkWriter$Entry) v3_2.next());
                if ((v6_3 == 0) || (!com.personal.aihub.CpkWriter.safe(v6_3.path))) {
                    throw com.personal.aihub.CpkWriter.error("Unsafe archive path.");
                } else {
                    java.io.OutputStream v7_5 = java.text.Normalizer.normalize(v6_3.path, java.text.Normalizer$Form.NFC);
                    if (!v2_7.add(v7_5.toLowerCase(java.util.Locale.ROOT))) {
                        throw com.personal.aihub.CpkWriter.error("Duplicate archive path.");
                    } else {
                        java.io.File v18 = com.personal.aihub.CpkWriter.source(p21, v6_3.assetKey);
                        long v19_2 = v18.length();
                        if (v19_2 > (536870912 - v13_6)) {
                            throw com.personal.aihub.CpkWriter.error("Archive exceeds512MB.");
                        } else {
                            v13_6 += v19_2;
                            long v8_15 = new com.personal.aihub.CpkWriter$Source;
                            v8_15(v7_5, v6_3.assetKey, v18, v19_2);
                            v1_2.add(v8_15);
                        }
                    }
                }
            }
            v1_2.sort(new com.personal.aihub.CpkWriter$2());
            int v2_21 = com.personal.aihub.CpkWriter.align(((long) (com.personal.aihub.CpkWriter.toc(v1_2).length + 2048)));
            int v10_0 = ((long) v2_21);
            int v6_6 = v1_2.iterator();
            java.io.OutputStream v7_1 = v10_0;
            while (v6_6.hasNext()) {
                String v9_4 = ((com.personal.aihub.CpkWriter$Source) v6_6.next());
                v9_4.offset = v7_1;
                v7_1 = ((long) com.personal.aihub.CpkWriter.align((v7_1 + v9_4.size)));
            }
            long v4_7 = com.personal.aihub.CpkWriter.toc(v1_2);
            long v19_1 = v10_0;
            java.io.File v5_6 = com.personal.aihub.CpkWriter.header(v10_0, (v7_1 - v10_0), ((long) v4_7.length), v1_2.size(), v13_6);
            if (v5_6.length > 2048) {
                throw com.personal.aihub.CpkWriter.error("Header exceeds alignment.");
            } else {
                if ((p23.exists()) || ((java.nio.file.Files.isSymbolicLink(p23.toPath())) || ((p23.getParentFile() == null) || ((!p23.getParentFile().isDirectory()) || (java.nio.file.Files.isSymbolicLink(p23.getParentFile().toPath())))))) {
                    throw com.personal.aihub.CpkWriter.error("Invalid archive output.");
                } else {
                    int v6_0 = 0;
                    try {
                        java.io.OutputStream v7_6 = p23.toPath();
                        long v8_18 = new java.nio.file.OpenOption[2];
                        v8_18[0] = java.nio.file.StandardOpenOption.CREATE_NEW;
                        v8_18[1] = java.nio.file.StandardOpenOption.WRITE;
                        java.io.OutputStream v7_7 = java.nio.file.Files.newOutputStream(v7_6, v8_18);
                        try {
                            v7_7.write(v5_6);
                            com.personal.aihub.CpkWriter.padding(v7_7, ((long) (2048 - v5_6.length)));
                            v7_7.write(v4_7);
                            com.personal.aihub.CpkWriter.padding(v7_7, ((long) ((v2_21 - 2048) - v4_7.length)));
                            int v2_3 = 65536;
                            byte[] v3_1 = new byte[65536];
                            Throwable v1_0 = v1_2.iterator();
                        } catch (Throwable v0_9) {
                            v6_0 = 1;
                            if (v6_0 != 0) {
                                java.nio.file.Files.deleteIfExists(p23.toPath());
                            }
                            throw v0_9;
                        } catch (Throwable v0_7) {
                            Throwable v1_4 = v0_7;
                            if (v7_7 != null) {
                                try {
                                    v7_7.close();
                                } catch (Throwable v0_8) {
                                    v1_4.addSuppressed(v0_8);
                                }
                            }
                            throw v1_4;
                        }
                        while (v1_0.hasNext()) {
                            long v4_2 = ((com.personal.aihub.CpkWriter$Source) v1_0.next());
                            java.io.File v5_3 = com.personal.aihub.CpkWriter.source(p21, v4_2.key);
                            if ((!v5_3.getCanonicalPath().equals(v4_2.file.getCanonicalPath())) || (v5_3.length() != v4_2.size)) {
                                throw com.personal.aihub.CpkWriter.error("Asset changed during export.");
                            } else {
                                long v8_5 = new java.io.FileInputStream(v5_3);
                                long v11_1 = 0;
                                try {
                                    while (v11_1 < v4_2.size) {
                                        int v2_13 = v8_5.read(v3_1, 0, ((int) Math.min(((long) v2_3), (v4_2.size - v11_1))));
                                        if (v2_13 <= 0) {
                                            throw com.personal.aihub.CpkWriter.error("Asset changed during export.");
                                        } else {
                                            v7_7.write(v3_1, 0, v2_13);
                                            v11_1 += ((long) v2_13);
                                            v2_3 = 65536;
                                        }
                                    }
                                } catch (Throwable v0_5) {
                                    Throwable v1_3 = v0_5;
                                    try {
                                        v8_5.close();
                                    } catch (Throwable v0_6) {
                                        v1_3.addSuppressed(v0_6);
                                    }
                                    throw v1_3;
                                }
                                if ((v8_5.read() != -1) || (v5_3.length() != v4_2.size)) {
                                    throw com.personal.aihub.CpkWriter.error("Asset changed during export.");
                                } else {
                                    v8_5.close();
                                    long v19_0 = (v19_1 + v4_2.size);
                                    long v4_4 = ((long) com.personal.aihub.CpkWriter.align(v19_0));
                                    com.personal.aihub.CpkWriter.padding(v7_7, (v4_4 - v19_0));
                                    v19_1 = v4_4;
                                    v2_3 = 65536;
                                }
                            }
                        }
                        if (v7_7 != null) {
                            v7_7.close();
                        }
                        return;
                    } catch (Throwable v0_9) {
                    }
                }
            }
        }
    }

    public static void write(java.io.File p6, org.json.JSONArray p7, java.io.File p8)
    {
        java.util.ArrayList v0_1 = new java.util.ArrayList();
        if (p7.length() > 5000) {
            throw com.personal.aihub.CpkWriter.error("Too many files.");
        } else {
            int v1_0 = 0;
            while (v1_0 < p7.length()) {
                String v2_1 = p7.getJSONObject(v1_0);
                v0_1.add(new com.personal.aihub.CpkWriter$Entry(v2_1.getString("path"), v2_1.getString("assetKey")));
                v1_0++;
            }
            com.personal.aihub.CpkWriter.write(p6, v0_1, p8);
            return;
        }
    }
}
