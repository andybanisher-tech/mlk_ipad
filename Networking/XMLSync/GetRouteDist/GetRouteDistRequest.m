//
//  GetRouteDistRequest.m
//  MLK
//
//  Created by Nikita on 19/02/15.
//
//

#import "GetRouteDistRequest.h"
#import "SyncError.h"
#import "GetRouteDistXMLParser.h"
#import "GetStatusDNBrendRequest.h"

@interface GetRouteDistRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetRouteDistRequest

- (void)routeReq {
    [self routeReq:LocalAuthWorker.routeNearCustomersSearchRadius];
}

- (void)routeReq:(double)searchRadius {
    [PersistenceWorker save:@(searchRadius) key:@"routeNearCustomersSearchRadius"];
    NSString *udid = self.managerID ? self.managerID : LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetRouteDist>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:SearchRadius>%.2f</sam:SearchRadius>"
                             "</sam:GetRouteDist>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid, searchRadius];
    
    //    NSLog(@"%@", soapMessage);
    
    self.progress = [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nМаршруты"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
//    NSString *theXML = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"%@", theXML);
    
    GetRouteDistXMLParser *parser = [GetRouteDistXMLParser new];
    parser.isSchedulerRequest = self.isSchedulerRequest;
    [parser parse:data];
    
    if (self.isSingleRequest || self.isSchedulerRequest) {
        [NSNotificationCenter.defaultCenter postNotificationName:@"routeRefreshed" object:@{@"managerID" : self.managerID ? self.managerID : LocalAuthWorker.login}];
        [SVProgressHUD showSuccessWithStatus:@"Обновление маршрута прошло успешно"];
    } else {
        GetStatusDNBrendRequest *newCustomerRequest = [GetStatusDNBrendRequest new];
        [newCustomerRequest statusDNBrandReq];
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
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nМаршруты"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
