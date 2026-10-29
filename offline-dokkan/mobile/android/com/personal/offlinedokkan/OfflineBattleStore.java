package com.personal.offlinedokkan;

import android.system.Os;
import android.system.OsConstants;
import org.json.JSONObject;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileDescriptor;
import java.io.IOException;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.nio.channels.Channels;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

/** Trusted native coordinator storage only. Never expose its raw methods to a game page. */
final class OfflineBattleStore {
    private static final Object PROCESS_LOCK=new Object();
    private static final int MAX_BYTES=4*1024*1024,CONFIG_BYTES=512*1024;
    private static final String FORMAT="offline-battle-slot-v1";
    private final File directory,current,staging,lock;
    private final String source,content,profile;

    OfflineBattleStore(File directory,String source,String content,String profile)throws IOException {
        if(!OfflinePlayerStore.validSource(source)||!content.matches("sha256:[a-f0-9]{64}")||!profile.matches("[A-Za-z0-9_.:-]{1,127}"))throw failure("BATTLE_STORAGE_CONTEXT_INVALID");
        this.directory=directory.getCanonicalFile();this.source=source;this.content=content;this.profile=profile;
        if(!this.directory.isDirectory()||Files.isSymbolicLink(directory.toPath()))throw failure("BATTLE_STORAGE_UNSAFE");
        current=new File(this.directory,"battle-slot.bin");staging=new File(this.directory,"battle-slot.pending");lock=new File(this.directory,"battle-slot.lock");
    }
    private static IOException failure(String code){return new IOException(code);}
    private static String hash(byte[] data)throws Exception {
        StringBuilder text=new StringBuilder();for(byte value:MessageDigest.getInstance("SHA-256").digest(data))text.append(String.format(java.util.Locale.ROOT,"%02x",value&255));return text.toString();
    }
    private void regular(File file)throws IOException {
        if(Files.exists(file.toPath(),LinkOption.NOFOLLOW_LINKS)&&!Files.isRegularFile(file.toPath(),LinkOption.NOFOLLOW_LINKS))throw failure("BATTLE_STORAGE_UNSAFE");
    }
    private void validateData(String data)throws Exception {
        if(data==null)throw failure("BATTLE_STORAGE_RECORD_INVALID");byte[] encoded=data.getBytes(StandardCharsets.UTF_8);
        if(encoded.length>MAX_BYTES)throw failure("BATTLE_SESSION_TOO_LARGE");
        if(!data.equals(new String(encoded,StandardCharsets.UTF_8)))throw failure("BATTLE_STORAGE_RECORD_INVALID");
        JSONObject envelope;
        try{envelope=new JSONObject(data);}catch(Exception error){throw failure("BATTLE_STORAGE_RECORD_INVALID");}
        Set<String> keys=new HashSet<>(Arrays.asList("format","version","configuration","configurationSha256","state","stateSha256","settlement"));
        java.util.Iterator<String> names=envelope.keys();while(names.hasNext())if(!keys.remove(names.next()))throw failure("BATTLE_STORAGE_RECORD_INVALID");
        Object version=envelope.opt("version");
        if(!keys.isEmpty()||!"offline-dokkan-battle-session".equals(envelope.optString("format"))||!(version instanceof Number)||((Number)version).doubleValue()!=1)throw failure("BATTLE_STORAGE_RECORD_INVALID");
        JSONObject configuration=envelope.getJSONObject("configuration"),state=envelope.getJSONObject("state");
        if(!content.equals(configuration.opt("contentId"))||!content.equals(state.opt("contentId")))throw failure("BATTLE_STORAGE_CONTEXT_MISMATCH");
        if(configuration.toString().getBytes(StandardCharsets.UTF_8).length>CONFIG_BYTES)throw failure("BATTLE_CONFIGURATION_TOO_LARGE");
        // These are consistency checks, never evidence for awarding a result.
        // The trusted coordinator must replay legal intents and verify settlement.
        if(!envelope.optString("configurationSha256").matches("[a-f0-9]{64}")||!envelope.optString("stateSha256").matches("[a-f0-9]{64}"))throw failure("BATTLE_SESSION_HASH_INVALID");
    }
    private JSONObject readLocked()throws Exception {
        regular(current);if(!current.exists())return null;
        if(current.length()<1||current.length()>MAX_BYTES+512L)throw failure("BATTLE_STORAGE_RECORD_INVALID");
        try(DataInputStream input=new DataInputStream(Channels.newInputStream(FileChannel.open(current.toPath(),StandardOpenOption.READ,LinkOption.NOFOLLOW_LINKS)))){
            if(!FORMAT.equals(input.readUTF()))throw failure("BATTLE_STORAGE_RECORD_INVALID");
            if(!source.equals(input.readUTF())||!content.equals(input.readUTF())||!profile.equals(input.readUTF()))throw failure("BATTLE_STORAGE_CONTEXT_MISMATCH");
            String token=input.readUTF(),digest=input.readUTF();int count=input.readInt();
            if(!token.matches("[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}")||!digest.matches("[a-f0-9]{64}")||count<1||count>MAX_BYTES)throw failure("BATTLE_STORAGE_RECORD_INVALID");
            byte[] bytes=new byte[count];input.readFully(bytes);if(input.read()!=-1||!digest.equals(hash(bytes)))throw failure("BATTLE_STORAGE_RECORD_INVALID");
            String data=new String(bytes,StandardCharsets.UTF_8);if(!Arrays.equals(bytes,data.getBytes(StandardCharsets.UTF_8)))throw failure("BATTLE_STORAGE_RECORD_INVALID");
            validateData(data);return new JSONObject().put("token",token).put("data",data);
        }
    }
    private interface LockedTask {Object run()throws Exception;}
    private Object locked(LockedTask task)throws Exception {
        synchronized(PROCESS_LOCK){
            regular(lock);
            try(FileChannel channel=FileChannel.open(lock.toPath(),StandardOpenOption.CREATE,StandardOpenOption.WRITE,LinkOption.NOFOLLOW_LINKS);FileLock held=channel.lock()){
                Os.chmod(lock.getPath(),0600);regular(staging);
                // A crashed unpublished stage never replaces the committed slot.
                Files.deleteIfExists(staging.toPath());
                return task.run();
            }
        }
    }
    Object read()throws Exception {return locked(()->{JSONObject row=readLocked();return row==null?JSONObject.NULL:row;});}
    Object compareAndSwap(String expectedToken,String data)throws Exception {
        if(expectedToken!=null&&!expectedToken.matches("[^\\x00-\\x1f\\x7f]{1,256}"))throw failure("BATTLE_STORAGE_TOKEN_INVALID");
        validateData(data);byte[] bytes=data.getBytes(StandardCharsets.UTF_8);
        return locked(()->{
            JSONObject previous=readLocked();String old=previous==null?null:previous.getString("token");
            if(expectedToken==null?old!=null:!expectedToken.equals(old))return Boolean.FALSE;
            String token;do{token=UUID.randomUUID().toString();}while(token.equals(old));
            boolean published=false;
            try{
                try(FileChannel stream=FileChannel.open(staging.toPath(),StandardOpenOption.CREATE_NEW,StandardOpenOption.WRITE,LinkOption.NOFOLLOW_LINKS);DataOutputStream output=new DataOutputStream(Channels.newOutputStream(stream))){
                    Os.chmod(staging.getPath(),0600);output.writeUTF(FORMAT);output.writeUTF(source);output.writeUTF(content);output.writeUTF(profile);output.writeUTF(token);output.writeUTF(hash(bytes));output.writeInt(bytes.length);output.write(bytes);output.flush();stream.force(true);
                }
                Files.move(staging.toPath(),current.toPath(),StandardCopyOption.ATOMIC_MOVE,StandardCopyOption.REPLACE_EXISTING);published=true;
                FileDescriptor descriptor=Os.open(directory.getPath(),OsConstants.O_RDONLY|OsConstants.O_CLOEXEC|OsConstants.O_NOFOLLOW,0);
                try{if(!OsConstants.S_ISDIR(Os.fstat(descriptor).st_mode))throw failure("BATTLE_STORAGE_UNSAFE");Os.fsync(descriptor);}finally{Os.close(descriptor);}
                return token;
            }finally{if(!published)Files.deleteIfExists(staging.toPath());}
        });
    }
}
