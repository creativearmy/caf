//
//  MapLocationViewController.h
//  ixcode
//
//  Created by swift on 16/3/25.
//  Copyright © 2016年 macmac. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^LocationBlocak)(UIImage *mapImage, double latitude, double longitude, NSString *address);

@interface MapLocationViewController : UIViewController
@property(nonatomic, copy) LocationBlocak locationBlock;
@property(nonatomic) double latitude;
@property(nonatomic) double longitude;
@property(nonatomic) BOOL isSelectPoistion;
-(void)initData:(double)latitude longitude:(double)longitude  isSelectLocation:(BOOL)isSelectLocation;
@end
