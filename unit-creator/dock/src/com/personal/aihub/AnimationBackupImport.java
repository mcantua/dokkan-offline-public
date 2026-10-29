package com.personal.aihub;

import android.app.Activity;
import android.content.Intent;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.MessageDigest;
import java.text.Normalizer;
import java.util.*;
import java.util.zip.*;
import org.json.*;

/** Dedicated, bounded animation ZIP picker. Never invokes the unit/database importers. */
final class AnimationBackupImport {
    private static final int REQUEST=0x5f3, MAX_DOCUMENT=8*1024*1024;
    private static final long MAX_ARCHIVE=80L*1024*1024, MAX_RESOURCES=64L*1024*1024;
    private static final Object LOCK=new Object();
    private static boolean done;private static Object selected;
    private AnimationBackupImport(){}

    static JSONObject pick(File root)throws Exception {
        final Activity activity=ForgeFixes.activity();if(activity==null)throw new IOException("The app is still starting.");
        synchronized(LOCK){done=false;selected=null;}
        final Intent intent=new Intent("android.intent.action.OPEN_DOCUMENT").addCategory("android.intent.category.OPENABLE");
        Intent.class.getMethod("setType",String.class).invoke(intent,"application/zip");
        activity.runOnUiThread(new Runnable(){public void run(){try{Activity.class.getMethod("startActivityForResult",Intent.class,int.class).invoke(activity,intent,REQUEST);}catch(Throwable failure){synchronized(LOCK){done=true;LOCK.notifyAll();}}}});
        long deadline=System.currentTimeMillis()+15*60*1000;
        synchronized(LOCK){while(!done&&System.currentTimeMillis()<deadline)LOCK.wait(1000);}
        Object uri;synchronized(LOCK){uri=selected;}if(uri==null)return new JSONObject().put("canceled",true);
        File archive=File.createTempFile("animation-backup-",".zip",activity.getCacheDir());
        try {
            Object resolver=activity.getClass().getMethod("getContentResolver").invoke(activity);
            InputStream source=(InputStream)resolver.getClass().getMethod("openInputStream",Class.forName("android.net.Uri")).invoke(resolver,uri);
            if(source==null)throw new IOException("That animation backup cannot be opened.");
            try(InputStream in=source;FileOutputStream out=new FileOutputStream(archive)){copy(in,out,MAX_ARCHIVE,null);out.getFD().sync();}
            return importFile(root,archive);
        }finally{archive.delete();}
    }

    static boolean activityResult(int request,int result,Intent data){
        if(request!=REQUEST)return false;Object uri=null;
        if(result==-1&&data!=null)try{uri=Intent.class.getMethod("getData").invoke(data);}catch(Throwable ignored){}
        synchronized(LOCK){selected=uri;done=true;LOCK.notifyAll();}return true;
    }

    private static boolean resourcePath(String path){return path.matches("resources/(?:[1-9][0-9]{0,2})\\.(?:png|jpg|jpeg|webp|gif|bmp|lwf|lua|usm|ogg|mp3|m4a|aac|wav|flac|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)")&&Integer.parseInt(path.substring(10,path.indexOf('.')))<=256;}
    private static long copy(InputStream in,OutputStream out,long limit,MessageDigest digest)throws Exception{
        long total=0;byte[] block=new byte[65536];int n;while((n=in.read(block))!=-1){total+=n;if(total>limit)throw new IOException("Animation backup exceeds its supported size.");out.write(block,0,n);if(digest!=null)digest.update(block,0,n);}return total;
    }
    private static String hex(byte[] bytes){StringBuilder text=new StringBuilder();for(byte b:bytes)text.append(String.format(Locale.ROOT,"%02x",b&255));return text.toString();}

