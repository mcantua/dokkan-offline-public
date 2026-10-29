#import "ODNativeFullCreatorValidator.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreFoundation/CoreFoundation.h>
#include "sqlite3.h"
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <math.h>
#include <errno.h>
#include <stdio.h>
static NSError *ODFBError(NSString *code){return [NSError errorWithDomain:@"OfflineDokkan.FullCreator" code:1 userInfo:@{NSLocalizedDescriptionKey:code}];}
static BOOL ODFBHex(NSString *s){return [s isKindOfClass:NSString.class]&&s.length==64&&[s rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet]].location==NSNotFound;}
static BOOL ODFBName(NSString *s){return [s isKindOfClass:NSString.class]&&s.length>0&&s.length<=100&&[s rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.:-"] invertedSet]].location==NSNotFound;}
static BOOL ODFBInt(id v){return [v isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)v)!=CFBooleanGetTypeID()&&isfinite([v doubleValue])&&[v doubleValue]==[v longLongValue]&&fabs([v doubleValue])<=9007199254740991.0;}
static BOOL ODFBPath(NSString *s){if(![s isKindOfClass:NSString.class]||!s.length||s.length>500||[s hasPrefix:@"/"]||[s rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\\:\000\r\n"]].location!=NSNotFound)return NO;for(NSString *part in [s componentsSeparatedByString:@"/"])if(!part.length||[part isEqual:@"."]||[part isEqual:@".."])return NO;return YES;}
static NSString *ODFBQuote(NSString *s){if(![s isKindOfClass:NSString.class]||!s.length||s.length>100)return nil;NSCharacterSet *set=[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"];if([s rangeOfCharacterFromSet:set.invertedSet].location!=NSNotFound||![[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"] characterIsMember:[s characterAtIndex:0]])return nil;return [NSString stringWithFormat:@"\"%@\"",s];}
static NSString *ODFBHash(NSData *d){unsigned char hash[32];CC_SHA256(d.bytes,(CC_LONG)d.length,hash);NSMutableString *s=[NSMutableString stringWithCapacity:64];for(int i=0;i<32;i++)[s appendFormat:@"%02x",hash[i]];return s;}
static id ODFBValue(sqlite3_stmt *s,int i){switch(sqlite3_column_type(s,i)){case SQLITE_INTEGER:return @(sqlite3_column_int64(s,i));case SQLITE_FLOAT:return @(sqlite3_column_double(s,i));case SQLITE_TEXT:return [NSString stringWithUTF8String:(const char *)sqlite3_column_text(s,i)]?:NSNull.null;default:return NSNull.null;}}
static NSArray *ODFBRows(sqlite3 *db,NSString *sql,NSNumber *arg){sqlite3_stmt *s=NULL;if(sqlite3_prepare_v2(db,sql.UTF8String,-1,&s,NULL)!=SQLITE_OK)return nil;if(arg&&sqlite3_bind_int64(s,1,arg.longLongValue)!=SQLITE_OK){sqlite3_finalize(s);return nil;}NSMutableArray *out=[NSMutableArray array];int rc;while((rc=sqlite3_step(s))==SQLITE_ROW){if(out.count>=50000){sqlite3_finalize(s);return nil;}NSMutableDictionary *r=[NSMutableDictionary dictionary];for(int i=0;i<sqlite3_column_count(s);i++)r[[NSString stringWithUTF8String:sqlite3_column_name(s,i)]]=ODFBValue(s,i);[out addObject:r];}sqlite3_finalize(s);return rc==SQLITE_DONE?out:nil;}
static BOOL ODFBSameFile(struct stat a,struct stat b){return a.st_dev==b.st_dev&&a.st_ino==b.st_ino&&a.st_size==b.st_size&&a.st_mtimespec.tv_sec==b.st_mtimespec.tv_sec&&a.st_mtimespec.tv_nsec==b.st_mtimespec.tv_nsec;}
@implementation ODNativeFullCreatorValidator {
    JSContext *_js;NSURL *_master,*_root;NSString *_content,*_profile,*_scope;ODFullCreatorOpenAsset _openAsset;
}
- (instancetype)initWithCreatorCoreURL:(NSURL *)core sparkingDependenciesURL:(NSURL *)dependencies masterURL:(NSURL *)master immutableResourceRoot:(NSURL *)resourceRoot contentID:(NSString *)content profileID:(NSString *)profile saveScope:(NSString *)scope openAsset:(ODFullCreatorOpenAsset)openAsset error:(NSError **)error {
    if(!(self=[super init]))return nil;
    NSString *hash=[content isKindOfClass:NSString.class]?[[content componentsSeparatedByString:@":"] lastObject]:nil;
    BOOL validContent=[content isKindOfClass:NSString.class]&&([content hasPrefix:@"sha256:"]||[content hasPrefix:@"sparking:sha256:"]||[content hasPrefix:@"eclipse:sha256:"])&&ODFBHex(hash);
    if(!validContent||!ODFBName(profile)||!ODFBHex(scope)||!core.isFileURL||!dependencies.isFileURL||!master.isFileURL||!resourceRoot.isFileURL){if(error)*error=ODFBError(@"FULL_BUNDLE_NATIVE_CONTEXT_INVALID");return nil;}
    _master=master.URLByResolvingSymlinksInPath;_root=resourceRoot.URLByResolvingSymlinksInPath;_content=[content copy];_profile=[profile copy];_scope=[scope copy];_openAsset=[openAsset copy];
    NSData *c=[NSData dataWithContentsOfURL:core options:NSDataReadingMappedIfSafe error:nil],*d=[NSData dataWithContentsOfURL:dependencies options:NSDataReadingMappedIfSafe error:nil];
    if(!c.length||c.length>1024*1024||!d.length||d.length>1024*1024){if(error)*error=ODFBError(@"FULL_BUNDLE_CREATOR_CODE_INVALID");return nil;}
    NSString *cs=[[NSString alloc]initWithData:c encoding:NSUTF8StringEncoding],*ds=[[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding];if(!cs||!ds){if(error)*error=ODFBError(@"FULL_BUNDLE_CREATOR_CODE_INVALID");return nil;}
    _js=[JSContext new];[_js evaluateScript:ds];if(!_js.exception)[_js evaluateScript:cs];
    [_js evaluateScript:@"globalThis.ODFullInspect=function(text,stamp){const RealDate=Date;globalThis.Date=class extends RealDate{constructor(...a){super(...(a.length?a:[stamp]));}static now(){return stamp;}};try{const p=JSON.parse(text),v=Forge.validate(p);if(v.errors.length)throw Error('FULL_BUNDLE_FORGE_REJECTED');const m=[p,...p.formProjects||[]];return {project:p,card:Forge.card(p),tables:Forge.materializeAll(p),entries:Forge.exportEntries(p),members:m.map(x=>({key:x.key,source:x.source,runtime_card_id:x.targetId})),source_dependencies:m.filter(x=>x.sourceDependencies).map(x=>({member_key:x.key,bundle:x.sourceDependencies})),shared_actions:m.filter(x=>x.actionHooks?.dodge).map(x=>({member_key:x.key,settings:x.actionHooks.dodge,generated_files:(x.generatedFiles||[]).filter(f=>f.owner==='dodge:unit')})),transform_links:p.transformLinks||[]};}finally{globalThis.Date=RealDate;}};"];
    if(_js.exception||![_js[@"ODFullInspect"] isObject]){if(error)*error=ODFBError(@"FULL_BUNDLE_CREATOR_CODE_INVALID");return nil;}
    if(![NSFileManager.defaultManager createDirectoryAtURL:_root withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions:@0700} error:nil]){if(error)*error=ODFBError(@"FULL_BUNDLE_CAPTURE_ROOT_INVALID");return nil;}
    return self;
}
- (NSDictionary *)captureFD:(int)source error:(NSError **)error {
    if(source<0){if(error)*error=ODFBError(@"FULL_BUNDLE_RESOURCE_UNAVAILABLE");return nil;}
    struct stat before={0},after={0};int flags=fcntl(source,F_GETFL);BOOL ok=flags>=0&&(flags&O_ACCMODE)==O_RDONLY&&fstat(source,&before)==0&&S_ISREG(before.st_mode)&&before.st_size>0&&before.st_size<=96LL*1024*1024;
    NSURL *temp=[_root URLByAppendingPathComponent:[NSString stringWithFormat:@".capture-%@",NSUUID.UUID.UUIDString]];int dest=ok?open(temp.fileSystemRepresentation,O_CREAT|O_EXCL|O_WRONLY|O_NOFOLLOW,0600):-1;if(dest<0)ok=NO;
    CC_SHA256_CTX state;CC_SHA256_Init(&state);unsigned char buf[65536],hash[32];ssize_t n=0;int64_t count=0;
    while(ok&&(n=read(source,buf,sizeof(buf)))>0){count+=n;if(count>before.st_size){ok=NO;break;}CC_SHA256_Update(&state,buf,(CC_LONG)n);ssize_t offset=0;while(offset<n){ssize_t wrote=write(dest,buf+offset,(size_t)(n-offset));if(wrote<=0){ok=NO;break;}offset+=wrote;}}
    if(n<0||count!=before.st_size)ok=NO;CC_SHA256_Final(hash,&state);ok=ok&&fstat(source,&after)==0&&ODFBSameFile(before,after);close(source);if(dest>=0){if(fsync(dest))ok=NO;close(dest);}
    NSMutableString *sha=[NSMutableString stringWithCapacity:64];for(int i=0;i<32;i++)[sha appendFormat:@"%02x",hash[i]];
    NSURL *blob=[_root URLByAppendingPathComponent:sha];struct stat stored={0};
    if(ok&&link(temp.fileSystemRepresentation,blob.fileSystemRepresentation)){if(errno!=EEXIST||lstat(blob.fileSystemRepresentation,&stored)||!S_ISREG(stored.st_mode)||stored.st_size!=count||(stored.st_mode&0222))ok=NO;}
    if(ok&&chmod(blob.fileSystemRepresentation,0400))ok=NO;
    [NSFileManager.defaultManager removeItemAtURL:temp error:nil];
    if(!ok){if(error)*error=ODFBError(@"FULL_BUNDLE_RESOURCE_CHANGED_OR_UNSAFE");return nil;}
    int dir=open(_root.fileSystemRepresentation,O_RDONLY|O_DIRECTORY);if(dir<0||fsync(dir)){if(dir>=0)close(dir);if(error)*error=ODFBError(@"FULL_BUNDLE_CAPTURE_NOT_DURABLE");return nil;}close(dir);
    return @{@"sha256":sha,@"size":@(count)};
}
- (NSDictionary *)captureText:(NSString *)text error:(NSError **)error {
    NSData *bytes=[text dataUsingEncoding:NSUTF8StringEncoding];if(!bytes.length||bytes.length>2*1024*1024){if(error)*error=ODFBError(@"FULL_BUNDLE_GENERATED_TEXT_INVALID");return nil;}
    NSURL *temp=[_root URLByAppendingPathComponent:[NSString stringWithFormat:@".text-%@",NSUUID.UUID.UUIDString]];
    if(![bytes writeToURL:temp options:NSDataWritingWithoutOverwriting error:nil]){if(error)*error=ODFBError(@"FULL_BUNDLE_CAPTURE_FAILED");return nil;}
    chmod(temp.fileSystemRepresentation,0600);int fd=open(temp.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW);NSDictionary *result=[self captureFD:fd error:error];[NSFileManager.defaultManager removeItemAtURL:temp error:nil];return result;
}
- (NSDictionary *)captureAsset:(NSString *)key cache:(NSMutableDictionary *)cache error:(NSError **)error {
    if(!ODFBPath(key)||!_openAsset){if(error)*error=ODFBError(@"FULL_BUNDLE_NATIVE_ASSET_CAPABILITY_REQUIRED");return nil;}
    if(cache[key])return cache[key];NSDictionary *result=[self captureFD:_openAsset(key,error) error:error];if(result)cache[key]=result;return result;
}
- (BOOL)rows:(NSDictionary *)tables source:(sqlite3 *)db error:(NSError **)error {
    if(![tables isKindOfClass:NSDictionary.class])return NO;NSUInteger count=0;
    for(NSString *table in tables){NSString *q=ODFBQuote(table);NSArray *rows=tables[table];if(!q||![rows isKindOfClass:NSArray.class])return NO;NSArray *columns=ODFBRows(db,[NSString stringWithFormat:@"PRAGMA table_info(%@)",q],nil);NSMutableDictionary *schema=[NSMutableDictionary dictionary];for(NSDictionary *c in columns)schema[c[@"name"]]=c;if(!schema.count)return NO;
        NSMutableSet *ids=[NSMutableSet set];for(NSDictionary *row in rows){if(++count>50000||![row isKindOfClass:NSDictionary.class]||!ODFBInt(row[@"id"])||[row[@"id"] longLongValue]<1||[ids containsObject:row[@"id"]])return NO;[ids addObject:row[@"id"]];
            for(NSString *name in schema){NSDictionary *c=schema[name];if(([c[@"notnull"] boolValue]||[c[@"pk"] boolValue])&&!row[name]&&c[@"dflt_value"]==NSNull.null)return NO;}
            for(NSString *name in row){id v=row[name];NSDictionary *c=schema[name];NSString *type=[c[@"type"] uppercaseString];if(!c)return NO;if(v==NSNull.null){if([c[@"notnull"] boolValue]||[c[@"pk"] boolValue])return NO;continue;}if([type containsString:@"INT"]&&!ODFBInt(v))return NO;if(([type containsString:@"CHAR"]||[type containsString:@"TEXT"]||[type containsString:@"JSON"]||[type containsString:@"DATE"])&&![v isKindOfClass:NSString.class])return NO;if([v isKindOfClass:NSString.class]){if([v lengthOfBytesUsingEncoding:NSUTF8StringEncoding]>1024*1024||[v rangeOfString:[NSString stringWithFormat:@"%C",(unichar)0]].location!=NSNotFound)return NO;}else if(![v isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)v)==CFBooleanGetTypeID()||!isfinite([v doubleValue]))return NO;}
            NSArray *existing=ODFBRows(db,[NSString stringWithFormat:@"SELECT id FROM %@ WHERE id=?",q],row[@"id"]);if(!existing||existing.count){if(error)*error=ODFBError(@"FULL_BUNDLE_SOURCE_COLLISION_RESERVE_NEW_SLOT");return NO;}
        }
    }return YES;
}
- (NSDictionary *)validateProjectBytes:(NSData *)bytes context:(NSDictionary *)context error:(NSError **)error {
    if(![bytes isKindOfClass:NSData.class]||!bytes.length||bytes.length>20*1024*1024||![context isKindOfClass:NSDictionary.class]||!ODFBName(context[@"definitionId"])||!ODFBInt(context[@"version"])||[context[@"version"] longLongValue]<1||!ODFBInt(context[@"materializationUTC"])||[context[@"materializationUTC"] longLongValue]<0||[context[@"materializationUTC"] longLongValue]>253402300799000LL){if(error)*error=ODFBError(@"FULL_BUNDLE_NATIVE_CONTEXT_INVALID");return nil;}
    NSString *text=[[NSString alloc]initWithData:bytes encoding:NSUTF8StringEncoding];if(!text){if(error)*error=ODFBError(@"FULL_BUNDLE_PROJECT_INVALID");return nil;}
    _js.exception=nil;JSValue *inspected=[_js[@"ODFullInspect"] callWithArguments:@[text,context[@"materializationUTC"]]];NSDictionary *result=[inspected toDictionary];
    if(_js.exception||![result isKindOfClass:NSDictionary.class]){_js.exception=nil;if(error)*error=ODFBError(@"FULL_BUNDLE_FORGE_VALIDATION_FAILED");return nil;}
    NSDictionary *project=result[@"project"];NSArray *members=result[@"members"];
    if(project[@"awaken"]||members.count<1||members.count>5){if(error)*error=ODFBError(@"FULL_BUNDLE_PROJECT_INVALID");return nil;}
    sqlite3 *db=NULL;if(sqlite3_open_v2(_master.fileSystemRepresentation,&db,SQLITE_OPEN_READONLY|SQLITE_OPEN_NOFOLLOW,NULL)!=SQLITE_OK){sqlite3_close(db);if(error)*error=ODFBError(@"FULL_BUNDLE_MASTER_UNAVAILABLE");return nil;}
    sqlite3_exec(db,"PRAGMA query_only=ON;PRAGMA trusted_schema=OFF;BEGIN",NULL,NULL,NULL);BOOL valid=YES;NSDictionary *base=nil;
    for(NSDictionary *m in members){NSDictionary *source=m[@"source"];NSNumber *id=source[@"cardId"];NSString *game=[_content hasPrefix:@"sparking:"]?@"sparking":[_content hasPrefix:@"eclipse:"]?@"eclipse":project[@"source"][@"database"];
        if(!ODFBInt(id)||![source[@"contentId"] isEqual:_content]||![source[@"database"] isEqual:game]){valid=NO;break;}
        NSArray *card=ODFBRows(db,@"SELECT * FROM cards WHERE id=?",id),*routes=ODFBRows(db,@"SELECT type,awaked_card_id FROM card_awakening_routes WHERE card_id=?",id);if(card.count!=1||!routes){valid=NO;break;}if(!base)base=card[0];for(NSDictionary *r in routes)if(([@[@"CardAwakeningRoute::Dokkan",@"CardAwakeningRoute::Zet"] containsObject:r[@"type"]])&&![r[@"awaked_card_id"] isEqual:id])valid=NO;
    }
    if(valid)valid=[self rows:result[@"tables"] source:db error:error];sqlite3_exec(db,"ROLLBACK",NULL,NULL,NULL);sqlite3_close(db);if(!valid){if(error&&!*error)*error=ODFBError(@"FULL_BUNDLE_SOURCE_SCHEMA_OR_ELIGIBILITY_FAILED");return nil;}
    NSMutableArray *resources=[NSMutableArray array];NSMutableDictionary *cache=[NSMutableDictionary dictionary];NSMutableSet *destinations=[NSMutableSet set];
    for(NSDictionary *entry in result[@"entries"]){NSString *path=entry[@"path"];if(!ODFBPath(path)){if(error)*error=ODFBError(@"FULL_BUNDLE_RESOURCE_PATH_INVALID");return nil;}if(![path hasPrefix:@"files/"]||[path hasSuffix:@".sql"])continue;NSString *destination=[path substringFromIndex:6],*normalized=[destination precomposedStringWithCanonicalMapping].lowercaseString;if(!ODFBPath(destination)||[destinations containsObject:normalized]){if(error)*error=ODFBError(@"FULL_BUNDLE_RESOURCE_COLLISION");return nil;}[destinations addObject:normalized];
        NSMutableDictionary *r=[@{@"path":destination} mutableCopy];if(entry[@"assetKey"]){NSDictionary *blob=[self captureAsset:entry[@"assetKey"] cache:cache error:error];if(!blob)return nil;[r addEntriesFromDictionary:blob];r[@"kind"]=@"captured-asset";}
        else if(entry[@"text"]){NSDictionary *blob=[self captureText:entry[@"text"] error:error];if(!blob)return nil;[r addEntriesFromDictionary:blob];r[@"kind"]=@"captured-generated-text";}
        else if([entry[@"cpk"] isKindOfClass:NSArray.class]){NSMutableArray *entries=[NSMutableArray array];for(NSDictionary *inner in entry[@"cpk"]){if(!ODFBPath(inner[@"path"])){if(error)*error=ODFBError(@"FULL_BUNDLE_CPK_ENTRY_INVALID");return nil;}NSDictionary *blob=[self captureAsset:inner[@"assetKey"] cache:cache error:error];if(!blob)return nil;NSMutableDictionary *item=[blob mutableCopy];item[@"path"]=inner[@"path"];[entries addObject:item];}r[@"kind"]=@"captured-cpk-inputs-build-pending";r[@"entries"]=entries;}
        else {if(error)*error=ODFBError(@"FULL_BUNDLE_RESOURCE_ENTRY_INVALID");return nil;}[resources addObject:r];
    }
    for(NSDictionary *shared in result[@"shared_actions"])for(NSDictionary *file in shared[@"generated_files"]){NSDictionary *blob=[self captureText:file[@"text"] error:error];if(!blob)return nil;NSMutableDictionary *r=[blob mutableCopy];r[@"path"]=file[@"path"];r[@"kind"]=@"captured-shared-action-installation-pending";[resources addObject:r];}
    NSString *projectSHA=ODFBHash(bytes);NSDictionary *identity=@{@"format":@"od-native-creator-full-bundle-v2",@"content_id":_content,@"profile_id":_profile,@"save_scope":_scope,@"definition_id":context[@"definitionId"],@"version":context[@"version"],@"project_sha256":projectSHA,@"materialization_utc":context[@"materializationUTC"],@"resources":resources,@"engine_admission":@"pending-master-cipher-resource-and-form-progression-binding"};
    _js[@"__odFullInspected"]=inspected;_js[@"__odFullIdentity"]=identity;
    NSString *bundleJSON=[[_js evaluateScript:@"JSON.stringify({...__odFullIdentity,tables:__odFullInspected.tables,members:__odFullInspected.members,transform_links:__odFullInspected.transform_links,source_dependencies:__odFullInspected.source_dependencies,shared_actions:__odFullInspected.shared_actions})"] toString];_js[@"__odFullInspected"]=nil;_js[@"__odFullIdentity"]=nil;
    NSData *bundleBytes=[bundleJSON dataUsingEncoding:NSUTF8StringEncoding];if(_js.exception||!bundleBytes.length||bundleBytes.length>64*1024*1024){_js.exception=nil;if(error)*error=ODFBError(@"FULL_BUNDLE_MATERIALIZATION_FAILED");return nil;}NSString *bundleSHA=ODFBHash(bundleBytes);
    NSMutableDictionary *card=[base mutableCopy];NSDictionary *authored=result[@"card"];for(NSString *field in @[@"name",@"rarity",@"element",@"cost",@"lv_max",@"skill_lv_max",@"hp_init",@"hp_max",@"atk_init",@"atk_max",@"def_init",@"def_max"])if(authored[field])card[field]=authored[field];
    NSString *rarity=context[@"rarity"];if(![@[@"UR",@"LR",@"SLR",@"GR"] containsObject:rarity]){if(error)*error=ODFBError(@"FULL_BUNDLE_ROOT_RARITY_INVALID");return nil;}
    NSDictionary *binding=@{@"format":@"od-full-creator-binding-v2",@"projection":@"progression-root-v1",@"content_id":_content,@"profile_id":_profile,@"save_scope":_scope,@"definition_id":context[@"definitionId"],@"version":context[@"version"],@"project_sha256":projectSHA,@"full_bundle_sha256":bundleSHA,@"member_count":@(members.count)};
    NSMutableDictionary *definition=[@{@"format":@"offline-dokkan-definition",@"schema_version":@1,@"definition_id":context[@"definitionId"],@"version":context[@"version"],@"source":@{@"content_id":_content,@"master_id":base[@"id"]},@"rarity":rarity,@"fully_awakened":@YES,@"card":card,@"tables":@{},@"full_bundle":binding} mutableCopy];
    if([card[@"lv_max"] longLongValue]>150)definition[@"progression_policy"]=@"creator-lr-extended-v1";id policy=context[@"statPolicy"]?:project[@"statPolicy"];if(policy)definition[@"stat_policy"]=policy;
    if(context[@"creatorId"]||context[@"creatorName"]){if(!ODFBName(context[@"creatorId"])||![context[@"creatorName"] isKindOfClass:NSString.class]){if(error)*error=ODFBError(@"FULL_BUNDLE_CREATOR_CREDIT_INVALID");return nil;}definition[@"creator"]=@{@"id":context[@"creatorId"],@"name":context[@"creatorName"]};}
    return @{@"definition":definition,@"full_bundle_bytes":bundleBytes,@"full_bundle_sha256":bundleSHA,@"project_sha256":projectSHA,@"member_count":@(members.count),@"materialization_utc":context[@"materializationUTC"],@"resource_scope":_scope};
}
@end
