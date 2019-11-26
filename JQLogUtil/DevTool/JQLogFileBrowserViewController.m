//
//  JQLogFileBrowserViewController.m
//  BFDevTools
//
//  Created by zhangjinquan on 2019/9/18.
//

#import "JQLogFileBrowserViewController.h"
#import "JQLogRowCell.h"
#import "QMUIKit.h"

#define kHistoryMaxCount 10
#define kHistoryKey @"dev_jqlog_search_key"

typedef NS_ENUM(NSInteger, FiltrateState) {
    FiltrateTextMatch,
    FiltrateRegexMatch
};

@interface JQLogRowDetailController : UIViewController

@property (nonatomic, copy) JQLogRow *textItem;

@end

@implementation JQLogRowDetailController
{
    UITextView *_textView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Log Detail";
    
//    WeakSelf;
//    self.navigationItem.rightBarButtonItem = [UIBarButtonItem itemWithTitle:@"Copy" style:UIBarButtonItemStylePlain block:^(UIBarButtonItem * _Nonnull item) {
//        StrongSelf;
//        [UIPasteboard generalPasteboard].string = strongSelf->_textView.text;
//    }];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Copy" style:UIBarButtonItemStylePlain target:self action:@selector(actionCopy)];
    
    _textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_textView];
    _textView.autoresizingMask = ~0;
    _textView.editable = NO;
    _textView.attributedText = self.textItem.attr;
}

- (void)actionCopy {
    [UIPasteboard generalPasteboard].string = _textView.text;
}

@end

@interface JQLogFileBrowserViewController () <UISearchBarDelegate>
{
    UITextView      *_textView;
    
    NSMutableArray  *_detailArray;
    NSMutableArray  *_premiryArray;
    NSMapTable<NSString *, NSNumber *> *_heightMap;
    NSString        *_searchingText;
    CGFloat          _viewWidth;
    
    NSRegularExpression *_displayRegex;
    NSString *_displayPattern;
    UIButton *_addBtn;
    UIView *_origionLeftView;
}

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, assign) FiltrateState filtrateState;

@end

@implementation JQLogFileBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.separatorColor = [UIColor greenColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    
    self.title = [self.filepath lastPathComponent];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 160, 44)];
    titleLabel.numberOfLines = 0;
    titleLabel.font = [UIFont systemFontOfSize:12];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.text = self.title;
    self.navigationItem.titleView = titleLabel;
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = @"输入关键字...";
    self.searchBar.showsBookmarkButton = YES;
    self.searchBar.delegate = self;
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.keyboardType = UIKeyboardTypeASCIICapable;
    [self.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchBar;

    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:@[@"文本匹配",@"正则匹配"]];
    NSDictionary *dict = @{ UITextAttributeFont:[UIFont systemFontOfSize:11] };
    [segment setTitleTextAttributes:dict forState:UIControlStateNormal];
    CGRect r = CGRectMake(self.view.frame.size.width - 120, 22, 120, 35);
    r = CGRectInset(r, 6, 6);
    segment.frame = r;
    [segment addTarget:self action:@selector(filtrateItemClick:) forControlEvents:UIControlEventValueChanged];
    segment.selectedSegmentIndex = self.filtrateState;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:segment];
    
    _origionLeftView = self.searchBar.qmui_textField.leftView;
    _addBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    [_addBtn addTarget:self action:@selector(addHistory) forControlEvents:UIControlEventTouchUpInside];
    [_addBtn setTitle:@"➕" forState:UIControlStateNormal];
    [_addBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

    _viewWidth = self.view.frame.size.width;
    _detailArray = [[NSMutableArray alloc] initWithCapacity:0];
    _premiryArray = [[NSMutableArray alloc] initWithCapacity:0];
    _heightMap = [NSMapTable<NSString *, NSNumber *> weakToStrongObjectsMapTable];
    
    [self loadLogfile];
}

- (void)addHistory {
    [self addHistoryKeyword:self.searchBar.text completion:^{
        [QMUITips showInfo:@"收藏完成"];
    }];
}

- (void)addHistoryKeyword:(NSString *)keyword completion:(dispatch_block_t)completion {
    if ([keyword length] == 0) {
        return;
    }
    NSMutableArray *arr = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:kHistoryKey]];
    [arr removeObject:keyword];
    [arr addObject:keyword];
    if ([arr count] > kHistoryMaxCount) {
        [arr removeObjectsInRange:NSMakeRange(0, kHistoryMaxCount - [arr count])];
    }
    [[NSUserDefaults standardUserDefaults] setObject:arr forKey:kHistoryKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)filtrateItemClick:(UISegmentedControl *)sengment{
    self.filtrateState = sengment.selectedSegmentIndex;
    [self doSearch:self.searchBar.text];
}

- (void)loadLogfile {
    __weak __auto_type weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (weakSelf == nil) {
            return;
        }
        NSArray *result = [weakSelf loadLogRows];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf loadTextViewWithArray:result];
        });
    });
}

