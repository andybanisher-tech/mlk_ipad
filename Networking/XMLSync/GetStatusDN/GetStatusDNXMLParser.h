//
//  GetStatusDNXMLParser.h
//  MLK
//
//  Created by Rustem Galyamov on 05.12.13.
//
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@class Dream;

@interface GetStatusDNXMLParser: NSObject

- (void)parse:(NSData *)webData;

@end
