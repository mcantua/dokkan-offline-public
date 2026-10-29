#import "ODDuoInGameActions.h"

/* UIControl is the public context-menu interaction's delegate. Preserve its
 * implementation, then release a user selection only after UIKit's actual
 * dismissal animator finishes. No fixed delay or private menu selector. */
@interface ODDuoInGameMenuButton : UIButton
@property(nonatomic) BOOL menuVisible;
@property(nonatomic) BOOL menuEnding;
@property(nonatomic) BOOL selectionCancelled;
@property(nonatomic) NSUInteger menuGeneration;
@property(nonatomic,copy) dispatch_block_t pendingSelection;
- (void)afterMenuDismissal:(dispatch_block_t)selection;
- (void)cancelSelectionAndDismiss;
@end
@implementation ODDuoInGameMenuButton
- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction
        willDisplayMenuForConfiguration:(UIContextMenuConfiguration *)configuration
        animator:(id<UIContextMenuInteractionAnimating>)animator {
    [super contextMenuInteraction:interaction willDisplayMenuForConfiguration:configuration animator:animator];
    self.menuGeneration++;self.menuVisible=YES;self.menuEnding=NO;self.selectionCancelled=NO;self.pendingSelection=nil;
}
- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction
        willEndForConfiguration:(UIContextMenuConfiguration *)configuration
        animator:(id<UIContextMenuInteractionAnimating>)animator {
    [super contextMenuInteraction:interaction willEndForConfiguration:configuration animator:animator];
    self.menuVisible=NO;self.menuEnding=YES;NSUInteger generation=self.menuGeneration;
    __weak ODDuoInGameMenuButton *weakSelf=self;
    dispatch_block_t finished=^{
        ODDuoInGameMenuButton *button=weakSelf;if(!button||generation!=button.menuGeneration)return;
        button.menuEnding=NO;dispatch_block_t selection=button.pendingSelection;button.pendingSelection=nil;
        if(selection)dispatch_async(dispatch_get_main_queue(),^{
            ODDuoInGameMenuButton *current=weakSelf;
            if(current&&generation==current.menuGeneration&&!current.selectionCancelled)selection();
        });
    };
    if(animator)[animator addCompletion:finished];else dispatch_async(dispatch_get_main_queue(),finished);
}
- (void)afterMenuDismissal:(dispatch_block_t)selection {
    if(self.selectionCancelled)return;
    if(self.menuVisible||self.menuEnding)self.pendingSelection=[selection copy];
    else {
        NSUInteger generation=self.menuGeneration;__weak ODDuoInGameMenuButton *weakSelf=self;
        dispatch_async(dispatch_get_main_queue(),^{
            ODDuoInGameMenuButton *current=weakSelf;
            if(current&&generation==current.menuGeneration&&!current.selectionCancelled)selection();
        });
    }
}
- (void)cancelSelectionAndDismiss {
    self.selectionCancelled=YES;self.pendingSelection=nil;self.menuGeneration++;
    [self.contextMenuInteraction dismissMenu];
}
@end

@interface ODDuoInGameActionsView : UIView
@property(nonatomic,weak) UIWindow *originalWindow;
@property(nonatomic,weak) UIViewController *originalController;
@property(nonatomic,weak) UIView *originalRenderer;
@property(nonatomic,strong) ODDuoInGameMenuButton *entry;
@property(nonatomic) BOOL creatorVisible;
@property(nonatomic) BOOL creatorEnabled;
@property(nonatomic) BOOL practiceVisible;
@property(nonatomic) BOOL practiceEnabled;
@property(nonatomic) BOOL practiceRetrySave;
@property(nonatomic,copy) NSString *menuSignature;
@property(nonatomic) BOOL diagnosticVisible;
@property(nonatomic,copy) dispatch_block_t creatorAction;
@property(nonatomic,copy) dispatch_block_t practiceAction;
@property(nonatomic,copy) void (^diagnosticAction)(UIView *);
@property(nonatomic) BOOL admittedForeground;
- (BOOL)originalSceneIsCurrent;
- (void)updateMenu;
@end
static ODDuoInGameActionsView *ODInGameActions;

