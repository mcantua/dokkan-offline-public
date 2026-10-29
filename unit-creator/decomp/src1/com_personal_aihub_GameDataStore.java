package com.personal.aihub;
final class GameDataStore {
    private final java.io.File directory;
    private final java.io.File pointer;
    private final java.io.File reference;
    private final java.io.File root;

    GameDataStore(java.io.File p2, java.io.File p3)
    {
        this.root = p2;
        this.reference = p3;
        java.io.File v3_3 = new java.io.File(p2, "databases");
        this.directory = v3_3;
        v3_3.mkdirs();
        this.pointer = new java.io.File(p2, "database-state.json");
        return;
    }

    static String hash(java.io.File p6)
    {
        Throwable v0_2 = java.security.MessageDigest.getInstance("SHA-256");
        int v1_2 = new java.io.FileInputStream(p6);
        try {
            String v6_6 = new byte[65536];
        } catch (String v6_1) {
            try {
                v1_2.close();
            } catch (Throwable v0_1) {
                v6_1.addSuppressed(v0_1);
            }
            throw v6_1;
        }
        while(true) {
            String v2_5 = v1_2.read(v6_6);
            int v4 = 0;
            if (v2_5 == -1) {
                break;
            }
            v0_2.update(v6_6, 0, v2_5);
        }
        v1_2.close();
        String v6_3 = new StringBuilder();
        Throwable v0_3 = v0_2.digest();
        int v1_0 = v0_3.length;
        while (v4 < v1_0) {
            v6_3.append(String.format(java.util.Locale.ROOT, "%02x", new Object[] {Integer.valueOf((v0_3[v4] & 255))})));
            v4++;
        }
        return v6_3.toString();
    }

    private void prune()
    {
        try {
            int v2_1 = this.state();
            java.util.HashSet v3_1 = new java.util.HashSet();
            v3_1.add(v2_1.getJSONObject("active").getString("file"));
        } catch (Exception) {
            return;
        }
        if (v2_1.optJSONObject("previous") != null) {
            v3_1.add(v2_1.getJSONObject("previous").getString("file"));
        }
        java.io.File[] v0_4 = this.directory.listFiles();
        if (v0_4 == null) {
            return;
        } else {
            int v1_1 = v0_4.length;
            int v2_0 = 0;
            while (v2_0 < v1_1) {
                java.io.File v4_2 = v0_4[v2_0];
                if ((v4_2.getName().matches("db-[a-f0-9]{64}\\.db")) && (!v3_1.contains(v4_2.getName()))) {
                    v4_2.delete();
                }
                v2_0++;
            }
            return;
        }
    }

    private org.json.JSONObject slot(java.io.File p9, org.json.JSONObject p10)
    {
        org.json.JSONObject v1_0 = this.directory;
        java.io.File v2_7 = new StringBuilder("stage-");
        v2_7.append(java.util.UUID.randomUUID());
        java.io.File v0_1 = new java.io.File(v1_0, v2_7.toString());
        try {
            org.json.JSONObject v1_2 = new java.io.FileInputStream(p9);
            try {
                java.io.IOException v9_2 = new java.io.FileOutputStream(v0_1);
                try {
                    java.io.File v2_1 = new byte[65536];
                    String v3_0 = 0;
                } catch (String v10_7) {
                    try {
                        v9_2.close();
                    } catch (java.io.IOException v9_9) {
                        v10_7.addSuppressed(v9_9);
                    }
                    throw v10_7;
                }
                while(true) {
                    int v5 = v1_2.read(v2_1);
                    if (v5 == -1) {
                        v9_2.getFD().sync();
                        v9_2.close();
                        v1_2.close();
                        java.io.IOException v9_3 = com.personal.aihub.GameDataStore.hash(v0_1);
                        org.json.JSONObject v1_4 = new StringBuilder();
                        v1_4.append("db-");
                        v1_4.append(v9_3);
                        v1_4.append(".db");
                        org.json.JSONObject v1_5 = v1_4.toString();
                        java.io.File v2_8 = new java.io.File(this.directory, v1_5);
                        if (!v2_8.exists()) {
                            if (!v0_1.renameTo(v2_8)) {
                                throw new java.io.IOException("Could not stage database");
                            } else {
                            }
                        }
                        java.io.IOException v9_8 = new org.json.JSONObject().put("file", v1_5).put("meta", new org.json.JSONObject(p10.toString()).put("sha256", v9_3).put("bytes", v2_8.length()));
                        v0_1.delete();
                        return v9_8;
                    } else {
                        v3_0 += ((long) v5);
                        if (v3_0 > 536870912) {
                            break;
                        }
                        v9_2.write(v2_1, 0, v5);
                    }
                }
                throw new java.io.IOException("Database exceeds 512 MB");
            } catch (java.io.IOException v9_10) {
                try {
                    v1_2.close();
                } catch (String v10_8) {
                    v9_10.addSuppressed(v10_8);
                }
                throw v9_10;
            }
        } catch (java.io.IOException v9_11) {
            v0_1.delete();
            throw v9_11;
        }
    }

    private static String text(java.io.File p4)
    {
        if (p4.length() > 1048576) {
            throw new java.io.IOException("Database state is too large");
        } else {
            Throwable v0_1 = new java.io.FileInputStream(p4);
            try {
                Throwable v4_2 = new java.io.ByteArrayOutputStream();
                try {
                    String v1_1 = new byte[8192];
                } catch (String v1_4) {
                    try {
                        v4_2.close();
                    } catch (Throwable v4_3) {
                        v1_4.addSuppressed(v4_3);
                    }
                    throw v1_4;
                }
                while(true) {
                    int v2_0 = v0_1.read(v1_1);
                    if (v2_0 == -1) {
                        break;
                    }
                    v4_2.write(v1_1, 0, v2_0);
                }
                String v1_3 = v4_2.toString("UTF-8");
                v4_2.close();
                v0_1.close();
                return v1_3;
            } catch (Throwable v4_4) {
                try {
                    v0_1.close();
                } catch (Throwable v0_3) {
                    v4_4.addSuppressed(v0_3);
                }
                throw v4_4;
            }
        }
    }

    private void write(org.json.JSONObject p4)
    {
        Throwable v1_4 = new StringBuilder();
        v1_4.append(this.pointer.getPath());
        v1_4.append(".tmp");
        java.io.File v0_1 = new java.io.File(v1_4.toString());
        try {
            Throwable v1_3 = new java.io.FileOutputStream(v0_1);
            try {
                v1_3.write(p4.toString().getBytes("UTF-8"));
                v1_3.getFD().sync();
            } catch (java.io.IOException v4_4) {
                try {
                    v1_3.close();
                } catch (Throwable v1_5) {
                    v4_4.addSuppressed(v1_5);
                }
                throw v4_4;
            }
            v1_3.close();
            if (!v0_1.renameTo(this.pointer)) {
                throw new java.io.IOException("Could not activate the database; previous data was kept");
            } else {
                v0_1.delete();
                return;
            }
        } catch (java.io.IOException v4_9) {
            v0_1.delete();
            throw v4_9;
        }
    }

    declared_synchronized void commit(java.io.File p5, org.json.JSONObject p6)
    {
        try {
            org.json.JSONObject v0_0 = this.state();
            Throwable v5_2 = new org.json.JSONObject().put("version", 1).put("active", this.slot(p5, p6));
        } catch (Throwable v5_3) {
            throw v5_3;
        }
        if (v0_0 == null) {
            if (this.current().isFile()) {
                v5_2.put("previous", this.slot(this.current(), this.meta()));
            }
        } else {
            v5_2.put("previous", v0_0.getJSONObject("active"));
        }
        this.write(v5_2);
        this.prune();
        return;
    }

    java.io.File current()
    {
        java.io.File v0_0 = this.state();
        if (v0_0 == null) {
            java.io.File v0_1 = new java.io.File(this.root, "database.db");
            if (!v0_1.exists()) {
                v0_1 = this.reference;
            }
            return v0_1;
        } else {
            return this.file(v0_0.getJSONObject("active"));
        }
    }

    java.io.File file(org.json.JSONObject p3)
    {
        java.io.IOException v3_1 = p3.getString("file");
        if (!v3_1.matches("db-[a-f0-9]{64}\\.db")) {
            throw new java.io.IOException("Invalid stored database name");
        } else {
            return new java.io.File(this.directory, v3_1);
        }
    }

    org.json.JSONObject meta()
    {
        org.json.JSONObject v0_0 = this.state();
        if (v0_0 == null) {
            org.json.JSONObject v1_2;
            org.json.JSONObject v0_8 = new java.io.File(this.root, "database-meta.json");
            if (!v0_8.exists()) {
                v1_2 = new org.json.JSONObject().put("source", "Bundled Eclipse English snapshot \u00b7 2026-10-14").put("date", "2026-10-14");
            } else {
                v1_2 = new org.json.JSONObject(com.personal.aihub.GameDataStore.text(v0_8));
            }
            return v1_2;
        } else {
            return v0_0.getJSONObject("active").getJSONObject("meta");
        }
    }

    declared_synchronized void restore()
    {
        try {
            org.json.JSONObject v0_0 = this.state();
        } catch (org.json.JSONObject v0_1) {
            throw v0_1;
        }
        if ((v0_0 == null) || (v0_0.optJSONObject("previous") == null)) {
            throw new java.io.IOException("No previous database is available");
        } else {
            this.write(new org.json.JSONObject().put("version", 1).put("active", v0_0.getJSONObject("previous")).put("previous", v0_0.getJSONObject("active")));
            return;
        }
    }

    org.json.JSONObject state()
    {
        if (this.pointer.exists()) {
            java.io.IOException v0_6 = new org.json.JSONObject(com.personal.aihub.GameDataStore.text(this.pointer));
            if (v0_6.optInt("version") != 1) {
                throw new java.io.IOException("Unsupported database state");
            } else {
                this.file(v0_6.getJSONObject("active"));
                if (v0_6.optJSONObject("previous") != null) {
                    this.file(v0_6.getJSONObject("previous"));
                }
                return v0_6;
            }
        } else {
            return 0;
        }
    }
}
