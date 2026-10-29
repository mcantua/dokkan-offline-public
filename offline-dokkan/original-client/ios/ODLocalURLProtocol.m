#import "ODLocalURLProtocol.h"
#import "ODGameHTTPABI.h"
#import "ODNativeCreatorNetwork.h"
#import "ODOriginalNativeOrigin.h"
#import "ODLocalURLProtocolBootstrap.h"
#include <math.h>

static const NSUInteger ODRequestLimit = 8 * 1024 * 1024;
static const NSUInteger ODResponseLimit = 32 * 1024 * 1024;

static NSError *ODTransportError(NSInteger code, NSString *label) {
    // Labels are fixed strings. Never include request URL/body, original errors or credentials.
    return [NSError errorWithDomain:@"OfflineDokkanTransport" code:code
                          userInfo:@{NSLocalizedDescriptionKey:label}];
}
static BOOL ODCanonicalPath(NSString *path) {
    if (![path isKindOfClass:NSString.class] || ![path hasPrefix:@"/"] ||
        path.length > 2048 || [path containsString:@"//"]) return NO;
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:
        @"/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-"];
    if ([path rangeOfCharacterFromSet:allowed.invertedSet].location != NSNotFound) return NO;
    for (NSString *part in [path componentsSeparatedByString:@"/"])
        if ([part isEqualToString:@"."] || [part isEqualToString:@".."]) return NO;
    return YES;
}
static BOOL ODMethod(NSString *method) {
    return [method isKindOfClass:NSString.class] &&
           [@[@"GET",@"POST",@"PUT",@"PATCH",@"DELETE",@"HEAD",@"OPTIONS"] containsObject:method];
}
static NSString *ODOrigin(NSURLComponents *url) {
    if (!url) return nil;
    NSString *scheme = url.scheme.lowercaseString, *host = url.host.lowercaseString;
    if (!scheme.length || ![@[@"http",@"https"] containsObject:scheme] || !host.length || host.length > 253 ||
        url.user != nil || url.password != nil) return nil;
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:
        @"abcdefghijklmnopqrstuvwxyz0123456789.-"];
    if ([host rangeOfCharacterFromSet:allowed.invertedSet].location != NSNotFound ||
        [host hasPrefix:@"."] || [host hasSuffix:@"."] || [host containsString:@".."]) return nil;
    NSInteger port = url.port ? url.port.integerValue : ([scheme isEqualToString:@"https"] ? 443 : 80);
    if (port < 1 || port > 65535) return nil;
    return [NSString stringWithFormat:@"%@://%@:%ld",scheme,host,(long)port];
}

@interface ODLocalTransportRequest ()
@property (nonatomic, copy) BOOL (^activePredicate)(void);
- (instancetype)initWithMethod:(NSString *)method path:(NSString *)path body:(NSData *)body
                   queryFields:(NSDictionary<NSString *,NSString *> *)fields active:(BOOL (^)(void))active;
@end
@implementation ODLocalTransportRequest
- (instancetype)initWithMethod:(NSString *)method path:(NSString *)path body:(NSData *)body
                   queryFields:(NSDictionary<NSString *,NSString *> *)fields active:(BOOL (^)(void))active {
    if ((self = [super init])) {
        _method = [method copy]; _path = [path copy]; _body = [body copy];
        _queryFields = [fields copy];
        _activePredicate = [active copy];
    }
    return self;
}
- (BOOL)isActive { return _activePredicate ? _activePredicate() : NO; }
@end

