//
//  GetMatrixRequest.m
//  mlk
//
//  Created by METASHARKS on 14/01/2017.
//
//

#import "GetMatrixRequest.h"
#import "GetMatrixXMLParser.h"
#import "GetBasePricesRequest.h"
#import "SyncError.h"

@interface GetMatrixRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetMatrixRequest

- (void)matrixReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetMatrix>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetMatrix>\n"
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
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nМатрица товаров"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
//    NSString *theXML = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"%@", theXML);
    
    GetMatrixXMLParser *parser = [GetMatrixXMLParser new];
    [parser parse:data];
    
    GetBasePricesRequest *basePriceRequest = [GetBasePricesRequest new];
    [basePriceRequest basePriceReq];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nМатрица товаров"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end


