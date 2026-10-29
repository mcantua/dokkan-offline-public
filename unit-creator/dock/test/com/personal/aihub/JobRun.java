package com.personal.aihub;
import java.io.*;
import java.util.*;
import org.json.*;
public class JobRun {
  static class Prefs implements android.content.SharedPreferences {
    final Map<String,Object> m = new HashMap<>();
    public boolean getBoolean(String k,boolean d){Object v=m.get(k);return v==null?d:(Boolean)v;}
    public int getInt(String k,int d){Object v=m.get(k);return v==null?d:(Integer)v;}
    public long getLong(String k,long d){Object v=m.get(k);return v==null?d:(Long)v;}
    public float getFloat(String k,float d){Object v=m.get(k);return v==null?d:(Float)v;}
    public String getString(String k,String d){Object v=m.get(k);return v==null?d:(String)v;}
    public Editor edit(){ final Prefs p=this; return new Editor(){
      public Editor putBoolean(String k,boolean v){p.m.put(k,v);return this;} public Editor putInt(String k,int v){p.m.put(k,v);return this;}
      public Editor putLong(String k,long v){p.m.put(k,v);return this;} public Editor putFloat(String k,float v){p.m.put(k,v);return this;}
      public Editor putString(String k,String v){p.m.put(k,v);return this;} public Editor remove(String k){p.m.remove(k);return this;}
      public boolean commit(){return true;} public void apply(){} }; }
  }
  static class Act extends android.app.Activity {
    final File files; final Map<String,Prefs> prefs = new HashMap<>(); final android.content.res.AssetManager am = new android.content.res.AssetManager();
    Act(File f){files=f;}
    public File getFilesDir(){return files;} public File getCacheDir(){File c=new File(files.getParentFile(),"cache"); c.mkdirs(); return c;}
    public android.content.res.AssetManager getAssets(){return am;} public android.content.Context getApplicationContext(){return this;}
    public android.content.SharedPreferences getSharedPreferences(String n,int m){return prefs.computeIfAbsent(n,k->new Prefs());}
    public Object getSystemService(String n){return new android.net.ConnectivityManager();}
    public String getPackageName(){return "com.personal.aihub";}
  }
  public static void main(String[] a) throws Exception {
    File app = new File(a[0]), downloads = new File(a[1]);
    String packs = a[2]; boolean movies = a.length > 3 && a[3].equals("movies");
    if (System.getenv("SCRIPT_INDEX") != null) android.content.res.AssetManager.SCRIPT_INDEX = System.getenv("SCRIPT_INDEX");
    Act act = new Act(new File(app, "files"));
    File root = new File(act.getFilesDir(), "forge");
    PublicStorage.prepare(root, downloads, 34);
    System.out.println("public folder: " + PublicStorage.folder());
    JSONObject args = new JSONObject().put("action","start").put("packs", new JSONArray(packs.split(","))).put("wifiOnly", true).put("movies", movies);
    JSONObject st = OfflineLibrary.dispatch(act, root, args);
    long t0 = System.currentTimeMillis(); String lastPhase = "";
    while (true) {
      Thread.sleep(5000);
      st = OfflineLibrary.dispatch(act, root, new JSONObject().put("action","status"));
      JSONObject j = st.getJSONObject("job");
      String line = String.format("%4ds %-28s done %d/%d failed %d skipped %d saved %.1f MB %s", (System.currentTimeMillis()-t0)/1000, j.optString("phase"), j.optLong("done"), j.optLong("total"), j.optLong("failed"), j.optLong("skipped"), j.optLong("savedBytes")/1048576.0, j.optString("waiting"));
      if (!j.optString("phase").equals(lastPhase) || (System.currentTimeMillis()-t0) % 60000 < 5000) System.out.println(line);
      lastPhase = j.optString("phase");
      if (j.optBoolean("finished")) { System.out.println(line); System.out.println("RESULT " + j.toString(1)); System.out.println("completed " + st.optJSONObject("completed") + " folder " + st.optString("folder")); break; }
    }
    System.exit(0);
  }
}