@implementation ODLocalTransportResponse
+ (instancetype)plainJSONResponseWithObject:(NSDictionary *)object {
    @try {
        if (![object isKindOfClass:NSDictionary.class] || [object objectForKey:@"sign"] != nil ||
            ![NSJSONSerialization isValidJSONObject:object]) return nil;
        NSData *body = [NSJSONSerialization dataWithJSONObject:object options:0 error:NULL];
        if (!body || body.length > ODResponseLimit) return nil;
        // Check the frozen bytes too: a caller's mutable dictionary must not
        // add `sign` between the initial guard and serialization.
        id frozen = [NSJSONSerialization JSONObjectWithData:body options:0 error:NULL];
        if (![frozen isKindOfClass:NSDictionary.class] || [frozen objectForKey:@"sign"] != nil) return nil;
        return [[self alloc] initWithStatusCode:200 contentType:@"application/json" body:body];
    } @catch (NSException *exception) {
        (void)exception;
        return nil;
    }
}
- (instancetype)initWithStatusCode:(NSInteger)statusCode contentType:(NSString *)type body:(NSData *)body {
    if (statusCode < 200 || statusCode > 599 || (statusCode >= 300 && statusCode <= 399) ||
        ![body isKindOfClass:NSData.class] || body.length > ODResponseLimit ||
        ![@[@"application/json",@"application/json; charset=utf-8",@"application/octet-stream"] containsObject:type]) return nil;
    if ((self = [super init])) { _statusCode = statusCode; _contentType = [type copy]; _body = [body copy]; }
    return self;
}
@end

@interface ODLocalTransportRoute ()
@property (nonatomic, copy, readonly) ODLocalTransportHandler handler;
@property (nonatomic, copy, readonly, nullable) ODLocalTransportScalarQueryValidator scalarQueryValidator;
@end
@implementation ODLocalTransportRoute
- (instancetype)initWithMethod:(NSString *)method path:(NSString *)path handler:(ODLocalTransportHandler)handler {
    return [self initWithMethod:method path:path scalarQueryValidator:nil handler:handler];
}
- (instancetype)initWithMethod:(NSString *)method path:(NSString *)path
         scalarQueryValidator:(ODLocalTransportScalarQueryValidator)validator handler:(ODLocalTransportHandler)handler {
    if (!ODMethod(method) || !ODCanonicalPath(path) || !handler) return nil;
    if ((self = [super init])) {
        _method = [method copy]; _path = [path copy]; _handler = [handler copy];
        _scalarQueryValidator = [validator copy];
    }
    return self;
}
- (void)handleRequest:(ODLocalTransportRequest *)request completion:(ODLocalTransportCompletion)completion {
    _handler(request, completion);
}
@end

