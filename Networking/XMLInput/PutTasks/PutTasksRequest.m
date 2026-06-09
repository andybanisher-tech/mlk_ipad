//
//  PutTasksRequest.m
//  MLK
//
//  Created by garu on 11/27/14.
//
//

#import "PutTasksRequest.h"
#import "XMLWriter.h"
#import "Base64Class.h"
#import "PutTasksXMLParser.h"
#import "SyncStateWorker.h"

#import "FilesStorageWorker.h"

static sqlite3 *database = nil;

@interface PutTasksRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@interface PutTasksRequest () {
    PutTasksRequest *me;
}

@end

@implementation PutTasksRequest

@synthesize custAccount, notShowErrorMessage;
@synthesize delegate;
@synthesize taskId;
@synthesize notShowProgress;
@synthesize status, result, transDate;
@synthesize lastTransRowId;

- (void)updateAfterSend:(NSString *)taskId custAcc:(NSString *)custAcc lastRowId:(sqlite3_int64)lastRowId {
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        
        static sqlite3_stmt *updStmt;
        
        const char *sql = "update TaskTable set isSended = ? where TaskId = ? and CustAccount = ?";
        
        if (sqlite3_prepare_v2(database, sql, -1, &updStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_int(updStmt, 1,1);
        sqlite3_bind_text(updStmt, 2, [taskId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updStmt, 3, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_step(updStmt);
        sqlite3_finalize(updStmt);
        
        static sqlite3_stmt *updTransStmt;
        
        //const char *sqlTrans = "update TaskTrans set isSended = ? where ROWID = ?";
        const char *sqlTrans = "update TaskTrans set isSended = ? where TaskId = ? and CustAccount = ?";
        
        if (sqlite3_prepare_v2(database, sqlTrans, -1, &updTransStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_int(updTransStmt, 1,1);
        //sqlite3_bind_int64(updTransStmt, 2, lastRowId);
        sqlite3_bind_text(updTransStmt, 2, [taskId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updTransStmt, 3, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updTransStmt);
        sqlite3_finalize(updTransStmt);
    }
    sqlite3_close(database);
}

- (void)deleteTask {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *deleteStmt;
        
        const char *sql = "delete from TaskTable where TaskId = ? and CustAccount = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL);
        //When binding parameters, index starts from 1 and not zero.
        sqlite3_bind_text(deleteStmt, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(deleteStmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(deleteStmt);
        sqlite3_finalize(deleteStmt);
    }
    sqlite3_close(database);
    
    [self.delegate refresh];
}

- (void)updateTask {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql_2 = "update TaskTable Set Status = ?, Result = ?, TransDate = ? where TaskId = ? and CustAccount = ?";
        
        sqlite3_stmt *updateStmt;
        
        if (sqlite3_prepare_v2(database, sql_2, -1, &updateStmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(updateStmt, 1, [status UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [result UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [transDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 4, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 5, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            sqlite3_step(updateStmt);
            sqlite3_finalize(updateStmt);
        }
    } else {
        sqlite3_close(database);
    }
    
    if (self.delegate) {
        [self.delegate refresh];
    }
}

- (void)sendTask {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select TaskId, TaskName, DateEnd, TypeOfResult, Result, CustAccount, Status, Source, Image, Setted, Visit, From1C from TaskTable where CustAccount = ? and TaskId = ?";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                
                NSString *taskIdLocal  = @"null";
                NSString *taskName     = @"null";
                NSString *dateEnd      = @"null";
                NSString *typeOfResult = @"null";
                NSString *resultLocal  = @"null";
                NSString *custAcc      = @"null";
                NSString *statusLocal  = @"null";
                NSString *source       = @"null";
                NSData   *imgData      = nil;
                NSString *image        = @"null";
                NSString *set          = @"null";
                NSString *visit        = @"null";
                NSString *from1C       = @"0";
                NSString *transTime    = @"null";
                NSString *transDate    = @"null";
                NSString *author       = @"";
                NSString *comment      = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    taskIdLocal = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    taskName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    dateEnd = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    typeOfResult = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    resultLocal = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    custAcc = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    status = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (sqlite3_column_text(selectstmt, 7))
                    source = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                if (sqlite3_column_blob(selectstmt, 8)) {
                    // imgData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt, 9) length:sqlite3_column_bytes(selectstmt, 9)];
                    imgData = [FilesStorageWorker getFileWithName:[NSString stringWithFormat:@"%@_%@", taskId, custAccount] atPath:[FilesStorageWorker taskImagesPath]];
                    
                    image = [Base64Class encode:imgData];
                }
                
                if (sqlite3_column_text(selectstmt, 9))
                    set = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 9)];
                
                if (sqlite3_column_text(selectstmt, 10))
                    visit = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 10)];
                
                if (sqlite3_column_text(selectstmt, 11))
                    from1C = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 11)];
                
                sqlite3_stmt *selectTransStmt;
                
                const char *sqlTrans = "select Status, Result, TypeOfResult, TransTime, TransDate, Comment, Image from TaskTrans where isSended = ? and TaskId = ? and CustAccount = ?";
                
                if (sqlite3_prepare_v2(database, sqlTrans, -1, &selectTransStmt, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_int(selectTransStmt, 1, 0);
                    sqlite3_bind_text(selectTransStmt, 2, [taskIdLocal UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selectTransStmt, 3, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
                    
                    while (sqlite3_step(selectTransStmt) == SQLITE_ROW)
                    {
                        XMLWriter* xmlWriter = [[XMLWriter alloc] init];
                        
                        if (sqlite3_column_text(selectTransStmt, 0))
                            statusLocal = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectTransStmt, 0)];
                        
                        if (sqlite3_column_text(selectTransStmt, 1))
                            resultLocal = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectTransStmt, 1)];
                        
                        if (sqlite3_column_text(selectTransStmt, 2))
                            typeOfResult = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectTransStmt, 2)];
                        
                        if (sqlite3_column_text(selectTransStmt, 3))
                            transTime = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectTransStmt, 3)];
                        
                        if (sqlite3_column_text(selectTransStmt, 4))
                            transDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectTransStmt, 4)];
                        
                        if (sqlite3_column_text(selectTransStmt, 5))
                            comment = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectTransStmt, 5)];
                        
                        if (sqlite3_column_blob(selectTransStmt, 6)) {
                            imgData = [FilesStorageWorker getFileWithName:[NSString stringWithFormat:@"%@_%@", taskId, custAccount] atPath:[FilesStorageWorker taskImagesPath]];
                            
                            image = [Base64Class encode:imgData];
                        }
                        
                        NSLog(@"task name - %@",taskName);
                        NSLog(@"status - %@",status);
                        
                        [xmlWriter writeStartElement:@"sam1:Value"];
                        
                        [xmlWriter writeStartElement:@"sam1:TaskID"];
                        [xmlWriter writeCharacters:taskId];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:TaskName"];
                        [xmlWriter writeCharacters:taskName];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:DateStart"];
                        [xmlWriter writeCharacters:[NSString stringWithFormat:@"%@ %@", transDate, transTime]];
                        [xmlWriter writeEndElement];
                        
                        NSString *dateEndVal;
                        if (![status isEqualToString:@"Открытая"]) {
                            dateEndVal = [NSString stringWithFormat:@"%@ %@", transDate, transTime];
                        } else {
                            dateEndVal = [NSString stringWithFormat:@"%@ %@", dateEnd, transTime];
                        }
                        
                        [xmlWriter writeStartElement:@"sam1:DateEnd"];
                        [xmlWriter writeCharacters:dateEndVal];
                        //[xmlWriter writeCharacters:dateEnd];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:TypeOfResult"];
                        [xmlWriter writeCharacters:typeOfResult];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Result"];
                        
                        if ([typeOfResult isEqualToString:@"5"])
                            [xmlWriter writeCharacters:image];
                        else
                            [xmlWriter writeCharacters:resultLocal];
                        
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:ClientCode"];
                        [xmlWriter writeCharacters:custAcc];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Status"];
                        [xmlWriter writeCharacters:statusLocal];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Source"];
                        [xmlWriter writeCharacters:source];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Set"];
                        [xmlWriter writeCharacters:set];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Visit"];
                        [xmlWriter writeCharacters:visit];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:From1C"];
                        [xmlWriter writeCharacters:from1C];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Photo"];
                        [xmlWriter writeCharacters:image];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Author"];
                        [xmlWriter writeCharacters:author];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Comment"];
                        [xmlWriter writeCharacters:comment];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeEndElement];
                        
                        [self sendMsg:[xmlWriter toString]];
                    }
                }
                
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
}

