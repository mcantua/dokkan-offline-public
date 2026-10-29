"""One Android-helper/JVM/JNI staging scenario; no APK or device/SAF claim.
Android API compilation is real. Tiny Context/URI/provider/descriptor facades
are test inputs only; the unchanged Java helper and C extractor perform the I/O.
"""
import argparse,hashlib,pathlib,subprocess,tempfile,zipfile
HERE=pathlib.Path(__file__).resolve().parent;REPO=HERE.parents[2]
parser=argparse.ArgumentParser();parser.add_argument('eclipse_zip',type=pathlib.Path);parser.add_argument('raw_database',type=pathlib.Path);args=parser.parse_args()
with tempfile.TemporaryDirectory(prefix='od-android-master-input-') as directory:
 work=pathlib.Path(directory);classes=work/'classes';classes.mkdir()
 java=REPO/'unit-creator/tools/javac';platform=REPO/'downloads/android-sdk/platforms/android-35/android.jar'
 utility=HERE/'com/personal/offlinedokkan/OfflineMasterArchive.java'
 subprocess.run([str(java),'--release','8','-Xlint:-options','-cp',str(platform),'-d',str(classes),str(utility)],check=True)
 sources={
 'android/net/Uri.java':'''package android.net; public final class Uri {private final java.net.URI value;private Uri(String s){value=java.net.URI.create(s);}public static Uri parse(String s){return new Uri(s);}public String getScheme(){return value.getScheme();}public String getAuthority(){return value.getAuthority();}public String toString(){return value.toString();}}''',
 'android/content/ContentResolver.java':'''package android.content; public abstract class ContentResolver {public abstract java.io.InputStream openInputStream(android.net.Uri u)throws java.io.IOException;}''',
 'android/content/Context.java':'''package android.content;public final class Context {private final java.io.File cache;private final ContentResolver resolver;public Context(java.io.File c,ContentResolver r){cache=c;resolver=r;}public java.io.File getCacheDir(){return cache;}public ContentResolver getContentResolver(){return resolver;}}''',
 'android/os/ParcelFileDescriptor.java':'''package android.os;public final class ParcelFileDescriptor implements java.io.Closeable {private final java.io.FileDescriptor descriptor;private ParcelFileDescriptor(java.io.FileDescriptor f){descriptor=f;}public static ParcelFileDescriptor dup(java.io.FileDescriptor f){return new ParcelFileDescriptor(f);}public int getFd(){try{java.lang.reflect.Field f=java.io.FileDescriptor.class.getDeclaredField("fd");f.setAccessible(true);return f.getInt(descriptor);}catch(Exception e){throw new AssertionError(e);}}public void close(){/* Borrowed only in this JVM facade. Real Android dup owns its duplicate. */}}''',
 'com/personal/offlinedokkan/MasterInputScenario.java':r'''package com.personal.offlinedokkan;
import android.content.*;import android.net.Uri;import java.io.*;import java.nio.file.*;import java.security.*;import java.util.*;
public final class MasterInputScenario {
 static final Map<String,File> files=new HashMap<>();static boolean broken;static int opened;
 static String hash(File file)throws Exception{MessageDigest d=MessageDigest.getInstance("SHA-256");try(InputStream in=new FileInputStream(file)){byte[] b=new byte[65536];int n;while((n=in.read(b))!=-1)d.update(b,0,n);}StringBuilder h=new StringBuilder();for(byte b:d.digest())h.append(String.format("%02x",b&255));return h.toString();}
 static void ok(String name,boolean value){if(!value)throw new AssertionError(name);System.out.println("PASS "+name);}
 static boolean empty(File cache){File root=new File(cache,"master-imports");return !root.exists()||root.list().length==0;}
 public static void main(String[]a)throws Exception{
  File root=new File(a[0]),cache=new File(root,"cache");cache.mkdirs();File archive=new File(a[1]),raw=new File(a[2]);String archiveHash=hash(archive),rawHash=hash(raw);
  files.put("content://approved/archive",archive);files.put("content://approved/../../../personal.db",raw);files.put("content://approved/corrupt",new File(a[3]));
  ContentResolver resolver=new ContentResolver(){public InputStream openInputStream(Uri uri)throws IOException{opened++;if(broken)return new InputStream(){int at;public int read()throws IOException{if(at++<16)return "SQLite format 3\000".charAt(at-1);throw new IOException("FIXTURE_PROVIDER_FAILED");}};File f=files.get(uri.toString());if(f==null)throw new IOException("NO_FIXTURE");return new FileInputStream(f);}};
  Context context=new Context(cache,resolver);
  try(OfflineMasterArchive.Stage stage=OfflineMasterArchive.stage(context,Uri.parse("content://approved/archive"),"eclipse")){ok("actual Java URI staging and JNI extraction produce supplied master SHA",hash(stage.database()).equals(a[4])&&stage.database().getCanonicalPath().startsWith(cache.getCanonicalPath()+File.separator));}
  ok("archive source copy and extracted temporary DB removed after success",empty(cache)&&hash(archive).equals(archiveHash));
  try(OfflineMasterArchive.Stage stage=OfflineMasterArchive.stage(context,Uri.parse("content://approved/../../../personal.db"),"eclipse")){ok("standalone SQLite passes through privately without using provider URI as a path",hash(stage.database()).equals(rawHash)&&!new File(root,"personal.db").exists());}
  ok("standalone SQLite staging removed and selected source unchanged",empty(cache)&&hash(raw).equals(rawHash));
  for(String[] entry:new String[][]{{"content://approved/corrupt","eclipse"},{"content://approved/archive","sparking"}}){boolean failed=false;try(OfflineMasterArchive.Stage ignored=OfflineMasterArchive.stage(context,Uri.parse(entry[0]),entry[1])){}catch(IOException expected){failed=true;}ok("failed archive or wrong game removes all temporary inputs/outputs",failed&&empty(cache));}
  int before=opened;boolean refused=false;try{OfflineMasterArchive.stage(context,Uri.parse("file:///private/personal.db"),"eclipse");}catch(IOException expected){refused=true;}ok("non-picker URI rejected before reading or staging",refused&&opened==before&&empty(cache));
  broken=true;refused=false;try{OfflineMasterArchive.stage(context,Uri.parse("content://approved/archive"),"eclipse");}catch(IOException expected){refused=true;}ok("interrupted provider copy leaves no source/output stage",refused&&empty(cache));broken=false;
  File outside=new File(root,"outside");outside.mkdir();Files.delete(new File(cache,"master-imports").toPath());Files.createSymbolicLink(new File(cache,"master-imports").toPath(),outside.toPath());refused=false;try{OfflineMasterArchive.stage(context,Uri.parse("content://approved/archive"),"eclipse");}catch(IOException expected){refused=true;}ok("symlinked staging root rejected without touching outside directory",refused&&outside.list().length==0);
 }
}'''
 }
 paths=[]
 for relative,text in sources.items():
  file=work/relative;file.parent.mkdir(parents=True,exist_ok=True);file.write_text(text);paths.append(str(file))
 subprocess.run([str(java),'--release','8','-Xlint:-options','-d',str(classes),*paths,str(utility)],check=True)
 include=REPO/'downloads/unit-creator-tools/jdk/usr/lib/jvm/java-21-openjdk-amd64/include'
 subprocess.run(['cc','-std=c11','-Wall','-Wextra','-Werror','-fPIC','-fvisibility=hidden','-shared','-I'+str(include),'-I'+str(include/'linux'),str(HERE/'master_archive_jni.c'),str(REPO/'offline-dokkan/content/master_archive.c'),'-lz','-Wl,--no-undefined','-o',str(work/'libodbridge.so')],check=True)
 # Compile-only against public Android API26 headers/ABI; no library/package build.
 compiler=REPO/'downloads/android-sdk/ndk/android-ndk-r28b/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android26-clang'
 subprocess.run([str(compiler),'-std=c11','-Wall','-Wextra','-Werror','-fsyntax-only',str(HERE/'master_archive_jni.c'),str(REPO/'offline-dokkan/content/master_archive.c')],check=True)
 with zipfile.ZipFile(args.eclipse_zip) as z:
  selected=next(n for n in z.namelist() if n in {'reference.db','assets/reference.db'});digest=hashlib.sha256()
  with z.open(selected) as f:
   for chunk in iter(lambda:f.read(65536),b''):digest.update(chunk)
 bad=work/'corrupt.zip'
 with zipfile.ZipFile(bad,'w',zipfile.ZIP_STORED) as z:z.writestr('assets/reference.db',b'SQLite format 3\x00'+b'X'*100)
 data=bytearray(bad.read_bytes());data[50]^=1;bad.write_bytes(data)
 subprocess.run(['java','--add-opens=java.base/java.io=ALL-UNNAMED','-Djava.library.path='+str(work),'-cp',str(classes),'com.personal.offlinedokkan.MasterInputScenario',str(work),str(args.eclipse_zip),str(args.raw_database),str(bad),digest.hexdigest()],check=True)
 print('Android API/JNI compile and focused staging checks passed; no APK/Android device run.',flush=True)
