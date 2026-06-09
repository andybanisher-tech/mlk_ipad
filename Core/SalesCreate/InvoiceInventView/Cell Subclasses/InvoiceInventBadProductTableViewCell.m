//
//  InvoiceInventBadProductTableViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 05.02.2021.
//

#import "InvoiceInventBadProductTableViewCell.h"

@interface InvoiceInventBadProductTableViewCell ()
@property (nonatomic, weak) IBOutlet UILabel *lblPercent;

@end

@implementation InvoiceInventBadProductTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [ASPFunctions view:self.lblPercent withCornerRadius:5.0];
    [ASPFunctions view:self.lblDiscount withCornerRadius:5.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    UIColor *percentColor = self.lblPercent.backgroundColor;
    UIColor *discountColor = self.lblDiscount.backgroundColor;
    
    [super setSelected:selected animated:animated];
    
    self.lblPercent.backgroundColor = percentColor;
    self.lblDiscount.backgroundColor = discountColor;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    UIColor *percentColor = self.lblPercent.backgroundColor;
    UIColor *discountColor = self.lblDiscount.backgroundColor;
    
    [super setHighlighted:highlighted animated:animated];
    
    self.lblPercent.backgroundColor = percentColor;
    self.lblDiscount.backgroundColor = discountColor;
}

#pragma mark - Setters
- (void)setPrice:(NSNumber *)price discount:(NSNumber *)discount {
    NSNumber *newPrice = @((100.0 - discount.doubleValue) / 100.0 * price.doubleValue);
    self.lblPrice.text = [NSString stringWithFormat:@"%0.2f", newPrice.doubleValue];
    
    if (discount.doubleValue > 0.0) {
        self.lblDiscount.hidden = NO;
        self.lblDiscount.text = [NSString stringWithFormat:@"-%.0f%%", discount.doubleValue];
    } else {
        self.lblDiscount.hidden = YES;
    }
}

@end
