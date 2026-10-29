package com.personal.aihub;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.zip.*;
import org.json.*;

/** Reinstall, malformed SQLite and stale replay in one actual-filesystem fixture lifecycle. */
public final class MasterDatabaseSnapshotsTest {
    static int checks;
    interface Action{void run()throws Exception;}
    static void ok(String label,boolean condition){if(!condition)throw new AssertionError(label);checks++;System.out.println("PASS "+label);}
    static boolean fails(Action action)throws Exception{try{action.run();return false;}catch(Exception expected){return true;}}
    static String read(File file)throws Exception{return new String(Files.readAllBytes(file.toPath()),"UTF-8");}
    static void write(File file,String text)throws Exception{file.getParentFile().mkdirs();Files.write(file.toPath(),text.getBytes("UTF-8"));}
    static GameDataStore store(File root){return new GameDataStore(root,new File(root,"bundled-database.db"));}
    static void start(File root,File downloads,boolean permission)throws Exception{PublicStorage.resetForTest();PublicStorage.allFilesForTest=permission;PublicStorage.prepare(root,downloads,34);PublicStorage.awaitMove(10000);}
    static JSONObject record(File archive)throws Exception{try(ZipFile z=new ZipFile(archive);InputStream in=z.getInputStream(z.getEntry("snapshot.json"))){ByteArrayOutputStream out=new ByteArrayOutputStream();byte[] b=new byte[4096];int n;while((n=in.read(b))!=-1)out.write(b,0,n);return new JSONObject(new String(out.toByteArray(),"UTF-8"));}}
    static void rewrite(File archive,JSONObject metadata,byte[] database)throws Exception{
        Map<String,byte[]> files=new LinkedHashMap<String,byte[]>();
        try(ZipFile zip=new ZipFile(archive)){Enumeration<? extends ZipEntry> all=zip.entries();while(all.hasMoreElements()){ZipEntry e=all.nextElement();try(InputStream in=zip.getInputStream(e)){ByteArrayOutputStream out=new ByteArrayOutputStream();byte[] b=new byte[4096];int n;while((n=in.read(b))!=-1)out.write(b,0,n);files.put(e.getName(),out.toByteArray());}}}
        files.put("snapshot.json",metadata.toString().getBytes("UTF-8"));if(database!=null)files.put("database.db",database);
        try(ZipOutputStream zip=new ZipOutputStream(new FileOutputStream(archive))){for(Map.Entry<String,byte[]> e:files.entrySet()){zip.putNextEntry(new ZipEntry(e.getKey()));zip.write(e.getValue());zip.closeEntry();}}
    }
    public static void main(String[] args)throws Exception{
        File fixture=new File(args[0]), newer=new File(args[1]);Path temp=Files.createTempDirectory("dokkan-master-check-");
        try{
            if(args.length>2&&"numbered".equals(args[2])){
                File downloads=temp.resolve("Download").toFile(),first=temp.resolve("first/forge").toFile();downloads.mkdirs();start(first,downloads,false);
                store(first).commit(fixture,new JSONObject().put("sourceType","eclipse-current"));MasterDatabaseSnapshots.save(first);
                File main=PublicStorage.folder(),old=new File(downloads,PublicStorage.NAME+" (2)");write(new File(old,".dokkan-unit-creator"),UUID.randomUUID().toString());
                File oldData=new File(old,"Game databases");oldData.mkdir();Files.move(new File(main,"Game databases/eclipse.snapshot").toPath(),new File(oldData,"eclipse.snapshot").toPath());
                File fresh=temp.resolve("fresh/forge").toFile();start(fresh,downloads,false);
                ok("numbered-folder snapshot stays inaccessible before fresh permission",!MasterDatabaseSnapshots.restore(fresh,"eclipse"));
                PublicStorage.allFilesForTest=true;PublicStorage.check();PublicStorage.awaitMove(10000);
                ok("fresh grant discovers snapshot in earlier recognized numbered folder",MasterDatabaseSnapshots.restore(fresh,"eclipse"));
                MasterDatabaseSnapshots.save(fresh);
                ok("next save overwrites the same one artifact without creating a second copy",new File(oldData,"eclipse.snapshot").isFile()&&!new File(main,"Game databases/eclipse.snapshot").exists());
                System.out.println(checks+" additional numbered-folder assertions passed; unchanged lifecycle scenarios were not rerun.");return;
            }
            File downloads=temp.resolve("Download").toFile(),first=temp.resolve("first/forge").toFile();downloads.mkdirs();start(first,downloads,false);
            JSONObject meta=new JSONObject().put("source","Fixture master").put("sourceType","eclipse-current").put("date","2026-10-28").put("aiKey","must-not-persist").put("sparkingKey","must-not-persist");
            store(first).commit(fixture,meta);MasterDatabaseSnapshots.save(first);
            File shared=new File(PublicStorage.folder(),"Game databases"),eclipse=new File(shared,"eclipse.snapshot");
            byte[] original=Files.readAllBytes(eclipse.toPath());
            ok("checked Eclipse snapshot has no connection or signing metadata",eclipse.isFile()&&!record(eclipse).toString().contains("must-not-persist")&&record(eclipse).getJSONObject("database").getJSONObject("schema").getLong("count")==1001);
            File spark=new File(first,"sparking");String manifest="{\"latest_version\":2000000000,\"assets\":[]}";String manifestName="catalog-assets-2000000000.json";write(new File(spark,manifestName),manifest);
            store(spark).commit(fixture,new JSONObject().put("sourceType","sparking-current").put("latestVersion",2000000000L).put("assetsManifest",manifestName));MasterDatabaseSnapshots.save(spark);
            ok("Sparking snapshot binds matching content and resource versions",new File(shared,"sparking.snapshot").isFile()&&record(new File(shared,"sparking.snapshot")).has("assets"));
            long timestamp=eclipse.lastModified();MasterDatabaseSnapshots.save(first);ok("unchanged shared snapshot is reused without rewriting",timestamp==eclipse.lastModified());
            File fresh=temp.resolve("reinstalled/forge").toFile();start(fresh,downloads,false);
            ok("reinstall cannot restore before fresh storage authorization",!MasterDatabaseSnapshots.restore(fresh,"eclipse")&&!new File(fresh,"database-state.json").exists());
            PublicStorage.allFilesForTest=true;PublicStorage.check();PublicStorage.awaitMove(10000);
            ok("fresh grant restores using original private activation",MasterDatabaseSnapshots.restore(fresh,"eclipse")&&store(fresh).current().isFile()&&store(fresh).meta().getString("sha256").equals(record(eclipse).getJSONObject("database").getString("sha256")));
            File freshSpark=new File(fresh,"sparking");ok("matching Sparking database and manifest restore without format keys",MasterDatabaseSnapshots.restore(freshSpark,"sparking")&&new File(freshSpark,manifestName).isFile()&&!new File(fresh,"sprk-format-key.bin").exists());
            File bundled=temp.resolve("bundled/forge/sparking").toFile();store(bundled).commit(fixture,new JSONObject().put("sourceType","sparking-bundled").put("latestVersion",2000000000L));
            ok("same bundled Sparking bytes do not repeatedly activate",!MasterDatabaseSnapshots.restore(bundled,"sparking"));
            store(fresh).commit(newer,meta);String activeHash=store(fresh).meta().getString("sha256");Files.write(eclipse.toPath(),original);
            ok("replayed snapshot cannot replace newer selected active database",!MasterDatabaseSnapshots.restore(fresh,"eclipse")&&store(fresh).meta().getString("sha256").equals(activeHash));
            File corruptRoot=temp.resolve("corrupt/forge").toFile();JSONObject broken=record(eclipse);byte[] bad=new byte[4096];Arrays.fill(bad,(byte)9);java.security.MessageDigest md=java.security.MessageDigest.getInstance("SHA-256");StringBuilder hex=new StringBuilder();for(byte b:md.digest(bad))hex.append(String.format("%02x",b&255));
            broken.getJSONObject("database").put("bytes",bad.length).put("sha256",hex.toString());rewrite(eclipse,broken,bad);
            ok("malformed SQLite with matching attacker-recomputed hash is refused",fails(()->MasterDatabaseSnapshots.restore(corruptRoot,"eclipse"))&&!new File(corruptRoot,"database-state.json").exists());
            Files.write(eclipse.toPath(),original);broken=record(eclipse);broken.getJSONObject("database").put("sha256",String.join("",Collections.nCopies(64,"0")));rewrite(eclipse,broken,null);
            ok("checksum mismatch is refused without activating any database",fails(()->MasterDatabaseSnapshots.restore(corruptRoot,"eclipse"))&&!new File(corruptRoot,"database-state.json").exists());
            Files.write(eclipse.toPath(),original);broken=record(eclipse);broken.getJSONObject("database").getJSONObject("schema").put("userVersion",999);rewrite(eclipse,broken,null);
            ok("SQLite version metadata mismatch is refused",fails(()->MasterDatabaseSnapshots.restore(corruptRoot,"eclipse"))&&!new File(corruptRoot,"database-state.json").exists());
            Files.write(eclipse.toPath(),original);File linked=temp.resolve("linked/forge").toFile(),personal=temp.resolve("personal").toFile();linked.getParentFile().mkdirs();personal.mkdirs();Files.createSymbolicLink(linked.toPath(),personal.toPath());
            ok("private-root symlink cannot redirect restore into personal files",fails(()->MasterDatabaseSnapshots.restore(linked,"eclipse"))&&personal.list().length==0);
            MasterDatabaseSnapshots.save(fresh);ok("one latest snapshot replaces old copy",shared.list((d,n)->n.equals("eclipse.snapshot")).length==1&&record(eclipse).getJSONObject("database").getString("sha256").equals(activeHash));
            try(java.util.stream.Stream<Path> paths=Files.walk(temp)){ok("no partial snapshot or restore staging remains",!paths.anyMatch(p->p.getFileName().toString().startsWith(".master-")));}
            System.out.println(checks+" master database lifecycle/corruption/replay checks passed; physical Android reinstall remains unverified.");
        }finally{PublicStorage.resetForTest();PublicStorage.removeTree(temp);}
    }
}
