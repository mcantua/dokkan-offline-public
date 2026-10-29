package com.personal.aihub;
final class AudioBanks$Identity {
    String kind;
    String locale;
    String pkg;

    AudioBanks$Identity(String p1, String p2, String p3)
    {
        this.kind = p1;
        this.pkg = p2;
        this.locale = p3;
        return;
    }

    String logical()
    {
        String v0_1 = new StringBuilder();
        v0_1.append(String.valueOf(this.kind));
        v0_1.append("|");
        v0_1.append(this.locale);
        v0_1.append("|");
        v0_1.append(java.text.Normalizer.normalize(this.pkg, java.text.Normalizer$Form.NFC).toLowerCase(java.util.Locale.ROOT));
        return v0_1.toString();
    }
}
