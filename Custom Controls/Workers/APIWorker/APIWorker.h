//
//  APIWorker.h
//  MLK
//
//  Created by Alexandr Polienko on 30.04.2020.
//  Copyright © 2020 MIR. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//Tokens
static NSString *const kExchangeSiteID = @"113";

@interface APIWorker: NSObject

+ (instancetype)sharedInstance;

#pragma mark - SOAP Requests
- (NSURLSessionDataTask *)sendInputRequest:(NSString *)soapMessage completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;
- (NSURLSessionDataTask *)sendOutputRequest:(NSString *)soapMessage completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;
- (NSURLSessionDataTask *)sendSiteRequest:(NSString *)soapMessage completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

#pragma mark - JSON Requests
- (void)getBonusBalance:(NSString *)custAccount completion:(void (^)(NSDictionary * _Nullable data, NSError * _Nullable error))completion;
- (void)getReferralOrders:(NSString *)custAccount page:(NSInteger)page completion:(void (^)(NSDictionary * _Nullable data, NSError * _Nullable error))completion;
- (void)getBrandSalesPlan:(NSString *)custAccount date:(NSString *)date completion:(void (^)(id _Nullable data, NSError * _Nullable error))completion;
- (void)getAvailablePromos:(NSString *)custAccount completion:(void (^)(NSArray * _Nullable promotions, NSError * _Nullable error))completion;

#pragma mark - Data
- (void)updateServerAddresses;
- (NSURL *)srvAddressInputURL;

#pragma mark - Constants
- (NSArray *)serverAddresses;

@end

NS_ASSUME_NONNULL_END
