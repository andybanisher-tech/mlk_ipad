//
//  MoreCustRequest.h
//  MLK
//
//  Created by garu on 11/7/14.
//
//

#import <Foundation/Foundation.h>

@interface MoreCustRequest: NSObject

@property(copy, nonatomic) NSString *propertyValueId;
@property(copy, nonatomic) NSString *brandId;

@property(assign, nonatomic) BOOL isCustContactRequest;

- (void)moreCustReq;

@end
