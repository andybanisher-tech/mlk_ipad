//
//  GetGroupBrandsXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 23.05.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "GetGroupBrandsXMLParser.h"
#import "GroupBrand.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetGroupBrandsXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *groupBrands;
@property (nonatomic, strong) GroupBrand *groupBrand;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetGroupBrandsXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict {
	if ([elementName isEqualToString:@"m:GetGroupBrandsResponse"]) {
		[self deleteGB];
        self.groupBrands = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.groupBrand = [[GroupBrand alloc] init];
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
		[self.groupBrands addObject:self.groupBrand];

        self.groupBrand = nil;
	} else if ([elementName isEqualToString:@"m:GroupID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.groupBrand setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:BrandID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.groupBrand setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:GroupName"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.groupBrand setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createGB {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.groupBrands.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into MerchGroupBrands (GroupId, BrandId, GroupName) Values( ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            GroupBrand *gb = self.groupBrands[y];
            
            sqlite3_bind_text(addStmt, 1, [gb.GroupID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [gb.BrandID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [gb.GroupName UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.groupBrands = nil;
    }
    sqlite3_close(database);
}

- (void)deleteGB {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *compiledStatement;
        // now execute sql statement
        sqlite3_exec(database, [[NSString stringWithFormat: 
                                 @"delete from MerchGroupBrands"] UTF8String], NULL, NULL, NULL); 
        
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.groupBrands.count > 0) {
        [self createGB];
    }
}

@end
