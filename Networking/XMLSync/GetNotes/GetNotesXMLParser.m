//
//  GetNotesXMLParser.m
//  MLK
//
//  Created by Nikita on 22/01/15.
//
//

#import "GetNotesXMLParser.h"
#import "Note.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetNotesXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, strong) Note *comment;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetNotesXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:GetNotesResponse"]) {
        [self deleteComment];
        self.comments = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.comment = [[Note alloc] init];
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
        [self.comments addObject:self.comment];
        self.comment = nil;
    } else if ([elementName isEqualToString:@"m:CustAccount"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.comment setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:CommentId"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.comment setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Description"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.comment setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:UserId"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.comment setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Date"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.comment setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:CommentType"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.comment setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Time"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.comment setValue:self.currentElementValue forKey:elementName];
    }
    
    self.currentElementValue = nil;
}

- (void)createComment {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.comments.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into CustComment (CustAccount, CommentId, Description, UserId, Date, CommentType, SendStatus, Time, ForDelete) Values(?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            Note *comment_local = self.comments[y];
            
            sqlite3_bind_text(addStmt, 1, [comment_local.custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [comment_local.commentId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [comment_local.description UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [comment_local.userId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [comment_local.date UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [comment_local.commentType UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [@"Sended" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 8, [comment_local.time UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 9, [@"0" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.comments = nil;
    }
    sqlite3_close(database);
}

- (void)deleteComment {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_exec(database, [[NSString stringWithFormat:
                                 @"delete from CustComment"] UTF8String], NULL, NULL, NULL);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.comments > 0) {
        [self createComment];
    }
}

@end


