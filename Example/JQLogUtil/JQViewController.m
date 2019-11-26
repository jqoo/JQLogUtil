//
//  JQViewController.m
//  JQLogUtil
//
//  Created by jqoo on 11/26/2019.
//  Copyright (c) 2019 jqoo. All rights reserved.
//

#import "JQViewController.h"
#import <JQLogUtil.h>

@interface JQViewController ()

@end

@implementation JQViewController

- (IBAction)actionDevTool:(id)sender {
    JQLogWarn2(1011, @"Shop", @"Show dev tool");
    
    UIViewController *vc = [[NSClassFromString(@"JQLoggerDevToolViewController") alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    JQLogInfo2(1011, @"Shop", @"Show product detail");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
