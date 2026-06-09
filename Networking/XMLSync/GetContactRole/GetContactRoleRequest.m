//
//  GetContactRoleRequest.m
//  MLK
//
//  Created by Alexandr Polienko on 29.11.2021.
//

#import "GetContactRoleRequest.h"
#import "GetContactRoleXMLParser.h"
#import "GetStatusDNRequest.h"

@interface GetContactRoleRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetContactRoleRequest

- (void)getContactRoles {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetContactRole>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetContactRole>\n"
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
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nДолжность контактного лица"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
//    NSString *theXML = [[NSString alloc]
//                        initWithBytes: [webData mutableBytes]
//                        length:[webData length]
//                        encoding:NSUTF8StringEncoding];
    //---shows the XML---
    //NSLog(theXML);
    
    GetContactRoleXMLParser *parser = [GetContactRoleXMLParser new];
    [parser parse:data];

    GetStatusDNRequest *dreamRequest = [GetStatusDNRequest new];
    [dreamRequest dreamReq];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nДолжность контактного лица"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