    /** ZIP central flags/modes are not exposed by java.util.zip.ZipEntry. Reject links and ZIP64 here. */
    private static void directory(File file)throws Exception {
        try(RandomAccessFile in=new RandomAccessFile(file,"r")){
            int length=(int)Math.min(file.length(),65557);byte[] tail=new byte[length];in.seek(file.length()-length);in.readFully(tail);int end=-1;
            for(int i=length-22;i>=0;i--)if(u32(tail,i)==0x06054b50L&&i+22+u16(tail,i+20)==length){end=i;break;}
            if(end<0||u16(tail,end+4)!=0||u16(tail,end+6)!=0||u16(tail,end+8)!=u16(tail,end+10))throw new IOException("Invalid animation ZIP directory.");
            int count=u16(tail,end+10);long bytes=u32(tail,end+12),offset=u32(tail,end+16);
            if(count<1||count>257||offset==0xffffffffL||bytes==0xffffffffL||offset+bytes!=file.length()-length+end)throw new IOException("Animation ZIP uses unsupported entries or ZIP64.");
            in.seek(offset);Set<String> names=new HashSet<String>();
            for(int i=0;i<count;i++){
                byte[] header=new byte[46];in.readFully(header);int flags=u16(header,8),method=u16(header,10),nameLength=u16(header,28),extra=u16(header,30),comment=u16(header,32),mode=(int)(u32(header,38)>>>16)&0xf000;
                if(u32(header,0)!=0x02014b50L||(flags&~0x808)!=0||(method!=0&&method!=8)||(mode!=0&&mode!=0x8000)||u16(header,34)!=0||nameLength<1||nameLength>200)throw new IOException("Animation ZIP contains linked, encrypted or unsupported entries.");
                byte[] name=new byte[nameLength];in.readFully(name);String path=new String(name,StandardCharsets.UTF_8);
                if(!"animation.json".equals(path)&&!resourcePath(path))throw new IOException("Animation ZIP contains an unexpected resource path.");
                if(!names.add(Normalizer.normalize(path,Normalizer.Form.NFC).toLowerCase(Locale.ROOT)))throw new IOException("Animation ZIP contains duplicate resources.");
                long next=in.getFilePointer()+extra+comment,localOffset=u32(header,42),compressed=u32(header,20);
                if(next>offset+bytes||localOffset+30>offset)throw new IOException("Animation ZIP entry extends outside its directory.");
                in.seek(localOffset);byte[] local=new byte[30];in.readFully(local);int localName=u16(local,26),localExtra=u16(local,28);
                if(u32(local,0)!=0x04034b50L||u16(local,6)!=flags||u16(local,8)!=method||localName!=nameLength||localOffset+30+localName+localExtra+compressed>offset)throw new IOException("Conflicting animation ZIP entry header.");
                byte[] actualName=new byte[localName];in.readFully(actualName);if(!Arrays.equals(name,actualName))throw new IOException("Conflicting animation ZIP resource path.");
                in.seek(next);
            }
            if(in.getFilePointer()!=offset+bytes)throw new IOException("Invalid animation ZIP entry count.");
        }
    }
    private static int u16(byte[] bytes,int offset){return(bytes[offset]&255)|((bytes[offset+1]&255)<<8);}
    private static long u32(byte[] bytes,int offset){return u16(bytes,offset)|((long)u16(bytes,offset+2)<<16);}

