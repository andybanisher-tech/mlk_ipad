//
//  GetTasksXMLParser.m
//  MLK
//
//  Created by garu on 11/25/14.
//
//

#import "GetTasksXMLParser.h"
#import "Task.h"

#import "FilesStorageWorker.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetTasksXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *tasks;
@property (nonatomic, strong) Task *task;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetTasksXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
	attributes:(NSDictionary *)attributeDict {
	
	if ([elementName isEqualToString:@"m:GetTasksResponse"]) {
		[self deleteTask];
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
    } else if ([elementName isEqualToString:@"TaskName"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.task setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"DateStart"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                    
        [self.task setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"DateEnd"]) {
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
    } else if ([elementName isEqualToString:@"Set"]) {
        elementName = @"Setted";//[elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.task setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"Visit"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.task setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"From1C"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.task setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"Photo"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.task setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createTask {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.tasks.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into TaskTable (TaskId, TaskName, DateStart, DateEnd, TypeOfResult, Result, CustAccount, Status, Source, Setted, Visit, From1C, isSended, Photo) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            Task *task_local = self.tasks[y];
            
            sqlite3_bind_text(addStmt, 1, [task_local.TaskID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [task_local.TaskName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [task_local.DateStart UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [task_local.DateEnd UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [task_local.TypeOfResult UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [task_local.Result UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [task_local.ClientCode UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 8, [task_local.Status UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 9, [task_local.Source UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 10,[task_local.Setted UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 11,[task_local.Visit UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 12,[task_local.From1C UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(addStmt, 13, 0);
            sqlite3_bind_text(addStmt, 14,[task_local.Photo UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.tasks = nil;
    }
    sqlite3_close(database);
}

- (void)deleteTask {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_exec(database, [[NSString stringWithFormat:
                                 @"delete from TaskTable"] UTF8String], NULL, NULL, NULL);
        
        sqlite3_exec(database, [[NSString stringWithFormat:
                                 @"delete from TaskTrans"] UTF8String], NULL, NULL, NULL);
        
        [FilesStorageWorker removeDirectoryAtPath:[FilesStorageWorker taskImagesPath]];
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.tasks.count > 0) {
        [self createTask];
    }
}

@end
