package com.personal.aihub;

import android.app.Activity;
import android.app.Application;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.webkit.CookieManager;
import android.webkit.RenderProcessGoneDetail;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.UUID;
import org.json.JSONArray;
import org.json.JSONObject;

/**
 * In-app animation player. Previews used to open a separate full-screen activity
 * (PreviewActivity) that had to start a new WebView, load the player and wait for a
 * "Load and play" tap. The dock shows the same isolated local player in a panel at the
 * top of the main screen instead: the editor stays visible and usable underneath, every
 * new preview replaces the one that is playing in place, and the animation starts by itself.
 * The panel can be dragged taller or shorter, expanded to the whole screen, or closed.
 *
 * Security is unchanged: the panel uses the same per-preview PreviewServer (random port,
 * HttpOnly cookie, local-only requests), the same bootstrap transfer and the same checks
 * as PreviewActivity. If anything here fails the caller falls back to PreviewActivity.
 */
final class PreviewDock {
    private static final String PREFS = "forge-preview-dock";
    private static final int BG = 0xFF0B141A, BAR = 0xFF152329, TEXT = 0xFFF2F5F7, ACCENT = 0xFFFFB15D;
    private static PreviewDock current;
    /** "Play this part" for movie scenes: the part to loop, handed to the next preview. */
    private static volatile JSONObject pendingTrim;

    static void noteTrim(JSONObject args) {
        JSONObject trim = args == null ? null : args.optJSONObject("trim");
        JSONObject clean = null;
        if (trim != null) {
            double from = trim.optDouble("from", Double.NaN), to = trim.optDouble("to", Double.NaN);
            if (!Double.isNaN(from) && !Double.isNaN(to) && from >= 0 && to > from && to <= 3600) {
                try { clean = new JSONObject().put("from", from).put("to", to); } catch (Exception ignored) {}
            }
        }
        pendingTrim = clean;
        // The animation editor asks for a small window (its tools stay visible below) or full screen.
        String size = args == null ? "" : args.optString("dockSize", "");
        pendingSize = "small".equals(size) || "full".equals(size) ? size : null;
        // The editor reopens a refreshed preview at its playhead, paused or playing.
        JSONObject start = null;
        if (args != null && (args.has("startAt") || args.has("startPaused"))) {
            try { start = new JSONObject().put("startAt", Math.max(0, Math.min(10000000, args.optInt("startAt", 0)))).put("startPaused", args.optBoolean("startPaused", false)); } catch (Exception ignored) {}
        }
        pendingStart = start;
    }

    private static volatile JSONObject pendingStart;

    private static volatile String pendingSize;

    private final Activity activity;
    private final FrameLayout host;
    private final WebView mainWeb;
    private LinearLayout panel;
    private TextView title, note, sizeButton;
    private FrameLayout stageFrame;
    private View handle;
    private WebView web;
    private WebViewStartup startup;
    private volatile PreviewServer server;
    private PreviewCache cache;
    private PreviewBootstrap bootstrap;
    private long bootstrapEpoch = -1;
    private StageExport recordingExport;
    private JSONObject request;
    private String raw;
    private boolean full, disposed, exportFull, dragging;
    private View topBar;
    private int lastAvailable;
    private Application.ActivityLifecycleCallbacks lifecycle;

    private PreviewDock(Activity activity, FrameLayout host, WebView mainWeb) {
        this.activity = activity;
        this.host = host;
        this.mainWeb = mainWeb;
    }

    // ------------------------------------------------------------------ entry points