    static JSONObject importFile(File root,File archive)throws Exception {
        if(!archive.isFile()||archive.length()>MAX_ARCHIVE)throw new IOException("Choose an animation ZIP up to80MiB.");directory(archive);
        File assets=new File(root,"assets");
        if(PublicStorage.isLink(root)||PublicStorage.isLink(assets))throw new IOException("Animation resources must use private app storage.");
        if(!assets.isDirectory()&&!assets.mkdirs())throw new IOException("Could not prepare animation resources.");
        String token=UUID.randomUUID().toString(),group="import-"+token;File target=new File(assets,group),stage=new File(assets,".animation-import-"+token);
        boolean committed=false,leased=false;
        try(ZipFile zip=new ZipFile(archive)){
            ZipEntry manifest=zip.getEntry("animation.json");if(manifest==null||manifest.getSize()<1||manifest.getSize()>MAX_DOCUMENT)throw new IOException("Animation backup metadata is missing or exceeds8MiB.");
            ByteArrayOutputStream text=new ByteArrayOutputStream();CRC32 manifestCrc=new CRC32();long manifestBytes;
            try(InputStream in=new CheckedInputStream(zip.getInputStream(manifest),manifestCrc)){manifestBytes=copy(in,text,MAX_DOCUMENT,null);}
            if(manifestBytes!=manifest.getSize()||manifestCrc.getValue()!=manifest.getCrc())throw new IOException("Animation metadata failed its size or CRC check.");
            JSONObject backup=new JSONObject(new String(text.toByteArray(),StandardCharsets.UTF_8)),document=backup.getJSONObject("document");
            if(!"dokkan-animation-backup".equals(backup.optString("format"))||backup.optInt("version")!=1||!"dokkan-animation-gallery".equals(document.optString("format"))||document.optInt("version")!=1||document.optJSONArray("assets")==null)throw new IOException("This is not a supported animation backup.");
            JSONArray resources=backup.getJSONArray("resources");if(resources.length()>256||zip.size()!=resources.length()+1)throw new IOException("Animation backup contains unlisted resources.");
            JSONObject mapping=new JSONObject();long total=0;Set<String> listed=new HashSet<String>();
            for(int i=0;i<resources.length();i++){
                JSONObject item=resources.getJSONObject(i);String path=item.getString("path"),sha=item.getString("sha256");Object size=item.get("bytes");
                if(!resourcePath(path)||!listed.add(path)||!sha.matches("[a-f0-9]{64}")||!(size instanceof Integer||size instanceof Long))throw new IOException("Invalid animation resource metadata.");
                long bytes=((Number)size).longValue();if(bytes<1||bytes>MAX_RESOURCES||(total+=bytes)>MAX_RESOURCES)throw new IOException("Animation resources exceed64MiB.");
                ZipEntry entry=zip.getEntry(path);if(entry==null||entry.isDirectory()||entry.getSize()!=bytes)throw new IOException("An animation resource is missing or has the wrong size.");
                mapping.put(path,group+"/"+path.substring("resources/".length()));
            }
            JSONArray attached=document.getJSONArray("assets");for(int i=0;i<attached.length();i++)if(!listed.contains(attached.getJSONObject(i).optString("key")))throw new IOException("An attached animation resource is not in this backup.");
            AnimationImportLeases.begin(root,token,mapping);leased=true;
            if(!stage.mkdir())throw new IOException("Could not stage the animation import.");
            for(int i=0;i<resources.length();i++){
                JSONObject item=resources.getJSONObject(i);String path=item.getString("path"),sha=item.getString("sha256"),name=path.substring("resources/".length());long bytes=item.getLong("bytes");ZipEntry entry=zip.getEntry(path);
                File destination=new File(stage,name);MessageDigest digest=MessageDigest.getInstance("SHA-256");CRC32 crc=new CRC32();long written;
                try(InputStream in=new CheckedInputStream(zip.getInputStream(entry),crc);FileOutputStream out=new FileOutputStream(destination)){written=copy(in,out,bytes,digest);out.getFD().sync();}
                if(written!=bytes||crc.getValue()!=entry.getCrc()||!sha.equals(hex(digest.digest())))throw new IOException("An animation resource failed its size or checksum check.");
            }
            Files.move(stage.toPath(),target.toPath());committed=true;
            return new JSONObject().put("document",document).put("resources",mapping).put("importToken",token);
        }finally{if(!committed){if(leased)AnimationImportLeases.dispatch(root,new JSONObject().put("action","discard").put("token",token));else PublicStorage.removeTree(stage.toPath());}}
    }
}
