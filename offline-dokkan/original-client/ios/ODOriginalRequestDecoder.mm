#import "ODOriginalRequestDecoder.h"
#import "../duo/ODDuoEngineState.h"
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <dlfcn.h>
#include <string>
#include <vector>
#include <algorithm>
#include <cstring>
#include <cstdint>

namespace {
using NativeString=std::string;
static_assert(sizeof(void*)==8 && sizeof(NativeString)==24,"Original arm64 native string ABI required");
#if !defined(_LIBCPP_ABI_VERSION) || _LIBCPP_ABI_VERSION != 1
#error The original std::__1 native string ABI is required
#endif
#if defined(_LIBCPP_ABI_ENABLE_STRING_TRIVIAL_ABI)
#error The original indirect native string return ABI is required
#endif
using ContextGetter=NativeString (*)(void);
using NativePair=NativeString (*)(NativeString const&,NativeString const&);
enum Function {ODEncoder,ODDecoder,ODResponseCaller,ODStartCaller,ODFunctionCount};
struct Pin {Function function;uint32_t bytes;const char*sha;};
static const Pin Pins[]={
    {ODEncoder,100,"3f00c3f3f7e2de05a9ee3faad6ba43b8f1f0900b08f6060fa36ee1b9fb2b0ade"},
    {ODDecoder,200,"07b37bdcda5d5b0f352ac98d75366ca0adf5ddc77878cd256ad147cc766643e1"},
    {ODResponseCaller,1276,"785d933d26d9474b66b0075a6fc10a2c1e06f343cd2ba528e01fc3940dd5627d"},
    {ODStartCaller,1596,"07e8bed5be4eda28c95689d36c1971a70e7ea58f07026243e55dbafef6696a42"},
};
static const NSUInteger MaxBody=1024u*1024u;
static NSError *Failure(NSString*reason){return[NSError errorWithDomain:@"OfflineDokkan.OriginalRequestCodec" code:1
    userInfo:@{NSLocalizedDescriptionKey:@"The original request could not be decoded. Existing game progress was preserved.",@"reason":reason}];}
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
struct Code { uint64_t base=0,text=0,size=0;uint32_t textOffset=0;uint64_t contextGetter=0;uint64_t entry[ODFunctionCount]={}; };
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
    unsigned counts[ODFunctionCount]={};bool terminated=false;std::vector<uint64_t> functionStarts;
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
        if(terminated)break;functionStarts.push_back(next);previous=next;current=next;
    }
    if(!terminated)return false;
    for(unsigned count:counts)if(count!=1)return false;
    // Pin the opaque getter through the actual signed-response callback BL.
    // No provider instruction body or referenced constant is read here.
    uint64_t pc=code.entry[ODResponseCaller]+0x144;
    size_t instructionOffset=code.textOffset+size_t(pc-code.text);uint32_t word=0;
    memcpy(&word,bytes+instructionOffset,sizeof(word));
    if((word&0xfc000000u)!=0x94000000u)return false;
    int64_t relative=word&0x03ffffffu;if(relative&0x02000000)relative-=0x04000000;
    code.contextGetter=uint64_t(int64_t(pc)+relative*4);
    if(std::find(functionStarts.begin(),functionStarts.end(),code.contextGetter)==functionStarts.end())return false;
    // Independently bind the outgoing start builder to that SAME getter.
    unsigned calls=0;
    for(size_t i=0;i<1596;i+=4){
        uint64_t at=code.entry[ODStartCaller]+i;
        memcpy(&word,bytes+code.textOffset+size_t(at-code.text),sizeof(word));
        if((word&0xfc000000u)==0x94000000u){
            relative=word&0x03ffffffu;if(relative&0x02000000)relative-=0x04000000;
            if(uint64_t(int64_t(at)+relative*4)==code.contextGetter)++calls;}
    }
    return calls==1;
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
// Check only our own harmless strings. The opaque context is never inspected.
static bool StringABI(){
    NativeString shortValue="od",longValue(40,'x');unsigned char shortBytes[24],longBytes[24];
    memcpy(shortBytes,&shortValue,24);memcpy(longBytes,&longValue,24);
    uintptr_t pointer=0;uint64_t length=0;memcpy(&pointer,longBytes,8);memcpy(&length,longBytes+8,8);
    return shortBytes[0]=='o'&&shortBytes[1]=='d'&&shortBytes[23]==2&&
        static_cast<int8_t>(longBytes[23])<0&&pointer==reinterpret_cast<uintptr_t>(longValue.data())&&length==40;
}
static NSData *CanonicalBase64(NSString *text){
    if(![text isKindOfClass:NSString.class]||!text.length||text.length>MaxBody||text.length%4)return nil;
    NSData *ascii=[text dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO];
    if(ascii.length!=text.length)return nil;
    const unsigned char *bytes=static_cast<const unsigned char*>(ascii.bytes);NSUInteger padding=0;
    for(NSUInteger i=0;i<ascii.length;++i){unsigned char c=bytes[i];
        if(c=='='){if(i<ascii.length-2||++padding>2)return nil;}
        else if(padding||!((c>='A'&&c<='Z')||(c>='a'&&c<='z')||(c>='0'&&c<='9')||c=='+'||c=='/'))return nil;
    }
    NSData *decoded=[[NSData alloc]initWithBase64EncodedString:text options:0];
    // Native stage2 unconditionally reads eight prefix bytes. Require at least
    // that prefix plus a nonempty payload; do not infer a cipher/block size.
    if(decoded.length<=8||decoded.length>MaxBody||![[decoded base64EncodedStringWithOptions:0]isEqual:text])return nil;
    return decoded;
}
static NSString *EnvelopeSign(NSData *body){
    if(![body isKindOfClass:NSData.class]||!body.length||body.length>MaxBody)return nil;
    NSString *text=[[NSString alloc]initWithData:body encoding:NSASCIIStringEncoding];if(!text)return nil;
    // The actual FastWriter emits sorted plain-ASCII keys, sign and optional
    // uint64 timewarp. This also rejects duplicate keys, unrelated data, JSON
    // escapes, fragments, noncanonical numbers and trailing tokens.
    static NSRegularExpression *pattern;static dispatch_once_t once;
    dispatch_once(&once,^{pattern=[NSRegularExpression regularExpressionWithPattern:
        @"\\A[ \\t\\r\\n]*\\{[ \\t\\r\\n]*\"sign\"[ \\t\\r\\n]*:[ \\t\\r\\n]*\"([A-Za-z0-9+/]*={0,2})\"[ \\t\\r\\n]*(?:,[ \\t\\r\\n]*\"timewarp\"[ \\t\\r\\n]*:[ \\t\\r\\n]*(0|[1-9][0-9]{0,19}))?[ \\t\\r\\n]*\\}[ \\t\\r\\n]*\\z"
        options:0 error:nil];});
    NSTextCheckingResult *match=[pattern firstMatchInString:text options:0 range:NSMakeRange(0,text.length)];
    if(!match||match.range.location!=0||match.range.length!=text.length)return nil;
    NSRange clock=[match rangeAtIndex:2];
    if(clock.location!=NSNotFound){NSString *number=[text substringWithRange:clock];
        if(number.length==20&&[number compare:@"18446744073709551615" options:NSLiteralSearch]==NSOrderedDescending)return nil;}
    NSString *sign=[text substringWithRange:[match rangeAtIndex:1]];
    return CanonicalBase64(sign)?sign:nil;
}
}

