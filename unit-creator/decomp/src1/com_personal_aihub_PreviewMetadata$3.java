package com.personal.aihub;
 class PreviewMetadata$3 implements com.personal.aihub.GameMetadata$Query {
    final synthetic java.util.Set val$ids;
    final synthetic java.util.Map val$own;
    final synthetic com.personal.aihub.GameMetadata$Query val$project;
    final synthetic com.personal.aihub.GameMetadata$Query val$sparking;

    PreviewMetadata$3(java.util.Map p1, java.util.Set p2, com.personal.aihub.GameMetadata$Query p3, com.personal.aihub.GameMetadata$Query p4)
    {
        this.val$own = p1;
        this.val$ids = p2;
        this.val$sparking = p3;
        this.val$project = p4;
        return;
    }

    public org.json.JSONObject row(String p3, long p4)
    {
        if (p3.equals("effect_packs")) {
            if (!this.val$own.containsKey(Long.valueOf(p4))) {
                if (this.val$ids.contains(Long.valueOf(p4))) {
                    return this.val$sparking.row(p3, p4);
                }
            } else {
                return ((org.json.JSONObject) this.val$own.get(Long.valueOf(p4)));
            }
        }
        return this.val$project.row(p3, p4);
    }
}
