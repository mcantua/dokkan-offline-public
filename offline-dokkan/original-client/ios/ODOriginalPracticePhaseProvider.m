#if defined(__APPLE__) && !defined(_DARWIN_C_SOURCE)
#define _DARWIN_C_SOURCE 1
#endif
#import "ODOriginalPracticePhaseProvider.h"
#import <CommonCrypto/CommonDigest.h>
#import <CoreFoundation/CoreFoundation.h>
#include <sqlite3.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <math.h>

static NSString *const ODPracticeMasterSHA=@"1a8f5a823a6efa7343ff463b92197a574898e03569e2067f3daf8a4f282be4f4";
static const uint64_t ODPracticeMasterBytes=114827264;
static NSString *const ODPracticeScene=@"internal:Tutorial::BattleSetupScene";
static NSError *ODPracticePhaseError(NSString *code) {
    return [NSError errorWithDomain:@"OfflineDokkan.OriginalPracticePhase" code:1
        userInfo:@{NSLocalizedDescriptionKey:code}];
}
static BOOL ODPracticeHex(NSString *text) {
    if(![text isKindOfClass:NSString.class]||text.length!=64)return NO;
    for(NSUInteger i=0;i<text.length;++i){unichar c=[text characterAtIndex:i];if(!((c>='0'&&c<='9')||(c>='a'&&c<='f')))return NO;}
    return YES;
}
static NSString *ODPracticeDigest(const unsigned char *digest) {
    static const char alphabet[]="0123456789abcdef";char hex[65];
    for(NSUInteger i=0;i<CC_SHA256_DIGEST_LENGTH;++i){hex[2*i]=alphabet[digest[i]>>4];hex[2*i+1]=alphabet[digest[i]&15];}
    hex[64]=0;return [NSString stringWithUTF8String:hex];
}
static BOOL ODPracticeSameFile(const struct stat *a,const struct stat *b) {
    return S_ISREG(a->st_mode)&&S_ISREG(b->st_mode)&&a->st_dev==b->st_dev&&a->st_ino==b->st_ino&&
        a->st_size==b->st_size&&a->st_mtimespec.tv_sec==b->st_mtimespec.tv_sec&&
        a->st_mtimespec.tv_nsec==b->st_mtimespec.tv_nsec;
}
static BOOL ODPracticeKeys(id object,NSArray<NSString *> *keys) {
    if(![object isKindOfClass:NSDictionary.class]||[(NSDictionary *)object count]!=keys.count)return NO;
    for(id key in object)if(![key isKindOfClass:NSString.class]||![keys containsObject:key])return NO;
    return YES;
}
static BOOL ODPracticeInteger(id value) {
    if(![value isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)value)==CFBooleanGetTypeID())return NO;
    double number=[value doubleValue];return isfinite(number)&&number==trunc(number)&&fabs(number)<=9007199254740991.0;
}
static BOOL ODPracticeArray(id value,NSUInteger count) {
    return [value isKindOfClass:NSArray.class]&&[(NSArray *)value count]==count;
}
static BOOL ODPracticeParameters(id value) {
    if(!ODPracticeKeys(value,@[@"bgm_id",@"map_id",@"enemies",@"card_ids",@"ball_tables",@"dummy_card_id",@"force_high_speed",@"fixed_next_turn_orders"]))return NO;
    NSDictionary *parameters=value;
    for(NSString *key in @[@"bgm_id",@"map_id",@"dummy_card_id"])if(!ODPracticeInteger(parameters[key]))return NO;
    id speed=parameters[@"force_high_speed"];
    if(![speed isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)speed)!=CFBooleanGetTypeID())return NO;
    id cards=parameters[@"card_ids"];
    if(!ODPracticeArray(cards,2))return NO;
    for(id card in cards)if(!ODPracticeInteger(card))return NO;
    id enemies=parameters[@"enemies"];
    if(!ODPracticeArray(enemies,1)||!ODPracticeArray(enemies[0],1))return NO;
    id enemy=enemies[0][0];
    NSArray<NSString *> *enemyKeys=@[@"hp",@"exp",@"turn",@"zeni",@"attack",@"ai_type",@"card_id",@"defence",@"first_turn",@"extra_hp_gauges_count"];
    if(!ODPracticeKeys(enemy,enemyKeys))return NO;
    for(NSString *key in enemyKeys)if(!ODPracticeInteger(enemy[key]))return NO;
    id tables=parameters[@"ball_tables"];
    if(!ODPracticeArray(tables,2))return NO;
    for(id table in tables){
        if(!ODPracticeArray(table,5))return NO;
        for(id row in table){if(!ODPracticeArray(row,9))return NO;for(id cell in row)if(!ODPracticeInteger(cell))return NO;}
    }
    id orders=parameters[@"fixed_next_turn_orders"];
    if(!ODPracticeArray(orders,1)||!ODPracticeArray(orders[0],2))return NO;
    for(id order in orders[0])if(!ODPracticeInteger(order))return NO;
    return YES;
}
/* Canonical projection preserves numeric owned instance IDs in native row.id.
 * This rejects a known collision; it is not proof of a foreign/stale native
 * cache's absence. The native battle bridge owns that separate admission. */
