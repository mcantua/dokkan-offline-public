#import "ODPreparedEngineLoader.h"
#import "../ios/ODOriginalNativeOrigin.h"
#import "../ios/ODGameHTTPABI.h"
#import <CommonCrypto/CommonDigest.h>
#include <mach-o/loader.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>

static const NSUInteger ODPreparedBytes=55697728;
static const NSUInteger ODOriginalCommandBytes=11224;
static void *ODResidentEngine;
static BOOL ODEngineLoadAttempted;
static BOOL ODLoaderFail(NSError **error,NSString *code) {
    if(error)*error=[NSError errorWithDomain:@"OfflineDokkanEngineLoader" code:1 userInfo:@{NSLocalizedDescriptionKey:code}];
    return NO;
}
static NSString *ODLoaderHash(NSData *data) {
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];CC_SHA256(data.bytes,(CC_LONG)data.length,hash);
    NSMutableString *value=[NSMutableString string];for(NSUInteger i=0;i<sizeof(hash);i++)[value appendFormat:@"%02x",hash[i]];return value;
}
static BOOL ODEngineCandidate(NSData *file) {
    if(file.length<ODPreparedBytes||file.length>128*1024*1024)return NO;
    const uint8_t *bytes=file.bytes;struct mach_header_64 header;memcpy(&header,bytes,sizeof(header));
    if(header.magic!=MH_MAGIC_64||header.cputype!=CPU_TYPE_ARM64||header.filetype!=MH_DYLIB||
       header.ncmds>1024||header.sizeofcmds>ODOriginalCommandBytes||header.flags&MH_PIE)return NO;
    NSMutableData *normalized=[NSMutableData dataWithBytes:bytes length:ODPreparedBytes];
    NSMutableData *commands=[NSMutableData data];NSUInteger offset=sizeof(header),count=0;BOOL signature=NO,linkedit=NO;
    for(uint32_t i=0;i<header.ncmds;i++) {
        if(offset+sizeof(struct load_command)>sizeof(header)+header.sizeofcmds)return NO;
        struct load_command command;memcpy(&command,bytes+offset,sizeof(command));
        if(command.cmdsize<8||command.cmdsize%8||offset+command.cmdsize>sizeof(header)+header.sizeofcmds)return NO;
        if(command.cmd==LC_CODE_SIGNATURE) {
            if(signature||command.cmdsize!=sizeof(struct linkedit_data_command))return NO;
            struct linkedit_data_command value;memcpy(&value,bytes+offset,sizeof(value));
            if(value.dataoff<ODPreparedBytes||(uint64_t)value.dataoff+value.datasize>file.length)return NO;
            signature=YES;
        } else {
            NSMutableData *copy=[NSMutableData dataWithBytes:bytes+offset length:command.cmdsize];
            if(command.cmd==LC_SEGMENT_64) {
                if(command.cmdsize<sizeof(struct segment_command_64))return NO;
                struct segment_command_64 *segment=copy.mutableBytes;
                if(command.cmdsize!=sizeof(*segment)+(uint64_t)segment->nsects*sizeof(struct section_64))return NO;
                if(!strncmp(segment->segname,"__LINKEDIT",16)) {
                    if(linkedit||segment->fileoff!=50839552)return NO;
                    // Only code-signing growth is normalized. All code, imports,
                    // fixups, other commands and the original byte prefix remain pinned.
                    segment->vmsize=4866048;segment->filesize=4858176;linkedit=YES;
                }
            }
            [commands appendData:copy];count++;
        }
        offset+=command.cmdsize;
    }
    if(!linkedit||offset!=sizeof(header)+header.sizeofcmds||commands.length>ODOriginalCommandBytes)return NO;
    header.ncmds=(uint32_t)count;header.sizeofcmds=(uint32_t)commands.length;
    [normalized replaceBytesInRange:NSMakeRange(0,sizeof(header)) withBytes:&header];
    memset((uint8_t *)normalized.mutableBytes+sizeof(header),0,ODOriginalCommandBytes);
    [normalized replaceBytesInRange:NSMakeRange(sizeof(header),commands.length) withBytes:commands.bytes];
    return [ODLoaderHash(normalized) isEqualToString:@"efaabfc9b3cdb0e2eeb550b6ea616f5eeb565c6584ad838b765f34539648d222"];
}
static BOOL ODLoadPreparedEngine(NSURL *url,ODPreparedEngineEnvironment configure,
        ODOriginalNativeOrigin **nativeOrigin,NSError **error) {
    if(nativeOrigin)*nativeOrigin=nil;
    if(!NSThread.isMainThread||!url.isFileURL||!configure)return ODLoaderFail(error,@"INVALID_ENGINE_LOAD_CONTEXT");
    NSURL *expected=[NSBundle.mainBundle.privateFrameworksURL URLByAppendingPathComponent:@"OriginalDokkanEngine.dylib"];
    if(!expected||![url.URLByResolvingSymlinksInPath.path isEqualToString:expected.URLByResolvingSymlinksInPath.path]||
        ![url.URLByStandardizingPath.path isEqualToString:expected.URLByStandardizingPath.path])
        return ODLoaderFail(error,@"PREPARED_ENGINE_NOT_IN_SIGNED_APP");
    if(ODEngineLoadAttempted)return ODLoaderFail(error,@"ENGINE_LOAD_ALREADY_ATTEMPTED");
    ODEngineLoadAttempted=YES;
    int fd=open(url.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);
    if(fd<0)return ODLoaderFail(error,@"PREPARED_ENGINE_UNAVAILABLE");
    struct stat before,after,path;
    BOOL valid=fstat(fd,&before)==0&&S_ISREG(before.st_mode)&&before.st_size>0&&
        (uint64_t)before.st_size>=ODPreparedBytes&&before.st_size<=128*1024*1024;
    NSMutableData *data=valid?[NSMutableData dataWithLength:(NSUInteger)before.st_size]:nil;
    NSUInteger done=0;
    while(valid&&done<data.length) {
        ssize_t n=pread(fd,(uint8_t *)data.mutableBytes+done,data.length-done,(off_t)done);
        if(n<=0){valid=NO;break;}done+=(NSUInteger)n;
    }
    valid=valid&&ODEngineCandidate(data);
    if(!valid){close(fd);return ODLoaderFail(error,@"PREPARED_ENGINE_IDENTITY_MISMATCH");}
    NSError *ignored=nil;
    if(!configure(&ignored)){close(fd);return ODLoaderFail(error,@"ENGINE_ENVIRONMENT_PREPARATION_FAILED");}
    valid=fstat(fd,&after)==0&&lstat(url.fileSystemRepresentation,&path)==0&&!S_ISLNK(path.st_mode)&&
        before.st_dev==after.st_dev&&before.st_ino==after.st_ino&&before.st_size==after.st_size&&
        before.st_mtimespec.tv_sec==after.st_mtimespec.tv_sec&&before.st_mtimespec.tv_nsec==after.st_mtimespec.tv_nsec&&
        path.st_dev==before.st_dev&&path.st_ino==before.st_ino;
    if(!valid){close(fd);return ODLoaderFail(error,@"PREPARED_ENGINE_CHANGED");}
    // Ordinary dyld/code-signing policy applies. No signature/protection bypass,
    // process injection, raw MH_EXECUTE fallback or source patcher execution.
    ODResidentEngine=dlopen(url.fileSystemRepresentation,RTLD_NOW|RTLD_LOCAL);
    close(fd);
    if(!ODResidentEngine)return ODLoaderFail(error,@"PREPARED_ENGINE_DYLD_LOAD_FAILED");
    if(nativeOrigin){
        if(!ODVerifySuppliedGameHTTPABI(NULL))return ODLoaderFail(error,@"PREPARED_ENGINE_HTTP_ABI_MISMATCH");
        *nativeOrigin=ODCreateOriginalNativeOriginForAdmittedImage(url,data,NULL);
        if(!*nativeOrigin)return ODLoaderFail(error,@"PREPARED_ENGINE_NATIVE_ORIGIN_UNAVAILABLE");
    }
    return YES;
}
BOOL ODLoadPreparedOriginalEngine(NSURL *url,ODPreparedEngineEnvironment configure,NSError **error) {
    return ODLoadPreparedEngine(url,configure,NULL,error);
}
BOOL ODLoadPreparedOriginalEngineWithNativeOrigin(NSURL *url,ODPreparedEngineEnvironment configure,
        ODOriginalNativeOrigin **nativeOrigin,NSError **error) {
    if(!nativeOrigin)return ODLoaderFail(error,@"INVALID_ENGINE_LOAD_CONTEXT");
    return ODLoadPreparedEngine(url,configure,nativeOrigin,error);
}
