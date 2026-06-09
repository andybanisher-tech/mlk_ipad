//
//  CustomerVisitsRequest.m
//  MLK
//
//  Created by Alexandr Polienko on 04.09.2023.
//

#import "CustomerVisitsRequest.h"
#import "CustomerVisitsXMLParser.h"
#import "SyncError.h"

@implementation CustomerVisitsRequest

- (void)getCustomerVisits:(NSString *)custAccount {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetVisits>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:CustAccount>%@</sam:CustAccount>"
                             "</sam:GetVisits>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid, custAccount];
   
    [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    CustomerVisitsXMLParser *parser = [CustomerVisitsXMLParser new];
    [parser parse:data];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

@end
