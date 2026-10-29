package com.personal.aihub;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;

import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.Enumeration;
import java.util.UUID;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import java.util.zip.ZipOutputStream;

/**
 * "Import to Eclipse" / "Import to Sparking" at the end of a unit.
 *
 * Both game apps are patched copies of Dokkan Battle with their own patch importers (checked in their APKs,
 * see AI-Workspace/Dokkan-Unit-Creator/docs/SEND-TO-GAME.md):
 *  - Eclipse (com.anthen.eclipse) imports .eclp files from its in-game file browser.
 *  - Sparking (com.sparkingDokkan.GLB) lists .sprk files in Internal storage/Download/Sparking/ in its
 *    "SPRK File Manager" and imports them from there.
 * Neither app accepts files from other apps directly (no intent filters), so the unit is saved where each app
 * looks (Download/Eclipse, Download/Sparking) and the app is opened.
 *
 * SPRK version 1 = "SPRK" 01 | IV[16] | AES-256-CTR(ZIP): patch_info.json, patches/sql/*.sql, patches/assets/*.
 * The key is the one the user's own Sparking APK carries (saved by the Sparking set-up as sprk-format-key.bin).
 */
final class SendToGame {
    static final String ECLIPSE = "com.anthen.eclipse", SPARKING = "com.sparkingDokkan.GLB";

    private SendToGame() {}

    static JSONObject send(File root, JSONObject args) throws Exception {
        final Activity activity = ForgeFixes.activity();
        if (activity == null) throw new IOException("The app is still starting.");
        String target = args.optString("target", "");
        if (!"eclipse".equals(target) && !"sparking".equals(target)) throw new IOException("Choose Eclipse or Sparking.");
        JSONObject request = new JSONObject(args.getJSONObject("request").toString());
        String base = safeName(request.optString("name", "My unit").replaceAll("(?i)\\.(eclp|zip|sprk)$", ""));
        File downloads = downloadsDir();
        if (downloads == null) throw new IOException("Your phone's Download folder isn't available right now.");
        File work = new File(activity.getCacheDir(), "send-" + UUID.randomUUID());
        if (!work.mkdirs()) throw new IOException("Couldn't prepare the file.");
        try {
            Method write = activity.getClass().getDeclaredMethod("writeExport", Uri.class, JSONObject.class);
            write.setAccessible(true);
            File dest;
            boolean existed = false, same = false;
            if ("eclipse".equals(target)) {
                request.put("kind", "eclp").put("name", base + ".eclp");
                File eclp = new File(work, base + ".eclp");
                write.invoke(activity, Uri.fromFile(eclp), request);
                dest = new File(new File(downloads, "Eclipse"), base + ".eclp");
                existed = dest.exists();
                byte[] before = existed ? sha256(dest) : null;
                copy(eclp, dest);
                same = before != null && java.util.Arrays.equals(before, sha256(dest));
            } else {
                byte[] key = readKey(new File(root, "sprk-format-key.bin"));
                try {
                    request.put("kind", "zip").put("name", base + ".zip");
                    File zip = new File(work, base + ".zip");
                    write.invoke(activity, Uri.fromFile(zip), request);
                    File sprkZip = new File(work, base + "-sprk.zip");
                    toSparkingZip(zip, sprkZip, request);
                    dest = new File(new File(downloads, "Sparking"), base + ".sprk");
                    existed = dest.exists();
                    byte[] before = existed ? sha256(dest) : null;
                    encrypt(sprkZip, dest, key);
                    same = before != null && java.util.Arrays.equals(before, sha256(dest));
                } finally { java.util.Arrays.fill(key, (byte) 0); }
            }
            boolean opened = open(activity, "eclipse".equals(target) ? ECLIPSE : SPARKING);
            return new JSONObject().put("saved", true).put("opened", opened).put("file", dest.getName())
                .put("folder", "Download › " + dest.getParentFile().getName()).put("path", dest.getAbsolutePath())
                .put("direct", true).put("same", same).put("replaced", existed && !same);
        } catch (java.lang.reflect.InvocationTargetException e) {
            Throwable c = e.getCause() == null ? e : e.getCause();
            throw c instanceof Exception ? (Exception) c : new IOException(String.valueOf(c));
        } finally {
            deleteTree(work);
        }
    }

