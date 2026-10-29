package com.personal.aihub;
public final class MovieStorage {
    public static final int CHUNK_LIMIT = 262144;
    public static final long FILE_LIMIT = 100663296;
    private static final String ID = "[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}";
    private static final String OWNER = "Dokkan Unit Forge movie uploads v1\n";
    public static final long TOTAL_LIMIT = 402653184;
    public static final long TTL = 600000;
    private final java.util.function.LongSupplier clock;
    private final java.util.Map jobs;
    private final java.io.File root;
    private final java.io.File staging;

    public MovieStorage(java.io.File p2)
    {
        this(p2, new com.personal.aihub.MovieStorage$1());
        return;
    }

    public MovieStorage(java.io.File p8, java.util.function.LongSupplier p9)
    {
        this.jobs = new java.util.LinkedHashMap();
        java.io.IOException v8_8 = p8.getAbsoluteFile();
        this.root = v8_8;
        this.clock = p9;
        int v9_1 = new java.io.File(v8_8.getParentFile(), ".forge-movie-uploads-v1");
        this.staging = v9_1;
        com.personal.aihub.MovieStorage.directories(v8_8);
        com.personal.aihub.MovieStorage.directories(v9_1.getParentFile());
        int v0_3 = 0;
        if (v9_1.mkdir()) {
            java.io.IOException v8_5 = new java.io.File(v9_1, ".owner").toPath();
            java.nio.file.LinkOption[] v3_1 = "Dokkan Unit Forge movie uploads v1\n".getBytes(java.nio.charset.StandardCharsets.UTF_8);
            long v4_1 = new java.nio.file.OpenOption[2];
            v4_1[0] = java.nio.file.StandardOpenOption.CREATE_NEW;
            v4_1[1] = java.nio.file.StandardOpenOption.WRITE;
            java.nio.file.Files.write(v8_5, v3_1, v4_1);
        }
        com.personal.aihub.MovieStorage.directories(v9_1);
        java.io.IOException v8_7 = new java.io.File(v9_1, ".owner");
        if ((java.nio.file.Files.isSymbolicLink(v8_7.toPath())) || ((!v8_7.isFile()) || ((v8_7.length() != ((long) 35)) || (!new String(java.nio.file.Files.readAllBytes(v8_7.toPath()), java.nio.charset.StandardCharsets.UTF_8).equals("Dokkan Unit Forge movie uploads v1\n"))))) {
            throw com.personal.aihub.MovieStorage.fail("The private upload folder is not owned by this app.");
        } else {
            java.io.IOException v8_14 = v9_1.listFiles();
            if (v8_14 == null) {
                throw com.personal.aihub.MovieStorage.fail("The private upload folder is unavailable.");
            } else {
                int v9_2 = v8_14.length;
                while (v0_3 < v9_2) {
                    java.nio.file.Path v1_2 = v8_14[v0_3];
                    if ((v1_2.getName().matches("upload-[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\\.part")) && (!java.nio.file.Files.isDirectory(v1_2.toPath(), new java.nio.file.LinkOption[] {java.nio.file.LinkOption.NOFOLLOW_LINKS})))) {
                        java.nio.file.Files.delete(v1_2.toPath());
                    }
                    v0_3++;
                }
                return;
            }
        }
    }

    private static void directories(java.io.File p3)
    {
        java.nio.file.Path v0_1 = p3.getAbsoluteFile().toPath().normalize().getRoot();
        java.io.IOException v3_3 = p3.getAbsoluteFile().toPath().normalize().iterator();
        while (v3_3.hasNext()) {
            v0_1 = v0_1.resolve(((java.nio.file.Path) v3_3.next()));
            boolean v1_4 = java.nio.file.Files.readAttributes(v0_1, java.nio.file.attribute.BasicFileAttributes, new java.nio.file.LinkOption[] {java.nio.file.LinkOption.NOFOLLOW_LINKS}));
            if ((!v1_4.isDirectory()) || (v1_4.isSymbolicLink())) {
                throw com.personal.aihub.MovieStorage.fail("The private movie folder is unsafe.");
            }
        }
        return;
    }

    private void discard(String p2)
    {
        this.jobs.remove(p2);
        java.nio.file.Files.deleteIfExists(this.temporary(p2).toPath());
        return;
    }

    private static java.io.IOException fail(String p3)
    {
        StringBuilder v1_1 = new StringBuilder("Movie: ");
        v1_1.append(p3);
        return new java.io.IOException(v1_1.toString());
    }

    public static org.json.JSONObject inspect(java.io.File p72)
    {
        boolean v0_0 = "stmid";
        java.io.RandomAccessFile v8_1 = new java.io.RandomAccessFile(p72, "r");
        try {
            int v9_0 = v8_1.length();
        } catch (boolean v0_1) {
            long v1_2 = v0_1;
            try {
                v8_1.close();
            } catch (boolean v0_2) {
                v1_2.addSuppressed(v0_2);
            }
            throw v1_2;
        }
        if ((v9_0 < 2048) || (v9_0 > 100663296)) {
            throw com.personal.aihub.MovieStorage.fail("Choose a complete authored movie up to 96 MB.");
        } else {
            int v13_0 = new java.util.ArrayList();
            int v14_0 = new java.util.ArrayList();
            int v15_0 = 0;
            int v4_2 = 0;
            String v5_0 = 0;
            int v6_9 = 0;
            int v7_4 = 0;
            long v1_1 = 0;
            int v20 = 0;
            int v23 = 0;
            int v24 = 0;
            int v25 = 0;
            int v26 = 0;
            int v27 = 0;
            long v2_28 = 0;
            long v18 = 0;
            long v21 = 0;
            long v28 = 0;
            long v30_0 = 0;
            long v32_0 = 0;
            long v34_1 = 0;
            long v36_2 = 0;
            long v38_2 = 0;
            while(true) {
                int v72_1 = v7_4;
                if (v18 >= v9_0) {
                    break;
                }
                long v1_19 = (v1_1 + 1);
                if (v1_19 > 70000) {
                    throw com.personal.aihub.MovieStorage.fail("The movie contains too many packets.");
                } else {
                    String v51 = v1_19;
                    long v52_0 = v2_28;
                    int v54 = v4_2;
                    int v11_2 = v5_0;
                    int v55 = v6_9;
                    long v1_21 = com.personal.aihub.MovieStorage.read(v8_1, v18, 32, v9_0);
                    long v2_25 = com.personal.aihub.MovieStorage.text(v1_21, v15_0, 4);
                    long v56_1 = (com.personal.aihub.MovieStorage.u32(v1_21, 4) + 8);
                    long v3_14 = ((long) (com.personal.aihub.MovieStorage.u16(v1_21, 8) + 8));
                    int v60 = v13_0;
                    int v12_1 = ((v56_1 - v3_14) - ((long) com.personal.aihub.MovieStorage.u16(v1_21, 10)));
                    long v58_1 = (v18 + v3_14);
                    String v5_7 = (v1_21[15] & 255);
                    if ((v56_1 >= 32) && (((v56_1 % 32) == 0) && ((v3_14 == 32) && ((v12_1 >= 0) && (v56_1 <= (v9_0 - v18)))))) {
                        int v4_4 = 12;
                        if ((v1_21[12] == 0) && ((v1_21[13] == 0) && ((v1_21[14] == 0) && (v5_7 <= 3)))) {
                            int v11_3;
                            boolean v44_0;
                            long v66;
                            int v10_3;
                            if (v18 != 0) {
                                int v7_5 = v72_1;
                                boolean v43_0 = v2_25.equals("@SFV");
                                if (!v43_0) {
                                    if (!v2_25.equals("@SFA")) {
                                        throw com.personal.aihub.MovieStorage.fail("Unsupported movie stream.");
                                    } else {
                                    }
                                }
                                String v65;
                                if (v5_7 != 1) {
                                    v66 = v9_0;
                                    long v1_28 = v12_1;
                                    v65 = v14_0;
                                    int v12_2 = v54;
                                    v44_0 = v0_0;
                                    int v13_2 = v7_5;
                                    long v45_0 = v11_2;
                                    int v10_2 = v52_0;
                                    if (v5_7 != 3) {
                                        int v7_7 = v55;
                                        if (v5_7 != 2) {
                                            if (!v43_0) {
                                                boolean v0 = 12;
                                                String v5_8 = v1_28;
                                                if ((v12_2 == 0) || ((v23 == 0) || ((v25 != 0) || ((v27 != 0) || (v5_8 < 1))))) {
                                                    throw com.personal.aihub.MovieStorage.fail("Incomplete ADX packet.");
                                                } else {
                                                    long v52_1 = v10_2;
                                                    v10_3 = v65;
                                                    v11_3 = v60;
                                                    long v58_2 = v5_8;
                                                    boolean v0_26 = com.personal.aihub.MovieStorage.read(v8_1, v58_1, ((int) Math.min(v5_8, 4096)), v66);
                                                    if (v28 != 0) {
                                                        if ((v58_2 != 18) || ((com.personal.aihub.MovieStorage.u16(v0_26, 0) != 32769) || (com.personal.aihub.MovieStorage.u16(v0_26, 2) != 14))) {
                                                            if ((v58_2 % 36) != 0) {
                                                                throw com.personal.aihub.MovieStorage.fail("ADX audio ends inside a sample block.");
                                                            } else {
                                                                v34_1 += (v58_2 / 36);
                                                            }
                                                        } else {
                                                            v27 = 1;
                                                        }
                                                    } else {
                                                        if ((v58_2 < 24) || (com.personal.aihub.MovieStorage.u16(v0_26, 0) != 32768)) {
                                                            throw com.personal.aihub.MovieStorage.fail("Invalid ADX header.");
                                                        } else {
                                                            long v1_43 = ((long) (com.personal.aihub.MovieStorage.u16(v0_26, 2) + 4));
                                                            long v3_24 = com.personal.aihub.MovieStorage.u32(v0_26, 12);
                                                            if ((v1_43 == v58_2) && ((v1_43 <= 4096) && ((v0_26[4] == 3) && ((v0_26[5] == 18) && ((v0_26[6] == 4) && ((v0_26[7] == 2) && ((com.personal.aihub.MovieStorage.u32(v0_26, 8) == 48000) && (v3_24 == com.personal.aihub.MovieStorage.n(v12_2, "total_samples"))))))))) {
                                                                String v5_25 = v0_26[18];
                                                                if (((v5_25 == 3) || (v5_25 == 4)) && ((!v0_26[19]) && (com.personal.aihub.MovieStorage.text(v0_26, (((int) v1_43) - 6), 6).equals("(c)CRI")))) {
                                                                    v36_2 = v1_43;
                                                                    v38_2 = v3_24;
                                                                    v28 += v58_2;
                                                                    v6_9 = v7_7;
                                                                    v4_2 = v12_2;
                                                                    v7_4 = v13_2;
                                                                    v5_0 = v45_0;
                                                                    v2_28 = v52_1;
                                                                    v18 += v56_1;
                                                                    v14_0 = v10_3;
                                                                    v13_0 = v11_3;
                                                                    v0_0 = v44_0;
                                                                    v1_1 = v51;
                                                                    v9_0 = v66;
                                                                    v15_0 = 0;
                                                                }
                                                            }
                                                            throw com.personal.aihub.MovieStorage.fail("Unsupported plain stereo ADX header.");
                                                        }
                                                    }
                                                }
                                            } else {
                                                if ((v13_2 == 0) || ((v24 == 0) || ((v26 == 0) || ((v20 != 0) || (v1_28 < 13))))) {
                                                    throw com.personal.aihub.MovieStorage.fail("Incomplete VP9 packet.");
                                                } else {
                                                    int v15_5;
                                                    boolean v0_41;
                                                    String v5_32;
                                                    long v41_2 = v10_2 cmp 0;
                                                    if (v41_2 != 0) {
                                                        v5_32 = v1_28;
                                                        v15_5 = 4;
                                                        v0_41 = 0;
                                                    } else {
                                                        long v68 = v1_28;
                                                        v15_5 = 4;
                                                        long v1_45 = com.personal.aihub.MovieStorage.read(v8_1, v58_1, 32, v66);
                                                        v5_32 = v68;
                                                        if ((v5_32 >= 45) && ((com.personal.aihub.MovieStorage.text(v1_45, 0, 4).equals("DKIF")) && ((com.personal.aihub.MovieStorage.le(v1_45, 4, 2) == 0) && ((com.personal.aihub.MovieStorage.le(v1_45, 6, 2) == 32) && (com.personal.aihub.MovieStorage.text(v1_45, 8, 4).equals("VP90")))))) {
                                                            v4_4 = 12;
                                                            if ((com.personal.aihub.MovieStorage.le(v1_45, 12, 2) == com.personal.aihub.MovieStorage.n(v13_2, "width")) && (com.personal.aihub.MovieStorage.le(v1_45, 14, 2) == com.personal.aihub.MovieStorage.n(v13_2, "height"))) {
                                                                long v2_42 = com.personal.aihub.MovieStorage.le(v1_45, 16, 4);
                                                                long v30_4 = com.personal.aihub.MovieStorage.le(v1_45, 20, 4);
                                                                if ((v2_42 != com.personal.aihub.MovieStorage.n(v13_2, "framerate_n")) || ((v30_4 != com.personal.aihub.MovieStorage.n(v13_2, "framerate_d")) || (com.personal.aihub.MovieStorage.le(v1_45, 24, 4) != com.personal.aihub.MovieStorage.n(v13_2, "total_frames")))) {
                                                                    throw com.personal.aihub.MovieStorage.fail("Movie frame timing differs from its metadata.");
                                                                } else {
                                                                    v0_41 = 32;
                                                                    v32_0 = v30_4;
                                                                    v30_0 = v2_42;
                                                                    long v2_43 = ((long) v0_41);
                                                                    long v52_2 = v2_43;
                                                                    int v9_4 = v4_4;
                                                                    byte[] v70 = v5_32;
                                                                    boolean v0_57 = com.personal.aihub.MovieStorage.read(v8_1, (v58_1 + v2_43), 13, v66);
                                                                    long v2_45 = com.personal.aihub.MovieStorage.le(v0_57, 0, v15_5);
                                                                    long v1_48 = v0_57[v9_4];
                                                                    if (v2_45 >= 1) {
                                                                        String v5_38 = v70;
                                                                        if ((((v2_45 + 12) + v52_2) == v5_38) && ((com.personal.aihub.MovieStorage.le(v0_57, v15_5, 8) == v10_2) && ((((v1_48 & 255) >> 6) == 2) && (((v1_48 & 48) == 0) && ((v41_2 != 0) || ((v1_48 & 12) == 0)))))) {
                                                                            int v61;
                                                                            int v4_12 = v60;
                                                                            v4_12.add(Long.valueOf(v18));
                                                                            if ((v1_48 & 12) != 0) {
                                                                                v61 = 0;
                                                                            } else {
                                                                                v61 = 1;
                                                                            }
                                                                            long v2_51 = v65;
                                                                            v2_51.add(Boolean.valueOf(v61));
                                                                            v21 += v5_38;
                                                                            v10_3 = v2_51;
                                                                            v11_3 = v4_12;
                                                                            v6_9 = v7_7;
                                                                            v4_2 = v12_2;
                                                                            v7_4 = v13_2;
                                                                            v5_0 = v45_0;
                                                                            v2_28 = (v10_2 + 1);
                                                                        }
                                                                    }
                                                                    throw com.personal.aihub.MovieStorage.fail("Invalid authored VP9 frame.");
                                                                }
                                                            }
                                                        }
                                                        throw com.personal.aihub.MovieStorage.fail("Unsupported IVF movie header.");
                                                    }
                                                }
                                            }
                                        } else {
                                            if (v1_28 > 64) {
                                                throw com.personal.aihub.MovieStorage.fail("Invalid movie marker.");
                                            } else {
                                                boolean v0_71 = ((int) v1_28);
                                                boolean v0_72 = com.personal.aihub.MovieStorage.text(com.personal.aihub.MovieStorage.read(v8_1, v58_1, v0_71, v66), 0, v0_71);
                                                if (!v0_72.equals("#HEADER END     ===============\u0000")) {
                                                    if (!v0_72.equals("#METADATA END   ===============\u0000")) {
                                                        if (!v0_72.equals("#CONTENTS END   ===============\u0000")) {
                                                            throw com.personal.aihub.MovieStorage.fail("Unsupported movie marker.");
                                                        } else {
                                                            if (!v43_0) {
                                                                if ((v27 == 0) || (v25 != 0)) {
                                                                    throw com.personal.aihub.MovieStorage.fail("Invalid audio end marker.");
                                                                } else {
                                                                    v25 = 1;
                                                                }
                                                            } else {
                                                                if ((v10_2 == 0) || (v20 != 0)) {
                                                                    throw com.personal.aihub.MovieStorage.fail("Invalid video end marker.");
                                                                } else {
                                                                    v20 = 1;
                                                                }
                                                            }
                                                        }
                                                    } else {
                                                        if ((!v43_0) || ((v7_7 == 0) || ((v7_7.isEmpty()) || ((v26 != 0) || (v10_2 > 0))))) {
                                                            throw com.personal.aihub.MovieStorage.fail("Invalid seek marker.");
                                                        } else {
                                                            v26 = 1;
                                                        }
                                                    }
                                                } else {
                                                    if (!v43_0) {
                                                        if ((v12_2 == 0) || ((v23 != 0) || (v28 > 0))) {
                                                            throw com.personal.aihub.MovieStorage.fail("Invalid audio header marker.");
                                                        } else {
                                                            v23 = 1;
                                                        }
                                                    } else {
                                                        if ((v13_2 == 0) || ((v24 != 0) || (v10_2 > 0))) {
                                                            throw com.personal.aihub.MovieStorage.fail("Invalid video header marker.");
                                                        } else {
                                                            v24 = 1;
                                                        }
                                                    }
                                                }
                                                v6_9 = v7_7;
                                            }
                                        }
                                    } else {
                                        if ((!v43_0) || ((v13_2 == 0) || ((v10_2 > 0) || ((v55 != 0) || ((com.personal.aihub.MovieStorage.n(v13_2, "metadata_size") != v56_1) || (v1_28 > 1048576)))))) {
                                            throw com.personal.aihub.MovieStorage.fail("Invalid movie seek metadata.");
                                        } else {
                                            v6_9 = com.personal.aihub.MovieStorage.utf(v8_1, v58_1, ((int) v1_28), v66, 10000);
                                        }
                                    }
                                    v2_28 = v10_2;
                                    v4_2 = v12_2;
                                    v7_4 = v13_2;
                                    v5_0 = v45_0;
                                } else {
                                    if (v12_1 > 65536) {
                                        throw com.personal.aihub.MovieStorage.fail("Movie metadata is too large.");
                                    } else {
                                        v65 = v14_0;
                                        int v13_4 = v7_5;
                                        v66 = v9_0;
                                        v44_0 = v0_0;
                                        long v1_61 = com.personal.aihub.MovieStorage.utf(v8_1, v58_1, ((int) v12_1), v9_0, 1);
                                        if (v1_61.size() != 1) {
                                            throw com.personal.aihub.MovieStorage.fail("Invalid stream metadata.");
                                        } else {
                                            long v45_3;
                                            int v10_5;
                                            v7_4 = ((java.util.Map) v1_61.get(0));
                                            if (!v43_0) {
                                                v45_3 = v11_2;
                                                v10_5 = v52_0;
                                                if ((v54 != 0) || ((v28 > 0) || ((v45_3.size() != 3) || ((com.personal.aihub.MovieStorage.n(v7_4, "audio_codec") != 2) || ((com.personal.aihub.MovieStorage.n(v7_4, "metadata_count") != 0) || ((com.personal.aihub.MovieStorage.n(v7_4, "metadata_size") != 0) || ((com.personal.aihub.MovieStorage.n(v7_4, "sampling_rate") != 48000) || ((com.personal.aihub.MovieStorage.n(v7_4, "num_channels") != 2) || (com.personal.aihub.MovieStorage.n(v7_4, "total_samples") < 1))))))))) {
                                                    throw com.personal.aihub.MovieStorage.fail("Unsupported ADX movie metadata.");
                                                } else {
                                                    v4_2 = v7_4;
                                                    v7_4 = v13_4;
                                                }
                                            } else {
                                                long v1_65 = com.personal.aihub.MovieStorage.n(v7_4, "width");
                                                long v3_41 = com.personal.aihub.MovieStorage.n(v7_4, "height");
                                                String v5_44 = com.personal.aihub.MovieStorage.n(v7_4, "total_frames");
                                                int v9_7 = com.personal.aihub.MovieStorage.n(v7_4, "framerate_n");
                                                v45_3 = v11_2;
                                                int v11_6 = com.personal.aihub.MovieStorage.n(v7_4, "framerate_d");
                                                if (v13_4 == 0) {
                                                    int v13_5 = v52_0;
                                                    if ((v13_5 <= 0) && ((com.personal.aihub.MovieStorage.n(v7_4, "mpeg_codec") == 9) && ((com.personal.aihub.MovieStorage.n(v7_4, "metadata_count") == 1) && ((com.personal.aihub.MovieStorage.n(v7_4, "metadata_size") >= 32) && ((com.personal.aihub.MovieStorage.n(v7_4, "metadata_size") <= 1048576) && ((v1_65 >= 1) && ((v3_41 >= 1) && ((v1_65 <= 4096) && ((v3_41 <= 4096) && (((v1_65 * v3_41) <= 16777216) && ((v5_44 >= 1) && ((v5_44 <= 10000) && (v11_6 >= 1))))))))))))) {
                                                        boolean v0_146 = (((double) v9_7) / ((double) v11_6));
                                                        if ((v0_146 < 4607182418800017408) || (v0_146 > 4638144666238189568)) {
                                                            throw com.personal.aihub.MovieStorage.fail("Unsupported VP9 movie metadata.");
                                                        } else {
                                                            v10_5 = v13_5;
                                                            v4_2 = v54;
                                                            v2_28 = v10_5;
                                                            v5_0 = v45_3;
                                                            v6_9 = v55;
                                                            v11_3 = v60;
                                                            v10_3 = v65;
                                                        }
                                                    }
                                                }
                                                throw com.personal.aihub.MovieStorage.fail("Unsupported VP9 movie metadata.");
                                            }
                                        }
                                    }
                                }
                            } else {
                                if ((!v2_25.equals("CRID")) || ((v5_7 != 1) || (v56_1 != 2048))) {
                                    throw com.personal.aihub.MovieStorage.fail("The movie directory is missing.");
                                } else {
                                    int v12_7 = v72_1;
                                    long v1_72 = com.personal.aihub.MovieStorage.utf(v8_1, v58_1, ((int) v12_1), v9_0, 3);
                                    if (((v1_72.size() != 2) && (v1_72.size() != 3)) || ((com.personal.aihub.MovieStorage.n(((java.util.Map) v1_72.get(0)), "filesize") != v9_0) || ((com.personal.aihub.MovieStorage.n(((java.util.Map) v1_72.get(0)), v0_0) != 0) || ((com.personal.aihub.MovieStorage.n(((java.util.Map) v1_72.get(1)), v0_0) != 1079199318) || ((v1_72.size() == 3) && (com.personal.aihub.MovieStorage.n(((java.util.Map) v1_72.get(2)), v0_0) != 1079199297)))))) {
                                        throw com.personal.aihub.MovieStorage.fail("Invalid authored movie directory.");
                                    } else {
                                        v44_0 = v0_0;
                                        v5_0 = v1_72;
                                        v66 = v9_0;
                                        v7_4 = v12_7;
                                        v10_3 = v14_0;
                                        v2_28 = v52_0;
                                        v4_2 = v54;
                                        v6_9 = v55;
                                        v11_3 = v60;
                                    }
                                }
                            }
                        }
                    }
                    throw com.personal.aihub.MovieStorage.fail("Invalid authored movie packet.");
                }
            }
            long v52_3 = v2_28;
            int v12_4 = v4_2;
            int v7_13 = v6_9;
            int v11_4 = v13_0;
            int v10_4 = v14_0;
            int v13_3 = v72_1;
            if ((v13_3 != 0) && ((v20 != 0) && (v52_3 == com.personal.aihub.MovieStorage.n(v13_3, "total_frames")))) {
                String v5_41 = v5_0;
                if ((v21 == com.personal.aihub.MovieStorage.n(((java.util.Map) v5_41.get(1)), "filesize")) && ((v7_13 != 0) && (!v7_13.isEmpty()))) {
                    if (com.personal.aihub.MovieStorage.n(((java.util.Map) v7_13.get(0)), "ofs_frmid") != 0) {
                        throw com.personal.aihub.MovieStorage.fail("The first movie seek must point to its first frame.");
                    } else {
                        int v4_1 = v7_13.iterator();
                        while (v4_1.hasNext()) {
                            int v6_7 = ((java.util.Map) v4_1.next());
                            int v14_5 = com.personal.aihub.MovieStorage.n(v6_7, "ofs_frmid");
                            if ((v14_5 >= 0) && (v14_5 < ((long) v11_4.size()))) {
                                long v2_19 = ((int) v14_5);
                                if ((((Boolean) v10_4.get(v2_19)).booleanValue()) && (((Long) v11_4.get(v2_19)).longValue() == com.personal.aihub.MovieStorage.n(v6_7, "ofs_byte"))) {
                                    long v3 = 0;
                                }
                            }
                            throw com.personal.aihub.MovieStorage.fail("Movie seek positions do not match its frames.");
                        }
                        int v10_0;
                        long v16_0;
                        if (v5_41.size() != 3) {
                            v10_0 = v30_0;
                            v16_0 = v32_0;
                        } else {
                            if ((v12_4 != 0) && ((v25 != 0) && (v27 != 0))) {
                                int v6_1 = v38_2;
                                if ((v34_1 == ((v6_1 + 31) / 32)) && ((v28 == ((v36_2 + (v34_1 * 36)) + 18)) && (v28 == com.personal.aihub.MovieStorage.n(((java.util.Map) v5_41.get(2)), "filesize")))) {
                                    int v10_1 = v32_0;
                                    int v14_1 = ((double) v10_1);
                                    v16_0 = v10_1;
                                    v10_0 = v30_0;
                                    long v3_3 = ((double) v10_0);
                                    if (Math.abs(((((double) v6_1) / 4676829883349860352) - ((((double) v52_3) * v14_1) / v3_3))) <= ((v14_1 / v3_3) + 4536770139825955493)) {
                                        int v15_1;
                                        org.json.JSONObject vtmp35 = new org.json.JSONObject().put("width", com.personal.aihub.MovieStorage.n(v13_3, "width")).put("height", com.personal.aihub.MovieStorage.n(v13_3, "height")).put("frames", v52_3).put("rate", new org.json.JSONObject().put("n", v10_0).put("d", v16_0));
                                        if (v5_41.size() != 3) {
                                            v15_1 = 0;
                                        } else {
                                            v15_1 = 1;
                                        }
                                        boolean v0_12 = vtmp35.put("preservedAudio", v15_1);
                                        v8_1.close();
                                        return v0_12;
                                    }
                                }
                            }
                            throw com.personal.aihub.MovieStorage.fail("The movie ends before its declared audio content.");
                        }
                    }
                }
            }
            throw com.personal.aihub.MovieStorage.fail("The movie ends before its declared video content.");
        }
    }

    private static boolean integer(Object p6)
    {
        int v1 = 0;
        if (((p6 instanceof Number)) && ((!(p6 instanceof Boolean)) && ((Double.isFinite(((Number) p6).doubleValue())) && (((Number) p6).doubleValue() == ((double) ((Number) p6).longValue()))))) {
            v1 = 1;
        }
        return v1;
    }

    private static long le(byte[] p4, int p5, int p6)
    {
        int v6_1 = (p6 - 1);
        long v0_0 = 0;
        while (v6_1 >= 0) {
            if (v0_0 > 35184372088831) {
                throw com.personal.aihub.MovieStorage.fail("Invalid movie number.");
            } else {
                v0_0 = ((v0_0 * 256) + ((long) (p4[(p5 + v6_1)] & 255)));
                v6_1--;
            }
        }
        return v0_0;
    }

    private static long n(java.util.Map p4, String p5)
    {
        long v4_1 = p4.get(p5);
        if ((v4_1 instanceof Number)) {
            long v4_5 = ((Number) v4_1);
            if (v4_5.doubleValue() == ((double) v4_5.longValue())) {
                return v4_5.longValue();
            }
        }
        throw com.personal.aihub.MovieStorage.fail("Invalid movie metadata.");
    }

    private static byte[] read(java.io.RandomAccessFile p2, long p3, int p5, long p6)
    {
        if ((p3 < 0) || ((p5 < null) || ((p5 > 1048576) || ((p3 > p6) || (((long) p5) > (p6 - p3)))))) {
            throw com.personal.aihub.MovieStorage.fail("The movie contains a truncated or oversized packet.");
        } else {
            byte[] v5_1 = new byte[p5];
            p2.seek(p3);
            p2.readFully(v5_1);
            return v5_1;
        }
    }

    private java.io.File temporary(String p5)
    {
        java.io.File v1 = this.staging;
        StringBuilder v2_1 = new StringBuilder("upload-");
        v2_1.append(p5);
        v2_1.append(".part");
        return new java.io.File(v1, v2_1.toString());
    }

    private static String text(byte[] p2, int p3, int p4)
    {
        return new String(p2, p3, p4, java.nio.charset.StandardCharsets.US_ASCII);
    }

    private static int u16(byte[] p1, int p2)
    {
        return (((p1[p2] & 255) << 8) | (p1[(p2 + 1)] & 255));
    }

    private static long u32(byte[] p7, int p8)
    {
        return (((((long) p7[(p8 + 2)]) & 255) << 8) | (((((long) p7[(p8 + 3)]) & 255) | ((((long) p7[p8]) & 255) << 24)) | ((((long) p7[(p8 + 1)]) & 255) << 16)));
    }

    private static java.util.List utf(java.io.RandomAccessFile p0, long p1, int p3, long p4, int p6)
    {
        java.util.List v0_1 = com.personal.aihub.MovieStorage.read(p0, p1, p3, p4);
        if ((v0_1.length < 32) || ((!com.personal.aihub.MovieStorage.text(v0_1, 0, 4).equals("@UTF")) || (com.personal.aihub.MovieStorage.u32(v0_1, 28) > ((long) p6)))) {
            throw com.personal.aihub.MovieStorage.fail("Invalid authored movie metadata.");
        } else {
            return com.personal.aihub.CpkArchive.utf(v0_1);
        }
    }

    public declared_synchronized org.json.JSONObject call(org.json.JSONObject p12)
    {
        try {
            com.personal.aihub.MovieStorage.directories(this.root);
            com.personal.aihub.MovieStorage.directories(this.staging);
            String v0_1 = new java.util.ArrayList(this.jobs.keySet()).iterator();
        } catch (Throwable v12_71) {
            throw v12_71;
        }
        while (v0_1.hasNext()) {
            String v1_22 = ((String) v0_1.next());
            if ((this.clock.getAsLong() - ((com.personal.aihub.MovieStorage$Job) this.jobs.get(v1_22)).touched) >= 600000) {
                this.discard(v1_22);
            }
        }
        String v0_13 = p12.opt("action");
        if (!(v0_13 instanceof String)) {
            throw com.personal.aihub.MovieStorage.fail("Choose a valid movie upload action.");
        } else {
            String v1_23;
            String v0_25 = ((String) v0_13);
            if (!v0_25.equals("begin")) {
                if (!v0_25.equals("append")) {
                    if (!v0_25.equals("finish")) {
                        if (!v0_25.equals("cancel")) {
                            throw com.personal.aihub.MovieStorage.fail("Invalid movie upload action.");
                        } else {
                        }
                    }
                    v1_23 = new String[] {"action", "uploadId"});
                } else {
                    v1_23 = new String[] {"action", "uploadId", "offset", "data"});
                }
            } else {
                v1_23 = new String[] {"action", "name"});
            }
            long v2_39 = new java.util.HashSet(java.util.Arrays.asList(v1_23));
            String v1_28 = p12.keys();
            while (v1_28.hasNext()) {
                if (!v2_39.contains(v1_28.next())) {
                    throw com.personal.aihub.MovieStorage.fail("Invalid movie upload arguments.");
                } else {
                }
            }
            if (!v0_25.equals("begin")) {
                String v1_33 = p12.opt("uploadId");
                if ((!(v1_33 instanceof String)) || ((!((String) v1_33).matches("[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}")) || (!this.jobs.containsKey(v1_33)))) {
                    throw com.personal.aihub.MovieStorage.fail("This movie upload expired or was canceled. Start it again.");
                } else {
                    String v1_34 = ((String) v1_33);
                    com.personal.aihub.MovieStorage$Job v5_10 = ((com.personal.aihub.MovieStorage$Job) this.jobs.get(v1_34));
                    long v6_8 = this.temporary(v1_34);
                    if (!v0_25.equals("cancel")) {
                        if (!v0_25.equals("append")) {
                            try {
                                if ((java.nio.file.Files.isSymbolicLink(v6_8.toPath())) || ((!java.nio.file.Files.isRegularFile(v6_8.toPath(), new java.nio.file.LinkOption[] {java.nio.file.LinkOption.NOFOLLOW_LINKS}))) || (v6_8.length() != v5_10.bytes))) {
                                    throw com.personal.aihub.MovieStorage.fail("The temporary movie file changed.");
                                } else {
                                    String v0_10 = com.personal.aihub.MovieStorage.inspect(v6_8);
                                    long v2_3 = new StringBuilder();
                                    v2_3.append("generated-movie-");
                                    v2_3.append(java.util.UUID.randomUUID());
                                    long v2_4 = v2_3.toString();
                                    long v7_7 = new java.io.File(this.root, v2_4);
                                    try {
                                        if (!v7_7.mkdir()) {
                                            throw com.personal.aihub.MovieStorage.fail("The movie destination is unavailable.");
                                        } else {
                                            com.personal.aihub.MovieStorage.directories(v7_7);
                                            Throwable v12_6 = v6_8.toPath();
                                            long v6_2 = new java.io.File(v7_7, "movie.usm").toPath();
                                            int v3_0 = new java.nio.file.CopyOption[1];
                                            v3_0[0] = java.nio.file.StandardCopyOption.ATOMIC_MOVE;
                                            java.nio.file.Files.move(v12_6, v6_2, v3_0);
                                            this.jobs.remove(v1_34);
                                            Throwable v12_9 = v0_10.put("storageTag", v1_34.replace("-", ""));
                                            int v3_4 = new StringBuilder();
                                            v3_4.append(v2_4);
                                            v3_4.append("/movie.usm");
                                            return v12_9.put("key", v3_4.toString()).put("path", "movie.usm").put("size", v5_10.bytes).put("name", v5_10.name).put("image", 0);
                                        }
                                    } catch (Throwable v12_2) {
                                    }
                                }
                            } catch (String v0_12) {
                                v7_7 = 0;
                                v12_2 = v0_12;
                            }
                            this.discard(v1_34);
                            if (v7_7 != 0) {
                                v7_7.delete();
                            }
                            throw v12_2;
                        } else {
                            String v0_21 = p12.opt("offset");
                            Throwable v12_17 = p12.opt("data");
                            if ((!com.personal.aihub.MovieStorage.integer(v0_21)) || (((Number) v0_21).longValue() != v5_10.bytes)) {
                                throw com.personal.aihub.MovieStorage.fail("Movie chunks must arrive in their original order. Retry this chunk.");
                            } else {
                                if (!(v12_17 instanceof String)) {
                                    throw com.personal.aihub.MovieStorage.fail("Invalid movie chunk.");
                                } else {
                                    Throwable v12_22 = ((String) v12_17);
                                    if ((v12_22.isEmpty()) || ((v12_22.length() > 349528) || (((v12_22.length() % 4) != 0) || (!v12_22.matches("[A-Za-z0-9+/]*={0,2}"))))) {
                                        throw com.personal.aihub.MovieStorage.fail("Invalid movie chunk.");
                                    } else {
                                        String v0_33 = java.util.Base64.getDecoder().decode(v12_22);
                                        if ((v0_33.length == 0) || ((v0_33.length > 262144) || (!java.util.Base64.getEncoder().encodeToString(v0_33).equals(v12_22)))) {
                                            throw com.personal.aihub.MovieStorage.fail("Invalid movie chunk.");
                                        } else {
                                            Throwable v12_32 = this.jobs.values().iterator();
                                            long v2_14 = 0;
                                            while (v12_32.hasNext()) {
                                                v2_14 += ((com.personal.aihub.MovieStorage$Job) v12_32.next()).bytes;
                                            }
                                            if (((v5_10.bytes + ((long) v0_33.length)) > 100663296) || ((v2_14 + ((long) v0_33.length)) > 402653184)) {
                                                this.discard(v1_34);
                                                throw com.personal.aihub.MovieStorage.fail("Movie uploads are limited to 96 MB per movie and 384 MB total.");
                                            } else {
                                                try {
                                                    if ((java.nio.file.Files.isSymbolicLink(v6_8.toPath())) || ((!java.nio.file.Files.isRegularFile(v6_8.toPath(), new java.nio.file.LinkOption[] {java.nio.file.LinkOption.NOFOLLOW_LINKS}))) || (v6_8.length() != v5_10.bytes))) {
                                                        throw com.personal.aihub.MovieStorage.fail("The temporary movie file changed.");
                                                    } else {
                                                        Throwable v12_47 = new java.io.RandomAccessFile(v6_8, "rw");
                                                        try {
                                                            if (v12_47.length() != v5_10.bytes) {
                                                                throw com.personal.aihub.MovieStorage.fail("The temporary movie file changed.");
                                                            } else {
                                                                v12_47.seek(v5_10.bytes);
                                                                v12_47.write(v0_33);
                                                                v12_47.getFD().sync();
                                                                v12_47.close();
                                                                v5_10.bytes = (v5_10.bytes + ((long) v0_33.length));
                                                                v5_10.touched = this.clock.getAsLong();
                                                                return new org.json.JSONObject().put("bytes", v5_10.bytes);
                                                            }
                                                        } catch (String v0_36) {
                                                            try {
                                                                v12_47.close();
                                                            } catch (Throwable v12_48) {
                                                                v0_36.addSuppressed(v12_48);
                                                            }
                                                            throw v0_36;
                                                        }
                                                    }
                                                } catch (Throwable v12_54) {
                                                    this.discard(v1_34);
                                                    throw v12_54;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        this.discard(v1_34);
                        return new org.json.JSONObject().put("canceled", 1);
                    }
                }
            } else {
                if (this.jobs.size() >= 4) {
                    throw com.personal.aihub.MovieStorage.fail("Finish or cancel another movie upload first.");
                } else {
                    String v0_42 = p12.opt("name");
                    if (p12.has("name")) {
                        if ((!(v0_42 instanceof String)) || (((String) v0_42).length() > 160)) {
                            throw com.personal.aihub.MovieStorage.fail("Choose a movie name of 160 characters or less.");
                        } else {
                        }
                    }
                    Throwable v12_64 = p12.optString("name", "Custom movie").replaceAll("[\\x00-\\x1f\\x7f]", "");
                    if (v12_64.isEmpty()) {
                        v12_64 = "Custom movie";
                    }
                    String v0_50 = java.util.UUID.randomUUID().toString();
                    String v1_17 = this.temporary(v0_50).toPath();
                    long v2_28 = new byte[0];
                    com.personal.aihub.MovieStorage$Job v5_1 = new java.nio.file.OpenOption[2];
                    v5_1[0] = java.nio.file.StandardOpenOption.CREATE_NEW;
                    v5_1[1] = java.nio.file.StandardOpenOption.WRITE;
                    java.nio.file.Files.write(v1_17, v2_28, v5_1);
                    this.jobs.put(v0_50, new com.personal.aihub.MovieStorage$Job(v12_64, this.clock.getAsLong()));
                    return new org.json.JSONObject().put("uploadId", v0_50);
                }
            }
        }
    }
}
