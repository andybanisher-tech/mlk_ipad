//
//  TasksViewController.h
//  MLK
//
//  Created by Alexandr Polienko on 11.08.2021.
//

#import "UIKit/UIKit.h"
#import "CustomersViewControllerDelegate.h"

@interface TasksViewController : UIViewController

@property (nonatomic, weak) id <CustomersViewControllerDelegate> delegate;

@end
