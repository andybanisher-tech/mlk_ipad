//
//  RouteMapViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 18.06.2024.
//

#import "RouteMapViewController.h"
#import "AppDelegate.h"

//VCs
#import "CustomersInRouteViewController.h"

//Frameworks
#import <YandexMapsMobile/YMKMapKitFactory.h>
#import "sqlite3.h"

#import "GeneratedAssetSymbols.h"

static sqlite3 *database = nil;

//Constants
static const double kMoscowLatitude = 55.75399399999374;
static const double kMoscowLongitude = 37.62209300000001;
static const double kZoomAdjustment = 0.8;
static const double kSelectedCustomerZoomLevel = 15.0;

static const float kMainPlacemarkZIndex = 100.0;

@interface RouteMapViewController ()<CustomersInRouteViewControllerDelegate, YMKUserLocationObjectListener, YMKMapObjectTapListener>

@property (nonatomic, weak) IBOutlet YMKMapView *mapView;

//Customers
@property (nonatomic, strong) NSMutableArray *customers;

//Map
@property (nonatomic, strong) YMKMap *map;
@property (nonatomic, strong) NSMutableArray<YMKPlacemarkMapObject *> *placemarksArray;

@property (nonatomic, strong) YMKPlacemarkMapObject *selectedCustomerPlacemark;
@property (nonatomic, strong) YMKPlacemarkMapObject *selectedNearCustomerPlacemark;

@property (nonatomic, strong) UIImage *customerMarkerImage;
@property (nonatomic, strong) UIImage *selectedCustomerMarkerImage;
@property (nonatomic, strong) UIImage *nearCustomerMarkerImage;
@property (nonatomic, strong) UIImage *selectedNearCustomerMarkerImage;

@property (nonatomic, weak) CustomersInRouteViewController *customersInRouteVC;

@end

@implementation RouteMapViewController

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavBar];
    [self setupUI];
}

#pragma mark - UI
- (void)setupNavBar {
    //NavBar Setup
    self.navigationItem.title = @"Маршрут на карте";
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:UIColor.whiteColor tintColor:[UIColor colorNamed:ACColorNameMLKLightBlue]];

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self  action:@selector(doneButtonTapped)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UIView *statusBarUnderlayView = [[UIView alloc] initWithFrame:CGRectMake(0.0, -ASPFunctions.statusBarHeight, self.navigationController.navigationBar.frame.size.width, ASPFunctions.statusBarHeight)];
    statusBarUnderlayView.backgroundColor = [UIColor blackColor];
    [self.navigationController.navigationBar addSubview:statusBarUnderlayView];
}

- (void)setupUI {
    UINavigationController *childNavVC = (UINavigationController *)self.childViewControllers.firstObject;
    self.customersInRouteVC = (CustomersInRouteViewController *)childNavVC.viewControllers.firstObject;
    self.customersInRouteVC.delegate = self;
    self.customersInRouteVC.currentDate = self.currentDate;
    
    [self configureMapView];
    
    //Observers
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(createRouteList) name:@"routeRefreshed" object:nil];
}

- (void)configureMapView {
    self.customerMarkerImage = [UIImage imageNamed:ACImageNameBlueMapMarker];
    self.selectedCustomerMarkerImage = [UIImage imageNamed:ACImageNameGreenMapMarker];
    self.nearCustomerMarkerImage = [UIImage imageNamed:ACImageNameGrayMapMarker];
    self.selectedNearCustomerMarkerImage = [UIImage imageNamed:ACImageNameOrangeMapMarker];
    
    self.map = self.mapView.mapWindow.map;
    [self.map.mapObjects addTapListenerWithTapListener:self];
    
    YMKMapKit *mapKit = [YMKMapKit sharedInstance];
    YMKUserLocationLayer *userLocationLayer = [mapKit createUserLocationLayerWithMapWindow:self.mapView.mapWindow];
    [userLocationLayer setHeadingModeActive:NO];
    [userLocationLayer setVisibleWithOn:YES];
    [userLocationLayer setObjectListenerWithObjectListener:self];
    
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;

    double targetLat = kMoscowLatitude;
    double targetLon = kMoscowLongitude;
    if (appDelegate.currentLocation) {
        targetLat = appDelegate.currentLocation.coordinate.latitude;
        targetLon = appDelegate.currentLocation.coordinate.longitude;
    }
    
    [self moveCameraWithTarget:[YMKPoint pointWithLatitude:targetLat longitude:targetLon] zoom:10.0 animated:NO];
}

