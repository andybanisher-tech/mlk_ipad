//
//  CDSecondaryOrdersHistoryCollectionViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 25.09.2024.
//

#import "CDSecondaryOrdersHistoryCollectionViewCell.h"

@interface CDSecondaryOrdersHistoryCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *decisionDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *sourceLabel;
@property (weak, nonatomic) IBOutlet UILabel *sumLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation CDSecondaryOrdersHistoryCollectionViewCell

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
    self.numberLabel.text = order[@"SalesNum"];
    self.orderDateLabel.text = order[@"SalesDate"];
    self.decisionDateLabel.text = order[@"DeliveryDate"];
    self.sourceLabel.text = order[@"ChannelTypeId"];
    self.sumLabel.text = [NSString stringWithFormat:@"%@ ₽", order[@"AmountSum"]];
    self.statusLabel.text = order[@"SalesStatus"];
}

@end
