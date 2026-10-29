package com.personal.aihub;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.MessageDigest;
import java.util.*;
import java.util.zip.*;
import org.json.*;

/** One checked, key-free master snapshot per game, outside uninstallable private storage.
 * Original GameDataStore still stages/activates the private database and its one undo slot.
 * All entry points run on the original bridge worker; no hashing or copying runs on the UI thread.
 */
public final class MasterDatabaseSnapshots {
    private static final long MAX_DB=512L*1024*1024, MAX_ASSETS=32L*1024*1024;
    private static final int MAX_META=64*1024;
    private static boolean restoring;
    private static String warning="";
    private static final Map<String,String> saved=new HashMap<String,String>();
    private MasterDatabaseSnapshots() {}

    /** Post-commit smali hook. A snapshot failure must never fail the successful private activation. */
    public static synchronized void changed(File storeRoot) {
        if(restoring)return;
        try { save(storeRoot); warning=""; }
        catch(Throwable problem){warning="Shared game-data copy was not updated: "+problem.getMessage();}
    }

    static synchronized JSONObject reconcile(File root) {
        JSONObject status=new JSONObject();
        try {
            if(folder(false)==null)return status.put("available",false);
            warning="";status.put("available",true);
            for(String game:new String[]{"eclipse","sparking"})try{
                File storeRoot="eclipse".equals(game)?root:new File(root,"sparking");
                boolean restored=restore(storeRoot,game);
                // Files created before shared storage was granted also get their one persistent copy.
                save(storeRoot);status.put("restored"+("eclipse".equals(game)?"Eclipse":"Sparking"),restored);
            }catch(Exception problem){warning+=(warning.isEmpty()?"":" ")+game+": "+problem.getMessage();}
        }catch(Exception problem){warning="Shared game-data reuse needs attention: "+problem.getMessage();}
        try {if(!warning.isEmpty())status.put("warning",warning);}catch(JSONException ignored){}
        return status;
    }

    private static File folder(boolean create)throws Exception {
        File base=PublicStorage.folder();
        if(base==null||!PublicStorage.isAppFolder(base))return null;
        File dir=new File(base,"Game databases");
        if(PublicStorage.isLink(dir))throw new IOException("Game-data folder cannot be a symbolic link.");
        if(create&&!dir.isDirectory()&&!dir.mkdir())throw new IOException("Could not prepare shared game data.");
        return dir;
    }

    private static String game(File storeRoot){return "sparking".equals(storeRoot.getName())?"sparking":"eclipse";}
    private static GameDataStore store(File root){return new GameDataStore(root,new File(root,"sparking".equals(game(root))?"sparking-unavailable.db":"bundled-database.db"));}

    private static File snapshot(File directory,String game)throws Exception {
        File current=safe(directory,game+".snapshot"),found=current.isFile()?current:null;
        if(current.exists()&&!current.isFile())throw new IOException("The master snapshot location is not a regular file.");
        if(PublicStorage.allFiles())for(File old:PublicStorage.otherAppFolders()){
            File oldDirectory=new File(old,"Game databases");
            if(!PublicStorage.isAppFolder(old)||!oldDirectory.isDirectory()||PublicStorage.isLink(oldDirectory))continue;
            File candidate=safe(oldDirectory,game+".snapshot");
            if(!candidate.isFile())continue;
            if(found!=null)throw new IOException("More than one "+game+" master snapshot remains. Keep the copy you want before restoring or updating shared game data.");
            found=candidate;
        }
        return found==null?current:found;
    }

    private static File safe(File root,String path)throws Exception {
        if(PublicStorage.isLink(root))throw new IOException("Game-data root cannot be a symbolic link.");
        File canonical=root.getCanonicalFile(),at=canonical;
        for(String segment:path.split("/")){
            if(segment.isEmpty()||segment.equals(".")||segment.equals("..")||segment.contains("\\"))throw new IOException("Unsafe game-data path.");
            at=new File(at,segment);if(PublicStorage.isLink(at))throw new IOException("Game-data paths cannot be symbolic links.");
        }
        if(!at.getCanonicalPath().startsWith(canonical.getPath()+File.separator))throw new IOException("Unsafe game-data location.");
        return at;
    }

    private static JSONObject readJson(File f,long max)throws Exception {
        if(!f.isFile()||f.length()>max)throw new IOException("Game-data metadata exceeds its limit or is missing.");
        return new JSONObject(new String(Files.readAllBytes(f.toPath()),StandardCharsets.UTF_8));
    }

