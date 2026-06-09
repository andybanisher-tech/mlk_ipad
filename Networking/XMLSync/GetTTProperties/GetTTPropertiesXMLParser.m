//
//  GetTTPropertiesXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 14.06.12.
//
//

#import "GetTTPropertiesXMLParser.h"
#import "TTProperties.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetTTPropertiesXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *ttPropertiesArray;
@property (nonatomic, strong) TTProperties *ttProperties;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetTTPropertiesXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:GetTTPropertiesResponse"]) {
        [self deleteGP];
        self.ttPropertiesArray = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.ttProperties = [[TTProperties alloc] init];
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
		[self.ttPropertiesArray addObject:self.ttProperties];

        self.ttProperties = nil;
	} else if ([elementName isEqualToString:@"m:Period"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.ttProperties setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:TTID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.ttProperties setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PropertyID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.ttProperties setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PropertyType"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                        
        [self.ttProperties setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PropertyName"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                            
        [self.ttProperties setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Multiple"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.ttProperties setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Required"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.ttProperties setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createGP {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.ttPropertiesArray.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into MerchTTProperties (Period, TTId, PropertyId, PropertyType, PropertyName, isMultiple, isRequired) Values(?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            TTProperties *ttp = self.ttPropertiesArray[y];
            
            sqlite3_bind_text(addStmt, 1, [ttp.Period UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [ttp.TTID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [ttp.PropertyID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [ttp.PropertyType UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [ttp.PropertyName UTF8String], -1, SQLITE_TRANSIENT);
            
            if ([ttp.Multiple localizedStandardContainsString:@"yes"] ||
                [ttp.Multiple localizedStandardContainsString:@"true"]) {
                sqlite3_bind_int(addStmt, 6, 1);
            } else {
                sqlite3_bind_int(addStmt, 6, 0);
            }
            
            if ([ttp.Required localizedStandardContainsString:@"yes"] ||
                [ttp.Required localizedStandardContainsString:@"true"]) {
                sqlite3_bind_int(addStmt, 7, 1);
            } else {
                sqlite3_bind_int(addStmt, 7, 0);
            }
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.ttPropertiesArray = nil;
    }
    sqlite3_close(database);
}

- (void)deleteGP {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *compiledStatement;
        // now execute sql statement
        sqlite3_exec(database, [[NSString stringWithFormat: 
                                 @"delete from MerchTTProperties"] UTF8String], NULL, NULL, NULL); 
        
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.ttPropertiesArray.count > 0) {
        [self createGP];
    }
}

@end
