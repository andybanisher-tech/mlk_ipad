//
//  RegularRouteView.m
//  MLK
//
//  Created by Rustem Galyamov on 29.08.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "RegularRouteView.h"

#import "XMLWriter.h"
#import "PutRouteToServerRequest.h"
#import "PutClientForRouteRequest.h"
#import "MapViewController.h"
#import "PutVisitDateRequest.h"
#import "PutClientsForPDZRequest.h"
#import "GetRouteDistRequest.h"
#import "RWBorderedButton.h"

#import "CustViewController.h"

#import "RouteViewTableSectionHeaderView.h"

#import "GeneratedAssetSymbols.h"

//Constants
static const CGFloat kSectionHeaderHeight = 50.0;

static sqlite3 *database = nil;

@interface RegularRouteView () <RouteViewTableSectionHeaderViewDelegate>
@property (nonatomic, strong) NSMutableArray *routeCustomersArray;

@property (nonatomic, strong) NSMutableArray *nearCustomersArray;
@property (nonatomic, strong) NSArray *filteredNearCustomersArray;

@property (nonatomic, copy) NSString *nearCustomerFilter;
@property (nonatomic, assign) double searchRadius;

@end

@implementation RegularRouteView

@synthesize delegate;
@synthesize custAccountGlobal, custNameGlobal;
@synthesize dateOfMonth;
@synthesize custName, custAddr;
@synthesize routelineNum, approoveReq;
@synthesize apprBtn;
@synthesize visitType;

- (void)createRouteList {
    [SVProgressHUD show];
    
    self.routeCustomersArray = [NSMutableArray new];
    self.nearCustomersArray = [NSMutableArray new];
    
    NSString *strDate;
    if (dateOfMonth) {
        strDate = dateOfMonth;
    } else {
        NSDateFormatter *dateFormatter = NSDateFormatter.new;
        [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
        
        strDate = [dateFormatter stringFromDate:NSDate.date];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (sqlite3_open_v2(SQLWorker.dbPath.UTF8String, &database, SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, NULL) == SQLITE_OK) {
            const char *sql = "select CustForRoute.CustAccount, CustForRoute.DateOfRoute, CustForRoute.RegularRoute, CustForRoute.Status, CustForRoute.CustName, CustForRoute.CustAddress, CustForRoute.NearCust, CustTable.PDZAmount, CustTable.SalesDate, cast(CustForRoute.lineNum as integer) as lnum from CustForRoute JOIN CustTable on CustForRoute.CustAccount = CustTable.CustAccount where CustForRoute.DateOfRoute = ? and CustForRoute.IsDeleted Is Not 1 order by lnum";
            sqlite3_stmt *selectstmt;
            
            if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
                sqlite3_bind_text(selectstmt, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
                
                while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                    NSMutableDictionary *routeObject = [NSMutableDictionary new];
                    
                    NSString *custAcc = @"null";
                    NSString *regularRoute = @"null";
                    NSString *status = @"null";
                    NSString *custName = @"null";
                    NSString *custAddress = @"null";
                    NSString *nearCust;
                    NSString *pdzAmount;
                    NSString *salesDate;
                    
                    if (sqlite3_column_text(selectstmt, 0))
                        custAcc = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                    
                    if (sqlite3_column_text(selectstmt, 2))
                        regularRoute = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                    
                    if (sqlite3_column_text(selectstmt, 3))
                        status = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                    
                    if (sqlite3_column_text(selectstmt, 4))
                        custName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                    
                    if (sqlite3_column_text(selectstmt, 5))
                        custAddress = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                    
                    if (sqlite3_column_text(selectstmt, 6))
                        nearCust = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                    
                    if (sqlite3_column_text(selectstmt, 7))
                        pdzAmount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                    
                    if (sqlite3_column_text(selectstmt, 8))
                        salesDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                    
                    routeObject[@"custAcc"] = custAcc;
                    routeObject[@"regularRoute"] = regularRoute;
                    routeObject[@"status"] = status;
                    routeObject[@"custName"] = custName;
                    routeObject[@"custAddress"] = custAddress;
                    routeObject[@"nearCust"] = nearCust;
                    routeObject[@"pdzAmount"] = pdzAmount;
                    routeObject[@"salesDate"] = salesDate;
                    
                    if (nearCust) {
                        routeObject[@"tasksCount"] = [self tasksCount:custAcc];
                        [self.nearCustomersArray addObject:routeObject];
                    } else {
                        [self.routeCustomersArray addObject:routeObject];
                    }
                }
            }
            sqlite3_finalize(selectstmt);
        }
        sqlite3_close(database);
        
        //Adding Start Route
        NSDictionary *startRouteObject = @{@"custAcc" : @"Start", @"regularRoute" : @"Start", @"status" : @"Start", @"custName" : @"Начало маршрута"};
        [self.routeCustomersArray insertObject:startRouteObject atIndex:0];
        
        //Adding Stop Route
        NSDictionary *stopRouteObject = @{@"custAcc" : @"Stop", @"regularRoute" : @"Stop", @"status" : @"Stop", @"custName" : @"Конец маршрута"};
        [self.routeCustomersArray addObject:stopRouteObject];
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            [self filterNearCustomers];
            
            [SVProgressHUD dismissWithDelay:0.1];
        });
    });
}

- (NSNumber *)tasksCount:(NSString *)custAcc {
    //Selecting Tasks count
    const char *sql = "select count(TaskId) from TaskTable where CustAccount = ? and (Status = 'Открытая' or Status = 'В работе')";
    sqlite3_stmt *selectstmt;
    
    NSNumber *tasksCount;
    if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selectstmt, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(selectstmt) == SQLITE_ROW) {
            if (sqlite3_column_text(selectstmt, 0)) {
                tasksCount = @(sqlite3_column_int(selectstmt, 0));
            }
        }
    }
    sqlite3_finalize(selectstmt);
    
    return tasksCount;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //NavBar Setup
    self.navigationItem.title = @"Маршрут";
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    
    RWBorderedButton *btnScheduler = [RWBorderedButton buttonWithFrame:CGRectMake(0.0, 0.0, 125.0, 30.0) title:@"Планировщик"];
    [btnScheduler addTarget:self action:@selector(btnSchedulerTapped) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *schedulerBarButton = [[UIBarButtonItem alloc] initWithCustomView:btnScheduler];
    
    RWBorderedButton *onMapButton = [RWBorderedButton buttonWithFrame:CGRectMake(0.0, 0.0, 85.0, 30.0) title:@"На карте"];
    [onMapButton addTarget:self
                    action:@selector(allOnMap)
          forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *onmapbutton = [[UIBarButtonItem alloc] initWithCustomView:onMapButton];
    
    RWBorderedButton *aprooveButton = [RWBorderedButton buttonWithFrame:CGRectMake(0.0, 0.0, 110.0, 30.0) title:@"Запрос ПДЗ"];
    [aprooveButton addTarget:self
                      action:@selector(aprooveRoute)
            forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *aprooveBtn = [[UIBarButtonItem alloc] initWithCustomView:aprooveButton];
    apprBtn = aprooveBtn;
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    flexSpace.width = 10.0;
    
    self.navigationItem.leftBarButtonItems = @[schedulerBarButton, onmapbutton, aprooveBtn, flexSpace];
    
    if (self.delegate == nil)
        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    
    [self.tableView registerNib:[UINib nibWithNibName: NSStringFromClass(RouteViewTableSectionHeaderView.class) bundle:nil] forHeaderFooterViewReuseIdentifier:NSStringFromClass(RouteViewTableSectionHeaderView.class)];
    
    [self.tableView setSeparatorColor:UIColor.clearColor];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    RWBorderedButton *editInnerButton = [RWBorderedButton buttonWithFrame:CGRectMake(0.0, 0.0, 90.0, 30.0) title:@"Изменить"];
    [editInnerButton addTarget:self
                        action:@selector(editButtonTapped:)
              forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithCustomView:editInnerButton];
    
    RWBorderedButton *selectDateButton = [RWBorderedButton buttonWithFrame:CGRectMake(0.0, 0.0, 80.0, 30.0) title:dateOfMonth];
    [selectDateButton addTarget:self
                         action:@selector(showCalendar:)
               forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *calButton = [[UIBarButtonItem alloc] initWithCustomView:selectDateButton];
    
    calendarBarButton = calButton;
    [self setDateInCalendarButton:NSDate.date];
    
    UIBarButtonItem *btnRefresh = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:ACImageNameRefresh] style:UIBarButtonItemStylePlain target:self action:@selector(btnRefreshTapped)];
    
    self.navigationItem.rightBarButtonItems = @[btnRefresh, editButton, calButton];
    
    [self locationQuery];
    
    self.searchRadius = LocalAuthWorker.routeNearCustomersSearchRadius;
    
    //Observers
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(createRouteList) name:@"routeRefreshed" object:nil];
}

#pragma mark - ASPDatePickerViewControllerDelegate
- (void)datePickerDidCancel {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)datePickerDidPickDate:(NSDate *)date {
    [self datePickerDidCancel];
    
    NSDateFormatter *formatter = NSDateFormatter.new;
    [formatter setDateFormat:dateFormat_dd_MM_YYYY];
    dateOfMonth = [formatter stringFromDate:date];
    
    [self refreshData];
    
    [self setDateInCalendarButton:date];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(
                                                                      0,
                                                                      0,
                                                                      CGRectGetWidth(self.navigationController.navigationBar.frame),
                                                                      CGRectGetHeight(self.view.frame))];
    
    self.view.backgroundColor = UIColor.clearColor;
    
    [self.tableView setBackgroundView:backgroundView];
    [self.tableView setBackgroundColor:UIColor.clearColor];
    
    UIImageView *bgImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ACImageNameGrayBackground]];
    [backgroundView addSubview:bgImage];
    
    bgImage.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[bgImage.leadingAnchor constraintEqualToAnchor:backgroundView.leadingAnchor],
       [bgImage.trailingAnchor constraintEqualToAnchor:backgroundView.trailingAnchor],
       [bgImage.topAnchor constraintEqualToAnchor:backgroundView.topAnchor],
       [bgImage.bottomAnchor constraintEqualToAnchor:backgroundView.bottomAnchor]]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self createRouteList];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self finalizeStatements];
}

#pragma mark - Button Actions
- (void)btnSchedulerTapped {
    [NavigationWorker openScheduler];
}

