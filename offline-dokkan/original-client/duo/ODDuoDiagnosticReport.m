#import "ODDuoDiagnosticReport.h"
#import <CoreFoundation/CoreFoundation.h>
#include <math.h>
#ifndef OD_BUILD_SOURCE_SHA
#define OD_BUILD_SOURCE_SHA "unavailable"
#endif

static NSDictionary *ODReportObject(id value) {
    return [value isKindOfClass:NSDictionary.class]?value:@{};
}
static void ODCopyReportFlags(NSDictionary *source, NSMutableDictionary *target, NSArray<NSString *> *keys) {
    for(NSString *key in keys){
        id value=source[key];
        if([value isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)value)==CFBooleanGetTypeID())
            target[key]=value;
    }
}
NSDictionary *ODDuoShareableDiagnosticReport(NSDictionary *report) {
    NSDictionary *source=ODReportObject(report),*host=ODReportObject(source[@"host"]);
    NSMutableDictionary *result=[@{@"schema":@1,@"application":@"Offline Dokkan + Unit Creator",
        @"classification":@"Diagnostic",@"reportAvailable":@(source.count>0),
        @"exportEstablishesGameplayVerification":@NO,@"sourceCommit":@OD_BUILD_SOURCE_SHA} mutableCopy];
    NSMutableDictionary *factory=[NSMutableDictionary dictionary],*native=[NSMutableDictionary dictionary];
    ODCopyReportFlags(source,factory,@[@"sameCanonicalCoreCaptured",@"canonicalPlayerAdmitted",
        @"sameCoreCreatorServicesIssued",@"scopedPlayerProjectorIssued",@"scopedPracticePhaseProviderIssued",
        @"knownIntegratedRelaunch",@"nativeMasterAccepted",@"actualOfflineLoginVerified",
        @"actualHomeVerified",@"actualBattleAndSaveVerified",@"canonicalPracticeNativeFinishPersisted"]);
    ODCopyReportFlags(host,native,@[@"bootstrapInstalled",@"nativeEnvironmentPrepared",
        @"localFoundationTransportInstalled",@"preparedEngineLoaded",@"nativeOriginArmed",
        @"originalRendererObserved",@"boundCreatorAttached",@"originalGameDataAdmitted",
        @"originalPracticeCapabilityResolved",@"originalPracticeParametersConfigured",@"originalPracticeRunning",
        @"originalPracticeFinishSaveRetryAvailable",
        @"originalRequestDecoderResolved",@"originalRequestDecoderVerified",@"creatorServicesPending",
        @"deferredCanonicalPlayerPrepared",@"creatorServicesBound",@"offlineAuthHandlersConfigured",
        @"offlineAuthOwnerInvalidated",@"offlineAuthHttpRouteAdmitted"]);
    // Only exact authored stage literals; never forward an NSError description.
    NSArray *stages=@[@"preparing-native-inputs",@"canonical-player-preparation-failed",
        @"canonical-player-context-changed",@"canonical-player-admission-missing",@"issuing-same-core-services",
        @"canonical-reference-unavailable",@"canonical-core-unavailable",@"native-resource-routes-unavailable",
        @"native-host-configuration-unavailable",@"opaque-source-candidate-preparation-failed",
        @"deferred-player-configuration-unavailable",@"offline-auth-route-configuration-unavailable",
        @"native-startup-inputs-unavailable",@"factory-precondition-failed",
        @"same-core-creator-services-unavailable",@"canonical-player-projector-unavailable",
        @"same-core-service-binding-failed",@"original-client-auth-and-profile-ready",
        @"waiting-for-main-loop-player-admission"];
    id stage=source[@"factoryStage"];
    factory[@"stage"]=[stage isKindOfClass:NSString.class]&&[stages containsObject:stage]?stage:@"unlisted-or-unavailable";
    NSArray *practiceStates=@[@"not-prepared",@"preparing-session",@"prepared",@"saving-native-finish",
        @"session-preparation-unavailable",@"native-finish-save-unavailable",@"native-finish-observed"];
    id practice=source[@"canonicalPracticeSessionState"];
    factory[@"practiceSessionState"]=[practice isKindOfClass:NSString.class]&&[practiceStates containsObject:practice]?practice:@"unlisted-or-unavailable";
    NSArray *codecStates=@[@"unavailable",@"ORIGINAL_REQUEST_CODEC_NATIVE_SELF_CHECK_REQUIRED",
        @"ORIGINAL_REQUEST_CODEC_ENGINE_NOT_CURRENT",@"ORIGINAL_REQUEST_CODEC_STRING_ABI_REJECTED",
        @"ORIGINAL_REQUEST_CODEC_NATIVE_SELF_CHECK_FAILED",@"ORIGINAL_REQUEST_CODEC_READY_FOR_CURRENT_ENGINE"];
    id codec=host[@"originalRequestDecoderState"];
    native[@"requestDecoderState"]=[codec isKindOfClass:NSString.class]&&[codecStates containsObject:codec]?codec:@"unlisted-or-unavailable";
    id count=host[@"registeredRouteCount"];
    if([count isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)count)!=CFBooleanGetTypeID()){
        double number=[count doubleValue];
        if(isfinite(number)&&number>=0&&number<=128&&number==trunc(number))native[@"registeredRouteCount"]=@((NSUInteger)number);
    }
    // A second exact vocabulary check before sharing the transport's already
    // sanitized observations. Never export a request URL, query, ID or body.
    NSArray *paths=@[@"/auth/nonce",@"/auth/sign_in",@"/resources/login",@"/resources/home",
        @"/user/mydata",@"/user_areas",@"/user_cards/",@"/cards",@"/teams",@"/events",@"/quests",
        @"/sugoroku_maps/start",@"/sugoroku_maps/finish",@"/missions",@"/missions/put_forward",
        @"/potentials",@"/potentials/release",@"/equip",@"/dragonball_sets",@"/db_stories",
        @"/genkai_battles",@"/joint_campaigns",@"/cooperation_campaigns",@"/announcements",
        @"/briefing",@"/support_leaders",@"/client_assets",@"/ondemand_assets",@"/assets/database",
        @"/sd/battle",@"/sd/characters",@"/sd/packs",@"/unrelease",@"/item_reverse_resolutions",
        @"/iap_rails",@"/client_assets/database",@"/item_reverse_resolutions/achievements",
        @"/iap_rails/googleplay_products",@"/quests/{id}/sugoroku_maps/start",
        @"/quests/{id}/sugoroku_maps/finish",@"/quests/{id}/sugoroku_maps/continue_info",
        @"/quests/{id}/sugoroku_maps/continue",@"/quests/{id}/briefing",@"/quests/{id}/supporters",
        @"/user_cards/{id}/potentials",@"/user_cards/{id}/potentials/release",
        @"/user_cards/{id}/potentials/{id}/unrelease",@"/cards/{id}/equip"];
    id observations=host[@"unsupportedFoundationRequests"];
    NSMutableArray *unsupported=[NSMutableArray array];
    if([observations isKindOfClass:NSArray.class]){
        NSUInteger limit=MIN((NSUInteger)64,[observations count]);
        for(NSUInteger index=0;index<limit;index++){
            NSDictionary *row=ODReportObject(observations[index]);id path=row[@"path"],method=row[@"method"];
            if([path isKindOfClass:NSString.class]&&[paths containsObject:path]&&
               [method isKindOfClass:NSString.class]&&[@[@"GET",@"POST",@"PUT",@"DELETE",@"PATCH",@"HEAD"] containsObject:method]){
                NSDictionary *safe=@{@"method":method,@"path":path};
                if(![unsupported containsObject:safe])[unsupported addObject:safe];
            }
        }
    }
    native[@"unsupportedRoutes"]=unsupported;
    result[@"factory"]=factory;result[@"nativeClient"]=native;
    return [result copy];
}
