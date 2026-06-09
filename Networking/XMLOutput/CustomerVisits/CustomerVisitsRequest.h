//
//  CustomerVisitsRequest.h
//  MLK
//
//  Created by Alexandr Polienko on 04.09.2023.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomerVisitsRequest: NSObject

- (void)getCustomerVisits:(NSString *)custAccount;

@end

NS_ASSUME_NONNULL_END
