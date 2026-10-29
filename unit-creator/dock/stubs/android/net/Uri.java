package android.net;
public abstract class Uri { public static Uri parse(String s){return null;} public static Uri fromFile(java.io.File f){return null;} public abstract String getPath(); public abstract String getHost(); public abstract String getScheme(); public abstract String getQueryParameter(String k); }