@interface ODOriginalRequestDecoder ()
- (instancetype)initPrivateWithPath:(NSString*)path image:(const mach_header*)image
    entries:(const uintptr_t*)entries getter:(uintptr_t)getter;
- (BOOL)currentImage;
@end
@implementation ODOriginalRequestDecoder {
    NSString *_imagePath,*_state;const mach_header *_image;
    uintptr_t _entries[ODFunctionCount],_getter;__weak id _original;
    BOOL _verified,_selfCheckAttempted;
}
- (instancetype)initPrivateWithPath:(NSString*)path image:(const mach_header*)image
        entries:(const uintptr_t*)entries getter:(uintptr_t)getter {
    if((self=[super init])){_imagePath=[path copy];_image=image;_getter=getter;
        memcpy(_entries,entries,sizeof(_entries));_state=@"ORIGINAL_REQUEST_CODEC_NATIVE_SELF_CHECK_REQUIRED";}return self;
}
- (BOOL)currentImage {
    const mach_header *image=nullptr;intptr_t slide=0;Dl_info info={};
    return NSThread.isMainThread&&object_getClass(self)==ODOriginalRequestDecoder.class&&
        Loaded(_imagePath,image,slide)&&image==_image&&ReadonlyPins(_entries)&&
        dladdr(reinterpret_cast<const void*>(_getter),&info)&&info.dli_fbase==_image;
}
- (BOOL)verifiedForCurrentEngine {
    ODDuoEngineState state={};
    return _verified&&[self currentImage]&&ODDuoInspectPinnedEngine(_original,&state)&&
        state.image==(uintptr_t)_image&&!state.paused&&!state.stopped;
}
- (NSString*)state {
    if(_verified&&![self verifiedForCurrentEngine])return @"ORIGINAL_REQUEST_CODEC_ENGINE_NOT_CURRENT";
    return _state;
}
- (BOOL)verifyWithOwnJSONForAppController:(id)original error:(NSError**)error {
    if(self.verifiedForCurrentEngine)return YES;
    if(_selfCheckAttempted&&!_verified){if(error)*error=Failure(_state);return NO;}
    ODDuoEngineState state={};uintptr_t scene=0,pending=0,table=0;Dl_info sceneType={};
    if(![self currentImage]||!ODDuoInspectPinnedEngine(original,&state)||state.image!=(uintptr_t)_image||
       state.paused||state.stopped||!Pointer(state.director+0x170,scene)||!scene||
       !Pointer(state.director+0x178,pending)||pending||!Pointer(scene,table)||!Read(table,8)||
       !dladdr(reinterpret_cast<const void*>(table),&sceneType)||sceneType.dli_fbase!=_image){
        if(error)*error=Failure(@"ORIGINAL_REQUEST_CODEC_WAITING_FOR_NATIVE_ENGINE");return NO;}
    // No Home dependency exists in the original codec callsites. This proves
    // an initialized active original scene and no pending scene, not that a
    // running Cocos transition has finished. No scene hook/poller is invented.
    _verified=NO;_selfCheckAttempted=YES;
    try {
        if(!StringABI()){_state=@"ORIGINAL_REQUEST_CODEC_STRING_ABI_REJECTED";if(error)*error=Failure(_state);return NO;}
        const NativeString probe="{\"offline_dokkan_codec_probe\":1}\n";
        // Hidden X8 owned-return storage is established by two independent
        // pinned original callsites, both with no explicit argument setup.
        // Pass this opaque native object DIRECTLY to unchanged native routines.
        NativeString opaque=reinterpret_cast<ContextGetter>(_getter)();
        NativeString encoded=reinterpret_cast<NativePair>(_entries[ODEncoder])(probe,opaque);
        if(encoded.empty()||encoded.size()>MaxBody){_state=@"ORIGINAL_REQUEST_CODEC_NATIVE_SELF_CHECK_FAILED";
            if(error)*error=Failure(_state);return NO;}
        NSString *sign=[[NSString alloc]initWithBytes:encoded.data() length:encoded.size() encoding:NSASCIIStringEncoding];
        if(!CanonicalBase64(sign)){_state=@"ORIGINAL_REQUEST_CODEC_NATIVE_SELF_CHECK_FAILED";
            if(error)*error=Failure(_state);return NO;}
        NativeString decoded=reinterpret_cast<NativePair>(_entries[ODDecoder])(encoded,opaque);
        if(decoded!=probe){_state=@"ORIGINAL_REQUEST_CODEC_NATIVE_SELF_CHECK_FAILED";
            if(error)*error=Failure(_state);return NO;}
        // Opaque context is destroyed normally here; no context/key survives in
        // this capability. Subsequent requests obtain current native context.
    }catch(...){_state=@"ORIGINAL_REQUEST_CODEC_NATIVE_SELF_CHECK_FAILED";
        if(error)*error=Failure(_state);return NO;}
    _original=original;_verified=YES;_state=@"ORIGINAL_REQUEST_CODEC_READY_FOR_CURRENT_ENGINE";return YES;
}
- (NSDictionary*)decodeOriginalPOSTBody:(NSData*)body error:(NSError**)error {
    if(!self.verifiedForCurrentEngine){if(error)*error=Failure(self.state);return nil;}
    NSString *sign=EnvelopeSign(body);
    if(!sign){if(error)*error=Failure(@"ORIGINAL_REQUEST_CODEC_ENVELOPE_INVALID");return nil;}
    try {
        NSData *ascii=[sign dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO];
        NativeString input(static_cast<const char*>(ascii.bytes),ascii.length);
        NativeString opaque=reinterpret_cast<ContextGetter>(_getter)();
        NativeString decoded=reinterpret_cast<NativePair>(_entries[ODDecoder])(input,opaque);
        if(decoded.empty()||decoded.size()>MaxBody){if(error)*error=Failure(@"ORIGINAL_REQUEST_CODEC_DECODE_FAILED");return nil;}
        NSData *plain=[NSData dataWithBytes:decoded.data() length:decoded.size()];
        id root=[NSJSONSerialization JSONObjectWithData:plain options:0 error:nil];
        if(![root isKindOfClass:NSDictionary.class]){if(error)*error=Failure(@"ORIGINAL_REQUEST_CODEC_DECODED_ROOT_INVALID");return nil;}
        // No plaintext or opaque context is logged, persisted or put in an
        // error/report. Only the already-validated route owner receives this.
        return root;
    }catch(...){_verified=NO;_state=@"ORIGINAL_REQUEST_CODEC_NATIVE_SELF_CHECK_REQUIRED";
        if(error)*error=Failure(@"ORIGINAL_REQUEST_CODEC_DECODE_FAILED");return nil;}
}
@end

