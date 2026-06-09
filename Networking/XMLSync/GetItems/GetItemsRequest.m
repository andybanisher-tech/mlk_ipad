//
//  GetItemsRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 06.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "GetItemsRequest.h"
#import "GetItemsXMLParser.h"
#import "GetMatrixRequest.h"
#import "SyncError.h"

#import "AnalyticsWorker.h"

@interface GetItemsRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetItemsRequest

- (void)itemsReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSSet *selectedIPadsSet = LocalAuthWorker.selectedIPadsSet;
    for (NSDictionary *object in selectedIPadsSet) {
        udid = [NSString stringWithFormat:@"%@,%@", udid, object[@"id"]];
    }
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetItems>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetItems>\n"
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
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nНоменклатура"];
    
    if (self.isSingleRequest) {
        [AnalyticsWorker appMetricaTrackSyncRemainsStarted:udid];
    }
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    //    NSLog( @"Succeeded! Received %lu bytes of data", (unsigned long)[webData length] );
    //    NSLog(@"Request body %@", connection.currentRequest.URL.absoluteString);
    //    NSLog(@"Request body %@", [[NSString alloc] initWithData:[connection.currentRequest HTTPBody] encoding:NSUTF8StringEncoding]);
//    NSString *theXML = [[NSString alloc]
//                        initWithBytes: [webData mutableBytes]
//                        length:[webData length]
//                        encoding:NSUTF8StringEncoding];
//    NSLog(@"%@", theXML);
    
    GetItemsXMLParser *parser = [GetItemsXMLParser new];
    [parser parse:data];
    
    if (self.isSingleRequest) {
        [SVProgressHUD dismiss];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [AlertWorkerObjc alertWithTitle:@"Обновление остатков прошло успешно"];
        });
        [AnalyticsWorker appMetricaTrackSyncRemainsSuccess];
    } else {
        GetMatrixRequest *matrixRequest = [GetMatrixRequest new];
        [matrixRequest matrixReq];
    }
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
    
    [AnalyticsWorker appMetricaTrackSyncRemainsFailure:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nНоменклатура"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end

