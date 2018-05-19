#import "ChatViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+Utility.h"
#import "TexstModel.h"
#import "AppDelegate.h"
#import "ChatsViewCell.h"
#import "ChatCell.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "Model.h"
#import "MapLocationViewController.h"
#import "MoneyViewController.h"
#import "RequestPostUploadHelper.h"
#import "VideoController.h"
#import "VideoModel.h"
#import <AVFoundation/AVFoundation.h>
#import "PlayViewController.h"
#import "LVRecordTool.h"
#import "lame.h"
#import "MBProgressHUD+ND.h"
#import "ShowChatImageView.h"
#import "UIImageView+WebCache.h"


#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define VERSION [[[UIDevice currentDevice] systemVersion] floatValue]



@interface ChatViewController ()<VideoComDelegate, LVRecordToolDelegate>

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
/** recording */
@property (nonatomic, strong) LVRecordTool *recordTool;
@end

NSString *TMP_UPLOAD_IMG_PATH=@"";

@implementation ChatViewController
{
    UILabel *title;
    
    UITableView *_panelMessages; // messages display area
    UIView *_panelMain; // main panel: voice button, text entry, plus button
    UIView *_panelPlus; // + button will activate _panelPlus
    UITextView *textInput; // overlap with _panelMain

    UIButton *recordingBtn;
    UIButton *recordBtn;
    BOOL isRecording;
    UIButton *playBtn;
    UIButton *cameraBtn;
    UIButton *moneyButton;
    
    NSString *chatLog;
    
    JSONArray *chat_entries;
    
    UILabel *timeLable;
    
    UIImage *sendImage;
    UIView *sendImageView;
    
    UIView *loadingView;
    
    MPMoviePlayerController *videoPlayer;
    UIWindow *backgroundWindow;
    
    AVAudioPlayer *player;
    AVAudioPlayer *cellAduioPlayer;
    AVAudioRecorder *recorder;
    NSURL *recordedFile;
    
    NSData *voiceData;
    
    NSString *queryTime;
    NSDate *queryDate;
    BOOL _panelPlusVisible;
    
    CLLocationManager *locationManager;
    NSString *videoName;
    
    BOOL isSendImage;
    
    ShowChatImageView*customCalloutView;
    
}
@synthesize title_text;
@synthesize userHeadImageData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        isRecording = NO;
        
        // FIXME: this does not work, [self setTitle];
        // delay is needed, maybe 2s
        [self performSelector:@selector(setTitle) withObject:nil afterDelay:1];
        
        chatLog = [[NSString alloc] init];
        chat_entries = [[JSONArray alloc] init];
        
        recordedFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"RecordedFile"]];
               self.view.backgroundColor = [UIColor grayColor];
    }
    return self;
}   
    
#pragma mark - show/dismiss moreView    
- (void)showAndDismissPanelPlus  
{
    NSInteger offset = VERSION >= 7.0 ? 20 : 0;
    if (_panelPlusVisible) { 
        [UIView animateWithDuration:0.3 animations:^{   
            _panelPlus.frame = CGRectOffset(_panelPlus.frame, 0, 216+36);
            _panelPlusVisible = NO;  
                
            CGFloat yOffset = 216+36;
            if (_panelMain.frame.origin.y == SCREEN_HEIGHT - 80 + offset) {
                [textInput resignFirstResponder];   
                return ;    
            }   
                
            CGRect inputFieldRect = _panelMain.frame;    
            CGRect tableRect = _panelMessages.frame;  
                
            inputFieldRect.origin.y += yOffset; 
            tableRect.size.height += yOffset;   
            _panelMessages.frame = tableRect; 
            _panelMain.frame = inputFieldRect;   
            if (_panelMessages.contentSize.height > _panelMessages.frame.size.height) { 
                [_panelMessages setContentOffset:CGPointMake(0, _panelMessages.contentSize.height - _panelMessages.frame.size.height) animated:YES];  
            }   
        }]; 
    }   
    else {
        _panelPlusVisible = YES;
        //float textview_to_botHight  = _textView.frame.origin.y+_textView.frame.size.height;
        if (isRecording) {
            isRecording = NO;
            [recordingBtn removeFromSuperview];
            [_panelMain addSubview:textInput];
            [recordBtn setImage:[UIImage imageNamed:@"mic.jpg"] forState:UIControlStateNormal];
        }else{
            [textInput resignFirstResponder];
        }
        
        CGFloat yOffset = -216-36;
        if (_panelMain.frame.origin.y == SCREEN_HEIGHT - 296 + offset|| _panelMain.frame.origin.y == SCREEN_HEIGHT - 296 - 24 * 1 + offset|| _panelMain.frame.origin.y == SCREEN_HEIGHT - 296 - 24 * 2 + offset) {
            [textInput resignFirstResponder];
            return ;
        }
        if (_panelMain.frame.origin.y == SCREEN_HEIGHT - 296 - 36 + offset|| _panelMain.frame.origin.y == SCREEN_HEIGHT - 296 - 36 - 24 * 1 + offset|| _panelMain.frame.origin.y == SCREEN_HEIGHT - 296 - 36 - 24 * 2 + offset) {
            [textInput resignFirstResponder];
            yOffset = 0;
        }
        
        CGRect inputFieldRect = _panelMain.frame;
        CGRect tableRect = _panelMessages.frame;
        
        inputFieldRect.origin.y += yOffset;
        tableRect.size.height += yOffset;
        if (_panelMessages.contentSize.height > _panelMessages.frame.size.height) {
            [_panelMessages setContentOffset:CGPointMake(0, _panelMessages.contentSize.height - _panelMessages.frame.size.height) animated:NO];
        }
        [UIView animateWithDuration:0.3 animations:^{
            _panelPlus.frame = CGRectOffset(_panelPlus.frame, 0, -216-36);
            _panelMessages.frame = tableRect;
            _panelMain.frame = inputFieldRect;
        }];
    }
    if (_panelMessages.contentSize.height > _panelMessages.frame.size.height) {
        [_panelMessages setContentOffset:CGPointMake(0, _panelMessages.contentSize.height - _panelMessages.frame.size.height) animated:YES];
    }
}

