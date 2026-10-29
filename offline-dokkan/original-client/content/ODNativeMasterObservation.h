#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/** Actual original-client diagnostic observation, main thread after the real
 * AppController/renderer exists. Reuses the admitted original image probe.
 * Reads only pinned code, the existing native master pointer/cache and the
 * existing native language string. Never allocates a singleton or calls C++,
 * SQLite, a key provider, a close/reopen API or a foreign database handle.
 * Returns fixed value-free evidence; no pointers, key bytes, file paths,
 * database rows, account fields or raw language values cross this boundary.
 * Handle presence is not codec/schema/selected-file acceptance. Those fields
 * stay explicitly unverified. Never use this partial report to enable routes.
 */
FOUNDATION_EXPORT NSDictionary * _Nullable ODCopyOriginalMasterObservation(
    id actualOriginalAppController);
NS_ASSUME_NONNULL_END