static NSDictionary<NSString *,NSString *> *ODParseScalarQuery(NSString *query) {
    if (![query isKindOfClass:NSString.class] || !query.length || query.length > 8192) return nil;
    NSArray<NSString *> *pairs = [query componentsSeparatedByString:@"&"];
    if (!pairs.count || pairs.count > 64) return nil;
    NSCharacterSet *keys = [NSCharacterSet characterSetWithCharactersInString:
        @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"];
    NSCharacterSet *values = [NSCharacterSet characterSetWithCharactersInString:
        @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-.:"];
    NSMutableDictionary<NSString *,NSString *> *fields = [NSMutableDictionary dictionary];
    for (NSString *pair in pairs) {
        NSRange separator = [pair rangeOfString:@"="];
        if (separator.location == NSNotFound || !separator.location || separator.location > 128) return nil;
        NSString *key = [pair substringToIndex:separator.location];
        NSString *value = [pair substringFromIndex:separator.location+1];
        // A second '=', percent encoding, '+' form ambiguity, array brackets,
        // controls, whitespace and non-ASCII all fail these exact alphabets.
        if (value.length > 512 || fields[key] != nil ||
            [key rangeOfCharacterFromSet:keys.invertedSet].location != NSNotFound ||
            [value rangeOfCharacterFromSet:values.invertedSet].location != NSNotFound) return nil;
        fields[key] = value;
    }
    return [fields copy];
}

static BOOL ODAdmitRouteQuery(ODLocalTransportRoute *route,NSString *query,
                             NSDictionary<NSString *,NSString *> **out) {
    if (!out) return NO;
    *out = nil;
    if (query != nil && !route.scalarQueryValidator) return NO;
    NSDictionary<NSString *,NSString *> *fields = query == nil ? @{} : ODParseScalarQuery(query);
    if (!fields) return NO;
    @try {
        if (route.scalarQueryValidator && !route.scalarQueryValidator(fields)) return NO;
    } @catch (NSException *exception) {
        (void)exception;
        return NO;
    }
    *out = fields;
    return YES;
}

@interface ODTransportConfiguration : NSObject
@property (nonatomic, copy) NSSet<NSString *> *origins;
@property (nonatomic, copy) NSDictionary<NSString *,ODLocalTransportRoute *> *routes;
@property (nonatomic, strong) dispatch_queue_t queue;
@end
@implementation ODTransportConfiguration
@end
static ODTransportConfiguration *ODConfiguration;
static BOOL ODTransportRearmed;
static ODUnsupportedOriginalRequestObserver ODUnsupportedObserver;
static NSMutableSet<NSString *> *ODObservedRequestPairs;

static BOOL ODTransportConfigurationIsCurrent(ODTransportConfiguration *configuration) {
    @synchronized(ODLocalURLProtocol.class) { return configuration && ODConfiguration == configuration; }
}

BOOL ODObserveUnsupportedOriginalRequests(ODUnsupportedOriginalRequestObserver observer,NSError **error) {
    @synchronized(ODLocalURLProtocol.class) {
        if(!observer||ODUnsupportedObserver){if(error)*error=ODTransportError(7,@"INVALID_ORIGINAL_REQUEST_OBSERVER");return NO;}
        ODUnsupportedObserver=[observer copy];ODObservedRequestPairs=[NSMutableSet set];return YES;
    }
}
static NSString *ODReviewedRequestPath(NSString *path) {
    if(!ODCanonicalPath(path))return nil;
    // Vocabulary already reviewed in collect_protocol_evidence.py. No observed
    // dynamic segment is copied into the result, even if it looks numeric.
    NSArray *fixed=@[@"/auth/nonce",@"/auth/sign_in",@"/resources/login",@"/resources/home",@"/user/mydata",@"/user_areas",
        @"/user_cards/",@"/cards",@"/teams",@"/events",@"/quests",@"/sugoroku_maps/start",@"/sugoroku_maps/finish",
        @"/missions",@"/missions/put_forward",@"/potentials",@"/potentials/release",@"/equip",@"/dragonball_sets",
        @"/db_stories",@"/genkai_battles",@"/joint_campaigns",@"/cooperation_campaigns",@"/announcements",
        @"/briefing",@"/support_leaders",@"/client_assets",@"/ondemand_assets",@"/assets/database",@"/sd/battle",
        @"/sd/characters",@"/sd/packs",@"/unrelease",@"/item_reverse_resolutions",@"/iap_rails",
        @"/client_assets/database",@"/item_reverse_resolutions/achievements",@"/iap_rails/googleplay_products"];
    if([fixed containsObject:path])return path;
    NSArray *templates=@[@"/quests/{id}/sugoroku_maps/start",@"/quests/{id}/sugoroku_maps/finish",
        @"/quests/{id}/sugoroku_maps/continue_info",@"/quests/{id}/sugoroku_maps/continue",
        @"/quests/{id}/briefing",@"/quests/{id}/supporters",@"/user_cards/{id}/potentials",
        @"/user_cards/{id}/potentials/release",@"/user_cards/{id}/potentials/{id}/unrelease",@"/cards/{id}/equip"];
    NSArray *parts=[path componentsSeparatedByString:@"/"];
    for(NSString *pattern in templates){
        NSArray *expected=[pattern componentsSeparatedByString:@"/"];if(parts.count!=expected.count)continue;
        BOOL matches=YES;
        for(NSUInteger i=0;i<parts.count;++i)
            if([expected[i] isEqualToString:@"{id}"] ? ![parts[i] length] : ![expected[i] isEqual:parts[i]]){matches=NO;break;}
        if(matches)return pattern;
    }
    return nil;
}
static void ODRecordUnsupportedRequest(NSURLRequest *request) {
    NSString *method=request.HTTPMethod;if(!ODMethod(method))return;
    NSURLComponents *url=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
    NSString *path=ODReviewedRequestPath(url.percentEncodedPath);if(!path)return;
    ODUnsupportedOriginalRequestObserver observer=nil;
    @synchronized(ODLocalURLProtocol.class){
        if(!ODUnsupportedObserver||ODObservedRequestPairs.count>=64)return;
        NSString *pair=[NSString stringWithFormat:@"%@ %@",method,path];
        if([ODObservedRequestPairs containsObject:pair])return;
        [ODObservedRequestPairs addObject:pair];observer=[ODUnsupportedObserver copy];
    }
    @try{observer(method,path);}@catch(NSException *exception){/* Diagnostics cannot alter transport admission. */}
}

static ODTransportConfiguration *ODCreateTransportConfiguration(NSArray<NSURL *> *origins,
        NSArray<ODLocalTransportRoute *> *routes, NSError **error) {
    if (![origins isKindOfClass:NSArray.class] || origins.count > 32 ||
        ![routes isKindOfClass:NSArray.class] || routes.count > 4096 || (routes.count && !origins.count)) {
        if (error) *error = ODTransportError(2,@"INVALID_LOCAL_CONFIGURATION"); return nil;
    }
    NSMutableSet *approved = [NSMutableSet set]; NSMutableDictionary *admitted = [NSMutableDictionary dictionary];
    for (NSURL *origin in origins) {
        NSURLComponents *url = [origin isKindOfClass:NSURL.class] ? [NSURLComponents componentsWithURL:origin resolvingAgainstBaseURL:NO] : nil;
        NSString *key = url ? ODOrigin(url) : nil;
        if (!key || (url.percentEncodedPath.length && ![url.percentEncodedPath isEqualToString:@"/"]) || url.query != nil || url.fragment != nil) {
            if (error) *error = ODTransportError(2,@"INVALID_LOCAL_CONFIGURATION"); return nil;
        }
        [approved addObject:key];
    }
    for (ODLocalTransportRoute *route in routes) {
        if (![route isMemberOfClass:ODLocalTransportRoute.class]) {
            if (error) *error = ODTransportError(2,@"INVALID_LOCAL_CONFIGURATION"); return nil;
        }
        NSString *key = [NSString stringWithFormat:@"%@ %@",route.method,route.path];
        if (admitted[key]) { if (error) *error = ODTransportError(2,@"DUPLICATE_LOCAL_ROUTE"); return nil; }
        admitted[key] = route;
    }
    ODTransportConfiguration *configuration = [ODTransportConfiguration new];
    configuration.origins = approved; configuration.routes = admitted;
    return configuration;
}

static BOOL ODInstallTransport(NSArray<NSURL *> *origins, NSArray<ODLocalTransportRoute *> *routes,
                               BOOL requireLoadedABI, NSError **error) {
    ODTransportConfiguration *configuration = ODCreateTransportConfiguration(origins,routes,error);
    if (!configuration || (requireLoadedABI && !ODVerifySuppliedGameHTTPABI(error))) return NO;
    @synchronized(ODLocalURLProtocol.class) {
        if (ODConfiguration) { if (error) *error = ODTransportError(2,@"LOCAL_TRANSPORT_ALREADY_INSTALLED"); return NO; }
        configuration.queue = dispatch_queue_create("personal.offlinedokkan.original-local-http",DISPATCH_QUEUE_SERIAL);
        ODConfiguration = configuration;
        if (![NSURLProtocol registerClass:ODLocalURLProtocol.class]) {
            ODConfiguration = nil; if (error) *error = ODTransportError(2,@"LOCAL_PROTOCOL_REGISTRATION_FAILED"); return NO;
        }
    }
    return YES;
}

BOOL ODInstallLocalTransport(NSArray<NSURL *> *origins, NSArray<ODLocalTransportRoute *> *routes, NSError **error) {
    return ODInstallTransport(origins,routes,YES,error);
}

BOOL ODInstallLocalTransportForPinnedBootstrap(NSArray<NSURL *> *origins,
                                               NSArray<ODLocalTransportRoute *> *routes,
                                               NSError **error) {
    return ODInstallTransport(origins,routes,NO,error);
}

BOOL ODRearmLocalTransportForLoadedOriginalOrigin(ODOriginalNativeOrigin *origin,
        NSArray<ODLocalTransportRoute *> *routes, NSError **error) {
    if (!NSThread.isMainThread || ![origin isMemberOfClass:ODOriginalNativeOrigin.class] ||
        ![origin isCurrentForLoadedOriginalImage] || ![routes isKindOfClass:NSArray.class] || !routes.count) {
        if (error) *error = ODTransportError(8,@"INVALID_LOADED_ORIGINAL_TRANSPORT"); return NO;
    }
    if (!ODVerifySuppliedGameHTTPABI(error)) return NO;
    NSURL *nativeOrigin = origin.origin;
    if (![nativeOrigin isKindOfClass:NSURL.class]) {
        if (error) *error = ODTransportError(8,@"INVALID_LOADED_ORIGINAL_TRANSPORT"); return NO;
    }
    ODTransportConfiguration *configuration = ODCreateTransportConfiguration(@[nativeOrigin],routes,error);
    if (!configuration || ![origin isCurrentForLoadedOriginalImage]) {
        if (error) *error = ODTransportError(8,@"INVALID_LOADED_ORIGINAL_TRANSPORT"); return NO;
    }
    @synchronized(ODLocalURLProtocol.class) {
        if (!ODConfiguration || ODTransportRearmed || ODConfiguration.origins.count ||
            ODConfiguration.routes.count || !ODConfiguration.queue) {
            if (error) *error = ODTransportError(8,@"ORIGINAL_TRANSPORT_REARM_REFUSED"); return NO;
        }
        configuration.queue = ODConfiguration.queue;
        ODConfiguration = configuration;
        ODTransportRearmed = YES;
    }
    return YES;
}

NSURLSessionConfiguration *ODLocalTransportSessionConfiguration(NSURLSessionConfiguration *base) {
    @synchronized(ODLocalURLProtocol.class) { if (!ODConfiguration) return nil; }
    NSURLSessionConfiguration *configuration = [base copy];
    NSMutableArray *classes = [NSMutableArray arrayWithObject:ODLocalURLProtocol.class];
    for (Class cls in configuration.protocolClasses) if (cls != ODLocalURLProtocol.class) [classes addObject:cls];
    configuration.protocolClasses = classes;
    configuration.URLCache = nil; configuration.HTTPCookieStorage = nil; configuration.URLCredentialStorage = nil;
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    return configuration;
}

@interface ODLocalURLProtocol ()
@property (nonatomic) BOOL stopped;
@property (nonatomic) BOOL completed;
@property (nonatomic) BOOL started;
@property (nonatomic, strong) ODTransportConfiguration *admittedConfiguration;
@end
@implementation ODLocalURLProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    @synchronized(ODLocalURLProtocol.class) { if (!ODConfiguration) return NO; }
    if (ODNativeCreatorRequestIsAuthorized(request)) return NO;
    NSString *scheme = request.URL.scheme.lowercaseString;
    return scheme.length && [@[@"http",@"https"] containsObject:scheme];
}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request { return request; }
+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b { return NO; }
- (void)finishResponse:(ODLocalTransportResponse *)response failure:(NSError *)failure {
    @synchronized(self) {
        if (_stopped || _completed) return;
        _completed = YES;
        if (_admittedConfiguration && !ODTransportConfigurationIsCurrent(_admittedConfiguration))
            failure = ODTransportError(8,@"LOCAL_TRANSPORT_RECONFIGURED");
        if (failure || ![response isMemberOfClass:ODLocalTransportResponse.class]) {
            ODRecordUnsupportedRequest(self.request);
            [self.client URLProtocol:self didFailWithError:failure ?: ODTransportError(5,@"INVALID_LOCAL_RESPONSE")]; return;
        }
        NSDictionary *headers = @{@"Content-Type":response.contentType,
            @"Content-Length":[NSString stringWithFormat:@"%lu",(unsigned long)response.body.length],
            @"Cache-Control":@"no-store"};
        NSHTTPURLResponse *http = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:response.statusCode
                                                         HTTPVersion:@"HTTP/1.1" headerFields:headers];
        [self.client URLProtocol:self didReceiveResponse:http cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        if (!_stopped && response.body.length && ![self.request.HTTPMethod isEqualToString:@"HEAD"])
            [self.client URLProtocol:self didLoadData:response.body];
        if (!_stopped) [self.client URLProtocolDidFinishLoading:self];
    }
}
- (void)startLoading {
    @synchronized(self) { if (_started || _stopped || _completed) return; _started = YES; }
    ODTransportConfiguration *configuration;
    @synchronized(ODLocalURLProtocol.class) { configuration = ODConfiguration; }
    @synchronized(self) { _admittedConfiguration = configuration; }
    if (!configuration) { [self finishResponse:nil failure:ODTransportError(2,@"LOCAL_TRANSPORT_UNAVAILABLE")]; return; }
    __weak ODLocalURLProtocol *weakSelf = self;
    dispatch_async(configuration.queue, ^{
        ODLocalURLProtocol *owner = weakSelf;
        if (!owner) return;
        @synchronized(owner) { if (owner.stopped || owner.completed) return; }
        if (!ODTransportConfigurationIsCurrent(configuration)) {
            [owner finishResponse:nil failure:ODTransportError(8,@"LOCAL_TRANSPORT_RECONFIGURED")]; return;
        }
        NSURLRequest *request = owner.request;
        NSURLComponents *url = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
        NSString *origin = ODOrigin(url), *path = url.percentEncodedPath, *method = request.HTTPMethod;
        if (!origin || ![configuration.origins containsObject:origin] || !ODCanonicalPath(path) ||
            url.fragment != nil || !ODMethod(method) || request.HTTPBodyStream || request.HTTPBody.length > ODRequestLimit) {
            [owner finishResponse:nil failure:ODTransportError(3,@"UNSUPPORTED_OFFLINE_REQUEST")]; return;
        }
        ODLocalTransportRoute *route = configuration.routes[[NSString stringWithFormat:@"%@ %@",method,path]];
        if (!route) { [owner finishResponse:nil failure:ODTransportError(4,@"UNVERIFIED_OFFLINE_ROUTE")]; return; }
        NSDictionary<NSString *,NSString *> *queryFields = nil;
        if (!ODAdmitRouteQuery(route,url.percentEncodedQuery,&queryFields)) {
            [owner finishResponse:nil failure:ODTransportError(3,@"UNSUPPORTED_OFFLINE_QUERY")]; return;
        }
        ODLocalTransportRequest *local = [[ODLocalTransportRequest alloc]
            initWithMethod:method path:path body:request.HTTPBody ?: NSData.data queryFields:queryFields active:^BOOL {
                ODLocalURLProtocol *current = weakSelf;
                if (!current) return NO;
                @synchronized(current) {
                    return current.started && !current.stopped && !current.completed &&
                        ODTransportConfigurationIsCurrent(current.admittedConfiguration);
                }
            }];
        NSTimeInterval seconds = request.timeoutInterval;
        if (!isfinite(seconds) || seconds <= 0) seconds = 60;
        seconds = fmin(120,fmax(1,seconds));
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(seconds * NSEC_PER_SEC)),configuration.queue, ^{
            [weakSelf finishResponse:nil failure:ODTransportError(6,@"LOCAL_RESPONSE_TIMEOUT")];
        });
        @try {
            [route handleRequest:local completion:^(ODLocalTransportResponse *response, NSError *error) {
                // Host errors may carry private user values. Only a fixed failure crosses this boundary.
                dispatch_async(configuration.queue, ^{
                    [weakSelf finishResponse:response failure:error ? ODTransportError(5,@"LOCAL_ROUTE_FAILED") : nil];
                });
            }];
        } @catch (NSException *exception) {
            [owner finishResponse:nil failure:ODTransportError(5,@"LOCAL_ROUTE_FAILED")];
        }
    });
}
- (void)stopLoading { @synchronized(self) { _stopped = YES; } }
@end
