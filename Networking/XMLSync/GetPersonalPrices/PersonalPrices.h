//
//  PersonalPrices.h
//  MLK
//
//  Created by Rustem Galyamov on 20.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PersonalPrices: NSObject {
    
	NSString *CustAccount;	
	NSString *BrandID;
    NSString *PriceTypeID;	
	NSString *ContractID;
    NSString *Discount;	
	NSString *Date;
    NSString *Round;
    NSString *ComDiscount;
    NSString *Active;
    // Andrey
    NSString *Delay;
    NSString *MatrixID;
}

@property(nonatomic,retain)NSString *CustAccount;
@property(nonatomic,retain)NSString *BrandID;
@property(nonatomic,retain)NSString *PriceTypeID;
@property(nonatomic,retain)NSString *ContractID;
@property(nonatomic,retain)NSString *Discount;
@property(nonatomic,retain)NSString *Date;
@property(nonatomic,retain)NSString *Round;
@property(nonatomic,retain)NSString *ComDiscount;
@property(nonatomic,retain)NSString *Active;
// Andrey
@property(nonatomic,retain)NSString *Delay;
@property(nonatomic,retain)NSString *MatrixID;

@end
