//
//  NavigationWorker.h
//  MLK
//
//  Created by Alexandr Polienko on 30.08.2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NavigationWorker : NSObject

+ (void)initialize NS_UNAVAILABLE;
+ (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - CustomerDetails
+ (void)openCustomerDetails:(NSString *)custAccount;

#pragma mark - Scheduler
+ (void)openScheduler;

@end

NS_ASSUME_NONNULL_END
