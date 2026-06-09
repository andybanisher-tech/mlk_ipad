//
//  GetStatusDNBrendRequest.m
//  mlk
//
//  Created by Nikolya Smolnyakov on 14.10.16.
//
//

#import "GetStatusDNBrendRequest.h"
#import "GetStatusDNBrendXMLParser.h"
#import "SyncError.h"
#import "SyncStateWorker.h"

#import "AnalyticsWorker.h"

@interface GetStatusDNBrendRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end


@implementation GetStatusDNBrendRequest

- (void)statusDNBrandReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetStatusDNBrend>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetStatusDNBrend>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid];
    
    //NSLog(soapMessage);
    
    self.progress = [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nСтатус DN"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    [SVProgressHUD dismiss];
    
    /*NSLog( @"Succeeded! Received %d bytes of data", [webData length] );
     
     NSString *theXML = [[NSString alloc]
     initWithBytes: [webData mutableBytes]
     length:[webData length]
     encoding:NSUTF8StringEncoding];
     //---shows the XML---
     NSLog(@"%@", theXML);*/
    
    GetStatusDNBrendXMLParser *parser = [GetStatusDNBrendXMLParser new];
    [parser parse:data];
    
    if (![SyncStateWorker getErrorState]) {
        [PersistenceWorker save:LocalAuthWorker.selectedIPadsSet key:@"synchronizedIPadsSet"];
        
        [SyncStateWorker setSynchronized:YES];
        
        [AlertWorkerObjc alertWithTitle:@"Синхронизация прошла успешно"];
        
        [AnalyticsWorker appMetricaTrackSyncAllDataSuccess];
    } else {
        [AlertWorkerObjc alertWithTitle:@"Синхронизация выполнена с ошибками"];
        
        [AnalyticsWorker appMetricaTrackSyncAllDataFailure:@"Синхронизация выполнена с ошибками"];
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
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nСтатус DN"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