#pragma mark -  back to friendlist
- (void)backToPrev  
{   
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tableViewGoFooter
{
    if (_isFirst) {
        return;
    }
    if (_panelMessages.contentSize.height > _panelMessages.frame.size.height) {
        [_panelMessages setContentOffset:CGPointMake(0, _panelMessages.contentSize.height - _panelMessages.frame.size.height) animated:YES];
    }
}

#pragma mark - textInput delegate
- (void)textInputReturn
{
    if (_panelPlusVisible) {
        [self showAndDismissPanelPlus];
    }
    [textInput resignFirstResponder];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSLog(@"=======shouldChangeTextInRange======");

    CGRect textInputRect = textInput.frame;
    CGRect textViewRect = _panelMain.frame;
    CGRect tableRect = _panelMessages.frame;
    
    if ([text isEqualToString:@"\n"]) { // send btn
        // filter these two for now
        if (![textInput.text isEqualToString:@""] && ![textInput.text isEqualToString:@"\n"]) {
            
            NSString * input = textInput.text;
            // FIXME hack to remove leading space, "\n"
            input = [input stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            JSONObject * data = [[JSONObject alloc]init];
            [data setObject:@"message" forKey:@"obj"];
            [data setObject:self.header_id forKey:@"header_id"];
            
            if ([self.header_type isEqualToString:@"chat"]) {
                [data setObject:@"chat_send" forKey:@"act"];
            }
            if ([self.header_type isEqualToString:@"group"]){
                [data setObject:@"group_send" forKey:@"act"];
            }
            if ([self.header_type isEqualToString:@"topic"]){
                [data setObject:@"topic_send" forKey:@"act"];
            }
            [data setObject:@"text" forKey:@"mtype"];
            [data setObject:input forKey:@"content"];
            
            [globalConn send:data];
            
            [data setObject:[globalConn.user_info s:@"_id"] forKey:@"from_id"];
            [data setObject:self.header_id forKey:@"header_id"];
            [data setObject:@"text" forKey:@"mtype"];
            [data setObject:input forKey:@"content"];
            [chat_entries addObject:data];
            
            [_panelMessages reloadData];
            [self tableViewGoFooter];
        }
        
        textInput.text = @"";
//     
//        NSInteger offset = VERSION >= 7.0 ? 20 : 0;
//        
//        textInputRect.size.height = 40;
//        textInput.frame = textInputRect;
//        textViewRect.size.height = 60;
//        textViewRect.origin.y = SCREEN_HEIGHT - 80 + offset;
//        _textView.frame = textViewRect;
//        tableRect.size.height = SCREEN_HEIGHT - 120;
//        msgTable.frame = tableRect;
        return YES;
    }
    
    // adjust height of textView
    CGSize size = [textInput.text sizeWithFont:[UIFont systemFontOfSize:20] constrainedToSize:CGSizeMake(textInput.frame.size.width , CGFLOAT_MAX) lineBreakMode:NSLineBreakByCharWrapping];
    
    NSLog(@"IM textView:shouldChangeTextInRange size.height=%f, textInput.frame.size.height=%f", size.height, textInput.frame.size.height);
    
    if (size.height > textInput.frame.size.height - 16 && textInput.frame.size.height < 88) {
        textViewRect.size.height += 24;
        textViewRect.origin.y -= 24;
        _panelMain.frame = textViewRect;
        textInputRect.size.height += 24;
        textInput.frame = textInputRect;
        tableRect.size.height -= 24;
        _panelMessages.frame = tableRect;
    }
    if (textInput.frame.size.height > 40 && size.height < textInput.frame.size.height - 16) {
        textViewRect.size.height -= 24;
        textViewRect.origin.y += 24;
        _panelMain.frame = textViewRect;
        textInputRect.size.height -= 24;
        textInput.frame = textInputRect;
        tableRect.size.height += 24;
        _panelMessages.frame = tableRect;
    }
    return YES;
}

- (void)keyboardShow :(NSNotification *)notify
{
    NSDictionary *info = [notify userInfo];
    
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardFrame];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    [_panelMain setFrame:CGRectMake(_panelMain.frame.origin.x, self.view.frame.size.height - keyboardFrame.size.height-_panelMain.frame.size.height, _panelMain.frame.size.width, _panelMain.frame.size.height)];
    [_panelMessages setFrame:CGRectMake(_panelMessages.frame.origin.x, _panelMessages.frame.origin.y, _panelMessages.frame.size.width, _panelMessages.frame.size.height - keyboardFrame.size.height)];
    [UIView commitAnimations];
    if (_panelMessages.contentSize.height > _panelMessages.frame.size.height) {
        [_panelMessages setContentOffset:CGPointMake(0, _panelMessages.contentSize.height - _panelMessages.frame.size.height) animated:YES];
    }
}

- (void)keyboardDismiss: (NSNotification *)notify
{
    NSDictionary *info = [notify userInfo];
    
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardFrame];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    [_panelPlus setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, _panelPlus.frame.size.height)];
    [_panelMain setFrame:CGRectMake(_panelMain.frame.origin.x, _panelMain.frame.origin.y + keyboardFrame.size.height, _panelMain.frame.size.width, _panelMain.frame.size.height)];
    [_panelMessages setFrame:CGRectMake(_panelMessages.frame.origin.x, _panelMessages.frame.origin.y, _panelMessages.frame.size.width, _panelMessages.frame.size.height + keyboardFrame.size.height)];
    [UIView commitAnimations];
    if (_panelMessages.contentSize.height > _panelMessages.frame.size.height) {
        [_panelMessages setContentOffset:CGPointMake(0, _panelMessages.contentSize.height - _panelMessages.frame.size.height) animated:YES];
    }
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{

    BOOL needAnimation = YES;
    if(_panelPlusVisible == YES){
        needAnimation = NO;
    }
    
    NSDictionary *info = [notification userInfo];
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect beginKeyboardRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endKeyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGFloat yOffset;
    
    yOffset = endKeyboardRect.origin.y - beginKeyboardRect.origin.y;
    NSLog(@"IM keyboardWillChangeFrame yOffset=%f", yOffset);

    CGRect inputFieldRect = _panelMain.frame;
    CGRect tableRect = _panelMessages.frame;
    
    // validate yOffset, fail safe, at least it will not fall off the screen
    if (inputFieldRect.origin.y + yOffset < 0) {
        yOffset = 100 - inputFieldRect.origin.y;
    }
    if (inputFieldRect.origin.y + yOffset > (self.view.frame.size.height-_panelMain.frame.size.height)) {
        yOffset = self.view.frame.size.height-_panelMain.frame.size.height - inputFieldRect.origin.y;
    }
    
    inputFieldRect.origin.y += yOffset;
    tableRect.size.height += yOffset;
    
    if(needAnimation==YES){
        [UIView animateWithDuration:duration animations:^{
            _panelMain.frame = inputFieldRect;
            _panelMessages.frame = tableRect;
        }];
        if (_panelMessages.contentSize.height > _panelMessages.frame.size.height) {
            [_panelMessages setContentOffset:CGPointMake(0, _panelMessages.contentSize.height - _panelMessages.frame.size.height) animated:YES];
        }
    }
    else{
        _panelMain.frame = inputFieldRect;
        _panelMessages.frame = tableRect;
        if (_panelMessages.contentSize.height > _panelMessages.frame.size.height) {
            [_panelMessages setContentOffset:CGPointMake(0, _panelMessages.contentSize.height - _panelMessages.frame.size.height) animated:YES];
        }
    }
    
}

- (void)keyboardWillChangeFrame_DEPRECATED:(NSNotification *)notification
{
    /* UIKeyboardWillChangeFrameNotification - keyborad pop up /retract
     
     1. during switching of keyboard from English to Chinese
     
     beginKeyboardRect	CGRect	(origin = (x = 0, y = 315), size = (width = 320, height = 253))	
     endKeyboardRect	CGRect	(origin = (x = 0, y = 316), size = (width = 320, height = 252))	
     
     2. during switching of keyboard from Chinese to English
     
     beginKeyboardRect	CGRect	(origin = (x = 0, y = 316), size = (width = 320, height = 252))
     endKeyboardRect	CGRect	(origin = (x = 0, y = 315), size = (width = 320, height = 253))	
     
     3. during switching of keyboard from English to Menu
     
     beginKeyboardRect	CGRect	(origin = (x = 0, y = 315), size = (width = 320, height = 253))
     endKeyboardRect	CGRect	(origin = (x = 0, y = 568), size = (width = 320, height = 253))	
     
     4. during switching of keyboard from Chinese to Menu

     beginKeyboardRect	CGRect	(origin = (x = 0, y = 316), size = (width = 320, height = 252))
     endKeyboardRect	CGRect	(origin = (x = 0, y = 568), size = (width = 320, height = 252))
     
     */
    
    BOOL needAnimation = YES;
    if(_panelPlusVisible == YES){
        needAnimation = NO;
    }
    
    NSDictionary *info = [notification userInfo];
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect beginKeyboardRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endKeyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGFloat yOffset;
    
    // - keyborad pop up /retract
    // use 10 to account for the minor difference of Chinese and English keyboard
    
    //if(endKeyboardRect.origin.y - beginKeyboardRect.origin.y<0){
    if(endKeyboardRect.origin.y - beginKeyboardRect.origin.y < -10){
        //表示键盘弹出;
        _panelPlusVisible = NO;
        yOffset = endKeyboardRect.origin.y - beginKeyboardRect.origin.y + (self.view.frame.size.height-_panelMain.frame.origin.y-_panelMain.frame.size.height);
    }else{
        //表示键盘回收
        [_panelPlus setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, _panelPlus.frame.size.height)];//隐藏moreview
        yOffset = endKeyboardRect.origin.y - beginKeyboardRect.origin.y;
    }
    NSInteger offset = VERSION >= 7.0 ? 20 : 0;
    
    if (yOffset == -216-36 && _panelPlusVisible) {
        _panelPlus.frame = CGRectOffset(_panelPlus.frame, 0, 216+36);
        _panelPlusVisible = NO;
    }
    if ((yOffset == -216-36 && _panelMain.frame.origin.y == SCREEN_HEIGHT - 296-36 - 24 * 1  + offset) || (yOffset == -216-36 && _panelMain.frame.origin.y == SCREEN_HEIGHT - 296-36 - 24 * 2 + offset) || (yOffset == -216-36 && _panelMain.frame.origin.y == SCREEN_HEIGHT - 296-36 + offset) || (yOffset == 216 && _panelPlusVisible)) {
        return;
    }
    if (yOffset == 252 && _panelPlusVisible) {
        return;
    }
    
    CGRect inputFieldRect = _panelMain.frame;
    CGRect tableRect = _panelMessages.frame;
    NSLog(@"IM keyboardWillChangeFrame yOffset=%f", yOffset);
    
    // validate yOffset, fail safe, at least it will not fall off the screen
    if (inputFieldRect.origin.y + yOffset < 0) {
        yOffset = 100 - inputFieldRect.origin.y;
    }
    if (inputFieldRect.origin.y + yOffset > (self.view.frame.size.height-_panelMain.frame.size.height)) {
        yOffset = self.view.frame.size.height-_panelMain.frame.size.height - inputFieldRect.origin.y;
    }
    
    inputFieldRect.origin.y += yOffset;
    tableRect.size.height += yOffset;
    
    if(needAnimation==YES){
        [UIView animateWithDuration:duration animations:^{
            _panelMain.frame = inputFieldRect;
            _panelMessages.frame = tableRect;
        }];
        if (_panelMessages.contentSize.height > _panelMessages.frame.size.height) {
            [_panelMessages setContentOffset:CGPointMake(0, _panelMessages.contentSize.height - _panelMessages.frame.size.height) animated:YES];
        }
    }
    else{
        _panelMain.frame = inputFieldRect;
        _panelMessages.frame = tableRect;
        if (_panelMessages.contentSize.height > _panelMessages.frame.size.height) {
            [_panelMessages setContentOffset:CGPointMake(0, _panelMessages.contentSize.height - _panelMessages.frame.size.height) animated:YES];
        }
    }
    
}

