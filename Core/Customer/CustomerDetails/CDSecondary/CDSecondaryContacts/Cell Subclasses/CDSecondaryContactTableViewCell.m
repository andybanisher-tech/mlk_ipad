//
//  CDSecondaryContactTableViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 26.03.2025.
//

#import "CDSecondaryContactTableViewCell.h"

@interface CDSecondaryContactTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *roleLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@end

@implementation CDSecondaryContactTableViewCell {
    BOOL _isPressed;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted == _isPressed) { return; }
    _isPressed = !_isPressed;
    
    [ASPFunctions pulseView:self isActive:highlighted];
}

#pragma mark - Setters
- (void)setContact:(NSDictionary *)contact {
    self.roleLabel.text = contact[@"Position"];
    
    NSString *sName = contact[@"SName"];
    NSString *name = contact[@"Name"];
    NSString *mName = contact[@"MName"];
    NSArray *nameComponents = [@[sName, name, mName] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @".*\\S.*"]];
    self.nameLabel.text = [nameComponents componentsJoinedByString:@" "];
    
    self.phoneLabel.text = contact[@"Phone"];
    self.emailLabel.text = contact[@"Email"];
}

@end
