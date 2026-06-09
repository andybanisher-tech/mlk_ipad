//
//  CDPrimaryCollectionViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 27.09.2024.
//

#import "CDPrimaryCollectionViewCell.h"

@interface CDPrimaryCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@end

@implementation CDPrimaryCollectionViewCell

#pragma mark - Life Cycle
- (void)awakeFromNib {
    [super awakeFromNib];
    
    //Constants
    CGFloat cellHeight = 50.0;
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
    self.iconImageView.hidden = item.icon == nil;
    self.iconImageView.image = item.icon;
    
    self.titleLabel.text = item.title;
    self.titleLabel.textColor = item.titleColor;
    
    self.titleDetailLabel.hidden = item.titleDetail == nil;
    self.titleDetailLabel.text = item.titleDetail;
    
    self.subtitleLabel.hidden = item.subtitle == nil;
    self.subtitleLabel.text = item.subtitle;
    
    self.contentView.alpha = item.isEnabled ? 1.0 : 0.5;
    self.userInteractionEnabled = item.isEnabled;
}

@end
