//
// Created by Damir Sitdikov on 31.01.16.
//

#import "SyncStateWorker.h"

#define kSyncStateKey @"SyncStateKey"
#define kSyncErrorStateKey @"SyncErrorStateKey"

@implementation SyncStateWorker

+ (BOOL)synchronized {
    if ([NSUserDefaults.standardUserDefaults objectForKey:kSyncStateKey]) {
        return [[NSUserDefaults.standardUserDefaults objectForKey:kSyncStateKey] boolValue];
    }
    
    return NO;
}

+ (void)setSynchronized:(BOOL)value {
    [NSUserDefaults.standardUserDefaults setBool:value forKey:kSyncStateKey];
    [NSNotificationCenter.defaultCenter postNotificationName:kSyncStateChanged object:nil];
}

+ (void)setErrorState:(BOOL)value {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setBool:value forKey:kSyncErrorStateKey];
}

+ (BOOL)getErrorState {
    if ([NSUserDefaults.standardUserDefaults objectForKey:kSyncErrorStateKey]) {
        return [[NSUserDefaults.standardUserDefaults objectForKey:kSyncErrorStateKey] boolValue];
    }

    return NO;
}

@end
