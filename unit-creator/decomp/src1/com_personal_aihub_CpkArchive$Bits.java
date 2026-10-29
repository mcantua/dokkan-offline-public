package com.personal.aihub;
final class CpkArchive$Bits {
    final byte[] bytes;
    int cache;
    int pool;
    int source;

    CpkArchive$Bits(byte[] p1, int p2)
    {
        this.bytes = p1;
        this.source = p2;
        return;
    }

    int take(int p7)
    {
        int v0_0 = 0;
        while (p7 > null) {
            if (this.pool == 0) {
                int v1_6 = this.source;
                if (v1_6 < 16) {
                    throw com.personal.aihub.CpkArchive.error("Truncated CRILAYLA bit stream");
                } else {
                    byte[] v2_0 = this.bytes;
                    this.source = (v1_6 - 1);
                    this.cache = (v2_0[v1_6] & 255);
                    this.pool = 8;
                }
            }
            int v1_4 = Math.min(p7, this.pool);
            int v3_1 = this.pool;
            v0_0 = ((v0_0 << v1_4) | ((this.cache >> (v3_1 - v1_4)) & ((int v4_1 << v1_4) - 1)));
            this.pool = (v3_1 - v1_4);
            p7 -= v1_4;
        }
        return v0_0;
    }
}
