package com.personal.aihub;

import android.content.Context;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.json.JSONArray;
import org.json.JSONObject;

/**
 * Everything the app downloads lives in ONE folder the person can see:
 *   Download/Dokkan Unit Creator/
 *       Game files/          offline downloads and everything the animation player fetched (preview-cache)
 *       Game movies/         prepared game movies (movie-cache)
 *       Animation scripts/   animation scripts (animation-sources)
 *       Sparking files/      verified Sparking downloads (sparking/resource-cache)
 *
 * The app keeps using its usual private paths (forge/preview-cache, ...): each one is a link to its
 * folder in Download, so no other code has to change.
 *
 * Nothing leaks into Photos/Gallery apps: every folder has a ".nomedia" file, and no saved file is
 * named like a picture, video or song (<hash>.body, .video, .lua, <hash>-<size>.data).
 *
 * Earlier installs: Android 11+ lets an app use its OWN files in Download without any permission, but
 * files left by an earlier install (uninstalled, then installed again) can only be reused or cleaned
 * up with "All files access". When such a folder is found the app asks (Android's own Settings
 * screen); with access it takes the folder over (reusing every file), merges any "(2)" copies into it
 * and removes duplicates. Without access it uses a separate folder rather than bypass Android.
 * Only the app's own file types inside its own folders are ever moved or deleted.
 *
 * Android 8–10 use the same shared folder only after a fresh storage permission grant.
 * Permission is checked again after reinstall; an old folder never grants access by itself.
 */
final class PublicStorage {
    static final String NAME = "Dokkan Unit Creator";
    private static final String MARKER = ".dokkan-unit-creator";
    private static volatile boolean development;
    private static String storageName() { return development ? NAME+" Development" : NAME; }
    private static String markerName() { return development ? MARKER+"-development" : MARKER; }
    /** private path (under forge/) → folder inside the public folder */
    static final String[][] LINKS = {
        {"preview-cache", "Game files"},
        {"movie-cache", "Game movies"},
        {"animation-sources", "Animation scripts"},
        {"sparking/resource-cache", "Sparking files"}
    };
    private static volatile boolean prepared;
    private static volatile File base, root, downloads;
    private static volatile int sdk;
    private static volatile Thread mover;
    private static volatile Context appContext;
    private static final Report MOVED = new Report();
    /** a folder from an earlier install was found and the person hasn't chosen yet (files stay private meanwhile) */
    private static volatile boolean waiting;
    /** tests: pretend "All files access" is on / off */
    static volatile Boolean allFilesForTest;

    private PublicStorage() {}

    static File folder() { return base; }

    static String label() {
        File b = base;
        return b == null ? "" : "Download › " + b.getName();
    }

    // ------------------------------------------------------------------ start

    static void prepare(Context context) {
        if (prepared || context == null) return;
        try {
            appContext = context.getApplicationContext();
            development = "com.dokkanunitcreator.development".equals(context.getPackageName());
            prepare(new File(context.getFilesDir(), "forge"), downloadsDir(), sdkInt());
        } catch (Throwable ignored) {}
    }

    static synchronized void prepare(File forgeRoot, File downloadsDir, int sdkVersion) {
        if (prepared) return;
        prepared = true;
        root = forgeRoot;
        downloads = downloadsDir == null ? null : downloadsDir.getAbsoluteFile();
        sdk = sdkVersion;
        if (sdk < 26 || downloads == null) return;
        if (sdk < 30 && !allFiles()) { waiting = !new File(root, "public-folder-declined").isFile(); return; }
        try {
            File chosen = choose(false);
            if (chosen != null) use(chosen);
        } catch (Throwable t) {
            base = null;
        }
    }

    /** Picks the folder. Never creates "(2)" while an earlier install's folder could still be reused. */
    private static File choose(boolean declined) throws IOException {
        String id = installId();
        File remembered = remembered();
        File main = new File(downloads, storageName());
        if (remembered != null && downloads.equals(remembered.getParentFile()) && state(remembered, id, false) == OURS
                && !(allFiles() && !remembered.equals(main) && isAppFolder(main))) return remembered;
        int s = state(main, id, true);
        if (s == OURS) { waiting = false; return main; }
        // Android may hide an earlier install's marker entirely. Wait for a real grant before
        // choosing another folder, rather than treating an inaccessible folder as absent.
        if (!allFiles() && !declined && !new File(root, "public-folder-declined").isFile()) { waiting = true; return null; }
        if (s == FOREIGN) {
            if (allFiles() && isAppFolder(main)) { adopt(main, id); waiting = false; return main; }
            for (File d : numbered()) if (!d.equals(main) && state(d, id, false) == OURS) { waiting = false; return d; }
            if (isAppFolder(main) && !declined && !new File(root, "public-folder-declined").isFile()) { waiting = true; return null; }
        }
        for (int i = 2; i <= 50; i++) {
            File dir = new File(downloads, storageName() + " (" + i + ")");
            if (state(dir, id, true) == OURS) { waiting = false; return dir; }
        }
        return null;
    }

