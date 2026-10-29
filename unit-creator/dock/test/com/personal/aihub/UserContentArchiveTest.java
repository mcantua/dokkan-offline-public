package com.personal.aihub;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.zip.*;
import org.json.*;

/** Focused actual-filesystem archive/restore and corruption check; no Android device claims. */
public class UserContentArchiveTest {
    static int checks;
    static void ok(String name,boolean value){checks++;if(!value)throw new AssertionError(name);System.out.println("PASS "+name);}
    static void write(File f,String s)throws Exception{f.getParentFile().mkdirs();Files.write(f.toPath(),s.getBytes("UTF-8"));}
    static void start(File root,File downloads,boolean access)throws Exception{PublicStorage.resetForTest();PublicStorage.allFilesForTest=access;PublicStorage.prepare(root,downloads,34);PublicStorage.awaitMove(10000);}
    static JSONObject action(File root,String action)throws Exception{return UserContentArchive.dispatch(root,new JSONObject().put("action",action));}
    static Map<String,byte[]> unzip(File f)throws Exception{Map<String,byte[]> out=new LinkedHashMap<String,byte[]>();try(ZipInputStream in=new ZipInputStream(new FileInputStream(f))){ZipEntry e;byte[] b=new byte[1024];while((e=in.getNextEntry())!=null){ByteArrayOutputStream bytes=new ByteArrayOutputStream();int n;while((n=in.read(b))!=-1)bytes.write(b,0,n);out.put(e.getName(),bytes.toByteArray());}}return out;}
    static void zip(File f,Map<String,byte[]> data)throws Exception{try(ZipOutputStream out=new ZipOutputStream(new FileOutputStream(f))){for(Map.Entry<String,byte[]> e:data.entrySet()){out.putNextEntry(new ZipEntry(e.getKey()));out.write(e.getValue());out.closeEntry();}}}
    static boolean fails(File root)throws Exception{try{action(root,"restore");return false;}catch(IOException expected){return true;}}
    public static void main(String[]args)throws Exception{
      File temp=Files.createTempDirectory("dokkan-content-").toFile();
      try{
        File downloads=new File(temp,"Download"),first=new File(temp,"first/forge");downloads.mkdirs();
        String id=UUID.randomUUID().toString(),unit="projects/unit-1.json",art="assets/generated-"+id+"/image.png";
        write(new File(first,unit),"{\"format\":\"dokkan-unit-forge\",\"key\":\"unit-1\",\"cardOverrides\":{\"name\":\"Saved unit\"}}");write(new File(first,art),"fixture-art");
        write(new File(first,"project-versions/unit-1/index.json"),"[]");write(new File(first,"patches/"+id+".json"),"{\"key\":\""+id+"\"}");
        write(new File(first,"ai-connections.json"),"do-not-archive");write(new File(first,"sprk-format-key.bin"),"do-not-archive");write(new File(first,"signing/private.jks"),"do-not-archive");
        write(new File(first,"assets/import-"+id+"/_databases/database.db"),"do-not-archive");write(new File(first,"assets/generated-"+id+"/credentials.json"),"do-not-archive");
        start(first,downloads,false);JSONObject saved=action(first,"save");File archive=new File(PublicStorage.folder(),"Creations-for-reinstall.zip");
        Map<String,byte[]> original=unzip(archive);ok("one archive includes units, versions, patch metadata and art",saved.getInt("files")==4&&original.containsKey(unit)&&original.containsKey(art));
        boolean safe=true;for(String p:original.keySet())if(p.contains("database.db")||p.contains("credentials")||p.contains("ai-connections")||p.contains("sprk-format")||p.contains(".jks"))safe=false;
        ok("native databases, AI credentials and Sparking/signing secrets excluded",safe);
        action(first,"save");File[] copies=archive.getParentFile().listFiles((d,n)->n.contains("Creations-for-reinstall")||n.equals(".creations-archive.part"));ok("saving overwrites one archive without extra copies",copies.length==1);
        File numbered=new File(downloads,PublicStorage.NAME+" (2)");write(new File(numbered,".dokkan-unit-creator"),UUID.randomUUID().toString());File prior=new File(numbered,archive.getName());Files.move(archive.toPath(),prior.toPath());archive=prior;
        File second=new File(temp,"second/forge");start(second,downloads,false);ok("reinstall cannot restore before reauthorization",fails(second)&&!new File(second,unit).exists());
        PublicStorage.allFilesForTest=true;PublicStorage.check();PublicStorage.awaitMove(10000);
        ok("fresh grant finds a single archive left in a numbered folder",action(second,"status").getBoolean("exists")&&action(second,"status").getString("folder").equals(numbered.getName()));
        JSONObject restored=action(second,"restore");ok("fresh grant restores private canonical files and asset references",restored.getInt("restored")==4&&new File(second,unit).isFile()&&new String(Files.readAllBytes(new File(second,art).toPath()),"UTF-8").equals("fixture-art")&&!Files.isSymbolicLink(new File(second,"assets").toPath()));
        ok("identical restore is idempotent",action(second,"restore").getInt("unchanged")==4);
        action(second,"save");ok("saving continues to replace the same archive rather than duplicate it",archive.isFile()&&!new File(PublicStorage.folder(),archive.getName()).exists());
        write(new File(second,unit),"different-existing-unit");ok("different existing files are not overwritten",fails(second)&&new String(Files.readAllBytes(new File(second,unit).toPath()),"UTF-8").equals("different-existing-unit"));
        File third=new File(temp,"third/forge");start(third,downloads,true);
        Map<String,byte[]> corrupt=new LinkedHashMap<String,byte[]>(original);corrupt.put(unit,"damaged".getBytes("UTF-8"));zip(archive,corrupt);ok("checksum failure restores nothing",fails(third)&&!new File(third,unit).exists()&&!new File(third,art).exists());
        Map<String,byte[]> escape=new LinkedHashMap<String,byte[]>(original);escape.put("../personal.txt","bad".getBytes("UTF-8"));zip(archive,escape);ok("ZIP path traversal rejected without writes",fails(third)&&!new File(temp,"personal.txt").exists());
        zip(archive,original);File outside=new File(temp,"outside");outside.mkdirs();Files.createSymbolicLink(new File(third,"assets").toPath(),outside.toPath());ok("restore rejects private-root symlink escapes",fails(third)&&outside.list().length==0);
        ok("all restore staging directories cleaned",third.listFiles((d,n)->n.startsWith(".creations-restore-")).length==0);
        System.out.println(checks+" content archive/restore checks passed; physical Android reauthorization remains unverified.");
      }finally{PublicStorage.resetForTest();PublicStorage.removeTree(temp.toPath());}
    }
}
