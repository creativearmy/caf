//
//  ChatCell.m
//  WeChat
//
//  Created by Jiao Liu on 11/26/13.
//  Copyright (c) 2013 Jiao Liu. All rights reserved.
//

#import "ChatCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+Utility.h"
#import "PlayViewController.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
@implementation ChatCell
{
    UILabel *inMsg;
    UILabel *outMsg;
    UILabel *outMsgLabel;
    UIImageView *inImage;
    UIImageView *outImage;
    UIImageView *bubbleImage;
    
    
    UIView *cellFrame;
}

- (void)setData:(NSDictionary *)data
{
    outMsgLabel.text = @"";
//    NSString *msgStr = [[NSString alloc] initWithData:[data objectForKey:@"msg"] encoding:NSUTF8StringEncoding];
    NSString * msgStr = [data objectForKey:@"data"];
    CGSize msgSize = [msgStr sizeWithFont:[UIFont systemFontOfSize:17] constrainedToSize:CGSizeMake(SCREEN_WIDTH - 70, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
    //**************图片************//
     NSString *msgType = [data objectForKey:@"msgType"];
    if ([data objectForKey:@"image"] != nil ) {
        
        if ([[data objectForKey:@"obj"] isEqualToString:@"test2"]) {
            UIImage *uiImage = [data objectForKey:@"image"];
            
             outImage.image = uiImage;
             bubbleImage.image = [[UIImage imageNamed:@"bubbleMine.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:14];
            
             if (msgType != nil) {
                 if ([msgType isEqualToString:@"money"]) {
                     [cellFrame setFrame:CGRectMake(0, 10, SCREEN_WIDTH, 160)];
                     
                     NSString* word = [data objectForKey:@"word"];
                     if (word != nil && [word length] > 0) {
                         outMsgLabel.text = word;
                         CGSize msgSizes = [outMsgLabel.text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(SCREEN_WIDTH - 70, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
                         [outImage setFrame:CGRectMake(SCREEN_WIDTH -msgSizes.width - 110, 40, 40, 40)];
                         outMsgLabel.frame = CGRectMake(outImage.frame.origin.x + 45, outImage.frame.origin.y + 10, msgSizes.width, msgSizes.height);
                         bubbleImage.frame = CGRectMake(outImage.frame.origin.x - 18,  33, outImage.frame.size.width + msgSizes.width + 40, outImage.frame.size.height + 25);
                     }
                     else{
                         outMsgLabel.text = @"红包";
                         CGSize msgSizes = [outMsgLabel.text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(SCREEN_WIDTH - 70, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
                         [outImage setFrame:CGRectMake(SCREEN_WIDTH -130, 40, 40, 40)];
                         outMsgLabel.frame = CGRectMake(outImage.frame.origin.x + 45, outImage.frame.origin.y + 10, msgSizes.width, msgSizes.height);
                         bubbleImage.frame = CGRectMake(outImage.frame.origin.x - 18,  33, outImage.frame.size.width + msgSizes.width + 40, outImage.frame.size.height + 25);
                     }
                     
                     outMsgLabel.textColor = [UIColor blackColor];
//                     cellFrame.backgroundColor = [UIColor redColor];
                     [cellFrame addSubview:bubbleImage];
                     [cellFrame addSubview:outImage];
                     [cellFrame addSubview:outMsgLabel];
//                     cellFrame.backgroundColor = [UIColor blueColor];
                 }
                else if([msgType isEqualToString:@"map"]){
                    [cellFrame setFrame:CGRectMake(0, 10, SCREEN_WIDTH, 220)];
                    [outImage setFrame:CGRectMake(SCREEN_WIDTH - uiImage.size.width - 60, 0, 150, 125)];
                    NSString *address = [data objectForKey:@"address"];
                    outMsgLabel.text = @"";
                    if (address != nil) {
                        outMsgLabel.text = address;
                    }
                    
                    outMsgLabel.textColor = [UIColor blackColor];
                    CGSize msgSizes = [outMsgLabel.text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(SCREEN_WIDTH - 70, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
                    outMsgLabel.frame = CGRectMake(outImage.frame.origin.x, uiImage.size.height -20, outImage.frame.size.width, msgSizes.height);
                    bubbleImage.frame = CGRectMake(outImage.frame.origin.x - 8,  -10, outImage.frame.size.width+ 25, outImage.frame.size.height  + outMsgLabel.frame.size.height + 25);
                    [cellFrame addSubview:bubbleImage];
                    [cellFrame addSubview:outImage];
                    [cellFrame addSubview:outMsgLabel];
                }
                else if ([msgType isEqualToString:@"video"]){
//                    UITapGestureRecognizer* recognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(playVideoView:)];
//                        cellFrame.backgroundColor = [UIColor blueColor];
                        [cellFrame setFrame:CGRectMake(0, 10, SCREEN_WIDTH, 160)];
                        [outImage setFrame:CGRectMake(SCREEN_WIDTH - uiImage.size.width - 60, 40, uiImage.size.width, uiImage.size.height)];
                        bubbleImage.frame = CGRectMake(outImage.frame.origin.x - 8,  30, outImage.frame.size.width + outMsgLabel.frame.size.width + 25, outImage.frame.size.height + outMsgLabel.frame.size.height + 25);
                        [cellFrame addSubview:bubbleImage];
                        [cellFrame addSubview:outImage];
                    outImage.userInteractionEnabled = false;
                    bubbleImage.userInteractionEnabled = false;
                    
                }
                else if ([msgType isEqualToString:@"voice"]){
                    outMsgLabel.text = @"语音";
                    [cellFrame setFrame:CGRectMake(0, 10, SCREEN_WIDTH, 160)];
                    [outImage setFrame:CGRectMake(SCREEN_WIDTH - uiImage.size.width - 60, 40, uiImage.size.width, uiImage.size.height)];
                    bubbleImage.frame = CGRectMake(outImage.frame.origin.x - 8,  30, outImage.frame.size.width + outMsgLabel.frame.size.width + 25, outImage.frame.size.height + outMsgLabel.frame.size.height + 25);
                    [cellFrame addSubview:bubbleImage];
                    [cellFrame addSubview:outImage];
                    outImage.userInteractionEnabled = false;
                    bubbleImage.userInteractionEnabled = false;
                                    cellFrame.backgroundColor = [UIColor redColor];
                    
                }
            }
            else {
//                cellFrame.backgroundColor = [UIColor blueColor];
                
                    [cellFrame setFrame:CGRectMake(0, 10, SCREEN_WIDTH, 160)];
                    [outImage setFrame:CGRectMake(SCREEN_WIDTH - uiImage.size.width - 60, 0, uiImage.size.width, uiImage.size.height)];
                    bubbleImage.frame = CGRectMake(outImage.frame.origin.x - 8,  -10, outImage.frame.size.width + outMsgLabel.frame.size.width + 25, outImage.frame.size.height + outMsgLabel.frame.size.height + 25);
                    [cellFrame addSubview:bubbleImage];
                    [cellFrame addSubview:outImage];
                }
            
            
            
        }
        else {
            [cellFrame setFrame:CGRectMake(0, 10, SCREEN_WIDTH, 160)];
            inImage.image = [UIImage imageNamed:@"icon"];
            [cellFrame addSubview:inImage];
        }
    }
    else
    {
        //*************文字************//
        [cellFrame setFrame:CGRectMake(0, 50, SCREEN_WIDTH, msgSize.height)];
        if ([[data objectForKey:@"obj"] isEqualToString:@"test1"]) {
            if (msgStr.length > 0) {
                bubbleImage.image = [[UIImage imageNamed:@"bubbleSomeone.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:14];
            }
            [outMsg setFrame:CGRectMake(60, 0, msgSize.width, msgSize.height)];
            bubbleImage.frame = CGRectMake(60 - 10,  - 4, outMsg.frame.size.width + 20, outMsg.frame.size.height + 15);
            outMsg.text = msgStr;
            [cellFrame addSubview:bubbleImage];
            [cellFrame addSubview:outMsg];
        }
        else {
            if (msgStr.length > 0) {
                bubbleImage.image = [[UIImage imageNamed:@"bubbleMine.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:14];
            }
            [inMsg setFrame:CGRectMake(SCREEN_WIDTH - msgSize.width - 60, 0, msgSize.width, msgSize.height)];
             bubbleImage.frame = CGRectMake(inMsg.frame.origin.x - 8,  - 4, inMsg.frame.size.width + 20, inMsg.frame.size.height + 15);
            inMsg.text = msgStr;
            [cellFrame addSubview:bubbleImage];
            [cellFrame addSubview:inMsg];
            cellFrame.backgroundColor = [UIColor blueColor];
        }
    }
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        cellFrame = [[UIView alloc] init] ;
        [self addSubview:cellFrame];
        
        inMsg = [[UILabel alloc] init] ;
        [inMsg setTextAlignment:NSTextAlignmentLeft];
        inMsg.font = [UIFont systemFontOfSize:17];
        inMsg.textColor = [UIColor blueColor];
        inMsg.backgroundColor = [UIColor clearColor];
        inMsg.numberOfLines = 0;
        
        outMsg = [[UILabel alloc] init] ;
        outMsg.textColor = [UIColor grayColor];
        [outMsg setTextAlignment:NSTextAlignmentLeft];
        outMsg.font = [UIFont systemFontOfSize:17];
        outMsg.backgroundColor = [UIColor clearColor];
        outMsg.numberOfLines = 0;
        
        outMsgLabel = [[UILabel alloc] init] ;
        outMsgLabel.textColor = [UIColor grayColor];
        [outMsgLabel setTextAlignment:NSTextAlignmentLeft];
        outMsgLabel.font = [UIFont systemFontOfSize:14];
        outMsgLabel.backgroundColor = [UIColor clearColor];
        outMsgLabel.numberOfLines = 0;
        
        inImage = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 180, 0, 120, 160)];
        outImage = [[UIImageView alloc] initWithFrame:CGRectMake(60, 0, 120, 160)];
        
        bubbleImage = [[UIImageView alloc] init] ;
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (UIImage *)reSizeImage:(UIImage *)image toSize:(CGSize)reSize{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [image drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return reSizeImage;
}

@end
