//
//  CustomerTypesTableViewController.h
//  MLK
//
//  Created by Alexandr Polienko on 15.10.2021.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CustomerTypesTableViewControllerDelegate <NSObject>

@optional
- (void)userDidSelectCustomerTypes:(NSArray *)selectedTypes;

@end

@interface CustomerTypesTableViewController : UITableViewController

@property (nonatomic, weak) id <CustomerTypesTableViewControllerDelegate> delegate;

@property (nonatomic, strong) NSMutableArray *selectedTypesArray;

@end

NS_ASSUME_NONNULL_END
