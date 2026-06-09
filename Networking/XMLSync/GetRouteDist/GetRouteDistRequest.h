//
//  GetRouteDistRequest.h
//  MLK
//
//  Created by Nikita on 19/02/15.
//
//

#import <Foundation/Foundation.h>

@interface GetRouteDistRequest: NSObject

@property (nonatomic, copy) NSString *managerID;
@property (nonatomic, assign) BOOL isSingleRequest;
@property (nonatomic, assign) BOOL isSchedulerRequest;

- (void)routeReq;
- (void)routeReq:(double)searchRadius;

@end
