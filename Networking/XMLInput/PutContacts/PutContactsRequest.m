//
//  PutContactsRequest.m
//  MLK
//
//  Created by Nikita on 22/01/15.
//
//

#import "PutContactsRequest.h"
#import "XMLWriter.h"
#import "PutContactsXMLParser.h"
#import "SyncStateWorker.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface PutContactsRequest ()

@property (nonatomic, strong) NSProgress *progress;

@end

@implementation PutContactsRequest

- (void)sendContact {
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select ContactId, Sname, Name, Mname, Birthday, Position, Phone, Email, ForDelete, Source, CustAccount, ContactId from CustContact where CustAccount = ? and ContactId = ?";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [self.custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [self.contactId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *sname     = @"null";
                NSString *name    = @"null";
                NSString *mname      = @"null";
                NSString *birthday = @"null";
                NSString *position       = @"null";
                NSString *phone       = @"null";
                NSString *email       = @"null";
                NSString *forDelete      = nil;
                NSString *source        = @"null";
                NSString *custAccount    = @"null";
                NSString *contactId          = @"null";
                
                if (sqlite3_column_text(selectstmt, 1))
                    sname = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    mname = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    birthday = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    position = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    phone = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (sqlite3_column_text(selectstmt, 7))
                    email = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                if (sqlite3_column_blob(selectstmt, 8))
                    forDelete = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                
                if (sqlite3_column_text(selectstmt, 9))
                    source = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 9)];
                
                if (sqlite3_column_text(selectstmt, 10))
                    custAccount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 10)];
                
                if (sqlite3_column_text(selectstmt, 11))
                    contactId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 11)];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:Sname"];
                [xmlWriter writeCharacters:sname];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Name"];
                [xmlWriter writeCharacters:name];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Mname"];
                [xmlWriter writeCharacters:mname];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Birthday"];
                [xmlWriter writeCharacters:birthday];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Position"];
                [xmlWriter writeCharacters:position];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Phone"];
                [xmlWriter writeCharacters:phone];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Email"];
                [xmlWriter writeCharacters:email];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ForDelete"];
                [xmlWriter writeCharacters:forDelete];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Source"];
                [xmlWriter writeCharacters:source];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CustAccount"];
                [xmlWriter writeCharacters:custAccount];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ContactId"];
                [xmlWriter writeCharacters:contactId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    [self sendMsg:[xmlWriter toString]];
}

- (void)sendMsg:(NSString *)msg {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org' xmlns:sam1='http://www.sample-package1.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:PutContacts>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:Value>"
                             "%@\n"
                             "</sam:Value>\n"
                             "</sam:PutContacts>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid, msg];
    
    ////NSLog(soapMessage);
    
    NSProgress *progress = [APIWorker.sharedInstance sendInputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    if (!self.notShowProgress) {
        self.progress = progress;
        [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
        
        [SVProgressHUD showProgress:0.0 status:@"Отправка данных\nDN"];
    }
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    if (!self.notShowProgress) {
        [SVProgressHUD dismiss];
    }
    
    //---shows the XML---
    ////NSLog(theXML);
    
    PutContactsXMLParser *parser = [PutContactsXMLParser new];
    parser.custAccount = self.custAccount;
    parser.contactId = self.contactId;
    [parser parse:data];
}

- (void)handleError:(NSError *)error {
    if (!self.notShowErrorMessage) {
        [SyncStateWorker setErrorState:YES];
        
        [AlertWorkerObjc alertWithTitle:@"Ошибка подключения. Данные сохранены локально и будут отправлены при синхронизации"];
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Отправка данных\nDN"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end

