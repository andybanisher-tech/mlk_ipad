//
//  GroupMarks.h
//  MLK
//
//  Created by Rustem Galyamov on 23.05.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GroupBrand: NSObject {
    
    NSString    *GroupID;
    NSString    *BrandID;
    NSString    *GroupName;
}

@property(nonatomic,retain)NSString *GroupID;
@property(nonatomic,retain)NSString *BrandID;
@property(nonatomic,retain)NSString *GroupName;

@end
