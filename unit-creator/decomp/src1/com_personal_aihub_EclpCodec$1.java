package com.personal.aihub;
 class EclpCodec$1 extends java.io.OutputStream {
    final synthetic javax.crypto.Cipher val$cipher;
    final synthetic java.io.OutputStream val$output;

    EclpCodec$1(javax.crypto.Cipher p1, java.io.OutputStream p2)
    {
        this.val$cipher = p1;
        this.val$output = p2;
        return;
    }

    public void write(int p4)
    {
        byte[] v1 = new byte[1];
        v1[0] = ((byte) p4);
        this.write(v1, 0, 1);
        return;
    }

    public void write(byte[] p2, int p3, int p4)
    {
        byte[] v2_1 = this.val$cipher.update(p2, p3, p4);
        if (v2_1 != null) {
            this.val$output.write(v2_1);
        }
        return;
    }
}
