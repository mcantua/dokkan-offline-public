#import "ODDuoLauncherPrivate.h"
#import "ODDuoAccountController.h"
#import "ODCreatorController.h"
#import "ODLocalHost.h"

@interface ODLocalHost (LauncherSetup)
- (void)importMaster;
@end

@implementation ODDuoLauncher (SavedAccount)
- (void)attachSavedAccountHostIfNeeded {
    ODLocalHost *host = self.savedAccountHost;
    if (!host) return;
    __weak ODDuoLauncher *weakSelf = self;
    host.savedAccountChanged = ^{ [weakSelf noteSavedAccountChanged]; };
    [self addChildViewController:host];
    UIView *hidden = host.view;
    hidden.hidden = YES;
    hidden.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    hidden.frame = self.view.bounds;
    [self.view insertSubview:hidden atIndex:0];
    [host didMoveToParentViewController:self];
}
- (void)noteSavedAccountChanged {
    ODLocalHost *host = self.savedAccountHost;
    if (!host) return;
    if (self.openCreatorWhenReady && [host.snapshot isKindOfClass:NSDictionary.class] && !host.savedAccountBusy) {
        self.openCreatorWhenReady = NO;
        [host openCreator];
        if ([host.presentedViewController isKindOfClass:ODCreatorController.class]) self.creatorController = (ODCreatorController *)host.presentedViewController;
        return;
    }
    ODDuoAccountController *account = self.accountController;
    if (!account) return;
    if ([host.snapshot isKindOfClass:NSDictionary.class]) {
        account.setupGameData = nil;
        [account applySnapshot:host.snapshot error:nil];
        return;
    }
    if (!self.creatingAccount && [host.lastError isEqualToString:@"PROFILE_NOT_FOUND"] && !host.savedAccountBusy) {
        self.creatingAccount = YES;
        [host createPlayer];
        return;
    }
    if (host.savedAccountBusy && !host.lastError.length) return;
    BOOL needsData = [host.lastError isEqualToString:@"DATA_SOURCE_SELECTION_REQUIRED"];
    __weak ODLocalHost *weakHost = host;
    account.setupGameData = needsData ? ^{ [weakHost importMaster]; } : nil;
    [account applySnapshot:nil error:host.lastError];
}
- (BOOL)openSavedAccountCreator {
    ODLocalHost *host = self.savedAccountHost;
    if (!host) return NO;
    if ([host.snapshot isKindOfClass:NSDictionary.class] && !host.savedAccountBusy) {
        [host openCreator];
        if ([host.presentedViewController isKindOfClass:ODCreatorController.class]) self.creatorController = (ODCreatorController *)host.presentedViewController;
        return YES;
    }
    if (!host.savedAccountBusy && [host.lastError isEqualToString:@"PROFILE_NOT_FOUND"]) {
        self.creatingAccount = YES;
        self.openCreatorWhenReady = YES;
        [host createPlayer];
        return YES;
    }
    return YES;
}
- (instancetype)initWithLibraryDirectory:(NSURL *)library saveDirectory:(NSURL *)saves {
    self = [self initWithCore:nil masterURL:nil contentID:nil game:nil creatorDirectory:nil];
    if (self) self.savedAccountHost = [[ODLocalHost alloc] initWithLibraryDirectory:library saveDirectory:saves];
    return self;
}
#if OD_CLOUD_FIXTURES
- (instancetype)initWithDatabaseDirectory:(NSURL *)databases contentIdentities:(NSArray<NSString *> *)contentIdentities saveDirectory:(NSURL *)saves {
    self = [self initWithCore:nil masterURL:nil contentID:nil game:nil creatorDirectory:nil];
    if (self) self.savedAccountHost = [[ODLocalHost alloc] initWithDatabaseDirectory:databases contentIdentities:contentIdentities saveDirectory:saves];
    return self;
}
#endif
@end
