//
//  GetItemsRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 06.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GetItemsRequest: NSObject

@property (nonatomic, assign) BOOL isSingleRequest;

- (void)itemsReq;

@end
