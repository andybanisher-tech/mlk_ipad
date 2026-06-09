//
//  MapViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 06.06.13.
//
//

#import "MapViewController.h"
#import "RWBorderedButton.h"
#import "AppDelegate.h"

#import "GeneratedAssetSymbols.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

//Constants
static const double kMoscowLatitude = 55.75399399999374;
static const double kMoscowLongitude = 37.62209300000001;
static const double kZoomAdjustment = 0.8;

@interface MapViewController () <YMKUserLocationObjectListener, YMKMapObjectTapListener>

@property (nonatomic, strong) YMKMap *map;
@property (nonatomic, strong) NSMutableArray<YMKPlacemarkMapObject *> *placemarksArray;
@property (nonatomic, strong) NSMutableArray<YMKPlacemarkMapObject *> *annotationsArray;

@property (nonatomic, strong) UIImage *blueMarkerImage;
@property (nonatomic, strong) UIImage *grayMarkerImage;

@end

@implementation MapViewController
@synthesize isViewPushed, custAddr, custName;

#pragma mark - View lifecycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:@"MapViewController" bundle:nibBundleOrNil];
    if (self) {
        self.blueMarkerImage = [UIImage imageNamed:ACImageNameBlueMapMarker];
        self.grayMarkerImage = [UIImage imageNamed:ACImageNameGrayMapMarker];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.presentationController.presentedView.gestureRecognizers.firstObject.enabled = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //NavBar Setup
    self.navigationItem.title = custName;
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];

    [self configureMapView];
    [self configureAndInstallAnnotations];

    if (isViewPushed == NO) {
        RWBorderedButton *closeButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Закрыть"];
        [closeButton addTarget:self
                        action:@selector(cancel_Clicked:)
              forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        self.navigationItem.rightBarButtonItem = barButton;
    }
}

#pragma mark - Helpers
- (void)configureMapView {
    self.placemarksArray = [NSMutableArray new];
    self.annotationsArray = [NSMutableArray new];
    
    self.map = self.mapView.mapWindow.map;
    [self.map.mapObjects addTapListenerWithTapListener:self];
    
    YMKMapKit *mapKit = [YMKMapKit sharedInstance];
    YMKUserLocationLayer *userLocationLayer = [mapKit createUserLocationLayerWithMapWindow:self.mapView.mapWindow];
    [userLocationLayer setHeadingModeActive:NO];
    [userLocationLayer setVisibleWithOn:YES];
    [userLocationLayer setObjectListenerWithObjectListener:self];
    
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    float zoom = 14.0;
    if (self.isAllRoute) {
        zoom = 10.0;
    }
    
    double targetLat = kMoscowLatitude;
    double targetLon = kMoscowLongitude;
    if (appDelegate.currentLocation) {
        targetLat = appDelegate.currentLocation.coordinate.latitude;
        targetLon = appDelegate.currentLocation.coordinate.longitude;
    }
    
    YMKCameraPosition *cameraPosition = [YMKCameraPosition cameraPositionWithTarget:[YMKPoint pointWithLatitude:targetLat longitude:targetLon] zoom:zoom azimuth:self.map.cameraPosition.azimuth tilt:self.map.cameraPosition.tilt];
    [self.map moveWithCameraPosition:cameraPosition];
}

- (void)configureAndInstallAnnotations {
    if (!self.isAllRoute) {
        NSArray *substrings = [custAddr componentsSeparatedByString:@","];
        
        if ([substrings count] == 4) {
            NSString *first     = [substrings objectAtIndex:0];
            NSString *second    = [substrings objectAtIndex:1];
            NSString *third     = [substrings objectAtIndex:2];
            NSString *fourth    = [substrings objectAtIndex:3];
            NSString *pointStr     = [NSString stringWithFormat:@"%@.%@, %@.%@", third, fourth, first, second];
            
            [self addMarkerWithCoordinatesString:pointStr isNearCustomer:NO moveCamera:YES];
            
        } else if ([substrings count] == 2) {
            NSString *first     = [substrings objectAtIndex:0];
            NSString *second    = [substrings objectAtIndex:1];
            NSString *pointStr     = [NSString stringWithFormat:@"%@, %@", second, first];
            
            [self addMarkerWithCoordinatesString:pointStr isNearCustomer:NO moveCamera:YES];
    
        }
    } else {
        NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
        NSDate *date = NSDate.date;
    
        [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
        NSString *strDate = [dateFormatter stringFromDate:date];
	
        if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
            sqlite3_stmt *selectstmt;
        
            /*const char *sql = "select CustName, GPSPoint from CustForRoute where DateOfRoute = ?";*/
            const char *sql = "SELECT rout.CustName, rout.NearCust, cust.GPSPoint FROM CustForRoute as rout JOIN CustTable as cust ON rout.CustAccount = cust.CustAccount WHERE DateOfRoute = ?";
            if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
                sqlite3_bind_text(selectstmt, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            
                while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                    NSString *nearCust;
                    
                    if (sqlite3_column_text(selectstmt, 0))
                        custName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                    
                    if (sqlite3_column_text(selectstmt, 1)) {
                        nearCust = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                    }
                
                    if (sqlite3_column_text(selectstmt, 2)) {
                        custAddr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                        
                        NSArray *substrings = [custAddr componentsSeparatedByString:@","];
                        
                        NSString *pointString;
                        if (substrings.count == 4) {
                            pointString = [NSString stringWithFormat:@"%@.%@, %@.%@", substrings[2], substrings[3], substrings[0], substrings[1]];
                        } else if (substrings.count == 2) {
                            pointString = [NSString stringWithFormat:@"%@, %@", substrings[1], substrings[0]];
                        }
                        
                        [self addMarkerWithCoordinatesString:pointString isNearCustomer:nearCust != nil moveCamera:NO];
                    }
                }
            }
            sqlite3_finalize(selectstmt);
            sqlite3_close(database);
        } else {
            sqlite3_close(database);
        }
        
        if (!self.placemarksArray.lastObject.geometry) { return; }

        YMKCameraPosition *cameraPosition = [YMKCameraPosition cameraPositionWithTarget:self.placemarksArray.lastObject.geometry zoom:self.map.cameraPosition.zoom azimuth:self.map.cameraPosition.azimuth tilt:self.map.cameraPosition.tilt];
        [self.map moveWithCameraPosition:cameraPosition];
        [self adjustCameraZoom];
    }
}

