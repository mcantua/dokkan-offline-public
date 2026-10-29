#import "ODDuoEngineState.h"
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>
#include <dlfcn.h>
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach-o/loader.h>
#include <string.h>
#if __has_feature(ptrauth_calls)
#include <ptrauth.h>
#endif

/* All RVAs below were derived from the exact admitted 6.6.0/build26093018
   executable, not guessed hooks. No C++ function is called and nothing is
   written. Reject changed source callbacks, vtables, mappings or flag states. */
static BOOL ODReadable(uintptr_t pointer,size_t bytes) {
    if (!pointer || !bytes || bytes>UINTPTR_MAX-pointer) return NO;
    _Static_assert(sizeof(vm_address_t)==sizeof(uintptr_t),"Requires native arm64 VM addresses");
    vm_address_t address=pointer;
    vm_size_t size=0;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t count=VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t object=MACH_PORT_NULL;
    kern_return_t status=vm_region_64(mach_task_self(),&address,&size,
        VM_REGION_BASIC_INFO_64,(vm_region_info_t)&info,&count,&object);
    if (object!=MACH_PORT_NULL) mach_port_deallocate(mach_task_self(),object);
    return status==KERN_SUCCESS && count==VM_REGION_BASIC_INFO_COUNT_64 &&
        address<=pointer && size>=pointer-address && bytes<=size-(pointer-address) &&
        (info.protection&VM_PROT_READ);
}
static const struct mach_header_64 *ODImage(const void *implementation) {
    Dl_info info;
    if (!dladdr(implementation,&info) || !info.dli_fbase ||
        !ODReadable((uintptr_t)info.dli_fbase,sizeof(struct mach_header_64))) return NULL;
    const struct mach_header_64 *header=info.dli_fbase;
    if (header->magic!=MH_MAGIC_64 || header->cputype!=CPU_TYPE_ARM64 ||
        (header->filetype!=MH_DYLIB && header->filetype!=MH_EXECUTE) ||
        header->ncmds>8192 || header->sizeofcmds>4*1024*1024 ||
        !ODReadable((uintptr_t)header,sizeof(*header)+header->sizeofcmds)) return NULL;
    return header;
}
static BOOL ODImageSpan(const struct mach_header_64 *header,uintptr_t rva,size_t bytes) {
    const uint8_t *p=(const uint8_t *)(header+1),*end=p+header->sizeofcmds;
    uint64_t base=UINT64_MAX;
    for (uint32_t i=0;i<header->ncmds;++i) {
        if ((size_t)(end-p)<sizeof(struct load_command)) return NO;
        const struct load_command *command=(const void *)p;
        if (command->cmdsize<sizeof(*command) || command->cmdsize>(size_t)(end-p)) return NO;
        if (command->cmd==LC_SEGMENT_64 && command->cmdsize>=sizeof(struct segment_command_64)) {
            const struct segment_command_64 *segment=(const void *)p;
            if (!strncmp(segment->segname,"__TEXT",16) && !segment->fileoff && segment->filesize)
                base=segment->vmaddr;
        }
        p+=command->cmdsize;
    }
    if (base==UINT64_MAX || p!=end || rva>UINTPTR_MAX-(uintptr_t)header) return NO;
    p=(const uint8_t *)(header+1);
    for (uint32_t i=0;i<header->ncmds;++i) {
        const struct load_command *command=(const void *)p;
        if (command->cmd==LC_SEGMENT_64 && command->cmdsize>=sizeof(struct segment_command_64)) {
            const struct segment_command_64 *segment=(const void *)p;
            if (segment->vmaddr>=base) {
                uint64_t begin=segment->vmaddr-base;
                if (rva>=begin && rva-begin<=segment->vmsize &&
                    bytes<=segment->vmsize-(rva-begin))
                    return ODReadable((uintptr_t)header+rva,bytes);
            }
        }
        p+=command->cmdsize;
    }
    return NO;
}
static const void *ODImplementation(Method method) {
    IMP implementation=method_getImplementation(method);
#if __has_feature(ptrauth_calls)
    return ptrauth_strip(implementation,ptrauth_key_function_pointer);
#else
    return (const void *)implementation;
#endif
}
static BOOL ODBody(const struct mach_header_64 *image,Method method,uintptr_t rva,
                   const unsigned char expected[CC_SHA256_DIGEST_LENGTH]) {
    if (!method || !ODImageSpan(image,rva,28) ||
        ODImplementation(method)!=(const void *)((uintptr_t)image+rva)) return NO;
    unsigned char actual[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(ODImplementation(method),28,actual);
    return !memcmp(actual,expected,sizeof(actual));
}
BOOL ODDuoInspectPinnedEngine(id original,ODDuoEngineState *out) {
    static const unsigned char background[32]={
        0xbc,0x1e,0x89,0x98,0xf5,0x2a,0xb8,0x24,0x76,0xc0,0xfe,0xac,0xb1,0x5e,0x52,0x4d,
        0x43,0x22,0x77,0x19,0xde,0x6e,0x9b,0x6d,0xb6,0xff,0x7f,0xfe,0xbd,0x11,0xbd,0x5d};
    static const unsigned char foreground[32]={
        0x15,0x47,0xb8,0xe6,0xba,0xc7,0xf7,0x66,0xe9,0xd7,0x3f,0x63,0xb6,0x90,0x18,0xb6,
        0x97,0x0d,0x51,0xaa,0xd4,0x2e,0x4f,0x17,0x4b,0xb1,0xa7,0xba,0x6e,0xa1,0xcc,0xb9};
    if (!NSThread.isMainThread || !out || !original ||
        ![original isKindOfClass:NSClassFromString(@"AppController")]) return NO;
    Class cls=NSClassFromString(@"AppController");
    if (object_getClass(original)!=cls) return NO;
    Method bg=class_getInstanceMethod(cls,@selector(applicationDidEnterBackground:));
    Method fg=class_getInstanceMethod(cls,@selector(applicationWillEnterForeground:));
    if (!bg || !fg || strcmp(method_getTypeEncoding(bg),"v24@0:8@16") ||
        strcmp(method_getTypeEncoding(fg),"v24@0:8@16")) return NO;
    const struct mach_header_64 *image=ODImage(ODImplementation(bg));
    if (!image || !ODBody(image,bg,0x33447c,background) ||
        !ODBody(image,fg,0x334498,foreground) ||
        !ODImageSpan(image,0x307f0d8,8) || !ODImageSpan(image,0x31d21b8,8) ||
        !ODImageSpan(image,0x2f6a800,0x28) || !ODImageSpan(image,0x2f8a430,8)) return NO;
    uintptr_t base=(uintptr_t)image;
    uintptr_t application=*(const uintptr_t *)(base+0x307f0d8);
    uintptr_t director=*(const uintptr_t *)(base+0x31d21b8);
    if (!ODReadable(application,8) || !ODReadable(director,512) ||
        *(const uintptr_t *)application!=base+0x2f6a800 ||
        *(const uintptr_t *)director!=base+0x2f8a430 ||
        *(const uintptr_t *)(base+0x2f6a818)!=base+0x1aaad40 ||
        *(const uintptr_t *)(base+0x2f6a820)!=base+0x1aaadd0) return NO;
    unsigned paused=*(const unsigned char *)(director+0x160);
    unsigned stopped=*(const unsigned char *)(director+0x1f8);
    if (paused>1 || stopped>1) return NO;
    *out=(ODDuoEngineState){base,application,director,paused!=0,stopped!=0};
    return YES;
}
