//
//  PropertiesList.h
//  MLK
//
//  Created by Rustem Galyamov on 02.06.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PropertiesList: NSObject {
    
    NSString    *PropertyID;
    NSString    *ListElementID;
    NSString    *ListElementName;
}

@property(nonatomic,retain)NSString *PropertyID;
@property(nonatomic,retain)NSString *ListElementID;
@property(nonatomic,retain)NSString *ListElementName;
@end
