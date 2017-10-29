#import "AppDelegate.h"
#import "i072ViewController.h"
#import "i000ViewController.h"
#import "ChatViewController.h"
#import "ViewController.h"

#import "MBProgressHUD+ND.h"

#define WSURL @"ws://112.124.70.60:51727/demo"

APIConnection *globalConn;

@interface AppDelegate ()

@end

@implementation AppDelegate

+ (AppDelegate *)APP{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    ViewController* firstVC = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    
    self.firstMainVC = [[UINavigationController alloc] initWithRootViewController:firstVC];
    self.firstMainVC.navigationBarHidden = YES;
    
    self.window.rootViewController = self.firstMainVC;

    [self.window makeKeyAndVisible];
    
    // singleton, init once, used through out app
    if (globalConn == nil) globalConn = [[APIConnection alloc] init];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

////////////////////////////////////////////////// SDK RELATED /////////////////////////////////////////////////////////

-(void)switchViewController:(NSString*)ixxx
{
    UIViewController * vc = nil;
    
    // 添加界面控制器到这里就可以用工具箱那边的 Switch 按键把这个界面调到前面做测试什么的
    
    if ([ixxx isEqualToString:@"i000"]) vc = [[i000ViewController alloc] initWithNibName:@"i000View" bundle:nil];
    if ([ixxx isEqualToString:@"i072"]) vc = [[i072ViewController alloc] initWithNibName:@"i072ViewBlank" bundle:nil];
    
    if ([ixxx isEqualToString:@"i052"]) {
        ChatViewController* c = [[ChatViewController alloc] init];
        c.obj = @"person";
        c.to_id = @"o14509039359136660099";
        c.title_text = @"私聊：AppDelegate.m vc.to_id";
        vc = c;
    }
    
    
    
    if (vc == nil) return;
    UINavigationController* unav = (UINavigationController*)self.window.rootViewController;
    [unav pushViewController:vc animated:YES];
}

-(void)response_received
{
    // global error display
    NSString * ustr =[globalConn.response s:@"ustr"];
    if (![ustr isEqualToString:@""]) {
        
        // this is for debug, ignore fornow
        if ([[globalConn.response s:@"uerr"] isEqualToString:@"ERR_CONNECTION_EXCEPTION"]) return;
        
        [MBProgressHUD showError:ustr];
    }
    
    if ([[globalConn.response s:@"obj"] isEqualToString:@"sdk"] &&
        [[globalConn.response s:@"act"] isEqualToString:@"switchreq"]) {
        
        NSString* ixxx = [globalConn.response s:@"ixxx"];
        
        [self switchViewController:ixxx];
    }
}

-(void)state_changed
{
}

-(void) init_sdk {

    if (globalConn == nil) globalConn = [[APIConnection alloc] init];

    // ensure init_sdk only once
    if ([[globalConn.user_data s:@"init_sdk"] isEqualToString:@"1"]) return;
    [globalConn.user_data setObject:@"1" forKey:@"init_sdk"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(state_changed)
                                                 name: globalConn.stateChangedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(response_received)
                                                 name: globalConn.responseReceivedNotification
                                               object:nil];
    
    [globalConn.client_info setObject:@"iOS" forKey:@"clienttype"];
    [globalConn.client_info setObject:@"1.9" forKey:@"version"];
    
    [globalConn setWsURL:WSURL];
    
    [globalConn connect];
}

@end
