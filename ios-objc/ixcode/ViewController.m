//
//  userLoginViewController.m
//  i011
//
//  Created by 李志远 on 15/12/8.
//  Copyright © 2015年 李志远. All rights reserved.
//

#import "MBProgressHUD+ND.h"
#import "AppDelegate.h"
#import "UtilsMacro.h"
#import "NSObject+MJKeyValue.h"

#import "i000ViewController.h"
#import "ViewController.h"

@interface ViewController (){
    NSString *login_name;
    NSString *login_passwd;
}

@property (strong, nonatomic) IBOutlet UITextField *account; //账号
@property (strong, nonatomic) IBOutlet UITextField *password;//密码
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;//登陆按键属性

- (IBAction)forgotPasswordClick:(UIButton *)sender;//忘记密码点击事件
- (IBAction)landingClick:(UIButton *)sender;//登陆点击事件
- (IBAction)registeredClick:(UIButton *)sender;//注册We点击事件

@end

@implementation ViewController

- (void )viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
-(void )viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // singleton, init once, used through out app, this happens BEFORE didFinishLaunchingWithOptions !!
    if (globalConn == nil) globalConn = [[APIConnection alloc] init];
    
    login_name  = [NSString stringWithFormat:@"test1"];//账号
    login_passwd= [NSString stringWithFormat:@"1"];     //密码
    _loginBtn.layer.cornerRadius = 5;

    if (globalConn.state < LOGIN_SCREEN_ENABLED) {
        _loginBtn.enabled = NO;
        _loginBtn.backgroundColor = [UIColor grayColor];
    }
    
    [self createNavBar];
    NSString* login_name_cache=[[NSUserDefaults standardUserDefaults] objectForKey:@"login_name_cache"];
    if (login_name_cache==nil) {
        login_name_cache=@"";
    }
    self.account.text=login_name_cache;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(response_received)
                                                 name:globalConn.responseReceivedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(state_changed)
                                                 name:globalConn.stateChangedNotification object:nil];
    
    // now we are ready to connect to server, and retrieve server_info
    [AppDelegate.APP init_sdk];
}

- (void)state_changed {
    
    if (globalConn.state == LOGIN_SCREEN_ENABLED) {
        _loginBtn.enabled = YES;
        _loginBtn.backgroundColor = RGB(104, 181, 64);
    }
    
    if (globalConn.state == IN_SESSION) {
    }
}

- (void)response_received {
    
    NSLog(@"handled by %@: %@:%@ uerr:%@", [self class],
          [globalConn.response objectForKey:@"obj"],
          [globalConn.response objectForKey:@"act"],
          [globalConn.response objectForKey:@"uerr"]);
    
    NSString*obj_act=[NSString stringWithFormat:@"%@_%@",globalConn.response[@"obj"],globalConn.response[@"act"]];
 
    if ([obj_act isEqualToString:@"person_login"]) {
        
        // cancel hourglass
        [MBProgressHUD hideHUDForView:self.view];
        
        // user error occurs, return structure can not be certain
        if (![[globalConn.response s:@"uerr"] isEqualToString:@""]) return;
        
        [self obLoginArrivedFormUL:globalConn.response];
    }
    
    return;
}

- (void)obLoginArrivedFormUL:(JSONObject *)response {
    

    if ([[response s:@"ustr"] isEqualToString:@""]) {
        
        [MBProgressHUD showSuccess:@"登录成功"];
        
        // check apns_device_token and update if needed
        /*
        if (![[globalConn.user_info s:@"apns_device_token"] isEqualToString:apns_device_token]) {
            NSMutableDictionary *req = [[NSMutableDictionary alloc] init];
            [req setObject:@"person" forKey:@"obj"];
            [req setObject:@"apns_device_token" forKey:@"act"];
            [req setObject:apns_device_token forKey:@"token"];
            [globalConn send:req];
        }
        */
        
        [[NSUserDefaults standardUserDefaults] setObject:self.account.text forKey:@"login_name_cache"];
        
        i000ViewController *vc = [[i000ViewController alloc]initWithNibName:@"i000View" bundle:nil];
        [self.navigationController pushViewController:vc animated:YES];
        
    }
    else {
        if ([response[@"derr"] containsString:@"does not exist"]) {
            [MBProgressHUD showError:@"该手机号码还未注册"];
        }
        else if ([response[@"derr"] containsString:@"login passwd not correct"]) {
            [MBProgressHUD showError:@"密码错误请重新输入"];
        }
        else {
            [MBProgressHUD showError:@"手机或密码错误，请重新输入"];
        }
        [MBProgressHUD hideHUDForView:self.view];
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)landingClick:(UIButton *)sender {
    
    if (self.account.text.length <= 0) {
        [MBProgressHUD showError:@"请输入账号!"];
        return;
    }
    if (self.password.text.length <= 0) {
       [MBProgressHUD showError:@"请输入密码!"];
        return;
    }
    [MBProgressHUD showMessage:@"" toView:self.view];

    //[globalConn credential:self.account.text withPasswd:self.password.text];
    //[globalConn connect];
    [globalConn login:self.account.text withPasswd:self.password.text];
}

- (void)createNavBar {
//    [self addNavigatorTitle:NSLocalizedString(@"登录", nil) parent:self.view];
//    
//    self.barViewControl.view.backgroundColor = RGB(52, 51, 52);
//    [self AddLeftBtnAction:nil normal:@"icon_back" selected:@"icon_back" action:^{
//        [self.navigationController popViewControllerAnimated:YES];
//    }];
    
}

- (IBAction)forgotPasswordClick:(UIButton *)sender {
    
    i000ViewController *forgotPwdVC = [[i000ViewController alloc] initWithNibName:@"i000View" bundle:nil];
    [self.navigationController pushViewController:forgotPwdVC animated:YES];
}

- (IBAction)registeredClick:(UIButton *)sender {
    
    i000ViewController *registVC = [[i000ViewController alloc] initWithNibName:@"i000View" bundle:nil];
    [self.navigationController pushViewController:registVC animated:YES];
}
@end
