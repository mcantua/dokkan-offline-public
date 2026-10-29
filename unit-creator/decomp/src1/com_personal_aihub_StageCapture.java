package com.personal.aihub;
final class StageCapture implements java.io.Closeable {
    static final String SCRIPT = "(()=>{const e=document.getElementById('stage');if(!e)return null;const p=e.parentElement;const r=e.dataset.phone==='1'&&(p&&p.classList.contains('stage-fit'))?p.getBoundingClientRect():e.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,vw:innerWidth,vh:innerHeight};})()";
    private final java.util.concurrent.atomic.AtomicBoolean busy;
    private final java.util.concurrent.atomic.AtomicBoolean closed;
    private final String origin;
    private final android.app.Activity owner;
    private final android.webkit.WebView web;

    StageCapture(android.app.Activity p2, android.webkit.WebView p3, String p4)
    {
        this.busy = new java.util.concurrent.atomic.AtomicBoolean();
        this.closed = new java.util.concurrent.atomic.AtomicBoolean();
        this.owner = p2;
        this.web = p3;
        this.origin = p4;
        return;
    }

    byte[] capture()
    {
        if ((this.closed.get()) || (!this.busy.compareAndSet(0, 1))) {
            throw new java.io.IOException("The animation snapshot is unavailable.");
        } else {
            java.util.concurrent.atomic.AtomicBoolean v0_4 = new java.util.concurrent.CompletableFuture();
            try {
                this.owner.runOnUiThread(new com.personal.aihub.StageCapture$1(this, v0_4));
                Throwable v1_4 = ((byte[]) v0_4.get(15, java.util.concurrent.TimeUnit.SECONDS));
                v0_4.cancel(0);
                java.util.concurrent.atomic.AtomicBoolean v0_6 = this.busy;
                v0_6.set(0);
                return v1_4;
            } catch (Throwable v1_5) {
                v0_6.cancel(0);
                this.busy.set(0);
                throw v1_5;
            }
        }
    }

    public void close()
    {
        this.closed.set(1);
        return;
    }

    void m36lambda$0$compersonalaihubStageCapture(java.util.concurrent.CompletableFuture p4)
    {
        if ((this.closed.get()) || ((this.owner.isFinishing()) || ((!this.web.isAttachedToWindow()) || (this.web.getUrl() == null)))) {
            p4.completeExceptionally(new java.io.IOException("Open the animation player before recording."));
        } else {
            android.webkit.WebView v0_5 = this.web.getUrl();
            com.personal.aihub.StageCapture$2 v1_1 = new StringBuilder();
            v1_1.append(String.valueOf(this.origin));
            v1_1.append("/tools/lua-player/");
            if (v0_5.startsWith(v1_1.toString())) {
                this.web.evaluateJavascript("(()=>{const e=document.getElementById(\'stage\');if(!e)return null;const p=e.parentElement;const r=e.dataset.phone===\'1\'&&(p&&p.classList.contains(\'stage-fit\'))?p.getBoundingClientRect():e.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,vw:innerWidth,vh:innerHeight};})()", new com.personal.aihub.StageCapture$2(this, p4));
            }
        }
        return;
    }

