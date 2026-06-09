//
//  CustomersInRouteViewController.h
//  MLK
//
//  Created by Alexandr Polienko on 18.06.2024.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CustomersInRouteViewControllerDelegate <NSObject>

- (void)userDidSelectCustomer:(NSDictionary * _Nullable)customer;

@end

@interface CustomersInRouteViewController : UIViewController

@property (nonatomic, weak) id <CustomersInRouteViewControllerDelegate> delegate;

@property (nonatomic, strong) NSDate *currentDate;

#pragma mark - Setters
- (void)setCustomers:(NSArray *)customers;
- (void)setSelectedCustomer:(NSDictionary *)customer;
- (void)setSelectedNearCustomer:(NSDictionary *)customer;

@end

NS_ASSUME_NONNULL_END
