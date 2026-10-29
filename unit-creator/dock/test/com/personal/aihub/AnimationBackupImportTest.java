package com.personal.aihub;
import java.io.*;
import java.nio.file.*;
import org.json.*;
/** Reads the actual ZIP produced by the gallery frontend; no game bytes or keys in this fixture. */
public final class AnimationBackupImportTest {
    static int checks;
    static void ok(String label,boolean condition){if(!condition)throw new AssertionError(label);checks++;System.out.println("PASS "+label);}
    public static void main(String[]args)throws Exception{
        Path temporary=Files.createTempDirectory("dokkan-animation-import-");
        try{
            File root=temporary.resolve("forge").toFile();new File(root,"projects").mkdirs();Files.write(new File(root,"projects/unit.json").toPath(),new byte[]{9});
            JSONObject first=AnimationBackupImport.importFile(root,new File(args[0]));JSONObject map=first.getJSONObject("resources");String key=map.getString("resources/1.mp3");
            ok("Android imports real gallery ZIP resource bytes",new File(root,"assets/"+key).isFile()&&first.getJSONObject("document").getString("format").equals("dokkan-animation-gallery"));
            JSONObject second=AnimationBackupImport.importFile(root,new File(args[0]));ok("repeat import reserves a fresh resource collection",!key.equals(second.getJSONObject("resources").getString("resources/1.mp3")));
            int before=new File(root,"assets").list().length;
            for(int i=1;i<args.length-1;i++){boolean failed=false;try{AnimationBackupImport.importFile(root,new File(args[i]));}catch(Exception expected){failed=true;}ok("invalid archive "+i+" rejects without committing resources",failed&&new File(root,"assets").list().length==before);}
            ok("gallery import preserves existing unit bytes",Files.readAllBytes(new File(root,"projects/unit.json").toPath())[0]==9);
            try(java.util.stream.Stream<Path> files=Files.walk(root.toPath())){ok("no failed import staging remains",!files.anyMatch(p->p.getFileName().toString().startsWith(".animation-import-")));}
            Files.write(Paths.get(args[args.length-1]),first.toString().getBytes("UTF-8"));
            JSONArray pending=(JSONArray)AnimationImportLeases.dispatch(root,new JSONObject().put("action","pending"));
            ok("fresh imports leave durable journal entries until gallery save",pending.length()==2);
            AnimationImportLeases.dispatch(root,new JSONObject().put("action","discard").put("token",first.getString("importToken")));
            ok("quota-style discard removes only its fresh unreferenced group",!new File(root,"assets/"+key).exists()&&new File(root,"assets/"+second.getJSONObject("resources").getString("resources/1.mp3")).isFile());
            String secondKey=second.getJSONObject("resources").getString("resources/1.mp3");Files.write(new File(root,"projects/pinned.json").toPath(),new JSONObject().put("assetKey",secondKey).toString().getBytes("UTF-8"));
            JSONObject protectedResult=(JSONObject)AnimationImportLeases.dispatch(root,new JSONObject().put("action","discard").put("token",second.getString("importToken")));
            ok("saved unit reference converts discard into safe commit",protectedResult.optBoolean("referenced")&&new File(root,"assets/"+secondKey).isFile());
            JSONObject versioned=AnimationBackupImport.importFile(root,new File(args[0]));File version=new File(root,"project-versions/unit/fixture.version");version.getParentFile().mkdirs();Files.write(version.toPath(),("VERSION-HEADER\n"+versioned.getJSONObject("resources").getString("resources/1.mp3")).getBytes("UTF-8"));
            JSONObject kept=(JSONObject)AnimationImportLeases.dispatch(root,new JSONObject().put("action","discard").put("token",versioned.getString("importToken")));
            ok("saved version protects its imported resources",kept.optBoolean("referenced"));
            String crash=java.util.UUID.randomUUID().toString(),crashKey="import-"+crash+"/1.mp3";AnimationImportLeases.begin(root,crash,new JSONObject().put("resources/1.mp3",crashKey));File stage=new File(root,"assets/.animation-import-"+crash);stage.mkdir();Files.write(new File(stage,"1.mp3").toPath(),new byte[]{1});
            ok("restart-style lookup discovers interrupted staged import",((JSONArray)AnimationImportLeases.dispatch(root,new JSONObject().put("action","pending"))).length()==1);
            AnimationImportLeases.dispatch(root,new JSONObject().put("action","discard").put("token",crash));
            ok("recovery discards only known interrupted staging",!stage.exists()&&((JSONArray)AnimationImportLeases.dispatch(root,new JSONObject().put("action","pending"))).length()==0);
            JSONObject committed=AnimationBackupImport.importFile(root,new File(args[0]));AnimationImportLeases.dispatch(root,new JSONObject().put("action","commit").put("token",committed.getString("importToken")));
            ok("successful gallery commit clears journal and keeps bytes",new File(root,"assets/"+committed.getJSONObject("resources").getString("resources/1.mp3")).isFile()&&((JSONArray)AnimationImportLeases.dispatch(root,new JSONObject().put("action","pending"))).length()==0);
            System.out.println(checks+" Android gallery ZIP assertions passed; physical picker remains unverified.");
        }finally{PublicStorage.removeTree(temporary);}
    }
}
