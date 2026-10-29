package com.personal.aihub;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Method;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.json.JSONArray;
import org.json.JSONObject;

/**
 * "Offline downloads": saves Eclipse resources on the phone ahead of time so animations and
 * pictures open without waiting. Files go into the same preview cache the player already
 * reads (forge/preview-cache, keyed exactly like PreviewCache), and animation scripts into
 * the same animation-sources folder the editor reads, so nothing else needs to change.
 *
 * Packs:
 *   essentials  - animation player, every animation script, every character picture
 *   units       - artwork, effects and sounds for the characters in your units
 *   everything  - artwork for every character and every animation effect (+ movies, optional)
 *
 * Downloads run on four background threads, can be paused, resumed or cancelled, wait for
 * Wi-Fi when "Wi-Fi only" is on, skip files already saved, and raise the preview storage
 * limit as needed (up to 32 GB) while keeping some free space on the phone.
 */
final class OfflineLibrary {
    private static final String ORIGIN = "https://dokkan-eclipse.com";
    private static final String PREFS = "forge-offline";
    private static final long KEEP_FREE = 400L * 1024 * 1024;
    private static final long MAX_FILE = 167772160L;
    private static final long[] BUDGETS = {536870912L, 1073741824L, 2147483648L, 4294967296L, 8589934592L, 17179869184L, 34359738368L};
    private static final Pattern CONSTANT = Pattern.compile("(?m)^\\s*([A-Za-z_]\\w*)\\s*=\\s*(\\d{1,9})\\s*;?");
    private static final Pattern EFFECT_CALL = Pattern.compile("entryEffect\\w*\\s*\\(([^,()]*(?:\\([^()]*\\))?[^,()]*),\\s*([A-Za-z_]\\w*|\\d{1,9})");
    private static final Pattern MOVIE_CALL = Pattern.compile("setupMovie\\s*\\(([^,()]*(?:\\([^()]*\\))?[^,()]*),\\s*([A-Za-z_]\\w*|\\d{1,9})");
    private static final Pattern SOUND_CALL = Pattern.compile("playSe\\w*\\s*\\(([^,()]*(?:\\([^()]*\\))?[^,()]*),\\s*([A-Za-z_]\\w*|\\d{1,9})");

    private static Job job;
    private static volatile Method normalizer;
    private static volatile long storageCheckedAt;
    private static volatile JSONObject storageCache;
    private static final ThreadPoolExecutor SAVER = new ThreadPoolExecutor(1, 1, 30, TimeUnit.SECONDS, new LinkedBlockingQueue<Runnable>(300));
    private static final Set<String> QUEUED = Collections.newSetFromMap(new ConcurrentHashMap<String, Boolean>());

    private OfflineLibrary() {}

    // ------------------------------------------------------------------ bridge

    static synchronized JSONObject dispatch(Activity activity, File root, JSONObject args) throws Exception {
        if (activity == null) throw new IOException("Offline downloads are not ready yet. Try again in a moment.");
        Context context = activity.getApplicationContext() != null ? activity.getApplicationContext() : activity;
        String action = args.optString("action", "status");
        SharedPreferences prefs = context.getSharedPreferences(PREFS, 0);
        if ("start".equals(action)) {
            if (job != null && !job.finished) throw new IOException("A download is already running. Pause or cancel it first.");
            JSONArray packs = args.optJSONArray("packs");
            if (packs == null || packs.length() == 0) throw new IOException("Choose what to download.");
            boolean wifiOnly = args.optBoolean("wifiOnly", true);
            prefs.edit().putBoolean("wifiOnly", wifiOnly).putBoolean("movies", args.optBoolean("movies", false)).commit();
            job = new Job(context, root, args, wifiOnly);
            // remembered until it finishes: if Android closes the app mid-way, it continues on the next open
            prefs.edit().putString("pending", args.toString()).commit();
            launch(activity);
        } else if (job == null && "status".equals(action) && prefs.getString("pending", null) != null) {
            // the last download was interrupted (Android closed the app): pick it up where it stopped
            try {
                JSONObject pending = new JSONObject(prefs.getString("pending", "{}"));
                pending.put("tidy", false);
                job = new Job(context, root, pending, prefs.getBoolean("wifiOnly", true));
                job.resumed = true;
                launch(activity);
            } catch (Exception e) {
                prefs.edit().remove("pending").commit();
            }
        } else if ("pause".equals(action) && job != null) {
            job.paused = true;
        } else if ("resume".equals(action) && job != null) {
            job.paused = false;
        } else if ("cancel".equals(action) && job != null) {
            job.cancelled = true;
            job.paused = false;
        } else if ("wifiOnly".equals(action)) {
            boolean value = args.optBoolean("value", true);
            prefs.edit().putBoolean("wifiOnly", value).commit();
            if (job != null) job.wifiOnly = value;
            if (!value) bindWifi(context, null);
        }
        if (job != null && job.finished) keepScreenOn(activity, false);
        return status(context, root, prefs);
    }

    private static void launch(Activity activity) {
        Thread thread = new Thread(job, "forge-offline-downloads");
        thread.setDaemon(true);
        thread.start();
        keepScreenOn(activity, true);
        DownloadService.start(activity);       // keeps going with the screen off or in another app
    }

    static Job currentJob() { return job; }

    private static void keepScreenOn(final Activity activity, final boolean on) {
        try {
            activity.runOnUiThread(new Runnable() {
                public void run() {
                    try {
                        if (on) activity.getWindow().addFlags(128); else activity.getWindow().clearFlags(128);
                    } catch (Throwable ignored) {}
                }
            });
        } catch (Throwable ignored) {}
    }

