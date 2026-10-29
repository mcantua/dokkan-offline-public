package android.database;
public interface Cursor extends java.io.Closeable { boolean moveToNext(); long getLong(int i); String getString(int i); boolean isNull(int i); void close(); }
