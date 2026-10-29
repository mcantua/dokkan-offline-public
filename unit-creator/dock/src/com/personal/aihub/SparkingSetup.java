package com.personal.aihub;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.Enumeration;
import java.util.Locale;
import java.util.zip.CRC32;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

/** Extracts format material only from the person's verified original Sparking APK.
 * Contains public library hashes/offsets, never a format key. Called by two narrow
 * SprkCodec hooks; the original importer still imports assets and saves the keys privately.
 */
public final class SparkingSetup {
    private static final int MAX_LIBRARY = 16 * 1024 * 1024;
    private SparkingSetup() {}

    static final class Version {
        final String name;
        final int patch, database;
        Version(String name, int patch, int database) { this.name=name; this.patch=patch; this.database=database; }
    }

    static Version version(String sha) throws IOException {
        if ("9d3f2749e391d990496b632b6adc135492f71e0baec7125d7b613a56e771dca0".equals(sha))
            return new Version("6.5.5", 648423, 487092);
        if ("83c0b40f49ae0edb0c91650ff36eb97a528db2c14627333f7023c3a13e0018d4".equals(sha))
            return new Version("6.6", 665339, 495950);
        throw new IOException("This Sparking APK version is not supported yet (supported: Sparking 6.5.5 and 6.6). Its format must be checked before importing encrypted patches.");
    }

    public static byte[] keyFromApk(File apk) throws Exception {
        Library library=library(apk);
        try { return patchKey(library.bytes, library.version); }
        finally { Arrays.fill(library.bytes,(byte)0); }
    }

    public static String databaseKeyFromApk(File apk) throws Exception {
        Library library=library(apk);
        try { return databaseKey(library.bytes, library.version); }
        finally { Arrays.fill(library.bytes,(byte)0); }
    }

    static byte[] patchKey(byte[] library, Version v) throws IOException {
        if (library.length < v.patch+16) throw new IOException("The supported Sparking patch format key is unavailable.");
        byte[] key=new byte[32]; // The verified SPRK format pads the 16-byte source to AES-256.
        System.arraycopy(library,v.patch,key,0,16);
        return key;
    }

    static String databaseKey(byte[] library, Version v) throws IOException {
        if (library.length <= v.database+64 || library[v.database+64]!=0)
            throw new IOException("The supported Sparking database format key is unavailable.");
        for (int i=v.database;i<v.database+64;i++) {
            int c=library[i]&255;
            if (!((c>='0'&&c<='9')||(c>='a'&&c<='f')||(c>='A'&&c<='F')))
                throw new IOException("The supported Sparking database format key is invalid.");
        }
        return new String(library,v.database,64,StandardCharsets.US_ASCII);
    }

    private static final class Library {
        final byte[] bytes; final Version version;
        Library(byte[] bytes, Version version) { this.bytes=bytes;this.version=version; }
    }

    private static Library library(File apk) throws Exception {
        if (apk==null || !apk.isFile()) throw new IOException("Import the original Sparking 6.5.5 or 6.6 Android APK first.");
        try (ZipFile zip=new ZipFile(apk)) {
            ZipEntry found=null;
            Enumeration<? extends ZipEntry> entries=zip.entries();
            while (entries.hasMoreElements()) {
                ZipEntry entry=entries.nextElement();
                if (!"lib/arm64-v8a/libbase.so".equals(entry.getName())) continue;
                if (found!=null) throw new IOException("The APK has duplicate native libraries.");
                found=entry;
            }
            if (found==null || found.isDirectory() || found.getSize()<600000 || found.getSize()>MAX_LIBRARY || found.getCompressedSize()>MAX_LIBRARY)
                throw new IOException("This APK does not contain a supported Sparking Android format library (6.5.5 or 6.6).");
            byte[] library=new byte[(int)found.getSize()];
            CRC32 crc=new CRC32();
            try {
                try (InputStream in=zip.getInputStream(found)) {
                    int offset=0,n;
                    while (offset<library.length && (n=in.read(library,offset,Math.min(65536,library.length-offset)))!=-1) {
                        crc.update(library,offset,n);offset+=n;
                    }
                    if (offset!=library.length || in.read()!=-1 || crc.getValue()!=found.getCrc())
                        throw new IOException("The Sparking format library is incomplete or corrupted.");
                }
                return new Library(library,version(hash(library))); // No extraction before the pinned hash matches.
            } catch (Exception e) { Arrays.fill(library,(byte)0);throw e; }
        }
    }

    private static String hash(byte[] bytes) throws Exception {
        byte[] digest=MessageDigest.getInstance("SHA-256").digest(bytes);
        StringBuilder text=new StringBuilder(64);
        for (byte b:digest) text.append(String.format(Locale.ROOT,"%02x",b&255));
        return text.toString();
    }
}
