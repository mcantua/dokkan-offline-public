#import "ODOriginalPlayerResourcesAdapter.h"
#import "ODOriginalRequestDecoder.h"

static NSError *ODPlayerResourcesError(NSString *code) {
    return [NSError errorWithDomain:@"OfflineDokkan.OriginalPlayerResources" code:1
        userInfo:@{NSLocalizedDescriptionKey:code}];
}
/* Pure bounded lexical checks: transport invokes these on its serial queue.
 * These values are never an identity, clock, revision, grant or Core command. */
static BOOL ODResourceUnsignedDecimal(id value) {
    if(![value isKindOfClass:NSString.class])return NO;
    NSString *text=value;
    if(!text.length||text.length>20||(text.length>1&&[text characterAtIndex:0]=='0'))return NO;
    for(NSUInteger i=0;i<text.length;++i){unichar c=[text characterAtIndex:i];if(c<'0'||c>'9')return NO;}
    return text.length<20||[text compare:@"18446744073709551615" options:NSLiteralSearch]!=NSOrderedDescending;
}
static BOOL ODResourceBootstrapQuery(NSDictionary<NSString *,NSString *> *fields,BOOL login) {
    if(![fields isKindOfClass:NSDictionary.class]||![fields[@"user"] isEqual:@"true"]||
       (login&&![fields[@"battle_status"] isEqual:@"true"]))return NO;
    for(id key in fields){
        if(![key isKindOfClass:NSString.class])return NO;
        if([@[@"user",@"cards",@"teams",@"battle_status"] containsObject:key]){
            if(![fields[key] isEqual:@"true"])return NO;
        }else if([key isEqual:@"user_card_updated_at"]){
            if(![fields[@"cards"] isEqual:@"true"]||!ODResourceUnsignedDecimal(fields[key]))return NO;
        }else if([key isEqual:@"timewarp"]){
            if(!ODResourceUnsignedDecimal(fields[key]))return NO;
        }else return NO;
    }
    return YES;
}

