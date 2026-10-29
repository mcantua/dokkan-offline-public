#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/// Primary record: engine.pairing in Keychain. Exactly one encrypted backup file.
/// Requires an authorized AISecureStore session. Caller must validate with Rust first.
@interface AIPairingStore : NSObject
- (instancetype)initWithDirectory:(NSURL *)directory;
- (BOOL)importValidatedPairingData:(NSData *)data error:(NSError * _Nullable * _Nullable)error;
/// Reads primary; if missing, decrypts the single backup and restores Keychain.
- (nullable NSData *)pairingDataWithError:(NSError * _Nullable * _Nullable)error;
- (BOOL)removePairingWithError:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
