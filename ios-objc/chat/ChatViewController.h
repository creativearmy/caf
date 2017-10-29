//
//  ChatViewController.h
//  WeChat
//
//  Created by Jiao Liu on 11/25/13.
//  Copyright (c) 2013 Jiao Liu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "EGORefreshTableHeaderView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "MessageModel.h"
#import "AppDelegate.h"

@interface ChatViewController : UIViewController <
    UIAlertViewDelegate,
    UITableViewDataSource,
    UITextViewDelegate,
    UITableViewDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    EGORefreshTableHeaderDelegate,
    CLLocationManagerDelegate,
    UIGestureRecognizerDelegate>
{
    NSString *user;
    NSData *userImageData;
    EGORefreshTableHeaderView *_refreshHeaderView;
    BOOL _reloading;
    BOOL _isFirst;
}
@property (nonatomic, copy) NSString *obj; // mode: person, task, topic
@property (nonatomic, copy) NSString *to_id;
@property (nonatomic, retain) NSString *title_text;
@property (nonatomic, retain) NSData *userHeadImageData;
@property (nonatomic, copy) NSString *next_id;
- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;

@end
