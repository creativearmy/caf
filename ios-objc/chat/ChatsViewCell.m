//
//  ChatCell.m
//  WeChat
//
//  Created by Jiao Liu on 11/26/13.
//  Copyright (c) 2013 Jiao Liu. All rights reserved.
//

#import "AppDelegate.h"
#import "ChatsViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+Utility.h"
#import "PlayViewController.h"
#import "UIImageView+WebCache.h"
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
@implementation ChatsViewCell
{
    UILabel *inMsg;
    UILabel *outMsg;
    UILabel *outMsgLabel;
    UIImageView *inImage;
    UIImageView *outImage;
    UIImageView *bubbleImage;
    
    UIImageView *outAvatarImageView;
    UIView *cellFrame;
}

- (void)setData:(JSONObject *)data
{
    _raw_data = data;
    
    outAvatarImageView.layer.cornerRadius=outAvatarImageView.frame.size.width/2;
    outAvatarImageView.layer.masksToBounds=YES;
    if (data[@"from_avatar"]!=nil) {
        [outAvatarImageView sd_setImageWithURL:[NSURL URLWithString:[[globalConn.server_info s:@"download_path"] stringByAppendingString:[data s:@"from_avatar"]]] placeholderImage:[UIImage imageNamed:@"icon"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (image) {
                outAvatarImageView.image=image;
            }
        }];
    }
    
    //**************文字************//
    if ([[data s:@"mtype"] isEqualToString:@"text"]) {
        
        NSString * msgStr = [data s:@"content"];
        CGSize msgSize = [msgStr sizeWithFont:[UIFont systemFontOfSize:17] constrainedToSize:CGSizeMake(SCREEN_WIDTH - 70, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
        
        [cellFrame setFrame:CGRectMake(0, 50, SCREEN_WIDTH, msgSize.height)];
        
        if ([[data s:@"from_id"] isEqualToString:[globalConn.user_info s:@"_id"]]) {
            if (msgStr.length > 0) {
                bubbleImage.image = [[UIImage imageNamed:@"bubbleMine.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:7];
            }
            [inMsg setFrame:CGRectMake(SCREEN_WIDTH - msgSize.width - 70, 12, msgSize.width, msgSize.height)];
            bubbleImage.frame = CGRectMake(SCREEN_WIDTH - msgSize.width - 80,  5, inMsg.frame.size.width + 20, inMsg.frame.size.height + 15);
            inMsg.text = msgStr;
             [outAvatarImageView  setFrame:CGRectMake(SCREEN_WIDTH - 50, 0, 40, 40)];
            [cellFrame setFrame:CGRectMake(0, 10, SCREEN_WIDTH, outAvatarImageView.frame.size.height+30)];
           
            [cellFrame addSubview:outAvatarImageView];
            [self addSubview:bubbleImage];
            [self addSubview:inMsg];
        }
        else {
            if (msgStr.length > 0) {
                bubbleImage.image = [[UIImage imageNamed:@"bubbleSomeone.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:6];
            }
            [outMsg setFrame:CGRectMake(60, 12, msgSize.width, msgSize.height)];
            
            bubbleImage.frame = CGRectMake(60 - 10,  5, outMsg.frame.size.width + 20, outMsg.frame.size.height + 15);
            outMsg.text = msgStr;
            [cellFrame setFrame:CGRectMake(0, 10, SCREEN_WIDTH, outAvatarImageView.frame.size.height+30)];
            [outAvatarImageView  setFrame:CGRectMake(0, 0, 40, 40)];
            [cellFrame addSubview:outAvatarImageView];
            [cellFrame addSubview:bubbleImage];
            [cellFrame addSubview:outMsg];
        }
        
        self.giveHeight=CGRectGetHeight(bubbleImage.frame) + 20;
    }
    
    //**************图片************//
    if ([[data s:@"mtype"] isEqualToString:@"image"]) {
        
        if ([[data s:@"from_id"] isEqualToString:[globalConn.user_info s:@"_id"]]) {
            
            UIImage *uiImage = [data objectForKey:@"image"];
            
            outImage.image = uiImage;
            bubbleImage.image = [[UIImage imageNamed:@"bubbleMine.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:7];
            [cellFrame setFrame:CGRectMake(0, 10, SCREEN_WIDTH, 160)];
            [outImage setFrame:CGRectMake(SCREEN_WIDTH - uiImage.size.width - 60, 10, uiImage.size.width, uiImage.size.height)];
            bubbleImage.frame = CGRectMake(outImage.frame.origin.x - 8,  2, outImage.frame.size.width + outMsgLabel.frame.size.width + 25, outImage.frame.size.height + outMsgLabel.frame.size.height + 25);
            [cellFrame setFrame:CGRectMake(0, 10, SCREEN_WIDTH, bubbleImage.frame.size.height+22)];
             [outAvatarImageView  setFrame:CGRectMake(SCREEN_WIDTH - 50, bubbleImage.frame.size.height - 50, 40, 40)];
            [cellFrame addSubview:outAvatarImageView];
            [cellFrame addSubview:bubbleImage];
            [cellFrame addSubview:outImage];
            self.giveHeight=CGRectGetHeight(bubbleImage.frame);
            
        } else {
            UIImage *uiImage = [data objectForKey:@"image"];
            
            outImage.image = uiImage;
            bubbleImage.image = [[UIImage imageNamed:@"bubbleSomeone.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:6];

            [cellFrame setFrame:CGRectMake(0, 10, SCREEN_WIDTH, 240)];
            [outImage setFrame:CGRectMake(60, 10, uiImage.size.width, uiImage.size.height)];
            bubbleImage.frame = CGRectMake(outImage.frame.origin.x - 8,  2, outImage.frame.size.width + outMsgLabel.frame.size.width + 25, outImage.frame.size.height + outMsgLabel.frame.size.height + 25);
            [cellFrame setFrame:CGRectMake(0, 10, SCREEN_WIDTH, bubbleImage.frame.size.height+22)];
            [outAvatarImageView  setFrame:CGRectMake(0, bubbleImage.frame.size.height - 50, 40, 40)];

            [cellFrame addSubview:bubbleImage];
            [cellFrame addSubview:outImage];
            [cellFrame addSubview:outAvatarImageView];


            self.giveHeight=CGRectGetHeight(bubbleImage.frame);
            
        }
        NSLog(@"%zd",self.giveHeight);
    }
    
    //**************视屏************//
    if ([[data s:@"mtype"] isEqualToString:@"video"]) {
        
        JSONObject *content  = [data o:@"content"];
        NSData * imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[self getDownloadURL:[content s:@"thumb"]]]];
        UIImage *uiImage = [UIImage imageWithData:imgData];
        
        if ([[data s:@"from_id"] isEqualToString:[globalConn.user_info s:@"_id"]]) {
            
            outImage.image = uiImage;
             bubbleImage.image = [[UIImage imageNamed:@"bubbleMine.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:7];
            //                    cellFrame.backgroundColor = [UIColor orangeColor];
            [cellFrame setFrame:CGRectMake(0, 5, SCREEN_WIDTH, 160)];
            [outImage setFrame:CGRectMake(SCREEN_WIDTH - uiImage.size.width - 60, 10, uiImage.size.width, uiImage.size.height)];
            bubbleImage.frame = CGRectMake(outImage.frame.origin.x - 8,  2, outImage.frame.size.width + outMsgLabel.frame.size.width + 25, outImage.frame.size.height + outMsgLabel.frame.size.height + 25);
            [cellFrame setFrame:CGRectMake(0, 5, SCREEN_WIDTH, bubbleImage.frame.size.height+22)];
            [outAvatarImageView  setFrame:CGRectMake(SCREEN_WIDTH - 50, 0, 40, 40)];
            [cellFrame addSubview:outAvatarImageView];
            [cellFrame addSubview:bubbleImage];
            [cellFrame addSubview:outImage];
            outImage.userInteractionEnabled = false;
            bubbleImage.userInteractionEnabled = false;
            self.giveHeight=CGRectGetHeight(bubbleImage.frame);
            
        } else {
            
            bubbleImage.image = [[UIImage imageNamed:@"bubbleSomeone.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:6];
            outImage.image = uiImage;
            //                    cellFrame.backgroundColor = [UIColor orangeColor];
            [cellFrame setFrame:CGRectMake(0, 5, SCREEN_WIDTH, 160)];
            [outImage setFrame:CGRectMake(60, 10, uiImage.size.width, uiImage.size.height)];
            bubbleImage.frame = CGRectMake(outImage.frame.origin.x - 8,  2, outImage.frame.size.width + outMsgLabel.frame.size.width + 25, outImage.frame.size.height + outMsgLabel.frame.size.height + 25);
            [cellFrame setFrame:CGRectMake(0, 5, SCREEN_WIDTH, bubbleImage.frame.size.height+22)];
            [outAvatarImageView  setFrame:CGRectMake(0, 0, 40, 40)];
            [cellFrame addSubview:outAvatarImageView];
            [cellFrame addSubview:bubbleImage];
            [cellFrame addSubview:outImage];
            outImage.userInteractionEnabled = false;
            bubbleImage.userInteractionEnabled = false;
            self.giveHeight=CGRectGetHeight(bubbleImage.frame);
        }
    }

    //**************声音************//
    if ([[data s:@"mtype"] isEqualToString:@"voice"]){
         
         UIImage *uiImage = [UIImage imageNamed:@"mic.jpg"];
         
         if ([[data s:@"from_id"] isEqualToString:[globalConn.user_info s:@"_id"]]) {
             
             outImage.image = uiImage;
             bubbleImage.image = [[UIImage imageNamed:@"bubbleMine.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:7];
             //                    cellFrame.backgroundColor = [UIColor orangeColor];
             [cellFrame setFrame:CGRectMake(0, 5, SCREEN_WIDTH, 160)];
             [outImage setFrame:CGRectMake(SCREEN_WIDTH - uiImage.size.width*0.3 - 60, 10, uiImage.size.width*0.3, uiImage.size.height*0.3)];
             bubbleImage.frame = CGRectMake(outImage.frame.origin.x - 8,  2, outImage.frame.size.width + outMsgLabel.frame.size.width + 25, outImage.frame.size.height + outMsgLabel.frame.size.height + 25);
             [cellFrame setFrame:CGRectMake(0, 5, SCREEN_WIDTH, bubbleImage.frame.size.height+22)];
             [outAvatarImageView  setFrame:CGRectMake(SCREEN_WIDTH - 50, 0, 40, 40)];
             [cellFrame addSubview:outAvatarImageView];
             [cellFrame addSubview:bubbleImage];
             [cellFrame addSubview:outImage];
             outImage.userInteractionEnabled = false;
             bubbleImage.userInteractionEnabled = false;
             self.giveHeight=CGRectGetHeight(bubbleImage.frame);
             
         } else {
             outImage.image = uiImage;
             bubbleImage.image = [[UIImage imageNamed:@"bubbleSomeone.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:6];
             //                    cellFrame.backgroundColor = [UIColor orangeColor];
             [cellFrame setFrame:CGRectMake(0, 5, SCREEN_WIDTH, 160)];
             [outImage setFrame:CGRectMake(60, 10, uiImage.size.width*0.3, uiImage.size.height*0.3)];
             bubbleImage.frame = CGRectMake(outImage.frame.origin.x - 8,  2, outImage.frame.size.width + outMsgLabel.frame.size.width + 25, outImage.frame.size.height + outMsgLabel.frame.size.height + 25);
             [cellFrame setFrame:CGRectMake(0, 5, SCREEN_WIDTH, bubbleImage.frame.size.height+22)];
             [outAvatarImageView  setFrame:CGRectMake(0, 0, 40, 40)];
                                     [cellFrame addSubview:outAvatarImageView];
             [cellFrame addSubview:bubbleImage];
             [cellFrame addSubview:outImage];
             outImage.userInteractionEnabled = false;
             bubbleImage.userInteractionEnabled = false;
             self.giveHeight=CGRectGetHeight(bubbleImage.frame);
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
        outAvatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 50, 0, 40, 40)];
        outAvatarImageView.image = [UIImage imageNamed:@"Mushroom"];
        bubbleImage = [[UIImageView alloc] init] ;
        
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}


- (void)dealloc
{
}

- (UIImage *)reSizeImage:(UIImage *)image toSize:(CGSize)reSize{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [image drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return reSizeImage;
}

-(NSString*)getDownloadURL:(NSString*)fid{
    //对应的下载地址http://112.124.70.60:8081/cgi-bin/download.pl?fid=f14604307210058600902001&proj=demo
    NSString *serURL =  [globalConn.server_info s:@"download_path"];
    NSString* newStr = [NSString stringWithFormat:@"%@%@", serURL, fid];
    return newStr;
}

@end
