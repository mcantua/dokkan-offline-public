package com.personal.aihub;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.Charset;
import java.util.Iterator;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.json.JSONArray;
import org.json.JSONObject;

/**
 * "Bring your own AI" connections. The web UI builds provider requests; this class adds the
 * user's key, sends them from a background thread (so the single bridge worker is never blocked
 * by a slow image generation) and hands the response back through polling.
 * Keys are stored only in the app's private storage and are never returned to the web UI.
 */
final class ForgeAi {
    private ForgeAi() {}

    private static final Charset UTF8 = Charset.forName("UTF-8");
    private static final String[] PROVIDERS = {"openai", "gemini", "anthropic", "xai", "openrouter", "custom"};
    private static final long MAX_RESPONSE = 48L * 1024 * 1024;
    private static final long JOB_TTL = 15L * 60 * 1000;
    private static final Map<String, Job> JOBS = new ConcurrentHashMap<String, Job>();

    private static final class Job {
        final long started = System.currentTimeMillis();
        volatile boolean done;
        volatile int status;
        volatile String body;
        volatile String error;
        volatile HttpURLConnection connection;
        volatile boolean cancelled;
    }

    static Object dispatch(File root, String method, JSONObject args) throws Exception {
        if ("aiConnections".equals(method)) return connections(root);
        if ("aiSaveConnection".equals(method)) return save(root, args);
        if ("aiRemoveConnection".equals(method)) return remove(root, args);
        if ("aiStart".equals(method)) return start(root, args);
        if ("aiPoll".equals(method)) return poll(args);
        if ("aiCancel".equals(method)) return cancel(args);
        return null;
    }

    private static boolean known(String provider) {
        for (String p : PROVIDERS) if (p.equals(provider)) return true;
        return false;
    }

    private static File store(File root) { return new File(root, "ai-connections.json"); }

    private static synchronized JSONObject read(File root) {
        File file = store(root);
        if (!file.isFile() || file.length() > 1024 * 1024) return new JSONObject();
        try {
            FileInputStream in = new FileInputStream(file);
            try {
                byte[] b = new byte[(int) file.length()];
                int n = 0;
                while (n < b.length) { int r = in.read(b, n, b.length - n); if (r < 0) break; n += r; }
                return new JSONObject(new String(b, 0, n, UTF8));
            } finally { in.close(); }
        } catch (Exception e) {
            return new JSONObject();
        }
    }

    private static synchronized void write(File root, JSONObject all) throws IOException {
        root.mkdirs();
        File tmp = new File(root, "ai-connections.tmp"), file = store(root);
        FileOutputStream out = new FileOutputStream(tmp);
        try { out.write(all.toString().getBytes(UTF8)); out.getFD().sync(); } finally { out.close(); }
        if (!tmp.renameTo(file)) { file.delete(); if (!tmp.renameTo(file)) throw new IOException("Could not save the AI connection."); }
        file.setReadable(false, false); file.setReadable(true, true);
    }

    private static JSONObject publicView(String provider, JSONObject c) throws Exception {
        String key = c.optString("apiKey", "");
        return new JSONObject().put("provider", provider).put("hasKey", key.length() > 0)
            .put("keyHint", key.length() > 4 ? "…" + key.substring(key.length() - 4) : key.length() > 0 ? "set" : "")
            .put("model", c.optString("model", "")).put("imageModel", c.optString("imageModel", ""))
            .put("baseUrl", c.optString("baseUrl", "")).put("updatedAt", c.optLong("updatedAt", 0));
    }

    private static JSONObject connections(File root) throws Exception {
        JSONObject all = read(root), out = new JSONObject();
        JSONArray list = new JSONArray();
        Iterator<String> it = all.keys();
        while (it.hasNext()) { String p = it.next(); if (known(p)) list.put(publicView(p, all.getJSONObject(p))); }
        return out.put("connections", list).put("active", all.optJSONObject("_settings") == null ? "" : all.getJSONObject("_settings").optString("active", ""));
    }

