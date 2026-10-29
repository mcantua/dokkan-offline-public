#import "ODOriginalNativeOrigin.h"
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <dlfcn.h>
#include <stdint.h>
#include <string.h>

_Static_assert(sizeof(vm_address_t)==sizeof(uintptr_t),"Self-memory VM addresses must preserve native pointers");
_Static_assert(sizeof(vm_size_t)>=sizeof(NSUInteger),"Self-memory VM sizes must preserve bounded lengths");

static NSString *const ODGetterHash=@"2de88ff35a07d9771c8b17dc41955d0998b04d47fbe09f0da11ba4cc74550e97";
static NSString *const ODConstructorHash=@"7b120b08aed81ff767330cd6b5cc6d1c7d5205f3a05074dae110d15a24aa105c";
typedef const void *(*ODNativeConfigGetter)(void);
typedef struct {uint64_t getter,constructor,text,size,base;uint32_t textOffset;} ODOriginCode;
static NSError *ODOriginFailure(void){return [NSError errorWithDomain:@"OfflineDokkan.NativeOrigin" code:1
    userInfo:@{NSLocalizedDescriptionKey:@"ORIGINAL_NATIVE_ORIGIN_UNAVAILABLE"}];}
static NSString *ODOriginHash(const void *bytes,NSUInteger count){
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];CC_SHA256(bytes,(CC_LONG)count,digest);
    char hex[65];static const char digits[]="0123456789abcdef";
    for(NSUInteger i=0;i<sizeof(digest);++i){hex[i*2]=digits[digest[i]>>4];hex[i*2+1]=digits[digest[i]&15];}
    hex[64]=0;return [NSString stringWithUTF8String:hex];
}
static NSData *ODOriginRead(uint64_t address,NSUInteger count){
    if(!address||!count||count>16384||address>UINT64_MAX-count)return nil;
    NSMutableData *bytes=[NSMutableData dataWithLength:count];vm_size_t copied=0;
    kern_return_t rc=vm_read_overwrite(mach_task_self(),(vm_address_t)(uintptr_t)address,
        (vm_size_t)count,(vm_address_t)(uintptr_t)bytes.mutableBytes,&copied);
    return rc==KERN_SUCCESS&&copied==count?[bytes copy]:nil;
}
static BOOL ODOriginSlide(uint64_t value,intptr_t slide,uint64_t *result){
    if(slide>=0){if(value>UINT64_MAX-(uint64_t)slide)return NO;*result=value+(uint64_t)slide;}
    else {uint64_t amount=(uint64_t)(-(slide+1))+1;if(value<amount)return NO;*result=value-amount;}
    return YES;
}
static BOOL ODOriginULEB(const uint8_t *bytes,NSUInteger end,NSUInteger *cursor,uint64_t *value){
    uint64_t out=0;unsigned shift=0;
    while(*cursor<end&&shift<64){uint8_t next=bytes[(*cursor)++];
        if(shift==63&&(next&0x7e))return NO;out|=(uint64_t)(next&0x7f)<<shift;
        if(!(next&0x80)){*value=out;return YES;}shift+=7;}
    return NO;
}
static BOOL ODOriginCodeFromVerifiedFile(NSData *file,ODOriginCode *result){
    if(file.length<sizeof(struct mach_header_64))return NO;
    const uint8_t *bytes=file.bytes;struct mach_header_64 header;memcpy(&header,bytes,sizeof(header));
    if(header.magic!=MH_MAGIC_64||header.cputype!=CPU_TYPE_ARM64||header.filetype!=MH_DYLIB||
       header.ncmds>1024||header.sizeofcmds>11224||sizeof(header)+(uint64_t)header.sizeofcmds>file.length)return NO;
    ODOriginCode code={0};struct linkedit_data_command starts={0};NSUInteger position=sizeof(header);
    for(uint32_t i=0;i<header.ncmds;++i){
        struct load_command command;if(position+sizeof(command)>sizeof(header)+header.sizeofcmds)return NO;
        memcpy(&command,bytes+position,sizeof(command));
        if(command.cmdsize<8||command.cmdsize%8||position+(uint64_t)command.cmdsize>sizeof(header)+header.sizeofcmds)return NO;
        if(command.cmd==LC_SEGMENT_64){
            struct segment_command_64 segment;if(command.cmdsize<sizeof(segment))return NO;
            memcpy(&segment,bytes+position,sizeof(segment));
            if(command.cmdsize!=sizeof(segment)+(uint64_t)segment.nsects*sizeof(struct section_64))return NO;
            if(!strncmp(segment.segname,"__TEXT",16)){
                code.base=segment.vmaddr;
                for(uint32_t j=0;j<segment.nsects;++j){struct section_64 section;
                    memcpy(&section,bytes+position+sizeof(segment)+j*sizeof(section),sizeof(section));
                    if(!strncmp(section.sectname,"__text",16)){
                        if(code.text||section.offset>file.length||section.size>file.length-section.offset||
                           section.addr>UINT64_MAX-section.size)return NO;
                        code.text=section.addr;code.size=section.size;code.textOffset=section.offset;
                    }
                }
            }
        }else if(command.cmd==LC_FUNCTION_STARTS){
            if(starts.datasize||command.cmdsize!=sizeof(starts))return NO;memcpy(&starts,bytes+position,sizeof(starts));
        }
        position+=command.cmdsize;
    }
    if(position!=sizeof(header)+header.sizeofcmds||!code.base||!code.text||!code.size||
       !starts.datasize||starts.datasize>8u*1024u*1024u||starts.dataoff+(uint64_t)starts.datasize>file.length)return NO;
    NSUInteger cursor=starts.dataoff,end=cursor+starts.datasize;uint64_t current=code.base,previous=0;BOOL terminated=NO;
    NSUInteger getterCount=0,constructorCount=0;
    while(cursor<end){uint64_t delta=0;if(!ODOriginULEB(bytes,end,&cursor,&delta))return NO;
        uint64_t next;if(!delta){next=code.text+code.size;terminated=YES;}
        else {if(current>UINT64_MAX-delta)return NO;next=current+delta;}
        if(previous){
            if(next<=previous)return NO;
            uint64_t length=next-previous;
            if(previous>=code.text&&next<=code.text+code.size&&(length==80||length==504)){
                NSUInteger offset=code.textOffset+(NSUInteger)(previous-code.text);
                NSString *digest=ODOriginHash(bytes+offset,(NSUInteger)length);
                if(length==80&&[digest isEqual:ODGetterHash]){code.getter=previous;++getterCount;}
                if(length==504&&[digest isEqual:ODConstructorHash]){code.constructor=previous;++constructorCount;}
            }
        }
        if(terminated)break;previous=next;current=next;
    }
    if(!terminated||getterCount!=1||constructorCount!=1)return NO;
    // Bind the resolved getter to its actual source constructor, without any
    // hard-coded callable address or reading embedded configuration data.
    NSUInteger offset=code.textOffset+(NSUInteger)(code.getter-code.text);BOOL callsConstructor=NO;
    for(NSUInteger i=0;i<80;i+=4){uint32_t word;memcpy(&word,bytes+offset+i,4);
        if((word&0xfc000000u)==0x94000000u){int64_t relative=(int64_t)(word&0x03ffffffu);
            if(relative&0x02000000)relative-=0x04000000;
            if((uint64_t)((int64_t)(code.getter+i)+relative*4)==code.constructor)callsConstructor=YES;}
    }
    if(!callsConstructor)return NO;*result=code;return YES;
}
static BOOL ODOriginImage(NSString *expected,const struct mach_header **header,intptr_t *slide){
    NSUInteger matches=0;
    for(uint32_t i=0;i<_dyld_image_count();++i){const char *name=_dyld_get_image_name(i);if(!name)continue;
        NSString *path=[[NSString stringWithUTF8String:name] stringByResolvingSymlinksInPath];
        if([path isEqual:expected]){*header=_dyld_get_image_header(i);*slide=_dyld_get_image_vmaddr_slide(i);++matches;}
    }
    return matches==1&&*header!=NULL;
}
static NSURL *ODOriginFromConfig(const void *config){
    uint64_t address=(uint64_t)(uintptr_t)config;if(address>UINT64_MAX-34)return nil;
    NSData *descriptor=ODOriginRead(address+8,24),*portData=ODOriginRead(address+32,2);
    if(!descriptor||!portData)return nil;
    const uint8_t *storage=descriptor.bytes;uint64_t count=storage[23],pointer=0;
    NSData *hostData=nil;
    if((int8_t)storage[23]<0){memcpy(&pointer,storage,8);memcpy(&count,storage+8,8);
        if(!count||count>4096)return nil;hostData=ODOriginRead(pointer,(NSUInteger)count);
    }else {if(!count||count>22)return nil;hostData=[descriptor subdataWithRange:NSMakeRange(0,(NSUInteger)count)];}
    if(!hostData||memchr(hostData.bytes,0,hostData.length))return nil;
    NSString *host=[[NSString alloc] initWithData:hostData encoding:NSUTF8StringEncoding];uint16_t port=0;
    memcpy(&port,portData.bytes,2);if(!host.length||!port)return nil;
    // Reject descriptor/port changes during the safe snapshot. This is a cold,
    // serialized read before requests, not a claim of concurrent string safety.
    if(![descriptor isEqual:ODOriginRead(address+8,24)]||![portData isEqual:ODOriginRead(address+32,2)])return nil;
    NSString *text=port==80?[NSString stringWithFormat:@"http://%@/",host]:
        [NSString stringWithFormat:@"%@://%@:%u/",port==443?@"https":@"http",host,(unsigned)port];
    NSURLComponents *parts=[NSURLComponents componentsWithString:text];
    NSInteger effectivePort=parts.port?parts.port.integerValue:([parts.scheme isEqual:@"https"]?443:80);
    if(!parts.host.length||parts.user||parts.password||parts.query||parts.fragment||![parts.path isEqual:@"/"]||
       ![parts.host isEqual:host]||effectivePort!=port)return nil;
    return parts.URL;
}

