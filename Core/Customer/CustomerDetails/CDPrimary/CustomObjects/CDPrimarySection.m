//
//  CDPrimarySection.m
//  MLK
//
//  Created by Alexandr Polienko on 21.07.2025.
//

#import "CDPrimarySection.h"

@interface CDPrimarySection ()

@property (nonatomic, readwrite) NSString *title;
@property (nonatomic, readwrite) NSArray<CDPrimarySectionItem *> *items;

@end

@implementation CDPrimarySection

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<CDPrimarySectionItem *> *)items {
    self = [super init];
    if (self) {
        self.title = title;
        self.items = items;
    }
    return self;
}

@end