    private static void use(File chosen) throws IOException {
        if (isLink(chosen)) throw new IOException("The download folder is a link, not an app folder");
        for (String[] link : LINKS) if (isLink(new File(chosen, link[1]))) throw new IOException("A download subfolder is a link");
        for (String[] link : LINKS) linkFolder(link[0], new File(chosen, link[1]));
        base = chosen;
        remember(chosen);
        startMover();
    }

    /** Folders can be deleted while the app runs (e.g. in Files): put them back before saving. */
    static void ensure() {
        File b = base;
        if (b == null) return;
        try {
            if (isLink(b)) return;
            for (String[] link : LINKS) if (isLink(new File(b, link[1]))) return;
            b.mkdirs();
            noMedia(b);
            for (String[] link : LINKS) { File d = new File(b, link[1]); d.mkdirs(); noMedia(d); }
        } catch (Throwable ignored) {}
    }

    /** Settings › Delete downloads: empties the folder but keeps it (and its link). */
    static void clear(File forgeRoot, String privateName) {
        File link = new File(forgeRoot, privateName);
        if (isLink(link) && !safePublicLink(link, privateName)) return;
        removeKnown(link, privateName, "");       // unrelated files stay even in a private cache folder
        File moving = new File(forgeRoot, privateName + ".moving");
        if (moving.exists() && !isLink(moving)) { removeKnown(moving, privateName, ""); deleteEmptyDirs(moving); }
        ensure();
    }

    // ------------------------------------------------------------------ earlier installs + permission

    /** What the download screens need to know before downloading. */
    static synchronized JSONObject check() throws Exception {
        JSONObject out = new JSONObject().put("android", sdk).put("permission", allFiles()).put("permissionKind", sdk >= 30 ? "all-files" : "storage");
        if (sdk < 26 || downloads == null) return out.put("public", false).put("private", true).put("needsChoice", false).put("old", new JSONArray());
        // access was just granted in Settings: take the earlier folder over now
        if (allFiles()) {
            File main = new File(downloads, storageName());
            if ((base == null || !base.equals(main)) && isAppFolder(main)) {
                adopt(main, installId());
                use(main);
                waiting = false;
            } else if (base == null) {
                File chosen = choose(false);
                if (chosen != null) use(chosen);
            }
        }
        JSONArray old = new JSONArray();
        for (File d : otherAppFolders()) old.put(new JSONObject().put("name", d.getName()).put("path", display(d)));
        return out.put("public", base != null).put("private", base == null).put("unavailable", base == null && allFiles()).put("folder", label()).put("waiting", waiting)
                .put("needsChoice", waiting || (!allFiles() && old.length() > 0 && !new File(root, "public-folder-declined").isFile())).put("old", old);
    }

    /** Opens Android's "All files access" screen for this app (the supported way to get it). */
    static boolean requestAccess(android.app.Activity activity) {
        if (activity == null || sdk < 26) return false;
        if (sdk < 30) {
            final android.app.Activity a = activity;
            activity.runOnUiThread(new Runnable() { public void run() {
                try { a.getClass().getMethod("requestPermissions", String[].class, int.class).invoke(a,
                        new Object[]{new String[]{"android.permission.READ_EXTERNAL_STORAGE", "android.permission.WRITE_EXTERNAL_STORAGE"}, Integer.valueOf(0x5f2)}); }
                catch (Throwable ignored) {}
            }});
            return true;
        }
        String pkg = activity.getPackageName();
        String[] actions = {"android.settings.MANAGE_APP_ALL_FILES_ACCESS_PERMISSION", "android.settings.MANAGE_ALL_FILES_ACCESS_PERMISSION"};
        for (int i = 0; i < actions.length; i++) {
            try {
                Class<?> intentClass = Class.forName("android.content.Intent");
                Object intent = intentClass.getConstructor(String.class).newInstance(actions[i]);
                if (i == 0) {
                    Object uri = Class.forName("android.net.Uri").getMethod("parse", String.class).invoke(null, "package:" + pkg);
                    intentClass.getMethod("setData", Class.forName("android.net.Uri")).invoke(intent, uri);
                }
                activity.startActivity((android.content.Intent) intent);
                return true;
            } catch (Throwable ignored) {}
        }
        return false;
    }

    /** The person chose not to give access: use a separate folder (Android doesn't allow reusing the old one). */
    static synchronized JSONObject decline() throws Exception {
        root.mkdirs();
        try { write(new File(root, "public-folder-declined"), "1"); } catch (Throwable ignored) {}
        if (base == null && sdk >= 30 && downloads != null) {
            File chosen = choose(true);
            if (chosen != null) use(chosen);
        }
        waiting = false;
        return check();
    }