    /** Runs on the UI thread (CreatorActivity posts the preview launch there). */
    static boolean open(Activity activity, String token) throws Exception {
        if (activity == null || token == null || !token.matches("[a-f0-9-]{36}")) return false;
        if (prefs(activity).getBoolean("separateWindow", false)) return false;
        // Old WebViews get PreviewActivity, which explains how to update them.
        try {
            PackageInfo info = WebView.getCurrentWebViewPackage();
            int major = info == null ? 0 : Integer.parseInt(info.versionName.split("\\.")[0]);
            if (major > 0 && major < 120) return false;
        } catch (Throwable ignored) {}
        File directory = new File(new File(activity.getCacheDir(), "animation-preview"), token);
        File file = new File(directory, "request.json");
        if (!file.isFile()) return false;
        String raw = PreviewActivity.read(new FileInputStream(file), PreviewBootstrap.MAX_REQUEST_BYTES);
        new JSONObject(raw);
        PreviewDock dock = current;
        if (dock == null || dock.disposed || dock.activity != activity) {
            if (dock != null) dock.dispose();
            WebView main = ForgeFixes.mainWeb();
            if (main == null || !(main.getParent() instanceof FrameLayout)) return false;
            dock = new PreviewDock(activity, (FrameLayout) main.getParent(), main);
            // The editor's own choice first, then Settings > Animations (full screen by default).
            String size = pendingSize;
            dock.full = size != null ? "full".equals(size) : prefs(activity).getBoolean("startFull", true);
            dock.attach();
            current = dock;
        }
        try {
            dock.play(raw);
        } catch (Exception e) {
            dock.dispose(); // PreviewActivity takes over with the untouched request file
            throw e;
        }
        file.delete();
        directory.delete();
        return true;
    }

    static void activityResult(int request, int result, Intent data) {
        PreviewDock dock = current;
        if (dock != null && dock.recordingExport != null) dock.recordingExport.result(request, result, data);
    }

    /** Bridge action "previewDock": status, close, back, full, dock, set {separateWindow}. */
    static JSONObject dispatch(final Activity activity, JSONObject args) throws Exception {
        if (activity == null) throw new java.io.IOException("The preview player is not ready yet.");
        final String action = args.optString("action", "status");
        if ("set".equals(action) && args.has("separateWindow")) {
            prefs(activity).edit().putBoolean("separateWindow", args.getBoolean("separateWindow")).commit();
        }
        if ("set".equals(action) && args.has("smooth")) {
            prefs(activity).edit().putBoolean("smooth", args.getBoolean("smooth")).commit();
        }
        if ("set".equals(action) && args.has("quality")) {
            String q = args.optString("quality", "auto");
            if (!"smooth".equals(q) && !"best".equals(q)) q = "auto";
            SharedPreferences p = prefs(activity);
            // A new epoch makes every preview forget "this phone needed fast colors".
            p.edit().putString("quality", q).putInt("qualityEpoch", p.getInt("qualityEpoch", 0) + 1).commit();
        }
        if ("set".equals(action) && args.has("startFull")) {
            prefs(activity).edit().putBoolean("startFull", args.getBoolean("startFull")).commit();
        }
        final boolean[] handled = {false};
        final java.util.concurrent.atomic.AtomicBoolean expired = new java.util.concurrent.atomic.AtomicBoolean(false);
        // The editor's timeline drives the player: seek {frame, play}, play, pause.
        if ("seek".equals(action) || "play".equals(action) || "pause".equals(action)) {
            final JSONObject command = new JSONObject().put("type", action);
            if ("seek".equals(action)) command.put("frame", Math.max(0, Math.min(10000000, args.optInt("frame", 0)))).put("play", args.optBoolean("play", false));
            activity.runOnUiThread(new Runnable() {
                public void run() {
                    PreviewDock dock = current;
                    if (dock == null || dock.disposed || dock.web == null) return;
                    try { dock.web.evaluateJavascript("window.ForgeDockPage&&ForgeDockPage.command&&ForgeDockPage.command(" + command.toString() + ")", null); } catch (Throwable ignored) {}
                }
            });
        }
        if ("close".equals(action) || "back".equals(action) || "full".equals(action) || "dock".equals(action) || "toggle".equals(action)) {
            final Object lock = new Object();
            final boolean[] done = {false};
            activity.runOnUiThread(new Runnable() {
                public void run() {
                    try {
                        PreviewDock dock = current;
                        if (expired.get()) return;
                        if (dock != null && !dock.disposed) {
                            handled[0] = true;
                            if ("close".equals(action)) dock.dispose();
                            else if ("back".equals(action)) dock.dispose(); // Back always closes the player
                            else if ("full".equals(action)) dock.setFull(true);
                            else if ("dock".equals(action)) dock.setFull(false);
                            else dock.setFull(!dock.full);
                        }
                    } catch (Throwable ignored) {
                    } finally {
                        synchronized (lock) { done[0] = true; lock.notifyAll(); }
                    }
                }
            });
            synchronized (lock) {
                long end = System.currentTimeMillis() + 3000;
                while (!done[0] && System.currentTimeMillis() < end) lock.wait(250);
                if (!done[0]) expired.set(true);
            }
        }
        PreviewDock dock = current;
        boolean open = dock != null && !dock.disposed;
        return new JSONObject().put("open", open).put("full", open && dock.full).put("handled", handled[0])
                .put("separateWindow", prefs(activity).getBoolean("separateWindow", false))
                .put("smooth", prefs(activity).getBoolean("smooth", true))
                .put("quality", prefs(activity).getString("quality", "auto"))
                .put("startFull", prefs(activity).getBoolean("startFull", true))
                .put("dockable", dockable(activity));
    }

