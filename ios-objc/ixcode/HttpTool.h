#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface NDFormDataFromTool : NSObject
@property (nonatomic, strong) NSData *data;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *filename;

@property (nonatomic, copy) NSString *mimeType;

@end

@interface HttpTool : NSObject

+ (void)postWithURL:(NSString *)url params:(NSDictionary *)params success:(void (^)(id))success failure:(void (^)(NSString *))failure;

+ (void)postWithURL:(NSString *)url params:(NSDictionary *)params formDataArray:(NSArray *)formDataArray success:(void (^)(id json))success failure:(void (^)(NSString *error))failure;

+ (void)getWithURL:(NSString *)url params:(NSDictionary *)params success:(void (^)(id json))success failure:(void (^)(NSString *error))failure;

+ (void)uploadImageWithUrl:(NSString *)url image:(UIImage *)image
                   success:(void (^)(id))success failure:(void (^)(NSString *))failure;

@end


