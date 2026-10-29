package com.personal.offlinedokkan;

/** Native host API backed by the actual player SQLite core. Never expose paths/handles to WebView code.
 * Same Java source works on Android and the Linux integration harness. Calls are serialized.
 * Stable command IDs belong to user intents and must be retained across retries. */
public final class OfflineCore implements AutoCloseable {
    static { System.loadLibrary("odbridge"); }
    private long handle;

    public OfflineCore(String hostSavePath, String hostMasterPath, String verifiedContentId) {
        handle = nativeOpen(hostSavePath, hostMasterPath, verifiedContentId);
        if (handle == 0) throw new IllegalStateException("OPEN_FAILED");
    }
    public synchronized String execute(String operation, String profile, String commandId, String argsJson) {
        requireOpen();
        return nativeExecute(handle, operation, profile, commandId, argsJson, false);
    }
    /** Trusted native policy/evaluator only. Never select this method from a WebView payload flag. */
    public synchronized String executePolicy(String operation, String profile, String commandId, String fixedHostArgsJson) {
        requireOpen();
        return nativeExecute(handle, operation, profile, commandId, fixedHostArgsJson, true);
    }
    public synchronized void exportSave(String approvedHostDestination) {
        requireOpen(); nativeSave(handle, approvedHostDestination, false);
    }
    public synchronized void importSave(String approvedHostSource) {
        requireOpen(); nativeSave(handle, approvedHostSource, true);
    }
    private void requireOpen() {
        if (handle == 0) throw new IllegalStateException("CLOSED");
    }
    @Override public synchronized void close() {
        long old = handle; handle = 0;
        if (old != 0) nativeClose(old);
    }
    private static native long nativeOpen(String save, String master, String content);
    private static native String nativeExecute(long handle, String operation, String profile, String command, String args, boolean policy);
    private static native void nativeSave(long handle, String path, boolean importing);
    private static native void nativeClose(long handle);
}
