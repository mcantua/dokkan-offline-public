#import "ODLocalHost.h"
#import "ODMasterLibrary.h"
#import "ODCreatorController.h"
#import "ODCreatorSession.h"
#import "ODCollectionController.h"
#import "../../adapter/ios/ODNativeCore.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include "sqlite3.h"
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

static BOOL ODSaveHasContent(NSURL *file,NSString *identity) {
    struct stat info;
    if(lstat(file.fileSystemRepresentation,&info)||!S_ISREG(info.st_mode)||info.st_size<100||info.st_size>512LL*1024*1024)return NO;
    sqlite3 *db=NULL;sqlite3_stmt *query=NULL;BOOL ok=NO;
    if(sqlite3_open_v2(file.fileSystemRepresentation,&db,SQLITE_OPEN_READONLY|SQLITE_OPEN_NOFOLLOW,NULL)==SQLITE_OK&&sqlite3_exec(db,"PRAGMA trusted_schema=OFF",NULL,NULL,NULL)==SQLITE_OK&&sqlite3_prepare_v2(db,"SELECT v FROM meta WHERE k='content'",-1,&query,NULL)==SQLITE_OK)
        ok=sqlite3_step(query)==SQLITE_ROW&&sqlite3_column_text(query,0)&&[identity isEqual:[NSString stringWithUTF8String:(const char *)sqlite3_column_text(query,0)]]&&sqlite3_step(query)==SQLITE_DONE;
    if(query)sqlite3_finalize(query);if(db)sqlite3_close(db);return ok;
}

@interface ODLocalHost () <UIDocumentPickerDelegate>
@property (nonatomic, readwrite) NSDictionary *snapshot;
@property (nonatomic, readwrite) NSString *lastError;
@end
@implementation ODLocalHost {
    NSURL *_databases, *_saves;
    NSArray<NSString *> *_identities;
    ODNativeCore *_core;
    NSString *_importSource;
    UILabel *_status, *_details;
    UIButton *_create, *_export, *_import, *_refresh, *_masterImport, *_creatorImport, *_creatorExport, *_creatorOpen, *_collection, *_teams, *_downloadCancel;
    NSURL *_selectedMaster; NSString *_selectedIdentity, *_selectedGame;
    ODMasterLibrary *_library;
    dispatch_queue_t _io;
    BOOL _selectingMaster;
    BOOL _selectingDefinition;
    NSUInteger _generation;
    BOOL _busy, _downloading, _downloadCancelled;
}
- (instancetype)initWithLibraryDirectory:(NSURL *)library saveDirectory:(NSURL *)saves {
    if ((self = [super init])) { _library = [[ODMasterLibrary alloc] initWithDirectory:library]; _saves = [saves copy]; _io = dispatch_queue_create("personal.offlinedokkan.master-import", DISPATCH_QUEUE_SERIAL); }
    return self;
}
#if OD_CLOUD_FIXTURES
- (instancetype)initWithDatabaseDirectory:(NSURL *)databases contentIdentities:(NSArray<NSString *> *)identities saveDirectory:(NSURL *)saves {
    if ((self = [self initWithLibraryDirectory:[saves URLByAppendingPathComponent:@"masters"] saveDirectory:saves])) { _databases = [databases copy]; _identities = [identities copy]; }
    return self;
}
#endif
- (UIButton *)button:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.configuration = [UIButtonConfiguration filledButtonConfiguration];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:48].active = YES;
    return button;
}
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"Offline Dokkan Battle"; self.view.backgroundColor = UIColor.systemBackgroundColor;
    UILabel *title = [UILabel new]; title.text = self.title; title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1]; title.numberOfLines = 0;
    _status = [UILabel new]; _status.numberOfLines = 0; _status.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _details = [UILabel new]; _details.numberOfLines = 0; _details.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _create = [self button:@"Create player" action:@selector(createPlayer)];
    _refresh = [self button:@"Refresh" action:@selector(refreshPlayer)];
    _collection = [self button:@"Character List" action:@selector(openCollection)];
    _teams = [self button:@"Team Formation" action:@selector(openTeams)];
    _export = [self button:@"Export save" action:@selector(exportSave)];
    _import = [self button:@"Import save" action:@selector(importSave)];
    _masterImport = [self button:@"Set up game data" action:@selector(importMaster)];
    _downloadCancel=[self button:@"Cancel download" action:@selector(cancelDatabaseDownload)];_downloadCancel.hidden=YES;
    _creatorImport = [self button:@"Import Offline Creator unit" action:@selector(importDefinition)];
    _creatorExport = [self button:@"Export Offline Creator unit" action:@selector(exportDefinition)];
    _creatorOpen = [self button:@"Open Unit Creator" action:@selector(openCreator)];
