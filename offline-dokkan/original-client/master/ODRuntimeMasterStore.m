#import "ODRuntimeMasterStore.h"
#import "ODRuntimeForgeCompiler.h"
#import <CommonCrypto/CommonDigest.h>
#import <CoreFoundation/CoreFoundation.h>
#include "sqlite3.h"
#include <sys/stat.h>
#include <sys/file.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <math.h>

static NSError *ODRMError(NSString *code){return [NSError errorWithDomain:@"OfflineDokkan.RuntimeMaster" code:1 userInfo:@{NSLocalizedDescriptionKey:code}];}
static BOOL ODRMHex(NSString *s){if(![s isKindOfClass:NSString.class]||s.length!=64)return NO;return [s rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet]].location==NSNotFound;}
static BOOL ODRMName(NSString *s){if(![s isKindOfClass:NSString.class]||!s.length||s.length>100)return NO;return [s rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.:-"] invertedSet]].location==NSNotFound;}
static BOOL ODRMIdent(NSString *s){if(![s isKindOfClass:NSString.class]||!s.length||s.length>100)return NO;NSCharacterSet *start=[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"];return [s rangeOfCharacterFromSet:start].location==0&&[s rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789"] invertedSet]].location==NSNotFound;}
static NSString *ODRMQuote(NSString *s){return ODRMIdent(s)?[NSString stringWithFormat:@"\"%@\"",s]:nil;}
static BOOL ODRMInteger(id v){return [v isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)v)!=CFBooleanGetTypeID()&&isfinite([v doubleValue])&&[v doubleValue]==[v longLongValue]&&fabs([v doubleValue])<=9007199254740991.0;}
static BOOL ODRMBool(id value,BOOL expected){return [value isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)value)==CFBooleanGetTypeID()&&[value boolValue]==expected;}
static BOOL ODRMAwakeningRequested(id value){return value&&value!=NSNull.null&&(![value isKindOfClass:NSNumber.class]||[value boolValue]);}
/* Forge formStructureErrors permits any distinct nonempty UTF-16 key up to
 *200 code units; child forms do not use the definition identifier grammar. */
static BOOL ODRMMemberKey(id value){return [value isKindOfClass:NSString.class]&&[value length]>0&&[value length]<=200;}
static NSData *ODRMJSON(id v){return [NSJSONSerialization isValidJSONObject:v]?[NSJSONSerialization dataWithJSONObject:v options:NSJSONWritingSortedKeys error:nil]:nil;}
static NSString *ODRMHash(NSData *data){unsigned char b[32];CC_SHA256(data.bytes,(CC_LONG)data.length,b);NSMutableString *s=[NSMutableString stringWithCapacity:64];for(int i=0;i<32;i++)[s appendFormat:@"%02x",b[i]];return s;}
static BOOL ODRMExec(sqlite3 *db,const char *s){return sqlite3_exec(db,s,NULL,NULL,NULL)==SQLITE_OK;}
static BOOL ODRMBind(sqlite3_stmt *s,NSArray *values){if(sqlite3_bind_parameter_count(s)!=(int)values.count)return NO;int i=1;for(id v in values){int rc;if(v==NSNull.null)rc=sqlite3_bind_null(s,i);else if([v isKindOfClass:NSString.class])rc=sqlite3_bind_text(s,i,[v UTF8String],-1,SQLITE_TRANSIENT);else if([v isKindOfClass:NSData.class])rc=sqlite3_bind_blob(s,i,[v bytes],(int)[v length],SQLITE_TRANSIENT);else if(ODRMInteger(v))rc=sqlite3_bind_int64(s,i,[v longLongValue]);else if([v isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)v)!=CFBooleanGetTypeID()&&isfinite([v doubleValue]))rc=sqlite3_bind_double(s,i,[v doubleValue]);else return NO;if(rc!=SQLITE_OK)return NO;i++;}return YES;}
static id ODRMValue(sqlite3_stmt *s,int i){switch(sqlite3_column_type(s,i)){case SQLITE_INTEGER:return @(sqlite3_column_int64(s,i));case SQLITE_FLOAT:return @(sqlite3_column_double(s,i));case SQLITE_TEXT:return [NSString stringWithUTF8String:(const char *)sqlite3_column_text(s,i)]?:NSNull.null;case SQLITE_BLOB:return [NSData dataWithBytes:sqlite3_column_blob(s,i) length:(NSUInteger)sqlite3_column_bytes(s,i)];default:return NSNull.null;}}
static NSArray *ODRMQuery(sqlite3 *db,NSString *sql,NSArray *values){sqlite3_stmt *s=NULL;if(sqlite3_prepare_v2(db,sql.UTF8String,-1,&s,NULL)!=SQLITE_OK)return nil;if(!ODRMBind(s,values)){sqlite3_finalize(s);return nil;}NSMutableArray *out=[NSMutableArray array];int rc;while((rc=sqlite3_step(s))==SQLITE_ROW){if(out.count>=50000){sqlite3_finalize(s);return nil;}NSMutableDictionary *row=[NSMutableDictionary dictionary];for(int i=0;i<sqlite3_column_count(s);i++)row[[NSString stringWithUTF8String:sqlite3_column_name(s,i)]]=ODRMValue(s,i);[out addObject:row];}sqlite3_finalize(s);return rc==SQLITE_DONE?out:nil;}
static BOOL ODRMWrite(sqlite3 *db,NSString *sql,NSArray *values){sqlite3_stmt *s=NULL;if(sqlite3_prepare_v2(db,sql.UTF8String,-1,&s,NULL)!=SQLITE_OK)return NO;BOOL ok=ODRMBind(s,values)&&sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);return ok;}
static BOOL ODRMFile(NSURL *url){return url.isFileURL&&[url.path isEqual:url.URLByResolvingSymlinksInPath.path]&&url.path.isAbsolutePath;}
static BOOL ODRMHashFile(NSURL *url,NSString *expected,struct stat *info){int fd=open(url.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_NONBLOCK);if(fd<0)return NO;struct stat before={0},after={0};BOOL ok=fstat(fd,&before)==0&&S_ISREG(before.st_mode)&&before.st_size>16&&before.st_size<=2LL*1024*1024*1024;CC_SHA256_CTX ctx;CC_SHA256_Init(&ctx);unsigned char buf[65536];ssize_t n=0;while(ok&&(n=read(fd,buf,sizeof(buf)))>0)CC_SHA256_Update(&ctx,buf,(CC_LONG)n);if(n<0)ok=NO;unsigned char hash[32];CC_SHA256_Final(hash,&ctx);ok=ok&&fstat(fd,&after)==0&&before.st_dev==after.st_dev&&before.st_ino==after.st_ino&&before.st_size==after.st_size&&before.st_mtimespec.tv_sec==after.st_mtimespec.tv_sec&&before.st_mtimespec.tv_nsec==after.st_mtimespec.tv_nsec;close(fd);NSMutableString *hex=[NSMutableString stringWithCapacity:64];for(int i=0;i<32;i++)[hex appendFormat:@"%02x",hash[i]];if(info)*info=before;return ok&&[hex isEqual:expected];}

