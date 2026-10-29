#import "InstallerService.h"
#import "SecureStore.h"
#import "PairingStore.h"
#import "RefreshCoordinator.h"
#import "../core/app_installer.h"
#import <UIKit/UIKit.h>
#import <math.h>
#import <sys/stat.h>

// Implemented by the Rust engine; declarations also live in app_installer.h.
extern AIStatus ai_initialize(const char *work_dir);
extern AIStatus ai_restore_session(void);
extern AIStatus ai_import_pairing(const uint8_t *bytes, size_t length);
extern AIStatus ai_sign_out(void);
extern void ai_cancel(void);
extern char *ai_poll_event_json(void);
extern char *ai_snapshot_json(void);
extern void ai_free_string(char *value);

@interface AIInstallerService ()
@property (nonatomic, strong) NSURL *workDirectory;
@property (nonatomic, strong) AIPairingStore *pairingStore;
@property (nonatomic, strong) NSTimer *pollTimer;
@property (nonatomic, copy) NSDictionary *engineState;
@property (nonatomic, copy) NSArray<NSDictionary *> *appRecords;
@property (nonatomic, copy) NSString *localMessage;
@property (nonatomic, copy) void (^backgroundCompletion)(BOOL);
@property (nonatomic) BOOL initialized;
@property (nonatomic) BOOL authorizing;
@property (nonatomic) BOOL signingForInstall;
@property (nonatomic) BOOL cancelling;
@property (nonatomic) BOOL staging;
@property (nonatomic) BOOL pairingBackupReady;
@property (nonatomic) BOOL biometricMigrationPending;
@property (nonatomic) NSUInteger operationGeneration;
@property (nonatomic) NSUInteger messageGeneration;
@property (nonatomic, strong) NSURL *pendingIPA;
@property (nonatomic, strong) NSNumber *pendingOperationId;
@property (nonatomic, strong) NSNumber *backgroundOperationId;
@property (nonatomic) BOOL pendingIPASecurityScope;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic) NSUInteger backgroundExecutionGeneration;
@property (nonatomic) BOOL foregroundRefreshPending;
@property (nonatomic) BOOL foregroundRefreshNeedsCheck;
@property (nonatomic, strong) NSDate *lastForegroundRefreshAttempt;
@property (nonatomic) BOOL notificationsSuppressedForExplicitSignOut;
@property (nonatomic) BOOL pairingVerified;
@property (nonatomic) BOOL pairingCheckRequested;
@property (nonatomic) BOOL pairingFileKnownPresent;
@end

