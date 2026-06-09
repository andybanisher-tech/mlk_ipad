//
//  GetListOfNotificationsXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 20.12.12.
//
//

#import "GetListOfNotificationsXMLParser.h"
#import "Notice.h"
#import "AppDelegate.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetListOfNotificationsXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *notices;
@property (nonatomic, strong) Notice *notice;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetListOfNotificationsXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
	attributes:(NSDictionary *)attributeDict {
	if ([elementName isEqualToString:@"m:GetListOfNotificationsResponse"]) {
		self.notices = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.notice = [[Notice alloc] init];
    }
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
    
    if ([elementName isEqualToString:@"m:Value"]) {
        [self.notices addObject:self.notice];

        self.notice = nil;
    } else if ([elementName isEqualToString:@"m:ID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.notice setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Name"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.notice setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Description"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                    
        [self.notice setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Alert"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                        
        [self.notice setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:NoticeDate"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.notice setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createNotice {
    NSDate *endDate = NSDate.date;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.notices.count; y++) {
            
            Notice *notice_local = self.notices[y];
            
            if ([self findNotice:notice_local.ID] == YES) {
                [self updateNotice:notice_local.ID alert:notice_local.Alert];
            } else {
                static sqlite3_stmt *addStmt;
            
                const char *sql = "insert or ignore into NoticeTable (ID, Name, Description, Status, NoticeDate) Values(?, ?, ?, ?, ?)";
            
                if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                    NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
                sqlite3_bind_text(addStmt, 1, [notice_local.ID UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 2, [notice_local.Name UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 3, [notice_local.Description UTF8String], -1, SQLITE_TRANSIENT);
                
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                
                [formatter setDateFormat:dateFormat_dd_MM_YYYY];
                
                NSDate *startDate = [formatter dateFromString:notice_local.NoticeDate];

                NSCalendar       *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                NSDateComponents *components        = [gregorianCalendar components:NSCalendarUnitDay
                                                                           fromDate:startDate
                                                                             toDate:endDate
                                                                            options:0];

                if ([components day] == 0)
                    sqlite3_bind_text(addStmt, 4, [@"new" UTF8String], -1, SQLITE_TRANSIENT);
                else
                    sqlite3_bind_text(addStmt, 4, [@"read" UTF8String], -1, SQLITE_TRANSIENT);
                
                sqlite3_bind_text(addStmt, 5, [notice_local.NoticeDate UTF8String], -1, SQLITE_TRANSIENT);
            
                if (sqlite3_step(addStmt) != SQLITE_DONE) {
                    NSLog(@"Commit Failed!");
                }
            
                sqlite3_finalize(addStmt);
            }
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.notices = nil;
    }
    sqlite3_close(database);
}

- (BOOL)findNotice:(NSString *)noticeId {
    BOOL haveNew = NO;
    
    const char *sql = "select ID from NoticeTable where ID = ?";
    sqlite3_stmt *statement;
        
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [noticeId UTF8String], -1, SQLITE_TRANSIENT);
            
        if (sqlite3_step(statement) == SQLITE_ROW)
            haveNew = YES;
    }
    sqlite3_finalize(statement);
    
    return haveNew;
}

- (void)updateNotice:(NSString *)noticeId alert:(NSString *)alert {
    char *sErrMsg;
    sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
    const char *sql = "update NoticeTable Set Status = ? where ID = ?";
        
    sqlite3_stmt *updateStmt;
        
    sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
    if ([alert isEqualToString:@"1"])
        sqlite3_bind_text(updateStmt, 1, [@"new" UTF8String], -1, SQLITE_TRANSIENT);
    
    sqlite3_bind_text(updateStmt, 2, [noticeId UTF8String], -1, SQLITE_TRANSIENT);
        
    sqlite3_step(updateStmt);
    sqlite3_finalize(updateStmt);
    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.notices.count > 0) {
        [self createNotice];
    }
    
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    
    if ([appDelegate checkForNew]) {
        [appDelegate showNotice];
    }
}

@end
