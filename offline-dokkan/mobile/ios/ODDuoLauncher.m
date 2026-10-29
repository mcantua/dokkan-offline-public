#import "ODDuoLauncherPrivate.h"
#import "ODDuoAccountController.h"
#import "ODDuoChrome.h"
#import "ODCreatorController.h"
#import "ODCreatorSession.h"
#import "../../adapter/ios/ODNativeCore.h"

@implementation ODDuoLauncher
- (instancetype)initWithCore:(ODNativeCore *)core masterURL:(NSURL *)master contentID:(NSString *)contentID game:(NSString *)game creatorDirectory:(NSURL *)directory {
    if ((self = [super init])) {
        _core = core;
        _masterURL = master;
        _contentID = [contentID copy];
        _game = [game copy];
        _creatorDirectory = directory;
    }
    return self;
}
- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ODDuoColor(0x0a1029);
    self.view.accessibilityIdentifier = @"duo-launcher";
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    UILabel *eyebrow = ODDuoLabel(@"CHOOSE", ODDuoTextFont(13), ODDuoColor(0xffcf6b));
    UILabel *title = ODDuoLabel(@"Dokkan", ODDuoDisplayFont(64), UIColor.whiteColor);
    UILabel *subtitle = ODDuoLabel(@"What do you want to open?", ODDuoTextFont(16), ODDuoColor(0xa9b5d6));
    UIButton *offline = ODDuoChoiceButton(@"Offline Dokkan", @"Your saved account", @"duo-open-offline");
    UIButton *creator = ODDuoChoiceButton(@"Unit Creator", @"Create a unit or edit your units", @"duo-open-creator");
    [offline addTarget:self action:@selector(openOfflineDokkan) forControlEvents:UIControlEventTouchUpInside];
    [creator addTarget:self action:@selector(openUnitCreator) forControlEvents:UIControlEventTouchUpInside];
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[eyebrow, title, subtitle, offline, creator]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 18;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [stack setCustomSpacing:8 afterView:eyebrow];
    [stack setCustomSpacing:28 afterView:subtitle];
    UIButtonConfiguration *creatorLook = creator.configuration;
    UIBackgroundConfiguration *creatorBackground = creatorLook.background;
    creatorBackground.backgroundColor = ODDuoColor(0x2f7cff);
    creatorBackground.strokeColor = ODDuoColor(0x0b3c8c);
    creatorLook.background = creatorBackground;
    creatorLook.baseForegroundColor = UIColor.whiteColor;
    creatorLook.subtitleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey, id> *(NSDictionary<NSAttributedStringKey, id> *incoming) {
        NSMutableDictionary *next = [incoming mutableCopy];
        next[NSFontAttributeName] = ODDuoTextFont(13);
        next[NSForegroundColorAttributeName] = UIColor.whiteColor;
        return next;
    };
    creator.configuration = creatorLook;
    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];
    [scroll addSubview:stack];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:36],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-28],
        [stack.centerXAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.centerXAnchor],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-36]
    ]];
    if ([self respondsToSelector:@selector(attachSavedAccountHostIfNeeded)]) [self attachSavedAccountHostIfNeeded];
}
- (void)refreshOwnedCore {
    if (!self.core || !self.accountController) return;
    __weak ODDuoLauncher *weakSelf = self;
    [self.core execute:@"profile.refresh" profile:@"local-player" command:NSUUID.UUID.UUIDString arguments:@{} reply:^(id result, NSError *error) {
        ODDuoLauncher *me = weakSelf;
        if (!me.accountController) return;
        if (error && [error.localizedDescription isEqualToString:@"PROFILE_NOT_FOUND"]) {
            [me.core execute:@"profile.create" profile:@"local-player" command:NSUUID.UUID.UUIDString arguments:@{} reply:^(id created, NSError *createError) {
                NSDictionary *snapshot = [created isKindOfClass:NSDictionary.class] ? created : nil;
                [me.accountController applySnapshot:snapshot error:createError.localizedDescription];
            }];
            return;
        }
        NSDictionary *snapshot = [result isKindOfClass:NSDictionary.class] ? result : nil;
        [me.accountController applySnapshot:snapshot error:error.localizedDescription];
    }];
}
- (void)openOfflineDokkan {
    if (self.presentedViewController) return;
    ODDuoAccountController *account = [ODDuoAccountController new];
    self.accountController = account;
    [self presentViewController:account animated:NO completion:^{
        if ([self respondsToSelector:@selector(noteSavedAccountChanged)]) [self noteSavedAccountChanged];
        [self refreshOwnedCore];
    }];
}
- (void)openUnitCreator {
    void (^show)(void) = ^{
        self.accountController = nil;
        if ([self respondsToSelector:@selector(openSavedAccountCreator)] && [self openSavedAccountCreator]) return;
        if (!self.core || !self.masterURL || !self.contentID.length || !self.game.length || !self.creatorDirectory) return;
        ODCreatorSession *session = [[ODCreatorSession alloc] initWithMasterURL:self.masterURL contentID:self.contentID game:self.game directory:self.creatorDirectory core:self.core];
        ODCreatorController *creator = [[ODCreatorController alloc] initWithSession:session completion:^{}];
        creator.closeButtonTitle = @"Back";
        self.creatorController = creator;
        [self presentViewController:creator animated:NO completion:nil];
    };
    if (self.presentedViewController) [self dismissViewControllerAnimated:NO completion:show];
    else show();
}
@end
