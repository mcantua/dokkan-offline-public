package com.personal.aihub;
public final enum class LaunchCoordinator$Result extends java.lang.Enum {
    private static final synthetic com.personal.aihub.LaunchCoordinator$Result[] $VALUES;
    public static final enum com.personal.aihub.LaunchCoordinator$Result APP;
    public static final enum com.personal.aihub.LaunchCoordinator$Result UNAVAILABLE;
    public static final enum com.personal.aihub.LaunchCoordinator$Result WEBSITE;

    private static synthetic com.personal.aihub.LaunchCoordinator$Result[] $values()
    {
        return new com.personal.aihub.LaunchCoordinator$Result[] {com.personal.aihub.LaunchCoordinator$Result.APP, com.personal.aihub.LaunchCoordinator$Result.WEBSITE, com.personal.aihub.LaunchCoordinator$Result.UNAVAILABLE});
    }

    static LaunchCoordinator$Result()
    {
        com.personal.aihub.LaunchCoordinator$Result.APP = new com.personal.aihub.LaunchCoordinator$Result("APP", 0);
        com.personal.aihub.LaunchCoordinator$Result.WEBSITE = new com.personal.aihub.LaunchCoordinator$Result("WEBSITE", 1);
        com.personal.aihub.LaunchCoordinator$Result.UNAVAILABLE = new com.personal.aihub.LaunchCoordinator$Result("UNAVAILABLE", 2);
        com.personal.aihub.LaunchCoordinator$Result.$VALUES = com.personal.aihub.LaunchCoordinator$Result.$values();
        return;
    }

    private LaunchCoordinator$Result(String p1, int p2)
    {
        super(p1, p2);
        return;
    }

    public static com.personal.aihub.LaunchCoordinator$Result valueOf(String p1)
    {
        return ((com.personal.aihub.LaunchCoordinator$Result) Enum.valueOf(com.personal.aihub.LaunchCoordinator$Result, p1));
    }

    public static com.personal.aihub.LaunchCoordinator$Result[] values()
    {
        return ((com.personal.aihub.LaunchCoordinator$Result[]) com.personal.aihub.LaunchCoordinator$Result.$VALUES.clone());
    }

    public static com.personal.aihub.LaunchCoordinator$Result[] valuesCustom()
    {
        com.personal.aihub.LaunchCoordinator$Result[] v0 = com.personal.aihub.LaunchCoordinator$Result.values();
        int v1 = v0.length;
        com.personal.aihub.LaunchCoordinator$Result[] v2 = new com.personal.aihub.LaunchCoordinator$Result[v1];
        System.arraycopy(v0, 0, v2, 0, v1);
        return v2;
    }
}
