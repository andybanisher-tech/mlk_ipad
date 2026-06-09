//
//  PutOrdersNewXMLParser.h
//  MLK
//
//  Created by Rustem Galyamov on 22.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PutOrdersNewXMLParser: NSObject

@property (nonatomic, assign) BOOL isConsult;
@property (nonatomic, copy) NSString *salesId;

- (void)parse:(NSData *)webData;

@end
