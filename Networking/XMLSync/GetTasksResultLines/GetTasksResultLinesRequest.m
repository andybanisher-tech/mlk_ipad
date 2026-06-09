//
//  GetTasksResultLinesRequest.m
//  MLK
//
//  Created by garu on 11/26/14.
//
//

#import "GetTasksResultLinesRequest.h"
#import "GetTasksResultLinesXMLParser.h"
#import "SyncError.h"
#import "GetNotesRequest.h"

@interface GetTasksResultLinesRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetTasksResultLinesRequest

- (void)taskListReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetTasksResultLines>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetTasksResultLines>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid];
    
    //NSLog(soapMessage);
    
    self.progress = [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nСписки значений"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    //    NSLog( @"Succeeded! Received %d bytes of data", [webData length] );
    //
    //    NSString *theXML = [[NSString alloc]
    //                        initWithBytes: [webData mutableBytes]
    //                        length:[webData length]
    //                        encoding:NSUTF8StringEncoding];
    //    //---shows the XML---
    //    NSLog(@"%@", theXML);
    
    GetTasksResultLinesXMLParser *parser = [GetTasksResultLinesXMLParser new];
    [parser parse:data];
    
    GetNotesRequest *custCommentRequest = [GetNotesRequest new];
    [custCommentRequest custCommentReq];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nСписки значений"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
