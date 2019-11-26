//
//  JQLogUtil.h
//  JQLogUtil
//
//  Created by zhangjinquan on 2019/11/26.
//

#import <Foundation/Foundation.h>

#ifdef LOG_LEVEL_DEF
#undef LOG_LEVEL_DEF
#endif

#define LOG_LEVEL_DEF jq_globalLogLevel

#import <CocoaLumberjack/CocoaLumberjack.h>

extern const DDLogLevel jq_globalLogLevel;

// 日志上下文标识
typedef NS_OPTIONS(NSUInteger, JQLogContext) {
    JQLogContextNone  = 0 // 默认context
};

typedef NS_OPTIONS(NSUInteger, JQLoggerType) {
    JQLoggerTypeASL  = 1 << 0, // 苹果的控制台Console.app
    JQLoggerTypeTTY  = 1 << 1, // Xcode控制台
    JQLoggerTypeFile = 1 << 2, // 文件
    JQLoggerTypeAll  = ( JQLoggerTypeASL|JQLoggerTypeTTY|JQLoggerTypeFile )
};

#define JQ_LOG_MACRO_V(isAsynchronous, lvl, flg, ctx, atag, fnct, frmt, args) \
    [DDLog log : isAsynchronous \
         level : lvl            \
          flag : flg            \
       context : ctx            \
          file : __FILE__       \
      function : fnct           \
          line : __LINE__       \
           tag : atag           \
        format : (frmt)         \
          args : args]

#define JQ_LOG_MAYBE_V(async, lvl, flg, ctx, tag, fnct, frmt, args) \
    do { if(lvl & flg) JQ_LOG_MACRO_V(async, lvl, flg, ctx, tag, fnct, frmt, args); } while(0)

#define JQLogWriteV(flg, ctx, tag, frmt, args) \
    JQ_LOG_MAYBE_V(((flg) != DDLogFlagError && (LOG_ASYNC_ENABLED)), LOG_LEVEL_DEF, flg, ctx, tag, __PRETTY_FUNCTION__, frmt, args)

#define JQLogWrite(flg, ctx, tag, frmt, ...) \
    LOG_MAYBE(((flg) != DDLogFlagError && (LOG_ASYNC_ENABLED)), LOG_LEVEL_DEF, flg, ctx, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define JQLogError2(ctx, tag, frmt, ...)   JQLogWrite(DDLogFlagError,   ctx, tag, frmt, ##__VA_ARGS__)
#define JQLogWarn2(ctx, tag, frmt, ...)    JQLogWrite(DDLogFlagWarning, ctx, tag, frmt, ##__VA_ARGS__)
#define JQLogInfo2(ctx, tag, frmt, ...)    JQLogWrite(DDLogFlagInfo,    ctx, tag, frmt, ##__VA_ARGS__)
#define JQLogDebug2(ctx, tag, frmt, ...)   JQLogWrite(DDLogFlagDebug,   ctx, tag, frmt, ##__VA_ARGS__)
#define JQLogVerbose2(ctx, tag, frmt, ...) JQLogWrite(DDLogFlagVerbose, ctx, tag, frmt, ##__VA_ARGS__)

#define JQLogError1(tag, frmt, ...)        JQLogWrite(DDLogFlagError,   JQLogContextNone, tag, frmt, ##__VA_ARGS__)
#define JQLogWarn1(tag, frmt, ...)         JQLogWrite(DDLogFlagWarning, JQLogContextNone, tag, frmt, ##__VA_ARGS__)
#define JQLogInfo1(tag, frmt, ...)         JQLogWrite(DDLogFlagInfo,    JQLogContextNone, tag, frmt, ##__VA_ARGS__)
#define JQLogDebug1(tag, frmt, ...)        JQLogWrite(DDLogFlagDebug,   JQLogContextNone, tag, frmt, ##__VA_ARGS__)
#define JQLogVerbose1(tag, frmt, ...)      JQLogWrite(DDLogFlagVerbose, JQLogContextNone, tag, frmt, ##__VA_ARGS__)

#define JQLogError(frmt, ...)              JQLogWrite(DDLogFlagError,   JQLogContextNone, null, frmt, ##__VA_ARGS__)
#define JQLogWarn(frmt, ...)               JQLogWrite(DDLogFlagWarning, JQLogContextNone, null, frmt, ##__VA_ARGS__)
#define JQLogInfo(frmt, ...)               JQLogWrite(DDLogFlagInfo,    JQLogContextNone, null, frmt, ##__VA_ARGS__)
#define JQLogDebug(frmt, ...)              JQLogWrite(DDLogFlagDebug,   JQLogContextNone, null, frmt, ##__VA_ARGS__)
#define JQLogVerbose(frmt, ...)            JQLogWrite(DDLogFlagVerbose, JQLogContextNone, null, frmt, ##__VA_ARGS__)

@interface JQLogUtil : NSObject

/**
 * Setup logger
 * config:
 {
     whitelist: {
         contexts: [1,2,3],
         modules: ['a', 'b']
     },
     blacklist: {
         contexts: [1,2,3],
         modules: ['a', 'b']
     },
     level: 1 // 默认是all
 }
 */
+ (void)setup:(JQLoggerType)type filterConfig:(NSDictionary *)config;
+ (void)setup:(JQLoggerType)type;

+ (void)addCustomLogger:(id <DDLogger>)logger;
+ (void)addCustomLogger:(id <DDLogger>)logger withLevel:(DDLogLevel)level;
+ (void)addCustomLogger:(id <DDLogger>)logger formatter:(id<DDLogFormatter>)formatter withLevel:(DDLogLevel)level;

+ (NSString *)logFileDirectory;

@end