static NSString *ODPracticeOwnedCollision(id envelope,NSData *parametersJSON) {
    id snapshot=[envelope isKindOfClass:NSDictionary.class]?envelope[@"player_snapshot"]:nil;
    id cards=[snapshot isKindOfClass:NSDictionary.class]?snapshot[@"cards"]:nil;
    if(![cards isKindOfClass:NSArray.class])return @"PRACTICE_CORE_OWNED_ID_MAPPING_UNAVAILABLE";
    NSDictionary *parameters=[NSJSONSerialization JSONObjectWithData:parametersJSON options:0 error:NULL];
    if(!ODPracticeParameters(parameters))return @"PRACTICE_PHASE_SOURCE_OR_SHAPE_MISMATCH";
    NSMutableSet<NSNumber *> *borrowed=[NSMutableSet setWithArray:parameters[@"card_ids"]];
    [borrowed addObject:parameters[@"dummy_card_id"]];
    for(id card in cards){
        id identity=[card isKindOfClass:NSDictionary.class]?card[@"instance_id"]:nil;
        if(!ODPracticeInteger(identity)||[identity longLongValue]<=0)return @"PRACTICE_CORE_OWNED_ID_MAPPING_UNAVAILABLE";
        if([borrowed containsObject:identity])return @"PRACTICE_FIXED_LOADOUT_OWNED_ID_COLLISION";
    }
    return nil;
}

