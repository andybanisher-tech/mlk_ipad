//
//  GetBrandMerchRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 04.07.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "GetBrandMerchRequest.h"
#import "GetBrandMerchXMLParser.h"
#import "GetGroupPropertiesValueRequest.h"
#import "SyncError.h"

@interface GetBrandMerchRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetBrandMerchRequest

- (void)brandMerchReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetBrandMerch>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetBrandMerch>\n"
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
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nМерчендайзинг - марки ТП"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
//    NSString *theXML = [[NSString alloc]
//                        initWithBytes: [webData mutableBytes]
//                        length:[webData length]
//                        encoding:NSUTF8StringEncoding];
//    //---shows the XML---
//    NSLog(@"%@", theXML);
    
    GetBrandMerchXMLParser *parser = [GetBrandMerchXMLParser new];
    [parser parse:data];
    
    GetGroupPropertiesValueRequest *gpValuesRequest = [GetGroupPropertiesValueRequest new];
    [gpValuesRequest groupPropertiesReq];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nМерчендайзинг - марки ТП"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
