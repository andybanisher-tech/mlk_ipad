//
//  Items.m
//  MLK
//
//  Created by Rustem Galyamov on 07.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "Items.h"

@interface Items () <NSCopying>

@end

@implementation Items


- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    id copy = [Items new];
    
    if (copy) {
        [copy setBrandID:self.brandID];
        [copy setItemID:self.itemID];
        [copy setItemName:self.itemName];
        [copy setUnit:self.unit];
        [copy setQty:self.qty];
        [copy setGroupID:self.groupID];
        [copy setClosed:self.closed];
        [copy setAction:self.action];
        [copy setPromo:self.promo];
        [copy setDiscount:self.discount];
        [copy setStoresJSON:self.storesJSON];
        [copy setBadProductJSON:self.badProductJSON];
        [copy setIsBadProduct:self.isBadProduct];
    }
    return copy;
}

@end
