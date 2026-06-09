//
//  GetPropertiesList.m
//  MLK
//
//  Created by Rustem Galyamov on 02.06.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "GetPropertiesListRequest.h"
#import "GetPropertiesListXMLParser.h"
#import "GetTTPropertiesRequest.h"
#import "SyncError.h"

@interface GetPropertiesListRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetPropertiesListRequest

- (void)propListReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetPropertiesList>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetPropertiesList>\n"
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
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nМерчендайзинг - Списки"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
//    NSString *theXML = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"%@", theXML);
    
    GetPropertiesListXMLParser *parser = [GetPropertiesListXMLParser new];
    [parser parse:data];
    
    GetTTPropertiesRequest *ttPropertiesRequest = [GetTTPropertiesRequest new];
    ttPropertiesRequest.syncTTPropertiesOnly = self.syncTTPropertiesOnly;
    [ttPropertiesRequest ttPropReq];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nМерчендайзинг - Списки"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
