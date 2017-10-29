//
//  IWHttpTool.m
//  ItcastWeibo
//
//  Created by apple on 14-5-19.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "HttpTool.h"
#import "AFNetworking.h"
#import "AppDelegate.h"
//#import "AFURLRequestSerialization.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "MBProgressHUD.h"

#import "AFHTTPRequestOperationManager.h"

/**
 *  用来封装文件数据的模型
 */
@implementation NDFormDataFromTool//NDFormDataFromTool

@end


@implementation HttpTool

#pragma mark - 检测网络连接
+(void)AFNetworkReachability:(void(^)(void))isOK isWiFi:(void (^)(void))isWiFi is3G:(void (^)(void))is3G isNO:(void (^)(void))isNO{
    //开启网络监视器 //如果要检测网络状态的变化,必须用检测管理器的单例的startMonitoring
    //[[AFNetworkReachabilityManager sharedManager] startMonitoring];
    //检测网络连接的单例,网络变化时的回调方法
    CTTelephonyNetworkInfo *networkStatus = [[CTTelephonyNetworkInfo alloc]init];
    NSString *statusName=@"";
    switch ([[AFNetworkReachabilityManager sharedManager] networkReachabilityStatus]) {
        case AFNetworkReachabilityStatusNotReachable:{statusName=@"没有网络";if(isNO){isNO();} break;}
        case AFNetworkReachabilityStatusReachableViaWiFi:{statusName=@"Wifi";if(isOK){isOK();} if(isWiFi){isWiFi();} break;}// 局域网
        case AFNetworkReachabilityStatusUnknown:{statusName=@"不知名网络";if(isOK){isOK();} break;}
        case AFNetworkReachabilityStatusReachableViaWWAN:{
            NSString *currentStatus  = networkStatus.currentRadioAccessTechnology;
            if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyGPRS"]){statusName=@"GPRS(2G网络)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyEdge"]){statusName=@"Edge(2G网络)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyWCDMA"]){statusName=@"WCDMA(3G网络)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSDPA"]){statusName=@"HSDPA(3G网络)(虽然移动用的是td而不是wcdma但也算是3G)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSUPA"]){statusName=@"HSUPA(3G网络)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMA1x"]){statusName=@"CDMA1xNetwork(2G网络)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORev0"]){statusName=@"CDMAEVDORev0(3G网络)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevA"]){statusName=@"CDMAEVDORevA(3G网络)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevB"]){statusName=@"CDMAEVDORevB(3G网络)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyeHRPD"]){statusName=@"HRPD(CDMA网络)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyLTE"]){statusName=@"LTE(4G网络)";
            }
            if(isOK){isOK();} if(is3G){is3G();} break;}
        default:break;
    }
}



+ (void)postWithURL:(NSString *)url params:(NSDictionary *)params success:(void (^)(id))success failure:(void (^)(NSString *))failure
{
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//处理汉字
    
    [self AFNetworkReachability:^(void){//判断是否有网络
        @try{
            // 1.创建请求管理对象
            AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];
            mgr.requestSerializer.HTTPShouldHandleCookies = YES;
            mgr.requestSerializer=[AFJSONRequestSerializer serializer];    //申明请求的数据是json类型
            mgr.responseSerializer = [AFJSONResponseSerializer serializer];//申明返回的结果是json类型
            mgr.responseSerializer.acceptableContentTypes=[NSSet setWithObject:@"text/html"];//包接受类型替换一致
            // 2.发送请求
            [mgr POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  [self processSuccess:success failure:failure operation:operation responseObject:responseObject];
                
              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self processFailure:failure operation:operation error:error];
              }];
            }@catch (NSException *e){
            NSLog(@"AFHTTPRequestOperation 异步请求错误 ,Error=%@",e);
        }
    }isWiFi:^(void){} is3G:^(void){}  isNO:^(void){
        
        if(failure){failure(@"请求错误,当前无可用的网络!！");}
    }];

}

+ (void)postWithURL:(NSString *)url params:(NSDictionary *)params formDataArray:(NSArray *)formDataArray success:(void (^)(id))success failure:(void (^)(NSString *))failure
{
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//处理汉字
    
    [self AFNetworkReachability:^(void){//判断是否有网络
        @try{
            // 1.创建请求管理对象
            AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];
            // 2.发送请求
            [mgr POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> totalFormData) {
                for (NDFormDataFromTool *formData in formDataArray) {
                    [totalFormData appendPartWithFileData:formData.data name:formData.name fileName:formData.filename mimeType:formData.mimeType];
                }
            } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [self processSuccess:success failure:failure operation:operation responseObject:responseObject];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self processFailure:failure operation:operation error:error];
                
            }];
        }@catch (NSException *e){
            NSLog(@"AFHTTPRequestOperation 异步请求错误 ,Error=%@",e);
        }
    }isWiFi:^(void){} is3G:^(void){}  isNO:^(void){
        if(failure){failure(@"请求错误,当前无可用的网络!！");}
    }];

}

/// 上传图片

+ (void)uploadImageWithUrl:(NSString *)url image:(UIImage *)image

                   success:(void (^)(id))success failure:(void (^)(NSString *))failure {

    NSData *imageData = UIImageJPEGRepresentation(image, 1);
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *str = [formatter stringFromDate:[NSDate date]];
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg", str];
    
    NDFormDataFromTool *data = [[NDFormDataFromTool alloc] init];
    data.mimeType = @"image/jpeg";
    data.data = imageData;
    data.name = @"local_file";
    data.filename = fileName;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[globalConn.server_info s:@"proj"] forKey:@"proj"];
    
    [self postWithURL:url params:params formDataArray:[NSArray arrayWithObject:data] success:success failure:failure];
}


+ (void)getWithURL:(NSString *)url params:(NSDictionary *)params success:(void (^)(id))success failure:(void (^)(NSString *))failure
{
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//处理汉字
    
    [self AFNetworkReachability:^(void){//判断是否有网络
        @try{
            // 1.创建请求管理对象
            AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];
            // 2.发送请求
            [mgr GET:url parameters:params
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 [self processSuccess:success failure:failure operation:operation responseObject:responseObject];
             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 [self processFailure:failure operation:operation error:error];
              }];
        }@catch (NSException *e){
            NSLog(@"AFHTTPRequestOperation 异步请求错误 ,Error=%@",e);
        }
    }isWiFi:^(void){} is3G:^(void){}  isNO:^(void){
        if(failure){failure(@"请求错误,当前无可用的网络!！");}
    }];

}

+ (void)processSuccess:(void (^)(id))success failure:(void (^)(NSString *))failure operation:(AFHTTPRequestOperation *)operation responseObject:(id) responseObject
{
    if(operation.response.statusCode==200){
        if (success) {
            success(responseObject);
        }
    }else{
        if (failure)
        {
             failure(@"请求错误,网络异常!");
        }
    }

}

+ (void)processFailure:(void (^)(NSString *))failure operation:(AFHTTPRequestOperation *)operation error:(NSError *) error
{
    NSLog(@"NetWork  error:%@",[error userInfo]);
    if (failure) {
        if (error.code == 2){
            failure(@"请求错误,网络连接超时!");
        }else if (error.code == 6){
            failure(@"请求错误,会话验证失败!");
        }else{
            failure(@"请求错误,网络异常!");
        }
    }
}


@end

