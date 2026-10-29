package com.personal.offlinedokkan;

import android.content.Context;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import java.io.Closeable;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PushbackInputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.Arrays;

/** Trusted native picker utility; call on a worker, never expose it to WebView arguments. */
final class OfflineMasterArchive {
    static { System.loadLibrary("odbridge"); }
    private static final long MAX_SOURCE=4294967295L, MAX_DATABASE=2147483648L;
    private static final byte[] SQLITE="SQLite format 3\000".getBytes(StandardCharsets.US_ASCII);
    private OfflineMasterArchive() {}

    /** Owns only its fresh private temporary directory. Closing never deletes an imported master. */
    static final class Stage implements Closeable {
        private final File directory, database;
        private boolean closed;
        private Stage(File directory) { this.directory=directory;database=new File(directory,"database.sqlite"); }
        File database() throws IOException {
            if(closed)throw new IOException("MASTER_STAGE_CLOSED");
            return database;
        }
        @Override public void close() throws IOException {
            if(closed)return;
            IOException error=null;
            // Fixed files only. No tree traversal or deletion selected by imported metadata.
            for(String name:new String[]{"source.input","database.sqlite","database.sqlite-journal","database.sqlite-wal","database.sqlite-shm"}) {
                File child=new File(directory,name);
                try { Files.deleteIfExists(child.toPath()); }
                catch(IOException failure) { error=failure; }
            }
            try { Files.deleteIfExists(directory.toPath()); }
            catch(IOException failure) { error=failure; }
            if(error!=null)throw new IOException("MASTER_STAGE_CLEANUP_FAILED",error);
            closed=true;
        }
    }

    static Stage stage(Context context, Uri pickerUri, String game) throws IOException {
        if(context==null||pickerUri==null||!"content".equals(pickerUri.getScheme())||pickerUri.getAuthority()==null||pickerUri.getAuthority().isEmpty())throw new IOException("MASTER_PICKER_URI_REQUIRED");
        if(!"eclipse".equals(game)&&!"sparking".equals(game))throw new IOException("MASTER_ARCHIVE_GAME_INVALID");
        // Only the app supplies this root. Provider display names/URI paths never become filesystem paths.
        File cache=context.getCacheDir();if(cache==null)throw new IOException("MASTER_STAGE_UNAVAILABLE");
        File root=new File(cache.getCanonicalFile(),"master-imports");
        if(Files.isSymbolicLink(root.toPath()))throw new IOException("MASTER_STAGE_UNSAFE");
        Files.createDirectories(root.toPath());
        if(!root.isDirectory()||!root.getCanonicalFile().equals(root))throw new IOException("MASTER_STAGE_UNSAFE");
        Stage stage=new Stage(Files.createTempDirectory(root.toPath(),"input-").toFile());
        boolean complete=false;
        try {
            File source=new File(stage.directory,"source.input");boolean sqlite;
            try(InputStream selected=context.getContentResolver().openInputStream(pickerUri)) {
                if(selected==null)throw new IOException("MASTER_INPUT_UNAVAILABLE");
                try(PushbackInputStream input=new PushbackInputStream(selected,16)) {
                    byte[] header=new byte[16];int used=0;
                    while(used<header.length) {int n=input.read(header,used,header.length-used);if(n<0)break;if(n==0){int b=input.read();if(b<0)break;header[used++]=(byte)b;}else used+=n;}
                    sqlite=used==16&&Arrays.equals(header,SQLITE);
                    boolean zip=used>=4&&header[0]=='P'&&header[1]=='K'&&header[2]==3&&header[3]==4;
                    if(!sqlite&&!zip)throw new IOException("MASTER_INPUT_UNSUPPORTED");
                    input.unread(header,0,used);
                    try(FileOutputStream output=new FileOutputStream(source)) {
                        byte[] buffer=new byte[65536];long total=0;int n;
                        while((n=input.read(buffer))!=-1) {
                            if(Thread.currentThread().isInterrupted())throw new IOException("MASTER_IMPORT_INTERRUPTED");
                            if(n==0){int b=input.read();if(b<0)break;buffer[0]=(byte)b;n=1;}
                            if(n>(sqlite?MAX_DATABASE:MAX_SOURCE)-total)throw new IOException("MASTER_INPUT_TOO_LARGE");
                            output.write(buffer,0,n);total+=n;
                        }
                        output.getFD().sync();
                    }
                }
            }
            if(sqlite)Files.move(source.toPath(),stage.database.toPath());
            else {
                try(FileInputStream input=new FileInputStream(source);FileOutputStream output=new FileOutputStream(stage.database);
                    ParcelFileDescriptor inputDescriptor=ParcelFileDescriptor.dup(input.getFD());
                    ParcelFileDescriptor outputDescriptor=ParcelFileDescriptor.dup(output.getFD())) {
                    extract(inputDescriptor.getFd(),outputDescriptor.getFd(),"sparking".equals(game));
                }
                Files.delete(source.toPath());
            }
            complete=true;
            return stage; // Caller must validate SQLite/schema/SHA before publication/activation.
        } finally {
            if(!complete)stage.close();
        }
    }
    private static native void extract(int source,int output,boolean sparking) throws IOException;
}
