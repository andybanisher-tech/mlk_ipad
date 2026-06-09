//
//  CDSecondaryPassportValuePickerTableViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 28.03.2025.
//

#import "CDSecondaryPassportValuePickerTableViewCell.h"

@interface CDSecondaryPassportValuePickerTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation CDSecondaryPassportValuePickerTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Setters
- (void)setName:(NSString *)name {
    self.nameLabel.text = name;
}

@end
