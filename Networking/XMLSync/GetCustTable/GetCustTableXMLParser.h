//
//  GetCustTableXMLParser.h
//  AiCRM
//
//  Created by Rustem Galyamov on 05.11.10.
//  Copyright 2010 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GetCustTableXMLParser: NSObject

@property (nonatomic, assign) BOOL isSchedulerRequest;

- (void)parse:(NSData *)webData;

@end
