package com.personal.aihub;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.MessageDigest;
import java.util.*;
import java.util.zip.*;
import org.json.*;

/** One explicitly saved user-content archive. Private roots remain canonical, not public symlinks. */
final class UserContentArchive {
    private static final String NAME = "Creations-for-reinstall.zip", MANIFEST = "manifest.json";
    private static final long MAX_TOTAL = 2L * 1024 * 1024 * 1024, MAX_ONE = 512L * 1024 * 1024;
    private static final int MAX_FILES = 10000, MAX_MANIFEST = 8 * 1024 * 1024;
    private static final int MAX_GALLERY=16*1024*1024, MAX_GALLERY_ONE=8*1024*1024;
    private static final long MAX_ARCHIVE = MAX_TOTAL + MAX_MANIFEST + MAX_FILES * 2048L;
    private static final String UUID = "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}";
    private static final String KEY = "[A-Za-z0-9_-]{1,100}";
    private static final Set<String> PRIVATE = new HashSet<String>(Arrays.asList("_databases", "ai-connections.json", "credentials.json", "secrets.json", "account.txt", "sprk-format-key.bin", "sparking-database-format.bin", "signing", "key-info.txt"));
    private UserContentArchive() {}

    static synchronized JSONObject dispatch(File root, JSONObject args) throws Exception {
        if(PublicStorage.isLink(root))throw new IOException("Creations must use private canonical app storage.");
        String action = args.optString("action", "status");
        File folder = PublicStorage.folder();
        boolean available = folder != null && PublicStorage.isAppFolder(folder);
        File archive;
        try { archive = available ? findArchive(folder) : null; }
        catch (IOException problem) {
            if ("status".equals(action)) return new JSONObject().put("available", available).put("exists", false).put("warning", problem.getMessage()).put("folder", PublicStorage.label());
            throw problem;
        }
        if ("status".equals(action)) return new JSONObject().put("available", available).put("galleryDocuments",true).put("exists", archive != null && archive.isFile() && !PublicStorage.isLink(archive)).put("folder", archive == null || archive.getParentFile().equals(folder) ? PublicStorage.label() : archive.getParentFile().getName()).put("name", NAME);
        if (!available) throw new IOException("Allow shared-storage access before saving or restoring creations.");
        if (PublicStorage.isLink(archive)) throw new IOException("The creations archive cannot be a symbolic link.");
        if ("save".equals(action)) return save(root, archive, args.optJSONObject("gallery"));
        if ("restore".equals(action)) return restore(root, archive);
        throw new IOException("Unknown creations archive action.");
    }

    private static File findArchive(File folder) throws IOException {
        File current = new File(folder, NAME), found = current.isFile() ? current : null;
        // Earlier private-mode installs may have used a numbered shared folder. A new permission
        // grant can adopt the main folder; do not strand the person's one archive in the old one.
        if (PublicStorage.allFiles()) for (File old : PublicStorage.otherAppFolders()) {
            File candidate = new File(old, NAME);
            if (!PublicStorage.isAppFolder(old) || !candidate.isFile() || PublicStorage.isLink(candidate)) continue;
            if (found != null) throw new IOException("More than one creations archive remains. Keep the one you want in your current downloads folder before saving or restoring.");
            found = candidate;
        }
        return found == null ? current : found;
    }

    private static boolean pathAllowed(String path) {
        if (path.length() > 500 || path.startsWith("/") || path.contains("\\") || path.contains(":") || path.contains("%")) return false;
        String[] parts = path.split("/", -1);
        for (String part : parts) if (part.isEmpty() || part.startsWith(".") || part.matches(".*[\\x00-\\x1f\\x7f].*") || PRIVATE.contains(part.toLowerCase(Locale.US))) return false;
        if (path.matches("projects/" + KEY + "\\.json")) return true;
        if (path.matches("project-versions/" + KEY + "/(index\\.json|" + UUID + "\\.version)")) return true;
        if (path.matches("patches/" + UUID + "\\.(json|eclp)")) return true;
        if (path.matches("animation-gallery/"+KEY+"\\.json")) return true;
        if (!path.startsWith("assets/") || parts.length < 3) return false;
        if (!parts[1].matches("(import|apk|patch|sparking|generated|generated-decoration|generated-lwf|generated-movie)-" + UUID + "|eclipse|art-download-[0-9]{10,16}-[A-Za-z0-9_-]{6,64}|sparking-source-[A-Za-z0-9_-]{1,80}")) return false;
        return path.matches("(?i).*\\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|m4a|aac|flac|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$");
    }

