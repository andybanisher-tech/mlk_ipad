//
//  MLKBorderedLabel.m
//  mlk
//
//  Created by Damir Sitdikov on 29.12.15.
//
//

#import "MLKBorderedLabel.h"

@implementation MLKBorderedLabel

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.borderWidth = 2.f/UIScreen.mainScreen.scale;
    self.layer.borderColor = UIColor.whiteColor.CGColor;
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
}

- (void)drawTextInRect:(CGRect)rect {
    UIEdgeInsets insets = {0, 10, 0, 10};
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

@end
