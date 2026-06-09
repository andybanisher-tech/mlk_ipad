//
//  PutGroupPropertiesValueRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 28.06.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PutPhotosRequest.h"

@interface PutGroupPropertiesValueRequest: NSObject {
    
    NSString        *custAccount;
    
    BOOL notShowProgress;
}

@property(nonatomic,retain)NSString     *custAccount;

@property(nonatomic,readwrite)BOOL notShowProgress;

- (void)sendGroupPropertiesValue;
- (void)sendMsg:(NSString *)msg;

@end
