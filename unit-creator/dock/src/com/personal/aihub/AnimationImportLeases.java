package com.personal.aihub;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import org.json.*;

/** Fresh-import leases only. No arbitrary asset path can be deleted through this bridge. */
final class AnimationImportLeases {
    private static final String TOKEN="[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}";
    private AnimationImportLeases(){}
    private static File directory(File root)throws Exception{
        if(PublicStorage.isLink(root))throw new IOException("Unsafe animation import root.");
        File dir=new File(root,"animation-import-leases");if(PublicStorage.isLink(dir))throw new IOException("Unsafe animation import journal.");
        if(!dir.isDirectory()&&!dir.mkdirs())throw new IOException("Could not preserve the animation import journal.");return dir;
    }
    private static File journal(File root,String token)throws Exception{
        if(!token.matches(TOKEN))throw new IOException("Invalid animation import token.");File file=new File(directory(root),token+".json");if(PublicStorage.isLink(file))throw new IOException("Unsafe animation import journal.");return file;
    }
    static void begin(File root,String token,JSONObject resources)throws Exception{
        if(directory(root).list().length>=64)throw new IOException("Finish the pending animation imports before importing another backup.");
        File file=journal(root,token);if(file.exists())throw new IOException("Animation import token already exists.");
        JSONArray keys=new JSONArray();Iterator<String> paths=resources.keys();while(paths.hasNext())keys.put(resources.getString(paths.next()));
        JSONObject lease=new JSONObject().put("version",1).put("token",token).put("resources",keys);
        File part=Files.createTempFile(directory(root).toPath(),".lease-",".tmp").toFile();
        try{
            try(FileOutputStream out=new FileOutputStream(part)){out.write(lease.toString().getBytes(StandardCharsets.UTF_8));out.getFD().sync();}
            try{Files.move(part.toPath(),file.toPath(),StandardCopyOption.ATOMIC_MOVE);}
            catch(AtomicMoveNotSupportedException unsupported){Files.move(part.toPath(),file.toPath());}
        }finally{part.delete();}
    }
    private static JSONObject read(File root,String token)throws Exception{
        File file=journal(root,token);if(!file.isFile()||file.length()>128*1024)throw new IOException("Animation import journal is missing or invalid.");
        JSONObject lease=new JSONObject(new String(Files.readAllBytes(file.toPath()),StandardCharsets.UTF_8));JSONArray keys=lease.getJSONArray("resources");
        if(lease.optInt("version")!=1||!token.equals(lease.optString("token"))||keys.length()>256)throw new IOException("Invalid animation import journal.");
        for(int i=0;i<keys.length();i++)if(!keys.getString(i).matches("import-"+token+"/[1-9][0-9]{0,2}\\.[a-z0-9]{1,8}"))throw new IOException("Animation import journal contains an unsafe key.");
        return lease;
    }
    static synchronized Object dispatch(File root,JSONObject args)throws Exception{
        String action=args.optString("action","pending");
        if("pending".equals(action)){
            JSONArray leases=new JSONArray();File[] files=directory(root).listFiles();if(files==null)throw new IOException("Could not read pending animation imports.");
            for(File file:files)if(file.getName().matches(TOKEN+"\\.json"))leases.put(read(root,file.getName().substring(0,36)));
            return leases;
        }
        String token=args.getString("token");read(root,token);
        if("commit".equals(action)){if(!journal(root,token).delete())throw new IOException("Could not finish the animation import journal.");return new JSONObject().put("committed",true);}
        if(!"discard".equals(action))throw new IOException("Unknown animation import lease action.");
        long[] budget={512L*1024*1024,50000};
        if(referenced(new File(root,"projects"),"import-"+token,budget)||referenced(new File(root,"project-versions"),"import-"+token,budget)){
            if(!journal(root,token).delete())throw new IOException("Could not finish the referenced animation import.");
            return new JSONObject().put("discarded",false).put("committed",true).put("referenced",true);
        }
        JSONObject lease=read(root,token);JSONArray keys=lease.getJSONArray("resources");Set<String> names=new HashSet<String>();for(int i=0;i<keys.length();i++)names.add(new File(keys.getString(i)).getName());
        File assets=new File(root,"assets");if(PublicStorage.isLink(assets))throw new IOException("Animation resources cannot be symbolic links.");
        for(String name:new String[]{"import-"+token,".animation-import-"+token}){
            File group=new File(assets,name);if(!group.exists())continue;if(PublicStorage.isLink(group)||!group.isDirectory())throw new IOException("Unsafe pending animation import folder.");
            File[] children=group.listFiles();if(children==null)throw new IOException("Could not check pending animation resources.");
            for(File child:children)if(!child.isFile()||PublicStorage.isLink(child)||!names.contains(child.getName()))throw new IOException("The pending animation folder contains other files; they were kept.");
            for(File child:children)if(!child.delete())throw new IOException("Could not discard a pending animation resource.");
            if(!group.delete())throw new IOException("Could not discard the empty animation import folder.");
        }
        if(!journal(root,token).delete())throw new IOException("Could not finish the discarded animation import journal.");
        return new JSONObject().put("discarded",true);
    }
    private static boolean referenced(File path,String token,long[] budget)throws Exception{
        if(!path.exists())return false;if(PublicStorage.isLink(path))throw new IOException("A unit reference could not be checked safely; pending resources were kept.");
        if(path.isDirectory()){
            File[] files=path.listFiles();if(files==null)throw new IOException("Saved unit references could not be checked; pending resources were kept.");
            for(File file:files)if(file.isDirectory()||file.getName().endsWith(".json")||file.getName().endsWith(".version"))if(referenced(file,token,budget))return true;
            return false;
        }
        if(--budget[1]<0||(budget[0]-=path.length())<0)throw new IOException("Saved unit reference checks exceed this import's limit; pending resources were kept.");
        byte[] needle=token.getBytes(StandardCharsets.UTF_8),buffer=new byte[65536];int matched=0;
        try(InputStream in=new FileInputStream(path)){int n;while((n=in.read(buffer))!=-1)for(int i=0;i<n;i++){if(buffer[i]==needle[matched]){if(++matched==needle.length)return true;}else matched=buffer[i]==needle[0]?1:0;}}
        return false;
    }
}