    private static JSONObject digest(File file)throws Exception {
        MessageDigest md=MessageDigest.getInstance("SHA-256");long count=0;
        try(InputStream in=new FileInputStream(file)){byte[] block=new byte[65536];int n;while((n=in.read(block))!=-1){count+=n;md.update(block,0,n);}}
        StringBuilder hex=new StringBuilder();for(byte b:md.digest())hex.append(String.format(Locale.ROOT,"%02x",b&255));
        return new JSONObject().put("bytes",count).put("sha256",hex.toString());
    }

    private static void match(File file,JSONObject expected,long max)throws Exception {
        long bytes=expected.getLong("bytes");String sha=expected.getString("sha256");
        if(bytes<1||bytes>max||file.length()!=bytes||!sha.matches("[a-f0-9]{64}")||!sha.equals(digest(file).getString("sha256")))throw new IOException("Saved game-data size or SHA-256 does not match.");
    }

    /** Match original strict master checks and record the exact column schema and SQLite version. */
    static JSONObject verify(File file)throws Exception {
        if(!file.isFile()||file.length()<512||file.length()>MAX_DB)throw new IOException("Invalid game database size.");
        SQLiteDatabase db=SQLiteDatabase.openDatabase(file.getPath(),null,SQLiteDatabase.OPEN_READONLY);
        try {
            try(Cursor c=db.rawQuery("PRAGMA quick_check",null)){if(!c.moveToNext()||!"ok".equals(c.getString(0))||c.moveToNext())throw new IOException("Saved game database failed SQLite integrity checks.");}
            String[][] required={{"cards","id","name","rarity","element","resource_id","hp_max","atk_max","def_max","passive_skill_set_id","leader_skill_set_id"},{"card_categories","id","name"},{"link_skills","id","name"},{"leader_skill_sets","id"},{"leader_skills","id","leader_skill_set_id"},{"passive_skill_sets","id"},{"passive_skills","id"},{"passive_skill_set_relations","id","passive_skill_set_id","passive_skill_id"}};
            StringBuilder schema=new StringBuilder();
            for(String[] table:required){
                try(Cursor c=db.rawQuery("SELECT type FROM sqlite_master WHERE name=?",new String[]{table[0]})){if(!c.moveToNext()||!"table".equals(c.getString(0)))throw new IOException("Saved game database is missing table "+table[0]+".");}
                Set<String> columns=new TreeSet<String>();
                try(Cursor c=db.rawQuery("PRAGMA table_info(\""+table[0]+"\")",null)){while(c.moveToNext())columns.add(c.getString(1));}
                for(int i=1;i<table.length;i++)if(!columns.contains(table[i]))throw new IOException("Saved game database is missing fields in "+table[0]+".");
                schema.append(table[0]).append(':').append(columns.toString()).append('\n');
            }
            long rows,version;
            try(Cursor c=db.rawQuery("SELECT count(*) FROM cards",null)){if(!c.moveToNext()||(rows=c.getLong(0))<1000)throw new IOException("Saved game database contains incomplete character data.");}
            try(Cursor c=db.rawQuery("PRAGMA user_version",null)){if(!c.moveToNext())throw new IOException("Saved game database has no SQLite version.");version=c.getLong(0);}
            MessageDigest md=MessageDigest.getInstance("SHA-256");StringBuilder hash=new StringBuilder();for(byte b:md.digest(schema.toString().getBytes(StandardCharsets.UTF_8)))hash.append(String.format(Locale.ROOT,"%02x",b&255));
            return new JSONObject().put("count",rows).put("userVersion",version).put("schemaSHA256",hash.toString());
        }finally{db.close();}
    }

    private static JSONObject metadata(JSONObject original)throws Exception {
        JSONObject meta=new JSONObject();
        for(String key:new String[]{"source","sourceType","date","publishedAt","latestVersion","count","assetsManifest"}){
            Object value=original.opt(key);
            if(value==null||value==JSONObject.NULL)continue;
            if((value instanceof String&&((String)value).length()<=1000)||value instanceof Number)meta.put(key,value);
        }
        return meta;
    }

    private static File assets(File root,JSONObject meta)throws Exception {
        String name=meta.optString("assetsManifest","");
        if(name.isEmpty())return null;
        if(!name.matches("(assets-[a-f0-9]{64}|catalog-assets-[0-9]+)\\.json"))throw new IOException("Invalid saved Sparking resource-list name.");
        File file=safe(root,name);JSONObject manifest=readJson(file,MAX_ASSETS);
        if(meta.optLong("latestVersion",0)<=0||manifest.optLong("latest_version",-1)!=meta.getLong("latestVersion")||manifest.optJSONArray("assets")==null)throw new IOException("Sparking resource list does not match its database version.");
        if(name.startsWith("assets-")&&!name.equals("assets-"+digest(file).getString("sha256")+".json"))throw new IOException("Sparking resource-list SHA-256 does not match.");
        return file;
    }

