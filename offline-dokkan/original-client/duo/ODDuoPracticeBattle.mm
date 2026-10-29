#import "ODDuoPracticeBattle.h"
#import "ODDuoEngineState.h"
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <dlfcn.h>
#include <functional>
#include <memory>
#include <initializer_list>
#include <new>
#include <cstring>
#include <cstdint>

namespace cocos2d { class Node; }
namespace {
using Finish = std::function<void(cocos2d::Node *)>;
// The pointee stays opaque; destruction uses the returned native control block,
// never a new deleter or a reconstructed UserCard object.
using OwnedCard = std::shared_ptr<void>;
static_assert(sizeof(OwnedCard)==16 && alignof(OwnedCard)==8,"Native shared ownership ABI required");
#if !defined(_LIBCPP_ABI_VERSION) || _LIBCPP_ABI_VERSION != 1
#error The original std::__1 Apple libc++ ownership ABI is required
#endif
#if defined(_LIBCPP_ABI_ENABLE_SHARED_PTR_TRIVIAL_ABI) || defined(_LIBCPP_ABI_OPTIMIZED_FUNCTION)
#error The original indirect shared_ptr return and virtual function-copy ABI are required
#endif
static_assert(sizeof(void *)==8,"Original practice requires arm64");
static_assert(sizeof(Finish)==32,"The original Apple libc++ callback ABI is required");
// Original callsites use a40-byte Json::Value and192-byte Json::Reader. These
// buffers are opaque; all construction, parsing and destruction use the engine.
struct alignas(16) NativeValue { unsigned char bytes[40]; };
struct alignas(16) NativeReader { unsigned char bytes[192]; };
enum Function { ODReaderConstruct, ODParseRange, ODValueConstruct, ODValueDestroy,
    ODReaderErrorsDestroy, ODReaderNodesDestroy, ODConfigureBattle, ODBattleScene,
    ODFinishCallback, ODReplaceScene, ODHomeScene, ODHomeConstruct, ODAudioOwner,
    ODAudioStop, ODOwnedModelAccessor, ODOwnedCardLookup,
    ODOwnedCardLookupBody, ODFunctionCount };
struct Pin { Function function; uint32_t bytes; const char *sha; };
static const Pin Pins[] = {
    {ODReaderConstruct, 48, "6b1fa73f45040cabe9bce4d4f5c436084eaeaa4824238f2704d1541941fbbbbd"},
    {ODParseRange, 704, "e39b7e57ca0e31248c37a09bf3c3a8f33d25ad7ac7c133f685bcf38b5a5dabb0"},
    {ODValueConstruct, 248, "15f0ef2ee10319485a4ad2e9c018d80662145a9230ac99c0daa53bc1c101101d"},
    {ODValueDestroy, 64, "970e0945e2513d8ac7ba9838443451fac57560f506d1968f751b8769aece3c47"},
    {ODReaderErrorsDestroy, 336, "fded41f2bc864f55a786522284d7dbad3940a3f4c8f0f0d3238cc7963c208f63"},
    {ODReaderNodesDestroy, 152, "ee23d47a2c1946ec918a46abef75ed03a815c859e016459feb0a7776d967f5ee"},
    {ODConfigureBattle, 1840, "5f7dc8291c2d70b15aa0e2da956aafa47c750f1d0176d5b512b3d449d09b7cb2"},
    {ODBattleScene, 144, "d93ab602c2a6fdf106a85eb72b5da0a292e84387ce9e610e5c731bed282a5cf1"},
    {ODFinishCallback, 8, "46ca8a34d292d76981a515bd6a9ef337c1d99651b47921f1a95400937c377074"},
    {ODReplaceScene, 48, "3f04d659ee30c5e394ad6b04d47e764dae34a42a63e746c254291ae3dc37056f"},
    {ODHomeScene, 160, "03a51e1fb7ef83553158cafab49ba1f7f749a7bd873dd9d9614101d37c9e746d"},
    {ODHomeConstruct, 232, "75fc92e08ed61d1a59240153309d6573264bfb0584fc1c80dc1a175357510031"},
    {ODAudioOwner, 80, "b76c2260cc846fa3efb6ecb1f18af99bc9efa8da8da3c3b8bb74f517aa511a70"},
    {ODAudioStop, 20, "4f7b256bbf522b31f4fcfbd160498c4882630130fa1d29c87c1b2b1e0302d7cb"},
    {ODOwnedModelAccessor, 112, "80d26d5832b2f1a08fad5854bb745c87b0652247b14629952d6d9133bda2f6c1"},
    {ODOwnedCardLookup, 8, "ac7ecc2a6e252a8c7b91e3254f38dd6da7f30a2c4259bdc96b2c78cc39924a6b"},
    {ODOwnedCardLookupBody, 96, "38aad106783a5341f017d38ba6dbd4deeb90687e6aebbdb5abafa6d176834528"},
};
using VoidObject = void (*)(void *);
using ConstructValue = void (*)(void *,uint32_t);
using ParseRange = bool (*)(void *,const char *,const char *,void *,bool);
using ConfigureBattle = void (*)(void *,const void *);
using SceneFactory = void *(*)(void);
using HomeFactory = void *(*)(uint32_t);
using SetFinish = void (*)(void *,const Finish &);
using ReplaceScene = void (*)(void *,void *);
using AudioOwner = void *(*)(void);
using OwnedContainer = void *(*)(void *);
// Original caller supplies a16-byte nontrivial result in X8, container inX0,
// signed64 ID inX1. Apple libc++ shared_ptr emits that exact indirect-return ABI.
using OwnedLookup = OwnedCard (*)(void *,int64_t);

static NSError *Failure(NSInteger code) {
    return [NSError errorWithDomain:@"OfflineDokkan.OriginalPractice" code:code
        userInfo:@{NSLocalizedDescriptionKey:@"The original practice battle is unavailable. Existing game progress was preserved."}];
}
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
class ParsedParameters {
    uintptr_t const *entries_;
    NativeValue value_{};NativeReader reader_{};bool valueLive_=false,readerLive_=false;
public:
    explicit ParsedParameters(uintptr_t const *entries):entries_(entries){}
    ~ParsedParameters(){
        if(readerLive_){
            // Exact original HTTP-completion normal/exception cleanup order.
            for(size_t offset:{size_t(0xa0),size_t(0x60)}){
                if(static_cast<int8_t>(reader_.bytes[offset+23])<0){void *pointer=nullptr;
                    memcpy(&pointer,reader_.bytes+offset,sizeof(pointer));::operator delete(pointer);}}
            reinterpret_cast<VoidObject>(entries_[ODReaderErrorsDestroy])(reader_.bytes+0x30);
            reinterpret_cast<VoidObject>(entries_[ODReaderNodesDestroy])(reader_.bytes);
        }
        if(valueLive_)reinterpret_cast<VoidObject>(entries_[ODValueDestroy])(value_.bytes);
    }
    bool parse(NSData *input){
        reinterpret_cast<ConstructValue>(entries_[ODValueConstruct])(value_.bytes,0);valueLive_=true;
        reinterpret_cast<VoidObject>(entries_[ODReaderConstruct])(reader_.bytes);readerLive_=true;
        const char *begin=static_cast<const char *>(input.bytes);
        return reinterpret_cast<ParseRange>(entries_[ODParseRange])(reader_.bytes,begin,begin+input.length,value_.bytes,false);
    }
    const void *value()const{return value_.bytes;}
};
// Match the source's actual lookup before permitting its fallback. A Core
// projection alone does not prove absence in the already-live native cache.
static bool OwnedLookupsMiss(uintptr_t image,const uintptr_t *entries,NSData *parameters) {
    uintptr_t owner=0,table=0,getter=0;
    // The original112-byte accessor's existing singleton and exact vtable.
    // Do not run its lazy constructor or create a second model/cache.
    if(!Pointer(image+0x310fba8,owner)||!owner||!Pointer(owner,table)||
       table!=image+0x2d285a0||!Pointer(table+0x68,getter))return false;
    // This8-byte getter can have identical compiler clones. Bind it through
    // this actual class vtable slot, then verify its body instead of guessing
    // a unique address from a repeated short hash.
    NSData *getterBody=Read(getter,8);
    if(!getterBody||!Hash(getterBody.bytes,8,"f637e07b3820a82a5634a0174c92391b8ec5194fafa5b124fa3a73d3007ae512"))return false;
    void *container=reinterpret_cast<OwnedContainer>(getter)(reinterpret_cast<void *>(owner));
    if(!container||!Read(reinterpret_cast<uintptr_t>(container),0x98))return false;
    id root=[NSJSONSerialization JSONObjectWithData:parameters options:0 error:nil];
    if(![root isKindOfClass:NSDictionary.class]||![root[@"card_ids"] isKindOfClass:NSArray.class]||
       ![root[@"dummy_card_id"] isKindOfClass:NSNumber.class])return false;
    NSMutableArray *ids=[root[@"card_ids"] mutableCopy];[ids addObject:root[@"dummy_card_id"]];
    if(ids.count!=3)return false;
    for(id candidate in ids){
        if(![candidate isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)candidate)==CFBooleanGetTypeID())return false;
        int64_t cardID=[candidate longLongValue];
        if(cardID<=0||![candidate isEqualToNumber:@(cardID)])return false;
        OwnedCard existing=reinterpret_cast<OwnedLookup>(entries[ODOwnedCardLookup])(container,cardID);
        // Returning releases only the lookup's added reference through the
        // actual native shared_weak_count virtual contract. No guessed deleter.
        if(existing.get()!=nullptr)return false;
    }
    return true;
}
// All state below belongs to the live original engine, never to Core ownership.
// GOT references and object fields come from the reviewed source-version callsites.
static bool ClearVolatileSingleton(uintptr_t image,uintptr_t gotRVA) {
    uintptr_t storage=0,object=0,table=0,destructor=0;
    if(!Pointer(image+gotRVA,storage)||!Pointer(storage,object))return false;
    if(!object)return true;
    if(!Pointer(object,table)||!Pointer(table+8,destructor)||!Read(destructor,4))return false;
    Dl_info info={};if(!dladdr(reinterpret_cast<const void *>(destructor),&info)||info.dli_fbase!=(const void *)image)return false;
    // Only the native singleton pointer is cleared. No original checkpoint file
    // or persistent save is removed, and no tutorial completion event is emitted.
    reinterpret_cast<VoidObject>(destructor)(reinterpret_cast<void *>(object));
    uintptr_t zero=0;memcpy(reinterpret_cast<void *>(storage),&zero,sizeof(zero));return true;
}
}