-(NSArray *)loadLogRows {
    NSMutableArray *mArr = [[NSMutableArray alloc] init];
    NSString *fileString = [NSString stringWithContentsOfFile:_filepath encoding:NSUTF8StringEncoding error:NULL];
    
    NSString *regexString = @"\\d{4}[-/]\\d{2}[-/]\\d{2} \\d{2}:\\d{2}:\\d{2}[:\\.]\\d{3} \\|JQLog:[^-]*-\\d+-([A-Z])\\| .+ > ";
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:regexString options:0 error:NULL];
    NSRange range = NSMakeRange(0, [fileString length]);
//    NSRange preRange = [regex rangeOfFirstMatchInString:fileString options:0 range:range];
    NSTextCheckingResult *result = [regex firstMatchInString:fileString options:0 range:range];
    NSRange preRange = result.range;
    
    while (preRange.location != NSNotFound) {
        char logFlag = 0;
        if ([result numberOfRanges] > 1) {
            logFlag = [[fileString substringWithRange:[result rangeAtIndex:1]] UTF8String][0];
        }
        
        NSRange remainRange = NSMakeRange(preRange.location + preRange.length, [fileString length] - preRange.location - preRange.length);
        result = [regex firstMatchInString:fileString options:0 range:remainRange];
        NSRange nextRange = result ? result.range : NSMakeRange(NSNotFound, 0);
        
        NSString *text = nil;
        NSInteger tail = nextRange.location != NSNotFound ? nextRange.location : [fileString length];
        text = [NSString stringWithFormat:@"%@\n%@",
                [fileString substringWithRange:preRange],
                [fileString substringWithRange:NSMakeRange(NSMaxRange(preRange), tail - NSMaxRange(preRange))]];
        if (text) {
            JQLogRow *item = [[JQLogRow alloc] initWithText:text];
            item.logFlag = logFlag;
            [mArr addObject:item];
            
            CGFloat height = [self calculateTextHeightWithWidth:_viewWidth fileContents:[item.attr string]] + 6;
            [_heightMap setObject:@(height) forKey:[item.attr string]];
        }
        preRange = nextRange;
    }
    return mArr;
}

-(CGFloat)calculateTextHeightWithWidth:(CGFloat)width fileContents:(NSString *)text{
    if (text.length == 0) {
        return 0;
    }
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    
    CGRect frame = [text boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                      options:NSStringDrawingUsesLineFragmentOrigin
                                   attributes:@{
                                                NSFontAttributeName:[UIFont systemFontOfSize:14],
                                                NSParagraphStyleAttributeName:paragraph
                                                }
                                      context:nil];
    if (frame.size.height > _viewWidth) {
        return _viewWidth;
    }
    return frame.size.height;
}

-(void)loadTextViewWithArray:(NSArray*)arr {
    NSArray *tempArray = [[arr reverseObjectEnumerator] allObjects];
    [_detailArray setArray:tempArray];
    [_premiryArray setArray:tempArray];
    //刷新数组
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _detailArray.count;
}

- (UIColor *)bgColorForLogFlag:(int)logFlag {
    switch (logFlag) {
        case 'V': return [UIColor whiteColor];
        case 'D': return [UIColor lightGrayColor];
        case 'I': return [UIColor colorWithRed:0.8 green:0.9 blue:0.9 alpha:0.5];
        case 'W': return [UIColor yellowColor];
        case 'E': return [UIColor redColor];
        default:
            break;
    }
    return [UIColor whiteColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JQLogRowCell *cell = [JQLogRowCell cellWithTableView:tableView];
    JQLogRow *item = _detailArray[indexPath.row];
    cell.logRow = item;
    [cell setBgColor:[self bgColorForLogFlag:item.logFlag]];
    
    if ([_displayPattern length] > 0 && !item.parsingFinished) {
        NSRegularExpression *regex = _displayRegex;
        NSString *pattern = _displayPattern;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSInteger len = [item.attr.string length];
            NSRange range = NSMakeRange(item.parseLocation, len - item.parseLocation);
            
            if (regex) {
                while (range.length && !item.shouldStopParsing) {
                    NSTextCheckingResult *result = [regex firstMatchInString:item.attr.string options:0 range:range];
                    if (result && result.range.location != NSNotFound) {
                        [self decorateText:item.attr inRange:result.range];
                        range.location = NSMaxRange(result.range);
                        range.length = len - range.location;
                        item.parseLocation = range.location;
                    }
                    else {
                        range.location = NSNotFound;
                        range.length = 0;
                    }
                }
            }
            else {
                while (range.length && !item.shouldStopParsing) {
                    NSRange r = [item.attr.string rangeOfString:pattern options:NSCaseInsensitiveSearch range:range];
                    
                    if (r.location != NSNotFound) {
                        [self decorateText:item.attr inRange:r];
                        range.location = NSMaxRange(r);
                        range.length = len - range.location;
                        item.parseLocation = range.location;
                    }
                    else {
                        range.location = NSNotFound;
                        range.length = 0;
                    }
                }
            }
            if (range.length == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    item.parsingFinished = YES;
                });
            }
        });
    }
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.searchBar endEditing:YES];
}

