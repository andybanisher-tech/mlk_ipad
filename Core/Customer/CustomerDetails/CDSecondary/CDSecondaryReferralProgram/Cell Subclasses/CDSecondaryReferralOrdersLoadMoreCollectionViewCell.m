//
//  CDSecondaryReferralOrdersLoadMoreCollectionViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 27.06.2025.
//

#import "CDSecondaryReferralOrdersLoadMoreCollectionViewCell.h"

@implementation CDSecondaryReferralOrdersLoadMoreCollectionViewCell

#pragma mark - Life Cycle
- (void)awakeFromNib {
    [super awakeFromNib];
    
    //Constants
    CGFloat cellHeight = 60.0;
    NSLayoutConstraint *heightConstraint = [self.contentView.heightAnchor constraintGreaterThanOrEqualToConstant:cellHeight];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;
    heightConstraint.active = YES;
}

#pragma mark - Button Actions
- (IBAction)loadMoreButtonTapped:(id)sender {
    self.onCellLoadMoreButtonTapped();
}

@end
