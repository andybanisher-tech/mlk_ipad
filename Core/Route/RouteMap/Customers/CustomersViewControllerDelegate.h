//
//  CustomersViewControllerDelegate.h
//  MLK
//
//  Created by Alexandr Polienko on 28.07.2023.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CustomersViewControllerDelegate <NSObject>

@optional
- (void)userDidAddCustomersToRoute:(NSArray *)customers date:(NSDate *)date;
- (void)userDidRemoveCustomersFromRoute:(NSArray *)customers;

@end

NS_ASSUME_NONNULL_END
