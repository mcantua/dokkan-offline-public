#import "ODDuoCreatorQuickAction.h"
#import "creator_menu_policy.h"
#import "ODDuoInGameActions.h"

static NSString *ODQuickActionType(void) {
    return [NSString stringWithUTF8String:od_creator_shortcut_type()];
}
@interface ODDuoCreatorQuickActionOwner : NSObject
@property(nonatomic,copy) NSString *type;
@property(nonatomic,copy) NSString *title;
@property(nonatomic,copy) NSString *subtitle;
@property(nonatomic,copy) NSString *entry;
@property(nonatomic) UIApplicationShortcutIconType icon;
@property(nonatomic,copy) BOOL (^current)(void);
@property(nonatomic,copy) ODDuoCreatorQuickActionAdmission admission;
@property(nonatomic,copy) ODDuoCreatorQuickActionInvocation invoke;
@property(nonatomic,copy) void (^report)(NSDictionary *);
@property(nonatomic,weak) UIWindow *window;
@property(nonatomic,weak) UIViewController *controller;
@property(nonatomic,weak) UIView *renderer;
@property(nonatomic) BOOL sourceActive;
@property(nonatomic) BOOL pending;
@property(nonatomic) BOOL running;
@property(nonatomic) BOOL drainScheduled;
@property(nonatomic) BOOL menuInstalled;
@property(nonatomic) NSUInteger invocationGeneration;
@property(nonatomic,copy) NSString *menuState;
@property(nonatomic,copy) NSDictionary *lastReport;
- (void)emit:(NSString *)outcome;
- (void)scheduleDrain;
- (void)installMenu;
@end
static ODDuoCreatorQuickActionOwner *ODQuickActionOwner;
static ODDuoCreatorQuickActionOwner *ODPracticeActionOwner;
static NSArray<ODDuoCreatorQuickActionOwner *> *ODQuickActionOwners(void) {
    if(ODQuickActionOwner&&ODPracticeActionOwner)return @[ODQuickActionOwner,ODPracticeActionOwner];
    if(ODQuickActionOwner)return @[ODQuickActionOwner];
    return ODPracticeActionOwner?@[ODPracticeActionOwner]:@[];
}

static __weak UIWindow *ODInGameWindow;
static __weak UIViewController *ODInGameController;
static __weak UIView *ODInGameRenderer;
static BOOL ODInGameSourceActive;
static BOOL (^ODDiagnosticCurrent)(void);
static void (^ODDiagnosticInvoke)(UIViewController *,UIView *,dispatch_block_t);
static BOOL ODDiagnosticRunning;
static NSUInteger ODDiagnosticGeneration;
static void ODRefreshInGameControls(void);
static void ODInvokeInGameAction(BOOL practice);
static void ODInvokeDiagnosticAction(UIView *sourceView);

