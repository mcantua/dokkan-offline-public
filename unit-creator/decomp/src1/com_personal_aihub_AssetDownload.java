package com.personal.aihub;
public final class AssetDownload {
    public static final String GROUP = "^art-download-[0-9]{10,16}-[A-Za-z0-9_-]{6,64}$";
    public static final long LIMIT = 167772160;

    public AssetDownload()
    {
        return;
    }

    public static java.io.File destination(java.io.File p4, String p5)
    {
        if ((!com.personal.aihub.GameAssets.safe(p5)) || ((!p4.isDirectory()) || (java.nio.file.Files.isSymbolicLink(p4.toPath())))) {
            throw new java.io.IOException("Invalid asset collection.");
        } else {
            String v5_2 = p5.split("/");
            int v0_2 = 0;
            int v1_0 = p4;
            while (v0_2 < (v5_2.length - 1)) {
                int v2_5 = new java.io.File(v1_0, v5_2[v0_2]);
                if ((!v2_5.isDirectory()) && (!v2_5.mkdir())) {
                    throw new java.io.IOException("Cannot create asset collection.");
                } else {
                    if (java.nio.file.Files.isSymbolicLink(v2_5.toPath())) {
                        throw new java.io.IOException("Asset collections cannot use symbolic links.");
                    } else {
                        v0_2++;
                        v1_0 = v2_5;
                    }
                }
            }
            int v0_4 = new java.io.File(v1_0, v5_2[(v5_2.length - 1)]);
            if (!java.nio.file.Files.isSymbolicLink(v0_4.toPath())) {
                String v5_6 = v0_4.getCanonicalPath();
                int v1_2 = new StringBuilder();
                v1_2.append(String.valueOf(p4.getCanonicalPath()));
                v1_2.append(java.io.File.separator);
                if (v5_6.startsWith(v1_2.toString())) {
                    return v0_4;
                }
            }
            throw new java.io.IOException("Invalid asset destination.");
        }
    }

    public static java.net.HttpURLConnection openOfficial(String p1)
    {
        return com.personal.aihub.AssetDownload.openOfficial(new java.net.URL(p1), 0);
    }

    private static java.net.HttpURLConnection openOfficial(java.net.URL p3, int p4)
    {
        if ((p4 > 5) || ((!"https".equals(p3.getProtocol())) || ((!"dokkan-eclipse.com".equals(p3.getHost())) || ((p3.getUserInfo() != null) || (p3.getPort() != -1))))) {
            throw new java.io.IOException("Only official Eclipse resource routes are supported.");
        } else {
            java.net.URL v0_6 = ((java.net.HttpURLConnection) p3.openConnection());
            v0_6.setConnectTimeout(20000);
            v0_6.setReadTimeout(60000);
            v0_6.setInstanceFollowRedirects(0);
            v0_6.setRequestProperty("User-Agent", "DokkanUnitCreator/2.7");
            v0_6.setRequestProperty("Accept-Encoding", "identity");
            String v1_8 = v0_6.getResponseCode();
            if ((v1_8 >= 300) && (v1_8 < 400)) {
                String v1_10 = v0_6.getHeaderField("Location");
                v0_6.disconnect();
                if (v1_10 == null) {
                    throw new java.io.IOException("Invalid Eclipse redirect.");
                } else {
                    return com.personal.aihub.AssetDownload.openOfficial(new java.net.URL(p3, v1_10), (p4 + 1));
                }
            } else {
                if (v1_8 != 200) {
                    v0_6.disconnect();
                    String v4_5 = new StringBuilder("Eclipse returned HTTP ");
                    v4_5.append(v1_8);
                    v4_5.append(".");
                    throw new java.io.IOException(v4_5.toString());
                } else {
                    return v0_6;
                }
            }
        }
    }

