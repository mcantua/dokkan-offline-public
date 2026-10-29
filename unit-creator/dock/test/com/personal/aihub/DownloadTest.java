package com.personal.aihub;

import java.io.*;
import java.net.*;
import java.util.*;

public class DownloadTest {
    static Map<String, byte[]> files = new HashMap<>();
    public static void main(String[] a) throws Exception {
        files.put("/assets/x/lwf_image0.png", new byte[12345]);
        files.put("/api/card/5", "{\"found\":true}".getBytes());
        URL.setURLStreamHandlerFactory(p -> "https".equals(p) ? new URLStreamHandler() {
            protected URLConnection openConnection(URL u) {
                return new HttpURLConnection(u) {
                    byte[] body = files.get(u.getFile().split("\\?")[0]);
                    public int getResponseCode() { return body == null ? 404 : 200; }
                    public long getContentLengthLong() { return body == null ? -1 : body.length; }
                    public String getContentType() { return u.getFile().endsWith(".png") ? "image/png" : "application/json"; }
                    public InputStream getInputStream() { return new ByteArrayInputStream(body); }
                    public void connect() {} public void disconnect() {} public boolean usingProxy() { return false; }
                };
            }
        } : null);
        File root = new File(a[0]); File cacheRoot = new File(root, "preview-cache");
        long[] reserved = {0};
        OfflineLibrary.Budget budget = new OfflineLibrary.Budget() { public void reserve(long b) { reserved[0] += b; } public void release(long b) { reserved[0] -= b; } };
        System.out.println("png bytes " + OfflineLibrary.download(cacheRoot, "https://dokkan-eclipse.com/assets/x/lwf_image0.png", 1 << 20, budget));
        System.out.println("again " + OfflineLibrary.download(cacheRoot, "https://dokkan-eclipse.com/assets/x/lwf_image0.png", 1 << 20, budget));
        System.out.println("json " + OfflineLibrary.download(cacheRoot, "https://dokkan-eclipse.com/api/card/5", 1 << 20, budget));
        try { OfflineLibrary.download(cacheRoot, "https://dokkan-eclipse.com/assets/missing.png", 1 << 20, budget); } catch (OfflineLibrary.MissingException e) { System.out.println("404 -> missing ok"); }
        try { OfflineLibrary.download(cacheRoot, "https://dokkan-eclipse.com/assets/x/lwf_image0.png?v=2", 100, budget); } catch (IOException e) { System.out.println("limit -> " + e.getMessage()); }
        PreviewCache cache = new PreviewCache(root);
        File body = cache.cachedBody("https://dokkan-eclipse.com/assets/x/lwf_image0.png");
        System.out.println("player sees body " + (body != null ? body.length() : -1) + ", reserved " + reserved[0]);
        System.out.println("settings " + cache.settings(new org.json.JSONObject()));
        System.out.println("leftovers " + Arrays.toString(cacheRoot.list((d, n) -> n.contains("part"))));
    }
}
