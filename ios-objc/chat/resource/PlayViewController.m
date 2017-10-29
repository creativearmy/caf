//
//  PlayViewController.m
//  ixcode
//
//  Created by swift on 16/4/22.
//  Copyright © 2016年 macmac. All rights reserved.
//
#import "PlayViewController.h"
#import "VideoController.h"
#import "SmallVideoView.h"
#import "VideoModel.h"
#import <AVFoundation/AVFoundation.h>

@interface PlayViewController()
@property (nonatomic, strong) NSString *mp4FilePath;
@property (nonatomic, strong) NSString *mp4FileURL;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@end

@implementation PlayViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *_actionButton=[[UIBarButtonItem alloc]initWithTitle:@"结束" style:UIBarButtonItemStylePlain target:self action:@selector(finishView)];
    self.navigationItem.rightBarButtonItem = _actionButton;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSLog(@"documentsDirectory=%@",documentsDirectory);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //NSString* path = [NSString stringWithFormat:@"%@/%@", documentsDirectory, self.mp4FileName];
    //self.mp4FilePath= path;
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self playVideo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)dealloc
{
    self.player = nil;
    self.playerLayer = nil;
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    self.playerItem = nil;
}

-(void)initData:(NSString *)url{
    self.mp4FileURL = url;
}

-(void)finishView{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)playVideo{
    //    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:self.mp4FilePath]];
    //    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    //    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    //    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //    playerLayer.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - ([UIScreen mainScreen].bounds.size.width * 3 / 4), [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width * 3 / 4);
    //    [self.view.layer addSublayer:playerLayer];

    //self.mp4FileURL=@"http://techslides.com/demos/sample-videos/small.mp4";
    NSLog(@"mp4FileURL: %@", self.mp4FileURL);
    self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.mp4FileURL]];

    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];

    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    playerLayer.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - ([UIScreen mainScreen].bounds.size.height * 3/ 4), [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width * 3 / 4);
    
    [self.view.layer addSublayer:playerLayer];
    self.playerLayer = playerLayer;
    //                         [self.videoComDelegate finishRecordVideo:self.filePath mp4FilePath:self.mp4FilePath mp4FileName:self.mp4FileName smallImage:[self getImage:self.mp4FilePath]];
    //                         [self.navigationController popViewControllerAnimated:true];

    self.player.volume = 1.0;
    
    // https://stevebranding.wordpress.com/2012/05/09/avplayer-in-depth/
    [self.player play];//开始播放
    //    self.playerLayer = playerLayer;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"KEY PATH    : %@", keyPath);
    NSLog(@"CHANGE      : %@", change);
    NSLog(@"status:%@", self.player.currentItem.error);
}

@end
