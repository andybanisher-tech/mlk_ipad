//
//  ASPFunctions.m
//  
//
//  Created by Alexandr Polienko on 17.01.2020.
//  Copyright © 2020 MIR. All rights reserved.
//

#import "ASPFunctions.h"
#import <SafariServices/SafariServices.h>

@implementation ASPFunctions

#pragma mark - NSString
+ (NSString *)addStringPercentEncoding:(NSString *)string {
    return [string stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
}

+ (BOOL)isEmailValid:(NSString *)email {
    BOOL stricterFilter = NO;
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}

#pragma mark - NSDate
+ (NSString *)changeDateFormatOfString:(NSString *)dateString {
    NSDateFormatter *dateFormatter  = NSDateFormatter.new;
    dateFormatter.dateFormat = dateFormat_dd_MMM_YYYY;
    NSDate *selDate = [dateFormatter dateFromString:dateString];
    
    dateFormatter.dateFormat = dateFormat_dd_MM_YYYY;
    return [dateFormatter stringFromDate:selDate];
}

+ (NSString *)dateStringFromDate:(NSDate *)date dateFormat:(NSString *)dateFormat {
    NSDateFormatter *formatter = NSDateFormatter.new;
    formatter.dateFormat = dateFormat;
    return [formatter stringFromDate:date];
}

#pragma mark - NSArray
+ (nullable id)firstObjectInArray:(NSArray *)array where:(BOOL (NS_NOESCAPE ^)(id obj, NSUInteger idx, BOOL *stop))predicate {
    NSUInteger searchIndex = [array indexOfObjectPassingTest:predicate];
    if (searchIndex != NSNotFound) {
        return array[searchIndex];
    } else {
        return nil;
    }
}

#pragma mark - UIViewController
+ (UIViewController *)topMostController {
    UIViewController *presentedVC = ASPFunctions.mainKeyWindow.rootViewController;
    while (presentedVC.presentedViewController) {
        presentedVC = presentedVC.presentedViewController;
    }
    
    if (!presentedVC) {
        NSLog(@"ASPAlertController Error: You don't have any views set. You may be calling in viewdidload. Try viewdidappear.");
    }
    
    if ([presentedVC isKindOfClass: UIAlertController.class]) {
        NSLog(@"TopViewController Error: Attempting to present Alert over another Alert.");
        return presentedVC;
    }
    
    return presentedVC;
}

+ (BOOL)isViewControllerVisible:(UIViewController *)vc {
    if (vc.isViewLoaded) {
        BOOL isVisible = vc.view.window != nil && vc.presentedViewController == nil;
        if (vc.navigationController) {
            isVisible = isVisible && vc.navigationController.viewControllers.lastObject == vc;
        }
        return  isVisible;
    }
    return NO;
}

#pragma mark - UINavigationController
+ (void)setupNavigationController:(UINavigationController *)navVC backgroundColor:(UIColor *)backgroundColor tintColor:(UIColor *)tintColor {
    [self setupNavigationController:navVC backgroundColor:backgroundColor titleColor:nil tintColor:tintColor];
}

+ (void)setupNavigationController:(UINavigationController *)navVC backgroundColor:(UIColor *)backgroundColor titleColor:(nullable UIColor *)titleColor tintColor:(UIColor *)tintColor {
    UINavigationBarAppearance *navBarAppearance = [UINavigationBarAppearance new];
    [navBarAppearance configureWithOpaqueBackground];
    navBarAppearance.backgroundColor = backgroundColor;
    if (titleColor) {
        navBarAppearance.titleTextAttributes = @{NSForegroundColorAttributeName : titleColor};
    }
    
    navVC.navigationBar.standardAppearance = navBarAppearance;
    navVC.navigationBar.scrollEdgeAppearance = navBarAppearance;
    navVC.navigationBar.tintColor = tintColor;
}

+ (void)setNavigationBar:(UINavigationBar *)navBar backgroundColor:(UIColor *)backgroundColor {
    navBar.standardAppearance.backgroundColor = backgroundColor;
    navBar.scrollEdgeAppearance.backgroundColor = backgroundColor;
}

#pragma mark - UIView
+ (void)view:(UIView *)view withCornerRadius:(CGFloat)radius {
    view.clipsToBounds = YES;
    
    view.layer.cornerRadius = radius;
    view.layer.rasterizationScale = UIScreen.mainScreen.scale;
    view.layer.shouldRasterize = YES;
}

+ (void)addLineLayerForView:(UIView *)view lineColor:(nullable UIColor *)lineColor lineWidth:(CGFloat)lineWidth cornerRadius:(CGFloat)cornerRadius {
    view.layer.shouldRasterize = YES;
    view.layer.rasterizationScale = UIScreen.mainScreen.scale;
    
    view.clipsToBounds = YES;
    
    if (lineColor) {
        view.layer.borderColor = lineColor.CGColor;
    }
    
    view.layer.borderWidth = lineWidth;
    view.layer.cornerRadius = cornerRadius;
}

+ (void)dropShadowForView:(UIView *)view shadowOffset:(CGSize)offset radius:(CGFloat)radius opacity:(CGFloat)opacity color:(UIColor *)color {
    view.layer.shouldRasterize = YES;
    view.layer.rasterizationScale = UIScreen.mainScreen.scale;
    view.layer.masksToBounds = NO;
    
    view.layer.shadowOffset = offset;
    view.layer.shadowRadius = radius;
    view.layer.shadowOpacity = opacity;
    view.layer.shadowColor = color.CGColor;
}

+ (void)pulseView:(UIView *)view isActive:(BOOL)isActive {
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.4 initialSpringVelocity:0.4 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        if (isActive) {
            view.transform = CGAffineTransformMakeScale(0.95, 0.95);
        } else {
            view.transform = CGAffineTransformIdentity;
        }
    } completion:nil];
}