    private static JSONObject status(Context context, File root, SharedPreferences prefs) throws Exception {
        JSONObject out = new JSONObject();
        Job j = job;
        out.put("wifiOnly", prefs.getBoolean("wifiOnly", true)).put("movies", prefs.getBoolean("movies", false));
        JSONObject completed;
        try { completed = new JSONObject(prefs.getString("completed", "{}")); } catch (Exception e) { completed = new JSONObject(); }
        out.put("completed", completed);
        out.put("network", network(context));
        if (j != null) {
            out.put("job", new JSONObject().put("running", !j.finished).put("paused", j.paused).put("cancelled", j.cancelled)
                    .put("finished", j.finished).put("phase", j.phase).put("label", j.label).put("waiting", j.waiting)
                    .put("total", j.total.get()).put("done", j.done.get()).put("failed", j.failed.get()).put("skipped", j.skipped.get())
                    .put("savedBytes", j.savedBytes.get()).put("error", j.error).put("packs", j.packs).put("startedAt", j.startedAt)
                    .put("finishedAt", j.finishedAt).put("failures", new JSONArray(j.failures()))
                    .put("cleanup", j.cleanup == null ? JSONObject.NULL : j.cleanup).put("originalsSkipped", j.original.get()).put("resumed", j.resumed));
        }
        out.put("storage", storage(root, j));
        out.put("folder", PublicStorage.label());
        return out;
    }

    private static JSONObject storage(File root, Job j) {
        try {
            long now = System.currentTimeMillis();
            JSONObject cached = storageCache;
            if (j != null && !j.finished && j.limit > 0) {
                return new JSONObject().put("bytes", j.used).put("maxBytes", j.limit).put("free", root.getUsableSpace());
            }
            if (cached == null || now - storageCheckedAt > 15000) {
                storageCheckedAt = now;
                final File cacheRoot = new File(root, "preview-cache");
                final long limit = readLimit(root);
                Thread scan = new Thread(new Runnable() {
                    public void run() {
                        try {
                            long total = 0, count = 0;
                            File[] files = cacheRoot.listFiles();
                            if (files != null) for (File f : files) if (f.getName().endsWith(".body")) { total += f.length(); count++; }
                            storageCache = new JSONObject().put("bytes", total).put("count", count).put("maxBytes", limit);
                        } catch (Throwable ignored) {}
                    }
                }, "forge-offline-usage");
                scan.setDaemon(true);
                scan.start();
                if (cached == null) cached = new JSONObject().put("maxBytes", limit);
            }
            return new JSONObject(cached.toString()).put("free", root.getUsableSpace());
        } catch (Exception e) {
            return new JSONObject();
        }
    }

    private static JSONObject network(Context context) {
        JSONObject out = new JSONObject();
        try {
            ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            NetworkInfo info = cm == null ? null : cm.getActiveNetworkInfo();
            out.put("connected", info != null && info.isConnected());
            out.put("metered", cm != null && cm.isActiveNetworkMetered());
            out.put("wifi", wifiNetwork(context) != null);
        } catch (Throwable t) {
            try { out.put("unknown", true); } catch (Exception ignored) {}
        }
        return out;
    }

    /** A connected, unmetered Wi-Fi (or Ethernet) network with internet, or null. */
    static android.net.Network wifiNetwork(Context context) {
        try {
            ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            if (cm == null) return null;
            android.net.Network[] all = cm.getAllNetworks();
            if (all == null) return null;
            for (android.net.Network n : all) {
                android.net.NetworkCapabilities c = cm.getNetworkCapabilities(n);
                if (c == null || !c.hasCapability(android.net.NetworkCapabilities.NET_CAPABILITY_INTERNET)) continue;
                if (!(c.hasTransport(android.net.NetworkCapabilities.TRANSPORT_WIFI) || c.hasTransport(android.net.NetworkCapabilities.TRANSPORT_ETHERNET))) continue;
                if (!c.hasCapability(android.net.NetworkCapabilities.NET_CAPABILITY_NOT_METERED)) continue;
                return n;
            }
        } catch (Throwable ignored) {}
        return null;
    }

    /** "Wi-Fi only": every connection of the app goes through Wi-Fi, so mobile data is never used — if Wi-Fi
     *  drops, downloads stop and wait instead of switching to mobile data. Released when the job ends. */
    static volatile android.net.Network boundTo;
    static void bindWifi(Context context, android.net.Network n) {
        try {
            ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            if (cm == null) return;
            if (n == null ? boundTo != null : !n.equals(boundTo)) { cm.bindProcessToNetwork(n); boundTo = n; }
        } catch (Throwable ignored) {}
    }

    // ------------------------------------------------------------------ main-screen pictures

    /**
     * Character pictures on the main screen come straight from Eclipse. When a picture is
     * already saved it is served from the phone; otherwise the WebView loads it as before and
     * a copy is saved in the background so it is instant (and offline) next time.
     */
    static WebResourceResponse intercept(Context context, final WebResourceRequest request) throws Exception {
        if (context == null || request == null || !"GET".equals(request.getMethod())) return null;
        final String url = request.getUrl().toString();
        if (!url.startsWith(ORIGIN + "/cdn/uncompressed/character/thumb/") || !url.endsWith(".png")) return null;
        final File root = new File(context.getFilesDir(), "forge");
        final PreviewCache cache = new PreviewCache(root);
        if (cache.cachedBody(url) != null) return cache.response(request);
        if (!cache.offline() && SAVER.getQueue().remainingCapacity() > 0 && QUEUED.add(url)) {
            try {
            SAVER.execute(new Runnable() {
                public void run() {
                    try {
                        File cacheRoot = new File(root, "preview-cache");
                        long limit = readLimit(root);
                        if (folderBytes(cacheRoot) < limit - 64L * 1024 * 1024) download(cacheRoot, url, 4L * 1024 * 1024, null);
                    } catch (Throwable ignored) {
                    } finally {
                        QUEUED.remove(url);
                    }
                }
            });
            } catch (java.util.concurrent.RejectedExecutionException e) {
                QUEUED.remove(url);
            }
        }
        return null;
    }

    private static volatile long folderBytesAt;
    private static volatile long folderBytesValue;

    private static long folderBytes(File cacheRoot) {
        long now = System.currentTimeMillis();
        if (now - folderBytesAt < 60000) return folderBytesValue;
        long total = 0;
        File[] files = cacheRoot.listFiles();
        if (files != null) for (File f : files) if (f.getName().endsWith(".body")) total += f.length();
        folderBytesValue = total;
        folderBytesAt = now;
        return total;
    }

    /** The preview storage limit, read without PreviewCache's lock (which is held during player downloads). */
    static long readLimit(File root) {
        try {
            long value = new JSONObject(read(new File(new File(root, "preview-cache"), "settings.json"), 65536)).optLong("maxBytes", 2147483648L);
            for (long b : BUDGETS) if (b == value) return value;
        } catch (Exception ignored) {}
        return 2147483648L;
    }