    /** True when previews open in the in-app panel (not the separate full-screen window). */
    static boolean dockable(Activity activity) {
        if (prefs(activity).getBoolean("separateWindow", false)) return false;
        try {
            PackageInfo info = WebView.getCurrentWebViewPackage();
            int major = info == null ? 0 : Integer.parseInt(info.versionName.split("\\.")[0]);
            if (major > 0 && major < 120) return false;
        } catch (Throwable ignored) {}
        return true;
    }

    private static SharedPreferences prefs(Activity activity) {
        return activity.getSharedPreferences(PREFS, 0);
    }

    // ------------------------------------------------------------------ views

    private int dp(float value) {
        return Math.round(value * activity.getResources().getDisplayMetrics().density);
    }

    private TextView button(String text, String label, View.OnClickListener listener) {
        TextView b = new TextView(activity);
        b.setText(text);
        b.setTextColor(TEXT);
        b.setTextSize(16f);
        b.setGravity(Gravity.CENTER);
        b.setMinWidth(dp(44));
        b.setPadding(dp(10), 0, dp(10), 0);
        b.setContentDescription(label);
        b.setClickable(true);
        b.setFocusable(true);
        b.setOnClickListener(listener);
        return b;
    }

    private void attach() {
        panel = new LinearLayout(activity);
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.setBackgroundColor(BG);
        panel.setClickable(true); // touches on the panel never reach the editor underneath

        LinearLayout bar = new LinearLayout(activity);
        bar.setOrientation(LinearLayout.HORIZONTAL);
        bar.setGravity(Gravity.CENTER_VERTICAL);
        bar.setBackgroundColor(BAR);
        bar.setPadding(dp(12), 0, dp(2), 0);
        TextView mark = new TextView(activity);
        mark.setText("▶ ");
        mark.setTextColor(ACCENT);
        mark.setTextSize(14f);
        bar.addView(mark);
        title = new TextView(activity);
        title.setTextColor(TEXT);
        title.setTextSize(16f);
        title.setSingleLine(true);
        title.setEllipsize(TextUtils.TruncateAt.END);
        bar.addView(title, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        sizeButton = button("Smaller", "Make the player smaller so the editor is visible", new View.OnClickListener() {
            public void onClick(View v) { setFull(!full); }
        });
        sizeButton.setBackgroundColor(0xFF22323F);
        sizeButton.setPadding(dp(14), 0, dp(14), 0);
        LinearLayout.LayoutParams sizeLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(40));
        sizeLp.rightMargin = dp(6);
        bar.addView(sizeButton, sizeLp);
        TextView close = button("✕  Close", "Close the animation player", new View.OnClickListener() {
            public void onClick(View v) { dispose(); }
        });
        close.setTextColor(0xFF20150C);
        close.setBackgroundColor(ACCENT);
        close.setPadding(dp(16), 0, dp(16), 0);
        LinearLayout.LayoutParams closeLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(40));
        closeLp.rightMargin = dp(8);
        bar.addView(close, closeLp);
        panel.addView(bar, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(56)));
        // The player page draws its own close/size controls over the animation (video-player
        // style); this bar only appears with the classic player tools and when saving a video.
        topBar = bar;
        bar.setVisibility(View.GONE);

        note = new TextView(activity);
        note.setTextColor(0xFF20150C);
        note.setBackgroundColor(ACCENT);
        note.setTextSize(13f);
        note.setPadding(dp(12), dp(6), dp(12), dp(6));
        note.setVisibility(View.GONE);
        note.setClickable(true);
        note.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) { note.setVisibility(View.GONE); }
        });
        panel.addView(note, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        stageFrame = new FrameLayout(activity);
        stageFrame.setBackgroundColor(0xFF000000);
        panel.addView(stageFrame, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        TextView grip = new TextView(activity);
        grip.setText("━━━");
        grip.setTextColor(0xFF6F8794);
        grip.setTextSize(12f);
        grip.setGravity(Gravity.CENTER);
        grip.setBackgroundColor(BAR);
        grip.setContentDescription("Drag to resize the animation player");
        grip.setOnTouchListener(new View.OnTouchListener() {
            float startY;
            int startH;
            public boolean onTouch(View v, MotionEvent e) {
                int action = e.getActionMasked();
                if (action == MotionEvent.ACTION_DOWN) {
                    dragging = true;
                    startY = e.getRawY();
                    startH = panel.getHeight();
                    return true;
                }
                if (action == MotionEvent.ACTION_MOVE) {
                    applyHeight(clampHeight(Math.round(startH + e.getRawY() - startY)), false);
                    return true;
                }
                if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_CANCEL) {
                    dragging = false;
                    int h = clampHeight(Math.round(startH + e.getRawY() - startY));
                    int avail = available();
                    if (avail > 0) prefs(activity).edit().putFloat("fraction", h / (float) avail).apply();
                    applyHeight(h, true);
                    return true;
                }
                return false;
            }
        });
        handle = grip;
        panel.addView(handle, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(22)));

        host.addView(panel, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(320), Gravity.TOP));
        lifecycle = new Application.ActivityLifecycleCallbacks() {
            public void onActivityCreated(Activity a, Bundle b) {}
            public void onActivityStarted(Activity a) {}
            public void onActivityResumed(Activity a) { if (a == activity && web != null) web.onResume(); }
            public void onActivityPaused(Activity a) { if (a == activity && web != null) web.onPause(); }
            public void onActivityStopped(Activity a) {}
            public void onActivitySaveInstanceState(Activity a, Bundle b) {}
            public void onActivityDestroyed(Activity a) { if (a == activity) dispose(); }
        };
        try { activity.getApplication().registerActivityLifecycleCallbacks(lifecycle); } catch (Throwable ignored) { lifecycle = null; }
        host.addOnLayoutChangeListener(relayout);
        host.post(new Runnable() { public void run() { layout(); } });
    }

    // Rotation and the keyboard change the space (the activity handles these without restarting).
    private final View.OnLayoutChangeListener relayout = new View.OnLayoutChangeListener() {
        public void onLayoutChange(View v, int l, int t, int r, int b, int ol, int ot, int or, int ob) {
            int avail = available();
            if (disposed || dragging || avail == lastAvailable) return;
            lastAvailable = avail;
            host.post(new Runnable() { public void run() { if (!disposed && !dragging) layout(); } });
        }
    };

    private int available() {
        int h = host.getHeight() - host.getPaddingTop() - host.getPaddingBottom();
        return h > 0 ? h : activity.getResources().getDisplayMetrics().heightPixels;
    }

    private int clampHeight(int h) {
        int avail = available();
        int min = Math.min(dp(200), avail / 2), max = Math.max(min, avail - dp(140));
        return Math.max(min, Math.min(max, h));
    }

    private void layout() {
        if (disposed) return;
        if (full) {
            panel.setLayoutParams(new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT, Gravity.TOP));
            handle.setVisibility(View.GONE);
        } else {
            handle.setVisibility(View.VISIBLE);
            float fraction = prefs(activity).getFloat("fraction", 0.46f);
            applyHeight(clampHeight(Math.round(available() * fraction)), true);
        }
        // Full screen covers the editor, so it stops drawing; the player gets the phone's attention.
        try { mainWeb.setVisibility(full ? View.INVISIBLE : View.VISIBLE); } catch (Throwable ignored) {}
        sizeButton.setText(full ? "Smaller" : "Full screen");
        sizeButton.setContentDescription(full ? "Make the player smaller so the editor is visible" : "Show the player on the whole screen");
        tellPage();
        tellMain(full ? "full" : "docked");
    }

    private void applyHeight(int h, boolean moveEditor) {
        panel.setLayoutParams(new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, h, Gravity.TOP));
        if (moveEditor) {
            FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
            lp.topMargin = h;
            mainWeb.setLayoutParams(lp);
        }
    }

    private void setFull(boolean value) {
        full = value;
        exportFull = false;
        layout();
    }

    private void tellMain(String state) {
        try { mainWeb.evaluateJavascript("window.ForgeDock&&ForgeDock.native(" + JSONObject.quote(state) + ")", null); } catch (Throwable ignored) {}
    }

    private void tellPage() {
        if (web == null) return;
        try { web.evaluateJavascript("window.ForgeDockPage&&ForgeDockPage.layout(" + (full ? "true" : "false") + ")", null); } catch (Throwable ignored) {}
    }

    private void showNote(String text) {
        if (note == null) return;
        note.setText(text);
        note.setVisibility(text == null || text.isEmpty() ? View.GONE : View.VISIBLE);
    }

    // ------------------------------------------------------------------ playback

    private void play(String raw) throws Exception {
        JSONObject request = new JSONObject(raw);
        stopServer();
        bootstrap = null;
        bootstrapEpoch = -1;
        showNote("");
        title.setText(request.optString("name", "Animation preview"));
        cache = new PreviewCache(new File(activity.getFilesDir(), "forge"));
        server = new PreviewServer(activity, cache, request.optString("assetKey"), request.optJSONArray("assets"),
                request.optJSONArray("effectPacks"), request.optString("forgeVerifiedMusicPath"), request.optString("sourceDatabase"),
                PreviewMetadata.sparkingEffects(request.has("sparkingEffectIds") ? request.get("sparkingEffectIds") : null),
                PreviewMetadata.normalizeVersion(request.has("sparkingVersion") ? request.get("sparkingVersion") : null));
        String[] privateKeys = {"assetKey", "assets", "effectPacks", "sparkingEffectIds", "sparkingVersion", "forgeVerifiedMusicPath"};
        for (String key : privateKeys) request.remove(key);
        request.put("bgmContext", server.bgmContext());
        request.put("dock", true);
        request.put("full", full); // the page draws a small panel at a lighter resolution
        JSONObject trim = pendingTrim;
        pendingTrim = null;
        String size = pendingSize;
        pendingSize = null;
        JSONObject start = pendingStart;
        pendingStart = null;
        // kept so "retry" reopens at the same spot with the same trim
        lastStart = start;
        lastTrim = trim;
        if (start != null) { request.put("startAt", start.optInt("startAt", 0)); request.put("startPaused", start.optBoolean("startPaused", false)); }
        if (trim != null && "movie".equals(request.optString("mode"))) request.put("trim", trim);
        request.put("autoplay", true);
        // Preview quality (Settings > Animations). Every mode except "best" draws at a steady 30 fps.
        String quality = prefs(activity).getString("quality", "auto");
        request.put("quality", quality);
        request.put("qualityEpoch", prefs(activity).getInt("qualityEpoch", 0));
        request.put("smooth30", !"best".equals(quality));
        this.request = request;
        this.raw = raw;
        ensureWeb();
        server.stageCapture(new StageCapture(activity, web, server.origin));
        recordingExport = new StageExport(activity);
        server.stageExport(recordingExport);
        web.loadUrl(server.entryURL(request.optString("mode", "lua")));
        // "Save video" records what is on screen, so it uses the whole screen for a sharp video.
        boolean export = java.util.regex.Pattern.compile("(?m)^-- FORGE_SEQUENCE_EXPORT [0-9]{1,5}$").matcher(request.optString("text")).find();
        if (export) { if (!full) exportFull = true; full = true; }
        else if (size != null) { exportFull = false; full = "full".equals(size); }
        else if (exportFull) { exportFull = false; full = false; }
        layout();
    }

    private void ensureWeb() {
        if (web != null) return;
        stageFrame.removeAllViews();
        web = new WebView(activity);
        web.setBackgroundColor(0xFF000000);
        stageFrame.addView(web, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        startup = new WebViewStartup(activity, stageFrame, "animation preview", new Runnable() {
            public void run() { retry(); }
        });
        startup.begin(web);
        WebSettings settings = web.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(false);
        settings.setAllowContentAccess(false);
        settings.setMediaPlaybackRequiresUserGesture(false);
        settings.setMixedContentMode(1);
        web.setWebChromeClient(new WebChromeClient() {
            // The page asks for "close", "size" and the top bar through its title (no JavaScript bridge).
            @Override public void onReceivedTitle(WebView view, String text) {
                if (view != web || disposed || text == null || !text.startsWith("forge-dock:")) return;
                String[] parts = text.substring("forge-dock:".length()).split(":");
                String command = parts.length > 0 ? parts[0] : "";
                // The editor's timeline follows the player: "pos:<frame>:<last frame>:<p|s|d>".
                if ("pos".equals(command) && parts.length >= 4 && parts[1].matches("[0-9]{1,7}") && parts[2].matches("[0-9]{1,7}") && parts[3].matches("[psd]")) {
                    try { mainWeb.evaluateJavascript("window.ForgeDock&&ForgeDock.position&&ForgeDock.position(" + parts[1] + "," + parts[2] + ",'" + parts[3] + "')", null); } catch (Throwable ignored) {}
                    return;
                }
                if ("close".equals(command)) host.post(new Runnable() { public void run() { if (!disposed) dispose(); } });
                else if ("size".equals(command)) host.post(new Runnable() { public void run() { if (!disposed) setFull(!full); } });
                else if ("bar-on".equals(command) && topBar != null) topBar.setVisibility(View.VISIBLE);
                else if ("bar-off".equals(command) && topBar != null) topBar.setVisibility(View.GONE);
            }
        });
        web.setWebViewClient(new Client());
    }

    private JSONObject lastStart, lastTrim;

    private void retry() {
        String again = raw;
        destroyWeb();
        if (again == null || disposed) return;
        pendingStart = lastStart;
        pendingTrim = lastTrim;
        try { play(again); } catch (Throwable t) { showNote("Could not reopen this preview: " + t.getMessage()); }
    }

    private void destroyWeb() {
        if (startup != null) startup.close();
        startup = null;
        bootstrap = null;
        WebView old = web;
        web = null;
        if (old != null) {
            try { old.stopLoading(); } catch (Throwable ignored) {}
            ViewParent parent = old.getParent();
            if (parent instanceof ViewGroup) ((ViewGroup) parent).removeView(old);
            try { old.destroy(); } catch (Throwable ignored) {}
        }
        if (stageFrame != null) stageFrame.removeAllViews();
        stopServer();
    }

    private void stopServer() {
        PreviewServer s = server;
        server = null;
        recordingExport = null;
        if (s != null) {
            String origin = s.origin, cookie = s.cookie;
            s.close();
            try { CookieManager.getInstance().setCookie(origin, cookie + "; Path=/; Max-Age=0; HttpOnly; SameSite=Strict", null); } catch (Throwable ignored) {}
        }
    }

    void dispose() {
        if (disposed) return;
        disposed = true;
        if (current == this) current = null;
        destroyWeb();
        raw = null;
        request = null;
        if (lifecycle != null) {
            try { activity.getApplication().unregisterActivityLifecycleCallbacks(lifecycle); } catch (Throwable ignored) {}
            lifecycle = null;
        }
        try { host.removeOnLayoutChangeListener(relayout); } catch (Throwable ignored) {}
        try { host.removeView(panel); } catch (Throwable ignored) {}
        try { mainWeb.setLayoutParams(new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)); } catch (Throwable ignored) {}
        try { mainWeb.setVisibility(View.VISIBLE); } catch (Throwable ignored) {}
        tellMain("closed");
    }

    private void unreliableRuntime() {
        destroyWeb();
        tellMain("failed");
        showNote("This device could not run the animation player reliably. Update Android System WebView or Chrome, then try again. Tap here to hide this message.");
    }

    // Same handshake as PreviewActivity: check the runtime, then send the request in chunks.
    private void sendBootstrap(final WebView view, final PreviewBootstrap boot, final long epoch, final int index, final String page) {
        if (startup == null || !startup.current(view, epoch) || bootstrap != boot) return;
        String script;
        if (index < 0) script = boot.beginScript();
        else if (index >= boot.chunkCount()) script = boot.mountScript(page);
        else script = boot.chunkScript(index);
        view.evaluateJavascript(script, new ValueCallback<String>() {
            public void onReceiveValue(String value) {
                if (startup == null || !startup.current(view, epoch) || bootstrap != boot) return;
                if (!"true".equals(value)) {
                    view.evaluateJavascript(boot.cancelScript(), null);
                    showNote("This preview did not finish opening. Tap Preview again to retry.");
                    startup.failed(view, epoch, "This animation did not finish opening. Try again.");
                    tellMain("failed");
                } else if (index != boot.chunkCount()) {
                    sendBootstrap(view, boot, epoch, index + 1, page);
                } else {
                    startup.stage(view, epoch, "controls-ready");
                    startup.ready(view, epoch);
                    tellPage();
                }
            }
        });
    }

    private final class Client extends WebViewClient {
        @Override
        public void onPageStarted(WebView view, String url, android.graphics.Bitmap favicon) {
            if (startup == null || server == null || !server.local(url)) return;
            bootstrap = null;
            bootstrapEpoch = -1;
            startup.begin(view);
        }

        @Override
        public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest req) {
            PreviewServer s = server;
            if (s == null || !s.local(req.getUrl().toString())) {
                return new WebResourceResponse("text/plain", "UTF-8", 403, "Blocked", Collections.singletonMap("Cache-Control", "no-store"),
                        new ByteArrayInputStream("Preview requests must use the isolated local player.".getBytes(StandardCharsets.UTF_8)));
            }
            // Prepared game movies kept on the phone (see MovieCache).
            String path = req.getUrl().getPath();
            if (path != null && path.startsWith("/_forge/movie-cache/")) return MovieCache.handle(activity, s, req);
            return null;
        }

        @Override
        public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest req) {
            PreviewServer s = server;
            return s == null || !s.local(req.getUrl().toString());
        }

        @Override
        public void onReceivedHttpError(final WebView view, WebResourceRequest req, WebResourceResponse response) {
            if (response.getStatusCode() != 503) return;
            String path = req.getUrl().getPath();
            if (path == null || path.startsWith("/account/")) return;
            final String message;
            if (path.startsWith("/_forge/stage-")) message = "The recording could not be captured or saved. Try again.";
            else if (cache != null && cache.offline()) message = "A file this animation needs is not downloaded yet. Turn off Offline preview or download it in Offline downloads.";
            else message = "A preview file could not be loaded. Check your connection, then tap Preview again.";
            activity.runOnUiThread(new Runnable() { public void run() { if (web == view) showNote(message); } });
        }

        @Override
        public void onReceivedError(WebView view, WebResourceRequest req, WebResourceError error) {
            if (web == view && req.isForMainFrame()) {
                showNote("Could not open the animation player. Tap Preview again.");
                if (startup != null) startup.failed(view, startup.epoch(), "Could not open the animation player. Try again.");
                tellMain("failed");
            }
        }

        @Override
        public boolean onRenderProcessGone(WebView view, RenderProcessGoneDetail detail) {
            if (web == view) {
                destroyWeb();
                showNote("The animation player stopped. Tap Preview to play it again.");
                tellMain("failed");
            } else {
                ViewParent parent = view.getParent();
                if (parent instanceof ViewGroup) ((ViewGroup) parent).removeView(view);
                view.destroy();
            }
            return true;
        }

        @Override
        public void onPageFinished(final WebView view, final String url) {
            if (server == null || startup == null || !server.local(url)) return;
            String path = android.net.Uri.parse(url).getPath();
            if (path == null || !path.matches("/tools/(lua|lwf|usm)-player/.*")) return;
            final long epoch = startup.epoch();
            if (bootstrapEpoch == epoch) return;
            bootstrapEpoch = epoch;
            startup.stage(view, epoch, "player-runtime");
            try {
                String check = PreviewActivity.read(activity.getAssets().open("ui/preview-runtime.js"), 20000)
                        + ";JSON.stringify({healthy:Boolean(window.ForgePreviewRuntime && window.ForgePreviewRuntime.healthy()),documentId:String(window.__forgeNativeDocumentId||'')})";
                view.evaluateJavascript(check, new ValueCallback<String>() {
                    public void onReceiveValue(String value) {
                        if (startup == null || !startup.current(view, epoch)) return;
                        mount(view, url, epoch, value);
                    }
                });
            } catch (Exception e) {
                showNote("Could not check the animation player. Tap Preview again.");
                startup.failed(view, epoch, "Could not check the animation player. Try again.");
                tellMain("failed");
            }
        }

        private void mount(WebView view, String url, long epoch, String value) {
            if (web != view || server == null || disposed || !url.equals(view.getUrl())) return;
            try {
                JSONObject health = new JSONObject(new JSONArray("[" + value + "]").getString(0));
                if (!health.optBoolean("healthy")) {
                    unreliableRuntime();
                    return;
                }
                request.put("offline", cache.offline());
                request.put("localPreview", true);
                PreviewBootstrap boot = new PreviewBootstrap(UUID.randomUUID().toString(), health.getString("documentId"), request.toString());
                String page = PreviewActivity.read(activity.getAssets().open("movie".equals(request.optString("mode")) ? "ui/movie-page.js" : "ui/animation-page.js"), 200000);
                bootstrap = boot;
                startup.stage(view, epoch, "request-transfer");
                sendBootstrap(view, boot, epoch, -1, page);
            } catch (Exception e) {
                showNote("Could not prepare this preview. Try a shorter sequence.");
                startup.failed(view, epoch, "Could not prepare this animation. Try a shorter sequence.");
                tellMain("failed");
            }
        }
    }
}
