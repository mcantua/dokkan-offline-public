package com.personal.aihub;

import android.app.Activity;
import android.content.Intent;

import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Method;

/**
 * "Import a .sql file": opens Android's file picker and hands the chosen file's text to the app's own SQL reader
 * (v2/ui/sql-import.js). Bridge calls run on the activity's worker thread, so this waits there for the picker's
 * answer, which arrives through the onActivityResult hook (ForgeFixes.activityResult). Methods not in the build
 * stubs are reached by reflection.
 */
final class SqlPicker {
    static final int REQUEST = 0x5f1;
    private static final long MAX = 64L * 1024 * 1024;
    private static final Object LOCK = new Object();
    private static boolean done;
    private static Object picked;   // android.net.Uri

    private SqlPicker() {}

    static JSONObject pick() throws Exception {
        final Activity activity = ForgeFixes.activity();
        if (activity == null) throw new IOException("The app is still starting.");
        synchronized (LOCK) { done = false; picked = null; }
        final Intent intent = new Intent("android.intent.action.OPEN_DOCUMENT").addCategory("android.intent.category.OPENABLE");
        Intent.class.getMethod("setType", String.class).invoke(intent, "*/*");
        activity.runOnUiThread(new Runnable() {
            public void run() {
                try {
                    Activity.class.getMethod("startActivityForResult", Intent.class, int.class).invoke(activity, intent, REQUEST);
                } catch (Throwable t) {
                    synchronized (LOCK) { done = true; LOCK.notifyAll(); }
                }
            }
        });
        long until = System.currentTimeMillis() + 15 * 60 * 1000;
        synchronized (LOCK) { while (!done && System.currentTimeMillis() < until) LOCK.wait(1000); }
        Object uri;
        synchronized (LOCK) { uri = picked; }
        if (uri == null) return new JSONObject();   // canceled
        Object resolver = activity.getClass().getMethod("getContentResolver").invoke(activity);
        Method open = resolver.getClass().getMethod("openInputStream", Class.forName("android.net.Uri"));
        InputStream in = (InputStream) open.invoke(resolver, uri);
        if (in == null) throw new IOException("That file can't be opened.");
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            byte[] buf = new byte[1 << 16];
            int n; long total = 0;
            while ((n = in.read(buf)) > 0) {
                total += n;
                if (total > MAX) throw new IOException("This .sql file is too large (over 64 MB).");
                out.write(buf, 0, n);
            }
        } finally { in.close(); }
        String name = "unit.sql";
        try {
            Object seg = uri.getClass().getMethod("getLastPathSegment").invoke(uri);
            if (seg != null) { String s = java.net.URLDecoder.decode(String.valueOf(seg), "UTF-8"); name = s.substring(s.lastIndexOf('/') + 1); }
        } catch (Throwable ignored) {}
        return new JSONObject().put("name", name).put("text", new String(out.toByteArray(), "UTF-8"));
    }

    /** From ForgeFixes.activityResult; true when the answer was ours. */
    static boolean activityResult(int request, int result, Intent data) {
        if (request != REQUEST) return false;
        Object uri = null;
        if (result == -1 && data != null) {
            try { uri = Intent.class.getMethod("getData").invoke(data); } catch (Throwable ignored) {}
        }
        synchronized (LOCK) { picked = uri; done = true; LOCK.notifyAll(); }
        return true;
    }
}
