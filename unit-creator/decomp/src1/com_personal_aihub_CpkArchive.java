package com.personal.aihub;
public final class CpkArchive {
    public static final int MAX_FILES = 10000;
    public static final int MAX_FILE_BYTES = 167772160;
    public static final int MAX_METADATA_BYTES = 33554432;
    public static final long MAX_TOTAL_BYTES = 2147483648;
    public final java.util.List entries;
    private final java.io.File file;
    public final long totalBytes;

    public CpkArchive(java.io.File p28)
    {
        com.personal.aihub.CpkArchive v27_1 = ;
this.file = p28;
        java.io.IOException v2_2 = new java.util.ArrayList();
        Throwable v3_2 = new java.io.RandomAccessFile(p28, "r");
        try {
            java.io.IOException v0_2 = com.personal.aihub.CpkArchive.packet(v3_2, 0, "CPK ");
        } catch (java.io.IOException v0_1) {
            java.io.IOException v2_0 = v0_1;
            try {
                v3_2.close();
            } catch (java.io.IOException v0_17) {
                v2_0.addSuppressed(v0_17);
            }
            throw v2_0;
        }
        if (v0_2.size() != 1) {
            throw com.personal.aihub.CpkArchive.error("Invalid archive header");
        } else {
            java.io.IOException v0_19 = ((java.util.Map) v0_2.get(0));
            long v6_3 = com.personal.aihub.CpkArchive.number(v0_19, "TocOffset");
            long v8_1 = com.personal.aihub.CpkArchive.number(v0_19, "ContentOffset");
            if (v6_3 == 0) {
                throw com.personal.aihub.CpkArchive.error("Archive has no named TOC; an external name map is required");
            } else {
                java.util.Iterator v10_7 = com.personal.aihub.CpkArchive.packet(v3_2, v6_3, "TOC ");
                if (((long) v10_7.size()) != com.personal.aihub.CpkArchive.number(v0_19, "Files")) {
                    throw com.personal.aihub.CpkArchive.error("Archive file count does not match TOC");
                } else {
                    long v6_4 = Math.min(v8_1, v6_3);
                    java.io.IOException v0_16 = new java.util.HashSet();
                    java.util.Iterator v10_4 = v10_7.iterator();
                    long v11_0 = 0;
                    while (v10_4.hasNext()) {
                        try {
                            int v13_5 = ((java.util.Map) v10_4.next());
                            int v14_3 = v13_5.get("FileName");
                            String v15_1 = v13_5.get("DirName");
                        } catch (java.io.IOException v0_1) {
                        }
                        if ((v14_3 instanceof String)) {
                            java.util.Iterator v28_1;
                            if ((v15_1 instanceof String)) {
                                v28_1 = v10_4;
                            } else {
                                v28_1 = v10_4;
                                if (!Long.valueOf(0).equals(v15_1)) {
                                    throw com.personal.aihub.CpkArchive.error("Invalid file name");
                                }
                            }
                            String v15_2;
                            String v16 = "";
                            if (!(v15_1 instanceof String)) {
                                v15_2 = "";
                            } else {
                                v15_2 = ((String) v15_1);
                            }
                            java.util.Iterator v10_1 = new StringBuilder();
                            if (!v15_2.isEmpty()) {
                                if (!v15_2.equals("<NULL>")) {
                                    long v4_4 = new StringBuilder();
                                    v4_4.append(v15_2);
                                    v4_4.append("/");
                                    v16 = v4_4.toString();
                                } else {
                                }
                            }
                            v10_1.append(v16);
                            v10_1.append(v14_3);
                            long v4_6 = v10_1.toString();
                            if (!com.personal.aihub.CpkArchive.safePath(v4_6)) {
                                throw com.personal.aihub.CpkArchive.error("Unsafe entry path");
                            } else {
                                if (!v0_16.add(java.text.Normalizer.normalize(v4_6, java.text.Normalizer$Form.NFC).toLowerCase(java.util.Locale.ROOT))) {
                                    throw com.personal.aihub.CpkArchive.error("Duplicate entry path");
                                } else {
                                    int v14_0 = com.personal.aihub.CpkArchive.number(v13_5, "FileSize");
                                    java.util.Iterator v10_3 = v0_16;
                                    java.io.IOException v0_7 = com.personal.aihub.CpkArchive.number(v13_5, "ExtractSize");
                                    com.personal.aihub.CpkArchive$Entry v18_0 = com.personal.aihub.CpkArchive.number(v13_5, "FileOffset");
                                    if ((v14_0 > 167772160) || ((v0_7 > 167772160) || (v0_7 > (2147483648 - v11_0)))) {
                                        throw com.personal.aihub.CpkArchive.error("Extracted data exceeds limit");
                                    } else {
                                        if (v18_0 > (9223372036854775807 - v6_4)) {
                                            throw com.personal.aihub.CpkArchive.error("Invalid file offset");
                                        } else {
                                            long v25 = (v18_0 + v6_4);
                                            com.personal.aihub.CpkArchive.range(v25, v14_0, v3_2.length(), "file contents");
                                            if (v25 < v8_1) {
                                                throw com.personal.aihub.CpkArchive.error("File overlaps archive metadata");
                                            } else {
                                                com.personal.aihub.CpkArchive$Entry v5_14 = new com.personal.aihub.CpkArchive$Entry;
                                                v5_14(v4_6, v25, ((int) v14_0), ((int) v0_7));
                                                v2_2.add(v5_14);
                                                v11_0 += v0_7;
                                                com.personal.aihub.CpkArchive v1 = v27_1;
                                                v0_16 = v10_3;
                                                v10_4 = v28_1;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    v3_2.close();
                    com.personal.aihub.CpkArchive v1_1 = v27_1;
                    v1_1.entries = java.util.Collections.unmodifiableList(v2_2);
                    v1_1.totalBytes = v11_0;
                    return;
                }
            }
        }
    }

    public static byte[] decodeCriLayla(byte[] p16, int p17)
    {
        if ((p16.length < 272) || (!new String(p16, 0, 8, java.nio.charset.StandardCharsets.US_ASCII).equals("CRILAYLA"))) {
            throw com.personal.aihub.CpkArchive.error("Unsupported compressed entry");
        } else {
            int v1_5 = java.nio.ByteBuffer.wrap(p16).order(java.nio.ByteOrder.LITTLE_ENDIAN);
            long v5_2 = ((((long) v1_5.getInt(8)) & 4294967295) + 256);
            int v1_8 = (((long) v1_5.getInt(12)) & 4294967295);
            if ((v5_2 > 167772160) || (v5_2 != ((long) p17))) {
                throw com.personal.aihub.CpkArchive.error("Compressed output size does not match file table");
            } else {
                com.personal.aihub.CpkArchive$Bits v7_7 = (16 + v1_8);
                com.personal.aihub.CpkArchive.range(v7_7, 256, ((long) p16.length), "CRILAYLA header");
                if ((272 + v1_8) != ((long) p16.length)) {
                    throw com.personal.aihub.CpkArchive.error("Unexpected trailing CRILAYLA data");
                } else {
                    int v9_7 = ((int) v5_2);
                    byte[] v10 = new byte[v9_7];
                    System.arraycopy(p16, ((int) v7_7), v10, 0, 256);
                    com.personal.aihub.CpkArchive$Bits v7_10 = new com.personal.aihub.CpkArchive$Bits(p16, ((int) (v1_8 + 15)));
                    int v9_0 = (v9_7 - 1);
                    while (v9_0 >= 256) {
                        if (v7_10.take(1) != 0) {
                            int v2_0 = 3;
                            int v1_16 = (v7_10.take(13) + 3);
                            int v12_3 = 0;
                            while (v12_3 < 4) {
                                int v13_2 = new int[] {2, 3, 5, 8})[v12_3];
                                int v14 = v7_10.take(v13_2);
                                v2_0 += v14;
                                if (v14 == ((1 << v13_2) - 1)) {
                                    v12_3++;
                                } else {
                                    int v11_0 = 0;
                                }
                                if (v11_0 != 0) {
                                    do {
                                        int v11_1 = v7_10.take(8);
                                        v2_0 += v11_1;
                                        if (v2_0 > (v9_0 + -255)) {
                                            throw com.personal.aihub.CpkArchive.error("CRILAYLA match exceeds output");
                                        } else {
                                        }
                                    } while(v11_1 == 255);
                                }
                                if ((v2_0 > (v9_0 + -255)) || (((long) (v9_0 + v1_16)) >= v5_2)) {
                                    throw com.personal.aihub.CpkArchive.error("Invalid CRILAYLA back-reference");
                                }
                                while(true) {
                                    int v11_6 = (v2_0 - 1);
                                    if (v2_0 <= 0) {
                                        break;
                                    }
                                    v10[v9_0] = v10[(v9_0 + v1_16)];
                                    v9_0--;
                                    v2_0 = v11_6;
                                }
                            }
                            v11_0 = 1;
                        } else {
                            v10[v9_0] = ((byte) v7_10.take(8));
                            v9_0--;
                        }
                    }
                    return v10;
                }
            }
        }
    }

    public static java.io.IOException error(String p3)
    {
        StringBuilder v1_1 = new StringBuilder("CPK: ");
        v1_1.append(p3);
        return new java.io.IOException(v1_1.toString());
    }

    private static long number(java.util.Map p4, String p5)
    {
        long v4_1 = p4.get(p5);
        if ((v4_1 instanceof Long)) {
            long v4_7 = ((Long) v4_1);
            if (v4_7.longValue() >= 0) {
                return v4_7.longValue();
            }
        }
        long v4_3 = new StringBuilder("Invalid ");
        v4_3.append(p5);
        throw com.personal.aihub.CpkArchive.error(v4_3.toString());
    }

    private static java.util.List packet(java.io.RandomAccessFile p5, long p6, String p8)
    {
        long v0_1 = com.personal.aihub.CpkArchive.read(p5, p6, 16);
        if (!new String(v0_1, 0, 4, java.nio.charset.StandardCharsets.US_ASCII).equals(p8)) {
            java.io.IOException v5_2 = new StringBuilder("Invalid ");
            v5_2.append(p8);
            v5_2.append(" packet");
            throw com.personal.aihub.CpkArchive.error(v5_2.toString());
        } else {
            long v0_2 = com.personal.aihub.CpkArchive.u64(v0_1, 8, 1);
            if (v0_2 > 33554432) {
                throw com.personal.aihub.CpkArchive.error("Metadata exceeds limit");
            } else {
                return com.personal.aihub.CpkArchive.utf(com.personal.aihub.CpkArchive.read(p5, (p6 + 16), ((int) v0_2)));
            }
        }
    }

    public static void range(long p3, long p5, long p7, String p9)
    {
        if ((p3 < 0) || ((p5 < 0) || ((p3 > p7) || (p5 > (p7 - p3))))) {
            long v3_2 = new StringBuilder("Truncated or invalid ");
            v3_2.append(p9);
            throw com.personal.aihub.CpkArchive.error(v3_2.toString());
        } else {
            return;
        }
    }

    private static byte[] read(java.io.RandomAccessFile p7, long p8, int p10)
    {
        com.personal.aihub.CpkArchive.range(p8, ((long) p10), p7.length(), "archive range");
        byte[] v10_1 = new byte[p10];
        p7.seek(p8);
        p7.readFully(v10_1);
        return v10_1;
    }

    public static boolean safePath(String p7)
    {
        if ((p7 == 0) || ((p7.isEmpty()) || ((p7.length() > 500) || (p7.startsWith("/"))))) {
            return 0;
        } else {
            int v2_1 = p7.toCharArray();
            String v4_0 = 0;
            while (v4_0 < v2_1.length) {
                char v5 = v2_1[v4_0];
                if ((v5 != 92) && ((v5 != 58) && ((v5 >= 32) && (v5 != 127)))) {
                    v4_0++;
                } else {
                    return 0;
                }
            }
            int v7_1 = p7.split("/", -1);
            int v2_3 = 0;
            while (v2_3 < v7_1.length) {
                boolean v3_1 = v7_1[v2_3];
                if ((!v3_1.isEmpty()) && ((!v3_1.equals(".")) && (!v3_1.equals("..")))) {
                    v2_3++;
                } else {
                    return 0;
                }
            }
            return 1;
        }
    }

    public static long u64(byte[] p7, int p8, boolean p9)
    {
        com.personal.aihub.CpkArchive.range(((long) p8), 8, ((long) p7.length), "64-bit value");
        long v0_2 = 0;
        int v2_1 = 0;
        while (v2_1 < 8) {
            int v5_0;
            if (!p9) {
                v5_0 = (p8 + v2_1);
            } else {
                v5_0 = ((p8 + 7) - v2_1);
            }
            int v5_3 = (p7[v5_0] & 255);
            if ((v2_1 == 0) && (v5_3 > 0)) {
                throw com.personal.aihub.CpkArchive.error("64-bit value exceeds safe range");
            } else {
                v0_2 = ((v0_2 << 8) | ((long) v5_3));
                v2_1++;
            }
        }
        if (v0_2 > 9007199254740991) {
            throw com.personal.aihub.CpkArchive.error("64-bit value exceeds safe range");
        } else {
            return v0_2;
        }
    }

    static java.util.List utf(byte[] p22)
    {
        java.io.IOException v0_5 = new com.personal.aihub.CpkArchive$Table(p22);
        java.util.ArrayList v1_5 = (v0_5.be.getShort(24) & 65535);
        int v2_0 = (65535 & v0_5.be.getShort(26));
        long v3_2 = v0_5.u32(28);
        if ((v1_5 > 512) || (v3_2 > 10000)) {
            throw com.personal.aihub.CpkArchive.error("Invalid table layout");
        } else {
            com.personal.aihub.CpkArchive.range(((long) v0_5.rows), (((long) v2_0) * v3_2), ((long) v0_5.strings), "UTF rows");
            v0_5.string(v0_5.u32(20));
            int v6_1 = new int[12];
            v6_1 = {1, 1, 2, 2, 4, 4, 8, 8, 4, 8, 4, 8};
            java.util.ArrayList v7_1 = new java.util.ArrayList();
            java.util.Iterator v8_3 = new java.util.HashSet();
            Object v10_0 = 32;
            String v11_0 = 0;
            Object v12_0 = 0;
            while (v11_0 < v1_5) {
                int v21_1 = v6_1;
                com.personal.aihub.CpkArchive.range(((long) v10_0), 5, ((long) v0_5.rows), "UTF columns");
                int v5_1 = v0_5.b[v10_0];
                int v6_0 = (v5_1 & 15);
                int v5_2 = (v5_1 & 240);
                int v9_1 = v0_5.string(v0_5.u32((v10_0 + 1)));
                v10_0 += 5;
                if (!v8_3.add(v9_1)) {
                    throw com.personal.aihub.CpkArchive.error("Duplicate UTF column");
                } else {
                    if ((v6_0 >= 12) || ((v5_2 != 16) && ((v5_2 != 48) && (v5_2 != 80)))) {
                        throw com.personal.aihub.CpkArchive.error("Unsupported UTF storage");
                    } else {
                        int v15_2 = Long.valueOf(0);
                        if (v5_2 == 48) {
                            v15_2 = v0_5.value(v6_0, v10_0, v0_5.rows);
                            v10_0 += v21_1[v6_0];
                        }
                        if (v5_2 == 80) {
                            v12_0 += v21_1[v6_0];
                        }
                        v7_1.add(new com.personal.aihub.CpkArchive$Column(v9_1, v6_0, v5_2, v15_2));
                        v11_0++;
                        v6_1 = v21_1;
                    }
                }
            }
            int v21_0 = v6_1;
            if (v12_0 > v2_0) {
                throw com.personal.aihub.CpkArchive.error("UTF row size does not match columns");
            } else {
                java.util.ArrayList v1_3 = new java.util.ArrayList();
                int v9_2 = 0;
                while (v9_2 < ((int) v3_2)) {
                    int v5_13 = (v0_5.rows + (v9_2 * v2_0));
                    int v6_5 = new java.util.HashMap();
                    java.util.Iterator v8_4 = v7_1.iterator();
                    while (v8_4.hasNext()) {
                        Object v10_4 = ((com.personal.aihub.CpkArchive$Column) v8_4.next());
                        if (v10_4.storage != 80) {
                            v6_5.put(v10_4.name, v10_4.constant);
                        } else {
                            v6_5.put(v10_4.name, v0_5.value(v10_4.type, v5_13, (v0_5.rows + ((v9_2 + 1) * v2_0))));
                            v5_13 += v21_0[v10_4.type];
                        }
                    }
                    v1_3.add(v6_5);
                    v9_2++;
                }
                return v1_3;
            }
        }
    }

    public byte[] read(com.personal.aihub.CpkArchive$Entry p7)
    {
        if ((p7.size < 0) || ((p7.size > 167772160) || ((p7.storedSize < 0) || (p7.storedSize > 167772160)))) {
            throw com.personal.aihub.CpkArchive.error("Entry exceeds limit");
        } else {
            Throwable v0_2 = new java.io.RandomAccessFile(this.file, "r");
            try {
                byte[] v1_2 = com.personal.aihub.CpkArchive.read(v0_2, p7.offset, p7.storedSize);
            } catch (java.io.IOException v7_5) {
                try {
                    v0_2.close();
                } catch (Throwable v0_4) {
                    v7_5.addSuppressed(v0_4);
                }
                throw v7_5;
            }
            if ((v1_2.length < 8) || (!new String(v1_2, 0, 8, java.nio.charset.StandardCharsets.US_ASCII).equals("CRILAYLA"))) {
                if (p7.size != p7.storedSize) {
                    throw com.personal.aihub.CpkArchive.error("Unsupported compression format");
                } else {
                    v0_2.close();
                    return v1_2;
                }
            } else {
                java.io.IOException v7_7 = com.personal.aihub.CpkArchive.decodeCriLayla(v1_2, p7.size);
                v0_2.close();
                return v7_7;
            }
        }
    }
}
