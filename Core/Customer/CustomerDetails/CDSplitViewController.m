//
//  CDSplitViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 30.08.2024.
//

#import "CDSplitViewController.h"

//VCs
#import "CDPrimaryViewController.h"
#import "CDSecondaryNavigationController.h"

#import "GeneratedAssetSymbols.h"

@implementation CDSplitViewController

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupVCs];
}

#pragma mark - Setup UI
- (void)setupUI {
    self.view.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F2"];
    
    UIView *statusBarUnderlayView = [UIView new];
    statusBarUnderlayView.backgroundColor = [UIColor blackColor];
    statusBarUnderlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:statusBarUnderlayView];
    
    [NSLayoutConstraint activateConstraints:@[
        //StatusBarUnderlayView
        [statusBarUnderlayView.heightAnchor constraintEqualToConstant:ASPFunctions.statusBarHeight],
        [statusBarUnderlayView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [statusBarUnderlayView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [statusBarUnderlayView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
}

- (void)setupVCs {
    CDPrimaryViewController *primaryVC = [[UIStoryboard storyboardWithName:@"CustomerDetails" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(CDPrimaryViewController.class)];
    primaryVC.custAccount = self.custAccount;
    
    UINavigationController *primaryNavVC = [[UINavigationController alloc] initWithRootViewController:primaryVC];
    
    CDSecondaryNavigationController *secondaryNavVC = [CDSecondaryNavigationController new];
    self.viewControllers = @[primaryNavVC, secondaryNavVC];
}

@end
