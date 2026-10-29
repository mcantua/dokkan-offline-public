package com.personal.aihub;

import android.content.Context;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;

/**
 * Prepared game movies, kept on the phone. A game movie (.usm) has to be converted into a video
 * the phone can play before it shows in a preview, which takes a while on a phone. The player used
 * to throw that work away when the preview closed, so every preview converted the same movie
 * again, even when the movie itself was downloaded. Now the converted video is kept here
 * (files/forge/movie-cache, at most 3 GB, oldest first out) and reused the next time.
 *
 * Only the in-app player's own local page can use it, through two GET addresses that never reach
 * the network (the player's WebView answers them here):
 *   /_forge/movie-cache/KEY.mp4            the kept video, or 404
 *   /_forge/movie-cache/keep/KEY/ID.mp4    keep the video the player just prepared (ID) as KEY
 * KEY is the SHA-256 of the original movie file plus the output kind, e.g. "<64 hex>-h".
 */
final class MovieCache {
    private static final long LIMIT = 3L * 1024 * 1024 * 1024;
    private static final long KEEP_FREE = 512L * 1024 * 1024;
    private static final String KEY = "[a-f0-9]{64}-[a-z]{1,4}";

    private MovieCache() {}

    static File folder(Context context) {
        return new File(new File(context.getFilesDir(), "forge"), "movie-cache");
    }

    static WebResourceResponse handle(Context context, Object server, WebResourceRequest request) {
        try {
            if (!"GET".equals(request.getMethod())) return reply(405, "{}");
            String path = request.getUrl().getPath();
            if (path == null || request.getUrl().toString().indexOf('?') >= 0) return reply(404, "{}");
            String rest = path.substring("/_forge/movie-cache/".length());
            File dir = folder(context);
            if (rest.matches(KEY + "\\.mp4")) {
                File file = new File(dir, rest);
                if (!file.isFile() || file.length() < 12) return reply(404, "{}");
                file.setLastModified(System.currentTimeMillis());
                Map<String, String> headers = new HashMap<String, String>();
                headers.put("Cache-Control", "no-store");
                headers.put("Content-Length", String.valueOf(file.length()));
                return new WebResourceResponse("video/mp4", null, 200, "OK", headers, new FileInputStream(file));
            }
            if (rest.matches("keep/" + KEY + "/[a-f0-9]{32}\\.mp4")) {
                String[] parts = rest.split("/");
                File source = preparedFile(server, parts[2]);
                if (source == null || !source.isFile() || source.length() < 12) return reply(404, "{}");
                dir.mkdirs();
                File target = new File(dir, parts[1] + ".mp4");
                if (target.isFile() && target.length() == source.length()) return reply(200, "{\"kept\":true}");
                if (dir.getUsableSpace() - source.length() < KEEP_FREE) return reply(507, "{\"kept\":false}");
                File part = new File(dir, parts[1] + ".part");
                InputStream in = new FileInputStream(source);
                FileOutputStream out = new FileOutputStream(part);
                try {
                    byte[] buffer = new byte[65536];
                    int n;
                    while ((n = in.read(buffer)) != -1) out.write(buffer, 0, n);
                } finally {
                    in.close();
                    out.close();
                }
                if (!part.renameTo(target)) { part.delete(); return reply(500, "{\"kept\":false}"); }
                trim(dir, target);
                return reply(200, "{\"kept\":true}");
            }
            return reply(404, "{}");
        } catch (Throwable t) {
            return reply(500, "{}");
        }
    }

    /** The player server keeps the videos it prepared for this preview in a private map. */
    private static File preparedFile(Object server, String id) throws Exception {
        if (server == null) return null;
        java.lang.reflect.Field field = server.getClass().getDeclaredField("movies");
        field.setAccessible(true);
        Object map = field.get(server);
        if (!(map instanceof Map)) return null;
        synchronized (server) {
            Object file = ((Map<?, ?>) map).get(id);
            return file instanceof File ? (File) file : null;
        }
    }

    /** Oldest videos go first once the folder is over its limit. */
    private static void trim(File dir, File keep) {
        File[] files = dir.listFiles();
        if (files == null) return;
        long total = 0;
        for (File f : files) total += f.length();
        if (total <= LIMIT) return;
        Arrays.sort(files, new Comparator<File>() {
            public int compare(File a, File b) { return Long.compare(a.lastModified(), b.lastModified()); }
        });
        for (File f : files) {
            if (total <= LIMIT) break;
            if (f.equals(keep)) continue;
            long size = f.length();
            if (f.delete()) total -= size;
        }
    }

    private static WebResourceResponse reply(int status, String json) {
        Map<String, String> headers = new HashMap<String, String>();
        headers.put("Cache-Control", "no-store");
        String reason = status == 200 ? "OK" : status == 404 ? "Not Found" : status == 405 ? "Method Not Allowed" : status == 507 ? "Insufficient Storage" : "Error";
        return new WebResourceResponse("application/json", "UTF-8", status, reason, headers, new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8)));
    }
}
