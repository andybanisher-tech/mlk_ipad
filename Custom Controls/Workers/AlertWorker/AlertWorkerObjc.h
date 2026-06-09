//
//  AlertWorkerObjc.h
//
//
//  Created by Alexandr Polienko on 22/11/2018.
//  Copyright © 2018 MIR. All rights reserved.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface AlertWorkerObjc: NSObject

+ (void)alertWithTitle:(nullable NSString *)title;
+ (void)alertWithTitle:(nullable NSString *)title message:(nullable NSString *)message;

+ (void)alertWithTitle:(nullable NSString *)title message:(nullable NSString *)message acceptMessage:(NSString *)acceptMessage acceptBlock:(void(^)(void))acceptBlock;
+ (void)alertWithTitle:(nullable NSString *)title message:(nullable NSString *)message buttons:(NSArray<NSString *> *)buttons tapBlock:(void(^)(UIAlertAction *action, NSInteger index))tapBlock;

+ (void)actionSheetWithTitle:(nullable NSString *)title message:(nullable NSString *)message sourceView:(UIView *)sourceView actions:(NSArray<UIAlertAction *> *)actions;
+ (void)actionSheetWithTitle:(nullable NSString *)title message:(nullable NSString *)message sourceView:(UIView *)sourceView buttons:(NSArray<NSString *> *)buttons tapBlock:(void(^)(UIAlertAction *action, NSInteger index))tapBlock;
+ (void)actionSheetWithTitle:(nullable NSString *)title message:(nullable NSString *)message sourceView:(UIView *)sourceView buttons:(NSArray<NSString *> *)buttons isLastButtonCancel:(BOOL)isLastButtonCancel permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections tapBlock:(void(^)(UIAlertAction *action, NSInteger index))tapBlock;

@end

NS_ASSUME_NONNULL_END
