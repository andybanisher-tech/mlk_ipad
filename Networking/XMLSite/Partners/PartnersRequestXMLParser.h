//
//  PartnersRequestXMLParser.h
//  MLK
//
//  Created by Alexandr Polienko on 12.12.2025.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PartnersRequestXMLParser : NSObject

- (void)parse:(NSData *)webData;

@end

NS_ASSUME_NONNULL_END
