package com.personal.aihub;
 class StageExport$2 implements java.lang.Runnable {
    final synthetic com.personal.aihub.StageExport this$0;
    final synthetic android.net.Uri val$data;
    final synthetic java.io.File val$file;

    StageExport$2(com.personal.aihub.StageExport p1, java.io.File p2, android.net.Uri p3)
    {
        this.this$0 = p1;
        this.val$file = p2;
        this.val$data = p3;
        return;
    }

    public final void run()
    {
        this.this$0.m40lambda$1$compersonalaihubStageExport(this.val$file, this.val$data);
        return;
    }
}