- (void) cancel_Clicked:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - IBActions
- (IBAction)locateMeButtonTapped:(id)sender {
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    YMKAnimation *animation = [YMKAnimation animationWithType:YMKAnimationTypeSmooth duration:0.3];
    YMKCameraPosition *cameraPosition = [YMKCameraPosition cameraPositionWithTarget:[YMKPoint pointWithLatitude:appDelegate.currentLocation.coordinate.latitude longitude:appDelegate.currentLocation.coordinate.longitude] zoom:14.0 azimuth:self.map.cameraPosition.azimuth tilt:self.map.cameraPosition.tilt];
    [self.map moveWithCameraPosition:cameraPosition animation:animation cameraCallback:nil];
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
//    YMKPlacemarkMapObject *tappedObject = (YMKPlacemarkMapObject *)mapObject;
    
//    BOOL alreadyAdded
//    if ([annotations containsObject:tappedObject]) {
//        return NO;
//    } else {
//        [self addAnnotationToMapAtPoint:tappedObject.geometry];
//        return YES;
//    }
    return YES;
}

#pragma mark - YMKMapView Helpers
- (void)addMarkerWithCoordinatesString:(NSString *)coordinatesString isNearCustomer:(BOOL)isNearCustomer moveCamera:(BOOL)moveCamera {
    NSArray *coordinatesArray = [coordinatesString componentsSeparatedByString:@","];
    NSString *latString = [coordinatesArray objectAtIndex:0];
    NSString *lonString = [coordinatesArray objectAtIndex:1];
    
    double lat = [latString doubleValue];
    double lon = [lonString doubleValue];
    
    YMKPoint *point = [YMKPoint pointWithLatitude:lat longitude:lon];
    YMKPlacemarkMapObject *placemark = [self.map.mapObjects addPlacemark];
    [placemark setGeometry:point];
    [placemark setIconWithImage:isNearCustomer ? self.grayMarkerImage : self.blueMarkerImage];
    
    [self.placemarksArray addObject:placemark];
    [self addAnnotationToMapAtPoint:point];

    if (moveCamera) {
        YMKCameraPosition *cameraPosition = [YMKCameraPosition cameraPositionWithTarget:[YMKPoint pointWithLatitude:lat longitude:lon] zoom:self.map.cameraPosition.zoom azimuth:self.map.cameraPosition.azimuth tilt:self.map.cameraPosition.tilt];
        [self.map moveWithCameraPosition:cameraPosition];
    }
}

- (void)addAnnotationToMapAtPoint:(YMKPoint *)point {
    UIView *annotationView = [UIView new];
    annotationView.backgroundColor = UIColor.whiteColor;
    
    UILabel *lblName = [UILabel new];
    lblName.font = [UIFont italicSystemFontOfSize: 17.0];
    lblName.text = custName;
    lblName.textAlignment = NSTextAlignmentCenter;
    lblName.textColor = [UIColor blackColor];
    [lblName sizeToFit];
    
    CGFloat sidePadding = 10.0;
    annotationView.frame = CGRectMake(0.0, 0.0, lblName.frame.size.width + sidePadding * 2, 40.0);
    lblName.center = annotationView.center;
    
    [annotationView addSubview:lblName];

    YRTViewProvider *viewProvider = [[YRTViewProvider alloc] initWithUIView:annotationView];
    YMKIconStyle *iconStyle = [YMKIconStyle
                               iconStyleWithAnchor:[NSValue valueWithCGPoint:CGPointMake(0.5, 1.8)]
                               rotationType:nil
                               zIndex:[NSNumber numberWithInt:100]
                               flat:[NSNumber numberWithInt:0]
                               visible:[NSNumber numberWithInt:1]
                               scale:[NSNumber numberWithInt:1]
                               tappableArea:nil];
    
    YMKPlacemarkMapObject *placemark = [self.map.mapObjects addPlacemark];
    [placemark setGeometry:point];
    [placemark setViewWithView:viewProvider style:iconStyle];

    [self.annotationsArray addObject:placemark];
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
    YMKCameraPosition *cameraPosition = [YMKCameraPosition cameraPositionWithTarget:avgPoint zoom:self.map.cameraBounds.getMaxZoom azimuth:self.map.cameraPosition.azimuth tilt:self.map.cameraPosition.tilt];
    [self.map moveWithCameraPosition:cameraPosition];

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
                YMKCameraPosition *newCameraPosition = [YMKCameraPosition cameraPositionWithTarget:self.map.cameraPosition.target zoom:newZoom azimuth:self.map.cameraPosition.azimuth tilt:self.map.cameraPosition.tilt];
                [self.map moveWithCameraPosition:newCameraPosition];
            } else {
                break;
            }
        }
    }
}

@end

