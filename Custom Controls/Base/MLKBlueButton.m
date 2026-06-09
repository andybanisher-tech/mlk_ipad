//
//  MLKBlueButton.m
//  mlk
//
//  Created by Damir Sitdikov on 14.01.16.
//
//

#import "MLKBlueButton.h"

@implementation MLKBlueButton

- (void)awakeFromNib {
    [super awakeFromNib];
    UIColor *fillColor = [ASPFunctions colorFromHex:@"00b4ff"];
    self.layer.cornerRadius = 5.0f;
    self.layer.borderWidth = 0.f;
    self.layer.backgroundColor = fillColor.CGColor;
    [self.titleLabel setFont:[UIFont boldSystemFontOfSize:18.f]];
    [self.titleLabel setTextColor:UIColor.whiteColor];
}


@end
