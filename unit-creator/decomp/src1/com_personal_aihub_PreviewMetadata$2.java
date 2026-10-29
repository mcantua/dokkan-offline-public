package com.personal.aihub;
 class PreviewMetadata$2 implements com.personal.aihub.GameMetadata$Query {
    final synthetic java.io.File val$sparkingDatabase;

    PreviewMetadata$2(java.io.File p1)
    {
        this.val$sparkingDatabase = p1;
        return;
    }

    public org.json.JSONObject row(String p2, long p3)
    {
        return com.personal.aihub.PreviewMetadata.access$000(this.val$sparkingDatabase, p2, p3);
    }
}
