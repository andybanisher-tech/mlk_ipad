//
//  BrandMerch.h
//  MLK
//
//  Created by Rustem Galyamov on 04.07.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BrandMerch: NSObject {
    
    NSString    *BrandID;
    NSString    *BrandName;
}

@property(nonatomic,retain)NSString *BrandID;
@property(nonatomic,retain)NSString *BrandName;

@end
