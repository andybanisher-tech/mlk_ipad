//
//  SyncError.m
//  MLK
//
//  Created by Андрей on 19.01.14.
//
//

#import "SyncError.h"
#import "HomeViewController.h"
#import "AppDelegate.h"

@implementation SyncError

- (void)errorMessage:(NSString *)error {
    [SVProgressHUD dismiss];
    
    UIViewController *viewController = ASPFunctions.topMostController;
    
    do {
        if ([viewController.presentingViewController isKindOfClass:UIAlertController.class]) {
            [viewController dismissViewControllerAnimated:NO completion:nil];
            viewController = viewController.presentingViewController;
        } else {
            [viewController dismissViewControllerAnimated:NO completion:^{
                [self showRetryAlert:error];
            }];
            break;
        }
    } while (YES);
}

- (void)showRetryAlert:(NSString *)message {
    [AlertWorkerObjc alertWithTitle:@"Ошибка синхронизации. Повторить?" message:message buttons:@[@"Повторить", @"Отмена"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if (index == 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
                HomeViewController *homeViewController = appDelegate.homeViewController;
                [homeViewController syncAllData];
            });
        }
    }];
}

@end
