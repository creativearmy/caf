//
//  i072ViewController.m
//  i072
//
//  Created by 寒光 on 15/12/11.
//  Copyright © 2015年 寒光. All rights reserved.
//
#import "AppDelegate.h"
#import "i072ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "NSObject+MJKeyValue.h"
#import "MBProgressHUD+ND.h"
#import "UIImageView+WebCache.h"

#import "HttpTool.h"

@interface i072ViewController ()<UIActionSheetDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UITextViewDelegate,UITextFieldDelegate,UIScrollViewDelegate>
{
    UIScrollView *scrollview;
    CGFloat width;
    NSString *imageData;
    NSMutableArray *_fileDataArray;
    NSFileManager *fileManager;//文件管理
    NSString *fileDirectory;//沙盒目录
    NSString *imageName;//存储图片名字
    int type;
    NSString *imageFid;
    NSMutableArray *_fields;
}
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIImageView *headFid;
@property (weak, nonatomic) IBOutlet UIButton *upheadFid;
@property (weak, nonatomic) IBOutlet UITextField *name;

@property (weak, nonatomic) IBOutlet UIImageView *manRight;
@property (weak, nonatomic) IBOutlet UIImageView *womanRight;
@property (weak, nonatomic) IBOutlet UITextField *phoneNo;
@property (weak, nonatomic) IBOutlet UITextField *provinceTextField;
@property (weak, nonatomic) IBOutlet UITextField *cityTextField;

@property (weak, nonatomic) IBOutlet UITextField *work_experience;

@property (weak, nonatomic) IBOutlet UITextField *addressTextField;
//@property (weak,nonatomic) NSMutableDictionary *update;
@property (weak,nonatomic) NSString *gender;

@property (weak, nonatomic) IBOutlet UIView *buttonView;

@property (nonatomic, strong) NSMutableArray *selectButtons;
@property (weak, nonatomic) IBOutlet UITextField *exucationTextField;
@property (weak, nonatomic) IBOutlet UITextField *paymentTextField;
@property (weak, nonatomic) IBOutlet UITextField *remarkTextField;


- (IBAction)man:(UIButton *)sender;
- (IBAction)woman:(UIButton *)sender;

- (IBAction)uphead:(UIButton *)sender;
@end

@implementation i072ViewController


#pragma mark -监听数据请求
- (void)addNotification {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(response_received)
                                                 name:globalConn.responseReceivedNotification object:nil];
}
- (void)response_received {
    //response模板
    NSString*ustr=globalConn.response[@"ustr"];
    if (ustr&&![ustr isEqualToString:@""]) {
        return;
    }
    NSLog(@"response: %@:%@ uerr:%@",
          [globalConn.response objectForKey:@"obj"],
          [globalConn.response objectForKey:@"act"],
          [globalConn.response objectForKey:@"uerr"]);
    
    // {"obj":"associate","act":"mock","to_login_name":"TOOLBOX_ACCOUNT","data":{"obj":"test","act":"output1","data":"blah"}}
    NSString*obj_act=[NSString stringWithFormat:@"%@_%@",globalConn.response[@"obj"],globalConn.response[@"act"]];
    
    if ([obj_act isEqualToString:@"person_update"]) {
        [self obLoginArrivedFromI072:globalConn.response];
        [self.navigationController popViewControllerAnimated:YES];
        
    }
    if ([obj_act isEqualToString:@"person_get"]) {
        [self refreshWithUserInfo:globalConn.response];
    }
    
    return;
}
-(void)refreshWithUserInfo:(JSONObject*)response
{
    
    JSONObject*data=[response o:@"data"];
    
    _fields = data[@"fields"];
    for (int i = 0; i < _buttonView.subviews.count; i++) {
        UIView *view = _buttonView.subviews[i];
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            //            NSLog(@"%@",button.titleLabel.text);
            for (NSString *title in _fields) {
                if ([title isEqualToString:button.titleLabel.text]) {
                    button.layer.borderWidth = 2.0f;
                    button.layer.borderColor = [UIColor blackColor].CGColor;
                }
            }
        }
        
    }
    
    self.phoneNo.text=[data s:@"phoneNo"];
    self.provinceTextField.text=[data s:@"province"];
    self.cityTextField.text=[data s:@"city"];
    self.addressTextField.text=[data s:@"address"];
    self.work_experience.text=[data s:@"work_experience"];
    self.exucationTextField.text =[data s:@"edu_experience"];
    self.paymentTextField.text =[data s:@"payment"];
    self.remarkTextField.text=[data s:@"singnature"];
    [self showSex:[data s:@"gender"]];
    
    NSURL *imageURL = [NSURL URLWithString:[[globalConn.server_info s:@"download_path"] stringByAppendingString:[data s:@"headFid"]]];
    [self.headFid sd_setImageWithURL:imageURL placeholderImage:[UIImage imageNamed:@"icon_head_example1.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
        self.headFid.image=image;
    }];

    self.name.text = [data s:@"name"];
    self.phoneNo.text = [data s:@"phoneNo"];

    
    [self showFields:[data a:@"fields"]];
}

