#import <Foundation/Foundation.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <Security/Security.h>

NS_ASSUME_NONNULL_BEGIN
/// Only Keychain stores account/session/signing secrets. No method logs values.
@interface AISecureStore : NSObject
/// TRUE only for genuinely missing configuration and an empty engine Keychain service.
/// Metadata queries do not authenticate or read any saved secret; errors fail closed.
+ (BOOL)initialSetupRequired;
+ (BOOL)biometricsEnabled;
+ (BOOL)sessionAuthorized;
/// For protected native operations only; returns nil outside the authorized session.
+ (nullable LAContext *)authorizedContext;
+ (void)authenticateSessionWithReason:(NSString *)reason completion:(void (^)(BOOL success))completion;
+ (void)endSession;
/// Migrates existing records in memory; old items are not deleted before updates.
/// On failure, attempts rollback and locks the session; returns NO.
+ (void)setBiometricsEnabled:(BOOL)enabled completion:(void (^)(BOOL success))completion;
+ (OSStatus)save:(NSData *)data key:(NSString *)key biometric:(BOOL)biometric;
+ (nullable NSData *)load:(NSString *)key context:(nullable LAContext *)context status:(nullable OSStatus *)status;
+ (OSStatus)remove:(NSString *)key;
/// Removes auth/session/signing records, retaining pairing and its backup.
+ (OSStatus)removeAccountRecords;
/// For an explicit reset only; this does not remove PairingStore's encrypted file.
+ (OSStatus)removeAll;
@end
NS_ASSUME_NONNULL_END
