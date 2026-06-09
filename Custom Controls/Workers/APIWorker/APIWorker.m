//
//  APIWorker.m
//  MLK
//
//  Created by Alexandr Polienko on 30.04.2020.
//  Copyright © 2020 MIR. All rights reserved.
//

#import "APIWorker.h"

#import "AnalyticsWorker.h"

//Urls
static NSString *const kDefaultServerAddress = @"https://exchange.mirlk.ru/v82/ws/";
static NSString *const kTestServerAddress = @"https://exchange.mirlk.ru/store_mukhin/ws/";
static NSString *const kSiteExchangeAddress = @"https://exchange.mirlk.ru/SiteExch/hs/site/";
static NSString *const kOldSiteExchangeAddress = @"https://exchange.mirlk.ru/v82/ws/site.1cws";
static NSString *const kPromoServiceAddress = @"https://bot.stalker-co.ru/promo/";

//Tokens
static NSString *const kExchangeAuthHeader = @"Gi@NYeV$D5";

//Constants
static const NSInteger kRequestLimit = 20;

@interface APIWorker ()

@property (nonatomic, strong) NSURLSession *soapUrlSession;
@property (nonatomic, strong) NSURLSession *jsonUrlSession;

@property (nonatomic, strong) NSURL *srvAddressInput;
@property (nonatomic, strong) NSURL *srvAddressOutput;

@end

@implementation APIWorker

+ (instancetype)sharedInstance {
    static APIWorker *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
        
        // Instantiate SOAP session configuration object.
        NSURLSessionConfiguration *soapConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        soapConfiguration.timeoutIntervalForRequest = 180.0;
        soapConfiguration.HTTPAdditionalHeaders = @{@"Content-Type" : @"application/soap+xml; charset=utf-8"};
        
        // Instantiate SOAP session object.
        sharedInstance.soapUrlSession = [NSURLSession sessionWithConfiguration:soapConfiguration];
        
        // Instantiate JSON session configuration object.
        NSURLSessionConfiguration *jsonConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        jsonConfiguration.timeoutIntervalForRequest = 60.0;
        
        // Instantiate JSON session object.
        sharedInstance.jsonUrlSession = [NSURLSession sessionWithConfiguration:jsonConfiguration];
        
        [sharedInstance updateServerAddresses];
    });
    
    return sharedInstance;
}

#pragma mark - SOAP Requests
- (NSURLSessionDataTask *)sendInputRequest:(NSString *)soapMessage completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.srvAddressInput];
    return [self sendRequest:request soapMessage:soapMessage completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)sendOutputRequest:(NSString *)soapMessage completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.srvAddressOutput];
    return [self sendRequest:request soapMessage:soapMessage completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)sendSiteRequest:(NSString *)soapMessage completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kOldSiteExchangeAddress]];
    return [self sendRequest:request soapMessage:soapMessage completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)sendRequest:(NSMutableURLRequest *)request soapMessage:(NSString *)soapMessage completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    request.HTTPMethod = @"POST";
    request.HTTPBody = [soapMessage dataUsingEncoding:NSUTF8StringEncoding];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    [AnalyticsWorker appMetricaTrackSendRequest:soapMessage];
    NSURLSessionDataTask *task = [self.soapUrlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(data, response, error);
        });
        
        [AnalyticsWorker appMetricaTrackRequestResponse:soapMessage error:error];
    }];
    [task resume];
    
    return task;
}

#pragma mark - JSON Requests
- (void)getBonusBalance:(NSString *)custAccount completion:(void (^)(NSDictionary * _Nullable data, NSError * _Nullable error))completion {
    NSString *urlString = [NSString stringWithFormat:@"%@UrGetBonusBalance?SiteID=%@&IDPartner=%@", kSiteExchangeAddress, kExchangeSiteID, custAccount];
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request addValue:kExchangeAuthHeader forHTTPHeaderField:@"Authorization"];

    NSURLSessionDataTask *task = [self.jsonUrlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                NSDictionary *dataJSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(dataJSON, nil);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
#if DEBUG
                NSLog(@"%@", error.localizedDescription);
#endif
            }
        });
    }];
    [task resume];
}

