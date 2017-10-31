
#import "MBProgressHUD+ND.h"

@implementation MBProgressHUD (ND)

+ (void)show:(NSString *)text icon:(NSString *)icon view:(UIView *)view
{
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.labelText = text;

    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"MBProgressHUD.bundle/%@", icon]]];

    hud.mode = MBProgressHUDModeCustomView;
    

    hud.removeFromSuperViewOnHide = YES;
    

    [hud hide:YES afterDelay:1];
}


+ (void)showError:(NSString *)error toView:(UIView *)view{
    [self show:error icon:@"error.png" view:view];
}

+ (void)showSuccess:(NSString *)success toView:(UIView *)view
{
    [self show:success icon:@"success.png" view:view];
}



+ (MBProgressHUD *)showMessage:(NSString *)message toView:(UIView *)view {
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.labelText = message;

    hud.removeFromSuperViewOnHide = YES;

    hud.dimBackground = YES;
    return hud;
}


+ (void)showTextOnly:(NSString *)text  view:(UIView *)view
{
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.labelText = text;

    hud.mode = MBProgressHUDModeText;
    hud.margin=10.0f;
    hud.yOffset=160.0f;

    hud.removeFromSuperViewOnHide = YES;
    

    [hud hide:YES afterDelay:2];
}



+ (void)showSuccess:(NSString *)success
{
    [self showSuccess:success toView:nil];
}

+ (void)showError:(NSString *)error
{
    [self showError:error toView:nil];
}

+(void)showTextOnly:(NSString *)text
{
    [self showTextOnly:text view:nil];
}

+ (MBProgressHUD *)showMessage:(NSString *)message
{
    return [self showMessage:message toView:nil];
}

+ (void)hideHUDForView:(UIView *)view
{
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
    [self hideHUDForView:view animated:YES];
}

+ (void)hideHUD
{
    [self hideHUDForView:nil];
}
@end
