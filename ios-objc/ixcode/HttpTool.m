#import "HttpTool.h"
#import "AFNetworking.h"
#import "AppDelegate.h"
//#import "AFURLRequestSerialization.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "MBProgressHUD.h"

#import "AFHTTPRequestOperationManager.h"

@implementation NDFormDataFromTool//NDFormDataFromTool

@end


@implementation HttpTool


+(void)AFNetworkReachability:(void(^)(void))isOK isWiFi:(void (^)(void))isWiFi is3G:(void (^)(void))is3G isNO:(void (^)(void))isNO{

    //[[AFNetworkReachabilityManager sharedManager] startMonitoring];

    CTTelephonyNetworkInfo *networkStatus = [[CTTelephonyNetworkInfo alloc]init];
    NSString *statusName=@"";
    switch ([[AFNetworkReachabilityManager sharedManager] networkReachabilityStatus]) {
        case AFNetworkReachabilityStatusNotReachable:{statusName=@"Network down";if(isNO){isNO();} break;}
        case AFNetworkReachabilityStatusReachableViaWiFi:{statusName=@"Wifi";if(isOK){isOK();} if(isWiFi){isWiFi();} break;}// 
        case AFNetworkReachabilityStatusUnknown:{statusName=@"Unknow Network";if(isOK){isOK();} break;}
        case AFNetworkReachabilityStatusReachableViaWWAN:{
            NSString *currentStatus  = networkStatus.currentRadioAccessTechnology;
            if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyGPRS"]){statusName=@"GPRS(2G)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyEdge"]){statusName=@"Edge(2G)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyWCDMA"]){statusName=@"WCDMA(3G)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSDPA"]){statusName=@"HSDPA(3G)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSUPA"]){statusName=@"HSUPA(3G)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMA1x"]){statusName=@"CDMA1xNetwork(2G)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORev0"]){statusName=@"CDMAEVDORev0(3G)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevA"]){statusName=@"CDMAEVDORevA(3G)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevB"]){statusName=@"CDMAEVDORevB(3G)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyeHRPD"]){statusName=@"HRPD(CDMA)";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyLTE"]){statusName=@"LTE(4G)";
            }
            if(isOK){isOK();} if(is3G){is3G();} break;}
        default:break;
    }
}



+ (void)postWithURL:(NSString *)url params:(NSDictionary *)params success:(void (^)(id))success failure:(void (^)(NSString *))failure
{
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//
    
    [self AFNetworkReachability:^(void){//
        @try{

            AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];
            mgr.requestSerializer.HTTPShouldHandleCookies = YES;
            mgr.requestSerializer=[AFJSONRequestSerializer serializer];    //
            mgr.responseSerializer = [AFJSONResponseSerializer serializer];//
            mgr.responseSerializer.acceptableContentTypes=[NSSet setWithObject:@"text/html"];//

            [mgr POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  [self processSuccess:success failure:failure operation:operation responseObject:responseObject];
                
              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self processFailure:failure operation:operation error:error];
              }];
            }@catch (NSException *e){
            NSLog(@"AFHTTPRequestOperation return error ,Error=%@",e);
        }
    }isWiFi:^(void){} is3G:^(void){}  isNO:^(void){
        
        if(failure){failure(@"Network is down");}
    }];

}

+ (void)postWithURL:(NSString *)url params:(NSDictionary *)params formDataArray:(NSArray *)formDataArray success:(void (^)(id))success failure:(void (^)(NSString *))failure
{
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//
    
    [self AFNetworkReachability:^(void){//
        @try{

            AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];

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
            NSLog(@"AFHTTPRequestOperation request failed ,Error=%@",e);
        }
    }isWiFi:^(void){} is3G:^(void){}  isNO:^(void){
        if(failure){failure(@"network is down");}
    }];

}


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
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//
    
    [self AFNetworkReachability:^(void){//
        @try{

            AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];

            [mgr GET:url parameters:params
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 [self processSuccess:success failure:failure operation:operation responseObject:responseObject];
             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 [self processFailure:failure operation:operation error:error];
              }];
        }@catch (NSException *e){
            NSLog(@"AFHTTPRequestOperation request failed ,Error=%@",e);
        }
    }isWiFi:^(void){} is3G:^(void){}  isNO:^(void){
        if(failure){failure(@"network is down");}
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
             failure(@"network is down");
        }
    }

}

+ (void)processFailure:(void (^)(NSString *))failure operation:(AFHTTPRequestOperation *)operation error:(NSError *) error
{
    NSLog(@"NetWork  error:%@",[error userInfo]);
    if (failure) {
        if (error.code == 2){
            failure(@"request timeout");
        }else if (error.code == 6){
            failure(@"session not valid");
        }else{
            failure(@"network is down");
        }
    }
}


@end

