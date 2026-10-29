#import "ODNativeCreatorNetwork.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *const ODTicketProperty=@"OfflineDokkan.NativeCreator.RequestTicket.v1";
static const NSUInteger ODToolBodyLimit=32*1024*1024;

static NSDictionary *ODBoundHeaders(NSURLRequest *request) {
    // Foundation can add these transport defaults after task creation. Cookies,
    // Authorization and every custom provider header stay explicitly bound.
    NSSet *defaults=[NSSet setWithArray:@[@"host",@"user-agent",@"accept-language",@"accept-encoding",@"content-length",@"connection"]];
    NSMutableDictionary *headers=[NSMutableDictionary dictionary];
    for(NSString *key in request.allHTTPHeaderFields){
        NSString *name=key.lowercaseString;
        if(![defaults containsObject:name])headers[name]=request.allHTTPHeaderFields[key];
    }
    return [headers copy];
}
static NSData *ODBoundBody(NSURLRequest *request) {
    NSData *body=request.HTTPBody?:NSData.data;
    if(request.HTTPBodyStream||body.length>ODToolBodyLimit)return nil;
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];CC_SHA256(body.bytes,(CC_LONG)body.length,digest);
    return [NSData dataWithBytes:digest length:sizeof(digest)];
}
static BOOL ODToolURL(NSURL *url) {
    if(![url isKindOfClass:NSURL.class]||url.user!=nil||url.password!=nil||url.fragment!=nil)return NO;
    NSString *scheme=url.scheme.lowercaseString;
    if([scheme isEqualToString:@"https"])return url.host.length>0;
    return [scheme isEqualToString:@"http"]&&[url.host isEqualToString:@"127.0.0.1"]&&url.port.integerValue>0&&url.port.integerValue<=65535;
}

@interface ODNativeCreatorRequestTicket:NSObject
@property(nonatomic,copy) NSString *url;
@property(nonatomic,copy) NSString *method;
@property(nonatomic,copy) NSDictionary *headers;
@property(nonatomic,copy) NSData *bodyDigest;
@property(nonatomic,copy) ODNativeCreatorNetworkCurrent current;
@end
@implementation ODNativeCreatorRequestTicket
@end

static NSHashTable *ODIssuedTickets(void) {
    static NSHashTable *tickets;static dispatch_once_t once;
    dispatch_once(&once,^{tickets=[NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPointerPersonality];});
    return tickets;
}
static BOOL ODTicketCurrent(ODNativeCreatorRequestTicket *ticket) {
    @try{return ticket.current&&ticket.current();}@catch(NSException *exception){return NO;}
}

NSURLRequest *ODNativeCreatorAuthorizedRequest(NSURLRequest *request,ODNativeCreatorNetworkCurrent current,
    ODNativeCreatorURLAuthorization authorizeURL,NSError **error) {
    NSURLRequest *approved=nil;
    @try {
        NSData *body=[request isKindOfClass:NSURLRequest.class]?ODBoundBody(request):nil;
        if(body&&ODToolURL(request.URL)&&current&&authorizeURL&&current()&&authorizeURL(request.URL)){
            ODNativeCreatorRequestTicket *ticket=[ODNativeCreatorRequestTicket new];
            ticket.url=[request.URL.absoluteString copy];ticket.method=[request.HTTPMethod copy];
            ticket.headers=ODBoundHeaders(request);ticket.bodyDigest=body;ticket.current=[current copy];
            NSMutableURLRequest *copy=[request mutableCopy];
            [NSURLProtocol removePropertyForKey:ODTicketProperty inRequest:copy];
            [NSURLProtocol setProperty:ticket forKey:ODTicketProperty inRequest:copy];
            @synchronized(ODIssuedTickets()){[ODIssuedTickets() addObject:ticket];}
            approved=[copy copy];
        }
    }@catch(NSException *exception){approved=nil;}
    if(!approved&&error)*error=[NSError errorWithDomain:@"OfflineDokkanCreatorNetwork" code:1
        userInfo:@{NSLocalizedDescriptionKey:@"CREATOR_NETWORK_REQUEST_NOT_AUTHORIZED"}];
    return approved;
}

BOOL ODNativeCreatorRequestIsAuthorized(NSURLRequest *request) {
    id raw=[NSURLProtocol propertyForKey:ODTicketProperty inRequest:request];
    if(![raw isMemberOfClass:ODNativeCreatorRequestTicket.class])return NO;
    ODNativeCreatorRequestTicket *ticket=raw;
    @synchronized(ODIssuedTickets()){if(![ODIssuedTickets() containsObject:ticket])return NO;}
    NSData *body=ODBoundBody(request);
    return body&&ODToolURL(request.URL)&&[ticket.url isEqualToString:request.URL.absoluteString]&&
        [ticket.method isEqualToString:request.HTTPMethod]&&[ticket.headers isEqualToDictionary:ODBoundHeaders(request)]&&
        [ticket.bodyDigest isEqualToData:body]&&ODTicketCurrent(ticket);
}
