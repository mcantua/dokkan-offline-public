#import "RefreshCoordinator.h"
#import <BackgroundTasks/BackgroundTasks.h>
#import <UserNotifications/UserNotifications.h>
#import <math.h>

static NSString * const AICanonicalRefreshTaskIdentifier = @"org.tin.appinstaller.refresh";
static NSString * const AIExpiryPrefix = @"org.tin.appinstaller.expiry.";
static NSString * const AIRefreshNeededIdentifier = @"org.tin.appinstaller.refresh-needed";
static NSString * const AIExpiryMetadataKey = @"org.tin.appinstaller.expiry-metadata";
static const NSTimeInterval AIWarningLead = 2.0 * 24.0 * 60.0 * 60.0;

@interface AIRefreshCoordinator ()
@property (nonatomic) BOOL registrationSucceeded;
@property (nonatomic) BOOL lastScheduleSucceeded;
@property (nonatomic) BOOL registrationAttempted;
@property (nonatomic, copy, nullable) NSString *taskIdentifier;
@property (nonatomic) NSUInteger reminderGeneration;
@property (nonatomic, copy) NSArray<NSDictionary *> *records;
@property (nonatomic, strong, nullable) BGAppRefreshTask *activeTask;
@property (nonatomic, strong, nullable) NSUUID *activeRun;
@end

@implementation AIRefreshCoordinator

+ (instancetype)shared {
    static AIRefreshCoordinator *coordinator;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ coordinator = [AIRefreshCoordinator new]; });
    return coordinator;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        id stored = [NSUserDefaults.standardUserDefaults objectForKey:AIExpiryMetadataKey];
        _records = [self sanitizedRecords:[stored isKindOfClass:NSArray.class] ? stored : @[]];
    }
    return self;
}

- (NSArray<NSDictionary *> *)sanitizedRecords:(NSArray *)records {
    NSMutableDictionary<NSString *, NSDictionary *> *unique = [NSMutableDictionary new];
    for (id item in records) {
        if (![item isKindOfClass:NSDictionary.class]) continue;
        NSString *bundle = item[@"bundleId"];
        NSNumber *expiry = item[@"expiry"];
        NSString *name = item[@"name"];
        if (![bundle isKindOfClass:NSString.class] || !bundle.length || bundle.length > 255) continue;
        if (![expiry isKindOfClass:NSNumber.class] || !isfinite(expiry.doubleValue) || expiry.doubleValue <= 0) continue;
        if (![name isKindOfClass:NSString.class] || !name.length) name = @"An installed app";
        if (name.length > 120) name = [name substringToIndex:120];
        unique[bundle] = @{@"bundleId":bundle, @"name":name, @"expiry":@(expiry.doubleValue)};
    }
    return [unique.allValues sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [a[@"expiry"] compare:b[@"expiry"]];
    }];
}

- (NSString *)resolvedTaskIdentifier {
    id configured = [NSBundle.mainBundle objectForInfoDictionaryKey:@"BGTaskSchedulerPermittedIdentifiers"];
    if (![configured isKindOfClass:NSArray.class]) return nil;
    NSString *bundle = NSBundle.mainBundle.bundleIdentifier;
    NSString *actual = bundle.length ? [bundle stringByAppendingString:@".refresh"] : nil;
    // Signing can rewrite both the bundle ID and its permitted background IDs.
    // Register only an identifier explicitly present in this installed artifact.
    if (actual && [configured containsObject:actual]) return actual;
    if ([configured containsObject:AICanonicalRefreshTaskIdentifier]) return AICanonicalRefreshTaskIdentifier;
    return nil;
}

- (void)registerTasks {
    NSAssert(NSThread.isMainThread, @"Register background tasks at application launch on the main thread.");
    if (self.registrationAttempted) return;
    self.registrationAttempted = YES;
    self.taskIdentifier = [self resolvedTaskIdentifier];
    if (!self.taskIdentifier.length) {
        self.registrationSucceeded = NO; self.lastScheduleSucceeded = NO;
        return;
    }
    __weak typeof(self) weakSelf = self;
    self.registrationSucceeded = [BGTaskScheduler.sharedScheduler registerForTaskWithIdentifier:self.taskIdentifier
        usingQueue:dispatch_get_main_queue() launchHandler:^(__kindof BGTask *task) {
            AIRefreshCoordinator *self = weakSelf;
            if (!self || ![task isKindOfClass:BGAppRefreshTask.class]) {
                [task setTaskCompletedWithSuccess:NO];
                return;
            }
            [self handleBackgroundTask:(BGAppRefreshTask *)task];
        }];
}

