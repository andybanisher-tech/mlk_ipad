//
//  AnalyticsWorker.m
//  MLK
//
//  Created by Alexandr Polienko on 17.06.2024.
//

#import "AnalyticsWorker.h"

//AppMetrica
#import <AppMetricaCore/AppMetricaCore.h>
#import <AppMetricaCrashes/AppMetricaCrashes.h>

static NSString *const kAppMetricaApiKey = @"0d701f3b-695e-4397-8cd3-0abd8cc6dc99";

@implementation AnalyticsWorker

#pragma mark - AppMetrica
+ (void)configureAppMetricaIfNeeded {
    if (!AMAAppMetrica.isActivated) {
        AMAAppMetricaConfiguration *configuration = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:kAppMetricaApiKey];
        configuration.locationTracking = NO;
        configuration.userProfileID = LocalAuthWorker.login;
        [AMAAppMetrica activateWithConfiguration:configuration];
        
        AMAAppMetricaCrashesConfiguration *crashesConfiguration = [AMAAppMetricaCrashesConfiguration new];
        crashesConfiguration.probablyUnhandledCrashReporting = YES;
        [[AMAAppMetricaCrashes crashes] setConfiguration:crashesConfiguration];
    }
    
    [self appMetricaUpdateUserProfile];
}

+ (void)appMetricaUpdateUserProfile {
    AMAUserProfile *profile = [[AMAUserProfile alloc] initWithUpdates:@[
        [[AMAProfileAttribute name] withValue:LocalAuthWorker.emple],
    ]];
    
    AMAAppMetrica.userProfileID = LocalAuthWorker.login;
    [AMAAppMetrica reportUserProfile:profile onFailure:nil];
}

+ (void)appMetricaTrackSyncAllDataStarted:(NSString *)udid {
    [AMAAppMetrica reportEvent:@"SyncAllData started" onFailure:^(NSError * _Nonnull error) {
        
    }];
}

+ (void)appMetricaTrackSyncAllDataSuccess {
    [AMAAppMetrica reportEvent:@"SyncAllData success" onFailure:^(NSError * _Nonnull error) {
        
    }];
}

+ (void)appMetricaTrackSyncAllDataFailure:(NSString *)errorString {
    [AMAAppMetrica reportEvent:@"SyncAllData failure" parameters:@{@"error" : errorString} onFailure:^(NSError * _Nonnull error) {
        
    }];
}

+ (void)appMetricaTrackSyncRemainsStarted:(NSString *)udid {
    [AMAAppMetrica reportEvent:@"SyncRemains started" onFailure:^(NSError * _Nonnull error) {
        
    }];
}

+ (void)appMetricaTrackSyncRemainsSuccess {
    [AMAAppMetrica reportEvent:@"SyncRemains success" onFailure:^(NSError * _Nonnull error) {
        
    }];
}

+ (void)appMetricaTrackSyncRemainsFailure:(NSString *)errorString {
    [AMAAppMetrica reportEvent:@"SyncRemains failure" parameters: @{@"error" : errorString} onFailure:^(NSError * _Nonnull error) {
        
    }];
}

+ (void)appMetricaTrackSendRequest:(NSString *)soapMessage {
    NSString *requestName = [self requestName:soapMessage];
    
    [AMAAppMetrica reportEvent:@"Request sent" parameters:@{@"requestName" : requestName} onFailure:^(NSError * _Nonnull error) {
            
    }];
}

+ (void)appMetricaTrackRequestResponse:(NSString *)soapMessage error:(NSError * _Nullable)error {
    NSString *requestName = [self requestName:soapMessage];
    
    if (error) {
        [AMAAppMetrica reportEvent:@"Response error" parameters:@{@"requestName" : requestName, @"error" : error.localizedDescription} onFailure:^(NSError * _Nonnull error) {
            
        }];
    } else {
        [AMAAppMetrica reportEvent:@"Response success" parameters:@{@"requestName" : requestName} onFailure:^(NSError * _Nonnull error) {
            
        }];
    }
}

#pragma mark - AppMetrica Helpers
+ (NSString *)requestName:(NSString *)soapMessage {
    NSString *regexString = @"<sam:(.*?)>";
    NSRange searchRange = [soapMessage rangeOfString:regexString options:NSRegularExpressionSearch | NSCaseInsensitiveSearch];
    if (searchRange.location != NSNotFound) {
        NSString *searchString = [soapMessage substringWithRange:NSMakeRange(searchRange.location, searchRange.length - 1)];
        NSArray *components = [searchString componentsSeparatedByString:@":"];
        return components.lastObject;
    }
    
    return soapMessage;
}

@end
