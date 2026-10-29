package com.personal.aihub;
import java.io.*;
import java.nio.file.*;
import java.lang.reflect.*;
public class StorageTest {
  static int fails = 0;
  static void ok(String n, boolean c){ System.out.println((c?"PASS ":"FAIL ")+n); if(!c) fails++; }
  static void w(File f, String s) throws IOException { f.getParentFile().mkdirs(); try (FileOutputStream o = new FileOutputStream(f)) { o.write(s.getBytes()); } }
  static String r(File f) throws IOException { return new String(Files.readAllBytes(f.toPath())); }
  static void reset() throws Exception { for (String n : new String[]{"prepared","base","mover"}) { Field f = PublicStorage.class.getDeclaredField(n); f.setAccessible(true); f.set(null, n.equals("prepared") ? false : null); } }
  public static void main(String[] a) throws Exception {
    File t = Files.createTempDirectory("ps").toFile(), root = new File(t, "app/forge"), dl = new File(t, "Download");
    dl.mkdirs();
    // an older version's private files
    w(new File(root, "preview-cache/aaa.body"), "body"); w(new File(root, "preview-cache/aaa.json"), "{}");
    w(new File(root, "preview-cache/settings.json"), "{\"maxBytes\":2147483648}");
    w(new File(root, "movie-cache/" + "k".repeat(3) + ".mp4"), "video");
    w(new File(root, "animation-sources/20260101/ab_script/x/sp1.lua"), "lua");
    w(new File(root, "projects/u.json"), "unit");
    PublicStorage.prepare(root, dl, 34);
    PublicStorage.awaitMove(10000);
    File base = new File(dl, "Dokkan Unit Creator");
    ok("public folder chosen", base.equals(PublicStorage.folder()));
    ok("label", PublicStorage.label().equals("Download › Dokkan Unit Creator"));
    for (String[] l : PublicStorage.LINKS) {
      ok(l[0] + " is a link to " + l[1], Files.isSymbolicLink(new File(root, l[0]).toPath()) && Files.readSymbolicLink(new File(root, l[0]).toPath()).toString().equals(new File(base, l[1]).getPath()));
      ok(l[1] + " has .nomedia", new File(base, l[1] + "/.nomedia").isFile());
      ok(l[0] + " old copy gone", !new File(root, l[0] + ".moving").exists());
    }
    ok("root .nomedia", new File(base, ".nomedia").isFile());
    ok("cache file moved", r(new File(base, "Game files/aaa.body")).equals("body") && r(new File(root, "preview-cache/aaa.body")).equals("body"));
    ok("settings moved", new File(base, "Game files/settings.json").isFile());
    ok("movie renamed .video", new File(base, "Game movies/kkk.video").isFile() && !new File(base, "Game movies/kkk.mp4").exists());
    ok("script moved", r(new File(base, "Animation scripts/20260101/ab_script/x/sp1.lua")).equals("lua"));
    ok("units stay private", new File(root, "projects/u.json").isFile() && !Files.isSymbolicLink(new File(root, "projects").toPath()));
    // nothing in the public folder looks like a picture / video / song
    final boolean[] media = {false};
    Files.walk(base.toPath()).forEach(p -> { if (p.toString().matches("(?i).*\\.(png|jpe?g|webp|gif|bmp|mp4|m4v|mov|webm|mp3|m4a|ogg|wav|aac|usm|awb|acb)$")) media[0] = true; });
    ok("no media-looking file names", !media[0]);
    // writing through the private path lands in the public folder
    w(new File(root, "preview-cache/bbb.body"), "x");
    ok("new files land in public folder", new File(base, "Game files/bbb.body").isFile());
    // second start: nothing changes
    reset(); PublicStorage.prepare(root, dl, 34);
    ok("second start same folder", base.equals(PublicStorage.folder()) && new File(base, "Game files/aaa.body").isFile());
    // folder deleted in the Files app while running → put back
    PublicStorage.removeTree(new File(base, "Game files").toPath());
    PublicStorage.ensure();
    w(new File(root, "preview-cache/ccc.body"), "x");
    ok("deleted folder comes back", new File(base, "Game files/ccc.body").isFile() && new File(base, "Game files/.nomedia").isFile());
    // delete downloads (Settings): empties, keeps the link
    PublicStorage.clear(root, "preview-cache");
    ok("clear empties folder, keeps link", Files.isSymbolicLink(new File(root, "preview-cache").toPath()) && !new File(base, "Game files/ccc.body").exists() && new File(base, "Game files/.nomedia").isFile());
    // a folder left by an earlier install (different id) is never reused
    File root2 = new File(t, "app2/forge");
    reset(); PublicStorage.prepare(root2, dl, 34);
    ok("other install gets its own folder", new File(dl, "Dokkan Unit Creator (2)").equals(PublicStorage.folder()));
    // old Android: stays private
    File root3 = new File(t, "app3/forge"); w(new File(root3, "preview-cache/z.body"), "z");
    reset(); PublicStorage.prepare(root3, dl, 29);
    ok("Android 10 stays private", PublicStorage.folder() == null && !Files.isSymbolicLink(new File(root3, "preview-cache").toPath()) && PublicStorage.label().isEmpty());
    // downloads through OfflineLibrary.download path: savedBody through the link
    System.out.println(fails == 0 ? "ALL PASS" : fails + " FAILED");
    System.exit(fails);
  }
}
