//
//  CustomAnnotationView.h
//  ixcode
//
//  Created by swift on 16/3/25.
//  Copyright © 2016年 macmac. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>
#import "CustomCalloutView.h"

@interface CustomAnnotationView : MAAnnotationView

@property (nonatomic, readonly) CustomCalloutView *calloutView;

@end
