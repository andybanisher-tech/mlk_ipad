//
//  Debouncer.m
//  MLK
//
//  Created by Alexandr Polienko on 23.02.2026.
//

#import "Debouncer.h"

@interface Debouncer ()

@property (nonatomic, assign) NSTimeInterval delay;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, nullable, copy) dispatch_block_t workItem;

@end

@implementation Debouncer

- (instancetype)init {
    return [self initWithDelay:0.8 queue:dispatch_get_main_queue()];
}

- (instancetype)initWithDelay:(NSTimeInterval)delay
                        queue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _delay = delay;
        _queue = queue ?: dispatch_get_main_queue();
    }
    return self;
}

- (void)dispatch:(dispatch_block_t)block {
    if (!block) return;
    
    [self cancel];
    
    __weak typeof(self) weakSelf = self;
    
    self.workItem = dispatch_block_create(0, block);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delay * NSEC_PER_SEC)), self.queue, self.workItem);
}

- (void)cancel {
    if (self.workItem) {
        dispatch_block_cancel(self.workItem);
        self.workItem = nil;
    }
}

- (void)dealloc {
    [self cancel];
}

@end
