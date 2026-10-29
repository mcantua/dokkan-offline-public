#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <objc/message.h>
#import <math.h>
#import "RefreshCoordinator.h"
#import "InstallerService.h"
#import "DisplayDiagnostics.h"

static NSString *AIText(id value, NSString *fallback) {
    return [value isKindOfClass:NSString.class] && [value length] ? value : fallback;
}
static NSDate *AIDate(id value) {
    if ([value isKindOfClass:NSDate.class]) return value;
    if ([value isKindOfClass:NSNumber.class]) return [value doubleValue] > 0 ? [NSDate dateWithTimeIntervalSince1970:[value doubleValue]] : nil;
    if ([value isKindOfClass:NSString.class]) {
        NSISO8601DateFormatter *formatter = [NSISO8601DateFormatter new];
        return [formatter dateFromString:value];
    }
    return nil;
}
static NSString *AIExpiryText(id value) {
    NSDate *date = AIDate(value);
    if (!date) return @"Expiry not available";
    NSTimeInterval remaining = [date timeIntervalSinceNow];
    if (remaining <= 0) return @"Expired — refresh needed";
    NSInteger days = (NSInteger)ceil(remaining / 86400.0);
    if (days == 1) return @"1 day left";
    return [NSString stringWithFormat:@"%ld days left", (long)days];
}
static NSString *AIBiometricName(void) {
    LAContext *context = [LAContext new];
    [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:NULL];
    return context.biometryType == LABiometryTypeTouchID ? @"Touch ID" : @"Face ID";
}
@interface AIDynamicLabel : UILabel
@property (nonatomic, copy) UIFontTextStyle textStyle;
- (void)updateFont;
@end
@implementation AIDynamicLabel
- (void)updateFont {
    UIFont *font = [UIFont preferredFontForTextStyle:self.textStyle ?: UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];
    if (![self.font isEqual:font]) self.font = font;
}
- (void)didMoveToWindow { [super didMoveToWindow]; [self updateFont]; }
- (void)traitCollectionDidChange:(UITraitCollection *)previous { [super traitCollectionDidChange:previous]; [self updateFont]; }
@end

@interface AIDynamicField : UITextField
- (void)updateFont;
@end
@implementation AIDynamicField
- (void)updateFont {
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];
    if (![self.font isEqual:font]) { self.font = font; [self invalidateIntrinsicContentSize]; }
}
- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    size.height = MAX(size.height, ceil(self.font.lineHeight) + 24);
    return size;
}
- (void)didMoveToWindow { [super didMoveToWindow]; [self updateFont]; }
- (void)traitCollectionDidChange:(UITraitCollection *)previous { [super traitCollectionDidChange:previous]; [self updateFont]; }
@end

@interface AIDynamicButton : UIButton
@end
@implementation AIDynamicButton
- (void)traitCollectionDidChange:(UITraitCollection *)previous {
    [super traitCollectionDidChange:previous];
    [self setNeedsUpdateConfiguration];
    [self invalidateIntrinsicContentSize];
}
- (void)didMoveToWindow { [super didMoveToWindow]; [self setNeedsUpdateConfiguration]; }
@end

static UILabel *AILabel(NSString *text, UIFontTextStyle style, UIColor *color) {
    AIDynamicLabel *label = [AIDynamicLabel new];
    label.text = text; label.numberOfLines = 0;
    label.textStyle = style; [label updateFont];
    label.adjustsFontForContentSizeCategory = YES;
    label.textColor = color ?: UIColor.labelColor;
    return label;
}
static UIButton *AIButton(NSString *title, BOOL prominent, id target, SEL action) {
    UIButton *button = [[AIDynamicButton alloc] initWithFrame:CGRectZero];
    UIButtonConfiguration *configuration = prominent ? [UIButtonConfiguration filledButtonConfiguration] : [UIButtonConfiguration tintedButtonConfiguration];
    configuration.title = title;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleLarge;
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(16, 18, 16, 18);
    configuration.titleLineBreakMode = NSLineBreakByWordWrapping;
    __weak UIButton *weakButton = button;
    configuration.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey,id> *(NSDictionary<NSAttributedStringKey,id> *attributes) {
        NSMutableDictionary *result = attributes.mutableCopy;
        result[NSFontAttributeName] = [UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:weakButton.traitCollection];
        return result;
    };
    button.configuration = configuration;
    button.titleLabel.adjustsFontForContentSizeCategory = YES;
    button.titleLabel.numberOfLines = 0;
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:52].active = YES;
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}
static UIStackView *AIStack(CGFloat spacing) {
    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical; stack.spacing = spacing;
    return stack;
}

@class AIHome;
@interface AISettings : UITableViewController
@property (nonatomic, weak) AIHome *home;
- (void)updateState;
@end

@interface AIHome : UIViewController <UIDocumentPickerDelegate, UITextFieldDelegate>
@property (nonatomic, strong) AIInstallerService *service;
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) NSLayoutConstraint *scrollLeading;
@property (nonatomic, strong) NSLayoutConstraint *scrollTrailing;
@property (nonatomic, strong) NSLayoutConstraint *scrollTop;
@property (nonatomic, strong) NSLayoutConstraint *scrollBottom;
@property (nonatomic, strong) NSLayoutConstraint *scrollAboveTaskHUD;
@property (nonatomic, strong) NSLayoutConstraint *taskHUDBottom;
@property (nonatomic, strong) UIVisualEffectView *taskHUD;
@property (nonatomic, strong) UILabel *taskHUDStatus;
@property (nonatomic, strong) UIActivityIndicatorView *taskHUDSpinner;
@property (nonatomic, strong) UIProgressView *taskHUDProgress;
@property (nonatomic, strong) UILabel *taskHUDPercent;
@property (nonatomic, strong) UIButton *taskHUDCancel;
@property (nonatomic, strong) UIStackView *content;
@property (nonatomic, strong) UIStackView *mainColumns;
@property (nonatomic, strong) UIStackView *rail;
@property (nonatomic, strong) UITextField *email;
@property (nonatomic, strong) UITextField *password;
@property (nonatomic, strong) UITextField *code;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) NSNumber *progressOperationID;
@property (nonatomic, strong) NSNumber *displayProgress;
@property (nonatomic, copy) NSString *lastError;
@property (nonatomic, strong) UIButton *submitButton;
@property (nonatomic, strong) NSString *screen;
@property (nonatomic) BOOL showBiometricOffer;
@property (nonatomic) BOOL pendingFreshLogin;
@property (nonatomic) BOOL pickingPairing;
@property (nonatomic) BOOL verificationSubmitted;
@property (nonatomic) BOOL teamSelectionSubmitted;
@property (nonatomic, strong) NSMutableArray<UIButton *> *teamButtons;
@property (nonatomic, strong) NSMutableArray<UIButton *> *verificationButtons;
@property (nonatomic, weak) UITextField *focusedField;
@property (nonatomic) BOOL needsFocusedFieldReveal;
@property (nonatomic) CGSize lastFocusViewportSize;
@property (nonatomic, copy) NSDictionary *homeDisplayReportSnapshot;
- (void)render;
- (void)pickPairing;
- (void)showSettings;
- (void)refresh;
- (NSDictionary *)displayGeometry;
- (void)showDisplayReport;
- (void)alert:(NSString *)title text:(NSString *)text;
@end

