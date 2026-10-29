package com.personal.aihub;
public final class GameBgm {
    private static final String SQL = "SELECT DISTINCT f.bgm_id AS id FROM finish_skill_sets f JOIN special_views v ON v.id=f.special_view_id WHERE v.script_name=? LIMIT 3";

    public GameBgm()
    {
        return;
    }

    public static org.json.JSONObject context(android.database.sqlite.SQLiteDatabase p11, String p12)
    {
        org.json.JSONObject v0_3 = new org.json.JSONObject().put("version", 1).put("found", 0);
        if ((p12 != null) && (p12.matches("ab_script/finish_skill/[A-Za-z0-9_]{1,80}\\.lua"))) {
            try {
                Throwable v11_1 = p11.rawQuery("SELECT DISTINCT f.bgm_id AS id FROM finish_skill_sets f JOIN special_views v ON v.id=f.special_view_id WHERE v.script_name=? LIMIT 3", new String[] {p12.substring((p12.lastIndexOf(47) + 1), (p12.length() - 4))}));
                try {
                    if (v11_1.getCount() == 1) {
                        v11_1.moveToFirst();
                        Object[] v5_4 = v11_1.getLong(0);
                        if ((v5_4 <= 0) || ((v5_4 > 2147483647) || (v11_1.getDouble(0) != ((double) v5_4)))) {
                            throw new java.io.IOException("Invalid game music context");
                        } else {
                            org.json.JSONObject v12_5 = v0_3.put("found", 1).put("scriptPath", p12).put("id", v5_4).put("package", String.format(java.util.Locale.ROOT, "bgm_%03d", new Object[] {Long.valueOf(v5_4)})));
                            if (v11_1 != null) {
                                v11_1.close();
                            }
                            return v12_5;
                        }
                    } else {
                        org.json.JSONObject v12_7;
                        if (v11_1.getCount() != 0) {
                            v12_7 = "This move has multiple different music contexts.";
                        } else {
                            v12_7 = "This move has no music selected in the imported game database.";
                        }
                        org.json.JSONObject v12_9 = v0_3.put("reason", v12_7);
                        if (v11_1 != null) {
                            v11_1.close();
                        }
                        return v12_9;
                    }
                } catch (org.json.JSONObject v12_8) {
                    if (v11_1 != null) {
                        try {
                            v11_1.close();
                        } catch (Throwable v11_2) {
                            v12_8.addSuppressed(v11_2);
                        }
                    }
                    throw v12_8;
                }
            } catch (Exception) {
                return v0_3.put("reason", "The imported game database cannot resolve this move\u2019s music.");
            }
        } else {
            return v0_3.put("reason", "This preview has no verified finish-skill music context.");
        }
    }

    public static String[] source(java.io.File p4, com.personal.aihub.GameAssets p5, org.json.JSONObject p6)
    {
        char v0_1 = p6.optString("package");
        if ((p6.optBoolean("found")) && (v0_1.matches("bgm_[0-9]{3,10}"))) {
            String v6_3 = new StringBuilder("/assets/bgm/");
            v6_3.append(v0_1);
            v6_3.append(".acb");
            String v6_5 = p5.resolve(v6_3.toString());
            StringBuilder v3_2 = new StringBuilder("/assets/bgm/");
            v3_2.append(v0_1);
            v3_2.append(".awb");
            String v5_1 = p5.resolve(v3_2.toString());
            if ((v6_5 != null) || (v5_1 != null)) {
                if ((v6_5 == null) || (v5_1 == null)) {
                    throw new java.io.IOException("Imported move music is missing its matching cue sheet or waveform bank. Import the complete music pair.");
                } else {
                    if (!v6_5.getParentFile().equals(v5_1.getParentFile())) {
                        throw new java.io.IOException("Imported move music must use a cue sheet and waveform from the same collection and folder.");
                    } else {
                        String[] v4_6 = p4.getCanonicalFile().toPath();
                        String v6_10 = v4_6.relativize(v6_5.toPath()).toString().replace(java.io.File.separatorChar, 47);
                        String[] v4_9 = v4_6.relativize(v5_1.toPath()).toString().replace(java.io.File.separatorChar, 47);
                        if ((!com.personal.aihub.GameAssets.safe(v6_10)) || (!com.personal.aihub.GameAssets.safe(v4_9))) {
                            throw new java.io.IOException("Invalid imported music resource");
                        } else {
                            return new String[] {v6_10, v4_9});
                        }
                    }
                }
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }
}
