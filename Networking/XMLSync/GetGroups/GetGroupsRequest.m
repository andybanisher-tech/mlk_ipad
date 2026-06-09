//
//  GetGroupsRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 28.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import "GetGroupsRequest.h"
#import "GetGroupsXMLParser.h"
#import "GetGroupBrandsRequest.h"
#import "SyncError.h"

@interface GetGroupsRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetGroupsRequest

- (void)groupReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetGroups>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetGroups>\n"
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
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nГруппы"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    GetGroupsXMLParser *parser = [GetGroupsXMLParser new];
    [parser parse:data];
    
    GetGroupBrandsRequest *groupBrandRequest = [GetGroupBrandsRequest new];
    [groupBrandRequest groupBrandReq];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nГруппы"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end

