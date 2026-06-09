//
//  GetBasePricesXMLParser.h
//  MLK
//
//  Created by Rustem Galyamov on 13.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GetBasePricesXMLParser: NSObject

- (void)parse:(NSData *)webData;

@end