#pragma mark - prepare for view
- (void)setTitle
{
    title.text = title_text;
    self.title = title_text;
}

#pragma mark - tableView delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return chat_entries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JSONObject* row_data = [chat_entries o:(int)indexPath.row];
    
    NSString *cellId = [NSString stringWithFormat:@"MsgCell%ld",(long)indexPath.row];
    ChatsViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    
    if (!cell) {
        cell = [[ChatsViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    [cell setData:row_data];
    
    return cell;
}

- (void)longPress:(UILongPressGestureRecognizer *)sender
{
    // only when gesture was recognized, not when ended
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        // get affected cell
        //ChatsViewCell *cell = (ChatsViewCell *)[gesture view];
        CGPoint pressPoint = [sender locationInView:_panelMessages];
        NSIndexPath *indexPath = [_panelMessages indexPathForRowAtPoint:pressPoint];
        
        if (indexPath == nil) {
            return;
        }
        ChatsViewCell *cell = (ChatsViewCell *)[_panelMessages cellForRowAtIndexPath:indexPath];
        if (cell != nil && cell.raw_data != nil && [[cell.raw_data s:@"mtype"] isEqualToString:@"text"]) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            [pasteboard setString: [cell.raw_data s:@"content"]];
            [MBProgressHUD showTextOnly:@"拷贝到剪贴版了"];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  
    NSLog(@"didSelectRowAtIndexPath");
    [self textInputReturn];
    JSONObject *row_data = [chat_entries objectAtIndex:indexPath.row];
    
    NSString *msgType = [row_data s:@"mtype"];

    if ([msgType isEqualToString:@"video"]) {
        NSString *video_url = [self getDownloadURL:[[row_data o:@"content"] s:@"fid"]];
        [self playViewVideoURL:video_url];
    }
    
    if ([msgType isEqualToString:@"voice"]) {
        //NSString *voiceName1 = [row_data s:@"filename"];
        NSString*s= [NSURL URLWithString:[[globalConn.server_info s:@"download_path"] stringByAppendingString:[row_data s:@"content"]]].absoluteString;
        // play voice over the net direct - streaming
        [self soundPlay:s];
        //[self palySoundVoice:voiceName];
    }

    if([msgType isEqualToString:@"image"])
    {
        // if data not compatible, skip
        NSString *fid = [[row_data o:@"content"] s:@"fid"];
        if ([fid isEqualToString:@""]) return;
        
        if(customCalloutView)[customCalloutView removeFromSuperview];
        customCalloutView=[[ShowChatImageView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        [self.view addSubview:customCalloutView];
        [customCalloutView.portraitView sd_setImageWithURL:[NSURL URLWithString:[[globalConn.server_info s:@"download_path"] stringByAppendingString:fid]]
                                          placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if(image){customCalloutView.portraitView.image=image;}
        }];
    }
}

-(void)palySoundVoice:(NSString*)voiceName{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSLog(@"documentsDirectory=%@",documentsDirectory);
    NSString* audioPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, voiceName];
    LVRecordTool* recordTools = [LVRecordTool sharedRecordTool];
    recordTools.delegate = self;
    [recordTools setURLVoice:[[NSURL alloc] initFileURLWithPath:audioPath]];
    [recordTools playRecordingFile];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    ChatsViewCell *cell = (ChatsViewCell*)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    NSDictionary *data = [chat_entries objectAtIndex:indexPath.row];
    [cell setData:data];
    return cell.giveHeight+25;
 
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    _panelMessages.tableHeaderView = timeLable;
    return timeLable;
}

-(void)inputMoney{
    MoneyViewController *control = [[MoneyViewController alloc]init];
    control.moneyBlock = ^(double money, NSString* word){
        NSLog(@"----money----%f", money);
        if (money > 0.0) {
            JSONObject * data = [[JSONObject alloc]init];
            UIImage *moneyImage = [self reSizeImage:[UIImage imageNamed:@"money"] toSize:CGSizeMake(40, 40)];
            
            [data setObject:@"test2" forKey:@"obj"];
            [data setObject:@"input1" forKey:@"act"];
            [data setObject:moneyImage forKey:@"image"];
            [data setObject:@"money" forKey:@"msgType"];
            [data setObject:word forKey:@"word"];
            [data setObject:[NSString stringWithFormat:@"%@",[NSDate date]] forKey:@"date"];
            
            [chat_entries addObject:data];
            [_panelMessages reloadData];
            [self tableViewGoFooter];
            dispatch_async(dispatch_get_main_queue(), ^{
                
            });
        }
    };
    [self presentViewController:control animated:YES completion:^{}];
}


-(NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *err;
    
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

//file size kb
- (CGFloat)getFileSize:(NSString *)path
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    float filesize = -1.0;
    if ([fileManager fileExistsAtPath:path]) {
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil];
        unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
        filesize = 1.0*size/1024;
    }
    return filesize;
}

-(void)playViewVideoURL:(NSString*)url{
    PlayViewController *ctrol = [[PlayViewController alloc]init];
    [ctrol initData:url];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:ctrol];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - video
- (void)finishRecordVideo:(NSString *)filePath mp4FilePath:(NSString *)mp4FilePath mp4FileName:(NSString *)mp4FileName  smallImage:(UIImage *)smallImage{
//    NSLog(@"=recordVideo===== filePath=%@", filePath);
//    NSLog(@"=recordVideo===== mp4FilePath=%@", mp4FilePath);
//    NSLog(@"=recordVideo thumb===== smallImage=%@", smallImage);
    UIImageView *imageView = [[UIImageView alloc]init];
    imageView.frame = CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/3, 100, 100);
    imageView.image = smallImage;
    imageView.userInteractionEnabled = true;
//    [self.videoName ]
    videoName= mp4FileName;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSLog(@"documentsDirectory=%@",documentsDirectory);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString* path = [NSString stringWithFormat:@"%@/%@", documentsDirectory, mp4FileName];
    NSData *data = [fileManager contentsAtPath:path];
    
    if (data != nil) {
        NSDictionary *dictionaryWithJsonString = [self upLoadVideoToServer:data videoName:mp4FileName];
        NSString *fid;
        NSString *filename;
        if (dictionaryWithJsonString != nil) {
            NSLog(@"video return fid=%@,fileName=%@", [dictionaryWithJsonString objectForKey:@"fid"], [dictionaryWithJsonString objectForKey:@"filename"]);
            if ([dictionaryWithJsonString objectForKey:@"fid"] != nil) {
                fid = [dictionaryWithJsonString objectForKey:@"fid"];
            }
            if ([dictionaryWithJsonString objectForKey:@"filename"] != nil) {
                filename = [dictionaryWithJsonString objectForKey:@"filename"];
            }

            
            NSDictionary *dictionaryWithJsonString = [self upLoadImageToServer:smallImage];
            
            NSDictionary *content = @{
                                           @"fid":fid,
                                           @"thumb":dictionaryWithJsonString[@"fid"]
                                           };

            JSONObject * data = [[JSONObject alloc]init];
            
            //[data setObject:smallImage forKey:@"image"];
            //[data setObject:fid forKey:@"content"];
            [data setObject:content forKey:@"content"];
            
            [data setObject:@"video" forKey:@"mtype"];
            //[data setObject:filename forKey:@"filename"];
            [data setObject:[globalConn.user_info s:@"_id"] forKey:@"from_id"];
            [data setObject:[globalConn.user_info s:@"name"] forKey:@"from_name"];
            [data setObject:[globalConn.user_info s:@"headFid"] forKey:@"from_avatar"];
            [chat_entries addObject:data];
            
            [_panelMessages reloadData];
            [self tableViewGoFooter];
            
            [self getDownloadURL:fid];
            NSMutableDictionary * sendData = [[NSMutableDictionary alloc]init];
            
            [sendData setObject:[NSString stringWithFormat:@"%@",[NSDate date]] forKey:@"date"];
            [sendData setObject:@"message" forKey:@"obj"];
            [sendData setObject:self.header_id forKey:@"header_id"];
            
            if ([self.header_type isEqualToString:@"chat"]) {
                [sendData setObject:@"chat_send" forKey:@"act"];
            }
            if ([self.header_type isEqualToString:@"group"]){
                [sendData setObject:@"group_send" forKey:@"act"];
            }
            if ([self.header_type isEqualToString:@"topic"]){
                [sendData setObject:@"topic_send" forKey:@"act"];
            }
            [sendData setObject:@"video" forKey:@"mtype"];
            [sendData setObject:content forKey:@"content"];
            
            [globalConn send:sendData];
            NSLog(@"return fid=%@,fileName=%@", [dictionaryWithJsonString objectForKey:@"fid"], [dictionaryWithJsonString objectForKey:@"filename"]);
            
        }
    }
    else {
        NSLog(@"finishRecordVideo fail");
    }
    
}

- (void)cancelRecordVideo{
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if([NSStringFromClass([touch.view class]) isEqualToString:@"UIView"]){
        return NO;
    }
    return YES;
}
#pragma mark - PickImage/Video

#pragma mark video
- (void)recordVideo
{
    NSLog(@"=======recordVideo======");
        VideoController * videoCtl = [[VideoController alloc]init];
        videoCtl.videoComDelegate = self;
        [self presentViewController:videoCtl animated:YES completion:^{
            
        }];
}

