//
//  GetNewCustomerXMLParser.h
//  MLK
//
//  Created by Rustem Galyamov on 08.05.2014.
//
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@class NewCustomer;

@interface GetNewCustomerXMLParser: NSObject

- (void)parse:(NSData *)webData;

@end
