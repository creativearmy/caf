//
//  MMBMNavBarViewController.m
//  makeMoney
//
//  Created by zwd on 14-8-21.
//  Copyright (c) 2014年 zwd. All rights reserved.
//

#import "DDBMNavBarViewController.h"

@interface DDBMNavBarViewController ()
{
    NSString *navTitle;
}

@end

@implementation DDBMNavBarViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (id)initNavigate:(NSString*)title
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
        // Custom initialization
        navTitle = title;        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.btnLeft.hidden = YES;
    self.btnRight.hidden = YES;
    self.btnSecondLeft.hidden = YES;
    self.btnSecondRight.hidden = YES;
    // Do any additional setup after loading the view from its nib.
    self.labTitle.text = navTitle;
    //统一标题栏文字大小，如果自定义字体可以直接这里添加更改
    self.labTitle.font = [UIFont systemFontOfSize:20];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 屏幕方向
// 允许自动旋转，在支持的屏幕中设置了允许旋转的屏幕方向。
- (BOOL)shouldAutorotate
{
    return YES;
}

// 支持的屏幕方向，这个方法返回 UIInterfaceOrientationMask 类型的值。
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

// 视图展示的时候优先展示为 home键在右边的 横屏
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end
