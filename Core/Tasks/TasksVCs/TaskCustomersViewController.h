//
//  TaskCustomersViewController.h
//  MLK
//
//  Created by Alexandr Polienko on 12.08.2021.
//

#import "UIKit/UIKit.h"
#import "CustomersViewControllerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TaskCustomersViewController : UIViewController

@property (nonatomic, weak) id <CustomersViewControllerDelegate> delegate;

@property (nonatomic, strong) NSDictionary *selectedTask;

@end

NS_ASSUME_NONNULL_END