-(void)showFields:(NSArray*)fields
{
    for (int i=0;i<17; i++) {
        UIButton*button= [self.view viewWithTag:1000+i];
        
        if ([self inArray:fields string:button.currentTitle]) {
            [self setUpSelectedButton:button];
        }
    }
    
}
-(BOOL)inArray:(NSArray*)array string:(NSString*)string
{
    for (int i=0; i<array.count; i++) {
        if ([string isEqualToString:array[i]]) {
            return YES;
        }
    }
    return NO;
    
}
-(void )obLoginArrivedFromI072:(JSONObject *)response {
    //    PersonUpdateReturn *UpdateReturn = [PersonUpdateReturn mj_objectWithKeyValues:notification.userInfo];
    if ([[response s:@"ustr"] isEqualToString:@""]){
        NSLog(@"%@",response[@"status"]);
    }
    else {
    }
}



#pragma mark -取消监听
-(void )removeNotification{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    [self addNotification];
    
    self.selectButtons = [@[] mutableCopy];
    
    for (UIView *view in self.buttonView.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            [self setUpLayerWithButton:button];
        }
    }
    
//    NSURL *imageURL = [WENetWork urlStrForFid:[globalConn user_info][@"headFid"]];
//    [self.headFid sd_setImageWithURL:imageURL placeholderImage:[UIImage imageNamed:@"icon_head_example2.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
//        self.headFid.image=image;
//    }];
    
//    self.name.text = [globalConn user_info][@"name"];
//    self.phoneNo.text = [globalConn user_info][@"phoneNo"];
    _headFid.layer.cornerRadius=_headFid.frame.size.width/2;
    _headFid.layer.masksToBounds=YES;
}

//-(void)input:(NSMutableDictionary*)date {
//    //发送数据
//    NSMutableDictionary *person_update = [NSMutableDictionary dictionary];
//
//    [person_update setObject:self.headFid.image forKey:@"headFid"];
//    [person_update setObject:self.name.text forKey:@"name"];
//    //    [person_update setObject:self.gender forKey:@"gender"];
//    [person_update setObject:self.phoneNo.text forKey:@"phoneNo"];
//    [person_update setObject:self.address.text forKey:@"address"];
//    [person_update setObject:self.work_experience.text forKey:@"work_experience"];
//    [person_update setObject:self.edu_experience.text  forKey:@"edu_experience"];
//    [person_update setObject:self.singnature.text  forKey:@"singnature"];
//    [person_update setObject:self.singnature.text forKey:@"singnature"];
//
//
//
//
//}

