package com.personal.aihub;
 class PreviewCache$1 extends java.io.FilterInputStream {
    long left;
    final synthetic com.personal.aihub.PreviewCache this$0;
    final synthetic long val$length;

    PreviewCache$1(com.personal.aihub.PreviewCache p1, java.io.InputStream p2, long p3)
    {
        this.this$0 = p1;
        this.val$length = p3;
        super(p2);
        super.left = p3;
        return;
    }

    public int read()
    {
        if (this.left > 0) {
            int v0_2 = super.read();
            if (v0_2 != -1) {
                this.left = (this.left - 1);
            }
            return v0_2;
        } else {
            return -1;
        }
    }

    public int read(byte[] p6, int p7, int p8)
    {
        if (p8 != 0) {
            if (this.left > 0) {
                int v6_1 = this.in.read(p6, p7, ((int) Math.min(((long) p8), this.left)));
                if (v6_1 > 0) {
                    this.left = (this.left - ((long) v6_1));
                }
                return v6_1;
            } else {
                return -1;
            }
        } else {
            return 0;
        }
    }
}