- (void)schedule {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self schedule]; });
        return;
    }
    if (!self.registrationSucceeded || !self.taskIdentifier.length) { self.lastScheduleSucceeded = NO; return; }
    if (!self.records.count) {
        [BGTaskScheduler.sharedScheduler cancelTaskRequestWithIdentifier:self.taskIdentifier];
        self.lastScheduleSucceeded = NO;
        return;
    }
    NSDate *now = [NSDate date];
    NSTimeInterval delay = 6.0 * 60.0 * 60.0;
    NSDictionary *first = self.records.firstObject;
    if (first) {
        NSTimeInterval untilWarning = [first[@"expiry"] doubleValue] - now.timeIntervalSince1970 - AIWarningLead;
        // Never spin in a tight resubmission loop when expiry has already passed.
        delay = MAX(15.0 * 60.0, MIN(delay, untilWarning));
    }
    BGAppRefreshTaskRequest *request = [[BGAppRefreshTaskRequest alloc] initWithIdentifier:self.taskIdentifier];
    request.earliestBeginDate = [now dateByAddingTimeInterval:delay];
    [BGTaskScheduler.sharedScheduler cancelTaskRequestWithIdentifier:self.taskIdentifier];
    NSError *error = nil;
    self.lastScheduleSucceeded = [BGTaskScheduler.sharedScheduler submitTaskRequest:request error:&error];
    // Scheduler errors intentionally remain unlogged; callers can inspect the boolean state.
}

- (void)handleBackgroundTask:(BGAppRefreshTask *)task {
    // This handler and every terminal transition are serialized on the main queue.
    [self schedule];
    if (self.activeTask || !self.refreshHandler || !self.canRefreshWithoutInteraction || !self.canRefreshWithoutInteraction()) {
        [self recordRefreshFailure];
        [task setTaskCompletedWithSuccess:NO];
        return;
    }
    self.activeTask = task;
    NSUUID *run = [NSUUID UUID];
    self.activeRun = run;
    __weak typeof(self) weakSelf = self;
    task.expirationHandler = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            AIRefreshCoordinator *self = weakSelf;
            if (!self || ![self.activeRun isEqual:run]) return;
            void (^cancel)(void) = self.cancelHandler;
            // Read the retained active task here. Capturing the original task in its own
            // expiration handler would form task -> handler -> task.
            BGAppRefreshTask *expiredTask = self.activeTask;
            // Mark it terminal first: cancellation may synchronously invoke the operation completion.
            self.activeRun = nil;
            self.activeTask = nil;
            expiredTask.expirationHandler = nil;
            if (cancel) cancel();
            [expiredTask setTaskCompletedWithSuccess:NO];
            [self recordRefreshFailure];
        });
    };
    self.refreshHandler(^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            AIRefreshCoordinator *self = weakSelf;
            if (!self || ![self.activeRun isEqual:run]) return;
            self.activeRun = nil;
            self.activeTask = nil;
            task.expirationHandler = nil;
            [task setTaskCompletedWithSuccess:success];
            if (success) {
                [UNUserNotificationCenter.currentNotificationCenter removePendingNotificationRequestsWithIdentifiers:@[AIRefreshNeededIdentifier]];
                [UNUserNotificationCenter.currentNotificationCenter removeDeliveredNotificationsWithIdentifiers:@[AIRefreshNeededIdentifier]];
                [self rebuildExpiryReminders];
            } else {
                [self recordRefreshFailure];
            }
        });
    });
}

- (void)updateAppRecords:(NSArray<NSDictionary *> *)records {
    if (!NSThread.isMainThread) {
        NSArray *snapshot = [records copy];
        dispatch_async(dispatch_get_main_queue(), ^{ [self updateAppRecords:snapshot]; });
        return;
    }
    self.records = [self sanitizedRecords:records ?: @[]];
    // Names, bundle identifiers and dates are non-secret metadata; no account/session data is stored.
    [NSUserDefaults.standardUserDefaults setObject:self.records forKey:AIExpiryMetadataKey];
    [self rebuildExpiryReminders];
    [self schedule];
}

- (void)requestNotificationAuthorization:(void (^)(BOOL))completion {
    // Called explicitly by the foreground UI, never by registerTasks/schedule/background handlers.
    [UNUserNotificationCenter.currentNotificationCenter requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
        completionHandler:^(BOOL granted, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) [self rebuildExpiryReminders];
                if (completion) completion(granted);
            });
        }];
}

