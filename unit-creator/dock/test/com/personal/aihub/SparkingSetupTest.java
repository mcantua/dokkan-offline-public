package com.personal.aihub;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.zip.*;

/** Synthetic data only: does not contain game libraries or real format material. */
public final class SparkingSetupTest {
    static int checks;
    interface Action { void run() throws Exception; }
    static void ok(String label,boolean value) { if(!value)throw new AssertionError(label);checks++;System.out.println("PASS "+label); }
    static boolean rejects(Action action) throws Exception { try{action.run();return false;}catch(IOException expected){return true;} }
    public static void main(String[] args) throws Exception {
        Path root=Files.createTempDirectory("dokkan-sparking-setup-");
        try {
            SparkingSetup.Version old=SparkingSetup.version("9d3f2749e391d990496b632b6adc135492f71e0baec7125d7b613a56e771dca0");
            SparkingSetup.Version current=SparkingSetup.version("83c0b40f49ae0edb0c91650ff36eb97a528db2c14627333f7023c3a13e0018d4");
            ok("both pinned versions select distinct validated layouts",old.name.equals("6.5.5")&&current.name.equals("6.6")&&old.patch!=current.patch&&old.database!=current.database);
            ok("unknown native library fingerprint is refused",rejects(()->SparkingSetup.version("0")));
            for(SparkingSetup.Version version:new SparkingSetup.Version[]{old,current}) {
                byte[] bytes=new byte[700000];Arrays.fill(bytes,version.database,version.database+64,(byte)'a');
                Arrays.fill(bytes,version.patch,version.patch+16,(byte)0x5a);
                byte[] key=SparkingSetup.patchKey(bytes,version);
                ok(version.name+" extraction uses correct offsets and zero padding",key.length==32&&key[0]==0x5a&&key[15]==0x5a&&key[16]==0&&key[31]==0&&SparkingSetup.databaseKey(bytes,version).equals(String.join("",Collections.nCopies(64,"a"))));
                bytes[version.database+64]=1;
                ok(version.name+" rejects unterminated database field",rejects(()->SparkingSetup.databaseKey(bytes,version)));
            }
            File apk=root.resolve("synthetic.apk").toFile();
            try(ZipOutputStream zip=new ZipOutputStream(new FileOutputStream(apk))){zip.putNextEntry(new ZipEntry("lib/arm64-v8a/libbase.so"));zip.write(new byte[700000]);zip.closeEntry();}
            ok("public APK entry points refuse synthetic unpinned library",rejects(()->SparkingSetup.keyFromApk(apk))&&rejects(()->SparkingSetup.databaseKeyFromApk(apk)));
            try(ZipOutputStream zip=new ZipOutputStream(new FileOutputStream(apk))){zip.putNextEntry(new ZipEntry("lib/arm64-v8a/libbase.so"));zip.write(new byte[10]);zip.closeEntry();}
            ok("undersized library is refused",rejects(()->SparkingSetup.keyFromApk(apk)));
            File source=root.resolve("source.eclp").toFile(),dest=root.resolve("unit.eclp").toFile();
            Files.write(source.toPath(),new byte[]{1,2,3});Files.write(dest.toPath(),new byte[]{9});
            SendToGame.copy(source,dest);
            ok("complete export replaces previous bytes",Arrays.equals(Files.readAllBytes(dest.toPath()),new byte[]{1,2,3}));
            File blocking=root.resolve("blocked.eclp").toFile();blocking.mkdir();Files.write(blocking.toPath().resolve("personal.txt"),new byte[]{8});
            ok("failed replacement preserves unrelated destination content",rejects(()->SendToGame.copy(source,blocking))&&Files.readAllBytes(blocking.toPath().resolve("personal.txt"))[0]==8);
            byte[] dummy=new byte[32]; // Entirely synthetic encryption fixture, never a game key.
            File sprk=root.resolve("unit.sprk").toFile();SendToGame.encrypt(source,sprk,dummy);byte[] first=Files.readAllBytes(sprk.toPath());
            SendToGame.encrypt(source,sprk,dummy);
            ok("unchanged Sparking export stays byte-identical",Arrays.equals(first,Files.readAllBytes(sprk.toPath()))&&first[0]=='S'&&first[4]==1);
            ok("failed encryption does not delete previous file",rejects(()->SendToGame.encrypt(root.resolve("missing.zip").toFile(),sprk,dummy))&&Arrays.equals(first,Files.readAllBytes(sprk.toPath())));
            try(java.util.stream.Stream<Path> paths=Files.list(root)){ok("no export staging files remain",!paths.anyMatch(p->p.getFileName().toString().startsWith(".dokkan-send-")));}
            System.out.println(checks+" focused Sparking setup/export checks passed; real 6.6 APK/game acceptance still requires user-provided inputs.");
        } finally { PublicStorage.removeTree(root); }
    }
}
