//
//  NavigationWorker.m
//  MLK
//
//  Created by Alexandr Polienko on 30.08.2024.
//

#import "NavigationWorker.h"

//VCs
#import "CDSplitViewController.h"
#import "SchedulerViewController.h"

@implementation NavigationWorker

#pragma mark - CustomerDetails
+ (void)openCustomerDetails:(NSString *)custAccount {
    CDSplitViewController *splitVC = [[UIStoryboard storyboardWithName:@"CustomerDetails" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(CDSplitViewController.class)];
    splitVC.modalPresentationStyle = UIModalPresentationFullScreen;
    splitVC.custAccount = custAccount;

    [ASPFunctions.topMostController presentViewController:splitVC animated:YES completion:nil];
}

#pragma mark - Scheduler
+ (void)openScheduler {
    SchedulerViewController *schedulerVC = [[UIStoryboard storyboardWithName:@"Scheduler" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(SchedulerViewController.class)];
    
    UINavigationController *schedulerNavVC = [[UINavigationController alloc] initWithRootViewController:schedulerVC];
    schedulerNavVC.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [ASPFunctions.topMostController presentViewController:schedulerNavVC animated:YES completion:nil];
}

@end
