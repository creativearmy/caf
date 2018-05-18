#import <UIKit/UIKit.h>

@interface i000ViewController : UIViewController
{
    IBOutlet UILabel *OUTPUT;
    IBOutlet UITextField *CHAT_LOGIN_NAME;
}

- (IBAction)inputAction:(id)sender;
- (IBAction)chatAction:(id)sender;

@property (strong, nonatomic) IBOutlet UILabel *OUTPUT;

@property (strong, nonatomic) IBOutlet UITextField *CHAT_LOGIN_NAME;

@end

