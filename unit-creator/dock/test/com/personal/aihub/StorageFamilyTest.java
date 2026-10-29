package com.personal.aihub;

import java.io.*;
import java.nio.file.*;
import java.lang.reflect.Field;

/** Only the new development/release isolation boundary; does not rerun storage lifecycle coverage. */
public final class StorageFamilyTest {
    static int checks;
    static void ok(String label,boolean condition){if(!condition)throw new AssertionError(label);checks++;System.out.println("PASS "+label);}
    static void start(File root,File downloads,boolean development,boolean permission)throws Exception{
        PublicStorage.resetForTest();Field flavor=PublicStorage.class.getDeclaredField("development");flavor.setAccessible(true);flavor.setBoolean(null,development);
        PublicStorage.allFilesForTest=permission;PublicStorage.prepare(root,downloads,34);PublicStorage.awaitMove(10000);
    }
    public static void main(String[]args)throws Exception{
        Path temp=Files.createTempDirectory("dokkan-storage-family-");
        try{
            File downloads=temp.resolve("Download").toFile();downloads.mkdirs();File release=temp.resolve("release/forge").toFile();start(release,downloads,false,true);
            File normal=PublicStorage.folder(),marker=new File(normal,".dokkan-unit-creator");byte[] identity=Files.readAllBytes(marker.toPath());
            File personal=new File(normal,"Game files/personal.txt");Files.write(personal.toPath(),new byte[]{1,2,3});
            File dev=temp.resolve("development/forge").toFile();start(dev,downloads,true,true);File separate=PublicStorage.folder();
            ok("development package uses its own named shared folder",separate.getName().equals(PublicStorage.NAME+" Development")&&!separate.equals(normal));
            ok("development ownership marker cannot authorize release-folder adoption",new File(separate,".dokkan-unit-creator-development").isFile()&&!PublicStorage.isAppFolder(normal)&&PublicStorage.otherAppFolders().isEmpty());
            PublicStorage.tidy(dev,null,null,null,null);PublicStorage.clear(dev,"preview-cache");
            ok("development cleanup leaves release marker and personal bytes intact",java.util.Arrays.equals(identity,Files.readAllBytes(marker.toPath()))&&java.util.Arrays.equals(new byte[]{1,2,3},Files.readAllBytes(personal.toPath())));
            start(temp.resolve("development-reinstall/forge").toFile(),downloads,true,false);
            ok("development reinstall still requires its own fresh grant",PublicStorage.folder()==null);
            PublicStorage.allFilesForTest=true;PublicStorage.check();PublicStorage.awaitMove(10000);
            ok("development regrant adopts only development folder",PublicStorage.folder().equals(separate)&&java.util.Arrays.equals(identity,Files.readAllBytes(marker.toPath())));
            start(release,downloads,false,true);
            ok("release startup never adopts development folder",PublicStorage.folder().equals(normal)&&!PublicStorage.isAppFolder(separate)&&PublicStorage.otherAppFolders().isEmpty());
            System.out.println(checks+" development/release storage isolation assertions passed.");
        }finally{PublicStorage.resetForTest();PublicStorage.removeTree(temp);}
    }
}
