package com.personal.aihub;
public final class CpkArchive$Entry {
    public final long offset;
    public final String path;
    public final int size;
    public final int storedSize;

    public CpkArchive$Entry(String p1, long p2, int p4, int p5)
    {
        this.path = p1;
        this.offset = p2;
        this.storedSize = p4;
        this.size = p5;
        return;
    }
}