@interface ODRuntimeMasterStore ()
- (nullable NSDictionary *)compilePacket:(NSDictionary *)packet fullBundle:(BOOL)full error:(NSError **)error;
@end

@implementation ODRuntimeMasterStore {
    NSURL *_master,*_derived;NSString *_content,*_scope,*_sourceSHA;ODRuntimeForgeCompiler *_compiler;
}
- (instancetype)initWithImmutableMaster:(NSURL *)master derivedMaster:(NSURL *)derived contentID:(NSString *)content saveScope:(NSString *)scope compiler:(ODRuntimeForgeCompiler *)compiler error:(NSError **)error {
    if(!(self=[super init]))return nil;
    if(![content isKindOfClass:NSString.class]){if(error)*error=ODRMError(@"RUNTIME_HOST_CONTEXT_INVALID");return nil;}
    NSString *prefix=[content hasPrefix:@"sparking:"]?@"sparking:":[content hasPrefix:@"eclipse:"]?@"eclipse:":@"";
    NSString *plain=[content substringFromIndex:prefix.length];NSString *sha=[plain hasPrefix:@"sha256:"]?[plain substringFromIndex:7]:nil;
    if(!ODRMFile(master)||!ODRMFile(derived)||[master.path isEqual:derived.path]||!ODRMHex(sha)||!ODRMHex(scope)||!compiler){if(error)*error=ODRMError(@"RUNTIME_HOST_CONTEXT_INVALID");return nil;}
    _master=master;_derived=derived;_content=[content copy];_scope=[scope copy];_sourceSHA=[sha copy];_compiler=compiler;return self;
}
- (BOOL)blueprint:(NSDictionary *)project definition:(NSDictionary *)definition {
    if(![project isKindOfClass:NSDictionary.class]||![definition isKindOfClass:NSDictionary.class]||![project[@"format"] isEqual:@"dokkan-unit-forge"]||![project[@"version"] isEqual:@1]||ODRMAwakeningRequested(project[@"awaken"])||definition[@"full_bundle"]||definition[@"stat_policy"]||definition[@"progression_policy"])return NO;
    for(NSString *field in @[@"formProjects",@"formLinks"]){id forms=project[field];if(forms&&(![forms isKindOfClass:NSArray.class]||[forms count]))return NO;}
    if(![definition[@"source"] isKindOfClass:NSDictionary.class]||![project[@"source"] isKindOfClass:NSDictionary.class])return NO;
    if(![definition[@"format"] isEqual:@"offline-dokkan-definition"]||![definition[@"schema_version"] isEqual:@1]||![definition[@"fully_awakened"] isEqual:@YES]||![definition[@"source"][@"content_id"] isEqual:_content]||![project[@"source"][@"cardId"] isEqual:definition[@"source"][@"master_id"]])return NO;
    NSDictionary *tables=project[@"tables"],*dt=definition[@"tables"];
    if(![tables isKindOfClass:NSDictionary.class]||![dt isKindOfClass:NSDictionary.class])return NO;
    NSArray *cards=tables[@"cards"];
    if(![cards isKindOfClass:NSArray.class]||cards.count!=1||![cards[0] isKindOfClass:NSDictionary.class]||![project[@"cardOverrides"] isKindOfClass:NSDictionary.class])return NO;
    NSMutableDictionary *card=[cards[0] mutableCopy];[card addEntriesFromDictionary:project[@"cardOverrides"]];if(![card isEqual:definition[@"card"]])return NO;
    for(NSString *table in dt)if(![dt[table] isEqual:tables[table]])return NO;
    return YES;
}
- (BOOL)omittedRows:(NSDictionary *)project definition:(NSDictionary *)definition source:(sqlite3 *)source {
    for(NSString *table in project[@"tables"]){if([table isEqual:@"cards"]||definition[@"tables"][table])continue;NSString *q=ODRMQuote(table);NSArray *rows=project[@"tables"][table];if(!q||![rows isKindOfClass:NSArray.class])return NO;for(NSDictionary *row in rows){if(![row isKindOfClass:NSDictionary.class]||!ODRMInteger(row[@"id"]))return NO;NSArray *actual=ODRMQuery(source,[NSString stringWithFormat:@"SELECT * FROM %@ WHERE id=?",q],@[row[@"id"]]);if(actual.count!=1||![actual[0] isEqual:row])return NO;}}return YES;
}
- (BOOL)metadata:(sqlite3 *)db existing:(BOOL)existing {
    NSDictionary *want=@{@"format":@"od-derived-original-master-v1",@"scope":_scope,@"content_id":_content,@"source_sha256":_sourceSHA};
    if(existing){NSArray *rows=ODRMQuery(db,@"SELECT key,value FROM od_runtime_meta",@[]);NSMutableDictionary *actual=[NSMutableDictionary dictionary];for(NSDictionary *r in rows)actual[r[@"key"]]=r[@"value"];return rows&&[actual isEqual:want];}
    if(!ODRMExec(db,"CREATE TABLE od_runtime_meta(key TEXT PRIMARY KEY,value TEXT NOT NULL) STRICT;CREATE TABLE od_runtime_versions(definition_id TEXT NOT NULL,version INTEGER NOT NULL,project_sha256 TEXT NOT NULL,definition_sha256 TEXT NOT NULL,runtime_id INTEGER NOT NULL UNIQUE,project BLOB NOT NULL,definition BLOB NOT NULL,accepted_binding TEXT NOT NULL CHECK(json_valid(accepted_binding)),receipt TEXT NOT NULL,PRIMARY KEY(definition_id,version)) STRICT;CREATE TABLE od_runtime_rows(table_name TEXT NOT NULL,row_id INTEGER NOT NULL,definition_id TEXT NOT NULL,version INTEGER NOT NULL,PRIMARY KEY(table_name,row_id)) STRICT;"))return NO;
    for(NSString *k in want)if(!ODRMWrite(db,@"INSERT INTO od_runtime_meta VALUES(?,?)",@[k,want[k]]))return NO;return YES;
}
- (NSInteger)admitRows:(NSDictionary *)tables database:(sqlite3 *)db {
    if(![tables isKindOfClass:NSDictionary.class])return -1;NSUInteger total=0;
    for(NSString *table in tables){NSString *q=ODRMQuote(table);NSArray *rows=tables[table];if(!q||![rows isKindOfClass:NSArray.class])return -1;
        NSArray *schema=ODRMQuery(db,[NSString stringWithFormat:@"PRAGMA table_info(%@)",q],@[]);NSMutableDictionary *cols=[NSMutableDictionary dictionary];for(NSDictionary *col in schema)cols[col[@"name"]]=col;if(!cols.count)return -1;NSMutableSet *seen=[NSMutableSet set];
        for(NSDictionary *row in rows){if(++total>50000||![row isKindOfClass:NSDictionary.class]||![[NSSet setWithArray:row.allKeys] isEqual:[NSSet setWithArray:cols.allKeys]]||!ODRMInteger(row[@"id"])||[row[@"id"] longLongValue]<1||[seen containsObject:row[@"id"]])return -1;[seen addObject:row[@"id"]];
            NSArray *collision=ODRMQuery(db,[NSString stringWithFormat:@"SELECT id FROM %@ WHERE id=?",q],@[row[@"id"]]);if(!collision)return -1;if(collision.count)return 0;
            for(NSString *field in row){id v=row[field];NSDictionary *col=cols[field];NSString *type=[col[@"type"] uppercaseString];if(v==NSNull.null){if([col[@"notnull"] boolValue]||[col[@"pk"] boolValue])return -1;}else if([type containsString:@"INT"]&&!ODRMInteger(v))return -1;else if(([type containsString:@"CHAR"]||[type containsString:@"TEXT"]||[type containsString:@"JSON"]||[type containsString:@"DATE"])&&![v isKindOfClass:NSString.class])return -1;else if([v isKindOfClass:NSString.class]){if([v lengthOfBytesUsingEncoding:NSUTF8StringEncoding]>1024*1024||[v rangeOfString:[NSString stringWithFormat:@"%C",(unichar)0]].location!=NSNotFound)return -1;}else if(![v isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)v)==CFBooleanGetTypeID()||!isfinite([v doubleValue]))return -1;}
        }
    }return 1;
}
- (BOOL)insertRows:(NSDictionary *)tables binding:(NSDictionary *)binding database:(sqlite3 *)db {
    for(NSString *table in tables)for(NSDictionary *row in tables[table]){NSArray *names=[row.allKeys sortedArrayUsingSelector:@selector(compare:)];NSMutableArray *quoted=[NSMutableArray array],*params=[NSMutableArray array],*values=[NSMutableArray array];for(NSString *name in names){NSString *q=ODRMQuote(name);if(!q)return NO;[quoted addObject:q];[params addObject:@"?"];[values addObject:row[name]];}NSString *sql=[NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)",ODRMQuote(table),[quoted componentsJoinedByString:@","],[params componentsJoinedByString:@","]];if(!ODRMWrite(db,sql,values)||!ODRMWrite(db,@"INSERT INTO od_runtime_rows VALUES(?,?,?,?)",@[table,row[@"id"],binding[@"definition_id"],binding[@"version"]]))return NO;}return YES;
}
- (BOOL)references:(NSDictionary *)result database:(sqlite3 *)db {
    NSMutableDictionary *refs=[result[@"foreign"] mutableCopy];if(![refs isKindOfClass:NSMutableDictionary.class])return NO;
    [refs addEntriesFromDictionary:@{@"card_special_id":@"card_specials",@"character_id":@"characters",@"card_unique_info_id":@"card_unique_infos",@"potential_board_id":@"potential_boards",@"card_awakening_set_id":@"card_awakening_sets"}];for(int i=1;i<=7;i++)refs[[NSString stringWithFormat:@"link_skill%d_id",i]]=@"link_skills";
    for(NSString *table in result[@"tables"])for(NSDictionary *row in result[@"tables"][table])for(NSString *field in row){NSString *target=refs[field];id value=row[field];if(!target||value==NSNull.null||[value isEqual:@0])continue;NSString *q=ODRMQuote(target);if(!q||!ODRMInteger(value))return NO;NSArray *found=ODRMQuery(db,[NSString stringWithFormat:@"SELECT id FROM %@ WHERE id=?",q],@[value]);if(found.count!=1)return NO;}
    NSArray *bad=ODRMQuery(db,@"PRAGMA foreign_key_check",@[]);return bad&&bad.count==0;
}
- (NSDictionary *)fullBundleForPacket:(NSDictionary *)packet project:(NSDictionary *)project definition:(NSDictionary *)definition error:(NSError **)error {
    NSDictionary *binding=packet[@"binding"],*accepted=packet[@"full_bundle_receipt"],*descriptor=definition[@"full_bundle"];
    NSData *bytes=packet[@"full_bundle_bytes"];NSString *sha=packet[@"full_bundle_sha256"];
    NSSet *packetFields=[NSSet setWithArray:@[@"binding",@"project_bytes",@"definition_bytes",@"full_bundle_bytes",@"full_bundle_sha256",@"full_bundle_receipt"]];
    NSSet *receiptFields=[NSSet setWithArray:@[@"format",@"content_id",@"save_scope",@"profile_id",@"definition_id",@"version",@"instance_id",@"profile_revision",@"projection_generation",@"full_bundle_sha256",@"project_sha256",@"definition_sha256",@"member_count"]];
    NSSet *descriptorFields=[NSSet setWithArray:@[@"format",@"projection",@"content_id",@"profile_id",@"save_scope",@"definition_id",@"version",@"project_sha256",@"full_bundle_sha256",@"member_count"]];
    BOOL valid=[[NSSet setWithArray:packet.allKeys] isEqual:packetFields]&&[accepted isKindOfClass:NSDictionary.class]&&[descriptor isKindOfClass:NSDictionary.class]&&
        [[NSSet setWithArray:accepted.allKeys] isEqual:receiptFields]&&[[NSSet setWithArray:descriptor.allKeys] isEqual:descriptorFields]&&
        [bytes isKindOfClass:NSData.class]&&bytes.length&&bytes.length<=64*1024*1024&&ODRMHex(sha)&&[ODRMHash(bytes) isEqual:sha]&&
        [accepted[@"format"] isEqual:@"od-accepted-full-bundle-receipt-v1"]&&[descriptor[@"format"] isEqual:@"od-full-creator-binding-v2"]&&[descriptor[@"projection"] isEqual:@"progression-root-v1"]&&
        [accepted[@"profile_id"] isEqual:@"local-player"]&&[descriptor[@"profile_id"] isEqual:@"local-player"]&&
        ODRMInteger(accepted[@"version"])&&ODRMInteger(accepted[@"instance_id"])&&ODRMInteger(accepted[@"member_count"])&&ODRMInteger(descriptor[@"version"])&&
        ODRMInteger(accepted[@"profile_revision"])&&[accepted[@"profile_revision"] longLongValue]>=0&&ODRMInteger(accepted[@"projection_generation"])&&[accepted[@"projection_generation"] longLongValue]>=0&&
        [accepted[@"instance_id"] isEqual:binding[@"instance_id"]]&&[accepted[@"definition_sha256"] isEqual:binding[@"definition_sha256"]]&&
        ODRMInteger(descriptor[@"member_count"])&&[descriptor[@"member_count"] integerValue]>=1&&[descriptor[@"member_count"] integerValue]<=5&&
        [accepted[@"member_count"] isEqual:descriptor[@"member_count"]];
    for(NSString *field in @[@"content_id",@"save_scope",@"definition_id",@"version",@"project_sha256"])
        valid=valid&&[accepted[field] isEqual:binding[field]]&&[descriptor[field] isEqual:binding[field]];
    valid=valid&&[accepted[@"full_bundle_sha256"] isEqual:sha]&&[descriptor[@"full_bundle_sha256"] isEqual:sha]&&
        [project isKindOfClass:NSDictionary.class]&&[definition isKindOfClass:NSDictionary.class]&&[project[@"format"] isEqual:@"dokkan-unit-forge"]&&ODRMInteger(project[@"version"])&&[project[@"version"] isEqual:@1]&&
        [definition[@"format"] isEqual:@"offline-dokkan-definition"]&&ODRMInteger(definition[@"schema_version"])&&[definition[@"schema_version"] isEqual:@1]&&ODRMInteger(definition[@"version"])&&ODRMBool(definition[@"fully_awakened"],YES)&&
        [definition[@"source"] isKindOfClass:NSDictionary.class]&&[project[@"source"] isKindOfClass:NSDictionary.class]&&[definition[@"source"][@"content_id"] isEqual:_content]&&[definition[@"source"][@"master_id"] isEqual:project[@"source"][@"cardId"]];
    NSDictionary *bundle=valid?[NSJSONSerialization JSONObjectWithData:bytes options:0 error:nil]:nil;
    if(![bundle isKindOfClass:NSDictionary.class]){if(error)*error=ODRMError(@"RUNTIME_FULL_BUNDLE_IDENTITY_MISMATCH");return nil;}
    valid=valid&&[bundle isKindOfClass:NSDictionary.class]&&[bundle[@"format"] isEqual:@"od-native-creator-full-bundle-v2"]&&
        [bundle[@"engine_admission"] isEqual:@"pending-master-cipher-resource-and-form-progression-binding"]&&!bundle[@"original_client_attached"]&&[bundle[@"source_sha256"] isEqual:_sourceSHA]&&
        [bundle[@"profile_id"] isEqual:@"local-player"]&&ODRMInteger(bundle[@"version"])&&ODRMInteger(bundle[@"member_count"])&&[bundle[@"member_count"] isEqual:descriptor[@"member_count"]]&&[bundle[@"tables"] isKindOfClass:NSDictionary.class]&&
        ODRMInteger(bundle[@"materialization_utc"])&&[bundle[@"materialization_utc"] longLongValue]>=0&&[bundle[@"materialization_utc"] longLongValue]<=253402300799000LL;
    for(NSString *field in @[@"content_id",@"save_scope",@"definition_id",@"version",@"project_sha256"])
        valid=valid&&[bundle[field] isEqual:binding[field]];
    NSArray *forms=project[@"formProjects"]?:@[],*members=bundle[@"members"];
    valid=valid&&[forms isKindOfClass:NSArray.class]&&[members isKindOfClass:NSArray.class]&&members.count==forms.count+1&&members.count==[descriptor[@"member_count"] unsignedIntegerValue];
    NSMutableArray *projects=[NSMutableArray arrayWithObject:project?:@{}];if([forms isKindOfClass:NSArray.class])[projects addObjectsFromArray:forms];
    NSDictionary *projectSource=[project[@"source"] isKindOfClass:NSDictionary.class]?project[@"source"]:nil;
    NSString *game=[_content hasPrefix:@"sparking:"]?@"sparking":[_content hasPrefix:@"eclipse:"]?@"eclipse":projectSource[@"database"];
    valid=valid&&game&&[@[@"eclipse",@"sparking"] containsObject:game];
    NSMutableSet *keys=[NSMutableSet set],*targets=[NSMutableSet set];
    if(valid)for(NSUInteger i=0;i<members.count;i++){
        NSDictionary *member=members[i],*design=projects[i];
        if(![member isKindOfClass:NSDictionary.class]||![design isKindOfClass:NSDictionary.class]||ODRMAwakeningRequested(design[@"awaken"])||!ODRMMemberKey(member[@"key"])||[keys containsObject:member[@"key"]]||
           ![member[@"key"] isEqual:design[@"key"]]||![member[@"source"] isKindOfClass:NSDictionary.class]||![member[@"source"] isEqual:design[@"source"]]||![member[@"source"][@"contentId"] isEqual:_content]||![member[@"source"][@"database"] isEqual:game]||
           !ODRMInteger(member[@"source"][@"cardId"])||[member[@"source"][@"cardId"] longLongValue]<1||!ODRMInteger(member[@"runtime_card_id"])||[member[@"runtime_card_id"] longLongValue]<1||
           ![member[@"runtime_card_id"] isEqual:design[@"targetId"]]||[targets containsObject:member[@"runtime_card_id"]]){valid=NO;break;}
        [keys addObject:member[@"key"]];[targets addObject:member[@"runtime_card_id"]];
    }
    for(NSString *field in @[@"resources",@"transform_links",@"source_dependencies",@"shared_actions"])valid=valid&&[bundle[field] isKindOfClass:NSArray.class];
    if(!valid){if(error)*error=ODRMError(@"RUNTIME_FULL_BUNDLE_IDENTITY_MISMATCH");return nil;}
    // Keep the accepted bytes intact. Do not pretend unproved file/dependency
    // remapping is an admitted complete unit by quietly omitting it.
    if([bundle[@"resources"] count]||[bundle[@"source_dependencies"] count]||[bundle[@"shared_actions"] count]){if(error)*error=ODRMError(@"RUNTIME_FULL_RESOURCE_ADMISSION_REQUIRED");return nil;}
    return bundle;
}
- (BOOL)fullResult:(NSDictionary *)result bundle:(NSDictionary *)bundle ids:(NSArray *)ids sha:(NSString *)sha {
    if(![result isKindOfClass:NSDictionary.class]||![result[@"tables"] isKindOfClass:NSDictionary.class]||![result[@"runtimeIds"] isEqual:ids]||![result[@"full_bundle_sha256"] isEqual:sha]||
       !ODRMBool(result[@"encoded_references_complete"],YES)||![result[@"encoded_reference_scope"] isEqual:@"private-owned-row-identities-only-v1"]||!ODRMBool(result[@"complete_member_materialization"],YES)||!ODRMBool(result[@"source_reference_validation_required"],YES)||!ODRMBool(result[@"gameplay_ready"],NO)||!ODRMBool(result[@"original_client_attached"],NO)||!ODRMBool(result[@"resource_admission_complete"],NO))return NO;
    NSArray *members=result[@"members"],*accepted=bundle[@"members"],*cards=result[@"tables"][@"cards"],*roots=result[@"native_root_card_ids"];
    if(![members isKindOfClass:NSArray.class]||members.count!=ids.count||![accepted isKindOfClass:NSArray.class]||accepted.count!=ids.count||![cards isKindOfClass:NSArray.class]||cards.count!=ids.count*2||![roots isKindOfClass:NSArray.class]||roots.count!=ids.count)return NO;
    NSMutableSet *expected=[NSMutableSet setWithArray:ids],*actual=[NSMutableSet set];
    for(NSUInteger i=0;i<ids.count;i++){
        NSDictionary *member=members[i],*source=accepted[i];NSNumber *root=@([ids[i] longLongValue]-1);
        if(![member isKindOfClass:NSDictionary.class]||![member[@"key"] isEqual:source[@"key"]]||![member[@"source_card_id"] isEqual:source[@"source"][@"cardId"]]||![member[@"accepted_runtime_card_id"] isEqual:source[@"runtime_card_id"]]||![member[@"runtime_card_id"] isEqual:ids[i]]||![roots[i] isEqual:root])return NO;
        [expected addObject:root];
    }
    for(NSDictionary *card in cards){if(![card isKindOfClass:NSDictionary.class]||!ODRMInteger(card[@"id"])||[actual containsObject:card[@"id"]])return NO;[actual addObject:card[@"id"]];}
    return [actual isEqual:expected];
}
- (BOOL)storedRowsMatch:(NSDictionary *)tables binding:(NSDictionary *)binding database:(sqlite3 *)db {
    NSUInteger expected=0;for(NSString *table in tables){NSArray *rows=tables[table];if(![rows isKindOfClass:NSArray.class]||rows.count>50000-expected)return NO;expected+=rows.count;}
    NSArray *counted=ODRMQuery(db,@"SELECT count(*) AS count FROM od_runtime_rows WHERE definition_id=? AND version=?",@[binding[@"definition_id"],binding[@"version"]]);
    if(counted.count!=1||!ODRMInteger(counted[0][@"count"])||[counted[0][@"count"] unsignedIntegerValue]!=expected)return NO;
    NSUInteger count=0;for(NSString *table in tables){NSString *quoted=ODRMQuote(table);NSArray *rows=tables[table];if(!quoted||![rows isKindOfClass:NSArray.class])return NO;for(NSDictionary *row in rows){
        if(++count>50000||![row isKindOfClass:NSDictionary.class]||!ODRMInteger(row[@"id"]))return NO;
        NSArray *actual=ODRMQuery(db,[NSString stringWithFormat:@"SELECT * FROM %@ WHERE id=?",quoted],@[row[@"id"]]);
        NSArray *owner=ODRMQuery(db,@"SELECT definition_id,version FROM od_runtime_rows WHERE table_name=? AND row_id=?",@[table,row[@"id"]]);
        if(actual.count!=1||![actual[0] isEqual:row]||owner.count!=1||![owner[0][@"definition_id"] isEqual:binding[@"definition_id"]]||![owner[0][@"version"] isEqual:binding[@"version"]])return NO;
    }}return YES;
}
- (NSDictionary *)compileAcceptedPacket:(NSDictionary *)packet error:(NSError **)error {
    if(![packet isKindOfClass:NSDictionary.class]||packet[@"full_bundle_bytes"]||packet[@"full_bundle_sha256"]||packet[@"full_bundle_receipt"]){if(error)*error=ODRMError(@"RUNTIME_FULL_BUNDLE_NATIVE_PATH_REQUIRED");return nil;}
    return [self compilePacket:packet fullBundle:NO error:error];
}
- (NSDictionary *)compileAcceptedFullBundlePacket:(NSDictionary *)packet error:(NSError **)error {
    return [self compilePacket:packet fullBundle:YES error:error];
}
- (NSDictionary *)compilePacket:(NSDictionary *)packet fullBundle:(BOOL)full error:(NSError **)error {
    if(![packet isKindOfClass:NSDictionary.class]||![packet[@"binding"] isKindOfClass:NSDictionary.class]){if(error)*error=ODRMError(@"RUNTIME_ACCEPTED_RECEIPT_MISMATCH");return nil;}
    // Freeze the native packet before hashing it. A caller's mutable container
    // or NSMutableData must not change between validation and SQLite commit.
    NSData *bindingBytes=ODRMJSON(packet[@"binding"]);NSDictionary *binding=bindingBytes.length&&bindingBytes.length<=8192?[NSJSONSerialization JSONObjectWithData:bindingBytes options:0 error:nil]:nil;
    NSData *projectBytes=[packet[@"project_bytes"] isKindOfClass:NSData.class]?[packet[@"project_bytes"] copy]:nil,*definitionBytes=[packet[@"definition_bytes"] isKindOfClass:NSData.class]?[packet[@"definition_bytes"] copy]:nil;
    if(![binding isKindOfClass:NSDictionary.class]||!projectBytes||!definitionBytes){if(error)*error=ODRMError(@"RUNTIME_ACCEPTED_RECEIPT_MISMATCH");return nil;}
    NSMutableDictionary *frozen=[packet mutableCopy];frozen[@"binding"]=binding;frozen[@"project_bytes"]=projectBytes;frozen[@"definition_bytes"]=definitionBytes;
    if(full){
        NSData *bundleBytes=[packet[@"full_bundle_bytes"] isKindOfClass:NSData.class]?[packet[@"full_bundle_bytes"] copy]:nil,*receiptBytes=ODRMJSON(packet[@"full_bundle_receipt"]);
        NSDictionary *accepted=receiptBytes.length&&receiptBytes.length<=8192?[NSJSONSerialization JSONObjectWithData:receiptBytes options:0 error:nil]:nil;
        if(!bundleBytes||![accepted isKindOfClass:NSDictionary.class]||![packet[@"full_bundle_sha256"] isKindOfClass:NSString.class]){if(error)*error=ODRMError(@"RUNTIME_FULL_BUNDLE_IDENTITY_MISMATCH");return nil;}
        frozen[@"full_bundle_bytes"]=bundleBytes;frozen[@"full_bundle_sha256"]=[packet[@"full_bundle_sha256"] copy];frozen[@"full_bundle_receipt"]=accepted;
    }
    packet=[frozen copy];NSString *failure=@"RUNTIME_COMPILATION_FAILED";
    NSSet *fields=[NSSet setWithArray:@[@"format",@"content_id",@"save_scope",@"definition_id",@"version",@"project_sha256",@"definition_sha256",@"instance_id",@"accepted"]];
    BOOL acceptedBool=[binding[@"accepted"] isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)binding[@"accepted"])==CFBooleanGetTypeID()&&[binding[@"accepted"] boolValue];
    if(![binding isKindOfClass:NSDictionary.class]||![[NSSet setWithArray:binding.allKeys] isEqual:fields]||![binding[@"format"] isEqual:@"od-accepted-creator-project-v1"]||!acceptedBool||![binding[@"content_id"] isEqual:_content]||![binding[@"save_scope"] isEqual:_scope]||!ODRMName(binding[@"definition_id"])||!ODRMInteger(binding[@"version"])||[binding[@"version"] longLongValue]<1||!ODRMInteger(binding[@"instance_id"])||[binding[@"instance_id"] longLongValue]<1||![projectBytes isKindOfClass:NSData.class]||!projectBytes.length||projectBytes.length>20*1024*1024||![definitionBytes isKindOfClass:NSData.class]||!definitionBytes.length||definitionBytes.length>16*1024*1024||!ODRMHex(binding[@"project_sha256"])||!ODRMHex(binding[@"definition_sha256"])||![ODRMHash(projectBytes) isEqual:binding[@"project_sha256"]]||![ODRMHash(definitionBytes) isEqual:binding[@"definition_sha256"]]){if(error)*error=ODRMError(@"RUNTIME_ACCEPTED_RECEIPT_MISMATCH");return nil;}
    NSDictionary *project=[NSJSONSerialization JSONObjectWithData:projectBytes options:0 error:nil],*definition=[NSJSONSerialization JSONObjectWithData:definitionBytes options:0 error:nil];
    if(![project isKindOfClass:NSDictionary.class]||![definition isKindOfClass:NSDictionary.class]||![binding[@"definition_id"] isEqual:definition[@"definition_id"]]||![binding[@"version"] isEqual:definition[@"version"]]){if(error)*error=ODRMError(@"RUNTIME_DEFINITION_PROJECT_MISMATCH");return nil;}
    NSDictionary *fullBundle=full?[self fullBundleForPacket:packet project:project definition:definition error:error]:nil;
    if(full&&!fullBundle)return nil;
    if(!full&&![self blueprint:project definition:definition]){if(error)*error=ODRMError(@"RUNTIME_DEFINITION_PROJECT_MISMATCH");return nil;}
    NSUInteger memberCount=full?[fullBundle[@"member_count"] unsignedIntegerValue]:1;
    NSURL *parent=_derived.URLByDeletingLastPathComponent;if(![NSFileManager.defaultManager createDirectoryAtURL:parent withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions:@0700} error:nil]){if(error)*error=ODRMError(@"RUNTIME_PATH_UNSAFE");return nil;}
    NSURL *lock=[NSURL fileURLWithPath:[_derived.path stringByAppendingString:@".lock"]];int lockFD=open(lock.fileSystemRepresentation,O_CREAT|O_WRONLY|O_NOFOLLOW,0600);struct stat lockInfo;
    if(lockFD<0||fstat(lockFD,&lockInfo)||!S_ISREG(lockInfo.st_mode)||(lockInfo.st_mode&0077)||flock(lockFD,LOCK_EX|LOCK_NB)){if(lockFD>=0)close(lockFD);if(error)*error=ODRMError(@"RUNTIME_COMPILER_BUSY");return nil;}
    sqlite3 *source=NULL,*db=NULL;NSURL *temp=nil;NSDictionary *receipt=nil;struct stat original={0},prior={0};BOOL existing=lstat(_derived.fileSystemRepresentation,&prior)==0;
    @try {
        if(!ODRMFile(_master)||!ODRMFile(_derived)||(existing&&(!S_ISREG(prior.st_mode)||(prior.st_mode&0077)))||!ODRMHashFile(_master,_sourceSHA,&original)){failure=@"RUNTIME_SOURCE_OR_PATH_MISMATCH";@throw failure;}
        if(existing&&prior.st_dev==original.st_dev&&prior.st_ino==original.st_ino){failure=@"RUNTIME_SOURCE_ALIAS";@throw failure;}
        if(sqlite3_open_v2(_master.fileSystemRepresentation,&source,SQLITE_OPEN_READONLY|SQLITE_OPEN_NOFOLLOW,NULL)!=SQLITE_OK||sqlite3_db_readonly(source,"main")!=1||!ODRMExec(source,"PRAGMA query_only=ON;PRAGMA trusted_schema=OFF")){failure=@"RUNTIME_SOURCE_OPEN_FAILED";@throw failure;}
        if(!full&&![self omittedRows:project definition:definition source:source]){failure=@"RUNTIME_UNADMITTED_ROW";@throw failure;}
        temp=[parent URLByAppendingPathComponent:[NSString stringWithFormat:@".runtime-%@.db",NSUUID.UUID.UUIDString]];int tempFD=open(temp.fileSystemRepresentation,O_CREAT|O_EXCL|O_WRONLY|O_NOFOLLOW,0600);if(tempFD<0)@throw failure;close(tempFD);
        if(sqlite3_open_v2(temp.fileSystemRepresentation,&db,SQLITE_OPEN_READWRITE|SQLITE_OPEN_NOFOLLOW,NULL)!=SQLITE_OK)@throw failure;
        sqlite3 *base=source,*previous=NULL;if(existing){if(sqlite3_open_v2(_derived.fileSystemRepresentation,&previous,SQLITE_OPEN_READONLY|SQLITE_OPEN_NOFOLLOW,NULL)!=SQLITE_OK){sqlite3_close(previous);@throw failure;}base=previous;}
        sqlite3_backup *backup=sqlite3_backup_init(db,"main",base,"main");int rc=backup?sqlite3_backup_step(backup,-1):SQLITE_ERROR;int finish=backup?sqlite3_backup_finish(backup):SQLITE_ERROR;sqlite3_close(previous);if(rc!=SQLITE_DONE||finish!=SQLITE_OK)@throw failure;
        if(!ODRMExec(db,"PRAGMA synchronous=FULL;PRAGMA foreign_keys=ON;PRAGMA trusted_schema=OFF;BEGIN IMMEDIATE")||![self metadata:db existing:existing]){failure=@"RUNTIME_IDENTITY_MISMATCH";@throw failure;}
        if(full&&!ODRMExec(db,"CREATE TABLE IF NOT EXISTS od_runtime_full_bundles(definition_id TEXT NOT NULL,version INTEGER NOT NULL,full_bundle_sha256 TEXT NOT NULL,full_bundle BLOB NOT NULL,runtime_ids TEXT NOT NULL CHECK(json_valid(runtime_ids)),PRIMARY KEY(definition_id,version),FOREIGN KEY(definition_id,version) REFERENCES od_runtime_versions(definition_id,version)) STRICT"))@throw failure;
        NSArray *old=ODRMQuery(db,@"SELECT project_sha256,definition_sha256,project,definition,runtime_id,accepted_binding,receipt FROM od_runtime_versions WHERE definition_id=? AND version=?",@[binding[@"definition_id"],binding[@"version"]]);if(!old)@throw failure;
        if(old.count){NSDictionary *row=old[0];NSData *ab=[row[@"accepted_binding"] dataUsingEncoding:NSUTF8StringEncoding];id previousBinding=[NSJSONSerialization JSONObjectWithData:ab options:0 error:nil];if(![row[@"project_sha256"] isEqual:binding[@"project_sha256"]]||![row[@"definition_sha256"] isEqual:binding[@"definition_sha256"]]||![row[@"project"] isEqual:projectBytes]||![row[@"definition"] isEqual:definitionBytes]||![previousBinding isEqual:binding]){failure=@"RUNTIME_VERSION_CONFLICT";@throw failure;}receipt=[NSJSONSerialization JSONObjectWithData:[row[@"receipt"] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];if(![receipt isKindOfClass:NSDictionary.class])@throw failure;
            if(full){
                NSArray *captured=ODRMQuery(db,@"SELECT full_bundle_sha256,full_bundle,runtime_ids FROM od_runtime_full_bundles WHERE definition_id=? AND version=?",@[binding[@"definition_id"],binding[@"version"]]);
                if(captured.count!=1||![captured[0][@"full_bundle_sha256"] isEqual:packet[@"full_bundle_sha256"]]||![captured[0][@"full_bundle"] isEqual:packet[@"full_bundle_bytes"]]){failure=@"RUNTIME_FULL_BUNDLE_VERSION_CONFLICT";@throw failure;}
                NSData *idsBytes=[captured[0][@"runtime_ids"] dataUsingEncoding:NSUTF8StringEncoding];NSArray *ids=idsBytes?[NSJSONSerialization JSONObjectWithData:idsBytes options:0 error:nil]:nil;
                if(![ids isKindOfClass:NSArray.class]||ids.count!=memberCount||![ids.firstObject isEqual:row[@"runtime_id"]]||![receipt[@"runtime_card_ids"] isEqual:ids]||![receipt[@"full_bundle_sha256"] isEqual:packet[@"full_bundle_sha256"]]||!ODRMBool(receipt[@"cold_engine_reload_required"],YES)||!ODRMBool(receipt[@"original_client_attached"],NO)||!ODRMBool(receipt[@"resource_admission_complete"],NO)){failure=@"RUNTIME_FULL_BUNDLE_VERSION_CONFLICT";@throw failure;}
                NSInteger base=[ids.firstObject integerValue];for(NSUInteger i=0;i<ids.count;i++)if(!ODRMInteger(ids[i])||[ids[i] longLongValue]!=base+(NSInteger)i*1000||[ids[i] longLongValue]<97000001||[ids[i] longLongValue]>98999001||[ids[i] longLongValue]%1000!=1){failure=@"RUNTIME_FULL_BUNDLE_VERSION_CONFLICT";@throw failure;}
                NSDictionary *result=[_compiler materializeAcceptedFullBundle:packet[@"full_bundle_bytes"] projectBytes:projectBytes definitionBytes:definitionBytes acceptedBinding:binding runtimeIDs:ids reservations:@[] floor:base error:nil];
                if(![self fullResult:result bundle:fullBundle ids:ids sha:packet[@"full_bundle_sha256"]]||![self storedRowsMatch:result[@"tables"] binding:binding database:db]||![self references:result database:db]){failure=@"RUNTIME_FULL_BUNDLE_STORED_ROWS_MISMATCH";@throw failure;}
                for(NSString *field in @[@"definition_id",@"version",@"project_sha256",@"definition_sha256",@"content_id",@"save_scope"])if(![receipt[field] isEqual:binding[field]]){failure=@"RUNTIME_FULL_BUNDLE_VERSION_CONFLICT";@throw failure;}
                if(![receipt[@"accepted_instance_id"] isEqual:binding[@"instance_id"]]||![receipt[@"runtime_card_id"] isEqual:ids.firstObject]||![receipt[@"form_count"] isEqual:@(memberCount)]||![receipt[@"members"] isEqual:result[@"members"]]||![receipt[@"native_root_card_ids"] isEqual:result[@"native_root_card_ids"]]||![receipt[@"encoded_reference_scope"] isEqual:result[@"encoded_reference_scope"]]){failure=@"RUNTIME_FULL_BUNDLE_VERSION_CONFLICT";@throw failure;}
            }
        }
        else {
            NSArray *used=ODRMQuery(db,@"SELECT runtime_id FROM od_runtime_versions UNION SELECT row_id AS runtime_id FROM od_runtime_rows WHERE table_name='cards' AND row_id BETWEEN 97000001 AND 98999001 AND row_id%1000=1 ORDER BY runtime_id",@[]);if(!used||used.count>2000)@throw failure;
            NSMutableArray *reservations=[NSMutableArray array];NSMutableSet *blocked=[NSMutableSet set];
            for(NSDictionary *r in used){NSNumber *value=r[@"runtime_id"];if(!ODRMInteger(value)||[value longLongValue]<97000001||[value longLongValue]>98999001||[value longLongValue]%1000!=1)@throw failure;[reservations addObject:@{@"key":[NSString stringWithFormat:@"reserved-%@",value],@"targetId":value}];[blocked addObject:value];}
            if(full)for(NSDictionary *member in fullBundle[@"members"]){long long value=([member[@"runtime_card_id"] longLongValue]/1000)*1000+1;NSNumber *oldBlock=@(value);if(![blocked containsObject:oldBlock]){[blocked addObject:oldBlock];[reservations addObject:@{@"key":[NSString stringWithFormat:@"authored-%@",oldBlock],@"targetId":oldBlock}];}}
            NSDictionary *result=nil;NSInteger floor=97000001;NSArray *allocated=nil;
            while(floor+(NSInteger)(memberCount-1)*1000<=98999001){
                NSMutableArray *ids=[NSMutableArray array];BOOL busy=NO;for(NSUInteger i=0;i<memberCount;i++){NSNumber *value=@(floor+(NSInteger)i*1000);[ids addObject:value];if([blocked containsObject:value])busy=YES;}
                if(busy){floor+=1000;continue;}
                NSError *compileError=nil;
                result=full?[_compiler materializeAcceptedFullBundle:packet[@"full_bundle_bytes"] projectBytes:projectBytes definitionBytes:definitionBytes acceptedBinding:binding runtimeIDs:ids reservations:reservations floor:floor error:&compileError]:[_compiler materializeAcceptedProject:project runtimeIDs:ids reservations:reservations floor:floor error:&compileError];
                if(!result){failure=compileError.localizedDescription?:@"RUNTIME_FORGE_REJECTED";@throw failure;}
                id next=result[@"next"];if(!ODRMInteger(next)||[next longLongValue]<floor||[next longLongValue]>98999001||[next longLongValue]%1000!=1)@throw failure;
                if([next integerValue]!=floor){floor=[next integerValue];result=nil;continue;}
                if(full&&![self fullResult:result bundle:fullBundle ids:ids sha:packet[@"full_bundle_sha256"]]){failure=@"RUNTIME_FULL_BUNDLE_MATERIALIZATION_MISMATCH";@throw failure;}
                NSInteger admission=[self admitRows:result[@"tables"] database:db];if(admission<0){failure=@"RUNTIME_ROW_SCHEMA_MISMATCH";@throw failure;}if(admission==1){allocated=[ids copy];break;}floor+=1000;result=nil;
            }
            if(!result){failure=@"RUNTIME_PRIVATE_BLOCKS_FULL";@throw failure;}
            if(![self insertRows:result[@"tables"] binding:binding database:db]||![self references:result database:db]){failure=@"RUNTIME_REFERENCE_OR_INSERT_FAILED";@throw failure;}
            NSNumber *runtimeID=[result[@"runtimeIds"] firstObject];NSMutableDictionary *written=[@{@"definition_id":binding[@"definition_id"],@"version":binding[@"version"],@"runtime_card_id":runtimeID,@"project_sha256":binding[@"project_sha256"],@"definition_sha256":binding[@"definition_sha256"],@"content_id":_content,@"save_scope":_scope,@"accepted_instance_id":binding[@"instance_id"],@"original_client_attached":@NO,@"resource_admission_complete":@NO,@"cold_engine_reload_required":@YES} mutableCopy];
            if(full){written[@"full_bundle_sha256"]=packet[@"full_bundle_sha256"];written[@"runtime_card_ids"]=allocated;written[@"native_root_card_ids"]=result[@"native_root_card_ids"];written[@"form_count"]=@(memberCount);written[@"members"]=result[@"members"];written[@"encoded_reference_scope"]=result[@"encoded_reference_scope"];}
            receipt=written;NSString *bindingJSON=[[NSString alloc]initWithData:ODRMJSON(binding) encoding:NSUTF8StringEncoding],*receiptJSON=[[NSString alloc]initWithData:ODRMJSON(receipt) encoding:NSUTF8StringEncoding];if(!bindingJSON||!receiptJSON||!ODRMWrite(db,@"INSERT INTO od_runtime_versions VALUES(?,?,?,?,?,?,?,?,?)",@[binding[@"definition_id"],binding[@"version"],binding[@"project_sha256"],binding[@"definition_sha256"],runtimeID,projectBytes,definitionBytes,bindingJSON,receiptJSON]))@throw failure;
            if(full){NSString *idsJSON=[[NSString alloc]initWithData:ODRMJSON(allocated) encoding:NSUTF8StringEncoding];if(!idsJSON||!ODRMWrite(db,@"INSERT INTO od_runtime_full_bundles VALUES(?,?,?,?,?)",@[binding[@"definition_id"],binding[@"version"],packet[@"full_bundle_sha256"],packet[@"full_bundle_bytes"],idsJSON]))@throw failure;}
            if(!ODRMExec(db,"COMMIT"))@throw failure;
            sqlite3_close(db);db=NULL;struct stat after={0},now={0};if((full&&!ODRMHashFile(_master,_sourceSHA,&after))||lstat(_master.fileSystemRepresentation,&after)||!S_ISREG(after.st_mode)||after.st_dev!=original.st_dev||after.st_ino!=original.st_ino||after.st_size!=original.st_size||after.st_mtimespec.tv_sec!=original.st_mtimespec.tv_sec||after.st_mtimespec.tv_nsec!=original.st_mtimespec.tv_nsec){failure=@"RUNTIME_SOURCE_CHANGED";@throw failure;}
            int status=lstat(_derived.fileSystemRepresentation,&now);if((existing&&(status||now.st_dev!=prior.st_dev||now.st_ino!=prior.st_ino||now.st_size!=prior.st_size||now.st_mtimespec.tv_sec!=prior.st_mtimespec.tv_sec||now.st_mtimespec.tv_nsec!=prior.st_mtimespec.tv_nsec))||(!existing&&status==0)){failure=@"RUNTIME_CONCURRENT_REPLACEMENT";@throw failure;}
            int persisted=open(temp.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW);if(persisted<0)@throw failure;BOOL durable=fsync(persisted)==0;close(persisted);if(!durable||chmod(temp.fileSystemRepresentation,0400)||rename(temp.fileSystemRepresentation,_derived.fileSystemRepresentation))@throw failure;temp=nil;int directory=open(parent.fileSystemRepresentation,O_RDONLY|O_DIRECTORY);if(directory<0)@throw failure;durable=fsync(directory)==0;close(directory);if(!durable)@throw failure;
        }
    } @catch(id ignored) {(void)ignored;receipt=nil;if(error)*error=ODRMError(failure);} @finally {sqlite3_close(db);sqlite3_close(source);if(temp)[NSFileManager.defaultManager removeItemAtURL:temp error:nil];flock(lockFD,LOCK_UN);close(lockFD);}
    return receipt;
}
@end
