//
//  InvoiceInventProductTableViewCell.h
//  MLK
//
//  Created by Alexandr Polienko on 05.09.2022.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@class InvoiceInventProductTableViewCell;

@protocol InvoiceInventProductTableViewCellDelegate <NSObject>

@optional
- (void)cellBtnQtyStoreTapped:(InvoiceInventProductTableViewCell *)sender;
- (void)cellBtnExpandTapped:(InvoiceInventProductTableViewCell *)sender;

@end

@interface InvoiceInventProductTableViewCell : UITableViewCell

@property (nonatomic, weak) id <InvoiceInventProductTableViewCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UIView *containerView;

@property (nonatomic, weak) IBOutlet UILabel *lblNumber;
@property (nonatomic, weak) IBOutlet UILabel *lblName;
@property (nonatomic, weak) IBOutlet UILabel *lblCode;

@property (nonatomic, weak) IBOutlet UITextField *txtAmountField;

@property (nonatomic, weak) IBOutlet UIButton *btnQtyStore;

@property (nonatomic, weak) IBOutlet UILabel *lblSum;

#pragma mark - Setters
- (void)setExpirationDate:(NSString *)dateString;
- (void)setPrice:(NSNumber *)price discount:(NSNumber *)discount;
- (void)setBadProduct:(NSArray *)data isExpanded:(BOOL)isExpanded;

@end

NS_ASSUME_NONNULL_END
