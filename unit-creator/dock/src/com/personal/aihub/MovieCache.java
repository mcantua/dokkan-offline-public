package com.personal.aihub;

import android.content.Context;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.IOException;
import java.io.FilterInputStream;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;

/**
 * Prepared game movies, kept on the phone. A game movie (.usm) has to be converted into a video
 * the phone can play before it shows in a preview, which takes a while on a phone. The player used
 * to throw that work away when the preview closed, so every preview converted the same movie
 * again, even when the movie itself was downloaded. Now the converted video is kept here
 * (files/forge/movie-cache, at most 3 GB, oldest first out) and reused the next time.
 *
 * Only the in-app player's own local page can use it, through two GET addresses that never reach
 * the network (the player's WebView answers them here):
 *   /_forge/movie-cache/KEY.mp4            the kept video, or 404
 *   /_forge/movie-cache/keep/KEY/ID.mp4    keep the video the player just prepared (ID) as KEY
 * KEY is the SHA-256 of the original movie file plus the output kind, e.g. "<64 hex>-h".
 */
final class MovieCache {
    private static final long LIMIT = 3L * 1024 * 1024 * 1024;
    private static final long KEEP_FREE = 512L * 1024 * 1024;
    private static final String KEY = "[a-f0-9]{64}-[a-z]{1,4}";

    private MovieCache() {}

    static File folder(Context context) {
        return new File(new File(context.getFilesDir(), "forge"), "movie-cache");
    }

    static WebResourceResponse handle(Context context, Object server, WebResourceRequest request) {
        try {
            if (!"GET".equals(request.getMethod())) return reply(405, "{}");
            String path = request.getUrl().getPath();
            if (path == null || request.getUrl().toString().indexOf('?') >= 0) return reply(404, "{}");
            String rest = path.substring("/_forge/movie-cache/".length());
            File dir = folder(context);
            if (rest.matches(KEY + "\\.mp4")) {
                // kept as ".video" so no gallery app ever treats it as a video
                File file = new File(dir, rest.substring(0, rest.length() - 4) + ".video");
                String range=null;
                Map<String,String> requested=request.getRequestHeaders();
                if(requested!=null)for(Map.Entry<String,String> entry:requested.entrySet())if("Range".equalsIgnoreCase(entry.getKey()))range=entry.getValue();
                return serve(file,range);
            }
            if (rest.matches("keep/" + KEY + "/[a-f0-9]{32}\\.mp4")) {
                String[] parts = rest.split("/");
                File source = preparedFile(server, parts[2]);
                if (source == null || !source.isFile() || source.length() < 12) return reply(404, "{}");
                if (!dir.isDirectory()) PublicStorage.ensure();
                dir.mkdirs();
                File target = new File(dir, parts[1] + ".video");
                if (target.isFile() && target.length() == source.length()) return reply(200, "{\"kept\":true}");
                if (dir.getUsableSpace() - source.length() < KEEP_FREE) return reply(507, "{\"kept\":false}");
                File part = new File(dir, parts[1] + ".part");
                InputStream in = new FileInputStream(source);
                FileOutputStream out = new FileOutputStream(part);
                try {
                    byte[] buffer = new byte[65536];
                    int n;
                    while ((n = in.read(buffer)) != -1) out.write(buffer, 0, n);
                } finally {
                    in.close();
                    out.close();
                }
                if (!part.renameTo(target)) { part.delete(); return reply(500, "{\"kept\":false}"); }
                trim(dir, target);
                return reply(200, "{\"kept\":true}");
            }
            return reply(404, "{}");
        } catch (Throwable t) {
            return reply(500, "{}");
        }
    }