- (void)allOnMap {
    mvControllerToolbar = [[MapViewController alloc] initWithNibName:@"MapViewController" bundle:NSBundle.mainBundle];
    
    mvControllerToolbar.isViewPushed = NO;
    
    mvControllerToolbar.custName = custName;
    mvControllerToolbar.custAddr = custAddr;
    mvControllerToolbar.isAllRoute = YES;
    
    if (mvNavController == nil)
        mvNavController = [[UINavigationController alloc] initWithRootViewController:mvControllerToolbar];
    
    mvNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    dispatch_async(dispatch_get_main_queue(),^() {
        [self.navigationController presentViewController:self->mvNavController animated:YES completion:nil];
        self->mvControllerToolbar = nil;
        self->mvNavController     = nil;
    });
}

- (void)aprooveRoute {
    [AlertWorkerObjc alertWithTitle:@"Запрос ПДЗ" message:[NSString stringWithFormat:@"Запросить ПДЗ на текущее число?"] buttons:@[@"Запросить", @"Отменить"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if (index == 0) {
            [self aprooveRouteYes];
        }
    }];
}

- (void)showCalendar:(id)sender {
    if (self.presentedViewController) { return; }
    
    ASPDatePickerViewController *datePickerVC = [ASPDatePickerViewController new];
    datePickerVC.delegate = self;
    datePickerVC.modalPresentationStyle = UIModalPresentationPopover;
    datePickerVC.popoverPresentationController.barButtonItem = calendarBarButton;
    [self presentViewController:datePickerVC animated:YES completion:nil];
}

- (void)editButtonTapped:(id)sender {
    BOOL state = self.editing;
    [self setEditing:!self.tableView.editing animated:YES];
    RWBorderedButton *innerButton = sender;
    [innerButton setHighlightedState:!state];
}

- (void)btnRefreshTapped {
    GetRouteDistRequest *routeRequest = [GetRouteDistRequest new];
    routeRequest.isSingleRequest = YES;
    [routeRequest routeReq:self.searchRadius];
}

- (void)onMap{
    [self custToMap:custAccountGlobal];
    NSLog(@"%@", [NSString stringWithFormat:@"%@ %@", custName, custAddr]);
    
    mvControllerToolbar = [[MapViewController alloc] initWithNibName:@"MapViewController" bundle:NSBundle.mainBundle];
    
    mvControllerToolbar.isViewPushed = NO;
    
    mvControllerToolbar.custName     = custName;
    mvControllerToolbar.custAddr     = custAddr;
    
    if (mvNavController == nil)
        mvNavController = [[UINavigationController alloc] initWithRootViewController:mvControllerToolbar];
    
    mvNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    dispatch_async(dispatch_get_main_queue(),^() {
        [self.navigationController presentViewController:self->mvNavController animated:YES completion:nil];
        self->mvControllerToolbar = nil;
        self->mvNavController     = nil;
    });
}

- (void)clearNearCustomersButtonTapped {
    self.nearCustomerFilter = nil;
    [self filterNearCustomers];
}

- (void)custToMap:(NSString *)custAcc {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql;
        
        if (custAcc)
            //             sql = "select CustName, GPSPoint from CustForRoute where DateOfRoute = ? and CustAccount = ?";
            sql = "SELECT rout.CustName, cust.GPSPoint FROM CustForRoute as rout JOIN CustTable as cust ON rout.CustAccount = cust.CustAccount where rout.DateOfRoute = ? and cust.CustAccount = ?";
        else
            //             sql = "select CustName, GPSPoint from CustForRoute where DateOfRoute = ? and Status = ?";
            sql = "SELECT rout.CustName, cust.GPSPoint FROM CustForRoute as rout JOIN CustTable as cust ON rout.CustAccount = cust.CustAccount WHERE rout.DateOfRoute = ? and rout.Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            
            if (custAcc)
                sqlite3_bind_text(statement, 2, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(statement, 2, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                if (sqlite3_column_text(statement, 0))
                    custName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                else
                    custName = @"null";
                
                if (sqlite3_column_text(statement, 1))
                    custAddr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
                else
                    custAddr = @"null";
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
}

- (NSString *)getCustGPSPoint:(NSString *)custAccount {
    NSString *custGPSPoint = @"null";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select GPSPoint from CustTable where CustAccount = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW) {
                if (sqlite3_column_text(selectstmt, 0))
                    custGPSPoint  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    return custGPSPoint;
}

- (NSString *)getCustAddress:(NSString *)custAccountSQL {
    NSString *custAddres = @"null";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select GPSPoint from CustTable where CustAccount = ?";
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccountSQL UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW) {
                if (sqlite3_column_text(selectstmt, 0))
                    custAddres  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return custAddres;
}

- (void)locationQuery {
    [SVProgressHUD show];
    if (!locationManager) {
        locationManager = [CLLocationManager new];
    }
    
    if (locationManager.authorizationStatus == kCLAuthorizationStatusNotDetermined) {
        [locationManager requestAlwaysAuthorization];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!CLLocationManager.locationServicesEnabled || self->locationManager.authorizationStatus == kCLAuthorizationStatusDenied) {
            dispatch_async(dispatch_get_main_queue(),^() {
                [SVProgressHUD dismiss];
#if !DEBUG
                [AlertWorkerObjc alertWithTitle:@"Служба геолокации отключена" message:@"Включите службу через настройки устройства."];
#endif
            });
        }
    });
    
    newPoint = YES;
    
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (currentLocation) {
        currentLocation = nil;
    }
    currentLocation = locations.firstObject;
    
    if (newPoint) {
        [self findLocation];
    }
    
    [SVProgressHUD dismiss];
}

#pragma mark - RouteViewTableSectionHeaderViewDelegate
- (void)headerShowButtonTapped:(double)searchRadius {
    [self.view endEditing:YES];
    if (self.searchRadius != searchRadius) {
        self.searchRadius = searchRadius;
        [self btnRefreshTapped];
    }
}

#pragma mark -
#pragma mark Internal Methods
- (void)findLocation {
    [locationManager stopUpdatingLocation];
    
    if (currentLocation) {
        if (![custAccountGlobal isEqualToString:@"Start"] && ![custAccountGlobal isEqualToString:@"Stop"] && [custAccountGlobal length] != 0) {
            newPoint = NO;
            [self createRoute:currentLocation.coordinate.longitude latitude:currentLocation.coordinate.latitude completion:^{
                if ([self->visitType isEqualToString:@"Завершить"]) {
                    [self visitedCuctomer:self->custAccountGlobal];
                } else if ([self->visitType isEqualToString:@"Посетить"]) {
                    [self inVisit:self->custAccountGlobal];
                }
                //[self inVisit:custAccountGlobal];
            }];
        }
    }
}

- (void)createRoute:(float)longitude latitude:(float)latitude  completion:(void (^ __nullable)(void))completion {
    NSArray *substrings = [[self getCustGPSPoint:custAccountGlobal] componentsSeparatedByString:@","];
    
    float lat2;
    float long2;
    
    if ([substrings count] == 4) {
        NSString *first     = [substrings objectAtIndex:0];
        NSString *second    = [substrings objectAtIndex:1];
        NSString *fhird     = [substrings objectAtIndex:2];
        NSString *fourth    = [substrings objectAtIndex:3];
        
        long2  = [[NSString stringWithFormat:@"%@.%@", first, second] floatValue];
        lat2 = [[NSString stringWithFormat:@"%@.%@", fhird, fourth] floatValue];
    } else if ([substrings count] == 2) {
            NSString *first     = [substrings objectAtIndex:0];
            NSString *second    = [substrings objectAtIndex:1];
            
            long2  = [[NSString stringWithFormat:@"%@", first] floatValue];
            lat2 = [[NSString stringWithFormat:@"%@",second] floatValue];
        } else {
            long2 = 0;
            lat2  = 0;
        }
    
    
    CLLocation *locA = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    
    CLLocation *locB = [[CLLocation alloc] initWithLatitude:lat2 longitude:long2];
    
    CLLocationDistance distance = [locA distanceFromLocation:locB];  //      distance is expressed in meters
    
    NSString *distanceString = [[NSString alloc] initWithFormat: @"%f", distance];
    
    NSString *delta = [PersistenceWorker load:@"GPSDiff"];
    
    NSLog(@"%i", [distanceString intValue] - [delta intValue]);
    
    if (abs([distanceString intValue]) > [delta intValue]) {
        [AlertWorkerObjc alertWithTitle:nil message:@"Координаты посещения отличаются от координат точки, уточнить координаты?" buttons:@[@"Да", @"Нет"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
            if (index == 0) {
                self->approoveReq = @"1";
            } else {
                self->approoveReq = @"0";
            }
            [self createRouteAfterAlert:longitude latitude:latitude];
            
            completion();
        }];
    } else {
        [self createRouteAfterAlert:longitude latitude:latitude];
        completion();
    }
}

- (void)createRouteAfterAlert:(float)longitude latitude:(float)latitude {
    NSDate *date = NSDate.date;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSString *dateString = [dateFormat stringFromDate:date];
    NSString *timeString = [timeFormat stringFromDate:date];
    NSString *gpsPoint   = [NSString stringWithFormat:@"%f,%f", longitude, latitude];
    
    int lineNum = [self getRouteCount:dateString];
    
    NSString *strLineNum = [NSString stringWithFormat:@"%i", lineNum];
    
    routelineNum = strLineNum;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *addStmt;
        const char *sql = "insert or ignore into Route (DateOfRoute, TimeOfRoute, lineNum, GPSPoint, CustAccount, Status, SendStatus, GPSRequest) Values(?, ?, ?, ?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(addStmt, 1, [dateString UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 2, [timeString UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 3, [strLineNum UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 4, [gpsPoint UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 5, [custAccountGlobal UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 6, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 7, [@"Sended" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 8, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
        NSLog(@"%@", custAccountGlobal);
        
        sqlite3_step(addStmt);
        sqlite3_finalize(addStmt);
    }
    sqlite3_close(database);
}

