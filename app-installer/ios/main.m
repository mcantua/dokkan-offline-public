#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <QuartzCore/QuartzCore.h>
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
    if ([style isEqualToString:UIFontTextStyleTitle1] || [style isEqualToString:UIFontTextStyleTitle2]) label.accessibilityTraits |= UIAccessibilityTraitHeader;
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
static UIStackView *AICard(CGFloat spacing) {
    UIStackView *card = AIStack(spacing);
    card.layoutMarginsRelativeArrangement = YES;
    card.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(20, 20, 20, 20);
    card.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    card.layer.cornerRadius = 22;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    return card;
}
static UIImageView *AISymbol(NSString *name, UIColor *color, CGFloat size) {
    UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:name withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:size weight:UIImageSymbolWeightRegular]]];
    image.tintColor = color ?: UIColor.systemBlueColor;
    image.contentMode = UIViewContentModeScaleAspectFit;
    image.isAccessibilityElement = NO;
    [image.widthAnchor constraintEqualToConstant:size + 8].active = YES;
    [image.heightAnchor constraintEqualToConstant:size + 8].active = YES;
    return image;
}
static UIView *AISeparator(void) {
    UIView *line = [UIView new]; line.backgroundColor = UIColor.separatorColor;
    [line.heightAnchor constraintEqualToConstant:0.5].active = YES;
    line.isAccessibilityElement = NO;
    return line;
}
static void AIButtonSymbol(UIButton *button, NSString *symbol) {
    UIButtonConfiguration *configuration = button.configuration;
    configuration.image = [UIImage systemImageNamed:symbol];
    configuration.imagePadding = 8;
    button.configuration = configuration;
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
@property (nonatomic, strong) UIStackView *content;
@property (nonatomic, strong) UIStackView *mainColumns;
@property (nonatomic, strong) UIStackView *setupColumns;
@property (nonatomic, strong) UIStackView *rail;
@property (nonatomic, strong) UIButton *railAction;
@property (nonatomic, strong) UIVisualEffectView *railBackdrop;
@property (nonatomic, strong) UIStackView *statusGroup;
@property (nonatomic, strong) UILabel *diagnosticLabel;
@property (nonatomic, strong) UITextField *email;
@property (nonatomic, strong) UITextField *password;
@property (nonatomic, strong) UITextField *code;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *progressPercent;
@property (nonatomic, strong) NSNumber *progressOperationID;
@property (nonatomic, strong) NSNumber *displayProgress;
@property (nonatomic, copy) NSString *lastError;
@property (nonatomic, strong) UIButton *submitButton;
@property (nonatomic, strong) UIButton *cancelButton;
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
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"gearshape"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
    self.navigationItem.rightBarButtonItem.accessibilityLabel = @"Settings";
    self.scroll = [UIScrollView new];
    self.scroll.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.scroll.translatesAutoresizingMaskIntoConstraints = NO;
    self.scroll.alwaysBounceVertical = YES;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [self.view addSubview:self.scroll];
    self.content = AIStack(20); self.content.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scroll addSubview:self.content];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    self.scrollLeading=[self.scroll.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor];
    self.scrollTrailing=[self.scroll.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor];
    self.scrollTop=[self.scroll.topAnchor constraintEqualToAnchor:safe.topAnchor];
    self.scrollBottom=[self.scroll.bottomAnchor constraintEqualToAnchor:self.view.keyboardLayoutGuide.topAnchor];
    [NSLayoutConstraint activateConstraints:@[
        self.scrollLeading,self.scrollTrailing,self.scrollTop,self.scrollBottom,
        [self.content.leadingAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.leadingAnchor constant:16],
        [self.content.trailingAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.trailingAnchor constant:-16],
        [self.content.topAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.topAnchor constant:20],
        [self.content.bottomAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.bottomAnchor constant:-24],
        [self.content.widthAnchor constraintEqualToAnchor:self.scroll.frameLayoutGuide.widthAnchor constant:-32]
    ]];
    self.rail = AIStack(6); self.rail.alignment = UIStackViewAlignmentCenter;
    self.rail.layoutMarginsRelativeArrangement = YES;
    self.rail.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(6, 4, 6, 4);
    self.railBackdrop = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial]];
    self.railBackdrop.layer.cornerRadius = 26; self.railBackdrop.layer.cornerCurve = kCACornerCurveContinuous;
    self.railBackdrop.clipsToBounds = YES; self.railBackdrop.hidden = YES;
    [self.view addSubview:self.railBackdrop];
    self.rail.hidden = YES; [self.view addSubview:self.rail];
    UIButton *railRefresh = [UIButton buttonWithType:UIButtonTypeSystem];
    self.railAction = railRefresh;
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
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
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
    self.submitButton = nil; self.cancelButton = nil;
    for (UIView *view in self.content.arrangedSubviews.copy) { [self.content removeArrangedSubview:view]; [view removeFromSuperview]; }
    self.mainColumns = nil; self.setupColumns = nil; self.statusLabel = nil; self.statusGroup = nil; self.diagnosticLabel = nil; self.spinner = nil; self.progressView = nil; self.progressPercent = nil; self.verificationSubmitted = NO; self.teamSelectionSubmitted = NO; self.teamButtons = nil; self.verificationButtons = nil;
}
- (void)addStatusTo:(UIStackView *)stack {
    self.statusGroup = AIStack(12);
    self.statusGroup.accessibilityIdentifier = @"Task status";
    [stack addArrangedSubview:self.statusGroup];
    self.statusLabel = AILabel(@"", UIFontTextStyleSubheadline, UIColor.secondaryLabelColor);
    self.statusLabel.accessibilityTraits |= UIAccessibilityTraitUpdatesFrequently;
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.spinner.hidesWhenStopped = YES;
    UIStackView *progress = [[UIStackView alloc] initWithArrangedSubviews:@[self.spinner, self.statusLabel]];
    progress.axis = UILayoutConstraintAxisHorizontal; progress.spacing = 10; progress.alignment = UIStackViewAlignmentCenter;
    [self.statusGroup addArrangedSubview:progress];
    self.diagnosticLabel = AILabel(@"", UIFontTextStyleFootnote, UIColor.secondaryLabelColor);
    self.diagnosticLabel.hidden = YES;
    [self.statusGroup addArrangedSubview:self.diagnosticLabel];
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.accessibilityLabel = @"Task progress";
    self.progressPercent = AILabel(@"", UIFontTextStyleCaption1, UIColor.secondaryLabelColor);
    UIStackView *fraction = [[UIStackView alloc] initWithArrangedSubviews:@[self.progressView, self.progressPercent]];
    fraction.axis = UILayoutConstraintAxisHorizontal; fraction.spacing = 12; fraction.alignment = UIStackViewAlignmentCenter;
    [self.statusGroup addArrangedSubview:fraction];
    self.cancelButton = AIButton(@"Cancel", NO, self, @selector(cancel));
    [self.statusGroup addArrangedSubview:self.cancelButton];
}
- (UITextField *)field:(NSString *)placeholder secure:(BOOL)secure {
    AIDynamicField *field = [AIDynamicField new];
    field.placeholder = placeholder; field.accessibilityLabel = placeholder;
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.backgroundColor = UIColor.tertiarySystemGroupedBackgroundColor;
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
    // Main and pairing rebuild on every state event, including changed refreshResults.
    if (!same || [screen isEqualToString:@"main"] || [screen isEqualToString:@"biometric"] || [screen isEqualToString:@"pairing"]) {
        [self clearContent]; self.screen = screen;
        if ([screen isEqualToString:@"login"]) [self buildLogin];
        else if ([screen isEqualToString:@"code"]) [self buildCode];
        else if ([screen isEqualToString:@"team"]) [self buildTeam];
        else if ([screen isEqualToString:@"biometric"]) [self buildBiometric];
        else if ([screen isEqualToString:@"pairing"]) [self buildPairing];
        else [self buildMain];
        if (![screen isEqualToString:@"main"]) [self styleOnboarding];
    }
    BOOL busy = [self.service.snapshot[@"busy"] boolValue];
    NSString *message = self.lastError ?: AIText(self.service.snapshot[@"statusMessage"], @"");
    self.statusLabel.text = message;
    self.statusLabel.hidden = !message.length && !busy;
    self.statusLabel.textColor = self.lastError.length ? UIColor.systemRedColor : UIColor.secondaryLabelColor;
    NSString *diagnostic = [self connectionDiagnostic];
    self.diagnosticLabel.text = diagnostic;
    self.diagnosticLabel.hidden = !diagnostic.length;
    self.statusGroup.hidden = !message.length && !busy && !diagnostic.length;
    if (busy) [self.spinner startAnimating]; else [self.spinner stopAnimating];
    self.cancelButton.hidden = !busy;
    BOOL numericProgress = busy && self.displayProgress != nil;
    self.progressView.superview.hidden = !numericProgress;
    if (numericProgress) {
        self.progressView.progress = self.displayProgress.floatValue;
        self.progressPercent.text = [NSString stringWithFormat:@"%.0f%%", self.displayProgress.doubleValue * 100];
        self.progressView.accessibilityValue = self.progressPercent.text;
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
- (void)styleOnboarding {
    NSArray<UIView *> *views = self.content.arrangedSubviews.copy;
    if (views.count < 2) return;
    for (UIView *view in views) { [self.content removeArrangedSubview:view]; [view removeFromSuperview]; }
    NSString *symbol = @{@"login":@"person.crop.circle.badge.checkmark", @"code":@"lock.shield", @"team":@"person.2", @"biometric":@"faceid", @"pairing":@"iphone.radiowaves.left.and.right"}[self.screen] ?: @"square.and.arrow.down";
    UIStackView *header = AIStack(12);
    header.accessibilityIdentifier = @"Setup introduction";
    UIStackView *symbolRow = [[UIStackView alloc] initWithArrangedSubviews:@[AISymbol(symbol, UIColor.systemBlueColor, 36), [UIView new]]];
    symbolRow.axis = UILayoutConstraintAxisHorizontal;
    [header addArrangedSubview:symbolRow];
    [header addArrangedSubview:views[0]];
    [header addArrangedSubview:views[1]];
    UIStackView *form = AICard(16);
    form.accessibilityIdentifier = @"Setup form";
    for (NSUInteger index = 2; index < views.count; index++) [form addArrangedSubview:views[index]];
    self.setupColumns = AIStack(24);
    self.setupColumns.accessibilityIdentifier = @"Adaptive setup layout";
    [self.setupColumns addArrangedSubview:header];
    [self.setupColumns addArrangedSubview:form];
    [self.content addArrangedSubview:self.setupColumns];
    // A partial refresh error may invalidate pairing proof. Keep its actual app
    // outcomes visible while the user rechecks the connection; do not bypass it.
    if ([self.screen isEqualToString:@"pairing"]) {
        UIStackView *results = AICard(14);
        results.accessibilityIdentifier = @"Refresh results card";
        [results addArrangedSubview:AILabel(@"Refresh results", UIFontTextStyleTitle2, nil)];
        NSUInteger matched = 0;
        for (NSDictionary *record in self.service.appRecords) {
            if (![record isKindOfClass:NSDictionary.class]) continue;
            NSString *bundle = AIText(record[@"bundleId"], @"");
            if (![self refreshResultForBundle:bundle]) continue;
            if (matched++) [results addArrangedSubview:AISeparator()];
            UIStackView *row = AIStack(4);
            row.accessibilityIdentifier = @"Managed app refresh row";
            [row addArrangedSubview:AILabel(AIText(record[@"name"], @"App"), UIFontTextStyleHeadline, nil)];
            [self addRefreshResultForBundle:bundle to:row];
            [results addArrangedSubview:row];
        }
        if (matched) [self.content addArrangedSubview:results];
    }
}
- (NSDictionary *)refreshResultForBundle:(NSString *)bundle {
    if (!bundle.length) return nil;
    id results = self.service.snapshot[@"refreshResults"];
    if (![results isKindOfClass:NSArray.class]) return nil;
    for (id value in [(NSArray *)results reverseObjectEnumerator]) {
        if (![value isKindOfClass:NSDictionary.class] || ![AIText(value[@"bundleId"], @"") isEqualToString:bundle]) continue;
        NSString *status = AIText(value[@"status"], @"");
        return [@[@"failed", @"refreshed"] containsObject:status] ? value : nil;
    }
    return nil;
}
- (void)addRefreshResultForBundle:(NSString *)bundle to:(UIStackView *)stack {
    NSDictionary *result = [self refreshResultForBundle:bundle];
    if (!result) return;
    BOOL failed = [result[@"status"] isEqual:@"failed"];
    UILabel *status = AILabel(failed ? @"Refresh failed" : @"Refreshed", UIFontTextStyleSubheadline, failed ? UIColor.systemRedColor : UIColor.systemGreenColor);
    status.accessibilityIdentifier = @"App refresh status";
    [stack addArrangedSubview:status];
    // The engine's result messages are fixed safe strings, never raw upstream errors.
    NSString *message = AIText(result[@"message"], @"");
    if (message.length > 512) message = failed ? @"Try refreshing this app again." : @"Refresh completed.";
    if (message.length) {
        UILabel *detail = AILabel(message, UIFontTextStyleFootnote, UIColor.secondaryLabelColor);
        detail.accessibilityIdentifier = @"App refresh detail";
        [stack addArrangedSubview:detail];
    }
}
- (NSString *)connectionDiagnostic {
    NSDictionary *state = self.service.snapshot;
    NSDictionary *stages = @{@"staging_cleanup":@"Previous install cleanup", @"tunnel_connect":@"VPN connection", @"pairing_session":@"Pairing session", @"pairing_tls":@"Secure pairing", @"service_start":@"Starting installer service", @"service_connect":@"Installer connection", @"service_tls":@"Secure installer connection", @"app_lookup":@"Reading apps", @"remote_pairing_connect":@"Remote pairing connection", @"remote_pairing_verify":@"Verifying remote pairing", @"remote_pairing_tunnel":@"Secure remote tunnel", @"remote_service_discovery":@"Finding device services", @"remote_service_connect":@"Connecting to device service", @"development_profiles":@"Development profiles", @"device_identity":@"Checking this iPhone"};
    NSDictionary *failures = @{@"timeout":@"Timed out", @"pairing_rejected":@"Pairing identity rejected", @"device_locked":@"Unlock this iPhone", @"developer_mode_required":@"Developer Mode required", @"tls_verification":@"Secure identity could not be verified", @"socket_permission":@"Network access denied", @"connection_refused":@"Connection unavailable", @"connection_closed":@"Connection closed", @"socket_failure":@"Network connection failed", @"session_inactive":@"Secure session ended", @"unknown_device_response":@"Unrecognized device response", @"session_ssl_not_enabled":@"Encrypted session unavailable", @"session_response_schema":@"Encryption not confirmed", @"protocol_response":@"Unexpected device response", @"device_service_failure":@"Device service unavailable", @"session_already_active":@"Another pairing session is active", @"session_connection_rejected":@"Pairing connection rejected", @"pairing_record_rejected":@"Pairing record rejected", @"trust_confirmation_pending":@"Trust confirmation needed", @"trust_confirmation_denied":@"Pairing trust denied", @"pairing_transport_prohibited":@"Connection does not permit pairing", @"session_protocol_rejected":@"Pairing request rejected"};
    NSString *stage = stages[AIText(state[@"connectionStage"], @"")];
    NSString *failureCode = AIText(state[@"connectionFailure"], @"");
    if (!failureCode.length) return @"";
    NSString *failure = failures[failureCode] ?: @"Connection could not finish";
    return stage.length ? [NSString stringWithFormat:@"%@ · %@", stage, failure] : failure;
}
- (void)buildMain {
    UIStackView *heading = AIStack(6);
    [heading addArrangedSubview:AILabel(@"Your apps. Your iPhone.", UIFontTextStyleTitle1, nil)];
    [heading addArrangedSubview:AILabel(@"Install from Files. Keep your apps up to date.", UIFontTextStyleSubheadline, UIColor.secondaryLabelColor)];
    [self.content addArrangedSubview:heading];
    self.mainColumns = AIStack(20);
    [self.content addArrangedSubview:self.mainColumns];
    UIStackView *actions = AIStack(16);
    UIStackView *install = AICard(18);
    install.accessibilityIdentifier = @"Install app card";
    UIStackView *installHeading = [[UIStackView alloc] initWithArrangedSubviews:@[AISymbol(@"square.and.arrow.down", UIColor.systemBlueColor, 28), AILabel(@"Install an app", UIFontTextStyleHeadline, nil)]];
    installHeading.axis = UILayoutConstraintAxisHorizontal; installHeading.alignment = UIStackViewAlignmentCenter; installHeading.spacing = 12;
    [install addArrangedSubview:installHeading];
    [install addArrangedSubview:AILabel(@"Choose an IPA from Files to install it on this iPhone. Choosing an existing app updates it in place.", UIFontTextStyleSubheadline, UIColor.secondaryLabelColor)];
    self.submitButton = AIButton(@"Install .IPA", YES, self, @selector(pickIPA));
    AIButtonSymbol(self.submitButton, @"plus");
    [install addArrangedSubview:self.submitButton];
    [self addStatusTo:install];
    [actions addArrangedSubview:install];
    UIStackView *connection = AICard(12);
    connection.accessibilityIdentifier = @"Connection card";
    BOOL verified = [self.service.snapshot[@"paired"] boolValue] && [self.service.snapshot[@"pairingVerified"] boolValue];
    UIStackView *connectionHeading = [[UIStackView alloc] initWithArrangedSubviews:@[AISymbol(verified ? @"checkmark.shield" : @"iphone", verified ? UIColor.systemGreenColor : UIColor.secondaryLabelColor, 22), AILabel(verified ? @"Connection verified" : @"This iPhone", UIFontTextStyleHeadline, nil)]];
    connectionHeading.axis = UILayoutConstraintAxisHorizontal; connectionHeading.alignment = UIStackViewAlignmentCenter; connectionHeading.spacing = 10;
    [connection addArrangedSubview:connectionHeading];
    [connection addArrangedSubview:AILabel([NSString stringWithFormat:@"Installer: %@", AIExpiryText(self.service.snapshot[@"ownExpiry"])], UIFontTextStyleSubheadline, UIColor.secondaryLabelColor)];
    [connection addArrangedSubview:AILabel(@"Keep LocalDevVPN connected while installing or refreshing.", UIFontTextStyleFootnote, UIColor.secondaryLabelColor)];
    [actions addArrangedSubview:connection];
    UIStackView *apps = AICard(16);
    apps.accessibilityIdentifier = @"Managed apps card";
    [apps addArrangedSubview:AILabel(@"Installed apps", UIFontTextStyleTitle2, nil)];
    NSArray *records = self.service.appRecords;
    NSUInteger count = 0;
    for (NSDictionary *record in records) {
        if (![record isKindOfClass:NSDictionary.class]) continue;
        if (count++) [apps addArrangedSubview:AISeparator()];
        UIStackView *details = AIStack(4);
        details.accessibilityIdentifier = @"Managed app refresh row";
        [details addArrangedSubview:AILabel(AIText(record[@"name"], @"App"), UIFontTextStyleHeadline, nil)];
        NSDate *expiry = AIDate(record[@"expiry"]);
        [details addArrangedSubview:AILabel(AIExpiryText(record[@"expiry"]), UIFontTextStyleSubheadline, expiry && [expiry timeIntervalSinceNow] <= 172800 ? UIColor.systemOrangeColor : UIColor.secondaryLabelColor)];
        NSString *bundle = AIText(record[@"bundleId"], @"");
        [self addRefreshResultForBundle:bundle to:details];
        if (bundle.length) [details addArrangedSubview:AILabel(bundle, UIFontTextStyleCaption1, UIColor.tertiaryLabelColor)];
        UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[AISymbol(@"app.fill", UIColor.systemBlueColor, 28), details]];
        row.axis = UILayoutConstraintAxisHorizontal; row.alignment = UIStackViewAlignmentTop; row.spacing = 12;
        [apps addArrangedSubview:row];
    }
    if (!count) {
        UIStackView *empty = AIStack(10);
        [empty addArrangedSubview:AILabel(@"Your apps will appear here", UIFontTextStyleHeadline, nil)];
        [empty addArrangedSubview:AILabel(@"Install your first IPA, or refresh to check the apps managed on this iPhone.", UIFontTextStyleSubheadline, UIColor.secondaryLabelColor)];
        [apps addArrangedSubview:empty];
    }
    UIButton *refresh = AIButton(@"Refresh all", NO, self, @selector(refresh));
    AIButtonSymbol(refresh, @"arrow.clockwise");
    refresh.enabled = ![self.service.snapshot[@"busy"] boolValue];
    [apps addArrangedSubview:refresh];
    [self.mainColumns addArrangedSubview:actions]; [self.mainColumns addArrangedSubview:apps];
    [self.content addArrangedSubview:AILabel(@"Free Apple accounts support 3 active apps, including this installer, and 10 App IDs per week. Extensions can use extra App IDs.", UIFontTextStyleFootnote, UIColor.secondaryLabelColor)];
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
    BOOL wide = self.view.bounds.size.width >= 600 && !UIContentSizeCategoryIsAccessibilityCategory(self.traitCollection.preferredContentSizeCategory);
    self.mainColumns.axis = wide ? UILayoutConstraintAxisHorizontal : UILayoutConstraintAxisVertical;
    self.mainColumns.distribution = wide ? UIStackViewDistributionFillEqually : UIStackViewDistributionFill;
    self.mainColumns.alignment = wide ? UIStackViewAlignmentTop : UIStackViewAlignmentFill;
    self.setupColumns.axis = wide ? UILayoutConstraintAxisHorizontal : UILayoutConstraintAxisVertical;
    self.setupColumns.distribution = wide ? UIStackViewDistributionFillEqually : UIStackViewDistributionFill;
    self.setupColumns.alignment = wide ? UIStackViewAlignmentTop : UIStackViewAlignmentFill;
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
    self.rail.hidden=YES; self.railBackdrop.hidden=YES;
    if(![geometry[@"valid"] boolValue])return;
    NSDictionary *frame=geometry[@"rail"][@"frame"];
    if(![frame isKindOfClass:NSDictionary.class] || frame.count!=4)return;
    self.rail.frame=CGRectMake([frame[@"x"] doubleValue],[frame[@"y"] doubleValue],[frame[@"width"] doubleValue],[frame[@"height"] doubleValue]);
    self.railBackdrop.frame=CGRectInset(self.rail.frame,MAX(0,(self.rail.frame.size.width-60)/2),0);
    BOOL main=[self.screen isEqualToString:@"main"];
    [self.railAction removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.railAction addTarget:self action:main ? @selector(refresh) : @selector(showDisplayReport) forControlEvents:UIControlEventTouchUpInside];
    [self.railAction setImage:[UIImage systemImageNamed:main ? @"arrow.clockwise" : @"info.circle"] forState:UIControlStateNormal];
    self.railAction.accessibilityLabel=main ? @"Refresh all apps" : @"Display report";
    self.rail.hidden=NO; self.railBackdrop.hidden=NO;
    for(UIButton *button in self.rail.arrangedSubviews)button.enabled=![button.accessibilityLabel isEqual:@"Refresh all apps"] || ![self.service.snapshot[@"busy"] boolValue];
}
- (void)showDisplayReport {
    __weak AIHome *weakSelf=self;
    AIDisplayReportController *report=[[AIDisplayReportController alloc]initWithProvider:^NSDictionary *(UIView *view) {
        AIHome *home=weakSelf;
        NSDictionary *layout=@{@"rootView":[AIDisplayDiagnostics rect:home.view.bounds],@"scroll":[AIDisplayDiagnostics rect:home.scroll.frame],@"content":[AIDisplayDiagnostics rect:home.content.frame],@"railHidden":@(home.rail.hidden),@"rail":[AIDisplayDiagnostics rect:home.rail.frame],@"wideColumns":@(home.mainColumns != nil && home.mainColumns.axis==UILayoutConstraintAxisHorizontal),@"wideSetupColumns":@(home.setupColumns != nil && home.setupColumns.axis==UILayoutConstraintAxisHorizontal)};
        NSMutableDictionary *state=[@{@"screen":home.screen ?: @"unknown",@"busy":@([home.service.snapshot[@"busy"] boolValue]),@"navigationDepth":@(home.navigationController.viewControllers.count)}mutableCopy];
        if(home.displayProgress)state[@"progress"]=home.displayProgress;
        return [AIDisplayDiagnostics reportForView:view geometry:[AIDisplayDiagnostics geometryForView:view] layout:layout state:state];
    }];
    [self.navigationController pushViewController:report animated:YES];
}

@end

@implementation AISettings
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"Settings";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
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
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section == 3 ? 1 : 2; }
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
    } else if (path.section == 1) {
        cell.textLabel.text = @"Installer expiry"; cell.detailTextLabel.text = AIExpiryText(self.home.service.snapshot[@"ownExpiry"]);
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (path.row == 0) {
        cell.textLabel.text = @"Daily refresh guide"; cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.textLabel.text = @"Expiry alerts"; cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    NSString *symbol = path.section == 3 ? @"rectangle.expand.vertical" :
        (path.section == 0 ? (path.row == 0 ? @"faceid" : @"rectangle.portrait.and.arrow.right") :
        (path.section == 1 ? (path.row == 0 ? @"link" : @"clock") : (path.row == 0 ? @"arrow.clockwise" : @"bell.badge")));
    cell.imageView.image = [UIImage systemImageNamed:symbol withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightRegular]];
    cell.imageView.tintColor = path.section == 0 && path.row == 1 ? UIColor.systemRedColor : UIColor.systemBlueColor;
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
    else if (path.section == 2 && path.row == 0) [self.home alert:@"Daily refresh" text:@"In Shortcuts, open Automation → Time of Day → Daily. Add Open App and choose App Installer. Choose Run Immediately if your iPhone offers it. Open and unlock the app when prompted. Refresh should finish before the apps expire; iOS cannot guarantee an unattended daily run."];
    else if (path.section == 2 && path.row == 1) [self expiryAlerts];
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
