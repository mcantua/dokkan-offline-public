package com.personal.aihub;
public final class LegacyDatabase {
    private static final int LIMIT = 536870912;

    private LegacyDatabase()
    {
        return;
    }

    public static void decrypt(java.io.File p1, java.io.File p2, byte[] p3)
    {
        com.personal.aihub.LegacyDatabase.decrypt(p1, p2, p3, 3);
        return;
    }

    public static void decrypt(java.io.File p26, java.io.File p27, byte[] p28, int p29)
    {
        if ((p29 != 3) && (p29 != 4)) {
            throw new java.io.IOException("Unsupported database cipher mode.");
        } else {
            Throwable v5_0;
            if (p29 != 3) {
                v5_0 = 4096;
            } else {
                v5_0 = 1024;
            }
            int v6;
            if (p29 != 3) {
                v6 = 80;
            } else {
                v6 = 48;
            }
            java.io.File v9_2;
            int v7 = (v5_0 - v6);
            if (p29 != 3) {
                v9_2 = 64;
            } else {
                v9_2 = 20;
            }
            javax.crypto.Cipher v10_2;
            if (p29 != 3) {
                v10_2 = "HmacSHA512";
            } else {
                v10_2 = "HmacSHA1";
            }
            if ((p28 == null) || ((p28.length == 0) || (p28.length > 4096))) {
                throw new java.io.IOException("The imported APK did not provide a supported database format.");
            } else {
                Throwable v4_5 = p26.getCanonicalFile();
                java.io.DataInputStream v11_5 = p27.getAbsoluteFile().getParentFile().getCanonicalFile();
                javax.crypto.Mac v12_5 = new java.io.File(v11_5, p27.getName());
                if ((!v11_5.isDirectory()) || ((v4_5.equals(v12_5)) || ((v12_5.exists()) && (!v12_5.getCanonicalFile().equals(v12_5))))) {
                    throw new java.io.IOException("Choose a separate safe database output file.");
                } else {
                    long v13_6 = v4_5.length();
                    if (v4_5.isFile()) {
                        int v16 = v9_2;
                        long v8_9 = ((long) v5_0);
                        if ((v13_6 >= v8_9) && ((v13_6 <= 536870912) && ((v13_6 % v8_9) == 0))) {
                            int v2_10 = new StringBuilder("legacy-db-");
                            v2_10.append(java.util.UUID.randomUUID());
                            v2_10.append(".tmp");
                            int v15_23 = new java.io.File(v11_5, v2_10.toString());
                            try {
                                java.io.DataInputStream v11_0 = new java.io.DataInputStream(new java.io.BufferedInputStream(new java.io.FileInputStream(v4_5)));
                                try {
                                    int v2_2 = new java.io.FileOutputStream(v15_23);
                                    try {
                                        byte[] v3_2 = new java.io.BufferedOutputStream(v2_2);
                                        try {
                                            Throwable v4_3 = new byte[v5_0];
                                            v11_0.readFully(v4_3);
                                            java.io.File v20 = v12_5;
                                            java.io.File v21 = v15_23;
                                            try {
                                                int v15_1 = java.util.Arrays.copyOf(v4_3, 16);
                                                javax.crypto.Mac v12_2 = ((byte[]) v15_1.clone());
                                                int v22_0 = v2_2;
                                                int v23 = v3_2;
                                                int v2_3 = 0;
                                                try {
                                                    while (v2_3 < v12_2.length) {
                                                        try {
                                                            v12_2[v2_3] = ((byte) (v12_2[v2_3] ^ 58));
                                                            v2_3++;
                                                        } catch (java.io.IOException v0_31) {
                                                            Throwable v4_4 = v0_31;
                                                            byte[] v1_1 = v21;
                                                            int v15_0 = v23;
                                                            int v2_0 = 0;
                                                            byte[] v3_0 = 0;
                                                            try {
                                                                v15_0.close();
                                                            } catch (java.io.IOException v0_32) {
                                                                v4_4.addSuppressed(v0_32);
                                                            } catch (java.io.IOException v0_33) {
                                                                Throwable v4_2 = v0_33;
                                                                try {
                                                                    v22_0.close();
                                                                } catch (java.io.IOException v0_34) {
                                                                    v4_2.addSuppressed(v0_34);
                                                                } catch (java.io.IOException v0_35) {
                                                                    Throwable v4_1 = v0_35;
                                                                    try {
                                                                        v11_0.close();
                                                                    } catch (java.io.IOException v0_36) {
                                                                        v4_1.addSuppressed(v0_36);
                                                                    } catch (java.io.IOException v0_2) {
                                                                        v1_1.delete();
                                                                        throw v0_2;
                                                                    }
                                                                    throw v4_1;
                                                                }
                                                                throw v4_2;
                                                            }
                                                            throw v4_4;
                                                        }
                                                    }
                                                } catch (java.io.IOException v0_5) {
                                                    v1_1 = v21;
                                                    v15_0 = v23;
                                                    v4_4 = v0_5;
                                                }
                                                byte[] v1_2;
                                                if (p29 != 3) {
                                                    v1_2 = 256000;
                                                } else {
                                                    v1_2 = 64000;
                                                }
                                                byte[] v1_3 = com.personal.aihub.LegacyDatabase.derive(p28, v15_1, v1_2, 32, v10_2);
                                                try {
                                                    v3_0 = com.personal.aihub.LegacyDatabase.derive(v1_3, v12_2, 2, 32, v10_2);
                                                    try {
                                                        javax.crypto.Mac v12_3 = javax.crypto.Mac.getInstance(v10_2);
                                                        v12_3.init(new javax.crypto.spec.SecretKeySpec(v3_0, v10_2));
                                                        javax.crypto.Cipher v10_1 = javax.crypto.Cipher.getInstance("AES/CBC/NoPadding");
                                                        v15_0 = 1;
                                                        java.io.File v28_1 = v1_3;
                                                        int v2_6 = 1;
                                                        try {
                                                            while (((long) v2_6) <= (v13_6 / v8_9)) {
                                                                if (v2_6 > v15_0) {
                                                                    try {
                                                                        v11_0.readFully(v4_3);
                                                                    } catch (java.io.IOException v0_21) {
                                                                        v2_0 = v28_1;
                                                                        v4_4 = v0_21;
                                                                        v1_1 = v21;
                                                                        v15_0 = v23;
                                                                    }
                                                                }
                                                                java.io.IOException v0_22;
                                                                if (v2_6 != v15_0) {
                                                                    v0_22 = 0;
                                                                } else {
                                                                    v0_22 = 16;
                                                                }
                                                                byte[] v1_8 = (v7 + 16);
                                                                try {
                                                                    java.io.File v9_3;
                                                                    v12_3.update(v4_3, v0_22, (v1_8 - v0_22));
                                                                    v12_3.update(((byte) v2_6));
                                                                    v12_3.update(((byte) (v2_6 >> 8)));
                                                                    v12_3.update(((byte) (v2_6 >> 16)));
                                                                    v12_3.update(((byte) (v2_6 >> 24)));
                                                                    long v24_1 = v8_9;
                                                                    try {
                                                                        if (!java.security.MessageDigest.isEqual(v12_3.doFinal(), java.util.Arrays.copyOfRange(v4_3, v1_8, (v1_8 + v16)))) {
                                                                            v9_3 = v28_1;
                                                                            v15_0 = v23;
                                                                            throw new java.io.IOException("Database authentication failed. The file is damaged or does not match this imported APK\'s supported format.");
                                                                        } else {
                                                                            v9_3 = v28_1;
                                                                            v15_0 = 2;
                                                                            v10_1.init(2, new javax.crypto.spec.SecretKeySpec(v9_3, "AES"), new javax.crypto.spec.IvParameterSpec(v4_3, v7, 16));
                                                                            java.io.IOException v0_27 = v10_1.doFinal(v4_3, v0_22, (v7 - v0_22));
                                                                            if (v2_6 != 1) {
                                                                                v15_0 = v23;
                                                                            } else {
                                                                                v15_0 = (v0_27[1] & 255);
                                                                                if ((((v0_27[0] & 255) << 8) | v15_0) == v5_0) {
                                                                                    v15_0 = (v0_27[4] & 255);
                                                                                    if (v15_0 >= v6) {
                                                                                        v15_0 = v0_27[5];
                                                                                        if (v15_0 == 64) {
                                                                                            v15_0 = v0_27[6];
                                                                                            if (v15_0 == 32) {
                                                                                                v15_0 = v0_27[7];
                                                                                                if (v15_0 == 32) {
                                                                                                    v15_0 = v23;
                                                                                                    v15_0.write("SQLite format 3\u0000".getBytes(java.nio.charset.StandardCharsets.US_ASCII));
                                                                                                    v15_0.write(v0_27);
                                                                                                    byte[] v1_22 = new byte[v6];
                                                                                                    v15_0.write(v1_22);
                                                                                                    java.util.Arrays.fill(v0_27, 0);
                                                                                                    v2_6++;
                                                                                                    v28_1 = v9_3;
                                                                                                    v23 = v15_0;
                                                                                                    v8_9 = v24_1;
                                                                                                    v15_0 = 1;
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                                v15_0 = v23;
                                                                                throw new java.io.IOException("The decrypted database has an unsupported SQLite header.");
                                                                            }
                                                                        }
                                                                    } catch (java.io.IOException v0_23) {
                                                                        v4_4 = v0_23;
                                                                        v2_0 = v9_3;
                                                                        v1_1 = v21;
                                                                    }
                                                                } catch (java.io.IOException v0_23) {
                                                                    v9_3 = v28_1;
                                                                    v15_0 = v23;
                                                                }
                                                            }
                                                        } catch (java.io.IOException v0_8) {
                                                            java.io.File v9_1 = v28_1;
                                                            v1_1 = v21;
                                                            v15_0 = v23;
                                                            v4_4 = v0_8;
                                                            v2_0 = v9_1;
                                                        }
                                                        v9_1 = v28_1;
                                                        v15_0 = v23;
                                                        try {
                                                            if (v11_0.read() != -1) {
                                                                v1_1 = v21;
                                                                try {
                                                                    throw new java.io.IOException("The legacy database changed during import.");
                                                                } catch (java.io.IOException v0_8) {
                                                                }
                                                            } else {
                                                                v15_0.flush();
                                                                v22_0.getFD().sync();
                                                                try {
                                                                    v15_0.close();
                                                                    try {
                                                                        v22_0.close();
                                                                        try {
                                                                            v11_0.close();
                                                                        } catch (java.io.IOException v0_2) {
                                                                            v1_1 = v21;
                                                                            v2_0 = v9_1;
                                                                        } catch (java.io.IOException v0_1) {
                                                                            v2_0 = v9_1;
                                                                            if (v2_0 != 0) {
                                                                                java.util.Arrays.fill(v2_0, 0);
                                                                            }
                                                                            if (v3_0 != null) {
                                                                                java.util.Arrays.fill(v3_0, 0);
                                                                            }
                                                                            throw v0_1;
                                                                        }
                                                                        if (v9_1 != null) {
                                                                            java.util.Arrays.fill(v9_1, 0);
                                                                        }
                                                                        if (v3_0 != null) {
                                                                            java.util.Arrays.fill(v3_0, 0);
                                                                        }
                                                                        byte[] v1_6 = v21;
                                                                        if (!v1_6.renameTo(v20)) {
                                                                            v1_6.delete();
                                                                            throw new java.io.IOException("Could not save the authenticated database.");
                                                                        } else {
                                                                            return;
                                                                        }
                                                                    } catch (java.io.IOException v0_16) {
                                                                        v1_1 = v21;
                                                                        v4_1 = v0_16;
                                                                        v2_0 = v9_1;
                                                                    }
                                                                } catch (java.io.IOException v0_15) {
                                                                    v1_1 = v21;
                                                                    v4_2 = v0_15;
                                                                    v2_0 = v9_1;
                                                                }
                                                            }
                                                        } catch (java.io.IOException v0_8) {
                                                            v1_1 = v21;
                                                        }
                                                    } catch (java.io.IOException v0_8) {
                                                        v9_1 = v1_3;
                                                    }
                                                } catch (java.io.IOException v0_7) {
                                                    v1_1 = v21;
                                                    v15_0 = v23;
                                                    v4_4 = v0_7;
                                                    v2_0 = v1_3;
                                                }
                                            } catch (java.io.IOException v0_5) {
                                                v22_0 = 0;
                                                v15_0 = v3_2;
                                                v1_1 = v21;
                                            }
                                        } catch (java.io.IOException v0_5) {
                                            v22_0 = v2_2;
                                            v1_1 = v15_23;
                                            v15_0 = v3_2;
                                        }
                                    } catch (java.io.IOException v0_4) {
                                        v22_0 = v2_2;
                                        v1_1 = v15_23;
                                        v4_2 = v0_4;
                                        v2_0 = 0;
                                        v3_0 = 0;
                                    }
                                } catch (java.io.IOException v0_3) {
                                    v1_1 = v15_23;
                                    v4_1 = v0_3;
                                    v2_0 = 0;
                                    v3_0 = 0;
                                }
                            } catch (java.io.IOException v0_2) {
                                v1_1 = v15_23;
                                v2_0 = 0;
                                v3_0 = 0;
                            } catch (java.io.IOException v0_1) {
                                v2_0 = 0;
                                v3_0 = 0;
                            } catch (java.io.IOException v0_1) {
                            }
                        }
                    }
                    throw new java.io.IOException("This legacy database is incomplete or uses an unsupported page format.");
                }
            }
        }
    }

    private static byte[] derive(byte[] p11, byte[] p12, int p13, int p14, String p15)
    {
        javax.crypto.Mac v0 = javax.crypto.Mac.getInstance(p15);
        v0.init(new javax.crypto.spec.SecretKeySpec(p11, p15));
        byte[] v11_1 = new byte[p14];
        byte[] v15_3 = new byte[(p12.length + 4)];
        System.arraycopy(p12, 0, v15_3, 0, p12.length);
        int v4 = 1;
        int v3 = 0;
        while (v3 < p14) {
            v15_3[p12.length] = ((byte) (v4 >> 24));
            v15_3[(p12.length + 1)] = ((byte) (v4 >> 16));
            v15_3[(p12.length + 2)] = ((byte) (v4 >> 8));
            v15_3[(p12.length + 3)] = ((byte) v4);
            byte[] v5_7 = v0.doFinal(v15_3);
            byte[] v6_8 = ((byte[]) v5_7.clone());
            int v7_0 = 1;
            while (v7_0 < p13) {
                v5_7 = v0.doFinal(v5_7);
                int v8_1 = 0;
                while (v8_1 < v6_8.length) {
                    v6_8[v8_1] = ((byte) (v6_8[v8_1] ^ v5_7[v8_1]));
                    v8_1++;
                }
                v7_0++;
            }
            int v7_2 = Math.min(v6_8.length, (p14 - v3));
            System.arraycopy(v6_8, 0, v11_1, v3, v7_2);
            v3 += v7_2;
            java.util.Arrays.fill(v6_8, 0);
            java.util.Arrays.fill(v5_7, 0);
            v4++;
        }
        return v11_1;
    }
}
