package com.personal.aihub;
public final enum class Provider extends java.lang.Enum {
    private static final synthetic com.personal.aihub.Provider[] $VALUES;
    public static final enum com.personal.aihub.Provider CHATGPT;
    public static final enum com.personal.aihub.Provider CLAUDE;
    public static final enum com.personal.aihub.Provider GROK;
    public final String color;
    public final String description;
    public final String label;
    public final String mark;
    public final String packageName;
    public final String website;

    private static synthetic com.personal.aihub.Provider[] $values()
    {
        return new com.personal.aihub.Provider[] {com.personal.aihub.Provider.CHATGPT, com.personal.aihub.Provider.GROK, com.personal.aihub.Provider.CLAUDE});
    }

    static Provider()
    {
        String v9_0 = new com.personal.aihub.Provider;
        v9_0("CHATGPT", 0, "ChatGPT", "com.openai.chatgpt", "https://chatgpt.com/", "Think, create, and explore.", "#76D8B1", "G");
        com.personal.aihub.Provider.CHATGPT = v9_0;
        com.personal.aihub.Provider[] v0_0 = new com.personal.aihub.Provider;
        v0_0("GROK", 1, "Grok", "ai.x.grok", "https://grok.com/", "A fresh perspective on anything.", "#CCD5EF", "X");
        com.personal.aihub.Provider.GROK = v0_0;
        com.personal.aihub.Provider[] v0_1 = new com.personal.aihub.Provider;
        v0_1("CLAUDE", 2, "Claude", "com.anthropic.claude", "https://claude.ai/", "Make room for your next idea.", "#E9AA8D", "C");
        com.personal.aihub.Provider.CLAUDE = v0_1;
        com.personal.aihub.Provider.$VALUES = com.personal.aihub.Provider.$values();
        return;
    }

    private Provider(String p1, int p2, String p3, String p4, String p5, String p6, String p7, String p8)
    {
        super(p1, p2);
        super.label = p3;
        super.packageName = p4;
        super.website = p5;
        super.description = p6;
        super.color = p7;
        super.mark = p8;
        return;
    }

    public static com.personal.aihub.Provider valueOf(String p1)
    {
        return ((com.personal.aihub.Provider) Enum.valueOf(com.personal.aihub.Provider, p1));
    }

    public static com.personal.aihub.Provider[] values()
    {
        return ((com.personal.aihub.Provider[]) com.personal.aihub.Provider.$VALUES.clone());
    }

    public static com.personal.aihub.Provider[] valuesCustom()
    {
        com.personal.aihub.Provider[] v0 = com.personal.aihub.Provider.values();
        int v1 = v0.length;
        com.personal.aihub.Provider[] v2 = new com.personal.aihub.Provider[v1];
        System.arraycopy(v0, 0, v2, 0, v1);
        return v2;
    }
}
