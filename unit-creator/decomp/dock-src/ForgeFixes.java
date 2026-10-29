package com.personal.aihub;

import android.content.Context;
import android.content.pm.PackageInfo;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.charset.Charset;
import java.io.IOException;
import org.json.JSONObject;

/** Small native fixes injected into the rebuilt APK. */
public final class ForgeFixes {
    private ForgeFixes() {}

    /**
     * The bundled card database is copied once into app storage. Without this check an app update
     * that ships a newer reference.db keeps using the stale copy forever. When the installed
     * package changes, the old copy is discarded so ensureDb() copies the new bundled one.
     * Imported/updated databases live elsewhere (GameDataStore state) and are not touched.
     */
    public static void refreshBundledDatabase(Context context, File root) {
        try {
            PackageInfo info = context.getPackageManager().getPackageInfo(context.getPackageName(), 0);
            String stamp = info.versionCode + ":" + info.lastUpdateTime;
            File marker = new File(root, "bundled-database.stamp");
            String previous = "";
            if (marker.isFile() && marker.length() < 256) {
                FileInputStream in = new FileInputStream(marker);
                try {
                    byte[] b = new byte[(int) marker.length()];
                    int n = 0;
                    while (n < b.length) { int r = in.read(b, n, b.length - n); if (r < 0) break; n += r; }
                    previous = new String(b, 0, n, Charset.forName("UTF-8")).trim();
                } finally { in.close(); }
            }
            if (stamp.equals(previous)) return;
            String[] names = {"bundled-database.db", "bundled-database.db-journal", "bundled-database.db-wal", "bundled-database.db-shm", "bundled.tmp"};
            for (String name : names) new File(root, name).delete();
            root.mkdirs();
            FileOutputStream out = new FileOutputStream(marker);
            try { out.write(stamp.getBytes(Charset.forName("UTF-8"))); } finally { out.close(); }
        } catch (Throwable ignored) {
            // Never block opening the database because of this housekeeping step.
        }
    }

    /**
     * Extra bridge actions. Returns null when the action is not handled here so the original
     * dispatcher continues. All bridge calls run on the activity's single worker thread, so
     * these file operations never race with saveProject.
     */
    public static Object dispatch(File root, String method, JSONObject args) throws Exception {
        if ("deleteProject".equals(method)) return deleteProject(root, args);
        if ("wipeData".equals(method)) return wipeData(root, args);
        if ("checkUpdates".equals(method)) return checkUpdates();
        if ("cardIndex".equals(method)) return cardIndex();
        if ("openStore".equals(method)) return openStore(args);
        if ("deletePatch".equals(method)) return deletePatch(root, args);
        if ("renderMode".equals(method)) return renderMode(args);
        if ("textZoom".equals(method)) return textZoom(args);
        if ("previewDock".equals(method)) return PreviewDock.dispatch(activity(), args);
        if ("previewAnimation".equals(method)) PreviewDock.noteTrim(args); // then the original handler runs
        if ("offlineLibrary".equals(method)) return OfflineLibrary.dispatch(activity(), root, args);
        if (method != null && method.startsWith("ai") && !"aiCompose".equals(method)) return ForgeAi.dispatch(root, method, args);
        return null;
    }