#if OD_CLOUD_FIXTURES
    _masterImport.hidden = _databases != nil;
#endif
    UILabel *note = [UILabel new]; note.text = @"Our own offline game. Player progress is saved on this device."; note.numberOfLines = 0; note.textColor = UIColor.secondaryLabelColor;
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[title, _masterImport, _downloadCancel, _status, _details, _create, _refresh, _collection, _teams, _creatorOpen, _creatorImport, _creatorExport, _export, _import, note]];
    stack.axis = UILayoutConstraintAxisVertical; stack.spacing = 16; stack.translatesAutoresizingMaskIntoConstraints = NO;
    UIScrollView *scroll = [UIScrollView new]; scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll]; [scroll addSubview:stack];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[[scroll.topAnchor constraintEqualToAnchor:safe.topAnchor], [scroll.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor], [scroll.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor], [scroll.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor], [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:20], [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-20], [stack.centerXAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.centerXAnchor], [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-40]]];
    [self openPlayer];
}
- (void)controls {
    _downloadCancel.hidden=!_downloading;_downloadCancel.enabled=_downloading;
    _refresh.enabled = !_busy; _import.enabled = !_busy && _core != nil; _masterImport.enabled = !_busy;
    _create.enabled = !_busy && !self.snapshot && [self.lastError isEqualToString:@"PROFILE_NOT_FOUND"];
    _create.hidden = self.snapshot != nil; _export.enabled = !_busy && self.snapshot != nil;
    _collection.enabled = !_busy && self.snapshot != nil; _teams.enabled = _collection.enabled;
    _creatorImport.enabled = !_busy && self.snapshot != nil; _creatorExport.enabled = _creatorImport.enabled;
    _creatorOpen.enabled = _creatorImport.enabled && _selectedMaster != nil;
}
- (void)openPlayer {
    [_core close]; _core = nil; _selectedMaster=nil; _selectedIdentity=nil; _selectedGame=nil; _generation++; self.snapshot = nil; self.lastError = nil;
    NSError *error = nil;
    if (![_saves isFileURL] || ![[NSFileManager defaultManager] createDirectoryAtURL:_saves withIntermediateDirectories:YES attributes:@{NSFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication} error:&error]) {
        self.lastError = @"INVALID_HOST_CONFIGURATION"; _status.text = @"Couldn't open player data."; [self controls]; return;
    }
    if (_databases && _identities.count == 2) {
        [self openMaster:[_databases URLByAppendingPathComponent:@"reference.db"] identity:_identities[0] source:@"eclipse"];
        return;
    }
    _busy = YES; _status.text = @"Opening game database…"; [self controls]; NSUInteger generation = _generation;
    dispatch_async(_io, ^{
        NSError *failure = nil; NSDictionary *selection = [self->_library activeSelection:&failure];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (generation != self->_generation) return; self->_busy = NO;
            if (!selection) { self.lastError = failure.localizedDescription; self->_status.text = @"Import your game database to get started."; self->_details.text = [self.lastError isEqual:@"DATA_SOURCE_SELECTION_REQUIRED"] ? @"Existing source data was kept. Choose its source in Set up game data." : @"Import a database or archive in Set up game data. Eclipse and Sparking are data sources for our game."; [self controls]; }
            else [self openMaster:selection[@"file"] identity:selection[@"content_id"] source:selection[@"source"]];
        });
    });
}
- (BOOL)adoptLegacyPlayerForSource:(NSString *)source identity:(NSString *)identity error:(NSError **)error {
    NSFileManager *files=NSFileManager.defaultManager;
    NSURL *canonical=[_saves URLByAppendingPathComponent:@"player.db"];
    if([files fileExistsAtPath:canonical.path]){
        if(ODSaveHasContent(canonical,identity))return YES;
        if(error)*error=[NSError errorWithDomain:@"OfflineDokkan" code:1 userInfo:@{NSLocalizedDescriptionKey:@"MASTER_MIGRATION_REQUIRED"}];return NO;
    }
    NSMutableArray *legacy=[NSMutableArray array];
    for(NSString *name in @[@"eclipse",@"sparking"]){
        NSURL *file=[_saves URLByAppendingPathComponent:[name stringByAppendingString:@"-player.db"]];
        if([files fileExistsAtPath:file.path])[legacy addObject:@{@"file":file,@"source":name}];
    }
    if(!legacy.count)return YES;
    if(legacy.count!=1||![legacy[0][@"source"] isEqual:source]){if(error)*error=[NSError errorWithDomain:@"OfflineDokkan" code:1 userInfo:@{NSLocalizedDescriptionKey:@"LEGACY_SAVE_RECOVERY_REQUIRED"}];return NO;}
    // Copy a consistent SQLite snapshot; never rename/delete an old player or ignore WAL.
    NSURL *origin=legacy[0][@"file"];
    if(!ODSaveHasContent(origin,identity)){if(error)*error=[NSError errorWithDomain:@"OfflineDokkan" code:1 userInfo:@{NSLocalizedDescriptionKey:@"LEGACY_SAVE_RECOVERY_REQUIRED"}];return NO;}
    NSURL *stage=[_saves URLByAppendingPathComponent:[@".adopt-" stringByAppendingFormat:@"%@.sqlite",NSUUID.UUID.UUIDString]];
    sqlite3 *input=NULL,*output=NULL;sqlite3_stmt *query=NULL;BOOL ok=NO;
    int fd=open(stage.fileSystemRepresentation,O_CREAT|O_EXCL|O_WRONLY|O_NOFOLLOW,0600);if(fd>=0)close(fd);
    if(fd>=0&&sqlite3_open_v2(origin.fileSystemRepresentation,&input,SQLITE_OPEN_READONLY|SQLITE_OPEN_NOFOLLOW,NULL)==SQLITE_OK&&sqlite3_exec(input,"PRAGMA trusted_schema=OFF;BEGIN",NULL,NULL,NULL)==SQLITE_OK&&sqlite3_prepare_v2(input,"SELECT v FROM meta WHERE k='content'",-1,&query,NULL)==SQLITE_OK){
        BOOL matches=sqlite3_step(query)==SQLITE_ROW&&sqlite3_column_text(query,0)&&[identity isEqual:[NSString stringWithUTF8String:(const char *)sqlite3_column_text(query,0)]];
        sqlite3_finalize(query);query=NULL;
        if(matches&&sqlite3_open_v2(stage.fileSystemRepresentation,&output,SQLITE_OPEN_READWRITE|SQLITE_OPEN_NOFOLLOW,NULL)==SQLITE_OK){
            int pageSize=0;sqlite3_stmt *pages=NULL;
            if(sqlite3_prepare_v2(input,"PRAGMA page_size",-1,&pages,NULL)==SQLITE_OK&&sqlite3_step(pages)==SQLITE_ROW)pageSize=sqlite3_column_int(pages,0);
            if(pages)sqlite3_finalize(pages);
            sqlite3_backup *backup=pageSize>0?sqlite3_backup_init(output,"main",input,"main"):NULL;
            if(backup){
                int rc;NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:30];
                do{rc=sqlite3_backup_step(backup,256);if((sqlite3_int64)sqlite3_backup_pagecount(backup)*pageSize>512LL*1024*1024){rc=SQLITE_TOOBIG;break;}if(rc==SQLITE_BUSY||rc==SQLITE_LOCKED)sqlite3_sleep(25);}while((rc==SQLITE_OK||rc==SQLITE_BUSY||rc==SQLITE_LOCKED)&&deadline.timeIntervalSinceNow>0);
                int finish=sqlite3_backup_finish(backup);ok=rc==SQLITE_DONE&&finish==SQLITE_OK;
            }
        }
    }
    if(query)sqlite3_finalize(query);if(output)sqlite3_close(output);if(input)sqlite3_close(input);
    if(ok){fd=open(stage.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW);ok=fd>=0&&fsync(fd)==0;if(fd>=0)close(fd);}
    if(ok)ok=link(stage.fileSystemRepresentation,canonical.fileSystemRepresentation)==0;
    [files removeItemAtURL:stage error:nil];
    if(!ok&&error)*error=[NSError errorWithDomain:@"OfflineDokkan" code:1 userInfo:@{NSLocalizedDescriptionKey:@"LEGACY_SAVE_RECOVERY_REQUIRED"}];
    return ok;
}
- (void)openMaster:(NSURL *)master identity:(NSString *)identity source:(NSString *)source {
    _busy=YES;[self controls];NSUInteger generation=_generation;
    dispatch_async(_io,^{
        NSError *error=nil;BOOL compatible=[self adoptLegacyPlayerForSource:source identity:identity error:&error];
        dispatch_async(dispatch_get_main_queue(),^{
            if(generation!=self->_generation)return;self->_busy=NO;
            if(!compatible){self.lastError=error.localizedDescription;self->_status.text=@"Your player data was kept.";self->_details.text=[self.lastError isEqual:@"MASTER_MIGRATION_REQUIRED"]?@"This data needs a compatibility update before it can be used with your player.":@"Earlier development saves need recovery before our single player can open.";[self controls];return;}
            [self->_core close];self->_selectedMaster=master;self->_selectedIdentity=[identity copy];self->_selectedGame=[source copy];
            self->_core=[[ODNativeCore alloc] initWithSaveURL:[self->_saves URLByAppendingPathComponent:@"player.db"] masterURL:master contentID:identity];
            [self refreshPlayer];
        });
    });
}
- (void)openCreator {
    if(_busy||!self.snapshot||!_selectedMaster||!_core)return;
    // Native-owned directories and the selected immutable master never come from page arguments.
    NSURL *directory=[_saves URLByAppendingPathComponent:@"creator/workspace"];
    NSURL *legacy=[[_saves URLByAppendingPathComponent:@"creator"] URLByAppendingPathComponent:_selectedGame];
    NSFileManager *files=NSFileManager.defaultManager;
    if(![files fileExistsAtPath:directory.path]&&[files fileExistsAtPath:legacy.path]){
        NSError *failure=nil;
        if(![files moveItemAtURL:legacy toURL:directory error:&failure]){_status.text=@"Your earlier Creator workspace was kept. Couldn't open it yet.";return;}
    }
    ODCreatorSession *session=[[ODCreatorSession alloc] initWithMasterURL:_selectedMaster contentID:_selectedIdentity game:_selectedGame directory:directory core:_core];
    __weak ODLocalHost *weakSelf=self;
    ODCreatorController *creator=[[ODCreatorController alloc] initWithSession:session completion:^{[weakSelf refreshPlayer];}];
    [self presentViewController:creator animated:YES completion:nil];
}
- (void)openCollection { [self presentOwnedForSlot:-1]; }
- (void)openTeams {
    if(_busy||!self.snapshot)return;
    UIAlertController *choose=[UIAlertController alertControllerWithTitle:@"Team Formation" message:@"Choose a team to edit." preferredStyle:UIAlertControllerStyleActionSheet];
    for(NSInteger slot=0;slot<20;slot++){
        NSUInteger count=0;for(NSDictionary *team in self.snapshot[@"teams"])if([team[@"slot"] integerValue]==slot)count=[team[@"members"] count];
        NSString *title=[NSString stringWithFormat:@"Team %ld · %lu / 6",(long)slot+1,(unsigned long)count];
        [choose addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){[self presentOwnedForSlot:slot];}]];
    }
    [choose addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    choose.popoverPresentationController.sourceView=_teams;choose.popoverPresentationController.sourceRect=_teams.bounds;[self presentViewController:choose animated:YES completion:nil];
}
- (void)presentOwnedForSlot:(NSInteger)slot {
    if(_busy||!self.snapshot||!_selectedMaster||!_core)return;
    NSDictionary *snapshot=self.snapshot;NSURL *master=_selectedMaster;NSUInteger generation=_generation;
    _busy=YES;[self controls];
    dispatch_async(_io,^{
        NSMutableDictionary *created=[NSMutableDictionary dictionary],*names=[NSMutableDictionary dictionary];
        for(NSDictionary *entry in snapshot[@"created_definitions"]){NSString *key=entry[@"definition_id"],*name=entry[@"document"][@"card"][@"name"];if([key isKindOfClass:NSString.class]&&[name isKindOfClass:NSString.class])created[key]=name;}
        sqlite3 *db=NULL;sqlite3_stmt *query=NULL;
        BOOL ok=sqlite3_open_v2(master.fileSystemRepresentation,&db,SQLITE_OPEN_READONLY|SQLITE_OPEN_NOFOLLOW,NULL)==SQLITE_OK&&sqlite3_exec(db,"PRAGMA trusted_schema=OFF;PRAGMA query_only=ON",NULL,NULL,NULL)==SQLITE_OK&&sqlite3_prepare_v2(db,"SELECT name FROM cards WHERE id=?1",-1,&query,NULL)==SQLITE_OK;
        NSMutableArray *characters=[NSMutableArray array];
        if(ok)for(NSDictionary *owned in snapshot[@"cards"]){
            NSDictionary *definition=[owned[@"created_definition"] isKindOfClass:NSDictionary.class]?owned[@"created_definition"]:nil;
            NSString *name=created[definition[@"definition_id"]?:@""];
            if(!name){NSNumber *identity=owned[@"master_id"];name=names[identity];if(!name){sqlite3_bind_int64(query,1,identity.longLongValue);if(sqlite3_step(query)==SQLITE_ROW&&sqlite3_column_text(query,0))name=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(query,0)];sqlite3_reset(query);sqlite3_clear_bindings(query);if(name)names[identity]=name;}}
            if(!name){ok=NO;break;}NSMutableDictionary *row=[owned mutableCopy];row[@"name"]=name;[characters addObject:row];
        }
        if(query)sqlite3_finalize(query);if(db)sqlite3_close(db);
        dispatch_async(dispatch_get_main_queue(),^{
            if(generation!=self->_generation)return;self->_busy=NO;[self controls];
            if(!ok){self->_status.text=@"Couldn't read your collection. Your characters were kept.";return;}
            NSArray *selected=@[];for(NSDictionary *team in snapshot[@"teams"])if([team[@"slot"] integerValue]==slot)selected=team[@"members"];
            void (^save)(NSArray<NSNumber *> *,void(^)(NSString *))=nil;
            if(slot>=0)save=^(NSArray<NSNumber *> *members,void(^reply)(NSString *)){
                if(generation!=self->_generation){reply(@"CONTENT_CHANGED");return;}
                [self->_core execute:@"team.set" profile:@"local-player" command:NSUUID.UUID.UUIDString arguments:@{@"slot":@(slot),@"members":members} reply:^(id result,NSError *error){reply(error.localizedDescription);if(!error)[self refreshPlayer];}];
            };
            ODCollectionController *collection=[[ODCollectionController alloc] initWithCharacters:characters selected:selected teamSlot:slot save:save];
            collection.lockCharacter=^(NSNumber *identity,BOOL locked,void(^reply)(NSString *)){
                if(generation!=self->_generation){reply(@"CONTENT_CHANGED");return;}
                [self->_core execute:@"card.lock" profile:@"local-player" command:NSUUID.UUID.UUIDString arguments:@{@"instance_id":identity,@"locked":@(locked)} reply:^(id result,NSError *error){reply(error.localizedDescription);if(!error)[self refreshPlayer];}];
            };
            UINavigationController *navigation=[[UINavigationController alloc] initWithRootViewController:collection];[self presentViewController:navigation animated:YES completion:nil];
        });
    });
}
- (void)finish:(id)result error:(NSError *)error generation:(NSUInteger)generation {
    if (generation != _generation) return;
    _busy = NO; self.lastError = error.localizedDescription;
    self.snapshot = [result isKindOfClass:NSDictionary.class] ? result : nil;
    if (self.snapshot) {
        _status.text = @"Player data ready";
        _details.text = [NSString stringWithFormat:@"Characters: %lu\nTeams: %lu\nACT: %@", (unsigned long)[self.snapshot[@"cards"] count], (unsigned long)[self.snapshot[@"teams"] count], self.snapshot[@"stamina"] ?: @0];
    } else {
        _status.text = [self.lastError isEqualToString:@"PROFILE_NOT_FOUND"] ? @"Create a player to get started." : @"Couldn't open player data. Try again.";
        _details.text = @"";
    }
    [self controls];
}
- (void)refreshPlayer {
    if (!_core || _busy) return; _busy = YES; _status.text = @"Opening player data…"; [self controls];
    NSUInteger generation = _generation;
    [_core execute:@"profile.refresh" profile:@"local-player" command:NSUUID.UUID.UUIDString arguments:@{} reply:^(id result, NSError *error) { [self finish:result error:error generation:generation]; }];
}
- (void)createPlayer {
    if (!_core || _busy || self.snapshot || ![self.lastError isEqualToString:@"PROFILE_NOT_FOUND"]) return;
    _busy = YES; [self controls]; NSUInteger generation = _generation;
    [_core execute:@"profile.create" profile:@"local-player" command:NSUUID.UUID.UUIDString arguments:@{} reply:^(id result, NSError *error) { [self finish:result error:error generation:generation]; }];
}
- (void)exportSave {
    if (_busy || !self.snapshot) return;
    NSURL *file = [_saves URLByAppendingPathComponent:[@"export-" stringByAppendingFormat:@"%@.sqlite", NSUUID.UUID.UUIDString]];
    _busy = YES; [self controls];
    [_core exportToURL:file reply:^(id result, NSError *error) {
        self->_busy = NO; [self controls];
        if (error) { self->_status.text = @"Couldn't export the save. Try again."; return; }
        UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[file] applicationActivities:nil];
        share.popoverPresentationController.sourceView = self->_export; share.popoverPresentationController.sourceRect = self->_export.bounds;
        share.completionWithItemsHandler = ^(UIActivityType type, BOOL completed, NSArray *items, NSError *failure) { [[NSFileManager defaultManager] removeItemAtURL:file error:nil]; };
        [self presentViewController:share animated:YES completion:nil];
    }];
}
- (void)importSave {
    if (_busy) return;
    _selectingMaster = NO; _selectingDefinition = NO;
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeItem] asCopy:YES];
    picker.delegate = self; picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}
