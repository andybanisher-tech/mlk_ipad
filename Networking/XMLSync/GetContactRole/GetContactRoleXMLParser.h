//
//  GetContactRoleXMLParser.h
//  MLK
//
//  Created by Alexandr Polienko on 29.11.2021.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GetContactRoleXMLParser: NSObject

- (void)parse:(NSData *)webData;

@end

NS_ASSUME_NONNULL_END
