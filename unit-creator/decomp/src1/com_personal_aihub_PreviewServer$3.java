package com.personal.aihub;
 class PreviewServer$3 implements java.lang.Runnable {
    final synthetic com.personal.aihub.PreviewServer this$0;
    final synthetic java.net.Socket val$socketAccept;

    PreviewServer$3(com.personal.aihub.PreviewServer p1, java.net.Socket p2)
    {
        this.this$0 = p1;
        this.val$socketAccept = p2;
        return;
    }

    public final void run()
    {
        this.this$0.m34lambda$2$compersonalaihubPreviewServer(this.val$socketAccept);
        return;
    }
}
