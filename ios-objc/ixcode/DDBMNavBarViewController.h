
#import <UIKit/UIKit.h>

@interface DDBMNavBarViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *btnLeft;
@property (weak, nonatomic) IBOutlet UILabel *labTitle;
@property (weak, nonatomic) IBOutlet UIButton *btnRight;
@property (weak, nonatomic) IBOutlet UIView *navView;
@property (weak, nonatomic) IBOutlet UIButton *btnSecondLeft;
@property (weak, nonatomic) IBOutlet UIButton *btnSecondRight;

- (id)initNavigate:(NSString*)title;

@end