ODOriginalRequestDecoder *ODCreateOriginalRequestDecoderForAdmittedImage(NSURL *url,NSData *file,NSError **error){
    if(!NSThread.isMainThread||!url.isFileURL){if(error)*error=Failure(@"ORIGINAL_REQUEST_CODEC_IDENTITY_UNAVAILABLE");return nil;}
    Code code;const mach_header *image=nullptr;intptr_t slide=0;uintptr_t base=0,getter=0,entries[ODFunctionCount]={};
    NSString *path=url.URLByResolvingSymlinksInPath.path;
    if(!Resolve(file,code)||!Loaded(path,image,slide)||!Slide(code.base,slide,base)||base!=(uintptr_t)image||
       !Slide(code.contextGetter,slide,getter)){if(error)*error=Failure(@"ORIGINAL_REQUEST_CODEC_IDENTITY_UNAVAILABLE");return nil;}
    for(unsigned i=0;i<ODFunctionCount;++i)if(!Slide(code.entry[i],slide,entries[i])){
        if(error)*error=Failure(@"ORIGINAL_REQUEST_CODEC_IDENTITY_UNAVAILABLE");return nil;}
    if(!ReadonlyPins(entries)){if(error)*error=Failure(@"ORIGINAL_REQUEST_CODEC_IDENTITY_UNAVAILABLE");return nil;}
    return [[ODOriginalRequestDecoder alloc]initPrivateWithPath:path image:image entries:entries getter:getter];
}
