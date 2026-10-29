package com.personal.aihub;
final class StageExport implements java.io.Closeable {
    static final int REQUEST = 531;
    private boolean closed;
    private java.io.File file;
    private final android.app.Activity owner;
    private java.util.concurrent.CompletableFuture pending;

    StageExport(android.app.Activity p1)
    {
        this.owner = p1;
        return;
    }

    private declared_synchronized void finish(boolean p2, Exception p3)
    {
        try {
            java.util.concurrent.CompletableFuture v0 = this.pending;
        } catch (Boolean v2_2) {
            throw v2_2;
        }
        if (v0 != null) {
            if (p3 != null) {
                v0.completeExceptionally(p3);
            } else {
                v0.complete(Boolean.valueOf(p2));
            }
        }
        return;
    }

    public declared_synchronized void close()
    {
        try {
            this.closed = 1;
            this.finish(0, new java.io.IOException("The animation preview was closed."));
            return;
        } catch (Throwable v0_3) {
            throw v0_3;
        }
    }

    void m39lambda$0$compersonalaihubStageExport()
    {
        try {
            if (this.owner.isFinishing()) {
                throw new java.io.IOException("The animation preview is closed.");
            } else {
                this.owner.startActivityForResult(new android.content.Intent("android.intent.action.CREATE_DOCUMENT").addCategory("android.intent.category.OPENABLE").setType("video/mp4").putExtra("android.intent.extra.TITLE", "animation-recording.mp4"), 531);
            }
        } catch (java.io.IOException v0_2) {
            this.finish(0, v0_2);
        }
        return;
    }

    void m40lambda$1$compersonalaihubStageExport(java.io.File p11, android.net.Uri p12)
    {
        try {
            if ((p11 == null) || ((p11.length() < 12) || (p11.length() > 167772160))) {
                throw new java.io.IOException("The recording is unavailable.");
            } else {
                int v1_3 = new java.io.FileInputStream(p11);
                try {
                    Throwable v11_5 = this.owner.getContentResolver().openOutputStream(p12, "wt");
                    try {
                        if (v11_5 == null) {
                            throw new java.io.IOException("The selected destination is unavailable.");
                        } else {
                            java.io.IOException v2_4 = new byte[65536];
                            long v5 = 0;
                            while(true) {
                                int v7 = v1_3.read(v2_4);
                                if (v7 == -1) {
                                    break;
                                }
                                if (this.closed) {
                                    throw new java.io.IOException("The animation preview is closed.");
                                } else {
                                    v5 += ((long) v7);
                                    if (v5 > 167772160) {
                                        throw new java.io.IOException("The recording exceeds160MiB.");
                                    } else {
                                        v11_5.write(v2_4, 0, v7);
                                    }
                                }
                            }
                            v11_5.flush();
                            if (v11_5 != null) {
                                v11_5.close();
                            }
                            v1_3.close();
                            this.finish(1, 0);
                        }
                    } catch (java.io.IOException v2_10) {
                        if (v11_5 != null) {
                            try {
                                v11_5.close();
                            } catch (Throwable v11_7) {
                                v2_10.addSuppressed(v11_7);
                            }
                        }
                        throw v2_10;
                    }
                } catch (Throwable v11_8) {
                    try {
                        v1_3.close();
                    } catch (int v1_7) {
                        v11_8.addSuppressed(v1_7);
                    }
                    throw v11_8;
                }
            }
        } catch (Throwable v11_9) {
            try {
                android.provider.DocumentsContract.deleteDocument(this.owner.getContentResolver(), p12);
            } catch (Exception) {
            }
            this.finish(0, v11_9);
        }
        return;
    }

    void result(int p2, int p3, android.content.Intent p4)
    {
        if (p2 == 531) {
            try {
                if (this.pending != null) {
                    if ((p3 != -1) || (p4 == null)) {
                        this.finish(0, 0);
                    } else {
                        if (p4.getData() != null) {
                            new Thread(new com.personal.aihub.StageExport$2(this, this.file, p4.getData()), "forge-recording-save").start();
                        } else {
                        }
                    }
                    return;
                } else {
                    return;
                }
            } catch (String v2_4) {
                throw v2_4;
            }
        } else {
            return;
        }
    }

    boolean save(java.io.File p4)
    {
        try {
            if ((this.closed) || (this.pending != null)) {
                throw new java.io.IOException("Finish the existing recording save dialog first.");
            } else {
                java.util.concurrent.CompletableFuture v0_2 = new java.util.concurrent.CompletableFuture();
                this.pending = v0_2;
                this.file = p4;
                this.owner.runOnUiThread(new com.personal.aihub.StageExport$1(this));
                try {
                    Throwable v1_4 = ((Boolean) v0_2.get()).booleanValue();
                } catch (Throwable v1_6) {
                    try {
                        if (this.pending == v0_2) {
                            this.pending = 0;
                            this.file = 0;
                        }
                    } catch (Throwable v4_3) {
                        throw v4_3;
                    }
                    throw v1_6;
                }
                if (this.pending == v0_2) {
                    this.pending = 0;
                    this.file = 0;
                }
                return v1_4;
            }
        } catch (Throwable v4_6) {
            throw v4_6;
        }
    }
}
