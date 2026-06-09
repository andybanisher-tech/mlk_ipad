//
//  GetMatrixXMLParser.m
//  mlk
//
//  Created by METASHARKS on 14/01/2017.
//
//

#import "GetMatrixXMLParser.h"
#import "Matrix.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetMatrixXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *matrixArray;
@property (nonatomic, strong) Matrix *matrix;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetMatrixXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
    
    if ([elementName isEqualToString:@"m:GetMatrixResponse"]) {
        //Initialize the array.
        [self deleteMatrix];
        self.matrixArray = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        //Initialize the contact.
        self.matrix = [[Matrix alloc] init];
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
        [self.matrixArray addObject:self.matrix];
        
        self.matrix = nil;
    } else if ([elementName isEqualToString:@"m:MatrixID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.matrix setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:MatrixName"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.matrix setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:ItemID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.matrix setValue:self.currentElementValue forKey:elementName];
    }
    
    self.currentElementValue = nil;
}

- (void)createMatrix {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.matrixArray.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into MatrixTable (MatrixId, MatrixName, ItemId) Values( ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            Matrix *matrixLocal = self.matrixArray[y];
            
            sqlite3_bind_text(addStmt, 1, [matrixLocal.MatrixID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [matrixLocal.MatrixName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [matrixLocal.ItemID UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(addStmt);
        }
        
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (void)deleteMatrix {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *compiledStatement;
        
        // now execute sql statement
        sqlite3_exec(database, [[NSString stringWithFormat:
                                 @"delete from MatrixTable"] UTF8String], NULL, NULL, NULL);
        
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.matrixArray.count > 0) {
        [self createMatrix];
    }
}

@end