#pragma mark - Working with Data
- (void)createRouteList {
    [SVProgressHUD showWithStatus:@"Загрузка списка клиентов"];
    
    self.customers = [NSMutableArray new];
    NSMutableArray *nearCustomers = [NSMutableArray new];
    
    self.placemarksArray = [NSMutableArray new];
    [self.map.mapObjects clear];
    
    NSDateFormatter *dateFormatter = NSDateFormatter.new;
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:self.currentDate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
            const char *sql = "select CustForRoute.CustAccount, CustForRoute.Status, CustForRoute.CustName, CustForRoute.NearCust, CustTable.Property6Name, CustTable.FactAddress, CustTable.Address, CustTable.GPSPoint, CustTable.SalesDate, cast(CustForRoute.lineNum as integer) as lnum from CustForRoute JOIN CustTable on CustForRoute.CustAccount = CustTable.CustAccount where CustForRoute.DateOfRoute = ? and CustForRoute.IsDeleted Is Not 1 order by lnum";
            sqlite3_stmt *selectstmt;
            
            if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
                sqlite3_bind_text(selectstmt, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
                
                while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                    NSMutableDictionary *customer = [NSMutableDictionary new];
                    
                    NSString *custAccount = @"null";
                    NSString *status = @"null";
                    NSString *custName = @"null";
                    NSString *nearCust;
                    NSString *property6Name;
                    NSString *factAddress;
                    NSString *address;
                    NSString *gpsPoint;
                    NSString *salesDate = @"–";
                    
                    if (sqlite3_column_text(selectstmt, 0))
                        custAccount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                    
                    if (sqlite3_column_text(selectstmt, 1))
                        status = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                    
                    if (sqlite3_column_text(selectstmt, 2))
                        custName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                    
                    if (sqlite3_column_text(selectstmt, 3))
                        nearCust = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                    
                    if (sqlite3_column_text(selectstmt, 4))
                        property6Name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                    
                    if (sqlite3_column_text(selectstmt, 5))
                        factAddress = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                    
                    if (sqlite3_column_text(selectstmt, 6))
                        address = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                    
                    if (sqlite3_column_text(selectstmt, 7))
                        gpsPoint = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                    
                    if (sqlite3_column_text(selectstmt, 8))
                        salesDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                    
                    customer[@"custAccount"] = custAccount;
                    customer[@"status"] = status;
                    customer[@"custName"] = custName;
                    customer[@"nearCust"] = nearCust;
                    customer[@"property6Name"] = property6Name;
                    customer[@"factAddress"] = factAddress;
                    customer[@"address"] = address;
                    customer[@"gpsPoint"] = gpsPoint;
                    customer[@"salesDate"] = salesDate;
                    customer[@"tasks"] = [self tasks:custAccount];
                    
                    if (nearCust) {
                        [nearCustomers addObject:customer];
                    } else {
                        [self.customers addObject:customer];
                    }
                }
            }
            sqlite3_finalize(selectstmt);
        }
        sqlite3_close(database);
        
        //Add nearCustomers to parent
        for (NSMutableDictionary *customer in self.customers) {
            NSArray *filteredNearCustomers = [nearCustomers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable object, NSDictionary<NSString *,id> * _Nullable bindings) {
                return [object[@"nearCust"] localizedStandardContainsString:customer[@"custAccount"]];
            }]];
            
            customer[@"nearCustomers"] = filteredNearCustomers;
        }

        dispatch_async(dispatch_get_main_queue(), ^() {
            [self.customersInRouteVC setCustomers:self.customers];

            [self addPlacemarks:self.customers];
            
            [self updateSelectedPlacemarksIfNeeded];
            
            [SVProgressHUD dismissWithDelay:0.1];
        });
    });
}

- (NSArray *)tasks:(NSString *)custAcc {
    //Selecting All Tasks
    const char *sql = "select TaskName from TaskTable where CustAccount = ? group by TaskId, TaskName";
    sqlite3_stmt *selectstmt;
    
    NSMutableArray *tasks = [NSMutableArray new];
    if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selectstmt, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
        
        while (sqlite3_step(selectstmt) == SQLITE_ROW) {
            if (sqlite3_column_text(selectstmt, 0)) {
                NSString *taskName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                [tasks addObject:taskName];
            }
        }
    }
    sqlite3_finalize(selectstmt);
    
    return tasks;
}

