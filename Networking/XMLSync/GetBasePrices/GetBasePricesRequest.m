//
//  GetBasePrices.m
//  MLK
//
//  Created by Rustem Galyamov on 13.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GetBasePricesRequest.h"
#import "GetBasePricesXMLParser.h"
#import "GetPersonalPricesRequest.h"
#import "SyncError.h"

@interface GetBasePricesRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetBasePricesRequest

- (void)basePriceReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetBasePrices>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetBasePrices>\n"
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
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nБазовый прайс-лист"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    /*NSLog( @"Succeeded! Received %d bytes of data", [webData length] );
     NSString *theXML = [[NSString alloc]
     initWithBytes: [webData mutableBytes]
     length:[webData length]
     encoding:NSUTF8StringEncoding];
     //---shows the XML---
     NSLog(@"%@", theXML);*/
    
    GetBasePricesXMLParser *parser = [GetBasePricesXMLParser new];
    [parser parse:data];
    
    GetPersonalPricesRequest *ppreq = [GetPersonalPricesRequest new];
    [ppreq pPricesReq];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nБазовый прайс-лист"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end

