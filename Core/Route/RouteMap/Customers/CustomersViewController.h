//
//  CustomersViewController.h
//  MLK
//
//  Created by Alexandr Polienko on 20.04.2022.
//

#import "UIKit/UIKit.h"
#import "CustomersViewControllerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface CustomersViewController : UIViewController

@property (nonatomic, weak) id <CustomersViewControllerDelegate> delegate;

@property (nonatomic, strong) NSArray *customersInRoute;
@property (nonatomic, strong) NSDate *selectedDate;

@property (nonatomic, copy) NSString *mainAcc;
@property (nonatomic, copy) NSString *currentAcc;
@property (nonatomic, strong) NSDictionary *selectedManager;

@end

NS_ASSUME_NONNULL_END
