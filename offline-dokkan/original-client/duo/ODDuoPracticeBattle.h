#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

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
@property(nonatomic,readonly,getter=isRunning) BOOL running;
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
