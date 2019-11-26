//
//  JQLogFilter.m
//  JQLogUtil
//
//  Created by zhangjinquan on 2019/11/26.
//

#import "JQLogFilter.h"

@implementation JQLogFilter {
    NSIndexSet *_contextWhitelist;
    NSIndexSet *_contextBlacklist;
    NSSet *_moduleWhitelist;
    NSSet *_moduleBlacklist;
    DDLogLevel _acceptLevel;
}

static NSIndexSet *indexSetFromArray(NSArray *arr) {
    NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
    [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [set addIndex:[obj integerValue]];
    }];
    return set;
}

- (instancetype)initWithConfig:(NSDictionary *)config {
    self = [super init];
    if (self) {
        _acceptLevel = DDLogLevelAll;
        
        if (config[@"level"]) {
            _acceptLevel = [config[@"level"] integerValue];
        }
        NSDictionary *whitelist = config[@"whitelist"];
        if (whitelist) {
            if ([whitelist[@"contexts"] count] > 0) {
                _contextWhitelist = indexSetFromArray(whitelist[@"contexts"]);
            }
            if ([whitelist[@"modules"] count] > 0) {
                _moduleWhitelist = [NSSet setWithArray:whitelist[@"modules"]];
            }
        }
        NSDictionary *blacklist = config[@"blacklist"];
        if (blacklist) {
            if ([blacklist[@"contexts"] count] > 0) {
                _contextBlacklist = indexSetFromArray(blacklist[@"contexts"]);
            }
            if ([blacklist[@"modules"] count] > 0) {
                _moduleBlacklist = [NSSet setWithArray:blacklist[@"modules"]];
            }
        }
    }
    return self;
}

- (NSString * __nullable)formatLogMessage:(DDLogMessage *)logMessage {
    BOOL accept = (_acceptLevel & logMessage->_flag) != 0;
    accept = accept && (!_contextBlacklist || ![_contextBlacklist containsIndex:logMessage->_context]);
    accept = accept && (!_moduleBlacklist || ![_moduleBlacklist containsObject:logMessage->_tag]);
    accept = accept && (!_contextWhitelist || [_contextWhitelist containsIndex:logMessage->_context]);
    accept = accept && (!_moduleWhitelist || [_moduleWhitelist containsObject:logMessage->_tag]);
    return accept ? logMessage->_message : nil;
}

@end