- (void)decorateText:(NSMutableAttributedString *)attrString inRange:(NSRange)range {
    [attrString addAttribute:NSFontAttributeName value:[UIFont italicSystemFontOfSize:14] range:range];
    [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
    [attrString addAttribute:NSUnderlineStyleAttributeName value:@1 range:range];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    JQLogRow *item = _detailArray[indexPath.row];
    NSNumber *num = [_heightMap objectForKey:item.attr.string];
    return [num doubleValue];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    JQLogRowDetailController *controller = [[JQLogRowDetailController alloc] init];
    controller.textItem = _detailArray[indexPath.row];
    controller.title = _displayPattern;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void) doSearch:(NSString *) st {
    //    [_dataArray removeAllObjects];
    _searchingText = [st copy];
    //    RCTrace(@"_searchingText : %@", _searchingText);
    //    RCTrace(@"x> _searchingText:%llX", (long long)_searchingText);
    
    //    RCTrace(@"doSearch");
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scheduleSearchTask) object:nil];
    [self performSelector:@selector(scheduleSearchTask) withObject:nil afterDelay:0.5];
}

- (void)scheduleSearchTask {
    // RCTrace(@"scheduleSearchTask");
    
    __weak typeof(self) weakSelf = self;
    
    NSString * searchText = _searchingText;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        if (strongSelf != nil) {
            NSRegularExpression *regex = nil;
            NSArray *arr = [strongSelf searchText:searchText regex:&regex];
            
            if (arr) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (searchText != _searchingText) {
                        //                        RCTrace(@"不刷新表格");
                        return ;
                    } else{
                        _displayPattern = searchText;
                        _displayRegex = regex;
                        [_detailArray setArray:arr];
                        //                        RCTrace(@"reload data");
                        [strongSelf.tableView reloadData];
                    }
                });
            }
        }
    });
}

- (NSArray *)searchText:(NSString *)searchText regex:(NSRegularExpression **)regexp {
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    if (searchText.length > 0) {
        if (self.filtrateState == FiltrateTextMatch) {
            for (JQLogRow *item in _premiryArray) {
                if (searchText != _searchingText) {
                    //                    RCTrace(@"线程提前结束了");
                    return nil;
                }
                if ([item.attr.string rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    [dataArray addObject:[item copy]];
                }
            }
        }
        else if(self.filtrateState == FiltrateRegexMatch){
            NSError *error;
            NSRegularExpression *regex;
            regex = [[NSRegularExpression alloc] initWithPattern:searchText options:NSRegularExpressionCaseInsensitive error:&error];
            if (error) {
                return nil;
            }
            
            for (JQLogRow *item in _premiryArray) {
                if (searchText != _searchingText) {
                    // RCTrace(@"线程提前结束了");
                    return nil;
                }
                NSTextCheckingResult *result = [regex firstMatchInString:item.attr.string options:0 range:NSMakeRange(0, item.attr.string.length)];
                if (result && result.range.location != NSNotFound) {
                    [dataArray addObject:[item copy]];
                }
            }
            *regexp = regex;
        }
        
    } else{
        return _premiryArray;
    }
    return dataArray;
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self doSearch:searchText];
    if ([searchText length] == 0) {
        self.searchBar.qmui_textField.leftView = _origionLeftView;
    }
    else {
        self.searchBar.qmui_textField.leftView = _addBtn;
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    self.filtrateState = selectedScope;
    [self doSearch:self.searchBar.text];
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
    NSArray *obj = [[NSUserDefaults standardUserDefaults] arrayForKey:kHistoryKey];
    [self showHistoryList:obj];
}

- (void)showHistoryList:(NSArray *)list {
    QMUIPopupMenuView *menu = [[QMUIPopupMenuView alloc] init];
    menu.minimumWidth = 100;
    menu.automaticallyHidesWhenUserTap = YES;
    menu.shouldShowItemSeparator = YES;
    menu.preferLayoutDirection = QMUIPopupContainerViewLayoutDirectionBelow;
    NSMutableArray *items = [NSMutableArray array];
    
    __weak __auto_type weakSelf = self;
    for (NSString *keyword in list) {
        [items addObject:[self itemWithTitle:keyword handler:^{
            weakSelf.searchBar.text = keyword;
            [weakSelf searchBar:weakSelf.searchBar textDidChange:keyword];
            [weakSelf addHistoryKeyword:keyword completion:nil];
        }]];
    }
    [items addObject:[self itemWithTitle:@"x清空历史x" handler:^{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kHistoryKey];
    }]];

    menu.items = items;
    menu.itemHeight = 30;
    menu.sourceView = self.searchBar.qmui_textField.rightView;
    [menu showWithAnimated:NO];
}

- (QMUIPopupMenuBaseItem *)itemWithTitle:(NSString *)title handler:(dispatch_block_t)handler {
    QMUIPopupMenuButtonItem *item = [QMUIPopupMenuButtonItem itemWithImage:nil title:title handler:^(QMUIPopupMenuButtonItem *aItem) {
        [aItem.menuView hideWithAnimated:NO];
        !handler ?: handler();
    }];
    return item;
}

@end
