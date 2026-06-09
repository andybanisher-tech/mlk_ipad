//
//  GetListOfNotificationsRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 20.12.12.
//
//

#import "GetListOfNotificationsRequest.h"
#import "GetListOfNotificationsXMLParser.h"
#import "GetFirmsRequest.h"

@interface GetListOfNotificationsRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetListOfNotificationsRequest

- (void)noticeReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSNumber *isNewNotice = [PersistenceWorker load:@"isNewNotice"];
    BOOL newNotice = isNewNotice ? isNewNotice.boolValue : YES;
    NSString *requestParameter = newNotice ? @"2" : @"0";
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetListOfNotifications>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:RequestParameter>%@</sam:RequestParameter>\n"
                             "</sam:GetListOfNotifications>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid, requestParameter];
    
    [PersistenceWorker save:@(NO) key:@"isNewNotice"];
    
    NSProgress *progress = [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    if (!self.notShowProgress) {
        self.progress = progress;
        [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
        
        [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nУведомления"];
    }
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
//    NSString *theXML = [[NSString alloc]
//                        initWithBytes: [webData mutableBytes]
//                        length:[webData length]
//                        encoding:NSUTF8StringEncoding];
     //---shows the XML---
     //NSLog(theXML);
    
    GetListOfNotificationsXMLParser *parser = [GetListOfNotificationsXMLParser new];
    [parser parse:data];
    
    if (!self.notShowProgress) {
        GetFirmsRequest *firmRequest = [GetFirmsRequest new];
        [firmRequest firmReq];
    }
}

- (void)handleError:(NSError *)error {
    if (!self.notShowProgress) {
        [SVProgressHUD dismiss];
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nУведомления"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
