#import <Foundation/Foundation.h>
@class ODNativeCore;
NS_ASSUME_NONNULL_BEGIN
/** Native one-session ledger owner for the actual canonical Core/profile/scope.
 * Its data comes only from the scoped readonly phase provider. No new save
 * connection, Web operation, win/outcome, reward, ACT or unit grant is added. */
@interface ODOriginalPracticeSession : NSObject
- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithCore:(ODNativeCore *)core contentID:(NSString *)content
    profileID:(NSString *)profile saveScopeSHA256:(NSString *)scope
    parametersJSON:(NSData *)parameters sourceReceipt:(NSDictionary *)receipt
    contextIsCurrent:(BOOL (^)(void))current;
@property(nonatomic,readonly,copy) NSData *parametersJSON;
@property(nonatomic,readonly) BOOL prepared;
@property(nonatomic,readonly) BOOL nativeFinishPersisted;
/** Fixed state only; session/profile/hash values are never put in reports. */
@property(nonatomic,readonly,copy) NSString *state;
/** Durable prepared record before native entry. A failed/abandoned entry stays
 * prepared; it is never described as a rendered or completed battle. */
- (void)prepareWithCompletion:(void (^)(NSError * _Nullable error))completion;
/** Invoke only from the original bridge's actual finish saver. Explicit retry
 * reuses the same command, payload and first expected revision. */
- (void)persistNativeFinishWithCompletion:(void (^)(NSError * _Nullable error))completion;
@end
NS_ASSUME_NONNULL_END
