//
//  GetBrandRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 05.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "GetBrandRequest.h"
#import "GetBrandXMLParser.h"
#import "GetItemsRequest.h"
#import "SyncError.h"

@interface GetBrandRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetBrandRequest

- (void)brandReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSSet *selectedIPadsSet = LocalAuthWorker.selectedIPadsSet;
    for (NSDictionary *object in selectedIPadsSet) {
        udid = [NSString stringWithFormat:@"%@,%@", udid, object[@"id"]];
    }
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetBrand>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetBrand>\n"
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
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nМарки"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    /*NSLog( @"Succeeded! Received %d bytes of data", [webData length] );
     
     NSString *theXML = [[NSString alloc]
     initWithBytes: [webData mutableBytes]
     length:[webData length]
     encoding:NSUTF8StringEncoding];
     //---shows the XML---
     //////NSLog(theXML);
     */
    
    GetBrandXMLParser *parser = [GetBrandXMLParser new];
    [parser parse:data];
    
    GetItemsRequest *itemsRequest = [GetItemsRequest new];
    [itemsRequest itemsReq];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nМарки"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end

