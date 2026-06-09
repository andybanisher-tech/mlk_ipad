//
//  NewCustomerDataPickerViewController.h
//  MLK
//
//  Created by Alexandr Polienko on 29.11.2021.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@protocol NewCustomerDataPickerViewControllerDelegate <NSObject>

@optional
- (void)userDidPickCustomerData:(NSDictionary *)data;

@end

@interface NewCustomerDataPickerViewController : UIViewController

@property (nonatomic, weak) id <NewCustomerDataPickerViewControllerDelegate> delegate;

@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, strong) NSDictionary *selectedObject;

@end

NS_ASSUME_NONNULL_END
