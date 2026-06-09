//
//  PutRouteToServerRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 10.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "PutRouteToServerRequest.h"
#import "PutRouteToServerXMLParser.h"
#import "SyncStateWorker.h"

@implementation PutRouteToServerRequest

@synthesize routeType;
@synthesize start, stop , visit, tapped, visited, cancelVisit;

- (void)sendRoute:(NSString *)msg {
    NSString *udid = LocalAuthWorker.login;
    
    if (self.delegate && visit) {
        [SVProgressHUD showInfoWithStatus:@"Отправка данных"];
    }
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:PutCustForRoute>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:Value>"
                             "%@\n"
                             "</sam:Value>\n"
                             "</sam:PutCustForRoute>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid, msg];

    [APIWorker.sharedInstance sendInputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    if (self.delegate && visit) {
        [SVProgressHUD dismiss];
    }
    
    if ([routeType isEqualToString:@"track"]) {
        PutRouteToServerXMLParser *parser = [PutRouteToServerXMLParser new];
        [parser parseData:data];
    }
    
    if (self.delegate) {
        PutRouteToServerXMLParser *parser = [PutRouteToServerXMLParser new];
        NSString *status = [parser getResponseStatus:data];
        
        if (status) {
            if (start) {
                [self.delegate isSendStart];
            } else if (stop) {
                 [self.delegate isSendStop];
            } else if (visit) {
                 [self.delegate isSendVisit];
            } else if (visited) {
                 [self.delegate isSendVisited];
            } else if (cancelVisit) {
                [self.delegate isSendCancelVisit];
            }
        } else {
            [SyncStateWorker setErrorState:YES];
            
            if (visit) {
                 [self.delegate isSendVisitNotSendStatus];
            } else if (visited) {
                 [self.delegate isSendVisitedNotSendStatus];
            } else if (cancelVisit) {
                 [self.delegate isSendCancelVisitNotSendStatus];
            } else {
                 [self.delegate failedToPutCustForRoute:status];
            }
        }
    }
}

- (void)handleError:(NSError *)error {
    if (visit && self.delegate) {
        [SVProgressHUD dismiss];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [AlertWorkerObjc alertWithTitle:@"Ошибка подключения. Данные сохранены локально и будут отправлены при синхронизации"];
        });
        
        [self.delegate isSendVisitNotSendStatus];
    }
    
    if ((start || stop ) && self.delegate ) {
        [SyncStateWorker setErrorState:YES];
        [AlertWorkerObjc alertWithTitle:@"Ошибка подключения. Данные сохранены локально и будут отправлены при синхронизации"];
    }
    
    if (visited && self.delegate) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [AlertWorkerObjc alertWithTitle:@"Ошибка подключения. Данные сохранены локально и будут отправлены при синхронизации"];
        });
        
        [self.delegate isSendVisitedNotSendStatus];
    }
    
    if (cancelVisit && self.delegate) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [AlertWorkerObjc alertWithTitle:@"Ошибка подключения. Данные сохранены локально и будут отправлены при синхронизации"];
        });
        
        [self.delegate isSendCancelVisitNotSendStatus];
    }
}

@end
