#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** In-memory decoded request only. No source-account headers are forwarded or logged. */
@interface ODLocalTransportRequest : NSObject
@property (nonatomic, copy, readonly) NSString *method;
@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, copy, readonly) NSData *body;
/** Raw ASCII scalar query values admitted by this route's native policy.
 * No percent/form decoding, arrays, duplicate keys, headers or source account
 * values are added here. Empty when the request has no query. */
@property (nonatomic, copy, readonly) NSDictionary<NSString *,NSString *> *queryFields;
/** Thread-safe observation of this native transport request's current activity.
 * NO after cancellation, completion, timeout, or protocol release. This is a
 * snapshot; it does not reserve activity or roll back an already-started action.
 * The transport independently drops late/duplicate/cancelled delivery. */
- (BOOL)isActive;
- (instancetype)init NS_UNAVAILABLE;
@end

/** Final local response; redirects, cookies, credentials and arbitrary headers are absent. */
@interface ODLocalTransportResponse : NSObject
@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, copy, readonly) NSString *contentType;
@property (nonatomic, copy, readonly) NSData *body;
/** Owned native DTO only: encode a plain HTTP200 JSON object. The reviewed
 * ordinary client path treats the presence of root `sign` as the signed path,
 * including JSON null, so that key is refused. This adds no DTO fields, endpoint
 * schema, route registration or network admission. */
+ (nullable instancetype)plainJSONResponseWithObject:(NSDictionary *)object;
- (nullable instancetype)initWithStatusCode:(NSInteger)statusCode
                              contentType:(NSString *)contentType body:(NSData *)body;
- (instancetype)init NS_UNAVAILABLE;
@end

typedef void (^ODLocalTransportCompletion)(ODLocalTransportResponse *_Nullable response,
                                            NSError *_Nullable error);
typedef void (^ODLocalTransportHandler)(ODLocalTransportRequest *request,
                                         ODLocalTransportCompletion completion);
/** Native source-proven route policy only. Receives immutable bounded ASCII
 * strings; must reject unknown keys and unverified value forms. timewarp stays
 * transport data, never a clock. Runs promptly on the serial transport queue:
 * schema checks only, no main-thread wait, live scope read or network work.
 * The handler separately owns live native admission. No page supplies this. */
typedef BOOL (^ODLocalTransportScalarQueryValidator)(NSDictionary<NSString *,NSString *> *fields);

/** Trusted native loader registers only exact routes with verified current contracts.
 * No routes, response schemas or live-service credentials are bundled by this module. */
@interface ODLocalTransportRoute : NSObject
@property (nonatomic, copy, readonly) NSString *method;
@property (nonatomic, copy, readonly) NSString *path;
- (nullable instancetype)initWithMethod:(NSString *)method path:(NSString *)path
                               handler:(ODLocalTransportHandler)handler;
/** Explicit source-proven scalar-query opt-in. A nil validator preserves the
 * default rejection of every query, including an empty trailing question mark.
 * A nonnil validator also sees @{} when the URL has no query, allowing a route
 * to require its proven flags. Percent-encoded/repeated/array queries reject. */
- (nullable instancetype)initWithMethod:(NSString *)method path:(NSString *)path
                  scalarQueryValidator:(nullable ODLocalTransportScalarQueryValidator)validator
                               handler:(ODLocalTransportHandler)handler;
/** Invoke this immutable native route on the caller's queue. The admitted host
 * may wrap its owned routes for lifecycle checks without exposing or replacing
 * their handler blocks. This grants no route registration or WebView authority. */
- (void)handleRequest:(ODLocalTransportRequest *)request completion:(ODLocalTransportCompletion)completion;
- (instancetype)init NS_UNAVAILABLE;
@end

/** Install once, before the actual game starts. Read-only ABI preflight must pass.
 * Untagged game HTTP(S) requests are handled locally or rejected. Explicit
 * Creator-tool requests can use a separate native opaque request capability;
 * no request header/JS switch disables this original-game boundary.
 * Only exact approved origins + method/path pairs reach a handler. No fallback.
 * Request streams, URL credentials, fragments and noncanonical paths reject.
 * Queries reject unless that exact native route opts into the source-proven
 * scalar policy above; there is no generic query permission.
 * Handlers run on a serial queue and must return promptly; completion may be async.
 * This does not intercept libcurl/sockets, WKWebView, or already-created sessions. */
FOUNDATION_EXPORT BOOL ODInstallLocalTransport(NSArray<NSURL *> *approvedOrigins,
                                              NSArray<ODLocalTransportRoute *> *routes,
                                              NSError **error);

/** Explicitly include the protocol in game NSURLSession configurations created
 * after install. The game must actually use that configuration; no swizzle occurs. */
FOUNDATION_EXPORT NSURLSessionConfiguration *_Nullable
ODLocalTransportSessionConfiguration(NSURLSessionConfiguration *base);

typedef void (^ODUnsupportedOriginalRequestObserver)(NSString *method,NSString *canonicalReviewedPath);
/** Native diagnostic registration only. Emits at most64 distinct already-
 * reviewed method/path pairs on the transport queue. Dynamic path segments
 * become {id}; no origins, URLs, query/header/body values or body field names
 * are supplied. Observation never admits a response or permits network fallback.
 * Callback must not synchronously wait on main or start network work. */
FOUNDATION_EXPORT BOOL ODObserveUnsupportedOriginalRequests(ODUnsupportedOriginalRequestObserver observer,
    NSError * _Nullable * _Nullable error);

@interface ODLocalURLProtocol : NSURLProtocol
@end
NS_ASSUME_NONNULL_END
