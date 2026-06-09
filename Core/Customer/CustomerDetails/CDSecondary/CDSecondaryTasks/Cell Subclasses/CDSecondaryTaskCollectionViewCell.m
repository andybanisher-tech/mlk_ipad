//
//  CDSecondaryTaskCollectionViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 29.03.2025.
//

#import "CDSecondaryTaskCollectionViewCell.h"

#import "GeneratedAssetSymbols.h"

@interface CDSecondaryTaskCollectionViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *endDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *sourceLabel;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *transDateLabel;

@end

@implementation CDSecondaryTaskCollectionViewCell

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
- (void)setTask:(NSDictionary *)task {
    self.nameLabel.text = task[@"TaskName"];
    self.endDateLabel.text = task[@"DateEnd"];
    
    NSString *from1C = task[@"From1C"];
    NSString *source = task[@"Source"];
    if ([from1C isEqualToString:@"1"]) {
        if ([source isEqualToString:@"iPad"]) {
            source = @"Назначено iPad";
        } else {
            source = @"Назначено 1C";
        }
    } else {
        source = @"Собств.";
    }
    self.sourceLabel.text = source;
    
    NSString *result;
    if ([task[@"TypeOfResult"] isEqual:@"2"]) {
        result = task[@"LineDescription"];
    } else {
        result = task[@"Result"];
    }
    self.resultLabel.text = result;
    
    NSString *status = task[@"Status"];
    if ([status isEqualToString:@"Готово"]) {
        self.statusLabel.textColor = [UIColor colorNamed:ACColorNameMLKGreen];
    } else {
        self.statusLabel.textColor = self.nameLabel.textColor;
    }
    self.statusLabel.text = task[@"Status"];
    
    self.transDateLabel.text = task[@"TransDate"];
}

@end