@interface ODDuoOriginalPracticeBattle ()
- (instancetype)initPrivateWithPath:(NSString *)path image:(const mach_header *)image entries:(const uintptr_t *)entries;
- (void)finishedOriginalBattle;
- (void)receiveNativeFinishForScene:(uintptr_t)scene generation:(NSUInteger)generation;
- (BOOL)beginOriginalPractice:(id)original parameters:(NSData *)parameters finishSaver:(nullable ODDuoPracticeNativeFinishSaver)saver error:(NSError **)error;
- (void)persistNativeFinishWithCompletion:(void (^)(NSError * _Nullable error))completion;
- (nullable NSError *)returnOriginalPracticeToHome;
- (BOOL)current;
@end
@implementation ODDuoOriginalPracticeBattle {
    NSString *_imagePath;const mach_header *_image;uintptr_t _entries[ODFunctionCount];
    __weak id _original;uintptr_t _battleScene;BOOL _running,_finishing;
    ODDuoPracticeNativeFinishSaver _finishSaver;BOOL _finishObserved,_savingFinish,_finishSaved,_returnFailed;
    NSUInteger _practiceGeneration;
}
- (instancetype)initPrivateWithPath:(NSString *)path image:(const mach_header *)image entries:(const uintptr_t *)entries {
    if((self=[super init])){_imagePath=[path copy];_image=image;memcpy(_entries,entries,sizeof(_entries));}return self;
}
- (BOOL)isRunning{return _running;}
- (BOOL)finishPersistenceRetryAvailable {return NSThread.isMainThread&&_running&&_finishing&&_finishObserved&&!_savingFinish&&_returnFailed;}
- (void)emit:(NSString *)outcome {
    if(self.report)self.report(@{@"entry":@"original-fixed-loadout-practice",@"outcome":outcome,
        @"running":@(_running),@"ordinaryQuest":@NO,@"rewardsGranted":@NO,
        @"ownedTeamsChanged":@NO,@"runtimeCombatVerified":@NO,
        @"nativeFinishObserved":@(_finishObserved),@"finishPersistenceConfigured":@(_finishSaver!=nil),
        @"finishPersistencePending":@(_savingFinish),@"nativeFinishSaved":@(_finishSaved),
        @"finishRetryAvailable":@(self.finishPersistenceRetryAvailable)});
}
- (BOOL)current {
    const mach_header *image=nullptr;intptr_t slide=0;
    return NSThread.isMainThread&&object_getClass(self)==ODDuoOriginalPracticeBattle.class&&
        Loaded(_imagePath,image,slide)&&image==_image&&ReadonlyPins(_entries);
}
- (BOOL)beginWithAppController:(id)original parametersJSON:(NSData *)parameters error:(NSError **)error {
    return [self beginOriginalPractice:original parameters:parameters finishSaver:nil error:error];
}
- (BOOL)beginWithAppController:(id)original parametersJSON:(NSData *)parameters
        finishSaver:(ODDuoPracticeNativeFinishSaver)saver error:(NSError **)error {
    if(!saver){if(error)*error=Failure(7);return NO;}
    return [self beginOriginalPractice:original parameters:parameters finishSaver:saver error:error];
}
- (BOOL)beginOriginalPractice:(id)original parameters:(NSData *)parameters
        finishSaver:(ODDuoPracticeNativeFinishSaver)saver error:(NSError **)error {
    ODDuoEngineState state={};uintptr_t scene=0,pending=0,table=0;
    if(_running||![self current]||![parameters isKindOfClass:NSData.class]||!parameters.length||parameters.length>65536||
       !ODDuoInspectPinnedEngine(original,&state)||state.image!=(uintptr_t)_image||state.paused||state.stopped||
       !Pointer(state.director+0x170,scene)||!Pointer(state.director+0x178,pending)||!scene||pending||
       !Pointer(scene,table)||table!=state.image+0x2dc71e0){
        if(error)*error=Failure(1);return NO;
    }
    try {
        if(!OwnedLookupsMiss(state.image,_entries,parameters)){
            if(error)*error=Failure(6);[self emit:@"native-fixed-loadout-lookup-not-admitted"];return NO;}
        ParsedParameters parsed(_entries);
        if(!parsed.parse(parameters)){if(error)*error=Failure(2);return NO;}
        // This native method's own body never reads its scene receiver. Its X1
        // is the owned Json::Value; it copies all phase data into InGameData.
        reinterpret_cast<ConfigureBattle>(_entries[ODConfigureBattle])(nullptr,parsed.value());
        void *battle=reinterpret_cast<SceneFactory>(_entries[ODBattleScene])();uintptr_t layer=0;
        if(!battle||!Pointer(reinterpret_cast<uintptr_t>(battle)+0x2d8,layer)||!layer){
            if(error)*error=Failure(3);[self emit:@"original-scene-creation-failed"];return NO;}
        ODDuoOriginalPracticeBattle *owner=self;
        NSUInteger generation=_practiceGeneration+1;uintptr_t sourceScene=reinterpret_cast<uintptr_t>(battle);
        Finish completion=[owner,generation,sourceScene](cocos2d::Node *){
            // Finish is delivered by the original engine. Defer replacement
            // until its callback stack unwinds; never invoke tutorial's event.
            dispatch_async(dispatch_get_main_queue(),^{[owner receiveNativeFinishForScene:sourceScene generation:generation];});
        };
        reinterpret_cast<SetFinish>(_entries[ODFinishCallback])(reinterpret_cast<void *>(layer),completion);
        _original=original;_battleScene=reinterpret_cast<uintptr_t>(battle);_running=YES;_finishing=NO;
        _finishSaver=[saver copy];_finishObserved=NO;_savingFinish=NO;_finishSaved=NO;_returnFailed=NO;_practiceGeneration=generation;
        reinterpret_cast<ReplaceScene>(_entries[ODReplaceScene])(reinterpret_cast<void *>(state.director),battle);
        [self emit:@"original-practice-scene-requested"];return YES;
    }catch(...){if(error)*error=Failure(4);[self emit:@"native-practice-entry-failed"];return NO;}
}
- (void)receiveNativeFinishForScene:(uintptr_t)scene generation:(NSUInteger)generation {
    // A late callback retained by an older native layer cannot settle a newer
    // session. This event records only the actual bound callback, not a win.
    if(!NSThread.isMainThread||!_running||scene!=_battleScene||generation!=_practiceGeneration||![self current])return;
    [self finishedOriginalBattle];
}
- (void)finishedOriginalBattle {
    if(!_running||_finishing)return;
    _finishing=YES;_finishObserved=YES;
    [self persistNativeFinishWithCompletion:^(NSError *failure){(void)failure;}];
}
- (void)retryNativeFinishPersistenceWithCompletion:(void (^)(NSError *))completion {
    if(!completion)return;
    if(!NSThread.isMainThread||!self.finishPersistenceRetryAvailable){completion(Failure(8));return;}
    [self persistNativeFinishWithCompletion:completion];
}
- (void)persistNativeFinishWithCompletion:(void (^)(NSError *))completion {
    if(!_running||!_finishing||!_finishObserved||_savingFinish){completion(Failure(8));return;}
    if(!_finishSaver||_finishSaved){
        NSError *failure=[self returnOriginalPracticeToHome];_returnFailed=failure!=nil;
        if(failure)[self emit:@"native-practice-return-retry-available"];completion(failure);return;
    }
    _savingFinish=YES;_returnFailed=NO;NSUInteger generation=_practiceGeneration;
    [self emit:@"native-practice-finish-persistence-requested"];
    _finishSaver(^(NSError *failure){
        dispatch_async(dispatch_get_main_queue(),^{
            if(generation!=self->_practiceGeneration||!self->_running||!self->_finishing||!self->_savingFinish){completion(Failure(8));return;}
            self->_savingFinish=NO;
            if(failure){self->_returnFailed=YES;[self emit:@"native-practice-finish-save-failed-retry-available"];completion(failure);return;}
            self->_finishSaved=YES;
            NSError *returnFailure=[self returnOriginalPracticeToHome];self->_returnFailed=returnFailure!=nil;
            if(returnFailure)[self emit:@"native-practice-return-retry-available"];completion(returnFailure);
        });
    });
}
- (NSError *)returnOriginalPracticeToHome {
    ODDuoEngineState state={};uintptr_t scene=0,pending=0;
    if(![self current]||!ODDuoInspectPinnedEngine(_original,&state)||state.image!=(uintptr_t)_image||
       state.paused||state.stopped||!Pointer(state.director+0x170,scene)||scene!=_battleScene||
       !Pointer(state.director+0x178,pending)||pending){[self emit:@"practice-return-unavailable"];return Failure(9);}
    try {
        // The original callback destroys these same volatile managers. Its
        // checkpoint unlink and FINISHED_BATTLE tutorial event are omitted.
        if(!ClearVolatileSingleton(state.image,0x2a2bf98)||!ClearVolatileSingleton(state.image,0x2a2bf48)){
            [self emit:@"practice-cleanup-unavailable"];return Failure(10);}
        void *audio=reinterpret_cast<AudioOwner>(_entries[ODAudioOwner])();
        reinterpret_cast<VoidObject>(_entries[ODAudioStop])(audio);
        void *home=reinterpret_cast<HomeFactory>(_entries[ODHomeScene])(0);
        if(!home){[self emit:@"original-home-unavailable"];return Failure(11);}
        reinterpret_cast<ReplaceScene>(_entries[ODReplaceScene])(reinterpret_cast<void *>(state.director),home);
        _battleScene=0;_running=NO;_finishing=NO;_original=nil;_returnFailed=NO;
        [self emit:@"original-practice-finish-callback-returned-to-home-request"];
        _finishSaver=nil;return nil;
    }catch(...){[self emit:@"native-practice-return-failed"];return Failure(12);}
}
@end

ODDuoOriginalPracticeBattle *ODCreateOriginalPracticeBattleForAdmittedImage(NSURL *url,NSData *file,NSError **error) {
    if(!NSThread.isMainThread||!url.isFileURL){if(error)*error=Failure(5);return nil;}
    Code code;const mach_header *image=nullptr;intptr_t slide=0;uintptr_t base=0,entries[ODFunctionCount]={};
    NSString *path=url.URLByResolvingSymlinksInPath.path;
    if(!Resolve(file,code)||!Loaded(path,image,slide)||!Slide(code.base,slide,base)||base!=(uintptr_t)image){
        if(error)*error=Failure(5);return nil;}
    for(unsigned i=0;i<ODFunctionCount;++i)if(!Slide(code.entry[i],slide,entries[i])){if(error)*error=Failure(5);return nil;}
    if(!ReadonlyPins(entries)){if(error)*error=Failure(5);return nil;}
    return [[ODDuoOriginalPracticeBattle alloc] initPrivateWithPath:path image:image entries:entries];
}
