//
//  MoneyViewController.m
//  ixcode
//
//  Created by swift on 16/4/11.
//  Copyright © 2016年 macmac. All rights reserved.
//

#import "MoneyViewController.h"
#import "UIImage+Utility.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface MoneyViewController(){
    UITextField *moneyInput;
    UITextField *wordInput;
    UIButton *confirmBtn;
}

@end

@implementation MoneyViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"红包";
    self.view.backgroundColor =[UIColor whiteColor];
    UILabel *Label = [[UILabel alloc] init];
    Label.frame = CGRectMake(SCREEN_WIDTH/2 -30, 40, 60, 30);
    Label.text = @"红包";
    Label.textAlignment = NSTextAlignmentCenter;
    Label.font = [UIFont systemFontOfSize:20];
    [self.view addSubview:Label];
    
    
    UILabel *idLable = [[UILabel alloc] init];
    idLable.frame = CGRectMake(10, Label.frame.origin.y + Label.frame.size.height + 30, 80, 30);
    idLable.text = @"红包(元):";
    [self.view addSubview:idLable];
    moneyInput = [[UITextField alloc] initWithFrame:CGRectMake(90, Label.frame.origin.y + Label.frame.size.height + 30, SCREEN_WIDTH - 100, 30)];
    moneyInput.layer.borderWidth = 1;
    moneyInput.font = [UIFont systemFontOfSize:19];
    moneyInput.layer.borderColor = [UIColor grayColor].CGColor;
    moneyInput.layer.cornerRadius = 3;
    moneyInput.delegate = self;
    [self.view addSubview:moneyInput];
    
    UILabel *wordLabel = [[UILabel alloc] init];
    wordLabel.frame = CGRectMake(10, moneyInput.frame.origin.y + moneyInput.frame.size.height + 30, 80, 30);
    wordLabel.text = @"想说的话:";
    [self.view addSubview:wordLabel];
    wordInput = [[UITextField alloc] initWithFrame:CGRectMake(90, moneyInput.frame.origin.y + moneyInput.frame.size.height + 30, SCREEN_WIDTH - 100, 30)];
    wordInput.layer.borderWidth = 1;
    wordInput.font = [UIFont systemFontOfSize:19];
    wordInput.layer.borderColor = [UIColor grayColor].CGColor;
    wordInput.layer.cornerRadius = 3;
    wordInput.delegate = self;
    
    [self.view addSubview:wordInput];
    confirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, wordInput.frame.origin.y + wordInput.frame.size.height + 20, SCREEN_WIDTH/2 - 25, 40)];
    [confirmBtn setBackgroundImage:[UIImage generateColorImage:[UIColor lightGrayColor] size:confirmBtn.frame.size] forState:UIControlStateNormal];
    [confirmBtn setTitle:@"发送" forState:UIControlStateNormal];
    [confirmBtn setTintColor:[UIColor whiteColor]];
    confirmBtn.layer.cornerRadius = 3;
    [confirmBtn addTarget:self action:@selector(sendMoney) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:confirmBtn];
    
}

-(void)sendMoney {
    double money = [moneyInput.text doubleValue];
    self.moneyBlock(money, wordInput.text);
//    [self.navigationController popViewControllerAnimated:true];
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [moneyInput resignFirstResponder];
    [wordInput resignFirstResponder];
    return YES;
}

@end
