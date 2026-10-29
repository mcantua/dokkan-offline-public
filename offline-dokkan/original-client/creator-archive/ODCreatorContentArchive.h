#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
typedef void (^ODCreatorArchiveReply)(NSDictionary * _Nullable result,NSString * _Nullable error);
typedef void (^ODCreatorArchiveDocumentCompletion)(NSDictionary<NSString *,NSData *> * _Nullable files,
                                                   NSString * _Nullable error);
typedef void (^ODCreatorArchiveSnapshotProvider)(ODCreatorArchiveDocumentCompletion completion);
typedef void (^ODCreatorArchiveDocumentsRestorer)(NSDictionary<NSString *,NSData *> *verifiedFiles,
                                                   ODCreatorArchiveReply completion);
/** One native-issued Creator resource/document archive capability. Page messages
 * supply action/gallery only, never filesystem authority. Native callers retain
 * folder security-scope access and serialize workspace mutations for the job.
 * A nil archive folder yields available:NO; private app storage is not advertised
 * as an archive surviving uninstall. Session callbacks own project authority. */
@interface ODCreatorContentArchive : NSObject
- (nullable instancetype)initWithResourcesRootURL:(NSURL *)resources
    archiveFolderURL:(nullable NSURL *)archiveFolder
    contextIsCurrent:(BOOL (^)(void))current
    snapshotProvider:(ODCreatorArchiveSnapshotProvider)snapshot
    documentsRestorer:(ODCreatorArchiveDocumentsRestorer)restore
    error:(NSError * _Nullable * _Nullable)error NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic,readonly) BOOL busy;
- (void)handleArguments:(NSDictionary *)arguments reply:(ODCreatorArchiveReply)reply;
- (void)invalidate;
@end
NS_ASSUME_NONNULL_END