- (void)cameraCapture
{
    NSLog(@"=======cameraCapture======");
    [self textInputReturn];
    UIImagePickerController *imagepicker = [[UIImagePickerController alloc] init];
    imagepicker.delegate = self;
    imagepicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:imagepicker animated:YES completion:^{
        NSLog(@"=======上传---cameraCapture");
    }];
    
}

- (void)pickImage
{
    NSLog(@"=======pickImage======");
    [self textInputReturn];
    UIImagePickerController *imagepicker = [[UIImagePickerController alloc] init];
    imagepicker.delegate = self;
    imagepicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagepicker animated:YES completion:^{
        NSLog(@"=======上传---pickImage");
    }];
}

-(NSString*)getDownloadURL:(NSString*)fid{

    NSString *serURL =  [globalConn.server_info s:@"download_path"];
    NSString* newStr = [NSString stringWithFormat:@"%@%@", serURL, fid];
    return newStr;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
     NSString* mediaType = [info objectForKey:@"UIImagePickerControllerMediaType"];
     if ([mediaType isEqualToString:(NSString *)kUTTypeImage]){
        UIImage *img=[info objectForKey:@"UIImagePickerControllerOriginalImage"];
         UIImage* sizeImage = [self reSizeImage:img toSize:CGSizeMake(150, 150)];
        UIImage *newImg=[RequestPostUploadHelper imageWithImageSimple:sizeImage scaledToSize:CGSizeMake(200, 200)];
        if(picker.sourceType==UIImagePickerControllerSourceTypeCamera){
            //        UIImageWriteToSavedPhotosAlbum(img,nil,nil,nil);
            
        }
         
        NSDictionary *dictionaryWithJsonString = [self upLoadImageToServer:img];
        NSString *fid;
        NSString *filename;
        if (dictionaryWithJsonString != nil) {
            NSLog(@"pickImage return fid=%@,fileName=%@", [dictionaryWithJsonString objectForKey:@"fid"], [dictionaryWithJsonString objectForKey:@"filename"]);
            if ([dictionaryWithJsonString objectForKey:@"fid"] != nil) {
                fid = [dictionaryWithJsonString objectForKey:@"fid"];
            }
            if ([dictionaryWithJsonString objectForKey:@"filename"] != nil) {
                filename = [dictionaryWithJsonString objectForKey:@"filename"];
            }
        }
        
        JSONObject * data = [[JSONObject alloc]init];
        [data setObject:@"image" forKey:@"mtype"];
        [data setObject:newImg forKey:@"image"];
//        [data setObject:fid forKey:@"content"];
        [data setObject:filename forKey:@"filename"];
        [data setObject:[globalConn.user_info s:@"_id"] forKey:@"from_id"];
        [data setObject:[globalConn.user_info s:@"headFid"] forKey:@"from_avatar"];
//         data[@"fid"]=dictionaryWithJsonString[@"fid"];
//         data[@"thumb"]=dictionaryWithJsonString[@"thumb"];
         data[@"content"]=@{@"fid":dictionaryWithJsonString[@"fid"],@"thumb":dictionaryWithJsonString[@"thumb"]};
        [chat_entries addObject:data];
        [_panelMessages reloadData];
        [self tableViewGoFooter];
         isSendImage = YES;
        [self dismissViewControllerAnimated:YES completion:^{
             
             
        }];
         
         
         NSMutableDictionary * sendData = [[NSMutableDictionary alloc]init];
    
         [sendData setObject:[NSString stringWithFormat:@"%@",[NSDate date]] forKey:@"date"];
         [sendData setObject:@"message" forKey:@"obj"];
         [sendData setObject:self.header_id forKey:@"header_id"];
         
         if ([self.header_type isEqualToString:@"chat"]) {
             [sendData setObject:@"chat_send" forKey:@"act"];
         }
         if ([self.header_type isEqualToString:@"group"]){
             [sendData setObject:@"group_send" forKey:@"act"];
         }
         if ([self.header_type isEqualToString:@"topic"]){
             [sendData setObject:@"topic_send" forKey:@"act"];
         }
         
         [sendData setObject:@"image" forKey:@"mtype"];
         sendData[@"content"]=@{@"fid":fid,@"thumb":dictionaryWithJsonString[@"thumb"],@"mime":dictionaryWithJsonString[@"type"]};
         [globalConn send:sendData];
         
         
        //[self getDownloadURL:fid];
        NSLog(@"服务器返回rrr：fid=%@,fileName=%@", [dictionaryWithJsonString objectForKey:@"fid"], [dictionaryWithJsonString objectForKey:@"filename"]);
    }
    
    
    //    CGRect rect = _testVIew.bounds;
    //    rect.origin.y = self.view.bounds.size.height - 30;
    //    _testVIew.bounds = rect;
    //            MessageModel * model1 = [[MessageModel alloc]init];
    //            model1.message = textInput.text;
    //            model1.stamp = @"input1";
//    [picker dismissViewControllerAnimated:YES completion:^{
//        NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
//        // video type
//        if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
//            [self showLoading];
//            PFFile *file = [PFFile fileWithData:[NSData dataWithContentsOfURL:[info objectForKey:UIImagePickerControllerMediaURL]]];
//            PFObject *videoObject = [PFObject objectWithClassName:chatLog];
//            [videoObject setObject:file forKey:@"video"];
//            [videoObject setObject:[PFUser currentUser].username forKey:@"user"];
//            [videoObject setObject:[NSString stringWithFormat:@"%@",[NSDate date]] forKey:@"date"];
//            [videoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//                if (succeeded) {
//                    [self dismissLoading];
//                }
//                else {
//                    [self dismissLoading];
//                }
//            }];
//            return;
//        }
//        sendImage = [[info objectForKey:UIImagePickerControllerOriginalImage] retain];
//        // Resize image
//        UIGraphicsBeginImageContext(CGSizeMake(120, 160));
//        [sendImage drawInRect: CGRectMake(0, 0, 120, 160)];
//        UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//        
//        if (!sendImageView) {
//            UIWindow *window = [[UIApplication sharedApplication] keyWindow];
//            sendImageView = [[UIView alloc] initWithFrame:CGRectMake(20, SCREEN_HEIGHT/2 - 120, SCREEN_WIDTH -  40, 240)];
//            sendImageView.alpha = 0.7;
//            sendImageView.layer.cornerRadius = 3;
//            sendImageView.backgroundColor = [UIColor blackColor];
//            [window addSubview:sendImageView];
//            
//            UIImageView *imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(sendImageView.frame.size.width/2 - 60, 10, 120, 160)] autorelease];
//            imageView.image = smallImage;
//            [sendImageView addSubview:imageView];
//            
//            UIButton *sendBtn = [[[UIButton alloc]initWithFrame:CGRectMake(10, 180, sendImageView.frame.size.width/2 - 15, 50)] autorelease];
//            [sendBtn setBackgroundImage:[UIImage generateColorImage:[UIColor greenColor] size:sendBtn.frame.size] forState:UIControlStateNormal];
//            [sendBtn setTitle:@"send" forState:UIControlStateNormal];
//            sendBtn.layer.cornerRadius = 3;
//            [sendBtn addTarget:self action:@selector(sendImage) forControlEvents:UIControlEventTouchUpInside];
//            [sendImageView addSubview:sendBtn];
//            
//            UIButton *cancelBtn = [[[UIButton alloc]initWithFrame:CGRectMake(sendImageView.frame.size.width/2 + 5,  180, sendImageView.frame.size.width/2 - 15, 50)] autorelease];
//            [cancelBtn setBackgroundImage:[UIImage generateColorImage:[UIColor greenColor] size:sendBtn.frame.size  ] forState:UIControlStateNormal];
//            [cancelBtn setTitle:@"cancel" forState:UIControlStateNormal];
//            cancelBtn.layer.cornerRadius = 3;
//            [cancelBtn addTarget:self action:@selector(dismissSend) forControlEvents:UIControlEventTouchUpInside];
//            [sendImageView addSubview:cancelBtn];
//        }
//    }];
}

-(NSDictionary*)upLoadVoiceToServer:(NSData*) voiceData1 voiceName:(NSString*)voiceName{
    
    
    NSString *serURL =  (NSString*)[globalConn.server_info objectForKey:@"upload_to"];
    
    NSString * proj =  (NSString *)[globalConn.server_info objectForKey:@"proj"];
    serURL = @"http://112.124.70.60:8081/cgi-bin/upload.pl";
    //    NSLog(@"----%@", proj);
    NSMutableDictionary * params = [NSMutableDictionary dictionaryWithCapacity:7];
    [params setValue:proj forKey:@"proj"];
    
    NSMutableDictionary * dicImages =[NSMutableDictionary dictionaryWithCapacity:5];
    
    [dicImages setValue:voiceData1 forKey:voiceName];
    NSString* result;
    
    //    NSLog(@"upload--fileName=%@",videoName);
    result = [RequestPostUploadHelper postVoiceToServer:serURL dicPostParams:params dicImages:dicImages];
    
    NSDictionary *dictionaryWithJsonString = [self dictionaryWithJsonString:result];
    NSString *fid;
    NSString *filename;
    if (dictionaryWithJsonString != nil) {
        //        NSLog(@"return fid=%@,fileName=%@", [dictionaryWithJsonString objectForKey:@"fid"], [dictionaryWithJsonString objectForKey:@"filename"]);
        if ([dictionaryWithJsonString objectForKey:@"fid"] != nil) {
            fid = [dictionaryWithJsonString objectForKey:@"fid"];
        }
        if ([dictionaryWithJsonString objectForKey:@"filename"] != nil) {
            filename = [dictionaryWithJsonString objectForKey:@"filename"];
        }
    }
    return dictionaryWithJsonString;
}