@implementation ODOriginalPracticePhaseProvider {
    ODNativeCore *_core;
    NSString *_profile,*_scope,*_sha,*_content;
    NSURL *_masterURL;
    uint64_t _bytes;
    ODResourceContextCurrent _current;
    dispatch_queue_t _queue;
    NSData *_cachedParameters;
    NSDictionary *_cachedReceipt;
    struct stat _cachedStat;
}
- (instancetype)initWithCore:(ODNativeCore *)core profileID:(NSString *)profile expectedSaveScopeSHA256:(NSString *)scope
    masterURL:(NSURL *)masterURL masterByteCount:(uint64_t)bytes masterSHA256:(NSString *)masterSHA256
    contextCurrent:(ODResourceContextCurrent)current {
    if(!core||![profile isKindOfClass:NSString.class]||!profile.length||!ODPracticeHex(scope)||!current||
       !masterURL.isFileURL||!masterURL.path.isAbsolutePath||bytes!=ODPracticeMasterBytes||![masterSHA256 isEqual:ODPracticeMasterSHA])return nil;
    if((self=[super init])){
        _core=core;_profile=[profile copy];_scope=[scope copy];_masterURL=[masterURL copy];_bytes=bytes;
        _sha=[masterSHA256 copy];_content=[@"sha256:" stringByAppendingString:_sha];_current=[current copy];
        _queue=dispatch_queue_create("personal.offlinedokkan.original-practice-phase",DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
- (BOOL)matchesOwnEnvelope:(id)value {
    if(![value isKindOfClass:NSDictionary.class])return NO;
    NSDictionary *admission=value[@"admission"],*snapshot=value[@"player_snapshot"];
    return [admission isKindOfClass:NSDictionary.class]&&[snapshot isKindOfClass:NSDictionary.class]&&
        [admission[@"profile_id"] isEqual:_profile]&&[admission[@"content_id"] isEqual:_content]&&
        [admission[@"save_scope_sha256"] isEqual:_scope]&&[admission[@"clean"] isEqual:@YES]&&
        [snapshot[@"profile_id"] isEqual:_profile]&&[snapshot[@"content_id"] isEqual:_content];
}
- (NSData *)readPinnedPhaseWithReceipt:(NSDictionary **)receipt error:(NSError **)error {
    int fd=open(_masterURL.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);
    if(fd<0){if(error)*error=ODPracticePhaseError(@"PRACTICE_MASTER_OPEN_FAILED");return nil;}
    struct stat before,after,pathState;
    BOOL valid=fstat(fd,&before)==0&&S_ISREG(before.st_mode)&&before.st_size>0&&(uint64_t)before.st_size==_bytes;
    if(valid&&_cachedParameters&&ODPracticeSameFile(&before,&_cachedStat)){
        valid=lstat(_masterURL.fileSystemRepresentation,&pathState)==0&&ODPracticeSameFile(&before,&pathState);
        close(fd);
        if(valid){*receipt=_cachedReceipt;return _cachedParameters;}
        if(error)*error=ODPracticePhaseError(@"PRACTICE_MASTER_CHANGED");return nil;
    }
    CC_SHA256_CTX hash;CC_SHA256_Init(&hash);unsigned char buffer[65536],digest[CC_SHA256_DIGEST_LENGTH];
    uint64_t total=0;
    while(valid){
        ssize_t count=read(fd,buffer,sizeof(buffer));
        if(count<0&&errno==EINTR)continue;
        if(count<0){valid=NO;break;}if(!count)break;
        total+=(uint64_t)count;if(total>_bytes){valid=NO;break;}CC_SHA256_Update(&hash,buffer,(CC_LONG)count);
    }
    CC_SHA256_Final(digest,&hash);
    valid=valid&&total==_bytes&&[_sha isEqual:ODPracticeDigest(digest)]&&fstat(fd,&after)==0&&
        ODPracticeSameFile(&before,&after)&&lstat(_masterURL.fileSystemRepresentation,&pathState)==0&&ODPracticeSameFile(&before,&pathState);
    if(!valid){close(fd);if(error)*error=ODPracticePhaseError(@"PRACTICE_MASTER_PIN_MISMATCH");return nil;}
    NSURLComponents *components=[NSURLComponents componentsWithURL:_masterURL resolvingAgainstBaseURL:NO];
    components.query=@"mode=ro&immutable=1";
    sqlite3 *db=NULL;sqlite3_stmt *statement=NULL;NSData *parameters=nil;
    int flags=SQLITE_OPEN_READONLY|SQLITE_OPEN_URI|SQLITE_OPEN_NOMUTEX;
#ifdef SQLITE_OPEN_NOFOLLOW
    flags|=SQLITE_OPEN_NOFOLLOW;
#endif
    if(components.string&&sqlite3_open_v2(components.string.UTF8String,&db,flags,NULL)==SQLITE_OK&&sqlite3_db_readonly(db,"main")==1&&
       sqlite3_prepare_v2(db,"SELECT tutorial_scene_url,parameters FROM tutorial_phases WHERE number=3",-1,&statement,NULL)==SQLITE_OK&&
       sqlite3_step(statement)==SQLITE_ROW&&sqlite3_column_type(statement,0)==SQLITE_TEXT&&sqlite3_column_type(statement,1)==SQLITE_TEXT){
        const unsigned char *uri=sqlite3_column_text(statement,0);
        const unsigned char *json=sqlite3_column_text(statement,1);int length=sqlite3_column_bytes(statement,1);
        NSString *scene=uri?[NSString stringWithUTF8String:(const char *)uri]:nil;
        // Own bounded parser budget, not an original-game stat/row default.
        if([scene isEqual:ODPracticeScene]&&json&&length>0&&length<=1024*1024){
            parameters=[NSData dataWithBytes:json length:(NSUInteger)length];
            if(sqlite3_step(statement)!=SQLITE_DONE)parameters=nil;
        }
    }
    sqlite3_finalize(statement);if(db)sqlite3_close(db);
    valid=fstat(fd,&after)==0&&ODPracticeSameFile(&before,&after)&&lstat(_masterURL.fileSystemRepresentation,&pathState)==0&&ODPracticeSameFile(&before,&pathState);
    close(fd);
    id parsed=parameters?[NSJSONSerialization JSONObjectWithData:parameters options:0 error:NULL]:nil;
    if(!valid||!parameters||!ODPracticeParameters(parsed)){
        if(error)*error=ODPracticePhaseError(@"PRACTICE_PHASE_SOURCE_OR_SHAPE_MISMATCH");return nil;
    }
    CC_SHA256(parameters.bytes,(CC_LONG)parameters.length,digest);
    _cachedStat=after;_cachedParameters=[parameters copy];
    _cachedReceipt=@{@"kind":@"original-master-practice-phase3",@"content_id":_content,@"master_sha256":_sha,
        @"master_bytes":@(_bytes),@"phase_number":@3,@"scene_uri":ODPracticeScene,
        @"parameter_bytes":@(parameters.length),@"parameter_sha256":ODPracticeDigest(digest),
        @"source_read_only":@YES,@"permanent_ownership_changed":@NO,@"native_engine_admitted":@NO};
    *receipt=_cachedReceipt;return _cachedParameters;
}
- (void)loadPhase3WithReply:(ODOriginalPracticePhaseReply)reply {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self loadPhase3WithReply:reply];});return;}
    if(!_current()){reply(nil,nil,ODPracticePhaseError(@"PRACTICE_CONTEXT_CHANGED"));return;}
    [_core originalClientPlayerSnapshotForProfile:_profile expectedSaveScopeSHA256:_scope reply:^(id before,NSError *failure){
        if(failure||!self->_current()||![self matchesOwnEnvelope:before]){
            reply(nil,nil,ODPracticePhaseError(@"PRACTICE_CORE_SCOPE_UNAVAILABLE"));return;
        }
        dispatch_async(self->_queue,^{
            NSError *error=nil;NSDictionary *receipt=nil;
            NSData *parameters=[self readPinnedPhaseWithReceipt:&receipt error:&error];
            dispatch_async(dispatch_get_main_queue(),^{
                if(!self->_current()){reply(nil,nil,ODPracticePhaseError(@"PRACTICE_CONTEXT_CHANGED"));return;}
                if(error||!parameters){reply(nil,nil,error?:ODPracticePhaseError(@"PRACTICE_PHASE_UNAVAILABLE"));return;}
                [self->_core originalClientPlayerSnapshotForProfile:self->_profile expectedSaveScopeSHA256:self->_scope reply:^(id after,NSError *finalFailure){
                    if(finalFailure||!self->_current()||![self matchesOwnEnvelope:after]){
                        reply(nil,nil,ODPracticePhaseError(@"PRACTICE_CORE_SCOPE_UNAVAILABLE"));return;
                    }
                    NSString *collision=ODPracticeOwnedCollision(after,parameters);
                    if(collision){reply(nil,nil,ODPracticePhaseError(collision));return;}
                    NSMutableDictionary *admitted=[receipt mutableCopy];
                    admitted[@"core_owned_id_collision_checked"]=@YES;
                    admitted[@"native_owned_id_absence_proven"]=@NO;
                    reply(parameters,[admitted copy],nil);
                }];
            });
        });
    }];
}
@end
