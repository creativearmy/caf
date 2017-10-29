//
//  MessageModel.m
//  气泡聊天
//
//  Created by qianfeng on 15/7/28.
//  Copyright (c) 2015年 qianfeng. All rights reserved.
//

#import "MessageModel.h"

@implementation MessageModel

- (void)setMessage:(NSString *)message
{
    _message = message;
    
    /**
     计算文字的宽高
     */
    [self calculateText:message];
}

- (void)calculateText:(NSString *)str
{
    _size = [str boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width - 90, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]} context:NULL].size;
}

@end