    void m37lambda$1$compersonalaihubStageCapture(java.util.concurrent.CompletableFuture p19, String p20)
    {
        try {
            android.graphics.Bitmap v0_8 = new org.json.JSONObject(p20);
            android.view.Window v3_5 = v0_8.getDouble("x");
            android.os.Handler v5_0 = v0_8.getDouble("y");
            android.graphics.Rect v7_6 = v0_8.getDouble("width");
            int v9_3 = v0_8.getDouble("height");
            double v11_1 = v0_8.getDouble("vw");
            double v13_1 = v0_8.getDouble("vh");
            android.graphics.Bitmap v0_7 = this.web.getScale();
        } catch (android.graphics.Bitmap v0_4) {
            p19.completeExceptionally(v0_4);
            return;
        }
        if ((Double.isFinite(v3_5)) && ((Double.isFinite(v5_0)) && ((Double.isFinite(v7_6)) && ((Double.isFinite(v9_3)) && ((Double.isFinite(v11_1)) && ((Double.isFinite(v13_1)) && ((Float.isFinite(v0_7)) && ((v0_7 > 0) && ((v3_5 >= 0) && ((v5_0 >= 0) && ((v7_6 >= 4611686018427387904) && ((v9_3 >= 4611686018427387904) && ((v7_6 <= 4661225614328463360) && (v9_3 <= 4661225614328463360)))))))))))))) {
            android.graphics.Rect v7_8 = (v7_6 + v3_5);
            if (v7_8 <= (v11_1 + 4607182418800017408)) {
                int v9_4 = (v9_3 + v5_0);
                if (v9_4 <= (v13_1 + 4607182418800017408)) {
                    double v11_5 = ((double) v0_7);
                    android.graphics.Bitmap v0_11 = ((int) Math.ceil((v3_5 * v11_5)));
                    android.view.Window v3_10 = ((int) Math.ceil((v5_0 * v11_5)));
                    com.personal.aihub.StageCapture$3 v4_4 = (((int) Math.floor((v7_8 * v11_5))) - v0_11);
                    android.os.Handler v5_7 = (((int) Math.floor((v9_4 * v11_5))) - v3_10);
                    if ((v4_4 < 2) || ((v5_7 < 2) || ((v4_4 > 4096) || ((v5_7 > 4096) || (((v0_11 + v4_4) > (this.web.getWidth() + 1)) || ((v3_10 + v5_7) > (this.web.getHeight() + 1))))))) {
                        throw new java.io.IOException("The animation stage is outside this preview.");
                    } else {
                        android.os.Looper v6_0 = new int[2];
                        this.web.getLocationInWindow(v6_0);
                        int v8_7 = v6_0[0];
                        android.os.Looper v6_1 = v6_0[1];
                        android.graphics.Rect v7_7 = new android.graphics.Rect((v8_7 + v0_11), (v6_1 + v3_10), ((v8_7 + v0_11) + v4_4), ((v6_1 + v3_10) + v5_7));
                        android.graphics.Bitmap v0_3 = android.graphics.Bitmap.createBitmap(v4_4, v5_7, android.graphics.Bitmap$Config.ARGB_8888);
                        android.view.PixelCopy.request(this.owner.getWindow(), v7_7, v0_3, new com.personal.aihub.StageCapture$3(this, v0_3, p19), new android.os.Handler(android.os.Looper.getMainLooper()));
                        return;
                    }
                }
            }
        }
        throw new java.io.IOException("Keep the complete animation stage visible before recording.");
    }

    void m38lambda$2$compersonalaihubStageCapture(android.graphics.Bitmap p4, java.util.concurrent.CompletableFuture p5, int p6)
    {
        try {
            if (!this.closed.get()) {
                if (!p5.isDone()) {
                    if (p6 != null) {
                        StringBuilder v2_1 = new StringBuilder("The device could not capture the current animation frame (");
                        v2_1.append(p6);
                        v2_1.append(").");
                        throw new java.io.IOException(v2_1.toString());
                    } else {
                        byte[] v6_4 = new java.io.ByteArrayOutputStream();
                        if ((!p4.compress(android.graphics.Bitmap$CompressFormat.PNG, 100, v6_4)) || (v6_4.size() > 8388608)) {
                            throw new java.io.IOException("The animation snapshot exceeds8MiB.");
                        } else {
                            p5.complete(v6_4.toByteArray());
                            p4.recycle();
                            return;
                        }
                    }
                } else {
                }
            }
        } catch (byte[] v6_8) {
            p5.completeExceptionally(v6_8);
            p4.recycle();
            return;
        } catch (Throwable v5_1) {
            p4.recycle();
            throw v5_1;
        }
        p4.recycle();
        return;
    }
}
