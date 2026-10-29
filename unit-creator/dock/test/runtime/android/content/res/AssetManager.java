package android.content.res;
public final class AssetManager {
  public static String UI = "/home/claude/work/v2/ui", OTHER = "/tmp/claude-0/rt/assets";
  public static String SCRIPT_INDEX = null;
  public java.io.InputStream open(String n) throws java.io.IOException {
    if (n.equals("ui/data/preview-script-index.json") && SCRIPT_INDEX != null) return new java.io.FileInputStream(SCRIPT_INDEX);
    if (n.startsWith("ui/")) return new java.io.FileInputStream(UI + "/" + n.substring(3));
    return new java.io.FileInputStream(OTHER + "/" + n);
  }
}
