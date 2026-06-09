//
//  ASPDatePickerViewController.h
//  MLK
//
//  Created by Alexandr Polienko on 06.04.2021.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN
@class ASPDatePickerViewController;

@protocol ASPDatePickerViewControllerDelegate <NSObject>
- (void)datePickerDidCancel;
- (void)datePickerDidPickDate:(NSDate *)date;

@end

@interface ASPDatePickerViewController : UIViewController

@property (nonatomic, weak) id <ASPDatePickerViewControllerDelegate> delegate;

- (void)setDatePickerMode:(UIDatePickerMode)datePickerMode;
- (void)setDatePickerStyle:(UIDatePickerStyle)datePickerStyle;

- (void)setCurrentDate:(NSDate *)currentDate;
- (void)setMaximumDate:(NSDate *)maximumDate;
- (void)setMinimumDate:(NSDate *)minimumDate;

@end

NS_ASSUME_NONNULL_END
