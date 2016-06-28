//
//  ActivityIndicatorBox.m
//  Amblist-iOS
//
//  Created by CyberDesignz on 11/23/12.
//
//

#import "ActivityIndicatorBox.h"
#import "MBProgressHUD.h"

@implementation ActivityIndicatorBox

+(void)showActivityIndicatorWithLabel:(NSString *)labelText forView:(UIView *)view{
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
     hud.mode = MBProgressHUDModeIndeterminate;

//     hud.labelText = labelText;
    hud.detailsLabelText=labelText;
     hud.color = [UIColor colorWithRed:0.23 green:0.50 blue:0.82 alpha:0.90];

    //[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    
    
    
}
+(void)hideActivityIndicatorforView:(UIView *)view{
    
    //[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [MBProgressHUD hideHUDForView:view animated:YES];
    
}
@end