    static boolean allFiles() {
        Boolean t = allFilesForTest;
        if (t != null) return t;
        if (sdk < 26) return false;
        if (sdk < 30) {
            try {
                if (appContext == null || ((Integer) appContext.getClass().getMethod("checkSelfPermission", String.class)
                        .invoke(appContext, "android.permission.WRITE_EXTERNAL_STORAGE")).intValue() != 0) return false;
                if (sdk == 29 && !((Boolean) Class.forName("android.os.Environment").getMethod("isExternalStorageLegacy").invoke(null))) return false;
                return true;
            } catch (Throwable e) { return false; }
        }
        try { return (Boolean) Class.forName("android.os.Environment").getMethod("isExternalStorageManager").invoke(null); } catch (Throwable e) { return false; }
    }

    /** Takes over a folder from an earlier install (needs All files access). Its files are re-owned during the next clean-up. */
    private static void adopt(File dir, String id) throws IOException {
        dir.mkdirs();
        File marker = new File(dir, markerName());
        String before = "";
        try { before = marker.isFile() ? readSmall(marker) : ""; } catch (Throwable ignored) {}
        write(marker, id);
        noMedia(dir);
        if (!id.equals(before)) {
            try { write(new File(root, "public-reown.txt"), dir.getPath()); } catch (Throwable ignored) {}
        }
    }

    /** Other folders made by this app (earlier installs, "(2)" copies), never the one in use. */
    static List<File> otherAppFolders() {
        List<File> out = new ArrayList<File>();
        if (downloads == null) return out;
        for (File d : numbered()) if (!d.equals(base) && isAppFolder(d)) out.add(d);
        if (allFiles()) for (File d : markerScan()) if (!d.equals(base) && !out.contains(d)) out.add(d);
        return out;
    }

    private static List<File> numbered() {
        List<File> out = new ArrayList<File>();
        out.add(new File(downloads, storageName()));
        File[] list = downloads.listFiles();
        if (list != null) for (File f : list) if (f.isDirectory() && Pattern.compile(Pattern.quote(storageName()) + "(?: \\([0-9]{1,3}\\))?").matcher(f.getName()).matches() && !out.contains(f)) out.add(f);
        for (int i = 2; i <= 50; i++) {
            File f = new File(downloads, storageName() + " (" + i + ")");
            if (!out.contains(f) && f.exists()) out.add(f);
        }
        return out;
    }

    /** A folder this app made: our name (or marker) and nothing but the app's own sub-folders and files. */
    static boolean isAppFolder(File d) {
        if (d == null || !d.isDirectory() || isLink(d)) return false;
        try {
            File marker = new File(d, markerName());
            if (isLink(marker) || !marker.isFile() || !readSmall(marker).matches("[a-f0-9-]{36}")) return false;
            for (String[] link : LINKS) if (isLink(new File(d, link[1]))) return false;
            return true;
        } catch (Throwable ignored) { return false; }
    }

    /** With All files access: finds the app's folders anywhere on the phone's shared storage (by marker). */
    private static List<File> markerScan() {
        List<File> out = new ArrayList<File>();
        File top = downloads == null ? null : downloads.getParentFile();
        if (top == null) return out;
        int[] budget = {20000};
        scan(top, 0, out, budget);
        return out;
    }

    private static void scan(File dir, int depth, List<File> out, int[] budget) {
        if (depth > 3 || budget[0] <= 0) return;
        File[] list = dir.listFiles();
        if (list == null) return;
        for (File f : list) {
            if (--budget[0] <= 0) return;
            if (!f.isDirectory() || isLink(f)) continue;
            String n = f.getName();
            if (depth == 0 && n.equals("Android")) continue;
            if (n.startsWith(".")) continue;
            if (new File(f, markerName()).exists()) { out.add(f); continue; }
            scan(f, depth + 1, out, budget);
        }
    }

    // ------------------------------------------------------------------ clean-up before downloads

    interface Network {
        /** Size of the script on Eclipse, or -1 when unknown (offline, error). */
        long scriptSize(String path);
    }

    static final class Report {
        long freedBytes, removed, reused, reowned, conflicts;
        final List<String> merged = new ArrayList<String>();
        boolean adopted;
        JSONObject json() throws Exception {
            return new JSONObject().put("freedBytes", freedBytes).put("removed", removed).put("reused", reused)
                    .put("reowned", reowned).put("conflicts", conflicts).put("merged", new JSONArray(merged)).put("adopted", adopted);
        }
    }

