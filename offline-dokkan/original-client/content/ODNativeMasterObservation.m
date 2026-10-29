#import "ODNativeMasterObservation.h"
#import "../duo/ODDuoEngineState.h"
#import <CommonCrypto/CommonDigest.h>
#include <mach/mach.h>
#include <stdint.h>
#include <string.h>

static BOOL ODMasterRead(uintptr_t source,void *target,size_t bytes) {
    if(!source||!target||!bytes||bytes>512||source>UINTPTR_MAX-bytes)return NO;
    _Static_assert(sizeof(vm_address_t)==sizeof(uintptr_t),"Requires native arm64 VM addresses");
    _Static_assert(sizeof(vm_size_t)>=sizeof(size_t),"Requires native VM size width");
    vm_size_t copied=0;
    return vm_read_overwrite(mach_task_self(),(vm_address_t)source,
        (vm_size_t)bytes,(vm_address_t)target,&copied)==KERN_SUCCESS&&copied==bytes;
}
static BOOL ODMasterCode(uintptr_t image,uintptr_t rva,size_t bytes,const char *expected) {
    unsigned char body[340],digest[CC_SHA256_DIGEST_LENGTH];
    if(bytes>sizeof body||rva>UINTPTR_MAX-image||!ODMasterRead(image+rva,body,bytes))return NO;
    CC_SHA256(body,(CC_LONG)bytes,digest);char hex[65];
    static const char digits[]="0123456789abcdef";
    for(NSUInteger i=0;i<sizeof digest;i++){hex[i*2]=digits[digest[i]>>4];hex[i*2+1]=digits[digest[i]&15];}
    hex[64]=0;return !strcmp(hex,expected);
}
static BOOL ODMasterLanguage(uintptr_t image,BOOL *isSourceDefault) {
    unsigned char object[24],text[23];uint64_t length=0;
    if(image>UINTPTR_MAX-0x30c2f18||!ODMasterRead(image+0x30c2f18,object,sizeof object))return NO;
    // The proved source English default fits this inline representation.
    // Longer/unknown forms stay unobserved; never follow a replaceable heap pointer.
    if((int8_t)object[23]<0)return NO;
    length=object[23];if(!length||length>22||object[length])return NO;
    memcpy(text,object,(size_t)length);
    for(uint64_t i=0;i<length;i++)if(!((text[i]>='a'&&text[i]<='z')||
        (text[i]>='A'&&text[i]<='Z')||(text[i]>='0'&&text[i]<='9')||text[i]=='_'||text[i]=='-'))return NO;
    *isSourceDefault=length==2&&text[0]=='e'&&text[1]=='n';return YES;
}
NSDictionary *ODCopyOriginalMasterObservation(id original) {
    ODDuoEngineState state={0};
    if(!NSThread.isMainThread||!ODDuoInspectPinnedEngine(original,&state))return nil;
    uintptr_t image=state.image;
    // Exact source bodies establish only the read layout/role. Hashing a
    // checker does NOT mean that checker has run or returned success.
    if(!ODMasterCode(image,0x44f9ec,100,"ecad0e17cdfe18d3e4d39ea9258da41b2af648ebc9b13240a26cd4e1f895daa4")||
       !ODMasterCode(image,0x44fa50,316,"ac277142cbeb5788e5b5983ce1dd621e49a3d359803f87a2e95c41fce277e46b")||
       !ODMasterCode(image,0x44ff74,340,"d80729df6d35f7869b0c9ae30f6f897c983a985914a6b45ea2576070fb90a3e1")||
       !ODMasterCode(image,0x41caf8,36,"511ba43ab59746dc37d87e171f30bcb0d679aa9a494660714689a717bd431a61")||
       !ODMasterCode(image,0x41dda0,12,"d6afb961a1ae81865f4ebf2f4554d8cceb30f1c5d0017e79079dafcd42398af1"))return nil;
    uintptr_t manager=0,confirmed=0,cache=0,confirmedCache=0,vtable=0;
    if(image>UINTPTR_MAX-0x30c4d10||!ODMasterRead(image+0x30c4d10,&manager,sizeof manager))return nil;
    BOOL present=manager!=0,handle=NO,stable=YES;
    if(present){
        if(manager>UINTPTR_MAX-16||!ODMasterRead(manager,&vtable,sizeof vtable)||vtable!=image+0x2a7bb78||
           !ODMasterRead(manager+16,&cache,sizeof cache)||!ODMasterRead(manager+16,&confirmedCache,sizeof confirmedCache))return nil;
        handle=cache!=0;stable=cache==confirmedCache;
    }
    if(!ODMasterRead(image+0x30c4d10,&confirmed,sizeof confirmed))return nil;
    stable=stable&&manager==confirmed;
    BOOL english=NO,language=ODMasterLanguage(image,&english);
    return @{@"schema":@1,@"source":@"actual-original-engine-read-only",
        @"pinnedOriginalImageObserved":@YES,@"nativeMasterSingletonPresent":@(present),
        @"nativeCachedHandlePresent":@(handle),@"cacheObservationStable":@(stable),
        @"shortNativeLanguageObserved":@(language),@"nativeLanguageMatchesSourceEnglishDefault":@(language&&english),
        @"selectedMasterFileObserved":@NO,@"bundleFallbackSelectionObserved":@NO,
        @"originalSchemaOutcomeObserved":@NO,@"nativeCipherCompatibilityVerified":@NO,
        @"nativeMasterAccepted":@NO,@"hostCalledNativeDatabaseFunction":@NO,
        @"hostReadOrCalledKeyProvider":@NO,@"cachedHandleWritten":@NO};
}
