#import "ODMasterLibrary.h"
#include "sqlite3.h"
#include <CommonCrypto/CommonDigest.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include "../../content/master_archive.h"

static NSError *ODImportError(NSString *code) { return [NSError errorWithDomain:@"OfflineDokkanMaster" code:1 userInfo:@{NSLocalizedDescriptionKey:code}]; }
static NSString *ODMasterHash(NSURL *file) {
    int fd = open(file.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_NONBLOCK); if(fd<0)return nil;
    struct stat info;if(fstat(fd,&info)||!S_ISREG(info.st_mode)||info.st_size<100||info.st_size>2LL*1024*1024*1024){close(fd);return nil;}
    CC_SHA256_CTX context;CC_SHA256_Init(&context);unsigned char buffer[65536];ssize_t n;
    while((n=read(fd,buffer,sizeof(buffer)))>0)CC_SHA256_Update(&context,buffer,(CC_LONG)n);
    close(fd);if(n<0)return nil;unsigned char hash[32];CC_SHA256_Final(hash,&context);
    NSMutableString *text=[NSMutableString stringWithCapacity:64];for(int i=0;i<32;i++)[text appendFormat:@"%02x",hash[i]];return text;
}
static BOOL ODMasterValid(sqlite3 *db) {
    sqlite3_stmt *query=NULL;BOOL ok=NO;
    if(sqlite3_exec(db,"PRAGMA trusted_schema=OFF;PRAGMA temp_store=MEMORY;",NULL,NULL,NULL)!=SQLITE_OK)return NO;
    if(sqlite3_prepare_v2(db,"PRAGMA quick_check",-1,&query,NULL)!=SQLITE_OK)return NO;
    ok=sqlite3_step(query)==SQLITE_ROW&&sqlite3_column_text(query,0)&&strcmp((const char *)sqlite3_column_text(query,0),"ok")==0&&sqlite3_step(query)==SQLITE_DONE;sqlite3_finalize(query);if(!ok)return NO;
    if(sqlite3_prepare_v2(db,"SELECT 1 FROM sqlite_schema WHERE name NOT LIKE 'sqlite_%' AND (type NOT IN('table','index') OR upper(coalesce(sql,'')) LIKE '%VIRTUAL TABLE%') LIMIT 1",-1,&query,NULL)!=SQLITE_OK)return NO;
    ok=sqlite3_step(query)==SQLITE_DONE;sqlite3_finalize(query);if(!ok)return NO;
    NSDictionary *required=@{@"cards":@[@"id",@"lv_max",@"skill_lv_max"],@"quests":@[@"id",@"area_id"],@"sugoroku_maps":@[@"id",@"quest_id",@"act"],@"training_items":@[@"id"],@"awakening_items":@[@"id"]};
    for(NSString *table in required){
        NSString *sql=[NSString stringWithFormat:@"PRAGMA table_info(\"%@\")",table];
        if(sqlite3_prepare_v2(db,sql.UTF8String,-1,&query,NULL)!=SQLITE_OK)return NO;
        NSMutableSet *names=[NSMutableSet set];int rc;
        while((rc=sqlite3_step(query))==SQLITE_ROW){const unsigned char *name=sqlite3_column_text(query,1);if(name)[names addObject:[NSString stringWithUTF8String:(const char *)name]];}
        sqlite3_finalize(query);if(rc!=SQLITE_DONE||![[NSSet setWithArray:required[table]] isSubsetOfSet:names])return NO;
    }
    if(sqlite3_prepare_v2(db,"SELECT count(*) FROM cards",-1,&query,NULL)!=SQLITE_OK)return NO;
    ok=sqlite3_step(query)==SQLITE_ROW&&sqlite3_column_int64(query,0)>0;sqlite3_finalize(query);return ok;
}
/** User-requested source download only; no game/login traffic or private crypto. */
@interface ODSourceDatabaseDownload : NSObject <NSURLSessionDataDelegate>
- (instancetype)initWithRoot:(NSURL *)root url:(NSURL *)url progress:(void(^)(int64_t,int64_t))progress completion:(void(^)(ODSourceDatabaseDownload *,NSURL *,NSError *))completion;
- (void)start;
- (void)cancel;
- (BOOL)isCancelled;
@end
@implementation ODSourceDatabaseDownload {
    NSURL *_root,*_url,*_stage;NSURLSession *_session;NSURLSessionDataTask *_task;
    void(^_progress)(int64_t,int64_t);void(^_completion)(ODSourceDatabaseDownload *,NSURL *,NSError *);
    int _fd;int64_t _received,_declared,_lastProgress;NSInteger _redirects;BOOL _finished,_cancelled;
}
static const int64_t ODSourceDatabaseLimit=512LL*1024*1024;
- (instancetype)initWithRoot:(NSURL *)root url:(NSURL *)url progress:(void(^)(int64_t,int64_t))progress completion:(void(^)(ODSourceDatabaseDownload *,NSURL *,NSError *))completion {
    if((self=[super init])){_root=root;_url=url;_progress=[progress copy];_completion=[completion copy];_fd=-1;_declared=-1;}return self;
}
- (BOOL)isCancelled { @synchronized(self){return _cancelled;} }
- (void)cancel { @synchronized(self){_cancelled=YES;[_task cancel];} }
- (void)start {
    _stage=[_root URLByAppendingPathComponent:[@".source-download-" stringByAppendingString:NSUUID.UUID.UUIDString]];
    _fd=open(_stage.fileSystemRepresentation,O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW,0600);
    if(_fd<0){[self finish:ODImportError(@"SOURCE_STAGE_FAILED")];return;}
    NSURLSessionConfiguration *configuration=NSURLSessionConfiguration.ephemeralSessionConfiguration;
    configuration.URLCache=nil;configuration.HTTPCookieStorage=nil;configuration.URLCredentialStorage=nil;configuration.HTTPShouldSetCookies=NO;
    configuration.requestCachePolicy=NSURLRequestReloadIgnoringLocalCacheData;configuration.timeoutIntervalForRequest=30;configuration.timeoutIntervalForResource=300;
    NSOperationQueue *queue=[NSOperationQueue new];queue.maxConcurrentOperationCount=1;queue.name=@"personal.offlinedokkan.source-download";
    _session=[NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:queue];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:_url];
    [request setValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];[request setValue:@"Offline-Dokkan-Data/0.1" forHTTPHeaderField:@"User-Agent"];
    _task=[_session dataTaskWithRequest:request];if(self.isCancelled){[self finish:ODImportError(@"SOURCE_DOWNLOAD_CANCELLED")];return;}[_task resume];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void(^)(NSURLRequest *))completionHandler {
    // A fixed literal URL is stronger than trusting a hostname suffix or an
    // arbitrary path on a provider host. TLS/server trust stays at OS defaults.
    if(self.isCancelled||++_redirects>3||![request.URL.absoluteString isEqual:_url.absoluteString]){completionHandler(nil);[self finish:ODImportError(self.isCancelled?@"SOURCE_DOWNLOAD_CANCELLED":@"SOURCE_REDIRECT_NOT_ALLOWED")];return;}
    completionHandler(request);
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveResponse:(NSURLResponse *)response completionHandler:(void(^)(NSURLSessionResponseDisposition))completionHandler {
    NSHTTPURLResponse *http=[response isKindOfClass:NSHTTPURLResponse.class]?(id)response:nil;
    NSString *encoding=[[http valueForHTTPHeaderField:@"Content-Encoding"] lowercaseString];
    int64_t declared=response.expectedContentLength;
    BOOL ok=!_finished&&!self.isCancelled&&http.statusCode==200&&[response.URL.absoluteString isEqual:_url.absoluteString]&&(!encoding.length||[encoding isEqual:@"identity"])&&(declared==-1||(declared>=16&&declared<=ODSourceDatabaseLimit));
    if(!ok){completionHandler(NSURLSessionResponseCancel);[self finish:ODImportError(self.isCancelled?@"SOURCE_DOWNLOAD_CANCELLED":@"SOURCE_RESPONSE_INVALID")];return;}
    _declared=declared;completionHandler(NSURLSessionResponseAllow);if(_progress)_progress(0,_declared);
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveData:(NSData *)data {
    if(_finished)return;
    if(self.isCancelled||data.length>(NSUInteger)(ODSourceDatabaseLimit-_received)){[self finish:ODImportError(self.isCancelled?@"SOURCE_DOWNLOAD_CANCELLED":@"SOURCE_TOO_LARGE")];return;}
    NSUInteger at=0;while(at<data.length){ssize_t written=write(_fd,(const char *)data.bytes+at,data.length-at);if(written<0&&errno==EINTR)continue;if(written<=0){[self finish:ODImportError(@"SOURCE_STAGE_FAILED")];return;}at+=(NSUInteger)written;}
    _received+=(int64_t)data.length;
    if(_declared>=0&&_received>_declared){[self finish:ODImportError(@"SOURCE_SIZE_MISMATCH")];return;}
    if(_progress&&_received-_lastProgress>=1024*1024){_lastProgress=_received;_progress(_received,_declared);}
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if(_finished)return;
    if(self.isCancelled){[self finish:ODImportError(@"SOURCE_DOWNLOAD_CANCELLED")];return;}
    if(error){[self finish:ODImportError(@"SOURCE_DOWNLOAD_FAILED")];return;}
    if(_received<16||(_declared>=0&&_declared!=_received)){[self finish:ODImportError(@"SOURCE_SIZE_MISMATCH")];return;}
    unsigned char header[16];
    if(pread(_fd,header,sizeof(header),0)!=sizeof(header)||memcmp(header,"SQLite format 3\0",16)){[self finish:ODImportError(@"PLAINTEXT_MASTER_REQUIRED_NO_DECRYPTION")];return;}
    if(fsync(_fd)){[self finish:ODImportError(@"SOURCE_STAGE_FAILED")];return;}
    if(_progress)_progress(_received,_declared);[self finish:nil];
}
- (void)finish:(NSError *)error {
    if(_finished)return;_finished=YES;
    if(_fd>=0){if(close(_fd)&&!error)error=ODImportError(@"SOURCE_STAGE_FAILED");_fd=-1;}
    [_session invalidateAndCancel];_task=nil;_session=nil;
    // Validation/import runs synchronously on the download delegate's private
    // worker before its one fresh staging file is removed.
    @try{if(_completion)_completion(self,error?nil:_stage,error);}
    @finally{if(_stage)unlink(_stage.fileSystemRepresentation);_completion=nil;_progress=nil;}
}
@end

@implementation ODMasterLibrary { NSURL *_root; ODSourceDatabaseDownload *_download; }
- (instancetype)initWithDirectory:(NSURL *)directory { if((self=[super init]))_root=[directory copy];return self; }
- (void)cancelDownload { @synchronized(self){[_download cancel];} }
- (void)downloadDatabaseForSource:(NSString *)source progress:(void(^)(int64_t,int64_t))progress completion:(void(^)(NSDictionary *,NSError *))completion {
    // Keep these literal URLs aligned with content/source_downloads.py.
    NSDictionary *providers=@{@"eclipse":@"https://dokkan-eclipse.com/cdn/uncompressed/sqlite/current/en/database_decrypted.db",@"sparking":@"https://ddl.dokkan-sparking.com/dokkan/assets/global/en/sqlite/current/en/database.db"};
    NSString *address=providers[source];NSError *error=nil;
    if(!address||![self prepare:&error]){completion(nil,error?:ODImportError(@"SOURCE_INVALID"));return;}
    @synchronized(self){
        if(_download){completion(nil,ODImportError(@"SOURCE_DOWNLOAD_BUSY"));return;}
        __weak ODMasterLibrary *weakSelf=self;
        _download=[[ODSourceDatabaseDownload alloc] initWithRoot:_root url:[NSURL URLWithString:address] progress:progress completion:^(ODSourceDatabaseDownload *download,NSURL *stage,NSError *failure){
            ODMasterLibrary *library=weakSelf;NSDictionary *selection=nil;
            if(!failure&&library&&!download.isCancelled)selection=[library importURL:stage game:source error:&failure];
            if(download.isCancelled||!library)failure=ODImportError(@"SOURCE_DOWNLOAD_CANCELLED");
            if(library){@synchronized(library){if(library->_download==download)library->_download=nil;}}
            completion(failure?nil:selection,failure);
        }];
        [_download start];
    }
}
- (BOOL)prepare:(NSError **)error {
    struct stat info;
    if(!_root.isFileURL||(!lstat(_root.fileSystemRepresentation,&info)&&(!S_ISDIR(info.st_mode)||S_ISLNK(info.st_mode)))){if(error)*error=ODImportError(@"CONTENT_LIBRARY_INVALID");return NO;}
    BOOL ready=[[NSFileManager defaultManager] createDirectoryAtURL:_root withIntermediateDirectories:YES attributes:@{NSFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication} error:error];
    if(ready){@synchronized(self){if(!_download){
        // Only our exact UUID-named fresh stages can survive process termination.
        // No active download, imported master, player or recovery copy is removed.
        for(NSString *name in [NSFileManager.defaultManager contentsOfDirectoryAtPath:_root.path error:nil]){
            if(![name hasPrefix:@".source-download-"]||![[NSUUID alloc] initWithUUIDString:[name substringFromIndex:@".source-download-".length]])continue;
            NSURL *file=[_root URLByAppendingPathComponent:name];struct stat stale;
            if(!lstat(file.fileSystemRepresentation,&stale)&&S_ISREG(stale.st_mode)&&stale.st_nlink==1)unlink(file.fileSystemRepresentation);
        }
    }}}
    return ready;
}
- (NSDictionary *)selectionForGame:(NSString *)game error:(NSError **)error {
    if(![game isEqual:@"eclipse"]&&![game isEqual:@"sparking"]){if(error)*error=ODImportError(@"GAME_INVALID");return nil;}
    if(![self prepare:error])return nil;
    NSDictionary *index=[NSDictionary dictionaryWithContentsOfURL:[_root URLByAppendingPathComponent:@"masters.plist"]];
    NSDictionary *entry=index[game];if(![entry isKindOfClass:NSDictionary.class]){if(error)*error=ODImportError(@"MASTER_REQUIRED");return nil;}
    NSString *hash=entry[@"sha256"];
    if(![hash isKindOfClass:NSString.class]||hash.length!=64||[hash rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet]].location!=NSNotFound){if(error)*error=ODImportError(@"MASTER_INDEX_INVALID");return nil;}
    NSURL *file=[_root URLByAppendingPathComponent:[hash stringByAppendingString:@".sqlite"]];
    if(![ODMasterHash(file) isEqual:hash]){if(error)*error=ODImportError(@"MASTER_INTEGRITY_INVALID");return nil;}
    return @{@"file":file,@"source":game,@"content_id":[NSString stringWithFormat:@"%@:sha256:%@",game,hash]};
}
- (NSDictionary *)activeSelection:(NSError **)error {
    if(![self prepare:error])return nil;
    NSURL *activeURL=[_root URLByAppendingPathComponent:@"active-master.plist"];
    NSDictionary *active=[NSDictionary dictionaryWithContentsOfURL:activeURL];
    NSString *source=active[@"source"];
    if(!active){
        // Older development hosts kept source records, not one game identity.
        NSDictionary *index=[NSDictionary dictionaryWithContentsOfURL:[_root URLByAppendingPathComponent:@"masters.plist"]];
        NSMutableArray *sources=[NSMutableArray array];
        for(NSString *key in @[@"eclipse",@"sparking"])if([index[key] isKindOfClass:NSDictionary.class])[sources addObject:key];
        if(sources.count!=1){if(error)*error=ODImportError(sources.count?@"DATA_SOURCE_SELECTION_REQUIRED":@"MASTER_REQUIRED");return nil;}
        source=sources.firstObject;
        if(![self activateSource:source error:error])return nil;
        active=[NSDictionary dictionaryWithContentsOfURL:activeURL];
    }
    NSDictionary *selection=[self selectionForGame:source error:error];
    if(!selection)return nil;
    if(![selection[@"content_id"] isEqual:active[@"content_id"]]){if(error)*error=ODImportError(@"MASTER_MIGRATION_REQUIRED");return nil;}
    return selection;
}
- (BOOL)activateSource:(NSString *)source error:(NSError **)error {
    NSDictionary *selection=[self selectionForGame:source error:error];if(!selection)return NO;
    NSURL *activeURL=[_root URLByAppendingPathComponent:@"active-master.plist"];
    NSDictionary *active=[NSDictionary dictionaryWithContentsOfURL:activeURL];
    if(active&&![active[@"content_id"] isEqual:selection[@"content_id"]]){if(error)*error=ODImportError(@"MASTER_MIGRATION_REQUIRED");return NO;}
    if(![@{@"source":source,@"content_id":selection[@"content_id"]} writeToURL:activeURL atomically:YES]){if(error)*error=ODImportError(@"MASTER_INDEX_FAILED");return NO;}
    return YES;
}
- (NSDictionary *)importURL:(NSURL *)source game:(NSString *)game error:(NSError **)error {
    if(!source.isFileURL||(![game isEqual:@"eclipse"]&&![game isEqual:@"sparking"])||![self prepare:error]){if(error&&!*error)*error=ODImportError(@"INVALID_HOST_CONFIGURATION");return nil;}
    struct stat initial,opened,after;
    if(lstat(source.fileSystemRepresentation,&initial)||!S_ISREG(initial.st_mode)||initial.st_size<16||(uint64_t)initial.st_size>OD_MASTER_ARCHIVE_MAX_SOURCE){if(error)*error=ODImportError(@"MASTER_FILE_INVALID");return nil;}
    int input=open(source.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_NONBLOCK);
    if(input<0||fstat(input,&opened)||opened.st_dev!=initial.st_dev||opened.st_ino!=initial.st_ino||!S_ISREG(opened.st_mode)){if(input>=0)close(input);if(error)*error=ODImportError(@"MASTER_FILE_CHANGED");return nil;}
    unsigned char header[16];ssize_t readHeader=pread(input,header,sizeof(header),0);
    if(readHeader==16&&!memcmp(header,"SQLite format 3\0",16)){close(input);return [self importSQLiteURL:source game:game error:error];}
    NSURL *stage=[_root URLByAppendingPathComponent:[@".archive-" stringByAppendingFormat:@"%@.sqlite",NSUUID.UUID.UUIDString]];
    int output=open(stage.fileSystemRepresentation,O_CREAT|O_EXCL|O_RDWR|O_NOFOLLOW,0600);
    if(output<0){close(input);if(error)*error=ODImportError(@"MASTER_STAGE_FAILED");return nil;}
    const char *archiveError=NULL;od_master_archive_result extracted;
    BOOL ok=od_master_archive_extract(input,output,game.UTF8String,&extracted,&archiveError)==0;
    if(ok&&(fstat(input,&after)||after.st_dev!=opened.st_dev||after.st_ino!=opened.st_ino||after.st_size!=opened.st_size||after.st_mtimespec.tv_sec!=opened.st_mtimespec.tv_sec||after.st_mtimespec.tv_nsec!=opened.st_mtimespec.tv_nsec))ok=NO;
    close(output);close(input);
    // Extraction never publishes a master. The normal SQLite/schema/hash pipeline remains authoritative.
    NSDictionary *selection=ok?[self importSQLiteURL:stage game:game error:error]:nil;
    [NSFileManager.defaultManager removeItemAtURL:stage error:nil]; // Only the fresh staging file created above.
    if(!ok&&error)*error=ODImportError(archiveError?[NSString stringWithUTF8String:archiveError]:@"MASTER_ARCHIVE_SOURCE_CHANGED");
    return selection;
}
- (NSDictionary *)importSQLiteURL:(NSURL *)source game:(NSString *)game error:(NSError **)error {
    if(!source.isFileURL||(![game isEqual:@"eclipse"]&&![game isEqual:@"sparking"])||![self prepare:error]){if(error&&!*error)*error=ODImportError(@"INVALID_HOST_CONFIGURATION");return nil;}
    struct stat initial,opened;
    if(lstat(source.fileSystemRepresentation,&initial)||!S_ISREG(initial.st_mode)||initial.st_size<100||initial.st_size>2LL*1024*1024*1024){if(error)*error=ODImportError(@"MASTER_FILE_INVALID");return nil;}
    NSURL *candidate=[_root URLByAppendingPathComponent:[@".import-" stringByAppendingFormat:@"%@.sqlite",NSUUID.UUID.UUIDString]];
    int descriptor=open(candidate.fileSystemRepresentation,O_CREAT|O_EXCL|O_RDWR,0600);if(descriptor<0){if(error)*error=ODImportError(@"MASTER_STAGE_FAILED");return nil;}close(descriptor);
    sqlite3 *origin=NULL,*target=NULL;BOOL ok=NO;
    if(sqlite3_open_v2(source.fileSystemRepresentation,&origin,SQLITE_OPEN_READONLY|SQLITE_OPEN_FULLMUTEX|SQLITE_OPEN_NOFOLLOW,NULL)==SQLITE_OK&&sqlite3_exec(origin,"PRAGMA query_only=ON;BEGIN",NULL,NULL,NULL)==SQLITE_OK&&ODMasterValid(origin)&&!lstat(source.fileSystemRepresentation,&opened)&&opened.st_dev==initial.st_dev&&opened.st_ino==initial.st_ino&&sqlite3_open_v2(candidate.fileSystemRepresentation,&target,SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX,NULL)==SQLITE_OK){
        int pageSize=0;sqlite3_stmt *pageQuery=NULL;
        if(sqlite3_prepare_v2(origin,"PRAGMA page_size",-1,&pageQuery,NULL)==SQLITE_OK&&sqlite3_step(pageQuery)==SQLITE_ROW)pageSize=sqlite3_column_int(pageQuery,0);
        sqlite3_finalize(pageQuery);
        sqlite3_backup *backup=pageSize>0?sqlite3_backup_init(target,"main",origin,"main"):NULL;
        if(backup){int rc;NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:30];
            do{rc=sqlite3_backup_step(backup,256);if((sqlite3_int64)sqlite3_backup_pagecount(backup)*pageSize>2LL*1024*1024*1024){rc=SQLITE_TOOBIG;break;}if(rc==SQLITE_BUSY||rc==SQLITE_LOCKED)sqlite3_sleep(25);}while((rc==SQLITE_OK||rc==SQLITE_BUSY||rc==SQLITE_LOCKED)&&deadline.timeIntervalSinceNow>0);
            int finished=sqlite3_backup_finish(backup);ok=rc==SQLITE_DONE&&finished==SQLITE_OK&&sqlite3_exec(target,"PRAGMA journal_mode=DELETE",NULL,NULL,NULL)==SQLITE_OK&&ODMasterValid(target);
        }
    }
    if(target)sqlite3_close(target);if(origin)sqlite3_close(origin);
    if(ok){descriptor=open(candidate.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW);ok=descriptor>=0&&fsync(descriptor)==0;if(descriptor>=0)close(descriptor);}
    NSString *hash=ok?ODMasterHash(candidate):nil;
    NSURL *destination=hash?[_root URLByAppendingPathComponent:[hash stringByAppendingString:@".sqlite"]]:nil;
    BOOL promoted=NO;
    if(hash){chmod(candidate.fileSystemRepresentation,0400);int result=link(candidate.fileSystemRepresentation,destination.fileSystemRepresentation);promoted=result==0;if(result&&![ODMasterHash(destination) isEqual:hash])hash=nil;}
    [[NSFileManager defaultManager] removeItemAtURL:candidate error:nil];
    if(!hash){if(error)*error=ODImportError(@"MASTER_IMPORT_FAILED");return nil;}
    NSURL *indexURL=[_root URLByAppendingPathComponent:@"masters.plist"];
    NSMutableDictionary *index=[[NSDictionary dictionaryWithContentsOfURL:indexURL] mutableCopy]?:[NSMutableDictionary dictionary];
    NSDictionary *previous=index[game];
    if(previous&&![previous[@"sha256"] isEqual:hash]){
        BOOL referenced=NO;for(NSDictionary *entry in index.allValues)if([entry[@"sha256"] isEqual:hash])referenced=YES;
        if(promoted&&!referenced)[NSFileManager.defaultManager removeItemAtURL:destination error:nil];
        if(error)*error=ODImportError(@"MASTER_MIGRATION_REQUIRED");return nil;
    } // Existing saves remain pinned; no silent migration.
    index[game]=@{@"sha256":hash};
    if(![index writeToURL:indexURL atomically:YES]){if(promoted)[NSFileManager.defaultManager removeItemAtURL:destination error:nil];if(error)*error=ODImportError(@"MASTER_INDEX_FAILED");return nil;}
    return [self selectionForGame:game error:error];
}
@end