    /**
     * Runs before every download. Merges the app's other folders into the one in use (with access),
     * re-owns files taken over from an earlier install, removes duplicates, half-finished files and
     * outdated copies, and keeps every file that is still valid so it isn't downloaded again.
     *   scriptKey   the current game-data key (animation scripts for other keys are outdated)
     *   keepKeys    asset keys the UI still uses (saved animations, drafts)
     */
    static Report tidy(File forgeRoot, File cacheDir, String scriptKey, Set<String> keepKeys, Network net) {
        Report r = new Report();
        try {
            File b = base;
            if (b != null && isAppFolder(b)) {
                if (allFiles()) {
                    for (File other : otherAppFolders()) {
                        mergeInto(other, b, r);
                        r.merged.add(display(other));
                    }
                    File pending = new File(forgeRoot, "public-reown.txt");
                    if (pending.isFile()) {
                        r.adopted = true;
                        if (reown(b, r)) pending.delete();
                    }
                }
                cleanFolder(b, r);
            }
            scripts(new File(forgeRoot, "animation-sources"), scriptKey, net, r);
            cleanPrivate(forgeRoot, cacheDir, keepKeys, r);
            synchronized (MOVED) {                 // what the background move already tidied counts too
                r.freedBytes += MOVED.freedBytes; r.removed += MOVED.removed;
                MOVED.freedBytes = 0; MOVED.removed = 0; MOVED.reused = 0;
            }
        } catch (Throwable ignored) {}
        return r;
    }

    private static void removeKnown(File dir, String kind, String rel) {
        File[] list = dir.listFiles();
        if (list == null) return;
        for (File f : list) {
            if (isLink(f)) continue;
            String path = rel.isEmpty() ? f.getName() : rel + "/" + f.getName();
            if (f.isDirectory() && !isLink(f)) {
                if (kind.equals("animation-sources") && path.matches("[A-Za-z0-9_-]{1,80}(/ab_script(/[A-Za-z0-9_-]+)*)?")) { removeKnown(f, kind, path); deleteEmptyDirs(f); }
                continue;
            }
            if (known(kind, path)) f.delete();
        }
    }

    /** Moves the app's own files from another of its folders into ours; duplicates are removed. */
    private static void mergeInto(File from, File into, Report r) {
        if (!isAppFolder(from) || !isAppFolder(into)) return;
        for (String[] link : LINKS) {
            File src = new File(from, link[1]);
            if (src.isDirectory()) moveKnown(src, new File(into, link[1]), link[0], "", r);
        }
        // Keep the marker while conflicts or personal files remain, so a later retry can find it.
        deleteEmptyDirs(from);
    }

    private static synchronized void moveKnown(File from, File to, String kind, String rel, Report r) {
        if (isLink(to) && !safePublicLink(to, kind)) return;
        File[] list = from.listFiles();
        if (list == null) return;
        to.mkdirs();
        noMedia(to);
        for (File f : list) {
            if (isLink(f)) continue;
            String name = f.getName(), path = rel.isEmpty() ? name : rel + "/" + name;
            if (f.isDirectory() && !isLink(f)) {
                if (kind.equals("animation-sources") && path.matches("[A-Za-z0-9_-]{1,80}(/ab_script(/[A-Za-z0-9_-]+)*)?")) moveKnown(f, new File(to, name), kind, path, r);
                continue;
            }
            if (name.equals(".nomedia")) { f.delete(); continue; }
            if (!known(kind, path)) continue;               // not the app's: never touched
            if (isTemp(name)) { r.freedBytes += f.length(); r.removed++; f.delete(); continue; }
            if (kind.equals("movie-cache") && name.endsWith(".mp4")) name = name.substring(0, name.length() - 4) + ".video";
            File dest = new File(to, name);
            if (dest.exists()) {
                if (!isLink(dest) && sameBytes(f, dest)) {
                    long bytes = f.length();
                    if (f.delete()) { r.freedBytes += bytes; r.removed++; }
                } else r.conflicts++;      // same name is not proof that the source is disposable
                continue;
            }
            if (!f.renameTo(dest)) {
                File stage = new File(to, name + ".moving-part");
                try {
                    copy(f, stage);
                    if (!sameBytes(f, stage)) throw new IOException("Migration copy did not match");
                    // Copying across /data and shared storage must not expose a half-written cache entry.
                    // No REPLACE_EXISTING: a concurrent completed download must not be overwritten.
                    Files.move(stage.toPath(), dest.toPath());
                    f.delete();
                } catch (Throwable ignored) {} finally { stage.delete(); }
            }
            if (!f.exists() && dest.isFile()) r.reused++;
        }
    }

    /** The app's own file names, per folder; anything else is left alone. */
    static boolean known(String kind, String path) {
        if (path.endsWith(".moving-part")) return known(kind, path.substring(0, path.length() - 12));
        String name = path.substring(path.lastIndexOf('/') + 1);
        if (kind.equals("preview-cache")) return name.matches("[a-f0-9]{64}\\.(body|json|tmp)(\\.tmp)?|[a-f0-9]{64}\\.j?part\\d+|settings\\.json") && !path.contains("/");
        if (kind.equals("movie-cache")) return name.matches("[a-f0-9]{64}-[a-z]{1,4}\\.(video|mp4|part)") && !path.contains("/");
        if (kind.equals("animation-sources")) return path.matches("[A-Za-z0-9_-]{1,80}/ab_script/[A-Za-z0-9_/-]+\\.lua(\\.part)?");
        if (kind.equals("sparking/resource-cache")) return name.matches("\\d{1,20}-\\d{1,12}\\.(data|json)|sparking-asset-[0-9a-f-]{36}\\.tmp") && !path.contains("/");
        return false;
    }

