#import "ODBattleStore.h"
#import <CommonCrypto/CommonDigest.h>
#include "sqlite3.h"
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

static const NSUInteger ODBattleDataLimit=4*1024*1024;
static NSError *ODBattleError(NSString *code){return [NSError errorWithDomain:@"OfflineDokkanBattleStore" code:1 userInfo:@{NSLocalizedDescriptionKey:code}];}
static NSString *ODBattleHash(NSData *data){unsigned char bytes[32];CC_SHA256(data.bytes,(CC_LONG)data.length,bytes);NSMutableString *out=[NSMutableString stringWithCapacity:64];for(int i=0;i<32;i++)[out appendFormat:@"%02x",bytes[i]];return out;}
static BOOL ODBattleToken(id token){return [token isKindOfClass:NSString.class]&&[token length]>0&&[token length]<=256&&[token rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location==NSNotFound;}
@implementation ODBattleStore {NSURL *_directory;NSString *_source,*_content;sqlite3 *_db;}
- (instancetype)initWithDirectory:(NSURL *)directory source:(NSString *)source contentID:(NSString *)contentID {if((self=[super init])){_directory=[directory copy];_source=[source copy];_content=[contentID copy];}return self;}
- (void)dealloc {if(_db)sqlite3_close_v2(_db);}
- (BOOL)fail:(NSString *)code error:(NSError **)error {if(error)*error=ODBattleError(code);return NO;}
- (BOOL)open:(NSError **)error {
    if(_db)return YES;
    if(!_directory.isFileURL||![@[@"eclipse",@"sparking"] containsObject:_source]||!_content.length||_content.length>127)return [self fail:@"BATTLE_STORAGE_CONFIGURATION_INVALID" error:error];
    NSFileManager *files=NSFileManager.defaultManager;struct stat info;
    if(![files createDirectoryAtURL:_directory withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions:@0700,NSFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication} error:error]||lstat(_directory.fileSystemRepresentation,&info)||!S_ISDIR(info.st_mode)||S_ISLNK(info.st_mode)||info.st_uid!=geteuid())return [self fail:@"BATTLE_STORAGE_DIRECTORY_INVALID" error:error];
    NSURL *file=[_directory URLByAppendingPathComponent:@"current-battle.sqlite"];
    if(lstat(file.fileSystemRepresentation,&info)){
        if(errno!=ENOENT)return [self fail:@"BATTLE_STORAGE_FILE_INVALID" error:error];
        int fd=open(file.fileSystemRepresentation,O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW,0600);
        if(fd<0&&errno!=EEXIST)return [self fail:@"BATTLE_STORAGE_FILE_INVALID" error:error];if(fd>=0)close(fd);
    }
    if(lstat(file.fileSystemRepresentation,&info)||!S_ISREG(info.st_mode)||S_ISLNK(info.st_mode)||info.st_nlink!=1||info.st_uid!=geteuid()||info.st_size>12LL*1024*1024)return [self fail:@"BATTLE_STORAGE_FILE_INVALID" error:error];
    sqlite3 *db=NULL;BOOL ok=sqlite3_open_v2(file.fileSystemRepresentation,&db,SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX|SQLITE_OPEN_NOFOLLOW,NULL)==SQLITE_OK;
    if(ok){sqlite3_busy_timeout(db,3000);sqlite3_limit(db,SQLITE_LIMIT_LENGTH,8*1024*1024);sqlite3_db_config(db,SQLITE_DBCONFIG_DEFENSIVE,1,NULL);sqlite3_db_config(db,SQLITE_DBCONFIG_TRUSTED_SCHEMA,0,NULL);
        ok=sqlite3_exec(db,"PRAGMA journal_mode=DELETE;PRAGMA synchronous=FULL;PRAGMA foreign_keys=ON;BEGIN IMMEDIATE;CREATE TABLE IF NOT EXISTS binding(id INTEGER PRIMARY KEY CHECK(id=1),source TEXT NOT NULL,content TEXT NOT NULL,profile TEXT NOT NULL) STRICT;CREATE TABLE IF NOT EXISTS slot(id INTEGER PRIMARY KEY CHECK(id=1),token TEXT NOT NULL,data TEXT NOT NULL CHECK(length(CAST(data AS BLOB)) BETWEEN 1 AND 4194304),sha256 TEXT NOT NULL) STRICT;",NULL,NULL,NULL)==SQLITE_OK;
    }
    sqlite3_stmt *query=NULL;
    if(ok){ok=sqlite3_prepare_v2(db,"INSERT INTO binding VALUES(1,?1,?2,'local-player') ON CONFLICT(id) DO NOTHING",-1,&query,NULL)==SQLITE_OK;
        if(ok){sqlite3_bind_text(query,1,_source.UTF8String,-1,SQLITE_TRANSIENT);sqlite3_bind_text(query,2,_content.UTF8String,-1,SQLITE_TRANSIENT);ok=sqlite3_step(query)==SQLITE_DONE;}sqlite3_finalize(query);query=NULL;}
    if(ok){ok=sqlite3_prepare_v2(db,"SELECT count(*) FROM binding WHERE id=1 AND source=?1 AND content=?2 AND profile='local-player'",-1,&query,NULL)==SQLITE_OK;
        if(ok){sqlite3_bind_text(query,1,_source.UTF8String,-1,SQLITE_TRANSIENT);sqlite3_bind_text(query,2,_content.UTF8String,-1,SQLITE_TRANSIENT);ok=sqlite3_step(query)==SQLITE_ROW&&sqlite3_column_int(query,0)==1;}sqlite3_finalize(query);query=NULL;}
    if(ok)ok=sqlite3_exec(db,"COMMIT",NULL,NULL,NULL)==SQLITE_OK;
    if(!ok){if(db){sqlite3_exec(db,"ROLLBACK",NULL,NULL,NULL);sqlite3_close_v2(db);}return [self fail:@"BATTLE_STORAGE_OPEN_FAILED_OR_CONTENT_CHANGED" error:error];}
    _db=db;return YES;
}
- (BOOL)validData:(NSString *)text bytes:(NSData **)bytes error:(NSError **)error {
    NSData *data=[text isKindOfClass:NSString.class]?[text dataUsingEncoding:NSUTF8StringEncoding]:nil;
    if(!data.length||data.length>ODBattleDataLimit)return [self fail:@"BATTLE_STORAGE_DATA_INVALID" error:error];
    sqlite3_stmt *query=NULL;BOOL valid=sqlite3_prepare_v2(_db,"SELECT json_valid(?1)",-1,&query,NULL)==SQLITE_OK;
    if(valid){sqlite3_bind_text(query,1,text.UTF8String,(int)data.length,SQLITE_TRANSIENT);valid=sqlite3_step(query)==SQLITE_ROW&&sqlite3_column_int(query,0)==1;}sqlite3_finalize(query);query=NULL;
    const char *sql="SELECT json_type(?1)='object' AND json_extract(?1,'$.format')='offline-dokkan-battle-session' AND json_type(?1,'$.version')='integer' AND json_extract(?1,'$.version')=1 AND json_type(?1,'$.configuration')='object' AND json_type(?1,'$.state')='object' AND json_type(?1,'$.configuration.contentId')='text' AND json_extract(?1,'$.configuration.contentId')=?2 AND json_type(?1,'$.state.contentId')='text' AND json_extract(?1,'$.state.contentId')=?2 AND length(CAST(json_extract(?1,'$.configuration') AS BLOB))<=524288 AND json_type(?1,'$.configurationSha256')='text' AND length(json_extract(?1,'$.configurationSha256'))=64 AND json_extract(?1,'$.configurationSha256') NOT GLOB '*[^0-9a-f]*' AND json_type(?1,'$.stateSha256')='text' AND length(json_extract(?1,'$.stateSha256'))=64 AND json_extract(?1,'$.stateSha256') NOT GLOB '*[^0-9a-f]*' AND json_type(?1,'$.settlement') IN('null','object') AND (SELECT count(*)=7 AND count(DISTINCT key)=7 FROM json_each(?1)) AND NOT EXISTS(SELECT 1 FROM json_each(?1) WHERE key NOT IN('format','version','configuration','configurationSha256','state','stateSha256','settlement'))";
    if(valid){valid=sqlite3_prepare_v2(_db,sql,-1,&query,NULL)==SQLITE_OK;if(valid){sqlite3_bind_text(query,1,text.UTF8String,(int)data.length,SQLITE_TRANSIENT);sqlite3_bind_text(query,2,_content.UTF8String,-1,SQLITE_TRANSIENT);valid=sqlite3_step(query)==SQLITE_ROW&&sqlite3_column_int(query,0)==1;}sqlite3_finalize(query);}
    if(!valid)return [self fail:@"BATTLE_STORAGE_ENVELOPE_OR_CONTENT_INVALID" error:error];
    if(bytes)*bytes=data;return YES;
}
- (NSDictionary *)readOpen:(NSError **)error {
    sqlite3_stmt *query=NULL;if(sqlite3_prepare_v2(_db,"SELECT token,data,sha256 FROM slot WHERE id=1",-1,&query,NULL)!=SQLITE_OK){[self fail:@"BATTLE_STORAGE_READ_FAILED" error:error];return nil;}
    int rc=sqlite3_step(query);if(rc==SQLITE_DONE){sqlite3_finalize(query);return nil;}
    NSString *token=nil,*data=nil,*hash=nil;
    if(rc==SQLITE_ROW){const unsigned char *t=sqlite3_column_text(query,0),*d=sqlite3_column_text(query,1),*h=sqlite3_column_text(query,2);if(t)token=[[NSString alloc] initWithBytes:t length:(NSUInteger)sqlite3_column_bytes(query,0) encoding:NSUTF8StringEncoding];if(d)data=[[NSString alloc] initWithBytes:d length:(NSUInteger)sqlite3_column_bytes(query,1) encoding:NSUTF8StringEncoding];if(h)hash=[[NSString alloc] initWithBytes:h length:(NSUInteger)sqlite3_column_bytes(query,2) encoding:NSUTF8StringEncoding];}
    sqlite3_finalize(query);NSData *bytes=nil;
    if(rc!=SQLITE_ROW||!ODBattleToken(token)||![self validData:data bytes:&bytes error:error]||![ODBattleHash(bytes) isEqual:hash]){if(error&&!*error)*error=ODBattleError(@"BATTLE_STORAGE_RECORD_INVALID");return nil;}
    return @{@"token":token,@"data":data};
}
- (NSDictionary *)read:(NSError **)error {if(error)*error=nil;if(![self open:error])return nil;return [self readOpen:error];}
- (id)compareAndSwap:(NSString *)expectedToken data:(NSString *)data error:(NSError **)error {
    if(error)*error=nil;
    if(expectedToken&&!ODBattleToken(expectedToken)){[self fail:@"BATTLE_STORAGE_TOKEN_INVALID" error:error];return nil;}
    if(![self open:error])return nil;NSData *bytes=nil;if(![self validData:data bytes:&bytes error:error])return nil;
    if(sqlite3_exec(_db,"BEGIN IMMEDIATE",NULL,NULL,NULL)!=SQLITE_OK){[self fail:@"BATTLE_STORAGE_LOCK_FAILED" error:error];return nil;}
    NSError *failure=nil;NSDictionary *old=[self readOpen:&failure];
    if(failure){sqlite3_exec(_db,"ROLLBACK",NULL,NULL,NULL);if(error)*error=failure;return nil;}
    if((old&&!expectedToken)||(!old&&expectedToken)||(old&&![old[@"token"] isEqual:expectedToken])){sqlite3_exec(_db,"ROLLBACK",NULL,NULL,NULL);return @NO;}
    NSString *token=NSUUID.UUID.UUIDString;while([token isEqual:expectedToken])token=NSUUID.UUID.UUIDString;
    sqlite3_stmt *query=NULL;BOOL ok=sqlite3_prepare_v2(_db,"INSERT INTO slot VALUES(1,?1,?2,?3) ON CONFLICT(id) DO UPDATE SET token=excluded.token,data=excluded.data,sha256=excluded.sha256",-1,&query,NULL)==SQLITE_OK;
    if(ok){sqlite3_bind_text(query,1,token.UTF8String,-1,SQLITE_TRANSIENT);sqlite3_bind_text(query,2,data.UTF8String,(int)bytes.length,SQLITE_TRANSIENT);NSString *hash=ODBattleHash(bytes);sqlite3_bind_text(query,3,hash.UTF8String,-1,SQLITE_TRANSIENT);ok=sqlite3_step(query)==SQLITE_DONE;}sqlite3_finalize(query);
    if(ok)ok=sqlite3_exec(_db,"COMMIT",NULL,NULL,NULL)==SQLITE_OK;
    if(!ok){sqlite3_exec(_db,"ROLLBACK",NULL,NULL,NULL);[self fail:@"BATTLE_STORAGE_COMMIT_FAILED" error:error];return nil;}return token;
}
@end
