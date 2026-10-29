#import "ODDuoAccountController.h"
#import "ODDuoChrome.h"

@implementation ODDuoAccountController {
    UILabel *_title, *_detail, *_note;
    UIButton *_setup, *_back;
    UIStackView *_stack;
}
- (instancetype)init {
    if ((self = [super init])) self.modalPresentationStyle = UIModalPresentationFullScreen;
    return self;
}
- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ODDuoColor(0x0a1029);
    self.view.accessibilityIdentifier = @"duo-account";
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    UILabel *eyebrow = ODDuoLabel(@"OFFLINE DOKKAN", ODDuoTextFont(13), ODDuoColor(0xffcf6b));
    _title = ODDuoLabel(@"Opening your saved account…", ODDuoDisplayFont(48), UIColor.whiteColor);
    _title.accessibilityIdentifier = @"duo-account-name";
    _detail = ODDuoLabel(@"", ODDuoTextFont(18), ODDuoColor(0xf1f4ff));
    _detail.accessibilityIdentifier = @"duo-account-characters";
    _note = ODDuoLabel(@"This is your saved Offline Dokkan account on this device.", ODDuoTextFont(14), ODDuoColor(0xa9b5d6));
    _setup = ODDuoChoiceButton(@"Set up game data", @"Needed before this account can open", @"duo-account-setup");
    _setup.hidden = YES;
    [_setup addTarget:self action:@selector(setupTapped) forControlEvents:UIControlEventTouchUpInside];
    _back = ODDuoChoiceButton(@"Launcher", @"Choose again", @"duo-account-back");
    UIButtonConfiguration *back = _back.configuration;
    UIBackgroundConfiguration *backBackground = back.background;
    backBackground.backgroundColor = ODDuoColor(0x16224d);
    backBackground.strokeColor = ODDuoColor(0x34489a);
    back.background = backBackground;
    back.baseForegroundColor = ODDuoColor(0xe7ecff);
    back.subtitleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey, id> *(NSDictionary<NSAttributedStringKey, id> *incoming) {
        NSMutableDictionary *next = [incoming mutableCopy];
        next[NSFontAttributeName] = ODDuoTextFont(13);
        next[NSForegroundColorAttributeName] = ODDuoColor(0xe7ecff);
        return next;
    };
    _back.configuration = back;
    [_back addTarget:self action:@selector(backTapped) forControlEvents:UIControlEventTouchUpInside];
    _stack = [[UIStackView alloc] initWithArrangedSubviews:@[eyebrow, _title, _detail, _note, _setup, _back]];
    _stack.axis = UILayoutConstraintAxisVertical;
    _stack.spacing = 16;
    _stack.translatesAutoresizingMaskIntoConstraints = NO;
    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];
    [scroll addSubview:_stack];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [_stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:28],
        [_stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-28],
        [_stack.centerXAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.centerXAnchor],
        [_stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-36]
    ]];
}
- (void)setupTapped { if (self.setupGameData) self.setupGameData(); }
- (void)backTapped { [self dismissViewControllerAnimated:NO completion:nil]; }
- (NSString *)plainError:(NSString *)error {
    if ([error isEqualToString:@"DATA_SOURCE_SELECTION_REQUIRED"]) return @"Your saved data was kept. This account needs its game data before it can open.";
    if ([error isEqualToString:@"MASTER_MIGRATION_REQUIRED"]) return @"This data needs a compatibility update before it can be used with your player.";
    if ([error isEqualToString:@"LEGACY_SAVE_RECOVERY_REQUIRED"]) return @"Earlier development saves need recovery before your account can open.";
    if ([error isEqualToString:@"PROFILE_NOT_FOUND"]) return @"Couldn't open your saved account. Your data was kept.";
    if (error.length) return @"Couldn't open your saved account. Your data was kept.";
    return @"";
}
- (void)applySnapshot:(NSDictionary *)snapshot error:(NSString *)error {
    if (![NSThread isMainThread]) { dispatch_async(dispatch_get_main_queue(), ^{ [self applySnapshot:snapshot error:error]; }); return; }
    id identity = snapshot[@"wire_identity"];
    NSString *name = [identity isKindOfClass:NSDictionary.class] ? identity[@"name"] : nil;
    if (![name isKindOfClass:NSString.class] || !name.length) name = snapshot ? @"Your saved account" : @"Couldn't open your account";
    NSArray *cards = [snapshot[@"cards"] isKindOfClass:NSArray.class] ? snapshot[@"cards"] : @[];
    NSArray *teams = [snapshot[@"teams"] isKindOfClass:NSArray.class] ? snapshot[@"teams"] : @[];
    NSNumber *rank = [snapshot[@"rank"] isKindOfClass:NSNumber.class] ? snapshot[@"rank"] : nil;
    _title.text = snapshot ? name : [self plainError:error];
    if (snapshot) {
        NSMutableArray *lines = [NSMutableArray arrayWithObject:[NSString stringWithFormat:@"Characters: %lu", (unsigned long)cards.count]];
        [lines addObject:[NSString stringWithFormat:@"Teams: %lu", (unsigned long)teams.count]];
        if (rank) [lines addObject:[NSString stringWithFormat:@"Rank: %@", rank]];
        _detail.text = [lines componentsJoinedByString:@"\n"];
        _note.text = cards.count ? @"These characters are in your saved account." : @"No characters yet. Finish a unit in the Unit Creator and it is added here.";
        _note.textColor = ODDuoColor(0xa9b5d6);
        _setup.hidden = YES;
    } else {
        _detail.text = @"";
        _note.text = @"Offline Dokkan keeps one saved account on this device.";
        _note.textColor = ODDuoColor(0xffb7b7);
        _setup.hidden = self.setupGameData == nil;
    }
    _accountReady = YES;
}
@end