- (void)sendTasks {
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select TaskId, TaskName, DateStart, DateEnd, TypeOfResult, Result, CustAccount, Status, Source, Image, Setted, Visit, From1C from TaskTable where CustAccount = ? and TaskId = ?";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *taskName     = @"null";
                NSString *dateStart    = @"null";
                NSString *dateEnd      = @"null";
                NSString *typeOfResult = @"null";
                NSString *resultf      = @"null";
                NSString *statusLocal  = @"null";
                NSString *source       = @"null";
                NSData   *imgData      = nil;
                NSString *image        = @"null";
                NSString *set          = @"null";
                NSString *visit        = @"null";
                NSString *from1C        = @"0";
                
                if (sqlite3_column_text(selectstmt, 1))
                    taskName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    dateStart = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    dateEnd = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    typeOfResult = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    resultf = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (result && ![result isEqualToString:@""])
                    resultf = result;
                
                NSLog(@"%@", resultf);
                
                if (sqlite3_column_text(selectstmt, 7))
                    statusLocal = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                if (sqlite3_column_text(selectstmt, 8))
                    source = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                
                if (sqlite3_column_blob(selectstmt, 9)) {
                    imgData = [FilesStorageWorker getFileWithName:[NSString stringWithFormat:@"%@_%@", taskId, custAccount] atPath:[FilesStorageWorker taskImagesPath]];
                    
                    image = [Base64Class encode:imgData];
                }
                
                if (sqlite3_column_text(selectstmt, 10))
                    set = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 10)];
                
                if (sqlite3_column_text(selectstmt, 11))
                    visit = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 11)];
                
                if (sqlite3_column_text(selectstmt, 12))
                    from1C = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 12)];
                
                [xmlWriter writeStartElement:@"sam1:Value"];
                
                [xmlWriter writeStartElement:@"sam1:TaskID"];
                [xmlWriter writeCharacters:taskId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam1:TaskName"];
                [xmlWriter writeCharacters:taskName];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam1:DateStart"];
                [xmlWriter writeCharacters:dateStart];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam1:DateEnd"];
                [xmlWriter writeCharacters:dateEnd];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam1:TypeOfResult"];
                [xmlWriter writeCharacters:typeOfResult];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam1:Result"];
                
                //if ([typeOfResult isEqualToString:@"5"])
                //    [xmlWriter writeCharacters:image];
                //else
                [xmlWriter writeCharacters:resultf];
                
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam1:ClientCode"];
                [xmlWriter writeCharacters:custAccount];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam1:Status"];
                [xmlWriter writeCharacters:statusLocal];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam1:Source"];
                [xmlWriter writeCharacters:source];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam1:Set"];
                [xmlWriter writeCharacters:set];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam1:Visit"];
                [xmlWriter writeCharacters:visit];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam1:From1C"];
                [xmlWriter writeCharacters:from1C];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam1:Photo"];
                [xmlWriter writeCharacters:image];
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
    me = self;
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org' xmlns:sam1='http://www.sample-package1.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:PutTasks>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:Value>"
                             "%@\n"
                             "</sam:Value>\n"
                             "</sam:PutTasks>\n"
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
    
    if (!notShowProgress) {
        self.progress = progress;
        [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
        
        [SVProgressHUD showProgress:0.0 status:@"Отправка данных\nDN"];
    }
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    if (!notShowProgress) {
        [SVProgressHUD dismiss];
    }
    
    @try {
        //---shows the XML---
        // NSLog(@"data - from task %@",theXML);
        
        PutTasksXMLParser *parser = [PutTasksXMLParser new];
        BOOL result = [parser getResponseResult:data];
        
        if (result) {
            if (self) {
                [self updateAfterSend:taskId custAcc:custAccount lastRowId:lastTransRowId];
            }
        } else if (!notShowErrorMessage) {
            [SyncStateWorker setErrorState:YES];
            [AlertWorkerObjc alertWithTitle:@"Ошибка подключения. Данные сохранены локально и будут отправлены при синхронизации"];
        }
    }
    
    @catch (NSException *exception) {
        if (! notShowErrorMessage) {
            [SyncStateWorker setErrorState:YES];
            [AlertWorkerObjc alertWithTitle:@"Ошибка подключения. Данные сохранены локально и будут отправлены при синхронизации"];
        }
    }
    
    @finally {
        me = nil;
    }
}

- (void)handleError:(NSError *)error {
    if (!notShowErrorMessage) {
        [SyncStateWorker setErrorState:YES];
        
        [AlertWorkerObjc alertWithTitle:@"Ошибка подключения. Данные сохранены локально и будут отправлены при синхронизации"];
    }
    me = nil;
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
