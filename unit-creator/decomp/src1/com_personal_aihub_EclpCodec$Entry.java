package com.personal.aihub;
public final class EclpCodec$Entry {
    public java.io.File file;
    public String path;
    public byte[] text;

    public EclpCodec$Entry(String p1, java.io.File p2, byte[] p3)
    {
        this.path = p1;
        this.file = p2;
        this.text = p3;
        return;
    }

    java.io.InputStream input()
    {
        java.io.FileInputStream v0_2;
        if (this.file != null) {
            v0_2 = new java.io.FileInputStream(this.file);
        } else {
            v0_2 = new java.io.ByteArrayInputStream(this.text);
        }
        return v0_2;
    }

    long size()
    {
        long v0_1;
        long v0_0 = this.file;
        if (v0_0 != 0) {
            v0_1 = v0_0.length();
        } else {
            v0_1 = ((long) this.text.length);
        }
        return v0_1;
    }
}
