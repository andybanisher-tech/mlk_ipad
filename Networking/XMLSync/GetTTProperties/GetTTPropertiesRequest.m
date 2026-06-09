//
//  GetTTPropertiesRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 14.06.12.
//
//

#import "GetTTPropertiesRequest.h"
#import "GetTTPropertiesXMLParser.h"
#import "GetBrandMerchRequest.h"
#import "GetTTPropertiesValueRequest.h"
#import "SyncError.h"

@interface GetTTPropertiesRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetTTPropertiesRequest

- (void)ttPropReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetTTProperties>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetTTProperties>\n"
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
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nМерчендайзинг - Параметры точки"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
//    NSString *theXML = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//
//    //---shows the XML---
//    NSLog(@"%@", theXML);
    
    GetTTPropertiesXMLParser *parser = [GetTTPropertiesXMLParser new];
    [parser parse:data];
    
    if (self.syncTTPropertiesOnly) {
        GetTTPropertiesValueRequest *ttPValuesRequest = [GetTTPropertiesValueRequest new];
        ttPValuesRequest.syncTTPropertiesOnly = self.syncTTPropertiesOnly;
        [ttPValuesRequest sendRequest];
    } else {
        GetBrandMerchRequest *mbReq = [GetBrandMerchRequest new];
        [mbReq brandMerchReq];
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
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nМерчендайзинг - Параметры точки"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end

