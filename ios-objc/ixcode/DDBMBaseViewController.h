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


- (void)addNavigatorTitle:(NSString*)title;

- (void)addNavigatorTitle:(NSString*)title parent:(UIView*)parent;

- (void)setNavTitle:(NSString*)title;


- (void)setBtnAction:(UIButton*) btn action:(void (^)(void))action isSecondLeft:(BOOL)isSecondLeft;


- (void)setBtnAction:(UIButton*) btn action:(void (^)(void))action isLeft:(BOOL)isLeft;


- (void)AddSecondLeftBtnAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action;

- (void)AddSecondRightBtnAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action;


- (void)AddLeftBtnAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action;

- (void)AddRightBtnAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action;

- (void)AddLeftBtnBacgroundAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action;

- (void)AddRightBtnBacgroundAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action;




-(void)changeStyle:(NSNotification *)notification;


-(void) showHUD:(NSString *) text;

-(void) hideHUD;
-(void) delayHUD:(NSString *) text;



- (void)delayHUDSecond: (NSString *)text;
-(void) hideTextHUD;
-(void) delayTextHUD:(NSString *)text;
-(void) showHUDIndeterminate;

-(void)createUI;
-(void)createData;


-(float) xPostiong:(UIView *)view sp:(float)sp;
-(float) yPostiong:(UIView *)view sp:(float)sp;


- (void)setProfile:(NSString *)profileString profileImage:(UIImageView *)imageView placeholderImage:(UIImage *)pImage;
@end