    private static boolean isTemp(String name) {
        return name.matches(".*\\.(j?part\\d*|moving-part|tmp)$") || name.startsWith(".probe-");
    }

    /** Files taken over from an earlier install are rewritten so this install owns them (works after access is turned off again). */
    private static boolean reown(File dir, Report r) {
        boolean complete = true;
        for (String[] link : LINKS) complete &= reownKnown(new File(dir, link[1]), link[0], "", r);
        return complete;
    }

    private static boolean reownKnown(File dir, String kind, String rel, Report r) {
        File[] list = dir.listFiles();
        if (list == null) return !dir.exists();
        boolean complete = true;
        for (File f : list) {
            if (isLink(f)) continue;
            String path = rel.isEmpty() ? f.getName() : rel + "/" + f.getName();
            if (f.isDirectory()) { if (kind.equals("animation-sources") && path.matches("[A-Za-z0-9_-]{1,80}(/ab_script(/[A-Za-z0-9_-]+)*)?")) complete &= reownKnown(f, kind, path, r); continue; }
            if (!f.isFile()) continue;
            String name = f.getName();
            if (!known(kind, path)) continue;
            File tmp = new File(dir, ".reown-" + UUID.randomUUID() + ".tmp");
            try {
                copy(f, tmp);
                if (!sameBytes(tmp, f)) { tmp.delete(); complete = false; continue; }
                long modified = f.lastModified();
                replace(tmp, f);       // replace atomically; never delete the only copy before a rename
                f.setLastModified(modified);
                r.reowned++;
            } catch (Throwable t) {
                tmp.delete();
                complete = false;
            }
        }
        return complete;
    }

    /** Half-finished files and older formats inside our folder. */
    private static void cleanFolder(File b, Report r) {
        long old = System.currentTimeMillis() - 10L * 60 * 1000;
        File[] top = b.listFiles();
        if (top != null) for (File f : top) if (f.isFile() && f.getName().startsWith(".probe-")) f.delete();
        File game = new File(b, "Game files");
        File[] list = game.listFiles();
        if (list != null) {
            Set<String> names = new HashSet<String>();
            for (File f : list) names.add(f.getName());
            for (File f : list) {
                String n = f.getName();
                if (f.lastModified() > old) continue;
                boolean half = (n.matches("[a-f0-9]{64}\\.body") && !names.contains(n.substring(0, 64) + ".json"))
                        || (n.matches("[a-f0-9]{64}\\.json") && !names.contains(n.substring(0, 64) + ".body"));
                if (half || (known("preview-cache", n) && isTemp(n))) { r.freedBytes += f.length(); r.removed++; f.delete(); }
            }
        }
        File movies = new File(b, "Game movies");
        list = movies.listFiles();
        if (list != null) for (File f : list) {
            String n = f.getName();
            if (!known("movie-cache", n)) continue;
            if (isTemp(n) && f.lastModified() <= old) { r.freedBytes += f.length(); r.removed++; f.delete(); }
            else if (n.endsWith(".mp4")) {
                File v = new File(movies, n.substring(0, n.length() - 4) + ".video");
                if (v.exists()) { r.freedBytes += f.length(); r.removed++; f.delete(); } else f.renameTo(v);
            }
        }
        File spark = new File(b, "Sparking files");
        list = spark.listFiles();
        if (list != null) for (File f : list) if (known("sparking/resource-cache", f.getName()) && isTemp(f.getName()) && f.lastModified() <= old) { r.freedBytes += f.length(); r.removed++; f.delete(); }
    }

    /**
     * Animation scripts are kept per game-data version. When the game data changes, a script from the
     * older version that is still the same size on Eclipse is moved over (no download); the rest of the
     * outdated copies are removed.
     */
    private static void scripts(File sources, String key, Network net, Report r) {
        if (key == null || key.isEmpty() || !key.matches("[A-Za-z0-9_-]{1,80}")) return;
        File[] keys = sources.listFiles();
        if (keys == null) return;
        File current = new File(sources, key);
        for (File k : keys) {
            if (!k.isDirectory() || k.getName().equals(key) || !k.getName().matches("[A-Za-z0-9_-]{1,80}")) continue;
            if (!new File(k, "ab_script").isDirectory()) continue;      // not a script folder of ours
            reuseScripts(new File(k, "ab_script"), new File(current, "ab_script"), "ab_script", net, r);
            deleteEmptyDirs(k);
        }
    }