-(NSDictionary*)upLoadVideoToServer:(NSData*) videoData videoName:(NSString*)videoName{
    
    NSString *serURL =  (NSString*)[globalConn.server_info objectForKey:@"upload_to"];
    
    NSString * proj =  (NSString *)[globalConn.server_info objectForKey:@"proj"];
    serURL = @"http://112.124.70.60:8081/cgi-bin/upload.pl";
//    NSLog(@"----%@", proj);
    NSMutableDictionary * params = [NSMutableDictionary dictionaryWithCapacity:7];
    [params setValue:proj forKey:@"proj"];
    
    NSMutableDictionary * dicImages =[NSMutableDictionary dictionaryWithCapacity:5];
    
    [dicImages setValue:videoData forKey:videoName];
    NSString* result;
    
//    NSLog(@"update --fileName=%@",videoName);
    result = [RequestPostUploadHelper postVideoToServer:serURL dicPostParams:params dicImages:dicImages];
    
    NSDictionary *dictionaryWithJsonString = [self dictionaryWithJsonString:result];
    NSString *fid;
    NSString *filename;
    if (dictionaryWithJsonString != nil) {
//        NSLog(@"return fid=%@,fileName=%@", [dictionaryWithJsonString objectForKey:@"fid"], [dictionaryWithJsonString objectForKey:@"filename"]);
        if ([dictionaryWithJsonString objectForKey:@"fid"] != nil) {
            fid = [dictionaryWithJsonString objectForKey:@"fid"];
        }
        if ([dictionaryWithJsonString objectForKey:@"filename"] != nil) {
            filename = [dictionaryWithJsonString objectForKey:@"filename"];
        }
    }
    return dictionaryWithJsonString;
}

-(NSDictionary*)upLoadImageToServer:(UIImage*) upLoadImage{
   
    
    NSString* fullPathToFile  = [RequestPostUploadHelper saveImage:upLoadImage WithName:[NSString stringWithFormat:@"%@%@",[RequestPostUploadHelper generateUuidString], @".jpg"]];
    
    NSString *serURL =  (NSString*)[globalConn.server_info objectForKey:@"upload_to"];
    
    NSString * proj =  (NSString *)[globalConn.server_info objectForKey:@"proj"];
    //serURL = @"http://112.124.70.60:8081/cgi-bin/upload.pl";
    NSLog(@"----%@", proj);
    NSMutableDictionary * params = [NSMutableDictionary dictionaryWithCapacity:7];
    [params setValue:proj forKey:@"proj"];
    NSArray *nameAry=[fullPathToFile componentsSeparatedByString:@"/"];
    NSMutableDictionary * dicImages =[NSMutableDictionary dictionaryWithCapacity:5];
    [dicImages setValue:upLoadImage forKey:[nameAry objectAtIndex:[nameAry count]-1]];
    NSString* result;
    
    if([fullPathToFile isEqualToString:@""]){
        [RequestPostUploadHelper postRequestWithURL:serURL postParems:params picFilePath:nil picFileName:nil];
    }else{
        
        NSArray *nameAry=[fullPathToFile componentsSeparatedByString:@"/"];
        NSLog(@"upload-fileName=%@",[nameAry objectAtIndex:[nameAry count]-1]);
        result = [RequestPostUploadHelper postImagesToServer:serURL dicPostParams:params dicImages:dicImages];
    }
    NSDictionary *dictionaryWithJsonString = [self dictionaryWithJsonString:result];
    NSString *fid;
    NSString *filename;
    if (dictionaryWithJsonString != nil) {
        NSLog(@"return fid=%@,fileName=%@", [dictionaryWithJsonString objectForKey:@"fid"], [dictionaryWithJsonString objectForKey:@"filename"]);
        if ([dictionaryWithJsonString objectForKey:@"fid"] != nil) {
            fid = [dictionaryWithJsonString objectForKey:@"fid"];
        }
        if ([dictionaryWithJsonString objectForKey:@"filename"] != nil) {
            filename = [dictionaryWithJsonString objectForKey:@"filename"];
        }
    }
    return dictionaryWithJsonString;
}

- (UIImage *)reSizeImage:(UIImage *)image toSize:(CGSize)reSize{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [image drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return reSizeImage;
}

- (void)sendImage
    {
        if(sendImageView) {
            [UIView animateWithDuration:0.3 animations:^{
                sendImageView.alpha = 0;
            } completion:^(BOOL finished) {
                [sendImageView removeFromSuperview];
//                [sendImageView release];
                sendImageView = nil;
            }];
        }
        // Resize image
        UIGraphicsBeginImageContext(CGSizeMake(120, 160));
        [sendImage drawInRect: CGRectMake(0, 0, 120, 160)];
        UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // Upload image
        [self showLoading];
        NSData *imageData = UIImagePNGRepresentation(smallImage);
//        PFObject *imageObject = [PFObject objectWithClassName:chatLog];
//        [imageObject setObject:imageData forKey:@"image"];
//        [imageObject setObject:[PFUser currentUser].username forKey:@"user"];
//        [imageObject setObject:[NSString stringWithFormat:@"%@",[NSDate date]] forKey:@"date"];
//        [imageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//            if (succeeded) {
//                [self dismissLoading];
//            }
//        }];
    }

- (void)dismissSend
{
    if(sendImageView) {
            [UIView animateWithDuration:0.3 animations:^{
                sendImageView.alpha = 0;
            } completion:^(BOOL finished) {
                [sendImageView removeFromSuperview];
                 sendImageView = nil;
            }]; 
    }   
}   

#pragma mark - sendVoice
- (void)textOrRecord
{
    
    if (isRecording)
    {
        isRecording = NO;
        [recordingBtn removeFromSuperview];
        [_panelMain addSubview:textInput];
        [recordBtn setImage:[UIImage imageNamed:@"mic.jpg"] forState:UIControlStateNormal];
        [textInput becomeFirstResponder];
    }
    else
    {
        isRecording = YES;
        [self textInputReturn];
        [textInput removeFromSuperview];
        [_panelMain addSubview:recordingBtn];
        [recordBtn setImage:[UIImage imageNamed:@"Text"] forState:UIControlStateNormal];
    }
}

- (void)recording
{
    [self viewWillDisappear:YES];
    recorder = [[AVAudioRecorder alloc] initWithURL:recordedFile settings:nil error:nil];
    [recorder prepareToRecord];
    [recorder record];
    NSLog(@"%@",[NSData dataWithContentsOfURL:recordedFile]);
}

#pragma mark - record void

- (void)recordBtnDidTouchDown:(UIButton *)recordBtn {
    self.recordTool = [[LVRecordTool alloc]init];
    self.recordTool.delegate = self;
    [self.recordTool startRecording];
}


- (void)recordBtnDidTouchUpInside:(UIButton *)recordBtn {
    double currentTime = self.recordTool.recorder.currentTime;
    NSLog(@"%lf", currentTime);
    if (currentTime < 2) {
        
        [self alertWithMessage:@"too short"];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            [self.recordTool stopRecording];
            [self.recordTool destructionRecordingFile];
        });
    } else {
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            [self.recordTool stopRecording];
            dispatch_async(dispatch_get_main_queue(), ^{
            });
        });

        NSLog(@"已成功录音");
    }
    // 
}

// move up to cancel
- (void)recordBtnDidTouchDragExit:(UIButton *)recordBtn {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [self.recordTool stopRecording];
        [self.recordTool destructionRecordingFile];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertWithMessage:@"cancel"];
        });
    });
    
}

#pragma mark - pop up
- (void)alertWithMessage:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"tip" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

#pragma mark - playback
- (void)playRecord {
    [self.recordTool playRecordingFile];
}

- (void)dealloc {
    [self.recordTool stopPlaying];
    [self.recordTool stopRecording];
}

#pragma mark - LVRecordToolDelegate
- (void)recordTool:(LVRecordTool *)recordTool didstartRecoring:(int)no {
}

- (void)recordTool:(LVRecordTool *)recordTool onRecordSuccess:(int)success catFileName:(NSString*)catFileName mp3FileName:(NSString*)mp3FileName{
     NSLog(@"file＝%@, mp3==%@", catFileName, mp3FileName);

    [self audio_PCMtoMP3:catFileName mp3FileName:mp3FileName];
    
}

- (void)recordTool:(LVRecordTool *)recordTool onRecordFailed:(int)success catFileName:(NSString*)catFileName mp3FileName:(NSString*)mp3FileName{
    
}

