//
//  GetTwoRegionXMLParser.h
//  MLK
//
//  Created by garu on 11/7/14.
//
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@class Region;

@interface GetTwoRegionXMLParser: NSObject

- (void)parse:(NSData *)webData;

@end
