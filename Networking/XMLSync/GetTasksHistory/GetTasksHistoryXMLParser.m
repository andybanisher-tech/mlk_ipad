//
//  GetTasksHistoryXMLParser.m
//  MLK
//
//  Created by garu on 12/13/14.
//
//

#import "GetTasksHistoryXMLParser.h"
#import "Task.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetTasksHistoryXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *tasks;
@property (nonatomic, strong) Task *task;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetTasksHistoryXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
	attributes:(NSDictionary *)attributeDict {
	
    if ([elementName isEqualToString:@"m:GetTasksHistoryResponse"]) {
        self.tasks = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"Value"]) {
        self.task = [[Task alloc] init];
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
    if ([elementName isEqualToString:@"Value"]) {
        [self.tasks addObject:self.task];

        self.task = nil;
    } else if ([elementName isEqualToString:@"TaskID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.task setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"DateStart"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                    
        [self.task setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"TypeOfResult"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                            
        [self.task setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"Result"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                
        [self.task setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"ClientCode"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                    
        [self.task setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"Status"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                        
        [self.task setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"Source"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.task setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"Author"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.task setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"Comment"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.task setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createTaskTrans {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.tasks.count; y++) {
            Task *task_local = self.tasks[y];
            
            static sqlite3_stmt *addStmt_2;
            
            const char *sql_2 = "insert or ignore into TaskTrans (TaskId, CustAccount, TransDate, TransTime, Result, TypeOfResult, Status, Source, Author, Comment, isSended) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql_2, -1, &addStmt_2, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            sqlite3_bind_text(addStmt_2, 1, [task_local.TaskID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 2, [task_local.ClientCode UTF8String], -1, SQLITE_TRANSIENT);
            
            NSArray *dateTimeArray = [task_local.DateStart componentsSeparatedByString:@" "];
            NSString *transDate = [dateTimeArray objectAtIndex:0];
            NSString *transTime = [dateTimeArray objectAtIndex:1];
            
            sqlite3_bind_text(addStmt_2, 3, [transDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 4, [transTime UTF8String], -1, SQLITE_TRANSIENT);
            
            if ([task_local.Result isEqualToString:@""])
                sqlite3_bind_text(addStmt_2, 5, [@"Новая задача" UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(addStmt_2, 5, [task_local.Result UTF8String], -1, SQLITE_TRANSIENT);
            
            sqlite3_bind_text(addStmt_2, 6, [task_local.TypeOfResult UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 7, [task_local.Status UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 8, [task_local.Source UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 9, [task_local.Author UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 10, [task_local.Comment UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(addStmt_2, 11, 1);
            
            if (sqlite3_step(addStmt_2) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            sqlite3_finalize(addStmt_2);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.tasks = nil;
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.tasks.count > 0) {
        [self createTaskTrans];
    }
}

@end