#pragma mark - Setters
- (void)setSelectedCustomerPlacemark:(YMKPlacemarkMapObject *)selectedCustomerPlacemark {
    [self moveCameraWithTarget:selectedCustomerPlacemark.geometry zoom:kSelectedCustomerZoomLevel animated:YES];
    
    if (_selectedCustomerPlacemark == selectedCustomerPlacemark) { return; }
    
    if (_selectedCustomerPlacemark.isValid) {
        [_selectedCustomerPlacemark setIconWithImage:self.customerMarkerImage];
    }
  
    [selectedCustomerPlacemark setIconWithImage:self.selectedCustomerMarkerImage];
    
    NSMutableArray *placemarksToRemove = [NSMutableArray new];
    for (YMKPlacemarkMapObject *placemark in self.placemarksArray) {
        if (placemark.userData[@"nearCust"]) {
            [placemarksToRemove addObject:placemark];
            [self.map.mapObjects removeWithMapObject:placemark];
        }
    }
    
    self.selectedNearCustomerPlacemark = nil;
    [self.placemarksArray removeObjectsInArray:placemarksToRemove];
    
    [self addPlacemarks:selectedCustomerPlacemark.userData[@"nearCustomers"]];
    
    _selectedCustomerPlacemark = selectedCustomerPlacemark;
    
    [self.customersInRouteVC setSelectedCustomer:selectedCustomerPlacemark.userData];
}

- (void)setSelectedNearCustomerPlacemark:(YMKPlacemarkMapObject *)selectedNearCustomerPlacemark {
    [self moveCameraWithTarget:selectedNearCustomerPlacemark.geometry zoom:self.map.cameraPosition.zoom animated:YES];
    
    if (_selectedNearCustomerPlacemark == selectedNearCustomerPlacemark) { return; }
    
    if (_selectedNearCustomerPlacemark.isValid) {
        [_selectedNearCustomerPlacemark setIconWithImage:self.nearCustomerMarkerImage];
        [_selectedNearCustomerPlacemark setZIndex:0.0];
    }
    
    [selectedNearCustomerPlacemark setIconWithImage:self.selectedNearCustomerMarkerImage];
    [selectedNearCustomerPlacemark setZIndex:kMainPlacemarkZIndex];
    
    _selectedNearCustomerPlacemark = selectedNearCustomerPlacemark;
    
    [self.customersInRouteVC setSelectedNearCustomer:selectedNearCustomerPlacemark.userData];
}

#pragma mark - Button Actions
- (void)doneButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)locateMeButtonTapped:(id)sender {
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    [self moveCameraWithTarget:[YMKPoint pointWithLatitude:appDelegate.currentLocation.coordinate.latitude longitude:appDelegate.currentLocation.coordinate.longitude] zoom:14.0 animated:YES];
}

#pragma mark - CustomersInRouteViewControllerDelegate
- (void)userDidSelectCustomer:(NSDictionary *)customer {
    NSUInteger searchIndex = [self.placemarksArray indexOfObjectPassingTest:^BOOL(YMKPlacemarkMapObject *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.userData[@"custAccount"] isEqual:customer[@"custAccount"]];
    }];
    
    if (searchIndex != NSNotFound) {
        if (customer[@"nearCust"]) {
            self.selectedNearCustomerPlacemark = self.placemarksArray[searchIndex];
        } else {
            self.selectedCustomerPlacemark = self.placemarksArray[searchIndex];
        }
    } else {
        if (self.selectedNearCustomerPlacemark) {
            self.selectedNearCustomerPlacemark = nil;
        } else {
            self.selectedCustomerPlacemark = nil;
        }
    }
}

#pragma mark - YMKMapView Helpers
- (void)addPlacemarks:(NSArray *)customers {
    for (NSDictionary *customer in customers) {
        NSArray *substrings = [customer[@"gpsPoint"] componentsSeparatedByString:@","];
        
        NSString *pointString;
        if (substrings.count == 4) {
            pointString = [NSString stringWithFormat:@"%@.%@, %@.%@", substrings[2], substrings[3], substrings[0], substrings[1]];
        } else if (substrings.count == 2) {
            pointString = [NSString stringWithFormat:@"%@, %@", substrings[1], substrings[0]];
        }
        
        if (!self.selectedCustomerPlacemark && !customer[@"nearCust"] && customer == self.customers.lastObject) {
            [self addPlacemarkWithCoordinatesString:pointString userData:customer moveCamera:YES];
            [self adjustCameraZoom];
        } else {
            [self addPlacemarkWithCoordinatesString:pointString userData:customer moveCamera:NO];
        }
    }
}

