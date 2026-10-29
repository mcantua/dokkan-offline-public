#import "ODDuoLauncher.h"
NS_ASSUME_NONNULL_BEGIN
@interface ODDuoLauncher ()
@property (nonatomic, readwrite, nullable) ODCreatorController *creatorController;
@property (nonatomic, readwrite, nullable) ODDuoAccountController *accountController;
@property (nonatomic, readwrite, nullable) ODLocalHost *savedAccountHost;
@property (nonatomic, strong, nullable) ODNativeCore *core;
@property (nonatomic, copy, nullable) NSURL *masterURL;
@property (nonatomic, copy, nullable) NSString *contentID;
@property (nonatomic, copy, nullable) NSString *game;
@property (nonatomic, strong, nullable) NSURL *creatorDirectory;
@property (nonatomic) BOOL creatingAccount;
@property (nonatomic) BOOL openCreatorWhenReady;
- (void)attachSavedAccountHostIfNeeded;
- (void)noteSavedAccountChanged;
- (BOOL)openSavedAccountCreator;
@end
NS_ASSUME_NONNULL_END