@interface ODOriginalNativeOrigin ()
- (instancetype)initPrivateWithPath:(NSString *)path header:(const struct mach_header *)header
    getter:(uint64_t)getter constructor:(uint64_t)constructor config:(const void *)config origin:(NSURL *)origin;
@end

@implementation ODOriginalNativeOrigin {
    NSString *_imagePath;
    const struct mach_header *_imageHeader;
    const void *_config;
    uint64_t _getterAddress,_constructorAddress;
}
- (instancetype)initPrivateWithPath:(NSString *)path header:(const struct mach_header *)header
        getter:(uint64_t)getter constructor:(uint64_t)constructor config:(const void *)config origin:(NSURL *)origin {
    if((self=[super init])){_imagePath=[path copy];_imageHeader=header;_getterAddress=getter;
        _constructorAddress=constructor;_config=config;_origin=[origin copy];}return self;
}
- (BOOL)isCurrentForLoadedOriginalImage {
    if(!NSThread.isMainThread||object_getClass(self)!=ODOriginalNativeOrigin.class)return NO;
    const struct mach_header *header=NULL;intptr_t slide=0;
    if(!ODOriginImage(_imagePath,&header,&slide)||header!=_imageHeader)return NO;
    NSData *getter=ODOriginRead(_getterAddress,80),*constructor=ODOriginRead(_constructorAddress,504);
    if(!getter||!constructor||![ODOriginHash(getter.bytes,getter.length) isEqual:ODGetterHash]||
       ![ODOriginHash(constructor.bytes,constructor.length) isEqual:ODConstructorHash])return NO;
    ODNativeConfigGetter call=(ODNativeConfigGetter)(uintptr_t)_getterAddress;const void *config=call();
    return config==_config&&[ODOriginFromConfig(config) isEqual:_origin];
}
@end

