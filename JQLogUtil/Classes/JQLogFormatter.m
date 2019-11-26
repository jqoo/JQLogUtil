//
//  JQLogFormatter.m
//  JQLogUtil
//
//  Created by zhangjinquan on 2019/11/26.
//

#import "JQLogFormatter.h"

static NSString *JQStringOfLogFlag(DDLogFlag flag) {
    switch (flag) {
        case DDLogFlagError:   return @"E";
        case DDLogFlagWarning: return @"W";
        case DDLogFlagInfo:    return @"I";
        case DDLogFlagDebug:   return @"D";
        case DDLogFlagVerbose: return @"V";
        default: break;
    }
    return @"";
}

@interface JQLogFormatter ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSString *appName;

@end

@implementation JQLogFormatter

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    }
    return _dateFormatter;
}

- (NSString *)appName {
    if (!_appName) {
        _appName = [NSProcessInfo processInfo].processName;
    }
    return _appName;
}

- (NSString * __nullable)formatLogMessage:(DDLogMessage *)logMessage {
    // time <module-type-level> appName[threadId:name] (filename:line func) > content
    NSMutableArray *comps = [NSMutableArray array];
    // time
    [comps addObject:[self.dateFormatter stringFromDate:logMessage->_timestamp]];
    // <module-type-level>
    [comps addObject:[NSString stringWithFormat:@"|JQLog:%@-%zd-%@|", logMessage->_tag, logMessage->_context, JQStringOfLogFlag(logMessage->_flag)]];
    
    if (_detailContext) {
        // appName[threadId:name]
        [comps addObject:[NSString stringWithFormat:@"%@[%@:%@]",
                          _showAppName ? self.appName:@"", logMessage->_threadID, [logMessage->_threadName length] == 0 ? logMessage->_queueLabel : logMessage->_threadName]];
        // (filename:line func)
        [comps addObject:[NSString stringWithFormat:@"(%@:%zu %@)",
                          [logMessage->_file lastPathComponent], logMessage->_line, logMessage->_function]];
    }
    else if (_showAppName) {
        [comps addObject:self.appName];
    }
    [comps addObject:@">"];
    [comps addObject:logMessage->_message];
    return [comps componentsJoinedByString:@" "];
}

@end
