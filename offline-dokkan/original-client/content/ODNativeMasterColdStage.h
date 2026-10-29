#import <Foundation/Foundation.h>
#include <stdint.h>
NS_ASSUME_NONNULL_BEGIN
/** Cold preparation of an opaque downloaded master for the ORIGINAL engine.
 * No SQLite/key/codec operation or engine ABI is called here. This is not
 * compatibility admission. The original bundle database.db remains fallback.
 * Use only before dlopen, on the native serial content queue, in a fresh own
 * app container under the own org.offlinedokkan.* identity namespace. Never
 * use a source-game installation or an existing player.
 */
@interface ODNativeMasterColdStage : NSObject
- (instancetype)init NS_UNAVAILABLE;
/** Native-only inputs, never a request/page/configuration claim. language must
 * come from the actual selected engine's language/settings contract; this
 * method validates spelling but cannot prove where the caller obtained it.
 * No caller is currently admitted to manufacture/default that language.
 * Source must be a hash-pinned immutable non-seed opaque download. The actual
 * own Documents/assets default root is selected by Foundation. Existing User
 * or sqlite/current is refused without opening its contents or replacing it.
 * A separate 0600 working copy is published atomically; native flags6 may
 * modify/remove it later. contextIsCurrent must remain valid through staging.
 */
+ (nullable instancetype)stageImmutableOpaqueMasterAtURL:(NSURL *)source
    byteCount:(uint64_t)bytes contentSHA256:(NSString *)sha256
    observedNativeLanguage:(NSString *)language contextIsCurrent:(BOOL (^)(void))current
    error:(NSError * _Nullable * _Nullable)error;
/** Explicit compatibility candidate for the supplied opaque Android export.
 * Exact source: 114827264 bytes, SHA256 f37296ef05e31000d9868741b18525a5d41311ccc152acb82c848b7b1c8ef14d.
 * The export's asset language is en; this does NOT claim that the running
 * original client selected en. Only the fresh own org.offlinedokkan.duo app
 * may publish an independent copy under assets/sqlite/current/en/database.db.
 * Existing User/current is refused, never inspected or replaced. The original
 * engine alone chooses whether to open this candidate or its bundle fallback.
 * Caller must also admit fresh startup provenance; never stage on resume.
 * Native key/open/schema/codec acceptance remains unobserved. */
+ (nullable instancetype)stagePinnedSourceExportCandidateAtURL:(NSURL *)source
    contextIsCurrent:(BOOL (^)(void))current
    error:(NSError * _Nullable * _Nullable)error;
/** Main/host may call before dlopen. Checks the pinned working inode/hash and
 * fresh tree again. No acceptance of later native writes/cache/codec implied.
 */
- (BOOL)confirmBeforeOriginalImageLoad:(NSError * _Nullable * _Nullable)error;
@property(nonatomic,readonly,copy) NSURL *assetsRootURL;
@property(nonatomic,readonly,copy) NSDictionary *stagingReport;
@end
NS_ASSUME_NONNULL_END