#pragma mark - UIButton
+ (void)setButtonTitleWithoutAnimation:(UIButton *)button title:(NSString *)title state:(UIControlState)state {
    [UIView setAnimationsEnabled:NO];
    
    [button setTitle:title forState:state];
    [button layoutIfNeeded];
    
    [UIView setAnimationsEnabled:YES];
}

#pragma mark - UIColor
+ (UIColor *)colorFromHex:(NSString *)hexString {
    if (hexString.length == 0) return [UIColor blackColor];
    if ([[hexString substringToIndex:1] isEqualToString:@"#"]) hexString = [hexString substringFromIndex:1];
    
    if ([hexString length] != 6) return [UIColor blackColor];
    
    hexString = [hexString uppercaseString];
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:0]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

#pragma mark - UIImage
+ (UIImage *)fillImage:(UIImage *)image withColor:(UIColor *)color {
    
    // begin a new image context, to draw our colored image onto with the right scale
    UIGraphicsBeginImageContextWithOptions(image.size, NO, UIScreen.mainScreen.scale);
    
    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // set the fill color
    [color setFill];
    
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextSetBlendMode(context, kCGBlendModeColorBurn);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGContextDrawImage(context, rect, image.CGImage);
    
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    // generate a new UIImage from the graphics context we drew onto
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //return the color-burned image
    return coloredImg;
}

#pragma mark - Url
+ (void)openWebSiteFrom:(UIViewController *)vc webSiteString:(NSString *)webSiteString {
    NSURL *url = [[NSURL alloc] initWithString:webSiteString];
    
    if (url) {
        SFSafariViewController *browser = [[SFSafariViewController alloc] initWithURL:url];
        [vc presentViewController:browser animated:YES completion:nil];
    }
}

#pragma mark - UIApplication
+ (UIWindow *)mainKeyWindow {
    NSSet *scenes = UIApplication.sharedApplication.connectedScenes;
    NSMutableArray *windows = [NSMutableArray new];
    
    for (UIWindowScene *scene in scenes) {
        [windows addObjectsFromArray:scene.windows];
    }
    
    UIWindow *mainKeyWindow = [windows filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIWindow *window, NSDictionary<NSString *,id> * _Nullable bindings) {
        return window.isKeyWindow;
    }]].lastObject;
    
    return mainKeyWindow;
}

+ (CGFloat)statusBarHeight {
    CGFloat statusBarHeight = [self mainKeyWindow].windowScene.statusBarManager.statusBarFrame.size.height;
    if (statusBarHeight) {
        return statusBarHeight;
    }
    
    return 0.0;
}

@end
