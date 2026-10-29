package com.personal.aihub;
 class PreviewResources$1 extends java.io.FilterInputStream {
    long remaining;
    final synthetic long val$j3;

    PreviewResources$1(java.io.InputStream p1, long p2)
    {
        this.val$j3 = p2;
        super(p1);
        super.remaining = p2;
        return;
    }

    public int read()
    {
        if (this.remaining > 0) {
            int v0_3 = super.read();
            if (v0_3 >= 0) {
                this.remaining = (this.remaining - 1);
            }
            return v0_3;
        } else {
            return -1;
        }
    }

    public int read(byte[] p6, int p7, int p8)
    {
        if (p8 != 0) {
            if (this.remaining > 0) {
                int v6_1 = this.in.read(p6, p7, ((int) Math.min(((long) p8), this.remaining)));
                if (v6_1 > 0) {
                    this.remaining = (this.remaining - ((long) v6_1));
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
