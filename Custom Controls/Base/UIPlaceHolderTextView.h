//
//  UIPlaceHolderTextView.h
//  SOCOLOR
//
//  Created by Коля on 24.12.15.
//  Copyright © 2015 MIR. All rights reserved.
//

#import "UIKit/UIKit.h"
IB_DESIGNABLE
@interface UIPlaceHolderTextView : UITextView

@property (nonatomic, strong) IBInspectable  NSString *placeholder;
@property (nonatomic, strong) UIColor *placeholderColor;

- (void)textChanged:(NSNotification*)notification;

@end
