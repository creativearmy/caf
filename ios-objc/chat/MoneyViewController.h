//
//  MoneyViewController.h
//  ixcode
//
//  Created by swift on 16/4/11.
//  Copyright © 2016年 macmac. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^MoneyBlock)(double money, NSString* word);

@interface MoneyViewController : UIViewController <UITextFieldDelegate>
@property(nonatomic, copy) MoneyBlock moneyBlock;
@end
