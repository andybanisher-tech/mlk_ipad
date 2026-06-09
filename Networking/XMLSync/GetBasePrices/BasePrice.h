//
//  BasePrice.h
//  MLK
//
//  Created by Rustem Galyamov on 13.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BasePrice: NSObject {
    
	NSString *ItemID;	
	NSString *Price;
    NSString *PriceDate;	
	NSString *PriceTypeID;
}

@property (nonatomic, retain) NSString *ItemID;
@property (nonatomic, retain) NSString *Price;
@property (nonatomic, retain) NSString *PriceDate;
@property (nonatomic, retain) NSString *PriceTypeID;

@end
