#import "ODCreatorSourceDatabases.h"
#define ForgeStorageContext ODScopedCreatorStorageContext
#define ForgeHost ODScopedCreatorHost
#import "../../../unit-creator/ios-objc/Host.h"
#import <sys/stat.h>
#import <fcntl.h>
#import <unistd.h>
#import <string.h>

@interface ODCreatorSourceDatabaseHandle : NSObject
@property(nonatomic,readonly) NSString *relative;
- (nullable instancetype)initWithRelative:(NSString *)relative storage:(ODScopedCreatorStorageContext *)storage;
- (BOOL)isCurrent;
- (void)invalidate;
@end
@implementation ODCreatorSourceDatabaseHandle {
    NSString *_path;ODScopedCreatorStorageContext *_storage;int _fd;struct stat _identity;
}
- (instancetype)initWithRelative:(NSString *)relative storage:(ODScopedCreatorStorageContext *)storage {
    if(!(self=[super init]))return nil;
    _fd=-1;_storage=storage;_relative=[relative copy];_path=[storage resolve:relative];
    if(!_path||[_path isEqual:storage.storageRoot])return nil;
    _fd=open(_path.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);unsigned char header[16];
    if(_fd<0||fstat(_fd,&_identity)||!S_ISREG(_identity.st_mode)||_identity.st_size<512||_identity.st_size>512*1024*1024||
        pread(_fd,header,sizeof(header),0)!=sizeof(header)||memcmp(header,"SQLite format 3",16))return nil;
    return self;
}
- (BOOL)isCurrent {
    @synchronized(self) {
        if(_fd<0||![_storage isCurrent])return NO;
        struct stat held,path;
        return !fstat(_fd,&held)&&!lstat(_path.fileSystemRepresentation,&path)&&S_ISREG(path.st_mode)&&
            held.st_dev==_identity.st_dev&&held.st_ino==_identity.st_ino&&held.st_size==_identity.st_size&&
            path.st_dev==held.st_dev&&path.st_ino==held.st_ino&&path.st_size==held.st_size&&
            held.st_mtimespec.tv_sec==_identity.st_mtimespec.tv_sec&&held.st_mtimespec.tv_nsec==_identity.st_mtimespec.tv_nsec&&
            held.st_ctimespec.tv_sec==_identity.st_ctimespec.tv_sec&&held.st_ctimespec.tv_nsec==_identity.st_ctimespec.tv_nsec;
    }
}
- (void)invalidate { @synchronized(self) {if(_fd>=0){close(_fd);_fd=-1;}} }
- (void)dealloc {if(_fd>=0)close(_fd);}
@end

@implementation ODCreatorSourceDatabases {
    ODScopedCreatorStorageContext *_storage;ODScopedCreatorHost *_host;
    NSMutableDictionary<NSString *,ODCreatorSourceDatabaseHandle *> *_handles;
    BOOL _invalidated;
}
- (instancetype)initWithStorageContext:(ODScopedCreatorStorageContext *)storage host:(ODScopedCreatorHost *)host {
    if((self=[super init])){_storage=storage;_host=host;_handles=[NSMutableDictionary dictionary];}return self;
}
- (void)handleMessage:(NSDictionary *)message reply:(void (^)(id,NSString *))reply {
    if(!NSThread.isMainThread||_invalidated||![_storage isCurrent]){reply(nil,@"The native source inspection scope is unavailable.");return;}
    NSString *op=[message[@"op"] isKindOfClass:NSString.class]?message[@"op"]:@"";
    if([op isEqualToString:@"sourceDatabaseOpen"]){
        NSString *relative=[message[@"path"] isKindOfClass:NSString.class]?message[@"path"]:@"";
        if(_handles.count>=8){reply(nil,@"Close the previous source inspection first.");return;}
        ODCreatorSourceDatabaseHandle *handle=[[ODCreatorSourceDatabaseHandle alloc] initWithRelative:relative storage:_storage];
        if(!handle||![handle isCurrent]){reply(nil,@"Choose a readable regular SQLite candidate inside this Creator workspace.");return;}
        NSString *token=[@"creator-source-db:" stringByAppendingString:NSUUID.UUID.UUIDString];_handles[token]=handle;
        reply(@{@"handle":token,@"readOnly":@YES,@"selectedMaster":@NO},nil);return;
    }
    NSString *token=[message[@"handle"] isKindOfClass:NSString.class]?message[@"handle"]:@"";
    ODCreatorSourceDatabaseHandle *handle=_handles[token];
    if([op isEqualToString:@"sourceDatabaseClose"]){[handle invalidate];[_handles removeObjectForKey:token];reply(@YES,nil);return;}
    if(![op isEqualToString:@"sourceDatabaseRead"]||!handle||![handle isCurrent]){reply(nil,@"The source inspection handle is unavailable or changed.");return;}
    NSString *kind=[message[@"kind"] isKindOfClass:NSString.class]?message[@"kind"]:@"";
    NSString *table=[message[@"table"] isKindOfClass:NSString.class]?message[@"table"]:nil;
    __weak ODCreatorSourceDatabases *weakSelf=self;
    [_host inspectSourceDatabase:handle.relative kind:kind table:table identityIsCurrent:^BOOL {return [handle isCurrent];}
        reply:^(id value,NSString *failure){ODCreatorSourceDatabases *me=weakSelf;if(!me||me->_invalidated||![handle isCurrent])reply(nil,@"The staged source changed.");else reply(value,failure);}];
}
- (void)invalidate { _invalidated=YES;for(ODCreatorSourceDatabaseHandle *handle in _handles.allValues)[handle invalidate];[_handles removeAllObjects]; }
- (void)dealloc {for(ODCreatorSourceDatabaseHandle *handle in _handles.allValues)[handle invalidate];}
@end
