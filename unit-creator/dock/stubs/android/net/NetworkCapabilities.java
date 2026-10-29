package android.net;
public class NetworkCapabilities { public static final int TRANSPORT_WIFI = 1; public static final int TRANSPORT_ETHERNET = 3; public static final int NET_CAPABILITY_INTERNET = 12; public static final int NET_CAPABILITY_NOT_METERED = 11;
  public boolean hasTransport(int t){return false;} public boolean hasCapability(int c){return false;} }
