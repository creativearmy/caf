//
//  MessageModel.h
//  气泡聊天
//
//  Created by qianfeng on 15/7/28.
//  Copyright (c) 2015年 qianfeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MessageModel : NSObject

@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString * stamp;
/**
 保存文字的宽高
 */
@property (nonatomic, assign) CGSize size;

@end
