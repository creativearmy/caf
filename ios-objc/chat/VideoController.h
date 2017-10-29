//
//  VideoController.h
//  SmallVideo
//
//  Created by swift on 16/4/22.
//  Copyright © 2016年 Xu Menghua. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol VideoComDelegate <NSObject>
@optional
- (void)finishRecordVideo:(NSString *)filePath mp4FilePath:(NSString *)mp4FilePath  mp4FileName:(NSString*)mp4FileName smallImage:(UIImage *)image;
- (void)cancelRecordVideo;
@end

@interface VideoController : UIViewController
-(void)convertToMP4;
-(void)playVideo;

@property(nonatomic, weak) id<VideoComDelegate> videoComDelegate;

@end