    // ------------------------------------------------------------------ cache files (same layout as PreviewCache)

    static String normalized(String url) throws Exception {
        Method m = normalizer;
        if (m == null) {
            m = PreviewCache.class.getDeclaredMethod("normalized", String.class);
            m.setAccessible(true);
            normalizer = m;
        }
        try {
            return (String) m.invoke(null, url);
        } catch (java.lang.reflect.InvocationTargetException e) {
            Throwable cause = e.getCause();
            if (cause instanceof Exception) throw (Exception) cause;
            throw e;
        }
    }

    private static File base(File cacheRoot, String normalizedUrl) throws Exception {
        byte[] digest = MessageDigest.getInstance("SHA-256").digest(normalizedUrl.getBytes(StandardCharsets.UTF_8));
        StringBuilder hex = new StringBuilder();
        for (byte b : digest) hex.append(String.format(Locale.US, "%02x", b & 255));
        return new File(cacheRoot, hex.toString());
    }

    static File savedBody(File cacheRoot, String url) throws Exception {
        File base = base(cacheRoot, normalized(url));
        File body = new File(base + ".body"), meta = new File(base + ".json");
        return body.isFile() && meta.isFile() ? body : null;
    }

    interface Budget {
        void reserve(long bytes) throws IOException;
        void release(long bytes);
    }

    /** Saves one Eclipse file into the preview cache. Returns bytes written; 0 if it was already saved. */
    static long download(File cacheRoot, String url, long max, Budget budget) throws Exception {
        String key = normalized(url);
        File base = base(cacheRoot, key);
        File body = new File(base + ".body"), meta = new File(base + ".json");
        if (body.isFile() && meta.isFile()) return 0;
        if (!cacheRoot.isDirectory()) PublicStorage.ensure();
        cacheRoot.mkdirs();
        // Same request as the app's other Eclipse downloads (AssetDownload): Eclipse often answers
        // with a redirect, which the old code treated as a failure, so most files never saved.
        HttpURLConnection c = null;
        URL at = new URL(key);
        int code = 0;
        for (int hop = 0; hop <= 5; hop++) {
            if (!"https".equals(at.getProtocol()) || !"dokkan-eclipse.com".equals(at.getHost()) || at.getUserInfo() != null || at.getPort() != -1) throw new IOException("Eclipse redirected outside its website");
            c = (HttpURLConnection) at.openConnection();
            c.setConnectTimeout(20000);
            c.setReadTimeout(60000);
            c.setInstanceFollowRedirects(false);
            c.setRequestProperty("User-Agent", "DokkanUnitForge/2.7");
            c.setRequestProperty("Accept-Encoding", "identity");
            code = c.getResponseCode();
            if (code < 300 || code >= 400) break;
            String location = c.getHeaderField("Location");
            release(c, true);
            if (location == null || hop == 5) throw new IOException("Eclipse redirect could not be followed");
            at = new URL(at, location);
        }
        File part = new File(base + ".part" + Thread.currentThread().getId());
        long reserved = 0;
        boolean kept = false;
        try {
            if (code == 404 || code == 410) throw new MissingException();
            if (code != 200) throw new IOException("Eclipse returned HTTP " + code);
            long length = c.getContentLengthLong();
            if (length > max) throw new IOException("File is larger than the preview limit");
            if (budget != null && length > 0) { budget.reserve(length); reserved = length; }
            long written = 0;
            InputStream in = c.getInputStream();
            FileOutputStream out = new FileOutputStream(part);
            try {
                byte[] buffer = new byte[65536];
                int n;
                while ((n = in.read(buffer)) != -1) {
                    written += n;
                    if (written > max) throw new IOException("File is larger than the preview limit");
                    out.write(buffer, 0, n);
                }
            } finally {
                out.close();
                in.close();
            }
            if (length >= 0 && written != length && c.getContentEncoding() == null) throw new IOException("Incomplete download");
            if (budget != null && reserved == 0) { budget.reserve(written); reserved = written; }
            String type = c.getContentType();
            if (body.isFile() && meta.isFile()) return 0; // saved by the player meanwhile (reservation released below)
            if (!part.renameTo(body)) throw new IOException("Could not save a downloaded file");
            File metaPart = new File(base + ".jpart" + Thread.currentThread().getId());
            FileOutputStream mo = new FileOutputStream(metaPart);
            try {
                mo.write(new JSONObject().put("url", key).put("type", type == null ? "application/octet-stream" : type).toString().getBytes(StandardCharsets.UTF_8));
            } finally {
                mo.close();
            }
            if (!metaPart.renameTo(meta)) throw new IOException("Could not save a downloaded file");
            kept = true;
            return written;
        } finally {
            part.delete();
            if (kept) { /* stream fully read and closed: the connection goes back to the pool */ }
            else release(c, code == 404 || code == 410);
            if (!kept && reserved > 0 && budget != null) budget.release(reserved);
        }
    }

    /**
     * Speed: a finished request hands its connection back so the next file reuses it (no new secure
     * connection per file, which was most of the time for small files). Broken requests are closed.
     */
    static void release(HttpURLConnection c, boolean reuse) {
        if (c == null) return;
        if (reuse) {
            try {
                InputStream in = c.getResponseCode() >= 400 ? c.getErrorStream() : c.getInputStream();
                if (in != null) {
                    byte[] b = new byte[8192];
                    int total = 0, n;
                    while (total < 262144 && (n = in.read(b)) != -1) total += n;
                    in.close();
                    return;
                }
            } catch (Exception ignored) {}
        }
        c.disconnect();
    }

    static final class MissingException extends IOException {
        MissingException() { super("Not on Eclipse"); }
    }

