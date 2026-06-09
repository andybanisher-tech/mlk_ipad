//
//  PutCommentsRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 28.06.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "PutCommentsRequest.h"
#import "XMLWriter.h"
#import "PutCommentsXMLParser.h"
#import "SyncStateWorker.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface PutCommentsRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation PutCommentsRequest

- (void)sendComments {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select CustAccount, Date, CommentType, Description, UserId, Time, CommentId, ForDelete from CustComment where CustAccount = ? and (SendStatus = 'Error' or SendStatus = 'New')";
        
        if (self.commentId) {
            sql = "select CustAccount, Date, CommentType, Description, UserId, Time, CommentId, ForDelete from CustComment where CommentId = ?";
        }
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            if (self.commentId) {
                sqlite3_bind_text(selectstmt, 1, [self.commentId UTF8String], -1, SQLITE_TRANSIENT);
            } else {
                //sqlite3_bind_text(selectstmt, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(selectstmt, 1, [self.custAccount UTF8String], -1, SQLITE_TRANSIENT);
                //sqlite3_bind_text(selectstmt, 3, [commentType UTF8String], -1, SQLITE_TRANSIENT);
            }
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *date           = @"null";
                NSString *type           = @"null";
                NSString *value          = @"null";
                NSString *user           = @"null";
                NSString *time           = @"null";
                NSString *commentNum     = @"null";
                NSString *forDeleteLocal = @"null";
                
                if (sqlite3_column_text(selectstmt, 1))
                    date  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    type  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    value  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    user  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    time  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    commentNum  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (sqlite3_column_text(selectstmt, 7))
                    forDeleteLocal  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                

                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:CustomerID"];
                [xmlWriter writeCharacters:self.custAccount];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CommentDate"];
                [xmlWriter writeCharacters:date];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:EmployeeID"];
                [xmlWriter writeCharacters:user];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CommentType"];
                [xmlWriter writeCharacters:type];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                [xmlWriter writeCharacters:value];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ForDelete"];
                [xmlWriter writeCharacters:forDeleteLocal];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CommentId"];
                [xmlWriter writeCharacters:commentNum];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Time"];
                [xmlWriter writeCharacters:time];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    // get the resulting XML string
    [self sendMsg:[xmlWriter toString]];
}

- (void)sendMsg:(NSString *)msg {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:PutComments>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:Value>"
                             "%@\n"
                             "</sam:Value>\n"
                             "</sam:PutComments>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid, msg];
    
    //    NSLog(@"%@", soapMessage);
    
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
        
        [SVProgressHUD showProgress:0.0 status:@"Отправка данных\nКомментарии"];
    }
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    if (!self.notShowProgress) {
        [SVProgressHUD dismiss];
    }

    /*NSString *theXML = [[NSString alloc]
     initWithBytes: [webData mutableBytes]
     length:[webData length]
     encoding:NSUTF8StringEncoding];
     //---shows the XML---
     ////NSLog(theXML);*/
    
    PutCommentsXMLParser *parser = [PutCommentsXMLParser new];
    parser.custAccount = self.custAccount;
    parser.commentId = self.commentId;
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
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Отправка данных\nКомментарии"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
