#import "AppDelegate.h"
#import "i072ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "NSObject+MJKeyValue.h"
#import "MBProgressHUD+ND.h"
#import "UIImageView+WebCache.h"

#import "HttpTool.h"

// Demo HTTP post file upload to file server to get a fid to be used for other api calls.
// Set a breakpoint where HttoTool is used to observer the file upload process.
// Click on the i072 screen avatar to start uploading file from camera or album.

@interface i072ViewController ()<UIActionSheetDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UITextViewDelegate,UITextFieldDelegate,UIScrollViewDelegate>
{
    UIScrollView *scrollview;
    CGFloat width;
    NSString *imageData;
    NSMutableArray *_fileDataArray;
    NSFileManager *fileManager;
    NSString *fileDirectory;
    NSString *imageName;
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

- (void)response_received {

    NSString*ustr=globalConn.response[@"ustr"];
    if (ustr&&![ustr isEqualToString:@""]) {
        return;
    }
    NSLog(@"response: %@:%@ uerr:%@",
          [globalConn.response objectForKey:@"obj"],
          [globalConn.response objectForKey:@"act"],
          [globalConn.response objectForKey:@"uerr"]);
    
    if ([[globalConn.response s:@"obj"] isEqualToString:@"person"] && [[globalConn.response s:@"act"] isEqualToString:@"get"]) {
        [self refreshWithUserInfo:globalConn.response];
    }
    
    return;
}

-(void)refreshWithUserInfo:(JSONObject*)response
{
    JSONObject*data = [response o:@"data"];
    
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

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];

    NSLog(@"addObserver: %@", NSStringFromClass([self class]));
    [globalConn addObserver:self selector:@selector(response_received) name:globalConn.responseReceivedNotification object:nil];
    
    self.selectButtons = [@[] mutableCopy];
    
    for (UIView *view in self.buttonView.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            [self setUpLayerWithButton:button];
        }
    }
    
    _headFid.layer.cornerRadius=_headFid.frame.size.width/2;
    _headFid.layer.masksToBounds=YES;
}

- (IBAction)adeptButtonClick:(UIButton *)sender {
    
    int count = 0;
        for (NSString *title in _fields) {
            if ([sender.titleLabel.text isEqualToString:title]) {
                count ++;
                NSMutableArray *temp = _fields.mutableCopy;
                [temp removeObject:title];
                _fields = temp;
                NSLog(@"%@",_fields);
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
    
    [globalConn addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    width = [UIScreen mainScreen].bounds.size.width;
    CGRect frame = [UIScreen mainScreen].bounds;
    self.mainView.frame =frame;
    scrollview = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 74, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.exucationTextField.delegate=self;
    self.paymentTextField.delegate=self;

    scrollview.showsVerticalScrollIndicator = NO;
    scrollview.showsVerticalScrollIndicator = NO;

    scrollview.bounces = NO;
    scrollview.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    [self.mainView addSubview:scrollview];
    
    scrollview.delegate = self;
    NSArray *views = [[NSBundle mainBundle]loadNibNamed:@"i072View" owner:self options:nil];
    UIView *view1 = views[0];
    view1.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width,view1.frame.size.height);
    [scrollview addSubview:view1];
    scrollview.contentSize = CGSizeMake(view1.frame.size.width, view1.frame.size.height+80);
    scrollview.delegate = self;
    
    NSMutableDictionary *req = [[NSMutableDictionary alloc] init];
    [req setObject:@"person" forKey:@"obj"];
    [req setObject:@"get" forKey:@"act"];
    
    // [globalConn send;req]
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.remarkTextField resignFirstResponder];
    [self.exucationTextField resignFirstResponder];
    [self.work_experience resignFirstResponder];
    [self.paymentTextField resignFirstResponder];
    
}

- (IBAction)man:(UIButton *)sender {
    if (self.manRight.tag==10) {
        self.manRight.alpha=1;
        self.manRight.tag=11;
        self.gender =@"male";
        NSLog(@"%@",self.gender);
        self.womanRight.alpha=0;
        self.womanRight.tag=20;
    }
    
}
-(void)showSex:(NSString*)sex
{
    if([sex isEqualToString:@"male"])
    {
        self.manRight.alpha=1;
        self.manRight.tag=11;
        self.gender =@"male";
        NSLog(@"%@",self.gender);
        self.womanRight.alpha=0;
        self.womanRight.tag=20;
    }
    else
    {
        self.womanRight.alpha=1;
        self.womanRight.tag=21;
        self.gender =@"female";
        NSLog(@"%@",self.gender);
        
        self.manRight.alpha=0;
        self.manRight.tag=10;
    }
    
}

- (IBAction)woman:(UIButton *)sender {
    if (self.womanRight.tag==20) {
        self.womanRight.alpha=1;
        self.womanRight.tag=21;
        self.gender =@"female";
        NSLog(@"%@",self.gender);
        
        self.manRight.alpha=0;
        self.manRight.tag=10;
        
    }
}

- (void)keyboardWillChangeFrame:(NSNotification *)note{
    NSLog(@"%@",note.userInfo);
    
    //    self.PleaseEvaluation.alpha=0;
    CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    

    CGRect keyboardFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    

    CGFloat deltaY = keyboardFrame.origin.y - scrollview.frame.size.height;
    
    [UIView animateWithDuration:duration animations:^{
        scrollview.transform = CGAffineTransformMakeTranslation(0, deltaY);
    }];
    
}

- (IBAction)qwe:(UITextField *)sender {
}

- (IBAction)qwer:(id)sender {
}

- (IBAction)return:(UITextField *)sender {
    
}

- (void)dealloc{
    NSLog(@"removeObserver: %@", NSStringFromClass([self class]));
    [globalConn removeObserver:self];
}

- (IBAction)uphead:(UIButton *)sender {
    
    UIActionSheet *action;
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        action = [[UIActionSheet alloc] initWithTitle:@"Pick a photo" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Album",@"Album",nil];
    }
    else
    {
        action = [[UIActionSheet alloc] initWithTitle:@"Pick a photo" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Album",nil];
    }
    [action showInView:self.view];
}

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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    NSURL *imageURL = [info valueForKey:UIImagePickerControllerReferenceURL];
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
    };
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
    [assetslibrary assetForURL:imageURL
                   resultBlock:resultblock
                  failureBlock:nil];
    [self performSelector:@selector(saveImage:) withObject:image afterDelay:0.5];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveImage:(UIImage *)image{
    
    self.headFid.image = image;
    
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [path firstObject];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"offersPhoto.jpg"];
    [UIImageJPEGRepresentation(image, 1.0f) writeToFile:imagePath atomically:YES];
    
    UIImage *portrait = [UIImage imageWithContentsOfFile:imagePath];
    
    imageFid = [[NSString alloc]init];
    
    [HttpTool uploadImageWithUrl:[globalConn.server_info s:@"upload_to"] image:portrait
     
        success:^(id json) {
            NSData *portraitImg = UIImagePNGRepresentation(portrait);
            NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
            [user setObject:portraitImg forKey:@"portrait"];
        
            imageFid= [json valueForKey:@"fid"];
            imageName = [json valueForKey:@"filename"];
        }
     
        failure:^(NSString *error){
            return;
        }
     ];
}

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
