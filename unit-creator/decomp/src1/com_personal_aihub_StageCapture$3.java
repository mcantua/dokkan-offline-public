package com.personal.aihub;
 class StageCapture$3 implements android.view.PixelCopy$OnPixelCopyFinishedListener {
    final synthetic com.personal.aihub.StageCapture this$0;
    final synthetic android.graphics.Bitmap val$bitmapCreateBitmap;
    final synthetic java.util.concurrent.CompletableFuture val$completableFuture;

    StageCapture$3(com.personal.aihub.StageCapture p1, android.graphics.Bitmap p2, java.util.concurrent.CompletableFuture p3)
    {
        this.this$0 = p1;
        this.val$bitmapCreateBitmap = p2;
        this.val$completableFuture = p3;
        return;
    }

    public final void onPixelCopyFinished(int p4)
    {
        this.this$0.m38lambda$2$compersonalaihubStageCapture(this.val$bitmapCreateBitmap, this.val$completableFuture, p4);
        return;
    }
}