    /**
     * The character finder's list in one small answer: only the twelve columns it needs, only
     * playable cards. Paging through "SELECT *" sent about 20 MB of JSON through the bridge.
     * Rows: [id, name, rarity, element, openYYYYMMDD, hp, atk, def, resource, passive, leader, grow].
     */
    private static org.json.JSONArray cardIndex() throws Exception {
        android.app.Activity activity = activity();
        if (activity == null) throw new IOException("The app is still starting.");
        java.lang.reflect.Field field = activity.getClass().getDeclaredField("db");
        field.setAccessible(true);
        android.database.sqlite.SQLiteDatabase db = (android.database.sqlite.SQLiteDatabase) field.get(activity);
        if (db == null) throw new IOException("Game data is not ready yet.");
        java.util.HashSet<String> columns = new java.util.HashSet<String>();
        android.database.Cursor info = db.rawQuery("PRAGMA table_info(cards)", null);
        try { while (info.moveToNext()) columns.add(info.getString(1)); } finally { info.close(); }
        String[] want = {"id", "name", "rarity", "element", "open_at", "hp_max", "atk_max", "def_max", "resource_id", "passive_skill_set_id", "leader_skill_set_id", "optimal_awakening_grow_type"};
        StringBuilder select = new StringBuilder();
        for (String column : want) {
            if (select.length() > 0) select.append(',');
            select.append(columns.contains(column) ? "\"" + column + "\"" : "NULL");
        }
        for (String need : new String[]{"id", "name", "hp_max", "passive_skill_set_id", "leader_skill_set_id"}) {
            if (!columns.contains(need)) throw new IOException("This game data has no " + need + " column.");
        }
        android.database.Cursor cursor = db.rawQuery("SELECT " + select + " FROM cards WHERE id % 10 = 1 AND ((id >= 1000000 AND id < 3000000) OR id >= 10000000)"
            + " AND hp_max > 300 AND passive_skill_set_id IS NOT NULL AND leader_skill_set_id IS NOT NULL ORDER BY id", null);
        org.json.JSONArray out = new org.json.JSONArray();
        try {
            while (cursor.moveToNext()) {
                org.json.JSONArray row = new org.json.JSONArray();
                row.put(cursor.getLong(0));
                row.put(cursor.isNull(1) ? "" : cursor.getString(1));
                row.put(cursor.isNull(2) ? 0 : cursor.getLong(2));
                row.put(cursor.isNull(3) ? 0 : cursor.getLong(3));
                String open = cursor.isNull(4) ? "" : cursor.getString(4);
                String digits = open.length() >= 10 ? open.substring(0, 10).replace("-", "") : "";
                long openDay = 0;
                try { if (digits.matches("[0-9]{8}")) openDay = Long.parseLong(digits); } catch (Exception ignored) {}
                row.put(openDay);
                for (int i = 5; i <= 8; i++) row.put(cursor.isNull(i) ? 0 : cursor.getLong(i));
                row.put(cursor.getLong(9));
                row.put(cursor.getLong(10));
                row.put(cursor.isNull(11) ? org.json.JSONObject.NULL : (Object) Long.valueOf(cursor.getLong(11)));
                out.put(row);
            }
        } finally { cursor.close(); }
        return out;
    }

    /** Opens the Play Store page of Android System WebView or Chrome (to update an old WebView). */
    private static JSONObject openStore(JSONObject args) throws Exception {
        String app = "chrome".equals(args.optString("app")) ? "com.android.chrome" : "com.google.android.webview";
        final android.app.Activity activity = activity();
        if (activity == null) throw new IOException("The app is still starting.");
        final String id = app;
        activity.runOnUiThread(new Runnable() { public void run() { openStoreNow(activity, id); } });
        return new JSONObject().put("opened", true);
    }

