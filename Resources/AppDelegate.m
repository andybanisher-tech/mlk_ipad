//
//  AppDelegate.m
//  Created by Rustem Galyamov on 23.08.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.

#import "AppDelegate.h"

#import "HomeViewController.h"
#import "LeftTableViewController.h"
#import "SalesViewController.h"
#import "SalesDetailViewController.h"
#import "SalesCreateView.h"
#import "NoticeViewController.h"

#import "GetListOfNotificationsRequest.h"
#import "SyncStateWorker.h"
#import "CheckVersionRequest.h"

// Andrey +
#import "XMLWriter.h"
#import "PutRouteToServerRequest.h"
#import "MLKSplitController.h"
// Andrey -

#import <YandexMapsMobile/YMKMapKitFactory.h>

#import "BackgroundTaskManager.h"

#import "GeneratedAssetSymbols.h"

static sqlite3 *database = nil;

//Constants
static NSString *const kYandexMapKitApiKey = @"f6837089-3af0-4b4e-814b-8e16f2b25cd1";

@implementation AppDelegate

@synthesize window, splitViewController, left, tabBarController;
@synthesize splitSalesViewController, sales, salesDetail, salesCreate;
@synthesize startViewController, homeViewController;
@synthesize cust;
@synthesize brand;
@synthesize contract;
@synthesize items;
@synthesize basePrice;
@synthesize pPrices;
@synthesize inBackground;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self createDBIfNeeded];
    
    //YadnexMapKit
    [YMKMapKit setApiKey:kYandexMapKitApiKey];
    [YMKMapKit mapKit];
    
    UITableView.appearance.sectionHeaderTopPadding = 0.0;
    
    CGRect frame = UIScreen.mainScreen.bounds;
    /*frame = CGRectInset(frame, 0, 10);
     frame = CGRectOffset(frame,0,10);*/
    window = [[UIWindow alloc] initWithFrame:frame];
    window.backgroundColor = [UIColor blackColor];
    //[window makeKeyAndVisible];
    
    //Домашняя страница
    //startViewController = [[UIViewController alloc] init];
    //startViewController.title = @"Home";
    
    homeViewController = [[HomeViewController alloc] init];
    homeViewController.title = @"МЛК";
    
    //Маршрутизация
    splitViewController = [[MLKSplitController alloc] init];
    splitViewController.title = @"Маршрут";
    
    left = [[LeftTableViewController alloc] initWithStyle:UITableViewStylePlain];
    
    //NavBar 1 Setup
    UINavigationController *nav1 = [[UINavigationController alloc] initWithRootViewController:left];
    [ASPFunctions setupNavigationController:nav1 backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    
    splitViewController.viewControllers = @[nav1];
    
    //Заказы
    splitSalesViewController = [[MLKSplitController alloc] init];
    splitSalesViewController.title = @"Документы";
    splitSalesViewController.view.backgroundColor = [UIColor greenColor];
    
    salesDetail = [[SalesDetailViewController alloc] init];
    splitSalesViewController.delegate = salesDetail;
    
    sales = [[SalesViewController alloc] initWithStyle:UITableViewStylePlain];
    sales.detailViewController = salesDetail;
    
    //NavBar 2 Setup
    UINavigationController *nav2 = [[UINavigationController alloc] initWithRootViewController:sales];
    [ASPFunctions setupNavigationController:nav2 backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    
    splitSalesViewController.viewControllers = [NSArray arrayWithObjects:nav2, salesDetail, nil];
    
    salesCreate = [[SalesCreateView alloc] init];
    salesCreate.title = @"Заказ";
    salesCreate.isViewPushed = YES;
    
    UINavigationController *nav3 = [[UINavigationController alloc] initWithRootViewController:salesCreate];
    
    self.tabBarController = [MLKTabBarController new];
    tabBarController.viewControllers = @[homeViewController, splitViewController, splitSalesViewController, nav3];
    
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    
    UIApplication.sharedApplication.idleTimerDisabled = YES;
    
    if ([self checkForNew] == YES)
        [self showNotice];
    
    self.shareModel = [LocationShareModel sharedModel];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    CLLocationManager *locationManager = AppDelegate.sharedLocationManager;
    locationManager.delegate = self;
    locationManager.allowsBackgroundLocationUpdates = YES;
    if (locationManager.authorizationStatus == kCLAuthorizationStatusNotDetermined) {
        [locationManager requestAlwaysAuthorization];
    }
    
    [self startLocationTracking];
    
    NSTimeInterval time = 60.0;
    
    self.locationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:time
                                                                target:self
                                                              selector:@selector(findLocation)
                                                              userInfo:nil
                                                               repeats:YES];
    //[self createTimer];
    [self createNoticeTimer];
    // Andrey +
    //[self createRouteTimer];
    // Andrey -
    //[self checkVersion];
    
    return YES;
}

