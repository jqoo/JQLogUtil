//
//  JQLogFormatter.h
//  JQLogUtil
//
//  Created by zhangjinquan on 2019/11/26.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

@interface JQLogFormatter : NSObject <DDLogFormatter>

@property (nonatomic, assign) BOOL showAppName;
@property (nonatomic, assign) BOOL detailContext;

@end
