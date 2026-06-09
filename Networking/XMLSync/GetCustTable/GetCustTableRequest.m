//
//  GetCustTableRequest.m
//  AiCRM
//
//  Created by Rustem Galyamov on 07.04.11.
//  Copyright 2011 Aimen Ltd. All rights reserved.
//

#import "GetCustTableRequest.h"
#import "GetCustTableXMLParser.h"
#import "GetCustContactNewRequest.h"
#import "GetRouteDistRequest.h"
#import "SyncError.h"
#import "SyncStateWorker.h"

#import "AnalyticsWorker.h"

@interface GetCustTableRequest ()

@property (nonatomic, copy) NSString *managerID;
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetCustTableRequest

- (void)requestCustTable {
    NSString *udid = LocalAuthWorker.login;
    
    NSSet *selectedIPadsSet = LocalAuthWorker.selectedIPadsSet;
    for (NSDictionary *object in selectedIPadsSet) {
        udid = [NSString stringWithFormat:@"%@,%@", udid, object[@"id"]];
    }
    
    [self requestCustTable:udid];
}

- (void)requestCustTable:(NSString *)login {
    self.managerID = login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetCustTable>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetCustTable>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", login];
    
    //NSLog(soapMessage);
    
    self.progress = [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nКлиенты"];
    
    [AnalyticsWorker appMetricaTrackSyncAllDataStarted:login];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    NSString *xmlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //---shows the XML---
//    NSLog(@"%@", xmlString);
    
    NSString *word  = @"#exception";
    NSString *word2 = @"SOAP-ENV:Fault";
    NSString *error = @"Ничего не найдено";
    
    if ([xmlString rangeOfString:word].location != NSNotFound) {
        [SVProgressHUD dismiss];
        
        [SyncStateWorker setErrorState:YES];
        [AlertWorkerObjc alertWithTitle:@"Ошибка подключения" message:@"Сервис недоступен. Повторите операцию позже."];
        
        [AnalyticsWorker appMetricaTrackSyncAllDataFailure:word];
    } else if ([xmlString rangeOfString:word2].location != NSNotFound) {
        [SVProgressHUD dismiss];
            
        [SyncStateWorker setErrorState:YES];
        [AlertWorkerObjc alertWithTitle:@"Ошибка подключения" message:@"Сервис недоступен. Повторите операцию позже."];
        
        [AnalyticsWorker appMetricaTrackSyncAllDataFailure:word2];
    } else if ([xmlString rangeOfString:error].location != NSNotFound) {
        [SVProgressHUD dismiss];
            
        [AlertWorkerObjc alertWithTitle:@"Ошибка cинхронизации" message:error];

        [PersistenceWorker remove:@"login"];
        
        [AnalyticsWorker appMetricaTrackSyncAllDataFailure:error];
    } else {
        xmlString = nil;
        
        GetCustTableXMLParser *parser = [GetCustTableXMLParser new];
        parser.isSchedulerRequest = self.isSchedulerRequest;
        [parser parse:data];

        if (self.isSchedulerRequest) {
            GetRouteDistRequest *routeRequest = [GetRouteDistRequest new];
            routeRequest.isSchedulerRequest = self.isSchedulerRequest;
            routeRequest.managerID = self.managerID;
            [routeRequest routeReq];
        } else {
            GetCustContactNewRequest *custContactRequest = [GetCustContactNewRequest new];
            [custContactRequest custContactReq];
        }
    }
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [SyncStateWorker setErrorState:YES];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nКлиенты"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
