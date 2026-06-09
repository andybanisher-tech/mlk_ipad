//
//  PutTTPropertiesValueRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 28.06.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PutGroupPropertiesValueRequest.h"

@interface PutTTPropertiesValueRequest: NSObject {
    
    NSString        *custAccount;
}
  
@property (nonatomic, retain) NSString *custAccount;
 
@property (nonatomic, assign) BOOL withoutProgress;
 
- (void)sendTTPropertiesValue;
- (void)sendMsg:(NSString *)msg;

@end
