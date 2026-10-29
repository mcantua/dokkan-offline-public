#import "SecureStore.h"
#import "../core/secure_storage.h"
#import <string.h>

static NSString *const AISecretService = @"org.tin.appinstaller.secure";
static NSString *const AISettingService = @"org.tin.appinstaller.settings";
static LAContext *AISession;
static NSDate *AISessionExpires;
static BOOL AIMigrating = NO;
static NSUInteger AIAuthenticationGeneration = 0;
static const NSUInteger AIMaxSecretSize = 4 * 1024 * 1024;

@implementation AISecureStore
+ (NSMutableDictionary *)query:(NSString *)key {
    return [@{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrService:AISecretService,
              (__bridge id)kSecAttrAccount:key} mutableCopy];
}
+ (BOOL)validKey:(NSString *)key {
    return key.length > 0 && key.length <= 512 && [key hasPrefix:@"engine."];
}
+ (NSMutableDictionary *)settingQuery {
    return [@{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrService:AISettingService,
              (__bridge id)kSecAttrAccount:@"biometrics"} mutableCopy];
}
// Metadata-only existence probes must never display LocalAuthentication UI or return secret bytes.
+ (OSStatus)metadataStatusForQuery:(NSDictionary *)query {
    NSMutableDictionary *q = [query mutableCopy];
    q[(__bridge id)kSecReturnAttributes] = @YES;
    q[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    LAContext *context = [LAContext new]; context.interactionNotAllowed = YES;
    q[(__bridge id)kSecUseAuthenticationContext] = context;
    CFTypeRef attributes = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)q, &attributes);
    if (attributes) CFRelease(attributes);
    [context invalidate];
    return status;
}
+ (BOOL)initialSetupRequired {
    @synchronized(self) {
        // Missing/unreadable/corrupt configuration beside an existing account must
        // never turn protected records into a passcode-only bootstrap session.
        if ([self metadataStatusForQuery:[self settingQuery]] != errSecItemNotFound) return NO;
        NSDictionary *service = @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
                                  (__bridge id)kSecAttrService:AISecretService};
        return [self metadataStatusForQuery:service] == errSecItemNotFound;
    }
}
+ (OSStatus)persistInitialBiometricsSetting {
    // Add only: never overwrite a setting that appeared after the fresh-state probe.
    uint8_t byte = 0;
    NSMutableDictionary *q = [self settingQuery];
    q[(__bridge id)kSecValueData] = [NSData dataWithBytes:&byte length:1];
    q[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
    return SecItemAdd((__bridge CFDictionaryRef)q, NULL);
}
+ (BOOL)biometricsEnabled {
    @synchronized(self) {
        NSMutableDictionary *q = [self settingQuery];
        q[(__bridge id)kSecReturnData] = @YES;
        LAContext *settingContext = [LAContext new]; settingContext.interactionNotAllowed = YES;
        q[(__bridge id)kSecUseAuthenticationContext] = settingContext;
        CFTypeRef result = NULL;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)q, &result);
        [settingContext invalidate];
        if (status != errSecSuccess) { if (result) CFRelease(result); return YES; } // Missing/unavailable setting fails toward protection.
        NSData *value = CFBridgingRelease(result);
        const uint8_t *bytes = value.bytes;
        return value.length != 1 || bytes[0] != 0;
    }
}
+ (OSStatus)persistBiometrics:(BOOL)enabled {
    uint8_t byte = enabled ? 1 : 0;
    NSData *value = [NSData dataWithBytes:&byte length:1];
    NSMutableDictionary *q = [self settingQuery];
    NSDictionary *attrs = @{(__bridge id)kSecValueData:value,
                           (__bridge id)kSecAttrAccessible:(__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly};
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)q, (__bridge CFDictionaryRef)attrs);
    if (status == errSecItemNotFound) {
        [q addEntriesFromDictionary:attrs];
        status = SecItemAdd((__bridge CFDictionaryRef)q, NULL);
    }
    return status;
}
+ (BOOL)sessionAuthorized {
    @synchronized(self) {
        if (AISession && (!AISessionExpires || [AISessionExpires timeIntervalSinceNow] <= 0)) {
            [AISession invalidate]; AISession = nil; AISessionExpires = nil;
            ++AIAuthenticationGeneration;
        }
        return !AIMigrating && AISession != nil;
    }
}
+ (LAContext *)authorizedContext {
    @synchronized(self) { return [self sessionAuthorized] ? AISession : nil; }
}
+ (void)endSession {
    @synchronized(self) {
        [AISession invalidate]; AISession = nil; AISessionExpires = nil;
        ++AIAuthenticationGeneration; // Invalidates any pending LocalAuthentication reply.
    }
}
+ (void)authenticateSessionWithReason:(NSString *)reason completion:(void (^)(BOOL))completion {
    __block NSUInteger generation;
    __block BOOL bootstrap;
    @synchronized(self) {
        if ([self sessionAuthorized]) { dispatch_async(dispatch_get_main_queue(), ^{ completion(YES); }); return; }
        bootstrap = [self initialSetupRequired];
        generation = ++AIAuthenticationGeneration;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        LAContext *context = [LAContext new];
        context.localizedCancelTitle = @"Cancel";
        // A genuinely fresh install first proves device ownership. Enrollment is
        // optional and offered later; existing secrets never use this bootstrap.
        LAPolicy policy = (!bootstrap && [self biometricsEnabled]) ? LAPolicyDeviceOwnerAuthenticationWithBiometrics : LAPolicyDeviceOwnerAuthentication;
        NSError *error = nil;
        if (![context canEvaluatePolicy:policy error:&error]) { [context invalidate]; completion(NO); return; }
        [context evaluatePolicy:policy localizedReason:reason reply:^(BOOL success, NSError *error) {
            @synchronized(self) {
                if (success && !AIMigrating && generation == AIAuthenticationGeneration) {
                    if (bootstrap && (![self initialSetupRequired] ||
                        [self persistInitialBiometricsSetting] != errSecSuccess)) success = NO;
                } else { success = NO; }
                if (success) {
                    [AISession invalidate]; AISession = context;
                    // Never let Rust background calls trigger authentication UI.
                    AISession.interactionNotAllowed = YES;
                    AISessionExpires = [NSDate dateWithTimeIntervalSinceNow:300];
                } else { [context invalidate]; success = NO; }
            }
            dispatch_async(dispatch_get_main_queue(), ^{ completion(success); });
        }];
    });
}
+ (SecAccessControlRef)access:(BOOL)biometric CF_RETURNS_RETAINED {
    return SecAccessControlCreateWithFlags(NULL, kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        biometric ? kSecAccessControlBiometryCurrentSet : kSecAccessControlUserPresence, NULL);
}
+ (OSStatus)saveDirect:(NSData *)data key:(NSString *)key biometric:(BOOL)biometric context:(LAContext *)context {
    if (![self validKey:key] || data.length > AIMaxSecretSize) return errSecParam;
    SecAccessControlRef access = [self access:biometric];
    if (!access) return errSecParam;
    NSMutableDictionary *q = [self query:key];
    if (!context) { CFRelease(access); return errSecInteractionNotAllowed; }
    context.interactionNotAllowed = YES;
    q[(__bridge id)kSecUseAuthenticationContext] = context;
    NSDictionary *attrs = @{(__bridge id)kSecValueData:data, (__bridge id)kSecAttrAccessControl:(__bridge id)access};
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)q, (__bridge CFDictionaryRef)attrs);
    if (status == errSecItemNotFound) {
        [q addEntriesFromDictionary:attrs];
        status = SecItemAdd((__bridge CFDictionaryRef)q, NULL);
    }
    CFRelease(access);
    return status;
}
+ (OSStatus)save:(NSData *)data key:(NSString *)key biometric:(BOOL)biometric {
    @synchronized(self) {
        if (![self sessionAuthorized]) return errSecInteractionNotAllowed;
        if (biometric != [self biometricsEnabled]) return errSecParam;
        return [self saveDirect:data key:key biometric:biometric context:AISession];
    }
}
+ (NSData *)load:(NSString *)key context:(LAContext *)context status:(OSStatus *)status {
    @synchronized(self) {
        if (![self validKey:key]) { if (status) *status = errSecParam; return nil; }
        if (![self sessionAuthorized]) { if (status) *status = errSecInteractionNotAllowed; return nil; }
        NSMutableDictionary *q = [self query:key];
        q[(__bridge id)kSecReturnData] = @YES;
        q[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
        LAContext *authorizedContext = context ?: AISession;
        authorizedContext.interactionNotAllowed = YES;
        q[(__bridge id)kSecUseAuthenticationContext] = authorizedContext;
        CFTypeRef value = NULL;
        OSStatus result = SecItemCopyMatching((__bridge CFDictionaryRef)q, &value);
        if (status) *status = result;
        if (result != errSecSuccess) { if (value) CFRelease(value); return nil; }
        NSData *data = CFBridgingRelease(value);
        if (data.length > AIMaxSecretSize) { if (status) *status = errSecParam; return nil; }
        return data;
    }
}
+ (OSStatus)remove:(NSString *)key {
    @synchronized(self) {
        if (![self validKey:key]) return errSecParam;
        if (![self sessionAuthorized]) return errSecInteractionNotAllowed;
        NSMutableDictionary *q = [self query:key];
        AISession.interactionNotAllowed = YES;
        q[(__bridge id)kSecUseAuthenticationContext] = AISession;
        return SecItemDelete((__bridge CFDictionaryRef)q);
    }
}
+ (NSArray<NSString *> *)recordKeys:(OSStatus *)status {
    NSMutableDictionary *q = [@{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:AISecretService, (__bridge id)kSecReturnAttributes:@YES,
        (__bridge id)kSecMatchLimit:(__bridge id)kSecMatchLimitAll} mutableCopy];
    if (!AISession) { if (status) *status = errSecInteractionNotAllowed; return @[]; }
    AISession.interactionNotAllowed = YES;
    q[(__bridge id)kSecUseAuthenticationContext] = AISession;
    CFTypeRef raw = NULL;
    OSStatus result = SecItemCopyMatching((__bridge CFDictionaryRef)q, &raw);
    if (status) *status = result == errSecItemNotFound ? errSecSuccess : result;
    if (result != errSecSuccess) { if (raw) CFRelease(raw); return @[]; }
    NSArray *rows = CFBridgingRelease(raw); NSMutableArray *keys = [NSMutableArray new];
    for (NSDictionary *row in rows) {
        NSString *key = row[(__bridge id)kSecAttrAccount];
        if ([key isKindOfClass:NSString.class] && [self validKey:key]) [keys addObject:key];
    }
    return keys;
}
+ (OSStatus)removeAccountRecords {
    @synchronized(self) {
        if (![self sessionAuthorized]) return errSecInteractionNotAllowed;
        OSStatus status = errSecSuccess; NSArray *keys = [self recordKeys:&status];
        if (status != errSecSuccess) return status;
        for (NSString *key in keys) {
            if ([key isEqualToString:@"engine.pairing"]) continue;
            OSStatus result = [self remove:key];
            if (result != errSecSuccess && result != errSecItemNotFound) status = result;
        }
        return status;
    }
}
+ (OSStatus)removeAll {
    @synchronized(self) {
        if (![self sessionAuthorized]) return errSecInteractionNotAllowed;
        OSStatus status = errSecSuccess; NSArray *keys = [self recordKeys:&status];
        if (status != errSecSuccess) return status;
        for (NSString *key in keys) {
            OSStatus result = [self remove:key];
            if (result != errSecSuccess && result != errSecItemNotFound) status = result;
        }
        return status;
    }
}
+ (void)setBiometricsEnabled:(BOOL)enabled completion:(void (^)(BOOL))completion {
    [self authenticateSessionWithReason:@"Authorize changes to secure storage." completion:^(BOOL success) {
        if (!success) { completion(NO); return; }
        if ([self biometricsEqual:enabled]) { completion(YES); return; }
        __block NSUInteger migrationGeneration;
        @synchronized(self) { migrationGeneration = AIAuthenticationGeneration; }
        LAContext *newContext = [LAContext new];
        LAPolicy policy = enabled ? LAPolicyDeviceOwnerAuthenticationWithBiometrics : LAPolicyDeviceOwnerAuthentication;
        NSError *error = nil;
        if (![newContext canEvaluatePolicy:policy error:&error]) { [newContext invalidate]; completion(NO); return; }
        [newContext evaluatePolicy:policy localizedReason:@"Confirm how your saved account is protected." reply:^(BOOL authorized, NSError *error) {
            if (!authorized) { [newContext invalidate]; dispatch_async(dispatch_get_main_queue(), ^{ completion(NO); }); return; }
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                BOOL changed = NO;
                @synchronized(self) {
                    if ([self sessionAuthorized] && migrationGeneration == AIAuthenticationGeneration) {
                        BOOL oldSetting = [self biometricsEnabled];
                        OSStatus status = errSecSuccess;
                        NSArray *keys = [self recordKeys:&status];
                        NSMutableDictionary<NSString *, NSMutableData *> *values = [NSMutableDictionary new];
                        if (status == errSecSuccess) {
                            // Read all records before changing any item. Values live only in RAM.
                            for (NSString *key in keys) {
                                NSData *value = [self load:key context:AISession status:&status];
                                if (!value || status != errSecSuccess) break;
                                values[key] = [value mutableCopy];
                            }
                        }
                        AIMigrating = YES;
                        NSMutableArray *updated = [NSMutableArray new];
                        if (status == errSecSuccess) {
                            for (NSString *key in keys) {
                                status = [self saveDirect:values[key] key:key biometric:enabled context:AISession];
                                if (status != errSecSuccess) break;
                                [updated addObject:key];
                            }
                        }
                        if (status == errSecSuccess) status = [self persistBiometrics:enabled];
                        if (status != errSecSuccess) {
                            // Existing items were never deleted. Attempt to restore changed ACLs.
                            for (NSString *key in updated) [self saveDirect:values[key] key:key biometric:oldSetting context:newContext];
                        } else {
                            [AISession invalidate]; AISession = newContext; AISession.interactionNotAllowed = YES;
                            AISessionExpires = [NSDate dateWithTimeIntervalSinceNow:300]; changed = YES;
                        }
                        for (NSMutableData *value in values.allValues) [value resetBytesInRange:NSMakeRange(0, value.length)];
                        AIMigrating = NO;
                        if (!changed) [self endSession];
                    }
                }
                if (!changed) [newContext invalidate];
                dispatch_async(dispatch_get_main_queue(), ^{ completion(changed); });
            });
        }];
    }];
}
+ (BOOL)biometricsEqual:(BOOL)enabled { return [self biometricsEnabled] == enabled; }
@end

