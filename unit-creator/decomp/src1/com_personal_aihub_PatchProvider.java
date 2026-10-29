package com.personal.aihub;
public final class PatchProvider extends android.content.ContentProvider {

    public PatchProvider()
    {
        return;
    }

    private java.io.File file(android.net.Uri p8)
    {
        java.io.File v0_1 = new StringBuilder();
        v0_1.append(this.getContext().getPackageName());
        v0_1.append(".patch");
        if ((!v0_1.toString().equals(p8.getAuthority())) || ((p8.getPathSegments().size() != 2) || ((!((String) p8.getPathSegments().get(0)).matches("[a-f0-9-]{36}")) || (!"unit-patch.zip".equals(p8.getLastPathSegment()))))) {
            throw new java.io.FileNotFoundException();
        } else {
            java.io.File v0_13 = new java.io.File(new java.io.File(new java.io.File(this.getContext().getCacheDir(), "converter"), ((String) p8.getPathSegments().get(0))), "unit-patch.zip");
            if (!v0_13.isFile()) {
                throw new java.io.FileNotFoundException();
            } else {
                return v0_13;
            }
        }
    }

    public int delete(android.net.Uri p1, String p2, String[] p3)
    {
        throw new UnsupportedOperationException();
    }

    public String getType(android.net.Uri p1)
    {
        return "application/zip";
    }

    public android.net.Uri insert(android.net.Uri p1, android.content.ContentValues p2)
    {
        throw new UnsupportedOperationException();
    }

    public boolean onCreate()
    {
        return 1;
    }

    public android.os.ParcelFileDescriptor openFile(android.net.Uri p2, String p3)
    {
        if (!"r".equals(p3)) {
            throw new java.io.FileNotFoundException("Read-only patch");
        } else {
            return android.os.ParcelFileDescriptor.open(this.file(p2), 268435456);
        }
    }

    public android.database.Cursor query(android.net.Uri p5, String[] p6, String p7, String[] p8, String p9)
    {
        try {
            int v5_1 = this.file(p5);
        } catch (Exception) {
            return 0;
        }
        if (p6 == null) {
            p6 = new String[] {"_display_name", "_size"});
        }
        android.database.MatrixCursor v9_1 = new android.database.MatrixCursor(p6);
        Object[] v0_0 = new Object[p6.length];
        int v1 = 0;
        while (v1 < p6.length) {
            if (!"_display_name".equals(p6[v1])) {
                if ("_size".equals(p6[v1])) {
                    v0_0[v1] = Long.valueOf(v5_1.length());
                }
            } else {
                v0_0[v1] = v5_1.getName();
            }
            v1++;
        }
        v9_1.addRow(v0_0);
        return v9_1;
    }

    public int update(android.net.Uri p1, android.content.ContentValues p2, String p3, String[] p4)
    {
        throw new UnsupportedOperationException();
    }
}
