//
//  InvoiceInventProductTableViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 05.09.2022.
//

#import "InvoiceInventProductTableViewCell.h"

@interface InvoiceInventProductTableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *expirationDateLabel;
@property (nonatomic, weak) IBOutlet UILabel *lblDiscount;
@property (nonatomic, weak) IBOutlet UILabel *lblPrice;
@property (nonatomic, weak) IBOutlet UILabel *lblOldPrice;
@property (nonatomic, weak) IBOutlet UIView *oldPriceStrikeThroughLineView;

@property (nonatomic, weak) IBOutlet UIButton *btnExpand;

@end

@implementation InvoiceInventProductTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [ASPFunctions view:self.lblDiscount withCornerRadius:5.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    UIColor *discountColor = self.lblDiscount.backgroundColor;
    UIColor *strikeThroughColor = self.oldPriceStrikeThroughLineView.backgroundColor;
    
    [super setSelected:selected animated:animated];
    
    self.lblDiscount.backgroundColor = discountColor;
    self.oldPriceStrikeThroughLineView.backgroundColor = strikeThroughColor;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    UIColor *discountColor = self.lblDiscount.backgroundColor;
    UIColor *strikeThroughColor = self.oldPriceStrikeThroughLineView.backgroundColor;
    
    [super setHighlighted:highlighted animated:animated];
    
    self.lblDiscount.backgroundColor = discountColor;
    self.oldPriceStrikeThroughLineView.backgroundColor = strikeThroughColor;
}

#pragma mark - Setters
- (void)setExpirationDate:(NSString *)dateString {
    self.expirationDateLabel.text = dateString;
    self.expirationDateLabel.superview.hidden = dateString == nil;
}

- (void)setPrice:(NSNumber *)price discount:(NSNumber *)discount {
    NSNumber *newPrice = @((100.0 - discount.doubleValue) / 100.0 * price.doubleValue);
    self.lblPrice.text = [NSString stringWithFormat:@"%0.2f", newPrice.doubleValue];
    
    self.lblOldPrice.text = [NSString stringWithFormat:@"%0.2f", price.doubleValue];
    
    if (discount.doubleValue > 0.0) {
        self.lblDiscount.hidden = NO;
        self.lblDiscount.text = [NSString stringWithFormat:@"-%.0f%%", discount.doubleValue];
        
        self.lblOldPrice.superview.hidden = NO;
    } else {
        self.lblDiscount.hidden = YES;
        self.lblOldPrice.superview.hidden = YES;
    }
}

- (void)setBadProduct:(NSArray *)data isExpanded:(BOOL)isExpanded {
    if (data.count > 0) {
        self.btnExpand.hidden = NO;
        NSString *btnExpandTitle;
        if (isExpanded) {
            btnExpandTitle = @"−";
        } else {
            btnExpandTitle = @"+";
        }
        [ASPFunctions setButtonTitleWithoutAnimation:self.btnExpand title:btnExpandTitle state:UIControlStateNormal];
    } else {
        self.btnExpand.hidden = YES;
    }
}

#pragma mark - Delegate
- (IBAction)btnQtyStoreTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(cellBtnQtyStoreTapped:)]) {
        [self.delegate cellBtnQtyStoreTapped:self];
    }
}

- (IBAction)btnExpandTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(cellBtnExpandTapped:)]) {
        [self.delegate cellBtnExpandTapped:self];
    }
}


@end
