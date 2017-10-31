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

@property (strong, nonatomic) IBOutlet UITextField *account; //
@property (strong, nonatomic) IBOutlet UITextField *password;//
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;//

- (IBAction)forgotPasswordClick:(UIButton *)sender;//
- (IBAction)landingClick:(UIButton *)sender;//
- (IBAction)registeredClick:(UIButton *)sender;//

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
    
    login_name  = [NSString stringWithFormat:@"test1"];//
    login_passwd= [NSString stringWithFormat:@"1"];     //
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
        
        [MBProgressHUD showSuccess:@"login succeed!"];
        
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
            [MBProgressHUD showError:@"mobile phone not registered"];
        }
        else if ([response[@"derr"] containsString:@"login passwd not correct"]) {
            [MBProgressHUD showError:@"password not match"];
        }
        else {
            [MBProgressHUD showError:@"phone or password not match"];
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
        [MBProgressHUD showError:@"enter phone number"];
        return;
    }
    if (self.password.text.length <= 0) {
       [MBProgressHUD showError:@"enter password"];
        return;
    }
    [MBProgressHUD showMessage:@"" toView:self.view];

    //[globalConn credential:self.account.text withPasswd:self.password.text];
    //[globalConn connect];
    [globalConn login:self.account.text withPasswd:self.password.text];
}

- (void)createNavBar {
//    [self addNavigatorTitle:NSLocalizedString(@"login", nil) parent:self.view];
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
