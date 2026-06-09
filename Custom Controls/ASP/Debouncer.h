//
//  Debouncer.h
//  MLK
//
//  Created by Alexandr Polienko on 23.02.2026.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Debouncer : NSObject

- (instancetype)initWithDelay:(NSTimeInterval)delay
                        queue:(dispatch_queue_t)queue;

- (void)dispatch:(dispatch_block_t)block;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