- (void)createRouteByTapping {
    NSDate *date = NSDate.date;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    
    NSString *dateString = [dateFormat stringFromDate:date];
    NSString *timeString = [timeFormat stringFromDate:date];
    NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.longitude, currentLocation.coordinate.latitude];
    
    int lineNum = [self getRouteCount:dateString];
    
    NSString *strLineNum = [NSString stringWithFormat:@"%i", lineNum];
    
    routelineNum = strLineNum;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *addStmt;
        const char *sql = "insert or ignore into Route (DateOfRoute, TimeOfRoute, lineNum, GPSPoint, CustAccount, Status, SendStatus, GPSRequest) Values(?, ?, ?, ?, ?, ?, ?, ?)";
        
        
        if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(addStmt, 1, [dateString UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 2, [timeString UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 3, [strLineNum UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 4, [gpsPoint UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 5, [custAccountGlobal UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 6, [@"VISIT TAPPED" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 7, [@"Sended" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 8, [@"" UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(addStmt);
        sqlite3_finalize(addStmt);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    [xmlWriter writeStartElement:@"sam:Value"];
    
    [xmlWriter writeStartElement:@"sam:LineNum"];
    [xmlWriter writeCharacters:strLineNum];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:CustAccount"];
    [xmlWriter writeCharacters:custAccountGlobal];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:GPSPoint"];
    [xmlWriter writeCharacters:gpsPoint];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:DateOfRoute"];
    [xmlWriter writeCharacters:dateString];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:TimeOfRoute"];
    [xmlWriter writeCharacters:timeString];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:RegularRoute"];
    [xmlWriter writeCharacters:@"YES"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Status"];
    [xmlWriter writeCharacters:@"VISIT TAPPED"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:ApprooveReq"];
    [xmlWriter writeCharacters:@""];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeEndElement];
    
    // get the resulting XML string
    NSString* xml = [xmlWriter toString];
    
    setRouteToserver = [PutRouteToServerRequest new];
    [setRouteToserver sendRoute:xml];
}

- (void)sendRouteToServerStartStopToDB:(NSString *)custAcc {
    
    NSDate *date = NSDate.date;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    
    NSString *dateString = [dateFormat stringFromDate:date];
    NSString *timeString = [timeFormat stringFromDate:date];
    NSString *gpsPoint   = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.longitude, currentLocation.coordinate.latitude];
    
    int lineNum = [self getRouteCount:dateString];
    
    NSString *strLineNum = [NSString stringWithFormat:@"%i", lineNum];
    
    routelineNum = strLineNum;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *addStmt;
        
        const char *sql = "insert or ignore into Route (DateOfRoute, TimeOfRoute, lineNum, GPSPoint, CustAccount, Status, SendStatus, GPSRequest) Values(?, ?, ?, ?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(addStmt, 1, [dateString UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 2, [timeString UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 3, [strLineNum UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 4, [gpsPoint UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 5, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 6, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 7, [@"new" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 8, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
        NSLog(@"%@", custAccountGlobal);
        
        sqlite3_step(addStmt);
        sqlite3_finalize(addStmt);
    }
    sqlite3_close(database);
}

- (void)sendCustForRoute {
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select CustAccount, DateOfRoute, IsDeleted from CustForRoute where isSended = ? ";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            
            sqlite3_bind_int(selectstmt, 1, 0);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                
                NSString *custAccount   = @"null";
                NSString *DateOfRoute      = @"null";
                NSInteger IsDeleted = 0;
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAccount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    DateOfRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_int(selectstmt, 2))
                    IsDeleted = sqlite3_column_int(selectstmt, 2);
                
                XMLWriter* xmlWriter = [[XMLWriter alloc] init];
                
                [xmlWriter writeStartElement:@"sam:Date"];
                [xmlWriter writeCharacters:DateOfRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CustAccount"];
                [xmlWriter writeCharacters:custAccount];
                [xmlWriter writeEndElement];
                
                NSString *forDel_val = @"";
                
                if (IsDeleted==1) {
                    forDel_val = @"1";
                } else if (IsDeleted==0) {
                    forDel_val = @"0";
                }
                
                [xmlWriter writeStartElement:@"sam:ForDelete"];
                [xmlWriter writeCharacters:forDel_val];
                [xmlWriter writeEndElement];
                
                PutClientForRouteRequest *sendCustForRoute = [[PutClientForRouteRequest alloc] init];
                
                [sendCustForRoute sendMsg:[xmlWriter toString]];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    [self sendRoute];
}

- (void)sendRoute {
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select DateOfRoute, lineNum, GPSPoint, TimeOfRoute, CustAccount, RegularRoute, Status, GPSRequest from Route where SendStatus = ? order by TimeOfRoute ASC";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [@"new" UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *dateOfRoute   = @"null";
                NSString *lineNum       = @"null";
                NSString *GPSPoint      = @"null";
                NSString *timeOfRoute   = @"null";
                NSString *cAccount      = @"null";
                NSString *rRoute        = @"null";
                NSString *status        = @"null";
                NSString *apprReq       = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    dateOfRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    lineNum  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    GPSPoint  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    timeOfRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    cAccount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    rRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    status  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (sqlite3_column_text(selectstmt, 7))
                    apprReq  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:LineNum"];
                [xmlWriter writeCharacters:lineNum];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CustAccount"];
                [xmlWriter writeCharacters:cAccount];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:GPSPoint"];
                [xmlWriter writeCharacters:GPSPoint];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:DateOfRoute"];
                [xmlWriter writeCharacters:dateOfRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:TimeOfRoute"];
                [xmlWriter writeCharacters:timeOfRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:RegularRoute"];
                [xmlWriter writeCharacters:rRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Status"];
                [xmlWriter writeCharacters:status];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ApprooveReq"];
                [xmlWriter writeCharacters:apprReq];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
                
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    // get the resulting XML string
    NSString* xml = [xmlWriter toString];
    
    PutRouteToServerRequest *setRouteToserver = [PutRouteToServerRequest new];
    setRouteToserver.routeType = @"track";
    [setRouteToserver sendRoute:xml];
    
    [self sendCustForRouteOnVisit];
}

- (void)sendCustForRouteOnVisit {
    
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select CustAccount, DateOfRoute, RegularRoute, Status, GPSPoint, TimeOfRoute, GPSRequest from CustForRoute where isSended = ? and Status = ? order by TimeOfRoute ASC";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            
            sqlite3_bind_int(selectstmt, 1, 0);
            sqlite3_bind_text(selectstmt, 2, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                
                NSString *custAccount   = @"null";
                NSString *DateOfRoute   = @"null";
                NSString *RegularRoute  = @"null";
                NSString *Status        = @"null";
                NSString *GPSPoint      = @"null";
                NSString *TimeOfRoute   = @"null";
                NSString *GPSRequest    = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAccount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    DateOfRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    RegularRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    Status = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    GPSPoint  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    TimeOfRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    GPSRequest = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                sqlite3_stmt *selectLineNum;
                const char *sqlLineNum = "select lineNum, Status from Route where CustAccount = ? and DateOfRoute = ? ";
                
                NSString *LineNumVisit = @"";
                NSString *LineNumTapped = @"";
                
                if (sqlite3_prepare_v2(database, sqlLineNum, -1, &selectLineNum, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_text(selectLineNum, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selectLineNum, 2, [DateOfRoute UTF8String], -1, SQLITE_TRANSIENT);
                    while (sqlite3_step(selectLineNum) == SQLITE_ROW)
                    {
                        NSString *statusRoute = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectLineNum, 1)];
                        if ([statusRoute isEqualToString:@"visit"]) {
                            LineNumVisit = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectLineNum, 0)];
                            NSLog(@"Line Num visit = %@",LineNumVisit);
                        } else if ([statusRoute isEqualToString:@"VISIT TAPPED"]) {
                            LineNumTapped = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectLineNum, 0)];
                            NSLog(@"Line Num tapped = %@",LineNumTapped);
                        }
                        
                    }
                    sqlite3_finalize(selectLineNum);
                }
                [self sendRoutesByTapping:custAccount date:DateOfRoute time:TimeOfRoute GPSPoint:GPSPoint LineNumTapped:LineNumTapped];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:LineNum"];
                [xmlWriter writeCharacters:LineNumVisit];
                [xmlWriter writeEndElement];
                //NSLog(@"Line Num = %@",LineNum);
                
                [xmlWriter writeStartElement:@"sam:CustAccount"];
                [xmlWriter writeCharacters:custAccount];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:GPSPoint"];
                [xmlWriter writeCharacters:GPSPoint];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:DateOfRoute"];
                [xmlWriter writeCharacters:DateOfRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:TimeOfRoute"];
                [xmlWriter writeCharacters:TimeOfRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:RegularRoute"];
                [xmlWriter writeCharacters:RegularRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Status"];
                [xmlWriter writeCharacters:Status];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ApprooveReq"];
                [xmlWriter writeCharacters:GPSRequest];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    NSString* xml = [xmlWriter toString];
    
    PutRouteToServerRequest *setRouteToserver;
    setRouteToserver = [PutRouteToServerRequest new];
    [setRouteToserver sendRoute:xml];
    
    [self sendCustForRouteOnVisited];
}

- (void)sendRoutesByTapping:(NSString *)custAcc date:(NSString *)date time:(NSString *)time GPSPoint:(NSString *)GPSPoint LineNumTapped:(NSString *)LineNumTapped {
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    [xmlWriter writeStartElement:@"sam:Value"];
    
    [xmlWriter writeStartElement:@"sam:LineNum"];
    [xmlWriter writeCharacters:LineNumTapped];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:CustAccount"];
    [xmlWriter writeCharacters:custAcc];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:GPSPoint"];
    [xmlWriter writeCharacters:GPSPoint];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:DateOfRoute"];
    [xmlWriter writeCharacters:date];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:TimeOfRoute"];
    [xmlWriter writeCharacters:time];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:RegularRoute"];
    [xmlWriter writeCharacters:@"YES"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Status"];
    [xmlWriter writeCharacters:@"VISIT TAPPED"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:ApprooveReq"];
    [xmlWriter writeCharacters:@""];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeEndElement];
    
    // get the resulting XML string
    NSString* xml = [xmlWriter toString];
    
    PutRouteToServerRequest *setRouteToserver = [PutRouteToServerRequest new];
    [setRouteToserver sendRoute:xml];
}

- (void)sendCustForRouteOnVisited {
    
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select CustAccount, LastVisitDate from CustTable where isSended = ?";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_int(selectstmt, 1, 0);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *customer = @"null";
                NSString *lvd   = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    customer  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    lvd  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:CustomerID"];
                [xmlWriter writeCharacters:customer];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:LastVisitDate"];
                [xmlWriter writeCharacters:lvd];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
                
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    // get the resulting XML string
    NSString* xml = [xmlWriter toString];
    
    PutVisitDateRequest  *sendLVDToServer = [PutVisitDateRequest new];
    [sendLVDToServer sendLVD:xml];
}

- (void)updateRouteStatusAfterSend:(NSString *)custAcc {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *updateStmt;
        
        const char *sql = "update Route Set SendStatus = ? where CustAccount = ? and DateOfRoute = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [@"Sended" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_bind_text(updateStmt, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
    }
    sqlite3_close(database);
    
    [self createRouteList];
}

- (int)getCustForRouteCount:(NSString *)strDate {
    int countLine = 0;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select count(*) from CustForRoute where DateOfRoute = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW )
                countLine  = sqlite3_column_int(statement, 0);
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return countLine;
}


-(int)getRouteCount:(NSString *)strDate {
    int countLine = 0;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select count(*) from Route where DateOfRoute = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW )
                countLine  = sqlite3_column_int(statement, 0);
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return countLine;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.routeCustomersArray.count;
    } else {
        return self.filteredNearCustomersArray.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kSectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0.0;
    } else {
        return kSectionHeaderHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.routeCustomersArray.count > 0 || self.filteredNearCustomersArray.count > 0) {
        RouteViewTableSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass(RouteViewTableSectionHeaderView.class)];
        headerView.delegate = self;
        headerView.searchDistanceTextField.text = [NSString stringWithFormat:@"%.2f", self.searchRadius];
        
        return headerView;
    } else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *CellIdentifier1 = @"Cell1";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier1];
            
            UIFont *cellFont = [UIFont systemFontOfSize:17.0];
            cell.textLabel.font = cellFont;
            
            UIButton *clearNearCustomersButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 60.0, 7.0, 40.0, 40.0)];
            clearNearCustomersButton.tag = 3333;
            [clearNearCustomersButton addTarget:self action:@selector(clearNearCustomersButtonTapped) forControlEvents:UIControlEventTouchUpInside];
            [clearNearCustomersButton setImage:[UIImage imageNamed:ACImageNameClearNearCust] forState:UIControlStateNormal];
            [cell.contentView addSubview:clearNearCustomersButton];
            
            UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0,50.f - 1.f/UIScreen.mainScreen.scale,CGRectGetWidth(tableView.frame),1.f/UIScreen.mainScreen.scale)];
            [separatorView setBackgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground]];
            [cell addSubview:separatorView];
        }
        
        NSDictionary *object = self.routeCustomersArray[indexPath.row];
        NSString *regularRoute = object[@"regularRoute"];
        
        if ([regularRoute isEqualToString:@"Start"]) {
            cell.imageView.image = [self IsStart] ? [UIImage imageNamed:ACImageNameCheckmarkSelected] : [UIImage imageNamed:ACImageNameCheckmark];
        } else if ([regularRoute isEqualToString:@"Stop"]) {
            cell.imageView.image = [self IsStop] ? [UIImage imageNamed:ACImageNameCheckmarkSelected] : [UIImage imageNamed:ACImageNameCheckmark];
        } else {
            cell.imageView.image = nil;
        }
        
        cell.textLabel.text = object[@"custName"];
        
        [cell.contentView viewWithTag:3333].hidden = ![self.nearCustomerFilter isEqualToString:object[@"custAcc"]];
        
        return cell;
    } else {
        static NSString *CellIdentifier2 = @"Cell2";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier2];
            cell.backgroundColor = UIColor.whiteColor;
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 5.0, 500.0, 20.0)];
            label.tag = 1001;
            [cell.contentView addSubview:label];
            
            UILabel *detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 25.0, 500.0, 20.0)];
            detailLabel.textColor = UIColor.lightGrayColor;
            detailLabel.tag = 1002;
            detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
            detailLabel.numberOfLines = 0;
            [cell.contentView addSubview:detailLabel];
            
            RWBorderedButton *taskCount = [RWBorderedButton buttonWithFrame:CGRectMake(self.view.frame.size.width - 60.0, 7, 40, 35) title:@""];
            taskCount.backgroundColor = [UIColor darkGrayColor];
            taskCount.tag                    = 2001;
            taskCount.layer.cornerRadius     = 5;
            taskCount.clipsToBounds          = YES;
            taskCount.titleLabel.textColor   = UIColor.whiteColor;
            taskCount.userInteractionEnabled = NO;
            [cell.contentView addSubview:taskCount];
            
            RWBorderedButton *dateOfSalesButton = [RWBorderedButton buttonWithFrame:CGRectMake(taskCount.frame.origin.x - 140.0, 7.0, 125.0, 35.0) title:@""];
            dateOfSalesButton.backgroundColor = [UIColor darkGrayColor];
            dateOfSalesButton.tag = 1003;
            dateOfSalesButton.layer.cornerRadius = 5;
            dateOfSalesButton.clipsToBounds = YES;
            dateOfSalesButton.titleLabel.textColor = UIColor.whiteColor;
            dateOfSalesButton.userInteractionEnabled = NO;
            [cell.contentView addSubview:dateOfSalesButton];
            
            UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0,50.f - 1.f/UIScreen.mainScreen.scale,CGRectGetWidth(tableView.frame),1.f/UIScreen.mainScreen.scale)];
            [separatorView setBackgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground]];
            [cell addSubview:separatorView];
        }
        
        NSDictionary *object = self.filteredNearCustomersArray[indexPath.row];
        
        UILabel *label = (UILabel *)[cell.contentView viewWithTag:1001];
        label.text = object[@"custName"];
        
        UILabel *detailLabel = (UILabel *)[cell.contentView viewWithTag:1002];
        detailLabel.text = object[@"custAddress"];
        
        NSString *pdzAmount = object[@"pdzAmount"];
        if (![pdzAmount isEqualToString:@"0"]) {
            label.text = [NSString stringWithFormat:@"\u2757 %@", label.text];
        }
        
        RWBorderedButton *taskCount = (RWBorderedButton *)[cell.contentView viewWithTag:2001];
        NSInteger count = [object[@"tasksCount"] integerValue];
        if (count > 0) {
            [taskCount setTitle:[NSString stringWithFormat:@"%ld", (long)count] forState:UIControlStateNormal];
            taskCount.hidden = NO;
        } else {
            [taskCount setTitle:@"" forState:UIControlStateNormal];
            taskCount.hidden = YES;
        }
        
        RWBorderedButton *dateOfSalesButton = (RWBorderedButton *)[cell.contentView viewWithTag:1003];
        NSString *salesDate = object[@"salesDate"];
        if (!salesDate || [salesDate isEqualToString:@"null"]) {
            dateOfSalesButton.hidden = YES;
        } else {
            dateOfSalesButton.hidden = NO;
            [dateOfSalesButton setTitle:salesDate forState:UIControlStateNormal];
        }
        
        return cell;
    }
}