- (IBAction)adeptButtonClick:(UIButton *)sender {
    
    int count = 0;
        for (NSString *title in _fields) {
            if ([sender.titleLabel.text isEqualToString:title]) {
                count ++;
                NSMutableArray *temp = _fields.mutableCopy;
                [temp removeObject:title];
                _fields = temp;
                NSLog(@"--%@",_fields);
                [self setUpLayerWithButton:sender];
                [self.selectButtons removeObject:sender];
            }
        }
    if (count == 0) {
        [self.selectButtons addObject:sender];
        NSMutableArray *temp = _fields.mutableCopy;
        [temp addObject:sender.titleLabel.text];
        _fields = temp;
        [self setUpSelectedButton:sender];
    }
}

- (void)setUpSelectedButton:(UIButton *)button {
    button.layer.borderWidth = 2.0f;
    button.layer.borderColor = [UIColor blackColor].CGColor;
}

- (void)setUpLayerWithButton:(UIButton *)button {
    button.layer.borderWidth = 1.0f;
    button.layer.borderColor = [UIColor grayColor].CGColor;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    //代理
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    //获取屏幕宽度
    width = [UIScreen mainScreen].bounds.size.width;
    CGRect frame = [UIScreen mainScreen].bounds;
    self.mainView.frame =frame;
    scrollview = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 74, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.exucationTextField.delegate=self;
    self.paymentTextField.delegate=self;
    //    [self.address addTarget:self action:@selector(textChange:) forControlEvents:UIControlEventEditingChanged];
    //    [self.work_experience addTarget:scrollview action:@selector(textChange:) forControlEvents:UIControlEventEditingChanged];
    //    [self.edu_experience addTarget:scrollview action:@selector(textChange:) forControlEvents:UIControlEventEditingChanged];
    //
    //    self.address.delegate=self;
    
    // 隐藏水平滚动条
    scrollview.showsVerticalScrollIndicator = NO;
    scrollview.showsVerticalScrollIndicator = NO;
    //设置溢出区的范围,弹跳效果
    scrollview.bounces = NO;
    //    scrollview.backgroundColor = [UIColor redColor];
    scrollview.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    [self.mainView addSubview:scrollview];
    
    scrollview.delegate = self;
    NSArray *views = [[NSBundle mainBundle]loadNibNamed:@"i072View" owner:self options:nil];
    UIView *view1 = views[0];
    view1.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width,view1.frame.size.height);
    //    self.singnature.delegate =self;
    [scrollview addSubview:view1];
    scrollview.contentSize = CGSizeMake(view1.frame.size.width, view1.frame.size.height+80);
    scrollview.delegate = self;
    
    //    self.headFid.image = [UIImage imageNamed:@"icon_head"];
    NSNull *xnil = [NSNull null];
    
    //    self.headFid = @"headFid";
    //    if ([@"headFid" isEqual:xnil]) {
    //        self.headFid =@"headFid";
    //    }
    //
    //    else {
    //        self.headFid = @"1";
    //
    //    }
    
    
    
    //    发送数据
    //        NSMutableDictionary *person_update = [NSMutableDictionary dictionary];
    //
    //        [person_update setObject:self.headFid.image forKey:@"headFid"];
    //        [person_update setObject:self.name.text forKey:@"name"];
    //        [person_update setObject:self.gender forKey:@"gender"];
    //        [person_update setObject:self.phoneNo.text forKey:@"phoneNo"];
    //        [person_update setObject:self.address.text forKey:@"address"];
    //        [person_update setObject:self.work_experience.text forKey:@"work_experience"];
    //        [person_update setObject:self.edu_experience.text  forKey:@"edu_experience"];
    //        [person_update setObject:self.singnature.text  forKey:@"singnature"];
    //        [person_update setObject:self.singnature.text forKey:@"singnature"];
    //
    //
    //
    //
    //        [[WEPersonRequest shareInstance]person_update :@"o14477397324317851066" withJobId:person_update];
    //
    //        [[SFTJobRequest shareInstance]job_get_detail:self.person_id withPersonLongitude:self.person_longitude withPersonLatitude:self.person_latitude withJobId:self.job_id];
    
    
    NSMutableDictionary *req = [[NSMutableDictionary alloc] init];
    [req setObject:@"person" forKey:@"obj"];
    [req setObject:@"get" forKey:@"act"];
    
    if (self.person_id.length > 0) {
        //[req setObject:self.person_id forKey:@"person_id"];
    }else{
        //[req setObject:[globalConn user_info][@"_id"] forKey:@"person_id"];
    }
    
    //    [req setObject:person_update forKey:@"update_date"];
    //[globalConn send:req];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.remarkTextField resignFirstResponder];
    //    [self.work_experience resignFirstResponder];
    [self.exucationTextField resignFirstResponder];
    [self.work_experience resignFirstResponder];
    [self.paymentTextField resignFirstResponder];
    
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


