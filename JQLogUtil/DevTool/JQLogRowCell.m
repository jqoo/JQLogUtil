//
//  JQLogLineCell.m
//  BFDevTools
//
//  Created by zhangjinquan on 2019/9/18.
//

#import "JQLogRowCell.h"

@interface JQLogRow ()

@property (nonatomic, assign) BOOL shouldStopParsing;

@end

@implementation JQLogRow

- (instancetype)initWithText:(NSString *)text {
    self = [super init];
    if (self) {
        self.attr = [[NSMutableAttributedString alloc] initWithString:text
                                                           attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}];
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    JQLogRow *row = [[JQLogRow allocWithZone:zone] init];
    row.attr = [self.attr mutableCopy];
    row.parseLocation = self.parseLocation;
    row.shouldStopParsing = self.shouldStopParsing;
    row.parsingFinished = self.parsingFinished;
    return row;
}

@end

@interface JQLogRowCell ()

@property (strong, nonatomic) UILabel *textView;

@end

@implementation JQLogRowCell

- (void)dealloc {
    self.logRow = nil;
}

- (void)setBgColor:(UIColor *)color {
    self.textView.backgroundColor = color;
}

+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    static NSString *ID = @"JQLogRowCell";
    JQLogRowCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil) {
        cell = [[JQLogRowCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    return cell;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    
    if (newSuperview == nil) {
        _logRow.shouldStopParsing = YES;
        [self setLogRow:nil];
    }
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textView = [[UILabel alloc] initWithFrame:self.contentView.bounds];
        //        self.textView.scrollEnabled = NO;
        self.textView.numberOfLines = 0;
        [self.contentView addSubview:self.textView];
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.contentView.opaque = NO;
        self.textView.autoresizingMask = ~0;
        self.textView.backgroundColor = [UIColor whiteColor];
        self.textView.opaque = NO;
    }
    return self;
}

//- (void)layoutSubviews {
//    [super layoutSubviews];
//
//    self.textView.frame = self.contentView.bounds;
//}

- (void)setLogRow:(JQLogRow *)logRow {
    if (_logRow == logRow) {
        return;
    }
    if (_logRow) {
        [_logRow removeObserver:self forKeyPath:@"parsingFinished"];
    }
    _logRow = logRow;
    if (_logRow) {
        [_logRow addObserver:self forKeyPath:@"parsingFinished" options:NSKeyValueObservingOptionNew context:NULL];
        self.textView.attributedText = [_logRow.attr copy];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    self.textView.attributedText = [_logRow.attr copy];
}

-(void)setText:(NSAttributedString *)text{
    _text = text;
    self.textView.attributedText = text;
}

@end
