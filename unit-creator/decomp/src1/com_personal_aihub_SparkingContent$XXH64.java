package com.personal.aihub;
final class SparkingContent$XXH64 {
    private static final long P1 = 11400714785074694791;
    private static final long P2 = 14029467366897019727;
    private static final long P3 = 1609587929392839161;
    private static final long P4 = 9650029242287828579;
    private static final long P5 = 2870177450012600261;
    private final byte[] pending;
    private long total;
    private int used;
    private long v1;
    private long v2;
    private long v3;
    private long v4;

    SparkingContent$XXH64()
    {
        this.v1 = 6983438078262162902;
        this.v2 = -4417276706812531889;
        this.v3 = 0;
        this.v4 = 7046029288634856825;
        byte[] v0_1 = new byte[32];
        this.pending = v0_1;
        return;
    }

    private void block(byte[] p5, int p6)
    {
        this.v1 = com.personal.aihub.SparkingContent$XXH64.round(this.v1, com.personal.aihub.SparkingContent$XXH64.read64(p5, p6));
        this.v2 = com.personal.aihub.SparkingContent$XXH64.round(this.v2, com.personal.aihub.SparkingContent$XXH64.read64(p5, (p6 + 8)));
        this.v3 = com.personal.aihub.SparkingContent$XXH64.round(this.v3, com.personal.aihub.SparkingContent$XXH64.read64(p5, (p6 + 16)));
        this.v4 = com.personal.aihub.SparkingContent$XXH64.round(this.v4, com.personal.aihub.SparkingContent$XXH64.read64(p5, (p6 + 24)));
        return;
    }

    private static long merge(long p2, long p4)
    {
        return (((p2 ^ com.personal.aihub.SparkingContent$XXH64.round(0, p4)) * -7046029288634856825) + -8796714831421723037);
    }

    private static long read32(byte[] p7, int p8)
    {
        return (((((long) p7[(p8 + 3)]) & 255) << 24) | (((((long) p7[p8]) & 255) | ((((long) p7[(p8 + 1)]) & 255) << 8)) | ((((long) p7[(p8 + 2)]) & 255) << 16)));
    }

    private static long read64(byte[] p7, int p8)
    {
        long v0 = 0;
        int v2 = 0;
        while (v2 < 8) {
            v0 |= ((((long) p7[(p8 + v2)]) & 255) << (v2 * 8));
            v2++;
        }
        return v0;
    }

    private static long round(long p2, long p4)
    {
        return (Long.rotateLeft((p2 + (p4 * -4417276706812531889)), 31) * -7046029288634856825);
    }

    void update(byte[] p6, int p7, int p8)
    {
        if ((p7 < 0) || ((p8 < 0) || (p7 > (p6.length - p8)))) {
            throw new IndexOutOfBoundsException();
        } else {
            this.total = (this.total + ((long) p8));
            byte[] v0_1 = this.used;
            if ((v0_1 + p8) >= 32) {
                if (v0_1 > null) {
                    int v3 = (32 - v0_1);
                    System.arraycopy(p6, p7, this.pending, v0_1, v3);
                    this.block(this.pending, 0);
                    p7 += v3;
                    p8 -= v3;
                    this.used = 0;
                }
                while (p8 >= 32) {
                    this.block(p6, p7);
                    p7 += 32;
                    p8 -= 32;
                }
                if (p8 > 0) {
                    System.arraycopy(p6, p7, this.pending, 0, p8);
                    this.used = p8;
                }
                return;
            } else {
                System.arraycopy(p6, p7, this.pending, v0_1, p8);
                this.used = (this.used + p8);
                return;
            }
        }
    }

    long value()
    {
        long v4_7;
        if (this.total < 32) {
            v4_7 = 2870177450012600261;
        } else {
            v4_7 = com.personal.aihub.SparkingContent$XXH64.merge(com.personal.aihub.SparkingContent$XXH64.merge(com.personal.aihub.SparkingContent$XXH64.merge(com.personal.aihub.SparkingContent$XXH64.merge((((Long.rotateLeft(this.v1, 1) + Long.rotateLeft(this.v2, 7)) + Long.rotateLeft(this.v3, 12)) + Long.rotateLeft(this.v4, 18)), this.v1), this.v2), this.v3), this.v4);
        }
        long v4_8 = (v4_7 + this.total);
        long v1_1 = 0;
        while(true) {
            byte[] v6_11 = (v1_1 + 8);
            int v7_0 = this.used;
            if (v6_11 > v7_0) {
                break;
            }
            v4_8 = ((Long.rotateLeft((v4_8 ^ com.personal.aihub.SparkingContent$XXH64.round(0, com.personal.aihub.SparkingContent$XXH64.read64(this.pending, v1_1))), 27) * -7046029288634856825) + -8796714831421723037);
            v1_1 = v6_11;
        }
        byte[] v6_12 = (v1_1 + 4);
        if (v6_12 <= v7_0) {
            v4_8 = ((Long.rotateLeft((v4_8 ^ (com.personal.aihub.SparkingContent$XXH64.read32(this.pending, v1_1) * -7046029288634856825)), 23) * -4417276706812531889) + 1609587929392839161);
            v1_1 = v6_12;
        }
        while (v1_1 < this.used) {
            int v7_2 = (v1_1 + 1);
            v4_8 = (Long.rotateLeft((v4_8 ^ ((((long) this.pending[v1_1]) & 255) * 2870177450012600261)), 11) * -7046029288634856825);
            v1_1 = v7_2;
        }
        long v1_10 = (((v4_8 >> 33) ^ v4_8) * -4417276706812531889);
        long v1_12 = ((v1_10 ^ (v1_10 >> 29)) * 1609587929392839161);
        return (v1_12 ^ (v1_12 >> 32));
    }
}
