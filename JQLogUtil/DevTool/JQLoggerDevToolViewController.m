//
//  JQLogUtilDevToolViewController.m
//  BFDevTools
//
//  Created by zhangjinquan on 2019/9/17.
//

#import "JQLoggerDevToolViewController.h"
#import "JQLogHomeBrowserTableViewController.h"
#import "JQLogUtil.h"

@implementation JQLoggerDevToolViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"JQLog";
//    self.navigationItem.rightBarButtonItem = [UIBarButtonItem itemWithTitle:@"完成" style:UIBarButtonItemStyleDone block:^(UIBarButtonItem * _Nonnull item) {
//        [UIManager dismissViewControllerCompletion:nil];
//    }];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(actionDone)];

    __weak __auto_type weakSelf = self;
    
    XLFormDescriptor * form = [XLFormDescriptor formDescriptorWithTitle:self.title];
    XLFormSectionDescriptor * section;
    
    // Basic Information
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    [section addFormRow:[self itemWithTitle:@"TTY Logger"
                                      value:[self isLoggerActive:[DDTTYLogger sharedInstance]]
                                   onSwitch:^(BOOL isOn) {
                                       if (isOn) {
                                           [JQLogUtil setup:JQLoggerTypeTTY];
                                       }
                                       else {
                                           [DDLog removeLogger:[DDTTYLogger sharedInstance]];
                                       }
                                   }]];
    
    [section addFormRow:[self itemWithTitle:@"ASL Logger"
                                      value:[self isLoggerActive:[self aslLogger]]
                                   onSwitch:^(BOOL isOn) {
                                       if (isOn) {
                                           [JQLogUtil setup:JQLoggerTypeASL];
                                       }
                                       else {
                                           [DDLog removeLogger:[self aslLogger]];
                                       }
                                   }]];
    
    [section addFormRow:[self itemWithTitle:@"File Logger"
                                      value:[self isLoggerActive:[self fileLogger]]
                                   onSwitch:^(BOOL isOn) {
                                       if (isOn) {
                                           [JQLogUtil setup:JQLoggerTypeFile];
                                       }
                                       else {
                                           [DDLog removeLogger:[self fileLogger]];
                                       }
                                   }]];
    [section addFormRow:[self itemWithTitle:@"查看日志" action:^{
        [weakSelf openFileLogBrowsers];
    }]];
    
    self.form = form;
}

- (void)actionDone {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)openFileLogBrowsers {
    NSString *path = [JQLogUtil logFileDirectory];
    JQLogHomeBrowserTableViewController *vc = [[JQLogHomeBrowserTableViewController alloc] initWithPath:path];
//    [UIManager showViewController:vc];
    [self.navigationController pushViewController:vc animated:YES];
}

- (id<DDLogger>)aslLogger {
    if (@available(iOS 10.0, *)) {
        return [DDOSLogger sharedInstance];
    }
    else {
        return [DDASLLogger sharedInstance];
    }
}

- (id<DDLogger>)fileLogger {
    __block id<DDLogger> logger = nil;
    [[DDLog sharedInstance].allLoggers enumerateObjectsUsingBlock:^(id<DDLogger>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.loggerName isEqualToString:@"com.jqoo.log-util.fileLogger"]) {
            logger = obj;
            *stop = YES;
        }
    }];
    return logger;
}

- (BOOL)isLoggerActive:(id<DDLogger>)logger {
    if (!logger) {
        return NO;
    }
    return [[DDLog sharedInstance].allLoggers containsObject:logger];
}

- (XLFormRowDescriptor *)itemWithTitle:(NSString *)title value:(BOOL)value onSwitch:(void (^)(BOOL isOn))onSwitch {
    XLFormRowDescriptor *item = [XLFormRowDescriptor formRowDescriptorWithTag:nil
                                                                      rowType:XLFormRowDescriptorTypeBooleanSwitch
                                                                        title:title];
    item.onChangeBlock = ^(id __nullable oldValue,id __nullable newValue,XLFormRowDescriptor* __nonnull sender) {
        onSwitch([newValue boolValue]);
    };
    item.value = @(value);
    return item;
}

- (XLFormRowDescriptor *)itemWithTitle:(NSString *)title action:(dispatch_block_t)action {
    XLFormRowDescriptor * buttonLeftAlignedRow = [XLFormRowDescriptor formRowDescriptorWithTag:nil rowType:XLFormRowDescriptorTypeButton title:title];
    [buttonLeftAlignedRow.cellConfig setObject:@(NSTextAlignmentNatural) forKey:@"textLabel.textAlignment"];
    [buttonLeftAlignedRow.cellConfig setObject:@(UITableViewCellAccessoryDisclosureIndicator) forKey:@"accessoryType"];
    
    __typeof(self) __weak weakSelf = self;
    buttonLeftAlignedRow.action.formBlock = ^(XLFormRowDescriptor * sender){
        [weakSelf deselectFormRow:sender];
        action();
    };
    return buttonLeftAlignedRow;
}

@end