@implementation AIInstallerService
+ (instancetype)shared {
    static AIInstallerService *service; static dispatch_once_t once;
    dispatch_once(&once, ^{ service = [AIInstallerService new]; });
    return service;
}
- (instancetype)init {
    if ((self = [super init])) {
        _engineState = @{}; _appRecords = @[];
        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        _notificationsSuppressedForExplicitSignOut = [NSUserDefaults.standardUserDefaults boolForKey:@"org.tin.appinstaller.explicit-signout-reminder-pause"];
        id lastAttempt = [NSUserDefaults.standardUserDefaults objectForKey:@"org.tin.appinstaller.last-foreground-refresh-attempt"];
        if ([lastAttempt isKindOfClass:NSDate.class]) _lastForegroundRefreshAttempt = lastAttempt;
        NSURL *support = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
        _workDirectory = [support URLByAppendingPathComponent:@"AppInstaller" isDirectory:YES];
        NSError *error = nil;
        BOOL created = [NSFileManager.defaultManager createDirectoryAtURL:_workDirectory withIntermediateDirectories:YES
            attributes:@{NSFileProtectionKey:NSFileProtectionComplete} error:&error];
        if (created) {
            [_workDirectory setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
            _pairingStore = [[AIPairingStore alloc] initWithDirectory:_workDirectory];
        } else { _localMessage = @"App Installer could not open its protected workspace."; }
        __weak typeof(self) weakSelf = self;
        [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationProtectedDataWillBecomeUnavailable object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
            [AISecureStore endSession];
            weakSelf.pairingVerified = NO; weakSelf.pairingCheckRequested = YES;
            [weakSelf cancel];
            ai_lock(); [weakSelf readEngineState];
        }];
        [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
            weakSelf.pairingVerified = NO; weakSelf.pairingCheckRequested = YES;
            weakSelf.pairingFileKnownPresent = weakSelf.pairingBackupReady || [weakSelf hasSavedMetadataForKey:@"engine.pairing"];
            weakSelf.foregroundRefreshNeedsCheck = YES;
            [weakSelf maybeStartForegroundDueRefresh];
            [weakSelf maybeCheckPairing];
        }];
        [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
            AIInstallerService *self = weakSelf; if (!self) return;
            self.foregroundRefreshNeedsCheck = NO;
            if (self.authorizing || self.biometricMigrationPending) {
                [AISecureStore endSession]; [self cancel];
            } else if (self.backgroundTaskIdentifier == UIBackgroundTaskInvalid &&
                       ([self.snapshot[@"busy"] boolValue] || self.foregroundRefreshPending)) {
                [self cancel];
                [self emit:@"error" message:@"Keep App Installer open to finish this task. iOS did not grant background execution."];
            }
        }];
        AIRefreshCoordinator *refresh = AIRefreshCoordinator.shared;
        refresh.canRefreshWithoutInteraction = ^BOOL {
            AIInstallerService *self = weakSelf;
            return self && !self.notificationsSuppressedForExplicitSignOut && [AISecureStore sessionAuthorized] && UIApplication.sharedApplication.protectedDataAvailable &&
                [self.snapshot[@"loginStatus"] isEqual:@"signed_in"] && [self.snapshot[@"paired"] boolValue] && ![self.snapshot[@"busy"] boolValue];
        };
        refresh.refreshHandler = ^(void (^completion)(BOOL)) {
            AIInstallerService *self = weakSelf;
            if (!self || self.backgroundCompletion) { completion(NO); return; }
            [self poll];
            self.backgroundCompletion = completion;
            if (ai_refresh_all() != AI_OK) { [self finishBackground:NO]; return; }
            [self readEngineState];
            self.backgroundOperationId = self.engineState[@"activeOperationId"];
        };
        refresh.cancelHandler = ^{ [weakSelf cancel]; };
        // Recover a crash between persisting explicit sign-out intent and clearing OS requests.
        if (_notificationsSuppressedForExplicitSignOut) [refresh cancelScheduledWork];
    }
    return self;
}
- (NSDictionary *)objectFromJSON:(char *)json {
    if (!json) return nil;
    // JSON comes only from our Rust engine, and has no account credentials.
    NSData *data = [[NSString stringWithUTF8String:json] dataUsingEncoding:NSUTF8StringEncoding];
    ai_free_string(json);
    if (!data) return nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [object isKindOfClass:NSDictionary.class] ? object : nil;
}
- (void)readEngineState {
    NSDictionary *state = [self objectFromJSON:ai_snapshot_json()];
    if (state) {
        self.engineState = state;
        NSArray *records = state[@"apps"] ?: state[@"appRecords"];
        if ([records isKindOfClass:NSArray.class]) self.appRecords = records;
    }
}
- (NSNumber *)ownExpiry {
    NSNumber *provided = self.engineState[@"ownExpiry"];
    if ([provided isKindOfClass:NSNumber.class] && provided.doubleValue > 0) return provided;
    // Read expiry metadata only. The CMS is not trusted for signing/authorization here.
    NSURL *profileURL = [NSBundle.mainBundle URLForResource:@"embedded" withExtension:@"mobileprovision"];
    if (!profileURL) return @0;
    NSData *profile = [NSData dataWithContentsOfURL:profileURL];
    if (!profile.length || profile.length > 4 * 1024 * 1024) return @0;
    NSData *startMarker = [@"<plist" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *endMarker = [@"</plist>" dataUsingEncoding:NSUTF8StringEncoding];
    NSRange start = [profile rangeOfData:startMarker options:0 range:NSMakeRange(0, profile.length)];
    if (start.location == NSNotFound) return @0;
    NSRange end = [profile rangeOfData:endMarker options:0 range:NSMakeRange(start.location, profile.length-start.location)];
    if (end.location == NSNotFound) return @0;
    NSData *xml = [profile subdataWithRange:NSMakeRange(start.location, NSMaxRange(end)-start.location)];
    id object = [NSPropertyListSerialization propertyListWithData:xml options:NSPropertyListImmutable format:nil error:nil];
    NSDate *date = [object isKindOfClass:NSDictionary.class] ? object[@"ExpirationDate"] : nil;
    return [date isKindOfClass:NSDate.class] ? @(date.timeIntervalSince1970) : @0;
}
- (NSDictionary *)snapshot {
    NSMutableDictionary *s = [self.engineState mutableCopy] ?: [NSMutableDictionary new];
    if (!s[@"loginStatus"]) s[@"loginStatus"] = @"signed_out";
    BOOL pairingAuthorizationCurrent = [AISecureStore sessionAuthorized];
    BOOL verifiedPairing = self.pairingVerified && pairingAuthorizationCurrent;
    s[@"pairingFilePresent"] = @(self.pairingFileKnownPresent || self.pairingBackupReady);
    s[@"pairingVerified"] = @(verifiedPairing);
    s[@"paired"] = @([s[@"paired"] boolValue] && self.pairingBackupReady && verifiedPairing);
    if (!s[@"busy"]) s[@"busy"] = @NO;
    s[@"busy"] = @([s[@"busy"] boolValue] || self.authorizing || self.staging || self.signingForInstall || self.pendingIPA != nil);
    s[@"backendReady"] = @(self.initialized && ai_backend_ready());
    s[@"securitySetupRequired"] = @([AISecureStore initialSetupRequired]);
    s[@"biometricEnabled"] = @(![AISecureStore initialSetupRequired] && [AISecureStore biometricsEnabled]);
    s[@"ownExpiry"] = [self ownExpiry];
    if (self.localMessage.length) s[@"statusMessage"] = self.localMessage;
    else if (!verifiedPairing && ![s[@"busy"] boolValue] &&
             self.pairingFileKnownPresent && !self.notificationsSuppressedForExplicitSignOut) {
        s[@"statusMessage"] = [AISecureStore sessionAuthorized] ?
            @"Pairing has not been verified for this foreground session. Keep LocalDevVPN connected and check again." :
            @"Unlock saved sign-in to check this iPhone’s pairing file.";
    }
    return s;
}
- (void)emit:(NSString *)type message:(NSString *)message {
    if (message.length) { self.localMessage = message; ++self.messageGeneration; }
    NSMutableDictionary *event = [@{@"type":type} mutableCopy];
    if (message.length) event[@"message"] = message;
    if (self.eventHandler) self.eventHandler(event);
}
- (void)resume {
    if (!NSThread.isMainThread) { dispatch_async(dispatch_get_main_queue(), ^{ [self resume]; }); return; }
    if (!self.initialized && self.pairingStore) {
        self.initialized = ai_initialize(self.workDirectory.path.fileSystemRepresentation) == AI_OK;
        if (self.initialized) ai_register_self_bundle(NSBundle.mainBundle.bundlePath.fileSystemRepresentation);
    }
    if (!self.pollTimer) {
        self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(poll) userInfo:nil repeats:YES];
    }
    [self readEngineState]; [self poll]; [self updateReminders];
    self.foregroundRefreshNeedsCheck = YES;
    if (!self.pairingVerified) self.pairingCheckRequested = YES;
    self.pairingFileKnownPresent = self.pairingBackupReady || [self hasSavedMetadataForKey:@"engine.pairing"];
    [self maybeStartForegroundDueRefresh]; [self maybeCheckPairing];
}
- (void)poll {
    for (NSUInteger i=0; i<32; ++i) {
        NSDictionary *event = [self objectFromJSON:ai_poll_event_json()];
        if (!event) break;
        NSString *type = [event[@"type"] isKindOfClass:NSString.class] ? event[@"type"] : @"state";
        [self readEngineState];
        NSUInteger messageGeneration = self.messageGeneration;
        NSNumber *eventId = event[@"operationId"];
        NSNumber *activeId = self.engineState[@"activeOperationId"];
        if (eventId && activeId && ![eventId isEqual:activeId]) continue;
        BOOL matchesPending = eventId && [eventId isEqual:self.pendingOperationId];
        BOOL matchesBackground = eventId && [eventId isEqual:self.backgroundOperationId];
        if ([event[@"operation"] isEqual:@"list"] && [type isEqual:@"done"]) {
            self.pairingVerified = YES; self.pairingFileKnownPresent = YES; self.pairingCheckRequested = NO;
        } else if ([event[@"operation"] isEqual:@"list"] && ([type isEqual:@"error"] || [type isEqual:@"cancelled"])) {
            self.pairingVerified = NO; self.pairingCheckRequested = NO;
        }
        if ([type isEqual:@"signed"] && matchesPending && self.signingForInstall && !self.cancelling) {
            self.signingForInstall = NO;
            if (ai_install_ipa(self.pendingIPA.path.fileSystemRepresentation) != AI_OK) {
                [self releasePendingIPA];
                [self emit:@"error" message:@"The signed app could not be sent to the iPhone."];
            } else {
                [self readEngineState]; self.pendingOperationId = self.engineState[@"activeOperationId"];
            }
        }
        if ([type isEqual:@"done"] && [event[@"operation"] isEqual:@"login"] &&
            [self.engineState[@"loginStatus"] isEqual:@"signed_in"]) {
            // Only a genuine current-generation engine login success resumes automatic reminders.
            self.notificationsSuppressedForExplicitSignOut = NO;
            [NSUserDefaults.standardUserDefaults removeObjectForKey:@"org.tin.appinstaller.explicit-signout-reminder-pause"];
        }
        if ([type isEqual:@"done"] || [type isEqual:@"error"] || [type isEqual:@"cancelled"]) {
            if (matchesPending) {
                self.signingForInstall = NO; self.cancelling = NO; [self releasePendingIPA];
            }
            NSString *operation = event[@"operation"];
            if (matchesBackground && [operation isEqual:@"refresh_all"]) [self finishBackground:[type isEqual:@"done"]];
            if (![type isEqual:@"done"]) {
                // Do not hide a real operation error behind an automatic pairing recheck.
                self.pairingVerified = NO; self.pairingCheckRequested = NO;
                BOOL wasRefreshAttempt = [operation isEqual:@"refresh_all"] || matchesBackground || self.foregroundRefreshPending;
                self.foregroundRefreshPending = NO;
                if (wasRefreshAttempt) [AIRefreshCoordinator.shared recordRefreshFailure];
            }
            if ([type isEqual:@"done"] && [operation isEqual:@"refresh_all"]) self.foregroundRefreshPending = NO;
            [self updateReminders];
        }
        if (messageGeneration == self.messageGeneration) self.localMessage = nil;
        if (self.eventHandler) self.eventHandler(event);
        // Revalidate real device state before an open-app due-refresh can proceed.
        if ([type isEqual:@"done"] && [event[@"operation"] isEqual:@"login"]) {
            if ([self.engineState[@"paired"] boolValue] && self.pairingBackupReady) {
                if (ai_list_installed() != AI_OK && self.foregroundRefreshPending) {
                    self.foregroundRefreshPending = NO;
                    [self emit:@"error" message:@"Open App Installer and check LocalDevVPN before refreshing."];
                }
                [self readEngineState];
            } else if (self.foregroundRefreshPending) {
                self.foregroundRefreshPending = NO;
                [self emit:@"error" message:@"Import a pairing file and save its protected backup before refreshing."];
            }
        } else if ([type isEqual:@"done"] && [event[@"operation"] isEqual:@"list"] && self.foregroundRefreshPending) {
            // Real foreground approval was obtained by maybeStartForegroundDueRefresh.
            if (!UIApplication.sharedApplication.protectedDataAvailable || ![AISecureStore sessionAuthorized] ||
                !self.pairingBackupReady || ai_refresh_all() != AI_OK) {
                self.foregroundRefreshPending = NO;
                [self emit:@"error" message:@"Unlock App Installer and tap Refresh all to continue."];
            }
            [self readEngineState];
        }
    }
    [self readEngineState];
    [self endBackgroundExecutionIfIdle];
    [self maybeStartForegroundDueRefresh]; [self maybeCheckPairing];
}
- (void)updateReminders {
    // Temporary session lock/expiry keeps warnings. An explicitly approved sign-out does not.
    if (self.notificationsSuppressedForExplicitSignOut) return;
    NSMutableArray *records = [self.appRecords mutableCopy] ?: [NSMutableArray new];
    NSNumber *own = [self ownExpiry];
    if (own.doubleValue > 0) [records addObject:@{@"name":@"App Installer",@"bundleId":NSBundle.mainBundle.bundleIdentifier ?: @"org.tin.appinstaller",@"expiry":own}];
    [AIRefreshCoordinator.shared updateAppRecords:records];
}
- (void)finishBackground:(BOOL)success {
    void (^completion)(BOOL) = self.backgroundCompletion;
    self.backgroundCompletion = nil; self.backgroundOperationId = nil;
    if (completion) completion(success);
}
- (void)authorize:(NSString *)reason action:(void (^)(void))action {
    if (!self.initialized || !ai_backend_ready()) { [self emit:@"error" message:@"The signing engine is unavailable in this build."]; return; }
    if ([self.snapshot[@"busy"] boolValue]) { [self emit:@"error" message:@"Please wait for the current task to finish."]; return; }
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) { [self emit:@"error" message:@"Open and unlock App Installer to continue."]; return; }
    if ([AISecureStore biometricsEnabled] && ![AISecureStore initialSetupRequired]) {
        LAContext *probe = [LAContext new]; NSError *probeError = nil;
        BOOL available = [probe canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&probeError];
        [probe invalidate];
        if (!available) {
            [self emit:@"error" message:@"Face ID or Touch ID is unavailable for this protected account. Check enrollment or unlock your iPhone, then try again."]; return;
        }
    }
    self.authorizing = YES;
    NSUInteger generation = ++self.operationGeneration;
    [AISecureStore authenticateSessionWithReason:reason completion:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (generation != self.operationGeneration) return;
            self.authorizing = NO;
            if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive ||
                !UIApplication.sharedApplication.protectedDataAvailable || ![AISecureStore sessionAuthorized]) {
                self.foregroundRefreshPending = NO;
                [self emit:@"error" message:@"Open and unlock App Installer to continue."]; return;
            }
            if (!success) { self.foregroundRefreshPending = NO; [self emit:@"error" message:@"Unlock was cancelled or unavailable. Your saved data was kept."]; return; }
            self.localMessage = nil; self.cancelling = NO;
            self.pairingVerified = NO; self.pairingCheckRequested = YES;
            NSData *savedPairing = [self.pairingStore pairingDataWithError:nil];
            self.pairingBackupReady = NO;
            if (savedPairing.length && ai_import_pairing(savedPairing.bytes, savedPairing.length) == AI_OK) {
                // Replace the single encrypted backup from the validated primary before permitting device work.
                self.pairingBackupReady = [self.pairingStore importValidatedPairingData:savedPairing error:nil];
            }
            [self beginBackgroundExecution];
            action(); [self readEngineState];
            [self endBackgroundExecutionIfIdle];
        });
    }];
}
- (void)signInWithEmail:(NSString *)email password:(NSString *)password {
    if (!email.length && !password.length) {
        [self authorize:@"Unlock your saved Apple session" action:^{
            if (ai_restore_session() != AI_OK) [self emit:@"error" message:@"No saved session is ready. Sign in to continue."];
        }];
        return;
    }
    if (!email.length || !password.length) { [self emit:@"error" message:@"Enter your Apple ID and password."]; return; }
    [self authorize:@"Unlock secure Apple account storage" action:^{
        if (ai_login(email.UTF8String, password.UTF8String) != AI_OK) [self emit:@"error" message:@"Sign-in could not start. Please try again."];
    }];
}
- (void)submitCode:(NSString *)code {
    if (code.length != 6 || [code rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet].location != NSNotFound) {
        [self emit:@"error" message:@"Enter the six-digit verification code."]; return;
    }
    if (ai_submit_2fa(code.UTF8String) != AI_OK) [self emit:@"error" message:@"No verification request is waiting for a code."];
    [self readEngineState];
}
- (void)selectTeam:(NSString *)teamId {
    if (!teamId.length || ai_select_team(teamId.UTF8String) != AI_OK) {
        [self emit:@"error" message:@"Choose one of the developer teams listed for this sign-in."];
    }
    [self readEngineState];
}
- (void)requestVerificationCode:(NSInteger)action numberID:(uint32_t)numberID {
    if (action < 0 || action > 2 || ai_request_2fa((int32_t)action, numberID) != AI_OK) {
        [self emit:@"error" message:@"That verification option is not available right now."];
    }
    [self readEngineState];
}
- (void)importPairingFile:(NSURL *)url {
    [self authorize:@"Unlock secure pairing storage" action:^{
        self.pairingVerified = NO; self.pairingCheckRequested = NO;
        BOOL scoped = [url startAccessingSecurityScopedResource];
        NSNumber *size = nil; [url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
        NSData *data = (size && size.unsignedLongLongValue <= 1024*1024) ? [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:nil] : nil;
        if (scoped) [url stopAccessingSecurityScopedResource];
        if (!data.length || ai_import_pairing(data.bytes, data.length) != AI_OK) {
            [self emit:@"error" message:@"That pairing file could not be validated or saved. Please check it and try again."]; return;
        }
        NSError *error = nil;
        self.pairingBackupReady = [self.pairingStore importValidatedPairingData:data error:&error];
        if (!self.pairingBackupReady) {
            [self emit:@"error" message:@"Pairing was validated, but its protected backup could not be saved. Import it again before continuing."]; return;
        }
        self.pairingFileKnownPresent = YES; self.pairingCheckRequested = YES;
        [self readEngineState];
        [self emit:@"state" message:@"Pairing file saved securely. Checking this iPhone through LocalDevVPN…"];
        [self maybeCheckPairing];
    }];
}
- (void)installIPA:(NSURL *)url {
    [self authorize:@"Approve signing and installing this app" action:^{
        if (!self.pairingBackupReady) { [self emit:@"error" message:@"Import a pairing file and save its protected backup before installing apps."]; return; }
        if (!url.isFileURL) { [self emit:@"error" message:@"Choose an IPA from Files."]; return; }
        self.staging = YES; [self emit:@"preparing" message:@"Preparing the IPA in protected storage…"];
        NSUInteger generation = self.operationGeneration;
        NSURL *imports = [self.workDirectory URLByAppendingPathComponent:@"imports" isDirectory:YES];
        NSURL *copy = [imports URLByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"ipa"]];
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            BOOL scoped = [url startAccessingSecurityScopedResource];
            __block BOOL copied = NO;
            NSError *error = nil;
            BOOL directory = [NSFileManager.defaultManager createDirectoryAtURL:imports withIntermediateDirectories:YES
                attributes:@{NSFileProtectionKey:NSFileProtectionComplete} error:&error];
            if (directory) {
                NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
                [coordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingWithoutChanges error:&error byAccessor:^(NSURL *readURL) {
                    NSNumber *size = nil, *regular = nil;
                    [readURL getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
                    [readURL getResourceValue:&regular forKey:NSURLIsRegularFileKey error:nil];
                    if (regular.boolValue && size.unsignedLongLongValue > 0 && size.unsignedLongLongValue <= 4ULL*1024*1024*1024) {
                        copied = [NSFileManager.defaultManager copyItemAtURL:readURL toURL:copy error:nil];
                        // Do not apply attributes through a copied symlink/hardlink to the user's original file.
                        struct stat copiedInfo;
                        if (copied && (lstat(copy.fileSystemRepresentation, &copiedInfo) != 0 ||
                            !S_ISREG(copiedInfo.st_mode) || copiedInfo.st_nlink != 1)) copied = NO;
                        if (copied) copied = [NSFileManager.defaultManager setAttributes:@{NSFileProtectionKey:NSFileProtectionComplete}
                            ofItemAtPath:copy.path error:nil];
                    }
                }];
            }
            if (scoped) [url stopAccessingSecurityScopedResource];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (generation != self.operationGeneration) {
                    [NSFileManager.defaultManager removeItemAtURL:copy error:nil]; return;
                }
                self.staging = NO;
                if (!copied || ![AISecureStore sessionAuthorized] || !UIApplication.sharedApplication.protectedDataAvailable) {
                    [NSFileManager.defaultManager removeItemAtURL:copy error:nil];
                    [self emit:@"error" message:@"The IPA could not be copied into protected storage. Unlock and choose it again."]; return;
                }
                self.pendingIPA = copy; self.signingForInstall = YES;
                if (ai_sign_ipa(copy.path.fileSystemRepresentation) != AI_OK) {
                    self.signingForInstall = NO; [self releasePendingIPA];
                    [self emit:@"error" message:@"Signing could not start. Check sign-in and pairing first."];
                }
                [self readEngineState]; self.pendingOperationId = self.engineState[@"activeOperationId"];
            });
        });
    }];
}
- (void)releasePendingIPA {
    if (self.pendingIPASecurityScope) [self.pendingIPA stopAccessingSecurityScopedResource];
    self.pendingIPASecurityScope = NO;
    if (self.pendingIPA) [NSFileManager.defaultManager removeItemAtURL:self.pendingIPA error:nil];
    self.pendingIPA = nil; self.pendingOperationId = nil;
}
- (void)refreshAll {
    [self authorize:@"Approve refreshing your installed apps" action:^{
        if (!self.pairingBackupReady) { [self emit:@"error" message:@"Import a pairing file and save its protected backup before refreshing apps."]; return; }
        if (ai_refresh_all() != AI_OK) {
            [self emit:@"error" message:@"Refresh could not start. Check sign-in, pairing and LocalDevVPN."];
            [AIRefreshCoordinator.shared recordRefreshFailure];
        }
    }];
}
- (void)cancel {
    // Invalidate the storage generation before clearing the pending-auth flags.
    // A late genuine LocalAuthentication reply must not unlock a cancelled task.
    BOOL authenticationPending = self.authorizing || self.biometricMigrationPending;
    if (authenticationPending) [AISecureStore endSession];
    self.pairingVerified = NO; self.pairingCheckRequested = NO;
    self.foregroundRefreshPending = NO; self.foregroundRefreshNeedsCheck = NO;
    ++self.operationGeneration; self.authorizing = NO; self.staging = NO;
    self.biometricMigrationPending = NO;
    self.cancelling = YES; self.signingForInstall = NO; ai_cancel();
    [self releasePendingIPA]; [self finishBackground:NO];
    [self readEngineState]; [self endBackgroundExecution];
    [self emit:@"cancelled" message:@"Task cancelled."];
}
- (void)signOut {
    [self cancel];
    [self authorize:@"Approve removing your saved Apple account" action:^{
        [self pauseScheduledWorkForExplicitSignOut];
        AIStatus result = ai_sign_out();
        OSStatus storage = [AISecureStore removeAccountRecords];
        [AIRefreshCoordinator.shared cancelScheduledWork];
        [AISecureStore endSession];
        [self readEngineState];
        [self emit:(result == AI_OK && storage == errSecSuccess) ? @"signed_out" : @"error"
            message:(result == AI_OK && storage == errSecSuccess) ? @"Signed out. Pairing was kept." : @"Sign-out needs another try to remove all saved account records."];
    }];
}
- (void)setBiometricsEnabled:(BOOL)enabled completion:(void (^)(BOOL))completion {
    if ([self.snapshot[@"busy"] boolValue] ||
        UIApplication.sharedApplication.applicationState != UIApplicationStateActive ||
        !UIApplication.sharedApplication.protectedDataAvailable) {
        [self emit:@"error" message:@"Wait for the current task to finish and keep App Installer open to change unlock settings."];
        if (completion) completion(NO); return;
    }
    self.authorizing = YES; self.biometricMigrationPending = YES;
    NSUInteger generation = ++self.operationGeneration;
    [AISecureStore setBiometricsEnabled:enabled completion:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (generation != self.operationGeneration) { if (completion) completion(NO); return; }
            self.authorizing = NO; self.biometricMigrationPending = NO;
            if (!success) [self emit:@"error" message:@"The unlock setting could not be changed. Your previous setting was kept."];
            if (completion) completion(success);
        });
    }];
}
+ (BOOL)foregroundRefreshDueForRecords:(NSArray<NSDictionary *> *)records now:(NSTimeInterval)now lastAttempt:(NSDate *)lastAttempt {
    if (!isfinite(now) || now <= 0) return NO;
    if ([lastAttempt isKindOfClass:NSDate.class]) {
        NSTimeInterval since = now - lastAttempt.timeIntervalSince1970;
        if (isfinite(since) && since >= 0 && since < 15.0 * 60.0) return NO;
    }
    for (id record in records) {
        if (![record isKindOfClass:NSDictionary.class]) continue;
        id expiry = record[@"expiry"];
        if (![expiry isKindOfClass:NSNumber.class]) continue;
        double date = [expiry doubleValue];
        if (isfinite(date) && date > 0 && date <= now + 2.0 * 86400.0) return YES;
    }
    return NO;
}
- (BOOL)hasSavedMetadataForKey:(NSString *)key {
    // Query existence/attributes only. Never return account identifiers, pairing bytes or tokens.
    LAContext *context = [LAContext new]; context.interactionNotAllowed = YES;
    NSDictionary *query = @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:@"org.tin.appinstaller.secure", (__bridge id)kSecAttrAccount:key,
        (__bridge id)kSecReturnAttributes:@YES, (__bridge id)kSecMatchLimit:(__bridge id)kSecMatchLimitOne,
        (__bridge id)kSecUseAuthenticationContext:context};
    CFTypeRef attributes = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &attributes);
    if (attributes) CFRelease(attributes); [context invalidate];
    return status == errSecSuccess;
}
- (BOOL)hasSavedAccountMetadata {
    return [self hasSavedMetadataForKey:@"engine.account.email"] && [self hasSavedMetadataForKey:@"engine.account.spd"];
}
- (void)maybeCheckPairing {
    if (!self.pairingCheckRequested || self.foregroundRefreshPending || self.notificationsSuppressedForExplicitSignOut ||
        !self.initialized || UIApplication.sharedApplication.applicationState != UIApplicationStateActive ||
        [self.snapshot[@"busy"] boolValue] || ![AISecureStore sessionAuthorized] ||
        !UIApplication.sharedApplication.protectedDataAvailable) return;
    // An existing authorized session permits this read-only check; no authentication
    // prompt is ever created by this path. Locked sessions stay explicitly unverified.
    self.pairingCheckRequested = NO;
    NSData *pairing = [self.pairingStore pairingDataWithError:nil];
    if (!pairing.length) { self.pairingVerified = NO; return; }
    self.pairingFileKnownPresent = YES;
    self.pairingBackupReady = [self.pairingStore importValidatedPairingData:pairing error:nil];
    if (!self.pairingBackupReady) {
        self.pairingVerified = NO;
        [self emit:@"error" message:@"The protected pairing backup needs another import before device access."]; return;
    }
    if (ai_list_installed() != AI_OK) {
        self.pairingVerified = NO;
        [self emit:@"error" message:@"Pairing could not be checked. Keep LocalDevVPN connected, then unlock saved sign-in to retry."]; return;
    }
    [self beginBackgroundExecution]; [self readEngineState];
}
- (void)maybeStartForegroundDueRefresh {
    if (self.notificationsSuppressedForExplicitSignOut) { self.foregroundRefreshNeedsCheck = NO; return; }
    if (!self.foregroundRefreshNeedsCheck || self.foregroundRefreshPending || !self.initialized ||
        UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
    if ([self.snapshot[@"busy"] boolValue]) return; // A startup self-source job may still be finishing.
    self.foregroundRefreshNeedsCheck = NO;
    NSMutableArray *records = [self.appRecords mutableCopy] ?: [NSMutableArray new];
    NSNumber *own = [self ownExpiry];
    if (own.doubleValue > 0) [records addObject:@{@"expiry":own}];
    NSDate *now = NSDate.date;
    if (![AIInstallerService foregroundRefreshDueForRecords:records now:now.timeIntervalSince1970 lastAttempt:self.lastForegroundRefreshAttempt] ||
        [AISecureStore initialSetupRequired] || ![self hasSavedAccountMetadata]) return;
    // Daily Open App now requests an actual due refresh, with genuine foreground
    // device-owner/biometric approval. It does not promise unattended execution.
    self.lastForegroundRefreshAttempt = now;
    [NSUserDefaults.standardUserDefaults setObject:now forKey:@"org.tin.appinstaller.last-foreground-refresh-attempt"];
    self.foregroundRefreshPending = YES;
    [self authorize:@"Your apps are near expiry. Unlock to approve refreshing them." action:^{
        if (!self.pairingBackupReady) {
            self.foregroundRefreshPending = NO;
            [self emit:@"error" message:@"Import a pairing file and save its protected backup before refreshing."]; return;
        }
        AIStatus status = [self.engineState[@"loginStatus"] isEqual:@"signed_in"] ? ai_list_installed() : ai_restore_session();
        if (status != AI_OK) {
            self.foregroundRefreshPending = NO;
            [self emit:@"error" message:@"Unlock saved sign-in or sign in again, then tap Refresh all."];
        }
        [self readEngineState];
    }];
    if (!self.authorizing && ![self.engineState[@"busy"] boolValue]) self.foregroundRefreshPending = NO;
}
- (void)beginBackgroundExecution {
    if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid || self.backgroundCompletion) return;
    NSUInteger generation = ++self.backgroundExecutionGeneration;
    __weak typeof(self) weakSelf = self;
    self.backgroundTaskIdentifier = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"Finish approved app refresh or installation" expirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            AIInstallerService *self = weakSelf;
            if (!self || generation != self.backgroundExecutionGeneration || self.backgroundTaskIdentifier == UIBackgroundTaskInvalid) return;
            // This is a bounded continuation, not an unattended refresh guarantee.
            [AISecureStore endSession]; ai_lock(); [self cancel];
            [self emit:@"error" message:@"iOS ended background time. Open and unlock App Installer, then retry; a completed device install may need rechecking."];
            [AIRefreshCoordinator.shared recordRefreshFailure];
        });
    }];
}
- (void)endBackgroundExecution {
    UIBackgroundTaskIdentifier task = self.backgroundTaskIdentifier;
    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    ++self.backgroundExecutionGeneration;
    if (task != UIBackgroundTaskInvalid) [UIApplication.sharedApplication endBackgroundTask:task];
}
- (void)endBackgroundExecutionIfIdle {
    if (![self.engineState[@"busy"] boolValue] && !self.authorizing && !self.staging &&
        !self.signingForInstall && !self.pendingIPA && !self.foregroundRefreshPending) [self endBackgroundExecution];
}

- (void)pauseScheduledWorkForExplicitSignOut {
    // Called after real foreground approval, before the engine emits its cancellation event.
    self.notificationsSuppressedForExplicitSignOut = YES;
    self.foregroundRefreshPending = NO; self.foregroundRefreshNeedsCheck = NO;
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"org.tin.appinstaller.explicit-signout-reminder-pause"];
    [AIRefreshCoordinator.shared cancelScheduledWork];
}

@end