@implementation ODOriginalPlayerResourcesAdapter
- (instancetype)initWithProjector:(ODResourceResponseProjector *)projector contextCurrent:(ODResourceContextCurrent)current {
    if(!projector)return nil;
    return [self initWithProjectorProvider:^ODResourceResponseProjector *(void){return projector;} contextCurrent:current];
}
- (instancetype)initWithProjectorProvider:(ODOriginalPlayerResourcesProjectorProvider)provider contextCurrent:(ODResourceContextCurrent)current {
    return [self initWithProjectorProvider:provider contextCurrent:current masterContextCurrent:current];
}
- (instancetype)initWithProjectorProvider:(ODOriginalPlayerResourcesProjectorProvider)provider contextCurrent:(ODResourceContextCurrent)current masterContextCurrent:(ODResourceContextCurrent)masterCurrent {
    return [self initWithProjectorProvider:provider contextCurrent:current masterContextCurrent:masterCurrent requestDecoderProvider:nil];
}
- (instancetype)initWithProjectorProvider:(ODOriginalPlayerResourcesProjectorProvider)provider contextCurrent:(ODResourceContextCurrent)current masterContextCurrent:(ODResourceContextCurrent)masterCurrent requestDecoderProvider:(ODOriginalPlayerRequestDecoderProvider)decoderProvider {
    if(!provider||!current||!masterCurrent)return nil;
    if((self=[super init])){
        ODResourceContextCurrent live=[current copy];
        ODResourceContextCurrent masterLive=[masterCurrent copy];
        ODOriginalPlayerResourcesProjectorProvider issuedProjector=[provider copy];
        ODOriginalPlayerRequestDecoderProvider issuedDecoder=[decoderProvider copy];
        NSMutableArray<ODLocalTransportRoute *> *routes=[NSMutableArray array];
        for(NSString *path in @[@"/resources/login",@"/resources/home"]){
            BOOL login=[path isEqualToString:@"/resources/login"];
            ODLocalTransportScalarQueryValidator query=^BOOL(NSDictionary<NSString *,NSString *> *fields){
                return ODResourceBootstrapQuery(fields,login);
            };
            ODLocalTransportRoute *route=[[ODLocalTransportRoute alloc] initWithMethod:@"GET" path:path
                scalarQueryValidator:query handler:^(ODLocalTransportRequest *request,ODLocalTransportCompletion completion){
                    if(![request.method isEqual:@"GET"]||![request.path isEqual:path]||request.body.length||!query(request.queryFields)){
                        completion(nil,ODPlayerResourcesError(@"ORIGINAL_PLAYER_RESOURCES_REQUEST_UNSUPPORTED"));return;
                    }
                    dispatch_async(dispatch_get_main_queue(),^{
                        if(!request.isActive||!live()){
                            completion(nil,ODPlayerResourcesError(@"ORIGINAL_PLAYER_RESOURCES_CONTEXT_CHANGED"));return;
                        }
                        ODResourceResponseProjector *projector=issuedProjector();
                        if(!projector){completion(nil,ODPlayerResourcesError(@"ORIGINAL_PLAYER_RESOURCES_NOT_READY"));return;}
                        [projector projectNewProfilePlayer:^(id candidate,NSError *error){
                            if(!request.isActive||!live()||issuedProjector()!=projector){
                                completion(nil,ODPlayerResourcesError(@"ORIGINAL_PLAYER_RESOURCES_CONTEXT_CHANGED"));return;
                            }
                            NSDictionary *result=[candidate isKindOfClass:NSDictionary.class]?candidate:nil;
                            NSDictionary *body=[result[@"response"] isKindOfClass:NSDictionary.class]?result[@"response"]:nil;
                            if(error||!body||![result[@"kind"] isEqual:@"new-original-player-skip-intro-projection"]){
                                completion(nil,ODPlayerResourcesError(@"ORIGINAL_PLAYER_RESOURCES_NOT_READY"));return;
                            }
                            ODLocalTransportResponse *response=[ODLocalTransportResponse plainJSONResponseWithObject:body];
                            completion(response,response?nil:ODPlayerResourcesError(@"ORIGINAL_PLAYER_RESOURCES_ENCODING_FAILED"));
                        }];
                    });
                }];
            if(!route)return nil;
            [routes addObject:route];
        }
        /* Actual TeamsIndexAPI inherits method0 and initializes an empty
         * query; no JSON-parameter setter is proven on that fetch path.
         * Preserve the transport's default rejection of every query. */
        ODLocalTransportRoute *teams=[[ODLocalTransportRoute alloc] initWithMethod:@"GET" path:@"/teams"
            handler:^(ODLocalTransportRequest *request,ODLocalTransportCompletion completion){
                if(![request.method isEqual:@"GET"]||![request.path isEqual:@"/teams"]||request.body.length||request.queryFields.count){
                    completion(nil,ODPlayerResourcesError(@"ORIGINAL_TEAMS_REQUEST_UNSUPPORTED"));return;
                }
                dispatch_async(dispatch_get_main_queue(),^{
                    if(!request.isActive||!live()||!masterLive()){
                        completion(nil,ODPlayerResourcesError(@"ORIGINAL_TEAMS_CONTEXT_CHANGED"));return;
                    }
                    ODResourceResponseProjector *projector=issuedProjector();
                    if(!projector){completion(nil,ODPlayerResourcesError(@"ORIGINAL_TEAMS_NOT_READY"));return;}
                    [projector projectCurrentTeams:^(id candidate,NSError *error){
                        if(!request.isActive||!live()||!masterLive()||issuedProjector()!=projector){
                            completion(nil,ODPlayerResourcesError(@"ORIGINAL_TEAMS_CONTEXT_CHANGED"));return;
                        }
                        NSDictionary *result=[candidate isKindOfClass:NSDictionary.class]?candidate:nil;
                        NSDictionary *body=[result[@"response"] isKindOfClass:NSDictionary.class]?result[@"response"]:nil;
                        NSString *json=[result[@"body_json"] isKindOfClass:NSString.class]?result[@"body_json"]:nil;
                        if(error||!body||!json.length||![result[@"kind"] isEqual:@"own-player-team-projection"]){
                            completion(nil,ODPlayerResourcesError(@"ORIGINAL_TEAMS_NOT_READY"));return;
                        }
                        ODLocalTransportResponse *response=[ODLocalTransportResponse plainJSONResponseWithObject:body];
                        completion(response,response?nil:ODPlayerResourcesError(@"ORIGINAL_TEAMS_ENCODING_FAILED"));
                    }];
                });
            }];
        if(!teams)return nil;
        [routes addObject:teams];
        ODLocalTransportRoute *update=[[ODLocalTransportRoute alloc] initWithMethod:@"POST" path:@"/teams"
            handler:^(ODLocalTransportRequest *request,ODLocalTransportCompletion completion){
                if(![request.method isEqual:@"POST"]||![request.path isEqual:@"/teams"]||!request.body.length||request.queryFields.count){
                    completion(nil,ODPlayerResourcesError(@"ORIGINAL_TEAMS_POST_REQUEST_UNSUPPORTED"));return;
                }
                dispatch_async(dispatch_get_main_queue(),^{
                    if(!request.isActive||!live()||!masterLive()){
                        completion(nil,ODPlayerResourcesError(@"ORIGINAL_TEAMS_POST_CONTEXT_CHANGED"));return;
                    }
                    ODOriginalRequestDecoder *decoder=issuedDecoder?issuedDecoder():nil;
                    if(!decoder){completion(nil,ODPlayerResourcesError(@"ORIGINAL_REQUEST_DECODER_UNAVAILABLE"));return;}
                    NSError *decodeFailure=nil;
                    // The capability rejects until its own original-codec
                    // roundtrip succeeds and validates the exact wire frame.
                    // Never try Foundation JSON/base64 as a replacement codec.
                    NSDictionary *decoded=[decoder decodeOriginalPOSTBody:request.body error:&decodeFailure];
                    if(decodeFailure||![decoded isKindOfClass:NSDictionary.class]||!decoder.verifiedForCurrentEngine){
                        completion(nil,decodeFailure?:ODPlayerResourcesError(@"ORIGINAL_REQUEST_CODEC_NOT_VERIFIED"));return;
                    }
                    ODResourceResponseProjector *projector=issuedProjector();
                    if(!projector){completion(nil,ODPlayerResourcesError(@"ORIGINAL_TEAMS_POST_NOT_READY"));return;}
                    ODResourceContextCurrent mutationCurrent=^BOOL{
                        return request.isActive&&live()&&masterLive()&&issuedProjector()==projector&&
                            issuedDecoder&&issuedDecoder()==decoder&&decoder.verifiedForCurrentEngine;
                    };
                    if(!mutationCurrent()){
                        completion(nil,ODPlayerResourcesError(@"ORIGINAL_TEAMS_POST_CONTEXT_CHANGED"));return;
                    }
                    // This nonce identifies this admitted adapter invocation.
                    // It is not an invented original request ID or permanent
                    // body-digest cache. A later identical request is allowed.
                    NSString *command=[@"original-team:" stringByAppendingString:NSUUID.UUID.UUIDString];
                    [projector applyDecodedOriginalTeamUpdate:decoded command:command mutationCurrent:mutationCurrent
                        reply:^(id candidate,NSError *writeFailure){
                            if(writeFailure){completion(nil,writeFailure);return;}
                            if(!mutationCurrent()){
                                completion(nil,ODPlayerResourcesError(@"ORIGINAL_TEAMS_POST_CONTEXT_CHANGED_AFTER_COMMIT"));return;
                            }
                            NSDictionary *result=[candidate isKindOfClass:NSDictionary.class]?candidate:nil;
                            NSDictionary *body=[result[@"response"] isKindOfClass:NSDictionary.class]?result[@"response"]:nil;
                            NSString *json=[result[@"body_json"] isKindOfClass:NSString.class]?result[@"body_json"]:nil;
                            if(!body||!json.length||![result[@"kind"] isEqual:@"own-player-team-projection"]){
                                completion(nil,ODPlayerResourcesError(@"ORIGINAL_TEAMS_POST_COMMITTED_RESPONSE_NOT_READY"));return;
                            }
                            ODLocalTransportResponse *response=[ODLocalTransportResponse plainJSONResponseWithObject:body];
                            completion(response,response?nil:ODPlayerResourcesError(@"ORIGINAL_TEAMS_POST_ENCODING_FAILED"));
                        }];
                });
            }];
        if(!update)return nil;
        [routes addObject:update];
        _routes=[routes copy];
    }
    return self;
}
@end
