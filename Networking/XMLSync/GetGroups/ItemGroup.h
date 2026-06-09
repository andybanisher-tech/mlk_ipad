//
//  ItemGroup.h
//  MLK
//
//  Created by Rustem Galyamov on 28.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ItemGroup: NSObject {
    
    NSString    *GroupID;
    NSString    *BrandID;
    NSString    *GroupName;
}    

@property (nonatomic, retain) NSString *GroupID;
@property (nonatomic, retain) NSString *BrandID;
@property (nonatomic, retain) NSString *GroupName;

@end