static BOOL ODInGameForeground(void) {
    UIWindow *window=ODInGameWindow;UIViewController *controller=ODInGameController;UIView *renderer=ODInGameRenderer;
    return NSThread.isMainThread&&ODInGameSourceActive&&window&&controller&&renderer&&
        !window.hidden&&window.isKeyWindow&&window.windowScene.activationState==UISceneActivationStateForegroundActive&&
        window.rootViewController==controller&&controller.isViewLoaded&&controller.view==renderer&&
        renderer.window==window&&!controller.presentedViewController&&!controller.transitionCoordinator;
}
static BOOL ODAnyActionBusy(void) {
    if(ODDiagnosticRunning)return YES;
    for(ODDuoCreatorQuickActionOwner *owner in ODQuickActionOwners())if(owner.running)return YES;
    return NO;
}
static BOOL ODAnyGameActionPending(void) {
    for(ODDuoCreatorQuickActionOwner *owner in ODQuickActionOwners())if(owner.pending)return YES;
    return NO;
}
static void ODRefreshInGameControls(void) {
    if(!NSThread.isMainThread)return;
    UIWindow *window=ODInGameWindow;UIViewController *controller=ODInGameController;UIView *renderer=ODInGameRenderer;
    if(!window||!controller||!renderer){ODDuoRemoveInGameActions(window);return;}
    BOOL creator=ODQuickActionOwner&&ODQuickActionOwner.current();
    BOOL practice=ODPracticeActionOwner&&ODPracticeActionOwner.current();
    BOOL diagnostic=ODDiagnosticCurrent&&ODDiagnosticCurrent()&&ODDiagnosticInvoke;
    BOOL foreground=ODInGameForeground()&&!ODAnyActionBusy();
    BOOL creatorReady=foreground&&!ODAnyGameActionPending()&&creator&&ODQuickActionOwner.admission(window,controller,renderer)==ODDuoCreatorEntryReady;
    ODDuoCreatorQuickActionReadiness practiceState=foreground&&practice?
        ODPracticeActionOwner.admission(window,controller,renderer):ODDuoCreatorEntryWaiting;
    BOOL practiceRetry=practiceState==ODDuoCreatorEntryRetrySave;
    BOOL practiceReady=foreground&&!ODAnyGameActionPending()&&practice&&
        (practiceState==ODDuoCreatorEntryReady||practiceRetry);
    ODDuoUpdateInGameActions(window,controller,renderer,foreground,creator,creatorReady,practice,practiceReady,practiceRetry,diagnostic,
        ^{ODInvokeInGameAction(NO);},^{ODInvokeInGameAction(YES);},^(UIView *source){ODInvokeDiagnosticAction(source);});
}
static void ODInvokeInGameAction(BOOL practice) {
    ODDuoCreatorQuickActionOwner *owner=practice?ODPracticeActionOwner:ODQuickActionOwner;
    if(!NSThread.isMainThread||!owner||!ODInGameForeground()||ODAnyActionBusy()||ODAnyGameActionPending()||!owner.current()||
       owner.window!=ODInGameWindow||owner.controller!=ODInGameController||owner.renderer!=ODInGameRenderer)return;
    ODDuoCreatorQuickActionReadiness readiness=owner.admission(owner.window,owner.controller,owner.renderer);
    if(readiness!=ODDuoCreatorEntryReady&&!(practice&&readiness==ODDuoCreatorEntryRetrySave))return;
    owner.pending=YES;[owner emit:@"queued-in-app-user-action"];[owner scheduleDrain];
}
static void ODInvokeDiagnosticAction(UIView *sourceView) {
    if(!NSThread.isMainThread||!ODInGameForeground()||ODAnyActionBusy()||!ODDiagnosticCurrent||
       !ODDiagnosticCurrent()||!ODDiagnosticInvoke||sourceView.window!=ODInGameWindow)return;
    ODDiagnosticRunning=YES;NSUInteger generation=++ODDiagnosticGeneration;
    ODRefreshInGameControls();
    ODDiagnosticInvoke(ODInGameController,sourceView,^{
        dispatch_async(dispatch_get_main_queue(),^{
            if(!ODDiagnosticRunning||generation!=ODDiagnosticGeneration)return;
            ODDiagnosticRunning=NO;ODRefreshInGameControls();
            for(ODDuoCreatorQuickActionOwner *owner in ODQuickActionOwners())[owner scheduleDrain];
        });
    });
}
BOOL ODDuoConfigureInGameDiagnosticAction(BOOL (^current)(void),
    void (^invoke)(UIViewController *,UIView *,dispatch_block_t),NSError **error) {
    if(!NSThread.isMainThread||ODDiagnosticInvoke||!current||!invoke){
        if(error)*error=[NSError errorWithDomain:@"OfflineDokkan.NativeQuickAction" code:2
            userInfo:@{NSLocalizedDescriptionKey:@"The diagnostic action could not be configured."}];
        return NO;
    }
    ODDiagnosticCurrent=[current copy];ODDiagnosticInvoke=[invoke copy];ODRefreshInGameControls();return YES;
}

