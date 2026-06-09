//
//  Base64Class.h
//  MLK
//
//  Created by Rustem Galyamov on 09.04.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Base64Class: NSObject

+ (NSString *)encode:(const uint8_t*) input length:(NSInteger) length;

+ (NSString *)encode:(NSData*) rawBytes;

+ (NSData *)decode:(const char*) string length:(NSInteger) inputLength;

+ (NSData *)decode:(NSString*) string;

@end
