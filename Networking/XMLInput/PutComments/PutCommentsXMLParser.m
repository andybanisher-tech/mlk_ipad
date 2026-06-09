//
//  PutCommentsXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 31.10.12.
//
//

#import "PutCommentsXMLParser.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface PutCommentsXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableString *currentElementValue;

@property (nonatomic, copy) NSString *response;

@end

@implementation PutCommentsXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    NSString *trimmedString = [string stringByTrimmingCharactersInSet:
                               NSCharacterSet.whitespaceAndNewlineCharacterSet];
    
    if (!self.currentElementValue) {
        self.currentElementValue = [[NSMutableString alloc] initWithString:trimmedString];
	} else {
        [self.currentElementValue appendString:trimmedString];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"m:Error"]) {
        self.response = self.currentElementValue.copy;
    }

    self.currentElementValue = nil;
}

- (void)updateComments {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        static sqlite3_stmt *updateStmt;
        
        const char *sql = "update CustComment set SendStatus = ? where Date = ? and CustAccount = ?  and (SendStatus = 'Error' or SendStatus = 'New')";
        
        if (self.commentId) {
            sql = "update CustComment set SendStatus = ? where CommentId = ? and (SendStatus = 'Error' or SendStatus = 'New')";
        }
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        if (self.commentId) {
            sqlite3_bind_text(updateStmt, 1, [self.response UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [self.commentId UTF8String], -1, SQLITE_TRANSIENT);
        } else {
            sqlite3_bind_text(updateStmt, 1, [self.response UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [self.custAccount UTF8String], -1, SQLITE_TRANSIENT);
            //sqlite3_bind_text(updateStmt, 4, [@"merch" UTF8String], -1, SQLITE_TRANSIENT);
        }
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if ([self.response localizedStandardContainsString:@"получено"]) {
        self.response = @"Sended";
    } else {
        self.response = @"Error";
    }
    
    [self updateComments];
}

@end
