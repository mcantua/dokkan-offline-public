package com.personal.aihub;

import android.content.Context;
import android.content.Intent;
import java.lang.reflect.Method;

/**
 * Keeps "Offline downloads" running when the screen turns off or you switch to another app.
 * Android freezes apps in the background; a foreground service (with its "Downloading game files…"
 * notification and progress bar) is Android's supported way to keep a long download going.
 * It also holds the CPU and Wi-Fi awake for the download only, and ends itself when the download is
 * done, paused for good, or cancelled. Type "specialUse" has no time limit (the "dataSync" type stops
 * after 6 hours a day on Android 15+, too short for "Everything").
 */
public class DownloadService extends android.app.Service {
    private static final int ID = 1201;
    private static final String CHANNEL = "downloads";
    private volatile boolean stopping;
    private Object wake, wifi;
    private Thread updater;

    public android.os.IBinder onBind(Intent intent) { return null; }

    public int onStartCommand(Intent intent, int flags, int startId) {
        try { startForegroundNow(notification("Getting ready…", 0, 0)); } catch (Throwable t) { stopSelf(); return 2; }
        acquire();
        if (updater == null || !updater.isAlive()) {
            updater = new Thread(new Runnable() { public void run() { loop(); } }, "forge-download-notice");
            updater.setDaemon(true);
            updater.start();
        }
        return 2; // START_NOT_STICKY: the app resumes an interrupted download itself when it opens
    }

    public void onDestroy() {
        stopping = true;
        release();
    }

    /** Android 15+: called if the system ever ends the service; stop cleanly (the download resumes next time). */
    public void onTimeout(int startId, int type) {
        stopping = true;
        try { stopSelf(); } catch (Throwable ignored) {}
    }

    private void loop() {
        while (!stopping) {
            try { Thread.sleep(3000); } catch (InterruptedException e) { return; }
            OfflineLibrary.Job j = OfflineLibrary.currentJob();
            if (j == null || j.finished) {
                stopping = true;
                try { stopForeground(1); } catch (Throwable ignored) {}
                try { stopSelf(); } catch (Throwable ignored) {}
                return;
            }
            long total = Math.max(1, j.total.get()), done = Math.min(j.done.get(), total);
            String text = j.paused ? "Paused" : !j.waiting.isEmpty() ? j.waiting : j.phase + " · " + done + " of " + total;
            try { notify(notification(text, (int) Math.min(1000, done * 1000 / total), 1000)); } catch (Throwable ignored) {}
        }
    }

    // ------------------------------------------------------------------ notification (by reflection: no SDK classes needed)

    private Object notification(String text, int progress, int max) throws Exception {
        Object nm = getSystemService("notification");
        Class<?> channelClass = Class.forName("android.app.NotificationChannel");
        Object channel = channelClass.getConstructor(String.class, CharSequence.class, int.class).newInstance(CHANNEL, "Downloads", 2);
        nm.getClass().getMethod("createNotificationChannel", channelClass).invoke(nm, channel);
        Class<?> builderClass = Class.forName("android.app.Notification$Builder");
        Object b = builderClass.getConstructor(Context.class, String.class).newInstance(this, CHANNEL);
        builderClass.getMethod("setSmallIcon", int.class).invoke(b, 0x01080081); // android.R.drawable.stat_sys_download
        builderClass.getMethod("setContentTitle", CharSequence.class).invoke(b, "Downloading game files");
        builderClass.getMethod("setContentText", CharSequence.class).invoke(b, text);
        builderClass.getMethod("setOngoing", boolean.class).invoke(b, true);
        builderClass.getMethod("setOnlyAlertOnce", boolean.class).invoke(b, true);
        builderClass.getMethod("setProgress", int.class, int.class, boolean.class).invoke(b, max, progress, max == 0);
        try {
            Object pmgr = getPackageManager();
            Intent open = (Intent) pmgr.getClass().getMethod("getLaunchIntentForPackage", String.class).invoke(pmgr, getPackageName());
            Object pi = Class.forName("android.app.PendingIntent").getMethod("getActivity", Context.class, int.class, Intent.class, int.class)
                    .invoke(null, this, 0, open, 0x04000000 | 0x08000000); // IMMUTABLE | UPDATE_CURRENT
            builderClass.getMethod("setContentIntent", Class.forName("android.app.PendingIntent")).invoke(b, pi);
        } catch (Throwable ignored) {}
        return builderClass.getMethod("build").invoke(b);
    }

    private void startForegroundNow(Object n) throws Exception {
        Class<?> nc = Class.forName("android.app.Notification");
        try {
            android.app.Service.class.getMethod("startForeground", int.class, nc, int.class).invoke(this, ID, n, 0x40000000); // SPECIAL_USE
        } catch (NoSuchMethodException e) {
            android.app.Service.class.getMethod("startForeground", int.class, nc).invoke(this, ID, n);
        }
    }

    private void notify(Object n) throws Exception {
        Object nm = getSystemService("notification");
        nm.getClass().getMethod("notify", int.class, Class.forName("android.app.Notification")).invoke(nm, ID, n);
    }

    // ------------------------------------------------------------------ keep the CPU and Wi-Fi awake while downloading

    private void acquire() {
        try {
            if (wake == null) {
                Object pm = getSystemService("power");
                wake = pm.getClass().getMethod("newWakeLock", int.class, String.class).invoke(pm, 1, "dokkan:downloads");
                wake.getClass().getMethod("setReferenceCounted", boolean.class).invoke(wake, false);
                wake.getClass().getMethod("acquire").invoke(wake);
            }
        } catch (Throwable ignored) {}
        try {
            if (wifi == null) {
                Object wm = getApplicationContext().getSystemService("wifi");
                wifi = wm.getClass().getMethod("createWifiLock", int.class, String.class).invoke(wm, 3, "dokkan:downloads"); // FULL_HIGH_PERF
                wifi.getClass().getMethod("setReferenceCounted", boolean.class).invoke(wifi, false);
                wifi.getClass().getMethod("acquire").invoke(wifi);
            }
        } catch (Throwable ignored) {}
    }

    private void release() {
        for (Object lock : new Object[]{wake, wifi}) {
            try { if (lock != null) lock.getClass().getMethod("release").invoke(lock); } catch (Throwable ignored) {}
        }
        wake = null;
        wifi = null;
    }

    // ------------------------------------------------------------------ start from the app

    static void start(android.app.Activity activity) {
        if (activity == null) return;
        try {
            if (sdk() >= 33) {
                Method check = Context.class.getMethod("checkSelfPermission", String.class);
                Object granted = check.invoke(activity, "android.permission.POST_NOTIFICATIONS");
                if (!Integer.valueOf(0).equals(granted))
                    android.app.Activity.class.getMethod("requestPermissions", String[].class, int.class)
                            .invoke(activity, new String[]{"android.permission.POST_NOTIFICATIONS"}, 7712);
            }
        } catch (Throwable ignored) {}
        try {
            Intent intent = new Intent(activity, DownloadService.class);
            Context.class.getMethod("startForegroundService", Intent.class).invoke(activity, intent);
        } catch (Throwable ignored) {}
    }

    private static int sdk() {
        try { return Class.forName("android.os.Build$VERSION").getField("SDK_INT").getInt(null); } catch (Throwable t) { return 0; }
    }
}
