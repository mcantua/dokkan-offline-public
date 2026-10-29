#import "ODBoundOriginalCreatorServices.h"
#import "../../adapter/ios/ODNativeCore.h"
#import "../../mobile/ios/ODCreatorSession.h"
#import "../duo/ODDuoOriginalScene.h"
#import "../creator-tools/ODScopedCreatorTools.h"
#import <CommonCrypto/CommonDigest.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

static NSError *ODBindingError(NSInteger code){return [NSError errorWithDomain:@"OfflineDokkan.OriginalCreatorBinding" code:code userInfo:@{NSLocalizedDescriptionKey:@"The same native game/save binding could not be confirmed. Your editor and original inputs are preserved; gameplay was not resumed."}];}
static NSError *ODOpeningRecoveredError(void){return [NSError errorWithDomain:@"OfflineDokkan.OriginalCreatorBinding" code:17 userInfo:@{NSLocalizedDescriptionKey:@"Unit Creator could not open. Its native binding was safely released; you can try opening it again."}];}
static BOOL ODHex(id v){return [v isKindOfClass:NSString.class]&&[v length]==64&&[v rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet]].location==NSNotFound;}
static BOOL ODSameFile(struct stat a,struct stat b){return a.st_dev==b.st_dev&&a.st_ino==b.st_ino&&a.st_size==b.st_size&&a.st_mtimespec.tv_sec==b.st_mtimespec.tv_sec&&a.st_mtimespec.tv_nsec==b.st_mtimespec.tv_nsec&&a.st_ctimespec.tv_sec==b.st_ctimespec.tv_sec&&a.st_ctimespec.tv_nsec==b.st_ctimespec.tv_nsec;}
static NSString *ODDigest(NSData *data){unsigned char h[32];CC_SHA256(data.bytes,(CC_LONG)data.length,h);NSMutableString *s=[NSMutableString string];for(int i=0;i<32;i++)[s appendFormat:@"%02x",h[i]];return s;}
static BOOL ODHashMaster(int fd,uint64_t expected,NSString *content,NSString *source,struct stat *identity){
    struct stat before,after;if(fstat(fd,&before)||!S_ISREG(before.st_mode)||before.st_nlink!=1||before.st_size<100||(uint64_t)before.st_size!=expected)return NO;
    unsigned char sqliteHeader[16];if(pread(fd,sqliteHeader,sizeof(sqliteHeader),0)!=sizeof(sqliteHeader)||memcmp(sqliteHeader,"SQLite format 3\0",16))return NO;
    CC_SHA256_CTX hash;CC_SHA256_Init(&hash);unsigned char buffer[65536];ssize_t n;uint64_t readBytes=0;
    while((n=read(fd,buffer,sizeof(buffer)))!=0){if(n<0){if(errno==EINTR)continue;return NO;}readBytes+=(uint64_t)n;if(readBytes>expected)return NO;CC_SHA256_Update(&hash,buffer,(CC_LONG)n);}
    unsigned char digest[32];CC_SHA256_Final(digest,&hash);NSMutableString *s=[NSMutableString string];for(int i=0;i<32;i++)[s appendFormat:@"%02x",digest[i]];
    NSString *raw=[@"sha256:" stringByAppendingString:s];
    NSString *qualified=[NSString stringWithFormat:@"%@:%@",source,raw];
    if(readBytes!=expected||fstat(fd,&after)||!ODSameFile(before,after)||(![content isEqual:raw]&&![content isEqual:qualified]))return NO;*identity=before;return YES;
}
static NSDictionary *ODReadOwner(int directory){
    int fd=openat(directory,".original-creator-binding.json",O_RDONLY|O_NOFOLLOW);if(fd<0)return nil;
    struct stat st;NSData *data=nil;if(!fstat(fd,&st)&&S_ISREG(st.st_mode)&&st.st_nlink==1&&st.st_size>0&&st.st_size<=4096){NSMutableData *b=[NSMutableData dataWithLength:(NSUInteger)st.st_size];ssize_t n=pread(fd,b.mutableBytes,b.length,0);if(n==st.st_size)data=b;}close(fd);
    id result=data?[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]:nil;return [result isKindOfClass:NSDictionary.class]?result:nil;
}
static BOOL ODClaimOwner(int directory,NSURL *workspace,NSDictionary *owner){
    NSDictionary *old=ODReadOwner(directory);if(old)return [old isEqual:owner];
    // Unknown/legacy documents are preserved for explicit migration, never
    // silently adopted into another logical save's workspace.
    NSArray *contents=[NSFileManager.defaultManager contentsOfDirectoryAtURL:workspace includingPropertiesForKeys:nil options:0 error:nil];if(!contents||contents.count)return NO;
    NSData *data=[NSJSONSerialization dataWithJSONObject:owner options:NSJSONWritingSortedKeys error:nil];if(!data||data.length>4096)return NO;
    int fd=openat(directory,".original-creator-binding.json",O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW,0600);if(fd<0)return NO;
    NSUInteger at=0;BOOL ok=YES;while(at<data.length){ssize_t n=write(fd,(const char *)data.bytes+at,data.length-at);if(n<0&&errno==EINTR)continue;if(n<=0){ok=NO;break;}at+=(NSUInteger)n;}
    if(fsync(fd))ok=NO;close(fd);if(ok)(void)fsync(directory);return ok&&[ODReadOwner(directory) isEqual:owner];
}

