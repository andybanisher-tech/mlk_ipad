//
//  SalesPdfRequest.h
//  MLK
//
//  Created by Alexandr Polienko on 15.04.2024.
//

#import <Foundation/Foundation.h>

//Custom Objects
#import "DocumentType.h"

NS_ASSUME_NONNULL_BEGIN

@interface SalesPdfRequest : NSObject

- (void)requestDocument:(DocumentType *)docType salesUUID:(NSString *)salesUUID completion:(void (^)(NSData *pdfData, NSString *_Nullable errorString))completion;

@end

NS_ASSUME_NONNULL_END