    private static File resolve(File root, String path) throws IOException {
        if (!pathAllowed(path)) throw new IOException("The creations archive contains an unsupported or private path.");
        File canonicalRoot = root.getCanonicalFile(), at = canonicalRoot;
        for (String segment : path.split("/")) {
            at = new File(at, segment);
            if (PublicStorage.isLink(at)) throw new IOException("Creations paths cannot use symbolic links.");
        }
        if (!at.getCanonicalPath().startsWith(canonicalRoot.getPath() + File.separator)) throw new IOException("Creations path escapes private storage.");
        return at;
    }

    private static void collect(File root, File dir, String relative, List<String> paths, int[] excluded) throws IOException {
        if (!dir.exists()) return;
        if (PublicStorage.isLink(dir)) throw new IOException("Creations folders cannot use symbolic links.");
        File[] children = dir.listFiles();
        if (children == null) throw new IOException("A creations folder could not be read.");
        Arrays.sort(children, new Comparator<File>() { public int compare(File a, File b) { return a.getName().compareTo(b.getName()); } });
        for (File f : children) {
            String p = relative + "/" + f.getName();
            if (PublicStorage.isLink(f)) throw new IOException("A creations file is a symbolic link; nothing was archived.");
            if (PRIVATE.contains(f.getName().toLowerCase(Locale.US)) || f.getName().startsWith(".")) { excluded[0]++; continue; }
            if (f.isDirectory()) { collect(root, f, p, paths, excluded); continue; }
            if (!pathAllowed(p)) { excluded[0]++; continue; }
            resolve(root, p);
            if (f.length() > MAX_ONE) throw new IOException("A creations file exceeds 512 MB. Export large resources separately.");
            paths.add(p);
            if (paths.size() > MAX_FILES) throw new IOException("Creations exceed 10,000 files. Nothing was archived.");
        }
    }

