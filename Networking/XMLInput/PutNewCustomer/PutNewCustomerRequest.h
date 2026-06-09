//
//  PutNewCustomerRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 08.04.2014.
//
//

#import <Foundation/Foundation.h>

@interface PutNewCustomerRequest: NSObject {
    NSString        *custAccount;
}

@property(nonatomic,retain)NSString        *custAccount;

- (void)sendCustomer:(NSString *)msg;

@end
