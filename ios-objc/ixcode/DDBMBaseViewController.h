//
//  MMBMBaseViewController.h
//  makeMoney
//
//  Created by zwd on 14-8-21.
//  Copyright (c) 2014年 zwd. All rights reserved.
//

/**
 所有UIViewControl统一方法写在这里，具体UIViewController继承该UIViewController
 */


#import <UIKit/UIKit.h>
#import "DDBMNavBarViewController.h"
#import "MBProgressHUD.h"
#define kChangeStyle @"changeStyle"

@interface DDBMBaseViewController : UIViewController<MBProgressHUDDelegate>

@property (nonatomic, strong)DDBMNavBarViewController *barViewControl;

@property (nonatomic, strong)MBProgressHUD *HUD;

/**
 Navigation Bar control function  begin
 ----------------------------------------------------
 */

//添加导航栏并设置标题
- (void)addNavigatorTitle:(NSString*)title;
//添加导航栏到指定父View并设置标题
- (void)addNavigatorTitle:(NSString*)title parent:(UIView*)parent;
//设置导航栏标题
- (void)setNavTitle:(NSString*)title;

//自定义第二个左右按钮
- (void)setBtnAction:(UIButton*) btn action:(void (^)(void))action isSecondLeft:(BOOL)isSecondLeft;

//自定义左右按钮
- (void)setBtnAction:(UIButton*) btn action:(void (^)(void))action isLeft:(BOOL)isLeft;

//添加二级左菜单，设置前景图
- (void)AddSecondLeftBtnAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action;
//添加二级右菜单，设置前景图
- (void)AddSecondRightBtnAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action;

//添加左菜单，设置前景图
- (void)AddLeftBtnAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action;
//添加右菜单，设置前景图
- (void)AddRightBtnAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action;
//添加左菜单，设置背景图
- (void)AddLeftBtnBacgroundAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action;
//添加右菜单，设置背景图
- (void)AddRightBtnBacgroundAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action;

/**
 ----------------------------------------------------
 Navigation Bar control function  END
 */



//换肤，需要重写
-(void)changeStyle:(NSNotification *)notification;

//提示信息框
-(void) showHUD:(NSString *) text;
//隐藏信息框
-(void) hideHUD;
-(void) delayHUD:(NSString *) text;


// JolieYang
- (void)delayHUDSecond: (NSString *)text;
-(void) hideTextHUD;
-(void) delayTextHUD:(NSString *)text;
-(void) showHUDIndeterminate;

-(void)createUI;
-(void)createData;


-(float) xPostiong:(UIView *)view sp:(float)sp;
-(float) yPostiong:(UIView *)view sp:(float)sp;

//设置网络图像
- (void)setProfile:(NSString *)profileString profileImage:(UIImageView *)imageView placeholderImage:(UIImage *)pImage;
@end
