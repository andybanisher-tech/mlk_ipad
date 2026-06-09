//
//  CDSecondaryPassportValuePickerViewController.h
//  MLK
//
//  Created by Alexandr Polienko on 28.03.2025.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CDSecondaryPassportValuePickerViewControllerDelegate <NSObject>

@optional
- (void)userDidPickValues:(NSArray *)values listIDs:(NSArray *)listIDs propertyID:(NSString *)propertyID;

@end

@interface CDSecondaryPassportValuePickerViewController : UIViewController

@property (nonatomic, weak) id <CDSecondaryPassportValuePickerViewControllerDelegate> delegate;

@property (nonatomic, strong) NSMutableArray *selectedValues;
@property (nonatomic, strong) NSMutableArray *selectedListIDs;
@property (nonatomic, copy) NSString *propertyID;
@property (nonatomic, assign) BOOL isMultiple;

@end

NS_ASSUME_NONNULL_END