static NSString *AIKeyFromCString(const char *key) {
    if (!key) return nil;
    size_t length = strnlen(key, 513);
    if (!length || length > 512) return nil;
    NSString *value = [[NSString alloc] initWithBytes:key length:length encoding:NSUTF8StringEncoding];
    return [value hasPrefix:@"engine."] ? value : nil;
}
static int32_t AIStoreStatus(OSStatus status) {
    if (status == errSecSuccess) return AI_STORE_OK;
    if (status == errSecItemNotFound) return AI_STORE_MISSING;
    if (status == errSecInteractionNotAllowed || status == errSecAuthFailed || status == errSecUserCanceled) return AI_STORE_LOCKED;
    return AI_STORE_ERROR;
}
int32_t ai_secure_read(const char *key, uint8_t *buffer, size_t capacity, size_t *length) {
    @autoreleasepool {
        if (!length) return AI_STORE_ERROR;
        *length = 0;
        NSString *name = AIKeyFromCString(key);
        if (!name) return AI_STORE_ERROR;
        OSStatus status = errSecSuccess;
        NSData *value = [AISecureStore load:name context:nil status:&status];
        if (!value) return AIStoreStatus(status);
        *length = value.length;
        if (!buffer && capacity == 0) return AI_STORE_OK;
        if (!buffer || capacity < value.length) return AI_STORE_BUFFER_SMALL;
        if (value.length) memcpy(buffer, value.bytes, value.length);
        return AI_STORE_OK;
    }
}
int32_t ai_secure_write(const char *key, const uint8_t *data, size_t length) {
    @autoreleasepool {
        NSString *name = AIKeyFromCString(key);
        if (!name || (!data && length) || length > AIMaxSecretSize) return AI_STORE_ERROR;
        NSData *value = [NSData dataWithBytes:data length:length];
        return AIStoreStatus([AISecureStore save:value key:name biometric:[AISecureStore biometricsEnabled]]);
    }
}
int32_t ai_secure_remove(const char *key) {
    @autoreleasepool {
        NSString *name = AIKeyFromCString(key);
        return name ? AIStoreStatus([AISecureStore remove:name]) : AI_STORE_ERROR;
    }
}
