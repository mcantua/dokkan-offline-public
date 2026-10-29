package com.personal.offlinedokkan;

import android.content.Context;
import android.os.SystemClock;
import java.io.Closeable;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.BooleanSupplier;
import javax.net.ssl.HttpsURLConnection;

/** Explicit native setup download only. No arbitrary URL, decryption or player activation. */
final class OfflineDatabaseDownload {
    private static final long MAX_BYTES=512L*1024*1024,MAX_MILLIS=5*60*1000;
    private static final AtomicBoolean leased=new AtomicBoolean();
    private static final byte[] HEADER="SQLite format 3\000".getBytes(StandardCharsets.US_ASCII);
    private OfflineDatabaseDownload(){}
    static String url(String source)throws IOException {
        if("eclipse".equals(source))return "https://dokkan-eclipse.com/cdn/uncompressed/sqlite/current/en/database_decrypted.db";
        if("sparking".equals(source))return "https://ddl.dokkan-sparking.com/dokkan/assets/global/en/sqlite/current/en/database.db";
        throw new IOException("INVALID_CONTENT_SOURCE");
    }
    static final class Stage implements Closeable {
        final File directory,database;
        final String source;
        String sha256;
        long bytes;
        private boolean closed;
        private Stage(File directory,String source){this.directory=directory;this.source=source;database=new File(directory,"database.sqlite");}
        @Override public void close()throws IOException {
            if(closed)return;IOException failure=null;
            for(String name:new String[]{"database.sqlite","database.sqlite-journal","database.sqlite-wal","database.sqlite-shm"}){
                try{Files.deleteIfExists(new File(directory,name).toPath());}catch(IOException error){failure=error;}
            }
            try{Files.deleteIfExists(directory.toPath());}catch(IOException error){failure=error;}
            if(failure!=null)throw new IOException("SOURCE_DOWNLOAD_CLEANUP_FAILED",failure);
            closed=true;leased.set(false);
        }
    }
    static Stage download(Context context,String source,BooleanSupplier cancelled)throws Exception {
        String permitted=url(source);
        if(!leased.compareAndSet(false,true))throw new IOException("SOURCE_DOWNLOAD_BUSY");
        Stage stage=null;boolean complete=false;HttpsURLConnection connection=null;
        try{
            File root=new File(context.getCacheDir().getCanonicalFile(),"database-downloads");
            if(Files.isSymbolicLink(root.toPath()))throw new IOException("SOURCE_DOWNLOAD_STAGING_UNSAFE");
            Files.createDirectories(root.toPath());
            if(!root.isDirectory()||!root.getCanonicalFile().equals(root))throw new IOException("SOURCE_DOWNLOAD_STAGING_UNSAFE");
            stage=new Stage(Files.createTempDirectory(root.toPath(),"input-").toFile(),source);
            if(cancelled.getAsBoolean())throw new IOException("SOURCE_DOWNLOAD_CANCELLED");
            // Default Android certificate and hostname verification stay enabled.
            // Redirects are rejected, including redirects elsewhere on this host.
            connection=(HttpsURLConnection)new URL(permitted).openConnection();
            connection.setInstanceFollowRedirects(false);connection.setConnectTimeout(30000);connection.setReadTimeout(30000);
            connection.setUseCaches(false);connection.setRequestMethod("GET");
            connection.setRequestProperty("Accept-Encoding","identity");connection.setRequestProperty("User-Agent","Offline-Dokkan-Data/0.1");
            long started=SystemClock.elapsedRealtime();int code=connection.getResponseCode();
            if(code>=300&&code<400)throw new IOException("SOURCE_REDIRECT_NOT_ALLOWED");
            if(code!=200)throw new IOException("SOURCE_DOWNLOAD_UNAVAILABLE");
            if(!permitted.equals(connection.getURL().toExternalForm()))throw new IOException("SOURCE_REDIRECT_NOT_ALLOWED");
            String encoding=connection.getHeaderField("Content-Encoding");
            if(encoding!=null&&!encoding.isEmpty()&&!"identity".equalsIgnoreCase(encoding))throw new IOException("SOURCE_ENCODING_UNSUPPORTED");
            String length=connection.getHeaderField("Content-Length");long expected=-1;
            if(length!=null){if(!length.matches("[0-9]{1,12}"))throw new IOException("SOURCE_LENGTH_INVALID");expected=Long.parseLong(length);if(expected<HEADER.length||expected>MAX_BYTES)throw new IOException("SOURCE_LENGTH_INVALID");}
            MessageDigest digest=MessageDigest.getInstance("SHA-256");byte[] header=new byte[HEADER.length];int headerBytes=0;long total=0;
            try(InputStream input=connection.getInputStream();FileOutputStream output=new FileOutputStream(stage.database)){
                byte[] buffer=new byte[65536];int count;
                while((count=input.read(buffer))!=-1){
                    if(cancelled.getAsBoolean()||Thread.currentThread().isInterrupted())throw new IOException("SOURCE_DOWNLOAD_CANCELLED");
                    if(SystemClock.elapsedRealtime()-started>MAX_MILLIS)throw new IOException("SOURCE_DOWNLOAD_TIMEOUT");
                    if(count==0){int value=input.read();if(value<0)break;buffer[0]=(byte)value;count=1;}
                    if(count>MAX_BYTES-total)throw new IOException("SOURCE_TOO_LARGE");
                    if(headerBytes<HEADER.length){int copied=Math.min(count,HEADER.length-headerBytes);System.arraycopy(buffer,0,header,headerBytes,copied);headerBytes+=copied;
                        if(headerBytes==HEADER.length&&!Arrays.equals(header,HEADER))throw new IOException("sparking".equals(source)?"PLAINTEXT_MASTER_REQUIRED_NO_DECRYPTION":"INVALID_MASTER_DOWNLOAD");}
                    total+=count;digest.update(buffer,0,count);output.write(buffer,0,count);
                }
                if(headerBytes!=HEADER.length||total<HEADER.length||expected>=0&&total!=expected)throw new IOException("SOURCE_SIZE_MISMATCH");
                output.getFD().sync();
            }
            StringBuilder hash=new StringBuilder();for(byte value:digest.digest())hash.append(String.format(java.util.Locale.ROOT,"%02x",value&255));
            stage.sha256=hash.toString();stage.bytes=total;complete=true;return stage;
        }finally{
            if(connection!=null)connection.disconnect();
            if(!complete){if(stage!=null)stage.close();else leased.set(false);}
        }
    }
}
