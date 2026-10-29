package com.personal.aihub;
final class PreviewResources {

    PreviewResources()
    {
        return;
    }

    private static android.webkit.WebResourceResponse error(int p8, String p9)
    {
        android.webkit.WebResourceResponse v7 = new android.webkit.WebResourceResponse;
        v7("text/plain", "UTF-8", p8, "Unavailable", java.util.Collections.singletonMap("Cache-Control", "no-store"), new java.io.ByteArrayInputStream(p9.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        return v7;
    }

    static android.webkit.WebResourceResponse response(android.content.Context p23, android.webkit.WebResourceRequest p24)
    {
        String v2_7 = p24.getUrl();
        if (("https".equals(v2_7.getScheme())) && (("dokkan-eclipse.com".equals(v2_7.getHost())) && ((v2_7.getPort() == -1) && (v2_7.getUserInfo() == null)))) {
            String v2_9;
            String v2_2 = v2_7.getPath();
            if (!"/_forge/training-context.js".equals(v2_2)) {
                if (!"/_forge/native-audio.js".equals(v2_2)) {
                    if (!"/_forge/audio-bank.js".equals(v2_2)) {
                        if (!"/_forge/imported-audio.js".equals(v2_2)) {
                            if (!"/_forge/media/movie-edit-plan.js".equals(v2_2)) {
                                if (!"/_forge/media/usm-writer.js".equals(v2_2)) {
                                    if (!"/_forge/media/native-adx.js".equals(v2_2)) {
                                        if (!"/_forge/media/hca-metadata.js".equals(v2_2)) {
                                            if (!"/tools/usm-player/js/pipeline.js".equals(v2_2)) {
                                                if (!"/tools/lua-player/js/forge-imported.js".equals(v2_2)) {
                                                    if (!"/tools/usm-player/js/forge-metadata.js".equals(v2_2)) {
                                                        if ((v2_2 != null) && (v2_2.matches("/_forge/media/(libav/)?[A-Za-z0-9][A-Za-z0-9_.-]*"))) {
                                                            StringBuilder v3_36 = new StringBuilder("ui/vendor/media/");
                                                            v3_36.append(v2_2.substring(14));
                                                            v2_9 = v3_36.toString();
                                                        } else {
                                                            v2_9 = 0;
                                                        }
                                                    } else {
                                                        v2_9 = "ui/media-metadata.js";
                                                    }
                                                } else {
                                                    v2_9 = "ui/imported-preview.js";
                                                }
                                            } else {
                                                v2_9 = "ui/media-pipeline.js";
                                            }
                                        } else {
                                            v2_9 = "ui/hca-metadata.js";
                                        }
                                    } else {
                                        v2_9 = "ui/native-adx.js";
                                    }
                                } else {
                                    v2_9 = "ui/usm-writer.js";
                                }
                            } else {
                                v2_9 = "ui/movie-edit-plan.js";
                            }
                        } else {
                            v2_9 = "ui/imported-audio.js";
                        }
                    } else {
                        v2_9 = "ui/audio-bank.js";
                    }
                } else {
                    v2_9 = "ui/native-audio.js";
                }
            } else {
                v2_9 = "ui/training-context.js";
            }
            if (v2_9 != null) {
                if ((p24.getMethod().equals("GET")) || (p24.getMethod().equals("HEAD"))) {
                    try {
                        StringBuilder v3_5 = p23.getAssets().open(v2_9);
                        int v7_1 = ((long) v3_5.available());
                        long v11_0 = (v7_1 - 1);
                        String v13_2 = ((String) p24.getRequestHeaders().get("Range"));
                    } catch (Exception) {
                        return com.personal.aihub.PreviewResources.error(404, "A packaged movie component is missing. Reinstall the app.");
                    }
                    if (v13_2 == null) {
                        v13_2 = ((String) p24.getRequestHeaders().get("range"));
                    }
                    int v0_11;
                    byte[] v4_12;
                    boolean v15_1 = new java.util.HashMap();
                    v15_1.put("Cache-Control", "no-store");
                    v15_1.put("Accept-Ranges", "bytes");
                    v15_1.put("Cross-Origin-Resource-Policy", "same-origin");
                    if (v13_2 != null) {
                        if ((!v13_2.matches("bytes=([0-9]+-[0-9]*|-[0-9]+)")) || (v7_1 == 0)) {
                            v3_5.close();
                            return com.personal.aihub.PreviewResources.error(416, "Invalid byte range");
                        } else {
                            byte[] v4_8 = v13_2.substring(6).split("-", -1);
                            if (!v4_8[0].isEmpty()) {
                                long v21_1 = Long.parseLong(v4_8[0]);
                                if (!v4_8[1].isEmpty()) {
                                    v11_0 = Math.min(v11_0, Long.parseLong(v4_8[1]));
                                }
                                v4_12 = v21_1;
                            } else {
                                byte[] v4_14 = Long.parseLong(v4_8[1]);
                                if (v4_14 <= 0) {
                                    throw new java.io.IOException();
                                } else {
                                    v4_12 = Math.max(0, (v7_1 - v4_14));
                                }
                            }
                            if ((v4_12 >= v7_1) || (v11_0 < v4_12)) {
                                throw new java.io.IOException();
                            } else {
                                StringBuilder v9_3 = new StringBuilder("bytes ");
                                v9_3.append(v4_12);
                                v9_3.append("-");
                                v9_3.append(v11_0);
                                v9_3.append("/");
                                v9_3.append(v7_1);
                                v15_1.put("Content-Range", v9_3.toString());
                                v0_11 = 206;
                            }
                        }
                    } else {
                        v0_11 = 200;
                        v4_12 = 0;
                    }
                    long v11_2 = ((v11_0 - v4_12) + 1);
                    v15_1.put("Content-Length", Long.toString(v11_2));
                    int v6_1 = "Partial Content";
                    int v7_4 = "OK";
                    if (!p24.getMethod().equals("HEAD")) {
                        String v10_0 = v15_1;
                        String v13_11 = 0;
                        while (v13_11 < v4_12) {
                            long v24_2 = v6_1;
                            com.personal.aihub.PreviewResources$1 v1_8 = v7_4;
                            int v6_3 = v3_5.skip((v4_12 - v13_11));
                            if (v6_3 > 0) {
                                v13_11 += v6_3;
                                v6_1 = v24_2;
                                v7_4 = v1_8;
                            } else {
                                v3_5.close();
                                return com.personal.aihub.PreviewResources.error(416, "Invalid byte offset");
                            }
                        }
                        String v16_0;
                        String v2_1;
                        long v24_1 = v6_1;
                        com.personal.aihub.PreviewResources$1 v1_5 = v7_4;
                        byte[] v4_16 = new android.webkit.WebResourceResponse;
                        boolean v15_2 = com.personal.aihub.PreviewResources.type(v2_9);
                        if (!v2_9.endsWith(".wasm")) {
                            v16_0 = "UTF-8";
                            v2_1 = 206;
                        } else {
                            v2_1 = 206;
                            v16_0 = 0;
                        }
                        int v18_0;
                        if (v0_11 != v2_1) {
                            v18_0 = v1_5;
                        } else {
                            v18_0 = v24_1;
                        }
                        v4_16(v15_2, v16_0, v0_11, v18_0, v10_0, new com.personal.aihub.PreviewResources$1(v3_5, v11_2));
                        return v4_16;
                    } else {
                        String v2_4;
                        String v16_1;
                        v3_5.close();
                        com.personal.aihub.PreviewResources$1 v1_10 = new android.webkit.WebResourceResponse;
                        StringBuilder v3_11 = com.personal.aihub.PreviewResources.type(v2_9);
                        if (!v2_9.endsWith(".wasm")) {
                            v16_1 = "UTF-8";
                            v2_4 = 206;
                        } else {
                            v2_4 = 206;
                            v16_1 = 0;
                        }
                        int v18_1;
                        if (v0_11 != v2_4) {
                            v18_1 = "OK";
                        } else {
                            v18_1 = "Partial Content";
                        }
                        byte[] v4_18 = new byte[0];
                        v1_10(v3_11, v16_1, v0_11, v18_1, v15_1, new java.io.ByteArrayInputStream(v4_18));
                        return v1_10;
                    }
                } else {
                    return com.personal.aihub.PreviewResources.error(405, "Method not allowed");
                }
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    private static String type(String p1)
    {
        if (!p1.endsWith(".wasm")) {
            if (!p1.endsWith(".js")) {
                String v1_2;
                if (!p1.endsWith(".json")) {
                    v1_2 = "text/plain";
                } else {
                    v1_2 = "application/json";
                }
                return v1_2;
            } else {
                return "application/javascript";
            }
        } else {
            return "application/wasm";
        }
    }
}
