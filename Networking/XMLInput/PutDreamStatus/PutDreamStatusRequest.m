//
//  PutDreamStatusRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 06.12.13.
//
//

#import "PutDreamStatusRequest.h"
#import "PutDreamStatusXMLParser.h"
#import "SyncStateWorker.h"

#import "sqlite3.h"

@implementation PutDreamStatusRequest

@synthesize custAccount, notShowErrorMessage;

- (void)sendDream:(NSString *)msg {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soapenv:Header/>\n"
                             "<soapenv:Body>\n"
                             "<sam:PutDreamStatus>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:Value>"
                             "%@\n"
                             "</sam:Value>\n"
                             "</sam:PutDreamStatus>\n"
                             "</soapenv:Body>\n"
                             "</soapenv:Envelope>\n", udid, msg];
    
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
    ////NSLog(theXML);
    
    PutDreamStatusXMLParser *parser = [PutDreamStatusXMLParser new];
    BOOL result = [parser getResponseResult:data];
    
    if (result) {
        if (custAccount) {
            [self updateAfterSend];
        }
    } else if (!notShowErrorMessage) {
        [SyncStateWorker setErrorState:YES];
        [AlertWorkerObjc alertWithTitle:@"Ошибка подключения. Данные сохранены локально и будут отправлены при синхронизации"];
    }
}

- (void)handleError:(NSError *)error {
    if (!notShowErrorMessage) {
        [AlertWorkerObjc alertWithTitle:@"Ошибка подключения. Данные сохранены локально и будут отправлены при синхронизации"];
    }
}

- (void)updateAfterSend {
    sqlite3 *database = nil;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *updateStmt;
        
        const char *sql = "update CustStatusDN Set isSended = ? where CustAccount = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_int(updateStmt, 1, 1);
        
        sqlite3_bind_text(updateStmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
    }
    sqlite3_close(database);
}

@end