    private static void reuseScripts(File from, File to, String rel, final Network net, final Report r) {
        final List<File[]> candidates = new ArrayList<File[]>();
        final List<String> paths = new ArrayList<String>();
        collectScripts(from, to, rel, candidates, paths, r);
        if (candidates.isEmpty()) return;
        java.util.concurrent.ExecutorService pool = java.util.concurrent.Executors.newFixedThreadPool(6);
        for (int i = 0; i < candidates.size(); i++) {
            final File f = candidates.get(i)[0], dest = candidates.get(i)[1];
            final String path = paths.get(i);
            pool.execute(new Runnable() {
                public void run() {
                    long size = net == null ? -1 : net.scriptSize(path);
                    if (size == -2) return;                                    // offline: keep it for now
                    synchronized (r) {
                        if (size >= 0 && size == f.length() && !dest.exists()) {
                            dest.getParentFile().mkdirs();
                            if (f.renameTo(dest)) { r.reused++; return; }
                        }
                        r.freedBytes += f.length(); r.removed++;
                        f.delete();
                    }
                }
            });
        }
        pool.shutdown();
        try { pool.awaitTermination(30, java.util.concurrent.TimeUnit.MINUTES); } catch (InterruptedException ignored) {}
    }

    private static void collectScripts(File from, File to, String rel, List<File[]> out, List<String> paths, Report r) {
        File[] list = from.listFiles();
        if (list == null) return;
        for (File f : list) {
            String path = rel + "/" + f.getName();
            if (f.isDirectory() && !isLink(f)) { collectScripts(f, new File(to, f.getName()), path, out, paths, r); continue; }
            if (!f.getName().matches("[A-Za-z0-9_-]+\\.lua(\\.part)?")) continue;
            File dest = new File(to, f.getName());
            if (f.getName().endsWith(".part") || dest.exists()) { r.freedBytes += f.length(); r.removed++; f.delete(); continue; }
            out.add(new File[]{f, dest});
            paths.add(path);
        }
    }

    /** Leftovers inside the app: old preview and import staging, and Sparking copies nothing uses any more. */
    private static void cleanPrivate(File forgeRoot, File cacheDir, Set<String> keepKeys, Report r) {
        long day = System.currentTimeMillis() - 24L * 3600 * 1000, twoDays = System.currentTimeMillis() - 48L * 3600 * 1000;
        if (cacheDir != null) {
            File[] previews = new File(cacheDir, "animation-preview").listFiles();
            if (previews != null) for (File f : previews) if (f.lastModified() < day) { r.freedBytes += size(f); r.removed++; removeTree(f.toPath()); }
            File[] list = cacheDir.listFiles();
            if (list != null) for (File f : list) if (f.getName().matches("sparking-(data-|snapshot-)?[0-9a-f-]{36}(\\.db)?") && f.lastModified() < day) { r.freedBytes += size(f); r.removed++; removeTree(f.toPath()); }
        }
        // per-download Sparking copies under forge/assets: removed only when no saved unit, saved version,
        // saved animation or draft refers to them
        if (keepKeys == null) return;                                    // not sure what saved animations use: keep all
        File assets = new File(forgeRoot, "assets");
        File[] list = assets.listFiles();
        if (list == null) return;
        Set<String> used = new HashSet<String>(keepKeys);
        boolean complete = collectKeys(new File(forgeRoot, "projects"), used) & collectKeys(new File(forgeRoot, "project-versions"), used);
        if (!complete) return;                                           // couldn't read everything: delete nothing
        for (File f : list) {
            String n = f.getName();
            if (!f.isDirectory() || isLink(f) || !n.matches("sparking-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")) continue;
            if (used.contains(n) || f.lastModified() > twoDays) continue;
            r.freedBytes += size(f); r.removed++;
            removeTree(f.toPath());
        }
    }

    private static final Pattern KEY = Pattern.compile("sparking-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}");

    private static boolean collectKeys(File dir, Set<String> out) {
        if (!dir.exists()) return true;
        File[] list = dir.listFiles();
        if (list == null) return false;
        boolean ok = true;
        for (File f : list) {
            if (f.isDirectory()) { ok &= collectKeys(f, out); continue; }
            try {
                if (f.length() > 64L * 1024 * 1024) { ok = false; continue; }
                Matcher m = KEY.matcher(new String(Files.readAllBytes(f.toPath()), StandardCharsets.UTF_8));
                while (m.find()) out.add(m.group());
            } catch (Throwable t) {
                ok = false;
            }
        }
        return ok;
    }

    // ------------------------------------------------------------------ folder state

    private static final int OURS = 1, FOREIGN = 2, UNUSABLE = 3;