- (NSTimer *)createTimer {
    return [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(findLocation) userInfo:nil repeats:YES];
}

- (NSTimer *)createNoticeTimer {
    return [NSTimer scheduledTimerWithTimeInterval:600.0 target:self selector:@selector(getNotice) userInfo:nil repeats:YES];
}

- (void)getNotice {
    UIApplicationState state = [UIApplication.sharedApplication applicationState];
    
    if (state == UIApplicationStateBackground || state == UIApplicationStateInactive) {
        return;
    } else {
        GetListOfNotificationsRequest *noticeRequest = [GetListOfNotificationsRequest new];
        noticeRequest.notShowProgress = YES;
        [noticeRequest noticeReq];
    }
}

// Andrey +
- (NSTimer*)createRouteTimer {
    return [NSTimer scheduledTimerWithTimeInterval:70.0 target:self selector:@selector(getRouteToServer) userInfo:nil repeats:YES];
}

- (void)getRouteToServer {
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select DateOfRoute, lineNum, GPSPoint, TimeOfRoute, CustAccount, RegularRoute, Status from Route where SendStatus = ?";
        
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
                [xmlWriter writeCharacters:status];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
                
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    // get the resulting XML string
    NSString* xml = [xmlWriter toString];
    
    PutRouteToServerRequest *setRouteToserver = [PutRouteToServerRequest new];
    
    setRouteToserver.visit       = NO;
    setRouteToserver.visited     = NO;
    setRouteToserver.cancelVisit = NO;
    
    setRouteToserver.routeType   = @"track";
    
    [setRouteToserver sendRoute:xml];
}

- (void)checkVersion {
    CheckVersionRequest *verReq = [CheckVersionRequest new];
    verReq.notShowProgress = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [verReq verReq];
    });
}

- (void)startLocationTracking {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!CLLocationManager.locationServicesEnabled) {
            [AlertWorkerObjc alertWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled"];
        } else {
            CLLocationManager *locationManager = AppDelegate.sharedLocationManager;
            CLAuthorizationStatus authorizationStatus = locationManager.authorizationStatus;
            
            if (authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways) {
                locationManager.delegate = self;
                locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
                locationManager.distanceFilter = kCLDistanceFilterNone;
                locationManager.allowsBackgroundLocationUpdates = YES;
                [locationManager startUpdatingLocation];
            }
        }
    });
}

+ (CLLocationManager *)sharedLocationManager {
    static CLLocationManager *_locationManager;
    
    @synchronized(self) {
        if (_locationManager == nil) {
            _locationManager = [CLLocationManager new];
            _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
            _locationManager.allowsBackgroundLocationUpdates = YES;
        }
    }
    
    return _locationManager;
}

#pragma mark -
#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    for (int i = 0; i < locations.count; i++) {
        CLLocation              *newLocation = [locations objectAtIndex:i];
        CLLocationCoordinate2D   theLocation = newLocation.coordinate;
        CLLocationAccuracy       theAccuracy = newLocation.horizontalAccuracy;
        NSTimeInterval           locationAge = -[newLocation.timestamp timeIntervalSinceNow];
        
        if (locationAge > 30.0)
            continue;
        
        //Select only valid location and also location with good accuracy
        if (newLocation != nil && theAccuracy > 0
            && theAccuracy < 2000
            && (!(theLocation.latitude == 0.0 && theLocation.longitude == 0.0))) {
            self.currentLocation = newLocation;
        }
    }
    //If the timer still valid, return it (Will not run the code below)
    if (self.shareModel.timer)
        return;
    
    //self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
    //[self.shareModel.bgTask beginNewBackgroundTask];
    
    //Restart the locationManger after 1 minute
    self.shareModel.timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self
                                                           selector:@selector(restartLocationUpdates)
                                                           userInfo:nil
                                                            repeats:NO];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // NSLog(@"locationManager error:%@",error);
    
    switch([error code]) {
        case kCLErrorNetwork: // general, network-related error
        {
            [AlertWorkerObjc alertWithTitle:@"Network Error" message:@"Please check your network connection."];
        }
            break;
        case kCLErrorDenied:
        {
            [AlertWorkerObjc alertWithTitle:@"Enable Location Service" message:@"You have to enable the Location Service to use this App. To enable, please go to Settings->Privacy->Location Services"];
        }
            break;
        default:
        {
            
        }
            break;
    }
}

