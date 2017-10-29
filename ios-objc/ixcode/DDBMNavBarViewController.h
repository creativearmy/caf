//
//  MMBMNavBarViewController.h
//  makeMoney
//
//  Created by zwd on 14-8-21.
//  Copyright (c) 2014年 zwd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DDBMNavBarViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *btnLeft;
@property (weak, nonatomic) IBOutlet UILabel *labTitle;
@property (weak, nonatomic) IBOutlet UIButton *btnRight;
@property (weak, nonatomic) IBOutlet UIView *navView;
@property (weak, nonatomic) IBOutlet UIButton *btnSecondLeft;
@property (weak, nonatomic) IBOutlet UIButton *btnSecondRight;

- (id)initNavigate:(NSString*)title;

@end
