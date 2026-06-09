//
//  ASPAlertControllerObjc.m
//  SOCOLOR
//
//  Created by Furkan Yilmaz on 11/11/15.
//  Objc rewritten by Alexandr Polienko on 22/11/2018.
//  Copyright © 2015 Furkan Yilmaz. All rights reserved.
//

#import "AlertWorkerObjc.h"

@implementation AlertWorkerObjc
    //==========================================================================================================
    // MARK: - Private Functions
    //==========================================================================================================

+ (UIAlertController *)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle buttons:(NSArray<NSString *> *)buttons isLastButtonCancel:(BOOL)isLastButtonCancel tapBlock:(void(^)(UIAlertAction *action, NSInteger index))tapBlock {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:preferredStyle];
    
    NSInteger buttonIndex = 0;
    for (NSString *buttonTitle in buttons) {
        UIAlertActionStyle preferredActionStyle = UIAlertActionStyleDefault;
        if (isLastButtonCancel && [buttonTitle isEqualToString:buttons.lastObject]) {
            if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad && preferredStyle == UIAlertControllerStyleActionSheet) {
                preferredActionStyle = UIAlertActionStyleDestructive;
            } else {
                preferredActionStyle = UIAlertActionStyleCancel;
            }
        }
        
        UIAlertAction *action = [self actionWithTitle:buttonTitle preferredStyle:preferredActionStyle buttonIndex:buttonIndex tapBlock:tapBlock];
        buttonIndex++;
        [alert addAction:action];
    }
    
    return alert;
}

+ (UIAlertAction *)actionWithTitle:(NSString *)title preferredStyle:(UIAlertActionStyle)preferredStyle buttonIndex:(NSInteger)buttonIndex tapBlock:(void(^)(UIAlertAction *action, NSInteger index))tapBlock{
    UIAlertAction *action = [UIAlertAction actionWithTitle:title style:preferredStyle handler:^(UIAlertAction * _Nonnull alertAction) {
        tapBlock(alertAction, buttonIndex);
    }];
    return action;
}

//==========================================================================================================
// MARK: - Class Functions
//==========================================================================================================

+ (void)alertWithTitle:(nullable NSString *)title {
    [self alertWithTitle:title message:@""];
}

+ (void)alertWithTitle:(nullable NSString *)title message:(nullable NSString *)message {
    [self alertWithTitle:title message:message acceptMessage:@"OK" acceptBlock:^{
        
    }];
}

+ (void)alertWithTitle:(nullable NSString *)title message:(nullable NSString *)message acceptMessage:(NSString *)acceptMessage acceptBlock:(void(^)(void))acceptBlock{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *acceptButton = [UIAlertAction actionWithTitle:acceptMessage style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        acceptBlock();
    }];
    [alert addAction:acceptButton];
    dispatch_async(dispatch_get_main_queue(), ^{
        [ASPFunctions.topMostController presentViewController:alert animated:YES completion:nil];
    });
}

+ (void)alertWithTitle:(nullable NSString *)title message:(nullable NSString *)message buttons:(NSArray<NSString *> *)buttons tapBlock:(void(^)(UIAlertAction *action, NSInteger index))tapBlock{
    UIAlertController *alert = [self alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert buttons:buttons isLastButtonCancel:YES tapBlock:tapBlock];
    dispatch_async(dispatch_get_main_queue(), ^{
        [ASPFunctions.topMostController presentViewController:alert animated:YES completion:nil];
    });
}

+ (void)actionSheetWithTitle:(nullable NSString *)title message:(nullable NSString *)message sourceView:(UIView *)sourceView actions:(NSArray<UIAlertAction *> *)actions {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:(UIAlertControllerStyleActionSheet)];
    
    for (UIAlertAction *action in actions) {
        [alert addAction:action];
    }
    alert.popoverPresentationController.sourceView = sourceView;
    alert.popoverPresentationController.sourceRect = sourceView.bounds;
    dispatch_async(dispatch_get_main_queue(), ^{
        [ASPFunctions.topMostController presentViewController:alert animated:YES completion:nil];
    });
}

+ (void)actionSheetWithTitle:(nullable NSString *)title message:(nullable NSString *)message sourceView:(UIView *)sourceView buttons:(NSArray<NSString *> *)buttons tapBlock:(void(^)(UIAlertAction *action, NSInteger index))tapBlock {
    UIAlertController *alert = [self alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet buttons:buttons isLastButtonCancel:YES tapBlock:tapBlock];
    alert.popoverPresentationController.sourceView = sourceView;
    alert.popoverPresentationController.sourceRect = sourceView.bounds;
    dispatch_async(dispatch_get_main_queue(), ^{
        [ASPFunctions.topMostController presentViewController:alert animated:YES completion:nil];
    });
}

+ (void)actionSheetWithTitle:(nullable NSString *)title message:(nullable NSString *)message sourceView:(UIView *)sourceView buttons:(NSArray<NSString *> *)buttons isLastButtonCancel:(BOOL)isLastButtonCancel permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections tapBlock:(void(^)(UIAlertAction *action, NSInteger index))tapBlock {
    UIAlertController *alert = [self alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet buttons:buttons isLastButtonCancel:isLastButtonCancel tapBlock:tapBlock];
    alert.popoverPresentationController.sourceView = sourceView;
    alert.popoverPresentationController.sourceRect = sourceView.bounds;
    alert.popoverPresentationController.permittedArrowDirections = permittedArrowDirections;
    dispatch_async(dispatch_get_main_queue(), ^{
        [ASPFunctions.topMostController presentViewController:alert animated:YES completion:nil];
    });
}

@end

