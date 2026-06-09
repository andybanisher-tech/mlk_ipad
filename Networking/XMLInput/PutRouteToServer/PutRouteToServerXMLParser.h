//
//  PutRouteToServerXMLParser.h
//  MLK
//
//  Created by Rustem Galyamov on 21.01.13.
//
//

#import <Foundation/Foundation.h>

@interface PutRouteToServerXMLParser: NSObject

- (void)parseData:(NSData *)webData;
- (NSString *)getResponseStatus:(NSData *)webData;

@end
