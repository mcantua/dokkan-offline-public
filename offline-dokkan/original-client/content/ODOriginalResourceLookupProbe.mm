#import "ODOriginalResourceLookupProbe.h"
#import "../duo/ODDuoEngineState.h"
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string>
#include <cstring>
#include <cstdint>

namespace {
#if !defined(_LIBCPP_ABI_VERSION) || _LIBCPP_ABI_VERSION != 1
#error Original Apple std::__1 string ABI required
#endif
#if defined(_LIBCPP_ABI_STRING_TRIVIAL_ABI)
#error Original nontrivial indirect std::string return ABI required
#endif
static_assert(sizeof(void *)==8 && sizeof(std::string)==24 && alignof(std::string)==8,
    "Original arm64 Apple string ABI required");
enum Function { ODFileUtilsExistingSource, ODFileUtilsConstructorSource,
    ODFileUtilsFullPath, ODFunctionCount };
struct Pin { Function function;uint32_t bytes;const char *sha; };
static const Pin Pins[]={
    {ODFileUtilsExistingSource,148,"cec8c606d28e7ff8d72bec792c1c4900f8ca09e7890f8ac22d5dcf8ed83e8b28"},
    {ODFileUtilsConstructorSource,132,"46a229b83d625d34eeaff7f36430dc4e0003ac29f54788ad17c1b76e27ddf969"},
    {ODFileUtilsFullPath,660,"1a43222687527b80c5ed4e36bac248868cfca9e40aa29346b30d45d07421339b"},
};
// Source X0 receiver, X1 const24-byte string&, X8 nontrivial string result.
// Apple libc++ owns construction/destruction; no opaque buffer/deleter guess.
using FullPath=std::string (*)(void *,const std::string &);
static NSData *Read(uintptr_t address,size_t count) {
    if(!address||!count||count>16384||address>UINTPTR_MAX-count)return nil;
    NSMutableData *bytes=[NSMutableData dataWithLength:count];vm_size_t copied=0;
    kern_return_t rc=vm_read_overwrite(mach_task_self(),(vm_address_t)address,count,
        (vm_address_t)(uintptr_t)bytes.mutableBytes,&copied);
    return rc==KERN_SUCCESS&&copied==count?[bytes copy]:nil;
}
static bool Pointer(uintptr_t address,uintptr_t &value) {
    NSData *bytes=Read(address,sizeof(value));if(!bytes)return false;
    memcpy(&value,bytes.bytes,sizeof(value));return true;
}
static bool Hash(const void *bytes,size_t count,const char *expected) {
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];CC_SHA256(bytes,(CC_LONG)count,digest);
    static const char digits[]="0123456789abcdef";
    for(size_t i=0;i<sizeof(digest);++i)
        if(digits[digest[i]>>4]!=expected[i*2]||digits[digest[i]&15]!=expected[i*2+1])return false;
    return expected[64]==0;
}
static bool ULEB(const uint8_t *bytes,size_t end,size_t &cursor,uint64_t &value) {
    value=0;unsigned shift=0;
    while(cursor<end&&shift<64){uint8_t next=bytes[cursor++];
        if(shift==63&&(next&0x7e))return false;value|=uint64_t(next&0x7f)<<shift;
        if(!(next&0x80))return true;shift+=7;}
    return false;
}
struct Code { uint64_t base=0,text=0,size=0;uint32_t textOffset=0;uint64_t entry[ODFunctionCount]={}; };
static bool Resolve(NSData *file,Code &code) {
    if(file.length<sizeof(mach_header_64))return false;
    const uint8_t *bytes=(const uint8_t *)file.bytes;mach_header_64 header;
    memcpy(&header,bytes,sizeof(header));
    if(header.magic!=MH_MAGIC_64||header.cputype!=CPU_TYPE_ARM64||header.filetype!=MH_DYLIB||
       header.ncmds>1024||header.sizeofcmds>11224||sizeof(header)+uint64_t(header.sizeofcmds)>file.length)return false;
    linkedit_data_command starts={};size_t position=sizeof(header),commandsEnd=position+header.sizeofcmds;
    for(uint32_t i=0;i<header.ncmds;++i){load_command command;
        if(position+sizeof(command)>commandsEnd)return false;memcpy(&command,bytes+position,sizeof(command));
        if(command.cmdsize<8||command.cmdsize%8||position+uint64_t(command.cmdsize)>commandsEnd)return false;
        if(command.cmd==LC_SEGMENT_64){segment_command_64 segment;
            if(command.cmdsize<sizeof(segment))return false;memcpy(&segment,bytes+position,sizeof(segment));
            if(command.cmdsize!=sizeof(segment)+uint64_t(segment.nsects)*sizeof(section_64))return false;
            if(!strncmp(segment.segname,"__TEXT",16)){
                if(code.base)return false;code.base=segment.vmaddr;
                for(uint32_t j=0;j<segment.nsects;++j){section_64 section;
                    memcpy(&section,bytes+position+sizeof(segment)+j*sizeof(section),sizeof(section));
                    if(!strncmp(section.sectname,"__text",16)){
                        if(code.text||section.offset>file.length||section.size>file.length-section.offset||
                           section.addr>UINT64_MAX-section.size)return false;
                        code.text=section.addr;code.size=section.size;code.textOffset=section.offset;}
                }
            }
        }else if(command.cmd==LC_FUNCTION_STARTS){
            if(starts.datasize||command.cmdsize!=sizeof(starts))return false;memcpy(&starts,bytes+position,sizeof(starts));}
        position+=command.cmdsize;
    }
    if(position!=commandsEnd||!code.base||!code.text||!code.size||!starts.datasize||
       starts.datasize>8u*1024u*1024u||starts.dataoff+uint64_t(starts.datasize)>file.length)return false;
    size_t cursor=starts.dataoff,end=cursor+starts.datasize;uint64_t current=code.base,previous=0;
    unsigned counts[ODFunctionCount]={};bool terminated=false;
    while(cursor<end){uint64_t delta=0;if(!ULEB(bytes,end,cursor,delta))return false;
        uint64_t next;
        if(!delta){next=code.text+code.size;terminated=true;}
        else {if(current>UINT64_MAX-delta)return false;next=current+delta;}
        if(previous){if(next<=previous)return false;
            uint64_t length=next-previous;
            if(previous>=code.text&&next<=code.text+code.size){
                size_t offset=code.textOffset+size_t(previous-code.text);
                for(const Pin &pin:Pins)if(length==pin.bytes&&Hash(bytes+offset,pin.bytes,pin.sha)){
                    code.entry[pin.function]=previous;++counts[pin.function];}
            }
        }
        if(terminated)break;previous=next;current=next;
    }
    if(!terminated)return false;
    for(unsigned count:counts)if(count!=1)return false;
    return true;
}
static bool Loaded(NSString *path,const mach_header *&header,intptr_t &slide) {
    unsigned count=0;
    for(uint32_t i=0;i<_dyld_image_count();++i){const char *name=_dyld_get_image_name(i);if(!name)continue;
        NSString *candidate=[[NSString stringWithUTF8String:name] stringByResolvingSymlinksInPath];
        if([candidate isEqual:path]){header=_dyld_get_image_header(i);slide=_dyld_get_image_vmaddr_slide(i);++count;}}
    return count==1&&header;
}
static bool Slide(uint64_t address,intptr_t slide,uintptr_t &result) {
    if(slide>=0){if(address>UINTPTR_MAX-uint64_t(slide))return false;result=address+uint64_t(slide);}
    else {uint64_t amount=uint64_t(-(slide+1))+1;if(address<amount)return false;result=address-amount;}
    return true;
}
static bool ReadonlyPins(const uintptr_t *entries) {
    for(const Pin &pin:Pins){NSData *body=Read(entries[pin.function],pin.bytes);
        if(!body||!Hash(body.bytes,pin.bytes,pin.sha))return false;}
    return true;
}
static bool AddressPair(NSData *file,const Code &code,Function function,size_t at,
        uint32_t reg,uint64_t &address) {
    uint64_t start=code.entry[function];
    if(start<code.text||start-code.text>code.size||at+8>code.size-(start-code.text))return false;
    size_t offset=code.textOffset+size_t(start-code.text)+at;uint32_t adrp=0,add=0;
    memcpy(&adrp,(const uint8_t *)file.bytes+offset,4);memcpy(&add,(const uint8_t *)file.bytes+offset+4,4);
    if((adrp&0x9f00001fu)!=(0x90000000u|reg)||
       (add&0xffc003ffu)!=(0x91000000u|(reg<<5)|reg))return false;
    int64_t delta=int64_t(((adrp>>5)&0x7ffffu)<<2)|int64_t((adrp>>29)&3u);
    if(delta&(int64_t(1)<<20))delta-=int64_t(1)<<21;
    uint64_t page=(start+at)&~uint64_t(4095);intptr_t relative=intptr_t(delta*4096);
    uintptr_t result=0;if(!Slide(page,relative,result))return false;
    uint64_t immediate=(add>>10)&4095u;if(result>UINT64_MAX-immediate)return false;
    address=uint64_t(result)+immediate;return true;
}
static bool HostStringABI(void) {
    std::string small="probe",large="original-resource-probe-layout";
    unsigned char a[24],b[24];memcpy(a,&small,24);memcpy(b,&large,24);
    uintptr_t pointer=0;uint64_t size=0;memcpy(&pointer,b,8);memcpy(&size,b+8,8);
    return a[23]==5&&!memcmp(a,"probe",5)&&(b[23]&0x80)&&
        pointer==reinterpret_cast<uintptr_t>(large.c_str())&&size==large.size();
}
static bool OwnRegular(NSURL *root,NSString *relative) {
    if(!root.isFileURL||!root.path.isAbsolutePath||!relative.length)return false;
    // Root is already derived from a canonical Foundation anchor. In
    // particular do not resolve its appended assets child before NOFOLLOW.
    int fd=open(root.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
    if(fd<0)return false;bool result=false;NSArray<NSString *> *parts=[relative componentsSeparatedByString:@"/"];
    for(NSUInteger i=0;i<parts.count;++i){NSString *part=parts[i];
        if(!part.length||[part isEqual:@"."]||[part isEqual:@".."]||
           [@[@"user",@"save",@"saves"] containsObject:part.lowercaseString])break;
        if(i+1==parts.count){struct stat info={};result=!fstatat(fd,part.fileSystemRepresentation,&info,AT_SYMLINK_NOFOLLOW)&&
            S_ISREG(info.st_mode)&&!S_ISLNK(info.st_mode);break;}
        int child=openat(fd,part.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
        if(child<0)break;close(fd);fd=child;
    }
    close(fd);return result;
}
struct Candidate {const char *label;const char *relative;};
// Exact members in the retained authenticated original iPhone inventory.
// These are availability probes, not a claim that their filename formatter
// or every battle dependency has been independently recovered.
static const Candidate Candidates[]={
    {"fixedPlayerCard","character/card/1022910.cpk"},
    {"fixedPlayerCharacter","ingame/battle/character/01196.cpk"},
    {"backgroundCandidate","ingame/battle/bg/battle_bg_00019.cpk"},
    {"musicWaveCandidate","bgm/bgm_149.awb"},
};
static NSString *Resolved(FullPath function,uintptr_t instance,const std::string &input) {
    std::string result=function(reinterpret_cast<void *>(instance),input);
    if(result.empty()||result.size()>4096||result.find('\0')!=std::string::npos)return nil;
    NSString *path=[[NSString alloc] initWithBytes:result.data() length:result.size() encoding:NSUTF8StringEncoding];
    return path.isAbsolutePath?path:nil;
}
static bool Matches(NSString *resolved,NSURL *root,NSURL *nativeSpelling,NSString *relative) {
    NSString *expected=[[root URLByAppendingPathComponent:relative] path];
    NSString *nativeExpected=[[nativeSpelling URLByAppendingPathComponent:relative] path];
    // Compare only trusted own-root spellings. Never resolve/stat an arbitrary
    // native-returned path, which could otherwise reach an unrelated tree.
    return resolved&&([resolved isEqual:expected]||[resolved isEqual:nativeExpected])&&OwnRegular(root,relative);
}
static NSError *Failure(void){return [NSError errorWithDomain:@"OfflineDokkan.ResourceLookupProbe" code:1
    userInfo:@{NSLocalizedDescriptionKey:@"Original resource observation is unavailable."}];}
}

@interface ODOriginalResourceLookupProbe ()
- (instancetype)initPrivateWithPath:(NSString *)path image:(uintptr_t)image
    entries:(const uintptr_t *)entries storage:(uintptr_t)storage table:(uintptr_t)table;
@end
@implementation ODOriginalResourceLookupProbe {
    NSString *_path;uintptr_t _image,_entries[ODFunctionCount],_storage,_table;
}
- (instancetype)initPrivateWithPath:(NSString *)path image:(uintptr_t)image
    entries:(const uintptr_t *)entries storage:(uintptr_t)storage table:(uintptr_t)table {
    if((self=[super init])){_path=[path copy];_image=image;_storage=storage;_table=table;
        memcpy(_entries,entries,sizeof(_entries));}return self;
}
- (NSDictionary *)observeForOriginalAppController:(id)original {
    NSDictionary *unavailable=@{@"observationPerformed":@NO,@"searchPathsChanged":@NO,
        @"singletonCreated":@NO,@"resourceContentsRead":@NO,@"runtimeGameplayVerified":@NO};
    if(!NSThread.isMainThread||object_getClass(self)!=ODOriginalResourceLookupProbe.class||
       UIApplication.sharedApplication.applicationState!=UIApplicationStateActive||
       ![NSBundle.mainBundle.bundleIdentifier hasPrefix:@"org.offlinedokkan."]||!HostStringABI())return unavailable;
    ODDuoEngineState state={};uintptr_t scene=0,pending=0,instance=0,table=0,resolver=0;
    const mach_header *header=nullptr;intptr_t slide=0;
    if(!Loaded(_path,header,slide)||reinterpret_cast<uintptr_t>(header)!=_image||
       !ODDuoInspectPinnedEngine(original,&state)||state.image!=_image||state.paused||state.stopped||
       !Pointer(state.director+0x170,scene)||!scene||!Pointer(state.director+0x178,pending)||pending||
       !ReadonlyPins(_entries)||!Pointer(_storage,instance)||!instance||!Pointer(instance,table)||table!=_table||
       !Pointer(table+0x48,resolver)||resolver!=_entries[ODFileUtilsFullPath])return unavailable;
    NSURL *nativeBundle=NSBundle.mainBundle.resourceURL;
    NSURL *nativeDocuments=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    if(!nativeBundle.isFileURL||!nativeDocuments.isFileURL)return unavailable;
    // Only the authoritative Foundation anchors are canonicalized. Every
    // appended assets directory and resource child still meets NOFOLLOW.
    NSURL *bundle=nativeBundle.URLByResolvingSymlinksInPath;
    NSURL *documents=nativeDocuments.URLByResolvingSymlinksInPath;
    NSURL *assets=[documents URLByAppendingPathComponent:@"assets" isDirectory:YES];
    NSURL *nativeAssets=[nativeDocuments URLByAppendingPathComponent:@"assets" isDirectory:YES];
    NSMutableDictionary *report=[@{@"observationPerformed":@YES,@"existingOriginalSingletonUsed":@YES,
        @"searchPathsChanged":@NO,@"singletonCreated":@NO,@"resourceContentsRead":@NO,
        @"originalFilenameCacheMayPopulate":@YES,@"runtimeGameplayVerified":@NO} mutableCopy];
    try {
        FullPath function=reinterpret_cast<FullPath>(resolver);
        for(const Candidate &candidate:Candidates){
            NSString *relative=[NSString stringWithUTF8String:candidate.relative];
            NSString *tutorial=[@"tutorial0/" stringByAppendingString:relative];
            NSString *canonical=Resolved(function,instance,std::string(candidate.relative));
            NSString *prefixed=Resolved(function,instance,std::string("assets/")+candidate.relative);
            NSString *bundled=Resolved(function,instance,std::string("tutorial0/")+candidate.relative);
            uintptr_t current=0;if(!Pointer(_storage,current)||current!=instance)return unavailable;
            report[[NSString stringWithUTF8String:candidate.label]]=@{
                @"expectedOriginalBundleFilePresent":@(OwnRegular(bundle,tutorial)),
                @"expectedOwnAssetsTutorialFilePresent":@(OwnRegular(assets,tutorial)),
                @"canonicalReturnedAbsolutePath":@(canonical!=nil),
                @"assetsPrefixedReturnedAbsolutePath":@(prefixed!=nil),
                @"tutorialReturnedAbsolutePath":@(bundled!=nil),
                @"canonicalResolvedToOriginalRoot":@(Matches(canonical,bundle,nativeBundle,relative)),
                @"canonicalResolvedToOriginalTutorial":@(Matches(canonical,bundle,nativeBundle,tutorial)),
                @"canonicalResolvedToOwnAssets":@(Matches(canonical,assets,nativeAssets,relative)),
                @"assetsPrefixedResolvedToOriginalTutorial":@(Matches(prefixed,bundle,nativeBundle,tutorial)),
                @"assetsPrefixedResolvedToOwnAssets":@(Matches(prefixed,assets,nativeAssets,relative)),
                @"tutorialResolvedToOwnAssetsTutorial":@(Matches(bundled,assets,nativeAssets,tutorial)),
                @"tutorialResolvedToOriginalTutorial":@(Matches(bundled,bundle,nativeBundle,tutorial))};
        }
    }catch(...){return unavailable;}
    return [report copy];
}
@end

ODOriginalResourceLookupProbe *ODCreateOriginalResourceLookupProbeForAdmittedImage(
        NSURL *url,NSData *file,NSError **error) {
    Code code={};uint64_t storageVM=0,tableVM=0;uintptr_t entries[ODFunctionCount]={},storage=0,table=0;
    const mach_header *header=nullptr;intptr_t slide=0;
    NSString *path=url.isFileURL?url.path.stringByResolvingSymlinksInPath:nil;
    if(!NSThread.isMainThread||!path.length||!Resolve(file,code)||!Loaded(path,header,slide)||
       !AddressPair(file,code,ODFileUtilsExistingSource,12,20,storageVM)||
       !AddressPair(file,code,ODFileUtilsConstructorSource,24,8,tableVM)||
       !Slide(storageVM,slide,storage)||!Slide(tableVM,slide,table)){
        if(error)*error=Failure();return nil;}
    for(unsigned i=0;i<ODFunctionCount;++i)if(!Slide(code.entry[i],slide,entries[i])){
        if(error)*error=Failure();return nil;}
    if(!ReadonlyPins(entries)){if(error)*error=Failure();return nil;}
    return [[ODOriginalResourceLookupProbe alloc] initPrivateWithPath:path image:reinterpret_cast<uintptr_t>(header)
        entries:entries storage:storage table:table];
}
