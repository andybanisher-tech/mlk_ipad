//
//  CDSecondaryReferralOrderCollectionViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 24.06.2025.
//

#import "CDSecondaryReferralOrderCollectionViewCell.h"

@interface CDSecondaryReferralOrderCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *clientLabel;
@property (weak, nonatomic) IBOutlet UILabel *sumLabel;
@property (weak, nonatomic) IBOutlet UILabel *bonusLabel;

@end

@implementation CDSecondaryReferralOrderCollectionViewCell

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
- (void)setOrder:(NSDictionary *)order {
    self.numberLabel.text = order[@"Order"];
    self.orderDateLabel.text = order[@"OrderDate"];
    self.clientLabel.text = order[@"Client"];
    self.sumLabel.text = [NSString stringWithFormat:@"%@ ₽", order[@"RealSum"]];
    self.bonusLabel.text = [NSString stringWithFormat:@"%@", order[@"BonusPoints"]];
}


@end
