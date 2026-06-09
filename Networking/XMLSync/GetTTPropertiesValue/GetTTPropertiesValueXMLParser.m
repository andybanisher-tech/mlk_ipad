//
//  TTPropertiesValueXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 13.07.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "GetTTPropertiesValueXMLParser.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetTTPropertiesValueXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *ttPropertiesValueArray;
@property (nonatomic, strong) NSMutableDictionary *ttPropertiesValue;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetTTPropertiesValueXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict {
	if ([elementName isEqualToString:@"m:GetTTPropertiesValueResponse"]) {
        [self deleteTTP];
        self.ttPropertiesValueArray = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.ttPropertiesValue = [NSMutableDictionary new];
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
        [self.ttPropertiesValueArray addObject:self.ttPropertiesValue];

        self.ttPropertiesValue = nil;
    } else if ([elementName isEqualToString:@"m:Period"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.ttPropertiesValue setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:CustomerID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.ttPropertiesValue setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:TTID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                    
        [self.ttPropertiesValue setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PropertyID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                            
        [self.ttPropertiesValue setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PropertyValue"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                
        [self.ttPropertiesValue setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PropertyValueID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.ttPropertiesValue setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createTTPvalues {
    NSDate *date = NSDate.date;
    NSDateFormatter *dateFormat = NSDateFormatter.new;
    dateFormat.dateFormat = dateFormat_dd_MM_YYYY;
    NSString *dateString = [dateFormat stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        const char *sql = "INSERT INTO TTPropertiesValue (PropertyId, Value, Date, CustAccount, SendStatus, ttId, ElementListId) VALUES (?, ?, ?, ?, ?, ?, ?) ON CONFLICT(Date, PropertyId, CustAccount) DO UPDATE SET Value = CASE WHEN length(TTPropertiesValue.Value) > 0 THEN TTPropertiesValue.Value || ',' || excluded.Value ELSE excluded.Value END, ElementListId = CASE WHEN length(TTPropertiesValue.ElementListId) > 0 THEN TTPropertiesValue.ElementListId || ',' || excluded.ElementListId ELSE excluded.ElementListId END, SendStatus = excluded.SendStatus, ttId = excluded.ttId";
        
        for (NSDictionary *object in self.ttPropertiesValueArray) {
            sqlite3_stmt *addStmt = NULL;
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK) {
                NSLog(@"Prepare error: %s", sqlite3_errmsg(database));
                continue;
            }
  
            sqlite3_bind_text(addStmt, 1, [object[@"PropertyID"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [object[@"PropertyValue"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, dateString.UTF8String, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [object[@"CustomerID"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [@"Sended" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [object[@"TTID"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [object[@"PropertyValueID"] UTF8String], -1, SQLITE_TRANSIENT);

            sqlite3_step(addStmt);
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.ttPropertiesValueArray = nil;
    }
    sqlite3_close(database);
}

- (void)deleteTTP {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *compiledStatement;
        // now execute sql statement
        sqlite3_exec(database, [[NSString stringWithFormat:
                                 @"delete from TTPropertiesValue"] UTF8String], NULL, NULL, NULL);
        
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.ttPropertiesValueArray.count > 0) {
        [self createTTPvalues];
    }
}

@end
