//
//  RegularRouteView.h
//  MLK
//
//  Created by Rustem Galyamov on 29.08.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import <CoreLocation/CoreLocation.h>
#import "PutClientForRouteRequest.h"
#import "PutRouteToServerRequest.h"
#import "MapViewController.h"

#import "ASPDatePickerViewController.h"

@protocol RouteControllerDelegate <NSObject>
- (void)showActionSheet:(NSString *)custAccount custName:(NSString *)custName;
- (void)routeIsUpdated;
- (void)setStateForApprBtn:(BOOL)state;
@end

@class MapViewController;

@interface RegularRouteView : UITableViewController <UITableViewDelegate,UITableViewDataSource, CLLocationManagerDelegate, PutClientForRouteRequestDelegate, PutRouteToServerRequestDelegate, ASPDatePickerViewControllerDelegate> {
    
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    
    BOOL newPoint;
    
    MapViewController       *mvControllerToolbar;
	UINavigationController  *mvNavController;
    
    NSString    *custAccountGlobal;
    NSString    *custNameGlobal;
    
    NSString            *dateOfMonth;
    PutRouteToServerRequest    *setRouteToserver;
    
    NSString    *custName;
    NSString    *custAddr;
    NSString    *routelineNum;
    NSString    *approoveReq;

    id apprBtn;

    NSString            *visitType;
    //mini
    UIBarButtonItem *calendarBarButton;
}
@property(nonatomic, weak) id<RouteControllerDelegate> delegate;
@property(nonatomic,retain) NSString *custAccountGlobal;
@property(nonatomic,retain) NSString *custNameGlobal;
@property(nonatomic,retain) NSString *dateOfMonth;
@property(nonatomic,retain) NSString *custName;
@property(nonatomic,retain) NSString *custAddr;
@property(nonatomic,retain) NSString *routelineNum;
@property(nonatomic,retain) NSString *approoveReq;
@property(nonatomic,retain)id apprBtn;
@property(nonatomic,retain) NSString *visitType;

- (void)locationQuery;
- (void)findLocation;
- (void)finalizeStatements;
- (void)removeCustomersFromRoute:(NSString *)custAccount;
- (void)removeCustomerFromRouteDB:(NSString *)custAccount;
- (void)inVisit:(NSString *)custAccount;
- (void)updateLineNum:(NSString *)custAccount lineNum:(NSString *)lineNum;
- (void)refreshData;
- (void)aprooveRoute;
-(BOOL)routeIsAprooved:(NSString *)routeDate;
-(BOOL)custIsAprooved:(NSString *)routeDate custAccount:(NSString *)custAcc;
- (void)sendRouteToServer:(NSString *)date;
- (void)sendRouteToServerInVisit:(NSString *)date custAccount:(NSString *)custAcc;
- (void)sendRouteToServerStartStopToDB:(NSString *)custAcc;
-(BOOL)custInVisit:(NSString *)custAcc;
-(BOOL)custVisited:(NSString *)custAcc;
-(BOOL)anyCustInVisit;
- (void)custToMap:(NSString *)custAcc;
- (void)cancelVisit:(NSString *)custAccount;
-(int)getRouteCount:(NSString *)strDate;
-(int)getCustForRouteCount:(NSString *)strDate;
- (void)createRouteAfterAlert:(float)longitude latitude:(float)latitude;
- (void)isSendVisit;
- (void)isSendVisited;
@end
