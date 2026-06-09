//
//  GetTwoRegionXMLParser.m
//  MLK
//
//  Created by garu on 11/7/14.
//
//

#import "GetTwoRegionXMLParser.h"
#import "Region.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetTwoRegionXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *regions;
@property (nonatomic, strong) Region *region;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetTwoRegionXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
	attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:GetTwoRegionResponse"]) {
        [self deleteRegion];
        self.regions = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.region = [[Region alloc] init];
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
        [self.regions addObject:self.region];

        self.region = nil;
    } else if ([elementName isEqualToString:@"m:PropertyID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.region setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PropertyValueID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.region setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PropertyValueName"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.region setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createRegion {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.regions.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into TwoRegion (PropertyID, PropertyValueID, PropertyValueName) Values(?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            Region *region_local = self.regions[y];
            
            sqlite3_bind_text(addStmt, 1, [region_local.PropertyID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [region_local.PropertyValueID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [region_local.PropertyValueName UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.regions = nil;
    }
    sqlite3_close(database);
}

- (void)deleteRegion {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *compiledStatement;
        
        // now execute sql statement
        sqlite3_exec(database, [[NSString stringWithFormat:
                                 @"delete from TwoRegion"] UTF8String], NULL, NULL, NULL);
        
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.regions.count > 0) {
        [self createRegion];
    }
}

@end
