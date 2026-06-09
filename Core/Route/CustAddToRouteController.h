//
//  CustAddToRouteController.h
//  MLK
//
//  Created by Nikita on 09/04/15.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

#import "MapViewController.h"

#import "ASPDatePickerViewController.h"

@class CustViewController;

@interface CustAddToRouteController : UIViewController <ASPDatePickerViewControllerDelegate> {
    NSString                    *custAcc;
    NSString                    *custName;
    NSString                    *custAddress;
    
    IBOutlet UILabel            *labelCustName;

    UILabel                     *dateLabel;
    
    CustViewController          *custViewController;
    IBOutlet UIButton           *addBtn;
    
    MapViewController           *mvControllerToolbar;
	MapViewController           *mvControllerCell;
	UINavigationController      *mvNavController;
    
    NSString                    *countTasks;
}
@property(nonatomic,retain)NSString                 *custAcc;
@property(nonatomic,retain)NSString                 *custName;
@property(nonatomic,retain)NSString                 *custAddress;
@property(nonatomic,retain)UILabel                  *labelCustName;
@property(nonatomic,retain)IBOutlet UIButton        *changeDate;
@property(nonatomic,retain)IBOutlet UIButton        *addBtn;
@property(nonatomic,retain)NSDate                   *selectedDate;
@property(nonatomic,retain)UILabel                  *dateLabel;
@property (nonatomic, strong) ASPDatePickerViewController *datePickerVC;
@property(nonatomic,retain)NSString                 *countTasks;

@property (nonatomic, weak)CustViewController       *delegate;

- (void)cancel_Clicked:(id)sender;


@end

