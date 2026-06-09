//
//  CDPrimaryHeaderCollectionViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 27.09.2024.
//

#import "CDPrimaryHeaderCollectionViewCell.h"

@interface CDPrimaryHeaderCollectionViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@end

@implementation CDPrimaryHeaderCollectionViewCell

#pragma mark - Life Cycle
- (void)awakeFromNib {
    [super awakeFromNib];
    
    //Constants
    CGFloat cellHeight = 70.0;
    NSLayoutConstraint *heightConstraint = [self.contentView.heightAnchor constraintEqualToConstant:cellHeight];
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
- (void)setItem:(CDPrimarySectionItem *)item {
    self.titleLabel.text = item.title;
    self.subtitleLabel.text = item.subtitle;
}

@end
