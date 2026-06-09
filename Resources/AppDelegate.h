//
//  AppDelegate.h
//  Created by Rustem Galyamov on 23.08.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"

#import "sqlite3.h"
#import <CoreLocation/CoreLocation.h>
#import "LocationShareModel.h"
#import "MLKTabBarController.h"
#import "MLKSplitController.h"

@class LeftTableViewController, DetailViewController;
@class SalesViewController, SalesDetailViewController;
@class HomeViewController;
@class SalesCreateView;

@interface AppDelegate: NSObject <UIApplicationDelegate, CLLocationManagerDelegate> {
    
	UIWindow *window;
	MLKSplitController          *splitViewController;
	MLKSplitController          *splitSalesViewController;
    UIViewController            *startViewController;
    
    HomeViewController          *homeViewController;
    LeftTableViewController     *left;
    SalesViewController         *sales;
    SalesDetailViewController   *salesDetail;
    SalesCreateView             *salesCreate;
    
    MLKTabBarController          *tabBarController;
    
    BOOL                        newPoint;
    
    NSMutableArray              *cust;
    NSMutableArray              *brand;
    NSMutableArray              *contract;
    NSMutableArray              *items;
    NSMutableArray              *basePrice;
    NSMutableArray              *pPrices;
    
    UINavigationController *infoNavController;
    
    UIBackgroundTaskIdentifier bgTask;
    
    BOOL inBackground;
}
@property (nonatomic, readwrite) BOOL inBackground;
@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UISplitViewController *splitViewController;
@property (nonatomic, retain) UISplitViewController *splitSalesViewController;
@property (nonatomic, retain) UIViewController *startViewController;
@property (nonatomic, retain) HomeViewController *homeViewController;
@property (nonatomic, retain) LeftTableViewController *left;
@property (nonatomic, retain) SalesViewController *sales;
@property (nonatomic, retain) SalesDetailViewController *salesDetail;
@property (nonatomic, retain) SalesCreateView *salesCreate;
@property (nonatomic, retain) UITabBarController *tabBarController;
@property (nonatomic, retain) CLLocation *currentLocation;
@property (nonatomic, retain) NSMutableArray *cust;
@property (nonatomic, retain) NSMutableArray *brand;
@property (nonatomic, retain) NSMutableArray *contract;
@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, retain) NSMutableArray *basePrice;
@property (nonatomic, retain) NSMutableArray *pPrices;
@property (nonatomic, strong) LocationShareModel * shareModel;
@property (nonatomic, retain) NSTimer* locationUpdateTimer;

+ (CLLocationManager *)sharedLocationManager;

- (NSTimer*)createTimer;
 
- (void)findLocation;
- (void)createRoute:(float)longitude latitude:(float)latitude;
- (int)getRouteCount:(NSString *)strDate;
- (void)showNotice;
- (BOOL)checkForNew;
- (void)getNotice;
- (void)checkNotice;
- (void)deleteNotice:(NSString *)noticeId;
- (void)checkVersion;
- (void)switchToSalesTab;
 
@end
