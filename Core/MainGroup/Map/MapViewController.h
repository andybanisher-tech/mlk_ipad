//
//  MapViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 06.06.13.
//
//

#import "UIKit/UIKit.h"
#import <YandexMapsMobile/YMKMapKitFactory.h>

@interface MapViewController: UIViewController {
    BOOL isViewPushed;
    
    NSString *custName;
    NSString *custAddr;
}

@property (nonatomic, weak) IBOutlet YMKMapView *mapView;

@property (nonatomic, assign) BOOL isViewPushed;

@property (nonatomic, assign) BOOL isAllRoute;

@property (nonatomic, copy) NSString *custName;
@property (nonatomic, copy) NSString *custAddr;

- (IBAction)locateMeButtonTapped:(id)sender;

@end