@implementation ODDuoCreatorQuickActionOwner
- (void)emit:(NSString *)outcome {
    ODRefreshInGameControls();
    NSDictionary *state=@{@"entry":self.entry,@"delivery":@"in-app-native-controls-and-app-icon-shortcut",
        @"inGameControls":ODDuoCopyInGameActionState(),
        @"cocosMenuHookInstalled":@(od_creator_menu_cocos_hook_installed()),
        @"menuInstalled":@(self.menuInstalled),@"menuState":self.menuState?:@"not-installed",
        @"pending":@(self.pending),@"presenting":@(self.running),@"outcome":outcome};
    if([self.lastReport isEqual:state])return;
    self.lastReport=state;self.report(state);
}
- (void)installMenu {
    if(self.menuInstalled)return;
    UIApplication *app=UIApplication.sharedApplication;
    NSMutableArray<UIApplicationShortcutItem *> *items=app?([app.shortcutItems mutableCopy]?:[NSMutableArray array]):nil;
    NSArray *staticItems=NSBundle.mainBundle.infoDictionary[@"UIApplicationShortcutItems"];
    NSString *type=self.type;
    BOOL dynamicHas=NO,staticHas=NO;
    for(UIApplicationShortcutItem *item in items)if([item.type isEqual:type])dynamicHas=YES;
    if([staticItems isKindOfClass:NSArray.class])for(id value in staticItems)
        if([value isKindOfClass:NSDictionary.class]&&[value[@"UIApplicationShortcutItemType"] isEqual:type])staticHas=YES;
    od_creator_shortcut_input input={0};
    input.context_current=self.current&&self.current();
    input.application_available=app!=nil;
    input.dynamic_has_type=dynamicHas;input.static_has_type=staticHas;
    input.static_count=[staticItems isKindOfClass:NSArray.class]?(int)staticItems.count:0;
    input.dynamic_count=items?(int)items.count:0;
    od_creator_shortcut_decision decision;
    if(od_creator_shortcut_decide(&input,NULL,&decision))return;
    if(decision.report_unavailable){self.menuState=@"existing-shortcuts-fill-menu";[self emit:@"menu-registration-unavailable"];return;}
    if(!decision.mark_installed||decision.cocos_hook_installed||decision.user_info_grants_access)return;
    if(decision.add_dynamic_item){
        UIApplicationShortcutIcon *icon=[UIApplicationShortcutIcon iconWithType:self.icon];
        [items addObject:[[UIApplicationShortcutItem alloc] initWithType:type
            localizedTitle:self.title
            localizedSubtitle:self.subtitle icon:icon userInfo:nil]];
        app.shortcutItems=items;
    }
    self.menuInstalled=YES;self.menuState=@"registered-not-device-verified";[self emit:@"native-menu-registered"];
}
- (void)scheduleDrain {
    if(!self.pending||self.running||self.drainScheduled)return;
    self.drainScheduled=YES;
    dispatch_async(dispatch_get_main_queue(),^{
        self.drainScheduled=NO;
        if(!self.pending||self.running)return;
        if(!self.current()){self.pending=NO;[self emit:@"native-context-unavailable"];return;}
        if(ODDiagnosticRunning){[self emit:@"waiting-for-diagnostic-dismissal"];return;}
        for(ODDuoCreatorQuickActionOwner *other in ODQuickActionOwners()) {
            if(other!=self&&other.running){[self emit:@"waiting-for-other-native-action"];return;}
        }
        UIWindow *window=self.window;UIViewController *controller=self.controller;UIView *renderer=self.renderer;
        if(!window||!controller||!renderer){[self emit:@"waiting-for-original-scene"];return;}
        ODDuoCreatorQuickActionReadiness readiness=self.admission(window,controller,renderer);
        if(readiness==ODDuoCreatorEntryAlreadyOpen){self.pending=NO;[self emit:self==ODQuickActionOwner?@"editor-already-open":@"practice-already-running"];return;}
        if(readiness==ODDuoCreatorEntryRejected){self.pending=NO;[self emit:@"native-binding-unavailable"];return;}
        BOOL ready=readiness==ODDuoCreatorEntryReady||
            (self==ODPracticeActionOwner&&readiness==ODDuoCreatorEntryRetrySave);
        if(!ready||!self.sourceActive||window.hidden||!window.isKeyWindow||
           window.windowScene.activationState!=UISceneActivationStateForegroundActive||
           window.rootViewController!=controller||!controller.isViewLoaded||controller.view!=renderer||
           renderer.window!=window||controller.presentedViewController||controller.transitionCoordinator){
            [self emit:@"waiting-for-admitted-foreground"];return;
        }
        self.pending=NO;self.running=YES;NSUInteger generation=++self.invocationGeneration;
        [self emit:@"requesting-native-presentation"];
        self.invoke(^(NSError *failure){
            dispatch_async(dispatch_get_main_queue(),^{
                if(!self.running||generation!=self.invocationGeneration)return;
                self.running=NO;
                for(ODDuoCreatorQuickActionOwner *other in ODQuickActionOwners())if(other!=self)[other scheduleDrain];
                [self emit:failure?@"native-presentation-rejected":@"native-presentation-request-accepted"];
            });
        });
    });
}
@end

