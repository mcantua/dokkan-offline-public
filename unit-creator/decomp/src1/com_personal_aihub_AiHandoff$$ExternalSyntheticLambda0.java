package com.personal.aihub;
public final synthetic class AiHandoff$$ExternalSyntheticLambda0 implements java.lang.Runnable {
    public final synthetic android.app.Activity f$0;
    public final synthetic String f$1;
    public final synthetic com.personal.aihub.Provider f$2;
    public final synthetic java.util.concurrent.atomic.AtomicReference f$3;
    public final synthetic java.util.concurrent.atomic.AtomicReference f$4;
    public final synthetic java.util.concurrent.CountDownLatch f$5;

    public synthetic AiHandoff$$ExternalSyntheticLambda0(android.app.Activity p1, String p2, com.personal.aihub.Provider p3, java.util.concurrent.atomic.AtomicReference p4, java.util.concurrent.atomic.AtomicReference p5, java.util.concurrent.CountDownLatch p6)
    {
        this.f$0 = p1;
        this.f$1 = p2;
        this.f$2 = p3;
        this.f$3 = p4;
        this.f$4 = p5;
        this.f$5 = p6;
        return;
    }

    public final void run()
    {
        com.personal.aihub.AiHandoff.lambda$compose$0(this.f$0, this.f$1, this.f$2, this.f$3, this.f$4, this.f$5);
        return;
    }
}