    private static String read(File file, int max) throws IOException {
        if (file.length() > max) throw new IOException("File is too large");
        FileInputStream in = new FileInputStream(file);
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buffer = new byte[16384];
            int n;
            while ((n = in.read(buffer)) != -1) out.write(buffer, 0, n);
            return new String(out.toByteArray(), StandardCharsets.UTF_8);
        } finally {
            in.close();
        }
    }

    private static String encodePath(String path) throws Exception {
        StringBuilder out = new StringBuilder();
        for (String part : path.split("/")) {
            if (part.isEmpty() || part.equals(".") || part.equals("..")) throw new IOException("Unsafe path");
            if (out.length() > 0) out.append('/');
            out.append(URLEncoder.encode(part, "UTF-8").replace("+", "%20"));
        }
        return out.toString();
    }

    // ------------------------------------------------------------------ the download job

    static final class Job implements Runnable {
        final Context context;
        final File root, cacheRoot;
        final JSONObject options;
        final JSONArray packs;
        final boolean movies;
        volatile boolean wifiOnly, paused, cancelled, finished;
        volatile String phase = "Starting", label = "", waiting = "", error = "";
        final long startedAt = System.currentTimeMillis();
        volatile long finishedAt;
        final AtomicLong total = new AtomicLong(), done = new AtomicLong(), failed = new AtomicLong(), skipped = new AtomicLong(), savedBytes = new AtomicLong();
        final AtomicLong pending = new AtomicLong();
        final Set<String> seen = Collections.newSetFromMap(new ConcurrentHashMap<String, Boolean>());
        final List<String> failureList = Collections.synchronizedList(new ArrayList<String>());
        volatile long used, limit;
        volatile JSONObject cleanup;
        volatile boolean resumed;
        final AtomicLong original = new AtomicLong();
        volatile boolean moviePhase;
        final Object budgetLock = new Object();
        ThreadPoolExecutor pool;
        Set<Long> effectIds = new HashSet<Long>();
        String sourceKey = "bundled";
        File database;

        Job(Context context, File root, JSONObject options, boolean wifiOnly) {
            this.context = context;
            this.root = root;
            this.cacheRoot = new File(root, "preview-cache");
            this.options = options;
            this.packs = options.optJSONArray("packs");
            this.movies = options.optBoolean("movies", false);
            this.wifiOnly = wifiOnly;
        }

        List<String> failures() {
            synchronized (failureList) { return new ArrayList<String>(failureList.subList(0, Math.min(20, failureList.size()))); }
        }

        boolean has(String pack) {
            for (int i = 0; i < packs.length(); i++) if (pack.equals(packs.optString(i))) return true;
            return false;
        }

        public void run() {
            // more files at once, each reusing its connection: much faster for thousands of small files
            try { System.setProperty("http.keepAlive", "true"); System.setProperty("http.maxConnections", "64"); } catch (Throwable ignored) {}
            pool = new ThreadPoolExecutor(64, 64, 30, TimeUnit.SECONDS, new LinkedBlockingQueue<Runnable>());
            try {
                prepare();
                // first: clean up what earlier builds left behind, so nothing is downloaded twice
                if (options.optBoolean("tidy", true)) {
                    phase = "Cleaning up old files";
                    label = "";
                    cleanup = PublicStorage.tidy(root, context.getCacheDir(), sourceKey, keepKeys(), new PublicStorage.Network() {
                        public long scriptSize(String path) { return remoteSize(path); }
                    }).json();
                    storageCheckedAt = 0;
                }
                boolean everything = has("everything");
                if (has("essentials") || has("units") || everything) {
                    phase = "Animation player";
                    player();
                    phase = "Animation scripts";
                    scripts();
                    phase = "Character pictures";
                    pictures();
                    complete("essentials");
                }
                if (has("units") && !everything) {
                    phase = "Your characters";
                    JSONArray cards = options.optJSONArray("cards");
                    for (int i = 0; cards != null && i < cards.length() && i < 400; i++) card(cards.optLong(i));
                    waitIdle();
                    phase = "Your animations";
                    JSONArray scripts = options.optJSONArray("scripts");
                    Set<String> paths = new LinkedHashSet<String>();
                    paths.add("ab_script/common/common.lua");
                    for (String path : allScripts()) if (path.startsWith("ab_script/ab_sys/")) paths.add(path);
                    for (int i = 0; scripts != null && i < scripts.length() && i < 2000; i++) paths.add(scripts.optString(i));
                    scriptAssets(paths);
                    phase = "Movies in your animations";
                    JSONArray moviePacks = options.optJSONArray("moviePacks");
                    for (int i = 0; moviePacks != null && i < moviePacks.length() && i < 400; i++) effect(moviePacks.optLong(i), true);
                    waitIdle();
                    complete("units");
                }
                if (everything) {
                    // game movies are huge (tens of GB): they come last, so running out of room
                    // for them never stops the rest of "Everything"
                    phase = "Every animation effect";
                    allEffects(false);
                    phase = "Every animation sound";
                    scriptAssets(allScripts());
                    phase = "Every character";
                    allCards();
                    complete("everything");
                    if (movies) {
                        phase = "Every game movie";
                        moviePhase = true;
                        allEffects(true);
                        complete("movies");
                    }
                }
                if (has("sparking")) {
                    phase = "Sparking custom content";
                    sparking();
                    complete("sparking");
                }
                phase = cancelled ? "Cancelled" : "Done";
            } catch (Cancelled c) {
                phase = "Cancelled";
            } catch (Throwable t) {
                error = t.getMessage() == null ? t.toString() : t.getMessage();
                phase = "Stopped";
            } finally {
                pool.shutdownNow();
                try { pool.awaitTermination(75, TimeUnit.SECONDS); } catch (InterruptedException ignored) {}
                Activity activity = ForgeFixes.activity();
                if (activity != null) keepScreenOn(activity, false);
                bindWifi(context, null);
                label = "";
                waiting = "";
                finished = true;
                finishedAt = System.currentTimeMillis();
                try { context.getSharedPreferences(PREFS, 0).edit().remove("pending").commit(); } catch (Throwable ignored) {}
                storageCheckedAt = 0;
                cleanParts();
            }
        }

        private void complete(String pack) {
            if (cancelled) throw new Cancelled();
            SharedPreferences prefs = context.getSharedPreferences(PREFS, 0);
            try {
                JSONObject completed = new JSONObject(prefs.getString("completed", "{}"));
                completed.put(pack, new JSONObject().put("at", System.currentTimeMillis()).put("failed", failed.get()));
                prefs.edit().putString("completed", completed.toString()).commit();
            } catch (Exception ignored) {}
        }

        private void cleanParts() {
            File[] files = cacheRoot.listFiles();
            if (files == null) return;
            for (File f : files) if (f.getName().matches("[a-f0-9]{64}\\.j?part\\d+")) f.delete();
        }

        private void prepare() throws Exception {
            PublicStorage.ensure();
            cacheRoot.mkdirs();
            JSONObject settings = new PreviewCache(root).settings(new JSONObject());
            used = settings.optLong("bytes");
            limit = settings.optLong("maxBytes", 2147483648L);
            // set the storage size once for what was chosen, instead of growing it step by step (each step
            // re-counted every saved file, which pauses all downloads on phones with many files)
            long want = has("everything") ? (movies ? 34359738368L : 17179869184L) : 2147483648L;
            if (want > limit && root.getUsableSpace() > want - used + KEEP_FREE) {
                try { new PreviewCache(root).settings(new JSONObject().put("maxBytes", want)); limit = want; } catch (Exception ignored) {}
            }
            GameDataStore store = new GameDataStore(root, new File(root, "bundled-database.db"));
            try {
                JSONObject meta = store.meta();
                String key = meta.optString("date", meta.optString("sha256", "bundled")).replaceAll("[^a-zA-Z0-9_-]", "");
                sourceKey = key.length() > 80 ? key.substring(0, 80) : key;
            } catch (Exception ignored) {}
            try { database = store.current(); } catch (Exception e) { database = new File(root, "bundled-database.db"); }
            if (database == null || !database.isFile()) database = new File(root, "bundled-database.db");
            for (long[] row : rows("SELECT id, category FROM effect_packs")) effectIds.add(row[0]);
        }

        List<long[]> rows(String sql) {
            List<long[]> out = new ArrayList<long[]>();
            SQLiteDatabase db = null;
            Cursor cursor = null;
            try {
                db = SQLiteDatabase.openDatabase(database.getPath(), null, SQLiteDatabase.OPEN_READONLY);
                cursor = db.rawQuery(sql, null);
                while (cursor.moveToNext()) out.add(new long[]{cursor.isNull(0) ? 0 : cursor.getLong(0), cursor.isNull(1) ? 0 : cursor.getLong(1)});
            } catch (Throwable t) {
                failureList.add("Database: " + t.getMessage());
            } finally {
                if (cursor != null) cursor.close();
                if (db != null) db.close();
            }
            return out;
        }

        // --------------------------------------------------------------- flow control

        void gate() {
            while (true) {
                if (cancelled) throw new Cancelled();
                if (paused) { waiting = "Paused"; sleep(500); continue; }
                JSONObject net = network(context);
                if (wifiOnly) {
                    android.net.Network w = wifiNetwork(context);
                    if (w == null) { bindWifi(context, null); waiting = "Waiting for Wi-Fi (mobile data is off for downloads)"; sleep(3000); continue; }
                    bindWifi(context, w);       // all downloads go through this Wi-Fi only
                } else {
                    bindWifi(context, null);
                    if (!net.optBoolean("connected", true)) { waiting = "Waiting for an Internet connection"; sleep(3000); continue; }
                }
                waiting = "";
                return;
            }
        }

        private void sleep(long ms) {
            try { Thread.sleep(ms); } catch (InterruptedException e) { throw new Cancelled(); }
        }

        void submit(final String what, final Task task) {
            if (cancelled) throw new Cancelled();
            total.incrementAndGet();
            pending.incrementAndGet();
            pool.execute(new Runnable() {
                public void run() {
                    try {
                        label = what;
                        task.run();
                    } catch (Cancelled c) {
                        // stop quietly
                    } catch (MissingException m) {
                        skipped.incrementAndGet();
                    } catch (Throwable t) {
                        failed.incrementAndGet();
                        if (failureList.size() < 200) failureList.add(what + ": " + (t.getMessage() == null ? t.toString() : t.getMessage()));
                        if (t instanceof StorageFull) { error = t.getMessage(); cancelled = true; }
                    } finally {
                        done.incrementAndGet();
                        if (pending.decrementAndGet() == 0) synchronized (pending) { pending.notifyAll(); }
                    }
                }
            });
        }

        void waitIdle() {
            synchronized (pending) {
                while (pending.get() > 0) {
                    try { pending.wait(500); } catch (InterruptedException e) { throw new Cancelled(); }
                }
            }
            if (cancelled) throw new Cancelled();
        }

        final Budget budget = new Budget() {
            public void reserve(long bytes) throws IOException {
                synchronized (budgetLock) {
                    if (root.getUsableSpace() - bytes < KEEP_FREE) throw new StorageFull(moviePhase ? "Your phone ran out of space for more game movies. Everything else is downloaded." : "Your phone is almost out of space. Free some space, then tap Download again.");
                    if (used + bytes > limit - 268435456L) {
                        used = scanBytes(); // count what the player and picture saver wrote too
                        long next = 0;
                        for (long b : BUDGETS) if (b >= used + bytes + 536870912L) { next = b; break; }
                        if (next == 0) throw new StorageFull(moviePhase ? "Game movies stopped at the 32 GB download limit. Everything else is downloaded." : "Downloaded previews reached the 32 GB limit. Clear some downloads first.");
                        try { new PreviewCache(root).settings(new JSONObject().put("maxBytes", next)); } catch (Exception e) { throw new IOException(e.getMessage()); }
                        limit = next;
                    }
                    used += bytes;
                }
            }
            public void release(long bytes) {
                synchronized (budgetLock) { used = Math.max(0, used - bytes); }
            }
        };

        long scanBytes() {
            long total = 0;
            File[] files = cacheRoot.listFiles();
            if (files != null) for (File f : files) if (f.getName().endsWith(".body")) total += f.length();
            return total;
        }

        /** Saves one Eclipse URL (relative paths are on dokkan-eclipse.com). */
        long save(String url, long max) throws Exception {
            if (url.startsWith("/")) url = ORIGIN + url;
            if (savedBody(cacheRoot, url) != null) return 0;
            gate();
            long bytes;
            // with many downloads at once Eclipse sometimes drops one: try it again a little later
            for (int attempt = 0; ; attempt++) {
                try { bytes = download(cacheRoot, url, max, budget); break; }
                catch (MissingException | StorageFull e) { throw e; }
                catch (IOException e) {
                    if (attempt >= 2 || cancelled) throw e;
                    sleep(attempt == 0 ? 2000 : 6000);
                    gate();
                }
            }
            savedBytes.addAndGet(bytes);
            return bytes;
        }

        JSONObject json(String url) throws Exception {
            save(url, 4L * 1024 * 1024);
            File body = savedBody(cacheRoot, url.startsWith("/") ? ORIGIN + url : url);
            if (body == null) throw new IOException("Not saved");
            return new JSONObject(read(body, 4 * 1024 * 1024));
        }

        void file(final String url, final long max) {
            if (!seen.add(url)) return;
            submit(shortName(url), new Task() { public void run() throws Exception { save(url, max); } });
        }

        private String shortName(String url) {
            int q = url.indexOf('?');
            String path = q < 0 ? url : url.substring(0, q);
            return path.substring(path.lastIndexOf('/') + 1);
        }

        /** Every file in an Eclipse folder (an LWF pack and its textures). */
        void folder(final String folder) {
            if (folder == null || folder.isEmpty() || !seen.add("folder:" + folder)) return;
            submit(folder.substring(folder.lastIndexOf('/') + 1), new Task() {
                public void run() throws Exception {
                    JSONObject listing = json(ORIGIN + "/api/file-browser?path=" + URLEncoder.encode(folder, "UTF-8"));
                    JSONArray items = listing.optJSONArray("items");
                    for (int i = 0; items != null && i < items.length() && i < 400; i++) {
                        JSONObject item = items.optJSONObject(i);
                        if (item == null || !"file".equals(item.optString("type"))) continue;
                        String path = item.optString("path");
                        if (!path.contains("/")) path = folder + "/" + path;
                        if (!path.matches("(?i)[a-z0-9_./ -]+\\.(lwf|png|jpe?g|webp|json)")) continue;
                        file(ORIGIN + "/assets/" + encodePath(path), MAX_FILE);
                    }
                }
            });
        }

        static String folderOf(String rel) {
            if (rel == null) return null;
            int slash = rel.lastIndexOf('/');
            return slash > 0 && rel.matches("(?i)[a-z0-9_./-]+") ? rel.substring(0, slash) : null;
        }

        /** null when the UI couldn't list every saved animation: then no per-unit copies are removed. */
        Set<String> keepKeys() {
            if (!options.optBoolean("keepKeysComplete", false)) return null;
            Set<String> out = new HashSet<String>();
            JSONArray keys = options.optJSONArray("keepKeys");
            for (int i = 0; keys != null && i < keys.length() && i < 20000; i++) out.add(keys.optString(i));
            return out;
        }

        /** Size of an animation script on Eclipse (HEAD), -2 when offline, -1 when unknown. */
        long remoteSize(String path) {
            if (cancelled) return -2;
            if (!network(context).optBoolean("connected", true)) return -2;
            HttpURLConnection c = null;
            try {
                c = (HttpURLConnection) new URL(ORIGIN + "/cdn/uncompressed/lua/" + encodePath(path)).openConnection();
                c.setRequestMethod("HEAD");
                c.setConnectTimeout(15000);
                c.setReadTimeout(30000);
                c.setInstanceFollowRedirects(true);
                c.setRequestProperty("User-Agent", "DokkanUnitForge/2.7");
                c.setRequestProperty("Accept-Encoding", "identity");
                int code = c.getResponseCode();
                if (code == 404 || code == 410) return -1;
                if (code != 200) return -2;
                return c.getContentLengthLong();
            } catch (Exception e) {
                return -2;
            } finally {
                if (c != null) c.disconnect();
            }
        }

        // --------------------------------------------------------------- Sparking: custom-made content only
        // Sparking's server also hosts the original game files; those are never downloaded from it (Eclipse
        // has them). A Sparking file is "custom" when Eclipse doesn't have the same character / effect /
        // stage / script (compared by the ID in its path). Downloads use Sparking's own verified download
        // (size + XXH64 + SHA-256) into the same cache the app reads, so nothing is fetched twice.

        void sparking() throws Exception {
            Activity activity = ForgeFixes.activity();
            File manifestFile;
            try {
                if (activity == null) throw new IOException("Open the app to download Sparking content.");
                Method m = activity.getClass().getDeclaredMethod("sparkingAssetManifest", long.class);
                m.setAccessible(true);
                manifestFile = (File) m.invoke(activity, -1L);
            } catch (java.lang.reflect.InvocationTargetException e) {
                Throwable cause = e.getCause() == null ? e : e.getCause();
                failed.incrementAndGet();
                failureList.add("Sparking: " + cause.getMessage());
                return;
            } catch (Exception e) {
                failed.incrementAndGet();
                failureList.add("Sparking: " + (e.getMessage() == null ? "the Sparking catalogue isn't ready. Download Sparking characters in Library first." : e.getMessage()));
                return;
            }
            final JSONObject manifest = new JSONObject(read(manifestFile, 33554432));
            final long version = manifest.optLong("latest_version", 0);
            JSONArray assets = manifest.optJSONArray("assets");
            final Set<String> eclipseScripts = allScripts();
            final File cache = new File(new File(root, "sparking"), "resource-cache");
            if (!cache.isDirectory()) PublicStorage.ensure();
            cache.mkdirs();
            final File temp = new File(context.getCacheDir(), "sparking-records");
            temp.mkdirs();
            final Map<String, Set<String>> listings = new ConcurrentHashMap<String, Set<String>>();
            for (int i = 0; assets != null && i < assets.length(); i++) {
                final JSONObject rec = assets.optJSONObject(i);
                if (rec == null) continue;
                final String path = rec.optString("file_path");
                if (!SparkingCustom.content(path)) continue;
                if (!SparkingCustom.supported(path)) continue;
                Boolean custom;
                try {
                    custom = SparkingCustom.custom(path, eclipseScripts, new SparkingCustom.Lister() {
                        public Set<String> list(String folder) throws Exception { return listing(listings, folder); }
                    });
                } catch (Cancelled c) {
                    throw c;
                } catch (Exception e) {
                    failed.incrementAndGet();
                    if (failureList.size() < 200) failureList.add(path + ": couldn't check whether it is custom-made (" + e.getMessage() + ")");
                    continue;
                }
                if (!custom) { original.incrementAndGet(); continue; }
                submit(path.substring(path.lastIndexOf('/') + 1), new Task() {
                    public void run() throws Exception { sparkingFile(rec, path, version, cache, temp); }
                });
            }
            waitIdle();
        }

        Set<String> listing(Map<String, Set<String>> listings, String folder) throws Exception {
            Set<String> names = listings.get(folder);
            if (names != null) return names;
            names = new HashSet<String>();
            try {
                JSONObject listing = json(ORIGIN + "/api/file-browser?path=" + URLEncoder.encode(folder, "UTF-8"));
                JSONArray items = listing.optJSONArray("items");
                for (int i = 0; items != null && i < items.length(); i++) {
                    JSONObject item = items.optJSONObject(i);
                    if (item != null) names.add(SparkingCustom.stem(item.optString("name")));
                }
            } catch (MissingException m) {
                // Eclipse has no such folder: everything in it is custom
            }
            listings.put(folder, names);
            return names;
        }

        void sparkingFile(JSONObject rec, String path, long version, File cache, File temp) throws Exception {
            long size = rec.getLong("size");
            String hash = rec.getString("hash");
            if (!hash.matches("\\d{1,20}") || size < 0) throw new IOException("Invalid Sparking resource record");
            File data = new File(cache, hash + "-" + size + ".data"), side = new File(cache, hash + "-" + size + ".json");
            if (data.isFile() && data.length() == size && side.isFile()) {
                try { if (hash.equals(new JSONObject(read(side, 8192)).optString("xxhash64"))) return; } catch (Exception ignored) {}
            }
            gate();
            if (root.getUsableSpace() - size < KEEP_FREE) throw new StorageFull("Your phone is almost out of space. Free some space, then tap Download again.");
            File one = new File(temp, "record-" + java.util.UUID.randomUUID() + ".json");
            try {
                FileOutputStream o = new FileOutputStream(one);
                try { o.write(new JSONObject().put("latest_version", version).put("assets", new JSONArray().put(rec)).toString().getBytes(StandardCharsets.UTF_8)); } finally { o.close(); }
                // the original Sparking downloader (and its checks) for the folders it handles; the same
                // checks for custom stages and the other project folders it doesn't know
                JSONObject info = SparkingFetch.originalAllows(path)
                        ? SparkingContent.downloadAsset(one, path, data, new SparkingContent.Progress() {
                            public void update(String phase, long done, long total) { if (cancelled) throw new Cancelled(); }
                        })
                        : SparkingFetch.download(rec, path, data);
                File sidePart = new File(cache, "sparking-asset-" + java.util.UUID.randomUUID() + ".tmp");
                FileOutputStream so = new FileOutputStream(sidePart);
                try { so.write(info.toString().getBytes(StandardCharsets.UTF_8)); } finally { so.close(); }
                if (!sidePart.renameTo(side)) { sidePart.delete(); throw new IOException("Could not save a Sparking file"); }
                savedBytes.addAndGet(size);
            } finally {
                one.delete();
            }
        }

        // --------------------------------------------------------------- packs

        void player() throws Exception {
            try {
                playerFiles();
            } catch (Cancelled c) {
                throw c;
            } catch (Exception e) {
                failed.incrementAndGet();
                failureList.add("Animation player: " + e.getMessage());
            }
        }

        void playerFiles() throws Exception {
            gate();
            PreviewTools tools = new PreviewTools(context, root);
            JSONObject state = tools.request(new JSONObject());
            if (state.optBoolean("ready")) return;
            label = "Player files";
            tools.request(new JSONObject().put("prepare", true));
            long end = System.currentTimeMillis() + 15L * 60 * 1000;
            while (System.currentTimeMillis() < end) {
                gate();
                state = new PreviewTools(context, root).request(new JSONObject());
                label = "Player files " + state.optLong("preparedFiles") + " of " + state.optLong("totalFiles");
                if (!state.optBoolean("preparing")) break;
                sleep(1000);
            }
            if (!state.optBoolean("ready")) failureList.add("Animation player: some player files could not be saved. Download again to retry.");
        }

        Set<String> allScripts() throws Exception {
            Set<String> out = new LinkedHashSet<String>();
            InputStream in = context.getAssets().open("ui/data/preview-script-index.json");
            String text;
            try {
                ByteArrayOutputStream buffer = new ByteArrayOutputStream();
                byte[] b = new byte[16384];
                int n;
                while ((n = in.read(b)) != -1) buffer.write(b, 0, n);
                text = new String(buffer.toByteArray(), StandardCharsets.UTF_8);
            } finally {
                in.close();
            }
            JSONArray scripts = new JSONObject(text).optJSONArray("scripts");
            for (int i = 0; scripts != null && i < scripts.length(); i++) {
                Object item = scripts.opt(i);
                String path = item instanceof JSONObject ? ((JSONObject) item).optString("path") : String.valueOf(item);
                if (path.matches("(?i)ab_script/[a-z0-9_/-]+\\.lua") && !path.contains("..")) out.add(path);
            }
            return out;
        }

        File scriptFile(String path) {
            return new File(new File(new File(root, "animation-sources"), sourceKey), path);
        }

        /** Same check and location as CreatorActivity.animationSource. */
        void scripts() throws Exception {
            for (final String path : allScripts()) {
                final File target = scriptFile(path);
                if (target.isFile()) continue;
                submit(path.substring(path.lastIndexOf('/') + 1), new Task() {
                    public void run() throws Exception {
                        gate();
                        HttpURLConnection c = null;
                        try {
                            c = AssetDownload.openOfficial(ORIGIN + "/cdn/uncompressed/lua/" + path);
                            InputStream in = c.getInputStream();
                            ByteArrayOutputStream out = new ByteArrayOutputStream();
                            try {
                                byte[] b = new byte[16384];
                                int n;
                                while ((n = in.read(b)) != -1) {
                                    out.write(b, 0, n);
                                    if (out.size() > 2097152) throw new IOException("Script is too large");
                                }
                            } finally {
                                in.close();
                            }
                            String text = new String(out.toByteArray(), StandardCharsets.UTF_8);
                            // a script Eclipse serves in a form the editor can't read either (empty, a web page or compiled
                            // code) is counted as "not on Eclipse", not as a failed download
                            if (text.trim().isEmpty() || text.trim().startsWith("<") || text.indexOf(0) >= 0) throw new MissingException();
                            target.getParentFile().mkdirs();
                            File part = new File(target.getPath() + ".part");
                            FileOutputStream fo = new FileOutputStream(part);
                            try { fo.write(out.toByteArray()); } finally { fo.close(); }
                            if (!part.renameTo(target)) { part.delete(); throw new IOException("Could not save script"); }
                            savedBytes.addAndGet(out.size());
                            c = null;   // fully read and closed: its connection is reused
                        } catch (IOException e) {
                            if (String.valueOf(e.getMessage()).contains("HTTP 404")) throw new MissingException();
                            throw e;
                        } finally {
                            if (c != null) c.disconnect();
                        }
                    }
                });
            }
            waitIdle();
        }

        void pictures() {
            for (long[] row : rows("SELECT DISTINCT (COALESCE(NULLIF(resource_id, 0), id) / 10) * 10, 0 FROM cards WHERE id < 9000000")) {
                long id = row[0];
                if (id <= 0) continue;
                file(ORIGIN + "/cdn/uncompressed/character/thumb/card_" + id + "_thumb/card_" + id + "_thumb.png", 4L * 1024 * 1024);
            }
            waitIdle();
        }

        /** Battle poses, card artwork, cut-ins, names and aura for one card. */
        void card(final long id) {
            if (id <= 0 || id > 99999999 || !seen.add("card:" + id)) return;
            submit("Card " + id, new Task() {
                public void run() throws Exception {
                    JSONObject card = json(ORIGIN + "/api/card/" + id);
                    if (!card.optBoolean("found", true)) return;
                    String[] packs = {"battle", "idle", "sp", "card_bg"};
                    for (String key : packs) {
                        JSONObject pack = card.optJSONObject(key);
                        if (pack != null) folder(folderOf(pack.optString("rel")));
                    }
                    JSONObject textures = card.optJSONObject("textures");
                    if (textures != null) {
                        JSONArray names = textures.names();
                        for (int i = 0; names != null && i < names.length(); i++) {
                            JSONObject t = textures.optJSONObject(names.optString(i));
                            String url = t == null ? "" : t.optString("url");
                            if (url.startsWith("/assets/") || url.startsWith("/api/card/")) file(url.startsWith("/") ? ORIGIN + url : url, MAX_FILE);
                        }
                    }
                    file(ORIGIN + "/api/card/" + id + "/fit/sp_name.png?w=1024&h=256&v=3", 8L * 1024 * 1024);
                    file(ORIGIN + "/api/card/" + id + "/fit/sp_phrase.png?w=1024&h=512&v=3", 8L * 1024 * 1024);
                    long aura = card.optLong("aura_effect_id", 0);
                    if (aura > 0) effect(aura);
                }
            });
        }

        /** One effect pack, for both the attacking and the defending side. */
        void effect(final long id) {
            effect(id, movies);
        }

        /** withMovie: also save the game movie in the pack (movies your animations use are always saved). */
        void effect(final long id, final boolean withMovie) {
            if (id <= 0 || !seen.add("effect:" + id + (withMovie ? ":movie" : ""))) return;
            submit("Effect " + id, new Task() {
                public void run() throws Exception {
                    // The player asks for /api/effect-pack/<id> (attacking side, with or without
                    // ?enemy=0) and ?enemy=1 (defending side); save every form it may use.
                    String[] forms = {"", "?enemy=0", "?enemy=1"};
                    for (String form : forms) {
                        JSONObject pack;
                        try {
                            pack = json(ORIGIN + "/api/effect-pack/" + id + form);
                        } catch (MissingException m) {
                            continue;
                        }
                        if (!pack.optBoolean("found", true)) continue;
                        JSONObject lwf = pack.optJSONObject("lwf");
                        if (lwf != null) folder(folderOf(lwf.optString("rel")));
                        JSONObject usm = pack.optJSONObject("usm");
                        if (usm != null && withMovie) {
                            String url = usm.optString("url");
                            if (url.startsWith("/assets/")) file(ORIGIN + url, MAX_FILE);
                        }
                    }
                }
            });
        }

        /** withMovies false: every effect pack without its movie; true: every pack's game movie. */
        void allEffects(boolean withMovies) {
            for (long[] row : rows("SELECT id, category FROM effect_packs ORDER BY id")) {
                if (!withMovies && row[1] == 5) continue;
                effect(row[0], withMovies);
            }
            waitIdle();
        }

        void allCards() {
            for (long[] row : rows("SELECT id, 0 FROM cards WHERE id < 9000000 AND id % 10 IN (0, 1) ORDER BY id")) card(row[0]);
            waitIdle();
        }

        /** Effects and sound effects used by these animation scripts. */
        void scriptAssets(Set<String> paths) {
            for (String path : paths) {
                File file = scriptFile(path);
                if (!file.isFile()) continue;
                try {
                    String text = read(file, 2097152);
                    Map<String, Long> constants = new HashMap<String, Long>();
                    Matcher m = CONSTANT.matcher(text);
                    while (m.find()) constants.put(m.group(1), Long.parseLong(m.group(2)));
                    m = EFFECT_CALL.matcher(text);
                    while (m.find()) {
                        Long id = value(m.group(2), constants);
                        if (id != null && effectIds.contains(id)) effect(id);
                    }
                    // game movies the animation plays (fusion scenes, cut-scenes)
                    m = MOVIE_CALL.matcher(text);
                    while (m.find()) {
                        Long id = value(m.group(2), constants);
                        if (id != null && id > 0) effect(id, true);
                    }
                    m = SOUND_CALL.matcher(text);
                    while (m.find()) {
                        Long id = value(m.group(2), constants);
                        if (id != null && id > 0) file(ORIGIN + "/api/se?cue=" + id, 32L * 1024 * 1024);
                    }
                } catch (Cancelled c) {
                    throw c;
                } catch (Exception e) {
                    failureList.add(path + ": " + e.getMessage());
                }
            }
            waitIdle();
        }

        private Long value(String token, Map<String, Long> constants) {
            if (token.matches("\\d+")) return Long.parseLong(token);
            return constants.get(token);
        }
    }

    interface Task {
        void run() throws Exception;
    }

    static final class Cancelled extends RuntimeException {
        Cancelled() { super("Cancelled"); }
    }

    static final class StorageFull extends IOException {
        StorageFull(String message) { super(message); }
    }
}
