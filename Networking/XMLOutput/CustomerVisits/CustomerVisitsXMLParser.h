//
//  CustomerVisitsXMLParser.h
//  MLK
//
//  Created by Alexandr Polienko on 04.09.2023.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomerVisitsXMLParser: NSObject

- (void)parse:(NSData *)webData;

@end

NS_ASSUME_NONNULL_END
