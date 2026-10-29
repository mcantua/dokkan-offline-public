package com.personal.aihub;
 class CreatorActivity$Bridge$1 implements java.lang.Runnable {
    final synthetic com.personal.aihub.CreatorActivity$Bridge this$1;
    final synthetic int val$i;
    final synthetic org.json.JSONObject val$jSONObjectOptJSONObject;
    final synthetic String val$string;

    CreatorActivity$Bridge$1(com.personal.aihub.CreatorActivity$Bridge p1, int p2, String p3, org.json.JSONObject p4)
    {
        this.this$1 = p1;
        this.val$i = p2;
        this.val$string = p3;
        this.val$jSONObjectOptJSONObject = p4;
        return;
    }

    public final void run()
    {
        this.this$1.m20lambda$1$compersonalaihubCreatorActivity$Bridge(this.val$i, this.val$string, this.val$jSONObjectOptJSONObject);
        return;
    }
}