- (void)cancelDatabaseDownload {
    @synchronized(self){_downloadCancelled=YES;}
    [_library cancelDownload];_downloadCancel.enabled=NO;_status.text=@"Cancelling download…";
}
- (void)downloadDatabase:(NSString *)source {
    if(_busy)return;
    if(self.snapshot&&_selectedGame&&![_selectedGame isEqual:source]){_status.text=@"This data needs a compatibility update before it can be used with your player. No download started.";return;}
    _busy=YES;_downloading=YES;@synchronized(self){_downloadCancelled=NO;}
    _status.text=@"Downloading game data…";_details.text=@"Only the selected database is downloaded. Your player stays on this device.";[self controls];NSUInteger generation=_generation;
    dispatch_async(_io,^{
        [self->_library downloadDatabaseForSource:source progress:^(int64_t received,int64_t total){
            dispatch_async(dispatch_get_main_queue(),^{
                if(generation!=self->_generation||!self->_downloading||self->_downloadCancelled)return;
                NSString *size=[NSByteCountFormatter stringFromByteCount:received countStyle:NSByteCountFormatterCountStyleFile];
                self->_status.text=total>0?[NSString stringWithFormat:@"Downloading %@ of %@…",size,[NSByteCountFormatter stringFromByteCount:total countStyle:NSByteCountFormatterCountStyleFile]]:[NSString stringWithFormat:@"Downloading %@…",size];
            });
        } completion:^(NSDictionary *selection,NSError *downloadError){
            dispatch_async(self->_io,^{
                NSError *failure=downloadError;BOOL accepted=selection!=nil&&!failure;
                @synchronized(self){
                    if(self->_downloadCancelled){failure=[NSError errorWithDomain:@"OfflineDokkan" code:1 userInfo:@{NSLocalizedDescriptionKey:@"SOURCE_DOWNLOAD_CANCELLED"}];accepted=NO;}
                    if(accepted){
                        NSURL *player=[self->_saves URLByAppendingPathComponent:@"player.db"];
                        if([NSFileManager.defaultManager fileExistsAtPath:player.path]&&!ODSaveHasContent(player,selection[@"content_id"])){
                            failure=[NSError errorWithDomain:@"OfflineDokkan" code:1 userInfo:@{NSLocalizedDescriptionKey:@"MASTER_MIGRATION_REQUIRED"}];accepted=NO;
                        }else accepted=[self->_library activateSource:source error:&failure];
                    }
                }
                dispatch_async(dispatch_get_main_queue(),^{
                    if(generation!=self->_generation)return;self->_downloading=NO;self->_busy=NO;[self controls];
                    if(accepted){[self openPlayer];return;}
                    NSString *code=failure.localizedDescription;
                    if([code isEqual:@"SOURCE_DOWNLOAD_CANCELLED"])self->_status.text=@"Download cancelled. Your player was kept.";
                    else if([code isEqual:@"PLAINTEXT_MASTER_REQUIRED_NO_DECRYPTION"])self->_status.text=@"This source download needs preparation. Import an already prepared database from Files. No decryption keys are included.";
                    else if([code isEqual:@"MASTER_MIGRATION_REQUIRED"])self->_status.text=@"This data needs a compatibility update. Your single player was kept.";
                    else self->_status.text=@"Couldn't download and validate this database. Your existing data was kept.";
                    self->_details.text=@"You can retry, or import a database or ZIP/APK from Files in Set up game data.";
                });
            });
        }];
    });
}
- (void)chooseDataAction:(NSString *)source {
    UIAlertController *action=[UIAlertController alertControllerWithTitle:@"Set up game data" message:@"Use your own file, or download a database from this source website. No download starts until you choose it." preferredStyle:UIAlertControllerStyleActionSheet];
    [action addAction:[UIAlertAction actionWithTitle:@"Import from Files" style:UIAlertActionStyleDefault handler:^(UIAlertAction *choice){
        self->_importSource=source;self->_selectingMaster=YES;self->_selectingDefinition=NO;
        UIDocumentPickerViewController *picker=[[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeItem] asCopy:NO];
        picker.delegate=self;picker.allowsMultipleSelection=NO;[self presentViewController:picker animated:YES completion:nil];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"Download database" style:UIAlertActionStyleDefault handler:^(UIAlertAction *choice){[self downloadDatabase:source];}]];
    [action addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    action.popoverPresentationController.sourceView=_masterImport;action.popoverPresentationController.sourceRect=_masterImport.bounds;
    [self presentViewController:action animated:YES completion:nil];
}
- (void)importMaster {
    if(_busy)return;
    UIAlertController *setup=[UIAlertController alertControllerWithTitle:@"Choose a data source" message:@"Eclipse and Sparking supply data for our own Offline Dokkan game. This does not switch your player or game mode." preferredStyle:UIAlertControllerStyleActionSheet];
    for(NSString *source in @[@"eclipse",@"sparking"])[setup addAction:[UIAlertAction actionWithTitle:[source isEqual:@"eclipse"]?@"Eclipse data":@"Sparking data" style:UIAlertActionStyleDefault handler:^(UIAlertAction *choice){[self chooseDataAction:source];}]];
    [setup addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    setup.popoverPresentationController.sourceView=_masterImport;setup.popoverPresentationController.sourceRect=_masterImport.bounds;
    [self presentViewController:setup animated:YES completion:nil];
}
- (void)importDefinition {
    if (_busy || !self.snapshot) return; _selectingMaster = NO; _selectingDefinition = YES;
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeJSON] asCopy:YES];
    picker.delegate = self; picker.allowsMultipleSelection = NO; [self presentViewController:picker animated:YES completion:nil];
}
- (void)exportDefinition {
    if (_busy || !self.snapshot) return; _busy = YES; [self controls];
    [_core execute:@"creator.library" profile:@"local-player" command:nil arguments:@{} reply:^(id result, NSError *error) {
        self->_busy = NO; [self controls]; NSArray *definitions = [result isKindOfClass:NSDictionary.class] ? result[@"definitions"] : nil;
        if (error) { self->_status.text = @"Couldn't open your Offline Creator units."; return; }
        if (!definitions.count) { self->_status.text = @"Import an Offline Creator unit first."; return; }
        UIAlertController *choose = [UIAlertController alertControllerWithTitle:@"Export Offline Creator unit" message:@"Choose a unit." preferredStyle:UIAlertControllerStyleActionSheet];
        for (NSDictionary *entry in definitions) {
            NSString *key = entry[@"definition_id"], *name = [entry[@"name"] isKindOfClass:NSString.class] ? entry[@"name"] : key;
            if (![key isKindOfClass:NSString.class]) continue;
            [choose addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { [self exportDefinitionID:key]; }]];
        }
        [choose addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        choose.popoverPresentationController.sourceView = self->_creatorExport; choose.popoverPresentationController.sourceRect = self->_creatorExport.bounds;
        [self presentViewController:choose animated:YES completion:nil];
    }];
}
- (void)exportDefinitionID:(NSString *)key {
    if (_busy) return; _busy = YES; [self controls];
    [_core execute:@"creator.export" profile:@"local-player" command:nil arguments:@{@"definition_id":key} reply:^(id result, NSError *error) {
        self->_busy = NO; [self controls];
        NSData *data = !error && result ? [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil] : nil;
        NSURL *file = [self->_saves URLByAppendingPathComponent:[@"offline-unit-" stringByAppendingFormat:@"%@.json",NSUUID.UUID.UUIDString]];
        if (!data || ![data writeToURL:file options:NSDataWritingWithoutOverwriting error:nil]) { self->_status.text = @"Couldn't export this Offline Creator unit."; return; }
        UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[file] applicationActivities:nil];
        share.popoverPresentationController.sourceView = self->_creatorExport; share.popoverPresentationController.sourceRect = self->_creatorExport.bounds;
        share.completionWithItemsHandler = ^(UIActivityType type, BOOL completed, NSArray *items, NSError *failure) { [NSFileManager.defaultManager removeItemAtURL:file error:nil]; };
        [self presentViewController:share animated:YES completion:nil];
    }];
}
- (void)documentPicker:(UIDocumentPickerViewController *)picker didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *source = urls.firstObject; if (!source || _busy) return;
    if (_selectingDefinition) {
        BOOL scope = [source startAccessingSecurityScopedResource]; _busy = YES; [self controls];
        dispatch_async(_io, ^{
            NSNumber *size = nil; [source getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
            NSData *bytes = size && size.unsignedLongLongValue <= 16*1024*1024 ? [NSData dataWithContentsOfURL:source options:NSDataReadingMappedIfSafe error:nil] : nil;
            NSDictionary *definition = bytes.length <= 16*1024*1024 && bytes ? [NSJSONSerialization JSONObjectWithData:bytes options:0 error:nil] : nil;
            if (scope) [source stopAccessingSecurityScopedResource];
            BOOL valid = [definition isKindOfClass:NSDictionary.class] && [definition[@"format"] isEqual:@"offline-dokkan-definition"] && [definition[@"schema_version"] isEqual:@1];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!valid) { self->_busy = NO; [self controls]; self->_status.text = @"Choose an Offline Creator unit JSON. This file was kept unchanged."; return; }
                [self->_core execute:@"creator.finish" profile:@"local-player" command:NSUUID.UUID.UUIDString arguments:@{@"definition":definition} reply:^(id result, NSError *error) {
                    self->_busy = NO; [self controls];
                    if (error) self->_status.text = @"This Offline Creator unit couldn't be imported. Your existing data was kept.";
                    else [self refreshPlayer];
                }];
            });
        });
        return;
    }
    if (_selectingMaster) {
        BOOL scope = [source startAccessingSecurityScopedResource]; _busy = YES; [self controls];
        NSString *game = _importSource;
        dispatch_async(_io, ^{
            NSError *failure=nil;NSDictionary *selection=nil;
            NSDictionary *active=[self->_library activeSelection:nil];
            BOOL hasPlayer=[NSFileManager.defaultManager fileExistsAtPath:[self->_saves URLByAppendingPathComponent:@"player.db"].path];
            if(hasPlayer&&active&&![active[@"source"] isEqual:game])failure=[NSError errorWithDomain:@"OfflineDokkan" code:1 userInfo:@{NSLocalizedDescriptionKey:@"MASTER_MIGRATION_REQUIRED"}];
            else {
                selection=[self->_library importURL:source game:game error:&failure];
                if(selection&&hasPlayer&&!ODSaveHasContent([self->_saves URLByAppendingPathComponent:@"player.db"],selection[@"content_id"])){
                    failure=[NSError errorWithDomain:@"OfflineDokkan" code:1 userInfo:@{NSLocalizedDescriptionKey:@"MASTER_MIGRATION_REQUIRED"}];selection=nil;
                }
                if(selection&&![self->_library activateSource:game error:&failure])selection=nil;
            }
            if (scope) [source stopAccessingSecurityScopedResource];
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_busy = NO; [self controls];
                if (selection) [self openPlayer];
                else self->_status.text = [failure.localizedDescription isEqual:@"MASTER_MIGRATION_REQUIRED"] ? @"This data needs a compatibility update before it can be used. Your single player was kept." : @"Couldn't import this game database. Your existing data was kept.";
            });
        });
        return;
    }
    // The document picker supplies a copy; the core validates content/schema/integrity before replacement.
    BOOL scope = [source startAccessingSecurityScopedResource];
    NSURL *copy = [_saves URLByAppendingPathComponent:[@"import-" stringByAppendingFormat:@"%@.sqlite", NSUUID.UUID.UUIDString]];
    NSError *copyError = nil; BOOL copied = [[NSFileManager defaultManager] copyItemAtURL:source toURL:copy error:&copyError];
    if (scope) [source stopAccessingSecurityScopedResource];
    if (!copied) { _status.text = @"Couldn't read the selected save."; return; }
    _busy = YES; [self controls];
    [_core importFromURL:copy reply:^(id result, NSError *error) {
        [[NSFileManager defaultManager] removeItemAtURL:copy error:nil]; self->_busy = NO; [self controls];
        if (error) self->_status.text = @"This save couldn't be imported. Your player data was kept.";
        else [self refreshPlayer];
    }];
}
@end