@implementation ODDuoInGameActionsView
- (instancetype)initWithFrame:(CGRect)frame {
    if(!(self=[super initWithFrame:frame]))return nil;
    self.backgroundColor=UIColor.clearColor;self.accessibilityViewIsModal=NO;
    _entry=[[ODDuoInGameMenuButton alloc] initWithFrame:CGRectZero];
    _entry.showsMenuAsPrimaryAction=YES;
    _entry.titleLabel.adjustsFontForContentSizeCategory=YES;_entry.titleLabel.numberOfLines=2;
    _entry.accessibilityIdentifier=@"original-game-creator-tools-menu";
    _entry.translatesAutoresizingMaskIntoConstraints=NO;
    [_entry.heightAnchor constraintGreaterThanOrEqualToConstant:44].active=YES;
    [_entry.widthAnchor constraintGreaterThanOrEqualToConstant:44].active=YES;
    [_entry.widthAnchor constraintLessThanOrEqualToConstant:160].active=YES;
    [self addSubview:_entry];return self;
}
- (BOOL)originalSceneIsCurrent {
    UIWindow *window=self.originalWindow;UIViewController *controller=self.originalController;
    UIView *renderer=self.originalRenderer;
    return NSThread.isMainThread&&self.admittedForeground&&window&&self.superview==window&&
        !window.hidden&&window.isKeyWindow&&window.windowScene.activationState==UISceneActivationStateForegroundActive&&
        window.rootViewController==controller&&controller.isViewLoaded&&controller.view==renderer&&
        renderer.window==window&&!controller.presentedViewController&&!controller.transitionCoordinator;
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if(![self originalSceneIsCurrent])return nil;
    UIView *hit=[super hitTest:point withEvent:event];
    // Only the compact entry consumes game touches. The rest of the transparent
    // view returns no target and leaves the source game's touch path intact.
    return hit==self?nil:hit;
}
- (void)openCreator {
    if(!self.hidden&&self.creatorVisible&&self.creatorEnabled&&[self originalSceneIsCurrent]&&self.creatorAction)self.creatorAction();
}
- (void)openPractice {
    if(!self.hidden&&self.practiceVisible&&self.practiceEnabled&&[self originalSceneIsCurrent]&&self.practiceAction)self.practiceAction();
}
- (void)shareDiagnostic {
    if(!self.hidden&&self.diagnosticVisible&&[self originalSceneIsCurrent]&&self.diagnosticAction)self.diagnosticAction(self.entry);
}
- (void)updateMenu {
    NSString *signature=[NSString stringWithFormat:@"%d:%d:%d:%d:%d:%d:%d",self.admittedForeground,
        self.creatorVisible,self.creatorEnabled,self.practiceVisible,self.practiceEnabled,self.practiceRetrySave,self.diagnosticVisible];
    if([self.menuSignature isEqual:signature])return;
    self.menuSignature=signature;
    __weak ODDuoInGameActionsView *weakSelf=self;
    NSMutableArray<UIMenuElement *> *items=[NSMutableArray array];
    if(self.creatorVisible){
        UIAction *creator=[UIAction actionWithTitle:@"Unit Creator" image:nil identifier:nil handler:^(UIAction *action){
            (void)action;ODDuoInGameActionsView *view=weakSelf;
            [view.entry afterMenuDismissal:^{[weakSelf openCreator];}];
        }];
        if(!self.creatorEnabled)creator.attributes=UIMenuElementAttributesDisabled;
        [items addObject:creator];
    }
    if(self.practiceVisible){
        UIAction *practice=[UIAction actionWithTitle:(self.practiceRetrySave?@"Retry Save":@"Practice Battle") image:nil identifier:nil handler:^(UIAction *action){
            (void)action;ODDuoInGameActionsView *view=weakSelf;
            [view.entry afterMenuDismissal:^{[weakSelf openPractice];}];
        }];
        if(!self.practiceEnabled)practice.attributes=UIMenuElementAttributesDisabled;
        [items addObject:practice];
    }
    if(self.diagnosticVisible){
        UIAction *diagnostic=[UIAction actionWithTitle:@"Share diagnostic report" image:nil identifier:nil handler:^(UIAction *action){
            (void)action;ODDuoInGameActionsView *view=weakSelf;
            [view.entry afterMenuDismissal:^{[weakSelf shareDiagnostic];}];
        }];
        [items addObject:diagnostic];
    }
    UIButtonConfiguration *configuration=[UIButtonConfiguration filledButtonConfiguration];
    configuration.title=self.creatorVisible?@"Unit Creator":@"Tools";
    configuration.baseBackgroundColor=[UIColor colorWithWhite:0.08 alpha:0.90];
    configuration.baseForegroundColor=UIColor.whiteColor;
    configuration.cornerStyle=UIButtonConfigurationCornerStyleMedium;
    configuration.contentInsets=NSDirectionalEdgeInsetsMake(8,12,8,12);
    self.entry.configuration=configuration;
    self.entry.menu=[UIMenu menuWithTitle:@"" children:items];
    self.entry.enabled=self.admittedForeground&&items.count>0;
    self.entry.accessibilityHint=@"Opens the game’s native Creator and tools menu.";
}
@end