    /** ECLP-style ZIP (metadata.json, files/…) → Sparking's patch layout. */
    static void toSparkingZip(File in, File out, JSONObject request) throws Exception {
        ZipFile z = new ZipFile(in);
        JSONObject meta = new JSONObject();
        try {
            ZipEntry m = z.getEntry("metadata.json");
            if (m != null) meta = new JSONObject(new String(readAll(z.getInputStream(m)), "UTF-8"));
        } catch (Exception ignored) {}
        ZipOutputStream zo = new ZipOutputStream(new FileOutputStream(out));
        int sql = 0;
        try {
            JSONObject info = new JSONObject()
                .put("name", meta.optString("name", request.optString("name", "My unit").replaceAll("\\.zip$", "")))
                .put("version", meta.optString("version", "1.0"))
                .put("description", meta.optString("description", ""))
                .put("creator_id", 0)   // Sparking 6.6 requires a whole number (0 = no creator group)
                .put("creator_name", meta.optString("author", "").trim().isEmpty() || "null".equals(meta.optString("author")) ? "Dokkan Unit Creator" : meta.optString("author"))
                .put("created_with", "Dokkan Unit Creator");
            put(zo, "patch_info.json", info.toString(2).getBytes("UTF-8"));
            put(zo, "patches/", new byte[0]);       // folder entries, for importers that look for the folder itself
            put(zo, "patches/sql/", new byte[0]);
            Enumeration<? extends ZipEntry> all = z.entries();
            while (all.hasMoreElements()) {
                ZipEntry e = all.nextElement();
                String p = e.getName();
                if (e.isDirectory() || !p.startsWith("files/")) continue;
                String rel = p.substring(6);
                if (!EclpCodec.safePath(rel)) throw new IOException("Unsafe file path in the unit: " + rel);
                byte[] b = readAll(z.getInputStream(e));
                if (rel.toLowerCase(java.util.Locale.ROOT).endsWith(".sql")) {
                    put(zo, "patches/sql/" + rel.replaceFirst("^sparking-sql/", ""), b);
                    sql++;
                } else {
                    put(zo, "patches/assets/" + rel, b);
                }
            }
        } finally {
            zo.close();
            z.close();
        }
        if (sql == 0) throw new IOException("This unit has no game data to send to Sparking.");
    }

    static void encrypt(File zip, File dest, byte[] key) throws Exception {
        if (key == null || key.length != 32) throw new IOException("Set up Sparking first (Library › Sparking).");
        // IV from the patch's own SHA-256: the same unit gives the same file, so sending it again is recognised.
        byte[] iv = java.util.Arrays.copyOf(sha256(zip), 16);
        javax.crypto.Cipher c = javax.crypto.Cipher.getInstance("AES/CTR/NoPadding");
        c.init(javax.crypto.Cipher.ENCRYPT_MODE, new javax.crypto.spec.SecretKeySpec(key, "AES"), new javax.crypto.spec.IvParameterSpec(iv));
        File parent = dest.getParentFile();
        if (parent != null) parent.mkdirs();
        File part = Files.createTempFile(parent.toPath(), ".dokkan-send-", ".part").toFile();
        boolean done = false;
        try (FileOutputStream o = new FileOutputStream(part); InputStream i = new FileInputStream(zip)) {
            o.write(new byte[]{'S', 'P', 'R', 'K', 1});
            o.write(iv);
            byte[] buf = new byte[1 << 16];
            int n;
            while ((n = i.read(buf)) > 0) { byte[] out = c.update(buf, 0, n); if (out != null) o.write(out); }
            byte[] end = c.doFinal();
            if (end != null) o.write(end);
            o.getFD().sync();
        } catch (Exception e) {
            part.delete();
            throw e;
        }
        try {
            if (dest.exists() && java.util.Arrays.equals(sha256(dest), sha256(part))) return;
            replace(part, dest);
            done=true;
        } finally {
            if (!done) part.delete();
        }
    }