    /** WebView video seeking needs real byte ranges, including suffix and open-ended requests. */
    static WebResourceResponse serve(File file,String range)throws Exception {
        if(!file.isFile()||PublicStorage.isLink(file)||file.length()<12)return reply(404,"{}");
        long length=file.length(),start=0,end=length-1;
        boolean partial=range!=null&&!range.trim().isEmpty(),valid=true;
        if(partial){
            java.util.regex.Matcher match=java.util.regex.Pattern.compile("bytes=([0-9]*)-([0-9]*)").matcher(range.trim());
            if(!match.matches()||(match.group(1).isEmpty()&&match.group(2).isEmpty()))valid=false;
            else try{
                if(match.group(1).isEmpty()){
                    long suffix=Long.parseLong(match.group(2));if(suffix<1)valid=false;
                    else start=Math.max(0,length-suffix);
                }else{
                    start=Long.parseLong(match.group(1));
                    if(!match.group(2).isEmpty())end=Math.min(end,Long.parseLong(match.group(2)));
                    if(start>=length||end<start)valid=false;
                }
            }catch(NumberFormatException invalid){valid=false;}
        }
        Map<String,String> headers=new HashMap<String,String>();
        headers.put("Cache-Control","no-store");headers.put("Accept-Ranges","bytes");
        if(!valid){headers.put("Content-Range","bytes */"+length);headers.put("Content-Length","0");return new WebResourceResponse("video/mp4",null,416,"Range Not Satisfiable",headers,new ByteArrayInputStream(new byte[0]));}
        long count=end-start+1;headers.put("Content-Length",String.valueOf(count));
        if(partial)headers.put("Content-Range","bytes "+start+"-"+end+"/"+length);
        FileInputStream source=new FileInputStream(file);
        try{source.getChannel().position(start);}catch(Exception failure){source.close();throw failure;}
        final long bytes=count;
        InputStream limited=new FilterInputStream(source){
            long remaining=bytes;
            public int read()throws IOException{if(remaining==0)return -1;int value=super.read();if(value>=0)remaining--;return value;}
            public int read(byte[] buffer,int offset,int amount)throws IOException{if(remaining==0)return -1;int n=in.read(buffer,offset,(int)Math.min(remaining,amount));if(n>0)remaining-=n;return n;}
            public long skip(long amount)throws IOException{long n=in.skip(Math.min(remaining,Math.max(0,amount)));remaining-=n;return n;}
            public int available()throws IOException{return (int)Math.min(remaining,in.available());}
        };
        file.setLastModified(System.currentTimeMillis());
        return new WebResourceResponse("video/mp4",null,partial?206:200,partial?"Partial Content":"OK",headers,limited);
    }

    /** The player server keeps the videos it prepared for this preview in a private map. */
    private static File preparedFile(Object server, String id) throws Exception {
        if (server == null) return null;
        java.lang.reflect.Field field = server.getClass().getDeclaredField("movies");
        field.setAccessible(true);
        Object map = field.get(server);
        if (!(map instanceof Map)) return null;
        synchronized (server) {
            Object file = ((Map<?, ?>) map).get(id);
            return file instanceof File ? (File) file : null;
        }
    }

    /** Oldest videos go first once the folder is over its limit. */
    private static void trim(File dir, File keep) {
        File[] files = dir.listFiles();
        if (files == null) return;
        long total = 0;
        for (File f : files) total += f.length();
        if (total <= LIMIT) return;
        Arrays.sort(files, new Comparator<File>() {
            public int compare(File a, File b) { return Long.compare(a.lastModified(), b.lastModified()); }
        });
        for (File f : files) {
            if (total <= LIMIT) break;
            if (f.equals(keep) || f.getName().startsWith(".")) continue;
            long size = f.length();
            if (f.delete()) total -= size;
        }
    }

    private static WebResourceResponse reply(int status, String json) {
        Map<String, String> headers = new HashMap<String, String>();
        headers.put("Cache-Control", "no-store");
        String reason = status == 200 ? "OK" : status == 404 ? "Not Found" : status == 405 ? "Method Not Allowed" : status == 507 ? "Insufficient Storage" : "Error";
        return new WebResourceResponse("application/json", "UTF-8", status, reason, headers, new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8)));
    }
}
