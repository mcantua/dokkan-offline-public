package com.personal.aihub;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import org.json.*;

/** New bulk-gallery cases only; actual ZIP/filesystem, no package/device claim. */
public final class BulkGalleryArchiveTest {
 public static void main(String[]args)throws Exception{
  File temp=Files.createTempDirectory("dokkan-bulk-gallery-").toFile();
  try{
   File downloads=new File(temp,"Download"),first=new File(temp,"first/forge");downloads.mkdirs();
   JSONObject snapshot=new JSONObject(new String(Files.readAllBytes(Paths.get(args[0])),"UTF-8"));
   String asset="assets/"+snapshot.getJSONArray("documents").getJSONObject(0).getJSONArray("assets").getJSONObject(0).getString("key");
   UserContentArchiveTest.write(new File(first,asset),"SYNTHETIC");
   UserContentArchiveTest.write(new File(first,"ai-connections.json"),"private");
   UserContentArchiveTest.write(new File(first,"assets/import-11111111-1111-4111-8111-111111111111/_databases/master.db"),"private");
   UserContentArchiveTest.start(first,downloads,false);
   JSONObject saved=UserContentArchive.dispatch(first,new JSONObject().put("action","save").put("gallery",snapshot));
   File archive=new File(PublicStorage.folder(),"Creations-for-reinstall.zip");Map<String,byte[]> original=UserContentArchiveTest.unzip(archive);
   UserContentArchiveTest.ok("bulk archive contains gallery document plus media, excludes databases and credentials",saved.getInt("galleryDocuments")==1&&original.size()==3&&original.containsKey(asset)&&original.keySet().toString().contains("animation-gallery/"));
   byte[] archiveBytes=Files.readAllBytes(archive.toPath());JSONObject unsafe=new JSONObject(snapshot.toString());unsafe.getJSONArray("documents").getJSONObject(0).getJSONObject("animationStudio").put("apiKey","private");boolean failed=false;try{UserContentArchive.dispatch(first,new JSONObject().put("action","save").put("gallery",unsafe));}catch(Exception expected){failed=true;}
   UserContentArchiveTest.ok("private gallery fields rejected before replacing the one archive",failed&&Arrays.equals(archiveBytes,Files.readAllBytes(archive.toPath())));
   File second=new File(temp,"second/forge");UserContentArchiveTest.start(second,downloads,false);
   UserContentArchiveTest.ok("fresh grant required for bulk restore",UserContentArchiveTest.fails(second));
   PublicStorage.allFilesForTest=true;PublicStorage.check();PublicStorage.awaitMove(10000);
   JSONObject restored=UserContentArchiveTest.action(second,"restore");
   UserContentArchiveTest.ok("verified gallery returned only after media restore with no stale native document mirror",restored.getInt("restored")==1&&restored.getJSONObject("gallery").getBoolean("verifiedFiles")&&new File(second,asset).isFile()&&!new File(second,"animation-gallery").exists());
   UserContentArchiveTest.ok("repeated native restore idempotent and archive intact for IndexedDB retry",UserContentArchiveTest.action(second,"restore").getInt("unchanged")==1&&Arrays.equals(archiveBytes,Files.readAllBytes(archive.toPath())));
   Files.write(Paths.get(args[1]),restored.getJSONObject("gallery").toString().getBytes("UTF-8"));
   File third=new File(temp,"third/forge");UserContentArchiveTest.start(third,downloads,true);Map<String,byte[]> corrupt=new LinkedHashMap<String,byte[]>(original);for(String path:original.keySet())if(path.startsWith("animation-gallery/"))corrupt.put(path,"damaged".getBytes("UTF-8"));UserContentArchiveTest.zip(archive,corrupt);
   UserContentArchiveTest.ok("corrupt gallery checksum activates no resource files",UserContentArchiveTest.fails(third)&&!new File(third,asset).exists());
  }finally{PublicStorage.resetForTest();PublicStorage.removeTree(temp.toPath());}
 }
}