    static byte[] sha256(File f) throws Exception {
        java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
        InputStream in = new FileInputStream(f);
        try { byte[] buf = new byte[1 << 16]; int n; while ((n = in.read(buf)) > 0) md.update(buf, 0, n); } finally { in.close(); }
        return md.digest();
    }

    /** Opens the game app if it is installed. */
    static boolean open(final Activity activity, String pkg) {
        try {
            final Intent i = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER).setPackage(pkg).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            final boolean[] ok = {true};
            final Object lock = new Object();
            final boolean[] done = {false};
            activity.runOnUiThread(new Runnable() {
                public void run() {
                    try { activity.startActivity(i); } catch (Throwable t) { ok[0] = false; }
                    synchronized (lock) { done[0] = true; lock.notifyAll(); }
                }
            });
            synchronized (lock) { long until = System.currentTimeMillis() + 3000; while (!done[0] && System.currentTimeMillis() < until) lock.wait(500); }
            return ok[0] && done[0];
        } catch (Throwable t) {
            return false;
        }
    }

    private static byte[] readKey(File f) throws IOException {
        if (!f.isFile() || f.length() != 32) throw new IOException("Set up Sparking first: Library › Sparking (it needs your Sparking APK once).");
        InputStream in = new FileInputStream(f);
        try { return readAll(in); } finally { in.close(); }
    }

    private static void put(ZipOutputStream zo, String name, byte[] b) throws IOException {
        ZipEntry entry = new ZipEntry(name);
        entry.setTime(315532800000L);   // fixed time: the same unit gives the same file
        zo.putNextEntry(entry);
        zo.write(b);
        zo.closeEntry();
    }

    private static byte[] readAll(InputStream in) throws IOException {
        ByteArrayOutputStream o = new ByteArrayOutputStream();
        byte[] buf = new byte[1 << 16];
        try (InputStream source = in) {
            int n;
            while ((n = source.read(buf)) > 0) o.write(buf, 0, n);
        }
        return o.toByteArray();
    }

    static void copy(File from, File to) throws IOException {
        File parent = to.getParentFile();
        if (parent != null && !parent.isDirectory() && !parent.mkdirs()) throw new IOException("Couldn't create Download › " + parent.getName() + ".");
        File part = Files.createTempFile(parent.toPath(), ".dokkan-send-", ".part").toFile();
        boolean done = false;
        try (InputStream in = new FileInputStream(from); FileOutputStream out = new FileOutputStream(part)) {
            byte[] buf = new byte[1 << 16];
            int n;
            while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
            out.getFD().sync();
        } catch (IOException e) {
            part.delete();
            throw e;
        }
        try {
            replace(part,to);
            done=true;
        } finally { if (!done) part.delete(); }
    }

    private static void replace(File part, File destination) throws IOException {
        // Never remove the previous export before the replacement succeeds.
        try {
            Files.move(part.toPath(),destination.toPath(),StandardCopyOption.ATOMIC_MOVE,StandardCopyOption.REPLACE_EXISTING);
        } catch (java.nio.file.AtomicMoveNotSupportedException unsupported) {
            Files.move(part.toPath(),destination.toPath(),StandardCopyOption.REPLACE_EXISTING);
        }
    }

    private static String safeName(String s) {
        String n = s.replaceAll("[\\\\/:*?\"<>|\\x00-\\x1f]", " ").trim();
        if (n.length() > 80) n = n.substring(0, 80).trim();
        return n.isEmpty() ? "My unit" : n;
    }

    private static File downloadsDir() {
        try {
            Class<?> env = Class.forName("android.os.Environment");
            String type = (String) env.getField("DIRECTORY_DOWNLOADS").get(null);
            return (File) env.getMethod("getExternalStoragePublicDirectory", String.class).invoke(null, type);
        } catch (Throwable t) {
            return null;
        }
    }

    private static void deleteTree(File f) {
        if (f == null) return;
        File[] kids = f.listFiles();
        if (kids != null) for (File k : kids) deleteTree(k);
        f.delete();
    }
}
