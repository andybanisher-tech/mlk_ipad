//
//  GetNewCustomerRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 08.05.2014.
//
//

#import "GetNewCustomerRequest.h"
#import "GetNewCustomerXMLParser.h"
#import "SyncError.h"
#import "GetTwoRegionRequest.h"

@interface GetNewCustomerRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetNewCustomerRequest

- (void)newCustomerReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetNewCustomer>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetNewCustomer>\n"
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
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nНовые клиенты"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
//    NSString *theXML = [[NSString alloc]
//                        initWithBytes: [webData mutableBytes]
//                        length:[webData length]
//                        encoding:NSUTF8StringEncoding];
     //---shows the XML---
//     NSLog(@"%@", theXML);
    
    GetNewCustomerXMLParser *parser = [GetNewCustomerXMLParser new];
    [parser parse:data];
    
    GetTwoRegionRequest *regionRequest = [GetTwoRegionRequest new];
    [regionRequest regionReq];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nНовые клиенты"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
