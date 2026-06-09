//
//  ActionFileRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 08.04.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ActionFileRequest: NSObject

@property(copy, nonatomic) NSString *actionId;

- (void)fileReq;

@end
