#import "AppDelegate.h"
#import "i072ViewController.h"
#import "i000ViewController.h"
#import "ChatViewController.h"
#import "ViewController.h"

#import "MBProgressHUD+ND.h"

#define WSURL @"ws://47.92.169.34:51700/demo"

// singleton global Creativearmy App Framework SDK obj
APIConnection *globalConn;
NSString* apns_device_token;

@interface AppDelegate ()

@end

@implementation AppDelegate

+ (AppDelegate *)APP{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    ViewController* firstVC = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    
    self.firstMainVC = [[UINavigationController alloc] initWithRootViewController:firstVC];
    self.firstMainVC.navigationBarHidden = YES;
    
    self.window.rootViewController = self.firstMainVC;

    [self.window makeKeyAndVisible];
    
    // singleton, init once, used through out app
    if (globalConn == nil) globalConn = [[APIConnection alloc] init];
    ////////////////////////////////////////////////// APNS RELATED /////////////////////////////////////////////////////////
    // make sure Background_Mode in info.plist remote_notification turned on as well!
    
    // Register the supported interaction types.
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    
    // Register for remote notifications.
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    // redfault is empty string
    apns_device_token = [NSString string];
        
    ////////////////////////////////////////////////// APNS TRIGGERED APP LAUNCH //////////////////////////////////////////////
    NSDictionary *remotenotif =[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remotenotif != nil) {
        // set a flag and defer action after login
        [globalConn.user_data setObject:@"1" forKey:@"show_inbox"];
    }
    
    // RootViewController initialization: e.g. userLoginViewController
    
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
    
    // if it is triggered by remote notification, user choose to open/bring it to foreground
    if ([[globalConn.user_data s:@"show_inbox"] isEqualToString:@"1"]) {
        // one time deal, reset the flag
        [globalConn.user_data setObject:@"0" forKey:@"show_inbox"];
        
        // TODO if top vc is already inbox vc, do nothing, refresh
        
        //if ([[self.firstMainVC topViewController] isKindOfClass:[i080InboxViewController class]]) {
        //    NSMutableDictionary *req = [[NSMutableDictionary alloc] init];
        //    [req setObject:@"inbox" forKey:@"obj"];
        //    [req setObject:@"get" forKey:@"act"];
        //    [globalConn send:req];
        //    
        //} else {
        //    // switch to inbox view controller
        //    // unified remote notification handler http://samwize.com/2015/08/07/how-to-handle-remote-notification-with-background-mode-enabled/
        //    // TODO
        //}
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

////////////////////////////////////////////////// APNS RELATED /////////////////////////////////////////////////////////
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)token {
    
    NSString *token_str = [[token description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    apns_device_token = [token_str stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSLog(@"apns_device_token: %@", apns_device_token);
    NSLog(@"original device token: %@", [token description]);

}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    NSLog(@"Error: %@", err);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    // somehow, this is called first when remote notification triggers the launch
    if (globalConn == nil) globalConn = [[APIConnection alloc] init];
    
    // what is this?
    completionHandler(UIBackgroundFetchResultNewData);

    NSLog(@"didReceiveRemoteNotification check show_inbox: %@ state: %i", [globalConn.user_data s:@"show_inbox"], globalConn.state);
    // launch triggered by remote notification
    if (globalConn.state <= LOGIN_SCREEN_SHOWN) {
        // deferred, wait after login,
        [globalConn.user_data setObject:@"1" forKey:@"show_inbox"];
        return;
    }
    
    NSLog(@"%@",userInfo);
    JSONObject *payload = (JSONObject*)[userInfo objectForKey:@"p"];
    [globalConn.user_data setObject:payload forKey:@"last_alert_payload"];
    
    NSString *title = @"";
    if ([[payload s:@"t"] isEqual:@"A"]) title = @"NOTIFICATION CATAGORY NAME 1";
    if ([[payload s:@"t"] isEqual:@"B"]) title = @"NOTIFICATION CATAGORY NAME 1";
    
    if (application.applicationState == UIApplicationStateActive) {
        
        NSString *alert = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
        UIAlertView *alertView1 = [[UIAlertView alloc] initWithTitle:@"TITLE" message:alert delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Inbox",nil];
        alertView1.tag = 10;
        [alertView1 show];
    }
}

// UIAlertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex

{
    if (buttonIndex == 0) {
        // ignore does nothing
        
    } else {
        
        JSONObject *payload = [globalConn.user_data o:@"last_alert_payload"];
        
        // TODO go directly to task or topic comment or chat page, for now go to inbox
        //if (true) {
        //    // if top vc is already inbox vc, do nothing, refresh
        //    if ([[self.firstMainVC topViewController] isKindOfClass:[i080InboxViewController class]]) {
        //    
        //        NSMutableDictionary *req = [[NSMutableDictionary alloc] init];
        //        [req setObject:@"inbox" forKey:@"obj"];
        //        [req setObject:@"get" forKey:@"act"];
        //        [globalConn send:req];
        //    
        //    } else {
        //        // switch to inbox vc
        //        // unified remote notification handler http://samwize.com/2015/08/07/how-to-handle-remote-notification-with-background-mode-enabled/
        //    }
        //}
    }
}

////////////////////////////////////////////////// SDK RELATED /////////////////////////////////////////////////////////

-(void)switchViewController:(NSString*)ixxx
{
    // Responds to Project Toolbox Switch command, and cause app to switch to another screen.
    UIViewController * vc = nil;
    
    // ixxx unique screen identifier. XXX shall be greater than 100 and less than 999
    // XXX less than 100 are allocated for system use
    
    
    if ([ixxx isEqualToString:@"i000"]) vc = [[i000ViewController alloc] initWithNibName:@"i000View" bundle:nil];
    if ([ixxx isEqualToString:@"i072"]) vc = [[i072ViewController alloc] initWithNibName:@"i072ViewBlank" bundle:nil];
    
    
    // Messaging demo, two-party conversation chat
    if ([ixxx isEqualToString:@"i052"]) {
        
        if ([[globalConn.user_data s:@"header_type"] isEqualToString:@"chat"]) {
            
            ChatViewController* c = [[ChatViewController alloc] init];
            
            c.header_type = @"chat";
            c.header_id = [globalConn.user_data s:@"header_id"];
            c.title_text = @"two-party conversation";
            vc = c;
        }
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
    
    NSLog(@"addObserver: %@", NSStringFromClass([self class]));
    [globalConn addObserver:self selector:@selector(state_changed) name: globalConn.stateChangedNotification object:nil];
    [globalConn addObserver:self selector:@selector(response_received) name: globalConn.responseReceivedNotification object:nil];
    
    [globalConn.client_info setObject:@"iOS" forKey:@"clienttype"];
    [globalConn.client_info setObject:@"1.9" forKey:@"version"];
    
    [globalConn setWsURL:WSURL];
    
    [globalConn connect];
}

@end
