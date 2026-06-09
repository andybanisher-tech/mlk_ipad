//
//  CDPrimarySectionItem.m
//  MLK
//
//  Created by Alexandr Polienko on 27.09.2024.
//

#import "CDPrimarySectionItem.h"

#import "GeneratedAssetSymbols.h"

@implementation CDPrimarySectionItem

- (instancetype)init {
    self = [super init];
    if (self) {
        self.titleColor = [UIColor colorNamed:ACColorNameGrayNavBarBackground];
        self.isEnabled = YES;
    }
    return self;
}

@end
