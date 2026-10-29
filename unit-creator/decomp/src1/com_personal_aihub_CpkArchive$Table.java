package com.personal.aihub;
final class CpkArchive$Table {
    final byte[] b;
    final java.nio.ByteBuffer be;
    final int data;
    final int length;
    final int rows;
    final int strings;

    CpkArchive$Table(byte[] p13)
    {
        java.io.IOException v13_6 = ((byte[]) p13.clone());
        this.b = v13_6;
        if ((v13_6.length < 4) || (!new String(v13_6, 0, 4, java.nio.charset.StandardCharsets.US_ASCII).equals("@UTF"))) {
            java.io.IOException v13_2 = 95;
            int v0_2 = 0;
            while(true) {
                byte[] v4_1 = this.b;
                if (v0_2 >= v4_1.length) {
                    break;
                }
                v4_1[v0_2] = ((byte) (v4_1[v0_2] ^ ((byte) v13_2)));
                v13_2 = ((v13_2 * 16661) & 255);
                v0_2++;
            }
        }
        java.io.IOException v13_4 = this.b;
        if ((v13_4.length < 32) || (!new String(v13_4, 0, 4, java.nio.charset.StandardCharsets.US_ASCII).equals("@UTF"))) {
            throw com.personal.aihub.CpkArchive.error("Unsupported table signature");
        } else {
            this.be = java.nio.ByteBuffer.wrap(this.b).order(java.nio.ByteOrder.BIG_ENDIAN);
            int v0_8 = (this.u32(4) + 8);
            com.personal.aihub.CpkArchive.range(0, v0_8, ((long) this.b.length), "UTF table");
            java.io.IOException v13_14 = ((int) v0_8);
            this.length = v13_14;
            int v0_13 = this.position((this.u32(8) + 8));
            this.rows = v0_13;
            int v1_2 = this.position((this.u32(12) + 8));
            this.strings = v1_2;
            int v2_2 = this.position((this.u32(16) + 8));
            this.data = v2_2;
            if ((v0_13 < 32) || ((v1_2 < v0_13) || ((v2_2 < v1_2) || (v2_2 > v13_14)))) {
                throw com.personal.aihub.CpkArchive.error("Invalid table layout");
            } else {
                return;
            }
        }
    }

    int position(long p3)
    {
        if (p3 > 2147483647) {
            throw com.personal.aihub.CpkArchive.error("Invalid UTF position");
        } else {
            return ((int) p3);
        }
    }

    String string(long p10)
    {
        String[] v0_3 = (((long) this.strings) + p10);
        com.personal.aihub.CpkArchive.range(v0_3, 1, ((long) this.data), "UTF string");
        java.io.IOException v10_6 = ((int) v0_3);
        int v11 = v10_6;
        while(true) {
            String[] v0_2 = this.data;
            if ((v11 >= v0_2) || (this.b[v11] == 0)) {
                break;
            }
            v11++;
        }
        if (v11 == v0_2) {
            throw com.personal.aihub.CpkArchive.error("Unterminated UTF string");
        } else {
            int v1_3 = 0;
            while (v1_3 < 2) {
                try {
                    v10_6 = java.nio.charset.Charset.forName(new String[] {"UTF-8", "Shift_JIS"})[v1_3]).newDecoder().onMalformedInput(java.nio.charset.CodingErrorAction.REPORT).onUnmappableCharacter(java.nio.charset.CodingErrorAction.REPORT).decode(java.nio.ByteBuffer.wrap(this.b, v10_6, (v11 - v10_6))).toString();
                    return v10_6;
                } catch (java.nio.charset.CharacterCodingException) {
                    v1_3++;
                }
            }
            throw com.personal.aihub.CpkArchive.error("Unsupported filename encoding");
        }
    }

    long u32(int p8)
    {
        com.personal.aihub.CpkArchive.range(((long) p8), 4, ((long) this.b.length), "UTF number");
        return (((long) this.be.getInt(p8)) & 4294967295);
    }

    Object value(int p12, int p13, int p14)
    {
        int[] v1 = new int[12];
        v1 = {1, 1, 2, 2, 4, 4, 8, 8, 4, 8, 4, 8};
        if (p12 >= 12) {
            throw com.personal.aihub.CpkArchive.error("Unsupported UTF column type");
        } else {
            com.personal.aihub.CpkArchive.range(((long) p13), ((long) v1[p12]), ((long) p14), "UTF value");
            switch (p12) {
                case 0:
                    return Long.valueOf(((long) (this.b[p13] & 255)));
                case 1:
                    return Long.valueOf(((long) this.b[p13]));
                case 2:
                    return Long.valueOf(((long) (this.be.getShort(p13) & 65535)));
                case 3:
                    return Long.valueOf(((long) this.be.getShort(p13)));
                case 4:
                    return Long.valueOf(this.u32(p13));
                case 5:
                    return Long.valueOf(((long) this.be.getInt(p13)));
                case 6:
                    return Long.valueOf(com.personal.aihub.CpkArchive.u64(this.b, p13, 0));
                case 7:
                    Long v12_30 = this.be.getLong(p13);
                    if ((v12_30 < -9007199254740991) || (v12_30 > 9007199254740991)) {
                        throw com.personal.aihub.CpkArchive.error("64-bit value exceeds safe range");
                    } else {
                        return Long.valueOf(v12_30);
                    }
                case 8:
                    return Double.valueOf(((double) this.be.getFloat(p13)));
                case 9:
                    return Double.valueOf(this.be.getDouble(p13));
                case 10:
                    return this.string(this.u32(p13));
                case 11:
                    long v0_2 = (((long) this.data) + this.u32(p13));
                    Long v12_16 = this.u32((p13 + 4));
                    com.personal.aihub.CpkArchive.range(v0_2, v12_16, ((long) this.length), "UTF byte data");
                    return java.util.Arrays.copyOfRange(this.b, ((int) v0_2), ((int) (v0_2 + v12_16)));
                default:
                    throw com.personal.aihub.CpkArchive.error("Unsupported UTF type");
            }
        }
    }
}