static BOOL ODConfigureQuickAction(BOOL practice,BOOL (^current)(void),ODDuoCreatorQuickActionAdmission admission,
    ODDuoCreatorQuickActionInvocation invoke,void (^report)(NSDictionary *),NSError **error) {
    if(!NSThread.isMainThread||(practice?ODPracticeActionOwner:ODQuickActionOwner)||!current||!admission||!invoke||!report){
        if(error)*error=[NSError errorWithDomain:@"OfflineDokkan.NativeQuickAction" code:1
            userInfo:@{NSLocalizedDescriptionKey:@"The native action could not be configured. Existing game and editor data were preserved."}];
        return NO;
    }
    ODDuoCreatorQuickActionOwner *owner=[ODDuoCreatorQuickActionOwner new];
    owner.current=current;owner.admission=admission;owner.invoke=invoke;owner.report=report;
    owner.type=practice?@"org.offlinedokkan.practice-battle":ODQuickActionType();
    owner.title=practice?@"Practice Battle":[NSString stringWithUTF8String:od_creator_shortcut_title()];
    owner.subtitle=practice?@"No rewards":[NSString stringWithUTF8String:od_creator_shortcut_subtitle()];
    owner.entry=practice?@"native-practice-battle":@"in-game-creator-menu";
    owner.icon=practice?UIApplicationShortcutIconTypePlay:UIApplicationShortcutIconTypeCompose;
    if(practice)ODPracticeActionOwner=owner;else ODQuickActionOwner=owner;
    [owner emit:@"configured"];return YES;
}
BOOL ODDuoConfigureCreatorQuickAction(BOOL (^current)(void),ODDuoCreatorQuickActionAdmission admission,
    ODDuoCreatorQuickActionInvocation invoke,void (^report)(NSDictionary *),NSError **error) {
    return ODConfigureQuickAction(NO,current,admission,invoke,report,error);
}
BOOL ODDuoConfigurePracticeQuickAction(BOOL (^current)(void),ODDuoCreatorQuickActionAdmission admission,
    ODDuoCreatorQuickActionInvocation invoke,void (^report)(NSDictionary *),NSError **error) {
    return ODConfigureQuickAction(YES,current,admission,invoke,report,error);
}
BOOL ODDuoHandleCreatorQuickAction(UIApplicationShortcutItem *item) {
    if(!NSThread.isMainThread)return NO;
    for(ODDuoCreatorQuickActionOwner *owner in ODQuickActionOwners()) {
        if(![item.type isEqual:owner.type])continue;
        if(!owner.current()){owner.pending=NO;[owner emit:@"native-context-unavailable"];return NO;}
        if(owner.running||owner.pending)return YES;
        owner.pending=YES;[owner emit:@"queued-user-action"];[owner scheduleDrain];return YES;
    }
    return NO;
}
void ODDuoUpdateCreatorQuickAction(UIWindow *window,UIViewController *controller,UIView *renderer,BOOL sourceActive) {
    if(!NSThread.isMainThread)return;
    ODInGameWindow=window;ODInGameController=controller;ODInGameRenderer=renderer;ODInGameSourceActive=sourceActive;
    for(ODDuoCreatorQuickActionOwner *owner in ODQuickActionOwners()) {
        if(!owner.current()){owner.pending=NO;[owner emit:@"native-context-unavailable"];continue;}
        owner.window=window;owner.controller=controller;owner.renderer=renderer;owner.sourceActive=sourceActive;
        [owner installMenu];[owner scheduleDrain];
    }
    ODRefreshInGameControls();
}
void ODDuoRefreshQueuedCreatorQuickAction(void) {
    if(!NSThread.isMainThread)return;
    for(ODDuoCreatorQuickActionOwner *owner in ODQuickActionOwners()) {
        if(!owner.current()){owner.pending=NO;[owner emit:@"native-context-unavailable"];continue;}
        [owner installMenu];[owner scheduleDrain];
    }
    ODRefreshInGameControls();
}
void ODDuoDisconnectCreatorQuickAction(UIWindow *window) {
    if(!NSThread.isMainThread)return;
    ODDuoRemoveInGameActions(window);
    if(ODInGameWindow==window){
        // A vanished scene must not leave the next admitted scene blocked on a
        // share-sheet completion that UIKit may no longer deliver. Invalidate
        // the generation so an old late completion cannot release a new sheet.
        ODDiagnosticGeneration++;ODDiagnosticRunning=NO;
        ODInGameWindow=nil;ODInGameController=nil;ODInGameRenderer=nil;ODInGameSourceActive=NO;
    }
    for(ODDuoCreatorQuickActionOwner *owner in ODQuickActionOwners()) {
        if(owner.window!=window)continue;
        owner.window=nil;owner.controller=nil;owner.renderer=nil;owner.sourceActive=NO;
        if(owner.pending)[owner emit:@"waiting-for-original-scene"];
    }
}
