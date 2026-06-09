//
//  RWBorderedButton.h
//  rockwool
//
//  Created by Иван Труфанов on 06.08.15.
//  Copyright (c) 2015 Werbary. All rights reserved.
//

#import "UIKit/UIKit.h"

@interface RWBorderedButton : UIButton

- (void)setHighlightedState:(BOOL)highlighted;

#pragma mark - Custom UIButton Init
+ (instancetype)buttonWithFrame:(CGRect)frame title:(NSString *)title;

@end
