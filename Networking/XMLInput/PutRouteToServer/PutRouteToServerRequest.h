//
//  PutRouteToServerRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 10.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PutRouteToServerRequestDelegate
- (void)isSendStart;
- (void)isSendStop;
- (void)isSendVisit;
- (void)isSendVisitNotSendStatus;
- (void)isSendVisitedNotSendStatus;
- (void)isSendCancelVisitNotSendStatus;
- (void)isSendVisited;
- (void)isSendCancelVisit;
- (void)failedToPutCustForRoute:(NSString *)status;

@end

@interface PutRouteToServerRequest: NSObject {
    NSString        *routeType;
    BOOL            start;
    BOOL            stop;
    BOOL            visit;
    BOOL            tapped;
    BOOL            visited;
    BOOL            cancelVisit;
}
  
@property (nonatomic, retain) NSString *routeType;
@property (nonatomic, weak) id<PutRouteToServerRequestDelegate> delegate;
@property (nonatomic, readwrite) BOOL start;
@property (nonatomic, readwrite) BOOL stop;
@property (nonatomic, readwrite) BOOL visit;
@property (nonatomic, readwrite) BOOL visited;
@property (nonatomic, readwrite) BOOL tapped;
@property (nonatomic, readwrite) BOOL cancelVisit;

- (void)sendRoute:(NSString *)msg;

@end

