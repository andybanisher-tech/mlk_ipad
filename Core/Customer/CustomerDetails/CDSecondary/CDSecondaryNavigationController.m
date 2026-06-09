//
//  CDSecondaryNavigationController.m
//  MLK
//
//  Created by Alexandr Polienko on 30.08.2024.
//

#import "CDSecondaryNavigationController.h"

#import "GeneratedAssetSymbols.h"

@interface CDSecondaryNavigationController () <UINavigationControllerDelegate>

@end

@implementation CDSecondaryNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - Setup UI
- (void)setupUI {
    self.delegate = self;
    
    [ASPFunctions setupNavigationController:self backgroundColor:[ASPFunctions colorFromHex:@"F2F2F7"] titleColor:[ASPFunctions colorFromHex:@"4F4F4F"] tintColor:[UIColor colorNamed:ACColorNameMLKLightBlue]];
    self.navigationBar.standardAppearance.shadowColor = UIColor.clearColor;
    self.navigationBar.scrollEdgeAppearance.shadowColor = UIColor.clearColor;
}

#pragma mark - Button Actions
- (void)closeBarButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Закрыть" style:UIBarButtonItemStyleDone target:self action:@selector(closeBarButtonTapped)];
    viewController.navigationItem.rightBarButtonItem = closeButton;
}

@end