- (void)audio_PCMtoMP3:(NSString*)catFileName mp3FileName:(NSString*)mp3FileName{
    
    NSString* catFiles = [NSString stringWithFormat:@"%@/%@", @"Documents", catFileName];
    NSLog(@"catFiles=%@", catFiles);
    NSString* mp3Files = [NSString stringWithFormat:@"%@/%@", @"Documents", mp3FileName];
    NSLog(@"mp3Files=%@", mp3Files);
    NSString *cafFilePath = [NSHomeDirectory() stringByAppendingPathComponent:catFiles];
    NSLog(@"cafFilePath=%@", cafFilePath);
    NSString *mp3FilePath = [NSHomeDirectory() stringByAppendingPathComponent:mp3Files];
    NSLog(@"mp3FilePath=%@", mp3FilePath);
    
    NSFileManager* fileManager=[NSFileManager defaultManager];

    if([fileManager removeItemAtPath:mp3FilePath error:nil])
    {
        NSLog(@"cancel");
    }
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");  //source 
        if(pcm == NULL){
            return;
        }
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output mp3
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 11025.0);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            write=read;
            fwrite(mp3_buffer, read, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {

        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategorySoloAmbient error: nil];
        [self finishConvertVoice2Mp3:catFileName mp3FileName:mp3FileName];
    }
}

-(void)soundPlay:(NSString* )voiceurl{

    NSError *playerError;
    
    NSURL *url = [NSURL URLWithString:voiceurl];
    NSData *voiceurl_obj=[NSData dataWithContentsOfURL:url];
    cellAduioPlayer = [[AVAudioPlayer alloc] initWithData:voiceurl_obj error:&playerError];
    
    if (cellAduioPlayer == nil)
    {
        NSLog(@"ERror creating play player: %@", [playerError description]);
        return;
    }
    [cellAduioPlayer setVolume:1.0f];
    [cellAduioPlayer setNumberOfLoops:0];
    [cellAduioPlayer prepareToPlay];
    [cellAduioPlayer play];
}

-(void)finishConvertVoice2Mp3:(NSString*)catFileName mp3FileName:(NSString*)mp3FileName{
    UIButton *playBtns = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/3, 100, 100)];
    playBtns.backgroundColor = [UIColor clearColor];
    [playBtns setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [playBtns addTarget:self action:@selector(playRecord) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSLog(@"documentsDirectory=%@",documentsDirectory);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString* path = [NSString stringWithFormat:@"%@/%@", documentsDirectory, catFileName];
    NSData *data = [fileManager contentsAtPath:path];
    
    if (data != nil) {
        NSDictionary *dictionaryWithJsonString = [self upLoadVoiceToServer:data voiceName:catFileName];
        NSString *fid;
        NSString *filename;
        if (dictionaryWithJsonString != nil) {
            NSLog(@" return fid=%@,fileName=%@", [dictionaryWithJsonString objectForKey:@"fid"], [dictionaryWithJsonString objectForKey:@"filename"]);
            if ([dictionaryWithJsonString objectForKey:@"fid"] != nil) {
                fid = [dictionaryWithJsonString objectForKey:@"fid"];
            }
     
            if ([dictionaryWithJsonString objectForKey:@"filename"] != nil) {
                filename = [dictionaryWithJsonString objectForKey:@"filename"];
            }
            UIImage* images = [UIImage imageNamed:@"mic.jpg"];
            JSONObject * data = [[JSONObject alloc]init];
            
            //[data setObject:images forKey:@"image"];
            [data setObject:fid forKey:@"content"];
            [data setObject:@"voice" forKey:@"mtype"];
            
            //[data setObject:catFileName forKey:@"filename"];
            
            [data setObject:[globalConn.user_info s:@"_id"] forKey:@"from_id"];
            [data setObject:[globalConn.user_info s:@"name"] forKey:@"from_name"];
            [data setObject:[globalConn.user_info s:@"headFid"] forKey:@"from_avatar"];
            
            [chat_entries addObject:data];
            [_panelMessages reloadData];
            [self tableViewGoFooter];
            
            NSMutableDictionary * sendData = [[NSMutableDictionary alloc]init];
    
            [sendData setObject:[NSString stringWithFormat:@"%@",[NSDate date]] forKey:@"date"];
            [sendData setObject:@"message" forKey:@"obj"];
            [sendData setObject:self.header_id forKey:@"header_id"];
            
            if ([self.header_type isEqualToString:@"chat"]) {
                [sendData setObject:@"chat_send" forKey:@"act"];
            }
            if ([self.header_type isEqualToString:@"group"]){
                [sendData setObject:@"group_send" forKey:@"act"];
            }
            if ([self.header_type isEqualToString:@"topic"]){
                [sendData setObject:@"topic_send" forKey:@"act"];
            }
            [sendData setObject:@"voice" forKey:@"mtype"];
            [sendData setObject:fid forKey:@"content"];
            
            [globalConn send:sendData];
            NSLog(@"return fid=%@,fileName=%@", [dictionaryWithJsonString objectForKey:@"fid"], [dictionaryWithJsonString objectForKey:@"filename"]);
        }
    }
    else {
        NSLog(@"finishRecordVideo fail");
    }
}

#pragma mark - sendLocation

 - (void)sendLocation
{
    [MBProgressHUD showError:@"TODO"];

    
//    MapLocationViewController *mapVC = [[MapLocationViewController alloc]init];
//    

//    
//    [mapVC initData:30.613558 longitude:104.613558 isSelectLocation:true];
//    
//    mapVC.locationBlock = ^(UIImage *mapImage, double latitude, double longitude, NSString *address){

//        NSDictionary *dictionaryWithJsonString = [self upLoadImageToServer:mapImage];
//        NSString *fid;
//        NSString *filename;
//        if (dictionaryWithJsonString != nil) {

//            if ([dictionaryWithJsonString objectForKey:@"fid"] != nil) {
//                fid = [dictionaryWithJsonString objectForKey:@"fid"];
//            }
//            if ([dictionaryWithJsonString objectForKey:@"filename"] != nil) {
//                filename = [dictionaryWithJsonString objectForKey:@"filename"];
//            }
//        }
//        NSMutableDictionary * data = [[NSMutableDictionary alloc]init];
//        [data setObject:@"test2" forKey:@"obj"];
//        [data setObject:@"input1" forKey:@"act"];
//        [data setObject:mapImage forKey:@"image"];
//        [data setObject:address forKey:@"address"];
//        [data setObject:fid forKey:@"fid"];
//        [data setObject:filename forKey:@"filename"];
//        [data setObject:@"map" forKey:@"msgType"];
//        [data setObject:[NSString stringWithFormat:@"%@",[NSDate date]] forKey:@"date"];
//        
//        [chat_entries addObject:data];
//        [msgTable reloadData];
//        [self tableViewGoFooter];
//    };
//    [self.navigationController pushViewController:mapVC animated:YES];
//    
    
}

-(void)locationPosition{
    /*
    MapLocationViewController *mapVC = [[MapLocationViewController alloc]init];
    [mapVC initData:30.613558 longitude:104.613558 isSelectLocation:false];
    [self.navigationController pushViewController:mapVC animated:YES];
     */
}
                             
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
//    if (newLocation != nil) {
//        [locationManager stopUpdatingLocation];
//    }
//    //CLLocationCoordinate2D loc = [newLocation coordinate];
//    //float longitude = loc.longitude;
//    //float latitude = loc.latitude;
//    CLGeocoder *geoCoder = [[[CLGeocoder alloc] init] autorelease];
//    [geoCoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
//        CLPlacemark *placemark = [placemarks objectAtIndex:0];
//        NSString *locString = [[[NSString alloc] init] autorelease];
//        if (placemark.thoroughfare != nil) {
//            locString = [NSString stringWithFormat:@"I am at %@,%@,%@", placemark.country,placemark.administrativeArea, placemark.thoroughfare];
//        }
//        if (![locString isEqualToString:@""] && ![chatLog isEqualToString:@""])
//        {
//            [self showLoading];
//            NSData *msgData = [locString dataUsingEncoding:NSUTF8StringEncoding];
//            PFObject *sendObjects = [PFObject objectWithClassName:chatLog];
//            [sendObjects setObject:msgData forKey:@"msg"];
//            [sendObjects setObject:[PFUser currentUser].username forKey:@"user"];
//            [sendObjects setObject:[NSString stringWithFormat:@"%@",[NSDate date]] forKey:@"date"];
//            [sendObjects saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//                if (succeeded) {
//                    [self dismissLoading];
//                }
//            }];
//        }
//    }];
    [self textInputReturn];
}


#pragma mark - show Loading
- (void)showLoading
{
    if (!loadingView) {
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        loadingView = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 40, SCREEN_HEIGHT / 2 - 30, 80,   60)];
        loadingView.backgroundColor = [UIColor blackColor];
        loadingView.alpha = 0.7;
        loadingView.layer.cornerRadius = 3;
        [window addSubview:loadingView];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, 80, 30)];
        label.text = @"sending";
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        [loadingView addSubview:label];
        
        UIActivityIndicatorView *activityIdc = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 80, 30)];
        [activityIdc setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
        [activityIdc startAnimating];
        [loadingView addSubview:activityIdc];
    }
}

