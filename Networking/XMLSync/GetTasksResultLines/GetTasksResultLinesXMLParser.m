//
//  GetTasksResultLinesXMLParser.m
//  MLK
//
//  Created by garu on 11/26/14.
//
//

#import "GetTasksResultLinesXMLParser.h"
#import "TaskList.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetTasksResultLinesXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *taskLists;
@property (nonatomic, strong) TaskList *taskList;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetTasksResultLinesXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
	attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:GetTasksResultLinesResponse"]) {
        [self deleteTaskList];
        self.taskLists = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"Value"]) {
        self.taskList = [[TaskList alloc] init];
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
        [self.taskLists addObject:self.taskList];

        self.taskList = nil;
    } else if ([elementName isEqualToString:@"TaskID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.taskList setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"LineID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.taskList setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"LineDescription"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                    
        [self.taskList setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createTaskList {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.taskLists.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into TaskList (TaskId, LineId, LineDescription) Values(?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            TaskList *taskList_local = self.taskLists[y];
            
            sqlite3_bind_text(addStmt, 1, [taskList_local.TaskID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [taskList_local.LineID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [taskList_local.LineDescription UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.taskLists = nil;
    }
    sqlite3_close(database);
}

- (void)deleteTaskList {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *compiledStatement;
        
        sqlite3_exec(database, [[NSString stringWithFormat:
                                 @"delete from TaskList"] UTF8String], NULL, NULL, NULL);
        
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.taskLists.count > 0) {
        [self createTaskList];
    }
}

@end