@implementation AIHome
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"App Installer";
    self.service = AIInstallerService.shared;
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"gearshape"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
    self.navigationItem.rightBarButtonItem.accessibilityLabel = @"Settings";
    self.scroll = [UIScrollView new];
    self.scroll.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.scroll.translatesAutoresizingMaskIntoConstraints = NO;
    self.scroll.alwaysBounceVertical = YES;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [self.view addSubview:self.scroll];
    self.content = AIStack(24); self.content.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scroll addSubview:self.content];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    self.scrollLeading=[self.scroll.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor];
    self.scrollTrailing=[self.scroll.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor];
    self.scrollTop=[self.scroll.topAnchor constraintEqualToAnchor:safe.topAnchor];
    self.scrollBottom=[self.scroll.bottomAnchor constraintEqualToAnchor:self.view.keyboardLayoutGuide.topAnchor];
    [NSLayoutConstraint activateConstraints:@[
        self.scrollLeading,self.scrollTrailing,self.scrollTop,self.scrollBottom,
        [self.content.leadingAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.leadingAnchor constant:24],
        [self.content.trailingAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.trailingAnchor constant:-24],
        [self.content.topAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.topAnchor constant:24],
        [self.content.bottomAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.bottomAnchor constant:-24],
        [self.content.widthAnchor constraintEqualToAnchor:self.scroll.frameLayoutGuide.widthAnchor constant:-48]
    ]];
    [self buildTaskHUD];
    self.rail = AIStack(18); self.rail.alignment = UIStackViewAlignmentCenter;
    self.rail.hidden = YES; [self.view addSubview:self.rail];
    UIButton *railRefresh = [UIButton buttonWithType:UIButtonTypeSystem];
    [railRefresh setImage:[UIImage systemImageNamed:@"arrow.clockwise"] forState:UIControlStateNormal];
    railRefresh.accessibilityLabel = @"Refresh all apps";
    [railRefresh addTarget:self action:@selector(refresh) forControlEvents:UIControlEventTouchUpInside];
    UIButton *railSettings = [UIButton buttonWithType:UIButtonTypeSystem];
    [railSettings setImage:[UIImage systemImageNamed:@"gearshape"] forState:UIControlStateNormal];
    railSettings.accessibilityLabel = @"Settings";
    [railSettings addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    for (UIButton *button in @[railRefresh, railSettings]) {
        [button.widthAnchor constraintEqualToConstant:44].active = YES;
        [button.heightAnchor constraintEqualToConstant:44].active = YES;
        [self.rail addArrangedSubview:button];
    }
    __weak AIHome *weakSelf = self;
    self.service.eventHandler = ^(NSDictionary *event) {
        if (NSThread.isMainThread) [weakSelf handleEvent:event];
        else dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf handleEvent:event]; });
    };
    [self render];
}
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [self render]; }
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Capture before navigation detaches Home; every rectangle and window field
    // then describes one observation, even when the report is opened in Settings.
    if (self.view.window) {
        [self.view layoutIfNeeded];
        NSDictionary *layout=@{@"observation":@"Home view captured before leaving; not live report-page geometry",@"coordinateSpace":@"Home view; content frame is in scroll content coordinates",@"rootView":[AIDisplayDiagnostics rect:self.view.bounds],@"scroll":[AIDisplayDiagnostics rect:self.scroll.frame],@"content":[AIDisplayDiagnostics rect:self.content.frame],@"railHidden":@(self.rail.hidden),@"rail":[AIDisplayDiagnostics rect:self.rail.frame],@"taskHUDHidden":@(self.taskHUD.hidden),@"taskHUD":[AIDisplayDiagnostics rect:self.taskHUD.frame],@"wideColumns":@(self.mainColumns.axis==UILayoutConstraintAxisHorizontal)};
        NSMutableDictionary *state=[@{@"screen":self.screen ?: @"unknown",@"busy":@([self.service.snapshot[@"busy"] boolValue]),@"navigationDepth":@(self.navigationController.viewControllers.count)}mutableCopy];
        if(self.displayProgress)state[@"progress"]=self.displayProgress;
        self.homeDisplayReportSnapshot=[AIDisplayDiagnostics reportForView:self.view geometry:[self displayGeometry] layout:layout state:state];
    }
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
- (void)updateTaskHUDMaterial {
    BOOL opaque = UIAccessibilityIsReduceTransparencyEnabled();
    self.taskHUD.effect = opaque ? nil : [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
    self.taskHUD.contentView.backgroundColor = opaque ? UIColor.secondarySystemGroupedBackgroundColor : UIColor.clearColor;
}
- (void)buildTaskHUD {
    self.taskHUD = [[UIVisualEffectView alloc] initWithEffect:nil];
    self.taskHUD.translatesAutoresizingMaskIntoConstraints = NO;
    self.taskHUD.accessibilityIdentifier = @"Ongoing task";
    self.taskHUD.layer.cornerRadius = 20;
    self.taskHUD.layer.cornerCurve = kCACornerCurveContinuous;
    self.taskHUD.clipsToBounds = YES;
    self.taskHUD.hidden = YES;
    [self.view addSubview:self.taskHUD];
    self.taskHUDStatus = AILabel(@"", UIFontTextStyleSubheadline, UIColor.secondaryLabelColor);
    self.taskHUDStatus.accessibilityTraits |= UIAccessibilityTraitUpdatesFrequently;
    [self.taskHUDStatus setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    self.taskHUDSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    UIStackView *status = [[UIStackView alloc] initWithArrangedSubviews:@[self.taskHUDSpinner, self.taskHUDStatus]];
    status.axis = UILayoutConstraintAxisHorizontal; status.spacing = 10; status.alignment = UIStackViewAlignmentCenter;
    status.translatesAutoresizingMaskIntoConstraints = NO;
    // Only lengthy status text scrolls; numeric progress and Cancel stay visible.
    UIScrollView *statusScroll = [UIScrollView new];
    statusScroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [statusScroll addSubview:status];
    self.taskHUDProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.taskHUDProgress.accessibilityLabel = @"Task progress";
    self.taskHUDPercent = AILabel(@"", UIFontTextStyleCaption1, UIColor.secondaryLabelColor);
    UIStackView *fraction = [[UIStackView alloc] initWithArrangedSubviews:@[self.taskHUDProgress, self.taskHUDPercent]];
    fraction.axis = UILayoutConstraintAxisHorizontal; fraction.spacing = 12; fraction.alignment = UIStackViewAlignmentCenter;
    self.taskHUDCancel = AIButton(@"Cancel", NO, self, @selector(cancel));
    UIStackView *body = [[UIStackView alloc] initWithArrangedSubviews:@[statusScroll, fraction, self.taskHUDCancel]];
    body.axis = UILayoutConstraintAxisVertical; body.spacing = 12; body.translatesAutoresizingMaskIntoConstraints = NO;
    [self.taskHUD.contentView addSubview:body];
    NSLayoutConstraint *statusHeight = [statusScroll.heightAnchor constraintEqualToAnchor:status.heightAnchor];
    statusHeight.priority = UILayoutPriorityDefaultHigh - 1;
    self.taskHUDBottom = [self.taskHUD.bottomAnchor constraintEqualToAnchor:self.view.keyboardLayoutGuide.topAnchor constant:-12];
    self.scrollAboveTaskHUD = [self.scroll.bottomAnchor constraintEqualToAnchor:self.taskHUD.topAnchor constant:-12];
    [NSLayoutConstraint activateConstraints:@[
        [self.taskHUD.leadingAnchor constraintEqualToAnchor:self.scroll.leadingAnchor constant:12],
        [self.taskHUD.trailingAnchor constraintEqualToAnchor:self.scroll.trailingAnchor constant:-12],
        [self.taskHUD.topAnchor constraintGreaterThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        self.taskHUDBottom,
        [body.leadingAnchor constraintEqualToAnchor:self.taskHUD.contentView.leadingAnchor constant:16],
        [body.trailingAnchor constraintEqualToAnchor:self.taskHUD.contentView.trailingAnchor constant:-16],
        [body.topAnchor constraintEqualToAnchor:self.taskHUD.contentView.topAnchor constant:16],
        [body.bottomAnchor constraintEqualToAnchor:self.taskHUD.contentView.bottomAnchor constant:-16],
        [status.leadingAnchor constraintEqualToAnchor:statusScroll.contentLayoutGuide.leadingAnchor],
        [status.trailingAnchor constraintEqualToAnchor:statusScroll.contentLayoutGuide.trailingAnchor],
        [status.topAnchor constraintEqualToAnchor:statusScroll.contentLayoutGuide.topAnchor],
        [status.bottomAnchor constraintEqualToAnchor:statusScroll.contentLayoutGuide.bottomAnchor],
        [status.widthAnchor constraintEqualToAnchor:statusScroll.frameLayoutGuide.widthAnchor],
        statusHeight,
        [statusScroll.heightAnchor constraintLessThanOrEqualToAnchor:self.view.heightAnchor multiplier:0.22],
        [statusScroll.heightAnchor constraintGreaterThanOrEqualToConstant:0]
    ]];
    [self updateTaskHUDMaterial];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateTaskHUDMaterial) name:UIAccessibilityReduceTransparencyStatusDidChangeNotification object:nil];
}
- (void)handleEvent:(NSDictionary *)event {
    NSString *type = AIText(event[@"type"], @"");
    NSDictionary *state = self.service.snapshot;
    NSNumber *eventID = [event[@"operationId"] isKindOfClass:NSNumber.class] ? event[@"operationId"] : nil;
    NSNumber *activeID = [state[@"activeOperationId"] isKindOfClass:NSNumber.class] ? state[@"activeOperationId"] : nil;
    BOOL currentEvent = !eventID || !activeID || [eventID isEqual:activeID];
    if (activeID && ![activeID isEqual:self.progressOperationID]) {
        self.progressOperationID = activeID; self.displayProgress = nil;
    }
    BOOL completedLogin = [type isEqualToString:@"logged_in"] ||
        ([type isEqualToString:@"done"] && [event[@"operation"] isEqual:@"login"] && [state[@"loginStatus"] isEqual:@"signed_in"]);
    if (completedLogin && self.pendingFreshLogin) self.showBiometricOffer = YES;
    if (completedLogin || (currentEvent && ([@[@"error", @"cancelled"] containsObject:type]))) self.pendingFreshLogin = NO;
    if ([type isEqualToString:@"signed_out"]) self.showBiometricOffer = NO;
    if (currentEvent) {
        if (eventID && ![eventID isEqual:self.progressOperationID]) {
            self.progressOperationID = eventID; self.displayProgress = nil;
        }
        if ([@[@"progress", @"preparing"] containsObject:type]) {
            self.lastError = nil;
            id progress = event[@"progress"];
            if ([progress isKindOfClass:NSNumber.class] && isfinite([progress doubleValue]))
                self.displayProgress = @(fmin(1.0, fmax(0.0, [progress doubleValue])));
            else if ([type isEqualToString:@"preparing"]) self.displayProgress = nil;
        }
        if ([@[@"done", @"error", @"cancelled", @"signed"] containsObject:type]) self.displayProgress = nil;
        if ([type isEqualToString:@"error"])
            self.lastError = AIText(event[@"message"], AIText(state[@"statusMessage"], @"The operation could not finish. Please try again."));
        if ([@[@"needs_2fa", @"error", @"cancelled"] containsObject:type]) self.verificationSubmitted = NO;
        if ([@[@"needs_team", @"error", @"cancelled"] containsObject:type]) self.teamSelectionSubmitted = NO;
        if ([@[@"needs_team", @"needs_2fa"] containsObject:type]) self.screen = nil;
    }
    [self render];
    UIViewController *top = self.navigationController.topViewController;
    if ([top isKindOfClass:AISettings.class]) [(AISettings *)top updateState];
    if (currentEvent && [type isEqualToString:@"done"] && ![state[@"busy"] boolValue]) UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Done");
    if (currentEvent && [type isEqualToString:@"error"]) UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, self.lastError);
}
- (NSString *)desiredScreen {
    NSString *login = AIText(self.service.snapshot[@"loginStatus"], @"signed_out");
    // A timeout/cancel consumes the pending callback; never leave a dead code/team form visible.
    BOOL waitingForReply = [self.service.snapshot[@"busy"] boolValue];
    if ([login isEqualToString:@"needs_2fa"]) return waitingForReply ? @"code" : @"login";
    if ([login isEqualToString:@"needs_team"]) return waitingForReply ? @"team" : @"login";
    if (![@[@"signed_in", @"logged_in"] containsObject:login]) return @"login";
    if (self.showBiometricOffer) return @"biometric";
    if (![self.service.snapshot[@"paired"] boolValue]) return @"pairing";
    return @"main";
}
- (void)clearContent {
    self.email.text = nil; self.password.text = nil; self.code.text = nil;
    self.email = nil; self.password = nil; self.code = nil;
    self.submitButton = nil;
    for (UIView *view in self.content.arrangedSubviews.copy) { [self.content removeArrangedSubview:view]; [view removeFromSuperview]; }
    self.mainColumns = nil; self.statusLabel = nil; self.verificationSubmitted = NO; self.teamSelectionSubmitted = NO; self.teamButtons = nil; self.verificationButtons = nil;
}
- (void)addStatusTo:(UIStackView *)stack {
    self.statusLabel = AILabel(@"", UIFontTextStyleSubheadline, UIColor.secondaryLabelColor);
    self.statusLabel.accessibilityTraits |= UIAccessibilityTraitUpdatesFrequently;
    [stack addArrangedSubview:self.statusLabel];
}
- (UITextField *)field:(NSString *)placeholder secure:(BOOL)secure {
    AIDynamicField *field = [AIDynamicField new];
    field.placeholder = placeholder; field.accessibilityLabel = placeholder;
    field.borderStyle = UITextBorderStyleRoundedRect;
    [field updateFont];
    field.adjustsFontForContentSizeCategory = YES;
    field.secureTextEntry = secure; field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.autocorrectionType = UITextAutocorrectionTypeNo; field.spellCheckingType = UITextSpellCheckingTypeNo;
    field.delegate = self;
    [field.heightAnchor constraintGreaterThanOrEqualToConstant:52].active = YES;
    return field;
}
- (void)render {
    if (!self.isViewLoaded) return;
    NSString *screen = [self desiredScreen];
    BOOL same = [screen isEqualToString:self.screen];
    // Keep an in-progress sign-in form intact when only a progress message changes.
    if (!same || [screen isEqualToString:@"main"] || [screen isEqualToString:@"biometric"] || [screen isEqualToString:@"pairing"]) {
        [self clearContent]; self.screen = screen;
        if ([screen isEqualToString:@"login"]) [self buildLogin];
        else if ([screen isEqualToString:@"code"]) [self buildCode];
        else if ([screen isEqualToString:@"team"]) [self buildTeam];
        else if ([screen isEqualToString:@"biometric"]) [self buildBiometric];
        else if ([screen isEqualToString:@"pairing"]) [self buildPairing];
        else [self buildMain];
    }
    BOOL busy = [self.service.snapshot[@"busy"] boolValue];
    NSString *message = self.lastError ?: AIText(self.service.snapshot[@"statusMessage"], @"");
    self.statusLabel.text = message;
    self.statusLabel.hidden = busy || !message.length;
    BOOL numericProgress = busy && self.displayProgress != nil;
    self.taskHUD.hidden = !busy;
    self.taskHUDStatus.text = message.length ? message : @"Working…";
    self.taskHUDProgress.superview.hidden = !numericProgress;
    if (busy) [self.taskHUDSpinner startAnimating]; else [self.taskHUDSpinner stopAnimating];
    // Switch constraints without imposing both bottom anchors during keyboard changes.
    if (busy) { self.scrollBottom.active = NO; self.scrollAboveTaskHUD.active = YES; }
    else { self.scrollAboveTaskHUD.active = NO; self.scrollBottom.active = YES; }
    if (numericProgress) {
        self.taskHUDProgress.progress = self.displayProgress.floatValue;
        self.taskHUDPercent.text = [NSString stringWithFormat:@"%.0f%%", self.displayProgress.doubleValue * 100];
        self.taskHUDProgress.accessibilityValue = self.taskHUDPercent.text;
    }
    BOOL acceptingCode = [screen isEqualToString:@"code"] && !self.verificationSubmitted;
    self.submitButton.enabled = !busy || acceptingCode;
    self.email.enabled = !busy; self.password.enabled = !busy; self.code.enabled = !busy || acceptingCode;
    for (UIButton *choice in self.teamButtons) choice.enabled = !self.teamSelectionSubmitted;
    for (UIButton *option in self.verificationButtons) option.enabled = !self.verificationSubmitted;
    [self.view setNeedsLayout];
}
- (void)buildLogin {
    [self.content addArrangedSubview:AILabel(@"Sign in with Apple ID", UIFontTextStyleTitle1, nil)];
    [self.content addArrangedSubview:AILabel(@"Use your Apple account to sign your apps. Your account details stay in this iPhone’s protected storage and are sent only to Apple.", UIFontTextStyleBody, UIColor.secondaryLabelColor)];
    self.email = [self field:@"Apple ID email" secure:NO];
    self.email.keyboardType = UIKeyboardTypeEmailAddress; self.email.textContentType = UITextContentTypeUsername; self.email.returnKeyType = UIReturnKeyNext;
    self.password = [self field:@"Password" secure:YES];
    self.password.textContentType = UITextContentTypePassword; self.password.returnKeyType = UIReturnKeyGo;
    [self.content addArrangedSubview:self.email]; [self.content addArrangedSubview:self.password];
    self.submitButton = AIButton(@"Continue", YES, self, @selector(signIn)); [self.content addArrangedSubview:self.submitButton];
    [self.content addArrangedSubview:AIButton(@"Unlock saved sign-in", NO, self, @selector(unlockSaved))];
    [self addStatusTo:self.content];
    if (self.service.snapshot[@"backendReady"] && ![self.service.snapshot[@"backendReady"] boolValue])
        [self.content addArrangedSubview:AILabel(@"The signing setup is not ready yet. Sign-in will stay unavailable until it is connected.", UIFontTextStyleFootnote, UIColor.secondaryLabelColor)];
}
- (void)buildCode {
    BOOL unknownMethod = [self.service.snapshot[@"unknown"] boolValue];
    self.verificationButtons = [NSMutableArray array];
    [self.content addArrangedSubview:AILabel(unknownMethod ? @"Choose how to get a code" : @"Enter your verification code", UIFontTextStyleTitle1, nil)];
    [self.content addArrangedSubview:AILabel(unknownMethod ? @"Choose a trusted device or phone number below. Enter the code after Apple sends it." : @"Enter the 6-digit code Apple sent to your trusted device or phone number.", UIFontTextStyleBody, UIColor.secondaryLabelColor)];
    if (!unknownMethod) {
    self.code = [self field:@"6-digit code" secure:YES];
    self.code.textContentType = UITextContentTypeOneTimeCode; self.code.keyboardType = UIKeyboardTypeNumberPad;
    [self.content addArrangedSubview:self.code];
    self.submitButton = AIButton(@"Verify", YES, self, @selector(submitCode)); [self.content addArrangedSubview:self.submitButton];
    UIButton *resend = AIButton(@"Resend code", NO, self, @selector(resendCode));
    [self.verificationButtons addObject:resend]; [self.content addArrangedSubview:resend];
    }
    UIButton *devices = AIButton(@"Send to trusted devices", NO, self, @selector(sendToDevices));
    [self.verificationButtons addObject:devices]; [self.content addArrangedSubview:devices];
    NSArray *numbers = [self.service.snapshot[@"twoFactorNumbers"] isKindOfClass:NSArray.class] ? self.service.snapshot[@"twoFactorNumbers"] : @[];
    for (NSDictionary *number in numbers) {
        if (![number isKindOfClass:NSDictionary.class] || ![number[@"id"] isKindOfClass:NSNumber.class]) continue;
        NSString *lastDigits = AIText(number[@"lastTwoDigits"], @"");
        if (lastDigits.length != 2 || [lastDigits rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet].location != NSNotFound) continue;
        UIButton *sms = AIButton([NSString stringWithFormat:@"Text code to number ending in %@", lastDigits], NO, self, @selector(sendSMS:));
        sms.accessibilityIdentifier = [number[@"id"] stringValue];
        [self.verificationButtons addObject:sms]; [self.content addArrangedSubview:sms];
    }
    [self.content addArrangedSubview:AIButton(@"Start over", NO, self, @selector(startOver))];
    [self addStatusTo:self.content];
}
- (void)buildTeam {
    [self.content addArrangedSubview:AILabel(@"Choose your developer team", UIFontTextStyleTitle1, nil)];
    [self.content addArrangedSubview:AILabel(@"Choose the Apple developer team to use for signing. Apps signed for another team may need separate provisioning.", UIFontTextStyleBody, UIColor.secondaryLabelColor)];
    self.teamButtons = [NSMutableArray array];
    NSArray *teams = [self.service.snapshot[@"teams"] isKindOfClass:NSArray.class] ? self.service.snapshot[@"teams"] : @[];
    for (NSDictionary *team in teams) {
        if (![team isKindOfClass:NSDictionary.class]) continue;
        NSString *identifier = AIText(team[@"id"], @"");
        if (!identifier.length) continue;
        NSString *name = AIText(team[@"name"], @"Developer team");
        UIButton *choice = AIButton(name, YES, self, @selector(selectTeamButton:));
        choice.accessibilityIdentifier = identifier;
        [self.teamButtons addObject:choice]; [self.content addArrangedSubview:choice];
    }
    if (!self.teamButtons.count) [self.content addArrangedSubview:AILabel(@"No developer team choices are available. Start over and sign in again.", UIFontTextStyleBody, UIColor.secondaryLabelColor)];
    [self.content addArrangedSubview:AIButton(@"Start over", NO, self, @selector(startOver))];
    [self addStatusTo:self.content];
}
- (void)selectTeamButton:(UIButton *)button {
    if (self.teamSelectionSubmitted || !button.accessibilityIdentifier.length) return;
    self.teamSelectionSubmitted = YES; self.lastError = nil;
    [self.service selectTeam:button.accessibilityIdentifier]; [self render];
}
- (void)requestCode:(NSInteger)action numberID:(uint32_t)numberID {
    if (![[self desiredScreen] isEqualToString:@"code"] || self.verificationSubmitted) return;
    [self.view endEditing:YES]; self.code.text = nil; self.lastError = nil; self.verificationSubmitted = YES;
    [self.service requestVerificationCode:action numberID:numberID]; [self render];
}
- (void)resendCode { [self requestCode:0 numberID:0]; }
- (void)sendToDevices { [self requestCode:1 numberID:0]; }
- (void)sendSMS:(UIButton *)button {
    NSScanner *scanner = [NSScanner scannerWithString:button.accessibilityIdentifier ?: @""];
    unsigned long long value = 0;
    if (![scanner scanUnsignedLongLong:&value] || !scanner.isAtEnd || value > UINT32_MAX) return;
    [self requestCode:2 numberID:(uint32_t)value];
}
- (void)buildBiometric {
    NSString *name = AIBiometricName();
    BOOL enabled = [self.service.snapshot[@"biometricEnabled"] boolValue];
    if (enabled) {
        [self.content addArrangedSubview:AILabel(@"Your sign-in is protected", UIFontTextStyleTitle1, nil)];
        [self.content addArrangedSubview:AILabel([NSString stringWithFormat:@"%@ is on for saved sign-ins and approving installs. Your account stays in this iPhone’s secure storage. You can review unlock options in Settings.", name], UIFontTextStyleBody, UIColor.secondaryLabelColor)];
        self.submitButton = AIButton(@"Continue", YES, self, @selector(skipBiometric));
        [self.content addArrangedSubview:self.submitButton];
        [self.content addArrangedSubview:AIButton(@"Unlock options", NO, self, @selector(showSettings))];
    } else {
        [self.content addArrangedSubview:AILabel([NSString stringWithFormat:@"Use %@ next time?", name], UIFontTextStyleTitle1, nil)];
        [self.content addArrangedSubview:AILabel(@"Protect later sign-ins and app signing with your fingerprint or face. If your enrolled biometrics change, you may need to sign in again.", UIFontTextStyleBody, UIColor.secondaryLabelColor)];
        self.submitButton = AIButton([NSString stringWithFormat:@"Use %@", name], YES, self, @selector(enableBiometric));
        [self.content addArrangedSubview:self.submitButton];
        [self.content addArrangedSubview:AIButton(@"Not now", NO, self, @selector(skipBiometric))];
    }
    [self addStatusTo:self.content];
}
- (void)buildPairing {
    BOOL saved=[self.service.snapshot[@"pairingFilePresent"] boolValue];
    [self.content addArrangedSubview:AILabel(@"Connect this iPhone", UIFontTextStyleTitle1, nil)];
    if (![self.service.snapshot[@"connectionConfigured"] boolValue]) {
        [self.content addArrangedSubview:AILabel(@"Set the peer address shown in LocalDevVPN once in Settings. The address stays on this iPhone.", UIFontTextStyleBody, UIColor.secondaryLabelColor)];
        [self.content addArrangedSubview:AIButton(@"Open connection settings", NO, self, @selector(showSettings))];
    }
    if(saved) {
        [self.content addArrangedSubview:AILabel(@"Your pairing file is saved. Unlock your saved sign-in to check this iPhone’s connection before installing or refreshing apps.", UIFontTextStyleBody, UIColor.secondaryLabelColor)];
        self.submitButton=AIButton(@"Unlock and check connection",YES,self,@selector(unlockSaved));
        [self.content addArrangedSubview:self.submitButton];
        [self.content addArrangedSubview:AIButton(@"Replace pairing file",NO,self,@selector(pickPairing))];
    } else {
        [self.content addArrangedSubview:AILabel(@"Import the pairing file made during your first computer setup. It allows this app to talk securely to this iPhone’s installer service.", UIFontTextStyleBody, UIColor.secondaryLabelColor)];
        self.submitButton=AIButton(@"Import pairing file",YES,self,@selector(pickPairing));
        [self.content addArrangedSubview:self.submitButton];
    }
    [self.content addArrangedSubview:AILabel(@"Keep LocalDevVPN configured as directed during setup. If pairing stops working after a privacy reset, the app will ask for a new file.", UIFontTextStyleFootnote, UIColor.secondaryLabelColor)];
    [self addStatusTo:self.content];
}
- (void)buildMain {
    self.mainColumns = AIStack(28);
    self.mainColumns.distribution = UIStackViewDistributionFillEqually;
    [self.content addArrangedSubview:self.mainColumns];
    UIStackView *actions = AIStack(20);
    [actions addArrangedSubview:AILabel(@"Your apps. Your iPhone.", UIFontTextStyleTitle1, nil)];
    self.submitButton = AIButton(@"Install .IPA", YES, self, @selector(pickIPA));
    [actions addArrangedSubview:self.submitButton];
    [actions addArrangedSubview:AILabel(@"Choose an IPA from Files. An app you already installed will be updated using the same bundle ID.", UIFontTextStyleBody, UIColor.secondaryLabelColor)];
    [self addStatusTo:actions];
    UIStackView *apps = AIStack(16);
    [apps addArrangedSubview:AILabel(@"Installed apps", UIFontTextStyleTitle2, nil)];
    NSArray *records = self.service.appRecords;
    if (!records.count) [apps addArrangedSubview:AILabel(@"No installed apps are listed yet. Refresh connects to this iPhone and checks the apps managed here.", UIFontTextStyleBody, UIColor.secondaryLabelColor)];
    for (NSDictionary *record in records) {
        if (![record isKindOfClass:NSDictionary.class]) continue;
        UIStackView *card = AIStack(4);
        [card addArrangedSubview:AILabel(AIText(record[@"name"], @"App"), UIFontTextStyleHeadline, nil)];
        [card addArrangedSubview:AILabel(AIExpiryText(record[@"expiry"]), UIFontTextStyleSubheadline,
            AIDate(record[@"expiry"]) && [AIDate(record[@"expiry"]) timeIntervalSinceNow] <= 172800 ? UIColor.systemOrangeColor : UIColor.secondaryLabelColor)];
        NSString *bundle = AIText(record[@"bundleId"], @"");
        if (bundle.length) [card addArrangedSubview:AILabel(bundle, UIFontTextStyleCaption1, UIColor.tertiaryLabelColor)];
        [apps addArrangedSubview:card];
    }
    NSArray *results = [self.service.snapshot[@"refreshResults"] isKindOfClass:NSArray.class] ? self.service.snapshot[@"refreshResults"] : @[];
    UIStackView *outcomes = AIStack(12);
    for (id value in results) {
        if (![value isKindOfClass:NSDictionary.class]) continue;
        NSDictionary *result = value;
        BOOL refreshed = [result[@"status"] isEqual:@"refreshed"];
        if (!refreshed && ![result[@"status"] isEqual:@"failed"]) continue;
        NSString *name = AIText(result[@"name"], @"App");
        UIStackView *outcome = AIStack(4);
        [outcome addArrangedSubview:AILabel([NSString stringWithFormat:@"%@ — %@", name, refreshed ? @"Refreshed" : @"Needs attention"], UIFontTextStyleHeadline, refreshed ? UIColor.labelColor : UIColor.systemOrangeColor)];
        [outcome addArrangedSubview:AILabel(AIText(result[@"message"], refreshed ? @"Refreshed and confirmed by the device." : @"Refresh was not confirmed. Review this app’s status before trying again."), UIFontTextStyleSubheadline, UIColor.secondaryLabelColor)];
        [outcomes addArrangedSubview:outcome];
    }
    if (outcomes.arrangedSubviews.count) {
        [apps addArrangedSubview:AILabel(@"Refresh results", UIFontTextStyleTitle3, nil)];
        [apps addArrangedSubview:outcomes];
    }
    UIButton *refresh = AIButton(@"Refresh all", NO, self, @selector(refresh));
    refresh.enabled = ![self.service.snapshot[@"busy"] boolValue]; [apps addArrangedSubview:refresh];
    [apps addArrangedSubview:AILabel(@"Free Apple accounts: 3 active apps, including this installer, and 10 App IDs per week. Extensions can use extra App IDs.", UIFontTextStyleFootnote, UIColor.secondaryLabelColor)];
    [self.mainColumns addArrangedSubview:actions]; [self.mainColumns addArrangedSubview:apps];
}
- (void)signIn {
    NSString *email = [self.email.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *password = self.password.text;
    if (!email.length || !password.length) { [self alert:@"Check your sign-in" text:@"Enter your Apple ID and password."]; return; }
    if (self.service.snapshot[@"backendReady"] && ![self.service.snapshot[@"backendReady"] boolValue]) {
        self.email.text = nil; self.password.text = nil;
        [self alert:@"Not ready yet" text:@"The signing setup has not been connected yet."]; return;
    }
    [self.view endEditing:YES]; self.lastError = nil; self.displayProgress = nil;
    self.pendingFreshLogin = YES;
    [self.service signInWithEmail:email password:password];
    self.email.text = nil; self.password.text = nil;
    [self render];
}
- (void)unlockSaved {
    if ([self.service.snapshot[@"busy"] boolValue]) return;
    [self.view endEditing:YES]; self.email.text = nil; self.password.text = nil;
    self.pendingFreshLogin = NO; self.lastError = nil; self.displayProgress = nil;
    [self.service signInWithEmail:@"" password:@""]; [self render];
}
- (void)submitCode {
    NSString *code = [self.code.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSCharacterSet *notDigits = NSCharacterSet.decimalDigitCharacterSet.invertedSet;
    if (code.length != 6 || [code rangeOfCharacterFromSet:notDigits].location != NSNotFound) {
        [self alert:@"Check the code" text:@"Enter the 6 digits Apple sent you."]; return;
    }
    [self.view endEditing:YES]; self.lastError = nil; self.verificationSubmitted = YES; [self.service submitCode:code]; self.code.text = nil; [self render];
}
- (BOOL)textFieldShouldReturn:(UITextField *)field {
    if (field == self.email) [self.password becomeFirstResponder];
    else if (field == self.password) [self signIn];
    else if (field == self.code) [self submitCode];
    return YES;
}
- (void)textFieldDidBeginEditing:(UITextField *)field {
    self.focusedField = field;
    self.needsFocusedFieldReveal = YES;
    [self.view setNeedsLayout];
    // The keyboard guide and text-field intrinsic height settle on the next layout pass.
    __weak AIHome *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf.view layoutIfNeeded]; [weakSelf revealFocusedField]; });
}
- (void)textFieldDidEndEditing:(UITextField *)field {
    if (self.focusedField == field) { self.focusedField = nil; self.needsFocusedFieldReveal = NO; }
}
- (void)revealFocusedField {
    UITextField *field = self.focusedField;
    if (!field.isFirstResponder || ![field isDescendantOfView:self.scroll] || CGRectGetHeight(self.scroll.bounds) <= 0) return;
    self.needsFocusedFieldReveal = NO;
    CGRect rect = [field convertRect:field.bounds toView:self.scroll];
    [self.scroll scrollRectToVisible:CGRectInset(rect, 0, -12) animated:NO];
}
- (void)keyboardWillChange:(NSNotification *)notification {
    if (!self.focusedField.isFirstResponder) return;
    self.needsFocusedFieldReveal = YES;
    [self.view setNeedsLayout];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = (UIViewAnimationOptions)([notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue] << 16);
    __weak AIHome *weakSelf = self;
    [UIView animateWithDuration:duration delay:0 options:curve | UIViewAnimationOptionBeginFromCurrentState animations:^{
        [weakSelf.view layoutIfNeeded]; [weakSelf revealFocusedField];
    } completion:^(BOOL finished) {
        [weakSelf.view layoutIfNeeded]; [weakSelf revealFocusedField];
    }];
}
- (void)enableBiometric {
    __weak AIHome *weakSelf = self;
    [self.service setBiometricsEnabled:YES completion:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) { weakSelf.showBiometricOffer = NO; [weakSelf render]; }
            else [weakSelf alert:@"Biometrics unavailable" text:@"The setting could not be changed. You can try again or choose Not now."];
        });
    }];
}
- (void)skipBiometric { self.showBiometricOffer = NO; [self render]; }
- (void)cancel { self.lastError = nil; self.displayProgress = nil; [self.service cancel]; self.password.text = nil; self.code.text = nil; [self render]; }
- (void)startOver { self.pendingFreshLogin = NO; self.lastError = nil; [self.service cancel]; self.showBiometricOffer = NO; [self render]; }
- (void)refresh { self.lastError = nil; self.displayProgress = nil; [self.service refreshAll]; [self render]; }
- (void)pickIPA { self.pickingPairing = NO; [self showPicker]; }
- (void)pickPairing { self.pickingPairing = YES; [self showPicker]; }
- (void)showPicker {
    if ([self.service.snapshot[@"busy"] boolValue]) {
        [self alert:@"Task in progress" text:@"Finish or cancel the current task before choosing another file."]; return;
    }
    [self.view endEditing:YES];
    UTType *type = self.pickingPairing ? UTTypeData : [UTType typeWithFilenameExtension:@"ipa"];
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[type ?: UTTypeData] asCopy:NO];
    picker.delegate = self; picker.allowsMultipleSelection = NO;
    UIViewController *presenter = self.navigationController.topViewController ?: self;
    [presenter presentViewController:picker animated:YES completion:nil];
}
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject; if (!url) return;
    self.lastError = nil; self.displayProgress = nil;
    if (self.pickingPairing) [self.service importPairingFile:url];
    else [self.service installIPA:url];
    [self render];
}
- (void)showSettings {
    if ([self.navigationController.topViewController isKindOfClass:AISettings.class]) return;
    AISettings *settings = [[AISettings alloc] initWithStyle:UITableViewStyleInsetGrouped];
    settings.home = self; [self.navigationController pushViewController:settings animated:YES];
}
- (void)alert:(NSString *)title text:(NSString *)text {
    UIViewController *presenter = self.navigationController.topViewController ?: self;
    if (presenter.presentedViewController) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:text preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [presenter presentViewController:alert animated:YES completion:nil];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    NSDictionary *insets = [self displayGeometry][@"contentInsets"];
    CGFloat contentWidth = MAX(0, self.view.bounds.size.width - [insets[@"left"] doubleValue] - [insets[@"right"] doubleValue] - 48);
    // Two useful columns need 286 points each plus their 28-point gap.
    BOOL wide = contentWidth >= 600 && !UIContentSizeCategoryIsAccessibilityCategory(self.traitCollection.preferredContentSizeCategory);
    self.mainColumns.axis = wide ? UILayoutConstraintAxisHorizontal : UILayoutConstraintAxisVertical;
    self.mainColumns.distribution = wide ? UIStackViewDistributionFillEqually : UIStackViewDistributionFill;
    [self layoutRail];
    CGSize viewport = self.scroll.bounds.size;
    if (!CGSizeEqualToSize(viewport, self.lastFocusViewportSize)) {
        self.lastFocusViewportSize = viewport;
        self.needsFocusedFieldReveal = self.focusedField.isFirstResponder;
    }
    if (self.needsFocusedFieldReveal) [self revealFocusedField];
}
- (void)traitCollectionDidChange:(UITraitCollection *)previous {
    [super traitCollectionDidChange:previous];
    if (![previous.preferredContentSizeCategory isEqual:self.traitCollection.preferredContentSizeCategory]) {
        self.needsFocusedFieldReveal = self.focusedField.isFirstResponder;
        [self.view setNeedsLayout];
    }
}
- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    self.needsFocusedFieldReveal = self.focusedField.isFirstResponder;
    [self.view setNeedsLayout];
}
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.needsFocusedFieldReveal = self.focusedField.isFirstResponder;
    __weak AIHome *weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [weakSelf.view setNeedsLayout];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        weakSelf.needsFocusedFieldReveal = weakSelf.focusedField.isFirstResponder;
        [weakSelf.view setNeedsLayout];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [weakSelf.view setNeedsLayout]; });
    }];
}
- (NSDictionary *)displayGeometry { return [AIDisplayDiagnostics geometryForView:self.view]; }
- (void)layoutRail {
    NSDictionary *geometry=[self displayGeometry];
    NSDictionary *insets=geometry[@"contentInsets"];
    UIEdgeInsets safe=self.view.safeAreaInsets;
    self.scrollLeading.constant=MAX(0,[insets[@"left"] doubleValue]-safe.left);
    self.scrollTrailing.constant=-MAX(0,[insets[@"right"] doubleValue]-safe.right);
    self.scrollTop.constant=MAX(0,[insets[@"top"] doubleValue]-safe.top);
    self.scrollBottom.constant=-MAX(0,[insets[@"bottom"] doubleValue]-safe.bottom);
    self.taskHUDBottom.constant=-12-MAX(0,[insets[@"bottom"] doubleValue]-safe.bottom);
    self.rail.hidden=YES;
    if(![self.screen isEqualToString:@"main"] || ![geometry[@"valid"] boolValue])return;
    NSDictionary *frame=geometry[@"rail"][@"frame"];
    if(![frame isKindOfClass:NSDictionary.class] || frame.count!=4)return;
    self.rail.frame=CGRectMake([frame[@"x"] doubleValue],[frame[@"y"] doubleValue],[frame[@"width"] doubleValue],[frame[@"height"] doubleValue]);
    self.rail.hidden=NO;
    for(UIButton *button in self.rail.arrangedSubviews)button.enabled=![button.accessibilityLabel isEqual:@"Refresh all apps"] || ![self.service.snapshot[@"busy"] boolValue];
}
- (void)showDisplayReport {
    __weak AIHome *weakSelf=self;
    AIDisplayReportController *report=[[AIDisplayReportController alloc]initWithProvider:^NSDictionary *(__unused UIView *view) {
        AIHome *home=weakSelf;
        return home.homeDisplayReportSnapshot ?: @{@"available":@NO,@"reason":@"Return to Home before opening a display report."};
    }];
    [self.navigationController pushViewController:report animated:YES];
}

