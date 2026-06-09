//
//  SalesPdfXMLParser.h
//  MLK
//
//  Created by Alexandr Polienko on 15.04.2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SalesPdfXMLParser : NSObject

- (void)parse:(NSData *)webData completion:(void (^)(NSData *pdfData, NSString *_Nullable errorString))completion;

@end

NS_ASSUME_NONNULL_END
