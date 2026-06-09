//
//  TaskTableViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 12.08.2021.
//

#import "TaskTableViewCell.h"

@implementation TaskTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Delegate
- (IBAction)btnAssignTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(cellBtnAssignTapped:)]) {
        [self.delegate cellBtnAssignTapped:self];
    }
}

@end
