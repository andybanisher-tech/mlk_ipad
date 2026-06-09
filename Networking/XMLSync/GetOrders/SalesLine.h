//
//  SalesLine.h
//  MLK
//
//  Created by Rustem Galyamov on 24.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SalesLine: NSObject

@property (nonatomic, copy) NSString *ItemID;
@property (nonatomic, copy) NSString *ItemName;
@property (nonatomic, copy) NSString *BrandName;
@property (nonatomic, copy) NSString *Qty;
@property (nonatomic, copy) NSString *AvailQty;
@property (nonatomic, copy) NSString *Price;
@property (nonatomic, copy) NSString *Discount;
@property (nonatomic, copy) NSString *LineAmount;
@property (nonatomic, copy) NSString *StoreID;
@property (nonatomic, copy) NSString *isBadProduct;

@end
