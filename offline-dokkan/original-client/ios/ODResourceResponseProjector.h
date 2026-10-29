#import <Foundation/Foundation.h>
#import "../../adapter/ios/ODNativeCore.h"

NS_ASSUME_NONNULL_BEGIN
/** Trusted native code derives unresolved sections from the exact selected
 * master and approved persistent fresh-player policy. Own teams and six-slot
 * formations come from the actual Core snapshot original_client_teams record;
 * this policy cannot replace them or assert an unpersisted native identity.
 * Runs on a private serial projection queue; return JSON only, never captured
 * account-cache values. */
typedef NSDictionary *_Nullable (^ODResourceNativePolicy)(NSDictionary *atomicPlayerEnvelope,NSError **error);
typedef BOOL (^ODResourceContextCurrent)(void);

/** Data-only adapter for the original client. Loads hash-pinned authored JS and
 * sanitized observed schema, requests one atomic own-core snapshot, projects
 * on a private JSC queue, and returns a JSON candidate/explicit missing fields.
 * It does not register a game route or manufacture incomplete success bodies. */
@interface ODResourceResponseProjector : NSObject
- (nullable instancetype)initWithCore:(ODNativeCore *)core saveURL:(NSURL *)saveURL
    masterURL:(NSURL *)masterURL contentID:(NSString *)content profileID:(NSString *)profile
    saveScopeSHA256:(NSString *)scope schemaURL:(NSURL *)schemaURL schemaSHA256:(NSString *)schemaHash
    moduleURL:(NSURL *)moduleURL moduleSHA256:(NSString *)moduleHash
    nativePolicy:(nullable ODResourceNativePolicy)policy contextCurrent:(ODResourceContextCurrent)current;
- (void)projectCurrentPlayer:(ODCoreReply)reply;
/** Current new-profile User DTO. Requires the actual persisted skip-intro
 * policy; existing profiles are not rewritten and full Home is not claimed. */
- (void)projectNewProfilePlayer:(ODCoreReply)reply;
/** Retained original User DTO for existing persisted unfinished profiles
 * and empty own collection. New profiles use projectNewProfilePlayer:.
 * Unresolved native fields stay absent;
 * this does not admit a general resources/home response or HTTP route. */
- (void)projectInitialTutorialPlayer:(ODCoreReply)reply;
/** Source-proven direct GET /teams DTO from the same persisted Core owner.
 * Does not require unresolved user/capacity policy or register an HTTP route. */
- (void)projectCurrentTeams:(ODCoreReply)reply;
/** Validates an already-decoded original POST /teams object against a fresh
 * own-player snapshot, returning normalized native mutation + expected revision.
 * Does not decode/sign a request, adopt timewarp, or execute the mutation. */
- (void)normalizeOriginalTeamUpdate:(NSDictionary *)decodedBody reply:(ODCoreReply)reply;
/** Native route only, after an original decoder has actually verified the
 * request. Normalize against a fresh same-Core snapshot, then apply once with
 * its exact revision/scope and an adapter-issued command. The additional
 * main-only predicate retains request/decoder/master authority through async
 * work. Cancellation after an accepted commit cannot roll it back. */
- (void)applyDecodedOriginalTeamUpdate:(NSDictionary *)decodedBody command:(NSString *)command
    mutationCurrent:(ODResourceContextCurrent)mutationCurrent reply:(ODCoreReply)reply;
- (instancetype)init NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
