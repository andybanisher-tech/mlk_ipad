//
//  PDZFileRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 09.26.2014.
//
//

#import "PDZFileRequest.h"
#import "PDZFileXMLParser.h"

@interface PDZFileRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation PDZFileRequest

- (void)fileReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetPDZ>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:Code>%@</sam:Code>\n"
                             "</sam:GetPDZ>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid, self.custAccount];
    
    //NSLog(soapMessage);
    
    self.progress = [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nФайл ПДЗ"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    [SVProgressHUD dismiss];
    
//    NSString *theXML = [[NSString alloc]
//                        initWithBytes: [webData mutableBytes]
//                        length:[webData length]
//                        encoding:NSUTF8StringEncoding];
     //---shows the XML---
     //NSLog(theXML);
    
    PDZFileXMLParser *parser = [PDZFileXMLParser new];
    [parser parse:data];
}

- (void)handleError:(NSError *)error {
    [SVProgressHUD dismiss];
    [AlertWorkerObjc alertWithTitle:@"Ошибка подключения"];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nФайл ПДЗ"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end