- (void)getReferralOrders:(NSString *)custAccount page:(NSInteger)page completion:(void (^)(NSDictionary * _Nullable data, NSError * _Nullable error))completion {
    NSString *urlString = [NSString stringWithFormat:@"%@urGetReferal_Inet_Orders?SiteID=%@&IDPartner=%@&Quantity=%ld&Page=%ld", kSiteExchangeAddress, kExchangeSiteID, custAccount, (long)kRequestLimit, (long)page];
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request addValue:kExchangeAuthHeader forHTTPHeaderField:@"Authorization"];

    NSURLSessionDataTask *task = [self.jsonUrlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                NSDictionary *dataJSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(dataJSON, nil);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
#if DEBUG
                NSLog(@"%@", error.localizedDescription);
#endif
            }
        });
    }];
    [task resume];
}

- (void)getBrandSalesPlan:(NSString *)custAccount date:(NSString *)date completion:(void (^)(id _Nullable data, NSError * _Nullable error))completion {
    NSString *urlString = [NSString stringWithFormat:@"%@UrGetSalesPlan?SiteID=%@&IDPartner=%@&Date=%@", kSiteExchangeAddress, kExchangeSiteID, custAccount, date];
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request addValue:kExchangeAuthHeader forHTTPHeaderField:@"Authorization"];

    NSURLSessionDataTask *task = [self.jsonUrlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                id dataJSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(dataJSON, nil);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
#if DEBUG
                NSLog(@"%@", error.localizedDescription);
#endif
            }
        });
    }];
    [task resume];
}

- (void)getAvailablePromos:(NSString *)custAccount completion:(void (^)(NSArray * _Nullable promotions, NSError * _Nullable error))completion {
    NSString *encodedCustAccount = [custAccount stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet] ?: @"";
    NSString *urlString = [NSString stringWithFormat:@"%@%@/data", kPromoServiceAddress, encodedCustAccount];
    NSURL *url = [NSURL URLWithString:urlString];

#if DEBUG
    NSLog(@"[Promos] GET %@", urlString);
#endif

    if (!url) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, [NSError errorWithDomain:@"APIWorker" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Неверный адрес запроса"}]);
        });
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 30.0;

    NSURLSessionDataTask *task = [self.jsonUrlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
#if DEBUG
        NSHTTPURLResponse *http = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse *)response : nil;
        NSLog(@"[Promos] status=%ld bytes=%lu error=%@", (long)http.statusCode, (unsigned long)data.length, error.localizedDescription);
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                completion(nil, error);
                return;
            }

            if (!data) {
                completion(nil, [NSError errorWithDomain:@"APIWorker" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"Пустой ответ сервера"}]);
                return;
            }

            NSError *jsonError;
            id dataJSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            if (jsonError || ![dataJSON isKindOfClass:NSDictionary.class]) {
                completion(nil, jsonError ?: [NSError errorWithDomain:@"APIWorker" code:-3 userInfo:@{NSLocalizedDescriptionKey: @"Неверный формат ответа"}]);
                return;
            }

            id promotions = dataJSON[@"promotions"];
            completion([promotions isKindOfClass:NSArray.class] ? promotions : @[], nil);
        });
    }];
    [task resume];
}

#pragma mark - Data
- (void)updateServerAddresses {
    NSString *serverUrlString = [PersistenceWorker load:@"serverAddress"];
    self.srvAddressOutput = [NSURL URLWithString:[NSString stringWithFormat:@"%@OUTPUT.1cws", serverUrlString ? serverUrlString : kDefaultServerAddress]];
    self.srvAddressInput = [NSURL URLWithString:[NSString stringWithFormat:@"%@INPUT.1cws", serverUrlString ? serverUrlString : kDefaultServerAddress]];
}

- (NSURL *)srvAddressInputURL {
    return self.srvAddressInput;
}

- (NSString *)authHeader {
    NSString *authString = [NSString stringWithFormat:@"%@:%@", LocalAuthWorker.userName, LocalAuthWorker.userPass];
    NSData *authData = [authString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authHeader = [NSString stringWithFormat: @"Basic %@", [authData base64EncodedStringWithOptions:0]];
    
    return authHeader;
}

#pragma mark - Constants
- (NSArray *)serverAddresses {
    return @[kDefaultServerAddress, kTestServerAddress];
}

@end
