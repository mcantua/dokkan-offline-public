package com.personal.aihub;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.security.MessageDigest;
import java.util.Locale;
import javax.net.ssl.HttpsURLConnection;
import org.json.JSONObject;

/**
 * Verified download of one Sparking custom file that lives outside the folders the original Sparking
 * downloader accepts (custom stages in dokkan_field/, Custom/, card/, thumb/, card_transform/).
 * Same rules as SparkingContent.downloadAsset: anonymous GET, no redirects, identity encoding, the
 * address must be exactly ddl.dokkan-sparking.com/dokkan/assets/global/en/<path>, size ≤ 192 MB and
 * equal to the manifest, XXH64 must equal the manifest checksum; SHA-256 recorded; written to a temp
 * file next to the destination and renamed only when everything matches.
 */
final class SparkingFetch {
    private SparkingFetch() {}

    private static final long MAX = 201326592L;

    /** Top folders the original Sparking downloader already handles (its checks are used for those). */
    static boolean originalAllows(String path) {
        String top = path.indexOf('/') < 0 ? path : path.substring(0, path.indexOf('/'));
        return java.util.Arrays.asList("outgame", "sugoroku", "character", "ingame", "script", "movie", "sound", "lua", "bgm", "item", "card_category", "sd_battle").contains(top)
                || path.matches("se/[A-Za-z0-9_-]{1,80}\\.(acb|awb)")
                || path.matches("voice/(?:(en|ja)/)?([A-Za-z0-9_-]{1,80})/\\2\\.(acb|awb)");
    }

    static JSONObject download(JSONObject rec, String path, File dest) throws Exception {
        if (!SparkingCustom.content(path)) throw new IOException("Not a Sparking project resource.");
        if (path.length() > 500 || path.indexOf('\\') >= 0 || path.indexOf(':') >= 0 || path.matches("(?s).*[\\x00-\\x1f\\x7f].*")) throw new IOException("Unsupported Sparking game resource path.");
        for (String part : path.split("/", -1)) if (part.isEmpty() || part.equals(".") || part.equals("..")) throw new IOException("Unsafe Sparking game resource path.");
        if (!path.equals(rec.optString("file_path"))) throw new IOException("This resource is not listed in the downloaded Sparking manifest.");
        Object sizeValue = rec.opt("size");
        if (!(sizeValue instanceof Integer || sizeValue instanceof Long)) throw new IOException("Unsupported Sparking game resource size or checksum.");
        long size = ((Number) sizeValue).longValue();
        if (size <= 0 || size > MAX || !"xxhash".equals(rec.optString("algorithm"))) throw new IOException("Unsupported Sparking game resource size or checksum.");
        String hash = rec.getString("hash");
        if (!hash.matches("[0-9]{1,20}")) throw new IOException("Invalid Sparking resource checksum.");
        long expected = Long.parseUnsignedLong(hash);
        URI url = new URI(rec.getString("url"));
        String rawPath = new URI(null, null, "/dokkan/assets/global/en/" + path, null).toASCIIString();
        if (!"https".equals(url.getScheme()) || !"ddl.dokkan-sparking.com".equals(url.getHost()) || !rawPath.equals(url.getRawPath())
                || url.getRawUserInfo() != null || url.getRawFragment() != null || (url.getPort() != -1 && url.getPort() != 443))
            throw new IOException("The Sparking resource download address does not match its manifest path.");
        File dir = dest.getAbsoluteFile().getParentFile();
        if (dir == null || !dir.isDirectory()) throw new IOException("Create the Sparking download folder first.");
        if (dest.exists() && !dest.isFile()) throw new IOException("Unsafe Sparking download destination.");
        File temp = new File(dir, "sparking-asset-" + java.util.UUID.randomUUID() + ".tmp");
        HttpsURLConnection c = (HttpsURLConnection) url.toURL().openConnection();
        try {
            c.setInstanceFollowRedirects(false);
            c.setConnectTimeout(20000);
            c.setReadTimeout(60000);
            c.setRequestProperty("Accept-Encoding", "identity");
            c.setRequestProperty("User-Agent", "Dokkan-Unit-Creation-Sparking-Content");
            int code = c.getResponseCode();
            if (code == 401 || code == 403) throw new IOException("The Sparking public content server refused this request. No account credentials were sent.");
            if (code != 200) throw new IOException("The Sparking public content server returned HTTP " + code + ". Try again later.");
            String enc = c.getHeaderField("Content-Encoding");
            if (enc != null && !"identity".equalsIgnoreCase(enc.trim())) throw new IOException("The Sparking server changed its download encoding.");
            long length = c.getContentLengthLong();
            if (length >= 0 && length != size) throw new IOException("The Sparking resource size differs from its manifest.");
            MessageDigest sha = MessageDigest.getInstance("SHA-256");
            SparkingContent.XXH64 xx = new SparkingContent.XXH64();
            long written = 0;
            InputStream in = c.getInputStream();
            FileOutputStream out = new FileOutputStream(temp);
            try {
                byte[] b = new byte[65536];
                int n;
                while ((n = in.read(b)) != -1) {
                    written += n;
                    if (written > size) throw new IOException("The Sparking resource size differs from its manifest.");
                    out.write(b, 0, n);
                    sha.update(b, 0, n);
                    xx.update(b, 0, n);
                }
                out.getFD().sync();
            } finally {
                out.close();
                in.close();
            }
            if (written != size) throw new IOException("The Sparking resource size differs from its manifest.");
            if (xx.value() != expected) throw new IOException("The Sparking resource checksum does not match its manifest.");
            StringBuilder hex = new StringBuilder();
            for (byte x : sha.digest()) hex.append(String.format(Locale.ROOT, "%02x", x & 255));
            if (!temp.renameTo(dest)) throw new IOException("Could not save the Sparking resource.");
            return new JSONObject().put("file_path", path).put("bytes", size).put("sha256", hex.toString()).put("xxhash64", hash);
        } finally {
            temp.delete();
            c.disconnect();
        }
    }
}
