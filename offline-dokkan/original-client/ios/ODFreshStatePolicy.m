#import "ODFreshStatePolicy.h"
#import <CoreFoundation/CoreFoundation.h>
#include <math.h>
#include <stdint.h>

static NSError *ODFreshError(NSString *code) {
    return [NSError errorWithDomain:@"OfflineDokkan.FreshState" code:1
        userInfo:@{NSLocalizedDescriptionKey:code}];
}
static BOOL ODJSONInteger(id value, long long *out) {
    if (![value isKindOfClass:NSNumber.class]) return NO;
    if (CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID()) return NO;
    double number = [(NSNumber *)value doubleValue];
    if (!isfinite(number) || number != trunc(number) || number > 9007199254740991.0 || number < -9007199254740991.0) return NO;
    *out = [(NSNumber *)value longLongValue];
    return YES;
}
static BOOL ODSentinelKey(NSString *key) {
    return [@[@"tutorial",@"is_finished",@"contents_lv",@"card_capacity",@"total_card_capacity",
        @"support_item_capacity",@"is_support_item_capacity_extended"] containsObject:key];
}
/* 0 clean, 1 pre-server sentinel, 2 not a usable policy object. */
static int ODScanPolicy(id value, NSInteger depth) {
    if (depth > 24) return 2;
    if ([value isKindOfClass:NSArray.class]) {
        for (id item in (NSArray *)value) {
            int nested = ODScanPolicy(item, depth + 1);
            if (nested) return nested;
        }
        return 0;
    }
    if (![value isKindOfClass:NSDictionary.class]) return 0;
    for (id key in (NSDictionary *)value) {
        if (![key isKindOfClass:NSString.class]) return 2;
        if (ODSentinelKey(key)) return 1;
        int nested = ODScanPolicy(((NSDictionary *)value)[key], depth + 1);
        if (nested) return nested;
    }
    return 0;
}

@implementation ODFreshStatePolicy
+ (NSDictionary *)evaluateSnapshot:(NSDictionary *)snapshot proposedSections:(NSDictionary *)proposed error:(NSError **)error {
    NSDictionary *source = [snapshot isKindOfClass:NSDictionary.class] ? snapshot[@"source_rank"] : nil;
    if (![source isKindOfClass:NSDictionary.class]) {
        if (error) *error = ODFreshError(@"SOURCE_RANK_REQUIRED");
        return nil;
    }
    long long rank = 0, experience = 0, staminaMax = 0, sourceRank = 0, sourceExp = 0, sourceAct = 0, friends = 0;
    if (!ODJSONInteger(snapshot[@"rank"], &rank) || !ODJSONInteger(snapshot[@"rank_experience"], &experience) ||
        !ODJSONInteger(snapshot[@"stamina_max"], &staminaMax) || !ODJSONInteger(source[@"rank"], &sourceRank) ||
        !ODJSONInteger(source[@"exp_total"], &sourceExp) || !ODJSONInteger(source[@"act_max"], &sourceAct) ||
        !ODJSONInteger(source[@"friends_capacity"], &friends)) {
        if (error) *error = ODFreshError(@"INVALID_FRESH_SNAPSHOT");
        return nil;
    }
    if (sourceAct < 1 || friends < 0) {
        if (error) *error = ODFreshError(@"SOURCE_RANK_REQUIRED");
        return nil;
    }
    if (sourceRank != rank || sourceExp != experience || sourceAct != staminaMax) {
        if (error) *error = ODFreshError(@"SOURCE_RANK_SCOPE_MISMATCH");
        return nil;
    }
    if (rank != 1 || experience != 0 || sourceExp != 0) {
        if (error) *error = ODFreshError(@"FRESH_RANK_NOT_ESTABLISHED");
        return nil;
    }
    id sections = @{};
    if (proposed) {
        int scan = [proposed isKindOfClass:NSDictionary.class] ? ODScanPolicy(proposed, 0) : 2;
        if (scan) {
            if (error) *error = ODFreshError(scan == 1 ? @"PRE_SERVER_SENTINEL_REJECTED" : @"INVALID_FRESH_POLICY");
            return nil;
        }
        NSData *data = [NSJSONSerialization dataWithJSONObject:proposed options:0 error:NULL];
        sections = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;
        if (![sections isKindOfClass:NSDictionary.class]) {
            if (error) *error = ODFreshError(@"INVALID_FRESH_POLICY");
            return nil;
        }
    }
    NSMutableDictionary *configured=[sections mutableCopy];
    NSMutableArray *unresolved=[@[@"tutorial.progress",@"tutorial.contents_lv",@"tutorial.is_finished",@"card_capacity",
        @"total_card_capacity",@"support_item_capacity",@"is_support_item_capacity_extended"] mutableCopy];
    NSMutableArray *admitted=[NSMutableArray array];
    id tutorial=snapshot[@"original_client_tutorial"];
    if(tutorial&&tutorial!=NSNull.null) {
        long long schema=0,progress=0;
        id finished=[tutorial isKindOfClass:NSDictionary.class]?tutorial[@"is_finished"]:nil;
        BOOL canonical=[tutorial isKindOfClass:NSDictionary.class]&&[(NSDictionary *)tutorial count]==4&&
            ODJSONInteger(tutorial[@"schema"],&schema)&&schema==1&&
            ODJSONInteger(tutorial[@"progress"],&progress)&&progress>=0&&progress<=INT32_MAX&&
            [finished isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)finished)==CFBooleanGetTypeID()&&
            (([tutorial[@"policy"] isEqual:@"original-tutorial-entry-v1"]&&![finished boolValue])||
             ([tutorial[@"policy"] isEqual:@"offline-new-player-skip-v1"]&&progress==0&&[finished boolValue]));
        id priorUser=configured[@"user"];
        if(!canonical||(priorUser&&![priorUser isKindOfClass:NSDictionary.class])) {
            if(error)*error=ODFreshError(canonical?@"INVALID_FRESH_POLICY":@"INVALID_CANONICAL_TUTORIAL");
            return nil;
        }
        NSMutableDictionary *user=priorUser?[priorUser mutableCopy]:[NSMutableDictionary dictionary];
        user[@"tutorial"]=@{@"progress":@(progress),@"is_finished":finished};configured[@"user"]=user;
        [admitted addObjectsFromArray:@[@"tutorial.progress",@"tutorial.is_finished"]];
        [unresolved removeObjectsInArray:admitted];
    }
    return @{
        @"schema": @1,
        @"kind": @"fresh-state-policy",
        @"sections": configured,
        @"admitted_source_facts": @[@"rank",@"exp_total",@"act_max",@"friends_capacity"],
        @"admitted_canonical_tutorial_fields": admitted,
        @"unresolved": unresolved,
        @"pre_server_sentinels_adopted": @NO,
        @"played_cache_values_adopted": @NO,
        @"starting_stats_invented": @NO,
        @"http_body_json": [NSNull null],
        @"http_route_admitted": @NO
    };
}
@end
