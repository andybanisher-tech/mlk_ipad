//
//  GetStatusDNXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 05.12.13.
//
//

#import "GetStatusDNXMLParser.h"
#import "Dream.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetStatusDNXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *dreams;
@property (nonatomic, strong) Dream *dream;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetStatusDNXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
	attributes:(NSDictionary *)attributeDict {
	if ([elementName isEqualToString:@"m:GetStatusDNResponse"]) {
		[self deleteDream];
        self.dreams = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.dream = [Dream new];
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
        [self.dreams addObject:self.dream];

        self.dream = nil;
    } else if ([elementName isEqualToString:@"m:CustomerID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.dream setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Status"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.dream setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createDream {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.dreams.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into CustStatusDN (CustAccount, StatusDN) Values(?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            Dream *dream_local = self.dreams[y];
            
            sqlite3_bind_text(addStmt, 1, [dream_local.CustomerID UTF8String], -1, SQLITE_TRANSIENT);
            
            if ([dream_local.Status isEqualToString:@""])
                sqlite3_bind_text(addStmt, 2, [@"Без статуса" UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(addStmt, 2, [dream_local.Status UTF8String], -1, SQLITE_TRANSIENT);
            
            NSLog(@"%@", dream_local.Status);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.dreams = nil;
    }
    sqlite3_close(database);
}

- (void)deleteDream {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *compiledStatement;
        
        // now execute sql statement
        sqlite3_exec(database, [[NSString stringWithFormat:
                                 @"delete from CustStatusDN"] UTF8String], NULL, NULL, NULL);
        
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.dreams.count > 0) {
        [self createDream];
    }
}

@end
