package com.personal.aihub;
import java.io.*;
import java.nio.file.*;
import java.util.UUID;

/** Combined real-filesystem storage lifecycle check; no Android device claims. */
public class StorageTest {
  static int checks;
  static void ok(String name, boolean value) { checks++; if (!value) throw new AssertionError(name); System.out.println("PASS " + name); }
  static String hex(char c) { StringBuilder s=new StringBuilder(); for(int i=0;i<64;i++)s.append(c); return s.toString(); }
  static void write(File f,String v)throws IOException { f.getParentFile().mkdirs(); try(FileOutputStream o=new FileOutputStream(f)){o.write(v.getBytes("UTF-8"));} }
  static String read(File f)throws IOException{return new String(Files.readAllBytes(f.toPath()),"UTF-8");}
  static File file(File d,String p){return new File(d,p);}
  static void start(File r,File d,int sdk,boolean access)throws Exception{PublicStorage.resetForTest();PublicStorage.allFilesForTest=access;PublicStorage.prepare(r,d,sdk);PublicStorage.awaitMove(10000);}
  public static void main(String[]args)throws Exception{
    File t=Files.createTempDirectory("dokkan-storage-").toFile();
    try{
      String k=hex('a'); File dl=file(t,"Download"),r1=file(t,"first/forge");dl.mkdirs();
      write(file(r1,"preview-cache/"+k+".body"),"valid-old-body");write(file(r1,"preview-cache/"+k+".json"),"{}");
      write(file(r1,"preview-cache/personal.txt"),"private-personal");write(file(r1,"projects/unit.json"),"created-unit");
      start(r1,dl,34,false);File main=file(dl,PublicStorage.NAME);
      ok("fresh folder uses persistent shared path",main.equals(PublicStorage.folder())&&Files.isSymbolicLink(file(r1,"preview-cache").toPath()));
      ok("recognized private files migrate",read(file(main,"Game files/"+k+".body")).equals("valid-old-body"));
      ok("personal private files and created units remain untouched",read(file(r1,"preview-cache.moving/personal.txt")).equals("private-personal")&&read(file(r1,"projects/unit.json")).equals("created-unit"));
      File personal=file(main,"Game files/personal.txt");write(personal,"personal");personal.setLastModified(1000000000000L);long mt=personal.lastModified();
      File r2=file(t,"reinstalled/forge");start(r2,dl,34,false);
      ok("reinstall waits for fresh authorization",PublicStorage.folder()==null&&PublicStorage.check().getBoolean("needsChoice"));
      ok("waiting does not create duplicate folders",!file(dl,PublicStorage.NAME+" (2)").exists());
      PublicStorage.allFilesForTest=true;PublicStorage.check();PublicStorage.awaitMove(10000);
      ok("grant reuses original folder and bytes",main.equals(PublicStorage.folder())&&read(file(r2,"preview-cache/"+k+".body")).equals("valid-old-body"));
      PublicStorage.tidy(r2,null,null,null,null);
      ok("reownership leaves personal file bytes and metadata intact",read(personal).equals("personal")&&personal.lastModified()==mt);
      ok("adopted files survive atomic reownership",read(file(main,"Game files/"+k+".body")).equals("valid-old-body")&&!file(r2,"public-reown.txt").exists());
      File other=file(dl,PublicStorage.NAME+" (2)");write(file(other,".dokkan-unit-creator"),UUID.randomUUID().toString());write(file(other,"Game files/"+k+".body"),"different-body");
      PublicStorage.Report conflict=PublicStorage.tidy(r2,null,null,null,null);
      ok("same-name differing bytes are kept",conflict.conflicts>0&&read(file(other,"Game files/"+k+".body")).equals("different-body")&&read(file(main,"Game files/"+k+".body")).equals("valid-old-body"));
      ok("conflicting folder keeps its marker for retry",file(other,".dokkan-unit-creator").isFile());
      write(file(other,"Game files/"+k+".body"),"valid-old-body");PublicStorage.Report duplicate=PublicStorage.tidy(r2,null,null,null,null);
      ok("only byte-identical duplicate removed",duplicate.removed>0&&!file(other,"Game files/"+k+".body").exists());
      PublicStorage.clear(r2,"preview-cache");ok("clear preserves unknown personal files",!file(main,"Game files/"+k+".body").exists()&&read(personal).equals("personal"));
      File outside=file(t,"Personal");write(file(outside,k+".body"),"outside");PublicStorage.removeTree(file(main,"Game files").toPath());Files.createSymbolicLink(file(main,"Game files").toPath(),outside.toPath());
      PublicStorage.clear(r2,"preview-cache");PublicStorage.tidy(r2,null,null,null,null);ok("cleanup rejects public-subfolder symlink escape",read(file(outside,k+".body")).equals("outside"));
      File dl2=file(t,"OtherDownload"),unrelated=file(dl2,PublicStorage.NAME);write(file(unrelated,"notes.txt"),"unrelated");start(file(t,"third/forge"),dl2,34,true);
      ok("folder name alone cannot authorize adoption",!PublicStorage.isAppFolder(unrelated)&&!file(unrelated,".dokkan-unit-creator").exists()&&read(file(unrelated,"notes.txt")).equals("unrelated"));
      File dl3=file(t,"LegacyDownload"),legacy=file(t,"legacy/forge");dl3.mkdirs();start(legacy,dl3,28,false);
      ok("Android 8-10 asks for storage permission",PublicStorage.folder()==null&&PublicStorage.check().getBoolean("needsChoice")&&PublicStorage.check().getString("permissionKind").equals("storage"));
      PublicStorage.allFilesForTest=true;PublicStorage.check();PublicStorage.awaitMove(10000);ok("legacy grant enables shared storage",file(dl3,PublicStorage.NAME).equals(PublicStorage.folder()));
      write(file(legacy,"preview-cache/"+k+".body"),"legacy");File legacy2=file(t,"legacy2/forge");start(legacy2,dl3,28,false);
      ok("legacy reinstall requires a new grant",PublicStorage.folder()==null&&PublicStorage.check().getBoolean("needsChoice"));
      PublicStorage.allFilesForTest=true;PublicStorage.check();PublicStorage.awaitMove(10000);ok("legacy reinstall reuses shared downloads",read(file(legacy2,"preview-cache/"+k+".body")).equals("legacy")&&!file(dl3,PublicStorage.NAME+" (2)").exists());
      File declined=file(t,"declined/forge");start(declined,dl3,28,false);PublicStorage.decline();start(declined,dl3,28,false);
      ok("declining legacy permission stays private without repeated prompt",PublicStorage.folder()==null&&!PublicStorage.check().getBoolean("needsChoice"));
      System.out.println(checks+" checks passed; actual Android permission and uninstall flows remain device checks.");
    }finally{PublicStorage.resetForTest();PublicStorage.removeTree(t.toPath());}
  }
}
