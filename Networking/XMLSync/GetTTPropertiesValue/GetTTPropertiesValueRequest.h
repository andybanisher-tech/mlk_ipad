//
//  GetTTPropertiesValueRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 13.07.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GetTTPropertiesValueRequest: NSObject

@property (nonatomic, assign) BOOL syncTTPropertiesOnly;

- (void)sendRequest;

@end
