#import "ODOfflineBootstrapAuth.h"
#import <Security/Security.h>
#include <stdint.h>
#include <string.h>

static NSError *ODAuthError(NSString *code) {
    return [NSError errorWithDomain:@"OfflineDokkan.BootstrapAuth" code:1
        userInfo:@{NSLocalizedDescriptionKey:code}];
}
static NSString *ODRandomToken(void) {
    uint8_t bytes[16];
    if (SecRandomCopyBytes(kSecRandomDefault, sizeof bytes, bytes) != errSecSuccess) return nil;
    char hex[33];
    static const char digits[] = "0123456789abcdef";
    for (int index = 0; index < 16; ++index) {
        hex[index * 2] = digits[bytes[index] >> 4];
        hex[index * 2 + 1] = digits[bytes[index] & 15];
    }
    hex[32] = 0;
    memset(bytes, 0, sizeof bytes);
    return [NSString stringWithUTF8String:hex];
}
static BOOL ODSigned32Sum(int32_t nativeTime, int32_t expiresIn, int32_t *sum) {
    int64_t combined = (int64_t)nativeTime + (int64_t)expiresIn;
    if (combined > INT32_MAX || combined < INT32_MIN) return NO;
    *sum = (int32_t)combined;
    return YES;
}

@implementation ODOfflineBootstrapAuth
+ (NSDictionary *)issueWithNativeTime:(int32_t)nativeTime expiresIn:(int32_t)expiresIn error:(NSError **)error {
    if (nativeTime < 0) {
        if (error) *error = ODAuthError(@"INVALID_NATIVE_TIME");
        return nil;
    }
    int32_t expiry = 0;
    if (!ODSigned32Sum(nativeTime, expiresIn, &expiry)) {
        if (error) *error = ODAuthError(@"SIGNED32_EXPIRY_OVERFLOW");
        return nil;
    }
    NSString *transaction = ODRandomToken(), *nonce = ODRandomToken(), *token = ODRandomToken();
    if (!transaction || !nonce || !token) {
        if (error) *error = ODAuthError(@"INVALID_OFFLINE_AUTH");
        return nil;
    }
    return @{
        @"schema": @1,
        @"kind": @"offline-bootstrap-auth-reader-relative-candidate",
        @"routes": @{
            @"nonce": @{@"method": @"GET", @"path": @"/auth/nonce"},
            @"sign_in": @{@"method": @"POST", @"path": @"/auth/sign_in"}
        },
        @"reader_relative": @{
            @"nonce": @{@"auth_transaction_id": transaction, @"nonce": nonce},
            @"sign_in": @{@"access_token": token, @"expires_in": @(expiresIn)}
        },
        @"expiry_unix": @(expiry),
        @"expiry_semantics": @"native time(NULL) plus signed32 expires_in",
        @"local_token_max": @128,
        @"field_value_format_verified": @NO,
        @"field_requiredness_verified": @NO,
        @"wire_body_envelope_verified": @NO,
        @"wire_wrapper": [NSNull null],
        @"http_body_json": [NSNull null],
        @"http_route_admitted": @NO,
        @"secret_or_captcha_admitted": @NO,
        @"remote_account_called": @NO,
        @"source_or_server_key_shipped": @NO
    };
}
+ (NSDictionary *)issuePlainJSONWithNativeTime:(int32_t)nativeTime expiresIn:(int32_t)expiresIn error:(NSError **)error {
    NSDictionary *issued = [self issueWithNativeTime:nativeTime expiresIn:expiresIn error:error];
    if (!issued) return nil;
    NSMutableDictionary *bodies = [NSMutableDictionary dictionaryWithCapacity:2];
    for (NSString *phase in @[@"nonce", @"sign_in"]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:issued[@"reader_relative"][phase]
            options:0 error:NULL];
        NSString *body = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
        if (!body) {
            if (error) *error = ODAuthError(@"OFFLINE_AUTH_JSON_ENCODING_FAILED");
            return nil;
        }
        bodies[phase] = body;
    }
    NSMutableDictionary *candidate = [issued mutableCopy];
    candidate[@"kind"] = @"offline-bootstrap-auth-plain-json-candidate";
    candidate[@"plain_json_body_candidates"] = [bodies copy];
    candidate[@"response_content_type"] = @"application/json";
    candidate[@"parsed_payload_root_verified"] = @YES;
    candidate[@"plain_json_body_envelope_verified"] = @YES;
    candidate[@"full_success_response_verified"] = @NO;
    candidate[@"original_iphone_runtime_verified"] = @NO;
    return [candidate copy];
}
@end