- (IBAction)man:(UIButton *)sender {
    if (self.manRight.tag==10) {
        self.manRight.alpha=1;
        self.manRight.tag=11;
        self.gender =@"男";
        NSLog(@"%@",self.gender);
        self.womanRight.alpha=0;
        self.womanRight.tag=20;
    }
    
}
-(void)showSex:(NSString*)sex
{
    if([sex isEqualToString:@"男"])
    {
        self.manRight.alpha=1;
        self.manRight.tag=11;
        self.gender =@"男";
        NSLog(@"%@",self.gender);
        self.womanRight.alpha=0;
        self.womanRight.tag=20;
    }
    else
    {
        self.womanRight.alpha=1;
        self.womanRight.tag=21;
        self.gender =@"女";
        NSLog(@"%@",self.gender);
        
        self.manRight.alpha=0;
        self.manRight.tag=10;
    }
    
}
- (IBAction)woman:(UIButton *)sender {
    if (self.womanRight.tag==20) {
        self.womanRight.alpha=1;
        self.womanRight.tag=21;
        self.gender =@"女";
        NSLog(@"%@",self.gender);
        
        self.manRight.alpha=0;
        self.manRight.tag=10;
        
    }
}

#pragma mark - 键盘操作
//计算键盘弹起高度
- (void)keyboardWillChangeFrame:(NSNotification *)note{
    NSLog(@"%@",note.userInfo);
    
    //    self.PleaseEvaluation.alpha=0;
    CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    //获得键盘的最后的FRAME
    CGRect keyboardFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    //计算控制器的VIEW需要平移的距离
    CGFloat deltaY = keyboardFrame.origin.y - scrollview.frame.size.height;
    
    [UIView animateWithDuration:duration animations:^{
        scrollview.transform = CGAffineTransformMakeTranslation(0, deltaY);
    }];
    
}
//
//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
//    [self.singnature resignFirstResponder];
//}


//回车收起键盘
- (IBAction)qwe:(UITextField *)sender {
    
    
}

- (IBAction)qwer:(id)sender {
}


- (IBAction)return:(UITextField *)sender {
    
}





- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self]; //删除通知，很重要，否则会向僵尸对象发信息，导致闪退。
    
}

#pragma mark - 选择拍照或从相册选择

- (IBAction)uphead:(UIButton *)sender {
    //    UIActionSheet *action;
    //    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
    //        action = [[UIActionSheet alloc] initWithTitle:@" " delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照",@"从相册选择",nil];
    //    }
    //    else
    //    {
    //        action = [[UIActionSheet alloc] initWithTitle:@" " delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"从相册选择",nil];
    //    }
    //    [action showInView:self.view];
    
    UIActionSheet *action;
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        action = [[UIActionSheet alloc] initWithTitle:@"获取图片" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照",@"从相册选择",nil];
    }
    else
    {
        action = [[UIActionSheet alloc] initWithTitle:@"获取图片" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"从相册选择",nil];
    }
    [action showInView:self.view];
}
#pragma mark - 调用UIActionSheet iOS7使用

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSUInteger sourceType = 0;
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        switch (buttonIndex) {
            case 0:
                sourceType = UIImagePickerControllerSourceTypeCamera;
                break;
            case 1:
                sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                break;
            default:
                return;
        }
    }
    else{
        if (buttonIndex == 0) {
            sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        }
        else
            return;
    }
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = YES;
    imagePickerController.sourceType = sourceType;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}