ODOriginalNativeOrigin *ODCreateOriginalNativeOriginForAdmittedImage(NSURL *url,NSData *file,NSError **error){
    if(!NSThread.isMainThread||!url.isFileURL){if(error)*error=ODOriginFailure();return nil;}
    ODOriginCode code={0};NSString *path=url.URLByResolvingSymlinksInPath.path;
    const struct mach_header *header=NULL;intptr_t slide=0;uint64_t getter=0,constructor=0,loadedBase=0;
    if(!ODOriginCodeFromVerifiedFile(file,&code)||!ODOriginImage(path,&header,&slide)||
       !ODOriginSlide(code.getter,slide,&getter)||!ODOriginSlide(code.constructor,slide,&constructor)||
       !ODOriginSlide(code.base,slide,&loadedBase)||loadedBase!=(uint64_t)(uintptr_t)header){
        if(error)*error=ODOriginFailure();return nil;
    }
    struct mach_header_64 loaded;NSData *readHeader=ODOriginRead((uint64_t)(uintptr_t)header,sizeof(loaded));
    if(!readHeader){if(error)*error=ODOriginFailure();return nil;}memcpy(&loaded,readHeader.bytes,sizeof(loaded));
    NSData *getterBytes=ODOriginRead(getter,80),*constructorBytes=ODOriginRead(constructor,504);Dl_info info={0};
    if(loaded.magic!=MH_MAGIC_64||loaded.cputype!=CPU_TYPE_ARM64||loaded.filetype!=MH_DYLIB||
       !getterBytes||!constructorBytes||![ODOriginHash(getterBytes.bytes,80) isEqual:ODGetterHash]||
       ![ODOriginHash(constructorBytes.bytes,504) isEqual:ODConstructorHash]||
       !dladdr((const void *)(uintptr_t)getter,&info)||info.dli_fbase!=(const void *)header){
        if(error)*error=ODOriginFailure();return nil;
    }
    ODNativeConfigGetter call=(ODNativeConfigGetter)(uintptr_t)getter;const void *config=call();
    NSURL *origin=ODOriginFromConfig(config);if(!origin){if(error)*error=ODOriginFailure();return nil;}
    ODOriginalNativeOrigin *capability=[[ODOriginalNativeOrigin alloc] initPrivateWithPath:path header:header
        getter:getter constructor:constructor config:config origin:origin];
    if(![capability isCurrentForLoadedOriginalImage]){if(error)*error=ODOriginFailure();return nil;}
    return capability;
}
