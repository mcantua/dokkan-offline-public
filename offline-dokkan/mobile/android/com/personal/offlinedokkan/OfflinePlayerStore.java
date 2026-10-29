package com.personal.offlinedokkan;

import android.content.Context;
import android.content.SharedPreferences;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.MessageDigest;

/** One player/workspace. Eclipse/Sparking identify imported content, never separate players. */
final class OfflinePlayerStore {
    static { System.loadLibrary("odbridge"); }
    private static final String[] SOURCES={"eclipse","sparking"};
    static final class Selection {
        final File directory,master;
        final String source,hash;
        Selection(File directory,String source,String hash){this.directory=directory;this.source=source;this.hash=hash;master=new File(directory,"master-"+hash+".db");}
    }
    private OfflinePlayerStore(){}
    private static SharedPreferences preferences(Context context){return context.getSharedPreferences("offline-dokkan-content",Context.MODE_PRIVATE);}
    static boolean validSource(String source){return "eclipse".equals(source)||"sparking".equals(source);}
    static File directory(Context context)throws IOException {
        File root=new File(context.getFilesDir(),"offline-dokkan");
        if(!root.isDirectory()&&!root.mkdirs())throw new IOException("STORAGE_UNAVAILABLE");
        return new File(root,"local-player");
    }
    private static Selection selection(File directory,String source,String hash)throws IOException {
        if(!validSource(source)||hash==null||!hash.matches("[a-f0-9]{64}"))throw new IOException("LEGACY_SAVE_RECOVERY_REQUIRED");
        Selection selected=new Selection(directory,source,hash);
        if(!selected.master.isFile())throw new IOException("MASTER_REQUIRED");
        return selected;
    }
    static synchronized Selection active(Context context)throws IOException {
        File canonical=directory(context);SharedPreferences prefs=preferences(context);
        String source=prefs.getString("active.source",""),hash=prefs.getString("active.sha256","");
        if(validSource(source)&&hash.matches("[a-f0-9]{64}"))return selection(canonical,source,hash);
        File receipt=new File(canonical,".source");
        if(receipt.isFile()){
            if(receipt.length()>128)throw new IOException("LEGACY_SAVE_RECOVERY_REQUIRED");
            String[] fields=new String(Files.readAllBytes(receipt.toPath()),StandardCharsets.US_ASCII).split("\n");
            if(fields.length!=2)throw new IOException("LEGACY_SAVE_RECOVERY_REQUIRED");
            Selection recovered=selection(canonical,fields[0],fields[1]);activate(context,recovered);return recovered;
        }
        if(new File(canonical,"player.db").exists()||new File(canonical,"creator-workspace.db").exists())throw new IOException("LEGACY_SAVE_RECOVERY_REQUIRED");
        Selection legacy=null;
        for(String candidate:SOURCES){
            File directory=new File(canonical.getParentFile(),candidate);
            if(!new File(directory,"player.db").exists()&&!new File(directory,"creator-workspace.db").exists())continue;
            if(legacy!=null)throw new IOException("LEGACY_SAVE_SELECTION_REQUIRED");
            legacy=selection(directory,candidate,prefs.getString(candidate+".sha256",""));
        }
        if(legacy==null)return null;
        // Never raw-copy a live SQLite/WAL pair. Read-only SQLite backup creates
        // one consistent candidate while all old development directories remain.
        File stage=Files.createTempDirectory(canonical.getParentFile().toPath(),".adopt-").toFile();
        boolean published=false;
        try{
            File master=new File(stage,legacy.master.getName());
            try(FileInputStream input=new FileInputStream(legacy.master);FileOutputStream output=new FileOutputStream(master)){
                byte[] bytes=new byte[65536];int count;MessageDigest digest;
                try{digest=MessageDigest.getInstance("SHA-256");}catch(Exception error){throw new IOException("STORAGE_UNAVAILABLE",error);}
                while((count=input.read(bytes))!=-1){output.write(bytes,0,count);digest.update(bytes,0,count);}output.getFD().sync();
                StringBuilder hex=new StringBuilder();for(byte value:digest.digest())hex.append(String.format(java.util.Locale.ROOT,"%02x",value&255));
                if(!legacy.hash.equals(hex.toString()))throw new IOException("LEGACY_SAVE_RECOVERY_REQUIRED");
            }
            for(String name:new String[]{"player.db","creator-workspace.db"}){
                File old=new File(legacy.directory,name);if(old.isFile())snapshot(old.getPath(),new File(stage,name).getPath(),name.equals("player.db")?"sha256:"+legacy.hash:null);
            }
            writeReceipt(stage,legacy.source,legacy.hash);
            if(canonical.exists()){
                String[] entries=canonical.list();if(entries==null||entries.length!=0||!canonical.delete())throw new IOException("LEGACY_SAVE_RECOVERY_REQUIRED");
            }
            if(!stage.renameTo(canonical))throw new IOException("STORAGE_UNAVAILABLE");
            published=true;Selection adopted=selection(canonical,legacy.source,legacy.hash);activate(context,adopted);return adopted;
        }finally{
            if(!published){File[] files=stage.listFiles();if(files!=null)for(File file:files)if(file.isFile())Files.deleteIfExists(file.toPath());Files.deleteIfExists(stage.toPath());}
        }
    }
    static void writeReceipt(File directory,String source,String hash)throws IOException {
        if(!validSource(source)||!hash.matches("[a-f0-9]{64}"))throw new IOException("INVALID_CONTENT_SOURCE");
        try(FileOutputStream output=new FileOutputStream(new File(directory,".source"))){output.write((source+"\n"+hash+"\n").getBytes(StandardCharsets.US_ASCII));output.getFD().sync();}
    }
    static synchronized void activate(Context context,Selection selection)throws IOException {
        if(!preferences(context).edit().putString("active.source",selection.source).putString("active.sha256",selection.hash).commit())throw new IOException("STORAGE_UNAVAILABLE");
    }
    private static native void snapshot(String source,String destination,String expectedContent)throws IOException;
}