- (void)rebuildExpiryReminders {
    NSAssert(NSThread.isMainThread, @"Notification state is serialized on the main thread.");
    NSUInteger generation = ++self.reminderGeneration;
    NSArray<NSDictionary *> *records = self.records;
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        BOOL permitted = settings.authorizationStatus == UNAuthorizationStatusAuthorized ||
                         settings.authorizationStatus == UNAuthorizationStatusProvisional ||
                         settings.authorizationStatus == UNAuthorizationStatusEphemeral;
        [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *requests) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (generation != self.reminderGeneration) return;
                NSMutableArray<NSString *> *owned = [NSMutableArray new];
                for (UNNotificationRequest *request in requests) {
                    if ([request.identifier hasPrefix:AIExpiryPrefix]) [owned addObject:request.identifier];
                }
                [center removePendingNotificationRequestsWithIdentifiers:owned];
                if (!permitted) return;
                NSTimeInterval now = NSDate.date.timeIntervalSince1970;
                NSUInteger count = 0;
                for (NSDictionary *record in records) {
                    // iOS has a pending-request limit; prioritize the nearest expirations and reserve room.
                    if (count++ >= 60) break;
                    NSTimeInterval expiry = [record[@"expiry"] doubleValue];
                    BOOL expired = expiry <= now;
                    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
                    content.title = expired ? @"App refresh is overdue" : @"App refresh reminder";
                    if (expired) {
                        content.body = @"An app’s signing profile has expired. Open App Installer to check recovery options.";
                    } else {
                        content.body = @"An app’s signing profile is near expiry. Open App Installer and refresh your apps.";
                    }
                    content.sound = UNNotificationSound.defaultSound;
                    // A reminder is scheduled from the real profile expiry, not an assumed seven-day duration.
                    NSTimeInterval interval = MAX(1.0, expiry - AIWarningLead - now);
                    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:interval repeats:NO];
                    NSString *identifier = [AIExpiryPrefix stringByAppendingString:record[@"bundleId"]];
                    [center addNotificationRequest:[UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger]
                        withCompletionHandler:nil];
                }
            });
        }];
    }];
}

- (void)recordRefreshFailure {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self recordRefreshFailure]; });
        return;
    }
    NSDictionary *first = self.records.firstObject;
    if (!first || [first[@"expiry"] doubleValue] - NSDate.date.timeIntervalSince1970 > AIWarningLead) return;
    NSUInteger generation = self.reminderGeneration;
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        BOOL permitted = settings.authorizationStatus == UNAuthorizationStatusAuthorized ||
                         settings.authorizationStatus == UNAuthorizationStatusProvisional ||
                         settings.authorizationStatus == UNAuthorizationStatusEphemeral;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!permitted || generation != self.reminderGeneration) return;
            UNMutableNotificationContent *content = [UNMutableNotificationContent new];
            content.title = @"Open App Installer to refresh";
            content.body = @"Background refresh could not finish. Unlock your iPhone, open App Installer, and tap Refresh all before your apps expire.";
            content.sound = UNNotificationSound.defaultSound;
            // One fixed identifier replaces an earlier pending warning instead of piling up duplicates.
            UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
            [center addNotificationRequest:[UNNotificationRequest requestWithIdentifier:AIRefreshNeededIdentifier content:content trigger:trigger]
                withCompletionHandler:nil];
        });
    }];
}

- (void)cancelScheduledWork {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self cancelScheduledWork]; });
        return;
    }
    BGAppRefreshTask *task = self.activeTask;
    self.activeRun = nil;
    self.activeTask = nil;
    task.expirationHandler = nil;
    if (task) {
        if (self.cancelHandler) self.cancelHandler();
        [task setTaskCompletedWithSuccess:NO];
    }
    if (self.taskIdentifier.length) {
        [BGTaskScheduler.sharedScheduler cancelTaskRequestWithIdentifier:self.taskIdentifier];
    }
    self.records = @[];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:AIExpiryMetadataKey];
    [self rebuildExpiryReminders];
    [UNUserNotificationCenter.currentNotificationCenter removePendingNotificationRequestsWithIdentifiers:@[AIRefreshNeededIdentifier]];
    [UNUserNotificationCenter.currentNotificationCenter removeDeliveredNotificationsWithIdentifiers:@[AIRefreshNeededIdentifier]];
}
@end
