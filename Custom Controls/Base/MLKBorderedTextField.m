//
//  MLKBorderedTextField.m
//  mlk
//
//  Created by Damir Sitdikov on 30.12.15.
//
//

#import "MLKBorderedTextField.h"

@implementation MLKBorderedTextField {
    UIEdgeInsets _sidePadding;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    //Constants
    CGFloat sidePadding = 5.0;
    _sidePadding = UIEdgeInsetsMake(0.0, sidePadding, 0.0, sidePadding);
    
    self.layer.borderWidth = 2.0 / UIScreen.mainScreen.scale;
    self.layer.borderColor = UIColor.whiteColor.CGColor;
    self.layer.cornerRadius = 5.0;
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.alpha = enabled ? 1.0 : 0.5;
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    return UIEdgeInsetsInsetRect(bounds, _sidePadding);
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds {
    return UIEdgeInsetsInsetRect(bounds, _sidePadding);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return UIEdgeInsetsInsetRect(bounds, _sidePadding);
}

@end
