//
//  GetOrdersXMLParser.h
//  MLK
//
//  Created by Rustem Galyamov on 24.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GetOrdersXMLParser: NSObject

@property (nonatomic, assign) BOOL removeOld;
@property (nonatomic, assign) BOOL syncSalesLine;
@property (nonatomic, copy) NSString *syncNum1C;

- (void)parse:(NSData *)webData;
 
@end
