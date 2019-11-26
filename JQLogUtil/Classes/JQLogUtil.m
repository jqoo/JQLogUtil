//
//  JQLogUtil.m
//  JQLogUtil
//
//  Created by zhangjinquan on 2019/11/26.
//

#import "JQLogUtil.h"
#import "JQLogFormatter.h"
#import "JQLogFilter.h"

#ifdef DEBUG
const DDLogLevel jq_globalLogLevel = DDLogLevelVerbose;
#else
const DDLogLevel jq_globalLogLevel = DDLogLevelInfo;
#endif

@interface JQPrivateFileLogger : DDFileLogger
@end

@implementation JQPrivateFileLogger

- (NSString *)loggerName {
    return @"com.jqoo.log-util.fileLogger";
}

@end

@implementation JQLogUtil

static JQLogFilter *_globalLogFilter;

+ (void)setup:(JQLoggerType)type {
    [self setup:type filterConfig:nil];
}

+ (void)setup:(JQLoggerType)type filterConfig:(NSDictionary *)config
{
    if (config) {
        _globalLogFilter = [[JQLogFilter alloc] initWithConfig:config];
    }
    
    if (type & JQLoggerTypeASL) {
        if (@available(iOS 10.0, *)) {
            [self addCustomLogger:[DDOSLogger sharedInstance]];
        }
        else {
            [self addCustomLogger:[DDASLLogger sharedInstance]];
        }
    }
    if (type & JQLoggerTypeTTY) {
        [self addCustomLogger:[DDTTYLogger sharedInstance] formatter:[JQLogFormatter new]];
    }
    if (type & JQLoggerTypeFile) {
        DDLogFileManagerDefault *fileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:[self logFileDirectory]];
        DDFileLogger *fileLogger = [[JQPrivateFileLogger alloc] initWithLogFileManager:fileManager];
        fileLogger.maximumFileSize = 2 * 1024 * 1024; // Default 2M
        
        JQLogFormatter *formatter = [JQLogFormatter new];
        formatter.detailContext = YES;
        
        [self addCustomLogger:fileLogger formatter:formatter];
    }
}

+ (NSString *)logFileDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *docPath = [paths firstObject];
    return [docPath stringByAppendingPathComponent:@"log"];
}

+ (void)addCustomLogger:(id <DDLogger>)logger {
    [self addCustomLogger:logger withLevel:DDLogLevelAll];
}

+ (void)addCustomLogger:(id <DDLogger>)logger withLevel:(DDLogLevel)level {
    [self addCustomLogger:logger formatter:nil withLevel:level];
}

+ (void)addCustomLogger:(id <DDLogger>)logger formatter:(id<DDLogFormatter>)formatter {
    [self addCustomLogger:logger formatter:formatter withLevel:DDLogLevelAll];
}

static id<DDLogFormatter> combineLogFormatters(id<DDLogFormatter> first, id<DDLogFormatter> second) {
    if (!first && !second) {
        return nil;
    }
    if (!(first && second)) {
        return first ?: second;
    }
    DDMultiFormatter *multi = [[DDMultiFormatter alloc] init];
    [multi addFormatter:first];
    [multi addFormatter:second];
    return multi;
}

+ (void)addCustomLogger:(id <DDLogger>)logger formatter:(id<DDLogFormatter>)formatter withLevel:(DDLogLevel)level {
    logger.logFormatter = combineLogFormatters(_globalLogFilter, formatter);
    [DDLog addLogger:logger withLevel:level];
}

@end