@end

@implementation AISettings
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"Settings";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 72;
}
- (void)traitCollectionDidChange:(UITraitCollection *)previous {
    [super traitCollectionDidChange:previous];
    if (self.isViewLoaded && ![previous.preferredContentSizeCategory isEqual:self.traitCollection.preferredContentSizeCategory]) [self updateState];
}
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [self updateState]; }
- (void)updateState { [self.tableView reloadData]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 4; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section == 3 ? 1 : (section == 1 ? 3 : 2); }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return @[@"Account", @"This iPhone", @"Refresh", @"Display"][(NSUInteger)section]; }
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 3) return @"View or share screen geometry without account data or unique device identifiers. A report does not prove physical touch or folding behavior.";
    if (section == 0) return @"Your Apple account details and signing keys belong in this iPhone’s Keychain. They are never written to ordinary files or logs.";
    if (section == 1) {
        if (self.home.lastError.length) return self.home.lastError;
        if ([self.home.service.snapshot[@"busy"] boolValue]) return @"A task is in progress. Return to the main screen to see progress or cancel it.";
        return @"A privacy reset can invalidate pairing. Import a new file if the app asks for one.";
    }
    return @"iOS chooses when background work can run. Opening the app and unlocking with Face ID or Touch ID may be needed before expiry.";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];
    cell.textLabel.adjustsFontForContentSizeCategory = YES; cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote compatibleWithTraitCollection:self.traitCollection];
    cell.detailTextLabel.adjustsFontForContentSizeCategory = YES; cell.detailTextLabel.numberOfLines = 0;
    if(path.section==3){cell.textLabel.text=@"Display report";cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;}
    else if (path.section == 0 && path.row == 0) {
        cell.textLabel.text = AIBiometricName();
        UISwitch *toggle = [UISwitch new]; toggle.on = [self.home.service.snapshot[@"biometricEnabled"] boolValue];
        toggle.accessibilityLabel = [NSString stringWithFormat:@"Use %@", AIBiometricName()];
        toggle.enabled = ![self.home.service.snapshot[@"busy"] boolValue];
        [toggle addTarget:self action:@selector(toggleBiometrics:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle; cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (path.section == 0) {
        cell.textLabel.text = @"Sign out"; cell.textLabel.textColor = UIColor.systemRedColor;
    } else if (path.section == 1 && path.row == 0) {
        cell.textLabel.text = @"Import pairing file";
        BOOL verified=[self.home.service.snapshot[@"paired"] boolValue] && [self.home.service.snapshot[@"pairingVerified"] boolValue];
        BOOL saved=[self.home.service.snapshot[@"pairingFilePresent"] boolValue];
        cell.detailTextLabel.text=verified ? @"Connection verified" : (saved ? @"Saved — unlock and check connection" : @"No pairing file saved");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (path.section == 1 && path.row == 1) {
        cell.textLabel.text = @"Connection address";
        cell.detailTextLabel.text = [self.home.service.snapshot[@"connectionConfigured"] boolValue] ? @"Configured on this iPhone" : @"Set the peer address shown by LocalDevVPN";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (path.section == 1) {
        cell.textLabel.text = @"Installer expiry"; cell.detailTextLabel.text = AIExpiryText(self.home.service.snapshot[@"ownExpiry"]);
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (path.row == 0) {
        cell.textLabel.text = @"Daily refresh guide"; cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.textLabel.text = @"Expiry alerts"; cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}
- (void)toggleBiometrics:(UISwitch *)toggle {
    toggle.enabled = NO; __weak AISettings *weakSelf = self;
    [self.home.service setBiometricsEnabled:toggle.on completion:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateState];
            if (!success) [weakSelf.home alert:@"Setting unchanged" text:@"Biometric protection could not be changed. Try again after unlocking the app."];
        });
    }];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];
    if(path.section==3){[self.home showDisplayReport];}
    else if (path.section == 0 && path.row == 1) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sign out?" message:@"This removes this app’s saved Apple session and signing credentials. Installed apps remain on the phone." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        __weak AISettings *weakSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"Sign out" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [weakSelf.home.service signOut]; weakSelf.home.showBiometricOffer = NO;
            [weakSelf.navigationController popToRootViewControllerAnimated:YES];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    } else if (path.section == 1 && path.row == 0) [self.home pickPairing];
    else if (path.section == 1 && path.row == 1) [self editConnectionAddress];
    else if (path.section == 2 && path.row == 0) [self.home alert:@"Daily refresh" text:@"In Shortcuts, open Automation → Time of Day → Daily. Add Open App and choose App Installer. Choose Run Immediately if your iPhone offers it. Open and unlock the app when prompted. Refresh should finish before the apps expire; iOS cannot guarantee an unattended daily run."];
    else if (path.section == 2 && path.row == 1) [self expiryAlerts];
}
- (void)editConnectionAddress {
    if ([self.home.service.snapshot[@"busy"] boolValue]) {
        [self.home alert:@"Task in progress" text:@"Finish or cancel the current task before changing the connection address."];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Connection address" message:@"Enter the peer IP address shown in LocalDevVPN. It stays on this iPhone. Keep the VPN connected when checking or installing apps." preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Peer IP address";
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.spellCheckingType = UITextSpellCheckingTypeNo;
        field.textContentType = nil;
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
        field.accessibilityLabel = @"LocalDevVPN peer IP address";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    __weak AISettings *weakSelf = self;
    __weak UIAlertController *weakAlert = alert;
    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *address = weakAlert.textFields.firstObject.text ?: @"";
        weakAlert.textFields.firstObject.text = nil;
        if (![weakSelf.home.service setConnectionAddress:address]) {
            [weakSelf.home alert:@"Address unchanged" text:@"Enter a valid IPv4 or IPv6 peer address and wait for any current task to finish."];
        }
        [weakSelf updateState];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)expiryAlerts {
    __weak AISettings *weakSelf = self;
    [[AIRefreshCoordinator shared] requestNotificationAuthorization:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.home alert:@"Expiry alerts" text:granted ? @"Notifications are allowed. Expiry warnings can appear two days before an app expires." : @"Notifications are not enabled. You can allow them in iPhone Settings."];
        });
    }];
}
@end

