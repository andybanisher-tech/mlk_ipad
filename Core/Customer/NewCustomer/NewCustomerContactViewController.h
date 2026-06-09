//
//  NewCustomerContactViewController.h
//  MLK
//
//  Created by Alexandr Polienko on 29.11.2021.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@protocol NewCustomerContactViewControllerDelegate <NSObject>

@optional
- (void)userDidAddContact:(NSDictionary *)contact;

@end

@interface NewCustomerContactViewController : UIViewController

@property (nonatomic, weak) id <NewCustomerContactViewControllerDelegate> delegate;

@property (nonatomic, strong) NSMutableDictionary *contactData;

@end

NS_ASSUME_NONNULL_END