- (void)dismissLoading
{
        if (loadingView) {
            [UIView animateWithDuration:0.3 animations:^{
                loadingView.alpha = 0;
            } completion:^(BOOL finished) { 
            [loadingView removeFromSuperview];  
             loadingView = nil;
        }]; 
    }
}

#pragma mark - Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
    [self viewWillDisappear:YES];
    NSDateFormatter *dateFormatter =[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    queryDate = [NSDate dateWithTimeInterval: -24*60*60 sinceDate:queryDate];
    queryTime = [dateFormatter stringFromDate:queryDate];
	_reloading = YES;
    
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_panelMessages];
    [self loadMoreData];
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	
	[self reloadTableViewDataSource];
//    chat_entries = nil;
	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:1.0];
	
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	
	return _reloading; // should return if data source model is reloading
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	
	return [NSDate date]; // should return date data source was last changed
}

#pragma mark - Other    
- (void)viewDidLoad 
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSInteger yoffset = VERSION >= 7.0 ? 20 : 0;
    //ALLOC GESTURE
    UITapGestureRecognizer *tapOnScreen = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textInputReturn)];
    tapOnScreen.delegate = self;
    [self.view addGestureRecognizer:tapOnScreen];
    

    UINavigationBar *nav = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0 + yoffset, SCREEN_WIDTH, 40)];
    [nav setBackgroundImage:[UIImage generateColorImage:[UIColor grayColor] size:nav.frame.size] forBarMetrics:UIBarMetricsDefault];
    title = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2 - 70, 5, 140, 30)];
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont systemFontOfSize:20];
    title.backgroundColor = [UIColor clearColor];
    [nav addSubview:title];
    
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    back.frame = CGRectMake(0, 5, 30, 30);
    [back setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    back.backgroundColor = [UIColor clearColor];
    [back addTarget:self action:@selector(backToPrev) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithCustomView:back];
    
    UINavigationItem *navItem = [[UINavigationItem alloc] init];
    navItem.leftBarButtonItem = backBtn;
//    self.navigationItem.leftBarButtonItem = backBtn;
    [nav pushNavigationItem:navItem animated:NO];
    [self.view addSubview:nav];
    

    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"i" style:UIBarButtonItemStylePlain target:self action:@selector(rightClick)];
    navItem.rightBarButtonItem = rightItem;
    nav.tintColor = [UIColor whiteColor];
//    self.navigationItem.rightBarButtonItem = rightItem;
    
    _panelMain = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 80 + yoffset, SCREEN_WIDTH, 60)];
    _panelMain.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_panelMain];
    
    textInput = [[UITextView alloc] initWithFrame:CGRectMake(50, 10, SCREEN_WIDTH - 100, 40)];
    textInput.layer.cornerRadius = 3;
    textInput.layer.borderColor = [UIColor whiteColor].CGColor;
    textInput.layer.borderWidth = 1;
    textInput.backgroundColor = [UIColor whiteColor];
    textInput.font = [UIFont systemFontOfSize:20];
    textInput.returnKeyType = UIReturnKeySend;
    textInput.delegate = self;
    [_panelMain addSubview:textInput];
    
    recordingBtn = [[UIButton alloc] initWithFrame:CGRectMake(50, 10, SCREEN_WIDTH - 100, 40)];
    [recordingBtn setTitle:@"press to talk" forState:UIControlStateNormal];
    [recordingBtn setBackgroundImage:[UIImage generateColorImage:[UIColor grayColor] size:recordingBtn.frame.size] forState:UIControlStateNormal];
    recordingBtn.layer.borderWidth = 1;
    recordingBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    [recordingBtn addTarget:self action:@selector(recordBtnDidTouchDown:) forControlEvents:UIControlEventTouchDown];
    [recordingBtn addTarget:self action:@selector(recordBtnDidTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [recordingBtn addTarget:self action:@selector(recordBtnDidTouchDragExit:) forControlEvents:UIControlEventTouchDragExit];
    UIButton *moreBtn = [[UIButton alloc] initWithFrame:CGRectMake(textInput.frame.origin.x + textInput.frame.size.width + 5, 10, 40, 40)];
    moreBtn.backgroundColor = [UIColor clearColor];
    [moreBtn setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [moreBtn addTarget:self action:@selector(showAndDismissPanelPlus) forControlEvents:UIControlEventTouchUpInside];
    [_panelMain addSubview:moreBtn];
    
    recordBtn = [[UIButton alloc] initWithFrame:CGRectMake(5, 10, 40, 40)];
    recordBtn.backgroundColor = [UIColor clearColor];
    [recordBtn setImage:[UIImage imageNamed:@"mic.jpg"] forState:UIControlStateNormal];
    [recordBtn addTarget:self action:@selector(textOrRecord) forControlEvents:UIControlEventTouchUpInside];
    [_panelMain addSubview:recordBtn];
    
    _panelMessages = [[UITableView alloc] initWithFrame:CGRectMake(0, 40 + yoffset, SCREEN_WIDTH, SCREEN_HEIGHT - 120)];
    _panelMessages.dataSource = self;
    _panelMessages.delegate = self;
    _panelMessages.separatorStyle = UITableViewCellSeparatorStyleNone;
    _panelMessages.userInteractionEnabled = true;
//    UITapGestureRecognizer *tapOnScreen = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textInputReturn)];
//    tapOnScreen.delegate = self;
//    [msgTable addGestureRecognizer:tapOnScreen];
    [self.view addSubview:_panelMessages];

    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]
                                                      initWithTarget:self action:@selector(longPress:)];
    longPressGesture.minimumPressDuration = 1.0; // long press setting
    [_panelMessages addGestureRecognizer:longPressGesture];
    
    NSDateFormatter *dateFormatter =[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    queryDate = [NSDate date];
    queryTime = [dateFormatter stringFromDate:queryDate];
    
    timeLable = [[UILabel alloc] init];
    timeLable.textAlignment = NSTextAlignmentCenter;
    timeLable.textColor = [UIColor blackColor];
    timeLable.font = [UIFont systemFontOfSize:14];
    timeLable.text = queryTime;
    
    if (_refreshHeaderView == nil) {
        EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - _panelMessages.bounds.size.height, self.view.frame.size.width, _panelMessages.bounds.size.height)];
        view.delegate = self;
        [_panelMessages addSubview:view];
        _refreshHeaderView = view;
     }
    
    // panel plus
    _panelPlus = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 20 + yoffset, SCREEN_WIDTH, 216)];
    _panelPlus.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_panelPlus];
    _panelPlusVisible = NO;
    
    UIButton *imageBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, (_panelPlus.frame.size.height - 30) / 2, (_panelPlus.frame.size.height - 30) / 2)];
    imageBtn.backgroundColor = [UIColor clearColor];
    [imageBtn setImage:[UIImage imageNamed:@"icon_photo_after"] forState:UIControlStateNormal];
    [imageBtn addTarget:self action:@selector(pickImage) forControlEvents:UIControlEventTouchUpInside];
    [_panelPlus addSubview:imageBtn];
    
    cameraBtn = [[UIButton alloc] initWithFrame:CGRectMake(imageBtn.frame.origin.x + imageBtn.frame.size.width + 10, 10, (_panelPlus.frame.size.height - 30) / 2, (_panelPlus.frame.size.height - 30) / 2)];
    [cameraBtn setImage:[UIImage imageNamed:@"icon_camera_after"] forState:UIControlStateNormal];
    cameraBtn.backgroundColor = [UIColor clearColor];
    [cameraBtn addTarget:self action:@selector(cameraCapture) forControlEvents:UIControlEventTouchUpInside];
    [_panelPlus addSubview:cameraBtn];
    
    UIButton *locationBtn = [[UIButton alloc] initWithFrame:CGRectMake(cameraBtn.frame.origin.x + cameraBtn.frame.size.width + 10, 10, (_panelPlus.frame.size.height - 30) / 2, (_panelPlus.frame.size.height - 30) / 2)];
    locationBtn.backgroundColor = [UIColor clearColor];
    [locationBtn setImage:[UIImage imageNamed:@"icon_map_after"] forState:UIControlStateNormal];
    [locationBtn addTarget:self action:@selector(sendLocation) forControlEvents:UIControlEventTouchUpInside];
    [_panelPlus addSubview:locationBtn];
    
    UIButton *videoBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, imageBtn.frame.origin.y + imageBtn.frame.size.height + 10, (_panelPlus.frame.size.height - 30) / 2, (_panelPlus.frame.size.height - 30) / 2)];
    videoBtn.backgroundColor = [UIColor clearColor];
    [videoBtn setImage:[UIImage imageNamed:@"icon_video_after"] forState:UIControlStateNormal];
    [videoBtn addTarget:self action:@selector(recordVideo) forControlEvents:UIControlEventTouchUpInside];
    [_panelPlus addSubview:videoBtn];
    
    
    
    UIButton *moneyBtn = [[UIButton alloc] initWithFrame:CGRectMake(locationBtn.frame.origin.y + locationBtn.frame.size.height + 10, locationBtn.frame.origin.y + locationBtn.frame.size.height + 10, (_panelPlus.frame.size.height - 30) / 2, (_panelPlus.frame.size.height - 30) / 2)];
    moneyBtn.backgroundColor = [UIColor clearColor];
    [moneyBtn setImage:[UIImage imageNamed:@"icon_card_after"] forState:UIControlStateNormal];
    [moneyBtn addTarget:self action:@selector(cartButton) forControlEvents:UIControlEventTouchUpInside];
    [_panelPlus addSubview:moneyBtn];
    
    
