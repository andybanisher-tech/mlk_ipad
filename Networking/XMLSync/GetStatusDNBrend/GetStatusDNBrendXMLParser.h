//
//  GetStatusDNBrendXMLParser.h
//  mlk
//
//  Created by Nikolya Smolnyakov on 14.10.16.
//
//

#import <Foundation/Foundation.h>


@interface GetStatusDNBrendXMLParser: NSObject

- (void)parse:(NSData *)webData;

@end