- (void)stopLocationTracking {
    //NSLog(@"stopLocationTracking");
    
    if (self.shareModel.timer) {
        [self.shareModel.timer invalidate];
        self.shareModel.timer = nil;
    }
    
    CLLocationManager *locationManager = [AppDelegate sharedLocationManager];
    locationManager.allowsBackgroundLocationUpdates = YES;
    [locationManager stopUpdatingLocation];
}

- (void)restartLocationUpdates {
    //NSLog(@"restartLocationUpdates");
    
    if (self.shareModel.timer) {
        [self.shareModel.timer invalidate];
        self.shareModel.timer = nil;
    }
    
    CLLocationManager *locationManager = [AppDelegate sharedLocationManager];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.allowsBackgroundLocationUpdates = YES;
    [locationManager startUpdatingLocation];
}

- (void)stopLocationDelayBy10Seconds {
    CLLocationManager *locationManager = [AppDelegate sharedLocationManager];
    locationManager.allowsBackgroundLocationUpdates = YES;
    [locationManager stopUpdatingLocation];
    
    //NSLog(@"locationManager stop Updating after 10 seconds");
}

#pragma mark -
#pragma mark Internal Methods
- (void)findLocation {
    if (inBackground) {
        [self extendBackgroundRunningTime];
    }
    
    if (self.currentLocation) {
        [self createRoute: self.currentLocation.coordinate.longitude latitude:self.currentLocation.coordinate.latitude];
    }
}

- (void)createRoute:(float)longitude latitude:(float)latitude {
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
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "insert or ignore into Route (DateOfRoute, TimeOfRoute, lineNum, GPSPoint, SendStatus) Values(?, ?, ?, ?, ?)";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [dateString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [timeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [strLineNum UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, [gpsPoint UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, [@"new" UTF8String], -1, SQLITE_TRANSIENT);
            
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(database);
            
            [self getRouteToServer];
        }
    } else {
        sqlite3_close(database);
    }
}

- (int)getRouteCount:(NSString *)strDate {
    int countLine = 0;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select count(*) from Route where DateOfRoute = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW )
                countLine  = sqlite3_column_int(statement, 0);
        }
        sqlite3_reset(statement);
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    return countLine;
}

- (void)showNotice {
    NoticeViewController *fvController = [[NoticeViewController alloc] initWithNibName: @"NoticeViewController" bundle: nil];
    
    fvController.isViewPushed = NO;
    
    if (infoNavController == nil)
        infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    infoNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    infoNavController.preferredContentSize = CGSizeMake(540,275);
    [self.tabBarController presentViewController:infoNavController animated:YES completion:nil];
    
    fvController = nil;
    infoNavController = nil;
}

-(BOOL)checkForNew{
    BOOL haveNew = FALSE;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select count(ID) from NoticeTable where Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [@"new" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                //                haveNew = YES;
                int count = sqlite3_column_int(statement, 0);
                haveNew = count>0;
                [homeViewController setNoticeCount:count];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return haveNew;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self checkVersion];
    [self checkNotice];
    
    if ([self checkForNew] == YES) {
        [self showNotice];
    }
}

#pragma mark - DB
- (void)createDBIfNeeded {
    //Checking if DB already exists
    if ([NSFileManager.defaultManager fileExistsAtPath:SQLWorker.dbPath]) {
        [self checkDBVersion];
    } else {
        [self createDB];
    }
}

- (void)createDB {
    //Copy the default DB to the appropriate location.
    NSError *error;
    BOOL success = [NSFileManager.defaultManager copyItemAtPath:SQLWorker.bundleDBPath toPath:SQLWorker.dbPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message ‘%@’.", error.localizedDescription);
    }
}

- (void)checkDBVersion {
    static sqlite3 *bundleDB = nil;
    
    int currentDBVersion = [SQLWorker getDBVersion:database atPath:SQLWorker.dbPath];
    int bundleDBVersion = [SQLWorker getDBVersion:bundleDB atPath:SQLWorker.bundleDBPath];
    
    if (currentDBVersion != bundleDBVersion) {
        [AlertWorkerObjc alertWithTitle:@"Необходимо выполнить полную синхронизацию"];
        
        [SyncStateWorker setSynchronized:NO];
        
        [NSFileManager.defaultManager removeItemAtPath:SQLWorker.dbPath error:nil];
        [self createDB];
    }
}

