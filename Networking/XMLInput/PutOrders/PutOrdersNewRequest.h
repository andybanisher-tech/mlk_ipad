//
//  PutOrdersNewRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 13.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PutOrdersNewRequest: NSObject

@property (nonatomic, assign) BOOL isConsult;
@property (nonatomic, copy) NSString *salesId;

- (void)sendSales:(NSString *)msg;

@end