- (void)updateLineNum:(NSString *)custAccount lineNum:(NSString *)lineNum{
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *updateStmt;
        
        const char *sql = "update CustForRoute Set lineNum = ? where CustAccount = ? and DateOfRoute = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [lineNum UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        
        if (dateOfMonth)
            sqlite3_bind_text(updateStmt, 3, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
        else
            sqlite3_bind_text(updateStmt, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
}

- (void)aprooveRouteYes {
    PutClientsForPDZRequest *sendPDZ = [[PutClientsForPDZRequest alloc] init];
    sendPDZ.notShowProgress = YES;
    [sendPDZ sendPDZ:nil];
}

- (void)sendRouteToServer:(NSString *)date {
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select CustAccount, DateOfRoute, RegularRoute, Status, lineNum, GPSPoint, TimeOfRoute, GPSRequest from CustForRoute where DateOfRoute = ?";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [date UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custAcc       = @"null";
                NSString *dateOfRoute   = @"null";
                NSString *regularRoute  = @"null";
                NSString *status        = @"null";
                NSString *lineNum       = @"null";
                NSString *GPSPoint      = @"null";
                NSString *timeOfRoute   = @"null";
                NSString *apprReq       = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAcc  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    dateOfRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    regularRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    status  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    lineNum  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    GPSPoint  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    timeOfRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (sqlite3_column_text(selectstmt, 7))
                    apprReq  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:LineNum"];
                [xmlWriter writeCharacters:lineNum];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CustAccount"];
                [xmlWriter writeCharacters:custAcc];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:GPSPoint"];
                [xmlWriter writeCharacters:GPSPoint];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:DateOfRoute"];
                [xmlWriter writeCharacters:dateOfRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:TimeOfRoute"];
                [xmlWriter writeCharacters:timeOfRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:RegularRoute"];
                [xmlWriter writeCharacters:regularRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Status"];
                [xmlWriter writeCharacters:status];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ApprooveReq"];
                [xmlWriter writeCharacters:apprReq];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
                
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    // get the resulting XML string
    NSString* xml = [xmlWriter toString];
    
    setRouteToserver = [PutRouteToServerRequest new];
    [setRouteToserver sendRoute:xml];
}

- (void)sendRouteToServerInVisit:(NSString *)date custAccount:(NSString *)custAcc {
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.longitude, currentLocation.coordinate.latitude];
    //test coord
    //NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", 55.014288, 72.939572];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *dateTime           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:dateTime];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSString *timeString = [timeFormat stringFromDate:dateTime];
    
    int lineNum = [self getRouteCount:date];
    
    NSString *strLineNum = [NSString stringWithFormat:@"%i", lineNum];
    
    
    [xmlWriter writeStartElement:@"sam:Value"];
    
    [xmlWriter writeStartElement:@"sam:LineNum"];
    //uncomm alex - linenum
    [xmlWriter writeCharacters:strLineNum];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:CustAccount"];
    [xmlWriter writeCharacters:custAcc];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:GPSPoint"];
    [xmlWriter writeCharacters:gpsPoint];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:DateOfRoute"];
    [xmlWriter writeCharacters:strDate];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:TimeOfRoute"];
    [xmlWriter writeCharacters:timeString];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:RegularRoute"];
    [xmlWriter writeCharacters:@"YES"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Status"];
    [xmlWriter writeCharacters:@"visit"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:ApprooveReq"];
    [xmlWriter writeCharacters:@""];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeEndElement];
    
    // get the resulting XML string
    NSString *xml = [xmlWriter toString];
    
    setRouteToserver = [PutRouteToServerRequest new];
    setRouteToserver.delegate = self;
    
    if ([custAcc isEqualToString:@"Start"]) {
        setRouteToserver.start = YES;
    } else if ([custAcc isEqualToString:@"Stop"]) {
            setRouteToserver.stop = YES;
        } else {
            setRouteToserver.visit = YES;
            setRouteToserver.visited = NO;
            setRouteToserver.cancelVisit = NO;
        }
    
    [setRouteToserver sendRoute:xml];
}

- (void)sendRouteToServerVisited:(NSString *)date custAccount:(NSString *)custAcc {
    [SVProgressHUD showWithStatus:@"Отправка данных"];
    
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.longitude, currentLocation.coordinate.latitude];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *dateTime           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:dateTime];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSString *timeString = [timeFormat stringFromDate:dateTime];
    
    int lineNum = [self getRouteCount:date];
    
    NSString *strLineNum = [NSString stringWithFormat:@"%i", lineNum];
    
    
    [xmlWriter writeStartElement:@"sam:Value"];
    
    [xmlWriter writeStartElement:@"sam:LineNum"];
    //uncomm alex - linenum
    [xmlWriter writeCharacters:strLineNum];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:CustAccount"];
    [xmlWriter writeCharacters:custAcc];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:GPSPoint"];
    [xmlWriter writeCharacters:gpsPoint];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:DateOfRoute"];
    [xmlWriter writeCharacters:strDate];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:TimeOfRoute"];
    [xmlWriter writeCharacters:timeString];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:RegularRoute"];
    [xmlWriter writeCharacters:@"YES"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Status"];
    [xmlWriter writeCharacters:@"visited"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:ApprooveReq"];
    [xmlWriter writeCharacters:@""];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeEndElement];
    
    // get the resulting XML string
    NSString *xml = [xmlWriter toString];
    
    setRouteToserver = [PutRouteToServerRequest new];
    setRouteToserver.delegate = self;
    
    setRouteToserver.visited = YES;
    setRouteToserver.visit = NO;
    setRouteToserver.cancelVisit = NO;
    
    [setRouteToserver sendRoute:xml];
}

- (void)sendRouteToServerCancelVisit:(NSString *)date custAccount:(NSString *)custAcc {
    [SVProgressHUD showWithStatus:@"Отправка данных"];
    
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.longitude, currentLocation.coordinate.latitude];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *dateTime           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:dateTime];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSString *timeString = [timeFormat stringFromDate:dateTime];
    
    int lineNum = [self getRouteCount:date];
    
    NSString *strLineNum = [NSString stringWithFormat:@"%i", lineNum];
    
    
    [xmlWriter writeStartElement:@"sam:Value"];
    
    [xmlWriter writeStartElement:@"sam:LineNum"];
    //uncomm alex - linenum
    [xmlWriter writeCharacters:strLineNum];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:CustAccount"];
    [xmlWriter writeCharacters:custAcc];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:GPSPoint"];
    [xmlWriter writeCharacters:gpsPoint];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:DateOfRoute"];
    [xmlWriter writeCharacters:strDate];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:TimeOfRoute"];
    [xmlWriter writeCharacters:timeString];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:RegularRoute"];
    [xmlWriter writeCharacters:@"YES"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Status"];
    [xmlWriter writeCharacters:@""];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:ApprooveReq"];
    [xmlWriter writeCharacters:@""];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeEndElement];
    
    // get the resulting XML string
    NSString *xml = [xmlWriter toString];
    
    setRouteToserver = [PutRouteToServerRequest new];
    setRouteToserver.delegate = self;
    
    setRouteToserver.cancelVisit = YES;
    setRouteToserver.visited = NO;
    setRouteToserver.visit = NO;
    
    [setRouteToserver sendRoute:xml];
}

- (void)sendRouteToServerInCancelVisit:(NSString *)date custAccount:(NSString *)custAcc {
    [SVProgressHUD showWithStatus:@"Отправка данных"];
    
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    
    NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.longitude, currentLocation.coordinate.latitude];
    //test coord
    //NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", 55.014288, 72.939572];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *dateTime           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:dateTime];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSString *timeString = [timeFormat stringFromDate:dateTime];
    
    int lineNum = [self getRouteCount:date];
    
    NSString *strLineNum = [NSString stringWithFormat:@"%i", lineNum];
    
    
    [xmlWriter writeStartElement:@"sam:Value"];
    
    [xmlWriter writeStartElement:@"sam:LineNum"];
    //uncomm alex - linenum
    [xmlWriter writeCharacters:strLineNum];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:CustAccount"];
    [xmlWriter writeCharacters:custAcc];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:GPSPoint"];
    [xmlWriter writeCharacters:gpsPoint];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:DateOfRoute"];
    [xmlWriter writeCharacters:strDate];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:TimeOfRoute"];
    [xmlWriter writeCharacters:timeString];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:RegularRoute"];
    [xmlWriter writeCharacters:@"YES"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Status"];
    [xmlWriter writeCharacters:@""];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:ApprooveReq"];
    [xmlWriter writeCharacters:@""];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeEndElement];
    
    // get the resulting XML string
    NSString *xml = [xmlWriter toString];
    
    setRouteToserver = [PutRouteToServerRequest new];
    setRouteToserver.delegate = self;
    if ([custAcc isEqualToString:@"Start"]) {
        setRouteToserver.start = YES;
    } else if ([custAcc isEqualToString:@"Stop"]) {
        setRouteToserver.stop = YES;
    } else {
        setRouteToserver.visit = NO;
    }
    
    [setRouteToserver sendRoute:xml];
}

-(BOOL)routeIsAprooved:(NSString *)routeDate {
    BOOL isAprooved = NO;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select RegularRoute from CustForRoute where DateOfRoute = ? and RegularRoute = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [routeDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [@"Yes" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                isAprooved = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return isAprooved;
}

-(BOOL)custIsAprooved:(NSString *)routeDate custAccount:(NSString *)custAcc {
    BOOL isAprooved = FALSE;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select RegularRoute from CustForRoute where DateOfRoute = ? and CustAccount = ? and RegularRoute = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [routeDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [@"Yes" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                isAprooved = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return isAprooved;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSDictionary *object = self.routeCustomersArray[indexPath.row];
        NSString *status = object[@"status"];
        
        if ([status isEqualToString:@"Start"] || [status isEqualToString:@"Stop"]) {
            cell.backgroundColor = [ASPFunctions colorFromHex:@"2ECCCD"];
        } else if ([status isEqual:@"visited"]) {
            cell.backgroundColor = [ASPFunctions colorFromHex:@"7DE779"];
        } else if ([status isEqual:@"visit"]) {
            cell.backgroundColor = [ASPFunctions colorFromHex:@"6395EC"];
        } else {
            cell.backgroundColor = [ASPFunctions colorFromHex:@"BDBDBD"];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0) {
        
        NSDictionary *object = self.routeCustomersArray[indexPath.row];
        NSString *custAcc = object[@"custAcc"];
        NSString *custName = object[@"custName"];
        
        if ([self.delegate respondsToSelector:@selector(showActionSheet:custName:)]) {
            [self.delegate showActionSheet:custAcc custName:custName];
        } else {
            [self viewActionSheet:custAcc custName:custName sourceView:cell];
        }
    } else {
        NSDictionary *object = self.filteredNearCustomersArray[indexPath.row];
        [self showNearCustomerAlert:object sourceView:cell];
    }
}

- (void)viewActionSheet:(NSString *)custAccount custName:(NSString *)custName sourceView:(UIView *)sourceView {
    if ([ASPFunctions.topMostController isKindOfClass:UIAlertController.class]) {
        return;
    }
    
    custAccountGlobal = custAccount;
    custNameGlobal = custName;
    
    BOOL custinvisit  = [self custInVisit:custAccount];
    BOOL custvisited  = [self custVisited:custAccount];
    BOOL anycustvisit = [self anyCustInVisit];
    
    // Andrey +
    BOOL start = [self IsStart];
    BOOL stop = [self IsStop];
    
    if ([custAccount isEqualToString:@"Start"]) {
        if (start == false) {
            [AlertWorkerObjc alertWithTitle:@"Начать маршрут?" message:nil buttons:@[@"Начать", @"Отмена"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
                if (index == 0) {
                    //need to uncom
                    [self locationQuery];
                    
                    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                    NSDate          *date           = NSDate.date;
                    
                    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                    
                    NSString *strDate = [dateFormatter stringFromDate:date];
                    [self sendRouteToServerStartStopToDB:@"Start"];
                    [self sendRouteToServerStartStop:strDate custAccount:@"Start"];
                }
            }];
        } else {
            [AlertWorkerObjc alertWithTitle:@"Маршрут уже начат"];
        }
        
    } else if ([custAccount isEqualToString:@"Stop"]) {
        if (stop == false && start == YES) {
            [AlertWorkerObjc alertWithTitle:@"Закончить маршрут?" message:nil buttons:@[@"Закончить", @"Отмена"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
                if (index == 0) {
                    //need to uncom
                    [self locationQuery];
                    
                    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                    NSDate          *date           = NSDate.date;
                    
                    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                    
                    NSString *strDate = [dateFormatter stringFromDate:date];
                    [self sendRouteToServerStartStopToDB:@"Stop"];
                    [self sendRouteToServerStartStop:strDate custAccount:@"Stop"];
                }
            }];
        } else if (stop == false && start == false) {
            [AlertWorkerObjc alertWithTitle:@"Маршрут не начат"];
        } else {
            [AlertWorkerObjc alertWithTitle:@"Маршрут уже закончен"];
        }
    } else {
        NSArray *buttonsArray;
        
        NSString *nearCustFilterTitle = [custAccount isEqualToString:self.nearCustomerFilter] ? @"Отменить фильтр" : @"Фильтр клиентов рядом";
        if (custinvisit && ![self IsStop]) {
            buttonsArray = @[@"Отменить визит", @"Завершить визит", @"Карточка клиента", @"Показать на карте", nearCustFilterTitle, @"Отмена"];
        } else if (custvisited || (anycustvisit && ![self IsStop]) || [self IsStop] || (![self IsStop] && ![self IsStart])) {
            buttonsArray = @[@"Карточка клиента", @"Показать на карте", nearCustFilterTitle, @"Отмена"];
        } else {
            buttonsArray = @[@"Посетить", @"Карточка клиента", @"Показать на карте", nearCustFilterTitle, @"Отмена"];
        }
        
        [AlertWorkerObjc actionSheetWithTitle:custAccount message:nil sourceView:sourceView buttons:buttonsArray tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
            if ([action.title isEqual:@"Посетить"]) {
                //[self inVisit:custAccountGlobal];
                self->visitType = @"Посетить";
                [self locationQuery];
            }
            
            if ([action.title isEqual:@"Отменить визит"]) {
                [self cancelVisit:self->custAccountGlobal];
            }
            
            if ([action.title isEqual:@"Завершить визит"]) {
                self->visitType = @"Завершить";
                [self locationQuery];
                //[self visitedCuctomer:custAccountGlobal];
            }
            
            if ([action.title isEqual:@"Карточка клиента"]) {
                [self openCustomerDetails];
            }
            
            if ([action.title isEqual:@"Показать на карте"]) {
                [self onMap];
            }
            
            if ([action.title isEqualToString:nearCustFilterTitle]) {
                if ([self.nearCustomerFilter isEqualToString:custAccount]) {
                    self.nearCustomerFilter = nil;
                } else {
                    self.nearCustomerFilter = custAccount;
                }
                
                [self filterNearCustomers];
            }
        }];
    }
}

- (void)showNearCustomerAlert:(NSDictionary *)object sourceView:(UIView *)sourceView {
    custAccountGlobal = object[@"custAcc"];
    custNameGlobal = object[@"custName"];
    
    [AlertWorkerObjc actionSheetWithTitle:custAccountGlobal message:nil sourceView:sourceView buttons:@[@"Добавить в маршрут", @"Карточка клиента", @"Показать на карте", @"Отмена"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if ([action.title isEqual:@"Добавить в маршрут"]) {
            NSString *strDate;
            if (self->dateOfMonth) {
                strDate = self->dateOfMonth;
            } else {
                NSDateFormatter *dateFormatter = NSDateFormatter.new;
                dateFormatter.dateFormat = dateFormat_dd_MM_YYYY;
                
                strDate = [dateFormatter stringFromDate:NSDate.date];
            }
            CustViewController *custVC = [CustViewController new];
            [custVC addCustomersToRoute:self->custAccountGlobal custName:self->custNameGlobal custAddr:object[@"custAddress"] strDate:strDate];
            [self createRouteList];
        }
        
        if ([action.title isEqual:@"Карточка клиента"]) {
            [self openCustomerDetails];
        }
        
        if ([action.title isEqual:@"Показать на карте"]) {
            [self onMap];
        }
    }];
}

-(BOOL)custInVisit:(NSString *)custAcc {
    BOOL visit = FALSE;
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from CustForRoute where DateOfRoute = ? and CustAccount = ? and Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                visit = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return visit;
}

-(BOOL)anyCustInVisit {
    BOOL visit = FALSE;
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from CustForRoute where DateOfRoute = ? and Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                visit = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return visit;
}


-(BOOL)custVisited:(NSString *)custAcc {
    BOOL visited = FALSE;
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from CustForRoute where DateOfRoute = ? and CustAccount = ? and Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [@"visited" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                visited = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return visited;
}

- (void)openCustomerDetails {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NavigationWorker openCustomerDetails:self->custAccountGlobal];
    });
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSDictionary *object = self.routeCustomersArray[indexPath.row];
        NSString *regularRoute = object[@"regularRoute"];
        if (![regularRoute isEqualToString:@"Start"] && ![regularRoute isEqualToString:@"Stop"]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    if (editing == YES)
        self.editButtonItem.tintColor = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
    else
        self.editButtonItem.tintColor = UIColor.clearColor;
    
    [super setEditing: editing animated: animated];
    [self.tableView setEditing:editing animated:animated];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSDictionary *object = self.routeCustomersArray[indexPath.row];
        NSString *regularRoute = object[@"regularRoute"];
        if (![regularRoute isEqualToString:@"Start"] && ![regularRoute isEqualToString:@"Stop"]) {
            return YES;
        }
    }
    
    
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSDictionary *objectToMove = self.routeCustomersArray[fromIndexPath.row];
    [self.routeCustomersArray removeObjectAtIndex:fromIndexPath.row];
    [self.routeCustomersArray insertObject:objectToMove atIndex:toIndexPath.row];
    
    for (int i = 0; i < self.routeCustomersArray.count; i++) {
        NSString *custAcc = self.routeCustomersArray[i][@"custAcc"];
        
        [self updateLineNum:custAcc lineNum:[NSString stringWithFormat:@"%i", i]];
        [self refreshData];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isAprooved;
    BOOL isvisited;
    
    NSDictionary *object = self.routeCustomersArray[indexPath.row];
    NSString *custAcc = object[@"custAcc"];
    
    isvisited = [self custVisited:custAcc];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (dateOfMonth)
        isAprooved = [self custIsAprooved:dateOfMonth custAccount:custAcc];
    else
        isAprooved = [self custIsAprooved:strDate custAccount:custAcc];
    
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //Delete the object from the table.
        if (! isvisited) {
            if (! isAprooved) {
                [self removeRouteCustomerAtIndexPath:indexPath];
                
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                
                [tableView reloadData];
                
                [self.delegate routeIsUpdated];
            }
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSDictionary *object = self.routeCustomersArray[indexPath.row];
        NSString *regularRoute = object[@"regularRoute"];
        if (![regularRoute isEqualToString:@"Start"] && ![regularRoute isEqualToString:@"Stop"]) {
            return UITableViewCellEditingStyleDelete;
        }
    }
    
    return UITableViewCellEditingStyleNone;
}

- (void)removeRouteCustomerAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *object = self.routeCustomersArray[indexPath.row];
    NSString *custAcc = object[@"custAcc"];
    
    [self.routeCustomersArray removeObjectAtIndex:indexPath.row];
    [self removeCustomersFromRoute:custAcc];
}

- (void)visited:(NSString *)custAccount {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    if (dateOfMonth)
        [self sendRouteToServerVisited:dateOfMonth custAccount:custAccount];
    else
        [self sendRouteToServerVisited:strDate custAccount:custAccount];
}

- (void)cancelVisit:(NSString *)custAccount {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    if (dateOfMonth)
        [self sendRouteToServerCancelVisit:dateOfMonth custAccount:custAccount];
    else
        [self sendRouteToServerCancelVisit:strDate custAccount:custAccount];
    
}

- (void)inVisit:(NSString *)custAccount {
    //test coord
    //NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", 55.014288, 72.939572];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    /*if (sqlite3_open([dbPath UTF8String], &database) == SQLITE_OK)
     {
     sqlite3_stmt *updateStmt;
     //TODO: bug_fix & gps check
     
     if (![first isEqualToString:@"0"])
     {
     const char *sql = "update CustForRoute Set Status = ?, GPSPoint = ?, TimeOfRoute = ?, GPSRequest = ?, isSended = ? where CustAccount = ? and DateOfRoute = ?";
     
     sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
     
     sqlite3_bind_text(updateStmt, 1, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
     sqlite3_bind_text(updateStmt, 2, [gpsPoint UTF8String], -1, SQLITE_TRANSIENT);
     sqlite3_bind_text(updateStmt, 3, [timeString UTF8String], -1, SQLITE_TRANSIENT);
     sqlite3_bind_text(updateStmt, 4, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
     sqlite3_bind_int(updateStmt, 5, 0);
     
     sqlite3_bind_text(updateStmt, 6, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
     
     if (dateOfMonth)
     sqlite3_bind_text(updateStmt, 7, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
     else
     sqlite3_bind_text(updateStmt, 7, [strDate UTF8String], -1, SQLITE_TRANSIENT);
     }
     else
     {
     const char *sql = "update CustForRoute Set Status = ?, TimeOfRoute = ?, GPSRequest = ?, isSended = ? where CustAccount = ? and DateOfRoute = ?";
     
     sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
     
     sqlite3_bind_text(updateStmt, 1, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
     sqlite3_bind_text(updateStmt, 2, [timeString UTF8String], -1, SQLITE_TRANSIENT);
     sqlite3_bind_text(updateStmt, 3, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
     sqlite3_bind_int(updateStmt, 4, 0);
     
     sqlite3_bind_text(updateStmt, 5, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
     
     if (dateOfMonth)
     sqlite3_bind_text(updateStmt, 6, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
     else
     sqlite3_bind_text(updateStmt, 6, [strDate UTF8String], -1, SQLITE_TRANSIENT);
     }
     
     sqlite3_step(updateStmt);
     sqlite3_finalize(updateStmt);
     sqlite3_close(database);
     }
     else
     sqlite3_close(database);*/
    
    if (dateOfMonth)
        [self sendRouteToServerInVisit:dateOfMonth custAccount:custAccount];
    else
        [self sendRouteToServerInVisit:strDate custAccount:custAccount];
}

- (void)refreshData{
    [self createRouteList];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (dateOfMonth) {
        [self setStateForApprBtn:FALSE];
        
        if ([strDate isEqualToString:dateOfMonth])
            [self setStateForApprBtn:YES];
    } else {
        [self setStateForApprBtn:YES];
    }
}

- (void)setStateForApprBtn:(BOOL)state {
    [apprBtn setEnabled:state];
}

- (void)visitedCuctomer:(NSString *)custAccount {
    [SVProgressHUD showWithStatus:@"Отправка данных"];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    [dateFormatter setDateFormat:dateFormat_YYYY_MM_dd];
    
    NSString *strDateComp = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *updateStmt;
        
        const char *sql = "update CustForRoute Set Status = ?, isSended = ? where CustAccount = ? and DateOfRoute = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [@"visited" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(updateStmt, 2, 0);
        sqlite3_bind_text(updateStmt, 3, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        
        if (dateOfMonth)
            sqlite3_bind_text(updateStmt, 4, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
        else
            sqlite3_bind_text(updateStmt, 4, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        
        
        sqlite3_stmt *updateVisitDate;
        
        const char *sqlDate = "update CustTable Set LastVisitDate = ?, LVDateComp = ?, isSended = ? where CustAccount = ?";
        
        sqlite3_prepare_v2(database, sqlDate, -1, &updateVisitDate, NULL);
        
        sqlite3_bind_text(updateVisitDate, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateVisitDate, 2, [strDateComp UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(updateVisitDate, 3, 0);
        sqlite3_bind_text(updateVisitDate, 4, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateVisitDate);
        sqlite3_finalize(updateVisitDate);
    }
    sqlite3_close(database);
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    
    NSString *dateString = [dateFormat stringFromDate:date];
    NSString *timeString = [timeFormat stringFromDate:date];
    NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.longitude, currentLocation.coordinate.latitude];
    
    int lineNum = [self getRouteCount:dateString];
    
    NSString *strLineNum = [NSString stringWithFormat:@"%i", lineNum];
    
    routelineNum = strLineNum;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *addStmt;
        const char *sql = "insert or ignore into Route (DateOfRoute, TimeOfRoute, lineNum, GPSPoint, CustAccount, Status, SendStatus, GPSRequest) Values(?, ?, ?, ?, ?, ?, ?, ?)";
        
        
        if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(addStmt, 1, [dateString UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 2, [timeString UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 3, [strLineNum UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 4, [gpsPoint UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 5, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 6, [@"visited" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 7, [@"Sended" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 8, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(addStmt);
        sqlite3_finalize(addStmt);
    }
    sqlite3_close(database);
    
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    [xmlWriter writeStartElement:@"sam:Value"];
    
    [xmlWriter writeStartElement:@"sam:LineNum"];
    [xmlWriter writeCharacters:strLineNum];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:CustAccount"];
    [xmlWriter writeCharacters:custAccount];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:GPSPoint"];
    [xmlWriter writeCharacters:gpsPoint];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:DateOfRoute"];
    [xmlWriter writeCharacters:dateString];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:TimeOfRoute"];
    [xmlWriter writeCharacters:timeString];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:RegularRoute"];
    [xmlWriter writeCharacters:@""];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Status"];
    [xmlWriter writeCharacters:@"visited"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:ApprooveReq"];
    [xmlWriter writeCharacters:@""];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeEndElement];
    
    NSString *xml = [xmlWriter toString];
    
    PutRouteToServerRequest *setRouteToserver = [PutRouteToServerRequest new];
    setRouteToserver.delegate = self;
    setRouteToserver.visited = YES;
    setRouteToserver.visit = NO;
    setRouteToserver.cancelVisit = NO;
    
    [setRouteToserver sendRoute:xml];
    [self sendLVD:custAccount];
}

- (void)removeCustomersFromRoute:(NSString *)custAccount {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    PutClientForRouteRequest *sendCustForRoute = [[PutClientForRouteRequest alloc] init];
    sendCustForRoute.custAccount = custAccount;
    
    if (dateOfMonth)
        sendCustForRoute.date = dateOfMonth;
    else
        sendCustForRoute.date = strDate;
    
    sendCustForRoute.delegate = self;
    sendCustForRoute.forDelete = YES;
    sendCustForRoute.notShowProgress = YES;
    [self removeCustomerFromRouteDB:custAccount];
    [sendCustForRoute sendCust];
}

- (void)removeCustomerFromRouteDB:(NSString *)custAccount {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *deleteStmt;
        
        //const char *sql = "delete from CustForRoute where CustAccount = ? and DateOfRoute = ?";
        const char *sql = "update CustForRoute set isSended = ? , IsDeleted = ? where CustAccount = ? and DateOfRoute = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL);
        //When binding parameters, index starts from 1 and not zero.
        sqlite3_bind_int(deleteStmt, 1, 0);
        sqlite3_bind_int(deleteStmt, 2, 1);
        sqlite3_bind_text(deleteStmt, 3, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        if (dateOfMonth)
            sqlite3_bind_text(deleteStmt, 4, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
        else
            sqlite3_bind_text(deleteStmt, 4, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(deleteStmt);
        sqlite3_finalize(deleteStmt);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
}

- (void)isSendedForDelete:(NSString *)custAccount {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *deleteStmt;
        
        const char *sql = "delete from CustForRoute where CustAccount = ? and DateOfRoute = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL);
        //When binding parameters, index starts from 1 and not zero.
        sqlite3_bind_text(deleteStmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        if (dateOfMonth)
            sqlite3_bind_text(deleteStmt, 2, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
        else
            sqlite3_bind_text(deleteStmt, 2, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(deleteStmt);
        sqlite3_finalize(deleteStmt);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
}

- (void)finalizeStatements {
    if (database) sqlite3_close(database);
}

- (void)sendLVD:(NSString *)custAccount {
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select CustAccount, LastVisitDate from CustTable where CustAccount = ?";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *customer = @"null";
                NSString *lvd   = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    customer  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    lvd  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:CustomerID"];
                [xmlWriter writeCharacters:customer];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:LastVisitDate"];
                [xmlWriter writeCharacters:lvd];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
                
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    // get the resulting XML string
    NSString* xml = [xmlWriter toString];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strVLDDate = [dateFormatter stringFromDate:date];
    
    PutVisitDateRequest    *sendLVDToServer = [PutVisitDateRequest new];
    sendLVDToServer.curCustAcc          = custAccount;
    sendLVDToServer.curStrDate          = strVLDDate;
    sendLVDToServer.notShowErrorMessage = YES;
    [sendLVDToServer sendLVD:xml];
}

// Andrey +
- (void)sendRouteToServerStartStop:(NSString *)_date custAccount:(NSString *)custAcc {
    [SVProgressHUD showWithStatus:@"Отправка данных"];
    
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    NSDate *date = NSDate.date;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    
    NSString *dateString = [dateFormat stringFromDate:date];
    NSString *timeString = [timeFormat stringFromDate:date];
    
    
    [xmlWriter writeStartElement:@"sam:Value"];
    
    [xmlWriter writeStartElement:@"sam:LineNum"];
    [xmlWriter writeCharacters:@"0"];//lineNum];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:CustAccount"];
    [xmlWriter writeCharacters:custAcc];
    [xmlWriter writeEndElement];
    
    NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.longitude, currentLocation.coordinate.latitude];
    
    [xmlWriter writeStartElement:@"sam:GPSPoint"];
    [xmlWriter writeCharacters:gpsPoint];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:DateOfRoute"];
    [xmlWriter writeCharacters:dateString];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:TimeOfRoute"];
    [xmlWriter writeCharacters:timeString];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:RegularRoute"];
    [xmlWriter writeCharacters:@"YES"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Status"];
    [xmlWriter writeCharacters:@"VISIT"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:ApprooveReq"];
    [xmlWriter writeCharacters:@""];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeEndElement];
    
    // get the resulting XML string
    NSString *xml = [xmlWriter toString];
    
    setRouteToserver = [PutRouteToServerRequest new];
    setRouteToserver.delegate = self;
    if ([custAcc isEqualToString:@"Start"])
        setRouteToserver.start = YES;
    if ([custAcc isEqualToString:@"Stop"])
        setRouteToserver.stop = YES;
    [setRouteToserver sendRoute:xml];
}

- (BOOL)IsStart {
    BOOL isStart = false;
    
    NSDate *date = NSDate.date;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *routeDate;
    
    if (dateOfMonth)
        routeDate = dateOfMonth;
    else
        routeDate = [dateFormat stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from StartStop where Date = ? and Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [routeDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [@"START" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                isStart = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return isStart;
}

- (void)addStart {
    
    NSDate *date = NSDate.date;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *routeDate = [dateFormat stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "insert or ignore into StartStop (Date, Status, isSended) Values(?, ?, ?)";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(statement, 1, [routeDate UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [@"START" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(statement, 3, 0);
        
        sqlite3_step(statement);
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
}

-(BOOL)IsStop{
    BOOL isStop = false;
    
    NSDate *date = NSDate.date;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *routeDate;
    
    if (dateOfMonth)
        routeDate = dateOfMonth;
    else
        routeDate = [dateFormat stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from StartStop where Date = ? and Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [routeDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [@"STOP" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                isStop = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return isStop;
}

- (void)addStop{
    BOOL start = [self IsStart];
    if (!start) {
        [AlertWorkerObjc alertWithTitle:@"Маршрут не начат"];
    } else {
        NSDate *date = NSDate.date;
        
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
        
        NSString *routeDate = [dateFormat stringFromDate:date];
        
        if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
            const char *sql = "insert or ignore into StartStop (Date, Status, isSended) Values(?, ?, ?)";
            sqlite3_stmt *statement;
            
            if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            sqlite3_bind_text(statement, 1, [routeDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [@"STOP" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(statement, 3, 0);
            
            sqlite3_step(statement);
            sqlite3_finalize(statement);
        }
        sqlite3_close(database);
    }
}

#pragma mark - SetRouteToServerDelegate
- (void)isSendStart {
    [self addStart];
    [self updateRouteStatusAfterSend:@"Start"];
    
    [SVProgressHUD dismiss];
}

- (void)isSendStop{
    [self addStop];
    [self updateRouteStatusAfterSend:@"Stop"];
    
    [SVProgressHUD dismiss];
}

- (void)isSendVisit {
    NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.longitude, currentLocation.coordinate.latitude];
    //test coord
    //NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", 55.014288, 72.939572];
    NSArray *substrings = [gpsPoint componentsSeparatedByString:@"."];
    
    NSString *first     = [substrings objectAtIndex:0];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSString *timeString = [timeFormat stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *updateStmt;
        //TODO: bug_fix & gps check
        
        if (![first isEqualToString:@"0"]) {
            const char *sql = "update CustForRoute Set Status = ?, GPSPoint = ?, TimeOfRoute = ?, GPSRequest = ?, isSended = ? where CustAccount = ? and DateOfRoute = ?";
            
            sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
            
            sqlite3_bind_text(updateStmt, 1, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [gpsPoint UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [timeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 4, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateStmt, 5, 1);
            
            sqlite3_bind_text(updateStmt, 6, [custAccountGlobal UTF8String], -1, SQLITE_TRANSIENT);
            
            if (dateOfMonth)
                sqlite3_bind_text(updateStmt, 7, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(updateStmt, 7, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        } else {
            const char *sql = "update CustForRoute Set Status = ?, TimeOfRoute = ?, GPSRequest = ?, isSended = ? where CustAccount = ? and DateOfRoute = ?";
            
            sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
            
            sqlite3_bind_text(updateStmt, 1, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [timeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateStmt, 4, 1);
            
            sqlite3_bind_text(updateStmt, 5, [custAccountGlobal UTF8String], -1, SQLITE_TRANSIENT);
            
            if (dateOfMonth)
                sqlite3_bind_text(updateStmt, 6, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(updateStmt, 6, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        }
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
    }
    sqlite3_close(database);
    
    [self openCustomerDetails];
    
    [self createRouteList];
    
    [SVProgressHUD dismiss];
}

- (void)isSendVisitNotSendStatus {
    NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.longitude, currentLocation.coordinate.latitude];
    //test coord
    //NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", 55.014288, 72.939572];
    NSArray *substrings = [gpsPoint componentsSeparatedByString:@"."];
    
    NSString *first     = [substrings objectAtIndex:0];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSString *timeString = [timeFormat stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *updateStmt;
        //TODO: bug_fix & gps check
        
        if (![first isEqualToString:@"0"]) {
            const char *sql = "update CustForRoute Set Status = ?, GPSPoint = ?, TimeOfRoute = ?, GPSRequest = ?, isSended = ? where CustAccount = ? and DateOfRoute = ?";
            
            sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
            
            sqlite3_bind_text(updateStmt, 1, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [gpsPoint UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [timeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 4, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateStmt, 5, 0);
            
            sqlite3_bind_text(updateStmt, 6, [custAccountGlobal UTF8String], -1, SQLITE_TRANSIENT);
            
            if (dateOfMonth)
                sqlite3_bind_text(updateStmt, 7, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(updateStmt, 7, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        } else {
            const char *sql = "update CustForRoute Set Status = ?, TimeOfRoute = ?, GPSRequest = ?, isSended = ? where CustAccount = ? and DateOfRoute = ?";
            
            sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
            
            sqlite3_bind_text(updateStmt, 1, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [timeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateStmt, 4, 0);
            
            sqlite3_bind_text(updateStmt, 5, [custAccountGlobal UTF8String], -1, SQLITE_TRANSIENT);
            
            if (dateOfMonth)
                sqlite3_bind_text(updateStmt, 6, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(updateStmt, 6, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        }
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
    }
    sqlite3_close(database);
    
    [self openCustomerDetails];
    
    [self createRouteList];
    
    [SVProgressHUD dismiss];
}

- (void)isSendVisitedNotSendStatus {
    NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.longitude, currentLocation.coordinate.latitude];
    //test coord
    //NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", 55.014288, 72.939572];
    NSArray *substrings = [gpsPoint componentsSeparatedByString:@"."];
    
    NSString *first     = [substrings objectAtIndex:0];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSString *timeString = [timeFormat stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *updateStmt;
        //TODO: bug_fix & gps check
        
        if (![first isEqualToString:@"0"]) {
            const char *sql = "update CustForRoute Set Status = ?, GPSPoint = ?, TimeOfRoute = ?, GPSRequest = ?, isSended = ? where CustAccount = ? and DateOfRoute = ?";
            
            sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
            
            sqlite3_bind_text(updateStmt, 1, [@"visited" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [gpsPoint UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [timeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 4, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateStmt, 5, 0);
            
            sqlite3_bind_text(updateStmt, 6, [custAccountGlobal UTF8String], -1, SQLITE_TRANSIENT);
            
            if (dateOfMonth)
                sqlite3_bind_text(updateStmt, 7, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(updateStmt, 7, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        } else {
            const char *sql = "update CustForRoute Set Status = ?, TimeOfRoute = ?, GPSRequest = ?, isSended = ? where CustAccount = ? and DateOfRoute = ?";
            
            sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
            
            sqlite3_bind_text(updateStmt, 1, [@"visited" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [timeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateStmt, 4, 0);
            
            sqlite3_bind_text(updateStmt, 5, [custAccountGlobal UTF8String], -1, SQLITE_TRANSIENT);
            
            if (dateOfMonth)
                sqlite3_bind_text(updateStmt, 6, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(updateStmt, 6, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        }
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
    }
    sqlite3_close(database);
    
    [self createRouteList];
    
    [SVProgressHUD dismiss];
}

- (void)isSendCancelVisitNotSendStatus {
    NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.longitude, currentLocation.coordinate.latitude];
    //test coord
    //NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", 55.014288, 72.939572];
    NSArray *substrings = [gpsPoint componentsSeparatedByString:@"."];
    
    NSString *first     = [substrings objectAtIndex:0];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSString *timeString = [timeFormat stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *updateStmt;
        //TODO: bug_fix & gps check
        
        if (![first isEqualToString:@"0"]) {
            const char *sql = "update CustForRoute Set Status = ?, GPSPoint = ?, TimeOfRoute = ?, GPSRequest = ?, isSended = ? where CustAccount = ? and DateOfRoute = ?";
            
            sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
            
            sqlite3_bind_text(updateStmt, 1, [@"" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [gpsPoint UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [timeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 4, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateStmt, 5, 0);
            
            sqlite3_bind_text(updateStmt, 6, [custAccountGlobal UTF8String], -1, SQLITE_TRANSIENT);
            
            if (dateOfMonth)
                sqlite3_bind_text(updateStmt, 7, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(updateStmt, 7, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        } else {
            const char *sql = "update CustForRoute Set Status = ?, TimeOfRoute = ?, GPSRequest = ?, isSended = ? where CustAccount = ? and DateOfRoute = ?";
            
            sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
            
            sqlite3_bind_text(updateStmt, 1, [@"" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [timeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateStmt, 4, 0);
            
            sqlite3_bind_text(updateStmt, 5, [custAccountGlobal UTF8String], -1, SQLITE_TRANSIENT);
            
            if (dateOfMonth)
                sqlite3_bind_text(updateStmt, 6, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(updateStmt, 6, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        }
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
    }
    sqlite3_close(database);
    
    [self createRouteList];
    
    [SVProgressHUD dismiss];
}

- (void)isSendVisited {
    NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.longitude, currentLocation.coordinate.latitude];
    //test coord
    //NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", 55.014288, 72.939572];
    NSArray *substrings = [gpsPoint componentsSeparatedByString:@"."];
    
    NSString *first     = [substrings objectAtIndex:0];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSString *timeString = [timeFormat stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *updateStmt;
        //TODO: bug_fix & gps check
        
        if (![first isEqualToString:@"0"]) {
            const char *sql = "update CustForRoute Set Status = ?, GPSPoint = ?, TimeOfRoute = ?, GPSRequest = ?, isSended = ? where CustAccount = ? and DateOfRoute = ?";
            
            sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
            
            sqlite3_bind_text(updateStmt, 1, [@"visited" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [gpsPoint UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [timeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 4, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateStmt, 5, 1);
            
            sqlite3_bind_text(updateStmt, 6, [custAccountGlobal UTF8String], -1, SQLITE_TRANSIENT);
            
            if (dateOfMonth)
                sqlite3_bind_text(updateStmt, 7, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(updateStmt, 7, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        } else {
            const char *sql = "update CustForRoute Set Status = ?, TimeOfRoute = ?, GPSRequest = ?, isSended = ? where CustAccount = ? and DateOfRoute = ?";
            
            sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
            
            sqlite3_bind_text(updateStmt, 1, [@"visited" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [timeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateStmt, 4, 1);
            
            sqlite3_bind_text(updateStmt, 5, [custAccountGlobal UTF8String], -1, SQLITE_TRANSIENT);
            
            if (dateOfMonth)
                sqlite3_bind_text(updateStmt, 6, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(updateStmt, 6, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        }
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
    }
    sqlite3_close(database);
    
    [self createRouteList];
    
    [SVProgressHUD dismiss];
}

- (void)isSendCancelVisit {
    NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.longitude, currentLocation.coordinate.latitude];
    //test coord
    //NSString *gpsPoint = [NSString stringWithFormat:@"%f,%f", 55.014288, 72.939572];
    NSArray *substrings = [gpsPoint componentsSeparatedByString:@"."];
    
    NSString *first     = [substrings objectAtIndex:0];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSString *timeString = [timeFormat stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *updateStmt;
        //TODO: bug_fix & gps check
        
        if (![first isEqualToString:@"0"]) {
            const char *sql = "update CustForRoute Set Status = ?, GPSPoint = ?, TimeOfRoute = ?, GPSRequest = ?, isSended = ? where CustAccount = ? and DateOfRoute = ?";
            
            sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
            
            sqlite3_bind_text(updateStmt, 1, [@"" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [gpsPoint UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [timeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 4, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateStmt, 5, 1);
            
            sqlite3_bind_text(updateStmt, 6, [custAccountGlobal UTF8String], -1, SQLITE_TRANSIENT);
            
            if (dateOfMonth)
                sqlite3_bind_text(updateStmt, 7, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(updateStmt, 7, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        } else {
            const char *sql = "update CustForRoute Set Status = ?, TimeOfRoute = ?, GPSRequest = ?, isSended = ? where CustAccount = ? and DateOfRoute = ?";
            
            sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
            
            sqlite3_bind_text(updateStmt, 1, [@"" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [timeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [approoveReq UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateStmt, 4, 1);
            
            sqlite3_bind_text(updateStmt, 5, [custAccountGlobal UTF8String], -1, SQLITE_TRANSIENT);
            
            if (dateOfMonth)
                sqlite3_bind_text(updateStmt, 6, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(updateStmt, 6, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        }
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
    }
    sqlite3_close(database);
    
    [self createRouteList];
    
    [SVProgressHUD dismiss];
}

- (void)failedToPutCustForRoute:(NSString *)status {
    [SVProgressHUD dismiss];
    
    [AlertWorkerObjc alertWithTitle:@"Ошибка!" message:[NSString stringWithFormat:@"%@\n\n%@", status, @"Повторите последнее действие"]];
    
    [self createRouteList];
}

#pragma mark - Helpers
- (void)filterNearCustomers {
    if (!self.nearCustomerFilter) {
        self.filteredNearCustomersArray = self.nearCustomersArray;
    } else {
        self.filteredNearCustomersArray = [self.nearCustomersArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable object, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [object[@"nearCust"] localizedStandardContainsString:self.nearCustomerFilter];
        }]];
    }
    
    [self.tableView reloadData];
}

#pragma mark - UpdateCalendarButton Title
- (void)setDateInCalendarButton:(NSDate *)newDate {
    if (calendarBarButton) {
        RWBorderedButton *innerButton = calendarBarButton.customView;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"dd.MM.yy"];
        [innerButton setTitle:[formatter stringFromDate:newDate] forState:UIControlStateNormal];
    }
}

@end
