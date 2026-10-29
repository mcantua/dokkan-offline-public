package com.personal.aihub;
 class PreviewMetadata$1 implements com.personal.aihub.GameMetadata$Query {
    final synthetic java.io.File val$database;

    PreviewMetadata$1(java.io.File p1)
    {
        this.val$database = p1;
        return;
    }

    public org.json.JSONObject row(String p2, long p3)
    {
        return com.personal.aihub.PreviewMetadata.access$000(this.val$database, p2, p3);
    }
}
