//
//  GroupProperties.h
//  MLK
//
//  Created by Rustem Galyamov on 23.05.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GroupProperties: NSObject {
    
    NSString    *Period;
    NSString    *GroupID;
    NSString    *PropertyID;
    NSString    *PropertyType;
    NSString    *PropertyName;
}

@property(nonatomic,retain)NSString *Period;
@property(nonatomic,retain)NSString *GroupID;
@property(nonatomic,retain)NSString *PropertyID;
@property(nonatomic,retain)NSString *PropertyType;
@property(nonatomic,retain)NSString *PropertyName;
@end
