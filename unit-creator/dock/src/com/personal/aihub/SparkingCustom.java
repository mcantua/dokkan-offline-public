package com.personal.aihub;

import java.util.Set;
import java.util.regex.Pattern;

/**
 * Tells Sparking's own custom-made content apart from the original game files that Sparking's server
 * also hosts. Only custom content is ever downloaded from Sparking; originals come from Eclipse.
 *
 * Content kinds that matter for units (everything else, like menus and shop pictures, is skipped):
 *   characters & transformations  character/..., card/..., thumb/..., card_transform/...
 *   moves, abilities, animations  lua/ab_script/..., ingame/battle/sp_effect, ingame/battle/effect
 *   effects & movies              ingame/..., movie/..., Custom/...
 *   stages & environments         ingame/battle/bg, dokkan_field/..., outgame/extension/dokkan_field
 *   music & voices                bgm/..., voice/..., se/...
 *
 * "Custom" = Eclipse doesn't have the same item: the first part of the path that carries an ID
 * (a character, effect, stage, card...) is looked up in Eclipse's file list for its folder; animation
 * scripts are looked up in Eclipse's script list. Sparking packs folders as ".cpk"; Eclipse serves the
 * same folder unpacked, so names are compared without their extension.
 */
final class SparkingCustom {
    private SparkingCustom() {}

    private static final Pattern CONTENT = Pattern.compile(
        "^(character/|card/|thumb/|card_transform/|card_category/|ingame/|movie/|lua/ab_script/|Custom/|dokkan_field/|outgame/extension/dokkan_field/|script/image/character/|bgm/|voice/|se/).+");
    private static final Pattern SUPPORTED = Pattern.compile(
        "(?i).+\\.(cpk|png|jpe?g|webp|lwf|lua|usm|acb|awb|json|atlas|plist|tmx|bytes|txt|ogg|mp3|wav)$");
    private static final Pattern SAFE = Pattern.compile("[A-Za-z0-9_./ -]{1,300}");

    interface Lister {
        /** Eclipse's names (without extension) in this folder; empty when Eclipse has no such folder. */
        Set<String> list(String folder) throws Exception;
    }

    static boolean content(String path) {
        return path != null && SAFE.matcher(path).matches() && !path.contains("..") && !path.startsWith("/") && CONTENT.matcher(path).matches();
    }

    static boolean supported(String path) {
        return SUPPORTED.matcher(path).matches();
    }

    static String stem(String name) {
        int dot = name.lastIndexOf('.');
        return dot > 0 ? name.substring(0, dot) : name;
    }

    /** {folder, name} of the part of the path that identifies the item. */
    static String[] idPart(String path) {
        String[] parts = path.split("/");
        for (int i = 1; i < parts.length; i++) {
            if (parts[i].matches(".*\\d.*")) {
                StringBuilder folder = new StringBuilder();
                for (int j = 0; j < i; j++) { if (j > 0) folder.append('/'); folder.append(parts[j]); }
                return new String[]{folder.toString(), stem(parts[i])};
            }
        }
        int slash = path.lastIndexOf('/');
        return new String[]{slash < 0 ? "" : path.substring(0, slash), stem(path.substring(slash + 1))};
    }

    /** True when the file is Sparking's own; false when Eclipse already has the original. */
    static boolean custom(String path, Set<String> eclipseScripts, Lister eclipse) throws Exception {
        if (path.startsWith("Custom/")) return true;
        if (path.startsWith("lua/")) return !eclipseScripts.contains(path.substring(4));
        String[] id = idPart(path);
        return !eclipse.list(id[0]).contains(id[1]);
    }
}
