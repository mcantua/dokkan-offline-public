package com.personal.aihub;

import java.io.File;
import java.io.FileOutputStream;
import java.lang.reflect.Method;
import java.util.*;
import java.util.regex.*;

public class OfflineTest {
    public static void main(String[] a) throws Exception {
        File root = new File(a[0]);
        PreviewCache cache = new PreviewCache(root);
        File cacheRoot = new File(root, "preview-cache");
        String[] urls = {
            "https://dokkan-eclipse.com/api/effect-pack/1?enemy=0",
            "https://dokkan-eclipse.com/api/effect-pack/1?enemy=1",
            "https://dokkan-eclipse.com/api/card/1020460",
            "https://dokkan-eclipse.com/api/card/1020460/fit/sp_name.png?w=1024&h=256&v=3",
            "https://dokkan-eclipse.com/assets/ingame/battle/character/01107/battle/lwf_image0.png",
            "https://dokkan-eclipse.com/api/file-browser?path=" + java.net.URLEncoder.encode("ingame/battle/character/01107/battle", "UTF-8"),
            "https://dokkan-eclipse.com/api/se?cue=10016",
            "https://dokkan-eclipse.com/cdn/uncompressed/character/thumb/card_1020460_thumb/card_1020460_thumb.png"};
        int ok = 0;
        for (String url : urls) {
            String key = OfflineLibrary.normalized(url);
            Method base = OfflineLibrary.class.getDeclaredMethod("base", File.class, String.class);
            base.setAccessible(true);
            File b = (File) base.invoke(null, cacheRoot, key);
            new FileOutputStream(b + ".body").close();
            FileOutputStream m = new FileOutputStream(b + ".json"); m.write(("{\"url\":\"" + key + "\",\"type\":\"image/png\"}").getBytes()); m.close();
            boolean seen = cache.cachedBody(url) != null && OfflineLibrary.savedBody(cacheRoot, url) != null;
            // the player asks with cache-busting parameters; they must hit the same file
            boolean bust = cache.cachedBody(url + (url.contains("?") ? "&" : "?") + "_=123") != null;
            System.out.println((seen ? "OK  " : "BAD ") + (bust ? "bust-ok " : "bust-miss ") + key);
            if (seen) ok++;
        }
        System.out.println("cache keys compatible: " + ok + "/" + urls.length);
        // script parsing
        String lua = "SP_01=\t155926\t;--x\nSE_01 = 1007;\npannti_f = entryEffect( spep_0 + 0, SP_01, 0x100, -1, 0, 0, 0 );\n" +
            "speff = entryEffect( spep_0  , 1504, 0x100, -1, 0, 0, 0 );\nctgogo = entryEffectLife( spep_0 +12, 190006, 72, 0x100, -1, 0, 50, 510);\n" +
            "kaihi = entryEffectUnpausable( SP_dodge,   1575,  0x100, -1, 0, 0, 350, 1100 );\nplaySe( spep_0 + 4, SE_01 );\nplaySe(math.floor(x), 1023);\n" +
            "x = entryEffect( f(1,2), 77, 0 );";
        Field[] dummy = null;
        Pattern c = field("CONSTANT"), e = field("EFFECT_CALL"), s = field("SOUND_CALL");
        Map<String, Long> consts = new HashMap<>();
        Matcher m = c.matcher(lua); while (m.find()) consts.put(m.group(1), Long.parseLong(m.group(2)));
        List<String> effects = new ArrayList<>(), sounds = new ArrayList<>();
        m = e.matcher(lua); while (m.find()) effects.add(m.group(2));
        m = s.matcher(lua); while (m.find()) sounds.add(m.group(2));
        System.out.println("constants " + consts + "\neffects " + effects + "\nsounds " + sounds);
        System.out.println("folderOf " + OfflineLibrary.Job.folderOf("ingame/battle/character/01107/battle/battle_character_01107.lwf"));
    }
    static Pattern field(String n) throws Exception { java.lang.reflect.Field f = OfflineLibrary.class.getDeclaredField(n); f.setAccessible(true); return (Pattern) f.get(null); }
    static class Field {}
}
