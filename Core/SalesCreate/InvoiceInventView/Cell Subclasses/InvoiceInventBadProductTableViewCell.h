//
//  InvoiceInventBadProductTableViewCell.h
//  MLK
//
//  Created by Alexandr Polienko on 05.02.2021.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface InvoiceInventBadProductTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblName;
@property (nonatomic, weak) IBOutlet UILabel *lblDiscount;
@property (nonatomic, weak) IBOutlet UITextField *txtAmountField;
@property (nonatomic, weak) IBOutlet UILabel *lblQtyStore;
@property (nonatomic, weak) IBOutlet UILabel *lblPrice;
@property (nonatomic, weak) IBOutlet UILabel *lblSum;

#pragma mark - Setters
- (void)setPrice:(NSNumber *)price discount:(NSNumber *)discount;

@end

NS_ASSUME_NONNULL_END
