//
//  ChatsViewCell.h
//  ixcode
//
//  Created by 田坛 on 16/5/7.
//  Copyright © 2016年 macmac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatsViewCell : UITableViewCell
- (void)setData: (NSDictionary *)data;

//image的frame
@property (nonatomic, assign)NSInteger giveHeight;

@end
