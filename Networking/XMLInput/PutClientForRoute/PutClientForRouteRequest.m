//
//  PutClientForRouteRequest.m
//  MLK
//
//  Created by Nikita on 08/04/15.
//
//

#import "PutClientForRouteRequest.h"
#import "XMLWriter.h"
#import "PutClientForRouteXMLParser.h"

#import "sqlite3.h"

@interface PutClientForRouteRequest ()

@property (nonatomic, strong) NSProgress *progress;

@end

@implementation PutClientForRouteRequest

@synthesize custAccount;
@synthesize forDelete, date, custName, custAddress;
@synthesize notShowProgress, notShowErrorMessage;

- (void)sendCust {
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    
    NSString *forDel_Val = @"";
    
    if (forDelete == YES)
        forDel_Val = @"1";
    else
        forDel_Val = @"0";
    
    //[xmlWriter writeStartElement:@"sam:Value"];
    
    [xmlWriter writeStartElement:@"sam:Date"];
    [xmlWriter writeCharacters:date];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:CustAccount"];
    [xmlWriter writeCharacters:custAccount];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:ForDelete"];
    [xmlWriter writeCharacters:forDel_Val];
    [xmlWriter writeEndElement];
    
    //[xmlWriter writeEndElement];
    
    [self sendMsg:[xmlWriter toString]];
}


- (void)sendMsg:(NSString *)msg {
    NSString *udid = self.managerID ? self.managerID : LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org' xmlns:sam1='http://www.sample-package1.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:PutClientForRoute>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:Value>"
                             "%@\n"
                             "</sam:Value>\n"
                             "</sam:PutClientForRoute>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid, msg];
    
//    NSLog(@"%@", soapMessage);
    
    NSProgress *progress = [APIWorker.sharedInstance sendInputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
  
    if (!notShowProgress) {
        self.progress = progress;
        [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
        
        [SVProgressHUD showProgress:0.0 status:@"Отправка данных\nDN"];
    }
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    if (!notShowProgress) {
        [SVProgressHUD dismiss];
    }
    
    //    NSString *theXML = [[NSString alloc]
    //                        initWithBytes: [webData mutableBytes]
    //                        length:[webData length]
    //                        encoding:NSUTF8StringEncoding];
    //    NSLog(@"%@", theXML);
    
    PutClientForRouteXMLParser *parser = [PutClientForRouteXMLParser new];
    BOOL result = [parser getResponseResult:data];
    
    if (result) {
        if (_delegate) {
            if (forDelete && [_delegate respondsToSelector:@selector(isSendedForDelete:)]) {
                [_delegate isSendedForDelete:custAccount];
            } else if ([_delegate respondsToSelector:@selector(isSended:custName:custAddr:strDate:)]){
                [_delegate isSended:custAccount custName:custName custAddr:custAddress strDate:date];
            }
        }
    } else if (!result && !notShowErrorMessage) {
        [AlertWorkerObjc alertWithTitle:@"Ошибка подключения. Данные сохранены локально и будут отправлены при синхронизации."];
    }
}

- (void)handleError:(NSError *)error {
    if (!notShowErrorMessage) {
        [AlertWorkerObjc alertWithTitle:@"Ошибка подключения. Данные сохранены локально и будут отправлены при синхронизации."];
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Отправка данных\nDN"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
