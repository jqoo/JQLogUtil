//
//  JQLogFilter.h
//  JQLogUtil
//
//  Created by zhangjinquan on 2019/11/26.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

/*
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
     level: 1
  }
 */

@interface JQLogFilter : NSObject <DDLogFormatter>

- (instancetype)initWithConfig:(NSDictionary *)config;

@end