void ODDuoUpdateInGameActions(UIWindow *window,UIViewController *controller,UIView *renderer,
    BOOL foreground,BOOL creatorVisible,BOOL creatorEnabled,BOOL practiceVisible,BOOL practiceEnabled,
    BOOL practiceRetrySave,BOOL diagnosticVisible,dispatch_block_t creatorAction,dispatch_block_t practiceAction,
    void (^diagnosticAction)(UIView *)) {
    if(!NSThread.isMainThread)return;
    if(!window||!controller||!renderer||window.rootViewController!=controller||
       !controller.isViewLoaded||controller.view!=renderer||renderer.window!=window)return;
    if(ODInGameActions&&ODInGameActions.originalWindow!=window){
        [ODInGameActions.entry cancelSelectionAndDismiss];[ODInGameActions removeFromSuperview];ODInGameActions=nil;
    }
    if(!ODInGameActions){
        if(!creatorVisible&&!practiceVisible&&!diagnosticVisible)return;
        ODDuoInGameActionsView *controls=[[ODDuoInGameActionsView alloc] initWithFrame:CGRectZero];
        controls.originalWindow=window;controls.originalController=controller;controls.originalRenderer=renderer;
        controls.translatesAutoresizingMaskIntoConstraints=NO;[window addSubview:controls];
        UILayoutGuide *safe=window.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[
            [controls.leadingAnchor constraintEqualToAnchor:window.leadingAnchor],
            [controls.trailingAnchor constraintEqualToAnchor:window.trailingAnchor],
            [controls.topAnchor constraintEqualToAnchor:window.topAnchor],
            [controls.bottomAnchor constraintEqualToAnchor:window.bottomAnchor],
            [controls.entry.topAnchor constraintEqualToAnchor:safe.topAnchor constant:8],
            [controls.entry.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-8],
            [controls.entry.leadingAnchor constraintGreaterThanOrEqualToAnchor:safe.leadingAnchor constant:8],
            [controls.entry.bottomAnchor constraintLessThanOrEqualToAnchor:safe.bottomAnchor constant:-8]
        ]];
        ODInGameActions=controls;
    }
    ODDuoInGameActionsView *controls=ODInGameActions;
    controls.originalController=controller;controls.originalRenderer=renderer;controls.admittedForeground=foreground;
    controls.creatorVisible=creatorVisible;controls.creatorEnabled=foreground&&creatorEnabled;
    controls.practiceVisible=practiceVisible;controls.practiceEnabled=foreground&&practiceEnabled;controls.practiceRetrySave=practiceRetrySave;
    controls.diagnosticVisible=diagnosticVisible;
    controls.creatorAction=creatorAction;controls.practiceAction=practiceAction;controls.diagnosticAction=diagnosticAction;
    controls.hidden=!foreground||(!creatorVisible&&!practiceVisible&&!diagnosticVisible);
    if(controls.hidden)[controls.entry cancelSelectionAndDismiss];
    [controls updateMenu];
    if(!controls.hidden)[window bringSubviewToFront:controls];
}
void ODDuoRemoveInGameActions(UIWindow *window) {
    if(!NSThread.isMainThread||ODInGameActions.originalWindow!=window)return;
    [ODInGameActions.entry cancelSelectionAndDismiss];[ODInGameActions removeFromSuperview];ODInGameActions=nil;
}
NSDictionary *ODDuoCopyInGameActionState(void) {
    if(!NSThread.isMainThread)return @{};
    ODDuoInGameActionsView *controls=ODInGameActions;
    return @{@"nativeControlsAttached":@(controls&&controls.superview==controls.originalWindow),
        @"nativeControlsVisible":@(controls&&!controls.hidden&&[controls originalSceneIsCurrent]),
        @"unitCreatorEnabled":@(controls&&controls.creatorVisible&&controls.creatorEnabled),
        @"practiceBattleEnabled":@(controls&&controls.practiceVisible&&controls.practiceEnabled&&!controls.practiceRetrySave),
        @"practiceSaveRetryEnabled":@(controls&&controls.practiceVisible&&controls.practiceEnabled&&controls.practiceRetrySave),
        @"diagnosticReportEnabled":@(controls&&controls.diagnosticVisible&&controls.admittedForeground)};
}
