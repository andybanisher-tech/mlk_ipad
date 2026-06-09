//
//  GetGroupPropertiesRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 23.05.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//
#import "GetGroupPropertiesRequest.h"
#import "GetGroupPropertiesXMLParser.h"
#import "GetPropertiesListRequest.h"
#import "SyncError.h"

@interface GetGroupPropertiesRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetGroupPropertiesRequest

- (void)groupPropReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetGroupProperties>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetGroupProperties>\n"
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
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nМерчендайзинг - Параметры группы"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    /*NSString *theXML = [[NSString alloc]
     initWithBytes: [webData mutableBytes]
     length:[webData length]
     encoding:NSUTF8StringEncoding];*/
    //---shows the XML---
    //////NSLog(theXML);
    
    GetGroupPropertiesXMLParser *parser = [GetGroupPropertiesXMLParser new];
    [parser parse:data];
    
    GetPropertiesListRequest *propertiesListRequest = [GetPropertiesListRequest new];
    [propertiesListRequest propListReq];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nМерчендайзинг - Параметры группы"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
