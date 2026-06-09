//
//  PutOrdersNewRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 13.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PutOrdersNewRequest.h"
#import "PutOrdersNewXMLParser.h"

@implementation PutOrdersNewRequest

@synthesize salesId;

- (void)sendSales:(NSString *)msg {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soapenv:Header/>\n"
                             "<soapenv:Body>\n"
                             "<sam:PutOrdersNew>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:Value>"
                             "%@\n"
                             "</sam:Value>\n"
                             "</sam:PutOrdersNew>\n"
                             "</soapenv:Body>\n"
                             "</soapenv:Envelope>\n", udid, msg];
    
//    NSLog(@"%@", soapMessage);
    
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
    /*NSString *theXML = [[NSString alloc]
     initWithBytes: [webData mutableBytes]
     length:[webData length]
     encoding:NSUTF8StringEncoding];
     //---shows the XML---
     ////NSLog(theXML);*/
    
    PutOrdersNewXMLParser *parser = [PutOrdersNewXMLParser new];
    parser.isConsult = self.isConsult;
    parser.salesId = salesId;
    [parser parse:data];
}

- (void)handleError:(NSError *)error {
    [AlertWorkerObjc alertWithTitle:@"Ошибка подключения. Не удалось отправить заказ. Проверьте настройки подключения."];
}

@end

