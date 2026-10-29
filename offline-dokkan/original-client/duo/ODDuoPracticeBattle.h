#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
typedef void (^ODDuoPracticeNativeFinishSaver)(void (^completion)(NSError * _Nullable error));

/** Native-only, manually selected practice using the original client's fixed
 * encounter and temporary loadout. This never admits an ordinary quest clear,
 * ACT charge, reward or collection/team mutation. The caller supplies only the
 * unchanged phase parameters from its current readonly master capability.
 */
@interface ODDuoOriginalPracticeBattle : NSObject
- (instancetype)init NS_UNAVAILABLE;
- (BOOL)beginWithAppController:(id)originalAppController
               parametersJSON:(NSData *)parameters
                        error:(NSError * _Nullable * _Nullable)error;
/** Same original entry, with a native-issued session's same-Core finish saver.
 * It is invoked only after the actual original finish callback. Cleanup/Home
 * wait for its durable commit; failed persistence keeps the battle/session.
 * The caller must durably prepare the exact phase/session before entry. */
- (BOOL)beginWithAppController:(id)originalAppController
               parametersJSON:(NSData *)parameters
                  finishSaver:(ODDuoPracticeNativeFinishSaver)saver
                        error:(NSError * _Nullable * _Nullable)error;
@property(nonatomic,readonly,getter=isRunning) BOOL running;
@property(nonatomic,readonly) BOOL finishPersistenceRetryAvailable;
/** Explicit native user action only; retries the same finish intent retained
 * by the session owner. It never replays combat or creates a new completion. */
- (void)retryNativeFinishPersistenceWithCompletion:(void (^)(NSError * _Nullable error))completion;
/* Main-thread status only. Contains no source parameters, native pointers or
 * account data. A started scene is not evidence that combat was completed. */
@property(nonatomic,copy,nullable) void (^report)(NSDictionary *state);
@end

/** Loader-internal issuance after its existing whole-image verification and
 * dlopen. The file is the SAME verified snapshot, not an arbitrary ABI recipe.
 * Resolves reviewed functions by unique body hashes at actual function starts;
 * it never searches for keys, configuration values or game data.
 */
FOUNDATION_EXPORT ODDuoOriginalPracticeBattle * _Nullable
ODCreateOriginalPracticeBattleForAdmittedImage(NSURL *loadedImageURL,
    NSData *verifiedImage, NSError * _Nullable * _Nullable error);
NS_ASSUME_NONNULL_END
