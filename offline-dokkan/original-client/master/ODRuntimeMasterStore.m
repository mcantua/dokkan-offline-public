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
static NSData *ODRMJSON(id v){return [NSJSONSerialization isValidJSONObject:v]?[NSJSONSerialization dataWithJSONObject:v options:NSJSONWritingSortedKeys error:nil]:nil;}
static NSString *ODRMHash(NSData *data){unsigned char b[32];CC_SHA256(data.bytes,(CC_LONG)data.length,b);NSMutableString *s=[NSMutableString stringWithCapacity:64];for(int i=0;i<32;i++)[s appendFormat:@"%02x",b[i]];return s;}
static BOOL ODRMExec(sqlite3 *db,const char *s){return sqlite3_exec(db,s,NULL,NULL,NULL)==SQLITE_OK;}
static BOOL ODRMBind(sqlite3_stmt *s,NSArray *values){if(sqlite3_bind_parameter_count(s)!=(int)values.count)return NO;int i=1;for(id v in values){int rc;if(v==NSNull.null)rc=sqlite3_bind_null(s,i);else if([v isKindOfClass:NSString.class])rc=sqlite3_bind_text(s,i,[v UTF8String],-1,SQLITE_TRANSIENT);else if([v isKindOfClass:NSData.class])rc=sqlite3_bind_blob(s,i,[v bytes],(int)[v length],SQLITE_TRANSIENT);else if(ODRMInteger(v))rc=sqlite3_bind_int64(s,i,[v longLongValue]);else if([v isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)v)!=CFBooleanGetTypeID()&&isfinite([v doubleValue]))rc=sqlite3_bind_double(s,i,[v doubleValue]);else return NO;if(rc!=SQLITE_OK)return NO;i++;}return YES;}
static id ODRMValue(sqlite3_stmt *s,int i){switch(sqlite3_column_type(s,i)){case SQLITE_INTEGER:return @(sqlite3_column_int64(s,i));case SQLITE_FLOAT:return @(sqlite3_column_double(s,i));case SQLITE_TEXT:return [NSString stringWithUTF8String:(const char *)sqlite3_column_text(s,i)]?:NSNull.null;case SQLITE_BLOB:return [NSData dataWithBytes:sqlite3_column_blob(s,i) length:(NSUInteger)sqlite3_column_bytes(s,i)];default:return NSNull.null;}}
static NSArray *ODRMQuery(sqlite3 *db,NSString *sql,NSArray *values){sqlite3_stmt *s=NULL;if(sqlite3_prepare_v2(db,sql.UTF8String,-1,&s,NULL)!=SQLITE_OK)return nil;if(!ODRMBind(s,values)){sqlite3_finalize(s);return nil;}NSMutableArray *out=[NSMutableArray array];int rc;while((rc=sqlite3_step(s))==SQLITE_ROW){if(out.count>=50000){sqlite3_finalize(s);return nil;}NSMutableDictionary *row=[NSMutableDictionary dictionary];for(int i=0;i<sqlite3_column_count(s);i++)row[[NSString stringWithUTF8String:sqlite3_column_name(s,i)]]=ODRMValue(s,i);[out addObject:row];}sqlite3_finalize(s);return rc==SQLITE_DONE?out:nil;}
static BOOL ODRMWrite(sqlite3 *db,NSString *sql,NSArray *values){sqlite3_stmt *s=NULL;if(sqlite3_prepare_v2(db,sql.UTF8String,-1,&s,NULL)!=SQLITE_OK)return NO;BOOL ok=ODRMBind(s,values)&&sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);return ok;}
static BOOL ODRMFile(NSURL *url){return url.isFileURL&&[url.path isEqual:url.URLByResolvingSymlinksInPath.path]&&url.path.isAbsolutePath;}
static BOOL ODRMHashFile(NSURL *url,NSString *expected,struct stat *info){int fd=open(url.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_NONBLOCK);if(fd<0)return NO;struct stat before={0},after={0};BOOL ok=fstat(fd,&before)==0&&S_ISREG(before.st_mode)&&before.st_size>16&&before.st_size<=2LL*1024*1024*1024;CC_SHA256_CTX ctx;CC_SHA256_Init(&ctx);unsigned char buf[65536];ssize_t n=0;while(ok&&(n=read(fd,buf,sizeof(buf)))>0)CC_SHA256_Update(&ctx,buf,(CC_LONG)n);if(n<0)ok=NO;unsigned char hash[32];CC_SHA256_Final(hash,&ctx);ok=ok&&fstat(fd,&after)==0&&before.st_dev==after.st_dev&&before.st_ino==after.st_ino&&before.st_size==after.st_size&&before.st_mtimespec.tv_sec==after.st_mtimespec.tv_sec&&before.st_mtimespec.tv_nsec==after.st_mtimespec.tv_nsec;close(fd);NSMutableString *hex=[NSMutableString stringWithCapacity:64];for(int i=0;i<32;i++)[hex appendFormat:@"%02x",hash[i]];if(info)*info=before;return ok&&[hex isEqual:expected];}

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
    if(![project isKindOfClass:NSDictionary.class]||![definition isKindOfClass:NSDictionary.class]||![project[@"format"] isEqual:@"dokkan-unit-forge"]||![project[@"version"] isEqual:@1]||project[@"awaken"]||definition[@"stat_policy"]||definition[@"progression_policy"])return NO;
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
- (NSDictionary *)compileAcceptedPacket:(NSDictionary *)packet error:(NSError **)error {
    if(![packet isKindOfClass:NSDictionary.class]||![packet[@"binding"] isKindOfClass:NSDictionary.class]){if(error)*error=ODRMError(@"RUNTIME_ACCEPTED_RECEIPT_MISMATCH");return nil;}
    NSString *failure=@"RUNTIME_COMPILATION_FAILED";NSDictionary *binding=packet[@"binding"];NSData *projectBytes=packet[@"project_bytes"],*definitionBytes=packet[@"definition_bytes"];
    NSSet *fields=[NSSet setWithArray:@[@"format",@"content_id",@"save_scope",@"definition_id",@"version",@"project_sha256",@"definition_sha256",@"instance_id",@"accepted"]];
    BOOL acceptedBool=[binding[@"accepted"] isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)binding[@"accepted"])==CFBooleanGetTypeID()&&[binding[@"accepted"] boolValue];
    if(![binding isKindOfClass:NSDictionary.class]||![[NSSet setWithArray:binding.allKeys] isEqual:fields]||![binding[@"format"] isEqual:@"od-accepted-creator-project-v1"]||!acceptedBool||![binding[@"content_id"] isEqual:_content]||![binding[@"save_scope"] isEqual:_scope]||!ODRMName(binding[@"definition_id"])||!ODRMInteger(binding[@"version"])||[binding[@"version"] longLongValue]<1||!ODRMInteger(binding[@"instance_id"])||[binding[@"instance_id"] longLongValue]<1||![projectBytes isKindOfClass:NSData.class]||!projectBytes.length||projectBytes.length>20*1024*1024||![definitionBytes isKindOfClass:NSData.class]||!definitionBytes.length||definitionBytes.length>16*1024*1024||!ODRMHex(binding[@"project_sha256"])||!ODRMHex(binding[@"definition_sha256"])||![ODRMHash(projectBytes) isEqual:binding[@"project_sha256"]]||![ODRMHash(definitionBytes) isEqual:binding[@"definition_sha256"]]){if(error)*error=ODRMError(@"RUNTIME_ACCEPTED_RECEIPT_MISMATCH");return nil;}
    NSDictionary *project=[NSJSONSerialization JSONObjectWithData:projectBytes options:0 error:nil],*definition=[NSJSONSerialization JSONObjectWithData:definitionBytes options:0 error:nil];
    if(![self blueprint:project definition:definition]||![binding[@"definition_id"] isEqual:definition[@"definition_id"]]||![binding[@"version"] isEqual:definition[@"version"]]){if(error)*error=ODRMError(@"RUNTIME_DEFINITION_PROJECT_MISMATCH");return nil;}
    NSURL *parent=_derived.URLByDeletingLastPathComponent;if(![NSFileManager.defaultManager createDirectoryAtURL:parent withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions:@0700} error:nil]){if(error)*error=ODRMError(@"RUNTIME_PATH_UNSAFE");return nil;}
    NSURL *lock=[NSURL fileURLWithPath:[_derived.path stringByAppendingString:@".lock"]];int lockFD=open(lock.fileSystemRepresentation,O_CREAT|O_WRONLY|O_NOFOLLOW,0600);struct stat lockInfo;
    if(lockFD<0||fstat(lockFD,&lockInfo)||!S_ISREG(lockInfo.st_mode)||(lockInfo.st_mode&0077)||flock(lockFD,LOCK_EX|LOCK_NB)){if(lockFD>=0)close(lockFD);if(error)*error=ODRMError(@"RUNTIME_COMPILER_BUSY");return nil;}
    sqlite3 *source=NULL,*db=NULL;NSURL *temp=nil;NSDictionary *receipt=nil;struct stat original={0},prior={0};BOOL existing=lstat(_derived.fileSystemRepresentation,&prior)==0;
    @try {
        if(!ODRMFile(_master)||!ODRMFile(_derived)||(existing&&(!S_ISREG(prior.st_mode)||(prior.st_mode&0077)))||!ODRMHashFile(_master,_sourceSHA,&original)){failure=@"RUNTIME_SOURCE_OR_PATH_MISMATCH";@throw failure;}
        if(existing&&prior.st_dev==original.st_dev&&prior.st_ino==original.st_ino){failure=@"RUNTIME_SOURCE_ALIAS";@throw failure;}
        if(sqlite3_open_v2(_master.fileSystemRepresentation,&source,SQLITE_OPEN_READONLY|SQLITE_OPEN_NOFOLLOW,NULL)!=SQLITE_OK||sqlite3_db_readonly(source,"main")!=1||!ODRMExec(source,"PRAGMA query_only=ON;PRAGMA trusted_schema=OFF")){failure=@"RUNTIME_SOURCE_OPEN_FAILED";@throw failure;}
        if(![self omittedRows:project definition:definition source:source]){failure=@"RUNTIME_UNADMITTED_ROW";@throw failure;}
        temp=[parent URLByAppendingPathComponent:[NSString stringWithFormat:@".runtime-%@.db",NSUUID.UUID.UUIDString]];int tempFD=open(temp.fileSystemRepresentation,O_CREAT|O_EXCL|O_WRONLY|O_NOFOLLOW,0600);if(tempFD<0)@throw failure;close(tempFD);
        if(sqlite3_open_v2(temp.fileSystemRepresentation,&db,SQLITE_OPEN_READWRITE|SQLITE_OPEN_NOFOLLOW,NULL)!=SQLITE_OK)@throw failure;
        sqlite3 *base=source,*previous=NULL;if(existing){if(sqlite3_open_v2(_derived.fileSystemRepresentation,&previous,SQLITE_OPEN_READONLY|SQLITE_OPEN_NOFOLLOW,NULL)!=SQLITE_OK){sqlite3_close(previous);@throw failure;}base=previous;}
        sqlite3_backup *backup=sqlite3_backup_init(db,"main",base,"main");int rc=backup?sqlite3_backup_step(backup,-1):SQLITE_ERROR;int finish=backup?sqlite3_backup_finish(backup):SQLITE_ERROR;sqlite3_close(previous);if(rc!=SQLITE_DONE||finish!=SQLITE_OK)@throw failure;
        if(!ODRMExec(db,"PRAGMA synchronous=FULL;PRAGMA foreign_keys=ON;PRAGMA trusted_schema=OFF;BEGIN IMMEDIATE")||![self metadata:db existing:existing]){failure=@"RUNTIME_IDENTITY_MISMATCH";@throw failure;}
        NSArray *old=ODRMQuery(db,@"SELECT project_sha256,definition_sha256,accepted_binding,receipt FROM od_runtime_versions WHERE definition_id=? AND version=?",@[binding[@"definition_id"],binding[@"version"]]);if(!old)@throw failure;
        if(old.count){NSDictionary *row=old[0];NSData *ab=[row[@"accepted_binding"] dataUsingEncoding:NSUTF8StringEncoding];id previousBinding=[NSJSONSerialization JSONObjectWithData:ab options:0 error:nil];if(![row[@"project_sha256"] isEqual:binding[@"project_sha256"]]||![row[@"definition_sha256"] isEqual:binding[@"definition_sha256"]]||![previousBinding isEqual:binding]){failure=@"RUNTIME_VERSION_CONFLICT";@throw failure;}receipt=[NSJSONSerialization JSONObjectWithData:[row[@"receipt"] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];if(![receipt isKindOfClass:NSDictionary.class])@throw failure;}
        else {
            NSArray *used=ODRMQuery(db,@"SELECT runtime_id FROM od_runtime_versions ORDER BY runtime_id",@[]);if(!used||used.count>2000)@throw failure;NSMutableArray *reservations=[NSMutableArray array];for(NSDictionary *r in used)[reservations addObject:@{@"key":[NSString stringWithFormat:@"reserved-%@",r[@"runtime_id"]],@"targetId":r[@"runtime_id"]}];
            NSDictionary *result=nil;NSInteger floor=97000001;while(floor<=98999001){result=[_compiler materializeAcceptedProject:project runtimeIDs:@[@(floor)] reservations:reservations floor:floor error:nil];if(!result)@throw failure;id next=result[@"next"];if(!ODRMInteger(next)||[next longLongValue]<floor||[next longLongValue]>98999001||[next longLongValue]%1000!=1)@throw failure;NSInteger candidate=[next integerValue];if(candidate!=floor){result=[_compiler materializeAcceptedProject:project runtimeIDs:@[@(candidate)] reservations:reservations floor:candidate error:nil];if(!result)@throw failure;}NSInteger admission=[self admitRows:result[@"tables"] database:db];if(admission<0){failure=@"RUNTIME_ROW_SCHEMA_MISMATCH";@throw failure;}if(admission==1)break;floor=candidate+1000;result=nil;}
            if(!result){failure=@"RUNTIME_PRIVATE_BLOCKS_FULL";@throw failure;}
            if(![self insertRows:result[@"tables"] binding:binding database:db]||![self references:result database:db]){failure=@"RUNTIME_REFERENCE_OR_INSERT_FAILED";@throw failure;}
            NSNumber *runtimeID=[result[@"runtimeIds"] firstObject];receipt=@{@"definition_id":binding[@"definition_id"],@"version":binding[@"version"],@"runtime_card_id":runtimeID,@"project_sha256":binding[@"project_sha256"],@"definition_sha256":binding[@"definition_sha256"],@"content_id":_content,@"save_scope":_scope,@"accepted_instance_id":binding[@"instance_id"],@"original_client_attached":@NO,@"resource_admission_complete":@NO};
            NSString *bindingJSON=[[NSString alloc]initWithData:ODRMJSON(binding) encoding:NSUTF8StringEncoding],*receiptJSON=[[NSString alloc]initWithData:ODRMJSON(receipt) encoding:NSUTF8StringEncoding];if(!bindingJSON||!receiptJSON||!ODRMWrite(db,@"INSERT INTO od_runtime_versions VALUES(?,?,?,?,?,?,?,?,?)",@[binding[@"definition_id"],binding[@"version"],binding[@"project_sha256"],binding[@"definition_sha256"],runtimeID,projectBytes,definitionBytes,bindingJSON,receiptJSON])||!ODRMExec(db,"COMMIT"))@throw failure;
            sqlite3_close(db);db=NULL;struct stat after={0},now={0};if(stat(_master.fileSystemRepresentation,&after)||after.st_dev!=original.st_dev||after.st_ino!=original.st_ino||after.st_size!=original.st_size||after.st_mtimespec.tv_sec!=original.st_mtimespec.tv_sec||after.st_mtimespec.tv_nsec!=original.st_mtimespec.tv_nsec){failure=@"RUNTIME_SOURCE_CHANGED";@throw failure;}
            int status=lstat(_derived.fileSystemRepresentation,&now);if((existing&&(status||now.st_dev!=prior.st_dev||now.st_ino!=prior.st_ino||now.st_size!=prior.st_size||now.st_mtimespec.tv_sec!=prior.st_mtimespec.tv_sec||now.st_mtimespec.tv_nsec!=prior.st_mtimespec.tv_nsec))||(!existing&&status==0)){failure=@"RUNTIME_CONCURRENT_REPLACEMENT";@throw failure;}
            int persisted=open(temp.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW);if(persisted<0)@throw failure;BOOL durable=fsync(persisted)==0;close(persisted);if(!durable||chmod(temp.fileSystemRepresentation,0400)||rename(temp.fileSystemRepresentation,_derived.fileSystemRepresentation))@throw failure;temp=nil;int directory=open(parent.fileSystemRepresentation,O_RDONLY|O_DIRECTORY);if(directory<0)@throw failure;durable=fsync(directory)==0;close(directory);if(!durable)@throw failure;
        }
    } @catch(id ignored) {(void)ignored;receipt=nil;if(error)*error=ODRMError(failure);} @finally {sqlite3_close(db);sqlite3_close(source);if(temp)[NSFileManager.defaultManager removeItemAtURL:temp error:nil];flock(lockFD,LOCK_UN);close(lockFD);}
    return receipt;
}
@end