    static synchronized void save(File root)throws Exception {
        File dir=folder(true);if(dir==null)return;
        File pointer=safe(root,"database-state.json");if(!pointer.isFile())return;
        JSONObject state=readJson(pointer,1024*1024);
        if(state.optInt("version")!=1)throw new IOException("Unsupported private database state.");
        JSONObject active=state.getJSONObject("active"),meta=metadata(active.getJSONObject("meta"));String name=active.getString("file");
        if(!name.matches("db-[a-f0-9]{64}\\.db"))throw new IOException("Unsafe private database filename.");
        File database=safe(root,"databases/"+name);String game=game(root);
        if("sparking".equals(game)&&!meta.has("assetsManifest")){
            String legacy="catalog-assets-"+meta.optLong("latestVersion",0)+".json";
            if(safe(root,legacy).isFile())meta.put("assetsManifest",legacy);
        }
        File target=snapshot(dir,game);
        String identity=name+":"+meta.toString()+":"+database.length()+":"+database.lastModified();
        String stamp=identity+":"+target.length()+":"+target.lastModified();
        if(stamp.equals(saved.get(target.getCanonicalPath())))return;
        JSONObject databaseInfo=digest(database);
        if(!name.equals("db-"+databaseInfo.getString("sha256")+".db"))throw new IOException("Active database does not match its stored address.");
        JSONObject checked=verify(database);databaseInfo.put("schema",checked);
        if("sparking".equals(game)&&meta.optLong("latestVersion",0)<=0)throw new IOException("Sparking data has no content version.");
        File asset="sparking".equals(game)?assets(root,meta):null;
        JSONObject record=new JSONObject().put("format","dokkan-master").put("version",1).put("game",game).put("database",databaseInfo).put("meta",meta);
        if(asset!=null)record.put("assets",digest(asset));
        File part=Files.createTempFile(target.getParentFile().toPath(),".master-",".part").toFile();
        try {
            try(FileOutputStream raw=new FileOutputStream(part);ZipOutputStream zip=new ZipOutputStream(raw)){
                zip.setLevel(Deflater.BEST_SPEED);zipFile(zip,"database.db",database);
                if(asset!=null)zipFile(zip,"assets.json",asset);
                zip.putNextEntry(new ZipEntry("snapshot.json"));zip.write(record.toString().getBytes(StandardCharsets.UTF_8));zip.closeEntry();zip.finish();raw.getFD().sync();
            }
            replace(part,target);
            saved.put(target.getCanonicalPath(),identity+":"+target.length()+":"+target.lastModified());
            if(saved.size()>8)saved.remove(saved.keySet().iterator().next());
        }finally{part.delete();}
    }

    private static void replace(File from,File to)throws IOException {
        try{Files.move(from.toPath(),to.toPath(),StandardCopyOption.ATOMIC_MOVE,StandardCopyOption.REPLACE_EXISTING);}
        catch(AtomicMoveNotSupportedException e){Files.move(from.toPath(),to.toPath(),StandardCopyOption.REPLACE_EXISTING);}
    }

    private static void zipFile(ZipOutputStream zip,String name,File file)throws Exception {
        zip.putNextEntry(new ZipEntry(name));try(InputStream in=new FileInputStream(file)){byte[] block=new byte[65536];int n;while((n=in.read(block))!=-1)zip.write(block,0,n);}zip.closeEntry();
    }

    private static JSONObject zipJson(ZipFile zip,String name)throws Exception {
        ZipEntry e=zip.getEntry(name);if(e==null||e.isDirectory()||e.getSize()<1||e.getSize()>MAX_META)throw new IOException("Invalid master snapshot metadata.");
        ByteArrayOutputStream out=new ByteArrayOutputStream();try(InputStream in=zip.getInputStream(e)){byte[] b=new byte[4096];int n;while((n=in.read(b))!=-1){if(out.size()+n>MAX_META)throw new IOException("Oversized master snapshot metadata.");out.write(b,0,n);}}
        return new JSONObject(new String(out.toByteArray(),StandardCharsets.UTF_8));
    }

