package com.personal.aihub;
public final class LaunchCoordinator {

    private LaunchCoordinator()
    {
        return;
    }

    public static com.personal.aihub.LaunchCoordinator$Result open(com.personal.aihub.Provider p0, boolean p1, com.personal.aihub.LaunchCoordinator$Platform p2)
    {
        if ((!p1) || (!p2.openApp(p0))) {
            com.personal.aihub.LaunchCoordinator$Result v0_3;
            if (!p2.openWebsite(p0)) {
                v0_3 = com.personal.aihub.LaunchCoordinator$Result.UNAVAILABLE;
            } else {
                v0_3 = com.personal.aihub.LaunchCoordinator$Result.WEBSITE;
            }
            return v0_3;
        } else {
            return com.personal.aihub.LaunchCoordinator$Result.APP;
        }
    }
}
