#import "PairingStore.h"
#import "SecureStore.h"
#import <Security/Security.h>
#import <sys/stat.h>
#import <fcntl.h>
#import <unistd.h>
#import <errno.h>

static NSString *const AIPairingErrorDomain = @"org.tin.appinstaller.pairing";
static NSString *const AIPairingKeyName = @"engine.pairing";
static const NSUInteger AIPairingMaxBytes = 2 * 1024 * 1024;

@interface AIPairingStore ()
@property (nonatomic, strong) NSURL *directory;
@property (nonatomic, strong) NSURL *backupURL;
@end

@implementation AIPairingStore
- (instancetype)initWithDirectory:(NSURL *)directory {
    self = [super init];
    if (self) {
        _directory = directory;
        _backupURL = [directory URLByAppendingPathComponent:@"pairing.encrypted" isDirectory:NO];
    }
    return self;
}
- (BOOL)fail:(NSError **)error code:(NSInteger)code message:(NSString *)message {
    if (error) *error = [NSError errorWithDomain:AIPairingErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey:message}];
    return NO;
}
- (BOOL)prepareDirectory:(NSError **)error {
    if (!self.directory.isFileURL) return [self fail:error code:1 message:@"Secure pairing storage is unavailable."];
    struct stat directoryInfo;
    if (lstat(self.directory.fileSystemRepresentation, &directoryInfo) == 0 && !S_ISDIR(directoryInfo.st_mode))
        return [self fail:error code:1 message:@"Secure pairing storage is invalid."];
    if (lstat(self.backupURL.fileSystemRepresentation, &directoryInfo) == 0 &&
        (!S_ISREG(directoryInfo.st_mode) || directoryInfo.st_nlink != 1))
        return [self fail:error code:1 message:@"The pairing backup location is invalid."];
    NSError *failure = nil;
    BOOL created = [[NSFileManager defaultManager] createDirectoryAtURL:self.directory withIntermediateDirectories:YES
        attributes:@{NSFileProtectionKey:NSFileProtectionComplete} error:&failure];
    if (!created) return [self fail:error code:1 message:@"Secure pairing storage is unavailable."];
    if (![self.directory setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&failure])
        return [self fail:error code:1 message:@"Pairing storage could not be excluded from cloud backup."];
    // The caller creates a private app-container path. Reject symlink destinations.
    NSNumber *symbolic = nil;
    if (![self.directory getResourceValue:&symbolic forKey:NSURLIsSymbolicLinkKey error:&failure] || symbolic.boolValue)
        return [self fail:error code:1 message:@"Secure pairing storage is invalid."];
    return YES;
}
- (NSData *)keyTag {
    return [@"org.tin.appinstaller.pairing.backup-key" dataUsingEncoding:NSUTF8StringEncoding];
}
- (SecKeyRef)privateKeyCreatingIfNeeded:(BOOL)create error:(NSError **)error CF_RETURNS_RETAINED {
    // Pairing backup key is device-only and requires user presence; no key bytes leave Keychain.
    // Primary pairing protection follows the stricter configurable account/biometry policy.
    LAContext *context = [AISecureStore authorizedContext];
    if (!context) { [self fail:error code:2 message:@"Unlock secure storage before using the pairing file."]; return NULL; }
    NSDictionary *query = @{(__bridge id)kSecClass:(__bridge id)kSecClassKey,
        (__bridge id)kSecAttrApplicationTag:[self keyTag],
        (__bridge id)kSecAttrKeyType:(__bridge id)kSecAttrKeyTypeECSECPrimeRandom,
        (__bridge id)kSecAttrKeyClass:(__bridge id)kSecAttrKeyClassPrivate,
        (__bridge id)kSecReturnRef:@YES,
        (__bridge id)kSecUseAuthenticationContext:context};
    CFTypeRef key = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &key);
    if (status == errSecSuccess) return (SecKeyRef)key;
    if (key) CFRelease(key);
    if (!create || status != errSecItemNotFound) {
        [self fail:error code:3 message:@"The pairing backup could not be unlocked. Unlock the app or import a new pairing file."];
        return NULL;
    }
    // No additional persistent backup or exported private key is created.
    SecAccessControlRef access = SecAccessControlCreateWithFlags(NULL, kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        kSecAccessControlUserPresence, NULL);
    if (!access) { [self fail:error code:3 message:@"The pairing backup key could not be protected."]; return NULL; }
    NSDictionary *attributes = @{(__bridge id)kSecAttrKeyType:(__bridge id)kSecAttrKeyTypeECSECPrimeRandom,
        (__bridge id)kSecAttrKeySizeInBits:@256,
        (__bridge id)kSecUseAuthenticationContext:context,
        (__bridge id)kSecPrivateKeyAttrs:@{(__bridge id)kSecAttrIsPermanent:@YES,
            (__bridge id)kSecAttrApplicationTag:[self keyTag],
            (__bridge id)kSecAttrAccessControl:(__bridge id)access}};
    CFErrorRef failure = NULL;
    SecKeyRef result = SecKeyCreateRandomKey((__bridge CFDictionaryRef)attributes, &failure);
    CFRelease(access);
    if (failure) CFRelease(failure);
    if (!result) [self fail:error code:3 message:@"The pairing backup key could not be created."];
    return result;
}
- (BOOL)looksLikePairingData:(NSData *)data {
    if (!data.length || data.length > AIPairingMaxBytes) return NO;
    id plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:nil];
    if (![plist isKindOfClass:NSDictionary.class]) return NO;
    NSDictionary *record = plist;
    NSSet *remoteFields = [NSSet setWithArray:@[@"format_version", @"public_key", @"private_key", @"identifier",
        @"peer_identifier", @"peer_public_key", @"alt_irk"]];
    BOOL remote = NO;
    for (id field in record) if ([remoteFields containsObject:field]) { remote = YES; break; }
    if (remote) {
        // Only the current peer-pinned wire format is allowed. Cryptographic
        // host-key consistency and peer-key/signature verification remain Rust's
        // responsibility; these bounds also guard decrypted backup recovery.
        if (data.length > 1024 * 1024) return NO;
        id version = record[@"format_version"];
        if (![version isKindOfClass:NSNumber.class] ||
            CFGetTypeID((__bridge CFTypeRef)version) != CFNumberGetTypeID() ||
            CFNumberIsFloatType((__bridge CFNumberRef)version) || [version longLongValue] != 2) return NO;
        for (id field in record) if (![remoteFields containsObject:field]) return NO;
        for (NSString *field in @[@"identifier", @"peer_identifier"]) {
            id value = record[field];
            if (![value isKindOfClass:NSString.class]) return NO;
            NSData *encoded = [value dataUsingEncoding:NSUTF8StringEncoding];
            if (!encoded.length || encoded.length > 1024) return NO;
        }
        for (NSString *field in @[@"public_key", @"private_key", @"peer_public_key"])
            if (![record[field] isKindOfClass:NSData.class] || [record[field] length] != 32) return NO;
        id discoveryKey = record[@"alt_irk"];
        return !discoveryKey || ([discoveryKey isKindOfClass:NSData.class] && [discoveryKey length] == 16);
    }
    // Rust validates the complete format and device session. This check is only a local bound/type guard.
    for (NSString *key in @[@"HostID", @"SystemBUID"])
        if (![record[key] isKindOfClass:NSString.class] || ![record[key] length]) return NO;
    for (NSString *key in @[@"HostCertificate", @"HostPrivateKey", @"RootCertificate"])
        if (![record[key] isKindOfClass:NSData.class] || ![record[key] length]) return NO;
    return YES;
}
- (BOOL)importValidatedPairingData:(NSData *)data error:(NSError **)error {
    @synchronized(self) {
        if (![AISecureStore sessionAuthorized]) return [self fail:error code:2 message:@"Unlock secure storage before importing the pairing file."];
        if (![self looksLikePairingData:data]) return [self fail:error code:4 message:@"The pairing file is not valid."];
        if (![self prepareDirectory:error]) return NO;
        SecKeyRef privateKey = [self privateKeyCreatingIfNeeded:YES error:error];
        if (!privateKey) return NO;
        SecKeyRef publicKey = SecKeyCopyPublicKey(privateKey);
        SecKeyAlgorithm algorithm = kSecKeyAlgorithmECIESEncryptionCofactorX963SHA256AESGCM;
        if (!publicKey || !SecKeyIsAlgorithmSupported(publicKey, kSecKeyOperationTypeEncrypt, algorithm)) {
            if (publicKey) CFRelease(publicKey); CFRelease(privateKey);
            return [self fail:error code:3 message:@"Encrypted pairing backup is unavailable on this device."];
        }
        CFErrorRef failure = NULL;
        CFDataRef rawCipher = SecKeyCreateEncryptedData(publicKey, algorithm, (__bridge CFDataRef)data, &failure);
        CFRelease(publicKey); CFRelease(privateKey);
        if (failure) CFRelease(failure);
        if (!rawCipher) return [self fail:error code:3 message:@"The pairing file could not be encrypted."];
        NSData *cipher = CFBridgingRelease(rawCipher);
        // Format marker contains no identity or secret. The ECIES payload is authenticated encryption.
        const uint8_t version = 1;
        NSMutableData *envelope = [NSMutableData dataWithBytes:&version length:1];
        [envelope appendData:cipher];
        OSStatus status = [AISecureStore save:data key:AIPairingKeyName biometric:[AISecureStore biometricsEnabled]];
        if (status != errSecSuccess) return [self fail:error code:5 message:@"The pairing file could not be saved in secure storage."];
        NSError *writeError = nil;
        // Atomic replacement retains exactly one logical backup; no numbered/history copies.
        BOOL wrote = [envelope writeToURL:self.backupURL options:NSDataWritingAtomic | NSDataWritingFileProtectionComplete error:&writeError];
        if (!wrote) return [self fail:error code:6 message:@"The pairing file was saved, but its encrypted backup could not be updated."];
        if (![self.backupURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&writeError])
            return [self fail:error code:6 message:@"The pairing backup could not be excluded from cloud backup."];
        return YES;
    }
}
- (NSData *)pairingDataWithError:(NSError **)error {
    @synchronized(self) {
        if (![AISecureStore sessionAuthorized]) { [self fail:error code:2 message:@"Unlock secure storage before using the pairing file."]; return nil; }
        OSStatus status = errSecSuccess;
        NSData *primary = [AISecureStore load:AIPairingKeyName context:nil status:&status];
        if (primary) {
            if (![self looksLikePairingData:primary]) { [self fail:error code:4 message:@"Import a new pairing file."]; return nil; }
            return primary;
        }
        if (status != errSecItemNotFound) { [self fail:error code:5 message:@"The pairing file could not be unlocked."]; return nil; }
        // Open without following a symlink; verify the descriptor, not an earlier path lookup.
        int descriptor = open(self.backupURL.fileSystemRepresentation, O_RDONLY | O_NOFOLLOW | O_CLOEXEC);
        struct stat info;
        if (descriptor < 0) { [self fail:error code:7 message:@"Import a pairing file to connect this iPhone."]; return nil; }
        if (fstat(descriptor, &info) != 0 || !S_ISREG(info.st_mode) || info.st_nlink != 1 ||
            info.st_size < 2 || info.st_size > AIPairingMaxBytes + 1024) {
            close(descriptor); [self fail:error code:7 message:@"The pairing backup is invalid. Import a new pairing file."]; return nil;
        }
        NSMutableData *envelope = [NSMutableData dataWithLength:(NSUInteger)info.st_size];
        NSUInteger offset = 0;
        while (offset < envelope.length) {
            ssize_t amount = read(descriptor, ((uint8_t *)envelope.mutableBytes) + offset, envelope.length - offset);
            if (amount < 0 && errno == EINTR) continue;
            if (amount <= 0) break;
            offset += (NSUInteger)amount;
        }
        close(descriptor);
        if (offset != envelope.length) { [self fail:error code:7 message:@"The pairing backup could not be read."]; return nil; }
        if (envelope.length < 2 || ((const uint8_t *)envelope.bytes)[0] != 1) {
            [self fail:error code:7 message:@"Import a new pairing file; its backup is unavailable."]; return nil;
        }
        SecKeyRef privateKey = [self privateKeyCreatingIfNeeded:NO error:error];
        if (!privateKey) return nil;
        SecKeyAlgorithm algorithm = kSecKeyAlgorithmECIESEncryptionCofactorX963SHA256AESGCM;
        NSData *cipher = [envelope subdataWithRange:NSMakeRange(1, envelope.length - 1)];
        CFErrorRef cryptoError = NULL;
        CFDataRef rawPlain = NULL;
        if (SecKeyIsAlgorithmSupported(privateKey, kSecKeyOperationTypeDecrypt, algorithm))
            rawPlain = SecKeyCreateDecryptedData(privateKey, algorithm, (__bridge CFDataRef)cipher, &cryptoError);
        CFRelease(privateKey);
        if (cryptoError) CFRelease(cryptoError);
        if (!rawPlain) { [self fail:error code:7 message:@"The pairing backup could not be opened. Import a new pairing file."]; return nil; }
        NSData *plain = CFBridgingRelease(rawPlain);
        if (![self looksLikePairingData:plain]) { [self fail:error code:7 message:@"The pairing backup is invalid. Import a new pairing file."]; return nil; }
        if ([AISecureStore save:plain key:AIPairingKeyName biometric:[AISecureStore biometricsEnabled]] != errSecSuccess) {
            [self fail:error code:5 message:@"The pairing backup could not be restored to secure storage."]; return nil;
        }
        return plain;
    }
}
- (BOOL)removePairingWithError:(NSError **)error {
    @synchronized(self) {
        if (![AISecureStore sessionAuthorized]) return [self fail:error code:2 message:@"Unlock secure storage before removing pairing data."];
        OSStatus status = [AISecureStore remove:AIPairingKeyName];
        if (status != errSecSuccess && status != errSecItemNotFound)
            return [self fail:error code:5 message:@"The pairing file could not be removed."];
        NSError *failure = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.backupURL.path] &&
            ![[NSFileManager defaultManager] removeItemAtURL:self.backupURL error:&failure])
            return [self fail:error code:6 message:@"The encrypted pairing backup could not be removed."];
        NSDictionary *query = @{(__bridge id)kSecClass:(__bridge id)kSecClassKey,
            (__bridge id)kSecAttrApplicationTag:[self keyTag],
            (__bridge id)kSecAttrKeyType:(__bridge id)kSecAttrKeyTypeECSECPrimeRandom};
        status = SecItemDelete((__bridge CFDictionaryRef)query);
        if (status != errSecSuccess && status != errSecItemNotFound)
            return [self fail:error code:3 message:@"The pairing backup key could not be removed."];
        return YES;
    }
}
@end
