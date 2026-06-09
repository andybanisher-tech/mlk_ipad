//
//  ActionFileRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 08.04.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "ActionFileRequest.h"
#import "ActionFileXMLParser.h"

@interface ActionFileRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation ActionFileRequest

- (void)fileReq {
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetFiles>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetFiles>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", self.actionId];
    
    //NSLog(soapMessage);
    
    self.progress = [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nФайл акции"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    [SVProgressHUD dismiss];
//    NSString *theXML = [[NSString alloc]
//                        initWithBytes: [webData mutableBytes]
//                        length:[webData length]
//                        encoding:NSUTF8StringEncoding];
     //---shows the XML---
     ////NSLog(theXML);
//     [theXML release];
    
    ActionFileXMLParser *parser = [ActionFileXMLParser new];
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
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nФайл акции"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end

