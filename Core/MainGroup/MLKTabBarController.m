//
//  MLKTabBarController.m
//  mlk
//
//  Created by Damir Sitdikov on 24.12.15.
//
//

#import "MLKTabBarController.h"
#import "SyncStateWorker.h"

#import "GeneratedAssetSymbols.h"

@interface MLKTabBarController () <UITabBarControllerDelegate>

@end

@implementation MLKTabBarController {
    BOOL _tabBarIsSet;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupTabBar];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [NSNotificationCenter.defaultCenter addObserver:self
                                             selector:@selector(syncStateChanged)
                                                 name:kSyncStateChanged
                                               object:nil];
    [self setupSVProgressHUD];
    
    if (@available(iOS 18.0, *)) {
        self.delegate = self;
        self.traitOverrides.horizontalSizeClass = UIUserInterfaceSizeClassUnspecified;
    }
}

- (void)syncStateChanged {
    [self setTabsEnabled:[SyncStateWorker synchronized]];
}

- (void)setTabsEnabled:(BOOL)enabled {
    for (UITabBarItem *tabBarItem in self.tabBar.items) {
        if (tabBarItem != self.tabBar.items.firstObject) {
            tabBarItem.enabled = enabled;
        }
    }
    
    if (enabled) {
        [self updateDocsAndOrderButtons];
    }    
}

- (void)updateDocsAndOrderButtons {
    NSString *zakaz = [PersistenceWorker load:@"zakaz"];
    self.tabBar.items[2].enabled = [zakaz isEqualToString:@"1"] && [SyncStateWorker synchronized];
    self.tabBar.items[3].enabled = [zakaz isEqualToString:@"1"] && [SyncStateWorker synchronized];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - TabBar
- (void)setupTabBar {
    if (_tabBarIsSet) { return; }
    
    UIColor *backgroundColor = [UIColor colorNamed:ACColorNameGrayNavBarBackground];
    
    NSDictionary *normalTitleAttrs = @{NSForegroundColorAttributeName : UIColor.whiteColor, NSFontAttributeName : [UIFont systemFontOfSize:13.0], NSParagraphStyleAttributeName : NSParagraphStyle.defaultParagraphStyle};
    NSDictionary *selectedTitleAttrs = @{NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameMLKBlue], NSFontAttributeName : [UIFont systemFontOfSize:13.0], NSParagraphStyleAttributeName : NSParagraphStyle.defaultParagraphStyle};
    NSDictionary *disabledTitleAttrs = @{NSFontAttributeName : [UIFont systemFontOfSize:13.0], NSParagraphStyleAttributeName : NSParagraphStyle.defaultParagraphStyle};
    UITabBarItemAppearance *tabBarItemAppearance = [UITabBarItemAppearance new];
    tabBarItemAppearance.normal.titleTextAttributes = normalTitleAttrs;
    tabBarItemAppearance.selected.titleTextAttributes = selectedTitleAttrs;
    tabBarItemAppearance.disabled.titleTextAttributes = disabledTitleAttrs;
    
    UITabBarAppearance *tabBarAppearance = [UITabBarAppearance new];
    [tabBarAppearance configureWithOpaqueBackground];
    tabBarAppearance.backgroundColor = backgroundColor;
    tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance;
    tabBarAppearance.inlineLayoutAppearance = tabBarItemAppearance;
    tabBarAppearance.compactInlineLayoutAppearance = tabBarItemAppearance;
    
    self.tabBar.standardAppearance = tabBarAppearance;
    self.tabBar.scrollEdgeAppearance = tabBarAppearance;
    
    NSArray *tabBarTitles = [self tabBarTitles];
    NSArray *tabBarIcons = [self tabBarIcons];
    
    for (int i = 0; i < self.tabBar.items.count; i++) {
        UIImage *tabItemIcon = [ASPFunctions fillImage:[UIImage imageNamed: tabBarIcons[i]] withColor:UIColor.whiteColor];
        UIImage *tabItemSelectedIcon = [ASPFunctions fillImage:[UIImage imageNamed: tabBarIcons[i]] withColor:[UIColor colorNamed:ACColorNameMLKBlue]];
        
        self.tabBar.items[i].image = [tabItemIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.tabBar.items[i].selectedImage = [tabItemSelectedIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.tabBar.items[i].title = tabBarTitles[i];
    }

    [self syncStateChanged];
    
    _tabBarIsSet = YES;
}

#pragma mark - SVProgressHUD
- (void)setupSVProgressHUD {
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleLight];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD setForegroundImageColor:[UIColor colorNamed:ACColorNameMLKBlue]];
    [SVProgressHUD setMinimumDismissTimeInterval:0.8];
    [SVProgressHUD setMaximumDismissTimeInterval:0.9];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(SVProgressHUDDidTouchDownInsideNotification:) name:SVProgressHUDDidTouchDownInsideNotification object:nil];
}

- (void)SVProgressHUDDidTouchDownInsideNotification:(NSNotification*) notification {
    SVProgressHUD *progressHUD = notification.object;
    NSTimer *fadeOutTimer = [progressHUD valueForKey:@"fadeOutTimer"] ;
    if (fadeOutTimer) {
        [SVProgressHUD dismiss];
    }
}

#pragma mark - UITabBarControllerDelegate
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    [UIView setAnimationsEnabled:NO];
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [UIView setAnimationsEnabled:YES];
}

#pragma mark - ConstData
- (NSArray *)tabBarTitles {
    return @[@"МЛК", @"Маршрут", @"Документы", @"Заказ"];
}

- (NSArray *)tabBarIcons {
    return @[ACImageNameTabBarMain, ACImageNameTabBarRoute, ACImageNameTabBarDocuments, ACImageNameTabBarOrder];
}


@end
