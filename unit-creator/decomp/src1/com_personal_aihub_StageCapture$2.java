package com.personal.aihub;
 class StageCapture$2 implements android.webkit.ValueCallback {
    final synthetic com.personal.aihub.StageCapture this$0;
    final synthetic java.util.concurrent.CompletableFuture val$completableFuture;

    StageCapture$2(com.personal.aihub.StageCapture p1, java.util.concurrent.CompletableFuture p2)
    {
        this.this$0 = p1;
        this.val$completableFuture = p2;
        return;
    }

    public final void onReceiveValue(Object p3)
    {
        this.this$0.m37lambda$1$compersonalaihubStageCapture(this.val$completableFuture, ((String) p3));
        return;
    }
}
