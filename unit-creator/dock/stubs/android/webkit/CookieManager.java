package android.webkit;
public abstract class CookieManager { public static CookieManager getInstance(){return null;} public abstract void setCookie(String u, String v, ValueCallback<Boolean> cb); }
