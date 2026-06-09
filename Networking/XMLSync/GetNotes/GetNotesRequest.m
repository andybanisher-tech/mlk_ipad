//
//  GetNotesRequest.m
//  MLK
//
//  Created by Nikita on 22/01/15.
//
//

#import "GetNotesRequest.h"
#import "SyncError.h"
#import "GetNotesXMLParser.h"
#import "GetRouteDistRequest.h"

@interface GetNotesRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetNotesRequest

- (void)custCommentReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetNotes>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetNotes>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid];
//    NSLog(@"%@", soapMessage);
    
    self.progress = [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nЗаметки контрагентов"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    /*NSLog( @"Succeeded! Received %d bytes of data", [webData length]);
     
     NSString *theXML = [[NSString alloc]
     initWithBytes: [webData mutableBytes]
     length:[webData length]
     encoding:NSUTF8StringEncoding];
     //---shows the XML---
     NSLog(@"%@", theXML);*/
    
    //
    
    GetNotesXMLParser *parser = [GetNotesXMLParser new];
    [parser parse:data];
    
    GetRouteDistRequest *routeRequest = [GetRouteDistRequest new];
    [routeRequest routeReq];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nЗаметки контрагентов"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
