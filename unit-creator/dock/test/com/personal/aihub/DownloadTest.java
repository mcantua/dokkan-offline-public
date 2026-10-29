package com.personal.aihub;

import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.util.*;
import org.json.JSONObject;

/** One focused downloader integrity/reuse check. Every HTTPS response is a local byte fixture. */
public class DownloadTest {
    static int checks, requests;
    static void ok(String name, boolean value) { checks++; if(!value)throw new AssertionError(name); System.out.println("PASS "+name); }
    static void write(File f, byte[] value)throws Exception{f.getParentFile().mkdirs();try(FileOutputStream o=new FileOutputStream(f)){o.write(value);}}
    static JSONObject metadata(File f)throws Exception{return new JSONObject(new String(Files.readAllBytes(f.toPath()),"UTF-8"));}
    public static void main(String[] args)throws Exception{
        final byte[] fixture=new byte[12345];Arrays.fill(fixture,(byte)7);
        URL.setURLStreamHandlerFactory(protocol->"https".equals(protocol)?new URLStreamHandler(){
            protected URLConnection openConnection(final URL url){
                requests++;
                return new HttpURLConnection(url){
                    public int getResponseCode(){return 200;}
                    public long getContentLengthLong(){return fixture.length;}
                    public String getContentType(){return "image/png";}
                    public InputStream getInputStream(){
                        if(url.getPath().contains("interrupted"))return new InputStream(){int read;public int read()throws IOException{if(read++>5)throw new IOException("fixture interruption");return 7;}};
                        return new ByteArrayInputStream(fixture);
                    }
                    public void connect(){} public void disconnect(){} public boolean usingProxy(){return false;}
                };
            }
        }:null);
        File root=Files.createTempDirectory("dokkan-integrity-").toFile(),cache=new File(root,"preview-cache");
        String url="https://dokkan-eclipse.com/assets/fixture.png";
        final long[] used={0};OfflineLibrary.Budget budget=new OfflineLibrary.Budget(){public void reserve(long n){used[0]+=n;}public void release(long n){used[0]-=n;}};
        try{
            ok("new download completes",OfflineLibrary.download(cache,url,1<<20,budget)==fixture.length);
            File body=OfflineLibrary.savedBody(cache,url),meta=new File(body.getPath().replaceFirst("\\.body$",".json"));
            JSONObject record=metadata(meta);
            ok("new metadata stores exact bytes and SHA-256",record.getLong("bytes")==fixture.length&&record.getString("sha256").matches("[a-f0-9]{64}"));
            int before=requests;ok("verified reuse does not redownload",OfflineLibrary.download(cache,url,1<<20,budget)==0&&requests==before);
            File personal=new File(cache,"personal.txt");write(personal,"keep".getBytes("UTF-8"));
            byte[] damaged=fixture.clone();damaged[0]=9;write(body,damaged);body.setLastModified(body.lastModified()+2000);
            ok("same-size corruption is rejected",OfflineLibrary.savedBody(cache,url)==null);
            ok("only the recognized corrupt pair is removed",!body.exists()&&!meta.exists()&&personal.isFile());
            ok("corrupt pair downloads a fresh verified replacement",OfflineLibrary.download(cache,url,1<<20,budget)==fixture.length&&OfflineLibrary.savedBody(cache,url)!=null);
            body=OfflineLibrary.savedBody(cache,url);meta=new File(body.getPath().replaceFirst("\\.body$",".json"));record=metadata(meta);
            record.remove("sha256");record.remove("bytes");write(meta,record.toString().getBytes("UTF-8"));before=requests;
            ok("legacy metadata without checksum is retained",OfflineLibrary.savedBody(cache,url)!=null&&OfflineLibrary.download(cache,url,1<<20,budget)==0&&requests==before);
            record.put("url","https://dokkan-eclipse.com/assets/different.png");write(meta,record.toString().getBytes("UTF-8"));
            ok("unrecognized pair is not deleted",OfflineLibrary.savedBody(cache,url)==null&&body.isFile()&&meta.isFile());
            record.put("url",url).put("bytes",fixture.length+1);write(meta,record.toString().getBytes("UTF-8"));
            ok("declared-size mismatch is rejected",OfflineLibrary.savedBody(cache,url)==null&&!meta.exists());
            OfflineLibrary.download(cache,url,1<<20,budget);body=OfflineLibrary.savedBody(cache,url);meta=new File(body.getPath().replaceFirst("\\.body$",".json"));
            File outside=new File(root,"outside.txt");write(outside,"outside".getBytes("UTF-8"));body.delete();Files.createSymbolicLink(body.toPath(),outside.toPath());
            ok("symlinked body never reads or deletes outside file",OfflineLibrary.savedBody(cache,url)==null&&new String(Files.readAllBytes(outside.toPath()),"UTF-8").equals("outside"));
            long reserved=used[0];boolean failed=false;try{OfflineLibrary.download(cache,"https://dokkan-eclipse.com/assets/interrupted.png",1<<20,budget);}catch(IOException expected){failed=true;}
            ok("interrupted stream fails and releases reservation",failed&&used[0]==reserved);
            File[] leftovers=cache.listFiles((d,n)->n.contains("part"));ok("interrupted stream leaves no partial files",leftovers!=null&&leftovers.length==0);
            System.out.println(checks+" downloader integrity/reuse checks passed; legacy bodies have no original checksum assurance.");
        }finally{PublicStorage.removeTree(root.toPath());}
    }
}