    private static void extract(ZipFile zip,String name,File file,long max)throws Exception {
        ZipEntry e=zip.getEntry(name);if(e==null||e.isDirectory()||e.getSize()<1||e.getSize()>max)throw new IOException("Invalid master snapshot entry.");
        long size=0;try(InputStream in=zip.getInputStream(e);FileOutputStream out=new FileOutputStream(file)){
            byte[] b=new byte[65536];int n;while((n=in.read(b))!=-1){size+=n;if(size>max||size>e.getSize())throw new IOException("Master snapshot entry exceeds its limit.");out.write(b,0,n);}out.getFD().sync();
        }if(size!=e.getSize())throw new IOException("Truncated master snapshot.");
    }

    static synchronized boolean restore(File root,String game)throws Exception {
        File dir=folder(false);if(dir==null)return false;
        File snapshot=snapshot(dir,game);if(!snapshot.isFile())return false;
        File pointer=safe(root,"database-state.json");JSONObject prior=pointer.isFile()?readJson(pointer,1024*1024):null;
        JSONObject previousMeta=prior==null?null:prior.getJSONObject("active").getJSONObject("meta");
        // A replay must never replace already selected/imported/downloaded data.
        if(prior!=null&&!("sparking".equals(game)&&"sparking-bundled".equals(previousMeta.optString("sourceType"))))return false;
        if(snapshot.length()>MAX_DB+MAX_ASSETS+2*1024*1024)throw new IOException("Master snapshot exceeds its limit.");
        if(!root.isDirectory()&&!root.mkdirs())throw new IOException("Could not prepare private database storage.");
        if(PublicStorage.isLink(root))throw new IOException("Private database root cannot be a link.");
        File stage=Files.createTempDirectory(root.toPath(),".master-restore-").toFile();
        try(ZipFile zip=new ZipFile(snapshot)){
            Set<String> names=new HashSet<String>();Enumeration<? extends ZipEntry> all=zip.entries();
            while(all.hasMoreElements()){String n=all.nextElement().getName();if(!Arrays.asList("database.db","assets.json","snapshot.json").contains(n)||!names.add(n))throw new IOException("Master snapshot contains unexpected or duplicate paths.");}
            JSONObject record=zipJson(zip,"snapshot.json");
            if(record.optInt("version")!=1||!"dokkan-master".equals(record.optString("format"))||!game.equals(record.optString("game")))throw new IOException("Unsupported master snapshot identity.");
            if(previousMeta!=null&&record.getJSONObject("database").optString("sha256").equals(previousMeta.optString("sha256")))return false;
            JSONObject meta=metadata(record.getJSONObject("meta"));
            if("sparking".equals(game)&&(meta.optLong("latestVersion",0)<=0||(previousMeta!=null&&meta.getLong("latestVersion")<previousMeta.optLong("latestVersion",0))))throw new IOException("Saved Sparking version is older than the active catalogue.");
            File database=new File(stage,"database.db");extract(zip,"database.db",database,MAX_DB);match(database,record.getJSONObject("database"),MAX_DB);
            JSONObject checked=verify(database),schema=record.getJSONObject("database").getJSONObject("schema");
            if(checked.getLong("count")!=schema.getLong("count")||checked.getLong("userVersion")!=schema.getLong("userVersion")||!checked.getString("schemaSHA256").equals(schema.getString("schemaSHA256")))throw new IOException("Saved database schema/version does not match its snapshot.");
            if(record.has("assets")){
                if(!"sparking".equals(game))throw new IOException("Unexpected resource manifest in Eclipse snapshot.");
                File asset=new File(stage,"assets.json");extract(zip,"assets.json",asset,MAX_ASSETS);match(asset,record.getJSONObject("assets"),MAX_ASSETS);
                String assetName=meta.optString("assetsManifest","");
                if(!assetName.matches("(assets-[a-f0-9]{64}|catalog-assets-[0-9]+)\\.json"))throw new IOException("Unsafe resource-list destination.");
                File assetStage=new File(stage,assetName);Files.move(asset.toPath(),assetStage.toPath());assets(stage,meta);
                File target=safe(root,assetName);
                if(target.exists()){if(!digest(target).getString("sha256").equals(record.getJSONObject("assets").getString("sha256")))throw new IOException("Existing private resource list differs; it was kept.");}
                else Files.move(assetStage.toPath(),target.toPath());
            }else if(names.contains("assets.json")||meta.has("assetsManifest"))throw new IOException("Snapshot resource-list metadata is incomplete.");
            // Original atomic private activation retains the previous database if staging/commit fails.
            restoring=true;
            try{store(root).commit(database,meta);}finally{restoring=false;}
            return true;
        }finally{PublicStorage.removeTree(stage.toPath());}
    }
}
