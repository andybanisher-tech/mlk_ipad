//
//  GetCustContactNewRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 02.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//
#import "GetCustContactNewRequest.h"
#import "GetCustContactXMLParser.h"
#import "SyncError.h"
#import "GetBrandRequest.h"

@interface GetCustContactNewRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetCustContactNewRequest

- (void)custContactReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSSet *selectedIPadsSet = LocalAuthWorker.selectedIPadsSet;
    for (NSDictionary *object in selectedIPadsSet) {
        udid = [NSString stringWithFormat:@"%@,%@", udid, object[@"id"]];
    }
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetCustContactNew>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetCustContactNew>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid];
    
//    NSLog(@"%@", soapMessage);
    
    self.progress = [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nКонтакты контрагентов"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    /*NSLog( @"Succeeded! Received %d bytes of data", [webData length]);
     
     NSString *theXML = [[NSString alloc]
     initWithBytes: [webData mutableBytes]
     length:[webData length]
     encoding:NSUTF8StringEncoding];
     //---shows the XML---
     NSLog(@"%@", theXML);*/
    
    //
    
    GetCustContactXMLParser *parser = [GetCustContactXMLParser new];
    [parser parse:data];
    
    GetBrandRequest *brandRequest = [GetBrandRequest new];
    [brandRequest brandReq];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nКонтакты контрагентов"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end