//    UIButton *moneyBtn = [[UIButton alloc] initWithFrame:CGRectMake(locationBtn.frame.origin.y + locationBtn.frame.size.height + 10, locationBtn.frame.origin.y + locationBtn.frame.size.height + 10, (moreView.frame.size.height - 30) / 2, (moreView.frame.size.height - 30) / 2)];
//    moneyBtn.backgroundColor = [UIColor clearColor];
//    [moneyBtn setImage:[UIImage imageNamed:@"money"] forState:UIControlStateNormal];
//    [moneyBtn addTarget:self action:@selector(inputMoney) forControlEvents:UIControlEventTouchUpInside];
//    [moreView addSubview:moneyBtn];
    
    isSendImage = NO;
}

- (void)rightClick
{
    /*// take it to the right page dependign on the context
    if ([self.obj isEqualToString:@"group"]) {
        i043_2WETaskEditViewController *i043_2VC=[[i043_2WETaskEditViewController alloc]init];
        i043_2VC._taskID=self.to_id;
        i043_2VC.project_id=[globalConn.user_data s:@"project_id"];    //
        [self.navigationController pushViewController:i043_2VC animated:YES];
    }
    if ([self.obj isEqualToString:@"person"]) {
        i073ViewController*i073VC=[[i073ViewController alloc]init];
        i073VC.person_id=self.to_id;
        [self.navigationController pushViewController:i073VC animated:YES];
    }
    if ([self.obj isEqualToString:@"topic"]) {
        TopicInfoViewController *topInfoVC = [[TopicInfoViewController alloc] initWithNibName:@"bulidTopicView" bundle:nil];
        topInfoVC.topicId = self.to_id;
        [self.navigationController pushViewController:topInfoVC animated:YES];
    }*/
}

-(void)cartButton
{
    [MBProgressHUD showError:@"todo"];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(response_received)
                                                 name:globalConn.responseReceivedNotification object:nil];

    float version = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (version >= 5.0) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:   UIKeyboardWillChangeFrameNotification object:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShow:) name:  UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDismiss:) name:   UIKeyboardWillHideNotification object:nil];
    }

    if (isSendImage) {
        isSendImage = NO;
        return;
    }
    
    // reset the memory data
    chat_entries = [[JSONArray alloc]init];
    
    NSMutableDictionary   *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:@"message" forKey:@"obj"];
    
    _isFirst = NO;
    if ([self.header_type isEqualToString:@"chat"]) {
        [dic setObject:@"chat_get" forKey:@"act"];
    }
    if ([self.header_type isEqualToString:@"group"]) {
        [dic setObject:@"task_get" forKey:@"act"];
    }
    if ([self.header_type isEqualToString:@"topic"]) {
        [dic setObject:@"topic_get" forKey:@"act"];
    }
    [dic setObject:self.header_id forKey:@"header_id"];
    [globalConn send:dic];


}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self dismissLoading];
}

- (void)loadMoreData {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(response_received)
                                                 name:globalConn.responseReceivedNotification object:nil];
    
    if (isSendImage) {
        isSendImage = NO;
        return;
    }
    NSMutableDictionary   *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:@"message" forKey:@"obj"];
    [dic setObject:@"chat_get" forKey:@"act"];
    if ([_next_block_id isEqualToString:@""] || [_next_block_id isEqualToString:@"0"]) {
        return ;
    }
    _isFirst = YES;
    [dic setObject:_next_block_id forKey:@"block_id"];
    [globalConn send:dic];
}

- (void)response_received {
    
    __block JSONArray *tempArray = @[].mutableCopy;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        
        NSLog(@"handled by %@: %@:%@ uerr:%@", [self class],
              [globalConn.response objectForKey:@"obj"],
              [globalConn.response objectForKey:@"act"],
              [globalConn.response objectForKey:@"uerr"]);
        
        // user error occurs, return structure can not be certain
        if (![[globalConn.response s:@"uerr"] isEqualToString:@""]) return;
        
        _next_block_id = [[globalConn.response o:@"block"] s:@"next_id"];
        NSString *_id = [[globalConn.response o:@"block"] s:@"_id"];
        
        NSLog(@"%@---------------%@",_next_block_id,_id);
        
        

        if ([[globalConn.response s:@"act"] isEqualToString:@"chat_get"]) {
            
                NSArray *arr = [[globalConn.response o:@"block"] a:@"entries"];
                
                for (int i= 0; i<arr.count; i++) {
                    
                    JSONObject *dic = [JSONObject dictionaryWithDictionary:arr[i]];
                    NSLog(@"%@",dic);
                    if ([[dic s:@"mtype"] isEqualToString:@"image"]) {
                        NSData * imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[self getDownloadURL:[dic s:@"content"]]]];

                        if([dic[@"content"]  isKindOfClass: [NSDictionary class]]){
                            imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[self getDownloadURL:dic[@"content"][@"thumb"]]]];
                        }
                   
                        
                        UIImage * img = [UIImage imageWithData:imgData];
                        if (img) {
                            [dic setObject:img forKey:@"image"];
                        }
                        
                    }
                    
                    [tempArray addObject:dic];
                }
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // reload records
                [tempArray addObjectsFromArray:chat_entries];
                chat_entries = [[JSONArray alloc] init];
                [_panelMessages reloadData];
                chat_entries = tempArray;
                [_panelMessages reloadData];
                
                [self tableViewGoFooter];
                
                if (_panelMessages.contentSize.height > _panelMessages.frame.size.height) {
                    if (!_isFirst) {
                        [_panelMessages setContentOffset:CGPointMake(0, _panelMessages.contentSize.height - _panelMessages.frame.size.height) animated:YES];
                    }
                    }
            });

            
            return;
        }

        

        JSONObject * data = nil;
        
        if ([[globalConn.response s:@"obj"] isEqualToString:@"push"]) {
            
            if (
                // I'm on percon chat page, and it is from the other party
                ([[globalConn.response s:@"act"] isEqualToString:@"message_chat"]
                && [self.header_type isEqualToString:@"chat"]
                && [self.header_id isEqualToString:[globalConn.response s:@"header_id"]]) ||
                
                ([[globalConn.response s:@"act"] isEqualToString:@"message_topic"]
                && [self.header_type isEqualToString:@"topic"]
                && [self.header_id isEqualToString:[globalConn.response s:@"header_id"]]) ||
                
                ([[globalConn.response s:@"act"] isEqualToString:@"message_group"]
                 && [self.header_type isEqualToString:@"group"]
                 && [self.header_id isEqualToString:[globalConn.response s:@"header_id"]])
                
                ) {
                
                data = globalConn.response;
                
                if ([[data s:@"mtype"] isEqualToString:@"image"]) {
                    
                    NSData * imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[self getDownloadURL:[data s:@"content"]]]];

                    if([data[@"content"]  isKindOfClass: [NSDictionary class]]){
                        imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[self getDownloadURL:data[@"content"][@"thumb"]]]];
                    }
                    
                    UIImage * img = [UIImage imageWithData:imgData];
                    if (img) {
                        [data setObject:img forKey:@"image"];
                    }

                }
            }
        }
        
        if (data != nil) {
                // add to the list and reload
            dispatch_async(dispatch_get_main_queue(), ^{
                [chat_entries addObject:data];
                [_panelMessages reloadData];
                [self tableViewGoFooter];
            });
        }
        
        /*
                // MAP ///////////////////////////////////////////////////////////
                else if ([[mutableDic objectForKey:@"msgType"] isEqualToString:@"map"]) {
                    
                    [data setObject:[mutableDic objectForKey:@"lat"] forKey:@"lat"];
                    [data setObject:[mutableDic objectForKey:@"lng"] forKey:@"lng"];
                    [data setObject:[mutableDic objectForKey:@"address"] forKey:@"address"];
                    
                    NSData * imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[self getDownloadURL:[globalConn.response objectForKey:@"fid"]]]];
                    UIImage * img = [UIImage imageWithData:imgData];
                    if (img) {
                        [data setObject:img forKey:@"image"];
                    }
                }
        
                // MONEY ///////////////////////////////////////////////////////////
                else if ([[mutableDic objectForKey:@"msgType"] isEqualToString:@"money"]) {
                    
                    [data setObject:[mutableDic objectForKey:@"word"] forKey:@"word"];
                    
                    UIImage *moneyImage = [self reSizeImage:[UIImage imageNamed:@"money"] toSize:CGSizeMake(40, 40)];
                    if (moneyImage) {
                        [data setObject:moneyImage forKey:@"image"];
                    }
                }
         */
        
    }); // dispatch
    
    return;
}

@end
