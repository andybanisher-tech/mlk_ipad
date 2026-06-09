//
//  PutTTPropertiesValueXMLParser.h
//  MLK
//
//  Created by Rustem Galyamov on 04.07.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PutTTPropertiesValueXMLParser: NSObject

@property (nonatomic, copy) NSString *custAccount;

- (void)parse:(NSData *)webData;

@end
