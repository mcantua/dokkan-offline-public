package com.personal.aihub;
 class CreatorActivity$10 implements java.util.Comparator {
    final synthetic com.personal.aihub.CreatorActivity this$0;
    final synthetic java.util.HashMap val$originalNames;

    CreatorActivity$10(com.personal.aihub.CreatorActivity p1, java.util.HashMap p2)
    {
        this.this$0 = p1;
        this.val$originalNames = p2;
        return;
    }

    public int compare(java.io.File p2, java.io.File p3)
    {
        return Integer.compare(com.personal.aihub.CreatorActivity.access$400(((String) this.val$originalNames.get(p3))), com.personal.aihub.CreatorActivity.access$400(((String) this.val$originalNames.get(p2))));
    }

    public bridge synthetic int compare(Object p1, Object p2)
    {
        return this.compare(((java.io.File) p1), ((java.io.File) p2));
    }
}
