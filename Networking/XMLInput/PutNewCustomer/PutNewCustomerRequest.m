//
//  PutNewCustomerRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 08.04.2014.
//
//

#import "PutNewCustomerRequest.h"
#import "PutNewCustomerXMLParser.h"

@implementation PutNewCustomerRequest

@synthesize custAccount;

- (void)sendCustomer:(NSString *)msg {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:PutNewCustomer>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:Value>"
                             "%@\n"
                             "</sam:Value>\n"
                             "</sam:PutNewCustomer>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid, msg];
    
    //NSLog(soapMessage);
    
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
    //---shows the XML---
    //    NSString *theXML = [[NSString alloc] initWithBytes:[webData mutableBytes] length:[webData length] encoding:NSUTF8StringEncoding];
    //    NSLog(@"%@", theXML);
    
    PutNewCustomerXMLParser *parser = [PutNewCustomerXMLParser new];
    parser.custAccount = custAccount;
    [parser parse:data];
}

- (void)handleError:(NSError *)error {
    [NSNotificationCenter.defaultCenter postNotificationName:@"SendNewCustomerNotification" object:@"NotSended"];
}

@end
