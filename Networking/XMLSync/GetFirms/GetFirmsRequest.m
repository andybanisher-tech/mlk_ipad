//
//  GetFirmsRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 21.01.13.
//
//

#import "GetFirmsRequest.h"
#import "GetFirmsXMLParser.h"
#import "AppDelegate.h"
#import "GetContactRoleRequest.h"
#import "SyncError.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetFirmsRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation GetFirmsRequest

- (void)firmReq {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:GetFirms>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "</sam:GetFirms>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid];
    
    self.progress = [APIWorker.sharedInstance sendOutputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
    
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nЮр.Лица"];
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
//    NSString *theXML = [[NSString alloc]
//                        initWithBytes: [webData mutableBytes]
//                        length:[webData length]
//                        encoding:NSUTF8StringEncoding];
    //---shows the XML---
    //NSLog(theXML);
    
    GetFirmsXMLParser *parser = [GetFirmsXMLParser new];
    [parser parse:data];
    
    GetContactRoleRequest *contactRoleRequest = [GetContactRoleRequest new];
    [contactRoleRequest getContactRoles];
    
    [self checkOpenSales];
}

- (void)handleError:(NSError *)error {
    SyncError *syncError = [SyncError new];
    [syncError errorMessage:error.localizedDescription];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Синхронизация\nЮр.Лица"];
    }
}

- (void)checkOpenSales {
    BOOL haveOpen = NO;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select SalesId from SalesTable where (SalesStatus = ? or SalesStatus = ?)";
        
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [@"Открыт" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [@"Ошибка" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                haveOpen = YES;
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    if (haveOpen) {
        AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
        [appDelegate switchToSalesTab];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
