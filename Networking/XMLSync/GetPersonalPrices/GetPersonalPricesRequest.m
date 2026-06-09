//
//  GetPersonalPrices.m
//  MLK
//
//  Created by Rustem Galyamov on 20.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GetPersonalPricesRequest.h"
#import "GetPersonalPricesXMLParser.h"
#import "GetOrdersRequest.h"
#import "SyncError.h"

@interface GetPersonalPricesRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetPersonalPricesRequest

- (void)pPricesReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSSet *selectedIPadsSet = LocalAuthWorker.selectedIPadsSet;
    for (NSDictionary *object in selectedIPadsSet) {
        udid = [NSString stringWithFormat:@"%@,%@", udid, object[@"id"]];
    }
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetPersonalPrices>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetPersonalPrices>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid];

    self.progress = [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nПерсональный прайс-лист"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
//    NSString *theXML = [[NSString alloc]
//                        initWithBytes: [webData mutableBytes]
//                        length:[webData length]
//                        encoding:NSUTF8StringEncoding];
//    //---shows the XML---
//    NSLog(@"%@", theXML);
    
    GetPersonalPricesXMLParser *parser = [GetPersonalPricesXMLParser new];
    [parser parse:data];
    
    GetOrdersRequest *salesRequest = [GetOrdersRequest new];
    salesRequest.synsSalesLine = NO;
    salesRequest.syncNum1C = @"";
    
    [salesRequest salesReq];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nПерсональный прайс-лист"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end

