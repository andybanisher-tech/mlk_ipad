//
//  GetGroupPropertiesXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 04.07.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "GetGroupPropertiesXMLParser.h"
#import "GroupProperties.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetGroupPropertiesXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *groupPropertiesArray;
@property (nonatomic, strong) GroupProperties *groupProperties;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetGroupPropertiesXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:GetGroupPropertiesResponse"]) {
        [self deleteGP];
        self.groupPropertiesArray = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.groupProperties = [[GroupProperties alloc] init];
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
        [self.groupPropertiesArray addObject:self.groupProperties];
        
        self.groupProperties = nil;
    } else if ([elementName isEqualToString:@"m:Period"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.groupProperties setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:GroupID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.groupProperties setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PropertyID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.groupProperties setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PropertyType"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.groupProperties setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PropertyName"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.groupProperties setValue:self.currentElementValue forKey:elementName];
    }
    
    self.currentElementValue = nil;
}

- (void)createGP {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.groupPropertiesArray.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into MerchGroupProperties (Period, GroupId, PropertyId, PropertyType, PropertyName) Values(?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            GroupProperties *gp = self.groupPropertiesArray[y];
            
            sqlite3_bind_text(addStmt, 1, [gp.Period UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [gp.GroupID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [gp.PropertyID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [gp.PropertyType UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [gp.PropertyName UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.groupPropertiesArray = nil;
    }
    sqlite3_close(database);
}

- (void)deleteGP {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *compiledStatement;
        // now execute sql statement
        sqlite3_exec(database, [[NSString stringWithFormat:
                                 @"delete from MerchGroupProperties"] UTF8String], NULL, NULL, NULL);
        
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.groupPropertiesArray.count > 0) {
        [self createGP];
    }
}

@end
