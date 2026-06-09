//
//  Brand.h
//  MLK
//
//  Created by Rustem Galyamov on 05.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Brand: NSObject {
	NSString *BrandID;	
	NSString *BrandName;
}

@property (nonatomic, retain) NSString *BrandID;
@property (nonatomic, retain) NSString *BrandName;

@end