- (void)addPlacemarkWithCoordinatesString:(NSString *)coordinatesString userData:(NSDictionary *)userData moveCamera:(BOOL)moveCamera {
    NSArray *coordinatesArray = [coordinatesString componentsSeparatedByString:@","];
    NSString *latString = coordinatesArray[0];
    NSString *lonString = coordinatesArray[1];
    
    double lat = [latString doubleValue];
    double lon = [lonString doubleValue];
    
    YMKPoint *point = [YMKPoint pointWithLatitude:lat longitude:lon];
    YMKPlacemarkMapObject *placemark = [self.map.mapObjects addPlacemark];
    [placemark setGeometry:point];
    [placemark setUserData:userData];
    
    if (userData[@"nearCust"]) {
        [placemark setIconWithImage: self.nearCustomerMarkerImage];
    } else {
        [placemark setIconWithImage: self.customerMarkerImage];
        [placemark setZIndex:kMainPlacemarkZIndex];
    }
   
    [self.placemarksArray addObject:placemark];
    
    if (moveCamera) {
        [self moveCameraWithTarget:[YMKPoint pointWithLatitude:lat longitude:lon] zoom:self.map.cameraPosition.zoom animated:NO];
    }
}

- (void)updateSelectedPlacemarksIfNeeded {
    if (self.selectedCustomerPlacemark) {
        NSUInteger searchIndex = [self.placemarksArray indexOfObjectPassingTest:^BOOL(YMKPlacemarkMapObject *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.userData[@"custAccount"]  isEqual:self.selectedCustomerPlacemark.userData[@"custAccount"]];
        }];
        
        if (searchIndex != NSNotFound) {
            self.selectedCustomerPlacemark = self.placemarksArray[searchIndex];
        }
    }
}

- (void)adjustCameraZoom {
    //Calculating average location between placemarks
    double avgLat = 0.0;
    double avgLon = 0.0;
    
    for (YMKPlacemarkMapObject *placemark in self.placemarksArray) {
        avgLat += placemark.geometry.latitude;
        avgLon += placemark.geometry.longitude;
    }
    
    YMKPoint *avgPoint = [YMKPoint pointWithLatitude:avgLat / self.placemarksArray.count  longitude:avgLon / self.placemarksArray.count];
    [self moveCameraWithTarget:avgPoint zoom:self.map.cameraBounds.getMaxZoom animated:NO];
    
    for (YMKPlacemarkMapObject *placemark in self.placemarksArray) {
        while (YES) {
            YMKVisibleRegion *visibleRegion = self.map.visibleRegion;
            
            double minLat = visibleRegion.bottomRight.latitude;
            double maxLat = visibleRegion.topLeft.latitude;
            
            double minLon = visibleRegion.topLeft.longitude;
            double maxLon = visibleRegion.bottomRight.longitude;
            
            if (placemark.geometry.latitude >= minLat &&
                placemark.geometry.latitude <= maxLat &&
                placemark.geometry.longitude >= minLon &&
                placemark.geometry.longitude <= maxLon) {
                break;
            }
            
            float newZoom = self.map.cameraPosition.zoom - kZoomAdjustment;
            if (newZoom >= kZoomAdjustment) {
                [self moveCameraWithTarget:self.map.cameraPosition.target zoom:newZoom animated:NO];
            } else {
                break;
            }
        }
    }
}

- (void)moveCameraWithTarget:(YMKPoint *)target zoom:(float)zoom animated:(BOOL)animated {
    if (!target) { return; }
    
    YMKCameraPosition *cameraPosition = [YMKCameraPosition cameraPositionWithTarget:target zoom:zoom azimuth:self.map.cameraPosition.azimuth tilt:self.map.cameraPosition.tilt];
    
    if (animated) {
        YMKAnimation *animation = [YMKAnimation animationWithType:YMKAnimationTypeSmooth duration:0.3];
        [self.map moveWithCameraPosition:cameraPosition animation:animation cameraCallback:nil];
    } else {
        [self.map moveWithCameraPosition:cameraPosition];
    }
}

#pragma mark - YMKUserLocationObjectListener
- (void)onObjectAddedWithView:(YMKUserLocationView *)view {
    [view.pin setIconWithImage:[UIImage imageNamed:ACImageNameUserDot]];
    [view.arrow setIconWithImage:[UIImage imageNamed:ACImageNameUserDot]];
}

- (void)onObjectRemovedWithView:(YMKUserLocationView *)view {}
- (void)onObjectUpdatedWithView:(YMKUserLocationView *)view event:(YMKObjectEvent *)event {}

#pragma mark - YMKMapObjectTapListener
- (BOOL)onMapObjectTapWithMapObject:(YMKMapObject *)mapObject point:(YMKPoint *)point {
    YMKPlacemarkMapObject *tappedObject = (YMKPlacemarkMapObject *)mapObject;
    
    if (tappedObject.userData[@"nearCust"]) {
        self.selectedNearCustomerPlacemark = tappedObject;
    } else {
        self.selectedCustomerPlacemark = tappedObject;
    }
    
    return YES;
}

@end
