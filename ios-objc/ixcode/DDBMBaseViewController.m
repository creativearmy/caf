#import "DDBMBaseViewController.h"
//#import "UIImageView+WebCache.h"
//#import "SFTAppInfo.h"
typedef void (^btnAction)(void);



@interface DDBMBaseViewController ()
{
    btnAction leftBtnAction;
    btnAction rightBtnAction;
    btnAction secondRightBtnAction;
    btnAction secondLeftBtnAction;
    
    //    UFBMNavBarViewController * barViewControl;
}
@end

@implementation DDBMBaseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(changeStyle:) name:kChangeStyle object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserOporatrerNoti:) name:@"wcuser_oporator_notification" object:nil];
    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
        self.automaticallyAdjustsScrollViewInsets=NO;
    }
    [self createUI];
    [self createData];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"wcuser_oporator_notification" object:nil];
}


- (void)onUserOporatrerNoti:(NSNotification *)notification{
}

-(void)changeStyle:(NSNotification *)notification{
    NSLog(@"....");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addNavigatorTitle:(NSString*)title
{
    [self addNavigatorTitle:title parent:self.view];
}


- (void)addNavigatorTitle:(NSString*)title parent:(UIView*)parent
{
    self.barViewControl = [[DDBMNavBarViewController alloc]initNavigate:title];
    
    self.barViewControl.view.frame = CGRectMake(0, 0, self.view.frame.size.width, 64);
    NSLog(@"%@：%@",title,NSStringFromCGRect(self.barViewControl.view.frame));
    if (parent)
        [parent addSubview:self.barViewControl.view];
    else
        [self.view addSubview:self.barViewControl.view];
    [self addChildViewController:self.barViewControl];
    [self.barViewControl didMoveToParentViewController:self];
}

- (void)setNavTitle:(NSString*)title
{
    self.barViewControl.labTitle.text = title;
}

- (void)setBtnAction:(UIButton*) btn action:(void (^)(void))action isLeft:(BOOL)isLeft
{
    if (isLeft)
    {
        leftBtnAction = nil;
        leftBtnAction = [action copy];
        [btn addTarget:self action:@selector(btnLeftClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        rightBtnAction = nil;
        rightBtnAction = [action copy];
        [btn addTarget:self action:@selector(btnRightClick:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setBtnAction:(UIButton*) btn action:(void (^)(void))action isSecondLeft:(BOOL)isSecondLeft
{
    if (isSecondLeft == NO)
    {
        secondRightBtnAction = nil;
        secondRightBtnAction = [action copy];
        [btn addTarget:self action:@selector(secondBtnRightClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        secondLeftBtnAction = nil;
        secondLeftBtnAction = [action copy];
        [btn addTarget:self action:@selector(secondBtnLeftClick:) forControlEvents:UIControlEventTouchUpInside];
        
    }
}

- (void)setBtnImage:(UIButton*) btn title:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action isLeft:(BOOL)isLeft
{
    if (title) {
        btn.titleLabel.adjustsFontSizeToFitWidth = YES;//

        CGSize size = [self autoSizeOfTitle:title font:[UIFont fontWithName:@"Arial" size:19.0] size:CGSizeMake(1000, 44)];
        btn.frame = CGRectMake(btn.frame.origin.x, btn.frame.origin.y, size.width, btn.frame.size.height);

        if ([title  isEqual: @" edit"]) {
            btn.titleEdgeInsets = UIEdgeInsetsMake(25, 0, 0, 0);
        }
        
    }
    
    if (isLeft && !title) {

        //btn.frame = CGRectMake(20, 20, 64,64);
        btn.imageEdgeInsets = UIEdgeInsetsMake(25, 15, 0, 0);
    }
    //

    if (!isLeft && !title) {

        btn.imageEdgeInsets = UIEdgeInsetsMake(25, 0, 0, 0);
    }
    //btn.backgroundColor = [UIColor blueColor];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:normal] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:selected] forState:UIControlStateSelected];
    [btn setImage:[UIImage imageNamed:selected] forState:UIControlStateHighlighted];
    [self setBtnAction:btn action:action isLeft:isLeft];
    btn.hidden = NO;
}



- (void)setBtnImage:(UIButton*) btn title:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action isSecondLeft:(BOOL)isSecondLeft
{
    if (title) {
        btn.titleLabel.adjustsFontSizeToFitWidth = YES;//
        CGSize size = [self autoSizeOfTitle:title font:[UIFont fontWithName:@"Arial" size:17.0] size:CGSizeMake(1000, 44)];
        btn.frame = CGRectMake(btn.frame.origin.x, btn.frame.origin.y, size.width, 44);
    }
    
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:normal] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:selected] forState:UIControlStateSelected];
    [btn setImage:[UIImage imageNamed:selected] forState:UIControlStateHighlighted];
    [self setBtnAction:btn action:action isSecondLeft:NO];
    btn.hidden = NO;
}

- (void)btnLeftClick:(id)sender
{
    if (leftBtnAction)
        leftBtnAction();
}

- (void)secondBtnLeftClick:(id)sender
{
    if (secondLeftBtnAction)
        secondLeftBtnAction();
}


- (void)btnRightClick:(id)sender
{
    if (rightBtnAction)
        rightBtnAction();
}
- (void)secondBtnRightClick:(id)sender
{
    if (secondRightBtnAction)
        secondRightBtnAction();
}

- (void)AddSecondLeftBtnAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action
{
    if (!self.barViewControl) return;
    [self setBtnImage:self.barViewControl.btnSecondLeft title:title normal:normal selected:selected action:action isSecondLeft:YES];
}
- (void)AddSecondRightBtnAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action
{
    if (!self.barViewControl) return;
    [self setBtnImage:self.barViewControl.btnSecondRight title:title normal:normal selected:selected action:action isSecondLeft:NO];
}

- (void)AddLeftBtnAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action
{
    
    
    if (!self.barViewControl) return;
    [self setBtnImage:self.barViewControl.btnLeft title:title normal:normal selected:selected action:action isLeft:YES];
}

- (void)AddRightBtnAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action
{
    if (!self.barViewControl) return;
    [self setBtnImage:self.barViewControl.btnRight title:title normal:normal selected:selected action:action isLeft:NO];
}

- (void)setBtnBackgroundImage:(UIButton*) btn title:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action  isLeft:(BOOL)isLeft
{
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:normal] forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:selected] forState:UIControlStateSelected];
    [btn setBackgroundImage:[UIImage imageNamed:selected] forState:UIControlStateHighlighted];
    [self setBtnAction:btn action:action isLeft:isLeft];
    btn.hidden = NO;
}

- (void)AddLeftBtnBacgroundAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action
{
    if (!self.barViewControl) return;
    [self setBtnBackgroundImage:self.barViewControl.btnLeft title:title normal:normal selected:selected action:action isLeft:YES];
}

- (void)AddRightBtnBacgroundAction:(NSString*) title normal:(NSString*)normal selected:(NSString*)selected action:(void (^)(void))action
{
    if (!self.barViewControl) return;
    [self setBtnBackgroundImage:self.barViewControl.btnRight title:title normal:normal selected:selected action:action isLeft:NO];
}

//- (void)dealloc
//{
//    NSLog(@"----> %s,%d",__FUNCTION__,__LINE__);
//    leftBtnAction = nil;
//    rightBtnAction = nil;
//    //    [[DDNetWorkAPIClient sharedClient] popVC:self];
//}


-(void) showHUD:(NSString*) text
{
    self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_HUD];
    _HUD.delegate = self;
    _HUD.mode = MBProgressHUDModeText;
    //    _HUD.labelText = @"";
    _HUD.detailsLabelText = text;
    [_HUD show:YES];
    
    
}
-(void) hideHUD
{
    if(_HUD != nil)
    {
        [_HUD removeFromSuperview];
        _HUD.delegate = nil;
        _HUD = nil;
    }
}
-(void)delayHUD:(NSString *)text
{
    [self showHUD:text];
    [self performSelector:@selector(hideHUD) withObject:nil afterDelay:2.0];
}

- (void)delayHUDSecond: (NSString *)text {
    [self showHUD:text];
    [self performSelector:@selector(hideHUD) withObject:nil afterDelay:0.8];
    
}

-(void)showHUDIndeterminate {
    self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_HUD];
    _HUD.delegate = self;
    _HUD.mode = MBProgressHUDModeIndeterminate;
    [_HUD show:YES];
}



-(void)createUI
{
    
}
-(void)createData
{
    
}



-(float) xPostiong:(UIView *)view sp:(float)sp
{
    return view.frame.size.width+view.frame.origin.x + sp;
}

-(float) yPostiong:(UIView *)view sp:(float)sp
{
    return view.frame.size.height+view.frame.origin.y + sp;
}


-(CGSize) autoSizeOfTitle:(NSString *)title font:(UIFont *)font size:(CGSize)maxSize
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    NSDictionary *attributes = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle.copy};
    CGSize labelSize = [title boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
    return labelSize;
}

- (BOOL)shouldAutorotate
{
    return YES;
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}



//- (void)setProfile:(NSString *)profileString profileImage:(UIImageView *)imageView placeholderImage:(UIImage *)pImage{
////    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:SERVER_IMAGE_URL,profileString]];
//    if (!profileString) {
//        profileString = @"";
//    }
//    if ([profileString isEqual:[NSNull null]]) {
//        profileString = @"";
//    }
//    if ([profileString rangeOfString:@"http://"].location != NSNotFound) {
//        url = [NSURL URLWithString:profileString];
//    }
//    [imageView sd_setImageWithURL:url placeholderImage:pImage];
//}
@end
