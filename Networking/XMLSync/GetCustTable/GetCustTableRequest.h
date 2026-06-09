//
//  GetCustTableRequest.h
//  AiCRM
//
//  Created by Rustem Galyamov on 07.04.11.
//  Copyright 2011 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GetCustTableRequest: NSObject

@property (nonatomic, assign) BOOL isSchedulerRequest;

- (void)requestCustTable;
- (void)requestCustTable:(NSString *)login;

@end
