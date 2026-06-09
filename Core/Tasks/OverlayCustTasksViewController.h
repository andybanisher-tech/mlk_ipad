//
//  OverlayCustTasksViewController.h
//  MLK
//
//  Created by garu on 11/24/14.
//
//

#import "UIKit/UIKit.h"
@class CustTasksViewController;

@interface OverlayCustTasksViewController : UIViewController {
	CustTasksViewController *rvController;
}

@property (nonatomic, retain) CustTasksViewController *rvController;

@end

