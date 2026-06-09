//
//  PresalesProductTableViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 08.09.2022.
//

#import "PresalesProductTableViewCell.h"

@interface PresalesProductTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *lblDiscount;

@property (nonatomic, weak) IBOutlet UILabel *lblPrice;
@property (nonatomic, weak) IBOutlet UILabel *lblPriceWithDiscount;

@end

@implementation PresalesProductTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Setters
- (void)setPrice:(NSNumber *)price discount:(NSNumber *)discount {
    NSNumber *newPrice = @((100.0 - discount.doubleValue) / 100.0 * price.doubleValue);
    self.lblPriceWithDiscount.text = [NSString stringWithFormat:@"%0.2f", newPrice.doubleValue];
      
    self.lblPrice.text = [NSString stringWithFormat:@"%0.2f", price.doubleValue];
    
    if (discount.doubleValue > 0.0) {
        self.lblDiscount.hidden = NO;
        self.lblDiscount.text = [NSString stringWithFormat:@"-%.0f%%", discount.doubleValue];
    } else {
        self.lblDiscount.hidden = YES;
    }
}

@end
