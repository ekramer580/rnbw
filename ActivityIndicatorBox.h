//
//  ActivityIndicatorBox.h
//  Amblist-iOS
//
//  Created by CyberDesignz on 11/23/12.
//
//

#import <Foundation/Foundation.h>

@interface ActivityIndicatorBox : NSObject

+(void)showActivityIndicatorWithLabel:(NSString *)labelText forView:(UIView *)view;
+(void)hideActivityIndicatorforView:(UIView *)view;

@end
