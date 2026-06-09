//
//  GetGroupPropertiesValueXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 08.07.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "GetGroupPropertiesValueXMLParser.h"
#import "GroupPropertiesValue.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetGroupPropertiesValueXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *groupPropertiesValueArray;
@property (nonatomic, strong) GroupPropertiesValue *groupPropertiesValue;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetGroupPropertiesValueXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict {
	
	if ([elementName isEqualToString:@"m:GetGroupPropertiesValueResponse"]) {
        self.groupPropertiesValueArray = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.groupPropertiesValue = [[GroupPropertiesValue alloc] init];
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
        [self.groupPropertiesValueArray addObject:self.groupPropertiesValue];

        self.groupPropertiesValue = nil;
    } else if ([elementName isEqualToString:@"m:Period"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.groupPropertiesValue setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:CustomerID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.groupPropertiesValue setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:GroupID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.groupPropertiesValue setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:BrandID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.groupPropertiesValue setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PropertyID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                    
        [self.groupPropertiesValue setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PropertyValue"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                    
        [self.groupPropertiesValue setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PropertyValueID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.groupPropertiesValue setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createGPvalues {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.groupPropertiesValueArray.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into PropertiesValue (GroupId, BrandId, PropertyId, Value, Date, CustAccount, SendStatus, ElementListId) Values(?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            GroupPropertiesValue *gpv = self.groupPropertiesValueArray[y];
            
            sqlite3_bind_text(addStmt, 1, [gpv.GroupID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [gpv.BrandID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [gpv.PropertyID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [gpv.PropertyValue UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [gpv.Period UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [gpv.CustomerID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [@"Sended" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 8, [gpv.PropertyValueID UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.groupPropertiesValueArray = nil;
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.groupPropertiesValueArray.count > 0) {
        [self createGPvalues];
    }
}

@end