    /** OURS: made by this install (claims a new/empty folder when allowed); FOREIGN: made by an earlier install. */
    private static int state(File dir, String id, boolean claim) {
        try {
            if (isLink(dir)) return UNUSABLE;
            File marker = new File(dir, markerName());
            if (marker.exists()) {
                if (isLink(marker)) return UNUSABLE;
                if (!marker.canRead()) return FOREIGN;
                return id.equals(readSmall(marker)) ? OURS : FOREIGN;
            }
            if (dir.exists() && !dir.isDirectory()) return UNUSABLE;
            if (!dir.isDirectory()) {
                if (!claim) return UNUSABLE;
                if (!dir.mkdirs()) return dir.exists() ? FOREIGN : UNUSABLE; // hidden from us: an earlier install's
            } else {
                File[] visible = dir.listFiles();
                if (visible != null) for (File f : visible) if (!f.getName().equals(".nomedia")) return FOREIGN;
                if (!claim) return UNUSABLE;
            }
            if (!marker.createNewFile()) return FOREIGN;            // a marker we can't see: an earlier install's
            write(marker, id);
            if (!id.equals(readSmall(marker))) return UNUSABLE;
            File probe = new File(dir, ".probe-" + UUID.randomUUID());
            write(probe, "ok");
            boolean good = "ok".equals(readSmall(probe));
            probe.delete();
            noMedia(dir);
            return good ? OURS : UNUSABLE;
        } catch (Throwable t) {
            return UNUSABLE;
        }
    }

    private static String installId() throws IOException {
        root.mkdirs();
        File f = new File(root, "public-folder-id.txt");
        if (f.isFile()) {
            String v = readSmall(f);
            if (v.matches("[a-f0-9-]{36}")) return v;
        }
        String v = UUID.randomUUID().toString();
        write(f, v);
        return v;
    }

    private static File remembered() {
        try {
            File f = new File(root, "public-folder.txt");
            if (!f.isFile()) return null;
            String v = readSmall(f);
            return v.isEmpty() ? null : new File(v);
        } catch (Throwable t) {
            return null;
        }
    }

    private static void remember(File dir) {
        try { write(new File(root, "public-folder.txt"), dir.getPath()); } catch (Throwable ignored) {}
    }

    private static String display(File d) {
        File top = downloads == null ? null : downloads.getParentFile();
        String p = d.getPath();
        if (top != null && p.startsWith(top.getPath() + "/")) p = p.substring(top.getPath().length() + 1);
        return p.replace("/", " › ");
    }

    // ------------------------------------------------------------------ links

    private static void linkFolder(String privateName, File target) throws IOException {
        target.mkdirs();
        noMedia(target);
        File link = new File(root, privateName);
        if (link.getParentFile() != null) link.getParentFile().mkdirs();
        Path lp = link.toPath();
        File moving = new File(root, privateName + ".moving");
        if (isLink(link)) {
            Path now = Files.readSymbolicLink(lp);
            if (now.toString().equals(target.getPath())) return;
            // it pointed at another of our public folders: what's there is moved over
            Files.delete(lp);
            Files.createSymbolicLink(lp, target.toPath());
            File old = new File(now.toString());
            if (old.isDirectory() && !isLink(old) && isAppFolder(old.getParentFile()) && !moving.exists() && !isLink(moving)) {
                try { Files.createSymbolicLink(moving.toPath(), old.toPath()); } catch (Throwable ignored) {}
            }
            return;
        }
        if (link.exists()) {
            // the private folder becomes "<name>.moving"; its files move over in the background
            if (moving.exists() && !isLink(moving)) {
                File[] children = link.listFiles();
                if (children != null) for (File c : children) {
                    File to = new File(moving, c.getName());
                    if (!to.exists()) c.renameTo(to);
                }
                File[] remaining = link.listFiles();
                if (remaining != null && remaining.length > 0) throw new IOException("Earlier private files were kept because a migration is still pending");
                Files.deleteIfExists(lp);
            } else if (!link.renameTo(moving)) {
                return; // keep the private folder working rather than lose anything
            }
        }
        try {
            Files.createSymbolicLink(lp, target.toPath());
        } catch (Throwable t) {
            if (!link.exists() && moving.isDirectory() && !isLink(moving)) moving.renameTo(link);
            else link.mkdirs();
            throw t instanceof IOException ? (IOException) t : new IOException(t);
        }
    }

    static boolean isLink(File f) {
        try { return Files.isSymbolicLink(f.toPath()); } catch (Throwable t) { return false; }
    }

    private static boolean safePublicLink(File link, String kind) {
        File b = base;
        if (b == null || !isAppFolder(b)) return false;
        for (String[] entry : LINKS) if (entry[0].equals(kind)) {
            File target = new File(b, entry[1]);
            try { return !isLink(target) && link.getCanonicalFile().equals(target.getCanonicalFile()); }
            catch (IOException ignored) { return false; }
        }
        return false;
    }

    static void noMedia(File dir) {
        try {
            File n = new File(dir, ".nomedia");
            if (!n.exists()) n.createNewFile();
        } catch (Throwable ignored) {}
    }

    // ------------------------------------------------------------------ moving old files

