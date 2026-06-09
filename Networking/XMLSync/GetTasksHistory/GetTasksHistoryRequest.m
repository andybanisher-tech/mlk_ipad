//
//  GetTasksHistoryRequest.m
//  MLK
//
//  Created by garu on 12/13/14.
//
//

#import "GetTasksHistoryRequest.h"
#import "GetTasksHistoryXMLParser.h"
#import "SyncError.h"
#import "GetTasksResultLinesRequest.h"

@interface GetTasksHistoryRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetTasksHistoryRequest

- (void)taskTransReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSSet *selectedIPadsSet = LocalAuthWorker.selectedIPadsSet;
    for (NSDictionary *object in selectedIPadsSet) {
        udid = [NSString stringWithFormat:@"%@,%@", udid, object[@"id"]];
    }
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetTasksHistory>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetTasksHistory>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid];
    
//    NSLog(soapMessage);

    self.progress = [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nЗадачи"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    //    NSString *theXML = [[NSString alloc]
    //                        initWithBytes: [webData mutableBytes]
    //                        length:[webData length]
    //                        encoding:NSUTF8StringEncoding];
    //    //---shows the XML---
    //    NSLog(@"%@", theXML);
    
    GetTasksHistoryXMLParser *parser = [GetTasksHistoryXMLParser new];
    [parser parse:data];
    
    GetTasksResultLinesRequest *taskListRequest = [GetTasksResultLinesRequest new];
    [taskListRequest taskListReq];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nЗадачи"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
