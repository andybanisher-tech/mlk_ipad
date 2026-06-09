//
//  RWBorderedButton.m
//  rockwool
//
//  Created by Иван Труфанов on 06.08.15.
//  Copyright (c) 2015 Werbary. All rights reserved.
//

#import "RWBorderedButton.h"

@implementation RWBorderedButton

- (void)awakeFromNib {
    [super awakeFromNib];
    [RWBorderedButton setupButton:self withTitle:self.configuration.title];
}

- (void)setHighlightedState:(BOOL)highlighted {
    [self updateConfiguration];
    UIButtonConfiguration *config = self.configuration;
    if (highlighted) {
        config.background.backgroundColor = [ASPFunctions colorFromHex:@"00b4ff"];
    } else {
        config.background.backgroundColor = UIColor.clearColor;
    }
    
    self.configuration = config;
}

+ (void)setupButton:(UIButton *)button withTitle:(NSString *)title {
    button.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;

    UIButtonConfiguration *config = button.configuration;
    if (!config) {
        config = UIButtonConfiguration.plainButtonConfiguration;
    }

    config.background.strokeColor = UIColor.whiteColor;
    config.background.strokeWidth = 2.0 / UIScreen.mainScreen.scale;
    config.baseForegroundColor = UIColor.whiteColor;
    config.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    config.title = title;
    
    __weak typeof(button) weakButton = button;
    config.titleTextAttributesTransformer = ^(NSDictionary<NSAttributedStringKey, id> *incoming) {
        NSMutableDictionary<NSAttributedStringKey, id> *outgoing = incoming.mutableCopy;
        outgoing[NSFontAttributeName] = [UIFont systemFontOfSize:16.0];
        outgoing[NSForegroundColorAttributeName] = weakButton.configuration.background.strokeColor;
        
        return outgoing;
    };
    
    button.configurationUpdateHandler = ^(__kindof UIButton * _Nonnull button) {
        UIButtonConfiguration *config = button.configuration;
        config.background.strokeColor = button.state == UIControlStateNormal ? UIColor.whiteColor : [UIColor.whiteColor colorWithAlphaComponent:0.6];
        
        button.configuration = config;
    };
        
    button.configuration = config;
}

#pragma mark - Custom UIButton Init
+ (instancetype)buttonWithFrame:(CGRect)frame title:(NSString *)title {
    RWBorderedButton *btn = [[RWBorderedButton alloc] initWithFrame:frame];
    [RWBorderedButton setupButton:btn withTitle:title];
    
    return btn;
}

@end
