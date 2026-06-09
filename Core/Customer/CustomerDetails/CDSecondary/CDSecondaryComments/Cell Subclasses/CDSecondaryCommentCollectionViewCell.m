//
//  CDSecondaryCommentCollectionViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 27.03.2025.
//

#import "CDSecondaryCommentCollectionViewCell.h"

@interface CDSecondaryCommentCollectionViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *dateAndTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;

@end

@implementation CDSecondaryCommentCollectionViewCell

#pragma mark - Life Cycle
- (void)awakeFromNib {
    [super awakeFromNib];
    
    //Constants
    CGFloat cellHeight = 50.0;
    NSLayoutConstraint *heightConstraint = [self.contentView.heightAnchor constraintGreaterThanOrEqualToConstant:cellHeight];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;
    heightConstraint.active = YES;
}

#pragma mark - Setters
- (void)setComment:(NSDictionary *)comment {
    NSString *date = comment[@"Date"];
    NSString *time = comment[@"Time"];
    NSArray *dateComponents = [@[date, time] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @".*\\S.*"]];
    self.dateAndTimeLabel.text = [dateComponents componentsJoinedByString:@" - "];
    
    self.commentLabel.text = comment[@"Description"];
}

@end