    private static void openStoreNow(android.app.Activity activity, String app) {
        try {
            android.content.Intent store = new android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse("market://details?id=" + app));
            store.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK);
            activity.startActivity(store);
        } catch (Exception e) {
            android.content.Intent web = new android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse("https://play.google.com/store/apps/details?id=" + app));
            web.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK);
            try { activity.startActivity(web); } catch (Exception ignored) {}
        }
    }

    private static JSONObject deleteProject(File root, JSONObject args) throws Exception {
        String key = args.optString("key", "");
        if (!key.matches("[a-zA-Z0-9_-]{1,100}")) throw new IOException("Invalid project key");
        File projects = new File(root, "projects");
        File project = new File(projects, key + ".json");
        if (!project.getCanonicalPath().equals(new File(projects.getCanonicalFile(), key + ".json").getPath())) throw new IOException("Unsafe project path");
        if (!project.isFile()) throw new IOException("This unit is no longer saved on this device.");
        if (!project.delete()) throw new IOException("Could not delete this unit. Try again.");
        removeTree(new File(new File(root, "project-versions"), key));
        return new JSONObject().put("deleted", true).put("key", key);
    }

    /**
     * Settings > Your data > Delete. Removes what the person chose: their units (and saved
     * versions), their own files (imported art, songs, animations, exported game files), the
     * offline downloads, and AI connections. The bundled game database is never touched.
     */
    private static JSONObject wipeData(File root, JSONObject args) throws Exception {
        if (!"DELETE".equals(args.optString("confirm", ""))) throw new IOException("Not confirmed.");
        JSONObject done = new JSONObject();
        if (args.optBoolean("units", false)) {
            removeTree(new File(root, "projects"));
            removeTree(new File(root, "project-versions"));
            new File(root, "projects").mkdirs();
            done.put("units", true);
        }
        if (args.optBoolean("files", false)) {
            for (String name : new String[]{"assets", "lwf", "patches", "animation-sources"}) removeTree(new File(root, name));
            new File(root, "assets").mkdirs();
            new File(root, "patches").mkdirs();
            done.put("files", true);
        }
        if (args.optBoolean("downloads", false)) {
            removeTree(new File(root, "preview-cache"));
            removeTree(new File(root, "movie-cache"));
            done.put("downloads", true);
        }
        if (args.optBoolean("ai", false)) {
            new File(root, "ai-connections.json").delete();
            new File(root, "ai-connections.tmp").delete();
            done.put("ai", true);
        }
        return done.put("ok", true);
    }

    /** Asks dokkan-eclipse.com when its game database was last published (no download). */
    private static JSONObject checkUpdates() {
        JSONObject out = new JSONObject();
        java.net.HttpURLConnection c = null;
        try {
            c = (java.net.HttpURLConnection) new java.net.URL("https://dokkan-eclipse.com/cdn/uncompressed/sqlite/current/en/database_decrypted.db").openConnection();
            c.setRequestMethod("HEAD");
            c.setConnectTimeout(15000);
            c.setReadTimeout(15000);
            c.setInstanceFollowRedirects(true);
            int code = c.getResponseCode();
            out.put("ok", code >= 200 && code < 300).put("status", code)
               .put("lastModified", c.getLastModified()).put("size", c.getContentLength());
        } catch (Throwable t) {
            try { out.put("ok", false).put("error", "Couldn't reach Dokkan Eclipse. Check your internet connection."); } catch (Exception ignored) {}
        } finally {
            if (c != null) c.disconnect();
        }
        return out;
    }

    private static JSONObject deletePatch(File root, JSONObject args) throws Exception {
        String key = args.optString("key", "");
        if (!key.matches("[a-f0-9-]{36}")) throw new IOException("Invalid patch key");
        File patches = new File(root, "patches");
        File eclp = new File(patches, key + ".eclp"), meta = new File(patches, key + ".json");
        if (!eclp.exists() && !meta.exists()) throw new IOException("This patch is no longer saved on this device.");
        if ((meta.exists() && !meta.delete()) || (eclp.exists() && !eclp.delete())) throw new IOException("Could not delete this patch. Try again.");
        return new JSONObject().put("deleted", true).put("key", key);
    }

    private static void removeTree(File file) {
        File[] children = file.isDirectory() ? file.listFiles() : null;
        if (children != null) for (File child : children) removeTree(child);
        file.delete();
    }

    // ---------------------------------------------------------------- rendering
    // The creator screen used to force software rendering (hardwareAccelerated="false" plus a
    // software layer), which made every scroll, tap and animation slow. It now uses the GPU.
    // Software rendering remains as a fallback the user can pick, and it is switched on
    // automatically if the page renderer crashes twice within ten minutes.
    private static final String RENDER_PREFS = "forge-render";
    private static volatile Context appContext;
    private static volatile java.lang.ref.WeakReference<android.webkit.WebView> webRef;
    private static volatile java.lang.ref.WeakReference<android.app.Activity> activityRef;

    static android.app.Activity activity() {
        java.lang.ref.WeakReference<android.app.Activity> ref = activityRef;
        return ref == null ? null : ref.get();
    }

    static android.webkit.WebView mainWeb() {
        java.lang.ref.WeakReference<android.webkit.WebView> ref = webRef;
        return ref == null ? null : ref.get();
    }

    // ---------------------------------------------------------------- hooks called from CreatorActivity
    /** Called instead of starting PreviewActivity. Returns false to fall back to the separate screen. */
    public static boolean openPreview(android.app.Activity activity, String token) {
        try { return PreviewDock.open(activity, token); } catch (Throwable t) { return false; }
    }

    /** Forwards picker results (recording "Save video") to the in-app player. */
    public static void activityResult(android.app.Activity activity, int request, int result, android.content.Intent data) {
        try { PreviewDock.activityResult(request, result, data); } catch (Throwable ignored) {}
    }

    /** Serves downloaded Eclipse pictures to the main screen so lists load instantly and offline. */
    public static android.webkit.WebResourceResponse intercept(android.webkit.WebResourceRequest request) {
        try { return OfflineLibrary.intercept(appContext, request); } catch (Throwable t) { return null; }
    }

    private static android.content.SharedPreferences renderPrefs(Context context) {
        return context.getSharedPreferences(RENDER_PREFS, 0);
    }

    public static void configureWebView(Context context, android.webkit.WebView web) {
        boolean software = false;
        try {
            Context app = context.getApplicationContext();
            appContext = app != null ? app : context;
            software = renderPrefs(appContext).getBoolean("software", false);
        } catch (Throwable ignored) {}
        webRef = new java.lang.ref.WeakReference<android.webkit.WebView>(web);
        if (context instanceof android.app.Activity) activityRef = new java.lang.ref.WeakReference<android.app.Activity>((android.app.Activity) context);
        try { web.setLayerType(software ? 1 : 0, null); } catch (Throwable ignored) {}
        try {
            int zoom = renderPrefs(appContext).getInt("textZoom", 100);
            if (zoom != 100) web.getSettings().setTextZoom(zoom);
            // "Normal" follows the phone's font size; very large system fonts (Samsung "Huge",
            // Android accessibility sizes) are kept to 140% so screens stay usable.
            else if (web.getSettings().getTextZoom() > 140) web.getSettings().setTextZoom(140);
        } catch (Throwable ignored) {}
    }

    /** Text size from Settings: Android's own WebView text zoom (80-200%), kept for the next start. */
    private static JSONObject textZoom(JSONObject args) throws Exception {
        Context context = appContext;
        if (context == null) throw new IOException("Display settings are not ready yet.");
        final int percent = Math.max(80, Math.min(200, args.optInt("percent", 100)));
        renderPrefs(context).edit().putInt("textZoom", percent).commit();
        final android.webkit.WebView web = webRef == null ? null : webRef.get();
        if (web != null) web.post(new Runnable() { public void run() { try { web.getSettings().setTextZoom(percent); } catch (Throwable ignored) {} } });
        return new JSONObject().put("percent", percent);
    }

    public static void noteRendererCrash(Context context) {
        try {
            android.content.SharedPreferences prefs = renderPrefs(context);
            long now = System.currentTimeMillis(), last = prefs.getLong("crashAt", 0L);
            int count = now - last < 600000L ? prefs.getInt("crashes", 0) + 1 : 1;
            android.content.SharedPreferences.Editor edit = prefs.edit().putLong("crashAt", now).putInt("crashes", count);
            if (count >= 2) edit.putBoolean("software", true).putBoolean("autoSoftware", true);
            edit.commit();
        } catch (Throwable ignored) {}
    }

    private static JSONObject renderMode(JSONObject args) throws Exception {
        Context context = appContext;
        if (context == null) throw new IOException("Rendering settings are not ready yet.");
        android.content.SharedPreferences prefs = renderPrefs(context);
        String set = args.optString("set", "");
        if ("gpu".equals(set) || "software".equals(set)) {
            final boolean software = "software".equals(set);
            prefs.edit().putBoolean("software", software).putBoolean("autoSoftware", false).putInt("crashes", 0).commit();
            final android.webkit.WebView web = webRef == null ? null : webRef.get();
            if (web != null) web.post(new Runnable() { public void run() { try { web.setLayerType(software ? 1 : 0, null); } catch (Throwable ignored) {} } });
        }
        return new JSONObject().put("mode", prefs.getBoolean("software", false) ? "software" : "gpu").put("auto", prefs.getBoolean("autoSoftware", false));
    }
}
