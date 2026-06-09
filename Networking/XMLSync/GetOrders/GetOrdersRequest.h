//
//  GetOrdersRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 22.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GetOrdersRequest: NSObject

@property(assign, nonatomic) BOOL removeOld;
@property(assign, nonatomic) BOOL synsSalesLine;
@property(copy, nonatomic) NSString *syncNum1C;

- (void)salesReq;
- (void)salesLineReq:(NSString *)salesNumber;


@end
