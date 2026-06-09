//
//  CDSecondaryBrandSalesPlanCollectionViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 23.02.2026.
//

#import "CDSecondaryBrandSalesPlanCollectionViewCell.h"

@interface CDSecondaryBrandSalesPlanCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *brandLabel;
@property (weak, nonatomic) IBOutlet UILabel *planLabel;
@property (weak, nonatomic) IBOutlet UILabel *factLabel;
@property (weak, nonatomic) IBOutlet UILabel *percentLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;

@end

@implementation CDSecondaryBrandSalesPlanCollectionViewCell

#pragma mark - Life Cycle
- (void)awakeFromNib {
    [super awakeFromNib];
    
    //Constants
    CGFloat cellHeight = 50.0;
    NSLayoutConstraint *heightConstraint = [self.contentView.heightAnchor constraintGreaterThanOrEqualToConstant:cellHeight];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;
    heightConstraint.active = YES;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.contentView.backgroundColor = highlighted ? UIColor.systemGray4Color : UIColor.whiteColor;
    } completion:nil];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.contentView.backgroundColor = selected ? UIColor.systemGray4Color : UIColor.whiteColor;
}

#pragma mark - Setters
- (void)setBrandSalesPlan:(NSDictionary *)brandSalesPlan {
    self.brandLabel.text = brandSalesPlan[@"brand"];
    self.planLabel.text = [NSString stringWithFormat:@"%@", brandSalesPlan[@"plan"]];
    self.factLabel.text = [NSString stringWithFormat:@"%@", brandSalesPlan[@"fact"]];
    self.percentLabel.text = [NSString stringWithFormat:@"%@", brandSalesPlan[@"percent"]];
    self.commentLabel.text = brandSalesPlan[@"comment"];
}

@end
