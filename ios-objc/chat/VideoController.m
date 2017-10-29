//
//  ViewController.m
//  SmallVideo
//
//  Created by Xu Menghua on 15/12/4.
//  Copyright © 2015年 Xu Menghua. All rights reserved.
//

#import "VideoController.h"
#import "SmallVideoView.h"
#import "VideoModel.h"
#import <AVFoundation/AVFoundation.h>

@interface VideoController () <SmallVideoViewDelegate>

@property (nonatomic, strong) SmallVideoView *smallVideoView;
@property (nonatomic, strong) VideoModel *videoModel;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *mp4FilePath;
@property (nonatomic, strong) NSString *mp4FileName;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@end

@implementation VideoController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *_actionButton=[[UIBarButtonItem alloc]initWithTitle:@"确定" style:UIBarButtonItemStylePlain target:self action:@selector(convertToMP4)];
    self.navigationItem.rightBarButtonItem = _actionButton;
    self.smallVideoView = [SmallVideoView sharedSmallVideoView];
    self.smallVideoView.delegate = self;
    [self.view addSubview:self.smallVideoView];
    self.videoModel = [[VideoModel alloc] init];
    [self.videoModel setRecVideoAndVideoPreviewLayer:self.smallVideoView];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)convertToMP4{
    NSLog(@"%f", [self getFileSize:self.filePath]);
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:self.filePath] options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
        //NSLog(@"%@", resultPath);
        exportSession.outputURL = [NSURL fileURLWithPath:self.mp4FilePath];
        exportSession.outputFileType = AVFileTypeMPEG4;
        [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
         {
             switch (exportSession.status) {
                     
                 case AVAssetExportSessionStatusUnknown:
                     NSLog(@"AVAssetExportSessionStatusUnknown");
                     break;
                 case AVAssetExportSessionStatusWaiting:
                     NSLog(@"AVAssetExportSessionStatusWaiting");
                     break;
                 case AVAssetExportSessionStatusExporting:
                     NSLog(@"AVAssetExportSessionStatusExporting");
                     break;
                 case AVAssetExportSessionStatusFailed:
                     NSLog(@"AVAssetExportSessionStatusFailed error:%@", exportSession.error);
                     break;
                 case AVAssetExportSessionStatusCompleted:
                     NSLog(@"AVAssetExportSessionStatusCompleted");
                     NSLog(@"上传的MP4视频格式大小，单位是KB＝%f", [self getFileSize:self.mp4FilePath]);
                     dispatch_async(dispatch_get_main_queue(), ^{
                         AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:self.mp4FilePath]];
                         self.player = [AVPlayer playerWithPlayerItem:playerItem];
                         AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
                         playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                         playerLayer.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - ([UIScreen mainScreen].bounds.size.width * 3 / 4), [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width * 3 / 4);
                         [self.view.layer addSublayer:playerLayer];
                         self.playerLayer = playerLayer;
                         [self.videoComDelegate finishRecordVideo:self.filePath mp4FilePath:self.mp4FilePath mp4FileName:self.mp4FileName smallImage:[self getImage:self.mp4FilePath]];
                         [self.navigationController popViewControllerAnimated:true];
//                         [self playVideo];
                     });
                     break;
             }
             
//             [self.videoComDelegate finishRecordVideo];
         }];
    }
}

-(void)playVideo{
    //    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:self.mp4FilePath]];
    //    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    //    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    //    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //    playerLayer.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - ([UIScreen mainScreen].bounds.size.width * 3 / 4), [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width * 3 / 4);
    //    [self.view.layer addSublayer:playerLayer];
    self.player.volume = 1.0;
    [self.player play];//开始播放
    //    self.playerLayer = playerLayer;
}

- (void)startRecord {
    NSString *timeTikesName = [NSString stringWithFormat:@"%.f", ([[NSDate date] timeIntervalSince1970] * 1000)];
    NSString *filePath =  [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mov",timeTikesName]];
    self.filePath = filePath;
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];//用时间给文件全名，以免重复，在测试的时候其实可以判断文件是否存在若存在，则删除，重新生成文件即可
    [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    NSString* path = [NSString stringWithFormat:@"%@.mp4", [formater stringFromDate:[NSDate date]]];
    NSString *mp4FilePath =  [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", [formater stringFromDate:[NSDate date]]]];
    self.mp4FilePath = mp4FilePath;
    self.mp4FileName = path;
    [self.videoModel beginRecordSaveToTheDocumentFilePath:filePath];
    NSLog(@"开始录制");
}

- (void)finishRecord {
    NSLog(@"结束录制");
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self performSelector:@selector(convertToMP4) withObject:nil afterDelay:2.0f];
    }];
    
}

- (void)cancelRecord {
    NSLog(@"取消录制");
}
-(void)finishRecordexit
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

//此方法可以获取文件的大小，返回的是单位是KB
- (CGFloat)getFileSize:(NSString *)path
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    float filesize = -1.0;
    if ([fileManager fileExistsAtPath:path]) {
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil];//获取文件的属性
        unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
        filesize = 1.0*size/1024;
    }
    return filesize;
}

- (UIImage *)getImage:(NSString *)videoURL
{
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:videoURL];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:opts];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    generator.appliesPreferredTrackTransform = YES;
    NSError *error = nil;
    CGImageRef img = [generator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:NULL error:&error];
    UIImage *image = [UIImage imageWithCGImage: img];
    return [self reSizeImage:image toSize:CGSizeMake(100, 100)];
}

- (UIImage *)reSizeImage:(UIImage *)image toSize:(CGSize)reSize{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [image drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return reSizeImage;
}

@end