    private static JSONObject copyDigest(InputStream in, OutputStream out, long limit) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        long bytes = 0; byte[] buffer = new byte[65536]; int n;
        while ((n = in.read(buffer)) != -1) {
            if (n > limit - bytes) throw new IOException("Creations archive exceeds its size limit.");
            out.write(buffer, 0, n); digest.update(buffer, 0, n); bytes += n;
        }
        StringBuilder hex = new StringBuilder(); for (byte b : digest.digest()) hex.append(String.format(Locale.US, "%02x", b & 255));
        return new JSONObject().put("bytes", bytes).put("sha256", hex.toString());
    }

    private static void galleryValue(Object value,int depth)throws Exception {
        if(depth>64)throw new IOException("Gallery editing data is nested too deeply.");
        if(value instanceof JSONObject){JSONObject object=(JSONObject)value;Iterator<String> keys=object.keys();while(keys.hasNext()){String key=keys.next();if(key.matches("(?i)(__proto__|prototype|constructor|password|api[_-]?key|access[_-]?token|refresh[_-]?token|secret|signing[_-]?key|sparking[_-]?key|credentials)"))throw new IOException("Gallery data cannot contain connection details or private keys.");galleryValue(object.get(key),depth+1);}}
        else if(value instanceof JSONArray){JSONArray array=(JSONArray)value;for(int i=0;i<array.length();i++)galleryValue(array.get(i),depth+1);}
    }

    private static JSONObject galleryDocument(JSONObject doc)throws Exception {
        Set<String> fields=new HashSet<String>(Arrays.asList("format","version","key","createdAt","updatedAt","draft","deletedAt","targetId","source","schema","tables","assets","movieBindings","animationStudio","provenance","sourceDependencies"));
        Iterator<String> names=doc.keys();while(names.hasNext())if(!fields.contains(names.next()))throw new IOException("This gallery document contains unsupported fields. Nothing was archived.");
        if(!"dokkan-animation-gallery".equals(doc.optString("format"))||doc.optInt("version")!=1||!doc.optString("key").matches(KEY)||doc.getJSONArray("assets").length()>256||doc.getJSONObject("animationStudio").getJSONArray("clips").length()>24||doc.getJSONObject("animationStudio").optString("name").length()>120||doc.getLong("targetId")<1||doc.getLong("targetId")>1999999000)throw new IOException("Invalid gallery document in creations archive.");
        JSONObject source=doc.getJSONObject("source");if(!Arrays.asList("eclipse","sparking").contains(source.optString("database")))throw new IOException("Unknown gallery game collection.");
        JSONObject tables=doc.getJSONObject("tables"),schema=doc.getJSONObject("schema");Iterator<String> tableNames=tables.keys();while(tableNames.hasNext())if(!"effect_packs".equals(tableNames.next()))throw new IOException("Gallery documents cannot contain unit or database tables.");Iterator<String> schemaNames=schema.keys();while(schemaNames.hasNext())if(!"effect_packs".equals(schemaNames.next()))throw new IOException("Gallery documents cannot contain database schemas.");
        if(tables.getJSONArray("effect_packs").length()>48||schema.getJSONArray("effect_packs").length()>256||doc.optJSONArray("movieBindings")==null||doc.getJSONArray("movieBindings").length()>48)throw new IOException("Invalid gallery movie records.");
        JSONArray attachments=doc.getJSONArray("assets");for(int i=0;i<attachments.length();i++){JSONObject attachment=attachments.getJSONObject(i);for(String field:new String[]{"key","path"}){String path=attachment.getString(field);if(path.length()>500||path.startsWith("/")||path.contains("\\")||path.contains(":")||path.contains("%"))throw new IOException("Unsafe gallery attachment path.");for(String part:path.split("/",-1))if(part.isEmpty()||part.startsWith(".")||part.matches(".*[\\x00-\\x1f\\x7f].*"))throw new IOException("Unsafe gallery attachment path.");}}
        galleryValue(doc,0);if(doc.toString().getBytes(StandardCharsets.UTF_8).length>MAX_GALLERY_ONE)throw new IOException("One gallery document exceeds8MiB.");return doc;
    }

    private static void galleryAssets(Object value,Set<String> referenced)throws Exception {
        if(value instanceof JSONObject){JSONObject object=(JSONObject)value;Iterator<String> keys=object.keys();while(keys.hasNext()){String key=keys.next();Object child=object.get(key);if("assetKey".equals(key)&&child instanceof String&&!((String)child).isEmpty())referenced.add((String)child);else galleryAssets(child,referenced);}}
        else if(value instanceof JSONArray){JSONArray array=(JSONArray)value;for(int i=0;i<array.length();i++)galleryAssets(array.get(i),referenced);}
    }
    private static Set<String> galleryAssets(JSONObject doc)throws Exception {
        Set<String> keys=new HashSet<String>();JSONArray assets=doc.getJSONArray("assets");for(int i=0;i<assets.length();i++)keys.add(assets.getJSONObject(i).getString("key"));galleryAssets(doc.getJSONObject("animationStudio"),keys);return keys;
    }
    private static Map<String,byte[]> galleryEntries(JSONObject snapshot)throws Exception {
        Map<String,byte[]> entries=new LinkedHashMap<String,byte[]>();if(snapshot==null)return entries;
        if(!"dokkan-animation-gallery-snapshot".equals(snapshot.optString("format"))||snapshot.optInt("version")!=1)throw new IOException("Unsupported gallery snapshot.");
        JSONArray docs=snapshot.getJSONArray("documents");if(docs.length()>1000)throw new IOException("Use up to1,000 gallery documents in one creations archive.");long total=0;
        for(int i=0;i<docs.length();i++){JSONObject doc=galleryDocument(docs.getJSONObject(i));String path="animation-gallery/"+doc.getString("key")+".json";byte[] bytes=doc.toString().getBytes(StandardCharsets.UTF_8);if(entries.put(path,bytes)!=null||(total+=bytes.length)>MAX_GALLERY)throw new IOException("Gallery documents are duplicate or exceed16MiB total.");}
        return entries;
    }

    private static void checkGalleryAssets(File root,JSONObject doc,Set<String> paths)throws Exception {
        for(String key:galleryAssets(doc)){
            String path="assets/"+key;
            if(pathAllowed(path)){File file=resolve(root,path);if(!file.isFile()||!paths.contains(path))throw new IOException("A gallery resource is missing or excluded: "+key);}
            else{
                // A source assetKey can designate its complete imported collection, rather than one file.
                if(key.contains("/")||!pathAllowed(path+"/probe.txt"))throw new IOException("Gallery resource has an unsupported or private path.");
                File probe=resolve(root,path+"/probe.txt"),folder=probe.getParentFile();if(!folder.isDirectory()||PublicStorage.isLink(folder))throw new IOException("A gallery source collection is missing.");
                boolean found=false;for(String candidate:paths)if(candidate.startsWith(path+"/")){found=true;break;}if(!found)throw new IOException("A gallery source collection has no supported archived files.");
            }
        }
    }

    private static JSONObject save(File root, File archive, JSONObject gallery) throws Exception {
        List<String> paths = new ArrayList<String>(); int[] excluded = {0};
        for (String name : new String[]{"projects", "project-versions", "assets", "patches"}) collect(root, new File(root, name), name, paths, excluded);
        Map<String,byte[]> galleryFiles=galleryEntries(gallery);if(paths.size()+galleryFiles.size()>MAX_FILES)throw new IOException("Creations exceed10,000 files.");
        if(gallery!=null)for(int i=0;i<gallery.getJSONArray("documents").length();i++)checkGalleryAssets(root,gallery.getJSONArray("documents").getJSONObject(i),new HashSet<String>(paths));
        if (paths.isEmpty()&&galleryFiles.isEmpty()) throw new IOException("There are no saved creations or imported resources to archive yet.");
        File part = new File(archive.getParentFile(), ".creations-archive.part");
        if (PublicStorage.isLink(part)) throw new IOException("Unsafe archive staging path.");
        long total = 0; JSONArray records = new JSONArray();
        try {
            try (FileOutputStream file = new FileOutputStream(part); ZipOutputStream zip = new ZipOutputStream(file)) {
                zip.setLevel(Deflater.BEST_SPEED);
                for (String path : paths) {
                    File src = resolve(root, path);
                    zip.putNextEntry(new ZipEntry(path));
                    JSONObject rec;
                    try (InputStream in = new FileInputStream(src)) { rec = copyDigest(in, zip, Math.min(MAX_ONE, MAX_TOTAL - total)); }
                    zip.closeEntry(); total += rec.getLong("bytes"); records.put(rec.put("path", path));
                }
                for(Map.Entry<String,byte[]> doc:galleryFiles.entrySet()){
                    zip.putNextEntry(new ZipEntry(doc.getKey()));JSONObject rec=copyDigest(new ByteArrayInputStream(doc.getValue()),zip,MAX_TOTAL-total);zip.closeEntry();total+=rec.getLong("bytes");records.put(rec.put("path",doc.getKey()));
                }
                JSONObject metadata=new JSONObject().put("format", "dokkan-user-content").put("version",gallery==null?1:2).put("files",records);
                if(gallery!=null)metadata.put("gallery",new JSONObject().put("format","dokkan-animation-gallery-snapshot").put("version",1).put("count",galleryFiles.size()).put("currentKey",gallery.optString("currentKey","")).put("lastDeleted",gallery.optString("lastDeleted","")));
                byte[] manifest = metadata.toString().getBytes(StandardCharsets.UTF_8);
                if (manifest.length > MAX_MANIFEST) throw new IOException("Creations manifest is too large.");
                zip.putNextEntry(new ZipEntry(MANIFEST)); zip.write(manifest); zip.closeEntry(); zip.finish(); file.getFD().sync();
            }
            if (part.length() > MAX_ARCHIVE) throw new IOException("Creations archive is too large.");
            try { Files.move(part.toPath(), archive.toPath(), StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE); }
            catch (AtomicMoveNotSupportedException e) { Files.move(part.toPath(), archive.toPath(), StandardCopyOption.REPLACE_EXISTING); }
            return new JSONObject().put("saved", true).put("files", paths.size()+galleryFiles.size()).put("galleryDocuments",galleryFiles.size()).put("bytes", total).put("excluded", excluded[0]);
        } finally { part.delete(); }
    }

    private static JSONObject digest(File file) throws Exception {
        try (InputStream in = new FileInputStream(file)) { return copyDigest(in, new OutputStream(){ public void write(int b) {} public void write(byte[] b,int off,int len) {} }, MAX_ONE); }
    }

    private static JSONObject restore(File root, File archive) throws Exception {
        if (!archive.isFile() || archive.length() > MAX_ARCHIVE) throw new IOException("No supported creations archive was found in the shared folder.");
        root.mkdirs();
        File stage = Files.createTempDirectory(root.toPath(), ".creations-restore-").toFile();
        Map<String, JSONObject> actual = new LinkedHashMap<String, JSONObject>();
        List<File> installed = new ArrayList<File>();
        boolean success = false; int restored = 0, skipped = 0;
        long total = 0; byte[] manifest = null;
        try {
            try (ZipInputStream zip = new ZipInputStream(new FileInputStream(archive))) {
                ZipEntry entry;
                while ((entry = zip.getNextEntry()) != null) {
                    String path = entry.getName();
                    if (entry.isDirectory()) throw new IOException("Unexpected directory entry in creations archive.");
                    if (MANIFEST.equals(path)) {
                        if (manifest != null) throw new IOException("Duplicate creations manifest.");
                        ByteArrayOutputStream data = new ByteArrayOutputStream(); copyDigest(zip, data, MAX_MANIFEST); manifest = data.toByteArray();
                    } else {
                        if (!pathAllowed(path) || actual.containsKey(path) || actual.size() >= MAX_FILES) throw new IOException("Unsafe, duplicate or excessive creations archive entry.");
                        File dest = resolve(stage, path); dest.getParentFile().mkdirs();
                        JSONObject record;
                        try (FileOutputStream out = new FileOutputStream(dest)) { record = copyDigest(zip, out, Math.min(MAX_ONE, MAX_TOTAL-total)); out.getFD().sync(); }
                        total += record.getLong("bytes"); actual.put(path, record);
                    }
                    zip.closeEntry();
                }
            }
            if (manifest == null) throw new IOException("Creations manifest is missing.");
            JSONObject m = new JSONObject(new String(manifest, StandardCharsets.UTF_8));
            if (!"dokkan-user-content".equals(m.optString("format")) || (m.optInt("version")!=1&&m.optInt("version")!=2)) throw new IOException("Unsupported creations archive format.");
            JSONArray files = m.getJSONArray("files");
            if (files.length() != actual.size()) throw new IOException("Creations manifest file count does not match.");
            Set<String> listed = new HashSet<String>();
            for (int i=0;i<files.length();i++) {
                JSONObject expected=files.getJSONObject(i); String path=expected.getString("path"); JSONObject got=actual.get(path);
                if (!listed.add(path) || got==null || got.getLong("bytes")!=expected.getLong("bytes") || !got.getString("sha256").equals(expected.getString("sha256"))) throw new IOException("A creations file failed its size or checksum check.");
                if(path.startsWith("animation-gallery/"))continue;
                File dest=resolve(root,path);
                if (dest.exists()) {
                    if (!dest.isFile()) throw new IOException("An existing creation path is a folder. Nothing was restored.");
                    JSONObject have=digest(dest);
                    if (have.getLong("bytes")!=got.getLong("bytes") || !have.getString("sha256").equals(got.getString("sha256"))) throw new IOException("An existing creation or resource differs. Nothing was restored; export or rename the existing item first.");
                }
            }
            JSONArray documents=new JSONArray();long galleryBytes=0;
            for(String path:actual.keySet())if(path.startsWith("animation-gallery/")){
                File file=resolve(stage,path);if(file.length()>MAX_GALLERY_ONE||(galleryBytes+=file.length())>MAX_GALLERY||documents.length()>=1000)throw new IOException("Gallery editing data exceeds its archive limit.");
                JSONObject doc=galleryDocument(new JSONObject(new String(Files.readAllBytes(file.toPath()),StandardCharsets.UTF_8)));if(!path.equals("animation-gallery/"+doc.getString("key")+".json"))throw new IOException("Gallery document identity does not match its path.");checkGalleryAssets(stage,doc,actual.keySet());documents.put(doc);
            }
            JSONObject gallery=m.optJSONObject("gallery");
            if((documents.length()>0&&m.optInt("version")!=2)||(m.optInt("version")==2&&gallery==null)||(gallery!=null&&(!"dokkan-animation-gallery-snapshot".equals(gallery.optString("format"))||gallery.optInt("version")!=1||gallery.optInt("count",-1)!=documents.length())))throw new IOException("Gallery manifest identity/count does not match.");
            // Validation completes before activation. Never overwrite an existing private file.
            for (String path : actual.keySet()) {
                if(path.startsWith("animation-gallery/"))continue; // virtual documents go to IndexedDB only after file verification.
                File dest=resolve(root,path);
                if (dest.exists()) { skipped++; continue; }
                dest.getParentFile().mkdirs(); Files.move(resolve(stage,path).toPath(),dest.toPath()); installed.add(dest); restored++;
            }
            success=true;
            JSONObject result=new JSONObject().put("restored",restored).put("unchanged",skipped).put("bytes",total);
            if(gallery!=null)result.put("gallery",new JSONObject(gallery.toString()).put("documents",documents).put("verifiedFiles",true));
            return result;
        } finally {
            if (!success) for (File f : installed) f.delete(); // only files created by this restore; no overwrites occurred
            PublicStorage.removeTree(stage.toPath());
        }
    }
}
