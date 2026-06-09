//
//  PutContactsXMLParser.h
//  MLK
//
//  Created by Nikita on 23/01/15.
//
//

#import <Foundation/Foundation.h>

@interface PutContactsXMLParser: NSObject

@property (nonatomic, copy) NSString *custAccount;
@property (nonatomic, copy) NSString *contactId;

- (void)parse:(NSData *)webData;

@end