@implementation ODBoundOriginalCreatorServices {
    ODNativeCore *_core;NSURL *_master,*_save,*_workspace,*_overlay;
    NSString *_content,*_source,*_scope;NSDictionary *_owner;BOOL (^_current)(void);
    int _masterFD,_workspaceFD;struct stat _masterIdentity,_workspaceIdentity,_saveIdentity;
    ODCreatorSession *_session;ODOriginalCreatorCoordinator *_coordinator;
    ODScopedCreatorTools *_tools;BOOL (^_networkAuthorization)(NSURL *);
    ODNativeCreatorLease *_coreLease;ODDuoOriginalGamePauseLease *_pauseLease;
    __weak UIWindow *_window;__weak UIViewController *_controller;__weak UIView *_renderer;
    BOOL _opening,_closePrepared,_ending,_failedPresentationRecovery,_recoveringPresentation;NSError *_lastBindingError;
}
- (instancetype)initWithCore:(ODNativeCore *)core masterURL:(NSURL *)master masterBytes:(uint64_t)bytes contentID:(NSString *)content sourceDatabase:(NSString *)source saveURL:(NSURL *)save workspaceURL:(NSURL *)workspace overlayURL:(NSURL *)overlay expectedSaveScopeSHA256:(NSString *)scope contextIsCurrent:(BOOL (^)(void))current error:(NSError **)error {
    if((self=[super init])){
        _masterFD=-1;_workspaceFD=-1;
        if(!core||![core matchesSaveURL:save masterURL:master contentID:content]||!master.isFileURL||!save.isFileURL||!workspace.isFileURL||!overlay.isFileURL||!ODHex(scope)||![content isKindOfClass:NSString.class]||!current||![@[@"eclipse",@"sparking"] containsObject:source]||[overlay.URLByStandardizingPath isEqual:master.URLByStandardizingPath]||[overlay.URLByStandardizingPath isEqual:save.URLByStandardizingPath])goto invalid;
        _core=core;_master=[master copy];_save=[save copy];_workspace=[workspace copy];_overlay=[overlay copy];_content=[content copy];_source=[source copy];_scope=[scope copy];_current=[current copy];
        _masterFD=open(master.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW);if(_masterFD<0||!ODHashMaster(_masterFD,bytes,content,source,&_masterIdentity))goto invalid;
        struct stat st;if(lstat(save.fileSystemRepresentation,&st)||!S_ISREG(st.st_mode)||st.st_nlink!=1)goto invalid;_saveIdentity=st;
        if(lstat(workspace.fileSystemRepresentation,&st)&&errno==ENOENT){if(![NSFileManager.defaultManager createDirectoryAtURL:workspace withIntermediateDirectories:NO attributes:@{NSFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication} error:nil])goto invalid;}
        _workspaceFD=open(workspace.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW);if(_workspaceFD<0||fstat(_workspaceFD,&_workspaceIdentity)||!S_ISDIR(_workspaceIdentity.st_mode))goto invalid;
        NSDictionary *context=@{@"master":master.absoluteString,@"save":save.absoluteString,@"workspace":workspace.absoluteString,@"overlay":overlay.absoluteString,@"content":content,@"source":source};
        _owner=@{@"format":@"original-creator-binding-v1",@"content_id":content,@"save_scope_sha256":scope,@"native_context_sha256":ODDigest([NSJSONSerialization dataWithJSONObject:context options:NSJSONWritingSortedKeys error:nil])};
        if(!ODClaimOwner(_workspaceFD,workspace,_owner))goto invalid;
        _session=[[ODCreatorSession alloc] initWithMasterURL:_master contentID:_content game:_source directory:_workspace core:_core originalClientSaveScopeSHA256:_scope lease:nil];
        if(!_session)goto invalid;_coordinator=[[ODOriginalCreatorCoordinator alloc] initWithServices:self];
    }return self;
invalid:if(error)*error=ODBindingError(1);return nil;
}
- (void)dealloc{if(_masterFD>=0)close(_masterFD);if(_workspaceFD>=0)close(_workspaceFD);}
- (ODCreatorSession *)creatorSession{return _session;}
- (ODScopedCreatorTools *)creatorTools{return _tools;}
- (BOOL)configureCreatorNetworkAuthorization:(BOOL (^)(NSURL *))authorization error:(NSError **)error {
    if(!NSThread.isMainThread||!authorization||_opening||_ending||_pauseLease||_coordinator.creatorIsOpen){if(error)*error=ODBindingError(14);return NO;}
    _networkAuthorization=[authorization copy];return YES;
}
- (ODOriginalCreatorCoordinator *)coordinator{return _coordinator;}
- (NSError *)lastBindingError{return _lastBindingError;}
- (BOOL)failedPresentationNeedsRecovery{return _failedPresentationRecovery;}
- (BOOL)matchesAdmittedContentID:(NSString *)contentID saveScopeSHA256:(NSString *)scope {
    return [contentID isEqual:_content]&&[scope isEqual:_scope];
}
- (ODNativeCore *)originalClientCoreForContentID:(NSString *)contentID saveScopeSHA256:(NSString *)scope {
    return NSThread.isMainThread&&[self matchesAdmittedContentID:contentID saveScopeSHA256:scope]&&
        [self creatorScopeIsCurrent] ? _core : nil;
}
- (BOOL)creatorScopeIsCurrent {
    struct stat master,path,workspace,save;
    return NSThread.isMainThread&&_current()&&[_core matchesSaveURL:_save masterURL:_master contentID:_content]&&
        !fstat(_masterFD,&master)&&!lstat(_master.fileSystemRepresentation,&path)&&S_ISREG(path.st_mode)&&ODSameFile(_masterIdentity,master)&&ODSameFile(master,path)&&
        !lstat(_save.fileSystemRepresentation,&save)&&S_ISREG(save.st_mode)&&save.st_nlink==1&&save.st_dev==_saveIdentity.st_dev&&save.st_ino==_saveIdentity.st_ino&&
        !fstat(_workspaceFD,&workspace)&&workspace.st_dev==_workspaceIdentity.st_dev&&workspace.st_ino==_workspaceIdentity.st_ino&&
        !lstat(_workspace.fileSystemRepresentation,&path)&&S_ISDIR(path.st_mode)&&path.st_dev==workspace.st_dev&&path.st_ino==workspace.st_ino&&[ODReadOwner(_workspaceFD) isEqual:_owner];
}
- (BOOL)receiptMatches:(id)receipt {
    return [receipt isKindOfClass:NSDictionary.class]&&[receipt[@"content_id"] isEqual:_content]&&[receipt[@"save_scope_sha256"] isEqual:_scope]&&
        [receipt[@"clean"] isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)receipt[@"clean"])==CFBooleanGetTypeID()&&[receipt[@"clean"] boolValue]&&
        [receipt[@"projection_generation"] isKindOfClass:NSNumber.class]&&[receipt[@"projection_generation"] isEqual:receipt[@"applied_generation"]];
}
- (BOOL)attachToOriginalWindow:(UIWindow *)window controller:(UIViewController *)controller renderer:(UIView *)renderer error:(NSError **)error {
    if(![_coordinator attachToOriginalWindow:window controller:controller renderer:renderer error:error])return NO;
    _window=window;_controller=controller;_renderer=renderer;return YES;
}
- (void)presentCreatorFromUserActionWithCompletion:(void (^)(NSError *))completion {
    if(!completion)return;
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self presentCreatorFromUserActionWithCompletion:completion];});return;}
    if(![self creatorScopeIsCurrent]||_opening||_ending||_recoveringPresentation||_coordinator.creatorIsOpen){completion(ODBindingError(2));return;}
    if(_failedPresentationRecovery){
        // A new explicit user action can retry cleanup, never reuse the held
        // stale tools/session as a fresh editing capability.
        [self recoverFailedPresentationWithCompletion:^(NSError *failure){
            if(failure)completion(failure);else[self presentCreatorFromUserActionWithCompletion:completion];
        }];return;
    }
    NSError *pauseError=nil;if(!_pauseLease)_pauseLease=ODDuoBeginCreatorPause(_window,_controller,_renderer,&pauseError);
    if(!_pauseLease){
        // The source pause implementation retains a faulted global lease when
        // its postconditions fail, even though it cannot hand that lease out.
        // Surface that state; never synthesize authority to release it.
        if([pauseError.domain isEqual:@"OfflineDokkan.OriginalDuoScene"]&&pauseError.code==15)_failedPresentationRecovery=YES;
        _lastBindingError=ODBindingError(3);completion(_lastBindingError);return;
    }
    _opening=YES;
    [_core synchronizeOriginalCreatorProjectionForProfile:@"local-player" overlayURL:_overlay reply:^(id receipt,NSError *failure){
        if(failure||![self receiptMatches:receipt]||![self creatorScopeIsCurrent]){[self failOpeningWithError:ODBindingError(4) completion:completion];return;}
        void (^issued)(ODNativeCreatorLease *,NSError *)=^(ODNativeCreatorLease *lease,NSError *error){
            if(error||!lease){[self failOpeningWithError:ODBindingError(5) completion:completion];return;}
            self->_coreLease=lease;self->_closePrepared=YES;
            self->_session=[[ODCreatorSession alloc] initWithMasterURL:self->_master contentID:self->_content game:self->_source directory:self->_workspace core:self->_core originalClientSaveScopeSHA256:self->_scope lease:lease];
            [self->_tools invalidate];self->_tools=nil;
            __weak ODBoundOriginalCreatorServices *weakSelf=self;
            self->_tools=[[ODScopedCreatorTools alloc] initWithWorkspaceURL:self->_workspace siteURL:[NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"site" isDirectory:YES] scopeIdentifier:self->_scope contextIsCurrent:^BOOL{ODBoundOriginalCreatorServices *binding=weakSelf;return binding&&[binding creatorScopeIsCurrent]&&binding->_coreLease==lease;} networkAuthorization:^BOOL(NSURL *url){ODBoundOriginalCreatorServices *binding=weakSelf;return binding&&[binding creatorScopeIsCurrent]&&binding->_networkAuthorization&&binding->_networkAuthorization(url);} error:nil];
            ODCreatorSession *issuedSession=self->_session;
            [self->_tools configureArchiveWithSnapshotProvider:^(ODCreatorArchiveDocumentCompletion callback){
                ODBoundOriginalCreatorServices *binding=weakSelf;
                if(!binding||![binding creatorScopeIsCurrent]||binding->_session!=issuedSession||binding->_coreLease!=lease){callback(nil,@"CREATOR_ARCHIVE_SCOPE_CHANGED");return;}
                [issuedSession exportArchiveDocumentsWithReply:callback];
            } documentsRestorer:^(NSDictionary<NSString *,NSData *> *documents,ODCreatorArchiveReply callback){
                ODBoundOriginalCreatorServices *binding=weakSelf;
                if(!binding||![binding creatorScopeIsCurrent]||binding->_session!=issuedSession||binding->_coreLease!=lease){callback(nil,@"CREATOR_ARCHIVE_SCOPE_CHANGED");return;}
                // Native archive validated all media first. Session commits its
                // document merge once; a durable success is never relabeled as
                // failure after commit, which could roll back referenced media.
                [issuedSession restoreArchiveDocuments:documents reply:callback];
            }];
            [self installBundledFullBundleValidation];
            NSError *presentError=nil;
            if(!self->_session||!self->_tools||![self creatorScopeIsCurrent]||![self->_coordinator presentCreatorFromUserActionWithError:&presentError]){[self failOpeningWithError:ODBindingError(6) completion:completion];return;}
            self->_opening=NO;self->_closePrepared=NO;self->_lastBindingError=nil;completion(nil);
        };
        if(self->_coreLease)issued(self->_coreLease,nil);
        else[self->_core acquireOriginalCreatorLeaseForProfile:@"local-player" expectedSaveScopeSHA256:self->_scope reply:issued];
    }];
}
- (void)failOpeningWithError:(NSError *)openingError completion:(void (^)(NSError *))completion {
    _opening=NO;_lastBindingError=openingError;
    if(_coordinator.creatorIsOpen){
        // An attached editor owns real editable state. Its confirmed close,
        // not pre-presentation cleanup, must release these capabilities.
        completion(_lastBindingError);return;
    }
    _failedPresentationRecovery=YES;
    [self recoverFailedPresentationWithCompletion:^(NSError *failure){
        self->_lastBindingError=failure?:ODOpeningRecoveredError();
        completion(self->_lastBindingError);
    }];
}
- (void)recoverFailedPresentationWithCompletion:(void (^)(NSError *))completion {
    if(!completion)return;
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self recoverFailedPresentationWithCompletion:completion];});return;}
    if(!_failedPresentationRecovery||_opening||_ending||_recoveringPresentation||_coordinator.creatorIsOpen||
       ![self creatorScopeIsCurrent]||!_pauseLease){
        _lastBindingError=ODBindingError(16);completion(_lastBindingError);return;
    }
    _recoveringPresentation=YES;
    // Initialization/recovery can publish an outbox after the opening's first
    // sync. Recheck now instead of treating that old clean receipt as current.
    _closePrepared=NO;
    BOOL active=[_coordinator canResumeOriginalGameAfterFailedPresentation];
    [self endCreatorPresentationWithActiveScene:active completion:^(NSError *failure){
        self->_recoveringPresentation=NO;
        if(failure){
            // Changed scope, dirty projection or uncertain source postconditions
            // keep the exact leases held for an explicit native recovery.
            self->_lastBindingError=ODBindingError(16);completion(self->_lastBindingError);return;
        }
        self->_failedPresentationRecovery=NO;self->_tools=nil;
        self->_lastBindingError=nil;completion(nil);
    }];
}
- (BOOL)installFullBundleValidationWithCreatorCoreURL:(NSURL *)core dependenciesURL:(NSURL *)dependencies error:(NSError **)error {
    if(!NSThread.isMainThread||!_session||!_tools||!_coreLease||!core.isFileURL||!dependencies.isFileURL||![self creatorScopeIsCurrent]){if(error)*error=ODBindingError(15);return NO;}
    NSURL *root=[_workspace URLByAppendingPathComponent:@"full-bundle-captures" isDirectory:YES];
    ODScopedCreatorTools *tools=_tools;ODCreatorSession *session=_session;
    return [session installSavedAccountFullBundleValidationWithCreatorCoreURL:core sparkingDependenciesURL:dependencies resourceRoot:root saveScope:_scope openAsset:^int(NSString *key,NSError **assetError){return [tools openAssetKey:key error:assetError];} error:error];
}
- (void)installBundledFullBundleValidation {
    NSURL *site=[NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"site" isDirectory:YES];
    NSURL *core=[site URLByAppendingPathComponent:@"core.js"],*dependencies=[site URLByAppendingPathComponent:@"sparking-dependencies.js"];
    if(![NSFileManager.defaultManager fileExistsAtPath:core.path]||![NSFileManager.defaultManager fileExistsAtPath:dependencies.path])return;
    [self installFullBundleValidationWithCreatorCoreURL:core dependenciesURL:dependencies error:nil];
}
- (BOOL)beginCreatorPresentationWithError:(NSError **)error {
    BOOL ok=[self creatorScopeIsCurrent]&&_coreLease&&_pauseLease&&[_coreLease.profileID isEqual:@"local-player"]&&[_coreLease.contentID isEqual:_content]&&[_coreLease.saveScopeSHA256 isEqual:_scope];
    if(!ok&&error)*error=ODBindingError(7);return ok;
}
- (void)prepareCreatorCloseWithCompletion:(void (^)(NSError *))completion {
    if(![self creatorScopeIsCurrent]||!_coreLease||!_pauseLease){completion(ODBindingError(8));return;}
    _closePrepared=NO;
    [_core synchronizeOriginalCreatorProjectionForProfile:@"local-player" overlayURL:_overlay reply:^(id receipt,NSError *failure){
        if(failure||![self receiptMatches:receipt]||![self creatorScopeIsCurrent]){self->_lastBindingError=ODBindingError(9);completion(self->_lastBindingError);return;}
        self->_closePrepared=YES;self->_lastBindingError=nil;completion(nil);
    }];
}
- (void)endCreatorPresentationWithActiveScene:(BOOL)active completion:(void (^)(NSError *))completion {
    if(![self creatorScopeIsCurrent]||!_pauseLease||_ending){completion(ODBindingError(10));return;}
    [_tools invalidate];
    if(!_coreLease){
        // A previous core release may have succeeded while the actual source
        // pause release failed. Revalidate/reconcile the SAME scope before a
        // native return retry; never grant the stale session another lease.
        _ending=YES;
        [_core synchronizeOriginalCreatorProjectionForProfile:@"local-player" overlayURL:_overlay reply:^(id receipt,NSError *failure){
            self->_ending=NO;
            if(failure||![self receiptMatches:receipt]||![self creatorScopeIsCurrent]){self->_lastBindingError=ODBindingError(13);completion(self->_lastBindingError);return;}
            [self finishSourcePause:active completion:completion];
        }];return;
    }
    if(!_closePrepared){[self prepareCreatorCloseWithCompletion:^(NSError *failure){if(failure)completion(failure);else[self endCreatorPresentationWithActiveScene:active completion:completion];}];return;}
    _ending=YES;
    [_core releaseOriginalCreatorLease:_coreLease reply:^(id receipt,NSError *failure){
        self->_ending=NO;
        if(failure||![self receiptMatches:receipt]||![self creatorScopeIsCurrent]){self->_closePrepared=NO;self->_lastBindingError=ODBindingError(11);completion(self->_lastBindingError);return;}
        self->_coreLease=nil;
        [self finishSourcePause:active completion:completion];
    }];
}
- (void)finishSourcePause:(BOOL)active completion:(void (^)(NSError *))completion {
    NSError *pauseError=nil;
    if(![self creatorScopeIsCurrent]||!_pauseLease||!ODDuoEndCreatorPause(_pauseLease,active&&[self creatorScopeIsCurrent],&pauseError)){_lastBindingError=ODBindingError(12);completion(_lastBindingError);return;}
    _pauseLease=nil;_closePrepared=NO;_lastBindingError=nil;completion(nil);
}
@end
