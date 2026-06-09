//
//  ASPFunctions.h
//  SOCOLOR
//
//  Created by Alexandr Polienko on 17.01.2020.
//  Copyright © 2020 MIR. All rights reserved.
//

#import "UIKit/UIKit.h"

//DateFormats
#define dateFormat_HH_mm_ss_dd_MM_YYYY @"HH:mm:ss dd.MM.yyyy"
#define dateFormat_dd_MM_YYYY @"dd.MM.yyyy"
#define dateFormat_dd_MMM_YYYY @"dd MMM yyyy"
#define dateFormat_YYYY_MM_dd @"yyyy.MM.dd"

NS_ASSUME_NONNULL_BEGIN

@interface ASPFunctions: NSObject

#pragma mark - NSString
+ (NSString *)addStringPercentEncoding:(NSString *)string;
+ (BOOL)isEmailValid:(NSString *)email;

#pragma mark - NSDate
+ (NSString *)changeDateFormatOfString:(NSString *)dateString;
+ (NSString *)dateStringFromDate:(NSDate *)date dateFormat:(NSString *)dateFormat;

#pragma mark - NSArray
+ (nullable id)firstObjectInArray:(NSArray *)array where:(BOOL (NS_NOESCAPE ^)(id obj, NSUInteger idx, BOOL *stop))predicate;

#pragma mark - UIViewController
+ (UIViewController *)topMostController;
+ (BOOL)isViewControllerVisible:(UIViewController *)vc;

#pragma mark - UINavigationController
+ (void)setupNavigationController:(UINavigationController *)navVC backgroundColor:(UIColor *)backgroundColor tintColor:(UIColor *)tintColor;
+ (void)setupNavigationController:(UINavigationController *)navVC backgroundColor:(UIColor *)backgroundColor titleColor:(nullable UIColor *)titleColor tintColor:(UIColor *)tintColor;
+ (void)setNavigationBar:(UINavigationBar *)navBar backgroundColor:(UIColor *)backgroundColor;

#pragma mark - UIView
+ (void)view:(UIView *)view withCornerRadius:(CGFloat)radius;
+ (void)addLineLayerForView:(UIView *)view lineColor:(nullable UIColor *)lineColor lineWidth:(CGFloat)lineWidth cornerRadius:(CGFloat)cornerRadius;
+ (void)dropShadowForView:(UIView *)view shadowOffset:(CGSize)offset radius:(CGFloat)radius opacity:(CGFloat)opacity color:(UIColor *)color;
+ (void)pulseView:(UIView *)view isActive:(BOOL)isActive;

#pragma mark - UIButton
+ (void)setButtonTitleWithoutAnimation:(UIButton *)button title:(NSString *)title state:(UIControlState)state;

#pragma mark - UIColor
+ (UIColor *)colorFromHex:(NSString *)hexString;

#pragma mark - UIImage
+ (UIImage *)fillImage:(UIImage *)image withColor:(UIColor *)color;

#pragma mark - Url
+ (void)openWebSiteFrom:(UIViewController *)vc webSiteString:(NSString *)webSiteString;

#pragma mark - UIApplication
+ (nullable UIWindow *)mainKeyWindow;
+ (CGFloat)statusBarHeight;

@end

NS_ASSUME_NONNULL_END
