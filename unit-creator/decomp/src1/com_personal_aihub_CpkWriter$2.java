package com.personal.aihub;
 class CpkWriter$2 implements java.util.Comparator {

    CpkWriter$2()
    {
        return;
    }

    public final int compare(Object p1, Object p2)
    {
        return com.personal.aihub.CpkWriter.compareCriPaths(((com.personal.aihub.CpkWriter$Source) p1).path, ((com.personal.aihub.CpkWriter$Source) p2).path);
    }
}
