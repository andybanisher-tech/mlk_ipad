//
//  PutVisitDateRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 06.12.13.
//
//

#import "PutVisitDateRequest.h"
#import "sqlite3.h"

@implementation PutVisitDateRequest

@synthesize curCustAcc, curStrDate, notShowErrorMessage;

- (void)sendLVD:(NSString *)msg {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soapenv:Header/>\n"
                             "<soapenv:Body>\n"
                             "<sam:PutVisitDate>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:Value>"
                             "%@\n"
                             "</sam:Value>\n"
                             "</sam:PutVisitDate>\n"
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
    //---shows the XML---
    ////NSLog(theXML);
    if (self.curStrDate && self.curCustAcc) {
        [self updateVLDAfterConnection];
    }
}

- (void)handleError:(NSError *)error {
    if (!notShowErrorMessage) {
        [AlertWorkerObjc alertWithTitle:@"Ошибка подключения. Данные сохранены локально и будут отправлены при синхронизации"];
    }
}

- (void)updateVLDAfterConnection {
    sqlite3 *database = nil;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *updateStmt;
        
        const char *sql = "update CustForRoute Set isSended = ? where CustAccount = ? and DateOfRoute = ? and Status = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        
        sqlite3_bind_int(updateStmt, 1, 1);
        sqlite3_bind_text(updateStmt, 2, [self.curCustAcc UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 3, [self.curStrDate UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 4, [@"visited" UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        
        
        sqlite3_stmt *updateVisitDate;
        
        const char *sqlDate = "update CustTable Set isSended = ? where CustAccount = ? and LastVisitDate = ?";
        
        sqlite3_prepare_v2(database, sqlDate, -1, &updateVisitDate, NULL);
        
        sqlite3_bind_int(updateVisitDate, 1, 1);
        sqlite3_bind_text(updateVisitDate, 2, [self.curCustAcc UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateVisitDate, 3, [self.curStrDate UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateVisitDate);
        sqlite3_finalize(updateVisitDate);
    }
    sqlite3_close(database);
}

@end
