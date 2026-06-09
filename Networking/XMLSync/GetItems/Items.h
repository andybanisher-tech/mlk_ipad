//
//  Items.h
//  MLK
//
//  Created by Rustem Galyamov on 07.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Items: NSObject

@property (nonatomic, copy) NSString *brandID;
@property (nonatomic, copy) NSString *itemID;
@property (nonatomic, copy) NSString *itemName;
@property (nonatomic, copy) NSString *unit;
@property (nonatomic, copy) NSString *qty;
@property (nonatomic, copy) NSString *groupID;
@property (nonatomic, copy) NSString *closed;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, copy) NSString *promo;
@property (nonatomic, copy) NSString *discount;
@property (nonatomic, copy) NSString *storesJSON;
@property (nonatomic, copy) NSString *badProductJSON;
@property (nonatomic, copy) NSString *isBadProduct;

@end