@interface AIScene : UIResponder <UIWindowSceneDelegate>
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIView *privacyCover;
@end
@implementation AIScene
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    if (![scene isKindOfClass:UIWindowScene.class]) return;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:[AIHome new]];
    navigation.navigationBar.prefersLargeTitles = YES;
    self.window.rootViewController = navigation; [self.window makeKeyAndVisible];
}
- (void)sceneDidBecomeActive:(UIScene *)scene {
    [self.privacyCover removeFromSuperview]; self.privacyCover=nil;
    [AIInstallerService.shared resume];
}
- (void)sceneWillResignActive:(UIScene *)scene {
    // A fold may transiently deactivate a foreground scene. Shield snapshots without destroying its form state.
    if (!self.privacyCover) {
        UIView *cover=[[UIView alloc]initWithFrame:self.window.bounds];cover.backgroundColor=UIColor.systemBackgroundColor;
        cover.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        cover.accessibilityIdentifier=@"App Installer privacy shield";
        UILabel *label=AILabel(@"App Installer",UIFontTextStyleTitle1,UIColor.secondaryLabelColor);
        label.translatesAutoresizingMaskIntoConstraints=NO;[cover addSubview:label];
        [NSLayoutConstraint activateConstraints:@[[label.centerXAnchor constraintEqualToAnchor:cover.centerXAnchor],[label.centerYAnchor constraintEqualToAnchor:cover.centerYAnchor]]];
        self.privacyCover=cover;[self.window addSubview:cover];
    }
}
- (void)sceneDidEnterBackground:(UIScene *)scene {
    UIViewController *root = self.window.rootViewController;
    if ([root isKindOfClass:UINavigationController.class]) {
        AIHome *home = (AIHome *)[(UINavigationController *)root viewControllers].firstObject;
        if ([home isKindOfClass:AIHome.class]) { home.password.text = nil; home.code.text = nil; }
    }
}
@end
@interface AIApp : UIResponder <UIApplicationDelegate>
@end
@implementation AIApp
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    [[AIRefreshCoordinator shared] registerTasks];
    [AIInstallerService.shared resume];
    return YES;
}
@end
int main(int argc, char **argv) { @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(AIApp.class)); } }
