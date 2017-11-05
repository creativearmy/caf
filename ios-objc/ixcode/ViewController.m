#import "MBProgressHUD+ND.h"
#import "AppDelegate.h"
#import "UtilsMacro.h"
#import "NSObject+MJKeyValue.h"

#import "i000ViewController.h"
#import "ViewController.h"

// App main window. It is the first screen when the spp starts

@interface ViewController (){
    NSString *login_name;
    NSString *login_passwd;
}

@property (strong, nonatomic) IBOutlet UITextField *account;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;

- (IBAction)forgotPasswordClick:(UIButton *)sender;
- (IBAction)landingClick:(UIButton *)sender;
- (IBAction)registeredClick:(UIButton *)sender;

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
    
    login_name  = [NSString stringWithFormat:@"test1"];
    login_passwd= [NSString stringWithFormat:@"1"];
    _loginBtn.layer.cornerRadius = 5;

    if (globalConn.state < LOGIN_SCREEN_ENABLED) {
        _loginBtn.enabled = NO;
        _loginBtn.backgroundColor = [UIColor grayColor];
    }
    
    [self createNavBar];
    
    JSONObject* jo = [globalConn user_joread];
    self.account.text = [[jo o:@"Account"] s:@"account"];
    
    NSLog(@"addObserver: %@", NSStringFromClass([self class]));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(response_received) name:globalConn.responseReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(state_changed) name:globalConn.stateChangedNotification object:nil];
    
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
    
    // uerr, ustr, derr: user error code, user error string, and extra error information for developer
    NSLog(@"server sent data handled by %@: thread %@, %@:%@ uerr:%@ ustr:%@ derr:%@", [self class], [globalConn.response objectForKey:@"obj"], [globalConn.response objectForKey:@"act"],
          [NSThread currentThread], [globalConn.response objectForKey:@"uerr"], [globalConn.response objectForKey:@"ustr"], [globalConn.response objectForKey:@"derr"]);
    
    // it is a login api call reponse
    if ([[globalConn.response s:@"obj"] isEqualToString:@"person"] && [[globalConn.response s:@"act"] isEqualToString:@"login"]) {

        if ([globalConn.response[@"derr"] containsString:@"does not exist"]) {
            [MBProgressHUD showError:@"mobile phone not registered"];
        }
        else if ([globalConn.response[@"derr"] containsString:@"login passwd not correct"]) {
            [MBProgressHUD showError:@"password not match"];
        }
        else {
            [MBProgressHUD showError:@"phone or password not match"];
        }

        [MBProgressHUD showSuccess:@"login succeed!"];
        //[MBProgressHUD hideHUDForView:self.view];
       
        JSONObject* jo = [globalConn user_joread];
        [[jo o:@"Account"] setValue:self.account.text forKey:@"account"];
        [globalConn user_jowrite:jo];
        
        i000ViewController *vc = [[i000ViewController alloc]initWithNibName:@"i000View" bundle:nil];
        [self.navigationController pushViewController:vc animated:YES];
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
