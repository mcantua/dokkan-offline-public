#import "ODCreatorSession.h"
#import "ODBattleStore.h"
#import "ODBattleCoordinator.h"
#import "../../adapter/ios/ODNativeCore.h"
#import "../../original-client/creator-bundle/ODNativeFullCreatorValidator.h"
#import <CommonCrypto/CommonDigest.h>
#include "sqlite3.h"
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdio.h>
#include <math.h>
#include <ctype.h>
#include <time.h>
#include <dirent.h>

static const NSUInteger ODProjectLimit = 20 * 1024 * 1024, ODRequestLimit = 24 * 1024 * 1024, ODStoreLimit = 96 * 1024 * 1024;
static BOOL ODObject(id v) { return [v isKindOfClass:NSDictionary.class]; }
static BOOL ODArray(id v) { return [v isKindOfClass:NSArray.class]; }
static BOOL ODInteger(id v) { return [v isKindOfClass:NSNumber.class] && isfinite([v doubleValue]) && [v doubleValue]==[v longLongValue] && fabs([v doubleValue])<=9007199254740991.0; }
static BOOL ODName(id v) {
    if (![v isKindOfClass:NSString.class] || ![v length] || [v length] > 100) return NO;
    return [v rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.:-"] invertedSet]].location == NSNotFound;
}
static BOOL ODArchiveVersion(id v){
    if(![v isKindOfClass:NSString.class])return NO;static NSRegularExpression *pattern;static dispatch_once_t once;
    dispatch_once(&once,^{pattern=[NSRegularExpression regularExpressionWithPattern:@"\\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\\z" options:0 error:nil];});
    return [pattern firstMatchInString:v options:0 range:NSMakeRange(0,[v length])]!=nil;
}
static BOOL ODIdent(id v) {
    if (![v isKindOfClass:NSString.class] || ![v length] || [v length] > 100) return NO;
    NSCharacterSet *start = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"];
    return [v rangeOfCharacterFromSet:start].location == 0 && [v rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"] invertedSet]].location == NSNotFound;
}
static NSData *ODJSON(id value) { return [NSJSONSerialization isValidJSONObject:value] ? [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingSortedKeys error:nil] : nil; }
static NSString *ODHash(NSData *bytes) {
    unsigned char digest[CC_SHA256_DIGEST_LENGTH]; CC_SHA256(bytes.bytes, (CC_LONG)bytes.length, digest);
    NSMutableString *hex = [NSMutableString stringWithCapacity:64]; for (int i=0;i<32;i++) [hex appendFormat:@"%02x",digest[i]]; return hex;
}
static int ODCaptureDirectory(NSURL *workspace,const char *kind){
    int root=open(workspace.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW);if(root<0)return -1;
    if(mkdirat(root,".accepted-creator-projects",0700)&&errno!=EEXIST){close(root);return -1;}(void)fsync(root);
    int store=openat(root,".accepted-creator-projects",O_RDONLY|O_DIRECTORY|O_NOFOLLOW);close(root);if(store<0)return -1;
    if(mkdirat(store,kind,0700)&&errno!=EEXIST){close(store);return -1;}(void)fsync(store);
    int directory=openat(store,kind,O_RDONLY|O_DIRECTORY|O_NOFOLLOW);close(store);return directory;
}
static NSDictionary *ODCaptureRead(int directory,NSString *name){
    int fd=openat(directory,name.UTF8String,O_RDONLY|O_NOFOLLOW);if(fd<0)return nil;struct stat st;NSMutableData *data=nil;
    if(!fstat(fd,&st)&&S_ISREG(st.st_mode)&&st.st_nlink==1&&st.st_size>0&&st.st_size<=64*1024*1024){
        data=[NSMutableData dataWithLength:(NSUInteger)st.st_size];NSUInteger at=0;
        while(at<data.length){ssize_t n=pread(fd,(char *)data.mutableBytes+at,data.length-at,(off_t)at);if(n<0&&errno==EINTR)continue;if(n<=0){data=nil;break;}at+=(NSUInteger)n;}
    }close(fd);id result=data?[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]:nil;return ODObject(result)?result:nil;
}
static BOOL ODCaptureWrite(int directory,NSString *name,NSDictionary *value){
    NSDictionary *prior=ODCaptureRead(directory,name);if(prior)return [prior isEqual:value];NSData *data=ODJSON(value);if(!data||data.length>64*1024*1024)return NO;
    NSString *temporary=[@".tmp-" stringByAppendingString:NSUUID.UUID.UUIDString];int fd=openat(directory,temporary.UTF8String,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW,0600);if(fd<0)return NO;
    BOOL ok=YES;NSUInteger at=0;while(at<data.length){ssize_t n=write(fd,(const char *)data.bytes+at,data.length-at);if(n<0&&errno==EINTR)continue;if(n<=0){ok=NO;break;}at+=(NSUInteger)n;}
    if(fsync(fd))ok=NO;if(close(fd))ok=NO;
    // Atomic no-replace publication: even a conflicting old receipt survives.
    if(ok&&linkat(directory,temporary.UTF8String,directory,name.UTF8String,0))ok=NO;
    unlinkat(directory,temporary.UTF8String,0);if(ok)(void)fsync(directory);
    return ok&&[ODCaptureRead(directory,name) isEqual:value];
}
static NSString *ODCaptureName(NSString *definition,NSNumber *version){return [NSString stringWithFormat:@"%@-v%@.json",ODHash([definition dataUsingEncoding:NSUTF8StringEncoding]),version];}
static NSArray *ODCaptureNames(int directory){
    DIR *stream=fdopendir(dup(directory));if(!stream)return nil;NSMutableArray *names=[NSMutableArray array];struct dirent *entry;
    while((entry=readdir(stream))){NSString *name=[NSString stringWithUTF8String:entry->d_name];if([name hasPrefix:@"."])continue;if(![name hasSuffix:@".json"]||[name containsString:@"/"]||names.count>=10000){closedir(stream);return nil;}[names addObject:name];}closedir(stream);return [names sortedArrayUsingSelector:@selector(compare:)];
}
static NSString *ODAfter(NSString *old) {
    NSISO8601DateFormatter *formatter=[NSISO8601DateFormatter new];formatter.formatOptions=NSISO8601DateFormatWithInternetDateTime|NSISO8601DateFormatWithFractionalSeconds;
    NSDate *previous=[old isKindOfClass:NSString.class]?[formatter dateFromString:old]:nil;
    NSDate *now=[NSDate dateWithTimeIntervalSince1970:MAX(NSDate.date.timeIntervalSince1970,previous?previous.timeIntervalSince1970+0.001:0)];return [formatter stringFromDate:now];
}
static NSString *ODNow(void) { return ODAfter(nil); }
static NSString *ODQuote(NSString *name) { return [NSString stringWithFormat:@"\"%@\"",[name stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""]]; }
static void *ODCreatorQueueKey=&ODCreatorQueueKey;
static dispatch_queue_t ODCreatorQueue(void) { static dispatch_queue_t queue;static dispatch_once_t once;dispatch_once(&once,^{queue=dispatch_queue_create("personal.offlinedokkan.creator",DISPATCH_QUEUE_SERIAL);dispatch_queue_set_specific(queue,ODCreatorQueueKey,ODCreatorQueueKey,NULL);});return queue; }
static NSMutableSet *ODFinishingProjects(void) { static NSMutableSet *set;static dispatch_once_t once;dispatch_once(&once,^{set=[NSMutableSet set];});return set; }
static id ODValue(sqlite3_stmt *s,int i) {
    switch(sqlite3_column_type(s,i)) {
        case SQLITE_INTEGER:return @(sqlite3_column_int64(s,i));
        case SQLITE_FLOAT:return @(sqlite3_column_double(s,i));
        case SQLITE_TEXT:return [NSString stringWithUTF8String:(const char *)sqlite3_column_text(s,i)] ?: @"";
        case SQLITE_BLOB:{ NSData *b=[NSData dataWithBytes:sqlite3_column_blob(s,i) length:(NSUInteger)sqlite3_column_bytes(s,i)]; return [[NSString alloc] initWithData:b encoding:NSUTF8StringEncoding] ?: [b base64EncodedStringWithOptions:0]; }
        default:return NSNull.null;
    }
}
static BOOL ODBind(sqlite3_stmt *s,NSArray *values) {
    if (sqlite3_bind_parameter_count(s)!=(int)values.count) return NO;
    int i=1;for(id v in values){int rc;
        if(v==NSNull.null)rc=sqlite3_bind_null(s,i);
        else if([v isKindOfClass:NSString.class])rc=sqlite3_bind_text(s,i,[v UTF8String],-1,SQLITE_TRANSIENT);
        else if([v isKindOfClass:NSNumber.class]){const char *t=[v objCType];rc=(*t=='d'||*t=='f')?sqlite3_bind_double(s,i,[v doubleValue]):sqlite3_bind_int64(s,i,[v longLongValue]);}
        else return NO;
        if(rc!=SQLITE_OK)return NO;i++;
    }return YES;
}
typedef struct {int64_t remaining;uint64_t deadline;} ODReadBudget;
static uint64_t ODReadClock(void){struct timespec t;if(clock_gettime(CLOCK_MONOTONIC,&t))return UINT64_MAX;return (uint64_t)t.tv_sec*1000000000+(uint64_t)t.tv_nsec;}
static int ODReadProgress(void *raw){ODReadBudget *b=raw;b->remaining-=1000;return b->remaining<0||ODReadClock()>b->deadline;}
static int ODReadAuthorizer(void *raw,int action,const char *a,const char *b,const char *database,const char *trigger){
    (void)trigger;NSDictionary *schema=(__bridge NSDictionary *)raw;
    if(action==SQLITE_SELECT||action==SQLITE_RECURSIVE)return SQLITE_OK;
    if(action==SQLITE_READ){if(database&&strcmp(database,"main"))return SQLITE_DENY;if(!database)return SQLITE_OK;NSString *table=a?[NSString stringWithUTF8String:a]:nil;return table&&(schema[table]||[table isEqual:@"sqlite_master"]||[table isEqual:@"sqlite_schema"])?SQLITE_OK:SQLITE_DENY;}
    if(action==SQLITE_FUNCTION){
        // printf/format report SQLITE_TOOBIG as SQL NULL, so a huge width looks like a successful read.
        static NSSet *functions;static dispatch_once_t once;dispatch_once(&once,^{functions=[NSSet setWithArray:[@"abs char coalesce concat concat_ws count date datetime glob group_concat hex ifnull iif instr json json_array json_array_length json_extract json_group_array json_group_object json_object json_quote json_type json_valid length like likelihood likely lower ltrim max min nullif octet_length quote random replace round rtrim sqlite_source_id sqlite_version strftime substr substring sum total trim typeof unicode unlikely upper" componentsSeparatedByString:@" "]];});
        NSString *function=b?[[NSString stringWithUTF8String:b] lowercaseString]:nil;return function&&[functions containsObject:function]?SQLITE_OK:SQLITE_DENY;
    }
    return SQLITE_DENY;
}
static NSSet *ODProjectionTables(void) {
    static NSSet *tables;static dispatch_once_t once;dispatch_once(&once,^{tables=[NSSet setWithArray:@[@"leader_skill_sets",@"leader_skills",@"passive_skill_sets",@"passive_skill_set_relations",@"passive_skills",@"card_specials",@"special_sets",@"specials",@"extra_special_options",@"card_active_skills",@"active_skill_sets",@"active_skills",@"card_standby_skill_set_relations",@"standby_skill_sets",@"standby_skills",@"standby_skill_set_finish_skill_set_relations",@"card_finish_skill_set_relations",@"finish_skill_sets",@"finish_skills",@"finish_specials",@"card_card_categories",@"card_categories",@"dokkan_fields",@"dokkan_field_active_skill_set_relations",@"dokkan_field_passive_skill_relations",@"link_skills",@"skill_causalities",@"sub_target_types",@"transformation_descriptions"]];});return tables;
}
static BOOL ODAwakenProject(id p) {
    id awaken=p[@"awaken"];return awaken&&awaken!=NSNull.null&&(![awaken isKindOfClass:NSNumber.class]||[awaken boolValue]);
}
static BOOL ODFullBundleProject(id p) {
    for(NSString *key in @[@"formProjects",@"transformLinks",@"assets",@"packedAssets",@"generatedFiles"]){id v=p[key];if(v&&(!ODArray(v)||[v count]))return YES;}
    for(NSString *key in @[@"actionHooks",@"animationAssignments"]){id v=p[key];if(v&&v!=NSNull.null&&(!ODObject(v)||[v count]))return YES;}
    return (p[@"sourceDependencies"]&&p[@"sourceDependencies"]!=NSNull.null) || (p[@"battlePoseBinding"]&&p[@"battlePoseBinding"]!=NSNull.null);
}
static BOOL ODUnsupported(id p) { return ODAwakenProject(p)||ODFullBundleProject(p); }

@implementation ODCreatorSession {
    NSURL *_master,*_directory; NSString *_content,*_game; ODNativeCore *_core;
    dispatch_queue_t _queue; ODBattleStore *_battleStore; ODBattleCoordinator *_battleCoordinator; sqlite3 *_db; NSDictionary *_schema; NSMutableDictionary *_state; NSString *_failure;
    BOOL _originalClientMode;NSString *_originalSaveScope;ODNativeCreatorLease *_originalLease;
    ODNativeFullCreatorValidator *_fullValidator;
}
- (instancetype)initWithMasterURL:(NSURL *)master contentID:(NSString *)contentID game:(NSString *)game directory:(NSURL *)directory core:(ODNativeCore *)core {
    if((self=[super init])){_master=master;_content=[contentID copy];_game=[game copy];_directory=directory;_core=core;_queue=ODCreatorQueue();}return self;
}
- (instancetype)initWithMasterURL:(NSURL *)master contentID:(NSString *)contentID game:(NSString *)game directory:(NSURL *)directory core:(ODNativeCore *)core originalClientSaveScopeSHA256:(NSString *)scope lease:(ODNativeCreatorLease *)lease {
    NSCharacterSet *invalid=[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet];
    if(![scope isKindOfClass:NSString.class]||scope.length!=64||[scope rangeOfCharacterFromSet:invalid].location!=NSNotFound||
       (lease&&(![lease.profileID isEqual:@"local-player"]||![lease.contentID isEqual:contentID]||![lease.saveScopeSHA256 isEqual:scope])))return nil;
    if((self=[self initWithMasterURL:master contentID:contentID game:game directory:directory core:core])){_originalClientMode=YES;_originalSaveScope=[scope copy];_originalLease=lease;}return self;
}
- (BOOL)originalClientMode{return _originalClientMode;}
- (void)executeCreator:(NSString *)operation command:(NSString *)command arguments:(NSDictionary *)arguments reply:(ODCoreReply)reply {
    if(!_originalClientMode){[_core execute:operation profile:@"local-player" command:command arguments:arguments reply:reply];return;}
    if(!_originalLease){dispatch_async(dispatch_get_main_queue(),^{reply(nil,[NSError errorWithDomain:@"OfflineDokkanCreator" code:1 userInfo:@{NSLocalizedDescriptionKey:@"CREATOR_NATIVE_LEASE_REQUIRED"}]);});return;}
    [_core executeCreatorOperation:operation profile:@"local-player" command:command arguments:arguments expectedSaveScopeSHA256:_originalSaveScope lease:_originalLease reply:reply];
}
- (NSString *)finishKey:(NSString *)key { return [_directory.path stringByAppendingFormat:@"|%@",key]; }
- (BOOL)isFinishing:(NSString *)key { return [ODFinishingProjects() containsObject:[self finishKey:key]]; }
- (void)dealloc { if(_db)sqlite3_close_v2(_db); }
- (NSArray *)rows:(NSString *)sql values:(NSArray *)values limit:(NSUInteger)limit {
    sqlite3_stmt *s=NULL;if(sqlite3_prepare_v2(_db,sql.UTF8String,-1,&s,NULL)!=SQLITE_OK)return nil;
    if(!sqlite3_stmt_readonly(s)||!ODBind(s,values)){sqlite3_finalize(s);return nil;}
    NSMutableArray *rows=[NSMutableArray array];int rc;NSUInteger bytes=0;
    while((rc=sqlite3_step(s))==SQLITE_ROW){NSMutableDictionary *row=[NSMutableDictionary dictionary];
        for(int i=0;i<sqlite3_column_count(s);i++){bytes+=(NSUInteger)sqlite3_column_bytes(s,i);row[[NSString stringWithUTF8String:sqlite3_column_name(s,i)]]=ODValue(s,i);}
        if(rows.count>=limit||bytes>32*1024*1024){sqlite3_finalize(s);return nil;}[rows addObject:row];
    }sqlite3_finalize(s);return rc==SQLITE_DONE?rows:nil;
}
- (BOOL)open {
    if(_failure)return NO;if(_state)return YES;
    if(![_game isEqual:@"eclipse"]&&![_game isEqual:@"sparking"]){_failure=@"INVALID_CREATOR_GAME";return NO;}
    struct stat st;if(!_db){if(!_master.isFileURL||lstat(_master.fileSystemRepresentation,&st)||!S_ISREG(st.st_mode)||S_ISLNK(st.st_mode)||st.st_nlink!=1){_failure=@"INVALID_MASTER_FILE";return NO;}
    if(sqlite3_open_v2(_master.fileSystemRepresentation,&_db,SQLITE_OPEN_READONLY|SQLITE_OPEN_NOMUTEX|SQLITE_OPEN_NOFOLLOW,NULL)!=SQLITE_OK){_failure=@"MASTER_OPEN_FAILED";return NO;}
    sqlite3_limit(_db,SQLITE_LIMIT_LENGTH,32*1024*1024);sqlite3_busy_timeout(_db,3000);
    sqlite3_exec(_db,"PRAGMA query_only=ON;PRAGMA trusted_schema=OFF",NULL,NULL,NULL);
    NSMutableDictionary *schema=[NSMutableDictionary dictionary];
    for(NSDictionary *t in [self rows:@"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name" values:@[] limit:1000]){
        NSString *name=t[@"name"];if(!ODIdent(name))continue;NSArray *columns=[self rows:@"SELECT cid,name,type,\"notnull\",dflt_value,pk FROM pragma_table_info(?)" values:@[name] limit:1000];if(!columns){_failure=@"MASTER_SCHEMA_FAILED";return NO;}schema[name]=columns;
    }if(!schema[@"cards"]){_failure=@"MASTER_SCHEMA_FAILED";return NO;}_schema=schema;}
    if(!_directory.isFileURL||![NSFileManager.defaultManager createDirectoryAtURL:_directory withIntermediateDirectories:YES attributes:@{NSFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication} error:nil]||lstat(_directory.fileSystemRepresentation,&st)||!S_ISDIR(st.st_mode)||S_ISLNK(st.st_mode)){_failure=@"CREATOR_STORAGE_UNAVAILABLE";return NO;}
    NSURL *file=[_directory URLByAppendingPathComponent:@"creator-state.json"];
    if(!lstat(file.fileSystemRepresentation,&st)){
        if(!S_ISREG(st.st_mode)||st.st_nlink!=1||st.st_size<0||(uint64_t)st.st_size>ODStoreLimit){_failure=@"INVALID_CREATOR_STORAGE";return NO;}
        NSData *data=[NSData dataWithContentsOfURL:file];id state=data?[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]:nil;
        if(!ODObject(state)||![state[@"version"] isEqual:@1]){_failure=@"INVALID_CREATOR_STORAGE";return NO;}
        if(![state[@"contentId"] isEqual:_content]){_failure=@"MASTER_MIGRATION_REQUIRED";return NO;}
        for(NSString *key in @[@"projects",@"versions",@"settings",@"intents",@"definitionIDs"])if(!ODObject(state[key])){_failure=@"INVALID_CREATOR_STORAGE";return NO;}
        for(NSString *key in state[@"intents"]){id intent=state[@"intents"][key];id context=ODObject(intent)?intent[@"context"]:nil;
            if(!ODName(key)||!ODObject(context)||!ODName(intent[@"snapshot"])||!ODName(intent[@"command"])||![intent[@"hash"] isKindOfClass:NSString.class]||[intent[@"hash"] length]!=64||!ODArray(intent[@"unchangedTables"])||![context[@"contentId"] isEqual:_content]||![context[@"sourceDatabase"] isEqual:_game]||!ODName(context[@"definitionId"])||!ODInteger(context[@"version"])||[context[@"version"] longLongValue]<1||![@[@"UR",@"LR",@"SLR",@"GR"] containsObject:context[@"rarity"]]){_failure=@"INVALID_CREATOR_INTENT";return NO;}
            if((context[@"creatorId"]||context[@"creatorName"])&&(!ODName(context[@"creatorId"])||![context[@"creatorName"] isKindOfClass:NSString.class])){_failure=@"INVALID_CREATOR_INTENT";return NO;}
            for(id table in intent[@"unchangedTables"])if(!ODIdent(table)){_failure=@"INVALID_CREATOR_INTENT";return NO;}
            if(intent[@"result"]&&(!ODObject(intent[@"result"])||![intent[@"result"][@"imported"] isEqual:@YES]||![intent[@"result"][@"definitionId"] isEqual:context[@"definitionId"]]||![intent[@"result"][@"version"] isEqual:context[@"version"]])){_failure=@"INVALID_CREATOR_INTENT";return NO;}
            if(intent[@"result"][@"instanceId"]&&(!ODInteger(intent[@"result"][@"instanceId"])||[intent[@"result"][@"instanceId"] longLongValue]<1||CFGetTypeID((__bridge CFTypeRef)intent[@"result"][@"instanceId"])==CFBooleanGetTypeID()||![intent[@"result"][@"available"] isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)intent[@"result"][@"available"])!=CFBooleanGetTypeID())){_failure=@"INVALID_CREATOR_INTENT";return NO;}
        }
        _state=state;
    }else if(errno==ENOENT){_state=[@{@"version":@1,@"contentId":_content,@"projects":[NSMutableDictionary dictionary],@"versions":[NSMutableDictionary dictionary],@"settings":[NSMutableDictionary dictionary],@"intents":[NSMutableDictionary dictionary],@"definitionIDs":[NSMutableDictionary dictionary]} mutableCopy];}
    else{_failure=@"CREATOR_STORAGE_UNAVAILABLE";return NO;}return YES;
}
- (BOOL)reloadState { _state=nil;return [self open]; }
- (NSMutableDictionary *)copyState { return [NSJSONSerialization JSONObjectWithData:ODJSON(_state) options:NSJSONReadingMutableContainers error:nil]; }
- (BOOL)commit:(NSMutableDictionary *)next {
    NSData *bytes=ODJSON(next);if(!bytes||bytes.length>ODStoreLimit)return NO;
    int dir=open(_directory.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW);if(dir<0)return NO;
    struct stat st;BOOL valid=fstatat(dir,"creator-state.json",&st,AT_SYMLINK_NOFOLLOW)==0?(S_ISREG(st.st_mode)&&st.st_nlink==1):errno==ENOENT;
    NSString *temp=[@".creator-" stringByAppendingString:NSUUID.UUID.UUIDString];int fd=valid?openat(dir,temp.UTF8String,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW,0600):-1;
    BOOL ok=fd>=0;NSUInteger at=0;while(ok&&at<bytes.length){ssize_t n=write(fd,(const char *)bytes.bytes+at,bytes.length-at);if(n<0&&errno==EINTR)continue;if(n<=0)ok=NO;else at+=(NSUInteger)n;}
    if(fd>=0){if(fsync(fd))ok=NO;if(close(fd))ok=NO;}
    if(ok&&renameat(dir,temp.UTF8String,dir,"creator-state.json"))ok=NO;
    // The file is already durable and atomically renamed; unsupported directory fsync does not undo it.
    if(ok){(void)fsync(dir);_state=next;}else unlinkat(dir,temp.UTF8String,0);
    close(dir);return ok;
}
// Archive operations are deliberately absent from handleOperation's public
// allowlist. Only the admitted native archive worker can supply these bytes.
- (void)exportArchiveDocumentsWithReply:(void (^)(NSDictionary<NSString *,NSData *> *,NSString *))reply {
    dispatch_async(_queue,^{
        if(![self reloadState]){[self reply:reply result:nil error:self->_failure];return;}
        NSMutableDictionary *files=[NSMutableDictionary dictionary];NSUInteger total=0;
        NSRegularExpression *keyPattern=[NSRegularExpression regularExpressionWithPattern:@"\\A[A-Za-z0-9_-]{1,100}\\z" options:0 error:nil];
        for(NSString *key in self->_state[@"projects"]){
            NSDictionary *project=[self project:key];NSData *data=ODJSON(project);
            if(![keyPattern firstMatchInString:key options:0 range:NSMakeRange(0,key.length)]||![self validProject:project]){[self reply:reply result:nil error:@"INVALID_ARCHIVE_DOCUMENT"];return;}
            files[[NSString stringWithFormat:@"projects/%@.json",key]]=data;total+=data.length;
            NSArray *versions=self->_state[@"versions"][key]?:@[];if(!ODArray(versions)||versions.count>10){[self reply:reply result:nil error:@"INVALID_SAVED_VERSIONS"];return;}
            NSMutableArray *index=[NSMutableArray array];NSUInteger versionTotal=0;
            for(NSDictionary *row in versions){
                if(!ODObject(row)){[self reply:reply result:nil error:@"INVALID_SAVED_VERSIONS"];return;}
                NSDictionary *document=row[@"project"];NSData *body=ODJSON(document);NSString *version=[row[@"versionKey"] lowercaseString];NSUUID *uuid=[[NSUUID alloc] initWithUUIDString:version];
                if(!uuid||!ODArchiveVersion(version)||![self validProject:document]||![document[@"key"] isEqual:key]||![row[@"revision"] isEqual:ODHash(body)]||![row[@"label"] isKindOfClass:NSString.class]||![row[@"createdAt"] isKindOfClass:NSString.class]){[self reply:reply result:nil error:@"INVALID_SAVED_VERSIONS"];return;}
                NSDictionary *header=@{@"versionKey":version,@"label":row[@"label"],@"createdAt":row[@"createdAt"],@"bytes":@(body.length),@"key":key,@"revision":ODHash(body)};
                NSMutableData *envelope=[ODJSON(header) mutableCopy];[envelope appendBytes:"\n" length:1];[envelope appendData:body];
                files[[NSString stringWithFormat:@"project-versions/%@/%@.version",key,version]]=envelope;
                [index addObject:@{@"versionKey":version,@"label":header[@"label"],@"createdAt":header[@"createdAt"],@"bytes":@(body.length),@"fileBytes":@(envelope.length)}];total+=envelope.length;versionTotal+=envelope.length;
            }
            if(versionTotal>40*1024*1024){[self reply:reply result:nil error:@"ARCHIVE_DOCUMENT_LIMIT"];return;}
            NSData *indexData=ODJSON(index);files[[NSString stringWithFormat:@"project-versions/%@/index.json",key]]=indexData;total+=indexData.length;
            if(total>ODStoreLimit||files.count>10000){[self reply:reply result:nil error:@"ARCHIVE_DOCUMENT_LIMIT"];return;}
        }
        [self reply:reply result:files error:nil];
    });
}
- (void)restoreArchiveDocuments:(NSDictionary<NSString *,NSData *> *)files reply:(ODCreatorReply)reply {
    // Snapshot before asynchronous dispatch. No filesystem capability escapes.
    if(!ODObject(files)||files.count>10000){[self reply:reply result:nil error:@"INVALID_ARCHIVE_DOCUMENT"];return;}
    NSMutableDictionary *frozen=[NSMutableDictionary dictionary];NSUInteger total=0;
    for(id key in files){id value=files[key];if(![key isKindOfClass:NSString.class]||![value isKindOfClass:NSData.class]||[value length]>ODProjectLimit+65536||(total+=[value length])>ODStoreLimit){[self reply:reply result:nil error:@"ARCHIVE_DOCUMENT_LIMIT"];return;}frozen[[key copy]]=[value copy];}
    dispatch_async(_queue,^{
        if(![self reloadState]){[self reply:reply result:nil error:self->_failure];return;}
        NSMutableDictionary *next=[self copyState],*projects=[NSMutableDictionary dictionary],*versions=[NSMutableDictionary dictionary];NSMutableSet *consumed=[NSMutableSet set];NSUInteger restored=0,unchanged=0;
        NSRegularExpression *projectPath=[NSRegularExpression regularExpressionWithPattern:@"\\Aprojects/([A-Za-z0-9_-]{1,100})\\.json\\z" options:0 error:nil];
        for(NSString *path in frozen){NSTextCheckingResult *match=[projectPath firstMatchInString:path options:0 range:NSMakeRange(0,path.length)];if(!match)continue;
            NSString *key=[path substringWithRange:[match rangeAtIndex:1]];id project=[NSJSONSerialization JSONObjectWithData:frozen[path] options:0 error:nil];
            if(![self validProject:project]||![project[@"key"] isEqual:key]||[self isFinishing:key]){[self reply:reply result:nil error:@"INVALID_ARCHIVE_DOCUMENT"];return;}
            id old=next[@"projects"][key];if(old&&![old isEqual:project]){[self reply:reply result:nil error:@"ARCHIVE_DOCUMENT_CONFLICT"];return;}
            projects[key]=project;[consumed addObject:path];if(old)unchanged++;else restored++;
        }
        for(NSString *key in projects){NSString *prefix=[NSString stringWithFormat:@"project-versions/%@/",key],*indexPath=[prefix stringByAppendingString:@"index.json"];NSData *indexData=frozen[indexPath];if(!indexData)continue;
            id index=[NSJSONSerialization JSONObjectWithData:indexData options:0 error:nil];if(!ODArray(index)||[index count]>10){[self reply:reply result:nil error:@"INVALID_SAVED_VERSIONS"];return;}
            NSMutableArray *rows=[NSMutableArray array];NSMutableSet *seen=[NSMutableSet set];NSUInteger size=0;
            for(id item in index){NSString *version=ODObject(item)?item[@"versionKey"]:nil;NSUUID *uuid=[version isKindOfClass:NSString.class]?[[NSUUID alloc] initWithUUIDString:version]:nil;
                if(!uuid||!ODArchiveVersion(version)||[seen containsObject:version]){[self reply:reply result:nil error:@"INVALID_SAVED_VERSIONS"];return;}[seen addObject:version];
                NSString *path=[[prefix stringByAppendingString:version] stringByAppendingString:@".version"];NSData *file=frozen[path];const unsigned char *bytes=file.bytes;NSUInteger split=0;while(split<MIN(file.length,65536)&&bytes[split]!='\n')split++;
                if(!file||split==0||split>=MIN(file.length,65536)){[self reply:reply result:nil error:@"INVALID_SAVED_VERSIONS"];return;}
                id header=[NSJSONSerialization JSONObjectWithData:[file subdataWithRange:NSMakeRange(0,split)] options:0 error:nil];NSData *body=[file subdataWithRange:NSMakeRange(split+1,file.length-split-1)];id document=[NSJSONSerialization JSONObjectWithData:body options:0 error:nil];
                if(!ODObject(header)||![header[@"key"] isEqual:key]||![header[@"versionKey"] isEqual:version]||![header[@"revision"] isEqual:ODHash(body)]||![self validProject:document]||![document[@"key"] isEqual:key]||![item[@"bytes"] isEqual:@(body.length)]||![header[@"bytes"] isEqual:@(body.length)]||![item[@"fileBytes"] isEqual:@(file.length)]||![header[@"label"] isKindOfClass:NSString.class]||![header[@"label"] length]||[header[@"label"] length]>160||![header[@"createdAt"] isKindOfClass:NSString.class]||![item[@"label"] isEqual:header[@"label"]]||![item[@"createdAt"] isEqual:header[@"createdAt"]]||(size+=file.length)>40*1024*1024){[self reply:reply result:nil error:@"INVALID_SAVED_VERSIONS"];return;}
                NSData *nativeBody=ODJSON(document);[rows addObject:@{@"versionKey":version,@"label":header[@"label"],@"createdAt":header[@"createdAt"],@"bytes":@(nativeBody.length),@"revision":ODHash(nativeBody),@"project":document,@"safety":@NO}];[consumed addObject:path];
            }
            NSArray *old=next[@"versions"][key]?:@[];
            // Existing histories survive; a conflicting history is explicit,
            // never silently replaced by an older archive.
            if(old.count&&rows.count){NSMutableDictionary *existing=[NSMutableDictionary dictionary];for(NSDictionary *row in old)existing[[row[@"versionKey"] lowercaseString]]=row;
                for(NSDictionary *row in rows){NSDictionary *prior=existing[row[@"versionKey"]];if(!prior||![prior[@"project"] isEqual:row[@"project"]]||![prior[@"label"] isEqual:row[@"label"]]||![prior[@"createdAt"] isEqual:row[@"createdAt"]]){[self reply:reply result:nil error:@"ARCHIVE_DOCUMENT_CONFLICT"];return;}}
            }else if(!old.count)versions[key]=rows;
            if(!old.count&&(rows.count||!next[@"versions"][key]))restored+=rows.count+1;else unchanged+=rows.count+1;
            [consumed addObject:indexPath];
        }
        if(consumed.count!=frozen.count){[self reply:reply result:nil error:@"INVALID_ARCHIVE_DOCUMENT_PATH"];return;}
        [next[@"projects"] addEntriesFromDictionary:projects];[next[@"versions"] addEntriesFromDictionary:versions];
        if(![self commit:next]){[self reply:reply result:nil error:@"CREATOR_STORAGE_WRITE_FAILED"];return;}
        [self reply:reply result:@{@"restored":@(restored),@"unchanged":@(unchanged),@"documents":@(consumed.count)} error:nil];
    });
}
- (id)project:(NSString *)key { id p=_state[@"projects"][key];return ODObject(p)?p:nil; }
- (BOOL)validProject:(id)p {
    NSData *data=ODJSON(p);if(!(ODObject(p)&&data&&data.length<=ODProjectLimit&&[p[@"format"] isEqual:@"dokkan-unit-forge"]&&[p[@"version"] isEqual:@1]&&ODName(p[@"key"])&&ODObject(p[@"tables"])&&ODArray(p[@"tables"][@"cards"])&&[p[@"tables"][@"cards"] count]==1&&ODObject(p[@"tables"][@"cards"][0])&&ODObject(p[@"cardOverrides"])&&ODObject(p[@"source"])&&[(p[@"source"][@"database"]?:@"eclipse") isEqual:_game]))return NO;
    if(p[@"patch"]&&!ODObject(p[@"patch"]))return NO;if(p[@"updatedAt"]&&![p[@"updatedAt"] isKindOfClass:NSString.class])return NO;
    if(p[@"source"][@"contentId"]&&![p[@"source"][@"contentId"] isEqual:_content])return NO;
    if(!ODInteger(p[@"targetId"])||[p[@"targetId"] longLongValue]<=0)return NO;
    if(p[@"formProjects"]&&p[@"formProjects"]!=NSNull.null&&(!ODArray(p[@"formProjects"])||[p[@"formProjects"] count]>64))return NO;
    // Incomplete/invalid card settings remain editable drafts; semantic checks belong to Finish/core.
    return YES;
}
- (NSDictionary *)summary:(NSDictionary *)p {
    NSMutableDictionary *card=[p[@"tables"][@"cards"][0] mutableCopy];[card addEntriesFromDictionary:p[@"cardOverrides"]];
    NSMutableArray *reserved=[NSMutableArray arrayWithObject:p[@"targetId"]];if(ODArray(p[@"formProjects"]))for(id form in p[@"formProjects"])if(ODObject(form)&&ODInteger(form[@"targetId"]))[reserved addObject:form[@"targetId"]];
    return @{@"key":p[@"key"],@"name":[card[@"name"] isKindOfClass:NSString.class]?card[@"name"]:@"Untitled unit",@"lvMax":ODInteger(card[@"lv_max"])?card[@"lv_max"]:@0,@"targetId":p[@"targetId"],@"reservedIds":reserved,@"updatedAt":p[@"updatedAt"]?:@"",@"rarity":ODInteger(card[@"rarity"])?card[@"rarity"]:@0,@"element":ODInteger(card[@"element"])?card[@"element"]:@0,@"resourceId":ODInteger(card[@"resource_id"])?card[@"resource_id"]:@0,@"sourceDatabase":_game,@"origin":[p[@"libraryOrigin"] isKindOfClass:NSString.class]?p[@"libraryOrigin"]:@"created",@"author":[p[@"patch"][@"author"] isKindOfClass:NSString.class]?p[@"patch"][@"author"]:@""};
}
- (NSArray *)query:(NSDictionary *)args {
    NSString *table=args[@"table"];NSArray *schema=ODIdent(table)?_schema[table]:nil;if(!schema)return nil;
    NSSet *columns=[NSSet setWithArray:[schema valueForKey:@"name"]];NSMutableArray *where=[NSMutableArray array],*values=[NSMutableArray array];
    id filters=args[@"filters"];if(filters&&!ODObject(filters))return nil;
    for(NSString *key in filters){if(!ODIdent(key)||![columns containsObject:key])return nil;id value=filters[key];[where addObject:[NSString stringWithFormat:@"%@ IS ?",ODQuote(key)]];[values addObject:value];}
    id ids=args[@"ids"];if(ids){if(!ODArray(ids)||[ids count]>1000||![columns containsObject:@"id"])return nil;if(![ids count])return @[];NSMutableArray *marks=[NSMutableArray array];for(id v in ids){[marks addObject:@"?"];[values addObject:v];}[where addObject:[NSString stringWithFormat:@"id IN (%@)",[marks componentsJoinedByString:@","]]];}
    id search=args[@"search"];if(search&&(!ODObject(search)||!ODIdent(search[@"column"])||![columns containsObject:search[@"column"]]))return nil;
    if([search[@"text"] isKindOfClass:NSString.class]&&[search[@"text"] length]){if([search[@"text"] length]>200)return nil;[where addObject:[NSString stringWithFormat:@"%@ LIKE ?",ODQuote(search[@"column"])]];[values addObject:[NSString stringWithFormat:@"%%%@%%",search[@"text"]]];}
    NSString *projection=@"*";id requested=args[@"columns"];if(requested){if(!ODArray(requested)||![requested count]||[requested count]>columns.count)return nil;NSMutableArray *parts=[NSMutableArray array];for(id c in requested){if(!ODIdent(c)||![columns containsObject:c])return nil;[parts addObject:ODQuote(c)];}projection=[parts componentsJoinedByString:@","];}
    id rawOrder=args[@"order"]?:@"id";if(![rawOrder isKindOfClass:NSString.class]||[rawOrder length]>128)return nil;
    NSArray *orderParts=[[rawOrder componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
    if(!orderParts.count||orderParts.count>2||!ODIdent(orderParts[0])||![columns containsObject:orderParts[0]])return nil;
    NSString *direction=orderParts.count==2?[orderParts[1] uppercaseString]:@"ASC";if(![@[@"ASC",@"DESC"] containsObject:direction])return nil;
    if((args[@"limit"]&&!ODInteger(args[@"limit"]))||(args[@"offset"]&&!ODInteger(args[@"offset"])))return nil;
    NSInteger limit=MAX(1,MIN(5000,args[@"limit"]?[args[@"limit"] integerValue]:100)),offset=MAX(0,[args[@"offset"] integerValue]);if(offset>10000000)return nil;
    NSString *sql=[NSString stringWithFormat:@"SELECT %@ FROM %@%@ ORDER BY %@ %@ LIMIT %ld OFFSET %ld",projection,ODQuote(table),where.count?[@" WHERE " stringByAppendingString:[where componentsJoinedByString:@" AND "]]:@"",ODQuote(orderParts[0]),direction,(long)limit,(long)offset];return [self rows:sql values:values limit:5000];
}
- (NSArray *)selectedMasterRead:(NSDictionary *)arguments {
    NSString *sql=arguments[@"sql"];NSArray *params=arguments[@"params"]?:@[];
    if(arguments.count>2||![sql isKindOfClass:NSString.class]||[sql lengthOfBytesUsingEncoding:NSUTF8StringEncoding]>16384||!ODArray(params)||params.count>1000)return nil;
    unichar zero=0;if([sql rangeOfString:[NSString stringWithCharacters:&zero length:1]].location!=NSNotFound)return nil;
    NSRegularExpression *prefix=[NSRegularExpression regularExpressionWithPattern:@"\\A\\s*(SELECT|WITH)\\b" options:NSRegularExpressionCaseInsensitive error:nil];if(![prefix firstMatchInString:sql options:0 range:NSMakeRange(0,sql.length)])return nil;
    int oldSQL=sqlite3_limit(_db,SQLITE_LIMIT_SQL_LENGTH,16384),oldColumns=sqlite3_limit(_db,SQLITE_LIMIT_COLUMN,128),oldLength=sqlite3_limit(_db,SQLITE_LIMIT_LENGTH,16*1024*1024);
    ODReadBudget budget={INT64_C(20000000),ODReadClock()+UINT64_C(3000000000)};
    sqlite3_set_authorizer(_db,ODReadAuthorizer,(__bridge void *)_schema);sqlite3_progress_handler(_db,1000,ODReadProgress,&budget);
    sqlite3_stmt *statement=NULL;const char *tail=NULL;BOOL ok=sqlite3_prepare_v3(_db,sql.UTF8String,-1,0,&statement,&tail)==SQLITE_OK&&statement&&sqlite3_stmt_readonly(statement)&&ODBind(statement,params);
    if(ok){while(tail&&isspace((unsigned char)*tail))tail++;if(tail&&*tail)ok=NO;}
    NSMutableArray *rows=[NSMutableArray array];NSUInteger bytes=0;int rc=SQLITE_DONE;
    while(ok&&(rc=sqlite3_step(statement))==SQLITE_ROW){
        if(rows.count>=5000){ok=NO;break;}NSMutableDictionary *row=[NSMutableDictionary dictionary];
        for(int c=0;c<sqlite3_column_count(statement);c++){const char *name=sqlite3_column_name(statement,c);if(!name){ok=NO;break;}bytes+=(NSUInteger)sqlite3_column_bytes(statement,c)+strlen(name)+8;if(bytes>16*1024*1024){ok=NO;break;}row[[NSString stringWithUTF8String:name]]=ODValue(statement,c);}
        if(ok)[rows addObject:row];
    }
    if(rc!=SQLITE_DONE)ok=NO;if(statement)sqlite3_finalize(statement);
    sqlite3_set_authorizer(_db,NULL,NULL);sqlite3_progress_handler(_db,0,NULL,NULL);sqlite3_limit(_db,SQLITE_LIMIT_SQL_LENGTH,oldSQL);sqlite3_limit(_db,SQLITE_LIMIT_COLUMN,oldColumns);sqlite3_limit(_db,SQLITE_LIMIT_LENGTH,oldLength);
    NSData *encoded=ok?ODJSON(rows):nil;return encoded&&encoded.length<=16*1024*1024?rows:nil;
}
- (BOOL)unchanged:(NSArray *)rows table:(NSString *)table {
    NSArray *schema=ODIdent(table)?_schema[table]:nil;if(!schema||!ODArray(rows)||rows.count>5000)return NO;
    NSArray *names=[schema valueForKey:@"name"];NSMutableArray *keys=[NSMutableArray array];for(NSDictionary *c in schema)if([c[@"pk"] integerValue]>0)[keys addObject:c[@"name"]];if(!keys.count&&[names containsObject:@"id"])[keys addObject:@"id"];if(!keys.count)return NO;
    for(id row in rows){if(!ODObject(row)||[row count]!=names.count)return NO;NSMutableArray *conditions=[NSMutableArray array],*values=[NSMutableArray array];for(NSString *key in keys){if(!row[key])return NO;[conditions addObject:[NSString stringWithFormat:@"%@ IS ?",ODQuote(key)]];[values addObject:row[key]];}
        NSArray *found=[self rows:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ LIMIT 2",ODQuote(table),[conditions componentsJoinedByString:@" AND "]] values:values limit:2];if(found.count!=1||![found[0] isEqual:row])return NO;
    }return YES;
}
- (NSArray *)proofForProject:(NSDictionary *)p {
    NSMutableArray *proof=[NSMutableArray array];for(NSString *table in p[@"tables"]){if([table isEqual:@"cards"]||[ODProjectionTables() containsObject:table])continue;id rows=p[@"tables"][table];if(!ODArray(rows))return nil;if(![rows count])continue;if(![self unchanged:rows table:table])return nil;[proof addObject:table];}return proof;
}
- (void)reply:(ODCreatorReply)reply result:(id)result error:(NSString *)error { dispatch_async(dispatch_get_main_queue(),^{reply(result,error);}); }
- (void)handleOperation:(NSString *)operation arguments:(NSDictionary *)arguments reply:(ODCreatorReply)reply {
    NSData *request=ODJSON(arguments);
    NSArray *allowed=@[@"info",@"query",@"querySparking",@"creatorMasterRead",@"wipeCreatorDocuments",@"cardIndex",@"projects",@"loadProject",@"saveProject",@"deleteProject",@"patches",@"assets",@"settings",@"settingsSave",@"listProjectVersions",@"saveProjectVersion",@"loadProjectVersion",@"deleteProjectVersion",@"restoreProjectVersion",@"offlineCreatorPrepare",@"offlineCreatorFinish",@"offlineGameSnapshot",@"offlineCardStats",@"offlineTeamSet",@"offlineBattleLoad",@"offlineBattleDispatch"];
    if(![operation isKindOfClass:NSString.class]||![allowed containsObject:operation]||!ODObject(arguments)||!request||request.length>ODRequestLimit){[self reply:reply result:nil error:@"INVALID_OR_UNSUPPORTED_CREATOR_REQUEST"];return;}
    if(_originalClientMode&&[@[@"offlineGameSnapshot",@"offlineCardStats",@"offlineTeamSet",@"offlineBattleLoad",@"offlineBattleDispatch"] containsObject:operation]){[self reply:reply result:nil error:@"ORIGINAL_CLIENT_GAMEPLAY_ONLY"];return;}
    // Freeze values crossing the asynchronous native boundary.
    NSDictionary *snapshot=[NSJSONSerialization JSONObjectWithData:request options:0 error:nil];NSString *op=[operation copy];
    dispatch_async(_queue,^{[self handle:op args:snapshot reply:reply];});
}
- (void)gameOperation:(NSString *)op args:(NSDictionary *)args reply:(ODCreatorReply)reply {
    if(_originalClientMode){[self reply:reply result:nil error:@"ORIGINAL_CLIENT_GAMEPLAY_ONLY"];return;}
    if([op isEqual:@"offlineGameSnapshot"]){
        if(args.count){[self reply:reply result:nil error:@"INVALID_GAME_ARGUMENTS"];return;}
        [_core execute:@"profile.refresh" profile:@"local-player" command:NSUUID.UUID.UUIDString arguments:@{} reply:^(id result,NSError *failure){[self reply:reply result:result error:failure.localizedDescription?:(!ODObject(result)?@"INVALID_CORE_REPLY":nil)];}];return;
    }
    if([op isEqual:@"offlineCardStats"]){
        id instance=args[@"instanceId"];
        if(args.count!=1||!ODInteger(instance)||[instance longLongValue]<1||CFGetTypeID((__bridge CFTypeRef)instance)==CFBooleanGetTypeID()){[self reply:reply result:nil error:@"INVALID_GAME_ARGUMENTS"];return;}
        [_core execute:@"card.stats" profile:@"local-player" command:nil arguments:@{@"instance_id":instance} reply:^(id result,NSError *failure){[self reply:reply result:result error:failure.localizedDescription?:(!ODObject(result)?@"INVALID_CORE_REPLY":nil)];}];return;
    }
    id slot=args[@"slot"],members=args[@"members"],intent=args[@"intentId"];
    BOOL valid=args.count==3&&ODInteger(slot)&&[slot longLongValue]>=0&&[slot longLongValue]<=19&&CFGetTypeID((__bridge CFTypeRef)slot)!=CFBooleanGetTypeID()&&ODArray(members)&&[members count]<=6&&ODName(intent);
    if(valid){for(id instance in members)if(!ODInteger(instance)||[instance longLongValue]<1||CFGetTypeID((__bridge CFTypeRef)instance)==CFBooleanGetTypeID()){valid=NO;break;}}
    if(valid)valid=[NSSet setWithArray:members].count==[members count];
    if(!valid){[self reply:reply result:nil error:@"INVALID_GAME_ARGUMENTS"];return;}
    [_core execute:@"team.set" profile:@"local-player" command:[@"game-team:" stringByAppendingString:intent] arguments:@{@"slot":slot,@"members":members} reply:^(id result,NSError *failure){
        (void)result;
        if(failure){[self reply:reply result:nil error:failure.localizedDescription];return;}
        [self->_core execute:@"profile.snapshot" profile:@"local-player" command:nil arguments:@{} reply:^(id profile,NSError *error){[self reply:reply result:profile error:error.localizedDescription?:(!ODObject(profile)?@"INVALID_CORE_REPLY":nil)];}];
    }];
}
- (void)nativeBattleOperation:(NSString *)operation arguments:(NSDictionary *)arguments reply:(ODCreatorReply)reply {
    if(_originalClientMode){[self reply:reply result:nil error:@"ORIGINAL_CLIENT_GAMEPLAY_ONLY"];return;}
    // This entrypoint has no registration in ODCreatorController or its page
    // operation whitelist. Only the native-owned battle coordinator may use it.
    if(![operation isKindOfClass:NSString.class]||![@[@"offlineBattleRead",@"offlineBattleCompareSwap"] containsObject:operation]||!ODObject(arguments)){[self reply:reply result:nil error:@"INVALID_NATIVE_BATTLE_OPERATION"];return;}
    NSData *request=ODJSON(arguments);if(!request||request.length>12*1024*1024){[self reply:reply result:nil error:@"BATTLE_STORAGE_REQUEST_INVALID"];return;}
    NSString *op=[operation copy];NSDictionary *args=[NSJSONSerialization JSONObjectWithData:request options:0 error:nil];
    dispatch_async(_queue,^{
        if(!self->_battleStore)self->_battleStore=[[ODBattleStore alloc] initWithDirectory:[self->_directory URLByAppendingPathComponent:@"battle"] source:self->_game contentID:self->_content];
        NSError *error=nil;id result=nil;
        if([op isEqual:@"offlineBattleRead"]){
            if(args.count){[self reply:reply result:nil error:@"BATTLE_STORAGE_REQUEST_INVALID"];return;}
            result=[self->_battleStore read:&error];if(!result&&!error)result=NSNull.null;
        }else{
            id token=args[@"expectedToken"],data=args[@"data"];
            if(args.count!=2||!token||(token!=NSNull.null&&![token isKindOfClass:NSString.class])||![data isKindOfClass:NSString.class]){[self reply:reply result:nil error:@"BATTLE_STORAGE_REQUEST_INVALID"];return;}
            result=[self->_battleStore compareAndSwap:token==NSNull.null?nil:token data:data error:&error];
        }
        [self reply:reply result:result error:error.localizedDescription];
    });
}
- (ODBattleCoordinator *)battleCoordinator {
    if(_originalClientMode)return nil;
    // Lazy: ordinary Creator startup/project operations create no JS engine.
    if(!_battleCoordinator){
        __weak ODCreatorSession *weakSelf=self;
        _battleCoordinator=[[ODBattleCoordinator alloc] initWithContentID:_content storage:^(NSString *operation,NSDictionary *arguments,ODBattleCoordinatorReply reply){
            ODCreatorSession *session=weakSelf;
            if(session)[session nativeBattleOperation:operation arguments:arguments reply:reply];
            else reply(nil,@"BATTLE_NATIVE_SESSION_CLOSED");
        }];
    }return _battleCoordinator;
}
- (void)startTrustedBattlePlan:(NSDictionary *)plan reply:(ODCreatorReply)reply {
    if(_originalClientMode){[self reply:reply result:nil error:@"ORIGINAL_CLIENT_GAMEPLAY_ONLY"];return;}
    NSData *bytes=ODJSON(plan);if(!ODObject(plan)||!bytes||bytes.length>512*1024){[self reply:reply result:nil error:@"BATTLE_TRUSTED_PLAN_INVALID"];return;}
    NSDictionary *snapshot=[NSJSONSerialization JSONObjectWithData:bytes options:0 error:nil];
    dispatch_async(_queue,^{[[self battleCoordinator] startTrustedPlan:snapshot reply:reply];});
}
- (void)openTrustedBattlePlan:(NSDictionary *)reference reply:(ODCreatorReply)reply {
    if(_originalClientMode){[self reply:reply result:nil error:@"ORIGINAL_CLIENT_GAMEPLAY_ONLY"];return;}
    NSData *bytes=ODJSON(reference);if(!ODObject(reference)||!bytes||bytes.length>4096){[self reply:reply result:nil error:@"BATTLE_TRUSTED_PLAN_INVALID"];return;}
    NSDictionary *snapshot=[NSJSONSerialization JSONObjectWithData:bytes options:0 error:nil];
    dispatch_async(_queue,^{[[self battleCoordinator] openTrustedPlan:snapshot reply:reply];});
}
- (void)handle:(NSString *)op args:(NSDictionary *)a reply:(ODCreatorReply)reply {
    if([op isEqual:@"offlineBattleLoad"]){
        if(a.count){[self reply:reply result:nil error:@"INVALID_BATTLE_ARGUMENTS"];return;}
        [[self battleCoordinator] load:reply];return;
    }
    if([op isEqual:@"offlineBattleDispatch"]){
        if(a.count!=1||!ODObject(a[@"command"])){[self reply:reply result:nil error:@"INVALID_BATTLE_ARGUMENTS"];return;}
        [[self battleCoordinator] dispatchCommand:a[@"command"] reply:reply];return;
    }
    if([@[@"offlineGameSnapshot",@"offlineCardStats",@"offlineTeamSet"] containsObject:op]){[self gameOperation:op args:a reply:reply];return;}
    if(![self open]){[self reply:reply result:nil error:_failure];return;}
    if(![@[@"info",@"query",@"querySparking",@"creatorMasterRead",@"cardIndex",@"patches",@"assets"] containsObject:op]&&![self reloadState]){[self reply:reply result:nil error:_failure];return;}
    id result=nil;NSString *error=nil;NSString *key=a[@"key"];NSDictionary *project=ODName(key)?[self project:key]:nil;
    if([op isEqual:@"info"]){NSArray *r=[self rows:@"SELECT count(*) AS n FROM cards" values:@[] limit:1];result=r?@{@"schema":_schema,@"count":r[0][@"n"],@"meta":@{@"source":@"Your imported game database",@"content_id":_content},@"database":@{@"canRestore":@NO},@"sourceDatabase":_game,@"offlineCreator":@{@"sourceDatabase":_game,@"contentId":_content,@"originalClientMode":@(_originalClientMode)}}:nil;}
    else if([op isEqual:@"query"]||[op isEqual:@"querySparking"]){if([op isEqual:@"querySparking"]&&![_game isEqual:@"sparking"])error=@"SPARKING_MASTER_NOT_SELECTED";else result=[self query:a];}
    else if([op isEqual:@"creatorMasterRead"]){result=[self selectedMasterRead:a];if(!result)error=@"SELECTED_MASTER_READ_REJECTED_OR_LIMIT_EXCEEDED";}
    else if([op isEqual:@"cardIndex"]){NSArray *want=@[@"id",@"name",@"rarity",@"element",@"open_at",@"hp_max",@"atk_max",@"def_max",@"resource_id",@"passive_skill_set_id",@"leader_skill_set_id",@"optimal_awakening_grow_type"];NSSet *have=[NSSet setWithArray:[_schema[@"cards"] valueForKey:@"name"]];NSMutableArray *select=[NSMutableArray array];for(NSString *c in want)[select addObject:[NSString stringWithFormat:@"%@ AS %@",[have containsObject:c]?ODQuote(c):@"NULL",ODQuote(c)]];
        NSArray *cards=[self rows:[NSString stringWithFormat:@"SELECT %@ FROM cards WHERE id %% 10=1 AND ((id>=1000000 AND id<3000000) OR id>=10000000%@) AND hp_max>300 AND passive_skill_set_id IS NOT NULL AND leader_skill_set_id IS NOT NULL ORDER BY id",[select componentsJoinedByString:@","],[_game isEqual:@"sparking"]?@" OR (id>=100000 AND id<1000000)":@""] values:@[] limit:100000];NSMutableArray *index=[NSMutableArray array];for(NSDictionary *c in cards){NSMutableArray *row=[NSMutableArray array];for(NSString *name in want){id v=c[name];if([name isEqual:@"open_at"]){NSString *text=[v isKindOfClass:NSString.class]?[[v componentsSeparatedByString:@"T"][0] stringByReplacingOccurrencesOfString:@"-" withString:@""]:@"";v=text.length>=8?@([[text substringToIndex:8] integerValue]):@0;}[row addObject:v?:NSNull.null];}[index addObject:row];}result=cards?index:nil;
    }
    else if([op isEqual:@"projects"]){NSMutableArray *list=[NSMutableArray array];for(id p in [_state[@"projects"] allValues]){if(![self validProject:p]){error=@"INVALID_SAVED_PROJECT";break;}[list addObject:[self summary:p]];}result=error?nil:list;}
    else if([op isEqual:@"loadProject"])result=project;
    else if([op isEqual:@"saveProject"]){id p=a[@"project"];if(![self validProject:p])error=@"INVALID_CREATOR_PROJECT";else if([self isFinishing:p[@"key"]])error=@"CREATOR_FINISH_IN_PROGRESS";else{NSDictionary *old=[self project:p[@"key"]];if(old&&[old[@"updatedAt"] isKindOfClass:NSString.class]&&[p[@"updatedAt"] isKindOfClass:NSString.class]&&[old[@"updatedAt"] compare:p[@"updatedAt"]]==NSOrderedDescending)result=@{@"saved":@NO,@"superseded":@YES};else{NSMutableDictionary *next=[self copyState];next[@"projects"][p[@"key"]]=p;if([self commit:next])result=@{@"saved":@YES,@"storage":@"native",@"revision":ODHash(ODJSON(p))};}}}
    else if([op isEqual:@"deleteProject"]){if(!project)error=@"PROJECT_NOT_FOUND";else if([self isFinishing:key])error=@"CREATOR_FINISH_IN_PROGRESS";else{NSMutableDictionary *next=[self copyState];[next[@"projects"] removeObjectForKey:key];[next[@"versions"] removeObjectForKey:key];[next[@"intents"] removeObjectForKey:key];if([self commit:next])result=@{@"deleted":@YES,@"key":key};}}
    else if([op isEqual:@"patches"]||[op isEqual:@"assets"])result=@[];
    else if([op isEqual:@"settings"])result=_state[@"settings"];
    else if([op isEqual:@"wipeCreatorDocuments"]){
        NSSet *fields=[NSSet setWithArray:@[@"confirm",@"units",@"settings"]];
        BOOL valid=[[NSSet setWithArray:a.allKeys] isSubsetOfSet:fields]&&[a[@"confirm"] isEqual:@"DELETE"];
        for(NSString *flag in @[@"units",@"settings"])if(a[flag]&&(![a[flag] isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)a[flag])!=CFBooleanGetTypeID()))valid=NO;
        if(!valid)error=@"INVALID_CREATOR_WIPE";
        else {BOOL busy=NO;for(NSString *key in _state[@"projects"])if([self isFinishing:key])busy=YES;
            if(busy)error=@"CREATOR_FINISH_IN_PROGRESS";else{NSMutableDictionary *next=[self copyState];
                if([a[@"units"] boolValue]){next[@"projects"]=[NSMutableDictionary dictionary];next[@"versions"]=[NSMutableDictionary dictionary];next[@"intents"]=[NSMutableDictionary dictionary];}
                if([a[@"settings"] boolValue])next[@"settings"]=[NSMutableDictionary dictionary];
                // Keep native definition identity history; this tool never
                // deletes, resets or grants original-game collection state.
                if([self commit:next])result=@{@"ok":@YES,@"units":@([a[@"units"] boolValue]),@"settings":@([a[@"settings"] boolValue])};
            }
        }
    }
    else if([op isEqual:@"settingsSave"]){id value=a[@"settings"]?:a;NSSet *allowed=[NSSet setWithArray:@[@"experience",@"theme",@"textZoom",@"reduceMotion",@"sound",@"haptics",@"compact",@"tourDone",@"language"]];if(!ODObject(value)||![[NSSet setWithArray:[value allKeys]] isSubsetOfSet:allowed]||ODJSON(value).length>8192)error=@"UNSUPPORTED_CREATOR_SETTINGS";else{NSMutableDictionary *next=[self copyState];next[@"settings"]=[value mutableCopy];if([self commit:next])result=next[@"settings"];}}
    else if([@[@"listProjectVersions",@"saveProjectVersion",@"loadProjectVersion",@"deleteProjectVersion",@"restoreProjectVersion"] containsObject:op]){[self versions:op args:a project:project reply:reply];return;}
    else if([op isEqual:@"offlineCreatorPrepare"]){[self prepare:project key:key reply:reply];return;}
    else if([op isEqual:@"offlineCreatorFinish"]){[self finish:project key:key args:a reply:reply];return;}
    else error=@"UNSUPPORTED_OFFLINE_CREATOR_OPERATION";
    [self reply:reply result:result error:error?:(!result?@"CREATOR_OPERATION_FAILED":nil)];
}
- (NSArray *)publicVersions:(NSArray *)rows {
    NSMutableArray *out=[NSMutableArray array];for(NSDictionary *r in rows)[out addObject:@{@"versionKey":r[@"versionKey"],@"label":r[@"label"],@"createdAt":r[@"createdAt"],@"bytes":r[@"bytes"]}];return out;
}
- (NSDictionary *)versionRow:(NSDictionary *)project label:(NSString *)label safety:(BOOL)safety {
    NSData *bytes=ODJSON(project);return @{@"versionKey":NSUUID.UUID.UUIDString,@"label":label,@"createdAt":ODNow(),@"bytes":@(bytes.length),@"revision":ODHash(bytes),@"project":project,@"safety":@(safety)};
}
- (NSArray *)keepVersion:(NSDictionary *)row old:(NSArray *)old {
    NSMutableArray *rows=[NSMutableArray arrayWithObject:row];NSUInteger size=[row[@"bytes"] unsignedIntegerValue];
    for(NSDictionary *r in old){if([row[@"safety"] boolValue]&&[r[@"safety"] boolValue])continue;if(rows.count>=10||size+[r[@"bytes"] unsignedIntegerValue]>40*1024*1024)break;[rows addObject:r];size+=[r[@"bytes"] unsignedIntegerValue];}return rows;
}
- (void)versions:(NSString *)op args:(NSDictionary *)a project:(NSDictionary *)project reply:(ODCreatorReply)reply {
    NSString *key=a[@"key"];if(!project||![self validProject:project]){[self reply:reply result:nil error:@"PROJECT_NOT_FOUND"];return;}
    NSString *revision=ODHash(ODJSON(project));NSArray *rows=_state[@"versions"][key]?:@[];
    if(!ODArray(rows)||rows.count>10){[self reply:reply result:nil error:@"INVALID_SAVED_VERSIONS"];return;}
    for(NSDictionary *r in rows)if(!ODObject(r)||![self validProject:r[@"project"]]||![r[@"project"][@"key"] isEqual:key]||!ODName(r[@"versionKey"])||![r[@"label"] isKindOfClass:NSString.class]||![r[@"createdAt"] isKindOfClass:NSString.class]||!ODInteger(r[@"bytes"])||[r[@"bytes"] unsignedIntegerValue]!=ODJSON(r[@"project"]).length||![ODHash(ODJSON(r[@"project"])) isEqual:r[@"revision"]]){[self reply:reply result:nil error:@"INVALID_SAVED_VERSIONS"];return;}
    if([op isEqual:@"listProjectVersions"]){[self reply:reply result:@{@"versions":[self publicVersions:rows],@"currentRevision":revision} error:nil];return;}
    BOOL restoring=[op isEqual:@"restoreProjectVersion"];
    if((restoring||a[@"expectedCurrentRevision"])&&![a[@"expectedCurrentRevision"] isEqual:revision]){[self reply:reply result:nil error:@"PROJECT_REVISION_CONFLICT"];return;}
    NSDictionary *selected=nil;for(NSDictionary *r in rows)if([r[@"versionKey"] isEqual:a[@"versionKey"]])selected=r;
    if([op isEqual:@"loadProjectVersion"]){[self reply:reply result:selected[@"project"] error:selected?nil:@"VERSION_NOT_FOUND"];return;}
    if([self isFinishing:key]){[self reply:reply result:nil error:@"CREATOR_FINISH_IN_PROGRESS"];return;}
    NSMutableDictionary *next=[self copyState];id result=nil;
    if([op isEqual:@"saveProjectVersion"]){NSString *label=[a[@"label"] isKindOfClass:NSString.class]?[a[@"label"] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]:nil;
        if(!label.length||label.length>80||[label rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location!=NSNotFound){[self reply:reply result:nil error:@"INVALID_VERSION_LABEL"];return;}
        NSDictionary *row=[self versionRow:project label:label safety:NO];next[@"versions"][key]=[self keepVersion:row old:rows];result=@{@"saved":@YES,@"versionKey":row[@"versionKey"],@"versions":[self publicVersions:next[@"versions"][key]],@"currentRevision":revision};
    }else if([op isEqual:@"deleteProjectVersion"]){if(!selected){[self reply:reply result:nil error:@"VERSION_NOT_FOUND"];return;}NSMutableArray *kept=[rows mutableCopy];[kept removeObject:selected];next[@"versions"][key]=kept;result=@{@"deleted":@YES,@"versions":[self publicVersions:kept],@"currentRevision":revision};
    }else if(restoring){if(!selected){[self reply:reply result:nil error:@"VERSION_NOT_FOUND"];return;}NSMutableDictionary *restored=[selected[@"project"] mutableCopy];restored[@"updatedAt"]=ODAfter(project[@"updatedAt"]);next[@"projects"][key]=restored;next[@"versions"][key]=[self keepVersion:[self versionRow:project label:@"Before restoring an earlier version" safety:YES] old:rows];result=@{@"saved":@YES,@"project":restored,@"versions":[self publicVersions:next[@"versions"][key]],@"currentRevision":ODHash(ODJSON(restored))};}
    BOOL saved=result&&[self commit:next];[self reply:reply result:saved?result:nil error:saved?nil:@"CREATOR_STORAGE_WRITE_FAILED"];
}
- (NSDictionary *)preparePayload:(NSDictionary *)intent project:(NSDictionary *)project {
    NSMutableDictionary *payload=[@{@"snapshot":intent[@"snapshot"],@"project":project,@"context":intent[@"context"],@"unchangedTables":intent[@"unchangedTables"]?:@[]} mutableCopy];
    if([intent[@"fullBundle"] isEqual:@YES])payload[@"fullBundle"]=@YES;return payload;
}
- (void)prepare:(NSDictionary *)project key:(NSString *)key reply:(ODCreatorReply)reply {
    BOOL full=ODFullBundleProject(project);
    if(!project||![self validProject:project]||ODAwakenProject(project)||(full&&!_fullValidator)||(!full&&ODUnsupported(project))){[self reply:reply result:nil error:@"UNSUPPORTED_CREATOR_PROJECT"];return;}
    if([self isFinishing:key]){[self reply:reply result:nil error:@"CREATOR_FINISH_IN_PROGRESS"];return;}
    NSString *hash=ODHash(ODJSON(project));NSDictionary *intent=_state[@"intents"][key];
    if(ODObject(intent)&&[intent[@"hash"] isEqual:hash]&&[intent[@"context"][@"contentId"] isEqual:_content]&&[intent[@"fullBundle"] isEqual:@(full)]){[self reply:reply result:[self preparePayload:intent project:project] error:nil];return;}
    NSArray *proof=full?@[]:[self proofForProject:project];if(!proof){[self reply:reply result:nil error:@"UNSUPPORTED_MODIFIED_TABLE"];return;}
    NSString *definitionID=_state[@"definitionIDs"][key]?:project[@"patch"][@"uuid"]?:key;
    if(!ODName(definitionID)){[self reply:reply result:nil error:@"INVALID_DEFINITION_ID"];return;}
    [self executeCreator:@"creator.library" command:nil arguments:@{} reply:^(id library,NSError *failure){
        if(failure||!ODObject(library)){[self reply:reply result:nil error:failure.localizedDescription?:@"CREATOR_LIBRARY_FAILED"];return;}
        NSDictionary *existing=nil;for(NSDictionary *d in library[@"definitions"])if([d[@"definition_id"] isEqual:definitionID])existing=d;
        if(existing){[self executeCreator:@"creator.export" command:nil arguments:@{@"definition_id":definitionID} reply:^(id document,NSError *error){dispatch_async(self->_queue,^{if(error){[self reply:reply result:nil error:error.localizedDescription];return;}[self preparedProject:project key:key hash:hash definitionID:definitionID previous:document proof:proof fullBundle:full reply:reply];});}];}
        else dispatch_async(self->_queue,^{[self preparedProject:project key:key hash:hash definitionID:definitionID previous:nil proof:proof fullBundle:full reply:reply];});
    }];
}
- (void)preparedProject:(NSDictionary *)project key:(NSString *)key hash:(NSString *)hash definitionID:(NSString *)definitionID previous:(NSDictionary *)previous proof:(NSArray *)proof fullBundle:(BOOL)full reply:(ODCreatorReply)reply {
    if(![self reloadState]){[self reply:reply result:nil error:_failure];return;}
    if(![ODHash(ODJSON([self project:key])) isEqual:hash]){[self reply:reply result:nil error:@"PROJECT_REVISION_CONFLICT"];return;}
    NSDictionary *existing=_state[@"intents"][key];if(ODObject(existing)&&[existing[@"hash"] isEqual:hash]&&[existing[@"fullBundle"] isEqual:@(full)]){[self reply:reply result:[self preparePayload:existing project:project] error:nil];return;}
    NSMutableDictionary *card=[project[@"tables"][@"cards"][0] mutableCopy];[card addEntriesFromDictionary:project[@"cardOverrides"]];
    for(NSString *field in @[@"id",@"rarity",@"lv_max"])if(!ODInteger(card[field])){[self reply:reply result:nil error:@"INVALID_OFFLINE_CARD_SETTINGS"];return;}
    if(!ODInteger(project[@"source"][@"cardId"])||[project[@"source"][@"cardId"] longLongValue]<1){[self reply:reply result:nil error:@"INVALID_SOURCE_CARD"];return;}
    NSInteger rarity=[card[@"rarity"] integerValue],cap=[card[@"lv_max"] integerValue];NSString *kind=rarity==4?@"UR":rarity==5?(cap==180?@"SLR":cap==200?@"GR":@"LR"):nil;
    long long version=[previous[@"version"] longLongValue];if(!kind||version<0||version>=9007199254740991LL){[self reply:reply result:nil error:@"UNSUPPORTED_CREATOR_RARITY"];return;}
    NSMutableDictionary *context=[@{@"contentId":_content,@"sourceDatabase":_game,@"definitionId":definitionID,@"version":@(version+1),@"rarity":kind} mutableCopy];
    if(ODObject(previous[@"creator"])){context[@"creatorId"]=previous[@"creator"][@"id"];context[@"creatorName"]=previous[@"creator"][@"name"];}
    if(previous[@"stat_policy"])context[@"statPolicy"]=previous[@"stat_policy"];
    if(full){long long stamp=(long long)llround(NSDate.date.timeIntervalSince1970*1000.0);if(stamp<0||stamp>253402300799000LL){[self reply:reply result:nil error:@"FULL_BUNDLE_NATIVE_CONTEXT_INVALID"];return;}context[@"materializationUTC"]=@(stamp);}
    NSMutableDictionary *next=[self copyState];next[@"definitionIDs"][key]=definitionID;
    NSDictionary *intent=@{@"snapshot":NSUUID.UUID.UUIDString,@"command":NSUUID.UUID.UUIDString,@"hash":hash,@"context":context,@"unchangedTables":proof,@"fullBundle":@(full)};next[@"intents"][key]=intent;
    BOOL saved=[self commit:next];[self reply:reply result:saved?[self preparePayload:intent project:project]:nil error:saved?nil:@"CREATOR_STORAGE_WRITE_FAILED"];
}
- (NSDictionary *)expectedDefinition:(NSDictionary *)project context:(NSDictionary *)context proof:(NSArray *)proof {
    if(ODUnsupported(project)||![self validProject:project])return nil;
    NSMutableDictionary *card=[project[@"tables"][@"cards"][0] mutableCopy];[card addEntriesFromDictionary:project[@"cardOverrides"]];
    for(NSString *field in @[@"id",@"rarity",@"lv_max"])if(!ODInteger(card[field]))return nil;
    if(![card[@"id"] isEqual:project[@"source"][@"cardId"]])return nil;
    NSMutableDictionary *tables=[NSMutableDictionary dictionary];for(NSString *table in project[@"tables"]){if([table isEqual:@"cards"])continue;id rows=project[@"tables"][table];if(!ODArray(rows))return nil;if(![rows count])continue;if([ODProjectionTables() containsObject:table])tables[table]=rows;else if(![proof containsObject:table])return nil;}
    NSMutableDictionary *definition=[@{@"format":@"offline-dokkan-definition",@"schema_version":@1,@"definition_id":context[@"definitionId"],@"version":context[@"version"],@"source":@{@"content_id":_content,@"master_id":project[@"source"][@"cardId"]},@"rarity":context[@"rarity"],@"fully_awakened":@YES,@"card":card,@"tables":tables} mutableCopy];
    if([card[@"lv_max"] integerValue]>150)definition[@"progression_policy"]=@"creator-lr-extended-v1";
    id policy=context[@"statPolicy"]?:project[@"statPolicy"];if(policy){if(![@[@"master-coefficient-linear-floor-v1",@"creator-cap-normalized-v1"] containsObject:policy]||(context[@"statPolicy"]&&project[@"statPolicy"]&&![context[@"statPolicy"] isEqual:project[@"statPolicy"]]))return nil;definition[@"stat_policy"]=policy;}
    if(context[@"creatorId"]||context[@"creatorName"])definition[@"creator"]=@{@"id":context[@"creatorId"],@"name":context[@"creatorName"]};
    return definition;
}
- (NSDictionary *)capturePacket:(NSDictionary *)record scope:(NSString *)scope {
    if(!ODObject(record)||![record[@"project_base64"] isKindOfClass:NSString.class]||![record[@"definition_base64"] isKindOfClass:NSString.class])return nil;
    NSDictionary *binding=record[@"binding"];NSData *project=[[NSData alloc] initWithBase64EncodedString:record[@"project_base64"]?:@"" options:0],*definition=[[NSData alloc] initWithBase64EncodedString:record[@"definition_base64"]?:@"" options:0];
    if(!ODObject(binding)||![binding[@"format"] isEqual:@"od-accepted-creator-project-v1"]||![binding[@"accepted"] isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)binding[@"accepted"])!=CFBooleanGetTypeID()||![binding[@"accepted"] boolValue]||![binding[@"content_id"] isEqual:_content]||![binding[@"save_scope"] isEqual:scope]||!ODName(binding[@"definition_id"])||!ODInteger(binding[@"version"])||CFGetTypeID((__bridge CFTypeRef)binding[@"version"])==CFBooleanGetTypeID()||[binding[@"version"] longLongValue]<1||!ODInteger(binding[@"instance_id"])||CFGetTypeID((__bridge CFTypeRef)binding[@"instance_id"])==CFBooleanGetTypeID()||[binding[@"instance_id"] longLongValue]<1||!project.length||project.length>ODProjectLimit||!definition.length||definition.length>16*1024*1024||![binding[@"project_sha256"] isEqual:ODHash(project)]||![binding[@"definition_sha256"] isEqual:ODHash(definition)])return nil;
    id document=[NSJSONSerialization JSONObjectWithData:definition options:0 error:nil];id design=[NSJSONSerialization JSONObjectWithData:project options:0 error:nil];
    if(![self validProject:design]||!ODObject(document)||![document[@"definition_id"] isEqual:binding[@"definition_id"]]||![document[@"version"] isEqual:binding[@"version"]]||!ODObject(document[@"source"])||![document[@"source"][@"content_id"] isEqual:_content])return nil;
    return @{@"binding":binding,@"project_bytes":project,@"definition_bytes":definition};
}
- (BOOL)validFinishReceipt:(id)receipt definition:(NSDictionary *)expected {
    return ODObject(receipt)&&ODInteger(receipt[@"instance_id"])&&[receipt[@"instance_id"] longLongValue]>0&&CFGetTypeID((__bridge CFTypeRef)receipt[@"instance_id"])!=CFBooleanGetTypeID()&&[receipt[@"definition_id"] isEqual:expected[@"definition_id"]]&&[receipt[@"version"] isEqual:expected[@"version"]]&&[receipt[@"available"] isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)receipt[@"available"])==CFBooleanGetTypeID()&&[receipt[@"newly_owned"] isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)receipt[@"newly_owned"])==CFBooleanGetTypeID();
}
- (void)promoteCapture:(NSDictionary *)pending receipt:(NSDictionary *)finished reply:(ODCreatorReply)reply {
    if(!ODObject(pending)||![pending[@"project_base64"] isKindOfClass:NSString.class]||![pending[@"expected_definition_base64"] isKindOfClass:NSString.class]){[self reply:reply result:nil error:@"INVALID_ACCEPTED_CREATOR_CAPTURE"];return;}
    NSString *scope=pending[@"save_scope"],*command=pending[@"command"];NSData *project=[[NSData alloc] initWithBase64EncodedString:pending[@"project_base64"]?:@"" options:0],*expectedBytes=[[NSData alloc] initWithBase64EncodedString:pending[@"expected_definition_base64"]?:@"" options:0];
    id expected=expectedBytes?[NSJSONSerialization JSONObjectWithData:expectedBytes options:0 error:nil]:nil;
    if(![pending[@"format"] isEqual:@"od-pending-creator-project-v1"]||![pending[@"content_id"] isEqual:_content]||!ODName(command)||!ODName(scope)||[scope length]!=64||(_originalClientMode&&![_originalSaveScope isEqual:scope])||!project.length||project.length>ODProjectLimit||![pending[@"project_sha256"] isEqual:ODHash(project)]||![pending[@"expected_definition_sha256"] isEqual:ODHash(expectedBytes)]||!ODObject(expected)||![self validFinishReceipt:finished definition:expected]){[self reply:reply result:nil error:@"INVALID_ACCEPTED_CREATOR_CAPTURE"];return;}
    [_core acceptedCreatorDefinitionForProfile:@"local-player" definitionID:expected[@"definition_id"] version:[expected[@"version"] longLongValue] expectedSaveScopeSHA256:scope lease:_originalLease reply:^(id raw,NSError *failure){dispatch_async(self->_queue,^{
        NSData *bytes=ODObject(raw)?raw[@"definition_bytes"]:nil;id registered=[bytes isKindOfClass:NSData.class]?[NSJSONSerialization JSONObjectWithData:bytes options:0 error:nil]:nil;
        if(failure||!ODObject(raw)||![bytes isKindOfClass:NSData.class]||!bytes.length||![registered isEqual:expected]||![raw[@"content_id"] isEqual:self->_content]||![raw[@"save_scope_sha256"] isEqual:scope]||![raw[@"profile_id"] isEqual:@"local-player"]||![raw[@"definition_id"] isEqual:expected[@"definition_id"]]||![raw[@"version"] isEqual:expected[@"version"]]||![raw[@"definition_sha256"] isEqual:ODHash(bytes)]){[self reply:reply result:nil error:@"CREATOR_ACCEPTED_DEFINITION_UNCONFIRMED"];return;}
        NSDictionary *binding=@{@"format":@"od-accepted-creator-project-v1",@"content_id":self->_content,@"save_scope":scope,@"definition_id":expected[@"definition_id"],@"version":expected[@"version"],@"project_sha256":pending[@"project_sha256"],@"definition_sha256":raw[@"definition_sha256"],@"instance_id":finished[@"instance_id"],@"accepted":@YES};
        NSDictionary *record=@{@"binding":binding,@"project_base64":pending[@"project_base64"],@"definition_base64":[bytes base64EncodedStringWithOptions:0]};
        int accepted=ODCaptureDirectory(self->_directory,"accepted");BOOL saved=accepted>=0&&ODCaptureWrite(accepted,ODCaptureName(expected[@"definition_id"],expected[@"version"]),record);if(accepted>=0)close(accepted);
        if(!saved){[self reply:reply result:nil error:@"CREATOR_ACCEPTED_CAPTURE_WRITE_FAILED_RETRY_SAME_FINISH"];return;}
        // A durable immutable accepted packet exists before pending bytes or
        // their local receipt can be removed. Historical accepted versions stay.
        NSString *name=[ODHash([command dataUsingEncoding:NSUTF8StringEncoding]) stringByAppendingString:@".json"];
        int dir=ODCaptureDirectory(self->_directory,"pending");if(dir>=0){unlinkat(dir,name.UTF8String,0);(void)fsync(dir);close(dir);}
        int receipts=ODCaptureDirectory(self->_directory,"receipts");if(receipts>=0){unlinkat(receipts,name.UTF8String,0);(void)fsync(receipts);close(receipts);}
        [self reply:reply result:[self capturePacket:record scope:scope] error:nil];
    });}];
}
- (void)finish:(NSDictionary *)project key:(NSString *)key args:(NSDictionary *)a reply:(ODCreatorReply)reply {
    NSDictionary *intent=ODName(key)?_state[@"intents"][key]:nil;id definition=a[@"definition"];
    if(!project||!ODObject(intent)||![intent[@"snapshot"] isEqual:a[@"snapshot"]]||![intent[@"hash"] isEqual:ODHash(ODJSON(project))]||![intent[@"context"][@"contentId"] isEqual:_content]){[self reply:reply result:nil error:@"PROJECT_REVISION_CONFLICT"];return;}
    if([self isFinishing:key]){[self reply:reply result:nil error:@"CREATOR_FINISH_IN_PROGRESS"];return;}
    BOOL full=[intent[@"fullBundle"] isEqual:@YES];
    NSDictionary *expected=full?nil:[self expectedDefinition:project context:intent[@"context"] proof:intent[@"unchangedTables"]];
    if(full){if(!_fullValidator){[self reply:reply result:nil error:@"UNSUPPORTED_CREATOR_PROJECT"];return;}if(ODObject(definition)&&definition[@"full_bundle"]){[self reply:reply result:nil error:@"FULL_BUNDLE_PAGE_DESCRIPTOR_REJECTED"];return;}}
    else if(!expected||!ODObject(definition)||![expected isEqual:definition]){[self reply:reply result:nil error:@"CREATOR_PROJECTION_MISMATCH"];return;}
    NSData *projectBytes=ODJSON(project);__block NSData *definitionBytes=ODJSON(expected);__block NSDictionary *resolved=expected;
    if(definitionBytes.length>16*1024*1024){[self reply:reply result:nil error:@"OFFLINE_DEFINITION_TOO_LARGE"];return;}
    if(!full&&intent[@"definition"]&&![intent[@"definition"] isEqual:definition]){[self reply:reply result:nil error:@"CREATOR_INTENT_CONFLICT"];return;}
    NSString *originalCommand=intent[@"command"],*command=[originalCommand stringByAppendingString:@":collection-v1"];
    [ODFinishingProjects() addObject:[self finishKey:key]];
    [_core originalCreatorProjectionAdmissionForProfile:@"local-player" reply:^(id admission,NSError *failure){dispatch_async(self->_queue,^{
        NSString *scope=ODObject(admission)?admission[@"save_scope_sha256"]:nil;
        if(failure||![admission[@"content_id"] isEqual:self->_content]||!ODName(scope)||scope.length!=64||(self->_originalClientMode&&![scope isEqual:self->_originalSaveScope])||![self reloadState]||![self->_state[@"intents"][key][@"command"] isEqual:originalCommand]||![intent[@"hash"] isEqual:ODHash(ODJSON([self project:key]))]) {
            [ODFinishingProjects() removeObject:[self finishKey:key]];[self reply:reply result:nil error:@"CREATOR_CAPTURE_SCOPE_OR_REVISION_CHANGED"];return;
        }
        NSData *bundleBytes=nil;
        if(full){
            if(![self->_fullValidator.saveScope isEqual:scope]||![self->_fullValidator.profileID isEqual:@"local-player"]||![self->_fullValidator.contentID isEqual:self->_content]){[ODFinishingProjects() removeObject:[self finishKey:key]];[self reply:reply result:nil error:@"FULL_BUNDLE_SAVE_SCOPE_MISMATCH"];return;}
            NSError *validationError=nil;NSDictionary *validated=[self->_fullValidator validateProjectBytes:projectBytes context:intent[@"context"] error:&validationError];
            bundleBytes=[validated[@"full_bundle_bytes"] isKindOfClass:NSData.class]?validated[@"full_bundle_bytes"]:nil;resolved=ODObject(validated[@"definition"])?validated[@"definition"]:nil;
            if(!resolved||!bundleBytes.length){[ODFinishingProjects() removeObject:[self finishKey:key]];[self reply:reply result:nil error:validationError.localizedDescription?:@"FULL_BUNDLE_FORGE_VALIDATION_FAILED"];return;}
            NSDictionary *stored=ODObject(intent[@"definition"])?intent[@"definition"]:nil;
            if(stored){
                BOOL same=[stored[@"definition_id"] isEqual:resolved[@"definition_id"]]&&[stored[@"version"] isEqual:resolved[@"version"]]&&[stored[@"full_bundle"][@"full_bundle_sha256"] isEqual:resolved[@"full_bundle"][@"full_bundle_sha256"]];
                if(!same){[ODFinishingProjects() removeObject:[self finishKey:key]];[self reply:reply result:nil error:@"CREATOR_INTENT_CONFLICT"];return;}
                resolved=stored;
            }
            definitionBytes=ODJSON(resolved);if(!definitionBytes||definitionBytes.length>16*1024*1024){[ODFinishingProjects() removeObject:[self finishKey:key]];[self reply:reply result:nil error:definitionBytes?@"OFFLINE_DEFINITION_TOO_LARGE":@"FULL_BUNDLE_MATERIALIZATION_FAILED"];return;}
        }
        NSDictionary *pending=@{@"format":@"od-pending-creator-project-v1",@"content_id":self->_content,@"save_scope":scope,@"definition_id":resolved[@"definition_id"],@"version":resolved[@"version"],@"command":command,@"creator_key":key,@"project_sha256":ODHash(projectBytes),@"expected_definition_sha256":ODHash(definitionBytes),@"project_base64":[projectBytes base64EncodedStringWithOptions:0],@"expected_definition_base64":[definitionBytes base64EncodedStringWithOptions:0]};
        NSString *name=[ODHash([command dataUsingEncoding:NSUTF8StringEncoding]) stringByAppendingString:@".json"];
        int accepted=ODCaptureDirectory(self->_directory,"accepted");NSDictionary *record=accepted>=0?ODCaptureRead(accepted,ODCaptureName(resolved[@"definition_id"],resolved[@"version"])):nil;if(accepted>=0)close(accepted);
        if(record){NSDictionary *packet=[self capturePacket:record scope:scope];
            id registered=packet?[NSJSONSerialization JSONObjectWithData:packet[@"definition_bytes"] options:0 error:nil]:nil;
            if(!packet||![registered isEqual:resolved]||![packet[@"binding"][@"project_sha256"] isEqual:pending[@"project_sha256"]]){[ODFinishingProjects() removeObject:[self finishKey:key]];[self reply:reply result:nil error:@"CREATOR_ACCEPTED_VERSION_CONFLICT"];return;}
            // The immutable native receipt survived even if the editable-state
            // receipt commit did not. Repair that cache without executing a
            // mutation or granting another owned instance (even after the Core
            // command's bounded full-result cache expires).
            NSDictionary *result=intent[@"result"];
            if(!ODInteger(result[@"instanceId"])||![result[@"instanceId"] isEqual:packet[@"binding"][@"instance_id"]]){
                result=@{@"imported":@YES,@"definitionId":resolved[@"definition_id"],@"version":resolved[@"version"],@"instanceId":packet[@"binding"][@"instance_id"],@"available":@NO,@"newlyOwned":@NO};
                NSMutableDictionary *repair=[self copyState];repair[@"intents"][key][@"result"]=result;
                if(![self commit:repair]){[ODFinishingProjects() removeObject:[self finishKey:key]];[self reply:reply result:nil error:@"CREATOR_RECEIPT_WRITE_FAILED_RETRY_SAME_FINISH"];return;}
            }
            [ODFinishingProjects() removeObject:[self finishKey:key]];[self liveImportResult:result reply:reply];return;
        }
        int directory=ODCaptureDirectory(self->_directory,"pending");BOOL captured=directory>=0&&ODCaptureWrite(directory,name,pending);if(directory>=0)close(directory);
        NSMutableDictionary *next=[self copyState];next[@"intents"][key][@"definition"]=resolved;
        if(!captured||![self commit:next]){[ODFinishingProjects() removeObject:[self finishKey:key]];[self reply:reply result:nil error:@"CREATOR_PENDING_CAPTURE_WRITE_FAILED"];return;}
        void (^acceptFinish)(id,NSError *)=^(id finished,NSError *error){dispatch_async(self->_queue,^{
            if(error||![self validFinishReceipt:finished definition:resolved]){[ODFinishingProjects() removeObject:[self finishKey:key]];[self reply:reply result:nil error:error.localizedDescription?:@"CREATOR_COLLECTION_REPLY_INVALID_RETRY_SAME_FINISH"];return;}
            // Persist the exact trusted Core callback before fetching canonical
            // definition bytes. An interrupted unknown request is never replayed
            // by recovery; only an explicit same-intent Finish may execute it.
            int receipts=ODCaptureDirectory(self->_directory,"receipts");BOOL receiptSaved=receipts>=0&&ODCaptureWrite(receipts,name,@{@"pending_sha256":ODHash(ODJSON(pending)),@"finish_receipt":finished});if(receipts>=0)close(receipts);
            if(!receiptSaved){[ODFinishingProjects() removeObject:[self finishKey:key]];[self reply:reply result:nil error:@"CREATOR_RECEIPT_CAPTURE_WRITE_FAILED_RETRY_SAME_FINISH"];return;}
            [self promoteCapture:pending receipt:finished reply:^(id packet,NSString *captureError){dispatch_async(self->_queue,^{
                [ODFinishingProjects() removeObject:[self finishKey:key]];
                if(captureError||!packet){[self reply:reply result:nil error:captureError?:@"CREATOR_CAPTURE_FAILED"];return;}
                if(![self reloadState]||![self->_state[@"intents"][key][@"command"] isEqual:originalCommand]){[self reply:reply result:nil error:@"CREATOR_RECEIPT_CONFLICT"];return;}
                NSDictionary *result=@{@"imported":@YES,@"definitionId":resolved[@"definition_id"],@"version":resolved[@"version"],@"instanceId":finished[@"instance_id"],@"available":finished[@"available"],@"newlyOwned":finished[@"newly_owned"]};
                NSMutableDictionary *saved=[self copyState];saved[@"intents"][key][@"result"]=result;
                if(![self commit:saved]){[self reply:reply result:nil error:@"CREATOR_RECEIPT_WRITE_FAILED_RETRY_SAME_FINISH"];return;}[self liveImportResult:result reply:reply];
            });}];
        });};
        if(bundleBytes)[self->_core creatorFinishValidatedBundleForProfile:@"local-player" command:command definition:resolved bundleBytes:bundleBytes expectedSaveScopeSHA256:scope lease:self->_originalClientMode?self->_originalLease:nil reply:acceptFinish];
        else [self executeCreator:@"creator.finish" command:command arguments:@{@"definition":resolved} reply:acceptFinish];
    });}];
}
- (void)recoverAcceptedNames:(NSArray *)names index:(NSUInteger)index scope:(NSString *)scope recovered:(NSUInteger)recovered unresolved:(NSUInteger)unresolved reply:(ODCreatorReply)reply {
    if(index>=names.count){[self reply:reply result:@{@"recovered":@(recovered),@"unresolved":@(unresolved),@"save_scope":scope} error:nil];return;}
    NSString *name=names[index];int directory=ODCaptureDirectory(_directory,"pending"),receipts=ODCaptureDirectory(_directory,"receipts");NSDictionary *pending=directory>=0?ODCaptureRead(directory,name):nil,*receipt=receipts>=0?ODCaptureRead(receipts,name):nil;if(directory>=0)close(directory);if(receipts>=0)close(receipts);
    if(!pending||!ODName(pending[@"command"])||![pending[@"save_scope"] isEqual:scope]||![pending[@"content_id"] isEqual:_content]||![name isEqual:[ODHash([pending[@"command"] dataUsingEncoding:NSUTF8StringEncoding]) stringByAppendingString:@".json"]]){[self reply:reply result:nil error:@"CREATOR_PENDING_CAPTURE_INVALID"];return;}
    if(!receipt){
        NSData *expected=[pending[@"expected_definition_base64"] isKindOfClass:NSString.class]?[[NSData alloc] initWithBase64EncodedString:pending[@"expected_definition_base64"] options:0]:nil;
        if(!expected.length||![pending[@"expected_definition_sha256"] isEqual:ODHash(expected)]){[self reply:reply result:nil error:@"CREATOR_PENDING_CAPTURE_INVALID"];return;}
        // Read ONLY the Core's exact retained command receipt. A missing/pruned
        // command stays pending until explicit same-intent retry; recovery
        // never executes an old Finish or creates an owned card.
        [_core creatorFinishReceiptForProfile:@"local-player" command:pending[@"command"] expectedDefinitionBytes:expected expectedSaveScopeSHA256:scope lease:_originalLease reply:^(id found,NSError *error){dispatch_async(self->_queue,^{
            if(error){if([error.localizedDescription isEqual:@"CREATOR_FINISH_RECEIPT_UNAVAILABLE"]){[self recoverAcceptedNames:names index:index+1 scope:scope recovered:recovered unresolved:unresolved+1 reply:reply];return;}[self reply:reply result:nil error:@"CREATOR_RECEIPT_LOOKUP_UNCONFIRMED"];return;}
            if(!ODObject(found)){[self reply:reply result:nil error:@"CREATOR_RECEIPT_LOOKUP_UNCONFIRMED"];return;}
            int dir=ODCaptureDirectory(self->_directory,"receipts");BOOL saved=dir>=0&&ODCaptureWrite(dir,name,@{@"pending_sha256":ODHash(ODJSON(pending)),@"finish_receipt":found});if(dir>=0)close(dir);
            if(!saved){[self reply:reply result:nil error:@"CREATOR_RECEIPT_CAPTURE_WRITE_FAILED"];return;}
            [self recoverAcceptedNames:names index:index scope:scope recovered:recovered unresolved:unresolved reply:reply];
        });}];return;
    }
    if(![receipt[@"pending_sha256"] isEqual:ODHash(ODJSON(pending))]){[self reply:reply result:nil error:@"CREATOR_RECEIPT_CAPTURE_CONFLICT"];return;}
    [self promoteCapture:pending receipt:receipt[@"finish_receipt"] reply:^(id result,NSString *error){(void)result;dispatch_async(self->_queue,^{if(error){[self reply:reply result:nil error:error];return;}[self recoverAcceptedNames:names index:index+1 scope:scope recovered:recovered+1 unresolved:unresolved reply:reply];});}];
}
- (void)recoverAcceptedProjectsWithReply:(ODCreatorReply)reply {
    dispatch_async(_queue,^{
        if(![self open]){[self reply:reply result:nil error:self->_failure];return;}
        [_core originalCreatorProjectionAdmissionForProfile:@"local-player" reply:^(id admission,NSError *error){dispatch_async(self->_queue,^{
            NSString *scope=ODObject(admission)?admission[@"save_scope_sha256"]:nil;
            if(error||!ODName(scope)||scope.length!=64||![admission[@"content_id"] isEqual:self->_content]||(self->_originalClientMode&&![scope isEqual:self->_originalSaveScope])){[self reply:reply result:nil error:@"CREATOR_CAPTURE_SCOPE_CHANGED"];return;}
            int directory=ODCaptureDirectory(self->_directory,"pending");NSArray *names=directory>=0?ODCaptureNames(directory):nil;if(directory>=0)close(directory);
            if(!names){[self reply:reply result:nil error:@"CREATOR_CAPTURE_STORAGE_UNAVAILABLE"];return;}
            [self recoverAcceptedNames:names index:0 scope:scope recovered:0 unresolved:0 reply:reply];
        });}];
    });
}
- (void)acceptedProjectForDefinitionID:(NSString *)definitionID version:(NSNumber *)version reply:(ODCreatorReply)reply {
    if(!ODName(definitionID)||!ODInteger(version)||CFGetTypeID((__bridge CFTypeRef)version)==CFBooleanGetTypeID()||[version longLongValue]<1){[self reply:reply result:nil error:@"INVALID_ACCEPTED_CREATOR_REFERENCE"];return;}
    NSString *identifier=[definitionID copy];NSNumber *number=[version copy];
    [self recoverAcceptedProjectsWithReply:^(id recovered,NSString *error){if(error){reply(nil,error);return;}dispatch_async(self->_queue,^{
        (void)recovered;int directory=ODCaptureDirectory(self->_directory,"accepted");NSDictionary *record=directory>=0?ODCaptureRead(directory,ODCaptureName(identifier,number)):nil;if(directory>=0)close(directory);
        NSString *scope=recovered[@"save_scope"];NSDictionary *packet=[self capturePacket:record scope:scope];
        if(!packet){[self reply:reply result:nil error:@"ACCEPTED_CREATOR_PROJECT_UNAVAILABLE"];return;}
        NSDictionary *document=[NSJSONSerialization JSONObjectWithData:packet[@"definition_bytes"] options:0 error:nil];
        if(!document[@"full_bundle"]){[self reply:reply result:packet error:nil];return;}
        NSDictionary *binding=packet[@"binding"];
        [self->_core acceptedCreatorFullBundleForProfile:@"local-player" definitionID:identifier
            version:number.longLongValue instanceID:[binding[@"instance_id"] longLongValue]
            expectedSaveScopeSHA256:scope lease:self->_originalLease reply:^(id full,NSError *failure){dispatch_async(self->_queue,^{
                NSData *bytes=ODObject(full)&&[full[@"full_bundle_bytes"] isKindOfClass:NSData.class]?full[@"full_bundle_bytes"]:nil;
                NSData *registered=ODObject(full)&&[full[@"definition_bytes"] isKindOfClass:NSData.class]?full[@"definition_bytes"]:nil;
                NSDictionary *proof=ODObject(full)&&ODObject(full[@"full_bundle_receipt"])?full[@"full_bundle_receipt"]:nil;
                NSDictionary *descriptor=ODObject(document[@"full_bundle"])?document[@"full_bundle"]:nil;
                if(failure||!bytes.length||bytes.length>64u*1024u*1024u||!registered||![registered isEqualToData:packet[@"definition_bytes"]]||
                   !proof||!descriptor||![full[@"content_id"] isEqual:self->_content]||![full[@"save_scope_sha256"] isEqual:scope]||
                   ![full[@"profile_id"] isEqual:@"local-player"]||![full[@"definition_id"] isEqual:identifier]||![full[@"version"] isEqual:number]||
                   ![full[@"full_bundle_sha256"] isEqual:ODHash(bytes)]||![descriptor[@"full_bundle_sha256"] isEqual:ODHash(bytes)]||
                   ![proof[@"instance_id"] isEqual:binding[@"instance_id"]]||![proof[@"project_sha256"] isEqual:binding[@"project_sha256"]]||
                   ![proof[@"definition_sha256"] isEqual:binding[@"definition_sha256"]]){
                    NSString *code=[failure.localizedDescription isEqual:@"FULL_BUNDLE_PAYLOAD_MISSING_RECOVERY_REQUIRED"]?@"FULL_BUNDLE_PAYLOAD_MISSING_RECOVERY_REQUIRED":@"ACCEPTED_FULL_BUNDLE_UNCONFIRMED";
                    [self reply:reply result:nil error:code];return;
                }
                NSMutableDictionary *complete=[packet mutableCopy];complete[@"full_bundle_bytes"]=bytes;
                complete[@"full_bundle_sha256"]=full[@"full_bundle_sha256"];complete[@"full_bundle_receipt"]=proof;
                [self reply:reply result:[complete copy] error:nil];
            });}];
    });}];
}
- (void)liveImportResult:(NSDictionary *)receipt reply:(ODCreatorReply)reply {
    // Registration and the direct-owned identity are durable; collection
    // availability/newest state must reflect the live player, including a consumed card.
    [self executeCreator:@"creator.library" command:nil arguments:@{} reply:^(id library,NSError *error){
        if(error||!ODObject(library)){[self reply:reply result:nil error:error.localizedDescription?:@"CREATOR_LIBRARY_REFRESH_FAILED_RETRY_FINISH"];return;}
        [self->_core execute:@"profile.snapshot" profile:@"local-player" command:nil arguments:@{} reply:^(id profile,NSError *failure){
            if(failure||!ODObject(profile)||!ODArray(profile[@"cards"])){[self reply:reply result:nil error:failure.localizedDescription?:@"CREATOR_COLLECTION_REFRESH_FAILED_RETRY_FINISH"];return;}
            BOOL available=NO;
            for(NSDictionary *card in profile[@"cards"])if([card[@"instance_id"] isEqual:receipt[@"instanceId"]]&&[card[@"created_definition"][@"definition_id"] isEqual:receipt[@"definitionId"]])available=YES;
            NSMutableDictionary *result=[receipt mutableCopy];result[@"available"]=@(available);result[@"account"]=@"local-player";result[@"library"]=library;result[@"banner"]=@{@"status":@"not_configured",@"drawable":@NO,@"reason":@"trusted_catalog_allocation_required"};[self reply:reply result:result error:nil];
        }];
    }];
}
- (BOOL)installSavedAccountFullBundleValidationWithCreatorCoreURL:(NSURL *)core sparkingDependenciesURL:(NSURL *)dependencies resourceRoot:(NSURL *)resourceRoot saveScope:(NSString *)scope openAsset:(int (^)(NSString *, NSError **))openAsset error:(NSError **)error {
    NSCharacterSet *invalid=[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet];
    if(!core.isFileURL||!dependencies.isFileURL||!resourceRoot.isFileURL||![scope isKindOfClass:NSString.class]||scope.length!=64||[scope rangeOfCharacterFromSet:invalid].location!=NSNotFound||!openAsset){if(error)*error=[NSError errorWithDomain:@"OfflineDokkanCreator" code:2 userInfo:@{NSLocalizedDescriptionKey:@"FULL_BUNDLE_NATIVE_CONTEXT_INVALID"}];return NO;}
    __block BOOL ok=NO;__block NSError *failure=nil;NSString *pinned=[scope copy];
    dispatch_block_t work=^{
        if(self->_originalClientMode&&![pinned isEqual:self->_originalSaveScope]){failure=[NSError errorWithDomain:@"OfflineDokkanCreator" code:2 userInfo:@{NSLocalizedDescriptionKey:@"FULL_BUNDLE_SAVE_SCOPE_MISMATCH"}];return;}
        NSError *local=nil;ODNativeFullCreatorValidator *validator=[[ODNativeFullCreatorValidator alloc] initWithCreatorCoreURL:core sparkingDependenciesURL:dependencies masterURL:self->_master immutableResourceRoot:resourceRoot contentID:self->_content profileID:@"local-player" saveScope:pinned openAsset:openAsset error:&local];
        if(!validator||![validator.profileID isEqual:@"local-player"]||![validator.contentID isEqual:self->_content]||![validator.saveScope isEqual:pinned]){failure=local?:[NSError errorWithDomain:@"OfflineDokkanCreator" code:2 userInfo:@{NSLocalizedDescriptionKey:@"FULL_BUNDLE_NATIVE_CONTEXT_INVALID"}];return;}
        self->_fullValidator=validator;ok=YES;
    };
    if(dispatch_get_specific(ODCreatorQueueKey))work();else dispatch_sync(_queue,work);
    if(!ok&&error)*error=failure;return ok;
}
@end
