//
//  GroupPropertiesValue.h
//  MLK
//
//  Created by Rustem Galyamov on 08.07.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GroupPropertiesValue: NSObject {
    
    NSString    *Period;
    NSString    *CustomerID;
    NSString    *GroupID;
    NSString    *BrandID;
    NSString    *PropertyID;
    NSString    *PropertyValue;
    NSString    *PropertyValueID;
}

@property(nonatomic,retain)NSString    *Period;
@property(nonatomic,retain)NSString    *CustomerID;
@property(nonatomic,retain)NSString    *GroupID;
@property(nonatomic,retain)NSString    *BrandID;
@property(nonatomic,retain)NSString    *PropertyID;
@property(nonatomic,retain)NSString    *PropertyValue;
@property(nonatomic,retain)NSString    *PropertyValueID;

@end
