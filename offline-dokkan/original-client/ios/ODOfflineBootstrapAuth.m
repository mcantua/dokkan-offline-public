#import "ODOfflineBootstrapAuth.h"
#import "ODLocalURLProtocol.h"
#import <Security/Security.h>
#include <stdint.h>
#include <string.h>
#include <time.h>

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
+ (NSArray<ODLocalTransportRoute *> *)candidateRoutesWithExpiresIn:(int32_t)expiresIn
        contextIsCurrent:(BOOL (^)(void))contextIsCurrent error:(NSError **)error {
    if (expiresIn <= 0 || !contextIsCurrent) {
        if (error) *error = ODAuthError(@"INVALID_OFFLINE_AUTH_OWNER");
        return nil;
    }
    BOOL (^current)(void) = [contextIsCurrent copy];
    // Both handlers run on ODLocalURLProtocol's serial queue. No disk state or
    // request headers/body values become part of the locally issued identity.
    __block NSDictionary *issued = nil;
    __block time_t issuedAt = 0;
    ODLocalTransportRoute *nonce = [[ODLocalTransportRoute alloc] initWithMethod:@"GET" path:@"/auth/nonce"
        handler:^(ODLocalTransportRequest *request, ODLocalTransportCompletion complete) {
            (void)request;
            if (!current()) {
                issued = nil;
                complete(nil, ODAuthError(@"OFFLINE_AUTH_SCOPE_CHANGED"));
                return;
            }
            issued = nil;
            time_t now = time(NULL);
            if (now < 0 || (uint64_t)now > INT32_MAX) {
                complete(nil, ODAuthError(@"INVALID_NATIVE_TIME"));
                return;
            }
            NSError *failure = nil;
            NSDictionary *next = [self issuePlainJSONWithNativeTime:(int32_t)now expiresIn:expiresIn error:&failure];
            if (!next || !current()) {
                complete(nil, failure ?: ODAuthError(@"OFFLINE_AUTH_SCOPE_CHANGED"));
                return;
            }
            NSData *body = [next[@"plain_json_body_candidates"][@"nonce"] dataUsingEncoding:NSUTF8StringEncoding];
            ODLocalTransportResponse *response = [[ODLocalTransportResponse alloc] initWithStatusCode:200
                contentType:@"application/json" body:body];
            if (!response) {
                complete(nil, ODAuthError(@"OFFLINE_AUTH_JSON_ENCODING_FAILED"));
                return;
            }
            if (!current()) {
                complete(nil, ODAuthError(@"OFFLINE_AUTH_SCOPE_CHANGED"));
                return;
            }
            issued = next;
            issuedAt = now;
            complete(response, nil);
        }];
    ODLocalTransportRoute *signIn = [[ODLocalTransportRoute alloc] initWithMethod:@"POST" path:@"/auth/sign_in"
        handler:^(ODLocalTransportRequest *request, ODLocalTransportCompletion complete) {
            (void)request;
            if (!current()) {
                issued = nil;
                complete(nil, ODAuthError(@"OFFLINE_AUTH_SCOPE_CHANGED"));
                return;
            }
            time_t now = time(NULL);
            if (!issued || now < 0 || now < issuedAt || (int64_t)now >= [issued[@"expiry_unix"] longLongValue]) {
                issued = nil;
                complete(nil, ODAuthError(@"OFFLINE_AUTH_NONCE_REQUIRED"));
                return;
            }
            // The native consumer adds expires_in to its receipt-time clock.
            // Repeated sign-ins retain this issue's original token/deadline.
            int64_t remaining = [issued[@"expiry_unix"] longLongValue] - (int64_t)now;
            NSDictionary *fields = @{@"access_token":issued[@"reader_relative"][@"sign_in"][@"access_token"],
                @"expires_in":@((int32_t)remaining)};
            NSData *body = [NSJSONSerialization dataWithJSONObject:fields options:0 error:NULL];
            ODLocalTransportResponse *response = [[ODLocalTransportResponse alloc] initWithStatusCode:200
                contentType:@"application/json" body:body];
            if (!current()) {
                issued = nil;
                complete(nil, ODAuthError(@"OFFLINE_AUTH_SCOPE_CHANGED"));
                return;
            }
            complete(response, response ? nil : ODAuthError(@"OFFLINE_AUTH_JSON_ENCODING_FAILED"));
        }];
    if (!nonce || !signIn) {
        if (error) *error = ODAuthError(@"OFFLINE_AUTH_ROUTE_CANDIDATE_FAILED");
        return nil;
    }
    return @[nonce, signIn];
}
@end