#pragma mark -
#pragma mark Memory management

- (void)applicationEnterBackground {
    CLLocationManager *locationManager = [AppDelegate sharedLocationManager];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.allowsBackgroundLocationUpdates = YES;
    [locationManager startUpdatingLocation];
    
    //Use the BackgroundTaskManager to manage all the background Task
    //self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
    //[self.shareModel.bgTask beginNewBackgroundTask];
    
    //UIApplication *app = UIApplication.sharedApplication;
    //double secondsToStayOpen = app.backgroundTimeRemaining;
    //NSLog(@"secondsToStayOpen %f ",secondsToStayOpen);
    
    [self extendBackgroundRunningTime];
    inBackground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    inBackground = NO;
}

- (void)extendBackgroundRunningTime {
    if (bgTask != UIBackgroundTaskInvalid) {
        // if we are in here, that means the background task is already running.
        // don't restart it.
        return;
    }
    NSLog(@"Attempting to extend background running time");
    
    __block Boolean self_terminate = YES;
    
    bgTask = [UIApplication.sharedApplication beginBackgroundTaskWithName:nil expirationHandler:^{
        NSLog(@"Background task expired by iOS");
        if (self_terminate) {
            [UIApplication.sharedApplication endBackgroundTask:self->bgTask];
            self->bgTask = UIBackgroundTaskInvalid;
        }
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"Background task started");
        
        while (YES) {
            [NSThread sleepForTimeInterval:1];
        }
        
    });
}

- (void)checkNotice {
    NSDate *endDate   = NSDate.date;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql;
        
        sql = "select ID, NoticeDate from  NoticeTable";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
            {
                NSString *notId = @"null";
                NSString *start = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    notId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                {
                    start = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                    
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    
                    [formatter setDateFormat:dateFormat_dd_MM_YYYY];
                    
                    NSDate *startDate = [formatter dateFromString:start];
                    
                    NSCalendar       *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *components        = [gregorianCalendar components:NSCalendarUnitDay
                                                                               fromDate:startDate
                                                                                 toDate:endDate
                                                                                options:0];
                    
                    if ([components day] > 40)
                    {
                        [self deleteNotice:notId];
                    }
                }
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
        
    }
    else
    {
        sqlite3_close(database);
    }
}

- (void)deleteNotice:(NSString *)noticeId {
    char *sErrMsg;
    sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
    
    const char *sql = "delete from NoticeTable where ID = ?";
    
    sqlite3_stmt *updateStmt;
    
    sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
    
    sqlite3_bind_text(updateStmt, 1, [noticeId UTF8String], -1, SQLITE_TRANSIENT);
    
    sqlite3_step(updateStmt);
    sqlite3_finalize(updateStmt);
    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
}

- (void)switchToSalesTab{
    [AlertWorkerObjc alertWithTitle:@"Проверка заказов" message:@"В системе существуют неотправленные заказы" buttons:@[@"Просмотр", @"ОК"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if (index == 0) {
            self.tabBarController.selectedViewController = [self.tabBarController.viewControllers objectAtIndex:2];
            
            self.window.rootViewController = self.tabBarController;
            [self.window makeKeyAndVisible];
            
            NSIndexPath *path       = [NSIndexPath indexPathForRow:2 inSection:0];
            
            [self->sales.tableView.delegate tableView:self->sales.tableView didSelectRowAtIndexPath:path];
        }
    }];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    //NSLog(@"applicationWillTerminate");
    
    int lineNum = 9999;
    
    NSDate *date = NSDate.date;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    
    NSString *dateString = [dateFormat stringFromDate:date];
    NSString *timeString = [timeFormat stringFromDate:date];
    
    NSString *strLineNum = [NSString stringWithFormat:@"%i", lineNum];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "insert or ignore into Route (DateOfRoute, TimeOfRoute, lineNum, GPSPoint, SendStatus) Values(?, ?, ?, ?, ?)";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [dateString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [timeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [strLineNum UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, [@"applicationWillTerminate" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, [@"new" UTF8String], -1, SQLITE_TRANSIENT);
            
            sqlite3_step(statement);
            sqlite3_finalize(statement);
        }
    }
    sqlite3_close(database);
}

@end
