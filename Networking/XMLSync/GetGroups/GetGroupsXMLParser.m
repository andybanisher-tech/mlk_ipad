//
//  GetGroupsXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 28.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import "GetGroupsXMLParser.h"
#import "ItemGroup.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetGroupsXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *groups;
@property (nonatomic, strong) ItemGroup *group;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetGroupsXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:GetGroupsResponse"]) {
        [self deleteGroup];
        self.groups = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.group = [[ItemGroup alloc] init];
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
		[self.groups addObject:self.group];

        self.group = nil;
	} else if ([elementName isEqualToString:@"m:GroupID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.group setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:BrandID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.group setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:GroupName"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.group setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createGroup {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.groups.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into ItemGroup (GroupId, BrandId, GroupName) Values( ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            ItemGroup *itemGroup = self.groups[y];
            
            sqlite3_bind_text(addStmt, 1, [itemGroup.GroupID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [itemGroup.BrandID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [itemGroup.GroupName UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.groups = nil;
    }
    sqlite3_close(database);
}

- (void)deleteGroup {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *compiledStatement;
        // now execute sql statement
        sqlite3_exec(database, [[NSString stringWithFormat: 
                                 @"delete from ItemGroup"] UTF8String], NULL, NULL, NULL); 
        
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.groups.count > 0) {
        [self createGroup];
    }
}

@end
