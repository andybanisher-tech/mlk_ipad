//
//  AnalyticsWorker.h
//  MLK
//
//  Created by Alexandr Polienko on 17.06.2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AnalyticsWorker : NSObject

+ (void)initialize NS_UNAVAILABLE;
+ (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - AppMetrica
+ (void)configureAppMetricaIfNeeded;

+ (void)appMetricaTrackSendRequest:(NSString *)soapMessage;
+ (void)appMetricaTrackRequestResponse:(NSString *)soapMessage error:(NSError * _Nullable)error;

+ (void)appMetricaTrackSyncAllDataStarted:(NSString *)udid;
+ (void)appMetricaTrackSyncAllDataSuccess;
+ (void)appMetricaTrackSyncAllDataFailure:(NSString *)errorString;

+ (void)appMetricaTrackSyncRemainsStarted:(NSString *)udid;
+ (void)appMetricaTrackSyncRemainsSuccess;
+ (void)appMetricaTrackSyncRemainsFailure:(NSString *)errorString;

@end

NS_ASSUME_NONNULL_END
