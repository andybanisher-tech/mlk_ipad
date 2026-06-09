//
//  PartnersRequest.m
//  MLK
//
//  Created by Alexandr Polienko on 12.12.2025.
//

#import "PartnersRequest.h"
#import "PartnersRequestXMLParser.h"
#import "SyncError.h"

@implementation PartnersRequest

- (void)getPartners:(NSString *)phone {
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<UrGetPartner xmlns=\"http://www.sample-package.org\">\n"
                             "<IDSite>%@</IDSite>\n"
                             "<IDPartner></IDPartner>\n"
                             "<Phone>%@</Phone>"
                             "<Email></Email>\n"
                             "<Version>2</Version>\n"
                             "<Other></Other>\n"
                             "</UrGetPartner>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", kExchangeSiteID, phone];
   
    [APIWorker.sharedInstance sendSiteRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
//    NSString *theXML = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"%@", theXML);
    
    PartnersRequestXMLParser *parser = [PartnersRequestXMLParser new];
    [parser parse:data];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

@end