    private static String clean(String value, int max) throws IOException {
        if (value == null) return "";
        value = value.trim();
        if (value.length() > max) throw new IOException("A setting is too long.");
        for (int i = 0; i < value.length(); i++) { char ch = value.charAt(i); if (ch < 0x20 || ch == 0x7f) throw new IOException("Remove spaces or line breaks from the key and model names."); }
        return value;
    }

    private static JSONObject save(File root, JSONObject args) throws Exception {
        String provider = args.optString("provider", "");
        if (!known(provider)) throw new IOException("Choose an AI provider.");
        JSONObject all = read(root), c = all.optJSONObject(provider);
        if (c == null) c = new JSONObject();
        if (args.has("apiKey")) {
            String key = clean(args.optString("apiKey", ""), 512);
            if (key.indexOf(' ') >= 0) throw new IOException("The API key cannot contain spaces.");
            if (key.length() > 0 || args.optBoolean("clearKey", false)) c.put("apiKey", key);
        }
        c.put("model", clean(args.optString("model", c.optString("model", "")), 160));
        c.put("imageModel", clean(args.optString("imageModel", c.optString("imageModel", "")), 160));
        if ("custom".equals(provider)) {
            String base = clean(args.optString("baseUrl", c.optString("baseUrl", "")), 300);
            while (base.endsWith("/")) base = base.substring(0, base.length() - 1);
            URL url = new URL(base);
            boolean local = "127.0.0.1".equals(url.getHost());
            if (!("https".equals(url.getProtocol()) || ("http".equals(url.getProtocol()) && local)) || url.getHost().length() == 0 || url.getUserInfo() != null) throw new IOException("Use an https:// address (for example https://example.com/v1), or http://127.0.0.1 for an AI app running on this phone.");
            c.put("baseUrl", base);
        }
        if (!"custom".equals(provider) && c.optString("apiKey", "").length() == 0) throw new IOException("Paste your API key to connect " + provider + ".");
        c.put("updatedAt", System.currentTimeMillis());
        all.put(provider, c);
        JSONObject settings = all.optJSONObject("_settings");
        if (settings == null) settings = new JSONObject();
        if (args.optBoolean("makeActive", true)) settings.put("active", provider);
        all.put("_settings", settings);
        write(root, all);
        return publicView(provider, c);
    }

    private static JSONObject remove(File root, JSONObject args) throws Exception {
        String provider = args.optString("provider", "");
        if (!known(provider)) throw new IOException("Choose an AI provider.");
        JSONObject all = read(root);
        all.remove(provider);
        JSONObject settings = all.optJSONObject("_settings");
        if (settings != null && provider.equals(settings.optString("active"))) settings.remove("active");
        write(root, all);
        return new JSONObject().put("removed", true);
    }

    private static String base(String provider, JSONObject c) {
        if ("openai".equals(provider)) return "https://api.openai.com/v1";
        if ("gemini".equals(provider)) return "https://generativelanguage.googleapis.com/v1beta";
        if ("anthropic".equals(provider)) return "https://api.anthropic.com/v1";
        if ("xai".equals(provider)) return "https://api.x.ai/v1";
        if ("openrouter".equals(provider)) return "https://openrouter.ai/api/v1";
        return c.optString("baseUrl", "");
    }

    private static void expire() {
        long now = System.currentTimeMillis();
        for (Map.Entry<String, Job> e : JOBS.entrySet()) if (now - e.getValue().started > JOB_TTL) JOBS.remove(e.getKey());
    }

    private static JSONObject start(File root, JSONObject args) throws Exception {
        expire();
        int running = 0;
        for (Job j : JOBS.values()) if (!j.done) running++;
        if (running >= 3) throw new IOException("Three AI requests are already running. Wait for one to finish.");
        final String provider = args.optString("provider", "");
        if (!known(provider)) throw new IOException("Connect an AI provider first.");
        final JSONObject c = read(root).optJSONObject(provider);
        if (c == null) throw new IOException("Connect " + provider + " first.");
        final String path = args.optString("path", "");
        if (!path.matches("/[A-Za-z0-9/._:\\-?=&%]{1,300}") || path.contains("..")) throw new IOException("Unsupported AI request.");
        final String method = "GET".equals(args.optString("method", "POST")) ? "GET" : "POST";
        final String base = base(provider, c);
        if (base.length() == 0) throw new IOException("Add the server address for your custom AI.");
        final byte[] body = "POST".equals(method) ? args.optJSONObject("body") == null ? "{}".getBytes(UTF8) : args.getJSONObject("body").toString().getBytes(UTF8) : null;
        if (body != null && body.length > 24 * 1024 * 1024) throw new IOException("This AI request is too large.");
        final String id = UUID.randomUUID().toString();
        final Job job = new Job();
        JOBS.put(id, job);
        Thread t = new Thread(new Runnable() {
            @Override public void run() { perform(job, provider, c, base + path, method, body); }
        }, "forge-ai-" + id.substring(0, 8));
        t.setDaemon(true);
        t.start();
        return new JSONObject().put("job", id);
    }

