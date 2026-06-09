//
//  SalesPdfRequest.m
//  MLK
//
//  Created by Alexandr Polienko on 15.04.2024.
//

#import "SalesPdfRequest.h"
#import "SalesPdfXMLParser.h"

@interface SalesPdfRequest ()
@property (nonatomic, strong) NSProgress *progress;

@property (nonatomic, strong) DocumentType *docType;

@end

@implementation SalesPdfRequest

- (void)requestDocument:(DocumentType *)docType salesUUID:(NSString *)salesUUID completion:(void (^)(NSData *pdfData, NSString *_Nullable errorString))completion {
    self.docType = docType;
    
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetDocs>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:SalesUUID>%@</sam:SalesUUID>\n"
                             "<sam:DocType>%lu</sam:DocType>\n"
                             "<sam:SiteID></sam:SiteID>\n"
                             "</sam:GetDocs>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid, salesUUID, (unsigned long)self.docType.docID];
    
    //NSLog(soapMessage);
    
    self.progress = [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            SalesPdfXMLParser *parser = [SalesPdfXMLParser new];
            [parser parse:data completion:completion];
        } else {
            completion(nil, @"Ошибка подключения");
        }
        [SVProgressHUD dismiss];
    }].progress;
    
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
    
    [SVProgressHUD showProgress:0.0 status:self.docType.name];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        
        [SVProgressHUD showProgress:progress.fractionCompleted status:self.docType.name];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
