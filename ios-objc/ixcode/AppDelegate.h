#import <UIKit/UIKit.h>
#import "APIConnection.h"

extern APIConnection *globalConn;

#define TOOLBOX_ACCOUNT @"test1"
#define IXCODE_ACCOUNT @"test2"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic ,strong)UINavigationController *firstMainVC;

-(void) init_sdk;
+ (AppDelegate *) APP;

@end

