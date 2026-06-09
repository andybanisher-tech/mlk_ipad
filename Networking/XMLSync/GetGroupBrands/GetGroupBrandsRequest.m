//
//  GetGroupBrandsRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 22.05.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "GetGroupBrandsRequest.h"
#import "GetGroupBrandsXMLParser.h"
#import "GetGroupPropertiesRequest.h"
#import "SyncError.h"

@interface GetGroupBrandsRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetGroupBrandsRequest

- (void)groupBrandReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetGroupBrands>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetGroupBrands>\n"
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
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nМерчендайзинг - Группы"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    //NSString *theXML = [[NSString alloc]
    //                    initWithBytes: [webData mutableBytes]
    //                    length:[webData length]
    //                    encoding:NSUTF8StringEncoding];
    //---shows the XML---
    //////NSLog(theXML);
    //[theXML release];
    /*NSString *theXML = [[NSString alloc]
     initWithBytes: [webData mutableBytes]
     length:[webData length]
     encoding:NSUTF8StringEncoding];
     //---shows the XML---
     NSLog(@"%@", theXML);*/
    
    GetGroupBrandsXMLParser *parser = [GetGroupBrandsXMLParser new];
    [parser parse:data];
    
    GetGroupPropertiesRequest *groupPropertiesRequest = [GetGroupPropertiesRequest new];
    [groupPropertiesRequest groupPropReq];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nМерчендайзинг - Группы"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
