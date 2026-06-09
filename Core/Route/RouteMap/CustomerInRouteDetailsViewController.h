//
//  CustomerInRouteDetailsViewController.h
//  MLK
//
//  Created by Alexandr Polienko on 19.06.2024.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CustomerInRouteDetailsViewControllerDelegate <NSObject>

- (void)userDidTapBackButton;
- (void)userDidSelectNearCustomer:(NSDictionary * _Nullable)customer;
- (void)userDidAddCustomerToRoute:(NSDictionary *)customer;
- (void)userDidChangeRadius:(double)radius;

@end

@interface CustomerInRouteDetailsViewController : UIViewController

@property (nonatomic, weak) id <CustomerInRouteDetailsViewControllerDelegate> delegate;

#pragma mark - Setters
- (void)setCustomer:(NSDictionary *)customer;

@end

NS_ASSUME_NONNULL_END
