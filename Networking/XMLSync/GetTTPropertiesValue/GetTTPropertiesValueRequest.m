//
//  GetTTPropertiesValueRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 13.07.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "GetTTPropertiesValueRequest.h"
#import "GetTTPropertiesValueXMLParser.h"
#import "SyncError.h"
#import "GetListOfNotificationsRequest.h"

@interface GetTTPropertiesValueRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetTTPropertiesValueRequest

- (void)sendRequest {
    NSString *udid = LocalAuthWorker.login;
    
    NSSet *selectedIPadsSet = LocalAuthWorker.selectedIPadsSet;
    for (NSDictionary *object in selectedIPadsSet) {
        udid = [NSString stringWithFormat:@"%@,%@", udid, object[@"id"]];
    }
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetTTPropertiesValue>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetTTPropertiesValue>\n"
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
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nМерчендайзинг - ТТ"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    //---shows the XML---
//    NSString *theXML = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"%@", theXML);
    
    GetTTPropertiesValueXMLParser *parser = [GetTTPropertiesValueXMLParser new];
    [parser parse:data];
    
    if (self.syncTTPropertiesOnly) {
        [NSNotificationCenter.defaultCenter postNotificationName:@"ttPropertiesUpdated" object:nil];
    } else {
        GetListOfNotificationsRequest *noticeRequest = [GetListOfNotificationsRequest new];
        [noticeRequest noticeReq];
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
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nМерчендайзинг - ТТ"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
