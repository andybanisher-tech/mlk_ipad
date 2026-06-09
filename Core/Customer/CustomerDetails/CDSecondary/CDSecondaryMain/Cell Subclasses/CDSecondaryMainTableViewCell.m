//
//  CDSecondaryMainTableViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 25.09.2024.
//

#import "CDSecondaryMainTableViewCell.h"

@interface CDSecondaryMainTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@end

@implementation CDSecondaryMainTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Setters
- (void)setData:(NSDictionary *)data {
    self.nameLabel.text = data[@"name"];
    self.valueLabel.text = data[@"value"];
}

@end
