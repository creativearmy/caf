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
@property (nonatomic, copy) NSString *header_type; // chat(two person), group(more than two person), topic, ...
@property (nonatomic, copy) NSString *header_id; // For chat, it is pid of the other person, for others, it is the header record id
@property (nonatomic, retain) NSString *title_text;
@property (nonatomic, retain) NSData *userHeadImageData;
@property (nonatomic, copy) NSString *next_block_id;
- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;

@end