#pragma mark - 确定所选择的图片
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    NSURL *imageURL = [info valueForKey:UIImagePickerControllerReferenceURL];
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        //        ALAssetRepresentation *representation = [myasset defaultRepresentation];
        //        NSString *fileName = [representation filename];
        //        imageName = [NSString stringWithFormat:@"%@",fileName];
    };
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
    [assetslibrary assetForURL:imageURL
                   resultBlock:resultblock
                  failureBlock:nil];
    [self performSelector:@selector(saveImage:) withObject:image afterDelay:0.5];
    [picker dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - 取消所选择的图片
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 保存图片到相应的位置上
- (void)saveImage:(UIImage *)image{
    
    
    
    self.headFid.image = image;
    
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [path firstObject];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"offersPhoto.jpg"];
    [UIImageJPEGRepresentation(image, 1.0f) writeToFile:imagePath atomically:YES];
    //获取相册图片
    UIImage *portrait = [UIImage imageWithContentsOfFile:imagePath];
    //获取图片的字节
    NSData *imageData = UIImageJPEGRepresentation(portrait, 1.0);
    Byte *bytes = (Byte *)[imageData bytes];
    //把图片的名字拆分
    NSArray *images = [imageName componentsSeparatedByString:@"."];
    //获取时间+8小时
    NSDate *date = [NSDate date];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate: date];
    NSDate *localeDate = [date  dateByAddingTimeInterval: interval];
    imageFid = [[NSString alloc]init];
    [HttpTool uploadImageWithUrl:[globalConn.server_info s:@"upload_to"] image:portrait success:^(id json) {
        
        NSData *imageData = UIImagePNGRepresentation(portrait);
        NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
        [user setObject:imageData forKey:@"portrait"];
        
        imageFid= [json valueForKey:@"fid"];
        imageName = [json valueForKey:@"filename"];
    }
                           failure:^(NSString *error){
                               return;
                           }];
    //    //发送数据的字典
    //    NSMutableDictionary *file_data = [[NSMutableDictionary alloc] init];
    //    [file_data setObject:imageFid forKey:@"file_fid"];
    //    [file_data setObject:[images[1] lowercaseString] forKey:@"file_type"];
    //    [file_data setObject:images[0] forKey:@"file_name"];
    //    [file_data setObject:[NSString stringWithFormat:@"%.2fMB",(int)bytes/(1048576*317.5)] forKey:@"file_size"];
    //    [file_data setObject:[NSString stringWithFormat:@"%f",[localeDate timeIntervalSince1970]] forKey:@"file_upload_time"];
    //    NSMutableDictionary *req = [[NSMutableDictionary alloc] init];
    //        [req setObject:@"project" forKey:@"obj"];
    //        [req setObject:@"fileUpload" forKey:@"act"];
    //        [req setObject:[globalConn user_info][@"_id"] forKey:@"project_id"];
    //        NSMutableDictionary *fileData = [[NSMutableDictionary alloc] init];
    //        [fileData setObject:[file_data objectForKey:@"file_fid"] forKey:@"file_fid"];
    //        [fileData setObject:[file_data objectForKey:@"file_type"] forKey:@"file_type"];
    //        [fileData setObject:[file_data objectForKey:@"file_name"] forKey:@"file_name"];
    //        [fileData setObject:[file_data objectForKey:@"file_size"] forKey:@"file_size"];
    //        [fileData setObject:[file_data objectForKey:@"file_upload_time"] forKey:@"file_upload_time"];
    //        [req setObject:fileData forKey:@"file_data"];
    //        [globalConn send:req];
    
}

#pragma mark - 限制字符数
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if (range.location>=5000)
    {
        return  NO;
    }
    else
    {
        return YES;
    }
}


-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    if (textField.text.length>300){
        return NO;
    }
    
    
    
    
    return YES;
}



@end
