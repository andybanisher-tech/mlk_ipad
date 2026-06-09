//
//  GetOrdersRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 22.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GetOrdersRequest.h"
#import "GetOrdersXMLParser.h"
#import "GetGroupsRequest.h"
#import "SyncError.h"

@interface GetOrdersRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetOrdersRequest

- (void)salesReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSSet *selectedIPadsSet = LocalAuthWorker.selectedIPadsSet;
    for (NSDictionary *object in selectedIPadsSet) {
        udid = [NSString stringWithFormat:@"%@,%@", udid, object[@"id"]];
    }
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetOrders_new>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetOrders_new>\n"
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
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nЗаказы"];
}

- (void)salesLineReq:(NSString *)salesNumber {
    NSString *udid = LocalAuthWorker.login;
    
    NSSet *selectedIPadsSet = LocalAuthWorker.selectedIPadsSet;
    for (NSDictionary *object in selectedIPadsSet) {
        udid = [NSString stringWithFormat:@"%@,%@", udid, object[@"id"]];
    }
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetOrdersLine>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:Number>%@</sam:Number>\n"
                             "</sam:GetOrdersLine>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid, salesNumber];
    
    self.progress = [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nЗаказы"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    //NSLog( @"Succeeded! Received %d bytes of data", [webData length] );
//    NSString *theXML = [[NSString alloc]
//                        initWithBytes: [webData mutableBytes]
//                        length:[webData length]
//                        encoding:NSUTF8StringEncoding];
    //---shows the XML---
//    NSLog(@"%@", theXML);
    
    GetOrdersXMLParser *parser = [GetOrdersXMLParser new];
    parser.removeOld = self.removeOld;
    parser.syncSalesLine = self.synsSalesLine;
    parser.syncNum1C = self.syncNum1C;
    [parser parse:data];
    
    if (!self.synsSalesLine && !self.removeOld) {
        GetGroupsRequest *itemsGroupRequest = [GetGroupsRequest new];
        [itemsGroupRequest groupReq];
    } else {
        [SVProgressHUD dismiss];
    }
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nЗаказы"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
