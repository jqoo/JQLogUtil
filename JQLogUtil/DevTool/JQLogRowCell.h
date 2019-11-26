//
//  JQLogLineCell.h
//  BFDevTools
//
//  Created by zhangjinquan on 2019/9/18.
//

#import <UIKit/UIKit.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

@interface JQLogRow : NSObject <NSCopying>

- (instancetype)initWithText:(NSString *)text;

@property (nonatomic, strong) NSMutableAttributedString *attr;
@property (nonatomic, assign) NSUInteger parseLocation;
@property (nonatomic, readonly) BOOL shouldStopParsing;
@property (nonatomic, assign) BOOL parsingFinished;
@property (nonatomic, assign) char logFlag;

@end

@interface JQLogRowCell : UITableViewCell

@property (nonatomic, strong) NSAttributedString *text;
@property (nonatomic, strong) JQLogRow *logRow;

- (void)setBgColor:(UIColor *)color;

+ (instancetype)cellWithTableView:(UITableView *)tableView;

@end
