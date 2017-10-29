#import "AppDelegate.h"
#import "i000ViewController.h"
#include <sys/time.h>

@interface i000ViewController ()

@end

@implementation i000ViewController

// 界面整合入序列说明： mock_* 相关的不能有的，只有胚片和界面制作验收过程需要
// 开发只要关注：【1】【2】【3】【4】
// 【1】见 AppDelegate.h
@synthesize OUTPUT;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"addObserver");
    
    // 【2】 注册回调
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(response_received:)
        name:globalConn.responseReceivedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"removeObserver");

    // 【2】 注销回调
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 【4】 按键按下 是用户输入，调用这里定义的 input 函数，工具箱那边登录后可以观察到
// 通常这里会收集一些数据，一起发送到服务器。比如一个选日期的界面，这里就应该有用选择的日期
- (IBAction)inputAction:(id)sender {
    NSMutableDictionary* data = [[NSMutableDictionary alloc] init];
    
    [data setObject:@"test" forKey:@"obj"];
    [data setObject:@"input1" forKey:@"act"];
    [data setObject:@"click" forKey:@"data"];
    
    // 通常还有用户在界面输入的其他数据，一起发送好了
    [self mock_capture_input:data];
}

- (void)response_received:(NSNotification *) notification {

    if (![[notification name] isEqualToString:@"response"]) return;
    
    NSLog(@"notification %@, thread %@, response: %@:%@ uerr:%@ derr:%@ ustr:%@",
        [notification name],
        [NSThread currentThread],
        [globalConn.response s:@"obj"],
        [globalConn.response s:@"act"],
        [globalConn.response s:@"uerr"],
        [globalConn.response s:@"derr"],
        [globalConn.response s:@"ustr"]);
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                            // 【服务端数据接收区】
    
    
    // 【3】 工具箱那里发送 "send input" 后，会发送数据到本APP。这个是模拟服务器 “输出”
    // 如果APP 要响应服务器的输出，像请求响应，或服务器的推送，就可以在这里定义要做的处理
    // 工具箱那里发送"send input"下面这个：
    // {"obj":"associate","act":"mock","to_login_name":"IXCODE_ACCOUNT","data":{"obj":"test","act":"OUTPUT1","data":"blah"}}
    if ([[globalConn.response s:@"obj"] isEqualToString:@"test"]) {
        if ([[globalConn.response s:@"act"] isEqualToString:@"output1"]) {
            //OUTPUT.text = [[[globalConn.response optJSONArray:@"data"] optJSONObject:1] optString:@"show" defaultValue:@"none"];
            //OUTPUT.text = [[globalConn.response optJSONArray:@"data"] optString:1];
            //OUTPUT.text = [globalConn.response optString:@"data"];
            
            // 服务器输出，简单的在屏幕上打印这条信息
            
            // // 懒人福气！ 可以用缩写的
            //OUTPUT.text = [[[globalConn.response a:@"data"] o:1] s:@"show" d:@"none"];
            //OUTPUT.text = [[globalConn.response a:@"data"] s:1];
            OUTPUT.text = [globalConn.response s:@"data"];
        }
    }
    if ([[globalConn.response s:@"obj"] isEqualToString:@"associate"]) {
        if ([[globalConn.response s:@"act"] isEqualToString:@"mock"]) {
            struct timeval time;
            gettimeofday(&time, NULL);
            long unsigned millis = (time.tv_sec*1000) + (time.tv_usec/1000);
            OUTPUT.text = [NSString stringWithFormat:@"mock resp %lu", millis];
        }
    }
        
    if ([[globalConn.response s:@"obj"] isEqualToString:@"person"]) {
        if ([[globalConn.response s:@"act"] isEqualToString:@"login"]) {
            if ([[globalConn.response s:@"ustr"] isEqualToString:@""]) {
                OUTPUT.text = [NSString stringWithFormat:@"本胚片工程用户ID %@ 自动登陆已经OK，\n请在演示工具箱也登陆账号ID %@ 密码 1", IXCODE_ACCOUNT, TOOLBOX_ACCOUNT];
                }
        }
    }
    
    return;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 界面整合入序列时候，下面一般不需要

-(void)mock_capture_input:(NSMutableDictionary*)data {
    NSMutableDictionary* req = [[NSMutableDictionary alloc] init];
    
    [req setObject:@"associate" forKey:@"obj"];
    [req setObject:@"mock" forKey:@"act"];
    [req setObject:TOOLBOX_ACCOUNT forKey:@"to_login_name"];
    [req setObject:data forKey:@"data"];
    
    [globalConn send:req];
}

@end
