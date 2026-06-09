//
//  DNRespXMLParser.h
//  MLK
//
//  Created by Rustem Galyamov on 27.11.12.
//
//

#import <Foundation/Foundation.h>

@interface PutListStatusDNXMLParser: NSObject

@property (nonatomic, copy) NSString *custAccount;

- (void)parse:(NSData *)webData;

@end