    public static long write(java.net.HttpURLConnection p19, java.io.File p20, boolean p21, long p22)
    {
        if ((p22 < 1) || (p22 > 167772160)) {
            throw new java.io.IOException("Invalid resource size limit.");
        } else {
            java.nio.file.Path v0_6 = p20.getParentFile();
            java.nio.file.Path v3_5 = new StringBuilder(".download-");
            v3_5.append(java.util.UUID.randomUUID());
            v3_5.append(".tmp");
            java.io.File v2_2 = new java.io.File(v0_6, v3_5.toString());
            try {
                if (p19.getResponseCode() != 200) {
                    throw new java.io.IOException("Resource download failed.");
                } else {
                    java.nio.file.CopyOption[] v4_10;
                    java.nio.file.Path v0_24 = p19.getHeaderField("Content-Length");
                    if (v0_24 == null) {
                        v4_10 = -1;
                    } else {
                        if (!v0_24.matches("[0-9]+")) {
                            throw new java.io.IOException("Invalid resource declared size.");
                        } else {
                            v4_10 = Long.parseLong(v0_24);
                            if (v4_10 > p22) {
                                throw new java.io.IOException("Resource download exceeds160MB.");
                            }
                        }
                    }
                    java.nio.file.Path v0_34 = p19.getHeaderField("Content-Encoding");
                    if (v0_34 != null) {
                        if (!v0_34.equalsIgnoreCase("identity")) {
                            throw new java.io.IOException("Unsupported resource HTTP compression.");
                        } else {
                        }
                    }
                    if (p21) {
                        if (java.nio.file.Files.exists(p20.toPath(), new java.nio.file.LinkOption[] {java.nio.file.LinkOption.NOFOLLOW_LINKS}))) {
                            throw new java.io.IOException("This artwork collection already contains that resource.");
                        } else {
                        }
                    }
                    int v6_4 = p19.getInputStream();
                    try {
                        java.nio.file.Path v0_43 = v2_2.toPath();
                        java.io.OutputStream v8_1 = new java.nio.file.OpenOption[2];
                        v8_1[0] = java.nio.file.StandardOpenOption.CREATE_NEW;
                        v8_1[1] = java.nio.file.StandardOpenOption.WRITE;
                        java.io.OutputStream v8_0 = java.nio.file.Files.newOutputStream(v0_43, v8_1);
                    } catch (java.nio.file.Path v0_16) {
                        java.nio.file.Path v3_8 = v0_16;
                        if (v6_4 != 0) {
                            try {
                                v6_4.close();
                            } catch (java.nio.file.Path v0_17) {
                                v3_8.addSuppressed(v0_17);
                            }
                        }
                        throw v3_8;
                    }
                    try {
                        java.nio.file.Path v0_46 = new byte[65536];
                        long v14 = 0;
                    } catch (java.nio.file.Path v0_0) {
                        java.io.OutputStream v11_0 = v8_0;
                        java.nio.file.Path v3_7 = v0_0;
                        if (v11_0 != null) {
                            try {
                                v11_0.close();
                            } catch (java.nio.file.Path v0_15) {
                                v3_7.addSuppressed(v0_15);
                            }
                        }
                        throw v3_7;
                    }
                    while(true) {
                        int v9_0 = v6_4.read(v0_46);
                        if (v9_0 == -1) {
                            break;
                        }
                        java.io.OutputStream v16 = v8_0;
                        int v7_0 = ((long) v9_0);
                        try {
                            if (v7_0 > (p22 - v14)) {
                                v11_0 = v16;
                                throw new java.io.IOException("Resource download exceeds160MB.");
                            } else {
                                if ((v4_10 >= 0) && (v7_0 > (v4_10 - v14))) {
                                    try {
                                        throw new java.io.IOException("Resource size does not match its download.");
                                    } catch (java.nio.file.Path v0_14) {
                                        v3_7 = v0_14;
                                        v11_0 = v16;
                                    }
                                } else {
                                    java.io.OutputStream v11_3 = v16;
                                    v11_3.write(v0_46, 0, v9_0);
                                    v14 += v7_0;
                                    v8_0 = v11_3;
                                    v11_0 = 1;
                                }
                            }
                        } catch (java.nio.file.Path v0_0) {
                        }
                    }
                    java.io.OutputStream v11_2 = v8_0;
                    if (v11_2 != null) {
                        v11_2.close();
                    }
                    if (v6_4 != 0) {
                        v6_4.close();
                    }
                    if (v4_10 >= 0) {
                        if (v14 != v4_10) {
                            throw new java.io.IOException("The resource download was incomplete.");
                        } else {
                        }
                    }
                    if (!p21) {
                        java.nio.file.Path v0_5 = v2_2.toPath();
                        java.nio.file.Path v3_1 = p20.toPath();
                        java.nio.file.CopyOption[] v4_1 = new java.nio.file.CopyOption[2];
                        v4_1[0] = java.nio.file.StandardCopyOption.ATOMIC_MOVE;
                        v4_1[1] = java.nio.file.StandardCopyOption.REPLACE_EXISTING;
                        java.nio.file.Files.move(v0_5, v3_1, v4_1);
                    } else {
                        java.nio.file.CopyOption[] v4_4 = new java.nio.file.CopyOption[0];
                        java.nio.file.Files.move(v2_2.toPath(), p20.toPath(), v4_4);
                    }
                    p19.disconnect();
                    java.nio.file.Files.deleteIfExists(v2_2.toPath());
                    return v14;
                }
            } catch (java.nio.file.Path v0_18) {
                p19.disconnect();
                java.nio.file.Files.deleteIfExists(v2_2.toPath());
                throw v0_18;
            }
        }
    }
}
