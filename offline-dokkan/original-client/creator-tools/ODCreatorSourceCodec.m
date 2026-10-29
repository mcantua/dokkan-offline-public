#import "ODCreatorSourceCodec.h"
#define ForgeStorageContext ODScopedCreatorStorageContext
#import "../../../unit-creator/ios-objc/Host.h"
#import "apk_libbase.h"
#import "../master/source_material.h"
#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>
#import <sys/stat.h>
#import <sys/mman.h>
#import <fcntl.h>
#import <unistd.h>
#import <stdatomic.h>
#import <stdbool.h>
#import <string.h>

static NSString *const ODSourceAPKHash = @"10ba87c268961285f26269d2110d5af4e114b7853d1baabf775fa33411bb3049";
static const uint64_t ODSourceAPKBytes = 108832078;
static int ODSourceSHA(void *context,const void *bytes,size_t length,char hex[65]) {
    (void)context;if(length>UINT32_MAX)return -1;
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];CC_SHA256(bytes,(CC_LONG)length,hash);
    static const char digits[]="0123456789abcdef";
    for(size_t i=0;i<sizeof(hash);i++){hex[2*i]=digits[hash[i]>>4];hex[2*i+1]=digits[hash[i]&15];}
    hex[64]=0;return 0;
}
static NSDictionary *ODSourceQuery(NSString *service,NSString *account) {
    return @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
             (__bridge id)kSecAttrService:service,(__bridge id)kSecAttrAccount:account};
}
static BOOL ODSourceStore(NSString *service,NSString *account,NSData *data) {
    NSDictionary *query=ODSourceQuery(service,account);
    OSStatus result=SecItemUpdate((__bridge CFDictionaryRef)query,(__bridge CFDictionaryRef)@{(__bridge id)kSecValueData:data});
    if(result==errSecItemNotFound){NSMutableDictionary *add=[query mutableCopy];add[(__bridge id)kSecValueData]=data;add[(__bridge id)kSecAttrAccessible]=(__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly;result=SecItemAdd((__bridge CFDictionaryRef)add,NULL);}
    return result==errSecSuccess;
}
static BOOL ODSourceExists(NSString *service,NSString *account) {
    return SecItemCopyMatching((__bridge CFDictionaryRef)ODSourceQuery(service,account),NULL)==errSecSuccess;
}
static BOOL ODSourceProof(NSString *service) {
    NSMutableDictionary *q=[ODSourceQuery(service,@"source.apk.sha256") mutableCopy];q[(__bridge id)kSecReturnData]=@YES;
    CFTypeRef result=NULL;if(SecItemCopyMatching((__bridge CFDictionaryRef)q,&result)!=errSecSuccess)return NO;
    NSData *data=(__bridge_transfer NSData *)result;
    return [data isEqual:[ODSourceAPKHash dataUsingEncoding:NSUTF8StringEncoding]];
}
@implementation ODCreatorSourceCodec {
    ODScopedCreatorStorageContext *_storage;atomic_bool _busy;
}
- (instancetype)initWithStorageContext:(ODScopedCreatorStorageContext *)storage {
    if((self=[super init])){_storage=storage;atomic_init(&_busy,false);}return self;
}
- (BOOL)isAdmitted {
    return [_storage isCurrent]&&ODSourceProof(_storage.sourceKeychainService)&&
        ODSourceExists(_storage.sourceKeychainService,@"sparking.db")&&ODSourceExists(_storage.sourceKeychainService,@"sparking.sprk");
}
- (NSDictionary *)status {
    BOOL ready=[self isAdmitted];
    return @{@"configured":@(ready),@"hasDatabaseKey":@(ready),@"hasPatchKey":@(ready),
             @"sourceVersion":@"6.6.0",@"apkSHA256":ODSourceAPKHash,@"rawSourceKeysReturned":@NO};
}
- (void)importAPKAtRelativePath:(NSString *)path reply:(void (^)(id,NSString *))reply {
    NSString *file=[_storage resolve:path];
    if(!file||[file isEqualToString:_storage.storageRoot]){reply(nil,@"Choose your admitted personal APK inside this Creator workspace.");return;}
    bool expected=false;if(!atomic_compare_exchange_strong(&_busy,&expected,true)){reply(nil,@"Finish the current personal-source import first.");return;}
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
        int fd=-1;void *mapping=MAP_FAILED,*library=NULL;size_t libraryBytes=0;od_source_material material;memset(&material,0,sizeof(material));NSString *failure=nil;
        do {
            fd=open(file.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);struct stat before,after;
            if(fd<0||fstat(fd,&before)||!S_ISREG(before.st_mode)||(uint64_t)before.st_size!=ODSourceAPKBytes){failure=@"This personal APK does not match the admitted source version.";break;}
            mapping=mmap(NULL,(size_t)before.st_size,PROT_READ,MAP_PRIVATE,fd,0);char digest[65];
            if(mapping==MAP_FAILED||ODSourceSHA(NULL,mapping,(size_t)before.st_size,digest)||strcmp(digest,ODSourceAPKHash.UTF8String)){failure=@"This personal APK does not match the admitted source version.";break;}
            if(od_creator_apk_libbase(mapping,(size_t)before.st_size,&library,&libraryBytes)||od_source_material_derive(library,libraryBytes,ODSourceSHA,NULL,&material)){failure=@"The source library is unsupported or changed.";break;}
            if(fstat(fd,&after)||before.st_dev!=after.st_dev||before.st_ino!=after.st_ino||before.st_size!=after.st_size||
                before.st_mtimespec.tv_sec!=after.st_mtimespec.tv_sec||before.st_mtimespec.tv_nsec!=after.st_mtimespec.tv_nsec||![self->_storage isCurrent]){failure=@"The Creator source or binding changed.";break;}
            static const char digits[]="0123456789abcdef";char patchHex[64];for(size_t i=0;i<32;i++){patchHex[2*i]=digits[material.sprk_key[i]>>4];patchHex[2*i+1]=digits[material.sprk_key[i]&15];}
            NSData *database=[NSData dataWithBytes:material.database_passphrase length:64],*patch=[NSData dataWithBytes:patchHex length:64];
            BOOL stored=ODSourceStore(self->_storage.sourceKeychainService,@"sparking.db",database)&&
                ODSourceStore(self->_storage.sourceKeychainService,@"sparking.sprk",patch)&&
                ODSourceStore(self->_storage.sourceKeychainService,@"source.apk.sha256",[ODSourceAPKHash dataUsingEncoding:NSUTF8StringEncoding]);
            volatile char *wipe=patchHex;for(size_t i=0;i<sizeof(patchHex);i++)wipe[i]=0;
            if(!stored)failure=@"The iPhone could not save the personal-source capability in Keychain.";
        }while(0);
        od_source_material_clear(&material);od_creator_apk_library_clear(library,libraryBytes);
        if(mapping!=MAP_FAILED)munmap(mapping,(size_t)ODSourceAPKBytes);if(fd>=0)close(fd);
        atomic_store(&self->_busy,false);
        dispatch_async(dispatch_get_main_queue(),^{if(![self->_storage isCurrent])reply(nil,@"The Creator workspace changed.");else reply(failure?nil:[self status],failure);});
    });
}
@end