    private static synchronized void startMover() {
        Thread running = mover;
        if (running != null && running.isAlive()) return;
        boolean any = false;
        for (String[] link : LINKS) { File m = new File(root, link[0] + ".moving"); if (m.exists() || isLink(m)) any = true; }
        if (!any) return;
        final File r = root;
        Thread t = new Thread(new Runnable() {
            public void run() {
                for (String[] link : LINKS) {
                    File from = new File(r, link[0] + ".moving");
                    if (!from.exists() && !isLink(from)) continue;
                    try {
                        synchronized (MOVED) { moveKnown(from, new File(r, link[0]), link[0], "", MOVED); }
                        if (isLink(from)) {
                            File target = new File(Files.readSymbolicLink(from.toPath()).toString());
                            Files.delete(from.toPath());
                            deleteEmptyDirs(target);
                        } else {
                            deleteEmptyDirs(from);
                            // anything left that isn't ours stays private, untouched
                        }
                    } catch (Throwable ignored) {}
                }
            }
        }, "forge-public-storage");
        t.setDaemon(true);
        t.setPriority(Thread.MIN_PRIORITY);
        mover = t;
        t.start();
    }

    static void awaitMove(long ms) throws InterruptedException {
        Thread t = mover;
        if (t != null) t.join(ms);
    }

    // ------------------------------------------------------------------ small helpers

    /** Removes empty folders (and the app's own marker/.nomedia files when nothing else is left). */
    private static boolean deleteEmptyDirs(File dir) {
        if (!dir.isDirectory() || isLink(dir)) return false;
        File[] list = dir.listFiles();
        boolean empty = true;
        if (list != null) for (File f : list) {
            if (f.isDirectory() && !isLink(f)) { if (!deleteEmptyDirs(f)) empty = false; }
            else if (!f.getName().equals(".nomedia") && !f.getName().equals(markerName())) empty = false;
        }
        if (!empty) return false;
        if (list != null) for (File f : list) f.delete();
        return dir.delete();
    }

    private static long size(File f) {
        if (f.isFile()) return f.length();
        long total = 0;
        File[] list = f.isDirectory() && !isLink(f) ? f.listFiles() : null;
        if (list != null) for (File c : list) total += size(c);
        return total;
    }

    private static void copy(File from, File to) throws IOException {
        InputStream in = new FileInputStream(from);
        try {
            FileOutputStream out = new FileOutputStream(to);
            try {
                byte[] b = new byte[65536];
                int n;
                while ((n = in.read(b)) != -1) out.write(b, 0, n);
                out.getFD().sync();
            } finally { out.close(); }
        } finally { in.close(); }
    }

    private static boolean sameBytes(File a, File b) {
        if (!a.isFile() || !b.isFile() || a.length() != b.length()) return false;
        try (InputStream x = new FileInputStream(a); InputStream y = new FileInputStream(b)) {
            byte[] xb = new byte[65536], yb = new byte[65536];
            int n;
            while ((n = x.read(xb)) != -1) {
                int used = 0;
                while (used < n) { int m = y.read(yb, used, n - used); if (m < 0) return false; used += m; }
                for (int i = 0; i < n; i++) if (xb[i] != yb[i]) return false;
            }
            return y.read() == -1;
        } catch (Throwable ignored) { return false; }
    }

    private static void replace(File from, File to) throws IOException {
        try { Files.move(from.toPath(), to.toPath(), StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE); }
        catch (java.nio.file.AtomicMoveNotSupportedException e) { Files.move(from.toPath(), to.toPath(), StandardCopyOption.REPLACE_EXISTING); }
    }

    /** Deletes a tree; a link is removed without touching what it points to. */
    static void removeTree(Path p) {
        try {
            if (Files.isSymbolicLink(p)) { Files.delete(p); return; }
            File f = p.toFile();
            File[] children = f.isDirectory() ? f.listFiles() : null;
            if (children != null) for (File c : children) removeTree(c.toPath());
            Files.deleteIfExists(p);
        } catch (Throwable ignored) {}
    }

    private static String readSmall(File f) throws IOException {
        if (f.length() > 4096) throw new IOException("too large");
        return new String(Files.readAllBytes(f.toPath()), StandardCharsets.UTF_8).trim();
    }

    private static void write(File f, String text) throws IOException {
        FileOutputStream out = new FileOutputStream(f);
        try { out.write(text.getBytes(StandardCharsets.UTF_8)); } finally { out.close(); }
    }

    private static int sdkInt() {
        try { return Class.forName("android.os.Build$VERSION").getField("SDK_INT").getInt(null); } catch (Throwable t) { return 0; }
    }

    private static File downloadsDir() {
        try {
            Class<?> env = Class.forName("android.os.Environment");
            String st = (String) env.getMethod("getExternalStorageState").invoke(null);
            if (!"mounted".equals(st)) return null;
            String type = (String) env.getField("DIRECTORY_DOWNLOADS").get(null);
            return (File) env.getMethod("getExternalStoragePublicDirectory", String.class).invoke(null, type);
        } catch (Throwable t) {
            return null;
        }
    }

    /** Tests only. */
    static synchronized void resetForTest() {
        prepared = false; base = null; root = null; downloads = null; sdk = 0; mover = null; waiting = false; allFilesForTest = null; appContext = null; development = false;
    }
}
