//
//  CheckVersionRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 07.06.13.
//
//

#import "CheckVersionRequest.h"
#import "CheckVersionXMLParser.h"

@interface CheckVersionRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation CheckVersionRequest

- (void)verReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage;
    NSString *curVersion = [[NSBundle.mainBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                   "<soap:Header/>\n"
                   "<soap:Body>\n"
                   "<sam:PutVersion>\n"
                   "<sam:ID>%@</sam:ID>\n"
                   "<sam:Value>%@</sam:Value>\n"
                   "</sam:PutVersion>\n"
                   "</soap:Body>\n"
                   "</soap:Envelope>\n", udid, curVersion];
    
    
    //    NSLog(soapMessage);
    
    NSProgress *progress = [APIWorker.sharedInstance sendInputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    if (!self.notShowProgress) {
        self.progress = progress;
        [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
        
        [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nПроверка версии приложения"];
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
    
    CheckVersionXMLParser *parser = [CheckVersionXMLParser new];
    [parser parse:data];
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
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nПроверка версии приложения"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
