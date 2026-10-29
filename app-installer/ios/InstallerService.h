#import <Foundation/Foundation.h>
#include <stdint.h>
NS_ASSUME_NONNULL_BEGIN
/// Native coordinator. Events/snapshots contain safe state and app metadata, never credentials.
@interface AIInstallerService : NSObject
+ (instancetype)shared;
/// Pure actual-expiry/cooldown policy; does not authenticate, sign or contact a device.
+ (BOOL)foregroundRefreshDueForRecords:(NSArray<NSDictionary *> *)records
                                  now:(NSTimeInterval)now
                          lastAttempt:(nullable NSDate *)lastAttempt;
@property (nonatomic, copy, nullable) void (^eventHandler)(NSDictionary *event);
@property (nonatomic, readonly) NSDictionary *snapshot;
@property (nonatomic, readonly) NSArray<NSDictionary *> *appRecords;
- (void)resume;
- (void)signInWithEmail:(NSString *)email password:(NSString *)password;
- (void)submitCode:(NSString *)code;
- (void)selectTeam:(NSString *)teamId;
/// action: 0 resend, 1 trusted devices, 2 SMS to an ID provided by Apple.
- (void)requestVerificationCode:(NSInteger)action numberID:(uint32_t)numberID;
- (void)cancel;
- (void)importPairingFile:(NSURL *)url;
- (void)installIPA:(NSURL *)url;
- (void)refreshAll;
- (void)signOut;
- (void)setBiometricsEnabled:(BOOL)enabled completion:(void (^)(BOOL success))completion;
@end
NS_ASSUME_NONNULL_END
