#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Opportunistic refresh scheduling and local expiry reminders. Contains no account secrets.
@interface AIRefreshCoordinator : NSObject
+ (instancetype)shared;

/// Must be configured by the service. Success means every requested app refresh finished.
@property (nonatomic, copy, nullable) void (^refreshHandler)(void (^completion)(BOOL success));
/// Cancels the engine operation when iOS expires a background execution window.
@property (nonatomic, copy, nullable) void (^cancelHandler)(void);
/// Explicitly returns YES only when the service can work without unlock, biometric or other UI.
@property (nonatomic, copy, nullable) BOOL (^canRefreshWithoutInteraction)(void);
@property (nonatomic, readonly) BOOL registrationSucceeded;
@property (nonatomic, readonly) BOOL lastScheduleSucceeded;

/// Call synchronously during application:didFinishLaunchingWithOptions:.
- (void)registerTasks;
- (void)schedule;
/// Metadata only: name, bundleId, expiry (NSNumber with Unix seconds). Include the installer itself.
- (void)updateAppRecords:(NSArray<NSDictionary *> *)records;
/// Call only from an explicit foreground user action. Background work never requests permission.
- (void)requestNotificationAuthorization:(void (^)(BOOL granted))completion;
/// Updates warnings after a real refresh failure; no credentials or raw errors are accepted.
- (void)recordRefreshFailure;
/// Sign out: clear this coordinator's task requests, persisted metadata and pending reminders.
- (void)cancelScheduledWork;
@end

NS_ASSUME_NONNULL_END
