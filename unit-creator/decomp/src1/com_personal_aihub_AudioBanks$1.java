package com.personal.aihub;
 class AudioBanks$1 implements java.util.Comparator {
    final synthetic com.personal.aihub.AudioBanks this$0;

    AudioBanks$1(com.personal.aihub.AudioBanks p1)
    {
        this.this$0 = p1;
        return;
    }

    public final int compare(Object p1, Object p2)
    {
        return ((com.personal.aihub.AudioBanks$Candidate) p1).key.compareTo(((com.personal.aihub.AudioBanks$Candidate) p2).key);
    }
}
