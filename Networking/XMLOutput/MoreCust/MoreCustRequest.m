//
//  MoreCustRequest.m
//  MLK
//
//  Created by garu on 11/7/14.
//
//

#import "MoreCustRequest.h"
#import "GetCustContactXMLParser.h"
#import "MoreCustXMLParser.h"
#import "SyncError.h"

@interface MoreCustRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation MoreCustRequest

- (void)moreCustReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *sam = self.isCustContactRequest ? @"GetCustContactDop" : @"GetCustTableDop";
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:%@>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:PropertyValueID>%@</sam:PropertyValueID>\n"
                             "<sam:BrandID>%@</sam:BrandID>\n"
                             "</sam:%@>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", sam, udid, self.propertyValueId, self.brandId, sam];
    
    ////NSLog(soapMessage);
    
    self.progress = [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nДополнительные клиенты"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    [SVProgressHUD dismiss];
    
    NSString *xmlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    //    NSLog(@"%@", theXML);
    
    NSString *word  = @"#exception";
    NSString *error = @"Ничего не найдено";
    
    if ([xmlString rangeOfString:word].location != NSNotFound) {
        [AlertWorkerObjc alertWithTitle:@"Ошибка подключения" message:@"Сервис недоступен. Повторите операцию позже."];
        
    } else if ([xmlString rangeOfString:error].location != NSNotFound) {
        [AlertWorkerObjc alertWithTitle:@"Ошибка cинхронизации" message:error];
    } else {
        if (self.isCustContactRequest) {
            GetCustContactXMLParser *parser = [GetCustContactXMLParser new];
            [parser parse:data];
        } else {
            MoreCustXMLParser *parser = [MoreCustXMLParser new];
            [parser parse:data];
            
            MoreCustRequest *moreCustRequest = [MoreCustRequest new];
            moreCustRequest.propertyValueId = self.propertyValueId;
            moreCustRequest.brandId = self.brandId;
            moreCustRequest.isCustContactRequest = YES;
            [moreCustRequest moreCustReq];
        }
    }
    
    xmlString = nil;
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nДополнительные клиенты"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
