//
//  PutNewCustomerXMLParser.h
//  MLK
//
//  Created by Rustem Galyamov on 08.04.2014.
//
//

#import <Foundation/Foundation.h>

@interface PutNewCustomerXMLParser: NSObject

@property (nonatomic, copy) NSString *custAccount;

- (void)parse:(NSData *)webData;

@end