    private static void perform(Job job, String provider, JSONObject c, String address, String method, byte[] body) {
        HttpURLConnection conn = null;
        try {
            URL url = new URL(address);
            conn = (HttpURLConnection) url.openConnection();
            job.connection = conn;
            conn.setInstanceFollowRedirects(false);
            conn.setConnectTimeout(20000);
            conn.setReadTimeout(240000);
            conn.setRequestMethod(method);
            conn.setRequestProperty("Accept", "application/json");
            conn.setRequestProperty("User-Agent", "DokkanUnitCreation/2.12 (Android)");
            String key = c.optString("apiKey", "");
            if ("gemini".equals(provider)) conn.setRequestProperty("x-goog-api-key", key);
            else if ("anthropic".equals(provider)) {
                conn.setRequestProperty("x-api-key", key);
                conn.setRequestProperty("anthropic-version", "2023-06-01");
            } else if (key.length() > 0) conn.setRequestProperty("Authorization", "Bearer " + key);
            if ("openrouter".equals(provider)) conn.setRequestProperty("X-Title", "Dokkan Unit Creation");
            if (body != null) {
                conn.setDoOutput(true);
                conn.setRequestProperty("Content-Type", "application/json");
                conn.setFixedLengthStreamingMode(body.length);
                OutputStream out = conn.getOutputStream();
                try { out.write(body); } finally { out.close(); }
            }
            int status = conn.getResponseCode();
            InputStream in = status >= 400 ? conn.getErrorStream() : conn.getInputStream();
            ByteArrayOutputStream buffer = new ByteArrayOutputStream();
            if (in != null) {
                try {
                    byte[] chunk = new byte[65536];
                    long total = 0;
                    int n;
                    while ((n = in.read(chunk)) >= 0) {
                        if (job.cancelled) throw new IOException("Canceled.");
                        total += n;
                        if (total > MAX_RESPONSE) throw new IOException("The AI response is too large.");
                        buffer.write(chunk, 0, n);
                    }
                } finally { in.close(); }
            }
            job.status = status;
            job.body = new String(buffer.toByteArray(), UTF8);
        } catch (Exception e) {
            String m = e.getMessage();
            job.error = job.cancelled ? "Canceled." : (e instanceof java.net.UnknownHostException ? "No Internet connection, or the AI server address is wrong." : e instanceof java.net.SocketTimeoutException ? "The AI service took too long to answer. Try again." : m == null ? "The AI request failed." : m);
        } finally {
            if (conn != null) conn.disconnect();
            job.done = true;
        }
    }

    private static JSONObject poll(JSONObject args) throws Exception {
        String id = args.optString("job", "");
        Job job = JOBS.get(id);
        if (job == null) throw new IOException("This AI request is no longer available. Try again.");
        if (!job.done) return new JSONObject().put("done", false).put("seconds", (System.currentTimeMillis() - job.started) / 1000);
        JOBS.remove(id);
        if (job.error != null) throw new IOException(job.error);
        return new JSONObject().put("done", true).put("status", job.status).put("text", job.body == null ? "" : job.body);
    }

    private static JSONObject cancel(JSONObject args) throws Exception {
        Job job = JOBS.remove(args.optString("job", ""));
        if (job != null) {
            job.cancelled = true;
            HttpURLConnection conn = job.connection;
            if (conn != null) try { conn.disconnect(); } catch (Exception ignored) {}
        }
        return new JSONObject().put("canceled", true);
    }
}
