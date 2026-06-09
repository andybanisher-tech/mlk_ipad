//
// Created by Damir Sitdikov on 31.01.16.
//

#import <Foundation/Foundation.h>

#define kSyncStateChanged @"SyncStateChanged"

@interface SyncStateWorker: NSObject

+ (BOOL)synchronized;

+ (void)setSynchronized:(BOOL)value;
+ (void)setErrorState:(BOOL)value;

+ (BOOL)getErrorState;

@end
