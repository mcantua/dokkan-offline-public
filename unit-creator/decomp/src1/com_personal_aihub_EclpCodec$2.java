package com.personal.aihub;
 class EclpCodec$2 extends java.io.InputStream {
    final synthetic java.io.BufferedInputStream val$input;
    final synthetic long[] val$remaining;

    EclpCodec$2(long[] p1, java.io.BufferedInputStream p2)
    {
        this.val$remaining = p1;
        this.val$input = p2;
        return;
    }

    public void close()
    {
        return;
    }

    public int read()
    {
        if (this.val$remaining[0] != 0) {
            java.io.EOFException v0_6 = this.val$input.read();
            if (v0_6 < null) {
                throw new java.io.EOFException();
            } else {
                long[] v2_0 = this.val$remaining;
                v2_0[0] = (v2_0[0] - 1);
                return v0_6;
            }
        } else {
            return -1;
        }
    }

    public int read(byte[] p7, int p8, int p9)
    {
        if (p9 != 0) {
            long v2_1 = this.val$remaining[0];
            if (v2_1 != 0) {
                java.io.EOFException v7_1 = this.val$input.read(p7, p8, ((int) Math.min(((long) p9), v2_1)));
                if (v7_1 < null) {
                    throw new java.io.EOFException();
                } else {
                    long[] v8_1 = this.val$remaining;
                    v8_1[0] = (v8_1[0] - ((long) v7_1));
                    return v7_1;
                }
            } else {
                return -1;
            }
        } else {
            return 0;
        }
    }
}
